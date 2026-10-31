extends SceneTree
## LE05-REPAIR (owner directive 2026-10-31, docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md, LE-05 A): basic tool
## repair at an anvil, normal play with the Living Economy on or off. The forge recipe's share for the wear (inputs rounded up, minutes
## rounded up, experience rounded down); partial, heavy and nearly broken wear; the Smithing level; the tiny-repair rule; no value
## from nothing; identity and holder kept; the player's verbs; a smith's own and its household's tools; saves.
## Run headless:  godot --headless --path game --script res://tests/le05_repair_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(on := false) -> World:
	if on:
		var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		c.enabled = true
		EconomyFoundation.set_override(c)
	else:
		EconomyFoundation.set_override({})
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_terms()
	test_unrepairable()
	test_no_value_from_nothing()
	test_work_repair(false)
	test_work_repair(true)
	test_skill_limit()
	test_player_verbs()
	test_smith()
	test_saves()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func wear_to(inv: Inventory, id: String, left: int) -> void:
	if not inv.has(id):
		inv.add(id)
	inv.durability[id] = left


func test_terms() -> void:
	var inv := Inventory.new()
	var full := int(GameData.item("axe").durability)          # 120; forge_axe: 2 iron bars, 1 plank, 60 minutes, 18 xp
	check(World.repair_recipe("axe") == "forge_axe", "an axe is mended by its forge recipe")
	inv.add("axe")
	check(World.repair_terms(inv, "axe").is_empty(), "an unworn axe has nothing to mend")
	wear_to(inv, "axe", full / 2)
	var t := World.repair_terms(inv, "axe")
	check(t["in"] == {"iron_bar": 1, "plank": 1} and int(t.minutes) == 30 and int(t.xp) == 9 and int(t.missing) == full / 2,
		"partial wear (half): half the inputs rounded up, half the minutes and xp (%s)" % str(t))
	wear_to(inv, "axe", 10)
	t = World.repair_terms(inv, "axe")
	check(t["in"] == {"iron_bar": 2, "plank": 1} and int(t.minutes) == 55 and int(t.xp) == 16, "heavy wear (110 of 120): %s" % str(t))
	wear_to(inv, "axe", 1)
	t = World.repair_terms(inv, "axe")
	check(t["in"] == {"iron_bar": 2, "plank": 1} and int(t.minutes) == 60 and int(t.xp) == 17,
		"nearly broken (1 use left): the whole forge inputs, never more (%s)" % str(t))
	wear_to(inv, "axe", full - 1)
	t = World.repair_terms(inv, "axe")
	check(t["in"] == {"iron_bar": 1, "plank": 1} and int(t.minutes) == 1 and int(t.xp) == 0,
		"a tiny repair (1 use) still takes one of each input, a minute and earns nothing (%s)" % str(t))
	# the tiny-repair rule: mending wear a little at a time never costs less than mending it at once
	for id in ["axe", "pickaxe", "hammer", "iron_sword", "iron_armor", "chisel"]:
		var f := int(GameData.item(id).durability)
		var once := Inventory.new()
		wear_to(once, id, 1)
		var whole: Dictionary = World.repair_terms(once, id)["in"]
		var bits := 0
		var lump := 0
		for k in whole:
			lump += int(whole[k])
		var step := maxi(1, f / 10)
		var gone := 0
		while gone < f - 1:
			var piece := mini(step, f - 1 - gone)
			var one := Inventory.new()
			wear_to(one, id, f - piece)
			var ti: Dictionary = World.repair_terms(one, id)["in"]
			for k in ti:
				bits += int(ti[k])
			gone += piece
		check(bits >= lump, "%s: ten small repairs cost %d units, one repair of the same wear %d (never cheaper)" % [id, bits, lump])


func test_unrepairable() -> void:
	var w := new_world(false)
	var p := w.player
	for id in ["shovel", "plough", "mallet", "rusty_axe", "rusty_pickaxe", "rusty_sword", "plain_clothes", "leather_armor", "log", "lockpick"]:
		check(World.repair_recipe(id) == "", "%s has no forge recipe at the anvil: not repairable" % id)
	wear_to(p.inv, "rusty_axe", 10)
	check(World.repair_terms(p.inv, "rusty_axe").is_empty() and w.repair_refusal(p, "rusty_axe", p.inv, p.inv).contains("cannot be mended"),
		"a worn rusty axe is refused (%s)" % w.repair_refusal(p, "rusty_axe", p.inv, p.inv))


## Requirement 4: the inputs a repair uses are worth at least the value the repair restores (the item's value x the share mended),
## for every repairable item, at a small, a half and a full share of wear.
func test_no_value_from_nothing() -> void:
	var worst := ""
	var n := 0
	for id in GameData.items:
		if World.repair_recipe(str(id)) == "":
			continue
		var f := int(GameData.item(str(id)).durability)
		for left in [f - 1, f / 2, 1]:
			var inv := Inventory.new()
			wear_to(inv, str(id), left)
			var t := World.repair_terms(inv, str(id))
			var cost := 0.0
			for k in t["in"]:
				cost += float(t["in"][k]) * GameData.value(str(k))
			var mended := GameData.value(str(id)) * float(t.missing) / float(f)
			n += 1
			if cost + 0.001 < mended * _forge_margin(str(id)):
				worst = "%s at %d left: inputs %.2f, mended %.2f" % [id, left, cost, mended]
	check(n > 100 and worst == "", "every repair's inputs are worth what forging them is worth for the share mended (%d cases) %s" % [n, worst])


## How much of an item's value its forge inputs make up (the smith's work is the rest): a repair keeps at least that share.
func _forge_margin(id: String) -> float:
	var rec: Dictionary = GameData.recipes[World.repair_recipe(id)]
	var c := 0.0
	for k in rec["in"]:
		c += float(rec["in"][k]) * GameData.value(str(k))
	return minf(1.0, c / maxf(0.001, GameData.value(id)))


func test_work_repair(on: bool) -> void:
	var w := new_world(on)
	var tag := "economy on" if on else "economy off"
	check((w.economy != null) == on, "%s: the switch is as set" % tag)
	var p := w.player
	p.skills["smithing"] = 0
	var full := int(GameData.item("axe").durability)
	for id in p.inv.ids():
		if id in ["axe", "iron_bar", "plank", "hammer"]:
			p.inv.remove(id, p.inv.count(id))
	p.inv.add("axe", 2)
	p.inv.durability["axe"] = 30
	p.inv.add("iron_bar", 3)
	p.inv.add("plank", 2)
	var coins0 := w.total_coins()
	var used_iron := float(w.stats.get("used_iron_bar", 0.0))
	var xp0 := int(p.skills.get("smithing", 0))
	var r := w.work_repair(p, "axe", p.inv, p.inv)
	check(r.result == "ok" and p.inv.count("axe") == 2 and not p.inv.durability.has("axe"),
		"%s: a heavily worn axe (30 of %d) is mended to full; still two axes, in the same pack" % [tag, full])
	check(p.inv.count("iron_bar") == 1 and p.inv.count("plank") == 1 and float(w.stats.get("used_iron_bar", 0.0)) - used_iron == 2.0,
		"%s: exactly the share used, counted in the goods ledger (2 bars, 1 plank)" % tag)
	check(int(p.skills.get("smithing", 0)) - xp0 == 13 and w.total_coins() == coins0, "%s: 13 xp (18 x 90 / 120, rounded down); no coin moved" % tag)
	check(w.work_repair(p, "axe", p.inv, p.inv).result == "refused", "%s: a mended axe is not mended again" % tag)
	p.inv.durability["axe"] = full - 1
	p.inv.remove("iron_bar", p.inv.count("iron_bar"))
	check(w.work_repair(p, "axe", p.inv, p.inv).why == "You do not have the materials." and p.inv.durability["axe"] == full - 1,
		"%s: without the materials nothing changes" % tag)


func test_skill_limit() -> void:
	var w := new_world(false)
	var p := w.player
	p.skills["smithing"] = 0
	wear_to(p.inv, "iron_armor", 100)                       # forge_iron_armor needs Smithing 3
	p.inv.add("iron_bar", 5)
	p.inv.add("leather", 2)
	check(w.repair_refusal(p, "iron_armor", p.inv, p.inv) == "Needs Smithing level 3.", "the player needs the forging's Smithing level (%s)" % w.repair_refusal(p, "iron_armor", p.inv, p.inv))
	check(w.work_repair(p, "iron_armor", p.inv, p.inv).result == "refused" and int(p.inv.durability["iron_armor"]) == 100, "refused below the level: nothing changes")
	var sm: NPC = w.npcs.filter(func(n): return n.alive and n.job == "smith")[0]
	sm.skills["smithing"] = 0
	wear_to(sm.inv, "iron_armor", 10)
	sm.inv.add("iron_bar", 5)
	sm.inv.add("leather", 2)
	check(w.brain.repair_job(sm).filter(func(x): return x is String and x == "iron_armor").is_empty(), "a smith below the level does not take the armour up")
	sm.skills["smithing"] = Skills.xp_for_level(3)
	check(w.repair_refusal(sm, "iron_armor", sm.inv, sm.inv) == "", "a smith with the level may mend it")


func anvil_for_player(w: World) -> String:
	for id in w.stations_of("anvil"):
		if w.station_refusal(id) == "":
			return id
	return ""


func test_player_verbs() -> void:
	var w := new_world(false)
	var p := w.player
	var sid := anvil_for_player(w)
	if sid == "":
		var sid0: String = w.stations_of("anvil")[0]
		var b: Dictionary = w.buildings.get(str(w.stations[sid0].get("building", "")), {})
		print("note: no anvil free to the player: %s" % w.station_refusal(sid0))
		check(not b.is_empty(), "the village's anvil is in a building")
		return
	p.pos = Vector2(w.station_use(sid)) + Vector2(0.5, 0.5)
	for id in ["axe", "iron_bar", "plank"]:
		p.inv.remove(id, p.inv.count(id))
	p.inv.add("axe")
	check(not w.player_repair_begin("axe", sid).ok, "an unworn axe: nothing to begin")
	p.inv.durability["axe"] = 60
	var b0 := w.player_repair_begin("axe", sid)
	check(not b0.ok and str(b0.why) == "You do not have the materials." and not w.player_at_station(sid), "no materials: refused, the anvil not held")
	p.inv.add("iron_bar", 1)
	p.inv.add("plank", 1)
	var b1 := w.player_repair_begin("axe", sid)
	var want := 30.0 / float(GameData.b("game_minutes_per_second")) * 0.5 * Skills.value(p, "smithing", "craft_time", 1.0)
	check(b1.ok and str(b1.station) == sid and is_equal_approx(float(b1.secs), want) and w.player_at_station(sid), "at the anvil the mending takes its share of the time and holds the anvil (%s)" % str(b1))
	var r := w.player_repair("axe")
	check(r.result == "ok" and not p.inv.durability.has("axe") and p.inv.count("iron_bar") == 0 and p.inv.count("plank") == 0, "player_repair mends it from the pack")
	w.release_player_station(sid)
	var saw: String = w.stations_of("sawhorse")[0] if not w.stations_of("sawhorse").is_empty() else ""
	if saw != "":
		check(not w.player_repair_begin("axe", saw).ok, "tools are mended only at an anvil")
	check(NetActions.VERBS.has("player_repair_begin") and NetActions.VERBS.has("player_repair"), "a guest's repair is a host verb (World.mirror)")


func test_smith() -> void:
	var w := new_world(false)
	var sm: NPC = w.npcs.filter(func(n): return n.alive and n.job == "smith")[0]
	for id in ["iron_ore", "copper_ore", "gold_ore"]:
		sm.inv.remove(id, sm.inv.count(id))
	sm.inv.add("iron_bar", 4)
	sm.inv.add("plank", 2)
	wear_to(sm.inv, "hammer", 380)                          # 5% worn: below the threshold
	check(w.brain.repair_job(sm).is_empty(), "a smith leaves a little-worn hammer alone (under repair.npc_min_missing)")
	wear_to(sm.inv, "hammer", 100)                          # 75% worn
	var job: Array = w.brain.repair_job(sm)
	check(job.size() == 2 and job[0] == sm and job[1] == "hammer", "a smith takes up its own worn hammer")
	var kin: Array = w.npcs.filter(func(n): return n.alive and n != sm and n.household == sm.household and sm.household >= 0)
	var other: Array = w.npcs.filter(func(n): return n.alive and n.household != sm.household and n.role == "adult")
	if not kin.is_empty():
		sm.inv.durability.erase("hammer")
		wear_to(kin[0].inv, "axe", 20)
		var j2: Array = w.brain.repair_job(sm)
		check(j2.size() == 2 and j2[0] == kin[0] and j2[1] == "axe", "a smith takes up its household's worn axe")
		var d0 := w.total_coins()
		var bars := sm.inv.count("iron_bar")
		check(w.work_repair(sm, "axe", kin[0].inv, sm.inv).result == "ok" and not kin[0].inv.durability.has("axe") and kin[0].inv.has("axe")
			and sm.inv.count("iron_bar") == bars - 2 and w.total_coins() == d0, "mended in its holder's pack with the smith's materials; no coin moved")
	wear_to(other[0].inv, "axe", 5)
	check(w.brain.repair_job(sm).filter(func(x): return x is NPC and x == other[0]).is_empty(), "nobody outside the household (paid repair is the economy's)")
	# the smith's day: it goes to the anvil and mends its hammer
	wear_to(sm.inv, "hammer", 100)
	sm.plan = []
	var n0 := float(w.stats.get("repaired_hammer", 0.0))
	for i in 2 * 24 * 60 * 2:
		w.update(0.5)
		if float(w.stats.get("repaired_hammer", 0.0)) > n0:
			break
	check(float(w.stats.get("repaired_hammer", 0.0)) > n0 and int(sm.inv.durability.get("hammer", 400)) > 100, "in play the smith walks to the anvil and mends its hammer (%s)" % str(sm.inv.durability.get("hammer", "full")))


func test_saves() -> void:
	var w := new_world(false)
	var p := w.player
	wear_to(p.inv, "pickaxe", 40)
	var d := w.to_dict()
	var s := JSON.stringify(d)
	check(not s.contains("repair"), "repair adds nothing to the save")
	var back := World.new()
	back.load_dict(VillageMap.load_default(), JSON.parse_string(s))
	check(int(back.player.inv.durability.get("pickaxe", -1)) == 40, "a worn tool's wear is kept across save and load")
	back.player.inv.add("iron_bar", 2)
	back.player.inv.add("plank", 1)
	check(back.work_repair(back.player, "pickaxe", back.player.inv, back.player.inv).result == "ok", "and is mended after loading")
	# an older save (Build 24 single, save v23) loads and its worn tools can be mended
	var f := FileAccess.get_file_as_string("res://tests/fixtures/b24_save_v23_single.json")
	var old := World.new()
	old.load_dict(VillageMap.load_default(), JSON.parse_string(f))
	var any := ""
	for n: NPC in old.npcs:
		for id in n.inv.durability:
			if any == "" and World.repair_recipe(str(id)) != "":
				any = "%d:%s" % [n.id, id]
	check(old.player != null, "the Build 24 save loads")
	if any != "":
		var n := old.npc(int(any.get_slice(":", 0)))
		var id := any.get_slice(":", 1)
		var have := n.inv.count(id)
		var t := World.repair_terms(n.inv, id)
		for k in t["in"]:
			n.inv.add(k, int(t["in"][k]))
		n.skills["smithing"] = 99999
		check(old.work_repair(n, id, n.inv, n.inv).result == "ok" and n.inv.count(id) == have and not n.inv.durability.has(id),
			"a worn %s from the Build 24 save is mended (count kept)" % id)
