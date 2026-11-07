extends SceneTree
## B25R2-CAVE (owner's playtest, 2026-11-07): a guest who followed the host into a cave stood "in the black outside": on the cave's
## level at a place outside it, in rock, for good. The guest's copy goes through a portal at once (World.mirror) and sends the passage
## to the host as a request; its moves went on meanwhile, and the host, its record of the guest still outside, refused them and sent the
## guest back by place only (s_correct): the copy kept the cave's level. Nothing ever told the guest its level again.
## Two Godot processes over loopback: this one the guest (the real game), tests/net_host.gd the host. Checked: through the cave's mouth
## and out again the two machines agree on the guest's level and place; a copy on the cave's level that the host has outside (the
## playtest's state) is put back on the host's level and place within seconds. Real devices and networks are not tested here.
##   godot --headless --path game --script res://tests/net_cave_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_cave/"
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
	port = 48700 + OS.get_process_id() % 40 * 2
	dport = port + 1
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


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


## The host's record of this guest, {} before it exists.
func me() -> Dictionary:
	return status().get("players", {}).get(str(main.net.my_pid), {})


## Whether the host and this copy agree: the same level `level` and places within `tiles`.
func agree(level: int, tiles := 1.5) -> bool:
	var m := me()
	if m.is_empty() or main.world == null:
		return false
	var hp := Vector2(float(m.pos[0]), float(m.pos[1]))
	return int(m.get("level", 0)) == level and main.world.player.map_level == level and hp.distance_to(main.world.player.pos) <= tiles


func say() -> String:
	var m := me()
	return "host: level %s at %s; guest: level %d at %s" % [str(m.get("level", "?")), str(m.get("pos", "?")),
		main.world.player.map_level if main.world != null else -99, str(main.world.player.pos) if main.world != null else "-"]


func _run() -> void:
	host_pid = spawn("res://tests/net_host.gd", [str(port), str(dport), "new", dir])
	check(await until(func(): return status().get("hosting", false), 90.0), "a host process starts a new world and hosts it (port %d)" % port)
	main.net.join("127.0.0.1", port, KEY, "Ann", "oak")
	check(await until(func(): return main.guest_world and main.world != null and not me().is_empty(), 30.0), "the guest joins the host's world")
	var w: World = main.world
	var portal := {}
	if w != null and w.underground != null:
		for p in w.underground.portals:
			if str(p.get("kind", "")) != "shaft" and (int(p.ends[0].level) == 0 or int(p.ends[1].level) == 0):
				portal = p
				break
	check(not portal.is_empty(), "the world has a way below from the surface (%s)" % str(portal.get("id", "none")))
	if portal.is_empty() or w == null:
		_end()
		return
	var out: Dictionary = portal.ends[0] if int(portal.ends[0].level) == 0 else portal.ends[1]
	var inn: Dictionary = portal.ends[1] if out == portal.ends[0] else portal.ends[0]
	var at_out := Vector2(out.stand) + Vector2(0.5, 0.5)
	# 1. through the mouth and out again, as a player walks it: the two machines agree at each step
	await command({"cmd": "guest_to", "x": at_out.x, "y": at_out.y})
	check(await until(func(): return agree(0, 0.2), 5.0), "the guest stands at the mouth on the surface, on both machines (%s)" % say())
	var r: Dictionary = w.player_through(Vector2(out.door - out.stand))
	check(int(r.get("level", 0)) == int(inn.level), "the guest's copy goes through at once (%s)" % str(r))
	check(await until(func(): return agree(int(inn.level)), 6.0), "the host takes the guest through too: both have it inside, on level %d (%s)" % [int(inn.level), say()])
	await wait(1.0)
	check(agree(int(inn.level)), "a second later they still agree: the guest's moves inside are not sent back outside (%s)" % say())
	r = w.player_through(Vector2(inn.door - inn.stand))
	check(int(r.get("level", -1)) == 0, "the way back out, on the guest's copy (%s)" % str(r))
	check(await until(func(): return agree(0), 6.0), "and on the host: both have the guest on the surface again (%s)" % say())
	# 2. the playtest's state: the copy inside, on the cave's level, while the host has the guest outside (a passage the host never
	# applied). Before the fix the host sent the place back and the level stayed: in rock, for good.
	await command({"cmd": "guest_to", "x": at_out.x + 0.0, "y": at_out.y})
	await until(func(): return agree(0, 0.2), 5.0)
	w.player.map_level = int(inn.level)
	w.player.pos = Vector2(inn.stand) + Vector2(0.5, 0.5)
	check(await until(func(): return agree(0), 6.0), "a copy left on the cave's level while the host has it outside is put back on the host's level and place (%s)" % say())
	var c := Vector2i(floori(w.player.pos.x), floori(w.player.pos.y))
	check(w.player.map_level == 0 and not w.map.is_solid(c), "and stands on open ground, not in rock (%s, level %d)" % [str(c), w.player.map_level])
	_end()


func _end() -> void:
	if host_pid > 0 and OS.is_process_running(host_pid):
		OS.kill(host_pid)
	print("net_cave_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
