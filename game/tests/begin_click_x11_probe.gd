extends SceneTree
## B42-BEGIN-DOUBLE-CLICK diagnostic probe (not a CI suite): character creation on a real X display (Xvfb, no window manager),
## driven by real X input from outside (tools/begin_click_xtest.py, XTest through ctypes). It writes the name field's, the family
## field's and Begin's screen positions to $XDIAG_OUT, then logs every mouse event the window gets, Begin's down/up/pressed, focus
## changes and the window's focus out/in, and whether the origin opened. XDIAG_FOCUSNAME=1 gives the name field the focus first (a
## player who has used only the keyboard). Run (one process at a time):
##   Xvfb :77 -screen 0 1600x1000x24 &  export DISPLAY=:77 XDIAG_OUT=/dev/shm/x/coords.json XDIAG_FOCUSNAME=1
##   python3 -I tools/begin_click_xtest.py $XDIAG_OUT kbd &  godot --path game --script res://tests/begin_click_x11_probe.gd
## Modes of the clicker: name, family, enter, tab, fast, nomove, emptyfirst, warm_emptyfirst, kbd. Before the correction, the
## first click into the window (kbd, emptyfirst) logged down, WINDOW_FOCUS_OUT, WINDOW_FOCUS_IN, the window's release, and no up
## or pressed: Begin needed a second click.
var main
var out := ""
func _init() -> void:
	out = OS.get_environment("XDIAG_OUT")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/zzx/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _scr(c: Control) -> Array:
	var p: Vector2 = root.get_final_transform() * c.get_global_transform_with_canvas() * (c.size / 2.0)
	var wp := DisplayServer.window_get_position()
	return [wp.x + p.x, wp.y + p.y]

func _run() -> void:
	if OS.get_environment("XDIAG_NOPROC") == "1":
		main.set_process(false)
	main.ui.show_title(main.can_continue())
	for i in 10: await process_frame
	(main.ui.panel_body.find_children("*", "Button", true, false).filter(func(b): return b.text == "New game")[0] as Button).pressed.emit()
	for i in 20: await process_frame
	var edits: Array = main.ui.panel_body.find_children("*", "LineEdit", true, false)
	var begin := main.ui.panel_body.find_child("Begin", true, false) as Button
	var log := []
	begin.button_down.connect(func(): log.append("down@%d" % Engine.get_process_frames()))
	begin.button_up.connect(func(): log.append("up@%d" % Engine.get_process_frames()))
	begin.pressed.connect(func(): log.append("pressed@%d" % Engine.get_process_frames()))
	(edits[0] as LineEdit).focus_exited.connect(func(): log.append("name_focus_exit@%d" % Engine.get_process_frames()))
	begin.gui_input.connect(func(e): if e is InputEventMouseButton: log.append("begin_gui %s@%d" % [e.pressed, Engine.get_process_frames()]))
	(edits[0] as LineEdit).gui_input.connect(func(e): if e is InputEventMouseButton: log.append("name_gui %s@%d" % [e.pressed, Engine.get_process_frames()]))
	root.gui_focus_changed.connect(func(c): log.append("focus->%s@%d" % [c.name if c else "none", Engine.get_process_frames()]))
	if OS.get_environment("XDIAG_FOCUSNAME") == "1":
		(edits[0] as LineEdit).grab_focus()
		await process_frame
	log.append("focus_at_start=%s editing=%s" % [root.gui_get_focus_owner(), (edits[0] as LineEdit).is_editing()])
	root.focus_entered.connect(func(): log.append("WINDOW_FOCUS_IN@%d" % Engine.get_process_frames()))
	root.focus_exited.connect(func(): log.append("WINDOW_FOCUS_OUT@%d" % Engine.get_process_frames()))
	log.append("window_focused_at_start=%s" % root.has_focus())
	root.window_input.connect(func(e): if e is InputEventMouseButton: log.append("win_mouse %s %s@%d" % [e.pressed, e.position, Engine.get_process_frames()]))
	print("XDIAG window ", DisplayServer.window_get_position(), " ", DisplayServer.window_get_size(), " canvas ", root.get_visible_rect().size, " begin ", begin.get_global_rect())
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"name": _scr(edits[0]), "family": _scr(edits[1]), "begin": _scr(begin)}))
	f.close()
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 15000 and main.ui.panel_kind == "creation":
		await process_frame
	for i in 10: await process_frame
	print("XDIAG main state btn=%s cut=%s up=%s" % [main._click_btn, main._click_cut, main._click_got_up])
	print("XDIAG result open=%s name=%s log=%s" % [main.ui.panel_kind, edits[0].text if is_instance_valid(edits[0]) else "(gone)", log])
	quit(0)
