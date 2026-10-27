extends SceneTree
## X20 (owner directive 2026-10-27, phases 4.5 and 5, item 11): a recorded multiplayer soak. One host and three guests (or two:
## "-- 2"), every process recording (MML_RECORD, inherited by the processes this one starts), play ordinarily for at least
## HOURS game hours: walking about, gifts and sales between players answered in their windows, messages, the host's own gifts;
## one guest leaves and comes back; the host saves while everyone plays. Then everyone leaves in order (the guests quit the game,
## the host quits with its world open), and a host process that records nothing loads the save to check that it continues where
## it stopped (coins, goods, clock). Every archive must pass tools/recorder_archive.py, and tools/recorder_archive.py
## --participants (the host's and each guest's hourly net_state digests) must find no section differing for three hours running.
## This process is the guest Ann; tests/net_host.gd the host; tests/net_interact_guest.gd Cara (g2) and Dan (g3).
##   godot --headless --path game --script res://tests/net_soak_test.gd [-- GUESTS(2|3) [HOURS]]

const ID_A := "a2123456789abcdef0123456789abcde"
const ID_C := "c2123456789abcdef0123456789abcde"
const ID_D := "d2123456789abcdef0123456789abcde"
const ORE := "iron_ore"

var main
var failures := 0
var checks := 0
var dir := "user://test_net_soak/"
var rec_root := ""
var port := 0
var dport := 0
var host_proc := -1
var procs := {}
var seq := 0
var gseq := {"g2": 0, "g3": 0}
var host_pid := 0
var ann := 0
var pids := {}                    # tag -> pid
var guests := 3
var hours := 4.0
var rounds := {"gifts": 0, "sales": 0, "says": 0, "host_gifts": 0, "walks": 0}


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		guests = clampi(int(a[0]), 2, 3)
	if a.size() > 1:
		hours = float(a[1])
	port = 49500 + OS.get_process_id() % 45 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	rec_root = ProjectSettings.globalize_path(dir + "rec_%d_%dg" % [OS.get_process_id(), guests])
	DirAccess.make_dir_recursive_absolute(rec_root)
	OS.set_environment("MML_RECORD", rec_root)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- helpers -----------------------
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


func gs(tag: String) -> Dictionary:
	return _read(tag + "_status.json")


func command(d: Dictionary) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(status().get("seq", -1)) >= seq, 8.0)


func gcmd(tag: String, d: Dictionary) -> void:
	gseq[tag] += 1
	d["seq"] = gseq[tag]
	var f := FileAccess.open(dir + tag + "_cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	await until(func(): return int(gs(tag).get("seq", -1)) >= int(gseq[tag]), 8.0)


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func rec(pid: int) -> Dictionary:
	return status().get("players", {}).get(str(pid), {})


func ore(pid: int) -> int:
	return int(rec(pid).get("inv", {}).get(ORE, 0))


func all_ore() -> int:
	var n := ore(host_pid) + ore(ann)
	for t in pids:
		n += ore(int(pids[t]))
	return n


func ref(pid: int) -> String:
	return "player" if pid == host_pid else "player:%d" % pid


func host_offers(kind: String, from_pid: int, to_pid: int) -> Array:
	var out := []
	for o in status().get("offers", []):
		if str(o.kind) == kind and str(o["from"]) == ref(from_pid) and str(o.to) == ref(to_pid):
			out.append(o)
	return out


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "cmd.json"))
	seq = 0
	host_proc = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir, "4"])
	return await until(func(): return status().get("hosting", false), 120.0)


func start_guest(tag: String, k: String, nm: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + tag + "_status.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + tag + "_cmd.json"))
	gseq[tag] = 0
	procs[tag] = spawn("res://tests/net_interact_guest.gd", [str(port), k, nm, "oak", dir, tag])


func stage() -> void:
	for attempt in 4:
		await command({"cmd": "stage"})
		main.move_to = Vector2.INF
		for t in pids:
			await gcmd(t, {"cmd": "still"})
		await wait(0.8)
		var sp: Array = status().get("spot", [])
		if sp.size() != 2:
			continue
		var want := Vector2(float(sp[0]), float(sp[1])) + Vector2(1, 0)
		var host_has: Array = rec(ann).get("pos", [0, 0])
		if main.world.player.pos.distance_to(want) < 0.1 and Vector2(float(host_has[0]), float(host_has[1])).distance_to(want) < 0.1:
			break
	await wait(0.6)


func minutes() -> float:
	return float(status().get("minutes", 0.0))


# ---------------------------------------------------------------- the run ------------------------
func _run() -> void:
	var t0 := Time.get_ticks_msec()
	check(await start_host("new"), "the host opens its world, recording")
	host_pid = int(status().host_pid)
	check(await until(func(): return str(status().get("rec", {}).get("state", "")) == "recording", 5.0), "the host records (%s)" % status().get("rec", {}))
	main.net.join("127.0.0.1", port, ID_A, "Ann", "oak")
	check(await until(func(): return main.guest_world, 40.0) and main.world.recorder != null, "Ann joins, recording")
	ann = main.net.my_pid
	var plan := [["g2", ID_C, "Cara"], ["g3", ID_D, "Dan"]].slice(0, guests - 1)
	for g in plan:
		start_guest(g[0], g[1], g[2])
		check(await until(func(): return gs(g[0]).get("welcomed", false), 60.0), "%s joins, recording" % g[2])
		pids[g[0]] = int(gs(g[0]).pid)
	check(status().get("connected", []).size() == guests, "1 host + %d guests" % guests)
	await command({"cmd": "give", "id": ORE, "n": 20})
	await command({"cmd": "give_host", "id": ORE, "n": 20})
	var m0 := minutes()
	var coins_ok := true
	var ore_ok := true
	var left := false
	var saved := false
	var r := 0
	while minutes() < m0 + hours * 60.0:
		r += 1
		await stage()
		var total := all_ore()
		await _round(r)
		await wait(1.5)
		coins_ok = coins_ok and int(status().get("coin_leak", 1)) == 0
		ore_ok = ore_ok and all_ore() == total
		await _walk(r)
		if not left and minutes() >= m0 + 90.0:
			left = true
			await _leave_and_back(plan[-1][0])
		if not saved and minutes() >= m0 + 150.0:
			saved = true
			await command({"cmd": "save"})
			check(str(status().get("census", {}).get("at", "")) == "saved_live", "the host saves while everyone plays (day %d)" % int(status().get("day", 0)))
	check(left and saved, "a guest left and came back; the host saved while everyone played")
	check(coins_ok, "coins conserved on the host after every round (%d rounds)" % r)
	check(ore_ok, "ore conserved over every player after every round")
	check(rounds.gifts > 0 and rounds.sales > 0 and rounds.says > 0 and rounds.host_gifts > 0 and rounds.walks > 0,
		"ordinary play happened: %s over %.1f game hours" % [rounds, (minutes() - m0) / 60.0])
	# orderly ends: the guests quit, the host quits with its world open (saving)
	var ended_at := minutes()
	for t in pids:
		await gcmd(t, {"cmd": "quit"})
		check(await until(func(): return not OS.is_process_running(procs[t]), 20.0), "%s quits the game" % t)
	await command({"cmd": "quit"})
	check(await until(func(): return not OS.is_process_running(host_proc), 30.0), "the host quits the game with its world open")
	var census: Dictionary = status().get("census", {})
	check(await until(func(): return not main.guest_world, 20.0), "Ann is out")
	# the save continues where it stopped: a host that records nothing loads it
	OS.set_environment("MML_RECORD", "")
	check(await start_host("continue"), "a host loads the save (not recording)")
	OS.set_environment("MML_RECORD", rec_root)
	var loaded: Dictionary = status().get("census", {})
	check(str(census.get("at", "")) == "saved" and absf(float(loaded.get("minutes", -1)) - float(census.get("minutes", -2))) < 0.01
		and int(loaded.get("coins", -1)) == int(census.get("coins", -2)) and JSON.stringify(loaded.get("goods")) == JSON.stringify(census.get("goods")),
		"load continuity: the clock (%.2f / %.2f), coins and goods as saved" % [float(census.get("minutes", -1)), float(loaded.get("minutes", -1))])
	check(str(status().get("rec", {}).get("dir", "x")) == "", "that host records nothing")
	await command({"cmd": "quit"})
	await until(func(): return not OS.is_process_running(host_proc), 30.0)
	main.end_recording()
	_archives(ended_at - m0)
	print("%d checks, %d failures (%.0f s)" % [checks, failures, (Time.get_ticks_msec() - t0) / 1000.0])
	quit(1 if failures > 0 else 0)


## One round of ordinary exchanges, each answered in the recipient's own window: Ann gives Cara an ore, the last guest sells Ann an
## ore for 2 coins, Cara says hello to the last guest (to Ann with two guests), the host gives Ann an ore.
func _round(r: int) -> void:
	var last := "g3" if pids.has("g3") else "g2"
	var cara := int(pids["g2"])
	var lastp := int(pids[last])
	main.world.player_offer("gift", cara, ORE, 1)
	if await until(func(): return not host_offers("gift", ann, cara).is_empty(), 5.0):
		var o: Dictionary = host_offers("gift", ann, cara)[0]
		await until(func(): return (gs("g2").get("offers", []) as Array).any(func(x): return int(x.id) == int(o.id)), 5.0)
		await gcmd("g2", {"cmd": "show_player", "pid": ann})
		await gcmd("g2", {"cmd": "press", "name": "OfferAccept%d" % int(o.id)})
		await gcmd("g2", {"cmd": "close"})
		if await until(func(): return host_offers("gift", ann, cara).is_empty(), 5.0):
			rounds.gifts += 1
	if r % 2 == 1:                                     # the coins go round: the last guest sells to Ann, then Ann to them
		await gcmd(last, {"cmd": "offer", "kind": "sell", "to": ann, "item": ORE, "qty": 1, "price": 2})
		if await until(func(): return main.world.offers_to(main.world.player).any(func(x): return str(x.kind) == "sell"), 5.0):
			var s: Dictionary = main.world.offers_to(main.world.player).filter(func(x): return str(x.kind) == "sell")[0]
			main.ui.show_player(lastp)
			await process_frame
			for b in main.ui.panel_body.find_children("OfferAccept%d" % int(s.id), "Button", true, false):
				(b as Button).pressed.emit()
			main.ui.hide_all()
			if await until(func(): return host_offers("sell", lastp, ann).is_empty(), 5.0):
				rounds.sales += 1
	else:
		main.world.player_offer("sell", lastp, ORE, 1, null, 2)
		if await until(func(): return not host_offers("sell", ann, lastp).is_empty(), 5.0):
			var s2: Dictionary = host_offers("sell", ann, lastp)[0]
			await until(func(): return (gs(last).get("offers", []) as Array).any(func(x): return int(x.id) == int(s2.id)), 5.0)
			await gcmd(last, {"cmd": "show_player", "pid": ann})
			await gcmd(last, {"cmd": "press", "name": "OfferAccept%d" % int(s2.id)})
			await gcmd(last, {"cmd": "close"})
			if await until(func(): return host_offers("sell", ann, lastp).is_empty(), 5.0):
				rounds.sales += 1
	await gcmd("g2", {"cmd": "say", "to": lastp if lastp != cara else ann, "text": "Round %d" % r})
	rounds.says += 1
	await command({"cmd": "offer", "kind": "gift", "to": ann, "item": ORE, "qty": 1})
	if await until(func(): return main.world.offers_to(main.world.player).any(func(x): return str(x.kind) == "gift" and str(x["from"]) == "player"), 5.0):
		var h: Dictionary = main.world.offers_to(main.world.player).filter(func(x): return str(x.kind) == "gift" and str(x["from"]) == "player")[0]
		main.ui.show_player(host_pid)
		await process_frame
		for b in main.ui.panel_body.find_children("OfferAccept%d" % int(h.id), "Button", true, false):
			(b as Button).pressed.emit()
		main.ui.hide_all()
		if await until(func(): return host_offers("gift", host_pid, ann).is_empty(), 5.0):
			rounds.host_gifts += 1


## Everyone walks somewhere near and back, by the game's own routing (a tap on the ground), the host by its own steps.
func _walk(r: int) -> void:
	var sp: Array = status().get("spot", [])
	if sp.size() != 2:
		return
	var at := Vector2(float(sp[0]), float(sp[1]))
	var offs := [Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0), Vector2(0, -4)]
	main.move_to = at + offs[r % 4] + Vector2(1, 0)
	var i := 1
	for t in pids:
		await gcmd(t, {"cmd": "walk", "x": at.x + offs[(r + i) % 4].x, "y": at.y + offs[(r + i) % 4].y + 1.4})
		i += 1
	await command({"cmd": "walk_host", "tiles": 3.0})
	await wait(3.0)
	rounds.walks += 1


func _leave_and_back(t: String) -> void:
	var pid := int(pids[t])
	await gcmd(t, {"cmd": "leave"})
	check(await until(func(): return rec(pid).get("away", false), 10.0), "%s leaves the world" % t)
	await wait(5.0)
	await gcmd(t, {"cmd": "join"})
	check(await until(func(): return gs(t).get("welcomed", false), 40.0) and int(gs(t).pid) == pid, "%s comes back as the same character" % t)


## Every archive passes the independent check; the host's and guests' digests agree (tools/recorder_archive.py --participants).
func _archives(played_minutes: float) -> void:
	var tool := ProjectSettings.globalize_path("res://../tools/recorder_archive.py")
	var names := Array(DirAccess.get_directories_at(rec_root))
	names.sort()
	var host_dir := ""
	var guest_dirs := []
	for n in names:
		var out := []
		var rc := OS.execute("python3", [tool, rec_root + "/" + n], out, true)
		var r = JSON.parse_string(str(out[0]) if not out.is_empty() else "")
		var role := str(r.get("net_role", "")) if r is Dictionary else ""
		check(rc == 0, "recorder_archive.py passes %s (%s; %s snapshots, %s digests) %s" % [n, role, r.get("snapshot_hours", "?") if r is Dictionary else "?",
			r.get("net_state_hours", "-") if r is Dictionary else "?", r.get("problems", []) if r is Dictionary else str(out)])
		if role == "host":
			host_dir = rec_root + "/" + n
		elif role == "guest":
			guest_dirs.append(rec_root + "/" + n)
	check(host_dir != "" and guest_dirs.size() == guests + 1, "one host session and %d guest sessions (one guest came back): %s" % [guests + 1, names])
	if host_dir == "":
		return
	var out2 := []
	var rc2 := OS.execute("python3", [tool, "--participants", host_dir] + guest_dirs, out2, true)
	print("participants: ", str(out2[0]) if not out2.is_empty() else "")
	var p = JSON.parse_string(str(out2[0]) if not out2.is_empty() else "")
	check(rc2 == 0, "--participants: no section differs from the host's for three hours running %s" % [p.get("problems", []) if p is Dictionary else ""])
	if p is Dictionary:
		var compared: Array = (p.get("differences", {}) as Dictionary).values().map(func(x): return int(x.hours_compared))
		check(compared.size() == guest_dirs.size() and compared.all(func(n): return n >= 1) and compared.max() >= 3,
			"each guest session compared hour by hour with the host (%s hours; %.1f game hours played)" % [compared, played_minutes / 60.0])
