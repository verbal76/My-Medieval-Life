extends SceneTree
## GP-ANVIL: every crafting station of the village in the real game scene, with its cells marked, saved as screenshots so
## the interaction targets are looked at against the art: red = where the station is drawn and tapped ("at"), green =
## where the worker stands ("use"), yellow = the cells a tap on the station accepts (Main.station_tap_cells).
## Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --script res://tests/station_shot.gd -- OUT_DIR [station ids...]

var main
var out := "/tmp"
var only: Array = []
var frames := 0
var queue: Array = []
var current := ""
var overlay: Node2D


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	for i in range(1, args.size()):
		only.append(args[i])
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/station_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	for id in main.world.stations:
		if only.is_empty() or only.has(id):
			queue.append(id)
	overlay = Node2D.new()
	overlay.z_index = 4000
	overlay.draw.connect(_draw_marks)
	main.add_child(overlay)
	_next()
	process_frame.connect(_wait)


func _next() -> void:
	current = queue.pop_front()
	var st: Dictionary = main.world.stations[current]
	main.world.player.pos = Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
	main.camera.zoom = Vector2(5, 5) * main.view_scale
	main.camera.position_smoothing_enabled = false
	main.follow_at = main._in_view(Vector2(int(st.at[0]) + 0.5, int(st.at[1]) + 0.5) * main.T)
	main.ui.hide_all()
	frames = 0
	overlay.queue_redraw()


func _draw_marks() -> void:
	var T: int = main.T
	var st: Dictionary = main.world.stations[current]
	var font := ThemeDB.fallback_font
	if main.has_method("station_tap_cells"):
		for c: Vector2i in main.station_tap_cells(current):
			overlay.draw_rect(Rect2(Vector2(c) * T + Vector2(3, 3), Vector2(T - 6, T - 6)), Color(1, 1, 0, 0.9), false, 1.0)
	overlay.draw_rect(Rect2(Vector2(int(st.at[0]), int(st.at[1])) * T, Vector2(T, T)), Color(1, 0, 0, 0.9), false, 1.0)
	overlay.draw_rect(Rect2(Vector2(int(st.use[0]), int(st.use[1])) * T + Vector2(1, 1), Vector2(T - 2, T - 2)), Color(0, 1, 0, 0.9), false, 1.0)
	overlay.draw_string(font, Vector2(int(st.at[0]), int(st.at[1])) * T + Vector2(0, -2), "%s %s at %s use %s" % [current, st.type, str(st.at), str(st.use)], HORIZONTAL_ALIGNMENT_LEFT, -1, 5)


func _wait() -> void:
	frames += 1
	if frames == 3:
		main.ui.hide_all()
	if frames < 20:
		return
	var img := root.get_texture().get_image()
	var path := "%s/station_%s.png" % [out, current]
	img.save_png(path)
	print("saved ", path)
	if queue.is_empty():
		process_frame.disconnect(_wait)
		quit(0)
		return
	_next()
