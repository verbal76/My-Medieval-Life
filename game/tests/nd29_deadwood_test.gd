extends SceneTree
## ND-29 deadwood (owner 2026-11-12: "Approve limited gathering of fallen branches and deadwood without an axe, using existing
## gathering systems wherever possible. Gathering must consume time, respect available resources, and conserve inventory. Do
## not create unlimited free firewood. Preserve nightly fuel consumption, save/load persistence, deterministic behavior, and
## existing cold-household reporting. Do not introduce new cold-exposure health or stamina penalties."). The outlaw band's
## people, who hold no axe, gather a log of fallen wood from a mature tree near their camp (Homesteads.plan_deadwood, act
## "deadwood"): deadwood_minutes of work, one log a tree every deadwood_seasons (a per-tree day, saved with the homesteads), only
## from grown trees within deadwood_radius, only while the camp's hearth holds fewer than keep_logs; the log is counted made_log
## (the item ledger's produced) and stored on the camp's hearth, where the nightly burn (World.burn_firewood) takes it.
##   godot --headless --path game --script res://tests/nd29_deadwood_test.gd

var checks := 0
var failures := 0
const NONE := Vector2i(1 << 30, 0)


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


## A seed-1 world at 9 in the morning of its first day, the band's camp hearth bare and its people with no coin (they cannot
## buy firewood: what reaches the hearth is gathered).
func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	while w.hour() < 9.0:
		w.update(1.0)
	var band: int = w.wilds.band_household()
	var pantry: Inventory = w.households[band].pantry
	pantry.remove("log", pantry.count("log"))
	for m: NPC in w.brain._members(band):
		m.inv.remove("log", m.inv.count("log"))
		m.coins = 0
	return w


func _at(n: NPC, t: Vector2i) -> void:
	n.pos = Vector2(t.x + 1, t.y) + Vector2(0.5, 0.5)
	n.plan.clear()


func _act(w: World, n: NPC, t: Vector2i) -> bool:
	return w.homesteads.act(n, {"step": "deadwood", "x": t.x, "y": t.y})


func _init() -> void:
	var cf: Dictionary = Homesteads.cfg()
	check(float(cf.get("deadwood_minutes", 0)) > 0.0 and float(cf.get("deadwood_seasons", 0)) > 0.0 and int(cf.get("deadwood_radius", 0)) > 0,
		"balance: deadwood_minutes, deadwood_seasons and deadwood_radius are set")
	var w := _world()
	var band: int = w.wilds.band_household()
	var c: Dictionary = w.wilds.band_claim()
	var members: Array = w.brain._members(band)
	check(band >= 0 and not c.is_empty() and not members.is_empty(), "fixture: the band's household, camp claim and people")
	if band < 0 or c.is_empty() or members.is_empty():
		finish()
		return
	var n: NPC = members[0]
	var pantry: Inventory = w.households[band].pantry
	n.hunger = 100.0
	check(not n.inv.has("axe"), "fixture: the bandit holds no axe")

	# the plan: to the nearest grown tree within reach, deadwood_minutes of work there, then the log home to the hearth
	var t: Vector2i = w.homesteads.deadwood_tree(c, n)
	check(t != NONE, "a grown tree stands within deadwood_radius of the camp (%s)" % t)
	n.plan.clear()
	check(w.homesteads.plan_deadwood(n, c) and n.doing == "gathering deadwood", "a bandit without an axe goes to gather deadwood (doing: %s)" % n.doing)
	var mins := 0.0
	var acts := []
	for s in n.plan:
		if str(s.k) == "work":
			mins += float(s.min)
		if s.has("args") and (s.args as Dictionary).has("step"):
			acts.append(str(s.args.step))
	check(mins >= float(cf.deadwood_minutes), "gathering takes time: %.0f game minutes of work (deadwood_minutes %s)" % [mins, cf.deadwood_minutes])
	check(acts == ["deadwood", "store_logs"], "the plan gathers then stores at the hearth (%s)" % [acts])
	var m2: NPC = members[1] if members.size() > 1 else null
	if m2 != null:
		m2.plan.clear()
		check(not w.homesteads.plan_deadwood(m2, c), "one of the band gathers at a time (a second one does not set out)")

	# the act: one log into the pack, counted for the item ledger (produced: made_log)
	var made0 := int(w.stats.get("made_log", 0))
	var got0 := int(w.stats.get("gathered_deadwood", 0))
	_at(n, Vector2i(9999, 9999))
	check(not _act(w, n, t), "nothing is gathered from afar (the gatherer must stand at the tree)")
	_at(n, t)
	check(_act(w, n, t) and n.inv.count("log") == 1, "at the tree the bandit gathers one log (pack: %d)" % n.inv.count("log"))
	check(int(w.stats.get("made_log", 0)) == made0 + 1 and int(w.stats.get("gathered_deadwood", 0)) == got0 + 1,
		"the log is counted produced (made_log +1, gathered_deadwood +1): the item ledger balances")
	check(not _act(w, n, t) and n.inv.count("log") == 1, "the same tree gives no more until its deadwood falls again")
	var back := int(w.homesteads.deadwood.get("%d,%d" % [t.x, t.y], -1))
	var days := roundi(Life.seasons_to_days(float(cf.deadwood_seasons)))
	check(back == w.day() + days, "the tree's wood is back on day %d (today %d + %d days)" % [back, w.day(), days])
	check(w.homesteads.deadwood_tree(c, n) != t, "the next gatherer looks to another tree")
	# stored at the hearth up to keep_logs
	n.pos = Vector2(Homesteads.step_of(c)) + Vector2(0.5, 0.5)
	check(w.homesteads.act(n, {"step": "store_logs"}) and pantry.count("log") == 1 and n.inv.count("log") == 0, "the log goes onto the camp's hearth")

	# save and load: the tree's day holds
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d.duplicate(true))
	var n2: NPC = w2.npc(n.id)
	check(int(w2.homesteads.deadwood.get("%d,%d" % [t.x, t.y], -1)) == back, "after a save and load the tree's day is kept")
	_at(n2, t)
	check(not _act(w2, n2, t), "after a save and load the tree still gives nothing before its day")
	w2.minutes += float(days) * 1440.0
	check(_act(w2, n2, t) and n2.inv.count("log") == 1, "on its day the tree gives a log again")

	# resources respected: a stump gives nothing; with every tree in reach spent, nothing is gathered
	var near: Vector2i = w.homesteads.deadwood_tree(c, n)
	var tr: Dictionary = w.tree_at(near)
	w.fell(tr, 0)
	check(w.homesteads.deadwood_tree(c, n) != near, "a felled tree (a stump) gives no deadwood")
	_at(n, near)
	check(not _act(w, n, near), "nor can a stump be gathered from")
	var spent := 0
	while true:
		var x: Vector2i = w.homesteads.deadwood_tree(c, n)
		if x == NONE or spent > 4000:
			break
		w.homesteads.deadwood["%d,%d" % [x.x, x.y]] = w.day() + 100
		spent += 1
	n.plan.clear()
	n.doing = ""
	check(spent > 0 and spent < 4000 and not w.homesteads.plan_deadwood(n, c), "when every tree in reach (%d) has given its wood, nothing is gathered" % spent)

	# a hearth with keep_logs logs: nobody gathers
	var w3 := _world()
	var c3: Dictionary = w3.wilds.band_claim()
	var b3: int = w3.wilds.band_household()
	var p3: Inventory = w3.households[b3].pantry
	var n3: NPC = w3.brain._members(b3)[0]
	p3.add("log", int(cf.keep_logs))
	check(not w3.homesteads.plan_deadwood(n3, c3), "with keep_logs (%s) on the hearth nobody gathers" % cf.keep_logs)
	p3.remove("log", p3.count("log"))
	# the hearth's logs are kept for the fire: a claim's works (a well, a pen) take only the logs above keep_logs from its pantry
	p3.add("log", int(cf.keep_logs))
	var at_keep: int = w3.wilds.spare_of(p3, "log")
	p3.add("log", 2)
	check(at_keep == 0 and w3.wilds.spare_of(p3, "log") == 2, "the claim's works leave keep_logs on the hearth (spare %d, then %d)" % [at_keep, w3.wilds.spare_of(p3, "log")])
	p3.remove("log", p3.count("log"))
	# a villager household is not the band: its people do not gather deadwood
	var v: NPC = null
	for o: NPC in w3.npcs:
		if o.alive and o.household >= 0 and o.household != b3 and o.role == "adult" and not o.inv.has("axe"):
			v = o
			break
	check(v != null and not w3.homesteads.plan_deadwood(v, c3), "a villager without an axe does not gather the band's deadwood")

	# the day: the band gathers on its own, the log reaches the hearth and its fire is lit that night; two worlds of one seed
	# do the same (determinism)
	var w4 := _world()
	var b4: int = w4.wilds.band_household()
	var cold3 := int(w3.stats.get("cold_hh_%d" % b3, 0))
	var cold4 := int(w4.stats.get("cold_hh_%d" % b4, 0))
	var hearth3 := 0
	var hearth4 := 0
	var start_day := w3.day()
	while w3.day() == start_day or w3.hour() < 9.0:
		w3.update(1.0)
		w4.update(1.0)
		if w3.hour() >= 21.0 and w3.day() == start_day:
			hearth3 = maxi(hearth3, p3.count("log"))
			hearth4 = maxi(hearth4, (w4.households[b4].pantry as Inventory).count("log"))
	var g3 := int(w3.stats.get("gathered_deadwood", 0))
	check(g3 > 0, "in a day the band gathers deadwood by itself (%d logs)" % g3)
	check(hearth3 > 0, "by nightfall the gathered wood is on the camp's hearth (%d)" % hearth3)
	check(int(w3.stats.get("cold_hh_%d" % b3, 0)) == cold3, "the camp's fire burned that night: the band was not cold")
	check(g3 == int(w4.stats.get("gathered_deadwood", 0)) and hearth3 == hearth4 and int(w4.stats.get("cold_hh_%d" % b4, 0)) == cold4
		and JSON.stringify(w3.homesteads.deadwood) == JSON.stringify(w4.homesteads.deadwood),
		"two worlds of one seed gather the same wood from the same trees (%s)" % JSON.stringify(w3.homesteads.deadwood))

	# exhaust: the nightly burn takes the hearth's logs, one a night; with none left (and no tree to give) the band is cold again
	var spent3 := 0
	while true:
		var x: Vector2i = w3.homesteads.deadwood_tree(c3, n3)
		if x == NONE or spent3 > 4000:
			break
		w3.homesteads.deadwood["%d,%d" % [x.x, x.y]] = w3.day() + 100
		spent3 += 1
	for m: NPC in w3.brain._members(b3):
		m.inv.remove("log", m.inv.count("log"))
	p3.remove("log", p3.count("log"))
	p3.add("log", 2)
	var burned0 := int(w3.stats.get("burned_log", 0))
	var c0 := int(w3.stats.get("cold_hh_%d" % b3, 0))
	w3.burn_firewood()
	w3.burn_firewood()
	check(p3.count("log") == 0 and int(w3.stats.get("cold_hh_%d" % b3, 0)) == c0, "two nights burn the hearth's two logs and the band is warm")
	check(int(w3.stats.get("burned_log", 0)) - burned0 >= 2, "each is counted burned (the ledger's consumed)")
	w3.burn_firewood()
	check(int(w3.stats.get("cold_hh_%d" % b3, 0)) == c0 + 1, "the third night, with the wood exhausted, the band is cold again")
	n3.plan.clear()
	n3.doing = ""
	check(not w3.homesteads.plan_deadwood(n3, c3), "and with no tree to give, no wood appears from nowhere")

	# cold-household reporting for a village household is unchanged: no log, cold; a log, not
	var vh := -1
	for h in w3.households.size():
		if h != b3 and not w3.households[h].get("ended", false) and not w3.households[h].has("homestead"):
			vh = h
			break
	var vp: Inventory = w3.households[vh].pantry
	vp.remove("log", vp.count("log"))
	var vc := int(w3.stats.get("cold_hh_%d" % vh, 0))
	w3.burn_firewood()
	check(int(w3.stats.get("cold_hh_%d" % vh, 0)) == vc + 1, "a village household with no log is still counted cold")
	vp.add("log", 1)
	w3.burn_firewood()
	check(int(w3.stats.get("cold_hh_%d" % vh, 0)) == vc + 1 and vp.count("log") == 0, "and one with a log burns it and is not")
	finish()


func finish() -> void:
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
