extends SceneTree
## PROSPECTIVE (Expansion 18, Q18-11 framework; PROS-18; wip/expansion18-preparation): capability levels 0-10, separate
## pay and output multipliers from data profiles (active = the owner's approved numbers, X18-CAPNUM; neutral the baseline;
## candidates for analysis only), the output safeguard
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
	test_active_is_approved()
	test_pay_and_output_separate()
	test_industries_differ()
	test_mining_safeguard()
	test_crafting_safeguard()
	test_farming_safeguard()
	test_pay_is_conserved()
	test_no_double_counting()
	test_never_blocks()
	test_determinism()
	test_hook()
	test_capnum_durations()
	test_capnum_farm_sites()
	test_capnum_farm_pay()
	test_capnum_ledger_yield()
	test_capnum_determinism()
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


## X18-CAPNUM (owner, Q18-11A closed 2026-10-22): the active profile is the owner's approved numbers; neutral stays the
## comparison baseline; every other profile is labelled UNAPPROVED or SUPERSEDED.
func test_active_is_approved() -> void:
	check(SettlementIndustries.active_profile() == "approved", "the active profile is the owner's approved one (X18-CAPNUM)")
	var all_one := true
	for ind in SettlementIndustries.data().industries:
		for l in 11:
			if SettlementIndustries.output_multiplier(ind, l, "neutral") != 1.0 or SettlementIndustries.pay_multiplier(ind, l, "neutral") != 1.0:
				all_one = false
	check(all_one, "the neutral profile (the baseline) is 1.0 for every industry at every level")
	var labels_ok := true
	for p in SettlementIndustries.profile_names():
		var lab := str(SettlementIndustries.data().effects.profiles[p].label)
		if p == "approved":
			labels_ok = labels_ok and lab.begins_with("APPROVED")
		elif p != "neutral" and not (lab.begins_with("UNAPPROVED") or lab.begins_with("SUPERSEDED")):
			labels_ok = false
	check(labels_ok, "the approved profile is labelled APPROVED; every other candidate UNAPPROVED or SUPERSEDED")
	# the owner's values at level 10: output (or farming's work rate) and pay = 0.4 of it
	var want := {"mining": [5.0, 2.0], "forestry": [5.0, 2.0], "trade": [10.0, 4.0], "tanning": [10.0, 4.0],
		"carpentry": [15.0, 6.0], "smithing": [15.0, 6.0], "farming": [10.0, 4.0]}
	var bad := []
	for ind in want:
		var o := (SettlementIndustries.output_multiplier(ind, 10, "approved", true) - 1.0) * 100.0
		var p := (SettlementIndustries.pay_multiplier(ind, 10, "approved", true) - 1.0) * 100.0
		if not near(o, want[ind][0]) or not near(p, want[ind][1]):
			bad.append("%s %.2f/%.2f" % [ind, o, p])
	check(bad.is_empty(), "approved at level 10: mining, forestry +5%%/+2%%; trade, tanning +10%%/+4%%; carpentry, smithing +15%%/+6%%; farming +10%% work rate/+4%% pay %s" % str(bad))
	# shapes: front-loaded for the simple trades, intermediate for trade, tanning and farming, the owner's for the crafts
	var sh: Dictionary = SettlementIndustries.data().effects.profiles.approved.shape
	check(sh.mining == "front_loaded" and sh.forestry == "front_loaded" and sh.trade == "intermediate" and sh.tanning == "intermediate"
		and sh.farming == "intermediate" and sh.carpentry == "owner_candidate" and sh.smithing == "owner_candidate", "each industry has its approved curve shape")
	# farming F1 as the owner approved it, levels 0-10 (the table is rounded to 0.1)
	var rate := [0.0, 2.5, 4.4, 5.9, 7.0, 7.8, 8.5, 9.1, 9.5, 9.8, 10.0]
	var pay := [0.0, 1.0, 1.8, 2.4, 2.8, 3.1, 3.4, 3.6, 3.8, 3.9, 4.0]
	var off := []
	for l in 11:
		var r := (SettlementIndustries.output_multiplier("farming", l, "approved") - 1.0) * 100.0
		var p := (SettlementIndustries.pay_multiplier("farming", l, "approved") - 1.0) * 100.0
		if absf(r - rate[l]) > 0.06 or absf(p - pay[l]) > 0.06:
			off.append("L%d %.3f/%.3f" % [l, r, p])
	check(off.is_empty(), "farming F1: work rate 0/2.5/.../10.0%% and pay 0/1.0/.../4.0%% at levels 0-10, within the table's rounding %s" % str(off))
	check(SettlementIndustries.yield_fixed("farming") and not SettlementIndustries.yield_fixed("smithing"),
		"farming's multiplier is a work rate only (yield fixed); the crafts' is faster output")


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
	check(near(SettlementProductivity.unit_minutes(base, "smithing", 10, t6, "neutral"), base * t6),
		"with the neutral profile the settlement adds nothing: the time is exactly the Skills' own (base x %.2f)" % t6)
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


# X18-SIM: the live hook is off in the game and, when an analysis run forces a level, only shortens work and raises
# the manor's quarry and mending wages; a level-10 miner in the real World still cannot take more than a seam holds.
func test_hook() -> void:
	CapabilityHook.off()
	check(CapabilityHook.work_time(25.0, "mining", 0.8) == 25.0 * 0.8 and CapabilityHook.pay(6, "mining") == 6 and CapabilityHook.time(90.0, "farming") == 90.0,
		"the hook is off in the game: every work time and wage is exactly the existing one")
	check(CapabilityHook.recipe_industry("smelt_iron") == "smithing" and CapabilityHook.recipe_industry("saw_planks") == "carpentry"
		and CapabilityHook.recipe_industry("tan_leather") == "tanning" and CapabilityHook.recipe_industry("build_handcart") == "carpentry"
		and CapabilityHook.recipe_industry("cook_pottage") == "", "recipes map to their industry by station and inputs; cooking has none (not faked)")
	CapabilityHook.forced = {"mining": 10, "carpentry": 10}
	CapabilityHook.profile = "aggressive"
	check(CapabilityHook.work_time(25.0, "mining", 1.0) < 25.0 and CapabilityHook.pay(6, "carpentry") > 6 and CapabilityHook.time(90.0, "farming") == 90.0,
		"forced: mining is faster, the mending wage higher; an industry not forced (farming) is untouched")
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var miner: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "miner":
			miner = n
			break
	var seam: Dictionary = {}
	for d in w.deposits:
		if str(d.ore) == "iron_ore" and int(d.amount) > 0:
			seam = d
			break
	seam.amount = 3
	var got := 0
	for i in 10:                                  # ten swings by a miner while mining is forced to level 10
		got += int(w.work_mine(miner, seam, miner.inv).get("n", 0))
	check(int(seam.amount) == 0 and got == 3, "a level-10 miner in the real World takes the seam's 3 ore and no more (%d taken, %d left)" % [got, int(seam.amount)])
	CapabilityHook.off()


# ------------------------------------------------------------------ X18-CAPNUM (owner, Q18-11A closed 2026-10-22)
const CAPNUM_INDUSTRIES := ["mining", "forestry", "trade", "tanning", "carpentry", "smithing", "farming"]


## Task durations and pay at levels 0, 5 and 10 for every industry, through the live hook with the approved profile:
## time = base / (1 + max x shape[L]); pay = base x (1 + 0.4 x max x shape[L]); level 0 changes nothing.
func test_capnum_durations() -> void:
	var prof: Dictionary = SettlementIndustries.data().effects.profiles.approved
	var shapes: Dictionary = SettlementIndustries.data().effects.shapes
	var bad := []
	var rows := []
	for ind in CAPNUM_INDUSTRIES:
		for l in [0, 5, 10]:
			CapabilityHook.off()
			CapabilityHook.forced = {ind: l}
			var g := float(prof.output_max[ind]) * float(shapes[str(prof.shape[ind])][l])
			var t := CapabilityHook.time(600.0, ind)
			var p := CapabilityHook.pay(1000, ind)
			if not near(t, 600.0 / (1.0 + g)) or p != roundi(1000.0 * (1.0 + 0.4 * g)) or (l == 0 and (t != 600.0 or p != 1000)):
				bad.append("%s L%d %.3f %d" % [ind, l, t, p])
			rows.append("%s L%d %.1f min %d" % [ind, l, t, p])
	CapabilityHook.off()
	print("     600-minute task / 1000-coin wage at levels 0, 5, 10: " + ", ".join(rows))
	check(bad.is_empty(), "every industry's task time and wage at levels 0, 5 and 10 follow the approved profile %s" % str(bad))
	CapabilityHook.forced = {"farming": 10}
	check(near(CapabilityHook.time(100.0, "farming"), 100.0 / 1.1) and CapabilityHook.time(100.0, "smithing") == 100.0,
		"farming at level 10 works 10%% faster (100 minutes -> %.1f); an industry not forced is untouched" % CapabilityHook.time(100.0, "farming"))
	CapabilityHook.off()


## The real farming sites in a live World (rule 3: durations fall with the effective level; rules 1-2: never more yield):
## the player's harvest, the pen keeper's feeding and collecting, the farmers' cutting of a manor field.
func test_capnum_farm_sites() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	# the player's harvest of a ripe cell: faster at level 10, the same goods
	var c := Vector2i(10, 10)
	w.farm.cells[c] = {"crop": "wheat", "state": "ripe", "progress": 1.0}
	var goods0 := w.farm.harvest_goods(c)
	CapabilityHook.off()
	var s0 := float(w.farm.plan({"act": "harvest", "cell": c}, w.player).get("secs", -1.0))
	CapabilityHook.forced = {"farming": 10}
	var pl := w.farm.plan({"act": "harvest", "cell": c}, w.player)
	var s10 := float(pl.get("secs", -1.0))
	var got: Dictionary = (pl.run.call() as Dictionary).get("items", {}) if pl.get("ok", false) else {}
	check(s0 > 0.0 and near(s10, s0 / 1.1), "the player's harvest takes %.2f s at level 10 against %.2f s" % [s10, s0])
	check(not goods0.is_empty() and got == goods0, "and yields exactly what the field gave at level 0 (%s; got %s)" % [str(goods0), str(got)])
	# the pen keeper: feeding and collecting (milk, eggs, wool)
	var keeper: NPC = null
	var pen := {}
	for n: NPC in w.npcs:
		if n.alive and n.job == "farmer" and not w.brain._keeper_pen(n).is_empty():
			keeper = n
			pen = w.brain._keeper_pen(n)
			break
	check(keeper != null, "a farmer keeps a pen")
	if keeper != null:
		pen.products = {}
		pen.trough = 0
		keeper.inv.add("wheat", 5)
		var mins := {}
		for l in [0, 5, 10]:
			CapabilityHook.off()
			CapabilityHook.forced = {"farming": l}
			w.brain._keeper(keeper)
			mins["feed%d" % l] = float(keeper.plan[-1].min)
			pen.products = {"egg": 2}
			w.brain._keeper(keeper)
			mins["collect%d" % l] = float(keeper.plan[-1].min)
			pen.products = {}
		var r5 := 1.0 + 0.1 * float(SettlementIndustries.data().effects.shapes.intermediate[5])
		check(near(mins.feed0, 15.0) and near(mins.feed5, 15.0 / r5) and near(mins.feed10, 15.0 / 1.1)
			and near(mins.collect0, 10.0) and near(mins.collect5, 10.0 / r5) and near(mins.collect10, 10.0 / 1.1),
			"feeding the pen and collecting its produce take less time with the level (%s)" % str(mins))
	# the farmers' cutting of a manor field
	var farmer: NPC = null
	var f := {}
	for n: NPC in w.npcs:
		if n.alive and n.job == "farmer" and not w.brain._field(n.workplace).is_empty() and w.brain._keeper_pen(n).is_empty():
			farmer = n
			f = w.brain._field(n.workplace)
			break
	check(farmer != null, "a farmer without a pen works a manor field")
	if farmer != null:
		f.state = "ripe"
		f.ripe_at = -100000.0
		var cut := {}
		for l in [0, 10]:
			CapabilityHook.off()
			CapabilityHook.forced = {"farming": l}
			w.brain._farmer(farmer)
			cut[l] = [str(farmer.plan[-1].get("act", "")), float(farmer.plan[-1].min)]
		check(cut[0][0] == "harvest" and cut[10][0] == "harvest" and near(float(cut[10][1]), float(cut[0][1]) / 1.1),
			"the farmers cut a ripe manor field faster at level 10 (%s)" % str(cut))
	CapabilityHook.off()


## Rules 4 and 7: pay applies to paid farm labour at a base rate the game sets (the harvest hand's wage); other hired work
## is not raised by the farming level, and neither is the price of grain.
func test_capnum_farm_pay() -> void:
	var t: Dictionary = {"hire": true, "harvest": 24, "wage": 50}
	var woods := {"hire": true, "wage": 50}
	CapabilityHook.off()
	check(Quests.promised(t) == 50 and Quests.promised(woods) == 50, "off: the harvest hand's wage is the template's")
	CapabilityHook.forced = {"farming": 10}
	check(Quests.promised(t) == 52 and Quests.promised(woods) == 50, "farming level 10: a 50-coin harvest wage becomes 52 (+4%); other hired work is unchanged")
	CapabilityHook.forced = {"farming": 5}
	check(Quests.promised(t) == roundi(50.0 * SettlementIndustries.pay_multiplier("farming", 5, "approved")),
		"level 5: 50 x %.4f" % SettlementIndustries.pay_multiplier("farming", 5, "approved"))
	CapabilityHook.forced = {"farming": 10}
	check(Quests.promised({"hire": true, "harvest": 24, "wage": 6}) == 6,
		"the real 6-coin harvest wage rounds back to 6 at level 10 (6 x 1.04 = 6.24): whole coins absorb the modifier (open question)")
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var seller: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "farmer":
			seller = n
			break
	CapabilityHook.off()
	var p0 := w.sell_price(seller, "wheat")
	CapabilityHook.forced = {"farming": 10}
	check(w.sell_price(seller, "wheat") == p0, "the price of grain is not raised by the farming level (%d)" % p0)
	CapabilityHook.off()


## Rules 1-2 in the regional model: a settlement's farming level never raises its crop (yield_fixed); a craft's does.
func test_capnum_ledger_yield() -> void:
	var made := {}
	for l in [0, 10]:
		var a := SettlementLedger.make({"id": "f%d" % l, "settlement": "f%d" % l, "production": {"wheat": 10.0, "plank": 10.0},
			"reserves": {"wheat": 100000, "plank": 100000}, "capabilities": {"farming": l, "carpentry": l}, "profile": "approved"})
		for d in 10:
			a.tick(d)
		made[l] = [a.stock.count("wheat"), a.stock.count("plank")]
	check(made[0][0] == 100 and made[10][0] == 100, "a farming town at level 10 grows the same 100 wheat in 10 days as at level 0 (%s)" % str(made))
	check(made[10][1] > made[0][1], "while a carpentry town at level 10 saws more planks from its reserve (%d against %d)" % [made[10][1], made[0][1]])


## Determinism with the approved profile forced: the same seed twice gives the same World; and the neutral comparison.
func test_capnum_determinism() -> void:
	var fp := func(forced: Dictionary) -> String:
		CapabilityHook.off()
		CapabilityHook.forced = forced
		var w := World.new()
		w.setup(VillageMap.load_default(), 3)
		var steps := int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.25)
		for i in steps:
			w.update(0.25)
			w.player.hunger = 100.0
		var out := JSON.stringify(w.to_dict()).md5_text()
		CapabilityHook.off()
		return out
	var all10 := {}
	for ind in ["mining", "forestry", "farming", "smithing", "carpentry", "tanning"]:
		all10[ind] = 10
	var a: String = fp.call(all10)
	var b: String = fp.call(all10)
	var n: String = fp.call({})
	check(a == b, "seed 3, one day, approved profile at level 10, twice: the same World (%s)" % a)
	print("     neutral (hook off) %s; approved level 10 %s: %s" % [n, a, "different" if a != n else "the same"])
	check(a != n, "and against the hook off the World differs (the faster work is real)")
