extends SceneTree
## Build 21 (owner directive 2026-10-24, section 2): the menus that open a world to friends and join one, in the real game scene.
##   Layout: the pause menu, Open to friends (closed and open) and Join a game (with games found and a message) are compact
##   windows, not the whole screen, and every button and text field lies inside the screen, on a phone in landscape (2404 x 1080,
##   2000 x 1119; the phone layout) and on a PC (1920 x 1080, 1280 x 800).
##   Behaviour: addresses typed by hand, hosting refused when the port is taken (the error shown), the name kept for next time,
##   the join window's refusals (no name, no address, a version refusal from the host), Cancel; a found game fills the address.
##   Smoke: a second Godot process (tests/net_host.gd, mode "ui") opens its world by its pause menu with a password; this process
##   joins from the title screen's Join a game by the address 127.0.0.1: both characters appear, both move, the guest leaves by its
##   pause menu (Leave the game), the host's world carries on; the host stops hosting from its window.
##   godot --headless --path game --script res://tests/net_ui_test.gd

var main
var checks := 0
var failures := 0
var dir := "user://test_net_ui/"
var seq := 0
var host_pid := -1


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("new_game"):
		print("FAIL the game's main script did not load: stopping")
		quit(1)
		return
	main.save_path = dir + "save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	main.new_game()
	await _layout()
	await _behaviour()
	await _smoke()
	if host_pid > 0 and OS.is_process_running(host_pid):
		OS.kill(host_pid)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- helpers ----------------------
func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func _screen(sz: Vector2i, phone: bool) -> void:
	root.size = sz
	main.settings.phone = phone
	main.settings.ui_size = "normal"
	main.settings.apply(self)


func find(name: String) -> Node:
	return main.ui.panel_body.find_child(name, true, false)


func press(text: String) -> bool:
	for b in main.ui.panel_body.find_children("*", "BaseButton", true, false):
		if b is Button and (b as Button).text.begins_with(text) and not (b as Button).disabled and (b as Button).is_visible_in_tree():
			(b as Button).pressed.emit()
			return true
	return false


func status_text() -> String:
	var l: Label = find("JoinStatus")
	return l.text if l != null and l.visible else ""


## Every visible button and text field of the open window that is not wholly inside the screen (strictly: no scrolling to it).
func outside() -> Array:
	var view: Rect2 = root.get_visible_rect().grow(0.5)
	var bad := []
	for c: Control in main.ui.panel.find_children("*", "Control", true, false):
		if (c is BaseButton or c is LineEdit) and c.is_visible_in_tree():
			var r := c.get_global_rect()
			if r.size.x > 0.0 and not view.encloses(r):
				bad.append("%s %s" % [(c as Button).text if c is Button else c.name, str(r)])
	var pr: Rect2 = main.ui.panel.get_global_rect()
	if not view.encloses(pr):
		bad.append("the window %s" % str(pr))
	return bad


## The window is compact: narrower than the screen (by a margin) and not the full screen's height unless it needs it.
func compact_ok(most_w: float) -> bool:
	var view: Vector2 = root.get_visible_rect().size
	var pr: Rect2 = main.ui.panel.get_global_rect()
	return pr.size.x <= most_w + 1.0 and pr.size.x < view.x - 40.0 and pr.size.y <= view.y


func status() -> Dictionary:
	var f := FileAccess.open(dir + "status.json", FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if typeof(d) == TYPE_DICTIONARY else {}


func command(d: Dictionary) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(status().get("seq", -1)) >= seq, 5.0)


# ---------------------------------------------------------------- layout -----------------------
func _layout() -> void:
	var ui: GameUI = main.ui
	var sizes := [[Vector2i(2404, 1080), true], [Vector2i(2000, 1119), true], [Vector2i(1920, 1080), false], [Vector2i(1280, 800), false]]
	for sz in sizes:
		_screen(sz[0], sz[1])
		var where := "%s (%s)" % [str(sz[0]), "phone" if sz[1] else "desktop"]
		var view: Vector2 = root.get_visible_rect().size
		ui.show_pause()
		await frames()
		var bad := outside()
		check(bad.is_empty() and ui.close_btn.is_visible_in_tree(), "pause menu: every button on screen at %s %s" % [where, str(bad.slice(0, 3))])
		check(compact_ok(580.0), "pause menu: a compact window at %s (%s in %s), not a full-screen background" % [where, str(ui.panel.size), str(view)])
		check(find("PauseButtons") != null and press("Open to friends"), "pause menu: Open to friends is there")
		await frames()
		check(ui.panel_kind == "host" and find("HostPassword") != null and find("HostAddress") != null, "Open to friends: the address, port and a password field (%s)" % (find("HostAddress").text if find("HostAddress") else "none"))
		bad = outside()
		check(bad.is_empty() and compact_ok(560.0), "Open to friends fits at %s, compact %s" % [where, str(bad.slice(0, 3))])
		# open: its status
		var why: String = main.host_game({"port": 47950, "discovery_port": 47951})
		NetWindow.show_host(ui)
		await frames()
		bad = outside()
		check(why == "" and bad.is_empty() and compact_ok(560.0) and find("HostPlayers") != null, "while hosting, its window fits at %s %s" % [where, str(bad.slice(0, 3))])
		main.stop_hosting()
		# join, with two games found and a message
		NetWindow.show_join(ui, "Wrong password.")
		await frames()
		main.net.discovery.found = {
			"192.168.1.20:47810": {"ip": "192.168.1.20", "port": 47810, "name": "Edmund", "world": "Thorne's village", "players": 1, "max": 2, "version": NetProtocol.full_version(), "locked": true, "seen": main.net.discovery._clock + 60.0},
			"192.168.1.31:47810": {"ip": "192.168.1.31", "port": 47810, "name": "A very long host name indeed", "world": "A village with a very long name in the far north", "players": 2, "max": 2, "version": "mml-net/1 save-20", "locked": false, "seen": main.net.discovery._clock + 60.0}}
		await wait(1.2)
		await frames()
		bad = outside()
		check(bad.is_empty() and compact_ok(600.0), "Join a game fits at %s, with games found and a message %s" % [where, str(bad.slice(0, 3))])
		check((find("JoinFound") as Node).find_children("*", "Button", true, false).size() == 2, "Join a game lists the games found on the network")
		main.net.discovery.close()
		ui.hide_all()
	_screen(Vector2i(1280, 720), false)


# ---------------------------------------------------------------- behaviour --------------------
func _behaviour() -> void:
	var ui: GameUI = main.ui
	var net: NetSession = main.net
	# addresses typed by hand
	check(NetWindow.parse_address("192.168.1.20") == {"ip": "192.168.1.20", "port": NetProtocol.GAME_PORT}, "an address typed by hand: the game's port")
	check(NetWindow.parse_address(" 10.0.0.5:47900 ") == {"ip": "10.0.0.5", "port": 47900}, "an address with its port")
	check(NetWindow.parse_address("127.0.0.1").ip == "127.0.0.1", "loopback")
	check(NetWindow.parse_address("").is_empty() and NetWindow.parse_address("1.2.3.4:99999").is_empty() and NetWindow.parse_address("not an address/x").is_empty(), "nonsense is refused")
	var lan := NetDiscovery.lan_addresses()
	check(lan.all(func(a): return a.is_valid_ip_address() and not a.begins_with("127.") and not a.contains(":")), "this device's addresses to show: LAN IPv4 only (%s)" % str(lan))
	# hosting refused when the game's port is in use: the window says so
	var blocker := ENetMultiplayerPeer.new()
	var held := blocker.create_server(NetProtocol.GAME_PORT, 1) == OK
	ui.show_pause()
	await frames()
	press("Open to friends")
	await frames()
	var opened := press("Open to friends")
	await frames()
	var err: Label = find("HostError")
	if held:
		check(opened and not net.is_host() and err != null and err.visible and err.text.contains(str(NetProtocol.GAME_PORT)), "hosting on a port in use fails with a clear message (%s)" % (err.text if err else "-"))
	blocker.close()
	# open, then stop: the world carries on, saved
	if not lan.is_empty():
		NetWindow.show_host(ui)
		await frames()
		(find("HostPassword") as LineEdit).text = "oak"
		press("Open to friends")
		await frames()
		check(net.is_host() and net.password == "oak" and net.port == NetProtocol.GAME_PORT and find("HostPlayers") != null and (find("HostPlayers") as Label).text.begins_with("Waiting"),
			"Open to friends opens the world on port %d with the password; the window shows who is playing" % NetProtocol.GAME_PORT)
		check(ui.panel_kind == "host" and press("Stop hosting"), "Stop hosting is offered")
		await frames()
		check(not net.is_host() and main.running and main.world != null and SaveStore.any_exists(main.save_path), "Stop hosting closes the session; the world is intact and saved")
	else:
		check(true, "(no LAN address on this machine: the open-and-stop check runs in the smoke below on loopback)")
	# join: refusals and Cancel
	main.settings.net_name = ""
	NetWindow.show_join(ui)
	await frames()
	(find("JoinName") as LineEdit).text = ""
	(find("JoinAddress") as LineEdit).text = "127.0.0.1:47960"
	press("Join")
	await frames()
	check(status_text() == NetSession.REFUSALS["name"] and not net.is_guest(), "no name: the player is asked for one")
	(find("JoinName") as LineEdit).text = "Ann"
	(find("JoinAddress") as LineEdit).text = ""
	press("Join")
	await frames()
	check(status_text().begins_with("Type the host's address") and not net.is_guest(), "no address: the player is told where to find it")
	(find("JoinAddress") as LineEdit).text = "127.0.0.1:47960"
	press("Join")
	await frames()
	check(net.is_guest() and status_text().begins_with("Connecting to 127.0.0.1") and (find("JoinCancel") as Button).visible and (find("JoinGo") as Button).disabled, "Join: connecting, shown, with Cancel")
	check(main.settings.net_name == "Ann" and main.settings.net_address == "127.0.0.1:47960", "the name and address are kept for next time")
	net.s_refuse("version")                   # as the host's refusal arrives
	await frames()
	check(status_text() == NetSession.REFUSALS["version"] and not net.is_guest() and not (find("JoinGo") as Button).disabled, "a refusal from the host is shown in the window (%s)" % status_text())
	press("Join")
	await frames()
	press("Cancel")
	await frames()
	check(not net.is_guest() and status_text() == "Cancelled.", "Cancel stops joining")
	# a found game: picking it fills the address; a locked one asks for the password
	main.net.discovery.found = {"192.168.1.20:47812": {"ip": "192.168.1.20", "port": 47812, "name": "Edmund", "world": "Thorne's village", "players": 1, "max": 2, "version": NetProtocol.full_version(), "locked": true, "seen": main.net.discovery._clock + 60.0}}
	await wait(1.2)
	var b: Button = (find("JoinFound") as Node).find_children("*", "Button", true, false)[0]
	b.pressed.emit()
	await frames()
	check((find("JoinAddress") as LineEdit).text == "192.168.1.20:47812" and status_text().ends_with("needs a password.") and not net.is_guest(), "a locked game found: its address filled, the password asked for")
	var name_kept: String = main.settings.net_name
	main.settings.load_file()
	check(main.settings.net_name == name_kept, "the name is saved in the settings file")
	main.net.discovery.close()
	ui.hide_all()


# ---------------------------------------------------------------- smoke ------------------------
func _smoke() -> void:
	var ui: GameUI = main.ui
	var net: NetSession = main.net
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/net_host.gd", "--", str(NetProtocol.GAME_PORT), str(NetProtocol.DISCOVERY_PORT), "ui", dir]
	host_pid = OS.create_process(OS.get_executable_path(), args)
	var up := await until(func(): return status().get("hosting", false), 90.0)
	check(up, "smoke: the host opens its world by its pause menu (Open to friends, a password)")
	if not up:
		return
	# this player leaves its own world for the title, then Join a game by the address
	main.save_game(false)
	main.running = false
	ui.show_title(true)
	await frames()
	check(press("Join a game"), "smoke: the title screen offers Join a game")
	await frames()
	(find("JoinName") as LineEdit).text = "Ann"
	(find("JoinAddress") as LineEdit).text = "127.0.0.1"
	(find("JoinPassword") as LineEdit).text = "oak"
	press("Join")
	var joined := await until(func(): return main.guest_world, 30.0)
	check(joined, "smoke: the guest joins by the address 127.0.0.1 with the password")
	if not joined:
		return
	var st := status()
	var host_pid_ := int(st.host_pid)
	await until(func(): return net.avatars.has(host_pid_) and main.avatar_sprites.has(host_pid_), 5.0)
	check(net.avatars.has(host_pid_) and main.avatar_sprites.has(host_pid_), "smoke: the host's character appears on the guest's screen")
	await until(func(): return str(status().get("ui_players", "")).contains("Ann"), 5.0)
	check((status().players as Dictionary).size() == 2 and str(status().ui_players).contains("Ann"), "smoke: the host has the guest, and its window says who is playing (%s)" % str(status().ui_players))
	# both move
	var w: World = main.world
	var from: Vector2 = w.player.pos
	for act in ["move_right", "move_down", "move_left", "move_up"]:
		var end := Time.get_ticks_msec() + 1200
		while Time.get_ticks_msec() < end:
			Input.action_press(act)
			await process_frame
		Input.action_release(act)
		if w.player.pos.distance_to(from) > 1.0:
			break
	var mine := func() -> Vector2:
		var q: Array = status().players.get(str(net.my_pid), {}).get("pos", [0, 0])
		return Vector2(q[0], q[1])
	await until(func(): return mine.call().distance_to(w.player.pos) < 0.3, 4.0)
	check(w.player.pos.distance_to(from) > 1.0 and mine.call().distance_to(w.player.pos) < 0.3, "smoke: the guest walks %.1f tiles and the host has it there" % w.player.pos.distance_to(from))
	var h0: Array = status().host_pos
	await command({"cmd": "walk_host", "tiles": 3.0})
	await wait(1.6)
	var h1: Array = status().host_pos
	check(Vector2(h1[0], h1[1]).distance_to(Vector2(h0[0], h0[1])) > 2.5 and net.avatars[host_pid_].pos.distance_to(Vector2(h1[0], h1[1])) < 0.5, "smoke: the host walks and the guest sees it")
	# the guest leaves by its pause menu
	ui.show_pause()
	await frames()
	check(press("Leave the game"), "smoke: the guest's pause menu offers Leave the game (no Save)")
	await frames()
	check(not main.guest_world and not net.is_guest() and ui.panel_kind == "title", "smoke: the guest is back at the title")
	await until(func(): return bool(status().players.get(str(net.my_pid), {}).get("away", false)) if net.my_pid > 0 else false, 5.0)
	var after := status()
	check(bool(after.hosting) and bool(after.running) and int(after.coin_leak) == 0, "smoke: the host's world carries on, still open, coins conserved")
	var m0 := float(after.minutes)
	await command({"cmd": "ui_stop"})
	await until(func(): return not bool(status().get("hosting", true)), 5.0)
	check(not bool(status().hosting) and bool(status().running), "smoke: the host stops hosting from its window; its world stays open")
	await command({"cmd": "quit"})
	await until(func(): return not OS.is_process_running(host_pid), 15.0)
	check(not OS.is_process_running(host_pid) and FileAccess.file_exists(dir + "host_save.json") and m0 > 0.0, "smoke: the host saves and quits")
