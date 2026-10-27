extends SceneTree
## MP-INTERACT-01: another player (Bob) beside the anvil, as the host sees him, saved as a screenshot so it is looked at: the prompt
## (Use on the anvil, Talk to Bob), the ring at his feet, and his window (or the terms of a sale). Needs a display (not --headless);
## the window's shape sets the screen's:
##   xvfb-run -a -s "-screen 0 2404x1080x24" godot --rendering-driver opengl3 --resolution 2404x1080 --path game \
##       --script res://tests/mp_interact_shot.gd -- OUT.png [phone|desktop] [touch|kbm|gamepad] [prompt|window|terms|list]

var main
var out := "/tmp/mp_interact.png"
var phone := true
var scheme := "touch"
var view := "prompt"
var frames := 0
var bob: PlayerState


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		phone = args[1] == "phone"
	if args.size() > 2:
		scheme = args[2]
	if args.size() > 3:
		view = args[3]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/mp_interact_shot/save1.json"
	main.settings.phone = phone
	main.settings.apply(self)
	main.view_scale = main.settings.layout_height() / 720.0
	main.new_game()
	main.ui.hide_all()
	main.net.set_process(false)
	main.scheme = scheme
	main.ui.set_scheme(scheme)
	main.ui.fit_safe_area()
	var w: World = main.world
	var anvil: String = w.stations_of("anvil")[0]
	var st: Dictionary = w.stations[anvil]
	var p := w.player
	p.pos = Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
	main.player_sprite.face(Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5) - p.pos)
	for n: NPC in w.npcs:
		if n.alive and n.pos.distance_to(p.pos) < 5.0:
			n.pos += Vector2(30, 30)
	bob = PlayerState.new()
	bob.name = "Bob"
	bob.family = "Guest"
	bob.sex = "male"
	bob.born = p.born
	bob.sprite = NetSession.LOOKS[1]
	bob.heir_sprite = bob.sprite
	Identity.register_player(w, bob)
	w.give_start_kit(bob)
	bob.pos = p.pos + main.facing_vec() * 0.9 + main.facing_vec().orthogonal() * 0.55
	w.add_guest(bob)
	main.net.role = "host"
	main.net.by_peer = {9001: bob.pid}
	main.net.moves = {9001: {"t": 0, "dir": Vector2.LEFT, "anim": "idle"}}
	p.inv.add("apple", 4)
	main.camera.zoom = Vector2(4, 4) * main.view_scale
	main.camera.position_smoothing_enabled = false
	main.follow_at = main._in_view(p.pos * main.T)
	main.recenter()


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 20:
		main.ui.dismiss_message()
		match view:
			"window":
				main.ui.show_player(bob.pid)
			"terms":
				main.ui.show_player(bob.pid, "terms", {"kind": "sell", "item": "apple", "qty": 2, "price": 7})
			"list":
				w_offer()
				main.ui.show_players()
	if frames == 40:
		root.get_texture().get_image().save_png(out)
		print("saved ", out, " ", root.get_visible_rect().size, " prompt: ", main.ui.prompt_text.replace("\n", " | "))
		quit(0)
	return false


func w_offer() -> void:
	var w: World = main.world
	w.as_actor(bob, func(): w.player_offer("gift", w.host_player().pid, "bread", 1))
