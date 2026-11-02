extends SceneTree
## KI-HOME-DOOR (flight recorder campaign run 41469410306, seed 2, findings F001/F002: 5,359 script errors in days 200-300 and
## 5,813 in days 300-365, every one World.building_door from NPCBrain._plan_evening on a villager whose home was not a building).
## A villager's evening, bed and strolls never look up the door of a building that is not there, and still give them a rest:
## one who begins homeless (a household that came for land and is building), one whose household loses its house (sold back,
## lease ended) with and without kin to lodge with, one who moves to another house, and one whose home is gone from the
## buildings. Pure World (no scene). Run headless:
##   godot --headless --path game --script res://tests/home_ref_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_begins_homeless()
	test_home_sold_no_kin()
	test_home_sold_lodges_with_kin()
	test_moves_to_another_home()
	test_home_removed()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A villager household (not the founding ones: index 3 on) with a house it holds, and an adult of it.
func _household(w: World) -> int:
	for h in range(3, w.households.size()):
		var hh: Dictionary = w.households[h]
		if w.buildings.has(str(hh.home)) and w.holds(World.hh_ref(h), w.buildings[hh.home]) and _adult(w, h) != null:
			return h
	return -1


func _adult(w: World, h: int) -> NPC:
	for o: NPC in w.brain._members(h):
		if o.role == "adult":
			return o
	return null


func _manor_door(w: World) -> Vector2i:
	return w.building_door(w.brain._manor_id())


## The evening (with no tavern or company: before the work day ends) and the bed: each makes a plan, and a homeless villager's
## bed is a rest where they stand. A look-up of a missing building aborts the planner and leaves the plan empty.
func _rests(w: World, n: NPC, what: String) -> void:
	n.plan.clear()
	n.coins = 0
	n.hp = n.max_hp
	w.brain._plan_evening(n, 17.0)
	check(not n.plan.is_empty(), what + ": the evening makes a plan")
	if n.doing == "resting":                    # the evening's rest walks about the rest cell, not about a door that is not there
		var to: Vector2i = n.plan[0].get("to", Vector2i(-99, -99))
		check(to.distance_to(w.brain.rest_cell(n)) <= 6.0, what + ": the evening rest is taken by the rest cell")
	n.plan.clear()
	w.brain._plan_bed(n, 60.0, true)
	check(not n.plan.is_empty() and str(n.plan.back().get("k", "")) == "work" and float(n.plan.back().get("min", 0.0)) == 60.0,
		what + ": the bed is a rest of the stated length")
	if not w.buildings.has(n.home):
		check(n.plan.size() == 1 and str(n.plan[0].get("anim", "")) == "idle", what + ": with no house, they rest where they stand")
	var meal: Array = w.brain._home_meal(n)     # a meal from the household's pantry, and its stores, where they keep to
	if not w.buildings.has(n.home):
		check(Vector2i(meal[0].to) == w.brain.rest_cell(n), what + ": the home meal is taken by the rest cell")
		n.inv.add("handcart", 1)
		w.brain.act(n, "store_home", {})
		check(n.inv.has("handcart"), what + ": with no house to set it down by, the handcart stays in hand")
		n.inv.remove("handcart", 1)
	else:
		check(not meal.is_empty(), what + ": the home meal is planned")
	var was := n.role
	n.role = "child"                            # a child's play walks about the same cell
	n.hunger = 100.0
	n.plan.clear()
	var why: String = w.brain._decide(n) if w.hour() >= NPCBrain.WAKE and w.hour() < NPCBrain.SLEEP else "night"
	n.role = was
	check(why == "night" or not n.plan.is_empty(), what + ": a child's day is planned (%s)" % why)


func test_begins_homeless() -> void:
	var w := new_world()
	var h := _household(w)
	var n := _adult(w, h)
	# as a household that came for land (Migration._household_out, reason "land"): a household of its own, no house yet
	var nh := {"id": w.households.size(), "family": "Newcome", "home": "", "members": [n.id], "pantry": Inventory.new(), "founded_day": w.day()}
	w.households.append(nh)
	(w.households[h].members as Array).erase(n.id)
	n.household = int(nh.id)
	n.home = ""
	check(w.brain.rest_cell(n) == _manor_door(w), "begins homeless: rests by the manor, where a household seeking a home arrives")
	_rests(w, n, "begins homeless")


func test_home_sold_no_kin() -> void:
	var w := new_world()
	var h := _household(w)
	var hh: Dictionary = w.households[h]
	var lost := str(hh.home)
	hh.family = "Nokin"                         # no other household of the family to lodge with
	hh.erase("founded_from")
	var n := _adult(w, h)
	w.set_owner(w.buildings[lost], World.MANOR)  # sold back to the manor (or the lease taken back)
	w.construction._rehouse(h)
	check(str(hh.home) == "", "home sold, no kin: the household has no house")
	check(w.brain._members(h).all(func(o: NPC) -> bool: return o.home == ""), "home sold, no kin: no member still lives in the sold house")
	check(w.brain.rest_cell(n) == _manor_door(w), "home sold, no kin: rests by the manor")
	_rests(w, n, "home sold, no kin")


func test_home_sold_lodges_with_kin() -> void:
	var w := new_world()
	var h := _household(w)
	var hh: Dictionary = w.households[h]
	var kin := -1
	for k in range(3, w.households.size()):
		if k != h and w.buildings.has(str(w.households[k].home)) and str(w.households[k].home) != str(hh.home):
			kin = k
			break
	hh.founded_from = kin
	var host := str(w.households[kin].home)
	var lost := str(hh.home)
	var n := _adult(w, h)
	w.set_owner(w.buildings[lost], World.MANOR)
	w.construction._rehouse(h)
	check(str(hh.home) == "" and w.brain._members(h).all(func(o: NPC) -> bool: return o.home == host),
		"home sold: the household lodges in the house of the household it came from")
	check(w.brain.rest_cell(n) == w.building_door(host), "home sold: rests by the kin's house")
	_rests(w, n, "home sold, lodging")
	# the family is found by name when the household it came from is gone
	w.households[kin].ended = true
	var other := -1
	for k in range(3, w.households.size()):
		if k != h and k != kin and w.buildings.has(str(w.households[k].home)):
			other = k
			break
	w.households[other].family = hh.family
	check(w.construction._kin_home(h) == str(w.households[other].home), "with the founding household gone, the first of the family takes them in")


func test_moves_to_another_home() -> void:
	var w := new_world()
	var h := _household(w)
	var n := _adult(w, h)
	var other := ""
	for id in w.buildings:
		if w.property.is_home(w.buildings[id]) and id != str(w.households[h].home):
			other = str(id)
			break
	w.construction.move_in(h, other)
	check(n.home == other and w.brain.rest_cell(n) == w.building_door(other), "moves to another home: rests by the new one")
	_rests(w, n, "moved home")


func test_home_removed() -> void:
	var w := new_world()
	var h := _household(w)
	var n := _adult(w, h)
	var gone := str(w.households[h].home)
	w.buildings.erase(gone)                     # a building no longer in the world (no code path removes one today; a save could)
	check(not w.buildings.has(n.home), "home removed: the reference is to no building")
	check(w.brain.rest_cell(n) == _manor_door(w), "home removed: rests by the manor")
	_rests(w, n, "home removed")
	check(w.household_cell(h, n.cell()) == n.cell(), "home removed: the household is found where its member stands")
