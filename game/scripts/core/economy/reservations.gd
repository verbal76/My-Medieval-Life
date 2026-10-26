class_name EconReservations
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the reservation record (spec s.6: "Explicitly reserve or earmark material while
## retaining physical ownership and location"). DISABLED and isolated: World builds it only when game/data/economy.json
## "enabled" is true; nothing in live play calls it.
##
## Record {id, owner, item, qty, purpose, made_day, made_minute, expiry, state}: owner is an actor ref, item an item id or
## COINS ("coins"), expiry a day (-1: never) after which expire_due(day) marks it expired, state held | released |
## expired | consumed.
##
## Invariants:
##  - A reservation is a claim, never a transfer: this record NEVER moves a coin or a good and never changes who holds
##    what or where. consume() only marks the claim consumed; the physical transfer stays with World.trade / World.give.
##  - reserve() refuses more than the owner actually holds (read through EconActor from the existing owners) minus what open
##    contracts hold (Contracts.held_for) and what is already reserved for the same item; so two reservations can never cover the same stock, and an unknown, dead or
##    ended owner holds nothing to reserve.
##  - Goods can still leave the owner by a live trade; unbacked() REPORTS such claims, it never repairs them.
##  - Deterministic: ids count up from 0, every listing and the saved array are sorted by id; no RNG, no wall clock.
##  - Cost: reserve/reserved/available/release/consume touch only the owner's own held reservations (an index by owner);
##    expire_due scans held reservations only. No population scan anywhere.
##  - Bounded: finished (released/expired/consumed) records beyond `keep_finished` are dropped oldest first.
## Contract holds (RECON-01, owner approval 2026-10-23 item 4): finished goods a seller still owes on an open contract are
## already earmarked by Contracts.held_for, the live authority (NPCBrain.reserve and Credit.available read it). This record
## recognises them without owning them: available() = held - contract holds - own reservations, and reserve() refuses anything
## beyond that, so the same goods cannot be both held for a contract and reserved. Nothing here changes held_for or any
## contract. At the integration the owner approves, contract holds are re-expressed as reservations with purpose
## "contract:<id>" and held_for reads from them (one mechanism), with a test that contract behaviour is unchanged.
## Consumers when the owner approves integration: the scattered forms in LE00_BUILD18_REFRESH s.3 (first
## contracts::held_for and accepted-order inputs), via EconomyFoundation.
## Saved as the optional World key "economy" only when the feature is on and this record is non-empty.

const COINS := "coins"
const HELD := "held"
const RELEASED := "released"
const EXPIRED := "expired"
const CONSUMED := "consumed"

var actors: EconActor
var events: EconEvents = null             # optional: reserve/release/expire/consume are noted when present
var keep_finished := 200
var next_id := 0
var records := {}                         # id (int) -> record
var _by_owner := {}                       # owner ref -> Array of held ids (ascending)
var _held := {}                           # held id -> true


func _init(actors_: EconActor, cfg := {}) -> void:
	actors = actors_
	keep_finished = maxi(0, int(cfg.get("keep_finished", 200)))


## {ok, id, reason}. `expiry` is a day (-1: never).
func reserve(owner: String, item: String, qty: int, purpose: String, expiry := -1) -> Dictionary:
	if qty <= 0:
		return _no("quantity")
	if item == "":
		return _no("item")
	if not actors.exists(owner):
		return _no("unknown owner")
	if not actors.alive(owner):
		return _no("owner not alive")
	var day := actors.w.day()
	if expiry >= 0 and expiry < day:
		return _no("already expired")
	if available(owner, item) < qty:
		return _no("not held")
	var r := {"id": next_id, "owner": owner, "item": item, "qty": qty, "purpose": purpose, "made_day": day, "made_minute": int(fmod(actors.w.minutes, World.DAY)), "expiry": expiry, "state": HELD}
	next_id += 1
	records[r.id] = r
	_held[r.id] = true
	if not _by_owner.has(owner):
		_by_owner[owner] = []
	_by_owner[owner].append(r.id)
	_note("reserve", r)
	return {"ok": true, "id": r.id, "reason": ""}


## Units of `item` the owner's held reservations cover.
func reserved(owner: String, item: String) -> int:
	var n := 0
	for id in _by_owner.get(owner, []):
		if records[id].item == item:
			n += int(records[id].qty)
	return n


## Units of `item` the owner still owes on open contracts (Contracts.held_for, the authority; 0 for coins, whose set-aside
## is escrow moved out of the purse, not an earmark).
func contract_held(owner: String, item: String) -> int:
	if item == COINS or actors.w.contracts == null:
		return 0
	return actors.w.contracts.held_for_ref(owner, item)


## What the owner holds of `item` less what open contracts hold and what is reserved (never negative). 0 for an unknown or
## dead owner.
func available(owner: String, item: String) -> int:
	if not actors.alive(owner):
		return 0
	return maxi(0, actors.holding(owner, item) - contract_held(owner, item) - reserved(owner, item))


func release(id: int) -> bool:
	return _finish(id, RELEASED, "release")


func consume(id: int) -> bool:
	return _finish(id, CONSUMED, "consume")


## Marks every held reservation whose expiry day is before `day` expired; returns their ids, ascending.
func expire_due(day: int) -> Array:
	var due := []
	var ids: Array = _held.keys()
	ids.sort()
	for id in ids:
		var e := int(records[id].expiry)
		if e >= 0 and e < day:
			due.append(id)
	for id in due:
		_finish(id, EXPIRED, "expire")
	return due


func get_record(id: int) -> Dictionary:
	return records[id].duplicate() if records.has(id) else {}


## Held reservations of an owner, ascending by id (copies).
func held_of(owner: String) -> Array:
	var out := []
	for id in _by_owner.get(owner, []):
		out.append(records[id].duplicate())
	return out


## Held claims the owner no longer backs, sorted by (owner, item): [{owner, item, reserved, contract_held, held, short, alive}].
## Contract holds count against the stock first, so a reservation is unbacked when reserved + contract holds exceed what is
## held; `short` is the part of the reservation that lacks backing. A report only; nothing is released, shrunk or moved.
func unbacked() -> Array:
	var out := []
	var owners: Array = _by_owner.keys()
	owners.sort()
	for o in owners:
		var items := {}
		for id in _by_owner[o]:
			items[records[id].item] = true
		var names: Array = items.keys()
		names.sort()
		for it in names:
			var res := reserved(o, it)
			var have := actors.holding(o, it) if actors.alive(o) else 0
			var owed := contract_held(o, it) if actors.alive(o) else 0
			if res + owed > have:
				out.append({"owner": o, "item": it, "reserved": res, "contract_held": owed, "held": have, "short": mini(res, res + owed - have), "alive": actors.alive(o)})
	return out


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
	_by_owner = {}
	_held = {}
	next_id = int(d.get("next_id", 0))
	for r in d.get("records", []):
		var c := {"id": int(r.id), "owner": str(r.owner), "item": str(r.item), "qty": int(r.qty), "purpose": str(r.purpose), "made_day": int(r.made_day), "made_minute": int(r.made_minute), "expiry": int(r.expiry), "state": str(r.state)}
		records[c.id] = c
		if c.state == HELD:
			_index(c)


func _index(r: Dictionary) -> void:
	_held[r.id] = true
	if not _by_owner.has(r.owner):
		_by_owner[r.owner] = []
	_by_owner[r.owner].append(r.id)
	_by_owner[r.owner].sort()


func _finish(id: int, state: String, ev: String) -> bool:
	if not _held.has(id):
		return false
	var r: Dictionary = records[id]
	r.state = state
	_held.erase(id)
	var l: Array = _by_owner[r.owner]
	l.erase(id)
	if l.is_empty():
		_by_owner.erase(r.owner)
	_note(ev, r)
	_prune()
	return true


func _prune() -> void:
	var done: Array = []
	for id in records:
		if not _held.has(id):
			done.append(id)
	if done.size() <= keep_finished:
		return
	done.sort()
	for i in done.size() - keep_finished:
		records.erase(done[i])


func _note(type: String, r: Dictionary) -> void:
	if events != null:
		var w := actors.w
		var coins := int(r.qty) if r.item == COINS else 0
		events.record_at(w.day(), int(fmod(w.minutes, World.DAY)), type, r.owner, "", "" if r.item == COINS else r.item, 0 if r.item == COINS else int(r.qty), coins, "%s #%d" % [r.purpose, r.id])


func _no(reason: String) -> Dictionary:
	return {"ok": false, "id": -1, "reason": reason}
