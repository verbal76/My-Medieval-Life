extends SceneTree
## PROSPECTIVE (Expansion 18, X18-CAPCOMP part 1; owner decision 2026-10-22): each person's industry experience from the
## hours they work (WorkExperience), the caps, the straight-line individual level, the hours-weighted workforce level of
## the last season (a report only), experience leaving with the person, the save section, and the prepared per-worker
## hook path (not enabled). Nothing here changes the game.
##   godot --headless --path game --script res://tests/experience_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func near(a: float, b: float) -> bool:
	return absf(a - b) < 1e-6


func _init() -> void:
	GameData.ensure()
	test_accrual_caps_levels()
	test_separation_and_dormancy()
	test_master_and_apprentice()
	test_workforce_average()
	test_step_mapping()
	test_live_world()
	test_leaving()
	test_save()
	test_per_worker_path()
	test_effective_kept_apart()
	test_production_compat()
	test_contract_compat()
	test_report()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


const DAY := 480.0                 # minutes of work in one experience day (8 game hours)


func test_accrual_caps_levels() -> void:
	var e := WorkExperience.new()
	e.credit("npc:1", "mining", 240.0, 0.0)
	check(near(e.days("npc:1", "mining"), 0.5), "4 game hours of mining are half an experience day")
	e.credit("npc:1", "mining", 240.0, 60.0)
	check(near(e.days("npc:1", "mining"), 1.0), "8 hours: one experience day")
	var caps := {"mining": 12, "forestry": 12, "farming": 18, "trade": 18, "tanning": 18, "carpentry": 24, "smithing": 24}
	var ok := true
	for ind in caps:
		ok = ok and near(WorkExperience.cap_days(ind), float(caps[ind])) and near(WorkExperience.level_of_days(ind, float(caps[ind])), 10.0)
	check(ok, "caps: mining and forestry 12 days; farming, trade, tanning 18; carpentry, smithing 24; each reaches level 10")
	check(near(WorkExperience.level_of_days("mining", 6.0), 5.0) and near(WorkExperience.level_of_days("smithing", 6.0), 2.5)
		and near(WorkExperience.level_of_days("farming", 4.5), 2.5) and near(WorkExperience.level_of_days("forestry", 0.0), 0.0),
		"the level is straight-line: 10 x days / cap (6 mining days 5.0; 6 smithing days 2.5; 4.5 farming days 2.5; none 0)")
	e.credit("npc:1", "mining", 30.0 * DAY, 120.0)
	check(near(e.level("npc:1", "mining"), 10.0) and near(e.days("npc:1", "mining"), 31.0),
		"past the cap the level stays 10 and the days worked are all kept (31; never reduced)")
	check(near(e.level("npc:9", "mining"), 0.0), "someone who never worked is level 0 (no starting experience is approved)")


func test_separation_and_dormancy() -> void:
	var e := WorkExperience.new()
	e.credit("npc:2", "mining", 6.0 * DAY, 0.0)
	check(near(e.days("npc:2", "farming"), 0.0), "mining hours give no farming experience (per industry)")
	# the worker turns to farming: their mining experience is kept, dormant
	var later := 10.0 * 1440.0
	e.credit("npc:2", "farming", 2.0 * DAY, later)
	check(near(e.level("npc:2", "mining"), 5.0) and near(e.days("npc:2", "farming"), 2.0),
		"after changing industries the mining level (5.0) is kept, never decaying, and farming grows on its own")
	check(str(e.workforce("mining", later).status) == "no active workers" and int(e.workforce("farming", later).active) == 1,
		"and the dormant miner is no active mining worker this season, an active farmer instead")


func test_master_and_apprentice() -> void:
	var e := WorkExperience.new()
	e.credit("npc:10", "smithing", 24.0 * DAY, 0.0)           # a master: level 10
	var t := 3.0 * 1440.0
	e.credit("npc:10", "smithing", 120.0, t)
	e.credit("npc:11", "smithing", 120.0, t)                  # an apprentice's first two hours beside them
	check(near(e.level("npc:10", "smithing"), 10.0), "the master keeps level 10 working beside an apprentice")
	check(near(e.level("npc:11", "smithing"), 10.0 * (120.0 / DAY) / 24.0),
		"the apprentice's level is from their own two hours only (%.3f): nobody inherits another's experience" % e.level("npc:11", "smithing"))


func test_workforce_average() -> void:
	var e := WorkExperience.new()
	var t := 5.0 * 1440.0
	check(e.workforce("tanning", t).status == "no active workers" and not e.workforce("tanning", t).has("level"),
		"with nobody working it, an industry reports \"no active workers\", never level 0")
	e.credit("npc:1", "tanning", 18.0 * DAY, 0.0)               # level 10, long ago
	e.credit("npc:2", "tanning", 9.0 * DAY - 60.0, 0.0)         # nearly level 5, long ago
	e.credit("npc:1", "tanning", 180.0, t)                      # 3 hours this season
	e.credit("npc:2", "tanning", 60.0, t + 60.0)                # 1 hour this season (now level 5)
	var wf := e.workforce("tanning", t + 120.0)
	var want := (3.0 * e.level("npc:1", "tanning") + 1.0 * e.level("npc:2", "tanning")) / 4.0
	check(int(wf.active) == 2 and near(float(wf.hours), 4.0) and near(float(wf.level), want),
		"the workforce level is the hours-weighted average of the active workers' own levels (%.3f over 4 hours)" % float(wf.level))
	check(e.workforce("tanning", t + 3.0 * 1440.0).status == "no active workers",
		"after a season (2 game days) without work there are no active workers, and their experience stays (%.1f, %.1f)" % [e.level("npc:1", "tanning"), e.level("npc:2", "tanning")])
	check(near(e.level("npc:1", "tanning"), 10.0), "the workforce figure is a report: it changes nobody's own level")


func test_step_mapping() -> void:
	var m := func(act: String, args := {}, kind := "") -> String: return WorkExperience.industry_of_step(act, args, kind)
	check(m.call("mine") == "mining" and m.call("mj_mine") == "mining" and m.call("chop") == "forestry"
		and m.call("craft", {"recipe": "smelt_iron"}) == "smithing" and m.call("craft", {"recipe": "saw_planks"}) == "carpentry"
		and m.call("craft", {"recipe": "tan_leather"}) == "tanning" and m.call("craft", {"recipe": "cook_pottage"}) == "",
		"work maps to industries as the capability hook maps it: mining swings, felling, recipes by station (cooking none)")
	check(m.call("harvest") == "farming" and m.call("sow") == "farming" and m.call("feed_pen") == "farming" and m.call("collect_pen") == "farming"
		and m.call("fp_work", {"task": "till"}) == "farming" and m.call("fp_work", {"task": "clear"}) == ""
		and m.call("mj_step", {}, "mend") == "carpentry" and m.call("mj_step", {}, "excavate") == "" and m.call("slaughter") == "" and m.call("hunt") == "",
		"farm tasks the owner listed are farming; clearing, slaughter, hunting and manor jobs other than mending are not attributed (open questions)")


func test_live_world() -> void:
	var a := _run(1, 1.0)
	var b := _run(1, 1.0)
	var da := a.experience.to_dict()
	check(JSON.stringify(da) == JSON.stringify(b.experience.to_dict()), "the same seed gives the same experience record (determinism)")
	var inds := {}
	for k in a.experience.minutes:
		for ind in a.experience.minutes[k]:
			inds[ind] = true
	print("     one day of seed 1: %d people with hours, industries %s; workforce %s" % [a.experience.minutes.size(), str(inds.keys()),
		str(["mining", "forestry", "farming", "smithing"].map(func(i): return a.experience.workforce(i, a.minutes)))])
	check(a.experience.minutes.size() > 0 and inds.has("farming"), "a day of the village's work is recorded by person and industry")
	var tot := 0.0
	for k in a.experience.minutes:
		for ind in a.experience.minutes[k]:
			tot += float(a.experience.minutes[k][ind])
	var people := a.npcs.filter(func(n): return n.alive).size()
	check(tot <= float(people) * 1440.0 + 1e-6, "no one is credited more hours than the day has (%.0f minutes over %d people)" % [tot, people])


func test_leaving() -> void:
	var w := _fresh(1)
	var n: NPC = w.npcs.filter(func(o): return o.alive and o.role == "adult")[0]
	var k := World.npc_ref(n.id)
	w.experience.credit(k, "forestry", 600.0, w.minutes)
	w.experience.credit(WorkExperience.PLAYER, "forestry", 60.0, w.minutes)
	w._new_day()
	check(w.experience.minutes.has(k), "a living villager's experience stays at dawn")
	n.alive = false
	w._new_day()
	check(not w.experience.minutes.has(k) and w.experience.workforce("forestry", w.minutes).active == 1,
		"when they die or leave, their experience leaves with them (only the player's hours remain this season)")
	w.note_player_work("forestry", 30.0)
	check(near(w.experience.days(WorkExperience.PLAYER, "forestry"), (60.0 + 30.0 * float(GameData.b("game_minutes_per_second"))) / DAY),
		"the player's finished work is credited by the same rule (seconds of action as game minutes)")


func test_save() -> void:
	var fresh := _fresh(2)
	check(not fresh.to_dict().has(WorkExperience.KEY), "a world nobody has worked in saves without the section (as before)")
	var w := _run(2, 0.5)
	var d := w.to_dict()
	check(d.has(WorkExperience.KEY) and str(d[WorkExperience.KEY].format) == WorkExperience.FORMAT, "once people work, the save carries the optional section")
	var back: Dictionary = JSON.parse_string(JSON.stringify(d))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), back)
	check(JSON.stringify(w2.experience.to_dict()) == JSON.stringify(w.experience.to_dict()), "the record round-trips through a JSON save")
	back.erase(WorkExperience.KEY)
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), back)
	check(w3.experience.minutes.is_empty() and w3.total_coins() == w.total_coins(), "a save without the section (every older save) loads, its tracking empty")
	back[WorkExperience.KEY] = {"format": "mml-x18-experience/99", "who": "knows"}
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), back)
	check(w4.to_dict()[WorkExperience.KEY] == back[WorkExperience.KEY], "a section of an unknown format is kept as it was, never reinterpreted or dropped")


func test_per_worker_path() -> void:
	var w := _fresh(1)
	var ad: Array = w.npcs.filter(func(o): return o.alive and o.role == "adult")
	var master: NPC = ad[0]
	var apprentice: NPC = ad[1]
	w.experience.credit(World.npc_ref(master.id), "smithing", 24.0 * DAY, 0.0)
	CapabilityHook.off()
	check(CapabilityHook.time(100.0, "smithing", master) == 100.0 and CapabilityHook.pay(100, "smithing", master) == 100,
		"the hook stays off: a level-10 master's work and pay are exactly the base")
	CapabilityHook.per_worker = true                 # the prepared path, switched on only here
	CapabilityHook.experience = w.experience
	var tm := CapabilityHook.time(100.0, "smithing", master)
	var ta := CapabilityHook.time(100.0, "smithing", apprentice)
	check(near(tm, 100.0 / 1.15) and near(ta, 100.0) and CapabilityHook.pay(100, "smithing", master) == 106 and CapabilityHook.pay(100, "smithing", apprentice) == 100,
		"on the prepared path each worker reads their own level: the master works 15%% faster and earns 6%% more; the apprentice beside them gets nothing of it")
	check(CapabilityHook.time(100.0, "smithing") == 100.0, "with no worker named nothing changes (no settlement-wide level is applied)")
	CapabilityHook.off()


func _fresh(s: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), s)
	return w


func _run(s: int, days: float) -> World:
	var w := _fresh(s)
	var steps := int(days * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		w.update(0.5)
		w.player.hunger = 100.0
	return w


## Owner Q18-11B / X18-CAPCOMP: workforce experience and the facility-limited effective capability are kept apart by
## structure. No facility rule is approved, so the test sets a cap itself and takes it away again.
func test_effective_kept_apart() -> void:
	var e := WorkExperience.new()
	e.credit("npc:5", "smithing", 24.0 * DAY, 0.0)
	e.credit("npc:5", "smithing", 60.0, 2000.0)
	check(near(WorkExperience.facility_cap("smithing"), 10.0) and near(e.effective_level("npc:5", "smithing"), 10.0),
		"with no facility rule approved there is no limit: the effective level equals the experience level (10)")
	check(near(e.effective_level("npc:5", "smithing", 4.0), 4.0) and near(e.level("npc:5", "smithing"), 10.0) and near(e.days("npc:5", "smithing"), 24.0 + 60.0 / DAY),
		"a facility limit (4, set by the test) lowers the effective level only: the experience level and days stay")
	var caps: Dictionary = SettlementIndustries.data().facilities.caps
	caps["smithing"] = 4
	var wf := e.workforce("smithing", 2100.0)
	check(near(float(wf.level), 10.0) and near(float(wf.effective), 4.0), "the report shows both: workforce 10, effective 4")
	CapabilityHook.off()
	CapabilityHook.per_worker = true
	CapabilityHook.experience = e
	var w := _fresh(1)
	var n: NPC = w.npcs.filter(func(o): return o.alive and o.role == "adult")[0]
	e.minutes[World.npc_ref(n.id)] = e.minutes["npc:5"].duplicate()
	check(near(CapabilityHook.time(100.0, "smithing", n), 100.0 / SettlementIndustries.output_multiplier("smithing", 4, "", true)),
		"the prepared per-worker path reads the effective level (4), not the experience level")
	caps.erase("smithing")
	check(near(CapabilityHook.time(100.0, "smithing", n), 100.0 / 1.15) and near(e.level(World.npc_ref(n.id), "smithing"), 10.0),
		"the limit lifted, the same worker is back at 10: nothing was erased")
	CapabilityHook.off()


## Production compatibility: on the prepared per-worker path (switched on here only) the real mining and felling steps
## take each worker's own time; the seam and the forest give exactly what they held. Off, nothing changes.
func test_production_compat() -> void:
	var w := _fresh(1)
	var ad: Array = w.npcs.filter(func(o): return o.alive and o.role == "adult")
	var master: NPC = ad[0]
	var apprentice: NPC = ad[1]
	w.experience.credit(World.npc_ref(master.id), "mining", 12.0 * DAY, 0.0)
	var seam: Dictionary = {}
	for d in w.deposits:
		if str(d.ore) == "iron_ore" and int(d.amount) > 0:
			seam = d
			break
	CapabilityHook.off()
	var off_m := float(w.brain.seam_steps(master, seam, "mine", {})[-1].min)
	var off_a := float(w.brain.seam_steps(apprentice, seam, "mine", {})[-1].min)
	CapabilityHook.per_worker = true
	CapabilityHook.experience = w.experience
	var on_m := float(w.brain.seam_steps(master, seam, "mine", {})[-1].min)
	var on_a := float(w.brain.seam_steps(apprentice, seam, "mine", {})[-1].min)
	check(on_m < off_m and near(on_a, off_a), "a level-10 miner's swing is shorter (%.1f against %.1f min); the apprentice's is their own (%.1f)" % [on_m, off_m, on_a])
	seam.amount = 2
	var got := 0
	for i in 6:
		got += int(w.work_mine(master, seam, master.inv).get("n", 0))
	check(got == 2 and int(seam.amount) == 0, "and the seam gives its 2 ore and no more")
	CapabilityHook.off()
	check(near(float(w.brain.seam_steps(master, seam, "mine", {})[-1].min), off_m), "off again: the existing time exactly")


## CON-01/CON-02: capability modifiers never touch negotiated terms. The contract code calls the hook only for a work
## time (felling a tree it was hired for), never for a price, quantity, wage or deadline; and contract work earns
## experience like any other work of its kind.
func test_contract_compat() -> void:
	var bad := []
	for path in ["res://scripts/core/contracts.gd", "res://scripts/core/contract_services.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for line in src.split("\n"):
			if "CapabilityHook." in line and not "CapabilityHook.work_time(" in line:
				bad.append(line.strip_edges().left(80))
			if "CapabilityHook.pay(" in line:
				bad.append(line.strip_edges().left(80))
	check(bad.is_empty(), "the contract code applies no pay modifier and no capability term: only the work time of felling %s" % str(bad))
	check(WorkExperience.industry_of_step("chop", {}) == "forestry" and WorkExperience.industry_of_step("mine", {}) == "mining"
		and WorkExperience.industry_of_step("svc_step", {"id": 1}) == "",
		"a contract's felling and mining earn experience as any felling and mining; service-contract steps (pit digging, surveys) are unattributed (open)")
	var t := {"hire": true, "wage": 8}
	CapabilityHook.off()
	CapabilityHook.forced = {"farming": 10, "mining": 10, "forestry": 10}
	check(Quests.promised(t) == 8, "a hired job other than the harvest keeps its stated wage, whatever the level")
	CapabilityHook.off()


func test_report() -> void:
	var w := _run(1, 1.0)
	var r := SettlementReport.village(w)
	var wf: Dictionary = r.workforce
	check(wf.size() == 7 and wf.has("trade") and str(wf.trade.status) == "no active workers",
		"the settlement report lists the seven industries' workforce; trade reports \"no active workers\" (no attributed trade hours)")
	check(str(wf.mining.status) == "ok" and near(float(wf.mining.level), float(wf.mining.effective)),
		"mining reports its workforce level %.3f, the effective average equal while no facility rule exists" % float(wf.mining.level))
