extends SceneTree
## PROSPECTIVE (Expansion 18, Q18-11 framework; PROS-18; wip/expansion18-preparation): capability levels 0-10, separate
## pay and output multipliers from data profiles (active = neutral; candidates for analysis only), the output safeguard
## (faster work, never raw materials from nothing) on real recipes and existing work times, and the no-double-counting rule
## between settlement capability (place-specific) and individual Skills (portable). Owner master directive 2026-10-21,
## section 10 items 1, 2, 4, 5, 6, 7, 8, 11.
##   godot --headless --path game --script res://tests/capability_test.gd

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
	test_levels_0_to_10()
	test_active_is_neutral()
	test_pay_and_output_separate()
	test_industries_differ()
	test_mining_safeguard()
	test_crafting_safeguard()
	test_farming_safeguard()
	test_pay_is_conserved()
	test_no_double_counting()
	test_never_blocks()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func near(a: float, b: float) -> bool:
	return absf(a - b) < 1e-6


# 1. levels 0-10
func test_levels_0_to_10() -> void:
	check(SettlementIndustries.max_level() == 10, "the capability scale runs 0-10")
	var d := SettlementIndustries.data().duplicate(true)
	var lv := []
	for i in 10:
		lv.append({"level": i + 1, "name": "step %d" % (i + 1), "needs": [{"kind": "practitioners", "jobs": ["weaver"], "count": i + 1}]})
	d.industries["weaving"] = {"name": "Weaving", "levels": lv}
	check(SettlementIndustries.validate(d).is_empty(), "an industry with ten levels validates")
	var prac := []
	for i in 10:
		prac.append({"job": "weaver", "skills": {}})
	check(SettlementIndustries.levels({"practitioners": prac}, d).weaving == 10, "ten weavers reach level 10")
	check(SettlementIndustries.levels({"practitioners": []}, d).weaving == 0, "none: level 0, the baseline")
	var d11 := d.duplicate(true)
	(d11.industries.weaving.levels as Array).append({"level": 11, "name": "too far", "needs": []})
	check(SettlementIndustries.validate(d11).any(func(p): return "beyond the 0-10 scale" in p), "a level 11 is refused")
	for prof in SettlementIndustries.profile_names():
		var ok := true
		var prev := 0.0
		for l in 11:
			var m := SettlementIndustries.output_multiplier("smithing", l, prof)
			if m < prev - 1e-9 or m < 1.0:
				ok = false
			prev = m
		check(ok and near(SettlementIndustries.output_multiplier("smithing", 0, prof), 1.0),
			"profile %s: level 0 is the baseline (1.0) and the multiplier never falls as the level rises" % prof)
	check(near(SettlementIndustries.output_multiplier("smithing", 15, "owner_candidate"), SettlementIndustries.output_multiplier("smithing", 10, "owner_candidate")),
		"a level above 10 is read as 10")
	# the owner's example table, exactly (master directive section 5)
	var table := [0.0, 3.6, 6.8, 9.6, 12.0, 14.0, 15.8, 17.2, 18.4, 19.4, 20.0]
	var exact := true
	for l in 11:
		if not near((SettlementIndustries.output_multiplier("carpentry", l, "owner_candidate") - 1.0) * 100.0, table[l]) \
				or not near((SettlementIndustries.pay_multiplier("carpentry", l, "owner_candidate") - 1.0) * 100.0, table[l] * 0.4):
			exact = false
	check(exact, "the owner_candidate profile reproduces the owner's example table (output +3.6% ... +20%, pay +1.44% ... +8%)")


func test_active_is_neutral() -> void:
	check(SettlementIndustries.active_profile() == "neutral", "the active profile is neutral (no approved numbers, Q18-11A)")
	var all_one := true
	for ind in SettlementIndustries.data().industries:
		for l in 11:
			if SettlementIndustries.output_multiplier(ind, l) != 1.0 or SettlementIndustries.pay_multiplier(ind, l) != 1.0:
				all_one = false
	check(all_one, "with the active profile every industry's pay and output multiplier is 1.0 at every level")
	var labels_ok := true
	for p in SettlementIndustries.profile_names():
		var lab := str(SettlementIndustries.data().effects.profiles[p].label)
		if p != "neutral" and not lab.begins_with("UNAPPROVED"):
			labels_ok = false
	check(labels_ok, "every candidate profile is labelled UNAPPROVED")


# 4. pay and output separate
func test_pay_and_output_separate() -> void:
	var o := SettlementIndustries.output_multiplier("smithing", 10, "owner_candidate")
	var p := SettlementIndustries.pay_multiplier("smithing", 10, "owner_candidate")
	check(near(o, 1.20) and near(p, 1.08), "at level 10 the candidate gives output x%.2f and pay x%.2f, two separate numbers" % [o, p])
	var eff: Dictionary = SettlementIndustries.data().effects
	var saved := float(eff.profiles.owner_candidate.pay_ratio)
	eff.profiles.owner_candidate.pay_ratio = 0.0
	check(near(SettlementIndustries.output_multiplier("smithing", 10, "owner_candidate"), o) and near(SettlementIndustries.pay_multiplier("smithing", 10, "owner_candidate"), 1.0),
		"changing the pay curve leaves the output curve as it was")
	eff.profiles.owner_candidate.pay_ratio = saved
	check(SettlementProductivity.adjusted_pay(6, "smithing", 10, "owner_candidate") == roundi(6 * 1.08) and SettlementProductivity.adjusted_pay(6, "smithing", 10) == 6,
		"AdjustedPay = BasePay (the existing helper wage, 6) x PayMultiplier; the active profile pays the base")


# 5. different industries, different modifiers
func test_industries_differ() -> void:
	var sm := SettlementIndustries.output_multiplier("smithing", 10, "differentiated")
	var fo := SettlementIndustries.output_multiplier("forestry", 10, "differentiated")
	var fo4 := SettlementIndustries.output_multiplier("forestry", 4, "differentiated") - 1.0
	var sm4 := SettlementIndustries.output_multiplier("smithing", 4, "differentiated") - 1.0
	check(sm > fo, "the differentiated candidate gives a complex craft a larger total (smithing x%.2f) than simple work (forestry x%.2f)" % [sm, fo])
	check(fo4 / (fo - 1.0) > sm4 / (sm - 1.0), "and simple work reaches more of its gain early (forestry %.0f%% by level 4, smithing %.0f%%)" % [100.0 * fo4 / (fo - 1.0), 100.0 * sm4 / (sm - 1.0)])
	check(near(SettlementIndustries.output_multiplier("mining", 10, "owner_candidate"), 1.0),
		"mining keeps 1.0 under every profile until MIN-D's stages 1-4 are mapped to 0-10 (a reconciliation item, not decided here)")


# 6, 7. the safeguard: mining depletes, never more than the deposit holds
func test_mining_safeguard() -> void:
	var base := float(GameData.b("mine_minutes"))
	var t0 := SettlementProductivity.unit_minutes(base, "smithing", 0, 1.0, "owner_candidate")
	var t10 := SettlementProductivity.unit_minutes(base, "smithing", 10, 1.0, "owner_candidate")
	check(near(t0, base) and near(t10, base / 1.2), "an output multiplier of 1.2 is 1/1.2 of the time a unit (%.1f -> %.1f minutes)" % [t0, t10])
	var d0 := {"ore": "iron_ore", "amount": 60}
	var d10 := {"ore": "iron_ore", "amount": 60}
	var i0 := Inventory.new()
	var i10 := Inventory.new()
	var r0 := SettlementProductivity.mine(d0, i0, 600.0, t0)
	var r10 := SettlementProductivity.mine(d10, i10, 600.0, t10)
	check(int(r10.made) > int(r0.made), "in ten hours the faster miner takes more (%d against %d)" % [int(r10.made), int(r0.made)])
	check(int(r0.made) + int(d0.amount) == 60 and int(r10.made) + int(d10.amount) == 60 and i10.count("iron_ore") == int(r10.made),
		"every unit came out of the seam: mined + left = 60 for both")
	var small := {"ore": "iron_ore", "amount": 7}
	var r := SettlementProductivity.mine(small, Inventory.new(), 6000.0, t10)
	check(int(r.made) == 7 and int(small.amount) == 0, "a level-10 miner cannot take more than the deposit holds (7 of 7, then nothing)")


func test_crafting_safeguard() -> void:
	for rid in ["smelt_iron", "forge_pickaxe", "saw_planks"]:
		var rec: Dictionary = GameData.recipes[rid]
		var ind := "carpentry" if str(rec.station) == "sawhorse" else "smithing"
		var stock := Inventory.new()
		for id in rec["in"]:
			stock.add(id, int(rec["in"][id]) * 10)
		var before := stock.items.duplicate()
		var t := SettlementProductivity.unit_minutes(float(rec.minutes), ind, 10, 1.0, "owner_candidate")
		var res := SettlementProductivity.craft(rid, stock, 100000.0, t)
		var ok := int(res.runs) == 10
		for id in rec["in"]:
			if int(res.used[id]) != int(rec["in"][id]) * int(res.runs) or stock.count(id) != int(before[id]) - int(res.used[id]):
				ok = false
		for id in rec["out"]:
			if int(res.made[id]) != int(rec["out"][id]) * int(res.runs):
				ok = false
		check(ok, "%s at level 10: %d runs from ten runs' inputs, every run took its full inputs %s and gave %s" % [rid, int(res.runs), str(rec["in"]), str(rec["out"])])
	var rec2: Dictionary = GameData.recipes["smelt_iron"]
	var st := Inventory.new()
	st.add("iron_ore", 5)
	st.add("coal", 9)
	var t2 := SettlementProductivity.unit_minutes(float(rec2.minutes), "smithing", 10, 1.0, "owner_candidate")
	var r2 := SettlementProductivity.craft("smelt_iron", st, 100000.0, t2)
	check(int(r2.runs) == 2 and st.count("iron_ore") == 1 and st.count("coal") == 7, "a level-10 smith with 5 ore smelts 2 bars and stops: it still needs full inputs")
	var tA := SettlementProductivity.unit_minutes(float(rec2.minutes), "smithing", 0, 1.0, "owner_candidate")
	var sA := Inventory.new()
	sA.add("iron_ore", 200)
	sA.add("coal", 100)
	var sB := sA.items.duplicate()
	var invB := Inventory.new()
	for id in sB:
		invB.add(id, int(sB[id]))
	var a := SettlementProductivity.craft("smelt_iron", sA, 480.0, tA)
	var b := SettlementProductivity.craft("smelt_iron", invB, 480.0, t2)
	check(int(b.runs) > int(a.runs) and int(b.used.iron_ore) == 2 * int(b.runs), "in a working day the faster smith smelts more (%d against %d), each with its full ore and coal" % [int(b.runs), int(a.runs)])


func test_farming_safeguard() -> void:
	var crop := int(GameData.b("field_yield"))
	var base := 90.0 / float(crop)       # the farmers' cut of a manor field (NPCBrain._farmer: 90 minutes) over its crop
	var f0 := {"crop": crop}
	var f10 := {"crop": crop}
	var i0 := Inventory.new()
	var i10 := Inventory.new()
	var r0 := SettlementProductivity.harvest(f0, i0, 10000.0, SettlementProductivity.unit_minutes(base, "farming", 0, 1.0, "owner_candidate"))
	var r10 := SettlementProductivity.harvest(f10, i10, 10000.0, SettlementProductivity.unit_minutes(base, "farming", 10, 1.0, "owner_candidate"))
	check(int(r0.made) == crop and int(r10.made) == crop, "a level-10 farm reaps the same %d wheat the field grew, no more" % crop)
	check(float(r10.minutes) < float(r0.minutes), "it only reaps it sooner (%.0f against %.0f minutes)" % [float(r10.minutes), float(r0.minutes)])


func test_pay_is_conserved() -> void:
	var buyer := SettlementLedger.make({"id": "b", "settlement": "b", "coins": 500, "needs": {"wheat": 5.0}, "can_travel": false})
	var seller := SettlementLedger.make({"id": "a", "settlement": "a", "coins": 0, "stock": {"wheat": 200}})
	var carter := SettlementLedger.make({"id": "b/carter", "settlement": "b", "kind": "carter", "transport": {"handcart": 1},
		"carts_for_hire": true, "capabilities": {"trade": 10}, "profile": "owner_candidate"})
	var ls := [buyer, seller, carter]
	var routes := TradeRoutes.table(ls, [["a", "b", 1200, {"road": 1.0}]])
	var p := RegionalMarket.plan(ls, routes)
	var base_fee := int(TradeRoutes.costed("a", "b", int(routes["a>b"].tiles), float(routes["a>b"].effective), "handcart").cost_per_unit)
	check(p.lines.size() > 0 and int(p.lines[0].fee_each) == int(ceil(base_fee * SettlementIndustries.pay_multiplier("trade", 10, "owner_candidate") - 1e-9)),
		"a level-10 carter's fee is the base fee x its pay multiplier (%d -> %d a unit)" % [base_fee, int(p.lines[0].fee_each) if p.lines.size() > 0 else -1])
	RegionalMarket.execute(p, ls)
	check(buyer.coins + seller.coins + carter.coins == 500 and RegionalMarket.matched(ls) == "", "and the higher pay comes from the buyer's purse: no coin created")


# 8. no double counting
func test_no_double_counting() -> void:
	var base := float(GameData.b("mine_minutes"))
	var t6 := Skills.value_at(6, "mining", "mine_time", 1.0)
	check(t6 < 1.0, "the live Skills already shorten a miner's swing (mine_time %.2f at mining 6)" % t6)
	check(near(SettlementProductivity.unit_minutes(base, "smithing", 10, t6), base * t6),
		"with the active profile the settlement adds nothing: the time is exactly the Skills' own (base x %.2f)" % t6)
	var g_skill := 1.0 / t6 - 1.0
	var g_place := SettlementIndustries.output_multiplier("smithing", 10, "owner_candidate") - 1.0
	var both := SettlementProductivity.unit_minutes(base, "smithing", 10, t6, "owner_candidate")
	check(near(both, base / (1.0 + g_skill + g_place)) and both > base * t6 / (1.0 + g_place),
		"the portable (skill, +%.0f%%) and place-specific (settlement, +%.0f%%) gains add over the base, each once; they do not compound" % [g_skill * 100.0, g_place * 100.0])
	var overlap := SettlementProductivity.SETTLEMENT_EFFECTS.filter(func(e): return Skills.EFFECTS.has(e) or SettlementProductivity.SKILL_QUANTITY_EFFECTS.has(e))
	check(overlap.is_empty(), "the settlement acts only on unit time and pay, never on the Skills' quantity effects (extra ore, saved inputs, bonus units)")
	var all_known := SettlementProductivity.SKILL_QUANTITY_EFFECTS.all(func(e): return Skills.EFFECTS.has(e))
	check(all_known, "the quantity effects it leaves alone are real Skills.EFFECTS keys")


# 2. never blocking
func test_never_blocks() -> void:
	var dep := {"ore": "coal", "amount": 5}
	var r := SettlementProductivity.mine(dep, Inventory.new(), 200.0, SettlementProductivity.unit_minutes(25.0, "smithing", 0, 1.0, "owner_candidate"))
	check(int(r.made) == 5, "at level 0 a miner with a seam and time still mines (5 of 5)")
	var st := Inventory.new()
	st.add("log", 3)
	var c := SettlementProductivity.craft("saw_planks", st, 1000.0, SettlementProductivity.unit_minutes(20.0, "carpentry", 0))
	check(int(c.runs) == 3 and st.count("plank") == 6, "at level 0 a carpenter with logs still saws planks")


# 11. determinism
func test_determinism() -> void:
	var a := []
	var b := []
	for prof in SettlementIndustries.profile_names():
		for ind in ["smithing", "farming", "forestry"]:
			for l in 11:
				a.append(SettlementIndustries.output_multiplier(ind, l, prof))
				b.append(SettlementIndustries.output_multiplier(ind, l, prof))
	check(a == b, "the same profile, industry and level always give the same multiplier (%d values)" % a.size())
