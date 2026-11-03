extends SceneTree
## REGION-NAV-01 S3 (plan AD-4, approved 2026-11-02): the remaining acceptance tests of villager long-distance travel.
##   arrival day deterministic  two worlds from the same seed, the same traveller and the same start arrive on the same day, at
##                              the same minute and cell, and no sooner than the road's length at the walking speed allows
##   a blocked route            a route with no path between its nodes (Overworld.close_node) fails the journey, which is
##                              recorded, and the traveller turns home along the road they came by
##   death mid-journey          what a traveller carries is conserved: slain on the road, it lies where they fell (loot);
##                              dying of other causes, it passes to the heir; either way the journey ends and is counted
## Pure World. Run headless:
##   godot --headless --path game --script res://tests/journey_s3_test.gd

const Census := preload("res://tests/census.gd")

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _adult(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.home != "" and n.job != "sage" and n.job != "guard":
			return n
	return null


func _run(w: World, cond: Callable, max_minutes: float) -> bool:
	var until := w.minutes + max_minutes
	while w.minutes < until:
		w.update(0.5)
		if cond.call():
			return true
	return false


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 6.0 * 60.0 + 30.0               # day 1, 6:30
	return w


## One trip to Wulstead: {day, minute, cell, start} at the moment of arrival ({} if they never arrive).
func _trip() -> Dictionary:
	var w := _world()
	var n := _adult(w)
	var start := w.minutes
	if Journeys.start(w, n, "wulstead", {"kind": "visit"}) != "":
		return {}
	if not _run(w, func() -> bool: return str(n.journey.get("leg", "")) == "there", 5 * 1440.0):
		return {}
	return {"day": w.day(), "minute": w.minutes, "cell": n.cell(), "start": start, "world": w, "n": n}


func _init() -> void:
	# --- arrival day deterministic ---
	var a := _trip()
	var b := _trip()
	check(not a.is_empty() and not b.is_empty(), "the traveller reaches Wulstead in both runs")
	if not a.is_empty() and not b.is_empty():
		check(int(a.day) == int(b.day) and is_equal_approx(float(a.minute), float(b.minute)) and a.cell == b.cell,
			"the same seed and start give the same arrival: day %d, minute %.1f, cell %s (and %d, %.1f, %s)" % [int(a.day), float(a.minute), a.cell, int(b.day), float(b.minute), b.cell])
		var w: World = a.world
		var road := w.map.overworld.road_route(Journeys.gate_index(w), "wulstead")
		var walk := float(GameData.b("walk_tiles_per_second")) / float(GameData.b("game_minutes_per_second"))
		check(float(a.minute) - float(a.start) >= float(road.size()) / walk,
			"no sooner than the road allows: %.0f minutes on the way, the %d-tile road takes at least %.0f" % [float(a.minute) - float(a.start), road.size(), float(road.size()) / walk])
	# --- a blocked route fails and the traveller turns home ---
	var w := _world()
	var ow: Overworld = w.map.overworld
	var n := _adult(w)
	check(Journeys.start(w, n, "wulstead", {"kind": "visit"}) == "", "%s sets off for Wulstead" % n.name)
	var wul: Dictionary = ow.site("wulstead")
	check(_run(w, func() -> bool: return n.pos.y > float(wul.center.y) / 3.0, 2 * 1440.0), "a third of the way down the road (at %s)" % n.cell())
	for nd in (ow._site_end("wulstead").nodes as Dictionary).keys():
		ow.close_node(nd)                                  # every road into Wulstead is blocked
	check(ow.road_route(Journeys.gate_index(w), "wulstead").is_empty(), "with its roads closed there is no route to Wulstead")
	var other: NPC = null
	for m: NPC in w.npcs:
		if m != n and m.alive and m.role == "adult" and m.household >= 0 and m.home != "" and m.job != "guard":
			other = m
			break
	check(other != null and Journeys.start(w, other, "wulstead", {"kind": "visit"}) != "", "a journey that cannot find its road is refused at the start")
	var failed0 := float(w.stats.get("journey_failed_no_road", 0.0))
	check(_run(w, func() -> bool: return str(n.journey.get("leg", "")) == "back", 120.0) and bool(n.journey.get("failed", false)),
		"the traveller already on the road finds the way blocked and turns back")
	check(float(w.stats.get("journey_failed_no_road", 0.0)) > failed0, "the failure is recorded (journey_failed_no_road)")
	var far := n.pos.y
	var home := _run(w, func() -> bool: return not Journeys.active(n), 3 * 1440.0)
	check(home and w.map.in_village(n.cell()), "they walk home and the journey is over (at %s, day %d)" % [n.cell(), w.day()])
	check(float(w.stats.get("journey_ended_turned_back", 0.0)) == 1.0 and float(w.stats.get("journey_arrived_wulstead", 0.0)) == 0.0,
		"counted as turned back, never as arrived (from %.0f tiles down the road)" % far)
	for nd in (ow._site_end("wulstead").nodes as Dictionary).keys():
		ow.close_node(nd, false)
	check(not ow.road_route(Journeys.gate_index(w), "wulstead").is_empty(), "the roads opened again, the route is found again")
	# --- death mid-journey conserves what is carried ---
	for slain in [true, false]:
		var w2 := _world()
		var t := _adult(w2)
		t.inv.add("nails", 3)
		var coins0 := w2.total_coins() - w2.coin_sources
		var nails0 := int(Census.goods(w2).get("nails", 0))
		var carried_nails := t.inv.count("nails")
		var carried_coins := t.coins
		Journeys.start(w2, t, "wulstead", {"kind": "visit"})
		_run(w2, func() -> bool: return not w2.map.in_village(t.cell()) and t.pos.y > float(w2.map.overworld.site("wulstead").center.y) / 4.0, 2 * 1440.0)
		var at := t.pos
		var loot0 := w2.loot.size()
		w2.kill(t, "slain by a bandit" if slain else "a fever")
		var how := "slain on the road" if slain else "dead of a fever on the road"
		check(not t.alive and not Journeys.active(t) and float(w2.stats.get("journey_ended_died", 0.0)) == 1.0, "%s: the journey ends with them, counted" % how)
		check(w2.total_coins() - w2.coin_sources == coins0, "%s: no coin made or lost (%d carried)" % [how, carried_coins])
		check(int(Census.goods(w2).get("nails", 0)) == nails0, "%s: the %d nails they carried are still in the world" % [how, carried_nails])
		if slain:
			var l: Dictionary = w2.loot[w2.loot.size() - 1] if w2.loot.size() > loot0 else {}
			check(not l.is_empty() and (l.pos as Vector2).distance_to(at) < 0.01 and (l.inv as Inventory).count("nails") == carried_nails and int(l.coins) == carried_coins,
				"slain: what they carried lies where they fell on the road (%s)" % str(l.get("pos", "-")))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
