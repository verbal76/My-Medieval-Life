extends SceneTree
## Multiplayer Batch D test tool: a UDP relay on loopback that stands between a guest and the host and treats their ENet datagrams as
## a bad network would, so the real transport (ENet's own resends, ordering and timeouts) meets real faults. Run in its own process:
##   godot --headless --path game --script res://tests/net_proxy.gd -- listen_port host_port dir
## It reads <dir>proxy.json now and then: {loss, dup, reorder (0-1 chances per datagram), delay_ms, jitter_ms, blackhole (bool: nothing
## passes either way, as when a phone is suspended or its network is gone), seed}. It writes <dir>proxy_status.json:
## {up, passed, dropped, duplicated, reordered, clients}. Deterministic for a seed, apart from the operating system's timing.

var listen := PacketPeerUDP.new()
var host_port := 0
var dir := ""
var clients := {}            # "ip:port" -> {ip, port, up: PacketPeerUDP}
var later: Array = []        # {at (ms), to: "host"|"guest", key, data}
var cfg := {}
var rng := RandomNumberGenerator.new()
var stats := {"passed": 0, "dropped": 0, "duplicated": 0, "reordered": 0}
var _t := 0.0


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	host_port = int(a[1])
	dir = str(a[2])
	rng.seed = 7
	var err := listen.bind(int(a[0]), "127.0.0.1")
	_write({"up": err == OK, "error": err})
	if err != OK:
		quit(1)


func _process(delta: float) -> bool:
	_t += delta
	if _t >= 0.2:
		_t = 0.0
		_read_cfg()
		_write({"up": true})
	var now := Time.get_ticks_msec()
	while listen.get_available_packet_count() > 0:
		var data := listen.get_packet()
		var key := "%s:%d" % [listen.get_packet_ip(), listen.get_packet_port()]
		if not clients.has(key):
			var up := PacketPeerUDP.new()
			up.bind(0, "127.0.0.1")
			up.set_dest_address("127.0.0.1", host_port)
			clients[key] = {"ip": listen.get_packet_ip(), "port": listen.get_packet_port(), "up": up}
		_pass("host", key, data, now)
	for key in clients:
		var up: PacketPeerUDP = clients[key].up
		while up.get_available_packet_count() > 0:
			_pass("guest", key, up.get_packet(), now)
	var keep := []
	for e in later:
		if now >= int(e.at):
			_send(str(e.to), str(e.key), e.data)
		else:
			keep.append(e)
	later = keep
	return false


func _pass(to: String, key: String, data: PackedByteArray, now: int) -> void:
	if bool(cfg.get("blackhole", false)) or rng.randf() < float(cfg.get("loss", 0.0)):
		stats.dropped += 1
		return
	var copies := 1
	if rng.randf() < float(cfg.get("dup", 0.0)):
		copies = 2
		stats.duplicated += 1
	for _i in copies:
		var wait := int(cfg.get("delay_ms", 0)) + rng.randi_range(0, int(cfg.get("jitter_ms", 0)))
		if rng.randf() < float(cfg.get("reorder", 0.0)):
			wait += 30 + rng.randi_range(0, 60)       # held back past the next ones
			stats.reordered += 1
		if wait <= 0:
			_send(to, key, data)
		else:
			later.append({"at": now + wait, "to": to, "key": key, "data": data})


func _send(to: String, key: String, data: PackedByteArray) -> void:
	if not clients.has(key):
		return
	stats.passed += 1
	if to == "host":
		(clients[key].up as PacketPeerUDP).put_packet(data)
	else:
		listen.set_dest_address(str(clients[key].ip), int(clients[key].port))
		listen.put_packet(data)


func _read_cfg() -> void:
	var f := FileAccess.open(dir + "proxy.json", FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	if int(d.get("seed", 7)) != int(cfg.get("seed", 7)):
		rng.seed = int(d.get("seed", 7))
	cfg = d
	if str(d.get("quit", "")) == "yes":
		quit(0)


func _write(extra: Dictionary) -> void:
	var d := stats.duplicate()
	d.merge(extra)
	d["clients"] = clients.size()
	d["cfg"] = cfg
	var tmp := dir + "proxy_status.tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(dir + "proxy_status.json"))
