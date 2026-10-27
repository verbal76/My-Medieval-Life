extends SceneTree
## MP-INTERACT-01: a second guest for tests/net_interact_test.gd, in its own Godot process running the real game scene. It joins the
## host, then does what the test's command file asks through its own interface (a tap on another player's character, a key, a
## button of the open window, the quantity picker) and writes what its screen and its copy of the world show to a status file.
## Args after "--": port key name password dir.

var main
var a: PackedStringArray
var dir := ""
var last_seq := -1
var t := 0.0


func _init() -> void:
	a = OS.get_cmdline_user_args()
	dir = str(a[4])
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "g2_unused.json"
	process_frame.connect(func():
		main.net.join("127.0.0.1", int(a[0]), str(a[1]), str(a[2]), str(a[3])), CONNECT_ONE_SHOT)


func _process(delta: float) -> bool:
	t += delta
	if t >= 0.1:
		t = 0.0
		_commands()
		_status()
	return false


func _commands() -> void:
	var f := FileAccess.open(dir + "g2_cmd.json", FileAccess.READ)
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
	if not main.guest_world:
		return
	match str(c.cmd):
		"tap_pid":                                   # a tap on that player's drawn character (Android)
			main.scheme = "touch"
			main.ui.set_scheme("touch")
			var sp: ActorSprite = main.avatar_sprites.get(int(c.pid))
			if sp != null:
				var at: Vector2 = main.get_canvas_transform() * (sp.position + Vector2(0, -0.4 * main.T))
				for down in [true, false]:
					var e := InputEventScreenTouch.new()
					e.index = 0
					e.position = at
					e.pressed = down
					root.push_input(e, true)
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
		"close":
			main.ui.hide_all()
		"quit":
			main.net.leave()
			quit(0)


func _status() -> void:
	var d := {"seq": last_seq, "welcomed": main.guest_world, "pid": main.net.my_pid}
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
			"toast": ui.toast.text if ui.toast.visible else ""}
		d["inv"] = w.player.inv.items.duplicate()
		d["coins"] = w.player.coins
		d["offers"] = w.offers.duplicate(true)
		d["others"] = main.other_players().map(func(q): return q.pid)
	var f := FileAccess.open(dir + "g2_status.tmp", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(dir + "g2_status.tmp"), ProjectSettings.globalize_path(dir + "g2_status.json"))
