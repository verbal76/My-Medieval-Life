extends SceneTree
## REGION-NAV-01: screenshots to look at (CLAUDE.md: visual output is looked at before it is reported): the player standing
## in a settlement's site in the real game scene, then the map window's Region view. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --path game --script res://tests/region_shot.gd -- OUT_DIR [settlement]

var main
var out := "/tmp"
var where := "wulstead"
var frames := 0
var step := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		where = args[1]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/region_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var st: Dictionary = w.map.overworld.site(where)
	# walk the player down the road a little first so the map has some explored ground, then into the site
	var south := Vector2i.ZERO
	for e in w.map.exits():
		if e.side == 2:
			south = e.out
	for k in range(0, 9):
		w.player.pos = Vector2(south) + Vector2(0.5, 0.5) + (Vector2(st.gate) - Vector2(south)) * (k / 8.0)
		w.update(0.01)
	w.player.pos = Vector2(st.slots[0].spot) + Vector2(0.5, 1.5)
	w.minutes = float(w.day()) * 1440.0 + 11.0 * 60.0
	process_frame.connect(_wait)


func _wait() -> void:
	frames += 1
	if frames < 40:
		return
	frames = 0
	if step == 0:
		root.get_viewport().get_texture().get_image().save_png(out + "/region_site_%s.png" % where)
		main.ui.show_map("region")
	elif step == 1:
		root.get_viewport().get_texture().get_image().save_png(out + "/region_map_%s.png" % where)
		quit(0)
	step += 1
