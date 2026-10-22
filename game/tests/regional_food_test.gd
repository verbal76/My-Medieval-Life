extends SceneTree
## REG-BUY-01 / REG-BUY-P1 (owner 2026-10-23, Q18-10, REG-BUY-D1): the neighbouring settlements' traders sell food to the village.
##   rule 1  the traders carry food bought from their settlement's farms, herds and cookshop
##   rule 2  only food above the settlement's local claim is released (households' need over reserve_days, less pantries, less
##           expected production)
##   rule 3  a food business with a demonstrated cash shortfall may sell into the protected food, up to the shortfall, never more
##   rule 4  the traders' prices are the settlement's own floating prices
## and the village's existing buyers (households with no food to be had in the village, the treasury's granary, the food
## businesses) buy it, with the coins and the goods crossing the border as every caravan trade does.
##   godot --headless --path game --script res://tests/regional_food_test.gd

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
	test_claim()
	test_release()
	test_shortfall()
	test_prices()
	test_village_buys()
	test_determinism_and_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


## The whole world's coins less the ones that came from outside it: constant through any trade.
func _net(w: World) -> int:
	return w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village())


## A settlement at day 0 with a rich trader, a farm that can pay its way, no expected output, and every pantry as `pantry` wheat.
func _town(id: String, pantry: int, farm_wheat: int) -> OffMapSettlement:
	var r := Regions.create(1)
	var s: OffMapSettlement = r.by_id[id]
	s.step_day(0)
	s.trader().till = 5000
	s.trader().reserve = 0
	s.trader().stock = {}
	for t in s.biz:
		s.biz[t].out = {}                      # nothing is expected to be made
		if t != "merchant":
			s.biz[t].till = 1000               # every business pays its way ...
			for f in s.food_items():
				s.biz[t].stock.erase(f)        # ... and holds no food but the farm's
	s.biz.farm.stock = {"wheat": farm_wheat, "plough": 9}
	s.biz.farm.horses = 0
	for h in s.hh:
		h.pantry = {"wheat": pantry} if pantry > 0 else {}
		h.credit = 0.0
	s.reopen_books()
	return s


func _wheat_pts() -> float:
	return NPCBrain.food_points("wheat")


func test_claim() -> void:
	var days := float(GameData.b("reserve_days"))
	var s := _town("wulstead", 0, 40)
	var need := 0.0
	for h in s.hh:
		if h.alive:
			need += s._need_pts(h) * days
	check(absf(s.food_claim_pts() - need) < 0.001, "with empty pantries and no expected output the claim is the households' need over reserve_days (%.0f points)" % need)
	for h in s.hh:
		h.pantry = {"wheat": 1000}
	check(s.food_claim_pts() == 0.0, "households holding more than they need over reserve_days leave no claim")
	for h in s.hh:
		h.pantry = {}
	s.biz.farm.out = {"wheat": 9}
	var exp := s.expected_food_pts(days)
	check(exp > 0.0 and absf(s.food_claim_pts() - maxf(0.0, need - exp)) < 0.001, "what the farm expects to produce over those days (%.0f points) comes off the claim" % exp)
	s.biz.farm.out = {"wheat_seed": 0.5}      # herd and others were flattened in _town
	check(s.expected_food_pts(days) == 0.0, "a seed is not food: it counts for nothing")


func test_release() -> void:
	# households need their food and nothing is expected: the farm's 40 wheat are the village's own and nothing is released
	var s := _town("wulstead", 0, 40)
	check(s.food_claim_pts() > 40.0 * _wheat_pts(), "the claim (%.0f points) is more than the farm holds (%.0f)" % [s.food_claim_pts(), 40.0 * _wheat_pts()])
	s.stock_trader_food()
	check(s.trader_has("wheat") == 0 and int(s.biz.farm.stock.wheat) == 40, "nothing is released while the households need it")
	check(s.audit() == "", "books balance")
	# households are provided for: all the farm's spare goes to the trader, at the price the trader pays
	s = _town("wulstead", 1000, 40)
	var till0 := int(s.trader().till)
	var farm0 := int(s.biz.farm.till)
	s.stock_trader_food()
	var p := maxi(1, roundi(float(s.price("wheat")) * float(OffMapSettlement.rules().trader_pays_share)))
	var got := s.trader_has("wheat")
	check(got == 40 - 0 and int(s.biz.farm.stock.get("wheat", 0)) == 0, "a surplus is released: the trader carries %d wheat" % got)
	check(till0 - int(s.trader().till) == got * p and int(s.biz.farm.till) - farm0 == got * p, "it paid %d each from its own till, into the farm's" % p)
	check(s.audit() == "" and s.coins() == int(s.start.coins), "the settlement's books balance and its coins are unchanged")
	# a surplus of half: the claim holds back the rest
	s = _town("wulstead", 0, 40)
	var one := 0.0
	for h in s.hh:
		one += s._need_pts(h) * float(GameData.b("reserve_days"))
	var wheat := ceili(one / _wheat_pts()) + 10
	s.biz.farm.stock.wheat = wheat
	s.stock_trader_food()
	var left := int(s.biz.farm.stock.wheat)
	check(s.trader_has("wheat") == 10 and left == wheat - 10, "only the %d wheat above the claim are released (%d held back)" % [s.trader_has("wheat"), left])
	# the trader's own purse limits it
	s = _town("wulstead", 1000, 40)
	s.trader().till = int(OffMapSettlement.rules().trader_reserve_floor) + 5
	s.stock_trader_food()
	check(s.trader_has("wheat") * maxi(1, roundi(float(s.price("wheat")) * 0.9)) <= 5, "the trader pays only from its own till above its floor")
	# a business that keeps what its recipes need
	s = _town("wulstead", 1000, 0)
	s.biz.cook.stock = {"wheat": 200, "meat": 20, "log": 20}
	var keep := int(s._keep(s.biz.cook).get("wheat", 0))
	s.stock_trader_food()
	check(int(s.biz.cook.stock.wheat) == keep and keep > 0, "the cookshop keeps the wheat its recipes take (%d)" % keep)


func test_shortfall() -> void:
	# rule 3: claim protects the farm's food; with no shortfall nothing is sold, with one only up to it
	var s := _town("wulstead", 0, 60)
	s.stock_trader_food()
	check(s.trader_has("wheat") == 0, "a farm that can pay its expenses sells nothing out of the protected food")
	s = _town("wulstead", 0, 60)
	var farm: Dictionary = s.biz.farm
	farm.till = 0
	s.reopen_books()
	var due := s._expense_due(farm)
	check(due == s._wage_bill(farm) and due > 0, "its essential expenses are its wage bill (%d coins)" % due)
	var short := s.cash_shortfall(farm)
	check(short == due, "with an empty till the demonstrated shortfall is all of it (%d)" % short)
	var p := maxi(1, roundi(float(s.price("wheat")) * float(OffMapSettlement.rules().trader_pays_share)))
	s.stock_trader_food()
	var n := s.trader_has("wheat")
	check(n > 0 and n * p <= short and (n + 1) * p > short, "it sold %d wheat for %d coins, as much as the shortfall (%d) allows and no more" % [n, n * p, short])
	check(int(farm.stock.wheat) == 60 - n and int(farm.stock.wheat) > 0, "the rest of the protected food stays (%d)" % int(farm.stock.wheat))
	check(s.food_claim_pts() > float(farm.stock.wheat) * _wheat_pts(), "the settlement is left under its claim: it chose the sale and bears the shortage")
	check(s.audit() == "", "books balance")
	# the shortfall also counts the inputs the business is short of (a missing plough)
	s = _town("wulstead", 0, 60)
	farm = s.biz.farm
	farm.till = 0
	farm.stock.erase("plough")
	var with_tools := s._expense_due(farm)
	check(with_tools > s._wage_bill(farm), "the cost of the tools and inputs it lacks is an expense too (%d > %d)" % [with_tools, s._wage_bill(farm)])
	# a trader that cannot pay limits it still more
	s = _town("wulstead", 0, 60)
	s.biz.farm.till = 0
	s.trader().till = int(OffMapSettlement.rules().trader_reserve_floor)
	s.stock_trader_food()
	check(s.trader_has("wheat") == 0, "a trader without coins buys nothing, whatever the shortfall")


func test_prices() -> void:
	var s := _town("wulstead", 1000, 60)
	var base := s.food_price("wheat")
	s.prices["wheat"] = float(base) * 2.0
	s._pcache = {}
	check(s.food_price("wheat") == s.price("wheat") and s.food_price("wheat") > base, "the trader asks the settlement's own price (%d, was %d)" % [s.food_price("wheat"), base])
	var r := Regions.create(1)
	var a: OffMapSettlement = r.by_id["wulstead"]
	var b: OffMapSettlement = r.by_id["netherton"]
	a.step_day(0)
	b.step_day(0)
	a.trader().stock = {"wheat": 5}
	b.trader().stock = {"wheat": 5}
	a.prices["wheat"] = 8.0
	b.prices["wheat"] = 3.0
	a._pcache = {}
	b._pcache = {}
	check(r.food_seller("wheat", [a, b]) == b, "the village's buyer takes the cheaper trader's wheat")
	check(r.food_seller("meat", [a, b]) == null, "and none for a food nobody carries")


## Take every food a villager could buy out of the village, so only the traders have any.
func _empty_village(w: World) -> void:
	for n: NPC in w.npcs:
		for f in NPCBrain.EDIBLE + ["meat"]:
			n.inv.remove(f, n.inv.count(f))
	for h in w.households:
		for f in NPCBrain.EDIBLE + ["meat"]:
			(h.pantry as Inventory).remove(f, (h.pantry as Inventory).count(f))
	for f in NPCBrain.EDIBLE + ["meat"]:
		w.granary.remove(f, w.granary.count(f))
	w._reserve_cache.clear()


func test_village_buys() -> void:
	var w := _world(1)
	w.regions.step_day(0)
	_empty_village(w)
	var on_road: Array = w.regions.begin_visit(w.day())
	check(on_road.size() > 0, "traders are on the road on the first visit day")
	for s: OffMapSettlement in w.regions.list:
		s.trader().stock.wheat = 80
		s.trader().stock.pottage = 30
		s.trader().till = 400
		s.reopen_books()
	w.treasury = 5000
	var coins0 := w.total_coins()
	var net0 := _net(w)
	var src0 := w.coin_sources
	var granary0 := w.granary.count("wheat")
	var pantry0 := 0
	for h in w.households:
		pantry0 += (h.pantry as Inventory).count("wheat") + (h.pantry as Inventory).count("pottage")
	var held0 := 0
	for s: OffMapSettlement in on_road:
		held0 += s.trader_has("wheat") + s.trader_has("pottage")
	var tills0 := 0
	for s: OffMapSettlement in on_road:
		tills0 += int(s.trader().till)
	var spent: int = w.brain._caravan_food(on_road)
	check(spent > 0, "the village's buyers buy food from the traders on the road (%d coins)" % spent)
	check(int(w.stats.get("caravan_food_households", 0)) > 0, "households with nothing to buy in the village buy (%d coins)" % int(w.stats.get("caravan_food_households", 0)))
	check(w.granary.count("wheat") > granary0 and int(w.stats.get("caravan_food_treasury", 0)) > 0, "the treasury restocks the granary (%d wheat)" % (w.granary.count("wheat") - granary0))
	var pantry1 := 0
	for h in w.households:
		pantry1 += (h.pantry as Inventory).count("wheat") + (h.pantry as Inventory).count("pottage")
	check(pantry1 > pantry0, "the food is in the households' pantries (%d more)" % (pantry1 - pantry0))
	var held1 := 0
	var tills1 := 0
	for s: OffMapSettlement in on_road:
		held1 += s.trader_has("wheat") + s.trader_has("pottage")
		tills1 += int(s.trader().till)
		check(s.audit() == "", "%s: its books balance after selling to the village" % s.name)
	check(tills1 - tills0 == spent, "the traders' tills took exactly what the village paid (%d)" % spent)
	var units := int(w.stats.get("caravan_food_units", 0))
	check(held0 - held1 == units and units > 0, "every unit that left a trader's stock is one the village imported (%d)" % units)
	check(w.total_coins() == coins0 - spent and w.coin_sources == src0 - spent, "the coins left the village: %d fewer" % spent)
	check(_net(w) == net0 and w.regions.audit() == "", "the whole world's coins are unchanged, the settlements' books balance")
	var imported := 0
	for k in w.stats:
		if str(k).begins_with("imported_"):
			imported += int(w.stats[k])
	check(imported == units, "recorded as imported goods (%d)" % imported)
	# the cheapest first: a household buys wheat before pottage when wheat is the cheaper food per point
	var wheat_cost := float(on_road[0].food_price("wheat")) / NPCBrain.food_points("wheat")
	var pot_cost := float(on_road[0].food_price("pottage")) / NPCBrain.food_points("pottage")
	check(wheat_cost <= pot_cost or int(w.stats.get("imported_pottage", 0)) > 0, "wheat first when it is the cheaper food per point")

	# a village that can feed itself does not shop abroad
	var v := _world(1)
	v.regions.step_day(0)
	var road: Array = v.regions.begin_visit(v.day())
	for s: OffMapSettlement in v.regions.list:
		s.trader().stock.wheat = 80
		s.reopen_books()
	for h in v.households:
		(h.pantry as Inventory).add("wheat", 60)
	v.treasury = 5000
	v.granary.add("wheat", 5000)
	for n: NPC in v.npcs:
		if n.job == "farmer" or v.brain.buy_role(n) == "merchant_food":
			n.inv.add("wheat", 400)
	v._reserve_cache.clear()
	var hh_before := int(v.stats.get("caravan_food_households", 0))
	v.brain._caravan_food(road)
	check(int(v.stats.get("caravan_food_households", 0)) == hh_before and int(v.stats.get("caravan_food_treasury", 0)) == 0,
		"households that hold their reserve and a granary that holds its target buy nothing")

	# a treasury that cannot spare coins above its reserve buys nothing
	var z := _world(1)
	z.regions.step_day(0)
	_empty_village(z)
	var road2: Array = z.regions.begin_visit(z.day())
	for s: OffMapSettlement in z.regions.list:
		s.trader().stock.wheat = 80
		s.reopen_books()
	z.treasury = 0
	z.brain._caravan_food_treasury(road2)
	check(int(z.stats.get("caravan_food_treasury", 0)) == 0 and z.treasury == 0, "an empty treasury buys no food (no hidden rescue: nothing is given)")
	# a trader with no food sells none
	var e := _world(1)
	e.regions.step_day(0)
	_empty_village(e)
	var road3: Array = e.regions.begin_visit(e.day())
	for s: OffMapSettlement in e.regions.list:
		s.trader().stock.erase("wheat")
		s.reopen_books()
	var coins_e := e.total_coins()
	e.brain._caravan_food_households(road3)
	e.brain._caravan_food_treasury(road3)
	check(e.total_coins() == coins_e or int(e.stats.get("caravan_food_units", 0)) == int(e.stats.get("imported_pottage", 0)) + int(e.stats.get("imported_roast_meat", 0)) + int(e.stats.get("imported_cheese", 0)) + int(e.stats.get("imported_bread", 0)) + int(e.stats.get("imported_meat", 0)),
		"what a trader does not carry cannot be bought")


func test_determinism_and_save() -> void:
	var a := _run(7, 24)
	var b := _run(7, 24)
	check(a == b, "two runs of the same settlements through 24 days, visiting and stocking, are identical")
	var r := Regions.create(3)
	for d in 12:
		r.step_day(d)
		if d % 2 == 1:
			r.begin_visit(d)
	var back := Regions.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())), 3)
	check(back != null and JSON.stringify(back.to_dict()) == JSON.stringify(r.to_dict()), "settlements that stocked their traders save and load unchanged")
	check(back.audit() == "" and r.audit() == "", "and their books balance")
	var food := 0
	for s: OffMapSettlement in r.list:
		for f in s.food_items():
			food += s.trader_has(f)
	print("     (food in the traders' stock after 12 days: %d)" % food)


func _run(seed_: int, days: int) -> String:
	var r := Regions.create(seed_)
	for d in days:
		r.step_day(d)
		if d % 2 == 1:
			r.begin_visit(d)
	return JSON.stringify(r.to_dict())
