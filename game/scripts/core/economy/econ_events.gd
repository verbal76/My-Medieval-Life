class_name EconEvents
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the economic event record (spec s.3 Event, s.14, s.16). A typed, strictly ordered,
## bounded ring of what happened to goods and coins. DIAGNOSTICS ONLY: nothing reads it to decide anything, and nothing
## in live play writes to it. World builds it only when game/data/economy.json "enabled" is true.
##
## Event {seq, day, minute, type, actor, other, item, qty, coins, note}: actor/other are refs ("" for none).
## Ordering: strictly by (day, minute, seq); seq is a counter that only grows, so ties break by arrival. An event stamped
## earlier than the last one is refused (record_at returns -1) rather than reordered, so the ring is always sorted.
## Bound: at most `capacity` events (economy.json events.capacity); the oldest fall off. Optional save
## (events.save): the ring and the counter, so seq stays unique and monotonic across a load.
## Consumers: economy_sim.gd diagnostics (later), EconReservations (reserve/release/expire/consume events), and the facts
## Expansion 19 may subscribe to. Never a second ledger: it records, the existing ledgers (World.total_coins, holdings)
## remain the truth.

const TYPES := ["trade", "gift", "wage", "tax", "production", "consumption", "spoilage", "theft", "death", "debt", "reserve", "release", "expire", "consume", "note"]

var capacity := 500
var save_it := true
var next_seq := 0
var ring: Array = []            # of Dictionary, sorted by (day, minute, seq)


func _init(cfg := {}) -> void:
	capacity = maxi(1, int(cfg.get("capacity", 500)))
	save_it = bool(cfg.get("save", true))


func record_at(day: int, minute: int, type: String, actor := "", other := "", item := "", qty := 0, coins := 0, note := "") -> int:
	if not type in TYPES:
		return -1
	if not ring.is_empty():
		var last: Dictionary = ring[ring.size() - 1]
		if _key(day, minute, 0) < _key(int(last.day), int(last.minute), 0):
			return -1
	var e := {"seq": next_seq, "day": day, "minute": minute, "type": type, "actor": actor, "other": other, "item": item, "qty": qty, "coins": coins, "note": note}
	next_seq += 1
	ring.append(e)
	if ring.size() > capacity:
		ring = ring.slice(ring.size() - capacity)
	return int(e.seq)


## The newest events first-to-last in order; optional filters.
func query(actor := "", type := "") -> Array:
	var out := []
	for e in ring:
		if (actor == "" or e.actor == actor or e.other == actor) and (type == "" or e.type == type):
			out.append(e.duplicate())
	return out


func size() -> int:
	return ring.size()


func is_empty() -> bool:
	return ring.is_empty()


## True when the ring is in strict (day, minute, seq) order and within its bound.
func ordered() -> bool:
	if ring.size() > capacity:
		return false
	for i in range(1, ring.size()):
		var a: Dictionary = ring[i - 1]
		var b: Dictionary = ring[i]
		if _key(int(a.day), int(a.minute), int(a.seq)) >= _key(int(b.day), int(b.minute), int(b.seq)):
			return false
	return true


static func _key(day: int, minute: int, seq: int) -> int:
	return (day * 100000 + minute) * 1000000000 + seq


func to_dict() -> Dictionary:
	return {"next_seq": next_seq, "ring": ring.duplicate(true)} if save_it else {}


func load_dict(d: Dictionary) -> void:
	next_seq = int(d.get("next_seq", 0))
	ring = []
	for e in d.get("ring", []):
		ring.append({"seq": int(e.seq), "day": int(e.day), "minute": int(e.minute), "type": str(e.type), "actor": str(e.actor), "other": str(e.other), "item": str(e.item), "qty": int(e.qty), "coins": int(e.coins), "note": str(e.note)})
	if ring.size() > capacity:
		ring = ring.slice(ring.size() - capacity)
