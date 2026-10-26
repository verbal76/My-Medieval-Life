class_name TargetOutline
extends Node2D
## GP-INTERACTABLE-OUTLINES (owner, 2026-10-24): a soft glow round the drawn shape of each usable thing in reach (a station,
## a chest, a counter, a stall, a seam...), brighter round the one Use would take (main.target). Not a new interaction
## framework: main hands it the things already on offer (main.target_options, which keep the reach and the rules) and the
## map cells each is drawn on; this only draws.
##
## The shape is the object's own pixels: the map's tiles at its cells (every layer but the ground, the paths and the roofs)
## and, where its art runs into the cells beside it (an oven's chimney, a long bench), the pixels joined to it there, never
## a wall or a floor beside it. Each shape is built once (a small image, cached by its tiles) and drawn as one sprite: at
## most MAX_SHOWN at a time, so the cost stays a handful of sprites whatever the village holds.

const T := 16
const MAX_SHOWN := 6
const NEAR := Color(1.0, 0.9, 0.55, 0.5)          # a thing in reach: a faint warm glow
const CHOSEN := Color(1.0, 0.95, 0.7, 1.0)        # the thing Use would take: bright
const CACHE_MAX := 48

var view: MapView
var sprites: Array[Sprite2D] = []
var cache := {}                    # signature -> {"tex": ImageTexture, "origin": Vector2 (world pixels)}
var _images := {}                  # atlas source id -> Image
var shown: Array = []              # tests: [cells, chosen] of each outline drawn now
var _last_key := ""
var _layers: Array = []            # [TileMapLayer, is the object's own layer set (not the wall row below0)] to read


func setup(v: MapView) -> void:
	view = v
	z_index = 0                    # drawn just before the characters (main puts the node there): over the floor, under people
	_layers.clear()
	var roofs: Array = view.map.data.get("roof_layers", [])
	for lay in view.map.data.layers:
		if str(lay.z) in ["ground", "path"] or roofs.has(lay.name):
			continue
		var layer: TileMapLayer = view.layers[lay.name]
		for l in [layer, view.sorted_of.get(layer)]:
			if l != null:
				_layers.append([l, str(lay.name) != "below0"])


## Draw the outlines: `items` is [[shape, chosen: bool], ...], a shape being the map cells a thing is drawn on (Array of
## Vector2i) or a sprite drawn over the map ({"tex": Texture2D, "at": its top-left, world pixels}: a market shelf); only the
## first MAX_SHOWN are drawn. The
## shapes are looked up only when the list changes; each frame otherwise only the chosen one's glow breathes.
func show_items(items: Array) -> void:
	var key := str(items.slice(0, MAX_SHOWN))
	if key != _last_key:
		_last_key = key
		shown = items.slice(0, MAX_SHOWN)
		while sprites.size() < shown.size():
			var s := Sprite2D.new()
			s.centered = false
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(s)
			sprites.append(s)
		for i in sprites.size():
			var s := sprites[i]
			var o := outline_of(shown[i][0]) if i < shown.size() else {}
			s.visible = not o.is_empty()
			if not o.is_empty():
				s.texture = o.tex
				s.position = o.origin
	var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() / 260.0)
	for i in shown.size():
		sprites[i].modulate = CHOSEN * Color(1, 1, 1, pulse) if shown[i][1] else NEAR


## Forget what is drawn (the map changed under it: a new game, a building put up).
func reset() -> void:
	_last_key = ""
	cache.clear()


## The outline of a shape (see show_items; {} if nothing is drawn there): built once per set of tiles or sprite, then cached.
func outline_of(shape) -> Dictionary:
	if shape is Dictionary:
		return _sprite_outline(shape)
	var cells: Array = shape
	if cells.is_empty() or view == null:
		return {}
	var lo: Vector2i = cells[0]
	var hi: Vector2i = cells[0]
	for c: Vector2i in cells:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	lo -= Vector2i.ONE                 # the art may run one cell past its cells (a chimney, the far end of a bench)
	hi += Vector2i.ONE
	var sig := PackedStringArray()
	for c: Vector2i in cells:
		sig.append("%d,%d" % [c.x, c.y])
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			for l in _layers:
				var tl: TileMapLayer = l[0]
				var src := tl.get_cell_source_id(Vector2i(x, y))
				if src >= 0:
					var ac := tl.get_cell_atlas_coords(Vector2i(x, y))
					sig.append("%d:%d,%d" % [src, ac.x, ac.y])
	var key := "|".join(sig)
	if cache.has(key):
		return cache[key]
	var o := _build(cells, lo, hi)
	if cache.size() >= CACHE_MAX:
		cache.clear()
	cache[key] = o
	return o


func _tile_image(src: int) -> Image:
	if not _images.has(src):
		var img: Image = view.sources[src].texture.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		_images[src] = img
	return _images[src]


## The object's pixels (the tiles on its own cells, and the pixels of the cells round them joined to those), and a glow
## two pixels wide round them: the inner ring solid, the outer one faint.
func _build(cells: Array, lo: Vector2i, hi: Vector2i) -> Dictionary:
	var size := (hi - lo + Vector2i.ONE) * T
	var own := {}
	for c: Vector2i in cells:
		own[c] = true
	var art := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var seeds := Image.create(size.x, size.y, false, Image.FORMAT_L8)     # 255: a pixel of the object's own cells
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			var cell := Vector2i(x, y)
			var mine := own.has(cell)
			for l in _layers:
				var tl: TileMapLayer = l[0]
				var src := tl.get_cell_source_id(cell)
				if src < 0:
					continue
				if not mine and not l[1]:
					continue                                 # the wall row beside the object is never part of it
				var ac := tl.get_cell_atlas_coords(cell)
				var tile := _tile_image(src).get_region(Rect2i(ac * T, Vector2i(T, T)))
				if not mine and _opaque(tile):
					continue                                 # a full tile beside it is a floor or a wall, not its art
				var at := (cell - lo) * T
				art.blend_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(T, T)), at)
				if mine:
					for py in T:
						for px in T:
							if tile.get_pixel(px, py).a > 0.0:
								seeds.set_pixel(at.x + px, at.y + py, Color.WHITE)
	# the object: the drawn pixels joined (4-way) to those of its own cells
	var mask := PackedByteArray()
	mask.resize(size.x * size.y)
	var stack: Array[int] = []
	for py in size.y:
		for px in size.x:
			if seeds.get_pixel(px, py).r > 0.5:
				var i := py * size.x + px
				mask[i] = 1
				stack.append(i)
	if stack.is_empty():
		return {}
	while not stack.is_empty():
		var i: int = stack.pop_back()
		var px := i % size.x
		var py := i / size.x
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := Vector2i(px, py) + d
			if q.x < 0 or q.y < 0 or q.x >= size.x or q.y >= size.y:
				continue
			var j := q.y * size.x + q.x
			if mask[j] == 0 and art.get_pixel(q.x, q.y).a > 0.0:
				mask[j] = 1
				stack.append(j)
	return {"tex": ImageTexture.create_from_image(_glow(mask, size)), "origin": Vector2(lo * T) - Vector2(2, 2)}


## The glow round a shape (`mask`: 1 inside, row by row, `size` wide and high): solid at distance 1 from it (8-way), faint
## (0.4) at distance 2, in an image two pixels wider on each side; nothing over the shape itself.
static func _glow(mask: PackedByteArray, size: Vector2i) -> Image:
	var pad := 2
	var out := Image.create(size.x + 2 * pad, size.y + 2 * pad, false, Image.FORMAT_RGBA8)
	for oy in out.get_height():
		for ox in out.get_width():
			var px := ox - pad
			var py := oy - pad
			if px >= 0 and py >= 0 and px < size.x and py < size.y and mask[py * size.x + px] == 1:
				continue
			var near := 9
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var qx := px + dx
					var qy := py + dy
					if qx >= 0 and qy >= 0 and qx < size.x and qy < size.y and mask[qy * size.x + qx] == 1:
						near = mini(near, maxi(absi(dx), absi(dy)))
			if near == 1:
				out.set_pixel(ox, oy, Color(1, 1, 1, 1))
			elif near == 2:
				out.set_pixel(ox, oy, Color(1, 1, 1, 0.4))
	return out


## A sprite's outline: its own pixels are the shape.
func _sprite_outline(sh: Dictionary) -> Dictionary:
	var tex: Texture2D = sh.get("tex")
	if tex == null:
		return {}
	var key := "%s@%s" % [tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id()), sh.at]
	if cache.has(key):
		return cache[key]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var mask := PackedByteArray()
	mask.resize(img.get_width() * img.get_height())
	for py in img.get_height():
		for px in img.get_width():
			if img.get_pixel(px, py).a > 0.0:
				mask[py * img.get_width() + px] = 1
	var o := {"tex": ImageTexture.create_from_image(_glow(mask, img.get_size())), "origin": Vector2(sh.at) - Vector2(2, 2)}
	if cache.size() >= CACHE_MAX:
		cache.clear()
	cache[key] = o
	return o


static func _opaque(tile: Image) -> bool:
	for py in T:
		for px in T:
			if tile.get_pixel(px, py).a < 1.0:
				return false
	return true
