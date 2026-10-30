class_name EconTransactions
extends RefCounted
## Expansion 20 LE-03: THE transaction authority for every party the economy model resolves (village actors and settlement
## parties): one validate-then-commit path with single-use transaction ids, immediate exchanges and shipments (transit custody,
## escrow, delivery, failure with refund, loss). Interface contract: docs/expansion20/TRANSACTION_AUTHORITY.md (owner directive
## 2026-10-30: LE-03 and the settlement food trade converge on one mechanism). Built by World whether or not the Living Economy is
## on (the settlement food trade is shipped play); claims (EconClaims) are enforced only while it is on. With no caller it changes
## nothing and writes no save key.
##
## It keeps no second ledger of holdings: coins and goods stay in the existing holders (NPC, PlayerState, SettlementParty's own
## books); between the two phases of a shipment they are in the shipment record (custody and escrow), reported by in_transit().
## Village sides cross the village's boundary as the caravan does (World.coin_sources, imported_/exported_ item stats);
## settlement sides are booked by SettlementParty (deal for a regional exchange; outside lines for a shipment).
## Deterministic: no RNG, no wall clock, sorted iteration; saved under the optional World key "transactions".

const KEY := "transactions"
const VILLAGE := ["npc", "player", "manor", "hh", "chapel", "stall", "shop", "front", "counter"]     # LE-04: every village holder
const PEOPLE := ["npc", "player"]          # parties World.trade serves (claims apply to them)
const TILLS := ["stall", "shop", "front", "counter"]
const OPEN := "open"
const FINAL := {"deliver": "delivered", "fail": "returned", "lose": "lost"}

## The other end of a settlement party's side when it deals with a village actor (SettlementParty.deal reads other.id).
class Outside extends RefCounted:
	var id := ""
	func _init(ref: String) -> void:
		id = ref

var w: World
var actors: EconActor
var keep_outcomes := 64
var keep_finished := 200
var keep_journal := 500
var marks := {}                 # namespace -> highest seq seen
var outcomes := {}              # namespace -> Array of [seq, result] (oldest first, bounded)
var shipments := {}             # txid -> record
var sunk := {}                  # item -> units destroyed in transit (lose)
var journal: Array = []


func _init(world: World) -> void:
	w = world
	actors = EconActor.new(world)


# ------------------------------------------------------------------------------------------------ ids
static func parse_id(txid: String) -> Array:
	var at := txid.rfind(":")
	if at <= 0 or at == txid.length() - 1:
		return []
	var ns := txid.substr(0, at)
	var sq := txid.substr(at + 1)
	if not sq.is_valid_int() or int(sq) <= 0:
		return []
	for ch in ns:
		if not (ch.is_valid_identifier() or ch.is_valid_int() or ch in ["_", "-", ".", "/"]):
			return []
	return [ns, int(sq)]


## {} when `txid` is a new attempt (its seq then marked seen); else the result to return (bad id, or a replay).
func _begin(txid: String) -> Dictionary:
	var p := parse_id(txid)
	if p.is_empty():
		return _res(false, "bad_id", txid)
	var ns: String = p[0]
	var sq: int = p[1]
	if sq <= int(marks.get(ns, 0)):
		for e in outcomes.get(ns, []):
			if int(e[0]) == sq:
				var r: Dictionary = (e[1] as Dictionary).duplicate()
				r.replay = true
				return r
		var s := _res(false, "stale_id", txid)
		s.replay = true
		return s
	marks[ns] = sq
	return {}


## A fresh id in `namespace` for a caller with no sequence of its own (the next above the namespace's mark).
func next_txid(ns: String) -> String:
	return "%s:%d" % [ns, int(marks.get(ns, 0)) + 1]


func _end(txid: String, r: Dictionary) -> Dictionary:
	var p := parse_id(txid)
	var l: Array = outcomes.get(p[0], [])
	l.append([p[1], r.duplicate()])
	while l.size() > keep_outcomes:
		l.pop_front()
	outcomes[p[0]] = l
	return r


static func _res(ok: bool, code: String, txid: String, state := "") -> Dictionary:
	return {"ok": ok, "code": code, "txid": txid, "replay": false, "state": state}


# ------------------------------------------------------------------------------------------------ parties
## {code, kind, obj}: code "" when usable.
func _party(ref: String) -> Dictionary:
	if not actors.exists(ref):
		return {"code": "unknown_party"}
	var k := actors.kind(ref)
	if not (k in VILLAGE or k == "region"):
		return {"code": "unsupported_party"}
	if k != "manor" and k not in TILLS and not actors.alive(ref):
		return {"code": "party_unavailable"}
	var obj = null
	match k:
		"npc":
			obj = w.npc(World.ref_id(ref))
		"player":
			obj = w.player_of_ref(ref)
		"region":
			obj = w.regions.party(ref)
		"manor":
			obj = w.granary
		"hh":
			obj = w.households[World.ref_id(ref)].pantry      # its goods; coins: its head's own purse (purses are not pooled)
		"chapel":
			obj = w.chapel.store if w.chapel != null else null
		_:
			obj = _till(ref)                                  # a till: coins only
	if obj == null:
		return {"code": "party_unavailable"}
	return {"code": "", "kind": k, "obj": obj, "ref": ref}


## The record holding a till's coins ("till" key), or null.
func _till(ref: String):
	match actors.kind(ref):
		"stall":
			var k := ref.trim_prefix("stall:")
			var st = w.stalls.get(k, w.stalls.get(int(k) if k.is_valid_int() else -1, null))
			return st
		"shop":
			var b: Dictionary = w.buildings.get(ref.trim_prefix("shop:"), {})
			return b.shop if b.has("shop") else null
		"front", "counter":
			var b: Dictionary = w.buildings.get(ref.get_slice(":", 1), {})
			return b.get(actors.kind(ref), null)
	return null


## A household's head, who pays and is paid for it (the keep_till and stall payee rule); null when nobody is left.
func _head(p: Dictionary) -> NPC:
	return w.party(str(p.ref))


## The goods store of a party (an Inventory or a SettlementParty); null for a till.
static func _store(p: Dictionary):
	if p.kind in TILLS:
		return null
	if p.kind in PEOPLE:
		return p.obj.inv
	return p.obj


func _held(p: Dictionary, item: String) -> int:
	if p.kind == "region":
		return int(p.obj.held(item))
	var st = _store(p)
	return int(st.count(item)) if st != null else 0


func _purse(p: Dictionary) -> int:
	match str(p.kind):
		"region":
			return int(p.obj.purse())
		"npc", "player":
			return int(p.obj.coins)
		"manor":
			return w.treasury
		"chapel":
			return w.chapel.coins
		"hh":
			var h := _head(p)
			return h.coins if h != null else 0
	return int(p.obj.get("till", 0))                          # a till


func _room(p: Dictionary, item: String) -> bool:
	if p.kind == "region":
		return bool(p.obj.can_hold(item))
	var st = _store(p)
	return st != null and bool(st.can_add(item))


## Coins into (k > 0) or out of (k < 0) a village party's own holder. No boundary crossing here.
func _add_coins(p: Dictionary, k: int, books := true) -> void:
	match str(p.kind):
		"npc", "player":
			p.obj.coins += k
			if p.obj is NPC and books:
				if k > 0:
					p.obj.earned += k
				else:
					p.obj.spent -= k
		"manor":
			w.treasury += k
		"chapel":
			w.chapel.coins += k
		"hh":
			_head(p).coins += k
		_:
			p.obj.till = int(p.obj.get("till", 0)) + k


## The shared checks of exchange and ship. "" when both sides can be met.
func _check(b: Dictionary, s: Dictionary, item: String, qty: int, total: int, room := true) -> String:
	if b.code != "":
		return str(b.code)
	if s.code != "":
		return str(s.code)
	if _held(s, item) < qty:
		return "no_stock"
	if _purse(b) < total:
		return "no_funds"
	if room and not _room(b, item):
		return "no_room"
	if b.kind == "hh" and total > 0 and _head(b) == null:
		return "party_unavailable"
	if s.kind in PEOPLE and not w.claims_allow(s.obj, item, qty):
		return "claimed"
	var payer = b.obj if b.kind in PEOPLE else (_head(b) if b.kind == "hh" else null)
	if payer != null and not w.claims_allow(payer, EconReservations.COINS, total, item, World.is_necessity(item)):
		return "claimed"
	return ""


func _valid(buyer: String, seller: String, item: String, qty: int, total: int) -> String:
	if qty <= 0 or total < 0 or item == "" or item == EconReservations.COINS:
		return "invalid_quantity"
	if buyer == seller:
		return "same_party"
	return ""


# ------------------------------------------------------------------------------------------------ moves (validated first)
func _goods_out(p: Dictionary, item: String, qty: int) -> void:      # into transit (out of the village for a village party)
	if p.kind == "region":
		p.obj.remove(item, qty)
	else:
		_store(p).remove(item, qty)
		w.stat("exported_" + item, float(qty))


func _goods_in(p: Dictionary, item: String, qty: int) -> void:       # out of transit
	if p.kind == "region":
		p.obj.add(item, qty)
	else:
		_store(p).add(item, qty)
		w.stat("imported_" + item, float(qty))


func _coins_out(p: Dictionary, k: int) -> void:
	if k <= 0:
		return
	if p.kind == "region":
		p.obj.outside_coins(-k)
	else:
		_add_coins(p, -k)
		w.coin_sources -= k


func _coins_in(p: Dictionary, k: int) -> void:
	if k <= 0:
		return
	if p.kind == "region":
		p.obj.outside_coins(k)
	else:
		_add_coins(p, k)
		w.coin_sources += k


func _note(txid: String, op: String, r: Dictionary, state: String) -> void:
	journal.append({"txid": txid, "op": op, "buyer": str(r.buyer), "seller": str(r.seller), "item": str(r.item), "qty": int(r.qty),
		"total": int(r.total), "day": w.day(), "minute": int(fmod(w.minutes, World.DAY)), "state": state})
	while journal.size() > keep_journal:
		journal.pop_front()


# ------------------------------------------------------------------------------------------------ calls
## Immediate exchange (section 3 of the contract): goods seller -> buyer and coins buyer -> seller together, or nothing.
func exchange(txid: String, buyer: String, seller: String, item: String, qty: int, total: int) -> Dictionary:
	var rep := _begin(txid)
	if not rep.is_empty():
		return rep
	var bad := _valid(buyer, seller, item, qty, total)
	if bad != "":
		return _end(txid, _res(false, bad, txid))
	var b := _party(buyer)
	var s := _party(seller)
	bad = _check(b, s, item, qty, total)
	if bad != "":
		return _end(txid, _res(false, bad, txid))
	if b.kind in PEOPLE and s.kind in PEOPLE:
		# the one village path: World.trade (its own claims, hooks, recorder); unit price for the record, the total paid
		if not w.trade(b.obj, s.obj, item, qty, total / qty, total):
			return _end(txid, _res(false, "claimed", txid))
	elif b.kind in VILLAGE and s.kind in VILLAGE:
		# LE-04: the manor, a household, the chapel or a till with another village party: inside the village, no boundary
		if s.kind in PEOPLE:
			w.claims_release(s.obj, item, qty)
		var payer = b.obj if b.kind in PEOPLE else (_head(b) if b.kind == "hh" else null)
		if payer != null:
			w.claims_release(payer, EconReservations.COINS, total, item, World.is_necessity(item))
		_store(s).remove(item, qty)
		_store(b).add(item, qty)
		_add_coins(b, -total)
		_add_coins(s, total)
	elif b.kind == "region" and s.kind == "region":
		if not (s.obj.can_deal("sell", item, qty, total) and b.obj.can_deal("buy", item, qty, total)):
			return _end(txid, _res(false, "no_funds", txid))
		s.obj.deal("sell", b.obj, item, qty, total, w.day())
		b.obj.deal("buy", s.obj, item, qty, total, w.day())
	else:
		var v: Dictionary = b if b.kind in VILLAGE else s
		var rp: Dictionary = s if v == b else b
		if v == b:
			var payer = b.obj if b.kind in PEOPLE else (_head(b) if b.kind == "hh" else null)
			if payer != null:
				w.claims_release(payer, EconReservations.COINS, total, item, World.is_necessity(item))
			rp.obj.deal("sell", Outside.new(buyer), item, qty, total, w.day())
			_store(b).add(item, qty)
			_coins_out(b, total)
			w.stat("imported_" + item, float(qty))
		else:
			if s.kind in PEOPLE:
				w.claims_release(s.obj, item, qty)
			rp.obj.deal("buy", Outside.new(seller), item, qty, total, w.day())
			_store(s).remove(item, qty)
			_coins_in(s, total)
			w.stat("exported_" + item, float(qty))
	_note(txid, "exchange", {"buyer": buyer, "seller": seller, "item": item, "qty": qty, "total": total}, "done")
	return _end(txid, _res(true, "ok", txid, "done"))


## LE-04 (OD-LE-07 D06: "Owners can make explicit recorded contributions, legitimate profit distributions or estate transfers;
## no silent pooling"): `amount` coins from one village party to another for `purpose` (contribution, distribution, necessity,
## estate, wage...), validated then committed, single-use id, journalled. Coins only; inside the village (no boundary crossed).
func transfer_coins(txid: String, from: String, to: String, amount: int, purpose: String) -> Dictionary:
	var rep := _begin(txid)
	if not rep.is_empty():
		return rep
	if amount <= 0:
		return _end(txid, _res(false, "invalid_quantity", txid))
	if from == to:
		return _end(txid, _res(false, "same_party", txid))
	var a := _party(from)
	var b := _party(to)
	if a.code != "" or b.code != "":
		return _end(txid, _res(false, str(a.code if a.code != "" else b.code), txid))
	if not (a.kind in VILLAGE and b.kind in VILLAGE):
		return _end(txid, _res(false, "unsupported_party", txid))
	if _purse(a) < amount:
		return _end(txid, _res(false, "no_funds", txid))
	if (a.kind == "hh" and _head(a) == null) or (b.kind == "hh" and _head(b) == null):
		return _end(txid, _res(false, "party_unavailable", txid))
	var payer = a.obj if a.kind in PEOPLE else (_head(a) if a.kind == "hh" else null)
	if payer != null and not w.claims_allow(payer, EconReservations.COINS, amount):
		return _end(txid, _res(false, "claimed", txid))
	if payer != null:
		w.claims_release(payer, EconReservations.COINS, amount)
	_add_coins(a, -amount, false)            # a move between an owner and its business: neither earned nor spent
	_add_coins(b, amount, false)
	_note(txid, "coins:" + purpose, {"buyer": to, "seller": from, "item": "", "qty": 0, "total": amount}, "done")
	return _end(txid, _res(true, "ok", txid, "done"))


## LE-04 (OD-LE-13B D12: "Death of a contract party can create estate claims up to real estate assets; heirs bear no automatic
## liability from separate personal funds"): `claim` coins owed by a villager who has just died to village party `to`, paid from
## the dead's own estate (its coins, before they pass on) and never more than it holds; the rest is written off. Single-use id,
## journalled ("estate"). Returns the result with the amount paid in `paid`.
func estate_claim(txid: String, dead: NPC, to: String, claim: int, why: String) -> Dictionary:
	var rep := _begin(txid)
	if not rep.is_empty():
		return rep
	var b := _party(to)
	if dead == null or claim <= 0 or b.code != "" or not (b.kind in VILLAGE):
		return _end(txid, _res(false, "invalid_quantity" if claim <= 0 else (str(b.code) if b.code != "" else "unknown_party"), txid))
	var pay := mini(claim, maxi(0, dead.coins))
	dead.coins -= pay
	_add_coins(b, pay, false)
	_note(txid, "estate:" + why, {"buyer": to, "seller": World.npc_ref(dead.id), "item": "", "qty": 0, "total": pay}, "done")
	var r := _res(true, "ok", txid, "done")
	r["paid"] = pay
	r["written_off"] = claim - pay
	return _end(txid, r)


## Shipment phase 1: the seller's goods into transit custody, the buyer's coins into escrow, together or nothing.
func ship(txid: String, buyer: String, seller: String, item: String, qty: int, total: int, due_day: int) -> Dictionary:
	var rep := _begin(txid)
	if not rep.is_empty():
		return rep
	var bad := _valid(buyer, seller, item, qty, total)
	if bad != "":
		return _end(txid, _res(false, bad, txid))
	var b := _party(buyer)
	var s := _party(seller)
	bad = _check(b, s, item, qty, total, false)      # room is checked on arrival (deliver), not now
	if bad != "":
		return _end(txid, _res(false, bad, txid))
	if s.kind in PEOPLE:
		w.claims_release(s.obj, item, qty)
	var payer = b.obj if b.kind in PEOPLE else (_head(b) if b.kind == "hh" else null)
	if payer != null:
		w.claims_release(payer, EconReservations.COINS, total, item, World.is_necessity(item))
	_goods_out(s, item, qty)
	_coins_out(b, total)
	var r := {"txid": txid, "buyer": buyer, "seller": seller, "item": item, "qty": qty, "total": total, "due_day": due_day,
		"made_day": w.day(), "state": OPEN, "closed_day": -1, "why": ""}
	shipments[txid] = r
	_note(txid, "ship", r, OPEN)
	return _end(txid, _res(true, "ok", txid, OPEN))


func deliver(txid: String) -> Dictionary:
	return _close(txid, "deliver", "")


func fail(txid: String, why: String) -> Dictionary:
	return _close(txid, "fail", why)


func lose(txid: String, why: String) -> Dictionary:
	return _close(txid, "lose", why)


## Phase 2: exactly one of deliver, fail (return and refund), lose (seller bears it; refund). Validated, then committed.
func _close(txid: String, op: String, why: String) -> Dictionary:
	if not shipments.has(txid):
		return _res(false, "not_found", txid)
	var r: Dictionary = shipments[txid]
	if r.state != OPEN:
		var same: bool = str(r.state) == str(FINAL[op])
		var d := _res(same, "duplicate" if same else "not_open", txid, str(r.state))
		d.replay = same
		return d
	var b := _party(str(r.buyer))
	var s := _party(str(r.seller))
	var item := str(r.item)
	var qty := int(r.qty)
	var total := int(r.total)
	match op:
		"deliver":
			if b.code != "" or s.code != "":
				return _res(false, str(b.code if b.code != "" else s.code), txid, OPEN)
			if not _room(b, item):
				return _res(false, "no_room", txid, OPEN)
			_goods_in(b, item, qty)
			_coins_in(s, total)
		"fail":
			if b.code != "" or s.code != "":
				return _res(false, str(b.code if b.code != "" else s.code), txid, OPEN)
			if not _room(s, item):
				return _res(false, "no_room", txid, OPEN)
			_goods_in(s, item, qty)
			_coins_in(b, total)
		"lose":
			if b.code != "":
				return _res(false, str(b.code), txid, OPEN)
			sunk[item] = int(sunk.get(item, 0)) + qty
			w.stat("lost_in_transit_" + item, float(qty))
			_coins_in(b, total)
	r.state = FINAL[op]
	r.closed_day = w.day()
	r.why = why
	_note(txid, op, r, str(r.state))
	_prune()
	return _res(true, "ok", txid, str(r.state))


func _prune() -> void:
	var done := []
	for id in shipments:
		if shipments[id].state != OPEN:
			done.append(id)
	if done.size() <= keep_finished:
		return
	done.sort_custom(func(a, b): return [int(shipments[a].closed_day), a] < [int(shipments[b].closed_day), b])
	for i in done.size() - keep_finished:
		shipments.erase(done[i])


# ------------------------------------------------------------------------------------------------ reads
func get_shipment(txid: String) -> Dictionary:
	return shipments[txid].duplicate() if shipments.has(txid) else {}


func open_shipments() -> Array:
	var ids: Array = shipments.keys()
	ids.sort()
	var out := []
	for id in ids:
		if shipments[id].state == OPEN:
			out.append(shipments[id].duplicate())
	return out


func overdue(day: int) -> Array:
	return open_shipments().filter(func(r): return int(r.due_day) < day)


## Coins in escrow and goods in custody of open shipments; the village parts (a village buyer's escrow, a village seller's
## goods) separately. The village's own ledgers already count them as outside (they crossed its boundary into transit).
func in_transit() -> Dictionary:
	var out := {"coins": 0, "goods": {}, "village_coins": 0, "village_goods": {}}
	for r in open_shipments():
		out.coins += int(r.total)
		out.goods[r.item] = int(out.goods.get(r.item, 0)) + int(r.qty)
		if actors.kind(str(r.buyer)) in VILLAGE:
			out.village_coins += int(r.total)
		if actors.kind(str(r.seller)) in VILLAGE:
			out.village_goods[r.item] = int(out.village_goods.get(r.item, 0)) + int(r.qty)
	return out


# ------------------------------------------------------------------------------------------------ save
func is_empty() -> bool:
	return marks.is_empty() and shipments.is_empty() and journal.is_empty() and sunk.is_empty()


func to_dict() -> Dictionary:
	var ids: Array = shipments.keys()
	ids.sort()
	var sh := []
	for id in ids:
		sh.append(shipments[id].duplicate())
	var ns: Array = marks.keys()
	ns.sort()
	var m := {}
	var o := {}
	for k in ns:
		m[k] = int(marks[k])
		o[k] = (outcomes.get(k, []) as Array).duplicate(true)
	var it: Array = sunk.keys()
	it.sort()
	var sk := {}
	for k in it:
		sk[k] = int(sunk[k])
	return {"marks": m, "outcomes": o, "shipments": sh, "sunk": sk, "journal": journal.duplicate(true)}


func load_dict(d: Dictionary) -> void:
	marks = {}
	outcomes = {}
	shipments = {}
	sunk = {}
	journal = []
	for k in d.get("marks", {}):
		marks[str(k)] = int(d.marks[k])
	for k in d.get("outcomes", {}):
		var l := []
		for e in d.outcomes[k]:
			var r: Dictionary = e[1]
			l.append([int(e[0]), {"ok": bool(r.ok), "code": str(r.code), "txid": str(r.txid), "replay": bool(r.get("replay", false)), "state": str(r.get("state", ""))}])
		outcomes[str(k)] = l
	for r in d.get("shipments", []):
		shipments[str(r.txid)] = {"txid": str(r.txid), "buyer": str(r.buyer), "seller": str(r.seller), "item": str(r.item), "qty": int(r.qty),
			"total": int(r.total), "due_day": int(r.due_day), "made_day": int(r.made_day), "state": str(r.state), "closed_day": int(r.closed_day), "why": str(r.why)}
	for k in d.get("sunk", {}):
		sunk[str(k)] = int(d.sunk[k])
	for j in d.get("journal", []):
		journal.append({"txid": str(j.txid), "op": str(j.op), "buyer": str(j.buyer), "seller": str(j.seller), "item": str(j.item), "qty": int(j.qty),
			"total": int(j.total), "day": int(j.day), "minute": int(j.minute), "state": str(j.state)})
