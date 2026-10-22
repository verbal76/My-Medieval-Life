extends SceneTree
## STONE-01 (owner decision 2026-10-21, docs/directives/2026-10-21_quarry_stone_blocks_decision.md;
## docs/build17/STONE_01_BLOCKS.md): raw quarry stone and finished building blocks are separate items; blocks are dressed
## from raw stone at a workbench with a mallet, by one recipe for the player and villagers (dress_stone: real labour,
## a tool, time and a skill); houses and workshops take blocks; the labourers dress blocks only to real demand and sell
## them through the existing trade; no block is ever made from nothing; sites from before keep their raw-stone cost;
## saves keep it all; the same seed gives the same course. Run headless:
##   godot --headless --path game --script res://tests/stone_test.gd

const Census := preload("res://tests/census.gd")

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	_test_data()
	_test_recipe_parity()
	_test_no_free_blocks()
	_test_villager_to_demand()
	_test_construction()
	_test_older_site()
	_test_saves()
	_test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _first(w: World, pred: Callable) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and pred.call(n):
			return n
	return null


func _blocks_everywhere(w: World) -> int:
	return int(Census.goods(w).get("building_block", 0)) + int(w.site_goods().get("building_block", 0))


func _test_data() -> void:
	var it: Dictionary = GameData.item("building_block")
	check(not it.is_empty() and str(it.name) == "Building block" and GameData.item("stone").name == "Stone", "a building block is its own item, apart from raw stone")
	var r: Dictionary = GameData.recipes.get("dress_stone", {})
	check(not r.is_empty() and r["in"].size() == 1 and int(r["in"].stone) == 2 and r.out.size() == 1 and int(r.out.building_block) == 2 and str(r.station) == "workbench"
			and str(r.tool) == "mallet" and int(r.minutes) == 30 and str(r.skill) == "crafting" and bool(r.exact),
			"dress_stone: two raw stone to two blocks at a workbench, with a mallet, half an hour, Crafting")
	var ok := (GameData.b("house_cost") as Dictionary).has("building_block") and not (GameData.b("house_cost") as Dictionary).has("stone")
	for k in GameData.b("workshop_cost"):
		var c: Dictionary = GameData.b("workshop_cost")[k]
		ok = ok and not c.has("stone") and c.has("building_block")
	check(ok, "houses and every workshop or module take building blocks, not raw stone")
	check(int(GameData.b("house_cost").building_block) == 20, "a house takes 20 blocks, as it took 20 stone")
	check((GameData.b("shop_equipment").oven as Dictionary).has("stone") and int(GameData.b("farm_plot").gate_stone) == 2,
			"shop hearths and the farmland gate keep raw stone (agent decision, documented)")
	check(Construction.SELLERS.building_block == ["merchant_raw", "laborer"] and NPCBrain.OUTLETS.building_block == ["merchant_raw"]
			and int(NPCBrain.BUYS.merchant_raw.building_block) > 0 and NPCBrain.NOT_EXPORTED.has("building_block"),
			"blocks are sold by the raw-goods merchant and the labourers, and not exported")


## PAR-04: the player and a villager make blocks by the one rule: the skill, the mallet, the stone, the time.
func _test_recipe_parity() -> void:
	var w := _world(1)
	var p := w.player
	p.inv.remove("mallet", p.inv.count("mallet"))
	p.inv.add("stone", 2)
	check(w.player_craft_refusal("dress_stone") == "You need a mallet.", "the player cannot dress stone without a mallet")
	check(w.work_craft(p, "dress_stone", p.inv).result == "tool" and p.inv.count("stone") == 2 and p.inv.count("building_block") == 0,
			"nor does the work go on without one: the stone stays stone")
	p.inv.add("mallet")
	var full := int(GameData.item("mallet").durability)
	var dur0 := int(p.inv.durability.get("mallet", full))
	check(w.player_craft_refusal("dress_stone") == "", "with a mallet and two stone the player can")
	var begin := w.player_craft_begin("dress_stone")
	check(not bool(begin.ok) or float(begin.secs) > 0.0, "the work takes time (%s)" % str(begin))
	var r := w.work_craft(p, "dress_stone", p.inv)
	check(r.result == "ok" and p.inv.count("stone") == 0 and p.inv.count("building_block") == 2, "two stone became two blocks")
	check(int(p.skills.get("crafting", 0)) >= 4, "and earned Crafting experience")
	check(int(p.inv.durability.get("mallet", full)) == dur0 - 1, "the mallet wore (%d of %d left)" % [int(p.inv.durability.get("mallet", full)), full])
	var v := _first(w, func(n: NPC) -> bool: return n.role == "adult" and n.job == "laborer")
	check(v != null, "the village has a labourer")
	if v == null:
		return
	v.inv.remove("mallet", v.inv.count("mallet"))
	v.inv.add("stone", 2)
	check(not w.brain._can_make(v, "dress_stone") and w.work_craft(v, "dress_stone", v.inv).result == "tool", "a villager without a mallet cannot either")
	v.inv.add("mallet")
	check(w.brain._can_make(v, "dress_stone"), "with a mallet they can")
	var r2 := w.work_craft(v, "dress_stone", v.inv)
	check(r2.result == "ok" and v.inv.count("stone") == 0 and v.inv.count("building_block") == 2, "the villager's two stone became two blocks, the same rule")
	v.skills["crafting"] = 0
	var low := {"skill": "crafting", "level": 1}
	check(Skills.level(v, str(low.skill)) >= int(low.level), "Crafting 1 is every adult's (the recipe's level)")


## Blocks come only out of stone: one stone, no block; a master's practised hand saves nothing and adds nothing.
func _test_no_free_blocks() -> void:
	var w := _world(2)
	var p := w.player
	p.inv.add("mallet")
	p.inv.add("stone", 1)
	check(w.work_craft(p, "dress_stone", p.inv).result == "materials" and p.inv.count("building_block") == 0 and p.inv.count("stone") == 1,
			"one stone makes no block")
	p.skills["crafting"] = Skills.xp_for_level(10)              # save_chance 0.25, bonus_chance 0.2 for other recipes
	p.inv.add("stone", 199)
	var made0 := int(w.stats.get("made_building_block", 0))
	var used0 := int(w.stats.get("used_stone", 0))
	var n := 0
	while p.inv.count("stone") >= 2:
		if w.work_craft(p, "dress_stone", p.inv).result != "ok":
			p.inv.add("mallet")                                   # a worn-out mallet replaced
			continue
		n += 1
	var made := int(w.stats.get("made_building_block", 0)) - made0
	var used := int(w.stats.get("used_stone", 0)) - used0
	check(n == 100 and p.inv.count("building_block") == 200 and made == 200 and used == 200,
			"a master dressed 200 stone into exactly 200 blocks in 100 batches (made %d, stone used %d)" % [made, used])
	check(int(w.stats.get("made_building_block", 0)) == _blocks_everywhere(w), "every block in the world was made from stone")


## The labourers dress stone only while blocks are wanted, and sell them on to the raw-goods merchant.
func _test_villager_to_demand() -> void:
	var w := _world(1)
	var lab := _first(w, func(n: NPC) -> bool: return n.role == "adult" and n.job == "laborer")
	var raw := _first(w, func(n: NPC) -> bool: return w.brain.buy_role(n) == "merchant_raw")
	check(lab != null and raw != null, "a labourer and a raw-goods merchant")
	if lab == null or raw == null:
		return
	# no demand: the merchant holds all the blocks it wants and no site needs any
	var raws := w.npcs.filter(func(n: NPC) -> bool: return n.alive and w.brain.buy_role(n) == "merchant_raw")
	for o: NPC in raws:
		o.inv.add("building_block", int(NPCBrain.BUYS.merchant_raw.building_block))
	lab.inv.add("mallet")
	lab.inv.add("stone", 4)
	check(w.construction.open_need("building_block") == 0 and not w.brain._block_demand(lab) and not w.brain._mason(lab),
			"with nobody wanting blocks (%d raw-goods merchants stocked, no site) the labourer dresses none" % raws.size())
	# demand: a merchant has room for blocks
	for o: NPC in raws:
		o.inv.remove("building_block", o.inv.count("building_block"))
	raw.coins = maxi(raw.coins, 200)
	check(w.brain._block_demand(lab), "the merchant wanting blocks is demand")
	lab.plan.clear()
	check(w.brain._mason(lab) and lab.plan.any(func(s): return str(s.get("act", "")) == "craft" and str(s.get("args", {}).get("recipe", "")) == "dress_stone"),
			"a labourer with a mallet and stone sets to dressing it at a workbench (%s)" % lab.doing)
	var blocks0 := _blocks_everywhere(w)
	var made0 := int(w.stats.get("made_building_block", 0))
	var stone_used0 := int(w.stats.get("used_stone", 0))
	var sold := false
	for k in 1440:
		w.update(0.5)
		if raw.inv.count("building_block") > 0:
			sold = true
			break
	var made := int(w.stats.get("made_building_block", 0)) - made0
	check(made > 0, "the village made %d blocks (by labourers)" % made)
	check(sold, "and they reached the raw-goods merchant through the trade (%d held)" % raw.inv.count("building_block"))
	check(_blocks_everywhere(w) - blocks0 == made - (int(w.stats.get("used_building_building_block", 0))), "every block counted: made = held + built in")
	check(int(w.stats.get("used_stone", 0)) - stone_used0 >= made, "each block took its stone (%d stone for %d blocks)" % [int(w.stats.get("used_stone", 0)) - stone_used0, made])
	# a labourer without a mallet buys one from the goods merchant, made by the carpenter
	var gm := _first(w, func(n: NPC) -> bool: return w.brain.buy_role(n) == "merchant_goods")
	var lab2 := _first(w, func(n: NPC) -> bool: return n.role == "adult" and n.job == "laborer" and n != lab)
	if gm != null and lab2 != null:
		lab2.inv.remove("mallet", lab2.inv.count("mallet"))
		gm.inv.add("mallet")
		raw.inv.remove("building_block", raw.inv.count("building_block"))
		lab2.coins = 100
		lab2.plan.clear()
		check(w.brain._mason(lab2) and lab2.plan.any(func(s): return str(s.get("act", "")) == "buy_from" and str(s.args.item) == "mallet"),
				"a labourer without a mallet buys one to meet the demand (%s)" % lab2.doing)


## Houses take blocks: raw stone is not accepted for them; a finished house uses its blocks up.
func _test_construction() -> void:
	var w := _world(3)
	var p := w.player
	var pl: Dictionary = w.plots[0]
	p.coins += 200
	w.buy_plot(pl)
	w.start_site(pl)
	check(pl.site.cost == GameData.b("house_cost") and pl.site.need.has("building_block") and not pl.site.need.has("stone"), "a new house site needs building blocks")
	p.inv.add("stone", 20)
	w.deliver(pl, p.inv)
	check(p.inv.count("stone") == 20 and int(pl.site.need.building_block) == 20, "raw stone is not taken for blocks")
	p.inv.add("building_block", 20)
	p.inv.add("plank", 30)
	p.inv.add("log", 10)
	var used0 := int(w.stats.get("used_building_building_block", 0))
	var done := w.deliver(pl, p.inv)
	check(done and p.inv.count("building_block") == 0 and int(w.stats.get("used_building_building_block", 0)) - used0 == 20,
			"20 blocks, 30 planks and 10 logs finish the house; the blocks are used up in it")
	# the helpers' market: a labourer's blocks are on sale to a builder
	var lab := _first(w, func(n: NPC) -> bool: return n.role == "adult" and n.job == "laborer")
	check(lab != null and w.construction._sells(lab, "building_block"), "a labourer sells blocks to builders")


## STONE-01 saves: a site marked out before blocks keeps its raw-stone cost; its delivered stone is its own and comes
## back on cancelling, as stone; it finishes with stone; nothing becomes a block.
func _test_older_site() -> void:
	var w := _world(4)
	var p := w.player
	var pl: Dictionary = w.plots[0]
	p.coins += 200
	w.buy_plot(pl)
	w.start_site(pl)
	pl.site.cost = {"plank": 30, "stone": 20, "log": 10}       # as a Build 16 or earlier Build 17 save holds it
	pl.site.need = {"plank": 30, "stone": 12, "log": 10}
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var pl2: Dictionary = w2.plot(str(pl.id))
	check(pl2.site.cost.has("stone") and int(pl2.site.need.stone) == 12 and not pl2.site.need.has("building_block"),
			"an older site keeps its recorded cost and need in raw stone after loading")
	check(w2.site_delivered(pl2) == {"stone": 8}, "its 8 stone delivered are counted as stone")
	var blocks0 := _blocks_everywhere(w2)
	w2.player.inv.add("stone", 3)
	w2.deliver(pl2, w2.player.inv)
	check(int(pl2.site.need.stone) == 9 and w2.player.inv.count("stone") == 0, "it still takes raw stone for its recorded need")
	check(w2.construction.open_need("stone") >= 9 and Construction.SELLERS.has("stone"), "and its builders can still buy raw stone for it")
	var back := w2.cancel_site(pl2, w2.player.inv)
	check(back == {"stone": 11} and w2.player.inv.count("stone") == 11 and _blocks_everywhere(w2) == blocks0, "cancelled, it gives back the 11 stone as stone: no block appears")
	# a site with no recorded cost (the oldest saves) is the house cost of its day, never today's blocks
	w2.start_site(pl2)
	pl2.site.erase("cost")
	pl2.site.need = {"plank": 30, "stone": 20, "log": 10}
	check(w2.site_delivered(pl2).is_empty(), "a site with no recorded cost counts nothing delivered that was never brought")


## Blocks and stone in packs, merchants and sites survive a save; the save version is unchanged (no format change).
func _test_saves() -> void:
	var w := _world(5)
	w.player.inv.add("building_block", 7)
	w.player.inv.add("stone", 3)
	var lab := _first(w, func(n: NPC) -> bool: return n.role == "adult" and n.job == "laborer")
	lab.inv.add("building_block", 4)
	var g0 := Census.goods(w)
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var g1 := Census.goods(w2)
	check(int(g1.get("building_block", 0)) == int(g0.get("building_block", 0)) and int(g1.get("stone", 0)) == int(g0.get("stone", 0)),
			"blocks (%d) and stone (%d) are all there after loading" % [int(g1.get("building_block", 0)), int(g1.get("stone", 0))])
	check(w2.player.inv.count("building_block") == 7 and w2.npc(lab.id).inv.count("building_block") == 4, "in the same hands")
	check(int(d.save_version) == World.SAVE_VERSION and World.SAVE_VERSION >= 17, "no new save version of its own (17; 18 is CC-01)")


## The same seed, the same course: two worlds with a labourer set to dress stone end alike.
func _test_determinism() -> void:
	var out := []
	for i in 2:
		var w := _world(6)
		for n: NPC in w.npcs:
			if n.alive and n.role == "adult" and n.job == "laborer":
				n.inv.add("mallet")
		for k in 960:
			w.update(0.5)
		out.append([int(w.stats.get("made_building_block", 0)), _blocks_everywhere(w), int(w.stats.get("used_stone", 0)), w.total_coins(), Census.goods(w).get("stone", 0)])
	check(out[0] == out[1], "two runs of one seed: the same blocks made, held and stone used (%s)" % str(out[0]))
	check(int(out[0][0]) > 0, "and blocks were made to the merchant's demand (%d)" % int(out[0][0]))
