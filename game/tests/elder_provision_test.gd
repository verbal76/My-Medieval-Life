extends SceneTree
## X20-FIREWOOD (docs/expansion20/FIREWOOD_AFFORD_INVESTIGATION.md): an elder buys the household's firewood and grain when no
## working-age member of the household has the coins to. Before the fix, NPCBrain._decide sent every elder to the farm plot,
## the church plot or a walk, and only adults reached _plan_provision; a household whose coins were all in elders' purses
## (retired parents, an elder-only home) went without firewood every night while sellers held logs (the 200-day seed 1 run:
## 129 of the 159 cold household-nights to day 160 in households holding 20-99 coins, every one with logs for sale).
## Checks: the elder plans the trip and the log reaches the pantry, paid from the elder's purse at the seller's price (coins
## and goods only move); an elder does not shop while an adult of the household has the coins (the adult's evening trip stays
## theirs); an elder with too few coins does not; a household that holds a log is not restocked.
##   godot --headless --path game --script res://tests/elder_provision_test.gd

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
	test_elder_only_household_buys_firewood()
	test_elder_with_coinless_adults_buys_firewood()
	test_elder_waits_for_an_adult_with_coins()
	test_poor_elder_and_stocked_household()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 10.0 * 60.0          # day 1, 10:00: shops open, sellers awake
	return w


## A household of the village, its members, the pantry emptied of firewood and grain, every member's own logs and food gone.
func household(w: World) -> int:
	for h in w.households.size():
		var ms: Array = w.brain._members(h)
		if ms.size() >= 2 and not w.households[h].get("ended", false):
			var pantry: Inventory = w.households[h].pantry
			for id in pantry.ids():
				pantry.remove(id, pantry.count(id))
			for o: NPC in ms:
				o.inv.remove("log", o.inv.count("log"))
				o.plan.clear()
			return h
	return -1


func retire(w: World, n: NPC, coins: int) -> void:
	if n.job != "":
		w.brain._change_job(n, "", "retired in old age")
	n.role = "elder"
	n.coins = coins
	n.hunger = 100.0
	n.hp = n.max_hp


## A seller of logs, awake, with logs in hand (the carpenter).
func log_seller(w: World) -> NPC:
	var c: NPC = w.brain._first_with_job("carpenter")
	c.inv.add("log", 10)
	c.anim = "idle"
	return c


func test_elder_only_household_buys_firewood() -> void:
	var w := new_world()
	var h := household(w)
	var ms: Array = w.brain._members(h)
	for o: NPC in ms:
		retire(w, o, 0)
	var elder: NPC = ms[0]
	elder.coins = 60
	log_seller(w)
	var total0 := w.total_coins()
	w.brain.decide(elder)
	check(str(elder.doing) == "buying firewood", "an elder-only household's elder with coins goes to buy firewood (%s)" % elder.doing)
	if elder.plan.is_empty():
		return
	# carry out the trip: the plan's last step is the purchase at the seller
	var step: Dictionary = elder.plan[-1]
	var seller := w.npc(int(step.args.get("vendor", -1)))
	check(seller != null and seller.inv.has("log") and step.args.get("pantry", false), "the trip ends with a purchase for the pantry from a holder of logs")
	if seller == null:
		return
	var logs0: int = seller.inv.count("log")
	var price: int = w.deal_price(w.sell_price(seller, "log"), elder, seller)
	elder.pos = Vector2(w.brain._workplace_cell(seller))
	var coins0 := elder.coins
	check(w.brain.act(elder, "buy_from", step.args), "and buys the log")
	var pantry: Inventory = w.households[h].pantry
	check(pantry.count("log") == 1, "the log is in the household's pantry (%d)" % pantry.count("log"))
	check(elder.coins == coins0 - price and seller.inv.count("log") == logs0 - 1, "paid from the elder's own purse at the seller's price (%d)" % price)
	check(w.total_coins() == total0, "coins only moved")


func test_elder_with_coinless_adults_buys_firewood() -> void:
	var w := new_world()
	var h := household(w)
	var ms: Array = w.brain._members(h)
	var elder: NPC = ms[0]
	retire(w, elder, 60)
	for o: NPC in ms.slice(1):
		if o.role == "adult":
			o.coins = 2                            # under a log's price: they cannot buy it
	log_seller(w)
	w.brain.decide(elder)
	check(str(elder.doing) == "buying firewood", "with the coins in the elder's purse only, the elder buys the firewood (%s)" % elder.doing)


func test_elder_waits_for_an_adult_with_coins() -> void:
	var w := new_world()
	var h := household(w)
	var ms: Array = w.brain._members(h)
	var elder: NPC = ms[0]
	retire(w, elder, 60)
	var adult: NPC = null
	for o: NPC in ms.slice(1):
		if o.role != "adult":
			o.role = "adult"
		adult = o
		o.coins = 40
	log_seller(w)
	w.brain.decide(elder)
	check(str(elder.doing) != "buying firewood" and str(elder.doing) != "buying grain for the household",
		"an elder leaves the household's shopping to an adult member who has the coins (%s)" % elder.doing)
	check(adult != null and w.brain._elder_provides(elder) == false, "the rule: an adult of the household can pay")


func test_poor_elder_and_stocked_household() -> void:
	var w := new_world()
	var h := household(w)
	var ms: Array = w.brain._members(h)
	for o: NPC in ms:
		retire(w, o, 2)                             # too few coins for a log
	log_seller(w)
	var elder: NPC = ms[0]
	w.brain.decide(elder)
	check(str(elder.doing) != "buying firewood", "an elder without the coins for a log does not set out (%s)" % elder.doing)
	elder.coins = 60
	(w.households[h].pantry as Inventory).add("log", 1)
	var hh: Dictionary = w.households[h]
	for f in ["wheat"]:
		(hh.pantry as Inventory).add(f, 10)
	elder.plan.clear()
	w.brain.decide(elder)
	check(str(elder.doing) != "buying firewood" and str(elder.doing) != "buying grain for the household",
		"a household with firewood and grain in the pantry is not restocked (%s)" % elder.doing)
