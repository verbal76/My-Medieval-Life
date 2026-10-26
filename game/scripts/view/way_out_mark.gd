class_name WayOutMark
extends Node2D
## GP-MINE-WOOD-FRAME (owner playtest 2026-10-26): below ground the way back up (the adit's or the cave's mouth: a portal
## whose other end is on the surface) was drawn as nothing but the passage running into the dark rock. It is drawn here
## as what it is: daylight falling in at the door cell, brightest at the mouth and fading toward the passage, with a few
## worn steps rising out. Drawn on the door cell only (rock, never a seam), under the characters and the darkness; the
## crossing itself (Main._through_portal, the tap on the door) is unchanged. Presentation only.

const LIGHT := Color(1.0, 0.93, 0.70)
const STEP := Color(0.55, 0.50, 0.42)
const STEP_DARK := Color(0.30, 0.27, 0.23)

var doors: Array = []          # [door cell, the way out (unit vector from the stand to the door)]
var tile := 16


func setup(w: World, lm: LevelMap) -> void:
	doors.clear()
	if w.underground == null:
		return
	for p in w.underground.portals:
		if str(p.get("kind", "")) == "shaft":
			continue                              # a shaft's ladder is drawn by WorksView
		for i in 2:
			var e: Dictionary = p.ends[i]
			var other: Dictionary = p.ends[1 - i]
			if int(e.level) == lm.level and int(other.level) == 0 and lm.in_level(e.door):
				doors.append([Vector2i(e.door), Vector2(Vector2i(e.door) - Vector2i(e.stand)).normalized()])
	queue_redraw()


func _draw() -> void:
	for d in doors:
		var c: Vector2i = d[0]
		var out: Vector2 = d[1]
		var o := Vector2(c) * tile
		draw_rect(Rect2(o, Vector2(tile, tile)), Color(0.05, 0.04, 0.03))        # the opening in the rock
		for k in 4:                                                                # daylight, brighter toward the outside
			var f := float(k + 1) / 4.0
			var band := Rect2(o, Vector2(tile, tile))
			if absf(out.y) >= absf(out.x):
				band = Rect2(o + Vector2(2, (float(k) * 4.0) if out.y > 0.0 else (12.0 - float(k) * 4.0)), Vector2(12, 4))
			else:
				band = Rect2(o + Vector2((float(k) * 4.0) if out.x > 0.0 else (12.0 - float(k) * 4.0), 2), Vector2(4, 12))
			draw_rect(band, Color(LIGHT, 0.25 + 0.6 * f))
		for k in 3:                                                                # worn steps rising out
			var r: Rect2
			if absf(out.y) >= absf(out.x):
				var y := 2.0 + float(k) * 5.0 if out.y < 0.0 else 12.0 - float(k) * 5.0
				r = Rect2(o + Vector2(3, y), Vector2(10, 1))
			else:
				var x := 2.0 + float(k) * 5.0 if out.x < 0.0 else 12.0 - float(k) * 5.0
				r = Rect2(o + Vector2(x, 3), Vector2(1, 10))
			draw_rect(r, STEP_DARK)
