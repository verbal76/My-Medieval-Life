extends SceneTree
## Expansion 18, SET-C-SIM / SET-C-FIVE / ECON-P1.3 (owner 2026-10-23): the five neighbouring settlements are economies
## of their own, and their traders are the caravan.
##   - five settlements of mixed kinds on the lore's places, each with households (members, purses, pantries), a treasury
##     and businesses with their own tills, stocks and workers
##   - a daily step moves real coins and goods by the village's rules and conserves them: coins and goods of the whole
##     world including the five (the village less its outside sources plus the settlements' coins stays what it was)
##   - deterministic from the seed; saved and loaded without a trace (an older save is founded and its caravan purse becomes
##     the traders' coins); stepped through the morning one settlement an hour
##   - the caravan carries only goods the traders hold and pays only coins the traders hold; no allowance; the plough horse
##     comes from a settlement that has one
##   godot --headless --path game --script res://tests/regions_test.gd

const Census := preload("res://tests/census.gd")
const STEP := 0.5

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
	test_founding()
	test_daily_step()
	test_determinism_and_save()
	test_hunger_and_treasury()
	test_roads()
	test_world_caravan()
	test_old_save()
	test_horse()
	test_staggered_step()
	test_necessity_wages()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _json(d: Dictionary) -> String:
	return JSON.stringify(d, "", true, true)


# ------------------------------------------------------------------ the five ----------------
func test_founding() -> void:
	var r := Regions.create(1)
	check(r.list.size() == 5, "five settlements are founded")
	var kinds := {}
	for s: OffMapSettlement in r.list:
		kinds[s.kind] = true
	check(kinds.size() == 5, "of five different kinds (%s)" % ", ".join(kinds.keys()))
	var names := r.list.map(func(s): return s.name)
	check(names == ["Wulstead", "Netherton", "Garton", "Higham-on-the-Way", "Bourton Abbas"], "they are places from the lore's gazetteer (%s)" % ", ".join(names))
	var industries := {}
	for s: OffMapSettlement in r.list:
		for i in s.industries:
			industries[i] = true
	for i in ["forestry", "carpentry", "masonry", "smithing", "farming", "tanning", "trade", "mining"]:
		check(industries.has(i), "the owner's first industry %s is practised somewhere" % i)
	for s: OffMapSettlement in r.list:
		var members := 0
		var purses := 0
		var pantry := 0
		for h in s.hh:
			members += int(h.adults) + int(h.children)
			purses += int(h.coins)
			pantry += int(h.pantry.get("wheat", 0))
		check(s.households() >= 5 and members == s.population() and purses > 0 and pantry > 0, "%s: %d households, %d people, purses of %d coins, food in the pantries" % [s.name, s.households(), members, purses])
		check(int(s.gov.coins) > 0 and s.gov.officials.size() >= 1 and s.gov_name != "", "%s has a treasury of %d coins and officials (%s)" % [s.name, int(s.gov.coins), s.gov_name])
		check(s.biz.size() >= 4 and s.biz.has("merchant") and s.biz.has("farm"), "%s has businesses (%s) and a trader" % [s.name, ", ".join(s.biz.keys())])
		check(int(s.trader().till) > 0 and s.trader().workers.size() > 0, "%s: the trader has a till (%d coins) and %d households" % [s.name, int(s.trader().till), s.trader().workers.size()])
		check(s.audit() == "", "%s: the opening books balance" % s.name)
	var g: OffMapSettlement = r.by_id["garton"]
	check(int(g.biz.quarry.reserves.iron_ore) > 0 and int(g.biz.quarry.reserves.coal) > 0, "Garton's diggings hold finite iron ore and coal")
	check(r.by_id["wulstead"].horses() >= 1 and r.by_id["higham"].horses() >= 1, "Wulstead and Higham keep horses")
	var d := OffMapSettlement.data()
	check(int(d.tiles_per_mile) > 0 and int(r.by_id["higham"].miles) - int(r.by_id["wulstead"].miles) == 40, "Higham lies forty miles on from Wulstead, as the novel says")


# ------------------------------------------------------------------ a day, many days ----------------
func test_daily_step() -> void:
	var r := Regions.create(2)
	var coins0 := r.coins()
	var people0 := r.population()
	var ok := true
	var negative := ""
	for d in 60:
		r.step_day(d)
		var bad := r.audit()
		if bad != "":
			ok = false
			print("      " + bad)
			break
		for s: OffMapSettlement in r.list:
			for h in s.hh:
				if int(h.coins) < 0:
					negative = "household coins"
			for t in s.biz:
				if int(s.biz[t].till) < 0:
					negative = "till"
				for k in s.biz[t].stock:
					if int(s.biz[t].stock[k]) < 0:
						negative = "stock " + k
			if int(s.gov.coins) < 0:
				negative = "treasury"
	check(ok, "sixty days: every settlement's books balance after every day (coins and goods by their flow lines)")
	check(negative == "", "no purse, till, treasury or stock ever goes negative (%s)" % negative)
	check(r.coins() == coins0, "with no trade with the village not one coin is made or lost among the five (%d)" % coins0)
	var made := 0
	var used := 0
	var wages := 0
	var tax := 0
	var pay := 0
	var tolls := 0
	for s: OffMapSettlement in r.list:
		for k in s.flows.produced:
			made += int(s.flows.produced[k])
		for k in s.flows.used:
			used += int(s.flows.used[k])
		wages += int(s.flows.wages_paid)
		tax += int(s.flows.tax_households) + int(s.flows.tax_businesses)
		pay += int(s.flows.official_pay)
		tolls += int(s.flows.tolls)
	check(made > 0 and used > 0 and wages > 0 and tax > 0 and pay > 0 and tolls > 0, "they produce (%d), use (%d), pay wages (%d), collect tax (%d) and tolls (%d) and pay their officials (%d)" % [made, used, wages, tax, tolls, pay])
	check(r.population() >= people0 * 9 / 10, "and live: %d of %d people after sixty days" % [r.population(), people0])
	var prices := {}
	for s: OffMapSettlement in r.list:
		for k in s.prices:
			prices[k] = true
			var v := float(GameData.value(k))
			if float(s.prices[k]) < v * float(GameData.b("price_min")) - 0.001 or float(s.prices[k]) > v * float(GameData.b("price_max")) + 0.001:
				check(false, "%s: the price of %s (%.1f) stays inside the village's band" % [s.name, k, float(s.prices[k])])
	check(prices.size() > 5, "prices float with the day's imbalance inside the village's band (%d goods priced)" % prices.size())
	# the cost of a day, for the five together
	var r2 := Regions.create(3)
	var t0 := Time.get_ticks_usec()
	for d in 30:
		r2.step_day(d)
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / 30.0
	print("      a day for all five: %.2f ms" % ms)
	check(ms < 100.0, "a day's step for all five costs %.1f ms (a phone steps a fifth of it an hour)" % ms)


func test_determinism_and_save() -> void:
	var a := Regions.create(5)
	var b := Regions.create(5)
	for d in 40:
		a.step_day(d)
		b.step_day(d)
	check(_json(a.to_dict()) == _json(b.to_dict()), "the same seed gives the same settlements, day for day (40 days, byte-identical)")
	var c := Regions.create(6)
	for d in 40:
		c.step_day(d)
	check(_json(a.to_dict()) != _json(c.to_dict()), "another seed gives other settlements")
	# saved as JSON and loaded: the same, and it goes on the same
	var text := _json(a.to_dict())
	var l := Regions.from_dict(JSON.parse_string(text), 5)
	check(l != null and _json(l.to_dict()) == text, "saved as JSON and loaded, the settlements are exactly as they were")
	check(l.audit() == "", "and the loaded books balance")
	for d in range(40, 70):
		a.step_day(d)
		l.step_day(d)
	check(_json(a.to_dict()) == _json(l.to_dict()), "thirty days on, the loaded copy and the original are still identical")
	check(Regions.from_dict({"format": "mml-regions-world/99", "day": 1, "settlements": []}, 5) == null, "a section of an unknown format is refused, not reinterpreted")


func test_hunger_and_treasury() -> void:
	# a household with nothing to eat, nothing to buy it with and no one to help it starves (a settlement is allowed to
	# fail); its coins and food go to the treasury, not out of the books
	var spec: Dictionary = OffMapSettlement.data().settlements[1]            # Netherton
	var s := OffMapSettlement.create(spec, 7, 1)
	var h: Dictionary = s.hh[0]
	h.coins = 0
	h.pantry = {}
	s.gov.coins = 0
	for t in s.biz:
		s.biz[t].stock.clear()
		s.biz[t].till = 0
	for o in s.hh:
		if o != h:
			o.coins = 0
			o.pantry = {}
	s.start = {"coins": s.coins(), "goods": s.goods()}
	var people0 := s.population()
	var members0 := int(h.adults) + int(h.children)
	for d in 12:
		s.step_day(d)
	check(int(s.flows.deaths) > 0 and s.population() < people0, "with no food, no coin and no help people starve (%d died of %d)" % [int(s.flows.deaths), people0])
	check(int(h.adults) + int(h.children) < members0 or not h.alive, "the household that had nothing lost members")
	check(s.audit() == "", "and the books still balance")
	# the treasury collects the village's tax rule and pays its officials; a hard-up household is given day labour
	var t := OffMapSettlement.create(spec, 8, 1)
	t.hh[1].coins = 400
	t.start = {"coins": t.coins(), "goods": t.goods()}
	var treasury0 := int(t.gov.coins)
	var rich0 := int(t.hh[1].coins)
	t.step_day(0)
	check(int(t.hh[1].coins) < rich0 + 40 and int(t.flows.tax_households) > 0, "the treasury takes tax from a household with cash above the exemption (%d coins)" % int(t.flows.tax_households))
	check(int(t.flows.official_pay) > 0 and t.audit() == "", "and pays its officials (%d coins)" % int(t.flows.official_pay))
	var collected := int(t.flows.tax_households) + int(t.flows.tax_businesses) + int(t.flows.tolls)
	check(int(t.gov.coins) <= treasury0 + collected, "the treasury holds no more than it had and collected (%d, from %d)" % [int(t.gov.coins), treasury0])


func test_roads() -> void:
	var r := Regions.create(9)
	for d in 30:
		r.step_day(d)
	var rin := 0
	var gin := 0
	for s: OffMapSettlement in r.list:
		rin += int(s.flows.road_coins_in)
		for k in s.flows.road_in:
			gin += int(s.flows.road_in[k])
	check(r.audit() == "", "after the traders' wholesale rounds the books still balance (and their road coins and goods cancel)")
	print("      road trade in 30 days: %d goods, %d coins" % [gin, rin])
	check(gin > 0 and rin > 0, "the traders did trade among themselves in thirty days (%d goods)" % gin)


# ------------------------------------------------------------------ the caravan ----------------
func _world(seed_: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


## The whole world's coins less the ones that came from outside it (outlaws, heirs, newcomers): the village's coins plus the
## settlements', less coin_sources (which moves the other way by what the village pays the settlements, net) less that net.
## Constant through any trade.
func _net(w: World) -> int:
	return w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village())


func test_world_caravan() -> void:
	var w := _world(1)
	check(w.regions != null and w.regions.list.size() == 5, "a new world has the five settlements")
	check(w.get("caravan_purse") == null, "the caravan has no purse of its own")
	check(not GameData.balance.has("caravan_allowance") and not GameData.balance.has("caravan_float"), "the daily allowance and the float are gone from the balance data")
	var net0 := _net(w)
	# the village has surplus to sell (the merchants' planks, the smiths' bars) so the traders have something to buy
	for o: NPC in w.npcs:
		if o.alive and o.job == "smith":
			o.inv.add("iron_bar", 12)
		if o.alive and o.job == "merchant":
			o.inv.add("plank", 20)
	# the first visit: every trader is on the road; they pay with the coins in their tills, at 0.8 x value
	var on_road: Array = w.regions.visiting(w.day())
	check(on_road.size() == 5, "on the first visit all five traders come")
	var tills0 := {}
	for s: OffMapSettlement in on_road:
		tills0[s.id] = int(s.trader().till)
	var village0 := w.total_coins()
	w.brain.caravan()
	var paid_to_village := 0
	var paid_by_village := 0
	for s: OffMapSettlement in on_road:
		paid_to_village += int(s.flows.coins_to_village)
		paid_by_village += int(s.flows.coins_from_village)
		check(int(s.trader().till) >= int(OffMapSettlement.rules().trader_reserve_floor) or int(s.trader().till) == tills0[s.id], "%s's trader paid out only coins it held (till %d from %d)" % [s.name, int(s.trader().till), tills0[s.id]])
		check(s.audit() == "", "%s: its books balance after the visit" % s.name)
	check(w.total_coins() - village0 == paid_to_village - paid_by_village, "the village's coins changed by exactly what the traders paid and were paid")
	check(_net(w) == net0, "the whole world's coins (the village's plus the settlements') changed by nothing but what came from outside the world: none made, none lost")
	check(w.coin_sources == paid_to_village - paid_by_village and w.coin_sources == w.regions.net_paid_by_village() * 0 + (paid_to_village - paid_by_village), "the village's outside sources are exactly what crossed the boundary")
	check(w.regions.net_paid_by_village() == -w.coin_sources, "and the settlements' side says the same: they were paid what the village paid")
	var sold_to_village := {}
	var bought_from_village := {}
	for s: OffMapSettlement in w.regions.list:
		for k in s.flows.to_village:
			sold_to_village[k] = int(sold_to_village.get(k, 0)) + int(s.flows.to_village[k])
		for k in s.flows.from_village:
			bought_from_village[k] = int(bought_from_village.get(k, 0)) + int(s.flows.from_village[k])
	var imp := 0
	var exp := 0
	for k in w.stats.keys():
		if str(k).begins_with("imported_"):
			check(int(w.stats[k]) == int(sold_to_village.get(str(k).substr(9), 0)), "what the village imported (%s: %d) is what the traders sold" % [str(k).substr(9), int(w.stats[k])])
			imp += int(w.stats[k])
		elif str(k).begins_with("exported_"):
			check(int(w.stats[k]) == int(bought_from_village.get(str(k).substr(9), 0)), "what the village exported (%s: %d) is what the traders bought" % [str(k).substr(9), int(w.stats[k])])
			exp += int(w.stats[k])
	check(exp > 0, "the traders bought goods the village had to spare (%d units)" % exp)
	check(imp > 0, "and sold the village what they carry (%d units)" % imp)
	# they buy only what their settlement wants and can pay for
	var wants_all := true
	for k in bought_from_village:
		var any := false
		for s: OffMapSettlement in w.regions.list:
			if int(s.flows.from_village.get(k, 0)) > 0:
				any = true
		wants_all = wants_all and any
	check(wants_all, "every good they bought went to a settlement that wanted it")
	# a trader with no coins buys nothing; a trader with no stone sells none
	var w2 := _world(1)
	for s: OffMapSettlement in w2.regions.list:
		s.trader().till = 0
		s.start.coins = s.coins()          # the books reopen with empty tills
	w2.brain.caravan()
	check(int(w2.stats.get("caravan_coins_in", 0)) == 0 and w2.coin_sources <= 0, "traders with empty tills buy nothing from the village (no allowance makes up for it); the village only paid them")
	var w3 := _world(1)
	for s: OffMapSettlement in w3.regions.list:
		var m: Dictionary = s.trader()
		m.stock.clear()
		s.start.goods = s.goods()
	var exp3 := 0
	w3.brain.caravan()
	for k in w3.stats:
		if str(k).begins_with("imported_"):
			exp3 += int(w3.stats[k])
	check(exp3 == 0, "traders with nothing on their carts sell the village nothing (an empty trip)")
	# the visiting rhythm: the nearer come more often
	var counts := {}
	for day in range(0, 48):
		if day % 2 == 1:
			for s: OffMapSettlement in w.regions.visiting(day):
				counts[s.id] = int(counts.get(s.id, 0)) + 1
	check(int(counts.wulstead) > int(counts.netherton) and int(counts.netherton) > int(counts.bourton), "the nearer settlements' traders come more often (%s)" % str(counts))
	# a year of the village with the traders: the ledger balances
	var w4 := _world(2)
	for i in int(2.0 * 1440.0 / float(GameData.b("game_minutes_per_second")) / STEP):
		w4.update(STEP)
		w4.player.hunger = 100.0
	check(w4.regions.audit() == "", "two days of the whole world: every settlement's books balance")
	check(w4.regions.list[0].day == 2 or w4.regions.list[0].day == 1, "the settlements took their steps with the village's days (day %d)" % w4.regions.list[0].day)


func test_old_save() -> void:
	var w := _world(3)
	for i in int(1.5 * 1440.0 / float(GameData.b("game_minutes_per_second")) / STEP):
		w.update(STEP)
		w.player.hunger = 100.0
	var text := _json(w.to_dict())
	var d: Dictionary = JSON.parse_string(text)
	check(d.has("regions") and not d.has("caravan_purse"), "a save carries the five settlements and no caravan purse")
	var map := VillageMap.load_default()
	var w2 := World.new()
	w2.load_dict(map, d)
	check(_json(w2.regions.to_dict()) == _json(w.regions.to_dict()), "loaded, the settlements are exactly as saved")
	check(w2.coin_sources == w.coin_sources and w2.total_coins() == w.total_coins() and _net(w2) == _net(w), "and no coin changed")
	# an older save: no settlements, a caravan purse
	var old: Dictionary = JSON.parse_string(text)
	old.erase("regions")
	old["caravan_purse"] = 321
	var w3 := World.new()
	w3.load_dict(map, old)
	check(w3.regions.list.size() == 5 and w3.regions.audit() == "", "an older save is given the five settlements, founded from its seed, and their books balance")
	var traders := 0
	for s: OffMapSettlement in w3.regions.list:
		traders += int(s.flows.migrated_in)
	check(traders == 321 and w3.regions.migrated_coins == 321, "its caravan purse of 321 coins became the traders' own")
	check(w3.total_coins() == w.total_coins() and w3.coin_sources == w.coin_sources, "no village coin changed hands")
	check(w3.regions.list[0].day >= 0, "the founded settlements were stepped up to the saved day (day %d)" % w3.regions.list[0].day)
	var again := World.new()
	again.load_dict(map, old)
	check(_json(again.regions.to_dict()) == _json(w3.regions.to_dict()), "founding an older save twice gives the same settlements")


func test_horse() -> void:
	var w := _world(1)
	var farm: Farming = w.farm
	var dealer: OffMapSettlement = w.regions.horse_dealer(1)
	check(dealer != null and dealer.id == "wulstead", "the nearest dealer with a horse on the road is Wulstead's")
	var h0 := dealer.horses()
	var till0 := int(dealer.biz.farm.till)
	check(w.regions.horse_dealer(1).has_horse(), "it has a horse to sell")
	var price := int(Farming.cfg().caravan_horse.price)
	check(dealer.sell_horse(price) and dealer.horses() == h0 - 1 and int(dealer.biz.farm.till) == till0 + price, "selling a horse takes one from the settlement's herd and puts the price in the till of the farm that kept it")
	check(dealer.audit() == "", "its books balance (the horse and the coins are lines)")
	# none of today's traders has a horse
	for s: OffMapSettlement in w.regions.list:
		while s.has_horse():
			s.sell_horse(1)
	check(w.regions.horse_dealer(1) == null, "when no trader on the road has a horse, none is for sale")
	w.minutes = 1.0 * 1440.0 + 13.0 * 60.0
	w.player.coins = 500
	check(farm.buy_horse_refusal(w.player).contains("horse"), "the farm refuses: %s" % farm.buy_horse_refusal(w.player))
	# a horse is bred from a pair that is fed
	var r := Regions.create(4)
	var wul: OffMapSettlement = r.by_id["wulstead"]
	var n0 := wul.horses()
	for d in 100:
		r.step_day(d)
	check(r.audit() == "", "a hundred days of feeding and foaling: the horse count has its lines (born %d, died %d)" % [int(wul.flows.horses_foaled), int(wul.flows.horses_died)])
	print("      Wulstead's horses: %d to %d" % [n0, wul.horses()])


func test_staggered_step() -> void:
	var r := Regions.create(1)
	r.step_hour(0, 7)
	var done := r.list.filter(func(s): return s.day == 0).size()
	check(done == 2, "the settlements step one an hour from six (by 07:00 two have taken day 0's step)")
	r.step_hour(0, 10)
	check(r.list.all(func(s): return s.day == 0) and r.day == 0, "by ten o'clock all five have")
	r.step_hour(0, 11)
	check(r.list.all(func(s): return s.day == 0), "a later hour of the same day steps nothing twice")
	r.step_hour(1, 6)
	check(r.list.filter(func(s): return s.day == 1).size() == 1, "the next morning starts again with the first")


## REG-INV-01 / PAR-02A: a business's working reserve never keeps its own hungry worker household from a day's food; a
## household that is not hungry, or can still buy a day's food, is paid only from the till above the reserve.
func test_necessity_wages() -> void:
	var r := Regions.create(1)
	var s: OffMapSettlement = r.by_id["higham"]
	var m: Dictionary = s.trader()
	var i: int = m.workers[0]
	var h: Dictionary = s.hh[i]
	m.till = int(m.reserve) - 1          # below the working reserve: nothing above it to pay out (set by the test)
	h.coins = 0
	h.hungry = 1
	var till0 := int(m.till)
	var coins0 := s.coins()
	s._pay_wages()
	var wage := int(s.btype("merchant").get("wage", 8))
	check(int(h.coins) == wage and int(m.till) == till0 - wage, "a hungry worker household with no coins is paid its wage below the reserve (%d coins)" % int(h.coins))
	check(s.coins() == coins0, "the wage only moves coins from the till to the purse (%d before, %d after)" % [coins0, s.coins()])
	var h2: Dictionary = s.hh[m.workers[1]] if m.workers.size() > 1 else {}
	if not h2.is_empty():
		h2.hungry = 0
		h2.coins = 0
		m.till = int(m.reserve) - 1
		s._pay_wages()
		check(int(h2.coins) == 0, "a worker household that is not hungry is not paid from below the reserve")
