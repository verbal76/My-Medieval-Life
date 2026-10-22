extends SceneTree
## REG-COURIER-01 (Expansion 18; X18-Q12, X18-Q12-BOOTH, X18-Q12-POST): the courier service in the LIVE World. A booth for each of
## the five settlements served by its own trader party, the village's booth by the stall rules, regular routes whose days come
## from the settlements' miles, recipients from real dealings with a settlement's trader, couriers stepped by World.update (the
## hour loop) and saved, and every coin and good counted across the village's boundary. The fee coefficients are the provisional
## X18-FEES values; nothing here sets or checks a balance value.
##   godot --headless --path game --script res://tests/courier_live_test.gd

const Census := preload("res://tests/census.gd")
const ITEM := "copper_ring"                    # a made good no villager's day touches in these few days: its count is exactly what the couriers move

var checks := 0
var failures := 0
var w: World


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	w = fresh(1)
	test_booths_and_routes()
	test_recipients()
	test_regular_route()
	test_special_and_fees()
	test_dead_courier()
	test_save_and_old_save()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func fresh(seed: int) -> World:
	var world := World.new()
	world.setup(VillageMap.load_default(), seed)
	world.couriers.daily()
	return world


## Coins and goods the whole system holds, less what crossed the village's boundary: constant while only the couriers move them.
func coin_gap(world: World = null) -> int:
	var x := world if world != null else w
	return x.total_coins() + x.regions.coins() - (x.coin_sources + x.regions.net_paid_by_village())


func item_gap(world: World = null) -> int:
	var x := world if world != null else w
	var made := 0
	for k in ["made_", "mined_", "felled_", "dug_", "cut_", "farm_harvest_"]:
		made += int(x.stats.get(k + ITEM, 0))
	var used := 0
	for k in ["eaten_", "used_", "used_building_", "used_works_", "used_repairs_", "burned_", "broke_", "spoiled_"]:
		used += int(x.stats.get(k + ITEM, 0))
	return int(Census.goods(x).get(ITEM, 0)) + int(x.stats.get("exported_" + ITEM, 0)) - int(x.stats.get("imported_" + ITEM, 0)) - made + used


## Game time passes through the live loop (World.update: the hour loop steps the couriers).
func run_days(days: float, world: World = null) -> void:
	var x := world if world != null else w
	var dt := 10.0 / float(GameData.b("game_minutes_per_second"))       # ten game minutes a step
	var steps := int(days * 144.0)
	for i in steps:
		x.player.hp = x.player.max_hp                  # (the player is not played: kept fed and well so the days pass)
		x.player.hunger = 100.0
		x.update(dt)


func wulstead() -> SettlementParty:
	return w.regions.party("wulstead/trader")


func test_booths_and_routes() -> void:
	var cs := w.couriers
	check(cs != null and cs.live, "the live World has a courier service")
	for s: OffMapSettlement in w.regions.list:
		var b := cs.booth_of(s.id)
		check(not b.is_empty() and str(b.keeper) == "region:%s/trader" % s.id and cs.alive(str(b.keeper)), "%s has a booth served by its own trader party" % s.name)
	var vb := cs.booth_of("village")
	check(not vb.is_empty() and str(vb.keeper).begins_with("npc:") and w.npc(int(str(vb.keeper).trim_prefix("npc:"))).alive, "the village has a booth kept by a villager (%s, %s)" % [str(vb.keeper), "a market stall" if str(vb.stall) != "" else "built"])
	check(str(vb.stall) != "" and w.stalls.has(str(vb.stall)), "and it stands at a market stall of the stall system")
	var days := {}
	for s: OffMapSettlement in w.regions.list:
		var out: Dictionary = {}
		var back: Dictionary = {}
		for r in cs.routes:
			if str(r.from) == str(vb.id) and str(cs.booth(str(r.to)).settlement) == s.id:
				out = r
			if str(r.to) == str(vb.id) and str(cs.booth(str(r.from)).settlement) == s.id:
				back = r
		check(not out.is_empty() and not back.is_empty() and float(out.days) > 0.0 and is_equal_approx(float(out.days), float(back.days)), "a regular route each way joins the village and %s (%.2f days for %d miles)" % [s.name, float(out.get("days", 0.0)), s.miles])
		days[s.id] = float(out.get("days", 0.0))
	check(days.wulstead < days.netherton and days.netherton < days.garton and days.garton < days.higham and days.higham < days.bourton, "the farther the settlement (miles), the longer the road")
	var table: Dictionary = w.regions.village_route_table()
	check(is_equal_approx(float(table["village>wulstead"].days), days.wulstead), "the days are the settlements.json distance hauled by a carrier (Regions.village_route_table)")


func test_recipients() -> void:
	var cs := w.couriers
	check(not cs.known_recipients("player").any(func(e): return str(e.ref).begins_with("region:")), "before any dealing the player knows no settlement's trader")
	check(cs.refusal({"sender": "player", "recipient": "region:wulstead/trader", "items": {ITEM: 1}, "kind": "special", "courier": str(cs.booth_of("village").keeper), "settlement": "wulstead"}) != "",
		"and a delivery to a stranger is refused")
	w.note_settlement_trade(w.player, w.regions.by_id["wulstead"])
	var rec := cs.known_recipients("player").filter(func(e): return str(e.ref) == "region:wulstead/trader")
	check(rec.size() == 1 and str(rec[0].kind) == "business" and str(rec[0].settlement) == "wulstead", "after dealing with Wulstead's trader the player may address it (located at Wulstead's booth)")
	check(not cs.known_recipients("player").any(func(e): return str(e.ref) == "region:garton/trader"), "and only that trader")
	# a real caravan visit: whoever sold to or bought from a trader is now a contact of it
	var before := cs.contacts.size()
	w.brain.caravan()
	check(cs.contacts.size() > before, "a caravan visit records the villagers who really dealt with the traders (%d new)" % (cs.contacts.size() - before))
	var c: Array = cs.contacts[cs.contacts.size() - 1]
	check(cs.is_known(str(c[0]), "region:" + str(c[1])), "and each may address the trader they dealt with")
	check(not cs.is_known("npc:%d" % w.npcs[0].id, "region:bourton/trader") or cs.contacts.any(func(p): return p[0] == "npc:%d" % w.npcs[0].id and p[1] == "bourton/trader"), "nobody else knows a trader they never dealt with")


func test_regular_route() -> void:
	var cs := w.couriers
	var vb := cs.booth_of("village")
	var route := {}
	for r in cs.routes:
		if str(r.from) == str(vb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead":
			route = r
	w.player.coins = 100
	w.player.inv.add(ITEM, 6)
	var gap0 := coin_gap()
	var item0 := item_gap()
	var held0 := wulstead().held(ITEM)
	var paid0 := int(w.regions.by_id["wulstead"].flows.outside_coins_out)
	var keeper: NPC = w.npc(int(str(vb.keeper).trim_prefix("npc:")))
	var kcoins0 := keeper.coins
	var order := {"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 6},
		"route": route.id, "collect": {"kind": "coins", "amount": 9}, "proceeds": "deposit"}
	var job := cs.book_route(order)
	check(not job.has("error") and w.player.coins == 100 - int(job.fee) and keeper.coins == kcoins0 + int(job.fee), "a regular-route booking pays the flat fee (%d coins) to the booth's keeper" % int(job.fee))
	check(w.player.inv.count(ITEM) == 0 and (vb.store as Inventory).count(ITEM) == 6, "and the goods wait in the booth's store, not yet delivered")
	check(coin_gap() == gap0 and item_gap() == item0, "the books balance at the booth")
	check(cs.book_route({"sender": "player", "recipient": "region:wulstead/trader", "settlement": "wulstead", "items": {ITEM: 1}, "route": route.id}).has("error"), "and a second booking with no goods is refused")
	run_days(1.2)                                    # the route leaves on day 1 (the first departure), in the live hour loop
	check(str(job.state) == "in_transit" and w.day() >= 1, "the courier leaves on the route's departure day (state %s, day %d)" % [str(job.state), w.day()])
	check(wulstead().held(ITEM) == held0, "and nothing has reached Wulstead before the road is travelled")
	run_days(float(route.days) + 0.2)
	check(wulstead().held(ITEM) == held0 + 6 and str(job.outcome) == "delivered", "after the journey's days Wulstead's trader holds the 6 goods")
	check(int(w.regions.by_id["wulstead"].flows.outside_coins_out) == paid0 + 9, "and has paid the 9 coins asked from its till")
	run_days(float(route.days) + 0.3)
	check(str(job.state) == "fulfilled", "the courier comes home: the contract is fulfilled only then")
	var dep := cs.waiting(str(vb.id), "player")
	check(int(dep.get("coins", 0)) == 9, "the payment waits at the sender's booth (deposit)")
	var took := cs.withdraw(str(vb.id), "player")
	check(int(took.coins) == 9 and w.player.coins == 100 - int(job.fee) + 9, "and the sender collects it there")
	check(coin_gap() == gap0, "coins: nothing created or lost across the village's boundary (gap %d, was %d)" % [coin_gap(), gap0])
	check(item_gap() == item0, "goods: every good moved is in the books (imported/exported) (gap %d, was %d; census %d exp %s imp %s holders %s)" % [item_gap(), item0, int(Census.goods(w).get(ITEM, 0)), str(w.stats.get("exported_" + ITEM)), str(w.stats.get("imported_" + ITEM)), str(Census.holders(w).keys().filter(func(k): return int(Census.holders(w)[k].get(ITEM, 0)) > 0))])
	check(w.regions.audit() == "", "every settlement's books balance (%s)" % w.regions.audit())
	var f: Dictionary = w.regions.by_id["wulstead"].flows
	check(int(f.outside_coins_out) == 9 and int(f.outside_in.get(ITEM, 0)) == 6, "Wulstead's flow lines show the traffic (outside_*)")


func test_special_and_fees() -> void:
	var cs := w.couriers
	var vb := cs.booth_of("village")
	var courier := str(vb.keeper)
	w.player.inv.add(ITEM, 3)
	w.player.coins = 200
	var gap0 := coin_gap()
	var item0 := item_gap()
	var order := {"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 3},
		"courier": courier, "collect": {"kind": "coins", "amount": 5}, "proceeds": "deliver"}
	var n := cs.negotiate(order, 1)
	check(str(n.answer) == "counter" and int(n.fee) > 1, "a special delivery is negotiated: an offer of 1 coin is countered with the least fee (%d)" % int(n.fee))
	var q := cs.quote(order)
	check(int(q.fee) == int(n.fee) and float(q.days) > 0.5, "worked out from the journey (%.2f days from the miles) and the carrier's wage" % float(q.days))
	var job := cs.book_special(order, int(n.fee))
	check(not job.has("error") and w.player.coins == 200 - int(n.fee) and vb.escrow == int(n.fee), "the fee is held at the booth, not paid yet")
	check(coin_gap() == gap0, "and held fees count in the village's coins")
	var held0 := wulstead().held(ITEM)
	var paid0 := int(w.regions.by_id["wulstead"].flows.outside_coins_out)
	var pc0: int = w.player.coins
	var kc0: int = w.npc(int(courier.trim_prefix("npc:"))).coins
	run_days(float(q.days) + 0.2)
	check(wulstead().held(ITEM) == held0 + 3 and str(job.outcome) == "delivered", "the courier delivers to Wulstead's trader after the days on the road")
	check(int(vb.escrow) == int(n.fee) and w.player.coins == pc0, "the fee is still held while the courier is away (the payment is not yet home)")
	run_days(float(q.days) + 0.3)
	check(str(job.state) == "fulfilled" and w.player.coins == pc0 + 5 and int(vb.escrow) == 0, "back home: the 5 coins collected go to the sender and the contract is fulfilled")
	check(w.npc(int(courier.trim_prefix("npc:"))).coins - kc0 >= int(n.fee), "the courier is paid its fee only when the work is done (no free transport) (%d vs %d, fee %d)" % [w.npc(int(courier.trim_prefix("npc:"))).coins, kc0, int(n.fee)])
	check(int(w.regions.by_id["wulstead"].flows.outside_coins_out) == paid0 + 5, "Wulstead paid from its own till")
	check(coin_gap() == gap0 and item_gap() == item0 and w.regions.audit() == "", "coins and goods balance; settlement books balance")
	# a delivery to a settlement the player has not dealt with is refused
	check(cs.refusal({"sender": "player", "recipient": "region:bourton/trader", "recipient_kind": "business", "settlement": "bourton", "items": {ITEM: 1}, "courier": courier}) != "", "a trader the player has not dealt with cannot be addressed")


func test_dead_courier() -> void:
	var cs := w.couriers
	var vb := cs.booth_of("village")
	var courier := str(vb.keeper)
	w.player.inv.add(ITEM, 2)
	w.player.coins = 200
	var gap0 := coin_gap()
	var item0 := item_gap()
	var order := {"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 2}, "courier": courier}
	var fee := int(cs.negotiate(order, 0).fee)
	var job := cs.book_special(order, fee)
	check(not job.has("error"), "a second special delivery is booked (%s)" % str(job.get("error", "")))
	var pc0: int = w.player.coins
	var held0 := wulstead().held(ITEM)
	run_days(0.1)
	w.kill(w.npc(int(courier.trim_prefix("npc:"))), "test: waylaid on the road")
	run_days(float(job.days) + 0.3)
	check(str(job.state) == "interrupted" and w.player.coins == pc0 + fee and int(vb.escrow) == 0, "a courier who dies on the road interrupts the delivery and the held fee goes back (%s)" % str(job.outcome))
	check(wulstead().held(ITEM) == held0, "nothing reached the settlement")
	check(coin_gap() == gap0 and item_gap() == item0, "the goods passed with the courier's estate (or heir) and nothing is lost or made")
	cs.daily()
	var kept := str(cs.booth_of("village").keeper)
	check(kept != courier and cs.alive(kept), "the next dawn the booth has a new keeper (%s)" % kept)


func test_save_and_old_save() -> void:
	var cs := w.couriers
	var vb := cs.booth_of("village")
	w.player.inv.add(ITEM, 4)
	w.player.coins = 300
	var route := {}
	for r in cs.routes:
		if str(r.from) == str(vb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead":
			route = r
	w.note_settlement_trade(w.player, w.regions.by_id["wulstead"])
	var job := cs.book_route({"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 4},
		"route": route.id, "collect": {"kind": "coins", "amount": 3}, "proceeds": "deliver"})
	check(not job.has("error"), "a route delivery is booked (%s)" % str(job.get("error", "")))
	run_days(float(route.next_day) + 0.15 - float(w.minutes) / World.DAY)        # just after the next departure
	check(str(job.state) == "in_transit", "mid-delivery: the courier is on the road")
	var gap0 := coin_gap()
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	check(d.has("couriers") and (d.couriers.jobs as Array).any(func(j): return j.id == job.id and j.state == "in_transit"), "the save holds the delivery on the road")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var c2 := w2.couriers
	var j2: Dictionary = {}
	for j in c2.jobs:
		if j.id == job.id:
			j2 = j
	check(not j2.is_empty() and str(j2.state) == "in_transit" and int(j2.items[ITEM]) == 4 and float(j2.arrive) == float(job.arrive), "a loaded world has the same delivery in the same state")
	check(c2.booths.size() == cs.booths.size() and c2.routes.size() == cs.routes.size() and c2.contacts.size() == cs.contacts.size() and c2.next_id == cs.next_id, "and the same booths, routes, contacts and counter")
	var base2 := item_gap(w2)                         # (the run's counters are not saved: the loaded world counts from its own start)
	check(coin_gap(w2) == gap0 and int(Census.goods(w2).get(ITEM, 0)) == int(Census.goods(w).get(ITEM, 0)), "the loaded world's coins and goods are the same as the saved world's")
	var held0 := w2.regions.party("wulstead/trader").held(ITEM)
	run_days(float(job.days) + 0.3, w2)
	check(str(j2.state) in ["returning", "fulfilled"] and w2.regions.party("wulstead/trader").held(ITEM) == held0 + 4, "the loaded world's courier arrives and hands over")
	run_days(float(job.days) + 0.3, w2)
	check(str(j2.state) == "fulfilled" and w2.player.coins == w.player.coins + 3, "and comes home: fulfilled")
	check(coin_gap(w2) == gap0 and item_gap(w2) == base2 and w2.regions.audit() == "", "all balanced after the loaded world finishes it")
	# an older save: no "couriers" key
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	old.erase("couriers")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.couriers != null and w3.couriers.jobs.is_empty() and w3.couriers.booth_of("wulstead").size() > 0 and w3.couriers.booth_of("village").is_empty(), "an old save loads with the settlements' booths and no deliveries on the road")
	w3.couriers.daily()
	check(not w3.couriers.booth_of("village").is_empty() and w3.couriers.routes.size() == 10, "and the village's booth and the ten routes open at the next dawn")
	w2.dispose()
	w3.dispose()


func test_determinism() -> void:
	var a := fresh(7)
	var b := fresh(7)
	for world in [a, b]:
		var vb: Dictionary = world.couriers.booth_of("village")
		var rt := {}
		for r in world.couriers.routes:
			if str(r.from) == str(vb.id) and str(world.couriers.booth(str(r.to)).settlement) == "garton":
				rt = r
		world.note_settlement_trade(world.player, world.regions.by_id["garton"])
		world.player.inv.add(ITEM, 2)
		world.player.coins = 100
		world.couriers.book_route({"sender": "player", "recipient": "region:garton/trader", "settlement": "garton", "items": {ITEM: 2}, "route": rt.id})
		run_days(2.5, world)
	check(JSON.stringify(a.couriers.to_dict()) == JSON.stringify(b.couriers.to_dict()) and a.coin_sources == b.coin_sources and a.total_coins() == b.total_coins(), "two worlds of one seed given the same orders end in the same state")
	a.dispose()
	b.dispose()
