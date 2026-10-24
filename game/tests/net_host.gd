extends SceneTree
## Multiplayer A2 test host (carried forward from the MP-01 prototype): the real game (main.gd) hosting its world in its own
## Godot process, driven by game/tests/net_g1_test.gd through a command file and reporting through a status file (both in
## the given directory). Args after "--": port discovery_port mode(new|continue) dir.

var main
var dir := "user://test_net/"
var mode := "new"
var port := 47900
var dport := 47901
var last_seq := -1
var t_status := 0.0
var started := false
var walk := 0.0
var coins0 := 0
var stats0 := {}


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
	main.ui.hide_all()
	var why: String = main.host_game({"port": port, "discovery_port": dport, "max_players": 2, "password": "oak",
		"host_name": "Hosta", "world_name": "Test Vale"})
	started = why == ""
	if not started:
		printerr("host failed: ", why)
	coins0 = main.world.total_coins()
	stats0 = main.world.stats.duplicate()
	_status()


func _process(delta: float) -> bool:
	if not started:
		return false
	main.world.host_player().hunger = 100.0          # the idle host does not starve while the test runs
	if walk > 0.0:
		var step := minf(walk, 3.0 * delta)
		main.world.host_player().pos.x += step
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
		"guest_to":
			for id in main.net.by_peer:
				var p: PlayerState = w.player_by_pid(int(main.net.by_peer[id]))
				p.pos = Vector2(float(c.x), float(c.y))
				main.net.rpc_id(id, "s_correct", p.pos)
		"host_pick":
			var pl := w.plant_at(Vector2i(int(c.x), int(c.y)))
			var got := w.pick_plant(pl)                  # the host's own character, as in single player
			for id in got:
				w.host_player().inv.add(id, int(got[id]))
		"ripen":
			var pl2 := w.plant_at(Vector2i(int(c.x), int(c.y)))
			pl2.state = "ripe"
		"quit":
			main.save_game(false)
			main.net.stop()
			main.save_game(false)
			_status()
			quit(0)


func _status() -> void:
	var w: World = main.world
	var players := {}
	for p: PlayerState in w.player_list():
		players[str(p.pid)] = {"name": p.name, "pos": [p.pos.x, p.pos.y], "inv": p.inv.items.duplicate(), "coins": p.coins, "hunger": p.hunger,
			"away": p.away, "host": w.is_host(p), "ref": w.player_ref(p), "key": p.net_key}
	var connected := []
	for id in main.net.by_peer:
		connected.append(int(main.net.by_peer[id]))
	var plants := {}
	for pl in w.plants:
		plants["%d,%d" % [int(pl.x), int(pl.y)]] = str(pl.state)
	var c_in := int(w.stats.get("newcomer_coins_in", 0)) - int(stats0.get("newcomer_coins_in", 0)) + int(w.stats.get("caravan_coins_in", 0)) - int(stats0.get("caravan_coins_in", 0)) \
		- int(w.stats.get("caravan_coins_out", 0)) + int(stats0.get("caravan_coins_out", 0)) + int(w.stats.get("scenario_coins_in", 0)) - int(stats0.get("scenario_coins_in", 0))
	var d := {"hosting": main.net.is_host(), "seq": last_seq, "players": players, "connected": connected, "rejected": main.net.rejected,
		"applied": main.net.applied, "host_pid": w.host_player().pid, "host_pos": [w.host_player().pos.x, w.host_player().pos.y],
		"minutes": w.minutes, "seed": w.seed, "plants": plants, "coin_leak": w.total_coins() - coins0 - c_in}
	var tmp := dir + "status.tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(dir + "status.json"))
