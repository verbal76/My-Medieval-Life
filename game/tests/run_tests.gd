extends SceneTree
## Headless tests and simulation checks. Run:
##   godot --headless --path game --script res://tests/run_tests.gd [-- --days N]
## Exit code 0 = all passed.

var failures := 0
var checks := 0
const FAR_PEOPLE := Vector2(3.5, 3.5)       # out of sight of the tavern and the market (theft tests)
const FAR_GUARDS := Vector2(116.5, 86.5)    # and the guards, out of sight and earshot of everyone


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
	test_tree_canopy()
	test_trades_and_works()
	test_quests()
	test_child_food()
	test_hiring()
	test_skill_quest()
	test_building_site()
	test_interiors()
	test_chest_keeps_marks()
	test_beds()
	test_theft_and_shops()
	test_property()
	test_property_migration()
	test_construction()
	test_helpers()
	test_households_split()
	test_construction_migration()
	test_build7_economy()
	test_manor_work()
	test_long_run_economy()
	test_resource_registry()
	test_wild_plants()
	test_save_store()
	test_doorways()
	test_village_layout()
	test_polish_work_looks()
	test_polish_game_leftovers()
	test_field_edges()
	test_work_has_purpose()
	test_no_child_pickpocket()
	test_credits()
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
	var a_start := a.coins
	a.coins = 5
	b.inv.add("iron_sword")
	var ok := w.trade(a, b, "iron_sword", 1, 50)
	check(not ok and b.inv.has("iron_sword") and a.coins == 5, "trade fails whole when buyer is short")
	check(w.total_coins() == before - (a_start - 5), "a refused trade moves no coins")
	a.coins = 60
	var b_coins := b.coins
	var held := w.total_coins()
	check(w.trade(a, b, "iron_sword", 1, 50) and a.inv.has("iron_sword") and a.coins == 10 and b.coins == b_coins + 50, "trade moves goods and coins")
	check(w.total_coins() == held, "a trade conserves the village's coins")


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
	check(not pen.is_empty() and w.pen_keeper(pen) != null and w.owner_of(pen) == World.MANOR, "the pig pen has a keeper (the manor's pen, let to them)")
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
	var keeper := w.pen_keeper(pen)
	keeper.plan.clear()
	b._keeper(keeper)
	check(keeper.plan.size() == 2 and keeper.plan[1].get("act", "") == "slaughter", "in a famine the keeper slaughters beyond the breeding stock")
	w.food_days = 99.0
	# an untended field is taken over by a hand at the manor
	var field: Dictionary = w.fields[1]
	var tenders := w.field_workers(field)
	for o: NPC in tenders:
		o.job = "manor_hand"
	var hand: NPC = tenders[0]
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
	check(w.granary.count("wheat") + w.manor_work.bound("granary", "wheat") > 0 and farmer.inv.count("wheat") >= keep, "outside a famine it buys only the surplus, left at the farmer's for the manor's carriers (farmer keeps %d)" % farmer.inv.count("wheat"))
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
	var kids := w.alive_count("child")
	check(w.granary.count("wheat") == ceili(((100 - kids) + kids * float(GameData.b("child_food_factor"))) * 72.0 * 7 / 120.0), "the settlers' granary holds 7 days of the village's food, children weighted (%d)" % w.granary.count("wheat"))
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
	var weighted := 0.0
	for o: NPC in b._members(h):
		weighted += 72.0 * (float(GameData.b("child_food_factor")) if o.role == "child" else 1.0)
	check(is_equal_approx(float(econ.need), weighted), "its daily food need follows its members, children weighted (%.1f)" % float(econ.need))
	# a keeper's death hands the pen on
	var pen: Dictionary = w.fauna.pen_of("cow")
	var keeper := w.pen_keeper(pen)
	w.kill(keeper, "a fall")
	var nk := w.pen_keeper(pen)
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
			filler.id = 8000 + b._field_workers(f) * 10 + w.fields.find(f)
			filler.job = "farmer"
			filler.workplace = f.id
			w.npcs.append(filler)
			w.by_id[filler.id] = filler
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
	var farmer0: NPC = w.field_workers(f)[0]
	check(w.player_harvest(f) == hand and int(f.crop) == 10 - hand, "a handful from the field")
	check(_wheat_held(w) - held0 == hand and float(w.stats.get("made_wheat", 0.0)) - made0 == hand, "harvested wheat is accounted for")
	check(p.crimes.size() == 1 and p.crimes[0].kind == "theft" and int(p.crimes[0].victim) == farmer0.id, "the theft is recorded against the field's farmer")
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
	# head, amulet and ring: worn like the other gear, saved, and empty in an older save
	for id in ["iron_helmet", "gold_ring", "amulet"]:
		p.inv.add(id)
	var def0 := p.defense()
	check(w.player_equip("iron_helmet") and p.head == "iron_helmet" and p.defense() == def0 + float(GameData.item("iron_helmet").armor), "a helmet adds its armour to the body armour's")
	check(w.player_equip("gold_ring") and p.ring == "gold_ring" and p.stamina_cap() == PlayerState.BASE_STAMINA + 10.0, "a gold ring: +10 max stamina")
	check(w.player_equip("amulet") and p.amulet == "amulet" and p.hp_cap() == p.max_hp + 5.0, "an amulet: +5 max health")
	p.hp = p.hp_cap()
	p.stamina = p.stamina_cap()
	w.player_unequip("amulet")
	check(p.hp == p.max_hp and p.hp_cap() == p.max_hp, "taking the amulet off brings health down to the plain maximum")
	w.player_equip("amulet")
	check(not w.player_equip("wheat") and not w.player_equip("copper_ring"), "neither a material nor jewellery not carried can be worn")
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), d2)
	check(w4.player.head == "iron_helmet" and w4.player.ring == "gold_ring" and w4.player.amulet == "amulet", "head, ring and amulet are saved")
	for k in ["head", "amulet", "ring"]:
		d2.player.erase(k)
	var w5 := World.new()
	w5.load_dict(VillageMap.load_default(), d2)
	check(w5.player.head == "" and w5.player.ring == "" and w5.player.amulet == "" and w5.player.weapon == w4.player.weapon, "an older save without them loads with them empty")
	check(w.player_drop("gold_ring", 1) and p.ring == "" and p.stamina == p.stamina_cap(), "dropping the worn ring empties the slot and the extra stamina")
	for r in ["leather_cap", "forge_iron_helmet", "forge_copper_ring", "forge_gold_ring", "forge_amulet"]:
		var rec: Dictionary = GameData.recipes[r]
		var out: String = rec.out.keys()[0]
		check(GameData.item(out).get("type", "") in ["head", "ring", "amulet"] and rec.station in ["anvil", "workbench"], "%s makes %s" % [r, out])
	w4.dispose()
	w5.dispose()
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
	check(not w.player.alive and w.player.death_cause == "a guard" and w.player.last_damage == "a guard", "a killing blow records its source as the cause of death (B8-020)")
	check(PlayerState.from_dict(w.player.to_dict()).death_cause == "a guard", "the cause of death is saved")
	w.continue_as_heir()
	var h := w.player
	check(h.death_cause == "" and h.last_damage == "", "the heir starts with no cause of death")
	check(h.alive and guard.target == -1, "guards stop fighting once the player is dead and the heir takes over")
	check(h.coins == int(GameData.b("start_coins_player")) and h.inv.total() == kit.values().reduce(func(a, x): return a + int(x), 0) and not h.inv.has("iron_sword"), "the heir carries only the starting kit")
	check(h.skills.is_empty() and h.home == "house_test", "the heir keeps the house but starts every skill from nothing")
	check(w.loot[-1].coins == 300 and w.loot[-1].inv.count("iron_sword") == 2, "what the dead carried lies where they fell")
	check(w.total_coins() - w.coin_sources == before, "the heir's coins are counted as new to the village")
	w.dispose()
	w2.dispose()
	w3.dispose()


## Phase 1: skilled trades keep their inputs and buyers, and the treasury's excess is spent.
## Trees: only the trunk cell is solid; the canopy (top at y - 1, bottom over the trunk) is in an
## "above" layer, walkable, and is taken away by felling and put back by regrowth.
func test_tree_canopy() -> void:
	var w := new_world()
	var m := w.map
	check(lay_is_above(m, "above0"), "tile canopies (arches and hedges) are in a layer drawn over the characters")
	var t := {}
	for tr in w.trees:
		var x := int(tr.x)
		var y := int(tr.y)
		if y < 30 and tr.state == "grown" and m.is_solid(Vector2i(x, y)) and not m.is_solid(Vector2i(x - 1, y - 1)) and not m.is_solid(Vector2i(x + 1, y - 1)):
			t = tr
			break
	check(not t.is_empty(), "a mature tree with open ground beside it")
	if t.is_empty():
		return
	var trunk := Vector2i(int(t.x), int(t.y))
	var top := trunk + Vector2i.UP
	check(m.is_solid(trunk), "a mature tree's trunk is solid")
	check(not m.is_solid(top), "a mature tree's canopy is walkable")
	var path := m.find_path(top + Vector2i.LEFT, top + Vector2i.RIGHT)
	check(path.size() == 3 and path.has(Vector2(top)), "a path goes straight through a canopy: %s" % [path])
	var felled := []
	w.tree_felled.connect(func(tr: Dictionary, side: int): felled.append(side))
	var chops := int(Trees.cfg().chops)
	# blow by blow: the cut marks grow, the last blow fells, no logs before it, and only once
	var logs := 0
	for k in chops - 1:
		var r := w.chop_tree(t, -1, 0)
		logs += int(r.logs)
		check(int(r.hits) == k + 1 and t.state == "grown" and m.is_solid(trunk), "blow %d only hurts the tree" % [k + 1])
	check(logs == 0 and w.tree_hits(trunk) == chops - 1, "no logs before the last blow")
	var last := w.chop_tree(t, -1, 0)
	check(int(last.logs) == 4 and t.state == "stump" and felled == [-1], "the last blow fells it: 4 logs, a stump, falling to the side of the blow")
	check(w.chop_tree(t, -1, 0).logs == 0 and w.fell(t, 0) == 0, "a felled tree gives no logs twice")
	check(not m.is_solid(trunk) and w.tree_hits(trunk) == 0, "a stump is walkable and unhurt")
	check(w.sapling_drop(t).size() == 1, "felling gives a sapling")
	# a hurt tree heals
	var t_h := {}
	for tr in w.trees:
		if tr.state == "grown" and tr != t:
			t_h = tr
			break
	w.chop_tree(t_h, 1, 0)
	w.minutes += float(Trees.cfg().heal_minutes) + 1.0
	check(w.tree_hits(Vector2i(int(t_h.x), int(t_h.y))) == 0, "a hurt tree heals after a while")
	# regrowth: stump -> sapling -> young -> growing -> mature, by the clock only, collision by stage
	w.minutes = float(t.regrow) * Trees.DAY - 1.0
	w.sync_tree(t)
	check(t.state == "stump", "the stump waits until its day")
	w.minutes = float(t.regrow) * Trees.DAY + 1.0
	w.sync_tree(t)
	check(t.state == "sapling" and not m.is_solid(trunk), "a stump sprouts into a walkable sapling")
	check(w.fell(t, 0) == 0 and w.chop_tree(t, 1, 0).logs == 0, "a sapling cannot be felled")
	w.minutes = float(t.born) + Trees.stage_minutes("sapling") + 1.0
	w.sync_tree(t)
	check(t.state == "young" and not m.is_solid(trunk) and w.fell(t, 0) == 0, "then a young tree: not solid, cannot be felled")
	w.minutes += Trees.stage_minutes("young")
	w.sync_tree(t)
	check(t.state == "growing" and m.is_solid(trunk) and w.fell(t, 0) == 0, "then a growing tree: solid trunk, cannot be felled")
	w.minutes += Trees.stage_minutes("growing")
	w.sync_tree(t)
	check(t.state == "grown" and m.is_solid(trunk) and not m.is_solid(top), "then mature again: solid trunk, walkable canopy")
	check(w.fell(t, 0) == 4, "and can be felled once more")
	# growth waits for somebody standing where a trunk would appear
	var t_y := {"x": trunk.x, "y": trunk.y, "species": "oak_summer", "state": "young", "regrow": 0.0, "born": w.minutes - Trees.stage_minutes("sapling") - Trees.stage_minutes("young") - 5.0}
	w.player.pos = Vector2(trunk) + Vector2(0.5, 0.5)
	check(not w.sync_tree(t_y) and t_y.state == "young", "a young tree does not grow solid under the player's feet")
	w.player.pos = Vector2(trunk) + Vector2(6.5, 0.5)
	check(w.sync_tree(t_y) and t_y.state == "growing", "and grows once they step away")
	# saves: a felled tree stays a stump; trees keep their stage; planted trees are kept
	var cell := _plant_spot(w)
	check(cell.x >= 0, "free grass to plant on")
	w.player.inv.add("oak_sapling", 1)
	var planted := w.plant_tree(cell, "oak_sapling")
	check(not planted.is_empty() and planted.state == "sapling" and planted.planted and not m.is_solid(cell), "a sapling is planted on free grass and is not solid")
	check(w.plant_refusal(cell).contains("tree"), "not again on the same cell: %s" % w.plant_refusal(cell))
	check(w.plant_refusal(cell + Vector2i(1, 0)) != "", "nor beside another tree")
	w.fell(t, 0)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var t2 := w2.tree_at(trunk)
	check(t2.state == "stump" and not w2.map.is_solid(trunk), "after loading, a felled tree is still a stump, walkable")
	var p2 := w2.tree_at(cell)
	check(not p2.is_empty() and p2.state == "sapling" and p2.get("planted", false) and p2.species == planted.species, "after loading, the planted sapling is still there")
	w2.minutes = float(planted.born) + Trees.stage_minutes("sapling") + Trees.stage_minutes("young") + Trees.stage_minutes("growing") + 1.0
	w2.sync_tree(p2)
	check(p2.state == "grown" and w2.map.is_solid(cell) and w2.fell(p2, 0) == 4, "a planted sapling grows into a tree that can be felled")
	# woodcutters only fell mature trees
	var near := w.nearest_tree(Vector2i(int(t_h.x), int(t_h.y)), 500.0)
	check(near.is_empty() or near.state == "grown", "villagers look for mature trees only")
	# every species grows through all stages and is felled once, with a picture for each stage
	for sp in Trees.art().variants:
		var v: Dictionary = Trees.art().variants[sp]
		var s := {"x": cell.x + 40, "y": cell.y, "species": sp, "state": "sapling", "regrow": 0.0, "born": w.minutes}
		var stages := [s.state]
		for st in ["sapling", "young", "growing"]:
			w.minutes += Trees.stage_minutes(st) + 0.5
			Trees.sync(s, w.minutes)
			stages.append(s.state)
		check(stages == ["sapling", "young", "growing", "grown"], "%s: sapling to mature %s" % [sp, stages])
		var pics := true
		for f in [v.sizes.young.file, v.sizes.growing.file, v.sizes.mature.file, v.stump.file, v.sapling.file, v.top.file, v.cuts.left[2].file, v.cuts.right[0].file]:
			pics = pics and Trees.texture(str(f)) != null
		check(pics, "%s has a picture for every stage, the stump, the falling top and the cut marks" % sp)
	# the village starts with trees of several species and stages, in patches, none on a road or exit
	var kinds := {}
	var stages_seen := {}
	var same := 0
	var pairs := 0
	var by_cell := {}
	for tr in w.trees:
		by_cell[Vector2i(int(tr.x), int(tr.y))] = tr
	for tr in w.trees:
		if tr.get("planted", false) or tr.state == "stump":
			continue
		kinds[tr.species] = true
		stages_seen[str(Trees.stage_at(7.0 * 60.0 - Trees.born_of(tr)))] = true
		for dd in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 0), Vector2i(0, 2)]:
			var o: Dictionary = by_cell.get(Vector2i(int(tr.x), int(tr.y)) + dd, {})
			if not o.is_empty():
				pairs += 1
				same += 1 if o.species == tr.species else 0
	check(kinds.size() >= 3, "the village's trees are of several species: %s" % [kinds.keys()])
	check(pairs > 50 and same < pairs * 9 / 10 and same > pairs / 5, "species come in patches, not all alike and not all different (%d of %d neighbours alike)" % [same, pairs])
	check(stages_seen.size() >= 3, "the village starts with trees of several growth stages: %s" % [stages_seen.keys()])
	var roads := {}
	for c in m.data.road:
		roads[Vector2i(int(c[0]), int(c[1]))] = true
	var on_road := 0
	for tr in w.trees:
		if roads.has(Vector2i(int(tr.x), int(tr.y))):
			on_road += 1
	check(on_road == 0, "no tree stands on a road")


## A cell of free grass the player could plant on, or (-1, -1).
func _plant_spot(w: World) -> Vector2i:
	for y in range(30, 60):
		for x in range(40, 80):
			if w.plant_refusal(Vector2i(x, y)) == "":
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func lay_is_above(m: VillageMap, name: String) -> bool:
	for lay in m.data.layers:
		if lay.name == name:
			return lay.z == "above"
	return false


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
	check(w.quests.marker(sage) == "story", "the sage shows the story pennant")
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
	# owner, 2026-10-18 (B7-002): a reward is offered only by someone who can pay it, set aside when
	# the player agrees, and paid in full
	smith.inv.remove("iron_ore", smith.inv.count("iron_ore"))
	var forge := Quests.template("ore_for_the_forge")
	smith.coins = 7
	check(not w.quests._wants(smith, forge), "a smith who cannot pay twenty coins does not offer them")
	w.quests.offers[smith.id] = "ore_for_the_forge"
	check(w.quests.accept(smith).is_empty() and w.quests.offer_of(smith).is_empty() and smith.coins == 7 and w.quests.last_refusal.contains("no longer pay"),
			"an offer the giver can no longer pay is withdrawn, and they keep their coins")
	smith.coins = 30
	check(w.quests._wants(smith, forge), "with the coins, the smith offers it")
	w.quests.offers[smith.id] = "ore_for_the_forge"
	var c1 := w.total_coins()
	var q2: Dictionary = w.quests.accept(smith)
	check(int(q2.reserved) == 20 and smith.coins == 10 and w.total_coins() == c1, "the twenty coins are set aside when the player agrees (still counted)")
	p.inv.add("iron_ore", 6)
	smith.coins = 0                                      # the smith spends everything else
	var c2 := w.total_coins()
	check(w.quests.complete(q2) == 20 and smith.coins == 0 and int(q2.reserved) == 0 and w.total_coins() == c2, "the promised twenty are paid in full though the smith spent the rest")
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


## Children eat by age: a child gets hungry child_food_factor as fast, and every food reckoning
## (household days, relief, the farmer's keep, the granary, the village's days, the caravan,
## the household reckoning and the quests' household_food_below) weights members the same way.
func test_child_food() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	var k := float(GameData.b("child_food_factor"))
	var child: NPC = w.npcs.filter(func(o): return o.role == "child")[0]
	var adult: NPC = w.npcs.filter(func(o): return o.role == "adult")[0]
	var elder: NPC = w.npcs.filter(func(o): return o.role == "elder")[0]
	check(NPCBrain.food_factor(child) == k and NPCBrain.food_factor(adult) == 1.0 and NPCBrain.food_factor(elder) == 1.0, "a child eats %.2f of an adult's food; adults and elders the same" % k)
	# hunger falls more slowly for a child
	for o: NPC in [child, adult]:
		o.hunger = 100.0
		o.target = -1
		o.plan = [b.work(100000, "", {}, "idle")]
	w._update_npc(child, 10.0)
	w._update_npc(adult, 10.0)
	check(is_equal_approx(100.0 - child.hunger, (100.0 - adult.hunger) * k), "a child gets hungry %.2f as fast (%.2f vs %.2f lost)" % [k, 100.0 - child.hunger, 100.0 - adult.hunger])
	# a household with children: its need, its days of food, its reckoning
	var h := -1
	for i in w.households.size():
		if b._members(i).any(func(o): return o.role == "child"):
			h = i
			break
	var members: Array = b._members(h)
	var weight := 0.0
	for o: NPC in members:
		weight += k if o.role == "child" else 1.0
	check(weight < members.size() and is_equal_approx(b.household_day_food(h), weight * 72.0), "a household's daily need weights its children (%.1f for %d members)" % [b.household_day_food(h), members.size()])
	for o: NPC in members:
		o.coins = 0
	w.households[h].pantry.items.clear()
	w.households[h].pantry.add("wheat", 3)
	check(is_equal_approx(b.household_food_days(h), 360.0 / (weight * 72.0)), "days of food are counted against the weighted need (%.2f)" % b.household_food_days(h))
	check(is_equal_approx(float(b.evaluate_household(h).need), weight * 72.0), "the household reckoning uses the weighted need")
	var vill := 0.0
	for o: NPC in w.npcs:
		if o.alive and o.role != "bandit":
			vill += k if o.role == "child" else 1.0
	check(is_equal_approx(b.village_day_food(), vill * 72.0), "the village's need weights its children (%.0f)" % b.village_day_food())
	# the quests' household_food_below follows household_food_days: 1.4 days for this household
	var elder_h := -1
	for i in w.households.size():
		if b._members(i).any(func(o): return o.role == "elder") and b._members(i).any(func(o): return o.role == "child"):
			elder_h = i
			break
	if elder_h >= 0:
		var em: Array = b._members(elder_h)
		var ew := 0.0
		for o: NPC in em:
			o.coins = 0
			ew += k if o.role == "child" else 1.0
		var giver: NPC = em.filter(func(o): return o.role == "elder")[0]
		w.households[elder_h].pantry.items.clear()
		# pottage for 1.6 adult-weighted days: below 1.5 days if children ate like adults, above it now
		var pots := ceili(1.6 * ew * 72.0 / 40.0)
		w.households[elder_h].pantry.add("pottage", pots)
		var days := b.household_food_days(elder_h)
		check(days >= 1.5 and (w.quests._wants(giver, Quests.template("food_for_the_family")) == false), "the food quest reads the weighted days (%.2f): this household is not short" % days)
	# relief fills a household to 3 days of its weighted need
	w.treasury = 100000
	w.granary.items.clear()
	w.granary.add("wheat", 500)
	w.households[h].pantry.items.clear()
	for o: NPC in members:
		for f in NPCBrain.FOOD:
			o.inv.remove(f, o.inv.count(f))
	b.market_food_points = 0.0
	b._relief(10.0, 100.0)
	var given: int = w.households[h].pantry.count("wheat")
	check(given == ceili(3.0 * weight * 72.0 / 120.0), "relief grain is 3 days of the weighted need (%d wheat)" % given)
	# a farmer keeps 3 days of the household's weighted need
	var farmer: NPC = w.npcs.filter(func(o): return o.job == "farmer")[0]
	var keep := int(GameData.b("granary_keep_buffer")) + b.reserve(farmer, "wheat") + ceili(b.household_day_food(farmer.household) * float(GameData.b("granary_keep_household_days")) / 120.0)
	check(b.keep_wheat(farmer) == keep, "a farmer's household keep is weighted (%d)" % keep)
	# the granary buys up to 7 days of the village's weighted need
	w.granary.items.clear()
	w.food_days = 99.0
	farmer.inv.add("wheat", 2000)
	farmer.coins = 0
	w.last_reeve_day = -1
	b.reeve_day()
	var granary_wheat := w.granary.count("wheat") + w.manor_work.bound("granary", "wheat")
	check(granary_wheat == int(b.village_day_food() * float(GameData.b("granary_target_days")) / 120.0) and b.village_day_food() < (w.alive_count() - w.alive_count("bandit")) * 72.0,"the granary's target is 7 days of the weighted need, with what is on its way (%d)" % granary_wheat)
	# the village's days of food
	w._update_food_days()
	var pts := 0.0
	for o: NPC in w.npcs:
		if o.alive and o.role != "bandit":
			for f in NPCBrain.FOOD:
				pts += o.inv.count(f) * float(GameData.item(f).food)
	for hh in w.households:
		for f in NPCBrain.FOOD:
			pts += hh.pantry.count(f) * float(GameData.item(f).food)
	for f in NPCBrain.FOOD:
		pts += w.table_food(f) * float(GameData.item(f).food)
	pts += w.granary.count("wheat") * float(GameData.item("wheat").food)
	pts += w.manor_work.food_points()
	check(is_equal_approx(w.food_days, pts / b.village_day_food()), "the village's food days use the weighted need (%.2f)" % w.food_days)
	# the caravan: food between the weighted and the unweighted 3-day reserve is not held back
	var seller: NPC = null
	for o: NPC in w.npcs:
		for f in NPCBrain.FOOD:
			o.inv.remove(f, o.inv.count(f))
		if o.job == "merchant" and b.buy_role(o) == "merchant_food" and seller == null:
			seller = o
	for hh in w.households:
		for f in NPCBrain.FOOD:
			hh.pantry.remove(f, hh.pantry.count(f))
	for c in w.containers:
		if c.kind == "table":
			c.inv.items.clear()
	var reserve_days := float(GameData.b("caravan_food_reserve_days"))
	var people := w.alive_count() - w.alive_count("bandit")
	var between := (b.village_day_food() * reserve_days + people * 72.0 * reserve_days) / 2.0
	seller.inv.add("pottage", ceili(between / 40.0))
	w.stats.erase("exported_pottage")
	b.caravan()
	check(int(w.stats.get("exported_pottage", 0)) > 0, "the caravan's food reserve is the weighted need: it buys food above it")
	for f in NPCBrain.FOOD:
		seller.inv.remove(f, seller.inv.count(f))
	seller.inv.add("pottage", floori(b.village_day_food() * reserve_days / 40.0) - 1)
	w.stats.erase("exported_pottage")
	b.caravan()
	check(int(w.stats.get("exported_pottage", 0)) == 0, "and holds the food back below it")
	w.dispose()


## Paid work for the player: a villager with work and the wage offers it when asked; the player
## does it with the ordinary mechanics; the wage comes from the employer's purse, in full.
func test_hiring() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	var p := w.player
	p.pos = FAR_GUARDS
	var farmer: NPC = null
	for o: NPC in w.npcs:
		if o.job == "farmer" and not w.quests.field_of(o).is_empty():
			farmer = o
			break
	var f: Dictionary = w.quests.field_of(farmer)
	w.set_field(f, "tilled")
	farmer.coins = 20
	check(w.quests.hires(farmer) and w.quests.hire_offer(farmer).is_empty(), "a farmer whose field is not ripe has no work")
	check(w.quests.no_work_line(farmer).begins_with("Not today"), "and says so")
	w.set_field(f, "ripe")
	f.crop = 60
	check(w.quests.hire_offer(farmer).get("id", "") == "work_the_harvest", "a farmer at harvest offers the player work")
	w.quests.offers.clear()
	w.quests.refresh()
	check(not w.quests.offers.values().has("work_the_harvest") and w.quests.marker(farmer) != "skill", "paid work is never a dawn offer or a marker")
	farmer.coins = 5
	check(w.quests.hire_offer(farmer).is_empty() and w.quests.no_work_line(farmer).contains("can't pay"), "an employer who cannot pay the wage offers no work")
	check(w.quests.accept(farmer, "work_the_harvest").is_empty(), "and the work cannot be taken on")
	farmer.coins = 20
	var children: Array = w.npcs.filter(func(o): return o.role == "child")
	check(not w.quests.hires(children[0]) and not w.quests.hires(w.npc(w.sage_id)), "children and the sage hire nobody")
	var q: Dictionary = w.quests.accept(farmer, "work_the_harvest")
	check(not q.is_empty() and p.quests.has(q), "the player takes on the harvest")
	# the farmer leaves the hired field alone
	farmer.plan.clear()
	b._farmer(farmer)
	check(not farmer.plan.any(func(s): return s.get("act", "") == "harvest"), "the farmer leaves a hired field to the hired hand")
	check(not b.act(farmer, "harvest", {"field": f.id}) and int(f.crop) == 60, "and does not cut it")
	# cutting it: no theft for the hired amount, theft beyond it
	var crimes0 := p.crimes.size()
	for i in 4:
		w.player_harvest(f)
	check(p.crimes.size() == crimes0 and p.stolen_count("wheat") == 0 and int(q.harvested) == 24, "cutting the hired 24 wheat is not theft")
	check(w.quests.hired_on(f).is_empty(), "once cut, the field is the farmer's again")
	w.player_harvest(f)
	check(p.crimes.size() == crimes0 + 1, "a handful more is theft")
	p.inv.remove("wheat", p.inv.count("wheat") - 24)        # (what was stolen, unless a guard took it back)
	p.trim_stolen()
	check(w.quests.ready(q), "ready with the wheat")
	# the wage was set aside when the work was taken on (B7-002), so it is paid in full
	check(int(q.reserved) == 6, "the wage was set aside from the farmer's purse when the player took the work")
	farmer.coins = 0                                     # the farmer spends everything else
	var coins0 := w.total_coins()
	var wheat0 := farmer.inv.count("wheat")
	var purse := p.coins
	check(w.quests.complete(q) == 6 and p.coins == purse + 6 and farmer.coins == 0 and farmer.inv.count("wheat") == wheat0 + 24 and not p.quests.has(q), "the wage set aside is paid in full; the wheat goes to the farmer")
	check(w.total_coins() == coins0, "a wage makes no coins")
	check(int(w.stats.get("hired_wages", 0)) == 6, "the ledger records the wage")
	# a woodcutter's day: logs delivered; undone work lapses
	var wc: NPC = w.npcs.filter(func(o): return o.job == "woodcutter")[0]
	wc.inv.remove("log", wc.inv.count("log"))
	wc.coins = 20
	var q2: Dictionary = w.quests.accept(wc, "work_the_woods")
	check(not q2.is_empty() and w.quests.line(q2, "offer").contains("6 log") and w.quests.line(q2, "offer").contains("six coins"), "a woodcutter short of logs hires the player: %s" % w.quests.line(q2, "offer"))
	check(w.quests.accept(wc, "work_the_woods").is_empty(), "one job at a time from one employer")
	q2.day = w.day() - 2
	w.quests.drop_failed()
	check(p.quests.has(q2), "the work is open for its days")
	q2.day = w.day() - 3
	w.quests.drop_failed()
	check(not p.quests.has(q2), "work left undone lapses")
	# a miner's shift, and it is saved
	var mn: NPC = w.npcs.filter(func(o): return o.job == "miner")[0]
	mn.inv.remove("iron_ore", mn.inv.count("iron_ore"))
	mn.coins = 20
	var q3: Dictionary = w.quests.accept(mn, "work_the_mine")
	check(not q3.is_empty(), "a miner short of ore hires the player")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.player.quests.any(func(x): return x.id == "work_the_mine" and int(x.giver) == mn.id), "accepted work is saved")
	w.dispose()
	w2.dispose()


## A side quest that teaches a skill: the tanner shows the scroll, and two hides raise Crafting to
## level 2, which unlocks leather armour.
func test_skill_quest() -> void:
	var w := new_world()
	var p := w.player
	var tanner: NPC = w.npcs.filter(func(o): return o.job == "tanner")[0]
	tanner.inv.remove("hide", tanner.inv.count("hide"))
	w.quests.offers.clear()
	w.quests.refresh()
	check(w.quests.offer_of(tanner).get("id", "") == "the_tanners_craft", "a tanner short of hides offers to teach")
	check(w.quests.marker(tanner) == "skill", "the teacher shows the skill scroll")
	var rec: Dictionary = GameData.recipes["leather_armor"]
	check(p.level("crafting") < int(rec.level), "leather armour is out of reach before")
	var q: Dictionary = w.quests.accept(tanner)
	p.inv.add("hide", 2)
	var coins0 := w.total_coins()
	var hides0 := tanner.inv.count("hide")
	check(w.quests.complete(q) == 0 and tanner.inv.count("hide") == hides0 + 2 and not p.inv.has("hide"), "the hides go to the tanner")
	check(p.level("crafting") == 2 and p.level("crafting") >= int(rec.level), "the player's Crafting is now level 2: leather armour can be made")
	check(w.quests.last_learned.contains("Crafting is now level 2") and w.quests.last_learned.contains("leather armour"), "what was learned is said: %s" % w.quests.last_learned)
	check(w.total_coins() == coins0, "teaching makes no coins")
	# a player who already knows it is not offered it
	w.quests.offers.clear()
	tanner.inv.remove("hide", tanner.inv.count("hide"))
	w.quests.refresh()
	check(w.quests.offer_of(tanner).is_empty(), "a player at level 2 is not offered the lesson")
	check(not p.raise_to("crafting", 2) and p.raise_to("smithing", 3) and p.level("smithing") == 3 and p.xp_into_level("smithing").x == 0, "teaching raises a skill to the start of a level, never down")
	w.dispose()


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
	for l in w.manor_work.lots:            # wheat the manor has on its way (a relief or granary haul) is still held
		n += l.inv.count("wheat")
	for j in w.manor_work.jobs:
		if j.get("load") is Inventory:
			n += (j.load as Inventory).count("wheat")
	n += w.manor_work.yard.count("wheat")
	return n


func test_building_site() -> void:
	var w := new_world()
	var p := w.player
	var pl: Dictionary = w.plots[0]
	p.coins += 100
	w.buy_plot(pl)
	w.start_site(pl)
	check(w.site_progress(pl) == 0.0, "a new site is 0% done")
	p.inv.add("plank", 30)
	p.inv.add("stone", 5)
	w.deliver(pl, p.inv)
	check(absf(w.site_progress(pl) - 35.0 / 60.0) < 0.001, "the progress bar counts delivered loads (%.2f)" % w.site_progress(pl))
	var coins0 := w.total_coins()
	var back := w.cancel_site(pl, p.inv)
	check(back == {"plank": 30, "stone": 5} and p.inv.count("plank") == 30 and p.inv.count("stone") == 5, "giving up a site returns every delivered load")
	check(pl.site.is_empty() and w.owner_of(pl) == World.PLAYER and w.total_coins() == coins0, "the frame comes down; the plot stays the player's; no coin changes")
	# a full pack: what does not fit is left in a bundle at the site
	w.start_site(pl)
	w.deliver(pl, p.inv)
	p.inv.max_stacks = p.inv.items.size()
	p.inv.add("wheat", 1)                     # fills nothing new: the pack has no free slot for planks
	var loot0 := w.loot.size()
	w.cancel_site(pl, p.inv)
	var bundle: Dictionary = w.loot.back() if w.loot.size() > loot0 else {}
	check(not bundle.is_empty() and int(bundle.inv.count("plank")) + p.inv.count("plank") == 30 and int(bundle.inv.count("stone")) + p.inv.count("stone") == 5, "with no room in the pack, the rest waits in a bundle at the site")
	p.inv.max_stacks = 0
	# a site from a save made before sites kept their cost still shows its progress and refunds
	w.start_site(pl)
	pl.site.erase("cost")
	pl.site.need = {"plank": 10, "stone": 20, "log": 10}
	check(absf(w.site_progress(pl) - 20.0 / 60.0) < 0.001 and w.site_delivered(pl) == {"plank": 20}, "older sites assume the house cost")


## Interiors (owner decision: roof fade, one entry mechanic for all): every roofed building has an
## inside entered only through its doors, walls solid and floor walkable; villagers walk in and sleep in
## their own beds; witnesses see only what happens in the same place; old saves move the people who
## were "hidden" at home inside; a house the player builds gets the same interior.
func test_interiors() -> void:
	var w := new_world()
	var m := w.map
	# every enterable building has an inside, and every home a sleeping place for each of its people
	for id in ["b_v1_house", "b_manor", "b2", "b3", "b4", "b5", "b24"]:
		check(w.interiors.has(id) and not (w.interiors[id].floor as Array).is_empty(), "%s has an interior with a floor" % id)
	var short := []
	for hh in w.households:
		var beds := {}
		for mid in hh.members:
			var s := w.home_spot(w.npc(int(mid)), "bed")
			if not s.is_empty():
				beds[str(s.at)] = true
		if beds.size() < (hh.members as Array).size():
			short.append("%s (%d people, %d places)" % [hh.home, hh.members.size(), beds.size()])
	check(short.is_empty(), "every villager has a bed or pallet of their own at home %s" % [short])
	var houses := 0
	for id in w.interiors:
		if w.buildings[id].type == "house" and (w.interiors[id].spots as Array).filter(func(s): return s.kind == "bed" and int(s.tile) != 593).size() >= 5:
			houses += 1
	check(houses == 21, "all 21 houses have five beds (%d)" % houses)
	# walls block, the floor is walkable, and the inside is reached only through a door
	var leaks := []
	for id in w.interiors:
		var it: Dictionary = w.interiors[id]
		var doors := {}
		for c in it.doors:
			doors[Vector2i(int(c[0]), int(c[1]))] = true
		for c in it.floor:
			var cell := Vector2i(int(c[0]), int(c[1]))
			if m.is_solid(cell):
				leaks.append("%s floor %s solid" % [id, cell])
			if doors.has(cell):
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n: Vector2i = cell + d
				if w.place_of(Vector2(n)) != id and not m.is_solid(n):
					leaks.append("%s %s -> %s" % [id, cell, n])
	check(leaks.is_empty(), "walls enclose every inside; only doors lead out %s" % [leaks.slice(0, 6)])
	var b5: Dictionary = w.buildings["b5"]
	check(m.is_solid(Vector2i(int(b5.x), int(b5.y) + 4)) and m.is_solid(Vector2i(int(b5.x) + 3, int(b5.y) + 1)), "a house's side and back walls are solid")
	var step := w.building_door("b5")
	var walker: NPC = null
	for n: NPC in w.npcs:
		if n.home == "b5" and n.role == "adult":
			walker = n
			break
	var bed := w.home_cell(walker, "bed")
	var path := m.find_path(step, bed)
	var through := ""
	for i in range(1, path.size()):
		var a := w.place_of(path[i - 1] + Vector2(0.5, 0.5))
		var b := w.place_of(path[i] + Vector2(0.5, 0.5))
		if a == "" and b == "b5":
			through = str(Vector2i(path[i]))
	check(not path.is_empty() and through == str(Vector2i(int(w.interiors["b5"].doors[0][0]), int(w.interiors["b5"].doors[0][1]))), "the way from the door step to a bed goes in through the door (%s)" % through)
	# a villager goes home at night and sleeps in their bed, inside (not hidden, not on the step)
	w.minutes = floorf(w.minutes / World.DAY) * World.DAY + 21.6 * 60.0
	w.last_hour = int(w.minutes / 60.0)
	walker.pos = Vector2(step) + Vector2(0.5, 1.5)
	walker.plan.clear()
	walker.target = -1
	walker.hunger = 100.0
	w.player.pos = Vector2(step) + Vector2(0.5, 3.5)
	var slept := false
	for i in 400:
		walker.hunger = 100.0
		w._update_npc(walker, 0.1)
		if w.asleep(walker):
			slept = true
			break
	check(slept and w.place_of(walker.pos) == "b5" and walker.cell() == bed, "%s walks in and lies down in bed (%s, %s)" % [walker.name, walker.doing, walker.cell()])
	check(not w.near(w.player.pos, 30.0).has(walker), "asleep indoors, they see nothing outside")
	# witnesses: those inside a building see only what happens in it, and those outside only outside
	var crate: Dictionary = {}
	for c in w.containers:
		if c.at == "b5" and w.place_of(Vector2(int(c.x), int(c.y))) == "b5":
			crate = c
	check(not crate.is_empty(), "a household crate stands inside house b5")
	for n: NPC in w.npcs:
		if n.alive and n.pos.distance_to(Vector2(step)) < 20.0:
			n.pos = FAR_PEOPLE
			n.plan = [w.brain.work(600, "", {}, "idle")]
	var inside_eye: NPC = null
	var outside_eye: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard" and n.home != "b5" and n.household >= 0:
			if inside_eye == null:
				inside_eye = n
			elif outside_eye == null:
				outside_eye = n
	var floor0: Array = w.interiors["b5"].floor
	inside_eye.pos = Vector2(int(floor0[0][0]), int(floor0[0][1])) + Vector2(0.5, 0.5)
	outside_eye.pos = Vector2(step) + Vector2(1.5, 0.5)
	for n in [inside_eye, outside_eye]:
		n.plan = [w.brain.work(600, "", {}, "idle")]
		n.anim = "idle"
	w.player.pos = Vector2(w.home_cell(walker, "chest")) + Vector2(0.5, 0.5)
	var crimes0 := w.player.crimes.size()
	w.player_take(crate)
	check(w.player.crimes.size() == crimes0 + 1 and int(w.player.crimes[-1].witnesses) == 1, "a theft inside a house is seen by the one awake inside, not by the one at the door or the sleeper")
	check(inside_eye.memory.any(func(t): return str(t).begins_with("saw ")) and not outside_eye.memory.any(func(t): return str(t).begins_with("saw ")), "%s inside saw it; %s outside did not" % [inside_eye.name, outside_eye.name])
	var barrel: Dictionary = {}
	for c in w.containers:
		if c.at == "b5" and w.place_of(Vector2(int(c.x), int(c.y))) == "" and w.container_pick(c) != "":
			barrel = c
	w.player.pos = Vector2(int(barrel.x), int(barrel.y)) + Vector2(0.5, 1.5)
	outside_eye.pos = w.player.pos + Vector2(1.0, 0)
	w.player_take(barrel)
	check(int(w.player.crimes[-1].witnesses) == 1 and outside_eye.memory.filter(func(t): return str(t).begins_with("saw ")).size() == 1, "outside, the one outside sees it and the one inside does not")
	# an old save: villagers "hidden" at home stood on the door step; they load inside, in bed
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	d.save_version = 3
	var moved := 0
	for nd in d.npcs:
		if nd.home == "b5" and bool(nd.alive):
			nd.hidden = true
			nd.pos = [step.x + 0.5, step.y + 0.5]
			moved += 1
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var ok := true
	for n: NPC in w2.npcs:
		if n.home == "b5" and n.alive:
			ok = ok and w2.place_of(n.pos) == "b5" and n.cell() == w2.home_cell(n, "bed")
	check(moved > 0 and ok, "a version 3 save's %d people hidden at home load inside, each at their own bed" % moved)
	var d2: Dictionary = w2.to_dict()
	check(int(d2.save_version) == World.SAVE_VERSION and not JSON.stringify(d2.npcs).contains("\"hidden\""), "saves are the current version and hold where people are, not \"hidden\"")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d2)))
	check(w3.npc(walker.id).pos == w2.npc(walker.id).pos and w3.place_of(w3.npc(walker.id).pos) == "b5", "a villager inside a house is still there after saving and loading")
	# a house the player builds gets the stamp's interior: walkable floor, solid walls, beds, a roof
	var p := w.player
	var pl: Dictionary = w.plots[0]
	p.coins += int(pl.price)
	w.buy_plot(pl)
	w.start_site(pl)
	var cost: Dictionary = GameData.b("house_cost")
	for id in cost:
		p.inv.add(id, int(cost[id]))
	check(w.deliver(pl, p.inv), "the player's house is finished")
	var hid := "house_" + str(pl.id)
	var hi: Dictionary = w.interiors.get(hid, {})
	check(not hi.is_empty() and hi.floor.size() == w.interiors["b5"].floor.size() and hi.spots.size() == w.interiors["b5"].spots.size(), "the built house has the same interior as Shade's house")
	var f0 := Vector2i(int(hi.floor[0][0]), int(hi.floor[0][1]))
	check(not m.is_solid(f0) and w.place_of(Vector2(f0) + Vector2(0.5, 0.5)) == hid and w.roof_over(Vector2(f0) + Vector2(0.5, 0.5)) == hid, "its floor is walkable, inside it and under its roof")
	check(m.is_solid(Vector2i(int(pl.x), int(pl.y) + 4)) and not m.is_solid(Vector2i(int(pl.door[0]), int(pl.door[1]) - 1)), "its walls are solid and its doorway open")
	var w4 := World.new()
	var m4 := VillageMap.load_default()
	w4.load_dict(m4, JSON.parse_string(JSON.stringify(w.to_dict())))
	check(not m4.is_solid(f0) and m4.is_solid(Vector2i(int(pl.x), int(pl.y) + 4)) and w4.place_of(Vector2(f0) + Vector2(0.5, 0.5)) == hid, "after loading, the built house's inside is the same")


## Every item in the village, wherever it is (people, pantries, tables, the granary, the player's
## pack and chest, bags on the ground): id -> count.
func _all_goods(w: World) -> Dictionary:
	var out := {}
	var add := func(inv: Inventory) -> void:
		for id in inv.items:
			out[id] = int(out.get(id, 0)) + int(inv.items[id])
	for n: NPC in w.npcs:
		add.call(n.inv)
	for hh in w.households:
		add.call(hh.pantry)
	for c in w.containers:
		if c.kind == "table":
			add.call(c.inv)
	add.call(w.granary)
	add.call(w.player.inv)
	add.call(w.player.chest)
	for l in w.loot:
		add.call(l.inv)
	# materials delivered to unfinished building sites and carried by hired helpers are still goods
	# held (the audit: site materials count in the goods-conservation test)
	for src in [w.site_goods(), w.construction.carried(), w.manor_work.goods()]:
		for id in src:
			out[id] = int(out.get(id, 0)) + int(src[id])
	return out


## Goods held plus what finished buildings used up: constant while goods only move, are delivered,
## carried, returned or built with.
func _ledger(w: World, ids: Array) -> Dictionary:
	var held := _all_goods(w)
	var out := {}
	for id in ids:
		out[id] = int(held.get(id, 0)) + int(w.stats.get("used_building_" + id, 0))
	return out


## Theft, shops and containers (owner rules, 2026-10-18): the tavern's tables hold food its keepers
## set out, crates and barrels are their owners' stock, taking from them is theft that witnesses
## remember and guards punish, stolen goods are marked and known to their owners, pockets can be
## picked. Goods and coins only move.
func test_theft_and_shops() -> void:
	var w := new_world()
	var p := w.player
	var kinds := {}
	for c in w.containers:
		kinds[c.kind] = int(kinds.get(c.kind, 0)) + 1
	check(int(kinds.get("table", 0)) > 0 and int(kinds.get("crate", 0)) > 0 and int(kinds.get("barrel", 0)) > 0, "the map has tables, crates and barrels (%s)" % kinds)
	var tables := w.containers.filter(func(c): return c.kind == "table" and c.inv.total() > 0)
	check(tables.size() > 0, "the keepers set food out on the tavern's tables when it opens (%d tables)" % tables.size())
	var goods0 := _all_goods(w)
	var coins0 := w.total_coins()
	# closing clears the tables back to the keepers; opening sets them again; nothing made or lost
	var m0 := w.minutes
	w.minutes = 22.5 * 60.0
	w.serve_tables()
	check(w.containers.all(func(c): return c.kind != "table" or c.inv.total() == 0), "at closing the tables are cleared")
	check(_all_goods(w) == goods0, "clearing the tables puts the food back in the keepers' stock")
	w.minutes = m0
	w.serve_tables()
	check(_all_goods(w) == goods0 and w.containers.any(func(c): return c.kind == "table" and c.inv.total() > 0), "the tables are set again from the keepers' stock")
	# everyone far away: nobody sees
	var away := func() -> void:
		for n: NPC in w.npcs:
			n.pos = FAR_GUARDS if n.job == "guard" else FAR_PEOPLE
			n.plan.clear()
			n.target = -1
	away.call()
	var t: Dictionary = w.containers.filter(func(c): return c.kind == "table" and c.inv.total() > 0)[0]
	p.pos = Vector2(int(t.x) + 0.5, int(t.y) + 1.5)
	var keeper: NPC = w.container_owner(t)
	var dish: String = w.container_pick(t)
	var crimes0 := p.crimes.size()
	check(w.player_take(t) == dish and p.inv.has(dish) and t.inv.total() == 0, "the player takes the %s from a table" % dish)
	check(p.stolen_count(dish) == 1 and p.stolen[dish].has(str(keeper.id)), "the dish is marked as stolen from %s" % keeper.name)
	check(p.crimes.size() == crimes0 + 1 and p.crimes[-1].kind == "theft" and int(p.crimes[-1].victim) == keeper.id and int(p.crimes[-1].witnesses) == 0, "taking from the tavern's table is theft from its keeper, unseen")
	check(keeper.memory.any(func(m): return str(m).begins_with("found %s from a table" % GameData.item_name(dish).to_lower())), "the keeper finds the dish missing")
	check(_all_goods(w) == goods0 and w.total_coins() == coins0, "theft moves goods: nothing made or lost")
	# a villager who sees it remembers
	var adult: NPC = null
	var guard: NPC = null
	for n: NPC in w.npcs:
		if adult == null and n.role == "adult" and n.job != "guard" and n.job != "tavernkeeper":
			adult = n
		if guard == null and n.job == "guard":
			guard = n
	var crate: Dictionary = {}
	for c in w.containers:
		if c.kind == "crate" and w.buildings.has(c.at) and w.buildings[c.at].type == "tavern" and w.container_pick(c) != "":
			crate = c
			break
	check(not crate.is_empty() and w.container_store(crate) == w.tavern_keeper().inv, "a tavern crate holds the tavern keeper's stock")
	p.pos = Vector2(int(crate.x) + 0.5, int(crate.y) + 1.5)
	adult.pos = p.pos + Vector2(2, 0)
	var item: String = w.container_pick(crate)
	var held := w.tavern_keeper().inv.count(item)
	check(w.player_take(crate) == item and w.tavern_keeper().inv.count(item) == held - 1, "taking from the crate takes from the keeper's stock")
	check(adult.memory.has("saw %s %s take %s from the tavern's stores" % [p.name, p.family, GameData.item_name(item).to_lower()]) and int(p.crimes[-1].witnesses) == 1, "a villager who saw it remembers it")
	check(_all_goods(w) == goods0, "still nothing made or lost")
	# a guard who sees it stops the player: the goods go back and the fine goes to the treasury
	adult.pos = FAR_PEOPLE
	guard.pos = p.pos + Vector2(2, 0)          # beside the player, inside the tavern with them
	p.coins = 40
	coins0 = w.total_coins()
	var t0 := w.treasury
	var inv0 := p.inv.count(item)
	held = w.tavern_keeper().inv.count(item)
	w.player_take(crate)
	var fine := World.theft_fine_for({item: 1})            # Build 13: the base fine plus a share of what it is worth
	check(fine >= int(GameData.b("theft_fine")) and p.crimes[-1].get("value", -1) == GameData.value(item) and int(p.crimes[-1].qty) == 1, "the record counts one %s worth %d" % [item, GameData.value(item)])
	check(p.inv.count(item) == inv0 and w.tavern_keeper().inv.count(item) == held, "the guard gives the %s back to the tavern" % item)
	check(p.coins == 40 - fine and w.treasury == t0 + fine and w.total_coins() == coins0 and guard.target == -1, "the player pays the %d coin fine to the treasury" % fine)
	check(w.last_guard.contains(guard.name), "the guard's words are reported: %s" % w.last_guard)
	p.coins = 3
	w.player_take(crate)
	check(p.coins == 0 and guard.target == -2, "a thief who cannot pay the fine is fought")
	guard.target = -1
	guard.pos = FAR_GUARDS
	check(_all_goods(w) == goods0, "nothing made or lost through the guard")
	# a household's barrel is its pantry
	var barrel: Dictionary = {}
	for c in w.containers:
		if c.kind == "barrel" and w.buildings.has(c.at) and w.buildings[c.at].type == "house" and w.household_in(c.at) >= 0:
			barrel = c
			break
	var hh: Dictionary = w.households[w.household_in(barrel.at)]
	check(w.container_store(barrel) == hh.pantry, "a house's barrel is its household's pantry")
	var pick: String = w.container_pick(barrel)
	var in_pantry: int = hh.pantry.count(pick)
	var owner: NPC = w.container_owner(barrel)
	p.pos = Vector2(int(barrel.x) + 0.5, int(barrel.y) + 1.5)
	check(w.player_take(barrel) == pick and hh.pantry.count(pick) == in_pantry - 1 and owner.household == int(hh.id), "taking from it takes the %s household's %s" % [hh.family, pick])
	check(w.container_whose(barrel) == "the %s household's" % hh.family, "and it is said to be theirs")
	# stolen goods offered back to their owner (or their household): refused
	var stall_id := ""
	var merchant: NPC = null
	for id in w.stalls:
		var m := w.party(w.tenant_of(w.stalls[id]))
		if m and w.stalls[id].kind == "food":
			stall_id = id
			merchant = m
			break
	var stall := {"id": stall_id, "kind": "stall", "x": int(w.stalls[stall_id].x), "y": int(w.stalls[stall_id].y), "at": stall_id}
	p.pos = Vector2(int(stall.x) + 0.5, int(stall.y) + 1.5)
	var ware: String = w.container_pick(stall)
	check(w.player_take(stall) == ware and p.stolen[ware].has(str(merchant.id)), "the %s taken from %s's stall is marked as theirs" % [ware, merchant.name])
	var have := p.inv.count(ware)
	coins0 = w.total_coins()
	var r: Dictionary = w.player_sell(merchant, ware, 1)
	check(r.result == "recognised" and p.inv.count(ware) == have and merchant.memory.any(func(m): return str(m).begins_with("caught %s %s selling me" % [p.name, p.family])), "%s knows their own %s and will not buy it: %s" % [merchant.name, ware, r.text])
	check(p.crimes[-1].kind == "fencing" and w.total_coins() == coins0, "it is recorded; no coins move")
	# sold to someone else it fetches the price; the mark goes with it
	var buyer: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.household != merchant.household and n.coins >= 5 and n.role == "adult" and not n.job in ["guard", "tavernkeeper", "cook"]:
			buyer = n
			break
	var marked := p.stolen_count(ware)
	r = w.player_sell(buyer, ware, 1)
	check(r.result == "sold" and p.inv.count(ware) == have - 1 and p.stolen_count(ware) == marked - 1 and w.total_coins() == coins0, "sold to %s, who cannot know it" % buyer.name)
	# a guard nearby may question the seller: the piece goes back to its owner, with the fine
	p.inv.add(ware)                                # the test gives one more to mark
	p.mark_stolen(ware, merchant.id, 1)
	goods0 = _all_goods(w)
	guard.pos = p.pos + Vector2(2, 0)
	var chance = GameData.balance.guard_question_chance
	GameData.balance.guard_question_chance = 1.0
	p.coins = 40
	coins0 = w.total_coins()
	var whose: Array = p.stolen[ware].keys()
	whose.sort_custom(func(a, b): return int(a) < int(b))
	var rightful: NPC = w.npc(int(whose[0]))           # the piece goes back to the first owner marked
	var mine := rightful.inv.count(ware)
	r = w.player_sell(buyer, ware, 1)
	GameData.balance.guard_question_chance = chance
	check(r.result == "questioned" and rightful.inv.count(ware) == mine + 1 and p.coins == 40 - fine and w.total_coins() == coins0, "a guard questions the seller: the %s goes back to %s (%s)" % [ware, rightful.name, r.text])
	check(_all_goods(w) == goods0, "nothing made or lost by selling stolen goods")
	guard.pos = FAR_GUARDS
	# marks follow the pack: goods eaten or dropped lose theirs
	var food := ""
	for id in p.stolen:
		if GameData.item(id).has("food"):
			food = id
	var before := p.stolen_count(food)
	p.inv.remove(food, p.inv.count(food))
	check(before > 0 and p.stolen_count(food) == 0 and not p.stolen.has(food), "goods no longer carried lose their marks")
	# picking a pocket: success takes a few coins; caught, the victim remembers and a guard comes
	var victim: NPC = buyer
	victim.coins = 20
	p.pos = victim.pos + Vector2(1, 0)
	coins0 = w.total_coins()
	var pc0 := p.coins
	var saved_pp: Array = [GameData.b("pickpocket_chance"), GameData.b("pickpocket_chance_per_level"), GameData.b("pickpocket_chance_max")]
	GameData.balance.pickpocket_chance = 1.0
	GameData.balance.pickpocket_chance_max = 1.0
	r = w.pickpocket(victim)
	check(r.ok and p.coins > pc0 and victim.coins == 20 - (p.coins - pc0) and w.total_coins() == coins0, "a picked pocket gives up %d coins: %s" % [p.coins - pc0, r.text])
	check(victim.memory.any(func(m): return str(m).begins_with("found ")) and p.crimes[-1].kind == "pickpocket", "the victim finds the coins missing; it is on the record")
	victim.coins = 0
	victim.inv.add("leather", 1)
	goods0 = _all_goods(w)
	var vinv := victim.inv.total()
	r = w.pickpocket(victim)
	check(r.ok and victim.inv.total() == vinv - 1 and p.stolen.keys().any(func(id): return p.stolen[id].has(str(victim.id))) and _all_goods(w) == goods0, "with no coins, one thing they carry is taken, marked as theirs: %s" % r.text)
	GameData.balance.pickpocket_chance = 0.0
	GameData.balance.pickpocket_chance_per_level = 0.0
	guard.pos = victim.pos + Vector2(6, 0)
	p.coins = 40
	coins0 = w.total_coins()
	r = w.pickpocket(victim)
	GameData.balance.pickpocket_chance = saved_pp[0]
	GameData.balance.pickpocket_chance_max = saved_pp[2]
	GameData.balance.pickpocket_chance_per_level = saved_pp[1]
	check(not r.ok and victim.memory.has("caught %s %s picking my pocket" % [p.name, p.family]), "a failed try is noticed: %s" % r.text)
	check(p.coins == 40 - int(GameData.b("theft_fine")) and w.total_coins() == coins0 and guard.memory.any(func(m): return str(m).begins_with("caught ")), "the guard stops the pickpocket and fines them (a failed try takes nothing: the base fine)")
	check(Dialogue.caught(w, victim) and (Dialogue.opening(w, victim).contains("caught") or Dialogue.opening(w, victim).contains("saw you")), "the victim is cold to the thief: %s" % Dialogue.opening(w, victim))
	# saved: the tables' dishes and the stolen marks
	p.inv.add("ale", 2)
	p.mark_stolen("ale", keeper.id, 2)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var same := true
	for c in w.containers:
		if c.kind == "table" and w2.container(c.id).inv.items != c.inv.items:
			same = false
	check(same and _all_goods(w2) == _all_goods(w), "the tables' dishes are saved")
	check(w2.player.stolen == p.stolen and w2.player.stolen_count("ale") == p.stolen_count("ale") and p.stolen_count("ale") >= 2, "the stolen marks are saved (%s)" % w2.player.stolen)
	# a save from before containers: the food was all in the keepers' hands; the tables are set from it
	w.minutes = 22.5 * 60.0
	w.serve_tables()
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	old.erase("containers")
	old.player.erase("stolen")
	old.minutes = m0
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.containers.size() == w.containers.size() and w3.containers.any(func(c): return c.kind == "table" and c.inv.total() > 0), "an older save loads with its containers, the tables set from the keepers' stock")
	check(_all_goods(w3) == _all_goods(w) and w3.player.stolen.is_empty(), "nothing made or lost loading it; nothing marked stolen")
	w.dispose()
	w2.dispose()
	w3.dispose()


func test_chest_keeps_marks() -> void:
	var w := new_world()
	var p := w.player
	p.inv.add("pottage", 3)
	p.mark_stolen("pottage", 7, 2)
	w.transfer(p.inv, p.chest, "pottage", 3)
	p.store_marks("pottage")
	check(p.stolen_count("pottage") == 0 and int(p.chest_stolen.pottage["7"]) == 2, "stolen goods put in the home chest keep their marks there")
	var d: Dictionary = JSON.parse_string(JSON.stringify(p.to_dict()))
	var q := PlayerState.from_dict(d)
	check(int(q.chest_stolen.pottage["7"]) == 2, "the chest's marks are saved")
	w.transfer(p.chest, p.inv, "pottage", 3)
	p.take_marks("pottage")
	check(p.stolen_count("pottage") == 2 and p.chest_stolen.is_empty(), "taken out again, they are still stolen")


func test_beds() -> void:
	# owner rule: villagers with homes sleep in their own beds; guards and cooks may take the pallets
	var w := new_world()
	var misplaced := []
	for hh in w.households:
		var beds := 0
		for sp in w.interiors.get(hh.home, {}).get("spots", []):
			if sp.kind == "bed" and int(sp.get("tile", 0)) % 100000 != 593:
				beds += 1
		var family := 0
		for id in hh.members:
			var n: NPC = w.npc(int(id))
			if n != null and not n.job in World.LODGERS:
				family += 1
		for id in hh.members:
			var n: NPC = w.npc(int(id))
			var spot := w.home_spot(n, "bed")
			var pallet := not spot.is_empty() and int(spot.get("tile", 0)) % 100000 == 593
			if pallet and not n.job in World.LODGERS and family <= beds:
				misplaced.append("%s (%s)" % [n.name, hh.home])
	check(misplaced.is_empty(), "every family member has a bed where the home has enough %s" % [misplaced])
	var b_manor := 0
	for sp in w.interiors["b_manor"].spots:
		if sp.kind == "bed" and int(sp.get("tile", 0)) % 100000 != 593:
			b_manor += 1
	check(b_manor == 4, "the manor has four beds (two added for the reeve's family)")
	# a save made before those beds, with someone standing where one now is, loads them beside it
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	d.npcs[0].pos = [20.5, 40.5]
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var moved: NPC = w2.npc(int(d.npcs[0].id))
	check(not w2.map.is_solid(moved.cell()) and moved.pos.distance_to(Vector2(20.5, 40.5)) < 4.0, "someone saved where a bed now stands steps beside it on load")

## Set the clock to `h` o'clock on the current day (the hour's business is not run again).
func _at_hour(w: World, h: float) -> void:
	w.minutes = float(w.day()) * World.DAY + h * 60.0
	w.last_hour = int(w.minutes / 60.0)


## Run the world for `mins` game minutes, or until `done` returns true.
func _run_until(w: World, mins: int, done: Callable) -> bool:
	var steps := int(mins / (float(GameData.b("game_minutes_per_second")) * 0.5))
	for i in steps:
		w.update(0.5)
		if done.call():
			return true
	return done.call()


## Ground for a building of this kind at `at` in the forests: its trees felled, as a builder would
## (the stumps are grubbed up when the ground is claimed).
## The first free place in the woods (scanning from the north-west) where a building of `kind` is refused only
## because a mature tree stands on it, clear of `skip`: the village no longer has its trees at fixed places.
func _wood_spot(w: World, kind: String, skip := Rect2i()) -> Vector2i:
	var fp: Vector2i = w.construction.footprint(kind)
	for y in range(1, 30):
		for x in range(1, 100):
			var r := Rect2i(Vector2i(x, y), fp)
			if skip.intersects(r):
				continue
			if w.construction.can_place(kind, r, World.PLAYER).contains("fell it first"):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _cleared(w: World, kind: String, at: Vector2i) -> Rect2i:
	var r := Rect2i(at, w.construction.footprint(kind))
	for t in w.trees:
		if t.state == "grown" and (r.has_point(Vector2i(int(t.x), int(t.y))) or Vector2i(int(t.x), int(t.y)) == w.construction.door_step(kind, r)):
			w.fell(t, 0)
	return r


## Give the player a house of their own (bought and built on plot0), their home, so workshops may follow.
func _player_house(w: World) -> Dictionary:
	var pl: Dictionary = w.plots[0]
	w.player.coins += 100
	w.property.buy(pl, World.PLAYER)
	w.start_site(pl)
	for id in GameData.b("house_cost"):
		w.player.inv.add(id, int(GameData.b("house_cost")[id]))
	w.deliver(pl, w.player.inv)
	return w.buildings["house_" + str(pl.id)]


## Property phase 2, construction (owner rules 2026-10-18): free placement anywhere legal with the
## ground bought or leased on the spot, generic construction any deliverer can feed with the owner
## keeping the building, readable names, the house-first rule and workshops with stations, interiors,
## permission and reservations. Coins and goods only move.
func test_construction() -> void:
	var w := new_world()
	var c := w.construction
	var p := w.player
	var coins := func() -> int: return w.total_coins() - w.coin_sources
	# placement legality
	var home := w.building_door("b5")
	var b5: Dictionary = w.buildings["b5"]
	check(c.can_place("house", Rect2i(int(b5.x) + 2, int(b5.y) + 2, 9, 10), World.PLAYER).begins_with("a building"), "a house cannot go over another building")
	var rc: Array = w.map.data.road[40]
	check(c.can_place("house", Rect2i(int(rc[0]) - 4, int(rc[1]) - 5, 9, 10), World.PLAYER) != "", "nor across the road")
	check(c.can_place("house", Rect2i(-3, 4, 9, 10), World.PLAYER) == "outside the village", "nor outside the village")
	check(c.can_place("smithy", Rect2i(60, 60, 9, 10), World.PLAYER).begins_with("A house comes first"), "a workshop needs a house first (owner rule)")
	check(c.can_place("house", Rect2i(60, 60, 5, 5), World.PLAYER).contains("needs 9x10"), "the footprint is the building's")
	var rect := c.find_ground("house", home, World.PLAYER)
	check(rect.size == Vector2i(9, 10) and c.can_place("house", rect, World.PLAYER) == "", "legal ground is found near a house (%s)" % rect)
	var step := c.door_step("house", rect)
	check(not w.map.is_solid(step) and not w.map.find_path(step, home).is_empty(), "its door step is clear and reachable")
	# buy on placement: the ground is surveyed, bought (the price to the treasury) and the site marked out
	p.coins = 500
	var c0: int = coins.call()
	var t0 := w.treasury
	var price: int = c.ground_terms(rect).price
	var site := c.place("house", rect, World.PLAYER)
	check(not site.is_empty() and w.owner_of(site) == World.PLAYER and w.treasury == t0 + price and p.coins == 500 - price and str(site.site.kind) == "house"
			and str(site.site.owner) == World.PLAYER and w.site_progress(site) == 0.0, "placing a house buys the ground (%d coins) and marks out the frame in one go" % price)
	check(c.place("house", rect, World.PLAYER).is_empty() and c.why.begins_with("surveyed land"), "the same ground cannot be built on twice (%s)" % c.why)
	# lease on placement
	var spot := _wood_spot(w, "house")
	check(spot.x >= 0 and c.can_place("house", Rect2i(spot, Vector2i(9, 10)), World.PLAYER).contains("fell it first"), "a grown tree must be felled first")
	var rect2 := _cleared(w, "house", spot)
	check(c.can_place("house", rect2, World.PLAYER) == "", "felled, its stump does not stand in the way")
	var rent: int = c.ground_terms(rect2).rent
	var leased := c.place("house", rect2, World.PLAYER, true)
	check(not leased.is_empty() and w.tenant_of(leased) == World.PLAYER and w.owner_of(leased) == World.MANOR and int(leased.rent) == rent and str(leased.site.owner) == World.PLAYER,
			"placing on leased ground: the first week's rent (%d) is paid and the site is the tenant's" % rent)
	check(coins.call() == c0, "no coin made or lost by placing")
	check(w.trees.filter(func(t): return rect2.has_point(Vector2i(int(t.x), int(t.y)))).all(func(t): return t.state == "cleared"), "the stumps on claimed ground are grubbed up for good")
	# readable names: no internal ids anywhere the player reads them
	var names: Array = w.property.heads().map(func(r): return w.property.describe(r))
	var raw := names.filter(func(nm): return str(nm).contains("plot") or str(nm).contains("parcel") or str(nm).contains("(b") or str(nm).contains("b7"))
	check(raw.is_empty(), "places are named without internal ids (%s)" % [raw])
	check(w.property.describe(w.plots[0]) != w.property.describe(w.plots[1]) and w.property.describe(w.plots[0]).begins_with("the clearing "), "the two clearings have names of their own: %s / %s" % [w.property.describe(w.plots[0]), w.property.describe(w.plots[1])])
	check(w.property.describe(site).begins_with("the %s family's building site for a house" % p.family), "a site is named for its family: %s" % w.property.describe(site))
	check(w.property.describe(w.buildings["b5"]).begins_with("the %s family's house" % w.households[w.household_in("b5")].family), "a house is named for the family living there: %s" % w.property.describe(w.buildings["b5"]))
	# generic construction: anyone may deliver; the site's owner keeps the building
	var ids := ["plank", "stone", "log", "iron_bar"]
	var ledger0 := _ledger(w, ids)
	var carrier: NPC = w.npcs[30]
	for id in GameData.b("house_cost"):
		carrier.inv.add(id, int(GameData.b("house_cost")[id]))
	var ledger1 := _ledger(w, ids)
	var part := Inventory.new()
	part.add("plank", 10)
	carrier.inv.remove("plank", 10)
	w.deliver(site, part, World.npc_ref(carrier.id))
	check(_ledger(w, ids) == ledger1 and int(w.site_goods().get("plank", 0)) == 10, "delivered materials stay counted on the site (goods ledger)")
	check(w.deliver(site, carrier.inv, World.npc_ref(carrier.id)), "a villager who is not the owner finishes the site")
	var hid := "house_" + str(site.id)
	check(w.buildings.has(hid) and w.owner_of(w.buildings[hid]) == World.PLAYER and str(w.buildings[hid].parcel) == str(site.id), "the house is the site owner's, not the deliverer's")
	check(w.interiors.has(hid) and w.map.is_solid(Vector2i(rect.position.x, rect.position.y)) and not w.map.is_solid(Vector2i(int(site.door[0]), int(site.door[1]))), "it has an interior, walls and an open door")
	check(_ledger(w, ids) == ledger1, "its materials are used up in it, counted in the ledger")
	# a workshop after a house: stamps, stations, interior, roof; the owner's to use, others with leave
	check(c.may_build("smithy", World.PLAYER) == "", "owning a house, the player may build a workshop")
	var wr := _cleared(w, "smithy", _wood_spot(w, "smithy", rect2))
	var ws := c.place("smithy", wr, World.PLAYER)
	check(not ws.is_empty() and str(ws.site.kind) == "smithy" and ws.site.cost == GameData.b("workshop_cost").smithy, "a smithy is marked out with its own cost")
	var wcost: Dictionary = GameData.b("workshop_cost").smithy
	var bag := Inventory.new()
	for id in wcost:
		bag.add(id, int(wcost[id]))
	w.deliver(ws, bag, World.PLAYER)
	var wid := "workshop_" + str(ws.id)
	var wb: Dictionary = w.buildings.get(wid, {})
	var forge := "ws_%s_forge" % wid
	var anvil := "ws_%s_anvil" % wid
	check(str(wb.get("type", "")) == "workshop" and w.stations.has(forge) and w.stations.has(anvil) and w.owner_of(w.stations[forge]) == World.PLAYER, "the finished smithy has a forge and an anvil, the player's")
	var wi: Dictionary = w.interiors.get(wid, {})
	check(not wi.is_empty() and not (wi.roof as Array).is_empty() and (wi.floor as Array).has(w.stations[forge].use) and w.place_of(Vector2(w.station_use(forge)) + Vector2(0.5, 0.5)) == wid,
			"it has an interior with a roof, and its stations are used from its floor")
	check(w.map.is_solid(Vector2i(int(w.stations[forge].at[0]), int(w.stations[forge].at[1]))), "the forge itself is solid")
	check(w.stations_of("forge").back() == forge, "the village's own forge comes first for villagers")
	var smith: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "smith":
			smith = o
			break
	check(w.may_use(World.PLAYER, w.stations[forge]) and w.station_refusal(forge) == "" and not w.npc_may_use(smith, w.stations[forge]), "the player works their own forge; a villager may not without leave")
	w.permit(wb, "all", true)
	check(w.npc_may_use(smith, w.stations[forge]), "given leave, a villager may")
	w.permit(wb, "all", false)
	# a smith whose own forge is taken does not take the player's
	var s4: Dictionary = w.stations["s4"]
	var other: NPC = w.npcs[0]
	s4.users[other.id] = w.minutes + 500.0
	other.plan = [w.brain.work(60, "craft", {"recipe": "smelt_iron", "station": "s4"})]
	check(w.brain._station_for(smith, "forge") == "", "with the village's forge reserved, a smith does not use the player's without leave")
	# reservations (audit defect 3): the player waits for a villager working at a station they do not hold
	check(w.station_refusal("s4") == "", "a villager only on the way (not at the forge) does not block the player (PL2-001)")
	other.pos = Vector2(w.station_use("s4")) + Vector2(0.5, 0.5)
	other.anim = "work"
	other.target = -1
	check(w.station_refusal("s4").contains("is using the forge"), "the player respects a villager at work at a station: %s" % w.station_refusal("s4"))
	other.plan.clear()
	check(w.station_refusal("s4") == "" and not s4.users.has(other.id), "a reservation whose villager has gone to other work lapses")
	w.reserve_for_player("s4", 30.0)
	check(w.brain._station_for(smith, "forge") == "", "while the player works the forge, the smith waits (or goes elsewhere)")
	s4.player_until = -1.0
	check(w.brain._station_for(smith, "forge") == "s4", "and uses it afterwards")
	# someone else's workshop: the player needs leave
	wb.owner = "hh:5"
	check(w.station_refusal(forge).contains("you need leave"), "a workshop that is not the player's needs leave: %s" % w.station_refusal(forge))
	wb.owner = World.PLAYER
	check(coins.call() == c0, "every coin kept through construction")
	w.dispose()


## Hired helpers (owner rule: hired for coin, they carry the owner's goods; the owner keeps the
## building): the wage from the employer's purse, the goods from the family chest, or bought at the
## market with the employer's coins, carried in real movement and delivered through World.deliver.
func test_helpers() -> void:
	var w := new_world()
	var c := w.construction
	var p := w.player
	var coins := func() -> int: return w.total_coins() - w.coin_sources
	var house := _player_house(w)
	p.home = str(house.id)
	p.coins = 400
	var rect := _cleared(w, "smithy", Vector2i(80, 15))
	var site := c.place("smithy", rect, World.PLAYER)
	var cost: Dictionary = site.site.cost
	for id in cost:
		p.chest.add(id, int(cost[id]))
	var helper: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job in ["miner", "laborer", "woodcutter"] and o.household >= 0:
			helper = o
			break
	helper.job = ""
	helper.workplace = ""
	_at_hour(w, 7.5)
	var c0: int = coins.call()
	var ids := ["plank", "stone", "log", "iron_bar"]
	# the employer's goods: the chest, what the helper carries, the site, the building
	var own := func() -> Dictionary:
		var out := {}
		var on_site := w.site_goods()
		var held := c.carried()
		for id in ids:
			out[id] = p.chest.count(id) + int(on_site.get(id, 0)) + int(held.get(id, 0)) + int(w.stats.get("used_building_" + id, 0))
		return out
	var ledger0: Dictionary = own.call()
	var hc0 := helper.coins
	var pc0 := p.coins
	check(c.hire(World.PLAYER, helper, site, 0) == "" and helper.coins == hc0 + int(GameData.b("helper_wage")) and p.coins == pc0 - int(GameData.b("helper_wage")),
			"the player hires %s for a day's wage (%d coins, from the player's purse)" % [helper.name, int(GameData.b("helper_wage"))])
	check(c.hire(World.PLAYER, helper, site, 0) != "", "nobody is hired twice in a day")
	var start := helper.pos
	var near := {"chest": 1e9, "site": 1e9}
	var done := _run_until(w, 600, func() -> bool:
		near.chest = minf(near.chest, helper.pos.distance_to(Vector2(w.building_door(p.home)) + Vector2(0.5, 0.5)))
		near.site = minf(near.site, helper.pos.distance_to(Vector2(int(site.door[0]), int(site.door[1])) + Vector2(0.5, 0.5)))
		return site.site.get("done", false))
	var visited_chest: bool = near.chest < 1.5
	var visited_site: bool = near.site < 1.5
	check(done and w.buildings.has("workshop_" + str(site.id)) and w.owner_of(w.buildings["workshop_" + str(site.id)]) == World.PLAYER,
			"the helper carries everything from the chest and the smithy stands, the player's")
	check(visited_chest and visited_site, "the helper really walked to the chest and to the site (came within %.1f and %.1f tiles; started %.0f tiles from the chest)" % [near.chest, near.site, start.distance_to(Vector2(w.building_door(p.home)))])
	check(cost.keys().all(func(id): return p.chest.count(id) == 0), "the materials came from the family chest")
	check(c.contract_of(helper).is_empty() and helper.memory.any(func(m): return str(m).begins_with("carried for")), "the contract ends with the building")
	check(own.call() == ledger0 and coins.call() == c0, "goods and coins kept: the materials are in the building, the wage in the helper's purse")
	# buying at the market with the employer's coins: nothing in the chest, a budget
	var rect2 := _cleared(w, "carpentry", _wood_spot(w, "carpentry"))
	var site2 := c.place("carpentry", rect2, World.PLAYER)
	var helper2: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != helper and o.job in ["miner", "laborer", "woodcutter"] and o.household >= 0:
			helper2 = o
			break
	helper2.job = "laborer"
	# sellers with stock
	for o: NPC in w.npcs:
		if o.alive and o.job == "carpenter":
			o.inv.add("plank", 20)
		if o.alive and w.brain.buy_role(o) == "merchant_raw":
			o.inv.add("stone", 20)
			o.inv.add("log", 20)
	w.minutes += World.DAY
	_at_hour(w, 7.2)
	p.coins = 300
	c0 = coins.call()
	ledger0 = own.call()
	var budget := 120
	check(c.hire(World.PLAYER, helper2, site2, budget) == "", "a helper hired to buy the rest (budget %d)" % budget)
	var pc := p.coins
	_run_until(w, 600, func() -> bool: return site2.site.get("done", false) or int(c.contract_of(helper2).get("spent", 0)) >= budget - 4)
	var spent := pc - p.coins
	var k: Dictionary = c.contract_of(helper2)
	check(spent > 0 and spent <= budget and (k.is_empty() or int(k.spent) == spent), "the helper bought materials with the player's coins, within the budget (%d)" % spent)
	check(w.site_progress(site2) > 0.0, "and carried them to the site (%.0f%%)" % (w.site_progress(site2) * 100.0))
	var bought := {}
	for id in ids:
		bought[id] = int(ledger0[id]) + int(w.stats.get("helper_bought_" + id, 0))
	check(coins.call() == c0 and own.call() == bought, "coins went to the sellers, the goods bought to the site or the helper's arms: nothing made or lost")
	# the day ends: the contract with it; what is still carried goes back to the chest
	w.minutes += World.DAY
	c.daily()
	check(c.contract_of(helper2).is_empty() and own.call() == bought and c.carried().is_empty(), "the next day the contract is over and nothing carried is lost")
	# a save keeps contracts and sites; a dead helper's load goes back
	var helper3 := helper
	_at_hour(w, 8.0)
	c.hire(World.PLAYER, helper3, site2, 0)
	(c.contract_of(helper3).load as Inventory).add("plank", 3)
	p.chest.remove("plank", mini(3, p.chest.count("plank")))
	var text := JSON.stringify(w.to_dict())
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(not w2.construction.contract_of(w2.npc(helper3.id)).is_empty() and (w2.construction.contract_of(w2.npc(helper3.id)).load as Inventory).count("plank") == 3, "a save keeps the day's contract and what the helper carries")
	var again := JSON.stringify(w2.to_dict())
	var w2b := World.new()
	w2b.load_dict(VillageMap.load_default(), JSON.parse_string(again))
	check(JSON.stringify(w2b.to_dict()) == again, "and saves the same again")
	w2b.dispose()
	var chest0 := p.chest.count("plank")
	w.kill(helper3, "fever")
	check(c.contract_of(helper3).is_empty() and p.chest.count("plank") == chest0 + 3, "a helper who dies leaves the employer's goods to the employer")
	w2.dispose()
	w.dispose()


## Crowded households split (owner rule): with more living members than beds and the coins for it, a
## grown member founds a household of the same family, gets an empty house (moving in at once) or
## buys ground and builds a house by the player's rules (hiring help or carrying), and moves in.
func test_households_split() -> void:
	var w := new_world()
	var c := w.construction
	var coins := func() -> int: return w.total_coins() - w.coin_sources
	check(range(w.households.size()).all(func(h): return not c.crowded(h)), "nobody is crowded at the start (the houses have a bed each)")
	# crowd a house: two children of another household come to live there
	var h := w.household_in("b5")
	var hh: Dictionary = w.households[h]
	var from := w.household_in("b10")
	var moved := 0
	for m in (w.households[from].members as Array).duplicate():
		var o: NPC = w.npc(int(m))
		if o.role == "child" and moved < 2:
			(w.households[from].members as Array).erase(o.id)
			(hh.members as Array).append(o.id)
			o.household = h
			o.home = "b5"
			moved += 1
	check(c.crowded(h), "six people in a house with five beds is crowded")
	var rich: NPC = w.party(World.hh_ref(h))
	rich.coins += 600
	var c0: int = coins.call()
	var n0 := w.households.size()
	var founder := c.founder_of(h)
	_at_hour(w, 6.0)
	c.daily()
	check(w.households.size() == n0 + 1, "the crowded household splits")
	var nh: Dictionary = w.households[n0]
	var ref := World.hh_ref(n0)
	check(founder.household == n0 and (nh.members as Array) == [founder.id] and not (hh.members as Array).has(founder.id) and str(nh.family) == str(hh.family),
			"%s founds a household of the same family" % founder.name)
	check(not c.crowded(h), "the old house is no longer crowded")
	var site: Dictionary = w.plot(str(nh.get("build", "")))
	check(not site.is_empty() and w.owner_of(site) == ref and str(site.site.owner) == ref and str(site.site.kind) == "house", "with no empty house for sale, they buy ground and mark out a house")
	check(c.contracts.any(func(k): return str(k.employer) == ref), "and set someone to carry for it")
	check(coins.call() == c0, "coins only moved (the family's gift, the ground to the manor, the wage)")
	var built := _run_until(w, 6 * 1440, func() -> bool: return site.site.get("done", false))
	var hid := "house_" + str(site.id)
	check(built and w.buildings.has(hid) and w.owner_of(w.buildings[hid]) == ref, "the house is built in the days that follow (%s)" % ("done" if built else "%.0f%%" % (w.site_progress(site) * 100.0)))
	check(str(nh.home) == hid and founder.home == hid and w.household_in(hid) == n0, "and the new household moves in")
	check(w.total_coins() == c0 + w.coin_sources, "coins conserved throughout")
	# an empty house: a crowded household moves straight in
	var w2 := new_world()
	var c2 := w2.construction
	var gone := w2.household_in("b7")
	for m in w2.households[gone].members:
		w2.kill(w2.npc(int(m)), "fever")
	var h2 := w2.household_in("b6")
	var hh2: Dictionary = w2.households[h2]
	var src := w2.household_in("b9")
	for m in (w2.households[src].members as Array).duplicate():
		var o: NPC = w2.npc(int(m))
		if o.role != "adult" and (hh2.members as Array).size() <= 5:
			(w2.households[src].members as Array).erase(o.id)
			(hh2.members as Array).append(o.id)
			o.household = h2
			o.home = "b6"
	w2.party(World.hh_ref(h2)).coins += 400
	var n2 := w2.households.size()
	_at_hour(w2, 6.0)
	c2.daily()
	check(w2.households.size() == n2 + 1 and str(w2.households[n2].home) == "b7" and w2.household_in("b7") == n2 and w2.holds(World.hh_ref(n2), w2.buildings["b7"]),
			"with an empty house for sale, the new household gets it from the manor and moves in at once")
	check(w2.property.describe(w2.buildings["b7"]).begins_with("the %s family's house" % hh2.family), "the house is named for its new family: %s" % w2.property.describe(w2.buildings["b7"]))
	# a save keeps the founded households
	var text := JSON.stringify(w.to_dict())
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	var again := JSON.stringify(w3.to_dict())
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), JSON.parse_string(again))
	check(w3.households.size() == w.households.size() and int(w3.households[n0].founded_from) == h and w3.npc(founder.id).household == n0 and str(w3.households[n0].home) == str(nh.home)
			and JSON.stringify(w4.to_dict()) == again,
			"a save keeps the new household, its house and its members")
	w.dispose()
	w2.dispose()
	w3.dispose()
	w4.dispose()


## Save version 6 (property phase 2) and the migration from 5: a version 5 save with a house being
## built on the player's plot and a house built on the other loads with its site a house's site, its
## house drawn from the house stamp, and nothing moved; saved again it is version 6 and stable.
func test_construction_migration() -> void:
	var w := new_world()
	var p := w.player
	var house := _player_house(w)
	p.home = str(house.id)
	p.coins += 100
	var pl1: Dictionary = w.plots[1]
	w.property.buy(pl1, World.PLAYER)
	w.start_site(pl1)
	p.inv.add("plank", 12)
	w.deliver(pl1, p.inv)
	var d := _as_v5(JSON.parse_string(JSON.stringify(w.to_dict())))
	check(not d.has("construction") and not d.plots[1].site.has("kind") and not d.buildings[house.id].has("stamp"), "the fixture is a version 5 save")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var s1: Dictionary = w2.plot(str(pl1.id)).site
	check(str(s1.kind) == "house" and absf(w2.site_progress(w2.plot(str(pl1.id))) - 12.0 / 60.0) < 0.001 and w2.site_delivered(w2.plot(str(pl1.id))) == {"plank": 12}, "v5: the site is a house's, with its progress")
	var hb: Dictionary = w2.buildings[house.id]
	check(str(hb.stamp) == "house" and str(hb.kind) == "house" and int(hb.x) == int(house.x) and w2.owner_of(hb) == World.PLAYER and w2.interiors.has(str(house.id)) and w2.player.home == str(house.id),
			"v5: the built house stays, the player's home, with its interior")
	check(w2.total_coins() == w.total_coins(), "v5: every coin kept")
	var again := JSON.stringify(w2.to_dict())
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(again))
	check(int(w2.to_dict().save_version) == World.SAVE_VERSION and JSON.stringify(w3.to_dict()) == again, "v5: saved again as the current version, stable")
	w.dispose()
	w2.dispose()
	w3.dispose()


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
		- int(st.get("eaten_wheat", 0)) - int(st.get("exported_wheat", 0)) - int(st.get("farm_seed_saved", 0))
	check(_wheat_held(w) == expect, "grain conserved: held %d, expected %d (harvest - cooked - fed - eaten - exported - kept as seed)" % [_wheat_held(w), expect])
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


## A save as save_version 5 wrote it, before property phase 2 (fixture builder for the migration
## tests): no helpers' contracts, sites without a kind, built houses without kind or stamp, no
## workshops and no founded households.
func _as_v5(d: Dictionary) -> Dictionary:
	d.save_version = 5
	d.format = "mml-save/5"
	d.erase("construction")
	for p in d.plots:
		if p.site is Dictionary:
			p.site.erase("kind")
	for id in d.buildings:
		for k in ["kind", "stamp", "allow"]:
			d.buildings[id].erase(k)
	for hh in d.households:
		for k in ["founded_from", "founded_day", "build"]:
			hh.erase(k)
	return d


## A save as save_version 4 wrote it, before property (fixture builder for the migration tests): a
## plot's owner "" or "player" and the player's plot list, a field's list of its farmers' ids, a
## stall's merchant id and a pen's keeper id (-1 for none), buildings without owners, no parcel
## counter and no settled households. `w` is the world the save `d` came from.
func _as_v4(w: World, d: Dictionary) -> Dictionary:
	_as_v5(d)
	d.save_version = 4
	d.format = "mml-save/4"
	d.erase("next_parcel")
	var mine := []
	for p in d.plots:
		if str(p.owner) == "player":
			mine.append(p.id)
		p.owner = "player" if str(p.owner) == "player" else ""
		for k in ["tenant", "rent", "due_day", "arrears", "missed", "building"]:
			p.erase(k)
	d.player.plots = mine
	for i in d.fields.size():
		d.fields[i].owner = w.field_workers(w.fields[i]).map(func(n): return n.id)
		d.fields[i].erase("tenant")
	for id in d.stalls:
		d.stalls[id].owner = World.ref_id(str(d.stalls[id].tenant)) if str(d.stalls[id].tenant) != "" else -1
		d.stalls[id].erase("tenant")
	if d.has("fauna"):
		for id in d.fauna.pens:
			var pen: Dictionary = d.fauna.pens[id]
			pen.owner = World.ref_id(str(pen.tenant)) if str(pen.tenant) != "" else -1
			pen.erase("tenant")
	for id in d.buildings:
		for k in ["owner", "tenant", "parcel", "rent", "due_day", "arrears", "missed"]:
			d.buildings[id].erase(k)
	for hh in d.households:
		hh.erase("ended")
	return d


## Property and land, phase 1 (owner rules 2026-10-18; docs/BUILD_DECISIONS.md "Property and land"):
## one owner reference everywhere, buying, leasing, weekly rent and eviction with every coin kept,
## a house whose family dies out going back to the manor and on to the player, several houses and
## selling one, the heir, the legality check for new ground, and the audit's defects.
func test_property() -> void:
	var w := new_world()
	var pr := w.property
	var p := w.player
	var valid := func(ref: String, tenant: bool) -> bool:
		if tenant and ref == "":
			return true
		return ref in [World.MANOR, World.PLAYER] or ((ref.begins_with("hh:") or ref.begins_with("npc:")) and World.ref_id(ref) >= 0)
	# one owner reference for every kind of property
	var things: Array = pr._all_things()
	var bad := things.filter(func(t): return not (t.owner is String and t.tenant is String and valid.call(t.owner, false) and valid.call(t.tenant, true)))
	check(things.size() == w.buildings.size() + w.plots.size() + w.stalls.size() + w.stations.size() + w.fauna.pens.size() + w.fields.size() and bad.is_empty(),
			"every building, plot, stall, station, pen and field has one owner and one tenant reference (%d things, %d bad)" % [things.size(), bad.size()])
	check(things.all(func(t): return not w.owner_of(t).begins_with("npc:")), "people own land and buildings only as households")
	var houses_ok := true
	for hh in w.households:
		var b: Dictionary = w.buildings[hh.home]
		var ref := World.hh_ref(int(hh.id))
		houses_ok = houses_ok and (w.owner_of(b) == ref if b.type in ["house", "hut"] else (w.owner_of(b) == World.MANOR and w.tenant_of(b) == ref))
	check(houses_ok, "a house is its household's own; the manor house and the tavern are the manor's, let to the households living there")
	check(w.owner_of(w.buildings["b4"]) == World.MANOR and w.owner_of(w.stations["s4"]) == World.MANOR and w.may_use(World.PLAYER, w.stations["s4"]), "the smithy and its forge are the manor's, open to the player")
	check(w.stalls.values().all(func(s): return Business.is_pitch(s) or (w.party(w.tenant_of(s)) != null and w.party(w.tenant_of(s)).job == "merchant")), "each stall is let to its merchant (the open pitches are the player's to rent)")
	check(w.fields.all(func(f): return w.owner_of(f) == World.MANOR and not w.field_workers(f).is_empty()), "the fields are the manor's, worked by its farmers")
	check(w.plots.all(func(pl): return pr.for_sale(pl)) and pr.price_of(w.plots[0]) == int(GameData.b("plot_price")) and int(w.plots[0].price) == int(GameData.b("plot_price")),
			"the plots are the manor's, for sale at balance.json's plot_price (audit defect 4)")
	var crate: Dictionary = {}
	for c in w.containers:
		if c.kind == "crate" and w.buildings.has(c.at) and w.buildings[c.at].type == "house":
			crate = c
			break
	check(w.container_owner(crate) == w.party(w.holder_of(w.buildings[crate.at])), "a crate's owner comes from who holds its house")
	# buying land: the price goes to the treasury, coins are kept
	var coins := func() -> int: return w.total_coins() - w.coin_sources
	var c0: int = coins.call()
	var pl0: Dictionary = w.plots[0]
	var pl1: Dictionary = w.plots[1]
	p.coins = 1000
	c0 = coins.call()
	var t0 := w.treasury
	check(pr.buy(pl0, World.PLAYER) == "" and w.owner_of(pl0) == World.PLAYER and w.treasury == t0 + 60 and p.coins == 940 and coins.call() == c0, "the player buys plot0 for 60 coins, paid to the treasury")
	check(pr.buy(pl0, World.PLAYER) != "" and pr.lease(pl0, World.PLAYER) != "", "it cannot be bought or leased twice")
	# leasing: a week's rent at once, then weekly; unpaid rent falls into arrears, then the lease ends
	var rent := pr.rent_of(pl1)
	check(pr.lease(pl1, World.PLAYER) == "" and w.tenant_of(pl1) == World.PLAYER and w.owner_of(pl1) == World.MANOR and int(pl1.rent) == rent and int(pl1.due_day) == w.day() + 7 and p.coins == 940 - rent,
			"the player leases plot1 for %d coins a week, the first week paid" % rent)
	pr.collect_rents()
	check(p.coins == 940 - rent, "no rent is taken before it is due")
	w.minutes += 7 * World.DAY
	pr.collect_rents()
	check(p.coins == 940 - 2 * rent and int(pl1.due_day) == w.day() + 7 and coins.call() == c0, "a week on, the rent is paid from the purse to the treasury")
	var purse := p.coins
	p.coins = 0
	w.treasury += purse                # (the player spends it; the coins stay counted)
	w.minutes += 7 * World.DAY
	pr.collect_rents()
	check(w.tenant_of(pl1) == World.PLAYER and int(pl1.arrears) == rent and int(pl1.missed) == 1, "a tenant who cannot pay falls into arrears")
	w.minutes += 7 * World.DAY
	pr.collect_rents()
	check(w.tenant_of(pl1) == "" and pr.for_sale(pl1) and not pl1.has("rent") and coins.call() == c0, "after %d unpaid weeks the manor takes the lease back; no coin is lost" % int(GameData.b("rent_evict_missed")))
	p.coins = purse
	w.treasury -= purse
	# arrears are paid with the next week's rent
	pr.lease(pl1, World.PLAYER)
	var keep := p.coins
	p.coins = 0
	w.minutes += 7 * World.DAY
	pr.collect_rents()
	p.coins = keep
	w.minutes += 7 * World.DAY
	pr.collect_rents()
	check(int(pl1.arrears) == 0 and p.coins == keep - 2 * rent and w.tenant_of(pl1) == World.PLAYER, "arrears are paid with the next rent")
	check(pr.end_lease(pl1, World.PLAYER) == "" and pr.for_sale(pl1) and coins.call() == c0, "the player gives the lease up")
	# a household dies out: its house and stores go to the manor, which sells it to the player
	var h := w.household_in("b7")
	var hh: Dictionary = w.households[h]
	hh.pantry.add("pottage", 2)
	var stores: int = hh.pantry.total()
	var gran0: int = w.granary.total()
	var goods0 := _all_goods(w)
	for m in hh.members:
		w.kill(w.npc(int(m)), "fever")
	var b7: Dictionary = w.buildings["b7"]
	check(w.owner_of(b7) == World.MANOR and pr.for_sale(b7) and hh.pantry.total() == 0 and w.granary.total() == gran0 + stores, "a house whose family died out goes back to the manor, its stores (%d) to the granary" % stores)
	check(_all_goods(w) == goods0 and coins.call() == c0, "nothing is lost or made when a household dies out")
	check(w.container_owner(w.containers.filter(func(c): return c.at == "b7")[0]) == null if w.containers.any(func(c): return c.at == "b7") else true, "its crates are nobody's now")
	check(pr.market().has(b7) and pr.market().has(pl1), "the manor offers the empty house and the plot")
	var hp := int(GameData.b("house_price"))
	t0 = w.treasury
	p.home = ""
	check(pr.buy(b7, World.PLAYER) == "" and w.owner_of(b7) == World.PLAYER and w.treasury == t0 + hp and p.home == "b7", "the player buys the empty house for %d coins; it becomes their home" % hp)
	check(w.household_in("b7") < 0 and w.container_owner(w.containers.filter(func(c): return c.at == "b7")[0]) == null if w.containers.any(func(c): return c.at == "b7") else true, "nobody else lives there")
	# a second house: built on plot0; the player chooses the home and sells one
	w.start_site(pl0)
	for id in GameData.b("house_cost"):
		p.inv.add(id, int(GameData.b("house_cost")[id]))
	w.deliver(pl0, p.inv)
	var hid := "house_plot0"
	check(w.owner_of(w.buildings[hid]) == World.PLAYER and str(w.buildings[hid].parcel) == "plot0" and str(pl0.building) == hid and p.home == "b7", "a house built on the player's plot is theirs; the home stays where it was")
	check(pr.homes_of(World.PLAYER) == ["b7", hid] and pr.held_by(World.PLAYER).size() == 2, "the player holds two houses")
	check(pr.set_home(hid) == "" and p.home == hid and pr.set_home("b5") != "", "the home is one of them, chosen")
	var value := pr.sale_value(pl0)
	t0 = w.treasury
	var pc := p.coins
	check(pr.sell(pl0, World.PLAYER) == "" and w.owner_of(pl0) == World.MANOR and w.owner_of(w.buildings[hid]) == World.MANOR and p.coins == pc + value and w.treasury == t0 - value,
			"selling the home sells the house with its plot to the manor (%d coins)" % value)
	check(p.home == "b7", "the home moves to the other house")
	check(pr.for_sale(pl0) and pr.price_of(pl0) == hp, "the manor offers the house on plot0 again, as a house")
	check(coins.call() == c0, "every coin is kept through the sales")
	# the heir inherits everything owned and leased
	pr.lease(pl0, World.PLAYER)
	p.home = hid
	w.damage_player(9999, "a fall")
	w.continue_as_heir()
	check(w.owner_of(b7) == World.PLAYER and w.tenant_of(pl0) == World.PLAYER and w.player.home == hid and pr.held_by(World.PLAYER).size() == 2, "the heir holds everything the family held, and keeps the home")
	check(w.player.pos.distance_to(Vector2(w.building_door(hid)) + Vector2(0.5, 0.5)) < 0.1, "the heir starts at the home's door")
	# selling the last house leaves the family homeless; the chest stays theirs
	w.player.chest.add("log", 3)
	pr.end_lease(pl0, World.PLAYER)
	check(w.player.home == "b7", "giving up the leased home moves the family to the house they own")
	w.treasury += 500
	c0 += 500
	pr.sell(b7, World.PLAYER)
	check(w.player.home == "" and w.player.chest.count("log") == 3 and pr.held_by(World.PLAYER).is_empty(), "selling the last house leaves the family homeless, the chest kept")
	# claiming new ground anywhere legal (phase 2 places buildings with it)
	check(pr.can_claim(Rect2i(int(w.buildings["b5"].x) + 1, int(w.buildings["b5"].y) + 1, 4, 4)).begins_with("a building"), "not on a building")
	check(pr.can_claim(Rect2i(int(pl0.x) + 2, int(pl0.y) + 2, 4, 4)).begins_with("surveyed land"), "not across a surveyed plot")
	var rc: Array = w.map.data.road[10]
	check(pr.can_claim(Rect2i(int(rc[0]) - 1, int(rc[1]) - 1, 3, 3)) != "", "not on the road (%s)" % pr.can_claim(Rect2i(int(rc[0]) - 1, int(rc[1]) - 1, 3, 3)))
	check(pr.can_claim(Rect2i(-2, 5, 4, 4)) == "outside the village" and pr.can_claim(Rect2i(30, 30, 2, 2)) == "too small", "inside the village and big enough")
	var f0: Dictionary = w.fields[0]
	check(pr.can_claim(Rect2i(int(f0.x), int(f0.y), 3, 3)).contains("field"), "not on a field")
	var clear := Rect2i()
	for y in range(2, w.map.h - 8, 2):
		for x in range(2, w.map.w - 8, 2):
			if clear.size == Vector2i.ZERO and pr.can_claim(Rect2i(x, y, 5, 5)) == "":
				clear = Rect2i(x, y, 5, 5)
	check(clear.size != Vector2i.ZERO, "there is clear ground to claim (%s)" % clear)
	c0 += 100 - w.player.coins
	w.player.coins = 100
	var lp := pr.land_price(5, 5)
	var parcel := pr.claim(clear, World.PLAYER)
	check(not parcel.is_empty() and parcel.id == "parcel0" and w.owner_of(parcel) == World.PLAYER and w.player.coins == 100 - lp and w.plots.has(parcel), "ground is surveyed and bought on the spot (%d coins for 5x5)" % lp)
	check(pr.claim(clear.grow(-1), World.PLAYER).is_empty() and pr.why.begins_with("surveyed land") and w.plots.size() == 3, "the same ground cannot be claimed again")
	c0 -= w.player.coins
	w.player.coins = 0
	check(pr.claim(Rect2i(clear.end.x + 2, clear.position.y, 5, 5), World.PLAYER).is_empty() and w.plots.size() == 3 and pr.next_parcel == 1, "nothing is surveyed for a buyer who cannot pay")
	check(coins.call() == c0, "every coin is kept through leases, rent, eviction, sales and claims")
	# audit defect 1: a farmer who changes work stops working the field at once
	var fw: Dictionary = w.fields[2]
	var leaver: NPC = w.field_workers(fw)[0]
	w.brain._change_job(leaver, "woodcutter", "test")
	check(not w.field_workers(fw).has(leaver), "a farmer who leaves is no longer one of the field's farmers")
	w.set_field(fw, "ripe")
	fw.crop = 20
	w.player.crimes.clear()
	w.player.pos = FAR_GUARDS
	w.player_harvest(fw)
	check(w.player.crimes.is_empty() or int(w.player.crimes[-1].victim) != leaver.id, "taking its wheat is no longer theft from the former farmer")
	# audit defect 2: a stall that falls vacant is let again by the manor
	var sid := "stall0"
	var merchant: NPC = w.party(w.tenant_of(w.stalls[sid]))
	w.kill(merchant, "fever")
	check(w.tenant_of(w.stalls[sid]) == "", "a dead merchant's stall falls vacant")
	var idle: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "woodcutter":
			idle = o
			break
	idle.job = ""
	idle.coins = 40
	pr.relet_stalls()
	check(w.tenant_of(w.stalls[sid]) == World.npc_ref(idle.id) and idle.job == "merchant" and idle.workplace == sid, "the manor lets it to a villager out of work")
	idle.pos = Vector2(int(w.stalls[sid].use[0]) + 0.5, int(w.stalls[sid].use[1]) + 0.5)
	check(w.at_post(idle) and w.container_owner({"id": sid, "kind": "stall", "x": 0, "y": 0, "at": sid}) == idle, "the new merchant serves there, and the stall's goods are theirs")
	# saving keeps it all
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(int(d.save_version) == World.SAVE_VERSION and w2.owner_of(w2.plot("parcel0")) == World.PLAYER and w2.property.next_parcel == 1 and w2.owner_of(w2.buildings["b7"]) == World.MANOR
			and w2.tenant_of(w2.stalls[sid]) == World.npc_ref(idle.id) and w2.households[h].get("ended", false), "a save keeps owners, tenants, parcels and ended households")
	var saved2 := JSON.stringify(w2.to_dict())
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(saved2))
	check(JSON.stringify(w3.to_dict()) == saved2, "and saves the same again")
	w3.dispose()
	w.dispose()
	w2.dispose()


## Saves 1-4 (before property) migrate into the one owner model: the player's plot and the house on
## it stay exactly where they are and stay theirs, the other plot stays the manor's, fields, stalls
## and pens get the new references, a household that had died out gives its house to the manor, and
## every coin is kept.
func test_property_migration() -> void:
	var w := new_world()
	var p := w.player
	p.coins += 200
	var pl: Dictionary = w.plots[0]
	w.buy_plot(pl)
	w.start_site(pl)
	for id in GameData.b("house_cost"):
		p.inv.add(id, int(GameData.b("house_cost")[id]))
	w.deliver(pl, p.inv)
	p.home = "house_plot0"
	for i in 200:
		w.update(0.5)
	var text := JSON.stringify(w.to_dict())
	var dead_home := ""
	for hh in w.households:              # a household of no farmer, merchant or keeper (their work passes on at death)
		if dead_home == "" and w.buildings[hh.home].type == "house" and hh.members.all(func(m): return not w.npc(int(m)).job in ["farmer", "merchant"]):
			dead_home = hh.home
	for v in [4, 3, 2, 1]:
		var d: Dictionary = _as_v4(w, JSON.parse_string(text))
		d.save_version = v
		d.format = "mml-save/%d" % v
		# a household that died out before property: nobody settled its house
		var hd: Dictionary = d.households.filter(func(x): return x.home == dead_home)[0]
		for nd in d.npcs:
			if hd.members.has(nd.id) or hd.members.has(float(nd.id)):
				nd.alive = false
		if v <= 2:
			for nd in d.npcs:
				if int(nd.id) == w.reeve_id:
					nd.coins = int(nd.coins) + int(d.treasury)
			for k in ["treasury", "granary", "last_reeve_day", "last_payday"]:
				d.erase(k)
		if v == 1:
			d.erase("fauna")
			d.deer = 30
		var coins_then := 0
		for nd in d.npcs:
			coins_then += int(nd.coins)
		coins_then += int(d.player.coins) + int(d.get("treasury", 0))
		for l in d.loot:
			coins_then += int(l.coins)
		var w2 := World.new()
		w2.load_dict(VillageMap.load_default(), d)
		var p0 := w2.plot("plot0")
		var hb: Dictionary = w2.buildings.get("house_plot0", {})
		check(int(p0.x) == int(pl.x) and int(p0.y) == int(pl.y) and w2.owner_of(p0) == World.PLAYER and str(p0.building) == "house_plot0", "v%d: the player's plot stays where it is, theirs, with its house" % v)
		check(not hb.is_empty() and int(hb.x) == int(pl.x) and int(hb.y) == int(pl.y) and w2.owner_of(hb) == World.PLAYER and str(hb.parcel) == "plot0" and w2.player.home == "house_plot0", "v%d: the house stays where it is, the player's home" % v)
		check(w2.property.for_sale(w2.plot("plot1")) and int(w2.plot("plot1").x) == int(w.plots[1].x), "v%d: the other plot stays the manor's, in place" % v)
		check(w2.fields.all(func(f): return w2.owner_of(f) == World.MANOR and w2.field_workers(f).map(func(n): return n.id) == w.field_workers(w.fields[w2.fields.find(f)]).map(func(n): return n.id)), "v%d: fields are the manor's, with the same farmers" % v)
		check(w2.stalls.keys().all(func(id): return w2.tenant_of(w2.stalls[id]) == w.tenant_of(w.stalls[id])), "v%d: each stall stays let to its merchant" % v)
		check(w2.fauna.pens.values().all(func(pen): return w2.pen_keeper(pen) != null), "v%d: each pen has its keeper" % v)
		check(w2.owner_of(w2.buildings[dead_home]) == World.MANOR and w2.property.for_sale(w2.buildings[dead_home]), "v%d: a house whose family had died out is the manor's, for sale" % v)
		check(w2.owner_of(w2.buildings["b_manor"]) == World.MANOR and w2.owner_of(w2.buildings["b5"]).begins_with("hh:"), "v%d: the other buildings get their owners" % v)
		check(w2.total_coins() == coins_then, "v%d: every coin is kept (%d)" % [v, coins_then])
		var again := JSON.stringify(w2.to_dict())
		var w3 := World.new()
		w3.load_dict(VillageMap.load_default(), JSON.parse_string(again))
		check(int(w2.to_dict().save_version) == World.SAVE_VERSION and JSON.stringify(w3.to_dict()) == again, "v%d: saved again as the current version, stable" % v)
		w2.dispose()
		w3.dispose()
	w.dispose()


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
	var old: Dictionary = _as_v4(w, JSON.parse_string(text))
	old.erase("fauna")
	old.save_version = 1
	old.deer = 30
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), old)
	check(w4.npcs.size() == w.npcs.size() and w4.fauna.animals.size() > 0, "a version 1 save loads and gets its animals")
	check(w4.pen_keeper(w4.fauna.pen_of("cow")) != null, "pens get keepers after loading a version 1 save")
	check(w4.total_coins() == w.total_coins(), "a version 1 save keeps every coin (%d vs %d)" % [w4.total_coins(), w.total_coins()])
	# a version 2 save (before the manor treasury): the reeve's coins become the treasury
	var v2: Dictionary = _as_v4(w, JSON.parse_string(text))
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
	check(int(w5.to_dict().save_version) == World.SAVE_VERSION and JSON.stringify(w5.to_dict()).contains("\"treasury\""), "saves are written as the current version with the treasury and granary")
	# a save from before the plots moved (they lay over houses b20-b22): plot0 owned with a house on
	# it and the player inside, plot1 unsold, and a tree where the new plot0 is
	var lay: Dictionary = _as_v4(w, JSON.parse_string(text))
	lay.save_version = 3
	lay.plots[0].x = 94; lay.plots[0].y = 78; lay.plots[0].door = [98, 87]
	lay.plots[0].owner = "player"; lay.plots[0].site = {"need": {}, "done": true}
	lay.plots[1].x = 106; lay.plots[1].y = 78; lay.plots[1].door = [110, 87]
	lay.buildings["house_plot0"] = {"id": "house_plot0", "type": "player_house", "x": 94, "y": 78, "w": 9, "h": 10, "door": [98, 87], "name": "Test family house"}
	lay.player.home = "house_plot0"
	lay.player.plots = ["plot0"]
	lay.player.pos = [98.5, 80.5]
	lay.trees.append({"x": 91, "y": 23, "trunk": 459, "top": 1562, "bottom": 1782, "state": "grown", "regrow": 0.0})
	var w8 := World.new()
	var m8 := VillageMap.load_default()
	w8.load_dict(m8, lay)
	var p0 := w8.plot("plot0")
	var mp0: Dictionary = m8.data.plots[0]
	var h0: Dictionary = w8.buildings["house_plot0"]
	check(int(p0.x) == int(mp0.x) and int(p0.y) == int(mp0.y) and w8.owner_of(p0) == World.PLAYER and p0.site.done, "an old save's plot moves to the map's plot with its owner and site")
	check(int(h0.x) == int(mp0.x) and int(h0.y) == int(mp0.y) and int(h0.door[1]) == int(mp0.door[1]) and w8.player.home == "house_plot0", "the house built on it moves with it and stays the player's home")
	check(Rect2(float(p0.x), float(p0.y), 9.0, 10.0).has_point(w8.player.pos), "the player standing in it moves with it")
	check(int(w8.plot("plot1").y) == int(m8.data.plots[1].y) and w8.property.for_sale(w8.plot("plot1")), "an unsold plot moves too (the manor's, for sale)")
	check(not w8.trees.any(func(t): return int(t.x) == 91 and int(t.y) == 23), "trees the generator cleared from the new plots are gone from the old save")
	check(m8.is_solid(Vector2i(91, 79)) and m8.is_solid(Vector2i(int(mp0.x) + 1, int(mp0.y) + 1)), "house b20's wall and the moved house are both solid")
	var w9 := World.new()
	w9.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w8.to_dict())))
	var w10 := World.new()
	var saved9 := JSON.stringify(w9.to_dict())
	w10.load_dict(VillageMap.load_default(), JSON.parse_string(saved9))
	var surveys := func(w: World) -> int: return w.log_lines.filter(func(l): return str(l).contains("surveyor")).size()
	check(surveys.call(w8) == 2 and surveys.call(w9) == 2 and int(w9.plot("plot0").x) == int(mp0.x), "loading the corrected save again moves nothing and notes nothing")
	check(JSON.stringify(w10.to_dict()) == saved9, "and the corrected save is stable from then on")
	# a save from before quests (Build 4) gets the storyline on load, once
	var pre: Dictionary = _as_v4(w, JSON.parse_string(text))
	pre.erase("quest_offers")
	pre.player.erase("quests")
	var w6 := World.new()
	w6.load_dict(VillageMap.load_default(), pre)
	var story: Array = w6.player.quests.filter(func(q): return q.id == "the_sage_in_the_north")
	check(story.size() == 1, "a save from before quests starts the sage storyline on load")
	var w7 := World.new()
	w7.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w6.to_dict())))
	check(w7.player.quests.filter(func(q): return q.id == "the_sage_in_the_north").size() == 1, "loading again does not start it twice")


## Build 7 economy corrections (owner, 2026-10-18; docs/release/BUILD_7_ISSUES.md B7-001 to B7-007).
func test_build7_economy() -> void:
	var w := new_world()
	var p := w.player
	var b: NPCBrain = w.brain
	p.pos = FAR_GUARDS
	check(p.coins == 20 and int(GameData.b("start_coins_player")) == 20, "B7-001: a new player starts with 20 coins")
	# B7-002: rewards set aside, returned when a quest ends unpaid
	var cook: NPC = w.npcs.filter(func(o): return o.job == "cook")[0]
	cook.inv.remove("log", cook.inv.count("log"))
	cook.coins = 40
	w.quests.offers.clear()
	w.quests.offers[cook.id] = "wood_for_the_hearth"
	var base := w.total_coins() - w.coin_sources
	var q: Dictionary = w.quests.accept(cook)
	check(int(q.reserved) == 10 and cook.coins == 30 and w.quests.reserved_total() == 10 and w.total_coins() - w.coin_sources == base, "B7-002: the cook's ten coins are set aside, still counted")
	var saved := JSON.stringify(w.to_dict())
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(saved))
	check(int(w2.player.quests.filter(func(x): return x.id == "wood_for_the_hearth")[0].reserved) == 10 and w2.total_coins() == w.total_coins(), "B7-002: the reserve is saved and loaded, nothing doubled or lost")
	w2.dispose()
	var heir_of: NPC = w._heir(cook)
	var heir_coins := heir_of.coins if heir_of else 0
	w.kill(cook, "illness")
	check(int(q.reserved) == 0 and (heir_of == null or heir_of.coins == heir_coins + 30 + 10) and w.total_coins() - w.coin_sources == base, "B7-002: a giver who dies has the reserve back first; it passes on with the rest")
	w.quests.drop_failed()
	check(not p.quests.has(q) and w.total_coins() - w.coin_sources == base, "B7-002: the quest is dropped without paying twice")
	# work that lapses gives the wage back
	var wc: NPC = w.npcs.filter(func(o): return o.job == "woodcutter")[0]
	wc.inv.remove("log", wc.inv.count("log"))
	wc.coins = 20
	base = w.total_coins() - w.coin_sources
	var qw: Dictionary = w.quests.accept(wc, "work_the_woods")
	check(wc.coins == 14 and int(qw.reserved) == 6, "B7-002: a wage is set aside when the work is taken on")
	qw.day = w.day() - 3
	w.quests.drop_failed()
	check(not p.quests.has(qw) and wc.coins == 20 and w.total_coins() - w.coin_sources == base, "B7-002: lapsed work gives the wage back to the employer")
	# the player dies: every reserve goes back
	var smith: NPC = w.npcs.filter(func(o): return o.job == "smith")[0]
	smith.inv.remove("iron_ore", smith.inv.count("iron_ore"))
	smith.coins = 25
	w.quests.offers[smith.id] = "ore_for_the_forge"
	var qs: Dictionary = w.quests.accept(smith)
	check(smith.coins == 5 and int(qs.reserved) == 20, "B7-002: the smith's twenty set aside")
	var before_heir := w.total_coins() - w.coin_sources
	w.continue_as_heir()
	check(smith.coins == 25 and w.quests.reserved_total() == 0 and w.total_coins() - w.coin_sources == before_heir, "B7-002: when the player dies the twenty go back to the smith")
	p = w.player
	p.pos = FAR_GUARDS
	# a save from before reserving (version 6): accepted quests are funded on load if they can be
	smith.coins = 25
	w.quests.offers[smith.id] = "ore_for_the_forge"
	var qo: Dictionary = w.quests.accept(smith)
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	old.save_version = 6
	for x in old.player.quests:
		if x.id == "ore_for_the_forge":
			x.erase("reserved")
	for o in old.npcs:
		if int(o.id) == smith.id:
			o.coins = 25                                 # as a version 6 save had it: nothing set aside
	var w6 := World.new()
	w6.load_dict(VillageMap.load_default(), old)
	var q6: Dictionary = w6.player.quests.filter(func(x): return x.id == "ore_for_the_forge")[0]
	check(int(q6.reserved) == 20 and w6.npc(smith.id).coins == 5 and w6.total_coins() == w.total_coins(), "B7-002: v6 save: the promised twenty are set aside on load, every coin kept")
	for o in old.npcs:
		if int(o.id) == smith.id:
			o.coins = 3                                  # a giver who cannot pay yet
	var w6b := World.new()
	w6b.load_dict(VillageMap.load_default(), old)
	var q6b: Dictionary = w6b.player.quests.filter(func(x): return x.id == "ore_for_the_forge")[0]
	w6b.player.inv.add("iron_ore", 6)
	check(int(q6b.reserved) == 0 and w6b.quests.complete(q6b) == -2 and w6b.player.inv.count("iron_ore") >= 6, "B7-002: v6 save, a giver who cannot pay: nothing changes hands yet")
	w6b.npc(smith.id).coins = 30
	check(w6b.quests.complete(q6b) == 20 and w6b.npc(smith.id).coins == 10, "B7-002: once they can, the exact twenty are paid")
	w6.dispose()
	w6b.dispose()
	w.quests._release(qo)
	p.quests.erase(qo)
	# B7-004: wheat cut for harvest work stays the farmer's
	var farmer: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "farmer" and not w.quests.field_of(o).is_empty() and w.quests.active_from(o).is_empty():
			farmer = o
			break
	var f: Dictionary = w.quests.field_of(farmer)
	w.set_field(f, "ripe")
	f.crop = 60
	farmer.coins = 20
	p.inv.remove("wheat", p.inv.count("wheat"))
	p.trim_stolen()
	var qh: Dictionary = w.quests.accept(farmer, "work_the_harvest")
	for i in 4:
		w.player_harvest(f)
	check(p.inv.count("wheat") == 24 and p.stolen_count("wheat") == 0, "B7-004: the hired wheat is cut without theft")
	w.transfer(p.inv, p.chest, "wheat", 6)
	var crimes0 := p.crimes.size()
	qh.day = w.day() - 2
	w.quests.drop_failed()
	check(not p.quests.has(qh) and farmer.coins == 20, "B7-004: the work lapses; the farmer has the wage back")
	check(int(p.stolen.get("wheat", {}).get(str(farmer.id), 0)) == 18 and int(p.chest_stolen.get("wheat", {}).get(str(farmer.id), 0)) == 6,
			"B7-004: the kept wheat is marked the farmer's, carried and in the chest")
	check(p.crimes.size() == crimes0 + 1 and str(p.crimes[-1].kind) == "theft" and Dialogue.caught(w, farmer), "B7-004: it is a theft on the record, and the farmer knows")
	# B7-003: the goods merchant buys made jewellery and helmets, within its means and caps
	var gm: NPC = null
	for o: NPC in w.npcs:
		if o.alive and b.buy_role(o) == "merchant_goods":
			gm = o
	for id in ["copper_ring", "gold_ring", "amulet", "leather_cap", "iron_helmet"]:
		gm.inv.remove(id, gm.inv.count(id))
		check(b.wants(gm, id) > 0 and w.buy_price(gm, id) > 0, "B7-003: the goods merchant buys a %s" % GameData.item_name(id).to_lower())
	gm.coins = 100
	p.inv.add("copper_ring", 4)
	var price := w.buy_price(gm, "copper_ring")
	var pc := p.coins
	check(w.player_sell(gm, "copper_ring", price).result == "sold" and p.coins == pc + price and gm.coins == 100 - price, "B7-003: selling a ring pays from the merchant's purse")
	w.player_sell(gm, "copper_ring", w.buy_price(gm, "copper_ring"))
	w.player_sell(gm, "copper_ring", w.buy_price(gm, "copper_ring"))
	check(b.wants(gm, "copper_ring") == 0 and gm.inv.count("copper_ring") == 3, "B7-003: no more than its stock cap")
	gm.coins = 0
	check(w.player_sell(gm, "copper_ring", w.buy_price(gm, "copper_ring")).result == "failed", "B7-003: a merchant without the coins cannot buy")
	# B7-007: stone by caravan once the village's own is worked out
	var raws: Array = w.npcs.filter(func(o): return o.alive and b.buy_role(o) == "merchant_raw")
	for o: NPC in raws:
		o.inv.remove("stone", o.inv.count("stone"))
		o.coins = 100
	check(b._caravan_stone() == 0, "B7-007: no stone brought while the village has its own")
	for d in w.deposits:
		if d.ore == "stone":
			d.amount = 0
	var exp0 := int(w.stats.get("exported_stone", 0))
	b.caravan()
	var got := 0
	for o: NPC in raws:
		got += o.inv.count("stone")
		check(o.inv.count("stone") <= int(NPCBrain.BUYS.merchant_raw.stone) and o.coins >= int(GameData.b("trader_cash_floor")), "B7-007: %s buys within the stock cap and keeps the cash floor" % o.name)
	var cfg: Dictionary = GameData.b("caravan_stone")
	var each := maxi(1, roundi(GameData.value("stone") * float(cfg.markup)))
	check(got > 0 and got <= int(cfg.load) and int(w.stats.get("imported_stone", 0)) == got, "B7-007: the caravan sells at most a cart of stone (%d)" % got)
	check(int(w.stats.get("caravan_stone_coins", 0)) == got * each, "B7-007: at its price (%d each), recorded" % each)
	check(int(w.stats.get("exported_stone", 0)) == exp0, "B7-007: while it brings stone it carries none of the village's away")
	for o: NPC in raws:
		o.inv.remove("stone", o.inv.count("stone"))
	var cs2 := w.coin_sources
	var sold := b._caravan_stone()
	check(sold > 0 and cs2 - w.coin_sources == sold * each, "B7-007: the coins for it leave the village (%d)" % (cs2 - w.coin_sources))
	w.dispose()


## The manor's work (owner, 2026-10-18): the reeve's jobs come only from the manor's real business,
## goods are carried and used (never made or lost), wages come from the treasury, set aside when a job
## is taken and paid when it is done, and villagers work by the same rules as the player.
func test_manor_work() -> void:
	var w := new_world()
	var p := w.player
	var b: NPCBrain = w.brain
	var mw: ManorWork = w.manor_work
	p.pos = FAR_GUARDS
	check(mw.jobs.is_empty() and mw.lots.is_empty() and mw.yard.total() == 0, "a new village: the manor has nothing to carry or mend, so no jobs")
	check(not mw.sites.is_empty(), "the village's works to mend: the well and the roads (%d)" % mw.sites.size())
	# the manor's evening buys repair materials: they wait at the seller's as the manor's lot
	var carp: NPC = w.npcs.filter(func(o): return o.job == "carpenter")[0]
	carp.inv.add("plank", 30)
	w.treasury = 3000
	var goods0 := _ledger(w, ["plank", "stone", "log", "iron_bar", "wheat"])
	var coins0 := w.total_coins()
	w.food_days = 0.5                                   # (a famine: the granary buys nothing this evening)
	w.last_reeve_day = -1
	b.reeve_day()
	var plank_lot := mw.lots.filter(func(l): return l.inv.count("plank") > 0)
	check(not plank_lot.is_empty() and str(plank_lot[0].to.kind) == "yard", "repair planks bought are left at the carpenter's as the manor's lot, bound for the works yard")
	check(mw.jobs.any(func(j): return j.kind == "haul") and mw.jobs.all(func(j): return j.taker == ""), "carrying them is posted as jobs")
	check(_ledger(w, ["plank", "stone", "log", "iron_bar", "wheat"]) == goods0 and w.total_coins() == coins0, "buying moves goods and coins: nothing made or lost")
	# the player carries a load to the works yard
	var hauls: Array = mw.open_for("player").filter(func(j): return j.kind == "haul" and str(j.to.kind) == "yard")
	var j: Dictionary = hauls[0]
	var t0 := w.treasury
	check(mw.take(j, "player") and w.treasury == t0 - int(j.wage) and int(j.reserved) == int(j.wage) and w.total_coins() == coins0, "taking a job sets its wage aside from the treasury (still counted)")
	check(not mw.take(mw.open_for("player")[0], "player") and mw.last_refusal.contains("already"), "one job at a time")
	check(mw.step(j) == "take" and mw.step_cell(j) == Vector2i(int(j.at[0]), int(j.at[1])), "first: collect the goods where they lie")
	var q := int(j.qty)
	var coins_p := p.coins
	check(mw.do_step(j, "player", p.inv) and j.load.total() == q and not p.inv.has("plank"), "collected: the manor's goods ride in the job's load, not the pack")
	check(mw.step(j) == "put" and mw.step_cell(j) == mw.yard_cell(), "then: to the works yard")
	check(mw.do_step(j, "player", p.inv) and mw.yard.count("plank") == q and p.coins == coins_p + int(j.wage) and mw.job_of("player").is_empty(), "delivered: in the yard, the wage paid")
	check(_ledger(w, ["plank", "stone", "log", "iron_bar", "wheat"]) == goods0 and w.total_coins() == coins0, "carrying makes and loses nothing")
	# mending uses the yard's materials (posted only when the yard holds a load)
	var load := int(ManorWork.cfg("mend_load"))
	check(mw.jobs.filter(func(x): return x.kind == "mend").size() == mw.yard.total() / load, "a mending job for each load in the yard (%d)" % (mw.yard.total() / load))
	var m: Dictionary = mw.open_for("player").filter(func(x): return x.kind == "mend")[0]
	var used0 := int(w.stats.get("used_repairs_plank", 0))
	mw.take(m, "player")
	mw.do_step(m, "player", p.inv)
	check(m.load.total() == load and mw.step(m) == "mend" and mw.step_cell(m) == Vector2i(int(m.site[0]), int(m.site[1])), "a mend takes a load from the yard to its site")
	coins_p = p.coins
	mw.do_step(m, "player", p.inv)
	check(int(w.stats.get("used_repairs_plank", 0)) == used0 + load and p.coins == coins_p + int(m.wage), "mending uses the load up (used_repairs_) and pays")
	var held := _all_goods(w)
	check(int(held.get("plank", 0)) + int(w.stats.get("used_repairs_plank", 0)) - used0 == int(goods0.plank) , "planks held plus planks used: still every plank")
	# a villager does the same work by the same rules
	var worker: NPC = w.npcs.filter(func(o): return o.role == "adult" and o.job == "woodcutter")[0]
	var open_now := mw.open_for(World.npc_ref(worker.id))
	var wc_coins := worker.coins
	check(mw.seek(worker) and not worker.plan.is_empty() and not mw.job_of(World.npc_ref(worker.id)).is_empty(), "a villager takes the most needed open job and plans it")
	var wj := mw.job_of(World.npc_ref(worker.id))
	check(wj.id == open_now[0].id and int(wj.reserved) == int(wj.wage), "the same job list and the same set-aside wage as the player's")
	var guard := 0
	while not mw.job_of(World.npc_ref(worker.id)).is_empty() and guard < 6:
		var st: Dictionary = worker.plan.filter(func(x): return x.get("act", "") in ["mj_step", "mj_mine"] or x.get("k", "") == "do")[0]
		b.act(worker, str(st.get("act", "mj_step")), st.get("args", {}))
		if not mw.job_of(World.npc_ref(worker.id)).is_empty():
			mw.plan(worker)
		guard += 1
	check(mw.job_of(World.npc_ref(worker.id)).is_empty() and worker.coins == wc_coins + int(wj.wage), "the villager does the steps and is paid the wage when done")
	# a manor hand is already paid: takes jobs unpaid
	var hand: NPC = worker
	hand.job = "manor_hand"
	var hj: Array = mw.open_for(World.npc_ref(hand.id))
	if not hj.is_empty():
		mw.take(hj[0], World.npc_ref(hand.id))
		check(int(hj[0].reserved) == 0, "a manor hand takes the manor's work without a second wage")
		mw.release(hj[0])
	hand.job = "woodcutter"
	# no funds, no paid work: the treasury keeps its reserve
	w.treasury = 0
	check(mw.open_for("player").is_empty() and not mw.jobs.is_empty(), "with an empty treasury no paid job is open, though the work waits")
	var poor: NPC = w.npcs.filter(func(o): return o.role == "adult" and o.job == "miner")[0]
	b.laboured_today.erase(poor.id)
	check(not mw.seek(poor), "and nobody is paid for standing about: no job, no day labour")
	w.treasury = 3000
	# undone work lapses at the next dawn: the wage back, the goods back where they were
	var lj: Dictionary = mw.open_for("player").filter(func(x): return x.kind == "haul")[0] if mw.open_for("player").any(func(x): return x.kind == "haul") else mw.open_for("player")[0]
	var tl := w.treasury
	mw.take(lj, "player")
	mw.do_step(lj, "player", p.inv)
	w.minutes += 1440.0
	mw.dawn()
	check(lj.taker == "" and lj.load.total() == 0 and w.treasury == tl, "undone, a job lapses at dawn: its wage and load go back")
	check(_ledger(w, ["plank", "stone", "log", "iron_bar", "wheat"]).plank + int(w.stats.get("used_repairs_plank", 0)) - used0 == int(goods0.plank), "and no plank is lost")
	# quarrying: the manor's own stone for its works, only while the yard lacks it
	mw.yard = Inventory.new()
	mw.refresh()
	w.last_reeve_day = -1
	w.food_days = 0.5
	b.reeve_day()
	var qj: Array = mw.jobs.filter(func(x): return x.kind == "quarry")
	check(qj.size() == 1 and int(qj[0].qty) == int(ManorWork.cfg("quarry_qty")), "the reeve posts one quarry job while the works lack stone")
	if qj.size() == 1:
		var qq: Dictionary = qj[0]
		mw.take(qq, "player")
		p.inv.remove("stone", p.inv.count("stone"))
		check(not mw.do_step(qq, "player", p.inv), "the player must bring the stone")
		p.inv.add("stone", int(qq.qty))
		coins_p = p.coins
		check(mw.do_step(qq, "player", p.inv) and mw.yard.count("stone") == int(qq.qty) and p.coins == coins_p + int(qq.wage), "ten stone to the yard: paid")
	# the granary's grain is carried from the farmer's
	var farmer: NPC = w.npcs.filter(func(o): return o.job == "farmer")[0]
	farmer.inv.add("wheat", 400)
	w.granary.items.clear()
	w.food_days = 99.0
	w.last_reeve_day = -1
	var g0: int = int(_all_goods(w).get("wheat", 0))
	b.reeve_day()
	var bound := mw.bound("granary", "wheat")
	check(bound > 0 and w.granary.count("wheat") == 0 and int(_all_goods(w).get("wheat", 0)) == int(g0), "grain the granary buys waits at the farmer's (%d), counted, nothing lost" % bound)
	# relief: carried to the household unless it is urgent
	var h := -1
	for i in w.households.size():
		if b._members(i).size() > 0 and b._members(i).all(func(o): return o.job != "farmer"):
			h = i
			break
	w.granary.add("wheat", 200)
	for o: NPC in b._members(h):
		o.coins = 0
		for f in NPCBrain.FOOD:
			o.inv.remove(f, o.inv.count(f))
	var pantry: Inventory = w.households[h].pantry
	pantry.items.clear()
	pantry.add("wheat", ceili(1.5 * b.household_day_food(h) / 120.0))
	var before := pantry.count("wheat")
	b._relief(b.daily_obligations(), 0.0)
	check(mw.pending_for(h) > 0 and pantry.count("wheat") == before, "relief for a household with a day and a half of food is carried to it (a job)")
	pantry.items.clear()
	b._relief(b.daily_obligations(), 0.0)
	check(mw.pending_for(h) == 0 and pantry.count("wheat") > 0, "under a day of food, it is brought at once")
	# saved and loaded: lots, yard, jobs and wages set aside
	var any := mw.open_for("player")
	if not any.is_empty():
		mw.take(any[0], "player")
		mw.do_step(any[0], "player", p.inv)
	var saved := JSON.stringify(w.to_dict())
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(saved))
	check(w2.total_coins() == w.total_coins() and _all_goods(w2) == _all_goods(w) and w2.manor_work.jobs.size() == mw.jobs.size() and w2.manor_work.reserved_total() == mw.reserved_total(),
			"saved and loaded: every coin, good, job and wage set aside")
	var again := JSON.stringify(w2.to_dict())
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(again))
	check(JSON.stringify(w3.to_dict()) == again, "saved again: stable")
	w2.dispose()
	w3.dispose()
	# the player dies: their job goes back
	var c_before := w.total_coins() - w.coin_sources
	w.continue_as_heir()
	check(mw.job_of("player").is_empty() and w.total_coins() - w.coin_sources == c_before, "the player's death gives their manor job back, wage and all")
	# a version 7 save's single manor job (10 stone for the reeve) is dropped, its wage back in the treasury
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	old.save_version = 7
	old.erase("manor_work")
	old.treasury = int(old.treasury) - 6
	old.player.quests.append({"id": "work_for_the_manor", "giver": w.reeve_id, "day": w.day(), "target": -1, "reserved": 6})
	var w7 := World.new()
	w7.load_dict(VillageMap.load_default(), old)
	check(not w7.player.quests.any(func(x): return x.id == "work_for_the_manor") and w7.treasury == int(old.treasury) + 6, "v7 save: the old single manor job is dropped, its six coins back in the treasury")
	w7.dispose()
	w.dispose()


## The long-run economy corrections (owner-authorized evidence-based fixes, 2026-10-18; B7-014 to B7-017,
## B7-009; docs/release/LONG_RUN_SIMULATION.md). Every number tested is provisional.
func test_long_run_economy() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	w.player.pos = FAR_GUARDS
	# B7-015: a guard's household is provisioned whenever the shops are open
	var night: NPC = null
	var day: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard":
			if o.workplace == "night" and night == null:
				night = o
			elif o.workplace == "day" and day == null:
				day = o
	for g: NPC in [night, day]:
		var pantry: Inventory = w.households[g.household].pantry
		for f in NPCBrain.FOOD + ["log"]:
			pantry.remove(f, pantry.count(f))
		g.coins = 30
	_at_hour(w, 10.0)
	night.plan.clear()
	b._guard(night, 10.0)
	check(night.doing.begins_with("buying") and not night.plan.is_empty(), "B7-015: a guard off duty with an empty pantry goes shopping while the shops are open (%s)" % night.doing)
	day.plan.clear()
	b._guard(day, 10.0)
	check(day.doing.begins_with("buying") and not day.plan.is_empty(), "B7-015: so does a guard on the rounds (%s)" % day.doing)
	var bought := false
	for s in night.plan:
		if s.k == "do":
			bought = b.act(night, s.act, s.args)
	var hp: Inventory = w.households[night.household].pantry
	check(bought and (hp.count("wheat") > 0 or hp.count("log") > 0), "B7-015: the trip stocks the household pantry")
	_at_hour(w, 23.0)
	day.plan.clear()
	b._guard(day, 23.0)
	check(not day.doing.begins_with("buying"), "B7-015: with the shops shut a guard goes to bed, not shopping")
	var stocked: Inventory = w.households[day.household].pantry
	stocked.add("wheat", 4)
	stocked.add("log", 2)
	_at_hour(w, 10.0)
	b._guard(day, 10.0)
	check(not day.doing.begins_with("buying"), "B7-015: a guard whose household is stocked stays on the rounds")
	# B7-016: firewood can be bought from a woodcutter with logs in hand, when no trader has any
	var buyer: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "miner":
			buyer = o
			break
	for o: NPC in w.npcs:
		if o.alive and (o.job == "carpenter" or b.buy_role(o) == "merchant_raw"):
			o.inv.remove("log", o.inv.count("log"))
	var cutter: NPC = w.npcs.filter(func(o): return o.alive and o.job == "woodcutter")[0]
	cutter.inv.add("log", 3)
	for o: NPC in w.npcs:
		o.anim = "idle"
	var seller: NPC = b._seller_of("log", buyer)
	check(seller == cutter, "B7-016: with no trader holding logs a household buys firewood from a woodcutter")
	var carp: NPC = w.npcs.filter(func(o): return o.alive and o.job == "carpenter")[0]
	carp.inv.add("log", 2)
	check(b._seller_of("log", buyer) == carp, "B7-016: and from a trader first when one has them")
	check(b._seller_of("axe", buyer) == null, "B7-016: a woodcutter sells no axe")
	# B7-016: the smith sells its tools on to the goods merchant, who retails them
	var smith: NPC = w.npcs.filter(func(o): return o.alive and o.job == "smith")[0]
	var gm: NPC = w.npcs.filter(func(o): return o.alive and b.buy_role(o) == "merchant_goods")[0]
	for id in ["iron_ore", "coal", "copper_ore"]:
		smith.inv.remove(id, smith.inv.count(id))
	smith.inv.remove("axe", smith.inv.count("axe"))
	smith.inv.add("axe", 3)
	gm.inv.remove("axe", gm.inv.count("axe"))
	gm.coins = 120
	smith.plan.clear()
	b._smith(smith)
	check(smith.doing.begins_with("taking axe to") and smith.plan.size() > 0, "B7-016: a smith with spare tools takes them to the goods merchant (%s)" % smith.doing)
	var coins_all := w.total_coins()
	var sc := smith.coins
	var sold: bool = b.act(smith, "sell_to", {"buyer": gm.id, "item": "axe"})
	check(sold and gm.inv.count("axe") > 0 and smith.coins > sc and smith.coins - sc == 120 - gm.coins and w.total_coins() == coins_all, "B7-016: the merchant pays the smith for them, coins moved and none made")
	# a woodcutter without an axe buys from the merchant before the smith
	var wc: NPC = w.npcs.filter(func(o): return o.alive and o.job == "woodcutter")[1]
	wc.inv.remove("axe", wc.inv.count("axe"))
	wc.coins = 200
	smith.inv.add("axe", 1)
	wc.plan.clear()
	b._get_tool(wc, "axe")
	var step: Dictionary = wc.plan.filter(func(s): return s.k == "do")[0]
	check(int(step.args.vendor) == gm.id and wc.doing == "buying a new axe", "B7-016: a woodcutter without an axe buys it from the goods merchant first")
	w.dispose()
	test_caravan_purse()


## B7-014: the caravan is a finite regional market. It holds a purse (`caravan_float` at the start, plus
## `caravan_allowance` a day up to the float, plus what the village pays it for ore and stone) and never
## pays out a coin it does not hold.
func test_caravan_purse() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	w.player.pos = FAR_GUARDS
	var float_coins := int(GameData.b("caravan_float"))
	# what one visit adds to the purse: the allowance for the days between visits, less as the village's coins near the ceiling
	var visit := func() -> int:
		var ceiling := float(GameData.b("caravan_ceiling_per_head")) * float(w.alive_count() - w.alive_count("bandit"))
		return roundi(float(GameData.b("caravan_allowance")) * int(GameData.b("caravan_every_days")) * clampf(1.0 - float(w.total_coins()) / ceiling, 0.0, 1.0))
	var smiths: Array = w.npcs.filter(func(o): return o.alive and o.job == "smith")
	var base := w.total_coins() - w.coin_sources
	check(w.caravan_purse == float_coins, "B7-014: a new world's caravan holds its float (%d)" % float_coins)
	# surplus to sell: every smith holds 12 iron bars (cap 8, so 8 for sale at 11 coins each)
	var stock := func() -> void:
		for s: NPC in smiths:
			s.inv.add("iron_bar", 12 - s.inv.count("iron_bar"))
	stock.call()
	var coins0 := w.total_coins()
	b.caravan()
	var paid := w.total_coins() - coins0
	check(paid > 0 and paid <= int(GameData.b("caravan_coins")) and w.caravan_purse == float_coins - paid and paid == w.coin_sources, "B7-014: it pays for the surplus (%d coins) out of its purse" % paid)
	check(w.total_coins() - w.coin_sources == base, "B7-014: coins are conserved")
	# B7-007: the mine's raw output is not carried away, whatever the merchants hold above half their caps
	var raws: Array = w.npcs.filter(func(o): return o.alive and b.buy_role(o) == "merchant_raw")
	for o: NPC in raws:
		for id in NPCBrain.NOT_EXPORTED:
			o.inv.add(id, 20)
		o.inv.add("plank", 20)
	w.caravan_purse = float_coins
	var raw0 := NPCBrain.NOT_EXPORTED.map(func(id): return int(w.stats.get("exported_" + id, 0)))
	var plank0 := int(w.stats.get("exported_plank", 0))
	b.caravan()
	var raw1 := NPCBrain.NOT_EXPORTED.map(func(id): return int(w.stats.get("exported_" + id, 0)))
	check(raw0 == raw1 and int(w.stats.get("exported_plank", 0)) > plank0, "B7-007: the caravan buys the merchants' planks but none of the mine's ore, coal or stone")
	w.caravan_purse = float_coins - paid
	# an empty purse buys nothing; the allowance refills it a little each visit
	w.caravan_purse = 0
	stock.call()
	var exp0 := int(w.stats.get("exported_iron_bar", 0))
	var src0 := w.coin_sources
	var added: int = visit.call()
	b.caravan()
	var each := maxi(1, roundi(GameData.value("iron_bar") * 0.8))
	var bought := int(w.stats.get("exported_iron_bar", 0)) - exp0
	check(added > 0 and bought == added / each and w.coin_sources - src0 == bought * each and w.caravan_purse == added - bought * each, "B7-014: with an empty purse it buys only what one visit's allowance (%d) pays for (%d bars)" % [added, bought])
	# at the ceiling the region adds nothing: the village's coins cannot pass it
	w.caravan_purse = 0
	w.treasury += int(GameData.b("caravan_ceiling_per_head")) * 100
	stock.call()
	exp0 = int(w.stats.get("exported_iron_bar", 0))
	b.caravan()
	check(int(visit.call()) == 0 and w.caravan_purse == 0 and int(w.stats.get("exported_iron_bar", 0)) == exp0, "B7-014: at the ceiling the caravan adds nothing to its purse and buys nothing")
	w.treasury -= int(GameData.b("caravan_ceiling_per_head")) * 100
	# the allowance fills the purse no higher than the float
	w.caravan_purse = float_coins - 1
	for s: NPC in smiths:
		s.inv.remove("iron_bar", s.inv.count("iron_bar"))
	b.caravan()
	check(w.caravan_purse == float_coins, "B7-014: the purse never fills past the float")
	# a purse for two bars is shared by two smiths, not given to the first
	added = visit.call()
	w.caravan_purse = 2 * each - added
	stock.call()
	b.caravan()
	var sold := smiths.map(func(s): return 12 - s.inv.count("iron_bar"))
	check(smiths.size() >= 2 and sold.all(func(n): return n <= 1) and sold.reduce(func(a, c): return a + c, 0) == 2, "B7-014: a purse for two bars is shared by two smiths (%s)" % str(sold))
	# what it sells the village comes back to its purse first
	for d in w.deposits:
		d.amount = 0
	for s: NPC in smiths:
		s.inv.remove("iron_ore", s.inv.count("iron_ore"))
		s.coins = 120
	w.caravan_purse = 0
	stock.call()
	var cs0 := w.coin_sources
	var all1 := w.total_coins() - w.coin_sources
	var out0 := int(w.stats.get("caravan_coins_out", 0))
	var in0 := int(w.stats.get("caravan_coins_in", 0))
	added = visit.call()
	b.caravan()
	var spent: int = int(w.stats.get("caravan_coins_out", 0)) - out0
	var got: int = int(w.stats.get("caravan_coins_in", 0)) - in0
	check(spent > 0 and got <= spent + added and w.coin_sources - cs0 == got - spent and w.total_coins() - w.coin_sources == all1, "B7-014: imports (%d coins) refill the purse and pay for the smiths' bars first (%d); conserved" % [spent, got])
	check(w.caravan_purse == spent + added - got, "B7-014: the purse is what it took in and was allowed, less what it paid")
	# saving: the purse is kept, and an older save's caravan arrives with its float
	w.caravan_purse = 321
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(int(saved.save_version) == World.SAVE_VERSION and World.SAVE_VERSION >= 9 and int(saved.caravan_purse) == 321, "B7-014: the purse is saved (save_version %d)" % World.SAVE_VERSION)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	check(w2.caravan_purse == 321 and w2.total_coins() == w.total_coins(), "B7-014: and loaded, no coin changed")
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	old.save_version = 8
	old.erase("caravan_purse")
	var w8 := World.new()
	w8.load_dict(VillageMap.load_default(), old)
	check(w8.caravan_purse == float_coins and w8.total_coins() == w.total_coins(), "B7-014: a version 8 save's caravan arrives with its float; every village coin kept")
	w2.dispose()
	w8.dispose()
	w.dispose()
	test_manor_job_reserve()


## B7-009: a new village's treasury (270) is under ten days of obligations (460) but over three days
## (138) and a wage: paid work exists from day 0, and the 3-day reserve is still kept.
func test_manor_job_reserve() -> void:
	var w := new_world()
	var mw: ManorWork = w.manor_work
	var days := float(GameData.b("manor_job_reserve_days"))
	var due: float = w.brain.daily_obligations()
	check(w.treasury < due * float(GameData.b("treasury_reserve_days")) and w.treasury > due * days, "B7-009: the starting treasury (%d) is under the ten-day reserve and over the job reserve (%d)" % [w.treasury, roundi(due * days)])
	# the manor buys repairs and grain in its evening business; the board then has work to carry
	w.brain.reeve_day()
	var jobs: Array = mw.open_for("player")
	check(not jobs.is_empty(), "B7-009: on day 0 the board has paid work for the player (%d jobs)" % jobs.size())
	if not jobs.is_empty():
		var j: Dictionary = jobs[0]
		var t0 := w.treasury
		check(mw.take(j, "player") and w.treasury == t0 - int(j.wage), "B7-009: and takes it: the wage (%d) is set aside from the treasury" % int(j.wage))
	# the line is the reserve after the wage, exactly
	var probe := {"wage": 6}
	w.treasury = int(ceil(due * days)) + 6
	check(mw.can_fund(probe, "player"), "B7-009: a wage is funded when the treasury keeps three days of obligations after it")
	w.treasury = int(ceil(due * days)) + 5
	check(not mw.can_fund(probe, "player"), "B7-009: and not one coin under")
	w.dispose()


## The resource registry (res://data/resources.json through ResourceNodes) agrees with the world.
## Wild flowers and berry bushes (B8-015, B8-016): walkable, picked for items, bare until they regrow,
## eaten or brewed, saved, and defined as resource nodes.
func test_wild_plants() -> void:
	var w := new_world()
	var p := w.player
	var kinds := {}
	for pl in w.plants:
		kinds[pl.kind] = int(kinds.get(pl.kind, 0)) + 1
	check(kinds.has("flower") and kinds.has("redberry") and kinds.has("blueberry"), "the map has flowers, red berry bushes and blue berry bushes: %s" % str(kinds))
	var below1: Array = w.map.data.layers.filter(func(l): return l.name == "below1")[0].data
	var walk := true
	var tiled := true
	for pl in w.plants:
		walk = walk and not w.map.is_solid(Vector2i(pl.x, pl.y))
		tiled = tiled and [2656, 2657, 2658, 2659, 2660, 2662].has(int(pl.tile)) and int(below1[int(pl.y) * w.map.w + int(pl.x)]) == int(pl.tile)
	check(walk, "every plant cell is walkable")
	check(tiled, "every plant is drawn with its own tile in layer below1")
	var by := {}
	for k in kinds:
		for pl in w.plants:
			if pl.kind == k:
				by[k] = pl
				break
	var d_flower := ResourceNodes.def_for("plant", "flower")
	check(d_flower.id == "flower_patch" and ResourceNodes.def_for("plant", "redberry").id == "red_berry_bush" and ResourceNodes.def_for("plant", "blueberry").id == "blue_berry_bush", "each plant kind has its resource node")
	var fl: Dictionary = by.flower
	var cell := Vector2i(fl.x, fl.y)
	var hit := ResourceNodes.node_at(w, cell, true)
	check(not hit.is_empty() and hit.ref == fl and ResourceNodes.can_harvest(w, d_flower, fl) == "" and ResourceNodes.remaining(w, d_flower, fl) == 1, "node_at finds a ripe flower on its own cell; it can be picked")
	check(ResourceNodes.instances(w, d_flower).size() == kinds.flower, "instances lists every flower")
	var changes := []
	w.tile_changed.connect(func(c, k, v): changes.append([c, k, v]))
	var n0 := p.inv.count("flower")
	var got := w.pick_plant(fl)
	check(got == {"flower": 1} and fl.state == "picked", "picking a flower gives a flower and leaves the plant picked")
	p.inv.add("flower", int(got.flower))
	check(p.inv.count("flower") == n0 + 1 and changes.size() == 1 and changes[0][1] == "below1" and changes[0][2] == -1, "the plant's tile is removed")
	check(w.pick_plant(fl).is_empty() and ResourceNodes.can_harvest(w, d_flower, fl).contains("picked") and ResourceNodes.remaining(w, d_flower, fl) == 0, "a picked plant gives nothing and says why")
	check(w.plant_at(cell) == fl and not w.map.is_solid(cell), "a picked plant's cell is still walkable")
	# it regrows at dawn, after plant_regrow_days
	var days: Array = GameData.b("plant_regrow_days")
	check(int(fl.regrow) - w.day() >= int(days[0]) and int(fl.regrow) - w.day() <= int(days[1]), "regrows %d to %d days later (balance.json)" % [int(days[0]), int(days[1])])
	fl.regrow = w.day() + 1
	w._new_day()
	check(fl.state == "picked", "not before its day")
	fl.regrow = w.day()
	changes.clear()
	w._new_day()
	check(fl.state == "ripe" and changes.size() == 1 and changes[0][2] == int(fl.tile), "at dawn on its day the plant is ripe and its tile returns")
	# berries are food: picked, then eaten through the usual path
	for k in ["redberry", "blueberry"]:
		var bush: Dictionary = by[k]
		var item: String = "red_berries" if k == "redberry" else "blueberries"
		var g := w.pick_plant(bush)
		check(g == {item: 2}, "a %s bush gives 2 %s" % [k, item])
		p.inv.add(item, 2)
		p.hunger = 50.0
		check(GameData.item(item).type == "food" and w.player_eat(item) and p.hunger > 50.0 and p.hunger < 100.0 and p.inv.count(item) == 1, "%s can be eaten for a little hunger" % item)
	# the flower recipe: three flowers brew a herbal tonic at the stove, which heals
	var rec: Dictionary = GameData.recipes["brew_tonic"]
	check(rec.station == "stove" and rec.in.keys() == ["flower"] and int(rec.in.flower) == 3 and rec.out.keys() == ["herbal_tonic"] and int(rec.out.herbal_tonic) == 1 and GameData.recipes_at("stove").has("brew_tonic"), "brew_tonic: three flowers make a herbal tonic at the stove")
	p.inv.add("flower", 3)
	check(p.inv.has_all(rec.in) and p.inv.remove_all(rec.in) and p.inv.add("herbal_tonic", 1), "the recipe's inputs are consumed and its output made")
	p.hp = 10.0
	check(w.player_eat("herbal_tonic") and p.hp == 10.0 + float(GameData.item("herbal_tonic").heal), "a herbal tonic restores health")
	p.hp = p.hp_cap() - 1.0
	p.inv.add("herbal_tonic", 1)
	w.player_eat("herbal_tonic")
	check(p.hp == p.hp_cap(), "health never passes its cap")
	check(ResourceNodes.uses_of("flower").any(func(u): return u.kind == "recipe" and u.id == "brew_tonic") and not ResourceNodes.sources_of("flower").is_empty(), "the registry knows the flower's use and source")
	# saved: picked state and regrow day survive; an older save loads all ripe
	var bush2: Dictionary = by.redberry
	bush2.state = "picked"
	bush2.regrow = float(w.day() + 3)
	var d = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var again: Dictionary = w2.plant_at(Vector2i(bush2.x, bush2.y))
	check(again.state == "picked" and int(again.regrow) == int(bush2.regrow) and w2.plant_at(cell).state == "ripe", "picked plants are saved with their regrow day")
	d.erase("plants")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d)
	check(w3.plants.all(func(pl): return pl.state == "ripe"), "a save without plants loads with every plant ripe")
	w2.dispose()
	w3.dispose()
	# claiming ground grubs the plants up
	var fl2: Dictionary = {}
	for pl in w.plants:
		if pl.state == "ripe" and w.property.can_claim(Rect2i(pl.x - 1, pl.y - 1, 3, 3)) == "":
			fl2 = pl
			break
	check(not fl2.is_empty(), "there is clear ground with a plant on it to claim")
	if not fl2.is_empty():
		p.coins = 100000
		var parcel := w.property.claim(Rect2i(fl2.x - 1, fl2.y - 1, 3, 3), World.PLAYER)
		check(not parcel.is_empty() and w.plant_at(Vector2i(fl2.x, fl2.y)).is_empty(), "plants on claimed building ground are grubbed up")
	w.dispose()


func test_resource_registry() -> void:
	var w := new_world()
	var p := w.player
	var defs := ResourceNodes.defs()
	check(not defs.is_empty() and ResourceNodes.def("iron_seam").id == "iron_seam" and ResourceNodes.def("nope").is_empty(), "the registry loads its node definitions")
	for id in defs:
		var d: Dictionary = defs[id]
		check(d.has("range") and d.has("tool") and d.has("tool_hint") and d.has("verb") and d.has("action_label"), "%s has range, tool, tool_hint, verb and action_label" % id)
	# every deposit is a seam node; what is left is its amount
	var ok := true
	for dep in w.deposits:
		var at := ResourceNodes.node_at(w, Vector2i(dep.x, dep.y))
		ok = ok and not at.is_empty() and at.ref == dep and at.def.match.ore == dep.ore and ResourceNodes.remaining(w, at.def, dep) == int(dep.amount) \
				and ResourceNodes.instances(w, at.def).has(dep) and ResourceNodes.cell_of(w, at.def, dep) == Vector2i(dep.x, dep.y)
	check(ok and not w.deposits.is_empty(), "every deposit maps to the seam node of its ore, and remaining is its amount")
	ok = true
	for t in w.trees:
		var c := Vector2i(t.x, t.y)
		var at := ResourceNodes.node_at(w, c)
		ok = ok and not at.is_empty() and at.def.id == "tree" and at.ref == w.tree_at(c) and ResourceNodes.remaining(w, at.def, at.ref) == 4
	check(ok and ResourceNodes.instances(w, ResourceNodes.def("tree")).size() == w.trees.size(), "every tree maps to the tree node, 4 logs each while grown")
	ok = true
	for f in w.fields:
		var at := ResourceNodes.node_at(w, Vector2i(int(f.x) + 1, int(f.y) + 1))
		ok = ok and not at.is_empty() and at.def.id == "wheat_field" and at.ref == f and ResourceNodes.remaining(w, at.def, f) == int(GameData.b("field_yield"))
		ok = ok and ResourceNodes.cell_of(w, at.def, f) == Vector2i(int(f.x) + int(f.w) / 2, int(f.y) + int(f.h) / 2)
	check(ok and not w.fields.is_empty(), "every field maps to the wheat field node; remaining is its crop")
	var wild := 0
	var mapped := 0
	ok = true
	for a: Animal in w.fauna.animals:
		var d := ResourceNodes.def_for("animal", a.species)
		ok = ok and not d.is_empty() and ResourceNodes.instances(w, d).has(a) and bool(d.player_harvest) == a.wild()
		if a.wild():
			wild += 1
		var at := ResourceNodes.node_at(w, a.cell())
		if not at.is_empty() and is_same(at.ref, a):
			mapped += 1
	check(ok and wild > 0, "every animal maps to its species' node; only the wild ones are the player's to hunt")
	check(mapped > 0, "node_at finds an animal standing on the cell (%d)" % mapped)
	# can_harvest: the start kit's rusty pickaxe mines; without a pickaxe or an axe, the reason
	var dep: Dictionary = w.deposits[0]
	var seam := ResourceNodes.def_for("deposit", str(dep.ore))
	check(ResourceNodes.can_harvest(w, seam, dep) == "", "with the start kit's pickaxe a seam can be mined")
	p.inv.remove("rusty_pickaxe")
	p.tool = ""
	check(ResourceNodes.can_harvest(w, seam, dep).contains("pickaxe"), "without a pickaxe: you need one, and where to get it")
	var tree: Dictionary = w.trees[0]
	var td := ResourceNodes.def("tree")
	check(ResourceNodes.can_harvest(w, td, tree).contains("axe"), "without an axe: you need one, and where to get it")
	p.inv.add("axe")
	check(ResourceNodes.can_harvest(w, td, tree) == "", "with an axe a grown tree can be felled")
	w.fell(tree, 0)
	check(ResourceNodes.can_harvest(w, td, tree).contains("stump") and ResourceNodes.remaining(w, td, tree) == 0, "a felled tree: a stump, nothing left")
	p.inv.add("pickaxe")
	for i in int(dep.amount):
		w.mine_unit(dep)
	check(ResourceNodes.remaining(w, seam, dep) == 0 and ResourceNodes.can_harvest(w, seam, dep) == "The seam is worked out.", "a worked-out seam says so")
	var f: Dictionary = w.fields[0]
	var fd := ResourceNodes.def("wheat_field")
	check(ResourceNodes.can_harvest(w, fd, f) == "", "a ripe field can be harvested (no tool)")
	check(ResourceNodes.theft_note(w, fd, f).contains("theft") == not w.field_workers(f).is_empty(), "a worked field: taking its crop is theft")
	w.set_field(f, "tilled")
	check(ResourceNodes.can_harvest(w, fd, f) != "" and ResourceNodes.remaining(w, fd, f) == 0, "a tilled field: nothing to harvest, and why")
	var cows: Array = w.fauna.animals.filter(func(a: Animal): return a.species == "cow")
	check(not cows.is_empty() and ResourceNodes.can_harvest(w, ResourceNodes.def("cow_pen"), cows[0]).contains("keeper"), "the keeper's livestock is not the player's to take")
	var boar: Dictionary = GameData.b("animals").boar
	check(ResourceNodes.products(ResourceNodes.def("wild_boar")) == {"meat": int(boar.meat), "hide": int(boar.hide)}, "products resolve balance keys")
	# uses_of, sources_of and chain agree with recipes.json
	ok = true
	for r in GameData.recipes:
		var rec: Dictionary = GameData.recipes[r]
		for id in rec.in:
			ok = ok and ResourceNodes.uses_of(id).any(func(u): return u.kind == "recipe" and u.id == r and int(u.qty) == int(rec.in[id]))
			ok = ok and ResourceNodes.chain(id, 1).becomes.any(func(s): return s.recipe == r and s.makes == rec.out)
		for id in rec.out:
			ok = ok and ResourceNodes.sources_of(id).any(func(s): return s.kind == "recipe" and s.id == r and int(s.qty) == int(rec.out[id]))
	check(ok, "every recipe is a use of each of its inputs, a source of its outputs and a step of their chains")
	var recipe_uses := 0
	for id in GameData.items:
		for u in ResourceNodes.uses_of(id):
			if u.kind == "recipe":
				recipe_uses += 1
				ok = ok and GameData.recipes[u.id].in.has(id)
	var inputs := 0
	for r in GameData.recipes:
		inputs += GameData.recipes[r].in.size()
	check(ok and recipe_uses == inputs, "uses_of names no recipe that does not consume the item (%d)" % recipe_uses)
	var logs := ResourceNodes.chain("log", 3)
	var planks: Array = logs.becomes.filter(func(s): return s.recipe == "saw_planks")
	check(not planks.is_empty() and planks[0].then[0].item == "plank" and planks[0].then[0].becomes.any(func(s): return s.recipe == "forge_pickaxe"),
		"a real chain: tree -> log -> plank (sawhorse) -> pickaxe (anvil)")
	check(ResourceNodes.sources_of("log").any(func(s): return s.kind == "node" and s.id == "tree"), "logs come from trees")
	check(ResourceNodes.sources_of("gold_ore").any(func(s): return s.kind == "node" and s.id == "gold_seam"), "gold ore comes from the gold seam (Build 13)")
	check(ResourceNodes.sources_of("bread").any(func(s): return s.kind == "recipe") and ResourceNodes.sources_of("bread").any(func(s): return s.kind == "start_kit"), "bread: the home food table makes it (PL2-013), and the start kit has it")
	check(ResourceNodes.uses_of("iron_ore").any(func(u): return u.kind == "buyer" and u.id == "smith" and int(u.qty) == int(NPCBrain.BUYS.smith.iron_ore)), "buyers come from NPCBrain.BUYS")
	check(ResourceNodes.uses_of("stone").any(func(u): return u.kind == "building" and u.id == "house") and ResourceNodes.uses_of("log").any(func(u): return u.kind == "fuel"), "building costs and fuel are uses")
	check(ResourceNodes.uses_of("pickaxe").any(func(u): return u.kind == "tool" and u.id == "iron_seam"), "a pickaxe is the tool for the seams")
	check(ResourceNodes.sources_of("stone").any(func(s): return s.kind == "import") and ResourceNodes.sources_of("iron_ore").any(func(s): return s.kind == "import"), "caravan imports are sources")
	w.dispose()


## SaveStore (owner, 2026-10-18: protect player data): atomic, verified writes with a backup;
## damaged, newer and missing saves told apart; interrupted and failed writes lose nothing.
func test_save_store() -> void:
	var dir := "user://test_saves/run_tests"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(f)))
	var path := dir.path_join("save1.json")
	var raw := func(p: String) -> String: return FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else "<missing>"
	var put := func(p: String, text: String) -> void:
		var f := FileAccess.open(p, FileAccess.WRITE)
		f.store_string(text)
		f.close()
	SaveStore.fail_at = ""
	check(SaveStore.inspect(path, 8, 0).state == "missing", "no file: missing")
	var a := '{"save_version": 8, "n": 1}'
	var b := '{"save_version": 8, "n": 2}'
	check(SaveStore.write_text(path, a).ok and raw.call(path) == a and not FileAccess.file_exists(path + ".tmp"), "a save is written whole, with no temp file left")
	check(SaveStore.write_text(path, b).ok and raw.call(path) == b and raw.call(path + ".bak") == a, "the next save keeps the previous one as the backup")
	check(SaveStore.inspect(path, 8, 0).state == "ok" and int(SaveStore.inspect(path, 8, 0).data.n) == 2, "a good save reads back")
	# every failing step leaves the save and the backup as they were
	for step in ["open", "write", "verify", "backup", "replace"]:
		SaveStore.fail_at = step
		var r: Dictionary = SaveStore.write_text(path, '{"save_version": 8, "n": 3}')
		check(not r.ok and r.reason != "" and raw.call(path) == b and raw.call(path + ".bak") == a and not FileAccess.file_exists(path + ".tmp"), "a write failing at '%s' changes nothing (%s)" % [step, r.reason])
	SaveStore.fail_at = ""
	# an interrupted earlier write (a stale temp file) is ignored and replaced
	put.call(path + ".tmp", '{"save_version": 8, "n": 4')
	check(SaveStore.inspect(path, 8, 0).state == "ok" and int(SaveStore.inspect(path, 8, 0).data.n) == 2, "a half-written temp file does not affect the save")
	check(SaveStore.write_text(path, a).ok and raw.call(path) == a and not FileAccess.file_exists(path + ".tmp"), "and the next save replaces it")
	# what cannot be used is told apart, with reasons
	for bad in ['{"save_version": 8, "n": ', "", "[1, 2]", '{"n": 1}', "not json at all"]:
		put.call(path, bad)
		var st: Dictionary = SaveStore.inspect(path, 8, 0)
		check(st.state == "unreadable" and st.reason != "", "unreadable: %s -> %s" % [bad.left(20), st.reason])
	put.call(path, '{"save_version": 9}')
	var nw: Dictionary = SaveStore.inspect(path, 8, 0)
	check(nw.state == "newer" and nw.version == 9 and nw.reason.contains("newer version"), "a later version's save is 'newer': %s" % nw.reason)
	# a save from before the village was rebuilt (generator v6, Build 8) is 'older': refused, kept unchanged, never written over
	check(SaveStore.MIN_VERSION <= World.SAVE_VERSION and World.SAVE_VERSION >= 14 and SaveStore.MIN_VERSION == 14, "saves older than the rebuilt village are refused (reads %d to %d)" % [SaveStore.MIN_VERSION, World.SAVE_VERSION])
	var old_text := '{"save_version": %d, "n": 7}' % (SaveStore.MIN_VERSION - 1)
	put.call(path, old_text)
	var og: Dictionary = SaveStore.inspect(path, World.SAVE_VERSION)
	check(og.state == "older" and og.version == SaveStore.MIN_VERSION - 1 and og.reason.contains("older version"), "an older version's save is 'older': %s" % og.reason)
	check(SaveStore.inspect(path, World.SAVE_VERSION, 0).state == "ok", "(the tests of the file handling read old versions with min_version 0)")
	var kept_old := SaveStore.preserve(path, og.state)
	check(kept_old != "" and raw.call(kept_old) == old_text and not FileAccess.file_exists(path) and kept_old.get_file().begins_with("save1.older-"), "the old save is kept unchanged as %s" % kept_old.get_file())
	put.call(path, '{"save_version": %d, "n": 8}' % World.SAVE_VERSION)
	check(SaveStore.inspect(path, World.SAVE_VERSION).state == "ok", "a current save reads")
	# an existing save that is not readable is never replaced by write_text
	put.call(path, "garbage")
	check(not SaveStore.write_text(path, a).ok and raw.call(path) == "garbage", "write_text refuses to replace a save it cannot read")
	# preserve moves it aside, bytes unchanged
	var kept := SaveStore.preserve(path, "unreadable")
	check(kept != "" and raw.call(kept) == "garbage" and not FileAccess.file_exists(path) and kept.get_file().begins_with("save1.unreadable-"), "preserve keeps it unchanged as %s" % kept.get_file())
	check(SaveStore.write_text(path, a).ok and raw.call(kept) == "garbage", "after which saving works and leaves the kept file alone")
	check(SaveStore.any_exists(path), "any_exists sees the save")
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(f)))


## The Build 8 village (generator v6): the mine's seams and the sawmill can be reached on foot with the village's own
## path-finding, personal chests stand by their owners, no tree tile is left in any layer, and nothing
## stands on top of anything else.
func test_village_layout() -> void:
	var w := new_world()
	var m: VillageMap = w.map
	var hub := Vector2i(int(m.data.spawns.player[0]), int(m.data.spawns.player[1]))
	var next_to := func(c: Vector2i) -> bool:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not m.is_solid(c + d) and not m.find_path(hub, c + d).is_empty():
				return true
		return false
	var trees := {}
	for t in w.trees:
		trees[Vector2i(int(t.x), int(t.y))] = true
	for d in w.deposits:
		var c := Vector2i(int(d.x), int(d.y))
		check(next_to.call(c) and not trees.has(c), "B8-004: the %s seam at %s is on open ground and can be reached on foot" % [d.ore, c])
	# B8-002: every interior floor cell (and the tavern's open-air kitchen) shows a floor tile, never plain grass
	var vw: int = int(m.data.w)
	var floors: Array = (m.data.layers as Array).filter(func(l): return l.z == "ground" and l.name != "ground0")
	var bare := 0
	var cells_n := 0
	var floor_cells: Array = []
	for id in w.buildings:
		var it = w.buildings[id].get("interior")
		if it != null:
			for c in it.floor:
				floor_cells.append(Vector2i(int(c[0]), int(c[1])))
	floor_cells.append(Vector2i(52, 47))
	for c in floor_cells:
		cells_n += 1
		if not floors.any(func(l): return int(l.data[c.y * vw + c.x]) >= 0 and int(l.data[c.y * vw + c.x]) < 100000):
			bare += 1
	check(cells_n > 100 and bare == 0, "B8-002: every interior floor cell has a floor tile, not grass (%d bare of %d)" % [bare, cells_n])
	var saws: Array = w.stations_of("sawhorse")
	check(saws.size() == 1 and w.buildings[w.stations[saws[0]].building].get("name", "") == "Sawmill", "B8-028: one sawhorse, in the building named Sawmill")
	var use: Vector2i = w.station_use(saws[0])
	check(not m.is_solid(use) and not m.find_path(hub, use).is_empty() and not (m.data.road as Array).any(func(c): return Vector2i(int(c[0]), int(c[1])) == use), "the sawhorse's use cell is free and reachable, and no road (guard post) cell")
	check(w.guard_posts.all(func(c: Vector2i) -> bool: return c != use), "no guard stands where the sawyer works")
	var cart: Vector2i = w.station_use(w.stations_of("mine_cart")[0])
	check(not m.find_path(hub, cart).is_empty(), "the mine cart can be reached")
	# personal chests: by their own building, and by no other
	var stalls := {}
	for s in m.data.stalls:
		stalls[s.id] = s
	var far := 0
	for c in w.containers:
		if c.kind == "table":
			continue
		var cell := Vector2i(c.x, c.y)
		if stalls.has(c.at):
			var s: Dictionary = stalls[c.at]
			far += 0 if absi(cell.x - int(s.x)) <= 2 and absi(cell.y - int(s.y)) <= 1 else 1
			continue
		var b: Dictionary = w.buildings[c.at]
		var own := Rect2i(int(b.x) - 1, int(b.y) - 1, int(b.w) + 2, int(b.h) + 3)
		var other := false
		for id in w.buildings:
			if id != c.at and Rect2i(int(w.buildings[id].x), int(w.buildings[id].y), int(w.buildings[id].w), int(w.buildings[id].h)).has_point(cell):
				other = true
		far += 0 if own.has_point(cell) and not other else 1
	check(far == 0, "B8-017: every personal chest is in or directly beside its owner's building (%d are not)" % far)
	# no tree tile in any tile layer
	var crowns := {}
	for pr in m.data.tiles.canopy:
		crowns[int(pr[0])] = true
		crowns[int(pr[1])] = true
	var stray := 0
	for lay in m.data.layers:
		if lay.z == "ground":
			continue
		for v in lay.data:
			if int(v) >= 0 and int(v) < 100000 and (crowns.has(int(v)) or (int(v) % 220 >= 16 and int(v) % 220 <= 23 and int(v) / 220 <= 11)):
				stray += 1
	check(stray == 0 and m.decor_trees().is_empty(), "B8-003: no tree tile is left in any layer (%d found)" % stray)
	# nothing stands on anything: building cells, trees, stations, deposits, fields, pens
	var taken := {}
	var overlaps := [0]
	var claim := func(cell: Vector2i) -> void:
		if taken.has(cell):
			overlaps[0] += 1
		taken[cell] = true
	for d in w.deposits:
		claim.call(Vector2i(int(d.x), int(d.y)))
	for t in trees:
		claim.call(t)
	for f in w.fields:
		for j in int(f.h):
			for i in int(f.w):
				claim.call(Vector2i(int(f.x) + i, int(f.y) + j))
	check(overlaps[0] == 0, "no seam, tree and field share a cell (%d overlaps)" % overlaps[0])
	var roads := {}
	for c in m.data.road:
		roads[Vector2i(int(c[0]), int(c[1]))] = true
	check(w.deposits.all(func(d): return not roads.has(Vector2i(int(d.x), int(d.y)))), "no seam lies on a road")


## Every building can be walked into and out of (Build 8 report: trapped just inside a door): from
## each outside door, a walk of straight steps (the player cannot squeeze through a diagonal gap)
## reaches every inner door, and the outside door reaches the open village (the market well).
func test_doorways() -> void:
	var w := new_world()
	var m: VillageMap = w.map
	var reach := func(from: Vector2i, limit: int) -> Dictionary:
		var seen := {from: true}
		var q := [from]
		while not q.is_empty() and seen.size() < limit:
			var c: Vector2i = q.pop_front()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if not seen.has(n) and not m.is_solid(n):
					seen[n] = true
					q.append(n)
		return seen
	var town: Dictionary = reach.call(Vector2i(int(m.data.buildings[0].door[0]), int(m.data.buildings[0].door[1])), 100000)
	for b in m.data.buildings:
		var out := Vector2i(int(b.door[0]), int(b.door[1]))
		check(not m.is_solid(out) and town.has(out), "%s (%s): its door is open and joined to the village" % [b.id, b.type])
		if not b.has("interior"):
			continue
		var inner := (b.interior.doors as Array).map(func(c): return Vector2i(int(c[0]), int(c[1])))
		check(inner.any(func(c): return town.has(c)), "%s (%s): walking in through a doorway reaches inside %s" % [b.id, b.type, inner])
		# every bed, table, hearth and chest inside is used from a cell reached on foot (B8-019: furniture traps)
		var cut := (b.interior.get("spots", []) as Array).filter(func(sp): return not town.has(Vector2i(int(sp.use[0]), int(sp.use[1]))))
		check(cut.is_empty(), "%s (%s): every spot inside is reachable %s" % [b.id, b.type, cut.map(func(sp): return "%s@%s" % [sp.kind, sp.use])])
	# every workstation's place of use is reached on foot
	var cut_st := []
	for id in w.stations:
		var u: Vector2i = w.station_use(id)
		if not town.has(u):
			cut_st.append("%s %s@%s" % [id, w.stations[id].type, u])
	check(cut_st.is_empty(), "every workstation can be reached %s" % [cut_st])


## Crops end cleanly inside every field (B8-017: the right and bottom edges showed half plants because
## one left-edge tile was drawn on every cell). No field art lies outside a field rectangle, each
## field cell draws from its state's 4x4 edge set, and the edge cells use the edge tiles: for the
## village's fields and for fields of other sizes, in every state.
func test_field_edges() -> void:
	var w := new_world()
	var m: VillageMap = w.map
	var cols := int(m.data.atlases[0].columns)
	var sets := {}                      # tile id -> state it belongs to
	for state in ["tilled", "growing", "ripe"]:
		for row in 4:
			for col in 4:
				sets[int(m.data.tiles.field[state]) + row * cols + col] = state
	var rects: Array[Rect2i] = []
	for f in m.data.fields:
		rects.append(Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)))
	var path1: Dictionary = (m.data.layers as Array).filter(func(l): return l.name == "path1")[0]
	var stray := 0
	var painted := 0
	for i in (path1.data as Array).size():
		var v := int(path1.data[i])
		if v >= 0 and sets.has(v):
			var cell := Vector2i(i % int(m.w), i / int(m.w))
			painted += 1
			if not rects.any(func(r: Rect2i): return r.has_point(cell)):
				stray += 1
	check(stray == 0 and painted == rects.reduce(func(a, r: Rect2i): return a + r.size.x * r.size.y, 0), "generated field art lies exactly on the field rectangles (%d stray of %d)" % [stray, painted])
	for state in ["tilled", "growing", "ripe"]:
		var base := int(m.data.tiles.field[state])
		var cells := {}
		var on_tile := func(cell: Vector2i, kind: String, value: int):
			if kind == "field":
				cells[cell] = value
		w.tile_changed.connect(on_tile)
		for f in w.fields:
			w.set_field(f, state)
		w.tile_changed.disconnect(on_tile)
		for f in w.fields:
			for j in int(f.h):
				for i in int(f.w):
					var cell := Vector2i(int(f.x) + i, int(f.y) + j)
					var got := int(cells.get(cell, -1))
					var col := (got - base) % cols
					var row := (got - base) / cols
					check(sets.get(got, "") == state, "%s %s cell %s draws from the %s set" % [state, f.id, cell, state])
					check((i == 0) == (col == 1) and (i == int(f.w) - 1) == (col == 3) and (j == 0) == (row == 0) and (j == int(f.h) - 1) == (row == 2), "%s %s cell %s: edge tiles exactly on the edges" % [state, f.id, cell])
	# any size: one cell, a strip, a block
	for size in [Vector2i(1, 1), Vector2i(1, 5), Vector2i(7, 1), Vector2i(2, 2), Vector2i(3, 3), Vector2i(11, 6)]:
		for j in size.y:
			for i in size.x:
				var t := World.field_cell_tile(0, size.x, size.y, i, j, cols)
				check(t % cols == (0 if size.x == 1 else (1 if i == 0 else (3 if i == size.x - 1 else 2))), "%s: column of (%d,%d)" % [size, i, j])
				check(t / cols == (3 if size.y == 1 else (0 if j == 0 else (2 if j == size.y - 1 else 1))), "%s: row of (%d,%d)" % [size, i, j])


## Nobody plays the work animation without real work (Build 8 report: villagers swinging tools at
## nothing): a day of village life, sampled, finds every working villager doing an act.
func test_work_has_purpose() -> void:
	var w := new_world()
	var idle_work := {}
	for step in 2880:
		w.update(0.5)
		if step % 40 != 0:
			continue
		for n: NPC in w.npcs:
			# a work step (not the walk that follows one, while the animation catches up) with no act
			if n.alive and n.anim == "work" and not n.plan.is_empty() and str(n.plan[0].get("k", "")) == "work" and str(n.plan[0].get("act", "")) == "":
				idle_work[n.job + ": " + n.doing] = true
	check(idle_work.is_empty(), "every villager swinging a tool is doing real work %s" % [idle_work.keys()])


## Children's pockets are never picked (owner, B8-010).
func test_no_child_pickpocket() -> void:
	var w := new_world()
	var kids := w.npcs.filter(func(n): return n.alive and n.role == "child")
	check(not kids.is_empty(), "the village has children")
	if kids.is_empty():
		return
	var k: NPC = kids[0]
	var c0 := k.coins
	var r := w.pickpocket(k)
	check(not r.ok and k.coins == c0 and w.player.crimes.is_empty(), "picking a child's pocket is refused: %s" % r.text)


## Every asset pack in the project and every source of imported art is credited (owner rule).
func test_credits() -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	var credited := {}
	for p in c.packs:
		check(str(p.creator) != "" and str(p.packs) != "", "a credit names its creator and packs: %s" % p.packs)
		for src in p.sources:
			credited[str(src)] = true
	for src in c.not_assets:
		credited[str(src)] = true
	var prov = JSON.parse_string(FileAccess.get_file_as_string("res://assets/PROVENANCE.json"))
	var holder = prov.get("files", prov) if prov is Dictionary else prov
	var entries: Array = holder if holder is Array else (holder as Dictionary).values()
	var missing := {}
	for f in entries:
		var src := str(f.get("source_zip", f.get("zip", f.get("source", ""))))
		if src != "" and not credited.has(src):
			missing[src] = true
	var root := ProjectSettings.globalize_path("res://").path_join("..")
	for name in DirAccess.get_files_at(root):
		if name.ends_with(".zip") or name.ends_with(".unitypackage"):
			if not credited.has(name):
				missing[name] = true
	for name in DirAccess.get_directories_at(root):
		if name in ["16x16 Assorted RPG Icons (partial)", "Flat Game UI Icon Pack", "MiniFolks Forest Animals"] and not credited.has(name):
			missing[name] = true
	check(missing.is_empty(), "every asset pack and imported-art source is credited %s" % [missing.keys()])


## B8-007: a villager's work step shows the matching tool (INT-112)
func test_polish_work_looks() -> void:
	var w := new_world()
	var n: NPC = w.npcs[0]
	var expect := {"mine": ["swing", "pickaxe"], "chop": ["swing", "axe"], "mj_step": ["swing", "hammer"],
		"hunt": ["swing", "rusty_sword"], "harvest": ["gather", ""], "sow": ["gather", ""]}
	for act in expect:
		n.plan = [w.brain.work(10, act, {}, "work")]
		check(w.brain.work_look(n) == expect[act], "B8-007: a villager's %s shows %s" % [act, str(expect[act])])
	var anvil: String = w.stations_of("anvil")[0]
	n.plan = [w.brain.work(10, "craft", {"station": anvil, "recipe": "forge_pickaxe"}, "work")]
	check(w.brain.work_look(n) == ["swing", "hammer"], "B8-007: smithing shows the hammer")
	var oven: String = w.stations_of("oven")[0]
	n.plan = [w.brain.work(10, "craft", {"station": oven, "recipe": "roast_meat"}, "work")]
	check(w.brain.work_look(n) == ["gather", ""], "B8-007: cooking shows no tool")
	n.plan = []
	check(w.brain.work_look(n)[1] == "", "B8-007: no tool when not working")
	w.dispose()


## PL2-004: rabbits give a pelt and chickens feathers; the pelt is tanned or sold (INT-113, INT-114)
func test_polish_game_leftovers() -> void:
	var w := new_world()
	var day := 1440.0
	var rabbit := w.fauna.spawn("woods_w", "rabbit", "m", null)
	var chicken := w.fauna.spawn("woods_w", "chicken", "m", null)
	rabbit.born = w.minutes - 40.0 * day
	chicken.born = w.minutes - 40.0 * day
	var rbag := w.fauna.kill(rabbit)
	var cbag := w.fauna.kill(chicken)
	check(rbag.count("rabbit_pelt") == 1 and rbag.count("meat") >= 1 and rbag.count("feather") == 0, "PL2-004: an adult rabbit gives meat and a pelt")
	check(cbag.count("feather") == 2 and cbag.count("rabbit_pelt") == 0, "PL2-004: an adult chicken gives feathers")
	var kit := w.fauna.spawn("woods_w", "rabbit", "m", null)
	check(w.fauna.kill(kit).count("rabbit_pelt") == 0, "PL2-004: a young rabbit gives no pelt")
	var rec: Dictionary = GameData.recipes["tan_pelts"]
	check(rec.station == "workbench" and int(rec["in"].get("rabbit_pelt", 0)) == 2 and int(rec.out.get("leather", 0)) == 1, "PL2-004: two pelts tan to leather at the workbench")
	for id in ["rabbit_pelt", "feather"]:
		check(GameData.items.has(id) and FileAccess.file_exists("res://assets/icons/%s.png" % id), "PL2-004: %s is an item with an icon" % id)
	check(NPCBrain.OUTLETS.has("rabbit_pelt") and NPCBrain.OUTLETS.has("feather") and NPCBrain.BUYS.merchant_goods.has("feather"), "PL2-004: pelts and feathers have buyers")
	w.dispose()
