extends SceneTree
## ND-26 (NetSession.zz_tick, _watch_guests): the liveness watchdog on the reliable heartbeat, with real Godot processes on loopback.
## This process is guest A running the real game (main.gd); tests/net_host.gd is the host in another process; tests/net_fault_guest.gd
## a second guest the test stalls and freezes. ENet alone found a guest frozen right after joining only up to ~27 s later (its
## timeouts are checked when a reliable resend is due, and the waits double from a round trip the joining guest's long frame
## inflated); the watchdog drops a playing guest silent past NetSession.TIMEOUT_MAX_MS. Covers: a live guest is never dropped (its
## own frame late by a few seconds included); a guest still building its world (longer than TIMEOUT_MAX_MS) is not dropped; a
## playing guest frozen shorter than the timeouts is kept; one frozen past them is dropped within TIMEOUT_MAX_MS (plus a frame and
## the status file's delay), out of play (MP-D1), and comes back as itself when let go; the host frozen: the guest finds it silent
## within the same time and waits for it, then comes back.
##   godot --headless --path game --script res://tests/net_liveness_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_liveness/"
var port := 0
var dport := 0
var host_pid := -1
var guest2_pid := -1
const KEY := "1a1b2c3d4e5f60718293a4b5c6d7e8f9"
const KEY2 := "e9e8d7c6b5a4938271605f4e3d2c1b0a"
const SLACK := 3.0                 # seconds over TIMEOUT_MAX_MS a drop may take: a heartbeat interval, frames, the status files' 0.2 s


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 48300 + OS.get_process_id() % 40 * 4
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "g2.json", "g2.json.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


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


func net_d() -> Dictionary:
	return status().get("net_d", {})


func conn() -> Array:
	return (status().get("connected", []) as Array).map(func(x): return int(x))


func rec(pid: int) -> Dictionary:
	return status().get("players", {}).get(str(pid), {})


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


## Waits `secs`; false if `cond` turned false at any frame meanwhile.
func holds(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if not cond.call():
			return false
		await process_frame
	return cond.call()


func in_game() -> bool:
	return main.guest_world and main.net.connected() and not main.net.reconnecting


func _run() -> void:
	host_pid = spawn("res://tests/net_host.gd", [str(port), str(dport), "new", dir, "3"])
	var up := await until(func(): return status().get("hosting", false), 90.0)
	check(up, "the host is up")
	if up:
		main.net.join("127.0.0.1", port, KEY, "Ann", "oak")
		var joined := await until(func(): return in_game() and main.net.host_heard >= 0, 40.0)
		check(joined, "guest A joins and plays (the host watched from its first frame after the world)")
		if joined:
			await _live()
			await _guest2()
			await _host_silent()
	for p in [host_pid, guest2_pid]:
		if p > 0 and OS.is_process_running(p):
			OS.kill(p)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- a live guest -----------------------
func _live() -> void:
	var net: NetSession = main.net
	var pid := net.my_pid
	var stay := func(): return in_game() and net.reconnects == 0 and conn().has(pid)
	var kept := await holds(stay, NetSession.TIMEOUT_MAX_MS / 1000.0 + SLACK)
	check(kept and int(net_d().get("watchdog", -1)) == 0 and net.host_silent_losses == 0,
		"a live guest with heartbeats is kept past TIMEOUT_MAX_MS, both ways (host drops %s, guest losses %d)" % [str(net_d().get("watchdog")), net.host_silent_losses])
	OS.delay_msec(NetSession.RESUME_AFTER_PAUSE_MS - 1000)     # one late frame of this guest, shorter than the timeouts
	var kept2 := await holds(stay, NetSession.TIMEOUT_MAX_MS / 1000.0 + SLACK)
	check(kept2 and int(net_d().get("watchdog", -1)) == 0 and net.host_silent_losses == 0 and not bool(rec(pid).get("away", true)),
		"a late frame of %d s is not silence: neither side drops the other, the guest stays in play" % [(NetSession.RESUME_AFTER_PAUSE_MS - 1000) / 1000])


# ---------------------------------------------------------------- a second guest: joining, frozen ----
func _guest2() -> void:
	var stall := NetSession.TIMEOUT_MAX_MS + 3000      # its world takes longer to build than the watchdog's limit
	guest2_pid = spawn("res://tests/net_fault_guest.gd", [str(port), KEY2, "Bea", "oak", "g2.json", dir, str(stall)])
	var in2 := await until(func(): return bool(read_json("g2.json").get("welcomed", false)), 40.0 + stall / 1000.0)
	check(in2, "a second guest joins")
	if not in2:
		return
	var pid2 := int(read_json("g2.json").pid)
	var played := await until(func(): return int(net_d().get("joining", -1)) == 0 and conn().has(pid2), NetSession.JOIN_TIMEOUT_MS / 1000.0)
	await until(func(): return false, 2.0)
	var g2 := read_json("g2.json")
	check(played and conn().has(pid2) and int(net_d().get("watchdog", -1)) == 0 and int(g2.get("reconnects", -1)) == 0,
		"building its world for %d s (longer than TIMEOUT_MAX_MS), it is not dropped; then it plays (%s; host drops %s)" % [stall / 1000, str(g2), str(net_d().get("watchdog"))])
	# frozen shorter than the timeouts (and than ENet's TIMEOUT_MIN_MS): kept
	var short := NetSession.TIMEOUT_MIN_MS - 1500
	OS.execute("kill", ["-STOP", str(guest2_pid)])
	var held := await holds(func(): return conn().has(pid2), short / 1000.0)
	OS.execute("kill", ["-CONT", str(guest2_pid)])
	check(held and int(net_d().get("watchdog", -1)) == 0, "frozen %.1f s while playing, it is kept (host drops %s)" % [short / 1000.0, str(net_d().get("watchdog"))])
	await until(func(): var g := read_json("g2.json"); return bool(g.get("guest_world", false)) and not bool(g.get("reconnecting", true)) and conn().has(pid2), 20.0)
	await until(func(): return false, 2.0)
	# frozen past the timeouts: dropped within TIMEOUT_MAX_MS
	var players0 := (status().players as Dictionary).size()
	OS.execute("kill", ["-STOP", str(guest2_pid)])
	var t_stop := Time.get_ticks_msec()
	var dropped := await until(func(): return not conn().has(pid2) and bool(rec(pid2).get("away", false)), NetSession.TIMEOUT_MAX_MS / 1000.0 + SLACK)
	var after := (Time.get_ticks_msec() - t_stop) / 1000.0
	# its connection ended too (Godot's peer list holds guest A only: no ghost peer left for the broadcasts)
	var ended := await until(func(): return int(net_d().get("mp_peers", -1)) == 1, 2.0)
	check(dropped and ended and int(status().get("coin_leak", 0)) == 0,
		"frozen past the timeouts, it is dropped within %.0f s (after %.1f s; watchdog drops %s), out of play, its connection ended (peers %s), coins conserved" % [NetSession.TIMEOUT_MAX_MS / 1000.0 + SLACK, after, str(net_d().get("watchdog")), str(net_d().get("mp_peers"))])
	await until(func(): return false, 1.0)
	OS.execute("kill", ["-CONT", str(guest2_pid)])
	var back := await until(func(): var g := read_json("g2.json"); return int(g.get("reconnects", 0)) >= 1 and bool(g.get("guest_world", false)) and not bool(g.get("reconnecting", true)) and conn().has(pid2), 30.0)
	check(back and int(read_json("g2.json").pid) == pid2 and (status().players as Dictionary).size() == players0, "let go, it comes back as itself (no second character)")
	OS.kill(guest2_pid)
	await until(func(): return not conn().has(pid2), 20.0)


# ---------------------------------------------------------------- the host silent --------------------
func _host_silent() -> void:
	var net: NetSession = main.net
	var pid := net.my_pid
	var r0 := net.reconnects
	await until(func(): return false, 2.0)
	OS.execute("kill", ["-STOP", str(host_pid)])
	var t_stop := Time.get_ticks_msec()
	var lost := await until(func(): return net.reconnecting, NetSession.TIMEOUT_MAX_MS / 1000.0 + SLACK)
	var after := (Time.get_ticks_msec() - t_stop) / 1000.0
	check(lost and main.guest_world, "the host frozen: the guest finds it silent within %.0f s and waits for it (after %.1f s; by the heartbeat %d)" % [NetSession.TIMEOUT_MAX_MS / 1000.0 + SLACK, after, net.host_silent_losses])
	await until(func(): return false, 1.0)
	OS.execute("kill", ["-CONT", str(host_pid)])
	var back := await until(func(): return in_game() and net.reconnects > r0, 60.0)
	check(back and net.my_pid == pid, "the host let go: the guest comes back by itself, the same character")
