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

const FORMAT := "mml-judgment/1"
const VERSION := 1
const SOURCES := ["participant", "witnessed", "told", "rumour"]

var cfg: Dictionary
var social: JudgmentSocial
var world_seed := 0
var day := 0
var next_event := 1
var facts := {}          # event id -> {id, type, day, actors: [[id, share permille]], victims, beneficiaries, value, tags, revision, knowers: {observer: true}}
var by_day := {}         # day -> [event ids] (horizon expiry)
var memories := {}       # observer -> {event id -> belief: {type, day, actors, src, by, hops, conf, sal}}
var contrib := {}        # observer -> {event id -> {actor: [good, bad]}}
var ledgers := {}        # observer -> {subject -> [good, bad, n, eff_good, eff_bad]}
var told_today := {}     # teller -> tellings today (gossip.daily_budget)
var stats := {}          # counters for diagnostics and performance reports
var unread := {}         # a saved section this version cannot read: kept and written back unchanged (CLAUDE.md s.7)
var last_trace := {}     # the last interpretation's parts (diagnostics: "why was the theft rated 0.55 BAD?")


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


func _stat(k: String, v := 1) -> void:
	stats[k] = int(stats.get(k, 0)) + v


func c(section: String) -> Dictionary:
	return cfg[section]


# ---------------------------------------------------------------- facts --------------------------
## Record what happened. `actors`: ids (equal shares) or [[id, share permille], ...]. Returns the event id, or -1
## when the catalog refuses it: an unknown type, a NEUTRAL type while neutral_events is off (SJD-Q01), or a value
## under the type's min_value (SJD-Q12).
func publish(type: String, actors: Array, victims: Array = [], beneficiaries: Array = [], value := 0, tags: Array = []) -> int:
	var def: Dictionary = (cfg.events as Dictionary).get(type, {})
	if def.is_empty():
		_stat("refused_unknown")
		return -1
	if str(def.polarity) == "NEUTRAL" and not bool(cfg.get("neutral_events", false)):
		_stat("refused_neutral")
		return -1
	if value < int(def.get("min_value", 0)):
		_stat("refused_insignificant")
		return -1
	var acts := []
	for a in actors:
		if a is Array:
			acts.append([int(a[0]), int(a[1])])
		else:
			acts.append([int(a), JudgmentMath.ONE / maxi(1, actors.size())])
	var id := next_event
	next_event += 1
	facts[id] = {"id": id, "type": type, "day": day, "actors": acts, "victims": victims.map(func(x): return int(x)),
		"beneficiaries": beneficiaries.map(func(x): return int(x)), "value": value, "tags": tags.duplicate(), "revision": 0, "knowers": {}}
	if not by_day.has(day):
		by_day[day] = []
	by_day[day].append(id)
	_stat("events")
	return id


func definition(type: String) -> Dictionary:
	return (cfg.events as Dictionary).get(type, {})


## An explicit correction of the facts (spec s.3.1: events are immutable; a mistake is corrected by a revision that
## keeps the original). Those who learn of it re-judge through correct().
func revise_fact(ev: int, actors: Array) -> void:
	var f: Dictionary = facts.get(ev, {})
	if f.is_empty():
		return
	if not f.has("original_actors"):
		f.original_actors = (f.actors as Array).duplicate(true)
	f.actors = actors.map(func(a): return [int(a), JudgmentMath.ONE / maxi(1, actors.size())] if not (a is Array) else [int(a[0]), int(a[1])])
	f.revision = int(f.revision) + 1


# ---------------------------------------------------------------- belief and memory --------------
## What `observer` holds about event `ev`, or {}.
func belief(observer: int, ev: int) -> Dictionary:
	return (memories.get(observer, {}) as Dictionary).get(ev, {})


## `observer` saw it (witnessed) or took part in it (participant): firsthand, full confidence by default.
func observe(ev: int, observer: int, src := "witnessed") -> void:
	var f: Dictionary = facts.get(ev, {})
	if f.is_empty():
		return
	learn(observer, ev, src, -1, 0, int(c("belief")[src]), f.actors)


## Every person in `observers` sees event `ev` (sorted, so the order is fixed); the victims and beneficiaries as
## participants.
func observe_all(ev: int, observers: Array) -> void:
	var f: Dictionary = facts.get(ev, {})
	if f.is_empty():
		return
	var ids := observers.duplicate()
	for v in f.victims + f.beneficiaries:
		if not ids.has(v):
			ids.append(v)
	ids.sort()
	for o in ids:
		observe(ev, int(o), "participant" if (f.victims.has(o) or f.beneficiaries.has(o)) else "witnessed")


## Take in a belief about `ev` and judge by it. A belief already held at the same or higher confidence about the same
## actors changes nothing (gossip heard twice adds nothing); a stronger or corrected one replaces it and its
## contribution (spec s.5.1). Returns true when anything changed.
func learn(observer: int, ev: int, src: String, by: int, hops: int, conf: int, actors: Array) -> bool:
	var f: Dictionary = facts.get(ev, {})
	if f.is_empty():
		return false
	if not memories.has(observer):
		memories[observer] = {}
	var mem: Dictionary = memories[observer]
	var old: Dictionary = mem.get(ev, {})
	if not old.is_empty() and int(old.conf) >= conf and _same_actors(old.actors, actors):
		_stat("dup_ignored")
		return false
	if old.is_empty() and has_contribution(observer, ev) and src in ["told", "rumour"]:
		_stat("dup_ignored")                       # judged before and since forgotten: hearing it again adds nothing
		return false
	var def := definition(str(f.type))
	var sev := int(def.severity)
	var sal := JudgmentMath.scale(sev, conf) if str(def.polarity) != "NEUTRAL" else int(c("memory").get("neutral_salience", 500))
	mem[ev] = {"type": str(f.type), "day": int(f.day), "actors": actors.duplicate(true), "src": src, "by": by, "hops": hops,
		"conf": conf, "sal": maxi(sal, int(old.get("sal", 0)))}
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
	var f: Dictionary = facts.get(ev, {})
	var b := belief(observer, ev)
	if f.is_empty() or b.is_empty():
		return
	var acts: Array = f.actors if new_actors.is_empty() else new_actors.map(func(a): return [int(a), JudgmentMath.ONE / maxi(1, new_actors.size())])
	b.actors = acts.duplicate(true)
	b.conf = maxi(int(b.conf), int(c("belief").witnessed))
	_stat("corrections")
	_judge(observer, ev)


## Keep `observer`'s memories within memory.capacity: the least salient goes first (fading ones before permanent
## ones), then the oldest event.
func _bound(observer: int) -> void:
	var mem: Dictionary = memories[observer]
	var cap := int(c("memory").capacity)
	while mem.size() > cap:
		var worst := -1
		var w_perm := 0
		var w_sal := 0
		for ev in mem:
			var perm := 1 if _permanent(mem[ev]) else 0
			var sal := int(mem[ev].sal)
			if worst < 0 or perm < w_perm or (perm == w_perm and (sal < w_sal or (sal == w_sal and int(ev) < worst))):
				worst = int(ev)
				w_perm = perm
				w_sal = sal
		_forget(observer, worst)


func _permanent(b: Dictionary) -> bool:
	return int(definition(str(b.type)).get("severity", 0)) >= int(c("memory").permanent_severity)


## Whether an actor list ([[id, share], ...]) names `who`.
static func _names(actors: Array, who: int) -> bool:
	for a in actors:
		if int(a[0]) == who:
			return true
	return false


## Forget a memory. Its points stay in the ledger (unless retract_on_forget); its contribution record goes too, since
## only a held belief can be corrected, and the fact's knowers keep the dedup key until the event retires, so hearing
## of it again adds nothing (memory use stays within capacity per person, not per event known).
func _forget(observer: int, ev: int) -> void:
	(memories[observer] as Dictionary).erase(ev)
	_stat("forgotten")
	if bool(c("memory").retract_on_forget):
		_post(observer, ev, {})
	else:
		(contrib.get(observer, {}) as Dictionary).erase(ev)


# ---------------------------------------------------------------- interpretation -----------------
## How `observer` reads what `actor` did in event `ev`, believing `b`: the signed interpretation P (permille, spec
## s.4) and its parts. Hierarchical: the affected party reads it fully; an accomplice approves; others by their tie
## to the affected (kin, friend, a rival reverses it); loyalty to the actor softens condemnation; on ambiguous events
## only, prior judgment of the actor may bias the reading, capped (SJD-Q05).
func interpret(observer: int, ev: int, actor: int, b: Dictionary) -> Dictionary:
	var ic := c("interpret")
	var f: Dictionary = facts[ev]
	var def := definition(str(f.type))
	var good := str(def.polarity) == "GOOD"
	var affected: Array = f.beneficiaries if good else f.victims
	var parts := {}
	var p := 0
	if affected.has(observer):
		p = int(ic.affected)
		parts.role = "affected"
	elif not good and _names(b.actors, observer):
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
	if bool(def.get("ambiguous", false)) and parts.role != "affected":
		var bias := JudgmentMath.clampi_(JudgmentMath.mul_div(net(observer, actor), int(ic.prior_bias_permille_per_point), 1000),
				-int(ic.prior_bias_cap), int(ic.prior_bias_cap))
		p += bias if good else -bias
		parts.prior_bias = bias if good else -bias
	p = JudgmentMath.clampi_(p, -JudgmentMath.ONE, JudgmentMath.ONE)
	parts.p = p
	return parts


## The points `observer` credits for `actor`'s part in `ev`: [good, bad] milli-points (one of them 0), with the parts
## in last_trace. Impact I = S x P x C (confidence_policy multiplier), or S x P above confidence_threshold, by share.
func evaluate(observer: int, ev: int, actor: int, share: int, b: Dictionary) -> Array:
	var f: Dictionary = facts[ev]
	var def := definition(str(f.type))
	if str(def.polarity) == "NEUTRAL" or actor == observer:
		return [0, 0]
	var parts := interpret(observer, ev, actor, b)
	var bc := c("belief")
	var conf := int(b.conf)
	var pol := str(bc.confidence_policy)
	var impact := 0
	if (pol == "threshold" or pol == "both") and conf < int(bc.confidence_threshold):
		impact = 0
	elif pol == "threshold":
		impact = JudgmentMath.scale(int(def.severity), int(parts.p))
	else:
		impact = JudgmentMath.mul_div(int(def.severity) * int(parts.p), conf, 1000000)
	impact = JudgmentMath.scale(impact, share)
	parts.severity = int(def.severity)
	parts.confidence = conf
	parts.impact = impact
	last_trace = parts
	var good := str(def.polarity) == "GOOD"
	if impact == 0:
		return [0, 0]
	if (impact > 0) == good:
		return [absi(impact), 0]
	return [0, absi(impact)]


## Recompute `observer`'s contributions for `ev` from their belief.
func _judge(observer: int, ev: int) -> void:
	var b := belief(observer, ev)
	var want := {}
	for a in b.actors:
		var gb := evaluate(observer, ev, int(a[0]), int(a[1]), b)
		if gb[0] != 0 or gb[1] != 0:
			want[int(a[0])] = gb
	_post(observer, ev, want)
	(facts[ev].knowers as Dictionary)[observer] = true


## Replace `observer`'s contributions for `ev` with `want` ({actor: [good, bad]}): the difference goes to the
## ledgers, which never go below 0 (spec s.5.1).
func _post(observer: int, ev: int, want: Dictionary) -> void:
	if not contrib.has(observer):
		contrib[observer] = {}
	var mine: Dictionary = contrib[observer]
	var had: Dictionary = mine.get(ev, {})
	var actors := {}
	for a in had:
		actors[a] = true
	for a in want:
		actors[a] = true
	var ids := actors.keys()
	ids.sort()
	for a in ids:
		var o: Array = had.get(a, [0, 0])
		var n: Array = want.get(a, [0, 0])
		if o[0] == n[0] and o[1] == n[1]:
			continue
		var l := ledger(observer, int(a), true)
		l[0] = maxi(0, int(l[0]) + int(n[0]) - int(o[0]))
		l[1] = maxi(0, int(l[1]) + int(n[1]) - int(o[1]))
		l[3] = maxi(0, int(l[3]) + int(n[0]) - int(o[0]))
		l[4] = maxi(0, int(l[4]) + int(n[1]) - int(o[1]))
		var was := int(o[0]) != 0 or int(o[1]) != 0
		var now := int(n[0]) != 0 or int(n[1]) != 0
		l[2] = int(l[2]) + (1 if now and not was else (-1 if was and not now else 0))
		_stat("contributions")
	if want.is_empty():
		mine.erase(ev)
	else:
		mine[ev] = want.duplicate(true)


func has_contribution(observer: int, ev: int) -> bool:
	return (contrib.get(observer, {}) as Dictionary).has(ev) or (facts.has(ev) and (facts[ev].knowers as Dictionary).has(observer))


# ---------------------------------------------------------------- ledgers ------------------------
## [good, bad, contributions, effective good, effective bad] (made on first use when `make`).
func ledger(observer: int, subject: int, make := false) -> Array:
	var mine: Dictionary = ledgers.get(observer, {})
	if mine.has(subject):
		return mine[subject]
	if not make:
		return [0, 0, 0, 0, 0]
	if not ledgers.has(observer):
		ledgers[observer] = {}
		mine = ledgers[observer]
	mine[subject] = [0, 0, 0, 0, 0]
	_stat("ledgers")
	return mine[subject]


## NET judgment of `subject` by `observer`, milli-points: GOOD - BAD (the effective view when one fades).
func net(observer: int, subject: int) -> int:
	var l := ledger(observer, subject)
	if int(c("memory").effective_fade_permille) > 0:
		return int(l[3]) - int(l[4])
	return int(l[0]) - int(l[1])


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
	var lo := mini(a, b)
	var hi := maxi(a, b)
	return tell(lo, hi) + tell(hi, lo)


## `teller` tells `listener` up to gossip.per_meeting of their most salient memories the listener does not hold
## (deterministic: salience, then event id), within the teller's daily_budget, only to someone they judge above
## share_net_at, never past max_hops from a firsthand source, never under min_confidence, never about the
## listener's own deed. The listener's confidence: the teller's x hop_factor x credibility (their judgment of the
## teller). A seeded hash may make a rumour name the wrong actor (misattribute_permille; the teller's most disliked).
## Returns how many were told.
func tell(teller: int, listener: int) -> int:
	var g := c("gossip")
	var bc := c("belief")
	if teller == listener or int(told_today.get(teller, 0)) >= int(g.daily_budget) or net(teller, listener) <= int(g.share_net_at):
		return 0
	var mem: Dictionary = memories.get(teller, {})
	if mem.is_empty():
		return 0
	var pick := []
	for ev in mem:
		var b: Dictionary = mem[ev]
		if not facts.has(ev) or int(b.hops) >= int(g.max_hops) or int(b.conf) < int(g.min_confidence):
			continue
		if not belief(listener, ev).is_empty() or has_contribution(listener, ev):
			continue
		if _names(b.actors, listener):
			continue
		pick.append([-int(b.sal), int(ev)])
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
		var b: Dictionary = mem[ev]
		var conf := JudgmentMath.mul_div(int(b.conf) * int(bc.hop_factor), cred, 1000000)
		if conf < int(g.min_confidence):
			continue
		var actors: Array = b.actors
		if int(g.misattribute_permille) > 0 and JudgmentMath.roll([world_seed, ev, teller, listener]) < int(g.misattribute_permille):
			var other := most_disliked(teller, int(actors[0][0]))
			if other != -999 and other != listener:
				actors = [[other, JudgmentMath.ONE]]
				_stat("misattributed")
		var src := "told" if int(b.hops) == 0 else "rumour"
		learn(listener, ev, src, teller, int(b.hops) + 1, conf, actors)
		told_today[teller] = int(told_today.get(teller, 0)) + 1
		_stat("tellings")
		k += 1
	return k


# ---------------------------------------------------------------- the day ------------------------
## A new day: tellings reset; memories fade and the faint are forgotten; events past memory.horizon_days retire
## (their facts and dedup keys; ledgers keep every point); an optional effective view fades.
func advance_day(d: int) -> void:
	if d <= day:
		return
	var steps := d - day
	day = d
	told_today.clear()
	var m := c("memory")
	var fade := int(m.salience_fade_permille)
	var below := int(m.forget_below)
	var perm := {}                      # the event types that never fade (looked up once, not per memory)
	for t in cfg.events:
		if int(cfg.events[t].severity) >= int(m.permanent_severity):
			perm[t] = true
	var obs := memories.keys()
	obs.sort()
	for o in obs:
		var mem: Dictionary = memories[o]
		var gone := []
		for ev in mem:
			var b: Dictionary = mem[ev]
			if perm.has(b.type):
				continue
			var s := int(b.sal)
			for i in steps:
				s -= JudgmentMath.scale(s, fade)
			b.sal = s
			if s < below:
				gone.append(int(ev))
		gone.sort()
		for ev in gone:
			_forget(int(o), ev)
	var ef := int(m.effective_fade_permille)
	if ef > 0:
		for o in ledgers:
			for s in ledgers[o]:
				var l: Array = ledgers[o][s]
				for i in steps:
					l[3] = int(l[3]) - JudgmentMath.scale(int(l[3]), ef)
					l[4] = int(l[4]) - JudgmentMath.scale(int(l[4]), ef)
	_expire(d - int(m.horizon_days))


## Retire every event that happened before `cutoff`: its fact and everyone's contribution key for it (their ledger
## points stay). Memories of it remain until forgotten; past the horizon nobody can tell it on or correct it.
func _expire(cutoff: int) -> void:
	var days := by_day.keys()
	days.sort()
	for dd in days:
		if int(dd) >= cutoff:
			break
		for ev in by_day[dd]:
			var f: Dictionary = facts.get(ev, {})
			if f.is_empty():
				continue
			for o in f.knowers:
				(contrib.get(o, {}) as Dictionary).erase(ev)
			facts.erase(ev)
			_stat("expired")
		by_day.erase(dd)


# ---------------------------------------------------------------- inspection ---------------------
## Developer inspector (spec s.14): what `observer` believes and thinks of `subject`, and why.
func inspect(observer: int, subject: int) -> Dictionary:
	var l := ledger(observer, subject)
	var why := []
	var mem: Dictionary = memories.get(observer, {})
	var evs := mem.keys()
	evs.sort()
	for ev in evs:
		var b: Dictionary = mem[ev]
		if _names(b.actors, subject):
			var gb: Array = ((contrib.get(observer, {}) as Dictionary).get(ev, {}) as Dictionary).get(subject, [0, 0])
			why.append({"event": int(ev), "type": b.type, "src": b.src, "by": b.by, "conf": b.conf, "points": gb})
	return {"good": l[0], "bad": l[1], "net": int(l[0]) - int(l[1]), "contributions": l[2], "memories": why}


func counts() -> Dictionary:
	var nm := 0
	var nc := 0
	var nl := 0
	for o in memories:
		nm += (memories[o] as Dictionary).size()
	for o in contrib:
		for ev in contrib[o]:
			nc += (contrib[o][ev] as Dictionary).size()
	for o in ledgers:
		nl += (ledgers[o] as Dictionary).size()
	return {"facts": facts.size(), "memories": nm, "contributions": nc, "ledgers": nl}


# ---------------------------------------------------------------- saving -------------------------
## The provisional save section (World "judgment"; SAVE_VERSION unchanged: an older save simply has none). Lists
## sorted by id, so the same state always writes the same text.
func to_dict() -> Dictionary:
	if not unread.is_empty():
		return unread.duplicate(true)
	var fs := []
	var ids := facts.keys()
	ids.sort()
	for id in ids:
		var f: Dictionary = facts[id]
		var kn: Array = (f.knowers as Dictionary).keys()
		kn.sort()
		var row := [int(id), str(f.type), int(f.day), f.actors.duplicate(true), f.victims.duplicate(), f.beneficiaries.duplicate(),
			int(f.value), f.tags.duplicate(), int(f.revision), kn]
		if f.has("original_actors"):
			row.append(f.original_actors.duplicate(true))
		fs.append(row)
	var ms := []
	var cs := []
	var ls := []
	for o in _sorted(memories):
		var mem: Dictionary = memories[o]
		for ev in _sorted(mem):
			var b: Dictionary = mem[ev]
			ms.append([int(o), int(ev), str(b.type), int(b.day), (b.actors as Array).duplicate(true), str(b.src), int(b.by), int(b.hops), int(b.conf), int(b.sal)])
	for o in _sorted(contrib):
		for ev in _sorted(contrib[o]):
			for a in _sorted(contrib[o][ev]):
				var gb: Array = contrib[o][ev][a]
				cs.append([int(o), int(ev), int(a), int(gb[0]), int(gb[1])])
	for o in _sorted(ledgers):
		for s in _sorted(ledgers[o]):
			var l: Array = ledgers[o][s]
			ls.append([int(o), int(s), int(l[0]), int(l[1]), int(l[2]), int(l[3]), int(l[4])])
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
## unknown format or a newer version is refused with a message and kept unread, written back unchanged, never dropped
## (CLAUDE.md section 7). Returns "" or the reason it was not read.
func load_dict(d: Dictionary) -> String:
	facts.clear()
	by_day.clear()
	memories.clear()
	contrib.clear()
	ledgers.clear()
	told_today.clear()
	unread = {}
	if d.is_empty():
		return ""
	var m := migrate(d)
	if m.has("error"):
		unread = d.duplicate(true)
		return str(m.error)
	day = int(m.day)
	next_event = int(m.next_event)
	for r in m.facts:
		var kn := {}
		for o in r[9]:
			kn[int(o)] = true
		var f := {"id": int(r[0]), "type": str(r[1]), "day": int(r[2]), "actors": _ints2(r[3]), "victims": (r[4] as Array).map(func(x): return int(x)),
			"beneficiaries": (r[5] as Array).map(func(x): return int(x)), "value": int(r[6]), "tags": (r[7] as Array).duplicate(), "revision": int(r[8]), "knowers": kn}
		if (r as Array).size() > 10:
			f.original_actors = _ints2(r[10])
		facts[f.id] = f
		if not by_day.has(f.day):
			by_day[f.day] = []
		by_day[f.day].append(f.id)
	for r in m.memories:
		if not memories.has(int(r[0])):
			memories[int(r[0])] = {}
		memories[int(r[0])][int(r[1])] = {"type": str(r[2]), "day": int(r[3]), "actors": _ints2(r[4]), "src": str(r[5]), "by": int(r[6]),
			"hops": int(r[7]), "conf": int(r[8]), "sal": int(r[9])}
	for r in m.contrib:
		if not contrib.has(int(r[0])):
			contrib[int(r[0])] = {}
		if not contrib[int(r[0])].has(int(r[1])):
			contrib[int(r[0])][int(r[1])] = {}
		contrib[int(r[0])][int(r[1])][int(r[2])] = [int(r[3]), int(r[4])]
	for r in m.ledgers:
		if not ledgers.has(int(r[0])):
			ledgers[int(r[0])] = {}
		ledgers[int(r[0])][int(r[1])] = [int(r[2]), int(r[3]), int(r[4]), int(r[5]), int(r[6])]
	for r in m.told_today:
		told_today[int(r[0])] = int(r[1])
	return ""


static func _ints2(a) -> Array:
	return (a as Array).map(func(x): return [int(x[0]), int(x[1])])


## Bring a saved section up to this version, or {"error": why}. Version 0 is the prototype's first draft layout
## (points as floats, ledgers as {"o:s": {good, bad}}); kept as the migration path a format change will extend.
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
