class_name NetSession
extends Node
## Multiplayer Batch A2 (docs/multiplayer/BATCH_A.md; carried forward from the MP-01 prototype d18d7d1 onto Batch A1): one
## node, named "NetSession" under the game's main node on every machine, so the same RPCs exist on the host and the guests.
## LAN and loopback only, over ENet (no relay, no paid service, no new dependency).
##
## Authority: the host's World is the only simulation, holding every player character in World.players by permanent pid
## (the host's first). A guest is a full PlayerState there, made a newcomer on its first visit (MP-D7) and found again by its
## identity on the next. A guest's machine builds its copy of the world from what the host sends when it joins (the save,
## with its own character in full and the other players' public looks only), shows it from its own character's side
## (World.set_local_player) and never simulates it: the other players, nearby villagers and the clock arrive as snapshots.
##   - movement: the guest walks locally (immediate) and sends its position MOVE_HZ times a second; the host accepts a
##     step no longer than the walking speed allows onto open ground, else sends the guest back (s_correct);
##   - actions (`request`): queued on arrival and applied by the host at one fixed point of its frame (apply_requests,
##     before World.update), in arrival order, each by NetActions as that guest (World.as_actor): the same World verbs as
##     the host's own; the answer carries the guest's character as the host has it and the world records changed.
## Identity: a guest sends its device key; the host keeps only the key's hash, on the guest's character
## (PlayerState.net_key), saved with the world. The same key returns the same character; a key already playing is refused
## (no duplicate characters). A guest who leaves goes out of active play (PlayerState.away, MP-D1): every record stays.
## Peer ids are only for the current connection.

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
const LOOKS := ["res://assets/characters/player_02.png", "res://assets/characters/player_03.png", "res://assets/characters/player_00.png", "res://assets/characters/player_01.png"]
const NPCS_PER_PACKET := 16          # villagers per snapshot packet (under 1 KB: ENet warns above its 1392-byte MTU)
const ANIMS := ["idle", "walk", "sword", "swing", "gather", "work"]

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
var by_peer := {}                   # peer id -> pid (connected guests)
var moves := {}                     # peer id -> {t (ms), dir, anim}: the last accepted move
var queue: Array = []               # requests waiting for the host's next tick: {seq, pid, peer, rid, kind, args}
var arrivals := 0                   # the arrival counter that orders `queue`
var applied := 0                    # requests applied (tests and the log)
var rejected := 0                   # moves sent back (tests and the log)
var discovery_port := NetProtocol.DISCOVERY_PORT

# guest
var my_key := ""
var my_name := ""
var my_password := ""
var my_id := 0
var my_pid := 0
var version_sent := ""              # tests: send another version to see the refusal
var avatars := {}                   # every other player: pid -> {pid, name, sprite, pos, dir, anim, alive}
var npc_target := {}                # npc id -> the last position the host sent (the view eases toward it)
var refusal := ""                   # the last refusal's code
var replies := {}                   # request id -> the host's answer
var _next_request := 1

var _t_players := 0.0
var _t_npcs := 0.0
var _t_move := 0.0
var _t_self := 0.0


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


## True while guests are connected to this host (the shared world must not stop for one player's menu, MP-D3).
func has_guests() -> bool:
	return is_host() and not by_peer.is_empty()


# ---------------------------------------------------------------- hosting --------------------
## Open the current world to other players. "" when hosting, else why not.
func host(opts: Dictionary) -> String:
	stop()
	port = int(opts.get("port", NetProtocol.GAME_PORT))
	discovery_port = int(opts.get("discovery_port", NetProtocol.DISCOVERY_PORT))
	max_players = clampi(int(opts.get("max_players", 2)), 2, NetProtocol.MAX_PLAYERS)
	password = str(opts.get("password", ""))
	host_name = str(opts.get("host_name", main.world.host_player().name))
	world_name = str(opts.get("world_name", "%s's village" % main.world.host_player().family))
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
	changed.emit("Hosting %s. Friends on the same network can join it." % world_name)
	return ""


func _answer() -> Dictionary:
	return {"name": host_name, "world": world_name, "players": 1 + by_peer.size(), "max": max_players,
		"port": port, "version": NetProtocol.full_version(), "locked": password != ""}


## End the session: guests are told the host left (their characters go out of play); the host's world carries on alone.
func stop() -> void:
	if is_host() and main != null and main.world != null:
		for id in by_peer:
			var g: PlayerState = main.world.player_by_pid(int(by_peer[id]))
			if g != null:
				g.away = true
	if peer != null:
		peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	discovery.close()
	role = ""
	by_peer.clear()
	moves.clear()
	queue.clear()
	avatars.clear()
	npc_target.clear()
	DisplayServer.screen_set_keep_on(false)
	players_changed.emit()


func _on_peer_connected(id: int) -> void:
	if is_host():
		rpc_id(id, "s_challenge", salt)


func _on_peer_disconnected(id: int) -> void:
	if not is_host() or not by_peer.has(id):
		return
	var g: PlayerState = main.world.player_by_pid(int(by_peer[id]))
	by_peer.erase(id)
	moves.erase(id)
	queue = queue.filter(func(q): return int(q.peer) != id)        # a request from someone gone is not applied
	discovery.info = _answer()
	if g != null:
		g.away = true                              # MP-D1: out of active play, every record kept
		changed.emit("%s left the world." % g.name)
		main.save_game(false)
	players_changed.emit()


## The guest character with this identity hash, null for none (a guest of an earlier visit, here or in the save).
func guest_by_key(kh: String) -> PlayerState:
	for p: PlayerState in main.world.player_list():
		if p.net_key == kh and not main.world.is_host(p):
			return p
	return null


## Whether a guest with this key hash and name may come in now: "" or a refusal code.
func admit(kh: String, version: String, pw_hash: String, who: String) -> String:
	if version != NetProtocol.full_version():
		return "version"
	if NetProtocol.password_hash(password, salt) != pw_hash:
		return "password"
	if who.strip_edges() == "":
		return "name"
	var known := guest_by_key(kh)
	if known != null and by_peer.values().has(known.pid):
		return "duplicate"
	if 1 + by_peer.size() >= max_players:
		return "full"
	if main.world == null or not main.running:
		return "busy"
	return ""


## The guest's character: theirs from an earlier visit (back in play where they left), or a newcomer (MP-D7) beside the
## host: a permanent pid of the band (Identity.register_player), the starting kit, nobody's opinion yet.
func guest_state(kh: String, who: String) -> PlayerState:
	var w: World = main.world
	var known := guest_by_key(kh)
	if known != null:
		known.away = false
		return known
	var p := PlayerState.new()
	p.name = who.strip_edges().left(16)
	p.family = ""
	p.sprite = LOOKS[kh.hex_decode()[0] % LOOKS.size()]
	p.heir_sprite = p.sprite
	p.born = w.host_player().born
	p.pos = spawn_near(w.host_player().pos)
	p.net_key = kh
	w.give_start_kit(p)
	w.stat("newcomer_coins_in", p.coins)          # a newcomer's purse and kit come in from outside, as a villager newcomer's
	for id in p.inv.items:
		w.stat("imported_" + str(id), float(p.inv.count(str(id))))
	Identity.register_player(w, p)
	w.add_guest(p)
	return p


## A free cell next to `at` for a newcomer to stand on.
func spawn_near(at: Vector2) -> Vector2:
	var w: World = main.world
	for r in range(1, 6):
		for off in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r), Vector2i(r, r), Vector2i(-r, r)]:
			var c: Vector2i = Vector2i(floori(at.x), floori(at.y)) + off
			if not w.map.is_solid_world(c):
				return Vector2(c) + Vector2(0.5, 0.5)
	return at


## A player as the others may see them: looks, name, place; no pack, purse, skills, crimes or identity.
static func public_player(p: PlayerState) -> Dictionary:
	var o := PlayerState.new()
	o.pid = p.pid
	o.name = p.name
	o.family = p.family
	o.sprite = p.sprite
	o.heir_sprite = p.heir_sprite
	o.appearance = p.appearance.duplicate(true)
	o.sex = p.sex
	o.born = p.born
	o.pos = p.pos
	o.alive = p.alive
	o.map_level = p.map_level
	o.away = p.away
	return o.to_dict()


## The world as this guest may see it: the save, with the guest's own character in full and every other player's public
## record only (no one else's pack, purse, crimes or identity hash).
func world_for(pid: int) -> PackedByteArray:
	var w: World = main.world
	var d: Dictionary = w.to_dict()
	d["player"] = public_player(w.host_player())
	var by := {}
	for p: PlayerState in w.player_list():
		by[str(p.pid)] = p.to_dict() if p.pid == pid else public_player(p)
	d["players"] = {"host": w.host_player().pid, "by_pid": by}
	d["net_pid"] = pid
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
	_lost("Could not reach that game. Check that both devices are on the same network.")


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
		get_tree().create_timer(0.5).timeout.connect(func(): if peer != null and multiplayer.get_peers().has(id): peer.disconnect_peer(id))
		return
	var p := guest_state(kh, who)
	by_peer[id] = p.pid
	moves[id] = {"t": Time.get_ticks_msec(), "dir": Vector2.DOWN, "anim": "idle"}
	discovery.info = _answer()
	rpc_id(id, "s_welcome", world_for(p.pid), id)
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
	if typeof(d) != TYPE_DICTIONARY or int(d.get("net_pid", 0)) <= 0:
		_lost("The world could not be received. Try joining again.")
		return
	my_pid = int(d.net_pid)
	if not main.start_guest_world(d, my_pid):
		_lost("The world could not be shown. Try joining again.")
		return
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
	var p: PlayerState = main.world.player_by_pid(int(by_peer[id]))
	if p == null or not p.alive:
		return
	var now := Time.get_ticks_msec()
	var dt := maxf(1.0 / NetProtocol.MOVE_HZ, float(now - int(moves[id].t)) / 1000.0)
	var most := float(GameData.b("player_tiles_per_second")) * float(GameData.b("sprint_speed")) * dt * 1.5 + 0.25
	if not move_ok(p, pos, most):
		rejected += 1
		rpc_id(id, "s_correct", p.pos)
		return
	p.pos = pos
	moves[id] = {"t": now, "dir": dir, "anim": anim if anim in ANIMS else "idle"}


## Whether player `p` may step to `to`: no farther than `most`, onto ground open on its own level (World.solid_for_player).
func move_ok(p: PlayerState, to: Vector2, most: float) -> bool:
	if not is_finite(to.x) or not is_finite(to.y) or p.pos.distance_to(to) > most:
		return false
	if p.pos.distance_to(to) < 0.01:
		return true
	return not main.world.solid_for_player(Vector2i(floori(to.x), floori(to.y)), p)


@rpc("authority", "call_remote", "reliable")
func s_correct(pos: Vector2) -> void:
	if main.world != null:
		main.world.player.pos = pos


# ---------------------------------------------------------------- RPCs: snapshots ------------
@rpc("authority", "call_remote", "unreliable_ordered")
func s_players(list: Array) -> void:
	var seen := {}
	for e in list:
		var pid := int(e.pid)
		if pid == my_pid:
			continue
		seen[pid] = true
		if not avatars.has(pid):
			avatars[pid] = {"pos": e.pos}
		avatars[pid].merge(e, true)
		var o: PlayerState = main.world.player_by_pid(pid) if main.world != null else null
		if o != null:
			o.pos = e.pos                         # the guest's copy of the other players follows the host
			o.alive = bool(e.alive)
	for pid in avatars.keys():
		if not seen.has(pid):
			avatars.erase(pid)
	players_changed.emit()


@rpc("authority", "call_remote", "reliable")
func s_self(d: Dictionary) -> void:
	if main.world != null and main.guest_world and int(d.get("pid", 0)) == my_pid:
		main.adopt_own_state(d)


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
## Guest: ask the host to do something; the answer lands in `replies[id]` (and the guest's character is updated from it).
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
	arrivals += 1
	queue.append({"seq": arrivals, "pid": int(by_peer[id]), "peer": id, "rid": rid, "kind": kind, "args": args})


## Host: apply every queued request, in arrival order (then pid), each once, as its player, and answer it. Called at one
## fixed point of the host's frame (Main._process, before World.update), so a recorded session replays the same way.
func apply_requests() -> void:
	if queue.is_empty():
		return
	var todo := queue
	queue = []
	todo.sort_custom(func(a, b): return [int(a.seq), int(a.pid)] < [int(b.seq), int(b.pid)])
	for q in todo:
		var p: PlayerState = main.world.player_by_pid(int(q.pid))
		var r := NetActions.apply(main.world, p, str(q.kind), q.args if q.args is Dictionary else {})
		applied += 1
		if peer != null and by_peer.has(int(q.peer)):
			rpc_id(int(q.peer), "s_reply", int(q.rid), r)


@rpc("authority", "call_remote", "reliable")
func s_reply(rid: int, r: Dictionary) -> void:
	replies[rid] = r
	if main.world != null and main.guest_world:
		var mine: Dictionary = r.get("player", {})
		if not mine.is_empty() and int(mine.get("pid", 0)) == my_pid:
			main.adopt_own_state(mine)            # the host's record of this player is the truth
		for patch in r.get("patches", []):
			NetActions.apply_patch(main.world, patch)
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
	_t_self += dt
	if _t_self >= 1.0 / NetProtocol.SELF_HZ:
		_t_self = 0.0
		for id in by_peer:                         # each guest's own character as the host has it (needs, pack, purse)
			var me: PlayerState = main.world.player_by_pid(int(by_peer[id]))
			if me != null:
				rpc_id(id, "s_self", me.to_dict())
	_t_npcs += dt
	if _t_npcs >= 1.0 / NetProtocol.NPCS_HZ:
		_t_npcs = 0.0
		for id in by_peer:
			var g: PlayerState = main.world.player_by_pid(int(by_peer[id]))
			if g == null:
				continue
			var list := []
			for n: NPC in main.world.npcs:
				if n.pos.distance_to(g.pos) <= NetProtocol.NPC_RANGE:
					list.append([n.id, n.pos.x, n.pos.y, n.facing.x, n.facing.y, n.anim, n.alive])
			for i in range(0, maxi(1, list.size()), NPCS_PER_PACKET):      # unreliable packets stay under the MTU
				rpc_id(id, "s_npcs", main.world.minutes, list.slice(i, i + NPCS_PER_PACKET))


## Every player in active play as the others see them, by pid: names, looks, place, facing and animation only.
func players_list() -> Array:
	var w: World = main.world
	var h: PlayerState = w.host_player()
	var out := [{"pid": h.pid, "name": h.name, "sprite": h.sprite, "pos": h.pos, "dir": main.facing_vec(), "anim": main.player_sprite.anim, "alive": h.alive}]
	for id in by_peer:
		var g: PlayerState = w.player_by_pid(int(by_peer[id]))
		if g != null:
			out.append({"pid": g.pid, "name": g.name, "sprite": g.sprite, "pos": g.pos, "dir": moves[id].dir, "anim": moves[id].anim, "alive": g.alive})
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


## The other players to draw: pid -> {pid, name, sprite, pos, dir, anim, alive}. On the host, the connected guests.
func others() -> Dictionary:
	if is_guest():
		return avatars
	var out := {}
	if is_host():
		for e in players_list().slice(1):
			out[int(e.pid)] = e
	return out


## Connected players' names, the host first.
func player_names() -> Array:
	if is_host():
		var out := [main.world.host_player().name + " (host)"]
		for id in by_peer:
			var g: PlayerState = main.world.player_by_pid(int(by_peer[id]))
			if g != null:
				out.append(g.name)
		return out
	var out2 := [my_name + " (you)"]
	for pid in avatars:
		out2.append(str(avatars[pid].name))
	return out2


## Bytes sent and received by this machine since the last call (ENet statistics), for the measurements.
func traffic() -> Vector2i:
	if peer == null or peer.host == null:
		return Vector2i.ZERO
	return Vector2i(peer.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA), peer.host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA))
