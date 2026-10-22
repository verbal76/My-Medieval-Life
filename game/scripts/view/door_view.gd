class_name DoorView
extends Node2D
## VIS-DOOR-01 (owner, B18-DIR Part 5): people go in and out of a building through an open, dark doorway instead of
## walking under the closed door. Looks only: nobody's path, position or access changes; it reads where people are.
##
## - The village's houses and workshops draw their wooden door twice: in a "below" layer under the characters and,
##   as part of the roof, in an "above" layer over them, so whoever stood in the doorway was drawn under the closed
##   door. The copy over the doorway is taken out of the above layers (setup, rescan); the door under the characters
##   stays, so a door nobody is using looks as it did.
## - While someone is stepping through the doorway (past the middle of its step, or in the door cell), or was under
##   HOLD seconds ago (no closing on a person, no flicker when several pass), the door is drawn open: a dark opening
##   inside its frame. A child of the village's MapView, after its ground layers: under the characters, so they walk
##   into the opening.
## - Someone crossing the threshold into a building whose inside is hidden (its roof is on) darkens and fades as
##   they go in, more the further in (`self_modulate` of their sprite, which nothing else uses), and comes out the
##   same way reversed. When the inside shows (the player is in there and the roof is lifted), nobody fades.

const DOOR_ART := [3875]          # the wooden door tile of the village's and the stamps' doorways (Puny World atlas)
const HOLD := 0.4                 # seconds a door stays open after the last person has left its step
const OPEN_AT := 0.6              # how far through (depth) someone must be for the door to open: past the step's middle,
                                  # so a villager only waiting on the step does not hold it open
const OPENING := Color(0.07, 0.05, 0.06)
const OPEN_RECT := Rect2(1, 1, 14, 12)       # the opening inside the door tile's frame (the tile's dark edges kept)
const T := 16

var world: World
var view: MapView
var roofs: RoofFade
var doors := []                   # {cell, step, out (Vector2: from the doorway to the step), building, open}
var zone := {}                    # door cell or step cell -> index in doors
var faded := {}                   # sprite instance id -> sprite: sprites this view has darkened
var stripped := {}                # door cell -> [[layer, value]]: the door copies taken out of the above layers


func setup(w: World, v: MapView, r: RoofFade) -> void:
	world = w
	view = v
	roofs = r
	rescan()


## Find every doorway with a wooden door (the buildings' interiors list their door cells; the step is the door
## cell's neighbour outside the building) and take the door copies over them out of the above layers. Called again
## after a building is built (main.gd _on_building_added), whose stamp brings its own door.
func rescan() -> void:
	doors.clear()
	zone.clear()
	var ids: Array = world.interiors.keys()
	ids.sort()
	for id in ids:
		for dc in world.interiors[id].get("doors", []):
			var cell := Vector2i(int(dc[0]), int(dc[1]))
			if not _has_door_art(cell):
				continue
			var step := _step_of(cell, str(id))
			if step == cell:
				continue
			zone[cell] = doors.size()
			zone[step] = doors.size()
			doors.append({"cell": cell, "step": step, "out": Vector2(step - cell), "building": str(id), "open": 0.0})
			_strip(cell)
	queue_redraw()


func _has_door_art(cell: Vector2i) -> bool:
	for name in view.layers:
		if str(name).begins_with("below") and DOOR_ART.has(view.tile_value(view.layers[name], cell) % 100000):
			return true
	return false


## The cell just outside a door: south first (the village's doors face south), then the other sides.
func _step_of(cell: Vector2i, building: String) -> Vector2i:
	for d in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		var c: Vector2i = cell + d
		if world.place_of(Vector2(c) + Vector2(0.5, 0.5)) != building and not world.map.is_solid(c):
			return c
	return cell


func _strip(cell: Vector2i) -> void:
	for layer in view.above_layers:
		var v := view.tile_value(layer, cell)
		if v >= 0:
			stripped[cell] = stripped.get(cell, []) + [[layer, v]]
			view.set_tile(layer, cell, -1)


## How far someone at `pos` is through a doorway: 0 at the outer edge of its step, 1 on the threshold, 2 at the
## inner edge of the door cell; -1 when not in that doorway's step or door cell (or off to its side).
static func depth(door: Dictionary, pos: Vector2) -> float:
	var out: Vector2 = door.out
	var outer: Vector2 = Vector2(door.step) + Vector2(0.5, 0.5) + out * 0.5
	var along := (pos - outer).dot(-out)
	var side := absf((pos - outer).dot(Vector2(out.y, -out.x)))
	if along < 0.0 or along > 2.0 or side > 0.7:
		return -1.0
	return along


## Every frame: `people` is [position, sprite or null] for everyone who could be at a door (a sprite only when it is
## drawn). Opens the doors someone is using and darkens those going into a hidden inside.
func update(people: Array, delta: float) -> void:
	var using := {}
	for pp in people:
		var pos: Vector2 = pp[0]
		var i: int = zone.get(Vector2i(floori(pos.x), floori(pos.y)), -1)
		var k := 0.0
		if i >= 0:
			var dp := depth(doors[i], pos)
			if dp >= OPEN_AT:
				using[i] = true
			if dp >= 0.0 and not _inside_shown(doors[i].building):
				k = clampf((dp - OPEN_AT) / (1.0 - OPEN_AT), 0.0, 1.0)
		var s: CanvasItem = pp[1]
		if s == null:
			continue
		if k > 0.0:
			s.self_modulate = Color(1.0 - 0.75 * k, 1.0 - 0.75 * k, 1.0 - 0.7 * k, 1.0 - 0.6 * k)
			faded[s.get_instance_id()] = s
		elif faded.has(s.get_instance_id()):
			s.self_modulate = Color.WHITE
			faded.erase(s.get_instance_id())
	var changed := false
	for i in doors.size():
		var was: bool = float(doors[i].open) > 0.0
		doors[i].open = HOLD if using.has(i) else maxf(0.0, float(doors[i].open) - delta)
		changed = changed or was != (float(doors[i].open) > 0.0)
	if changed:
		queue_redraw()


## Whether the inside of a building is on show: the player is in it and its roof is lifted (or it has no roof).
func _inside_shown(building: String) -> bool:
	if world.interiors.has(building) and (world.interiors[building].get("roof", []) as Array).is_empty():
		return true
	return roofs != null and roofs.current == building and roofs.alpha < 0.5


func is_open(cell: Vector2i) -> bool:
	var i: int = zone.get(cell, -1)
	return i >= 0 and doors[i].cell == cell and float(doors[i].open) > 0.0


func _draw() -> void:
	for d in doors:
		if float(d.open) > 0.0:
			draw_rect(Rect2(Vector2(d.cell) * T + OPEN_RECT.position, OPEN_RECT.size), OPENING)
