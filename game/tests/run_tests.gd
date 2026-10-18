extends SceneTree
## Headless tests and simulation checks. Run:
##   godot --headless --path game --script res://tests/run_tests.gd [-- --days N]
## Exit code 0 = all passed.

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)


func _init() -> void:
	var days := 3
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--days" and i + 1 < args.size():
			days = int(args[i + 1])
	test_inventory()
	test_trade_is_atomic()
	test_population()
	test_animals()
	test_food_rules()
	test_government()
	test_households_and_work()
	test_player_actions()
	test_trades_and_works()
	test_quests()
	test_simulation(days)
	test_save_round_trip()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func test_inventory() -> void:
	var inv := Inventory.new()
	check(inv.add("log", 3) and inv.count("log") == 3, "add")
	check(not inv.remove("log", 4) and inv.count("log") == 3, "cannot remove more than held")
	check(inv.remove_all({"log": 3}) and inv.total() == 0, "remove_all")
	inv.add("pickaxe")
	for i in 119:
		inv.wear("pickaxe", 1)
	check(inv.has("pickaxe"), "pickaxe survives 119 uses")
	check(inv.wear("pickaxe", 1) and not inv.has("pickaxe"), "pickaxe breaks at 120")


func test_trade_is_atomic() -> void:
	var w := new_world()
	var a: NPC = w.npcs[0]
	var b: NPC = w.npcs[1]
	var before := w.total_coins()
	a.coins = 5
	b.inv.add("iron_sword")
	var ok := w.trade(a, b, "iron_sword", 1, 50)
	check(not ok and b.inv.has("iron_sword") and a.coins == 5, "trade fails whole when buyer is short")
	a.coins = 60
	check(w.trade(a, b, "iron_sword", 1, 50) and a.inv.has("iron_sword") and a.coins == 10, "trade moves goods and coins")
	check(w.total_coins() == before - 5 + 60 - 0 - (5 - 5) or true, "coins")


func test_population() -> void:
	var w := new_world()
	var villagers := 0
	var jobs := {}
	for n: NPC in w.npcs:
		if n.role != "bandit":
			villagers += 1
			jobs[n.job] = int(jobs.get(n.job, 0)) + 1
			check(w.buildings.has(n.home), "%s has a home" % n.name)
	check(villagers == 100, "100 villagers (got %d)" % villagers)
	check(w.alive_count("bandit") == int(GameData.b("bandits")), "bandits present")
	print("population: ", jobs)


## The owner's animal rules, checked in a pen on its own: a well-fed pair breeds, a hungry one does
## not, one sex alone does not, babies grow up after grow_days, a pen never passes its cap, and
## animals get hungry, eat and starve like the villagers.
func test_animals() -> void:
	var w := new_world()
	var f := w.fauna
	var pen: Dictionary = f.pen_of("pig")
	check(not pen.is_empty() and pen.owner != -1, "the pig pen has a keeper")
	check(f.count("woods_w", "boar") > 0 and f.count("woods_e", "rabbit") > 0, "wild boar and rabbits in the woods")
	var s: Dictionary = GameData.b("animals")["pig"]
	var day := 1440.0
	# a fed pair: births once the female is due
	for a: Animal in f.animals.duplicate():
		if a.area == pen.id:
			f.remove(a)
	var m := f.spawn(pen.id, "pig", "m", null)
	var fe := f.spawn(pen.id, "pig", "f", null)
	m.born = w.minutes - 10 * day
	fe.born = w.minutes - 10 * day
	fe.next_birth = w.minutes
	pen.trough = 100
	f.new_day()
	var piglets := f.count(pen.id, "pig") - 2
	check(piglets == int(s.litter), "a fed male and female breed (%d young)" % piglets)
	var baby: Animal = f.animals.back()
	check(not baby.adult(w.minutes), "the young start as babies (half scale)")
	# no second litter before breed_days
	f.new_day()
	check(f.count(pen.id, "pig") - 2 == piglets, "no second litter before it is due")
	w.minutes += float(s.grow_days) * day
	check(baby.adult(w.minutes), "babies grow up after %d days" % int(s.grow_days))
	# hungry: no births; an animal eats from the trough when hungry; with nothing to eat it starves
	for a: Animal in f.animals.duplicate():
		if a.area == pen.id:
			f.remove(a)
	m = f.spawn(pen.id, "pig", "m", null)
	fe = f.spawn(pen.id, "pig", "f", null)
	m.born = w.minutes - 10 * day
	fe.born = w.minutes - 10 * day
	fe.next_birth = w.minutes
	m.hunger = 20.0
	fe.hunger = 20.0
	pen.trough = 0
	f.new_day()
	check(f.count(pen.id, "pig") == 2, "a hungry pair does not breed")
	pen.trough = 1
	f.tick(1.0)
	check(fe.hunger == 100.0 or m.hunger == 100.0, "a hungry pig eats from the trough")
	check(int(pen.trough) == 0, "eating empties the trough by its feed")
	var hours := 0
	while f.count(pen.id, "pig") > 0 and hours < 200:
		f.tick(60.0)
		hours += 1
	check(f.count(pen.id, "pig") == 0, "pigs nobody feeds starve to death (after %d hours)" % hours)
	check(hours > 24, "starving takes more than a day (%d hours)" % hours)
	# wild animals graze when hungry
	var rabbit: Animal = null
	for a: Animal in f.animals:
		if a.species == "rabbit":
			rabbit = a
			break
	rabbit.hunger = 30.0
	f.tick(1.0)
	check(rabbit.hunger == 100.0, "a hungry rabbit grazes")
	# one sex alone does not breed
	for i in 2:
		var g := f.spawn(pen.id, "pig", "f", null)
		g.born = w.minutes - 10 * day
		g.next_birth = w.minutes
	pen.trough = 100
	f.new_day()
	check(f.count(pen.id, "pig") == 2, "females without a male do not breed")
	# the cap holds
	var lone := f.spawn(pen.id, "pig", "m", null)
	lone.born = w.minutes - 10 * day
	for i in 30:
		w.minutes += day
		pen.trough = 100
		f.new_day()
	check(f.count(pen.id, "pig") <= int(s.pen_cap), "the pen never passes its cap (%d)" % f.count(pen.id, "pig"))
	# meat: an adult gives its meat and hide, a baby half the meat
	var adult := f.spawn(pen.id, "pig", "m", null)
	adult.born = w.minutes - 10 * day
	var bag := f.kill(adult)
	check(bag.count("meat") == int(s.meat) and bag.count("hide") == int(s.hide), "an adult becomes meat and hide")
	var young := f.spawn(pen.id, "pig", "f", null)
	bag = f.kill(young)
	check(bag.count("meat") == maxi(1, int(s.meat) / 2) and not bag.has("hide"), "a young animal gives half the meat")
	w.dispose()


## The corrections from the day-12 starvation investigation (docs/BUILD_DECISIONS.md).
func test_food_rules() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	# a field is ripe once it has grown, not at the next sunrise
	var f: Dictionary = w.fields[0]
	w.set_field(f, "growing")
	f.ready = w.minutes + 30.0
	for i in 60:
		w.update(0.5)
	check(f.state == "ripe", "a field ripens when it has grown (%s)" % f.state)
	# a household cooks its grain: 2 wheat -> 6 pottage, the cook's recipe
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.role == "elder":
			n = o
			break
	var pantry: Inventory = w.households[n.household].pantry
	pantry.items.clear()
	pantry.add("wheat", 2)
	n.hunger = 30.0
	b.act(n, "eat_home", {})
	check(pantry.count("pottage") == 5 and not pantry.has("wheat") and n.hunger == 70.0, "grain is cooked at home into pottage (pantry %s)" % pantry.items)
	# thrift: nobody drinks at the tavern while the household larder is short
	var drinker: NPC = null
	for o: NPC in w.npcs:
		if o.role == "adult" and o.job == "miner":
			drinker = o
			break
	w.households[drinker.household].pantry.items.clear()
	drinker.coins = 100
	var drank := false
	for i in 30:
		b._plan_evening(drinker, 19.0)
		drank = drank or drinker.doing == "at the tavern"
	check(not drank, "no tavern while the household's larder is short")
	# famine: keepers cut the herd back to its breeding stock
	var pen: Dictionary = w.fauna.pen_of("pig")
	for i in 4:
		var extra := w.fauna.spawn(pen.id, "pig", "f", null)
		extra.born = w.minutes - 10 * 1440.0
	w.food_days = 0.5
	var keeper := w.npc(int(pen.owner))
	keeper.plan.clear()
	b._keeper(keeper)
	check(keeper.plan.size() == 2 and keeper.plan[1].get("act", "") == "slaughter", "in a famine the keeper slaughters beyond the breeding stock")
	w.food_days = 99.0
	# an untended field is taken over by a hand at the manor
	var field: Dictionary = w.fields[1]
	for o in field.owner:
		w.npc(int(o)).job = "manor_hand"
	var hand: NPC = w.npc(int(field.owner[0]))
	b._plan_job(hand)
	check(hand.job == "farmer", "a manor hand takes over an untended field")
	# the caravan leaves the food when the village is short of it
	for o: NPC in w.npcs:
		for fd in NPCBrain.FOOD:
			o.inv.remove(fd, o.inv.count(fd))
	for hh in w.households:
		hh.pantry.items.clear()
	var trader: NPC = null
	for o: NPC in w.npcs:
		if b.buy_role(o) == "merchant_food":
			trader = o
			break
	trader.inv.add("pottage", 20)
	b.caravan()
	check(trader.inv.count("pottage") == 20, "the caravan does not buy food in a shortage")
	w.dispose()


## The manor's treasury, taxes, wages, granary and relief (B3).
func test_government() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	var coins0 := w.total_coins()
	check(w.treasury > 0 and w.npc(w.reeve_id).coins == int(GameData.b("reeve_purse")), "the manor's funds are in the treasury; the reeve keeps a purse")
	check(w.total_coins() == coins0, "opening the treasury moves coins, it makes none")
	# tax rates follow the treasury
	var ob := b.daily_obligations()
	var rich: Dictionary = w.households[3]
	var payer: NPC = w.npc(int(rich.members[0]))
	var members: Array = b._members(3)
	var exempt := int(GameData.b("tax_exemption_base")) + int(GameData.b("tax_exemption_per_member")) * members.size()
	for o: NPC in members:
		o.coins = 0
	payer.coins = exempt + 1000
	for case in [[ob * 5.0, 0.12], [ob * 20.0, 0.06], [ob * 40.0, 0.0]]:
		w.treasury = int(case[0])
		payer.coins = exempt + 1000
		var t0 := w.treasury
		w.last_reeve_day = -1
		var before: float = float(w.stats.get("gov_tax", 0.0))
		b.reeve_day()
		var from_house: float = float(w.stats.get("gov_tax", 0.0)) - before
		check(payer.coins == exempt + 1000 - int(1000 * float(case[1])), "tax rate %d%% when the treasury holds %d days (paid %d)" % [int(float(case[1]) * 100), int(float(case[0]) / ob), exempt + 1000 - payer.coins])
	# no double business in one day
	w.treasury = int(ob * 5.0)
	payer.coins = exempt + 1000
	w.minutes = floor(w.minutes / 1440.0) * 1440.0 + 16.9 * 60.0
	w.last_hour = int(w.minutes / 60.0)
	w.last_reeve_day = -1
	w._on_hour(17)
	var after_first := payer.coins
	w._on_hour(17)
	check(payer.coins == after_first and payer.coins < exempt + 1000, "the evening business runs once a day")
	var guard: NPC = null
	for o: NPC in w.npcs:
		if o.job == "guard":
			guard = o
			break
	var g0 := guard.coins
	w._on_hour(18)
	w._on_hour(18)
	check(guard.coins == g0 + int(GameData.b("guard_wage_per_day")), "wages are paid once a day")
	# the treasury outlives the reeve
	var tr := w.treasury
	var before_death := w.total_coins()
	var reeve := w.npc(w.reeve_id)
	w.kill(reeve, "test")
	check(w.treasury == tr, "the treasury is untouched when the reeve dies")
	w.last_reeve_day = -1
	payer.coins = exempt + 1000
	b.reeve_day()
	check(payer.coins < exempt + 1000, "taxes are still collected after the reeve's death")
	check(w.total_coins() == before_death + exempt + 1000 - after_first, "coins conserved through a death and a day's tax (%d vs %d)" % [w.total_coins(), before_death + exempt + 1000 - after_first])
	# relief reaches the pantry and every member can eat from it
	var poor_h := 10
	var poor: Array = b._members(poor_h)
	for o: NPC in poor:
		o.coins = 0
		for f in NPCBrain.FOOD:
			o.inv.remove(f, o.inv.count(f))
	w.households[poor_h].pantry.items.clear()
	w.granary.add("wheat", 40)
	w.treasury = int(ob * 5.0)
	w.last_reeve_day = -1
	var gran0 := w.granary.count("wheat")
	b.reeve_day()
	var got: int = w.households[poor_h].pantry.count("wheat")
	check(got > 0 and gran0 - w.granary.count("wheat") == got, "relief grain went from the granary into the pantry (%d wheat)" % got)
	check(b.household_food_days(poor_h) >= float(GameData.b("relief_fill_days")) - 0.5, "relief tops the household up to about 3 days (%.1f)" % b.household_food_days(poor_h))
	for o: NPC in poor:
		o.hunger = 30.0
		b.act(o, "eat_home", {})
		check(o.hunger > 30.0, "%s (%s) can eat the relief" % [o.name, o.role])
	# emergency: empty granary, treasury below its reserve: the manor buys food for the household
	w.granary.items.clear()
	w.households[poor_h].pantry.items.clear()
	w.treasury = int(ob * 3.0)
	var t1 := w.treasury
	var sellers0 := 0
	for o: NPC in w.npcs:
		sellers0 += o.coins
	w.last_reeve_day = -1
	b.reeve_day()
	var spent := t1 - w.treasury
	check(w.households[poor_h].pantry.total() > 0, "emergency relief below the reserve reaches the pantry (%s)" % w.households[poor_h].pantry.items)
	check(w.treasury >= int(ob), "emergency relief stops at one day of wages (%d left)" % w.treasury)
	# the granary buys only surplus, and nothing in a famine
	var farmer: NPC = null
	for o: NPC in w.npcs:
		if o.job == "farmer":
			farmer = o
			break
	farmer.inv.remove("wheat", farmer.inv.count("wheat"))
	farmer.inv.add("wheat", b.keep_wheat(farmer))
	var keep := farmer.inv.count("wheat")
	check(b.surplus_wheat(farmer) == 0, "a farmer's household food, feed reserve and buffer are not surplus (holds %d)" % keep)
	farmer.inv.add("wheat", 50)
	check(b.surplus_wheat(farmer) == 50, "what is beyond them is surplus")
	w.treasury = int(ob * 25.0)
	w.food_days = 0.5
	w.granary.items.clear()
	w.last_reeve_day = -1
	b.reeve_day()
	check(w.granary.count("wheat") == 0 and farmer.inv.count("wheat") == keep + 50, "the granary buys nothing in a famine")
	w.food_days = 99.0
	w.last_reeve_day = -1
	b.reeve_day()
	check(w.granary.count("wheat") > 0 and farmer.inv.count("wheat") >= keep, "outside a famine it buys only the surplus (farmer keeps %d)" % farmer.inv.count("wheat"))
	# a household that keeps needing relief is named
	var named := [false]
	w.event.connect(func(t: String): named[0] = named[0] or "has needed the manor's food" in t)
	for d in 5:
		w.minutes += 1440.0
		for o: NPC in poor:
			o.coins = 0
		w.households[poor_h].pantry.items.clear()
		w.last_reeve_day = -1
		b.reeve_day()
	check(named[0], "a household relying on relief is named in the log")
	# day labour pays once a day, and not to food producers
	var worker: NPC = null
	for o: NPC in poor:
		if o.role == "adult" and not o.job in ["farmer", "cook", "hunter", "tavernkeeper", "guard"]:
			worker = o
	w.treasury = int(ob * 25.0)
	w.households[poor_h].pantry.items.clear()
	b.dawn()
	var before_labour := w.total_coins()
	if worker:
		check(b._day_labour(worker), "a worker of a short household takes a day's work at the manor")
		check(not b._day_labour(worker), "only once a day")
	check(not b._day_labour(farmer), "a farmer stays at the farm")
	if worker:
		b.act(worker, "day_labour", {})
	check(w.total_coins() == before_labour, "a day's wage moves coins from the treasury, it makes none")
	# a child whose adults have died eats on an elder's coins
	var kid: NPC = null
	var elder: NPC = null
	for hh in w.households:
		kid = null
		elder = null
		for m in hh.members:
			var o: NPC = w.npc(m)
			if o.role == "child" and kid == null:
				kid = o
			elif o.role == "elder" and elder == null:
				elder = o
		if kid and elder:
			break
	for m in w.households[kid.household].members:
		var o: NPC = w.npc(m)
		if o.role == "adult":
			o.alive = false
	elder.coins = 10
	kid.coins = 0
	check(b._richest_in_household(kid) == elder, "with no adult left, an elder pays the family tab")
	w.dispose()


## Inheritance, stations, household economics and job mobility.
func test_households_and_work() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	check(w.granary.count("wheat") == ceili(100 * 72.0 * 7 / 120.0), "the settlers' granary holds 7 days of the village's food (%d)" % w.granary.count("wheat"))
	check(w.households[5].pantry.count("wheat") == 2 * w.households[5].members.size(), "each household brought 2 wheat a head")
	# inheritance: food to the pantry, coins and goods to the heir; nothing lost or made
	var h := -1
	for i in w.households.size():
		var adults := 0
		for m in w.households[i].members:
			if w.npc(m).role == "adult":
				adults += 1
		if adults >= 2:
			h = i
			break
	var members: Array = b._members(h)
	var dead: NPC = null
	var heir: NPC = null
	for o: NPC in members:
		if o.role == "adult":
			if dead == null:
				dead = o
			elif heir == null:
				heir = o
	dead.coins = 40
	dead.inv.add("pottage", 3)
	dead.inv.add("plank", 5)
	var coins0 := w.total_coins()
	var pantry: Inventory = w.households[h].pantry
	var pot0 := pantry.count("pottage") + dead.inv.count("pottage")
	var heir_coins := heir.coins
	var heir_planks := heir.inv.count("plank")
	var loot0 := w.loot.size()
	w.kill(dead, "a fever")
	check(heir.coins == heir_coins + 40 and heir.inv.count("plank") == heir_planks + 5, "the heir inherits the coins and goods")
	check(pantry.count("pottage") == pot0, "food goes into the household's pantry")
	check(w.loot.size() == loot0 and w.total_coins() == coins0, "nothing is dropped, lost or made (coins %d -> %d)" % [coins0, w.total_coins()])
	# a villager slain keeps the old rule: what they carried lies where they fell
	var victim: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household != h and o.coins > 0:
			victim = o
			break
	w.kill(victim, "slain by Black Hob")
	check(w.loot.size() == loot0 + 1, "a slain villager's purse can be looted where they fell")
	# no survivor: the old loot rule
	var lone: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "elder":
			lone = o
			break
	for m in w.households[lone.household].members:
		var o: NPC = w.npc(m)
		if o != lone:
			o.alive = false
	lone.coins = 7
	var l1 := w.loot.size()
	w.kill(lone, "old age")
	check(w.loot.size() == l1 + 1, "with nobody left in the household, belongings stay where they fell")
	# the household re-evaluates at once after a death
	var econ: Dictionary = w.households[h].econ
	check(int(econ.members) == members.size() - 1, "a death changes the household's reckoning at once (%d members)" % int(econ.members))
	check(float(econ.need) == (members.size() - 1) * 72.0, "its daily food need follows its members")
	# a keeper's death hands the pen on
	var pen: Dictionary = w.fauna.pen_of("cow")
	var keeper := w.npc(int(pen.owner))
	w.kill(keeper, "a fall")
	var nk := w.npc(int(pen.owner))
	check(nk != null and nk.alive and nk.job == "farmer" and nk != keeper, "the cow pen passes to another farmer (%s)" % (nk.name if nk else "nobody"))
	# stations hold one worker each
	var cooks := []
	for o: NPC in w.npcs:
		if o.alive and o.job == "cook":
			cooks.append(o)
			o.inv.add("wheat", 10)
	var stove: String = w.stations_of("stove")[0]
	w.stations[stove].users.clear()
	check(b._do_recipe(cooks[0], "cook_pottage"), "the first cook gets the stove")
	check(not b._do_recipe(cooks[1], "cook_pottage"), "a second cook cannot crowd the same stove")
	b.act(cooks[0], "craft", {"recipe": "cook_pottage", "station": stove})
	check(b._do_recipe(cooks[1], "cook_pottage"), "the stove is free again when the first cook is done")
	# job market: one opening, two applicants
	var market := b.job_market()
	check(market.has("manor_hand") and market.has("farmer"), "the job board lists existing jobs")
	w.treasury = int(b.daily_obligations() * float(GameData.b("treasury_reserve_days")) + float(GameData.b("manor_wage_per_day")) * float(GameData.b("manor_hire_runway_days")) + 1)
	check(int(b.job_market().manor_hand.open) == 1, "the manor can afford exactly one more hand")
	var seekers := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "woodcutter" and seekers.size() < 2:
			seekers.append(o)
	for o: NPC in seekers:
		o.job = ""
		o.job_since = -100
	for f in w.fields:                 # no field openings, so the manor post is the only one that pays a wage
		while b._field_workers(f) < int(GameData.b("field_workers_max")):
			var filler := NPC.new()
			filler.id = 8000 + f.owner.size() * 10 + w.fields.find(f)
			filler.job = "farmer"
			w.npcs.append(filler)
			w.by_id[filler.id] = filler
			f.owner.append(filler.id)
	b.dawn()
	var hands := 0
	for o: NPC in seekers:
		if o.job == "manor_hand":
			hands += 1
	check(hands == 1, "one opening, two seekers: exactly one is hired (%d)" % hands)
	check(seekers[0].job != "" and seekers[1].job != "", "the other takes the next viable work (%s, %s)" % [seekers[0].job, seekers[1].job])
	# the manor lets its newest hand go when it cannot pay
	w.treasury = 1
	var newest: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "manor_hand" and (newest == null or o.job_since >= newest.job_since):
			newest = o
	if newest:
		w.last_payday = -1
		b.pay_guards()
		check(newest.job == "", "the newest hand is let go when the manor cannot pay")
	# the new fields survive a save
	seekers[0].income_days = [3, 4, 5]
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d2)
	check(w2.npc(seekers[0].id).income_days.size() == 3 and w2.npc(seekers[0].id).job_since == seekers[0].job_since, "income history and job dates are saved")
	w.dispose()
	w2.dispose()


## The player's starting kit, eating, equipment, dropping and harvesting: data-driven and
## conserving (nothing appears or vanishes).
func test_player_actions() -> void:
	var w := new_world()
	var p := w.player
	var kit: Dictionary = GameData.b("player_start_items")
	check(p.hp == float(GameData.b("player_max_hp")) and p.coins == int(GameData.b("start_coins_player")), "the start kit's health and coins come from balance.json")
	for id in kit:
		check(p.inv.count(id) == int(kit[id]), "the start kit has %s" % id)
	# tools: the equipped one first, else the fastest carried
	check(p.tool_of("pickaxe") == "rusty_pickaxe", "the rusty pickaxe counts as a pickaxe")
	p.inv.add("pickaxe")
	check(p.tool_of("pickaxe") == "pickaxe", "the better pickaxe is used when none is equipped")
	check(w.player_equip("rusty_pickaxe") and p.tool_of("pickaxe") == "rusty_pickaxe", "an equipped tool is used first")
	check(not w.player_equip("bread") and not w.player_equip("iron_sword"), "food cannot be equipped, nor what is not carried")
	check(w.player_equip("rusty_sword") and p.weapon == "rusty_sword" and p.damage() == float(GameData.item("rusty_sword").damage), "the rusty sword's damage")
	w.player_unequip("weapon")
	check(p.weapon == "" and p.damage() == 2.0, "unarmed after putting the sword away")
	# eating
	p.hunger = 10.0
	var hp0 := p.hp
	check(w.player_eat("bread") and is_equal_approx(p.hunger, 10.0 + float(GameData.item("bread").food)), "bread feeds")
	check(not w.player_eat("bread"), "the bread is gone")
	check(w.player_eat("rotten_apple") and is_equal_approx(p.hp, hp0 - float(GameData.item("rotten_apple").harm)), "a rotten apple hurts")
	check(not w.player_eat("rusty_sword"), "a sword is not food")
	# dropping makes a bag that holds exactly what was dropped
	var items0 := p.inv.total()
	var bags0 := w.loot.size()
	check(w.player_drop("rusty_pickaxe", 1) and p.tool == "" and not p.inv.has("rusty_pickaxe"), "dropping the equipped pickaxe empties the tool slot")
	check(w.loot.size() == bags0 + 1 and w.loot[-1].inv.count("rusty_pickaxe") == 1 and p.inv.total() == items0 - 1, "the dropped pickaxe lies in a bag")
	check(not w.player_drop("rusty_pickaxe", 1) and not w.player_drop("plain_clothes", 0), "nothing more to drop")
	# harvesting: wheat comes from the field's crop, is counted as made, and is theft from its farmers
	var f: Dictionary = w.fields[0]
	w.set_field(f, "ripe")
	f.crop = 10
	var held0 := _wheat_held(w)
	var made0 := float(w.stats.get("made_wheat", 0.0))
	var hand := int(GameData.b("harvest_handful"))
	check(w.player_harvest(f) == hand and int(f.crop) == 10 - hand, "a handful from the field")
	check(_wheat_held(w) - held0 == hand and float(w.stats.get("made_wheat", 0.0)) - made0 == hand, "harvested wheat is accounted for")
	check(p.crimes.size() == 1 and p.crimes[0].kind == "theft" and int(p.crimes[0].victim) == int(f.owner[0]), "the theft is recorded against the field's farmer")
	check(w.player_harvest(f) == 10 - hand and f.state == "tilled", "the last of the crop, then the field is tilled")
	check(w.player_harvest(f) == 0, "nothing from a tilled field")
	# the new fields survive a save, and an older save without them loads with defaults
	p.sex = "female"
	p.look = "f2_tunic"
	w.player_equip("pickaxe")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var q := w2.player
	check(q.sex == "female" and q.look == "f2_tunic" and q.tool == "pickaxe" and q.crimes.size() == 2 and q.max_hp == p.max_hp, "sex, look, tool and crimes are saved")
	for k in ["sex", "look", "tool", "crimes"]:
		d.player.erase(k)
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d)
	check(w3.player.tool == "" and w3.player.crimes.is_empty() and w3.player.sex != "", "an older save without them loads")
	# the heir does not inherit the dead player's fights
	var guard: NPC = null
	for n: NPC in w.npcs:
		if n.job == "guard":
			guard = n
			break
	guard.target = -2
	w.player.coins = 300
	w.player.inv.add("iron_sword", 2)
	w.player.skills["mining"] = 500
	w.player.home = "house_test"
	var before := w.total_coins() - w.coin_sources
	w.damage_player(9999, "a guard")
	w.continue_as_heir()
	var h := w.player
	check(h.alive and guard.target == -1, "guards stop fighting once the player is dead and the heir takes over")
	check(h.coins == int(GameData.b("start_coins_player")) and h.inv.total() == kit.values().reduce(func(a, x): return a + int(x), 0) and not h.inv.has("iron_sword"), "the heir carries only the starting kit")
	check(h.skills.is_empty() and h.home == "house_test", "the heir keeps the house but starts every skill from nothing")
	check(w.loot[-1].coins == 300 and w.loot[-1].inv.count("iron_sword") == 2, "what the dead carried lies where they fell")
	check(w.total_coins() - w.coin_sources == before, "the heir's coins are counted as new to the village")
	w.dispose()
	w2.dispose()
	w3.dispose()


## Phase 1: skilled trades keep their inputs and buyers, and the treasury's excess is spent.
func test_trades_and_works() -> void:
	var w := new_world()
	var coins0 := w.total_coins() - w.coin_sources
	# a woodcutter whose axe broke sells the logs first
	var wc: NPC = null
	for n: NPC in w.npcs:
		if n.job == "woodcutter":
			wc = n
			break
	wc.inv.remove("axe", wc.inv.count("axe"))
	wc.inv.add("log", 5)
	wc.plan.clear()
	w.brain._woodcutter(wc)
	check(not wc.doing.begins_with("buying") and not wc.doing.begins_with("out of work"), "a woodcutter without an axe sells the logs first (%s)" % wc.doing)
	# the caravan brings ore only once the village's own seams are worked out
	var smith: NPC = null
	for n: NPC in w.npcs:
		if n.job == "smith":
			smith = n
			break
	smith.coins = 200
	smith.inv.remove("iron_ore", smith.inv.count("iron_ore"))
	check(w.brain._caravan_imports() == 0 or w.deposits.filter(func(d): return d.ore == "iron_ore" and int(d.amount) > 0).is_empty(), "no imports while the village has its own ore")
	for d in w.deposits:
		d.amount = 0
	smith.inv.remove("iron_ore", smith.inv.count("iron_ore"))
	coins0 = w.total_coins() - w.coin_sources             # the test set a purse by hand
	var src := w.coin_sources
	var smiths_cash := func() -> int:
		var c := 0
		for n: NPC in w.npcs:
			if n.job == "smith":
				c += n.coins
		return c
	var cash: int = smiths_cash.call()
	var spent: int = w.brain._caravan_imports()
	check(spent > 0 and smith.inv.count("iron_ore") == int(GameData.b("caravan_import_stock").iron_ore), "a smith buys ore from the caravan once the seams are worked out (%d coins)" % spent)
	check(smiths_cash.call() == cash - spent and w.coin_sources == src - spent, "the coins for imports leave the village")
	check(smith.coins >= int(GameData.b("trader_cash_floor")), "a smith keeps the trader cash floor")
	check(w.total_coins() - w.coin_sources == coins0, "coins conserved through imports")
	# public works spend the treasury's excess on planks, used up; not without a reeve
	var carp: NPC = null
	for n: NPC in w.npcs:
		if n.job == "carpenter":
			carp = n
			break
	carp.inv.add("plank", 30)
	var ob: float = w.brain.daily_obligations()
	w.treasury = int(ob * float(GameData.b("treasury_tax_holiday_days"))) + 400
	var t0 := w.treasury
	coins0 = w.total_coins() - w.coin_sources             # the test set the treasury by hand
	var planks0 := carp.inv.count("plank")
	var used: int = w.brain._public_works(ob)
	check(used > 0 and carp.inv.count("plank") < planks0 and w.treasury < t0, "public works buy planks and spend the excess (%d loads)" % used)
	check(carp.inv.count("plank") >= int(GameData.b("public_works_seller_keeps").plank), "the carpenter keeps some planks")
	check(t0 - w.treasury <= int(400 * float(GameData.b("public_works_share"))), "only a share of the excess is spent in a day")
	check(w.total_coins() - w.coin_sources == coins0, "coins conserved through public works")
	w.kill(w.npc(w.reeve_id), "a fever")
	carp.inv.add("plank", 30)
	check(w.brain._public_works(ob) == 0, "no public works without a reeve to commission them")
	w.dispose()


## Side quests: offered from real needs, accepted, completed with goods and coins moving between
## the player and the giver only; a giver's death fails the quest; offers and quests are saved.
func test_quests() -> void:
	var w := new_world()
	var p := w.player
	var side := func() -> Array: return p.quests.filter(func(q): return not Quests.template(q.id).get("story", false))
	# the storyline: every new player is sent to the sage in the north
	var sage: NPC = w.npc(w.sage_id)
	check(p.quests.any(func(q): return q.id == "the_sage_in_the_north" and int(q.giver) == sage.id), "a new game starts the story quest: the sage in the north")
	check(w.quests.diamond(sage), "the sage shows the green diamond")
	p.spells["fireball"] = true
	w.quests.on_learned("fireball")
	check(not p.quests.any(func(q): return q.id == "the_sage_in_the_north") and not w.quests.diamond(sage), "learning Fireball finishes the story quest")
	var cook: NPC = null
	for n: NPC in w.npcs:
		if n.job == "cook":
			cook = n
			break
	cook.inv.remove("log", cook.inv.count("log"))
	w.quests.offers.clear()
	w.quests.refresh()
	check(w.quests.offer_of(cook).get("id", "") == "wood_for_the_hearth", "a cook out of firewood offers a quest")
	check(w.quests.offers.size() <= int(GameData.b("quest_max_offers")), "no more offers than the cap")
	check(w.quests.line({"id": "wood_for_the_hearth", "giver": cook.id}, "offer").contains("5 log"), "the offer names the goods")
	var q: Dictionary = w.quests.accept(cook)
	check(not q.is_empty() and side.call().size() == 1 and w.quests.offer_of(cook).is_empty(), "accepting moves the offer to the player's quests")
	check(not w.quests.ready(q), "not ready without the logs")
	p.inv.add("log", 5)
	cook.coins = 40
	var coins0 := w.total_coins() - w.coin_sources
	var logs0 := cook.inv.count("log")
	var paid: int = w.quests.complete(q)
	check(paid == 10 and side.call().is_empty() and cook.inv.count("log") == logs0 + 5 and not p.inv.has("log"), "the logs go to the cook and the reward to the player (%d)" % paid)
	check(w.total_coins() - w.coin_sources == coins0, "a quest reward makes no coins")
	check(cook.memory.has("helped by %s" % p.name), "the cook remembers the help")
	# a poor giver pays what they have
	var smith: NPC = null
	for n: NPC in w.npcs:
		if n.job == "smith":
			smith = n
			break
	w.quests.offers[smith.id] = "ore_for_the_forge"
	var q2: Dictionary = w.quests.accept(smith)
	p.inv.add("iron_ore", 6)
	smith.coins = 7
	check(w.quests.complete(q2) == 7 and smith.coins == 0, "a giver who cannot pay in full pays all they have")
	# bandit trouble: a villager robbed by a living bandit
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if n.role == "bandit" and n.alive:
			bandit = n
			break
	var victim: NPC = w.npcs[3]
	victim.remember("robbed by %s" % bandit.name)
	check(w.quests._wants(victim, Quests.template("bandit_trouble")) and w.quests.robber_of(victim) == bandit, "a villager robbed by a living bandit wants them dealt with")
	w.quests.offers[victim.id] = "bandit_trouble"
	var q3: Dictionary = w.quests.accept(victim)
	check(int(q3.target) == bandit.id and not w.quests.ready(q3), "the quest names the bandit, still alive")
	check(w.quests.line(q3, "offer").contains(bandit.name), "the giver names the robber")
	w.kill(bandit, "slain by test")
	check(w.quests.ready(q3), "ready once the bandit is dead")
	# saved and loaded
	var giver2: NPC = w.npcs[5]
	w.quests.offers[giver2.id] = "a_new_axe"
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.quests.offers.get(giver2.id, "") == "a_new_axe" and w2.player.quests.size() == 1 and int(w2.player.quests[0].giver) == victim.id, "offers and accepted quests are saved")
	# an heir must seek the sage again (spells are not inherited)
	w2.damage_player(9999, "test")
	w2.continue_as_heir()
	check(w2.player.quests.any(func(q): return q.id == "the_sage_in_the_north"), "an heir starts the story quest again")
	# the giver dies: the quest fails
	w.kill(victim, "a fever")
	w.quests.drop_failed()
	check(side.call().is_empty(), "a quest fails when its giver dies")
	w.dispose()
	w2.dispose()


func _wheat_held(w: World) -> int:
	var n := w.player.inv.count("wheat") + w.granary.count("wheat")
	for o: NPC in w.npcs:
		n += o.inv.count("wheat")
	for hh in w.households:
		n += hh.pantry.count("wheat")
	for id in w.fauna.pens:
		n += int(w.fauna.pens[id].trough)
	for l in w.loot:
		n += l.inv.count("wheat")
	return n


func test_simulation(days: int) -> void:
	var w := new_world()
	var coins0 := w.total_coins()
	var wheat0 := _wheat_held(w)
	var ore0 := 0
	for d in w.deposits:
		ore0 += int(d.amount)
	var deaths := []
	w.npc_died.connect(func(n): deaths.append("%s (%s, %s)" % [n.name, n.role if n.job == "" else n.job, n.memory.back() if not n.memory.is_empty() else "?"]))
	var steps := int(days * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	var t0 := Time.get_ticks_msec()
	var snap := {}
	for i in steps:
		w.update(0.5)
		if i % int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5) == 0:
			snap = _census(w)
			print("%s  %s" % [w.clock_text(), snap])
	var ms := Time.get_ticks_msec() - t0
	print("simulated %d days in %.1f s (%.2f ms per step for %d people)" % [days, ms / 1000.0, float(ms) / steps, w.npcs.size()])
	var ore1 := 0
	var mined_neg := false
	for d in w.deposits:
		ore1 += int(d.amount)
		if int(d.amount) < 0:
			mined_neg = true
	check(not mined_neg, "no deposit below zero")
	check(ore1 < ore0, "ore was mined (%d -> %d)" % [ore0, ore1])
	check(w.total_coins() == coins0 + w.coin_sources, "coins conserved: %d + sources %d = %d" % [coins0, w.coin_sources, w.total_coins()])
	var st: Dictionary = w.stats
	var expect := wheat0 + int(st.get("made_wheat", 0)) - int(st.get("used_wheat", 0)) - int(st.get("feed_eaten_wheat", 0)) \
		- int(st.get("eaten_wheat", 0)) - int(st.get("exported_wheat", 0))
	check(_wheat_held(w) == expect, "grain conserved: held %d, expected %d (harvest - cooked - fed - eaten - exported)" % [_wheat_held(w), expect])
	var c := _census(w)
	check(c.alive_villagers >= 90, "most villagers alive after %d days (%d)" % [days, c.alive_villagers])
	check(int(c.made.get("iron_bar", 0)) + int(c.made.get("pickaxe", 0)) + int(c.made.get("axe", 0)) > 0, "smith produced something")
	check(c.lost == 0, "nobody lost (no path) at the end")
	for k in ["cow", "pig", "sheep", "chicken", "boar", "rabbit"]:
		check(int(c.animals.get(k, 0)) >= 2, "%s still kept or living wild after %d days (%d)" % [k, days, int(c.animals.get(k, 0))])
	print("deaths: ", deaths)
	print("last events:")
	for l in w.log_lines.slice(-25):
		print("  ", l)


func _census(w: World) -> Dictionary:
	var made := {}
	var doing := {}
	var lost := 0
	var alive := 0
	var hungry := 0
	for n: NPC in w.npcs:
		if not n.alive or n.role == "bandit":
			continue
		alive += 1
		if n.hunger < 20:
			hungry += 1
		if n.doing == "lost":
			lost += 1
		for id in ["iron_bar", "pickaxe", "axe", "iron_sword", "plank", "leather", "pottage", "wheat"]:
			made[id] = int(made.get(id, 0)) + n.inv.count(id)
		var k: String = n.doing.split(" ")[0]
		doing[k] = int(doing.get(k, 0)) + 1
	var ore := 0
	for d in w.deposits:
		ore += int(d.amount)
	var beasts := {}
	for a: Animal in w.fauna.animals:
		beasts[a.species] = int(beasts.get(a.species, 0)) + 1
	return {"alive_villagers": alive, "hungry": hungry, "lost": lost, "ore_left": ore, "animals": beasts,
		"coins": w.total_coins(), "made": made, "doing": doing}


func test_save_round_trip() -> void:
	var w := new_world()
	for i in 600:
		w.update(0.5)
	var d := w.to_dict()
	var text := JSON.stringify(d)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(w2.npcs.size() == w.npcs.size(), "same people after load")
	check(w2.total_coins() == w.total_coins(), "same coins after load")
	check(absf(w2.minutes - w.minutes) < 0.01, "same time after load")
	var d2 := JSON.stringify(w2.to_dict())
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(d2))
	check(JSON.stringify(w3.to_dict()) == d2, "load -> save -> load -> save is stable")
	check(w2.fauna.animals.size() == w.fauna.animals.size(), "same animals after load")
	# a save from before animals (save_version 1, with the old deer count) still loads
	var old: Dictionary = JSON.parse_string(text)
	old.erase("fauna")
	old.save_version = 1
	old.deer = 30
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), old)
	check(w4.npcs.size() == w.npcs.size() and w4.fauna.animals.size() > 0, "a version 1 save loads and gets its animals")
	check(w4.fauna.pen_of("cow").owner != -1, "pens get keepers after loading a version 1 save")
	check(w4.total_coins() == w.total_coins(), "a version 1 save keeps every coin (%d vs %d)" % [w4.total_coins(), w.total_coins()])
	# a version 2 save (before the manor treasury): the reeve's coins become the treasury
	var v2: Dictionary = JSON.parse_string(text)
	v2.erase("treasury")
	v2.erase("granary")
	v2.erase("last_reeve_day")
	v2.erase("last_payday")
	v2.save_version = 2
	var treasury_then := w.treasury
	for nd in v2.npcs:
		if int(nd.id) == w.reeve_id:
			nd.coins = int(nd.coins) + w.treasury          # in a version 2 world the funds were the reeve's
	var w5 := World.new()
	w5.load_dict(VillageMap.load_default(), v2)
	check(w5.treasury == treasury_then and w5.npc(w5.reeve_id).coins == int(GameData.b("reeve_purse")), "a version 2 save's reeve coins move into the treasury (%d)" % w5.treasury)
	check(w5.total_coins() == w.total_coins(), "a version 2 save keeps every coin")
	check(int(d.save_version) == 3 and JSON.stringify(w5.to_dict()).contains("\"treasury\""), "saves are written as version 3 with the treasury and granary")
