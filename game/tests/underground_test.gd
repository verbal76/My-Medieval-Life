extends SceneTree
## MIN-A underground foundation (docs/build17/MIN_A_ARCHITECTURE.md, owner OD-29): the adit gallery is the same for a
## seed and reachable from its entrance, lies only under the hill's rock, the adit's portals round-trip, a seam below
## is mined by the surface's own rules and ledger, saves keep the player's level and the seams by (level, x, y), an
## older save loads on the surface with the gallery full, and the surface's map, seams and villagers' sums are not
## changed by the gallery. The second half drives the real game scene: walking into the adit fades the surface out and
## the gallery in, and back. Run headless:
##   godot --headless --path game --script res://tests/underground_test.gd

var failures := 0
var checks := 0
var main
const TEST_SAVE := "user://test_saves/underground_test/save1.json"


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	_test_generation()
	_test_portals_and_collision()
	_test_mining_below()
	_test_save_load()
	_test_surface_unchanged()
	_test_villagers_below()
	_test_across_levels()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = TEST_SAVE
	process_frame.connect(_run_scene, CONNECT_ONE_SHOT)


func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _static_rock(m: VillageMap, c: Vector2i) -> bool:
	return m.in_village(c) and str(m.data.solid[c.y])[c.x] == "1"


# ---------------------------------------------------------------- generation -----------------
func _test_generation() -> void:
	var m := VillageMap.load_default()
	var a := Underground.create(1, m).fingerprint()
	check(a == Underground.create(1, m).fingerprint() and a == Underground.create(1, VillageMap.load_default()).fingerprint(),
			"the gallery is identical for a seed (map, region and seams)")
	var differ := false
	for s in [2, 3, 7]:
		if Underground.create(s, m).fingerprint() != a:
			differ = true
	check(differ, "other seeds give other galleries")
	for s in [1, 2, 3, 7, 12345]:
		var u := Underground.create(s, m)
		var lm: LevelMap = u.maps[0]
		var door := Vector2i(int(m.data.mine.entrance[0]), int(m.data.mine.entrance[1]) - 1)
		var floors := lm.floor_cells()
		var bad_reach := 0
		var bad_rock := 0
		for c in floors:
			var p := lm.find_path(door, c)
			if p.is_empty() or Vector2i(p[p.size() - 1]) != c:
				bad_reach += 1
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if not _static_rock(m, c + Vector2i(dx, dy)) and c != door:
						bad_rock += 1
		check(lm.id == "adit_gallery" and lm.level == -1 and floors.size() >= 30 and not lm.is_solid(door),
				"seed %d: a gallery of %d floor cells on level -1, open at the adit (%s)" % [s, floors.size(), str(door)])
		check(bad_reach == 0 and lm.reachable_from(door).size() == floors.size(), "seed %d: every floor cell is reachable from the entrance by the level's own A*" % s)
		check(bad_rock == 0, "seed %d: the floor lies only under the hill's rock, a cell deep all round (except the entrance)" % s)
		check(lm.is_solid(door + Vector2i(0, 1)) and lm.is_solid(lm.region.position - Vector2i.ONE) and lm.is_solid(Vector2i(48, 40)),
				"seed %d: the daylight mouth and everything off the map is rock below" % s)
		var walls := {}
		for c in lm.wall_cells():
			walls[c] = true
		var seam_ok := u.seams.size() == 6
		var kinds := {}
		for sd in u.seams:
			var c := Vector2i(int(sd.x), int(sd.y))
			kinds[str(sd.ore)] = int(kinds.get(str(sd.ore), 0)) + 1
			if not walls.has(c) or not _static_rock(m, c) or int(sd.level) != -1 or int(sd.amount) <= 0:
				seam_ok = false
		check(seam_ok and kinds == {"iron_ore": 2, "coal": 2, "copper_ore": 1, "stone": 1}, "seed %d: six seams on the cave walls under the rock, as the data names them" % s)
	var amounts := {}
	for d in m.data.deposits:
		amounts[str(d.ore)] = int(d.amount)
	var same := true
	for sd in Underground.create(1, m).seams:
		if int(sd.amount) != int(amounts[str(sd.ore)]):
			same = false
	check(same, "each seam below holds the village's own amount for its ore (no new quantity rule)")


# ---------------------------------------------------------------- portals --------------------
func _test_portals_and_collision() -> void:
	var w := _world()
	var p := w.player
	var stand := Vector2i(int(w.map.data.mine.entrance[0]), int(w.map.data.mine.entrance[1]))
	var door := stand + Vector2i.UP
	check(w.underground.portals.size() == 1 and w.underground.portals[0].id == "adit", "one portal: the adit")
	p.pos = Vector2(stand) + Vector2(0.5, 0.5)
	check(w.player_through(Vector2.LEFT).is_empty() and w.player_level == 0, "walking along the rock face does not go in")
	var seen := []
	w.player_level_changed.connect(func(l): seen.append(l))
	var r := w.player_through(Vector2(0.2, -1.0))
	check(r.get("level", 0) == -1 and w.player_level == -1 and p.pos == Vector2(door) + Vector2(0.5, 0.5) and seen == [-1],
			"walking into the adit puts the player on level -1 under it (%s)" % str(p.pos))
	check(w.player_through(Vector2.UP).is_empty() and w.player_level == -1, "walking on into the hill does not bounce back out")
	r = w.player_through(Vector2.DOWN)
	check(r.get("level", -9) == 0 and w.player_level == 0 and p.pos == Vector2(stand) + Vector2(0.5, 0.5) and seen == [-1, 0],
			"walking out of the gallery puts the player back in front of the adit")
	p.pos = Vector2(stand) + Vector2(2.5, 0.5)
	check(w.player_through(Vector2.UP).is_empty(), "only the stand in front of the adit leads in")
	# surface collision is the surface's own; below, the level's
	var same := true
	for y in range(0, 30):
		for x in range(30, 70):
			if w.solid_for_player(Vector2i(x, y)) != w.map.is_solid_world(Vector2i(x, y)):
				same = false
	check(same, "on the surface the player's collision is the surface's own, cell for cell")
	p.pos = Vector2(stand) + Vector2(0.5, 0.5)
	w.player_through(Vector2.UP)
	var lm: LevelMap = w.underground.maps[0]
	var agree := true
	for c in lm.cells():
		if w.solid_for_player(c) != lm.is_solid(c):
			agree = false
	check(agree and w.solid_for_player(stand) and w.solid_for_player(Vector2i(48, 30)), "below, the level's map is the collision: the yard and the village are rock")
	var far: Vector2i = lm.floor_cells()[0]
	var path := w.path_for_player(door, far)
	check(not path.is_empty() and path.size() >= 2 and Array(path).all(func(q): return not lm.is_solid(Vector2i(q))),
			"a tap-walk route below stays on the level's floor (%d steps)" % path.size())
	# a cart is not taken through
	w.player_through(Vector2.DOWN)
	var cart := w.carts.place(World.PLAYER, p.pos)
	w.carts.hitch(cart, World.PLAYER)
	r = w.player_through(Vector2.UP)
	check(r.has("refused") and w.player_level == 0, "a pulled cart does not go through the adit: %s" % str(r.get("refused", "")))
	w.carts.park(cart)
	check(w.player_through(Vector2.UP).get("level", 0) == -1, "the cart set down, the player goes in")


# ---------------------------------------------------------------- mining ---------------------
func _test_mining_below() -> void:
	var w := _world()
	var p := w.player
	var below := w.deposits.filter(func(d): return World.level_of(d) == -1)
	check(below.size() == 6 and w.deposits.size() == w.map.data.deposits.size() + 6, "the gallery's seams are ordinary records in World.deposits")
	var seam: Dictionary = below.filter(func(d): return d.ore == "iron_ore")[0]
	var c := Vector2i(int(seam.x), int(seam.y))
	check(w.deposit_at(c, -1) == seam and w.deposit_at(c).is_empty(), "a seam below is found on its level only, not on the surface above it")
	check(w.nearest_deposit(c, ["iron_ore"]).get("level", 0) == 0 and w.nearest_deposit(c, ["iron_ore"], -1) == seam,
			"the nearest seam is looked for on one level (the surface unless named)")
	check(w.villagers_reach(seam) and w.villagers_reach(w.deposits[0]) and w.villager_levels == [0, -1], "villagers reach the gallery's seams and the surface's")
	var node := ResourceNodes.def_for_deposit(seam)
	check(not node.is_empty() and str(node.id) == "iron_seam", "a seam below is the same resource node as on the surface (iron_seam)")
	p.inv.add("pickaxe")
	var left := int(seam.amount)
	var got0 := p.inv.count("iron_ore")
	var stat0 := int(w.stats.get("mined_iron_ore", 0))
	var xp0 := int(p.skills.get("mining", 0))
	var r := w.work_mine(p, seam, p.inv, "pickaxe")
	var fell := left - int(seam.amount)
	check(r.result == "ok" and fell == int(r.n) and fell >= 1, "one swing below takes a unit (or two by the skill's chance) from the seam (%d)" % fell)
	check(p.inv.count("iron_ore") - got0 == fell and int(w.stats.get("mined_iron_ore", 0)) - stat0 == fell, "the ore goes to the pack and is counted mined_iron_ore, unit for unit")
	check(int(p.skills.get("mining", 0)) - xp0 == 8 * fell, "the same Mining xp as on the surface (8 an ore)")
	var gold := {"x": c.x, "y": c.y, "ore": "gold_ore", "amount": 3, "level": -1}
	check(w.work_mine(p, gold, p.inv, "pickaxe").result == "gold" or Skills.has(p, "mining", "gold"), "the gold gate holds below as above")
	# worked out: the hollow tile on the level, never on the surface's layer
	var surface_changes := []
	var level_changes := []
	w.tile_changed.connect(func(cell, kind, v): surface_changes.append([cell, kind, v]))
	w.level_tile_changed.connect(func(l, cell, v): level_changes.append([l, cell, v]))
	seam.amount = 1
	w.mine_unit(seam)
	check(int(seam.amount) == 0 and w.mine_unit(seam) == "" and surface_changes.is_empty() and level_changes == [[-1, c, int(w.map.data.tiles.depleted_rock)]],
			"a worked-out seam below shows the hollow on its level, is never refilled, and leaves the surface's tiles alone")
	# loot dropped below lies below
	w.player.pos = Vector2(48.5, 10.5)
	w.player_through(Vector2.UP)
	var n0 := w.loot.size()
	p.inv.add("coal", 3)
	check(w.player_drop("coal", 2) and w.loot.size() == n0 + 1 and World.level_of(w.loot[n0]) == -1, "what the player sets down below lies on the level")
	p.inv.max_stacks = p.inv.items.size()
	w.player_gain("charcoal" if GameData.items.has("charcoal") else "plank", 1, "made_")
	check(w.loot.size() == n0 + 2 and World.level_of(w.loot[n0 + 1]) == -1, "what the pack cannot hold below is set down on the level")


# ---------------------------------------------------------------- saves ----------------------
func _test_save_load() -> void:
	var w := _world(3)
	var p := w.player
	p.pos = Vector2(48.5, 10.5)
	w.player_through(Vector2.UP)
	var lm: LevelMap = w.underground.maps[0]
	var spot: Vector2i = lm.floor_cells()[lm.floor_cells().size() / 2]
	p.pos = Vector2(spot) + Vector2(0.37, 0.61)
	var below := w.deposits.filter(func(d): return World.level_of(d) == -1)
	below[0].amount = 17
	below[1].amount = 0
	var bag := Inventory.new()
	bag.add("coal", 2)
	w.loot.append({"pos": p.pos, "inv": bag, "coins": 0, "from": "dropped by test", "level": -1})
	var d := w.to_dict()
	check(int(d.save_version) == World.SAVE_VERSION and World.SAVE_VERSION == 17 and d.underground.player_level == -1, "the save is version 17 and holds the player's level")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w2.player_level == -1 and w2.player.pos.is_equal_approx(p.pos), "a save made below loads below, at the same place")
	var b2 := w2.deposits.filter(func(x): return World.level_of(x) == -1)
	check(b2.size() == 6 and int(w2.deposit_at(Vector2i(below[0].x, below[0].y), -1).amount) == 17 and int(w2.deposit_at(Vector2i(below[1].x, below[1].y), -1).amount) == 0
			and w2.deposits.size() == w.deposits.size(), "the seams below keep their amounts, matched by level and cell")
	check(w2.loot.any(func(l): return World.level_of(l) == -1 and l.inv.count("coal") == 2), "a pile left below stays below")
	var key := func(x) -> String: return "%d,%d,%d,%s,%d" % [int(x.get("level", 0)), int(x.x), int(x.y), str(x.ore), int(x.amount)]
	check(w2.to_dict().deposits.map(key) == w.deposits.map(key), "saved again, the seams are unchanged, in order")
	# a Build 16 save: no "underground", no seams below; the player loads on the surface and the gallery is full
	var old: Dictionary = JSON.parse_string(JSON.stringify(d))
	old.erase("underground")
	old.save_version = 16
	old.deposits = old.deposits.filter(func(x): return int(x.get("level", 0)) == 0)
	old.player.pos = [30.5, 40.5]
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	var b3 := w3.deposits.filter(func(x): return World.level_of(x) == -1)
	check(w3.player_level == 0 and b3.size() == 6 and b3.all(func(x): return int(x.amount) > 0), "a version 16 save loads with the player on the surface and the gallery's seams full")
	# a surface seam and a seam below at the same cell stay two seams
	var w4 := _world(3)
	var sd: Dictionary = w4.deposits[0]
	var twin := {"x": int(sd.x), "y": int(sd.y), "ore": "coal", "amount": 5, "level": -1}
	w4.deposits.append(twin)
	var d4: Dictionary = JSON.parse_string(JSON.stringify(w4.to_dict()))
	var w5 := World.new()
	w5.load_dict(VillageMap.load_default(), d4)
	check(int(w5.deposit_at(Vector2i(sd.x, sd.y)).amount) == int(sd.amount) and int(w5.deposit_at(Vector2i(sd.x, sd.y), -1).amount) == 5,
			"the load keys seams by (level, x, y): one above and one below the same cell are both kept")


# ---------------------------------------------------------------- surface --------------------
func _test_surface_unchanged() -> void:
	var w := _world(5)
	var m := VillageMap.load_default()
	var surface := w.deposits.filter(func(d): return World.level_of(d) == 0)
	var orig: Array = m.data.deposits
	var same := surface.size() == orig.size()
	for i in mini(surface.size(), orig.size()):
		if int(surface[i].x) != int(orig[i].x) or int(surface[i].y) != int(orig[i].y) or str(surface[i].ore) != str(orig[i].ore) or surface[i].has("level"):
			same = false
	check(same, "the village's own seams are unchanged and come first, with no level field")
	# villagers reach the gallery now: its ore counts in the labour market and the village's ore left
	var v := _world(5)
	v.deposits = v.deposits.filter(func(d): return World.level_of(d) == 0)
	var below_stone := 0
	for d in w.deposits:
		if World.level_of(d) == -1 and d.ore == "stone":
			below_stone += int(d.amount)
	check(w.quests.deposit_left("stone") == v.quests.deposit_left("stone") + below_stone and w.brain.job_market().miner.open >= v.brain.job_market().miner.open,
			"the gallery's ore counts as the village's own (deposit_left, the labour market's miner places)")
	var w2 := _world(5)
	for k in 480:
		w.update(0.5)
		w2.update(0.5)
	check(_surface_print(w) == _surface_print(w2) and JSON.stringify(w.deposits) == JSON.stringify(w2.deposits),
			"two worlds of one seed run identically with villagers free to go below (%d game minutes)" % int(w.minutes - 420.0))
	var st := w.rng.state
	Underground.create(w.seed, w.map)
	check(w.rng.state == st, "making the gallery draws nothing from the world's random stream")


# ---------------------------------------------------------------- villagers below -------------
## Every seam on the surface worked out but the gallery's: a miner walks in through the adit, mines a gallery seam by
## the same swing, carries the ore out and sells it; saved and loaded while below, the trip goes on; every unit taken
## is counted; and every villager's level agrees with where they stand all the while.
func _test_villagers_below() -> void:
	var w := _world(1)
	for d in w.deposits:
		if World.level_of(d) == 0:
			d.amount = 0
	var start := {}
	for d in w.deposits:
		start["%d,%d,%d" % [World.level_of(d), int(d.x), int(d.y)]] = int(d.amount)
	var miner: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "miner":
			miner = n
			break
	check(miner != null, "the village has a miner")
	if miner == null:
		return
	var mined0 := {}
	for o in ["iron_ore", "coal", "copper_ore", "stone"]:
		mined0[o] = int(w.stats.get("mined_" + o, 0))
	var went_below := false
	var mined_below := false
	var came_up_with_ore := false
	var sold := false
	var saved := {}
	var bad_level := 0
	var ore_of := func(n: NPC) -> int: return n.inv.count("iron_ore") + n.inv.count("coal") + n.inv.count("copper_ore") + n.inv.count("stone")
	var last_ore: int = ore_of.call(miner)
	var last_coins := miner.coins
	for k in 6000:
		w.update(0.5)
		for n: NPC in w.npcs:
			if n.alive and n.depth != w.level_at(n.pos):
				bad_level += 1
			if n.alive and n.depth != 0 and w.underground.is_solid(n.depth, n.cell()):
				bad_level += 1
		var ore: int = ore_of.call(miner)
		if miner.depth == -1:
			went_below = true
			if saved.is_empty():
				saved = JSON.parse_string(JSON.stringify(w.to_dict()))
			if ore > last_ore:
				mined_below = true
		elif mined_below and ore > 0:
			came_up_with_ore = true
		if came_up_with_ore and miner.depth == 0 and ore < last_ore and miner.coins > last_coins:
			sold = true
		last_ore = ore
		last_coins = miner.coins
		if sold:
			break
	check(went_below, "a miner walks through the adit into the gallery when the surface's seams are worked out")
	check(mined_below, "they mine a gallery seam there")
	check(came_up_with_ore, "they carry the ore back out through the adit")
	check(sold, "and sell it (%s)" % miner.doing)
	check(bad_level == 0, "every villager's level agrees with the ground they stand on, all the way (%d disagreements)" % bad_level)
	check(int(w.stats.get("portal_crossings", 0)) >= 2, "the crossings are counted (%d)" % int(w.stats.get("portal_crossings", 0)))
	# conservation: every unit that left a seam is counted mined, seam by seam on both levels
	var fell := {}
	var fell_below := 0
	for d in w.deposits:
		var k := "%d,%d,%d" % [World.level_of(d), int(d.x), int(d.y)]
		var f: int = int(start.get(k, int(d.amount))) - int(d.amount)
		if f < 0:
			check(false, "seam %s never refills" % k)
		fell[d.ore] = int(fell.get(d.ore, 0)) + f
		if World.level_of(d) == -1:
			fell_below += f
	var ledger_ok := true
	for o in mined0:
		if int(fell.get(o, 0)) != int(w.stats.get("mined_" + o, 0)) - int(mined0[o]):
			ledger_ok = false
			print("  ", o, ": seams fell ", fell.get(o, 0), ", mined ", int(w.stats.get("mined_" + o, 0)) - int(mined0[o]))
	check(ledger_ok and fell_below > 0, "every unit taken below is counted mined_<ore>, unit for unit (%d from the gallery)" % fell_below)
	# saved while the miner was below: the load keeps them below, and the trip goes on from there
	check(not saved.is_empty(), "a save was made with the miner below")
	if saved.is_empty():
		return
	var mid: Dictionary = (saved.npcs as Array).filter(func(x): return int(x.id) == miner.id)[0]
	check(int(mid.get("level", 0)) == -1, "the save holds the miner's level")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), saved)
	var m3: NPC = w3.npc(miner.id)
	check(m3.depth == -1 and m3.pos.is_equal_approx(Vector2(float(mid.pos[0]), float(mid.pos[1]))), "loaded, the miner is below, where they were")
	var up := false
	for k in 4000:
		w3.update(0.5)
		if m3.depth == 0:
			up = true
			break
	check(up and m3.alive, "after the load the miner finds the way out again (%s)" % m3.doing)
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w3.to_dict())))
	check(JSON.stringify(w4.to_dict().npcs) == JSON.stringify(w3.to_dict().npcs), "saved again, the villagers and their levels are unchanged")


## Nothing acts across levels: awareness, reach, fights, animals' aggression, bandits' prey, chat and loot.
func _test_across_levels() -> void:
	var w := _world(2)
	var lm: LevelMap = w.underground.maps[0]
	var below_cell: Vector2i = lm.floor_cells()[0]
	var a: NPC = null
	var b: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard":
			if a == null:
				a = n
			elif b == null:
				b = n
	a.depth = -1
	a.pos = Vector2(below_cell) + Vector2(0.5, 0.5)
	a.plan.clear()
	# b stands on the surface at the hill's foot, the nearest a surface walker can come
	var foot := Vector2i(48, 10)
	b.pos = Vector2(foot) + Vector2(0.5, 0.5)
	var at_mouth := Vector2(48.5, 9.5)            # the gallery's inner stand, one cell from b
	a.pos = at_mouth
	check(w.level_at(a.pos) == -1 and w.level_at(b.pos) == 0, "the gallery's mouth is below, the stand before it above")
	check(not w.near(b.pos, 10.0).has(a) and not w.present(b.pos, 10.0).has(a) and not w.near(a.pos, 10.0).has(b) and not w.present(a.pos, 10.0).has(b),
			"neither sees nor reaches the other through the rock (near, present)")
	check(not w.reaches(b.pos, a.pos) and not w.reaches(a.pos, b.pos), "no reach across levels")
	a.target = b.id
	w.brain.fight(a, 0.1)
	check(a.target == -1, "a fight across levels ends at once")
	b.target = -2
	w.player.pos = Vector2(below_cell) + Vector2(0.5, 0.5)
	w.player_level = -1
	w.brain.fight(b, 0.1)
	check(b.target == -1, "nobody on the surface fights the player below")
	check(w.fauna._foe_pos("player") == Vector2.INF and w.fauna._foe_pos("npc:%d" % a.id) == Vector2.INF and w.fauna._foe_pos("npc:%d" % b.id) != Vector2.INF,
			"animals (on the surface) cannot go for anyone below")
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			bandit = n
			break
	if bandit != null:
		bandit.pos = b.pos + Vector2(1, 0)
		check(w.brain._prey_for(bandit) != w.player, "a bandit does not prey on the player below")
	# loot left below is not the guards'
	var bag := Inventory.new()
	bag.add("coal", 1)
	w.loot.append({"pos": at_mouth, "inv": bag, "coins": 9, "from": "dropped by test", "level": -1, "t": -1.0e6})
	var guard: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard":
			guard = n
			break
	if guard != null:
		guard.pos = b.pos
		check(w.brain._loot_to_recover(guard).is_empty(), "a guard does not recover coins lying below")
	# a villager below is drawn in the gallery only: World tells their level, the surface's rules leave them alone
	w.player_level = 0
	w.player.pos = b.pos
	check(not w.near(w.player.pos, float(GameData.b("witness_radius"))).has(a), "no witness below sees what the player does above")


func _surface_print(w: World) -> String:
	var d := w.to_dict()
	d.deposits = (d.deposits as Array).filter(func(x): return int(x.get("level", 0)) == 0)
	d.erase("log")
	return JSON.stringify(d)


# ---------------------------------------------------------------- the scene ------------------
func _run_scene() -> void:
	main.new_game()
	var w: World = main.world
	check(main.level_views.size() == 1 and not main.level_views.values()[0].visible and main.view.modulate.a == 1.0, "the gallery's view is built and hidden on the surface")
	var lv: LevelView = main.level_views.values()[0]
	var tiles: Dictionary = GameData.resources.deposit_tiles.ore
	var wrong := 0
	for d in w.deposits.filter(func(x): return World.level_of(x) == -1):
		if lv.tile_value(lv.seam_layer, Vector2i(d.x, d.y)) != int(tiles[d.ore]):
			wrong += 1
	check(wrong == 0, "every seam below is drawn with its own ore's sprite, as on the surface")
	var floor_drawn := true
	for c in lv.level_map.floor_cells():
		if lv.tile_value(lv.floor_layer, c) < 0 or lv.tile_value(lv.wall_layer, c) >= 0:
			floor_drawn = false
	check(floor_drawn, "the floor is drawn and no wall stands on it")
	var p: PlayerState = w.player
	p.pos = Vector2(48.5, 10.6)
	main._through_portal(Vector2.UP)
	check(w.player_level == -1, "Main: pushing into the adit goes in")
	for k in 3:
		main._process(0.05)
	check(main.level_alpha > 0.0 and main.level_alpha < 1.0 and lv.visible and main.view.modulate.a < 1.0 and main.view.modulate.a > 0.0, "the surface fades out while the gallery fades in (%.2f)" % main.level_alpha)
	for k in 10:
		main._process(0.05)
	var npc_faded: bool = main.sprites.values().all(func(s): return s.modulate.a == 0.0)
	check(main.level_alpha == 1.0 and main.view.modulate.a == 0.0 and main.above.modulate.a == 0.0 and npc_faded and main.player_sprite.modulate.a == 1.0,
			"below: the surface and everyone on it are hidden; the player is not")
	# the target below is the seam in front, mined by the surface's own action
	var seam: Dictionary = w.deposits.filter(func(x): return World.level_of(x) == -1 and int(x.amount) > 0)[0]
	var lm: LevelMap = lv.level_map
	var stand := Vector2i(-1, -1)
	for dv: Vector2i in VillageMap.SIDES:
		if not lm.is_solid(Vector2i(seam.x, seam.y) + dv):
			stand = Vector2i(seam.x, seam.y) + dv
	p.pos = Vector2(stand) + Vector2(0.5, 0.5)
	main.player_sprite.face(Vector2(Vector2i(seam.x, seam.y) - stand))
	p.inv.add("pickaxe")
	main._find_target()
	check(str(main.target.get("kind", "")) == "deposit" and main.target.dep == seam, "below, the seam in front is the target (%s)" % str(main.target.get("label", "")))
	var hit := ResourceNodes.node_at(w, Vector2i(seam.x, seam.y), true)
	var gs: Vector2 = main._gather_stand(hit.get("def", {}), seam) if not hit.is_empty() else Vector2.INF
	check(not hit.is_empty() and hit.ref == seam and not lm.is_solid(Vector2i(gs.floor())), "Gather mode below finds the level's seam and a stand on the level's floor beside it")
	var before := int(seam.amount)
	main.interact()
	var guard := 0
	while not main.action.is_empty() and guard < 4000:
		main._player_step(0.05)
		guard += 1
	check(int(seam.amount) < before, "Use mines it by the same action as on the surface (%d -> %d)" % [before, int(seam.amount)])
	check(main.attack() == "ignored", "nothing to fight below")
	# out again
	p.pos = Vector2(48.5, 9.4)
	main._through_portal(Vector2.DOWN)
	for k in 12:
		main._process(0.05)
	check(w.player_level == 0 and main.level_alpha == 0.0 and not lv.visible and main.view.modulate.a == 1.0 and main.sprites.values().all(func(s): return s.modulate.a == 1.0),
			"out of the adit: the surface and its people are back, the gallery hidden")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
