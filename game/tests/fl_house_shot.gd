extends SceneTree
## B25R1-022: screenshots to look at (CLAUDE.md: visual output is looked at before it is reported) of the Fantasy Lands houses
## in the real game scene: the player in front of a styled house of a settlement, then in its doorway (the roof lifted), then
## inside. `kind` "elite" picks a great house (fl_hall), "any" the first styled home. Needs a display (not --headless):
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 --path game --script res://tests/fl_house_shot.gd -- OUT_DIR [settlement] [kind]

var main
var out := "/tmp"
var where := "garton"
var kind := "any"
var frames := 0
var step := 0
var slot := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		where = args[1]
	if args.size() > 2:
		kind = args[2]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/fl_house_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var st: Dictionary = w.map.overworld.site(where)
	for sl in st.slots:
		var s := str(sl.get("style", ""))
		if s != "" and (kind != "elite" or s.begins_with("fl_hall")):
			slot = sl
			break
	if slot.is_empty():
		printerr("no styled house in ", where)
		quit(1)
		return
	print("house ", slot.style, " at ", slot.rect)
	w.player.pos = Vector2(slot.spot) + Vector2(0.5, 1.5)
	w.minutes = 2.0 * 1440.0 + 11.0 * 60.0
	process_frame.connect(_wait)


func _wait() -> void:
	frames += 1
	if frames < 40:
		return
	frames = 0
	var w: World = main.world
	var tag := "%s_%s" % [where, kind]
	if step == 0:
		root.get_viewport().get_texture().get_image().save_png(out + "/fl_%s_front.png" % tag)
		w.player.pos = Vector2(slot.door) + Vector2(0.5, 0.6)
	elif step == 1:
		root.get_viewport().get_texture().get_image().save_png(out + "/fl_%s_door.png" % tag)
		print("lifted ", main.ow_view.site_roof_lifted())
		w.player.pos = Vector2(slot.door) + Vector2(0.5, -0.4)
	elif step == 2:
		root.get_viewport().get_texture().get_image().save_png(out + "/fl_%s_inside.png" % tag)
		quit(0)
	step += 1
