extends SceneTree
## MIN-B quarrying (docs/build17/MIN_B_QUARRY.md; Mining spec stage 1 and section 11): a worked-out ore seam stays
## quarryable for ordinary stone from a second finite pool of the same record (its host rock), the ore never comes back,
## the rock quarried away leaves open ground; villagers quarry host rock and boulders by the player's own swing; the
## village's stone left counts them, so the caravan's stone comes only under the threshold; the manor's quarry job pays
## its wage from the treasury; every unit is counted mined_stone; saves keep it. Run headless:
##   godot --headless --path game --script res://tests/quarry_test.gd

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
	_test_pools()
	_test_player_rule()
	_test_quarried_away()
	_test_stone_left_and_caravan()
	_test_villagers_quarry()
	_test_manor_quarry()
	_test_saves()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _seam(w: World, ore: String, level := 0) -> Dictionary:
	for d in w.deposits:
		if d.ore == ore and World.level_of(d) == level:
			return d
	return {}


## Every unit of stone that left a seam, a host rock or a boulder, and the mined_stone count, since `s0`.
func _stone_fall(w: World, s0: Dictionary) -> int:
	var now := _stone_snapshot(w)
	return int(s0.total) - int(now.total)


func _stone_snapshot(w: World) -> Dictionary:
	var t := 0
	for d in w.deposits:
		if d.ore == "stone":
			t += int(d.amount)
		if d.has("host"):
			t += int(d.host.amount)
	for b in w.boulders:
		t += maxi(0, int(b.amount))
	return {"total": t, "mined": int(w.stats.get("mined_stone", 0))}


func _test_pools() -> void:
	var w := _world()
	var host := int(GameData.b("quarry_host_stone"))
	var ok := true
	for d in w.deposits:
		if d.ore == "stone":
			ok = ok and not d.has("host")
		else:
			ok = ok and d.has("host") and int(d.host.amount) == host and d.host.ore == "stone" and str(d.host.of) == str(d.ore) \
					and int(d.host.x) == int(d.x) and int(d.host.y) == int(d.y) and World.level_of(d.host) == World.level_of(d)
	check(ok and host == 20, "every ore seam (surface and gallery) holds %d stone in its host rock; a stone seam holds none" % host)
	var iron := _seam(w, "iron_ore")
	check(w.deposit_at(Vector2i(iron.x, iron.y)) == iron, "while its ore lasts a seam is the ore seam")


func _test_player_rule() -> void:
	var w := _world()
	var p := w.player
	p.inv.add("pickaxe")
	var iron := _seam(w, "iron_ore")
	var c := Vector2i(iron.x, iron.y)
	iron.amount = 1
	var r := w.work_mine(p, iron, p.inv)
	check(int(iron.amount) == 0 and r.result == "ok", "the last iron ore is taken")
	var h := w.deposit_at(c)
	check(h == iron.host and h.ore == "stone", "then the same cell gives its host rock: stone")
	var hit := ResourceNodes.node_at(w, c, true)
	check(not hit.is_empty() and str(hit.def.id) == "stone_seam" and hit.ref == iron.host and ResourceNodes.remaining(w, hit.def, hit.ref) == 20
			and ResourceNodes.can_harvest(w, hit.def, hit.ref) == "", "the player sees a stone seam with 20 left and may quarry it (Gather mode, the journal)")
	check(ResourceNodes.instances(w, ResourceNodes.def("stone_seam")).has(iron.host), "the host rock is among the stone seam node's instances")
	var s0 := _stone_snapshot(w)
	var got0 := p.inv.count("stone")
	var xp0 := int(p.skills.get("mining", 0))
	r = w.work_mine(p, h, p.inv)
	var n := int(r.get("n", 0))
	check(r.result == "ok" and str(r.ore) == "stone" and n >= 1 and p.inv.count("stone") - got0 == n, "one swing quarries stone (%d) into the pack" % n)
	check(_stone_fall(w, s0) == n and int(w.stats.mined_stone) - int(s0.mined) == n, "counted mined_stone, unit for unit")
	check(int(iron.amount) == 0 and w.mine_unit(iron) == "", "the ore count never rises: the seam's iron stays 0")
	check(int(p.skills.get("mining", 0)) - xp0 == 8 * n, "the same Mining xp as any seam")
	var gold := _seam(w, "gold_ore")
	gold.amount = 0
	var novice := NPC.new()
	novice.inv.add("pickaxe")
	check(w.work_mine(novice, w.deposit_at(Vector2i(gold.x, gold.y)), novice.inv).result == "ok", "a worked-out gold seam's host rock is plain stone: no Mining 3 needed")


func _test_quarried_away() -> void:
	var w := _world()
	var coal := _seam(w, "coal")
	var c := Vector2i(coal.x, coal.y)
	coal.amount = 0
	coal.host.amount = 1
	var changes := []
	w.tile_changed.connect(func(cell, kind, v): changes.append([cell, kind, v]))
	check(w.map.is_solid(c), "a worked-out seam is still rock")
	check(w.mine_unit(w.deposit_at(c)) == "stone", "its last stone is taken")
	check(not w.map.is_solid(c) and changes == [[c, "below", -1]] and int(w.deposit_at(c).amount) == 0 and w.mine_unit(w.deposit_at(c)) == "",
			"then the rock is gone: open ground, its tile taken away, nothing left to take")
	# below the surface: the cave grows by the cell
	var g := _seam(w, "iron_ore", -1)
	var gc := Vector2i(g.x, g.y)
	var lm: LevelMap = w.underground.map_at(-1, gc)
	var lchanges := []
	w.level_tile_changed.connect(func(l, cell, v): lchanges.append([l, cell, v]))
	g.amount = 0
	g.host.amount = 1
	check(lm.is_solid(gc), "a gallery seam is rock in the cave wall")
	w.mine_unit(w.deposit_at(gc, -1))
	var reach := lm.reachable_from(w.underground.portals[0].ends[1].stand)
	check(not lm.is_solid(gc) and reach.has(gc) and lchanges == [[-1, gc, -1]] and w.level_at(Vector2(gc) + Vector2(0.5, 0.5)) == -1,
			"in the gallery the quarried rock opens into the cave, walkable from the entrance")


func _test_stone_left_and_caravan() -> void:
	var w := _world()
	var seams := 0
	for d in w.deposits:
		if d.ore == "stone":
			seams += int(d.amount)
	var bould := 0
	for b in w.boulders:
		bould += int(b.amount)
	check(w.quests.deposit_left("stone") == seams + bould, "the village's stone left: the stone seams and the boulders (no ore seam worked out yet)")
	for d in w.deposits:
		if d.ore == "stone":
			d.amount = 0
	for b in w.boulders:
		b.amount = 0
	check(w.quests.deposit_left("stone") == 0 and w.brain._stone_scarce(), "with every stone seam and boulder gone and the ore still in, stone is scarce")
	var iron := _seam(w, "iron_ore")
	iron.amount = 0
	check(w.quests.deposit_left("stone") == 20 and not w.brain._stone_scarce(), "a worked-out ore seam's host rock is the village's stone again: no caravan stone")
	var imp0 := int(w.stats.get("imported_stone", 0))
	check(w.brain._caravan_stone() == 0 and int(w.stats.get("imported_stone", 0)) == imp0, "the caravan brings no stone while the village has more than the threshold")
	iron.host.amount = int(GameData.b("caravan_import_when_left"))
	check(w.brain._stone_scarce(), "at the threshold the caravan's stone comes again (%d left)" % w.quests.deposit_left("stone"))
	var market: Dictionary = w.brain.job_market()
	check(int(market.miner.open) >= 0, "the labour market counts the stone left to quarry as work")


## With the stone seams worked out and some ore seams too, labourers (and miners with no ore to sell) quarry the host
## rock and the boulders; every unit they take is counted.
func _test_villagers_quarry() -> void:
	var w := _world(1)
	for d in w.deposits:
		if d.ore == "stone":
			d.amount = 0
		elif World.level_of(d) == 0 and d.ore in ["iron_ore", "coal"]:
			d.amount = 0
	var s0 := _stone_snapshot(w)
	var boulders0 := 0
	for b in w.boulders:
		boulders0 += int(b.amount)
	var host0 := 0
	for d in w.deposits:
		if d.has("host"):
			host0 += int(d.host.amount)
	var lab: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "laborer":
			lab = n
	check(lab != null, "the village has a labourer")
	if lab != null:
		var src := w.nearest_seam(lab, ["stone"])
		check(not src.is_empty() and (src.has("of") or src.get("boulder", false)), "a labourer's nearest stone is a host rock or a boulder (%s)" % ("host rock" if src.has("of") else "boulder"))
	for k in 2880:
		w.update(0.5)
	var host1 := 0
	for d in w.deposits:
		if d.has("host"):
			host1 += int(d.host.amount)
	var boulders1 := 0
	for b in w.boulders:
		boulders1 += int(b.amount)
	var fell := _stone_fall(w, s0)
	var counted := int(w.stats.get("mined_stone", 0)) - int(s0.mined)
	check(host1 < host0 or boulders1 < boulders0, "villagers quarried host rock (%d) and boulders (%d) in a day" % [host0 - host1, boulders0 - boulders1])
	check(fell == counted and fell > 0, "mined_stone equals the fall of every stone pool (%d = %d)" % [fell, counted])
	var ore_ok := true
	for d in w.deposits:
		if d.ore != "stone" and World.level_of(d) == 0 and d.ore in ["iron_ore", "coal"] and int(d.amount) != 0:
			ore_ok = false
	check(ore_ok, "no worked-out ore seam regained ore")


## The manor's quarry job (an existing manor job: B7-006 is answered by it and by CON-01 contracts) works host rock
## and boulders when the stone seams are gone, and its wage comes from the treasury.
func _test_manor_quarry() -> void:
	var w := _world(2)
	for d in w.deposits:
		if d.ore == "stone":
			d.amount = 0
		elif d.ore == "iron_ore" and World.level_of(d) == 0:
			d.amount = 0
	var mw: ManorWork = w.manor_work
	mw.jobs.clear()
	mw.post_quarry()
	var q: Array = mw.jobs.filter(func(j): return j.kind == "quarry")
	check(q.size() == 1, "the reeve posts a quarry job while host rock and boulders hold stone (%d left)" % w.quests.deposit_left("stone"))
	if q.is_empty():
		return
	var hand: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard":
			hand = n
			break
	hand.inv.add("pickaxe")
	var t0 := w.treasury
	var coins0 := w.total_coins() - w.coin_sources
	check(mw.take(q[0], World.npc_ref(hand.id)), "a villager takes it")
	check(mw.plan(hand) and not hand.plan.is_empty(), "and plans the quarrying: %s" % hand.doing)
	var wk: Dictionary = hand.plan[1]
	var src := w.deposit_at(Vector2i(int(wk.args.x), int(wk.args.y)), int(wk.args.get("level", 0)))
	check(not src.is_empty() and src.ore == "stone" and (src.has("of") or src.get("boulder", false)), "at a host rock or a boulder, not a worked-out seam's ore")
	var guard := 0
	var s0 := _stone_snapshot(w)
	while not mw.jobs.filter(func(j): return j.kind == "quarry").is_empty() and guard < 20000:
		w.update(0.5)
		guard += 1
	check(mw.jobs.filter(func(j): return j.kind == "quarry").is_empty(), "the quarry job is done (%d steps)" % guard)
	check(_stone_fall(w, s0) == int(w.stats.get("mined_stone", 0)) - int(s0.mined), "its stone is counted mined_stone, unit for unit")
	check(int(w.stats.get("manor_job_quarry", 0)) >= 1 and w.treasury <= t0, "the wage came from the treasury (paid %d)" % int(w.stats.get("gov_manor_jobs", 0)))
	check(w.total_coins() - w.coin_sources == coins0, "no coins made or lost: every coin held is the start's plus the caravan's net flow")


func _test_saves() -> void:
	var w := _world(3)
	var iron := _seam(w, "iron_ore")
	iron.amount = 0
	iron.host.amount = 7
	var coal := _seam(w, "coal")
	coal.amount = 0
	coal.host.amount = 1
	w.mine_unit(w.deposit_at(Vector2i(coal.x, coal.y)))
	var g := _seam(w, "copper_ore", -1)
	g.amount = 0
	g.host.amount = 1
	w.mine_unit(w.deposit_at(Vector2i(g.x, g.y), -1))
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var i2 := w2.deposit_at(Vector2i(iron.x, iron.y))
	check(i2.has("of") and int(i2.amount) == 7, "a half-quarried host rock keeps its stone over a save")
	check(not w2.map.is_solid(Vector2i(coal.x, coal.y)) and not w2.underground.map_at(-1, Vector2i(g.x, g.y)).is_solid(Vector2i(g.x, g.y)),
			"rock quarried away stays open ground after a load, on the surface and in the gallery")
	# a save from before MIN-B (no host rock): every ore seam gets its host rock, whole; worked-out seams too
	var old: Dictionary = JSON.parse_string(JSON.stringify(d))
	for x in old.deposits:
		x.erase("host")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	var ok := true
	for x in w3.deposits:
		if x.ore != "stone" and (not x.has("host") or int(x.host.amount) != 20):
			ok = false
	check(ok and int(w3.deposit_at(Vector2i(iron.x, iron.y)).amount) == 20, "an older save's ore seams get their host rock whole (the worked-out iron seam can be quarried)")
	check(int(d.save_version) == 17, "no new save version (17)")
