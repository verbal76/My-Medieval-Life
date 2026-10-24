class_name Furniture
extends RefCounted
## Furniture behaviour by spot kind (PL1-07 poses, PL2-013 player housing). Every interior's `spots`
## (World.interiors: the map's buildings and the stamps of buildings the player builds) carry a `kind`;
## what a kind does is defined here once, so a new room, house or kitchen gets it with no code of its own:
##
##   bed     lie in it (people sleep in it; the player rests in it and wakes beside it)
##   chair   sit on it (people eat seated; the player sits, and stands up with any input)
##   hearth  a home hearth: the "oven" and "stove" stations' recipes (roasting, pottage, brewing), never the
##           forge's smelting; the same list for the player and villagers (FSE-B11, home_recipes)
##   table   a food table: the "prep" station's recipes (cold preparation, no heat)
##
## The chairs are not in the map's spot lists (the generator emits beds, tables, hearths and chests); they
## are found here from the stool tiles Shade drew (CHAIR_TILES) in the interior's own floor cells, by
## `with_chairs`, so a chair is a spot like any other. Map data, never saved. docs/BUILD_DECISIONS.md.

const CHAIR_TILES := [1003]                               # Shade's wooden stool (paid atlas tile ids)
const LAYERS := ["below0", "below1", "below2"]            # the layers furniture is drawn in
const STATION_OF := {"hearth": "oven", "table": "prep"}   # a home's spot kind -> the crafting station it is
const HOME_STATIONS := {"hearth": ["oven", "stove"], "table": ["prep"]}   # whose recipes a home spot offers (FSE-B11)
const HOME_PREFIX := "home:"                              # a home station's id: home:<building>:<kind>:<x>,<y>
const FACES := {"S": 0, "E": 2, "N": 4, "W": 6}           # ActorSprite DIRS indices


## `it` (an interior: area, floor, spots, ...) with a "chair" spot for every stool tile in its area.
## `tiles`: layer name -> flat cell array of `tw` cells a row, for the interior's own origin `o`
## (the map's layers at (0,0); a building stamp's at the stamp's offset).
static func with_chairs(it: Dictionary, layers: Dictionary, tw: int, o: Vector2i) -> Dictionary:
	if it.is_empty() or not it.has("spots"):
		return it
	var out := it.duplicate()
	var spots: Array = (it.spots as Array).duplicate()
	var floor_cells := {}
	for c in it.floor:
		floor_cells[Vector2i(int(c[0]), int(c[1]))] = true
	var taken := {}
	for s in spots:
		taken[Vector2i(int(s.at[0]), int(s.at[1]))] = true
	var cells := []
	for c in it.area:
		cells.append(Vector2i(int(c[0]), int(c[1])))
	cells.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y or (a.y == b.y and a.x < b.x))
	for c: Vector2i in cells:
		var lc: Vector2i = c - o
		var found := false
		for ln in LAYERS:
			var arr = layers.get(ln)
			if arr != null and lc.x >= 0 and lc.y >= 0 and lc.y * tw + lc.x < (arr as Array).size() and int(arr[lc.y * tw + lc.x]) in CHAIR_TILES:
				found = true
		if not found:
			continue
		var use := _use_cell(c, floor_cells, taken)
		if use == Vector2i(-1, -1):
			continue
		var face := _face_of(c, spots)
		spots.append({"kind": "chair", "at": [c.x, c.y], "use": [use.x, use.y], "face": face})
	out.spots = spots
	return out


## The cell to walk to for a chair: the chair's own cell when it can be walked on, else the nearest
## free floor cell beside it.
static func _use_cell(c: Vector2i, floor_cells: Dictionary, taken: Dictionary) -> Vector2i:
	if floor_cells.has(c):
		return c
	for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var n: Vector2i = c + d
		if floor_cells.has(n) and not taken.has(n):
			return n
	return Vector2i(-1, -1)


## Which way a chair faces: toward an adjacent table (S, E, N or W), else south.
static func _face_of(c: Vector2i, spots: Array) -> String:
	for pair in [["S", Vector2i(0, 1)], ["N", Vector2i(0, -1)], ["E", Vector2i(1, 0)], ["W", Vector2i(-1, 0)]]:
		for s in spots:
			if s.kind == "table" and Vector2i(int(s.at[0]), int(s.at[1])) == c + (pair[1] as Vector2i):
				return pair[0]
	return "S"


## The ActorSprite direction index a chair spot looks toward.
static func face_dir(spot: Dictionary) -> int:
	return int(FACES.get(str(spot.get("face", "S")), 0))


## Whether a kind is a crafting station of a home (hearth: oven, table: prep).
static func station_kind(kind: String) -> String:
	return str(STATION_OF.get(kind, ""))


## The recipes a home spot of a kind offers: one list for the player's craft window and the villagers' home cooking
## and brewing (FSE-B11: villagers cooked stove recipes at the hearth, the player only oven ones).
static func home_recipes(kind: String) -> Array:
	var out := []
	for st in HOME_STATIONS.get(kind, []):
		out += GameData.recipes_at(str(st))
	out.sort()
	return out


# ---------------------------------------------------------------- home stations ----------------
## The station id of a home's spot, for the craft window and the recipes (not a World.stations entry: the
## villagers' own work never uses them).
static func station_id(building: String, spot: Dictionary) -> String:
	return "%s%s:%s:%d,%d" % [HOME_PREFIX, building, spot.kind, int(spot.at[0]), int(spot.at[1])]


static func is_home_station(id: String) -> bool:
	return id.begins_with(HOME_PREFIX)


## The station a home station id names: {id, type, building}.
static func station_def(id: String) -> Dictionary:
	var parts := id.trim_prefix(HOME_PREFIX).split(":")
	if parts.size() < 3:
		return {}
	return {"id": id, "type": station_kind(parts[1]), "kind": parts[1], "building": parts[0], "home": true}


## Why the player may not use a home's furniture ("" = may): it is their own home, or one they hold.
static func home_refusal(w, id: String) -> String:
	var d := station_def(id)
	if d.is_empty() or str(d.type) == "":
		return "That is not something to cook or prepare at."
	var b: Dictionary = w.buildings.get(str(d.building), {})
	if b.is_empty():
		return "That is not something to cook or prepare at."
	if str(w.player.home) == str(d.building) or w.holds(w.acting_ref(), b):
		return ""
	return "This is not your house; you need leave to use its %s." % ("hearth" if d.type == "oven" else "table")


## The label a home station offers.
static func station_label(type: String) -> String:
	return "Cook at the hearth" if type == "oven" else "Prepare food at the table"


## Spots of a player's own place to use, near `probe` (the point in front of the player): the player is
## inside building `place` and it is theirs. Returns candidates {kind, spot, id?, label} in order of
## distance; main.gd adds them to the target list (every input reaches them: they are ordinary targets).
static func options(w, place: String, probe: Vector2) -> Array:
	var out := []
	if place == "" or not w.interiors.has(place):
		return out
	var b: Dictionary = w.buildings.get(place, {})
	if str(w.player.home) != place and (b.is_empty() or not w.holds(w.acting_ref(), b)):
		return out
	for sp in w.interiors[place].spots:
		var at := Vector2(int(sp.at[0]), int(sp.at[1])) + Vector2(0.5, 0.5)
		if at.distance_to(probe) >= 0.9:
			continue
		if sp.kind == "chair":
			out.append({"kind": "sit", "spot": sp, "id": station_id(place, sp), "dist": at.distance_to(probe), "label": "Sit on the chair"})
		elif station_kind(str(sp.kind)) != "":
			var sid := station_id(place, sp)
			var no := home_refusal(w, sid)
			out.append({"kind": "station", "id": sid, "spot": sp, "dist": at.distance_to(probe),
					"label": station_label(station_kind(str(sp.kind))) if no == "" else no})
	out.sort_custom(func(a, b): return a.dist < b.dist)
	return out
