extends SceneTree
## Expansion 20 LE-05 route risk in prices (design s.5 "travel and risk"; docs/expansion20/LE05_IMPLEMENTATION.md s.2; EconRouteRisk).
## The per-route loss record counts only losses that happen (a courier's interrupted load, a delivery's goods a bandit took), moves
## nothing, saves as an optional key and is deterministic; the price term is the expected loss from it (PROVISIONAL rule), exactly 0
## with no recorded loss, and nothing at all while the economy is off. Nothing asserts that anyone prospers.
## Run headless:  godot --headless --path game --script res://tests/le05_route_risk_test.gd

const Census := preload("res://tests/census.gd")
const ITEM := "copper_ring"           # a made good no villager's day touches in a few days (courier_live_test's choice)

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func on_cfg(route_risk := true) -> Dictionary:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	c.market.route_risk = route_risk
	return c


func new_world(on := true, route_risk := true) -> World:
	EconomyFoundation.set_override(on_cfg(route_risk) if on else EconomyFoundation.off_config())
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_switch()
	test_zero_without_losses()
	test_rate_and_term()
	test_courier_loss()
	test_robbery_loss()
	test_save_and_load()
	test_determinism()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func adults(w: World) -> Array:
	return w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.household >= 0)


## Coins and goods the whole system holds, less what crossed the village's boundary (courier_live_test's measure).
func coin_gap(x: World) -> int:
	return x.total_coins() + x.regions.coins() - (x.coin_sources + x.regions.net_paid_by_village())


func item_gap(x: World, item := ITEM) -> int:
	var made := 0
	for k in ["made_", "mined_", "felled_", "dug_", "cut_", "farm_harvest_"]:
		made += int(x.stats.get(k + item, 0))
	var used := 0
	for k in ["eaten_", "used_", "used_building_", "used_works_", "used_repairs_", "burned_", "broke_", "spoiled_"]:
		used += int(x.stats.get(k + item, 0))
	return int(Census.goods(x).get(item, 0)) + int(x.stats.get("exported_" + item, 0)) - int(x.stats.get("imported_" + item, 0)) - made + used


func run_days(x: World, days: float) -> void:
	var dt := 10.0 / float(GameData.b("game_minutes_per_second"))
	for i in int(days * 144.0):
		x.player.hp = x.player.max_hp
		x.player.hunger = 100.0
		x.update(dt)


## The price terms of seller `s` for a unit of `id` to `buyer_ref`.
func terms(w: World, s: NPC, buyer_ref: String, id: String) -> Dictionary:
	return w.contracts.price_terms(s, buyer_ref, id, w.contracts.means(s, id, 3))


func test_switch() -> void:
	var off := new_world(false)
	var s: NPC = adults(off)[0]
	var b: NPC = adults(off)[3]
	check(EconRouteRisk.of(off) == null, "economy off: no route record is built")
	check(off.contracts.route_risk_per_unit(s, World.npc_ref(b.id), "plank") == 0.0 and float(terms(off, s, World.npc_ref(b.id), "plank").route_risk) == 0.0,
		"economy off: no route-risk term (CON-01's price exactly as before)")
	run_days(off, 1.0)
	check(not JSON.stringify(off.to_dict()).contains("route_risk"), "economy off: the save has no route_risk key")
	var noflag := new_world(true, false)
	var rr := EconRouteRisk.of(noflag)
	rr.note_lost(EconRouteRisk.VILLAGE, noflag.day(), 50, false)
	check(rr != null and not rr.pricing() and noflag.contracts.route_risk_per_unit(noflag.npc(s.id), World.npc_ref(b.id), "plank") == 0.0,
		"economy on, market.route_risk off: losses are recorded but not priced")


func test_zero_without_losses() -> void:
	var w := new_world(true)
	var flagless := new_world(true, false)
	var rr := EconRouteRisk.of(w)
	check(rr != null and rr.pricing() and rr.is_empty(), "economy on with market.route_risk: an empty record")
	var ps := adults(w)
	var same := true
	var zero := true
	var n := 0
	for i in range(0, mini(ps.size(), 8)):
		var s: NPC = ps[i]
		s.income_days = [30, 30, 30, 30, 30]
		flagless.npc(s.id).income_days = [30, 30, 30, 30, 30]
		for id in ["plank", "iron_bar", "bread"]:
			for br in [World.npc_ref(ps[(i + 3) % ps.size()].id), World.MANOR, World.PLAYER]:
				var t := terms(w, s, br, id)
				var t2 := terms(flagless, flagless.npc(s.id), br, id)
				zero = zero and typeof(t.route_risk) == TYPE_FLOAT and float(t.route_risk) == 0.0
				same = same and int(t.min) == int(t2.min)
				n += 1
	check(zero, "no recorded loss: the route-risk term is exactly 0.0 (%d price quotes)" % n)
	check(same, "no recorded loss: every minimum price is identical to the price without the term (%d quotes)" % n)
	rr.note_carried(EconRouteRisk.VILLAGE, w.day(), 500)
	check(rr.rate(EconRouteRisk.VILLAGE, w.day()) == 0.0 and w.contracts.route_risk_per_unit(ps[0], World.PLAYER, "plank") == 0.0,
		"goods carried with nothing lost: still exactly 0")


func test_rate_and_term() -> void:
	var w := new_world(true)
	var rr := EconRouteRisk.of(w)
	var ps := adults(w)
	var s: NPC = ps[0]
	var b := World.npc_ref(ps[4].id)
	var day := w.day()
	check(EconRouteRisk.route_of(World.npc_ref(s.id), b) == "village" and EconRouteRisk.route("wulstead", "village") == EconRouteRisk.route("village", "wulstead"),
		"routes: one place for an in-village delivery; a settlement link the same either way")
	rr.note_carried("village", day, 90)
	rr.note_lost("village", day, 10, false)
	var r1 := rr.rate("village", day)
	check(is_equal_approx(r1, 0.1), "loss rate = value lost / value carried over the window (10 of 100: %.3f)" % r1)
	var v := float(GameData.value("plank"))
	var t1 := w.contracts.route_risk_per_unit(s, b, "plank")
	check(is_equal_approx(t1, 0.1 * v * float(rr.cfg.get("risk_weight", 1.0))) and t1 > 0.0, "the term is the expected loss: rate x the unit's value x risk_weight (%.3f)" % t1)
	var pt := terms(w, s, b, "plank")
	check(is_equal_approx(float(pt.route_risk), t1) and int(pt.min) == maxi(1, roundi(maxf(float(pt.going), maxf(float(pt.cost), float(pt.alternatives))) * (float(pt.household) - float(pt.relationship) + float(pt.risk)) + float(pt.travel) + float(pt.route_risk))),
		"the minimum price carries the route-risk term beside travel (%d)" % int(pt.min))
	rr.note_lost("village", day, 40, false)
	var t2 := w.contracts.route_risk_per_unit(s, b, "plank")
	check(t2 > t1, "more recorded losses: the term rises (%.3f > %.3f)" % [t2, t1])
	check(w.contracts.route_risk_per_unit(s, b, "iron_bar") > t2 or GameData.value("iron_bar") <= GameData.value("plank"), "a dearer unit carries a larger expected loss")
	check(rr.rate("village|wulstead", day) == 0.0, "a loss on one route prices no other route")
	rr.note_lost("village|bourton", day, 5, true)
	check(rr.rate("village|bourton", day) == 1.0, "a loss whose carrying left the window is capped at the whole load (rate 1)")
	var later := day + rr.window_days()
	check(rr.rate("village", later - 1) > 0.0 and rr.rate("village", later) == 0.0, "the window rolls: losses older than %d days no longer count" % rr.window_days())
	rr.dawn(later)
	check(rr.is_empty(), "and dawn drops the old days (bounded record)")


func test_courier_loss() -> void:
	var w := new_world(true)
	var rr := EconRouteRisk.of(w)
	var cs := w.couriers
	cs.daily()
	var vb := cs.booth_of("village")
	var courier := str(vb.keeper)
	cs.note_settlement_trade("player", "wulstead")
	w.player.inv.add(ITEM, 2)
	w.player.coins = 200
	var gap0 := coin_gap(w)
	var item0 := item_gap(w)
	var order := {"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 2}, "courier": courier}
	var fee := int(cs.negotiate(order, 0).fee)
	var job := cs.book_special(order, fee)
	check(not job.has("error"), "a special delivery to Wulstead is booked (%s)" % str(job.get("error", "")))
	var key := EconRouteRisk.route("village", "wulstead")
	var load := GameData.value(ITEM) * 2
	var t0 := rr.totals(key, w.day())
	check(int(t0.carried) == load and int(t0.trips) == 1 and int(t0.lost) == 0 and rr.rate(key, w.day()) == 0.0,
		"the load is counted as carried on the road village|wulstead (%d), nothing lost" % load)
	var loot0 := w.loot.size()
	run_days(w, 0.1)
	w.kill(w.npc(int(courier.trim_prefix("npc:"))), "test: waylaid on the road")
	run_days(w, float(job.days) + 0.3)
	var t1 := rr.totals(key, w.day())
	check(str(job.state) == "interrupted" and int(t1.lost) == load and int(t1.losses) == 1, "the courier's interrupted journey is a recorded loss of its load (%s; lost %d)" % [str(job.outcome), int(t1.lost)])
	check(is_equal_approx(float(t1.rate), 1.0) and rr.rate("village", w.day()) == 0.0, "the loss is on that road only (rate %.2f there)" % float(t1.rate))
	var dropped := 0
	for i in range(loot0, w.loot.size()):
		if str(w.loot[i].get("from", "")) == "A courier's load":
			dropped += (w.loot[i].inv as Inventory).count(ITEM)
	check(dropped == 2, "the load lies where the courier fell, as before (the record moved nothing)")
	check(coin_gap(w) == gap0 and item_gap(w) == item0, "conservation: coins and goods balance across the loss (gaps %d/%d, were %d/%d)" % [coin_gap(w), item_gap(w), gap0, item0])


func test_robbery_loss() -> void:
	var w := new_world(true)
	var rr := EconRouteRisk.of(w)
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			bandit = n
			break
	var ps := adults(w).filter(func(n): return n.job != "guard")
	var s: NPC = ps[0]
	for id in s.inv.ids():
		s.inv.remove(id, s.inv.count(id))
	s.inv.add("plank", 3)
	w.player.coins = 500
	var r: Dictionary = w.contracts.propose(World.PLAYER, s, "plank", 3, GameData.value("plank") * 3, 3)
	check(r.has("contract") and bandit != null, "a villager owes 3 planks on an open contract (%s)" % str(r.get("answer", r.keys())))
	if not r.has("contract") or bandit == null:
		return
	var coins0 := s.coins + bandit.coins
	var planks0 := s.inv.count("plank") + bandit.inv.count("plank")
	bandit.pos = s.pos + Vector2(0.6, 0.0)
	bandit.depth = s.depth
	bandit.hp = bandit.max_hp
	bandit.target = s.id
	bandit.attack_cd = 0.0
	w.brain.fight(bandit, 0.1)
	var t := rr.totals("village", w.day())
	check(s.inv.count("plank") == 2 and bandit.inv.count("plank") >= 1, "a bandit robs the seller of a plank on the way (as before)")
	check(int(t.lost) == GameData.value("plank") and int(t.losses) == 1 and int(t.carried) == GameData.value("plank"), "the delivery's goods taken are a recorded loss on the village's roads (%s)" % str(t))
	check(s.coins + bandit.coins == coins0 and s.inv.count("plank") + bandit.inv.count("plank") == planks0, "conservation: the robbery moves what it moved before; the record moves nothing")
	check(w.contracts.route_risk_per_unit(s, World.PLAYER, "plank") > 0.0, "and the seller's next delivered price in the village carries the expected loss")
	# a robbery of goods nobody owes is not a delivery loss
	var o: NPC = ps[1]
	for id in o.inv.ids():
		o.inv.remove(id, o.inv.count(id))
	o.inv.add("iron_bar", 1)
	bandit.pos = o.pos + Vector2(0.6, 0.0)
	bandit.depth = o.depth
	bandit.hp = bandit.max_hp
	bandit.target = o.id
	bandit.attack_cd = 0.0
	w.brain.bandit_robbed.clear()
	w.brain.fight(bandit, 0.1)
	check(o.inv.count("iron_bar") == 0 and int(rr.totals("village", w.day()).losses) == 1, "a robbery of goods owed on no contract adds no route loss (no danger invented)")


func test_save_and_load() -> void:
	var w := new_world(true)
	var rr := EconRouteRisk.of(w)
	rr.note_carried("village|wulstead", w.day(), 40)
	rr.note_lost("village|wulstead", w.day(), 12, true)
	rr.note_lost("village", w.day(), 3, false)
	var s := JSON.stringify(w.to_dict())
	check(s.contains("route_risk"), "the record is saved under the economy section's optional key route_risk")
	var back := World.new()
	back.load_dict(VillageMap.load_default(), JSON.parse_string(s))
	var rb := EconRouteRisk.of(back)
	check(rb != null and JSON.stringify(rb.to_dict()) == JSON.stringify(rr.to_dict()), "it loads back exactly")
	check(is_equal_approx(rb.rate("village|wulstead", back.day()), rr.rate("village|wulstead", w.day())), "with the same loss rate")
	var d: Dictionary = JSON.parse_string(s)
	(d[EconomyFoundation.KEY] as Dictionary).erase("route_risk")
	var old := World.new()
	old.load_dict(VillageMap.load_default(), d)
	check(EconRouteRisk.of(old) != null and EconRouteRisk.of(old).is_empty(), "an older save (no route_risk key) loads with an empty record")
	EconomyFoundation.set_override(EconomyFoundation.off_config())
	var parked := World.new()
	parked.load_dict(VillageMap.load_default(), JSON.parse_string(s))
	check(parked.economy == null and JSON.stringify(parked.to_dict()[EconomyFoundation.KEY]) == JSON.stringify(JSON.parse_string(s)[EconomyFoundation.KEY]),
		"switched off: the section (record included) is parked and written back unchanged")


func test_determinism() -> void:
	var a := new_world(true)
	var b := new_world(true)
	for x: World in [a, b]:
		var rr := EconRouteRisk.of(x)
		rr.note_carried("village|garton", x.day(), 30)
		rr.note_lost("village|garton", x.day(), 7, true)
	run_days(a, 3.0)
	run_days(b, 3.0)
	check(JSON.stringify(EconRouteRisk.of(a).to_dict()) == JSON.stringify(EconRouteRisk.of(b).to_dict()), "two runs of one seed keep the same record")
	check(JSON.stringify(a.to_dict()) == JSON.stringify(b.to_dict()), "and the same world")
