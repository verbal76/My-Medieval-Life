extends SceneTree
## B25R2 playtest repair (owner directive 2026-11-06, item 2, "Riverbank autotravel"): on a long journey the automatic walk drove
## the player into a riverbank and stayed there. Causes: RegionTravel._attach joined the player (in open country: after a manual
## step, a Resume or a stuck replan) to the nearest roads by a straight leg never checked for water, the walk (Main._route_step)
## goes straight at a target the pathfinder cannot reach, sliding along what is in the way, and TravelDriver counted any movement
## as progress, so sliding along the bank was never taken for stuck.
##  1. Planning from open country beside the water (places whose straight line to the nearest road runs over the water, the
##     playtest's case), on several seeds: every hop of the route is dry (bridges and fords are crossed on foot), so the walk is
##     led to a crossing and over it, never at the bank; a journey with no way on foot is refused with a reason.
##  2. Driving: a route whose next hop is held at the bank, the walker sliding to and fro along it: the driver plans again from
##     where it stands and, with no progress, stops with a message within ATTEMPTS checks, keeping the destination; it never
##     pushes for ever.
##   godot --headless --path game -s res://tests/travel_river_test.gd

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	GameData.ensure()
	for seed in [1, 2, 7]:
		_plans(seed)
	_driver()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Whether the straight line a..b runs over water that cannot be walked (the test's own check, so it reads the same before and
## after the repair; a bridge, a ford and the shallows are walked: Overworld.is_water counts a ford).
static func _crosses(ow: Overworld, a: Vector2i, b: Vector2i) -> bool:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for k in range(0, n + 1):
		var c := Vector2i((Vector2(a).lerp(Vector2(b), k / float(maxi(1, n)))).round())
		if ow.is_water(c) and not ow.is_ford(c):
			return true
	return false


## Open cells in the country beside the water from which the straight line to the nearest road cell runs over the water.
func _riverside(w: World, limit: int) -> Array:
	var ow: Overworld = w.map.overworld
	var out := []
	var area := Rect2i(ow.village).grow(260)
	for y in range(area.position.y, area.end.y, 9):
		for x in range(area.position.x, area.end.x, 9):
			var c := Vector2i(x, y)
			if ow.village.grow(4).has_point(c) or not ow.site_at(c).is_empty() or ow.is_water(c) or w.map.is_solid_world(c):
				continue
			if ow.nearest_water(c, 5) == Overworld.NO_WATER:
				continue
			var best := Vector2i(1 << 30, 0)
			var bd := INF
			for seg in RegionRoads.segments(ow, Rect2i(c - Vector2i(40, 40), Vector2i(80, 80))):
				var sc: PackedInt32Array = seg.cells
				for k in sc.size() / 2:
					var q := Vector2i(sc[2 * k], sc[2 * k + 1])
					var d := Vector2(c).distance_to(Vector2(q))
					if d < bd:
						bd = d
						best = q
			if bd < 40.0 and _crosses(ow, c, best):
				out.append(c)
				if out.size() >= limit:
					return out
	return out


func _plans(seed: int) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var ow: Overworld = w.map.overworld
	var starts := _riverside(w, 6)
	check(not starts.is_empty(), "seed %d: places beside the water whose nearest road lies over it (%d)" % [seed, starts.size()])
	var home := Vector2(ow.village.get_center())
	var far: Vector2i = ow.sites[0].center
	for st in ow.sites:
		if Vector2(st.center).distance_to(home) > Vector2(far).distance_to(home):
			far = st.center
	var planned := 0
	var refused := 0
	var wet_hops := []
	for s in starts:
		for dest in [far, Vector2i(home)]:
			var r := RegionTravel.plan(w, s, dest)
			if not bool(r.ok):
				refused += 1
				check(str(r.get("why", "")) != "", "seed %d: a journey from %s with no way on foot says why (%s)" % [seed, str(s), str(r.get("why", ""))])
				continue
			planned += 1
			var cells: PackedVector2Array = r.cells
			for k in range(1, cells.size()):
				if _crosses(ow, Vector2i(cells[k - 1]), Vector2i(cells[k])):
					wet_hops.append("%s->%s from %s" % [str(Vector2i(cells[k - 1])), str(Vector2i(cells[k])), str(s)])
	check(planned > 0, "seed %d: journeys planned from beside the water (%d planned, %d refused)" % [seed, planned, refused])
	check(wet_hops.is_empty(), "seed %d: no hop of any route runs over the water (%d do: %s)" % [seed, wet_hops.size(), str(wet_hops.slice(0, 3))])


## A stand-in for Main: just what TravelDriver reads and writes.
class FakeMain:
	extends RefCounted
	var world: World
	var move_to := Vector2.INF
	var chase = null
	var talk_to = null
	var reach_to := Vector2.INF
	var action := {}
	var gather := {}
	var cam_free := false
	var ui = null
	var said: Array = []

	func message(t: String, _s := 0.0) -> void:
		said.append(t)

	func recenter() -> void:
		pass


func _driver() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var ow: Overworld = w.map.overworld
	var starts := _riverside(w, 12)
	var m := FakeMain.new()
	m.world = w
	m.ui = m
	var p := w.player
	var d := TravelDriver.new()
	var started := false
	for st in starts:                                  # a place beside the water from which the journey is planned
		p.pos = Vector2(st) + Vector2(0.5, 0.5)
		d = TravelDriver.new()
		if d.start(m, Vector2i(ow.sites[0].center)) == "":
			started = true
			break
	check(started, "driver: a journey planned from beside the water (of %d places)" % starts.size())
	if not started:
		return
	# the walker is held at the bank: it slides to and fro along it and never comes nearer the target
	var t := 0.0
	var gave_up := false
	var base := p.pos
	while t < 60.0:
		p.pos = base + Vector2(sin(t * 3.0) * 1.5, 0.0)
		d.step(m, Vector2.ZERO, 0.25)
		t += 0.25
		if not RegionTravel.active(p):
			gave_up = true
			break
	var bound := TravelDriver.WATCH * (TravelDriver.ATTEMPTS + 1) + 1.0
	check(gave_up, "driver: sliding along the bank without coming nearer is stuck; the journey stops (after %.1f s)" % t)
	check(gave_up and t <= bound, "driver: it stops within the bounded checks (%.1f s <= %.1f s)" % [t, bound])
	check(m.said.size() > 0 and RegionTravel.has_destination(p), "driver: it says why and keeps the destination for Resume (%s)" % str(m.said))
