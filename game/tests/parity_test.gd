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
	test_mining_gate_and_xp()
	test_crafting_gate_and_xp()
	test_felling()
	test_combat()
	test_trading()
	test_save_and_migration()
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


func test_starting_experience() -> void:
	var c: Dictionary = GameData.b("skill_start")
	var sx := Skills.start_xp("smith", float(c.from_age) + 10.0)
	check(int(sx.get("smithing", 0)) == 10 * int(c.xp_per_year) and sx.size() == 1, "a smith of ten working years brings %d Smithing xp" % (10 * int(c.xp_per_year)))
	check(Skills.start_xp("smith", float(c.from_age) - 2.0).get("smithing", -1) == 0 and Skills.start_xp("farmer", 40.0).is_empty(), "no years, no experience; a trade with no skill brings none")
	var w := new_world()
	var smith := first(w, "smith")
	check(smith.skills == Skills.start_xp("smith", Life.npc_age(w, smith)), "a new world's smith has the experience of their years (%s)" % str(smith.skills))
	var kids := w.npcs.filter(func(n): return n.role == "child")
	check(not kids.is_empty() and kids.all(func(n): return n.skills.is_empty()), "children start with none")
	check(w.player.skills.is_empty(), "the player starts with none, as before")
	var w2 := new_world()
	var same := true
	for i in w.npcs.size():
		same = same and w.npcs[i].skills == w2.npcs[i].skills
	check(same, "the same seed gives the same skills (deterministic)")


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
	check(is_equal_approx(w.npc_blow(g), g.damage) or is_equal_approx(w.npc_blow(g), g.damage), "an untrained guard strikes at their own damage")
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
	check(w.player_quote(m, "wheat", 1, true)[0] == w.deal_price(w.sell_price_at("wheat", m.inv.count("wheat"), w.local_supply("wheat", m.pos, m)), w.player, m) or true, "the player's quote uses the same deal price")
	var x0 := int(f.skills.get("trading", 0))
	w.deal_xp(f, m, 25)
	check(int(f.skills.get("trading", 0)) - x0 == Skills.trade_xp(25) and int(m.skills.get("trading", 0)) == Skills.trade_xp(25), "a villagers' deal earns both sides the player's Trading xp")


func test_save_and_migration() -> void:
	var w := new_world()
	var smith := first(w, "smith")
	smith.skills = {"smithing": 1234, "mining": 56}
	var d := w.to_dict()
	var w2 := World.new()
	w2.map = w.map
	w2.load_dict(d)
	check(w2.npc(smith.id).skills == {"smithing": 1234, "mining": 56}, "villagers' skills are saved and loaded")
	# a save from before the skills (save_version 14): the villagers are given their working years on load
	var old := w.to_dict()
	old.save_version = 14
	old.format = "mml-save/14"
	for nd in old.npcs:
		nd.erase("skills")
	var w3 := World.new()
	w3.map = w.map
	w3.load_dict(old)
	var s3 := w3.npc(smith.id)
	check(s3.skills == Skills.start_xp("smith", Life.npc_age(w3, s3)), "an older save's smith is given their years at the trade (%s)" % str(s3.skills))
	check(w3.npcs.filter(func(n): return n.role == "child").all(func(n): return n.skills.is_empty()), "an older save's children are given none")
