extends SceneTree
## B25R1-Q1 (owner 2026-11-03: stone roads, dirt roads, dirt trails), checked in the real game scene, headless:
##   godot --headless --path game --script res://tests/road_types_test.gd
## All three types are there, from the network's own data and on its own cells; stone is the improved part, not every road
## between places; each type is drawn with its own tiles in the world (the chunk's path layer) and on the Region map; every
## cell of every type is walkable; and the character walks across all three on one journey by the existing travel and walking.

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		printerr("FAIL: " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("new_game"):
		print("FAIL the game's main script did not load: stopping")
		quit(1)
		return
	main.save_path = "user://test_saves/road_types_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _frames(n: int, dt := 0.1) -> void:
	for i in n:
		main._process(dt)


func _run() -> void:
	main.set_process(false)
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var area := RegionMapPanel.settlement_network(w)
	# --- the three types, from the data
	var by := {"stone": [], "road": [], "trail": []}
	for seg in RegionRoads.segments(ow, area):
		var c: PackedInt32Array = seg.cells
		for q in range(0, c.size() / 2, 3):
			var cell := Vector2i(c[q * 2], c[q * 2 + 1])
			if ow.village.has_point(cell):
				continue
			var k := str(RegionRoads.main_kinds(ow).get(cell, "trail"))
			by[k].append(cell)
	var lanes := RegionRoads.lane_cells(ow)
	check(by.stone.size() > 50 and by.road.size() > 50 and by.trail.size() > 50, "all three road types are on the network (stone %d, dirt road %d, trail %d sampled)" % [by.stone.size(), by.road.size(), by.trail.size()])
	var kinds := RegionRoads.main_kinds(ow)
	var n_stone := 0
	for c in kinds:
		if kinds[c] == "stone":
			n_stone += 1
	check(n_stone * 100 < kinds.size() * 40, "stone is the improved part, not every road between places (%d of %d main road cells)" % [n_stone, kinds.size()])
	var approaches := 0
	for st in ow.sites:
		var paved := 0
		for c in kinds:
			if kinds[c] == "stone" and (st.rect as Rect2i).grow(RegionRoads.STONE_NEAR).has_point(c) and not (st.rect as Rect2i).has_point(c):
				paved += 1
		if paved >= 10:
			approaches += 1
	check(approaches == ow.sites.size(), "every settlement's road approach is paved (%d of %d)" % [approaches, ow.sites.size()])
	check(lanes.size() > 100, "the settlements' streets are paved (%d cells)" % lanes.size())
	# --- walkable, every type
	var bad := 0
	var sampled := 0
	for k in by:
		for cell in by[k]:
			sampled += 1
			if ow.is_solid(cell) or not ow.is_road(cell) or RegionRoads.cell_kind(ow, cell) != k:
				bad += 1
	for cell in lanes:
		sampled += 1
		if ow.is_solid(cell) or w.map.is_solid_world(cell):
			bad += 1
	check(bad == 0, "every sampled cell of every type is open road (streets open ground), its type the world's (%d sampled, %d not)" % [sampled, bad])
	# --- drawn with its own tiles: the view's tile per type, and the chunk's path layer
	var view: OverworldView = main.ow_view
	var drawn := {"stone": 0, "road": 0, "trail": 0}
	var wrong := 0
	for k in by:
		for cell in (by[k] as Array).filter(func(c): return not ow.is_bridge(c)).slice(0, 40):     # (a bridge has its own tile: water_test)
			var ch := ow.get_chunk(Overworld.chunk_of(cell))
			var i: int = (cell.y - ch.cy * Overworld.CHUNK) * Overworld.CHUNK + cell.x - ch.cx * Overworld.CHUNK
			var t: int = view.road_tile(cell, ch.path[i])
			var in_atlas := t >= MapView.ROAD_TILES and t < MapView.ROAD_TILES + 100000
			var row := (t - MapView.ROAD_TILES) / 16
			if k == "road":
				wrong += 0 if t == ch.path[i] else 1
			elif k == "stone":
				wrong += 0 if in_atlas and row < MapView.ROAD_STONE_ROWS else 1
			else:
				wrong += 0 if in_atlas and row >= MapView.ROAD_TRAIL_ROW else 1
			drawn[k] += 1
	check(wrong == 0 and view.sources.size() >= 5, "each type has its own tiles: dirt roads the dirt path, stone the paving rows, trails the trail rows (%s, %d wrong)" % [str(drawn), wrong])
	# the real chunk drawing: stand in Wulstead and let the chunks build
	var st: Dictionary = ow.site("wulstead")
	w.player.pos = Vector2(st.gate) + Vector2(0.5, 0.5)
	main.recenter()
	view.follow(w.player.pos, w.player.pos, 0.0, -1)     # every chunk round the player built now, as a load does
	var gate_cell := Vector2i(st.gate)
	var lane_cell: Vector2i = lanes.keys().filter(func(c): return (st.rect as Rect2i).has_point(c))[0]
	var built: Dictionary = view.chunks.get(Overworld.chunk_of(lane_cell), {})
	check(not built.is_empty() and (built.path as TileMapLayer).get_cell_source_id(lane_cell) == 4, "in the world, Wulstead's street is drawn with the stone road tiles (atlas 4)")
	check(not built.is_empty() and (view.chunks.get(Overworld.chunk_of(gate_cell), built).path as TileMapLayer).get_cell_source_id(gate_cell) == 4, "and so is the road where it comes into the site")
	# --- the Region map's lines carry the same three types
	var lines := RegionMapPanel.road_lines(ow, area)
	var lk := {}
	var mismatch := 0
	for l in lines:
		lk[l.kind] = int(lk.get(l.kind, 0)) + 1
		var mid: Vector2 = l.pts[l.pts.size() / 2]
		var cell := Vector2i(mid.floor())
		if not ow.village.has_point(cell) and ow.is_road(cell) and RegionRoads.cell_kind(ow, cell) != l.kind and l.pts.size() > 3:
			mismatch += 1
	check(lk.has("stone") and lk.has("road") and lk.has("trail"), "the Region map draws the three types (%s)" % str(lk))
	check(mismatch == 0, "the map's type for a line is the world's for its cells (%d differ)" % mismatch)
	# --- one journey over all three: from Wulstead's street, out by the stone approach and the dirt road, onto a trail
	var start: Vector2i = lane_cell
	var goal := Vector2i(-1048576, 0)
	for cell in by.trail:
		if cell.distance_to(Vector2(st.center)) < 110.0 and cell.distance_to(Vector2(st.center)) > 50.0 and goal.x == -1048576:
			var r := RegionTravel.plan(w, start, cell)
			if bool(r.ok) and not bool(r.direct):
				var ks := {}
				for c in r.cells:
					ks[RegionRoads.cell_kind(ow, Vector2i(c))] = true
				if ks.has("stone") and ks.has("road") and ks.has("trail"):
					goal = cell
	check(goal.x != -1048576, "a destination on a trail whose route crosses stone, dirt road and trail")
	if goal.x != -1048576:
		w.player.pos = Vector2(start) + Vector2(0.5, 0.5)
		var why: String = main.travel.start(main, goal)
		check(why == "", "the travel is planned by the existing route planner (%s)" % why)
		var walked := {}
		var n := 0
		while RegionTravel.has_destination(w.player) and n < 1500:
			_frames(1)
			walked[RegionRoads.cell_kind(ow, Vector2i(w.player.pos.floor()))] = true
			n += 1
		check(not RegionTravel.has_destination(w.player) and w.player.pos.distance_to(Vector2(goal) + Vector2(0.5, 0.5)) < 2.5, "the character walks it to the end (%d frames)" % n)
		check(walked.has("stone") and walked.has("road") and walked.has("trail"), "walking on stone, dirt road and trail alike (%s)" % str(walked.keys()))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
