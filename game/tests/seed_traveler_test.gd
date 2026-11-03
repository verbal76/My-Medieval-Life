extends SceneTree
## B25R1-009, seed travelers (owner 2026-11-03, docs/directives/2026-11-03_b25r1_seed_travelers.md): a few of the village's own
## residents set out at the founding to buy one ordinary item at another settlement (SeedTravelers). The directive's validation:
##   designated     the configured number, real residents (household, home), each with coins for the item, no duplicates, the
##                  population unchanged
##   one journey    home -> the road -> the destination's site -> one item bought from its seller in person -> home -> ordinary
##                  life; the same person throughout (id, name, household, home); the money and the good actually moved
##                  (buyer's purse and pack, seller's stock), coins conserved across the boundary, the settlements' books balance
##   save/load      saved mid-journey on the road, loaded: the same journey and person; they go on to buy and come home
##   determinism    two worlds from the same seed choose the same travellers and make the same journey (trace equal)
##   interactive    in the real main scene: a seed traveller on the road outside the village is tapped, walked up to and talked
##                  to (the talk window), and says where they are going (beside the countryside's ambient passers-by, which
##                  stay: owner 2026-11-03, "We can have them as well")
## Run headless:
##   godot --headless --path game --script res://tests/seed_traveler_test.gd

const Census := preload("res://tests/census.gd")

var failures := 0
var checks := 0
var main


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func coin_gap(w: World) -> int:
	return w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village())


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func seeds(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return Journeys.active(n) and bool(n.journey.get("purpose", {}).get("seed", false)))


## The seed traveller with the shortest road (the quickest whole journey to test).
func nearest(w: World) -> NPC:
	var best: NPC = null
	for n: NPC in seeds(w):
		if best == null or Envoys.trip_days(w, str(n.journey.to)) < Envoys.trip_days(w, str(best.journey.to)):
			best = n
	return best


## Run `w` until `cond` or `max_minutes` pass; `each` is called after every step. True when `cond` held.
func _run(w: World, cond: Callable, max_minutes: float, each := Callable()) -> bool:
	var until := w.minutes + max_minutes
	while w.minutes < until:
		w.update(0.5)
		if each.is_valid():
			each.call()
		if cond.call():
			return true
	return false


func _init() -> void:
	_test_designated()
	var trace := _test_journey()
	_test_determinism(trace)
	_test_save_mid_journey()
	_test_in_main()


func _finish() -> void:
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_designated() -> void:
	var w := _world()
	var s := seeds(w)
	check(s.size() == SeedTravelers.cfg().count, "%d seed travellers set out at the founding (settlements.json: %d)" % [s.size(), SeedTravelers.cfg().count])
	var ids := {}
	var dests := {}
	for n: NPC in s:
		ids[n.id] = true
		dests[str(n.journey.to)] = true
		var p: Dictionary = n.journey.purpose
		check(n.household >= 0 and n.home != "" and n.role == "adult" and w.by_id.get(n.id) == n, "%s %s (id %d, %s) is a resident of the village: household %d, home %s" % [n.name, n.family, n.id, n.job, n.household, n.home])
		check(int(p.qty) == 1 and int(p.price) > 0 and int(p.price) <= n.coins - w.reserve_of(n), "  goes to %s to buy one %s at %d, from their own %d coins" % [str(n.journey.to), str(p.item), int(p.price), n.coins])
		check(not str(p.about).is_empty() and w.regions.party(str(p.about)) != null and w.regions.party(str(p.about)).sale_cap(str(p.item)) >= 1, "  from a real seller there who has it (%s)" % str(p.about))
		check(not n.job in SeedTravelers.cfg().skip_jobs, "  not a post the village cannot spare (%s)" % n.job)
	check(ids.size() == s.size(), "no one is sent twice")
	var w2 := _world()
	check(w2.npcs.size() == w.npcs.size() and w.npcs.size() == w2.npcs.filter(func(n): return n.alive).size(), "the population is unchanged: %d villagers, nobody added" % w.npcs.size())
	var bands := {}
	for n: NPC in w.npcs:
		bands[n.id] = true
	check(bands.size() == w.npcs.size(), "every villager appears once (no duplicate person on the road)")
	# not forced again: a loaded world sends nobody new
	var b := World.new()
	b.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(seeds(b).size() == s.size() and int(b.stats.get("seed_travelers", 0.0)) == 0, "loading the world sends nobody more: the same %d on their errands, none designated on loading" % seeds(b).size())


## One whole journey. Returns the trace (hourly positions and legs) for the determinism check.
func _test_journey() -> Array:
	var w := _world()
	var n := nearest(w)
	var pop0 := w.npcs.size()
	var id := n.id
	var who := [n.name, n.family, n.household, n.home, n.job]
	var p: Dictionary = n.journey.purpose
	var item := str(p.item)
	var party: SettlementParty = null
	var held0 := 0
	var inv0 := 0
	var coins0 := 0
	var gap0 := coin_gap(w)
	print("     %s %s walks to %s for %s (%d coins), %.2f road days each way" % [n.name, n.family, str(n.journey.to), item, int(p.price), Envoys.trip_days(w, str(n.journey.to))])
	var trace := []
	var seen := {"road": false, "site": false, "gap_ok": true, "pop_ok": true}
	var each := func() -> void:
		if int(w.minutes) % 60 == 0:
			trace.append([int(w.minutes), str(n.journey.get("leg", "home")), snappedf(n.pos.x, 0.01), snappedf(n.pos.y, 0.01)])
		if not w.map.in_village(n.cell()) and w.map.overworld.site_at(n.cell()).is_empty():
			seen.road = true
		if not w.map.overworld.site_at(n.cell()).is_empty():
			seen.site = true
		if coin_gap(w) != gap0:
			seen.gap_ok = false
		for o: NPC in w.npcs.slice(pop0):
			if o.role != "child" or o.born < 0.0:
				seen.pop_ok = false               # only a newborn may join (births go on); travel adds nobody
	var bought_stat := "seed_travelers_bought"
	var g0 := {}
	var bought := false
	var until := w.minutes + 12 * 1440.0
	while w.minutes < until and n.alive:
		var at_seller: bool = not n.plan.is_empty() and str(n.plan[0].get("act", "")) == "region_buy"
		if at_seller:
			g0 = Census.goods(w)                     # the village's goods the moment before the trade
			item = str(p.item)                       # (the item on sale there now: SeedTravelers.refresh)
			party = w.regions.party(str(p.about))
			held0 = party.held(item) if party != null else -1
			inv0 = n.inv.count(item)
			coins0 = n.coins
		w.update(0.5)
		each.call()
		if float(w.stats.get(bought_stat, 0.0)) > 0.0:
			bought = true
			break
	check(seen.road, "they walked the road outside the village")
	check(bought and n.alive, "they bought at %s on day %d (%s)" % [str(n.journey.get("to", "")), w.day(), n.doing])
	check(not w.map.overworld.site_at(n.cell()).is_empty() and seen.site, "the purchase was made at the settlement's site, in person (%s)" % n.cell())
	check(n.inv.count(item) == inv0 + 1, "the %s is in their pack (%d -> %d)" % [item, inv0, n.inv.count(item)])
	check(party != null and party.held(item) == held0 - 1, "it left the seller's own stock (%s: %d -> %d)" % [str(p.about), held0, party.held(item) if party != null else -1])
	var price := (w.regions.by_id[str(n.journey.to)] as OffMapSettlement).price(item)
	check(n.coins == coins0 - price and price > 0, "their purse paid the settlement's price for it (%d -> %d coins, price %d)" % [coins0, n.coins, price])
	check(seen.gap_ok and coin_gap(w) == gap0 and w.regions.audit() == "", "coins conserved throughout, across the boundary (gap %d); the settlements' books balance" % coin_gap(w))
	var g1 := Census.goods(w)
	check(not g0.is_empty() and int(g1.get(item, 0)) == int(g0.get(item, 0)) + 1 and int(w.stats.get("imported_" + item, 0.0)) >= 1, "the village's goods gain exactly the one item (%d -> %d), booked as imported" % [int(g0.get(item, 0)), int(g1.get(item, 0))])
	var home := _run(w, func() -> bool: return not Journeys.active(n) or not n.alive, 12 * 1440.0, each)
	check(home and n.alive and w.map.in_village(n.cell()), "they walked home (day %d, at %s in the village)" % [w.day(), n.cell()])
	check(int(w.stats.get("seed_travelers_ended_home", 0.0)) >= 1, "the journey ended at home (recorded)")
	check(n.inv.count(item) >= inv0 + 1 or int(w.stats.get("eaten_" + item, 0.0)) > 0, "they brought the %s home" % item)
	check(n.id == id and [n.name, n.family, n.household, n.home, n.job] == who and w.npc(id) == n, "the same person throughout: id %d, %s %s, household %d, home %s, %s" % [id, n.name, n.family, n.household, n.home, n.job])
	check(seen.pop_ok and w.npcs.size() >= pop0 and w.npcs.slice(0, pop0).all(func(o: NPC) -> bool: return w.npc(o.id) == o), "the population is intact: nobody removed, nobody added by the journey (%d, %d born meanwhile)" % [w.npcs.size(), w.npcs.size() - pop0])
	var normal := _run(w, func() -> bool: return not n.plan.is_empty() and not str(n.doing).begins_with("on the road"), 120.0)
	check(normal and not Journeys.active(n), "they take up ordinary life again: %s" % n.doing)
	var again := _run(w, func() -> bool: return Journeys.active(n) and bool(n.journey.get("purpose", {}).get("seed", false)), 2 * 1440.0)
	check(not again, "they are not sent again as a seed traveller")
	check(coin_gap(w) == gap0, "coins still conserved after (gap %d)" % coin_gap(w))
	return trace


func _test_determinism(trace: Array) -> void:
	var a := _world()
	var b := _world()
	var sa := seeds(a).map(func(n): return [n.id, str(n.journey.to), str(n.journey.purpose.item), str(n.journey.purpose.about)])
	var sb := seeds(b).map(func(n): return [n.id, str(n.journey.to), str(n.journey.purpose.item), str(n.journey.purpose.about)])
	check(sa == sb, "the same seed chooses the same travellers, places, items and sellers: %s" % str(sa))
	var n := nearest(b)
	var t2 := []
	_run(b, func() -> bool: return not Journeys.active(n) or not n.alive, 24 * 1440.0, func() -> void:
		if int(b.minutes) % 60 == 0:
			t2.append([int(b.minutes), str(n.journey.get("leg", "home")), snappedf(n.pos.x, 0.01), snappedf(n.pos.y, 0.01)]))
	var k := mini(trace.size(), t2.size())
	check(k > 24 and trace.slice(0, k) == t2.slice(0, k), "a second world from the same seed makes the same journey, hour by hour (%d hours compared)" % k)
	var c := World.new()
	c.setup(VillageMap.load_default(), 2)
	var sc := seeds(c).map(func(x): return x.id)
	check(sc.size() == SeedTravelers.cfg().count, "another seed also sends %d (%s)" % [sc.size(), str(sc)])


func _test_save_mid_journey() -> void:
	var w := _world()
	var n := nearest(w)
	var on_road := _run(w, func() -> bool: return str(n.journey.get("leg", "")) == "out" and not w.map.in_village(n.cell()) and w.map.overworld.site_at(n.cell()).is_empty() and n.cell().distance_to(Vector2i(w.map.exits()[int(n.journey.gate)].out)) > 40, 2 * 1440.0)
	check(on_road, "on the road, well out of the village, at %s" % n.cell())
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var b := World.new()
	b.load_dict(VillageMap.load_default(), d)
	var m := b.npc(n.id)
	check(m != null and m.name == n.name and m.household == n.household and m.home == n.home, "loaded: the same person (%s %s)" % [m.name if m else "-", m.family if m else "-"])
	check(m != null and m.pos.distance_to(n.pos) < 0.01 and JSON.stringify(m.journey) == JSON.stringify(JSON.parse_string(JSON.stringify(n.journey))), "loaded: the same place on the road and the same journey (%s)" % str(m.journey if m else {}))
	check(b.npcs.size() == w.npcs.size() and seeds(b).size() == seeds(w).size(), "loaded: nobody duplicated or lost (%d villagers, %d on their errand)" % [b.npcs.size(), seeds(b).size()])
	var gap0 := coin_gap(b)
	var p0 := m.pos
	_run(b, func() -> bool: return m.pos.distance_to(p0) > 3.0, 240.0)
	check(m.pos.distance_to(p0) > 3.0 and Journeys.active(m), "loaded: they walk on along the road (%.1f tiles)" % m.pos.distance_to(p0))
	var done := _run(b, func() -> bool: return not Journeys.active(m) or not m.alive, 14 * 1440.0)
	check(done and m.alive and b.map.in_village(m.cell()) and int(b.stats.get("seed_travelers_bought", 0.0)) >= 1 and int(b.stats.get("seed_travelers_ended_home", 0.0)) >= 1, "loaded: they go on to buy at %s and come home (day %d)" % [str(n.journey.to), b.day()])
	check(coin_gap(b) == gap0 and b.regions.audit() == "", "loaded: coins conserved to the end of the journey")


func _test_in_main() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_main_run, CONNECT_ONE_SHOT)


func _frames(k: int) -> void:
	for i in k:
		main._process(1.0 / 30.0)


func _main_run() -> void:
	main.new_game()
	await process_frame
	main.ui.hide_all()
	var w: World = main.world
	var s := seeds(w)
	check(s.size() == SeedTravelers.cfg().count, "a new game in the main scene sends its seed travellers (%d)" % s.size())
	var n := nearest(w)
	var out := _run(w, func() -> bool: return not w.map.in_village(n.cell()) and w.map.overworld.site_at(n.cell()).is_empty() and n.cell().distance_to(Vector2i(w.map.exits()[int(n.journey.gate)].out)) > 30, 2 * 1440.0)
	check(out, "%s is on the road outside the village (%s)" % [n.name, n.cell()])
	var hr := w.hour()
	if hr >= float(Journeys.REST_FROM) or hr < float(Journeys.REST_TO):
		_run(w, func() -> bool: return w.hour() >= float(Journeys.REST_TO) and w.hour() < 12.0 and Journeys.active(n), 1440.0)
	w.player.pos = n.pos + Vector2(0, 4.0)
	main.move_to = Vector2.INF
	main.talk_to = null
	_frames(2)
	main._tap(main.get_canvas_transform() * ((n.pos + Vector2(0, -0.4)) * main.T))
	var talked := false
	for i in 60:
		_frames(5)
		if main.ui.is_open("talk"):
			talked = true
			break
	check(main.talk_to == n or talked, "tapping %s on the road walks the player up to them" % n.name)
	check(talked, "and talks to them, as to anyone in the village (the talk window)")
	var text := ""
	for l in main.ui.panel_body.find_children("*", "Label", true, false):
		text += str(l.text) + " "
	var place := str(w.map.overworld.site(str(n.journey.to)).name)
	check(text.contains(place), "they say where they are going: \"%s\"" % text.strip_edges().left(160))
	main.ui.hide_all()
	main.queue_free()
	await process_frame
	await process_frame
	_finish()
