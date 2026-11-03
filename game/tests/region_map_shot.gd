extends SceneTree
## B25R1-005 / B25R1-006: screenshots of the Region map to look at (CLAUDE.md: visual output is looked at before it is reported),
## in the real game scene. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --resolution 1280x720 --script res://tests/region_map_shot.gd -- OUT_DIR [phone]
## "phone": the phone layout (as on Android). Shots: the map as it opens (the whole network), zoomed in on home with a found
## landmark and a destination chosen, then the HUD while travelling (the Travel bar) and while suspended.

var main
var out := "/tmp"
var tag := "desktop"
var frames := 0
var step := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1 and args[1] == "phone":
		tag = "phone"
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	if tag == "phone":
		main.settings.phone = true
		main.apply_settings()
	main.save_path = "user://test_saves/region_map_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	w.player.hunger = 100.0
	# walk down the south road a little way so some ground is explored, and pass the mine entrance (a landmark)
	for lm in Landmarks.all(w):
		if lm.kind == "mine":
			w.player.pos = Vector2(lm.at) + Vector2(2.5, 3.5)
			w.update(0.01)
	var road := w.map.overworld.road_route(Journeys.gate_index(w), "wulstead")
	for k in range(0, 120, 6):
		w.player.pos = road[k] + Vector2(0.5, 0.5)
		w.update(0.01)
	w.player.pos = road[60] + Vector2(0.5, 0.5)
	main.recenter()
	main.ui.show_map("region")
	process_frame.connect(_wait)


func _shot(name: String) -> void:
	var path := "%s/region_%s_%s.png" % [out, tag, name]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("saved " + path)


func _map() -> RegionMapPanel:
	var found: Array = main.ui.panel_body.find_children("*", "RegionMapPanel", true, false)
	return found[0] if not found.is_empty() else null


func _wait() -> void:
	frames += 1
	if frames < 30:
		return
	frames = 0
	var w: World = main.world
	if step == 0:
		_shot("open")
		var r := _map()
		r.centre_on_player()
		r.zoom = 3.0
		r.centre = Vector2(w.map.overworld.village.get_center()) + Vector2(0, 50)
	elif step == 1:
		_shot("zoomed")
		# choose a destination by tapping the map (off the road, south of Wulstead), as a player does
		var r := _map()
		r.fit_network()
		var st: Dictionary = w.map.overworld.site("netherton")
		var at := r.to_screen(Vector2(st.center) + Vector2(0, 40))
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = true
		e.position = at
		r._gui_input(e)
		e = e.duplicate()
		e.pressed = false
		r._gui_input(e)
		print("travel: ", w.player.travel)
	elif step == 2:
		_shot("travelling")
		main.ui.show_map("region")                 # the route planned, drawn while on the way
	elif step == 3:
		_shot("map_route")
		main.ui.hide_all()
		main.travel.suspend(main)
	elif step == 4:
		_shot("suspended")
		main.ui.show_map("region")
	elif step == 5:
		_shot("map_destination")
		quit(0)
	step += 1
