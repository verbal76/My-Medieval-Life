extends SceneTree
## NPC-04 (Build 25 audit, WP-1): NPCBrain._plan_seek_company (CRT-11) sends an unpartnered adult in the evening to spend time
## beside the one they court (or their best friend). The choice tested only alive and asleep, so a companion away on a journey
## (REGION-NAV-01: on the road or at a settlement), out at a homestead (Homesteads.remote: away and outside the village) or on
## another depth (MIN-A: underground) was still chosen and the seeker planned a walk to a cell they cannot share. The test puts
## the courted companion in each of those places: the seeker must not plan to go to them; and with the same companion at home
## the seeker does (the control).
##   godot --headless --path game --script res://tests/npc04_evening_company_away_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	var sk: Dictionary = Relations.cfg().seek
	sk.chance = 1.0          # every evening, so the rng never decides the case
	sk.poor_chance = 1.0
	for where in ["home", "journey", "homestead", "underground"]:
		test_case(where)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func pair(w: World) -> Array:
	var a: NPC = null
	var b: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.partner == -1 and o.household >= 0:
			if a == null:
				a = o
			elif b == null and o.household != a.household:
				b = o
	return [a, b]


func test_case(where: String) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var p := pair(w)
	var n: NPC = p[0]
	var who: NPC = p[1]
	check(n != null and who != null, "%s fixture: two unpartnered adults of different households" % where)
	if n == null or who == null:
		return
	w.relations.interests[n.id] = who.id
	n.coins = maxi(n.coins, 0)
	n.anim = "idle"
	who.anim = "idle"
	match where:
		"journey":
			who.journey = {"to": "s0", "purpose": {"kind": "test"}, "leg": "out", "since": w.day(), "gate": Journeys.gate_index(w)}
			who.pos = Vector2(w.map.w + 30, w.map.h + 30)          # on the road, beyond the village's map
		"homestead":
			w.households[who.household]["homestead"] = "test"
			who.pos = Vector2(-40, -40)                              # out in the country
			check(w.homesteads.remote(who), "homestead fixture: the companion is out at the homestead")
		"underground":
			who.depth = -1
	var target := who.cell()
	var planned: bool = w.brain._plan_seek_company(n)
	var to_them: bool = planned and n.plan.any(func(s): return str(s.get("k", "")) == "go" and s.has("to") and Vector2i(s.to).distance_to(target) <= 1.5)
	if where == "home":
		check(planned and str(n.doing).contains(who.name), "with the companion at home, the seeker goes to spend the evening with them (%s)" % n.doing)
	else:
		check(not to_them, "with the companion %s, the seeker does not plan to walk to them (planned: %s, doing: %s)" % [
			{"journey": "away on a journey", "homestead": "out at a homestead", "underground": "underground"}[where], str(planned), n.doing])
