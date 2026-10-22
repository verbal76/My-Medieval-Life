class_name Inventory
extends RefCounted
## Items owned by one actor, container or shop. Item counts never go negative; transfers are
## all-or-nothing (see World.trade and World.transfer).

var items := {}          # item id -> count
var durability := {}     # tool/weapon id -> remaining durability of the one in use
var max_stacks := 0      # 0 = unlimited distinct items
## INV-18 (Build 18): > 0 makes each pack category (GameData.category) a capacity pool of this many item-type
## positions (the player's pack: PlayerState.PACK_CAPS). One store underneath; the categories are only capacity
## rules. 0 (villagers, chests, carts, stalls) = no category rule.
var category_cap := 0
## Returns {item id: units worn} (PlayerState.worn_counts): a worn or wielded unit takes no position. Not saved.
var worn_fn := Callable()


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
	if max_stacks > 0 and not items.has(id) and items.size() >= max_stacks:
		return false
	return category_cap <= 0 or positions(id) > 0 or used(GameData.category(id)) < category_cap


## Whether every one of `ids` can be added together: two new kinds of one category need two free positions
## (can_add asks for one kind at a time). Goods one action yields together are taken together or not at all.
func can_add_all(ids) -> bool:
	return _short_of(ids) == ""


## The refusal when can_add_all says no, naming the category short of room.
func full_text_all(ids) -> String:
	var cat := _short_of(ids)
	if cat == "" or cat == "*":
		return "Your pack is full."
	var need := 0
	for id in _fresh(ids):
		if GameData.category(id) == cat:
			need += 1
	return "%s inventory full: %d of %d slots%s." % [GameData.category_name(cat), used(cat), category_cap,
		(", and this needs %d" % need) if need > 1 else ""]


## The kinds among `ids` (once each) that would take a new position.
func _fresh(ids) -> Array:
	var out := []
	for v in ids:
		var id := str(v)
		if not out.has(id) and (positions(id) == 0 if category_cap > 0 else not items.has(id)):
			out.append(id)
	return out


## "" when `ids` all fit; "*" when the kind limit (max_stacks) is short; else the first category short of room.
func _short_of(ids) -> String:
	var fresh := _fresh(ids)
	if max_stacks > 0 and items.size() + fresh.filter(func(id): return not items.has(id)).size() > max_stacks:
		return "*"
	if category_cap <= 0:
		return ""
	var need := {}
	for id in fresh:
		var cat := GameData.category(id)
		need[cat] = int(need.get(cat, 0)) + 1
	for cat in GameData.CATEGORIES:
		if need.has(cat) and used(cat) + int(need[cat]) > category_cap:
			return cat
	return ""


## How many units of `id` are worn (equipped), never more than are held.
func worn(id: String) -> int:
	if not worn_fn.is_valid():
		return 0
	return mini(count(id), int(worn_fn.call().get(id, 0)))


## INV-18: the backpack positions `id` takes: 1 while an unworn unit is held, else 0 (a stack is one position;
## an equipped item takes none, a second, unworn unit of it does).
func positions(id: String) -> int:
	return 1 if count(id) - worn(id) > 0 else 0


## The positions used in category `cat`.
func used(cat: String) -> int:
	var w: Dictionary = worn_fn.call() if worn_fn.is_valid() else {}
	var n := 0
	for id in items:
		if count(id) - mini(count(id), int(w.get(id, 0))) > 0 and GameData.category(id) == cat:
			n += 1
	return n


## The item ids whose backpack position is in `cat` (sorted): what that tab shows.
func in_category(cat: String) -> Array:
	return ids().filter(func(id): return positions(id) > 0 and GameData.category(id) == cat)


## The refusal for adding `id` when can_add says no, naming the category ("Tools inventory full: 18 of 18
## slots."); a pack with no category rule is just full.
func full_text(id: String) -> String:
	if max_stacks > 0 and not items.has(id) and items.size() >= max_stacks:
		return "Your pack is full."
	if category_cap > 0:
		var cat := GameData.category(id)
		return "%s inventory full: %d of %d slots." % [GameData.category_name(cat), used(cat), category_cap]
	return "Your pack is full."


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
