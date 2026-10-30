class_name EconOffers
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the offer record (design s.3 Offer, s.5). DISABLED and isolated: World builds it only
## when game/data/economy.json "enabled" is true; LE-02 (EconMarket) posts and settles offers, still only while the switch is on.
##
## Offer {id, side: ask|bid, actor, item, qty, price_each, location, made_day, made_minute, expiry, visibility, state:
## open|withdrawn|expired|filled, filled, reservation, source}.
##   ask: `actor` offers to sell `qty` of `item`; posting RESERVES those goods (EconReservations, purpose "offer:<id>"), so
##        an ask is always over goods the actor really holds and not already held for a contract or another claim.
##   bid: `actor` offers to buy; posting reserves the coins for qty x price_each (item "coins"), so a bid is always backed.
## Invariants:
##  - An offer is not a sale (design s.19: "Treat bids as completed sales" is an anti-pattern): posting, withdrawing, expiring
##    and record_fill move no coin and no good. The transfer is World.trade's, settled by LE-02; record_fill only books, after
##    such a trade, that `qty` of the offer was taken, and shrinks the reservation to the rest (consume, re-reserve).
##  - Prices are given by the caller. LE-01 sets no price: OD-LE-02 (owner, APPROVED: combined market pricing with limited
##    negotiation) is LE-02's to implement; the existing prices (World.sell_price_at, buy_price_at) stay the live ones.
##  - Visibility (owner OD-LE-02B, D01 answer C, APPROVED): offers are LOCAL to real encounters, stalls and direct dialogue.
##    Posting tells nobody but the poster (source "own"); others learn of an offer only by meeting its poster (EconMarket
##    on_encounter: knowledge source "in_person"), by being told it by someone who genuinely knew it (the integrated gossip,
##    source "word_of_mouth", OD-LE-10 D09), or in the negotiation itself. There is no universal offer board: nothing here
##    lists offers to an actor (open_for is an index for the engine and the tests, never read as what an actor knows).
##  - Deterministic: ids count up; listings sorted by id. Indexes by item and by actor (open offers only); no population scan.
##  - Bounded: finished offers beyond `keep_finished` are dropped oldest first.
## LE-02 (owner OD-LE-02, OD-LE-03; docs/expansion20/LE02_IMPLEMENTATION.md) adds optional fields, each defaulted on load so
## an LE-01 save reads unchanged: min_lot (the fewest units a fill may take), committed (units promised by a CON-01 contract
## the offer led to: a commitment, not a transaction), contracts (those contract ids), revisions and reviewed_day (the
## anti-oscillation bookkeeping of EconMarket.review), need (the need kind a bid answers). remaining = qty - filled -
## committed. revise() changes an open offer's price (a bid re-reserves its coins at the new price or keeps the old one);
## commit() books units promised by a contract and shrinks the reservation as record_fill does.

## OD-LE-02B (owner, D01 answer C, APPROVED): recorded on every offer. Local: seen only by those who meet the poster, are
## told by someone who knew, or deal with them (see the header). No offer board.
const VISIBILITY := "local: real encounters, stalls and direct dialogue (OD-LE-02B D01)"
const ASK := "ask"
const BID := "bid"
const OPEN := "open"

var reservations: EconReservations
var events: EconEvents = null
var knowledge: EconKnowledge = null        # the poster knows its own offer (source "own")
var keep_finished := 200
var next_id := 0
var records := {}                 # id -> offer
var _by_item := {}                # item -> Array of open ids (ascending)
var _by_actor := {}               # actor -> Array of open ids (ascending)


func _init(reservations_: EconReservations, cfg := {}) -> void:
	reservations = reservations_
	keep_finished = maxi(0, int(cfg.get("keep_finished", 200)))


## {ok, id, reason}. `location` is a place id the world already uses ("" when none: EconActor.location is the default).
func post(side: String, actor: String, item: String, qty: int, price_each: int, expiry := -1, location := "", source := "", min_lot := 1, need := "") -> Dictionary:
	if not side in [ASK, BID]:
		return _no("side")
	if item == "" or item == EconReservations.COINS:
		return _no("item")
	if qty <= 0 or price_each < 0:
		return _no("quantity or price")
	var w := reservations.actors.w
	if expiry >= 0 and expiry < w.day():
		return _no("already expired")
	var res: Dictionary
	if side == ASK:
		res = reservations.reserve(actor, item, qty, "offer:%d" % next_id, expiry)
	elif qty * price_each > 0:
		res = reservations.reserve(actor, EconReservations.COINS, qty * price_each, "offer:%d" % next_id, expiry)
	else:
		res = {"ok": reservations.actors.alive(actor), "id": -1, "reason": "owner not alive"}     # a bid of nothing holds nothing
	if not res.ok:
		return _no(str(res.reason))
	var o := {"id": next_id, "side": side, "actor": actor, "item": item, "qty": qty, "price_each": price_each,
		"location": location if location != "" else reservations.actors.location(actor), "made_day": w.day(),
		"made_minute": int(fmod(w.minutes, World.DAY)), "expiry": expiry, "visibility": VISIBILITY, "state": OPEN, "filled": 0,
		"reservation": int(res.id), "source": source, "min_lot": clampi(min_lot, 1, qty), "committed": 0, "contracts": [],
		"revisions": 0, "reviewed_day": w.day(), "need": need, "seen_filled": 0, "dialogue_day": -1}
	next_id += 1
	records[o.id] = o
	_index(o)
	if knowledge != null:
		knowledge.learn(actor, actor, item, EconKnowledge.SELLS if side == ASK else EconKnowledge.BUYS, price_each, "own", int(o.id), str(o.location))
	_note("note", o, "offer %s posted" % side)
	return {"ok": true, "id": o.id, "reason": ""}


func withdraw(id: int) -> bool:
	return _finish(id, "withdrawn")


## Books that `qty` of an open offer was taken by a trade that already happened (World.trade, LE-02's settlement); the offer's
## reservation shrinks to the rest. Moves nothing. Refuses more than remains. Returns true when booked.
func record_fill(id: int, qty: int) -> bool:
	if not records.has(id) or records[id].state != OPEN or qty <= 0 or qty > remaining(id):
		return false
	var o: Dictionary = records[id]
	o.filled = int(o.filled) + qty
	_rebook(o)
	_note("note", o, "offer filled %d" % qty)
	if remaining(id) == 0:
		_finish(id, "filled")
	return true


## LE-02: books that `qty` of an open offer was promised by CON-01 contract `contract_id` (a commitment: no goods or coins
## moved; the contract's own escrow holds the buyer's coins). The reservation shrinks to the rest. True when booked.
func commit(id: int, qty: int, contract_id: int) -> bool:
	if not records.has(id) or records[id].state != OPEN or qty <= 0 or qty > remaining(id):
		return false
	var o: Dictionary = records[id]
	o.committed = int(o.committed) + qty
	(o.contracts as Array).append(contract_id)
	_rebook(o)
	_note("note", o, "offer committed %d to contract %d" % [qty, contract_id])
	if remaining(id) == 0:
		_finish(id, "filled")
	return true


## LE-02: a new price for an open offer (EconMarket.review). A bid's coins are reserved again at the new price; when they cannot
## be (the actor no longer holds them) the offer keeps its old price and reservation and false is returned. Counts a revision.
func revise(id: int, price_each: int) -> bool:
	if not records.has(id) or records[id].state != OPEN or price_each < 0:
		return false
	var o: Dictionary = records[id]
	var old := int(o.price_each)
	if old == price_each:
		return true
	if o.side == BID:
		var was := int(o.reservation)
		if was >= 0:
			reservations.release(was)
		var amount := remaining(id) * price_each
		var r := reservations.reserve(str(o.actor), EconReservations.COINS, amount, "offer:%d" % id, int(o.expiry)) if amount > 0 else {"ok": true, "id": -1}
		if not r.ok:
			var back := reservations.reserve(str(o.actor), EconReservations.COINS, remaining(id) * old, "offer:%d" % id, int(o.expiry)) if was >= 0 else {"ok": false, "id": -1}
			o.reservation = int(back.id) if back.ok else -1
			return false
		o.reservation = int(r.id)
	o.price_each = price_each
	o.revisions = int(o.revisions) + 1
	o.reviewed_day = reservations.actors.w.day()
	_note("note", o, "offer price %d -> %d" % [old, price_each])
	return true


## LE-02: an open offer cut to `qty` units in all (no fewer than already filled and committed plus one; the reservation follows).
## Used when an ask's goods or a bid's coins have gone by other means (EconMarket.review). False when refused.
func resize(id: int, qty: int) -> bool:
	if not records.has(id) or records[id].state != OPEN:
		return false
	var o: Dictionary = records[id]
	if qty <= int(o.filled) + int(o.committed) or qty >= int(o.qty):
		return false
	o.qty = qty
	o.min_lot = mini(int(o.min_lot), remaining(id))
	_rebook(o)
	_note("note", o, "offer cut to %d" % qty)
	return true


## The offer's reservation made to cover exactly what remains (consumed, then the rest reserved again).
## LE-03: when the actor no longer holds enough to back what remains (its goods or coins went by another use), the offer is
## cut to what it can back (never left open without its reservation); with less than its lot backable it is withdrawn.
func _rebook(o: Dictionary) -> void:
	var id := int(o.id)
	if int(o.reservation) >= 0:
		reservations.consume(int(o.reservation))
		o.reservation = -1
	var left := remaining(id)
	if left <= 0:
		return
	var item := str(o.item) if o.side == ASK else EconReservations.COINS
	var per := 1 if o.side == ASK else int(o.price_each)
	if per <= 0:
		return                                         # a bid of nothing holds nothing
	var r := reservations.reserve(str(o.actor), item, left * per, "offer:%d" % id, int(o.expiry))
	if r.ok:
		o.reservation = int(r.id)
		return
	var keep := mini(left, reservations.available(str(o.actor), item) / per)
	if keep > 0 and keep >= mini(int(o.min_lot), left):
		o.qty = int(o.filled) + int(o.committed) + keep
		o.min_lot = mini(int(o.min_lot), keep)
		r = reservations.reserve(str(o.actor), item, keep * per, "offer:%d" % id, int(o.expiry))
		if r.ok:
			o.reservation = int(r.id)
			_note("note", o, "offer cut to %d (backing)" % int(o.qty))
			return
	if o.state == OPEN:
		_finish(id, "withdrawn")                       # nothing it can still back


func remaining(id: int) -> int:
	return int(records[id].qty) - int(records[id].filled) - int(records[id].get("committed", 0)) if records.has(id) else 0


## Marks open offers whose expiry day is before `day` expired (their reservations released); returns their ids.
func expire_due(day: int) -> Array:
	var ids: Array = []
	for it in _by_item:
		for id in _by_item[it]:
			var e := int(records[id].expiry)
			if e >= 0 and e < day:
				ids.append(id)
	ids.sort()
	for id in ids:
		_finish(id, "expired")
	return ids


## True when an open offer is still covered by its reservation (an ask whose goods left by a live trade is not).
func backed(id: int) -> bool:
	if not records.has(id) or records[id].state != OPEN:
		return false
	var o: Dictionary = records[id]
	if int(o.reservation) < 0:
		return o.side == BID and int(o.price_each) == 0
	var item := str(o.item) if o.side == ASK else EconReservations.COINS
	for u in reservations.unbacked():
		if u.owner == o.actor and u.item == item:
			return false
	return true


## Open offers for an item (optionally one side), ascending by id (copies). An index read for the engine and tests; what an
## ACTOR may know is EconKnowledge's.
func open_for(item: String, side := "") -> Array:
	var out := []
	for id in _by_item.get(item, []):
		if side == "" or records[id].side == side:
			out.append(records[id].duplicate(true))
	return out


func open_of(actor: String) -> Array:
	var out := []
	for id in _by_actor.get(actor, []):
		out.append(records[id].duplicate(true))
	return out


func get_offer(id: int) -> Dictionary:
	return records[id].duplicate(true) if records.has(id) else {}


func is_empty() -> bool:
	return records.is_empty()


func to_dict() -> Dictionary:
	var ids: Array = records.keys()
	ids.sort()
	var arr := []
	for id in ids:
		arr.append(records[id].duplicate(true))
	return {"next_id": next_id, "records": arr}


func load_dict(d: Dictionary) -> void:
	records = {}
	_by_item = {}
	_by_actor = {}
	next_id = int(d.get("next_id", 0))
	for r in d.get("records", []):
		var o := {"id": int(r.id), "side": str(r.side), "actor": str(r.actor), "item": str(r.item), "qty": int(r.qty), "price_each": int(r.price_each),
			"location": str(r.location), "made_day": int(r.made_day), "made_minute": int(r.made_minute), "expiry": int(r.expiry),
			"visibility": str(r.visibility), "state": str(r.state), "filled": int(r.filled), "reservation": int(r.reservation), "source": str(r.source),
			"min_lot": int(r.get("min_lot", 1)), "committed": int(r.get("committed", 0)), "contracts": (r.get("contracts", []) as Array).map(func(x): return int(x)),
			"revisions": int(r.get("revisions", 0)), "reviewed_day": int(r.get("reviewed_day", r.made_day)), "need": str(r.get("need", "")),
			"seen_filled": int(r.get("seen_filled", 0)), "dialogue_day": int(r.get("dialogue_day", -1))}
		records[o.id] = o
		if o.state == OPEN:
			_index(o)


func _index(o: Dictionary) -> void:
	for pair in [[_by_item, str(o.item)], [_by_actor, str(o.actor)]]:
		var m: Dictionary = pair[0]
		if not m.has(pair[1]):
			m[pair[1]] = []
		m[pair[1]].append(int(o.id))
		m[pair[1]].sort()


func _unindex(o: Dictionary) -> void:
	for pair in [[_by_item, str(o.item)], [_by_actor, str(o.actor)]]:
		var m: Dictionary = pair[0]
		var l: Array = m.get(pair[1], [])
		l.erase(int(o.id))
		if l.is_empty():
			m.erase(pair[1])


func _finish(id: int, state: String) -> bool:
	if not records.has(id) or records[id].state != OPEN:
		return false
	var o: Dictionary = records[id]
	o.state = state
	_unindex(o)
	if int(o.reservation) >= 0:
		reservations.release(int(o.reservation))
		o.reservation = -1
	_note("note", o, "offer " + state)
	_prune()
	return true


func _prune() -> void:
	var done: Array = []
	for id in records:
		if records[id].state != OPEN:
			done.append(id)
	if done.size() <= keep_finished:
		return
	done.sort()
	for i in done.size() - keep_finished:
		records.erase(done[i])


func _note(type: String, o: Dictionary, what: String) -> void:
	if events != null:
		var w := reservations.actors.w
		events.record_at(w.day(), int(fmod(w.minutes, World.DAY)), type, str(o.actor), "", str(o.item), int(o.qty), int(o.qty) * int(o.price_each), "%s #%d" % [what, int(o.id)])


func _no(reason: String) -> Dictionary:
	return {"ok": false, "id": -1, "reason": reason}
