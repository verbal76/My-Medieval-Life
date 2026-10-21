extends SceneTree
## DVW-B4: goods decay. Stored food spoils a little each dawn (grain slowest), counted as spoiled_<item> so the goods
## ledger balances; the draw is hashed, not taken from world.rng, so a world spoils the same way every run; clothes and
## armour wear by the day worn and are gone when worn out (broke_), the player's and villagers' alike; carts wear by
## the tiles pulled and fall apart leaving their load lying; wear is saved; conditions read as words.
##   godot --headless --path game --script res://tests/decay_test.gd

const Census := preload("res://tests/census.gd")

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
	test_rates()
	test_spoilage_ledger()
	test_clothes_and_armour()
	test_carts()
	test_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func test_rates() -> void:
	check(Decay.rate("wheat") > 0.0 and Decay.rate("wheat") < Decay.rate("pottage") and Decay.rate("pottage") < Decay.rate("milk"), "grain spoils slowest, cooked food faster, milk fastest")
	check(Decay.rate("iron_ore") == 0.0 and Decay.rate("log") == 0.0 and Decay.rate("healing_tonic") == 0.0, "ore, wood and medicine keep")
	check(Decay.spoiled(1000, 0.004, 0.99) == 4 and Decay.spoiled(1000, 0.004, 0.0) == 4 and Decay.spoiled(10, 0.05, 0.3) == 1 and Decay.spoiled(10, 0.05, 0.6) == 0,
		"count x rate whole units spoil, the remainder as one more unit when the draw falls under it")
	check(Decay.spoiled(3, 0.5, 0.0) <= 3 and Decay.spoiled(0, 0.5, 0.0) == 0 and Decay.spoiled(5, 0.0, 0.0) == 0, "never more than the stack, nothing from nothing")
	check(Decay.draw(1, 5, "hh:2", "wheat") == Decay.draw(1, 5, "hh:2", "wheat") and Decay.draw(1, 5, "hh:2", "wheat") != Decay.draw(1, 6, "hh:2", "wheat"),
		"the draw is fixed for a world, day, holder and item, and differs by day")
	var n := 0
	var lost := 0
	for d in 2000:
		lost += Decay.spoiled(5, 0.05, Decay.draw(1, d, "x", "pottage"))
		n += 5
	check(absf(float(lost) / float(n) - 0.05) < 0.01, "over many days the loss is the rate (%.3f of 0.05)" % (float(lost) / float(n)))
	check(Decay.condition(100, 100) == "new" and Decay.condition(50, 100) == "worn" and Decay.condition(20, 100) == "well worn" and Decay.condition(5, 100) == "falling apart", "condition words")


func test_spoilage_ledger() -> void:
	var w := new_world()
	var pantry: Inventory = w.households[0].pantry
	pantry.add("wheat", 1000)
	pantry.add("iron_ore", 50)
	var p0 := pantry.count("wheat")
	var ore0 := pantry.count("iron_ore")
	var g0 := Census.goods(w)
	var st0 := w.stats.duplicate()
	var w2 := new_world()
	w2.households[0].pantry.add("wheat", 1000)
	w2.households[0].pantry.add("iron_ore", 50)
	Decay.dawn(w)
	Decay.dawn(w2)
	check(pantry.count("wheat") == p0 - floori(float(p0) * Decay.rate("wheat")) or pantry.count("wheat") == p0 - floori(float(p0) * Decay.rate("wheat")) - 1,
		"a pantry's grain loses its day's share (%d of %d)" % [p0 - pantry.count("wheat"), p0])
	check(pantry.count("iron_ore") == ore0, "ore does not spoil")
	var g1 := Census.goods(w)
	var ok := true
	for id in g0:
		var gone := int(g0[id]) - int(g1.get(id, 0))
		var counted := int(float(w.stats.get("spoiled_" + id, 0.0)) - float(st0.get("spoiled_" + id, 0.0)))
		if gone != counted:
			ok = false
			printerr("  %s: %d gone, %d counted" % [id, gone, counted])
	check(ok, "every good that left the village's stock is counted as spoiled_<item> (the ledger balances)")
	check(float(w.stats.get("spoiled_total", 0.0)) > 0.0, "spoilage is counted (%d units)" % int(w.stats.get("spoiled_total", 0.0)))
	check(Census.goods(w) == Census.goods(w2), "two worlds of the same seed spoil exactly alike (no world.rng)")


func test_clothes_and_armour() -> void:
	var w := new_world()
	var p := w.player
	check(p.armor == "plain_clothes" and p.inv.has("plain_clothes"), "the player starts in plain clothes")
	var full := int(GameData.item("plain_clothes").durability)
	Decay.wear_clothes(w)
	check(int(p.inv.durability.get("plain_clothes", full)) == full - 1, "clothes worn lose a day's wear")
	p.inv.durability["plain_clothes"] = 1
	Decay.wear_clothes(w)
	check(not p.inv.has("plain_clothes") and p.armor == "" and int(w.stats.get("broke_plain_clothes", 0)) == 1, "worn out, they are gone and the slot empties (broke_plain_clothes)")
	p.inv.add("leather_armor")
	p.inv.add("leather_armor")
	p.armor = "leather_armor"
	p.inv.durability["leather_armor"] = 1
	Decay.wear_clothes(w)
	check(p.inv.count("leather_armor") == 1 and p.armor == "leather_armor" and int(p.inv.durability.leather_armor) == int(GameData.item("leather_armor").durability),
		"with a spare, the next one is worn, fresh")
	var unworn := int(p.inv.durability.get("leather_armor", 0))
	p.armor = ""
	Decay.wear_clothes(w)
	check(int(p.inv.durability.get("leather_armor", 0)) == unworn, "armour carried but not worn does not wear")
	var g: NPC = w.brain._first_with_job("guard")
	check(g != null and g.inv.has("leather_armor"), "a guard wears leather armour")
	if g == null:
		return
	var a0 := g.armor
	g.inv.durability["leather_armor"] = 1
	Decay.wear_clothes(w)
	check(not g.inv.has("leather_armor") and g.armor == maxf(0.0, a0 - float(GameData.item("leather_armor").armor)), "a villager's armour wears out by the same rule and its protection goes")


func _cart(w: World) -> Dictionary:
	var c := w.carts.place(World.PLAYER, w.player.pos + Vector2(1, 0))
	(c.store as Inventory).add("log", 5)
	return c


func test_carts() -> void:
	var w := new_world()
	var c := _cart(w)
	check(w.carts.condition(c) == "new", "a new cart is new")
	w.carts.hitch(c, World.PLAYER)
	var g0 := Census.goods(w)
	w.player.pos += Vector2(5, 0)
	w.carts.update(0.1)
	check(float(c.worn) > 2.5 and float(c.worn) < 6.0, "pulling wears it by the tiles it moved (%.1f)" % float(c.worn))
	c.worn = float(Decay.cfg().cart_tiles) * 0.4
	check(w.carts.condition(c) == "worn", "a cart pulled for part of its life reads worn")
	c.worn = float(Decay.cfg().cart_tiles) - 1.0
	var loot0 := w.loot.size()
	w.player.pos += Vector2(5, 0)
	w.carts.update(0.1)
	check(w.carts.carts.is_empty() and int(w.stats.get("carts_broken", 0)) == 1, "worn out, it falls apart")
	check(w.loot.size() == loot0 + 1 and (w.loot[-1].inv as Inventory).count("log") == 5 and Census.goods(w) == g0, "and its load lies where it stood: no good lost")


func test_save() -> void:
	var w := new_world()
	var c := _cart(w)
	c.worn = 123.5
	w.player.inv.durability["plain_clothes"] = 77
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(is_equal_approx(float(w2.carts.carts[0].worn), 123.5) and int(w2.player.inv.durability.plain_clothes) == 77, "a cart's wear and clothes' wear are saved and loaded")
	var d := w.to_dict()
	for r in d.carts.carts:
		r.erase("worn")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(float(w3.carts.carts[0].worn) == 0.0, "an older save's carts load unworn")
