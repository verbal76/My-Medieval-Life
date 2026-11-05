extends SceneTree
## B25R1-025: screenshots and measurements of the aerial Region and Village maps (CLAUDE.md: visual output is looked at before
## it is reported), in the real game scene, for any seed. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 --path game --script res://tests/aerial_map_shot.gd -- OUT_DIR SEED [phone]
## The player walks the roads to Wulstead and to Netherton (exploring them), then stands in Wulstead. Shots: the Region map as it
## opens, zoomed in on Wulstead (the close pictures), the Village map of the home village and of Wulstead, and Wulstead zoomed in.
## Prints the times (first build, opening again) and the memory (the aerial pictures' bytes, the static memory delta) as
## MEASURE lines. The alignment with the world is checked by tests/aerial_map_test.gd.

var main
var out := "/tmp"
var seed := 1
var tag := "desktop"
var frames := 0
var step := 0
var t_open := 0
var mem0 := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		seed = int(args[1])
	if args.size() > 2 and args[2] == "phone":
		tag = "phone"
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


## A new game on `s` (Main.new_game, with the seed given).
static func new_world(m, s: int) -> void:
	m.new_game()
	if s == 1:
		return
	m._clear_world()
	m.map = VillageMap.load_default()
	m.world = World.new()
	m.world.setup(m.map, s)
	m._build_scene()
	m._show_plants()
	m.world.farm_plots.show_all()
	m._start(true)


## Walk the player along the roads from the village to `sids` (explores the chunks round them, as walking does).
static func explore(m, sids: Array) -> void:
	var w: World = m.world
	for sid in sids:
		var road: PackedVector2Array = w.map.overworld.road_route(Journeys.gate_index(w), str(sid))
		for k in range(0, road.size(), 8):
			w.player.pos = road[k] + Vector2(0.5, 0.5)
			Atlas.note_position(w, w.player)
		w.player.pos = road[road.size() - 1] + Vector2(0.5, 0.5)
		Atlas.note_position(w, w.player)


func _setup() -> void:
	if tag == "phone":
		main.settings.phone = true
		main.apply_settings()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves/aerial_map_shot"))
	main.save_path = "user://test_saves/aerial_map_shot/save1.json"
	new_world(main, seed)
	main.ui.hide_all()
	main.aerial_background = false
	var w: World = main.world
	w.player.hunger = 100.0
	explore(main, ["wulstead", "netherton"])
	var st: Dictionary = w.map.overworld.site("wulstead")
	w.player.pos = Vector2(st.center) + Vector2(0.5, 3.5)
	Atlas.note_position(w, w.player)
	main.recenter()
	print("MEASURE seed ", seed, " gen ", w.map.overworld.gen, " explored chunks ", w.player.explored.size())
	mem0 = OS.get_static_memory_usage()
	process_frame.connect(_wait)


func _shot(name: String) -> void:
	var path := "%s/aerial_s%d_%s_%s.png" % [out, seed, tag, name]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("saved " + path)


func _region() -> RegionMapPanel:
	var found: Array = main.ui.panel_body.find_children("*", "RegionMapPanel", true, false)
	return found[0] if not found.is_empty() else null


func _village() -> VillageMapPanel:
	var found: Array = main.ui.panel_body.find_children("*", "VillageMapPanel", true, false)
	return found[0] if not found.is_empty() else null


func _wait() -> void:
	frames += 1
	var a := AerialMap.of(main)
	var w: World = main.world
	if step == 0:
		var t0 := Time.get_ticks_usec()
		main.ui.show_map("region")
		t_open = Time.get_ticks_usec() - t0
		print("MEASURE region first open (setup, first pump) ms ", t_open / 1000.0, " queued ", a.queue.size())
		t_open = Time.get_ticks_msec()
		step = 1
		frames = 0
		return
	if step == 1:
		if not a.queue.is_empty() or frames < 20:
			return
		print("MEASURE region first build wall ms ", Time.get_ticks_msec() - t_open, " lo chunks ", a.lo_drawn, " lo compose ms ", a.lo_usec / 1000.0,
				" of which generation ms ", a.gen_usec / 1000.0, " frames ", frames)
		_shot("region_open")
		var r := _region()
		var st: Dictionary = w.map.overworld.site("wulstead")
		r.zoom = 6.0
		r.centre = Vector2(st.center)
		r.moved = true
		step = 2
		frames = 0
		return
	if step == 2:
		if not a.hi_queue.is_empty() or frames < 20:
			return
		_shot("region_zoom")
		main.ui.hide_all()
		var t0 := Time.get_ticks_usec()
		main.ui.show_map("region")
		print("MEASURE region open again (cached) ms ", (Time.get_ticks_usec() - t0) / 1000.0)
		step = 3
		frames = 0
		return
	if step == 3:
		if frames < 10:
			return
		main.ui.hide_all()
		main.ui.map_place = ""
		var t0 := Time.get_ticks_usec()
		main.ui.show_map("village")
		print("MEASURE village open ms ", (Time.get_ticks_usec() - t0) / 1000.0)
		t_open = Time.get_ticks_msec()
		a.hi_usec = 0
		a.hi_drawn = 0
		step = 4
		frames = 0
		return
	if step == 4:
		if not a.hi_queue.is_empty() or frames < 20:
			return
		print("MEASURE village HI build wall ms ", Time.get_ticks_msec() - t_open, " hi chunks ", a.hi_drawn, " hi compose ms ", a.hi_usec / 1000.0)
		_shot("village_home")
		main.ui.hide_all()
		main.ui.map_place = "wulstead"
		var t0 := Time.get_ticks_usec()
		main.ui.show_map("village")
		print("MEASURE settlement map open ms ", (Time.get_ticks_usec() - t0) / 1000.0, " title ", main.ui.panel_title.text if "panel_title" in main.ui else "")
		t_open = Time.get_ticks_msec()
		a.hi_usec = 0
		a.hi_drawn = 0
		step = 5
		frames = 0
		return
	if step == 5:
		if not a.hi_queue.is_empty() or frames < 20:
			return
		print("MEASURE settlement HI build wall ms ", Time.get_ticks_msec() - t_open, " hi chunks ", a.hi_drawn, " hi compose ms ", a.hi_usec / 1000.0)
		_shot("village_wulstead")
		var v := _village()
		v.zoom_at(v.to_screen(Vector2(w.map.overworld.site("wulstead").center)), 2.5)
		step = 6
		frames = 0
		return
	if step == 6:
		if not a.hi_queue.is_empty() or frames < 20:
			return
		_shot("village_wulstead_zoom")
		main.ui.hide_all()
		main.ui.map_place = ""
		main.ui.show_map("village")
		step = 7
		frames = 0
		return
	if step == 7:
		if frames < 20:
			return
		var v := _village()
		v.zoom_at(v.to_screen(Vector2(main.world.map.overworld.village.get_center())), 2.2)
		step = 8
		frames = 0
		return
	if step == 8:
		if not a.hi_queue.is_empty() or frames < 20:
			return
		_shot("village_home_zoom")
		var b := a.bytes()
		print("MEASURE memory: LO pages ", b.pages, " (", b.lo_bytes / 1024, " KiB with CPU copies), HI chunks ", b.hi, " (", b.hi_bytes / 1024,
				" KiB), static memory delta since before the first open ", (OS.get_static_memory_usage() - mem0) / 1024, " KiB")
		quit(0)

