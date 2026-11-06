class_name TravelDriver
extends RefCounted
## B25R1-006 (owner directive 2026-11-03, section 4): walks the player to the destination chosen on the Region map
## (RegionTravel), through the real world. It only sets Main's move_to a few tiles ahead along the planned route, so the
## character walks by the game's own walking (Main._route_step, the pathfinder, collisions, speed, sprint, carts) while the
## world goes on (time, hunger, weather, animals, hostile encounters). The camera follows the player as on any walk.
##
## Manual control at any moment: a movement key, stick or d-pad, a tap or click on the ground, a villager, an animal or a
## thing, work begun, a fight, anything that takes the player's feet, suspends the journey at once; the destination stays
## (PlayerState.travel) until Resume (planned again from where the player stands) or Dismiss (cleared). A route that makes no
## progress is planned again from where the player stands, at most ATTEMPTS times in a row; then the journey is suspended with
## a message (never an endless retry against blocked ground). The route is not saved: after a load it is planned again.

const AHEAD := 12               # tiles ahead along the road the next walking target is set
const REACHED := 1.6            # a waypoint this close is passed
const WATCH := 4.0              # seconds of walking between progress checks
const ATTEMPTS := 3             # plans in a row that make no progress before giving up

var route := PackedVector2Array()
var idx := 0
var set_to := Vector2.INF       # the move_to this driver last set
var attempts := 0
var watch_t := 0.0
var watch_pos := Vector2.ZERO
var watch_idx := 0
var watch_d := INF              # B25R2: the distance to the walk's target at the last progress check
var world_id := 0


func reset() -> void:
	route = PackedVector2Array()
	watch_d = INF
	idx = 0
	set_to = Vector2.INF
	attempts = 0
	watch_t = 0.0
	watch_idx = 0


## Plan the route from where the player stands. "" when planned, else why not.
func replan(m) -> String:
	var p: PlayerState = m.world.player
	var r := RegionTravel.plan(m.world, Vector2i(p.pos.floor()), RegionTravel.destination(p))
	_stop_own_walk(m)                              # the walk this driver set is its own, not the player's
	reset()
	if not bool(r.ok):
		return str(r.why)
	route = r.cells
	idx = 1
	watch_idx = idx
	watch_pos = p.pos
	return ""


## Choose a destination (a tap on the Region map) and set off. "" when on the way, else why not (nothing changes).
func start(m, cell: Vector2i) -> String:
	var w: World = m.world
	var r := RegionTravel.choose(w, w.player, cell)
	if w.recorder != null:                         # B25R1-016: the player's journeys (set or refused, the route's length and road share)
		var why_code := str(r.get("reason", "unreachable"))
		if not bool(r.ok) and why_code.begins_with("water"):
			w.recorder.chronicle("travel_blocked_by_water", w.player, {"destination": "cell:%d,%d" % [cell.x, cell.y], "outcome": "failed",
				"reason": "no_crossing", "detail": why_code, "x": cell.x, "y": cell.y})       # B25R1-017: refused because of water
		if bool(r.ok):
			var xs := WaterNotes.route_crossings(w, r.cells)
			if int(xs.bridges) + int(xs.fords) > 0:          # B25R1-017: a route choice that crosses water
				w.recorder.chronicle("route_crossing", w.player, {"destination": "cell:%d,%d" % [cell.x, cell.y], "object": str(xs.first),
					"needs": {"bridges": int(xs.bridges), "fords": int(xs.fords), "road_cells": int(r.get("road", 0)), "waypoints": (r.cells as PackedVector2Array).size()},
					"chosen": WaterNotes.chosen(xs), "alternatives": [["bridge", int(xs.bridges) > 0, int(xs.bridges), ""], ["ford", int(xs.fords) > 0, int(xs.fords), ""]]})
		w.recorder.chronicle("travel_destination_set" if bool(r.ok) else "travel_refused", w.player, {"destination": "cell:%d,%d" % [cell.x, cell.y],
			"place": RegionTravel.place_name(w, w.player, cell), "outcome": "ok" if bool(r.ok) else "refused", "reason": "" if bool(r.ok) else why_code,
			"needs": {"waypoints": (r.get("cells", PackedVector2Array()) as PackedVector2Array).size(), "road_cells": int(r.get("road", 0)), "direct": bool(r.get("direct", false))},
			"detail": "" if bool(r.ok) else str(r.get("why", "")).left(160)})
	if not bool(r.ok):
		return str(r.why)
	reset()
	world_id = w.get_instance_id()
	route = r.cells
	idx = 1
	watch_idx = idx
	watch_pos = w.player.pos
	_clear_walk(m)
	if m.cam_free:
		m.recenter()
	return ""


## Resume Destination: plan again from here and walk on. "" when walking, else why not (the destination is kept).
func resume(m) -> String:
	var p: PlayerState = m.world.player
	if not RegionTravel.has_destination(p):
		return "There is no destination to go to."
	var why := replan(m)
	if why != "":
		return why
	p.travel.active = true
	world_id = m.world.get_instance_id()
	_clear_walk(m)
	if m.cam_free:
		m.recenter()
	return ""


## Dismiss Destination: the journey is cancelled, the destination and route cleared.
func dismiss(m) -> void:
	_note(m, "travel_dismissed")
	_finish(m)


## B25R1-016: the flight recorder's note of the player's journey (one guarded call; null recorder: nothing).
func _note(m, kind: String, why := "") -> void:
	var w: World = m.world
	if w == null or w.recorder == null or not RegionTravel.has_destination(w.player):
		return
	var d := RegionTravel.destination(w.player)
	w.recorder.chronicle(kind, w.player, {"destination": "cell:%d,%d" % [d.x, d.y], "place": RegionTravel.place_name(w, w.player, d),
		"needs": {"route_left": maxi(0, route.size() - idx)}, "detail": why.left(160)})


func _finish(m) -> void:
	_stop_own_walk(m)
	RegionTravel.dismiss(m.world.player)
	reset()


## Suspend: the player has taken control (or the way is blocked). The destination stays.
func suspend(m, why := "") -> void:
	_note(m, "travel_suspended", why)
	_stop_own_walk(m)
	RegionTravel.suspend(m.world.player)
	reset()
	if why != "":
		m.ui.message(why, 6.0)


func _stop_own_walk(m) -> void:
	if set_to != Vector2.INF and m.move_to == set_to:
		m.move_to = Vector2.INF


func _clear_walk(m) -> void:
	m.move_to = Vector2.INF
	m.chase = null
	m.talk_to = null
	m.reach_to = Vector2.INF


## Whether anything but this driver has taken the player's feet this frame (`v`: the movement input).
func _manual(m, v: Vector2) -> bool:
	if v.length() > 0.1:
		return true
	if m.move_to != Vector2.INF and m.move_to != set_to:
		return true                                # a tap or click on the ground (or a walk to something tapped)
	return m.chase != null or m.talk_to != null or m.reach_to != Vector2.INF or not m.action.is_empty() or not m.gather.is_empty()


## Each frame of play (Main._player_step, before walking): suspends on manual input, else keeps move_to set along the route.
func step(m, v: Vector2, delta: float) -> void:
	var w: World = m.world
	var p: PlayerState = w.player
	if w.get_instance_id() != world_id:
		reset()                                    # another world (loaded, a new game): the route is planned again
		world_id = w.get_instance_id()
	if not RegionTravel.active(p):
		if not route.is_empty():
			reset()
		return
	if _manual(m, v):
		suspend(m, "You stop. Your destination is kept: Resume to go on, Dismiss to forget it.")
		return
	if not p.alive or w.player_level != Underground.SURFACE:
		suspend(m)
		return
	if route.is_empty():
		var why := replan(m)
		if why != "":
			_note(m, "travel_suspended", why)
			RegionTravel.suspend(p)
			m.ui.message(why, 6.0)
			return
	while idx < route.size() and p.pos.distance_to(route[idx] + Vector2(0.5, 0.5)) < REACHED:
		idx += 1
	# a waypoint further on reached first (the walk cut a corner the road doubles back round, as where a side road joins
	# a road and turns back along it): go on from there, or the walk would wait for ever for the one it passed by
	for q in range(idx + 1, mini(route.size(), idx + AHEAD + 1)):
		if p.pos.distance_to(route[q] + Vector2(0.5, 0.5)) < REACHED:
			idx = q + 1
	if idx >= route.size():
		var name := RegionTravel.place_name(w, p, RegionTravel.destination(p))
		_note(m, "travel_arrived")
		_finish(m)
		m.ui.message("You have arrived at %s." % name if name != "the marked place" else "You have reached the marked place.", 5.0)
		return
	var j := idx
	var here := Vector2i(p.pos.floor())
	while j + 1 < route.size() and j - idx < AHEAD and maxi(absi(int(route[j + 1].x) - here.x), absi(int(route[j + 1].y) - here.y)) <= AHEAD:
		j += 1
	var target := route[j] + Vector2(0.5, 0.5)
	if m.move_to == Vector2.INF or (target != set_to and p.pos.distance_to(set_to) < 4.0):
		m.move_to = target
		set_to = target
	# progress: no waypoint passed and no closer to the walk's target for WATCH seconds -> plan again; ATTEMPTS times in a row ->
	# give up with a message. B25R2 (item 2): progress is coming closer to the target, not moving: sliding along a riverbank moves
	# the character without bringing it nearer, and was taken for progress for ever
	watch_t += delta
	if watch_t >= WATCH:
		watch_t = 0.0
		var dist := p.pos.distance_to(set_to) if set_to != Vector2.INF else INF
		var closer := dist < watch_d - 1.0
		watch_d = dist
		if idx == watch_idx and not closer:
			attempts += 1
			if attempts >= ATTEMPTS:
				var here_c := Vector2i(p.pos.floor())
				if w.recorder != null and w.map.overworld != null and w.map.overworld.nearest_water(here_c, 3) != Overworld.NO_WATER:
					w.recorder.chronicle("travel_blocked_by_water", p, {"outcome": "failed", "reason": "no_crossing", "detail": "blocked at the water's edge",
						"x": here_c.x, "y": here_c.y})           # B25R1-017: a walk given up at the water's edge
				suspend(m, "The way ahead is blocked. Your destination is kept: Resume to try again, or Dismiss it.")
				return
			var keep := attempts
			var why2 := replan(m)
			attempts = keep
			if why2 != "":
				suspend(m, why2)
				return
		else:
			attempts = 0
		watch_idx = idx
		watch_pos = p.pos
