extends SceneTree
## JOB-01, the shared manor job board for salaried hands (owner REC-013 Q2, 2026-10-21): manor hands may take board work
## with no extra wage; the pickaxe and survey exclusions hold for them; nobody has priority (first come, the same list
## for a hand and a labourer); one job at a time for everyone, and a taken job is nobody else's; the wage set aside
## comes back on release, so the treasury and the reserve always add up. LOG-01: an unclaimed delivery falls to the reeve
## only when no manor hand is free, carried physically, delivered once, unpaid. Run headless:
##   godot --headless --path game --script res://tests/job_board_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	_test_board()
	_test_reeve_fallback()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _held(w: World) -> int:
	return w.treasury + w.manor_work.reserved_total()


func _test_board() -> void:
	var w := _world(1)
	var mw := w.manor_work
	w.treasury = 5000
	mw.jobs.clear()
	var hand: NPC = w.brain._first_with_job("laborer")
	w.brain._change_job(hand, "manor_hand", "a test")
	var lab: NPC = w.brain._first_with_job("laborer")
	check(hand != null and lab != null and hand != lab, "a manor hand and a labourer")
	var h := "npc:%d" % hand.id
	var l := "npc:%d" % lab.id
	check(mw.is_staff(h) and not mw.is_staff(l) and not mw.is_staff(World.PLAYER), "only the hand is staff")
	mw._post({"kind": "mend", "item": "stone", "qty": 2, "wage": 6})
	mw._post({"kind": "mend", "item": "stone", "qty": 2, "wage": 6})
	var a: Dictionary = mw.jobs[0]
	var b: Dictionary = mw.jobs[1]
	# no priority: the hand and the labourer see the same jobs, in the same order
	var oh: Array = mw.open_for(h).map(func(j): return int(j.id))
	var ol: Array = mw.open_for(l).map(func(j): return int(j.id))
	check(oh == ol and oh.size() == 2, "the same open jobs, in the same order, for a hand and a labourer (no staff priority)")
	# first come: the labourer takes the first job; it is then nobody else's
	var held0 := _held(w)
	check(mw.take(a, l), "the labourer takes a job first")
	check(int(a.reserved) == 6 and _held(w) == held0, "the labourer's wage is set aside from the treasury, nothing made or lost")
	check(not mw.take(a, h) and mw.last_refusal == "Someone else has taken that work.", "the hand cannot take a job already taken")
	check(not mw.open_for(h).has(a), "a taken job is off the board")
	# no double booking
	check(not mw.take(b, l) and mw.last_refusal == "You are already doing work for the manor.", "one job at a time: the labourer cannot take a second")
	# the hand takes board work with no extra wage
	var t0 := w.treasury
	check(mw.take(b, h) and int(b.reserved) == 0 and w.treasury == t0, "the hand takes the other job unpaid: no wage set aside")
	check(mw.job_of(h) == b and mw.job_of(l) == a, "each worker holds exactly the job they took")
	# release puts the wage back and leaves the job posted
	mw.release(a)
	check(a.taker == "" and int(a.reserved) == 0 and _held(w) == held0, "releasing returns the wage to the treasury; the job stays posted")
	check(mw.open_for(h).has(a) and not mw.open_for(h).has(b), "the released job is back on the board; the hand's own job is not")
	check(not mw.take(a, h) and mw.last_refusal == "You are already doing work for the manor.", "the busy hand still cannot take a second job")
	# the exclusions hold for staff
	mw._post({"kind": "quarry", "item": "stone", "qty": 4, "wage": 8})
	var q: Dictionary = mw.jobs[mw.jobs.size() - 1]
	mw.release(b)
	hand.inv.remove("pickaxe", hand.inv.count("pickaxe"))
	check(not mw.open_for(h).has(q), "a quarry needs a pickaxe, for a hand as for anyone")
	hand.inv.add("pickaxe")
	check(mw.open_for(h).has(q), "with a pickaxe the hand may quarry")
	mw._post({"kind": "survey", "qty": 1, "wage": 10, "clues": []})
	var s: Dictionary = mw.jobs[mw.jobs.size() - 1]
	hand.inv.add(Prospecting.KIT)
	hand.coins += 500
	check(not mw.open_for(h).has(s), "surveys stay closed to manor hands, kit and fees in hand or not")


func _test_reeve_fallback() -> void:
	var w := _world(2)
	var mw := w.manor_work
	w.treasury = 5000
	mw.jobs.clear()
	mw.lots.clear()
	var reeve: NPC = w.brain._first_with_job("reeve")
	var hand: NPC = w.brain._first_with_job("laborer")
	w.brain._change_job(hand, "manor_hand", "a test")
	check(reeve != null and hand != null, "a reeve and a manor hand")
	var r := "npc:%d" % reeve.id
	check(mw.is_staff(r), "the reeve is salaried staff: board work pays no extra wage")
	mw.yard.add("wheat", 5)
	check(mw.consign(mw.yard, mw.yard_cell(), "wheat", 5, {"kind": "granary"}, "a test", "test"), "goods consigned to the granary")
	mw.refresh()
	var hauls: Array = mw.jobs.filter(func(j): return j.kind == "haul")
	check(hauls.size() == 1, "one delivery posted")
	var j: Dictionary = hauls[0]
	check(not mw.reeve_fallback(reeve) and j.taker == "", "a free manor hand: the reeve leaves the delivery to the hand")
	mw._post({"kind": "mend", "item": "stone", "qty": 2, "wage": 6})
	var m: Dictionary = mw.jobs[mw.jobs.size() - 1]
	check(mw.take(m, "npc:%d" % hand.id), "the hand is busy with other work")
	var grain0 := w.granary.count("wheat")
	var t0 := w.treasury
	var c0 := reeve.coins
	var all0 := grain0 + reeve.inv.count("wheat") + 5
	check(mw.reeve_fallback(reeve) and j.taker == r and int(j.reserved) == 0 and w.treasury == t0, "no free hand: the reeve takes the delivery, no wage set aside")
	check(not mw.reeve_fallback(reeve), "the reeve does not take a second job")
	check(mw.do_step(j, r, reeve.inv) and j.load.count("wheat") == 5, "the reeve loads the goods from where they lie")
	check(mw.do_step(j, r, reeve.inv), "and puts them down at the granary")
	check(w.granary.count("wheat") == grain0 + 5 and not mw.jobs.has(j), "delivered once; the job is done")
	check(w.granary.count("wheat") + reeve.inv.count("wheat") == all0 and reeve.coins == c0 and w.treasury == t0, "every unit accounted for; no wage paid to the salaried reeve")
