class_name AerialMap
extends RefCounted
## B25R1-025 (owner 2026-11-05, docs/directives/2026-11-05_b25r1_aerial_maps.md): the aerial pictures the Region and Village
## maps draw, made from the player's own generated world with the game's own tile art, never from a stored flyover.
##
## How: a chunk's picture is composed on the CPU, cell by cell, from the very tile values the world view draws there
## (OverworldView: the chunk's ground, roads (road_tile), objects, the settlements' and landmarks' building stamps, the
## homesteads; MapView: the village's own layers as they stand, the player's buildings included; CropView's plants; every tree
## as TreeView dresses it), each tile shrunk once to LO or HI pixels a side by an alpha-weighted box filter. Nothing is drawn by
## the GPU and no chunk view is built, so it costs a few milliseconds a chunk, not the flyover's camera passes.
##  - LO (2 px a tile): the whole region, in pages of PAGE x PAGE chunks (RGBA, transparent where unexplored). A chunk is
##    drawn once when the player explores it (Atlas.note_position, picked up by `pump` in the background) and again only when
##    its signature changes (`signatures`: the ways worn or paved, trees felled or planted, boulders broken, flowers picked,
##    homesteads built in it; the village's buildings, trees and fields; the seed and the generation).
##  - HI (8 px a tile): close views (the Village map, the Region map zoomed in), chunk by chunk on demand, at most HI_KEEP
##    kept (least recently used dropped), each a texture only (no CPU copy).
## Discovery: explored chunks (Atlas.explored) and the home village are drawn; owner requirement 2026-11-05: every settlement's
## own ground (its plan rect) is drawn from the first day, wherever the player has been; the rest of the country stays dark
## until explored. The settlements' chunks are generated and drawn once, at the start, on a worker thread with a private
## Overworld of the same seed (start_sites), never on the main thread during play; their pictures are masked to the
## settlements' rects until the chunk is explored.
## Drawing only: nothing here changes the world. One per world (`of`).

const LO := 2
const HI := 8
const PAGE := 4                     # chunks a LO page side (128 tiles, 256 px)
const HI_KEEP := 36
const HI_VIEW := 30                 # close pictures a view asks for at most (the nearest its middle), so they never churn
const T := 16

static var _inst: AerialMap = null

var main
var world: World
var ow: Overworld
var _atlas: Array = []             # the tile atlases (MapView.sources) as RGBA8 images, loaded while a map is open (release_art)
var _cols: Array[int] = []
var allow_load := true              # false during play: a chunk needing art not yet shrunk waits for a map to open
var _missing := false
var _ovv: OverworldView = null      # the worker's private view (road tiles, building looks) bound to its own Overworld
const EXPLORED_SALT := 0x5a17e1d    # in a chunk's signature once explored (its picture is then no longer masked)
# the settlements' ground, drawn on a worker thread at the start (start_sites)
var sites_state := ""               # "" not started, "running", "done"
var site_total := 0
var site_done := 0                  # (written by the worker)
var site_usec := 0                  # the worker's time
var site_start_usec := 0            # main-thread time spent starting it (the atlases read, the trees' art shrunk)
var _site_thread: Thread
var _site_mutex := Mutex.new()
var _site_out: Array = []           # [chunk, Image] handed over by the worker
var _site_cancel := false
var _worker: AerialMap
var _pal := {}                      # px a tile -> {tile value -> Image (k x k) or null (clear)}
var _spr := {}                      # px a tile -> {art file -> [Image, scale]}
var _crops: Image
var lo_sig := {}                    # chunk -> the signature its LO picture was drawn with
var pages := {}                     # page -> {img: Image, tex: ImageTexture, dirty: bool}
var hi := {}                        # chunk -> {tex: ImageTexture, sig: int, use: int}
var _use := 0
var queue: Array[Vector2i] = []     # LO chunks waiting to be drawn
var hi_queue: Array[Vector2i] = []
var _sigs := {}                     # chunk -> signature (signatures(), refreshed by `refresh`)
var _sig_base := 0
var _explored_seen := -1
var _vcells := {}                   # village layer cells, per compose batch (see _village_layers)
var _vcells_frame := -1
# measurements (tests and the report)
var lo_drawn := 0
var hi_drawn := 0
var lo_usec := 0
var hi_usec := 0
var gen_usec := 0
var waited_gen := 0                 # chunks passed over during play: not generated (no generation then)
var waited_art := 0                 # ... or needing art not shrunk yet
var _needs_art := {}


## The aerial maps of `m`'s world, made on first need and kept while the world is the same.
static func of(m) -> AerialMap:
	if _inst == null or _inst.world != m.world or _inst.main != m:
		if _inst != null:
			_inst.stop_sites()
		_inst = AerialMap.new()
		_inst._setup(m)
	return _inst


static func drop() -> void:
	if _inst != null:
		_inst.stop_sites()
	_inst = null


func _setup(m) -> void:
	main = m
	world = m.world
	ow = world.map.overworld
	var view: MapView = m.view
	for k in view.sources.size():
		_atlas.append(null)
		_cols.append(int(view.columns[k]))
	var ci: Image = load("res://assets/tiles/crops.png").get_image()
	if ci.is_compressed():
		ci.decompress()
	ci.convert(Image.FORMAT_RGBA8)
	_crops = ci
	_sig_base = hash([ow.seed, ow.gen])


# ------------------------------------------------------------------ art, shrunk -----------------
## An atlas's image (MapView.sources), loaded on first need; null while loading is not allowed (play: see allow_load).
func _atlas_img(a: int) -> Image:
	if _atlas[a] == null:
		if not allow_load:
			return null
		var tex: Texture2D = main.view.sources[a].texture
		var im: Image = tex.get_image() if tex != null else null
		if im == null:
			im = Image.create(T, T, false, Image.FORMAT_RGBA8)
		if im.is_compressed():
			im.decompress()
		im.convert(Image.FORMAT_RGBA8)
		_atlas[a] = im
	return _atlas[a]


## Let go of the atlases (tens of MB): what was shrunk from them is kept. Called as a map closes.
func release_art() -> void:
	for a in _atlas.size():
		_atlas[a] = null


## A tile shrunk to k x k: each pixel the alpha-weighted mean of its (16/k)^2 source pixels; null when the tile is clear.
## Both sizes are made at once (so the atlas is needed once a tile). With loading not allowed and the atlas not at hand,
## null and `_missing` set (not remembered).
func tile(v: int, k: int) -> Image:
	var pal: Dictionary = _pal.get(k, {})
	if pal.has(v):
		return pal[v]
	var a := v / 100000
	if a < 0 or a >= _atlas.size():
		for kk in [LO, HI]:
			_pal_of(kk)[v] = null
		return null
	var src := _atlas_img(a)
	if src == null:
		_missing = true
		return null
	var t := v % 100000
	var cols := _cols[a]
	var r := Rect2i((t % cols) * T, (t / cols) * T, T, T)
	var region: Image = src.get_region(r) if r.end.x <= src.get_width() and r.end.y <= src.get_height() else null
	for kk in [LO, HI]:
		_pal_of(kk)[v] = shrink(region, T / kk) if region != null else null
	return _pal[k][v]


func _pal_of(k: int) -> Dictionary:
	if not _pal.has(k):
		_pal[k] = {}
	return _pal[k]


## `img` shrunk by an integer factor `f` (alpha-weighted box filter); null if every pixel is clear.
static func shrink(img: Image, f: int) -> Image:
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width() / f
	var h := img.get_height() / f
	if w < 1 or h < 1:
		return null
	var src := img.get_data()
	var sw := img.get_width()
	var out := PackedByteArray()
	out.resize(w * h * 4)
	var any := false
	var n := float(f * f)
	for y in h:
		for x in w:
			var r := 0.0
			var g := 0.0
			var b := 0.0
			var al := 0.0
			for dy in f:
				var row := ((y * f + dy) * sw + x * f) * 4
				for dx in f:
					var q := row + dx * 4
					var aa := float(src[q + 3])
					r += src[q] * aa
					g += src[q + 1] * aa
					b += src[q + 2] * aa
					al += aa
			var o := (y * w + x) * 4
			if al > 0.0:
				out[o] = int(r / al)
				out[o + 1] = int(g / al)
				out[o + 2] = int(b / al)
				out[o + 3] = int(al / n)
				any = any or out[o + 3] > 8
	if not any:
		return null
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out)


## A tree's sprite file and its top-left corner in world pixels, as TreeView dresses it (no cut marks, no fruit); [] for none.
static func tree_sprite(rec: Dictionary) -> Array:
	var state := str(rec.get("state", "grown"))
	if state == "cleared":
		return []
	var v: Dictionary = Trees.variant(str(rec.get("species", "oak_summer")))
	var file := ""
	var pivot := Vector2.ZERO
	var off := Vector2.ZERO
	match state:
		"stump":
			file = v.stump.file
			pivot = Vector2(v.pivot[0], v.pivot[1])
			off = Vector2(v.stump.off[0], v.stump.off[1])
		"sapling":
			file = v.sapling.file
			pivot = Vector2(v.sapling.pivot[0], v.sapling.pivot[1])
		_:
			var s: Dictionary = v.sizes.get(state if state != "grown" else "mature", v.sizes.mature)
			file = s.file
			pivot = Vector2(s.pivot[0], s.pivot[1])
	return [file, TreeView.base_of(rec) + off - pivot]


## A sprite's art shrunk to k px a tile ([Image or null]).
func sprite(file: String, k: int) -> Image:
	var d: Dictionary = _spr.get(k, {})
	if d.is_empty():
		_spr[k] = d
	if d.has(file):
		return d[file]
	var tex := Trees.texture(file)
	var out: Image = null
	if tex != null:
		var im := tex.get_image()
		if im != null:
			if im.is_compressed():
				im.decompress()
			var f := T / k
			var pw := ceili(im.get_width() / float(f)) * f
			var ph := ceili(im.get_height() / float(f)) * f
			var pad := Image.create(pw, ph, false, Image.FORMAT_RGBA8)
			im.convert(Image.FORMAT_RGBA8)
			pad.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i.ZERO)
			out = shrink(pad, f)
	d[file] = out
	return out


# ------------------------------------------------------------------ composing ------------------
## The picture of chunk `cc` at k px a tile: what the world view draws there, ground to roofs; null when it needs art that
## may not be loaded now (allow_load false).
func compose(cc: Vector2i, k: int, mask := false) -> Image:
	_missing = false
	var t0 := Time.get_ticks_usec()
	var n := Overworld.CHUNK
	var box := Rect2i(cc * n, Vector2i(n, n))
	var img := Image.create(n * k, n * k, false, Image.FORMAT_RGBA8)
	var village := ow.village
	var all_village := village.encloses(box)
	var ch: Overworld.Chunk = null
	if not all_village:
		var had := ow.cache.has(cc)
		ch = ow.get_chunk(cc)
		if not had:
			gen_usec += Time.get_ticks_usec() - t0
	var ovv: OverworldView = _ovv if _ovv != null else main.ow_view
	var lanes := RegionRoads.lane_cells(ow)
	var tops: Array = []            # [cell, value] drawn over the trees (roofs)
	var trees: Array = []           # tree records
	if ch != null:
		var live := false
		for y in n:
			for x in n:
				var i := y * n + x
				var gv := ch.ground[i]
				if gv < 0:
					continue
				if ch.water[i] != 0 and ovv != null:
					gv = ovv.water_value(gv, live)
				_put(img, x, y, k, gv, true)
		for y in n:
			for x in n:
				var i := y * n + x
				if ch.ground[i] < 0:
					continue
				var cell := Vector2i(box.position.x + x, box.position.y + y)
				if ch.path[i] >= 0 or lanes.has(cell) or ow.road_state.has(cell):
					var pv: int = ovv.road_tile(cell, ch.path[i]) if ovv != null else ch.path[i]
					if pv >= 0:
						_put(img, x, y, k, pv, false)
				if ch.deco[i] >= 0 and not ow.rock_gone(cell) and not ow.flower_gone(cell):
					var dv: int = ch.deco[i]
					if dv == int(ow.tiles.rock) and ResourceNodes.boulder_small(cell) and _atlas.size() > 3:
						dv = MapView.SMALL_BOULDER_TILE
					_put(img, x, y, k, dv, false)
		_stamps(img, box, k, tops)
		_homes(img, box, k, tops)
		trees = _chunk_trees(ch, cc)
	# the canopies of the neighbours' trees that reach over the seam (when those chunks are at hand: no generation for this)
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
		var nc: Vector2i = cc + d
		if not ow.cache.has(nc):
			continue
		var nch: Overworld.Chunk = ow.cache[nc]
		var near := false
		for q in range(0, nch.trees.size(), 3):
			if nch.trees[q + 1] - box.end.y < 4 and nch.trees[q] - box.end.x < 3 and box.position.x - nch.trees[q] < 4:
				near = true
				break
		if not near:
			continue
		for t in _chunk_trees(nch, nc):
			if int(t.y) - box.end.y < 4 and int(t.x) - box.end.x < 3 and box.position.x - int(t.x) < 4:
				trees.append(t)
	if village.intersects(box):
		_village(img, box, k, tops, trees)
	# the trees, north to south (a southern tree's canopy over a northern one's trunk), then what is drawn over them
	trees.sort_custom(func(a, b): return int(a.y) < int(b.y) or (int(a.y) == int(b.y) and int(a.x) < int(b.x)))
	for t in trees:
		var sp := tree_sprite(t)
		if sp.is_empty():
			continue
		var im := sprite(str(sp[0]), k)
		if im == null:
			continue
		var at: Vector2 = (sp[1] as Vector2) / float(T) * k - Vector2(box.position * k)
		img.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(at.round()))
	for e in tops:
		_put(img, e[0].x - box.position.x, e[0].y - box.position.y, k, e[1], false)
	if _missing:
		return null                         # (art not at hand during play: drawn when a map opens)
	if mask:
		img = _mask_sites(img, box, k)
	if k == LO:
		lo_usec += Time.get_ticks_usec() - t0
		lo_drawn += 1
	else:
		hi_usec += Time.get_ticks_usec() - t0
		hi_drawn += 1
	return img


## Only the settlements' own ground of a picture (their plan rects), the rest clear: a chunk not explored yet.
func _mask_sites(img: Image, box: Rect2i, k: int) -> Image:
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	for st in ow.sites:
		var r := (st.rect as Rect2i).intersection(box)
		if r.has_area():
			out.blit_rect(img, Rect2i((r.position - box.position) * k, r.size * k), (r.position - box.position) * k)
	return out


## Is the chunk drawn masked (not explored, not the village's: only its settlements' ground)?
func masked(cc: Vector2i) -> bool:
	return not world.player.explored.has(cc) and not _box(cc).intersects(ow.village)


static func _box(cc: Vector2i) -> Rect2i:
	return Rect2i(cc * Overworld.CHUNK, Vector2i(Overworld.CHUNK, Overworld.CHUNK))


## The chunks with settlement ground, outside the village.
func site_chunks() -> Array:
	var seen := {}
	var out := []
	for st in ow.sites:
		for cc in _chunks_of(st.rect):
			if not seen.has(cc) and not _box(cc).intersects(ow.village):
				seen[cc] = true
				out.append(cc)
	return out


func _put(img: Image, x: int, y: int, k: int, v: int, opaque: bool) -> void:
	var pal: Dictionary = _pal.get(k, {})
	var im: Image = pal[v] if pal.has(v) else tile(v, k)
	if im == null:
		return
	if opaque:
		img.blit_rect(im, Rect2i(0, 0, k, k), Vector2i(x * k, y * k))
	else:
		img.blend_rect(im, Rect2i(0, 0, k, k), Vector2i(x * k, y * k))


static func _layer_rank(a: String) -> int:
	return 0 if a.begins_with("ground") else 1 if a.begins_with("path") else 2 if a.begins_with("below") else 3


## The settlements' and the country landmarks' buildings and yard pieces in `box` (OverworldView._draw_site_buildings).
func _stamps(img: Image, box: Rect2i, k: int, tops: Array) -> void:
	var ovv: OverworldView = _ovv if _ovv != null else main.ow_view
	for st in ow.sites + ow.structures:
		if not (st.rect as Rect2i).intersects(box):
			continue
		for sl in st.slots + st.get("props", []):
			var r: Rect2i = sl.rect
			if not r.intersects(box):
				continue
			var stamp: Dictionary = ow.stamps.get(Overworld.slot_stamp(sl), ow.stamps.house)
			var swap: Dictionary = ovv._look_swap(str(sl.get("look", ""))) if ovv != null else {}
			_stamp_cells(img, box, k, tops, stamp, r.position, swap)


func _stamp_cells(img: Image, box: Rect2i, k: int, tops: Array, stamp: Dictionary, at: Vector2i, swap: Dictionary) -> void:
	var names: Array = (stamp.layers as Dictionary).keys()
	names.sort_custom(func(a: String, b: String) -> bool:
		return _layer_rank(a) < _layer_rank(b) or (_layer_rank(a) == _layer_rank(b) and a < b))
	var r := Rect2i(at, Vector2i(int(stamp.w), int(stamp.h)))
	var clip := r.intersection(box)
	for lname in names:
		var above := str(lname).begins_with("above")
		var cells: Array = stamp.layers[lname]
		for j in range(clip.position.y - r.position.y, clip.end.y - r.position.y):
			for i in range(clip.position.x - r.position.x, clip.end.x - r.position.x):
				var v := int(cells[j * int(stamp.w) + i])
				if not swap.is_empty():
					v = int(swap.get(str(v), v))
				if v < 0:
					continue
				var cell := r.position + Vector2i(i, j)
				if above:
					tops.append([cell, v])
				else:
					_put(img, cell.x - box.position.x, cell.y - box.position.y, k, v, false)


## The homesteads (Overworld.homes) in `box` (OverworldView._draw_homes).
func _homes(img: Image, box: Rect2i, k: int, tops: Array) -> void:
	for hm in ow.homes:
		var r: Rect2i = hm.get("rect", Rect2i())
		if hm.has("layers"):
			for cells: Dictionary in hm.layers:
				for cell: Vector2i in cells:
					if box.has_point(cell):
						_put(img, cell.x - box.position.x, cell.y - box.position.y, k, int(cells[cell]), false)
			continue
		if not r.grow(1).intersects(box):
			continue
		if str(hm.stamp) == "":
			var c := Vector2i(hm.frame)
			if box.has_point(c):
				_put(img, c.x - box.position.x, c.y - box.position.y, k, int(hm.tile), false)
			continue
		_stamp_cells(img, box, k, tops, ow.stamps.get(str(hm.stamp), ow.stamps.house), r.position, {})


## A chunk's trees as the view draws them (Overworld.chunk_trees), from the chunk in hand.
func _chunk_trees(ch: Overworld.Chunk, cc: Vector2i) -> Array:
	var out := []
	for q in range(0, ch.trees.size(), 3):
		var cell := Vector2i(ch.trees[q], ch.trees[q + 1])
		var t: Dictionary = ow.changes.get(cell, {})
		if t.is_empty():
			var kind := ch.trees[q + 2]
			if kind < 0 or kind >= (ow.tiles.trees as Array).size():
				continue
			var i := (cell.y - cc.y * Overworld.CHUNK) * Overworld.CHUNK + cell.x - cc.x * Overworld.CHUNK
			var snow := i >= 0 and i < ch.snow.size() and ch.snow[i] == 2
			var kd: Dictionary = ow.tiles.trees[kind]
			var born := Trees.initial_born(cell.x, cell.y)
			t = {"x": cell.x, "y": cell.y, "species": Trees.species_for(str(kd.group), cell.x, cell.y, snow),
					"state": Trees.stage_at(ow.clock - born)}
		out.append(t)
	for c: Vector2i in ow.changes:
		if Overworld.chunk_of(c) == cc and ow.changes[c].get("planted", false):
			out.append(ow.changes[c])
	return out


## The village's own cells in `box`: its layers as the village view holds them now (MapView.tile_value: the player's
## buildings, frames and cleared cells included), its trees and the plants on its fields.
func _village(img: Image, box: Rect2i, k: int, tops: Array, trees: Array) -> void:
	var view: MapView = main.view
	var map: VillageMap = world.map
	var clip := box.intersection(ow.village)
	for lay in map.data.layers:
		var layer: TileMapLayer = view.layers.get(lay.name)
		if layer == null:
			continue
		var above := str(lay.z) == "above"
		for cell: Vector2i in _layer_cells(layer, view):
			if not clip.has_point(cell):
				continue
			var v := view.tile_value(layer, cell)
			if v < 0:
				continue
			if above:
				tops.append([cell, v])
			else:
				_put(img, cell.x - box.position.x, cell.y - box.position.y, k, v, false)
	var cv: CropView = main.crop_view
	if cv != null:
		var f := T / k
		for e in cv.shown:
			var cell := Vector2i(int(e[0]), int(e[1]))
			if clip.has_point(cell):
				var key := 900000 + int(e[2]) * 16 + int(e[3])
				var pal: Dictionary = _pal.get(k, {})
				if not pal.has(key):
					pal[key] = shrink(_crops.get_region(Rect2i(int(e[3]) * T, int(e[2]) * T, T, T)), f)
					_pal[k] = pal
				var im: Image = pal[key]
				if im != null:
					img.blend_rect(im, Rect2i(0, 0, k, k), (cell - box.position) * k)
	for t in world.trees:
		if clip.has_point(Vector2i(int(t.x), int(t.y))):
			trees.append(t)


## A village layer's used cells (and its sorted twin's), read once a frame.
func _layer_cells(layer: TileMapLayer, view: MapView) -> Array:
	var f := Engine.get_process_frames()
	if f != _vcells_frame:
		_vcells.clear()
		_vcells_frame = f
	if not _vcells.has(layer):
		var cells: Array = layer.get_used_cells()
		var twin: TileMapLayer = view.sorted_of.get(layer)
		if twin != null and view.roof_layers.has(layer):
			cells += twin.get_used_cells()
		_vcells[layer] = cells
	return _vcells[layer]


# ------------------------------------------------------------------ what changed ---------------
## Each chunk's signature (chunk -> int): the world's changes that alter what is drawn there. A chunk not listed has none
## (its signature is the base: the seed and the generation).
func signatures() -> Dictionary:
	var b := {}
	var day := int(ow.clock / 1440.0)
	for c: Vector2i in ow.road_state:
		_mix(b, Overworld.chunk_of(c), hash([c, RoadWear.visual(ow, c)]))
	for c: Vector2i in ow.changes:
		var t: Dictionary = ow.changes[c]
		_mix(b, Overworld.chunk_of(c), hash([c, str(t.get("state", "")), str(t.get("species", "")), day]))
	for c: Vector2i in ow.rock_changes:
		_mix(b, Overworld.chunk_of(c), hash([c, ow.rock_gone(c)]))
	for c: Vector2i in ow.plant_changes:
		_mix(b, Overworld.chunk_of(c), hash([c, ow.flower_gone(c)]))
	for hm in ow.homes:
		var r: Rect2i = hm.get("rect", Rect2i())
		var h := hash([str(hm.get("id", "")), str(hm.get("stamp", "")), int(hm.get("tile", -1)), r, hm.get("layers", []).size()])
		if hm.has("layers"):
			for cells: Dictionary in hm.layers:
				for cell: Vector2i in cells:
					_mix(b, Overworld.chunk_of(cell), hash([cell, cells[cell]]))
		elif r.has_area():
			for cc in _chunks_of(r.grow(1)):
				_mix(b, cc, h)
		elif hm.has("frame"):
			_mix(b, Overworld.chunk_of(Vector2i(hm.frame)), h)
	var vk := village_key()
	for cc in _chunks_of(ow.village):
		_mix(b, cc, vk)
	return b


func _mix(b: Dictionary, cc: Vector2i, h: int) -> void:
	b[cc] = int(b.get(cc, 0)) ^ h


## What the village's picture depends on beyond its generated map: the buildings, the trees, the fields' plants.
func village_key() -> int:
	var h := hash(world.buildings.keys())
	for id in world.buildings:
		var bd: Dictionary = world.buildings[id]
		h ^= hash([id, int(bd.get("x", 0)), int(bd.get("y", 0)), str(bd.get("type", ""))])
	for t in world.trees:
		h ^= hash([int(t.x), int(t.y), str(t.state)])
	var cv: CropView = main.crop_view
	if cv != null:
		h ^= hash(cv.shown)
	return h


static func _chunks_of(r: Rect2i) -> Array:
	var out := []
	var a := Overworld.chunk_of(r.position)
	var z := Overworld.chunk_of(r.end - Vector2i.ONE)
	for y in range(a.y, z.y + 1):
		for x in range(a.x, z.x + 1):
			out.append(Vector2i(x, y))
	return out


func sig(cc: Vector2i) -> int:
	return _sig_base ^ int(_sigs.get(cc, 0)) ^ (EXPLORED_SALT if world.player.explored.has(cc) else 0)


## May the map show this chunk: explored by the player, the home village's, or holding a settlement's ground (masked to it).
func shown(cc: Vector2i) -> bool:
	if world.player.explored.has(cc) or _box(cc).intersects(ow.village):
		return true
	for st in ow.sites:
		if (st.rect as Rect2i).intersects(_box(cc)):
			return true
	return false


# ------------------------------------------------------------------ the LO pages ---------------
static func page_of(cc: Vector2i) -> Vector2i:
	return Vector2i(Overworld.fdiv(cc.x, PAGE), Overworld.fdiv(cc.y, PAGE))


## Check every shown chunk against the world (on opening a map): the changed and the new ones are queued, nearest the
## player first.
func refresh() -> void:
	_sigs = signatures()
	var want: Array[Vector2i] = []
	for cc: Vector2i in world.player.explored:
		if lo_sig.get(cc, null) != sig(cc):
			want.append(cc)
	for cc in _chunks_of(ow.village):
		if lo_sig.get(cc, null) != sig(cc) and not world.player.explored.has(cc):
			want.append(cc)
	if sites_state == "done":                   # (while the worker draws them, they are its)
		for cc in site_chunks():
			if lo_sig.get(cc, null) != sig(cc) and not world.player.explored.has(cc):
				want.append(cc)
	var pc := Overworld.chunk_of(Vector2i(world.player.pos.floor()))
	want.sort_custom(func(a: Vector2i, b: Vector2i): return (a - pc).length_squared() < (b - pc).length_squared())
	queue = want
	_explored_seen = world.player.explored.size()
	for cc: Vector2i in hi.keys():
		if hi[cc].sig != sig(cc):
			hi.erase(cc)


## Newly explored chunks join the queue (each frame, cheaply: only when the explored count changed).
func notice() -> void:
	var n := world.player.explored.size()
	if n == _explored_seen:
		return
	_explored_seen = n
	if _sigs.is_empty():
		_sigs = signatures()
	for cc: Vector2i in world.player.explored:
		if lo_sig.get(cc, null) != sig(cc) and not queue.has(cc):
			queue.append(cc)                         # (new, or a settlement's chunk drawn masked until now)


## Draw queued LO chunks for up to `budget_usec`; with `generate` false a chunk not in the overworld's cache waits (no
## generation stalls play): it is drawn when a map is open. At most `most` drawn. Returns how many are still waiting.
func pump(budget_usec: int, generate: bool, most := 1 << 30) -> int:
	var t0 := Time.get_ticks_usec()
	var i := 0
	var done := 0
	while i < queue.size() and Time.get_ticks_usec() - t0 < budget_usec and done < most:
		var cc: Vector2i = queue[i]
		if not generate and not ow.cache.has(cc) and not ow.village.encloses(Rect2i(cc * Overworld.CHUNK, Vector2i(Overworld.CHUNK, Overworld.CHUNK))):
			waited_gen += 1
			i += 1
			continue
		if not allow_load and _needs_art.has(cc):
			i += 1                               # (it needs art not shrunk yet: drawn when a map is open)
			continue
		queue.remove_at(i)
		if generate and not ow.cache.has(cc):
			_keep_near()
		if draw_lo(cc):
			done += 1
			_needs_art.erase(cc)
		else:
			_needs_art[cc] = true
			waited_art += 1
			queue.insert(i, cc)
			i += 1
	return queue.size()


## Keep the chunks round the player the overworld's most recently used, so drawing far chunks does not push them out of
## its cache (the world would build them again after the map closes).
func _keep_near() -> void:
	var pc := Overworld.chunk_of(Vector2i(world.player.pos.floor()))
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if ow.cache.has(pc + Vector2i(dx, dy)):
				ow.get_chunk(pc + Vector2i(dx, dy))


func draw_lo(cc: Vector2i) -> bool:
	var img := compose(cc, LO, masked(cc))
	if img == null:
		return false
	_place(cc, img)
	return true


func _place(cc: Vector2i, img: Image) -> void:
	var pg := page_of(cc)
	var p: Dictionary = pages.get(pg, {})
	if p.is_empty():
		var side := PAGE * Overworld.CHUNK * LO
		var pi := Image.create(side, side, false, Image.FORMAT_RGBA8)
		p = {"img": pi, "tex": null, "dirty": true}
		pages[pg] = p
	var at := (cc - pg * PAGE) * Overworld.CHUNK * LO
	(p.img as Image).blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
	p.dirty = true
	lo_sig[cc] = sig(cc)


## A page's texture, uploaded again when a chunk in it was drawn.
func page_tex(pg: Vector2i) -> ImageTexture:
	var p: Dictionary = pages.get(pg, {})
	if p.is_empty():
		return null
	if p.dirty:
		var up: Image = (p.img as Image).duplicate()
		up.generate_mipmaps()                       # (the Region map minifies them when zoomed out)
		if p.tex == null:
			p.tex = ImageTexture.create_from_image(up)
		else:
			(p.tex as ImageTexture).update(up)
		p.dirty = false
	return p.tex


## The tiles a page covers.
static func page_rect(pg: Vector2i) -> Rect2:
	var s := PAGE * Overworld.CHUNK
	return Rect2(Vector2(pg * s), Vector2(s, s))


# ------------------------------------------------------------------ HI chunks ------------------
## The close picture of a chunk if drawn and current, else null (and it is queued).
func hi_tex(cc: Vector2i) -> ImageTexture:
	var e: Dictionary = hi.get(cc, {})
	if not e.is_empty() and e.sig == sig(cc):
		_use += 1
		e.use = _use
		return e.tex
	if not hi_queue.has(cc):
		hi_queue.append(cc)
	return null


## Draw queued HI chunks for up to `budget_usec` (at least one); the least recently used beyond HI_KEEP are dropped.
func pump_hi(budget_usec: int) -> int:
	var t0 := Time.get_ticks_usec()
	while not hi_queue.is_empty() and (Time.get_ticks_usec() - t0 < budget_usec):
		var cc: Vector2i = hi_queue.pop_front()
		if not shown(cc):
			continue
		if not ow.cache.has(cc):
			_keep_near()
		var img := compose(cc, HI, masked(cc))
		if img == null:
			continue
		img.generate_mipmaps()                   # (the maps minify them, filtered, below 8 px a tile on screen)
		_use += 1
		hi[cc] = {"tex": ImageTexture.create_from_image(img), "sig": sig(cc), "use": _use}
	while hi.size() > HI_KEEP:
		var old := Vector2i.ZERO
		var best := 1 << 60
		for k: Vector2i in hi:
			if int(hi[k].use) < best:
				best = int(hi[k].use)
				old = k
		hi.erase(old)
	return hi_queue.size()


## Forget the HI requests not seen this frame (the view moved on).
func hi_trim(keep: Dictionary) -> void:
	hi_queue = hi_queue.filter(func(c): return keep.has(c))


## Bytes held: the LO pages (CPU image, and the texture with its mipmaps) and the HI textures (with their mipmaps).
func bytes() -> Dictionary:
	var side := PAGE * Overworld.CHUNK * LO
	var hs := Overworld.CHUNK * HI
	return {"pages": pages.size(), "lo_bytes": pages.size() * side * side * 4 * 7 / 3, "hi": hi.size(), "hi_bytes": hi.size() * hs * hs * 4 * 4 / 3}


# ------------------------------------------------------------------ the settlements, at the start --------------
## Owner requirement 2026-11-05: every settlement's ground is on the Region map from the first day. Its ~200 chunks cost
## 25-30 ms each to generate here, too much for the main thread during play, so a worker thread makes a private Overworld of
## the same seed (Overworld.create, about 1.5 s here) and generates and composes them there (LO, masked to the settlements'
## rects); the main thread only places the finished pictures (integrate_sites). The worker shares no mutable state with the
## game: its own Overworld, its own view for road tiles and building looks, its own palette; the atlases and the trees'
## shrunk art are read-only images prepared here first. Started once a world (Main._aerial_step, or a map opening first).
func start_sites() -> void:
	if sites_state != "":
		return
	var t0 := Time.get_ticks_usec()
	var todo: Array = []
	for cc in site_chunks():
		if lo_sig.get(cc, null) == null:
			todo.append(cc)
	site_total = todo.size()
	if todo.is_empty():
		sites_state = "done"
		return
	# what the worker reads, made here: every atlas, every tree picture shrunk, the static tables warmed
	var keep_load := allow_load
	allow_load = true
	for a in _atlas.size():
		_atlas_img(a)
	allow_load = keep_load
	for vk in (Trees.art().variants as Dictionary):
		var v: Dictionary = Trees.art().variants[vk]
		var files: Array = []
		for key in ["stump", "sapling", "fruit"]:
			if v.has(key):
				files.append(str(v[key].file))
		for sz in (v.get("sizes", {}) as Dictionary):
			files.append(str(v.sizes[sz].file))
		for f in files:
			sprite(f, LO)
	Trees.stage_at(0.0)
	Overworld.water_cfg()
	var wk := AerialMap.new()
	wk.main = main
	wk.world = world
	wk._atlas = _atlas.duplicate()
	wk._cols = _cols
	wk._crops = _crops
	wk.allow_load = false
	wk._spr = {LO: (_spr.get(LO, {}) as Dictionary).duplicate()}
	var v := OverworldView.new()
	var src: OverworldView = main.ow_view
	v.sources = src.sources
	v.columns = src.columns
	v._dirt_bits = src._dirt_bits
	v._look_swap("_")                            # (reads its building looks now, not on the worker)
	wk._ovv = v
	_worker = wk
	sites_state = "running"
	_site_cancel = false
	var clock: float = ow.clock
	var seed_v: int = ow.seed
	var vmap: VillageMap = world.map
	_site_thread = Thread.new()
	_site_thread.start(_site_work.bind(wk, todo, seed_v, vmap, clock), Thread.PRIORITY_LOW)
	site_start_usec = Time.get_ticks_usec() - t0


## The worker: a private Overworld, then each settlement chunk composed (2 px a tile, masked) and handed over.
func _site_work(wk: AerialMap, todo: Array, seed_v: int, vmap: VillageMap, clock: float) -> void:
	var t0 := Time.get_ticks_usec()
	var o := Overworld.create(seed_v, vmap)
	o.clock = clock
	wk.ow = o
	wk._ovv.overworld = o
	for cc: Vector2i in todo:
		if _site_cancel:
			break
		var img := wk.compose(cc, LO, true)
		_site_mutex.lock()
		_site_out.append([cc, img])
		_site_mutex.unlock()
		site_done += 1
	site_usec = Time.get_ticks_usec() - t0


## Place what the worker has finished (cheap: a blit each), and once it is done, join it and keep its shrunk tiles. A
## chunk the main thread has drawn meanwhile (explored), or one changed in the player's world (its signature not the base
## one), is left to the main thread.
func integrate_sites() -> void:
	if sites_state != "running":
		return
	_site_mutex.lock()
	var got := _site_out
	_site_out = []
	_site_mutex.unlock()
	for e in got:
		var cc: Vector2i = e[0]
		var img: Image = e[1]
		if img == null or not masked(cc) or int(_sigs.get(cc, 0)) != 0 or lo_sig.get(cc, null) == sig(cc):
			continue
		_place(cc, img)
	if _site_thread != null and not _site_thread.is_alive():
		_site_thread.wait_to_finish()
		_site_thread = null
		_finish_sites()


func _finish_sites() -> void:
	sites_state = "done"
	if _worker != null:
		for k in [LO, HI]:
			var mine := _pal_of(k)
			var theirs: Dictionary = _worker._pal.get(k, {})
			for v in theirs:
				if not mine.has(v):
					mine[v] = theirs[v]
		_worker._ovv.free()
		_worker = null
	if main.ui == null or not main.ui.is_open("map"):
		release_art()                            # (the atlases were read for the worker; a map open keeps them)


## Stop the worker (a world left: a new game, a load, quitting).
func stop_sites() -> void:
	_site_cancel = true
	if _site_thread != null:
		_site_thread.wait_to_finish()
		_site_thread = null
	if _worker != null and is_instance_valid(_worker._ovv):
		_worker._ovv.free()
	_worker = null
