class_name CanopyFade
extends Node2D
## Tree canopies are drawn over the characters, so a character can walk behind a tree. A canopy the
## player is behind fades to see-through, and back when they leave: its tiles move from the map's
## "above" layer to a layer of their own whose alpha is faded. Only the cells the player covers are
## looked at each frame, so the cost does not grow with the number of trees.

const ALPHA := 0.45            # a faded canopy's opacity
const FADE_TIME := 0.15        # seconds to fade out or back in
# the player's drawn body relative to their position (the feet), in tiles: PUNY CHARACTERS fill
# pixels 9-23 x 7-23 of the 32 px frame, which ActorSprite draws with row 23 on the position
const BODY := Rect2(-0.44, -1.0, 0.88, 1.0)

var view: MapView
var top_of := {}               # canopy bottom tile -> its top tile
var bottom_of := {}            # canopy top tile -> its bottom tile
var faded := {}                # tree key -> {layer, cells: [[from layer, cell, source, coords, alt]], alpha}
var owner_of := {}             # faded cell -> its tree key
var pool: Array[TileMapLayer] = []


func setup(v: MapView, canopy: Array) -> void:
	view = v
	for pair in canopy:
		bottom_of[int(pair[0])] = int(pair[1])
		top_of[int(pair[1])] = int(pair[0])


## Fade the canopies over the player standing at feet (tiles); call every frame.
func update(feet: Vector2, delta: float) -> void:
	var want := {}
	var r := Rect2(feet + BODY.position, BODY.size)
	for y in range(floori(r.position.y), floori(r.end.y) + 1):
		for x in range(floori(r.position.x), floori(r.end.x) + 1):
			var c := Vector2i(x, y)
			if owner_of.has(c):
				want[owner_of[c]] = true
				continue
			for i in view.above_layers.size():
				var key := _tree_at(i, c)
				if key != "":
					want[key] = true
	var step := delta * (1.0 - ALPHA) / FADE_TIME
	for key in faded.keys():
		var f: Dictionary = faded[key]
		f.alpha = move_toward(f.alpha, ALPHA if want.has(key) else 1.0, step)
		f.layer.modulate.a = f.alpha
		if f.alpha >= 1.0 and not want.has(key):
			_restore(key)


## Put every faded canopy back at once (before the map's above tiles change).
func restore_all() -> void:
	for key in faded.keys():
		_restore(key)


func is_faded(cell: Vector2i) -> bool:
	return owner_of.has(cell) and float(faded[owner_of[cell]].alpha) < 1.0


## The key of the tree whose canopy covers cell c in above layer i (fading it in if new), or "".
func _tree_at(i: int, c: Vector2i) -> String:
	var src := view.above_layers[i]
	var v := view.tile_value(src, c)
	var cells: Array[Vector2i] = []
	if bottom_of.has(v):
		cells.append(c)
		if view.tile_value(src, c + Vector2i.DOWN) == bottom_of[v]:
			cells.append(c + Vector2i.DOWN)
	elif top_of.has(v):
		if view.tile_value(src, c + Vector2i.UP) == top_of[v]:
			cells.append(c + Vector2i.UP)
		cells.append(c)
	else:
		return ""
	var key := "%d,%d,%d" % [cells[0].x, cells[0].y, i]
	var layer: TileMapLayer = pool.pop_back() if not pool.is_empty() else null
	if layer == null:
		layer = TileMapLayer.new()
		layer.tile_set = view.tileset
		layer.z_index = src.z_index
		add_child(layer)
	var moved := []
	for cell in cells:
		moved.append([src, cell, src.get_cell_source_id(cell), src.get_cell_atlas_coords(cell), src.get_cell_alternative_tile(cell)])
		layer.set_cell(cell, src.get_cell_source_id(cell), src.get_cell_atlas_coords(cell), src.get_cell_alternative_tile(cell))
		src.erase_cell(cell)
		owner_of[cell] = key
	layer.modulate.a = 1.0
	layer.visible = true
	faded[key] = {"layer": layer, "cells": moved, "alpha": 1.0}
	return key


func _restore(key: String) -> void:
	var f: Dictionary = faded[key]
	for m in f.cells:
		var src: TileMapLayer = m[0]
		src.set_cell(m[1], m[2], m[3], m[4])
		owner_of.erase(m[1])
	var layer: TileMapLayer = f.layer
	layer.clear()
	layer.visible = false
	pool.append(layer)
	faded.erase(key)
