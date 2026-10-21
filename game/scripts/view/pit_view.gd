class_name PitView
extends Node2D
## MIN-E: the open pits drawn on the village's ground (docs/build17/MIN_E_OPEN_PIT.md). A child of the village's
## MapView, under its "below" layers (a seam opened in a pit is drawn there, over the pit's floor) and the characters,
## so it fades with the surface. Each dug cell shows the layer it is down to with the village's own tiles (the free
## atlas's dirt for topsoil and dirt, the hill's rock fill for spoil, the quarry's grey cobbled slab for stone),
## darker the deeper it is, with a shadow band along every side that drops from a shallower neighbour (the terrace
## walls); the ramp's cells are lighter and stepped. A staked pit shows its four corner stakes; a spoil heap is a mound
## of its earth's colour, its size by how full it is. No new art: the tiles are the map's (asset pipeline: existing
## tiles); the stakes and mounds are a few procedural pixels at the 16 px tile, as ClueView's stains are.

const DIRT := 100038                       # the free atlas's plain dirt (village.json ground)
const RUBBLE := 16751                      # the hill top's rock fill (ROCK_FILL, tools/build_village.py)
const SLAB := 9287                         # the quarry's grey cobbled stone (ROCK_SLAB)
const EARTH := {"topsoil": Color(0.30, 0.21, 0.12), "dirt": Color(0.55, 0.38, 0.22), "spoil": Color(0.50, 0.47, 0.42)}

var tile := 16
var pits: OpenPits
var src: MapView


func setup(map_view: MapView, open_pits: OpenPits) -> void:
	src = map_view
	pits = open_pits
	if pits != null and not pits.changed.is_connected(queue_redraw):
		pits.changed.connect(queue_redraw)
	queue_redraw()


func _tex(v: int) -> Array:
	var atlas := v / 100000
	var t := v % 100000
	var cols: int = src.columns[atlas]
	return [src.sources[atlas].texture, Rect2((t % cols) * tile, (t / cols) * tile, tile, tile)]


func _tile_for(item: String) -> int:
	match item:
		"spoil":
			return RUBBLE
		"stone":
			return SLAB
	return DIRT


func _draw() -> void:
	if pits == null or src == null:
		return
	var s := OpenPits.size()
	var ls := OpenPits.layers()
	for p in pits.pits:
		var o := Vector2(int(p.x), int(p.y)) * tile
		var touched := false
		for i in s * s:
			var dug := int(p.dug[i])
			if dug <= 0 and not OpenPits.is_ramp(i):
				continue
			touched = touched or dug > 0
			var d := OpenPits.depth_of(dug)
			var at := o + Vector2(i % s, i / s) * tile
			var r := Rect2(at, Vector2(tile, tile))
			if dug <= 0:
				continue
			var item := str(ls[mini(d, ls.size() - 1)].item)
			var t := _tex(_tile_for(item))
			if d == 0:
				draw_texture_rect_region(t[0], r, t[1], Color(1, 1, 1, 0.6))       # topsoil being stripped
				continue
			var shade := maxf(0.42, 1.0 - 0.14 * d)
			if OpenPits.is_ramp(i):
				t = _tex(DIRT)
				shade = maxf(0.55, 1.0 - 0.09 * d)
			draw_rect(r, Color(0.42, 0.31, 0.2) * Color(shade, shade, shade))     # earth under the tile (the dirt tile is not opaque)
			draw_texture_rect_region(t[0], r, t[1], Color(shade, shade, shade))
			if OpenPits.is_ramp(i):
				for k in 3:                                                    # the ramp's steps
					draw_rect(Rect2(at + Vector2(2, 3 + k * 5), Vector2(tile - 4, 1)), Color(0.18, 0.12, 0.07, 0.45))
			# terrace walls: a shadow along each side where the ground is higher
			for side in [[Vector2i(0, -1), Rect2(0, 0, tile, 3)], [Vector2i(-1, 0), Rect2(0, 0, 3, tile)],
					[Vector2i(1, 0), Rect2(tile - 2, 0, 2, tile)], [Vector2i(0, 1), Rect2(0, tile - 2, tile, 2)]]:
				var nc: Vector2i = Vector2i(int(p.x) + i % s, int(p.y) + i / s) + side[0]
				var ni := OpenPits.index(p, nc)
				var nd := OpenPits.depth_of(int(p.dug[ni])) if ni >= 0 else 0
				if nd < d:
					var band: Rect2 = side[1]
					draw_rect(Rect2(at + band.position, band.size), Color(0.08, 0.06, 0.05, minf(0.75, 0.3 + 0.15 * (d - nd))))
		if not touched:                                                        # staked: four corner stakes
			for c in [Vector2(0, 0), Vector2(s, 0), Vector2(0, s), Vector2(s, s)]:
				var at: Vector2 = o + c * tile - Vector2(1, 6)
				draw_rect(Rect2(at, Vector2(2, 6)), Color(0.42, 0.28, 0.14))
				draw_rect(Rect2(at, Vector2(2, 1)), Color(0.85, 0.80, 0.70))
		for h in p.heaps:
			var inv: Inventory = h.inv
			var n := inv.total()
			if n <= 0:
				continue
			var most := ""
			for id in inv.ids():
				if most == "" or inv.count(id) > inv.count(most):
					most = id
			var col: Color = EARTH.get(most, EARTH.dirt)
			var f := clampf(float(n) / float(maxi(1, pits.heap_cap(p))), 0.0, 1.0)
			var cx := (float(int(h.x)) + 0.5) * tile
			var by := (float(int(h.y)) + 1.0) * tile - 1.0
			var rx := tile * (0.28 + 0.2 * f)
			var ry := tile * (0.16 + 0.22 * f)
			_mound(Vector2(cx, by - ry), rx, ry, col)


## A heap of earth: a dark rim, the earth, and the light on its upper left, a dome standing on the cell's bottom.
func _mound(c: Vector2, rx: float, ry: float, col: Color) -> void:
	_dome(c, rx, ry, col.darkened(0.45))
	_dome(c + Vector2(0, 1), rx - 1.0, ry - 1.0, col)
	_dome(c + Vector2(-rx * 0.3, -ry * 0.25), rx * 0.35, ry * 0.3, col.lightened(0.22))


## The upper half of an ellipse round `c` over a block down to `c.y + ry`.
func _dome(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for a in 13:
		var ang := PI + PI * float(a) / 12.0
		pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
	pts.append(c + Vector2(rx, ry))
	pts.append(c + Vector2(-rx, ry))
	draw_colored_polygon(pts, col)
