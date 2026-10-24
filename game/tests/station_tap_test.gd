extends SceneTree
## GP-ANVIL (owner directive 2026-10-24, section 1): a tap (Android) or a left click (PC) on the drawn anvil opens the anvil:
## the player walks to the anvil's use cell, beside it, faces it and its window opens; a tap on the woodpile beside it does
## not, from far or near. The same for every station the player works at, and the station data are audited: each is drawn
## ("at") on a cell other than where its worker stands ("use"), the use cell is open ground next to it. Driven through the
## real game scene with real input events (InputEventScreenTouch and InputEventMouseButton), headless:
##   godot --headless --path game --script res://tests/station_tap_test.gd

var main
var checks := 0
var failures := 0
const ANVIL := "s5"
const WOODPILE := Vector2i(77, 45)      # the stacked wood drawn below and left of the anvil's table (screenshot, station_shot.gd)


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		printerr("FAIL: " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("station_tapped"):
		print("FAIL the game's main script did not load: stopping")
		quit(1)
		return
	main.save_path = "user://test_saves/station_tap_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _screen(cell: Vector2) -> Vector2:
	return main.get_canvas_transform() * (cell * main.T)


## A finger down and up on `cell` (a tap), or a left click there.
func _press(cell: Vector2, touch: bool) -> void:
	var at := _screen(cell)
	if touch:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = at
		e.pressed = true
		main._unhandled_input(e)
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.position = at
		up.pressed = false
		main._unhandled_input(up)
	else:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = at
		m.pressed = true
		m.device = 0
		main._unhandled_input(m)


## Play frames of the player's controls until they stop walking (and a reach ends).
func _walk() -> void:
	for i in 400:
		if main.move_to == Vector2.INF and main.reach_to == Vector2.INF:
			return
		main._player_step(1.0 / 30.0)


func _reset(pos: Vector2) -> void:
	main.ui.hide_all()
	main.move_to = Vector2.INF
	main.reach_to = Vector2.INF
	main.reach_station = ""
	main.world.player.pos = pos


func _open_title() -> String:
	return main.ui.title_label.text if main.ui.panel.visible and main.ui.panel_kind == "craft" else ""


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var st: Dictionary = w.stations[ANVIL]
	var at := Vector2i(int(st.at[0]), int(st.at[1]))
	var use := Vector2i(int(st.use[0]), int(st.use[1]))
	check(main.station_tapped(Vector2(at) + Vector2(0.5, 0.5)) == ANVIL, "a point on the drawn anvil %s is the anvil" % str(at))
	check(main.station_tapped(Vector2(WOODPILE) + Vector2(0.5, 0.5)) == "", "a point on the woodpile %s is no station" % str(WOODPILE))
	check(main.station_tapped(Vector2(use) + Vector2(0.5, 0.5)) == "", "the floor the smith stands on %s is not the anvil either" % str(use))
	for touch in [true, false]:
		var how := "a tap (touch)" if touch else "a left click (mouse)"
		# from across the smithy: walk to the anvil's use cell and open it
		_reset(Vector2(use) + Vector2(-2.5, 3.5))
		await process_frame
		_press(Vector2(at) + Vector2(0.5, 0.5), touch)
		_walk()
		var p := w.player.pos
		check(_open_title() == "THE ANVIL", "%s on the anvil from 4 tiles away opens the anvil (window %s)" % [how, _open_title()])
		check(p.distance_to(Vector2(use) + Vector2(0.5, 0.5)) < World.STATION_REACH and not w.solid_for_player(Vector2i(floori(p.x), floori(p.y))),
				"%s: the player stands beside the anvil, on open floor (%.2f, %.2f)" % [how, p.x, p.y])
		# the woodpile, tapped from far and from right beside it, never opens the anvil
		_reset(Vector2(use) + Vector2(-2.5, 3.5))
		await process_frame
		_press(Vector2(WOODPILE) + Vector2(0.5, 0.5), touch)
		_walk()
		check(_open_title() == "", "%s on the woodpile from 4 tiles away does not open the anvil (stood at %.1f, %.1f)" % [how, w.player.pos.x, w.player.pos.y])
		_reset(Vector2(use) + Vector2(0.5, 0.5))
		await process_frame
		_press(Vector2(WOODPILE) + Vector2(0.5, 0.5), touch)
		_walk()
		check(_open_title() == "", "%s on the woodpile while standing at the anvil's place does not open the anvil" % how)
		# standing there, Use (the button, E, A) still offers the anvil: the woodpile is not what is used
		_reset(Vector2(use) + Vector2(0.5, 0.5))
		main.player_sprite.face(Vector2(at) - Vector2(use))
		main._find_target()
		check(not main.target.is_empty() and str(main.target.kind) == "station" and str(main.target.id) == ANVIL, "%s: standing at the anvil, Use is the anvil (%s)" % [how, str(main.target.get("label", ""))])
	# every station the player works at: tapped from a few tiles away, it opens itself
	for id in w.stations:
		var s: Dictionary = w.stations[id]
		if not s.type in World.PLAYER_STATIONS:
			continue
		var sa := Vector2i(int(s.at[0]), int(s.at[1]))
		var su := Vector2i(int(s.use[0]), int(s.use[1]))
		check(sa != su and maxi(absi(sa.x - su.x), absi(sa.y - su.y)) == 1 and not w.solid_for_player(su),
				"%s %s: drawn at %s, its worker stands beside it on open ground %s" % [id, s.type, str(sa), str(su)])
		_reset(Vector2(su) + Vector2(0.5, 0.5))
		await process_frame
		_press(Vector2(sa) + Vector2(0.5, 0.5), true)
		_walk()
		var want := "STOVE — COOKING & TONICS" if s.type == "stove" else "THE %s" % str(s.type).to_upper()
		check(_open_title() == want, "%s %s: a tap on it opens it (%s)" % [id, s.type, _open_title()])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
