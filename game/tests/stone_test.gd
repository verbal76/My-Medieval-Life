extends SceneTree
## STONE-01 (owner decision 2026-10-21, docs/directives/2026-10-21_quarry_stone_blocks_decision.md;
## docs/build17/STONE_01_BLOCKS.md): raw quarry stone and finished building blocks are separate items; blocks are dressed
## from raw stone at a workbench with a mallet, by one recipe for the player and villagers (dress_stone: real labour,
## a tool, time and a skill); houses and workshops take blocks; the labourers dress blocks only to real demand and sell
## them through the existing trade; no block is ever made from nothing; sites from before keep their raw-stone cost;
## saves keep it all; the same seed gives the same course.
## Build 18 (owner B18-DP-09, B18-DP-10; STONE-02, STONE-03, STONE-04, STONE-06, X18-STONECUT): dressing is three raw stone
## to two blocks and one fragment (raw stone), with a mallet AND an iron chisel (forge_chisel), by the Masonry tiers; any
## villager may dress for their own use; the stonecutter is an independent trade in the ordinary economy. Run headless:
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
	_test_masonry_tiers()
	_test_chisel()
	_test_personal_use()
	_test_stonecutter()
	_test_villager_to_demand()
	_test_construction()
	_test_older_site()
	_test_saves()
	_test_old_save()
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
	check(not r.is_empty() and r["in"].size() == 1 and int(r["in"].stone) == 3 and r.out.size() == 2 and int(r.out.building_block) == 2 and int(r.out.stone) == 1
			and str(r.station) == "workbench" and r.tool == ["mallet", "chisel"] and int(r.minutes) == 30 and str(r.skill) == "masonry" and not r.has("exact"),
			"dress_stone: three raw stone to two blocks and one stone, at a workbench, with a mallet and an iron chisel, half an hour, Masonry")
	var f: Dictionary = GameData.recipes.get("forge_chisel", {})
	var ch: Dictionary = GameData.item("chisel")
	check(not f.is_empty() and str(f.station) == "anvil" and f["in"].size() == 1 and int(f["in"].iron_bar) == 1 and f.out.size() == 1 and int(f.out.chisel) == 1 and int(f.minutes) == 30 and str(f.skill) == "smithing" and int(f.level) == 1,
			"forge_chisel: an iron bar at the anvil, half an hour, Smithing 1 (B18-DP-10)")
	check(str(ch.name) == "Iron chisel" and str(ch.tool) == "chisel" and int(ch.durability) == 150 and int(ch.value) == 18 and str(ch.category) == "tools",
			"the iron chisel is an item: a tool of 150 uses worth 18 coins (the hammer's 20, from its bar)")
	var ok := (GameData.b("house_cost") as Dictionary).has("building_block") and not (GameData.b("house_cost") as Dictionary).has("stone")
	for k in GameData.b("workshop_cost"):
		var c: Dictionary = GameData.b("workshop_cost")[k]
		ok = ok and not c.has("stone") and c.has("building_block")
	check(ok, "houses and every workshop or module take building blocks, not raw stone")
	check(int(GameData.b("house_cost").building_block) == 20, "a house takes 20 blocks, as it took 20 stone")
	check((GameData.b("shop_equipment").oven as Dictionary).has("stone") and int(GameData.b("farm_plot").gate_stone) == 2,
			"shop hearths and the farmland gate keep raw stone (agent decision, documented)")
	check(Construction.SELLERS.building_block == ["merchant_raw", "laborer", "stonecutter"] and NPCBrain.OUTLETS.building_block == ["merchant_raw"]
			and int(NPCBrain.BUYS.merchant_raw.building_block) > 0 and NPCBrain.NOT_EXPORTED.has("building_block"),
			"blocks are sold by the raw-goods merchant, the labourers and the stonecutters, and not exported")


## PAR-04: the player and a villager make blocks by the one rule: the skill, the mallet and the chisel, the stone, the time.
func _test_recipe_parity() -> void:
	var w := _world(1)
	var p := w.player
	p.inv.remove("mallet", p.inv.count("mallet"))
	p.inv.remove("chisel", p.inv.count("chisel"))
	p.inv.add("stone", 3)
	check(w.player_craft_refusal("dress_stone") == "You need a mallet.", "the player cannot dress stone without a mallet")
	p.inv.add("mallet")
	check(w.player_craft_refusal("dress_stone") == "You need an iron chisel.", "nor with a mallet and no iron chisel")
	check(w.work_craft(p, "dress_stone", p.inv).result == "tool" and p.inv.count("stone") == 3 and p.inv.count("building_block") == 0,
			"nor does the work go on without both: the stone stays stone")
	p.inv.remove("mallet")
	p.inv.add("chisel")
	check(w.player_craft_refusal("dress_stone") == "You need a mallet.", "a chisel alone is not enough either")
	p.inv.add("mallet")
	var mfull := int(GameData.item("mallet").durability)
	var cfull := int(GameData.item("chisel").durability)
	var mdur0 := int(p.inv.durability.get("mallet", mfull))
	var cdur0 := int(p.inv.durability.get("chisel", cfull))
	check(w.player_craft_refusal("dress_stone") == "", "with both and three stone the player can")
	var begin := w.player_craft_begin("dress_stone")
	check(not bool(begin.ok) or float(begin.secs) > 0.0, "the work takes time (%s)" % str(begin))
	var made0 := int(w.stats.get("made_building_block", 0))
	var r := w.work_craft(p, "dress_stone", p.inv)
	check(r.result == "ok" and p.inv.count("stone") == 1 and p.inv.count("building_block") == 2, "three stone became two blocks and one fragment, kept as raw stone")
	check(int(w.stats.get("made_building_block", 0)) - made0 == 2 and int(w.stats.get("used_stone", 0)) == 3 and int(w.stats.get("made_stone", 0)) == 1,
			"the ledger: 3 stone used, 2 blocks and 1 stone made")
	check(int(p.skills.get("masonry", 0)) >= 4, "and earned Masonry experience")
	check(int(p.inv.durability.get("mallet", mfull)) == mdur0 - 1 and int(p.inv.durability.get("chisel", cfull)) == cdur0 - 1,
			"the mallet and the chisel each wore a use (%d, %d left)" % [int(p.inv.durability.get("mallet", mfull)), int(p.inv.durability.get("chisel", cfull))])
	check(p.inv.has_all({"stone": 1}) and not p.inv.has_all({"stone": 3}), "the fragment is raw stone: it counts towards the next batch")
	var v := _first(w, func(n: NPC) -> bool: return n.role == "adult" and n.job == "laborer")
	check(v != null, "the village has a labourer")
	if v == null:
		return
	v.inv.remove("mallet", v.inv.count("mallet"))
	v.inv.remove("chisel", v.inv.count("chisel"))
	v.inv.add("stone", 3)
	v.inv.add("mallet")
	check(not w.brain._can_make(v, "dress_stone") and w.work_craft(v, "dress_stone", v.inv).result == "tool", "a villager without a chisel cannot either")
	v.inv.add("chisel")
	check(w.brain._can_make(v, "dress_stone"), "with both they can")
	var r2 := w.work_craft(v, "dress_stone", v.inv)
	check(r2.result == "ok" and v.inv.count("stone") == 1 and v.inv.count("building_block") == 2, "the villager's three stone became two blocks and a fragment, the same rule")
	check(int(v.inv.durability.get("chisel", cfull)) == cfull - 1 and int(v.inv.durability.get("mallet", mfull)) == mfull - 1, "and wore both tools a use")
	v.skills["masonry"] = 0
	var low := {"skill": "masonry", "level": 1}
	check(Skills.level(v, str(low.skill)) >= int(low.level), "Masonry 1 is every adult's (the recipe's level)")


## Blocks come only out of stone: two stone make none; with the base conversion nothing is made from nothing and every
## stone is accounted for (used, made as a fragment, or still held). A master's practised hand is the existing Masonry tiers.
func _test_no_free_blocks() -> void:
	var w := _world(2)
	var p := w.player
	p.inv.add("mallet")
	p.inv.add("chisel")
	p.inv.add("stone", 2)
	check(w.work_craft(p, "dress_stone", p.inv).result == "materials" and p.inv.count("building_block") == 0 and p.inv.count("stone") == 2,
			"two stone make no block (a batch is three)")
	# Masonry 1: no tier effect, so every batch is exactly 3 -> 2 + 1
	p.inv.add("stone", 97)
	var made0 := int(w.stats.get("made_building_block", 0))
	var used0 := int(w.stats.get("used_stone", 0))
	var frag0 := int(w.stats.get("made_stone", 0))
	var n := 0
	while p.inv.count("stone") >= 3:
		if w.work_craft(p, "dress_stone", p.inv).result != "ok":
			p.inv.add("mallet")                                   # a worn-out tool replaced
			p.inv.add("chisel")
			continue
		n += 1
	var made := int(w.stats.get("made_building_block", 0)) - made0
	var used := int(w.stats.get("used_stone", 0)) - used0
	var frag := int(w.stats.get("made_stone", 0)) - frag0
	check(p.inv.count("building_block") == 2 * n and made == 2 * n and used == 3 * n and frag == n and p.inv.count("stone") == 99 - used + frag,
			"at Masonry 1 %d batches: %d blocks, %d stone used, %d fragments, %d stone left" % [n, made, used, frag, p.inv.count("stone")])
	check(int(w.stats.get("made_building_block", 0)) == _blocks_everywhere(w), "every block in the world was made from stone")


## STONE-03 (B18-DP-09): skill affects efficiency through the existing Masonry tiers: craft time (levels 3 and 7), the
## practised hand that spares the materials (5, 9) and the extra unit (7, 10), exactly the crafting conventions.
func _test_masonry_tiers() -> void:
	var w := _world(7)
	var p := w.player
	p.inv.add("mallet", 4)
	p.inv.add("chisel", 4)
	var t1 := float(w.player_craft_begin("dress_stone", "").get("secs", 0.0))
	p.inv.add("stone", 3)
	t1 = float(w.player_craft_begin("dress_stone").secs)
	p.skills["masonry"] = Skills.xp_for_level(3)
	var t3 := float(w.player_craft_begin("dress_stone").secs)
	p.skills["masonry"] = Skills.xp_for_level(7)
	var t7 := float(w.player_craft_begin("dress_stone").secs)
	check(t1 > 0.0 and absf(t3 / t1 - 0.85) < 0.001 and absf(t7 / t1 - 0.7) < 0.001, "Masonry 3 and 7 shorten the work to 0.85 and 0.7 of the time (%.2f, %.2f, %.2f)" % [t1, t3, t7])
	# a master over many batches: sometimes the stone is spared, sometimes an extra block; the ledger stays exact
	p.skills["masonry"] = Skills.xp_for_level(10)
	p.inv.remove("stone", p.inv.count("stone"))
	p.inv.add("stone", 300)
	var made0 := int(w.stats.get("made_building_block", 0))
	var used0 := int(w.stats.get("used_stone", 0))
	var frag0 := int(w.stats.get("made_stone", 0))
	var stone0 := p.inv.count("stone")
	var batches := 0
	while batches < 120:
		if w.work_craft(p, "dress_stone", p.inv).result != "ok":
			p.inv.add("mallet")
			p.inv.add("chisel")
			continue
		batches += 1
	var made := int(w.stats.get("made_building_block", 0)) - made0
	var used := int(w.stats.get("used_stone", 0)) - used0
	var frag := int(w.stats.get("made_stone", 0)) - frag0
	check(made > 2 * batches and used < 3 * batches, "a master mason's batches gave more than the base (%d blocks for %d batches, %d stone used of %d)" % [made, batches, used, 3 * batches])
	check(frag == batches and p.inv.count("building_block") == made and p.inv.count("stone") == stone0 - used + frag,
			"and every stone and block is accounted for in the ledger (blocks %d, stone %d)" % [p.inv.count("building_block"), p.inv.count("stone")])
	check(not bool(GameData.recipes.dress_stone.get("exact", false)) and GameData.skills.masonry.tiers["5"].effects.save_chance == 0.15, "dress_stone uses the Masonry tiers as they are")


## STONE-06 (B18-DP-10): the chisel is forged from an iron bar at the anvil, a real item worn by use, bought and sold in the
## ordinary economy; the smith forges one for a buyer who wants it.
func _test_chisel() -> void:
	var w := _world(8)
	var smith := _first(w, func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job == "smith")
	check(smith != null, "the village has a smith")
	if smith == null:
		return
	smith.inv.remove("chisel", smith.inv.count("chisel"))
	smith.inv.add("iron_bar", 3)
	for k in ["iron_ore", "copper_ore", "gold_ore"]:
		smith.inv.remove(k, smith.inv.count(k))                   # nothing to smelt: the forge turns to what a buyer wants
	check(w.brain._can_make(smith, "forge_chisel"), "a smith (Smithing 1) can forge a chisel")
	var bars0 := smith.inv.count("iron_bar")
	var made0 := int(w.stats.get("made_chisel", 0))
	var used0 := int(w.stats.get("used_iron_bar", 0))
	var h0 := int(smith.inv.durability.get("hammer", int(GameData.item("hammer").durability)))
	var r := w.work_craft(smith, "forge_chisel", smith.inv)
	check(r.result == "ok" and smith.inv.count("chisel") == 1 and smith.inv.count("iron_bar") == bars0 - 1, "one iron bar made one chisel")
	check(int(w.stats.get("made_chisel", 0)) - made0 == 1 and int(w.stats.get("used_iron_bar", 0)) - used0 == 1, "counted in the ledger")
	check(smith.inv.has("hammer") == false or int(smith.inv.durability.get("hammer", int(GameData.item("hammer").durability))) < h0 or h0 == 0, "anvil work wore the smith's hammer, as any forging")
	var gm := _first(w, func(n: NPC) -> bool: return w.brain.buy_role(n) == "merchant_goods")
	check(gm != null and int(NPCBrain.BUYS.merchant_goods.chisel) > 0 and NPCBrain.OUTLETS.chisel == ["merchant_goods"] and NPCBrain.MADE_TO_ORDER.has("chisel"),
			"the goods merchant buys chisels the smith has forged for it")
	if gm != null:
		gm.coins = maxi(gm.coins, 100)
		smith.plan.clear()
		check(w.brain._buyer_for(smith, "chisel") == gm, "the smith finds the merchant a buyer of a chisel")
		var c0 := w.total_coins()
		check(w.brain._smith(smith) and smith.plan.any(func(s): return str(s.get("act", "")) == "sell_to" and str(s.args.item) == "chisel"), "and takes it to him (%s)" % smith.doing)
		check(w.total_coins() == c0, "no coin made or lost")
	# it wears out after 150 dressings and is gone; the dresser is then without it
	var p := w.player
	p.inv.remove("chisel", p.inv.count("chisel"))
	p.inv.add("chisel")
	p.inv.add("mallet", 3)
	p.inv.durability["chisel"] = 1
	p.inv.add("stone", 3)
	var broke0 := int(w.stats.get("broke_chisel", 0))
	check(w.work_craft(p, "dress_stone", p.inv).result == "ok" and not p.inv.has("chisel") and int(w.stats.get("broke_chisel", 0)) - broke0 == 1,
			"its last use breaks it: the chisel is consumed")
	check(w.player_craft_refusal("dress_stone") == "You need an iron chisel.", "and the dresser needs another")


## STONE-02: any villager dresses stone for their own use by the player's rules, and a title buys no bypass.
func _test_personal_use() -> void:
	var w := _world(9)
	var f := _first(w, func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job == "farmer" and n.household >= 0)
	check(f != null, "a farmer, not a labourer or any mason")
	if f == null:
		return
	for k in ["mallet", "chisel", "stone", "building_block"]:
		f.inv.remove(k, f.inv.count(k))
	f.inv.add("stone", 3)
	check(not w.brain._can_make(f, "dress_stone"), "without the tools a farmer cannot dress stone, as the player cannot")
	f.inv.add("mallet")
	f.inv.add("chisel")
	check(w.brain._can_make(f, "dress_stone") and w.work_craft(f, "dress_stone", f.inv).result == "ok" and f.inv.count("building_block") == 2 and f.inv.count("stone") == 1,
			"with the player's tools and Masonry a farmer dresses 3 stone into 2 blocks and a fragment")
	# a builder of their own household's house, no blocks on sale: dresses for it (STONE-02)
	for o: NPC in w.npcs:
		o.inv.remove("building_block", o.inv.count("building_block"))
	f.inv.remove("building_block", f.inv.count("building_block"))
	f.inv.add("stone", 2)
	var c := {"load": Inventory.new(), "employer": World.hh_ref(f.household), "worker": f.id}
	f.plan.clear()
	check(w.construction._dress_own(f, c, {"building_block": 6}) and f.plan.any(func(s): return str(s.get("act", "")) == "craft" and str(s.get("args", {}).get("recipe", "")) == "dress_stone"),
			"a villager building their own house sets to dressing the stone they hold (%s)" % f.doing)
	check(not w.construction._dress_own(f, c, {"plank": 4}), "but only for blocks the site still needs")
	# no tools, and none to buy: they do not dress, and buy a tool only when one is for sale and they can pay
	f.inv.remove("chisel", f.inv.count("chisel"))
	for o: NPC in w.npcs:
		o.inv.remove("chisel", o.inv.count("chisel"))
	f.plan.clear()
	check(not w.construction._dress_own(f, c, {"building_block": 6}) and f.plan.is_empty(), "with no chisel anywhere for sale they cannot")
	var gm := _first(w, func(n: NPC) -> bool: return w.brain.buy_role(n) == "merchant_goods")
	if gm != null:
		gm.inv.add("chisel")
		f.coins = 200
		check(w.construction._dress_own(f, c, {"building_block": 6}) and f.plan.any(func(s): return str(s.get("act", "")) == "buy_from" and str(s.args.item) == "chisel"),
				"with one for sale and the coins, they buy it first (%s)" % f.doing)
	# a labourer (a title) is under the same rule: no tool, no dressing
	var lab := _first(w, func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job == "laborer")
	if lab != null:
		lab.inv.remove("chisel", lab.inv.count("chisel"))
		lab.inv.add("stone", 3)
		check(w.work_craft(lab, "dress_stone", lab.inv).result == "tool", "a labourer's title is no bypass: without the chisel the work is refused")


## X18-STONECUT: the stonecutter is a trade of the ordinary economy: it buys stone with its own coins, dresses it and sells
## the blocks to whoever buys; with no buyer it earns nothing; the place opens only when blocks are wanted and stone is for sale.
func _test_stonecutter() -> void:
	var w := _world(10)
	var raws := w.npcs.filter(func(n: NPC) -> bool: return n.alive and w.brain.buy_role(n) == "merchant_raw")
	var raw: NPC = raws[0] if not raws.is_empty() else null
	var sc := _free_adult(w)
	check(raw != null and sc != null, "a raw-goods merchant and an adult who could take up the trade")
	if raw == null or sc == null:
		return
	# the place: closed with no demand, open with demand and stone for sale
	for o: NPC in raws:
		o.inv.add("building_block", int(NPCBrain.BUYS.merchant_raw.building_block))
		o.inv.add("stone", 12)
	check(w.construction.open_need("building_block") == 0 and int(w.brain.job_market().stonecutter.open) == 0, "with no one wanting blocks the market opens no stonecutter's place")
	for o: NPC in raws:
		o.inv.remove("building_block", o.inv.count("building_block"))
		o.coins = maxi(o.coins, 300)
		o.inv.remove("stone", o.inv.count("stone"))
	check(int(w.brain.job_market().stonecutter.open) == 0, "with blocks wanted but no stone to buy, none either")
	raw.inv.add("stone", 12)
	var place: Dictionary = w.brain.job_market().stonecutter
	check(int(place.open) == 1 and str(place.tool) == "chisel" and float(place.pay) > 0.0, "with blocks wanted and stone for sale one place opens, its tool the chisel")
	# take it up through the ordinary job change; tools bought or held
	w.brain._change_job(sc, "stonecutter", "test")
	check(sc.job == "stonecutter" and int(w.brain.job_market().stonecutter.open) == 0 and w.brain.living_in("stonecutter") == 1 and not w.brain.is_essential("stonecutter"),
			"it is taken (the place closes) and is no essential trade handed on by succession")
	check(NPCBrain.KEEPS.stonecutter == ["mallet", "chisel"] and w.brain.buy_role(sc) == "stonecutter" and NPCBrain.BUYS.stonecutter.stone > 0, "it keeps its tools and buys raw stone")
	sc.inv.remove("mallet", sc.inv.count("mallet"))
	sc.inv.remove("chisel", sc.inv.count("chisel"))
	sc.coins = 200
	sc.inv.remove("stone", sc.inv.count("stone"))
	# no tools: no dressing; with the goods merchant's chisel and mallet for sale it buys them with its own coins
	var gm := _first(w, func(n: NPC) -> bool: return w.brain.buy_role(n) == "merchant_goods")
	gm.inv.add("mallet")
	gm.inv.add("chisel")
	sc.plan.clear()
	check(w.brain._stonecutter(sc) and sc.plan.any(func(s): return str(s.get("act", "")) == "buy_from" and str(s.args.item) in ["mallet", "chisel"]), "without its tools it buys them first (%s)" % sc.doing)
	sc.inv.add("mallet")
	sc.inv.add("chisel")
	gm.inv.remove("mallet", gm.inv.count("mallet"))
	gm.inv.remove("chisel", gm.inv.count("chisel"))
	sc.plan.clear()
	check(w.brain._stonecutter(sc) and sc.plan.any(func(s): return str(s.get("act", "")) == "buy_from" and str(s.args.item) == "stone" and int(s.args.qty) == 3),
			"with them it buys a batch of stone from the raw-goods merchant (%s)" % sc.doing)
	# a day-by-day run: stone bought, dressed, blocks sold; coins and goods conserved, and the trade earns
	var blocks0 := _blocks_everywhere(w)
	var made0 := int(w.stats.get("made_building_block", 0))
	var built0 := int(w.stats.get("used_building_building_block", 0))
	var c_sc0 := sc.coins
	for k in 1440 * 2:
		w.update(0.5)
	var made := int(w.stats.get("made_building_block", 0)) - made0
	check(made > 0, "the stonecutter dressed %d blocks (bought stone, not free)" % made)
	check(sc.coins != c_sc0, "its coins moved: it paid for stone and was paid for blocks (%d -> %d)" % [c_sc0, sc.coins])
	check(_blocks_everywhere(w) - blocks0 == made - (int(w.stats.get("used_building_building_block", 0)) - built0), "every block counted: made = held + built in")
	# no customer: nobody wants blocks, none sold, nothing guaranteed, no hidden rescue
	var w2 := _world(11)
	var raws2 := w2.npcs.filter(func(n: NPC) -> bool: return n.alive and w2.brain.buy_role(n) == "merchant_raw")
	for o: NPC in raws2:
		o.inv.add("building_block", int(NPCBrain.BUYS.merchant_raw.building_block))
		o.inv.add("stone", 12)
	var sc2 := _free_adult(w2)
	w2.brain._change_job(sc2, "stonecutter", "test")
	sc2.inv.add("mallet")
	sc2.inv.add("chisel")
	sc2.coins = 50
	var c2 := sc2.coins
	var made2 := int(w2.stats.get("made_building_block", 0))
	sc2.plan.clear()
	check(not w2.brain._mason(sc2) and w2.brain._stonecutter(sc2) and sc2.doing.begins_with("waiting"), "with no customer it dresses nothing and waits (%s)" % sc2.doing)
	check(sc2.coins == c2 and int(w2.stats.get("made_building_block", 0)) == made2, "and earns and spends nothing")


## An adult with no trade or a manor hand, free to take up the stonecutter's.
func _free_adult(w: World) -> NPC:
	var n := _first(w, func(o: NPC) -> bool: return o.role == "adult" and o.job == "")
	if n == null:
		n = _first(w, func(o: NPC) -> bool: return o.role == "adult" and o.job in ["manor_hand", "laborer"])
	return n


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
	lab.inv.add("chisel")
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
		lab2.inv.add("chisel")
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


## A save from before the chisel (a pack with a worn mallet, blocks and stone, no chisel): nothing is lost or reinterpreted;
## the old blocks and mallets stay what they were; dressing now asks for the chisel; a worn chisel is saved as any tool.
func _test_old_save() -> void:
	var w := _world(12)
	var p := w.player
	p.inv.remove("chisel", p.inv.count("chisel"))
	p.inv.add("mallet")
	p.inv.durability["mallet"] = 77
	p.inv.add("building_block", 5)
	p.inv.add("stone", 4)
	var lab := _first(w, func(n: NPC) -> bool: return n.role == "adult" and n.job == "laborer")
	lab.inv.add("mallet")
	lab.inv.add("building_block", 3)
	var g0 := Census.goods(w)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var g1 := Census.goods(w2)
	check(g1 == g0 and int(g1.get("chisel", 0)) == int(g0.get("chisel", 0)), "every item of the older save is there after loading, no chisel made from nothing")
	var p2 := w2.player
	check(p2.inv.count("building_block") == 5 and p2.inv.count("stone") == 4 and int(p2.inv.durability.get("mallet", 0)) == 77 and not p2.inv.has("chisel"),
			"the player's blocks, stone and worn mallet are as they were")
	check(w2.player_craft_refusal("dress_stone") == "You need an iron chisel." and w2.work_craft(p2, "dress_stone", p2.inv).result == "tool" and p2.inv.count("stone") == 4,
			"dressing now needs the chisel, and until it is had nothing changes")
	p2.inv.add("chisel")
	check(w2.work_craft(p2, "dress_stone", p2.inv).result == "ok" and p2.inv.count("building_block") == 7 and p2.inv.count("stone") == 2 and int(p2.inv.durability.get("mallet", 0)) == 76,
			"with one the work is the new rule on the old stock (the mallet's wear goes on from 77)")
	var d3: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d3)
	check(int(w3.player.inv.durability.get("chisel", 0)) == int(GameData.item("chisel").durability) - 1 and w3.player.inv.count("building_block") == 7,
			"the worn chisel and the new blocks survive another save")
	check(int(d3.save_version) == World.SAVE_VERSION, "no new save version")


## The same seed, the same course: two worlds with a labourer set to dress stone end alike.
func _test_determinism() -> void:
	var out := []
	for i in 2:
		var w := _world(6)
		for n: NPC in w.npcs:
			if n.alive and n.role == "adult" and n.job == "laborer":
				n.inv.add("mallet")
				n.inv.add("chisel")
		for k in 960:
			w.update(0.5)
		out.append([int(w.stats.get("made_building_block", 0)), _blocks_everywhere(w), int(w.stats.get("used_stone", 0)), w.total_coins(), Census.goods(w).get("stone", 0)])
	check(out[0] == out[1], "two runs of one seed: the same blocks made, held and stone used (%s)" % str(out[0]))
	check(int(out[0][0]) > 0, "and blocks were made to the merchant's demand (%d)" % int(out[0][0]))
