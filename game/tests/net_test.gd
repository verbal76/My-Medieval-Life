extends SceneTree
## MP-01 multiplayer test with separate Godot processes on this machine (127.0.0.1): this process is a
## guest running the real game (main.gd); tests/net_host.gd runs the host in another process, and
## tests/net_guest.gd a second guest when needed. Covers hosting, discovery, refusals (version, password,
## duplicate identity, full), joining, movement both ways, invalid moves, shared actions, disconnect and
## reconnect with the same character, a host restart from its save, and traffic. Real devices (phones,
## two PCs on a real network) are not tested here. Run headless:
##   godot --headless --path game --script res://tests/net_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net/"
var port := 0
var dport := 0
var host_pid := -1
var seq := 0
const KEY := "0123456789abcdef0123456789abcdef"
const KEY2 := "fedcba9876543210fedcba9876543210"


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 47900 + OS.get_process_id() % 40 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "g2.json", "g3.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- helpers ----------------------
func spawn(script: String, args: Array) -> int:
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script, "--"] + args
	return OS.create_process(OS.get_executable_path(), a)


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


## Wait (running the game) until `cond` holds or `secs` pass. Returns whether it held.
func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func join(key: String, pw := "oak", who := "Ann") -> void:
	main.net.join("127.0.0.1", port, key, who, pw)


func me() -> Dictionary:
	return status().get("guests", {}).get(NetProtocol.key_hash(KEY), {})


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	host_pid = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir])
	seq = 0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "cmd.json"))
	return await until(func(): return status().get("hosting", false), 60.0)


# ---------------------------------------------------------------- the run ----------------------
func _run() -> void:
	check(await start_host("new"), "a host process starts a new world and hosts it (port %d)" % port)
	await discovery()
	await refusals()
	await joining_and_moving()
	await shared_actions()
	await other_guests()
	await reconnect()
	await host_restart()
	if host_pid > 0:
		OS.kill(host_pid)
	print("net_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func discovery() -> void:
	main.net.discovery.look(["127.0.0.1"], dport)
	var ok := await until(func(): return main.net.discovery.games().any(func(g): return int(g.port) == port), 8.0)
	check(ok, "the guest finds the host's game on the network (UDP discovery)")
	if ok:
		var g: Dictionary = main.net.discovery.games().filter(func(g): return int(g.port) == port)[0]
		check(str(g.name) == "Hosta" and str(g.world) == "Test Vale" and int(g.players) == 1 and int(g.max) == 2 and g.locked and str(g.version) == NetProtocol.full_version(),
			"it shows host name, world name, players 1 of 2, a password and the version: " + JSON.stringify(g))
		check(not JSON.stringify(g).contains("guest") and not g.has("key"), "discovery tells no identities")
	main.net.discovery.close()


func refusals() -> void:
	main.net.version_sent = "mml-net/0 save-1"
	join(KEY)
	await until(func(): return main.net.refusal != "", 10.0)
	check(main.net.refusal == "version" and not main.guest_world, "a different game version is refused (%s)" % main.net.refusal)
	main.net.version_sent = ""
	join(KEY, "wrong")
	await until(func(): return main.net.refusal != "", 10.0)
	check(main.net.refusal == "password" and not main.guest_world, "a wrong password is refused (%s)" % main.net.refusal)
	check(status().get("guests", {}).is_empty(), "no character was made for a refused guest")


func joining_and_moving() -> void:
	join(KEY)
	var ok := await until(func(): return main.guest_world, 20.0)
	check(ok, "the guest joins with the right password and sees the host's world")
	if not ok:
		return
	check(main.world.player.name == "Ann" and main.world.guests.is_empty(), "its own character is the player; nobody else's private state came with the world")
	await until(func(): return me().size() > 0 and main.net.avatars.has(1), 5.0)
	check(me().get("name", "") == "Ann" and status().connected.size() == 1, "the host keeps the guest's character under the identity hash")
	check(main.net.avatars.has(1) and str(main.net.avatars[1].name) != "" and str(main.net.avatars[1].name) != "Ann", "the guest sees the host's character (%s)" % str(main.net.avatars.get(1, {}).get("name", "")))
	await until(func(): return main.avatar_sprites.has(1), 3.0)
	check(main.avatar_sprites.has(1) and is_instance_valid(main.avatar_sprites[1]), "and draws it")
	# the guest walks: the host sees it
	var from: Vector2 = main.world.player.pos
	for act in ["move_right", "move_down", "move_left", "move_up"]:   # whichever way is open from where the guest stands
		var end := Time.get_ticks_msec() + 1200
		while Time.get_ticks_msec() < end:        # held down: pressed again each frame (headless runs drop held keys)
			Input.action_press(act)
			await process_frame
		Input.action_release(act)
		if main.world.player.pos.distance_to(from) > 1.0:
			break
	await wait(0.6)
	var mp: Array = me().get("pos", [0, 0])
	var on_host := Vector2(mp[0], mp[1])
	check(main.world.player.pos.distance_to(from) > 1.0, "the guest walked %.1f tiles on its screen" % main.world.player.pos.distance_to(from))
	check(on_host.distance_to(main.world.player.pos) < 0.3, "the host has the guest where the guest is (%.2f tiles apart)" % on_host.distance_to(main.world.player.pos))
	# the host walks: the guest sees it
	var h0: Array = status().host_pos
	await command({"cmd": "walk_host", "tiles": 3.0})
	await wait(1.6)
	var h1: Array = status().host_pos
	var seen: Vector2 = main.net.avatars[1].pos
	check(Vector2(h1[0], h1[1]).distance_to(Vector2(h0[0], h0[1])) > 2.5 and seen.distance_to(Vector2(h1[0], h1[1])) < 0.5, "the host walked 3 tiles and the guest sees it there (%.2f off)" % seen.distance_to(Vector2(h1[0], h1[1])))
	await until(func(): return main.avatar_sprites[1].position.distance_to(seen * main.T) < 4.0, 2.0)
	check(main.avatar_sprites[1].position.distance_to(seen * main.T) < 4.0, "the host's sprite eased to its new place")
	check((main.net.avatars[1].dir as Vector2).x > 0.5, "facing east as it walked")
	# an impossible move is sent back
	var r0 := int(status().rejected)
	var before: Vector2 = main.world.player.pos
	main.net.rpc_id(1, "c_move", before + Vector2(30, 0), Vector2.RIGHT, "walk")
	await wait(0.5)
	var mp2: Array = me().pos
	check(int(status().rejected) > r0 and Vector2(mp2[0], mp2[1]).distance_to(before) < 0.5, "a 30-tile jump is refused by the host")
	check(main.world.player.pos.distance_to(before) < 0.5, "and the guest is put back where the host has it")
	# traffic over two seconds of play
	main.net.traffic()
	await wait(2.0)
	var tr: Vector2i = main.net.traffic()
	print("     guest traffic: %.0f bytes/s up, %.0f bytes/s down; host frame %.2f ms, memory %.0f MB, %d villagers alive" % [tr.x / 2.0, tr.y / 2.0, float(status().frame_ms), float(status().memory_mb), int(status().npcs_alive)])
	check(tr.y / 2.0 < 20000.0 and tr.x / 2.0 < 5000.0, "traffic stays small (%.1f KB/s down, %.1f KB/s up)" % [tr.y / 2000.0, tr.x / 2000.0])


func shared_actions() -> void:
	if not main.guest_world:
		return
	# an apple tree, ripe, with the guest beside it (the host moves the guest: its word is final)
	var ti := -1
	for i in main.world.trees.size():
		if str(main.world.trees[i].get("species", "")) == "apple_orchard":
			ti = i
			break
	check(ti >= 0, "an apple tree to share")
	var t: Dictionary = main.world.trees[ti]
	await command({"cmd": "summer"})
	await command({"cmd": "ripen", "tree": ti})
	var spot: Vector2 = main.net.spawn_near(Vector2(int(t.x), int(t.y)) + Vector2(0.5, 0.5))
	await command({"cmd": "guest_to", "x": spot.x, "y": spot.y})
	await until(func(): return main.world.player.pos.distance_to(spot) < 0.1, 3.0)
	var a0: int = main.world.player.inv.count("apple")
	var r1: int = main.net.request("pick_fruit", {"x": int(t.x), "y": int(t.y)})
	var r2: int = main.net.request("pick_fruit", {"x": int(t.x), "y": int(t.y)})
	await until(func(): return main.net.replies.has(r1) and main.net.replies.has(r2), 5.0)
	var got := int(GameData.b("fruit_trees").apple_orchard.yield)
	check(main.net.replies.get(r1, {}).get("ok", false) and main.world.player.inv.count("apple") == a0 + got, "the first pick is granted: %d apples" % got)
	check(not main.net.replies.get(r2, {}).get("ok", true), "the same pick twice: the second finds it picked (%s)" % main.net.replies.get(r2, {}).get("text", ""))
	await wait(0.3)
	check(int(me().get("apples", -1)) == a0 + got, "the host's record of the guest's pack agrees")
	# the host reaches the ripe tree first: the guest's request finds nothing
	await command({"cmd": "ripen", "tree": ti})
	await command({"cmd": "host_pick", "tree": ti})
	var r3: int = main.net.request("pick_fruit", {"x": int(t.x), "y": int(t.y)})
	await until(func(): return main.net.replies.has(r3), 5.0)
	check(not main.net.replies[r3].ok and int(status().host_apples) >= got, "the host picked first: the guest's request is refused, no apples made twice")
	# invalid requests
	var r4: int = main.net.request("conjure_gold", {"coins": 999})
	var r5: int = main.net.request("pick_fruit", {"x": int(t.x) + 40, "y": int(t.y)})
	await until(func(): return main.net.replies.has(r4) and main.net.replies.has(r5), 5.0)
	check(not main.net.replies[r4].ok and not main.net.replies[r5].ok, "an unknown action and one out of reach are refused (%s / %s)" % [main.net.replies[r4].text, main.net.replies[r5].text])


func other_guests() -> void:
	# the same identity from another process while Ann is in: refused, no second character
	var g2 := spawn("res://tests/net_guest.gd", [str(port), KEY, "Ann again", "oak", "g2.json", dir])
	var ok := await until(func(): return FileAccess.file_exists(dir + "g2.json"), 60.0)
	var r = JSON.parse_string(FileAccess.get_file_as_string(dir + "g2.json")) if ok else {}
	check(ok and not r.welcomed and str(r.refusal) == "duplicate", "the same identity joining again from another process is refused: %s" % str(r))
	# another identity when the world (2 players) is full
	var g3 := spawn("res://tests/net_guest.gd", [str(port), KEY2, "Bert", "oak", "g3.json", dir])
	ok = await until(func(): return FileAccess.file_exists(dir + "g3.json"), 60.0)
	r = JSON.parse_string(FileAccess.get_file_as_string(dir + "g3.json")) if ok else {}
	check(ok and not r.welcomed and str(r.refusal) == "full", "a third player in a two-player world is refused: %s" % str(r))
	check(status().guests.size() == 1, "only one guest character exists")


func reconnect() -> void:
	if not main.guest_world:
		return
	await wait(0.4)
	var left_at: Vector2 = main.world.player.pos
	var apples: int = main.world.player.inv.count("apple")
	main.leave_guest_world("")
	await until(func(): return status().connected.is_empty(), 5.0)
	check(status().connected.is_empty() and me().size() > 0, "the guest leaves; the host keeps the character")
	join(KEY)
	await until(func(): return main.guest_world, 20.0)
	check(main.guest_world and main.world.player.pos.distance_to(left_at) < 0.3 and main.world.player.inv.count("apple") == apples,
		"rejoining restores the same character: where it stood (%.2f off), its %d apples" % [main.world.player.pos.distance_to(left_at), apples])
	check(status().guests.size() == 1, "and no second character was made")


func host_restart() -> void:
	if not main.guest_world:
		return
	await wait(0.4)
	var left_at: Vector2 = main.world.player.pos
	var apples: int = main.world.player.inv.count("apple")
	command({"cmd": "quit"})
	var gone := await until(func(): return not main.guest_world, 15.0)
	check(gone, "the host stops: the guest is told and leaves the world")
	await wait(1.0)
	check(await start_host("continue"), "the host continues its world from the save")
	join(KEY)
	await until(func(): return main.guest_world, 20.0)
	check(main.guest_world and main.world.player.pos.distance_to(left_at) < 0.3 and main.world.player.inv.count("apple") == apples,
		"after the host's restart the guest's character is restored from the host's save (%.2f off, %d apples)" % [main.world.player.pos.distance_to(left_at), main.world.player.inv.count("apple")])
	var save := SaveStore.inspect(dir + "host_save.json", World.SAVE_VERSION)
	check(save.state == "ok" and save.data.has("guests") and not JSON.stringify(save.data.guests).contains(KEY), "the host's save keeps the guest under its hash, never the key")
	main.leave_guest_world("")
	await command({"cmd": "quit"})
