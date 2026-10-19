class_name NetSession
extends Node
## MP-01 player-hosted multiplayer (docs/MULTIPLAYER.md): one node, named "NetSession" under the game's
## main node on every machine, so the same RPCs exist on the host and the guests.
##
## Authority: the host's World is the only simulation. A guest builds its view of the world from what the
## host sends when it joins (the world as saved, with the guest's own character in it and nobody else's
## private state), then never simulates it: villagers near the guest, the clock and the other players
## arrive as snapshots, and the guest sends requests that the host checks and answers:
##   - movement: the guest moves its character locally (so walking feels immediate) and sends its position
##     MOVE_HZ times a second; the host accepts a step no longer than the walking speed allows onto open
##     ground, and otherwise sends the guest back to the last accepted position (s_correct);
##   - actions (`request`): the host validates against its own world, applies the outcome once, and
##     answers the asking guest; two players asking for the same thing are served in arrival order, so
##     the second finds it gone (the shared-interaction pattern, docs/MULTIPLAYER.md section 6).
## Identity: a guest sends its device key; the host keeps the key's hash with the guest's character in
## World.guests and saves it with the world. The same key returns the same character; a key already
## playing is refused (no duplicate characters). Peer ids are only for the current connection.

signal changed(text: String)        # something the player should be told (joins, refusals, losses)
signal players_changed

const REFUSALS := {
	"version": "That game runs a different version of My Medieval Life. Both players need the same version.",
	"password": "Wrong password.",
	"full": "That world is full.",
	"duplicate": "You are already playing in that world (from this device or with the same identity).",
	"name": "Please give your character a name.",
	"busy": "The host is not ready to take players yet.",
}

var main                            # the game's main node (main.gd)
var role := ""                      # "", "host" or "guest"
var peer: ENetMultiplayerPeer
var discovery := NetDiscovery.new()
var port := NetProtocol.GAME_PORT

# host
var max_players := 2
var password := ""
var salt := ""
var host_name := ""
var world_name := ""
var by_peer := {}                   # peer id -> key hash (connected guests)
var moves := {}                     # peer id -> {t (ms), dir, anim}: the last accepted move
var rejected := 0                   # moves sent back (tests and the log)
var discovery_port := NetProtocol.DISCOVERY_PORT

# guest
var my_key := ""
var my_name := ""
var my_password := ""
var my_id := 0
var version_sent := ""              # tests: send another version to see the refusal
var avatars := {}                   # every other player: id -> {name, sprite, pos, dir, anim, alive}
var npc_target := {}                # npc id -> the last position the host sent (the view eases toward it)
var refusal := ""                   # the last refusal's code
var replies := {}                   # request id -> the host's answer
var _next_request := 1

var _t_players := 0.0
var _t_npcs := 0.0
var _t_move := 0.0


func _ready() -> void:
	name = "NetSession"
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)


func is_host() -> bool:
	return role == "host"


func is_guest() -> bool:
	return role == "guest"


# ---------------------------------------------------------------- hosting --------------------
## Open the current world to other players. "" when hosting, else why not.
func host(opts: Dictionary) -> String:
	stop()
	port = int(opts.get("port", NetProtocol.GAME_PORT))
	discovery_port = int(opts.get("discovery_port", NetProtocol.DISCOVERY_PORT))
	max_players = clampi(int(opts.get("max_players", 2)), 2, NetProtocol.MAX_PLAYERS)
	password = str(opts.get("password", ""))
	host_name = str(opts.get("host_name", main.world.player.name))
	world_name = str(opts.get("world_name", "%s's village" % main.world.player.family))
	salt = Crypto.new().generate_random_bytes(8).hex_encode()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, NetProtocol.MAX_PLAYERS + 2)       # room beyond the limit, so a player over it is told "full", not left waiting
	if err != OK:
		peer = null
		return "Could not open the game to others (port %d is in use or blocked)." % port
	multiplayer.multiplayer_peer = peer
	role = "host"
	discovery.host(_answer(), discovery_port)
	DisplayServer.screen_set_keep_on(true)        # a sleeping host stops the world for everyone
	changed.emit("Hosting %s. Friends on the same network can join from Join Nearby Game." % world_name)
	return ""


func _answer() -> Dictionary:
	return {"name": host_name, "world": world_name, "players": 1 + by_peer.size(), "max": max_players,
		"port": port, "version": NetProtocol.full_version(), "locked": password != ""}


## End the session: guests are told the host left; the host's world carries on alone.
func stop() -> void:
	if peer != null:
		peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	discovery.close()
	role = ""
	by_peer.clear()
	moves.clear()
	avatars.clear()
	npc_target.clear()
	DisplayServer.screen_set_keep_on(false)
	players_changed.emit()


func _on_peer_connected(id: int) -> void:
	if is_host():
		rpc_id(id, "s_challenge", salt)


func _on_peer_disconnected(id: int) -> void:
	if not is_host():
		return
	var kh: String = by_peer.get(id, "")
	by_peer.erase(id)
	moves.erase(id)
	discovery.info = _answer()
	if kh != "" and main.world.guests.has(kh):
		changed.emit("%s left the world." % main.world.guests[kh].name)
		main.save_game(false)                      # their character is kept where they stood
	players_changed.emit()


## Whether a guest with this key hash and name may come in now: "" or a refusal code.
func admit(kh: String, version: String, pw_hash: String, who: String) -> String:
	if version != NetProtocol.full_version():
		return "version"
	if NetProtocol.password_hash(password, salt) != pw_hash:
		return "password"
	if who.strip_edges() == "":
		return "name"
	if by_peer.values().has(kh):
		return "duplicate"
	if 1 + by_peer.size() >= max_players:
		return "full"
	if main.world == null or not main.running:
		return "busy"
	return ""


## The guest's character: theirs from an earlier visit, or a newcomer by the host's player.
func guest_state(kh: String, who: String) -> PlayerState:
	var w: World = main.world
	if w.guests.has(kh):
		return w.guests[kh].state
	var p := PlayerState.new()
	p.name = who.strip_edges().left(16)
	p.family = ""
	var looks := ["res://assets/characters/player_02.png", "res://assets/characters/player_03.png", "res://assets/characters/player_00.png", "res://assets/characters/player_01.png"]
	p.sprite = looks[kh.hex_decode()[0] % looks.size()]
	p.heir_sprite = p.sprite
	p.born = w.player.born
	p.pos = spawn_near(w.player.pos)
	w.give_start_kit(p)
	w.guests[kh] = {"name": p.name, "state": p}
	return p


## A free cell next to `at` for a newcomer to stand on.
func spawn_near(at: Vector2) -> Vector2:
	var m: VillageMap = main.world.map
	for r in range(1, 6):
		for off in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r), Vector2i(r, r), Vector2i(-r, r)]:
			var c: Vector2i = Vector2i(floori(at.x), floori(at.y)) + off
			if not m.is_solid_world(c):
				return Vector2(c) + Vector2(0.5, 0.5)
	return at


## The world as this guest may see it: the save, with the guest's own character as the player and no
## other player's private state (the host's character, other guests, identity hashes).
func world_for(kh: String) -> PackedByteArray:
	var d: Dictionary = main.world.to_dict()
	d["player"] = (main.world.guests[kh].state as PlayerState).to_dict()
	d.erase("guests")
	var raw := JSON.stringify(d).to_utf8_buffer()
	return raw.compress(FileAccess.COMPRESSION_GZIP)


# ---------------------------------------------------------------- joining --------------------
## Join the game at `ip`. The answer comes later as `changed` (and `refusal` on a refusal).
func join(ip: String, game_port: int, key: String, who: String, pw := "") -> String:
	stop()
	my_key = key
	my_name = who
	my_password = pw
	refusal = ""
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, game_port)
	if err != OK:
		peer = null
		return "Could not start joining (%s)." % error_string(err)
	multiplayer.multiplayer_peer = peer
	role = "guest"
	changed.emit("Joining world...")
	return ""


func _on_connected() -> void:
	my_id = multiplayer.get_unique_id()


func _on_failed() -> void:
	_lost("Could not reach that game. Check that both devices are on the same Wi-Fi network.")


func _on_server_gone() -> void:
	_lost("Host disconnected. The world has stopped until the host plays again.")


func _lost(text: String) -> void:
	var was_in: bool = is_guest() and main.guest_world
	stop()
	changed.emit(text)
	if was_in:
		main.leave_guest_world(text)


## Guest: leave the host's world.
func leave() -> void:
	stop()


# ---------------------------------------------------------------- RPCs: handshake ------------
@rpc("authority", "call_remote", "reliable")
func s_challenge(host_salt: String) -> void:
	var v := version_sent if version_sent != "" else NetProtocol.full_version()
	rpc_id(1, "c_hello", v, my_key, my_name, NetProtocol.password_hash(my_password, host_salt))


@rpc("any_peer", "call_remote", "reliable")
func c_hello(version: String, key: String, who: String, pw_hash: String) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	var kh := NetProtocol.key_hash(key) if key.length() == 32 else ""
	var why := admit(kh, version, pw_hash, who) if kh != "" else "version"
	if why != "":
		rpc_id(id, "s_refuse", why)
		get_tree().create_timer(0.5).timeout.connect(func(): if peer != null: peer.disconnect_peer(id))
		return
	var p := guest_state(kh, who)
	by_peer[id] = kh
	moves[id] = {"t": Time.get_ticks_msec(), "dir": Vector2.DOWN, "anim": "idle"}
	discovery.info = _answer()
	rpc_id(id, "s_welcome", world_for(kh), id)
	changed.emit("%s joined the world." % p.name)
	main.save_game(false)
	players_changed.emit()


@rpc("authority", "call_remote", "reliable")
func s_refuse(code: String) -> void:
	refusal = code
	var text: String = REFUSALS.get(code, "The host refused the connection.")
	stop()
	changed.emit(text)


@rpc("authority", "call_remote", "reliable")
func s_welcome(blob: PackedByteArray, id: int) -> void:
	my_id = id
	var d = JSON.parse_string(blob.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	if typeof(d) != TYPE_DICTIONARY:
		_lost("The world could not be received. Try joining again.")
		return
	main.start_guest_world(d)
	changed.emit("Joined %s." % str(d.get("world_name", "the world")))
	players_changed.emit()


# ---------------------------------------------------------------- RPCs: movement -------------
@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_move(pos: Vector2, dir: Vector2, anim: String) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if not by_peer.has(id):
		return
	var p: PlayerState = main.world.guests[by_peer[id]].state
	var now := Time.get_ticks_msec()
	var dt := maxf(1.0 / NetProtocol.MOVE_HZ, float(now - int(moves[id].t)) / 1000.0)
	var most := float(GameData.b("player_tiles_per_second")) * float(GameData.b("sprint_speed")) * dt * 1.5 + 0.25
	if not move_ok(p.pos, pos, most):
		rejected += 1
		rpc_id(id, "s_correct", p.pos)
		return
	p.pos = pos
	moves[id] = {"t": now, "dir": dir, "anim": anim if anim in ["idle", "walk", "sword", "swing", "gather"] else "idle"}


## Whether a guest's step from `from` to `to` is allowed: no farther than `most` and onto open ground.
func move_ok(from: Vector2, to: Vector2, most: float) -> bool:
	if not is_finite(to.x) or not is_finite(to.y) or from.distance_to(to) > most:
		return false
	return not main.world.map.is_solid_world(Vector2i(floori(to.x), floori(to.y))) or from.distance_to(to) < 0.01


@rpc("authority", "call_remote", "reliable")
func s_correct(pos: Vector2) -> void:
	if main.world != null:
		main.world.player.pos = pos


# ---------------------------------------------------------------- RPCs: snapshots ------------
@rpc("authority", "call_remote", "unreliable_ordered")
func s_players(list: Array) -> void:
	var seen := {}
	for e in list:
		var id := int(e.id)
		if id == my_id:
			continue
		seen[id] = true
		if not avatars.has(id):
			avatars[id] = {"pos": e.pos}
		avatars[id].merge(e, true)
	for id in avatars.keys():
		if not seen.has(id):
			avatars.erase(id)
	players_changed.emit()


@rpc("authority", "call_remote", "unreliable_ordered")
func s_npcs(minutes: float, list: Array) -> void:
	if main.world == null:
		return
	main.world.minutes = maxf(main.world.minutes, minutes)
	for e in list:
		var n: NPC = main.world.npc(int(e[0]))
		if n == null:
			continue
		npc_target[n.id] = Vector2(e[1], e[2])
		n.facing = Vector2(e[3], e[4])
		n.anim = str(e[5])
		n.alive = bool(e[6])


# ---------------------------------------------------------------- RPCs: actions --------------
## Guest: ask the host to do something with the shared world; the answer lands in `replies[id]`.
func request(kind: String, args: Dictionary) -> int:
	var rid := _next_request
	_next_request += 1
	rpc_id(1, "c_request", rid, kind, args)
	return rid


@rpc("any_peer", "call_remote", "reliable")
func c_request(rid: int, kind: String, args: Dictionary) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if not by_peer.has(id):
		return
	var p: PlayerState = main.world.guests[by_peer[id]].state
	var r := NetActions.apply(main.world, p, kind, args)
	rpc_id(id, "s_reply", rid, r)


@rpc("authority", "call_remote", "reliable")
func s_reply(rid: int, r: Dictionary) -> void:
	replies[rid] = r
	if main.world != null and r.get("ok", false):
		for id in r.get("gained", {}):
			main.world.player.inv.add(id, int(r.gained[id]))
	if str(r.get("text", "")) != "":
		changed.emit(str(r.text))


# ---------------------------------------------------------------- every frame ----------------
func _process(dt: float) -> void:
	if role == "":
		if discovery.udp.is_bound():
			discovery.poll(dt, discovery_port)
		return
	discovery.poll(dt, discovery_port)
	if is_host():
		_host_step(dt)
	elif is_guest() and main.guest_world:
		_guest_step(dt)


func _host_step(dt: float) -> void:
	if by_peer.is_empty():
		return
	_t_players += dt
	if _t_players >= 1.0 / NetProtocol.PLAYERS_HZ:
		_t_players = 0.0
		rpc("s_players", players_list())
	_t_npcs += dt
	if _t_npcs >= 1.0 / NetProtocol.NPCS_HZ:
		_t_npcs = 0.0
		for id in by_peer:
			var at: Vector2 = (main.world.guests[by_peer[id]].state as PlayerState).pos
			var list := []
			for n: NPC in main.world.npcs:
				if n.pos.distance_to(at) <= NetProtocol.NPC_RANGE:
					list.append([n.id, n.pos.x, n.pos.y, n.facing.x, n.facing.y, n.anim, n.alive])
			rpc_id(id, "s_npcs", main.world.minutes, list)


## Every player as the others see them: the host is id 1, guests their peer ids. Names and looks only.
func players_list() -> Array:
	var p: PlayerState = main.world.player
	var out := [{"id": 1, "name": p.name, "sprite": p.sprite, "pos": p.pos, "dir": main.facing_vec(), "anim": main.player_sprite.anim, "alive": p.alive}]
	for id in by_peer:
		var g: PlayerState = main.world.guests[by_peer[id]].state
		out.append({"id": id, "name": g.name, "sprite": g.sprite, "pos": g.pos, "dir": moves[id].dir, "anim": moves[id].anim, "alive": g.alive})
	return out


func _guest_step(dt: float) -> void:
	_t_move += dt
	if _t_move >= 1.0 / NetProtocol.MOVE_HZ:
		_t_move = 0.0
		rpc_id(1, "c_move", main.world.player.pos, main.facing_vec(), main.player_sprite.anim)
	var k := minf(1.0, dt * 8.0)
	for id in npc_target:
		var n: NPC = main.world.npc(id)
		if n != null:
			n.pos = n.pos.lerp(npc_target[id], k) if n.pos.distance_to(npc_target[id]) < 3.0 else npc_target[id]


## The other players to draw: id -> {name, sprite, pos, dir, anim, alive}. On the host, the connected guests.
func others() -> Dictionary:
	if is_guest():
		return avatars
	var out := {}
	if is_host():
		for e in players_list().slice(1):
			out[int(e.id)] = e
	return out


## Connected players' names, the host first (the host's player list).
func player_names() -> Array:
	if is_host():
		var out := [main.world.player.name + " (host)"]
		for id in by_peer:
			out.append(main.world.guests[by_peer[id]].name)
		return out
	var out2 := [my_name + " (you)"]
	for id in avatars:
		out2.append(str(avatars[id].name) + (" (host)" if int(id) == 1 else ""))
	return out2


## Bytes sent and received by this machine since the last call (ENet statistics), for the measurements.
func traffic() -> Vector2i:
	if peer == null or peer.host == null:
		return Vector2i.ZERO
	return Vector2i(peer.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA), peer.host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA))
