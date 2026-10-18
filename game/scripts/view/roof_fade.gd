class_name RoofFade
extends Node2D
## Roofs are drawn over the characters. While the player is under a building's roof (inside it, or
## behind its eaves), that building's roof fades out so its inside shows, and comes back when they
## leave (owner decision: roof fade, one continuous world, no separate interior scenes). Only that
## one building's roof tiles move: from the map's roof layers (village.json "roof_layers") to layers
## of their own whose alpha is faded, the way CanopyFade fades a tree. Nothing is scanned per frame:
## the building comes from World.roof_over (a cell lookup).

const ALPHA := 0.0             # a faded roof's opacity
const FADE_TIME := 0.25        # seconds to fade out or back in

var view: MapView
var src: Array[TileMapLayer] = []      # the roof layers, in draw order
var dst: Array[TileMapLayer] = []      # their faded stand-ins
var current := ""                      # the building whose roof is lifted (fading or faded), "" none
var alpha := 1.0
var moved := []                        # [layer index, cell, source, coords, alternative]


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


## Fade toward showing the inside of `building` ("" = every roof on); call every frame.
func update(building: String, roof_cells: Array, delta: float) -> void:
	var step := delta * (1.0 - ALPHA) / FADE_TIME
	if building != current:
		alpha = move_toward(alpha, 1.0, step)             # the old roof comes back first
		if alpha >= 1.0 or current == "":
			restore_all()
			if building != "":
				_lift(building, roof_cells)
	else:
		alpha = move_toward(alpha, ALPHA, step)
	for d in dst:
		d.modulate.a = alpha


## Put the lifted roof back at once (before the map's roof tiles change).
func restore_all() -> void:
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
