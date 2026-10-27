extends SceneTree
## MP-INTERACT-01: a second guest for tests/net_interact_test.gd (and, X20 phase 4.5, the second and third guests of
## tests/net_mp4_test.gd), in its own Godot process running the real game scene. It joins the host, then does what the test's command
## file asks through its own interface (a tap or a left click on another player's character, a key, a pad button, a button of the open
## window, the quantity picker, a tap on a plant) and writes what its screen and its copy of the world show to a status file; on
## "compare" it compares its copy with the host's frozen dump (tests/net_snapshot.gd). It can leave and join again.
## Args after "--": port key name password dir [tag, default "g2": its files are <tag>_cmd.json and <tag>_status.json].

const Snap := preload("res://tests/net_snapshot.gd")

var main
var a: PackedStringArray
var dir := ""
var tag := "g2"
var last_seq := -1
var t := 0.0
var releases: Array = []       # input events to release on the next frame (a key or a pad button pressed by a command)
var cmp := {}                  # the last "compare": {seq, bad}


func _init() -> void:
	a = OS.get_cmdline_user_args()
	dir = str(a[4])
	if a.size() > 5:
		tag = str(a[5])
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + tag + "_unused.json"
	process_frame.connect(_join, CONNECT_ONE_SHOT)


func _join() -> void:
	main.net.join("127.0.0.1", int(a[0]), str(a[1]), str(a[2]), str(a[3]))


func _process(delta: float) -> bool:
	for e in releases:
		Input.parse_input_event(e)
	releases.clear()
	t += delta
	if t >= 0.1:
		t = 0.0
		_commands()
		_status()
	return false


func _scheme(s: String) -> void:
	main.scheme = s
	main.ui.set_scheme(s)


func _commands() -> void:
	var f := FileAccess.open(dir + tag + "_cmd.json", FileAccess.READ)
	if f == null:
		return
	var c = JSON.parse_string(f.get_as_text())
	if typeof(c) != TYPE_DICTIONARY or int(c.seq) <= last_seq:
		return
	last_seq = int(c.seq)
	if str(c.cmd) == "quit":
		main.net.leave()
		quit(0)
		return
	if str(c.cmd) == "join":                         # back into the host's world (a reconnection)
		if not main.guest_world:
			_join()
		return
	if not main.guest_world:
		return
	match str(c.cmd):
		"tap_pid":                                   # a tap on that player's drawn character (Android)
			_scheme("touch")
			var sp: ActorSprite = main.avatar_sprites.get(int(c.pid))
			if sp != null:
				var at: Vector2 = main.get_canvas_transform() * (sp.position + Vector2(0, -0.4 * main.T))
				for down in [true, false]:
					var e := InputEventScreenTouch.new()
					e.index = 0
					e.position = at
					e.pressed = down
					root.push_input(e, true)
		"click_pid":                                 # a left click on that player's drawn character (Windows, Linux)
			_scheme("kbm")
			var sp2: ActorSprite = main.avatar_sprites.get(int(c.pid))
			if sp2 != null:
				var at2: Vector2 = main.get_canvas_transform() * (sp2.position + Vector2(0, -0.4 * main.T))
				var mb := InputEventMouseButton.new()
				mb.button_index = MOUSE_BUTTON_LEFT
				mb.position = at2
				mb.pressed = true
				root.push_input(mb, true)
				var mu := mb.duplicate()
				mu.pressed = false
				root.push_input(mu, true)
		"key":                                       # a key pressed (released next frame)
			_scheme("kbm")
			var e2 := InputEventKey.new()
			e2.physical_keycode = int(c.code)
			e2.keycode = int(c.code)
			e2.pressed = true
			Input.parse_input_event(e2)
			var up := e2.duplicate()
			up.pressed = false
			releases.append(up)
		"pad":                                       # a pad button pressed (released next frame)
			_scheme("gamepad")
			var j := InputEventJoypadButton.new()
			j.button_index = int(c.button)
			j.pressed = true
			Input.parse_input_event(j)
			var ju := j.duplicate()
			ju.pressed = false
			releases.append(ju)
		"face":                                      # this player faces a point (tiles)
			main.player_sprite.face(Vector2(float(c.x), float(c.y)) - main.world.player.pos)
			main.move_to = Vector2.INF
		"still":                                     # stop walking (a tap or click walks the player toward what it chose)
			main.move_to = Vector2.INF
		"pick":                                      # a tap on a plant: the gathering path (Main.select_resource), as net_g1_test does it
			var hit := ResourceNodes.node_at(main.world, Vector2i(int(c.x), int(c.y)), true)
			if not hit.is_empty():
				main.select_resource(hit, false)
		"say":                                       # a message to another player, sent as its Talk window sends one
			main.world.player_offer("say", int(c.to), "", 0, null, 0, 0, str(c.text))
		"offer":                                     # an offer to another player, as its window's terms send one (World.player_offer)
			main.world.player_offer(str(c.kind), int(c.to), str(c.get("item", "")), int(c.get("qty", 1)), null, int(c.get("price", 0)), int(c.get("days", 0)))
		"press":
			for b in main.ui.panel_body.find_children("*", "BaseButton", true, false):
				if b is Button and ((b as Button).name == str(c.name) or (b as Button).text == str(c.name)) and not (b as Button).disabled and (b as Button).is_visible_in_tree():
					(b as Button).pressed.emit()
					break
		"picker":
			var qp: QuantityPicker = main.ui.panel_body.find_child("QuantityPicker", true, false)
			if qp != null:
				qp.set_qty(int(c.n))
				qp.confirm()
		"show_player":                               # that player's window opened (as after choosing them), to answer what is in it
			main.ui.show_player(int(c.pid))
		"close":
			main.ui.hide_all()
		"leave":                                     # this player leaves the host's world (a disconnection)
			main.leave_guest_world("")
		"compare":                                   # this copy against the host's frozen dump
			var df := FileAccess.open(dir + "dump.json", FileAccess.READ)
			var dump = JSON.parse_string(df.get_as_text()) if df != null else {}
			cmp = {"seq": last_seq, "bad": Snap.compare(main.world, main.net.my_pid, dump if dump is Dictionary else {}, c.get("keys", []))}


func _status() -> void:
	var d := {"seq": last_seq, "welcomed": main.guest_world, "pid": main.net.my_pid, "refusal": main.net.refusal, "cmp": cmp,
		"world": main.world != null, "running": main.running}
	if main.guest_world:
		var w: World = main.world
		var ui: GameUI = main.ui
		var words := []
		var buttons := []
		if ui.modal():
			for l in ui.panel_body.find_children("*", "Label", true, false):
				words.append((l as Label).text)
			for b in ui.panel_body.find_children("*", "Button", true, false):
				if (b as Button).is_visible_in_tree():
					buttons.append(str((b as Button).name))
		d["ui"] = {"kind": ui.panel_kind if ui.modal() else "", "title": ui.title_label.text if ui.modal() else "", "words": words, "buttons": buttons,
			"toast": ui.toast.text if ui.toast.visible else "", "target": str(main.target.get("kind", "")), "target_pid": int(main.target.get("pid", 0)),
			"pids": main.target_options.map(func(o): return int(o.get("pid", 0)))}
		d["inv"] = w.player.inv.items.duplicate()
		d["coins"] = w.player.coins
		d["pos"] = [w.player.pos.x, w.player.pos.y]
		d["minutes"] = w.minutes
		d["offers"] = w.offers.duplicate(true)
		d["others"] = main.other_players().map(func(q): return q.pid)
		d["replies"] = main.net.replies.values().map(func(r): return str(r.get("text", "")))
		d["results"] = main.net.replies.values().map(func(r): return JSON.stringify(r.get("result")))
		d["messages"] = w.player_messages().map(func(e): return str(e[2]))
	var f := FileAccess.open(dir + tag + "_status.tmp", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(dir + tag + "_status.tmp"), ProjectSettings.globalize_path(dir + tag + "_status.json"))
