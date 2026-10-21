extends SceneTree
## FARM-09 (owner Q11, 2026-10-21): marking out farmland in the real game scene with the mouse, a finger and the
## keys or a pad. The first corner, a diagonal drag that grows and shrinks the rectangle, the green or red preview
## with the reason, the lease and the price shown mid-screen and updated with the size, the explicit confirmation,
## and the deal refused without the coins. Run headless:
##   godot --headless --path game --script res://tests/farm_place_test.gd

var main
var failures := 0
var checks := 0


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
	if main.get_script() == null or not main.has_method("begin_farm_placement"):
		print("FAIL the game's main script did not load (a script error above): stopping")
		quit(1)
		return
	process_frame.connect(_run, CONNECT_ONE_SHOT)


## The screen point of a cell's middle under the current view.
func at(cell: Vector2i) -> Vector2:
	return main.get_canvas_transform() * ((Vector2(cell) + Vector2(0.5, 0.5)) * 16.0)


func mouse_button(cell: Vector2i, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at(cell)
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	main._placing_input(e)


func mouse_move(cell: Vector2i, held: bool) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at(cell)
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	main._placing_input(e)


func touch(cell: Vector2i, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = at(cell)
	main._unhandled_input(e)              # the game's own path: placing input, then the touch bookkeeping


func drag(cell: Vector2i) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = at(cell)
	main._unhandled_input(e)


func action(name: String) -> void:
	var e := InputEventAction.new()
	e.action = name
	e.pressed = true
	main._placing_input(e)


func price_text() -> String:
	return main.ui.farm_price_label.text


func _run() -> void:
	main.save_path = "user://test_saves/farm_place_test/save1.json"
	main.new_game()
	var w: World = main.world
	var fp: FarmPlots = w.farm_plots
	w.player.coins = 100
	var sp = w.map.data.spawns.player
	var r: Rect2i = fp.find_ground(Vector2i(6, 5), Vector2i(int(sp[0]), int(sp[1])), 0)
	w.player.pos = Vector2(r.get_center()) + Vector2(0.5, 0.5)
	main.recenter()
	main.camera.position = w.player.pos * 16.0
	main.camera.reset_smoothing()
	await process_frame
	await process_frame

	# the mouse: press the first corner, drag diagonally, the rectangle follows; release sets it
	main.begin_farm_placement()
	check(main.placing.has("farm") and main.ui.farm_price.visible, "farmland placing starts with the price panel shown")
	check(price_text() == "Choose the first corner", "first the corner is asked for")
	mouse_move(r.position, false)
	check(Vector2i(main.placing.a) == r.position and not main.placing.set, "the green marker follows the mouse")
	mouse_button(r.position, true)
	check(main.placing.set and main.place_rect() == Rect2i(r.position, Vector2i.ONE), "a press puts down the first corner")
	mouse_move(r.position + Vector2i(2, 2), true)
	check(main.place_rect().size == Vector2i(3, 3), "dragging grows the rectangle (3x3)")
	var small := price_text()
	mouse_move(r.end - Vector2i.ONE, true)
	check(main.place_rect() == r and main.place_refusal() == "", "dragging to the opposite corner: the 6x5 rectangle, green")
	check(price_text() != small and price_text().contains("Lease: 2 coins a week") and price_text().contains("Buy: 20 coins"), "the price follows the size: %s" % price_text().replace("\n", " / "))
	mouse_move(r.position + Vector2i(3, 2), true)
	check(main.place_rect().size == Vector2i(4, 3), "dragging back shrinks it (4x3)")
	mouse_move(r.end - Vector2i.ONE, true)
	mouse_button(r.end - Vector2i.ONE, false)
	check(not main.placing.open and main.place_rect() == r, "releasing sets the opposite corner")
	mouse_move(r.position + Vector2i(30, 30), false)
	check(main.place_rect() == r, "moving the mouse afterwards leaves it set")
	# a red preview with the reason over a building
	var house: Dictionary = w.buildings["b5"]
	main._move_farm_corner(Vector2i(int(house.x) + 2, int(house.y) + 2))
	check(main.place_refusal() != "" and main.ui.place_label.text.begins_with("Farmland cannot go here"), "over a building it is refused, with the reason: %s" % main.ui.place_label.text)
	main._move_farm_corner(r.end - Vector2i.ONE)
	# a click inside confirms: the deal window
	mouse_button(r.position + Vector2i(1, 1), true)
	check(main.ui.panel_kind == "farm_deal", "a click inside the rectangle opens the deal")
	var buttons: Array = main.ui.panel_body.find_children("*", "Button", true, false)
	var lease_b: Button = null
	var buy_b: Button = null
	for b: Button in buttons:
		if b.text.begins_with("Lease for 2"):
			lease_b = b
		elif b.text.begins_with("Buy for 20"):
			buy_b = b
	check(lease_b != null and buy_b != null and not lease_b.disabled and not buy_b.disabled, "lease and buy are offered at the shown prices")
	var t0 := w.treasury
	lease_b.pressed.emit()
	var p: Dictionary = fp.plot_at(r.position)
	check(not p.is_empty() and w.tenant_of(p) == World.PLAYER and w.treasury == t0 + 2 and w.player.coins == 98, "leasing pays the first week to the manor; the plot is the player's")
	check(main.placing.is_empty() and not main.ui.farm_price.visible, "placing ends")

	# a finger: down on a corner, drag, lift; Place confirms; too poor to buy
	w.player.coins = 3
	var r2: Rect2i = fp.find_ground(Vector2i(5, 6), r.get_center(), 0)
	main.begin_farm_placement()
	touch(r2.position, true)
	check(main.placing.set and main.place_rect().size == Vector2i.ONE, "a finger down puts the first corner")
	drag(r2.position + Vector2i(2, 3))
	check(main.place_rect().size == Vector2i(3, 4), "dragging the finger grows the rectangle")
	drag(r2.end - Vector2i.ONE)
	touch(r2.end - Vector2i.ONE, false)
	check(main.place_rect() == r2 and not main.placing.open, "lifting the finger sets the opposite corner (%s)" % str(main.place_rect()))
	main.confirm_placement()                  # the Place here button
	check(main.ui.panel_kind == "farm_deal", "Place here opens the deal")
	var buy2: Button = null
	var lease2: Button = null
	for b: Button in main.ui.panel_body.find_children("*", "Button", true, false):
		if b.text.begins_with("Buy for"):
			buy2 = b
		elif b.text.begins_with("Lease for"):
			lease2 = b
	check(buy2 != null and buy2.disabled and lease2 != null and not lease2.disabled, "with 3 coins buying (20) is refused, leasing (2) is not")
	check(fp.claim(r2, World.PLAYER, false).is_empty() and fp.why == "you need 20 coins", "and the deal itself refuses the purchase")
	main.ui.hide_all()
	main.end_placement()

	# the keys or a pad: the marker steps, A sets the corner, steps grow it, A confirms, B goes back
	w.player.coins = 100
	main.begin_farm_placement()
	main._move_farm_corner(r2.position)
	action("interact")
	check(main.placing.set, "E or A puts the first corner")
	main.move_ghost(Vector2i(1, 0))
	main.move_ghost(Vector2i(1, 0))
	main.move_ghost(Vector2i(0, 1))
	main.move_ghost(Vector2i(0, 1))
	check(main.place_rect().size == Vector2i(3, 3), "stepping grows the rectangle a cell at a time")
	action("ui_cancel")
	check(not main.placing.set and not main.placing.is_empty(), "B or Esc goes back to the first corner")
	action("ui_cancel")
	check(main.placing.is_empty(), "and again stops")

	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
