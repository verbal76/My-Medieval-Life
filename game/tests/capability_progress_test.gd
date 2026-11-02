extends SceneTree
## B25-CAPABILITY (owner Decisions 1 and 8, 2026-11-01, docs/directives/2026-11-01_nine_owner_decisions_consolidated.md):
## organic skills and the village's capability milestones. Experience comes from real, successful work whatever the purpose
## (a builder quarrying stone for their own house earns Mining as a miner does); a failed action teaches nothing; the
## settlement's level is derived from real conditions only and one skilled person does not make it advanced; a milestone is
## announced once, on its first achievement, never again when the level falls and comes back; the milestone record survives
## a save and load and an older save is seeded silently; recording and announcing move no coin, item or random draw.
##   godot --headless --path game --script res://tests/capability_progress_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_personal_project_xp()
	test_no_xp_without_success()
	test_level_from_real_conditions()
	test_one_skilled_person()
	test_milestone_once()
	test_live_announcement()
	test_save_round_trip()
	test_older_save_silent()
	test_no_output_or_coins()
	test_level_up_text()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _fresh(s: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), s)
	return w


func _non_miner(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "miner" and n.job != "laborer":
			return n
	return null


# Decision 1: "A villager who mines stone to build his own house gains Mining experience".
func test_personal_project_xp() -> void:
	var w := _fresh(1)
	var n := _non_miner(w)
	n.skills["mining"] = 0
	n.inv.add("pickaxe")
	check(w.construction._quarry_own(n), "a builder with a pickaxe who cannot buy stone plans to quarry it (%s, a %s)" % [n.name, n.job])
	var step: Dictionary = n.plan.filter(func(s): return str(s.get("act", "")) == "mine")[0] if n.plan.any(func(s): return str(s.get("act", "")) == "mine") else {}
	check(not step.is_empty() and n.doing.contains("own building"), "the plan is a swing at a stone seam, for their own building")
	var before := n.inv.count("stone")
	var ok: bool = w.brain.act(n, "mine", step.get("args", {}))
	check(ok and n.inv.count("stone") > before, "the swing takes stone from the seam into their pack")
	check(int(n.skills.get("mining", 0)) > 0, "and earns Mining xp though they are no miner (%d xp)" % int(n.skills.get("mining", 0)))
	check(WorkExperience.industry_of_step("mine", {}) == "mining", "the 'mine' act is mining work for the experience record, whoever swings")
	var none := _fresh(1)
	var m := _non_miner(none)
	m.inv.remove("pickaxe", m.inv.count("pickaxe"))
	check(not none.construction._quarry_own(m), "without a pickaxe nobody quarries (no tool, no work)")


# "Keeping xp only for real successful actions".
func test_no_xp_without_success() -> void:
	var w := _fresh(2)
	var n := _non_miner(w)
	n.skills["mining"] = 0
	n.inv.add("pickaxe")
	var dry := {"ore": "stone", "amount": 0, "x": 0, "y": 0}
	var r := w.work_mine(n, dry, n.inv)
	check(str(r.result) == "out" and int(n.skills.get("mining", 0)) == 0, "a swing at a worked-out seam earns no xp")
	var gold := {"ore": "gold_ore", "amount": 5, "x": 0, "y": 0}
	r = w.work_mine(n, gold, n.inv)
	check(str(r.result) == "gold" and int(n.skills.get("mining", 0)) == 0, "a swing refused (gold below Mining 3) earns no xp")
	n.skills["smithing"] = 0
	var empty := Inventory.new()
	var c := w.work_craft(n, "smelt_iron" if GameData.recipes.has("smelt_iron") else str(GameData.recipes.keys()[0]), empty)
	check(str(c.result) != "ok" and int(n.skills.get("smithing", 0)) == 0, "a craft without its materials earns no xp")


# Decision 8: "Settlement levels must be derived from actual world conditions, not granted arbitrarily."
func test_level_from_real_conditions() -> void:
	var w := _fresh(3)
	var a := SettlementProfile.update(w, w.settlement_caps.duplicate(true), w.day())
	var rep := SettlementReport.village(w)
	var same := true
	for ind in rep.capabilities:
		same = same and int(a.industries[ind].level) == int(rep.capabilities[ind])
	check(same, "every industry's level is the one the world's facts give (SettlementReport)")
	# take away every smith's skill: the smithing level falls to what is left
	var caps := w.settlement_caps.duplicate(true)
	for n: NPC in w.npcs:
		n.skills.erase("smithing")
	w.player.skills.erase("smithing")
	var b := SettlementProfile.update(w, caps, w.day())
	check(int(b.industries.smithing.level) <= 1 and int(b.industries.smithing.level) < int(a.industries.smithing.level),
		"with nobody's smithing above the level-1 floor the village's smithing falls from %d to %d" % [int(a.industries.smithing.level), int(b.industries.smithing.level)])
	check(SettlementProfile.best(caps, "smithing") >= int(a.industries.smithing.level), "and the milestone record keeps the best it reached")


# "A village does not become an advanced mining settlement simply because one person reaches a particular personal level."
func test_one_skilled_person() -> void:
	var cap: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/capabilities.json"))
	var d := {"industries": {"mining": cap.industries.mining}}
	var master := {"job": "smith", "skills": {"mining": 10, "smithing": 10},
		"tools": {"pickaxe": 1, "shovel": 1, "prospecting_kit": 1}}
	var facts := {"practitioners": [master], "tools": {"pickaxe": 3, "shovel": 3, "prospecting_kit": 1}, "stations": {"forge": 1},
		"structures": {"pit_ramp": 1, "timber_support": 1}, "portals": [-1], "records": {"discovery": 1},
		"transport": {"handcart": 1}, "deposit_access": [0]}
	var one := int(SettlementIndustries.levels(facts, d).mining)
	check(one >= 1 and one < 3, "one master miner with every tool and facility: mining level %d, not open pit or underground" % one)
	facts.practitioners = []
	check(int(SettlementIndustries.levels(facts, d).mining) == 0, "nobody able: level 0, whatever the facilities")
	facts.practitioners = [master, master.duplicate(true)]
	check(int(SettlementIndustries.levels(facts, d).mining) == 4, "two such miners and the works: underground mining (4)")
	var smiths := {"practitioners": [{"skills": {"smithing": 10}, "tools": {}}], "stations": {"forge": 1, "anvil": 1}, "stock": {"hammer": 1}, "tools": {"hammer": 1}}
	var sd := SettlementIndustries.data()
	check(int(SettlementIndustries.evaluate(smiths, sd).levels.smithing) < 3, "one master smith alone does not make a master smithy")


# A milestone is announced on its first achievement only.
func test_milestone_once() -> void:
	var st := {"levels": {"mining": 1}, "since": {"mining": 0}, "history": []}
	SettlementProfile.seed_milestones(st, 0)
	check(SettlementProfile.best(st, "mining") == 1, "the starting level is recorded silently as reached")
	var r := SettlementProfile.note_milestones(st, {"mining": 2}, 5)
	check(r.size() == 1 and int(r[0].level) == 2, "level 2 first reached: one milestone")
	check(SettlementProfile.note_milestones(st, {"mining": 2}, 6).is_empty(), "holding at 2: nothing new")
	check(SettlementProfile.note_milestones(st, {"mining": 1}, 7).is_empty(), "falling to 1: nothing")
	check(SettlementProfile.note_milestones(st, {"mining": 2}, 8).is_empty(), "back to 2: not announced again (the record is the hysteresis)")
	check(int(st.milestones.mining["2"]) == 5, "the milestone keeps the day it was first reached")
	r = SettlementProfile.note_milestones(st, {"mining": 4}, 9)
	check(r.size() == 1 and int(r[0].level) == 4 and st.milestones.mining.has("3") and int(st.milestones.mining["3"]) == 9,
		"a rise of two levels records both and is announced once, at the higher")
	check(SettlementProfile.milestone_text("mining", 2) == "Village Development: Mining Capability Level 2 Reached.", "the owner's words")


# The live wiring: the dawn's update finds a new milestone once; the announcement goes to the record and the journal.
func test_live_announcement() -> void:
	var w := _fresh(4)
	var shown := []
	w.event.connect(func(line: String): shown.append(line))     # the village lane (World.note -> event -> GameUI.village)
	var ind := ""
	for id in w.settlement_caps.levels:
		if int(w.settlement_caps.levels[id]) > 0:
			ind = str(id)
			break
	check(ind != "", "the village starts with some capability (%s)" % ind)
	w.settlement_caps.milestones.erase(ind)            # as if it had never been reached
	var p := SettlementProfile.update(w, w.settlement_caps, w.day())
	check((p.reached as Array).size() == 1 and str(p.reached[0].industry) == ind, "the update finds it newly reached")
	w.announce_milestones(p.reached)
	var text := SettlementProfile.milestone_text(ind, int(p.reached[0].level))
	check(shown.filter(func(l): return str(l).ends_with(text)).size() == 1, "announced once, as village news through note(): %s" % text)
	var kept: Array = w.messages.entries(w.player_ref(w.player))
	check(kept.any(func(e): return str(e[1]) == "village" and str(e[2]) == text), "kept in the player's journal under 'village'")
	check(w.log_lines.any(func(l): return str(l).ends_with(text)), "and in the village record")
	p = SettlementProfile.update(w, w.settlement_caps, w.day())
	check((p.reached as Array).is_empty(), "the next update announces nothing")


func test_save_round_trip() -> void:
	var w := _fresh(5)
	w.settlement_caps.milestones["mining"] = {"1": 0, "2": 3, "3": 7}
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(JSON.stringify(w2.settlement_caps.milestones) == JSON.stringify(w.settlement_caps.milestones), "the milestone record round-trips through a JSON save")
	check(SettlementProfile.best(w2.settlement_caps, "mining") == 3 and typeof(w2.settlement_caps.milestones.mining["2"]) == TYPE_INT,
		"best and days read back as whole numbers")


func test_older_save_silent() -> void:
	var w := _fresh(6)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	(d[SettlementSave.KEY].capabilities.village as Dictionary).erase("milestones")
	(d[SettlementSave.KEY].capabilities.village.history as Array).append({"day": 1, "industry": "trade", "from": 0, "to": 2})
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(not w2.settlement_caps.has("milestones"), "an older save loads without the optional key (the loaded state is not rewritten)")
	var p := SettlementProfile.update(w2, w2.settlement_caps, w2.day())
	check((p.reached as Array).is_empty(), "its first update seeds the record silently: no announcement")
	check(SettlementProfile.best(w2.settlement_caps, "trade") >= 2 and int(w2.settlement_caps.milestones.trade["2"]) == 1,
		"levels its saved history shows are kept as reached, on the day the history gives")


func _coins(w: World) -> int:
	var c := w.player.coins
	for n: NPC in w.npcs:
		c += n.coins
	return c


func _goods(w: World) -> String:
	var parts := [JSON.stringify(w.player.inv.to_dict())]
	for n: NPC in w.npcs:
		parts.append(JSON.stringify(n.inv.to_dict()))
	return "|".join(parts)


# "Settlement capabilities represent real capacity, not automatic extra output or currency creation."
func test_no_output_or_coins() -> void:
	var w := _fresh(7)
	var coins := _coins(w)
	var goods := _goods(w)
	var rng := w.rng.state
	var skills := JSON.stringify(w.npcs.map(func(n): return n.skills))
	for id in w.settlement_caps.milestones.keys():
		w.settlement_caps.milestones.erase(id)
	var p := SettlementProfile.update(w, w.settlement_caps, w.day())
	w.announce_milestones(p.reached)
	check(not (p.reached as Array).is_empty(), "milestones recorded and announced (%d)" % (p.reached as Array).size())
	check(_coins(w) == coins and _goods(w) == goods and w.rng.state == rng and JSON.stringify(w.npcs.map(func(n): return n.skills)) == skills,
		"no coin, item, skill or random draw moved")
	var mx := 0.0
	for id in p.industries:
		mx = maxf(mx, absf(SettlementIndustries.output_multiplier("mining", float(p.industries.get("mining", {}).get("level", 0))) - 1.0))
	check(mx == 0.0, "the village's mining level carries no output bonus of its own (no double counting with the miners' Skills)")


func test_level_up_text() -> void:
	check(Skills.level_up_text("mining", 3).begins_with("Mining Level 3 Reached."), "the personal announcement: %s" % Skills.level_up_text("mining", 3))
	var w := _fresh(8)
	var got := []
	w.player_leveled.connect(func(s: String, l: int): got.append([s, l]))
	w.player.skills["mining"] = 0
	var up := w.player_xp("mining", Skills.xp_for_level(3))
	check(up == 3 and got.size() == 1 and got[0][0] == "mining" and got[0][1] == 3, "the player's level-up is signalled once for the interface (player_leveled)")
