extends SceneTree
## FARM-08B: the cattle investigation's defects, fixed and kept fixed. A pen keeper buys as much feed as a seller can
## spare and the keeper can pay for (a part lot, as the player may buy), farmers keep grain in hand for keepers short
## of feed instead of shutting it in the family chest, and a keeper short of feed culls the elderly (who no longer
## breed) before the young that would replace them. Nothing is spawned, fed or paid for by the rules under test.
## Run: godot --headless --path game --script res://tests/herd_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 9.0 * 60.0                     # mid-morning: nobody asleep
	return w


func _init() -> void:
	test_cull_order()
	test_part_lot()
	test_grain_kept_for_keepers()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _clear_pen(w: World, pen: Dictionary) -> void:
	for a: Animal in w.fauna.animals.duplicate():
		if a.area == pen.id:
			w.fauna.remove(a)


func _beast(w: World, pen: Dictionary, sex: String, age_days: float) -> Animal:
	var a := w.fauna.spawn(pen.id, str(pen.kind), sex, null)
	a.born = w.minutes - age_days * 1440.0
	return a


## No wheat anywhere a keeper could get it: every pack, chest and the trough emptied.
func _no_grain(w: World, pen: Dictionary) -> void:
	for o: NPC in w.npcs:
		o.inv.remove("wheat", o.inv.count("wheat"))
	for hh in w.households:
		(hh.pantry as Inventory).remove("wheat", (hh.pantry as Inventory).count("wheat"))
	pen.trough = 0


func _plan_acts(n: NPC) -> Array:
	return n.plan.map(func(st): return str(st.get("act", "")))


func test_cull_order() -> void:
	var w := new_world()
	var pen: Dictionary = w.fauna.pen_of("cow")
	var sp: Dictionary = GameData.b("animals").cow
	var grown := Animal.stage_days(sp, "grow") + 1.0
	var old := Animal.stage_days(sp, "elder") + 1.0
	_clear_pen(w, pen)
	var bull := _beast(w, pen, "m", grown)
	var cow1 := _beast(w, pen, "f", grown)
	var cow2 := _beast(w, pen, "f", grown)
	var calf := _beast(w, pen, "f", 2.0)
	check(w.fauna.surplus(pen, true) == calf, "breeding stock only (a bull, two cows) and a calf: short of feed, the calf goes")
	var elder := _beast(w, pen, "f", old)
	check(elder.elderly(w.minutes) and not elder.breeds(w.minutes), "an elderly cow no longer breeds")
	check(w.fauna.surplus(pen, true) == elder, "short of feed, the elderly cow goes before the calf that would replace her")
	w.fauna.remove(cow2)
	w.fauna.remove(cow1)
	check(w.fauna.surplus(pen, true) == elder, "even with the breeding cows short of the keep, an elderly cow is no breeding stock")
	w.fauna.remove(elder)
	var old_bull := _beast(w, pen, "m", old)
	check(w.fauna.surplus(pen, true) == old_bull, "an elderly bull goes too, the young bull is kept")
	check(bull.alive and calf.alive, "nothing else was touched")
	# not short of feed: a pen below its cap keeps everyone, elders included
	check(w.fauna.surplus(pen) == null, "a pen below its cap culls nobody when there is feed")
	w.dispose()


func test_part_lot() -> void:
	var w := new_world()
	var pen: Dictionary = w.fauna.pen_of("cow")
	var keeper: NPC = w.pen_keeper(pen)
	check(keeper != null, "the cow pen has a keeper")
	_no_grain(w, pen)
	var need := w.fauna.daily_need(pen)
	var seller: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "farmer" and o != keeper and w.brain._keeper_pen(o).is_empty() and not w.asleep(o):
			seller = o
			break
	check(seller != null and need > 1, "a farmer keeping no pen is awake to sell (the pen eats %d a day)" % need)
	seller.inv.add("wheat", need)                      # one day's feed: less than the three-day lot
	keeper.coins = 1000
	keeper.plan.clear()
	keeper.hunger = 100.0
	var coins := w.total_coins()
	w.brain._keeper(keeper)
	var buy: Dictionary = {}
	for st in keeper.plan:
		if str(st.get("act", "")) == "buy_from":
			buy = st.get("args", {})
	check(not buy.is_empty() and int(buy.vendor) == seller.id and int(buy.qty) == need,
			"a seller with only part of a lot sells that part: buy %s (plan %s)" % [buy, _plan_acts(keeper)])
	check(not _plan_acts(keeper).has("slaughter"), "the keeper buys rather than culls")
	# the keeper who can pay for only some buys only that
	var price := w.sell_price(seller, "wheat")
	keeper.coins = price
	keeper.plan.clear()
	w.brain._keeper(keeper)
	buy = {}
	for st in keeper.plan:
		if str(st.get("act", "")) == "buy_from":
			buy = st.get("args", {})
	check(not buy.is_empty() and int(buy.qty) == 1, "a keeper with the price of one buys one (%s)" % [buy])
	check(w.brain.act(keeper, "buy_from", buy) and keeper.inv.count("wheat") == 1 and keeper.coins == 0 and w.total_coins() == coins - (1000 - price),
			"the part lot is a real sale: one wheat for the keeper's last coins")
	# with nothing to pay with the keeper finds no feed, and the stat says why
	keeper.coins = 0
	keeper.inv.remove("wheat", 1)
	keeper.plan.clear()
	w.brain._keeper(keeper)
	check(int(w.stats.get("keeper_no_coins_cow", 0)) >= 1, "no coins: counted as grain for sale the keeper could not pay for")
	w.dispose()


func test_grain_kept_for_keepers() -> void:
	var w := new_world()
	var pen: Dictionary = w.fauna.pen_of("cow")
	var keeper: NPC = w.pen_keeper(pen)
	_no_grain(w, pen)
	# the cook and the food merchant are full of grain: they want none
	for o: NPC in w.npcs:
		if o.alive and (o.job == "cook" or w.brain.buy_role(o) == "merchant_food"):
			o.inv.add("wheat", 200)
	var farmer: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "farmer" and o.household != keeper.household and w.brain._keeper_pen(o).is_empty() \
				and o.household >= 0 and not w.households[o.household].get("ended", false):
			farmer = o
			break
	check(farmer != null, "a farmer of another household who keeps no pen")
	var want: int = w.brain.feed_want(keeper)
	check(want == w.brain.reserve(keeper, "wheat") and want > 0, "the keeper, holding no grain, lacks its four days' feed (%d)" % want)
	check(w.brain._sale_stock(farmer, "wheat") >= want, "the farmer counts the keeper's want among the grain buyers will take")
	var pantry: Inventory = w.households[farmer.household].pantry
	pantry.add("pottage", 200)                         # the family's food is stocked: nothing goes in for the table
	farmer.inv.add("wheat", 300)
	w.brain.stock_family_chest(farmer)
	check(farmer.inv.count("wheat") >= want, "the farmer keeps %d in hand for the keeper (pack %d, chest %d)" % [want, farmer.inv.count("wheat"), pantry.count("wheat")])
	# a keeper holding its reserve wants nothing, and the farmer keeps nothing back for it
	keeper.inv.add("wheat", want)
	check(w.brain.feed_want(keeper) == 0, "a keeper holding its reserve wants no more")
	w.dispose()
