extends SceneTree
## EMP-04 (Build 25 audit, WP-1): NPCBrain.skilled_place (B25-EMPLOY-IMPL) finds room for one more hand of a crafting trade by
## summing the free working time of all the trade's stations, then names one station (the one with the most free time) as the
## place. The audit asked: when no single station has a worker's day free but the stations together do, does the hire happen,
## and can the new worker work? The test builds that split: every station of the smiths' kinds keeps less free time than one
## smith's day there, together more. It checks that a place is offered (room), and that the new hand is not tied to the named
## station: with it taken, a smith's work goes to another of the trade's stations (in the village, the forge and the anvil: smelting
## and forging recipes; _station_for picks any free one the worker may use and does not consult the workplace), so the summed time is usable. If either fails, the trade offers room no one can use.
##   godot --headless --path game --script res://tests/emp04_skilled_place_split_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_split()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_split() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var job := "smith"
	var smiths: Array = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.job == job)
	check(not smiths.is_empty(), "fixture: the village has smiths (%d)" % smiths.size())
	if smiths.is_empty():
		return
	var k := smiths.size()
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var sts := []
	for kind in NPCBrain.TRADE_STATIONS[job]:
		for st in w.stations_of(kind):
			if w.may_use("", w.stations[st]) or w.ventures.hiring_station(st):
				sts.append(st)
	check(sts.size() >= 2, "fixture: the smiths' trade has at least two stations a hire may use (%d)" % sts.size())
	if sts.size() < 2:
		return
	# every station: capacity x day of time, of which the smiths use all but `left`; each smith spends `per` a day there in all
	var cap_total := 0.0
	for st in sts:
		cap_total += float(w.stations[st].get("capacity", 1)) * day
	var left := 0.0
	var per := 0.0
	# per = (cap_total - n*left) / k; choose left so that left < per <= n*left
	var n := sts.size()
	left = cap_total / float(k + n) * 0.9
	per = (cap_total - n * left) / float(k)
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var d := {}
		for st in sts:
			d[st] = {job: float(w.stations[st].get("capacity", 1)) * day - left}
		past.append(d)
	w.station_load = {"day": w.day(), "today": {}, "past": past}
	check(left < per and n * left >= per, "fixture: each station has %.0f free minutes, less than one smith's %.0f a day; together %.0f" % [left, per, n * left])
	for o: NPC in smiths:                  # a settled, well-earning trade, so only room decides (afford, B25-EMPLOY-IMPL)
		o.income_days = [400, 400, 400, 400, 400]
		o.left_job = ""
	var sp: Dictionary = w.brain.skilled_place(job)
	check(int(sp.open) == 1, "the place is offered: the hire can happen (open %d; room %s, work %s, afford %s)" % [int(sp.open), str(sp.room), str(sp.work), str(sp.afford)])
	check(bool(sp.room), "the summed free time is room for another smith (as the rule reads: the stations together)")
	check(str(sp.place) in sts, "a station is named as the place (%s)" % sp.place)
	# the new hand: works at whatever station of the kind is free, not only the named one
	var hire: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != job and o.household >= 0:
			hire = o
			break
	var place := str(sp.place)
	var others: Array = sts.filter(func(st): return st != place and w.npc_may_use(hire, w.stations[st]))
	check(not others.is_empty(), "fixture: another of the trade's stations the new hand may use besides %s (%s)" % [place, str(others)])
	if others.is_empty():
		return
	hire.job = job
	hire.workplace = place
	# the named station taken by the smiths at work there
	for i in int(w.stations[place].get("capacity", 1)):
		var b2: NPC = smiths[mini(i, smiths.size() - 1)]
		b2.plan = [{"k": "work", "args": {"station": place}}]
		w.stations[place].users[b2.id] = w.minutes + 600.0
	var other: String = others[0]
	w.stations[other].users = {}
	check(w.brain._station_for(hire, str(w.stations[place].type)) == "", "fixture: the named %s (%s) is taken" % [w.stations[place].type, place])
	var got: String = w.brain._station_for(hire, str(w.stations[other].type))
	check(got == other, "with it taken, the new smith's work can go to the trade's other station (%s %s: %s)" % [w.stations[other].type, other, got])
	print("EMP-04 reading: the stations' free time adds up because a smith's work moves between them (forge and anvil recipes), and _station_for ignores the workplace")
