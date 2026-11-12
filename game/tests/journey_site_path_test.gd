extends SceneTree
## REGION-NAV-01 (Journeys; found by the simulation gate's playtest probe, B25): the road a traveller walks to a neighbouring
## settlement ends at the edge of its site, and the leg goes on to the place they came for (out) or from where they stand to
## the road (back). Those last steps are walked, not jumped: the laid path crosses no solid cell of the world (a settlement's
## building is not entered, Overworld.site_building_at). World._walk walks straight from one path point to the next, so each
## step between points is sampled. Pure World, no update run. Run headless:
##   godot --headless --path game --script res://tests/journey_site_path_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


## The solid cells the straight steps of `path` (from `from`) cross, outside the village (its own grid is its own test's).
func crossed(w: World, from: Vector2, path: PackedVector2Array) -> Array:
	var out := []
	var at := from
	for p in path:
		var to := p + Vector2(0.5, 0.5)
		var steps := maxi(1, ceili(at.distance_to(to) * 4.0))
		for i in steps + 1:
			var c := Vector2i((at + (to - at) * float(i) / float(steps)).floor())
			if not w.map.in_village(c) and w.map.is_solid_world(c) and not out.has(c):
				out.append(c)
		at = to
	return out


func longest_step(from: Vector2, path: PackedVector2Array) -> float:
	var best := 0.0
	var at := from
	for p in path:
		best = maxf(best, at.distance_to(p + Vector2(0.5, 0.5)))
		at = p + Vector2(0.5, 0.5)
	return best


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 9.0 * 60.0                     # day 1, 9:00: a time to walk, not to rest
	var adults := w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 0 and n.home != "" \
		and n.job != "sage" and n.job != "guard" and n.journey.is_empty())
	var k := 0
	for sid in ["netherton", "higham", "garton", "wulstead"]:
		var st: Dictionary = w.map.overworld.site(sid)
		if st.is_empty():
			continue
		var n: NPC = adults[k]
		k += 1
		check(Journeys.start(w, n, sid, {"kind": "visit"}) == "", "%s sets off for %s" % [n.name, st.name])
		check(Journeys.resume(w, n), "the way out to %s is laid" % st.name)
		var bad := crossed(w, n.pos, n.path)
		check(bad.is_empty(), "the way out to %s crosses no solid cell (%d crossed, e.g. %s)" % [st.name, bad.size(), str(bad.slice(0, 4))])
		check(longest_step(n.pos, n.path) < 2.0, "the way out to %s is walked a cell at a time (longest step %.1f)" % [st.name, longest_step(n.pos, n.path)])
		var spot := Vector2(st.slots[0].spot)
		check(not n.path.is_empty() and Vector2(n.path[n.path.size() - 1]) == spot, "it ends at %s's spot %s" % [st.name, str(spot)])
		# at the site, the leg home: from where they stand to the road and back to the village
		n.pos = spot + Vector2(0.5, 0.5)
		n.journey.leg = "back"
		n.plan.clear()
		check(Journeys.resume(w, n), "the way home from %s is laid" % st.name)
		bad = crossed(w, n.pos, n.path)
		check(bad.is_empty(), "the way home from %s crosses no solid cell (%d crossed, e.g. %s)" % [st.name, bad.size(), str(bad.slice(0, 4))])
		check(longest_step(n.pos, n.path) < 2.0, "the way home from %s is walked a cell at a time (longest step %.1f)" % [st.name, longest_step(n.pos, n.path)])
		check(not n.path.is_empty() and w.map.in_village(Vector2i(n.path[n.path.size() - 1])), "it ends in the village")
		Journeys.end(w, n, "test")
	check(k >= 3, "the seed's world has the settlements the probe found the travellers walking to (%d)" % k)
	w.dispose()
	print("journey_site_path_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
