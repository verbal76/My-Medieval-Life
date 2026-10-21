extends SceneTree
## OD-19 (owner, 2026-10-20) and PAR-02A: the reserve is a dynamic assessment of a household's foreseeable necessities,
## not a fixed coin floor (World.necessity, World.reserve_of, World.can_afford). The decision's nine scenarios.
## Run:
##   godot --headless --path game --script res://tests/reserve_test.gd

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
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	scenarios(w)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func members(w: World, n: NPC) -> Array:
	return w.brain._members(n.household)


## Empty a household's food, logs and medicine (pantry and pockets), as if it had nothing put by.
func bare(w: World, n: NPC) -> void:
	var stores: Array = [w.households[n.household].pantry]
	for m: NPC in members(w, n):
		stores.append(m.inv)
	for inv: Inventory in stores:
		for id in NPCBrain.FOOD + NPCBrain.MEDICINES + ["log"]:
			inv.items.erase(id)


## B7-015 (the seed-2 starvation, FSE-16): who pays for a hungry villager's meal is decided at the price asked, and the
## manor's relief reaches the hungriest household first.
func tab_and_relief(w: World, fam: NPC) -> void:
	var rich: NPC = null
	for m: NPC in members(w, fam):
		if m != fam and m.role in ["adult", "elder"]:
			rich = m
	var v: NPC = w.brain._vendor_with_food(fam)
	check(rich != null and v != null, "tab: a household member to pay, and food on sale")
	if rich == null or v == null:
		return
	bare(w, fam)
	for m: NPC in members(w, fam):
		m.coins = 0
	# the vendor's cheap food gone: its cheapest meal costs more than 2 coins (the old fixed test's figure)
	for id in ["pottage", "ale", "bread", "cheese"]:
		v.inv.items.erase(id)
	v.inv.add("roast_meat", 3)
	var meal := 1 << 30
	for f in NPCBrain.COOKED:
		if v.inv.has(f):
			meal = mini(meal, w.sell_price(v, f))
	fam.coins = 2
	rich.coins = meal * 10
	fam.hunger = 10.0
	var planned: bool = w.brain._plan_eat(fam)
	check(meal > 2 and planned and fam.doing == "eating on the family's tab", "tab: with %d coins for a %d-coin meal, the family's tab pays (%s)" % [fam.coins, meal, fam.doing])
	rich.coins = 0
	for o: NPC in w.npcs:
		if o.alive and (o.job == "farmer" or w.brain.buy_role(o) == "merchant_food"):
			o.inv.items.erase("wheat")
	var missed0: float = w.stats.get("missed_meal_no_money", 0.0)
	fam.plan = []
	check(not w.brain._plan_eat(fam) and float(w.stats.get("missed_meal_no_money", 0.0)) == missed0 + 1.0,
		"tab: with 2 coins and nobody to pay the rest: no trip to the vendor, a meal missed for want of money")
	relief_sources(w, fam)


## Every household's food and coins taken away except `keep`'s, the others left exactly the reserve horizon of pottage
## (OD-19's reserve_days: they neither qualify for relief nor have food to spare); the granary and all sellers emptied.
func strip_village(w: World, keep: Array) -> void:
	for h in w.households.size():
		var mem: Array = w.brain._members(h)
		for m: NPC in mem:
			m.coins = 0
			for id in NPCBrain.EDIBLE + ["meat", "log"]:
				m.inv.items.erase(id)
		var p: Inventory = w.households[h].pantry
		for id in NPCBrain.EDIBLE + ["meat", "log"]:
			p.items.erase(id)
		if not keep.has(h) and not mem.is_empty():
			p.add("pottage", ceili(float(GameData.b("reserve_days")) * w.brain.household_day_food(h) / NPCBrain.food_points("pottage")))
	w.granary.items.erase("wheat")
	for o: NPC in w.npcs:
		for id in NPCBrain.EDIBLE + ["meat"]:
			o.inv.items.erase(id)
	w._price_cache.clear()
	w._reserve_cache.clear()


## FSE-17 (owner, 2026-10-20: relief checks every food store) and the order of service (B7-015).
func relief_sources(w: World, fam: NPC) -> void:
	var hs := []
	for h in w.households.size():
		if h != fam.household and not w.brain._members(h).is_empty():
			hs.append(h)
	var a: int = hs[0]
	var b: int = hs[1]
	var c: int = hs[2]
	var obl: float = w.brain.daily_obligations()
	w.treasury = 100000
	# the hungriest first: one unit for sale, two households under the trigger
	strip_village(w, [a, b])
	w.households[a].pantry.add("pottage", ceili(1.5 * w.brain.household_day_food(a) / 40.0))
	var farmer: NPC = w.npcs.filter(func(o): return o.alive and o.job == "farmer" and o.household != a and o.household != b)[0]
	farmer.inv.add("wheat", w.brain.keep_wheat(farmer) + 1)
	var da: float = w.brain.household_food_days(a)
	var db: float = w.brain.household_food_days(b)
	w.brain._relief(obl, 0.0)
	check(a < b and da > db and db < 1.0 and w.households[b].pantry.count("wheat") == 1 and w.households[a].pantry.count("wheat") == 0 and w.manor_work.pending_for(a) == 0,
		"relief: with one unit for sale, the household with nothing (hh%d, %.2f days) gets it before hh%d (%.2f days)" % [b, db, a, da])
	# B7-015 (seed 4): grain counts as pottage only in whole pots, and relief gives grain to make them
	var one := Inventory.new()
	one.add("wheat", 1)
	var two := Inventory.new()
	two.add("wheat", 2)
	check(is_equal_approx(NPCBrain.store_points([one]), float(GameData.item("wheat").food)) and is_equal_approx(NPCBrain.store_points([one, one]), 2.0 * NPCBrain.food_points("wheat")),
			"B7-015: one grain is worth its raw food (no pot from it); two make a pot, in one store or across the household's")
	strip_village(w, [b])
	w.households[b].pantry.add("wheat", 1)
	w.granary.add("wheat", 50)
	w.brain._relief(obl, 0.0)
	var grain := 0
	for inv: Inventory in w.brain.household_stores(b):
		grain += inv.count("wheat")
	grain += w.manor_work.pending_for(b)
	check(grain > 1 and grain % NPCBrain.pottage_batch() == 0, "B7-015: relief tops a household's odd grain up to whole pots (%d)" % grain)
	w.granary.remove("wheat", w.granary.count("wheat"))
	# any food from any seller: only bread at the tavern
	strip_village(w, [b])
	var keeper: NPC = w.npcs.filter(func(o): return o.alive and o.job == "tavernkeeper")[0]
	keeper.inv.add("bread", 3)
	var kc: int = keeper.coins
	w.brain._relief(obl, 0.0)
	check(w.households[b].pantry.count("bread") > 0 and keeper.coins > kc, "FSE-17: relief buys the tavern's bread when there is no grain or pottage (%d bread)" % w.households[b].pantry.count("bread"))
	# other households' food beyond their own reserve horizon, never below it, paid to them
	strip_village(w, [b])
	var extra := 5
	w.households[c].pantry.add("pottage", extra)
	var cneed: float = w.brain.household_day_food(c) * float(GameData.b("reserve_days"))
	var head: NPC = w.brain._richest_in_household(w.brain._members(c)[0])
	w.brain._relief(obl, 0.0)
	var cleft: float = NPCBrain.store_points([w.households[c].pantry])
	check(w.households[b].pantry.count("pottage") > 0 and cleft >= cneed and head.coins > 0,
		"FSE-17: relief buys another household's spare food, leaving it its own %d points (%d left), and pays it %d coins" % [int(cneed), int(cleft), head.coins])
	# a household whose home is not one of the buildings: relief's carriers collect its spare food where its head stands
	# (before: a script error, and the pickup placed at cell 0,0, so the relief could wait there for good)
	strip_village(w, [b])
	w.households[b].pantry.add("pottage", ceili(1.5 * w.brain.household_day_food(b) / 40.0))     # not urgent: carried
	var home_c: String = str(w.households[c].home)
	w.households[c].home = "no-such-building"
	w.households[c].pantry.add("pottage", 5)
	var c_head: NPC = w.brain._richest_in_household(w.brain._members(c)[0])
	w.brain._relief(obl, 0.0)
	w.households[c].home = home_c
	var at_head := false
	for l in w.manor_work.lots:
		if str(l.to.get("kind", "")) == "pantry" and int(l.to.get("hh", -1)) == b and Vector2i(int(l.at[0]), int(l.at[1])) == c_head.cell():
			at_head = true
	check(at_head and c_head.cell() != Vector2i.ZERO, "FSE-17: a seller household with no building for a home: relief collects its food where its head stands")
	# raw meat only for a household with logs to roast it, as many as its logs
	strip_village(w, [b])
	var hunter: NPC = w.npcs.filter(func(o): return o.alive and o.job == "hunter" and o.household != b)[0]
	hunter.inv.add("meat", 3)
	w.brain._relief(obl, 0.0)
	var no_logs: bool = w.households[b].pantry.count("meat") == 0
	strip_village(w, [b])
	hunter.inv.add("meat", 3)
	w.households[b].pantry.add("log", 2)
	w.brain._relief(obl, 0.0)
	check(no_logs and w.households[b].pantry.count("meat") == 2, "FSE-17: relief buys raw meat only for logs to roast it (none without logs, %d for 2 logs)" % w.households[b].pantry.count("meat"))
	# a household's own food is reckoned from all it holds: members' pockets, and meat it can roast
	strip_village(w, [b])
	var mb: Array = w.brain._members(b)
	var need: float = w.brain.household_day_food(b)
	(mb[0] as NPC).inv.add("pottage", 3)
	w.households[b].pantry.add("meat", 2)
	w.households[b].pantry.add("log", 1)
	var want: float = (3.0 * 40.0 + 1.0 * NPCBrain.food_points("meat")) / need
	check(absf(w.brain.household_food_days(b) - want) < 0.001, "FSE-17: a household's food counts what members carry and the meat its logs can roast (%.2f days)" % want)
	check(NPCBrain.food_points("wheat") == 120.0 and NPCBrain.food_points("meat") == 120.0 and NPCBrain.food_points("egg") == 10.0,
		"one valuation of food: wheat as cooked (120), meat as roasted (120), the rest as eaten")
	# parity: villagers eat what the player can eat, and roast meat at their hearth
	strip_village(w, [b])
	var eater: NPC = mb[0]
	eater.inv.add("egg", 5)
	eater.hunger = 10.0
	eater.plan = []
	var ate: bool = w.brain._plan_eat(eater)
	check(ate and str(eater.plan[0].get("act", "")) == "eat" and str(eater.plan[0].get("args", {}).get("item", "")) == "egg",
		"parity: a villager with eggs in hand and nothing else eats an egg, as the player can (%s)" % eater.doing)
	# FSE-18: the family chest. Home, a villager puts the food they carry for eating in the pantry; a producer keeps what
	# buyers will take; a food vendor keeps its stock but stocks the chest to the reserve horizon first
	strip_village(w, [b])
	var pb0: Inventory = w.households[b].pantry
	for id in NPCBrain.EDIBLE:
		pb0.items.erase(id)
	var member: NPC = mb[0]
	member.inv.add("apple", 6)
	w.brain.stock_family_chest(member)
	check(pb0.count("apple") == 6 and member.inv.count("apple") == 0, "FSE-18: home, a villager puts the apples they carry in the family chest")
	var farmer18: NPC = w.npcs.filter(func(o): return o.alive and o.job == "farmer")[0]
	var kp: Inventory = w.households[farmer18.household].pantry
	for id in NPCBrain.EDIBLE:
		kp.items.erase(id)
	kp.add("pottage", 200)                              # the chest is full: only what buyers will not take goes in
	farmer18.inv.add("milk", 500)
	var sale: int = w.brain._sale_stock(farmer18, "milk")
	w.brain.stock_family_chest(farmer18)
	check(sale < 500 and farmer18.inv.count("milk") == sale and kp.count("milk") == 500 - sale,
		"FSE-18: a keeper keeps the milk buyers will take (%d) and puts the rest in the family chest (%d)" % [sale, kp.count("milk")])
	farmer18.inv.items.erase("milk")
	var tk: NPC = w.npcs.filter(func(o): return o.alive and o.household >= 0 and (o.job in ["tavernkeeper", "cook"] or w.brain.buy_role(o) == "merchant_food"))[0]
	var tp: Inventory = w.households[tk.household].pantry
	for id in NPCBrain.EDIBLE:
		tp.items.erase(id)
	tk.inv.add("pottage", 100)
	var horizon: float = w.brain.household_day_food(tk.household) * float(GameData.b("reserve_days"))
	w.brain.stock_family_chest(tk)
	check(NPCBrain.store_points([tp]) >= horizon and NPCBrain.store_points([tp]) < horizon + 40.0 and tk.inv.count("pottage") > 0,
		"FSE-18: a food vendor stocks the family chest to its reserve horizon (%d of %d points) and keeps the rest to sell (%d)" % [int(NPCBrain.store_points([tp])), int(horizon), tk.inv.count("pottage")])
	# the family chest takes firewood too, and an elder's logs are not trade stock: a household with raw meat in the pantry
	# and logs in a member's pocket could not roast it (Simon Brook starved so, seed 2, day 189)
	strip_village(w, [b])
	var elder_m: NPC = null
	for m: NPC in mb:
		if m.job == "" or m.role == "elder":
			elder_m = m
	if elder_m == null:
		elder_m = mb[0]
	var pbf: Inventory = w.households[b].pantry
	pbf.items.erase("log")
	pbf.add("meat", 2)
	elder_m.inv.add("log", 7)
	w.brain.stock_family_chest(elder_m)
	check(pbf.count("log") == 7 and elder_m.inv.count("log") == 0, "FSE-18: home, a member's firewood goes in the family chest (%d logs)" % pbf.count("log"))
	w.brain._cook_at_home(mb[mb.size() - 1], pbf)
	check(pbf.count("roast_meat") >= 2, "FSE-18: so the household can roast its meat at the hearth")
	var cw: NPC = w.npcs.filter(func(o): return o.alive and o.job == "carpenter")[0]
	var cwp: Inventory = w.households[cw.household].pantry
	cwp.remove("meat", cwp.count("meat"))
	cw.inv.add("log", 5)
	var cwl: int = cw.inv.count("log")
	w.brain.stock_family_chest(cw)
	check(cw.inv.count("log") == cwl, "FSE-18: a carpenter keeps the logs their trade works (inputs are not the family's)")
	# B7-015 (seed 4): but the chest's meat gets its firewood from trade stock first, as its food does
	cwp.add("meat", 3)
	var cl0 := cwp.count("log")
	w.brain.stock_family_chest(cw)
	check(cwp.count("log") >= 3 and cw.inv.count("log") == cwl - (cwp.count("log") - cl0), "B7-015: a trader home puts in the logs to roast the family chest's meat (%d logs for 3 meat)" % cwp.count("log"))
	# FSE-18: the player's family chest counts in the player's reserve, by the households' rule
	var pl := w.player
	var home0: String = pl.home
	if pl.home == "" or not w.buildings.has(pl.home):
		pl.home = str(w.buildings.keys()[0])            # a home for the check
	pl.inv.items.clear()
	pl.chest.items.clear()
	var before := int(w.necessity(pl).food)
	pl.chest.add("pottage", 20)
	w._reserve_cache.clear()
	check(int(w.necessity(pl).food) < before, "FSE-18: food in the player's family chest lowers what the player keeps back for food (%d -> %d)" % [before, int(w.necessity(pl).food)])
	pl.chest.items.clear()
	pl.home = home0
	strip_village(w, [b])
	var pb: Inventory = w.households[b].pantry
	pb.add("meat", 1)
	pb.add("log", 1)
	w.brain._cook_at_home(eater, pb)
	check(pb.count("roast_meat") >= 2 and not pb.has("meat"), "parity: a household roasts its own meat at the hearth with a log (%d roast meat)" % pb.count("roast_meat"))


func scenarios(w: World) -> void:
	var fam: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and members(w, n).size() >= 3 and n.job == "farmer":
			fam = n
			break
	check(fam != null, "a farming family of three or more")
	var pantry: Inventory = w.households[fam.household].pantry
	# 1. well stocked, few expenses: nothing to keep back
	bare(w, fam)
	pantry.add("pottage", 60)
	pantry.add("log", 10)
	var r1 := w.necessity(fam)
	check(int(r1.food) == 0 and int(r1.fuel) == 0 and int(r1.need) == 0 and int(r1.reserve) == 0, "1. a well-stocked household with few expenses keeps nothing back (%s)" % str(r1))
	# 2. dependants and little food: a real reserve, larger for a larger household
	bare(w, fam)
	var r2 := w.necessity(fam)
	check(int(r2.food) > 0 and int(r2.fuel) > 0, "2. a household with dependants and no food keeps money for food and firewood (%s)" % str(r2))
	var lone: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and members(w, n).size() == 1:
			lone = n
			break
	if lone != null:
		bare(w, lone)
		check(int(w.necessity(lone).food) < int(r2.food), "   and one living alone needs less for food than a family")
	# 3. a merchant with goods but little cash: goods are not food; food in stock is
	var gm: NPC = w.npcs.filter(func(o): return o.alive and w.brain.buy_role(o) == "merchant_goods")[0]
	bare(w, gm)
	gm.inv.add("iron_sword", 3)
	gm.coins = 5
	var r3 := w.necessity(gm)
	check(int(r3.food) > 0, "3. a goods merchant with stock but no food still needs money for food (%s)" % str(r3))
	var fm: NPC = w.npcs.filter(func(o): return o.alive and w.brain.buy_role(o) == "merchant_food")[0]
	bare(w, fm)
	var bare_food := int(w.necessity(fm).food)
	fm.inv.add("pottage", 40)
	check(int(w.necessity(fm).food) < bare_food, "   a food merchant's own food stock lowers what they keep for food")
	# 4. an obligation falling due: the rent
	bare(w, fam)
	pantry.add("pottage", 60)
	pantry.add("log", 10)
	var lease: Dictionary = {}
	for r in w.property.records():
		if w.tenant_of(r) == World.hh_ref(fam.household):
			lease = r
			break
	if lease.is_empty():
		lease = w.property.records()[0]
	var keep := [w.tenant_of(lease), lease.get("rent", 0), lease.get("due_day", -1)]
	w.set_tenant(lease, World.hh_ref(fam.household), 7)
	lease.due_day = w.day() + 1
	check(int(w.necessity(fam).rent) == 7 + int(lease.get("arrears", 0)) and int(w.necessity(fam).need) >= 7, "4. rent falling due is kept back (%s)" % str(w.necessity(fam)))
	w.set_tenant(lease, str(keep[0]), int(keep[1]))
	lease.due_day = keep[2]
	# 5. food with reserved money; 6. stock only above the reserve
	bare(w, fam)
	w._reserve_cache.clear()
	var res := w.reserve_of(fam)
	for m: NPC in members(w, fam):
		if m != fam:
			m.coins = 0
	w._reserve_cache.clear()
	res = w.reserve_of(fam)
	fam.coins = maxi(1, res)
	check(res > 0 and w.can_afford(fam, mini(3, fam.coins), true), "5. a villager may spend reserved money on food for the household (%d reserved)" % res)
	check(not w.can_afford(fam, 3), "6. but not on goods or stock that would eat into it")
	fam.coins = res + 10
	check(w.can_afford(fam, 10) and not w.can_afford(fam, 11), "   above the reserve they may, and only so far")
	# 6b. a business purchase needed to keep earning: a trader out of an input of their trade may buy one unit with
	# reserved coins; with one in hand they work it before buying more (OD-19 section 3)
	var tanner: NPC = w.npcs.filter(func(o): return o.alive and o.job == "tanner")[0]
	bare(w, tanner)
	tanner.inv.items.erase("rabbit_pelt")
	for m: NPC in members(w, tanner):
		if m != tanner:
			m.coins = 0
	w._reserve_cache.clear()
	var tres := w.reserve_of(tanner)
	var pp := w.buy_price(tanner, "rabbit_pelt")
	tanner.coins = maxi(pp, tres - 1)
	check(tres > 0 and tanner.coins - pp < tres and w.can_afford(tanner, pp, false, "rabbit_pelt"), "6b. a tanner with no pelts buys one into their reserve, to keep earning (reserve %d)" % tres)
	tanner.inv.add("rabbit_pelt", 1)
	check(not w.can_afford(tanner, pp, false, "rabbit_pelt"), "   with one in hand, no more until it is worked")
	check(not w.can_afford(tanner, pp, false, "iron_ore"), "   and nothing outside their trade")
	tanner.inv.items.erase("rabbit_pelt")
	# 7. expected income that fails to arrive
	var guard: NPC = w.npcs.filter(func(o): return o.alive and o.job == "guard" and o.household >= 0)[0]
	bare(w, guard)
	var t0 := w.treasury
	w.treasury = 100000
	var with_pay := w.necessity(guard)
	w.treasury = 0
	var no_pay := w.necessity(guard)
	w.treasury = t0
	check(int(with_pay.income) > 0 and int(no_pay.income) == 0 and int(no_pay.need) > int(with_pay.need), "7. a guard counts on their wage while the manor can pay it, and keeps more back when it cannot (%d -> %d)" % [int(with_pay.need), int(no_pay.need)])
	# 8. the player: the same calculation, and the same rule when selling to a villager
	var pr := w.necessity(w.player)
	check(pr.has("reserve") and pr.has("food") and pr.has("rent"), "8. the player's foreseeable needs come from the same calculation (%s)" % str(pr))
	var smith: NPC = w.npcs.filter(func(o): return o.alive and o.job == "smith")[0]
	w._reserve_cache.clear()
	var sr := w.reserve_of(smith)
	var price := w.buy_price(smith, "iron_ore")
	smith.coins = sr + price - 1
	w.player.inv.add("iron_ore", 1)
	check(w.player_sell_many(smith, "iron_ore", 1).result == "failed" and not w.can_afford(smith, price), "   the smith will not buy into their reserve from the player, nor from a villager")
	# 9. changing needs, changing reserve
	bare(w, fam)
	var a := int(w.necessity(fam).need)
	pantry.add("pottage", 6)
	var b := int(w.necessity(fam).need)
	fam.hp = fam.max_hp * 0.2
	var c := int(w.necessity(fam).need)
	fam.hp = fam.max_hp
	check(b < a and c > b, "9. food in store lowers the reserve, an injury with no medicine raises it (%d, %d, %d)" % [a, b, c])
	# the relief reckoning counts coins only for food they can buy now (a defect found 2026-10-20: a household with
	# 2 coins when a meal cost 3 counted as having 1.67 days of food, so relief never came urgently and its people starved)
	bare(w, fam)
	var unit: Array = w.cheapest_food_unit()
	check(int(unit[0]) > 0 and int(unit[1]) > 0, "relief: the cheapest food on sale is known (%s)" % str(unit))
	for m: NPC in members(w, fam):
		m.coins = 0
	fam.coins = int(unit[0]) - 1
	check(w.brain.household_food_days(fam.household) == 0.0, "relief: coins that cannot buy a meal are no food (%d coins, food at %d)" % [fam.coins, int(unit[0])])
	fam.coins = int(unit[0]) * 3
	var days3: float = w.brain.household_food_days(fam.household)
	check(days3 > 0.0 and days3 <= 3.0 * float(unit[1]) / maxf(1.0, w.brain.household_day_food(fam.household)) + 0.001, "relief: coins count for the food they can buy (%.2f days)" % days3)
	fam.coins = 0
	tab_and_relief(w, fam)
	# determinism: the same world, the same reserves
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 1)
	var same := true
	var w3 := World.new()
	w3.setup(VillageMap.load_default(), 1)
	for i in w2.npcs.size():
		same = same and w2.necessity(w2.npcs[i]) == w3.necessity(w3.npcs[i])
	check(same, "the reserve is deterministic: the same world gives the same reserves")
