class_name PlacementGhost
extends Node2D
## The footprint of a building the player is placing: a tinted rectangle over the ground it would
## cover, green where it may go and red where it may not, its door cell marked and, when it may go,
## a faint outline of its roof edge. Drawn over the map and the roofs; pixel-aligned (16 px tiles).

const T := 16
const OK := Color(0.35, 0.85, 0.35)
const NO := Color(0.9, 0.25, 0.2)

var rect := Rect2i()
var door := Vector2i(-1, -1)
var legal := false


func show_at(r: Rect2i, door_cell: Vector2i, ok: bool) -> void:
	rect = r
	door = door_cell
	legal = ok
	visible = true
	queue_redraw()


func _draw() -> void:
	if rect.size == Vector2i.ZERO:
		return
	var c := OK if legal else NO
	var px := Rect2(Vector2(rect.position) * T, Vector2(rect.size) * T)
	draw_rect(px, Color(c, 0.28))
	# the tile grid, faint, so the footprint reads in tiles
	for x in range(1, rect.size.x):
		draw_line(px.position + Vector2(x * T, 0), px.position + Vector2(x * T, px.size.y), Color(c, 0.18), 1.0)
	for y in range(1, rect.size.y):
		draw_line(px.position + Vector2(0, y * T), px.position + Vector2(px.size.x, y * T), Color(c, 0.18), 1.0)
	draw_rect(px, Color(c, 0.95), false, 2.0)
	if door.x >= 0:
		var d := Rect2(Vector2(door) * T, Vector2(T, T))
		draw_rect(d, Color(1.0, 0.85, 0.4, 0.75))
		draw_rect(d, Color(0.3, 0.2, 0.1), false, 1.5)
