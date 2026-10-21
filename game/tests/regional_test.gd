extends SceneTree
## PROSPECTIVE (Expansion 18, PROS-18; wip/expansion18-preparation): regional supply and demand, trade routes and
## transport, competition and cooperation, over fixture settlements (2 to 4; the live game has one village).
## Conservation, genuine trade (every transfer matched), settlement independence and determinism (spec s.5, s.6, s.11).
##   godot --headless --path game --script res://tests/regional_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_demand_and_supply()
	test_genuine_trade()
	test_no_demand_no_sale()
	test_cash_poor_town()
	test_competition()
	test_buyers_and_carriage()
	test_levels_scale_never_gate()
	test_cooperation()
	test_routes()
	test_independence()
	test_long_run_conservation()
	test_determinism()
	test_refused_line()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------------------ fixtures
func farm() -> SettlementLedger:
	return SettlementLedger.make({"id": "a_farm", "name": "Wheatby", "pos": [0, 0], "population": 80, "coins": 100,
		"stock": {"wheat": 200, "bread": 30}, "needs": {"wheat": 8.0, "iron_bar": 0.2}, "production": {"wheat": 10.0},
		"transport": {"handcart": 2}})


func mine() -> SettlementLedger:
	return SettlementLedger.make({"id": "b_mine", "name": "Hollow", "pos": [300, 0], "population": 20, "coins": 600,
		"stock": {"iron_bar": 30, "wheat": 2}, "needs": {"wheat": 6.0}, "production": {"iron_bar": 1.0},
		"transport": {"handcart": 1}})


func timber() -> SettlementLedger:
	return SettlementLedger.make({"id": "c_timber", "name": "Oakley", "pos": [0, 300], "population": 25, "coins": 300,
		"stock": {"plank": 120}, "needs": {"wheat": 3.0}, "production": {"plank": 6.0}})


func starving() -> SettlementLedger:
	return SettlementLedger.make({"id": "d_starve", "name": "Marsh", "pos": [300, 300], "population": 40, "coins": 25,
		"stock": {}, "needs": {"wheat": 5.0}})


func links(ids: Array, tiles := 300) -> Array:
	var out := []
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			out.append([ids[i], ids[j], tiles, {"road": 1.0}])
	return out


func totals(ls: Array) -> Dictionary:
	var coins := 0
	var goods := {}
	for l: SettlementLedger in ls:
		coins += l.coins
		for k in l.stock.items:
			goods[k] = int(goods.get(k, 0)) + int(l.stock.items[k])
	return {"coins": coins, "goods": goods}


func trade_round(ls: Array, routes: Dictionary, agreements := [], day := 0) -> Dictionary:
	var p := RegionalMarket.plan(ls, routes, agreements)
	var r := RegionalMarket.execute(p, ls, day)
	p.done = r.done
	p.refused = r.refused
	return p


# ------------------------------------------------------------------------------ tests
func test_demand_and_supply() -> void:
	var m := mine()
	var days := int(RegionalMarket.cfg().reserve_days)
	check(RegionalMarket.horizon(m, "wheat") == 6 * days and RegionalMarket.demand(m, "wheat") == 6 * days - 2,
		"demand is the reserve days' need less the store (%d)" % RegionalMarket.demand(m, "wheat"))
	check(RegionalMarket.supply(m, "wheat") == 0 and RegionalMarket.supply(m, "iron_bar") == 30, "supply is what is held beyond the settlement's own need")
	var f := farm()
	check(RegionalMarket.supply(f, "wheat") == 200 - 8 * days, "a farm keeps its own reserve before it sells")
	check(RegionalMarket.willing(m, "wheat") > GameData.value("wheat") and RegionalMarket.willing(f, "plank") == 0,
		"a short buyer pays above value; nobody pays for what they do not need")
	var bal := RegionalMarket.balance([f, m, timber()], "wheat")
	check(int(bal.supply) == RegionalMarket.supply(f, "wheat") and int(bal.demand) == RegionalMarket.demand(m, "wheat") + RegionalMarket.demand(timber(), "wheat"),
		"the regional balance of wheat sums the settlements' supply and demand")


## Spec s.6 row 1: agricultural village with grain surplus, mining town with a food deficit and money.
func test_genuine_trade() -> void:
	var ls := [farm(), mine()]
	var before := totals(ls)
	var routes := TradeRoutes.table(ls, links(["a_farm", "b_mine"]))
	var p := trade_round(ls, routes)
	var wheat: Array = p.done.filter(func(l): return l.item == "wheat")
	check(wheat.size() == 1 and wheat[0].seller == "a_farm" and wheat[0].buyer == "b_mine", "the mining town buys the farm's grain")
	check(RegionalMarket.demand(ls[1], "wheat") == 0, "as much as it needs for its reserve")
	var iron: Array = p.done.filter(func(l): return l.item == "iron_bar")
	check(iron.size() == 1 and iron[0].seller == "b_mine", "and iron goes the other way (spec s.6 row 2)")
	var after := totals(ls)
	check(after.coins == before.coins and after.goods == before.goods, "trade creates and destroys nothing: coins %d -> %d, goods kept" % [before.coins, after.coins])
	check(RegionalMarket.matched(ls) == "", "every transfer is matched by the other party's (%s)" % RegionalMarket.matched(ls))
	for l: SettlementLedger in ls:
		check(l.balanced() == "", "%s's books balance (%s)" % [l.id, l.balanced()])
	check(int(wheat[0].unit_price) == GameData.value("wheat") and wheat[0].carriage == "self" and int(wheat[0].fee_total) == 0,
		"the buyer pays the seller's price at its door and fetches the grain itself (Q18-10: no free delivery, nothing bundled)")


## Spec s.6 row 3: lumber surplus, no lumber demand: no guaranteed sale.
func test_no_demand_no_sale() -> void:
	var ls := [timber(), mine()]
	ls[1].stock.add("wheat", 100)              # the mine has all the food it needs
	var p := trade_round(ls, TradeRoutes.table(ls, links(["c_timber", "b_mine"])))
	check(p.done.filter(func(l): return l.item == "plank").is_empty(), "nobody buys planks nobody needs (surplus is not a sale)")


## Spec s.6 row 4 and s.11: a starving but cash-poor town does not conjure purchasing power.
func test_cash_poor_town() -> void:
	var ls := [farm(), starving()]
	var coins0: int = ls[1].coins
	var p := trade_round(ls, TradeRoutes.table(ls, links(["a_farm", "d_starve"])))
	var bought := 0
	for l in p.done:
		if l.buyer == "d_starve":
			bought += int(l.units)
	check(bought == (coins0 - int(RegionalMarket.cfg().cash_floor)) / GameData.value("wheat"), "the cash-poor town buys only what its coins above its floor pay for (%d)" % bought)
	var un: Array = p.unmet.filter(func(u): return u.buyer == "d_starve" and u.item == "wheat")
	check(un.size() == 1 and un[0].reason == "funds" and int(un[0].units) > 0, "the rest of its need is recorded unmet for want of funds (%d)" % (int(un[0].units) if un.size() > 0 else -1))
	var broke := starving()
	broke.coins = 0
	var ls2 := [farm(), broke]
	var p2 := trade_round(ls2, TradeRoutes.table(ls2, links(["a_farm", "d_starve"])))
	check(p2.done.is_empty() and ls2[1].coins == 0 and ls2[1].stock.count("wheat") == 0, "with no coins it gets nothing: no gift, no credit (Q18-5 open)")


func carter(id: String, place: String, transport: Dictionary) -> SettlementLedger:
	return SettlementLedger.make({"id": id, "settlement": place, "kind": "carter", "coins": 0, "transport": transport,
		"carts_for_hire": true})


## Spec s.6 row 5: two settlements selling the same good, a third buying: price and distance decide.
func test_competition() -> void:
	var near := farm()
	near.id = "a_near"
	near.settlement = "a_near"
	var far := farm()
	far.id = "b_far"
	far.settlement = "b_far"
	var buyer := mine()
	buyer.id = "c_buyer"
	buyer.settlement = "c_buyer"
	var ls := [near, far, buyer]
	var routes := TradeRoutes.table(ls, [["a_near", "c_buyer", 100, {"road": 1.0}], ["b_far", "c_buyer", 2000, {"open": 1.0}]])
	var p := trade_round(ls, routes)
	var wheat: Array = p.done.filter(func(l): return l.item == "wheat")
	check(wheat.size() == 1 and wheat[0].seller == "a_near", "at the same price the buyer fetches from the nearer seller (a shorter trip)")
	check(p.lost.any(func(l): return l.seller == "b_far" and l.item == "wheat"), "the other seller's lost sale is recorded")
	# capacity: the buyer carries one pack itself; a carter of its own town hauls the rest, for a fee
	near = farm()
	near.id = "a_near"
	near.settlement = "a_near"
	far = farm()
	far.id = "b_far"
	far.settlement = "b_far"
	buyer = mine()
	buyer.id = "c_buyer"
	buyer.settlement = "c_buyer"
	buyer.transport = {"carry": 1}
	buyer.stock.remove("wheat", 2)
	buyer.open_books()
	var cart := carter("c_carter", "c_buyer", {"handcart": 1})
	ls = [near, far, buyer, cart]
	routes = TradeRoutes.table(ls, [["a_near", "c_buyer", 100, {"road": 1.0}], ["b_far", "c_buyer", 600, {"road": 1.0}]])
	var coins0: int = totals(ls).coins
	p = trade_round(ls, routes)
	wheat = p.done.filter(func(l): return l.item == "wheat")
	var cap := TradeRoutes.capacity({"carry": 1})
	check(wheat.size() == 2 and wheat[0].carriage == "self" and int(wheat[0].units) == cap and wheat[1].carriage == "carter"
		and wheat[1].carrier == "c_carter" and int(wheat[1].fee_total) > 0,
		"the buyer carries what one pack holds (%d); a willing carter hauls the rest for a fee (%d coins)" % [cap, int(wheat[1].fee_total) if wheat.size() > 1 else -1])
	check(cart.coins == int(wheat[1].fee_total) and int(buyer.totals().carriage_paid) == int(wheat[1].fee_total),
		"the fee goes from the buyer to the carter, apart from the price of the goods")
	check(RegionalMarket.matched(ls) == "" and totals(ls).coins == coins0, "every sale and every carriage payment is matched; no coin made or lost")
	for l: SettlementLedger in ls:
		check(l.balanced() == "", "%s's books balance (%s)" % [l.id, l.balanced()])


## Owner Q18-10: anyone may buy; a buyer that cannot travel needs a willing, paid carter; there is no free delivery.
func test_buyers_and_carriage() -> void:
	var f := farm()
	var manor := SettlementLedger.make({"id": "b_mine/manor", "settlement": "b_mine", "kind": "treasury", "coins": 300,
		"needs": {"wheat": 2.0}, "can_travel": false})
	var house := SettlementLedger.make({"id": "b_mine/hh:3", "settlement": "b_mine", "kind": "household", "coins": 40,
		"needs": {"wheat": 1.0}, "transport": {"carry": 1}})
	var ls := [f, manor, house]
	var routes := TradeRoutes.table(ls, links(["a_farm", "b_mine"]))
	var p := trade_round(ls, routes)
	check(p.done.any(func(l): return l.buyer == "b_mine/hh:3" and l.carriage == "self"), "a household buys from another settlement and carries the grain home itself")
	var mu: Array = p.unmet.filter(func(u): return u.buyer == "b_mine/manor")
	check(not p.done.any(func(l): return l.buyer == "b_mine/manor") and mu.size() == 1 and mu[0].reason == "no carriage",
		"a treasury that cannot travel gets nothing without a carter (no free delivery)")
	f = farm()
	manor = SettlementLedger.make({"id": "b_mine/manor", "settlement": "b_mine", "kind": "treasury", "coins": 300,
		"needs": {"wheat": 2.0}, "can_travel": false})
	var hired := carter("b_mine/npc:9", "b_mine", {"carry": 1})
	ls = [f, manor, hired]
	p = trade_round(ls, TradeRoutes.table(ls, links(["a_farm", "b_mine"])))
	var ml: Array = p.done.filter(func(l): return l.buyer == "b_mine/manor")
	check(ml.size() > 0 and ml.all(func(l): return l.carriage == "carter" and int(l.fee_each) > 0), "with a willing carter the treasury buys, and pays the carter")
	check(int(ml[0].units) <= TradeRoutes.capacity({"carry": 1}) if ml.size() > 0 else false, "no more than the carter can carry")
	check(RegionalMarket.matched(ls) == "" and hired.coins == ml.reduce(func(a, l): return a + int(l.fee_total), 0), "the carter is paid exactly the fees, matched")
	check(p.done.all(func(l): return l.carriage == "self" or int(l.fee_total) > 0), "every line is fetched by the buyer or paid carriage: none is delivered free")
	var offer := RegionalMarket.to_contract_offer(ml[0], 3)
	check(offer.buyer == "b_mine/manor" and offer.seller == "a_farm" and int(offer.qty) == int(ml[0].units) and int(offer.price_each) == GameData.value("wheat")
		and int(offer.deadline_day) > 3 and str(offer.carriage.mode) == "carter",
		"a planned line maps to a CON-01 goods offer, with the carriage kept apart (CON-01 has no service contracts, Q18-12)")


## Owner Q18-9: a level only scales pay and output; it never stops an activity. The magnitudes are the owner's (Q18-11):
## the data's factors are all 1.0, so nothing changes until they are set.
func test_levels_scale_never_gate() -> void:
	check(SettlementIndustries.output_factor("farming", 0) == 1.0 and SettlementIndustries.pay_factor("mining", 4) == 1.0,
		"every pay and output factor is 1.0 until the owner sets them (Q18-11)")
	var a := farm()
	a.capabilities = {"farming": 0}
	var b := farm()
	b.capabilities = {"farming": 2}
	for day in 10:
		a.tick(day)
		b.tick(day)
	check(int(a.totals().produce.get("wheat", 0)) == 100 and a.totals().produce == b.totals().produce,
		"at level 0 a settlement still produces, and with neutral factors exactly as at level 2")
	var eff: Dictionary = SettlementIndustries.data().effects
	var saved: Dictionary = eff.output_factor.duplicate(true)
	eff.output_factor["farming"] = [0.5, 1.0, 1.5]          # a test curve only, not a proposal
	var c := farm()
	c.capabilities = {"farming": 0}
	var d := farm()
	d.capabilities = {"farming": 2}
	for day in 10:
		c.tick(day)
		d.tick(day)
	check(int(c.totals().produce.wheat) == 50 and int(d.totals().produce.wheat) == 150 and c.balanced() == "" and d.balanced() == "",
		"with factors in the data, the level scales output (50 at level 0, 150 at level 2), never to nothing, and the books balance")
	eff.output_factor = saved
	check(SettlementIndustries.industry_of("iron_ore") == "mining" and SettlementIndustries.industry_of("feather") == "",
		"each good's industry for its output factor comes from the data")


func test_cooperation() -> void:
	# two toolmaking towns with pickaxes; a third town's manor buys them through a carter on foot, so the carriage fee
	# grows with distance; the partner is the dearer one
	var mk := func(id: String, coins: int, stock: Dictionary, needs: Dictionary) -> SettlementLedger:
		return SettlementLedger.make({"id": id, "coins": coins, "stock": stock, "needs": needs})
	var a: SettlementLedger = mk.call("a_cheap", 50, {"pickaxe": 20}, {})
	var b: SettlementLedger = mk.call("b_partner", 50, {"pickaxe": 20}, {})
	var buyer: SettlementLedger = mk.call("c_buyer", 900, {}, {"pickaxe": 1.0})
	buyer.can_travel = false
	var cart := carter("c_carter", "c_buyer", {"carry": 1})
	var ls := [a, b, buyer, cart]
	var routes := TradeRoutes.table(ls, [["a_cheap", "c_buyer", 300, {"road": 1.0}], ["b_partner", "c_buyer", 1500, {"road": 1.0}]])
	var plain := RegionalMarket.plan(ls, routes)
	var pa := int(plain.lines[0].unit_price) + int(plain.lines[0].fee_each)
	var rb: Dictionary = routes["b_partner>c_buyer"]
	var pb := GameData.value("pickaxe") + int(TradeRoutes.costed("b_partner", "c_buyer", int(rb.tiles), float(rb.effective), "carrier").cost_per_unit)
	var margin := 1.0 + float(RegionalMarket.cfg().preferred_margin_pct) / 100.0
	check(pb > pa and float(pb) <= float(pa) * margin, "the fixture: the partner is dearer delivered (%d vs %d coins) but within the margin" % [pb, pa])
	check(plain.lines[0].seller == "a_cheap", "without an agreement the cheaper town wins")
	var p := RegionalMarket.plan(ls, routes, [["b_partner", "c_buyer", "preferred"]])
	check(p.lines[0].seller == "b_partner", "with one, the cooperation partner within the margin wins the sale")
	check(int(p.lines[0].unit_price) + int(p.lines[0].fee_each) == pb, "at its own price: cooperation lowers no price and gives nothing away")
	var far_routes := TradeRoutes.table(ls, [["a_cheap", "c_buyer", 300, {"road": 1.0}], ["b_partner", "c_buyer", 4000, {"rough": 1.0}]])
	var p2 := RegionalMarket.plan(ls, far_routes, [["b_partner", "c_buyer", "preferred"]])
	check(p2.lines[0].seller == "a_cheap", "a partner far dearer than the margin does not")
	RegionalMarket.execute(p, ls)
	check(RegionalMarket.matched(ls) == "" and a.coins + b.coins + buyer.coins + cart.coins == 1000, "and the cooperative trade is matched and conserves coins")


func test_routes() -> void:
	# a 12 x 7 grid: a wall across the middle with one gap; a road along the bottom
	var grid := [
		"............",
		"............",
		"............",
		"#####.######",
		"............",
		"............",
		"rrrrrrrrrrrr"]
	var classify := func(c: Vector2i) -> String:
		var ch: String = grid[c.y][c.x]
		return "solid" if ch == "#" else ("road" if ch == "r" else "open")
	var bounds := Rect2i(0, 0, 12, 7)
	var p := TradeRoutes.grid_path(Vector2i(0, 0), Vector2i(11, 6), classify, bounds)
	check(p.found and not p.cells.any(func(c): return grid[c.y][c.x] == "#"), "a route goes round solid ground (%d tiles)" % int(p.tiles))
	check(p.cells.has(Vector2i(5, 3)), "through the one gap")
	var walled := grid.duplicate()
	walled[3] = "############"
	var cut := func(c: Vector2i) -> String:
		return "solid" if walled[c.y][c.x] == "#" else "open"
	check(not TradeRoutes.grid_path(Vector2i(0, 0), Vector2i(11, 6), cut, bounds).found, "no way through, no route")
	var a := SettlementLedger.make({"id": "north", "pos": [0, 0]})
	var b := SettlementLedger.make({"id": "south", "pos": [11, 6], "needs": {"wheat": 1.0}})
	a.stock.add("wheat", 50)
	var t_open := TradeRoutes.grid_table([a, b], cut, bounds)
	check(t_open.is_empty(), "settlements cut off from each other get no route")
	var p_cut := RegionalMarket.plan([a, b], t_open)
	check(p_cut.lines.is_empty() and p_cut.unmet[0].reason == "no supplier", "and cannot trade (unmet: no supplier)")
	var road := TradeRoutes.abstract_route("x", "y", 600, {"road": 1.0}, "carrier")
	var rough := TradeRoutes.abstract_route("x", "y", 600, {"rough": 1.0}, "carrier")
	check(float(rough.effective) > float(road.effective) and int(rough.cost_per_unit) >= int(road.cost_per_unit) and rough.days > road.days,
		"rough ground makes a route longer and dearer than a road")
	var cart := TradeRoutes.abstract_route("x", "y", 600, {"road": 1.0}, "handcart")
	check(int(cart.cost_per_unit) <= int(road.cost_per_unit) and TradeRoutes.capacity({"handcart": 2}) > TradeRoutes.capacity({}),
		"a handcart carries more and hauls a unit no dearer than a back (carts exist since B14)")
	var g1 := TradeRoutes.grid_path(Vector2i(0, 0), Vector2i(11, 6), classify, bounds)
	check(g1.cells == p.cells, "the same grid gives the same path (determinism)")


## A settlement without trade partners neither gains nor loses goods or coins from the model: only its own
## production and use touch it, line by line.
func test_independence() -> void:
	var lone := timber()
	lone.id = "z_lone"
	var ls := [farm(), mine(), lone]
	var routes := TradeRoutes.table(ls, links(["a_farm", "b_mine"]))     # nobody links to z_lone
	var snap := JSON.stringify(lone.to_dict())
	var p := trade_round(ls, routes)
	check(JSON.stringify(lone.to_dict()) == snap, "a settlement with no route is untouched by a trade round")
	check(not p.done.any(func(l): return l.seller == "z_lone" or l.buyer == "z_lone"), "no line names it")
	check(p.unmet.any(func(u): return u.buyer == "z_lone" and u.reason == "no supplier"), "its unmet need is recorded, not filled")
	var solo := timber()
	var twin := timber()
	for day in 20:
		solo.tick(day)
		twin.tick(day)
		RegionalMarket.execute(RegionalMarket.plan([solo], {}), [solo], day)
	check(solo.to_dict() == twin.to_dict(), "on its own for 20 days it ends exactly as with no market at all")
	check(solo.balanced() == "", "its books balance by its own production and use (%s)" % solo.balanced())
	var t := solo.totals()
	check(int(t.shortage.get("wheat", 0)) == 60, "and its wheat shortage is real and recorded (%d)" % int(t.shortage.get("wheat", 0)))


## Four settlements trade for 60 days, every day: coins are conserved exactly (no income lines), goods equal the
## opening plus production less use, every transfer is matched.
func test_long_run_conservation() -> void:
	var ls := [farm(), mine(), timber(), starving()]
	var routes := TradeRoutes.table(ls, links(["a_farm", "b_mine", "c_timber", "d_starve"], 400))
	var before := totals(ls)
	var trades := 0
	for day in 60:
		for l: SettlementLedger in ls:
			l.tick(day)
		trades += trade_round(ls, routes, [], day).done.size()
	var after := totals(ls)
	check(after.coins == before.coins, "60 days of regional trade: coins %d -> %d (no coin from nowhere)" % [before.coins, after.coins])
	var made := {}
	var used := {}
	for l: SettlementLedger in ls:
		var t := l.totals()
		for k in t.produce:
			made[k] = int(made.get(k, 0)) + int(t.produce[k])
		for k in t.consume:
			used[k] = int(used.get(k, 0)) + int(t.consume[k])
		check(l.balanced() == "", "%s's books balance after 60 days" % l.id)
	var ok := true
	for k in RegionalMarket.goods_of(ls):
		if int(after.goods.get(k, 0)) != int(before.goods.get(k, 0)) + int(made.get(k, 0)) - int(used.get(k, 0)):
			ok = false
	check(ok, "every good is the opening stock plus production less use (%d trades)" % trades)
	check(RegionalMarket.matched(ls) == "", "and every transfer is matched")
	print("     after 60 days: %s" % str(ls.map(func(l): return "%s %d coins" % [l.id, l.coins])))


func test_determinism() -> void:
	check(_fingerprint() == _fingerprint(), "the same settlements and routes give the same 30 days of trade, coin for coin")


func _fingerprint() -> String:
	var ls := [farm(), mine(), timber(), starving()]
	var routes := TradeRoutes.table(ls, links(["a_farm", "b_mine", "c_timber", "d_starve"], 350))
	var log := []
	for day in 30:
		for l: SettlementLedger in ls:
			l.tick(day)
		log.append(trade_round(ls, routes, [["a_farm", "d_starve", "preferred"]], day).done)
	return JSON.stringify([log, ls.map(func(l): return l.to_dict())])


func test_refused_line() -> void:
	var ls := [farm(), mine()]
	var p := RegionalMarket.plan(ls, TradeRoutes.table(ls, links(["a_farm", "b_mine"])))
	ls[0].stock.remove("wheat", ls[0].stock.count("wheat"))    # the grain is gone before the carts leave
	var before := totals(ls)
	var r := RegionalMarket.execute(p, ls)
	check(r.refused.any(func(l): return l.item == "wheat") and not r.done.any(func(l): return l.item == "wheat"),
		"a planned sale whose goods are gone is refused whole")
	check(totals(ls).coins == before.coins and RegionalMarket.matched(ls) == "", "and nothing half-moves")
