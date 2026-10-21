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
	check(int(wheat[0].unit_price) == GameData.value("wheat") + int(routes["a_farm>b_mine"].cost_per_unit),
		"the delivered price is the value plus the haulage, paid to the hauling seller")


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
	var price := GameData.value("wheat") + int(TradeRoutes.table(ls, links(["a_farm", "d_starve"]))["a_farm>d_starve"].cost_per_unit)
	check(bought == (coins0 - int(RegionalMarket.cfg().cash_floor)) / price, "the cash-poor town buys only what its coins above its floor pay for (%d)" % bought)
	var un: Array = p.unmet.filter(func(u): return u.buyer == "d_starve" and u.item == "wheat")
	check(un.size() == 1 and un[0].reason == "funds" and int(un[0].units) > 0, "the rest of its need is recorded unmet for want of funds (%d)" % (int(un[0].units) if un.size() > 0 else -1))
	var broke := starving()
	broke.coins = 0
	var ls2 := [farm(), broke]
	var p2 := trade_round(ls2, TradeRoutes.table(ls2, links(["a_farm", "d_starve"])))
	check(p2.done.is_empty() and ls2[1].coins == 0 and ls2[1].stock.count("wheat") == 0, "with no coins it gets nothing: no gift, no credit (Q18-5 open)")


## Spec s.6 row 5: two settlements selling the same good, a third buying: price and distance decide.
func test_competition() -> void:
	var near := farm()
	near.id = "a_near"
	var far := farm()
	far.id = "b_far"
	var buyer := mine()
	buyer.id = "c_buyer"
	var ls := [near, far, buyer]
	var routes := TradeRoutes.table(ls, [["a_near", "c_buyer", 100, {"road": 1.0}], ["b_far", "c_buyer", 2000, {"open": 1.0}]])
	check(int(routes["a_near>c_buyer"].cost_per_unit) < int(routes["b_far>c_buyer"].cost_per_unit), "the nearer road route hauls cheaper")
	var p := trade_round(ls, routes)
	var wheat: Array = p.done.filter(func(l): return l.item == "wheat")
	check(wheat.size() == 1 and wheat[0].seller == "a_near", "the cheaper delivered price wins the sale")
	check(p.lost.any(func(l): return l.seller == "b_far" and l.item == "wheat"), "the dearer seller's lost sale is recorded")
	# capacity: the near seller can carry only a carrier's load; the far one fills the rest
	near = farm()
	near.id = "a_near"
	near.transport = {"handcart": 0}
	far = farm()
	far.id = "b_far"
	buyer = mine()
	buyer.id = "c_buyer"
	buyer.stock.remove("wheat", 2)
	ls = [near, far, buyer]
	routes = TradeRoutes.table(ls, [["a_near", "c_buyer", 100, {"road": 1.0}], ["b_far", "c_buyer", 600, {"road": 1.0}]])
	p = trade_round(ls, routes)
	wheat = p.done.filter(func(l): return l.item == "wheat")
	var cap := TradeRoutes.capacity({"handcart": 0})
	check(wheat.size() == 2 and wheat[0].seller == "a_near" and int(wheat[0].units) == cap and wheat[1].seller == "b_far",
		"a seller sends no more than its transport carries; the next cheapest fills the rest")
	check(RegionalMarket.matched(ls) == "" and totals(ls).coins == 100 + 100 + 600, "and every coin is still accounted for")


func test_cooperation() -> void:
	# two toolmaking towns carrying pickaxes on their backs to a third that needs them; the partner is the dearer one
	var mk := func(id: String, coins: int, stock: Dictionary, needs: Dictionary) -> SettlementLedger:
		return SettlementLedger.make({"id": id, "coins": coins, "stock": stock, "needs": needs})
	var a: SettlementLedger = mk.call("a_cheap", 50, {"pickaxe": 20}, {})
	var b: SettlementLedger = mk.call("b_partner", 50, {"pickaxe": 20}, {})
	var buyer: SettlementLedger = mk.call("c_buyer", 900, {}, {"pickaxe": 1.0})
	var ls := [a, b, buyer]
	var routes := TradeRoutes.table(ls, [["a_cheap", "c_buyer", 300, {"road": 1.0}], ["b_partner", "c_buyer", 1500, {"road": 1.0}]])
	var pa := int(routes["a_cheap>c_buyer"].cost_per_unit) + GameData.value("pickaxe")
	var pb := int(routes["b_partner>c_buyer"].cost_per_unit) + GameData.value("pickaxe")
	var margin := 1.0 + float(RegionalMarket.cfg().preferred_margin_pct) / 100.0
	check(pb > pa and float(pb) <= float(pa) * margin, "the fixture: the partner is dearer (%d vs %d coins) but within the margin" % [pb, pa])
	var plain := RegionalMarket.plan(ls, routes)
	check(plain.lines[0].seller == "a_cheap", "without an agreement the cheaper town wins")
	var p := RegionalMarket.plan(ls, routes, [["b_partner", "c_buyer", "preferred"]])
	check(p.lines[0].seller == "b_partner", "with one, the cooperation partner within the margin wins the sale")
	check(int(p.lines[0].unit_price) == pb, "at its own price: cooperation lowers no price and gives nothing away")
	var far_routes := TradeRoutes.table(ls, [["a_cheap", "c_buyer", 300, {"road": 1.0}], ["b_partner", "c_buyer", 4000, {"rough": 1.0}]])
	var p2 := RegionalMarket.plan(ls, far_routes, [["b_partner", "c_buyer", "preferred"]])
	check(p2.lines[0].seller == "a_cheap", "a partner far dearer than the margin does not")
	RegionalMarket.execute(p, ls)
	check(RegionalMarket.matched(ls) == "" and a.coins + b.coins + buyer.coins == 1000, "and the cooperative trade is matched and conserves coins")


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
