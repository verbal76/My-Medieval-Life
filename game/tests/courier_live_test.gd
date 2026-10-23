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
	test_shop_booths()
	test_near_market_booth()
	test_notary_live()
	test_law_lessons()
	test_villagers_post()
	test_settlement_carriage()
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


# ------------------------------------------------------------------------------ Build 18 courier items (X18-Q12-BOOTH, -POST, X18-Q13, LAW-SKILL)
func ref_of(n: NPC) -> String:
	return "npc:%d" % n.id


func wulstead_of(world: World) -> OffMapSettlement:
	return world.regions.by_id["wulstead"]


## Q18-15: a business with a shop opens its own booth at its shop, with its own route to each settlement; the village's keeper carries it
## and is paid the flat fee. The player, with a market stall of their own, has the same.
func test_shop_booths() -> void:
	var x := fresh(3)
	var cs := x.couriers
	var vb := cs.booth_of("village")
	var merchant: NPC = x.npcs.filter(func(n): return n.alive and n.job == "merchant")[0]
	var mref := ref_of(merchant)
	check(cs.is_business(mref) and cs.booth_of_keeper(mref).is_empty(), "a merchant is a business with a shop and has no booth of its own yet")
	var farmer: NPC = x.npcs.filter(func(n): return n.alive and n.role == "adult" and not cs.is_business(ref_of(n)))[0]
	check(cs.open_shop_booth(ref_of(farmer)) != "", "a villager with no shop cannot open a booth (%s)" % cs.open_shop_booth(ref_of(farmer)))
	check(cs.open_shop_booth(mref) == "", "the merchant opens a booth at its shop")
	var sb := cs.booth_of_keeper(mref)
	var loc := cs.location(mref, "business")
	check(bool(sb.shop) and str(sb.settlement) == "village" and int(sb.x) == int(loc.x) and int(sb.y) == int(loc.y), "it stands at the merchant's stall (%d, %d)" % [int(sb.x), int(sb.y)])
	check(cs.open_shop_booth(mref) != "" and cs.booth_of("village").id == vb.id, "a second booth for the same keeper is refused and the village's booth is still the market's")
	var mine := cs.routes.filter(func(r): return str(r.from) == str(sb.id))
	check(mine.size() == 5 and mine.all(func(r): return str(r.carrier) == str(vb.id) and float(r.days) > 0.0), "it has a route to each of the five settlements, carried by the village booth's keeper")
	check(cs.routes.size() == 15, "and the village's own ten routes are unchanged (%d routes)" % cs.routes.size())
	# parity: the player with no shop has none; with a stall of their own, the same booth
	check(cs.open_shop_booth("player") != "", "the player with no shop cannot open one")
	x.player.inv.add("plank", 3)
	var site := x.business.stalls.find_site("player")
	check(x.business.stalls.build("player", site, x.player.inv) == "" and cs.open_shop_booth("player") == "", "the player builds a stall (the STALL rules) and opens a booth at it")
	var pb := cs.booth_of_keeper("player")
	check(bool(pb.shop) and Vector2i(int(pb.x), int(pb.y)) == site and cs.booth_near(Vector2(site.x + 1.0, site.y + 0.5), 1.8).id == pb.id, "at the player's stall, found by the booth action")
	# the merchant sends goods by its own booth
	var wul := wulstead_of(x)
	x.note_settlement_trade(merchant, wul)
	merchant.inv.add(ITEM, 5)
	merchant.coins = 100
	var rt: Dictionary = cs.routes.filter(func(r): return str(r.from) == str(sb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead")[0]
	var keeper: NPC = x.npc(int(str(vb.keeper).trim_prefix("npc:")))
	var k0 := keeper.coins
	var m0 := merchant.coins
	var gap0 := coin_gap(x)
	var item0 := item_gap(x)
	var job := cs.book_route({"sender": mref, "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 5},
		"route": rt.id, "collect": {"kind": "coins", "amount": 7}, "proceeds": "deposit"})
	check(not job.has("error") and keeper.coins == k0 + int(job.fee) and merchant.coins == m0 - int(job.fee), "the flat fee (%d) is paid to the village's keeper who carries it, not to the owner of the shop" % int(job.fee))
	check((sb.store as Inventory).count(ITEM) == 5 and (vb.store as Inventory).count(ITEM) == 0 and str(job.booth) == str(sb.id), "the goods wait in the shop's booth")
	run_days(float(rt.days) * 2.0 + 3.5, x)
	check(str(job.state) == "fulfilled" and str(job.outcome) == "delivered", "delivered and home (%s, %s)" % [str(job.state), str(job.outcome)])
	check(int(cs.waiting(str(sb.id), mref).get("coins", 0)) == 7 and cs.waiting(str(vb.id), mref).is_empty(), "the 7 coins asked wait at the shop's own booth")
	check(int(cs.withdraw(str(sb.id), mref).coins) == 7, "and the owner takes them there")
	check(coin_gap(x) == gap0 and item_gap(x) == item0 and x.regions.audit() == "", "coins and goods balance; settlement books balance")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(x.to_dict(), "", true, true))
	var x2 := World.new()
	x2.load_dict(VillageMap.load_default(), saved)
	check(not x2.couriers.booth_of_keeper("player").is_empty() and bool(x2.couriers.booth_of_keeper("player").shop) and x2.couriers.routes.size() == x.couriers.routes.size(), "shop booths and their routes survive saving and loading")
	x2.dispose()
	x.dispose()
	# an owner's death: an empty booth closes at the next dawn with its routes; one with goods or a delivery waiting stays
	var z := fresh(11)
	var zm: NPC = z.npcs.filter(func(n): return n.alive and n.job == "merchant")[0]
	z.couriers.open_shop_booth(ref_of(zm))
	var zr := z.couriers.routes.size()
	z.kill(zm, "test")
	z.couriers.daily()
	check(z.couriers.booth_of_keeper(ref_of(zm)).is_empty() and z.couriers.routes.size() == zr - 5, "the empty booth of a dead owner closes at the next dawn, with its five routes")
	z.dispose()


## Q18-16: with no market stall free, the village's booth is a stall its keeper builds near the market by the STALL rules.
func test_near_market_booth() -> void:
	var x := World.new()
	x.setup(VillageMap.load_default(), 5)
	var cs := x.couriers
	cs.routes.clear()
	cs.booths = cs.booths.filter(func(b): return str(b.settlement) != "village")
	for sid in x.stalls:
		if str(x.stalls[sid].get("tenant", "")) == "":
			x.stalls[sid].tenant = "npc:0"                    # fixture: every pitch is let
	var hired: NPC = x.npcs.filter(func(n): return n.alive and x.construction.can_hire(n) == "")[0]
	cs.daily()
	check(cs.booth_of("village").is_empty(), "with no stall free and nobody holding planks, no booth opens yet")
	hired.inv.add("plank", 3)
	cs.daily()
	var vb := cs.booth_of("village")
	check(not vb.is_empty() and str(vb.keeper) == ref_of(hired) and str(vb.stall).begins_with("bstall") and Stalls.is_built(x.stalls[str(vb.stall)]), "a villager with the planks builds one (%s) and keeps it" % str(vb.stall))
	check(hired.inv.count("plank") == 0 and int(x.stats.get("stalls_built", 0)) >= 1, "built from the keeper's own three planks (nothing free)")
	check(cs.routes.size() == 10, "and the ten routes open from it")
	x.dispose()


func _wul_ready(x: World, till: int) -> void:
	var wul := wulstead_of(x)
	wul.trader().till += till                         # fixture: the trader's till can pay a formal price
	wul.reopen_books()


## X18-Q13: a payment above the small-agreement line is a formal contract; it is carried only by a courier with Law, signed before them
## by the sender as it leaves and by the recipient on arrival, brought back; never remotely, never at once.
func test_notary_live() -> void:
	var x := fresh(4)
	var cs := x.couriers
	var vb := cs.booth_of("village")
	var courier := str(vb.keeper)
	var cn: NPC = x.npc(int(courier.trim_prefix("npc:")))
	_wul_ready(x, 400)
	x.note_settlement_trade(x.player, wulstead_of(x))
	x.player.coins = 300
	x.player.inv.add(ITEM, 6)
	var small := int(CourierService.cfg().contracts.small_value)
	var order := {"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 6},
		"courier": courier, "collect": {"kind": "coins", "amount": small + 30}, "proceeds": "deliver"}
	var rt: Dictionary = cs.routes.filter(func(r): return str(r.from) == str(vb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead")[0]
	var ro := order.duplicate(true)
	ro.kind = "route"
	ro.route = rt.id
	check(cs.is_formal(order) and cs.refusal(ro).contains("must be signed"), "a payment of %d coins is a formal contract: a regular route cannot carry it" % (small + 30))
	check(cs.refusal(order).contains("does not know enough law"), "and a courier without Law cannot notarise it (Law %d)" % Skills.level(cn, "law"))
	var small_order := order.duplicate(true)
	small_order.collect = {"kind": "coins", "amount": 9}
	small_order.notarise = true
	check(cs.refusal(small_order) == "A small agreement needs no notary.", "a small agreement needs no notary")
	# the keeper learns the law it needs from the reeve and the preacher, a lesson a day
	check(Skills.level(cn, "law") < int(CourierService.cfg().notary.min_level), "a new booth keeper has no law")
	for d in 8:
		run_days(1.0, x)
		if Law.qualified(x, courier):
			break
	check(Law.qualified(x, courier), "the booth keeper takes lessons and reaches Law %d (xp %d)" % [int(CourierService.cfg().notary.min_level), int(cn.skills.get("law", 0))])
	var law0 := int(cn.skills.law)
	var gap0 := coin_gap(x)
	var item0 := item_gap(x)
	var n := cs.negotiate(order, 1)
	check(str(n.answer) == "counter" and int(n.quote.parts.get("notarial service", 0)) == int(CourierService.cfg().special.notary_fee), "the fee includes the notarial service (%d)" % int(CourierService.cfg().special.notary_fee))
	check(cs.describe(order).contains("formal contract") and cs.describe(order).contains("nothing is signed from afar"), "the instruction says it is a formal contract")
	var pc0: int = x.player.coins
	var job := cs.book_special(order, int(n.fee))
	check(not job.has("error") and int(job.agreement) >= 0, "booked: the delivery carries a document (%s)" % str(job.get("error", "")))
	var ag := cs.agreement(int(job.agreement))
	check(str(ag.class) == "formal" and ag.signatures.has("player") and not ag.signatures.has("region:wulstead/trader") and not cs.formal().binding(ag), "the sender signed before the notary as it left; the recipient has not; not binding")
	check(int(cn.skills.law) == law0 + int(CourierService.cfg().law.witness_xp), "the notary learned from witnessing the signature")
	check(cs.formal().sign(ag, "region:wulstead/trader") != "" and cs.formal().sign_before_notary(ag, "region:wulstead/trader", "npc:99999", 0.0) != "", "the recipient cannot sign from afar, nor before a notary who does not hold it")
	run_days(float(job.days) * 0.5, x)
	check(not ag.signatures.has("region:wulstead/trader") and str(job.state) == "in_transit", "nothing is signed while the document is on the road")
	run_days(float(job.days) * 0.5 + 0.2, x)
	check(ag.signatures.has("region:wulstead/trader") and not cs.formal().binding(ag) and str(job.state) == "returning", "the recipient signed before the notary on arrival; not binding until the document is back")
	run_days(float(job.days) + 0.3, x)
	check(str(job.state) == "fulfilled" and cs.formal().binding(ag) and str(ag.holder) == "player" and str(ag.state) == "signed", "back with both signatures: the contract is binding and the sender holds it")
	check(int(cn.skills.law) >= law0 + 2 * int(CourierService.cfg().law.witness_xp) + int(CourierService.cfg().law.carry_xp), "the notary learned from the second signature and from carrying the document home")
	check(x.player.coins == pc0 - int(n.fee) + small + 30, "the sender paid the fee and received the %d coins" % (small + 30))
	check(coin_gap(x) == gap0 and item_gap(x) == item0 and x.regions.audit() == "", "coins and goods balance; settlement books balance")
	# refused: the recipient will not sign; the goods come back; incomplete
	x.player.inv.add(ITEM, 2)
	var o2 := order.duplicate(true)
	o2.items = {ITEM: 2}
	var j2 := cs.book_special(o2, int(n.fee))
	j2.refuse = true
	var ag2 := cs.agreement(int(j2.agreement))
	run_days(float(j2.days) * 2.0 + 0.6, x)
	check(str(j2.state) == "returned" and str(ag2.state) == "rejected" and not ag2.signatures.has("region:wulstead/trader") and x.player.inv.count(ITEM) >= 2, "a recipient who will not sign: rejected, not binding, the goods come home")
	# interrupted: the notary is waylaid
	x.player.inv.add(ITEM, 2)
	var pc1: int = x.player.coins
	var gap1 := coin_gap(x)
	var j3 := cs.book_special(o2, int(n.fee))
	var ag3 := cs.agreement(int(j3.agreement))
	run_days(0.1, x)
	x.kill(cn, "test: waylaid on the road")
	run_days(float(j3.days) + 0.3, x)
	check(str(j3.state) == "interrupted" and str(ag3.state) == "interrupted" and not cs.formal().binding(ag3) and x.player.coins == pc1, "the notary is waylaid: the agreement is interrupted, incomplete, and the held fee goes back")
	check(coin_gap(x) == gap1, "and every coin is accounted for")
	# a small payment is an ordinary delivery: no document, no signature
	cs.daily()
	var nk := str(cs.booth_of("village").keeper)
	x.player.inv.add(ITEM, 1)
	var j4 := cs.book_special({"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 1},
		"courier": nk, "collect": {"kind": "coins", "amount": 9}}, 40)
	check(not j4.has("error") and int(j4.agreement) == -1, "a small payment is carried with no document and no signature (%s)" % str(j4.get("error", "")))
	x.dispose()
	# save and load mid-journey: the document and its signatures come back, and the loaded world finishes it
	var y := fresh(4)
	_wul_ready(y, 400)
	y.note_settlement_trade(y.player, wulstead_of(y))
	y.player.coins = 300
	y.player.inv.add(ITEM, 6)
	var ycs := y.couriers
	var ycn: NPC = y.npc(int(str(ycs.booth_of("village").keeper).trim_prefix("npc:")))
	ycn.skills["law"] = Skills.xp_for_level(int(CourierService.cfg().notary.min_level))
	var yo := order.duplicate(true)
	yo.courier = str(ycs.booth_of("village").keeper)
	var yj := ycs.book_special(yo, 200)
	check(not yj.has("error"), "(a second world) the notarised delivery is booked (%s)" % str(yj.get("error", "")))
	run_days(float(yj.days) * 0.5, y)
	var d: Dictionary = JSON.parse_string(JSON.stringify(y.to_dict(), "", true, true))
	var y2 := World.new()
	y2.load_dict(VillageMap.load_default(), d)
	var yag := y2.couriers.agreement(int(yj.agreement))
	check(not yag.is_empty() and str(yag.state) == "with_notary" and yag.signatures.has("player") and int(yag.value) == int(small + 30), "the saved document is there with the sender's signature")
	run_days(float(yj.days) * 2.0 + 0.5, y2)
	check(str(yag.state) == "signed" and y2.couriers.formal().binding(yag) and y2.regions.audit() == "", "and the loaded world completes it: both signatures, binding")
	var old: Dictionary = JSON.parse_string(JSON.stringify(y.to_dict(), "", true, true))
	(old.couriers as Dictionary).erase("agreements")
	var y3 := World.new()
	y3.load_dict(VillageMap.load_default(), old)
	check(y3.couriers.agreements.is_empty() and y3.couriers.jobs.size() == y.couriers.jobs.size(), "a save without documents loads with none")
	y3.dispose()
	y2.dispose()
	y.dispose()


## LAW-SKILL: the lessons, the saved skill and the older save.
func test_law_lessons() -> void:
	var x := fresh(6)
	var player_lv0 := Skills.level(x.player, "law")
	check(player_lv0 == 1 and not x.player.skills.has("law") and x.npcs.all(func(n): return not n.skills.has("law")), "Law starts at nothing for the player and every villager")
	var reeve: NPC = x.npc(x.reeve_id)
	var preacher: NPC = x.npcs.filter(func(n): return n.alive and n.job == "preacher")[0] if x.npcs.any(func(n): return n.alive and n.job == "preacher") else null
	check(Law.teaches(reeve) and preacher != null and Law.teaches(preacher) and Law.teacher_cap(preacher) > Law.teacher_cap(reeve), "the reeve and the chapel's preacher teach Law, the preacher further")
	x.player.skills["law"] = Skills.xp_for_level(Law.teacher_cap(reeve))
	check(not Law.teach(x, "player", reeve).ok and Law.teach(x, "player", preacher).ok, "past the reeve's ceiling the preacher still teaches the player")
	var d: Dictionary = JSON.parse_string(JSON.stringify(x.to_dict(), "", true, true))
	var x2 := World.new()
	x2.load_dict(VillageMap.load_default(), d)
	check(int(x2.player.skills.law) == int(x.player.skills.law) and x2.law_lessons.has("player"), "the player's Law and the day's lesson are saved and loaded")
	var older: Dictionary = JSON.parse_string(JSON.stringify(x.to_dict(), "", true, true))
	(older.player.skills as Dictionary).erase("law")
	var x3 := World.new()
	x3.load_dict(VillageMap.load_default(), older)
	check(Skills.level(x3.player, "law") == 1 and not x3.player.skills.has("law"), "a save that has no skills loads with Law at nothing")
	x3.dispose()
	x2.dispose()
	x.dispose()


## X18-Q12-POST, same rules for NPCs: a business with surplus a settlement's trader wants, whom it has dealt with, sends it by its own
## booth's regular route and asks the trader's price on arrival; the same flat fee; a record of what it did.
func test_villagers_post() -> void:
	var a := _post_world(8)
	var cs := a.couriers
	var wul := wulstead_of(a)
	check(not a.stats.has("courier_posts_villager"), "(before the post) no villager has sent anything")
	cs.villagers_post()
	var posted: Array = cs.jobs.filter(func(j): return str(j.sender).begins_with("npc:") and str(j.kind) == "route")
	check(posted.size() >= 1, "a business with surplus the trader wants books a delivery (%d booked)" % posted.size())
	if posted.is_empty():
		a.dispose()
		return
	var j: Dictionary = posted[0]
	var sender := a.npc(int(str(j.sender).trim_prefix("npc:")))
	var sb := cs.booth_of_keeper(str(j.sender))
	var col: Dictionary = j.collect
	check(bool(sb.shop) and str(j.booth) == str(sb.id) and str(j.recipient) == "region:wulstead/trader" and str(col.kind) == "coins" and int(col.amount) <= int(CourierService.cfg().contracts.small_value),
		"from its own booth, to the trader it knows, asking its payment (%d coins, a small agreement)" % int(col.amount))
	check(int(j.fee) == int(CourierService.cfg().routes.fee_per_load) * maxi(1, int(ceil(float(CourierService.units_of(j.items)) / float(CourierService.cfg().routes.load_units)))), "at the established flat fee (%d)" % int(j.fee))
	check(cs.jobs.filter(func(q): return q.sender == j.sender).size() == 1 and int(a.stats.get("courier_posts_villager", 0)) >= 1, "one delivery in flight for a business, and the posting is counted")
	var gap0 := coin_gap(a)
	var item0 := item_gap_of(a, j.items.keys()[0])
	var t0: int = int(wul.flows.outside_coins_out)
	cs.villagers_post()
	check(cs.jobs.filter(func(q): return q.sender == j.sender).size() == 1, "the same day it does not send again")
	run_days(float(cs.route(str(j.route)).days) * 2.0 + 3.5, a)
	check(str(j.state) == "fulfilled" and str(j.outcome) == "delivered", "the trader received the goods and the courier came home (%s)" % str(j.state))
	check(int(wul.flows.outside_coins_out) == t0 + int(col.amount), "the trader paid the %d coins asked, from its till" % int(col.amount))
	check(coin_gap(a) == gap0 and a.regions.audit() == "", "coins balance across the boundary; settlement books balance")
	check(item_gap_of(a, j.items.keys()[0]) == item0, "the goods are in the books (imported/exported)")
	# determinism
	var b := _post_world(8)
	b.couriers.villagers_post()
	a.dispose()
	var c := _post_world(8)
	c.couriers.villagers_post()
	check(JSON.stringify(b.couriers.to_dict()) == JSON.stringify(c.couriers.to_dict()), "two worlds of one seed post the same deliveries")
	b.dispose()
	c.dispose()


func item_gap_of(world: World, id: String) -> int:
	var made := 0
	for k in ["made_", "mined_", "felled_", "dug_", "cut_", "farm_harvest_"]:
		made += int(world.stats.get(k + id, 0))
	var used := 0
	for k in ["eaten_", "used_", "used_building_", "used_works_", "used_repairs_", "burned_", "broke_", "spoiled_"]:
		used += int(world.stats.get(k + id, 0))
	return int(Census.goods(world).get(id, 0)) + int(world.stats.get("exported_" + id, 0)) - int(world.stats.get("imported_" + id, 0)) - made + used


## A world where a merchant holds more than the caravan would leave it of something Wulstead's trader lacks, and has dealt with that trader.
func _post_world(seed_: int) -> World:
	var x := fresh(seed_)
	var wul := wulstead_of(x)
	var wants: Dictionary = wul.wants()
	for n: NPC in x.npcs:
		if not n.alive or n.role != "adult" or not n.job in ["merchant", "smith"]:
			continue
		var caps: Dictionary = x.brain.export_caps(n)
		for id in caps:
			if int(wants.get(id, 0)) > 0 and not NPCBrain.NOT_EXPORTED.has(id) and not NPCBrain.FOOD.has(id) and id != "meat" and not x.brain.keeps(n, id):
				n.inv.items[id] = int(caps[id])
				n.coins = 60
				x.note_settlement_trade(n, wul)
				wul.trader().till += 300
				wul.reopen_books()
				return x
	return x


## Q18-10: a settlement's trader may carry a special delivery for a fee, on its way home or anywhere if its party offers carts for hire;
## it is paid on arrival back, never free; only a trader the sender has dealt with.
func test_settlement_carriage() -> void:
	var x := fresh(9)
	var cs := x.couriers
	check(cs.carriers("player", "wulstead").all(func(c): return c.begins_with("npc:")), "a trader the player has not dealt with is not on the list of carters")
	x.note_settlement_trade(x.player, wulstead_of(x))
	check(cs.carriers("player", "wulstead").has("region:wulstead/trader") and not cs.carriers("player", "village").has("region:wulstead/trader"), "after dealing with Wulstead's trader it carries to Wulstead, on its way home, not elsewhere")
	x.note_settlement_trade(x.player, x.regions.by_id["garton"])
	check(not cs.carriers("player", "wulstead").has("region:garton/trader"), "Garton's trader does not carry to Wulstead")
	x.regions.party("garton/trader").set_option("carts_for_hire", true)
	check(cs.carriers("player", "wulstead").has("region:garton/trader"), "unless its party offers carts for hire (SettlementParty.carts_for_hire)")
	x.player.coins = 200
	x.player.inv.add(ITEM, 3)
	var gap0 := coin_gap(x)
	var item0 := item_gap(x)
	var order := {"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead", "items": {ITEM: 3},
		"courier": "region:wulstead/trader", "collect": {"kind": "coins", "amount": 4}, "proceeds": "deliver"}
	check(cs.carrier_refusal("player", "region:higham/trader", "wulstead") != "", "a carter the player does not know is refused")
	var n := cs.negotiate(order, 1)
	check(str(n.answer) == "counter" and int(n.fee) >= int(CourierService.cfg().special.minimum), "the carter's fee is worked out from the work, never nothing (%d)" % int(n.fee))
	var till0: int = int(wulstead_of(x).flows.outside_coins_out)
	var job := cs.book_special(order, int(n.fee))
	check(not job.has("error") and x.player.coins == 200 - int(n.fee), "the fee is held at the booth while the work is done")
	run_days(float(job.days) + 0.2, x)
	check(str(job.outcome) == "delivered" and int(wulstead_of(x).flows.outside_coins_out) == till0 + 4, "the trader's party hands over the goods and the payment as the recipient")
	run_days(float(job.days) + 0.3, x)
	check(str(job.state) == "fulfilled" and x.player.coins == 200 - int(n.fee) + 4, "and is paid its fee only when the work is done")
	check(coin_gap(x) == gap0 and item_gap(x) == item0 and x.regions.audit() == "", "coins and goods balance; settlement books balance")
	x.dispose()
