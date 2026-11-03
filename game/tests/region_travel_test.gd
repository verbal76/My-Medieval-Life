extends SceneTree
## Build 25 Revision 1 (owner directive 2026-11-03, sections 1-4; B25R1-003, -004, -005, -006), checked in the real game scene,
## headless:  godot --headless --path game --script res://tests/region_travel_test.gd
##  - every settlement is on the Region map from day 1, named, with no place learned; the roads are drawn from the real road
##    network (every cell drawn is a road cell of the world), both kinds, joining the village to every settlement;
##  - a landmark found on foot keeps its icon through a save and a load (an older save without the key loads with none);
##  - tap anywhere: a route prefers the roads, the character really walks it (time and hunger go on), manual input suspends it
##    and keeps the destination, Resume plans again from where the player is, Dismiss clears it, a save keeps the destination
##    and a load plans it again, a point that cannot be reached is refused, a route that cannot progress gives up;
##  - on the map, a drag or a pinch never chooses a destination, a tap does.

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		printerr("FAIL: " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("new_game"):
		print("FAIL the game's main script did not load: stopping")
		quit(1)
		return
	main.save_path = "user://test_saves/region_travel_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _frames(n: int, dt := 0.1) -> void:
	for i in n:
		main._process(dt)


func _run() -> void:
	main.set_process(false)
	main.new_game()
	main.ui.hide_all()
	_known_from_day_one()
	_roads()
	_landmarks()
	_route_prefers_road()
	_walk_interrupt_resume_dismiss()
	_save_load()
	_to_wulstead()
	_refused()
	await _map_input()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _south_gate() -> Dictionary:
	for e in main.map.exits():
		if int(e.side) == 2:
			return e
	return main.map.exits()[0]


# ------------------------------------------------------------------ B25R1-003 ------------------
func _known_from_day_one() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var ow: Overworld = w.map.overworld
	check(ow.sites.size() == 5, "the world has its five settlements (%d)" % ow.sites.size())
	check(p.places.is_empty(), "day 1: the player has been told of no place (Atlas.places empty)")
	var net := RegionMapPanel.settlement_network(w)
	var b := RegionMapPanel.region_bounds(w, p)
	var inside := 0
	for st in ow.sites:
		if net.encloses(st.rect) and b.encloses(st.rect):
			inside += 1
	check(inside == ow.sites.size(), "day 1: every settlement lies inside the map the Region view opens on (%d of %d)" % [inside, ow.sites.size()])
	check(RegionTravel.bearing(Vector2(60, 45), Vector2(60, 45 + 240)) == "20 mi S", "distance and direction: 240 tiles south reads 20 mi S (%s)" % RegionTravel.bearing(Vector2(60, 45), Vector2(60, 285)))
	check(RegionTravel.bearing(Vector2(0, 0), Vector2(-60, -60)).ends_with("NW"), "eight directions: up and left is NW")


# ------------------------------------------------------------------ B25R1-004 ------------------
func _roads() -> void:
	var ow: Overworld = main.world.map.overworld
	var segs := RegionRoads.segments(ow, RegionMapPanel.settlement_network(main.world))
	var kinds := {}
	var sampled := 0
	var off := 0
	for s in segs:
		kinds[RegionRoads.kind_of(ow, s)] = true
		var cells: PackedInt32Array = s.cells
		var n := cells.size() / 2
		for q in [0, n / 2, n - 1]:
			var c := Vector2i(cells[q * 2], cells[q * 2 + 1])
			if ow.village.has_point(c):
				continue
			sampled += 1
			if not ow.is_road(c) or ow.is_solid(c):
				off += 1
	check(segs.size() > 30, "the region's road network is listed from the road data (%d segments)" % segs.size())
	check(kinds.has("road") and kinds.has("trail"), "both kinds are there: roads between the places and trails (%s)" % str(kinds.keys()))
	check(sampled > 60 and off == 0, "every road drawn on the map is a walkable road cell of the world (%d sampled, %d not)" % [sampled, off])
	var main_cells := RegionRoads.main_cells(ow)
	var gi := Journeys.gate_index(main.world)
	var joined := 0
	for st in ow.sites:
		var r := ow.road_route(gi, str(st.id))
		var on := 0
		for c in r:
			if main_cells.has(Vector2i(c)):
				on += 1
		if not r.is_empty() and on == r.size():
			joined += 1
	check(joined == ow.sites.size(), "the roads join the village to every settlement, all of it drawn as road (%d of %d)" % [joined, ow.sites.size()])


# ------------------------------------------------------------------ landmarks ------------------
func _landmarks() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var all := Landmarks.all(w)
	var mine := {}
	for lm in all:
		if lm.kind == "mine":
			mine = lm
	check(not mine.is_empty(), "the mine's entrance is a discoverable place (%d places in all)" % all.size())
	check(p.landmarks.is_empty() or not p.landmarks.has(str(mine.get("id", ""))), "not yet found at the start")
	var keep := p.pos
	p.pos = Vector2(mine.at) + Vector2(3.5, 4.5)
	w.update(0.01)
	check(p.landmarks.has(str(mine.id)), "walking near the mine entrance marks it on the map")
	check(Landmarks.known(w, p).size() >= 1, "the found place is listed for the map's icons")
	var back := PlayerState.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check(back.landmarks.has(str(mine.id)) and int(back.landmarks[str(mine.id)].x) == int(mine.at.x), "a found place survives a save and a load")
	var old := p.to_dict()
	old.erase("landmarks")
	old.erase("travel")
	var older := PlayerState.from_dict(old)
	check(older.landmarks.is_empty() and older.travel.is_empty(), "an older save (no landmarks, no travel) loads with none")
	p.pos = keep
	w.update(0.01)


# ------------------------------------------------------------------ B25R1-006 ------------------
## A road cell `along` cells down the south road towards Wulstead, and a point `side` tiles off it on open ground.
func _road_point(along: int) -> Vector2i:
	var ow: Overworld = main.world.map.overworld
	var r := ow.road_route(Journeys.gate_index(main.world), "wulstead")
	return Vector2i(r[mini(along, r.size() - 1)])


func _open_beside(c: Vector2i, side: int) -> Vector2i:
	var w: World = main.world
	for d in range(side, side + 12):
		for o in [Vector2i(d, 0), Vector2i(-d, 0), Vector2i(0, d), Vector2i(0, -d)]:
			var t: Vector2i = c + o
			if not w.map.is_solid_world(t) and not w.map.overworld.is_road(t) and RegionTravel.walkable(w, c, t):
				return t
	return c


func _route_prefers_road() -> void:
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var from := Vector2i(w.player.pos.floor())
	var wul: Dictionary = ow.site("wulstead")
	var r := RegionTravel.plan(w, from, Vector2i(wul.slots[0].spot))
	check(bool(r.ok), "a route from home to Wulstead is planned (%s)" % str(r.get("why", "")))
	if bool(r.ok):
		var cells: PackedVector2Array = r.cells
		check(not bool(r.direct) and int(r.road) * 10 >= cells.size() * 8, "it follows the road: %d of %d waypoints on road" % [int(r.road), cells.size()])
		check(int(r.get("main", 0)) * 10 >= cells.size() * 7, "on the road between the places (%d of %d)" % [int(r.get("main", 0)), cells.size()])
		var again := RegionTravel.plan(w, from, Vector2i(wul.slots[0].spot))
		check(again.cells == r.cells, "the same route every time (deterministic)")
	# a point off the road far down it: the route goes by road, then leaves it for the point
	var far := _open_beside(_road_point(220), 6)
	var r2 := RegionTravel.plan(w, from, far)
	check(bool(r2.ok) and not bool(r2.direct) and int(r2.road) > 60,   # B25R1-018: the road bends away from the point sooner
		 "a point off the road far away: by road, then off it (%d road cells)" % int(r2.get("road", 0)))
	if bool(r2.ok):
		var last: Vector2 = r2.cells[r2.cells.size() - 1]
		check(Vector2i(last) == far, "the route ends at the point itself")


func _walk_interrupt_resume_dismiss() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var dest := _open_beside(_road_point(40), 4)
	var why: String = main.travel.start(main, dest)
	check(why == "" and RegionTravel.active(p), "a destination is chosen and the character sets off (%s)" % why)
	var t0 := w.minutes
	var h0 := p.hunger
	var start := p.pos
	_frames(60)
	check(p.pos.distance_to(start) > 15.0, "the character walks in the world (%.1f tiles in 6 s)" % p.pos.distance_to(start))
	check(w.minutes > t0, "time goes on while travelling")
	check(p.hunger <= h0, "hunger goes on while travelling (%.2f -> %.2f)" % [h0, p.hunger])
	check(main.move_to != Vector2.INF, "by the game's own walking (move_to set ahead on the route)")
	# manual input suspends, the destination stays
	Input.action_press("move_left")
	_frames(1)
	Input.action_release("move_left")
	check(RegionTravel.has_destination(p) and not RegionTravel.active(p), "a movement key suspends auto-travel and keeps the destination")
	var here := p.pos
	_frames(20)
	check(p.pos.distance_to(here) < 0.5, "suspended: the character no longer walks on its own")
	# a tap on the ground suspends too
	why = main.travel.resume(main)
	check(why == "" and RegionTravel.active(p), "Resume sets off again (%s)" % why)
	check(main.travel.route.size() > 0 and Vector2(main.travel.route[0]).distance_to(p.pos) < 2.0, "Resume plans again from where the player stands")
	main.move_to = p.pos + Vector2(2, 0)
	_frames(1)
	check(not RegionTravel.active(p) and RegionTravel.has_destination(p), "a tap on the ground suspends it too, the destination kept")
	main.travel.resume(main)
	var n := 0
	while RegionTravel.has_destination(p) and n < 900:
		_frames(1)
		n += 1
	check(not RegionTravel.has_destination(p), "the character arrives and the journey ends (%d frames)" % n)
	check(p.pos.distance_to(Vector2(dest) + Vector2(0.5, 0.5)) < 2.5, "at the chosen point (%.1f tiles off)" % p.pos.distance_to(Vector2(dest) + Vector2(0.5, 0.5)))
	# dismiss
	main.travel.start(main, _road_point(10))
	main.travel.dismiss(main)
	check(not RegionTravel.has_destination(p) and main.travel.route.is_empty(), "Dismiss clears the destination and the route")
	_frames(5)
	check(not RegionTravel.has_destination(p), "and nothing walks on")


## The whole way to a neighbouring settlement: out of the village, along the road, into its site.
func _to_wulstead() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var st: Dictionary = w.map.overworld.site("wulstead")
	var why: String = main.travel.start(main, Vector2i(st.slots[0].spot))
	check(why == "", "travel to Wulstead from where the player stands (%s)" % why)
	var t0 := w.minutes
	var n := 0
	while RegionTravel.has_destination(p) and n < 3000:
		_frames(1)
		n += 1
	check(not RegionTravel.has_destination(p) and not w.map.overworld.site_at(Vector2i(p.pos.floor())).is_empty(),
		"the character walks all the way into Wulstead (%d frames, %.0f game minutes)" % [n, w.minutes - t0])


func _save_load() -> void:
	var p: PlayerState = main.world.player
	var dest := _open_beside(_road_point(60), 5)
	main.travel.start(main, dest)
	_frames(10)
	check(main.save_game(false), "saved while travelling")
	var d := SaveStore.inspect(main.save_path, World.SAVE_VERSION)
	main._load_save(d.data)
	main.ui.hide_all()
	var q: PlayerState = main.world.player
	check(q != p and RegionTravel.destination(q) == dest and RegionTravel.active(q), "the destination and travel state come back from the save")
	_frames(1)
	check(main.travel.route.size() > 0 and Vector2(main.travel.route[0]).distance_to(q.pos) < 2.0, "after the load the route is planned again from where the player stands")
	var before := q.pos
	_frames(30)
	check(q.pos.distance_to(before) > 5.0, "and the character walks on")
	main.travel.dismiss(main)


func _refused() -> void:
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var from := Vector2i(w.player.pos.floor())
	# a mountain top, inside its rim: open ground but out of reach without steps
	var top := Vector2i(1 << 30, 0)
	for r in range(2, 12):
		for cy in range(-r, r + 1):
			for cx in range(-r, r + 1):
				if top.x != 1 << 30 or maxi(absi(cx), absi(cy)) != r:
					continue
				var cc := Overworld.chunk_of(from) + Vector2i(cx, cy)
				if ow.chunk_in_village(cc):
					continue
				var ch := ow.get_chunk(cc)
				for i in ch.top.size():
					var c := cc * Overworld.CHUNK + Vector2i(i % Overworld.CHUNK, i / Overworld.CHUNK)
					if ch.top[i] == 1 and not ow.is_solid(c) and ow.is_top(c):
						var ok := true
						for dy in range(-RegionTravel.SNAP, RegionTravel.SNAP + 1):
							for dx in range(-RegionTravel.SNAP, RegionTravel.SNAP + 1):
								if not ow.is_top(c + Vector2i(dx, dy)) and not ow.is_solid(c + Vector2i(dx, dy)):
									ok = false
						if ok:
							top = c
							break
	check(top.x != 1 << 30, "a mountain top to test was found")
	if top.x != 1 << 30:
		var r := RegionTravel.plan(w, from, top)
		check(not bool(r.ok), "a point on a mountain top, out of reach, is refused (%s)" % str(r.get("why", "")))
		var why: String = main.travel.start(main, top)
		check(why != "" and not RegionTravel.has_destination(w.player), "and choosing it sets no destination")
	# below ground: no travel
	var keep: int = w.player_level
	w.player_level = -1
	check(not bool(RegionTravel.plan(w, from, _road_point(20)).ok), "below ground the map does not send you travelling")
	w.player_level = keep
	# bounded attempts: a route whose way is shut gives up with a message, never retries for ever
	var p: PlayerState = w.player
	var dest := _road_point(80)
	main.travel.start(main, dest)
	var stuck := p.pos
	var n := 0
	while RegionTravel.active(p) and n < 400:
		p.pos = stuck                               # held fast (as if walled in): no progress at all
		main._player_step(0.1)
		n += 1
	check(not RegionTravel.active(p) and RegionTravel.has_destination(p), "no progress: the journey gives up after bounded attempts (%d frames), the destination kept" % n)
	check(n >= int(TravelDriver.ATTEMPTS * TravelDriver.WATCH / 0.1) - 2 and n < 400, "after planning again %d times, not at the first check and not never" % (TravelDriver.ATTEMPTS - 1))
	main.travel.dismiss(main)


# ------------------------------------------------------------------ B25R1-005 ------------------
func _map_input() -> void:
	var p: PlayerState = main.world.player
	main.ui.show_map("region")
	for i in 4:
		await process_frame
	var r: RegionMapPanel = main.ui.panel_body.find_children("*", "RegionMapPanel", true, false)[0] if not main.ui.panel_body.find_children("*", "RegionMapPanel", true, false).is_empty() else null
	check(r != null, "the Region view opens")
	if r == null:
		return
	r._process(0.0)
	check(r.fitted and r.size.y > 300.0 and r.size.x > 600.0, "the map fills the window (%s)" % str(r.size))
	var net := Rect2(RegionMapPanel.settlement_network(main.world))
	var tl := r.to_screen(net.position)
	var br := r.to_screen(net.end)
	check(tl.x >= -1 and tl.y >= -1 and br.x <= r.size.x + 1 and br.y <= r.map_size().y + 1, "it opens zoomed out on the whole settlement network")
	var z0 := r.zoom
	var c0 := r.centre
	# a drag: never a destination
	var press := r.size / 2.0
	_mouse(r, press, true)
	_motion(r, press + Vector2(40, 30), Vector2(40, 30))
	_mouse(r, press + Vector2(40, 30), false)
	check(not RegionTravel.has_destination(p) and r.centre != c0, "a drag pans the map and chooses nothing")
	# a pinch: zooms, never a destination
	_touch(r, 0, press - Vector2(50, 0), true)
	_mouse(r, press - Vector2(50, 0), true)
	_touch(r, 1, press + Vector2(50, 0), true)
	var dr := InputEventScreenDrag.new()
	dr.index = 1
	dr.position = press + Vector2(150, 0)
	r._gui_input(dr)
	_touch(r, 1, press + Vector2(150, 0), false)
	_touch(r, 0, press - Vector2(50, 0), false)
	_mouse(r, press - Vector2(50, 0), false)
	check(r.zoom > z0 * 1.5 and not RegionTravel.has_destination(p), "a pinch zooms in (%.2f -> %.2f) and chooses nothing" % [z0, r.zoom])
	# the wheel
	var z1 := r.zoom
	var wh := InputEventMouseButton.new()
	wh.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wh.pressed = true
	wh.position = press
	r._gui_input(wh)
	check(r.zoom < z1, "the mouse wheel zooms out")
	r.centre_on_player()
	check(r.centre == p.pos, "Centre on me centres the map on the player")
	# a tap: travel there; the window closes
	var target := _open_beside(_road_point(30), 3)
	var at := r.to_screen(Vector2(target) + Vector2(0.5, 0.5))
	_mouse(r, at, true)
	_mouse(r, at + Vector2(3, 2), false)
	check(RegionTravel.active(p) and RegionTravel.destination(p).distance_to(target) <= 1.5, "a tap chooses that point and the character sets off")
	check(not main.ui.panel.visible, "the map closes when travel starts")
	main.travel.dismiss(main)


func _mouse(r: Control, at: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = at
	r._gui_input(e)


func _motion(r: Control, at: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.relative = rel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	r._gui_input(e)


func _touch(r: Control, i: int, at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = at
	e.pressed = down
	r._gui_input(e)
