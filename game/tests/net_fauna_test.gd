extends SceneTree
## Build 21 (owner directive 2026-10-24, section 4): the animals of the host's world on a guest's machine, over loopback, both
## processes running the real game scene. This process is the guest; tests/net_host.gd the host. The host alone simulates the
## animals; the guest's copy follows: an animal the host moves is where the host has it (NetSession.s_animals), its health the
## host's, one killed on the host goes from the guest's copy and one born there appears (s_fauna_life), a pen's trough is the
## host's (NetSync "fauna"); left alone, the guest's copy does not wander (it is never simulated).
##   godot --headless --path game --script res://tests/net_fauna_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_fauna/"
var port := 0
var dport := 0
var host_pid := -1
var seq := 0
const KEY := "0123456789abcdef0123456789abcdef"


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 49100 + OS.get_process_id() % 40 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "dump.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


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


func mine(id: int) -> Animal:
	return main.world.fauna.by_id(id) if main.world != null else null


func _run() -> void:
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/net_host.gd", "--", str(port), str(dport), "new", dir]
	host_pid = OS.create_process(OS.get_executable_path(), a)
	var up := await until(func(): return status().get("hosting", false), 90.0)
	check(up, "the host opens its world")
	if up:
		main.net.join("127.0.0.1", port, KEY, "Ann", "oak")
		var joined: bool = await until(func(): return main.guest_world, 30.0)
		check(joined, "the guest joins")
		if joined:
			await _animals()
	await command({"cmd": "quit"})
	await until(func(): return not OS.is_process_running(host_pid), 15.0)
	if OS.is_process_running(host_pid):
		OS.kill(host_pid)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _animals() -> void:
	var w: World = main.world
	var st := status()
	var host_ids: Array = (st.animals as Dictionary).keys().map(func(k): return int(k))
	host_ids.sort()
	var my_ids: Array = w.fauna.animals.map(func(x: Animal): return x.id)
	check(host_ids == my_ids and not my_ids.is_empty(), "the guest's copy holds the host's animals (%d)" % my_ids.size())
	# a pen animal: the guest goes beside its pen
	var pick := -1
	var pen := ""
	for k in st.animals:
		if not bool(st.animals[k].wild) and w.fauna.pens.has(str(st.animals[k].area)):
			pick = int(k)
			pen = str(st.animals[k].area)
			break
	check(pick > 0, "a pen animal to watch (%d in %s)" % [pick, pen])
	if pick <= 0:
		return
	var cells: Array = w.fauna.cells(pen)
	var gate: Dictionary = w.fauna.pens[pen]
	var by: Vector2 = Vector2(int(gate.gate[0]), int(gate.gate[1]) + 2) + Vector2(0.5, 0.5)
	await command({"cmd": "guest_to", "x": by.x, "y": by.y})
	await wait(0.5)
	# the host moves it: the guest's copy follows
	var to: Vector2 = Vector2(cells[0]) + Vector2(0.5, 0.5)
	if to.distance_to(mine(pick).pos) < 1.0:
		to = Vector2(cells[-1]) + Vector2(0.5, 0.5)
	await command({"cmd": "animal_to", "id": pick, "x": to.x, "y": to.y})
	var followed: bool = await until(func(): return mine(pick) != null and mine(pick).pos.distance_to(to) < 0.1, 3.0)
	check(followed, "an animal the host moves is where the host has it on the guest's machine (%.2f tiles off)" % (mine(pick).pos.distance_to(to) if mine(pick) else -1.0))
	# left alone it stays: the guest does not simulate it
	await until(func(): return mine(pick).pos.distance_to(to) < 0.005, 2.0)       # the view's easing has settled
	var still := mine(pick).pos
	await wait(2.0)
	var hp := Vector2(float(status().animals[str(pick)].pos[0]), float(status().animals[str(pick)].pos[1]))
	check(mine(pick).pos.distance_to(still) < 0.05 and mine(pick).pos.distance_to(hp) < 0.1, "the guest's copy does not wander on its own (host %s, guest %s)" % [str(hp), str(mine(pick).pos)])
	# its health is the host's
	await command({"cmd": "animal_hurt", "id": pick, "hp": 3.0})
	var hurt: bool = await until(func(): return mine(pick) != null and absf(mine(pick).hp - 3.0) < 0.01, 3.0)
	check(hurt, "an animal's health on the guest's machine is the host's (%.1f)" % (mine(pick).hp if mine(pick) else -1.0))
	# killed on the host: gone from the guest's copy, and its sprite goes
	await command({"cmd": "animal_kill", "id": pick})
	var gone: bool = await until(func(): return mine(pick) == null, 3.0)
	check(gone, "an animal killed on the host is gone from the guest's copy")
	await wait(1.0)
	check(not main.animal_sprites.has(pick), "and from the guest's screen")
	# born on the host: the guest's copy has it, with its kind and place
	var before: Array = (status().animals as Dictionary).keys()
	await command({"cmd": "animal_spawn", "area": pen, "species": str(w.fauna.pens[pen].kind)})
	await until(func(): return (status().animals as Dictionary).size() > before.size(), 3.0)
	var born := -1
	for k in status().animals:
		if not before.has(k):
			born = int(k)
	var arrived: bool = await until(func(): return mine(born) != null, 3.0)
	check(born > 0 and arrived and mine(born).species == str(status().animals[str(born)].species) and mine(born).area == pen,
		"an animal born on the host appears on the guest's machine (%d, %s)" % [born, mine(born).species if mine(born) else "-"])
	# a pen's trough (the fauna section, sent with the shared world)
	await command({"cmd": "pen_trough", "id": pen, "n": 37})
	var s0: int = main.net.syncs
	await command({"cmd": "dump", "keys": ["fauna"]})
	await until(func(): return main.net.syncs > s0, 3.0)
	await wait(0.3)
	check(int(w.fauna.pens[pen].trough) == 37, "a pen's trough on the guest's machine is the host's (%d)" % int(w.fauna.pens[pen].trough))
	var ids2: Array = (status().animals as Dictionary).keys().map(func(k): return int(k))
	ids2.sort()
	check(ids2 == w.fauna.animals.map(func(x: Animal): return x.id), "after the deaths and births both machines hold the same animals")
	# every animal far from the guest stands where the host has it after a section sync
	var far_off := 0
	var host_now: Dictionary = status().animals
	var hp0 := Vector2(float(status().host_pos[0]), float(status().host_pos[1]))
	for x: Animal in w.fauna.animals:
		var hpos := Vector2(float(host_now[str(x.id)].pos[0]), float(host_now[str(x.id)].pos[1]))
		var quiet: bool = hpos.distance_to(hp0) > w.detail_radius + 4.0          # far from the host too: it is not moving there
		if quiet and x.pos.distance_to(w.player.pos) > NetProtocol.NPC_RANGE and x.pos.distance_to(hpos) > 0.1:
			far_off += 1
	check(far_off == 0, "animals beyond the snapshots' reach are where the host had them at the last sync (%d off)" % far_off)
