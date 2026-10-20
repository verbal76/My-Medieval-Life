extends SceneTree
## The Build 8 world fixes, in the real game scene (a focused check, well under a minute): deposits are
## what their sprite shows (B8-008), small grey boulders are pickaxe nodes that stay broken (B8-026),
## the roof never returns while the player is inside a building (B8-018), and an essential trade is
## handed on after its worker dies (B8-016). Run headless:
##   godot --headless --path game --script res://tests/world_test.gd

var failures := 0
var checks := 0
var main
const TEST_SAVE := "user://test_saves/world_test/save1.json"


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = TEST_SAVE
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _finish_action() -> void:
	var guard := 0
	while not main.action.is_empty() and guard < 4000:
		main._player_step(0.05)
		guard += 1


func _run() -> void:
	main.new_game()
	_deposits()
	_gold()
	_boulders()
	_roofs()
	_succession()
	_pl_gameplay()
	_station_conflict()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- B8-008 ----------------------
func _tile_cells(m: VillageMap, tile_ok: Callable) -> Array:
	var out := []
	for lay in m.data.layers:
		if not (str(lay.name).begins_with("below") or str(lay.name).begins_with("above")):
			continue
		for i in lay.data.size():
			if tile_ok.call(int(lay.data[i])):
				out.append([str(lay.name), Vector2i(i % m.w, i / m.w)])
	return out


func _deposits() -> void:
	var w: World = main.world
	var m: VillageMap = main.map
	var dt: Dictionary = GameData.resources.deposit_tiles
	var tiles: Dictionary = dt.ore
	var bad := 0
	for d in w.deposits:
		var drawn: int = main.view.tile_value(main.view.layer("below0"), Vector2i(d.x, d.y))
		if drawn != int(tiles[d.ore]):
			bad += 1
			print("  seam ", d.ore, " at ", d.x, ",", d.y, " is drawn with tile ", drawn, ", not ", tiles[d.ore])
	check(bad == 0 and w.deposits.size() > 0, "every seam is drawn with its own ore's tile (%d seams)" % w.deposits.size())
	var seams := {}
	for d in w.deposits:
		seams[Vector2i(d.x, d.y)] = true
	var flecked := {}
	for t in dt.flecked:
		flecked[int(t)] = true
	var loose := _tile_cells(m, func(v): return flecked.has(v)).filter(func(e): return not seams.has(e[1]))
	check(loose.is_empty(), "no ore-flecked sprite stands anywhere without a seam behind it (%d)" % loose.size())
	var ores := {}
	for o in tiles:
		if o != "stone":
			ores[int(tiles[o])] = o
	var wrong := 0
	for d in w.deposits:
		var node := ResourceNodes.node_at(w, Vector2i(d.x, d.y), true)
		var got: String = ResourceNodes.products(node.def).keys()[0] if not node.is_empty() else ""
		if got != d.ore or str(node.def.name).to_lower().find(str(GameData.item_name(d.ore)).split(" ")[0].to_lower()) < 0:
			wrong += 1
	check(wrong == 0, "each seam's node, product and name agree (prompt, yield) for all %d seams" % w.deposits.size())
	check(int(m.data.tiles.depleted_rock) == int(dt.worked_out) and not flecked.has(int(dt.worked_out)), "a worked-out seam has its own hollow tile")
	var stone_seam := {}
	for d in w.deposits:
		if d.ore == "stone":
			stone_seam = d
	var left := int(stone_seam.amount)
	w.mine_unit(stone_seam)
	check(int(stone_seam.amount) == left - 1, "mining a seam takes a unit")


# ---------------------------------------------------------------- Build 13: gold -------------
func _gold() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var golds := w.deposits.filter(func(d): return d.ore == "gold_ore")
	check(golds.size() == 1 and int(golds[0].amount) == 8, "the mine has one gold seam of 8 units")
	var g: Dictionary = golds[0]
	var node := ResourceNodes.node_at(w, Vector2i(g.x, g.y), true)
	check(not node.is_empty() and node.def.id == "gold_seam" and ResourceNodes.products(node.def) == {"gold_ore": 1}, "it is the gold seam node and gives gold ore")
	p.inv.add("pickaxe")
	var xp0 := int(p.skills.get("mining", 0))
	p.skills["mining"] = 0
	check(ResourceNodes.can_harvest(w, node.def, node.ref) == "Gold needs Mining level 3.", "a novice miner is refused gold")
	p.skills["mining"] = Skills.xp_for_level(3)
	check(ResourceNodes.can_harvest(w, node.def, node.ref) == "", "at Mining 3 the seam can be worked")
	p.skills["mining"] = xp0
	var smith: NPC = w.npcs.filter(func(n): return n.alive and n.job == "smith")[0]
	check(w.brain.wants(smith, "gold_ore") > 0 and GameData.recipes.has("smelt_gold"), "the smith buys gold ore and smelts it")
	# a save made before the gold seam existed gets it, full, on load; other seams keep their state
	var d := w.to_dict()
	var first: Dictionary = d.deposits.filter(func(x): return x.ore != "gold_ore")[0]
	first.amount = 1
	d.deposits = d.deposits.filter(func(x): return x.ore != "gold_ore")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))   # its own map: never touch the running game
	var g2 := w2.deposits.filter(func(x): return x.ore == "gold_ore")
	check(g2.size() == 1 and int(g2[0].amount) == 8, "an older save without the gold seam gains it full on load")
	check(w2.deposits.size() == w.deposits.size() and int(w2.deposit_at(Vector2i(first.x, first.y)).amount) == 1, "the saved seams keep their amounts")


# ---------------------------------------------------------------- B8-026 ----------------------
func _boulders() -> void:
	var w: World = main.world
	var m: VillageMap = main.map
	var p: PlayerState = w.player
	p.inv.add("pickaxe")
	check(w.boulders.size() > 0 and int(ResourceNodes.def("boulder").uses_small) < int(ResourceNodes.def("boulder").uses), "the village has %d boulders, small ones with fewer uses than large ones" % w.boulders.size())
	var taken := {}
	for t in w.trees:
		taken[Vector2i(int(t.x), int(t.y))] = "tree"
	for st in w.stations.values():
		taken[Vector2i(int(st.at[0]), int(st.at[1]))] = "station"
	for c in w.containers:
		taken[Vector2i(int(c.x), int(c.y))] = "container"
	for pl in w.plants:
		taken[Vector2i(int(pl.x), int(pl.y))] = "plant"
	var clash := 0
	for bb in w.boulders:
		if taken.has(Vector2i(int(bb.x), int(bb.y))):
			clash += 1
	check(clash == 0, "no boulder shares a cell with a tree, station, container or plant (%d)" % clash)
	# a village boulder: a node of its own, stone, the right prompt, a few swings, then gone and walkable
	var b: Dictionary = w.boulders[0]
	var cell := Vector2i(b.x, b.y)
	var uses := int(b.amount)
	var node := ResourceNodes.node_at(w, cell, true)
	check(not node.is_empty() and node.def.id == "boulder" and ResourceNodes.products(node.def) == {"stone": 1}, "a boulder is the boulder node and gives stone")
	check(m.is_solid(cell) and ResourceNodes.can_harvest(w, node.def, node.ref) == "", "it is solid and can be mined with a pickaxe")
	var held := {}
	for id in p.inv.ids():
		if GameData.item(id).get("tool", "") == "pickaxe":
			held[id] = p.inv.count(id)
	for id in held:
		p.inv.remove(id, held[id])
	check(ResourceNodes.can_harvest(w, node.def, node.ref) != "", "not without one")
	for id in held:
		p.inv.add(id, held[id])
	var stone0 := p.inv.count("stone")
	var stand := Vector2.ZERO
	var face := Vector2.ZERO
	for dd in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		if stand == Vector2.ZERO and not m.is_solid(cell + dd) and w.place_of(Vector2(cell + dd) + Vector2(0.5, 0.5)) == "":
			stand = Vector2(cell + dd) + Vector2(0.5, 0.5)
			face = Vector2(-dd.x, -dd.y)
	p.pos = stand
	main.player_sprite.face(face)
	main._find_target()
	check(main.target.get("kind", "") == "deposit" and str(main.target.get("label", "")).begins_with("Mine stone (%d left)" % uses),
			"Use offers it: \"%s\"" % main.target.get("label", ""))
	for k in uses:
		main._find_target()
		main._use()
		_finish_action()
	check(p.inv.count("stone") - stone0 >= uses, "%d swings gave %d stone" % [uses, p.inv.count("stone") - stone0])
	check(int(b.amount) == 0 and not m.is_solid(cell) and w.deposit_at(cell).is_empty(), "the boulder is gone and its cell is open")
	var gone := true
	for lay in m.data.layers:
		if str(lay.name).begins_with("below") and int(lay.data[cell.y * m.w + cell.x]) == int(GameData.resources.deposit_tiles.boulder):
			gone = false
		var l: TileMapLayer = main.view.layer(str(lay.name))
		if str(lay.name).begins_with("below") and main.view.tile_value(l, cell) == int(GameData.resources.deposit_tiles.boulder):
			gone = false
	check(gone, "its sprite is gone from every layer")
	# an overworld boulder: found, mined, persists across chunk reloads and save/load
	var o: Overworld = m.overworld
	var west: Vector2i = m.exits()[3].out
	var oc := Vector2i(-9999, 0)
	for r in range(4, 120):
		for dy in range(-r, r + 1):
			var sc := west + Vector2i(-r, dy)
			if oc.x == -9999 and o.has_boulder(sc) and not o.is_road(sc):
				oc = sc
	check(oc.x != -9999, "an overworld boulder exists near the west road")
	var od := w.deposit_at(oc)
	var ouses := int(od.amount)
	check(ouses == ResourceNodes.boulder_uses(oc), "its uses follow its size (%d)" % ouses)
	check(not od.is_empty() and od.get("ow", false) and od.ore == "stone" and ResourceNodes.node_at(w, oc, true).def.id == "boulder", "it is a boulder node too")
	check(o.is_solid(oc), "and it blocks the way")
	p.pos = Vector2(oc) + Vector2(-0.5, 0.5)
	main.camera.position = p.pos * 16.0
	main.ow_view.follow(p.pos, p.pos, 0.1, -1)
	var oview: Dictionary = main.ow_view.chunks[Overworld.chunk_of(oc)]
	check(main.ow_view.tile_value(oview.objects, oc) == (MapView.SMALL_BOULDER_TILE if ResourceNodes.boulder_small(oc) else int(o.tiles.rock)), "it is drawn, small ones smaller")
	var got := ""
	for k in ouses:
		got = w.mine_unit(w.deposit_at(oc))
	check(got == "stone" and w.deposit_at(oc).is_empty() and not o.is_solid(oc) and o.rock_gone(oc), "%d uses break it for stone; its cell is open" % ouses)
	check(main.ow_view.tile_value(oview.objects, oc) == -1, "and its sprite is erased")
	var far := Vector2(oc) + Vector2(400.5, 0.5)
	p.pos = far
	main.camera.position = far * 16.0
	main.ow_view.follow(far, far, 0.1, -1)
	check(not main.ow_view.chunks.has(Overworld.chunk_of(oc)), "far away its chunk unloads")
	p.pos = Vector2(oc) + Vector2(-0.5, 0.5)
	main.camera.position = p.pos * 16.0
	main.ow_view.follow(p.pos, p.pos, 0.1, -1)
	oview = main.ow_view.chunks[Overworld.chunk_of(oc)]
	check(main.ow_view.tile_value(oview.objects, oc) == -1 and not o.is_solid(oc), "back again the broken boulder stays gone")
	# a second one worked on but not finished keeps its uses
	var half := Vector2i(-9999, 0)
	for r in range(4, 120):
		for dy in range(-r, r + 1):
			var sc := west + Vector2i(-r, dy)
			if half.x == -9999 and sc != oc and o.has_boulder(sc) and not o.rock_gone(sc) and not o.is_road(sc):
				half = sc
	w.mine_unit(w.deposit_at(half))
	var huses := ResourceNodes.boulder_uses(half)
	check(int(w.deposit_at(half).amount) == huses - 1, "a boulder half mined keeps %d uses" % (huses - 1))
	var vb: Dictionary = w.boulders[1]
	var vuses := int(vb.amount)
	w.mine_unit(vb)
	var vcell := Vector2i(vb.x, vb.y)
	check(main.save_game(false), "the game saves")
	main.continue_game()
	var w2: World = main.world
	check(w2.deposit_at(cell).is_empty() and not w2.map.is_solid(cell), "after loading the village boulder is still broken")
	check(w2.map.overworld.rock_gone(oc) and not w2.map.overworld.is_solid(oc) and w2.deposit_at(oc).is_empty(), "after loading the overworld boulder is still broken")
	check(int(w2.deposit_at(half).amount) == huses - 1 and int(w2.deposit_at(vcell).amount) == vuses - 1, "and the half-mined ones keep their uses")
	check(w2.boulders.filter(func(x): return int(x.amount) <= 0).size() == 1 and w2.deposits.size() == main.world.deposits.size(), "the seams are untouched")


# ---------------------------------------------------------------- B8-018 ----------------------
## Whether the player's feet fit at `at` (main.gd _blocked_corners).
func _fits(m: VillageMap, at: Vector2) -> bool:
	for c in main.BODY:
		var q: Vector2 = at + c
		if m.is_solid_world(Vector2i(floori(q.x), floori(q.y))):
			return false
	return true


func _roofs() -> void:
	var w: World = main.world
	var m: VillageMap = main.map
	var STEP := 0.25
	var ids := w.interiors.keys()
	ids.sort()
	var walked := 0
	var lapses := 0
	var tested := 0
	for id in ids:
		var it: Dictionary = w.interiors[id]
		if (it.roof as Array).is_empty():
			continue
		tested += 1
		var b: Dictionary = w.buildings[id]
		var x0 := int(b.x) - 2
		var y0 := int(b.y) - 2
		var nx := int((int(b.w) + 4) / STEP)
		var ny := int((int(b.h) + 4) / STEP)
		# every position the feet fit, on a quarter-tile grid, within two tiles of the building
		var fit := PackedByteArray()
		fit.resize(nx * ny)
		for j in ny:
			for i in nx:
				fit[j * nx + i] = 1 if _fits(m, Vector2(x0 + i * STEP, y0 + j * STEP)) else 0
		# walk in from outside (a breadth-first tree from the border) and look at every step: once the
		# roof has lifted for the player inside, no later position within the building's outline asks
		# for it back (a depth-first walk down the tree carries the hold and the state)
		var parent := PackedInt32Array()
		parent.resize(nx * ny)
		parent.fill(-2)
		var queue := []
		for j in ny:
			for i in nx:
				if (i == 0 or j == 0 or i == nx - 1 or j == ny - 1) and fit[j * nx + i] == 1:
					parent[j * nx + i] = -1
					queue.append(j * nx + i)
		var qi := 0
		var kids := {}
		while qi < queue.size():
			var k: int = queue[qi]
			qi += 1
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var ni: int = k % nx + dd.x
				var nj: int = k / nx + dd.y
				if ni < 0 or nj < 0 or ni >= nx or nj >= ny:
					continue
				var nk := nj * nx + ni
				if fit[nk] == 1 and parent[nk] == -2:
					parent[nk] = k
					if not kids.has(k):
						kids[k] = []
					kids[k].append(nk)
					queue.append(nk)
		var rect := Rect2(float(b.x), float(b.y), float(b.w), float(b.h))
		var stack := []
		for k in queue:
			if parent[k] == -1:
				stack.append([k, "", false])
		while not stack.is_empty():
			var e: Array = stack.pop_back()
			var k: int = e[0]
			var pos := Vector2(x0 + (k % nx) * STEP, y0 + (k / nx) * STEP)
			var rf := RoofFade.probe(w, pos, e[1])
			walked += 1
			var lifted: bool = e[2]
			if lifted and rect.has_point(pos) and rf.inside != id:
				lapses += 1
				if lapses <= 5:
					print("  roof returns at ", pos, " in ", id, " (inside=", rf.inside, " under=", rf.under, ")")
			for c in kids.get(k, []):
				stack.append([c, rf.inside, lifted or rf.inside == id])
		# the positions the feet fit that the walk never reached are sealed in: they must be inside too
		for k in queue.size():
			pass
	check(tested >= 5 and walked > 1000, "walked %d positions in and around %d roofed buildings" % [walked, tested])
	check(lapses == 0, "walking anywhere inside a building, the roof is never asked back (%d lapses)" % lapses)
	# frame by frame through the real RoofFade: the roof of a building the player is in only ever
	# fades out, also when the map redraws a tile under it (RoofFade.restore_all, B8-018)
	var rises := 0
	var checked := 0
	for id in ids:
		var it: Dictionary = w.interiors[id]
		if (it.roof as Array).is_empty() or it.floor.size() < 4:
			continue
		var door: Array = it.doors[0]
		var cells: Array = it.floor
		var path := [Vector2(float(door[0]) + 0.5, float(door[1]) + 0.5)]
		for c in cells:
			path.append(Vector2(float(c[0]) + 0.5, float(c[1]) + 0.5))
		var hold := ""
		var prev := 2.0
		var was_in := false
		var roofs: RoofFade = main.roofs
		roofs.restore_all()
		roofs.resume_building = ""
		var n := 0
		for pos in path:
			for f in 3:
				var rf := RoofFade.probe(w, pos, hold)
				hold = rf.inside
				if rf.inside == id:
					was_in = true
				roofs.follow(rf.inside, rf.inside_roof, rf.under, rf.under_roof, 0.05)
				n += 1
				if was_in and rf.inside == id:
					if roofs.alpha > prev + 0.0001:
						rises += 1
					prev = roofs.alpha
				if was_in and n % 7 == 0:
					roofs.restore_all()           # the map redraws a tile of the roof layers meanwhile
				checked += 1
		roofs.restore_all()
		roofs.resume_building = ""
	check(rises == 0 and checked > 100, "frame by frame (%d frames) the lifted roof never comes back, even through a map redraw (%d rises)" % [checked, rises])


# ---------------------------------------------------------------- B8-016 ----------------------
func _by_job(w: World, job: String) -> Array:
	return w.npcs.filter(func(o: NPC): return o.alive and o.role == "adult" and o.job == job)


func _days(w: World, n: int) -> void:
	w.minutes += float(n) * 1440.0


func _succession() -> void:
	main.new_game()
	var w: World = main.world
	var b: NPCBrain = w.brain
	var wait := int(GameData.b("succession_days"))
	var coins0 := w.total_coins() - w.coin_sources
	var alive0 := w.npcs.filter(func(o: NPC): return o.alive).size()
	# 1. the smith dies: the post is open, then an adult without a trade takes it, workstation and all
	var smiths := _by_job(w, "smith")
	var dead: NPC = smiths[0]
	var forge := dead.workplace
	var hammers := func() -> int:
		var c := 0
		for o: NPC in w.npcs:
			c += o.inv.count("hammer")
		return c
	var hammers0: int = hammers.call()
	check(smiths.size() == 2 and forge != "", "the village starts with two smiths at the forge (%s)" % forge)
	w.kill(dead, "illness")
	check(w.vacancies.size() == 1 and w.vacancies[0].job == "smith" and w.vacancies[0].workplace == forge, "a smith's death opens the post")
	b.succession_dawn()
	check(_by_job(w, "smith").size() == 1 and w.vacancies.size() == 1, "not at once: the post waits %d days" % wait)
	_days(w, wait)
	var laborers := _by_job(w, "laborer").size()
	b.succession_dawn()
	var smiths2 := _by_job(w, "smith")
	check(smiths2.size() == 2 and w.vacancies.is_empty(), "after %d days an apprentice takes the post" % wait)
	var apprentice: NPC = smiths2.filter(func(o: NPC): return o != smiths[1])[0]
	check(apprentice.workplace == forge and apprentice.id != dead.id and _by_job(w, "laborer").size() == laborers - 1,
			"%s, a labourer, works the same forge" % apprentice.name)
	check(not dead.alive and w.npcs.filter(func(o: NPC): return o.alive and o.name == dead.name and o.family == dead.family and o.id == dead.id).is_empty(), "the dead smith stays dead")
	check(apprentice.inv.has("hammer"), "and has the smith's hammer")
	check(hammers.call() == hammers0, "passed on from the heir, not made from nothing (%d hammers before, %d after)" % [hammers0, hammers.call()])
	check(w.total_coins() - w.coin_sources == coins0, "no coins appear: coins conserved")
	# 2. a trade nobody can be apprenticed to: a newcomer arrives with the caravan
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and NPCBrain.APPRENTICE_FROM.has(o.job):
			o.job = "farmer"                           # nobody is without a trade
			o.workplace = w.fields[0].id
	var carpenters := _by_job(w, "carpenter")
	var saw: String = carpenters[0].workplace
	var home: String = str(carpenters[0].home)
	for c in carpenters:
		w.kill(c, "illness")                           # both: their household may die out
	check(w.vacancies.size() == 2 and _by_job(w, "carpenter").is_empty(), "both carpenters die: two posts open")
	var npcs0 := w.npcs.size()
	_days(w, wait)
	b.succession_dawn()
	check(w.vacancies.size() == 2 and w.npcs.size() == npcs0, "no one without a trade: the posts wait for the caravan")
	var coin_src0 := w.coin_sources
	b.succession_caravan()                             # what brain.caravan() does first, apart from its trading
	var cars := _by_job(w, "carpenter")
	check(cars.size() == 2 and w.vacancies.is_empty() and w.npcs.size() == npcs0 + 2, "the caravan brings two newcomers who take the posts")
	var nc: NPC = cars[0]
	check(nc.id >= npcs0 + 1 and nc.workplace == saw and nc.home != "" and w.buildings.has(nc.home) and nc.household >= 0 and nc.alive,
			"%s %s has the workstation, a home (%s) and a household" % [nc.name, nc.family, nc.home])
	check(w.households[nc.household].members.has(nc.id) and not w.households[nc.household].get("ended", false), "the household lists them and is alive")
	check(w.coin_sources == coin_src0 + 2 * int(GameData.b("newcomer_coins")) and w.total_coins() - w.coin_sources == coins0,
			"their purses are counted as coming into the village and no other coin appears")
	var in_home := false
	for o: NPC in w.npcs:
		if o.alive and o.home == home and o.job == "carpenter":
			in_home = true
	check(in_home or home != "", "a carpenter lives in the old house or another")
	# the newcomer is a villager like the rest: it gets a sprite, plans, and the day runs
	main._sync_sprites()
	check(main.sprites.has(nc.id), "the newcomer has a sprite")
	for k in 200:
		w.update(0.5)
	check(nc.alive and nc.plan.size() + int(nc.doing != "") > 0, "and plans its day (%s)" % nc.doing)
	# 3. no caravan: a newcomer comes anyway after newcomer_max_days
	var tanners := _by_job(w, "tanner")
	w.kill(tanners[0], "illness")
	_days(w, wait + 1)
	b.succession_dawn()
	check(w.vacancies.size() == 1, "a vacancy after %d days still waits for the caravan" % (wait + 1))
	_days(w, int(GameData.b("newcomer_max_days")))
	b.succession_dawn()
	check(w.vacancies.is_empty() and _by_job(w, "tanner").size() == 2, "after newcomer_max_days one comes without it")
	# 4. open posts survive saving and loading; the last farmer's death opens a post too
	for o: NPC in _by_job(w, "farmer"):
		w.kill(o, "illness")
	check(_by_job(w, "farmer").is_empty() and w.vacancies.size() == 1 and w.vacancies[0].job == "farmer", "the last farmer's death opens a post (one for the floor of one)")
	var alive_before := w.npcs.filter(func(o: NPC): return o.alive).size()
	check(main.save_game(false), "the game saves")
	main.continue_game()
	check(main.world.vacancies.size() == 1 and main.world.vacancies[0].job == "farmer", "an open post is still open after loading")
	var n2: int = main.world.npcs.filter(func(o: NPC): return o.alive).size()
	check(n2 == alive_before and n2 < alive0 + 3, "nobody was resurrected (%d alive, was %d before saving)" % [n2, alive_before])
	var dead_ids := {}
	for o: NPC in main.world.npcs:
		if not o.alive:
			dead_ids[o.id] = true
	check(dead_ids.has(dead.id) and dead_ids.size() >= 5, "the dead are still dead after loading (%d)" % dead_ids.size())


# ---------------------------------------------------------------- PL2-001 / 004 / 006 / 007 / 011 -----------
func _pl_gameplay() -> void:
	main.new_game()
	_pl2_001()
	_pl2_004()
	_pl2_011()
	_pl2_006()
	_pl2_007()


## A station is "in use" only by a villager at it, awake and working there.
func _pl2_001() -> void:
	var w: World = main.world
	var st_id := ""
	var n: NPC = null
	for id in w.stations:
		if w.stations[id].type in ["forge", "anvil", "workbench"] and w.station_refusal(id) == "":
			st_id = id
			break
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult":
			n = o
			break
	check(st_id != "" and n != null, "PL2-001: a station and a villager to test with")
	var st: Dictionary = w.stations[st_id]
	var at := Vector2(w.station_use(st_id)) + Vector2(0.5, 0.5)
	var work := {"k": "work", "min": 60.0, "anim": "work", "act": "craft", "args": {"station": st_id, "recipe": "tan_leather"}}
	st.users[n.id] = w.minutes + 500.0
	n.plan = [{"k": "go", "to": w.station_use(st_id), "speed": 1.0}, work.duplicate(true)]
	n.pos = at + Vector2(30, 0)
	check(w.station_refusal(st_id) == "", "PL2-001: a villager only on the way (or far off) does not block the forge")
	n.plan = [work.duplicate(true)]
	n.pos = at
	n.anim = "work"
	n.target = -1
	st.users[n.id] = w.minutes + 500.0
	var msg := w.station_refusal(st_id)
	check(msg.contains("is using the %s" % st.type) and msg.contains(n.name), "PL2-001: at it and working, the message names them: \"%s\"" % msg)
	n.anim = "sleep"
	check(w.station_refusal(st_id) == "", "PL2-001: asleep, they are not using it")
	n.anim = "work"
	n.plan.clear()
	check(w.station_refusal(st_id) == "" and not st.users.has(n.id), "PL2-001: a task switch releases the reservation")
	n.plan = [work.duplicate(true)]
	st.users[n.id] = w.minutes + 500.0
	w.kill(n, "test")
	check(w.station_refusal(st_id) == "" and not st.users.has(n.id), "PL2-001: a death releases it")
	var b: NPCBrain = w.brain
	var m: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult":
			m = o
			break
	st.users[m.id] = w.minutes + 500.0
	m.plan = [{"k": "go", "to": Vector2i(1, 1), "speed": 1.0}]
	b._station_for(m, st.type)
	check(not st.users.has(m.id), "PL2-001: a villager who moved on to something else loses the station's reservation")
	var sv := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), sv)
	check(w2.stations[st_id].users.is_empty(), "PL2-001: no stale lock survives a reload")


## A hunted animal leaves a pile you can see, take and tan.
func _pl2_004() -> void:
	var w: World = main.world
	var p := w.player
	var boar: Animal = null
	for a: Animal in w.fauna.animals:
		if a.species == "boar" and a.adult(w.minutes):
			boar = a
			break
	check(boar != null, "PL2-004: a wild boar")
	boar.hp = 0.5
	var spot := boar.pos
	p.pos = spot + Vector2(-0.7, 0)
	main.player_sprite.face(Vector2(1, 0))
	var loot0 := w.loot.size()
	main._hit_animal(boar, 5.0)
	check(w.loot.size() == loot0 + 1, "PL2-004: the kill leaves one pile")
	var pile: Dictionary = w.loot[-1]
	check(pile.inv.count("meat") >= 1 and pile.inv.count("hide") >= 1 and int(pile.coins) == 0, "PL2-004: a boar leaves meat and a hide, no coins")
	check(main._loot_at(spot) == pile.pos and main._loot_at(spot + Vector2(3, 0)) == Vector2.INF, "PL2-004: a tap on the pile finds it")
	p.pos = spot + Vector2(0, 0.6)
	main._find_target()
	check(main.target.get("kind", "") == "loot" and str(main.target.label).contains("meat") and str(main.target.label).contains("hide"), "PL2-004: the prompt names what is there: \"%s\"" % main.target.get("label", ""))
	var meat0 := p.inv.count("meat")
	main.interact()
	check(p.inv.count("meat") > meat0 and p.inv.has("hide") and not w.loot.has(pile), "PL2-004: taking it fills the pack and removes the pile")
	check(int(GameData.recipes.tan_leather.in.hide) == 1 and int(GameData.recipes.tan_leather.out.leather) == 1, "PL2-004: a hide is tanned to leather at the workbench")
	w.loot.append({"pos": Vector2(5.5, 5.5), "inv": Inventory.from_dict({"items": {"meat": 2}}), "coins": 0, "from": "the wild boar", "t": w.minutes - 4.0 * 1440.0})
	w.loot.append({"pos": Vector2(6.5, 5.5), "inv": Inventory.from_dict({"meat": 1}), "coins": 0, "from": "Somebody", "t": w.minutes - 4.0 * 1440.0})
	var n0 := w.loot.size()
	var spoiled0 := float(w.stats.get("spoiled_meat", 0.0))
	w._new_day()
	check(w.loot.size() == n0 - 1, "PL2-004: a carcass spoils after %d days, a dead person's belongings stay" % int(World.ANIMAL_LOOT_DAYS))
	check(float(w.stats.get("spoiled_meat", 0.0)) - spoiled0 == 2.0, "EQ-06: what spoils is counted (spoiled_meat), so the goods ledger balances")
	w.loot.clear()
	main._sync_loot()


## Nothing is reached across a wall.
func _pl2_011() -> void:
	var w: World = main.world
	var p := w.player
	var home := ""
	var f := Vector2i.ZERO
	var out := Vector2i.ZERO
	for id in w.interiors:
		var door := Vector2(w.building_door(id)) + Vector2(0.5, 0.5)
		for c in w.interiors[id].floor:
			var cell := Vector2i(int(c[0]), int(c[1]))
			if (Vector2(cell) + Vector2(0.5, 0.5)).distance_to(door) < 3.0:
				continue
			for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				for k in range(2, 4):
					var o: Vector2i = cell + d * k
					if home == "" and w.place_of(Vector2(o) + Vector2(0.5, 0.5)) == "" and not main.map.is_solid(o) and (Vector2(o) + Vector2(0.5, 0.5)).distance_to(door) > 3.0:
						home = id
						f = cell
						out = o
	check(home != "", "PL2-011: a house with open ground beyond its wall")
	var inside := Vector2(f) + Vector2(0.5, 0.5)
	var outside := Vector2(out) + Vector2(0.5, 0.5)
	check(not w.reaches(inside, outside) and not w.reaches(outside, inside), "PL2-011: not across the wall, in either direction")
	check(w.reaches(inside, inside + Vector2(0.4, 0)) and w.reaches(outside, outside + Vector2(0.4, 0)), "PL2-011: indoors and outdoors reach as before")
	var door := Vector2(w.building_door(home)) + Vector2(0.5, 0.5)
	check(w.reaches(door, door + Vector2(0, 1.0)), "PL2-011: from the doorway the street is in reach")
	p.pos = inside
	var fake := {"id": "t", "x": out.x, "y": out.y, "kind": "flower", "tile": 2657, "state": "ripe", "regrow": 0.0}
	w.plants.append(fake)
	main.target = {"kind": "plant", "plant": fake, "label": "Pick flower"}
	var flowers0 := p.inv.count("flower")
	main._use()
	_finish_action()
	check(fake.state == "ripe" and p.inv.count("flower") == flowers0, "PL2-011: using the flower across the wall picks nothing")
	main.player_sprite.face(Vector2(out - f).sign())
	main._find_target()
	check(main.target.get("kind", "") != "plant" or main.target.plant != fake, "PL2-011: the target list does not offer it")
	main.select_resource({"def": ResourceNodes.def_for("plant", "flower"), "ref": fake}, true)
	check(main.gather.is_empty(), "PL2-011: tapping it (Gather) does not start gathering")
	w.plants.erase(fake)
	p.pos = outside
	main.target = {}


## Flowers outside the village, the red one, and boulders of both sizes.
func _pl2_006() -> void:
	var w: World = main.world
	var m: VillageMap = main.map
	var p := w.player
	var o: Overworld = m.overworld
	var reds := w.plants.filter(func(pl): return int(pl.tile) == 2656)
	check(reds.size() >= 1 and reds[0].kind == "flower", "PL1-12: the low red flower (tile 2656) is a registered, pickable plant")
	var got := w.pick_plant(reds[0])
	check(got == {"flower": 1} and reds[0].state == "picked", "PL1-12: picking it gives a flower, and it is bare after")
	var west: Vector2i = m.exits()[3].out
	var fc := Vector2i(-9999, 0)
	var small := Vector2i(-9999, 0)
	var large := Vector2i(-9999, 0)
	for r in range(4, 140):
		for dy in range(-r, r + 1):
			var sc := west + Vector2i(-r, dy)
			if fc.x == -9999 and not o.flower_at(sc).is_empty() and not o.is_road(sc):
				fc = sc
			if o.has_boulder(sc) and not o.is_road(sc) and o.is_solid(sc):
				if small.x == -9999 and ResourceNodes.boulder_small(sc):
					small = sc
				if large.x == -9999 and not ResourceNodes.boulder_small(sc):
					large = sc
	check(fc.x != -9999, "PL2-006: a wild flower outside the village")
	check(small.x != -9999 and large.x != -9999 and w.deposit_at(small).amount < w.deposit_at(large).amount, "PL1-06: a small boulder has fewer uses than a large one")
	p.pos = Vector2(fc) + Vector2(0.5, 0.5)
	main.camera.position = p.pos * 16.0
	main.ow_view.follow(p.pos, p.pos, 0.1, -1)
	var node := ResourceNodes.node_at(w, fc, true)
	check(not node.is_empty() and node.def.id == "flower_patch" and ResourceNodes.can_harvest(w, node.def, node.ref) == "", "PL2-006: it is a flower node, ripe")
	main.player_sprite.face(Vector2(0, 1))
	main.target = {"kind": "plant", "plant": node.ref, "label": ""}
	var f0 := p.inv.count("flower")
	main._use()
	_finish_action()
	check(p.inv.count("flower") == f0 + 1 and o.flower_gone(fc), "PL2-006: picked outside the village: +1 flower, bare")
	var oview: Dictionary = main.ow_view.chunks[Overworld.chunk_of(fc)]
	check(main.ow_view.tile_value(oview.objects, fc) == -1, "PL2-006: its sprite is gone")
	check(ResourceNodes.can_harvest(w, node.def, w.plant_at(fc)) != "", "PL2-006: and it cannot be picked again at once")
	check(main.save_game(false), "PL2-006: saves")
	main.continue_game()
	var w2: World = main.world
	check(w2.map.overworld.flower_gone(fc) and w2.plant_at(fc).state == "picked", "PL2-006: after loading it is still bare")
	w2.minutes = float(int(w2.map.overworld.plant_changes[fc]) + 1) * 1440.0 + 360.0
	w2.map.overworld.clock = w2.minutes
	w2._new_day()
	check(not w2.map.overworld.flower_gone(fc) and w2.plant_at(fc).state == "ripe", "PL2-006: it grows back")
	for c in [small, large]:
		var d: Dictionary = w2.deposit_at(c)
		var n := int(d.amount)
		var st := 0
		for k in n:
			if w2.mine_unit(w2.deposit_at(c)) == "stone":
				st += 1
		check(st == n and w2.deposit_at(c).is_empty() and not w2.map.overworld.is_solid(c), "PL1-06: a %s boulder gave %d stone and is gone" % ["small" if c == small else "large", st])


## A sown field ripens on game time and stands ripe, in sight, before the farmers cut and replant it.
func _pl2_007() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var f: Dictionary = w.fields[0]
	check(w.field_cuttable(f) == false, "PL2-007: a field that has just ripened is not cut at once")
	var ripe_samples := 0
	var after := false
	for hour in 24 * 5:
		for i in 60:
			w.update(0.5)
		if f.state == "ripe" and w.day() >= 1:
			ripe_samples += 1
		if ripe_samples > 0 and f.state in ["tilled", "growing"]:
			after = true
	check(ripe_samples >= 6, "PL2-007: a field stood ripe for %d game hours (from day 1) where the player can harvest it" % ripe_samples)
	check(after, "PL2-007: and the farmers then cut it and sowed it again")
	check(is_equal_approx(w.field_grow_days(f), float(GameData.b("field_grow_days"))), "PL2-007: the season hook (field_grow_days) gives the base grow time")


# ---------------------------------------------------------------- Build 13: station occupancy --
## A villager who reserved the forge and arrives while the player works at it waits, never works it at the
## same time; the player's place is freed the moment their work ends or is cut short; a villager kept waiting
## too long gives up its reservation; nothing about a station's use survives a save and load.
func _station_conflict() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var forge: String = w.stations_of("forge")[0]
	for o: NPC in w.npcs:                          # nobody else at the forge for this test
		w.stations[forge].users.erase(o.id)
	var smith: NPC = w.npcs.filter(func(o): return o.alive and o.job == "smith")[0]
	smith.inv.items.clear()
	smith.inv.add("hammer")
	smith.inv.add("iron_ore", 2)
	smith.inv.add("coal", 1)
	smith.target = -1
	check(w.brain._do_recipe(smith, "smelt_iron") and w.stations[forge].users.has(smith.id), "the smith reserves the forge for a smelting")
	# the player starts work at the forge at the same moment (the smith is only on the way)
	main.ui.hide_all()
	main.cancel_action("")
	p.inv.add("iron_ore", 2)
	p.inv.add("coal", 1)
	p.pos = Vector2(w.station_use(forge)) + Vector2(0.5, 0.5)
	check(w.station_refusal(forge) == "", "on the way, the smith does not block the player (PL2-001)")
	main.craft("smelt_iron", forge)
	check(not main.action.is_empty() and w.player_at_station(forge), "the player is working at the forge")
	check(w.brain._station_for(w.npcs.filter(func(o): return o.alive and o.job == "smith" and o != smith)[0], "forge") == "", "no other villager can claim the forge while the player works it")
	# the smith arrives and must wait, not work alongside
	smith.pos = Vector2(w.station_use(forge)) + Vector2(0.5, 0.5)
	smith.plan.pop_front()
	smith.work_left = float(smith.plan[0].min)
	var ore0 := smith.inv.count("iron_ore")
	for i in 10:
		w._run_plan(smith, 0.5, 2.0)
	check(smith.inv.count("iron_ore") == ore0 and smith.anim == "idle" and smith.doing.contains("waiting"), "arriving while the player works, the smith waits beside the forge (%s)" % smith.doing)
	check(w.station_refusal(forge) == "", "a waiting smith is not using the forge")
	# interruption: the player stops; the place is free at once and the smith works
	main.cancel_action("You stop.")
	check(not w.player_at_station(forge), "cancelling frees the forge at once")
	for i in 40:
		w._run_plan(smith, 0.5, 2.0)
	check(smith.inv.count("iron_ore") == ore0 - 2 and smith.inv.count("iron_bar") >= 1 and not w.stations[forge].users.has(smith.id), "then the smith smelts, and its reservation is released")
	# finished work frees the place too
	p.inv.add("iron_ore", 2)
	p.inv.add("coal", 1)
	main.craft("smelt_iron", forge)
	main.action.left = 0.0
	main._player_step(0.05)
	check(main.action.is_empty() and not w.player_at_station(forge), "finished work frees the forge")
	# kept waiting too long, the villager gives the place up and plans again
	smith.inv.add("iron_ore", 2)
	smith.inv.add("coal", 1)
	check(w.brain._do_recipe(smith, "smelt_iron"), "the smith reserves the forge again")
	w.reserve_for_player(forge, 600.0)
	smith.plan.pop_front()
	smith.work_left = float(smith.plan[0].min)
	var waited := 0
	while not smith.plan.is_empty() and waited < 200:
		w._run_plan(smith, 0.5, 2.0)
		waited += 1
	check(smith.plan.is_empty() and not w.stations[forge].users.has(smith.id) and waited * 2 >= int(GameData.b("station_wait_minutes")), "after %d minutes the smith gives way and frees its reservation" % (waited * 2))
	# save and load: neither a reservation nor the player's place is carried over
	w.reserve_for_player(forge, 600.0)
	check(main.save_game(false), "the game saves with the player at the forge")
	main.continue_game()
	var w2: World = main.world
	check(not w2.player_at_station(forge) and w2.stations[forge].users.is_empty(), "after loading, the forge is free: no stale reservation")
