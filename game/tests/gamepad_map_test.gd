extends SceneTree
## B25R1-012 (owner 2026-11-03): choosing a destination on the Region map with a gamepad, through real joypad events
## (Input.parse_input_event): the cursor shows and moves with the D-pad, the map stays still under the character (who does not
## move behind the open window), the triggers zoom, R3 centres on the player, A travels through the same route planning as a
## tap, movement input suspends the journey, X resumes it and Y dismisses it. Run:
##   godot --headless --path game --script res://tests/gamepad_map_test.gd

var failures := 0
var checks := 0
var main


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves/gamepad_map"))
	main.save_path = "user://test_saves/gamepad_map/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _button(b: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = b
	e.pressed = down
	Input.parse_input_event(e)


func _axis(a: int, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = a
	e.axis_value = v
	Input.parse_input_event(e)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## The triggers zoom by time held, and frame times vary on a loaded machine: hold for up to two seconds of frames,
## stopping once the condition holds (the check after it still fails if it never does).
func _hold_until(cond: Callable) -> void:
	for i in 240:
		await process_frame
		if cond.call():
			return


func _map() -> RegionMapPanel:
	var found: Array = main.ui.panel_body.find_children("*", "RegionMapPanel", true, false)
	return found[0] if not found.is_empty() else null


func _open_map() -> RegionMapPanel:
	main.ui.show_map("region")
	await _frames(4)
	return _map()


func _run() -> void:
	main.new_game()
	await _frames(2)
	main.ui.hide_all()
	var w: World = main.world
	var p: PlayerState = w.player
	var r := await _open_map()
	check(r != null and main.ui.modal(), "the Region map is open")
	check(r.cursor == Vector2.INF, "no cursor before a pad is used")
	var home := p.pos
	# the first D-pad press shows the cursor on the player
	_button(JOY_BUTTON_DPAD_DOWN, true)
	await _frames(2)
	check(r.cursor != Vector2.INF and r.to_screen(r.cursor).distance_to(r.to_screen(home)) < 40.0, "a D-pad press shows the cursor, on the player (on screen)")
	var c0 := r.cursor
	await _frames(30)
	_button(JOY_BUTTON_DPAD_DOWN, false)
	await _frames(2)
	check(r.cursor.y > c0.y + 1.0, "held down, the D-pad moves the cursor south (%.1f -> %.1f)" % [c0.y, r.cursor.y])
	check(p.pos.distance_to(home) < 0.01, "the character does not move under the open map")
	check(main.ui.modal() and _map() == r, "the D-pad does not move the focus or open another window (still the map)")
	_button(JOY_BUTTON_DPAD_UP, true)
	await _frames(1)
	_button(JOY_BUTTON_DPAD_UP, false)
	await _frames(2)
	check(_map() == r, "D-pad up does not open the journal while the map is open")
	# zoom with the triggers, about the cursor
	var z0: float = r.zoom
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _hold_until(func(): return r.zoom > z0 * 1.1)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _frames(1)
	check(r.zoom > z0 * 1.1, "RT zooms in (%.2f -> %.2f)" % [z0, r.zoom])
	var z1: float = r.zoom
	_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _hold_until(func(): return r.zoom < z1 * 0.9)
	_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await _frames(1)
	check(r.zoom < z1 * 0.9, "LT zooms out (%.2f -> %.2f)" % [z1, r.zoom])
	# R3: centre on the player
	r.centre += Vector2(80, 80)
	_button(JOY_BUTTON_RIGHT_STICK, true)
	await _frames(1)
	_button(JOY_BUTTON_RIGHT_STICK, false)
	await _frames(1)
	check(r.centre.distance_to(p.pos) < 1.0 and r.cursor.distance_to(p.pos) < 1.0, "R3 centres the map and the cursor on the player")
	# A: travel to the point under the cursor, by the same route planning as a tap (a point a little way down the road south)
	var o: Overworld = w.map.overworld
	var target := Vector2.INF
	for k in range(1, 40):
		var c := Vector2i(int(p.pos.x), o.village.end.y + 6 + k)
		for dx in range(-12, 13):
			var cc := c + Vector2i(dx, 0)
			if not w.map.is_solid_world(cc):
				target = Vector2(cc) + Vector2(0.5, 0.5)
				break
		if target != Vector2.INF:
			break
	check(target != Vector2.INF, "an open point south of the village to aim at")
	r.cursor = target
	_button(JOY_BUTTON_A, true)
	await _frames(1)
	_button(JOY_BUTTON_A, false)
	await _frames(3)
	check(RegionTravel.has_destination(p) and Vector2(RegionTravel.destination(p)).distance_to(target) < 1.5, "A sets the cursor's point as the destination (%s)" % str(RegionTravel.destination(p) if RegionTravel.has_destination(p) else "none"))
	check(RegionTravel.active(p) and not main.ui.modal(), "the map closes and the journey starts")
	var start := p.pos
	await _frames(90)
	check(p.pos.distance_to(start) > 1.0, "the character walks the route (%.1f tiles)" % p.pos.distance_to(start))
	# interrupt with the stick: the journey stops, the destination stays
	_axis(JOY_AXIS_LEFT_X, 1.0)
	await _frames(6)
	_axis(JOY_AXIS_LEFT_X, 0.0)
	await _frames(3)
	check(not RegionTravel.active(p) and RegionTravel.has_destination(p), "moving the stick suspends the journey and keeps the destination")
	# reopen the map: X resumes, Y dismisses
	r = await _open_map()
	_button(JOY_BUTTON_X, true)
	await _frames(1)
	_button(JOY_BUTTON_X, false)
	await _frames(3)
	check(RegionTravel.active(p), "X on the map resumes the journey (replanned from here)")
	_axis(JOY_AXIS_LEFT_Y, 1.0)
	await _frames(6)
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	await _frames(3)
	r = await _open_map()
	if r != null:
		r.pad_button(JOY_BUTTON_DPAD_DOWN)                  # the cursor on, as a pad player has it
	_button(JOY_BUTTON_Y, true)
	await _frames(1)
	_button(JOY_BUTTON_Y, false)
	await _frames(3)
	check(not RegionTravel.has_destination(p), "Y on the map dismisses the destination")
	# B closes the map as it closes every window
	main.ui.show_map("region")
	await _frames(3)
	_button(JOY_BUTTON_B, true)
	await _frames(2)
	_button(JOY_BUTTON_B, false)
	await _frames(2)
	check(not main.ui.modal(), "B closes the map")
	# a touch or the mouse hides the cursor
	r = await _open_map()
	r.pad_button(JOY_BUTTON_DPAD_RIGHT)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_WHEEL_UP
	mb.pressed = true
	mb.position = r.size / 2.0
	r._gui_input(mb)
	check(r.cursor == Vector2.INF, "the mouse hides the pad's cursor")
	main.ui.hide_all()
	print("%d checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)
