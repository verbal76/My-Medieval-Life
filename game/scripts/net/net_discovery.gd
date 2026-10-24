class_name NetDiscovery
extends RefCounted
## Multiplayer A2 (from the MP-01 prototype, unchanged in behaviour): LAN discovery over UDP. A guest looking for games sends a small query (NetProtocol.DISCOVER)
## to the local network's broadcast address (and any addresses it is given, e.g. 127.0.0.1 in tests)
## once a second; every host listening on NetProtocol.DISCOVERY_PORT answers that guest directly with
## {name, world, players, max, port, version, locked}. A host answers only these questions and never
## says who is playing. Broadcasts can be blocked by a router, a phone hotspot or "client isolation";
## then a guest joins by the host's address (docs/multiplayer/BATCH_A.md).

var udp := PacketPeerUDP.new()
var hosting := false
var info := {}                 # host: what it answers with
var found := {}                # guest: "ip:port" -> {ip, port, name, world, players, max, version, locked, seen}
var extra: Array = []          # guest: addresses asked besides the broadcast one
var ask_every := 1.0
var _t := 0.0
var _clock := 0.0


## Host: listen for questions. Returns OK or an error.
func host(answer: Dictionary, port := NetProtocol.DISCOVERY_PORT) -> int:
	close()
	hosting = true
	info = answer
	return udp.bind(port)


## Guest: start asking. Answers arrive on an ephemeral port.
func look(addresses: Array = [], port := NetProtocol.DISCOVERY_PORT) -> int:
	close()
	hosting = false
	extra = addresses
	found = {}
	udp.set_broadcast_enabled(true)
	var err := udp.bind(0)
	_ask(port)
	return err


func close() -> void:
	udp.close()
	udp = PacketPeerUDP.new()


## Call every frame.
func poll(dt: float, port := NetProtocol.DISCOVERY_PORT) -> void:
	_clock += dt
	if not udp.is_bound():
		return
	if hosting:
		while udp.get_available_packet_count() > 0:
			var q := udp.get_packet().get_string_from_utf8()
			if q != NetProtocol.DISCOVER:
				continue
			udp.set_dest_address(udp.get_packet_ip(), udp.get_packet_port())
			udp.put_packet(JSON.stringify(info).to_utf8_buffer())
		return
	while udp.get_available_packet_count() > 0:
		var pkt := udp.get_packet()
		var ip := udp.get_packet_ip()
		var d = JSON.parse_string(pkt.get_string_from_utf8())
		if typeof(d) != TYPE_DICTIONARY or not d.has("port"):
			continue
		d["ip"] = ip
		d["seen"] = _clock
		found["%s:%d" % [ip, int(d.port)]] = d
	for k in found.keys():                   # a host not heard from for 4 s has gone
		if _clock - float(found[k].seen) > 4.0:
			found.erase(k)
	_t += dt
	if _t >= ask_every:
		_t = 0.0
		_ask(port)


func _ask(port: int) -> void:
	for ip in ["255.255.255.255"] + extra:
		udp.set_dest_address(ip, port)
		udp.put_packet(NetProtocol.DISCOVER.to_utf8_buffer())


## Build 21: this device's addresses on the local network that a friend can type to join (IPv4, not loopback or link-local),
## private-network ones first (home Wi-Fi: 192.168.x.x, 10.x.x.x, 172.16-31.x.x).
static func lan_addresses() -> Array:
	var private := []
	var other := []
	for a: String in IP.get_local_addresses():
		if not a.is_valid_ip_address() or a.contains(":") or a.begins_with("127.") or a.begins_with("169.254.") or a == "0.0.0.0":
			continue
		var p := a.split(".")
		var is_private := a.begins_with("192.168.") or a.begins_with("10.") or (p[0] == "172" and int(p[1]) >= 16 and int(p[1]) <= 31)
		(private if is_private else other).append(a)
	private.sort()
	other.sort()
	return private + other


## The games found, sorted by name then address (a stable list for the menu).
func games() -> Array:
	var out := found.values()
	out.sort_custom(func(a, b): return [str(a.name), str(a.ip)] < [str(b.name), str(b.ip)])
	return out
