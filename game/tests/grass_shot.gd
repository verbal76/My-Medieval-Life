extends SceneTree
## B25R1-Q8: the low grass tufts looked at and measured, in the real game scene: a screenshot in the village and one in the
## overworld with the player standing among the tufts, and for each place the frame cost with the tufts shown and hidden in
## turn (the same scene, alternating blocks of frames): process time (Performance TIME_PROCESS), the wall time between
## frames, draw calls and primitives; plus the time taken to lay the tufts (the village once, the overworld per chunk).
## Needs a display:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --path game \
##       --script res://tests/grass_shot.gd -- OUTDIR

var main
var out := "/tmp/grass"
var frames := 0
var place := 0                      # 0 village, 1 overworld
var last_us := 0
var stats := {true: [], false: []}  # grass shown -> [[process ms, wall ms, draw calls, primitives]]
const BLOCK := 40
const BLOCKS := 6                   # on, off, on, off, ...
const SETTLE := 30


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/grass_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	main._start(true)
	main.ui.dismiss_message()
	main.camera.position_smoothing_enabled = false
	_go(_village_spot())
	process_frame.connect(_frame)


## The village cell with the most tufts round it (7 x 5), on open ground.
func _village_spot() -> Vector2:
	var view: MapView = main.view
	var best := Vector2i.ZERO
	var most := -1
	for c: Vector2i in view.grass_layer.get_used_cells():
		if c.x < 8 or c.y < 6 or c.x > main.world.map.w - 8 or c.y > main.world.map.h - 6:
			continue
		var n := 0
		for dy in range(-2, 3):
			for dx in range(-3, 4):
				n += 1 if view.grass_value(c + Vector2i(dx, dy)) >= 0 else 0
		if n > most:
			most = n
			best = c
	return Vector2(best) + Vector2(0.5, 0.6)


func _overworld_spot() -> Vector2:
	var ow: Overworld = main.world.map.overworld
	var at := Vector2(ow.village.end.x + 40, ow.village.get_center().y + 10)
	main.ow_view.follow(at, at, 0.0, -1)
	var c := Vector2i(at)
	for r in 30:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := c + Vector2i(dx, dy)
				if main.ow_view.grass_value(q) >= 0 and not ow.is_solid(q):
					return Vector2(q) + Vector2(0.5, 0.6)
	return at


func _go(p: Vector2) -> void:
	main.world.player.pos = p
	main.recenter()
	main.camera.zoom = Vector2(3, 3) * main.view_scale


func _show(on: bool) -> void:
	if main.view.grass_layer != null:
		main.view.grass_layer.visible = on
	for cc in main.ow_view.chunks:
		(main.ow_view.chunks[cc].grass as TileMapLayer).visible = on


func _frame() -> void:
	frames += 1
	main.world.player.hunger = 100.0
	var now := Time.get_ticks_usec()
	var wall := (now - last_us) / 1000.0
	last_us = now
	if frames == SETTLE:
		var name := "village" if place == 0 else "overworld"
		root.get_texture().get_image().save_png("%s/grass_%s.png" % [out, name])
		_show(false)
	if frames == SETTLE + 2:
		root.get_texture().get_image().save_png("%s/grass_%s_off.png" % [out, "village" if place == 0 else "overworld"])
	if frames > SETTLE + 5:
		var k := (frames - SETTLE - 5) / BLOCK
		var on := k % 2 == 0
		var in_block := (frames - SETTLE - 5) % BLOCK
		if in_block == 0:
			_show(on)
		elif in_block > 3:                         # a few frames to settle after each switch
			(stats[on] as Array).append([Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, wall,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		if k >= BLOCKS:
			_report()
			place += 1
			frames = 0
			stats = {true: [], false: []}
			_show(true)
			if place >= 2:
				var ov: OverworldView = main.ow_view
				print("GRASS_BUILD %s" % JSON.stringify({"village_lay_ms": snappedf(main.view.grass_usec / 1000.0, 0.01),
					"village_tufts": main.view.grass_layer.get_used_cells().size(), "overworld_lay_ms_total": snappedf(ov.grass_usec / 1000.0, 0.01),
					"overworld_build_ms_total": snappedf(ov.build_usec / 1000.0, 0.01), "overworld_chunks_loaded": ov.chunks.size()}))
				quit(0)
				return
			_go(_overworld_spot())


func _report() -> void:
	var res := {"place": "village" if place == 0 else "overworld"}
	for on in [true, false]:
		var s: Array = stats[on]
		var cols := [[], [], [], []]
		for r in s:
			for i in 4:
				cols[i].append(r[i])
		for i in 4:
			cols[i].sort()
		var tag := "on" if on else "off"
		var mean := func(a: Array) -> float:
			var t := 0.0
			for v in a:
				t += v
			return t / maxf(1.0, a.size())
		res[tag] = {"frames": s.size(), "process_ms_mean": snappedf(mean.call(cols[0]), 0.01), "process_ms_p50": snappedf(cols[0][cols[0].size() / 2], 0.01),
			"wall_ms_mean": snappedf(mean.call(cols[1]), 0.01), "wall_ms_p50": snappedf(cols[1][cols[1].size() / 2], 0.01),
			"draw_calls": cols[2][cols[2].size() / 2], "primitives": cols[3][cols[3].size() / 2]}
	print("GRASS_FRAME %s" % JSON.stringify(res))
