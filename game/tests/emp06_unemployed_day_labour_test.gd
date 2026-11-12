extends SceneTree
## EMP-06 (Build 25 audit, WP-1): intent check, no game change. NPCBrain._day_labour (the manor's paid day work for an adult whose
## own work has earned nothing today while the household is short of food) excludes the unemployed (job "") by its job list, and
## the work step calls it only for `n.job != ""`. The unemployed reach paid work by the dawn job search (seek_work: the job
## market, manor hands' posts), the manor's land clearing (B25-ECON-P5) and, for a parent whose dependants are hungry,
## FAMILY-01's _family_labour (on in the shipping configuration: judgment.json family_first), which has no job list.
## This test records what the code does on a short-food day, for the owner's reading (is the exclusion intended?):
## - the same adult, household short of food and nothing earned today, with manor work open: as a labourer they take the day's
##   manor work; out of work they do not;
## - FAMILY-01 is on, so an unemployed parent of hungry dependants has its own path.
## Owner rule 2026-11-12 (docs/directives/2026-11-12_extra_life_owner_decisions.md, "Allow day labour"): the unemployed take it too.
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
	check(JudgmentLive.on(unemployed.w, JudgmentFamily.FLAG), "FAMILY-01 (family_first) is on in the shipping configuration: an unemployed parent of hungry dependants has _family_labour")
	print("EMP-06 reading: day labour %s for a labourer, %s for the unemployed; FAMILY-01 %s" % [str(as_labourer.took), str(unemployed.took), "on" if JudgmentLive.on(unemployed.w, JudgmentFamily.FLAG) else "off"])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func case_for(job: String) -> Dictionary:
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
	var out := {"w": w, "ready": false, "took": false, "open": 0}
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
	w.brain.earned_at_dawn[n.id] = n.earned
	w.brain.laboured_today.erase(n.id)
	out.open = w.manor_work.open_for(World.npc_ref(n.id)).size()
	out.ready = w.brain.household_food_days(n.household) < float(GameData.b("relief_trigger_days")) and int(out.open) > 0
	out.took = w.brain._day_labour(n)
	return out
