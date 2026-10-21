extends SceneTree
## FARM-01..05, FARM-07, FARM-09 (owner Q9, Q11, 2026-10-21): family farmland of any size. Pricing by area
## (Property's land price and weekly rent rule, no new coefficient), lease against purchase, refusal on
## insufficient funds, overlap and access refusals, the fence and gate by the pen rule plus stone from real
## inventory, ploughing and sowing with real seed, the harvest to the household, household members' work by
## age, NPC uptake by the same rules, conservation of coins and goods, and a save. Pure World. Run:
##   godot --headless --path game --script res://tests/farm_plots_test.gd

const Census := preload("res://tests/census.gd")

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
	return w


func _init() -> void:
	test_pricing()
	test_lease_and_buy()
	test_refusals()
	test_fence()
	test_player_farming()
	test_household_farming()
	test_household_work()
	test_uptake()
	test_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A household with a home and an able adult (the first by index).
func household(w: World) -> int:
	for h in w.households.size():
		if w.buildings.has(str(w.households[h].home)) and w.brain._members(h).any(func(o: NPC) -> bool: return o.role == "adult"):
			return h
	return -1


func adult_of(w: World, h: int) -> NPC:
	for o: NPC in w.brain._members(h):
		if o.role == "adult":
			return o
	return null


## Free farmland of this size near the player's start, cleared of anything that would need clearing first.
func ground(w: World, size: Vector2i, h := 0) -> Rect2i:
	var sp = w.map.data.spawns.player
	var r: Rect2i = w.farm_plots.find_ground(size, Vector2i(int(sp[0]), int(sp[1])), h)
	return r


func clear_rect(w: World, r: Rect2i) -> void:
	for t in w.trees:
		if r.has_point(Vector2i(int(t.x), int(t.y))) and t.state != "cleared":
			t.state = "cleared"
			w.map.set_solid(Vector2i(int(t.x), int(t.y)), false)
	for pl in w.plants:
		if r.has_point(Vector2i(int(pl.x), int(pl.y))):
			pl.state = "cleared"


func goods_total(w: World, id: String) -> int:
	return int(Census.goods(w).get(id, 0))


func st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0))


func test_pricing() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	var t44 := fp.terms(Rect2i(0, 0, 4, 4))
	var t56 := fp.terms(Rect2i(0, 0, 5, 6))
	var t66 := fp.terms(Rect2i(0, 0, 6, 6))
	var t910 := fp.terms(Rect2i(0, 0, 9, 10))
	check(int(t44.price) == w.property.land_price(4, 4) and int(t44.price) == 11, "a 4x4 plot is bought at Property.land_price: ceil(60 x 16 / 90) = 11")
	check(int(t44.rent) == 2 and int(t56.rent) == 2, "16 and 30 cells lease at 2 coins a week (the FARM-07 baseline)")
	check(int(t66.rent) == 3 and int(t910.rent) == 6, "36 cells lease at 3, a 9x10 at 6 (the house plot's 6): rent follows area")
	check(int(t910.price) == int(GameData.b("plot_price")), "a 9x10 plot costs plot_price, as the house plots")
	var last := 0
	var mono := true
	for k in range(3, 14):
		var p := int(fp.terms(Rect2i(0, 0, k, k)).price)
		mono = mono and p > last
		last = p
	check(mono, "larger plots cost more to buy")
	check(int(t910.rent) > int(t44.rent), "larger plots lease for more")


func test_lease_and_buy() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	w.player.coins = 100
	var coins0 := w.total_coins()
	var r := ground(w, Vector2i(5, 6))
	check(r.size == Vector2i(5, 6), "free ground for a 5x6 plot is found")
	var t0 := w.treasury
	var p := fp.claim(r, World.PLAYER, true)
	check(not p.is_empty() and FarmPlots.is_farm(p), "the player leases farmland")
	check(w.player.coins == 98 and w.treasury == t0 + 2, "the first week's 2 coins go from the purse to the treasury")
	check(w.tenant_of(p) == World.PLAYER and int(p.rent) == 2 and w.owner_of(p) == World.MANOR, "the lease is on the land registry: the manor's, let at 2 a week")
	check(fp.plots_of(World.PLAYER).size() == 1 and w.holds(World.PLAYER, p), "the plot is the player's to use")
	# a week later the existing rent collection charges it once
	w.minutes += 7.0 * 1440.0
	w.property.collect_rents()
	check(w.player.coins == 96 and w.treasury == t0 + 4, "the weekly rent is collected by Property.collect_rents")
	w.property.collect_rents()
	check(w.player.coins == 96, "and not twice in the same week")
	# outright purchase: the price at once, no rent ever
	var r2 := ground(w, Vector2i(4, 4))
	var t1 := w.treasury
	var q := fp.claim(r2, World.PLAYER, false)
	check(not q.is_empty() and w.owner_of(q) == World.PLAYER and w.tenant_of(q) == "", "the player buys a 4x4 plot outright")
	check(w.player.coins == 96 - 11 and w.treasury == t1 + 11, "the price (11) goes to the treasury")
	check(not q.has("rent"), "bought land carries no rent")
	w.minutes += 7.0 * 1440.0
	var before := w.player.coins
	w.property.collect_rents()
	check(w.player.coins == before - 2, "a week on, only the leased plot's rent is due, not the bought one's")
	check(w.total_coins() == coins0, "coins are conserved: purse and treasury")


func test_refusals() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	w.player.coins = 1
	var r := ground(w, Vector2i(6, 6))
	var n := w.plots.size()
	var t0 := w.treasury
	check(fp.claim(r, World.PLAYER, false).is_empty() and fp.why.begins_with("you need"), "1 coin cannot buy a 6x6 plot (24): refused, %s" % fp.why)
	check(fp.claim(r, World.PLAYER, true).is_empty() and fp.why == "you need 3 coins", "nor lease it (3 a week)")
	check(w.plots.size() == n and w.treasury == t0 and w.player.coins == 1, "nothing is registered or paid")
	w.player.coins = 100
	var p := fp.claim(r, World.PLAYER, true)
	check(not p.is_empty(), "with coins it is leased")
	var over := Rect2i(r.position + Vector2i(2, 2), Vector2i(5, 5))
	check(fp.refusal(over) != "", "an overlapping rectangle is refused (%s)" % fp.refusal(over))
	check(fp.claim(over, World.PLAYER, true).is_empty(), "and cannot be claimed")
	check(fp.refusal(Rect2i(r.position, Vector2i(2, 5))) == "too small: at least 3x3 (a fence round one cell)", "a strip under 3 wide is refused")
	var house: Dictionary = w.buildings[w.buildings.keys()[0]]
	for id in w.buildings:
		if str(w.buildings[id].get("type", "")) == "house":
			house = w.buildings[id]
			break
	var step := Rect2i(int(house.x), int(house.y) + int(house.h), 4, 4)
	check(fp.refusal(step) != "", "ground over a house's door step is refused (%s)" % fp.refusal(step))
	var field: Dictionary = w.fields[0]
	check(fp.refusal(Rect2i(int(field.x), int(field.y), 4, 4)) != "", "the manor's fields are refused")
	check(fp.refusal(Rect2i(0, 0, 4, 4)) == "outside the village", "the village's edge is refused")


func test_fence() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	w.player.coins = 100
	var r := ground(w, Vector2i(5, 6))
	var p := fp.claim(r, World.PLAYER, true)
	clear_rect(w, r)
	var cost := fp.fence_cost(p)
	check(int(cost.plank) == 6 and int(cost.plank) == w.farm.pen_planks(r), "a 5x6 plot's fence (18 cells, the gate free) takes the pen rule's 6 planks")
	check(int(cost.stone) == int(GameData.b("farm_plot").gate_stone), "and the gate's stone (farm_plot.gate_stone)")
	var big := fp.fence_cost({"x": 0, "y": 0, "w": 12, "h": 8, "farm": {}})
	check(int(big.plank) == 12, "a 12x8 plot's fence (36 cells) takes 12 planks: by the actual perimeter")
	var inside := r.position + Vector2i(1, 1)
	check(fp.till_block(inside) != "", "unfenced farmland is not ploughed: %s" % fp.till_block(inside))
	check(w.farm.till_refusal(inside, w.player) == "Put up the farmland's fence and gate first.", "the player's till is refused the same way")
	w.player.inv.add("plank", 5)
	w.player.inv.add("stone", 2)
	check(fp.build_fence(p, World.PLAYER, [w.player.inv]) != "", "5 planks are not enough")
	w.player.inv.add("plank", 1)
	var planks0 := goods_total(w, "plank")
	var stone0 := goods_total(w, "stone")
	var used_p0 := st(w, "used_plank")
	check(fp.build_fence(p, World.PLAYER, [w.player.inv]) == "", "with 6 planks and 2 stone the fence goes up")
	check(not w.player.inv.has("plank") and not w.player.inv.has("stone"), "the materials are taken from the pack")
	check(goods_total(w, "plank") == planks0 - 6 and st(w, "used_plank") - used_p0 == 6, "the planks leave the world as used_plank (the ledger's drain)")
	check(goods_total(w, "stone") == stone0 - 2, "the stone is used up")
	var g := fp.gate_of(p)
	var solid := true
	for c: Vector2i in w.farm.fence_cells(r):
		if c != g:
			solid = solid and w.map.is_solid(c)
	check(solid and not w.map.is_solid(g), "the fence is solid, the gate open")
	check(fp.on_fence_line(p, g) and not fp.rect_of(p).grow(-1).has_point(g), "the gate is on the fence line")
	check(fp.build_fence(p, World.PLAYER, [w.player.inv]) == "It is fenced already.", "a fence is built once")
	check(fp.till_block(inside) == "" and fp.till_block(r.position) == "That is the fence line.", "inside the fence it can be ploughed, not on the fence line")


func test_player_farming() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	w.player.coins = 100
	var r := ground(w, Vector2i(4, 4))
	var p := fp.claim(r, World.PLAYER, true)
	clear_rect(w, r)
	w.player.inv.add("plank", 4)
	w.player.inv.add("stone", 2)
	check(fp.build_fence(p, World.PLAYER, [w.player.inv]) == "", "the player's 4x4 plot is fenced (4 planks, 2 stone)")
	var c := r.position + Vector2i(1, 1)
	w.player.stamina = 1000.0
	check(w.farm.till(c, w.player) == "", "the player ploughs inside it (Farming, the existing per-cell rules)")
	w.player.inv.add("wheat_seed", 1)
	var seed0 := goods_total(w, "wheat_seed")
	check(w.farm.sow(c, "wheat", w.player) == "", "and sows wheat")
	check(goods_total(w, "wheat_seed") == seed0 - 1, "the seed is used up")
	for i in 60:
		w.farm.hour()
	check(str(w.farm.cells[c].state) == "ripe", "it ripens in the crop's days")
	var wheat0 := w.player.inv.count("wheat")
	var got := w.farm.harvest(c, w.player)
	check(int(got.get("wheat", 0)) == 3 and w.player.inv.count("wheat") == wheat0 + 3, "the harvest goes to the player")


func test_household_farming() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	var h := household(w)
	var n := adult_of(w, h)
	check(h >= 0 and n != null, "a household with a home and an adult")
	var ref := World.hh_ref(h)
	n.coins += 50
	var coins0 := w.total_coins()
	var purse0: int = w.property.purse(ref)
	var r := ground(w, Vector2i(4, 4), h)
	var p := fp.claim(r, ref, true)
	check(not p.is_empty() and w.tenant_of(p) == ref and int(p.rent) == 2, "a household leases a 4x4 plot at the player's price (2 a week)")
	check(w.property.purse(ref) == purse0 - 2, "paid from the household's purses")
	clear_rect(w, r)
	var pantry: Inventory = w.households[h].pantry
	# the fence from the member's pack and the family chest
	n.inv.add("plank", 3)
	pantry.add("plank", 1)
	pantry.add("stone", 2)
	check(fp.act(n, "fp_fence", {"plot": str(p.id)}), "a member puts up the fence")
	check(bool(p.farm.fence) and not n.inv.has("plank") and not pantry.has("plank") and not pantry.has("stone"), "with the household's own planks and stone")
	var inner := r.grow(-1)
	var cs := []
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			cs.append([x, y])
	check(fp.act(n, "fp_work", {"plot": str(p.id), "task": "till", "cells": cs}), "the member ploughs the inside")
	check(fp.cells.size() == 4, "4 cells tilled")
	pantry.add("wheat_seed", 3)
	var seed0 := goods_total(w, "wheat_seed")
	fp.act(n, "fp_work", {"plot": str(p.id), "task": "sow", "crop": "wheat", "cells": cs})
	var sown := fp.cells.values().filter(func(e): return e.state == "growing").size()
	check(sown == 3, "3 seeds sow 3 cells, no more (one seed a cell)")
	check(goods_total(w, "wheat_seed") == seed0 - 3 and not pantry.has("wheat_seed"), "the seed is used up from the family chest")
	for i in 60:
		fp.hour()
	check(fp.cells.values().filter(func(e): return e.state == "ripe").size() == 3, "the sown cells ripen at the player's rate")
	var wheat0 := pantry.count("wheat")
	var made0 := st(w, "farm_harvest_wheat")
	fp.act(n, "fp_work", {"plot": str(p.id), "task": "harvest", "cells": cs})
	check(pantry.count("wheat") == wheat0 + 9 and pantry.count("wheat_seed") == 3, "the harvest (3 wheat a cell and the seed back) goes to the family chest")
	check(st(w, "farm_harvest_wheat") - made0 == 9, "counted as farm_harvest_ (the ledger's faucet)")
	check(w.total_coins() == coins0, "coins are conserved")
	# another household's member cannot work it
	for o: NPC in w.npcs:
		if o.alive and o.household >= 0 and o.household != h:
			check(not fp.act(o, "fp_work", {"plot": str(p.id), "task": "harvest", "cells": cs}), "someone of another household cannot work the plot")
			break


func test_household_work() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	var h := household(w)
	var ref := World.hh_ref(h)
	var n := adult_of(w, h)
	n.coins += 50
	var r := ground(w, Vector2i(4, 4), h)
	var p := fp.claim(r, ref, true)
	clear_rect(w, r)
	var pantry: Inventory = w.households[h].pantry
	pantry.add("plank", 4)
	pantry.add("stone", 2)
	check(fp.plan_work(n), "an able adult plans work on the family's plot")
	check(str(n.plan.back().get("act", "")) == "fp_fence", "the fence first, once the ground is clear")
	fp.act(n, "fp_fence", {"plot": str(p.id)})
	check(fp.plan_work(n) and str(n.plan.back().args.task) == "till", "then ploughing")
	var mins := float(n.plan.back().min)
	var per := float(Farming.cfg().till.hand.seconds) * float(GameData.b("game_minutes_per_second"))
	check(is_equal_approx(mins, per * 4.0), "at the player's time a cell by hand (%.0f game minutes for 4 cells)" % mins)
	var elder: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "elder" and o.household >= 0:
			elder = o
			break
	if elder != null:
		var eh := elder.household
		var er := ground(w, Vector2i(4, 4), eh)
		w.households[eh].pantry.add("plank", 4)
		var ep := fp.claim(er, World.hh_ref(eh), false) if w.property.purse(World.hh_ref(eh)) >= 11 else {}
		if not ep.is_empty():
			clear_rect(w, er)
			check(not fp.plan_work(elder), "an elder does not put up fences or plough (heavy work)")
	var child: NPC = null
	for o: NPC in w.brain._members(h):
		if o.role == "child":
			child = o
	if child != null:
		check(not fp.able(child), "a child does not work the plot")
	n.hp = n.max_hp * 0.2
	check(not fp.able(n), "a badly hurt member rests instead")


func test_uptake() -> void:
	var a := _uptake_run()
	var b := _uptake_run()
	check(a == b, "the households' choices are deterministic (%s)" % str(a))


func _uptake_run() -> Array:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	var out := []
	var h := household(w)
	var ref := World.hh_ref(h)
	var need := fp.land_requirement(h)
	check(need >= 1, "the household's land requirement: %d cells for a year's food" % need)
	var per_adult := 24.0 * float(GameData.b("hunger_per_hour")) * Life.year_days() / fp.cell_food_per_year()
	check(per_adult < 1.7, "FSE-15: an adult needs %.2f cells a year at the net yield (not the 1.7 assumed before)" % per_adult)
	check(fp.labour_cells(h) >= need, "its able members can tend that many cells (%d)" % fp.labour_cells(h))
	# poor: nothing above its reserve, it takes nothing
	for o: NPC in w.brain._members(h):
		o.coins = 0
	w.households[h].econ = {"sustainable": false}
	var n0 := w.plots.size()
	check(fp.consider(h).is_empty() and w.plots.size() == n0, "a household without coins to spare takes no farmland (no free land)")
	# in need and with coins: it takes a plot by the player's prices
	var n := adult_of(w, h)
	n.coins = 300
	var t0 := w.treasury
	var p := fp.consider(h)
	check(not p.is_empty() and w.holds(ref, p), "a household short of food with coins to spare takes farmland")
	if not p.is_empty():
		var r := FarmPlots.rect_of(p)
		var t := fp.terms(r)
		var paid := w.treasury - t0
		check(paid == (int(t.rent) if w.tenant_of(p) == ref else int(t.price)), "it pays the same price as the player would (%d)" % paid)
		check((r.size.x - 2) * (r.size.y - 2) >= need, "the plot holds its land requirement (%d cells inside)" % ((r.size.x - 2) * (r.size.y - 2)))
		out.append([r.position.x, r.position.y, r.size.x, r.size.y, w.tenant_of(p), paid])
	# a household that eats well and earns does not
	var h2 := -1
	for k in w.households.size():
		if k != h and w.buildings.has(str(w.households[k].home)) and not w.brain._members(k).is_empty():
			h2 = k
			break
	if h2 >= 0:
		for o: NPC in w.brain._members(h2):
			o.coins = 300
		w.households[h2].pantry.add("wheat", 400)
		w.households[h2].econ = {"sustainable": true}
		check(fp.consider(h2).is_empty(), "a household with plenty of food and a living does not take farmland (no quota)")
	return out


func test_save() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	var h := household(w)
	var n := adult_of(w, h)
	n.coins += 50
	var r := ground(w, Vector2i(4, 4), h)
	var p := fp.claim(r, World.hh_ref(h), true)
	clear_rect(w, r)
	w.households[h].pantry.add("plank", 4)
	w.households[h].pantry.add("stone", 2)
	fp.act(n, "fp_fence", {"plot": str(p.id)})
	var c := r.position + Vector2i(1, 1)
	fp.act(n, "fp_work", {"plot": str(p.id), "task": "till", "cells": [[c.x, c.y]]})
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var p2 := w2.plot(str(p.id))
	check(FarmPlots.is_farm(p2) and bool(p2.farm.fence) and w2.tenant_of(p2) == World.hh_ref(h), "the plot, its lease and its fence survive a save")
	check(w2.farm_plots.cells.has(c) and str(w2.farm_plots.cells[c].plot) == str(p.id), "the household's tilled cell survives a save")
	var g := w2.farm_plots.gate_of(p2)
	check(w2.map.is_solid(r.position) and not w2.map.is_solid(g), "the fence is solid again after loading, the gate open")
	var old: Dictionary = d.duplicate(true)
	old.erase("farm_plots")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.farm_plots != null and w3.farm_plots.cells.is_empty(), "a save without farmland loads with none")
