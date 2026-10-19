extends SceneTree
## The player's market stall and the villagers who buy from it (PL1-10 stages 1 and 2): renting a pitch,
## listing, pricing, taking back, closing, the daily rent and what unpaid rent does, sales only while the
## player is there, demand only for real needs within real budgets, coins conserved, save and load. Run:
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
	var held := w.player.coins
	check(b.collect(s) == paid and w.player.coins == held + paid and int(s.till) == 0, "the till is collected into the purse")


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
	# a poor morning: the till covers the rent
	p.coins = 1
	s.till = 12
	w.minutes += 1440.0
	b.daily()
	check(int(s.missed) == 0 and int(s.till) + p.coins == 12 + 1 - Business.rent_day(), "the till pays the rent when the purse cannot")
	# nothing to pay with: sales stop, then the pitch goes back with the goods
	p.coins = 0
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
