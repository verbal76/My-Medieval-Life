extends SceneTree
## B25R2 playtest repair (owner directive 2026-11-06, items 4 and 5): the whole game is played with a controller, no mouse.
##  1. Every window the game opens from play (the pause menu, the Pack and its tabs, Skills, the Journal, both maps, settings,
##     controls, the wiki, credits, players, home, land, building, resources, a villager's talk, trade, gifts, employment,
##     contracts, the reeve's job board, a stall, a chest): every control a mouse could press (buttons, option lists, sliders, text
##     fields, spin boxes) is reached by the pad's own focus stepping (GameUI.cycle_focus, the triggers), and shows the theme's focus
##     frame (or draws its own). A control the pad cannot reach is named.
##  2. The travel bar at the foot of the screen, through real joypad events (Input.parse_input_event): D-pad Right puts the pad on
##     Resume (fewer than two targets to cycle), A resumes the journey, the focus stays on the bar (Dismiss), B gives the pad back to
##     play, D-pad Left puts it on Dismiss, A dismisses the destination and the bar goes; the mouse still presses the buttons.
##  3. The Region map: the View button puts the pad on the window's buttons (the triggers zoom there), A presses one, View gives the
##     pad back to the map's cursor.
##   godot --headless --path game -s res://tests/pad_reach_test.gd

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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves/pad_reach"))
	main.save_path = "user://test_saves/pad_reach/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _button(b: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = b
	e.pressed = down
	Input.parse_input_event(e)


func _press(b: int) -> void:
	_button(b, true)
	await _frames(2)
	_button(b, false)
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## The controls in the open window a mouse could use.
func _controls() -> Array:
	return main.ui.panel.find_children("*", "Control", true, false).filter(func(c): return c.is_visible_in_tree() \
		and (c is BaseButton or c is LineEdit or c is Slider or c is SpinBox or c is ItemList) and not (c is BaseButton and c.disabled))


## Whether control `c` shows that it has focus: the theme's focus frame, or its own drawing (it redraws on focus, as the Pack's tabs).
func _shows_focus(c: Control) -> bool:
	if not c.focus_entered.get_connections().is_empty():
		return true
	var sb := c.get_theme_stylebox("focus")
	return sb != null and not (sb is StyleBoxEmpty)


## Step the pad's focus through the open window (the triggers: GameUI.cycle_focus) and check every control is met and shows it.
func _audit(name: String) -> void:
	await _frames(3)
	if not main.ui.panel.visible:
		check(false, "%s: the window opens" % name)
		return
	var all := _controls()
	var unreachable := all.filter(func(c): return c.focus_mode == Control.FOCUS_NONE)
	var met := {}
	for i in all.size() + 2:
		main.ui.cycle_focus(1)
		var f = main.ui.get_viewport().gui_get_focus_owner()
		if f != null:
			met[f] = true
	var missed := all.filter(func(c): return c.focus_mode != Control.FOCUS_NONE and not met.has(c))
	var unseen := all.filter(func(c): return c.focus_mode != Control.FOCUS_NONE and not _shows_focus(c))
	var names := func(arr: Array) -> String: return ", ".join(arr.slice(0, 6).map(func(c): return "%s '%s'" % [c.get_class(), str(c.get("text") if c.get("text") != null else c.name)]))
	check(not all.is_empty() and unreachable.is_empty() and missed.is_empty(), "%s: all %d controls reached by the pad (%d with no focus: %s; %d missed: %s)" % [
		name, all.size(), unreachable.size(), names.call(unreachable), missed.size(), names.call(missed)])
	check(unseen.is_empty(), "%s: the pad's focus shows on every control (%d without a frame: %s)" % [name, unseen.size(), names.call(unseen)])
	main.ui.hide_all()
	await _frames(2)


func _run() -> void:
	main.new_game()
	await _frames(3)
	main.ui.hide_all()
	main.ui.scheme = "gamepad"
	var w: World = main.world
	var ui = main.ui
	# 1. every window
	var adult: NPC = null
	var trader: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and adult == null:
			adult = n
		if n.alive and n.job == "merchant" and trader == null:
			trader = n
	var reeve: NPC = w.npc(w.reeve_id) if w.reeve_id >= 0 else null
	var opens := [
		["pause menu", func(): ui.show_pause()],
		["Pack (general)", func(): ui.show_inventory("general")],
		["Skills", func(): ui.show_skills()],
		["Journal", func(): ui.show_journal(0)],
		["Village map", func(): ui.show_map("village")],
		["Region map", func(): ui.show_map("region")],
		["settings", func(): ui.show_settings(func(): ui.show_pause())],
		["controls", func(): ui.show_controls(func(): ui.show_pause())],
		["wiki", func(): ui.show_wiki(func(): ui.show_pause())],
		["credits", func(): ui.show_credits()],
		["players", func(): ui.show_players()],
		["home", func(): ui.show_home()],
		["land", func(): ui.show_land(reeve)],
		["building menu", func(): ui.show_build_menu()],
		["resources", func(): ui.show_resources()],
	]
	if adult != null:
		opens.append(["talk", func(): ui.show_talk(adult)])
		opens.append(["gifts", func(): ui.show_gifts(adult)])
		opens.append(["employ", func(): ui.show_employ(adult)])
		opens.append(["contract", func(): ui.show_contract(adult)])
	if trader != null:
		opens.append(["trade", func(): ui.show_trade(trader)])
	if reeve != null:
		opens.append(["manor jobs", func(): ui.show_manor_jobs(reeve)])
	if not w.stalls.is_empty():
		var sid = w.stalls.keys()[0]
		opens.append(["stall", func(): ui.show_stall(str(sid))])
	for o in opens:
		o[1].call()
		await _audit(o[0])
	# 2. the travel bar, through real joypad events
	ui.hide_all()
	await _frames(2)
	var ow: Overworld = w.map.overworld
	var dest: Vector2i = ow.sites[0].center
	var why: String = main.travel.start(main, dest)
	check(why == "", "a journey is chosen (%s)" % why)
	RegionTravel.suspend(w.player)
	await _frames(4)
	var bar: TravelBar = ui.travel_bar
	check(bar.visible and bar.resume_btn.visible, "the travel bar shows Resume and Dismiss while the journey is stopped")
	main.target_options = []
	await _press(JOY_BUTTON_DPAD_RIGHT)
	check(ui.get_viewport().gui_get_focus_owner() == bar.resume_btn, "D-pad Right puts the pad on Resume")
	check(_shows_focus(bar.resume_btn), "Resume shows the pad's focus")
	await _press(JOY_BUTTON_A)
	await _frames(3)
	check(RegionTravel.active(w.player), "A on Resume sets off again")
	check(ui.get_viewport().gui_get_focus_owner() == bar.dismiss_btn, "the pad's focus stays on the bar (Dismiss) once walking")
	await _press(JOY_BUTTON_B)
	check(not bar.has_pad_focus(), "B gives the pad back to play")
	RegionTravel.suspend(w.player)
	await _frames(3)
	await _press(JOY_BUTTON_DPAD_LEFT)
	check(ui.get_viewport().gui_get_focus_owner() == bar.dismiss_btn, "D-pad Left puts the pad on Dismiss")
	await _press(JOY_BUTTON_A)
	await _frames(3)
	check(not RegionTravel.has_destination(w.player) and not bar.visible, "A on Dismiss forgets the destination and the bar goes")
	# the mouse still presses the buttons
	main.travel.start(main, dest)
	RegionTravel.suspend(w.player)
	await _frames(3)
	bar.resume_btn.pressed.emit()
	await _frames(2)
	check(RegionTravel.active(w.player), "a click on Resume still sets off")
	main.travel.dismiss(main)
	await _frames(2)
	# 3. the Region map's buttons
	ui.show_map("region")
	await _frames(4)
	check(not (ui.get_viewport().gui_get_focus_owner() is BaseButton), "the Region map opens with the pad on the map, not a button (A travels)")
	await _press(JOY_BUTTON_BACK)
	var f = ui.get_viewport().gui_get_focus_owner()
	check(f is BaseButton and ui.panel.is_ancestor_of(f), "View puts the pad on the map window's buttons (%s)" % str(f.get("text") if f != null else "none"))
	check(ui.is_open("map"), "View on the map does not open the Pack")
	await _press(JOY_BUTTON_BACK)
	check(not (ui.get_viewport().gui_get_focus_owner() is BaseButton), "View again gives the pad back to the map")
	await _press(JOY_BUTTON_BACK)
	var first = ui.get_viewport().gui_get_focus_owner()
	var label := str(first.get("text")) if first != null else ""
	await _press(JOY_BUTTON_A)
	await _frames(3)
	check(label == "Village" and ui.map_mode == "village", "A presses the focused map button (%s: the Village map)" % label)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
