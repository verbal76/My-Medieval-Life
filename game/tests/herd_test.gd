extends SceneTree
## FARM-08B: the cattle investigation's defects, fixed and kept fixed. A keeper short of feed culls the elderly (who no
## longer breed) before the young that would replace them. Nothing is spawned, fed or paid for by the rules under test.
## Run: godot --headless --path game --script res://tests/herd_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 9.0 * 60.0                     # mid-morning: nobody asleep
	return w


func _init() -> void:
	test_cull_order()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _clear_pen(w: World, pen: Dictionary) -> void:
	for a: Animal in w.fauna.animals.duplicate():
		if a.area == pen.id:
			w.fauna.remove(a)


func _beast(w: World, pen: Dictionary, sex: String, age_days: float) -> Animal:
	var a := w.fauna.spawn(pen.id, str(pen.kind), sex, null)
	a.born = w.minutes - age_days * 1440.0
	return a


## No wheat anywhere a keeper could get it: every pack, chest and the trough emptied.
func _no_grain(w: World, pen: Dictionary) -> void:
	for o: NPC in w.npcs:
		o.inv.remove("wheat", o.inv.count("wheat"))
	for hh in w.households:
		(hh.pantry as Inventory).remove("wheat", (hh.pantry as Inventory).count("wheat"))
	pen.trough = 0


func _plan_acts(n: NPC) -> Array:
	return n.plan.map(func(st): return str(st.get("act", "")))


func test_cull_order() -> void:
	var w := new_world()
	var pen: Dictionary = w.fauna.pen_of("cow")
	var sp: Dictionary = GameData.b("animals").cow
	var grown := Animal.stage_days(sp, "grow") + 1.0
	var old := Animal.stage_days(sp, "elder") + 1.0
	_clear_pen(w, pen)
	var bull := _beast(w, pen, "m", grown)
	var cow1 := _beast(w, pen, "f", grown)
	var cow2 := _beast(w, pen, "f", grown)
	var calf := _beast(w, pen, "f", 2.0)
	check(w.fauna.surplus(pen, true) == calf, "breeding stock only (a bull, two cows) and a calf: short of feed, the calf goes")
	var elder := _beast(w, pen, "f", old)
	check(elder.elderly(w.minutes) and not elder.breeds(w.minutes), "an elderly cow no longer breeds")
	check(w.fauna.surplus(pen, true) == elder, "short of feed, the elderly cow goes before the calf that would replace her")
	w.fauna.remove(cow2)
	w.fauna.remove(cow1)
	check(w.fauna.surplus(pen, true) == elder, "even with the breeding cows short of the keep, an elderly cow is no breeding stock")
	w.fauna.remove(elder)
	var old_bull := _beast(w, pen, "m", old)
	check(w.fauna.surplus(pen, true) == old_bull, "an elderly bull goes too, the young bull is kept")
	check(bull.alive and calf.alive, "nothing else was touched")
	# not short of feed: a pen below its cap keeps everyone, elders included
	check(w.fauna.surplus(pen) == null, "a pen below its cap culls nobody when there is feed")
	w.dispose()
