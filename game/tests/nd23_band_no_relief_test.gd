extends SceneTree
## ND-23 (player-journey test 2026-11-12; owner "Exclude the band", docs/directives/2026-11-12_extra_life_owner_decisions.md on
## the records branch): the manor's grain relief (NPCBrain._relief) went to every hungry household, the outlaw band's too (seed 1,
## day 1: 7 wheat consigned to the six bandits, the job reading "to the  family's house" and the grain left at the works yard).
## Now the band's household gets none; a hungry village household still does.
##   godot --headless --path game --script res://tests/nd23_band_no_relief_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var band: int = w.wilds.band_household() if w.wilds != null else -1
	check(band >= 0 and not w.brain._members(band).is_empty(), "fixture: the outlaw band has a household with members (%d)" % band)
	var village := -1
	for h in range(3, w.households.size()):
		if h != band and not w.households[h].get("band", false) and not w.brain._members(h).is_empty():
			village = h
			break
	check(village >= 0, "fixture: a village household")
	if band < 0 or village < 0:
		finish()
		return
	for h in [band, village]:
		w.households[h].pantry.items.clear()
		for o: NPC in w.brain._members(h):
			for id in GameData.items:
				if GameData.items[id].get("kind", "") == "food" or GameData.items[id].get("food", 0) != 0:
					o.inv.remove(id, o.inv.count(id))
	w.granary.add("wheat", 200)
	check(w.brain.household_food_days(band) < float(GameData.b("relief_trigger_days")), "fixture: the band's household is short of food")
	check(w.brain.household_food_days(village) < float(GameData.b("relief_trigger_days")), "fixture: the village household is short of food")
	var band_before: int = w.households[band].pantry.count("wheat")
	w.brain._relief(0.0, 0.0)
	check(w.manor_work.pending_for(band) == 0 and w.households[band].pantry.count("wheat") == band_before,
		"the outlaw band's household gets no manor relief (pending %d, wheat %d)" % [w.manor_work.pending_for(band), w.households[band].pantry.count("wheat")])
	check(w.manor_work.pending_for(village) > 0 or w.households[village].pantry.count("wheat") > 0,
		"a hungry village household is still relieved (pending %d, wheat %d)" % [w.manor_work.pending_for(village), w.households[village].pantry.count("wheat")])
	finish()


func finish() -> void:
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
