class_name OverworldView
extends MapView
## Draws the overworld (Overworld) as a ring of chunks round the camera. Each loaded chunk is a node
## with four TileMapLayers: ground, road, objects (tree trunks, rocks, flowers, bushes) and tree tops
## (drawn over the characters, faded by a CanopyFade while the player stands behind one). Chunks
## are built a few per frame as the camera moves, and freed once they are more than one chunk
## beyond the ring, so what is held is bounded whatever distance is walked. The village's own
## MapView draws the village; the cells inside it are not drawn here. The tiles, the atlases and
## the TileSet are the village MapView's (the art is the same packs).

const BUILD_PER_FRAME := 3

var overworld: Overworld
var radius := 2                       # chunks beyond the camera's chunk that are kept drawn
var chunks := {}                      # chunk coordinates -> {root, ground, path, objects, tops}
var canopy: CanopyFade
var tree_sink: TreeView               # draws the chunks' trees as sprites (set by Main); the tiles here are ground, roads and decoration
var tops_set := {}                    # canopy top tile -> true
var _center := Vector2i(1 << 30, 1 << 30)
var _pending: Array[Vector2i] = []
var _works_seen := -1                 # B14-07: Overworld.works_version last drawn
var _works_tex := {}                  # way kind ("steps_ns", "stairs_ew", ...) -> its 16 px tile (game/assets/terrain)
var _site_sorted_parent: Node2D       # the characters' y-sorted node (the village MapView's): where a site building's front wall is drawn
var _site_roofs := {}                 # the village's roof layer names (village.json "roof_layers")
var _road_seen := -1                  # B25R1-011: Overworld.road_rev last drawn
var _road_day := -1                   # the game day the loaded ways were last drawn for
var live_check: Callable              # B25R1-019: (chunk rect in tiles) -> whether its water animates; Main sets it (the presence query)
var _live_seen := -1                  # the presence version the loaded water was last drawn for
var _live := {}                       # chunk -> whether its water was drawn animated
var _dirt_bits := {}                  # B25R1-Q1: dirt path tile -> its connected sides (overworld_tiles.json dirt_path)


func setup(src: MapView, o: Overworld, load_radius: int) -> void:
	overworld = o
	radius = load_radius
	tileset = src.tileset
	sources = src.sources
	columns = src.columns
	animated = src.animated
	_site_sorted_parent = src._sorted_parent
	if src.map != null:
		for n in src.map.data.get("roof_layers", []):
			_site_roofs[str(n)] = true
	var pairs := []
	for k in o.tiles.trees:
		pairs.append([int(k.top), int(k.bottom)])
		tops_set[int(k.top)] = true
	for k in (o.tiles.dirt_path as Array).size():
		for t in o.tiles.dirt_path[k]:
			_dirt_bits[int(t)] = k
	canopy = CanopyFade.new()
	add_child(canopy)
	canopy.setup(self, pairs)


## Keep the chunks round `center` (tiles) drawn, building at most `budget` this call (a negative
## budget builds them all: a first view, a teleport), and fade canopies over `feet`.
func follow(center: Vector2, feet: Vector2, delta: float, budget := BUILD_PER_FRAME) -> void:
	var cc := Overworld.chunk_of(Vector2i(floori(center.x), floori(center.y)))
	if cc != _center:
		_center = cc
		_pending.clear()
		var want: Array = []
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var c := cc + Vector2i(dx, dy)
				if not chunks.has(c) and not overworld.chunk_in_village(c):
					want.append([dx * dx + dy * dy, c.y, c.x, c])
		want.sort()
		for w in want:
			_pending.append(w[3])
		for c: Vector2i in chunks.keys():
			if maxi(absi(c.x - cc.x), absi(c.y - cc.y)) > radius + 1:
				_free(c)
	var n := 0
	while not _pending.is_empty() and (budget < 0 or n < budget):
		var c: Vector2i = _pending.pop_front()
		if not chunks.has(c):
			_build(c)
			n += 1
	if budget < 0 and tree_sink != null:
		tree_sink.flush()
	_road_step()
	_live_step()
	if overworld.works_version != _works_seen:
		_works_seen = overworld.works_version
		for c: Vector2i in chunks:
			_draw_works(c)
	canopy.update(feet, delta)


## B14-07: the steps, stairs and walkways through a cliff's rim in a loaded chunk, each a 16 px tile over its cell, under
## the characters (drawn again whenever a way is made).
func _draw_works(cc: Vector2i) -> void:
	var c: Dictionary = chunks.get(cc, {})
	if c.is_empty():
		return
	var layer: Node2D = c.works
	for k in layer.get_children():
		k.queue_free()
	var cells: Array = overworld.works.keys().filter(func(w: Vector2i) -> bool: return Overworld.chunk_of(w) == cc)
	cells.sort()
	for cell: Vector2i in cells:
		var kind := str(overworld.works[cell])
		var low := 0
		if kind.begins_with("steps") and kind.length() == 8:       # "steps_ns" / "steps_ew" (the old "steps" has no run)
			# the tile's low side (its grass edge) faces the ground, not the top: steps_ns is drawn low side south, steps_ew low
			# side east; a cell with more steps on its low side takes the "_mid" tile, whose treads run on to the next cell
			low = _steps_low_side(cell, kind.ends_with("_ew"))
			var ahead: Vector2i = cell + (Vector2i(low, 0) if kind.ends_with("_ew") else Vector2i(0, low))
			if str(overworld.works.get(ahead, "")).begins_with("steps"):
				kind += "_mid"
		var file := kind + ".png"
		if kind.begins_with("steps") and not ResourceLoader.exists("res://assets/terrain/" + file):
			file = "steps.png"                  # an older way of unknown run keeps the first stand-in tile
		if not _works_tex.has(file):
			_works_tex[file] = load("res://assets/terrain/" + file) if ResourceLoader.exists("res://assets/terrain/" + file) else null
		if _works_tex[file] == null:
			continue
		var sp := Sprite2D.new()
		sp.texture = _works_tex[file]
		sp.centered = false
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.position = Vector2(cell * MapView.T)
		if low != 0:
			sp.flip_v = kind.begins_with("steps_ns") and low < 0
			sp.flip_h = kind.begins_with("steps_ew") and low < 0
		layer.add_child(sp)


## Which way along its run the ground lies from a steps cell: +1 (south or east) or -1 (north or west). Walk the way's cells
## (the same run) to either end; the end that is not a mountain top is the ground.
func _steps_low_side(cell: Vector2i, ew: bool) -> int:
	var axis := Vector2i(1, 0) if ew else Vector2i(0, 1)
	var ends := []
	for sgn in [1, -1]:
		var c: Vector2i = cell + axis * sgn
		while overworld.works.has(c) and str(overworld.works[c]).begins_with("steps") and absi(c.x - cell.x) + absi(c.y - cell.y) < 16:
			c += axis * sgn
		ends.append(overworld.is_top(c))
	return -1 if ends[0] and not ends[1] else 1   # ends[0] is the + end: a top there puts the ground at the - end


## B25R1-Q1 and B25R1-011: the tile a cell's way is drawn with, by its look now (RoadWear.visual: the generated type, worn in
## by footfall, faded, grown over, paved, damaged): -1 for grass. A generated dirt road keeps its generated dirt path tile
## `dirt` (-1 where the generator drew none); the rest come from the road tile sheet (MapView atlas 4) or the dirt path set,
## for the connected sides: the generated ones (from `dirt`), worn ways beside it, and a settlement's street beside stone.
## Drawing only: the cell, its walkability and the chunk data are unchanged.
func road_tile(cell: Vector2i, dirt: int) -> int:
	var look := RoadWear.visual(overworld, cell)
	if RegionRoads.lane_cells(overworld).has(cell):
		look = "stone" if look == "" else look
	if look == "":
		return -1
	if sources.size() <= 4:
		return dirt
	if overworld.is_bridge(cell) and sources.size() > WATER_ATLAS:
		return _bridge_tile(cell, look)
	var bits: int = int(_dirt_bits.get(dirt, 0)) if dirt >= 0 else 0
	var lanes := RegionRoads.lane_cells(overworld)
	for k in 4:
		var n: Vector2i = cell + [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][k]
		if overworld.road_state.has(n) and RoadWear.is_way(overworld, n):
			bits |= 1 << k                              # a way worn in beside it
		elif look.begins_with("stone") and (lanes.has(n) or (lanes.has(cell) and overworld.is_road(n))):
			bits |= 1 << k
		elif dirt < 0 and not lanes.has(cell) and overworld.is_road(n):
			bits |= 1 << k                              # a worn cell joins the generated road beside it
	if bits == 0:
		bits = 10                                       # alone: the east-west piece, as the dirt path's default
	if look == "road":
		if dirt >= 0 and int(_dirt_bits.get(dirt, -1)) == bits:
			return dirt
		var opts: Array = overworld.tiles.dirt_path[bits]
		return int(opts[0]) if not opts.is_empty() else dirt
	var row := 0
	match look:
		"stone":
			row = Overworld.hash32(overworld.seed, cell.x, cell.y, 91) % ROAD_STONE_ROWS
		"trail":
			row = ROAD_TRAIL_ROW + Overworld.hash32(overworld.seed, cell.x, cell.y, 92) % 2
		"road_overgrown":
			row = ROAD_OVERGROWN_ROW
		"trail_overgrown":
			row = ROAD_OVERGROWN_ROW + 1
		"stone_damaged":
			row = ROAD_DAMAGED_ROW
		"stone_broken":
			row = ROAD_DAMAGED_ROW + 1
	return ROAD_TILES + row * 16 + bits


## B25R1-Q3: a road over a stream: a stone bridge on a stone road, else a plank one, running the way the road does.
func _bridge_tile(cell: Vector2i, look: String) -> int:
	# B25R1-017: one bridge, one way: the planks (or stones) of all its cells run the long way of the crossing, whichever
	# way the road's cells step across the water
	var box := overworld.crossing_box(cell)
	var run := "ew" if box.size.x > box.size.y else "ns" if box.size.y > box.size.x else ("ns" if overworld.is_water(cell + Vector2i(-1, 0)) or overworld.is_water(cell + Vector2i(1, 0)) else "ew")
	var stone := look.begins_with("stone") or overworld.forced_crossing(cell) == "stone_bridge"     # B25R1-018: canonical stone bridge
	var br: Dictionary = overworld.tiles.water.bridge
	if not stone:
		# EA-01: a wooden bridge has its ends: the post-capped north end and the south end on its legs; rounded east and west
		var step := Vector2i(0, 1) if run == "ns" else Vector2i(1, 0)
		var head := not overworld.is_bridge(cell - step)
		var tail := not overworld.is_bridge(cell + step)
		if head != tail:
			var end := ("n" if head else "s") if run == "ns" else ("w" if head else "e")
			if br.has("plank_" + end):
				return int(br["plank_" + end])
	return int(br[("stone_" if stone else "plank_") + run])


## B25R1-011: draw a loaded cell's way again (its look changed), with its four neighbours (their joins may change).
func redraw_road(cell: Vector2i) -> void:
	for c in [cell, cell + Vector2i(0, -1), cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(-1, 0)]:
		var cc := Overworld.chunk_of(c)
		if not chunks.has(cc) or overworld.village.has_point(c):
			continue
		var ch := overworld.get_chunk(cc)
		var i: int = (c.y - cc.y * Overworld.CHUNK) * Overworld.CHUNK + c.x - cc.x * Overworld.CHUNK
		set_tile(chunks[cc].path, c, road_tile(c, ch.path[i]))


## B25R1-011: what changed since the last frame (footfall, paving, repair: Overworld.road_dirty), and once a game day every
## loaded way (fading, overgrowth and damage come with time).
## B25R1-019 (owner: water animates only inside the player's live range): the water of a loaded chunk is drawn from the
## animated atlas (5) when the chunk is live, from its still twin (6, the first frame) when not. live_check answers (Main:
## the presence workstream's rect_live when it is there, else every loaded chunk is live); re-checked when `version` changes
## (Main passes it) and for each chunk built.
func water_value(v: int, live: bool) -> int:
	if v >= 0 and v / 100000 == WATER_ATLAS and not live and sources.size() > WATER_STILL_ATLAS:
		return v + (WATER_STILL_ATLAS - WATER_ATLAS) * 100000
	return v


func chunk_live(cc: Vector2i) -> bool:
	return not live_check.is_valid() or bool(live_check.call(Rect2(Vector2(cc * Overworld.CHUNK), Vector2(Overworld.CHUNK, Overworld.CHUNK))))


var live_version := 0                 # bumped by Main when the live range changes


func _live_step() -> void:
	if live_version == _live_seen:
		return
	_live_seen = live_version
	for cc: Vector2i in chunks:
		var now := chunk_live(cc)
		if bool(_live.get(cc, true)) == now:
			continue
		_live[cc] = now
		var ch := overworld.get_chunk(cc)
		for i in Overworld.CHUNK * Overworld.CHUNK:
			if ch.water[i] != 0:
				set_tile(chunks[cc].ground, Vector2i(cc.x * Overworld.CHUNK + i % Overworld.CHUNK, cc.y * Overworld.CHUNK + i / Overworld.CHUNK), water_value(ch.ground[i], now))


func _road_step() -> void:
	if overworld.road_rev != _road_seen:
		_road_seen = overworld.road_rev
		var cells: Array = overworld.road_dirty.keys()
		overworld.road_dirty.clear()
		for c: Vector2i in cells:
			redraw_road(c)
	var day := RoadWear.day_of(overworld)
	if day != _road_day:
		_road_day = day
		for cc: Vector2i in chunks:
			var ch := overworld.get_chunk(cc)
			for i in Overworld.CHUNK * Overworld.CHUNK:
				var c := Vector2i(cc.x * Overworld.CHUNK + i % Overworld.CHUNK, cc.y * Overworld.CHUNK + i / Overworld.CHUNK)
				if ch.path[i] >= 0 or overworld.road_state.has(c):
					set_tile(chunks[cc].path, c, road_tile(c, ch.path[i]))


func _layer(root: Node2D, z: int) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.tile_set = tileset
	l.z_index = z
	l.rendering_quadrant_size = 32
	root.add_child(l)
	return l


func _build(cc: Vector2i) -> void:
	var ch := overworld.get_chunk(cc)
	var root := Node2D.new()
	root.name = "chunk_%d_%d" % [cc.x, cc.y]
	add_child(root)
	var ground := _layer(root, 0)
	var path := _layer(root, 0)
	var objects := _layer(root, 0)
	var tops := _layer(root, 10)
	var x0 := cc.x * Overworld.CHUNK
	var y0 := cc.y * Overworld.CHUNK
	var lanes := RegionRoads.lane_cells(overworld)
	var live_now := chunk_live(cc)
	_live[cc] = live_now
	for y in Overworld.CHUNK:
		for x in Overworld.CHUNK:
			var i := y * Overworld.CHUNK + x
			var cell := Vector2i(x0 + x, y0 + y)
			if ch.ground[i] >= 0:
				set_tile(ground, cell, water_value(ch.ground[i], live_now) if ch.water[i] != 0 else ch.ground[i])
			if ch.path[i] >= 0 or lanes.has(cell) or overworld.road_state.has(cell):
				set_tile(path, cell, road_tile(cell, ch.path[i]))
			if ch.deco[i] >= 0 and not overworld.rock_gone(cell) and not overworld.flower_gone(cell):    # a broken boulder or a picked flower stays gone
				var v: int = ch.deco[i]
				if v == int(overworld.tiles.rock) and ResourceNodes.boulder_small(cell) and sources.size() > 3:
					v = MapView.SMALL_BOULDER_TILE
				set_tile(objects, cell, v)
	if tree_sink != null:
		tree_sink.load_chunk(cc, overworld.chunk_trees(cc))
	var site_above := _draw_site_buildings(root, cc)
	var works := Node2D.new()             # B14-07: steps, stairs and walkways, over the ground and the cliff's rim
	works.name = "works"
	root.add_child(works)
	chunks[cc] = {"root": root, "ground": ground, "path": path, "objects": objects, "tops": tops, "works": works, "site_above": site_above}
	above_layers.append(tops)
	_draw_works(cc)


## REGION-NAV-01: the buildings of a settlement site in this chunk, painted from the village's building stamps (the same
## art and layers as a house or workshop in the village): ground, path and "below" layers under the characters, "above"
## layers (roofs) over them. Only the cells inside this chunk, so a building across a seam is drawn once.
func _draw_site_buildings(root: Node2D, cc: Vector2i) -> Array:
	var box := Rect2i(cc * Overworld.CHUNK, Vector2i(Overworld.CHUNK, Overworld.CHUNK))
	var layers := {}
	var sorted: TileMapLayer = null       # this chunk's site front walls, drawn among the characters
	for st in overworld.sites:
		if not (st.rect as Rect2i).intersects(box):
			continue
		for sl in st.slots:
			var r: Rect2i = sl.rect
			if not r.intersects(box):
				continue
			var stamp: Dictionary = overworld.stamps.get(str(sl.stamp), overworld.stamps.house)
			var swap: Dictionary = _look_swap(str(sl.get("look", "")))    # B25R1-018: the building's colour variant (region_stamps.json)
			var names: Array = (stamp.layers as Dictionary).keys()
			names.sort_custom(func(a: String, b: String) -> bool:
				var ra := 0 if a.begins_with("ground") else 1 if a.begins_with("path") else 2 if a.begins_with("below") else 3
				var rb := 0 if b.begins_with("ground") else 1 if b.begins_with("path") else 2 if b.begins_with("below") else 3
				return ra < rb or (ra == rb and a < b))
			for lname in names:
				var l: TileMapLayer = layers.get(lname)
				if l == null:
					l = _layer(root, 10 if str(lname).begins_with("above") else 0)
					l.name = str(lname)
					layers[lname] = l
					if str(lname).begins_with("above"):
						above_layers.append(l)
				var cells: Array = stamp.layers[lname]
				for j in int(stamp.h):
					for i in int(stamp.w):
						var v := int(cells[j * int(stamp.w) + i])
						if not swap.is_empty():
							v = int(swap.get(str(v), v))
						var cell := r.position + Vector2i(i, j)
						if v < 0 or not box.has_point(cell):
							continue
						if str(lname).begins_with("above") and _site_sorts(stamp, str(lname), i, j, cell):
							if sorted == null:
								sorted = TileMapLayer.new()
								sorted.name = "site_front_%d_%d" % [cc.x, cc.y]
								sorted.tile_set = tileset
								sorted.y_sort_enabled = true
								_site_sorted_parent.add_child(sorted)
							_put(sorted, cell, v)
						else:
							set_tile(l, cell, v)
	var above := []
	for lname in layers:
		if str(lname).begins_with("above"):
			above.append(layers[lname])
	if sorted != null:
		above.append(sorted)              # (freed with the chunk; see _free)
	return above


static var _looks := {}


## B25R1-018: tile -> tile of a building colour variant ("thatch"), {} for the stamp as drawn (game/data/region_stamps.json,
## made by tools/build_region_stamps.py from the paid tileset's colour blocks).
static func _look_swap(look: String) -> Dictionary:
	if look == "":
		return {}
	if _looks.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/region_stamps.json"))
		_looks = d.variants if d is Dictionary else {"_": {}}
	return (_looks.get(look, {}) as Dictionary).get("swap", {})


## GP-DRAW-UNDER-HOUSE for the settlement sites (owner 2026-11-03: "half of them would go under the building's sprite"): an
## "above" tile of a site building is drawn among the characters, by its cell's bottom edge, when its cell is one of the
## building's solid cells and either it is not a roof layer (an overlay on a solid cell, B8-025) or no roof-layer tile of the
## stamp lies south of it (the bottom row of the front wall). The rest of the roof stays over everyone, as in the village.
func _site_sorts(stamp: Dictionary, lname: String, i: int, j: int, cell: Vector2i) -> bool:
	if _site_sorted_parent == null or not overworld.site_building_at(cell):
		return false
	if not _site_roofs.has(lname):
		return true
	if j + 1 >= int(stamp.h):
		return true
	for rn in _site_roofs:
		var rl: Array = (stamp.layers as Dictionary).get(rn, [])
		if not rl.is_empty() and int(rl[(j + 1) * int(stamp.w) + i]) >= 0:
			return false
	return true


func _free(cc: Vector2i) -> void:
	canopy.restore_all()                  # faded tiles go back to their layers before the layer goes
	if tree_sink != null:
		tree_sink.unload_chunk(cc)
	var c: Dictionary = chunks[cc]
	above_layers.erase(c.tops)
	for l in c.get("site_above", []):
		above_layers.erase(l)
		if is_instance_valid(l) and l.get_parent() == _site_sorted_parent:
			l.queue_free()                # a front-wall layer lives among the characters, not under this chunk's root
	c.root.queue_free()
	chunks.erase(cc)


## A tile of the objects ("below") or tree-top ("above") layer changed at a cell (a felled tree
## stump, a sapling, a regrown tree): the same call World.tile_changed makes for the village.
func apply_change(cell: Vector2i, kind: String, value: int) -> void:
	if kind == "below":
		var c: Dictionary = chunks.get(Overworld.chunk_of(cell), {})
		if not c.is_empty():
			set_tile(c.objects, cell, value)
		return
	if kind != "above":
		return
	canopy.restore_all()
	# a tree's top and bottom tiles both sit in the layer of the chunk that holds its trunk, which
	# for a top tile (the cell above the trunk) may be the chunk below
	var below := Overworld.chunk_of(cell + Vector2i.DOWN)
	var own := Overworld.chunk_of(cell)
	var target := below if tops_set.has(value) else own
	for cc in [own, below]:
		var c: Dictionary = chunks.get(cc, {})
		if not c.is_empty() and (cc == target or value < 0):
			set_tile(c.tops, cell, value)


func loaded_count() -> int:
	return chunks.size()


## The tile value drawn on a cell's ground layer, or -1 (tests).
func ground_value(cell: Vector2i) -> int:
	var c: Dictionary = chunks.get(Overworld.chunk_of(cell), {})
	return -1 if c.is_empty() else tile_value(c.ground, cell)
