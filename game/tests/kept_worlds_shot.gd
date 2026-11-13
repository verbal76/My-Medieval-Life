extends SceneTree
## B25-DEMO-KEPT-WORLDS: the demo's title, Kept worlds window with three worlds (one used up), saved as a screenshot so the window is
## looked at before it is called done. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --script res://tests/kept_worlds_shot.gd -- OUT.png [expired]
## With "expired", the used-up world's end screen (show_kept_expired) instead.

const DIR := "user://test_saves/kept_worlds_shot/"

var main
var out := "/tmp/kept_worlds.png"
var expired_screen := false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	expired_screen = args.has("expired")
	var abs := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs):
		for f in DirAccess.get_files_at(abs):
			DirAccess.remove_absolute(abs.path_join(f))
	DirAccess.make_dir_recursive_absolute(abs)
	Demo.force = 1
	SteamPromo.opener = func(u: String) -> int: return OK
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = DIR + "save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _press(caption: String) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		if str((b as Button).text) == caption and not (b as Button).disabled:
			(b as Button).pressed.emit()
			return true
	return false


func _world(name: String, family: String, used: float) -> void:
	main.running = false
	main.ui.show_title(main.can_continue())
	_press("New game")
	var edits: Array = main.ui.panel_body.find_children("*", "LineEdit", true, false)
	(edits[0] as LineEdit).text = name
	(edits[1] as LineEdit).text = family
	_press("Begin")
	_press("Begin")
	await process_frame
	Demo.state(main.save_meta).active = used
	if used >= 7200.0:
		main.save_meta.demo.expired = true
	main.save_game(false)


func _run() -> void:
	main.set_process(false)
	await _world("Ada", "Miller", 7200.0)
	await _world("Bea", "Cooper", 2580.0)
	await _world("Cid", "Thatcher", 900.0)
	main.running = false
	if expired_screen:
		var ada := ""
		for e in main.kept_worlds():
			if bool(e.get("expired", false)):
				ada = str(e.path)
		main.ui.show_kept_expired(ada)
	else:
		main.ui.show_kept_worlds()
	for i in 20:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	Demo.force = -1
	quit(0)
