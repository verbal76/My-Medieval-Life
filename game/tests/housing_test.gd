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
	for id in need0:
		bought0[id] = int(w.stats.get("helper_bought_" + str(id), 0))
		held0[id] = int(w.stats.get("helper_took_" + str(id), 0))
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
		if bought + own < int(need0[id]):           # what was carried back unused may make it more, never less
			free.append("%s: %d delivered, %d taken from the store, %d bought" % [id, int(need0[id]), own, bought])
	check(free.is_empty(), "every material delivered was taken from the household's store or bought, none from nothing %s" % [free])
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
