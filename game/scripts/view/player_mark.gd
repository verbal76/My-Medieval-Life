class_name PlayerMark
extends Node2D
## MP-INTERACT-01 (owner, 2026-10-27): the mark of another player in reach, a ring at their feet: faint for each player Use, Talk or
## Next could choose, bright (breathing) round the one chosen. The players' counterpart of TargetOutline's glow (which follows a
## thing's drawn tiles): a player moves, so the ring follows the drawn character. main hands it the places; this only draws.

const NEAR := Color(1.0, 0.9, 0.55, 0.45)
const CHOSEN := Color(1.0, 0.95, 0.7, 1.0)
const RADIUS := Vector2(7.0, 3.5)           # pixels: the ellipse round a character's feet

var marks: Array = []                       # [[position (world pixels), chosen: bool], ...] drawn now (tests read it)


func show_marks(list: Array) -> void:
	if list.is_empty() and marks.is_empty():
		return
	marks = list
	queue_redraw()


func _process(_delta: float) -> void:
	if not marks.is_empty():
		queue_redraw()                      # the chosen one breathes, and the players move


func _draw() -> void:
	var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() / 260.0)
	for m in marks:
		var at: Vector2 = m[0]
		var col: Color = CHOSEN * Color(1, 1, 1, pulse) if m[1] else NEAR
		var pts := PackedVector2Array()
		for i in 25:
			var a := TAU * i / 24.0
			pts.append(at + Vector2(cos(a) * RADIUS.x, sin(a) * RADIUS.y))
		draw_polyline(pts, col, 1.0 if not m[1] else 1.5)
