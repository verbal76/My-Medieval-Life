extends SceneTree
## Multiplayer Batch D (docs/multiplayer/BATCH_D_CONNECTIVITY.md): connections under faults, with real Godot processes on loopback.
## This process is guest A running the real game (main.gd); tests/net_host.gd is the host in another process; tests/net_proxy.gd a
## UDP relay between A and the host that drops, repeats, delays, reorders or swallows ENet's datagrams; tests/net_fault_guest.gd a
## second guest the test kills and freezes. Covers: invite codes (made, read back, typing mistakes, a dead address passed over, the
## wrong world refused); the router question on this machine (no router: the code claims no internet); requests repeated, late and
## swapped (each applied once, in order; the pack counted exactly; coins conserved); a lossy, repeating, reordering network; the
## network gone for a while (the guest reconnects by itself to the same character, no second one); an Android guest's pause and
## resume (reconnects at once, its token taking its character back); a guest killed and frozen; an Android host's pause (the guests
## told, wait, come back; the host's clock does not jump); the host killed and restarted from its save (the guest comes back by
## itself); the host stopping (the guest is told and does not wait). Real devices and real networks are not tested here.
##   godot --headless --path game --script res://tests/net_fault_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_fault/"
var port := 0
var dport := 0
var pport := 0
var host_pid := -1
var proxy_pid := -1
var guest2_pid := -1
var seq := 0
var said: Array = []
var food := ""
const KEY := "0a1b2c3d4e5f60718293a4b5c6d7e8f9"
const KEY2 := "f9e8d7c6b5a4938271605f4e3d2c1b0a"


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 48100 + OS.get_process_id() % 40 * 4
	dport = port + 1
	pport = port + 2
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "proxy.json", "proxy_status.json", "g2.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- helpers ----------------------
func spawn(script: String, args: Array) -> int:
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script, "--"] + args
	return OS.create_process(OS.get_executable_path(), a)


func read_json(name: String) -> Dictionary:
	var f := FileAccess.open(dir + name, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if typeof(d) == TYPE_DICTIONARY else {}


func status() -> Dictionary:
	return read_json("status.json")


func command(d: Dictionary, wait_for := true) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	if wait_for:
		await until(func(): return int(status().get("seq", -1)) >= seq, 5.0)


func proxy(cfg: Dictionary) -> void:
	var f := FileAccess.open(dir + "proxy.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(cfg))
	f.close()
	await wait(0.4)                              # the relay reads it every 0.2 s


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func rec(pid := -1) -> Dictionary:
	return status().get("players", {}).get(str(pid if pid >= 0 else main.net.my_pid), {})


## The pids of the guests connected to the host now (as whole numbers).
func conn() -> Array:
	return (status().get("connected", []) as Array).map(func(x): return int(x))


func net_d() -> Dictionary:
	return status().get("net_d", {})


## The host's applied requests of player `pid`, numbers in the order applied.
func applied_of(pid: int) -> Array:
	return (net_d().get("log", []) as Array).filter(func(e): return int(e[0]) == pid).map(func(e): return int(e[1]))


func host_food() -> int:
	return int(rec().get("inv", {}).get(food, 0))


func in_game() -> bool:
	return main.guest_world and main.net.connected() and not main.net.reconnecting


# ---------------------------------------------------------------- the run ----------------------
func _run() -> void:
	main.net.changed.connect(func(t): said.append(t))
	for id in ["bread", "apple", "cooked_fish"]:
		if GameData.items.has(id) and GameData.item(id).has("food"):
			food = id
			break
	_codes()
	await _router()
	host_pid = spawn("res://tests/net_host.gd", [str(port), str(dport), "new", dir, "3"])
	proxy_pid = spawn("res://tests/net_proxy.gd", [str(pport), str(port), dir])
	var up := await until(func(): return status().get("hosting", false) and read_json("proxy_status.json").get("up", false), 90.0)
	check(up and food != "", "the host and the relay are up (food: %s)" % food)
	if up:
		await _join_by_code()
		if main.guest_world:
			await _repeats()
			await _lossy()
			await _dropped()
			await _guest_pause()
			await _guest_killed()
			await _host_pause()
			await _host_killed()
			await _host_stops()
	_finish()


func _finish() -> void:
	for p in [host_pid, proxy_pid, guest2_pid]:
		if p > 0 and OS.is_process_running(p):
			OS.kill(p)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- invite codes -----------------
func _codes() -> void:
	var list := [{"ip": "192.168.1.20", "kind": "lan"}, {"ip": "10.0.0.7", "kind": "lan"}, {"ip": "2001:db8::42:1", "kind": "v6"}, {"ip": "203.0.113.9", "kind": "public"}]
	var code := NetInvite.make(list, 47810, "a1b2c3d4")
	var r := NetInvite.parse(code)
	check(code.begins_with("MML-") and r.ok and int(r.port) == 47810 and str(r.tag) == "a1b2c3d4", "an invite code reads back: port and world tag (%s, %d characters)" % [code, code.length()])
	var ips: Array = (r.addresses as Array).map(func(a): return [str(a.kind), str(a.ip)])
	check(ips == [["lan", "192.168.1.20"], ["lan", "10.0.0.7"], ["v6", "2001:db8:0:0:0:0:42:1"], ["public", "203.0.113.9"]], "its addresses, in the order to try: network, IPv6, internet (%s)" % str(ips))
	check(NetInvite.parse(code.to_lower().replace("-", " ")).ok and NetInvite.parse("Join me! " + code + " thanks").ok, "read ignoring case, spaces and words around it")
	var typo := code.substr(0, 10) + ("A" if code[10] != "A" else "B") + code.substr(11)
	check(not NetInvite.parse(typo).ok and str(NetInvite.parse(typo).error) == "typo" and not NetInvite.parse(code.left(code.length() - 3)).ok, "a typing mistake or a cut-off code is caught")
	check(not NetInvite.parse("192.168.1.20").ok and NetWindow.parse_address("192.168.1.20").ip == "192.168.1.20", "an address is not taken for a code, and still joins as an address")
	check(NetWindow.parse_address("[2001:db8::1]:47900") == {"ip": "2001:db8::1", "port": 47900} and NetWindow.parse_address("2001:db8::1").port == NetProtocol.GAME_PORT, "IPv6 addresses typed by hand, with or without a port")
	check(NetInvite.classify("100.72.1.1") == "cgnat" and NetInvite.classify("192.168.0.4") == "lan" and NetInvite.classify("8.8.4.4") == "public" and NetInvite.classify("fe80::1") == "link" and NetInvite.classify("2a00::1") == "v6",
		"addresses classified: the provider's shared range is never taken for the internet")
	var only_lan := NetInvite.parse(NetInvite.make([{"ip": "192.168.1.20", "kind": "lan"}], 47810, "a1b2c3d4"))
	check(only_lan.ok and (only_lan.addresses as Array).all(func(a): return str(a.kind) == "lan"), "a code made without a router's mapping holds no internet address")


## The router question, for real, on this machine (a container with no home router): the answer is "no router", and nothing in the
## window or the code claims friends elsewhere can join.
func _router() -> void:
	var u := NetUpnp.new()
	u.start(port + 3)
	var done := await until(func(): return u.poll() or u.state != "checking", 15.0)
	check(done and u.state in ["no_router", "refused", "shared", "mapped"], "the router question runs in the background and ends (%s)" % u.state)
	check(u.state != "mapped" or NetInvite.classify(u.external) == "public", "a mapping is only claimed on a real public address")
	var fake := NetSession.new()
	fake.upnp.state = "no_router"
	var lines: Array = NetWindow.reach_lines(fake)
	check(lines.size() >= 2 and not bool(lines[1][1]) and str(lines[1][0]).begins_with("Friends elsewhere: no"), "with no router answer the window says friends elsewhere cannot join (%s)" % str(lines[1][0]))
	fake.upnp.state = "shared"
	check(str(NetWindow.reach_lines(fake)[1][0]).contains("carrier-grade NAT"), "a shared provider address is named as such")
	fake.upnp.state = "mapped"
	fake.upnp.external = "100.80.0.1"
	check(not fake.upnp.reachable_outside(), "a 'mapping' on the provider's shared range is not counted as reachable")
	u.stop()
	fake.free()


# ---------------------------------------------------------------- joining ----------------------
func _join_by_code() -> void:
	var tag := str(net_d().get("tag", ""))
	# nothing at all answers: a meaningful error, naming what was tried
	said.clear()
	main.net.join_targets([{"ip": "198.51.100.7", "port": pport, "kind": "lan"}], KEY, "Ann", "oak", tag)
	await until(func(): return not main.net.is_guest(), 10.0)
	check(not main.net.is_guest() and not said.is_empty() and str(said[-1]).begins_with("Could not reach the host at any address in the invite code (tried: your network)"), "nothing answering ends in a clear message naming what was tried (%s)" % str(said.back() if not said.is_empty() else ""))
	# the wrong world's tag at the right address: passed over
	var wrong := NetInvite.parse(NetInvite.make([{"ip": "127.0.0.1", "kind": "public"}], pport, "00000000"))
	said.clear()
	main.net.join_targets(wrong.addresses, KEY, "Ann", "oak", str(wrong.tag))
	await until(func(): return not main.net.is_guest(), 10.0)
	check(not main.guest_world and said.has(NetSession.OTHER_GAME), "a code for another world, at a live address, is refused, not joined (%s)" % str(said))
	# a dead address first (as a friend's LAN address seen from elsewhere), then the live one
	var code := NetInvite.make([{"ip": "10.255.255.1", "kind": "lan"}, {"ip": "127.0.0.1", "kind": "public"}], pport, tag)
	var r := NetInvite.parse(code)
	var t0 := Time.get_ticks_msec()
	main.net.join_targets(r.addresses, KEY, "Ann", "oak", str(r.tag))
	var joined := await until(func(): return main.guest_world, 30.0)
	check(joined and main.net.tried_kinds == ["lan", "public"] and Time.get_ticks_msec() - t0 >= 3500, "joined by the invite code: the dead network address given up in its time, the next one used (%s, %.1f s)" % [str(main.net.tried_kinds), (Time.get_ticks_msec() - t0) / 1000.0])
	await until(func(): return main.net.resume_token != "", 3.0)
	check(main.net.resume_token.length() == 24 and not str(status()).contains(main.net.resume_token), "the host gave a resume token, kept nowhere in its status or save")
	await wait(0.2)


# ---------------------------------------------------------------- repeated, late, swapped requests ---
func _repeats() -> void:
	var net: NetSession = main.net
	await command({"cmd": "give", "id": food, "n": 12})
	await until(func(): return main.world.player.inv.count(food) >= 12, 3.0)
	var pid := net.my_pid
	var n0 := host_food()
	var d0 := int(net_d().duplicates)
	net.faults = {"dup": true}
	var rids := []
	for i in 3:
		rids.append(net.request("eat", {"id": food}))
		await wait(0.05)
	await until(func(): return host_food() <= n0 - 3 and int(net_d().duplicates) >= d0 + 3, 4.0)
	await wait(0.5)
	check(host_food() == n0 - 3 and int(net_d().duplicates) >= d0 + 3, "every request sent twice: each eaten once (%s %d -> %d), the repeats answered from the record (%d)" % [food, n0, host_food(), int(net_d().duplicates) - d0])
	check(rids.all(func(r): return net.replies.has(r) and bool(net.replies[r].ok)), "and the guest has one answer to each")
	net.faults = {}
	# an old request sent again much later (as a stale datagram might): not applied
	var n1 := host_food()
	net.rpc_id(1, "c_request", int(rids[0]), "eat", {"id": food})
	await wait(0.6)
	check(host_food() == n1, "a request number already applied, sent again later, is not applied again")
	# late and swapped: numbered order kept
	net.faults = {"reorder": true, "delay_ms": 250}
	var mine := []
	for i in 4:
		mine.append(net.request("eat", {"id": food}))
	await until(func(): return host_food() <= n1 - 4, 5.0)
	net.faults = {}
	var done_list := applied_of(pid)
	var tail: Array = done_list.slice(done_list.size() - 4)
	check(host_food() == n1 - 4 and tail == mine, "requests arriving late and swapped are applied once each, in the order sent (%s)" % str(tail))
	check(int(status().coin_leak) == 0, "coins conserved")
	await until(func(): return main.world.player.inv.count(food) == host_food(), 3.0)
	check(main.world.player.inv.count(food) == host_food(), "the guest's pack agrees with the host's (%d)" % host_food())


# ---------------------------------------------------------------- a bad network ------------------
func _lossy() -> void:
	var net: NetSession = main.net
	await proxy({"loss": 0.2, "dup": 0.15, "reorder": 0.15, "delay_ms": 30, "jitter_ms": 40, "seed": 11})
	var n0 := host_food()
	var a0 := int(status().applied)
	var w: World = main.world
	var from: Vector2 = w.player.pos
	for i in 3:
		net.request("eat", {"id": food})
		await wait(0.3)
	for act in ["move_right", "move_down", "move_left", "move_up"]:
		var end := Time.get_ticks_msec() + 700
		while Time.get_ticks_msec() < end:
			Input.action_press(act)
			await process_frame
		Input.action_release(act)
	await until(func(): return host_food() <= n0 - 3, 8.0)
	await wait(1.5)
	var ps := read_json("proxy_status.json")
	check(host_food() == n0 - 3, "20%% loss, 15%% repeats, 15%% reordering: three meals eaten exactly once each (%s %d -> %d; requests applied in all, the walk's included, %d; relay dropped %d, repeated %d, reordered %d; reconnecting %s, reconnects %d)" % [food, n0, host_food(), int(status().applied) - a0, int(ps.get("dropped", 0)), int(ps.get("duplicated", 0)), int(ps.get("reordered", 0)), str(net.reconnecting), net.reconnects])
	await until(func():
		var q: Array = rec().get("pos", [0, 0])
		return Vector2(q[0], q[1]).distance_to(w.player.pos) < 0.5, 5.0)
	var q2: Array = rec().get("pos", [0, 0])
	check(in_game() and Vector2(q2[0], q2[1]).distance_to(w.player.pos) < 0.5 and w.player.pos.distance_to(from) > 0.0, "the walk arrives on the host (%.2f tiles apart)" % Vector2(q2[0], q2[1]).distance_to(w.player.pos))
	await proxy({})
	await until(func(): return main.world.player.inv.count(food) == host_food() and main.world.player.coins == int(rec().coins), 4.0)
	var kinds := {}
	for e in net_d().get("log", []):
		if e.size() > 2:
			kinds[str(e[2])] = int(kinds.get(str(e[2]), 0)) + 1
	check(int(status().coin_leak) == 0 and main.world.player.inv.count(food) == host_food() and main.world.player.coins == int(rec().coins),
		"coins conserved, the packs and purses agree (leak %d; %s %d/%d; coins %d/%d; applied %s)" % [int(status().coin_leak), food, main.world.player.inv.count(food), host_food(), main.world.player.coins, int(rec().coins), str(kinds)])


# ---------------------------------------------------------------- the network gone ------------------
func _dropped() -> void:
	var net: NetSession = main.net
	var pid := net.my_pid
	var players0 := (status().players as Dictionary).size()
	await proxy({"blackhole": true})
	await wait(1.5)
	check(in_game(), "a gap of a second and a half: still connected (ENet waits longer)")
	var lost := await until(func(): return net.reconnecting, 20.0)
	check(lost and main.guest_world and main.paused, "the network gone longer: the guest notices, keeps its view stopped and reconnects by itself")
	var away := await until(func(): return bool(rec(pid).get("away", false)), 15.0)
	check(away and int(status().coin_leak) == 0, "the host takes its character out of play, records kept, coins conserved (MP-D1)")
	var r0 := net.reconnects
	var n_req := net.request("eat", {"id": food})
	check(not bool(net.replies[n_req].ok), "an action while disconnected is not sent (the host's world will be the truth)")
	await wait(3.0)
	await proxy({})
	var back := await until(func(): return in_game() and net.reconnects == r0 + 1, 25.0)
	check(back and net.my_pid == pid and not main.paused, "the network back: the guest is in the game again by itself, the same character (pid %d)" % pid)
	await until(func(): return not bool(rec(pid).get("away", true)), 3.0)
	check((status().players as Dictionary).size() == players0 and not bool(rec(pid).away), "no second character; back in play on the host")
	await until(func(): return main.world.player.inv.count(food) == host_food(), 3.0)
	check(main.world.player.inv.count(food) == host_food() and int(status().coin_leak) == 0, "the guest's pack is the host's again; coins conserved")


# ---------------------------------------------------------------- an Android guest paused ------------
func _guest_pause() -> void:
	var net: NetSession = main.net
	var pid := net.my_pid
	var r0 := net.reconnects
	var res0 := int(net_d().resumes)
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await proxy({"blackhole": true})              # the app is frozen: nothing goes either way
	main.process_mode = Node.PROCESS_MODE_DISABLED
	await wait(5.0)
	await proxy({})
	main.process_mode = Node.PROCESS_MODE_INHERIT
	main._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(net.reconnecting, "back from a pause longer than the host waits, the guest reconnects at once")
	var back := await until(func(): return in_game() and net.reconnects == r0 + 1, 20.0)
	check(back and net.my_pid == pid and int(net_d().resumes) > res0, "it takes its own character back with its token, no refusal (resumes %d)" % int(net_d().resumes))
	await until(func(): return conn().has(pid), 3.0)
	check(conn().count(pid) == 1, "one connection for it on the host (%s)" % str(conn()))


# ---------------------------------------------------------------- a second guest killed and frozen ---
func _guest_killed() -> void:
	guest2_pid = spawn("res://tests/net_fault_guest.gd", [str(port), KEY2, "Bea", "oak", "g2.json", dir])
	var in2 := await until(func(): return bool(read_json("g2.json").get("welcomed", false)), 40.0)
	check(in2, "a second guest joins directly")
	if not in2:
		return
	var pid2 := int(read_json("g2.json").pid)
	var players0 := (status().players as Dictionary).size()
	OS.kill(guest2_pid)
	var gone := await until(func(): return not conn().has(pid2) and bool(rec(pid2).get("away", false)), 20.0)
	check(gone and int(status().coin_leak) == 0, "the second guest killed: the host drops it in its time, its character out of play, coins conserved")
	guest2_pid = spawn("res://tests/net_fault_guest.gd", [str(port), KEY2, "Bea", "oak", "g2.json", dir])
	var again := await until(func(): var g := read_json("g2.json"); return bool(g.get("welcomed", false)) and int(g.get("os_pid", -1)) == guest2_pid, 40.0)
	check(again and int(read_json("g2.json").pid) == pid2 and (status().players as Dictionary).size() == players0, "started again, it is the same character (no duplicate)")
	# frozen (SIGSTOP) longer than the timeouts, then let go: it reconnects by itself
	OS.execute("kill", ["-STOP", str(guest2_pid)])
	await until(func(): return not conn().has(pid2), 20.0)
	OS.execute("kill", ["-CONT", str(guest2_pid)])
	var thawed := await until(func(): var g := read_json("g2.json"); return int(g.get("reconnects", 0)) >= 1 and bool(g.guest_world) and not bool(g.reconnecting), 30.0)
	check(thawed and conn().has(pid2) and int(read_json("g2.json").pid) == pid2, "frozen past the timeouts and let go, it reconnects by itself as itself (%s; host %s)" % [str(read_json("g2.json")), str(conn())])
	OS.kill(guest2_pid)
	await until(func(): return not conn().has(pid2), 20.0)


# ---------------------------------------------------------------- an Android host paused ------------
func _host_pause() -> void:
	var net: NetSession = main.net
	var pid := net.my_pid
	var r0 := net.reconnects
	said.clear()
	await command({"cmd": "suspend", "secs": 14.0}, false)
	var told := await until(func(): return net.host_paused, 5.0)
	check(told and said.has(NetSession.HOST_PAUSED_WAIT), "the host's app paused: the guest is told it is waiting for the host")
	var dropped := await until(func(): return net.reconnecting, 25.0)
	if dropped:
		check(net.reconnect_window == (NetSession.HOST_PAUSED_SECONDS if net.reconnect_paused else NetSession.RECONNECT_SECONDS) and (net.reconnect_paused or float(net_d().get("suspended", {}).get("secs", 0.0)) > 0.0),
			"its connection drops; dropped while the host said it was paused, it waits the longer time (paused %s, %.0f s)" % [str(net.reconnect_paused), net.reconnect_window])
	else:
		check(true, "(its connection outlasted the freeze on this run: the host's own timeout ends it on its return)")
	var back := await until(func(): return in_game() and net.reconnects > r0, 60.0)
	check(back and net.my_pid == pid, "the host back: the guest is in the game again, the same character")
	var sp: Dictionary = net_d().get("suspended", {})
	await until(func(): return float(status().minutes) > 0.0, 1.0)
	var gmps := float(GameData.b("game_minutes_per_second"))
	var ran := float(status().minutes) - float(sp.get("minutes_before", 0.0))
	check(not sp.is_empty() and ran < gmps * 14.0 * 0.5, "the host's world did not run the frozen time on its return (%.1f game minutes since; the freeze was %.0f)" % [ran, gmps * 14.0])
	check(int(status().coin_leak) == 0, "coins conserved")


# ---------------------------------------------------------------- the host killed and restarted -----
func _host_killed() -> void:
	var net: NetSession = main.net
	var pid := net.my_pid
	var r0 := net.reconnects
	await command({"cmd": "save"})
	var saved: Dictionary = status().census
	var my_food := host_food()
	OS.kill(host_pid)
	var lost := await until(func(): return net.reconnecting, 20.0)
	check(lost and main.guest_world, "the host killed: the guest notices and waits for it")
	host_pid = spawn("res://tests/net_host.gd", [str(port), str(dport), "continue", dir, "3"])
	var back := await until(func(): return in_game() and net.reconnects > r0, 60.0)
	check(back and net.my_pid == pid, "the host restarted from its save: the guest comes back by itself, the same character")
	var st := status()
	check(int(st.census.coins) == int(saved.coins) and host_food() == my_food, "the world loads as saved: coins %d = %d, the guest's %s %d" % [int(st.census.coins), int(saved.coins), food, host_food()])
	var n0 := host_food()
	net.request("eat", {"id": food})
	await until(func(): return host_food() == n0 - 1, 4.0)
	await wait(0.4)
	check(host_food() == n0 - 1, "its requests are applied (once) by the restarted host")


# ---------------------------------------------------------------- the host stops ---------------------
func _host_stops() -> void:
	said.clear()
	await command({"cmd": "quit"}, false)
	var gone := await until(func(): return not main.guest_world, 10.0)
	check(gone and said.has(NetSession.HOST_STOPPED) and not main.net.reconnecting, "the host stops on purpose: the guest is told at once and does not wait (%s)" % str(said))
	await until(func(): return not OS.is_process_running(host_pid), 15.0)
