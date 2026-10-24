extends SceneTree
## B18-DP-01 (owner, 2026-10-23), PL1-10 stage 4: an attendant hired under the existing hire and wage rules works the
## player's own workshop stations on the player's production orders, with the real recipes, materials and wages; the goods
## go into the stall's stock and sell by the existing rules; a stall shows its goods with the item icons; a leased village house
## opens as a shop under the lease and storefront rules and closes with the lease. Inputs, outputs and coins are conserved;
## missing materials, skill, tool or a free station stop the work; saves keep the orders and the workroom; the same seed
## gives the same result. Run:
##   godot --headless --path game --script res://tests/business_works_test.gd

const Census := preload("res://tests/census.gd")

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   ", what)
	else:
		failures += 1
		print("FAIL ", what)


func _init() -> void:
	GameData.ensure()
	_production()
	_orders_and_limits()
	_display()
	_leased_house()
	var a := _signature()
	var b := _signature()
	check(a == b, "the same seed gives the same production (%s)" % a)
	print("business_works_test: %d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A world on day 1 at 9:00; the player holds a village house with a stove and a workbench beside its door, rents a
## pitch and has hired an attendant.
func _world() -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 9.0 * 60.0
	var b: Dictionary = {}
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var x: Dictionary = w.buildings[id]
		if str(x.get("type", "")) == "house" and w.business.front_place(x).size() > 0:
			b = x
			break
	w.set_owner(b, World.PLAYER)
	var door := w.building_door(str(b.id))
	var kinds := ["stove", "workbench"]
	var placed := []
	for off in [Vector2i(2, 1), Vector2i(-3, 1), Vector2i(3, 1), Vector2i(-4, 1), Vector2i(4, 1), Vector2i(-5, 1), Vector2i(5, 1), Vector2i(-6, 1)]:
		if placed.size() >= kinds.size():
			break
		var c: Vector2i = door + off
		var ok := true
		for cc: Vector2i in [c, c + Vector2i(0, 1)]:
			if not w.map.in_village(cc) or w.map.is_solid(cc) or not w.plant_at(cc).is_empty() or not w.tree_at(cc).is_empty():
				ok = false
		if ok:
			var e := {"kind": kinds[placed.size()], "at": [c.x, c.y], "use": [c.x, c.y + 1]}
			if not b.has("fit"):
				b["fit"] = []
			b.fit.append(e)
			w.fitting.apply(b, e, false)
			placed.append(c)
	w.player.coins = 400
	w.player.inv.items.clear()
	w.business.rent()
	var s: Dictionary = w.business.mine()
	var cands := w.business.candidates()
	var att: NPC = cands[0]
	for o: NPC in w.npcs:
		if o != att:
			o.plan = [{"k": "work", "min": 99999.0, "anim": "work"}]
	w.business.hire(s, att)
	att.hunger = 100.0
	return {"w": w, "b": b, "s": s, "att": att}


func _player_goods(w: World, id: String) -> int:
	return int(Census.holders(w).get("player", {}).get(id, 0))


func _production() -> void:
	var sc := _world()
	var w: World = sc.w
	var s: Dictionary = sc.s
	var att: NPC = sc.att
	var biz: Business = w.business
	var wk: BusinessWorks = biz.works
	check(wk.stations().size() == 2 and wk.station_kinds().has("stove") and wk.station_kinds().has("workbench"), "the player's own stations are the two placed in their house")
	check(wk.recipes().has("brew_poultice") and wk.recipes().has("make_mallet") and not wk.recipes().has("smelt_iron"), "the recipes offered are those of the stations the player has")
	check(biz.is_attendant(att) and biz.attendant_of(s) == att, "the attendant was hired by the existing rule and paid by the existing wage")
	check(wk.add_order(s, "smelt_iron", 1) != "", "a recipe none of the player's stations makes cannot be ordered")
	check(wk.add_order(s, "brew_poultice", 3) == "" and wk.add_order(s, "brew_poultice", 2) != "", "an order for three batches of poultices; one order for each recipe")
	# no materials: nothing starts, the reason is kept, the attendant minds the counter
	check(wk.next_job(s, att).is_empty() and str(s.works_note).contains("workroom lacks"), "without materials nothing starts: " + str(s.works_note))
	att.plan.clear()
	check(biz.plan_attendant(att) and att.doing.contains("minding") and att.plan.size() == 2, "the attendant minds the counter meanwhile")
	# materials are set aside from the pack
	w.player.inv.add("flower", 7)
	check(wk.stock_work(s, "flower", 100) != "" and wk.stock_work(s, "flower", 6) == "" and w.player.inv.count("flower") == 1 and int(s.work.flower) == 6, "six flowers move from the pack to the workroom")
	var coins := w.total_coins()
	var goods0 := Census.goods(w)
	var pl0 := _player_goods(w, "flower")
	var wage_stat := float(w.stats.get("attendant_wages", 0.0))
	var used0 := float(w.stats.get("used_flower", 0.0))
	var made0 := float(w.stats.get("made_herbal_poultice", 0.0))
	# the plan: to the stove, the real craft, back to the counter and an hour minding it
	att.plan.clear()
	att.pos = w.building_door(str(sc.b.id)) + Vector2i(2, 2)
	check(biz.plan_attendant(att) and att.doing.contains("making brew poultice") and att.plan.size() == 4, "the attendant's day: " + att.doing)
	var step: Dictionary = att.plan[1]
	check(str(step.act) == "craft" and str(step.args.biz) == str(s.id) and wk.stations().has(str(step.args.station)), "the work is the villagers' own craft step at one of the player's stations")
	check(w.stations[step.args.station].users.has(att.id), "the station is held for the attendant while they work")
	# run the real world loop until the craft is done
	var steps := 0
	while float(w.stats.get("business_crafts", 0.0)) < 1.0 and steps < 4000:
		w.update(0.5)
		steps += 1
	check(steps < 4000 and float(w.stats.get("business_crafts", 0.0)) == 1.0, "the world's own loop carried the attendant to the stove and the craft was finished (%d steps)" % steps)
	var made := int(w.stats.get("made_herbal_poultice", 0.0) - made0)
	var used := int(w.stats.get("used_flower", 0.0) - used0)
	check(made >= 1 and (used == 2 or used == 0), "two flowers went in and a poultice came out (made %d, used %d)" % [made, used])
	check(int(s.stock.get("herbal_poultice", 0)) == made and int(s.prices.herbal_poultice) == GameData.value("herbal_poultice"), "the goods are in the stall's stock at the market value")
	check(int(wk.work_of(s).get("flower", 0)) == 6 - used, "the inputs left the workroom, only for the work done")
	check(int(wk.orders(s)[0].left) == 2, "the order counts down: two batches left")
	var gd := Census.goods(w)
	check(int(gd.get("herbal_poultice", 0)) - int(goods0.get("herbal_poultice", 0)) >= made - 0 and _player_goods(w, "flower") - pl0 == -used, "goods conserved: the player's holdings lost exactly the flowers used (%d) and gained the poultices made" % used)
	check(w.total_coins() == coins and float(w.stats.get("attendant_wages", 0.0)) == wage_stat, "no coins moved by the work itself")
	# wages by the existing rule
	w.minutes += 1440.0 - 60.0
	var tl := int(s.till)
	var ac := att.coins
	var pc := w.player.coins
	coins = w.total_coins()
	biz.daily()
	check(att.coins == ac + biz.wage() and w.total_coins() == coins and int(s.costs.wages) == 2 * biz.wage(), "the next morning the wage is paid as before (till then purse), coins conserved")
	check(not att.skills.is_empty() and att.skills.has("healing"), "the attendant gained Healing experience from the real recipe")
	# missing skill, then the tool
	att.plan.clear()
	var ale := "brew_ale"
	s.orders = []
	wk.add_order(s, ale, 1)
	w.player.inv.add("wheat", 3)
	wk.stock_work(s, "wheat", 3)
	att.skills.erase("cooking")
	check(wk.why_not(s, att, ale).contains("cooking level 2") and wk.next_job(s, att).is_empty(), "too little skill stops the work: " + wk.why_not(s, att, ale))
	att.skills["cooking"] = 400
	check(wk.why_not(s, att, ale) == "" and not wk.next_job(s, att).is_empty(), "with the skill it can start")
	var toolr := ""
	for r in GameData.recipes:
		if GameData.recipes[r].has("tool") and wk.recipes().has(r):
			toolr = r
	if toolr != "":
		for id in GameData.recipes[toolr]["in"]:
			s.work[id] = int(GameData.recipes[toolr]["in"][id])
		att.skills[str(GameData.recipes[toolr].skill)] = 400
		check(wk.why_not(s, att, toolr).contains("no "), "a recipe that needs a tool stops without one in the attendant's pack: " + wk.why_not(s, att, toolr))
	# a busy station
	var kind: String = GameData.recipes[ale].station
	var st := wk.free_station(att, kind)
	w.stations[st].users[9999] = w.minutes + 500.0
	w.npcs[0].plan = [{"k": "work", "args": {"station": st}, "min": 100.0}]
	var oth: NPC = w.npcs[0] if w.npcs[0] != att else w.npcs[1]
	w.stations[st].users.erase(9999)
	w.stations[st].users[oth.id] = w.minutes + 500.0
	oth.plan = [{"k": "work", "args": {"station": st}, "min": 100.0, "anim": "work"}]
	oth.target = -1
	check(wk.free_station(att, kind) == "" and wk.next_job(s, att).is_empty() and str(s.works_note).contains("busy"), "a station in use by someone else stops the work: " + str(s.works_note))
	oth.plan.clear()
	# dismissal stops it; closing the stall returns everything
	biz.dismiss(s)
	check(not biz.is_attendant(att) and not biz.plan_attendant(att), "dismissed, they work for nobody")
	var pack_before := w.player.inv.total()
	var inside := wk.work_total(s) + int(s.stock.get("herbal_poultice", 0))
	biz.close(s)
	check(w.player.inv.total() >= pack_before + inside - 0 and not s.has("work") and not s.has("orders"), "closing the stall returns the workroom and the stock to the pack (%d pieces)" % inside)


func _orders_and_limits() -> void:
	var sc := _world()
	var w: World = sc.w
	var s: Dictionary = sc.s
	var att: NPC = sc.att
	var wk: BusinessWorks = w.business.works
	# a keep-stock order stops at the target and starts again below it
	check(wk.add_order(s, "make_mallet", 0, 2) == "", "keep two mallets in stock")
	w.player.inv.add("log", 4)
	w.player.inv.add("plank", 4)
	wk.stock_work(s, "log", 4)
	wk.stock_work(s, "plank", 4)
	check(not wk.next_job(s, att).is_empty() and str(wk.next_job(s, att).recipe) == "make_mallet", "below the target the attendant starts the recipe")
	s.stock["mallet"] = 2
	check(wk.next_job(s, att).is_empty(), "at the target nothing is made")
	s.stock["mallet"] = 1
	check(not wk.next_job(s, att).is_empty(), "below it again, it is made again")
	# finishing without the materials makes nothing and keeps the reason
	s.work.clear()
	check(not wk.finish(att, {"biz": str(s.id), "recipe": "make_mallet", "station": ""}) and str(s.works_note).contains("could not"), "a craft whose materials are gone makes nothing: " + str(s.works_note))
	# the stall's own limits
	check(wk.add_order(s, "make_mallet", 3) != "", "one order for each recipe")
	for r in ["brew_poultice", "brew_tonic", "weave_cloth", "tan_leather", "leather_cap"]:
		wk.add_order(s, r, 1)
	check(wk.orders(s).size() <= BusinessWorks.MAX_ORDERS, "the orders stay within the window's limit")
	# save and load keep orders, workroom and note
	s.work = {"flower": 3}
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var s2: Dictionary = w2.business.mine()
	check(w2.business.works.orders(s2).size() == wk.orders(s).size() and int(w2.business.works.work_of(s2).flower) == 3, "save and load keep the orders and the workroom")
	check(w2.total_coins() == w.total_coins() and Census.goods(w2) == Census.goods(w), "and every coin and every good")
	# an older save has neither
	for st: Dictionary in d.stalls.values():
		st.erase("orders")
		st.erase("work")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d)
	check(w3.business.works.orders(w3.business.mine()).is_empty() and w3.business.works.work_total(w3.business.mine()) == 0, "a save made before production has no orders and an empty workroom")


func _display() -> void:
	var sc := _world()
	var w: World = sc.w
	var s: Dictionary = sc.s
	var biz: Business = w.business
	w.player.inv.add("plank", 8)
	w.player.inv.add("iron_ore", 5)
	w.player.inv.add("log", 2)
	biz.list_item(s, "plank", 8)
	biz.list_item(s, "iron_ore", 5)
	biz.list_item(s, "log", 2)
	var g := Business.display_goods(s, 4)
	check(g == ["plank", "iron_ore", "log"], "the counter shows the stall's real goods, the most plentiful first: " + str(g))
	check(Business.display_goods(s, 2) == ["plank", "iron_ore"], "at most as many kinds as the counter has room for")
	check(biz.shelves().any(func(d): return int(d.x) == int(s.x) and int(d.y) == int(s.y) and d.goods == g), "the stall is among the shelves to draw, at its own place (GP-MARKET-SHELVES)")
	w.minutes = 1440.0 + 9.0 * 60.0
	w.npcs[0].coins = 100
	check(biz.sell(s, w.npcs[0], "iron_ore", 5, 3), "the iron ore sells out")
	check(not Business.display_goods(s, 4).has("iron_ore") and Business.display_goods(s, 4).size() == 2, "a sold-out kind leaves the counter")
	check(biz.set_display(s, "log") != "", "only a larger stall features an item")
	s.large = true
	biz.set_display(s, "log")
	check(Business.display_goods(s, 4)[0] == "log", "a larger stall's featured item comes first")
	for id in Business.display_goods(s, 4):
		check(ResourceLoader.exists("res://assets/icons/%s.png" % id), "the existing item icon for %s is there" % id)
	# demand: a hurt villager with no medicine buys a poultice the attendant made (the existing selling rules)
	s.stock["herbal_poultice"] = 2
	s.prices["herbal_poultice"] = GameData.value("herbal_poultice")
	var buyer: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "merchant" and o.household >= 0:
			buyer = o
			break
	buyer.hp = 1.0
	buyer.coins = 100
	(w.households[buyer.household].pantry as Inventory).add("log", 5)
	for m in NPCBrain.MEDICINES:
		buyer.inv.items.erase(m)
		(w.households[buyer.household].pantry as Inventory).items.erase(m)
	var coins := w.total_coins()
	var till := int(s.till)
	var o := biz.offer(buyer, s)
	check(not o.is_empty() and str(o.item) == "herbal_poultice", "a hurt villager with no medicine would buy one: " + str(o.get("item", "")))
	check(biz.sell(s, buyer, o.item, int(o.qty), int(o.price), bool(o.pantry)) and int(s.till) == till + int(o.qty) * int(o.price) and w.total_coins() == coins, "and buys it by the existing sale: the coins in the till, conserved")


func _leased_house() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 9.0 * 60.0
	var biz: Business = w.business
	var b: Dictionary = {}
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var x: Dictionary = w.buildings[id]
		if str(x.get("type", "")) == "house" and biz.front_place(x).size() > 0:
			b = x
			break
	if not b.is_empty():
		var hh := w.household_in(str(b.id))
		if hh >= 0:
			for m in w.households[hh].members:
				w.npc(int(m)).alive = false
		w.set_owner(b, World.MANOR)            # the household died out: the house fell back to the manor, which lets it
		w.set_tenant(b, "")
	check(not b.is_empty(), "a village house the manor lets, with room for a counter (%s)" % b.get("id", "?"))
	check(b.is_empty() or w.property.for_sale(b), "the manor has it for sale or lease")
	if b.is_empty():
		return
	w.player.coins = 500
	check(biz.storefront_refusal(b) != "", "a house the player does not hold cannot have a storefront")
	var t0 := w.treasury
	check(w.property.lease(b, World.PLAYER) == "" and w.tenant_of(b) == World.PLAYER and w.owner_of(b) == World.MANOR and w.treasury > t0, "the player leases it from the manor: the rent goes to the treasury")
	for id in Business.storefront_cost():
		w.player.inv.add(id, int(Business.storefront_cost()[id]))
	check(biz.storefront_refusal(b) == "", "a leased house can have a storefront under the same rules")
	check(biz.build_storefront(b) == "" and b.has("shop") and biz.is_mine(b.shop) and biz.premises().has(b.shop), "built and open as a shop of the player's")
	check(biz.rent_of(b.shop) == 0, "no licence on top of the lease")
	w.player.inv.add("herbal_poultice", 4)
	check(biz.list_item(b.shop, "herbal_poultice", 4) == "", "goods go up for sale")
	var buyer: NPC = w.npcs[0]
	buyer.coins = 200
	var coins := w.total_coins()
	w.player.pos = biz.use_cell(b.shop)
	check(biz.attended(b.shop) and biz.sell(b.shop, buyer, "herbal_poultice", 2, 6) and int(b.shop.till) == 12 and w.total_coins() == coins, "it sells; the sale is in the shop's own till (ECON-P3), conserved")
	w.minutes += 1440.0
	var c0 := w.total_coins()
	biz.daily()
	check(w.total_coins() == c0 and b.has("shop") and int(b.shop.till) == 12, "a morning on: the shop's till is the player's, not the household money")
	# the lease ends: the shop closes with it, the goods and the till come home, the counter stays
	var till := int(b.shop.till)
	var pc := w.player.coins
	check(w.property.end_lease(b, World.PLAYER) == "" and not b.has("shop"), "giving up the lease closes the shop at once")
	check(w.player.inv.count("herbal_poultice") == 2 and w.player.coins >= pc + till - 100, "the unsold goods and the till came back to the player")
	check(b.has("front") and w.map.is_solid(Vector2i(int(b.front.x), int(b.front.y))), "the counter stays with the house")


func _signature() -> String:
	var sc := _world()
	var w: World = sc.w
	var s: Dictionary = sc.s
	var att: NPC = sc.att
	var wk: BusinessWorks = w.business.works
	wk.add_order(s, "brew_poultice", 2)
	w.player.inv.add("flower", 4)
	wk.stock_work(s, "flower", 4)
	att.plan.clear()
	att.pos = w.building_door(str(sc.b.id)) + Vector2i(2, 2)
	w.business.plan_attendant(att)
	var steps := 0
	while float(w.stats.get("business_crafts", 0.0)) < 1.0 and steps < 4000:
		w.update(0.5)
		steps += 1
	return "steps %d stock %s work %s total %d" % [steps, str(s.stock), str(s.get("work", {})), w.total_coins()]
