extends SceneTree
## Skills (PL2-005): the xp curve, that every tier effect in skills.json is read by game code and
## changes an outcome, that early play stays in the first tiers, that saves keep their xp, and that
## the wiki prints the tiers from the data. Run:
##   godot --headless --path game --script res://tests/skills_test.gd

var failures := 0


func check(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_curve()
	test_effects_are_wired()
	test_outcomes()
	test_early_play()
	test_saves()
	test_text_and_wiki()
	print("skills_test: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)


func test_curve() -> void:
	var starts := [0, 100, 350, 800, 1500, 2500, 3850, 5600, 7800, 10500]
	var ok := true
	for i in starts.size():
		ok = ok and Skills.xp_for_level(i + 1) == starts[i]
	check(ok and Skills.max_level() == 10, "the xp each level starts at: %s" % [starts])
	check(Skills.level_of(99) == 1 and Skills.level_of(100) == 2 and Skills.level_of(349) == 2 and Skills.level_of(350) == 3, "level boundaries 99/100 and 349/350")
	check(Skills.level_of(10499) == 9 and Skills.level_of(10500) == 10 and Skills.level_of(999999) == 10, "level 10 is the top")
	check(Skills.progress(120) == Vector2i(20, 250) and Skills.progress(20000).y == 0, "progress into a level; none needed at the top")
	var p := PlayerState.new()
	check(p.raise_to("mining", 4) and p.level("mining") == 4 and p.xp_into_level("mining").x == 0 and not p.raise_to("mining", 3), "teaching raises to the start of a level, never down")
	check(Skills.rank(1) == "Novice" and Skills.rank(4) == "Apprentice" and Skills.rank(10) == "Master", "ranks by level")


func _source(path: String) -> String:
	return FileAccess.get_file_as_string("res://" + path)


## Every effect key in the data is declared, printed and read by the named script; every skill used.
func test_effects_are_wired() -> void:
	var used := {}
	var bad := []
	for sk in GameData.skills:
		for l in Skills.tier_levels(sk):
			for key in GameData.skills[sk].tiers[str(l)].get("effects", {}):
				used[key] = true
				if not Skills.EFFECTS.has(key):
					bad.append("%s.%s undeclared" % [sk, key])
					continue
				var src := _source(Skills.EFFECTS[key].code)
				if not ('"%s"' % key) in src:
					bad.append("%s is not read in %s" % [key, Skills.EFFECTS[key].code])
				if Skills.describe(key, float(GameData.skills[sk].tiers[str(l)].effects[key])).contains("%s"):
					bad.append("%s prints badly" % key)
	check(bad.is_empty(), "every perk key is declared and read by its script: %s" % [bad])
	var unused := []
	for key in Skills.EFFECTS:
		if not used.has(key):
			unused.append(key)
	check(unused.is_empty(), "no declared effect is unused: %s" % [unused])
	var recipes_ok := true
	for r in GameData.recipes.values():
		recipes_ok = recipes_ok and GameData.skills.has(str(r.skill)) and int(r.level) <= Skills.max_level()
	check(recipes_ok, "every recipe's skill exists and its level is within the tiers")
	# a tier's effect changes the number the game reads (not just the text)
	var flat := []
	for sk in GameData.skills:
		for l in Skills.tier_levels(sk):
			for key in GameData.skills[sk].tiers[str(l)].get("effects", {}):
				if Skills.value_at(l, sk, key, -1.0) == Skills.value_at(l - 1, sk, key, -1.0):
					flat.append("%s.%s@%d" % [sk, key, l])
	check(flat.is_empty(), "each tier effect moves the value the code reads: %s" % [flat])


func _player_at(skill: String, lv: int) -> PlayerState:
	var p := PlayerState.new()
	p.skills[skill] = Skills.xp_for_level(lv)
	return p


func test_outcomes() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	# trading: prices
	var base_buy := 0.0
	var seen := []
	for lv in [1, 2, 5, 10]:
		w.player = _player_at("trading", lv)
		seen.append([w.player_price_factor(true), w.player_price_factor(false)])
	check(is_equal_approx(seen[0][0], 1.0) and seen[1][0] < 1.0 and seen[2][0] < seen[1][0] and seen[3][0] < seen[2][0] and seen[3][1] > seen[2][1] and is_equal_approx(seen[3][1], 1.2), "trading: buying gets cheaper and selling dearer with each tier (%s)" % [seen])
	# combat: damage and damage taken
	w.player = _player_at("combat", 1)
	w.player.inv.add("iron_sword")
	w.player.weapon = "iron_sword"
	var d1 := w.player.damage()
	w.player = _player_at("combat", 10)
	w.player.inv.add("iron_sword")
	w.player.weapon = "iron_sword"
	check(w.player.damage() > d1 * 1.6, "combat: damage %.1f -> %.1f" % [d1, w.player.damage()])
	w.player.hp = 100.0
	w.player.armor = ""
	w.damage_player(10.0, "test")
	check(is_equal_approx(w.player.hp, 93.0), "combat: a level 10 fighter takes 30%% less damage (hp %.1f)" % w.player.hp)
	# stealth
	w.player = _player_at("stealth", 1)
	var c1 := w.pickpocket_chance()
	w.player = _player_at("stealth", 5)
	var c5 := w.pickpocket_chance()
	w.player = _player_at("stealth", 10)
	var c10 := w.pickpocket_chance()
	check(c1 < c5 and c5 < c10 and c10 <= float(GameData.b("pickpocket_chance_max")) + 0.0001, "stealth: pickpocket chance %.2f < %.2f < %.2f" % [c1, c5, c10])
	check(Skills.value(_player_at("stealth", 10), "stealth", "guard_radius", 1.0) < Skills.value(_player_at("stealth", 5), "stealth", "guard_radius", 1.0), "stealth: a caught try is seen over a shorter distance")
	# woodcutting: sapling chance and log yield
	w.player = _player_at("woodcutting", 10)
	var t := {"species": "oak_summer"}
	var n0 := 0
	var n1 := 0
	for i in 600:
		n0 += int(w.sapling_drop(t).values()[0])
		n1 += int(w.sapling_drop(t, Skills.value(w.player, "woodcutting", "sapling_bonus")).values()[0])
	check(n1 > n0, "woodcutting: the sapling bonus gives more saplings (%d -> %d from 600 trees)" % [n0, n1])
	check(int(Skills.value(w.player, "woodcutting", "log_bonus")) == 3 and int(Skills.value(_player_at("woodcutting", 1), "woodcutting", "log_bonus")) == 0, "woodcutting: +3 logs a tree at 10, none at 1")
	# mining: gold needs the tier, speed and wear
	check(not Skills.has(_player_at("mining", 2), "mining", "gold") and Skills.has(_player_at("mining", 3), "mining", "gold"), "mining: gold ore opens at level 3")
	check(Skills.value(_player_at("mining", 9), "mining", "mine_time", 1.0) < 0.7 and Skills.value(_player_at("mining", 10), "mining", "tool_wear_save") > 0.8, "mining: faster swings and rare tool wear at the top")
	# fireball
	var f1 := Skills.value(_player_at("magic", 1), "magic", "fireball_cooldown", float(GameData.b("fireball_cooldown")))
	var f10 := Skills.value(_player_at("magic", 10), "magic", "fireball_cooldown", 6.0)
	check(f1 == float(GameData.b("fireball_cooldown")) and f10 < f1 / 2.0, "magic: fireball cooldown %.1f -> %.1f" % [f1, f10])
	# crafting: gear is never doubled; a station's work is quicker
	check(Skills.is_gear("iron_sword") and Skills.is_gear("pickaxe") and not Skills.is_gear("iron_bar"), "crafting: a bonus unit applies to materials and food, not gear")
	check(Skills.value(_player_at("smithing", 10), "smithing", "craft_time", 1.0) <= 0.5 and Skills.value(_player_at("cooking", 10), "cooking", "bonus_chance") > 0.2, "smithing and cooking: quicker, wasteful-less work at the top")
	w.dispose()


func test_early_play() -> void:
	# a first stretch of work: the numbers per action are those in main.gd (mining 8 xp an ore, chopping
	# 12 a blow and 4 blows a tree, trading 2 + coins / 5, recipes' own xp)
	check(Skills.level_of(30 * 8) <= 2, "mining 30 ore (240 xp) is level %d, in the first tiers" % Skills.level_of(240))
	var trees: int = 5
	var chops: int = int(Trees.cfg().chops)
	check(Skills.level_of(trees * chops * 12) <= 2 and Skills.level_of(trees * chops * 12) >= 2, "felling 5 trees is level %d: a level early, no more" % Skills.level_of(trees * chops * 12))
	check(Skills.level_of(10 * int(GameData.recipes["smelt_iron"].xp)) == 2, "10 iron smelts reach smithing level 2")
	check(Skills.level_of(100 * 8) < 5, "even 100 ore (800 xp) is not past level 4: the middle tiers need real play (level %d)" % Skills.level_of(800))
	check(Skills.trade_xp(1) == 2 and Skills.trade_xp(40) == 10 and Skills.trade_xp(5000) == 30, "trade xp grows with the deal, capped")


func test_saves() -> void:
	var p := PlayerState.new()
	p.skills = {"mining": 777, "woodcutting": 45, "magic": 100}
	var q := PlayerState.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check(q.skills == p.skills and int(q.skills.mining) == 777, "xp keys and values survive a save and load unchanged")
	# an old save: 500 mining xp was level 3 on the old curve; it is kept, and is level 3 here too
	var old := PlayerState.new()
	old.skills = {"mining": 500, "stealth": 1000}
	check(int(old.skills.mining) == 500 and old.level("mining") == 3 and old.level("stealth") == 4, "old xp is kept; levels follow the new curve (500 -> 3, 1000 -> 4)")
	check(old.gain("mining", 1) == 0 and int(old.skills.mining) == 501, "xp adds to what was saved")


func test_text_and_wiki() -> void:
	var line := Skills.tier_text("mining", 3)
	check(line.contains("Mine gold ore"), "tier text names the unlock: %s" % line)
	check(Skills.tier_text("mining", 2).contains("25%"), "tier text prints the number from the data: %s" % Skills.tier_text("mining", 2))
	check(Skills.tier_text("tanning", 2).contains("leather armour") or Skills.tier_text("tanning", 2).contains("leather armor"), "recipe unlocks are listed by level: %s" % Skills.tier_text("tanning", 2))
	check(Skills.tier_text("stealth", 2).contains("%"), "stealth prints the resulting chance: %s" % Skills.tier_text("stealth", 2))
	var w := Wiki.build()
	check(w.pages.has("sys:skills") and w.pages.has("skill:mining"), "the wiki has the skills page and each skill's page")
	var rows := []
	for b in w.pages["skill:mining"].blocks:
		rows.append_array(b.get("rows", []))
	check(rows.any(func(r): return str(r[1]).contains("Mine gold ore")) and rows.any(func(r): return r[0] == "Level 10"), "the mining page lists all tiers from the data (%d rows)" % rows.size())
