class_name EconKnowledge
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the knowledge record (design s.3 Knowledge, s.13: "Never grant every NPC global market
## knowledge"). DISABLED and isolated: World builds it only when game/data/economy.json "enabled" is true; nothing in live play
## reads it to decide (today's villagers still find sellers by the existing searches, NPCBrain._seller_of / _buyer_for; LE-02
## is where decisions start reading this instead).
##
## Entry {knower, subject, item, side: sells|buys, price_each (-1 unknown), offer (-1 none), source, learned_day,
## learned_minute, seen_day, location}: "knower knows that subject sells (or buys) item, last at price_each, as of seen_day".
## One entry per (knower, subject, item, side): newer news replaces the price and seen_day, the first source and learned_day
## stay. So the record grows with who has dealt with whom in what, never with time. Age = today - seen_day (age()).
##
## Only EXISTING means grant knowledge (SOURCES_OPEN):
##   own       the actor's own offer (posted through EconOffers)
##   dealing   a completed World.trade between the two (both learn: the buyer that the seller sells at that price, the seller
##             that the buyer buys); the same dealing Relations.note_trade already records as a commercial contact (X18-Q12-POST)
##   contract  the two parties of a CON-01 contract learn its item and price (Contracts records)
## Means an owner decision governs are REFUSED (learn returns false, nothing recorded) until the owner answers:
##   in_person, notice      OWNER DECISION OD-LE-02B (offer visibility: in person at stalls and meetings, a notice board)
##   word_of_mouth, rumour  OWNER DECISION OD-LE-10 (economic rumour, memory persistence and reliability)
## NO TRUST, OPINION OR REPUTATION HERE (owner rule 2026-10-26, docs/directives/2026-10-26_build19_carryover_audit_x20_integration.md
## s.7): an entry is a commercial fact (who deals in what, at what price, learned how). What a knower THINKS of the subject is
## the shared Expansion 19 model's and is read there when a decision needs it: JudgmentStore.trust_of, Relations.peek().regard,
## JudgmentSocial.regard, chosen among feasible options by JudgmentWeighting.choose (as JudgmentLive.pick_seller does), with
## EconActor.judged_person mapping an economy ref to the person judged. Nothing in LE-01 reads or decides on opinion.
## DECISION SEAM (LE-02 onward; owner rule 2026-10-26): opinion is ONE weighed factor beside need, scarcity, alternatives,
## price, relationships and personality in JudgmentWeighting.choose. An NPC may refuse a deal because of it and another in the
## same circumstances may deal out of necessity: never a fixed regard or reputation cutoff that refuses automatically, never a
## rule or clamp that keeps every deal possible regardless of preference. Weights and formulas are owner-held.
## Reliability and forgetting: OWNER DECISION OD-LE-10. Placeholder: no confidence is computed (reliability() returns
## RELIABILITY_UNDECIDED) and nothing is forgotten or decays; an entry only ever has its price and seen_day refreshed.
## Travel feasibility (design s.3) is not a stored field: `location` is recorded and LE-02 judges the route.
##
## Indexes: by knower and by (subject, item); no population scan. Deterministic: entries keyed by a stable string, every
## listing sorted. Saved.

## OWNER DECISION OD-LE-10 (economic rumour, memory persistence and reliability). Placeholders, read by nothing that decides.
const RELIABILITY_UNDECIDED := -1.0
const MEMORY := "OWNER DECISION OD-LE-10: undecided; nothing decays or is forgotten"
const SOURCES_OPEN := ["own", "dealing", "contract"]
const SOURCES_UNDECIDED := {"in_person": "OD-LE-02B", "notice": "OD-LE-02B", "word_of_mouth": "OD-LE-10", "rumour": "OD-LE-10"}
const SELLS := "sells"
const BUYS := "buys"

var actors: EconActor
var entries := {}               # key -> entry
var _by_knower := {}            # knower -> {key: true}
var _by_subject := {}           # subject + "|" + item -> {key: true}
var refused := {}               # source -> times a learn by an undecided source was refused (diagnostics)


func _init(actors_: EconActor) -> void:
	actors = actors_


static func key(knower: String, subject: String, item: String, side: String) -> String:
	return "%s|%s|%s|%s" % [knower, subject, item, side]


## Records that `knower` learned of `subject` dealing in `item`. False (nothing recorded) for an undecided or unknown
## source, an unknown knower or subject, or a knower learning about itself by anything but its own offer.
func learn(knower: String, subject: String, item: String, side: String, price_each := -1, source := "dealing", offer := -1, location := "") -> bool:
	if SOURCES_UNDECIDED.has(source):
		refused[source] = int(refused.get(source, 0)) + 1
		return false
	if not source in SOURCES_OPEN or not side in [SELLS, BUYS] or item == "":
		return false
	if not actors.exists(knower) or not actors.exists(subject):
		return false
	if (knower == subject) != (source == "own"):
		return false
	var w := actors.w
	var k := key(knower, subject, item, side)
	var e: Dictionary = entries.get(k, {})
	if e.is_empty():
		e = {"knower": knower, "subject": subject, "item": item, "side": side, "price_each": price_each, "offer": offer, "source": source,
			"learned_day": w.day(), "learned_minute": int(fmod(w.minutes, World.DAY)), "seen_day": w.day(), "location": location if location != "" else actors.location(subject)}
		entries[k] = e
		_add(_by_knower, knower, k)
		_add(_by_subject, subject + "|" + item, k)
	else:
		e.seen_day = w.day()
		if price_each >= 0:
			e.price_each = price_each
		if offer >= 0:
			e.offer = offer
	return true


## Copies of what `knower` knows, optionally of one item and side, sorted by key.
func known_by(knower: String, item := "", side := "") -> Array:
	var out := []
	var ks: Array = _by_knower.get(knower, {}).keys()
	ks.sort()
	for k in ks:
		var e: Dictionary = entries[k]
		if (item == "" or e.item == item) and (side == "" or e.side == side):
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


func age(e: Dictionary) -> int:
	return actors.w.day() - int(e.seen_day)


## OWNER DECISION OD-LE-10: how far an entry is to be trusted. Placeholder: undecided, so always RELIABILITY_UNDECIDED. When
## decided it must read the shared judgment model (trust in the source), never compute a trust of its own.
func reliability(_e: Dictionary) -> float:
	return RELIABILITY_UNDECIDED


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
	_by_subject = {}
	for x in d.get("entries", []):
		var e := {"knower": str(x.knower), "subject": str(x.subject), "item": str(x.item), "side": str(x.side), "price_each": int(x.price_each),
			"offer": int(x.offer), "source": str(x.source), "learned_day": int(x.learned_day), "learned_minute": int(x.learned_minute),
			"seen_day": int(x.seen_day), "location": str(x.location)}
		var k := key(e.knower, e.subject, e.item, e.side)
		entries[k] = e
		_add(_by_knower, e.knower, k)
		_add(_by_subject, e.subject + "|" + e.item, k)


static func _add(m: Dictionary, a: String, k: String) -> void:
	if not m.has(a):
		m[a] = {}
	m[a][k] = true
