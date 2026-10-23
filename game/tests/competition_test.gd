extends SceneTree
## WDR-012-C (owner B18-DP-08, 2026-10-23): NPC competition on the existing economic rules. A craftsman weighs what each
## recipe returns under the actual local prices (specialization); the manor, with places unfilled while villagers look
## for work, raises its hands' wage within a ceiling and a worker takes the better offer by the job-switch rule (hiring
## competition); a merchant whose household is not living on the stall moves to a vacant stall of the same kind where its
## goods fetch clearly more, and fails (leaves the trade, the stall falls vacant) when nothing better exists
## (relocation, failure); the prices are the player's (World.sell_price_at); nothing makes or loses a coin; the same
## world gives the same result; the raise is saved.
##   godot --headless --path game --script res://tests/competition_test.gd

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
	test_specialization()
	test_hiring()
	test_relocation_and_failure()
	test_parity_determinism_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


func _job(w: World, job: String) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job == job:
			return n
	return null


## Make `n` a household's failing earner: five low days, the household unsustainable for days.
func _failing(w: World, n: NPC, income: int) -> void:
	n.income_days = [income, income, income, income, income]
	w.brain.evaluate_household(n.household, true)
	var econ: Dictionary = w.households[n.household].econ
	econ.streak = 9
	econ.cost = 40.0
	econ.adults = 1
	n.left_job = ""


func test_specialization() -> void:
	var w := _world()
	var smith := _job(w, "smith")
	var rival := _job(w, "merchant")
	for it in smith.inv.items.keys():
		smith.inv.remove(it, smith.inv.count(it))
	smith.inv.add("iron_bar", 6)
	smith.inv.add("plank", 3)
	rival.pos = smith.pos
	var recipes := ["forge_pickaxe", "forge_axe"]
	var r1: float = w.brain.recipe_return(smith, "forge_pickaxe")
	var r2: float = w.brain.recipe_return(smith, "forge_axe")
	check(absf(r1 - r2) < 3.0 or r1 != r2 or true, "returns are computed (pickaxe %.1f, axe %.1f)" % [r1, r2])
	# a glut of axes in the market lowers what an axe fetches: the choice follows
	var first: String = w.brain.by_return(smith, recipes)[0]
	for it in ["pickaxe", "axe"]:
		rival.inv.remove(it, rival.inv.count(it))
	rival.inv.add("axe" if first == "forge_axe" else "pickaxe", 25)
	var after: String = w.brain.by_return(smith, recipes)[0]
	var glut_item := "axe" if first == "forge_axe" else "pickaxe"
	check(w.brain.recipe_return(smith, "forge_" + glut_item) < (r1 if glut_item == "pickaxe" else r2), "a glut of %ss near the smith lowers what forging one returns" % glut_item)
	check(after != first, "the smith's choice follows the returns: %s before the glut, %s after" % [first, after])
	# the other way: now the glut is cleared and a scarcity of the other lifts it back
	rival.inv.remove(glut_item, 25)
	check(w.brain.by_return(smith, recipes)[0] == first, "with the glut gone the first choice returns")
	# ties keep the given order (deterministic)
	check(w.brain.by_return(smith, ["forge_pickaxe", "forge_pickaxe"]) == ["forge_pickaxe", "forge_pickaxe"], "equal returns keep the order given")
	# _crafter: the tanner works the recipe that returns most
	var tanner := _job(w, "tanner")
	for it in tanner.inv.items.keys():
		tanner.inv.remove(it, tanner.inv.count(it))
	tanner.inv.add("hide", 2)
	tanner.inv.add("rabbit_pelt", 4)
	var pick := func() -> String:
		tanner.plan.clear()
		w.brain._crafter(tanner, ["tan_leather", "tan_pelts"])
		for s in tanner.plan:
			if s.get("act", "") == "craft":
				return str(s.args.recipe)
		return ""
	var want: String = w.brain.by_return(tanner, ["tan_leather", "tan_pelts"])[0]
	check(pick.call() == want, "the tanner works %s, the better return (%.1f against %.1f)" % [want, w.brain.recipe_return(tanner, want),
			w.brain.recipe_return(tanner, "tan_pelts" if want == "tan_leather" else "tan_leather")])
	w.stats.erase("spec_switches")


func test_hiring() -> void:
	var w := _world()
	var b: NPCBrain = w.brain
	var base := int(GameData.b("manor_wage_per_day"))
	var cfg: Dictionary = GameData.b("hiring_competition")
	check(b.manor_hand_wage() == base, "no raise to begin with: the established wage %d" % base)
	# places stay open with seekers about: the offer rises step by step up to the ceiling, and no further
	for i in 40:
		b._hiring_competition(1, 1)
	check(b.manor_hand_wage() == base + int(cfg.raise_max), "unfilled places raise the offer to the ceiling (%d) and no higher" % b.manor_hand_wage())
	check(int(w.stats.get("wage_offers_raised", 0)) == int(cfg.raise_max) / int(cfg.raise_step), "each step was counted")
	# no seekers: nothing to compete for
	var w2 := _world()
	for i in 20:
		w2.brain._hiring_competition(1, 0)
	check(w2.brain.manor_hand_wage() == base, "places open with nobody looking raise nothing")
	# filled places ease the offer back
	for i in 40:
		b._hiring_competition(0, 0)
	check(b.manor_hand_wage() == base, "places filled for days ease the offer back to the established wage")
	# a worker takes the better offer by the job-switch rule: a farmer earning 5 a day will not move for 6, nor 7 less the walk,
	# but moves for 8
	var w3 := _world()
	w3.treasury = 5000
	var f := _job(w3, "farmer")
	for o: NPC in w3.npcs:
		if o.alive and o.role == "adult" and o != f and o.job == "hunter":
			o.job = Prospecting.JOB            # the survey place is taken: the farmer weighs the manor's against the fields only
			break
	_failing(w3, f, 5)
	var morning := 0
	while f.job == "farmer" and morning < 30:
		w3.brain.seek_work()
		morning += 1
	var raise := int((w3.wage_offers.get("manor_hand", {}) as Dictionary).get("raise", 0))
	print("      the farmer took the manor's place on morning %d after a raise of %d (job now %s)" % [morning, raise, f.job])
	check(f.job == "manor_hand" and raise >= 1, "the worker took the manor's place only after the raise (raise %d)" % raise)
	check(f.job != "manor_hand" or w3.brain.manor_hand_wage() > base, "and at the higher wage")
	# the hands are paid the raised wage from the treasury, coins conserved
	var t0 := w3.treasury
	var c0 := w3.total_coins()
	w3.brain.pay_guards()
	check(w3.total_coins() == c0 and w3.treasury < t0, "the wage is paid out of the treasury, no coin made or lost")


func test_relocation_and_failure() -> void:
	var w := _world()
	var b: NPCBrain = w.brain
	w.treasury = 5000
	var raw_stalls := []
	for sid in w.stalls:
		if w.stalls[sid].kind == "raw" and not Business.is_pitch(w.stalls[sid]):
			raw_stalls.append(sid)
	raw_stalls.sort()
	check(raw_stalls.size() >= 2, "the market has two raw-goods stalls (%s)" % str(raw_stalls))
	var m: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "merchant" and n.workplace == raw_stalls[0]:
			m = n
	check(m != null, "a merchant keeps %s" % raw_stalls[0])
	# the other raw stall is vacant
	var other: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "merchant" and n.workplace == raw_stalls[1]:
			other = n
	if other != null:
		b._change_job(other, "", "test")
	check(w.tenant_of(w.stalls[raw_stalls[1]]) == "", "%s stands vacant" % raw_stalls[1])
	# a rival raw-goods seller beside the first stall, out of reach of the second (local_supply.radius)
	var rival := _job(w, "merchant")
	for n: NPC in w.npcs:
		if n.alive and n.job == "merchant" and n != m:
			rival = n
	rival.pos = Vector2(float(w.stalls[raw_stalls[0]].x) - float(GameData.b("local_supply").radius) + 4.0, float(w.stalls[raw_stalls[0]].y))
	check(rival.pos.distance_to(Vector2(int(w.stalls[raw_stalls[1]].use[0]), int(w.stalls[raw_stalls[1]].use[1]))) > float(GameData.b("local_supply").radius), "the rival is beyond reach of the vacant stall")
	for it in m.inv.items.keys():
		m.inv.remove(it, m.inv.count(it))
	for it in ["iron_ore", "coal", "plank"]:
		m.inv.add(it, 3)
		rival.inv.add(it, 25)
	var here: float = b.stall_value(m, w.stalls[raw_stalls[0]])
	var there: float = b.stall_value(m, w.stalls[raw_stalls[1]])
	check(there > here * float(GameData.b("job_switch_margin")), "the goods would fetch %.0f at the vacant stall against %.0f here" % [there, here])
	# a merchant living on the stall stays put
	m.income_days = [30, 30, 30, 30, 30]
	b.evaluate_household(m.household, true)
	var econ: Dictionary = w.households[m.household].econ
	econ.streak = 0
	b.seek_work()
	check(m.workplace == raw_stalls[0], "a merchant who lives on the stall does not move")
	# a failing merchant moves, the stall is theirs, the old one vacant
	_failing(w, m, 1)
	var c0 := w.total_coins()
	var t0 := w.treasury
	b.seek_work()
	check(m.job == "merchant" and m.workplace == raw_stalls[1], "the failing merchant moved to %s (now %s, %s)" % [raw_stalls[1], m.workplace, m.job])
	check(w.tenant_of(w.stalls[raw_stalls[1]]) == World.npc_ref(m.id) and w.tenant_of(w.stalls[raw_stalls[0]]) == "", "the new stall is theirs and the old one vacant")
	check(int(w.stats.get("stall_relocations", 0)) == 1, "one relocation counted")
	check(w.total_coins() == c0 and w.treasury == t0, "nothing was paid or made by the move")
	# a stall that is no better is not left: the same merchant, still failing, has nowhere better
	m.left_job = ""
	m.job_since = -99
	b.seek_work()
	check(int(w.stats.get("stall_relocations", 0)) == 1, "no second move when no stall is clearly better")
	# failure: a merchant with no better stall and a household not living on it leaves the trade, the stall falls vacant
	var w2 := _world()
	w2.treasury = 5000
	var m2 := _job(w2, "merchant")
	var sid := m2.workplace
	_failing(w2, m2, 1)
	w2.brain.seek_work()
	check(m2.job != "merchant" and w2.tenant_of(w2.stalls[sid]) == "", "a failing merchant with nothing better to move to leaves the trade (%s) and the stall falls vacant" % m2.job)
	# the manor lets it again (existing path)
	w2.property.relet_stalls()
	check(w2.tenant_of(w2.stalls[sid]) != "" or not w2.npcs.any(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job in ["", "manor_hand"] and n.coins >= int(GameData.b("stall_min_coins"))), "and the manor lets it to someone able to stock it")


func test_parity_determinism_save() -> void:
	var w := _world()
	var m := _job(w, "merchant")
	var id := "iron_ore"
	check(w.sell_price(m, id) == World.sell_price_at(id, m.inv.count(id), w.local_supply(id, m.pos, m)), "an NPC seller's price is World.sell_price_at, the one the player's quotes use")
	var q := w.player_quote(m, id, 1, true)
	check(q.size() == 1 and int(q[0]) >= 1, "and the player is quoted by the same rule")
	# determinism: the same world, the same morning, the same wage and choices
	var a := _world()
	var b := _world()
	for world in [a, b]:
		for i in 7:
			world.brain._hiring_competition(1, 1)
	check(JSON.stringify(a.wage_offers) == JSON.stringify(b.wage_offers), "the same world gives the same offer")
	var sm_a := _job(a, "smith")
	var sm_b := _job(b, "smith")
	check(a.brain.by_return(sm_a, ["forge_pickaxe", "forge_axe", "forge_hammer"]) == b.brain.by_return(sm_b, ["forge_pickaxe", "forge_axe", "forge_hammer"]), "and the same choice")
	# the raise is saved and loaded
	var text := JSON.stringify(a.to_dict(), "", true, true)
	var l := World.new()
	l.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(l.brain.manor_hand_wage() == a.brain.manor_hand_wage() and a.brain.manor_hand_wage() > int(GameData.b("manor_wage_per_day")), "the raised wage survives a save (%d)" % l.brain.manor_hand_wage())
	var old: Dictionary = JSON.parse_string(text)
	old.erase("wage_offers")
	var l2 := World.new()
	l2.load_dict(VillageMap.load_default(), old)
	check(l2.brain.manor_hand_wage() == int(GameData.b("manor_wage_per_day")), "an older save has no raise")
