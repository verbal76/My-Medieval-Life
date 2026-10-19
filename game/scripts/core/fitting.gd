class_name Fitting
extends RefCounted
## Equipment the player places in their own rooms (PL1-10 stage 3; docs/BUILD_DECISIONS.md "Player businesses,
## stages 3 and 4"). A room the player built (a house, a workshop, a storeroom, living quarters) can be fitted
## with a shop counter, shelves, stock chests and the existing station types (oven, stove, workbench, forge,
## anvil). Pieces are kept in the building's own `fit` list [{kind, at: [x, y], use: [x, y]}] (saved with the
## building); the cell is solid, drawn in the map's "below1" layer with tiles the stamps already use, and a
## station piece is a World.stations entry like a workshop's, so the crafting window, the recipes, the
## villagers' permission rules and the prompts are the existing ones. Nothing is placed where it would shut a
## door, a bed or any cell off from the door: every cell reachable before must stay reachable. The materials
## come from the pack (counted as used in the building, as a building's are) and come back when a piece is
## taken up. What a shop is follows the equipment (trade()): a forge and an anvil make it a smithy, an oven a
## bakery. Rules only; the window is scripts/ui/fit_window.gd and the placing bar is main.gd's.

const KINDS := ["counter", "shelves", "stock_chest", "oven", "stove", "workbench", "forge", "anvil"]
const STATIONS := ["oven", "stove", "workbench", "forge", "anvil"]
const NAMES := {"counter": "shop counter", "shelves": "shelves", "stock_chest": "stock chest", "oven": "oven", "stove": "stove",
	"workbench": "workbench", "forge": "forge", "anvil": "anvil"}
const PURPOSE := {"counter": "where the shop sells from and where the attendant stands",
	"shelves": "more kinds of goods on sale", "stock_chest": "a back room for spare stock that refills the shelves",
	"oven": "roasting and baking", "stove": "cooking, brewing and tonics", "workbench": "carpentry",
	"forge": "smelting", "anvil": "smithing"}
const LAYER := "below1"
## The tiles the stamps already draw each piece with (the workshops' own stations, the family chest, the tavern counter).
const ART := {"counter": 3578, "shelves": 2542, "stock_chest": 355, "oven": 2567, "stove": 3001, "workbench": 5180, "forge": 2567, "anvil": 2540}
const SIDES := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]

var w: World


func _init(world: World) -> void:
	w = world


# ---------------------------------------------------------------- what is there ----------------
static func cost(kind: String) -> Dictionary:
	return (GameData.b("shop_equipment") as Dictionary).get(kind, {})


static func cost_text(kind: String) -> String:
	var parts := []
	var c := cost(kind)
	for id in c:
		parts.append("%d %s" % [int(c[id]), GameData.item_name(id).to_lower()])
	return ", ".join(parts)


## How many of a kind a room may have: one each, but several shelves and stock chests.
static func limit(kind: String) -> int:
	return int(GameData.b("shop_max_shelves")) if kind == "shelves" else (int(GameData.b("shop_max_chests")) if kind == "stock_chest" else 1)


func list(b: Dictionary) -> Array:
	return b.get("fit", [])


func count(b: Dictionary, kind: String) -> int:
	var n := 0
	for e in list(b):
		if str(e.kind) == kind:
			n += 1
	return n


func entry(b: Dictionary, kind: String) -> Dictionary:
	for e in list(b):
		if str(e.kind) == kind:
			return e
	return {}


func cell_of(e: Dictionary, key := "at") -> Vector2i:
	return Vector2i(int(e[key][0]), int(e[key][1]))


## The station kinds a room has: its stamp's own (a smithy's forge and anvil) and the ones placed in it.
func station_kinds(b: Dictionary) -> Array:
	var out := []
	for s in w.stamp_of(b).get("stations", []):
		if not out.has(str(s.type)):
			out.append(str(s.type))
	for e in list(b):
		if STATIONS.has(str(e.kind)) and not out.has(str(e.kind)):
			out.append(str(e.kind))
	return out


func has_kind(b: Dictionary, kind: String) -> bool:
	return station_kinds(b).has(kind) or count(b, kind) > 0


# ---------------------------------------------------------------- what a shop is ----------------
## What the equipment makes the place: forge and anvil a smithy, an oven a bakery, a workbench a carpenter's
## shop, a stove a kitchen, otherwise a general store.
func trade(b: Dictionary) -> String:
	var k := station_kinds(b)
	if k.has("forge") and k.has("anvil"):
		return "smithy"
	if k.has("oven"):
		return "bakery"
	if k.has("workbench"):
		return "carpenter's shop"
	if k.has("stove"):
		return "kitchen"
	return "general store"


func recipe_count(b: Dictionary) -> int:
	var n := 0
	for k in station_kinds(b):
		n += GameData.recipes_at(k).size()
	return n


## "Fitted as a smithy: forge, anvil (9 recipes)."
func summary(b: Dictionary) -> String:
	var k := station_kinds(b)
	if k.is_empty():
		return "A general store: no workstation fitted."
	return "Fitted as a %s: %s (%d recipe%s can be made here)." % [trade(b), ", ".join(k), recipe_count(b), "" if recipe_count(b) == 1 else "s"]


# ---------------------------------------------------------------- rules --------------------------
func floor_set(b: Dictionary) -> Dictionary:
	var out := {}
	for c in w.interiors.get(str(b.id), {}).get("floor", []):
		out[Vector2i(int(c[0]), int(c[1]))] = true
	return out


## Cells nothing may be put on: doors and their steps, the interior's spots and the cells to use them from,
## the stamp's stations, and the pieces already placed (and where each is used from).
func taken(b: Dictionary) -> Dictionary:
	var out := {}
	var it: Dictionary = w.interiors.get(str(b.id), {})
	for d in it.get("doors", []):
		out[Vector2i(int(d[0]), int(d[1]))] = true
		out[Vector2i(int(d[0]), int(d[1]) - 1)] = true
	for sp in it.get("spots", []):
		out[Vector2i(int(sp.at[0]), int(sp.at[1]))] = true
		out[Vector2i(int(sp.use[0]), int(sp.use[1]))] = true
	var o := Vector2i(int(b.x), int(b.y))
	for s in w.stamp_of(b).get("stations", []):
		out[o + Vector2i(int(s.at[0]), int(s.at[1]))] = true
		out[o + Vector2i(int(s.use[0]), int(s.use[1]))] = true
	for e in list(b):
		out[cell_of(e)] = true
		out[cell_of(e, "use")] = true
	return out


## Whether the stamp itself drew something in the furniture layer there (rugs, shelves of its own).
func _stamp_art(b: Dictionary, cell: Vector2i) -> bool:
	var st := w.stamp_of(b)
	var arr = st.get("layers", {}).get(LAYER)
	var i := (cell.y - int(b.y)) * int(st.w) + (cell.x - int(b.x))
	return arr != null and i >= 0 and i < (arr as Array).size() and int(arr[i]) >= 0


func _reach(b: Dictionary, floor_cells: Dictionary, blocked: Vector2i) -> Dictionary:
	var seen := {}
	var doors: Array = w.interiors.get(str(b.id), {}).get("doors", [])
	if doors.is_empty():
		return seen
	var start := Vector2i(int(doors[0][0]), int(doors[0][1]))
	var queue: Array = [start]
	seen[start] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d in SIDES:
			var n: Vector2i = c + d
			if seen.has(n) or n == blocked or not floor_cells.has(n) or w.map.is_solid(n):
				continue
			seen[n] = true
			queue.append(n)
	return seen


## The cell a piece is used from: the first free floor cell beside it (south first, as the workshops' are).
func find_use(b: Dictionary, cell: Vector2i) -> Vector2i:
	var fl := floor_set(b)
	var tk := taken(b)
	for d in SIDES:
		var n: Vector2i = cell + d
		if fl.has(n) and not w.map.is_solid(n) and (not tk.has(n) or _is_use_cell(b, n)):
			return n
	return Vector2i(-1, -1)


func _is_use_cell(b: Dictionary, c: Vector2i) -> bool:
	for e in list(b):
		if cell_of(e, "use") == c:
			return true
	return false


## Why a piece of this kind cannot stand on this cell of this room, "" if it can.
func why_not(b: Dictionary, kind: String, cell: Vector2i) -> String:
	if not KINDS.has(kind):
		return "That cannot be placed."
	if b.is_empty() or not World.is_built(b) or not w.holds(World.PLAYER, b) or not w.interiors.has(str(b.id)):
		return "Only a room of your own can be fitted out."
	var have := count(b, kind) + (1 if STATIONS.has(kind) and station_kinds(b).has(kind) and count(b, kind) == 0 else 0)
	if have >= limit(kind):
		return "The room has all the %s it can hold." % NAMES[kind] if limit(kind) > 1 else "The room already has a %s." % NAMES[kind]
	var fl := floor_set(b)
	if not fl.has(cell):
		return "It must stand on the floor inside the room"
	if taken(b).has(cell) or _stamp_art(b, cell):
		return "something is there already"
	if w.map.is_solid(cell):
		return "something is in the way"
	var use := find_use(b, cell)
	if use == Vector2i(-1, -1):
		return "there would be no room to stand at it"
	var before := _reach(b, fl, Vector2i(-1, -1))
	var after := _reach(b, fl, cell)
	if not after.has(use):
		return "it would shut the way"
	for k in before:
		if k != cell and not after.has(k):
			return "it would block the way to part of the room"
	var c := cost(kind)
	for id in c:
		if w.player.inv.count(id) < int(c[id]):
			return "you need %s" % cost_text(kind)
	return ""


## Place a piece. "" when done, else why not.
func place(b: Dictionary, kind: String, cell: Vector2i) -> String:
	var why := why_not(b, kind, cell)
	if why != "":
		return why
	var use := find_use(b, cell)
	var c := cost(kind)
	for id in c:
		w.player.inv.remove(id, int(c[id]))
		w.stat("used_building_" + id, float(c[id]))
	var fit := list(b).duplicate()
	fit.append({"kind": kind, "at": [cell.x, cell.y], "use": [use.x, use.y]})
	b.fit = fit
	apply(b, fit[-1], true)
	w.stat("fitted_" + kind)
	w.note("%s %s fitted a %s in %s." % [w.player.name, w.player.family, NAMES[kind], w.property.describe(b)])
	return ""


func station_id(b: Dictionary, kind: String) -> String:
	return "ws_%s_%s" % [b.id, kind]


## Make a piece real: its cell solid, its tile drawn (when `draw`), a station registered.
func apply(b: Dictionary, e: Dictionary, draw: bool) -> void:
	var cell := cell_of(e)
	w.map.set_solid(cell, true)
	if draw:
		w.tile_changed.emit(cell, LAYER, int(ART[str(e.kind)]))
	if STATIONS.has(str(e.kind)):
		var id := station_id(b, str(e.kind))
		var old: Dictionary = w.stations.get(id, {})
		w.stations[id] = {"id": id, "type": str(e.kind), "building": str(b.id), "users": old.get("users", {}), "owner": w.owner_of(b),
			"tenant": "", "at": [cell.x, cell.y], "use": [int(e.use[0]), int(e.use[1])], "fitted": true}


## After a load: every building's pieces are solid and its stations stand again (drawing is main.gd's).
func restore(b: Dictionary) -> void:
	for e in list(b):
		apply(b, e, false)


func restore_all() -> void:
	for id in w.buildings:
		restore(w.buildings[id])


## Take a piece up: the materials return to the pack. A counter takes its open shop with it (the goods and
## coins return to the player). "" when done, else why not.
func remove(b: Dictionary, kind: String) -> String:
	var e := entry(b, kind)
	if e.is_empty():
		return "There is none to take up."
	if STATIONS.has(kind) and not (w.stations.get(station_id(b, kind), {}).get("users", {}) as Dictionary).is_empty():
		return "Someone is working at it."
	var c := cost(kind)
	for id in c:
		if not w.player.inv.can_add(id):
			return "Your pack is full."
	var s: Dictionary = b.get("shop", {})
	if kind == "counter" and not s.is_empty():
		w.note(w.business.close(s, "You took up the counter."))
	elif kind in ["shelves", "stock_chest"] and not s.is_empty():
		var after := count(b, kind) - 1
		if kind == "shelves" and (s.stock as Dictionary).size() > w.business.listing_cap(s, after):
			return "Take some goods off the shelves first."
		if kind == "stock_chest" and w.business.store_total(s) > after * int(GameData.b("shop_store_per_chest")):
			return "Empty some of the stock chest first."
	var fit := list(b).duplicate()
	fit.erase(e)
	b.fit = fit
	var cell := cell_of(e)
	w.map.set_solid(cell, false)
	w.tile_changed.emit(cell, LAYER, -1)
	if STATIONS.has(kind):
		w.stations.erase(station_id(b, kind))
	for id in c:
		w.player.inv.add(id, int(c[id]))
		w.stat("used_building_" + id, -float(c[id]))
	w.note("%s took up the %s in %s." % [w.player.name, NAMES[kind], w.property.describe(b)])
	return ""


## The rooms the player can fit out (built, held by them), for the fit-out target.
func fit_refusal(b: Dictionary) -> String:
	if b.is_empty() or not World.is_built(b) or not w.interiors.has(str(b.id)):
		return "That room cannot be fitted out."
	if not w.holds(World.PLAYER, b):
		return "That is not your room."
	return ""
