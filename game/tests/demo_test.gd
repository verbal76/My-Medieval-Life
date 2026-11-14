extends SceneTree
## DEMO-01 (owner 2026-11-03): the demo's 120 minutes of active play per world, its expiry, the full game's loading of demo saves, and
## the Steam promotion. The clock is driven with chosen frame times (no real waiting). Run headless:
##   godot --headless --path game --script res://tests/demo_test.gd

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
	_test_clock()
	_test_steam()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/demo_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ------------------------------------------------------------------ the clock (pure) ----------
func _test_clock() -> void:
	var m := {}
	check(is_equal_approx(Demo.remaining(m), 7200.0) and not Demo.expired(m), "a new world has 120 minutes")
	Demo.tick(m, 0.1)
	check(is_equal_approx(Demo.remaining(m), 7199.9), "active play counts")
	Demo.tick(m, 3600.0)
	check(is_equal_approx(Demo.remaining(m), 7199.9 - float(Demo.cfg().max_step)), "a frame after a suspension or a clock jump counts no more than %.2f s" % float(Demo.cfg().max_step))
	var before := Demo.remaining(m)
	Demo.tick(m, -5.0)
	Demo.tick(m, NAN)
	Demo.tick(m, INF)
	check(is_equal_approx(Demo.remaining(m), before), "negative, NaN and infinite frame times count nothing")
	var a := {}
	var b := {}
	for i in 60 * 60:
		Demo.tick(a, 1.0 / 60.0)
	for i in 20 * 60:
		Demo.tick(b, 1.0 / 20.0)
	check(absf(Demo.remaining(a) - Demo.remaining(b)) < 0.01 and absf(Demo.remaining(a) - 7140.0) < 0.01, "a minute at 60 and at 20 frames a second counts the same minute")
	var w := {}
	var events := []
	w.demo = {"allowance": 7200.0, "active": 7200.0 - 1801.0}
	for i in 2000 * 4:
		events.append_array(Demo.tick(w, 0.25))
	check(events == ["warn:1800", "warn:600", "warn:300", "warn:60", "expired"], "warnings at 30, 10, 5 and 1 minutes left, each once, then the end (%s)" % str(events))
	check(Demo.expired(w) and Demo.remaining(w) == 0.0 and Demo.tick(w, 1.0).is_empty(), "expired: nothing left, never negative, nothing more counts")
	var saved: Dictionary = JSON.parse_string(JSON.stringify({"demo": {"allowance": 7200.0, "active": 1234.5, "warned": [1800]}}))
	check(is_equal_approx(Demo.remaining(saved), 7200.0 - 1234.5) and (Demo.state(saved).warned as Array) == [1800], "the time used and the warnings shown come back from a save (another session)")
	var copy: Dictionary = saved.duplicate(true)
	Demo.tick(copy, 0.2)
	check(not is_equal_approx(Demo.remaining(copy), Demo.remaining(saved)), "two worlds keep their own clocks")
	var x := {"demo": {"allowance": 7200.0, "active": 99999.0}}
	check(Demo.expired(x) and Demo.remaining(x) == 0.0, "a record with more used than allowed reads as expired, with nothing left")
	check(Demo.text(6120.0) == "1h 42m" and Demo.text(600.0) == "10m" and Demo.text(30.0) == "30s", "the timer reads 1h 42m, 10m, 30s")


# ------------------------------------------------------------------ Steam -----------------------
func _test_steam() -> void:
	var opened := []
	SteamPromo.opener = func(u: String) -> int:
		opened.append(u)
		return OK
	# NAME-01 (owner 2026-11-13): the shipped file names Forge My Life's App ID, 5615690 (never the store item id 1442556)
	SteamPromo.set_override({})
	check(str(SteamPromo.cfg().get("app_id", "")) == "5615690" and SteamPromo.url() == "https://store.steampowered.com/app/5615690/" and SteamPromo.label() == "Wishlist on Steam" and SteamPromo.has_page(),
			"game/data/steam.json: Forge My Life's store page (App ID 5615690), 'Wishlist on Steam'")
	var c: Dictionary = SteamPromo.cfg().duplicate(true)
	c.app_id = ""
	c.store_url = ""
	SteamPromo.set_override(c)
	check(SteamPromo.url() == "https://store.steampowered.com/" and SteamPromo.label() == "Coming Soon on Steam" and not SteamPromo.has_page(), "with no store page set: the Steam store's front page, 'Coming Soon on Steam' (no claim it can be wishlisted)")
	check(SteamPromo.open() == "" and opened == ["https://store.steampowered.com/"], "the button opens the generic destination")
	c.app_id = "1234560"
	SteamPromo.set_override(c)
	check(SteamPromo.url() == "https://store.steampowered.com/app/1234560/" and SteamPromo.label() == "Wishlist on Steam", "with an app id set: the game's page, 'Wishlist on Steam'")
	SteamPromo.opener = func(u: String) -> int: return ERR_CANT_OPEN
	check(SteamPromo.open().contains("could not be opened"), "a link that cannot open says so, and nothing else happens")
	SteamPromo.set_override({})
	SteamPromo.opener = func(u: String) -> int: return OK


# ------------------------------------------------------------------ the game ----------------------
func _frames(n: int, dt: float) -> void:
	for i in n:
		main._process(dt)


func _run() -> void:
	main.set_process(false)
	# B42-DEMO-WINDOW-TITLE: the full game (no demo feature) keeps its window's own title; the demo build's start sets its own
	check(root.title.begins_with("Forge My Life") and not root.title.contains("Demo"), "the full game's window title is its own (%s)" % root.title)
	Demo.force = 1
	main.apply_window_title()
	check(root.title == "Forge My Life Demo", "the demo's start titles its window Forge My Life Demo (%s)" % root.title)
	Demo.force = -1
	root.title = str(ProjectSettings.get_setting("application/config/name"))
	Demo.force = 1
	# the title (no world yet): nothing counts; the Steam button is there in the demo
	var ui = main.ui
	check(ui.panel_body.find_child("SteamButton", true, false) != null, "the demo's main menu has the Steam button")
	main.new_game()
	await process_frame
	check(main.save_meta.has("demo") and is_equal_approx(Demo.remaining(main.save_meta), 7200.0), "a new world in the demo gets its 120 minutes")
	var r0: float = Demo.remaining(main.save_meta)
	main.paused = true
	_frames(120, 0.1)
	check(is_equal_approx(Demo.remaining(main.save_meta), r0), "paused (a menu, a window that pauses the world): no time counts")
	main.paused = false
	main.app_focused = false
	var m0: float = main.world.minutes
	_frames(120, 0.1)
	check(is_equal_approx(Demo.remaining(main.save_meta), r0) and is_equal_approx(main.world.minutes, m0), "in the background: no time counts, and the world waits")
	main.app_focused = true
	_frames(100, 0.1)
	check(absf(r0 - Demo.remaining(main.save_meta) - 10.0) < 0.01 and main.world.minutes > m0, "playing: ten seconds of play count ten seconds")
	# a save and a load keep the clock; the opened Steam link changes nothing
	main.save_game(false)
	var used: float = 7200.0 - Demo.remaining(main.save_meta)
	SteamPromo.open()
	main.continue_game()
	await process_frame
	check(absf(7200.0 - Demo.remaining(main.save_meta) - used) < 0.01, "saved and loaded, the world keeps its time used (%.1f s)" % used)
	# near the end: the last warning, then expiry
	main.save_meta.demo.active = 7200.0 - 61.0
	main.save_meta.demo.warned = [1800, 600, 300]
	_frames(60 * 4 + 20, 0.25)
	check(main.save_meta.demo.warned.has(60), "the one-minute warning is shown once")
	var day_at_end: float = main.world.minutes
	check(Demo.expired(main.save_meta) and main.paused and ui.is_open("demo_expired"), "at the end the world stops, and the demo's end screen is shown")
	check(ui.panel_body.find_child("SteamButton", true, false) != null, "the end screen has the Steam button")
	_frames(200, 0.1)
	check(is_equal_approx(main.world.minutes, day_at_end), "after the end the world does not advance")
	var npcs: int = main.world.npcs.size()
	var coins: int = main.world.total_coins()
	main.continue_game()
	await process_frame
	check(ui.is_open("demo_expired") and main.paused and Demo.expired(main.save_meta), "the saved, expired world is kept and cannot be resumed in the demo")
	main.ui.show_title(main.can_continue())
	var cont := _button_text_starting("Continue")
	check(cont.contains("demo time used"), "the title marks the expired world (%s)" % cont)
	# Android: the demo and the full game keep their saves apart; the player carries the world across with Export and Import (a file)
	var exported := "user://test_saves/demo_test/carried.json"
	var ex: Dictionary = main.export_save_to(exported)
	check(ex.ok and FileAccess.file_exists(exported), "the demo's world is exported to a file the player chooses (%s)" % str(ex.get("reason", "")))
	var demo_id := str(main.save_meta.get("save_id", ""))
	Demo.force = 0
	main.save_path = "user://test_saves/demo_test/full_app/save1.json"      # the full game's own, separate storage
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves/demo_test/full_app"))
	var im: Dictionary = main.import_save_from(exported)
	await process_frame
	check(im.ok and str(main.save_meta.get("save_id", "")) == demo_id, "the full game imports it as the same world (its id kept, %s)" % str(im.get("reason", "")))
	# the full game: the same save plays on, unrestricted, with everything in it
	main.continue_game()
	await process_frame
	check(main.running and not main.paused and not ui.is_open("demo_expired"), "the full game loads the expired demo world and plays it")
	check(main.world.npcs.size() == npcs and main.world.total_coins() == coins, "nothing is lost: %d villagers, %d coins" % [npcs, coins])
	var m1: float = main.world.minutes
	_frames(200, 0.1)
	check(main.world.minutes > m1 and not ui.is_open("demo_expired"), "and time goes on: no demo restriction in the full game")
	# a new world in the demo: a fresh allowance
	Demo.force = 1
	main.new_game()
	await process_frame
	check(is_equal_approx(Demo.remaining(main.save_meta), 7200.0) and not Demo.expired(main.save_meta), "a new world in the demo starts with a fresh 120 minutes")
	# the same world in both builds goes on the same way before the end (the demo touches nothing in the world)
	var d: Dictionary = main.world.to_dict()
	var worlds := []
	for f in [1, 0]:
		Demo.force = f
		var w := World.new()
		w.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
		var meta := {}
		for i in 2000:
			w.update(0.5)
			if f == 1:
				Demo.tick(meta, 0.5)
		worlds.append(JSON.stringify(w.to_dict()))
		w.dispose()
	check(worlds[0] == worlds[1], "the same world goes on identically in the demo and the full game")
	Demo.force = -1
	main.ui.show_title(main.can_continue())
	check(main.ui.panel_body.find_child("SteamButton", true, false) != null, "the full game's main menu has the Steam button too")
	print("%d checks, %d failures" % [checks, failures])
	SteamPromo.opener = Callable()            # (the test's lambda must not outlive the test in a static)
	main.queue_free()                         # (a clean exit: the scene and its world freed before quitting)
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)


func _button_text_starting(prefix: String) -> String:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		if str(b.text).begins_with(prefix):
			return str(b.text)
	return ""
