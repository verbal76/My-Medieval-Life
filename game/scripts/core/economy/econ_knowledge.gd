class_name EconKnowledge
extends RefCounted
## Expansion 20 (Living Economy), LE-01 record, LE-02 sources and reliability: the knowledge record (design s.3 Knowledge,
## s.13: "Never grant every NPC global market knowledge"). DISABLED and isolated: World builds it only when
## game/data/economy.json "enabled" is true. LE-02's market (EconMarket) reads it to price and to choose whom to approach.
##
## Entry {knower, subject, item, side: sells|buys, price_each (-1 unknown), offer (-1 none), source, latest, via,
## learned_day, learned_minute, seen_day, location}: "knower knows that subject sells (or buys) item, last at price_each, as
## of seen_day". One entry per (knower, subject, item, side): newer news replaces the price, seen_day, latest (the source of
## that news) and via; the first source and learned_day stay. News older than what the knower holds changes nothing. So the
## record grows with who has dealt with whom in what, never with time. Age = today - seen_day (age()).
##
## Sources (SOURCES_OPEN), every one an existing means or one the owner approved:
##   own            the actor's own offer (posted through EconOffers)
##   dealing        a completed World.trade between the two (both learn: the buyer that the seller sells at that price, the
##                  seller that the buyer buys); the same dealing Relations.note_trade records as a commercial contact
##   contract       the two parties of a CON-01 contract learn its item and price (Contracts records)
##   in_person      owner OD-LE-02B (D01 answer C, APPROVED): offers are local to real encounters, stalls and direct
##                  dialogue: what one villager sees of another's open offers when they meet (EconMarket.on_encounter, on
##                  Relations.share's shared hour) and the quotes said in a negotiation
##   word_of_mouth  owner OD-LE-10 (D09 answer C, APPROVED): price knowledge passes by the EXISTING gossip (the meetings the
##                  judgment store tells at, JudgmentStore._meet_now -> EconMarket.on_meeting), only what the teller genuinely
##                  learned firsthand, with its age (the teller's seen_day travels with it) and `via` (who told), so its trust
##                  is read from the shared judgment model (reliability)
## Refused (SOURCES_REFUSED; learn returns false and counts it, nothing recorded):
##   notice         OD-LE-02B D01: there is no universal offer board
##   rumour         OD-LE-10 D09: no separate price-rumour engine; heard prices travel only as word_of_mouth
## NO TRUST, OPINION OR REPUTATION STORED HERE (owner rule 2026-10-26): an entry is a commercial fact. How far a heard price is
## believed is computed when asked (reliability) from the shared model: JudgmentStore.credibility(listener, teller), the
## gossip system's own measure. What a knower THINKS of the subject is read where a decision is weighed
## (JudgmentWeighting.choose, EconMarket). Never a fixed regard or reputation cutoff.
## Memory (OD-LE-10 D09: "may be wrong or stale"): firsthand entries are kept (bounded by pairs and items); reliability falls
## with age (half_life_days, PROVISIONAL engineering parameter); hearsay is bounded per knower (max_hearsay, PROVISIONAL): past
## it the knower's oldest hearsay is forgotten first. A stale price is not corrected by anyone: it stays wrong until news comes.
## Travel feasibility (design s.3) is not a stored field: `location` is recorded and the market judges the route.
##
## Indexes: by knower, by knower and item, and by (subject, item); no population scan. Deterministic: entries keyed by a stable
## string, every listing sorted. Saved (the LE-02 fields optional: an LE-01 entry loads with latest = source, via "").

const MEMORY := "OD-LE-10 D09: firsthand kept; reliability decays with age; hearsay bounded per knower (max_hearsay)"
const SOURCES_OPEN := ["own", "dealing", "contract", "in_person", "word_of_mouth"]
const FIRSTHAND := ["own", "dealing", "contract", "in_person"]
const SOURCES_REFUSED := {"notice": "OD-LE-02B D01: no universal offer board",
	"rumour": "OD-LE-10 D09: no separate price-rumour engine (heard prices travel only as word_of_mouth)"}
const SELLS := "sells"
const BUYS := "buys"

var actors: EconActor
var half_life_days := 7.0
var max_hearsay := 40
var hearsay_without_judgment := 0.5
var entries := {}               # key -> entry
var _by_knower := {}            # knower -> {key: true}
var _by_knower_item := {}       # knower + "|" + item -> {key: true}
var _by_subject := {}           # subject + "|" + item -> {key: true}
var refused := {}               # source -> times a learn by a refused source was refused (diagnostics)
var forgotten := 0              # hearsay entries dropped by the max_hearsay bound (diagnostics)


func _init(actors_: EconActor, cfg := {}) -> void:
	actors = actors_
	half_life_days = maxf(0.5, float(cfg.get("half_life_days", 7.0)))
	max_hearsay = maxi(1, int(cfg.get("max_hearsay", 40)))
	hearsay_without_judgment = clampf(float(cfg.get("hearsay_without_judgment", 0.5)), 0.0, 1.0)


static func key(knower: String, subject: String, item: String, side: String) -> String:
	return "%s|%s|%s|%s" % [knower, subject, item, side]


## Records that `knower` learned of `subject` dealing in `item`. False (nothing recorded) for a refused or unknown source,
## an unknown knower or subject, a knower learning about itself by anything but its own offer, word_of_mouth without a
## teller (`via`, another known actor), or news older than what the knower already holds. `seen` is the day the news is
## of (word of mouth carries the teller's; -1 today).
func learn(knower: String, subject: String, item: String, side: String, price_each := -1, source := "dealing", offer := -1, location := "", seen := -1, via := "") -> bool:
	if SOURCES_REFUSED.has(source):
		refused[source] = int(refused.get(source, 0)) + 1
		return false
	if not source in SOURCES_OPEN or not side in [SELLS, BUYS] or item == "":
		return false
	if not actors.exists(knower) or not actors.exists(subject):
		return false
	if (knower == subject) != (source == "own"):
		return false
	if source == "word_of_mouth" and (via == "" or via == knower or not actors.exists(via)):
		return false
	if source != "word_of_mouth":
		via = ""
	var w := actors.w
	var day := w.day() if seen < 0 else mini(seen, w.day())
	var k := key(knower, subject, item, side)
	var e: Dictionary = entries.get(k, {})
	if e.is_empty():
		e = {"knower": knower, "subject": subject, "item": item, "side": side, "price_each": price_each, "offer": offer, "source": source,
			"latest": source, "via": via, "learned_day": w.day(), "learned_minute": int(fmod(w.minutes, World.DAY)), "seen_day": day,
			"location": location if location != "" else actors.location(subject)}
		entries[k] = e
		_add(_by_knower, knower, k)
		_add(_by_knower_item, knower + "|" + item, k)
		_add(_by_subject, subject + "|" + item, k)
		if source == "word_of_mouth":
			_bound_hearsay(knower)
		return true
	if day < int(e.seen_day) or (day == int(e.seen_day) and source == "word_of_mouth" and str(e.latest) in FIRSTHAND):
		return false                   # older news, or hearsay of the same day as what the knower saw for itself
	e.seen_day = day
	e.latest = source
	e.via = via
	if price_each >= 0:
		e.price_each = price_each
	if offer >= 0:
		e.offer = offer
	return true


## Copies of what `knower` knows, optionally of one item and side, sorted by key.
func known_by(knower: String, item := "", side := "") -> Array:
	var out := []
	var ks: Array = (_by_knower_item.get(knower + "|" + item, {}) if item != "" else _by_knower.get(knower, {})).keys()
	ks.sort()
	for k in ks:
		var e: Dictionary = entries[k]
		if side == "" or e.side == side:
			out.append(e.duplicate())
	return out


## Who knows that `subject` deals in `item` (sorted knower refs).
func knowers_of(subject: String, item: String) -> Array:
	var out := []
	for k in _by_subject.get(subject + "|" + item, {}):
		out.append(entries[k].knower)
	out.sort()
	return out


func knows(knower: String, subject: String, item: String, side: String) -> bool:
	return entries.has(key(knower, subject, item, side))


func get_entry(knower: String, subject: String, item: String, side: String) -> Dictionary:
	return entries.get(key(knower, subject, item, side), {}).duplicate()


func age(e: Dictionary) -> int:
	return actors.w.day() - int(e.seen_day)


## OD-LE-10 D09: how far an entry is to be believed, 0..1, computed now and never stored: the trust in its source (firsthand 1;
## word of mouth the listener's credibility of the teller from the shared judgment model, JudgmentStore.credibility, the
## measure gossip itself uses; hearsay_without_judgment when judgment is off) times its freshness (halved every
## half_life_days of age). The economy computes no trust of its own.
func reliability(e: Dictionary) -> float:
	var trust := 1.0
	if str(e.get("latest", e.get("source", ""))) == "word_of_mouth":
		var j = actors.w.judgment
		var me := actors.judged_person(str(e.knower))
		var teller := actors.judged_person(str(e.get("via", "")))
		if j != null and me != -1 and teller != -1:
			trust = float(j.credibility(me, teller)) / float(JudgmentMath.ONE)
		else:
			trust = hearsay_without_judgment
	return clampf(trust * pow(0.5, float(maxi(0, age(e))) / half_life_days), 0.0, 1.0)


## The knower's firsthand entries, freshest first (then by key): what it may tell another (word of mouth).
func firsthand_of(knower: String) -> Array:
	var out := []
	var ks: Array = _by_knower.get(knower, {}).keys()
	ks.sort()
	for k in ks:
		var e: Dictionary = entries[k]
		if str(e.latest) in FIRSTHAND and str(e.subject) != knower and int(e.price_each) >= 0:
			out.append(e)
	out.sort_custom(func(a, b): return int(a.seen_day) > int(b.seen_day) or (int(a.seen_day) == int(b.seen_day) and key(a.knower, a.subject, a.item, a.side) < key(b.knower, b.subject, b.item, b.side)))
	return out


func _bound_hearsay(knower: String) -> void:
	var heard := []
	for k in _by_knower.get(knower, {}):
		if str(entries[k].latest) == "word_of_mouth":
			heard.append(k)
	if heard.size() <= max_hearsay:
		return
	heard.sort_custom(func(a, b): return int(entries[a].seen_day) < int(entries[b].seen_day) or (int(entries[a].seen_day) == int(entries[b].seen_day) and a < b))
	for i in heard.size() - max_hearsay:
		_drop(heard[i])
		forgotten += 1


func _drop(k: String) -> void:
	var e: Dictionary = entries[k]
	entries.erase(k)
	for pair in [[_by_knower, str(e.knower)], [_by_knower_item, str(e.knower) + "|" + str(e.item)], [_by_subject, str(e.subject) + "|" + str(e.item)]]:
		var m: Dictionary = pair[0]
		if m.has(pair[1]):
			(m[pair[1]] as Dictionary).erase(k)
			if (m[pair[1]] as Dictionary).is_empty():
				m.erase(pair[1])


func size() -> int:
	return entries.size()


func is_empty() -> bool:
	return entries.is_empty()


func to_dict() -> Dictionary:
	var ks: Array = entries.keys()
	ks.sort()
	var arr := []
	for k in ks:
		arr.append(entries[k].duplicate())
	return {"entries": arr}


func load_dict(d: Dictionary) -> void:
	entries = {}
	_by_knower = {}
	_by_knower_item = {}
	_by_subject = {}
	for x in d.get("entries", []):
		var e := {"knower": str(x.knower), "subject": str(x.subject), "item": str(x.item), "side": str(x.side), "price_each": int(x.price_each),
			"offer": int(x.offer), "source": str(x.source), "latest": str(x.get("latest", x.source)), "via": str(x.get("via", "")),
			"learned_day": int(x.learned_day), "learned_minute": int(x.learned_minute), "seen_day": int(x.seen_day), "location": str(x.location)}
		var k := key(e.knower, e.subject, e.item, e.side)
		entries[k] = e
		_add(_by_knower, e.knower, k)
		_add(_by_knower_item, e.knower + "|" + e.item, k)
		_add(_by_subject, e.subject + "|" + e.item, k)


static func _add(m: Dictionary, a: String, k: String) -> void:
	if not m.has(a):
		m[a] = {}
	m[a][k] = true
