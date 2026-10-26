extends SceneTree
## GP-MESSAGE-FOOTPRINT (owner, 2026-10-26): the opening message and a three-choice interaction prompt (a villager chosen
## beside an oven, as in the owner's screenshot) in the real game scene, saved as a screenshot so it is looked at. Needs a
## display (not --headless); the window's shape sets the screen's (phone: the owner's 2404 x 1080; 16:9: 1920 x 1080):
##   xvfb-run -a -s "-screen 0 2404x1080x24" godot --rendering-driver opengl3 --resolution 2404x1080 --path game \
##       --script res://tests/msg_prompt_shot.gd -- OUT.png [phone|desktop] [touch|kbm|gamepad] [npc|station|journal]

var main
var out := "/tmp/msg_prompt.png"
var phone := true
var scheme := "touch"
var choose := "npc"          # "npc": a villager chosen, as in the owner's screenshot; "station": the oven (the talk line shows)
var frames := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		phone = args[1] == "phone"
	if args.size() > 2:
		scheme = args[2]
	if args.size() > 3:
		choose = args[3]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/msg_prompt_shot/save1.json"
	main.settings.phone = phone
	main.settings.apply(self)
	main.view_scale = main.settings.layout_height() / 720.0
	main.new_game()
	main.ui.hide_all()
	main.scheme = scheme
	main.ui.set_scheme(scheme)
	main.ui.fit_safe_area()
	var w: World = main.world
	var st_id := ""
	for id in w.stations:
		if w.stations[id].type == "oven":
			st_id = id
			break
	var st: Dictionary = w.stations[st_id]
	var p := w.player
	p.pos = Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
	main.player_sprite.face(Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5) - p.pos)
	var near: Array = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job != "guard")
	for i in 2:                                # two villagers beside the oven: three things on offer
		var by: NPC = near[i]
		by.plan = [w.brain.work(6000, "", {}, "idle")]
		by.anim = "idle"
		by.pos = p.pos + main.facing_vec() * 0.6 + main.facing_vec().orthogonal() * (0.6 if i == 0 else -0.6)
	main.camera.zoom = Vector2(4, 4) * main.view_scale
	main.camera.position_smoothing_enabled = false
	main.follow_at = main._in_view(p.pos * main.T)
	main._start(true)                         # the opening message of a new game
	main.paused = true
	process_frame.connect(_wait)


func _wait() -> void:
	frames += 1
	main._sync_sprites()
	main._find_target()
	if frames == 5 and choose == "npc":
		for i in main.target_options.size():         # choose the villager, as in the owner's screenshot
			if str(main.target.get("kind", "")) in ["npc", "shop"]:
				break
			main.cycle_target(1)
	if frames == 20 and choose == "journal":
		main.ui.show_journal(-1, false, true)        # the journal's Messages page, where every message is kept
	if frames < 30:
		return
	process_frame.disconnect(_wait)
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " ", img.get_size(), " options ", main.target_options.map(func(t): return str(t.kind)),
			" prompt: ", main.ui.prompt_text.replace("\n", " | "), " toast: ", main.ui.toast.get_global_rect(), " box: ", main.ui.prompt_box.get_global_rect())
	quit(0)
