class_name Inventory
extends RefCounted
## Items owned by one actor, container or shop. Item counts never go negative; transfers are
## all-or-nothing (see World.trade and World.transfer).

var items := {}          # item id -> count
var durability := {}     # tool/weapon id -> remaining durability of the one in use
var max_stacks := 0      # 0 = unlimited distinct items


func count(id: String) -> int:
	return int(items.get(id, 0))


func has(id: String, n := 1) -> bool:
	return count(id) >= n


func has_all(need: Dictionary) -> bool:
	for id in need:
		if count(id) < int(need[id]):
			return false
	return true


func can_add(id: String) -> bool:
	return max_stacks == 0 or items.has(id) or items.size() < max_stacks


func add(id: String, n := 1) -> bool:
	if n <= 0:
		return n == 0
	if not can_add(id):
		return false
	items[id] = count(id) + n
	return true


func remove(id: String, n := 1) -> bool:
	if count(id) < n or n < 0:
		return false
	items[id] = count(id) - n
	if items[id] == 0:
		items.erase(id)
		durability.erase(id)
	return true


func remove_all(need: Dictionary) -> bool:
	if not has_all(need):
		return false
	for id in need:
		remove(id, int(need[id]))
	return true


func total() -> int:
	var n := 0
	for id in items:
		n += items[id]
	return n


func ids() -> Array:
	var a := items.keys()
	a.sort()
	return a


## Wear the tool or weapon `id` by `amount`; when it breaks one is removed. Returns true if one broke.
func wear(id: String, amount: int) -> bool:
	if not has(id):
		return false
	var full := int(GameData.item(id).get("durability", 0))
	if full <= 0:
		return false
	var left := int(durability.get(id, full)) - amount
	if left <= 0:
		remove(id)
		if has(id):
			durability[id] = full
		return true
	durability[id] = left
	return false


func to_dict() -> Dictionary:
	return {"items": items.duplicate(), "durability": durability.duplicate(), "max_stacks": max_stacks}


static func from_dict(d: Dictionary) -> Inventory:
	var inv := Inventory.new()
	for k in d.get("items", {}):
		inv.items[k] = int(d.items[k])
	for k in d.get("durability", {}):
		inv.durability[k] = int(d.durability[k])
	inv.max_stacks = int(d.get("max_stacks", 0))
	return inv
