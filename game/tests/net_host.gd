extends SceneTree
## MP-01 test host: a real game (main.gd) hosting its world in its own Godot process, driven by
## game/tests/net_test.gd through a command file and reporting through a status file (both under
## user://test_net/). Args after "--": port discovery_port mode(new|continue) dir.

var main
var dir := "user://test_net/"
var mode := "new"
var port := 47900
var dport := 47901
var last_seq := -1
var t_status := 0.0
var started := false
var frames := 0
var frame_time := 0.0
var walk := 0.0


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	port = int(a[0])
	dport = int(a[1])
	mode = str(a[2])
	dir = str(a[3])
	DirAccess.make_dir_recursive_absolute(dir)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "host_save.json"
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	if mode == "continue":
		main.continue_game()
	else:
		main.new_game()
	var why: String = main.host_game({"port": port, "discovery_port": dport, "max_players": 2, "password": "oak",
		"host_name": "Hosta", "world_name": "Test Vale"})
	started = why == ""
	if not started:
		printerr("host failed: ", why)
	_status()


func _process(delta: float) -> bool:
	if not started:
		return false
	frames += 1
	frame_time += Performance.get_monitor(Performance.TIME_PROCESS)
	if walk > 0.0:
		var step := minf(walk, 3.0 * delta)
		main.world.player.pos.x += step
		walk -= step
	t_status += delta
	if t_status >= 0.1:
		t_status = 0.0
		_commands()
		_status()
	return false


func _commands() -> void:
	var f := FileAccess.open(dir + "cmd.json", FileAccess.READ)
	if f == null:
		return
	var c = JSON.parse_string(f.get_as_text())
	if typeof(c) != TYPE_DICTIONARY or int(c.seq) <= last_seq:
		return
	last_seq = int(c.seq)
	var w: World = main.world
	match str(c.cmd):
		"walk_host":
			walk = float(c.tiles)
			main.player_sprite.face(Vector2.RIGHT)
		"summer":
			w.minutes = 2.0 * 1440.0 + 600.0
		"ripen":
			var t: Dictionary = w.trees[int(c.tree)]
			t.state = "grown"
			t.erase("fruit_day")
		"host_pick":
			main.world.player.inv.add("apple", 0)
			var got := w.pick_fruit(w.trees[int(c.tree)])
			main.world.player.inv.add("apple", int(got.get("apple", 0)))
		"guest_to":
			for id in main.net.by_peer:
				var p: PlayerState = w.guests[main.net.by_peer[id]].state
				p.pos = Vector2(float(c.x), float(c.y))
				main.net.rpc_id(id, "s_correct", p.pos)
		"quit":
			main.save_game(false)
			main.net.stop()
			_status()
			quit(0)


func _status() -> void:
	var w: World = main.world
	var guests := {}
	for kh in w.guests:
		var p: PlayerState = w.guests[kh].state
		guests[kh] = {"name": w.guests[kh].name, "pos": [p.pos.x, p.pos.y], "apples": p.inv.count("apple"), "coins": p.coins, "sprite": p.sprite}
	var connected := []
	for id in main.net.by_peer:
		connected.append(main.net.by_peer[id])
	var tr: Vector2i = main.net.traffic()
	var d := {"hosting": main.net.is_host(), "seq": last_seq, "guests": guests, "connected": connected, "rejected": main.net.rejected,
		"host_pos": [w.player.pos.x, w.player.pos.y], "host_apples": w.player.inv.count("apple"), "sent": tr.x, "received": tr.y,
		"frame_ms": 1000.0 * frame_time / maxf(1.0, frames), "memory_mb": OS.get_static_memory_usage() / 1048576.0,
		"npcs_alive": w.npcs.filter(func(n): return n.alive).size(), "minutes": w.minutes}
	frames = 0
	frame_time = 0.0
	var tmp := dir + "status.tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(dir + "status.json"))
