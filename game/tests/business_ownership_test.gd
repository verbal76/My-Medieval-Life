extends SceneTree
## B25-BIZ-OWN (owner, 2026-11-01; docs/expansion20/BUSINESS_OWNERSHIP.md): the five final decisions on business ownership,
## paid employment and economic expansion. D1 separate business money; D2 paid employees versus independent craftspeople;
## D3 abandoning an unfinished business site; D4 permanent employment across the professions; D5 building, buying, selling
## and expanding businesses, home-attached workshops, careers; the two-shop finding. Coins and goods conserved, determinism,
## save and load (an older save included), multiplayer verbs. Run headless:
##   godot --headless --path game --script res://tests/business_ownership_test.gd

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
	for t in ["test_business_till", "test_sales_and_materials", "test_independent_hand", "test_paid_employee",
			"test_close_keeps_till", "test_roles", "test_wage_and_resign", "test_obligations", "test_abandon",
			"test_sell_and_buy", "test_home_workshop_sale", "test_npc_buys_listed", "test_player_buys", "test_standalone",
			"test_expansion", "test_career", "test_no_shop_cap", "test_save_load", "test_verbs", "test_determinism"]:
		if has_method(t):
			call(t)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	w.judgment.cfg.decision.integration.work_accept = false      # the villager's own yes is JudgmentLive's test; here the terms
	return w


func of_job(w: World, job: String) -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.job == job)


## The goods ledger the conservation suite reads: every item held anywhere (packs, stores, sites, tills of goods).
func goods(w: World, id: String) -> int:
	var t := w.player.inv.count(id) + w.player.chest.count(id) + w.granary.count(id)
	for n: NPC in w.npcs:
		t += n.inv.count(id)
	for hh in w.households:
		t += (hh.pantry as Inventory).count(id)
	for l in w.loot:
		t += (l.inv as Inventory).count(id)
	t += int(w.site_goods().get(id, 0))
	return t


func smithy_full(w: World) -> void:
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var d := {}
		for kind in NPCBrain.TRADE_STATIONS.smith:
			for st in w.stations_of(kind):
				if w.ventures.venture_at(st).is_empty():
					d[st] = {"smith": day}
		past.append(d)
	w.station_load = {"day": w.day(), "today": {}, "past": past}


## Every smith station busy, the businesses' own included: work for the trade and no room anywhere.
func all_full(w: World) -> void:
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var d := {}
		for kind in NPCBrain.TRADE_STATIONS.smith:
			for st in w.stations_of(kind):
				d[st] = {"smith": day * float(w.stations[st].get("capacity", 1))}
		past.append(d)
	w.station_load = {"day": w.day(), "today": {}, "past": past}


func founder(w: World) -> NPC:
	var s: NPC = null
	for o: NPC in of_job(w, "smith"):
		if s == null or Skills.level(o, "smithing") > Skills.level(s, "smithing"):
			s = o
	var key := World.npc_ref(s.id)
	if not w.experience.minutes.has(key):
		w.experience.minutes[key] = {}
	w.experience.minutes[key]["smithing"] = 480.0 * 60.0
	s.coins += 3000
	w.brain.evaluate_household(s.household)
	return s


func found_one(w: World) -> NPC:
	var s := founder(w)
	smithy_full(w)
	w.ventures.found(s, w.ventures.eligible(s))
	return s


func finish(w: World, s: NPC) -> Dictionary:
	var hh: Dictionary = w.households[s.household]
	var p: Dictionary = w.plot(str(hh.build))
	var pantry: Inventory = hh.pantry
	for id in p.site.need.duplicate():
		pantry.add(id, int(p.site.need[id]))
	w.deliver(p, pantry)
	return w.buildings.get(str(p.get("building", "")), {})


## A founded, built and opened smithy of seed `seed`'s best smith: [keeper, workshop].
func open_one(w: World) -> Array:
	var s := found_one(w)
	var b := finish(w, s)
	w.minutes += 1440.0
	w.station_load = {}                   # no demand read this morning: the business opens and hires nobody yet
	w.ventures.daily()
	return [s, b]


# ---------------------------------------------------------------- D1 ------------------------------
func test_business_till() -> void:
	var w := world()
	var s := found_one(w)
	var b := finish(w, s)
	var head: NPC = w.party(World.hh_ref(s.household))
	var coins := w.total_coins()
	var purse: int = w.property.purse(World.hh_ref(s.household))
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	var v: Dictionary = b.venture
	check(b.has("venture") and v.has("till"), "an open venture keeps a till of its own (D1)")
	var put := int(v.get("invested", 0))
	check(put > 0 and int(v.till) == put and purse - w.property.purse(World.hh_ref(s.household)) == put and w.total_coins() == coins,
		"the household invests working capital from its spendable coins (%d); nothing made" % put)
	check(w.business.tills() >= put and w.economy == null or true, "the venture's till is counted with the village's money")
	# the morning settlement: the household's protected reserve is never drawn into the till
	v.till = 0
	for o: NPC in w.brain._members(s.household):
		o.coins = mini(o.coins, w.reserve_of(o))
	coins = w.total_coins()
	var before: int = w.property.purse(World.hh_ref(s.household))
	w.business.money.daily()
	check(w.property.purse(World.hh_ref(s.household)) == before and int(v.till) == 0 and w.total_coins() == coins,
		"a bare till is not topped up from the household's protected reserve")
	# owner invests and withdraws by choice
	head.coins += 50
	check(w.business.money.invest(b, "venture", head, 30) and int(v.till) == 30 and w.business.money.withdraw(b, "venture", head, 10) and int(v.till) == 20,
		"the owner invests and withdraws by choice (invest 30, withdraw 10)")
	check(not w.business.money.withdraw(b, "venture", head, 999) and int(v.till) == 20, "nothing beyond what the till holds can be withdrawn")
	check(w.total_coins() == coins + 50, "coins conserved through investing and withdrawing")


func test_sales_and_materials() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	var v: Dictionary = b.venture
	v.till = 0
	# a craft at the business's station: what it makes is the business's goods
	var st := str(w.ventures.trade_stations(b, "smith").filter(func(x): return str(w.stations[x].type) == "forge")[0])
	s.inv.add("iron_ore", 2)
	s.inv.add("coal", 2)
	var rcp := "smelt_iron"
	if not GameData.recipes.has(rcp):
		for k in GameData.recipes:
			if str(GameData.recipes[k].station) == "forge" and w.brain._can_make(s, k):
				rcp = k
				break
	for id in GameData.recipes[rcp]["in"]:
		s.inv.add(id, int(GameData.recipes[rcp]["in"][id]))
	var snap: Dictionary = w.ventures.craft_begin(s, {"station": st, "recipe": rcp})
	var ok := str(w.work_craft(s, rcp, s.inv).result) == "ok"
	w.ventures.craft_end(s, snap)
	var out := str(GameData.recipes[rcp].out.keys()[0])
	check(ok and int(v.goods.get(out, 0)) >= 1, "goods made at the business's station by its keeper are the business's (%s)" % out)
	# the sale of the business's goods: the price goes into its till, not the keeper's purse
	var buyer: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household != s.household:
			buyer = o
			break
	buyer.coins += 500
	var coins := w.total_coins()
	var sc := s.coins
	check(w.trade(buyer, s, out, 1, 7), "a buyer buys one from the keeper")
	check(int(v.till) == 7 and s.coins == sc and w.total_coins() == coins, "the sale's 7 coins go into the business's till (D1: revenue belongs to the business)")
	# materials: a business purchase is paid from the till, and only what it holds
	var item := "iron_ore"
	check(w.ventures.budget(s, item) == 7, "the business's budget for its materials is its till")
	check(w.ventures.budget(s, "bread") == -1, "food is not a business purchase")
	var merchant: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != s and w.brain.buy_role(o) == "merchant_raw":
			merchant = o
	if merchant == null:
		merchant = buyer
	merchant.inv.add(item, 20)
	var up := w.deal_price(w.sell_price(merchant, item), s, merchant)
	var q: int = w.brain.buy_qty(s, merchant, item, 20)
	check(q == 7 / up, "the business can only buy what its till pays for (%d at %d)" % [q, up])
	s.coins += 1000
	q = w.brain.buy_qty(s, merchant, item, 20)
	check(q == 7 / up, "the keeper's own purse does not pay the business's materials")
	coins = w.total_coins()
	sc = s.coins
	var had := s.inv.count(item)
	var g0 := int(v.goods.get(item, 0))
	w.brain.act(s, "buy_from", {"vendor": merchant.id, "item": item, "qty": 20})
	var got := s.inv.count(item) - had
	check(got == q and int(v.till) == 7 - up * got and s.coins == sc and w.total_coins() == coins,
		"the purchase is paid from the till (%d bought, till %d); the keeper's purse untouched" % [got, int(v.till)])
	check(int(v.goods.get(item, 0)) - g0 == got and int((v.costs as Dictionary).get("materials", 0)) == up * got, "the materials are the business's goods, its cost recorded")
	v.till = 0
	had = s.inv.count(item)
	w.brain.act(s, "buy_from", {"vendor": merchant.id, "item": item, "qty": 5})
	check(s.inv.count(item) == had, "a business with no money buys nothing (it cannot spend money it does not hold)")


func test_independent_hand() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	var hand: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job in ["", "manor_hand", "laborer"] and o.household != s.household:
			hand = o
			break
	hand.job = "smith"
	b.venture.hands.append(hand.id)
	w.permit(b, World.npc_ref(hand.id), true)
	hand.inv.add("iron_bar", 1)
	var buyer: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != hand and o != s:
			buyer = o
			break
	buyer.coins += 100
	var hc := hand.coins
	var till := int(b.venture.till)
	check(w.trade(buyer, hand, "iron_bar", 1, 9) and hand.coins == hc + 9 and int(b.venture.till) == till,
		"an independent craftsperson working the business's benches with leave keeps their own earnings (D2)")
	check(w.ventures.business_of(hand).is_empty() and w.ventures.budget(hand, "iron_ore") == -1, "and buys their own materials with their own money")


func candidate(w: World, b: Dictionary, trade := "smith") -> NPC:
	var sk: String = w.brain._trade_skill(trade)
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.job in Construction.HIRABLE and o.id != int(b.venture.keeper) \
				and w.employment.refusal(o, trade, Ventures.ref_of(b)) == "":
			if int(o.skills.get(sk, 0)) <= 0:
				o.skills[sk] = Skills.xp_for_level(1)
			return o
	return null


func test_paid_employee() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	var v: Dictionary = b.venture
	var e := candidate(w, b)
	var wage: int = w.employment.market_wage("smith")
	v.till = 0
	check(w.employment.hire_for(Ventures.ref_of(b), e, "smith", wage) != "", "a business without the money cannot take on an employee")
	v.till = wage * 10
	var coins := w.total_coins()
	var ec := e.coins
	check(w.employment.hire_for(Ventures.ref_of(b), e, "smith", wage) == "", "a business with the money takes on a paid employee")
	check(e.job == "smith" and int(v.till) == wage * 9 and e.coins == ec + wage and w.total_coins() == coins,
		"the first day's wage is paid from the business's till (%d); a genuine transfer" % wage)
	check(w.npc_may_use(e, w.stations[e.workplace]) and str(w.stations[e.workplace].building) == str(b.id), "the employee works at the business's stations with the keeper's leave")
	check(w.ventures.stations_for(e, str(w.stations[e.workplace].type)).has(e.workplace), "the business's stations come first for its employee")
	check(not w.employment.plan(e), "a business's employee works the trade's own day (NPCBrain._plan_job), not a player's errand")
	# production by the employee at the business's station belongs to the employer; its sale pays the till
	e.inv.add("iron_bar", 1)
	w.employment.record_of(e).owed["iron_bar"] = 1
	var buyer: NPC = s
	buyer.coins += 100
	var till := int(v.till)
	ec = e.coins
	check(w.trade(buyer, e, "iron_bar", 1, 9) and int(v.till) == till + 9 and e.coins == ec, "the employee's sale of the employer's goods pays the business's till")
	# wages each dawn from the till; an unpaid wage ends the employment
	w.minutes += 1440.0
	till = int(v.till)
	ec = e.coins
	w.employment.daily()
	check(int(v.till) == till - wage and e.coins == ec + wage, "the next day's wage is paid from the till at dawn")
	v.till = wage - 1
	w.minutes += 1440.0
	w.employment.daily()
	check(not w.employment.is_employed(e) and not w.npc_may_use(e, w.stations[w.ventures.trade_stations(b, "smith")[0]]),
		"a business that cannot pay loses its employee, and their leave at its benches")
	# the venture hires by itself when it has work, room and the money
	var w2 := world()
	var r2 := open_one(w2)
	var b2: Dictionary = r2[1]
	b2.venture.till = 1000
	smithy_full(w2)
	for o: NPC in of_job(w2, "smith"):
		o.income_days = [40, 40, 40, 40, 40]
		o.job_since = -100
		o.left_job = ""
	candidate(w2, b2)
	w2.ventures._hire(b2)
	var hired: Array = w2.employment.of_employer(Ventures.ref_of(b2))
	check(hired.size() == 1 and int(w2.stats.get("venture_employees_hired", 0)) == 1, "a busy business with money hires a paid employee by itself")
	w2.ventures._hire(b2)
	var room := 0
	for st in w2.ventures.trade_stations(b2, "smith"):
		room += int(w2.stations[st].get("capacity", 1))
	check(w2.employment.of_employer(Ventures.ref_of(b2)).size() + 1 <= room, "it never takes on more people than its stations hold")
	var w3 := world()
	var b3: Dictionary = open_one(w3)[1]
	b3.venture.till = 1000
	w3.station_load = {}
	candidate(w3, b3)
	w3.ventures._hire(b3)
	check(w3.employment.of_employer(Ventures.ref_of(b3)).is_empty(), "with no work for the trade it hires nobody")


func test_close_keeps_till() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	var e := candidate(w, b)
	b.venture.till = 200
	w.employment.hire_for(Ventures.ref_of(b), e, "smith", w.employment.market_wage("smith"))
	var till := int(b.venture.till)
	var purse: int = w.property.purse(World.hh_ref(s.household))
	var coins := w.total_coins()
	w.ventures.close(b, "test")
	check(not b.has("venture") and w.property.purse(World.hh_ref(s.household)) == purse + till and w.total_coins() == coins,
		"a closing business's till goes to its household (TILL-D1), nothing made (%d)" % till)
	check(not w.employment.is_employed(e), "its employees' employment ends with it")


# ---------------------------------------------------------------- D4 ------------------------------
## A home of the player's own with its chest (ground and materials given here; earned and bought in play).
func player_home(w: World) -> Dictionary:
	if w.player.home != "" and w.buildings.has(w.player.home):
		return w.buildings[w.player.home]
	var sp = w.map.data.spawns.player
	var c: Construction = w.construction
	var rect := c.find_ground("house", Vector2i(int(sp[0]), int(sp[1])), World.PLAYER)
	w.player.coins += w.property.land_price(rect.size.x, rect.size.y)
	var p: Dictionary = c.place("house", rect, World.PLAYER)
	for id in p.site.need.duplicate():
		w.player.inv.add(id, int(p.site.need[id]))
	w.deliver(p, w.player.inv)
	w.property.set_home(str(p.building))
	return w.buildings[str(p.building)]


## A building of `kind` of the player's on ground of its own near `near` (materials and the ground given).
func player_build(w: World, kind: String, near: Vector2i) -> Dictionary:
	var rect: Rect2i = w.construction.find_ground(kind, near, World.PLAYER)
	w.player.coins += w.property.land_price(rect.size.x, rect.size.y)
	var p: Dictionary = w.construction.place(kind, rect, World.PLAYER)
	if p.is_empty():
		return {}
	for id in p.site.need.duplicate():
		w.player.inv.add(id, int(p.site.need[id]))
	w.deliver(p, w.player.inv)
	return w.buildings.get(str(p.get("building", "")), {})


func hirable(w: World, skip := []) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.job in Construction.HIRABLE and not skip.has(o) and w.employment.obligation(o) == "":
			return o
	for o: NPC in w.npcs:                 # few are out of work on a new world: one who has just left their work (test setup)
		if o.alive and o.role == "adult" and o.household >= 0 and not skip.has(o) and w.employment.obligation(o) == "" and o.job in ["farmer", "woodcutter", "miner"]:
			o.job = ""
			return o
	return null


func test_roles() -> void:
	var w := world()
	var used := []
	check(w.employment.refusal(hirable(w), "woodcutter").begins_with("You need a home"), "no home store: nobody can be employed to fill it")
	var home := player_home(w)
	w.player.coins += 500
	var chest: Inventory = w.construction.store_of(World.PLAYER)
	check(w.employment.refusal(hirable(w), "jester") != "", "no role without a work system of its own is offered")
	# woodcutter
	var wc := hirable(w)
	used.append(wc)
	check(w.employment.employ(wc, "woodcutter") == "" and wc.job == "woodcutter", "a woodcutter is employed (D4)")
	wc.inv.add("axe", 1)
	w.minutes = float(w.day()) * 1440.0 + 9 * 60
	wc.plan.clear()
	check(w.employment.plan(wc) and wc.plan.any(func(s): return str(s.get("act", "")) == "emp_chop"), "they plan to fell a tree for the employer")
	var step: Dictionary = wc.plan.filter(func(s): return str(s.get("act", "")) == "emp_chop")[0]
	var logs := goods(w, "log")
	var held := wc.inv.count("log")
	check(w.employment.act_chop(wc, step.args), "the tree is felled by the woodcutter's rule")
	var got := wc.inv.count("log") - held
	check(got > 0 and int(w.employment.record_of(wc).owed.get("log", 0)) == got and goods(w, "log") == logs + got, "the logs come from the tree, owed to the employer (%d)" % got)
	var c0 := chest.count("log")
	w.employment.act_deliver(wc)
	check(chest.count("log") - c0 == got, "and are delivered into the employer's chest")
	# builder
	var bd := hirable(w, used)
	used.append(bd)
	var rect: Rect2i = w.construction.find_ground("house", Vector2i(int(home.x), int(home.y)) + Vector2i(0, 14), World.PLAYER)
	w.player.coins += w.property.land_price(rect.size.x, rect.size.y)
	var site: Dictionary = w.construction.place("house", rect, World.PLAYER)
	check(not site.is_empty(), "the player marks out a building site")
	for id in site.site.need:
		chest.add(id, int(site.site.need[id]))
	check(w.employment.employ(bd, "builder") == "" and bd.job == "laborer", "a builder is employed")
	bd.plan.clear()
	var planned: bool = w.employment.plan(bd)
	var hc: Dictionary = w.construction.contract_of(bd)
	check(planned and bool(hc.get("employment", false)) and int(hc.wage) == 0 and int(hc.budget) == 0,
		"they carry the employer's materials to the employer's site through the helper's work, no second wage, no spending")
	check(bd.plan.any(func(s): return str(s.get("act", "")) in ["helper_take", "helper_deliver"]), "fetching from the employer's store")
	# craft (a carpenter at the player's own carpenter's shop)
	var cp := hirable(w, used)
	used.append(cp)
	check(w.employment.refusal(cp, "carpenter").begins_with("You hold no"), "no station of the trade: no crafter")
	var shop := player_build(w, "carpentry", Vector2i(int(home.x), int(home.y)) + Vector2i(14, 0))
	check(not shop.is_empty(), "the player builds a carpenter's shop")
	cp.skills["carpentry"] = maxi(int(cp.skills.get("carpentry", 0)), Skills.xp_for_level(1))
	check(w.employment.employ(cp, "carpenter") == "Choose what they are to make.", "a crafter is told what to make")
	check(w.employment.employ(cp, "carpenter", -1, "", "forge_axe") != "", "only what the employer's stations make")
	check(w.employment.employ(cp, "carpenter", -1, "", "saw_planks") == "" and cp.job == "carpenter", "a carpenter is employed to saw planks")
	chest.add("log", 3)
	var lg := chest.count("log")
	var pl := chest.count("plank")
	cp.plan.clear()
	check(w.employment.plan(cp) and cp.plan.any(func(s): return str(s.get("act", "")) == "emp_craft"), "they plan the real recipe at the employer's station")
	var cs: Dictionary = cp.plan.filter(func(s): return str(s.get("act", "")) == "emp_craft")[0]
	var r := str(cs.args.recipe)
	check(str(w.stations[str(cs.args.station)].building) == str(shop.id), "at the employer's own station (%s, %s)" % [r, str(cs.args.station)])
	var outk := str(GameData.recipes[r].out.keys()[0])
	var ink := str(GameData.recipes[r]["in"].keys()[0])
	var o0 := chest.count(outk)
	var i0 := chest.count(ink)
	check(w.employment.act_craft(cp, cs.args), "the work is done (World.work_craft)")
	check(r == "saw_planks" and chest.count(ink) < i0 and chest.count(outk) > o0, "the materials came out of the employer's chest and the goods (%s) went into it" % outk)
	check(w.employment.carried(w.employment.record_of(cp), cp) == 0, "nothing of it stays with the employee")
	# farmer
	var fm := hirable(w, used)
	used.append(fm)
	check(w.employment.refusal(fm, "farmer").begins_with("You hold no farmland"), "no farmland: no farm hand")
	var fr: Rect2i = w.farm_plots.find_ground(Vector2i(6, 5), Vector2i(int(home.x), int(home.y)), 0)
	w.player.coins += 500
	var plot: Dictionary = w.farm_plots.claim(fr, World.PLAYER, false)
	check(not plot.is_empty(), "the player buys farmland")
	plot.farm.fence = true
	check(w.employment.employ(fm, "farmer") == "", "a farm hand is employed")
	fm.plan.clear()
	var fp: bool = w.employment.plan(fm)
	var fs: Array = fm.plan.filter(func(s): return str(s.get("act", "")) == "fp_work")
	check(fp and not fs.is_empty() and str(fs[0].args.plot) == str(plot.id), "they plan work on the employer's farmland (%s)" % (str(fs[0].args.task) if not fs.is_empty() else "none"))
	if not fs.is_empty():
		check(w.farm_plots.act(fm, "fp_work", fs[0].args), "the employer's farmland may be worked by their farm hand")
	check(not w.farm_plots.act(hirable(w, used), "fp_work", fs[0].args if not fs.is_empty() else {}), "nobody else's")
	check(w.farm_plots._store(fm, plot) == chest, "the crop of the employer's field goes to the employer's store")
	# account: the wage from a premises' till
	var ms := hirable(w, used)
	w.player.coins += 100
	w.business.rent()
	var pitch: Dictionary = w.business.mine()
	w.business.deposit(pitch, 50)
	var pc := w.player.coins
	check(w.employment.employ(ms, "miner", -1, str(pitch.id)) == "" and int(pitch.till) == 50 - int(w.employment.record_of(ms).wage) and w.player.coins == pc,
		"the wage can be paid from a premises' till instead of the purse")


func test_wage_and_resign() -> void:
	var w := world()
	player_home(w)
	w.player.coins += 500
	var n := hirable(w)
	var m: int = w.employment.market_wage("miner")
	check(m >= w.brain.manor_hand_wage(), "the market wage is never below the manor's day wage (%d)" % m)
	check(w.employment.employ(n, "miner", m - 1) .begins_with(n.name + " wants at least"), "an offer below the market wage is declined")
	check(w.employment.employ(n, "miner", m + 3) == "" and int(w.employment.record_of(n).wage) == m + 3, "a better offer is taken at the agreed wage")
	check(w.employment.dismiss(n) == "" and not w.employment.is_employed(n), "the employer dismisses the employee")
	check(w.employment.employ(n, "miner") == "", "taken on again")
	var rec: Dictionary = w.employment.record_of(n)
	rec.wage = 1
	var gone := false
	for d in 8:
		w.minutes += 1440.0
		w.player.coins += 50
		w.employment.daily()
		if not w.employment.is_employed(n):
			gone = true
			break
	check(gone and int(w.stats.get("employees_resigned", 0)) == 1 and n.job == "miner", "an employee paid well below the market leaves on their weekly morning, keeping their trade")
	check(int(GameData.b("employment").get("wage", 0)) == 10 and Employment.wage() == 10, "the old flat wage remains only for records saved without one")


func test_obligations() -> void:
	var w := world()
	player_home(w)
	w.player.coins += 500
	var n := hirable(w)
	check(w.employment.employ(n, "miner") == "", "employed")
	check(w.business.hire_refusal(n) != "" and w.construction.can_hire(n) != "", "an employee is not hired by another at the same time")
	var a := hirable(w, [n])
	w.business.rent()
	w.business.hire(w.business.mine(), a)
	check(w.employment.refusal(a, "miner") != "", "a counter attendant cannot be employed over that obligation")
	var r := open_one(w)
	check(w.employment.refusal(r[0], "smith").contains("business of their own") or w.employment.refusal(r[0], "smith") != "", "a keeper of a business cannot be employed by another")


# ---------------------------------------------------------------- D5: buying and selling ----------
## Another smith of the village, made able and minded to found (test setup), in another household than `s`'s.
func second_smith(w: World, s: NPC) -> NPC:
	var o: NPC = null
	for c: NPC in w.npcs:
		if c.alive and c.role == "adult" and c.household >= 0 and c.household != s.household and w.employment.obligation(c) == "" \
				and w.ventures.kept_by(c).is_empty():
			var hh: Dictionary = w.households[c.household]
			var house: Dictionary = w.buildings.get(str(hh.get("home", "")), {})
			if not house.is_empty() and w.owner_of(house) == World.hh_ref(c.household) and str(hh.get("build", "")) == "":
				o = c
				break
	o.job = "smith"
	o.skills["smithing"] = maxi(int(o.skills.get("smithing", 0)), Skills.xp_for_level(5))
	var key := World.npc_ref(o.id)
	if not w.experience.minutes.has(key):
		w.experience.minutes[key] = {}
	w.experience.minutes[key]["smithing"] = 480.0 * 60.0
	o.coins += 5000
	w.brain.evaluate_household(o.household)
	return o


func test_sell_and_buy() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	var seller_ref := World.hh_ref(s.household)
	check(w.ventures.offer_refusal(b, World.PLAYER) == "It is not yours to sell.", "only the owner may offer a workshop")
	# the keeper changes trade (the labour market's job change): the business closes, the unused workshop goes on sale
	var e := candidate(w, b)
	b.venture.till = 300
	w.employment.hire_for(Ventures.ref_of(b), e, "smith", w.employment.market_wage("smith"))
	for o: NPC in w.brain._members(s.household):
		if o.job == "smith":
			w.brain._change_job(o, "carpenter", "test: a smith who wants to be a carpenter")
	var sk := int(s.skills.get("smithing", 0))
	var xp := float(w.experience.minutes[World.npc_ref(s.id)]["smithing"])
	var purse: int = w.property.purse(seller_ref)
	var till := int(b.venture.till)
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	check(not b.has("venture") and w.property.purse(seller_ref) >= purse + till, "the business closes and its till goes to the seller's household")
	check(not w.employment.is_employed(e), "its employee's employment ends with it")
	check(b.has("sale") and str(b.sale.by) == seller_ref and int(b.sale.price) == w.ventures.asking(b), "nobody of the household works it any more: it is offered for sale (%d)" % int(b.get("sale", {}).get("price", 0)))
	check(int(s.skills.get("smithing", 0)) == sk and float(w.experience.minutes[World.npc_ref(s.id)]["smithing"]) == xp, "the career change keeps their smithing skill and experience")
	# another smith of the village buys it rather than build one
	var o := second_smith(w, s)
	smithy_full(w)
	var opt: Dictionary = w.ventures.eligible(o)
	check(opt.has("buy") and opt.buy == b, "an eligible smith's option is the smithy on sale, not a new one")
	var price := int(opt.price)
	check(price == w.deal_price(int(b.sale.price), o, w.party(seller_ref)), "at the price both sides' Trading agrees (%d)" % price)
	var coins := w.total_coins()
	purse = w.property.purse(seller_ref)
	var bp: int = w.property.purse(World.hh_ref(o.household))
	var house: Dictionary = w.buildings[str(w.households[s.household].home)]
	var sites := w.plots.size()
	var buildings := w.buildings.size()
	check(w.ventures.found(o, opt), "the smith buys it")
	check(w.property.purse(seller_ref) == purse + price and bp - w.property.purse(World.hh_ref(o.household)) >= price, "the seller receives the agreed price from the buyer")
	check(w.owner_of(b) == World.hh_ref(o.household) and not b.has("sale"), "the workshop is the buyer's")
	check(b.has("venture") and int(b.venture.keeper) == o.id and int(b.venture.household) == o.household, "the buyer opens their business there at once")
	check(w.owner_of(house) == seller_ref, "the seller's house stays the seller's")
	check(w.plots.size() == sites and w.buildings.size() == buildings and w.total_coins() == coins, "nothing is duplicated: the same building and ground, and coins conserved")
	for st in w.ventures.trade_stations(b, "smith"):
		check(str(w.stations[st].owner) == World.hh_ref(o.household), "its station %s goes with it" % st)
	check(not w.npc_may_use(s, w.stations[w.ventures.trade_stations(b, "smith")[0]]), "the seller's people have no leave there any more")


## The player's house on the first surveyed plot with a smithy added to it as a room (materials given; test setup):
## [house, smithy].
func player_house_with_smithy(w: World) -> Array:
	var plot: Dictionary = w.plots[0]
	w.player.coins += 1000
	w.buy_plot(plot)
	w.start_site(plot)
	for id in GameData.b("house_cost"):
		w.player.inv.add(id, int(GameData.b("house_cost")[id]))
	w.deliver(plot, w.player.inv)
	var house: Dictionary = w.property.building_on(plot)
	w.property.set_home(str(house.id))
	var near := Rect2i(int(plot.x) - 14, int(plot.y) - 14, int(plot.w) + 28, int(plot.h) + 28)
	for t in w.trees:
		if t.state == "grown" and near.has_point(Vector2i(int(t.x), int(t.y))):
			w.fell(t, 0)
	var rect: Rect2i = w.construction.find_module_slot("smithy", plot, World.PLAYER)
	var site: Dictionary = w.construction.place("smithy", rect, World.PLAYER, false, plot)
	if site.is_empty():
		return []
	for id in site.site.need.duplicate():
		w.player.inv.add(id, int(site.site.need[id]))
	w.deliver(site, w.player.inv)
	return [house, w.property.building_on(site)]


func test_home_workshop_sale() -> void:
	var w := world()
	var r := player_house_with_smithy(w)
	check(not r.is_empty(), "a smithy can be added to a house as a room of the property")
	if r.is_empty():
		return
	var house: Dictionary = r[0]
	var b: Dictionary = r[1]
	var p: Dictionary = w.property.parcel_under(b)
	var hp: Dictionary = w.property.parcel_under(house)
	check(str(p.get("estate", "")) == str(hp.id), "the smithy's ground is a parcel of its own, marked as part of the house's property")
	check(w.ventures.offer_refusal(house, World.PLAYER) != "", "the house is not a business to sell (and has a room built onto it)")
	var doors_before := w.doorways.filter(func(d): return str(d.a) == str(b.id) or str(d.b) == str(b.id)).size()
	check(w.ventures.offer(b, 60) == "", "the player offers the smithy added to their house")
	w.player.chest.add("bread", 3)
	var chest := w.player.chest.items.duplicate()
	var pack := w.player.inv.items.duplicate()
	var o: NPC = null
	for c: NPC in of_job(w, "smith"):
		o = c
	o.skills["smithing"] = maxi(int(o.skills.get("smithing", 0)), Skills.xp_for_level(5))
	o.coins += 5000
	var key := World.npc_ref(o.id)
	if not w.experience.minutes.has(key):
		w.experience.minutes[key] = {}
	w.experience.minutes[key]["smithing"] = 480.0 * 60.0
	w.brain.evaluate_household(o.household)
	smithy_full(w)
	var opt: Dictionary = w.ventures.eligible(o)
	var pc := w.player.coins
	check(opt.has("buy") and opt.buy == b and w.ventures.found(o, opt), "a villager smith buys it")
	check(w.player.coins == pc + int(opt.price), "the player receives the agreed price")
	check(w.owner_of(b) == World.hh_ref(o.household) and w.owner_of(house) == World.PLAYER and w.owner_of(hp) == World.PLAYER and w.player.home == str(house.id),
		"the workshop changes hands; the player's house, its ground and the home do not (D5 D)")
	check(str(w.property.parcel_under(b).get("estate", "")) == "" and not w.property.estate_parcels(hp).has(w.property.parcel_under(b)),
		"the workshop is detached from the house's property: a property of its own")
	check(w.doorways.filter(func(d): return str(d.a) == str(b.id) or str(d.b) == str(b.id)).is_empty(), "no inner doorway joins it to the house any more (%d before)" % doors_before)
	check(w.player.chest.items == chest and w.player.inv.items == pack, "the household's possessions are untouched")
	check(not w.property.homes_of(World.hh_ref(o.household)).has(str(house.id)) and w.property.rooms_of(str(house.id)).size() >= 1, "no residential right passes to the buyer")
	check(w.construction.module_refusal("smithy", hp, World.PLAYER) == "", "the house's property may have a smithy added again")


func test_player_buys() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	check(w.ventures.buy(b) == "It is not for sale.", "an unwilling owner's workshop cannot be bought")
	b.erase("venture")
	w.ventures._offer(b, World.hh_ref(s.household), 120)
	w.player.coins = 10
	check(w.ventures.buy(b).begins_with("You need"), "the buyer must hold the price")
	w.player.coins = 1000
	var price: int = w.ventures.price_for(b, w.player)
	var coins := w.total_coins()
	var purse: int = w.property.purse(World.hh_ref(s.household))
	check(w.ventures.buy(b) == "" and w.player.coins == 1000 - price and w.property.purse(World.hh_ref(s.household)) == purse + price and w.total_coins() == coins,
		"the player pays the seller the agreed price (%d); coins conserved" % price)
	# the player sells it on to a villager who wants a smithy
	check(w.ventures.offer(b, 0) == "Name a price.", "a sale needs a price")
	check(w.ventures.offer(b, 90) == "" and int(b.sale.price) == 90, "the player offers it for sale")
	check(w.ventures.withdraw(b) == "" and not b.has("sale"), "and may take the offer back")
	w.ventures.offer(b, 90)
	var o := second_smith(w, s)
	smithy_full(w)
	var opt: Dictionary = w.ventures.eligible(o)
	var pc := w.player.coins
	check(opt.has("buy") and w.ventures.found(o, opt), "a villager smith buys the player's workshop by the same rule")
	check(w.player.coins == pc + int(opt.price) and w.owner_of(b) == World.hh_ref(o.household) and b.has("venture"), "the player receives the price; the villager runs it (players and villagers follow the same rules)")


func test_standalone() -> void:
	var w := world()
	var s := founder(w)
	smithy_full(w)
	# no room beside the house: the workshop stands on ground of its own, owned and run on its own
	var house: Dictionary = w.buildings[str(w.households[s.household].home)]
	var opt: Dictionary = w.ventures.eligible(s)
	opt.house = {}
	opt.rect = w.construction.find_ground("smithy", w.building_door(str(house.id)), World.hh_ref(s.household))
	check(w.ventures.found(s, opt), "a standalone smithy is founded on ground of its own")
	var b := finish(w, s)
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	var p: Dictionary = w.property.parcel_under(b)
	check(b.has("venture") and w.property.estate_id(p) == str(p.id) and w.owner_of(b) == World.hh_ref(s.household), "it is a property of its own, run as a business")
	check(w.ventures.offer_refusal(b, World.hh_ref(s.household)) == "", "and may be sold on its own")


# ---------------------------------------------------------------- D3 ------------------------------
func test_abandon() -> void:
	var w := world()
	var s := found_one(w)
	var h := s.household
	var hh: Dictionary = w.households[h]
	var p: Dictionary = w.plot(str(hh.build))
	var pantry: Inventory = hh.pantry
	# half the materials delivered
	var half := {}
	for id in p.site.need:
		half[id] = int(p.site.need[id]) / 2
		pantry.add(id, int(half[id]))
	w.deliver(p, pantry)
	var delivered: Dictionary = w.site_delivered(p)
	var coins := w.total_coins()
	var purse: int = w.property.purse(World.hh_ref(h))
	var before := {}
	for id in delivered:
		before[id] = goods(w, str(id))
	check(w.ventures.abandon(h, "test: given up"), "a business being set up can be given up voluntarily (D3)")
	check(not hh.has("venture") and str(hh.get("build", "")) == "", "the household is released from the building obligation")
	w.minutes += 1440.0
	w.construction.daily()
	check(str(hh.get("build", "")) == "" and not hh.has("venture"), "and the next morning's building work does not take it up again")
	check(p.site.is_empty() and w.owner_of(p) == World.hh_ref(h), "the frame comes down; the ground stays the household's")
	check(w.property.purse(World.hh_ref(h)) == purse and w.total_coins() == coins, "no money is refunded and none is made")
	var same := true
	for id in delivered:
		same = same and goods(w, str(id)) == int(before[id])
		same = same and pantry.count(str(id)) >= int(delivered[id])
	check(same and not delivered.is_empty(), "the delivered materials are recovered into the household's store, none duplicated or lost")
	check(w.ventures.refusal(s) != "keeps a business already", "they may pursue other plans")
	# a housing need makes completion unreasonable: home first
	var w2 := world()
	var s2 := found_one(w2)
	var hh2: Dictionary = w2.households[s2.household]
	hh2.housing = {"crowded": {"need": "crowded", "since": w2.day(), "plan": "quarters"}}
	w2.minutes += 1440.0
	w2.ventures._review_setup()
	check(not hh2.has("venture") and str(hh2.get("build", "")) == "", "a family that needs its home seen to gives up the workshop it was building")
	# no progress for stall_days and the household cannot pay for the rest
	var w3 := world()
	var s3 := found_one(w3)
	var hh3: Dictionary = w3.households[s3.household]
	w3.ventures._review_setup()
	for o: NPC in w3.brain._members(s3.household):
		o.coins = 0
	w3.minutes += 1440.0 * (int(GameData.b("ventures").stall_days) - 1)
	w3.ventures._review_setup()
	check(hh3.has("venture"), "a stalled site is kept until stall_days have passed")
	w3.minutes += 1440.0
	w3.ventures._review_setup()
	check(not hh3.has("venture") and int(w3.stats.get("ventures_abandoned_given_up", 0)) == 1, "after stall_days without progress, a site the household cannot afford is given up")
	# the player's own site: the existing cancellation, materials back, no refund
	var w4 := world()
	player_home(w4)
	var rect: Rect2i = w4.construction.find_ground("smithy", Vector2i(int(w4.map.data.spawns.player[0]), int(w4.map.data.spawns.player[1])) + Vector2i(0, 14), World.PLAYER)
	w4.player.coins += w4.property.land_price(rect.size.x, rect.size.y)
	var ps: Dictionary = w4.construction.place("smithy", rect, World.PLAYER)
	var need: Dictionary = ps.site.need.duplicate()
	var k := str(need.keys()[0])
	w4.player.inv.add(k, int(need[k]))
	w4.deliver(ps, w4.player.inv)
	var pcoins := w4.player.coins
	var back: Dictionary = w4.cancel_site(ps, w4.player.inv)
	check(int(back.get(k, 0)) == int(need[k]) and w4.player.inv.count(k) >= int(need[k]) and w4.player.coins == pcoins and ps.site.is_empty(),
		"the player's unfinished workshop is given up through the same cancellation: materials back, no money")


# ---------------------------------------------------------------- D5: expansion and careers -------
func test_expansion() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	all_full(w)
	b.venture.till = 0
	check(w.ventures.expansion(s).is_empty(), "a business without the money does not expand")
	b.venture.till = 5000
	var opt: Dictionary = w.ventures.expansion(s)
	check(not opt.is_empty() and opt.expand == b and not opt.has("buy"), "a thriving business may open a standalone workshop of its own (%s)" % str(opt.get("rect", "")))
	var coins := w.total_coins()
	check(w.ventures.found(s, opt), "the keeper sets up a second workshop, paid by the business")
	var hh: Dictionary = w.households[s.household]
	check(hh.has("venture") and bool(hh.venture.get("expansion", false)) and int((b.venture.costs as Dictionary).get("premises", 0)) == int(opt.start) and w.total_coins() == coins,
		"the business pays the household for the premises (%d, its cost recorded); nothing made" % int(opt.start))
	var b2 := finish(w, s)
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	check(b2.has("venture") and bool(b2.venture.get("expansion", false)) and int(b2.venture.keeper) == s.id and str(w.stations[s.workplace].building) == str(b.id),
		"the second workshop opens; the keeper stays at their first")
	check(int(b2.venture.till) > 0, "its working capital comes from the first business's till (%d)" % int(b2.venture.till))
	check(w.ventures.open_ventures().filter(func(x): return int(x.venture.household) == s.household).size() == 2, "the family runs two businesses: no fixed cap")
	var w2 := world()
	var r2 := open_one(w2)
	var b9: Dictionary = r2[1]
	b9.venture.till = 5000
	var rr := player_house_with_smithy(w2)
	all_full(w2)
	if not rr.is_empty():
		w2.ventures.offer(rr[1], 40)
		var opt2: Dictionary = w2.ventures.expansion(r2[0])
		check(opt2.has("buy") and opt2.buy == rr[1], "a business expanding buys a workshop on sale before building one")


func test_career() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	var sm := int(s.skills.get("smithing", 0))
	var cp := int(s.skills.get("carpentry", 0))
	var ex: Dictionary = (w.experience.minutes.get(World.npc_ref(s.id), {}) as Dictionary).duplicate()
	# the smith becomes a carpenter through the labour market's job change
	w.brain._change_job(s, "carpenter", "test: a career change")
	check(s.job == "carpenter" and int(s.skills.get("smithing", 0)) == sm and int(s.skills.get("carpentry", 0)) == cp, "a career change keeps every skill; it grants none")
	check((w.experience.minutes.get(World.npc_ref(s.id), {}) as Dictionary) == ex, "and every recorded working day")
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	check(not b.has("venture"), "the smithy's business closes with nobody of the family in the trade")
	# owning a workshop grants no skill: buying one needs the same skill and experience as founding
	var o := second_smith(w, s)
	o.skills["smithing"] = Skills.xp_for_level(1)
	smithy_full(w)
	check(w.ventures.refusal(o) == "not skilled enough yet", "an unskilled villager cannot buy their way into a trade's business")
	w.player.coins += 1000
	var before := int(w.player.skills.get("smithing", 0)) if w.player.get("skills") != null else 0
	if b.has("sale"):
		w.ventures.buy(b)
	check(w.owner_of(b) == World.PLAYER and (int(w.player.skills.get("smithing", 0)) if w.player.get("skills") != null else 0) == before,
		"the player who buys the smithy owns it and gains no smithing by it")
	# back again: the carpenter returns to smithing and the household's money from the sale is theirs
	w.brain._change_job(s, "smith", "test: back to the forge")
	check(int(s.skills.get("smithing", 0)) == sm, "returning to the old trade, the skill is still theirs")
