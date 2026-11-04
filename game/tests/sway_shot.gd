extends SceneTree
## B25R1-019: the trees' sway in the breeze, looked at in the real scene. Stands the player among the village's trees, the
## world paused, and saves frames a fraction of a second apart (OUTDIR/sway_0..3.png) plus a strip of the top rows' motion.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --path game \
##       --script res://tests/sway_shot.gd -- OUTDIR

var main
var out := "/tmp/sway"
var frames := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/sway_shot/save1.json"
	main.new_game()
	main.ui.hide_all()
	main._start(true)
	main.ui.dismiss_message()
	main.paused = true                          # the world holds still: only the breeze moves
	var w: World = main.world
	var best := Vector2.ZERO
	var most := -1
	for t in w.trees:                            # the spot with the most grown trees within 5 tiles
		if str(t.state) != "grown":
			continue
		var c := Vector2(int(t.x), int(t.y))
		var k := 0
		for u in w.trees:
			if Vector2(int(u.x), int(u.y)).distance_to(c) < 5.0:
				k += 1
		if k > most:
			most = k
			best = c
	w.player.pos = best + Vector2(0.5, 5.5)
	main.camera.position_smoothing_enabled = false
	main.camera.zoom = Vector2(4, 4) * main.view_scale
	print("among %d trees at %s" % [most, best])
	process_frame.connect(_frame)


func _frame() -> void:
	frames += 1
	main._sync_sprites()
	if frames in [20, 40, 60, 80]:
		var img := root.get_texture().get_image()
		img.save_png(out + "/sway_%d.png" % ((frames - 20) / 20))
	if frames >= 80:
		print("saved frames; wind_time %.2f" % main.tree_view.wind_time)
		quit(0)
