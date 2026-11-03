extends SceneTree
## B25R1-Q3 (owner 2026-11-03: streams in the overworld, waterfalls into pools, bridges where roads cross, water to use),
## overworld generator version 4, headless:  godot --headless --path game --script res://tests/water_test.gd
## Generation 4 (the region rebuilt, B25R1-018, with the water on it) is pinned by golden hashes; an older world's save is
## refused (owner B25R1-Q5); generation 4 is deterministic, has streams, waterfalls and bridges, water is
## solid and bridges walkable, every road stays walkable and joined, the village and settlements are never touched, the
## water query answers, and the Region map has the streams and bridges.

var main
var checks := 0
var failures := 0
# md5 of seven chunks per seed (ground, path, deco, solid, kind, snow, top, trees, water), generation 4, recorded on
# wip/b25r1-water after merging the region fix (a8d3886) and the EA-01 polish: any change to the generator's output changes these
const GOLDEN_4 := {1: "f3789cea5de73f30a6209dec0e4b0b5d", 2: "0739c0958e0a3543ad859415a29da4ba", 7: "42f5b6f4f0c113d9159d8cf2983161f1"}
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


func _run() -> void:
	main.set_process(false)
	var m: VillageMap = main.map if main.map != null else VillageMap.load_default()
	if main.map == null:
		main.map = m
	# --- generation 4 pinned
	for s in GOLDEN_4:
		var fp := fingerprint(Overworld.create(s, m), true)
		check(fp == GOLDEN_4[s], "seed %d, generation 4: every chunk and its water as recorded (%s)" % [s, fp])
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
	var passed := {}
	for cc in a.anchored_courses():
		for sid in cc.get("passes", []):
			passed[str(sid)] = true
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
				# never on built ground; within the clearance only beside a settlement a canonical course passes (the layout's
				# passes_settlement: the Netherton stream, the river round Higham)
				if a._rdist(a.village, c.x, c.y) < Overworld.VILLAGE_CLEAR - 1 or a.sites.any(func(st): return a._rdist(st.rect, c.x, c.y) < (1 if passed.has(str(st.id)) else Overworld.VILLAGE_CLEAR - 1)):
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
	check(n.water > 1000 and n.bridge > 0, "generation 4 has streams and bridges round the village (%s; the falls are checked where the courses drop, below)" % str(n))
	check(bad_solid == 0, "every stream, pool and waterfall cell is water and solid (%d not)" % bad_solid)
	check(n.ford > 0 and ford_bad == 0, "streams have fords, stepping stones walked across (%d cells, %d not walkable)" % [n.ford, ford_bad])
	check(bridge_bad == 0, "every bridge is a road cell, walkable, not water (%d not)" % bridge_bad)
	check(near_places == 0, "no water on any settlement's ground, nor within %d tiles of the village or a settlement a canonical course does not pass (%d cells)" % [Overworld.VILLAGE_CLEAR, near_places])
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
		var sp := RegionTravel.plan(w, Vector2i(w.player.pos.floor()), Vector2i(st.slots[0].spot))
		check(bool(sp.ok), "%s is still reached from home (%s %s %s)" % [st.name, st.slots[0].spot, sp.get("why", ""), sp.get("reason", "")])
	# --- water as a resource
	var near := ow.nearest_water(br + Vector2i(0, 0), 8) if br != Vector2i.ZERO else Overworld.NO_WATER
	check(near != Overworld.NO_WATER and ow.is_water(near), "nearest_water finds the stream (%s)" % near)
	var bank := ow.nearest_water_access(br, 8)
	check(bank != Overworld.NO_WATER and not ow.is_solid(bank) and Vector2(bank).distance_to(Vector2(near)) < 1.5, "nearest_water_access gives an open cell beside it to drink from (%s)" % bank)
	check(ow.nearest_water(ow.village.get_center(), 10) == Overworld.NO_WATER, "none inside the village (wells are the fallback there)")
	# --- a saved generation-4 world says so; an older generation's save is refused (owner B25R1-Q5)
	check(main.save_game(false), "saved")
	var d := SaveStore.inspect(main.save_path, World.SAVE_VERSION)
	check(int(d.data.overworld.gen) == 4, "a new world's save says generation 4")
	var w3 := World.new()
	w3.load_dict(m, {"seed": 1, "save_version": World.SAVE_VERSION, "overworld": {"seed": 1, "gen": 3}})
	check(not w3.load_error.is_empty(), "a generation-3 save is refused with a message, not drawn (%s)" % w3.load_error)
	# --- B25R1-017: rivers and streams, a connected network, flowing downhill
	check(Overworld.NO_WATER == Vector2i(1 << 30, 0), "nearest_water's none is Vector2i(1 << 30, 0), the agreed signature")
	var big := Rect2i(-260, -200, 640, 1200)
	var courses := ow.streams_in(big)
	var rivers := courses.filter(func(c): return int(c.order) == 2)
	var graph := ow.course_graph(big)
	var fed := 0
	var uphill := 0
	for c in courses:
		if str(c.joins) != "":
			fed += 1
		if c.has("canonical"):
			continue                                   # a canonical course follows the novel's geography (checked below)
		var pts: Array = c.pts
		for q in range(2, pts.size(), 2):
			if ow._height(Vector2i((pts[q] as Vector2).round())) > ow._height(Vector2i((pts[q - 2] as Vector2).round())) + 6:
				uphill += 1
	check(rivers.size() >= 2 and courses.size() > rivers.size(), "rivers and streams both (%d rivers, %d courses)" % [rivers.size(), courses.size()])
	check(fed >= 2 and rivers.any(func(r): return not (graph[r.id].tributaries as Array).is_empty()), "streams feed rivers: a network (%d streams join a river)" % fed)
	check(uphill == 0, "every generated course runs downhill, step by step (%d steps up)" % uphill)
	# --- B25R1-018: the canonical water (game/data/region_layout.json)
	var canon := {}
	for c in ow.anchored_courses():
		canon[str(c.id)] = c
	check(canon.has("canon:upmeads_water") and canon.has("canon:netherton_stream") and canon.has("canon:coldlake") and canon.has("canon:st_ann_pool"),
		"the region layout's water is there: Upmeads Water, the Netherton stream, Coldlake round Higham, the chapel pool on the Downs (%s)" % str(canon.keys()))
	if canon.has("canon:netherton_stream"):
		check(str(canon["canon:netherton_stream"].joins) == "canon:upmeads_water", "the Netherton stream runs into Upmeads Water")
	if canon.has("canon:upmeads_water"):
		var up: Array = canon["canon:upmeads_water"].pts
		check((up[up.size() - 1] as Vector2).x > (up[0] as Vector2).x + 400.0 and int(canon["canon:upmeads_water"].order) >= 2,
			"Upmeads Water is a river flowing west to east past the village (%s -> %s)" % [up[0], up[up.size() - 1]])
		var east := 0
		for cy in range(Overworld.fdiv(int((up[0] as Vector2).y) - 20, 32), Overworld.fdiv(int((up[0] as Vector2).y) + 40, 32) + 1):
			for cx in range(Overworld.fdiv(-200, 32), Overworld.fdiv(300, 32) + 1):
				if ow.chunk_in_village(Vector2i(cx, cy)):
					continue
				var ch := ow.get_chunk(Vector2i(cx, cy))
				for i in 1024:
					if ch.water[i] != 0 and ch.level[i] >= 2 and (ch.flow[i] == 1 or ch.flow[i] == 2 or ch.flow[i] == 8):
						east += 1
		check(east > 200, "its water flows east (%d river cells running E, SE or NE)" % east)
	var kinds := {}
	var on_roads := 0
	var ok_x := 0
	for f in ow._forced:
		var at: Vector2 = f[0]
		var got := ""
		var road_there := false
		for dy in range(-6, 7):
			for dx in range(-6, 7):
				var c := Vector2i(at.floor()) + Vector2i(dx, dy)
				if not ow.is_road(c):
					continue
				road_there = true
				if ow.is_bridge(c) and got == "":
					got = "bridge"
				elif ow.is_ford(c) and got == "":
					got = "ford"
		kinds[str(f[2]) + "@" + str(Vector2i(at))] = got if road_there else "(no road here yet)"
		if road_there:
			on_roads += 1
			if (str(f[2]) == "ford" and got == "ford") or (str(f[2]) != "ford" and got == "bridge"):
				ok_x += 1
	# the layout's crossings sit on the region workstream's roads; on a branch without them some have no road yet
	check(ow._forced.size() == 5 and ok_x == on_roads, "each of the layout's 5 crossings with a road through it is that crossing (%d of %d with a road): %s" % [ok_x, on_roads, str(kinds)])
	var stone_drawn := false
	var view_ow: Overworld = main.ow_view.overworld
	main.ow_view.overworld = ow                       # the view's tile choice for this world's cells (the save test loaded another)
	for f in ow._forced:
		if str(f[2]) != "stone_bridge":
			continue
		for dy in range(-6, 7):
			for dx in range(-6, 7):
				var c := Vector2i((f[0] as Vector2).floor()) + Vector2i(dx, dy)
				if ow.is_bridge(c) and ow.forced_crossing(c) == "stone_bridge":
					var t: int = main.ow_view.road_tile(c, -1)
					if t == int(ow.tiles.water.bridge.stone_ns) or t == int(ow.tiles.water.bridge.stone_ew):
						stone_drawn = true
	main.ow_view.overworld = view_ow
	check(stone_drawn or not str(kinds).contains("stone_bridge@(20, 830)\": \"bridge"), "a stone bridge of the layout is drawn in stone (where its road is)")
	var downs_water := 0
	var downs_springs := 0
	for c in ow.streams_in(Rect2i(-500, ow._downs.position.y, 1100, ow._downs.size.y)):
		if c.has("canonical"):
			continue                                   # the canon's own water (the river round Higham reaches the Downs' edge)
		for pt in c.pts:
			if ow.in_downs(Vector2i((pt as Vector2).round())):
				downs_water += 1
		if ow.in_downs(Vector2i((c.pts[0] as Vector2).round())):
			downs_springs += 1
	check(ow._downs.has_area() and downs_water == 0 and downs_springs == 0, "the Downs are waterless: no generated course rises or runs there (%d points, %d springs)" % [downs_water, downs_springs])
	var rv: Dictionary = rivers[0] if not rivers.is_empty() else {}
	check(not rv.is_empty() and float(graph[rv.id].catchment) >= float(rv.length) and int(graph[rv.id].order) == 2, "the course graph keeps order, length and catchment (%s)" % str(graph.get(rv.get("id", ""), {})))
	# per cell: flow, level, bank
	var flows := {}
	var lv := {}
	var banks := 0
	var fall_rim := 0
	var nfalls := 0
	var foam_near_fall := 0
	for cy in range(Overworld.fdiv(area.position.y, 32), Overworld.fdiv(area.end.y, 32) + 1):
		for cx in range(Overworld.fdiv(area.position.x, 32), Overworld.fdiv(area.end.x, 32) + 1):
			if a.chunk_in_village(Vector2i(cx, cy)):
				continue
			var ch := a.get_chunk(Vector2i(cx, cy))
			for i in 1024:
				var c := Vector2i(cx * 32 + i % 32, cy * 32 + i / 32)
				if ch.water[i] != 0:
					flows[int(ch.flow[i])] = int(flows.get(int(ch.flow[i]), 0)) + 1
					lv[int(ch.level[i])] = true
				elif ch.bank[i] >= 1 and ch.bank[i] <= Overworld.BANK_REACH:
					banks += 1
				if ch.water[i] == 3:
					nfalls += 1
					# a genuine drop: a mountain top just above (inside the rim), and no top just below: the water leaves the
					# raised ground over its edge
					if (a.is_top(c + Vector2i(0, -1)) or a.is_top(c + Vector2i(0, -2))) and not a.is_top(c + Vector2i(0, 1)) and a.is_solid(c):
						fall_rim += 1
					for dd in range(1, 5):
						if a.flow_at(c + Vector2i(0, dd)) == Overworld.FLOW_FOAM:
							foam_near_fall += 1
							break
	# the region layout (B25R1-018) leaves no cliff a course crosses near the village: the falls are looked for along the
	# courses across the region (nearest_fall at every few points)
	var fall_chunks := {}
	for crs in a.streams_in(Rect2i(-700, -450, 1400, 1600)):
		var pts: Array = crs.pts
		for pi in range(0, pts.size(), 2):
			if fall_chunks.size() >= 6:
				break
			var f := a.nearest_fall(Vector2i(pts[pi]), 7)
			if f != Overworld.NO_WATER:
				fall_chunks[Overworld.chunk_of(f)] = true
	var feet := 0
	for cc: Vector2i in fall_chunks:
		var ch := a.get_chunk(cc)
		for i in 1024:
			var c := Vector2i(cc.x * 32 + i % 32, cc.y * 32 + i / 32)
			if ch.water[i] == 3:
				nfalls += 1
				if (a.is_top(c + Vector2i(0, -1)) or a.is_top(c + Vector2i(0, -2))) and not a.is_top(c + Vector2i(0, 1)) and a.is_solid(c):
					fall_rim += 1
				for dd in range(1, 5):
					if a.flow_at(c + Vector2i(0, dd)) == Overworld.FLOW_FOAM:
						foam_near_fall += 1
						break
				var below := c + Vector2i(0, 1)
				var bch := a.get_chunk(Overworld.chunk_of(below))
				if a.is_water(below) and int(bch.ground[(below.y - Overworld.chunk_of(below).y * 32) * 32 + below.x - Overworld.chunk_of(below).x * 32]) == int(a.tiles.water.fall_foot):
					feet += 1
	check(feet > 0, "EA-01: a fall runs on into the cell below it, its foot drawn with the cascade and splash (%d of %d falls)" % [feet, nfalls])
	var moving := 0
	for f in range(1, 9):
		moving += int(flows.get(f, 0))
	check(moving > 1000, "the water flows: %d cells carry a downstream direction (%s)" % [moving, str(flows)])
	check(lv.has(1) and lv.has(2), "levels: streams 1, rivers 2 (%s)" % str(lv.keys()))
	check(banks > 500, "dry cells beside the water keep their bank height, the floodplain (%d)" % banks)
	check(nfalls > 0 and fall_rim == nfalls, "every waterfall is a genuine drop: a mountain top just above it, low ground below (%d of %d)" % [fall_rim, nfalls])
	check(int(flows.get(Overworld.FLOW_FOAM, 0)) > 0 and foam_near_fall > 0, "a foaming pool below the falls (%d foam cells; %d falls with foam just below)" % [int(flows.get(Overworld.FLOW_FOAM, 0)), foam_near_fall])
	# the weather hooks: nothing changes the water now; set_level and on_level_changed are there for it
	var heard := []
	ow.on_level_changed = func(c, o, n): heard.append([c, o, n])
	var wcell := ow.nearest_water(br, 8) if br != Vector2i.ZERO else Vector2i.ZERO
	var lvl0 := ow.water_level(wcell)
	ow.set_level(wcell, lvl0 + 1.0)
	check(heard.size() == 1 and is_equal_approx(ow.water_level(wcell), lvl0 + 1.0), "set_level and on_level_changed: the flood hooks answer (%s)" % str(heard))
	ow.level_override.clear()
	ow.on_level_changed = Callable()
	check(is_equal_approx(ow.seasonal_flow, 1.0) and ow.water_level(wcell) == lvl0, "and the water is constant otherwise (seasonal_flow 1)")
	# stable crossing ids for the flight recorder
	if br != Vector2i.ZERO:
		var id := ow.crossing_id(br)
		var fresh := Overworld.create(ow.seed, main.map)
		check(id.begins_with("crossing:bridge:") and fresh.crossing_id(br) == id, "a bridge's crossing id is stable (%s, the same in a fresh world)" % id)
	check(GameAudio.water_volume(1.0, 2.0, 12.0) == 1.0 and GameAudio.water_volume(7.0, 2.0, 12.0) > 0.0 and GameAudio.water_volume(13.0, 2.0, 12.0) == 0.0,
		"the water sound is loudest beside the water and silent far off")
	# --- the Region map
	var bounds := RegionMapPanel.region_bounds(w, w.player)
	var sts := ow.streams_in(bounds)
	check(sts.size() >= 3, "the Region map has the streams (%d)" % sts.size())
	check(not RegionMapPanel.bridge_points(ow, sts, bounds).is_empty(), "and the bridges where the roads cross them (%d)" % RegionMapPanel.bridge_points(ow, sts, bounds).size())
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
