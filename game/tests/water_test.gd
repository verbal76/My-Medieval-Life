extends SceneTree
## B25R1-Q3 (owner 2026-11-03: streams in the overworld, waterfalls into pools, bridges where roads cross, water to use),
## overworld generator version 4, headless:  godot --headless --path game --script res://tests/water_test.gd
## Old worlds keep their maps (generation 3 exactly as before, by golden hashes recorded before streams existed), a save
## of a generation-3 world loads as generation 3; generation 4 is deterministic, has streams, waterfalls and bridges, water is
## solid and bridges walkable, every road stays walkable and joined, the village and settlements are never touched, the
## water query answers, and the Region map has the streams and bridges.

var main
var checks := 0
var failures := 0
# md5 of seven chunks per seed (ground, path, deco, solid, kind, snow, top, trees), generation 3, recorded on wip/b25r1 at
# 1fe530d before the streams were added
const GOLDEN_3 := {1: "4f4eae43380bb0c6444d2dee8f8118de", 2: "ed2a2fb118007bc7b133260b95c92ed3", 7: "5c957dd6377d14fabb94afffc8ebb8ae"}
const CHUNKS := [Vector2i(-3, 2), Vector2i(1, 4), Vector2i(2, 9), Vector2i(-2, -3), Vector2i(5, 1), Vector2i(0, 20), Vector2i(-6, 12)]


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
	main.save_path = "user://test_saves/water_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


static func fingerprint(ow: Overworld, with_water := false) -> String:
	var parts := PackedStringArray()
	for cc in CHUNKS:
		var ch := ow.get_chunk(cc)
		parts.append(str(ch.ground) + str(ch.path) + str(ch.deco) + str(ch.solid) + str(ch.kind) + str(ch.snow) + str(ch.top) + str(ch.trees)
			+ (str(ch.water) if with_water else ""))
	return "|".join(parts).md5_text()


func _old(s: int) -> Overworld:
	var ow := Overworld.create(s, main.map)
	ow.load_dict({"seed": s, "gen": 3, "changes": [], "rocks": [], "flowers": [], "works": []})
	return ow


func _run() -> void:
	main.set_process(false)
	var m: VillageMap = main.map if main.map != null else VillageMap.load_default()
	if main.map == null:
		main.map = m
	# --- old worlds keep their maps
	for s in GOLDEN_3:
		check(fingerprint(_old(s)) == GOLDEN_3[s], "seed %d, a generation-3 world: every chunk exactly as before the streams" % s)
	var o3 := _old(1)
	check(o3.gen == 3 and o3.streams_in(Rect2i(-500, -500, 1500, 2000)).is_empty() and not o3.is_water(Vector2i(108, 189)), "a generation-3 world has no streams and no water")
	check(o3.nearest_water(Vector2i(108, 189), 40) == Overworld.NO_WATER, "and its water query answers none (wells are the fallback)")
	check(int(o3.to_dict().gen) == 3, "and it is saved as generation 3 again")
	var o1 := _old(1)
	o1.load_dict({"gen": 1})
	check(o1.gen == 3, "a generation-1 or -2 save is drawn as generation 3, as it was")
	# --- generation 4: deterministic, streams there
	var a := Overworld.create(1, m)
	var b := Overworld.create(1, m)
	check(a.gen == Overworld.GEN_VERSION and Overworld.GEN_VERSION == 4, "a new world is generation 4")
	var fa := fingerprint(a, true)
	check(fa == fingerprint(b, true), "generation 4 is deterministic (the same seed, the same chunks and water)")
	var b2 := Overworld.create(1, m)
	for cc in [Vector2i(9, 9), Vector2i(-9, 3), Vector2i(4, 14)]:
		b2.get_chunk(cc)                                # other chunks first: a chunk never depends on what was made before it
	check(fingerprint(b2, true) == fa, "and independent of the order chunks are made in")
	var area := Rect2i(-160, 90, 420, 520)
	var n := {"water": 0, "bridge": 0, "fall": 0, "ford": 0}
	var ford_bad := 0
	var bad_solid := 0
	var near_places := 0
	var bridge_bad := 0
	var bridges: Array[Vector2i] = []
	for cy in range(Overworld.fdiv(area.position.y, 32), Overworld.fdiv(area.end.y, 32) + 1):
		for cx in range(Overworld.fdiv(area.position.x, 32), Overworld.fdiv(area.end.x, 32) + 1):
			if a.chunk_in_village(Vector2i(cx, cy)):
				continue
			var ch := a.get_chunk(Vector2i(cx, cy))
			for i in 1024:
				var c := Vector2i(cx * 32 + i % 32, cy * 32 + i / 32)
				var wv: int = ch.water[i]
				if wv == 0:
					continue
				if a._rdist(a.village, c.x, c.y) < Overworld.VILLAGE_CLEAR or a.sites.any(func(st): return a._rdist(st.rect, c.x, c.y) < Overworld.VILLAGE_CLEAR):
					near_places += 1
				match wv:
					4:
						n.ford += 1
						if a.is_solid(c) or not a.is_ford(c) or not a.is_water(c):
							ford_bad += 1
					1, 3:
						n["water" if wv == 1 else "fall"] += 1
						if not a.is_solid(c) or not a.is_water(c):
							bad_solid += 1
					2:
						n.bridge += 1
						bridges.append(c)
						if a.is_solid(c) or not a.is_road(c) or a.is_water(c) or not a.is_bridge(c):
							bridge_bad += 1
	check(n.water > 1000 and n.fall > 0 and n.bridge > 0, "generation 4 has streams, waterfalls and bridges round the village (%s)" % str(n))
	check(bad_solid == 0, "every stream, pool and waterfall cell is water and solid (%d not)" % bad_solid)
	check(n.ford > 0 and ford_bad == 0, "streams have fords, stepping stones walked across (%d cells, %d not walkable)" % [n.ford, ford_bad])
	check(bridge_bad == 0, "every bridge is a road cell, walkable, not water (%d not)" % bridge_bad)
	check(near_places == 0, "no water within %d tiles of the village or a settlement (%d cells)" % [Overworld.VILLAGE_CLEAR, near_places])
	# --- the roads stay walkable and joined
	var off := 0
	var sampled := 0
	for seg in RegionRoads.segments(a, area):
		var cells: PackedInt32Array = seg.cells
		for q in range(0, cells.size() / 2, 2):
			var c := Vector2i(cells[q * 2], cells[q * 2 + 1])
			if a.village.has_point(c):
				continue
			sampled += 1
			if a.is_solid(c):
				off += 1
	check(sampled > 300 and off == 0, "every road cell is walkable, bridges included (%d sampled, %d not)" % [sampled, off])
	var joined := 0
	for st in a.sites:
		var r := a.road_route(Journeys.gate_index(main.world) if main.world != null else 2, str(st.id))
		if not r.is_empty() and not Array(r).any(func(c): return a.is_solid(Vector2i(c))):
			joined += 1
	check(joined == a.sites.size(), "the road from the village to every settlement is open all the way (%d of %d)" % [joined, a.sites.size()])
	# --- pathing: across a stream by its bridge, never through water
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var br := Vector2i.ZERO
	var c0 := Overworld.chunk_of(ow.village.get_center())
	for r in range(2, 12):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if br != Vector2i.ZERO or maxi(absi(dx), absi(dy)) != r or ow.chunk_in_village(c0 + Vector2i(dx, dy)):
					continue
				var ch := ow.get_chunk(c0 + Vector2i(dx, dy))
				for i in 1024:
					if ch.water[i] == 2 and br == Vector2i.ZERO:
						br = (c0 + Vector2i(dx, dy)) * 32 + Vector2i(i % 32, i / 32)
	check(br != Vector2i.ZERO, "a bridge near the village to cross (%s)" % br)
	if br != Vector2i.ZERO:
		# the bridge's cells (joined) and the road cells touching them: the two of those furthest apart are its two ends
		var span := {br: true}
		var todo: Array[Vector2i] = [br]
		var k := 0
		var shore: Array[Vector2i] = []
		while k < todo.size():
			var at: Vector2i = todo[k]
			k += 1
			for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
				var nb: Vector2i = at + d
				if span.has(nb):
					continue
				if ow.is_bridge(nb):
					span[nb] = true
					todo.append(nb)
				elif ow.is_road(nb) and not ow.is_solid(nb) and not shore.has(nb):
					shore.append(nb)
		var e1 := br
		var e2 := br
		for x in shore:
			for y in shore:
				if x.distance_to(y) > e1.distance_to(e2):
					e1 = x
					e2 = y
		var path := w.map.find_path_world(e1, e2)
		var wet := 0
		var over := 0
		for c in path:
			if ow.is_water(Vector2i(c)):
				wet += 1
			if ow.is_bridge(Vector2i(c)):
				over += 1
		check(not path.is_empty() and Vector2i(path[path.size() - 1]) == e2 and wet == 0 and over > 0, "the pathfinder crosses the stream from %s to %s, over the bridge, never on water (%d water cells, %d bridge cells walked)" % [e1, e2, wet, over])
		var plan := RegionTravel.plan(w, Vector2i(w.player.pos.floor()), br + Vector2i(0, 0))
		check(bool(plan.ok), "the travel planner reaches the bridge (%s)" % str(plan.get("why", "")))
		var wplan := RegionTravel.plan(w, Vector2i(w.player.pos.floor()), ow.nearest_water(br, 6))
		check(bool(wplan.ok) and Vector2i(wplan.dest) != ow.nearest_water(br, 6) and not ow.is_water(Vector2i(wplan.dest)), "a tap on the water itself plans to the open bank beside it")
	for st in ow.sites:
		check(bool(RegionTravel.plan(w, Vector2i(w.player.pos.floor()), Vector2i(st.slots[0].spot)).ok), "%s is still reached from home" % st.name)
	# --- water as a resource
	var near := ow.nearest_water(br + Vector2i(0, 0), 8) if br != Vector2i.ZERO else Overworld.NO_WATER
	check(near != Overworld.NO_WATER and ow.is_water(near), "nearest_water finds the stream (%s)" % near)
	var bank := ow.nearest_water_access(br, 8)
	check(bank != Overworld.NO_WATER and not ow.is_solid(bank) and Vector2(bank).distance_to(Vector2(near)) < 1.5, "nearest_water_access gives an open cell beside it to drink from (%s)" % bank)
	check(ow.nearest_water(ow.village.get_center(), 10) == Overworld.NO_WATER, "none inside the village (wells are the fallback there)")
	# --- a saved generation-4 world loads as generation 4; a generation-3 save keeps its map
	check(main.save_game(false), "saved")
	var d := SaveStore.inspect(main.save_path, World.SAVE_VERSION)
	check(int(d.data.overworld.gen) == 4, "a new world's save says generation 4")
	d.data.overworld.gen = 3
	main._load_save(d.data)
	main.ui.hide_all()
	var ow3: Overworld = main.world.map.overworld
	check(ow3.gen == 3 and not ow3.is_water(near) and ow3.streams_in(Rect2i(-500, -500, 1500, 2000)).is_empty(), "the same save marked generation 3 loads as generation 3: no water")
	var ref := _old(ow3.seed)
	var same := 0
	for cc in CHUNKS:
		if str(ow3.get_chunk(cc).ground) == str(ref.get_chunk(cc).ground) and str(ow3.get_chunk(cc).solid) == str(ref.get_chunk(cc).solid):
			same += 1
	check(same == CHUNKS.size(), "and its chunks are generation 3's, unchanged (%d of %d)" % [same, CHUNKS.size()])
	# --- the Region map
	var bounds := RegionMapPanel.region_bounds(w, w.player)
	var sts := ow.streams_in(bounds)
	check(sts.size() >= 3, "the Region map has the streams (%d)" % sts.size())
	check(not RegionMapPanel.bridge_points(ow, sts, bounds).is_empty(), "and the bridges where the roads cross them (%d)" % RegionMapPanel.bridge_points(ow, sts, bounds).size())
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
