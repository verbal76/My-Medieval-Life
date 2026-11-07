extends SceneTree
## Probe (owner's playtest 2026-11-07, "freeze every other step south of the starter village"): the real game scene, seed 1 (every
## new game's world), the player walked at walking speed from the village gate to the settlement nearest due south and through it.
## Every frame's wall time is measured; for each frame over SPIKE_MS, the world's own subsystems (World.prof) and the frame's place.
## Diagnostics only: changes nothing.
##   godot --headless --path game -s res://tests/stutter_probe.gd [-- seconds=120]

const SPIKE_MS := 50.0
var main
var t_last := 0
var frames := 0
var spikes: Array = []
var route: PackedVector2Array
var idx := 1
var limit := 150.0
var t_game := 0.0
var site := {}
var prof0 := {}
var chunks0 := {}
var nodes0 := 0
var b0 := 0
var tiles0 := 0
var t_pre := 0
var t_post := 0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seconds="):
			limit = float(a.substr(8))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://stutter_probe/save.json"
	process_frame.connect(_begin, CONNECT_ONE_SHOT)


func _begin() -> void:
	main.new_game()
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var home := Vector2(ow.village.get_center())
	var best := INF
	for st in ow.sites:
		var d := Vector2(st.center) - home
		if d.y > 20 and absf(d.x) < d.y and d.length() < best:
			best = d.length()
			site = st
	print("home %s; site south: %s at %s (%.0f tiles)" % [str(home), str(site.get("name", "?")), str(site.get("center", "?")), best])
	var gate := Vector2i(ow.gates[0].out)
	for g in ow.gates:
		if Vector2(g.out).y > Vector2(gate).y:
			gate = Vector2i(g.out)
	var r := RegionTravel.plan(w, gate, Vector2i(site.center))
	print("route ok=%s cells=%d from gate %s" % [str(r.ok), (r.get("cells", []) as PackedVector2Array).size(), str(gate)])
	route = r.cells
	w.player.pos = route[0] + Vector2(0.5, 0.5)
	w.profiling = true
	if OS.get_cmdline_user_args().has("noaerial"):
		main.aerial_background = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("off="):
			for n in main.get_children():
				if str(n.name) == a.substr(4) or a.substr(4) == "list":
					if a.substr(4) != "list":
						n.process_mode = Node.PROCESS_MODE_DISABLED
					print("child %s (%s) descendants %d" % [n.name, n.get_class(), n.find_children("*", "", true, false).size()])
	if OS.get_cmdline_user_args().has("notrees"):
		main.ow_view.tree_sink = null
	t_last = Time.get_ticks_usec()
	process_frame.connect(_frame)
	RenderingServer.frame_pre_draw.connect(func(): t_pre = Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func(): t_post = Time.get_ticks_usec())


func _frame() -> void:
	var now := Time.get_ticks_usec()
	if OS.get_cmdline_user_args().has("forcetiles"):
		var worst := [0, ""]
		var tot := 0
		for l in main.find_children("*", "TileMapLayer", true, false):
			var a := Time.get_ticks_usec()
			(l as TileMapLayer).update_internals()
			var d := Time.get_ticks_usec() - a
			tot += d
			if d > int(worst[0]):
				worst = [d, "%s (%s) %d cells, y_sort %s, parent %s" % [l.name, l.get_path(), (l as TileMapLayer).get_used_cells().size(), str(l.y_sort_enabled), l.get_parent().name]]
		if tot > 20000:
			print("TILES %.0f ms; worst %.0f ms: %s" % [tot / 1000.0, int(worst[0]) / 1000.0, worst[1]])
		now = Time.get_ticks_usec()
	var ms := (now - t_last) / 1000.0
	var t_prev := t_last
	t_last = now
	frames += 1
	var w: World = main.world
	if frames > 30 and ms > SPIKE_MS:
		var top := []
		for k in w.prof:
			var us := int(w.prof[k].us) - int(prof0.get(k, {}).get("us", 0))
			if us > 5000:
				top.append([us / 1000.0, k])
		top.sort()
		top.reverse()
		spikes.append([ms, t_game, w.player.pos, top.slice(0, 5)])
		var mt := []
		var pt: Dictionary = main.get("__pt") if main.get("__pt") != null else {}
		for k in pt:
			if not str(k).begins_with("__") and int(pt[k]) > 5000:
				mt.append([int(pt[k]) / 1000, k])
		mt.sort()
		mt.reverse()
		var cur: Dictionary = main.ow_view.chunks
		var built := cur.keys().filter(func(c): return not chunks0.has(c)).size()
		var freed := chunks0.keys().filter(func(c): return not cur.has(c)).size()
		var pts: Dictionary = main.get("__pt") if main.get("__pt") != null else {}
		mt.append(["main end->pre_draw %.0f, draw %.0f, post->next %.0f" % [(t_pre - int(pts.get("__end", 0))) / 1000.0, (t_post - t_pre) / 1000.0, (now - t_post) / 1000.0], ""])
		mt.append(["NEW TILES %d" % (_tiles() - tiles0), ""])
		mt.append(["tiles forced at main's end %.0f ms" % (int(pts.get("__tiles", 0)) / 1000.0), ""])
		mt.append(["main %.0f ms, before main %.0f, after main %.0f" % [(int(pts.get("__end", 0)) - int(pts.get("__start", 0))) / 1000.0, (int(pts.get("__start", 0)) - t_prev) / 1000.0, (now - int(pts.get("__end", now))) / 1000.0], ""])
		mt.append(["chunks +%d -%d, nodes %+d, build %d ms, process %.0f ms, physics %.0f ms, nav %.0f" % [built, freed, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - nodes0, (int(main.ow_view.build_usec) - b0) / 1000, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS) * 1000.0], ""])
		if spikes.size() <= 40:
			print("SPIKE %.0f ms at t=%.1fs pos=%s main: %s world: %s" % [ms, t_game, str(w.player.pos.floor()), str(mt), str(top.slice(0, 3))])
	prof0 = w.prof.duplicate(true)
	chunks0 = (main.ow_view.chunks as Dictionary).duplicate()
	nodes0 = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	b0 = int(main.ow_view.build_usec)
	tiles0 = _tiles()
	var dt := 1.0 / 60.0
	t_game += dt
	var speed := float(GameData.b("player_tiles_per_second"))
	var p := w.player
	if idx < route.size():
		var target := route[idx] + Vector2(0.5, 0.5)
		if p.pos.distance_to(target) <= speed * dt:
			p.pos = target
			idx += 1
		else:
			p.pos += (target - p.pos).normalized() * speed * dt
	if idx >= route.size() or t_game > limit:
		print("frames %d, spikes over %d ms: %d, game seconds %.0f, reached waypoint %d of %d" % [frames, int(SPIKE_MS), spikes.size(), t_game, idx, route.size()])
		quit(0)


func _tiles() -> int:
	var n := 0
	var ts: TileSet = main.ow_view.tileset
	for i in ts.get_source_count():
		var src := ts.get_source(ts.get_source_id(i))
		n += src.get_tiles_count()
	return n
