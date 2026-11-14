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
##
## Batch D (docs/multiplayer/BATCH_D_CONNECTIVITY.md): joining by an invite code (NetInvite: the host's addresses that can work, tried
## in order, each with its own time limit) or a typed address; the router asked to forward the port (NetUpnp, on a thread); ENet
## timeouts of 4-10 s; a guest whose connection drops keeps its view and reconnects by itself (RECONNECT_SECONDS, longer while the
## host says it is paused), taking its character back with the resume token the host gave it (never saved); a host that stops says
## so (z_bye), so its guests do not retry; Android pause and resume (on_app_paused / on_app_resumed). Each guest request carries a
## number: the host applies each number once, in number order, and answers a repeated one from its record (no second purchase,
## gift or transaction); requests unanswered when a connection drops are not sent again (the world the host sends at the rejoin is
## the truth). Tests may inject faults into a guest's requests (`faults`).

signal changed(text: String)        # something the player should be told (joins, refusals, losses)
signal answered(text: String)       # the host's answer to one of this guest's requests (shown, not kept: routine feedback)
signal players_changed
signal world_synced(mark: int)       # guest (MP C): the host's sections taken into this copy (s_sync); `mark` as send_syncs gave it, else -1
signal verb_answered(rid: int, result: Variant)    # X20: the host's result of one of this guest's verbs (Main._on_verb_answered)

const REFUSALS := {
	"version": "That game runs a different version of Forge My Life. Both players need the same version.",
	"password": "Wrong password.",
	"full": "That world is full.",
	"duplicate": "You are already playing in that world (from this device or with the same identity).",
	"name": "Please give your character a name.",
	"busy": "The host is not ready to take players yet.",
}
## Batch D: what a guest is told when it cannot get in or loses the host.
const UNREACHABLE_ADDRESS := "Could not reach that game. Check the address, that both devices are on the same network, and that the host's firewall allows the game."
const UNREACHABLE_CODE := "Could not reach the host at any address in the invite code (tried: %s). If you are not on the same network, the host's router or internet provider may not let games in from outside: see Playing with friends in the help."
const OTHER_GAME := "That address leads to a different game than the invite code's. Ask the host for a new code."
const HOST_STOPPED := "The host closed the world to friends. It has stopped until they play again."
const HOST_LOST := "Lost the connection to the host. The world has stopped until the host plays again; your character waits there."
const RECONNECTING := "Connection to the host lost. Reconnecting..."
const HOST_PAUSED_WAIT := "The host's game is paused (in the background). Waiting for it to come back..."
const RECONNECT_SECONDS := 60.0      # a guest whose connection dropped tries to come back this long
const HOST_PAUSED_SECONDS := 300.0   # ... and this long when the host said it was paused (an Android host in the background)
const TIMEOUT_MIN_MS := 4000         # ENet: a peer silent this long may be dropped, and is by TIMEOUT_MAX_MS (defaults 5 and 30 s)
const TIMEOUT_MAX_MS := 10000
## B25R1: a guest that has just been welcomed builds the host's world in one long frame (main.start_guest_world: 4-5 s measured
## on a test machine with other work running, longer on a slow phone), and cannot answer the network meanwhile. Its connection is
## given this long (ENet's own default) until its first move shows it is playing; then TIMEOUT_MIN_MS/TIMEOUT_MAX_MS again.
const JOIN_TIMEOUT_MS := 30000
## ND-26: ENet alone can take up to about three times TIMEOUT_MAX_MS to find a dead connection (it checks its timeouts only when an
## unacknowledged reliable send is due again, and the wait doubles each time from a round trip that a joining guest's long frame
## inflates: 27 s measured). So each side sends the other a small reliable heartbeat (zz_tick) every BEAT_SECONDS while a guest plays,
## and a side that has heard nothing from the other for longer than TIMEOUT_MAX_MS ends that connection itself, by the same path as
## ENet's own end: the host drops the guest (MP-D1, out of active play, every record kept), the guest reconnects. A guest still
## building its world is not watched (JOIN_TIMEOUT_MS); this machine's own long frames do not count as the other side's silence.
## Never the unreliable moves: ENet's throttle can hold them back for seconds after a join.
const BEAT_SECONDS := 1.0
const OWN_GAP_MS := 1000             # a frame of this machine longer than this: its length is not counted as the other side's silence
const HOLD_SECONDS := 2.0            # host: a request numbered past a missing one waits this long for it, then goes ahead
const REPLIES_KEPT := 64             # host: answers kept per guest to answer a repeated request without applying it again
## Host stopping (B25R1): how long it waits for its guests to end their connections after its goodbye (z_bye) before it ends them
## itself, and then for those ends to be delivered. A guest ends its own connection when it reads the goodbye, so the goodbye is read
## first: a goodbye and the host's end arriving in one network read reach the guest as the end only (Godot's ENet peer closes on the
## end and drops the packets read with it), and the guest would wait to reconnect instead of going to the title.
const BYE_WAIT_SECONDS := 2.0
const BYE_CLOSE_SECONDS := 0.3
const RESUME_AFTER_PAUSE_MS := 4000  # guest: back from a pause longer than this, reconnect at once (the host may have dropped it)
const LOOKS := ["res://assets/characters/player_02.png", "res://assets/characters/player_03.png", "res://assets/characters/player_00.png", "res://assets/characters/player_01.png"]
const NPCS_PER_PACKET := 24          # villagers per snapshot packet (under 1 KB: ENet warns above its 1392-byte MTU)
## B25R1 (traffic): floats a villager takes in a snapshot (s_npcs): id, x, y, facing x and y, flags (NPC_ALIVE, NPC_FIELD,
## NPC_SWING), and the place drawn at field work (x, y; 0 when not at it). Its animation goes beside, in the packet's string list.
const NPC_FLOATS := 8
const NPC_ALIVE := 1
const NPC_FIELD := 2
const NPC_SWING := 4
## ... and the players' fields that change only now and then (a snapshot carries them when they changed, or on the key).
const PLAYER_STATIC := ["name", "sprite", "worn", "wield", "partner", "children"]
const ANIMS := ["idle", "walk", "sword", "swing", "gather", "work"]
const ANIMALS_PER_PACKET := 24       # Build 21: animals per snapshot packet (8 floats each: under the MTU, as the villagers')
const ANIMAL_ACTS := ["", "attack", "hit"]   # an animal's one-off animation, sent as its index
const ANIMALS_KEY_EVERY := 4         # every 4th animal snapshot (once a second) carries every animal near the guest, moved or not
## B25R1 (traffic): the villagers' snapshots carry only the villagers whose row changed since it was last sent to that guest, and every
## NPCS_KEY_EVERY-th one (once a second) every villager near it, so a lost packet is put right within a second (as the animals').
const NPCS_KEY_EVERY := 4
## A villager leaving a guest's range is sent where it went at once and on this many following keys (a lost packet is put right).
const LEFT_KEYS := 2
## ... and the players' list goes only when it changed, and every PLAYERS_KEY_EVERY-th tick (once a second) whatever it holds.
const PLAYERS_KEY_EVERY := 10

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
var joining := {}                   # host: peer ids welcomed and not yet moved (building the world: JOIN_TIMEOUT_MS)
var _built_frame := -1              # guest: the frame the world was built in (JOIN_TIMEOUT_MS until the network is read after it)
var heard := {}                     # host (ND-26): peer id -> when that playing guest was last heard (msec; zz_tick, zz_playing)
var _host_frame_msec := -1          # host (ND-26): when its last frame ran (its own long frame is not a guest's silence)
var _t_beat := 0.0
var watchdog_drops := 0             # host (ND-26): playing guests dropped for silence (tests, the log)
var host_heard := -1                # guest (ND-26): when the host was last heard while playing (msec), -1 when not watched
## B42-NET-MP4-STALE: whether this guest has heard the host's heartbeat since it built the world it was sent. Until it has, it waits
## for the host as long as the host waits for a joining guest (JOIN_TIMEOUT_MS), not TIMEOUT_MAX_MS: what the host sent during the
## guest's long building frame went unacknowledged, and ENet's resend waits, doubled each time, can hold the host's first heartbeat
## back for more than ten seconds after the world is built, though the host is there (net_mp4_test under load: a guest that had just
## rejoined dropped a live host, reconnected, built the world again, and could be dropped again). Once heard, TIMEOUT_MAX_MS.
var host_heard_since_join := false
var host_silent_losses := 0         # guest (ND-26): connections ended because the host was silent (tests)
var queue: Array = []               # requests waiting for the host's next tick: {seq, pid, peer, rid, kind, args}
var arrivals := 0                   # the arrival counter that orders `queue`
var applied := 0                    # requests applied (tests and the log)
var journal_kept := 0               # GP-MESSAGE-JOURNAL: guests' journal entries received (not requests; tests)
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
var field_pose := {}                # GP-FARMER-TENDING: npc id -> {pos, anim, tool, facing}: how the host draws a villager at work on a field (FieldWorkView)
var animal_target := {}             # Build 21: animal id -> the last position the host sent (the view eases toward it)
var refusal := ""                   # the last refusal's code
var replies := {}                   # request id -> the host's answer
var _next_request := 1
var level_differs := 0              # guest (B25R2-CAVE): players' lists in a row that put this player on another level than its copy
var portal_rid := 0                  # guest (B25R2-CAVE): the request of a passage through a portal (World.player_through) not yet answered
var predicted := {}                 # MP C: request id -> what this machine's own run of the verb gave (World.mirror), to tell when the host differs
var syncs := 0                      # MP C: world sections taken from the host (tests)

# host, MP C: each guest's copy of the shared world (NetSync)
var synced := {}                    # peer id -> {section: hash} last sent to it
var sync_due := {}                  # peer id -> true: send its changed sections this frame (it had a request applied)
var _t_sync := 0.0
var _n_sync := 0
var sync_bytes := 0                 # bytes of sections sent (the measurements)

# host, Build 21: each guest's copy of the animals (NetSync "fauna" for their records; these for their live state)
var fauna_known := {}               # peer id -> {animal id: true}: the animals that guest's copy holds
var fauna_sent := {}                # peer id -> {animal id: [x, y, fx, fy, moving, act, hp]}: the live state last sent to it (as floats)
var _n_animals := 0
var npcs_sent := {}                 # B25R1: peer id -> {npc id: the snapshot row last sent to it}
var left_view := {}                 # peer id -> {npc id: keys left to send it on}: villagers gone out of that guest's range
var _n_npcs := 0
var _players_sent: Array = []       # B25R1: the players' snapshot last broadcast
var _players_static := {}           # B25R1: pid -> its PLAYER_STATIC fields as last broadcast
var _players_peers: Array = []      # B25R1: the connections the last snapshot went to (a new one gets every field)
var _n_players := 0

# Batch D, host
var upnp := NetUpnp.new()
var tag := ""                       # this world's tag (NetInvite.world_tag), told to each guest before the challenge
var resume_tokens := {}             # pid -> the token its connection may come back with, this hosting session only (never saved)
var hello_extra := {}               # peer id -> {token, next}: what a guest said before its hello (z_resume)
var streams := {}                   # identity -> {next, done: {rid: answer}, order: [rid], held: {rid: queue entry}}
var duplicates := 0                 # repeated requests answered from the record, not applied again (tests, the log)
var gaps_skipped := 0               # requests applied after giving up waiting for a missing earlier number
var resumes := 0                    # connections that took their character back with the token
var applied_log: Array = []         # [pid, rid, verb] in the order applied (the last 200; tests)
# Batch D, guest
var targets: Array = []             # the addresses being tried: {ip, port, kind}
var _attempt := -1
var _attempt_until := 0.0
var tried_kinds: Array = []
var expect_tag := ""                # the invite code's world tag ("" for a typed address)
var seen_tag := ""
var resume_token := ""
var good_target := {}               # the address that worked (the one reconnecting tries)
var reconnecting := false
var reconnect_until := 0.0
var reconnect_paused := false       # the host had said it was paused when the connection dropped
var reconnect_window := 0.0         # how long the current (or last) reconnection may take (tests, the log)
var _retry_at := 0.0
var _retries := 0
var reconnects := 0                 # times this guest came back (tests)
var moves_sent := 0                 # guest: its moves sent to the host (tests)
var host_paused := false
var bye := ""                       # the host said it stopped (no retries)
var _bye_read := false              # B25R1: ... and the guest has yet to end the connection for it
var _paused_msec := -1
var _frame_msec := -1               # guest (KI-12): when its last frame ran, to see a freeze no pause notice announced
var faults := {}                    # tests: {dup: true, delay_ms: n, reorder: true} on this guest's requests
var _fault_out: Array = []
var _fault_pair: Array = []

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
	tag = NetInvite.world_tag(main.world.seed, main.world.host_player().pid)
	if bool(opts.get("upnp", false)):
		upnp.start(port)                          # Batch D: the router asked to forward the port, in the background
	else:
		upnp.state = "off"
	if main.world.recorder != null:
		main.world.recorder.net_event(self, "host_started", main.world.host_player(), "max_players=%d" % max_players)     # X20-FINAL
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
			rpc_id(int(id), "z_bye", "stopped")          # Batch D: so the guests do not wait to reconnect
		_drain()
	upnp.stop()
	_close_peer()
	discovery.close()
	role = ""
	_bye_read = false
	resume_tokens.clear()
	hello_extra.clear()
	streams.clear()
	targets = []
	_attempt = -1
	reconnecting = false
	host_paused = false
	_fault_out.clear()
	_fault_pair.clear()
	by_peer.clear()
	moves.clear()
	joining.clear()
	heard.clear()
	_host_frame_msec = -1
	host_heard = -1
	host_heard_since_join = false
	_built_frame = -1
	_frame_msec = -1
	queue.clear()
	synced.clear()
	sync_due.clear()
	fauna_known.clear()
	fauna_sent.clear()
	npcs_sent.clear()
	left_view.clear()
	_players_sent = []
	_players_static.clear()
	_players_peers = []
	predicted.clear()
	avatars.clear()
	npc_target.clear()
	animal_target.clear()
	DisplayServer.screen_set_keep_on(false)
	players_changed.emit()


## Batch D: drop the connection without telling anything (the peer object only), keeping the role and the guest's view.
func _close_peer() -> void:
	var p := peer
	peer = null
	multiplayer.multiplayer_peer = null          # first, so closing raises no signal of a lost server here
	if p != null:
		p.close()


## Batch D, host: before closing, let the packets just sent (the goodbye) reach the guests. B25R1: ENet is run (once, when hosting
## stops) until every guest has read the goodbye and ended its connection (z_bye), for up to BYE_WAIT_SECONDS; a connection still
## open then is asked to end once its queue is delivered, and ENet runs up to BYE_CLOSE_SECONDS more. (Before, the host asked at once:
## its end often reached a guest in the same read as the goodbye, which the guest then never saw, and it retried for a minute.)
func _drain() -> void:
	if peer == null or peer.host == null:
		return
	for id in multiplayer.get_peers():
		var pp := peer.get_peer(id)
		if pp != null and not by_peer.has(id):
			pp.peer_disconnect_later()                 # a connection still joining had no goodbye: ended at once
	peer.host.flush()
	var asked := false
	var start := Time.get_ticks_msec()
	var end := start + int((BYE_WAIT_SECONDS + BYE_CLOSE_SECONDS) * 1000.0)
	while Time.get_ticks_msec() < end:
		var live := []
		for id in multiplayer.get_peers():
			var pp := peer.get_peer(id)
			if pp != null and pp.get_state() != ENetPacketPeer.STATE_DISCONNECTED:
				live.append(pp)
		if live.is_empty():
			break
		if not asked and Time.get_ticks_msec() >= start + int(BYE_WAIT_SECONDS * 1000.0):
			asked = true
			for pp: ENetPacketPeer in live:
				pp.peer_disconnect_later()             # a guest that did not answer in time (frozen, or its connection lost)
		peer.host.service(10)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Batch D: whether this guest has a live connection to the host.
func connected() -> bool:
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _set_timeout(id: int, building := false) -> void:
	if peer == null:
		return
	var pp := peer.get_peer(id)
	if pp != null:
		pp.set_timeout(32, JOIN_TIMEOUT_MS if building else TIMEOUT_MIN_MS, JOIN_TIMEOUT_MS if building else TIMEOUT_MAX_MS)


func _on_peer_connected(id: int) -> void:
	if is_host():
		_set_timeout(id)
		rpc_id(id, "z_tag", tag)                    # Batch D: before the challenge (an older guest ignores it and is refused by version)
		rpc_id(id, "s_challenge", salt)


func _on_peer_disconnected(id: int) -> void:
	hello_extra.erase(id)
	if not is_host() or not by_peer.has(id):
		return
	_drop_peer(id, false)


## Host: guest connection `id` is gone (it left, timed out, or came back on a new connection, `quiet`): its character goes out of
## active play (MP-D1), every record kept, its waiting requests dropped, and the world saved.
func _drop_peer(id: int, quiet: bool) -> void:
	var g: PlayerState = main.world.player_by_pid(int(by_peer[id]))
	if main.world.recorder != null:
		main.world.recorder.net_event(self, "guest_resumed" if quiet else "guest_left", g, "peer=%d" % id)     # X20-FINAL
	if g != null and streams.has(_ident(g)):
		(streams[_ident(g)].held as Dictionary).clear()
	by_peer.erase(id)
	moves.erase(id)
	joining.erase(id)
	heard.erase(id)
	synced.erase(id)
	sync_due.erase(id)
	fauna_known.erase(id)
	fauna_sent.erase(id)
	npcs_sent.erase(id)
	left_view.erase(id)
	queue = queue.filter(func(q): return int(q.peer) != id)        # a request from someone gone is not applied
	discovery.info = _answer()
	if g != null:
		g.away = true                              # MP-D1: out of active play, every record kept
		if not quiet:
			changed.emit("%s left the world." % g.name)
			main.save_game(false)
	if quiet and peer != null and multiplayer.get_peers().has(id):
		peer.disconnect_peer(id)                   # the dead connection a guest came back from (not forced: a forced drop raises no
		                                           # peer_disconnected, so Godot's multiplayer would keep a ghost peer and fail every broadcast)
	players_changed.emit()


## Host: the identity a guest's requests are numbered under (its key's hash, which an heir carries on), else its pid.
func _ident(p: PlayerState) -> String:
	return p.net_key if p.net_key != "" else "pid:%d" % p.pid


## The guest character with this identity hash, null for none (a guest of an earlier visit, here or in the save). The line's
## living character is the one (after a death and the heir, MP-D4, the heir carries the identity); should a damaged save hold
## two characters under one identity, the lowest pid (player_list order), so the same one every time.
func guest_by_key(kh: String) -> PlayerState:
	for p: PlayerState in main.world.player_list():
		if p.net_key == kh and not main.world.is_host(p):
			return p
	return null


## Whether a guest with this key hash and name may come in now: "" or a refusal code.
## Batch D: `token`, the resume token the host gave this identity's connection earlier this session, lets a guest whose old connection
## the host still holds (not yet timed out) take its character back on the new one; without it a second copy is refused as before.
func admit(kh: String, version: String, pw_hash: String, who: String, token := "") -> String:
	if version != NetProtocol.full_version():
		return "version"
	if NetProtocol.password_hash(password, salt) != pw_hash:
		return "password"
	if who.strip_edges() == "":
		return "name"
	var known := guest_by_key(kh)
	if known != null and by_peer.values().has(known.pid) and not resumable(known, token):
		return "duplicate"
	if 1 + by_peer.size() - (1 if known != null and by_peer.values().has(known.pid) else 0) >= max_players:
		return "full"
	if main.world == null or not main.running:
		return "busy"
	return ""


## Batch D: whether `token` is the one this hosting session gave player `p`'s connection.
func resumable(p: PlayerState, token: String) -> bool:
	return p != null and token != "" and str(resume_tokens.get(p.pid, "")) == token


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
	w.as_actor(p, w.quests.start_story)           # MP C: a newcomer seeks the sage, as every new character does
	w.stat("player_newcomers")
	w.note("%s arrives in the village, a newcomer." % p.name)
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
	o.armor = p.armor                         # ARMOR-01: worn armour and headgear are seen by everyone (the look, not the pack)
	o.head = p.head
	o.weapon = p.weapon                       # WEAPON-VISIBLE-01: the weapon in hand is drawn on them too
	o.sex = p.sex
	o.born = p.born
	o.pos = p.pos
	o.alive = p.alive
	o.map_level = p.map_level
	o.away = p.away
	o.partner = p.partner                       # MP-PLAYER-FAMILY: whom they married and their children are known to all (family records)
	o.children = p.children.duplicate()
	o.mother = p.mother
	o.father = p.father
	return o.to_dict()


## X20: what of the players' private records a guest's copy receives (World.to_dict `d`, changed in place for guest `ref`; `w` the
## host's world): MML-MP-07, NetPrivacy.filter (the offers, sharing pairs and kept messages of X20 and MP-05 among them).
static func _private_for(d: Dictionary, ref: String, w: World = null) -> void:
	NetPrivacy.filter(d, ref, w)


## Host (X20, tests): the offers and messages between players that guest `ref`'s copy holds (_private_for).
static func offers_for(w: World, ref: String) -> Array:
	return w.offers.filter(func(o): return str(o["from"]) == ref or str(o.to) == ref)


## Host (MML-MP-07, tests): the world as guest `pid` is welcomed with it (world_for, before the players in play are added).
static func welcome_view(w: World, pid: int) -> Dictionary:
	var d: Dictionary = w.to_dict()
	d["player"] = public_player(w.host_player())
	var by := {}
	for p: PlayerState in w.player_list():
		by[str(p.pid)] = p.to_dict() if p.pid == pid else public_player(p)
	d["players"] = {"host": w.host_player().pid, "by_pid": by}
	d["net_pid"] = pid
	_private_for(d, w.player_ref(w.player_by_pid(pid)), w)     # MML-MP-07: nobody else's private records in the welcome
	return d


## The world as this guest may see it: the save, with the guest's own character in full and every other player's public
## record only (no one else's pack, purse, crimes or identity hash).
func world_for(pid: int) -> PackedByteArray:
	var d := welcome_view(main.world, pid)
	_welcome_digest = NetSync.digest(d)            # what this guest's copy holds from now (NetSync.changed sends the rest)
	# who is in play and where, as s_players says it: the welcome carries it (reliable), so the copy has the other players from its
	# first frame. The snapshots are unreliable and ENet's throttle drops most of them while the welcome is acknowledged (CI: a
	# rejoined guest had none for seconds and could not see or choose the host, net_interact_test "and she the host")
	d["net_players"] = players_list().map(func(e): return e.merged({"pos": [e.pos.x, e.pos.y], "dir": [e.dir.x, e.dir.y]}, true))
	var raw := JSON.stringify(d).to_utf8_buffer()
	return raw.compress(FileAccess.COMPRESSION_GZIP)


# ---------------------------------------------------------------- joining --------------------
## Join the game at `ip`. The answer comes later as `changed` (and `refusal` on a refusal).
func join(ip: String, game_port: int, key: String, who: String, pw := "") -> String:
	return join_targets([{"ip": ip, "port": game_port, "kind": "direct"}], key, who, pw)


## Batch D: join by an invite code (NetInvite.parse) or a typed address: `list` of {ip, port, kind} tried in order, each until it
## answers or its time (NetInvite.ATTEMPT_SECONDS) runs out. `world_tag` ("" for a typed address): the code's world, so an address
## that leads to another game is passed over. "" when the first attempt started, else why not.
func join_targets(list: Array, key: String, who: String, pw := "", world_tag := "") -> String:
	stop()
	my_key = key
	my_name = who
	my_password = pw
	refusal = ""
	bye = ""
	expect_tag = world_tag
	resume_token = ""
	good_target = {}
	targets = list
	_attempt = -1
	tried_kinds = []
	role = "guest"
	if not _next_target():
		role = ""
		return "Could not start joining (no address to try)."
	changed.emit("Joining world...")
	return ""


## Guest: open the next address of `targets`. False when none is left.
func _next_target() -> bool:
	_close_peer()
	while _attempt + 1 < targets.size():
		_attempt += 1
		if _open_client(targets[_attempt]):
			return true
	return false


func _open_client(t: Dictionary) -> bool:
	_close_peer()
	var p := ENetMultiplayerPeer.new()
	if p.create_client(str(t.ip), int(t.port)) != OK:
		return false
	peer = p
	multiplayer.multiplayer_peer = peer
	seen_tag = ""
	var kind := str(t.get("kind", "direct"))
	if not tried_kinds.has(kind):
		tried_kinds.append(kind)
	_attempt_until = _now() + float(NetInvite.ATTEMPT_SECONDS.get(kind, 12.0))
	return true


## Guest: the address being tried did not answer (in time, or refused the connection): the next, else the end of the attempt.
func _attempt_failed() -> void:
	if reconnecting:
		_retry_later()
		return
	if _next_target():
		return
	var only_typed: bool = tried_kinds.all(func(k): return k == "direct")
	_lost(UNREACHABLE_ADDRESS if only_typed else UNREACHABLE_CODE % ", ".join(tried_kinds.map(func(k): return _kind_words(str(k)))))


static func _kind_words(kind: String) -> String:
	return {"lan": "your network", "loopback": "this device", "v6": "IPv6", "public": "the internet", "direct": "the address"}.get(kind, kind)


func _on_connected() -> void:
	my_id = multiplayer.get_unique_id()
	_set_timeout(1)


func _on_failed() -> void:
	_attempt_failed()


func _on_server_gone() -> void:
	_lost(HOST_STOPPED if bye != "" else HOST_LOST, bye == "")


## Guest: the connection is over. `retry`: it dropped while playing, so try to come back (Batch D) before giving up.
func _lost(text: String, retry := false) -> void:
	var was_in: bool = is_guest() and main.guest_world
	if was_in and retry and not good_target.is_empty():
		if not reconnecting:
			_begin_reconnect()
		else:
			_retry_later()
		return
	if was_in and main.world != null and main.world.recorder != null:
		main.world.recorder.net_event(self, "host_lost", main.world.player, text.left(100), "interrupted")     # X20-FINAL
	stop()
	changed.emit(text)
	if was_in:
		main.leave_guest_world(text)


## Guest (Batch D): the connection dropped while playing. The view stays (stopped: the host's world is not simulated here) and the
## guest tries the address that worked, again and again, until RECONNECT_SECONDS (HOST_PAUSED_SECONDS when the host said it is paused).
func _begin_reconnect() -> void:
	reconnecting = true
	_retries = 0
	reconnect_window = HOST_PAUSED_SECONDS if host_paused else RECONNECT_SECONDS
	reconnect_paused = host_paused
	reconnect_until = _now() + reconnect_window
	host_heard = -1
	host_heard_since_join = false
	_close_peer()
	_retry_at = _now() + 0.5
	predicted.clear()
	_fault_out.clear()
	_fault_pair.clear()
	if main.world != null and main.world.recorder != null:
		main.world.recorder.net_event(self, "reconnecting", main.world.player, "", "interrupted")
	main.net_interrupted(HOST_PAUSED_WAIT if host_paused else RECONNECTING)
	changed.emit(HOST_PAUSED_WAIT if host_paused else RECONNECTING)


func _retry_later() -> void:
	_close_peer()
	_retries += 1
	_retry_at = _now() + minf(8.0, 0.5 * pow(2.0, _retries))


func _reconnect_step() -> void:
	if peer != null:
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING and _now() > _attempt_until:
			_retry_later()
		return
	if _now() > reconnect_until:
		reconnecting = false
		_lost(HOST_LOST)
		return
	if _now() >= _retry_at:
		if not _open_client(good_target):
			_retry_later()
		else:
			_attempt_until = _now() + 5.0


## Guest: leave the host's world.
func leave() -> void:
	stop()


## Batch D, Android (Main._notification): the app goes to the background (or the screen locks). A host saves (Main does) and tells
## its guests it is paused, so they wait for it longer; a guest notes the time.
func on_app_paused() -> void:
	_paused_msec = Time.get_ticks_msec()
	if is_host() and peer != null:
		for id in by_peer:
			rpc_id(int(id), "z_paused", true)
		peer.host.flush()


## ... and comes back. A host tells its guests (those whose connections lasted; the others are reconnecting by themselves). A guest away
## longer than the host would wait reconnects at once, rather than wait for its old connection to be found dead.
func on_app_resumed() -> void:
	var away_ms := Time.get_ticks_msec() - _paused_msec if _paused_msec >= 0 else 0
	_paused_msec = -1
	if is_host() and peer != null:
		for id in by_peer:
			rpc_id(int(id), "z_paused", false)
	elif is_guest() and main.guest_world and not reconnecting and (away_ms > RESUME_AFTER_PAUSE_MS or not connected()):
		_begin_reconnect()


# ---------------------------------------------------------------- RPCs: handshake ------------
@rpc("authority", "call_remote", "reliable")
func s_challenge(host_salt: String) -> void:
	if expect_tag != "" and seen_tag != expect_tag and not reconnecting:
		_attempt_failed()                          # Batch D: this address leads to another game than the code's
		if not is_guest():
			changed.emit(OTHER_GAME)
		return
	var v := version_sent if version_sent != "" else NetProtocol.full_version()
	rpc_id(1, "z_resume", resume_token, _next_request)     # Batch D: before the hello, on the same ordered channel
	rpc_id(1, "c_hello", v, my_key, my_name, NetProtocol.password_hash(my_password, host_salt))


## Batch D: the host's world tag, told before its challenge. (Batch D's RPCs are named z_... so the older RPCs keep their ids,
## which Godot gives in name order: a guest of an older version still gets the version refusal.)
@rpc("authority", "call_remote", "reliable")
func z_tag(t: String) -> void:
	seen_tag = t


## Batch D, host: what a guest says before its hello: the resume token it was given (if any) and the number of its next request.
@rpc("any_peer", "call_remote", "reliable")
func z_resume(token: String, next_rid: int) -> void:
	if is_host():
		hello_extra[multiplayer.get_remote_sender_id()] = {"token": token.left(64), "next": next_rid}


## Batch D, guest: the token this connection may come back with (this hosting session only).
@rpc("authority", "call_remote", "reliable")
func z_token(t: String) -> void:
	resume_token = t


## Batch D, guest: the host is closing the session on purpose (Stop hosting, quit): no reconnecting.
@rpc("authority", "call_remote", "reliable")
func z_bye(reason: String) -> void:
	bye = reason if reason != "" else "stopped"
	_bye_read = true                               # B25R1: this guest ends the connection itself, next frame (_process)


## Batch D, guest: the host's app went to the background (true) or came back (false).
@rpc("authority", "call_remote", "reliable")
func z_paused(on: bool) -> void:
	host_paused = on
	if on:
		changed.emit(HOST_PAUSED_WAIT)
		if reconnecting:
			reconnect_until = maxf(reconnect_until, _now() + HOST_PAUSED_SECONDS)


@rpc("any_peer", "call_remote", "reliable")
func c_hello(version: String, key: String, who: String, pw_hash: String) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if not multiplayer.get_peers().has(id):
		return                                     # Batch D: its connection was already reported gone (read after the disconnect)
	var kh := NetProtocol.key_hash(key) if key.length() == 32 else ""
	var extra: Dictionary = hello_extra.get(id, {})
	var token := str(extra.get("token", ""))
	var why := admit(kh, version, pw_hash, who, token) if kh != "" else "version"
	if why != "":
		if main.world != null and main.world.recorder != null:
			main.world.recorder.net_event(self, "guest_refused", null, "code=%s" % why, "refused")     # X20-FINAL
		rpc_id(id, "s_refuse", why)
		get_tree().create_timer(0.5).timeout.connect(func(): if peer != null and multiplayer.get_peers().has(id): peer.disconnect_peer(id))
		return
	var back := guest_by_key(kh)
	var resumed := resumable(back, token)
	if back != null:
		for old in by_peer.keys():
			if int(by_peer[old]) == back.pid:
				_drop_peer(int(old), true)         # Batch D: its old connection, not yet timed out, gives way to this one
	if resumed:
		resumes += 1
	var p := guest_state(kh, who)
	by_peer[id] = p.pid
	joining[id] = true
	_set_timeout(id, true)                         # B25R1: it builds the world it is sent before it can answer (JOIN_TIMEOUT_MS)
	_open_stream(p, int(extra.get("next", -1)), resumed)
	resume_tokens[p.pid] = Crypto.new().generate_random_bytes(12).hex_encode()
	if main.world.recorder != null:
		main.world.recorder.net_event(self, "guest_joined", p, "peer=%d guests=%d" % [id, by_peer.size()])     # X20-FINAL
	moves[id] = {"t": Time.get_ticks_msec(), "dir": Vector2.DOWN, "anim": "idle"}
	discovery.info = _answer()
	rpc_id(id, "s_welcome", world_for(p.pid), id)
	p.away = true                                  # MP-D1: out of active play (not targetable, not acting) while it builds the world it
	                                               # was sent and cannot see or move; in play at its first move (c_move). Its own copy
	                                               # (the welcome above) has it in play.
	rpc_id(id, "z_token", str(resume_tokens[p.pid]))
	synced[id] = _welcome_digest
	announce(p, id)                               # MP-INTERACT-01: the guests already here learn who came (their public record)
	var known := {}
	for a: Animal in main.world.fauna.animals:        # the welcome's save holds every animal there is now
		known[a.id] = true
	fauna_known[id] = known
	fauna_sent[id] = {}
	changed.emit("%s joined the world." % p.name)
	main.save_game(false)
	players_changed.emit()


@rpc("authority", "call_remote", "reliable")
func s_refuse(code: String) -> void:
	refusal = code
	var text: String = REFUSALS.get(code, "The host refused the connection.")
	if reconnecting and code == "busy":
		_retry_later()                             # Batch D: a restarted host still loading its world
		return
	if main != null and main.guest_world:
		_lost(text)                                # Batch D: refused on the way back (the world filled meanwhile): to the title
		return
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
	var was_back := reconnecting
	reconnecting = false
	host_paused = false
	good_target = targets[_attempt] if not was_back and _attempt >= 0 and _attempt < targets.size() else good_target
	if was_back:
		reconnects += 1
	_built_frame = Engine.get_process_frames()
	_set_timeout(1, true)                          # B25R1: ENet checks its timeouts before it reads what came in the meantime, so
	                                               # after this long frame the host's answers would count as late (JOIN_TIMEOUT_MS)
	if not main.start_guest_world(d, my_pid):
		_lost("The world could not be shown. Try joining again.")
		return
	var pl: Array = (d.get("net_players", []) as Array).map(func(e): return (e as Dictionary).merged({"pid": int(e.pid),
		"pos": Vector2(float(e.pos[0]), float(e.pos[1])), "dir": Vector2(float(e.dir[0]), float(e.dir[1])), "level": int(e.level),
		"partner": int(e.partner), "children": (e.children as Array).map(func(c): return int(c))}, true))
	s_players(pl)                                  # the players in play as the host had them when it welcomed this guest
	if main.world != null and main.world.recorder != null:
		main.world.recorder.net_event(self, "joined_host", main.world.player, "pid=%d" % my_pid)     # X20-FINAL: the guest's own session
	changed.emit(("Reconnected to %s." if was_back else "Joined %s.") % str(d.get("world_name", "the world")))
	players_changed.emit()


# ---------------------------------------------------------------- RPCs: movement -------------
## Host: guest connection `id`, welcomed, has built the world and plays: in active play from now (MP-D1), the usual timeouts. Its first
## move or its zz_playing, whichever comes first.
func _playing(id: int) -> void:
	if not joining.has(id):
		return
	joining.erase(id)
	heard[id] = Time.get_ticks_msec()              # ND-26: watched from now (zz_tick)
	_set_timeout(id)                               # B25R1: playing, the usual timeouts from now on
	var p: PlayerState = main.world.player_by_pid(int(by_peer[id])) if by_peer.has(id) else null
	if p != null:
		p.away = false                             # MP-D1: and in active play from now (out of it while it built the world: c_hello)
		players_changed.emit()


## Guest -> host, reliable, once its world is built (its first frame after): it plays. The moves (unreliable) say so too, but ENet's
## throttle can drop them for seconds after the welcome, leaving the guest out of play on the host meanwhile (CI, net_interact_test
## "the host can choose her again"). Named zz_ so the older RPCs keep their ids (Godot numbers them in name order).
@rpc("any_peer", "call_remote", "reliable")
func zz_playing() -> void:
	var id := multiplayer.get_remote_sender_id()
	if is_host() and by_peer.has(id):
		_playing(id)


## ND-26: the heartbeat, both ways, reliable, every BEAT_SECONDS while a guest plays: a guest's to the host, the host's to each
## playing guest. Named zz_ (after zz_playing) so the other RPCs keep their ids.
@rpc("any_peer", "call_remote", "reliable")
func zz_tick() -> void:
	var id := multiplayer.get_remote_sender_id()
	if is_host():
		if heard.has(id):
			heard[id] = Time.get_ticks_msec()
	elif is_guest() and id == 1 and host_heard >= 0:
		host_heard = Time.get_ticks_msec()
		host_heard_since_join = true


## Host (ND-26): a playing guest silent (no heartbeat) for longer than TIMEOUT_MAX_MS is dropped as ENet drops a dead connection
## (_drop_peer: out of active play, every record kept, the world saved), and its connection ended at once (peer_disconnect_now: Godot
## then reports it gone; the peer_disconnected that follows finds it already dropped). A guest still joining is not in `heard`.
func _watch_guests(now: int) -> void:
	for id in heard.keys():
		if not by_peer.has(id) or joining.has(id):
			heard.erase(id)
			continue
		if now - int(heard[id]) <= TIMEOUT_MAX_MS:
			continue
		watchdog_drops += 1
		var pp := peer.get_peer(int(id)) if peer != null else null
		_drop_peer(int(id), false)
		if pp != null:
			pp.peer_disconnect_now()


@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_move(pos: Vector2, dir: Vector2, anim: String) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if not by_peer.has(id):
		return
	var p: PlayerState = main.world.player_by_pid(int(by_peer[id]))
	_playing(id)
	if p == null or not p.alive:
		return
	if _passage_waiting(id):
		return                                     # B25R2-CAVE: the guest went through a portal on its own copy; the passage, queued, moves it here
	var now := Time.get_ticks_msec()
	var dt := maxf(1.0 / NetProtocol.MOVE_HZ, float(now - int(moves[id].t)) / 1000.0)
	var most := float(GameData.b("player_tiles_per_second")) * float(GameData.b("sprint_speed")) * dt * 1.5 + 0.25
	if not move_ok(p, pos, most):
		rejected += 1
		rpc_id(id, "zz_correct", p.pos, p.map_level)     # B25R2-CAVE: the place and the level, so the guest's copy is never on another level
		return
	p.pos = pos
	moves[id] = {"t": now, "dir": dir, "anim": anim if anim in ANIMS else "idle"}


## Whether player `p` may step to `to`: no farther than `most`, onto ground open on its own level (World.solid_for_player).
func move_ok(p: PlayerState, to: Vector2, most: float) -> bool:
	if not is_finite(to.x) or not is_finite(to.y) or p.pos.distance_to(to) > most:
		return false
	if p.pos.distance_to(to) < 0.01:
		return true
	return main.world.step_ok(p, to)                 # MP C1: the core's walking rule, the host's own (World.step_ok)


@rpc("authority", "call_remote", "reliable")
func s_correct(pos: Vector2) -> void:
	if main.world != null:
		main.world.player.pos = pos


## Host -> guest (B25R2-CAVE, owner 2026-11-07): the guest's place and the level it is on, as the host has them. s_correct sent the
## place only: a guest whose copy had gone through a cave's mouth the host had not (a move refused before the passage, or the passage
## refused) stood on the cave's level at a place outside it, in rock, for good. Named zz_ so the older RPCs keep their ids.
@rpc("authority", "call_remote", "reliable")
func zz_correct(pos: Vector2, level: int) -> void:
	if main.world != null:
		main.world.player.pos = pos
		main.world.player.map_level = level


## Host (B25R2-CAVE): whether guest connection `id` has a passage through a portal queued or held, not yet applied. Its moves meanwhile
## are from the other side of the portal: not refused (sending it back), only left until the passage puts it there.
func _passage_waiting(id: int) -> bool:
	for e in queue:
		if int(e.peer) == id and e.args is Dictionary and str(e.args.get("path", "")) == "player_through":
			return true
	for k in streams:
		for e in (streams[k].held as Dictionary).values():
			if int(e.peer) == id and e.args is Dictionary and str(e.args.get("path", "")) == "player_through":
				return true
	return false


# ---------------------------------------------------------------- RPCs: snapshots ------------
@rpc("authority", "call_remote", "unreliable_ordered")
func s_players(list: Array) -> void:
	var seen := {}
	for e in list:
		var pid := int(e.pid)
		if pid == my_pid:
			# B25R2-CAVE: this player's own level, as the host has it, is the truth once no passage of its own is waiting
			# (twice in a row: a list sent before the passage may arrive after its answer, on another channel)
			if main.world != null and main.guest_world and portal_rid == 0 and e.has("level") and int(e.level) != main.world.player.map_level:
				level_differs += 1
				if level_differs >= 2:
					main.world.player.map_level = int(e.level)
					main.world.player.pos = e.pos
					level_differs = 0
			else:
				level_differs = 0
			continue
		seen[pid] = true
		if not avatars.has(pid):
			avatars[pid] = {"pos": e.pos}
		avatars[pid].merge(e, true)
		var o: PlayerState = main.world.player_by_pid(pid) if main.world != null else null
		if o != null:
			o.pos = e.pos                         # the guest's copy of the other players follows the host
			if e.has("worn") and (e.worn as Array).size() == 2:
				o.armor = str(e.worn[0])              # ARMOR-01: and what they wear (drawn by main._sync_avatars)
				o.head = str(e.worn[1])
			if e.has("wield"):
				o.weapon = str(e.wield)                # WEAPON-VISIBLE-01: and the weapon they hold
			o.alive = bool(e.alive)
			o.map_level = int(e.get("level", o.map_level))     # MP-INTERACT-01: the level they are on (the adit), and that they are in play
			o.away = false
			o.partner = int(e.get("partner", o.partner))                 # MP-PLAYER-FAMILY: their family as the host has it
			o.children = (e.get("children", o.children) as Array).map(func(c): return int(c))
	for pid in avatars.keys():
		if not seen.has(pid):
			avatars.erase(pid)
	if main.world != null and main.guest_world:
		for q: PlayerState in main.world.player_list():
			if q.pid != my_pid and not seen.has(q.pid):
				q.away = true                         # MP-INTERACT-01: the host no longer reports them in play (left, MP-D1)
	players_changed.emit()


## Host (MP-INTERACT-01): tell every other connected guest the public record of player `p` (one who joined, an heir), so their copy
## has them to choose and to name: the same record a welcome holds for each other player (public_player).
func announce(p: PlayerState, but_peer: int) -> void:
	if p == null or peer == null:
		return
	var d := public_player(p)
	for id in by_peer:
		if int(id) != but_peer:
			rpc_id(int(id), "s_public", d)


## Guest (MP-INTERACT-01): another player's public record (a guest who joined after this one, an heir): added to this copy, or its
## public fields brought up to date.
@rpc("authority", "call_remote", "reliable")
func s_public(d: Dictionary) -> void:
	if main.world == null or not main.guest_world or int(d.get("pid", 0)) == my_pid:
		return
	var fresh := PlayerState.from_dict(d)
	var q: PlayerState = main.world.player_by_pid(fresh.pid)
	if q == null:
		main.world.add_guest(fresh)
		return
	for k in ["name", "family", "sprite", "heir_sprite", "appearance", "armor", "head", "weapon", "sex", "born", "alive", "map_level",
			"partner", "children", "mother", "father"]:
		q.set(k, fresh.get(k))


@rpc("authority", "call_remote", "reliable")
func s_self(d: Dictionary) -> void:
	if main.world != null and main.guest_world and int(d.get("pid", 0)) == my_pid:
		main.adopt_own_state(d)


## B25R1 (traffic): NPC_FLOATS floats a villager in `rows`, its animation in `anims` (the villagers that changed since the last
## snapshot, and all near the guest on a key one: NPCS_KEY_EVERY).
@rpc("authority", "call_remote", "unreliable_ordered")
func s_npcs(minutes: float, rows: PackedFloat32Array, anims: PackedStringArray) -> void:
	if main.world == null:
		return
	main.world.minutes = maxf(main.world.minutes, minutes)
	for r in mini(anims.size(), rows.size() / NPC_FLOATS):
		var b := r * NPC_FLOATS
		var n: NPC = main.world.npc(int(rows[b]))
		if n == null:
			continue
		var flags := int(rows[b + 5])
		npc_target[n.id] = Vector2(rows[b + 1], rows[b + 2])
		n.facing = Vector2(rows[b + 3], rows[b + 4])
		n.anim = anims[r]
		n.alive = flags & NPC_ALIVE != 0
		if flags & NPC_FIELD:
			var swing := flags & NPC_SWING != 0
			field_pose[n.id] = {"pos": Vector2(rows[b + 6], rows[b + 7]), "anim": "swing" if swing else "walk", "tool": FieldWorkView.TOOL if swing else "", "facing": n.facing}
		else:
			field_pose.erase(n.id)


var _welcome_digest := {}
var _rec_hour := -1                 # X20: the last game hour a recorded host marked its sync for the guests' digests (send_syncs)


## Guest (Build 21): the animals near this player as the host has them: place, facing, walking or not, a one-off animation
## (attack, hit) and health. An animal this copy does not hold yet waits for s_fauna_life.
## Eight floats an animal: id, x, y, facing x and y, walking (1 or 0), the animation's index (ANIMAL_ACTS), health.
@rpc("authority", "call_remote", "unreliable_ordered")
func s_animals(list: PackedFloat32Array) -> void:
	if main.world == null or not main.guest_world:
		return
	for i in range(0, list.size() - 7, 8):
		var a: Animal = main.world.fauna.by_id(int(list[i]))
		if a == null:
			continue
		animal_target[a.id] = Vector2(list[i + 1], list[i + 2])
		a.facing = Vector2(list[i + 3], list[i + 4])
		a.moving = list[i + 5] > 0.5
		a.act = ANIMAL_ACTS[clampi(int(list[i + 6]), 0, ANIMAL_ACTS.size() - 1)]
		a.act_left = 0.4 if a.act != "" else 0.0
		a.hp = list[i + 7]


## Guest (Build 21): animals the host made (births, spawns: their whole records) and animals gone from the host's world (killed,
## taken by a predator, sold, died), at once and reliably; the view fades a gone animal out as it does on the host.
@rpc("authority", "call_remote", "reliable")
func s_fauna_life(born: Array, gone: Array) -> void:
	if main.world == null or not main.guest_world:
		return
	var d: Array = JSON.parse_string(JSON.stringify(born))      # as a save is read
	for ad in d:
		NetSync.add_animal(main.world, Animal.from_dict(ad))
	for aid in gone:
		var a: Animal = main.world.fauna.by_id(int(aid))
		if a != null:
			main.world.fauna.remove(a)
		animal_target.erase(int(aid))


# ---------------------------------------------------------------- RPCs: actions --------------
## Guest (MP C, World.remote): send verb `path` with its arguments, named as both machines name them (NetActions.enc). The id of
## the request; the host's answer comes as s_reply, the world sections it changed as s_sync.
func send_verb(path: String, args: Array) -> int:
	if path in LOCAL_QUERIES:
		return 0                                   # Batch D: a question, not an action: answered from this copy, nothing sent
	var a := []
	for v in args:
		a.append(NetActions.enc(main.world, v))
	var rid := request("verb", {"path": path, "a": a})
	if path == "player_through":
		portal_rid = rid
	return rid


## Batch D: World verbs that only answer a question and change nothing (the interface asks container_pick every frame to word the
## prompt beside a chest or table): a guest answers them from its copy and does not send them (they were requests to the host each
## frame, about 14 a second while beside a container).
const LOCAL_QUERIES := ["container_pick"]


## Guest: what this machine's own run of a sent verb gave (World.remote_done).
func note_prediction(rid, r) -> void:
	if rid is int and rid > 0:
		predicted[rid] = NetActions.enc(main.world, r)


## Guest: the id of the request sent last (a verb just sent through World.mirror).
func last_request() -> int:
	return _next_request - 1


## Guest: ask the host to do something; the answer lands in `replies[id]` (and the guest's character is updated from it).
## Batch D: every request is numbered (rid, rising); the host applies each number once. Not connected (reconnecting): not sent,
## answered here as refused (the world the host sends on the way back is the truth).
func request(kind: String, args: Dictionary) -> int:
	var rid := _next_request
	_next_request += 1
	if not connected():
		replies[rid] = {"ok": false, "text": "Not connected to the host."}
		return rid
	if faults.is_empty():
		rpc_id(1, "c_request", rid, kind, args)
	else:
		_fault_send({"rid": rid, "kind": kind, "args": args})
	return rid


## Tests (Batch D): a request sent as a faulty network might deliver it: twice (dup), late (delay_ms), or swapped with the next
## (reorder). Late ones go from _process.
func _fault_send(e: Dictionary) -> void:
	e["at"] = _now() + float(faults.get("delay_ms", 0)) / 1000.0
	var batch := [e]
	if bool(faults.get("reorder", false)):
		_fault_pair.append(e)
		if _fault_pair.size() < 2:
			e["pair_at"] = _now() + 1.0
			return
		batch = [_fault_pair[1], _fault_pair[0]]
		_fault_pair.clear()
	for x in batch:
		_fault_out.append(x)
		if bool(faults.get("dup", false)):
			_fault_out.append(x.duplicate())


func _fault_step() -> void:
	if _fault_pair.size() == 1 and _now() >= float(_fault_pair[0].pair_at):
		_fault_out.append(_fault_pair[0])          # no second came: the one held goes alone
		_fault_pair.clear()
	if not connected():
		return
	var keep := []
	for e in _fault_out:
		if _now() >= float(e.at):
			rpc_id(1, "c_request", int(e.rid), str(e.kind), e.args)
		else:
			keep.append(e)
	_fault_out = keep


@rpc("any_peer", "call_remote", "reliable")
func c_request(rid: int, kind: String, args: Dictionary) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if not by_peer.has(id):
		return
	var p: PlayerState = main.world.player_by_pid(int(by_peer[id]))
	if p == null:
		return
	var st: Dictionary = _stream_of(p)
	var e := {"pid": p.pid, "peer": id, "rid": rid, "kind": kind, "args": args, "t": _now()}
	if int(st.next) < 0:
		st.next = rid                              # no number told (z_resume missing): the first one sets it
	if rid < int(st.next) or (st.held as Dictionary).has(rid):
		duplicates += 1                            # Batch D: applied (or waiting) already: never again
		if (st.done as Dictionary).has(rid):
			rpc_id(id, "s_reply", rid, st.done[rid])
		return
	if rid > int(st.next):
		st.held[rid] = e                           # an earlier number has not come yet: wait for it (HOLD_SECONDS)
		return
	_enqueue(st, e)


## Host (Batch D): request `e` is next in its guest's numbering: queued, then any held ones that now follow it.
func _enqueue(st: Dictionary, e: Dictionary) -> void:
	arrivals += 1
	e["seq"] = arrivals
	queue.append(e)
	st.next = int(e.rid) + 1
	while (st.held as Dictionary).has(int(st.next)):
		var h: Dictionary = st.held[int(st.next)]
		st.held.erase(int(st.next))
		arrivals += 1
		h["seq"] = arrivals
		queue.append(h)
		st.next = int(st.next) + 1


## Host (Batch D): a held request has waited HOLD_SECONDS for a missing earlier number: the gap is given up and the held go in order.
func _release_held() -> void:
	for k in streams:
		var st: Dictionary = streams[k]
		var held: Dictionary = st.held
		if held.is_empty():
			continue
		var first := int(held.keys().min())
		if _now() - float(held[first].t) < HOLD_SECONDS:
			continue
		gaps_skipped += first - int(st.next)
		var e: Dictionary = held[first]
		held.erase(first)
		if by_peer.has(int(e.peer)):
			_enqueue(st, e)
		else:
			st.next = first + 1


## Host (Batch D): this player's request numbering, made on its first join.
func _stream_of(p: PlayerState) -> Dictionary:
	var k := _ident(p)
	if not streams.has(k):
		streams[k] = {"next": -1, "done": {}, "order": [], "held": {}}
	return streams[k]


## Host (Batch D): at a join, the guest's numbering: kept when it came back with its token (the same run of numbers, so a request
## repeated across the reconnection is still known), else begun afresh from the number it told (`next`, -1 for none).
func _open_stream(p: PlayerState, next_rid: int, resumed: bool) -> void:
	var st := _stream_of(p)
	if not resumed:
		st.done = {}
		st.order = []
		st.next = next_rid
	elif next_rid > int(st.next):
		st.next = next_rid                         # numbers sent before the drop that never arrived are not waited for
	st.held = {}


## Host (Batch D): keep the answer to request `rid` of player `p`, for a repeat of it.
func _remember(p: PlayerState, rid: int, r: Dictionary, what := "") -> void:
	if p == null:
		return
	var st := _stream_of(p)
	st.done[rid] = r
	st.order.append(rid)
	while (st.order as Array).size() > REPLIES_KEPT:
		st.done.erase(st.order.pop_front())
	applied_log.append([p.pid, rid, what])
	if applied_log.size() > 200:
		applied_log.pop_front()


## X20 (net_mp4_test): a guest's copy changes its own offers before the host answers (World.player_answer takes the answered one
## away at once; World.player_offer, mirrored, adds one). When the host refuses (the buyer is short, not beside them, "You have asked
## already") its offers are unchanged, so NetSync.changed would not send them and the copy would keep its guess: an offer still
## waiting gone from the recipient's screen, or one that does not exist shown. After these verbs the offers always go again.
const OFFER_VERBS := ["player_offer", "player_answer"]


## Host: apply every queued request, in arrival order (then pid), each once, as its player, and answer it. Called at one
## fixed point of the host's frame (Main._process, before World.update), so a recorded session replays the same way.
func apply_requests() -> void:
	if queue.is_empty():
		return
	var todo := queue
	queue = []
	todo.sort_custom(func(a, b): return [int(a.seq), int(a.pid)] < [int(b.seq), int(b.pid)])
	for q in todo:
		if joining.has(int(q.peer)) and by_peer.has(int(q.peer)):
			_playing(int(q.peer))                  # MML-MP-06: a connected guest that acts has built its world: in play, as at its first move (MP-D1)
		var p: PlayerState = main.world.player_by_pid(int(q.pid))
		var r := NetActions.apply(main.world, p, str(q.kind), q.args if q.args is Dictionary else {})
		applied += 1
		_remember(p, int(q.rid), r, str(q.args.get("path", q.kind)) if q.args is Dictionary else str(q.kind))     # Batch D: a repeat of this number is answered, not applied again
		if main.world.recorder != null:
			main.world.recorder.net_request(self, p, str(q.kind), r)     # X20-FINAL: each player action the host applied
		if r.has("heir_pid") and by_peer.has(int(q.peer)):
			by_peer[int(q.peer)] = int(r.heir_pid)     # MP-D4: the connection now plays the heir
			announce(main.world.player_by_pid(int(r.heir_pid)), int(q.peer))     # MP-INTERACT-01: the others learn of the heir
			players_changed.emit()
			main.save_game(false)
		if peer != null and by_peer.has(int(q.peer)):
			rpc_id(int(q.peer), "s_reply", int(q.rid), r)
			sync_due[int(q.peer)] = true                # MP C: its copy takes the sections this changed, at once (send_syncs)
			if str(r.get("path", "")) in OFFER_VERBS and synced.has(int(q.peer)):
				synced[int(q.peer)]["player_offers"] = -1     # X20: the offers go again even when the host's did not change (OFFER_VERBS)
	send_syncs(false)


@rpc("authority", "call_remote", "reliable")
func s_reply(rid: int, r: Dictionary) -> void:
	if replies.has(rid):
		return                                     # Batch D: an answer repeated (the request came twice): taken once
	replies[rid] = r
	if main.world != null and main.guest_world and r.has("heir_pid"):
		my_pid = int(r.heir_pid)
		main.adopt_heir(r.get("player", {}))          # MP-D4: the heir the host made is this player's character now
	elif main.world != null and main.guest_world:
		var mine: Dictionary = r.get("player", {})
		if not mine.is_empty() and int(mine.get("pid", 0)) == my_pid:
			main.adopt_own_state(mine)            # the host's record of this player is the truth
			if str(r.get("path", "")) == "player_through":
				var fresh := PlayerState.from_dict(mine)     # B25R2-CAVE: after a passage, the side of the portal too (the host's)
				main.world.player.pos = fresh.pos
				main.world.player.map_level = fresh.map_level
		if rid == portal_rid:
			portal_rid = 0
		for patch in r.get("patches", []):
			NetActions.apply_patch(main.world, patch)
	if r.has("path"):
		# MP C, a verb: this machine already showed its own result; the host's is told only when it differs (someone was first,
		# the host's world had moved on), and the sections that follow (s_sync) put the copy right
		var mine_r = predicted.get(rid)
		predicted.erase(rid)
		verb_answered.emit(rid, r.get("result"))
		if (not bool(r.get("ok", false)) or JSON.stringify(mine_r) != JSON.stringify(r.get("result"))) and str(r.get("text", "")) != "":
			answered.emit(str(r.text))
		if main.world != null and main.world.recorder != null and JSON.stringify(mine_r) != JSON.stringify(r.get("result")):
			main.world.recorder.net_event(self, "prediction_differs", main.world.player, "rid=%d path=%s" % [rid, str(r.get("path", ""))], "failed")     # X20-FINAL
		return
	if str(r.get("text", "")) != "":
		answered.emit(str(r.text))


# ---------------------------------------------------------------- GP-MESSAGE-JOURNAL ----------
const JOURNAL_MAX_CHARS := 600       # a journal entry a guest sends is cut to this (no message of the game is longer)

## Guest (World.remote_journal): a message this player was shown and keeps, for the host to keep in its world under this
## player. Not a request: no answer, no sync, never applied as an action.
func send_journal(text: String, category: String) -> void:
	if peer != null and not is_host():
		rpc_id(1, "c_journal", text.left(JOURNAL_MAX_CHARS), category)


@rpc("any_peer", "call_remote", "reliable")
func c_journal(text: String, category: String) -> void:
	if not is_host() or main.world == null:
		return
	var id := multiplayer.get_remote_sender_id()
	if not by_peer.has(id):
		return
	var p: PlayerState = main.world.player_by_pid(int(by_peer[id]))
	if p == null:
		return
	main.world.messages.record(main.world.player_ref(p), main.world.minutes, category, text.left(JOURNAL_MAX_CHARS))
	journal_kept += 1


## Host (MP C): each guest due one (or all, `all`) gets the sections of the shared world that changed since it was last sent them.
## One World.to_dict for all of them; nothing is sent to a guest whose copy is current.
## X20 (net_soak_test): `clock` >= 0 marks the sync of a recorded host's game hour: every guest gets it, with the host's clock, even
## when nothing changed, and a recording guest takes its hourly digest of the very state the host's digest saw (WorldRecorder).
## `mark` >= 0 (the tests' "dump", tests/net_host.gd) likewise goes to every due guest even when nothing changed: the guest's copy
## right after taking it (world_synced) is the host's world of this very frame, whatever syncs come after it.
func send_syncs(all: bool, skip: Array = [], clock := -1.0, mark := -1) -> void:
	if peer == null or by_peer.is_empty():
		return
	var due := []
	var sync_due_was := sync_due.duplicate()       # a guest with a request applied gets every changed section
	for id in by_peer:
		if all or sync_due.has(id):
			due.append(id)
	if due.is_empty():
		return
	var all_d: Dictionary = main.world.to_dict()
	for id in due:
		sync_due.erase(id)
		if not synced.has(id):
			synced[id] = {}
		var g: PlayerState = main.world.player_by_pid(int(by_peer[id]))
		var d := all_d.duplicate(false)                # MML-MP-07: each guest's sections filtered for it (the host's world untouched)
		_private_for(d, main.world.player_ref(g) if g != null else "", main.world)
		var ch := NetSync.changed(d, synced[id], skip if not sync_due_was.has(id) else [])
		if clock >= 0.0:
			ch["_net_clock"] = clock
		if mark >= 0:
			ch["_net_mark"] = mark
		if ch.is_empty():
			continue
		var blob := JSON.stringify(ch).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
		sync_bytes += blob.size()
		if main.world.recorder != null:
			main.world.recorder.net_sync(self, true, ch.size(), blob.size())     # X20-FINAL: counted, not one row each
		rpc_id(id, "s_sync", blob)


@rpc("authority", "call_remote", "reliable")
func s_sync(blob: PackedByteArray) -> void:
	if main.world == null or not main.guest_world:
		return
	var d = JSON.parse_string(blob.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	if d is Dictionary:
		var clock := float(d.get("_net_clock", -1.0))
		var mark := int(d.get("_net_mark", -1))
		d.erase("_net_clock")
		d.erase("_net_mark")
		if clock >= 0.0:
			main.world.minutes = maxf(main.world.minutes, clock)      # the host's clock, as the villager snapshots bring it (s_npcs)
		NetSync.adopt(main.world, d)
		if d.has("npcs"):                          # a villager the sync placed beyond the snapshots' reach is not eased back
			for nid in npc_target.keys():
				var n: NPC = main.world.npc(nid)
				if n != null and n.pos.distance_to(main.world.player.pos) > NetProtocol.NPC_RANGE:
					npc_target.erase(nid)
		syncs += 1
		if main.world.recorder != null:
			main.world.recorder.net_sync(self, false, (d as Dictionary).size(), blob.size(), clock >= 0.0)     # X20-FINAL (and the guest's hourly digest)
		world_synced.emit(mark)


# ---------------------------------------------------------------- every frame ----------------
func _process(dt: float) -> void:
	if role == "":
		if discovery.udp.is_bound():
			discovery.poll(dt, discovery_port)
		return
	discovery.poll(dt, discovery_port)
	if is_host():
		if upnp.poll():
			players_changed.emit()                 # Batch D: the router answered; the window shows the new invite code
		_release_held()
		var now_h := Time.get_ticks_msec()
		var own := now_h - _host_frame_msec if _host_frame_msec >= 0 else 0
		_host_frame_msec = now_h
		if own > OWN_GAP_MS:
			for id in heard:                           # ND-26: the host itself stood still (a long frame, a freeze): not the guests' silence
				heard[id] = int(heard[id]) + own
		_watch_guests(now_h)
		_host_step(dt)
		return
	if not is_guest():
		return
	if _bye_read:
		_bye_read = false
		_lost(HOST_STOPPED)                        # B25R1: the host is stopping and waits for its guests to end their connections
		return
	var now_ms := Time.get_ticks_msec()
	var gap := now_ms - _frame_msec if _frame_msec >= 0 else 0
	_frame_msec = now_ms
	if gap > RESUME_AFTER_PAUSE_MS and _built_frame < 0 and main.guest_world and not reconnecting:
		# KI-12: the process was frozen with no pause notice (stopped, a computer asleep, a debugger; on_app_resumed covers Android's
		# notice): as after a pause, reconnect at once. Left to ENet, the dead connection is seen only TIMEOUT_MAX_MS or more after its
		# first send (0-20 s measured after a SIGSTOP), then the world is sent again. The frame that built the world is not a freeze.
		_begin_reconnect()
		return
	if reconnecting:
		_reconnect_step()
		return
	if host_heard >= 0:
		if gap > OWN_GAP_MS:
			host_heard += gap                          # ND-26: this guest's own long frame is not the host's silence
		if now_ms - host_heard > (TIMEOUT_MAX_MS if host_heard_since_join else JOIN_TIMEOUT_MS) and main.guest_world and connected():
			host_heard = -1
			host_silent_losses += 1
			_on_server_gone()                          # ND-26: the host silent past TIMEOUT_MAX_MS: lost, as when ENet ends the connection
			return
	if peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING and _now() > _attempt_until:
		_attempt_failed()                          # Batch D: this address did not answer in its time
		return
	if not faults.is_empty() or not _fault_out.is_empty():
		_fault_step()
	if main.guest_world and connected():
		_guest_step(dt)


func _host_step(dt: float) -> void:
	if by_peer.is_empty():
		return
	var live := multiplayer.get_peers()
	for id in by_peer.keys():
		if not live.has(int(id)):
			_drop_peer(int(id), false)             # Batch D: a connection ENet has ended without a signal reaching here
	if by_peer.is_empty():
		return
	_t_beat += dt
	if _t_beat >= BEAT_SECONDS:
		_t_beat = 0.0
		for id in heard:                               # ND-26: the host's heartbeat to each playing guest
			rpc_id(int(id), "zz_tick")
	if main.world.recorder != null:                    # X20: a recorded host's hour (its digest was just taken, World._on_hour)
		var hk := int(main.world.minutes / 60.0)
		if _rec_hour < 0:
			_rec_hour = hk                             # the hour under way when the first guest came: its digest was taken before
		elif hk != _rec_hour:
			_rec_hour = hk
			main.world.recorder.net_state_maybe()      # the host's digest of this frame's world: the state the marked sync carries
			send_syncs(true, [], main.world.minutes)
	_t_players += dt
	if _t_players >= 1.0 / NetProtocol.PLAYERS_HZ:
		_t_players = 0.0
		_n_players += 1
		var pl := players_snapshot(_n_players % PLAYERS_KEY_EVERY == 0)
		if pl != _players_sent or _n_players % PLAYERS_KEY_EVERY == 0:     # B25R1: unchanged, nothing to send but the key
			_players_sent = pl
			rpc("s_players", pl)
	_t_sync += dt
	if _t_sync >= NetSync.SYNC_SECONDS:
		_t_sync = 0.0
		_n_sync += 1
		send_syncs(true, [] if _n_sync % NetSync.NPCS_EVERY == 0 else NetSync.SLOW)     # MP C: the shared world as it went on (the villagers' and animals' records less often)
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
		_n_npcs += 1
		var key := _n_npcs % NPCS_KEY_EVERY == 0
		for id in by_peer:
			var g: PlayerState = main.world.player_by_pid(int(by_peer[id]))
			if g == null:
				continue
			if not npcs_sent.has(id):
				npcs_sent[id] = {}
			var sent: Dictionary = npcs_sent[id]
			var list := []
			var rows := PackedFloat32Array()
			var anims := PackedStringArray()
			for n: NPC in main.world.npcs:
				var fw := FieldWorkView.pose(main.world, n) if n.pos.distance_to(g.pos) <= NetProtocol.NPC_RANGE else {}
				var row := [n.id, n.pos.x, n.pos.y, n.facing.x, n.facing.y, n.anim, n.alive] if fw.is_empty() else \
					[n.id, n.pos.x, n.pos.y, fw.facing.x, fw.facing.y, n.anim, n.alive, fw.pos.x, fw.pos.y, 1 if fw.anim == "swing" else 0]
				if n.pos.distance_to(g.pos) <= NetProtocol.NPC_RANGE:
					if key or sent.get(n.id) != row:     # B25R1: a villager standing as it was last sent is not sent again until the key
						sent[n.id] = row
						list.append(row)
				elif sent.has(n.id) or left_view.get(id, {}).has(n.id):
					# a villager gone out of this guest's range (walked off, sent away) is sent once where it went, and again on the
					# next LEFT_KEYS keys, so the copy never keeps it where it was last seen near the guest (a lost packet included)
					sent.erase(n.id)
					var lv: Dictionary = left_view.get_or_add(id, {})
					lv[n.id] = int(lv.get(n.id, LEFT_KEYS + 1)) - (1 if key else 0)
					if key or lv[n.id] == LEFT_KEYS + 1:
						list.append(row)
					if lv[n.id] <= 0:
						lv.erase(n.id)
			for i in range(0, maxi(1, list.size()), NPCS_PER_PACKET):      # unreliable packets stay under the MTU
				rows.clear()
				anims.clear()
				for row in list.slice(i, i + NPCS_PER_PACKET):
					var field: bool = row.size() >= 10
					rows.append_array([row[0], row[1], row[2], row[3], row[4],
						(NPC_ALIVE if row[6] else 0) | (NPC_FIELD if field else 0) | (NPC_SWING if field and row[9] == 1 else 0),
						row[7] if field else 0.0, row[8] if field else 0.0])
					anims.append(str(row[5]))
				rpc_id(id, "s_npcs", main.world.minutes, rows, anims)
		_n_animals += 1
		for id in by_peer:
			var g2: PlayerState = main.world.player_by_pid(int(by_peer[id]))
			if g2 != null:
				send_animals(id, g2, _n_animals % ANIMALS_KEY_EVERY == 0)


## Host (Build 21): guest `id`'s copy of the animals follows the host's. Births and deaths anywhere go reliably (s_fauna_life); the
## live state of the animals near the guest goes in unreliable snapshots, only what changed since it was last sent, and every
## animal near it on a key snapshot (`all`), so a lost packet is put right within a second. The guest never simulates animals.
func send_animals(id: int, g: PlayerState, all: bool) -> void:
	var f: Fauna = main.world.fauna
	if not fauna_known.has(id):
		fauna_known[id] = {}
		fauna_sent[id] = {}
	var known: Dictionary = fauna_known[id]
	var sent: Dictionary = fauna_sent[id]
	var here := {}
	var born := []
	for a: Animal in f.animals:
		here[a.id] = true
		if not known.has(a.id):
			known[a.id] = true
			born.append(a.to_dict())
	var gone := []
	for aid in known.keys():
		if not here.has(aid):
			known.erase(aid)
			sent.erase(aid)
			gone.append(aid)
	if not born.is_empty() or not gone.is_empty():
		rpc_id(id, "s_fauna_life", born, gone)
	if g.map_level != 0:
		return                                     # animals live above ground
	var list := PackedFloat32Array()
	for a: Animal in f.near(g.pos, NetProtocol.NPC_RANGE):
		var fc := a.facing.normalized() if a.facing.length() > 0.001 else Vector2.DOWN
		var live := PackedFloat32Array([a.pos.x, a.pos.y, snappedf(fc.x, 0.01), snappedf(fc.y, 0.01), 1.0 if a.moving else 0.0, maxi(0, ANIMAL_ACTS.find(a.act)), a.hp])
		if not all and sent.get(a.id) == live:
			continue
		sent[a.id] = live
		list.append(float(a.id))
		list.append_array(live)
	for i in range(0, list.size(), ANIMALS_PER_PACKET * 8):
		rpc_id(id, "s_animals", list.slice(i, i + ANIMALS_PER_PACKET * 8))


## Every player in active play as the others see them, by pid: names, looks, place, facing and animation only.
func players_list() -> Array:
	var w: World = main.world
	var h: PlayerState = w.host_player()
	var out := [{"pid": h.pid, "name": h.name, "sprite": h.sprite, "pos": h.pos, "dir": main.facing_vec(), "anim": main.net_anim(), "alive": h.alive, "level": h.map_level,
		"worn": [h.armor, h.head], "wield": h.weapon,       # ARMOR-01: what each player wears; WEAPON-VISIBLE-01: what they hold
		"partner": h.partner, "children": h.children}]          # MP-PLAYER-FAMILY: a player's spouse and children are public family records
	for id in by_peer:
		var g: PlayerState = w.player_by_pid(int(by_peer[id]))
		if g != null:
			out.append({"pid": g.pid, "name": g.name, "sprite": g.sprite, "pos": g.pos, "dir": moves[id].dir, "anim": moves[id].anim, "alive": g.alive, "level": g.map_level,
				"worn": [g.armor, g.head], "wield": g.weapon, "partner": g.partner, "children": g.children})
	return out


func _guest_step(dt: float) -> void:
	if _built_frame >= 0 and Engine.get_process_frames() > _built_frame:
		_built_frame = -1
		_set_timeout(1)                            # the network read once since the world was built: the usual timeouts again
		rpc_id(1, "zz_playing")                    # and it plays (reliable: the moves may be throttled away for a while)
		host_heard = Time.get_ticks_msec()         # ND-26: the host watched from now (zz_tick)
		host_heard_since_join = false              # B42-NET-MP4-STALE: until its first heartbeat, JOIN_TIMEOUT_MS
		_t_beat = BEAT_SECONDS
	_t_beat += dt
	if _t_beat >= BEAT_SECONDS:
		_t_beat = 0.0
		rpc_id(1, "zz_tick")                       # ND-26: this guest's heartbeat to the host
	_t_move += dt
	if _t_move >= 1.0 / NetProtocol.MOVE_HZ:
		_t_move = 0.0
		rpc_id(1, "c_move", main.world.player.pos, main.facing_vec(), main.net_anim())
		moves_sent += 1
	var k := minf(1.0, dt * 8.0)
	for id in npc_target:
		var n: NPC = main.world.npc(id)
		if n != null:
			n.pos = n.pos.lerp(npc_target[id], k) if n.pos.distance_to(npc_target[id]) < 3.0 else npc_target[id]
	for id in animal_target.keys():                  # Build 21: the animals near this player ease toward the host's places
		var a: Animal = main.world.fauna.by_id(id)
		if a == null:
			animal_target.erase(id)
			continue
		a.pos = a.pos.lerp(animal_target[id], k) if a.pos.distance_to(animal_target[id]) < 3.0 else animal_target[id]
		a.act_left = maxf(0.0, a.act_left - dt)


## Host (B25R1, traffic): the players' list as s_players sends it: each player's place, facing, animation, life and level every time,
## and its PLAYER_STATIC fields only when they changed since last sent, on the key (`all`), or when a connection came or went.
func players_snapshot(all: bool) -> Array:
	var peers := by_peer.keys()
	peers.sort()
	if peers != _players_peers:
		_players_peers = peers
		all = true
	var out := []
	for e: Dictionary in players_list():
		var st := {}
		for k in PLAYER_STATIC:
			st[k] = e[k]
		var pid := int(e.pid)
		if not all and _players_static.get(pid) == st:
			for k in PLAYER_STATIC:
				e.erase(k)
		_players_static[pid] = st
		out.append(e)
	return out


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
