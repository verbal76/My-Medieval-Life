class_name ClueView
extends Node2D
## MIN-C: the prospecting clues drawn on the ground (docs/build17/MIN_C_PROSPECTING.md): each stain a faint blotch of
## its ore's colour (prospecting.json "color") on its cell and a few flecks round it, in a pattern hashed from the
## clue's cell, so the same stain looks the same in every game. Drawn under the characters (a child of the blood
## layer, which fades with the surface when the player goes below). Procedural pixels at the 16 px tile, no new art:
## the stains are hints in the soil, not objects. A clue whose samples are all taken still shows: the stain stays.

var tile := 16
var marks: Array = []          # [Rect2 in pixels, Color]


## `open_ground(cell) -> bool`, when given, keeps a mark only if every cell it touches is bare ground: no fleck is
## painted over a plant or a solid object drawn in the map's "below" layer (the stains are in the soil).
func setup(p: Prospecting, tile_px: int, open_ground := Callable()) -> void:
	tile = tile_px
	marks.clear()
	if p == null:
		return
	var ores: Dictionary = Prospecting.cfg().ores
	for c in p.clues:
		var rgb: Array = ores.get(str(c.ore), {}).get("color", [0.4, 0.3, 0.2])
		var base := Vector2(int(c.x), int(c.y)) * tile
		for i in 9:
			var h := Overworld.hash32(int(c.x), int(c.y), Prospecting.SALT_SPOT + i, 7)
			var span := tile + 6 if i < 6 else tile * 2
			var off := Vector2(h % span, (h >> 8) % span) - Vector2(span - tile, span - tile) / 2.0
			var size := 3 if i < 3 else (2 if i < 6 else 1)
			var a := 0.55 if i < 6 else 0.75
			var r := Rect2(base + off, Vector2(size, size))
			if open_ground.is_valid() and not _on_open_ground(r, open_ground):
				continue
			marks.append([r, Color(float(rgb[0]), float(rgb[1]), float(rgb[2]), a)])
	queue_redraw()


func _on_open_ground(r: Rect2, open_ground: Callable) -> bool:
	for corner in [r.position, r.end - Vector2.ONE]:
		if not open_ground.call(Vector2i((corner / tile).floor())):
			return false
	return true


func _draw() -> void:
	for m in marks:
		draw_rect(m[0], m[1])
