extends SceneTree
## GP-ACTIONBAR / GP-PICKAXE-ANIM: the phone HUD (the two touch columns at the right) while the player mines a seam in
## Gather mode, in the real game scene, saved as a screenshot so it is looked at. Needs a display (not --headless); use a
## phone-shaped window (the owner's Pixel 10 Pro XL screenshot is 2404 x 1080):
##   xvfb-run -a -s "-screen 0 2404x1080x24" godot --rendering-driver opengl3 --resolution 2404x1080 --path game \
##       --script res://tests/touch_bar_shot.gd -- OUT.png

var main
var out := "/tmp/touch_bar.png"
var frames := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/touch_bar_shot/save1.json"
	main.settings.phone = true
	main.settings.apply(self)
	main.view_scale = main.settings.layout_height() / 720.0
	main.new_game()
	main.ui.hide_all()
	main.ui.set_scheme("touch")
	main.ui.fit_safe_area()
	var w: World = main.world
	var d := w.nearest_deposit(Vector2i(w.player.pos), ["iron_ore", "stone", "coal"])
	d.amount = 40
	var c: Vector2i = w.brain.beside(Vector2i(int(d.x), int(d.y)), Vector2i(int(d.x), int(d.y)) + Vector2i(0, -1))
	w.player.pos = Vector2(c) + Vector2(0.5, 0.5)
	main.camera.zoom = Vector2(4, 4) * main.view_scale
	main.camera.position_smoothing_enabled = false
	main.follow_at = main._in_view(w.player.pos * main.T)
	main.gather_button()
	main.select_resource(ResourceNodes.node_at(w, Vector2i(int(d.x), int(d.y)), true), true)
	process_frame.connect(_wait)


func _wait() -> void:
	frames += 1
	if frames >= 40:
		main.ui.toast.visible = false              # the Gather hint would cover the miner
	if frames < 45:
		return
	process_frame.disconnect(_wait)
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " ", img.get_size(), " anim ", main.player_sprite.anim, " tool ", main.player_sprite.tool_item, " action ", main.action.get("label", ""))
	quit(0)
