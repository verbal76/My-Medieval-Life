class_name OverworldView
extends MapView
## Draws the overworld (Overworld) as a ring of chunks round the camera. Each loaded chunk is a node
## with four TileMapLayers: ground, road, objects (tree trunks, rocks, flowers, bushes) and tree tops
## (drawn over the characters, faded by a CanopyFade while the player stands behind one). Chunks
## are built a few per frame as the camera moves, and freed once they are more than one chunk
## beyond the ring, so what is held is bounded whatever distance is walked. The village's own
## MapView draws the village; the cells inside it are not drawn here. The tiles, the atlases and
## the TileSet are the village MapView's (the art is the same packs).

## B25R2 (owner directive 2026-11-06, item 3, the travel stutter): one chunk a frame (it was 3: crossing a chunk border built
## two or three at once, 100-150 ms in one frame, travel_perf_test), and on a frame with none to build the data of one chunk of
## the next ring out is prepared ahead in the direction of travel (_prefetch), so the ones needed at the border are ready.
const BUILD_PER_FRAME := 1

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
var _homes_root: Node2D               # B25R1-010: the homesteads' houses and frames (Overworld.homes), drawn over the chunks' ground
var _homes_seen := -1                 # Overworld.homes_version last drawn
var _home_roofs := {}                 # home id -> [its "above" layers, its house rect]: the roof fades while the player is inside
var _road_seen := -1                  # B25R1-011: Overworld.road_rev last drawn
var _road_day := -1                   # the game day the loaded ways were last drawn for
var live_check: Callable              # B25R1-019: (chunk rect in tiles) -> whether its water animates; Main sets it (the presence query)
var _live_seen := -1                  # the presence version the loaded water was last drawn for
var _live := {}                       # chunk -> whether its water was drawn animated
var _lift_rect := Rect2i()            # B25R1-022: the site building whose roof is lifted (its slot rect), empty none
var _lift_alpha := 1.0                # how far it is lifted (1 on, RoofFade.ALPHA off)
var _lift_moved := []                 # [source layer, cell, source id, atlas coords, alternative, faded layer]
var _lift_dst: TileMapLayer           # the lifted roof's tiles over the characters
var _lift_dst_sorted: TileMapLayer    # and its front wall's, among them
var _dirt_bits := {}                  # B25R1-Q1: dirt path tile -> its connected sides (overworld_tiles.json dirt_path)
var _flat := {}                       # B25R1-Q8: the flat grass tile values (overworld_tiles.json grass): where a tuft may grow


func setup(src: MapView, o: Overworld, load_radius: int) -> void:
	_pf_stop()                                    # B42: a worker laid out for another world stops first
	_pf_map = src.map
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
	for g in o.tiles.grass:
		_flat[int(g)] = true
	for k in (o.tiles.dirt_path as Array).size():
		for t in o.tiles.dirt_path[k]:
			_dirt_bits[int(t)] = k
	canopy = CanopyFade.new()
	add_child(canopy)
	canopy.setup(self, pairs)


## Keep the chunks round `center` (tiles) drawn, building at most `budget` this call (a negative
## budget builds them all: a first view, a teleport), and fade canopies over `feet`.
## B25-MOVE-STUTTER-INV (diagnostics only, off by default): microseconds per part of follow, summed until a probe clears it.
var profiling := false
var prof := {}


func _pf(key: String, t0: int) -> int:
	var now := Time.get_ticks_usec()
	prof[key] = int(prof.get(key, 0)) + now - t0
	return now


func follow(center: Vector2, feet: Vector2, delta: float, budget := BUILD_PER_FRAME) -> void:
	var tq := Time.get_ticks_usec() if profiling else 0
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
		if profiling:
			tq = _pf("ow:recentre+free", tq)
	var n := 0
	while not _pending.is_empty() and (budget < 0 or n < budget):
		var c: Vector2i = _pending.pop_front()
		if not chunks.has(c):
			_build(c)
			n += 1
	if profiling:
		tq = _pf("ow:build", tq)
	if n == 0 and budget >= 0:
		_prefetch(cc, center)
		if profiling:
			tq = _pf("ow:prefetch", tq)
	if budget < 0 and tree_sink != null:
		tree_sink.flush()
	_road_step()
	if profiling:
		tq = _pf("ow:road_step", tq)
	_live_step()
	if profiling:
		tq = _pf("ow:live_step", tq)
	if overworld.works_version != _works_seen:
		_works_seen = overworld.works_version
		for c: Vector2i in chunks:
			_draw_works(c)
	if overworld.homes_version != _homes_seen:
		_homes_seen = overworld.homes_version
		_draw_homes()
	if profiling:
		tq = _pf("ow:works+homes", tq)
	site_roof_step(feet, delta)
	for id in _home_roofs:
		var inside := Rect2((_home_roofs[id][1] as Rect2i)).has_point(feet)
		for l: TileMapLayer in _home_roofs[id][0]:
			l.modulate.a = 0.3 if inside else 1.0
	if profiling:
		tq = _pf("ow:roofs", tq)
	canopy.update(feet, delta)
	if profiling:
		_pf("ow:canopy", tq)


var _last_center := Vector2.INF                # B25R2: where the view's centre was, for the direction of travel (_prefetch)


## B25R2: with nothing to build this frame, generate the data (Overworld.get_chunk, kept in its cache) of one chunk of the ring
## just outside the drawn window, the one nearest the point the view is heading for: the costly part of a chunk is then done
## before the border is crossed, and building it is only drawing. Never more than one a frame.
## B42 (B25-MOVE-STUTTER-INV, owner 2026-11-14: "advance, briefly freeze, advance again" on the trails south): that one
## chunk's generation was 26-140 ms on the main thread, on several frames in a row at every chunk crossing (152 of the 215
## frames over 50 ms on the southern walk). It is now generated on a background thread (async_prefetch), by a private
## Overworld laid out from the same seed, map and generation, and taken into the world's cache here (Overworld.adopt_chunk).
## A chunk is a function of the seed, the map and the generation alone (the working state of the chunk being generated is
## the instance's own), so it is the chunk get_chunk would make: chunk_prefetch_test compares every field. A chunk needed
## before the worker has it is made on the main thread as before, and the worker's copy is dropped.
var async_prefetch := true
var prefetch_adopted := 0                      # chunks the worker made that were taken into the cache (tests, probes)
var _pf_thread: Thread
var _pf_sem: Semaphore
var _pf_mutex := Mutex.new()
var _pf_want := Vector2i.ZERO                  # the chunk the worker was asked for (one at a time)
var _pf_busy := false                          # asked and not yet handed back (main thread only)
var _pf_out: Array = []                        # [chunk coordinates, Chunk, its fixed_works cells], under _pf_mutex
var _pf_quit := false
var _pf_map: VillageMap                        # the village map the world was laid out with (the worker lays out its own)


func _prefetch(cc: Vector2i, center: Vector2) -> void:
	if async_prefetch:
		_pf_collect()
	var heading := Vector2.ZERO if _last_center == Vector2.INF else (center - _last_center)
	_last_center = center
	if heading.length() < 0.01:
		return                                     # standing still: nothing ahead to prepare
	if async_prefetch and _pf_busy:
		return                                     # one at a time: the worker is on one
	var ahead := center + heading.normalized() * float(Overworld.CHUNK * (radius + 1))
	var best := Vector2i(1 << 30, 0)
	var bd := INF
	for dy in range(-radius - 1, radius + 2):
		for dx in range(-radius - 1, radius + 2):
			if maxi(absi(dx), absi(dy)) != radius + 1:
				continue
			var c := cc + Vector2i(dx, dy)
			if overworld.cache.has(c) or overworld.chunk_in_village(c):
				continue
			var d := (Vector2(c * Overworld.CHUNK) + Vector2(Overworld.CHUNK, Overworld.CHUNK) * 0.5).distance_to(ahead)
			if d < bd:
				bd = d
				best = c
	if bd == INF:
		return
	if not async_prefetch or _pf_map == null:
		overworld.get_chunk(best)
		return
	if _pf_thread == null:
		_pf_sem = Semaphore.new()
		_pf_quit = false
		# the worker reads none of the live world: a copy of what Overworld.create reads (the map's size and stamps; the gates
		# as this world has them, not the map's exits, which read its live solid cells)
		var snap := VillageMap.new()
		snap.w = _pf_map.w
		snap.h = _pf_map.h
		snap.data = {"stamps": (_pf_map.data.stamps as Dictionary).duplicate(true)}
		var gates: Array = []
		for g in overworld.gates:
			gates.append({"out": g.out, "dir": g.dir})
		_pf_thread = Thread.new()
		_pf_thread.start(_pf_work.bind(overworld.seed, snap, overworld.gen, gates), Thread.PRIORITY_LOW)
	_pf_mutex.lock()
	_pf_want = best
	_pf_mutex.unlock()
	_pf_busy = true
	_pf_sem.post()


## The worker: a private Overworld (Overworld.create, about 1.5 s, once), then each chunk asked for, generated and handed
## back with the generator's rim steps in it (fixed_works, which _generate records as it goes).
func _pf_work(seed_v: int, vmap: VillageMap, gen: int, gates: Array) -> void:
	var o := Overworld.create(seed_v, vmap, gen, gates)
	while true:
		_pf_sem.wait()
		_pf_mutex.lock()
		var quit := _pf_quit
		var cc := _pf_want
		_pf_mutex.unlock()
		if quit:
			return
		var ch := o._generate(cc.x, cc.y)
		var fw := {}
		for y in Overworld.CHUNK:
			for x in Overworld.CHUNK:
				var c := Vector2i(cc.x * Overworld.CHUNK + x, cc.y * Overworld.CHUNK + y)
				if o.fixed_works.has(c):
					fw[c] = o.fixed_works[c]
		_pf_mutex.lock()
		_pf_out.append([cc, ch, fw])
		_pf_mutex.unlock()


## Take what the worker has finished into the world's cache (cheap: a dictionary insert).
func _pf_collect() -> void:
	if _pf_thread == null:
		return
	_pf_mutex.lock()
	var got := _pf_out
	_pf_out = []
	_pf_mutex.unlock()
	for e in got:
		_pf_busy = false
		if overworld.adopt_chunk(e[0], e[1], e[2]):
			prefetch_adopted += 1


## Stop the worker (the view is leaving, or drawing another world): it finishes the chunk it is on, if any.
func _pf_stop() -> void:
	if _pf_thread == null:
		return
	_pf_mutex.lock()
	_pf_quit = true
	_pf_mutex.unlock()
	_pf_sem.post()
	_pf_thread.wait_to_finish()
	_pf_thread = null
	_pf_out = []
	_pf_busy = false


func _exit_tree() -> void:
	_pf_stop()


## B14-07: the steps, stairs and walkways through a cliff's rim in a loaded chunk, each a 16 px tile over its cell, under
## the characters (drawn again whenever a way is made).
func _draw_works(cc: Vector2i) -> void:
	var c: Dictionary = chunks.get(cc, {})
	if c.is_empty():
		return
	var layer: Node2D = c.works
	for k in layer.get_children():
		k.queue_free()
	var cells: Array = (overworld.works.keys() + overworld.fixed_works.keys()).filter(func(w: Vector2i) -> bool: return Overworld.chunk_of(w) == cc)
	cells.sort()
	for cell: Vector2i in cells:
		var kind := overworld.way_at(cell)              # (B25R1-018: the generator's steps up a knoll too)
		var low := 0
		if kind.begins_with("steps") and kind.length() == 8:       # "steps_ns" / "steps_ew" (the old "steps" has no run)
			# the tile's low side (its grass edge) faces the ground, not the top: steps_ns is drawn low side south, steps_ew low
			# side east; a cell with more steps on its low side takes the "_mid" tile, whose treads run on to the next cell
			low = _steps_low_side(cell, kind.ends_with("_ew"))
			var ahead: Vector2i = cell + (Vector2i(low, 0) if kind.ends_with("_ew") else Vector2i(0, low))
			if overworld.way_at(ahead).begins_with("steps"):
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
		while overworld.way_at(c).begins_with("steps") and absi(c.x - cell.x) + absi(c.y - cell.y) < 16:
			c += axis * sgn
		ends.append(overworld.is_top(c))
	return -1 if ends[0] and not ends[1] else 1   # ends[0] is the + end: a top there puts the ground at the - end


## B25R1-Q1 and B25R1-011: the tile a cell's way is drawn with, by its look now (RoadWear.visual: the generated type, worn in
## by footfall, faded, grown over, paved, damaged): -1 for grass. A generated dirt road keeps its generated dirt path tile
## `dirt` (-1 where the generator drew none); the rest come from the road tile sheet (MapView atlas 4) or the dirt path set,
## for the connected sides: the generated ones (from `dirt`), worn ways beside it, and a settlement's street beside stone.
## Drawing only: the cell, its walkability and the chunk data are unchanged.
func road_tile(cell: Vector2i, dirt: int) -> int:
	if dirt >= 200000:
		return dirt                                     # B25R1-018: a hill figure's chalk line or an earthwork's bank (no road)
	var look := RoadWear.visual(overworld, cell)
	if RegionRoads.lane_cells(overworld).has(cell):
		look = "stone" if look == "" else look
	if look == "":
		return -1
	if sources.size() <= 4:
		return dirt
	if overworld.is_ford(cell) and sources.size() > WATER_ATLAS:
		return -1                                  # EA-01: a ford on the road shows its stepping stones, not a track over the water
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
## animated atlas (WATER_ATLAS, 9) when the chunk is live, from its still twin (WATER_STILL_ATLAS, 10, the first frame) when not. live_check answers (Main:
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


var build_usec := 0                   # time spent building chunks (_build), for the perf harness (grass_shot)


func _build(cc: Vector2i) -> void:
	var t0 := Time.get_ticks_usec()
	var ch := overworld.get_chunk(cc)
	var root := Node2D.new()
	root.name = "chunk_%d_%d" % [cc.x, cc.y]
	add_child(root)
	if _homes_root != null:
		move_child(_homes_root, get_child_count() - 1)     # B25R1-010: the homesteads stay drawn over every chunk's ground
	var ground := _layer(root, 0)
	var grass := _layer(root, 0)          # B25R1-Q8: the low grass tufts, over the ground, under the roads and objects
	grass.name = "grass"
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
	_lay_grass(cc, ch, grass, lanes)
	if tree_sink != null:
		tree_sink.load_chunk(cc, overworld.chunk_trees(cc))
	var site_above := _draw_site_buildings(root, cc)
	var works := Node2D.new()             # B14-07: steps, stairs and walkways, over the ground and the cliff's rim
	works.name = "works"
	root.add_child(works)
	chunks[cc] = {"root": root, "ground": ground, "grass": grass, "path": path, "objects": objects, "tops": tops, "works": works, "site_above": site_above}
	above_layers.append(tops)
	_draw_works(cc)
	if _lift_rect.has_area():              # B25R1-022: a lifted roof reaching into this new chunk lifts there too
		var r := _lift_rect
		var a := _lift_alpha
		_site_roof_restore()
		_site_roof_lift(r)
		_lift_alpha = a
		_site_roof_apply()
	build_usec += Time.get_ticks_usec() - t0


## B25R1-Q8: the low grass tufts of a chunk (MapView.grass_tuft), on open flat grass only: no road, worn way or street, no
## water, no rock, flower or bush, nothing solid (trees, cliffs, a raised rim), no settlement building or yard (a styled house's
## plot included), no homestead, no steps or way through a rim. Drawing only.
func _lay_grass(cc: Vector2i, ch: Overworld.Chunk, layer: TileMapLayer, lanes: Dictionary) -> void:
	if not has_grass_art():
		return
	var t0 := Time.get_ticks_usec()
	var box := Rect2i(cc * Overworld.CHUNK, Vector2i(Overworld.CHUNK, Overworld.CHUNK))
	var keep_off: Array[Rect2i] = []           # the settlements' buildings and yards, the homesteads, in this chunk
	for st in overworld.sites + overworld.structures:
		if (st.rect as Rect2i).grow(1).intersects(box):
			for sl in st.slots + st.get("props", []):
				var grown := (sl.rect as Rect2i).grow(1)      # (grown before the test: a plot on a chunk's edge keeps the next chunk's cells off too)
				if grown.intersects(box):
					keep_off.append(grown)
	var fenced := {}
	for hm in overworld.homes:
		if (hm.rect as Rect2i).intersects(box):
			keep_off.append(hm.rect)
		for cells: Dictionary in hm.get("layers", []):
			for c: Vector2i in cells:
				fenced[c] = true
	var tufts := MapView.low_grass()
	var plain: Array = tufts.plain
	var flowered: Array = tufts.flowered
	var seed := overworld.seed
	var roads: Dictionary = overworld.road_state
	var changed: Dictionary = overworld.changes
	var ways: Dictionary = overworld.works
	var fixed_ways: Dictionary = overworld.fixed_works
	for y in Overworld.CHUNK:
		for x in Overworld.CHUNK:
			var cell := box.position + Vector2i(x, y)
			var h := Overworld.hash32(seed, cell.x, cell.y, GRASS_SALT)      # MapView.grass_tuft, inlined (a chunk is 1024 cells)
			var roll := h % 100
			if roll >= GRASS_PLAIN + GRASS_FLOWERED:
				continue
			var i := y * Overworld.CHUNK + x
			if ch.solid[i] != 0 or ch.water[i] != 0 or ch.path[i] >= 0 or ch.deco[i] >= 0 or not _flat.has(ch.ground[i]):
				continue
			if lanes.has(cell) or roads.has(cell) or fenced.has(cell) or changed.has(cell) or ways.has(cell) or fixed_ways.has(cell):
				continue                           # (B25R1-018: nor on a way through a rim, the player's or the generator's steps)
			var off := false
			for r in keep_off:
				if r.has_point(cell):
					off = true
					break
			if off:
				continue
			var list: Array = plain if roll < GRASS_PLAIN else flowered
			_put(layer, cell, int(list[(h >> 8) % list.size()]))
	grass_usec += Time.get_ticks_usec() - t0


func _grass_off(cell: Vector2i) -> void:
	var c: Dictionary = chunks.get(Overworld.chunk_of(cell), {})
	if not c.is_empty():
		(c.grass as TileMapLayer).erase_cell(cell)


## The tuft drawn on a cell of a loaded chunk, -1 for none (tests).
func grass_value(cell: Vector2i) -> int:
	var c: Dictionary = chunks.get(Overworld.chunk_of(cell), {})
	return -1 if c.is_empty() else tile_value(c.grass, cell)


## B25R1-010: every homestead's house (painted from the village's house stamp, as a settlement's buildings are: ground, path
## and "below" layers under the characters, "above" layers over them, fading while the player is inside) and every frame of
## a house being built (the village's frame tile). Few, so all are drawn again whenever one changes.
func _draw_homes() -> void:
	if _homes_root != null:
		_homes_root.queue_free()
	_home_roofs.clear()
	_homes_root = Node2D.new()
	_homes_root.name = "homesteads"
	add_child(_homes_root)
	for hm in overworld.homes:
		var r: Rect2i = hm.rect
		if hm.has("layers"):
			for cells: Dictionary in hm.layers:      # a claim's fence, or a well being dug (Wilds.overworld_entries)
				var ll := _layer(_homes_root, 0)
				for cell: Vector2i in cells:
					set_tile(ll, cell, int(cells[cell]))
			continue
		if str(hm.stamp) == "":
			var fl := _layer(_homes_root, 0)
			set_tile(fl, Vector2i(hm.frame), int(hm.tile))
			continue
		var stamp: Dictionary = overworld.stamps.get(str(hm.stamp), overworld.stamps.house)
		var names: Array = (stamp.layers as Dictionary).keys()
		names.sort_custom(func(a: String, b: String) -> bool:
			var ra := 0 if a.begins_with("ground") else 1 if a.begins_with("path") else 2 if a.begins_with("below") else 3
			var rb := 0 if b.begins_with("ground") else 1 if b.begins_with("path") else 2 if b.begins_with("below") else 3
			return ra < rb or (ra == rb and a < b))
		var roofs: Array[TileMapLayer] = []
		for lname in names:
			var above := str(lname).begins_with("above")
			var l := _layer(_homes_root, 10 if above else 0)
			l.name = "%s_%s" % [str(hm.id), str(lname)]
			if above:
				roofs.append(l)
			var cells: Array = stamp.layers[lname]
			for j in int(stamp.h):
				for i in int(stamp.w):
					var v := int(cells[j * int(stamp.w) + i])
					if v >= 0:
						set_tile(l, r.position + Vector2i(i, j), v)
		_home_roofs[str(hm.id)] = [roofs, Rect2i(r.position, Vector2i(r.size.x, r.size.y - 1))]


## REGION-NAV-01: the buildings of a settlement site in this chunk, painted from the village's building stamps (the same
## art and layers as a house or workshop in the village): ground, path and "below" layers under the characters, "above"
## layers (roofs) over them. Only the cells inside this chunk, so a building across a seam is drawn once.
func _draw_site_buildings(root: Node2D, cc: Vector2i) -> Array:
	var box := Rect2i(cc * Overworld.CHUNK, Vector2i(Overworld.CHUNK, Overworld.CHUNK))
	var layers := {}
	var sorted: TileMapLayer = null       # this chunk's site front walls, drawn among the characters
	for st in overworld.sites + overworld.structures:   # (B25R1-018: and the landmarks built in the country)
		if not (st.rect as Rect2i).intersects(box):
			continue
		for sl in st.slots + st.get("props", []):     # (B25R1-018: and the yard pieces)
			var r: Rect2i = sl.rect
			if not r.intersects(box):
				continue
			var stamp: Dictionary = overworld.stamps.get(Overworld.slot_stamp(sl), overworld.stamps.house)   # (B25R1-022: its house style's)
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
				var clip := r.intersection(box)          # only this chunk's part (a town's walls are one stamp round it all)
				for j in range(clip.position.y - r.position.y, clip.end.y - r.position.y):
					for i in range(clip.position.x - r.position.x, clip.end.x - r.position.x):
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


## The building colour variants, read once per view (an instance member: a static one kept 71 scripts alive at exit, B25R1).
var _looks := {}


## B25R1-018: tile -> tile of a building colour variant ("thatch"), {} for the stamp as drawn (game/data/region_stamps.json,
## made by tools/build_region_stamps.py from the paid tileset's colour blocks).
func _look_swap(look: String) -> Dictionary:
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


## B25R1-022 (owner 2026-11-04: "make the roofs removable like our current ones for going inside"; RoofFade's rules): a
## settlement building's roof lifts while the player is inside it (Overworld.site_inside_at: its doorway and rooms), fully
## (RoofFade.ALPHA) over RoofFade.FADE_TIME, and comes back on leaving. Only that building's roof tiles move, from the
## chunks' site layers to two layers of their own whose alpha is faded, as RoofFade does in the village. `feet` in tiles.
func site_roof_step(feet: Vector2, delta: float) -> void:
	var cell := Vector2i(floori(feet.x), floori(feet.y))
	var want := Rect2i()
	if not overworld.village.has_point(cell):
		var sl := overworld.site_inside_at(cell)
		if not sl.is_empty():
			want = sl.rect
	var step := delta / RoofFade.FADE_TIME
	if want != _lift_rect:
		if _lift_rect.has_area():
			_lift_alpha = move_toward(_lift_alpha, 1.0, step)       # the old roof comes back first
			if _lift_alpha < 1.0:
				_site_roof_apply()
				return
			_site_roof_restore()
		if want.has_area():
			_site_roof_lift(want)
	elif _lift_rect.has_area():
		_lift_alpha = move_toward(_lift_alpha, RoofFade.ALPHA, step)
	_site_roof_apply()


## The site building whose roof is lifted (its slot rect), or an empty rect.
func site_roof_lifted() -> Rect2i:
	return _lift_rect if _lift_alpha < 1.0 else Rect2i()


func _site_roof_apply() -> void:
	for l in [_lift_dst, _lift_dst_sorted]:
		if l != null:
			l.modulate.a = _lift_alpha


func _site_roof_lift(r: Rect2i) -> void:
	_lift_rect = r
	_lift_alpha = 1.0
	if _lift_dst == null:
		_lift_dst = _layer(self, 10)
		_lift_dst.name = "site_roof_lifted"
		if _site_sorted_parent != null:
			_lift_dst_sorted = TileMapLayer.new()
			_lift_dst_sorted.name = "site_roof_lifted_front"
			_lift_dst_sorted.tile_set = tileset
			_lift_dst_sorted.y_sort_enabled = true
			_site_sorted_parent.add_child(_lift_dst_sorted)
	var st := overworld.site_at(r.position)
	var stamp := {}
	for sl in st.get("slots", []):
		if sl.rect == r:
			stamp = overworld.stamps.get(Overworld.slot_stamp(sl), {})
	if stamp.is_empty():
		return
	var above: Array = []
	for ln in (stamp.layers as Dictionary):
		if str(ln).begins_with("above"):
			above.append(stamp.layers[ln])
	for j in r.size.y:
		for i in r.size.x:
			var roofed := false
			for cells: Array in above:
				if int(cells[j * int(stamp.w) + i]) >= 0:
					roofed = true
			if not roofed:
				continue
			var cell := r.position + Vector2i(i, j)
			var c: Dictionary = chunks.get(Overworld.chunk_of(cell), {})
			for l: TileMapLayer in c.get("site_above", []):
				if not is_instance_valid(l):
					continue
				var id := l.get_cell_source_id(cell)
				if id < 0:
					continue
				var d := _lift_dst_sorted if l.y_sort_enabled and _lift_dst_sorted != null else _lift_dst
				_lift_moved.append([l, cell, id, l.get_cell_atlas_coords(cell), l.get_cell_alternative_tile(cell), d])
				d.set_cell(cell, id, l.get_cell_atlas_coords(cell), l.get_cell_alternative_tile(cell))
				l.erase_cell(cell)


## Put the lifted roof back at once (a chunk is freed or built, or the player has left).
func _site_roof_restore() -> void:
	for m in _lift_moved:
		var l: TileMapLayer = m[0]
		if is_instance_valid(l):
			l.set_cell(m[1], m[2], m[3], m[4])
	_lift_moved.clear()
	for l in [_lift_dst, _lift_dst_sorted]:
		if l != null:
			l.clear()
	_lift_rect = Rect2i()
	_lift_alpha = 1.0


func _free(cc: Vector2i) -> void:
	canopy.restore_all()                  # faded tiles go back to their layers before the layer goes
	_site_roof_restore()                  # (B25R1-022: and a lifted site roof; lifted again next frame if still inside)
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
