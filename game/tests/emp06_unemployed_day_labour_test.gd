extends SceneTree
## EMP-06 (Build 25 audit, WP-1; owner rule 2026-11-12, docs/directives/2026-11-12_extra_life_owner_decisions.md item 4,
## "Allow day labour"): "The unemployed may take open manor day labour when their household is short of food, like labourers
## do." NPCBrain._day_labour admits the unemployed (job "") on the labourer's terms, and the work step calls it for them before
## noon (npc_brain.gd, "EMP-06: out of work, short of food"). This test checks the rule and its condition, both ways:
## - positive: the same adult, household short of food, nothing earned today, manor work open: as a labourer and out of work,
##   they take the day's manor work;
## - negative (Build 42, the owner's condition): household NOT short of food, or work already earned today: out of work, they
##   take no day labour, and no manor job is taken for them;
## - FAMILY-01 (family_first, on in the shipping configuration) stays a separate path for a parent of hungry dependants.
##   godot --headless --path game --script res://tests/emp06_unemployed_day_labour_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	var as_labourer := case_for("laborer")
	var unemployed := case_for("")
	check(as_labourer.ready and unemployed.ready, "fixture: a short-food household, nothing earned today, manor work open (%d jobs)" % int(unemployed.open))
	check(bool(as_labourer.took), "as a labourer, the adult takes the manor's day work on a short-food day")
	check(bool(unemployed.took), "owner rule 2026-11-12 (EMP-06, allow day labour): out of work, the same adult takes the manor's day work on a short-food day")
	var fed := case_for("", "fed")
	check(bool(fed.ready), "fixture: the same household with its pantry stocked (%.1f food days, trigger %s), manor work open (%d jobs)" % [float(fed.food_days), str(GameData.b("relief_trigger_days")), int(fed.open)])
	check(not bool(fed.took), "owner's condition: out of work but the household is NOT short of food: no day labour")
	check(not bool(fed.taken), "... and no manor job is taken for them (the board is unchanged)")
	var earned := case_for("", "earned")
	check(bool(earned.ready), "fixture: short-food household, but the adult has already earned today")
	check(not bool(earned.took), "out of work, short of food, but work already earned today: no day labour (labourer's terms)")
	check(not bool(earned.taken), "... and no manor job is taken for them")
	check(JudgmentLive.on(unemployed.w, JudgmentFamily.FLAG), "FAMILY-01 (family_first) is on in the shipping configuration: an unemployed parent of hungry dependants has _family_labour")
	print("EMP-06 reading: day labour %s for a labourer, %s for the unemployed; FAMILY-01 %s" % [str(as_labourer.took), str(unemployed.took), "on" if JudgmentLive.on(unemployed.w, JudgmentFamily.FLAG) else "off"])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func case_for(job: String, variant: String = "") -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 8.0 * 60.0                      # day 1, 8:00: working hours, before noon
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.job in ["laborer", "", "manor_hand"] and w.homesteads != null and not w.homesteads.away(o):
			n = o
			break
	if n == null:
		for o: NPC in w.npcs:
			if o.alive and o.role == "adult" and o.household >= 0 and not (o.job in ["guard", "reeve", "sage"]):
				n = o
				break
	var out := {"w": w, "ready": false, "took": false, "taken": false, "open": 0, "food_days": 0.0}
	if n == null:
		return out
	n.job = job
	var hh: Dictionary = w.households[n.household]
	for m: NPC in w.npcs:
		if m.alive and m.household == n.household:
			for f in NPCBrain.FOOD:
				m.inv.remove(f, m.inv.count(f))
	for f in NPCBrain.FOOD:
		(hh.pantry as Inventory).remove(f, (hh.pantry as Inventory).count(f))
	for post in ["post_quarry", "post_clearing", "post_paving", "post_shore"]:     # the manor's board: some work open today
		if w.manor_work.open_for(World.npc_ref(n.id)).is_empty():
			w.manor_work.call(post)
	var trigger := float(GameData.b("relief_trigger_days"))
	if variant == "fed":                                  # a stocked pantry: the household is not short of food
		var guard := 0
		while w.brain.household_food_days(n.household) < trigger + 2.0 and guard < 200:
			(hh.pantry as Inventory).add("bread", 10)
			guard += 1
	w.brain.earned_at_dawn[n.id] = n.earned
	if variant == "earned":                               # something already earned today
		w.brain.earned_at_dawn[n.id] = n.earned - 1
	w.brain.laboured_today.erase(n.id)
	var who := World.npc_ref(n.id)
	out.open = w.manor_work.open_for(who).size()
	out.food_days = w.brain.household_food_days(n.household)
	var short := float(out.food_days) < trigger
	out.ready = int(out.open) > 0 and (not short if variant == "fed" else short)
	out.took = w.brain._day_labour(n)
	out.taken = not w.manor_work.job_of(who).is_empty() or w.brain.laboured_today.has(n.id)
	return out
