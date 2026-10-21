class_name JudgmentStore
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19; spec docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf,
## gates SJD-C and SJD-D): personal memory, subjective interpretation and signed GOOD/BAD judgment. Isolated: the live
## game creates none unless judgment.json "enabled" is true or a test attaches one (JudgmentLive.attach). Every
## number is in game/data/judgment.json (provisional; the open owner questions SJD-Q01..Q14 are parameters there).
##
## "The event is what happened. Belief is what someone thinks happened. Judgment is what that means to them.
## Decision is what they choose to do given everything else in their life." (spec, design maxim). Four records:
##   facts        what happened (publish): immutable but for an explicit correction (revise_fact)
##   memories     what each person believes, with provenance: participant, witnessed, told (by whom), rumour; bounded
##                (memory.capacity) and fading (salience), so nobody remembers everything
##   contrib      each person's active contribution per event and judged actor: one, replaced, never added twice
##                (spec invariant 4), so a rumour heard twice or a correction never double counts
##   ledgers      observer -> subject: lifetime GOOD and BAD (never negative), NET = GOOD - BAD, the number of
##                contributions, and an optional faded "effective" view (off by default: SJD-Q02)
## Judgment is a disposition, not a decision: JudgmentWeighting turns it into one factor among need, price and
## alternatives, weighed by the live decision code that already owns the choice.
##
## Compact records (round 2, memory): every record is a PackedInt64Array, not a Dictionary (event types and sources
## by index), so a memory or an opinion costs a few dozen bytes. fact(), belief() and ledger() give readable views.
##
## The daily update (fading, forgetting, retiring old events) is sliced (round 2, frame cost): begin_day(d) at dawn
## does only the global part and queues every person; dawn_hour() brings a share of them up to date each hour, and any
## person is brought up to date the moment anything reads or changes their records (catch-up on touch, _cu). A
## person's daily update depends only on their own records and the day, so the sliced update gives exactly the state
## the whole update at dawn gives (advance_day, which is begin_day then finish_dawn), whatever happens in between
## (judgment_test: same end state, hash for hash).

const FORMAT := "mml-judgment/1"
const VERSION := 1
const SOURCES := ["participant", "witnessed", "told", "rumour"]
const TOLD := 2
# a memory: [type, day, src, by, hops, conf, sal, actor count, actor, share, actor, share...]
const M_TYPE := 0
const M_DAY := 1
const M_SRC := 2
const M_BY := 3
const M_HOPS := 4
const M_CONF := 5
const M_SAL := 6
const M_NA := 7
# a fact: [type, day, revision, value, actor count, (actor, share)..., victim count, victims..., beneficiary count, ...]
const F_TYPE := 0
const F_DAY := 1
const F_REV := 2
const F_VALUE := 3
const F_NA := 4

var cfg: Dictionary
var social: JudgmentSocial
var world_seed := 0
var day := 0
var next_event := 1
var facts := {}          # event id -> PackedInt64Array (F_*)
var fact_tags := {}      # event id -> tags, only for events that have any
var fact_orig := {}      # event id -> the original actors, only for revised events
var knowers := {}        # event id -> PackedInt64Array of everyone who has judged it, sorted (the dedup key)
var by_day := {}         # day -> [event ids] (horizon expiry)
var memories := {}       # observer -> {event id -> PackedInt64Array (M_*)}
var contrib := {}        # observer -> {event id -> PackedInt64Array [actor, good, bad, ...] by actor}
var ledgers := {}        # observer -> {subject -> PackedInt64Array [good, bad, n, eff_good, eff_bad]}
var told_today := {}     # teller -> tellings today (gossip.daily_budget)
var stats := {}          # counters for diagnostics and performance reports
var unread := {}         # a saved section this version cannot read: kept and written back unchanged (CLAUDE.md s.7)
var last_trace := {}     # the last interpretation's parts (diagnostics: "why was the theft rated 0.55 BAD?")
var timing := {}         # microseconds spent, by part (measurement only: never saved, never read by the simulation)

# the sliced daily update
var _people := PackedInt64Array()   # everyone with any record, sorted
var _active := false     # a day's update is under way
var _queue := PackedInt64Array()    # everyone queued at begin_day (a copy of _people then), by id
var _qi := 0             # the queue's next position: those before it are up to date
var _early := {}         # people at or after _qi already brought up to date on touch
var _steps := 0          # days the pending update covers
var _retiring := {}      # events retired at begin_day: each knower's record of them goes at their catch-up

# the catalog and settings, looked up once
var _types: Array = []
var _tix := {}
var _sev := PackedInt64Array()
var _pol := PackedInt64Array()   # 1 GOOD, -1 BAD, 0 NEUTRAL
var _amb := PackedInt64Array()   # 1 ambiguous
var _perm := PackedInt64Array()  # 1 never fades
var _cap := 24
var _fade := 0
var _below := 0
var _eff_fade := 0
var _retract := false
var _slices := 24


static var _cfg_cache := {}


## judgment.json, read once; each caller gets its own copy (a store may be given changed values by a test).
static func default_cfg() -> Dictionary:
	if _cfg_cache.is_empty():
		var f := FileAccess.open("res://data/judgment.json", FileAccess.READ)
		_cfg_cache = JSON.parse_string(f.get_as_text())
	return _cfg_cache.duplicate(true)


func _init(config: Dictionary = {}, social_view: JudgmentSocial = null, seed := 0) -> void:
	cfg = config if not config.is_empty() else default_cfg()
	social = social_view if social_view != null else JudgmentSocial.new()
	world_seed = seed
	_types = (cfg.events as Dictionary).keys()
	_types.sort()
	var m: Dictionary = cfg.memory
	for i in _types.size():
		var d: Dictionary = cfg.events[_types[i]]
		_tix[_types[i]] = i
		_sev.append(int(d.severity))
		_pol.append(1 if str(d.polarity) == "GOOD" else (-1 if str(d.polarity) == "BAD" else 0))
		_amb.append(1 if bool(d.get("ambiguous", false)) else 0)
		_perm.append(1 if int(d.severity) >= int(m.permanent_severity) else 0)
	_cap = int(m.capacity)
	_fade = int(m.salience_fade_permille)
	_below = int(m.forget_below)
	_eff_fade = int(m.effective_fade_permille)
	_retract = bool(m.retract_on_forget)
	_slices = maxi(1, int(m.get("dawn_slices", 24)))


func _stat(k: String, v := 1) -> void:
	stats[k] = int(stats.get(k, 0)) + v


func c(section: String) -> Dictionary:
	return cfg[section]


# ---------------------------------------------------------------- facts --------------------------
## Record what happened. `actors`: ids (equal shares) or [[id, share permille], ...]. Returns the event id, or -1
## when the catalog refuses it: an unknown type, a NEUTRAL type while neutral_events is off (SJD-Q01), or a value
## under the type's min_value (SJD-Q12).
func publish(type: String, actors: Array, victims: Array = [], beneficiaries: Array = [], value := 0, tags: Array = []) -> int:
	if not _tix.has(type):
		_stat("refused_unknown")
		return -1
	var def: Dictionary = cfg.events[type]
	if str(def.polarity) == "NEUTRAL" and not bool(cfg.get("neutral_events", false)):
		_stat("refused_neutral")
		return -1
	if value < int(def.get("min_value", 0)):
		_stat("refused_insignificant")
		return -1
	var id := next_event
	next_event += 1
	facts[id] = _pack_fact(int(_tix[type]), day, 0, value, _shares(actors), victims, beneficiaries)
	if not tags.is_empty():
		fact_tags[id] = tags.duplicate()
	if not by_day.has(day):
		by_day[day] = []
	by_day[day].append(id)
	_stat("events")
	return id


## Actors as [[id, share permille], ...]: plain ids share equally.
static func _shares(actors: Array) -> Array:
	var out := []
	for a in actors:
		if a is Array:
			out.append([int(a[0]), int(a[1])])
		else:
			out.append([int(a), JudgmentMath.ONE / maxi(1, actors.size())])
	return out


static func _pack_fact(type: int, d: int, rev: int, value: int, actors: Array, victims: Array, beneficiaries: Array) -> PackedInt64Array:
	var f := PackedInt64Array([type, d, rev, value, actors.size()])
	for a in actors:
		f.append(int(a[0]))
		f.append(int(a[1]))
	f.append(victims.size())
	for v in victims:
		f.append(int(v))
	f.append(beneficiaries.size())
	for b in beneficiaries:
		f.append(int(b))
	return f


static func _fact_actors(f: PackedInt64Array) -> Array:
	var out := []
	for i in f[F_NA]:
		out.append([f[F_NA + 1 + 2 * i], f[F_NA + 2 + 2 * i]])
	return out


## Victims (`which` 0) or beneficiaries (1) of a packed fact.
static func _fact_people(f: PackedInt64Array, which: int) -> Array:
	var at := F_NA + 1 + 2 * f[F_NA]
	if which == 1:
		at += 1 + f[at]
	var out := []
	for i in f[at]:
		out.append(f[at + 1 + i])
	return out


func has_fact(ev: int) -> bool:
	return facts.has(ev)


## A readable view of a fact: {id, type, day, actors, victims, beneficiaries, value, tags, revision[, original_actors]},
## or {} when there is none (never known, or retired past the horizon).
func fact(ev: int) -> Dictionary:
	if not facts.has(ev):
		return {}
	var f: PackedInt64Array = facts[ev]
	var out := {"id": ev, "type": _types[f[F_TYPE]], "day": f[F_DAY], "actors": _fact_actors(f), "victims": _fact_people(f, 0),
		"beneficiaries": _fact_people(f, 1), "value": f[F_VALUE], "tags": fact_tags.get(ev, []).duplicate(), "revision": f[F_REV]}
	if fact_orig.has(ev):
		out.original_actors = (fact_orig[ev] as Array).duplicate(true)
	return out


func definition(type: String) -> Dictionary:
	return (cfg.events as Dictionary).get(type, {})


## An explicit correction of the facts (spec s.3.1: events are immutable; a mistake is corrected by a revision that
## keeps the original). Those who learn of it re-judge through correct().
func revise_fact(ev: int, actors: Array) -> void:
	if not facts.has(ev):
		return
	var f: PackedInt64Array = facts[ev]
	if not fact_orig.has(ev):
		fact_orig[ev] = _fact_actors(f)
	facts[ev] = _pack_fact(f[F_TYPE], f[F_DAY], f[F_REV] + 1, f[F_VALUE], _shares(actors), _fact_people(f, 0), _fact_people(f, 1))


# ---------------------------------------------------------------- belief and memory --------------
static func _pack_mem(type: int, d: int, src: int, by: int, hops: int, conf: int, sal: int, actors: Array) -> PackedInt64Array:
	var m := PackedInt64Array([type, d, src, by, hops, conf, sal, actors.size()])
	for a in actors:
		m.append(int(a[0]))
		m.append(int(a[1]))
	return m


static func _mem_actors(m: PackedInt64Array) -> Array:
	var out := []
	for i in m[M_NA]:
		out.append([m[M_NA + 1 + 2 * i], m[M_NA + 2 + 2 * i]])
	return out


static func _mem_names(m: PackedInt64Array, who: int) -> bool:
	for i in m[M_NA]:
		if m[M_NA + 1 + 2 * i] == who:
			return true
	return false


## What `observer` holds about event `ev` ({type, day, actors, src, by, hops, conf, sal}), or {}.
func belief(observer: int, ev: int) -> Dictionary:
	_cu(observer)
	var mem: Dictionary = memories.get(observer, {})
	if not mem.has(ev):
		return {}
	var m: PackedInt64Array = mem[ev]
	return {"type": _types[m[M_TYPE]], "day": m[M_DAY], "actors": _mem_actors(m), "src": SOURCES[m[M_SRC]], "by": m[M_BY],
		"hops": m[M_HOPS], "conf": m[M_CONF], "sal": m[M_SAL]}


func memory_count(observer: int) -> int:
	_cu(observer)
	return (memories.get(observer, {}) as Dictionary).size()


## `observer` saw it (witnessed) or took part in it (participant): firsthand, full confidence by default.
func observe(ev: int, observer: int, src := "witnessed") -> void:
	if not facts.has(ev):
		return
	learn(observer, ev, src, -1, 0, int(c("belief")[src]), _fact_actors(facts[ev]))


## Every person in `observers` sees event `ev` (sorted, so the order is fixed); the victims and beneficiaries as
## participants.
func observe_all(ev: int, observers: Array) -> void:
	if not facts.has(ev):
		return
	var f: PackedInt64Array = facts[ev]
	var involved := _fact_people(f, 0) + _fact_people(f, 1)
	var ids := observers.duplicate()
	for v in involved:
		if not ids.has(v):
			ids.append(v)
	ids.sort()
	for o in ids:
		observe(ev, int(o), "participant" if involved.has(o) else "witnessed")


## Take in a belief about `ev` and judge by it. A belief already held at the same or higher confidence about the same
## actors changes nothing (gossip heard twice adds nothing); a stronger or corrected one replaces it and its
## contribution (spec s.5.1). Returns true when anything changed.
func learn(observer: int, ev: int, src: String, by: int, hops: int, conf: int, actors: Array) -> bool:
	_cu(observer)
	if not facts.has(ev):
		return false
	if not memories.has(observer):
		memories[observer] = {}
		_add_person(observer)
	var mem: Dictionary = memories[observer]
	var had := mem.has(ev)
	var old_sal := 0
	if had:
		var old: PackedInt64Array = mem[ev]
		if old[M_CONF] >= conf and _same_actors(_mem_actors(old), actors):
			_stat("dup_ignored")
			return false
		old_sal = old[M_SAL]
	elif src in ["told", "rumour"] and has_contribution(observer, ev):
		_stat("dup_ignored")                       # judged before and since forgotten: hearing it again adds nothing
		return false
	var f: PackedInt64Array = facts[ev]
	var t := f[F_TYPE]
	var sal := JudgmentMath.scale(_sev[t], conf) if _pol[t] != 0 else int(c("memory").get("neutral_salience", 500))
	mem[ev] = _pack_mem(t, f[F_DAY], SOURCES.find(src), by, hops, conf, maxi(sal, old_sal), actors)
	_stat("beliefs")
	_judge(observer, ev)
	_bound(observer)
	return true


static func _same_actors(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if int(a[i][0]) != int(b[i][0]) or int(a[i][1]) != int(b[i][1]):
			return false
	return true


## The observer learns the truth of a corrected event (revise_fact), or that it was someone else (new_actors): the
## old contribution is taken back and the new one posted (spec s.15 "Belief correction").
func correct(observer: int, ev: int, new_actors: Array = []) -> void:
	_cu(observer)
	var mem: Dictionary = memories.get(observer, {})
	if not facts.has(ev) or not mem.has(ev):
		return
	var m: PackedInt64Array = mem[ev]
	var acts: Array = _fact_actors(facts[ev]) if new_actors.is_empty() else _shares(new_actors)
	mem[ev] = _pack_mem(m[M_TYPE], m[M_DAY], m[M_SRC], m[M_BY], m[M_HOPS], maxi(m[M_CONF], int(c("belief").witnessed)), m[M_SAL], acts)
	_stat("corrections")
	_judge(observer, ev)


## Keep `observer`'s memories within memory.capacity: the least salient goes first (fading ones before permanent
## ones), then the oldest event.
func _bound(observer: int) -> void:
	var mem: Dictionary = memories[observer]
	while mem.size() > _cap:
		var worst := -1
		var w_perm := 0
		var w_sal := 0
		for ev in mem:
			var m: PackedInt64Array = mem[ev]
			var perm := _perm[m[M_TYPE]]
			var sal := m[M_SAL]
			if worst < 0 or perm < w_perm or (perm == w_perm and (sal < w_sal or (sal == w_sal and int(ev) < worst))):
				worst = int(ev)
				w_perm = perm
				w_sal = sal
		_forget(observer, worst)


## Forget a memory. Its points stay in the ledger (unless retract_on_forget); its contribution record goes too, since
## only a held belief can be corrected, and the event's knowers keep the dedup key until the event retires, so hearing
## of it again adds nothing (memory use stays within capacity per person, not per event known).
func _forget(observer: int, ev: int) -> void:
	(memories[observer] as Dictionary).erase(ev)
	_stat("forgotten")
	if _retract:
		_post(observer, ev, {})
	else:
		(contrib.get(observer, {}) as Dictionary).erase(ev)


# ---------------------------------------------------------------- interpretation -----------------
## How `observer` reads what `actor` did in event `ev`, believing the actors `believed`: the signed interpretation P
## (permille, spec s.4) and its parts. Hierarchical: the affected party reads it fully; an accomplice approves; others
## by their tie to the affected (kin, friend, a rival reverses it); loyalty to the actor softens condemnation; on
## ambiguous events only, prior judgment of the actor may bias the reading, capped (SJD-Q05).
func interpret(observer: int, ev: int, actor: int, believed: Array) -> Dictionary:
	var ic := c("interpret")
	var f: PackedInt64Array = facts[ev]
	var good := _pol[f[F_TYPE]] == 1
	var affected := _fact_people(f, 1 if good else 0)
	var parts := {}
	var p := 0
	if affected.has(observer):
		p = int(ic.affected)
		parts.role = "affected"
	elif not good and _names(believed, observer):
		p = int(ic.accomplice)
		parts.role = "accomplice"
	else:
		parts.role = "bystander"
		p = int(ic.bystander)
		var best := -1
		for v in affected:
			var pv := int(ic.bystander)
			var why := "bystander"
			if social.kin(observer, int(v)):
				pv = int(ic.kin)
				why = "kin of %d" % int(v)
			elif social.friends(observer, int(v)):
				pv = int(ic.friend)
				why = "friend of %d" % int(v)
			elif net(observer, int(v)) <= int(ic.rival_net_at):
				pv = int(ic.rival)
				why = "rival of %d" % int(v)
			if best < 0 or absi(pv) > absi(p) or (absi(pv) == absi(p) and pv > p):
				p = pv
				parts.role = why
				best = 1
	parts.base = p
	if not good and p > 0 and parts.role != "affected":
		if social.kin(observer, actor):
			p = JudgmentMath.scale(p, int(ic.kin_of_actor))
			parts.loyalty = "kin of actor"
		elif social.friends(observer, actor):
			p = JudgmentMath.scale(p, int(ic.friend_of_actor))
			parts.loyalty = "friend of actor"
	if _amb[f[F_TYPE]] == 1 and parts.role != "affected":
		var bias := JudgmentMath.clampi_(JudgmentMath.mul_div(net(observer, actor), int(ic.prior_bias_permille_per_point), 1000),
				-int(ic.prior_bias_cap), int(ic.prior_bias_cap))
		p += bias if good else -bias
		parts.prior_bias = bias if good else -bias
	p = JudgmentMath.clampi_(p, -JudgmentMath.ONE, JudgmentMath.ONE)
	parts.p = p
	return parts


## Whether an actor list ([[id, share], ...]) names `who`.
static func _names(actors: Array, who: int) -> bool:
	for a in actors:
		if int(a[0]) == who:
			return true
	return false


## The points `observer` credits for `actor`'s part in `ev`: [good, bad] milli-points (one of them 0), with the parts
## in last_trace. Impact I = S x P x C (confidence_policy multiplier), or S x P above confidence_threshold, by share.
func evaluate(observer: int, ev: int, actor: int, share: int, conf: int, believed: Array) -> Array:
	var t: int = facts[ev][F_TYPE]
	if _pol[t] == 0 or actor == observer:
		return [0, 0]
	var parts := interpret(observer, ev, actor, believed)
	var bc := c("belief")
	var pol := str(bc.confidence_policy)
	var impact := 0
	if (pol == "threshold" or pol == "both") and conf < int(bc.confidence_threshold):
		impact = 0
	elif pol == "threshold":
		impact = JudgmentMath.scale(_sev[t], int(parts.p))
	else:
		impact = JudgmentMath.mul_div(_sev[t] * int(parts.p), conf, 1000000)
	impact = JudgmentMath.scale(impact, share)
	parts.severity = _sev[t]
	parts.confidence = conf
	parts.impact = impact
	last_trace = parts
	var good := _pol[t] == 1
	if impact == 0:
		return [0, 0]
	if (impact > 0) == good:
		return [absi(impact), 0]
	return [0, absi(impact)]


## Recompute `observer`'s contributions for `ev` from their belief.
func _judge(observer: int, ev: int) -> void:
	var m: PackedInt64Array = memories[observer][ev]
	var believed := _mem_actors(m)
	var want := {}
	for a in believed:
		var gb := evaluate(observer, ev, int(a[0]), int(a[1]), m[M_CONF], believed)
		if gb[0] != 0 or gb[1] != 0:
			want[int(a[0])] = gb
	_post(observer, ev, want)
	var k: PackedInt64Array = knowers.get(ev, PackedInt64Array())
	var i := k.bsearch(observer)
	if i >= k.size() or k[i] != observer:
		k.insert(i, observer)
		knowers[ev] = k


## Replace `observer`'s contributions for `ev` with `want` ({actor: [good, bad]}): the difference goes to the
## ledgers, which never go below 0 (spec s.5.1).
func _post(observer: int, ev: int, want: Dictionary) -> void:
	if not contrib.has(observer):
		contrib[observer] = {}
		_add_person(observer)
	var mine: Dictionary = contrib[observer]
	var had := {}
	if mine.has(ev):
		var row: PackedInt64Array = mine[ev]
		for i in range(0, row.size(), 3):
			had[row[i]] = [row[i + 1], row[i + 2]]
	var actors := {}
	for a in had:
		actors[a] = true
	for a in want:
		actors[a] = true
	var ids := actors.keys()
	ids.sort()
	var out := PackedInt64Array()
	for a in ids:
		var o: Array = had.get(a, [0, 0])
		var n: Array = want.get(a, [0, 0])
		if int(n[0]) != 0 or int(n[1]) != 0:
			out.append(int(a))
			out.append(int(n[0]))
			out.append(int(n[1]))
		if o[0] == n[0] and o[1] == n[1]:
			continue
		var was := int(o[0]) != 0 or int(o[1]) != 0
		var now := int(n[0]) != 0 or int(n[1]) != 0
		_ledger_add(observer, int(a), int(n[0]) - int(o[0]), int(n[1]) - int(o[1]), 1 if now and not was else (-1 if was and not now else 0))
		_stat("contributions")
	if out.is_empty():
		mine.erase(ev)
	else:
		mine[ev] = out


func has_contribution(observer: int, ev: int) -> bool:
	_cu(observer)
	if (contrib.get(observer, {}) as Dictionary).has(ev):
		return true
	if not knowers.has(ev):
		return false
	var k: PackedInt64Array = knowers[ev]
	var i := k.bsearch(observer)
	return i < k.size() and k[i] == observer


## The contribution `observer` holds for `actor`'s part in `ev`: [good, bad] ([0, 0] if none).
func contribution(observer: int, ev: int, actor: int) -> Array:
	_cu(observer)
	var row: PackedInt64Array = (contrib.get(observer, {}) as Dictionary).get(ev, PackedInt64Array())
	for i in range(0, row.size(), 3):
		if row[i] == actor:
			return [row[i + 1], row[i + 2]]
	return [0, 0]


# ---------------------------------------------------------------- ledgers ------------------------
## [good, bad, contributions, effective good, effective bad] (a copy; [0, 0, 0, 0, 0] when none).
func ledger(observer: int, subject: int) -> Array:
	_cu(observer)
	var mine: Dictionary = ledgers.get(observer, {})
	if not mine.has(subject):
		return [0, 0, 0, 0, 0]
	return Array(mine[subject])


func _ledger_add(observer: int, subject: int, dg: int, db: int, dn: int) -> void:
	if not ledgers.has(observer):
		ledgers[observer] = {}
		_add_person(observer)
	var mine: Dictionary = ledgers[observer]
	var l: PackedInt64Array
	if mine.has(subject):
		l = mine[subject]
	else:
		l = PackedInt64Array([0, 0, 0, 0, 0])
		_stat("ledgers")
	l[0] = maxi(0, l[0] + dg)
	l[1] = maxi(0, l[1] + db)
	l[2] = l[2] + dn
	l[3] = maxi(0, l[3] + dg)
	l[4] = maxi(0, l[4] + db)
	mine[subject] = l


## Set a ledger's GOOD and BAD outright (tests and fixtures: an opinion formed before the scenario starts).
func set_ledger(observer: int, subject: int, good_points: int, bad_points: int) -> void:
	_cu(observer)
	if not ledgers.has(observer):
		ledgers[observer] = {}
		_add_person(observer)
	var l: PackedInt64Array = (ledgers[observer] as Dictionary).get(subject, PackedInt64Array([0, 0, 0, 0, 0]))
	l[0] = good_points
	l[1] = bad_points
	l[3] = good_points
	l[4] = bad_points
	ledgers[observer][subject] = l


## NET judgment of `subject` by `observer`, milli-points: GOOD - BAD (the effective view when one fades).
func net(observer: int, subject: int) -> int:
	_cu(observer)
	var mine: Dictionary = ledgers.get(observer, {})
	if not mine.has(subject):
		return 0
	var l: PackedInt64Array = mine[subject]
	return l[3] - l[4] if _eff_fade > 0 else l[0] - l[1]


func good(observer: int, subject: int) -> int:
	return int(ledger(observer, subject)[0])


func bad(observer: int, subject: int) -> int:
	return int(ledger(observer, subject)[1])


## The judgment as a decision factor on the spec's 0..100 scale (milli): disposition_mid + NET, clamped (spec s.7.3:
## NET -6.59 -> 43.41).
func disposition(observer: int, subject: int) -> int:
	return JudgmentMath.clampi_(int(c("decision").disposition_mid) + net(observer, subject), 0, 100000)


## Large GOOD and BAD together (SJD-Q04): min(GOOD, BAD), clamped to 0..100 points.
func ambivalence(observer: int, subject: int) -> int:
	var l := ledger(observer, subject)
	return mini(100000, mini(int(l[0]), int(l[1])))


## The subject `observer` thinks worst of (lowest NET, then lowest id), or -999 when they judge nobody below 0.
func most_disliked(observer: int, besides := -999) -> int:
	_cu(observer)
	var best := -999
	var best_net := 0
	var mine: Dictionary = ledgers.get(observer, {})
	var ids := mine.keys()
	ids.sort()
	for s in ids:
		var v := net(observer, int(s))
		if int(s) != besides and v < best_net:
			best = int(s)
			best_net = v
	return best


# ---------------------------------------------------------------- information sharing ------------
## Two people spend time together (Relations.share's hour, or a test): each may tell the other (tell).
func meet(a: int, b: int) -> int:
	if not memories.has(a) and not memories.has(b):
		return 0                                   # neither knows anything to tell
	var t := Time.get_ticks_usec()
	var lo := mini(a, b)
	var hi := maxi(a, b)
	var k := tell(lo, hi) + tell(hi, lo)
	timing.meet_us = int(timing.get("meet_us", 0)) + Time.get_ticks_usec() - t
	return k


## `teller` tells `listener` up to gossip.per_meeting of their most salient memories the listener does not hold
## (deterministic: salience, then event id), within the teller's daily_budget, only to someone they judge above
## share_net_at, never past max_hops from a firsthand source, never under min_confidence, never about the
## listener's own deed. The listener's confidence: the teller's x hop_factor x credibility (their judgment of the
## teller). A seeded hash may make a rumour name the wrong actor (misattribute_permille; the teller's most disliked).
## Returns how many were told.
func tell(teller: int, listener: int) -> int:
	if teller == listener or not memories.has(teller):
		return 0
	_cu(teller)
	_cu(listener)
	var mem: Dictionary = memories.get(teller, {})
	if mem.is_empty():
		return 0
	var g := c("gossip")
	if int(told_today.get(teller, 0)) >= int(g.daily_budget) or net(teller, listener) <= int(g.share_net_at):
		return 0
	var bc := c("belief")
	var heard: Dictionary = memories.get(listener, {})
	var pick := []
	for ev in mem:
		var m: PackedInt64Array = mem[ev]
		if not facts.has(ev) or m[M_HOPS] >= int(g.max_hops) or m[M_CONF] < int(g.min_confidence):
			continue
		if heard.has(ev) or has_contribution(listener, ev) or _mem_names(m, listener):
			continue
		pick.append([-m[M_SAL], int(ev)])
	if pick.is_empty():
		return 0
	pick.sort()
	var cred := JudgmentMath.clampi_(int(bc.credibility_base) + JudgmentMath.mul_div(net(listener, teller), int(bc.credibility_permille_per_point), 1000),
			int(bc.credibility_min), JudgmentMath.ONE)
	var k := 0
	for p in pick:
		if k >= int(g.per_meeting) or int(told_today.get(teller, 0)) >= int(g.daily_budget):
			break
		var ev := int(p[1])
		var m: PackedInt64Array = mem[ev]
		var conf := JudgmentMath.mul_div(m[M_CONF] * int(bc.hop_factor), cred, 1000000)
		if conf < int(g.min_confidence):
			continue
		var actors := _mem_actors(m)
		if int(g.misattribute_permille) > 0 and JudgmentMath.roll([world_seed, ev, teller, listener]) < int(g.misattribute_permille):
			var other := most_disliked(teller, int(actors[0][0]))
			if other != -999 and other != listener:
				actors = [[other, JudgmentMath.ONE]]
				_stat("misattributed")
		var src := "told" if m[M_HOPS] == 0 else "rumour"
		learn(listener, ev, src, teller, m[M_HOPS] + 1, conf, actors)
		told_today[teller] = int(told_today.get(teller, 0)) + 1
		_stat("tellings")
		k += 1
	return k


# ---------------------------------------------------------------- the day ------------------------
## A new day, all at once: begin_day then finish_dawn (the reference the sliced update must equal).
func advance_day(d: int) -> void:
	begin_day(d)
	finish_dawn()


## Dawn, the global part only: tellings reset; events past memory.horizon_days retire (their facts and dedup keys go
## now; each knower's record of them goes at their catch-up); everyone with records is queued for their own update
## (fading, forgetting, the optional effective view), applied by dawn_hour over the day or on first touch. The queue is
## a copy of the sorted list of people, so beginning a day costs no per-person work.
func begin_day(d: int) -> void:
	if d <= day:
		return
	finish_dawn()
	_steps = d - day
	day = d
	told_today.clear()
	var cutoff := d - int(c("memory").horizon_days)
	var days := by_day.keys()
	days.sort()
	for dd in days:
		if int(dd) >= cutoff:
			break
		for ev in by_day[dd]:
			if facts.has(ev):
				facts.erase(ev)
				fact_tags.erase(ev)
				fact_orig.erase(ev)
				knowers.erase(ev)
				_retiring[ev] = true
				_stat("expired")
		by_day.erase(dd)
	_queue = _people.duplicate()          # a copy: packed arrays are shared by reference, and people may join mid-day
	_qi = 0
	_early.clear()
	_active = not _queue.is_empty()
	if not _active:
		_retiring.clear()


func _add_person(o: int) -> void:
	var i := _people.bsearch(o)
	if i >= _people.size() or _people[i] != o:
		_people.insert(i, o)


## Whether `o`'s update for the day is still to be applied (queued at dawn, not yet reached nor caught up on touch).
func pending(o: int) -> bool:
	if not _active:
		return false
	var i := _queue.bsearch(o)
	return i >= _qi and i < _queue.size() and _queue[i] == o and not _early.has(o)


## One hour's share of the queued update: ceil(queued / memory.dawn_slices) people, in id order. Returns how many queue
## places are left.
func dawn_hour() -> int:
	return dawn_slice(ceili(float(_queue.size()) / float(_slices)))


## Bring up to `k` more queued people up to date (those already caught up on touch are skipped, not counted).
func dawn_slice(k: int) -> int:
	if not _active:
		return 0
	var t := Time.get_ticks_usec()
	var done := 0
	while _qi < _queue.size() and done < k:
		var o := _queue[_qi]
		_qi += 1
		if _early.has(o):
			_early.erase(o)
			continue
		_dawn_one(o)
		done += 1
	if _qi >= _queue.size():
		_active = false
		_queue = PackedInt64Array()
		_qi = 0
		_early.clear()
		_retiring.clear()
	timing.dawn_us = int(timing.get("dawn_us", 0)) + Time.get_ticks_usec() - t
	return _queue.size() - _qi


func finish_dawn() -> void:
	dawn_slice(1 << 40)


## Catch-up on touch: apply today's update to `o` if it is still pending, before anything reads or changes their
## records.
func _cu(o: int) -> void:
	if not _active or not pending(o):
		return
	_early[o] = true
	_dawn_one(o)


## One person's daily update: their memories fade (for each day the update covers) and the faint are forgotten, then
## their records of retired events go, then their effective view fades.
func _dawn_one(o: int) -> void:
	var mem: Dictionary = memories.get(o, {})
	if not mem.is_empty():
		var gone := []
		for ev in mem:
			var m: PackedInt64Array = mem[ev]
			if _perm[m[M_TYPE]] == 1:
				continue
			var s := m[M_SAL]
			for i in _steps:
				s -= JudgmentMath.scale(s, _fade)
			m[M_SAL] = s
			mem[ev] = m
			if s < _below:
				gone.append(int(ev))
		gone.sort()
		for ev in gone:
			_forget(o, ev)
	if not _retiring.is_empty() and contrib.has(o):
		var mine: Dictionary = contrib[o]
		for ev in mine.keys():
			if _retiring.has(ev):
				mine.erase(ev)
	if _eff_fade > 0 and ledgers.has(o):
		var mine: Dictionary = ledgers[o]
		for s in mine:
			var l: PackedInt64Array = mine[s]
			for i in _steps:
				l[3] = l[3] - JudgmentMath.scale(l[3], _eff_fade)
				l[4] = l[4] - JudgmentMath.scale(l[4], _eff_fade)
			mine[s] = l


# ---------------------------------------------------------------- inspection ---------------------
## Developer inspector (spec s.14): what `observer` believes and thinks of `subject`, and why.
func inspect(observer: int, subject: int) -> Dictionary:
	var l := ledger(observer, subject)
	var why := []
	var mem: Dictionary = memories.get(observer, {})
	var evs := mem.keys()
	evs.sort()
	for ev in evs:
		if _mem_names(mem[ev], subject):
			var b := belief(observer, int(ev))
			why.append({"event": int(ev), "type": b.type, "src": b.src, "by": b.by, "conf": b.conf, "points": contribution(observer, int(ev), subject)})
	return {"good": l[0], "bad": l[1], "net": int(l[0]) - int(l[1]), "contributions": l[2], "memories": why}


func counts() -> Dictionary:
	finish_dawn()
	var nm := 0
	var nc := 0
	var nl := 0
	for o in memories:
		nm += (memories[o] as Dictionary).size()
	for o in contrib:
		for ev in contrib[o]:
			nc += (contrib[o][ev] as PackedInt64Array).size() / 3
	for o in ledgers:
		nl += (ledgers[o] as Dictionary).size()
	return {"facts": facts.size(), "memories": nm, "contributions": nc, "ledgers": nl}


# ---------------------------------------------------------------- saving -------------------------
## The provisional save section (World "judgment"; SAVE_VERSION unchanged: an older save simply has none). Lists
## sorted by id, so the same state always writes the same text. Any pending daily update is applied first (it gives
## the same state whenever it is applied).
func to_dict() -> Dictionary:
	if not unread.is_empty():
		return unread.duplicate(true)
	finish_dawn()
	var fs := []
	for id in _sorted(facts):
		var f: PackedInt64Array = facts[id]
		var row := [int(id), _types[f[F_TYPE]], f[F_DAY], _fact_actors(f), _fact_people(f, 0), _fact_people(f, 1),
			f[F_VALUE], fact_tags.get(id, []).duplicate(), f[F_REV], Array(knowers.get(id, PackedInt64Array()))]
		if fact_orig.has(id):
			row.append((fact_orig[id] as Array).duplicate(true))
		fs.append(row)
	var ms := []
	var cs := []
	var ls := []
	for o in _sorted(memories):
		var mem: Dictionary = memories[o]
		for ev in _sorted(mem):
			var m: PackedInt64Array = mem[ev]
			ms.append([int(o), int(ev), _types[m[M_TYPE]], m[M_DAY], _mem_actors(m), SOURCES[m[M_SRC]], m[M_BY], m[M_HOPS], m[M_CONF], m[M_SAL]])
	for o in _sorted(contrib):
		for ev in _sorted(contrib[o]):
			var row: PackedInt64Array = contrib[o][ev]
			for i in range(0, row.size(), 3):
				cs.append([int(o), int(ev), row[i], row[i + 1], row[i + 2]])
	for o in _sorted(ledgers):
		for s in _sorted(ledgers[o]):
			var l: PackedInt64Array = ledgers[o][s]
			ls.append([int(o), int(s), l[0], l[1], l[2], l[3], l[4]])
	var tt := []
	for t in _sorted(told_today):
		tt.append([int(t), int(told_today[t])])
	return {"format": FORMAT, "version": VERSION, "day": day, "next_event": next_event, "facts": fs, "memories": ms,
		"contrib": cs, "ledgers": ls, "told_today": tt}


static func _sorted(d: Dictionary) -> Array:
	var ks := d.keys()
	ks.sort()
	return ks


## Load a saved section. {} (a save from before judgment: every Build 16 save) gives an empty store. A section of an
## unknown format, a newer version, or naming an event type this catalog lacks is refused with a message and kept
## unread, written back unchanged, never dropped (CLAUDE.md section 7). Returns "" or the reason it was not read.
func load_dict(d: Dictionary) -> String:
	for x in [facts, fact_tags, fact_orig, knowers, by_day, memories, contrib, ledgers, told_today, _early, _retiring]:
		(x as Dictionary).clear()
	_people = PackedInt64Array()
	_queue = PackedInt64Array()
	_qi = 0
	_active = false
	unread = {}
	if d.is_empty():
		return ""
	var m := migrate(d)
	if not m.has("error"):
		for r in m.facts:
			if not _tix.has(str(r[1])):
				m = {"error": "judgment section names an event type '%s' this game does not know: kept unread" % str(r[1])}
				break
	if not m.has("error"):
		for r in m.memories:
			if not _tix.has(str(r[2])):
				m = {"error": "judgment section names an event type '%s' this game does not know: kept unread" % str(r[2])}
				break
	if m.has("error"):
		unread = d.duplicate(true)
		return str(m.error)
	day = int(m.day)
	next_event = int(m.next_event)
	for r in m.facts:
		var id := int(r[0])
		facts[id] = _pack_fact(int(_tix[str(r[1])]), int(r[2]), int(r[8]), int(r[6]), _ints2(r[3]), (r[4] as Array).map(func(x): return int(x)),
				(r[5] as Array).map(func(x): return int(x)))
		if not (r[7] as Array).is_empty():
			fact_tags[id] = (r[7] as Array).duplicate()
		var kn := PackedInt64Array()
		for o in r[9]:
			kn.append(int(o))
		kn.sort()
		if not kn.is_empty():
			knowers[id] = kn
		if (r as Array).size() > 10:
			fact_orig[id] = _ints2(r[10])
		if not by_day.has(int(r[2])):
			by_day[int(r[2])] = []
		by_day[int(r[2])].append(id)
	for r in m.memories:
		if not memories.has(int(r[0])):
			memories[int(r[0])] = {}
		memories[int(r[0])][int(r[1])] = _pack_mem(int(_tix[str(r[2])]), int(r[3]), SOURCES.find(str(r[5])), int(r[6]), int(r[7]), int(r[8]), int(r[9]), _ints2(r[4]))
	for r in m.contrib:
		var o := int(r[0])
		var ev := int(r[1])
		if not contrib.has(o):
			contrib[o] = {}
		var row: PackedInt64Array = (contrib[o] as Dictionary).get(ev, PackedInt64Array())
		row.append_array(PackedInt64Array([int(r[2]), int(r[3]), int(r[4])]))
		contrib[o][ev] = row
	for r in m.ledgers:
		if not ledgers.has(int(r[0])):
			ledgers[int(r[0])] = {}
		ledgers[int(r[0])][int(r[1])] = PackedInt64Array([int(r[2]), int(r[3]), int(r[4]), int(r[5]), int(r[6])])
	for r in m.told_today:
		told_today[int(r[0])] = int(r[1])
	for d2 in [memories, contrib, ledgers]:
		for o in d2:
			_add_person(int(o))
	return ""


static func _ints2(a) -> Array:
	return (a as Array).map(func(x): return [int(x[0]), int(x[1])])


## Bring a saved section up to this version, or {"error": why}. Version 0 is the prototype's first draft layout
## (points as floats, ledgers as {"o:s": {good, bad}}); kept as the migration path a format change will extend.
## The compact in-memory records of round 2 did not change the saved layout: a round-1 save loads unchanged.
static func migrate(d: Dictionary) -> Dictionary:
	var fmt := str(d.get("format", ""))
	if fmt == "mml-judgment/0":
		var out := {"format": FORMAT, "version": VERSION, "day": int(d.get("day", 0)), "next_event": int(d.get("next_event", 1)),
			"facts": [], "memories": [], "contrib": [], "ledgers": [], "told_today": []}
		var keys: Array = (d.get("ledgers", {}) as Dictionary).keys()
		keys.sort()
		for k in keys:
			var ab: PackedStringArray = str(k).split(":")
			var l: Dictionary = d.ledgers[k]
			var g := roundi(float(l.get("good", 0.0)) * 1000.0)
			var b := roundi(float(l.get("bad", 0.0)) * 1000.0)
			out.ledgers.append([int(ab[0]), int(ab[1]), g, b, 0, g, b])
		return out
	if fmt != FORMAT:
		return {"error": "judgment section of unknown format '%s': kept unread" % fmt}
	if int(d.get("version", 0)) > VERSION:
		return {"error": "judgment section version %d is newer than this game's %d: kept unread" % [int(d.version), VERSION]}
	for k in ["facts", "memories", "contrib", "ledgers"]:
		if not (d.get(k, null) is Array):
			return {"error": "judgment section damaged (no %s): kept unread" % k}
	var out := d.duplicate(true)
	if not out.has("told_today"):
		out.told_today = []
	return out


## A hash of the whole state (determinism tests: same seed and events, same hash).
func state_hash() -> int:
	return JSON.stringify(to_dict()).hash()
