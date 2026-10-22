extends SceneTree
## PAR-01 (owner OD-18.1, 2026-10-20: "All villagers must develop skills exactly as the player does"): villagers keep
## skills as the player does, by the same curve, gates, tier effects and experience, saved with them; a grown villager
## brings the experience of their working years (Skills.start_xp), and an older save's villagers are given it on load.
## Run:
##   godot --headless --path game --script res://tests/parity_test.gd

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
	test_starting_experience()
	test_careers_and_incidental_experience()
	test_mining_gate_and_xp()
	test_crafting_gate_and_xp()
	test_felling()
	test_combat()
	test_trading()
	test_save_and_migration()
	test_eleven_recipes()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func first(w: World, job: String) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.job == job:
			return n
	return null


## PAR-01A: a plausible, deterministic history in their trade, given only at world creation; not age alone, not mastery
## for all, nothing for children, the player or skills outside their trade.
func test_starting_experience() -> void:
	var c: Dictionary = GameData.b("skill_start")
	var cap := roundi(float(c.max_tenure_years) * float(c.xp_per_year))
	check(int(Skills.start_xp("smith", 70.0, 1.0).smithing) == cap and Skills.level_of(cap) < Skills.max_level(), "even a lifelong smith starts below the top level (%d xp, level %d)" % [cap, Skills.level_of(cap)])
	check(int(Skills.start_xp("smith", float(c.from_age) + 2.0, 0.0).smithing) < Skills.xp_for_level(3), "a young apprentice smith starts below Smithing 3 (no iron armour yet)")
	check(Skills.start_xp("smith", float(c.from_age) - 2.0, 1.0).get("smithing", -1) == 0 and Skills.start_xp("farmer", 50.0, 1.0).is_empty(), "no working years, no experience; a trade without a skill brings none")
	check(Skills.start_xp("farmer", 50.0, 1.0).get("smithing", 0) == 0 and Skills.start_xp("smith", 50.0, 1.0).keys() == ["smithing"], "experience only in the person's own trade: a 50-year-old farmer has no Smithing")
	var w := new_world()
	var smith := first(w, "smith")
	check(smith.skills == Skills.start_xp("smith", Life.npc_age(w, smith), Skills.tenure_share(w, smith)), "a new world's smith has their history in the trade (%s)" % str(smith.skills))
	var lv := {}
	for n: NPC in w.npcs:
		for sk in n.skills:
			lv[Skills.level(n, sk)] = true
	check(lv.size() >= 3 and not lv.has(Skills.max_level()), "starting levels are spread (%s), and nobody starts at the top" % str(lv.keys()))
	check(w.npcs.filter(func(n): return n.role == "child").all(func(n): return n.skills.is_empty()), "children start with none")
	check(w.player.skills.is_empty(), "the player starts with none, as before")
	var w2 := new_world()
	var same := true
	for i in w.npcs.size():
		same = same and w.npcs[i].skills == w2.npcs[i].skills
	check(same, "the same seed gives the same skills (deterministic)")


## PAR-01B and PAR-01C: a new job brings no experience and takes none away; experience comes from the work done,
## whatever the job; a newcomer starts with none.
func test_careers_and_incidental_experience() -> void:
	var w := new_world()
	var smith := first(w, "smith")
	var before: Dictionary = smith.skills.duplicate()
	w.brain._change_job(smith, "farmer", "test")
	check(smith.skills == before and int(smith.skills.get("smithing", 0)) > 0, "a smith turned farmer keeps their Smithing, and gains nothing for the new job")
	w.brain._change_job(smith, "smith", "test")
	check(smith.skills == before, "back at the forge, the Smithing they had is all there")
	var farmer := first(w, "farmer")
	var f0: Dictionary = farmer.skills.duplicate()
	w.brain._change_job(farmer, "smith", "test")
	check(farmer.skills == f0 and int(farmer.skills.get("smithing", 0)) == 0, "a farmer turned smith starts at 0 Smithing")
	check(not w.brain._can_make(farmer, "forge_iron_armor") and not w.brain._do_recipe(farmer, "forge_iron_armor"), "and cannot forge iron armour, however much the village needs it")
	# what they actually do teaches them, whatever their job
	var hh := first(w, "miner")
	var m0 := int(hh.skills.get("woodcutting", 0))
	w.work_felled(hh, 4, hh.inv)
	check(int(hh.skills.get("woodcutting", 0)) - m0 == 12, "a miner who fells a tree for the household earns the woodcutter's 12 xp")
	var cook0 := int(farmer.skills.get("cooking", 0))
	var pantry := Inventory.new()
	pantry.add("wheat", 2)
	w.work_craft(farmer, "cook_pottage", pantry)
	check(int(farmer.skills.get("cooking", 0)) - cook0 == int(GameData.recipes.cook_pottage.xp), "cooking at home earns Cooking")
	# the same work, the same experience, for the player and a villager
	w.player.skills = {}
	var v := first(w, "merchant")
	v.skills = {}
	w.work_mine(w.player, {"x": 0, "y": 0, "ore": "stone", "amount": 1}, w.player.inv)
	w.work_mine(v, {"x": 0, "y": 0, "ore": "stone", "amount": 1}, v.inv)
	check(w.player.skills == v.skills and int(v.skills.mining) == 8, "one swing earns the player and a villager the same 8 Mining xp")
	# a newcomer comes with nothing learned here
	var dead := first(w, "woodcutter")
	w.kill(dead, "test")
	var vac := {"job": "woodcutter", "who": dead.name, "household": dead.household, "home": dead.home, "workplace": dead.workplace}
	var nc: NPC = w.brain._newcomer_for(vac)
	check(nc != null and nc.skills.is_empty(), "a newcomer starts with no experience")


func test_mining_gate_and_xp() -> void:
	var w := new_world()
	var miner := first(w, "miner")
	var gold := {"x": 0, "y": 0, "ore": "gold_ore", "amount": 5}
	var stone := {"x": 0, "y": 0, "ore": "stone", "amount": 5}
	miner.skills = {}
	w.player.skills = {}
	check(w.work_mine(miner, gold, miner.inv).result == "gold" and w.work_mine(w.player, gold, w.player.inv).result == "gold" and int(gold.amount) == 5, "below Mining 3 neither a miner nor the player can take gold")
	check(not w.brain._can_mine(miner, "gold_ore") and w.brain._can_mine(miner, "iron_ore"), "a miner below Mining 3 does not set out for a gold seam")
	var r := w.work_mine(miner, stone, miner.inv)
	check(r.result == "ok" and int(miner.skills.get("mining", 0)) == 8 * int(r.n), "a swing earns a miner the player's 8 xp an ore (%s)" % str(miner.skills))
	miner.skills = {"mining": Skills.xp_for_level(3)}
	w.player.skills = {"mining": Skills.xp_for_level(3)}
	check(w.work_mine(miner, gold, miner.inv).result == "ok" and w.work_mine(w.player, gold, w.player.inv).result == "ok", "at Mining 3 both can")


func test_crafting_gate_and_xp() -> void:
	var w := new_world()
	var smith := first(w, "smith")
	var rec: Dictionary = GameData.recipes["forge_iron_armor"]
	smith.skills = {"smithing": Skills.xp_for_level(int(rec.level) - 1)}
	for id in rec["in"]:
		smith.inv.add(id, int(rec["in"][id]))
	check(w.work_craft(smith, "forge_iron_armor", smith.inv).result == "level", "a smith below Smithing %d cannot forge iron armour, as the player cannot" % int(rec.level))
	check(not w.brain._do_recipe(smith, "forge_iron_armor"), "nor sets out to")
	smith.skills = {"smithing": Skills.xp_for_level(int(rec.level))}
	var made0 := float(w.stats.get("made_iron_armor", 0.0))
	var x0 := int(smith.skills.smithing)
	var res := w.work_craft(smith, "forge_iron_armor", smith.inv)
	check(res.result == "ok" and smith.inv.has("iron_armor") and int(smith.skills.smithing) - x0 == int(rec.xp), "at the level they can, and earn the recipe's %d xp" % int(rec.xp))
	check(float(w.stats.get("made_iron_armor", 0.0)) - made0 >= 1.0, "what they make is counted (made_)")
	# the same skill time for both
	var t := Skills.value(smith, "smithing", "craft_time", 1.0)
	w.player.skills = smith.skills.duplicate()
	check(t == Skills.value(w.player, "smithing", "craft_time", 1.0), "the same level gives the same craft time")


func test_felling() -> void:
	var w := new_world()
	var wc := first(w, "woodcutter")
	wc.skills = {"woodcutting": Skills.xp_for_level(6)}
	var bonus := int(Skills.value(wc, "woodcutting", "log_bonus"))
	check(bonus == 2, "Woodcutting 6 gives two extra logs a tree")
	var logs0 := wc.inv.count("log")
	var f := w.work_felled(wc, 4 + bonus, wc.inv)
	check(wc.inv.count("log") - logs0 == 4 + bonus and int(wc.skills.woodcutting) == Skills.xp_for_level(6) + 12, "a felled tree's logs and the player's 12 xp")
	check(f.has("broke"), "the axe wears by the same rule")


func test_combat() -> void:
	var w := new_world()
	var g := first(w, "guard")
	var v := first(w, "farmer")
	v.skills = {}
	v.armor = 0.0
	v.hp = 30.0
	w.harm_npc(v, 10.0)
	check(is_equal_approx(v.hp, 20.0), "an untrained villager takes a blow in full")
	v.hp = 30.0
	v.skills = {"combat": Skills.xp_for_level(10)}
	w.harm_npc(v, 10.0)
	check(is_equal_approx(v.hp, 30.0 - 10.0 * Skills.value(v, "combat", "damage_taken", 1.0)), "Combat 10 takes less, as the player's damage_taken")
	g.skills = {}
	var plain := w.npc_blow(g)
	check(is_equal_approx(plain, g.damage), "an untrained guard strikes at their own damage (no crit below Combat 5)")
	g.skills = {"combat": Skills.xp_for_level(8)}
	var b := w.npc_blow(g)
	check(b >= g.damage * 1.5 - 0.001, "Combat 8 strikes harder (x1.5), as the player's damage_mult (%.1f)" % b)


func test_trading() -> void:
	var w := new_world()
	var m := first(w, "merchant")
	var f := first(w, "farmer")
	m.skills = {}
	f.skills = {}
	check(w.deal_price(100, f, m) == 100, "two untrained traders deal at the plain price")
	m.skills = {"trading": Skills.xp_for_level(10)}
	check(w.deal_price(100, f, m) == 120 and w.deal_price(100, m, f) == 80, "a master trader gets 20%% better prices either way, as the player does")
	w.player.skills = {"trading": Skills.xp_for_level(10)}
	check(w.deal_price(100, w.player, m) == 100, "two masters cancel out")
	m.skills = {}
	w.player.skills = {}
	m.inv.add("wheat", 5)
	var q0: int = w.player_quote(m, "wheat", 1, true)[0]
	m.skills = {"trading": Skills.xp_for_level(10)}
	var q1: int = w.player_quote(m, "wheat", 1, true)[0]
	check(q1 > q0, "a master trader asks the player more, by the same rule (%d -> %d)" % [q0, q1])
	m.skills = {}
	var x0 := int(f.skills.get("trading", 0))
	w.deal_xp(f, m, 25)
	check(int(f.skills.get("trading", 0)) - x0 == Skills.trade_xp(25) and int(m.skills.get("trading", 0)) == Skills.trade_xp(25), "a villagers' deal earns both sides the player's Trading xp")


func test_save_and_migration() -> void:
	var w := new_world()
	var smith := first(w, "smith")
	smith.skills = {"smithing": 1234, "mining": 56}
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w2.npc(smith.id).skills == {"smithing": 1234, "mining": 56}, "villagers' skills are saved and loaded")
	# a save from before the skills (save_version 14): the villagers are given their working years on load
	var old := w.to_dict()
	old.save_version = 14
	old.format = "mml-save/14"
	for nd in old.npcs:
		nd.erase("skills")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(old)))
	var s3 := w3.npc(smith.id)
	check(s3.skills == Skills.start_xp("smith", Life.npc_age(w3, s3), Skills.tenure_share(w3, s3)), "an older save's smith is given, once, a history in the trade (%s)" % str(s3.skills))
	# the migration happens once: saved again it is a 15 save, and loading that does not seed anyone again
	var lone: NPC = w3.npcs.filter(func(n): return n.alive and n.role == "adult" and not n.skills.is_empty())[0]
	lone.skills = {}                          # (someone who, by now, has no recorded experience)
	s3.skills["smithing"] = int(s3.skills.smithing) + 7     # and experience earned since the migration
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w3.to_dict())))
	check(w4.npc(lone.id).skills.is_empty() and w4.npc(s3.id).skills == s3.skills, "a migrated save, saved and loaded again, is not re-seeded and keeps what was earned")
	check(w3.npcs.filter(func(n): return n.role == "child").all(func(n): return n.skills.is_empty()), "an older save's children are given none")


## PAR-04 (owner OD-18.4): every recipe the player can make has a villager who makes it, when they have the skill, the
## materials and a buyer who wants it; never merely because they can.
func test_eleven_recipes() -> void:
	var w := new_world()
	var smith := first(w, "smith")
	var goods: NPC = w.npcs.filter(func(o): return o.alive and w.brain.buy_role(o) == "merchant_goods")[0]
	var all_goods: Array = w.npcs.filter(func(o): return o.alive and w.brain.buy_role(o) == "merchant_goods")
	var stock_all := func(id: String, full: bool) -> void:       # every goods merchant has all it wants of id, or none
		for g: NPC in all_goods:
			g.inv.items.erase(id)
			if full:
				g.inv.add(id, int(NPCBrain.BUYS.merchant_goods[id]))
	var free_stations := func() -> void:
		for st in w.stations:
			w.stations[st].users.clear()
	# the smith: a gold bar for a buyer, at Smithing 3
	smith.inv.items.clear()
	smith.plan.clear()
	smith.inv.add("gold_ore", 2)
	smith.inv.add("coal", 1)
	smith.skills = {"smithing": Skills.xp_for_level(2)}
	check(not w.brain._smith(smith) or not str(smith.plan[-1].get("args", {}).get("recipe", "")) == "smelt_gold", "below Smithing 3 the smith does not smelt gold")
	smith.plan.clear()
	smith.skills = {"smithing": Skills.xp_for_level(3)}
	check(w.brain._smith(smith) and str(smith.plan[-1].get("args", {}).get("recipe", "")) == "smelt_gold", "at Smithing 3, with a buyer for the bar, the smith smelts gold")
	# the smith: a copper ring only while someone wants one
	for rid in [["forge_copper_ring", {"copper_bar": 1}, "copper_ring"], ["forge_iron_helmet", {"iron_bar": 2, "leather": 1}, "iron_helmet"], ["forge_amulet", {"copper_bar": 1, "leather": 1}, "amulet"], ["forge_gold_ring", {"gold_bar": 1}, "gold_ring"]]:
		smith.inv.items.clear()
		smith.plan.clear()
		for id in rid[1]:
			smith.inv.add(id, int(rid[1][id]))
		stock_all.call(rid[2], false)
		free_stations.call()
		var made: bool = w.brain._smith(smith) and str(smith.plan[-1].get("args", {}).get("recipe", "")) == rid[0]
		stock_all.call(rid[2], true)                 # every goods merchant has all it wants
		free_stations.call()
		smith.plan.clear()
		var not_made: bool = not (w.brain._smith(smith) and str(smith.plan[-1].get("args", {}).get("recipe", "")) == rid[0])
		stock_all.call(rid[2], false)
		check(made and not_made, "the smith forges a %s while the goods merchant wants one, and not once it has enough" % rid[2])
	# the tanner: a leather cap and leather armour for a buyer
	var tanner := first(w, "tanner")
	for rid in [["leather_cap", 2], ["leather_armor", 4]]:
		tanner.inv.items.clear()
		tanner.plan.clear()
		tanner.inv.add("leather", int(rid[1]))
		stock_all.call("leather_cap", rid[0] != "leather_cap")      # testing the armour: the caps are wanted no more
		stock_all.call(rid[0], false)
		free_stations.call()
		check(w.brain._tanner(tanner) and str(tanner.plan[-1].get("args", {}).get("recipe", "")) == rid[0], "the tanner makes %s for the goods merchant" % rid[0])
	# the carpenter: a plough for a buyer
	var carp := first(w, "carpenter")
	carp.inv.items.clear()
	carp.plan.clear()
	carp.inv.add("plank", 4)
	carp.inv.add("iron_bar", 2)
	stock_all.call("plough", false)
	free_stations.call()
	check(w.brain._carpenter_goods(carp) and str(carp.plan[-1].get("args", {}).get("recipe", "")) == "craft_plough", "the carpenter makes a plough for the goods merchant")
	# the cook: flatbread when there is no egg and the tavern wants bread
	var cook := first(w, "cook")
	cook.inv.items.clear()
	cook.plan.clear()
	cook.inv.add("wheat", 3)
	for o: NPC in w.npcs:
		if o.job == "tavernkeeper":
			o.inv.items.erase("bread")
	free_stations.call()
	check(w.brain._cook(cook) and str(cook.plan[-1].get("args", {}).get("recipe", "")) == "knead_flatbread", "with no egg, the cook kneads flatbread for the tavern")
	# the sage: the herbal tonic, and the strong tonic at Healing 3
	var sage := w.npc(w.sage_id)
	sage.inv.items.clear()
	sage.plan.clear()
	sage.inv.add("herbal_poultice", 8)
	sage.inv.add("healing_tonic", 6)
	sage.inv.add("ale", 1)
	sage.skills = {"cooking": Skills.xp_for_level(3), "healing": Skills.xp_for_level(3)}
	free_stations.call()
	check(w.brain._plan_job(sage) and str(sage.plan[-1].get("args", {}).get("recipe", "")) == "brew_strong_tonic", "at Healing 3 the sage brews the strong tonic")
	sage.plan.clear()
	sage.inv.items.erase("ale")
	sage.inv.add("flower", 3)
	free_stations.call()
	check(w.brain._plan_job(sage) and str(sage.plan[-1].get("args", {}).get("recipe", "")) == "brew_tonic", "and keeps a few herbal tonics")
	# made in full through the one craft function: inputs out, outputs in, counted
	carp.skills = {}
	var r := w.work_craft(carp, "craft_plough", carp.inv)
	check(r.result == "ok" and carp.inv.has("plough") and not carp.inv.has("iron_bar"), "a villager's plough uses its inputs and is made by the same function as the player's")
