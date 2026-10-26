class_name WantedRing
extends Node2D
## GP-WANTED-INDICATOR (owner, 2026-10-26: "a red circle around our body so I know when I am being hunted by guards"): a red
## ring round the player's character, on the ground at the feet and round the body, drawn behind the sprite while a guard
## is on this player's case (Justice.alert `hunted`: pursuing, coming to where they were reported, or searching); gone
## when nobody is. A child of the player's ActorSprite (whose origin is the feet). Presentation only: it reads the case,
## never writes it.

const RED := Color8(226, 40, 32)
const RX := 9.0           # the ring's half-width (pixels at 1x: a little wider than the 16 px body)
const RY := 4.5           # its half-height (a ring lying on the ground)
const RISE := 8.0         # the upper ring round the body, from the feet
var on := false
var t := 0.0


func _init() -> void:
	name = "WantedRing"
	show_behind_parent = true
	visible = false


func set_on(v: bool, delta := 0.0) -> void:
	on = v
	visible = v
	if v:
		t += delta
		queue_redraw()


func _draw() -> void:
	var pulse := 0.65 + 0.35 * sin(t * 5.0)
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * float(i) / 32.0
		pts.append(Vector2(cos(a) * RX, sin(a) * RY))
	draw_colored_polygon(pts.slice(0, 32), Color(RED, 0.22 * pulse))
	draw_polyline(pts, Color(RED, 0.95 * pulse), 1.5)
	# round the body too, so it reads on any ground (a faint circle; the sprite covers its middle)
	draw_arc(Vector2(0, -RISE), 11.0, 0.0, TAU, 40, Color(RED, 0.75 * pulse), 1.0)
