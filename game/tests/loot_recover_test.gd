extends SceneTree
## KI-RECOVER-LOOT (flight recorder 41536805310 seed 2, F001-F007, 2026-11-03): a guard sent to coins left lying where they
## cannot reach them (a solid cell, or outside the village's grid) failed recover_loot every couple of minutes for months.
## Now a failed recovery leaves that loot alone for a day (skip_until), and coins a guard can reach are still brought to the
## manor. Pure World. Run headless:
##   godot --headless --path game --script res://tests/loot_recover_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _guard(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard":
			return n
	return null


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 10.0 * 60.0
	var g := _guard(w)
	check(g != null, "the village has a guard")
	# coins lying out of reach: far outside the village's grid, beside the guard's range
	var far := g.pos + Vector2(float(w.map.w) + 40.0, 0.0)
	var unreachable := {"pos": far, "inv": Inventory.new(), "coins": 7, "from": "a test", "t": 0.0}
	w.loot.append(unreachable)
	var t0 := w.treasury
	g.pos = far - Vector2(3.0, 0.0)                     # as close as their walk could bring them
	check(w.brain._loot_to_recover(g) == unreachable, "the guard on duty is sent to the coins left lying")
	check(not w.brain.act(g, "recover_loot", {}), "out of reach, the recovery fails")
	var again := 0
	for i in 400:                                       # 20 hours of the guard's choices
		w.minutes += 3.0
		if w.brain._loot_to_recover(g) == unreachable:
			again += 1
	check(again == 0, "and the same coins are not chosen again within the day (chosen %d times in 20 hours, was every decision)" % again)
	check(int(unreachable.coins) == 7 and w.treasury == t0 and w.loot.has(unreachable), "the coins stay where they lie for anyone; nothing moves")
	w.minutes += 300.0
	check(w.brain._loot_to_recover(g) == unreachable, "a day later the guard tries again")
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var l2: Dictionary = w2.loot[w2.loot.size() - 1]
	check(is_equal_approx(float(l2.get("skip_until", -1.0)), float(unreachable.skip_until)), "the time it is left until is saved and loaded")
	# coins within reach are still recovered
	var near := {"pos": g.pos + Vector2(0.5, 0.0), "inv": Inventory.new(), "coins": 5, "from": "a test", "t": 0.0}
	w.loot.append(near)
	check(w.brain.act(g, "recover_loot", {}) and w.treasury == t0 + 5 and not w.loot.has(near), "coins within reach are brought to the manor (5 coins)")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
