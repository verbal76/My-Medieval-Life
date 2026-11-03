extends SceneTree
## REGION-NAV-01 Q3 (owner 2026-11-03: approved conditionally on "verifying that the physical locations, regional distances, road
## connections, travel times, and economic geography all agree ... one consistent geographical model"): one world, one geography.
##   locations   each settlement's site in the overworld stands at its OffMapSettlement.pos from the village's centre
##   roads       a road joins the village to every settlement and every settlement to every other (Overworld.road_route/site_route)
##   distances   the regional trade's routes (Regions.route_table, village_route_table) are those roads' lengths
##   economy     the courier service's links (CourierService.links: its journey days and fees) are those same routes
##   travel      a villager's walk (Journeys) follows the same road: its walking time is that length at the walking speed
## Pure World. Run headless:
##   godot --headless --path game --script res://tests/region_geography_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	for seed_value in [1, 2]:
		_one(seed_value)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _one(seed_value: int) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	var ow: Overworld = w.map.overworld
	var gi := Journeys.gate_index(w)
	var routes := w.regions.route_table()
	var vroutes := w.regions.village_route_table()
	var links: Dictionary = w.couriers.links
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(JSON.stringify(w2.couriers.links) == JSON.stringify(links), "seed %d: after a save and load the couriers' routes are the same road lengths (validation D4)" % seed_value)
	var walk := float(GameData.b("walk_tiles_per_second")) / float(GameData.b("game_minutes_per_second"))      # tiles a game minute
	for s: OffMapSettlement in w.regions.list:
		var st: Dictionary = ow.site(s.id)
		check(st.center == ow.village.get_center() + s.pos, "seed %d %s: its site stands at its trade coordinates %s from the village's centre" % [seed_value, s.name, s.pos])
		var r := ow.road_route(gi, s.id)
		check(r.size() > 0, "seed %d %s: a road joins it to the village (%d tiles)" % [seed_value, s.name, r.size()])
		var vr: Dictionary = vroutes.get("village>" + s.id, {})
		check(int(vr.get("tiles", -1)) == r.size() and int((vroutes.get(s.id + ">village", {}) as Dictionary).get("tiles", -1)) == r.size(),
			"seed %d %s: the trade's route from the village is that road's length, both ways (%d)" % [seed_value, s.name, int(vr.get("tiles", -1))])
		var cl: Dictionary = links.get("village>" + s.id, {})
		check(int(cl.get("tiles", -1)) == r.size() and is_equal_approx(float(cl.get("days", -1.0)), float(vr.get("days", -2.0))),
			"seed %d %s: the couriers travel that same route (%d tiles, %.2f days)" % [seed_value, s.name, int(cl.get("tiles", -1)), float(cl.get("days", -1.0))])
		var minutes := float(r.size()) / walk
		check(minutes > 0.0 and minutes < 3.0 * 1440.0, "seed %d %s: a villager walking that road takes %.0f game minutes (%.1f days of walking)" % [seed_value, s.name, minutes, minutes / 1440.0])
		for t: OffMapSettlement in w.regions.list:
			if t.id == s.id:
				continue
			var sr := ow.site_route(s.id if s.id < t.id else t.id, t.id if s.id < t.id else s.id)      # the economy measures each pair once
			var back := ow.site_route(t.id, s.id)
			check(absi(back.size() - ow.site_route(s.id, t.id).size()) <= 2, "seed %d %s and %s: the shortest road is as long either way (%d, %d)" % [seed_value, s.name, t.name, ow.site_route(s.id, t.id).size(), back.size()])
			var rt: Dictionary = routes.get(s.id + ">" + t.id, {})
			check(sr.size() > 0 and int(rt.get("tiles", -1)) == sr.size() and int((routes.get(t.id + ">" + s.id, {}) as Dictionary).get("tiles", -1)) == sr.size()
				and int((links.get(s.id + ">" + t.id, {}) as Dictionary).get("tiles", -1)) == sr.size(),
				"seed %d %s to %s: a road (%d tiles), and the trade's and the couriers' route are its length both ways" % [seed_value, s.name, t.name, sr.size()])
