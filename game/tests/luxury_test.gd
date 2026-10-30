extends SceneTree
## DVW-B3-LUX (owner, 2026-10-23): luxury imports sold by the caravan for status. Costly goods (spices, fine cloth, jewellery)
## come from a trader's own stock; villagers and the player buy them with real coins that go into the trader's till and
## leave the village; what a settlement does not hold cannot be sold; a household short of coin or food does not buy; the
## buying is deterministic; ownership is kept through a save.
##   godot --headless --path game --script res://tests/luxury_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_data()
	test_villagers_buy()
	test_rules()
	test_stock_limit()
	test_player()
	test_player_food()
	test_save_and_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


## The whole world's coins less the ones that came from outside it: constant through any trade (regions_test).
func _net(w: World) -> int:
	return w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village())


## Adults with a taste for luxuries, each in a household of their own with food, their purse set to `coins`.
func _buyers(w: World, k: int, coins: int) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if out.size() >= k:
			break
		if n.alive and n.role == "adult" and n.household >= 0 and Luxury.taste(w, n) >= float(Luxury.cfg().min_taste):
			n.coins = coins
			(w.households[n.household].pantry as Inventory).add("wheat", 40)
			out.append(n)
	w._reserve_cache.clear()
	return out


func _held(w: World, id: String) -> int:
	var n := 0
	for s: OffMapSettlement in w.regions.list:
		n += s.trader_has(id)
	return n


func test_data() -> void:
	var c := Luxury.cfg()
	check((c.items as Array) == ["jewellery", "fine_cloth", "spice"], "three luxuries: jewellery, fine cloth and spices")
	var last := 1000000
	for id: String in c.items:
		check(GameData.items.has(id) and ResourceLoader.exists("res://assets/icons/%s.png" % id), "%s is an item with its own icon" % id)
		check(GameData.value(id) < last and Luxury.price(id) > GameData.value(id), "%s costs %d coins, more than its value %d, and less than the one before" % [id, Luxury.price(id), GameData.value(id)])
		last = GameData.value(id)
		check(GameData.item(id).get("food", 0) == 0 and not GameData.item(id).has("bonus"), "%s is neither food nor worn: it is kept" % id)
		for r in GameData.recipes:
			if not (GameData.recipes[r]["in"] as Dictionary).has(id):
				continue
			# The armour and weapon catalogue (Build 22, owner D16: its items stand; materials provisional) uses fine cloth as
			# silk in garments; no other recipe may take a luxury, and jewellery and spices go into nothing.
			var worn := true
			for o in (GameData.recipes[r].get("out", {}) as Dictionary):
				worn = worn and str(GameData.item(str(o)).get("type", "")) in ["armor", "head"]
			check(id == "fine_cloth" and worn, "only a catalogue garment may take a luxury: %s takes %s" % [r, id])
	var r := Regions.create(1)
	var holders := []
	for s: OffMapSettlement in r.list:
		if s.trader_has("jewellery") + s.trader_has("fine_cloth") + s.trader_has("spice") > 0:
			holders.append(s.id)
		check(s.audit() == "", "%s: the opening books balance with the luxuries in its stock" % s.name)
	check(holders == ["wulstead", "higham"], "the market town and the abbey town hold them (%s); the others do not" % ", ".join(holders))
	check(Luxury.price("spice") == 18 and Luxury.price("fine_cloth") == 38 and Luxury.price("jewellery") == 75, "the provisional prices are 18, 38 and 75 coins")


func test_villagers_buy() -> void:
	var w := _world(1)
	var buyers := _buyers(w, 6, 3000)
	check(buyers.size() == 6, "six villagers with a taste for luxuries and money to spend")
	var on_road: Array = w.regions.begin_visit(w.day())
	var net0 := _net(w)
	var coins0 := w.total_coins()
	var src0 := w.coin_sources
	var tills0 := {}
	var stock0 := {}
	for s: OffMapSettlement in on_road:
		tills0[s.id] = int(s.trader().till)
		stock0[s.id] = (s.trader().stock as Dictionary).duplicate()
	var purses0 := buyers.map(func(n): return n.coins)
	var held0 := Luxury.held_by(w)
	var paid := Luxury.visit(w, on_road)
	check(paid > 0, "a visit sells luxuries to villagers (%d coins)" % paid)
	var bought := 0
	for k in buyers.size():
		var n: NPC = buyers[k]
		var spent: int = int(purses0[k]) - n.coins
		var has := 0
		for id: String in Luxury.items():
			has += n.inv.count(id)
		check((spent > 0) == (has > 0), "%s %s: coins fell by %d and the luxury is in the pack (%d kept)" % [n.name, n.family, spent, has])
		bought += has
	check(bought > 0 and bought <= int(Luxury.cfg().buyers_per_visit), "at most %d villagers buy on a visit (%d did)" % [int(Luxury.cfg().buyers_per_visit), bought])
	var held1 := Luxury.held_by(w)
	var units := 0
	for id: String in Luxury.items():
		units += int(held1[id]) - int(held0[id])
	check(units == bought, "the units the villagers hold are the units bought (%d)" % units)
	var till_gain := 0
	var stock_loss := 0
	for s: OffMapSettlement in on_road:
		till_gain += int(s.trader().till) - int(tills0[s.id])
		for id: String in Luxury.items():
			stock_loss += int(stock0[s.id].get(id, 0)) - int(s.trader().stock.get(id, 0))
		check(s.audit() == "", "%s: its books still balance (the coins and the goods have lines)" % s.name)
	check(till_gain == paid and stock_loss == bought, "the coins went into the traders' tills (%d) and the goods left their stock (%d)" % [till_gain, stock_loss])
	check(w.total_coins() == coins0 - paid and w.coin_sources == src0 - paid, "the coins left the village: %d fewer, and its outside sources %d lower" % [paid, paid])
	check(_net(w) == net0, "the whole world's coins are unchanged: none made, none lost")
	check(int(w.stats.get("luxury_coins", 0)) == paid and int(w.stats.get("caravan_coins_out", 0)) == paid, "the village's ledger records them as paid to the caravan")
	var imported := 0
	for k in w.stats:
		if str(k).begins_with("imported_"):
			imported += int(w.stats[k])
	check(imported == bought, "and the goods as imported (%d)" % imported)
	var again := Luxury.visit(w, on_road)
	var held2 := Luxury.held_by(w)
	var total2 := 0
	for id: String in Luxury.items():
		total2 += int(held2[id])
		check(int(held2[id]) <= buyers.size() * int(Luxury.cfg().own_max[id]), "nobody owns more than %d of %s" % [int(Luxury.cfg().own_max[id]), id])
	check(total2 >= bought and again >= 0, "a second visit sells some more (%d coins) and nothing is taken back" % again)
	var through_caravan := _world(1)
	through_caravan.minutes = 1 * 1440.0 + 12.0 * 60.0
	var rich := _buyers(through_caravan, 3, 3000)
	var before := _net(through_caravan)
	through_caravan.brain.caravan()
	check(_net(through_caravan) == before and rich.any(func(n): return n.coins < 3000), "the caravan's own visit (NPCBrain.caravan) runs it: the world's coins unchanged, someone bought")


func test_rules() -> void:
	var w := _world(1)
	var on_road: Array = w.regions.begin_visit(w.day())
	var n: NPC = _buyers(w, 1, 0)[0]
	var cheapest := Luxury.price("spice")
	var need := int(ceil(float(cheapest) / float(Luxury.cfg().spend_share)))
	# below the reserve and savings plus the price's share, nothing is bought
	w._reserve_cache.clear()
	var floor_ := w.reserve_of(n) + int(Luxury.cfg().keep_coins)
	n.coins = floor_ + need - 1
	check(Luxury.pick(w, n, on_road) == "", "with one coin too few above the reserve (%d) and savings, no luxury is chosen" % w.reserve_of(n))
	n.coins = floor_ + need
	check(Luxury.pick(w, n, on_road) == "spice", "with just enough, the dearest it can afford is chosen (spices)")
	n.coins = floor_ + 100000
	check(Luxury.pick(w, n, on_road) == "jewellery", "with plenty, jewellery")
	n.inv.add("jewellery", 1)
	check(Luxury.pick(w, n, on_road) == "fine_cloth", "owning the one jewellery it wants, fine cloth next")
	n.inv.add("fine_cloth", 2)
	n.inv.add("spice", 3)
	check(Luxury.pick(w, n, on_road) == "", "owning all it wants, none")
	n.inv.items.erase("jewellery")
	n.inv.items.erase("fine_cloth")
	n.inv.items.erase("spice")
	# a household short of food buys nothing
	var coins := w.total_coins()
	var saved: float = float(Luxury.cfg().min_food_days)
	(Luxury.cfg() as Dictionary)["min_food_days"] = 100000.0
	var paid := Luxury.visit(w, on_road)
	(Luxury.cfg() as Dictionary)["min_food_days"] = saved
	check(paid == 0 and w.total_coins() == coins, "a household with under the food it must have buys nothing, however much it holds")
	# a villager with no taste, a child and a dead villager buy nothing
	var shy: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and Luxury.taste(w, o) < float(Luxury.cfg().min_taste):
			shy = o
			break
	check(shy != null, "some villagers have no taste for luxuries")
	if shy != null:
		shy.coins = 100000
		var before := shy.coins
		Luxury.visit(w, on_road)
		check(shy.coins == before, "one without a taste buys none, rich as they are")
	var kid: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "child":
			kid = o
			break
	if kid != null:
		kid.coins = 100000
		Luxury.visit(w, on_road)
		check(kid.coins == 100000, "a child buys none")
	# the rule's inputs are fixed: the same world gives the same tastes
	var w2 := _world(1)
	var same := true
	for o: NPC in w.npcs:
		same = same and Luxury.taste(w, o) == Luxury.taste(w2, w2.npc(o.id))
	check(same, "tastes are the same in a world made again from the seed")


func test_stock_limit() -> void:
	var w := _world(1)
	for s: OffMapSettlement in w.regions.list:
		for id: String in Luxury.items():
			s.trader().stock.erase(id)
		s.start.goods = s.goods()                      # the books reopen with these stocks
	var higham: OffMapSettlement = w.regions.by_id["higham"]
	higham.trader().stock["jewellery"] = 1
	higham.start.goods = higham.goods()
	var _b := _buyers(w, 6, 20000)
	var on_road: Array = w.regions.begin_visit(w.day())
	Luxury.visit(w, on_road)
	var held := Luxury.held_by(w)
	check(int(held.jewellery) == 1 and int(held.fine_cloth) == 0 and int(held.spice) == 0, "only what a trader holds can be bought: one jewellery, no fine cloth, no spices")
	check(higham.trader_has("jewellery") == 0 and higham.audit() == "", "Higham's trader has none left and its books balance")
	var paid := Luxury.visit(w, on_road)
	check(paid == 0, "with nothing left in any trader's stock, nothing is sold")
	# a trader that is not on the road sells nothing
	var w2 := _world(1)
	var _b2 := _buyers(w2, 6, 20000)
	var only_netherton: Array = [w2.regions.by_id["netherton"]]
	check(Luxury.visit(w2, only_netherton) == 0, "a visit by a trader holding none (Netherton) sells none")


func test_player() -> void:
	var w := _world(1)
	var p := w.player
	p.coins = 1000
	w.minutes = 2 * 1440.0 + 13.0 * 60.0               # day 2: not a visit day
	check(Luxury.offers(w).is_empty() and Luxury.refusal(w, p, "spice") == "The caravan is not here.", "when the caravan is not in the village the wagon offers nothing")
	w.minutes = 1 * 1440.0 + 13.0 * 60.0               # day 1, 13:00: the first visit, every trader on the road
	var offers := Luxury.offers(w)
	check(offers.map(func(o): return o.id) == ["jewellery", "fine_cloth", "spice"], "the wagon offers all three on the first visit")
	var net0 := _net(w)
	var coins0 := w.total_coins()
	var wulstead: OffMapSettlement = w.regions.by_id["wulstead"]
	var higham: OffMapSettlement = w.regions.by_id["higham"]
	var h0 := higham.trader_has("spice")
	var till0: int = int(higham.trader().till)
	check(Luxury.refusal(w, p, "spice") == "", "with the coins and room, the player may buy")
	check(Luxury.buy(w, p, "spice") == "", "the player buys spices")
	check(p.inv.count("spice") == 1 and p.coins == 1000 - Luxury.price("spice"), "one unit in the pack, %d coins paid" % Luxury.price("spice"))
	check(higham.trader_has("spice") == h0 - 1 and int(higham.trader().till) == int(till0) + Luxury.price("spice"), "it came from the trader with the most (Higham's) and the coins went into its till")
	check(higham.audit() == "" and wulstead.audit() == "", "the settlements' books balance")
	check(w.total_coins() == coins0 - Luxury.price("spice") and _net(w) == net0, "the coins left the village; the world's total is unchanged")
	p.coins = 5
	check(Luxury.buy(w, p, "jewellery") == "You need %d coins." % Luxury.price("jewellery") and p.inv.count("jewellery") == 0, "with too few coins nothing is sold")
	p.coins = 1000
	for s: OffMapSettlement in w.regions.list:
		s.trader().stock.erase("fine_cloth")
	check(Luxury.buy(w, p, "fine_cloth") == "None of the traders here has any.", "what no trader holds cannot be bought")
	check(Luxury.buy(w, p, "iron_bar") == "The caravan does not sell that.", "and the wagon sells only luxuries here")
	# the pack's own capacity rule applies: a full crafted tab refuses
	var crafted := 0
	for id in GameData.items:
		if crafted >= p.inv.category_cap:
			break
		if GameData.category(id) == "crafted" and id != "jewellery" and p.inv.count(id) == 0:
			p.inv.items[id] = 1
			crafted += 1
	p.coins = 1000
	check(p.inv.category_cap > 0 and Luxury.refusal(w, p, "jewellery").contains("inventory full"), "with the crafted tab of the pack full, the jewellery is refused: " + Luxury.refusal(w, p, "jewellery"))


## REG-BUY-01 parity: the player buys food at the wagon like the households and businesses do, at the cheapest trader's price.
func test_player_food() -> void:
	var w := _world(1)
	var p := w.player
	p.coins = 1000
	w.minutes = 2 * 1440.0 + 13.0 * 60.0               # day 2: not a visit day
	check(CaravanFood.offers(w).is_empty() and CaravanFood.refusal(w, p, "wheat") == "The caravan is not here.", "food: when the caravan is not in the village the wagon offers none")
	w.minutes = 1 * 1440.0 + 13.0 * 60.0               # day 1, 13:00: the first visit
	var road: Array = w.regions.visiting(w.day())
	var wul: OffMapSettlement = w.regions.by_id["wulstead"]
	(wul.trader().stock as Dictionary)["wheat"] = 20            # fixture: the trader holds wheat released by its settlement's businesses
	(w.regions.by_id["garton"].trader().stock as Dictionary)["wheat"] = 20
	(w.regions.by_id["garton"].trader().stock as Dictionary)["bread"] = 5
	wul.reopen_books()
	w.regions.by_id["garton"].reopen_books()
	var seller: OffMapSettlement = w.regions.food_seller("wheat", road)
	check(seller != null and CaravanFood.offers(w).any(func(o): return o.id == "wheat" and int(o.price) == seller.food_price("wheat")), "the wagon offers wheat at the cheapest trader's price (%d)" % (seller.food_price("wheat") if seller != null else -1))
	var net0 := _net(w)
	var coins0 := w.total_coins()
	var held0 := seller.trader_has("wheat")
	var till0: int = int(seller.trader().till)
	var price := seller.food_price("wheat")
	var imp0 := int(w.stats.get("imported_wheat", 0))
	check(CaravanFood.buy(w, p, "wheat") == "" and p.inv.count("wheat") >= 1 and p.coins == 1000 - price, "the player buys a unit of wheat for %d coins" % price)
	check(seller.trader_has("wheat") == held0 - 1 and int(seller.trader().till) == till0 + price, "it left that trader's stock and the coins entered its till")
	check(w.total_coins() == coins0 - price and _net(w) == net0 and int(w.stats.get("imported_wheat", 0)) == imp0 + 1, "the coins left the village, the unit is booked as imported; nothing made")
	for s: OffMapSettlement in w.regions.list:
		check(s.audit() == "", "%s's books balance" % s.name)
	p.coins = 0
	check(CaravanFood.buy(w, p, "wheat") == "You need %d coins." % seller.food_price("wheat"), "without the coins nothing is sold")
	p.coins = 1000
	for s: OffMapSettlement in w.regions.list:
		s.trader().stock.erase("cheese")
	check(CaravanFood.buy(w, p, "cheese") == "None of the traders here has any.", "what no trader holds cannot be bought")
	check(CaravanFood.buy(w, p, "iron_bar") == "The caravan does not sell that.", "the wagon sells only the settlements' foods here")
	var a := _world(3)
	var b := _world(3)
	for x in [a, b]:
		x.player.coins = 500
		x.minutes = 1 * 1440.0 + 13.0 * 60.0
		(x.regions.by_id["garton"].trader().stock as Dictionary)["wheat"] = 20
		(x.regions.by_id["garton"].trader().stock as Dictionary)["bread"] = 5
		x.regions.by_id["garton"].reopen_books()
		CaravanFood.buy(x, x.player, "wheat")
		CaravanFood.buy(x, x.player, "bread")
	check(JSON.stringify(a.to_dict(), "", true, true) == JSON.stringify(b.to_dict(), "", true, true), "two worlds of one seed given the same purchases end identical")


func test_save_and_determinism() -> void:
	var a := _world(2)
	var b := _world(2)
	var ba := _buyers(a, 6, 3000)
	var bb := _buyers(b, 6, 3000)
	Luxury.visit(a, a.regions.begin_visit(a.day()))
	Luxury.visit(b, b.regions.begin_visit(b.day()))
	var sa := JSON.stringify(a.to_dict(), "", true, true)
	var sb := JSON.stringify(b.to_dict(), "", true, true)
	check(sa == sb, "two worlds made from one seed buy the same luxuries, to the last coin")
	check(ba.map(func(n): return n.id) == bb.map(func(n): return n.id), "from the same villagers")
	var map := VillageMap.load_default()
	var w2 := World.new()
	w2.load_dict(map, JSON.parse_string(sa))
	var held_a := Luxury.held_by(a)
	var held_2 := Luxury.held_by(w2)
	check(JSON.stringify(held_a) == JSON.stringify(held_2) and int(held_2.values().reduce(func(x, y): return x + y, 0)) > 0, "what they own is there after saving and loading (%s)" % JSON.stringify(held_2))
	check(w2.regions.audit() == "" and _net(w2) == _net(a), "the settlements' books balance and the world's coins are unchanged after loading")
	# the next visit after loading buys what the original's would
	var on_a: Array = a.regions.begin_visit(a.day())
	var on_2: Array = w2.regions.begin_visit(w2.day())
	var pa := Luxury.visit(a, on_a)
	var p2 := Luxury.visit(w2, on_2)
	check(pa == p2, "a loaded world's next visit sells what the original's does (%d and %d coins)" % [pa, p2])
	# a save from before this change has no luxuries in its traders' stock: it loads, and sells none
	var old: Dictionary = JSON.parse_string(sa)
	for s in old.regions.settlements:
		for t in s.biz:
			for id in ["spice", "fine_cloth", "jewellery"]:
				(s.biz[t].stock as Dictionary).erase(id)
		for id in ["spice", "fine_cloth", "jewellery"]:
			(s.start.goods as Dictionary).erase(id)
	var w3 := World.new()
	w3.load_dict(map, old)
	check(w3.regions != null and w3.regions.list.size() == 5, "an older save loads")
	var none := 0
	for s: OffMapSettlement in w3.regions.list:
		none += s.trader_has("spice") + s.trader_has("fine_cloth") + s.trader_has("jewellery")
	check(none == 0 and Luxury.offers(w3).is_empty(), "its traders hold no luxuries and the wagon offers none")
