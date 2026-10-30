extends SceneTree
## Expansion 20 LE-03, priority 1: ONE authoritative transaction path for village actors (EconClaims through World.trade and the
## village paths that move goods for coins). Adversarial: competing claims on the same goods and coins in the same tick, an
## offer against a routine purchase, contract holds, stale offers after goods or coins went by an outflow nobody refuses,
## rollback of a refused transfer (nothing changes), save and load mid-reservation, duplicate purchases across channels
## (npc_orders, market bids, inbound contracts), the escrow, the non-trade paths, conservation, determinism, and the switch
## (economy off: nothing changes). Nothing asserts that anyone prospers.
## Run headless:  godot --headless --path game --script res://tests/le03_claims_test.gd

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


func cfg_on(drive := true) -> Dictionary:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	c.market.drive = drive
	return c


func new_world(seed := 1, drive := true) -> World:
	EconomyFoundation.set_override(cfg_on(drive))
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_ask_against_routine_sale()
	test_bid_against_routine_purchase()
	test_contract_holds_bind()
	test_same_goods_same_tick()
	test_same_coins_same_tick()
	test_stale_offers()
	test_rollback()
	test_rebook_to_backing()
	test_escrow_and_orders()
	test_inbound_no_duplicate()
	test_village_paths()
	test_save_mid_reservation()
	test_determinism()
	test_switch_off()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------------------------------------ helpers
func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0:
			out.append(n)
	return out


func job(w: World, j: String, k := 0) -> NPC:
	var i := 0
	for n: NPC in adults(w):
		if n.job == j:
			if i == k:
				return n
			i += 1
	return null


func role(w: World, r: String) -> NPC:
	for n: NPC in adults(w):
		if w.brain.buy_role(n) == r:
			return n
	return null


func ref(n: NPC) -> String:
	return World.npc_ref(n.id)


func ledger(w: World) -> Array:
	return [w.total_coins(), Census.goods(w)]


func clear(w: World, item: String) -> void:
	for n: NPC in w.npcs:
		n.inv.remove(item, n.inv.count(item))


func contract(w: World, seller: NPC, buyer: NPC, item: String, qty: int, price: int, days := 5) -> Dictionary:
	buyer.coins = maxi(buyer.coins, qty * price + 400)
	var c: Dictionary = w.contracts._new_record(ref(buyer), ref(seller), item, qty, price, days, [])
	var ok: bool = w.contracts._open(c)
	assert(ok)
	return c


func audit_clean(w: World) -> bool:
	var a: Array = w.economy.claims.audit()
	if not a.is_empty():
		printerr("  audit: " + JSON.stringify(a))
	return a.is_empty()


## Every holding and every claim record (claims' own diagnostic counters left out).
func snapshot(w: World) -> String:
	var people := []
	for n: NPC in w.npcs:
		people.append([n.id, n.coins, n.inv.items])
	var e := w.economy.to_dict()
	e.erase("claims")
	e.erase("events")
	return JSON.stringify([people, w.player.coins, w.player.inv.items, w.treasury, e])


func ask(w: World, n: NPC, item: String, qty: int, price: int, lot := 1) -> int:
	var r := w.economy.offers.post(EconOffers.ASK, ref(n), item, qty, price, w.day() + 5, "", "market", lot)
	assert(r.ok)
	return int(r.id)


func bid(w: World, n: NPC, item: String, qty: int, price: int, lot := 1) -> int:
	var r := w.economy.offers.post(EconOffers.BID, ref(n), item, qty, price, w.day() + 5, "", "market", lot, "input")
	assert(r.ok, str(r))
	return int(r.id)


# ------------------------------------------------------------------------------------------------ an ask against a routine sale
func test_ask_against_routine_sale() -> void:
	var w := new_world()
	var of := w.economy.offers
	clear(w, "plank")
	var car := job(w, "carpenter")
	var buyer := job(w, "farmer")
	car.inv.add("plank", 6)
	var a := ask(w, car, "plank", 4, 3)
	buyer.coins = 200
	var before := ledger(w)
	check(w.trade(buyer, car, "plank", 2, 3), "a routine sale of two of six planks goes ahead (two unclaimed)")
	check(of.remaining(a) == 4 and w.economy.reservations.reserved(ref(car), "plank") == 4, "the ask keeps its four: the free planks were sold first")
	check(w.trade(buyer, car, "plank", 3, 3), "a routine sale into the ask's planks goes ahead: a sale answers the ask")
	check(of.remaining(a) == 1 and w.economy.reservations.reserved(ref(car), "plank") == 1 and car.inv.count("plank") == 1, "the ask is cut to the one plank left, before the goods moved")
	check(w.trade(buyer, car, "plank", 1, 3) and of.get_offer(a).state == "withdrawn", "selling the last plank withdraws the ask (no open offer over goods that are gone)")
	check(ledger(w) == before and audit_clean(w), "conserved; every open offer backed")


# ------------------------------------------------------------------------------------------------ a bid against a routine purchase
func test_bid_against_routine_purchase() -> void:
	var w := new_world()
	var of := w.economy.offers
	clear(w, "plank")
	clear(w, "bread")
	var sm := job(w, "smith")
	var car := job(w, "carpenter")
	var baker := job(w, "baker") if job(w, "baker") != null else role(w, "merchant_food")
	sm.coins = 30
	var b := bid(w, sm, "plank", 8, 3)        # 24 coins held back
	check(w.economy.reservations.reserved(ref(sm), "coins") == 24, "the bid reserves its 24 coins")
	car.inv.add("leather", 3)
	car.inv.add("plank", 3)
	baker.inv.add("bread", 2)
	var before := ledger(w)
	check(not w.trade(sm, car, "leather", 1, 7), "an unrelated purchase of 7 with 6 free coins is refused (the bid's coins are not spent twice)")
	check(of.remaining(b) == 8 and sm.coins == 30, "nothing moved, the bid stands whole")
	check(w.trade(sm, car, "leather", 1, 6), "an unrelated purchase within the free coins goes ahead")
	check(of.remaining(b) == 8, "and the bid is untouched")
	check(w.trade(sm, car, "plank", 3, 3), "a routine purchase of the very planks it bids for may use the bid's coins")
	check(of.remaining(b) == 5 and w.economy.reservations.reserved(ref(sm), "coins") == 15 and sm.coins == 15, "the bid yields three units (newest first), still backed")
	check(w.trade(sm, baker, "bread", 2, 4), "a household necessity (bread) may draw on the bid's coins")
	check(of.remaining(b) == 2 and sm.coins == 7 and w.economy.reservations.reserved(ref(sm), "coins") == 6, "the bid is cut to what the purse still backs")
	var after := ledger(w)
	if after != before:
		printerr("  ledger before %s\n  after %s" % [JSON.stringify(before), JSON.stringify(after)])
	check(after == before and audit_clean(w), "conserved; every open offer backed")
	check(w.can_afford(sm, 2, false, "leather") == false or w.claims_free_coins(sm, "leather") >= 2, "can_afford reads the coins no claim holds")
	check(w.claims_free_coins(sm, "leather") == 1 and w.claims_free_coins(sm, "plank") == 7 and w.claims_free_coins(sm, "bread", true) == 7,
		"free coins: 1 for something else, all 7 for planks or a necessity")


# ------------------------------------------------------------------------------------------------ contract holds never yield
func test_contract_holds_bind() -> void:
	var w := new_world()
	clear(w, "plank")
	var car := job(w, "carpenter")
	var lab := job(w, "laborer")
	var buyer := job(w, "farmer")
	car.inv.add("plank", 5)
	contract(w, car, lab, "plank", 3, 4)
	buyer.coins = 100
	check(w.trade(buyer, car, "plank", 2, 3), "two planks beyond what the contract holds can be sold")
	check(not w.trade(buyer, car, "plank", 1, 3), "the three held for the contract cannot (no double claim)")
	check(car.inv.count("plank") == 3, "the contract's goods are still there")
	check(not w.claims_allow(car, "plank", 1) and w.claims_allow(car, "plank", 0), "the same rule for the paths outside World.trade")
	check(audit_clean(w), "no breach")
	var a := w.economy.offers.post(EconOffers.ASK, ref(car), "plank", 1, 3)
	check(not a.ok, "nor can an ask reserve goods a contract holds")


# ------------------------------------------------------------------------------------------------ competing claims on one stock
func test_same_goods_same_tick() -> void:
	var w := new_world()
	var m := w.economy.market
	var of := w.economy.offers
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	var mr := role(w, "merchant_raw")
	var fr := job(w, "farmer")
	car.inv.add("plank", 4)
	var a := ask(w, car, "plank", 4, 3)
	sm.coins = 200
	mr.coins = 200
	fr.coins = 200
	var b1 := bid(w, sm, "plank", 4, 4)
	var b2 := bid(w, mr, "plank", 4, 4)
	var before := ledger(w)
	# in one tick: a routine purchase, then two market settlements against the same ask
	check(w.trade(fr, car, "plank", 1, 3), "a routine purchase takes one of the four first")
	check(of.remaining(a) == 3, "the ask yields that one")
	var r1 := m._settle({"rounds": 0, "ok": false, "deal": {}}, sm, car, "plank", 3, 3, b1, a, "test")
	var r2 := m._settle({"rounds": 0, "ok": false, "deal": {}}, mr, car, "plank", 3, 3, b2, a, "test")
	check(r1.outcome == "settled" and r2.outcome == "cannot_perform", "the second settlement on the same goods is refused (no duplicate purchase)")
	check(car.inv.count("plank") == 0 and of.get_offer(a).state == "filled", "the ask filled exactly once")
	check(sm.inv.count("plank") == 3 and mr.inv.count("plank") == 0, "the goods went to one buyer")
	check(of.remaining(b2) == 4 and w.economy.reservations.reserved(ref(mr), "coins") == 16, "the loser's bid and coins untouched")
	check(not w.trade(mr, car, "plank", 1, 3), "and a routine purchase from the empty stock is refused")
	check(ledger(w) == before and audit_clean(w), "conserved; every open offer backed")


func test_same_coins_same_tick() -> void:
	var w := new_world()
	var m := w.economy.market
	var of := w.economy.offers
	clear(w, "plank")
	clear(w, "leather")
	var sm := job(w, "smith")
	var car := job(w, "carpenter")
	var tan := job(w, "tanner") if job(w, "tanner") != null else role(w, "merchant_raw")
	sm.coins = 20
	var b := bid(w, sm, "plank", 5, 4)           # all 20 coins held back
	car.inv.add("plank", 5)
	tan.inv.add("leather", 5)
	var before := ledger(w)
	check(not w.trade(sm, tan, "leather", 1, 4), "the bid's coins cannot pay for leather")
	var r := m._settle({"rounds": 0, "ok": false, "deal": {}}, sm, car, "plank", 5, 4, b, -1, "test")
	check(r.outcome == "settled" and sm.coins == 0 and of.get_offer(b).state == "filled", "the settlement spends the reserved coins exactly once")
	check(not w.trade(sm, tan, "leather", 1, 1), "nothing is left to spend twice")
	check(ledger(w) == before and audit_clean(w), "conserved; every open offer backed")


# ------------------------------------------------------------------------------------------------ stale offers
func test_stale_offers() -> void:
	var w := new_world()
	var m := w.economy.market
	var of := w.economy.offers
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	car.inv.add("plank", 4)
	var a := ask(w, car, "plank", 4, 3)
	sm.coins = 100
	var b := bid(w, sm, "plank", 4, 4)
	car.inv.remove("plank", 3)                 # used up by an outflow nobody refuses (crafting, eating, a theft)
	sm.coins = 8                               # and a tax took the bid's coins
	var r := m._settle({"rounds": 0, "ok": false, "deal": {}}, sm, car, "plank", 3, 3, b, a, "test")
	check(r.outcome == "cannot_perform" and car.inv.count("plank") == 1 and sm.coins == 8, "a stale offer cannot fill beyond what is still held")
	var cut: Array = w.economy.claims.reconcile_all()
	check(cut.has(a) and cut.has(b), "the dawn reconciliation cuts both stale offers")
	check(of.remaining(a) == 1 and of.remaining(b) == 2 and audit_clean(w), "to what is held (1 plank; 8 coins = 2 at 4)")
	sm.coins = 0
	w.economy.dawn(w.day())
	check(of.get_offer(b).state == "withdrawn" and audit_clean(w), "a bid with nothing left behind it is withdrawn at dawn")
	var r2 := m._settle({"rounds": 0, "ok": false, "deal": {}}, sm, car, "plank", 1, 3, b, a, "test")
	check(r2.outcome == "cannot_perform", "a withdrawn bid never fills")


# ------------------------------------------------------------------------------------------------ rollback
func test_rollback() -> void:
	var w := new_world()
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	var lab := job(w, "laborer")
	car.inv.add("plank", 4)
	ask(w, car, "plank", 2, 3)
	contract(w, car, lab, "plank", 2, 4)
	sm.coins = 12
	bid(w, sm, "leather", 2, 4)
	var snap := snapshot(w)
	check(not w.trade(sm, car, "plank", 3, 3), "a sale needing the contract's goods is refused")
	check(snapshot(w) == snap, "refused at the seller: nothing changed (not even the ask that would have yielded)")
	check(not w.trade(sm, car, "plank", 2, 3), "a sale the seller could make but the buyer cannot pay without its leather bid is refused")
	check(snapshot(w) == snap, "refused at the buyer: nothing changed (not even the seller's ask)")
	check(not w.claims_release(sm, "coins", 5, "iron_bar"), "the non-trade path refuses the same purchase")
	check(snapshot(w) == snap, "and changes nothing")
	sm.inv.add("pickaxe", 50)
	check(not w.trade(car, sm, "pickaxe", 1, 1000), "a sale beyond the purse is refused before any claim is looked at")
	check(audit_clean(w), "no breach")


# ------------------------------------------------------------------------------------------------ rebook to backing
func test_rebook_to_backing() -> void:
	var w := new_world()
	var of := w.economy.offers
	clear(w, "plank")
	var sm := job(w, "smith")
	var car := job(w, "carpenter")
	sm.coins = 20
	var b := bid(w, sm, "plank", 5, 4)
	car.inv.add("plank", 2)
	# the negotiated price rose above the bid's own (the buyer conceded): 2 at 6 = 12, leaving 8 for 3 more at 4
	check(w.trade(sm, car, "plank", 2, 6, -1, [int(of.get_offer(b).reservation)]) and of.record_fill(b, 2), "a fill at a negotiated price above the bid")
	check(of.get_offer(b).state == "open" and of.remaining(b) == 2 and int(of.get_offer(b).reservation) >= 0, "the bid is cut to the two units its coins still back, never left without a reservation")
	check(audit_clean(w), "every open offer backed")


# ------------------------------------------------------------------------------------------------ escrow and npc_orders
func test_escrow_and_orders() -> void:
	var w := new_world()
	var sm := job(w, "smith")
	var car := job(w, "carpenter")
	sm.coins = 30 + w.reserve_of(sm)
	bid(w, sm, "plank", 5, 6)                  # 30 held back
	check(w.contracts.fund_refusal(ref(sm), 5) != "", "an escrow cannot set aside coins a bid holds back")
	check(w.contracts.propose(ref(sm), car, "iron_bar", 1, 5, 3).get("answer", "") == "refused", "so a contract that needs them is refused, nothing set aside")
	sm.coins += 5
	check(w.contracts.fund_refusal(ref(sm), 5) == "", "free coins can be set aside")
	# npc_orders: one channel per need
	var b := role(w, "merchant_raw")
	var ids: Array = NPCBrain.BUYS.get(w.brain.buy_role(sm), {}).keys()
	ids.sort()
	var item := ""
	for id in ids:
		if w.brain.batch_unit(sm, id) > 0 and w.brain.wants(sm, id) >= w.brain.batch_unit(sm, id):
			item = id
			break
	if item != "":
		for n: NPC in w.npcs:
			n.inv.remove(item, n.inv.count(item))
		sm.inv.remove(item, sm.inv.count(item))
		sm.coins = 500 + w.reserve_of(sm)
		var held: int = w.contracts.list.size()
		bid(w, sm, item, w.brain.wants(sm, item), 1)
		check(not w.contracts.order_input(sm) or w.contracts.list.back().item != item, "a business with an open market bid for an input orders it no second way")
		check(w.contracts.list.size() == held or w.contracts.list.back().item != item, "no second order for %s" % item)
	else:
		check(true, "no input to test the order on (skipped by the scenario, not by the rule)")
	check(b != null, "a raw-goods merchant exists")


# ------------------------------------------------------------------------------------------------ inbound contracts: no duplicate purchase
func test_inbound_no_duplicate() -> void:
	var w := new_world()
	var m := w.economy.market
	var sm := job(w, "smith")
	var car := job(w, "carpenter")
	var ids: Array = NPCBrain.BUYS.get(w.brain.buy_role(sm), {}).keys()
	ids.sort()
	var item := ""
	for id in ids:
		if w.brain.batch_unit(sm, id) > 0:
			item = id
			break
	sm.inv.remove(item, sm.inv.count(item))
	var want0: int = w.brain.wants(sm, item)
	sm.coins = 1000
	var c := contract(w, car, sm, item, 2, 3)
	check(w.economy.claims.inbound(ref(sm), item) == 2, "two units are coming on the contract")
	check(w.brain.wants(sm, item) == maxi(0, want0 - 2), "the business wants the rest only (the market drives): %d -> %d" % [want0, w.brain.wants(sm, item)])
	var tool: String = NPCBrain.JOB_TOOL.get(sm.job, "")
	if tool == "":
		tool = "hammer"
	var lab := job(w, "laborer")
	var need := {"actor": ref(lab), "kind": "tool", "item": "axe", "qty": 1}
	contract(w, sm, lab, "axe", 1, 10)
	check(int(m.open_need(ref(lab), need).qty) == 0, "a tool already ordered on a contract is not bid for again")
	c.delivered = 2
	c.state = "fulfilled"
	check(w.economy.claims.inbound(ref(sm), item) == 0, "nothing coming once delivered")
	EconomyFoundation.set_override(cfg_on(false))
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 1)
	var sm2 := w2.npc(sm.id)
	sm2.inv.remove(item, sm2.inv.count(item))
	sm2.coins = 1000
	var want2: int = w2.brain.wants(sm2, item)
	contract(w2, w2.npc(car.id), sm2, item, 2, 3)
	check(w2.brain.wants(sm2, item) == want2, "with the market not driving, wants() is as before")


# ------------------------------------------------------------------------------------------------ the paths outside World.trade
func test_village_paths() -> void:
	var w := new_world()
	var of := w.economy.offers
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	car.inv.add("plank", 3)
	var a := ask(w, car, "plank", 3, 3)
	check(w.claims_allow(car, "plank", 2) and of.remaining(a) == 3, "claims_allow is pure")
	check(w.claims_release(car, "plank", 2) and of.remaining(a) == 1, "claims_release (a manor or caravan purchase of the goods) cuts the ask first")
	sm.coins = 10
	var b := bid(w, sm, "plank", 2, 5)
	check(not w.claims_release(sm, "coins", 3, "iron_bar"), "a caravan import of something else cannot spend the bid's coins")
	check(w.claims_release(sm, "coins", 3, "bread", true) and of.remaining(b) == 1, "a necessity can, cutting the bid to what is left")
	# a villager buying at a premises' counter (Business.sell): the same rule
	var s := {"stock": {"leather": 2}, "prices": {"leather": 3}, "till": 0, "earned": 0, "sales": []}
	sm.coins = 5
	check(not w.business.sell(s, sm, "leather", 1, 3), "a counter purchase cannot spend coins a bid holds back")
	check(int(s.stock.leather) == 2 and sm.coins == 5, "nothing moved")
	check(audit_clean(w), "no breach")


# ------------------------------------------------------------------------------------------------ save and load mid-reservation
func test_save_mid_reservation() -> void:
	var w := new_world()
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	var fr := job(w, "farmer")
	car.inv.add("plank", 4)
	var a := ask(w, car, "plank", 3, 3)
	sm.coins = 20
	var b := bid(w, sm, "plank", 4, 4)
	w.trade(fr, car, "plank", 2, 3)            # cuts the ask to 2 (a claim stat recorded)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(d.economy.has("claims") and d.economy.has("reservations"), "saved: reservations and the claims' counters")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(JSON.stringify(w2.economy.to_dict()) == JSON.stringify(w.economy.to_dict()), "round trip identical")
	var tan := job(w, "tanner") if job(w, "tanner") != null else fr
	tan.inv.add("leather", 2)
	w2.npc(tan.id).inv.add("leather", 2)
	var r1 := w.trade(sm, tan, "leather", 1, 5)
	var r2 := w2.trade(w2.npc(sm.id), w2.npc(tan.id), "leather", 1, 5)
	check(r1 == false and r2 == false, "after load the bid's coins are still held back (no double spend across a save)")
	var s1 := w.trade(fr, car, "plank", 2, 3)
	var s2 := w2.trade(w2.npc(fr.id), w2.npc(car.id), "plank", 2, 3)
	check(s1 and s2 and w.economy.offers.get_offer(a).state == w2.economy.offers.get_offer(a).state, "a competing purchase after load ends exactly as without the save")
	check(JSON.stringify(w.economy.to_dict()) == JSON.stringify(w2.economy.to_dict()) and audit_clean(w2), "identical records; no breach")
	check(w2.economy.offers.remaining(b) == 4, "the bid untouched")


# ------------------------------------------------------------------------------------------------ determinism
func run_scenario() -> String:
	var w := new_world(3)
	clear(w, "plank")
	var car := job(w, "carpenter")
	var sm := job(w, "smith")
	var fr := job(w, "farmer")
	car.inv.add("plank", 5)
	ask(w, car, "plank", 4, 3)
	sm.coins = 40
	bid(w, sm, "plank", 6, 4)
	w.trade(fr, car, "plank", 3, 3)
	car.inv.remove("plank", 1)
	w.economy.dawn(w.day())
	var m := w.economy.market
	m.on_encounter(sm.id, car.id)
	for k in 120:
		w.update(0.5)
	return JSON.stringify(w.to_dict())


func test_determinism() -> void:
	check(run_scenario() == run_scenario(), "the same competing claims twice give byte-identical saves")


# ------------------------------------------------------------------------------------------------ the switch
func test_switch_off() -> void:
	EconomyFoundation.set_override({})
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	check(w.economy == null, "shipped: economy.json enabled false, nothing built")
	var car := job(w, "carpenter")
	check(w.claims_allow(car, "plank", 999) and w.claims_release(car, "coins", 999) and w.claims_free_coins(car) == car.coins,
		"the claims entry points do nothing while the economy is off")
	# enabled with the market not driving: le02_market_test.test_switch (a stepped day identical to the switch off) covers it
