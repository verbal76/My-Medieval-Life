extends SceneTree
## Multiplayer gate G1 (docs/multiplayer/MULTIPLAYER_PREPARATION.md section 10, Batch A2): two Godot processes on this
## machine over loopback (127.0.0.1). This process is a guest running the real game (main.gd); tests/net_host.gd runs the
## host's real game in another process; tests/net_guest.gd a second guest when needed. Covers: hosting and LAN discovery;
## refusals (version, password, duplicate identity, full); joining, the guest a full player in the host's World.players by a
## permanent pid with the ref "player:<pid>"; both seeing the same world (seed, clock, positions both ways); an impossible
## move refused; the guest's actions applied by the host as that guest (eat from the pack, pick a wild plant through the
## tap path), the host's and the guest's records of the guest agreeing after each, a plant taken first by the host refused;
## coins conserved (the newcomer's purse counted in); leaving (out of play, MP-D1) and rejoining as the same character; a
## host restart from its save. Real devices and real networks are not tested here. Run headless:
##   godot --headless --path game --script res://tests/net_g1_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_g1/"
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


## The host's record of this guest (by its pid), {} before it exists.
func me() -> Dictionary:
	return status().get("players", {}).get(str(main.net.my_pid), {})


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	host_pid = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir])
	seq = 0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "cmd.json"))
	return await until(func(): return status().get("hosting", false), 90.0)


## The guest's own pack as the host has it and as the guest shows it: the same, item for item.
func packs_agree() -> bool:
	var host_inv: Dictionary = me().get("inv", {})
	var mine: Dictionary = main.world.player.inv.items
	if host_inv.size() != mine.size():
		return false
	for k in host_inv:
		if int(host_inv[k]) != int(mine.get(k, -1)):
			return false
	return true


# ---------------------------------------------------------------- the run ----------------------
func _run() -> void:
	check(await start_host("new"), "a host process starts a new world and hosts it (port %d)" % port)
	await discovery()
	await refusals()
	await joining_and_moving()
	await actions()
	await other_guests()
	await reconnect()
	await host_restart()
	if host_pid > 0 and OS.is_process_running(host_pid):
		OS.kill(host_pid)
	print("net_g1_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func discovery() -> void:
	main.net.discovery.look(["127.0.0.1"], dport)
	var ok := await until(func(): return main.net.discovery.games().any(func(g): return int(g.port) == port), 8.0)
	check(ok, "the guest finds the host's game on the network (UDP discovery)")
	if ok:
		var g: Dictionary = main.net.discovery.games().filter(func(g): return int(g.port) == port)[0]
		check(str(g.name) == "Hosta" and str(g.world) == "Test Vale" and int(g.players) == 1 and int(g.max) == 2 and g.locked and str(g.version) == NetProtocol.full_version(),
			"it shows host name, world name, players 1 of 2, a password and the version: " + JSON.stringify(g))
		check(not g.has("key") and not g.has("players_list"), "discovery tells no identities")
	main.net.discovery.close()


func refusals() -> void:
	main.net.version_sent = "mml-net/1 save-20"
	join(KEY)
	await until(func(): return main.net.refusal != "", 10.0)
	check(main.net.refusal == "version" and not main.guest_world, "a different game version is refused (%s)" % main.net.refusal)
	main.net.version_sent = ""
	join(KEY, "wrong")
	await until(func(): return main.net.refusal != "", 10.0)
	check(main.net.refusal == "password" and not main.guest_world, "a wrong password is refused (%s)" % main.net.refusal)
	check(status().get("players", {}).size() == 1, "no character was made for a refused guest")


func joining_and_moving() -> void:
	join(KEY)
	var ok := await until(func(): return main.guest_world, 30.0)
	check(ok, "the guest joins with the right password and sees the host's world")
	if not ok:
		return
	var w: World = main.world
	var st := status()
	await until(func(): return me().size() > 0, 5.0)
	st = status()
	var pid: int = main.net.my_pid
	check(pid >= World.BAND_START and me().get("name", "") == "Ann" and not bool(me().host) and str(me().ref) == "player:%d" % pid and (st.connected as Array).map(func(x): return int(x)) == [pid],
		"the host has the guest as a player of its World.players by a permanent pid %d, ref %s" % [pid, str(me().get("ref", ""))])
	check(str(me().get("key", "")) == NetProtocol.key_hash(KEY) and str(me().get("key", "")) != KEY, "the host keeps the guest's identity hash, never the key")
	check(w.player.pid == pid and w.player.name == "Ann" and w.player_by_pid(int(st.host_pid)) != null and w.player_ref(w.player) == "player:%d" % pid,
		"on the guest, its own character is the player (pid %d), the host's character is in its World.players" % pid)
	var host_copy: PlayerState = w.player_by_pid(int(st.host_pid))
	check(host_copy.inv.items.is_empty() and host_copy.coins == 0 and host_copy.crimes.is_empty(), "the guest got the host's public record only (no pack, purse or crimes)")
	check(w.seed == int(st.seed) and absf(w.minutes - float(st.minutes)) < 30.0, "the same world: seed %d, the clock %.0f / %.0f" % [w.seed, w.minutes, float(st.minutes)])
	check(packs_agree() and w.player.coins == int(me().coins), "the guest's pack and purse are the host's record of them (%d coins)" % w.player.coins)
	await until(func(): return main.net.avatars.has(int(st.host_pid)), 5.0)
	check(main.net.avatars.has(int(st.host_pid)) and str(main.net.avatars[int(st.host_pid)].name) != "Ann", "the guest sees the host's character")
	await until(func(): return main.avatar_sprites.has(int(st.host_pid)), 3.0)
	check(main.avatar_sprites.has(int(st.host_pid)) and is_instance_valid(main.avatar_sprites[int(st.host_pid)]), "and draws it")
	# the guest walks: the host sees it
	var from: Vector2 = w.player.pos
	for act in ["move_right", "move_down", "move_left", "move_up"]:   # whichever way is open from where the guest stands
		var end := Time.get_ticks_msec() + 1200
		while Time.get_ticks_msec() < end:        # held down: pressed again each frame (headless runs drop held keys)
			Input.action_press(act)
			await process_frame
		Input.action_release(act)
		if w.player.pos.distance_to(from) > 1.0:
			break
	await wait(0.6)
	# MP C: under load the host's status can lag the guest's last steps a moment (it also sends world sections now): wait for it
	await until(func(): var q: Array = me().get("pos", [0, 0]); return Vector2(q[0], q[1]).distance_to(w.player.pos) < 0.3, 3.0)
	var mp: Array = me().get("pos", [0, 0])
	var on_host := Vector2(mp[0], mp[1])
	check(w.player.pos.distance_to(from) > 1.0, "the guest walked %.1f tiles on its screen" % w.player.pos.distance_to(from))
	check(on_host.distance_to(w.player.pos) < 0.3, "the host has the guest where the guest is (%.2f tiles apart)" % on_host.distance_to(w.player.pos))
	# the host walks: the guest sees it
	var h0: Array = status().host_pos
	await command({"cmd": "walk_host", "tiles": 3.0})
	await wait(1.6)
	var h1: Array = status().host_pos
	var seen: Vector2 = main.net.avatars[int(st.host_pid)].pos
	check(Vector2(h1[0], h1[1]).distance_to(Vector2(h0[0], h0[1])) > 2.5 and seen.distance_to(Vector2(h1[0], h1[1])) < 0.5, "the host walked 3 tiles and the guest sees it there (%.2f off)" % seen.distance_to(Vector2(h1[0], h1[1])))
	check(host_copy.pos.distance_to(seen) < 0.01, "the guest's copy of the host's character follows it")
	# an impossible move is sent back
	var r0 := int(status().rejected)
	var before: Vector2 = w.player.pos
	main.net.rpc_id(1, "c_move", before + Vector2(30, 0), Vector2.RIGHT, "walk")
	await wait(0.5)
	var mp2: Array = me().pos
	check(int(status().rejected) > r0 and Vector2(mp2[0], mp2[1]).distance_to(before) < 0.5, "a 30-tile jump is refused by the host")
	check(w.player.pos.distance_to(before) < 0.5, "and the guest is put back where the host has it")
	# traffic over two seconds of play
	main.net.traffic()
	await wait(2.0)
	var tr: Vector2i = main.net.traffic()
	print("     guest traffic: %.0f bytes/s up, %.0f bytes/s down" % [tr.x / 2.0, tr.y / 2.0])
	check(tr.y / 2.0 < 20000.0 and tr.x / 2.0 < 5000.0, "traffic stays small (%.1f KB/s down, %.1f KB/s up)" % [tr.y / 2000.0, tr.x / 2000.0])


func actions() -> void:
	if not main.guest_world:
		return
	var w: World = main.world
	# eat: the host eats for the guest, as the guest (World.player_eat under as_actor); both records agree
	var food := ""
	for id in w.player.inv.items:
		if GameData.item(str(id)).has("food"):
			food = str(id)
			break
	check(food != "", "the newcomer's kit has food (%s)" % food)
	var n0 := w.player.inv.count(food)
	var applied0 := int(status().applied)
	var r1: int = main.net.request("eat", {"id": food})
	await until(func(): return main.net.replies.has(r1), 5.0)
	await wait(0.3)
	check(main.net.replies.get(r1, {}).get("ok", false) and w.player.inv.count(food) == n0 - 1 and int(status().applied) == applied0 + 1,
		"the guest eats a %s: the host applied it once (%s)" % [food, main.net.replies.get(r1, {}).get("text", "")])
	# GP-MESSAGE-JOURNAL: a message the guest keeps goes to the host's journal under the guest, never as another action
	var applied1 := int(status().applied)
	var kept0 := int(status().get("journal_kept", 0))
	main.ui.message("You sell 1 apple for 3 coins (journal test).", 4.0, "trade")
	await until(func(): return int(status().get("journal_kept", 0)) > kept0, 5.0)
	var j: Dictionary = status().get("journal", {})
	var mine: Dictionary = j.get(main.world.player_ref(main.world.player), {})
	check(str(mine.get("last", "")) == "You sell 1 apple for 3 coins (journal test)." and not str(j.get("player", {}).get("last", "")).contains("journal test")
		and int(status().applied) == applied1, "a kept message reaches the host's journal under the guest, and the host applies no action for it (%s)" % [j])
	check(packs_agree() and absf(w.player.hunger - float(me().hunger)) < 1.0, "the host's and the guest's records of the guest agree (pack, hunger %.1f / %.1f)" % [w.player.hunger, float(me().hunger)])
	# pick a wild plant, through the guest's own tap path (Main.select_resource), beside it
	var pl := {}
	for p in w.plants:
		if str(p.state) == "ripe" and str(status().plants.get("%d,%d" % [int(p.x), int(p.y)], "")) == "ripe":
			pl = p
			break
	check(not pl.is_empty(), "a ripe wild plant to share")
	var cell := Vector2i(int(pl.x), int(pl.y))
	var spot: Vector2 = main.net.spawn_near(Vector2(cell) + Vector2(0.5, 0.5))
	await command({"cmd": "guest_to", "x": spot.x, "y": spot.y})
	await until(func(): return w.player.pos.distance_to(spot) < 0.1, 3.0)
	var inv0: Dictionary = w.player.inv.items.duplicate()
	var hit := ResourceNodes.node_at(w, cell, true)
	main.select_resource(hit, false)
	await until(func(): return w.player.inv.items != inv0, 5.0)
	await wait(0.4)
	check(w.player.inv.items != inv0 and packs_agree(), "the guest picks the plant: the host picked it as the guest and both packs agree")
	check(str(pl.state) == "picked" and str(status().plants.get("%d,%d" % [cell.x, cell.y], "")) == "picked", "both see the plant picked (guest %s, host %s)" % [pl.state, status().plants.get("%d,%d" % [cell.x, cell.y], "")])
	# the host takes it first: the guest's request finds it gone, nothing made twice
	await command({"cmd": "ripen", "x": cell.x, "y": cell.y})
	await command({"cmd": "host_pick", "x": cell.x, "y": cell.y})
	var inv1: Dictionary = w.player.inv.items.duplicate()
	var r3: int = main.net.request("pick_plant", {"x": cell.x, "y": cell.y})
	await until(func(): return main.net.replies.has(r3), 5.0)
	check(not main.net.replies[r3].ok and w.player.inv.items == inv1 and packs_agree(), "the host picked first: the guest's request is refused (%s), nothing made twice" % main.net.replies[r3].text)
	# invalid requests
	var r4: int = main.net.request("conjure_gold", {"coins": 999})
	var r5: int = main.net.request("pick_plant", {"x": cell.x + 40, "y": cell.y})
	var r6: int = main.net.request("eat", {"id": "iron_ore"})
	await until(func(): return main.net.replies.has(r4) and main.net.replies.has(r5) and main.net.replies.has(r6), 5.0)
	check(not main.net.replies[r4].ok and not main.net.replies[r5].ok and not main.net.replies[r6].ok and packs_agree(),
		"an unknown action, a plant out of reach and eating ore are refused (%s / %s / %s)" % [main.net.replies[r4].text, main.net.replies[r5].text, main.net.replies[r6].text])
	# an action the host does not take from guests yet changes nothing on the guest's copy
	var c0 := w.player.coins
	main.attack_button()
	main.interact()
	check(w.player.coins == c0 and packs_agree(), "actions not yet shared (Attack, Use) do nothing on the guest's copy")
	await wait(1.3)
	check(absf(w.player.hunger - float(me().hunger)) < 0.5 and w.player.coins == int(me().coins) and packs_agree(), "the host's needs for the guest reach it each second (hunger %.2f / %.2f)" % [w.player.hunger, float(me().hunger)])
	check(int(status().coin_leak) == 0, "coins are conserved on the host (the newcomer's purse counted in; leak %d)" % int(status().coin_leak))


func other_guests() -> void:
	# the same identity from another process while Ann is in: refused, no second character
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "g2.json"))
	spawn("res://tests/net_guest.gd", [str(port), KEY, "Ann again", "oak", "g2.json", dir])
	var ok := await until(func(): return FileAccess.file_exists(dir + "g2.json"), 90.0)
	var r = JSON.parse_string(FileAccess.get_file_as_string(dir + "g2.json")) if ok else {}
	check(ok and not r.welcomed and str(r.refusal) == "duplicate", "the same identity joining again from another process is refused: %s" % str(r))
	# another identity when the world (2 players) is full
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "g3.json"))
	spawn("res://tests/net_guest.gd", [str(port), KEY2, "Bert", "oak", "g3.json", dir])
	ok = await until(func(): return FileAccess.file_exists(dir + "g3.json"), 90.0)
	r = JSON.parse_string(FileAccess.get_file_as_string(dir + "g3.json")) if ok else {}
	check(ok and not r.welcomed and str(r.refusal) == "full", "a third player in a two-player world is refused: %s" % str(r))
	check(status().players.size() == 2, "only one guest character exists")


func reconnect() -> void:
	if not main.guest_world:
		return
	await wait(0.4)
	var pid: int = main.net.my_pid
	var left_at: Vector2 = main.world.player.pos
	var inv: Dictionary = main.world.player.inv.items.duplicate()
	main.leave_guest_world("")
	await until(func(): return status().connected.is_empty(), 5.0)
	var rec: Dictionary = status().players.get(str(pid), {})
	check(status().connected.is_empty() and bool(rec.get("away", false)), "the guest leaves: its character is out of play on the host, kept with its records (MP-D1)")
	join(KEY)
	await until(func(): return main.guest_world, 30.0)
	check(main.guest_world and main.net.my_pid == pid and main.world.player.pos.distance_to(left_at) < 0.3 and main.world.player.inv.items == inv,
		"rejoining restores the same character: pid %d, where it stood (%.2f off), its pack" % [main.net.my_pid, main.world.player.pos.distance_to(left_at)])
	await wait(0.3)
	check(status().players.size() == 2 and not bool(status().players[str(pid)].away), "no second character was made, and it is back in play")


func host_restart() -> void:
	if not main.guest_world:
		return
	await wait(0.4)
	var pid: int = main.net.my_pid
	var left_at: Vector2 = main.world.player.pos
	var inv: Dictionary = main.world.player.inv.items.duplicate()
	command({"cmd": "quit"})
	var gone := await until(func(): return not main.guest_world, 20.0)
	check(gone, "the host stops: the guest is told and leaves the world")
	await wait(1.0)
	var save := SaveStore.inspect(dir + "host_save.json", World.SAVE_VERSION)
	var saved: Dictionary = save.get("data", {}).get("players", {}).get("by_pid", {}).get(str(pid), {}) if save.state == "ok" else {}
	check(not saved.is_empty() and str(saved.get("net_key", "")) == NetProtocol.key_hash(KEY) and not JSON.stringify(save.data).contains(KEY) and bool(saved.get("away", false)),
		"the host's save (21) keeps the guest's character by pid, out of play, under its identity hash, never the key")
	check(await start_host("continue"), "the host continues its world from the save")
	join(KEY)
	await until(func(): return main.guest_world, 30.0)
	check(main.guest_world and main.net.my_pid == pid and main.world.player.pos.distance_to(left_at) < 0.3 and main.world.player.inv.items == inv,
		"after the host's restart the guest's character is restored from the host's save (pid %d, %.2f off)" % [main.net.my_pid, main.world.player.pos.distance_to(left_at)])
	main.leave_guest_world("")
	await command({"cmd": "quit"})
	await until(func(): return not OS.is_process_running(host_pid), 10.0)
