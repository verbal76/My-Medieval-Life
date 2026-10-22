extends SceneTree
## OD-16, the owner's answer of 2026-10-20 (register EQ-19, EQ-20, EQ-21): money flows back to the essential trades.
##  (b) the manor buys tools for workers short of one, or pays a smith in advance for one that is then forged and handed
##      over (EQ-19);
##  (a) bandits spend their coins at the market, and guards bring coins left lying to the treasury (EQ-20);
##  (c) the caravan buys producers' surplus (hunters' meat and hides, tanners' leather) (EQ-21), each unit from the
##      seller that needs the sale most, not the smiths first (EQ-22, owner 2026-10-21).
## Every coin and good only moves: the village's total coins are checked before and after. Run:
##   godot --headless --path game --script res://tests/od16_test.gd

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
	test_manor_buys_a_tool_on_sale()
	test_manor_pays_the_smith_in_advance()
	test_bandit_spends_at_the_market()
	test_guard_recovers_loot()
	test_caravan_buys_producers_surplus()
	test_caravan_buys_by_need()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func woodcutter_without_axe(w: World) -> NPC:
	var n: NPC = w.brain._first_with_job("woodcutter")
	n.inv.remove("axe", n.inv.count("axe"))
	n.coins = 0
	return n


## EQ-19: an axe on sale at the goods merchant's or the smith's is bought from the treasury and handed to the woodcutter.
func test_manor_buys_a_tool_on_sale() -> void:
	var w := new_world()
	var n := woodcutter_without_axe(w)
	var smith: NPC = w.brain._first_with_job("smith")
	smith.inv.add("axe", 2)
	w.treasury = 2000
	var coins0 := w.total_coins()
	var spent: int = w.brain._support_trades(w.brain.daily_obligations())
	check(n.inv.has("axe"), "the woodcutter short of an axe is given one the manor bought")
	check(spent > 0 and w.treasury == 2000 - spent, "the treasury paid for it (%d coins)" % spent)
	check(w.total_coins() == coins0, "coins only moved")
	check(not w.brain.tool_short(n), "and is no longer short of a tool")


## EQ-19: with no axe on sale, the poorest smith is paid an axe's worth in advance; the order keeps the woodcutter in
## the trade; the smith forges it first once the forge has its inputs, and it is handed to the woodcutter.
func test_manor_pays_the_smith_in_advance() -> void:
	var w := new_world()
	var n := woodcutter_without_axe(w)
	for o: NPC in w.npcs:
		if o.alive and (o.job == "smith" or w.brain.buy_role(o) == "merchant_goods"):
			o.inv.remove("axe", o.inv.count("axe"))
	w.treasury = 2000
	var coins0 := w.total_coins()
	w.brain._support_trades(w.brain.daily_obligations())
	var order: Dictionary = w.brain._order_for(n)
	check(not order.is_empty() and str(order.tool) == "axe", "with no axe on sale, the manor orders one for the woodcutter")
	if order.is_empty():
		return
	var smith := w.npc(int(order.smith))
	check(w.treasury == 2000 - int(order.paid) and int(order.paid) > 0, "paid in advance from the treasury (%d coins)" % int(order.paid))
	check(w.total_coins() == coins0, "coins only moved")
	check(not w.brain.tool_short(n), "the woodcutter, an axe coming, is not counted out of work")
	smith.inv.remove("plank", smith.inv.count("plank"))
	for id in ["iron_ore", "copper_ore", "coal"]:
		smith.inv.remove(id, smith.inv.count(id))
	smith.inv.remove("iron_bar", smith.inv.count("iron_bar"))
	smith.inv.add("iron_bar", 4)                  # bars for the axe and more, but no plank
	smith.coins = 50
	w.brain._smith(smith)
	check(str(smith.doing).contains("plank for the manor"), "short of a plank, the smith fetches one for the order rather than working the bars into something else (%s)" % smith.doing)
	check(smith.inv.count("iron_bar") == 4, "the bars are kept for the order")
	for id in ["iron_ore", "copper_ore", "coal"]:   # nothing to smelt: the forge goes straight to the order
		smith.inv.remove(id, smith.inv.count(id))
	for id in GameData.recipes["forge_axe"].in:
		smith.inv.add(str(id), int(GameData.recipes["forge_axe"].in[id]))
	smith.inv.remove("axe", smith.inv.count("axe"))
	w.brain._smith(smith)
	check(str(smith.doing).contains("axe"), "the smith sets about the ordered axe first (%s)" % smith.doing)
	smith.inv.add("axe")                          # forged (the recipe's run is the engine's own, tested elsewhere)
	check(w.brain.keeps(smith, "axe"), "the ordered axe is not sold away")
	w.brain._deliver_orders()
	check(n.inv.has("axe") and w.brain._order_for(n).is_empty(), "it is handed to the woodcutter and the order is closed")
	# an order the forge cannot meet (no coal to be had) lapses after manor_order_days, so its worker is not held
	# in a trade without a tool for good
	var n2: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "miner" and o != n:
			n2 = o
			break
	if n2 != null:
		n2.inv.remove("pickaxe", n2.inv.count("pickaxe"))
		n2.coins = 0
		w.manor_orders.append({"smith": smith.id, "tool": "pickaxe", "for": n2.id, "paid": 0, "day": w.day() - int(GameData.b("manor_order_days")) - 1})
		check(not w.brain.tool_short(n2), "while the order is open the miner waits for the pickaxe")
		w.brain._deliver_orders()
		check(w.brain._order_for(n2).is_empty() and w.brain.tool_short(n2), "an order not met in time lapses and the miner may seek other work")


## EQ-20: a bandit with coins buys food at a stall no guard is near; the coins reach the seller.
func test_bandit_spends_at_the_market() -> void:
	var w := new_world()
	var bandit: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			bandit = o
			break
	check(bandit != null, "a bandit")
	if bandit == null:
		return
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard":
			o.pos = Vector2(1, 1)                 # the guards are elsewhere
	bandit.coins = 60
	bandit.hp = bandit.max_hp
	check(w.brain._bandit_market(bandit), "a bandit with coins slips into the market (%s)" % bandit.doing)
	var step: Dictionary = bandit.plan[-1]
	var seller := w.npc(int(step.args.vendor))
	var c0 := seller.coins
	var total0 := w.total_coins()
	bandit.pos = Vector2(w.brain._workplace_cell(seller))
	check(w.brain.act(bandit, "buy_from", step.args), "and buys %s" % step.args.item)
	check(seller.coins > c0 and bandit.coins < 60, "the coins reach the seller (%d to %d)" % [c0, seller.coins])
	check(w.total_coins() == total0, "coins only moved")


## EQ-20: coins left lying for loot_recover_hours near a guard on duty are brought to the treasury.
func test_guard_recovers_loot() -> void:
	var w := new_world()
	var guard: NPC = w.brain._first_with_job("guard")
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			o.pos = Vector2(1, 1)
	var spot := guard.pos + Vector2(3, 0)
	w.loot.append({"pos": spot, "inv": Inventory.new(), "coins": 25, "from": "someone", "t": w.minutes - 13.0 * 60.0})
	w.loot.append({"pos": guard.pos + Vector2(2, 0), "inv": Inventory.new(), "coins": 9, "from": "fresh", "t": w.minutes})
	var lost: Dictionary = w.brain._loot_to_recover(guard)
	check(not lost.is_empty() and int(lost.coins) == 25, "a guard finds the coins left lying half a day, not the fresh ones")
	var t0 := w.treasury
	var total0 := w.total_coins()
	guard.pos = spot
	check(w.brain.act(guard, "recover_loot", {}), "and recovers them")
	check(w.treasury == t0 + 25 and w.total_coins() == total0, "to the treasury; coins only moved")


## EQ-21: the caravan buys a hunter's meat and hides beyond what the hunter keeps; the coins come from outside.
func test_caravan_buys_producers_surplus() -> void:
	var w := new_world()
	var hunter: NPC = w.brain._first_with_job("hunter")
	hunter.inv.add("meat", 30)
	hunter.inv.add("hide", 10)
	w.regions.fund_only("wulstead", 500)         # a settlement that uses meat and hides has the coins
	var c0 := hunter.coins
	w.brain.caravan()
	check(int(w.stats.get("exported_meat", 0)) > 0 or int(w.stats.get("exported_hide", 0)) > 0, "the caravan buys the hunter's surplus meat or hides")
	check(hunter.coins > c0, "the hunter is paid (%d to %d)" % [c0, hunter.coins])
	check(hunter.inv.count("meat") >= int(GameData.b("caravan_producer_keep").meat) or int(w.stats.get("exported_meat", 0)) == 0, "keeping what a hunter keeps")
	check(int(w.stats.get("caravan_in_hunter", 0)) == hunter.coins - c0, "the caravan's coins, from outside, paid the hunter (caravan_in_hunter %d)" % int(w.stats.get("caravan_in_hunter", 0)))


## EQ-22 (owner 2026-10-21): the caravan buys by need, not the smiths first. A smith well stocked with its inputs and
## coins and a tanner with no hides and no coins both have surplus; the tanner is served first, and the caravan never
## spends more than its trader's till.
func test_caravan_buys_by_need() -> void:
	var w := new_world()
	var b: NPCBrain = w.brain
	for o: NPC in w.npcs:                        # no other seller's surplus in the way
		if o.alive and o.job in ["merchant", "smith", "hunter", "tanner"]:
			for id in o.inv.ids():
				o.inv.remove(id, o.inv.count(id))
		if o.alive and (o.job == "merchant" or o.id == w.sage_id):
			o.coins = 0                              # and nobody buys seed or medicine from it, so its purse is what we set
	for s: OffMapSettlement in w.regions.list:   # DVW-B3-LUX: and no luxuries on the carts, so no purse here is spent on one (luxury_test covers them)
		for id: String in Luxury.items():
			s.trader().stock.erase(id)
		s.reopen_books()
	var smith: NPC = b._first_with_job("smith")
	var tanner: NPC = b._first_with_job("tanner")
	for id in NPCBrain.BUYS.smith:
		smith.inv.add(id, int(NPCBrain.BUYS.smith[id]))
	smith.coins = 500
	smith.inv.add("iron_bar", 12)                # 8 over its keep of 4
	tanner.coins = 0
	tanner.inv.add("leather", 12)                # 6 over its keep of 6
	check(b.restock_cost(smith) == 0 and b.restock_cost(tanner) > 0, "the smith lacks none of its inputs; the tanner lacks its hides (restock %d)" % b.restock_cost(tanner))
	check(b.caravan_line_need(tanner, "leather", 6, b.restock_cost(tanner)) > b.caravan_line_need(smith, "iron_bar", 8, 0), "the tanner needs the sale more than the smith")
	var leather := maxi(1, roundi(GameData.value("leather") * 0.8))
	var bar := maxi(1, roundi(GameData.value("iron_bar") * 0.8))
	var total0 := w.total_coins() - w.coin_sources
	# a purse that would pay for one bar: it goes to the tanner's leather (as many pieces as it covers), not the bar
	var buyer: OffMapSettlement = w.regions.by_id["garton"]            # wants leather (no tannery) and iron bars
	w.regions.fund_only("garton", maxi(leather, bar))
	var purse0 := buyer.trader_cash()
	total0 = w.total_coins() - w.coin_sources
	b.caravan()
	var pieces := 12 - tanner.inv.count("leather")
	check(pieces == purse0 / leather and smith.inv.count("iron_bar") == 12, "a purse of %d buys %d of the tanner's leather and none of the smith's bars (bars %d)" % [purse0, pieces, smith.inv.count("iron_bar")])
	check(buyer.trader_cash() >= 0 and purse0 - buyer.trader_cash() == tanner.coins and tanner.coins == pieces * leather, "paid %d from its purse of %d, no more" % [tanner.coins, purse0])
	# a larger purse still never pays out more than the trader holds
	w.regions.fund_only("garton", 3 * leather + bar)
	purse0 = buyer.trader_cash()
	total0 = w.total_coins() - w.coin_sources
	var paid0 := tanner.coins + smith.coins
	b.caravan()
	var paid := tanner.coins + smith.coins - paid0
	check(paid > 0 and paid <= purse0 and buyer.trader_cash() == purse0 - paid, "it spends %d of a purse of %d, never more" % [paid, purse0])
	check(w.total_coins() - w.coin_sources == total0, "coins only moved: the village's coins less coin_sources are unchanged")
