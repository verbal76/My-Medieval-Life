extends SceneTree
## B42 (lead decision 2026-11-14; LE-03 design s.6 "cannot silently divert committed stock"): a villager's own meal and the
## family-chest stocking took food that a CON-01 contract's input earmark claimed, with no claims check (found by the
## B42-EARMARK-SHORT trace audit). Now they use unclaimed units only; survival is never put behind a contract: with no other
## meal a villager eats a claimed unit, and its earmark shrinks by it ("eaten in need"). Checked, with the Living Economy on:
##   1 earmarked milk is not eaten while other food is in the pack (the meal plan picks the other food; an "eat milk" act refuses)
##   2 earmarked milk is not put into the household's pantry (stock_family_chest)
##   3 in need, the claimed milk is eaten, the earmark shrinks by the unit, nothing is left unbacked, the use is counted
##   4 the contract's own recipe still works from the rest (after_craft), and no milk is created or lost (pack + pantry + eaten)
##   godot --headless --path game --script res://tests/b42_earmark_eat_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	c.market.drive = true
	EconomyFoundation.set_override(c)
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var maker: NPC = null
	var buyer: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0:
			if maker == null and w.brain._can_make(n, "press_cheese"):
				maker = n
			elif buyer == null:
				buyer = n
	check(maker != null and buyer != null, "a villager who can press cheese, and a buyer")
	var ref := World.npc_ref(maker.id)
	var pantry: Inventory = w.households[maker.household].pantry
	for f in NPCBrain.EDIBLE + ["meat"]:
		maker.inv.remove(f, maker.inv.count(f))
	maker.inv.add("milk", 3)
	maker.inv.add("bread", 1)
	buyer.coins = 300
	var k: Dictionary = w.contracts._new_record(World.npc_ref(buyer.id), ref, "cheese", 1, 6, 4, [])
	k.route = "craft"
	k.recipe = "press_cheese"
	check(w.contracts._open(k) and w.economy.reservations.reserved(ref, "milk") == 3, "a craft contract earmarks the 3 milk its cheese needs")
	var milk0 := maker.inv.count("milk") + pantry.count("milk")
	# 1 other food first; the earmarked milk is not eaten
	maker.hunger = 40.0
	maker.plan.clear()
	var planned: bool = w.brain._plan_eat(maker)
	var item := str((maker.plan[0] as Dictionary).get("args", {}).get("item", "")) if planned and not maker.plan.is_empty() else ""
	check(planned and item != "milk", "with bread in the pack the meal is not the earmarked milk (plan: %s)" % JSON.stringify(maker.plan))
	check(not w.brain.act(maker, "eat", {"item": "milk"}) and maker.inv.count("milk") == 3, "an ordinary 'eat milk' refuses the earmarked milk")
	# 2 storing never takes earmarked units
	w.brain.stock_family_chest(maker)
	check(pantry.count("milk") == 0 and maker.inv.count("milk") == 3, "earmarked milk is not put into the household's pantry (pack %d, pantry %d)" % [maker.inv.count("milk"), pantry.count("milk")])
	# 3 in need: no other food at all, the claimed milk is eaten and the earmark shrinks by it
	maker.inv.remove("bread", maker.inv.count("bread"))
	var eaten0 := float(w.stats.get("eaten_milk", 0.0))
	var h0 := maker.hunger
	check(w.brain.act(maker, "eat", {"item": "milk", "in_need": true}) and maker.inv.count("milk") == 2 and maker.hunger > h0, "in need the claimed milk is eaten")
	check(w.economy.reservations.reserved(ref, "milk") == 2 and w.economy.reservations.unbacked().is_empty(), "the earmark shrank by the unit eaten (2 milk), nothing is left unbacked")
	check(int(w.economy.claims.stats.get("earmark_eaten_in_need", 0)) == 1 and float(w.stats.get("eaten_in_need_milk", 0.0)) == 1.0, "the use in need is counted (earmark_eaten_in_need 1)")
	check(maker.inv.count("milk") + pantry.count("milk") + int(float(w.stats.get("eaten_milk", 0.0)) - eaten0) == milk0, "no milk created or lost (pack + pantry + eaten = %d)" % milk0)
	# 4 the contract's own recipe still uses what it holds: one more milk and the cheese is made from the earmark
	maker.inv.add("milk", 1)
	var res: Dictionary = w.work_craft(maker, "press_cheese", maker.inv)
	check(res.result == "ok" and maker.inv.count("cheese") == 1 and w.economy.reservations.reserved(ref, "milk") == 0, "the contract's recipe works from the earmark as before (%s)" % str(res.result))
	w.dispose()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
