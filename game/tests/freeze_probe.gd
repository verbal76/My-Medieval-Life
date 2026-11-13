extends SceneTree
## B25-MOVE-STUTTER-INV (owner 2026-11-13, "step, freeze, step, freeze ... the whole game freezes momentarily and then catches
## up"): a measurement probe, diagnostics only. The real game scene (main.tscn), a new game (seed 1, every new game's world), the
## player walked by the movement actions themselves (Input.action_press, so main._player_step, collision and the camera run as in
## play) from the middle of the starter village, out of its south gate, across the open country to the settlement nearest due
## south (Wendholt on seed 1) and on through it, then back and forth inside it. Every frame is written to a CSV: wall time,
## the game delta, world ticks taken, the world's subsystems (World.prof deltas), main._process's parts (main.frame_prof), the
## player's place and step, chunks built, tiles made. Changes nothing in the game (both profilers only read the clock).
##   godot --headless --path game [--fixed-fps 60] -s res://tests/freeze_probe.gd -- csv=/abs/path.csv [seconds=150] [stay=20]
## With --fixed-fps 60 every frame's delta is 1/60 s (deterministic: the same world each run, wall time measured); without it
## the delta is the real frame time (as on a device), which shows what the frame after a long one does (the catch-up).

var main
var csv: FileAccess
var route: PackedVector2Array
var idx := 1
var limit := 150.0
var stay := 20.0
var t_game := 0.0
var frames := 0
var t_last := 0
var prof0 := {}
var ticks0 := 0
var b0 := 0
var tiles0 := 0
var pos0 := Vector2.ZERO
var stuck := 0.0
var snaps := 0
var site := {}
var inside_until := -1.0
var back_forth: Array = []
var bf_i := 0
var keys_world := ["hourly (incl. daily)", "villagers (all)", "villagers: decide", "villagers: run plan (incl. walking)", "fauna",
		"carts", "player", "presence", "neighbouring settlements (a step an hour, mornings)"]
var keys_main := ["pre (audio, view report)", "world.update", "player_step", "projectiles, look, aerial", "autosave", "fx",
		"sync_sprites (incl. ow_view.follow)", "levels, marks, outlines", "hud",
		"ss:doors, pose, signs, canopy", "ss:tree_view", "ss:ow_view.follow"]
var keys_ow := ["ow:recentre+free", "ow:build", "ow:prefetch", "ow:road_step", "ow:live_step", "ow:works+homes", "ow:roofs", "ow:canopy"]
var made_seen := 0
var made_seen_v := 0
var emits: Array = []                 # this frame's World.tile_changed (cell, layer, value), printed when a tile was made
var last_v := Vector2.ZERO
var delta_prev := 0.0
var t_pre := 0                        # RenderingServer's draw of the frame just finished (headless: nothing drawn)
var t_post := 0


func _init() -> void:
	var path := "user://freeze_probe.csv"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seconds="):
			limit = float(a.substr(8))
		elif a.begins_with("stay="):
			stay = float(a.substr(5))
		elif a.begins_with("csv="):
			path = a.substr(4)
	csv = FileAccess.open(path, FileAccess.WRITE)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://freeze_probe/save.json"
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
	var gate := Vector2i(ow.gates[0].out)
	for g in ow.gates:
		if Vector2(g.out).y > Vector2(gate).y:
			gate = Vector2i(g.out)
	# inside the village first: from where a new game puts the player to the south gate, by the game's own route finder
	var r0 := RegionTravel.plan(w, Vector2i(w.player.pos.floor()), gate)
	var r := RegionTravel.plan(w, gate, Vector2i(site.center))
	route = PackedVector2Array()
	if bool(r0.get("ok", false)):
		route.append_array(r0.cells)
	route.append_array(r.cells)
	print("start %s; gate %s; site %s at %s; village leg ok=%s (%d), journey ok=%s (%d)" % [str(w.player.pos), str(gate),
			str(site.get("name", "?")), str(site.get("center", "?")), str(r0.get("ok", false)), (r0.get("cells", []) as Array).size(),
			str(r.ok), (r.get("cells", []) as Array).size()])
	if not bool(r0.get("ok", false)):
		w.player.pos = Vector2(gate) + Vector2(0.5, 0.5)
	if OS.get_cmdline_user_args().has("premake_fields"):
		_premake_fields(w)
	w.profiling = true
	# (set, not assigned: an older commit without these diagnostics just has none, so the same probe measures it)
	main.set("frame_profiling", true)
	main.ow_view.set("profiling", true)
	main.ow_view.set("log_made", true)
	main.view.set("log_made", true)
	w.tile_changed.connect(func(c: Vector2i, layer: String, v: int): emits.append([c, layer, v]))
	main.set("aerial_background", true)
	csv.store_line(",".join(PackedStringArray(["frame", "t_game", "wall_ms", "delta_ms", "ticks", "hour", "minutes", "x", "y",
			"step", "vx", "vy", "level", "where", "chunks_built_ms", "tiles_made", "snap", "nodes", "render_ms"] \
			+ keys_world.map(func(k): return "w:" + k.replace(",", ";")) + keys_main.map(func(k): return "m:" + k.replace(",", ";")) + keys_ow.map(func(k): return "m:" + k))))
	t_last = Time.get_ticks_usec()
	ticks0 = _ticks(w)
	pos0 = w.player.pos
	b0 = int(main.ow_view.build_usec)
	tiles0 = _tiles()
	process_frame.connect(_frame)
	RenderingServer.frame_pre_draw.connect(func(): t_pre = Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func(): t_post = Time.get_ticks_usec())


## Called before main._process each frame: write the frame just finished (its wall time, the world's and main's parts), then
## press the movement keys for this frame.
func _frame() -> void:
	var now := Time.get_ticks_usec()
	var wall := (now - t_last) / 1000.0
	t_last = now
	var w: World = main.world
	frames += 1
	var row := []
	var tiles := _tiles()
	var place := "overworld"
	var at := w.place_of(w.player.pos)
	if w.player.map_level != 0:
		place = "level%d" % w.player.map_level
	elif at != "":
		place = "inside:" + at
	elif w.map.overworld != null and w.map.overworld.village.has_point(Vector2i(w.player.pos.floor())):
		place = "village"
	elif w.map.overworld != null and not w.map.overworld.site_at(Vector2i(w.player.pos.floor())).is_empty():
		place = "site"
	row.append_array([frames, "%.3f" % t_game, "%.3f" % wall, "%.3f" % (delta_prev * 1000.0), _ticks(w) - ticks0,
			int(w.minutes / 60.0) % 24, "%.1f" % w.minutes, "%.3f" % w.player.pos.x, "%.3f" % w.player.pos.y,
			"%.4f" % w.player.pos.distance_to(pos0), "%.2f" % last_v.x, "%.2f" % last_v.y, w.player.map_level, place,
			"%.3f" % ((int(main.ow_view.build_usec) - b0) / 1000.0), tiles - tiles0, snaps,
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "%.3f" % (maxi(0, t_post - t_pre) / 1000.0)])
	for k in keys_world:
		row.append("%.3f" % ((int(w.prof.get(k, {}).get("us", 0)) - int(prof0.get(k, {}).get("us", 0))) / 1000.0))
	for k in keys_main:
		row.append("%.3f" % (int(_dict(main, "frame_prof").get(k, 0)) / 1000.0))
	for k in keys_ow:
		row.append("%.3f" % (int(_dict(main.ow_view, "prof").get(k, 0)) / 1000.0))
	main.ow_view.set("prof", {})
	csv.store_line(",".join(PackedStringArray(row.map(func(x): return str(x)))))
	var ml: Array = main.ow_view.get("made_log") if main.ow_view.get("made_log") != null else []
	while made_seen < ml.size():
		print("MADE frame %d t=%.2f atlas %d index %d animated %s at %s" % [frames, t_game, int(ml[made_seen][0]), int(ml[made_seen][1]), str(ml[made_seen][2]), str(w.player.pos.floor())])
		made_seen += 1
	var mv: Array = main.view.get("made_log") if main.view.get("made_log") != null else []
	while made_seen_v < mv.size():
		print("MADE(village view) frame %d t=%.2f atlas %d index %d" % [frames, t_game, int(mv[made_seen_v][0]), int(mv[made_seen_v][1])])
		made_seen_v += 1
		if made_seen_v == mv.size():
			print("   tile_changed this frame: %s" % str(emits.slice(0, 12)))
	emits.clear()
	prof0 = w.prof.duplicate(true)
	ticks0 = _ticks(w)
	b0 = int(main.ow_view.build_usec)
	tiles0 = tiles
	delta_prev = main.get_process_delta_time()      # the delta of the frame starting now (written with its row next time)
	t_game += delta_prev
	_steer(w)
	pos0 = w.player.pos
	if t_game > limit or (inside_until >= 0.0 and t_game > inside_until):
		csv.close()
		print("frames %d, game seconds %.1f, waypoint %d of %d, snaps %d" % [frames, t_game, idx, route.size(), snaps])
		quit(0)


## Hold the movement actions toward the next waypoint (as a stick would); a player held up a second by a corner is put on the
## waypoint (counted as a snap; the probe's own help, not the game's).
func _steer(w: World) -> void:
	var p := w.player
	if idx >= route.size():
		if inside_until < 0.0:
			inside_until = t_game + stay
			var c := Vector2(site.center) + Vector2(0.5, 0.5)
			back_forth = [c + Vector2(-6, 0), c + Vector2(6, 0), c + Vector2(0, -5), c + Vector2(0, 5)]
			route = PackedVector2Array()
			for i in 8:
				route.append(back_forth[i % 4] - Vector2(0.5, 0.5))
			idx = 0
		else:
			idx = 0
	var target := route[idx] + Vector2(0.5, 0.5)
	if p.pos.distance_to(target) < 0.35:
		idx += 1
		stuck = 0.0
		if idx >= route.size():
			return
		target = route[idx] + Vector2(0.5, 0.5)
	var v := (target - p.pos).normalized()
	last_v = v
	_press("move_right", maxf(v.x, 0.0))
	_press("move_left", maxf(-v.x, 0.0))
	_press("move_down", maxf(v.y, 0.0))
	_press("move_up", maxf(-v.y, 0.0))
	if p.pos.distance_to(pos0) < 0.01:
		stuck += main.get_process_delta_time()
		if stuck > 1.0:
			p.pos = target
			snaps += 1
			stuck = 0.0
	else:
		stuck = 0.0


func _press(a: String, s: float) -> void:
	if s > 0.05:
		Input.action_press(a, s)
	else:
		Input.action_release(a)


## PROBE, not a fix (the experiment that tests the cause): make the 4 x 4 edge variants of every field state's tile (tilled,
## growing, ripe) before the walk, as MapView._make_tile would on first use. If the frames of 100+ ms in play are the TileSet
## changing when a field's new variant is first drawn, they go with this.
func _premake_fields(w: World) -> void:
	var cols := int(w.map.data.atlases[0].columns)
	var made := 0
	for state in w.map.data.tiles.field:
		var base := int(w.map.data.tiles.field[state])
		for row in 4:
			for col in 4:
				var t := base + row * cols + col
				var coords := Vector2i(t % cols, t / cols)
				if not main.view.sources[0].has_tile(coords):
					main.view._make_tile(0, coords, t)
					made += 1
	print("premake_fields: %d field tiles made before the walk" % made)


func _ticks(w: World) -> int:
	return int(w.get("ticks")) if w.get("ticks") != null else 0     # (no fixed tick before e66ca18)


func _dict(o: Object, k: String) -> Dictionary:
	var v = o.get(k)
	return v if v is Dictionary else {}


func _tiles() -> int:
	var n := 0
	var ts: TileSet = main.ow_view.tileset
	for i in ts.get_source_count():
		n += ts.get_source(ts.get_source_id(i)).get_tiles_count()
	return n
