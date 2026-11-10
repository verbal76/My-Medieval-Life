extends SceneTree
## BIZ-05 (Build 25 audit): a venture's hands (independent craftspeople at its benches, B25-BIZ-D2) already fill one of its places
## each. The dawn hiring (Ventures._hire) counts its places as keeper + hands + employees; it must not then take one of its own
## hands on as a paid employee as well (their job is the trade, so they pass the candidate filter), or one person fills two
## places and the business pays a wage to someone already at its benches. Fixture: an open smithy with room for more, one
## hand who is by far the most skilled smith, and another willing adult with some skill; the dawn hiring takes someone not already at its benches.
##   godot --headless --path game --script res://tests/biz05_hand_not_hired_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_hand_not_hired()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	w.judgment.cfg.decision.integration.work_accept = false      # the villager's own yes is JudgmentLive's test; here the terms
	return w


func of_job(w: World, job: String) -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.job == job)


## The fixtures of biz03_payroll_priority_test.gd: the village's best smith founds, builds and opens a smithy.
func founder(w: World) -> NPC:
	var s: NPC = null
	for o: NPC in of_job(w, "smith"):
		if s == null or Skills.level(o, "smithing") > Skills.level(s, "smithing"):
			s = o
	var key := World.npc_ref(s.id)
	if not w.experience.minutes.has(key):
		w.experience.minutes[key] = {}
	w.experience.minutes[key]["smithing"] = 480.0 * 60.0
	s.coins += 3000
	w.brain.evaluate_household(s.household)
	return s


func smithy_full(w: World) -> void:
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var d := {}
		for kind in NPCBrain.TRADE_STATIONS.smith:
			for st in w.stations_of(kind):
				if w.ventures.venture_at(st).is_empty():
					d[st] = {"smith": day}
		past.append(d)
	w.station_load = {"day": w.day(), "today": {}, "past": past}


func open_one(w: World) -> Array:
	var s := founder(w)
	smithy_full(w)
	w.ventures.found(s, w.ventures.eligible(s))
	var hh: Dictionary = w.households[s.household]
	var p: Dictionary = w.plot(str(hh.build))
	var pantry: Inventory = hh.pantry
	for id in p.site.need.duplicate():
		pantry.add(id, int(p.site.need[id]))
	w.deliver(p, pantry)
	var b: Dictionary = w.buildings.get(str(p.get("building", "")), {})
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	return [s, b]


func test_hand_not_hired() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	check(b.has("venture"), "fixture: the smithy is open")
	if not b.has("venture"):
		return
	var v: Dictionary = b.venture
	var ref := Ventures.ref_of(b)
	# room for a third: the keeper and one hand at its benches leave one place
	var sts: Array = w.ventures.trade_stations(b, "smith")
	check(not sts.is_empty(), "fixture: the smithy has smith stations")
	if sts.is_empty():
		return
	var places := 0
	for st in sts:
		places += int(w.stations[st].get("capacity", 1))
	if places < 3:
		w.stations[sts[0]]["capacity"] = int(w.stations[sts[0]].get("capacity", 1)) + 3 - places
		places = 3
	var hand: NPC = null
	var other: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.household != s.household and o.job in Construction.HIRABLE \
				and w.employment.refusal(o, "smith", ref) == "":
			if hand == null:
				hand = o
			elif other == null:
				other = o
	check(hand != null and other != null, "fixture: a hand and another willing adult")
	if hand == null or other == null:
		return
	hand.job = "smith"
	hand.skills["smithing"] = Skills.xp_for_level(10)          # by far the most suitable for the place
	v.hands.append(hand.id)
	w.permit(b, World.npc_ref(hand.id), true)
	other.skills["smithing"] = Skills.xp_for_level(1)
	check(w.employment.refusal(hand, "smith", ref) == "", "fixture: the hand passes the employment terms on their own (their job is the trade)")
	v.till = w.employment.market_wage("smith") * 100
	smithy_full(w)
	check(bool(w.brain.skilled_place("smith").work), "fixture: the trade has work")
	w.ventures._hire(b)
	var emps: Array = w.employment.of_employer(ref)
	check(not w.employment.is_employed(hand), "the business does not take its own hand on as a paid employee")
	check((v.hands as Array).has(hand.id), "the hand stays one of its hands")
	check(1 + (v.hands as Array).size() + emps.size() <= places, "nobody fills two places: keeper, hands and employees within its %d places (%d)" % [places, 1 + (v.hands as Array).size() + emps.size()])
	check(emps.size() == 1 and int(emps[0].npc) != hand.id, "the place goes to another willing adult (%d employees)" % emps.size())
