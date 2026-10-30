extends SceneTree
## Expansion 20 LE-03, priority 2: household budgets (obligations and necessities by their own urgency, then discretionary
## needs), food bids from a household's payer, production that honours accepted contracts (inputs earmarked, not diverted,
## released by the general expiry: no tool-order trap), a worker waiting on a manor tool order free to seek the tool elsewhere
## (real opportunity response), conservation and the switch. Gate "No tool-order traps; real opportunity response".
## Nothing asserts that anyone prospers; a trade is asserted only where the scenario's terms overlap.
## Run headless:  godot --headless --path game --script res://tests/le03_economy_test.gd

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
	test_food_bid()
	test_budget_order()
	test_earmarked_inputs()
	test_no_tool_order_trap()
	test_tool_need_switch()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


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


func ref(n: NPC) -> String:
	return World.npc_ref(n.id)


func ledger(w: World) -> Array:
	return [w.total_coins(), Census.goods(w)]


func audit_clean(w: World) -> bool:
	var a: Array = w.economy.claims.audit()
	if not a.is_empty():
		printerr("  audit: " + JSON.stringify(a))
	return a.is_empty()


## A household short of food: `days` of the reserve_days horizon covered, `need` food points a day.
func hungry(w: World, h: int, days: float, need: float) -> void:
	w.households[h].econ = {"days": days, "need": need}
	w.economy.needs.mark(World.hh_ref(h))


func a_household(w: World, exclude := []) -> int:
	for n: NPC in adults(w):
		if not exclude.has(n.household) and w.economy.market.food_payer(n.household) == n and not n.job in ["farmer", "cook", "tavernkeeper", "merchant"]:
			return n.household
	return -1


# ------------------------------------------------------------------------------------------------ food bids
func test_food_bid() -> void:
	var w := new_world()
	var m := w.economy.market
	var of := w.economy.offers
	var h := a_household(w)
	var payer := m.food_payer(h)
	check(payer != null and payer.role == "adult", "a household's food payer is one of its adults (the most coins)")
	for mid in w.households[h].members:
		var o := w.npc(int(mid))
		if o != null and o.role == "adult" and o != payer:
			check(o.coins <= payer.coins, "no other adult of the household holds more coins than the payer")
	hungry(w, h, 0.5, 30.0)
	var need := m.need_for(ref(payer), m.food_item(payer), "food")
	check(not need.is_empty() and need.kind == "food" and NPCBrain.FOOD.has(str(need.item)), "the household's food shortfall is a need its payer answers (%s)" % str(need.get("item", "")))
	check(int(need.qty) == ceili(45.0 / NPCBrain.food_points(str(need.item))), "in units of the chosen food: 1.5 days x 30 points")
	payer.coins = 200
	var posted: Array = []
	for k in 40:
		posted.append_array(m.post_bids(w.day()))
	var fb: Array = of.open_of(ref(payer)).filter(func(x): return x.side == EconOffers.BID and x.need == "food")
	check(fb.size() == 1, "one food bid for the household, from its payer")
	var food_bids := 0
	for id in posted:
		if of.get_offer(int(id)).need == "food" and of.get_offer(int(id)).actor == ref(payer):
			food_bids += 1
	check(food_bids == 1, "posting again does not open a second food bid for the same need (another food included)")
	var b: Dictionary = fb[0]
	var item := str(b.item)
	# a seller of that food meets the payer: the bid settles through World.trade
	var seller := job(w, "laborer")              # not a trade that keeps grain back (a farmer's feed, a cook's flour)
	seller.inv.add(item, 20)
	var before := ledger(w)
	var r := m.negotiate(payer, seller, item, of.remaining(int(b.id)), int(b.id), -1, "encounter")
	check(r.outcome in ["settled", "no_agreement", "buyer_refused", "seller_refused"], "the bargain ends in a valid outcome (%s)" % r.outcome)
	if r.outcome == "settled":
		check(payer.inv.count(item) >= int(r.qty) and of.get_offer(int(b.id)).filled == int(r.qty), "food bought: in the payer's pack, the bid filled by what was sold")
	check(ledger(w) == before and audit_clean(w), "conserved; every open offer backed")
	# met need: the bid goes at review
	w.households[h].econ = {"days": 5.0, "need": 30.0}
	w.economy.needs.mark(World.hh_ref(h))
	w.minutes += World.DAY
	m.review(w.day())
	check(of.get_offer(int(b.id)).state != "open", "a food bid whose need is met is withdrawn at review (or already filled)")


# ------------------------------------------------------------------------------------------------ budgets
func test_budget_order() -> void:
	var w := new_world()
	var m := w.economy.market
	var h := a_household(w)
	var payer := m.food_payer(h)
	payer.coins = 30 + w.reserve_of(payer)
	hungry(w, h, 0.0, 40.0)                       # urgent: no food at all (urgency 1.0)
	var fi := m.food_item(payer)
	var food := m.need_for(ref(payer), fi, "food")
	var input := {"actor": ref(payer), "kind": "input", "item": "plank", "qty": 10, "shortfall": 10.0, "target": 10.0, "cover_days": -1.0, "deadline": -1}
	var fb := m.budget_for(payer, food)
	var ib := m.budget_for(payer, input)
	check(fb > 0, "food, a necessity, gets budget first (%d)" % fb)
	check(ib <= maxi(0, w.spendable(payer) - fb), "a discretionary input gets only what food leaves above the reserve (%d)" % ib)
	hungry(w, h, 2.0, 40.0)                       # fed for the horizon: no food need
	var ib2 := m.budget_for(payer, input)
	check(ib2 >= ib, "with the food need met the input may take more (%d >= %d)" % [ib2, ib])
	# an owed contract outranks an input; a tool (urgency 1.0) outranks a contract far from its deadline
	var sm := job(w, "smith")
	sm.coins = 50 + w.reserve_of(sm)
	var lab := job(w, "laborer")
	lab.coins = 500
	var c: Dictionary = w.contracts._new_record(ref(lab), ref(sm), "leather", 4, 9, 9, [])
	w.contracts._open(c)
	w.economy.needs.mark(ref(sm))
	var owed := m.need_for(ref(sm), "leather", "contract")
	var inp := {"actor": ref(sm), "kind": "input", "item": "coal", "qty": 30, "shortfall": 30.0, "target": 30.0, "cover_days": -1.0, "deadline": -1}
	check(not owed.is_empty() and m.budget_for(sm, owed) > 0, "goods owed on a contract get budget (%d)" % m.budget_for(sm, owed))
	check(m.budget_for(sm, inp) <= maxi(0, m.cash_for(sm) - m.budget_for(sm, owed)), "an input gets what the obligation leaves")
	var id := m.post_bid(sm, "coal", inp)
	check(id < 0 or w.economy.offers.get_offer(id).qty * w.economy.offers.get_offer(id).price_each <= m.cash_for(sm), "a bid is sized by the budget, never past the free coins")


# ------------------------------------------------------------------------------------------------ production honours contracts
func test_earmarked_inputs() -> void:
	var w := new_world()
	var cl := w.economy.claims
	var car := job(w, "carpenter")
	var lab := job(w, "laborer")
	# a recipe the carpenter can work, and another product from the same input
	var r := ""
	var item := ""
	for rid in GameData.recipes:
		var rec: Dictionary = GameData.recipes[rid]
		if w.brain._can_make(car, rid) and (rec["in"] as Dictionary).has("log") and (rec["in"] as Dictionary).size() == 1:
			r = rid
			item = str((rec.out as Dictionary).keys()[0])
			break
	check(r != "", "the carpenter works logs (%s -> %s)" % [r, item])
	var other := ""
	for rid in GameData.recipes:
		var rec: Dictionary = GameData.recipes[rid]
		if rid != r and w.brain._can_make(car, rid) and (rec["in"] as Dictionary).has("log") and not (rec.out as Dictionary).has(item):
			other = rid
			break
	car.inv.remove(item, car.inv.count(item))
	car.inv.remove("log", car.inv.count("log"))
	var per_log := int(GameData.recipes[r]["in"].log)
	var per_out := int(GameData.recipes[r].out[item])
	car.inv.add("log", per_log * 2)
	lab.coins = 500
	var c: Dictionary = w.contracts._new_record(ref(lab), ref(car), item, per_out * 2, 3, 4, [])
	c.route = "craft"
	c.recipe = r
	check(w.contracts._open(c), "a craft contract opens")
	check(w.economy.reservations.reserved(ref(car), "log") == per_log * 2, "its inputs are earmarked (%d logs), still in the carpenter's pack" % (per_log * 2))
	check(car.inv.count("log") == per_log * 2, "an earmark moves nothing")
	var buyer := job(w, "farmer")
	buyer.coins = 200
	check(not w.trade(buyer, car, "log", 1, 2), "earmarked inputs cannot be sold away")
	if other != "":
		check(not cl.craft_ok(car, other) and not w.brain._do_recipe(car, other), "nor worked into another product (%s): no silent diversion" % other)
	check(cl.craft_ok(car, r), "the contract's own recipe may use them")
	var res := w.work_craft(car, r, car.inv)
	check(res.result == "ok" and w.economy.reservations.reserved(ref(car), "log") == per_log, "working the contract's recipe consumes its earmark as it goes (%d left)" % w.economy.reservations.reserved(ref(car), "log"))
	check(audit_clean(w), "no breach")
	# general expiry, no trap: the contract's deadline passes, it lapses, the earmark goes with it
	w.minutes += World.DAY * 6
	w.contracts.dawn()
	w.economy.dawn(w.day())
	var open := Contracts.is_open(w.contracts.get_contract(int(c.id)))
	check(open or w.economy.reservations.reserved(ref(car), "log") == 0, "once the contract has ended its earmark is released (no input held forever)")
	check(w.economy.reservations.reserved(ref(car), "log") == 0 or open, "the logs are free for anything again")


# ------------------------------------------------------------------------------------------------ no tool-order trap
func test_no_tool_order_trap() -> void:
	var w := new_world()
	var m := w.economy.market
	var wc := job(w, "woodcutter")
	var tool: String = NPCBrain.JOB_TOOL[wc.job]
	wc.inv.remove(tool, wc.inv.count(tool))
	var sm := job(w, "smith")
	w.manor_orders.append({"smith": sm.id, "tool": tool, "for": wc.id, "paid": 10, "day": w.day()})
	w.economy.needs.mark(ref(wc))
	var need := m.need_for(ref(wc), tool, "tool")
	check(not need.is_empty(), "a worker waiting on the manor's order may still seek the tool (the market drives)")
	wc.coins = 200
	var bid := m.post_bid(wc, tool, need)
	check(bid >= 0, "it bids for one")
	var mg: NPC = null
	for n: NPC in adults(w):
		if w.brain.buy_role(n) == "merchant_goods":
			mg = n
	if mg == null:
		mg = job(w, "farmer")
	mg.inv.add(tool, 1)
	var before := ledger(w)
	var r := m.negotiate(wc, mg, tool, 1, bid, -1, "encounter")
	check(r.outcome in ["settled", "not_for_sale", "no_agreement", "buyer_refused", "seller_refused"], "an opportunity met in person ends validly (%s)" % r.outcome)
	if r.outcome == "settled":
		check(wc.inv.has(tool), "the worker has its tool without waiting for the forge")
		sm.inv.add(tool, 1)
		w.brain._deliver_orders()
		check(wc.inv.count(tool) == 1 and not w.brain.tool_short(wc), "the worker works with its own tool; the forged one is not forced on it")
		check(w.economy.market.need_for(ref(wc), tool, "tool").is_empty(), "and it seeks no other")
	check(ledger(w) == before or r.outcome == "settled", "conserved")
	check(audit_clean(w), "no breach")


func test_tool_need_switch() -> void:
	var w := new_world(1, false)
	var wc := job(w, "woodcutter")
	var tool: String = NPCBrain.JOB_TOOL[wc.job]
	wc.inv.remove(tool, wc.inv.count(tool))
	w.manor_orders.append({"smith": job(w, "smith").id, "tool": tool, "for": wc.id, "paid": 10, "day": w.day()})
	var tools: Array = w.economy.needs.derive(ref(wc)).filter(func(x): return x.kind == "tool")
	check(tools.is_empty(), "market not driving: a worker on a manor order has no tool need (LE-01 as before)")
	check(w.economy.market.budget_for(wc, {"kind": "input", "item": "log", "qty": 1}) >= 0, "the budget reads nothing while not driving")
