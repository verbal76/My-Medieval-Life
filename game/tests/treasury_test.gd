extends SceneTree
## TREAS-01 (owner directive 2026-10-21, section 5: the manor treasury as the village's reserve). Income reaches the
## treasury from the party that pays it; in a shortage the manor buys real food from real sellers with treasury coins,
## the goods become the manor's and relief gives only what the manor holds; its own stock (the granary, grain and other
## food) is given before a coin is spent; with no stock and no seller nothing is given and nothing is paid; the treasury
## never goes below its floor or below zero. Every check counts all coins (World.total_coins) and every good (the
## census economy_sim uses) before and after: nothing made, nothing lost.
##   godot --headless --path game --script res://tests/treasury_test.gd

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


func _init() -> void:
	GameData.ensure()
	income()
	relief_buys_into_manor_stock()
	granary_stock_first()
	nothing_from_nothing()
	finite_treasury()
	carried_relief()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


## Every coin and good, to compare before and after an operation.
func snapshot(w: World) -> Dictionary:
	return {"coins": w.total_coins(), "goods": Census.goods(w)}


func same(a: Dictionary, b: Dictionary) -> bool:
	return int(a.coins) == int(b.coins) and JSON.stringify(a.goods) == JSON.stringify(b.goods)


func diff(a: Dictionary, b: Dictionary) -> String:
	var out := []
	var ids: Array = (a.goods as Dictionary).keys() + (b.goods as Dictionary).keys()
	ids.sort()
	for id in ids:
		if int(a.goods.get(id, 0)) != int(b.goods.get(id, 0)) and not out.has("%s" % id):
			out.append("%s %d->%d" % [id, int(a.goods.get(id, 0)), int(b.goods.get(id, 0))])
	return "coins %d->%d; %s" % [int(a.coins), int(b.coins), ", ".join(out)]


## Empty every store of food (households, villagers, the granary), and every household's coins, but keep `keep`
## households' pantries filled to their reserve so only `hungry` ones need relief.
func strip(w: World, hungry: Array) -> void:
	for h in w.households.size():
		var mem: Array = w.brain._members(h)
		for m: NPC in mem:
			m.coins = 0
		var p: Inventory = w.households[h].pantry
		for id in NPCBrain.EDIBLE + ["meat", "log"]:
			p.items.erase(id)
		if not hungry.has(h) and not mem.is_empty():
			p.add("pottage", ceili(float(GameData.b("reserve_days")) * w.brain.household_day_food(h) / NPCBrain.food_points("pottage")))
	for id in NPCBrain.EDIBLE + ["meat"]:
		w.granary.items.erase(id)
	for o: NPC in w.npcs:
		for id in NPCBrain.EDIBLE + ["meat"]:
			o.inv.items.erase(id)
	w._price_cache.clear()
	w._reserve_cache.clear()


func a_household(w: World) -> int:
	for h in w.households.size():
		if not w.brain._members(h).is_empty() and h >= 3:
			return h
	return -1


## Taxes and land sales: the treasury gains exactly what the payers lose; nothing else changes.
func income() -> void:
	var w := new_world()
	var obl: float = w.brain.daily_obligations()
	w.treasury = int(obl)                                   # under the reserve: taxed at the higher rate
	var h := a_household(w)
	for m: NPC in w.brain._members(h):
		m.coins = 500
	var before := snapshot(w)
	var t0 := w.treasury
	var paid0 := 0
	for m: NPC in w.brain._members(h):
		paid0 += m.coins
	var tax0 := float(w.stats.get("gov_tax", 0.0))
	w.brain.reeve_day()
	var paid1 := 0
	for m: NPC in w.brain._members(h):
		paid1 += m.coins
	var taxed := int(float(w.stats.get("gov_tax", 0.0)) - tax0)
	check(taxed > 0 and paid0 - paid1 >= 0, "tax: the manor taxes cash above a household's needs (%d coins in all; hh%d paid %d)" % [taxed, h, paid0 - paid1])
	check(int(snapshot(w).coins) == int(before.coins), "tax and the evening's spending only move coins (%d before, %d after)" % [int(before.coins), w.total_coins()])
	# a plot bought from the manor: its price goes from the buyer's purse into the treasury
	var w2 := new_world()
	w2.player.coins = 5000
	var pl: Dictionary = {}
	for p in w2.plots:
		if w2.property.for_sale(p):
			pl = p
			break
	var price: int = w2.property.price_of(pl)
	var tb := w2.treasury
	var cb := w2.total_coins()
	var why: String = w2.property.buy(pl, World.PLAYER)
	check(why == "" and w2.treasury == tb + price and w2.player.coins == 5000 - price and w2.total_coins() == cb,
		"a plot sold by the manor: %d coins from the buyer into the treasury, the total unchanged (%s)" % [price, why])
	# a lease's first week, from a household's members
	var w3 := new_world()
	var h3 := a_household(w3)
	for m: NPC in w3.brain._members(h3):
		m.coins = 300
	var let: Dictionary = {}
	for p in w3.plots:
		if w3.property.for_sale(p):
			let = p
			break
	var rent: int = w3.property.rent_of(let)
	var t3 := w3.treasury
	var c3 := w3.total_coins()
	var lw: String = w3.property.lease(let, World.hh_ref(h3))
	check(lw == "" and w3.treasury == t3 + rent and w3.total_coins() == c3,
		"a lease's first week: %d coins from hh%d's purses into the treasury (%s)" % [rent, h3, lw])


## A shortage: the granary empty, one household with nothing, a farmer with grain to spare and a tavern with bread.
## The manor pays the sellers from the treasury (coins only move: the sellers gain what the treasury loses), the goods
## pass through the manor's store, and the household's pantry gains exactly what the sellers lost.
func relief_buys_into_manor_stock() -> void:
	var w := new_world()
	var h := a_household(w)
	strip(w, [h])
	w.treasury = 100000
	var farmer: NPC = w.npcs.filter(func(o): return o.alive and o.job == "farmer" and o.household != h)[0]
	farmer.inv.add("wheat", w.brain.keep_wheat(farmer) + 4)
	var keeper: NPC = w.npcs.filter(func(o): return o.alive and o.job == "tavernkeeper" and o.household != h)[0]
	keeper.inv.add("bread", 6)
	var before := snapshot(w)
	var t0 := w.treasury
	var sellers0 := farmer.coins + keeper.coins
	var farmer_wheat0 := farmer.inv.count("wheat")
	var bread0 := keeper.inv.count("bread")
	var days: float = w.brain.household_food_days(h)
	var helped: int = w.brain._relief(w.brain.daily_obligations(), 0.0)
	var pantry: Inventory = w.households[h].pantry
	var got_wheat := farmer_wheat0 - farmer.inv.count("wheat")
	var got_bread := bread0 - keeper.inv.count("bread")
	var spent := t0 - w.treasury
	check(days < 1.0 and helped == 1 and spent > 0, "shortage: hh%d with %.2f days of food is helped, the treasury paying %d coins" % [h, days, spent])
	check(farmer.coins + keeper.coins - sellers0 == spent, "the sellers receive exactly what the treasury pays (%d)" % spent)
	check(pantry.count("wheat") == got_wheat and pantry.count("bread") == got_bread and got_wheat + got_bread > 0,
		"the pantry gains exactly what the sellers gave up (%d wheat, %d bread)" % [got_wheat, got_bread])
	check(w.granary.total() == 0, "bought goods pass through the manor's store and none is left behind or made there")
	check(float(w.stats.get("gov_relief_bought", 0.0)) == float(spent), "every coin spent is recorded (gov_relief_bought %d)" % int(w.stats.get("gov_relief_bought", 0.0)))
	check(same(before, snapshot(w)), "no coin or good made or lost (%s)" % diff(before, snapshot(w)))


## The manor's own food first: bread and cheese in the granary (a house's stores fallen to it) are given before any coin
## is spent, though a seller has food.
func granary_stock_first() -> void:
	var w := new_world()
	var h := a_household(w)
	strip(w, [h])
	w.treasury = 100000
	var need: float = float(GameData.b("relief_fill_days")) * w.brain.household_day_food(h)
	var bread := ceili(need / NPCBrain.food_points("bread")) + 2
	w.granary.add("bread", bread)
	var keeper: NPC = w.npcs.filter(func(o): return o.alive and o.job == "tavernkeeper" and o.household != h)[0]
	keeper.inv.add("bread", 6)
	var before := snapshot(w)
	var t0 := w.treasury
	w.brain._relief(w.brain.daily_obligations(), 0.0)
	var given := bread - w.granary.count("bread")
	check(given > 0 and w.households[h].pantry.count("bread") == given and w.treasury == t0 and keeper.inv.count("bread") == 6,
		"the granary's bread (not grain) is given first: %d of %d, no coin spent, the tavern's bread untouched" % [given, bread])
	check(w.granary.count("bread") > 0, "and only what is needed: %d left in the granary" % w.granary.count("bread"))
	check(same(before, snapshot(w)), "no coin or good made or lost (%s)" % diff(before, snapshot(w)))


## No stock anywhere and no seller: nothing is given, nothing paid, nothing made, whatever the treasury holds.
func nothing_from_nothing() -> void:
	var w := new_world()
	var h := a_household(w)
	strip(w, [h])
	# nobody else has food to spare either: every pantry emptied
	for hh in w.households:
		for id in NPCBrain.EDIBLE + ["meat"]:
			(hh.pantry as Inventory).items.erase(id)
	w.treasury = 100000
	var before := snapshot(w)
	var helped: int = w.brain._relief(w.brain.daily_obligations(), 0.0)
	check(helped == 0 and w.treasury == 100000 and w.households[h].pantry.total() == 0,
		"no food anywhere: no household helped, no coin spent, no food appears (helped %d)" % helped)
	check(same(before, snapshot(w)), "no coin or good made or lost (%s)" % diff(before, snapshot(w)))
	# the whole evening's business, too, on an empty village
	w.last_reeve_day = -1
	w.brain.reeve_day()
	check(int(snapshot(w).coins) == int(before.coins) and w.treasury >= 0, "the manor's whole evening on an empty village moves coins only (treasury %d)" % w.treasury)


## The treasury is finite: relief that is not an emergency stops at the reserve, an emergency at one day of wages;
## with an empty treasury nothing is bought; the treasury never goes negative.
func finite_treasury() -> void:
	var w := new_world()
	var h := a_household(w)
	strip(w, [h])
	var farmer: NPC = w.npcs.filter(func(o): return o.alive and o.job == "farmer" and o.household != h)[0]
	farmer.inv.add("wheat", w.brain.keep_wheat(farmer) + 40)
	var obl: float = w.brain.daily_obligations()
	w.treasury = int(obl) + 7                             # an emergency may spend down to one day of wages
	var before := snapshot(w)
	w.brain._relief(obl, obl * 10.0)
	check(w.treasury >= int(obl) and w.treasury < int(obl) + 7,
		"an emergency below the reserve spends down to a day's wages, no further (%d left of %d, floor %d)" % [w.treasury, int(obl) + 7, int(obl)])
	check(same(before, snapshot(w)), "coins and grain only moved (%s)" % diff(before, snapshot(w)))
	w.treasury = 0
	var f0 := farmer.inv.count("wheat")
	for m: NPC in w.brain._members(h):
		m.inv.items.erase("wheat")
	w.households[h].pantry.items.clear()
	w.brain._relief(obl, obl * 10.0)
	check(w.treasury == 0 and farmer.inv.count("wheat") == f0, "an empty treasury buys nothing")
	w.last_reeve_day = -1
	w.brain.pay_guards()
	w.brain.reeve_day()
	check(w.treasury >= 0, "wages and the evening's business never take the treasury below zero (%d)" % w.treasury)


## A household short of food but not in an emergency: the bought food waits in the manor's lot (the manor's goods)
## until carried, and the census sees every grain the whole way.
func carried_relief() -> void:
	var w := new_world()
	var h := a_household(w)
	strip(w, [h])
	w.households[h].pantry.add("pottage", ceili(1.4 * w.brain.household_day_food(h) / NPCBrain.food_points("pottage")))
	w.treasury = 100000
	var farmer: NPC = w.npcs.filter(func(o): return o.alive and o.job == "farmer" and o.household != h)[0]
	farmer.inv.add("wheat", w.brain.keep_wheat(farmer) + 6)
	w.granary.add("cheese", 2)
	var before := snapshot(w)
	var t0 := w.treasury
	var c0 := farmer.coins
	w.brain._relief(w.brain.daily_obligations(), 0.0)
	check(w.manor_work.pending_for(h) > 0 and w.granary.count("cheese") < 2, "not an emergency: relief (the granary's cheese and bought grain) waits in the manor's lots, %d things" % w.manor_work.pending_for(h))
	check(farmer.coins - c0 == t0 - w.treasury, "the farmer is paid exactly what the treasury gives (%d)" % (t0 - w.treasury))
	check(same(before, snapshot(w)), "no coin or good made or lost (%s)" % diff(before, snapshot(w)))
