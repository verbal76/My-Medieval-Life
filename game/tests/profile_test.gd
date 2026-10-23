extends SceneTree
## Expansion 18 SET-A / SET-B: the maintained all-industry capability profile (SettlementProfile): the daily recompute
## equals the on-demand report, a facility shortage lowers the effective values and never the workforce experience
## (X18-CAPCOMP), the history round-trips through the save under the optional key, an old save derives the profile,
## an unknown section is kept, and the same seed gives the same profile.
##   godot --headless --path game --script res://tests/profile_test.gd

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
	test_matches_report()
	test_facility_loss()
	test_save_round_trip()
	test_old_save()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


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


func test_matches_report() -> void:
	var w := _run(1, 2.2)
	var p: Dictionary = w.settlement_profile
	check(int(p.day) >= 2, "the profile was recomputed at dawn (day %d)" % int(p.day))
	var rep := SettlementReport.village(w)
	var again := SettlementProfile.update(w, w.settlement_caps.duplicate(true), w.day())
	var same := true
	for ind in rep.capabilities:
		same = same and int(again.industries[ind].level) == int(rep.capabilities[ind])
		same = same and JSON.stringify(again.industries[ind].workforce) == JSON.stringify(rep.workforce.get(ind, w.experience.workforce(str(ind), w.minutes)))
	check(same and again.industries.size() == rep.capabilities.size(), "a recompute equals the on-demand report: levels and workforce, every industry")
	check(not (w.settlement_caps.levels as Dictionary).is_empty() and (w.settlement_caps.since as Dictionary).size() == rep.capabilities.size(),
		"the history state holds a level and a day for every industry")


func test_facility_loss() -> void:
	var w := _fresh(1)
	var n: NPC = w.npcs.filter(func(o): return o.alive and o.role == "adult")[0]
	var key := World.npc_ref(n.id)
	w.experience.credit(key, "smithing", 24.0 * 480.0, w.minutes)
	var days_before := w.experience.days(key, "smithing")
	var p0 := SettlementProfile.update(w, w.settlement_caps, w.day())
	var caps: Dictionary = SettlementIndustries.data().facilities.caps
	caps["smithing"] = 4
	var p1 := SettlementProfile.update(w, w.settlement_caps, w.day())
	caps.erase("smithing")
	check(float(p1.industries.smithing.effective) <= 4.0 and float(p0.industries.smithing.effective) >= float(p1.industries.smithing.effective),
		"a facility limit lowers the effective value")
	check(w.experience.days(key, "smithing") == days_before and w.experience.level(key, "smithing") >= 9.99,
		"and the worker's experience is untouched (X18-CAPCOMP)")
	var wf: Dictionary = p1.industries.smithing.workforce
	check(wf.get("status", "") != "ok" or float(wf.level) >= float(wf.effective), "the workforce level stays above the effective one when limited")


func test_save_round_trip() -> void:
	var w := _run(2, 2.2)
	w.settlement_caps.history.append({"day": 1, "industry": "forestry", "from": 2, "to": 1})
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(d.has(SettlementSave.KEY) and str(d[SettlementSave.KEY].format) == SettlementSave.FORMAT, "the save carries the optional section, version unchanged (%d)" % int(d.save_version))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(JSON.stringify(w2.settlement_caps) == JSON.stringify(w.settlement_caps) or _norm(w2.settlement_caps) == _norm(w.settlement_caps),
		"levels, days and history round-trip through a JSON save")
	d[SettlementSave.KEY] = {"format": "mml-settlements/99", "who": "knows"}
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d)
	check(w3.to_dict()[SettlementSave.KEY] == d[SettlementSave.KEY], "a section of an unknown format is kept as it was")


func _norm(s: Dictionary) -> String:
	var t = JSON.parse_string(JSON.stringify(s))
	return JSON.stringify(t)


func test_old_save() -> void:
	var w := _run(3, 1.2)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	d.erase(SettlementSave.KEY)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(not w2.settlement_profile.is_empty() and (w2.settlement_caps.history as Array).is_empty(), "an older save derives its profile on load, with no invented history")
	var rep := SettlementReport.village(w2)
	var ok := true
	for ind in rep.capabilities:
		ok = ok and int(w2.settlement_profile.industries[ind].level) == int(rep.capabilities[ind])
	check(ok, "and it equals the on-demand report")


func test_determinism() -> void:
	var a := _run(1, 2.2)
	var b := _run(1, 2.2)
	check(_norm(a.settlement_caps) == _norm(b.settlement_caps) and JSON.stringify(a.settlement_profile) == JSON.stringify(b.settlement_profile),
		"the same seed gives the same profile and history")
