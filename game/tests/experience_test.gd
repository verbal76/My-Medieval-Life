extends SceneTree
## PROSPECTIVE (Expansion 18, X18-CAPCOMP part 1; owner decision 2026-10-22): each person's industry experience from the
## hours they work (WorkExperience), the caps, the straight-line individual level, the hours-weighted workforce level of
## the last season (a report only), experience leaving with the person, the save section, and the prepared per-worker
## hook path, which the owner's answers (2026-10-23) have switched on (test_switched_on and after).
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
	test_d1_formula()
	test_d1_farming()
	test_d1_once()
	test_d1_old_save()
	test_d1_determinism()
	test_switched_on()
	test_d6_wages()
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
		and m.call("fp_work", {"task": "till"}) == "farming" and m.call("mj_step", {}, "mend") == "carpentry" and m.call("hunt") == "",
		"farm tasks the owner listed are farming; mending is carpentry; hunting is none")
	# owner D4 (2026-10-23, "Use the table"): slaughter, clearing ground, fencing farmland -> farming; survey, trial pits,
	# excavation, tunnelling, shoring, backfill, service-contract digging -> mining; hunting, foraging, picking, building,
	# hauling, carting -> none
	check(m.call("slaughter") == "farming" and m.call("fp_work", {"task": "clear"}) == "farming" and m.call("fp_fence") == "farming",
		"D4: slaughter, clearing ground and fencing farmland are farming")
	var mine_kinds := true
	for k in ["survey", "trial", "excavate", "tunnel", "shore", "backfill"]:
		mine_kinds = mine_kinds and m.call("mj_step", {}, k) == "mining"
	check(mine_kinds and m.call("svc_step", {"id": 1}) == "mining" and m.call("prospect") == "mining",
		"D4: survey, trial pits, excavation, tunnelling, shoring, backfill and service-contract digging are mining")
	var none_ok := true
	for a in ["hunt", "forage", "pick_fruit", "build_front", "build_stall", "cart_hitch", "cart_load", "mc_load", "assay"]:
		none_ok = none_ok and m.call(a) == ""
	check(none_ok and m.call("mj_step", {}, "haul") == "", "D4: hunting, foraging, picking, building, hauling and carting earn nothing")


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
	var per := {}
	for h in a.experience.recent:
		for k in a.experience.recent[h]:
			for ind in a.experience.recent[h][k]:
				per[k] = float(per.get(k, 0.0)) + float(a.experience.recent[h][k][ind])
	var most := 0.0
	for k in per:
		most = maxf(most, float(per[k]))
	check(not per.is_empty() and most <= 1440.0 + 1e-6, "no one is credited more hours than the day has (most %.0f minutes; %d workers)" % [most, per.size()])


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
	check(fresh.to_dict().has(WorkExperience.KEY) and bool(fresh.to_dict()[WorkExperience.KEY].seeded),
		"a new world saves the section, marked seeded (owner D1)")
	var w := _run(2, 0.5)
	var d := w.to_dict()
	check(d.has(WorkExperience.KEY) and str(d[WorkExperience.KEY].format) == WorkExperience.FORMAT, "the save carries the optional section")
	var back: Dictionary = JSON.parse_string(JSON.stringify(d))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), back)
	check(JSON.stringify(w2.experience.to_dict()) == JSON.stringify(w.experience.to_dict()), "the record round-trips through a JSON save")
	back.erase(WorkExperience.KEY)
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), back)
	check(w3.experience.seeded and w3.total_coins() == w.total_coins(), "a save without the section (every older save) loads and is given its starting experience once (D1)")
	back[WorkExperience.KEY] = {"format": "mml-x18-experience/99", "who": "knows"}
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), back)
	check(w4.to_dict()[WorkExperience.KEY] == back[WorkExperience.KEY], "a section of an unknown format is kept as it was, never reinterpreted or dropped")


func test_per_worker_path() -> void:
	var w := _fresh(1)
	var master: NPC = _novice(w, "smithing", 0)
	var apprentice: NPC = _novice(w, "smithing", 1)
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


## The `i`-th living adult with no experience in `industry` (no starting experience: no xp in its skill).
func _novice(w: World, industry: String, i: int) -> NPC:
	var out: Array = w.npcs.filter(func(o): return o.alive and o.role == "adult" and w.experience.days(World.npc_ref(o.id), industry) == 0.0)
	return out[i]


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
	var w := _fresh(1)
	CapabilityHook.off()
	CapabilityHook.per_worker = true
	CapabilityHook.experience = e
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
	var master: NPC = _novice(w, "mining", 0)
	var apprentice: NPC = _novice(w, "mining", 1)
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
		and WorkExperience.industry_of_step("svc_step", {"id": 1}) == "mining",
		"a contract's felling and mining earn experience as any felling and mining; service-contract steps (pit digging, surveys) are mining (owner D4)")
	var t := {"hire": true, "wage": 8}
	CapabilityHook.off()
	CapabilityHook.forced = {"farming": 10, "mining": 10, "forestry": 10}
	check(Quests.promised(t) == 8, "a hired job other than the harvest keeps its stated wage, whatever the level")
	CapabilityHook.off()


func test_report() -> void:
	var w := _run(1, 1.0)
	var r := SettlementReport.village(w)
	var wf: Dictionary = r.workforce
	check(wf.size() == 8 and wf.has("trade") and str(wf.trade.status) == "ok" and float(wf.trade.hours) > 0.0,
		"the settlement report lists the eight industries' workforce (masonry joined the seven, Q18-2); trade now has hours (the merchants keep the stall open, owner D4): %s" % str(wf.trade))
	check(str(wf.mining.status) == "ok" and near(float(wf.mining.level), float(wf.mining.effective)),
		"mining reports its workforce level %.3f, the effective average equal while no facility rule exists" % float(wf.mining.level))


# ------------------------------------------------------------------ owner D1 (2026-10-22): starting experience
## Starting days = cap x recorded skill level / 10, per industry, for each villager holding xp in the industry's skill.
func test_d1_formula() -> void:
	var w := _fresh(1)
	var bad := []
	var n_with := 0
	for n: NPC in w.npcs:
		if not n.alive or not n.role in ["adult", "elder"]:
			continue
		var k := World.npc_ref(n.id)
		for ind in WorkExperience.SKILL_OF:
			var xp := int(n.skills.get(str(WorkExperience.SKILL_OF[ind]), 0))
			var want := 0.0 if xp <= 0 else WorkExperience.cap_days(str(ind)) * float(Skills.level_of(xp)) / 10.0
			if not near(w.experience.days(k, str(ind)), want):
				bad.append("%s %s %.2f/%.2f" % [k, ind, w.experience.days(k, str(ind)), want])
			if want > 0.0:
				n_with += 1
	check(bad.is_empty() and n_with > 0, "every villager's starting days are cap x skill level / 10 in each industry (%d person-industries seeded) %s" % [n_with, str(bad.slice(0, 4))])
	var smiths: Array = w.npcs.filter(func(o): return o.alive and o.job == "smith")
	smiths.sort_custom(func(a, b): return Skills.level(a, "smithing") > Skills.level(b, "smithing"))
	var s8: NPC = smiths[0]
	var s6: NPC = smiths[1]
	check(Skills.level(s8, "smithing") == 8 and Skills.level(s6, "smithing") == 6
		and near(w.experience.days(World.npc_ref(s8.id), "smithing"), 19.2) and near(w.experience.days(World.npc_ref(s6.id), "smithing"), 14.4)
		and near(w.experience.level(World.npc_ref(s8.id), "smithing"), 8.0) and near(w.experience.level(World.npc_ref(s6.id), "smithing"), 6.0),
		"the seed-1 smiths (Skills 8 and 6) start with 19.2 and 14.4 smithing days: experience levels 8 and 6")
	check(near(w.experience.days(World.npc_ref(s8.id), "carpentry"), 0.0 if int(s8.skills.get("carpentry", 0)) <= 0 else WorkExperience.cap_days("carpentry") * Skills.level(s8, "carpentry") / 10.0),
		"industries are independent: a smith's carpentry start comes from their carpentry record only")
	check(not w.experience.minutes.has(WorkExperience.PLAYER), "the player gets no starting experience (PAR-01A: the player gets none)")
	check(w.experience.recent.is_empty(), "the starting experience is not recent work: nobody is active in the season's report until they work")
	var no_xp := true
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and int(n.skills.get("mining", 0)) <= 0 and w.experience.days(World.npc_ref(n.id), "mining") > 0.0:
			no_xp = false
	check(no_xp, "the level-1 floor of a skill never practised is no recorded history: no starting days (requirement 4)")


## Farming from the PAR-01A working-history rule, exactly as PAR-01A gives a trade skill.
func test_d1_farming() -> void:
	var w := _fresh(1)
	var c: Dictionary = GameData.b("skill_start")
	var farmers: Array = w.npcs.filter(func(o): return o.alive and o.role in ["adult", "elder"] and o.job == "farmer")
	var bad := []
	var rows := []
	for n: NPC in farmers:
		var xp: int = Skills.start_xp("miner", Life.npc_age(w, n), Skills.tenure_share(w, n)).get("mining", 0)   # PAR-01A's own computation, read through a trade
		var want := 0.0 if xp <= 0 else WorkExperience.cap_days("farming") * float(Skills.level_of(xp)) / 10.0
		var got := w.experience.days(World.npc_ref(n.id), "farming")
		rows.append("%.1f" % got)
		if not near(got, want):
			bad.append("%d %.2f/%.2f" % [n.id, got, want])
	check(not farmers.is_empty() and bad.is_empty(), "each farmer's farming start is what PAR-01A's tenure gives a trade (days %s) %s" % [", ".join(rows), str(bad)])
	var others := true
	for n: NPC in w.npcs:
		if n.alive and n.job != "farmer" and w.experience.days(World.npc_ref(n.id), "farming") > 0.0:
			others = false
	check(others, "only farmers get a farming start (PAR-01A gives a trade's history to that trade only)")


## Once only; saved experience is never overwritten, reset or regenerated.
func test_d1_once() -> void:
	var w := _fresh(1)
	var before := JSON.stringify(w.experience.to_dict())
	w.experience.seed_once(w)
	check(JSON.stringify(w.experience.to_dict()) == before, "seeding again does nothing (marked seeded)")
	var k := World.npc_ref(_novice(w, "forestry", 0).id)
	w.experience.credit(k, "forestry", 300.0, w.minutes)
	var d := w.to_dict()
	var back: Dictionary = JSON.parse_string(JSON.stringify(d))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), back)
	check(near(w2.experience.days(k, "forestry"), 300.0 / DAY) and JSON.stringify(w2.experience.minutes) == JSON.stringify(w.experience.minutes),
		"a saved world loads with exactly its experience: nothing re-seeded or reset")
	var e := WorkExperience.new()
	e.credit("npc:1", "mining", 60.0, 0.0)
	e.seed_once(w)
	check(not e.seeded and e.minutes.size() == 1, "a record already holding experience (an earlier branch save) is never seeded over")
	var smith: NPC = w.npcs.filter(func(o): return o.alive and o.job == "smith")[0]
	var sk := World.npc_ref(smith.id)
	var sm := w.experience.days(sk, "smithing")
	w.experience.credit(sk, "mining", 480.0, w.minutes)
	check(near(w.experience.days(sk, "smithing"), sm), "starting experience is kept when the person works another industry")


## An older save (no section): migrated once on load, the same as a new world's settlers would get.
func test_d1_old_save() -> void:
	var w := _fresh(3)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var want := JSON.stringify(d[WorkExperience.KEY].minutes)
	d.erase(WorkExperience.KEY)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.experience.seeded and JSON.stringify(w2.experience.minutes) == want,
		"an older save without experience records gets the same starting experience on load as at the world's creation")
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d2)
	check(JSON.stringify(w3.experience.to_dict()) == JSON.stringify(w2.experience.to_dict()), "and once saved, it round-trips unchanged")
	var d0 := {"format": WorkExperience.FORMAT_0, "minutes": {"npc:1": {"mining": 120.0}}, "recent": {}}
	d2[WorkExperience.KEY] = d0
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), d2)
	check(not w4.experience.seeded and w4.experience.minutes.size() == 1 and near(w4.experience.days("npc:1", "mining"), 0.25),
		"a section written before D1 (format 0) keeps its records and is not seeded over")


## Deterministic: the same seed gives the same starting experience; the world itself is unchanged by it.
func test_d1_determinism() -> void:
	var a := _fresh(4)
	var b := _fresh(4)
	check(JSON.stringify(a.experience.to_dict()) == JSON.stringify(b.experience.to_dict()), "the same seed gives the same starting experience")
	var d := a.to_dict()
	d.erase(WorkExperience.KEY)
	var e := b.to_dict()
	e.erase(WorkExperience.KEY)
	check(JSON.stringify(d) == JSON.stringify(e), "and the rest of the saved world is the same")


# ------------------------------------------------------------------ owner answers 2026-10-23 (D2-D9): the hook is ON
func test_switched_on() -> void:
	# D5: a real-valued level reads between the whole levels around it
	var m7 := SettlementIndustries.output_multiplier("smithing", 7.0, "approved", true)
	var m8 := SettlementIndustries.output_multiplier("smithing", 8.0, "approved", true)
	check(near(SettlementIndustries.output_multiplier("smithing", 7.3, "approved", true), m7 + 0.3 * (m8 - m7))
		and near(SettlementIndustries.pay_multiplier("farming", 2.5, "approved", true),
			0.5 * (SettlementIndustries.pay_multiplier("farming", 2.0, "approved", true) + SettlementIndustries.pay_multiplier("farming", 3.0, "approved", true)))
		and near(SettlementIndustries.output_multiplier("smithing", 11.0, "approved", true), SettlementIndustries.output_multiplier("smithing", 10.0, "approved", true)),
		"D5: 7.3 takes 30%% of the way from level 7 to 8 (no floor); beyond 10 reads 10")
	# D3: bands name the levels for the player; they gate nothing
	check(WorkExperience.band(0.0) == "novice" and WorkExperience.band(2.99) == "novice" and WorkExperience.band(3.0) == "journeyman"
		and WorkExperience.band(6.99) == "journeyman" and WorkExperience.band(7.0) == "master" and WorkExperience.band(10.0) == "master",
		"D3: novice below 3, journeyman 3 to below 7, master 7 and above")
	# D2: effective = experience; the wear seam exists and today limits nothing
	check(near(WorkExperience.wear_cap("smithing", "npc:1"), 10.0), "D2: the wear cap seam limits nothing yet")
	# the game's own world binds the hook to its record
	var w := _fresh(1)
	check(CapabilityHook.per_worker and CapabilityHook.experience == w.experience, "the capability hook is on and reads the world's experience record")
	var smith: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "smith" and w.experience.level(World.npc_ref(n.id), "smithing") > 5.0:
			smith = n
			break
	var novice: NPC = _novice(w, "smithing", 0)
	if smith != null:
		var lv := w.experience.effective_level(World.npc_ref(smith.id), "smithing")
		check(near(CapabilityHook.time(100.0, "smithing", smith), 100.0 / SettlementIndustries.output_multiplier("smithing", lv, "", true))
			and CapabilityHook.time(100.0, "smithing", smith) < 100.0 and near(CapabilityHook.time(100.0, "smithing", novice), 100.0),
			"a seeded smith (level %.1f) works faster at their own level; a villager with none works at the base time" % lv)
	else:
		check(false, "seed 1 has an experienced smith")
	# the player's own record is their own (none seeded)
	check(near(CapabilityHook.time(100.0, "farming", w.player), 100.0), "the player starts at the base time (no starting experience)")
	w.experience.credit(WorkExperience.PLAYER, "farming", 18.0 * DAY, 0.0)
	check(near(CapabilityHook.time(100.0, "farming", w.player), 100.0 / 1.1), "and earns it by working: farming experience shortens the player's own farm work")
	# D4: a merchant's hours at the stall are trade experience (a day of the live world)
	var d := _run(1, 1.0)
	var tr: Dictionary = d.experience.workforce("trade", d.minutes)
	check(str(tr.status) == "ok" and float(tr.hours) > 0.0, "D4: trade hours accrue from the merchants keeping the stall (%s h)" % str(snappedf(float(tr.get("hours", 0.0)), 0.1)))
	# an analysis run (forced levels alone) leaves the per-worker path unbound
	CapabilityHook.off()
	CapabilityHook.analysis = true
	var a := _fresh(1)
	check(not CapabilityHook.per_worker and CapabilityHook.experience == null, "analysis runs keep the forced levels alone (bind does nothing)")
	CapabilityHook.off()
	a = null


## D6 and D8: a posted manor job carries the base wage; the wage is fixed when it is taken, at the taker's own effective
## level, rounded to the nearest coin; the treasury check and the sum set aside move to acceptance.
func test_d6_wages() -> void:
	var w := _fresh(1)
	var mw := w.manor_work
	w.treasury = 5000
	mw.jobs.clear()
	var lab: Array = w.npcs.filter(func(o): return o.alive and o.role == "adult" and not mw.is_staff(World.npc_ref(o.id)))
	var master: NPC = lab[0]
	var novice: NPC = lab[1]
	w.experience.minutes.erase(World.npc_ref(master.id))
	w.experience.minutes.erase(World.npc_ref(novice.id))
	w.experience.credit(World.npc_ref(master.id), "mining", 12.0 * DAY, 0.0)
	mw._post({"kind": "quarry", "item": "stone", "qty": 2, "wage": 100})
	mw._post({"kind": "quarry", "item": "stone", "qty": 2, "wage": 100})
	var base_mult := SettlementIndustries.pay_multiplier("mining", 10.0, "", true)
	check(int(mw.jobs[0].wage) == 100 and mw.wage_for(mw.jobs[0], World.npc_ref(master.id)) == roundi(100.0 * base_mult)
		and mw.wage_for(mw.jobs[0], World.npc_ref(novice.id)) == 100 and roundi(100.0 * base_mult) == 102,
		"the posted wage is the base (100); the master's wage when taken is 102 (+2%% at level 10, nearest coin), the novice's 100")
	var held := w.treasury
	check(mw.take(mw.jobs[0], World.npc_ref(master.id)) and int(mw.jobs[0].reserved) == 102 and w.treasury == held - 102,
		"the master takes it: 102 is set aside from the treasury at acceptance (one payment, no new money)")
	var held2 := w.treasury
	check(mw.take(mw.jobs[1], World.npc_ref(novice.id)) and int(mw.jobs[1].reserved) == 100 and w.treasury == held2 - 100, "the novice takes the other: 100 set aside")
	# the treasury check is at acceptance, with the taker's wage: a chest that can spare 100 but not 102
	var j1: Dictionary = mw.jobs[1]
	mw.release(mw.jobs[0])
	mw.release(j1)
	check(w.treasury == held, "released, both wages are back in the treasury (%d)" % w.treasury)
	mw.jobs.clear()
	mw._post({"kind": "quarry", "item": "stone", "qty": 2, "wage": 100})
	var reserve_need: float = w.brain.daily_obligations() * float(GameData.b("manor_job_reserve_days"))
	w.treasury = int(ceil(reserve_need)) + 101
	check(mw.can_fund(mw.jobs[0], World.npc_ref(novice.id)) and not mw.can_fund(mw.jobs[0], World.npc_ref(master.id)),
		"a chest that can spare 100 pays the novice's wage but not the master's 102: the check is made for the taker")
	# D8: small wages round to the nearest coin, as now (6 * 1.0 + fraction stays 6)
	w.experience.credit(World.npc_ref(master.id), "farming", 18.0 * DAY, 0.0)
	check(CapabilityHook.pay(6, "farming", master) == 6 and CapabilityHook.pay(50, "farming", master) == 52 and CapabilityHook.pay(50, "farming", novice) == 50,
		"D8: 6 coins at +4%% (6.24) stays 6, 50 becomes 52: the nearest whole coin, no carried fractions")
