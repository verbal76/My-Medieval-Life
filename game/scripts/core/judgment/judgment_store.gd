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
## Owner decisions (2026-10-21, docs/directives/2026-10-21_expansion19_sjd_final_decisions.md), round 4:
##   Q01  every event is a fact; each observer's interpretation may be positive, negative or zero; zero posts nothing
##        (no third ledger); NEUTRAL facts are always recorded, remembered and told, and score only through an
##        optional per-observer "personal" rule in the catalog (none configured: no automatic moral significance)
##   Q02  ordinary GOOD and BAD fade very slowly (decay.ordinary_permille_per_day, PROPOSED, unapproved); a murder
##        contribution never fades: each ledger keeps a fading part and a permanent part, routed by the event type
##   Q06  a told story's confidence comes from the listener's trust in the immediate teller, read from the existing
##        relationship number (Relations regard, through JudgmentSocial.regard); witnesses are firsthand; the chain's
##        confidence is the product along it; hearing it again never re-scores; a more credible telling updates the
##        existing belief and its contribution
##   Q07  no hop limit and no confidence floor: a story goes as far as real meetings carry it; per-meeting and daily
##        exchange limits remain; each person judges an event once (knowers), a belief is only replaced by a strictly
##        more confident one, so processing is bounded
##   Q08  interpretation from personal morality (morality_spread_permille), relationships, loyalties and who was
##        affected; no legal model here (guards and reports stay in World)
##   Q11  murder memories are permanent; others by severity (permanent_severity) or personal significance to the one
##        affected (permanent_personal_severity); permanent memories never fade, are not counted in the ordinary
##        capacity, and their facts never retire
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
##
## Word of mouth is spread over frames (round 3, frame cost): meet_later(a, b) queues a meeting (Relations.share's hour
## queues them all at once) and gossip_pump() tells a few each tick, in order. A meeting reads and changes only its two
## people's records, so before anything reads or changes a person's records, the queued meetings that person depends on
## are told first: the person's last queued meeting and, walking back, every earlier one sharing someone with a meeting
## already taken (the dependency closure, _flush_for). Those left behind share nobody with them, so they commute. The
## result is the same as telling every meeting the moment it is queued (meet), whenever the pump runs (judgment_test:
## same tellings, beliefs and end state).
## A pure read of someone's ledger (net, disposition, ledger: what decisions read) need not tell their queued meetings
## first when they provably cannot change it (_cu_read, 2026-10-22): a queued meeting can change X's ledger only by
## telling X something; it can only pass on what someone in X's dependency chain holds now, at no more confidence than
## they hold it (confidence only falls along a chain) and naming the same actors (when misattribution is off). So when X
## already holds every such memory at least as surely, or judged it before, the read gives the same answer either way
## and the meetings stay queued. A read of one entry (X's opinion of s: net, disposition, ledger) needs only that no
## such memory names s among its actors (nor among the actors X believed before, for an upgrade): a telling changes X's
## ledger only for the actors of the event told. Any change to X's records still tells them first. This is gossip.timing "hour" (the default): the hour's meetings count as told
## at the hour's start, as in rounds 1 and 2.
## gossip.timing "scheduled" (the gossip model since the owner's answer to X19-Q-TIMING, 2026-10-23: "They should spread
## organically by contact and closeness like a real rumor or gossip would"): each meeting is told at its own minute of
## the hour (a seeded hash of the pair and the hour), when gossip_tick reaches that minute; nothing is told early and
## reads never tell anything first, so no frame carries more than that minute's meetings. Meetings not yet told are
## saved with the section ("scheduled") and, if the setting is "hour" when it loads, move into the hour queue in minute
## order (load_dict), so none is lost or told twice. "hour" stays as the reference mode the identity tests and the
## perf harness compare against; the live setting is "scheduled".
## Closeness (gossip.closeness_floor_permille): how much of what a teller could pass on a meeting actually passes
## depends on how close the pair are (the existing relationship number, regard 0..100): each story passes with a chance
## from the floor (strangers) up to certain at regard 100, a seeded roll of the story, the pair and the meeting's minute.
## A story that does not pass this time may pass in a later meeting. A floor of 1000 turns the weighting off.

const FORMAT := "mml-judgment/1"
const VERSION := 3                       # 2 (Build 19): optional keys clock, lied, stories, choices, fights; traits v2 (anger in minutes). Version 1 sections load unchanged.
                                         # 3 (Expansion 20 R4, GM-01): optional keys refs (a fact's entity references and links) and history; version 1-2 sections load with none.
const ASPIRE_VERSION := 4                # 4 (Expansion 20 R5, WDR-011-C): the optional key aspire (NPC aspirations), written ONLY when it has rows, so a
                                         # section with aspirations off is version 3 byte for byte; Builds 19-22 meeting a 4 keep it unread (never dropped)
const MAX_VERSION := 4                   # the newest section this game reads
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
const M_FLAGS := 7                       # bit 1: a permanent memory (Q11)
const M_NA := 8
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
const NEWS_BASE := 1 << 36               # A5 (GP-DIALOGUE): news facts (family "news") take ids from here, so the moral events' ids (and every seeded roll on them) stay as they were
var next_news := NEWS_BASE
var news_told_today := {}  # A5: teller -> news tellings today (gossip.news_daily_budget), apart from the moral budget
var facts := {}          # event id -> PackedInt64Array (F_*)
var fact_tags := {}      # event id -> tags, only for events that have any
var fact_orig := {}      # event id -> the original actors, only for revised events
var knowers := {}        # event id -> PackedInt64Array of everyone who has judged it, sorted (the dedup key)
var by_day := {}         # day -> [event ids] (horizon expiry)
var memories := {}       # observer -> {event id -> PackedInt64Array (M_*)}
var contrib := {}        # observer -> {event id -> PackedInt64Array [actor, good, bad, ...] by actor}
var ledgers := {}        # observer -> [subjects (PackedInt64Array, ascending), values (PackedInt64Array, L_W a subject: life good, life bad, n, fading good, fading bad, permanent good, permanent bad, the day decayed to)]
const L_W := 8                   # values a ledger entry
var _none := PackedInt64Array()  # put in a record's place while its array changes, so the change is made in place
var trust := {}          # listener -> {subject -> trust milli-points 0..100000}: how far the listener relies on the subject (X19-REGARD)
var told_today := {}     # teller -> tellings today (gossip.daily_budget)
var stats := {}          # counters for diagnostics and performance reports
var unread := {}         # a saved section this version cannot read: kept and written back unchanged (CLAUDE.md s.7)
var last_trace := {}     # the last interpretation's parts (diagnostics: "why was the theft rated 0.55 BAD?"), kept when trace is on
var threat_cache := {}   # FAMILY-01 danger: the threats of the current game minute (JudgmentFamily._threats; never saved)
var family_trace := []   # FAMILY-01: the last family-priority decisions with their weighing traces (JudgmentFamily; for the recorder; never saved)
var clock_abs := 0       # game minutes at the last gossip_tick (see now_minute); saved as "clock"
var lied := {}           # liar -> day of their last invented story (X19-MISINFO: at most one per liar per game year; saved)
var story_pending := {}  # child -> [day they came of age, parents who have told them (bit 0 mother, bit 1 father)] (X19-STORY-LIFE; saved)
var last_choice := {}    # chooser -> {decision key -> [token, day]}: a stubborn person's last choice in a decision (saved)
var fights := {}         # pair key -> [aggressor, first blow minute, last blow minute]: a fight under way (X19-EVENT-Q self-defence; saved)
var fact_refs := {}      # GM-01: event id -> what a fact touched and led to: {household, giver_household, plot, building, item, qty, cost, built_day, links: [[kind, target], ...]}; only facts that have any; retires with the fact (saved "refs")
var history := {}        # GM-01: event id -> the historical record of a significant deed, kept after its fact retires: {type, day, actors, beneficiaries, value, refs, known: {person: [source, teller, generation]}} (saved "history")
var trace := false       # developer diagnostics: keep each interpretation's parts in last_trace (off: the same numbers, no record)
var rec = null           # REC-19 D5: the flight recorder (WorldRecorder) when one is attached (WorldRecorder.attach, JudgmentLive.attach); never saved, never read by the simulation: it is handed values already computed
var timing := {}         # microseconds spent, by part (measurement only: never saved, never read by the simulation)
var asp: JudgmentAspiration   # R5 (WDR-011-C): NPC aspirations, judgment.json "aspiration" (off by default: inert); saved "aspire" when it has rows
var _wref: WeakRef = null     # the live World this store belongs to (JudgmentLive.attach), held weakly; null in bare-store tests
var world:
	get:
		return _wref.get_ref() if _wref != null else null
	set(v):
		_wref = weakref(v) if v != null else null

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
var _perm := PackedInt64Array()  # 1 a memory of it never fades for anyone who knows (Q11: murder, or permanent_severity)
var _perm_first := PackedInt64Array()  # SJD-H C2: 1 a memory of it never fades for those it personally touched only: the ones it
                                       # happened to, eyewitnesses and the family of the one harmed (catalog "memory": "firsthand");
                                       # anyone else's (hearsay) is an ordinary memory and fades, while the judgment stays (_jperm)
var _perm_legacy := PackedInt64Array() # the rule before C2 (the type's "permanent" or permanent_severity), read only for saved
                                       # memory rows without flags (rounds 1-3), so saved data is never reinterpreted
var _jperm := PackedInt64Array() # 1 a judgment from it never decays (Q02: murder)
var _famh := PackedInt64Array()  # the type's family, hashed (Q08 personal morality)
var _news := PackedInt64Array()  # A5: 1 for a news type (family "news", NEUTRAL): known and told, never judged, apart from the moral memory and gossip
var _news_cap := 12              # memory.news_capacity: news memories a person holds at most (apart from memory.capacity)
var _g_news_per := 1             # gossip.news_per_meeting
var _g_news_budget := 4          # gossip.news_daily_budget
var _personal := []              # per type: the NEUTRAL "personal" rule (Q01) or {}
var _perm_personal := 3000       # memory.permanent_personal_severity: permanent for the one affected (Q11)
var _decay := 0                  # decay.ordinary_permille_per_day (Q02)
var _tol_spread := 0             # personality.tolerance_spread_permille (Q03)
var _tol_step := 0               # personality.tolerance_per_point (Q13 life events)
var _w_step := 0                 # personality.weight_per_point
var _shift_max := 0              # personality.max_shift_permille
var bonds: JudgmentBonds             # X19-FOUND-BONDS/FAMREP: pair history, resentment, family reputation (judgment_bonds.gd)
var life := {}                   # person -> disposition-weight shift permille, from firsthand life events (saved). The tolerance shift lives in pers.life_tol (RECON-01)
var pers: JudgmentPersonality    # the personality framework (traits, wisdom, anger, history): judgment_personality.gd, config "traits"
var _morality := 0               # interpret.morality_spread_permille (Q08)
var _perm_refs := {}             # event id -> permanent memories of it: such facts never retire (Q11)
var _cap := 24
var _fade := 0
var _below := 0
var _retract := false
var _slices := 24
# gossip and belief settings, looked up once (tell runs often)
var _g_per := 2
var _g_budget := 6
var _g_share_at := -20000
var _g_mis := 0
var _b_hop := 900
var _b_cred_stranger := 500
var _b_cred_pp := 10
var _b_cred_min := 100
var _g_pump := 8
var _i := PackedInt64Array()             # interpret: affected, accomplice, kin, friend, bystander, rival, rival_net_at,
                                         # kin_of_actor, friend_of_actor
var _b_policy := 0                       # confidence_policy: 0 multiplier, 1 threshold, 2 both
var _b_thr := 300
const SAL_ROOM := 1 << 20                # salience is far below this; tell sorts (SAL_ROOM - sal) << 40 | event id

# the gossip queue: meetings told later, in order
var _gq := PackedInt64Array()            # a, b, a, b, ...
var _gdone := PackedByteArray()          # 1 once told
var _ghead := 0                          # the first meeting not yet told
var _glast := {}                         # person -> their last queued meeting's index
var _gflushing := false
var _gver := 0                           # bumped by anything that changes what a queued meeting could tell (see _reach)
var _reach_ver := -1
var _reach_cache := {}                   # person -> [_gver, the actors whose entries queued meetings could change, any change at all, the closure]
var _g_sched := false                    # gossip.timing "scheduled"
var _sched := {}                         # minute -> PackedInt64Array [a, b, ...] in the order queued (scheduled timing)
var _stamp := 0                          # the meeting being told: its minute (scheduled) or 0, a part of the closeness roll
var _t_seed := 0                        # trust.seed_from_regard_permille: a first impression from liking (X19-REGARD)
var _t_ev := PackedInt64Array()         # per event type: trust milli-points a firsthand or told account of it moves the actor's trust
var _t_true := 0                        # trust.rumour_confirmed: milli-points the teller gains when what they told is borne out
var _t_false := 0                       # trust.rumour_false: ... loses when it is shown wrong
var _lie_chance := 0                    # lies.chance_permille: of the meetings where a teller with a motive gossips about that person (X19-MISINFO)
var _lie_gap := 0                       # lies.gap_days: days between one liar's inventions (0: one game year, Life.year_days())
var _lie_res := 2000                    # lies.min_resentment: serious resentment toward the subject (milli-points) that gives a motive
var _lie_types := []                    # lies.types: what an invented story accuses the subject of
var _refuting := false                  # R1: a refutation is being taken in at its meeting (trust.rumour_false applies, not the catalog's)
var _story_good := 2000                 # family_story.good_severity: a good deed this serious is passed on to children (X19-STORY-LIFE)
var _story_days := 4                    # family_story.expire_days: how long a new adult waits to be told, at home with a parent
var _fight_min := 10                    # self_defence.fight_minutes: a fight ends when no blow has fallen for this long
var _col_cap := 250                     # bonds.inherit_cap_permille: inherited impression never more than this share of the strongest personal judgment
var _g_floor := 1000                     # gossip.closeness_floor_permille
var _snext := -1                         # the next minute whose meetings are still to tell (-1: none queued yet)


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
		var legacy := bool(d.get("permanent", false)) or int(d.severity) >= int(m.permanent_severity)
		var first := legacy and str(d.get("memory", "")) == "firsthand" and int(d.severity) < int(m.permanent_severity)
		_perm.append(1 if legacy and not first else 0)
		_perm_first.append(1 if first else 0)
		_perm_legacy.append(1 if legacy else 0)
		_jperm.append(1 if bool(d.get("permanent", false)) else 0)
		_t_ev.append(int((d.get("trust", 0))))
		_famh.append(str(d.get("family", "")).hash())
		_news.append(1 if str(d.get("family", "")) == "news" and str(d.polarity) == "NEUTRAL" else 0)
		_personal.append((d.get("personal", {}) as Dictionary).duplicate())
	_cap = int(m.capacity)
	_news_cap = int(m.get("news_capacity", 12))
	_g_news_per = int((cfg.get("gossip", {}) as Dictionary).get("news_per_meeting", 1))
	_g_news_budget = int((cfg.get("gossip", {}) as Dictionary).get("news_daily_budget", 4))
	_fade = int(m.salience_fade_permille)
	_below = int(m.forget_below)
	_perm_personal = int(m.get("permanent_personal_severity", 3000))
	_decay = int((cfg.get("decay", {}) as Dictionary).get("ordinary_permille_per_day", 0))
	_retract = bool(m.retract_on_forget)
	_slices = maxi(1, int(m.get("dawn_slices", 24)))
	var g: Dictionary = cfg.gossip
	var bc: Dictionary = cfg.belief
	_g_per = int(g.per_meeting)
	_g_budget = int(g.daily_budget)
	_g_share_at = int(g.share_net_at)
	_g_mis = int(g.misattribute_permille)
	_g_pump = maxi(1, int(g.get("pump_per_tick", 8)))
	_g_sched = str(g.get("timing", "scheduled")) == "scheduled"
	_g_floor = clampi(int(g.get("closeness_floor_permille", 1000)), 0, 1000)
	var tc: Dictionary = cfg.get("trust", {})
	_t_seed = clampi(int(tc.get("seed_from_regard_permille", 1000)), 0, 1000)
	_t_true = int(tc.get("rumour_confirmed", 0))
	_t_false = int(tc.get("rumour_false", 0))
	var lc: Dictionary = cfg.get("lies", {})
	_lie_chance = int(lc.get("chance_permille", 0)) if _g_sched else 0     # the "hour" reference mode never invents (identity measurements)
	_lie_gap = int(lc.get("gap_days", 0))
	_lie_res = int(lc.get("min_resentment", 2000))
	_lie_types = (lc.get("types", ["theft", "trade_cheat"]) as Array).duplicate()
	var fc: Dictionary = cfg.get("family_story", {})
	_story_good = int(fc.get("good_severity", 2000))
	_story_days = int(fc.get("expire_days", 4))
	_fight_min = int((cfg.get("self_defence", {}) as Dictionary).get("fight_minutes", 10))
	_col_cap = int((cfg.get("bonds", {}) as Dictionary).get("inherit_cap_permille", 250))
	_b_hop = int(bc.hop_factor)
	_b_cred_stranger = int(bc.credibility_stranger)
	_b_cred_pp = int(bc.credibility_permille_per_point)
	_b_cred_min = int(bc.credibility_min)
	var ic: Dictionary = cfg.interpret
	for k in ["affected", "accomplice", "kin", "friend", "bystander", "rival", "rival_net_at", "kin_of_actor", "friend_of_actor"]:
		_i.append(int(ic[k]))
	_morality = int(ic.get("morality_spread_permille", 0))
	var pc: Dictionary = cfg.get("personality", {})
	_tol_spread = maxi(0, int(pc.get("tolerance_spread_permille", 0)))
	_tol_step = int(pc.get("tolerance_per_point", 0))
	_w_step = int(pc.get("weight_per_point", 0))
	_shift_max = maxi(0, int(pc.get("max_shift_permille", 0)))
	pers = JudgmentPersonality.new(cfg.get("traits", {}), seed)
	pers.configure_life(_tol_step, _shift_max)
	_b_policy = {"multiplier": 0, "threshold": 1, "both": 2}.get(str(bc.confidence_policy), 0)
	_b_thr = int(bc.confidence_threshold)
	bonds = JudgmentBonds.new(self, cfg.get("bonds", {}))
	asp = JudgmentAspiration.new(self, cfg.get("aspiration", {}), seed)
	if JudgmentAspiration.override.has("job_choice"):
		(cfg.decision.integration as Dictionary).job_choice = bool(JudgmentAspiration.override.job_choice)    # economy_sim --job-choice


func _stat(k: String, v := 1) -> void:
	stats[k] = int(stats.get(k, 0)) + v


func c(section: String) -> Dictionary:
	return cfg[section]


# ---------------------------------------------------------------- facts --------------------------
## Record what happened. `actors`: ids (equal shares) or [[id, share permille], ...]. Returns the event id, or -1
## when the catalog refuses it: an unknown type, or a value under the type's min_value (SJD-Q12, provisional). A
## NEUTRAL fact is recorded like any other (Q01): it is remembered and told, and scores only by a "personal" rule.
func publish(type: String, actors: Array, victims: Array = [], beneficiaries: Array = [], value := 0, tags: Array = []) -> int:
	if not _tix.has(type):
		_stat("refused_unknown")
		return -1
	var def: Dictionary = cfg.events[type]
	if value < int(def.get("min_value", 0)):
		_stat("refused_insignificant")
		return -1
	var id := next_event
	if _news[int(_tix[type])] == 1:
		id = next_news                          # A5: news has its own ids
		next_news += 1
	else:
		next_event += 1
	facts[id] = _pack_fact(int(_tix[type]), day, 0, value, _shares(actors), victims, beneficiaries)
	if not tags.is_empty():
		fact_tags[id] = tags.duplicate()
	if not by_day.has(day):
		by_day[day] = []
	by_day[day].append(id)
	_stat("events")
	_stat("event_" + type)                  # a diagnostics counter per kind (reports)
	if rec != null:
		rec.judgment_fact(id, type, _shares(actors), victims, beneficiaries, value, tags)     # REC-19 D5
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
	flush_gossip()
	_gver += 1
	if not facts.has(ev):
		return
	var f: PackedInt64Array = facts[ev]
	if not fact_orig.has(ev):
		fact_orig[ev] = _fact_actors(f)
	facts[ev] = _pack_fact(f[F_TYPE], f[F_DAY], f[F_REV] + 1, f[F_VALUE], _shares(actors), _fact_people(f, 0), _fact_people(f, 1))


# ---------------------------------------------------------------- belief and memory --------------
static func _pack_mem(type: int, d: int, src: int, by: int, hops: int, conf: int, sal: int, actors: Array, flags := 0) -> PackedInt64Array:
	var m := PackedInt64Array([type, d, src, by, hops, conf, sal, flags, actors.size()])
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
		"hops": m[M_HOPS], "conf": m[M_CONF], "sal": m[M_SAL], "permanent": (m[M_FLAGS] & 1) == 1}


func memory_count(observer: int) -> int:
	_cu(observer)
	return (memories.get(observer, {}) as Dictionary).size()


## Ordinary (not permanent) memories `observer` holds: the count memory.capacity bounds.
func ordinary_count(observer: int) -> int:
	_cu(observer)
	var n := 0
	var mem: Dictionary = memories.get(observer, {})
	for ev in mem:
		if (mem[ev][M_FLAGS] & 1) == 0 and _news[mem[ev][M_TYPE]] == 0:
			n += 1
	return n


## Whether `observer`'s memory of fact `f`, learnt from source index `src`, is permanent (Q11): a murder (the type's
## "permanent"), anything at least memory.permanent_severity, or, for the one affected by it (a victim, or a beneficiary),
## anything at least memory.permanent_personal_severity. SJD-H C2 (owner 2026-10-31): a type whose catalog entry says
## "memory": "firsthand" (an assault) is permanent only for those it personally touched: a participant, an eyewitness, or
## the family (JudgmentSocial.kin) of one it was done to; anyone else's account of it, told or rumoured, is an ordinary
## memory (it fades and is bounded like any other), while the judgment formed from it stays where X19-ASSAULT puts it.
func _mem_permanent(observer: int, f: PackedInt64Array, src := 0) -> bool:
	var t := f[F_TYPE]
	if _perm[t] == 1:
		return true
	if _perm_first[t] == 1:
		if src < TOLD:
			return true
		for v in _fact_people(f, 0) + _fact_people(f, 1):
			if int(v) == observer or social.kin(observer, int(v)):
				return true
		return false
	if _sev[t] < _perm_personal:
		return false
	var at := F_NA + 1 + 2 * f[F_NA]                 # victims, then beneficiaries, read in place
	for k in 2:
		for i in f[at]:
			if f[at + 1 + i] == observer:
				return true
		at += 1 + f[at]
	return false


## `observer` saw it (witnessed) or took part in it (participant): firsthand, full confidence by default.
## Whether facts of type index `t` are kept past the ordinary horizon: a permanent memory type (Q11), or one whose judgment
## never fades (X19-ASSAULT): such a fact stays so a later telling is recognised and judged once (its knowers stay).
func kept_type(t: int) -> bool:
	return _perm[t] == 1 or _perm_first[t] == 1 or _jperm[t] == 1


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


## Take in a belief about `ev` and judge by it. A belief already held at the same or higher confidence changes nothing
## (hearing a story again never re-scores it, Q06); a strictly more confident one replaces it and its contribution
## (spec s.5.1; Q06: "update the existing belief"). Corrections go through correct(). Returns true when anything
## changed.
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
		if old[M_CONF] >= conf:
			_stat("dup_ignored")
			return false
		old_sal = old[M_SAL]
		_stat("upgraded")
	elif SOURCES.find(src) >= TOLD and has_contribution(observer, ev):
		_stat("dup_ignored")                       # judged before and since forgotten: hearing it again adds nothing
		return false
	var f: PackedInt64Array = facts[ev]
	var t := f[F_TYPE]
	var rev: int = rec.belief_begin(observer, ev, _types[t], src, by, hops, conf, had) if rec != null else 0    # REC-19 D5
	var fresh := not had and not has_contribution(observer, ev)
	if had and SOURCES.find(src) < TOLD:
		var prev: PackedInt64Array = mem[ev]
		if prev[M_SRC] >= TOLD:                     # a told account meets first-hand knowledge: the teller was right or wrong (X19-REGARD)
			_vouch(observer, prev[M_BY], _same_actors(_mem_actors(prev), actors))
	var sal := JudgmentMath.scale(_sev[t], conf) if _pol[t] != 0 else int(c("memory").get("neutral_salience", 500))
	if _news[t] == 1:
		# A5: news (a purchase, a fence, relief, a death, a missing tool) is known and told, never judged: no ledger, trust,
		# personality or bond moves, and it is held apart from the moral memories (memory.news_capacity)
		mem[ev] = _pack_mem(t, f[F_DAY], SOURCES.find(src), by, hops, conf, maxi(sal, old_sal), actors, 0)
		_stat("news_beliefs")
		_bound_news(observer)
		if rev > 0:
			rec.end(rev)
		return true
	var was_perm := had and (((mem[ev] as PackedInt64Array)[M_FLAGS] & 1) == 1)
	var perm := was_perm or _mem_permanent(observer, f, SOURCES.find(src))     # a permanent memory stays so; hearsay seen later becomes so (C2)
	mem[ev] = _pack_mem(t, f[F_DAY], SOURCES.find(src), by, hops, conf, maxi(sal, old_sal), actors, 1 if perm else 0)
	_gver += 1
	if perm and not was_perm:
		_perm_refs[ev] = int(_perm_refs.get(ev, 0)) + 1
	_stat("beliefs")
	_judge(observer, ev)
	if fresh and SOURCES.find(src) < TOLD:
		_live(observer, ev)
		if pers.active:
			_trait_experience(observer, ev)
		bonds.on_belief(observer, ev)               # X19-FOUND-BONDS: resentment and betrayal history
	if fresh:
		var rtg: Array = fact_tags.get(ev, [])
		if rtg.size() >= 2 and str(rtg[0]) == "refutes":   # R1 (X19-MISINFO): learning a lie was shown false corrects what it caused
			_drop_lie(observer, int(rtg[1]), int((actors[0] as Array)[0]) if not actors.is_empty() else -1)
	if fresh and _t_ev[t] != 0 and not _refuting:      # at a refutation the approved trust.rumour_false applies instead (_refute)
		var late: bool = (fact_tags.get(ev, []) as Array).has("late")      # X19-EVENT-Q (3): a late repayment is a fair deal with half the trust gain
		for a in actors:                            # reliability shown by the deed itself: a fair deal, a cheat, a false charge
			if int(a[0]) != observer:
				var dt := JudgmentMath.mul_div(JudgmentMath.mul_div(_t_ev[t], conf, 1000), int(a[1]), 1000)
				trust_add(observer, int(a[0]), dt / 2 if late and dt > 0 else dt)
	_bound(observer)
	if rev > 0:
		rec.end(rev)
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
	if m[M_SRC] >= TOLD and m[M_CONF] < int(c("belief").witnessed):
		_vouch(observer, m[M_BY], _same_actors(_mem_actors(m), acts))     # the story the teller gave is borne out or shown wrong
	mem[ev] = _pack_mem(m[M_TYPE], m[M_DAY], m[M_SRC], m[M_BY], m[M_HOPS], maxi(m[M_CONF], int(c("belief").witnessed)), m[M_SAL], acts, m[M_FLAGS])
	_gver += 1
	_stat("corrections")
	_judge(observer, ev)


## Keep `observer`'s ordinary memories within memory.capacity: the least salient goes first, then the oldest event.
## Permanent memories (Q11) are never pushed out and not counted.
func _bound(observer: int) -> void:
	var mem: Dictionary = memories[observer]
	if mem.size() <= _cap:
		return
	while true:
		var ordinary := 0
		var worst := -1
		var w_sal := 0
		for ev in mem:
			var m: PackedInt64Array = mem[ev]
			if (m[M_FLAGS] & 1) == 1 or _news[m[M_TYPE]] == 1:
				continue
			ordinary += 1
			var sal := m[M_SAL]
			if worst < 0 or sal < w_sal or (sal == w_sal and int(ev) < worst):
				worst = int(ev)
				w_sal = sal
		if ordinary <= _cap:
			return
		_forget(observer, worst)
		if ordinary - 1 <= _cap:
			return                                 # what a second pass would find: one ordinary memory fewer


## A5: keep `observer`'s news memories within memory.news_capacity: the oldest event goes first.
func _bound_news(observer: int) -> void:
	var mem: Dictionary = memories[observer]
	var news := []
	for ev in mem:
		if _news[(mem[ev] as PackedInt64Array)[M_TYPE]] == 1:
			news.append(int(ev))
	if news.size() <= _news_cap:
		return
	news.sort()
	for i in news.size() - _news_cap:
		mem.erase(news[i])
		_stat("news_forgotten")


## Forget a memory. Its points stay in the ledger (unless retract_on_forget); its contribution record goes too, since
## only a held belief can be corrected, and the event's knowers keep the dedup key until the event retires, so hearing
## of it again adds nothing (memory use stays within capacity per person, not per event known).
func _forget(observer: int, ev: int) -> void:
	_gver += 1
	var t: int = (memories[observer] as Dictionary)[ev][M_TYPE]
	(memories[observer] as Dictionary).erase(ev)
	_stat("forgotten")
	if rec != null:
		rec.memory_forgot(observer, ev, _types[t])      # X20-FINAL: forgetting is recorded (fading itself: the daily summary)
	if _retract:
		_post(observer, ev, {}, _jperm[t] == 1)
	else:
		(contrib.get(observer, {}) as Dictionary).erase(ev)


# ---------------------------------------------------------------- interpretation -----------------
## How `observer` reads what `actor` did in event `ev`, believing the actors `believed`: the signed interpretation P
## (permille, spec s.4) and its parts. Hierarchical: the affected party reads it fully; an accomplice approves; others
## by their tie to the affected (kin, friend, a rival reverses it); loyalty to the actor softens condemnation;
## prior judgment of the actor never colours the reading: every event is judged on its own (SJD-Q05, "Not at all").
func interpret(observer: int, ev: int, actor: int, believed: Array) -> Dictionary:
	var parts := {}
	var p := _interpret_p(observer, ev, actor, believed, parts)
	parts.p = p
	return parts


## The signed interpretation P (permille) of interpret(); its parts go into `parts` only when one is given (trace or a
## direct interpret() call), so the usual path builds no dictionary. The same arithmetic either way.
func _interpret_p(observer: int, ev: int, actor: int, believed: Array, parts = null) -> int:
	var f: PackedInt64Array = facts[ev]
	var good := _pol[f[F_TYPE]] == 1
	var at := F_NA + 1 + 2 * f[F_NA]                 # the victims' count, then the beneficiaries' (read in place, not copied)
	if good:
		at += 1 + f[at]
	var n_aff := f[at]
	var is_aff := false
	for i in n_aff:
		if f[at + 1 + i] == observer:
			is_aff = true
			break
	var p := 0
	if is_aff:
		p = _i[0]
		if parts != null:
			parts.role = "affected"
	elif not good and _names(believed, observer):
		p = _i[1]
		if parts != null:
			parts.role = "accomplice"
	else:
		if parts != null:
			parts.role = "bystander"
		p = _i[4]
		var best := -1
		for i in n_aff:
			var v := f[at + 1 + i]
			var pv := _i[4]
			var why := 0                              # 0 bystander, 1 kin, 2 friend, 3 rival
			if social.kin(observer, v):
				pv = _i[2]
				why = 1
			elif social.friends(observer, v):
				pv = _i[3]
				why = 2
			elif net(observer, v) <= threshold(observer, _i[6]):
				pv = _i[5]
				why = 3
			if best < 0 or absi(pv) > absi(p) or (absi(pv) == absi(p) and pv > p):
				p = pv
				if parts != null:
					parts.role = ["bystander", "kin", "friend", "rival"][why]
					parts.of = v
				best = 1
	if parts != null:
		parts.base = p
	if not good and p > 0 and not is_aff:
		if social.kin(observer, actor):
			p = JudgmentMath.scale(p, _i[7])
			if parts != null:
				parts.loyalty = "kin of actor"
		elif social.friends(observer, actor):
			p = JudgmentMath.scale(p, _i[8])
			if parts != null:
				parts.loyalty = "friend of actor"
	if _morality > 0 and not is_aff:
		var mor := morality(observer, f[F_TYPE])
		p = JudgmentMath.scale(p, mor)
		if parts != null:
			parts.morality = mor
	return JudgmentMath.clampi_(p, -JudgmentMath.ONE, JudgmentMath.ONE)


## Personal morality (Q08): how strongly `observer` feels about this family of deeds, permille, fixed per person and
## family by the seed: 1000 +/- interpret.morality_spread_permille (provisional). Never applied to the one affected.
func morality(observer: int, type: int) -> int:
	if _morality <= 0:
		return JudgmentMath.ONE
	var r := JudgmentMath.hash_ints([world_seed, observer, _famh[type]]) % (2 * _morality + 1) - _morality
	return JudgmentMath.ONE + r


## Personal tolerance (SJD-Q03), permille: 1000 +/- personality.tolerance_spread_permille, fixed by the world seed and the
## person's id (their temperament at birth; nothing is stored for it), plus the shift their own life has given them.
## Above 1000 they put up with more before souring on someone; below, they hold a grudge sooner.
func tolerance(person: int) -> int:
	var t := JudgmentMath.ONE
	if _tol_spread > 0:
		t += JudgmentMath.hash_ints([world_seed, person, 4099]) % (2 * _tol_spread + 1) - _tol_spread
	if pers.moves_tolerance():
		t += pers.tolerance_shift(person)              # the one owner of tolerance change: SJD-Q13 life shift + long-term drift (RECON-01)
	return t


## A NET threshold (negative milli-points) as `person` holds it: the configured one scaled by their tolerance.
func threshold(person: int, base: int) -> int:
	if _tol_spread <= 0 and not pers.moves_tolerance():
		return base
	return JudgmentMath.scale(base, tolerance(person))


## The life shift on the weight of a person's disposition factor (SJD-Q13), permille; 0 when their life has not moved it.
func weight_shift(person: int) -> int:
	return int(life.get(person, 0))


## A firsthand experience shapes the person (SJD-Q13, bounded): the victim of a bad deed grows less tolerant, the one
## helped weighs others' opinions (trust in a helper) more. Once per event per person (called when the belief is new).
func _live(observer: int, ev: int) -> void:
	var f: PackedInt64Array = facts[ev]
	var t := f[F_TYPE]
	if _pol[t] == 0 or (_tol_step == 0 and _w_step == 0) or _shift_max == 0:
		return
	var at := F_NA + 1 + 2 * f[F_NA]
	if _pol[t] == 1:
		at += 1 + f[at]
	var hit := false
	for i in f[at]:
		if f[at + 1 + i] == observer:
			hit = true
	if not hit:
		return
	if _pol[t] < 0:
		if pers.life_provocation(observer, _sev[t]):      # tolerance change belongs to the personality layer (RECON-01)
			_stat("life_shifts")
	else:
		life[observer] = JudgmentMath.clampi_(int(life.get(observer, 0)) + JudgmentMath.mul_div(_sev[t], _w_step, 1000), -_shift_max, _shift_max)
		_stat("life_shifts")


## Personality framework hook (X19-FOUND-PERS): a firsthand deed that touches `observer` as victim of a BAD one or
## beneficiary of a GOOD one is a meaningful experience (provocation or positive) for their traits and anger.
func _trait_experience(observer: int, ev: int) -> void:
	var f: PackedInt64Array = facts[ev]
	var t := f[F_TYPE]
	if _pol[t] == 0:
		return
	var at := F_NA + 1 + 2 * f[F_NA]
	if _pol[t] == 1:
		at += 1 + f[at]
	for i in f[at]:
		if f[at + 1 + i] == observer:
			var nm := now_minute()
			pers.experience(observer, "provocation" if _pol[t] < 0 else "positive", _sev[t], nm / 1440, 0, nm % 1440)
			return


## The game minute now: the live world's clock as last told by gossip_tick, never earlier than the start of the store's day.
func now_minute() -> int:
	return maxi(clock_abs, day * 1440)


## Personality growth for other systems, permille, 0 = none (Worker B's resentment softening calls this if present).
## Positive development only: tolerance drift above origin, stubbornness shed, carried-over wisdom (see JudgmentPersonality.growth).
func personality_growth(person: int) -> int:
	return pers.growth(person)


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
	if actor == observer:
		return [0, 0]
	if _pol[t] == 0:
		return _personal_points(observer, ev, share, conf)
	var parts = {} if trace else null
	var p := _interpret_p(observer, ev, actor, believed, parts)
	var impact := 0
	if _b_policy != 0 and conf < _b_thr:
		impact = 0
	elif _b_policy == 1:
		impact = JudgmentMath.scale(_sev[t], p)
	else:
		impact = JudgmentMath.mul_div(_sev[t] * p, conf, 1000000)
	impact = JudgmentMath.scale(impact, share)
	if parts != null:
		parts.p = p
		parts.severity = _sev[t]
		parts.confidence = conf
		parts.impact = impact
		last_trace = parts
	if impact == 0:
		return [0, 0]
	if (impact > 0) == (_pol[t] == 1):
		return [absi(impact), 0]
	return [0, absi(impact)]


## Q01: a NEUTRAL fact scores only by its type's "personal" rule ({severity, beneficiary, victim, kin, friend}: P
## permille for one of the beneficiaries or victims, or kin or friend of a beneficiary); positive posts GOOD, negative
## BAD, zero nothing. With no rule (the default for every type) it is zero for everyone: no automatic moral meaning.
func _personal_points(observer: int, ev: int, share: int, conf: int) -> Array:
	var f: PackedInt64Array = facts[ev]
	var rule: Dictionary = _personal[f[F_TYPE]]
	if rule.is_empty():
		if trace:
			last_trace = {"role": "no personal meaning", "p": 0}
		return [0, 0]
	var benef := _fact_people(f, 1)
	var p := 0
	var role := "unrelated"
	if benef.has(observer):
		p = int(rule.get("beneficiary", 0))
		role = "beneficiary"
	elif _fact_people(f, 0).has(observer):
		p = int(rule.get("victim", 0))
		role = "victim"
	else:
		for b in benef:
			if social.kin(observer, b):
				p = int(rule.get("kin", 0))
				role = "kin"
				break
			if social.friends(observer, b):
				p = int(rule.get("friend", 0))
				role = "friend"
	var impact := JudgmentMath.scale(JudgmentMath.mul_div(int(rule.get("severity", 0)) * p, conf, 1000000), share)
	if trace:
		last_trace = {"role": role, "p": p, "impact": impact}
	if impact > 0:
		return [impact, 0]
	if impact < 0:
		return [0, -impact]
	return [0, 0]


## Recompute `observer`'s contributions for `ev` from their belief.
func _judge(observer: int, ev: int) -> void:
	var m: PackedInt64Array = memories[observer][ev]
	var believed := _mem_actors(m)
	var want := {}
	for a in believed:
		var gb := evaluate(observer, ev, int(a[0]), int(a[1]), m[M_CONF], believed)
		if gb[0] != 0 or gb[1] != 0:
			want[int(a[0])] = gb
	_post(observer, ev, want, _jperm[m[M_TYPE]] == 1)
	var k: PackedInt64Array = knowers.get(ev, PackedInt64Array())
	var i := k.bsearch(observer)
	if i >= k.size() or k[i] != observer:
		k.insert(i, observer)
		knowers[ev] = k


## Replace `observer`'s contributions for `ev` with `want` ({actor: [good, bad]}): the difference goes to the
## ledgers, which never go below 0 (spec s.5.1): to their permanent part for a murder (`perm`, Q02), else to their
## fading part.
func _post(observer: int, ev: int, want: Dictionary, perm := false) -> void:
	if not contrib.has(observer):
		contrib[observer] = {}
		_add_person(observer)
	var mine: Dictionary = contrib[observer]
	var row: PackedInt64Array = mine.get(ev, PackedInt64Array())
	var ids := []                                  # every actor in the old row or the new, ascending
	for i in range(0, row.size(), 3):
		ids.append(row[i])
	for a in want:
		if not ids.has(a):
			ids.append(a)
	if ids.size() > 1:
		ids.sort()
	var out := PackedInt64Array()
	for a in ids:
		var og := 0
		var ob := 0
		for i in range(0, row.size(), 3):
			if row[i] == a:
				og = row[i + 1]
				ob = row[i + 2]
		var n: Array = want.get(a, [0, 0])
		var ng := int(n[0])
		var nb := int(n[1])
		if ng != 0 or nb != 0:
			out.append(a)
			out.append(ng)
			out.append(nb)
		if og == ng and ob == nb:
			continue
		if rec != null:
			rec.judgment_post(observer, ev, int(a), og, ob, ng, nb)      # REC-19 D5: the ledger post
		var was := og != 0 or ob != 0
		var now := ng != 0 or nb != 0
		_ledger_add(observer, a, ng - og, nb - ob, 1 if now and not was else (-1 if was and not now else 0), perm)
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
## [lifetime good, lifetime bad, contributions, fading good, fading bad, permanent good, permanent bad] (a copy; all 0
## when none). The lifetime totals never fade (history, spec s.5.2); NET uses the fading and permanent parts.
func ledger(observer: int, subject: int) -> Array:
	_cu_read(observer, subject)
	var rec = ledgers.get(observer)
	var i := -1 if rec == null else _lfind(rec, subject)
	if i < 0:
		return [0, 0, 0, 0, 0, 0, 0]
	_ldecay(rec, i)
	return Array((rec[1] as PackedInt64Array).slice(L_W * i, L_W * i + 7))


## Everyone `observer` has a ledger entry for, ascending.
func subjects(observer: int) -> PackedInt64Array:
	var rec = ledgers.get(observer)
	return PackedInt64Array() if rec == null else rec[0]


## Ledgers are kept per observer as two packed arrays (2026-10-22, memory): the subjects, ascending, and L_W values
## for each, so an entry costs its values and no dictionary slot or array of its own. Same values, same order.
static func _lfind(rec: Array, subject: int) -> int:
	var subs: PackedInt64Array = rec[0]
	var i := subs.bsearch(subject)
	return i if i < subs.size() and subs[i] == subject else -1


## The entry at `i` with the decay it is due applied (2026-10-22, lazily): the fading parts lose _decay_step a day for
## every day since it was last brought up to date, the same integer steps in the same order the daily update applied
## to every ledger at each person's dawn, so every value read is the same; only entries nobody reads wait.
func _ldecay(rec: Array, i: int) -> void:
	var v: PackedInt64Array = rec[1]
	var b := L_W * i
	if v[b + 7] >= day:
		return
	rec[1] = _none
	if _decay > 0 and (v[b + 3] != 0 or v[b + 4] != 0):
		for k in day - v[b + 7]:
			v[b + 3] = v[b + 3] - _decay_step(v[b + 3])
			v[b + 4] = v[b + 4] - _decay_step(v[b + 4])
	v[b + 7] = day
	rec[1] = v


## The place of `subject` in `observer`'s ledger, brought up to date, or made (all 0, decayed to today) when missing
## (`count`: as a new judgment in the stats).
func _lslot(observer: int, subject: int, count: bool) -> int:
	if not ledgers.has(observer):
		ledgers[observer] = [PackedInt64Array(), PackedInt64Array()]
		_add_person(observer)
	var rec: Array = ledgers[observer]
	var subs: PackedInt64Array = rec[0]
	var i := subs.bsearch(subject)
	if i < subs.size() and subs[i] == subject:
		_ldecay(rec, i)
		return i
	rec[0] = _none
	subs.insert(i, subject)
	rec[0] = subs
	var v: PackedInt64Array = rec[1]
	rec[1] = _none
	v.insert(L_W * i, day)
	for k in L_W - 1:
		v.insert(L_W * i, 0)
	rec[1] = v
	if count:
		_stat("ledgers")
	return i


func _ledger_add(observer: int, subject: int, dg: int, db: int, dn: int, perm := false) -> void:
	var i := _lslot(observer, subject, true)
	var rec: Array = ledgers[observer]
	var v: PackedInt64Array = rec[1]
	rec[1] = _none
	var b := L_W * i
	v[b] = maxi(0, v[b] + dg)
	v[b + 1] = maxi(0, v[b + 1] + db)
	v[b + 2] = v[b + 2] + dn
	var at := b + (5 if perm else 3)
	v[at] = maxi(0, v[at] + dg)
	v[at + 1] = maxi(0, v[at + 1] + db)
	rec[1] = v


## Set a ledger's GOOD and BAD outright (tests and fixtures: an opinion formed before the scenario starts).
func set_ledger(observer: int, subject: int, good_points: int, bad_points: int) -> void:
	_cu(observer)
	_gver += 1
	var i := _lslot(observer, subject, false)
	var rec: Array = ledgers[observer]
	var v: PackedInt64Array = rec[1]
	rec[1] = _none
	var b := L_W * i
	v[b] = good_points
	v[b + 1] = bad_points
	v[b + 3] = good_points
	v[b + 4] = bad_points
	v[b + 5] = 0
	v[b + 6] = 0
	rec[1] = v


## NET judgment of `subject` by `observer`, milli-points: GOOD - BAD over the fading parts (decayed, Q02) and the
## permanent parts (murder, never decayed).
func net(observer: int, subject: int) -> int:
	_cu_read(observer, subject)
	var rec = ledgers.get(observer)
	var i := -1 if rec == null else _lfind(rec, subject)
	if i < 0:
		return 0
	_ldecay(rec, i)
	var v: PackedInt64Array = rec[1]
	var b := L_W * i
	return v[b + 3] + v[b + 5] - v[b + 4] - v[b + 6]


func good(observer: int, subject: int) -> int:
	return int(ledger(observer, subject)[0])


func bad(observer: int, subject: int) -> int:
	return int(ledger(observer, subject)[1])


## The judgment as a decision factor on the spec's 0..100 scale (milli): disposition_mid + NET, clamped (spec s.7.3:
## NET -6.59 -> 43.41).
func disposition(observer: int, subject: int) -> int:
	return JudgmentMath.clampi_(int(c("decision").disposition_mid) + net(observer, subject) + colour(observer, subject), 0, 100000)


## The disposition from the observer's own judgment of the subject alone, without the family name's colour.
func personal_disposition(observer: int, subject: int) -> int:
	return JudgmentMath.clampi_(int(c("decision").disposition_mid) + net(observer, subject), 0, 100000)


## The colour the subject's family name gives the observer's disposition, milli-points (X19-BOND-LIMITS): the inherited
## impression (JudgmentBonds.family_reputation: the observer's own remembered judgments of the subject's relatives, by
## relationship distance), weakened by every dealing the observer has had with the subject, and never more than
## bonds.inherit_cap_permille (a quarter) of the strongest personal judgment the observer holds of anyone. Kept apart
## from the direct, relationship-weighted reaction to a witnessed deed (interpret). It only colours: JudgmentWeighting
## never lets it alone cause a refusal.
func colour(observer: int, subject: int) -> int:
	if not bonds.family_active() or observer == subject or not ledgers.has(observer):
		return 0
	var raw := bonds.family_reputation(observer, subject)
	if raw == 0:
		return 0
	var used := int((ledger(observer, subject) as Array)[2]) * bonds.override_per_experience()
	var left := maxi(0, 1000 - used)
	if left == 0:
		return 0
	var v := JudgmentMath.mul_div(raw, left, 1000)
	var strongest := 0
	for sub_ in subjects(observer):
		strongest = maxi(strongest, absi(net(observer, int(sub_))))
	var cap := JudgmentMath.mul_div(strongest, _col_cap, 1000)
	return JudgmentMath.clampi_(v, -cap, cap)


## The most the colour could add to anyone's disposition for `observer`, milli-points (a bound for shortcuts).
func colour_bound(observer: int) -> int:
	if not bonds.family_active():
		return 0
	var strongest := 0
	for sub_ in subjects(observer):
		strongest = maxi(strongest, absi(net(observer, int(sub_))))
	return JudgmentMath.mul_div(strongest, _col_cap, 1000)


## Large GOOD and BAD together (SJD-Q04): min(GOOD, BAD), clamped to 0..100 points.
func ambivalence(observer: int, subject: int) -> int:
	var l := ledger(observer, subject)
	return mini(100000, mini(int(l[0]), int(l[1])))


## The subject `observer` thinks worst of (lowest NET, then lowest id), or -999 when they judge nobody below 0.
func most_disliked(observer: int, besides := -999) -> int:
	_cu_read(observer)
	var best := -999
	var best_net := 0
	var ids := subjects(observer)                # ascending (a copy: reading never changes who is in it)
	for s in ids:
		var v := net(observer, int(s))
		if int(s) != besides and v < best_net:
			best = int(s)
			best_net = v
	return best


# ---------------------------------------------------------------- information sharing ------------
## Two people spend time together (a test, or a caller that wants the result now): each may tell the other (tell),
## at once, after the queued meetings either of them depends on. Returns how many were told.
func meet(a: int, b: int) -> int:
	_flush_for(a)
	_flush_for(b)
	return _meet_now(a, b)


func _meet_now(a: int, b: int) -> int:
	if not memories.has(a) and not memories.has(b):
		if world != null and world.economy != null:
			world.economy.on_meeting(a, b)         # EXPANSION 20 LE-02: prices pass even when no judged event does; null while disabled
		return 0                                   # neither knows anything to tell
	var t := Time.get_ticks_usec()
	var lo := mini(a, b)
	var hi := maxi(a, b)
	var k := tell(lo, hi) + tell(hi, lo)
	timing.meet_us = int(timing.get("meet_us", 0)) + Time.get_ticks_usec() - t
	if world != null and world.economy != null:
		world.economy.on_meeting(a, b)             # EXPANSION 20 LE-02 (OD-LE-10 D09): prices by word of mouth; null while disabled
	return k


## Queue a meeting to be told later (Relations.share's hour): the same result as meet() now (see the header).
func meet_later(a: int, b: int) -> void:
	if a == b:
		return
	_gver += 1
	_glast[a] = _gq.size() / 2
	_glast[b] = _gq.size() / 2
	_gq.append(a)
	_gq.append(b)
	_gdone.append(0)


## The live entry point (Relations.share): two people spent the hour starting at game minute `hour_minute` together.
## "hour" timing queues the meeting (meet_later); "scheduled" sets it at its own minute of that hour (meet_at).
func meet_hourly(a: int, b: int, hour_minute: int) -> void:
	if _g_sched:
		var lo := mini(a, b) + 1024
		var hi := maxi(a, b) + 1024
		var h := ((lo * 73856093) ^ (hi * 19349663) ^ ((hour_minute / 60) * 83492791) ^ (world_seed * 2654435)) & 0x7FFFFFFF
		meet_at(a, b, hour_minute + h % 60)              # a cheap seeded spread: an hour's meetings are queued in one frame
	else:
		meet_later(a, b)


## Scheduled timing: a meeting told when gossip_tick reaches game minute `at` (same-minute meetings in the order queued).
func meet_at(a: int, b: int, at: int) -> void:
	if a == b:
		return
	var row: PackedInt64Array = _sched.get(at, PackedInt64Array())
	row.append(a)
	row.append(b)
	_sched[at] = row
	if _snext < 0 or at < _snext:
		_snext = at


## The live tick (World.update): "hour" timing tells gossip.pump_per_tick queued meetings; "scheduled" tells every
## meeting whose minute has come (up to game minute `now`).
func gossip_tick(now: int) -> void:
	if now > clock_abs:
		clock_abs = now
	if _g_sched:
		_tell_due(now)
	else:
		gossip_pump()


func _tell_due(now: int) -> void:
	if _sched.is_empty() or _snext > now:
		return
	var t := Time.get_ticks_usec()
	var mins := _sched.keys()
	mins.sort()
	for mm in mins:
		if int(mm) > now:
			_snext = int(mm)
			break
		var row: PackedInt64Array = _sched[mm]
		_sched.erase(mm)
		for i in range(0, row.size(), 2):
			_stamp = int(mm)
			_meet_now(row[i], row[i + 1])
	_stamp = 0
	if _sched.is_empty():
		_snext = -1
	timing.due_us = int(timing.get("due_us", 0)) + Time.get_ticks_usec() - t


func gossip_queued() -> int:
	var n := 0
	for mm in _sched:
		n += (_sched[mm] as PackedInt64Array).size() / 2
	for i in range(_ghead, _gdone.size()):
		if _gdone[i] == 0:
			n += 1
	return n


## Tell up to `k` queued meetings in order (gossip.pump_per_tick when k < 0); World.update calls it each tick.
## Returns how many are still queued.
func gossip_pump(k := -1) -> int:
	if _ghead >= _gdone.size():
		return 0
	var t := Time.get_ticks_usec()
	var left := _g_pump if k < 0 else k
	_gver += 1
	var was := _gflushing
	_gflushing = true
	while _ghead < _gdone.size() and left > 0:
		if _gdone[_ghead] == 0:
			_gdone[_ghead] = 1
			_meet_now(_gq[2 * _ghead], _gq[2 * _ghead + 1])
			left -= 1
		_ghead += 1
	_gflushing = was
	_gtrim()
	timing.pump_us = int(timing.get("pump_us", 0)) + Time.get_ticks_usec() - t
	return gossip_queued()


func flush_gossip() -> void:
	while _ghead < _gdone.size():
		gossip_pump(1 << 30)


## Tell, in order, the queued meetings `o` depends on: their last one and every earlier one sharing someone with a
## meeting already taken (walking back). The rest share nobody with these, so leaving them queued changes nothing.
func _flush_for(o: int) -> void:
	if _gflushing or _ghead >= _gdone.size() or not _glast.has(o):
		return
	var last := int(_glast[o])
	if last < _ghead or _gdone[last] == 1:
		return
	var who := {o: true}
	var take := _closure(o, who)
	_tell_taken(take)


## The queued meetings `o` depends on, newest first: their last one and every earlier one sharing someone with a meeting
## already taken. `who` gathers the people they involve.
func _closure(o: int, who: Dictionary) -> PackedInt64Array:
	var take := PackedInt64Array()
	var i := int(_glast[o])
	while i >= _ghead:
		if _gdone[i] == 0:
			var a := _gq[2 * i]
			var b := _gq[2 * i + 1]
			if who.has(a) or who.has(b):
				take.append(i)
				who[a] = true
				who[b] = true
		i -= 1
	return take


## Tell the meetings of a closure (newest first in `take`) in queue order.
func _tell_taken(take: PackedInt64Array) -> void:
	_gver += 1
	var t := Time.get_ticks_usec()
	_gflushing = true
	for j in range(take.size() - 1, -1, -1):
		var m := take[j]
		_gdone[m] = 1
		_meet_now(_gq[2 * m], _gq[2 * m + 1])
	_gflushing = false
	while _ghead < _gdone.size() and _gdone[_ghead] == 1:
		_ghead += 1
	_gtrim()
	_stat("gossip_flushes")
	var took := Time.get_ticks_usec() - t
	timing.flush_us = int(timing.get("flush_us", 0)) + took
	if took > int(timing.get("flush_max_us", 0)):
		timing.flush_max_us = took
		timing.flush_max_meetings = take.size()


## Once every queued meeting is told, empty the queue.
func _gtrim() -> void:
	if _ghead >= _gdone.size():
		_gq = PackedInt64Array()
		_gdone = PackedByteArray()
		_ghead = 0
		_glast.clear()


## `teller` tells `listener` up to gossip.per_meeting of their most salient memories the listener does not hold, or holds
## less confidently than this telling would give (deterministic: salience, then event id), within the teller's
## daily_budget (exchange limits, Q07), only to someone they judge above share_net_at, never about the listener's own
## deed, never something the listener judged before and has since forgotten. No hop limit and no confidence floor (Q07).
## The listener's confidence (Q06): the teller's x hop_factor x credibility, credibility from the listener's trust in
## the teller (credibility(): the existing relationship number, then their judgment of the teller). A seeded hash may
## make a rumour name the wrong actor (misattribute_permille; the teller's most disliked). Returns how many were told.
func tell(teller: int, listener: int) -> int:
	if rec == null:
		return _tell(teller, listener)
	var gev: int = rec.gossip_begin(teller, listener)                  # REC-19 D5: the telling and the beliefs it gave
	var k := _tell(teller, listener)
	rec.gossip_end(gev, teller, listener, k)
	return k


## EXPANSION 20 LE-02 (OD-LE-10 D09, a read only): whether `teller` would tell `listener` anything at a meeting, by the gossip's
## own rule (their net judgment above the teller's share threshold). The Living Economy passes prices by word of mouth only then.
func would_tell(teller: int, listener: int) -> bool:
	return teller != listener and net(teller, listener) > threshold(teller, _g_share_at)


func _tell(teller: int, listener: int) -> int:
	if teller == listener or not memories.has(teller):
		return 0
	_cu(teller)
	_cu(listener)
	var mem: Dictionary = memories[teller]
	if mem.is_empty():
		return 0
	if net(teller, listener) <= threshold(teller, _g_share_at):
		return 0
	if int(told_today.get(teller, 0)) >= _g_budget:
		_tell_news(teller, listener, mem, memories.get(listener, {}))     # A5: the moral budget spent, news may still pass
		return 0
	var cred := -1                                 # the listener's trust in the teller, found when first needed
	var heard: Dictionary = memories.get(listener, {})
	var mine: Dictionary = contrib.get(listener, {})
	var keys := PackedInt64Array()
	var about := {}                                # whom the stories told in this meeting were about
	for ev in mem:
		var m: PackedInt64Array = mem[ev]
		if not facts.has(ev) or _mem_names(m, listener) or _news[m[M_TYPE]] == 1:
			continue
		if cred < 0:
			cred = credibility(listener, teller)
		var conf := JudgmentMath.mul_div(m[M_CONF] * _b_hop, cred, 1000000)
		if conf <= 0:
			continue                               # a story nobody could believe at all is not passed on
		if heard.has(ev):
			if (heard[ev] as PackedInt64Array)[M_CONF] >= conf:
				continue                           # held as surely already: hearing it again changes nothing (Q06)
		elif mine.has(ev):
			continue
		else:
			var kn: PackedInt64Array = knowers.get(ev, PackedInt64Array())
			var at := kn.bsearch(listener)
			if at < kn.size() and kn[at] == listener:
				continue                           # judged before and since forgotten
		keys.append(((SAL_ROOM - m[M_SAL]) << 40) | int(ev))
	if keys.is_empty():
		_tell_news(teller, listener, mem, heard)
		return 0
	keys.sort()
	var k := 0
	for key in keys:
		if k >= _g_per or int(told_today.get(teller, 0)) >= _g_budget:
			break
		var ev := key & ((1 << 40) - 1)
		var m: PackedInt64Array = mem[ev]
		if _g_floor < 1000 and JudgmentMath.roll([world_seed, ev, teller, listener, _stamp, day]) >= close_chance(listener, teller):
			_stat("withheld")                      # not passed on this time: the pair are not close enough (a later meeting may)
			continue
		var conf := JudgmentMath.mul_div(m[M_CONF] * _b_hop, cred, 1000000)
		var actors := _mem_actors(m)
		if is_lie(ev):                                   # X19-MISINFO: a guard or a firsthand witness shows an invented story false
			var liar := liar_of(ev)
			if listener != liar and _contradicts(listener, actors):
				_refute(teller, listener, ev, liar)
				continue
		if _g_mis > 0 and JudgmentMath.roll([world_seed, ev, teller, listener]) < _g_mis:
			var other := most_disliked(teller, int(actors[0][0]))
			if other != -999 and other != listener:
				actors = [[other, JudgmentMath.ONE]]
				_stat("misattributed")
		var src := "told" if m[M_HOPS] == 0 else "rumour"
		learn(listener, ev, src, teller, m[M_HOPS] + 1, conf, actors)
		told_today[teller] = int(told_today.get(teller, 0)) + 1
		_stat("tellings")
		k += 1
		for a in actors:
			about[int(a[0])] = true
	if k > 0 and _lie_chance > 0:
		k += _maybe_lie(teller, listener, about)
	_tell_news(teller, listener, mem, heard)
	return k


## A5: in the same meeting, the teller passes on news (purchases, fences, relief, deaths, missing tools) the listener
## lacks, newest first, at most gossip.news_per_meeting, within its own daily budget (gossip.news_daily_budget), at the
## gossip's closeness chance (its own seeded roll). News never takes the place of a moral story, and is not counted in
## the moral budget or the lies' motive; it moves no judgment. Returns how many were told.
func _tell_news(teller: int, listener: int, mem: Dictionary, heard: Dictionary) -> int:
	if _g_news_per <= 0 or int(news_told_today.get(teller, 0)) >= _g_news_budget:
		return 0
	var cand := []
	for ev in mem:
		var m: PackedInt64Array = mem[ev]
		if _news[m[M_TYPE]] == 0 or not facts.has(ev) or heard.has(ev) or _mem_names(m, listener):
			continue
		cand.append(int(ev))
	if cand.is_empty():
		return 0
	cand.sort()
	cand.reverse()                                # the newest first (news ids rise with time)
	var cred := credibility(listener, teller)
	var k := 0
	for ev in cand:
		if k >= _g_news_per or int(news_told_today.get(teller, 0)) >= _g_news_budget:
			break
		if _g_floor < 1000 and JudgmentMath.roll([world_seed, ev, teller, listener, _stamp, day, 7177]) >= close_chance(listener, teller):
			continue
		var m: PackedInt64Array = mem[ev]
		var conf := JudgmentMath.mul_div(m[M_CONF] * _b_hop, cred, 1000000)
		if conf <= 0:
			continue
		learn(listener, ev, "told" if m[M_HOPS] == 0 else "rumour", teller, m[M_HOPS] + 1, conf, _mem_actors(m))
		news_told_today[teller] = int(news_told_today.get(teller, 0)) + 1
		_stat("news_tellings")
		k += 1
	return k


## The chance, permille, that a story a teller could pass on does pass in a meeting: gossip.closeness_floor_permille
## for people with no tie, rising to 1000 with the existing relationship number (regard 0..100). Gossip spreads by
## contact and closeness (owner, X19-Q-TIMING).
func close_chance(a: int, b: int) -> int:
	var reg := clampi(social.regard(a, b), 0, 100)
	return _g_floor + (JudgmentMath.ONE - _g_floor) * reg / 100


# ---------------------------------------------------------------- X19-MISINFO: deliberate lies -----
## Whether fact `ev` is an invented story (tagged ["lie", liar]); the fact is what was SAID, no such deed happened.
func is_lie(ev: int) -> bool:
	var tg: Array = fact_tags.get(ev, [])
	return tg.size() >= 2 and str(tg[0]) == "lie"


func liar_of(ev: int) -> int:
	return int((fact_tags.get(ev, [0, -1]) as Array)[1])


## Whether `person` has a motive to invent a story about `subject` (owner, X19-MISINFO: serious resentment or a rivalry):
## resentment of at least lies.min_resentment, or their NET of the subject at or below the rival line (their tolerance).
func lie_motive(person: int, subject: int) -> bool:
	return bonds.resentment(person, subject) >= _lie_res or net(person, subject) <= threshold(person, _i[6])


## The teller `teller` has just told `listener` real stories about the people in `about`. If the teller has a motive against
## one of them (sorted by id, the first), may invent a story about them: at most one per liar per game year, in
## lies.chance_permille (5%) of such meetings, decided by a seeded hash of the people and the meeting (never World.rng).
## The invented story is a fact tagged as a lie that only the liar's memory and the listener's belief hold. Returns 1 when told.
func _maybe_lie(teller: int, listener: int, about: Dictionary) -> int:
	var gap := _lie_gap if _lie_gap > 0 else Life.year_days()
	if lied.has(teller) and day - int(lied[teller]) < gap:
		return 0
	var subs := about.keys()
	subs.sort()
	for sub_ in subs:
		var who := int(sub_)
		if who == listener or who == teller or not lie_motive(teller, who):
			continue
		if JudgmentMath.roll([world_seed, teller, listener, who, _stamp, day, 9137]) >= _lie_chance:
			return 0
		return 1 if _invent(teller, listener, who) else 0
	return 0


func _invent(liar: int, listener: int, subject: int) -> bool:
	if _lie_types.is_empty():
		return false
	var type := str(_lie_types[JudgmentMath.hash_ints([world_seed, liar, subject, day, 9139]) % _lie_types.size()])
	var ev := publish(type, [subject], [], [], 0, ["lie", liar])
	if ev < 0:
		return false
	lied[liar] = day
	var f: PackedInt64Array = facts[ev]
	var t := f[F_TYPE]
	if not memories.has(liar):
		memories[liar] = {}
		_add_person(liar)
	# the liar holds the story they made up (flag 2): it can be retold, but they judge nobody by it
	(memories[liar] as Dictionary)[ev] = _pack_mem(t, day, TOLD, -1, 0, JudgmentMath.ONE, _sev[t], [[subject, JudgmentMath.ONE]], 2)
	_hold(liar, ev)
	_gver += 1
	var conf := JudgmentMath.mul_div(JudgmentMath.ONE * _b_hop, credibility(listener, liar), 1000000)
	if conf > 0:
		learn(listener, ev, "told", liar, 1, conf, [[subject, JudgmentMath.ONE]])
	told_today[liar] = int(told_today.get(liar, 0)) + 1
	_stat("lies")
	_stat("tellings")
	return true


## A guard (the village's reports show no such crime), or kin of the accused (a firsthand witness of how they live), who
## hears the story knows it false.
func _contradicts(listener: int, actors: Array) -> bool:
	if social.is_guard(listener):
		return true
	for a in actors:
		if social.kin(listener, int(a[0])):
			return true
	return false


## `listener` shows `teller`'s story false: the listener never takes it up, a teller who held it takes back what they had
## judged from it (only those who learn it correct their judgment), and the liar loses rumour_false (15 points) of trust
## with each of them.
## R1 (Expansion 20, X19-MISINFO "proven false corrects the judgment it caused; consequences by intent, harm, repetition"):
## the liar's deed is itself a fact, the catalog's `false_accusation` (actor the liar, victims the accused, tagged
## ["refutes", the lie]), published once per lie (_refutation) and taken in firsthand by both at the meeting. Each judges
## it by the catalog's own rules (BAD, its severity, read through their tie to the accused, as any deed), so each lie shown
## false is judged once more against the liar. It travels by word of mouth like any deed, and whoever later learns of it
## drops what the lie made them think (learn, _drop_lie). Trust: the two at the meeting lose the approved rumour_false
## (15 points), not the catalog's 20 on top of it (_refuting); a told account of it moves trust by the catalog, as any deed.
func _refute(teller: int, listener: int, ev: int, liar: int) -> void:
	_stat("lies_refuted")
	_gver += 1
	_hold(listener, ev)
	var held := teller != liar and (memories.get(teller, {}) as Dictionary).has(ev)
	var rf := _refutation(ev, liar)
	if rf > 0:
		var accused := _fact_people(facts[rf], 0)
		_refuting = true
		for o in ([listener, teller] if held else [listener]):
			if int(o) != liar:
				observe(rf, int(o), "participant" if accused.has(o) else "witnessed")
		_refuting = false
	if listener != liar:
		trust_add(listener, liar, -_t_false)
	if held:
		_drop_lie(teller, ev, liar)                  # already done by learn when it took in the refutation
		trust_add(teller, liar, -_t_false)


## R1: the `false_accusation` fact that shows lie `ev` false: the one already published for it while it lasts, else a new
## one (actor the liar, victims those the lie accused), noted on the lie's tags (["lie", liar, refutation]). -1 when the
## catalog refuses it.
func _refutation(ev: int, liar: int) -> int:
	var tg: Array = fact_tags.get(ev, [])
	if tg.size() >= 3 and facts.has(int(tg[2])):
		return int(tg[2])
	var accused := []
	for a in _fact_actors(facts[ev]):
		accused.append(int(a[0]))
	var rf := publish("false_accusation", [liar], accused, [], 0, ["refutes", ev])
	if rf > 0 and tg.size() >= 2:
		var t2 := tg.duplicate()
		if t2.size() >= 3:
			t2[2] = rf
		else:
			t2.append(rf)
		fact_tags[ev] = t2
	return rf


## R1: `observer` has learned that lie `ev` was shown false: they take back what they judged from it and drop the story
## (never the liar, who judged nobody by it). True when there was anything to take back.
func _drop_lie(observer: int, ev: int, liar: int) -> bool:
	if observer == liar:
		return false
	var mem: Dictionary = memories.get(observer, {})
	var mine: Dictionary = contrib.get(observer, {})
	if not mem.has(ev) and not mine.has(ev):
		return false
	if mine.has(ev):
		_post(observer, ev, {}, false)
		mine.erase(ev)
	mem.erase(ev)
	_hold(observer, ev)
	_gver += 1
	_stat("lies_corrected")
	return true


## `observer`'s memory of `ev` becomes permanent (never fades, never pushed out, its fact never retires): a betrayal by a
## friend is never erased.
func keep_forever(observer: int, ev: int) -> void:
	var mem: Dictionary = memories.get(observer, {})
	if not mem.has(ev):
		return
	var m: PackedInt64Array = mem[ev]
	if (m[M_FLAGS] & 1) == 1:
		return
	m[M_FLAGS] = m[M_FLAGS] | 1
	mem[ev] = m
	_perm_refs[ev] = int(_perm_refs.get(ev, 0)) + 1
	_gver += 1


## Note that `person` has dealt with event `ev` (the dedup key): they will not take it up again.
func _hold(person: int, ev: int) -> void:
	var k: PackedInt64Array = knowers.get(ev, PackedInt64Array())
	var i := k.bsearch(person)
	if i >= k.size() or k[i] != person:
		k.insert(i, person)
		knowers[ev] = k


# ---------------------------------------------------------------- GM-01: historical memory --------------------
## Rule 009 and the owner's directive of 2026-10-19 Part I ("the 30 planks"): a fact can name what it touched and what it
## led to (entity references: a household, a plot, a building, an item and its quantity; links: [kind, target], kinds
## "contributed" and "built"), and a significant deed is kept as a historical record after its fact retires, with who
## knows of it and how: "participant" (took part, or of the households concerned at the time) or "family" (told by a
## parent, generation counted from the record). The record is knowledge, not judgment: it posts nothing to a ledger,
## moves no trust and is never told in gossip, so it changes no decision (judgment-weighted gratitude is for R6 to measure
## first). Numbers in judgment.json "history" (PROVISIONAL agent values).

## Give fact `ev` its entity references and links (`refs`; `links` defaults to none).
func set_refs(ev: int, refs: Dictionary) -> void:
	if not facts.has(ev):
		return
	var r := refs.duplicate(true)
	if not r.has("links"):
		r.links = []
	fact_refs[ev] = r


## The references and links of `ev`: its history record's (which outlives the fact), else the fact's, else {}.
func refs_of(ev: int) -> Dictionary:
	if history.has(ev):
		return history[ev].refs
	return fact_refs.get(ev, {})


## Add a causal link [kind, target] to `ev` (on the fact and on its history record), once.
func add_link(ev: int, kind: String, target: String) -> void:
	for r in [fact_refs.get(ev, null), history[ev].refs if history.has(ev) else null]:
		if r == null:
			continue
		var l := [kind, target]
		if not (r.links as Array).has(l):
			r.links.append(l)


## Whether `ev` is significant enough to become history (the significance rule, judgment.json "history"): a deed of a
## kind in history.types worth at least history.min_value, and at least history.significant_share_permille of what it
## went toward (refs.cost: a house's cost when it was given), when that is known.
func significant(ev: int) -> bool:
	var hc: Dictionary = cfg.get("history", {})
	var f := fact(ev)
	if f.is_empty() or not (hc.get("types", []) as Array).has(str(f.type)):
		return false
	var v := int(f.value)
	if v < int(hc.get("min_value", 1)):
		return false
	var cost := int((fact_refs.get(ev, {}) as Dictionary).get("cost", 0))
	return cost <= 0 or v * 1000 >= int(hc.get("significant_share_permille", 0)) * cost


## Make `ev` history when it is significant: those in `present` know of it firsthand. Returns whether it is history.
func make_history(ev: int, present: Array) -> bool:
	if history.has(ev):
		return true
	if not significant(ev):
		return false
	var f := fact(ev)
	var actors := (f.actors as Array).map(func(a): return int(a[0]) if a is Array else int(a))
	var kn := {}
	for p in present:
		kn[int(p)] = ["participant", -1, 0]
	history[ev] = {"type": str(f.type), "day": int(f.day), "actors": actors, "beneficiaries": (f.beneficiaries as Array).duplicate(),
		"value": int(f.value), "refs": (fact_refs.get(ev, {"links": []}) as Dictionary).duplicate(true), "known": kn}
	_stat("history_records")
	if rec != null:
		rec.history_made(ev, history[ev])      # X20-FINAL (GM-01)
	return true


## The historical records `person` knows of, by event id.
func history_known(person: int) -> Array:
	var out := []
	for ev in _sorted(history):
		if (history[ev].known as Dictionary).has(person):
			out.append(int(ev))
	return out


## A house was finished on `plot` as `building` on day `d`: every fact and record that went toward it now names it.
func building_done(plot: String, building: String, d: int) -> void:
	for which in 2:
		var src: Dictionary = fact_refs if which == 0 else history
		for ev in _sorted(src):
			var r: Dictionary = src[ev] if which == 0 else src[ev].refs
			if str(r.get("plot", "")) == plot and str(r.get("building", "")) == "":
				r.building = building
				r.built_day = d
				add_link(int(ev), "built", "building:" + building)


## `parent` tells `child` the family's history they know, at home as with the family stories (X19-STORY-LIFE): every
## record the parent knows, the child does not, and that is within history.max_generations of the deed. Returns how many.
func tell_family_history(parent: int, child: int) -> int:
	if parent == child:
		return 0
	var gens := int((cfg.get("history", {}) as Dictionary).get("max_generations", 4))
	var n := 0
	for ev in _sorted(history):
		var kn: Dictionary = history[ev].known
		if not kn.has(parent) or kn.has(child):
			continue
		var g := int(kn[parent][2]) + 1
		if g > gens:
			continue
		kn[child] = ["family", parent, g]
		n += 1
		_stat("history_told")
	if rec != null:
		rec.history_told(parent, child, n)      # X20-FINAL (GM-01)
	return n


# ---------------------------------------------------------------- X19-STORY-LIFE: family stories --
## Whether a parent's memory is worth handing down: a permanent one (a killing, an assault, a betrayal) or a good deed at
## least family_story.good_severity serious. Ordinary deeds fade with the rest and are not passed on.
func _story_worthy(m: PackedInt64Array) -> bool:
	if (m[M_FLAGS] & 2) != 0:
		return false                                   # an invented story is not a family story
	if (m[M_FLAGS] & 1) == 1:
		return true
	return _pol[m[M_TYPE]] == 1 and _sev[m[M_TYPE]] >= _story_good


## `parent` tells `child` the family stories they hold, as they would at home: each passes at the gossip rate (the
## closeness chance, a seeded roll of the story and the pair), believed as a told story is (credibility of the parent).
## Returns how many the child took up.
func tell_family_stories(parent: int, child: int) -> int:
	if parent == child or not memories.has(parent):
		return 0
	_cu(parent)
	_cu(child)
	var mem: Dictionary = memories[parent]
	var evs := mem.keys()
	evs.sort()
	var n := 0
	var cred := -1
	for ev in evs:
		var m: PackedInt64Array = mem[ev]
		if not facts.has(ev) or _mem_names(m, child) or not _story_worthy(m):
			continue
		if has_contribution(child, ev) or (memories.get(child, {}) as Dictionary).has(ev):
			continue
		if _g_floor < 1000 and JudgmentMath.roll([world_seed, ev, parent, child, 4241]) >= close_chance(child, parent):
			_stat("stories_withheld")
			continue
		if cred < 0:
			cred = credibility(child, parent)
		var conf := JudgmentMath.mul_div(m[M_CONF] * _b_hop, cred, 1000000)
		if conf <= 0:
			continue
		if learn(child, ev, "told" if m[M_HOPS] == 0 else "rumour", parent, m[M_HOPS] + 1, conf, _mem_actors(m)):
			n += 1
			_stat("family_stories")
	return n


# ---------------------------------------------------------------- X19-EVENT-Q: fights and self-defence --
## A blow `attacker` strikes at `victim` now. Returns true when it is SELF-DEFENCE: the victim had struck first in this same
## fight (a fight ends when no blow has fallen for self_defence.fight_minutes), so the answer is not judged as an attack.
## Otherwise the attacker starts, or goes on with, the fight as its aggressor.
func note_blow(attacker: int, victim: int) -> bool:
	var now := now_minute()
	var k := JudgmentBonds._pk(attacker, victim)
	var f = fights.get(k)
	if f != null and now - int(f[2]) <= _fight_min:
		f[2] = now
		fights[k] = f
		return int(f[0]) != attacker
	fights[k] = [attacker, now, now]
	return false


## Whether `victim` struck first in a fight with `killer` that is still under way (the killing is then self-defence).
func struck_first(victim: int, killer: int) -> bool:
	var f = fights.get(JudgmentBonds._pk(victim, killer))
	return f != null and now_minute() - int(f[2]) <= _fight_min and int(f[0]) == victim


func _end_old_fights() -> void:
	if fights.is_empty():
		return
	var now := now_minute()
	for k in fights.keys():
		if now - int((fights[k] as Array)[2]) > _fight_min:
			fights.erase(k)


# ---------------------------------------------------------------- stubborn choices ---------------
## What `chooser` chose last time in the decision `dkey` ("" if they never did): a stubborn person is slow to give it up.
func last_token(chooser: int, dkey: String) -> String:
	var row: Dictionary = last_choice.get(chooser, {})
	return str((row[dkey] as Array)[0]) if row.has(dkey) else ""


func remember_choice(chooser: int, dkey: String, token: String) -> void:
	if not last_choice.has(chooser):
		last_choice[chooser] = {}
	var row: Dictionary = last_choice[chooser]
	row[dkey] = [token, day]
	if row.size() > 16:                                   # keep the 16 most recent decisions per person
		var oldest := ""
		var od := 1 << 60
		var ks := row.keys()
		ks.sort()
		for k in ks:
			var dd := int((row[k] as Array)[1])
			if dd < od:
				od = dd
				oldest = str(k)
		row.erase(oldest)


## Trust, X19-REGARD (owner 2026-10-23, "separate them"): how far `a` relies on `b`, milli-points 0..100000, apart from
## liking (Relations regard, which still sets gossip closeness). With no evidence yet it is a first impression: regard
## x trust.seed_from_regard_permille; then each deed and each told account that proves right or wrong moves it.
func trust_of(a: int, b: int) -> int:
	var row: Dictionary = trust.get(a, {})
	if row.has(b):
		return int(row[b])
	return clampi(social.regard(a, b), 0, 100) * 1000 * _t_seed / 1000


func trust_add(a: int, b: int, d: int) -> void:
	if a == b or d == 0:
		return
	var cur := trust_of(a, b)
	if not trust.has(a):
		trust[a] = {}
	trust[a][b] = clampi(cur + d, 0, 100000)
	if rec != null:
		rec.trust_move(a, b, cur, int(trust[a][b]))                   # REC-19 D5
	_stat("trust_moves")


## The teller of a story that has met the facts: right (their account matched who did it) or wrong.
func _vouch(listener: int, teller: int, right: bool) -> void:
	if teller >= 0:
		trust_add(listener, teller, _t_true if right else -_t_false)


## How far `listener` believes what `teller` tells them, permille (Q06): credibility_stranger for someone they have no
## record with, rising to 1000 with the listener's trust in the teller (trust_of: its own value, not liking), moved by their judgment of the teller (credibility_permille_per_point a point of NET), within
## credibility_min..1000. Witnesses never need it: firsthand beliefs take belief.witnessed.
func credibility(listener: int, teller: int) -> int:
	var base := _b_cred_stranger + (JudgmentMath.ONE - _b_cred_stranger) * trust_of(listener, teller) / 100000
	return JudgmentMath.clampi_(base + JudgmentMath.mul_div(net(listener, teller), _b_cred_pp, 1000), _b_cred_min, JudgmentMath.ONE)


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
	flush_gossip()                               # the day's meetings belong to it
	_tell_due(d * 1440 - 1)                      # ... scheduled ones too (all fall before dawn; a long skip may have left some)
	finish_dawn()
	_gver += 1
	_reach_cache.clear()
	_steps = d - day
	day = d
	clock_abs = maxi(clock_abs, d * 1440)
	told_today.clear()
	news_told_today.clear()
	_end_old_fights()
	bonds.dawn(d)                                # X19-FOUND-BONDS: softening through personality growth (inert as shipped)
	var cutoff := d - int(c("memory").horizon_days)
	var days := by_day.keys()
	days.sort()
	for dd in days:
		if int(dd) >= cutoff:
			break
		for ev in by_day[dd]:
			if facts.has(ev) and (kept_type((facts[ev] as PackedInt64Array)[F_TYPE]) or _perm_refs.has(ev)):
				_stat("kept_permanent")                # Q11: a permanent record never retires with the ordinary horizon
				continue
			if facts.has(ev):
				facts.erase(ev)
				fact_tags.erase(ev)
				fact_orig.erase(ev)
				fact_refs.erase(ev)                   # GM-01: a significant deed's references live on in its history record
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


## Catch-up for a pure read of `o`'s ledger (see the header), of the entry for `subject` (WHOLE: all of it): their
## queued meetings are told first only if they could change what is read. The day's update is applied as on any touch.
const WHOLE := -1099511627776        # no person has this id: the whole ledger


func _cu_read(o: int, subject := WHOLE) -> void:
	if not _gflushing and _ghead < _gdone.size() and _glast.has(o):
		var last := int(_glast[o])
		if last >= _ghead and _gdone[last] == 0:
			var r := _reach(o)
			var could: Dictionary = r[1]
			if not bool(r[2]) or (subject != WHOLE and not could.has(WHOLE) and not could.has(subject)):
				_stat("read_without_flush")
			else:
				_tell_taken(r[3])
	if not _active or not pending(o):
		return
	_early[o] = true
	_dawn_one(o)


## What `o`'s queued meetings could change in `o`'s ledger: [version, {actor: true} whose entries could change, whether
## anything could, the closure]. Kept while nothing that could change it has happened (_gver): any meeting queued or
## told, any memory learned, corrected or forgotten, a revised fact, a new day. With misattribution, or retraction on
## forgetting, every entry is treated as changeable.
func _reach(o: int) -> Array:
	if _reach_ver != _gver:
		_reach_cache.clear()                     # every entry is out of date once anything has changed: keep none
		_reach_ver = _gver
	var r: Array = _reach_cache.get(o, [])
	if not r.is_empty() and int(r[0]) == _gver:
		return r
	var who := {o: true}
	var take := _closure(o, who)
	var actors := {}
	var any := _learnable(o, who, actors)
	r = [_gver, actors, any, take]
	_reach_cache[o] = r
	return r


## Gathers into `actors` the actors of every memory a queued meeting among `who` could still tell `o` (and, for a more
## confident telling of something `o` holds, the actors `o` believed); true when there is any such memory, or always
## when misattribution or retraction on forgetting make every entry changeable (then `actors` is not to be trusted).
func _learnable(o: int, who: Dictionary, actors: Dictionary) -> bool:
	if _g_mis > 0 or _retract:
		actors[WHOLE] = true
		return true
	var held: Dictionary = memories.get(o, {})
	var mine: Dictionary = contrib.get(o, {})
	var any := false
	for p in who:
		if int(p) == o or not memories.has(p):
			continue
		var mem: Dictionary = memories[p]
		for ev in mem:
			var m: PackedInt64Array = mem[ev]
			if not facts.has(ev) or _mem_names(m, o) or _news[m[M_TYPE]] == 1:
				continue
			if held.has(ev):
				var h: PackedInt64Array = held[ev]
				if h[M_CONF] >= m[M_CONF]:
					continue
				for i in h[M_NA]:
					actors[h[M_NA + 1 + 2 * i]] = true
			elif mine.has(ev):
				continue
			else:
				var kn: PackedInt64Array = knowers.get(ev, PackedInt64Array())
				var at := kn.bsearch(o)
				if at < kn.size() and kn[at] == o:
					continue
			for i in m[M_NA]:
				actors[m[M_NA + 1 + 2 * i]] = true
			any = true
	return any


## Catch-up on touch: apply today's update to `o` if it is still pending, before anything reads or changes their
## records.
func _cu(o: int) -> void:
	if not _gflushing and _ghead < _gdone.size():
		_flush_for(o)
	if not _active or not pending(o):
		return
	_early[o] = true
	_dawn_one(o)


## One person's daily update: their ordinary memories fade (for each day the update covers) and the faint are
## forgotten, then their records of retired events go. The fading parts of their judgments decay (Q02) entry by entry
## when next read or changed (_ldecay), the same steps; a murder's permanent part never decays.
func _dawn_one(o: int) -> void:
	var mem: Dictionary = memories.get(o, {})
	if not mem.is_empty():
		var gone := []
		for ev in mem:
			var m: PackedInt64Array = mem[ev]
			if (m[M_FLAGS] & 1) == 1:
				continue                           # a permanent memory never fades (Q11)
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
	# the fading parts of the person's ledgers decay when each entry is next read or changed (_ldecay): the same steps


## One day's decay of a fading part: its share at the rate, rounded, and at least one milli-point while anything is
## left (so a small remainder fades out instead of sticking where the rounded share is 0).
func _decay_step(v: int) -> int:
	if v <= 0:
		return 0
	return maxi(1, JudgmentMath.scale(v, _decay))


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
	return {"good": l[0], "bad": l[1], "net": net(observer, subject), "fading": [l[3], l[4]], "permanent": [l[5], l[6]],
		"contributions": l[2], "memories": why}


func counts() -> Dictionary:
	flush_gossip()
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
		nl += (ledgers[o][0] as PackedInt64Array).size()
	return {"facts": facts.size(), "memories": nm, "contributions": nc, "ledgers": nl}


# ---------------------------------------------------------------- saving -------------------------
## The provisional save section (World "judgment"; SAVE_VERSION unchanged: an older save simply has none). Lists
## sorted by id, so the same state always writes the same text. Any pending daily update is applied first (it gives
## the same state whenever it is applied).
func to_dict() -> Dictionary:
	if not unread.is_empty():
		return unread.duplicate(true)
	flush_gossip()
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
			ms.append([int(o), int(ev), _types[m[M_TYPE]], m[M_DAY], _mem_actors(m), SOURCES[m[M_SRC]], m[M_BY], m[M_HOPS], m[M_CONF], m[M_SAL], m[M_FLAGS]])
	for o in _sorted(contrib):
		for ev in _sorted(contrib[o]):
			var row: PackedInt64Array = contrib[o][ev]
			for i in range(0, row.size(), 3):
				cs.append([int(o), int(ev), row[i], row[i + 1], row[i + 2]])
	for o in _sorted(ledgers):
		var rec: Array = ledgers[o]
		var subs: PackedInt64Array = rec[0]
		for i in subs.size():
			_ldecay(rec, i)
			var v: PackedInt64Array = rec[1]
			var b := L_W * i
			ls.append([int(o), subs[i], v[b], v[b + 1], v[b + 2], v[b + 3], v[b + 4], v[b + 5], v[b + 6]])
	var tt := []
	for t in _sorted(told_today):
		tt.append([int(t), int(told_today[t])])
	var out := {"format": FORMAT, "version": VERSION, "day": day, "next_event": next_event, "facts": fs, "memories": ms,
		"contrib": cs, "ledgers": ls, "told_today": tt}
	if next_news != NEWS_BASE:
		out.next_news = next_news                # A5: news ids (optional: a section without news has none)
	if not news_told_today.is_empty():
		var nt := []
		for t in _sorted(news_told_today):
			nt.append([int(t), int(news_told_today[t])])
		out.news_told_today = nt
	if not trust.is_empty():
		var tr := []
		for o in _sorted(trust):
			for sub_ in _sorted(trust[o]):
				tr.append([int(o), int(sub_), int(trust[o][sub_])])
		out.trust = tr                           # X19-REGARD: only pairs with a record (older sections have none)
	if not life.is_empty():
		var lf := []
		for o in _sorted(life):
			lf.append([int(o), int(life[o])])
		out.life = lf                            # SJD-Q13: the disposition-weight shifts (older sections have none; the tolerance shift is under traits.tol)
	var pt := pers.to_dict()
	if not pt.is_empty():
		out.traits = pt                          # X19-FOUND-PERS: traits, wisdom, anger, history (older sections have none)
	if not bonds.is_empty():
		out.bonds = bonds.to_dict()              # X19-FOUND-BONDS: optional key (older sections have none)
	if not _sched.is_empty():
		var sc := []
		for mm in _sorted(_sched):
			var row: PackedInt64Array = _sched[mm]
			for i in range(0, row.size(), 2):
				sc.append([int(mm), row[i], row[i + 1]])
		out.scheduled = sc                       # scheduled timing: meetings whose minute has not come yet
	out.clock = now_minute()                     # Build 19 keys below, each written only when it has something (version 1 sections have none)
	if not lied.is_empty():
		var ld := []
		for o in _sorted(lied):
			ld.append([int(o), int(lied[o])])
		out.lied = ld                            # X19-MISINFO: when each liar last invented a story
	if not story_pending.is_empty():
		var sp := []
		for o in _sorted(story_pending):
			sp.append([int(o), int(story_pending[o][0]), int(story_pending[o][1])])
		out.stories = sp                         # X19-STORY-LIFE: new adults not yet told their family stories
	if not last_choice.is_empty():
		var lc := []
		for o in _sorted(last_choice):
			for k in _sorted(last_choice[o]):
				lc.append([int(o), str(k), str(last_choice[o][k][0]), int(last_choice[o][k][1])])
		out.choices = lc                         # stubborn people's last choices
	if not fights.is_empty():
		var fl := []
		for k in _sorted(fights):
			var f: Array = fights[k]
			fl.append([int((k >> 32) - JudgmentBonds.FAR), JudgmentBonds._lo(k), int(f[0]), int(f[1]), int(f[2])])
		out.fights = fl                          # fights under way (self-defence)
	if not fact_refs.is_empty():
		var rf := []
		for ev in _sorted(fact_refs):
			rf.append([int(ev), (fact_refs[ev] as Dictionary).duplicate(true)])
		out.refs = rf                            # GM-01 (version 3): facts' entity references and links
	if not history.is_empty():
		var hs := []
		for ev in _sorted(history):
			var h: Dictionary = history[ev]
			var kn := []
			for p in _sorted(h.known):
				kn.append([int(p), str(h.known[p][0]), int(h.known[p][1]), int(h.known[p][2])])
			hs.append([int(ev), str(h.type), int(h.day), (h.actors as Array).duplicate(), (h.beneficiaries as Array).duplicate(), int(h.value),
					(h.refs as Dictionary).duplicate(true), kn])
		out.history = hs                         # GM-01 (version 3): the historical records and who knows each
	var ad := asp.to_dict()
	if not ad.is_empty():
		out.aspire = ad                          # R5 (version 4): aspirations; absent (and version 3) while off or empty
		out.version = ASPIRE_VERSION
	return out


static func _sorted(d: Dictionary) -> Array:
	var ks := d.keys()
	ks.sort()
	return ks


## Load a saved section. {} (a save from before judgment: every Build 16 save) gives an empty store. A section of an
## unknown format, a newer version, or naming an event type this catalog lacks is refused with a message and kept
## unread, written back unchanged, never dropped (CLAUDE.md section 7). Returns "" or the reason it was not read.
func load_dict(d: Dictionary) -> String:
	for x in [facts, fact_tags, fact_orig, knowers, by_day, memories, contrib, ledgers, trust, told_today, news_told_today, life, _early, _retiring, lied, story_pending, last_choice, fights, fact_refs, history]:
		(x as Dictionary).clear()
	pers.clear()
	_people = PackedInt64Array()
	_queue = PackedInt64Array()
	_qi = 0
	_active = false
	_gq = PackedInt64Array()
	_gdone = PackedByteArray()
	_ghead = 0
	_glast.clear()
	_perm_refs.clear()
	_reach_cache.clear()
	_gver += 1
	_sched.clear()
	_snext = -1
	clock_abs = 0
	bonds.load_dict({})
	asp.load_dict({})
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
	if not m.has("error"):
		var pe := JudgmentPersonality.error_of(m.get("traits", null))
		if pe != "":
			m = {"error": pe}
	if m.has("error"):
		unread = d.duplicate(true)
		return str(m.error)
	day = int(m.day)
	next_event = int(m.next_event)
	next_news = int(m.get("next_news", NEWS_BASE))           # A5: an older section has no news
	for r in m.get("news_told_today", []):
		news_told_today[int(r[0])] = int(r[1])
	for r in m.facts:
		var id := int(r[0])
		facts[id] = _pack_fact(int(_tix[str(r[1])]), int(r[2]), int(r[8]), int(r[6]), _ints2(r[3]), (r[4] as Array).map(func(x): return int(x)),
				(r[5] as Array).map(func(x): return int(x)))
		if not (r[7] as Array).is_empty():
			fact_tags[id] = (r[7] as Array).map(func(x): return int(x) if x is float and x == floorf(x) else x)    # JSON reads whole numbers as floats: ["lie", liar] keeps its integer
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
		var flags := int(r[10]) if (r as Array).size() > 10 else (1 if _perm_legacy[int(_tix[str(r[2])])] == 1 else 0)   # round-1..3 rows: by type, the rule they were saved under
		memories[int(r[0])][int(r[1])] = _pack_mem(int(_tix[str(r[2])]), int(r[3]), SOURCES.find(str(r[5])), int(r[6]), int(r[7]), int(r[8]), int(r[9]), _ints2(r[4]), flags)
		if (flags & 1) == 1:
			_perm_refs[int(r[1])] = int(_perm_refs.get(int(r[1]), 0)) + 1
	for r in m.contrib:
		var o := int(r[0])
		var ev := int(r[1])
		if not contrib.has(o):
			contrib[o] = {}
		var row: PackedInt64Array = (contrib[o] as Dictionary).get(ev, PackedInt64Array())
		row.append_array(PackedInt64Array([int(r[2]), int(r[3]), int(r[4])]))
		contrib[o][ev] = row
	for r in m.ledgers:
		var pg := int(r[7]) if (r as Array).size() > 8 else 0        # round-1..3 rows have no permanent part
		var pb := int(r[8]) if (r as Array).size() > 8 else 0
		var i := _lslot(int(r[0]), int(r[1]), false)
		var rec: Array = ledgers[int(r[0])]
		var v: PackedInt64Array = rec[1]
		rec[1] = _none
		var vals := [int(r[2]), int(r[3]), int(r[4]), int(r[5]), int(r[6]), pg, pb, day]
		for k in L_W:
			v[L_W * i + k] = vals[k]
		rec[1] = v
	for r in m.told_today:
		told_today[int(r[0])] = int(r[1])
	for r in m.get("trust", []):
		if not trust.has(int(r[0])):
			trust[int(r[0])] = {}
		trust[int(r[0])][int(r[1])] = clampi(int(r[2]), 0, 100000)
	pers.load_dict(m.get("traits", {}))
	for r in m.get("life", []):
		if (r as Array).size() >= 3:                  # the older layout [person, tolerance, weight]: the tolerance part moves to the personality layer
			pers.adopt_life_tolerance(int(r[0]), clampi(int(r[1]), -_shift_max, _shift_max))
			if int(r[2]) != 0:
				life[int(r[0])] = clampi(int(r[2]), -_shift_max, _shift_max)
		elif int(r[1]) != 0:
			life[int(r[0])] = clampi(int(r[1]), -_shift_max, _shift_max)
	bonds.load_dict(m.get("bonds", {}))
	clock_abs = maxi(int(m.get("clock", 0)), day * 1440)
	for r in m.get("lied", []):
		lied[int(r[0])] = int(r[1])
	for r in m.get("stories", []):
		story_pending[int(r[0])] = [int(r[1]), int(r[2])]
	for r in m.get("choices", []):
		if not last_choice.has(int(r[0])):
			last_choice[int(r[0])] = {}
		last_choice[int(r[0])][str(r[1])] = [str(r[2]), int(r[3])]
	for r in m.get("fights", []):
		fights[JudgmentBonds._pk(int(r[0]), int(r[1]))] = [int(r[2]), int(r[3]), int(r[4])]
	for r in m.get("refs", []):                  # GM-01: absent in version 1-2 sections (no references, no links)
		if facts.has(int(r[0])):
			fact_refs[int(r[0])] = _whole(r[1])
	for r in m.get("history", []):
		var kn := {}
		for k in r[7]:
			kn[int(k[0])] = [str(k[1]), int(k[2]), int(k[3])]
		history[int(r[0])] = {"type": str(r[1]), "day": int(r[2]), "actors": _whole(r[3]), "beneficiaries": _whole(r[4]), "value": int(r[5]),
				"refs": _whole(r[6]), "known": kn}
	var ae := asp.load_dict(m.get("aspire", {}))     # R5: absent before version 4 (no shifts, survival 0; the first dawn sets the bands)
	if ae != "":
		_stat("aspire_unread")
	for r in m.get("scheduled", []):
		if _g_sched:
			meet_at(int(r[1]), int(r[2]), int(r[0]))
		else:
			meet_later(int(r[1]), int(r[2]))      # saved under "scheduled", loaded under "hour": queued in minute order, none lost
	for d2 in [memories, contrib, ledgers]:
		for o in d2:
			_add_person(int(o))
	return ""


## JSON reads whole numbers as floats: give them back as integers, through dictionaries and arrays.
static func _whole(v):
	if v is float and v == floorf(v):
		return int(v)
	if v is Array:
		return (v as Array).map(func(x): return _whole(x))
	if v is Dictionary:
		var o := {}
		for k in v:
			o[k] = _whole(v[k])
		return o
	return v


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
	if int(d.get("version", 0)) > MAX_VERSION:
		return {"error": "judgment section version %d is newer than this game's %d: kept unread" % [int(d.version), MAX_VERSION]}
	# version 1 (Builds 16-18 prototype sections) -> 2: nothing is rewritten here; the Build 19 keys (clock, lied, stories,
	# choices, fights) are optional and absent in version 1, and "traits" v1 (anger in days) is converted by its own loader
	# version 2 -> 3 (GM-01): nothing is rewritten; the keys refs and history are optional and absent before (no links, no
	# historical records: a Build 19-22 save loads with none and gains them from the deeds done after it is loaded)
	# version 3 -> 4 (R5, WDR-011-C): nothing is rewritten; the key aspire is optional (no shifts, survival 0, no false
	# crossing: the first dawn only sets the bands); it is written back as version 4 only while it has rows
	for k in ["facts", "memories", "contrib", "ledgers"]:
		if not (d.get(k, null) is Array):
			return {"error": "judgment section damaged (no %s): kept unread" % k}
	var out := d.duplicate(true)
	if not out.has("told_today"):
		out.told_today = []
	out.version = VERSION                              # read as the current layout; written back as the current version (4 only with aspire rows)
	return out


## A hash of the whole state (determinism tests: same seed and events, same hash).
func state_hash() -> int:
	var d := to_dict()
	d.erase("clock")          # when the world last told the store the time is not state: telling at once or over ticks ends the same
	return JSON.stringify(d).hash()
