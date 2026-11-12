extends SceneTree
## REG-01 (Build 25 audit, WP-1): a journey's walk is laid along the road (Journeys, go(..., pathed=true)); a save drops the
## plan's `pathed` mark and the path itself is not saved (NPC.to_dict), so after a load the leg resumes (Journeys.resume) and
## the walk may be re-found by the world's open-ground path search instead of the laid road. The audit asked whether that
## changes the route or the arrival. The test runs the same trip to Wulstead twice from the same seed: once never saved, once
## saved and loaded half way down the road; it compares, from the save on, the share of ticks on road cells, the cells walked
## (how far the loaded traveller ever is from the uninterrupted one's route) and the arrival time.
##   godot --headless --path game --script res://tests/reg01_journey_reload_route_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _adult(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.home != "" and n.job != "sage" and n.job != "guard":
			return n
	return null


func _start() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 6.0 * 60.0 + 30.0               # day 1, 6:30 (journey_test's trip)
	var n := _adult(w)
	n.inv.add("bread", 4)
	Journeys.start(w, n, "wulstead", {"kind": "visit"})
	return w


## To half way down the road (journey_test's save point).
func _to_midway(w: World, n: NPC) -> bool:
	var wul: Dictionary = w.map.overworld.site("wulstead")
	var until := w.minutes + 3 * 1440.0
	while w.minutes < until:
		w.update(0.5)
		if not w.map.in_village(n.cell()) and n.pos.y > float(wul.center.y) / 2.0:
			return true
	return false


## From here to arrival at the site: {cells (in order, one per change), road ticks, ticks, arrived minute (-1: never)}.
func _to_arrival(w: World, n: NPC) -> Dictionary:
	var out := {"cells": [], "road": 0, "n": 0, "at": -1.0}
	var until := w.minutes + 4 * 1440.0
	while w.minutes < until:
		w.update(0.5)
		var c := n.cell()
		if (out.cells as Array).is_empty() or out.cells.back() != c:
			out.cells.append(c)
		out.n = int(out.n) + 1
		if w.map.overworld.is_road(c):
			out.road = int(out.road) + 1
		if str(n.journey.get("leg", "")) == "there":
			out.at = w.minutes
			return out
	return out


func _init() -> void:
	GameData.ensure()
	var a := _start()
	var b := _start()
	var na := _adult(a)
	var nb := _adult(b)
	check(Journeys.active(na) and Journeys.active(nb), "fixture: both worlds' traveller sets off for Wulstead")
	check(_to_midway(a, na) and _to_midway(b, nb), "fixture: both reach half way down the road")
	check(na.pos.distance_to(nb.pos) < 0.01 and absf(a.minutes - b.minutes) < 0.01, "fixture: the two worlds are the same at the save point (%s, %s)" % [na.cell(), nb.cell()])
	var b2 := World.new()
	b2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(b.to_dict(), "", true, true)))
	var nb2: NPC = b2.npc(nb.id)
	check(nb2 != null and Journeys.active(nb2) and nb2.pos.distance_to(na.pos) < 0.01, "saved and loaded on the road, still on the way, where they stood")
	var ra := _to_arrival(a, na)
	var rb := _to_arrival(b2, nb2)
	check(float(ra.at) >= 0.0 and float(rb.at) >= 0.0, "both arrive at Wulstead (never saved at minute %.0f, saved and loaded at %.0f)" % [float(ra.at), float(rb.at)])
	var far := 0.0
	for c in rb.cells:
		var best := 1e9
		for c2 in ra.cells:
			best = minf(best, Vector2(c).distance_to(Vector2(c2)))
		far = maxf(far, best)
	print("REG-01 measurement: road ticks %d of %d never saved, %d of %d saved and loaded; the loaded walk is at most %.1f tiles from the uninterrupted route; arrival %.0f vs %.0f game minutes" % [
		int(ra.road), int(ra.n), int(rb.road), int(rb.n), far, float(ra.at), float(rb.at)])
	check(int(rb.road) * int(ra.n) * 10 >= int(ra.road) * int(rb.n) * 9, "after the load they keep to the road as much as the uninterrupted trip (within a tenth)")
	check(far <= 3.0, "after the load they walk the same route (never more than 3 tiles from it: %.1f)" % far)
	check(absf(float(rb.at) - float(ra.at)) <= 60.0, "after the load they arrive when the uninterrupted traveller does (within an hour: %.0f minutes apart)" % absf(float(rb.at) - float(ra.at)))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
