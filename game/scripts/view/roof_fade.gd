class_name RoofFade
extends Node2D
## Roofs are drawn over the characters. Owner rules (2026-10-18): while the player is inside a building
## its roof becomes fully transparent so the inside shows; a roof also fades when it would hide the
## player (standing behind its eaves), but only part way, and not for a moment's passing; no flicker.
## Only that one building's roof tiles move: from the map's roof layers (village.json "roof_layers")
## to layers of their own whose alpha is faded, the way CanopyFade fades a tree. Nothing is scanned
## per frame: the building comes from World.roof_over / World.place_of (cell lookups).

const ALPHA := 0.0             # a roof over the player's building, inside it: fully transparent
const EAVES_ALPHA := 0.5       # a roof that would hide the player behind its eaves (agent proposal)
const FADE_TIME := 0.25        # seconds to fade out or back in
const ENTER_HOLD := 0.0        # seconds before a roof lifts on going inside (at once)
const EAVES_HOLD := 0.4        # seconds behind the eaves before that roof fades (no fade in passing)
const LEAVE_HOLD := 0.3        # seconds out from under a roof before it comes back (no door flicker)

var view: MapView
var src: Array[TileMapLayer] = []      # the roof layers, in draw order
var dst: Array[TileMapLayer] = []      # their faded stand-ins
var sorted_dst: Array[TileMapLayer] = []   # the stand-ins of the roof layers' y-sorted twins (among the characters)
var current := ""                      # the building whose roof is lifted (fading or faded), "" none
var alpha := 1.0
var goal := 1.0                        # the alpha the current roof is heading for
var moved := []                        # [layer index, cell, source, coords, alternative]
var want := ""                         # what the player's position asks for, held for `held` seconds
var want_alpha := 1.0
var held := 0.0
var resume_building := ""              # the roof put back by restore_all while it was lifted, and how far (B8-018):
var resume_alpha := 1.0                # lifted again at that alpha, not from fully on, so a map change never flashes it


func setup(v: MapView, roof_layers: Array) -> void:
	view = v
	for name in roof_layers:
		var l := view.layer(str(name))
		if l == null:
			continue
		src.append(l)
		var d := TileMapLayer.new()
		d.tile_set = view.tileset
		d.z_index = l.z_index
		d.visible = false
		add_child(d)
		dst.append(d)
		# GP-DRAW-UNDER-HOUSE: the front edge of a building lives in the layer's y-sorted twin (MapView._refront);
		# it lifts with the rest of the roof, into a faded copy that sorts among the characters the same way
		var twin: TileMapLayer = view.sorted_of.get(l)
		if twin != null:
			src.append(twin)
			var td := TileMapLayer.new()
			td.tile_set = view.tileset
			td.y_sort_enabled = true
			td.visible = false
			twin.get_parent().add_child(td)
			dst.append(td)
			sorted_dst.append(td)


## What the player's position asks of the roofs: {inside, inside_roof, under, under_roof}, the arguments of
## follow. `hold` is the building the player was last inside ("" none): within its outline the player
## stays inside it, on a cell its interior missed (a back room, a courtyard cell), or the roof would
## flick between lifted and eaves-faded (Build 8 reports). Pure: main.gd calls it every frame, the
## tests walk every building with it.
static func probe(world: World, pos: Vector2, hold: String) -> Dictionary:
	var inside := world.place_of(pos)
	if inside != "" and (world.interiors[inside].roof as Array).is_empty():
		inside = ""
	if inside == "" and hold != "" and world.buildings.has(hold) and world.interiors.has(hold):
		var hb: Dictionary = world.buildings[hold]
		if Rect2(float(hb.x), float(hb.y), float(hb.w), float(hb.h)).has_point(pos):
			inside = hold
	# behind the eaves a roof fades only when it would hide the player: over their feet and head both
	var under := world.roof_over(pos)
	if under != "" and world.roof_over(pos + Vector2(0, -1)) != under:
		under = ""
	return {"inside": inside, "inside_roof": world.interiors[inside].roof if inside != "" else [],
			"under": under, "under_roof": world.interiors[under].roof if under != "" else []}


## Called every frame with the building the player is inside ("" none) and the one whose roof is
## over them ("" none): settles which roof to lift and how far, with holds against flicker.
func follow(inside: String, inside_roof: Array, under: String, under_roof: Array, delta: float) -> void:
	var b := inside if inside != "" else under
	var a := ALPHA if inside != "" else (EAVES_ALPHA if under != "" else 1.0)
	if b != want or not is_equal_approx(a, want_alpha):
		want = b
		want_alpha = a
		held = 0.0
	held += delta
	var hold := ENTER_HOLD if inside != "" else (EAVES_HOLD if under != "" else LEAVE_HOLD)
	if held >= hold or b == current:
		update(b, inside_roof if inside != "" else under_roof, a, delta)
	else:
		update(current, [], goal, delta)


## Fade toward `target` alpha over `building` ("" = every roof on).
func update(building: String, roof_cells: Array, target := ALPHA, delta := 0.0) -> void:
	var step := delta * 1.0 / FADE_TIME
	if building != current:
		alpha = move_toward(alpha, 1.0, step)             # the old roof comes back first
		if alpha >= 1.0 or current == "":
			restore_all()
			if building != "":
				_lift(building, roof_cells)
				goal = target
				if building == resume_building:
					alpha = resume_alpha          # it was already lifted this far: carry on from there
				resume_building = ""
	else:
		goal = target if building != "" else 1.0
		alpha = move_toward(alpha, goal, step)
	for d in dst:
		d.modulate.a = alpha


## Put the lifted roof back at once (before the map's roof tiles change).
func restore_all() -> void:
	if current != "":
		resume_building = current
		resume_alpha = alpha
	for m in moved:
		var s: TileMapLayer = src[m[0]]
		s.set_cell(m[1], m[2], m[3], m[4])
	moved.clear()
	for d in dst:
		d.clear()
		d.visible = false
	current = ""
	alpha = 1.0


func is_lifted(building: String) -> bool:
	return building != "" and building == current and alpha < 1.0


## The player's own building shows inside (fully lifted or lifting), not just an eaves fade.
func is_open(building: String) -> bool:
	return is_lifted(building) and goal <= ALPHA


func _lift(building: String, roof_cells: Array) -> void:
	current = building
	alpha = 1.0
	for c in roof_cells:
		var cell := Vector2i(int(c[0]), int(c[1]))
		for i in src.size():
			var s := src[i]
			var id := s.get_cell_source_id(cell)
			if id < 0:
				continue
			moved.append([i, cell, id, s.get_cell_atlas_coords(cell), s.get_cell_alternative_tile(cell)])
			dst[i].set_cell(cell, id, s.get_cell_atlas_coords(cell), s.get_cell_alternative_tile(cell))
			s.erase_cell(cell)
	for d in dst:
		d.visible = true
		d.modulate.a = alpha
