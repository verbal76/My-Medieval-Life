extends SceneTree
## REGION-NAV-01 S8 (plan): the regional systems in the running game. Acceptance (plan, S8): determinism (two runs); save
## mid-mission; the item and currency ledgers (the item ledger over a year: economy_sim's LEAKS line, with the REGION line). The
## desktop cost is measured with economy_sim against the baseline (docs); the Android figure is a device check (LE-07 gate 11). Pure World.
## Run headless:
##   godot --headless --path game --script res://tests/region_sim_test.gd

const DAYS := 8

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func coin_gap(w: World) -> int:
	return w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village())


func _state(w: World) -> String:
	var parts := PackedStringArray([str(w.minutes), str(w.treasury), str(w.coin_sources), str(w.rng.state), JSON.stringify(w.intel_book)])
	for n: NPC in w.npcs:
		parts.append("%d|%s|%d|%s|%s|%s|%s" % [n.id, n.alive, n.coins, n.pos, JSON.stringify(n.journey), n.inv.items, n.intel.size()])
	parts.append(JSON.stringify(w.regions.to_dict()))
	return "|".join(parts).md5_text()


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _days(w: World, days: float) -> float:
	var t := Time.get_ticks_msec()
	var until := w.minutes + days * 1440.0
	while w.minutes < until:
		w.update(0.5)
	return float(Time.get_ticks_msec() - t)


func _envoy(w: World) -> NPC:
	for j in w.manor_work.jobs:
		if str(j.kind) == "envoy" and str(j.taker) != "":
			var n := w.npc(int(str(j.taker).substr(4)))
			if n != null and Journeys.active(n):
				return n
	return null


func _init() -> void:
	# determinism: two runs of the same seed are the same, regional systems included
	var a := _world()
	var gap0 := coin_gap(a)
	_days(a, DAYS)
	var b := _world()
	_days(b, DAYS)
	var st := func(w: World, k: String) -> int: return int(w.stats.get(k, 0.0))
	check(st.call(a, "envoy_posted") > 0 and st.call(a, "journey_started") > 0, "in %d days the reeve posts envoys and villagers travel (%d posted, %d journeys, %d interviews)" % [DAYS, st.call(a, "envoy_posted"), st.call(a, "journey_started"), st.call(a, "envoy_interviews")])
	check(_state(a) == _state(b), "two runs of seed 1 for %d days end in the same state, the regional systems included" % DAYS)
	check(coin_gap(a) == gap0 and a.regions.audit() == "", "the currency ledger balances across the village's boundary (gap %d, was %d) and every settlement's books" % [coin_gap(a), gap0])
	# save mid-mission (a world without the founding's seed travellers, B25R1-009: with them, seed 1's envoy post goes untaken
	# for the first 20 days, an outcome of the changed village, so this scenario's envoy would never set out)
	var seeds0 := int(OffMapSettlement.data().seed_travelers.count)
	OffMapSettlement.data().seed_travelers.count = 0
	var w := _world()
	OffMapSettlement.data().seed_travelers.count = seeds0
	var until := w.minutes + 20.0 * 1440.0
	while w.minutes < until and _envoy(w) == null:
		w.update(0.5)
	var e := _envoy(w)
	check(e != null, "an envoy is on the road (%s, on day %d)" % [e.name if e else "-", w.day()])
	if e == null:
		print("%d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var d0: Dictionary = JSON.parse_string(JSON.stringify(d))
	var d1: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
	var same := true
	for k in ["intel_book", "regions", "couriers", "manor_work", "treasury", "coin_sources"]:
		same = same and JSON.stringify(d0.get(k)) == JSON.stringify(d1.get(k))
	for i in (d0.npcs as Array).size():
		for k in ["journey", "intel", "coins", "inv", "pos"]:
			same = same and JSON.stringify(d0.npcs[i].get(k)) == JSON.stringify(d1.npcs[i].get(k))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d1.duplicate(true))
	check(same and JSON.stringify(JSON.parse_string(JSON.stringify(w3.to_dict()))) == JSON.stringify(d1), "saved mid-mission: the reeve's book, the villagers' journeys and knowledge, the settlements, the couriers and the job board load unchanged, and a loaded world saves stably")
	var e2 := w2.npc(e.id)
	check(e2 != null and Journeys.active(e2) and str(e2.journey.get("purpose", {}).get("kind", "")) == "envoy", "the envoy is still on the mission after the load")
	var gap2 := coin_gap(w2)
	var reports0 := int(w2.stats.get("envoy_reports", 0.0))
	var done := false
	var until2 := w2.minutes + 8.0 * 1440.0
	while w2.minutes < until2 and not done:
		w2.update(0.5)
		done = int(w2.stats.get("envoy_reports", 0.0)) > reports0
	check(done and not (Envoys.book(w2).records as Array).is_empty(), "the loaded mission is finished: the envoy reports and the reeve's book has %d records" % (Envoys.book(w2).records as Array).size())
	check(coin_gap(w2) == gap2 and w2.regions.audit() == "", "the currency ledger still balances after the load (gap %d)" % coin_gap(w2))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
