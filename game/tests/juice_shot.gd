extends SceneTree
## JUICE J1/J2 (owner Decision 9): the effects in the real game scene, saved as a screenshot so they are looked at: chips and
## dust at a seam-like blow and sparks beside the player, the corner log's two lanes (a gain with its icon above a village
## line) and the coin counter's "+25". Particles are held still at the moment of capture. Needs a display (not --headless):
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 --path game \
##       --script res://tests/juice_shot.gd -- OUT.png [reduce]

var main
var out := "/tmp/juice_shot.png"
var reduce := false
var frames := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	reduce = "reduce" in args
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	main.save_path = "user://test_saves/juice_shot/save1.json"
	main.settings.reduce_effects = reduce
	main.new_game()
	main.ui.hide_all()
	main.camera.zoom = Vector2(4, 4)
	main.camera.position_smoothing_enabled = false
	main._start(true)
	main.paused = true
	main.ui.dismiss_message()
	process_frame.connect(_wait)


func _wait() -> void:
	frames += 1
	main._sync_sprites()
	main.ui.update_hud()
	if frames == 20:
		var p: PlayerState = main.world.player
		main.ui.village("The east iron seam at the mine is worked out.")
		main.ui.gain("+1 Iron ore", "iron_ore")
		p.coins += 25
		main.ui.update_hud()
		main.fx.burst("stone", p.pos * main.T + Vector2(14, -4))
		main.fx.burst("sparks", p.pos * main.T + Vector2(-14, -4))
		main.fx.burst("complete", p.pos * main.T + Vector2(0, 20))
		main.fx.step(0.08)
		main.fx.set_process(false)          # hold the particles where they are for the capture
	if frames < 24:
		return
	process_frame.disconnect(_wait)
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " ", img.get_size(), " live ", main.fx.live(), " corner ", main.ui.log_texts(), " coins ", main.ui.coins_label.text)
	quit(0)
