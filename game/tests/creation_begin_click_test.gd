extends SceneTree
## B42-BEGIN-DOUBLE-CLICK (owner 2026-11-14, C7: "Character creation Begin button sometimes needs a second click: reproduce, find the
## actual cause, correct, focused regression coverage"). Character creation as a player meets it: a name typed into the name field
## (which keeps the keyboard focus), then ONE mouse click on Begin, sent through the engine's input (Input.parse_input_event: a
## motion, a press, a release), not by calling the button's handler.
##
## The cause (traced with real X input, XTest on Xvfb, the setting of the packaged Linux test that reported it): the first click
## into the window makes the system move the window's focus out and back in between the press and the release; the engine ends
## every press when its window loses focus, so the release reached no control and Begin never fired. Here that focus change is
## sent as the window's own notifications between the press and the release (as the display server sends them). Checks: a plain
## click starts the world once; the click cut by a focus change starts it once (it did not before the correction); released away
## from Begin it does nothing; with no name the click still asks for a name. Run headless:
##   godot --headless --path game --script res://tests/creation_begin_click_test.gd

const DIR := "user://test_saves/creation_begin_click/"

var main
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	root.size = Vector2i(1280, 720)                    # a desktop window (headless starts at 64 x 64, stretched)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = DIR + "save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _settle(n := 4) -> void:
	for i in n:
		await process_frame


## A control's centre in window pixels (where the pointer is when it is over it).
func _at(c: Control) -> Vector2:
	return root.get_final_transform() * c.get_global_transform_with_canvas() * (c.size / 2.0)


func _move(at: Vector2) -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = at
	mv.global_position = at
	mv.relative = Vector2(8, 0)
	Input.parse_input_event(mv)
	await process_frame


func _button(down: bool, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	Input.parse_input_event(e)
	await process_frame


## One click: the pointer to `at`, a press; with `cut`, the window's focus out and back in (the first click into the window);
## the pointer to `release_at` (the same place unless given), the release.
func _click(at: Vector2, cut: bool, release_at := Vector2.INF) -> void:
	await _move(at)
	await _button(true, at)
	if cut:
		root.propagate_notification(Window.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		root.propagate_notification(Window.NOTIFICATION_WM_WINDOW_FOCUS_IN)
		await process_frame
	var to := at if release_at == Vector2.INF else release_at
	if to != at:
		await _move(to)
	await _button(false, to)


## Character creation, `name` typed into the name field, which keeps the focus.
func _creation(name: String) -> Dictionary:
	main.running = false
	main.ui.show_creation({})
	await _settle(6)
	var edits: Array = main.ui.panel_body.find_children("*", "LineEdit", true, false)
	var begin := main.ui.panel_body.find_child("Begin", true, false) as Button
	if edits.size() < 2 or begin == null:
		return {}
	var ed: LineEdit = edits[0]
	ed.grab_focus()
	await process_frame
	for ch in name:
		var k := InputEventKey.new()
		k.pressed = true
		k.keycode = OS.find_keycode_from_string(ch.to_upper())
		k.unicode = ch.unicode_at(0)
		Input.parse_input_event(k)
		await process_frame
		var up: InputEventKey = k.duplicate()
		up.pressed = false
		Input.parse_input_event(up)
		await process_frame
	var fired := [0]
	begin.pressed.connect(func(): fired[0] += 1)
	return {"edit": ed, "begin": begin, "fired": fired}


func _try(what: String, cut: bool) -> void:
	var c := await _creation("Ada")
	check(not c.is_empty() and (c.edit as LineEdit).text == "Ada" and root.gui_get_focus_owner() == c.edit,
			"%s: the name was typed and the name field has the focus" % what)
	if c.is_empty():
		return
	await _click(_at(c.begin), cut)
	await _settle()
	check(main.ui.is_open("origin") and int(c.fired[0]) == 1, "%s: ONE click on Begin starts the world, once (open: %s, Begin fired %d)" % [what, main.ui.panel_kind, int(c.fired[0])])


func _run() -> void:
	await _try("a plain click", false)
	await _try("the first click into the window (its focus moves out and back between press and release)", true)
	# released away from Begin after such a cut: no click, as with any button
	var c := await _creation("Bea")
	if not c.is_empty():
		await _click(_at(c.begin), true, _at(c.begin) + Vector2(0, -160))
		await _settle()
		check(main.ui.is_open("creation") and int(c.fired[0]) == 0, "pressed on Begin, cut, released elsewhere: nothing starts")
	# no name: the one click still asks for a name and gives the field the focus
	c = await _creation("")
	if not c.is_empty():
		await _click(_at(c.begin), true)
		await _settle()
		check(main.ui.is_open("creation") and int(c.fired[0]) == 1 and root.gui_get_focus_owner() == c.edit and str(main.ui.toast.text).contains("name"),
				"no name: one cut click asks for a name (\"%s\") and the name field has the focus" % str(main.ui.toast.text))
	print("%d checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
