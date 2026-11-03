extends SceneTree
## B25R1-019: the live render measured and looked at. In the real game scene, at the market after a morning of play: the
## process time per frame (Performance TIME_PROCESS: scripts, the world's tick and the drawing set-up; not the GPU) and how
## many villagers and animals are live, at the normal zoom, zoomed out (a phone's pinch) and with the whole village live (a
## stand-in for the old 34-tile tier's drawing); two screenshots a moment apart to see the trees sway. Needs a display:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --path game \
##       --script res://tests/presence_shot.gd -- OUTDIR

var main
var out := "/tmp/presence"
var frames := 0
var phase := 0
var samples: Array = []
var counts: Array = []
const PHASES := [["normal", 3.0], ["zoomed_out", 1.5], ["all_live", 3.0]]
const FRAMES := 240


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/presence_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	main._start(true)
	main.ui.dismiss_message()
	var w: World = main.world
	w.minutes = 1440.0 + 9.0 * 60.0
	for k in 240:                                 # two game hours: the morning's market
		w.player.hunger = 100.0
		w.update(0.5)
	var m: Vector2 = w.station_use(w.stations_of("tavern_counter")[0]) if not w.stations_of("tavern_counter").is_empty() else w.player.pos
	w.player.pos = Vector2(m) + Vector2(0.5, 3.5)
	main.camera.position_smoothing_enabled = false
	_zoom(3.0)
	process_frame.connect(_frame)


func _zoom(z: float) -> void:
	main.camera.zoom = Vector2(z, z) * main.view_scale


func _frame() -> void:
	frames += 1
	var w: World = main.world
	w.player.hunger = 100.0
	if frames == 30 and phase == 0:
		get_root().get_texture().get_image().save_png(out + "/sway_a.png")
	if frames == 45 and phase == 0:
		get_root().get_texture().get_image().save_png(out + "/sway_b.png")
	if frames > 20:
		samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		var live := 0
		var drawn := 0
		for n: NPC in w.npcs:
			live += 1 if n.live else 0
			var s = main.sprites.get(n.id)
			drawn += 1 if s != null and s.visible else 0
		var animals := 0
		for a: Animal in w.fauna.animals:
			animals += 1 if w.presence.animal_live(a.id) else 0
		counts.append([live, drawn, animals])
	if frames < FRAMES:
		return
	samples.sort()
	var mean := 0.0
	for v in samples:
		mean += v
	mean /= maxf(1.0, samples.size())
	var c: Array = counts[counts.size() - 1]
	print("PRESENCE_FRAME %s" % JSON.stringify({"phase": PHASES[phase][0], "zoom": PHASES[phase][1], "frames": samples.size(),
		"process_ms_mean": snappedf(mean, 0.01), "process_ms_p50": snappedf(samples[samples.size() / 2], 0.01),
		"process_ms_p95": snappedf(samples[int(samples.size() * 0.95)], 0.01), "process_ms_max": snappedf(samples[-1], 0.01),
		"live_villagers": c[0], "drawn_villagers": c[1], "live_animals": c[2], "villagers": w.npcs.size(),
		"crowd": w.presence.crowd_stats}))
	get_root().get_texture().get_image().save_png(out + "/%s.png" % PHASES[phase][0])
	phase += 1
	frames = 0
	samples = []
	counts = []
	if phase >= PHASES.size():
		quit(0)
		return
	_zoom(float(PHASES[phase][1]))
	if PHASES[phase][0] == "all_live":
		main.view_override = Vector2(400, 400)       # the whole village live: the old tier's drawing, for comparison
