extends SceneTree
## WDR-002-C: World Design Rule 2 (Professional Interdependency), its verification scenario: "Run a complete chain with
## inventories, payment, shortages and demand." Two chains on the real World and the real trade, craft and demand rules
## (NPCBrain.wants, World.purchase_qty/trade, the villagers' own craft step), each link a different profession:
##   grain:  farmer -> cook (wheat, paid) -> pottage -> tavernkeeper (paid)
##   timber: woodcutter -> carpenter (log, paid) -> planks -> smith (paid)
## Each link moves goods and coins between actual owners (nothing created but by a recipe), a short supply stops the next
## link, a demand already met buys nothing, and a buyer without coins buys nothing. Which professions supply which is
## audited per profession in docs/systems/MATERIAL_INTERDEPENDENCY.md (tools/check_materials.py). Pure World. Run headless:
##   godot --headless --path game --script res://tests/interdependency_test.gd

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
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	test_grain(w)
	test_timber(w)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func one(w: World, job: String, skip: Array = []) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job == job and not skip.has(n):
			return n
	return null


func clear(n: NPC, ids: Array) -> void:
	for id in ids:
		n.inv.remove(id, n.inv.count(id))


## One sale by the seller's own rule (the villagers' "sell_to" step): returns what changed hands.
func sell(w: World, seller: NPC, buyer: NPC, id: String) -> Dictionary:
	var g0 := buyer.inv.count(id)
	var sc := seller.coins
	var bc := buyer.coins
	var ok: bool = w.brain.act(seller, "sell_to", {"buyer": buyer.id, "item": id})
	return {"ok": ok, "goods": buyer.inv.count(id) - g0, "paid": bc - buyer.coins, "received": seller.coins - sc}


## The recipe at its station by the villager's own craft step (the stove or sawhorse is reserved, then released).
func make(w: World, n: NPC, recipe: String) -> bool:
	var st: String = w.brain._station_for(n, str(GameData.recipes[recipe].station))
	if st == "":
		return false
	return w.brain.act(n, "craft", {"recipe": recipe, "station": st})


func test_grain(w: World) -> void:
	var farmer := one(w, "farmer")
	var cook := one(w, "cook")
	var inn := one(w, "tavernkeeper")
	check(farmer != null and cook != null and inn != null, "the village has a farmer, a cook and a tavernkeeper")
	clear(farmer, ["wheat", "pottage"])
	clear(cook, ["wheat", "pottage"])
	clear(inn, ["pottage"])
	cook.coins = 100
	inn.coins = 100
	var coins0 := w.total_coins()
	# demand: a cook with no wheat wants it; one stocked to its limit wants none
	check(w.brain.wants(cook, "wheat") > 0, "demand: a cook out of wheat wants it")
	# shortage: nothing to cook, the next link stops
	check(not make(w, cook, "cook_pottage"), "shortage: with no wheat the cook makes no pottage")
	# payment: the farmer's wheat goes to the cook for coins
	var stock: int = w.brain.keep_wheat(farmer) + 8          # a farmer sells only the surplus beyond its household's keep
	farmer.inv.add("wheat", stock)
	var s1 := sell(w, farmer, cook, "wheat")
	check(s1.ok and s1.goods > 0 and s1.paid > 0 and s1.paid == s1.received, "payment: the cook pays the farmer for the wheat (%d for %d), coin for coin" % [s1.paid, s1.goods])
	check(farmer.inv.count("wheat") + cook.inv.count("wheat") == stock, "inventories: the wheat moved from the farmer to the cook, none lost or made")
	# production: the cook turns wheat into pottage (the recipe is the only creation)
	var wheat := cook.inv.count("wheat")
	check(wheat >= 2 and make(w, cook, "cook_pottage"), "the cook cooks pottage from the farmer's wheat")
	check(cook.inv.count("wheat") == wheat - 2 and cook.inv.count("pottage") == 6, "the recipe took 2 wheat and made 6 pottage")
	# the next link: pottage to the tavernkeeper, paid
	var s2 := sell(w, cook, inn, "pottage")
	check(s2.ok and s2.goods > 0 and s2.paid > 0 and s2.paid == s2.received, "payment: the tavernkeeper pays the cook for the pottage (%d for %d)" % [s2.paid, s2.goods])
	check(cook.inv.count("pottage") + inn.inv.count("pottage") == 6, "inventories: the pottage moved from the cook to the tavernkeeper")
	check(w.total_coins() == coins0, "the village's coins are the same after the chain: they only changed hands")
	# demand met: a tavernkeeper stocked to its limit buys no more
	inn.inv.add("pottage", 200)
	var held := inn.inv.count("pottage")
	cook.inv.add("pottage", 6)
	var s3 := sell(w, cook, inn, "pottage")
	check(not s3.ok and s3.goods == 0 and s3.paid == 0 and inn.inv.count("pottage") == held, "demand met: a tavernkeeper stocked to its limit buys nothing")
	# no purchasing power: a buyer without coins buys nothing, however much it wants
	clear(inn, ["pottage"])
	inn.coins = 0
	var s4 := sell(w, cook, inn, "pottage")
	check(not s4.ok and s4.goods == 0 and cook.inv.count("pottage") == 6, "no coins: need alone buys nothing, the cook keeps its pottage")


func test_timber(w: World) -> void:
	var cutter := one(w, "woodcutter")
	var carp := one(w, "carpenter")
	var smith := one(w, "smith")
	check(cutter != null and carp != null and smith != null, "the village has a woodcutter, a carpenter and a smith")
	clear(cutter, ["log", "plank"])
	clear(carp, ["log", "plank"])
	clear(smith, ["plank"])
	carp.coins = 100
	smith.coins = 100
	var coins0 := w.total_coins()
	check(w.brain.wants(carp, "log") > 0, "demand: a carpenter out of logs wants them")
	check(not make(w, carp, "saw_planks"), "shortage: with no logs the carpenter saws no planks")
	cutter.inv.add("log", 6)
	var s1 := sell(w, cutter, carp, "log")
	check(s1.ok and s1.goods > 0 and s1.paid > 0 and s1.paid == s1.received, "payment: the carpenter pays the woodcutter for the logs (%d for %d)" % [s1.paid, s1.goods])
	check(cutter.inv.count("log") + carp.inv.count("log") == 6, "inventories: the logs moved from the woodcutter to the carpenter")
	var logs := carp.inv.count("log")
	check(logs >= 1 and make(w, carp, "saw_planks"), "the carpenter saws planks from the woodcutter's logs")
	check(carp.inv.count("log") == logs - 1 and carp.inv.count("plank") == 2, "the recipe took 1 log and made 2 planks")
	var s2 := sell(w, carp, smith, "plank")
	check(s2.ok and s2.goods > 0 and s2.paid > 0 and s2.paid == s2.received, "payment: the smith pays the carpenter for the planks (%d for %d)" % [s2.paid, s2.goods])
	check(carp.inv.count("plank") + smith.inv.count("plank") == 2, "inventories: the planks moved from the carpenter to the smith")
	check(w.total_coins() == coins0, "the village's coins are the same after the chain: they only changed hands")
