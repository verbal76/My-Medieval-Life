extends SceneTree
## REGION-NAV-01 S3 (Journeys): a villager walks the road to a neighbouring settlement and back in the world's own movement: they
## leave by the south gate, are on the road (not teleported) day by day, rest at night, arrive at the site, stay till the next
## morning and come home; a save made on the road loads and the journey goes on from where they stand; coins and goods are
## unchanged by the journey; a place with no road fails and is recorded. Pure World. Run headless:
##   godot --headless --path game --script res://tests/journey_test.gd

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


## Step the world in half-second ticks until `cond` holds or `max_minutes` of game time pass; returns whether it held.
func _run(w: World, cond: Callable, max_minutes: float) -> bool:
	var until := w.minutes + max_minutes
	while w.minutes < until:
		w.update(0.5)
		if cond.call():
			return true
	return false


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 6.0 * 60.0 + 30.0               # day 1, 6:30
	var n := _adult(w)
	n.inv.add("bread", 4)
	var coins0 := w.total_coins() - w.coin_sources
	var bread0 := n.inv.count("bread")
	check(Journeys.start(w, n, "nowhere", {"kind": "visit"}) != "", "a journey to a place that does not exist is refused")
	check(Journeys.start(w, n, "wulstead", {"kind": "visit"}) == "" and Journeys.active(n), "%s sets off for Wulstead" % n.name)
	check(Journeys.start(w, n, "garton", {"kind": "visit"}) != "", "one journey at a time")
	var wul: Dictionary = w.map.overworld.site("wulstead")
	var left := _run(w, func() -> bool: return not w.map.in_village(n.cell()), 600.0)
	check(left, "they walk out of the village (at %s)" % n.cell())
	# on the road: they move a step at a time, never jumping
	var tr := {"last": n.pos, "max": 0.0, "road": 0, "n": 0}          # (a lambda captures locals by value: a dictionary is shared)
	var midway := _run(w, func() -> bool:
		tr.max = maxf(float(tr.max), n.pos.distance_to(tr.last))
		tr.last = n.pos
		tr.n = int(tr.n) + 1
		if w.map.overworld.is_road(n.cell()):
			tr.road = int(tr.road) + 1
		return n.pos.y > float(wul.center.y) / 2.0, 1440.0)
	check(midway, "half way down the road (at %s)" % n.cell())
	check(int(tr.n) > 20 and float(tr.max) < 3.0, "no jump on the way: the largest move in one of %d ticks was %.2f tiles" % [int(tr.n), float(tr.max)])
	check(int(tr.road) * 10 >= int(tr.n) * 7, "they keep to the road (%d of %d ticks on road cells)" % [int(tr.road), int(tr.n)])
	# a save on the road: the journey goes on from where they stand
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var n2: NPC = w2.npc(n.id)
	check(n2 != null and Journeys.active(n2) and str(n2.journey.to) == "wulstead" and n2.pos.distance_to(n.pos) < 0.01, "saved and loaded on the road, they are still on their way to Wulstead, where they stood")
	var arrived := _run(w2, func() -> bool: return str(n2.journey.get("leg", "")) == "there", 4 * 1440.0)
	check(arrived and not w2.map.overworld.site_at(n2.cell()).is_empty(), "they arrive at Wulstead's site (day %d, at %s)" % [w2.day(), n2.cell()])
	check(float(w2.stats.get("journey_arrived_wulstead", 0.0)) == 1.0, "the arrival is counted")
	check(n2.inv.count("bread") <= bread0, "nothing was gained on the road: %d bread on arrival of the %d they set out with" % [n2.inv.count("bread"), bread0])
	# at night on the road they rest; at the site they stay till morning, then come home
	var home := _run(w2, func() -> bool: return not Journeys.active(n2), 5 * 1440.0)
	check(home and w2.map.in_village(n2.cell()), "they come home and the journey is over (day %d, at %s)" % [w2.day(), n2.cell()])
	check(float(w2.stats.get("journey_ended_home", 0.0)) == 1.0, "the end is counted")
	check(w2.total_coins() - w2.coin_sources == coins0, "the journey moved no coin")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
