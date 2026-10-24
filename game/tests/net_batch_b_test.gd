extends SceneTree
## Multiplayer Batch B (docs/multiplayer/BATCH_B.md; gate G1's persistence part, MULTIPLAYER_PREPARATION.md sections 6 and 10):
## two and three Godot processes on this machine over loopback (127.0.0.1), every one running the real game scene. This process
## is a guest; tests/net_host.gd the host; tests/net_guest.gd another guest. Covers: a guest's per-player records (pack, purse,
## skills, crimes, the justice case under "player:<pid>", killings, a judgment fact tagged with its reference) made on the host
## and kept; a guest disconnecting with a request in flight (applied whole or not at all); the host saving and quitting, the
## coin and goods census identical across the restart, the guest out of play until it rejoins and then the same character with
## the same records on both machines; the host killed after a save made while the guest played (the guest still comes back out of
## play, MP-D1); a guest joining while the host saves every frame; the same identity refused while in play; the guest's death:
## the world goes on, nothing is chosen for it, it may leave and come back still dead, and its own choice brings the heir by the
## established succession (MP-D4) under the same identity and line; a newcomer (MP-D7) with its band pid and starting kit.
## Real devices and real networks are not tested here. Run headless:
##   godot --headless --path game --script res://tests/net_batch_b_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_b/"
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
	port = 48000 + OS.get_process_id() % 40 * 2
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


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func join(key: String = KEY) -> bool:
	main.net.join("127.0.0.1", port, key, "Ann", "oak")
	return await until(func(): return main.guest_world, 30.0)


func leave() -> void:
	main.leave_guest_world("")
	await until(func(): return (status().get("connected", [1]) as Array).is_empty(), 5.0)


## The host's record of player `pid` (this guest's by default), {} before it exists.
func rec(pid := 0) -> Dictionary:
	return status().get("players", {}).get(str(pid if pid > 0 else main.net.my_pid), {})


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	host_pid = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir, "3"])
	seq = 0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "cmd.json"))
	return await until(func(): return status().get("hosting", false), 90.0)


func stop_host(cmd := "quit") -> void:
	command({"cmd": cmd})
	await until(func(): return not main.guest_world, 20.0)
	await until(func(): return not OS.is_process_running(host_pid), 10.0)


## What the guest's character is, for comparing two moments: the host's record of it (pack, purse, skills, crimes, case,
## killings, judgment tag) plus the guest machine's own copy (pack, purse, crimes).
func snapshot() -> Dictionary:
	var r := rec()
	return {"pid": main.net.my_pid, "inv": JSON.stringify(r.get("inv", {}), "", true), "coins": int(r.get("coins", -1)), "skills": JSON.stringify(r.get("skills", {}), "", true),
		"crimes": int(r.get("crimes", -1)), "case": int(r.get("case", -1)), "killings": int(r.get("killings", -1)), "jtag": bool(r.get("jtag", false)),
		"mine_inv": JSON.stringify(main.world.player.inv.items, "", true) if main.guest_world else "", "mine_coins": main.world.player.coins if main.guest_world else -1,
		"mine_crimes": main.world.player.crimes.size() if main.guest_world else -1}


## The host's and the guest's copies of the guest agree (pack item by item, purse, crimes).
func agree(s: Dictionary) -> bool:
	var host_inv: Dictionary = rec().get("inv", {})
	var mine: Dictionary = main.world.player.inv.items if main.guest_world else {}
	var same := host_inv.size() == mine.size()
	for k in host_inv:
		same = same and int(host_inv[k]) == int(mine.get(k, -1))
	if not (same and s.coins == s.mine_coins and s.crimes == s.mine_crimes):
		print("     host %s %d %d / guest %s %d %d" % [JSON.stringify(host_inv), s.coins, s.crimes, JSON.stringify(mine), s.mine_coins, s.mine_crimes])
	return same and s.coins == s.mine_coins and s.crimes == s.mine_crimes


func spawn_guest(key: String, who: String, out: String) -> Dictionary:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + out))
	spawn("res://tests/net_guest.gd", [str(port), key, who, "oak", out, dir])
	var ok := await until(func(): return FileAccess.file_exists(dir + out), 90.0)
	var r = JSON.parse_string(FileAccess.get_file_as_string(dir + out)) if ok else null
	return r if r is Dictionary else {}


# ---------------------------------------------------------------- the run ----------------------
func _run() -> void:
	check(await start_host("new"), "a host process starts a new world and hosts it (port %d)" % port)
	check(await join(), "the guest joins")
	if main.guest_world:
		await records()
		await mid_action()
		await restart()
		await killed_host()
		await mid_save()
		await death_and_heir()
		await newcomer()
	if host_pid > 0 and OS.is_process_running(host_pid):
		await stop_host()
	if host_pid > 0 and OS.is_process_running(host_pid):
		OS.kill(host_pid)
	print("net_batch_b_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func records() -> void:
	await until(func(): return rec().size() > 0, 5.0)
	var c0 := int(rec().coins)
	await command({"cmd": "endow"})
	await until(func(): return main.world.player.crimes.size() > 0, 5.0)
	var s := snapshot()
	check(s.coins == c0 + 5 and s.skills.contains("mining") and s.crimes == 1 and s.case == 1 and s.killings == 1,
		"the guest's own records on the host: purse %d, skills, a theft on its record, its case under %s, a killing" % [s.coins, str(rec().ref)])
	check(s.jtag or status().get("players", {}).values().all(func(p): return not p.jtag), "a judgment fact is tagged with the guest's reference (%s)" % str(s.jtag))
	check(agree(s), "and the guest's machine shows the same pack, purse and crimes")
	check(int(rec(int(status().host_pid)).get("crimes", -1)) == 0 and int(rec(int(status().host_pid)).get("killings", -1)) == 0, "none of it is the host's")
	check(int(status().coin_leak) == 0, "coins conserved (5 moved from the host, none made)")


## A request in flight when the guest goes: applied whole by the host, or not at all; nothing half done.
func mid_action() -> void:
	var w: World = main.world
	var food := ""
	for id in w.player.inv.items:
		if GameData.item(str(id)).has("food"):
			food = str(id)
	var n0 := int(rec().inv.get(food, 0))
	var a0 := int(status().applied)
	main.net.request("eat", {"id": food})
	main.leave_guest_world("")                 # gone the same frame
	await until(func(): return (status().connected as Array).is_empty(), 5.0)
	await wait(0.5)
	var n1 := int(rec_by_key().inv.get(food, 0))
	var applied := int(status().applied) - a0
	check((applied == 0 and n1 == n0) or (applied == 1 and n1 == n0 - 1), "a guest gone with a request in flight: applied whole or not at all (applied %d, %s %d -> %d)" % [applied, food, n0, n1])
	check(bool(rec_by_key().away) and int(status().coin_leak) == 0, "its character is out of play, its records kept; coins conserved")
	check(await join(), "it rejoins")
	await wait(0.3)
	check(int(main.world.player.inv.count(food)) == n1 and agree(snapshot()), "and has what the host has (%s %d)" % [food, n1])


## The host's record of the guest by its identity (after it left, my_pid still names it).
func rec_by_key() -> Dictionary:
	for p in status().get("players", {}).values():
		if str(p.key) == NetProtocol.key_hash(KEY):
			return p
	return {}


func restart() -> void:
	await wait(0.4)
	var before := snapshot()
	var left_at: Vector2 = main.world.player.pos
	await stop_host("quit")
	var saved: Dictionary = status().census
	check(not main.guest_world and str(saved.get("at", "")) == "saved", "the host saves and quits; the guest is told and leaves")
	check(await start_host("continue"), "the host continues from its save")
	var loaded: Dictionary = status().census
	check(int(loaded.coins) == int(saved.coins), "coin census identical across the restart (%d / %d)" % [int(saved.coins), int(loaded.coins)])
	check(JSON.stringify(loaded.goods, "", true) == JSON.stringify(saved.goods, "", true), "goods census identical across the restart (%d kinds)" % (loaded.goods as Dictionary).size())
	check(bool(rec(before.pid).get("away", false)) and (status().connected as Array).is_empty(), "the guest's character is in the world, out of play until it rejoins")
	check(await join(), "the guest reconnects")
	await wait(0.5)
	var after := snapshot()
	check(after.pid == before.pid and main.world.player.pos.distance_to(left_at) < 0.3, "the same character (pid %d), where it stood" % after.pid)
	check(after.inv == before.inv and after.coins == before.coins and after.skills == before.skills, "the same pack, purse and skills")
	check(after.crimes == before.crimes and after.case == before.case and after.killings == before.killings and after.jtag == before.jtag, "the same crimes, case, killings and judgment fact")
	check(agree(after) and not bool(rec().away), "both machines agree, and it is back in play")
	var dup := await spawn_guest(KEY, "Ann again", "g2.json")
	check(not dup.get("welcomed", true) and str(dup.get("refusal", "")) == "duplicate", "the same identity from another process is refused while it plays: %s" % str(dup))


## The host is killed after a save written while the guest played (its record says in play): loaded, the guest is out of play.
func killed_host() -> void:
	var pid: int = main.net.my_pid
	await stop_host("crash")
	var raw := SaveStore.inspect(dir + "host_save.json", World.SAVE_VERSION)
	var saved: Dictionary = raw.get("data", {}).get("players", {}).get("by_pid", {}).get(str(pid), {}) if raw.state == "ok" else {}
	check(not saved.is_empty() and not bool(saved.get("away", false)), "the host was killed after a save that has the guest in play")
	check(await start_host("continue"), "the host continues from that save")
	check(bool(status().census.away.get(str(pid), false)) and bool(rec(pid).away), "loaded, the guest is out of play until it rejoins (MP-D1)")
	check(await join() and main.net.my_pid == pid, "and rejoins as the same character")


## A guest joins while the host is saving every frame: saving runs on the host's main thread, so the join is handled between
## saves; the newest save has the guest, readable.
func mid_save() -> void:
	await leave()
	await command({"cmd": "save_storm", "secs": 4.0})
	var s0 := int(status().saves)
	check(await join(), "the guest joins while the host saves every frame")
	await until(func(): return not status().get("storm", true), 8.0)
	var raw := SaveStore.inspect(dir + "host_save.json", World.SAVE_VERSION)
	var saved: Dictionary = raw.get("data", {}).get("players", {}).get("by_pid", {}).get(str(main.net.my_pid), {}) if raw.state == "ok" else {}
	print("     save %s, record %s, saves %d" % [raw.state, JSON.stringify(saved).left(120), int(status().saves) - s0])
	check(int(status().saves) > s0 + 3 and raw.state == "ok" and not saved.is_empty() and not bool(saved.get("away", false)),
		"%d saves meanwhile, the last one readable with the guest in play" % (int(status().saves) - s0))
	check(agree(snapshot()), "and the guest's character is whole on both machines")


func death_and_heir() -> void:
	var pid: int = main.net.my_pid
	var ref := str(rec().ref)
	var leak0 := int(status().coin_leak)
	await command({"cmd": "kill_guest"})
	await until(func(): return not main.world.player.alive, 5.0)
	await wait(0.3)
	check(not main.world.player.alive and not bool(rec(pid).alive), "the guest's character dies on the host, and the guest sees it")
	check(main.ui.is_open("death"), "the guest is shown the death screen (its choice)")
	var m0 := float(status().minutes)
	await wait(2.0)
	check(float(status().minutes) > m0 and not bool(rec(pid).alive) and main.net.my_pid == pid, "the world goes on (MP-D4) and nothing chooses for the guest")
	await leave()
	check(await join() and main.net.my_pid == pid and not main.world.player.alive, "it can leave and come back: still dead, still its character")
	await until(func(): return main.ui.is_open("death"), 3.0)
	check(main.ui.is_open("death"), "and the choice is offered again")
	main.continue_as_heir()                    # the death screen's "Continue as the heir"
	await until(func(): return main.net.my_pid != pid, 5.0)
	await wait(0.4)
	var h := rec()
	var heir_pid: int = main.net.my_pid
	check(main.net.my_pid != pid and main.world.player.alive and bool(h.get("alive", false)) and not main.ui.is_open("death"), "the guest chose the heir: pid %d, alive on both machines" % main.net.my_pid)
	check(str(h.get("key", "")) == NetProtocol.key_hash(KEY) and int(h.get("line", 0)) == pid and str(h.get("ref", "")) == ref, "the heir has the identity and the line's reference (%s)" % str(h.get("ref", "")))
	check(rec(pid).is_empty() and status().players.size() == 2, "the dead character is an ancestor now, not a player; still two players")
	check(int(h.get("case", -1)) == 0 and int(h.get("killings", -1)) == 1 and h.skills.is_empty(), "the case ended with the dead; the line's killings stay; skills start anew")
	check(int(status().coin_leak) - leak0 == int(h.coins), "coins: only the heir's starting purse came in (%d)" % int(h.coins))
	await leave()
	check(await join() and main.net.my_pid == heir_pid, "the same identity now finds the heir (pid %d)" % heir_pid)


func newcomer() -> void:
	var n0 := int(status().newcomers)
	var leak0 := int(status().coin_leak)
	var r := await spawn_guest(KEY2, "Bert", "g3.json")
	check(r.get("welcomed", false), "a second guest, a new identity, joins a three-player world")
	await until(func(): return (status().connected as Array).size() == 1, 5.0)
	var bert := {}
	for p in status().players.values():
		if str(p.name) == "Bert":
			bert = p
	check(not bert.is_empty() and int(bert.coins) == int(GameData.b("start_coins_player")) and int(bert.crimes) == 0 and int(bert.case) == 0 and str(bert.key) == NetProtocol.key_hash(KEY2),
		"it arrives a newcomer (MP-D7): the starting kit, a clean record, its own identity")
	check(int(status().newcomers) == n0 + 1 and int(status().coin_leak) == leak0, "counted as a newcomer; its purse counted in, coins conserved")
	check(bool(bert.get("away", false)) and status().players.size() == 3, "it left again: out of play, kept; three players in the world")
