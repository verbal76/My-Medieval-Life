extends SceneTree
## The player's market stall and the villagers who buy from it (PL1-10 stages 1 and 2): renting a pitch,
## listing, pricing, taking back, closing, the daily rent and what unpaid rent does, sales only while the
## player is there, demand only for real needs within real budgets, coins conserved, save and load; and (stages 3-4)
## the larger stall, equipment placed in a built room, a shop with shelves, a back room and books, trade from the
## equipment, hired attendants who sell while the player is away and are paid daily, save and load. Run:
##   godot --headless --path game --script res://tests/business_test.gd

var failures := 0
var checks := 0
var main
var w: World
const TEST_SAVE := "user://test_saves/business_test/save1.json"


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = TEST_SAVE
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	main.new_game()
	_fresh()
	_rent()
	_list_price_close()
	_attended_sales()
	_demand()
	_walk()
	_rent_daily()
	_larger_stall()
	_shop()
	_attendant()
	_shop_save()
	_save_load()
	_wiki()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _fresh() -> void:
	w = main.world
	var s: Dictionary = w.business.mine()
	if not s.is_empty():
		w.business.close(s)
	w.player.coins = 100
	w.player.inv.items.clear()
	w.player.stolen.clear()


func _job(job: String) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.job == job and n.role == "adult":
			return n
	return null


func _stall_at() -> void:
	var s: Dictionary = w.business.mine()
	w.player.pos = w.business.use_cell(s) + Vector2(0, 1)


func _rent() -> void:
	var b: Business = w.business
	var pitches: Array = w.stalls.values().filter(func(s): return Business.is_pitch(s))
	check(pitches.size() == Business.PITCHES.size() and w.tenant_of(pitches[0]) == "", "the manor keeps open pitches in the market")
	check(w.stalls.values().filter(func(s): return not Business.is_pitch(s) and w.tenant_of(s) != "").size() == 6, "the six merchants keep their own stalls; no merchant took a pitch")
	var total := w.total_coins()
	var treasury := w.treasury
	check(b.rent_refusal() == "", "a pitch can be rented")
	w.player.coins = 3
	check(b.rent_refusal() != "" and b.rent() != "", "not with fewer coins than the day's rent")
	w.player.coins = 100
	total = w.total_coins()
	check(b.rent() == "", "rent: done")
	check(w.player.coins == 100 - Business.rent_day() and w.treasury == treasury + Business.rent_day(), "the first day's rent goes from the purse to the treasury (%d coins)" % Business.rent_day())
	check(w.total_coins() == total, "coins are conserved")
	var s := b.mine()
	check(not s.is_empty() and w.tenant_of(s) == World.PLAYER, "the player is the stall's tenant")
	check(b.rent() != "", "only one stall at a time")
	w.property.relet_stalls()
	check(w.tenant_of(s) == World.PLAYER, "the manor's re-letting leaves the player's pitch alone")
	check(Business.rent_day() == 5, "rent is about 5 coins a day (balance.json)")
	var costs_ok: bool = b.mine().id == "pitch0" and w.map.is_solid(Vector2i(int(s.x), int(s.y))) and not w.map.is_solid(Vector2i(int(s.use[0]), int(s.use[1])))
	check(costs_ok, "the pitch is drawn solid with a free place to stand")


func _list_price_close() -> void:
	var b: Business = w.business
	var p := w.player
	var s := b.mine()
	p.inv.add("plank", 6)
	p.inv.add("iron_ore", 4)
	p.inv.add("pickaxe", 1)
	check(b.list_item(s, "plank", 7) != "" and p.inv.count("plank") == 6, "listing more than you carry is refused and changes nothing")
	check(b.list_item(s, "plank", 6) == "" and b.list_item(s, "iron_ore", 4) == "" and b.list_item(s, "pickaxe", 1) == "", "list planks, ore and a tool")
	check(p.inv.count("plank") == 0 and int(s.stock.plank) == 6 and int(s.stock.iron_ore) == 4 and int(s.stock.pickaxe) == 1, "the goods left the pack for the stall's stock")
	check(b.price_of(s, "plank") == GameData.value("plank"), "a new listing starts at the market value")
	check(b.set_price(s, "plank", 0) != "" and b.set_price(s, "plank", GameData.value("plank") * Business.PRICE_CAP + 1) != "", "a price of 0 or beyond the cap is refused")
	check(b.set_price(s, "plank", 4) == "" and b.price_of(s, "plank") == 4, "set a price")
	check(b.set_price(s, "axe", 4) != "", "no price for what is not listed")
	check(b.unlist(s, "plank", 2) == "" and int(s.stock.plank) == 4 and p.inv.count("plank") == 2, "take some back")
	check(b.unlist(s, "plank", 5) != "", "not more than the stall holds")
	check(b.list_item(s, "plank", 2) == "" and int(s.stock.plank) == 6 and b.price_of(s, "plank") == 4, "adding to a listing keeps its price")
	p.inv.add("log", 5)
	p.stolen["log"] = {"7": 2}
	check(b.listable("log") == 3 and b.list_item(s, "log", 4) != "", "goods marked stolen cannot be put up (no fencing)")
	p.stolen.clear()
	p.inv.remove("log", 5)
	# closing returns everything, the till too
	s.till = 9
	var coins := p.coins
	var line := b.close(s)
	check(p.inv.count("plank") == 6 and p.inv.count("iron_ore") == 4 and p.inv.count("pickaxe") == 1, "closing returns every item to the pack: " + line)
	check(p.coins == coins + 9 and w.tenant_of(s) == "" and not s.has("stock"), "and the till; the pitch is free again")
	# a full pack: what does not fit lies at the stall
	check(b.rent() == "" and b.mine().id == s.id, "rent again")
	s = b.mine()
	check(b.list_item(s, "plank", 6) == "" and b.list_item(s, "iron_ore", 4) == "", "stock again")
	p.inv.items.clear()
	for i in 3:
		p.inv.add(["axe", "hammer", "log"][i], 1)
	p.inv.max_stacks = p.inv.items.size()
	var loot0 := w.loot.size()
	b.close(s)
	check(p.inv.max_stacks == p.inv.items.size() and w.loot.size() == loot0 + 1 and w.loot[-1].inv.total() == 10 and w.loot[-1].from == "your stall", "a pack with no room leaves the goods at the stall as loot, none lost")
	w.loot.pop_back()
	p.inv.max_stacks = 0
	p.inv.items.clear()
	p.coins = 100


func _stock_up(planks := 20, ore := 20) -> Dictionary:
	var b: Business = w.business
	if b.mine().is_empty():
		b.rent()
	var s := b.mine()
	var p := w.player
	p.inv.add("plank", planks)
	p.inv.add("iron_ore", ore)
	p.inv.add("pickaxe", 1)
	p.inv.add("axe", 1)
	b.list_item(s, "plank", planks)
	b.list_item(s, "iron_ore", ore)
	b.list_item(s, "pickaxe", 1)
	b.list_item(s, "axe", 1)
	_stall_at()
	return s


func _attended_sales() -> void:
	var b: Business = w.business
	var smith := _job("smith")
	var s := _stock_up()
	smith.coins = 200
	smith.inv.items.erase("iron_ore")
	var total := w.total_coins()
	var o := b.offer(smith, s)
	check(o.get("item", "") != "" and int(o.price) == b.price_of(s, o.item), "the smith has a need the stall can meet: " + str(o))
	w.player.pos = Vector2(5, 5)
	check(not b.attended(s) and not b.arrive(smith, {"stall": s.id, "item": o.item}), "no sale while the player is away")
	_stall_at()
	var till := int(s.till)
	var coins := smith.coins
	var had := smith.inv.count(o.item)
	check(b.arrive(smith, {"stall": s.id, "item": o.item}), "a sale while the player stands at the stall")
	var paid: int = int(s.till) - till
	check(paid > 0 and smith.coins == coins - paid and smith.inv.count(o.item) > had, "coins went from the smith to the till, the goods into the smith's pack")
	check(w.total_coins() == total, "coins are conserved (the till counts)")
	check(s.sales.size() == 1 and int(s.sales[0].price) == int(o.price), "the sale is recorded")
	s.missed = 1
	check(not b.attended(s), "no sales while the rent is owing")
	s.missed = 0
	# STALL-05 / Q13 (owner 2026-10-21): a market stall's proceeds come by closing it; the session is settled, the
	# manor's 5% (with the carried fraction) to the treasury, the rest into the purse; it may be opened again at once
	var held := w.player.coins
	var treasury := w.treasury
	var due: Vector2i = b.stalls.due(s)
	check(b.stalls.unsettled(s) == paid and b.stalls.withdrawable(s) == 0, "the open session's %d coins are held, not withdrawable" % paid)
	check(b.collect(s) == paid - due.x and w.player.coins == held + paid - due.x and w.treasury == treasury + due.x and int(s.till) == 0, "collecting closes the stall and settles the till: %d to the purse, %d to the manor" % [paid - due.x, due.x])
	check(w.total_coins() == total, "coins are conserved by the settlement")
	check(not b.attended(s) and b.stalls.open(s, World.PLAYER) == "" and b.attended(s), "closed after settling, opened again at once")


func _demand() -> void:
	var b: Business = w.business
	var s := _stock_up()
	_stall_at()
	# the smith buys ore until the need is met, then no more
	var smith := _job("smith")
	smith.coins = 500
	smith.inv.items.erase("iron_ore")
	smith.inv.items.erase("plank")
	smith.inv.items.erase("coal")
	smith.inv.items.erase("copper_ore")
	smith.inv.items.erase("gold_ore")
	smith.inv.items.erase("leather")
	# B14 local pricing: a stall dearer than the village's local price for ore loses the sale to the merchants
	s.prices["iron_ore"] = b.ceiling("iron_ore", 0, s, smith) + 1
	check(b.offer(smith, s).get("item", "") != "iron_ore", "a stall asking more than the local price (%d) sells the smith no ore" % b.ceiling("iron_ore", 0, s, smith))
	s.prices["iron_ore"] = b.ceiling("iron_ore", 0, s, smith)          # priced to the local market, it gets the trade
	var n_buys := 0
	for i in 20:
		var o := b.offer(smith, s)
		if o.is_empty() or not b.arrive(smith, {"stall": s.id, "item": o.item}):
			break
		n_buys += 1
	check(n_buys > 0 and b.offer(smith, s).is_empty(), "the smith bought what he needed (%d visits) and then buys nothing more" % n_buys)
	check(smith.inv.count("iron_ore") * 2 >= 30 and smith.inv.count("plank") * 2 >= 10, "his ore and planks are at the level he restocks to (ore %d, planks %d)" % [smith.inv.count("iron_ore"), smith.inv.count("plank")])
	# the carpenter buys planks for an open building site
	var carp := _job("carpenter")
	carp.coins = 300
	carp.inv.items.erase("plank")
	check(b.needs(carp).filter(func(x): return x.item == "plank").is_empty(), "the carpenter needs no planks while no site asks for them")
	var site: Dictionary = w.plots[0]
	var saved_site: Dictionary = site.site
	site.site = {"need": {"plank": 8}, "done": false, "owner": World.PLAYER}
	s.stock.plank = 10
	s.prices.plank = GameData.value("plank")
	var o2 := b.offer(carp, s)
	check(o2.get("item", "") == "plank" and int(o2.qty) <= 6, "the carpenter buys planks for an open site: " + str(o2))
	var cc := carp.coins
	check(b.arrive(carp, {"stall": s.id, "item": "plank"}) and carp.inv.count("plank") == int(o2.qty) and carp.coins == cc - int(o2.qty) * int(o2.price), "and pays for them from his own coins")
	site.site = saved_site
	check(b.needs(carp).filter(func(x): return x.item == "plank").is_empty(), "the site finished, the need is gone")
	# a tool: a farmer has no tool need; a woodcutter without an axe has, and must be able to pay
	var farmer := _job("farmer")
	farmer.coins = 500
	check(b.offer(farmer, s).get("item", "") != "pickaxe" and b.offer(farmer, s).get("item", "") != "axe", "a farmer, needing no tool, is not offered the tool")
	var wc := _job("woodcutter")
	wc.inv.items.erase("axe")
	for id in ["log"]:
		wc.inv.items.erase(id)
	wc.coins = 2
	check(b.offer(wc, s).is_empty(), "a woodcutter without an axe cannot pay the stall's price: nothing bought")
	wc.coins = 100
	var ow := b.offer(wc, s)
	check(ow.get("item", "") == "axe", "with coins he considers the axe: " + str(ow))
	var axe_price := b.price_of(s, "axe")
	s.prices.axe = GameData.value("axe") * Business.PRICE_CAP
	check(b.offer(wc, s).is_empty(), "but not at four times the market price (the merchants sell it for less)")
	s.prices.axe = axe_price
	check(b.arrive(wc, {"stall": s.id, "item": "axe"}) and wc.inv.has("axe") and b.offer(wc, s).is_empty(), "he buys it once and the need is met")
	# a miner without a pickaxe, a guard without gear, a household without firewood
	var miner := _job("miner")
	miner.inv.items.erase("pickaxe")
	miner.inv.items.erase("rusty_pickaxe")
	miner.coins = 100
	check(b.offer(miner, s).get("item", "") == "pickaxe", "a miner without a pickaxe is a buyer")
	var kid: NPC = null
	for n: NPC in w.npcs:
		if n.role == "child":
			kid = n
	check(kid == null or b.needs(kid).is_empty(), "children do not shop")
	check(_job("merchant") == null or b.needs(_job("merchant")).is_empty(), "merchants do not shop for stock")
	var head: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and w.party("hh:%d" % n.household) == n and n.job != "merchant":
			head = n
			break
	var hh: Dictionary = w.households[head.household]
	(hh.pantry as Inventory).items.erase("log")
	head.coins = 50
	s.stock.log = 5
	s.prices.log = GameData.value("log")
	var ol := b.offer(head, s)
	check(ol.get("item", "") == "log" and bool(ol.pantry), "a household with no firewood buys logs for its pantry: " + str(ol))
	var pan: int = (hh.pantry as Inventory).count("log")
	check(b.arrive(head, {"stall": s.id, "item": "log"}) and (hh.pantry as Inventory).count("log") == pan + int(ol.qty), "the logs go into the household's pantry")
	check(b.offer(head, s).get("item", "") != "log", "firewood in the pantry, no more is bought")
	# the hourly round sends a few idle buyers, never more than the limit, never when the player is away
	for n: NPC in w.npcs:
		n.plan = []
	var wood := _job("woodcutter")
	wood.inv.items.erase("axe")
	wood.coins = 100
	s.stock.axe = 1
	b.heading.clear()
	w.player.pos = Vector2(5, 5)
	b.hour()
	check(b.heading.is_empty(), "no buyers are sent while the player is away")
	_stall_at()
	b.hour()
	check(b.heading.size() >= 1 and b.heading.size() <= int(GameData.b("stall_buyers_per_hour")), "buyers are sent, at most %d an hour (%d)" % [int(GameData.b("stall_buyers_per_hour")), b.heading.size()])
	for id in b.heading:
		var n := w.npc(int(id))
		check(n.plan.size() == 2 and n.plan[1].act == "buy_stall", "%s walks to the stall to buy" % n.name)
		break


func _walk() -> void:
	# a real trip: the buyer's plan walks him to the stall and the purchase happens on arrival
	var b: Business = w.business
	var s := b.mine()
	for n: NPC in w.npcs:
		n.plan = [{"k": "work", "min": 99999.0, "anim": "work"}]       # busy: only the woodcutter is free to come
	var wc := _job("woodcutter")
	wc.plan = []
	wc.inv.items.erase("axe")
	wc.coins = 100
	s.stock.axe = 1
	s.prices.axe = GameData.value("axe")
	b.heading.clear()
	_stall_at()
	var sent := wc.coins
	b.hour()
	var queued := b.heading.has(wc.id)
	var before := int(s.till)
	for i in 1200:
		if not queued or wc.inv.has("axe"):
			break
		w.player.pos = b.use_cell(s) + Vector2(0, 1)
		w.update(0.25)
	check(queued, "the woodcutter set out for the stall")
	if queued:
		check(wc.inv.has("axe") and wc.coins < sent and int(s.till) > before, "he walked to the stall and bought the axe (till +%d)" % (int(s.till) - before))


func _rent_daily() -> void:
	var b: Business = w.business
	var p := w.player
	var s := b.mine()
	p.coins = 50
	s.till = 0
	var total := w.total_coins()
	var treasury := w.treasury
	var paid_day := int(s.paid_day)
	w.minutes += 1440.0
	b.daily()
	check(int(s.paid_day) == paid_day + 1 and p.coins == 50 - Business.rent_day() and w.treasury == treasury + Business.rent_day(), "rent is paid each morning from the purse to the treasury")
	check(w.total_coins() == total, "coins are conserved by the rent")
	b.daily()
	check(p.coins == 50 - Business.rent_day(), "never twice in a day")
	# a poor morning: settled coins left in the till cover the rent (an older save's till: no open session)
	p.coins = 1
	s.erase("session")
	s.till = 12
	w.minutes += 1440.0
	b.daily()
	check(int(s.missed) == 0 and int(s.till) + p.coins == 12 + 1 - Business.rent_day(), "the till pays the rent when the purse cannot")
	# STALL-05 / Q13 (owner 2026-10-21): an open session's proceeds are not withdrawable, so the rent is not taken from them
	p.coins = 1
	s.till = 12
	s.session = {"gross": 12, "sold": {"plank": 3}, "day": w.day(), "hour": 9, "seller": World.PLAYER}
	w.minutes += 1440.0
	b.daily()
	check(int(s.missed) == 1 and int(s.till) == 12 and p.coins == 1, "the open session's proceeds do not pay the rent: it is owing")
	p.coins = Business.rent_day() * 3
	check(b.pay_arrears(s) == "" and int(s.missed) == 0, "paid from the purse")
	# nothing to pay with: sales stop, then the pitch goes back with the goods
	p.coins = 0
	s.erase("session")
	s.till = 0
	var stock_planks := int(s.stock.get("plank", 0))
	w.minutes += 1440.0
	b.daily()
	check(int(s.missed) == 1 and not b.attended(s) and not s.is_empty() and w.tenant_of(s) == World.PLAYER, "unpaid rent stops sales; the stall is still yours")
	p.coins = Business.rent_day() * 3
	check(b.pay_arrears(s) == "" and int(s.missed) == 0, "paying what is owed opens it again")
	p.coins = 0
	w.minutes += 1440.0
	b.daily()
	w.minutes += 1440.0
	b.daily()
	check(w.tenant_of(s) == "" and not s.has("stock"), "rent unpaid for %d mornings: the manor takes the pitch back" % int(GameData.b("stall_evict_days")))
	check(p.inv.count("plank") >= stock_planks and (stock_planks == 0 or p.inv.count("plank") > 0), "the unsold goods came back to the player (%d planks)" % p.inv.count("plank"))

# ---------------------------------------------------------------- stages 3 and 4 -------------------
func _finish(pl: Dictionary) -> void:
	for id in pl.site.need.duplicate():
		w.player.inv.add(id, int(pl.site.need[id]))
	w.deliver(pl, w.player.inv, World.PLAYER)


## A leased plot with a finished house of the player's and a storeroom added to the property (a modular
## room, PL2-008/014: its floor has space for equipment); returns the storeroom.
func _own_house() -> Dictionary:
	w.player.coins = 3000
	var pl: Dictionary = w.plots[0]
	w.property.lease(pl, World.PLAYER)
	w.start_site(pl, "house", World.PLAYER)
	_finish(pl)
	var box := Rect2i(int(pl.x) - 40, int(pl.y) - 40, int(pl.w) + 80, int(pl.h) + 80)
	for t in w.trees:
		if box.has_point(Vector2i(int(t.x), int(t.y))):
			t.state = "cleared"
			w.map.set_solid(Vector2i(int(t.x), int(t.y)), false)
	var c: Construction = w.construction
	var m: Dictionary = c.place("storage", c.find_module_slot("storage", pl, World.PLAYER), World.PLAYER, false, pl)
	_finish(m)
	return w.property.building_on(m)


func _give(kind: String) -> void:
	var c := Fitting.cost(kind)
	for id in c:
		w.player.inv.add(id, int(c[id]))


func _free_cell(b: Dictionary, kind: String, skip := 0) -> Vector2i:
	var cells: Array = w.fitting.floor_set(b).keys()
	cells.sort_custom(func(m: Vector2i, n: Vector2i): return m.y < n.y or (m.y == n.y and m.x < n.x))
	for c: Vector2i in cells:
		if w.fitting.why_not(b, kind, c) == "" or (w.fitting.why_not(b, kind, c).begins_with("you need") and skip == 0):
			if skip > 0:
				skip -= 1
				continue
			return c
	return Vector2i(-1, -1)


func _larger_stall() -> void:
	var b: Business = w.business
	_fresh()
	w.player.coins = 100
	w.player.inv.items.clear()
	b.rent()
	var s := b.mine()
	var cap := b.listing_cap(s)
	check(cap == int(GameData.b("stall_max_listings")) and not bool(s.get("large", false)), "a plain stall holds %d kinds" % cap)
	w.player.coins = 10
	check(b.upgrade(s) != "" and not bool(s.get("large", false)), "a larger stall needs its price")
	w.player.coins = 100
	var treasury := w.treasury
	var total := w.total_coins()
	check(b.upgrade(s) == "" and bool(s.large) and w.player.coins == 100 - int(GameData.b("stall_large_cost")), "it is bought from the manor")
	check(w.treasury == treasury + int(GameData.b("stall_large_cost")) and w.total_coins() == total, "the price went to the treasury: coins conserved")
	check(b.listing_cap(s) == int(GameData.b("stall_large_listings")) and b.rent_of(s) == int(GameData.b("stall_large_rent_day")) and b.rent_of(s) > Business.rent_day(), "it holds more kinds and costs more a day")
	check(b.upgrade(s) != "", "it cannot be bought twice")
	var kinds := GameData.items.keys().filter(func(k): return GameData.value(k) > 0)
	kinds.sort()
	for i in b.listing_cap(s):
		w.player.inv.add(kinds[i], 1)
	var ok := 0
	for i in b.listing_cap(s):
		if b.list_item(s, kinds[i], 1) == "":
			ok += 1
	check(ok == b.listing_cap(s) and s.stock.size() > int(GameData.b("stall_max_listings")), "a larger stall takes %d kinds, more than a plain one" % ok)
	check(b.set_display(s, kinds[0]) == "" and str(s.display) == kinds[0] and b.set_display(s, "zzz") != "", "one of the goods on sale can be displayed")
	w.minutes += 1440.0
	var before := w.player.coins
	w.player.pos = Vector2(5, 5)
	b.daily()
	check(w.player.coins == before - b.rent_of(s) and int(s.costs.rent) == Business.rent_day() + b.rent_of(s), "the larger rent is taken each morning and kept in the expenses")
	check(b.expenses(s) == Business.rent_day() + int(GameData.b("stall_large_cost")) + b.rent_of(s) and b.profit(s) == -b.expenses(s), "revenue less expenses is the profit")
	var line := b.close(s)
	check(not s.has("large") and not s.has("display") and w.tenant_of(s) == "", "closing it gives back the pitch, plain again (" + line.substr(0, 30) + ")")
	_fresh()


func _shop() -> void:
	var b: Business = w.business
	var f: Fitting = w.fitting
	_fresh()
	w.player.inv.items.clear()
	var h := _own_house()
	check(str(h.kind) == "storage" and w.holds(World.PLAYER, h) and w.interiors.has(str(h.id)), "the player owns a storeroom module with an interior")
	check(f.why_not(w.buildings["b_manor"], "counter", Vector2i(0, 0)) != "", "a room that is not the player's cannot be fitted out")
	var cell := _free_cell(h, "counter")
	check(cell.x >= 0, "there is a free floor cell for a counter")
	check(f.why_not(h, "counter", cell).begins_with("you need"), "no materials, no counter: " + f.why_not(h, "counter", cell))
	_give("counter")
	check(f.why_not(h, "counter", Vector2i(int(h.x) - 3, int(h.y) - 3)) != "", "not outside the room")
	var door: Array = w.interiors[h.id].doors[0]
	check(f.why_not(h, "counter", Vector2i(int(door[0]), int(door[1]))) != "", "not on the door")
	var spot: Dictionary = w.interiors[h.id].spots[0]
	check(f.why_not(h, "counter", Vector2i(int(spot.at[0]), int(spot.at[1]))) != "", "not on the room's own furniture")
	var planks := w.player.inv.count("plank")
	var used := float(w.stats.get("used_building_plank", 0.0))
	var placed := f.place(h, "counter", cell)
	check(placed == "", "the counter is placed " + placed)
	check(w.map.is_solid(cell) and f.count(h, "counter") == 1 and w.player.inv.count("plank") == planks - int(Fitting.cost("counter").plank), "its cell is solid and its planks left the pack")
	check(float(w.stats.get("used_building_plank", 0.0)) == used + float(Fitting.cost("counter").plank), "its materials are counted as used in the building")
	check(f.place(h, "counter", _free_cell(h, "counter")) != "", "a room has one counter")
	# every cell reachable before stays reachable: fill the room with shelves until the rule says no
	var refused := false
	for i in 12:
		_give("shelves")
		var c2 := _free_cell(h, "shelves")
		if c2.x < 0 or f.count(h, "shelves") >= Fitting.limit("shelves"):
			break
		f.place(h, "shelves", c2)
	for c: Vector2i in f.floor_set(h):
		if f.why_not(h, "stock_chest", c).begins_with("it would"):
			refused = true
	var reach_ok := true
	var step := Vector2i(int(h.door[0]), int(h.door[1]) - 1)
	for sp in w.interiors[h.id].spots:
		var u := Vector2i(int(sp.use[0]), int(sp.use[1]))
		if w.map.is_solid(u) or w.map.find_path(step, u).is_empty():
			reach_ok = false
	check(reach_ok, "every spot of the room is still reachable from the door after the equipment")
	check(f.count(h, "shelves") == Fitting.limit("shelves"), "shelves go up to their limit (%d)" % f.count(h, "shelves"))
	# the shop
	w.player.inv.items.clear()
	w.player.coins = 100
	var treasury := w.treasury
	var total := w.total_coins()
	check(b.open_shop(h) == "" and h.has("shop") and w.treasury == treasury + int(GameData.b("shop_licence_day")), "the shop is opened and the licence paid to the manor")
	check(w.total_coins() == total, "coins conserved when the shop opens")
	var s: Dictionary = h.shop
	check(b.record(str(h.id)) == s and b.is_mine(s) and b.premises().has(s), "the shop is one of the player's premises")
	check(b.listing_cap(s) == int(GameData.b("shop_listings")) + f.count(h, "shelves") * int(GameData.b("shop_shelf_listings")), "shelves set how many kinds it holds (%d)" % b.listing_cap(s))
	check(f.trade(h) == "general store", "with no workstation it is a general store")
	_give("oven")
	var oc := _free_cell(h, "oven")
	check(f.place(h, "oven", oc) == "" and w.stations.has(f.station_id(h, "oven")) and w.stations[f.station_id(h, "oven")].type == "oven", "an oven placed in the room is a real station")
	check(f.trade(h) == "bakery" and f.recipe_count(h) > 0, "an oven makes it a bakery (%d recipes)" % f.recipe_count(h))
	check(w.station_refusal(f.station_id(h, "oven")) == "" and not w.may_use(World.npc_ref(w.npcs[0].id), w.stations[f.station_id(h, "oven")]), "the owner may use it; villagers may not")
	_give("workbench")
	f.place(h, "workbench", _free_cell(h, "workbench"))
	check(f.trade(h) == "bakery" and f.station_kinds(h).has("workbench"), "a workbench adds carpentry (the oven still names the trade)")
	var wb := f.remove(h, "workbench")
	check(wb == "" and not w.stations.has(f.station_id(h, "workbench")) and f.count(h, "workbench") == 0, "a piece taken up leaves no station")
	check(w.player.inv.count("plank") == int(Fitting.cost("workbench").plank), "its materials came back")
	check(f.remove(h, "oven") == "" and f.trade(h) == "general store", "taking the oven up makes it a general store again")
	for k in ["forge", "anvil"]:
		_give(k)
		check(f.place(h, k, _free_cell(h, k)) == "", "a %s is placed" % k)
	check(f.trade(h) == "smithy" and w.stations_of("forge").has(f.station_id(h, "forge")), "a forge and an anvil make it a smithy")
	f.remove(h, "forge")
	f.remove(h, "anvil")
	# stock, a sale at the counter, back room
	w.player.inv.items.clear()
	w.player.inv.add("plank", 40)
	w.player.coins = 100
	check(b.list_item(s, "plank", 10) == "" and int(s.stock.plank) == 10, "goods go up for sale in the shop")
	_give("stock_chest")
	check(f.place(h, "stock_chest", _free_cell(h, "stock_chest")) == "" and b.store_cap(s) == int(GameData.b("shop_store_per_chest")), "a stock chest gives a back room")
	check(b.store_item(s, "plank", 20) == "" and b.store_total(s) == 20, "spare stock goes to the back room")
	check(b.store_item(s, "plank", 1000) != "", "the back room has a limit")
	var carp := _job("carpenter")
	carp.inv.items.clear()
	carp.coins = 500
	s.use = [int(s.use[0]), int(s.use[1])]
	w.player.pos = b.use_cell(s) + Vector2(0, 0.5)
	check(b.attended(s), "the player at the counter is selling")
	var total2 := w.total_coins()
	check(b.sell(s, carp, "plank", 10, b.price_of(s, "plank")), "the shelf sells out")
	check(int(s.stock.get("plank", 0)) == int(GameData.b("shop_restock")) and b.store_total(s) == 20 - int(GameData.b("shop_restock")) and s.prices.has("plank"), "the back room refills the shelf at the same price")
	check(w.total_coins() == total2, "coins conserved by the shop's sale")
	check(b.profit(s) == int(s.earned) - b.expenses(s), "profit is revenue less expenses")
	# licence daily and unpaid
	w.player.pos = Vector2(5, 5)
	w.minutes += 1440.0
	var coins := w.player.coins
	var till0 := int(s.till)
	var lic := int(GameData.b("shop_licence_day"))
	b.daily()
	check(int(s.costs.licence) == 2 * lic and w.player.coins == coins - maxi(0, lic - till0) and int(s.till) == maxi(0, till0 - lic), "the licence is taken each morning, from the shop's till first (ECON-P3)")
	# taking the counter up closes the shop and returns everything
	var pack := w.player.inv.count("plank")
	check(f.remove(h, "counter") == "" and not h.has("shop"), "taking up the counter closes the shop")
	check(w.player.inv.count("plank") >= pack + 20 and w.player.inv.count("plank") > 30, "its stock, back room and materials came back")


func _attendant() -> void:
	var b: Business = w.business
	var f: Fitting = w.fitting
	var h: Dictionary = w.buildings.values().filter(func(x): return str(x.get("kind", "")) == "storage" and w.holds(World.PLAYER, x))[0]
	w.player.inv.items.clear()
	w.player.coins = 200
	_give("counter")
	check(f.place(h, "counter", _free_cell(h, "counter")) == "" and b.open_shop(h) == "", "a counter and a shop to mind")
	var s: Dictionary = h.shop
	w.player.inv.add("iron_ore", 10)
	b.list_item(s, "iron_ore", 10)
	var cands := b.candidates()
	check(not cands.is_empty() and cands.all(func(n): return n.job in Business.HIRABLE and n.role == "adult"), "villagers without a trade can be hired (%d)" % cands.size())
	var smith := _job("smith")
	check(b.hire_refusal(smith) != "", "a villager with a trade cannot")
	check(b.hire_refusal(w.npcs.filter(func(n): return n.role == "child")[0]) != "", "a child cannot")
	var a: NPC = cands[0]
	var coins := w.player.coins
	var acoins := a.coins
	var total := w.total_coins()
	check(b.hire(s, a) == "" and b.attendant_of(s) == a and a.coins == acoins + b.wage() and w.player.coins == coins - b.wage(), "an attendant is hired and paid the day's wage")
	check(w.total_coins() == total and int(s.costs.wages) == b.wage(), "coins conserved; the wage is an expense")
	check(b.hire(s, cands[1]) != "" and b.hire_refusal(a) != "", "one attendant at a time; a hired villager is not free")
	check(w.construction.can_hire(a) != "", "a builder (player or villager) cannot hire the attendant away as a carrier")
	# a real NPC with a day: the brain sends them to the counter in working hours
	w.minutes = float(w.day()) * 1440.0 + 9.0 * 60.0
	a.plan.clear()
	a.hunger = 100.0
	w.brain.decide(a)
	check(a.plan.size() >= 1 and a.plan[0].k == "go" and a.doing.contains("minding"), "the attendant's plan takes them to the counter: " + a.doing)
	# the player is far; the attendant is not there yet: nothing sells
	smith.coins = 300
	smith.inv.items.erase("iron_ore")
	w.player.pos = Vector2(5, 5)
	a.pos = Vector2(5, 8)
	check(not b.attended(s) and not b.arrive(smith, {"stall": s.id, "item": "iron_ore"}), "no attendant at the counter and the player away: no sale")
	a.pos = b.use_cell(s)
	check(b.attendant_present(s) and b.attended(s) and not b.player_near(s), "the attendant at the counter opens the shop while the player is far")
	var o := b.offer(smith, s)
	var till := int(s.till)
	var total2 := w.total_coins()
	check(not o.is_empty() and b.arrive(smith, {"stall": s.id, "item": o.item}), "a villager with a real need buys from the attendant: " + str(o.get("item", "")))
	check(int(s.till) > till and w.total_coins() == total2 and str(s.sales[-1].by) == "attendant", "the coins are in the till, conserved, the sale marked as the attendant's")
	var guard := 0
	while b.offer(smith, s).get("item", "") == "iron_ore" and guard < 30:
		b.arrive(smith, {"stall": s.id, "item": "iron_ore"})
		guard += 1
	check(guard < 30 and b.offer(smith, s).get("item", "") != "iron_ore" and not b.arrive(smith, {"stall": s.id, "item": "iron_ore"}), "the attendant's sales stop when the smith's need or the stock is used up (%d bought, %d left)" % [guard, int(s.stock.get("iron_ore", 0))])
	# the hourly demand also runs without the player
	for n: NPC in w.npcs:
		if n != a:
			n.plan = [{"k": "work", "min": 99999.0, "anim": "work"}]
	var wc := _job("woodcutter")
	wc.plan = []
	wc.inv.items.erase("axe")
	wc.coins = 100
	s.stock.axe = 1
	s.prices.axe = GameData.value("axe")
	b.heading.clear()
	b.hour()
	check(b.heading.has(wc.id) and not wc.plan.is_empty(), "the hourly check sends a woodcutter who needs an axe to the shop while the player is away")
	# wages each morning, from the till first
	w.minutes += 1440.0
	var wage_day := int(s.wage_day)
	var pc := w.player.coins
	var tl := int(s.till)
	var ac := a.coins
	b.daily()
	check(int(s.wage_day) == w.day() and a.coins == ac + b.wage() and w.player.coins + int(s.till) == pc + tl - b.wage() - int(GameData.b("shop_licence_day")), "the wage is paid every morning (till and purse)")
	check(int(s.costs.wages) == 2 * b.wage(), "wages are totalled in the expenses")
	# no money, no attendant
	w.player.coins = 0
	s.till = 0
	w.minutes += 1440.0
	b.daily()
	check(b.attendant_of(s) == null and int(s.missed) == 1, "an attendant who cannot be paid leaves (and the licence is owing)")
	check(not b.is_attendant(a) and not b.plan_attendant(a), "and is nobody's attendant any more")
	w.player.coins = 100
	b.pay_arrears(s)
	# a stall can have an attendant too, who stands at the pitch
	var p := w.player
	check(b.rent() == "", "the player rents a pitch as well")
	var st := b.mine()
	p.inv.add("plank", 4)
	b.list_item(st, "plank", 4)
	var a2: NPC = b.candidates()[0]
	check(b.hire(st, a2) == "" and b.plan_attendant(a2) and a2.doing.contains("stall"), "an attendant can mind the stall")
	a2.pos = b.use_cell(st)
	p.pos = Vector2(5, 5)
	check(b.attended(st), "the stall sells while the player is away, with its attendant at it")
	a2.anim = "sleep"
	check(not b.attended(st), "not while the attendant sleeps")
	a2.anim = "idle"
	check(b.close(st) != "" and not b.is_attendant(a2), "closing the stall lets the attendant go")
	b.dismiss(s)


func _shop_save() -> void:
	var b: Business = w.business
	var f: Fitting = w.fitting
	var h: Dictionary = w.buildings.values().filter(func(x): return str(x.get("kind", "")) == "storage" and w.holds(World.PLAYER, x))[0]
	var s: Dictionary = h.shop
	w.player.coins = 200
	_give("oven")
	f.place(h, "oven", _free_cell(h, "oven"))
	_give("shelves")
	f.place(h, "shelves", _free_cell(h, "shelves"))
	w.player.inv.add("iron_ore", 3)
	b.list_item(s, "iron_ore", 3)
	var a: NPC = b.candidates()[0]
	b.hire(s, a)
	s.till = 11
	var cells: Array = f.list(h).map(func(e): return f.cell_of(e))
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	main._load_save(d)
	w = main.world
	var h2: Dictionary = w.buildings[str(h.id)]
	check(h2.has("shop") and int(h2.shop.till) == 11 and int(h2.shop.stock.iron_ore) == 3 and int(h2.shop.attendant) == a.id, "save and load keep the shop, its stock, till and attendant")
	check(w.fitting.list(h2).size() == cells.size() and w.fitting.trade(h2) == "bakery", "and the equipment and what it makes the shop")
	check(cells.all(func(c): return w.map.is_solid(c)), "the equipment is solid again")
	check(w.stations.has(w.fitting.station_id(h2, "oven")) and w.station_refusal(w.fitting.station_id(h2, "oven")) == "", "the oven is a station again and the owner may use it")
	check(w.business.attendant_of(h2.shop) != null and w.business.tills() == 11, "the attendant is the same villager; the till counts in the village's coins")
	check(w.business.profit(h2.shop) == int(h2.shop.earned) - w.business.expenses(h2.shop), "the books survive")
	# an older save has no shops and no equipment: nothing breaks
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	for id in old.buildings:
		old.buildings[id].erase("shop")
		old.buildings[id].erase("fit")
	main._load_save(old)
	w = main.world
	check(w.business.shops().is_empty() and w.business.premises().size() <= 1, "a save without shops or equipment loads as before")


func _save_load() -> void:
	var b: Business = w.business
	w.player.coins = 100
	if b.mine().is_empty():
		b.rent()
	var s := b.mine()
	w.player.inv.add("plank", 5)
	b.list_item(s, "plank", 5)
	b.set_price(s, "plank", 6)
	s.till = 7
	s.sales.append({"day": 0, "hour": 9, "who": "Test Buyer", "item": "plank", "qty": 1, "price": 6})
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	main._load_save(d)
	w = main.world
	var s2: Dictionary = w.business.mine()
	check(not s2.is_empty() and int(s2.stock.plank) == 5 and w.business.price_of(s2, "plank") == 6 and int(s2.till) == 7, "save and load keep the tenancy, stock, price and till")
	check(s2.sales.size() == 1 and int(s2.sales[0].qty) == 1 and int(s2.paid_day) == int(s.paid_day), "and the sales record and rent day")
	# a save made before pitches existed gets them
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	for id in Business.PITCHES.map(func(p): return p.id):
		old.stalls.erase(id)
	main._load_save(old)
	w = main.world
	check(w.stalls.has("pitch0") and w.stalls.has("pitch1") and w.tenant_of(w.stalls.pitch0) == "", "an older save gets the open pitches on load")
	check(w.business.tills() == 0, "tills start empty")


func _wiki() -> void:
	var wk := Wiki.build()
	check(wk.pages.has("guide:stall") and wk.pages["guide:stall"].title == "How do I sell from my own stall?", "the wiki has the stall guide")
	var found := false
	for id in wk.pages:
		if wk.pages[id].category == "notyet" and str(wk.pages[id].title).to_lower().contains("player shops and stalls"):
			found = true
	check(not found, "'Player shops and stalls' is no longer listed as not built")
