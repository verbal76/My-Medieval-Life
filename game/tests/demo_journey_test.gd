extends SceneTree
## DEMO-01 (owner 2026-11-03) as a player meets it, Build 25 verification (Stage E): the demo edition driven through the real game
## scene and its windows, beside demo_test.gd (which checks the clock's rules). Checks: the export presets (three full, three demo
## with the "demo" feature, the same files shipped, tests left out, the Android demo its own package); the title in the demo and the
## full game (Demo marked, nothing for developers on it); New game, creation and the origin in the demo, the creation note and the
## HUD's timer; play counting down on the timer; the 30-minute warning; the end at 120 minutes with the approved end screen (no crash,
## no dead end: the main menu, Continue showing the end screen again, a new world); the expired world saved, and loaded and played in
## the full game from the same save slot (Windows and Linux: one user folder) and through Export and Import (Android). Run headless:
##   godot --headless --path game --script res://tests/demo_journey_test.gd

const DIR := "user://test_saves/demo_journey_test/"
const SAVE := DIR + "save1.json"
const DEV_WORDS := ["debug", "cheat", "god mode", "console", "teleport", "warp", "spawn", "give all", "developer", "test"]

var main
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func note(what: String) -> void:
	print("     " + what)


func _init() -> void:
	_test_presets()
	Demo.force = 1
	SteamPromo.opener = func(u: String) -> int: return OK         # never open a browser from a test
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = SAVE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ------------------------------------------------------------------ export presets ----------------
func _test_presets() -> void:
	var cf := ConfigFile.new()
	check(cf.load("res://export_presets.cfg") == OK, "export_presets.cfg reads")
	var by_name := {}
	for s in cf.get_sections():
		if s.begins_with("preset.") and not s.ends_with(".options"):
			by_name[str(cf.get_value(s, "name", ""))] = s
	for base in ["Windows Desktop", "Linux", "Android"]:
		var full: String = by_name.get(base, "")
		var demo: String = by_name.get(base + " Demo", "")
		check(full != "" and demo != "", "%s has a full preset and a demo preset" % base)
		if full == "" or demo == "":
			continue
		check(not str(cf.get_value(full, "custom_features", "")).contains("demo"), "%s (full): no demo feature" % base)
		check(str(cf.get_value(demo, "custom_features", "")).split(",").has("demo"), "%s Demo: the 'demo' feature (Demo.is_demo)" % base)
		check(cf.get_value(full, "exclude_filter", "") == cf.get_value(demo, "exclude_filter", "") and cf.get_value(full, "export_filter", "") == cf.get_value(demo, "export_filter", ""),
				"%s Demo ships the same files as the full game (one source)" % base)
		check(str(cf.get_value(full, "exclude_filter", "")).contains("tests/*"), "%s: the test scripts (developer tools) are left out of the package" % base)
		check(str(cf.get_value(full, "export_path", "")) != str(cf.get_value(demo, "export_path", "")), "%s: the demo exports to its own file" % base)
	var a_full: String = by_name.get("Android", "")
	var a_demo: String = by_name.get("Android Demo", "")
	if a_full != "" and a_demo != "":
		var id_full := str(cf.get_value(a_full + ".options", "package/unique_name", ""))
		var id_demo := str(cf.get_value(a_demo + ".options", "package/unique_name", ""))
		check(id_full == "com.hotatticgames.mymedievallife.dev" and id_demo == id_full + ".demo", "Android: the full game keeps its package id and the demo has its own (%s, %s)" % [id_full, id_demo])


# ------------------------------------------------------------------ helpers -----------------------
func _frames(n: int, dt := 0.1) -> void:
	for i in n:
		main._process(dt)


func _buttons() -> Array:
	return main.ui.panel_body.find_children("*", "Button", true, false).map(func(b): return str(b.text))


func _labels() -> Array:
	return main.ui.panel_body.find_children("*", "Label", true, false).map(func(l): return str(l.text))


func _press(caption: String, prefix := false) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		var t := str((b as Button).text)
		if (t == caption or (prefix and t.begins_with(caption))) and not (b as Button).disabled:
			(b as Button).pressed.emit()
			return true
	return false


func _no_dev(where: String) -> void:
	var bad := []
	for t in _buttons():
		for word in DEV_WORDS:
			if str(t).to_lower().contains(word):
				bad.append(t)
	check(bad.is_empty(), "%s: nothing for developers offered (%s)" % [where, ", ".join(_buttons())])


## New game, a name, Begin, then the origin's Begin: the player's way into a new world.
func _new_world(name: String) -> bool:
	if not main.ui.is_open("creation"):
		return false
	var edits: Array = main.ui.panel_body.find_children("*", "LineEdit", true, false)
	if edits.size() < 2:
		return false
	(edits[0] as LineEdit).text = name
	(edits[1] as LineEdit).text = "Demo"
	if not _press("Begin") or not main.ui.is_open("origin"):
		return false
	return _press("Begin")


func _saved_meta() -> Dictionary:
	var r := SaveStore.inspect(SAVE, World.SAVE_VERSION)
	return (r.data as Dictionary).get("meta", {}) if r.state == "ok" else {}


# ------------------------------------------------------------------ the demo, played ---------------
func _run() -> void:
	var ui = main.ui
	main.set_process(false)
	check(ui.is_open("title"), "the demo opens on its title")
	check(_labels().any(func(t): return t.contains("120 minutes")), "the demo's title says each world has 120 minutes")
	check(ui.panel_body.find_child("SteamButton", true, false) != null, "the demo's title has the Steam button")
	_no_dev("the demo's title")
	_press("Settings")
	_no_dev("the demo's Settings")
	for tab in ["display", "interface", "controls", "saves"]:
		ui.show_settings(func(): ui.show_title(main.can_continue()), tab)
		_no_dev("the demo's Settings, %s" % tab)
		if tab == "saves":
			note("Settings, Saves in this (desktop) run offers: %s%s" % [", ".join(_buttons()), "  (the gameplay recording, 'for testing', is shown on Windows and Linux: SIM-GATE-01 amendment)" if main.recording_supported() else ""])
	ui.show_title(main.can_continue())
	check(_press("New game") and _new_world("Ada"), "New game, a name, Begin and the origin's Begin, in the demo")
	await process_frame
	var w: World = main.world
	check(main.running and not main.paused and not ui.modal(), "the demo world is in play")
	check(is_equal_approx(Demo.remaining(main.save_meta), 7200.0), "the new demo world has its 120 minutes")
	var msgs: Array = w.player_messages().map(func(e): return str(e[2]))
	check(msgs.has(Demo.CREATION_NOTE), "the demo's note is shown at the start of a new world and kept in the journal (%d messages)" % msgs.size())
	var id0 := str(main.save_meta.get("save_id", ""))
	# the HUD's timer counts down with play
	_frames(600)                    # one minute of play
	ui.update_hud()
	check(absf(Demo.remaining(main.save_meta) - 7140.0) < 0.01, "a minute of play counts a minute (%.1f s left)" % Demo.remaining(main.save_meta))
	check(ui.demo_label.visible and str(ui.demo_label.text) == "Demo time left: 1h 59m", "the HUD shows the time left (%s)" % str(ui.demo_label.text))
	# the pause menu stops the clock and offers nothing for developers
	ui.show_pause()
	main.paused = true
	_no_dev("the pause menu")
	var r0 := Demo.remaining(main.save_meta)
	_frames(300)
	check(is_equal_approx(Demo.remaining(main.save_meta), r0), "paused on the menu: the clock waits")
	ui.hide_all()
	main.paused = false
	# the 30-minute warning, once, in the journal
	main.save_meta.demo.active = 7200.0 - 1800.5
	_frames(10)
	msgs = w.player_messages().map(func(e): return str(e[2]))
	check(msgs.has(Demo.warning(1800)), "the warning at 30 minutes left is shown (%s)" % Demo.warning(1800))
	# the end: the world stops, is saved, and the approved end screen is shown
	main.save_meta.demo.active = 7200.0 - 1.0
	main.save_meta.demo.warned = [1800, 600, 300, 60]
	var coins: int = w.total_coins()
	var pos: Vector2 = w.player.pos
	_frames(20)
	check(Demo.expired(main.save_meta) and main.paused and ui.is_open("demo_expired"), "at 120 minutes the world stops and the demo's end screen opens")
	check(_labels().has(Demo.EXPIRED_NOTE), "the end screen says the approved words: \"%s\"" % Demo.EXPIRED_NOTE)
	check(_buttons().has("Start a new world") and _buttons().has("Main menu") and ui.panel_body.find_child("SteamButton", true, false) != null,
			"the end screen offers a new world, the main menu and the Steam page (%s)" % ", ".join(_buttons()))
	var meta := _saved_meta()
	check(not meta.is_empty() and Demo.expired(meta) and str(meta.get("save_id", "")) == id0, "the expired world is saved, marked used up, with its id")
	var m_end: float = w.minutes
	_frames(300)
	check(is_equal_approx(w.minutes, m_end) and w.player.pos == pos and w.total_coins() == coins, "after the end nothing moves on")
	# no dead end: the main menu, Continue (the end screen again), Settings' Export
	check(_press("Main menu") and ui.is_open("title"), "Main menu goes to the title")
	check(_buttons().any(func(t): return t.begins_with("Continue") and t.contains("demo time used")), "the title marks the used-up world (%s)" % ", ".join(_buttons()))
	check(_press("Continue", true), "Continue pressed")
	await process_frame
	check(ui.is_open("demo_expired") and main.paused, "Continue shows the end screen again: the expired world is not resumed in the demo")
	var exported := DIR + "carried.json"
	var ex: Dictionary = main.export_save_to(exported)
	check(ex.ok, "the expired world is exported to a file (Settings, Saves: Export) (%s)" % str(ex.get("reason", "")))
	# the full game: Windows and Linux share the user folder (one config/name), so the full game's Continue finds the demo's world
	Demo.force = 0
	ui.show_title(main.can_continue())
	_no_dev("the full game's title")
	check(not _buttons().any(func(t): return t.contains("demo")), "the full game's title says nothing of the demo (%s)" % ", ".join(_buttons()))
	check(_press("Continue"), "the full game: Continue pressed on the demo's save slot")
	await process_frame
	w = main.world
	check(main.running and not main.paused and not ui.modal() and str(main.save_meta.get("save_id", "")) == id0, "the full game continues the expired demo world (its id %s)" % id0)
	check(w.total_coins() == coins and w.player.pos == pos and is_equal_approx(w.minutes, m_end), "exactly where it stopped: %d coins, the player at %s, minute %.1f" % [coins, str(pos), m_end])
	_frames(300)
	check(w.minutes > m_end and not ui.is_open("demo_expired") and not ui.demo_label.visible, "and plays on with no demo limit or timer")
	check(main.save_game(false), "the full game saves the world")
	# Android: the full game is its own app with its own storage; the exported file is imported there
	main.save_path = DIR + "full_app/save1.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + "full_app"))
	var im: Dictionary = main.import_save_from(exported)
	await process_frame
	check(im.ok and str(main.save_meta.get("save_id", "")) == id0, "Android: the full game imports the exported demo world (%s)" % str(im.get("reason", "")))
	main.continue_game()
	await process_frame
	check(main.running and not main.paused and not ui.is_open("demo_expired"), "and plays it")
	# back in the demo: the end screen's "Start a new world" gives a fresh world
	main.save_path = SAVE
	Demo.force = 1
	main.continue_game()
	await process_frame
	check(ui.is_open("demo_expired"), "the demo again: its saved world is the full game's now played-on world, still used up in the demo")
	check(_press("Start a new world") and ui.is_open("creation"), "Start a new world opens character creation")
	check(_new_world("Bea"), "a second world begun")
	await process_frame
	check(main.running and not main.paused and is_equal_approx(Demo.remaining(main.save_meta), 7200.0) and str(main.save_meta.get("save_id", "")) != id0,
			"a new demo world has a fresh 120 minutes and its own id")
	var prev := SAVE.get_basename() + ".previous.json"
	var kept: bool = FileAccess.file_exists(prev) and str((SaveStore.inspect(prev, World.SAVE_VERSION).data as Dictionary).get("meta", {}).get("save_id", "")) == id0
	check(kept, "the used-up world is kept beside it (%s)" % prev.get_file())
	check(main.kept_worlds().any(func(e): return str(e.get("save_id", "")) == id0 and bool(e.get("expired", false))),
		"the kept world (%s) is offered on the title's Kept worlds list, marked used up (B25-DEMO-KEPT-WORLDS)" % prev.get_file())
	# journey finding 3 (DEMO-01: "Do not delete expired worlds"): a further new world puts Bea's world aside as the previous game;
	# the used-up world it would have replaced is kept under its own name, never removed
	var bea := str(main.save_meta.get("save_id", ""))
	main.save_game(false)
	main.running = false
	ui.show_title(true)
	check(_press("New game") and _new_world("Cid"), "a third world begun from the title")
	await process_frame
	var kept_as := DIR + "save1.expired-%s.json" % id0
	var arch: Dictionary = SaveStore.inspect(kept_as, World.SAVE_VERSION).data if FileAccess.file_exists(kept_as) else {}
	var prev_id := str((SaveStore.inspect(prev, World.SAVE_VERSION).data as Dictionary).get("meta", {}).get("save_id", "")) if FileAccess.file_exists(prev) else ""
	check(not arch.is_empty() and str(arch.get("meta", {}).get("save_id", "")) == id0 and Demo.expired(arch.get("meta", {})) and prev_id == bea,
		"the used-up world is not deleted by the next new world: it is kept as %s, still marked used up; Bea's world is the previous game" % kept_as.get_file())
	print("%d checks, %d failures" % [checks, failures])
	Demo.force = -1
	SteamPromo.opener = Callable()
	main.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)
