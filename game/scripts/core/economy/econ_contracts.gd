class_name EconContractLinks
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the contract side of the model (design s.3 Contract, s.6). DISABLED and isolated:
## World builds it only when game/data/economy.json "enabled" is true. It adds NO second contract record: CON-01's
## Contracts (contracts.gd) stays the one record, settles every delivery and payment and decides every ending (lapse,
## cancel, a party's death under OD-29's provisional rules). This class only links that record to the model:
##  - view(id): one read of a contract with what the model knows of it: the goods still owed (Contracts.left, which is what
##    Contracts.held_for_ref holds back for the seller, RECON-01), the buyer's escrow (`reserved`), whether it is overdue,
##    and the input reservations linked to it.
##  - earmark(id, item, qty): the seller sets aside an INPUT for an accepted contract (design s.6: "Explicitly reserve or
##    earmark material while retaining physical ownership and location"): an EconReservations claim with purpose
##    "contract:<id>" and expiry the contract's deadline_day (so it ends with the contract's own lapse, the dawn after).
##    Only the seller, only while the contract is accepted, only within EconReservations.available (which already nets out
##    the contract's own holds). Moves nothing.
##  - sweep(): once a dawn, for linked contracts only (an index, no scan of every contract), releases the linked claims of a
##    contract that is no longer open, whatever ended it. The ending is the contract module's; this follows it.
## Breach and renegotiation: the owner's answer to OD-LE-13 (APPROVED: context-sensitive, negotiated partial delivery,
## extension, changed payment or cancellation; no automatic penalty) is LE-02/LE-04's to build on CON-01's counters; LE-01
## adds no penalty field and no breach rule. Death of a party: OWNER DECISION OD-LE-13B (DEATH_OF_PARTY below); until then the
## contract module's existing on_death decides and the sweep merely follows the contract's state.
## Deterministic: ids sorted; saved as {contract id: [reservation ids]}.

## OWNER DECISION OD-LE-13B (death of a party: the contract ends, passes to the heir or household, or goes to the estate).
## Placeholder: LE-01 changes nothing; Contracts.on_death (OD-29 provisional) stays the rule.
const DEATH_OF_PARTY := "OWNER DECISION OD-LE-13B: undecided; Contracts.on_death (OD-29 provisional) applies"
const PURPOSE := "contract:"

var reservations: EconReservations
var links := {}                 # contract id (int) -> Array of reservation ids (ascending)


func _init(reservations_: EconReservations) -> void:
	reservations = reservations_


func _contracts() -> Contracts:
	return reservations.actors.w.contracts


## A read of contract `id` joined with the model; {} when there is no such contract.
func view(id: int) -> Dictionary:
	var c: Dictionary = _contracts().get_contract(id) if _contracts() != null else {}
	if c.is_empty():
		return {}
	var open := Contracts.is_open(c)
	var held := []
	for r in links.get(id, []):
		var rec := reservations.get_record(int(r))
		if not rec.is_empty():
			held.append(rec)
	return {"id": int(c.id), "buyer": str(c.buyer), "seller": str(c.seller), "item": str(c.item), "qty": int(c.qty), "price_each": int(c.price_each),
		"deadline_day": int(c.deadline_day), "state": str(c.state), "kind": str(c.get("kind", "goods")), "delivered": int(c.delivered), "paid": int(c.paid),
		"owed": Contracts.left(c) if open else 0, "escrow": int(c.get("reserved", 0)), "open": open,
		"overdue": open and reservations.actors.w.day() > int(c.deadline_day), "inputs": held}


## {ok, id, reason}: the seller of open contract `id` sets aside `qty` of input `item` for it.
func earmark(id: int, item: String, qty: int) -> Dictionary:
	var c: Dictionary = _contracts().get_contract(id) if _contracts() != null else {}
	if c.is_empty():
		return {"ok": false, "id": -1, "reason": "no contract"}
	if not Contracts.is_open(c):
		return {"ok": false, "id": -1, "reason": "contract not open"}
	if item == EconReservations.COINS:
		return {"ok": false, "id": -1, "reason": "coins are escrowed by the contract"}
	var r := reservations.reserve(str(c.seller), item, qty, PURPOSE + str(id), int(c.deadline_day))
	if r.ok:
		var l: Array = links.get(id, [])
		l.append(int(r.id))
		l.sort()
		links[id] = l
	return r


## Releases the claims linked to contracts that are no longer open; returns the contract ids unlinked, ascending.
func sweep() -> Array:
	var ids: Array = links.keys()
	ids.sort()
	var done := []
	for id in ids:
		var c: Dictionary = _contracts().get_contract(int(id)) if _contracts() != null else {}
		if c.is_empty() or not Contracts.is_open(c):
			for r in links[id]:
				reservations.release(int(r))       # false for one already expired or consumed: nothing to do
			links.erase(id)
			done.append(int(id))
		else:
			var keep := []
			for r in links[id]:
				if reservations.get_record(int(r)).get("state", "") == EconReservations.HELD:
					keep.append(int(r))
			if keep.is_empty():
				links.erase(id)
			else:
				links[id] = keep
	return done


func is_empty() -> bool:
	return links.is_empty()


func to_dict() -> Dictionary:
	var ids: Array = links.keys()
	ids.sort()
	var d := {}
	for id in ids:
		d[str(id)] = (links[id] as Array).duplicate()
	return {"links": d}


func load_dict(d: Dictionary) -> void:
	links = {}
	var l: Dictionary = d.get("links", {})
	for k in l:
		var arr: Array = (l[k] as Array).map(func(x): return int(x))
		arr.sort()
		links[int(k)] = arr
