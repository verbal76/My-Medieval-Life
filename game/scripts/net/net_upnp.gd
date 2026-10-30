class_name NetUpnp
extends RefCounted
## Multiplayer Batch D (docs/multiplayer/BATCH_D_CONNECTIVITY.md): ask the home router to forward the game's UDP port to this device
## (UPnP-IGD, Godot's built-in UPNP class: no new dependency, no server), and learn the router's public address for the invite code.
## A router search takes up to several seconds, so it runs on its own thread; `state` says how it went:
##   "" not asked, "checking", "mapped" (the router forwards the port and has a real public address: friends elsewhere can try it),
##   "shared" (the router mapped it but its own outside address is private or the provider's shared range, 100.64.0.0/10:
##   carrier-grade or double NAT, nobody outside reaches it), "refused" (a router answered but would not map the port),
##   "no_router" (nothing answered: UPnP off, or no home router, as on mobile data), "off" (not asked for: tests, or the player).
## The mapping lasts until it is removed (lease 0, which every IGD version accepts) and is removed when hosting stops.

const SEARCH_MS := 2000
const DESCRIPTION := "My Medieval Life"

var state := ""
var external := ""            # the router's outside address ("" until known)
var port := 0
var _thread: Thread
var _upnp: UPNP
var _done := false
var _result := {}
var _mutex := Mutex.new()


## Start mapping `game_port` in the background. Poll `poll()` each frame (or read `state` after `wait()`).
func start(game_port: int) -> void:
	stop()
	port = game_port
	state = "checking"
	external = ""
	_done = false
	_thread = Thread.new()
	_thread.start(_work.bind(game_port))


func _work(game_port: int) -> void:
	var u := UPNP.new()
	var r := {"state": "no_router", "external": "", "upnp": null}
	if u.discover(SEARCH_MS, 2, "InternetGatewayDevice") == UPNP.UPNP_RESULT_SUCCESS and u.get_gateway() != null and u.get_gateway().is_valid_gateway():
		var ext := u.query_external_address()
		r.external = ext
		if u.add_port_mapping(game_port, game_port, DESCRIPTION, "UDP", 0) == UPNP.UPNP_RESULT_SUCCESS:
			r.upnp = u
			r.state = "mapped" if NetInvite.classify(ext) == "public" else "shared"
		else:
			r.state = "shared" if ext != "" and NetInvite.classify(ext) != "public" else "refused"
	_mutex.lock()
	_result = r
	_done = true
	_mutex.unlock()


## Take the thread's answer when it has one. True when `state` just changed.
func poll() -> bool:
	if _thread == null:
		return false
	_mutex.lock()
	var done := _done
	_mutex.unlock()
	if not done:
		return false
	_thread.wait_to_finish()
	_thread = null
	state = str(_result.state)
	external = str(_result.external)
	_upnp = _result.upnp
	return true


## Remove the mapping (if one was made) and forget the answer. Waits for a search still running.
func stop() -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null
		_upnp = _result.get("upnp")
	if _upnp != null:
		_upnp.delete_port_mapping(port, "UDP")
		_upnp = null
	_result = {}
	state = ""
	external = ""


## Whether the invite code may name the public address: only when the router mapped the port on a real public address.
func reachable_outside() -> bool:
	return state == "mapped" and NetInvite.classify(external) == "public"
