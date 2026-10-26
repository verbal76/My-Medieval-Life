class_name EconOffers
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the offer record (design s.3 Offer, s.5). DISABLED and isolated: World builds it only
## when game/data/economy.json "enabled" is true; nothing in live play posts an offer (LE-02 will).
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
##  - Visibility: OWNER DECISION OD-LE-02B (who can see an offer: in person at stalls and meetings, by word of mouth, a notice
##    board). Placeholder VISIBILITY: every offer carries it; posting tells nobody (EconKnowledge refuses the sources that
##    decision governs), so only the poster knows of its own offer.
##  - Deterministic: ids count up; listings sorted by id. Indexes by item and by actor (open offers only); no population scan.
##  - Bounded: finished offers beyond `keep_finished` are dropped oldest first.

## OWNER DECISION OD-LE-02B (offer visibility). Placeholder: recorded on every offer, read by nothing that decides.
const VISIBILITY := "OWNER DECISION OD-LE-02B: undecided"
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
func post(side: String, actor: String, item: String, qty: int, price_each: int, expiry := -1, location := "", source := "") -> Dictionary:
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
		"reservation": int(res.id), "source": source}
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
	if int(o.reservation) >= 0:
		reservations.consume(int(o.reservation))
		o.reservation = -1
	var left := remaining(id)
	if left > 0:
		var item := str(o.item) if o.side == ASK else EconReservations.COINS
		var amount := left if o.side == ASK else left * int(o.price_each)
		var r := reservations.reserve(str(o.actor), item, amount, "offer:%d" % id, int(o.expiry)) if amount > 0 else {"ok": false, "id": -1}
		o.reservation = int(r.id) if r.ok else -1      # not re-backed: unbacked offers are reported by backed(), never repaired
	_note("note", o, "offer filled %d" % qty)
	if left == 0:
		_finish(id, "filled")
	return true


func remaining(id: int) -> int:
	return int(records[id].qty) - int(records[id].filled) if records.has(id) else 0


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
			out.append(records[id].duplicate())
	return out


func open_of(actor: String) -> Array:
	var out := []
	for id in _by_actor.get(actor, []):
		out.append(records[id].duplicate())
	return out


func get_offer(id: int) -> Dictionary:
	return records[id].duplicate() if records.has(id) else {}


func is_empty() -> bool:
	return records.is_empty()


func to_dict() -> Dictionary:
	var ids: Array = records.keys()
	ids.sort()
	var arr := []
	for id in ids:
		arr.append(records[id].duplicate())
	return {"next_id": next_id, "records": arr}


func load_dict(d: Dictionary) -> void:
	records = {}
	_by_item = {}
	_by_actor = {}
	next_id = int(d.get("next_id", 0))
	for r in d.get("records", []):
		var o := {"id": int(r.id), "side": str(r.side), "actor": str(r.actor), "item": str(r.item), "qty": int(r.qty), "price_each": int(r.price_each),
			"location": str(r.location), "made_day": int(r.made_day), "made_minute": int(r.made_minute), "expiry": int(r.expiry),
			"visibility": str(r.visibility), "state": str(r.state), "filled": int(r.filled), "reservation": int(r.reservation), "source": str(r.source)}
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
