extends SceneTree
## B25R1-011 (owner 2026-11-03: roads upgrade with use, fade without it; main roads only grow over; stone is damaged slowly,
## hampers carts and is repaired with stone; the player paves with stone; the village pays a worker and supplies stone),
## checked in the real game scene, headless:  godot --headless --path game --script res://tests/road_wear_test.gd

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		printerr("FAIL: " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("new_game"):
		print("FAIL the game's main script did not load: stopping")
		quit(1)
		return
	main.save_path = "user://test_saves/road_wear_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _frames(n: int, dt := 0.1) -> void:
	for i in n:
		main._process(dt)


func _days(n: float) -> void:
	var w: World = main.world
	w.minutes += n * 1440.0
	w.map.overworld.clock = w.minutes


## An open grass cell near the south road, no road within 3 tiles.
func _grass(ow: Overworld, near: Vector2i) -> Vector2i:
	for r in range(6, 40):
		for d in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(r, r)]:
			var c: Vector2i = near + d
			var ok := not ow.is_solid(c) and not ow.village.has_point(c) and RoadWear.base_level(ow, c) == 0
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					if ow.is_road(c + Vector2i(dx, dy)):
						ok = false
			if ok:
				return c
	return Vector2i.ZERO


func _run() -> void:
	main.set_process(false)
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var road := ow.road_route(Journeys.gate_index(w), "wulstead")
	var kinds := RegionRoads.main_kinds(ow)
	var dirt := Vector2i.ZERO
	var stone := Vector2i.ZERO
	for c in road:
		var ci := Vector2i(c)
		if dirt == Vector2i.ZERO and kinds.get(ci, "") == "road":
			dirt = ci
		if stone == Vector2i.ZERO and kinds.get(ci, "") == "stone" and not ow.village.grow(2).has_point(ci):
			stone = ci
	var g := _grass(ow, Vector2i(road[60]))
	check(g != Vector2i.ZERO and dirt != Vector2i.ZERO and stone != Vector2i.ZERO, "cells to test: grass %s, dirt road %s, stone %s" % [g, dirt, stone])
	# --- wear: grass -> trail -> dirt road by footfall
	var steps_trail := 0
	while RoadWear.level(ow, g) < 1 and steps_trail < 100:
		RoadWear.foot(ow, g)
		steps_trail += 1
	check(steps_trail == int(100.0 / RoadWear.FOOT), "grass becomes a trail after %d steps (100%%)" % steps_trail)
	check(ow.road_dirty.has(g), "the change is marked for the view to redraw")
	var steps_road := 0
	while RoadWear.level(ow, g) < 2 and steps_road < 100:
		RoadWear.foot(ow, g)
		steps_road += 1
	check(steps_road == int(100.0 / RoadWear.FOOT), "and a dirt road after %d more" % steps_road)
	for k in 30:
		RoadWear.foot(ow, g)
	check(RoadWear.level(ow, g) == 2, "footfall never makes stone (paving does)")
	check(not ow.is_solid(g) and not w.map.is_solid_world(g), "a worn way stays open ground")
	# the view draws it
	var view: OverworldView = main.ow_view
	check(view.road_tile(g, -1) >= 0, "the worn road is drawn (tile %d)" % view.road_tile(g, -1))
	# routing prefers it: straight over the worn cells costs less than over grass
	var a := g + Vector2i(0, -3)
	for k in 7:
		for n in 45:
			RoadWear.foot(ow, a + Vector2i(0, k))
	check(RegionTravel._line_cost(w, a, a + Vector2i(0, 6)) < 6.0 * RegionTravel.OFF_ROAD * 0.6, "a worn path counts as road for the route's cost (%.1f against %.1f over grass)" % [RegionTravel._line_cost(w, a, a + Vector2i(0, 6)), 6.0 * RegionTravel.OFF_ROAD])
	# --- usage paths fade without traffic, faster than main roads
	var u0 := RoadWear.gained(ow, g)
	_days(5)
	check(RoadWear.gained(ow, g) < u0 and RoadWear.level(ow, g) == 1, "unwalked, a worn road fades back to a trail (%.0f%% -> %.0f%%)" % [u0, RoadWear.gained(ow, g)])
	_days(20)
	check(RoadWear.level(ow, g) == 0, "and to grass")
	# --- main dirt roads never go: they only grow over, and footfall clears that
	check(RoadWear.level(ow, dirt) == 2 and RoadWear.overgrown(ow, dirt), "a main dirt road unwalked for %d days is grown over but still a road" % RoadWear.day_of(ow))
	_days(400)
	check(RoadWear.level(ow, dirt) == 2 and ow.is_road(dirt) and RegionRoads.main_cells(ow).has(dirt), "after 400 more days it is still a road, on the network and the map")
	check(bool(RegionTravel.plan(w, Vector2i(w.player.pos.floor()), Vector2i(road[200])).ok), "and still routed along")
	var t_over := view.road_tile(dirt, -1)
	RoadWear.foot(ow, dirt)
	check(not RoadWear.overgrown(ow, dirt) and view.road_tile(dirt, -1) != t_over, "a step clears the overgrowth (drawn again: %d -> %d)" % [t_over, view.road_tile(dirt, -1)])
	# --- stone: slow damage, carts hampered, repair with stone
	var day0 := RoadWear.day_of(ow)
	check(RoadWear.damage(ow, stone) >= RoadWear.BROKEN, "a stone road unrepaired for %d days is broken (%.0f%%)" % [day0, RoadWear.damage(ow, stone)])
	check(RoadWear.level(ow, stone) == 3 and not ow.is_solid(stone), "broken stone is still stone road, still open")
	check(RoadWear.cart_factor(ow, stone) == RoadWear.CART_BROKEN, "a cart on broken stone goes at %d%%" % roundi(RoadWear.CART_BROKEN * 100))
	var p: PlayerState = w.player
	p.pos = Vector2(stone) + Vector2(0.5, 0.5)
	p.inv.remove("stone", p.inv.count("stone"))
	check(main.paving.refusal(main, stone).begins_with("You need"), "repair refused without stone (%s)" % main.paving.refusal(main, stone))
	p.inv.add("stone", 3)
	var used0 := float(w.stats.get("used_stone", 0.0))
	main.paving.here(main)
	_frames(int(Paving.SECS / 0.1) + 3)
	check(RoadWear.damage(ow, stone) < 1.0 and p.inv.count("stone") == 3 - RoadWear.REPAIR_STONE, "repaired with %d stone (damage %.0f%%)" % [RoadWear.REPAIR_STONE, RoadWear.damage(ow, stone)])
	check(is_equal_approx(float(w.stats.get("used_stone", 0.0)) - used0, float(RoadWear.REPAIR_STONE)), "the stone is counted used (the goods ledger)")
	_days(10)
	check(RoadWear.damage(ow, stone) > 0.0 and RoadWear.damage(ow, stone) < RoadWear.DAMAGED, "damage comes back slowly (%.0f%% after 10 days)" % RoadWear.damage(ow, stone))
	# --- carts wear stone much faster than people
	var s1 := Vector2i.ZERO
	var s2 := Vector2i.ZERO
	for c in road:
		var ci := Vector2i(c)
		if kinds.get(ci, "") == "stone" and ci != stone and not ow.village.grow(2).has_point(ci):
			if s1 == Vector2i.ZERO:
				s1 = ci
			elif s2 == Vector2i.ZERO and ci.distance_to(s1) > 3:
				s2 = ci
	RoadWear.repair(ow, s1)
	RoadWear.repair(ow, s2)
	for k in 20:
		RoadWear.foot(ow, s1, false)
		RoadWear.foot(ow, s2, true)
	check(RoadWear.damage(ow, s2) > RoadWear.damage(ow, s1) * 5.0 and RoadWear.damage(ow, s1) > 0.0, "20 carts damage stone %.1f%%, 20 walkers %.1f%% (a cart %dx a person, balance.json road_wear)" % [RoadWear.damage(ow, s2), RoadWear.damage(ow, s1), int(GameData.b("road_wear").stone_cart_multiplier)])
	var cart := {"pos": Vector2(stone) + Vector2(0.5, 0.5), "kind": "handcart"}
	for k in 400:
		RoadWear.foot(ow, stone, true)
	check(RoadWear.damage_state(ow, stone) == "broken" and w.carts.pull_speed_for(cart) < Carts.pull_speed(), "a cart on stone broken by carts is slowed (%.2f of walking against %.2f)" % [w.carts.pull_speed_for(cart), Carts.pull_speed()])
	RoadWear.repair(ow, stone)
	# --- the player paves a dirt road with stone
	var pv := dirt
	p.pos = Vector2(pv) + Vector2(0.5, 0.5)
	p.inv.remove("stone", p.inv.count("stone"))
	check(main.paving.refusal(main, pv) != "", "paving refused without stone (%s)" % main.paving.refusal(main, pv))
	check(main.paving.refusal(main, g + Vector2i(3, 3)).begins_with("That is not a road"), "and on grass (%s)" % main.paving.refusal(main, g + Vector2i(3, 3)))
	p.inv.add("stone", RoadWear.PAVE_STONE)
	main.paving.toggle(main)
	check(main.paving.tap(main, pv), "in paving mode a tap on the road is taken")
	_frames(int(Paving.SECS / 0.1) + 3)
	check(RoadWear.level(ow, pv) == 3 and p.inv.count("stone") == 0, "the player paves it: stone road, %d stone used" % RoadWear.PAVE_STONE)
	main.paving.toggle(main)
	_days(30)
	check(RoadWear.level(ow, pv) == 3, "paving never fades back")
	# --- the village pays a worker and supplies stone
	var mw: ManorWork = w.manor_work
	mw.yard.add("stone", 30)
	w.treasury = maxf(w.treasury, 500.0)
	mw.post_paving()
	var job := {}
	for j in mw.jobs:
		if j.kind == "mend" and j.has("pave"):
			job = j
	check(not job.is_empty(), "the manor posts a paving job (%s)" % mw.describe(job) if not job.is_empty() else "the manor posts a paving job")
	if not job.is_empty():
		var cells: Array = job.pave
		var yard0 := mw.yard.count("stone")
		var t0 := w.treasury
		var c0 := p.coins
		p.inv.remove("stone", p.inv.count("stone"))
		check(mw.take(job, "player"), "the job is taken (%s)" % mw.last_refusal)
		var wage := int(job.reserved)
		check(mw.do_step(job, "player", p.inv), "the yard's stone is collected")
		check(mw.yard.count("stone") == yard0 - int(job.qty), "%d stone leave the works yard" % int(job.qty))
		check(mw.do_step(job, "player", p.inv), "and the road is paved")
		var paved := 0
		for e in cells:
			if RoadWear.level(ow, Vector2i(int(e[0]), int(e[1]))) == 3 and RoadWear.damage(ow, Vector2i(int(e[0]), int(e[1]))) < 1.0:
				paved += 1
		check(paved == cells.size(), "all %d cells of the busiest road outside the village are stone (%d)" % [cells.size(), paved])
		check(is_equal_approx(t0 - w.treasury, float(wage)) and p.coins == c0 + wage, "the worker is paid %d coins from the treasury (no coin made)" % wage)
	# --- save and load, determinism
	RoadWear.foot(ow, g)
	var before := RoadWear.to_save(ow)
	check(main.save_game(false), "saved")
	var d := SaveStore.inspect(main.save_path, World.SAVE_VERSION)
	main._load_save(d.data)
	main.ui.hide_all()
	var ow2: Overworld = main.world.map.overworld
	check(RoadWear.to_save(ow2) == before and RoadWear.level(ow2, pv) == 3, "the worn, paved and repaired cells come back from the save (%d)" % before.size())
	var old := ow2.to_dict()
	old.erase("roads")
	ow2.load_dict(old)
	check(ow2.road_state.is_empty(), "an older save (no roads key) loads with none")
	var o1 := Overworld.create(7, main.map)
	var o2 := Overworld.create(7, main.map)
	for o in [o1, o2]:
		for k in 300:
			RoadWear.foot(o, Vector2i(30 + k % 17, 140 + (k * 7) % 23), k % 5 == 0)
		o.clock = 3.0 * 1440.0
		RoadWear.prune(o)
	check(RoadWear.to_save(o1) == RoadWear.to_save(o2) and not o1.road_state.is_empty(), "the same steps give the same roads (deterministic, %d cells)" % o1.road_state.size())
	o1.clock = 60.0 * 1440.0
	RoadWear.prune(o1)
	check(o1.road_state.size() < o2.road_state.size(), "faded cells are forgotten at dawn (bounded: %d -> %d)" % [o2.road_state.size(), o1.road_state.size()])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
