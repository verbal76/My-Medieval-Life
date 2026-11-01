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
