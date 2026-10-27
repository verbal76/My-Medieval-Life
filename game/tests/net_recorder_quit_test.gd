extends SceneTree
## X20 (owner directive 2026-10-27, phases 4.5 and 5): a flight recording ends whenever its world is closed in an orderly way, in a
## network session as in single player. Every process here records (MML_RECORD, inherited by the processes it starts): the host
## (tests/net_host.gd), this guest Ann, and the guest Cara (tests/net_interact_guest.gd). Orderly ends covered: a guest quitting the
## game while in the host's world; the host's "Save and quit to title" (its session ends while the process lives on) and the guests it
## leaves (their copies closed); the host quitting the game with its world open (after a restart from its save). Each session must
## then be ended and "complete", and every archive must pass the independent check, tools/recorder_archive.py (a host's session
## its hourly snapshots, a guest's its hourly net_state digests). A process that is killed is not tested: its archive is
## incomplete, as it should be.
##   godot --headless --path game --script res://tests/net_recorder_quit_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_recq/"
var rec_root := ""
var port := 0
var dport := 0
var host_proc := -1
var cara_proc := -1
var seq := 0
var gseq := 0
var host_pid := 0
const ID_A := "a1123456789abcdef0123456789abcde"
const ID_C := "c1123456789abcdef0123456789abcde"


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 49300 + OS.get_process_id() % 45 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	rec_root = ProjectSettings.globalize_path(dir + "rec_%d" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(rec_root)
	OS.set_environment("MML_RECORD", rec_root)          # this process and every process it starts record (FlightRecorder.env_root)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func spawn(script: String, args: Array) -> int:
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script, "--"] + args
	return OS.create_process(OS.get_executable_path(), a)


func _read(f_: String) -> Dictionary:
	var f := FileAccess.open(dir + f_, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if typeof(d) == TYPE_DICTIONARY else {}


func status() -> Dictionary:
	return _read("status.json")


func cara() -> Dictionary:
	return _read("g2_status.json")


func command(d: Dictionary) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(status().get("seq", -1)) >= seq, 8.0)


func ccmd(d: Dictionary) -> void:
	gseq += 1
	d["seq"] = gseq
	var f := FileAccess.open(dir + "g2_cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "cmd.json"))
	seq = 0
	host_proc = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir, "4"])
	return await until(func(): return status().get("hosting", false), 120.0)


func join_ann() -> bool:
	main.net.join("127.0.0.1", port, ID_A, "Ann", "oak")
	return await until(func(): return main.guest_world, 40.0)


## The session.json of process `pid`'s sessions (FlightRecorder: s<unix>_p<pid>[_n]), oldest first.
func sessions_of(pid: int) -> Array:
	var out := []
	var names := Array(DirAccess.get_directories_at(rec_root))
	names.sort()
	for n in names:
		if str(n).contains("_p%d" % pid):
			var f := FileAccess.open(rec_root + "/" + n + "/session.json", FileAccess.READ)
			var d = JSON.parse_string(f.get_as_text()) if f != null else null
			out.append({"name": n, "rec": d if d is Dictionary else {}})
	return out


func ended(pid: int, i: int) -> bool:
	var ss := sessions_of(pid)
	return ss.size() > i and bool(ss[i].rec.get("ended", false)) and str(ss[i].rec.get("completeness", "")) == "complete"


func state(pid: int) -> Array:
	return sessions_of(pid).map(func(s): return "%s %s" % [s.name, s.rec.get("completeness", "?")])


func _run() -> void:
	check(await start_host("new"), "the host opens its world, recording")
	check(await join_ann(), "Ann joins, recording")
	cara_proc = spawn("res://tests/net_interact_guest.gd", [str(port), ID_C, "Cara", "oak", dir, "g2"])
	check(await until(func(): return cara().get("welcomed", false), 60.0), "Cara joins, recording")
	host_pid = host_proc
	await wait(40.0)                                   # more than a game hour: the host's hourly snapshot, the guests' digests
	# 1. a guest quits the game while in the host's world (its process ends in order)
	ccmd({"cmd": "quit"})
	check(await until(func(): return not OS.is_process_running(cara_proc), 20.0), "Cara quits the game")
	check(ended(cara_proc, 0), "Cara's recording ended with her game (%s)" % [state(cara_proc)])
	# 2. the host's Save and quit to title: its world closes, the process lives on
	await command({"cmd": "quit_to_title"})
	check(await until(func(): return ended(host_pid, 0), 10.0), "the host's Save and quit to title ends its recording (%s; the host says %s)" % [state(host_pid), status().get("rec", {})])
	check(await until(func(): return not main.guest_world, 20.0), "Ann is out of the closed world")
	check(await until(func(): return ended(OS.get_process_id(), 0), 5.0), "Ann's recording of that world ended (%s)" % [state(OS.get_process_id())])
	await command({"cmd": "quit"})
	await until(func(): return not OS.is_process_running(host_proc), 20.0)
	check(sessions_of(host_pid).size() == 1, "the host's process quit from the title left no other session (%s)" % [state(host_pid)])
	# 3. the host back from its save, then quitting the game with its world open
	check(await start_host("continue"), "the host continues its world")
	check(await join_ann(), "Ann rejoins")
	await wait(40.0)
	await command({"cmd": "quit"})
	check(await until(func(): return not OS.is_process_running(host_proc), 20.0), "the host quits the game with its world open")
	check(ended(host_proc, 0), "the host's recording ended with its game (%s)" % [state(host_proc)])
	check(await until(func(): return not main.guest_world, 20.0) and await until(func(): return ended(OS.get_process_id(), 1), 5.0),
		"Ann's second recording ended when the host left (%s)" % [state(OS.get_process_id())])
	# every archive passes the independent check
	var names := Array(DirAccess.get_directories_at(rec_root))
	names.sort()
	check(names.size() == 5, "five sessions: the host's two, Ann's two, Cara's one (%s)" % [names])
	for n in names:
		var out := []
		var rc := OS.execute("python3", [ProjectSettings.globalize_path("res://../tools/recorder_archive.py"), rec_root + "/" + n], out, true)
		var problems := ""
		var r = JSON.parse_string(str(out[0]) if not out.is_empty() else "")
		if r is Dictionary:
			problems = str(r.get("problems", []))
		check(rc == 0, "tools/recorder_archive.py passes %s (%s) %s" % [n, (r.get("net_role", "") if r is Dictionary else ""), problems])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
