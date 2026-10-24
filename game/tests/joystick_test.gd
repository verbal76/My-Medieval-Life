extends SceneTree
## GP-JOYSTICK and GP-INPUT-CONSIST (owner, 2026-10-24), in the real game scene: "Moving by touch" is tap (the default,
## unchanged: a tap on open ground walks there) or a thumbstick in the lower-left corner. The stick shows only in play with
## touch, hides under any window (and lets go), stays inside the screen; a finger dragged on it presses the same move
## actions as keys and pads, so the player walks at the world's own speed and stops on release; a tap on open ground then
## does not walk. The choice is saved.
##   godot --headless --path game --script res://tests/joystick_test.gd

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/joystick_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func touch(stick: Control, at: Vector2, pressed: bool, idx := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.pressed = pressed
	e.position = at
	stick._gui_input(e)


func drag(stick: Control, at: Vector2, idx := 0) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = at
	stick._gui_input(e)


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	var ui = main.ui
	var w: World = main.world
	var st: GameSettings = main.settings
	check(st.touch_move == "tap", "tap-to-move is the default")
	main.scheme = "touch"
	ui.set_scheme("touch")
	await frames()
	var stick: VirtualStick = ui.stick
	check(stick != null and not stick.visible, "with tap-to-move there is no stick")
	# tap-to-move unchanged: a tap on open ground walks there
	var p := w.player
	var ground := p.pos + Vector2(3, 0)
	for k in 8:
		if not w.map.is_solid(Vector2i(ground.floor())):
			break
		ground += Vector2(0, 1)
	main._tap((main.get_canvas_transform() * (ground * main.T)))
	check(main.move_to != Vector2.INF, "a tap on open ground walks there (tap-to-move)")
	main.move_to = Vector2.INF
	# the stick
	st.touch_move = "joystick"
	ui.update_hud()
	await frames()
	check(stick.visible, "chosen, the stick shows in play with touch")
	var view: Rect2 = root.get_visible_rect()
	check(view.encloses(stick.get_global_rect()) and stick.get_global_rect().position.x < view.size.x * 0.3 and stick.get_global_rect().end.y > view.size.y * 0.6,
		"in the lower left, inside the screen %s" % str(stick.get_global_rect()))
	var from := p.pos
	var c := stick.centre()
	touch(stick, c, true)
	drag(stick, c + Vector2(VirtualStick.RADIUS, 0))
	check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left") and Input.get_action_strength("move_right") > 0.9,
		"pushing right presses move_right, as a key or the pad's stick does")
	for k in 30:
		main._player_step(1.0 / 30.0)
	var by_stick := p.pos
	touch(stick, c + Vector2(VirtualStick.RADIUS, 0), false)
	# the same second with the keyboard's move_right from the same place: the same walk (one movement path)
	p.pos = from
	Input.action_press("move_right")
	for k in 30:
		main._player_step(1.0 / 30.0)
	Input.action_release("move_right")
	check(by_stick.distance_to(from) > 0.5 and by_stick.distance_to(p.pos) < 0.05, "the stick walks exactly as the keyboard does (%.2f tiles; keys %.2f)" % [by_stick.distance_to(from), p.pos.distance_to(from)])
	p.pos = by_stick
	check(not Input.is_action_pressed("move_right") and stick.push == Vector2.ZERO, "lifting the finger lets go")
	var at := p.pos
	for k in 10:
		main._player_step(1.0 / 30.0)
	check(p.pos.distance_to(at) < 0.01, "and the player stops")
	# hidden under any window, letting go
	touch(stick, c, true)
	drag(stick, c + Vector2(0, -VirtualStick.RADIUS))
	ui.show_pause()
	ui.update_hud()
	await frames()
	check(not stick.visible and not Input.is_action_pressed("move_up"), "a window hides the stick and lets go of the move")
	ui.hide_all()
	ui.update_hud()
	await frames()
	check(stick.visible, "and it comes back in play")
	# a tap on open ground does not walk with the stick
	main._tap((main.get_canvas_transform() * (ground * main.T)))
	check(main.move_to == Vector2.INF, "with the stick, a tap on open ground does not walk")
	# the choice is saved; keyboard and mouse never show it
	st.save_file()
	var again := GameSettings.new()
	again.load_file()
	check(again.touch_move == "joystick", "the choice is saved")
	main.scheme = "kbm"
	ui.set_scheme("kbm")
	await frames()
	check(not stick.visible, "with keyboard and mouse there is no stick")
	st.touch_move = "tap"
	st.save_file()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
