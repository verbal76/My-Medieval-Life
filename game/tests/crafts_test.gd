extends SceneTree
## Build 17: villagers make and sell the stuff of B14-07's wooden stairs and walkways by the PAR-04 rule (made for a buyer
## only): the smith forges nails and the carpenter makes mallets when the goods merchant wants them, and sells them to it;
## and PL1-12: the low red flowering plant can be picked wherever it grows, in the village and (overworld generator
## version 2) outside it, with version 1 saves still keeping their changes.
##   godot --headless --path game --script res://tests/crafts_test.gd

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
	test_smith_nails()
	test_carpenter_mallet()
	test_red_flower_village()
	test_red_flower_outside()
	test_old_overworld_save()
	test_wiki()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func merchant_goods(w: World) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and w.brain.buy_role(o) == "merchant_goods":
			return o
	return null


## A smith with only one iron bar and its lockpicks stocked: what it forges is up to the buyers.
func bare_smith(w: World) -> NPC:
	var s: NPC = w.brain._first_with_job("smith")
	s.inv = Inventory.new()
	s.inv.add("hammer")
	s.inv.add("iron_bar", 1)
	s.inv.add("lockpick", 3)
	w.minutes = floorf(w.minutes / World.DAY) * World.DAY + 10.0 * 60.0
	return s


## Fill (or empty) every goods merchant's stock of `id` to what it buys.
func stock(w: World, id: String, full: bool) -> void:
	for o: NPC in w.npcs:
		if o.alive and w.brain.buy_role(o) == "merchant_goods":
			o.inv.remove(id, o.inv.count(id))
			if full:
				o.inv.add(id, int(NPCBrain.BUYS.merchant_goods[id]))


func _plans(n: NPC, recipe: String) -> bool:
	return n.plan.any(func(st): return str(st.get("act", "")) == "craft" and str(st.get("args", {}).get("recipe", "")) == recipe)


func test_smith_nails() -> void:
	var w := new_world()
	var m := merchant_goods(w)
	var s := bare_smith(w)
	check(m != null and w.brain.wants(m, "nails") > 0, "the goods merchant wants nails (BUYS)")
	stock(w, "nails", true)
	m.coins = 500
	w.brain._smith(s)
	check(not _plans(s, "forge_nails"), "with every goods merchant stocked, the smith forges no nails (made for a buyer only)")
	stock(w, "nails", false)
	s.plan.clear()
	w.brain._smith(s)
	check(_plans(s, "forge_nails"), "with the merchant short of nails, the smith forges them")
	check(str(w.work_craft(s, "forge_nails", s.inv).result) == "ok" and s.inv.count("nails") >= 12, "a bar becomes a dozen nails (World.work_craft)")
	var c0 := w.total_coins()
	s.plan.clear()
	w.brain._smith(s)
	var sell: Dictionary = s.plan[-1] if not s.plan.is_empty() else {}
	check(str(sell.get("act", "")) == "sell_to" and str(sell.args.item) == "nails" and int(sell.args.buyer) == m.id, "and takes them to the goods merchant")
	var held := s.inv.count("nails")
	check(w.brain.act(s, "sell_to", sell.args) and m.inv.count("nails") > 0 and s.inv.count("nails") < held and w.total_coins() == c0,
		"who buys them (%d) for coins that only move" % m.inv.count("nails"))


func test_carpenter_mallet() -> void:
	var w := new_world()
	var m := merchant_goods(w)
	var c: NPC = w.brain._first_with_job("carpenter")
	c.inv.add("log", 2)
	c.inv.add("plank", 2)
	w.minutes = floorf(w.minutes / World.DAY) * World.DAY + 10.0 * 60.0
	m.coins = 500
	stock(w, "mallet", true)
	check(not w.brain._carpenter_mallet(c), "with every goods merchant stocked, the carpenter makes no mallet")
	stock(w, "mallet", false)
	check(w.brain._carpenter_mallet(c) and _plans(c, "make_mallet"), "with the merchant wanting one, the carpenter makes a mallet at the workbench")
	check(str(w.work_craft(c, "make_mallet", c.inv).result) == "ok" and c.inv.has("mallet"), "a log and a plank become a mallet")
	check(w.brain._carpenter_mallet(c) and str(c.plan[-1].get("act", "")) == "sell_to", "and the carpenter takes it to the merchant")
	check(w.brain.act(c, "sell_to", c.plan[-1].args) and m.inv.has("mallet") and not c.inv.has("mallet"), "who buys it")


func test_red_flower_village() -> void:
	var w := new_world()
	var red := {}
	for pl in w.plants:
		if int(pl.get("tile", 0)) == 2656:
			red = pl
	check(not red.is_empty() and str(red.kind) == "flower", "the village's low red flowering plant is a wild flower plant")
	if red.is_empty():
		return
	var at := w.plant_at(Vector2i(int(red.x), int(red.y)))
	var got := w.pick_plant(at)
	check(int(got.get("flower", 0)) == 1 and str(red.state) == "picked", "it can be picked: a flower, and the plant is bare until it regrows")


func test_red_flower_outside() -> void:
	var w := new_world()
	var o: Overworld = w.map.overworld
	check(2656 in (o.tiles.flowers as Array).map(func(t): return int(t)), "the overworld draws the red flower among its wild flowers (overworld_tiles.json)")
	var found := {}
	var count := 0
	for cy in range(-3, 4):
		for cx in range(-3, 4):
			var ch := o.get_chunk(Vector2i(cx, cy))
			for i in Overworld.CHUNK * Overworld.CHUNK:
				if ch.deco[i] == 2656:
					count += 1
					if found.is_empty():
						found = o.flower_at(Vector2i(cx * Overworld.CHUNK + i % Overworld.CHUNK, cy * Overworld.CHUNK + i / Overworld.CHUNK))
	check(count > 0 and not found.is_empty(), "red flowers grow outside the village (%d near it)" % count)
	if found.is_empty():
		return
	var cell := Vector2i(int(found.x), int(found.y))
	var got := w.pick_plant(w.plant_at(cell))
	check(int(got.get("flower", 0)) == 1 and o.flower_gone(cell), "one outside is picked like any wild flower")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.map.overworld.flower_gone(cell), "and the picking is saved")


func test_old_overworld_save() -> void:
	var w := new_world()
	var o: Overworld = w.map.overworld
	o.note_rock(Vector2i(-50, -50), 0)
	var d := w.to_dict()
	check(int(d.overworld.gen) == Overworld.GEN_VERSION and Overworld.GEN_VERSION == 2, "the overworld generator is version 2")
	d.overworld.gen = 1
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w2.map.overworld.rock_changes.get(Vector2i(-50, -50), 1) == 0, "a version 1 save keeps its changes (the cells are the same)")


func test_wiki() -> void:
	var wk := Wiki.build()
	var t: String = wk.pages.get("sys:cliff_ways", {}).get("text", "")
	check(t.contains("pickaxe and mining level 2") and t.contains("mallet and carpentry level 2") and t.contains("both ways") and t.contains("never grows again")
			and "sys:cliff_ways" in wk.search("stairs"), "the wiki explains cliff steps, stairs and walkways")
