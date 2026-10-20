extends SceneTree
## EQ-07, HOUSE-01..07 and FAM-01 (owner directive 2026-10-20, docs/directives/2026-10-20_housing_succession_adoption.md):
## a household recognizes a housing need and keeps it as a goal with a plan and the reason it waits; it
## saves (no courting gifts) instead of needing the whole price first; the responsible adult (a surviving
## parent, of either sex) decides and builds; materials the household holds are used and the rest bought,
## none appear from nothing; building waits out a shortage and resumes; hunger comes before carrying.
## The family mechanics of FAM-02..06 (orphans, adoption) are not implemented and not tested here. Run:
##   godot --headless --path game --script res://tests/housing_test.gd

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
	test_crowding_is_a_goal()
	test_saving_before_the_full_price()
	test_responsible_adult_after_a_death()
	test_mother_builds_with_own_and_bought_materials()
	test_shortage_then_resume()
	test_hunger_before_carrying()
	test_couples_of_either_sex()
	test_forge_buys_imported_ore()
	test_founder_who_pairs_keeps_building()
	test_tool_less_worker()
	test_axe_bought_to_take_up_woodcutting()
	test_left_trade_post_opens()
	test_bed_sharing()
	test_quarters_on_an_original_house()
	test_sleeping_loft()
	test_housing_options_weighed()
	test_small_room()
	test_baby_while_lodging()
	test_family_helps_builder()
	test_builder_makes_timber()
	test_caravan_keeps_needed_tools()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func run_days(w: World, days: int) -> void:
	for d in days:
		for m in 1440:
			w.update(0.5)
			w.player.hunger = 100.0


## A household of a couple and their children, made crowded by births (owner: births need no bed).
func crowded_family(w: World) -> int:
	var c := w.construction
	for hh in w.households:
		var h := int(hh.id)
		var ad: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "adult")
		if h < 3 or ad.size() != 2 or ad[0].partner != ad[1].id:
			continue
		var mom: NPC = ad[0] if ad[0].sex == "female" else ad[1]
		while not c.crowded(h):
			Life.birth(w, mom, w.npc(mom.partner), h)
		return h
	return -1


func test_crowding_is_a_goal() -> void:
	var w := new_world()
	var c := w.construction
	var h := crowded_family(w)
	check(h >= 0 and c.crowded(h), "a family grows past its beds (HOUSE-01: the need comes from the household's real state)")
	c.daily()
	var g: Dictionary = c.housing_goals(h).get("crowded", {})
	check(not g.is_empty() and int(g.since) == w.day(), "the household recognizes it and keeps a housing goal (%s)" % [g])
	check(int(g.get("by", -1)) == c.responsible_adult(h).id, "the goal is its responsible adult's")
	check(str(g.get("why", "")) != "" or str(w.households[h].get("build", "")) != "", "and says what it waits on, or is being built (%s)" % g.get("why", ""))
	c.daily()
	check(int(c.housing_goals(h).crowded.since) == int(g.since), "the goal lasts from day to day; it is not made anew")
	# the need gone (the extra members gone), the goal goes with it
	for o: NPC in w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "child"):
		w.kill(o, "fever")
	c.daily()
	check(not c.crowded(h) and c.housing_goals(h).is_empty(), "when the house is no longer crowded the goal ends")


## HOUSE-03/04: a grown child who must leave but whose family cannot yet pay for a start keeps the goal and
## saves; a household putting money by buys no courting gifts.
func test_saving_before_the_full_price() -> void:
	var w := new_world()
	var c := w.construction
	var Y := float(GameData.b("calendar").year_days) * 1440.0
	var kid: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "child" and n.household >= 3 and c._grown_child(n):
			n.born = w.minutes - 20.0 * Y
			n.role = "adult"
			if c._may_found(n):
				kid = n
				break
	check(kid != null, "a child grows up at home")
	if kid == null:
		return
	var h := kid.household
	var mom: NPC = w.npc(kid.mother) if kid.mother >= 0 else w.npc(kid.father)
	while not c.crowded(h):
		Life.birth(w, mom, w.npc(mom.partner) if mom.partner >= 0 else null, h)
	for o: NPC in w.brain._members(h):
		o.coins = 0
	kid.coins = 30
	var n_hh := w.households.size()
	c.daily()
	var g: Dictionary = c.housing_goals(h).get("crowded", {})
	check(w.households.size() == n_hh and kid.household == h, "with too little put by nobody leaves yet")
	check(str(g.get("plan", "")) == "split" and int(g.get("cost", 0)) > 0 and int(g.get("short", 0)) > 0, "but the goal stands: a split, its start cost, and what is still to save above what the family keeps to live on (%s)" % [g])
	check(c.saving_for_home(kid), "the household is saving for it")
	# courting gifts wait while the household saves
	var friend: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household != h and n != kid:
			friend = n
			break
	var t := w.relations.tie(kid.id, friend.id)
	t.friends = true
	t.regard = 50.0
	kid.coins = 100
	var sk: Dictionary = Relations.cfg().seek
	var chance := float(sk.chance)
	sk.chance = 1.0
	w.minutes = float(w.day()) * 1440.0 + 18.0 * 60.0
	var planned: bool = w.brain._plan_seek_company(kid)
	sk.chance = chance
	check(planned and not JSON.stringify(kid.plan).contains("buy_from"), "a villager saving for a home spends the evening with a friend but buys no gift")
	# with the coins the start needs, the grown child leaves to found a household
	kid.coins = int(g.cost) + c._keep(h, w.brain._members(h).size() - 1) + 50
	c.daily()
	check(kid.household == n_hh, "once enough is put by, the grown child founds a household of their own")


## FAM-01: when one parent dies, the other is the household's responsible adult, either way round.
func test_responsible_adult_after_a_death() -> void:
	for dies in ["male", "female"]:
		var w := new_world()
		var c := w.construction
		var h := crowded_family(w)
		var parents: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "adult")
		var gone: NPC = parents[0] if parents[0].sex == dies else parents[1]
		var left: NPC = parents[1] if gone == parents[0] else parents[0]
		w.kill(gone, "fever")
		check(c.responsible_adult(h) == left, "the %s dies: the %s left decides for the household" % ["father" if dies == "male" else "mother", "mother" if dies == "male" else "father"])
		c.daily()
		var g: Dictionary = c.housing_goals(h).get("crowded", {})
		check(g.is_empty() or int(g.by) == left.id, "and any housing goal is theirs")


## HOUSE-02/04/05: a widowed mother whose household has no home of its own starts a house herself, carries
## the materials it holds, buys the rest, and finishes it; every item delivered came from the household's
## store or was bought from a seller (none from nothing).
func test_mother_builds_with_own_and_bought_materials() -> void:
	var w := new_world(2)
	var c := w.construction
	var h := crowded_family(w)
	var parents: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "adult")
	var mom: NPC = parents[0] if parents[0].sex == "female" else parents[1]
	w.kill(w.npc(mom.partner), "fever")
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	check(c.responsible_adult(h) == mom, "the widowed mother is responsible for the household")
	# the household lodges without a home of its own (its house let go back to the manor's ground)
	var pantry: Inventory = hh.pantry
	pantry.add("stone", 20)
	var home := str(hh.home)
	var plan := c._home_plan(1 << 20, w.building_door(home), ref)
	if plan.has("house"):
		check(true, "(an empty house is on the market: this world would buy it rather than build; skipping)")
		return
	var rect: Rect2i = plan.rect if plan.has("rect") else Rect2i()
	var p: Dictionary = plan.plot if plan.has("plot") else c.place("house", rect, ref)
	if plan.has("plot"):
		w.property.buy(p, ref)
		w.start_site(p, "house", ref)
	hh.build = str(p.id)
	for o: NPC in w.brain._members(h):
		o.coins = 0
	mom.coins = 200
	var need0: Dictionary = p.site.need.duplicate()
	var bought0 := {}
	var held0 := {}
	var made0 := {}
	for id in need0:
		bought0[id] = int(w.stats.get("helper_bought_" + str(id), 0))
		held0[id] = int(w.stats.get("helper_took_" + str(id), 0))
		made0[id] = int(w.stats.get("builder_own_" + str(id), 0))
	var carriers := {}
	for d in 20:
		for m in 1440:
			w.update(0.5)
			w.player.hunger = 100.0
			for k in c.contracts:
				if str(k.site) == str(p.id):
					carriers[int(k.worker)] = true
		if p.site.get("done", false):
			break
	check(p.site.get("done", false), "the house is finished (%s still needed)" % [p.site.get("need", {})])
	check(carriers.has(mom.id), "the mother carried for it herself (carriers %s)" % [carriers.keys()])
	check(pantry.count("stone") == 0, "the stone the household held went into it")
	var free := []
	for id in need0:
		var bought := int(w.stats.get("helper_bought_" + str(id), 0)) - int(bought0[id])
		var own := int(w.stats.get("helper_took_" + str(id), 0)) - int(held0[id])
		var made := int(w.stats.get("builder_own_" + str(id), 0)) - int(made0[id])    # felled and sawn by the builder (HOUSE-04)
		if bought + own + made < int(need0[id]):    # what was carried back unused may make it more, never less
			free.append("%s: %d delivered, %d taken from the store, %d bought, %d the builder's own" % [id, int(need0[id]), own, bought, made])
	check(free.is_empty(), "every material delivered was taken from the household's store, bought or made by the builder, none from nothing %s" % [free])
	check(str(hh.home) == "house_" + str(p.id) or str(hh.home) == home, "the household has its house")


## HOUSE-05: a shortage stops the work without losing it; the work resumes when goods are on sale again.
func test_shortage_then_resume() -> void:
	var w := new_world(3)
	var c := w.construction
	var h := crowded_family(w)
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	var rect := c.find_ground("house", w.building_door(str(hh.home)), ref)
	var p := c.place("house", rect, ref)
	check(not p.is_empty(), "a household marks out a house")
	if p.is_empty():
		return
	hh.build = str(p.id)
	c.responsible_adult(h).coins += 400
	var held := {}                                 # every plank for sale set aside: a shortage
	var aside := Inventory.new()
	var take_planks := func() -> void:
		for o: NPC in w.npcs:
			if o.alive and c._sells(o, "plank") and o.inv.count("plank") > 0:
				held[o.id] = int(held.get(o.id, 0)) + o.inv.count("plank")
				aside.add("plank", o.inv.count("plank"))
				o.inv.remove("plank", o.inv.count("plank"))
	take_planks.call()
	for k in c.contracts:                          # and none already bought and on the way
		if str(k.site) == str(p.id):
			aside.add("plank", (k.load as Inventory).count("plank"))
			(k.load as Inventory).remove("plank", (k.load as Inventory).count("plank"))
	for step in 3 * 1440:
		w.update(0.5)
		w.player.hunger = 100.0
		if step % 20 == 0:
			take_planks.call()
	check(not p.site.get("done", false) and int(p.site.need.get("plank", 0)) > 0, "with no planks for sale the house cannot be finished")
	check(str(hh.get("build", "")) == str(p.id), "but the site and what was delivered stay")
	for id in held:
		w.npc(int(id)).inv.add("plank", int(held[id]))
	for d in 15:
		run_days(w, 1)
		if p.site.get("done", false):
			break
	check(p.site.get("done", false), "planks on sale again: the building resumes and is finished (%s left)" % [p.site.get("need", {})])


## HOUSE-05: hunger comes before the day's carrying.
func test_hunger_before_carrying() -> void:
	var w := new_world()
	var c := w.construction
	var h := crowded_family(w)
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	var p := c.place("house", c.find_ground("house", w.building_door(str(hh.home)), ref), ref)
	hh.build = str(p.id)
	var by := c.responsible_adult(h)
	by.coins += 300
	w.minutes = float(w.day()) * 1440.0 + 10.0 * 60.0
	check(c.hire(ref, by, p, 200) == "", "the responsible adult takes a day to carry for the new house")
	by.inv.add("bread", 2)
	by.hunger = float(GameData.b("eat_below")) - 20.0
	w.brain.decide(by)
	check(not str(by.doing).contains("building site"), "a hungry builder eats first (doing: %s)" % by.doing)
	by.hunger = 100.0
	w.brain.decide(by)
	check(str(by.doing).contains("building site") or str(by.doing).contains("waiting for building"), "fed, they carry (doing: %s)" % by.doing)


## HOUSE-02: two partners of the same sex who live apart want a home of their own, as any couple does.
func test_couples_of_either_sex() -> void:
	var w := new_world()
	var c := w.construction
	var a: NPC = null
	var b: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner < 0 and c._may_found(n):
			if a == null:
				a = n
			elif b == null and n.sex == a.sex and n.household != a.household and not Life.kin(a.id, a.mother, a.father, n.id, n.mother, n.father):
				b = n
	check(a != null and b != null, "two single adults of the same sex in different households")
	if a == null or b == null:
		return
	Life._link_partners(a, b)
	var pairs: Array = c.couples_needing_home().filter(func(pr) -> bool: return (pr[0] == a and pr[1] == b) or (pr[0] == b and pr[1] == a))
	check(pairs.size() == 1, "they are a couple needing a home, counted once")


## EQ-07: building timber needs axes, axes need iron. Once the mine is worked out the caravan's ore and coal
## go to the raw-goods merchant (B7-007); the smith buys them there, or no axe is ever made again.
func test_forge_buys_imported_ore() -> void:
	var w := new_world()
	var smith: NPC = w.brain._first_with_job("smith")
	var raw: NPC = null
	for o: NPC in w.npcs:
		if o.alive and w.brain.buy_role(o) == "merchant_raw":
			raw = o
			break
	check(smith != null and raw != null, "the village has a smith and a raw-goods merchant")
	for id in ["iron_ore", "coal", "iron_bar", "copper_ore"]:
		smith.inv.remove(id, smith.inv.count(id))
	smith.coins = 200
	raw.inv.add("coal", 6)
	raw.inv.add("iron_ore", 10)
	w.minutes = float(w.day()) * 1440.0 + 10.0 * 60.0
	var coal0 := raw.inv.count("coal")
	w.brain._smith(smith)
	check(JSON.stringify(smith.plan).contains("buy_from") and str(smith.doing).contains("coal"), "a smith with no ore or coal goes to buy coal from the merchant (doing: %s)" % smith.doing)
	w.brain.act(smith, "buy_from", {"vendor": raw.id, "item": "coal", "qty": 2})
	w.brain._smith(smith)
	w.brain.act(smith, "buy_from", {"vendor": raw.id, "item": "iron_ore", "qty": 4})
	check(smith.inv.count("coal") == 2 and smith.inv.count("iron_ore") == 4 and raw.inv.count("coal") == coal0 - 2, "and the iron ore after it, paid for, from the merchant's stock")
	w.brain._smith(smith)
	check(str(smith.doing).contains("smelt") or JSON.stringify(smith.plan).contains("smelt_iron"), "then smelts (doing: %s)" % smith.doing)


## EQ-07: a founder building their house who then pairs is not pulled into the partner's home; the partner
## joins the founding household and the site goes on (it was abandoned for good before).
func test_founder_who_pairs_keeps_building() -> void:
	var w := new_world()
	var c := w.construction
	var Y := float(GameData.b("calendar").year_days) * 1440.0
	var kid: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "child" and n.household >= 3 and c._grown_child(n):
			n.born = w.minutes - 20.0 * Y
			n.role = "adult"
			if c._may_found(n):
				kid = n
				break
	var h := kid.household
	var mom: NPC = w.npc(kid.mother) if kid.mother >= 0 else w.npc(kid.father)
	while not c.crowded(h):
		Life.birth(w, mom, w.npc(mom.partner) if mom.partner >= 0 else null, h)
	kid.coins = 400
	c.daily()
	var nh := kid.household
	check(nh != h and str(w.households[nh].get("build", "")) != "", "a grown child founds a household and starts a house")
	var site := str(w.households[nh].build)
	var mate: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner < 0 and n.household >= 3 and n.household != h and Life._may_move(w, n) and Life.has_room(w, n.household) \
				and not Life.kin(kid.id, kid.mother, kid.father, n.id, n.mother, n.father):
			mate = n
			break
	check(mate != null, "a partner with room at home")
	Life._link_partners(kid, mate)
	check(Life._move_in(w, kid, mate), "they move in together")
	check(kid.household == nh and mate.household == nh, "the partner joins the founding household, not the other way round")
	check(str(w.households[nh].get("build", "")) == site, "and the house goes on being built")


## EQ-07: a woodcutter whose axe broke after their coins went into the house is out of work in all but name.
## The house budget keeps back the price of the missing tool, and the job market treats them as out of work.
func test_tool_less_worker() -> void:
	var w := new_world()
	var c := w.construction
	var cutter: NPC = w.brain._first_with_job("woodcutter")
	check(cutter != null and cutter.inv.has("axe"), "a woodcutter with an axe")
	check(not w.brain.tool_short(cutter), "is not short of a tool")
	cutter.inv.remove("axe", cutter.inv.count("axe"))
	cutter.coins = 0
	check(w.brain.tool_short(cutter), "the axe gone and no coins for one: short of the tool")
	check(c._tool_reserve(cutter.household) > 0, "a household building keeps back the price of the missing axe")
	var price: int = w.brain.tool_price(cutter, "axe")
	if price > 0:
		cutter.coins = price
		check(not w.brain.tool_short(cutter), "with the coins for an axe on sale, not short: they go and buy one")
		cutter.coins = 0
	w.treasury = 5000                              # the manor can hire
	var hh: Dictionary = w.households[cutter.household]
	hh.econ = {"cost": 10.0, "adults": 1, "streak": 0}
	w.brain.seek_work()
	check(cutter.job != "woodcutter", "the job market moves a woodcutter with no axe and no coins into paying work (now %s)" % cutter.job)


## EQ-07, tool recovery: someone out of work with the coins for an axe on sale (the smith's or the goods merchant's)
## can take up woodcutting while there are trees for more woodcutters; the job market used to look for axes among
## the timber sellers only, so nobody without an axe could ever become a woodcutter and the trade died out.
func test_axe_bought_to_take_up_woodcutting() -> void:
	var w := new_world()
	var smith: NPC = w.brain._first_with_job("smith")
	smith.inv.add("axe", 2)                           # a spare axe on sale at the forge
	var seeker: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job in ["manor_hand", "farmer", "hunter"] and o.household >= 3:
			seeker = o
			break
	check(seeker != null, "a villager to look for work")
	if seeker == null:
		return
	var kept := false
	for o: NPC in w.npcs:                             # one woodcutter stays (the trade's wage is known); room for more
		if o.alive and o.job == "woodcutter":
			if kept:
				o.job = "farmer"
			kept = true
	var keep_fields = GameData.balance["field_workers_max"]
	var keep_game = GameData.balance["game_per_hunter"]
	var keep_ore = GameData.balance["ore_per_miner"]
	GameData.balance["field_workers_max"] = 0         # no field, game or mine openings: woodcutting is the work on offer
	GameData.balance["game_per_hunter"] = 100000
	GameData.balance["ore_per_miner"] = 100000
	seeker.job = ""
	seeker.inv.remove("axe", seeker.inv.count("axe"))
	var price: int = w.brain.tool_price(seeker, "axe")
	check(price > 0, "an axe is on sale (%d coins)" % price)
	seeker.coins = price + 50
	w.treasury = 0                                    # the manor cannot hire: woodcutting is the work there is
	w.households[seeker.household].econ = {"cost": 10.0, "adults": 1, "streak": 0}
	w.brain.seek_work()
	GameData.balance["field_workers_max"] = keep_fields
	GameData.balance["game_per_hunter"] = keep_game
	GameData.balance["ore_per_miner"] = keep_ore
	check(seeker.job == "woodcutter", "out of work with the coins for an axe on sale, they take up woodcutting (now %s)" % seeker.job)


## EQ-07: an essential trade left for other work is handed on as after a death: when the last smith leaves the forge,
## the smith's post opens for an apprentice or a newcomer, and the smith who left is not taken back as the apprentice.
func test_left_trade_post_opens() -> void:
	var w := new_world()
	var smiths: Array = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.job == "smith")
	check(smiths.size() >= 1, "the village has a smith")
	for o: NPC in smiths.slice(1):
		o.job = "manor_hand"
	var smith: NPC = smiths[0]
	var place := smith.workplace
	var posts: int = w.brain.open_posts("smith")
	smith.coins = 0
	smith.income_days = [0, 0, 0, 0, 0, 0]
	w.treasury = 5000
	w.households[smith.household].econ = {"cost": 50.0, "adults": 1, "streak": 99}
	w.brain.seek_work()
	check(smith.job != "smith", "a smith whose work does not keep the household fed takes other work (now %s)" % smith.job)
	check(w.brain.open_posts("smith") == posts + 1, "the smith's post opens (%d open)" % w.brain.open_posts("smith"))
	var v: Dictionary = {}
	for x in w.vacancies:
		if x.job == "smith":
			v = x
	check(str(v.get("workplace", "")) == place, "at the forge the smith left (%s)" % v.get("workplace", ""))
	var a: NPC = w.brain._apprentice_for(v)
	check(a == null or a != smith, "the smith who left is not taken back as the apprentice")


## HOUSE-08 (owner, OD-13): a couple shares a bed and young children share beds (two to a bed, below
## life.child_until); adolescents, adults and elders need a bed each. No bed is made: only who shares.
func test_bed_sharing() -> void:
	var w := new_world()
	var c := w.construction
	var Y := float(GameData.b("calendar").year_days) * 1440.0
	var h := -1
	for hh in w.households:
		var ad: Array = w.brain._members(int(hh.id)).filter(func(o: NPC) -> bool: return o.role == "adult")
		if int(hh.id) >= 3 and ad.size() == 2 and ad[0].partner == ad[1].id:
			h = int(hh.id)
			break
	var parents: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "adult")
	var mom: NPC = parents[0] if parents[0].sex == "female" else parents[1]
	for o: NPC in w.brain._members(h).filter(func(o: NPC) -> bool: return o.role != "adult"):
		(w.households[h].members as Array).erase(o.id)
		o.household = -1
	var kids := []
	for i in 3:
		var k: NPC = Life.birth(w, mom, w.npc(mom.partner), h)
		k.born = w.minutes - 5.0 * Y
		kids.append(k)
	var beds := c.beds_in(str(w.households[h].home))
	check(c.beds_needed(h) == 1 + 2, "two parents and three young children need three sleeping places: the couple's bed and two for the children (%d)" % c.beds_needed(h))
	check(beds >= 3 and not c.crowded(h), "so a family of five in a %d-bed house is not crowded" % beds)
	for k: NPC in kids:
		k.born = w.minutes - 14.0 * Y            # adolescents now (life.child_until 12)
	check(c.beds_needed(h) == 1 + 3, "grown past the child stage, each needs a bed of their own (%d)" % c.beds_needed(h))
	var single: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner < 0 and n.household != h and n.household >= 3:
			single = n
			break
	check(c.beds_needed(h, single) == c.beds_needed(h) + 1, "a single adult joining needs a bed of their own")
	var dad: NPC = w.npc(mom.partner)
	(w.households[h].members as Array).erase(dad.id)
	dad.household = -1
	check(c.beds_needed(h, dad) == c.beds_needed(h), "a partner joining shares their partner's bed")


## HOUSE-09 (owner, OD-13): an original village house (laid out with no parcel) is eligible for living
## quarters. Surveying its ground costs nothing and changes no hands; the letting's terms move to the parcel.
## On the current village layout no original house has ground beside it for the 9x10 quarters (roads,
## houses and trees on every side: measured on seeds 1 and 2), so a crowded family there keeps its goal with
## that reason and gains no bed it did not build (OD-14 asks the owner what to do about the layout).
func test_quarters_on_an_original_house() -> void:
	var w := new_world(2)
	var c := w.construction
	var h := -1
	for hid in range(3, w.households.size()):
		if w.buildings.has(str(w.households[hid].home)) and w.property.parcel_under(w.buildings[str(w.households[hid].home)]).is_empty():
			h = hid
			break
	var hh: Dictionary = w.households[h]
	var house: Dictionary = w.buildings[str(hh.home)]
	var owner0 := w.owner_of(house)
	var tenant0 := w.tenant_of(house)
	house.rent = 7
	house.due_day = w.day() + 3
	var coins0: int = w.total_coins()
	var heads0: int = w.property.heads().size()
	var p := w.property.survey_under(house)
	check(not p.is_empty() and w.property.parcel_under(house) == p and w.property.building_on(p) == house, "the ground under an original house becomes its parcel")
	check(w.owner_of(p) == owner0 and w.tenant_of(p) == tenant0 and w.holds(World.hh_ref(h), p) == w.holds(World.hh_ref(h), house), "held exactly as the house is")
	check(int(p.get("rent", 0)) == 7 and not house.has("rent"), "the letting's terms move to the parcel, which heads the deal (as for a house built on bought ground)")
	check(w.total_coins() == coins0 and w.property.heads().size() == heads0, "nothing is paid and the deal is still one deal")
	check(w.property.survey_under(house) == p, "surveying again changes nothing")
	# the layout: is there ground anywhere for quarters beside an original house?
	var w2 := new_world(2)
	var c2 := w2.construction
	var any_room := false
	for hid in range(3, w2.households.size()):
		var home := str(w2.households[hid].home)
		if not w2.buildings.has(home):
			continue
		w2.property.survey_under(w2.buildings[home])
		var r := c2.find_module_slot("quarters", w2.buildings[home], World.hh_ref(hid))
		if r.size != Vector2i.ZERO and c2.can_place("quarters", r, World.hh_ref(hid), w2.buildings[home]) == "":
			any_room = true
	check(not any_room, "(measured) no original house has free ground beside it for the 9x10 quarters on this layout; OD-14")
	# a crowded family there now builds a sleeping loft (HOUSE-12) instead: see test_sleeping_loft


## HOUSE-12 (owner-approved 2026-10-20): a crowded family in an original house with no ground builds a sleeping
## loft: the materials are bought or taken from its store, delivered and used up; the two sleeping places
## exist only when the last load is in; ownership and membership are unchanged; one loft per house; a loft
## sleeper goes to the ladder and is not drawn on the ground floor; the loft survives a save; and with no
## option left the goal says so and nothing is retried.
func test_sleeping_loft() -> void:
	var w := new_world(2)
	var c := w.construction
	var h := crowded_family(w)
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	var house: Dictionary = w.buildings[str(hh.home)]
	var owner0 := w.owner_of(house)
	var members0: Array = (hh.members as Array).duplicate()
	var beds0 := c.beds_in(str(hh.home))
	var pantry: Inventory = hh.pantry
	pantry.add("log", 6)                              # firewood the family holds: weighed as material it has
	c.responsible_adult(h).coins += 300
	var took0 := {}
	var bought0 := {}
	for id in c.cost_of("loft"):
		took0[id] = int(w.stats.get("helper_took_" + str(id), 0))
		bought0[id] = int(w.stats.get("helper_bought_" + str(id), 0))
	c.daily()
	var p: Dictionary = w.plot(str(hh.get("build", "")))
	check(not p.is_empty() and str(p.site.kind) == "loft" and w.property.building_on(p) == house, "a crowded family with no ground beside its house sets about a sleeping loft (%s)" % [c.housing_goals(h)])
	if p.is_empty():
		return
	check(str(c.housing_goals(h).crowded.plan) == "loft", "its goal records the plan")
	check(c.beds_in(str(hh.home)) == beds0 and int(house.get("loft", 0)) == 0, "no sleeping place before it is built")
	check(c.loft_refusal(house, ref) != "", "nothing else is started at the house while it is being built")
	for d in 15:
		run_days(w, 1)
		if p.site.get("done", false) or int(house.get("loft", 0)) > 0:
			break
	check(int(house.get("loft", 0)) == int(Construction.loft_cfg().beds), "the household builds the loft (%s left)" % [p.site.get("need", {})])
	check(c.beds_in(str(hh.home)) == beds0 + int(Construction.loft_cfg().beds), "two more sleeping places once it is finished (%d, was %d)" % [c.beds_in(str(hh.home)), beds0])
	check(str(p.site.kind) == "house" and p.site.get("done", false) and w.buildings.has(str(house.id)) and w.property.building_on(p) == house, "the house is still the one house, finished; no new building")
	var supplied := true
	for id in c.cost_of("loft"):
		var got := int(w.stats.get("helper_took_" + str(id), 0)) - int(took0[id]) + int(w.stats.get("helper_bought_" + str(id), 0)) - int(bought0[id])
		supplied = supplied and got >= int(c.cost_of("loft")[id])
	check(supplied, "every plank and log was taken from the household's store or bought: none from nothing")
	check(w.owner_of(house) == owner0 and members0.all(func(id): return (hh.members as Array).has(id) or not w.npc(int(id)).alive), "ownership and membership unchanged")
	check(c.loft_refusal(house, ref).contains("already"), "one loft per house")
	# a loft sleeper goes to the ladder and is hidden
	var sleeper: NPC = null
	for o: NPC in w.brain._members(h):
		if bool(w.home_spot(o, "bed").get("loft", false)):
			sleeper = o
			break
	check(sleeper != null, "the later sleepers in the household's order sleep in the loft")
	if sleeper != null:
		var ladder := w.home_cell(sleeper, "bed")
		var floor_cells: Array = w.interiors[str(hh.home)].floor.map(func(f): return Vector2i(int(f[0]), int(f[1])))
		check(floor_cells.has(ladder) and not w.map.is_solid(ladder), "their bed is reached from the ladder, a floor cell inside the house")
		sleeper.anim = "sleep"
		check(w.in_loft(sleeper), "asleep up there: not drawn on the ground floor")
		sleeper.anim = "idle"
		check(not w.in_loft(sleeper), "awake, they are seen again")
	# saves keep the loft; an older save without the field loads with no loft
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(int(w2.buildings[str(house.id)].get("loft", 0)) == 2 and w2.construction.beds_in(str(hh.home)) == c.beds_in(str(hh.home)), "a saved game keeps the loft and its beds")
	d = JSON.parse_string(JSON.stringify(d))          # a copy: to_dict shares the live building records
	for bd in d.buildings.values():
		bd.erase("loft")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w3.construction.beds_in(str(hh.home)) == beds0, "a save from before lofts loads with no loft")
	# nothing left to try: the goal says so, and no site is started again and again
	while not c.crowded(h):
		var mom: NPC = c.responsible_adult(h)
		Life.birth(w, mom if mom.sex == "female" else w.npc(mom.partner), mom if mom.sex != "female" else w.npc(mom.partner), h)
	c.daily()
	c.daily()
	var g: Dictionary = c.housing_goals(h).get("crowded", {})
	check(str(g.get("plan", "")) == "none" and str(g.why).contains("loft already") and str(hh.get("build", "")) == "", "with the loft built and no ground, the goal says why and nothing is retried (%s; crowded %s, founder %s, build %s)" % [c.housing_goals(h), c.crowded(h), c.founder_of(h), hh.get("build", "")])


## HOUSE-12 (owner: weigh the options by circumstances, not a loft first by rule): in a house with ground
## beside it, a household short of a bed or two takes the cheaper loft; one short of more than a loft gives
## takes the living quarters, which give enough room.
func test_housing_options_weighed() -> void:
	for want_quarters in [false, true]:
		var w := new_world(2)
		var c := w.construction
		var h := crowded_family(w)
		var hh: Dictionary = w.households[h]
		var ref := World.hh_ref(h)
		# the family moves to a house it builds on open ground (so there is room beside it)
		var p := c.place("house", c.find_ground("house", w.building_door(str(hh.home)), ref), ref)
		var bag := Inventory.new()
		for id in p.site.need:
			bag.add(str(id), int(p.site.need[id]))
		w.deliver(p, bag)
		c.move_in(h, "house_" + str(p.id))
		var guard := 0
		var lacking := c.beds_needed(h) - c.beds_in(str(hh.home))
		var target := int(Construction.loft_cfg().beds) + 1 if want_quarters else 1
		while lacking != target and guard < 60:
			var kids: Array = w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "child")
			if lacking < target:
				var mom: NPC = c.responsible_adult(h)
				Life.birth(w, mom if mom.sex == "female" else w.npc(mom.partner), mom if mom.sex != "female" else w.npc(mom.partner), h)
			elif not kids.is_empty():
				(hh.members as Array).erase(kids[0].id)
				kids[0].household = -1
			lacking = c.beds_needed(h) - c.beds_in(str(hh.home))
			guard += 1
		c.responsible_adult(h).coins += 1000
		c.daily()
		var site: Dictionary = w.plot(str(hh.get("build", "")))
		var kind := str(site.site.kind) if not site.is_empty() else "none"
		if want_quarters:
			check(kind == "quarters", "short of %d sleeping places, more than a loft gives: living quarters beside the house (%s)" % [lacking, kind])
		else:
			check(kind == "loft", "short of one sleeping place: the cheaper sleeping loft (%s)" % kind)


## HOUSE-10 (owner OD-14, 2026-10-20: retain the 5x6 attached room for houses with legitimate ground): a crowded
## family in one of the three original houses with ground beside it (b23, b24, b_v1_house; measured), whose loft is
## built, adds a small room against the house through the module rules: the ground beside it bought or leased,
## materials taken or bought and used up, two beds only when the last load is in, the beds counted as the house's
## and slept in, ownership and membership unchanged, one room per property, and the room kept by a save.
func test_small_room() -> void:
	var w := new_world(2)
	var c := w.construction
	var h := -1
	for hh in w.households:
		if str(hh.home) == "b_v1_house":
			h = int(hh.id)
	check(h >= 0, "a household lives in b_v1_house")
	if h < 0:
		return
	var hh: Dictionary = w.households[h]
	var ref := World.hh_ref(h)
	var house: Dictionary = w.buildings["b_v1_house"]
	house.loft = int(Construction.loft_cfg().beds)       # its loft is built already
	w.index_interiors()
	var mom: NPC = null
	for o: NPC in w.brain._members(h):
		if o.role == "adult" and o.sex == "female":
			mom = o
	while not c.crowded(h):
		Life.birth(w, mom, w.npc(mom.partner), h)
	var owner0 := w.owner_of(house)
	var members0: Array = (hh.members as Array).duplicate()
	var beds0 := c.beds_in("b_v1_house")
	c.responsible_adult(h).coins += 1000
	var took0 := {}
	for id in c.cost_of("room"):
		took0[id] = int(w.stats.get("helper_took_" + str(id), 0)) + int(w.stats.get("helper_bought_" + str(id), 0))
	c.daily()
	var p: Dictionary = w.plot(str(hh.get("build", "")))
	check(not p.is_empty() and str(p.site.get("kind", "")) == "room", "with the loft built and no ground for quarters, the family sets about a small room (%s)" % [c.housing_goals(h)])
	if p.is_empty():
		return
	var rect := Rect2i(int(p.x), int(p.y), int(p.w), int(p.h))
	check(rect.size == Vector2i(5, 6) and c.attach_refusal(rect, house) == "", "5x6 ground standing against the house (%s)" % rect)
	check(str(c.housing_goals(h).crowded.plan) == "room" and w.holds(ref, p), "its goal records the plan; the ground is the household's")
	check(c.beds_in("b_v1_house") == beds0, "no bed before it is built")
	for d in 20:
		run_days(w, 1)
		if p.site.get("done", false):
			break
	var room: Dictionary = w.property.building_on(p)
	check(p.site.get("done", false) and not room.is_empty() and str(room.get("kind", "")) == "room", "the household builds the room (%s left)" % [p.site.get("need", {})])
	if room.is_empty():
		return
	check(c.beds_in("b_v1_house") == beds0 + 2 and w.property.rooms_of("b_v1_house").has(str(room.id)), "two more beds, counted as the house's (%d, was %d)" % [c.beds_in("b_v1_house"), beds0])
	var supplied := true
	for id in c.cost_of("room"):
		var got := int(w.stats.get("helper_took_" + str(id), 0)) + int(w.stats.get("helper_bought_" + str(id), 0)) - int(took0[id])
		supplied = supplied and got >= int(c.cost_of("room")[id])
	check(supplied, "every plank, stone and log was taken from the household's store or bought: none from nothing")
	check(w.owner_of(house) == owner0 and members0.all(func(id): return (hh.members as Array).has(id) or not w.npc(int(id)).alive), "the house's ownership and the household unchanged")
	var in_room := 0
	for o: NPC in w.brain._members(h):
		var spot := w.home_spot(o, "bed")
		if w.interiors[str(room.id)].spots.has(spot):
			in_room += 1
	check(in_room >= 1, "members of the household sleep in the room's beds (%d)" % in_room)
	check(c.module_refusal("room", house, ref).contains("already"), "one small room to a property")
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w2.buildings.has(str(room.id)) and w2.construction.beds_in("b_v1_house") == c.beds_in("b_v1_house"), "a saved game keeps the room and its beds")


## EQ-17: a couple who founded a household and are still building its house lodge with family, so the
## household has no home yet. A baby born then lives with its parents, never in no house at all (365-day
## runs logged thousands of script errors from such babies), and moves in with them when the house is done.
func test_baby_while_lodging() -> void:
	var w := new_world()
	var a: NPC = null
	var b: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner < 0:
			if a == null and n.sex == "female":
				a = n
			elif b == null and n.sex == "male" and a != null and n.household != a.household:
				b = n
	check(a != null and b != null, "a woman and a man of different households")
	if a == null or b == null:
		return
	Life._link_partners(a, b)
	var lodging := a.home
	var nh := {"id": w.households.size(), "family": a.family, "home": "", "members": [], "pantry": Inventory.new(),
		"founded_from": a.household, "founded_day": w.day(), "build": "plot_test"}
	w.households.append(nh)
	for o: NPC in [a, b]:
		w.households[o.household].members.erase(o.id)
		o.household = int(nh.id)
		nh.members.append(o.id)
	var k := Life.birth(w, a, b, int(nh.id))
	check(k.home == lodging and w.buildings.has(k.home), "the baby lives where its mother lodges (%s), not in no house" % k.home)
	var house := ""
	for id in w.buildings:
		if id != lodging and w.property.is_home(w.buildings[id]):
			house = str(id)
			break
	w.construction.move_in(int(nh.id), house)
	check(k.home == house and a.home == house and b.home == house, "when the house is done the baby moves in with its parents")


## HOUSE-04, the owner's housing directive ("Obtaining help from relatives"): a household building its home
## gets, toward what its site still costs, what its family can spare above its own keep; coins only move;
## a family that is building itself, or has nothing to spare, gives nothing.
func test_family_helps_builder() -> void:
	var w := new_world()
	var c := w.construction
	var from := crowded_family(w)
	var child: NPC = null
	for o: NPC in w.brain._members(from):
		if o.role == "adult" and c._grown_child(o):
			child = o
	if child == null:
		for o: NPC in w.brain._members(from):
			if o.role == "adult" and child == null and c.responsible_adult(from) != o:
				child = o
	check(child != null, "a grown member to found a household")
	if child == null:
		return
	var nh := {"id": w.households.size(), "family": child.family, "home": "", "members": [], "pantry": Inventory.new(),
		"founded_from": from, "founded_day": w.day()}
	w.households.append(nh)
	var h := int(nh.id)
	w.households[from].members.erase(child.id)
	child.household = h
	nh.members.append(child.id)
	var ref := World.hh_ref(h)
	var rect := c.find_ground("house", w.building_door(str(w.households[from].home)), ref)
	check(rect.size != Vector2i.ZERO, "ground for the new house")
	if rect.size == Vector2i.ZERO:
		return
	var p := c.place("house", rect, ref)
	w.start_site(p, "house", ref)
	nh.build = str(p.id)
	child.coins = 5
	var family: Array = w.brain._members(from)
	for o: NPC in family:
		o.coins = 0
	family[0].coins = 400
	var total := w.total_coins()
	var keep := c._keep(from, family.size()) + c._tool_reserve(from)
	var short := c.estimate(p.site.need) + 10 + c._tool_reserve(h) - w.property.purse(ref)
	c._family_help(h)
	var gave := child.coins - 5
	check(gave > 0 and gave == mini(short, 400 - keep), "the family gives what the site still needs, within what it can spare (%d of %d short; it keeps %d)" % [gave, short, keep])
	check(w.property.purse(World.hh_ref(from)) >= keep, "and keeps what its own people need (%d)" % w.property.purse(World.hh_ref(from)))
	check(w.total_coins() == total, "coins move from the family to the builder: none is made or lost")
	var before := child.coins
	c._family_help(h)
	check(child.coins == before or child.coins - before <= maxi(0, w.property.purse(World.hh_ref(from)) - keep), "a second call gives no more than is left to spare")
	# a family that is building itself, or has nothing to spare, gives nothing
	child.coins = 5
	for o: NPC in family:
		o.coins = 0
	family[0].coins = keep
	c._family_help(h)
	check(child.coins == 5, "a family with nothing above its keep gives nothing")
	family[0].coins = 400
	w.households[from].build = "elsewhere"
	c._family_help(h)
	check(child.coins == 5, "nor a family building a home of its own")
	w.households[from].erase("build")


## HOUSE-04, the owner's housing directive ("gathering available timber", "producing materials through
## existing crafting"): with no timber for sale, a builder with an axe fells trees, saws the logs into planks
## at a sawhorse and carries them to the site; every log is felled and every plank sawn, none from nothing.
func test_builder_makes_timber() -> void:
	var w := new_world()
	var c := w.construction
	var from := crowded_family(w)
	var builder: NPC = null
	for o: NPC in w.brain._members(from):
		if o.role == "adult" and builder == null and c.responsible_adult(from) != o:
			builder = o
	check(builder != null, "a grown member to build")
	if builder == null:
		return
	var nh := {"id": w.households.size(), "family": builder.family, "home": "", "members": [], "pantry": Inventory.new(),
		"founded_from": from, "founded_day": w.day()}
	w.households.append(nh)
	var h := int(nh.id)
	w.households[from].members.erase(builder.id)
	builder.household = h
	nh.members.append(builder.id)
	var ref := World.hh_ref(h)
	var rect := c.find_ground("house", w.building_door(str(w.households[from].home)), ref)
	if rect.size == Vector2i.ZERO:
		check(false, "ground for the new house")
		return
	var p := c.place("house", rect, ref)
	w.start_site(p, "house", ref)
	nh.build = str(p.id)
	p.site.need = {"log": 3, "plank": 4}      # a small remainder: three logs and four planks to go
	for o: NPC in w.npcs:                      # nobody has timber to sell
		if o != builder:
			o.inv.remove("log", o.inv.count("log"))
			o.inv.remove("plank", o.inv.count("plank"))
	builder.inv.remove("log", builder.inv.count("log"))
	builder.inv.remove("plank", builder.inv.count("plank"))
	builder.job = "laborer"
	builder.coins = 60
	if not builder.inv.has("axe"):
		builder.inv.add("axe")
	var felled0 := int(w.stats.get("felled_log", 0))
	var sawn0 := int(w.stats.get("made_plank", 0))
	var own0 := int(w.stats.get("builder_own_log", 0)) + int(w.stats.get("builder_own_plank", 0))
	for d in 6:
		for m in 1440:
			w.update(0.5)
			w.player.hunger = 100.0
			if m % 120 == 0:                   # keep the market bare of timber
				for o: NPC in w.npcs:
					if o != builder and not c.contracts.any(func(k): return int(k.worker) == o.id):
						o.inv.remove("log", o.inv.count("log"))
						o.inv.remove("plank", o.inv.count("plank"))
		if p.site.get("done", false):
			break
	var felled := int(w.stats.get("felled_log", 0)) - felled0
	var sawn := int(w.stats.get("made_plank", 0)) - sawn0
	var own := int(w.stats.get("builder_own_log", 0)) + int(w.stats.get("builder_own_plank", 0)) - own0
	check(felled > 0 and sawn > 0, "trees were felled and planks sawn in the village meanwhile (%d logs, %d planks)" % [felled, sawn])
	check(own >= 7 or p.site.get("done", false), "and carried their own timber to the site (%d pieces)" % own)
	check(p.site.get("done", false), "the house is finished with timber the builder made (%s still needed)" % [p.site.get("need", {})])


## EQ-07, "economic recovery from missing work tools": the caravan does not buy away a tool that villagers
## here need. With three woodcutters short of an axe, an axe for each stays for sale; with none short, the
## surplus above the merchant's stock goes as before.
func test_caravan_keeps_needed_tools() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	var merchant: NPC = null
	for o: NPC in w.npcs:
		if o.alive and b.buy_role(o) == "merchant_goods" and merchant == null:
			merchant = o
	var cutters: Array = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.job == "woodcutter")
	check(merchant != null and cutters.size() >= 3, "a goods merchant and three woodcutters")
	if merchant == null or cutters.size() < 3:
		return
	for o: NPC in w.npcs:                      # only the merchant holds axes for sale
		if o != merchant and (o.job == "smith" or b.buy_role(o) == "merchant_goods"):
			o.inv.remove("axe", o.inv.count("axe"))
	merchant.inv.remove("axe", merchant.inv.count("axe"))
	merchant.inv.add("axe", 4)
	for i in 3:
		cutters[i].inv.remove("axe", cutters[i].inv.count("axe"))
	for i in range(3, cutters.size()):
		if not cutters[i].inv.has("axe"):
			cutters[i].inv.add("axe")
	check(int(b.local_tool_need().axe) >= 3, "three woodcutters need an axe (%d)" % int(b.local_tool_need().axe))
	var exported := int(w.stats.get("exported_axe", 0))
	w.caravan_purse = 1000
	b.caravan()
	check(merchant.inv.count("axe") >= 3, "the caravan leaves an axe for each of them (%d kept, %d exported)" % [merchant.inv.count("axe"), int(w.stats.get("exported_axe", 0)) - exported])
	for i in 3:
		cutters[i].inv.add("axe")
	var need_now := int(b.local_tool_need().axe)
	merchant.inv.add("axe", 2)                  # six: two above what the merchant keeps in stock
	w.caravan_purse = 1000
	b.caravan()
	check(need_now > 0 or int(w.stats.get("exported_axe", 0)) > exported, "with nobody short of one, the surplus goes to the caravan as before (%d exported)" % (int(w.stats.get("exported_axe", 0)) - exported))
