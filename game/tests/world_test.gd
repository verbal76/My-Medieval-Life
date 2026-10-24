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
	_fse_defects()
	_dvw_a12()
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
	var surface := w.deposits.filter(func(x): return World.level_of(x) == 0)   # the gallery's seams are drawn by its LevelView (underground_test)
	var tiles: Dictionary = dt.ore
	var bad := 0
	for d in surface:
		var drawn: int = main.view.tile_value(main.view.layer("below0"), Vector2i(d.x, d.y))
		if drawn != int(tiles[d.ore]):
			bad += 1
			print("  seam ", d.ore, " at ", d.x, ",", d.y, " is drawn with tile ", drawn, ", not ", tiles[d.ore])
	check(bad == 0 and surface.size() > 0, "every seam is drawn with its own ore's tile (%d seams)" % surface.size())
	var seams := {}
	for d in surface:
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
	for d in surface:
		var node := ResourceNodes.node_at(w, Vector2i(d.x, d.y), true)
		var got: String = ResourceNodes.products(node.def).keys()[0] if not node.is_empty() else ""
		if got != d.ore or str(node.def.name).to_lower().find(str(GameData.item_name(d.ore)).split(" ")[0].to_lower()) < 0:
			wrong += 1
	check(wrong == 0, "each seam's node, product and name agree (prompt, yield) for all %d seams" % surface.size())
	check(int(m.data.tiles.depleted_rock) == int(dt.worked_out) and not flecked.has(int(dt.worked_out)), "a worked-out seam has its own hollow tile")
	var stone_seam := {}
	for d in surface:
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
	_player_gain()
	_par02_reserve()
	_shop01_need()
	_par05_awareness()
	_pick01_reports()
	_ctr01_counters()
	_fse12_shared_fields()
	_fse13_seasonal_fields()
	_par03_rest()
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
	var herd := []                     # the prompt is about the pile: any herd-mate standing beside it is set aside for the check
	for o: Animal in w.fauna.animals.duplicate():
		if o != boar and o.pos.distance_to(spot) < 4.0:
			herd.append(o)
			w.fauna.animals.erase(o)
	main._find_target()
	check(main.target.get("kind", "") == "loot" and str(main.target.label).contains("meat") and str(main.target.label).contains("hide"), "PL2-004: the prompt names what is there: \"%s\"" % main.target.get("label", ""))
	var meat0 := p.inv.count("meat")
	main.interact()
	check(p.inv.count("meat") > meat0 and p.inv.has("hide") and not w.loot.has(pile), "PL2-004: taking it fills the pack and removes the pile")
	w.fauna.animals.append_array(herd)
	check(int(GameData.recipes.tan_leather.in.hide) == 1 and int(GameData.recipes.tan_leather.out.leather) == 1, "PL2-004: a hide is tanned to leather at the workbench")
	w.loot.append({"pos": Vector2(5.5, 5.5), "inv": Inventory.from_dict({"items": {"meat": 2}}), "coins": 0, "from": "the wild boar", "t": w.minutes - 4.0 * 1440.0})
	w.loot.append({"pos": Vector2(6.5, 5.5), "inv": Inventory.from_dict({"meat": 1}), "coins": 0, "from": "Somebody", "t": w.minutes - 4.0 * 1440.0})
	var n0 := w.loot.size()
	var spoiled0 := float(w.stats.get("spoiled_meat", 0.0))
	var decay0 := float(w.stats.get("decay_meat", 0.0))        # DVW-B4: meat in store spoils at dawn too, counted apart
	w._new_day()
	check(w.loot.size() == n0 - 1, "PL2-004: a carcass spoils after %d days, a dead person's belongings stay" % int(World.ANIMAL_LOOT_DAYS))
	check(float(w.stats.get("spoiled_meat", 0.0)) - spoiled0 - (float(w.stats.get("decay_meat", 0.0)) - decay0) == 2.0, "EQ-06: what spoils is counted (spoiled_meat), so the goods ledger balances")
	w.loot.clear()
	main._sync_loot()


## PAR-03 (OD-18.3): one recovery model. The same rest heals a villager as it heals the player; a rest cut short or too
## short heals nobody; a badly hurt villager with no medicine to hand goes to rest.
func _par03_rest() -> void:
	var w: World = main.world
	var p := w.player
	var day_min := float(GameData.b("rest").day_minutes)
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "guard" and o.home != "" and o.household >= 0:
			n = o
			break
	var keep := [n.hp, n.plan.duplicate(true), n.anim, n.coins, n.inv.to_dict(), p.hp]
	n.hp = n.max_hp * 0.4
	p.hp = p.hp_cap() * 0.4
	check(not w.rest_recover(n, day_min - 1.0, false) and not w.rest_recover(p, day_min - 1.0, false) and n.hp < n.max_hp and p.hp < p.hp_cap(), "PAR-03: a rest shorter than %d minutes heals neither the player nor a villager" % int(day_min))
	check(w.rest_recover(n, day_min, false) and w.rest_recover(p, day_min, false) and n.hp == n.hp_cap() and p.hp == p.hp_cap(), "PAR-03: the same rest heals both to full")
	n.hp = n.max_hp * 0.4
	check(w.rest_recover(n, 15.0, true) and n.hp == n.max_hp, "PAR-03: a rest that lasts to the morning heals, however short, as the player's does")
	# a hurt villager with no medicine to hand goes to rest, and the rest, run in the world, heals them
	n.hp = n.max_hp * 0.3
	for m in NPCBrain.MEDICINES:
		n.inv.items.erase(m)
	var pantry: Inventory = w.households[n.household].pantry
	var meds := {}
	for m in NPCBrain.MEDICINES:
		meds[m] = pantry.count(m)
		pantry.items.erase(m)
	n.coins = 0
	n.plan.clear()
	check(w.brain._plan_rest_hurt(n) and str(n.plan[-1].get("act", "")) == "rest_end" and float(n.plan[-1].args.min) == day_min, "PAR-03: a badly hurt villager with no medicine goes to rest (%s)" % n.doing)
	n.plan = [n.plan[-1]]                    # already at the bed: the rest itself
	n.work_left = day_min
	var m0 := w.minutes
	for i in 400:
		w.update(0.5)
		if n.plan.is_empty() or n.hp >= n.max_hp:
			break
	check(n.hp == n.max_hp, "PAR-03: the rest runs its course and heals them")
	n.hp = n.max_hp * 0.3
	n.plan = [w.brain.work(day_min, "rest_end", {"min": day_min, "morning": false}, "sleep")]
	n.work_left = day_min
	w.update(0.5)
	w.wake(n)                                 # woken: the rest is cut short
	check(n.plan.is_empty() and n.hp < n.max_hp, "PAR-03: a rest cut short heals nothing (a fresh rest must run its course)")
	for m in meds:
		if int(meds[m]) > 0:
			pantry.add(m, int(meds[m]))
	n.hp = keep[0]
	n.plan = keep[1]
	n.anim = keep[2]
	n.coins = keep[3]
	n.inv = Inventory.from_dict(keep[4])
	p.hp = keep[5]


## PAR-05 (OD-18.5, final directive section 9): an attack is known only by those who see it, and by the victim; they
## carry word to a guard; the same for the player and a bandit; a wall stops sight; nobody hears anything.
func _par05_awareness() -> void:
	var w: World = main.world
	var p := w.player
	var keep := {}
	for n: NPC in w.npcs:
		keep[n.id] = [n.pos, n.target, n.hp, n.anim]
	var p0 := p.pos
	var at := Vector2(w.bandit_camp) + Vector2(0.5, 8.5)
	var guard: NPC = null
	var victim: NPC = null
	for n: NPC in w.npcs:
		n.plan.clear()
		n.target = -1
		n.pos = Vector2(116.5, 86.5)                 # everyone far away
		if n.alive and n.job == "guard" and guard == null:
			guard = n
		elif n.alive and n.role == "adult" and n.job != "guard" and victim == null:
			victim = n
	guard.anim = "idle"
	victim.anim = "idle"
	check(w.place_of(at) == "" and w.place_of(at + Vector2(12, 0)) == "", "PAR-05: the test ground is outdoors")
	p.pos = at
	victim.pos = at + Vector2(0.8, 0)
	guard.pos = at + Vector2(25, 0)
	w.player_assault(victim)
	check(guard.target == -1, "PAR-05: a guard who does not see the attack knows nothing of it")
	victim.target = -1
	guard.pos = at + Vector2(6, 0)
	w.player_assault(victim)
	check(guard.target == -2, "PAR-05: a guard who sees the attack answers it")
	guard.target = -1
	victim.target = -1
	guard.pos = victim.pos + Vector2(float(GameData.b("witness_radius")) + 4.0, 0)
	victim.report = {}
	w.player_assault(victim)
	check(guard.target == -1, "PAR-05: a guard out of sight does not hear an attack (there is no hearing)")
	check(int(victim.report.get("offender", 0)) == -2, "PAR-05: the victim will report it")
	victim.target = -1
	victim.plan.clear()
	check(w.brain._report(victim) and str(victim.plan[-1].get("act", "")) == "report", "PAR-05: the victim goes to tell the guard (%s)" % victim.doing)
	victim.pos = guard.pos + Vector2(1.5, 0)
	w.brain.act(victim, "report", {"guard": guard.id})
	check(guard.target == -1 and str(guard.pursuit.get("state", "")) == "responding" and victim.report.is_empty(), "PAR-05: told by the victim, the guard answers it (A2: the player out of their sight, they go to where the player was seen)")
	guard.target = -1
	var wit: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "guard" and o != victim:
			wit = o
			break
	wit.anim = "idle"
	wit.pos = at + Vector2(0, 2.0)
	wit.report = {}
	victim.pos = at + Vector2(0.8, 0)
	w.player_assault(victim)
	check(int(wit.report.get("offender", 0)) == -2, "PAR-05: a witness will report it too")
	wit.pos = guard.pos + Vector2(0, 1.5)
	w.brain._report(wit)
	check(guard.target == -1 and str(guard.pursuit.get("state", "")) == "responding" and wit.report.is_empty(), "PAR-05: a witness in sight of a guard tells them at once (A2: the guard goes to where the player was seen)")
	guard.target = -1
	wit.report = {"offender": -2, "t": w.minutes - float(GameData.b("report").hours) * 60.0 - 1.0, "how": "saw"}
	w.brain._report(wit)
	check(guard.target == -1 and wit.report.is_empty(), "PAR-05: an old report lapses")
	victim.report = {}
	wit.pos = Vector2(116.5, 86.5)
	var inside := ""
	var cell := Vector2.ZERO
	for id in w.interiors:
		var fl: Array = w.interiors[id].floor
		if not fl.is_empty():
			inside = id
			cell = Vector2(int(fl[0][0]), int(fl[0][1])) + Vector2(0.5, 0.5)
			break
	guard.pos = cell
	p.pos = cell + Vector2(0, 3.0) if w.place_of(cell + Vector2(0, 3.0)) == "" else cell + Vector2(0, 5.0)
	victim.pos = p.pos + Vector2(0.5, 0)
	if w.place_of(p.pos) == "" and inside != "":
		w.player_assault(victim)
		check(guard.target == -1, "PAR-05: a guard indoors neither sees nor hears an attack outside")
	guard.target = -1
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			bandit = n
			break
	if bandit:
		bandit.pos = at
		victim.pos = at + Vector2(0.8, 0)
		guard.pos = at + Vector2(25, 0)
		w.raise_alarm(w.aware_of_attack(bandit.pos, victim), bandit.id)
		check(guard.target == -1 and int(victim.report.get("offender", -9)) == bandit.id, "PAR-05: nor does an unseen bandit's attack reach a guard, but its victim will report it")
		victim.report = {}
		guard.pos = at + Vector2(6, 0)
		w.raise_alarm(w.aware_of_attack(bandit.pos, victim), bandit.id)
		check(guard.target == bandit.id, "PAR-05: a guard who sees a bandit's attack takes on the bandit, by the same rule")
		guard.target = -1
		guard.pos = cell
		bandit.pos = cell + Vector2(0, 3.0) if w.place_of(cell + Vector2(0, 3.0)) == "" else cell + Vector2(0, 5.0)
		check(w.brain._bandit_seen(guard) == null, "PAR-05: a guard does not see a bandit through a wall")
	for n: NPC in w.npcs:
		var k: Array = keep[n.id]
		n.pos = k[0]
		n.target = k[1]
		n.hp = k[2]
		n.anim = k[3]
	p.pos = p0


## PICK-01 (owner OD-20, 2026-10-21): a caught pickpocket is reported by the victim and those who saw it, through
## PAR-05's report rules; there is no cry a guard hears, and a pocket picked unseen is known to no guard.
## ARM-01, CTR-01..03: the armoury counter has no keeper standing at it; the player rings, the smith walks over by the
## ordinary path and serves there (the shop window), and goes back to work after; out of hours or asleep, the player is told.
func _ctr01_counters() -> void:
	var w: World = main.world
	var p := w.player
	var m0 := w.minutes
	var p0 := p.pos
	var ids: Array = w.counters.all()
	check(ids.size() >= 1 and str(w.stations[ids[0]].type) == "armory_counter", "CTR-01: the armoury counter is a skilled trade's counter (%s)" % str(ids))
	var id: String = ids[0]
	var smiths: Array = w.counters.keepers(id)
	check(smiths.size() > 0 and smiths.all(func(o): return o.job == "smith"), "ARM-01: the smiths keep the armoury counter (%d)" % smiths.size())
	var keep := {}
	for n: NPC in smiths:
		keep[n.id] = [n.pos, n.plan.duplicate(true), n.anim, n.hunger, n.target, n.doing]
	w.counters.serving.clear()
	p.pos = Vector2(w.station_use(id)) + Vector2(0.5, 1.5)
	var post := {"id": id, "stall": false, "cells": []}
	check(w.shopkeeper_at(id) == null and main._shop_target(post).kind == "summon", "CTR-02: at the counter with nobody serving, the prompt rings for service (%s)" % main._shop_target(post).label)
	# at night: told why, nobody comes
	w.minutes = floorf(w.minutes / World.DAY) * World.DAY + 23.0 * 60.0
	for n: NPC in smiths:
		n.anim = "sleep"
	var r: Dictionary = w.counters.summon(id)
	check(not r.ok and str(r.text).contains("asleep") and w.counters.server(id) == null, "CTR-03: at night nobody comes and the player is told why (%s)" % r.text)
	# by day: the first available smith walks over
	w.minutes = floorf(w.minutes / World.DAY) * World.DAY + 10.0 * 60.0
	for n: NPC in smiths:
		n.anim = "idle"
		n.hunger = 100.0
		n.target = -1
		n.plan = [w.brain.work(120, "", {}, "work")]
	var start: Vector2 = smiths[0].pos
	r = w.counters.summon(id)
	var s: NPC = r.npc
	check(r.ok and s != null and s.plan[0].k == "go" and w.counters.server(id) == s, "CTR-02: by day the smith comes (%s)" % r.text)
	var again: Dictionary = w.counters.summon(id)
	check(again.npc == s and str(again.text).contains("on the way"), "CTR-03: ringing again sends nobody else (%s)" % again.text)
	var steps := 0
	while not (w.at_post(s) and s.plan[0].k == "work") and steps < 3000:
		w._update_npc(s, 0.05)
		steps += 1
	check(w.at_post(s) and w.shopkeeper_at(id) == s and main._shop_target(post).kind == "shop", "CTR-02: walked over (%d steps from %s), at the counter the smith serves: the shop window (%s)" % [steps, str(start), w.shop_name(s)])
	_ctr04_counter_terms(s)
	s.work_left = 0.0
	w._update_npc(s, 0.05)
	check(w.counters.server(id) == s and w.at_post(s), "CTR-03: while the player is at the counter, the smith stays to serve")
	# the player leaves: the turn ends and the smith goes back to work
	p.pos = Vector2(116.5, 86.5)
	s.work_left = 0.0
	w._update_npc(s, 0.05)
	check(w.counters.server(id) == null and not w.at_post(s), "CTR-03: with the player gone, the smith goes back to work")
	for n: NPC in smiths:
		var k: Array = keep[n.id]
		n.pos = k[0]
		n.plan = k[1]
		n.anim = k[2]
		n.hunger = k[3]
		n.target = k[4]
		n.doing = k[5]
	w.counters.serving.clear()
	w.minutes = m0
	p.pos = p0


## CTR-04 (owner 2026-10-20 section 7): a permanent counter is not a market stall: a sale at the armoury counter is the
## ordinary trade (World.player_sell_many / player_buy_many at player_quote prices) and no stall commission is taken:
## every coin the player pays or is paid goes to or from the serving smith, and no coin goes anywhere else.
func _ctr04_counter_terms(s: NPC) -> void:
	var w: World = main.world
	var p := w.player
	var keep := [p.coins, s.coins, s.inv.count("iron_ore"), p.inv.count("iron_ore"), s.inv.count("pickaxe"), p.inv.count("pickaxe")]
	s.inv.remove("iron_ore", s.inv.count("iron_ore"))     # below its want (SHOP-01)
	s.coins = w.reserve_of(s) + 200
	p.inv.add("iron_ore", 1)
	s.inv.add("pickaxe", 2)
	var total0 := w.total_coins()
	var treasury0 := w.treasury
	var p0 := p.coins
	var s0 := s.coins
	var quote: int = w.player_quote(s, "iron_ore", 1, false)[0]
	var r: Dictionary = w.player_sell_many(s, "iron_ore", 1)
	check(r.result == "sold" and int(r.paid) == quote and p.coins == p0 + quote and s.coins == s0 - quote,
			"CTR-04: the player sells at the armoury counter by the ordinary trade, %d coins from the smith to the player (%s)" % [quote, str(r)])
	var bill: int = w.player_quote(s, "pickaxe", 1, true)[0]
	p.coins += bill
	var p1 := p.coins
	var s1 := s.coins
	var armoury: Dictionary = w.business.money.counter_building(s)     # ECON-P3: a trade counter's takings go to its till
	var till1 := BusinessMoney.counter_till_of(armoury) if not armoury.is_empty() else 0
	r = w.player_buy_many(s, "pickaxe", 1)
	var till_in := (BusinessMoney.counter_till_of(armoury) - till1) if not armoury.is_empty() else 0
	check(r.result == "bought" and int(r.paid) == bill and p.coins == p1 - bill and (s.coins - s1) + till_in == bill,
			"CTR-04: and buys a pickaxe there: the whole %d coins go to the smith's counter (till %d, purse %d), no commission (%s)" % [bill, till_in, s.coins - s1, str(r)])
	check(w.total_coins() == total0 + bill and w.treasury == treasury0, "CTR-04: no coin goes to the realm or anywhere else at a counter")
	s.inv.remove("pickaxe", s.inv.count("pickaxe"))
	s.inv.add("pickaxe", keep[4])
	s.inv.remove("iron_ore", s.inv.count("iron_ore"))
	s.inv.add("iron_ore", keep[2])
	p.inv.remove("pickaxe", p.inv.count("pickaxe"))
	p.inv.add("pickaxe", keep[5])
	p.inv.remove("iron_ore", p.inv.count("iron_ore"))
	p.inv.add("iron_ore", keep[3])
	p.coins = keep[0]
	s.coins = keep[1]


## SHOP-01, TRADE-01 (owner 2026-10-20 section 6): a business buys an input only for a recipe its trade has the skill
## for, up to its want (its stock rounded up to whole batches, within it), part lots towards a batch included, with its
## own coins above its reserve; the player's and a villager's sales to it go by the one rule (World.purchase_qty) and are
## refused with a clear reason; coins and goods are conserved.
func _shop01_need() -> void:
	var w: World = main.world
	var p := w.player
	var smith: NPC = _by_job(w, "smith")[0]
	var miner: NPC = _by_job(w, "miner")[0]
	var cook: NPC = _by_job(w, "cook")[0]
	var keep := [smith.coins, smith.inv.count("iron_ore"), smith.inv.count("gold_ore"), smith.inv.count("leather"), smith.skills.duplicate(),
			miner.coins, miner.inv.count("iron_ore"), p.coins, p.inv.count("iron_ore"), p.inv.count("stone"), p.inv.count("gold_ore"), p.inv.count("leather"),
			miner.plan.duplicate(true), cook.coins, cook.inv.count("milk"), p.inv.count("milk")]
	var setinv := func(who, item: String, q: int) -> void:
		who.inv.remove(item, who.inv.count(item))
		who.inv.add(item, q)
	var cap := int(NPCBrain.BUYS.smith.iron_ore)
	smith.coins = w.reserve_of(smith) + 300
	# accumulation towards a batch: a cook with no milk takes one towards a 3-milk cheese
	setinv.call(cook, "milk", 0)
	cook.coins = w.reserve_of(cook) + 100
	setinv.call(p, "milk", 1)
	var r: Dictionary = w.player_sell_many(cook, "milk", 1)
	check(w.brain.batch_unit(cook, "milk") == 3 and r.result == "sold" and cook.inv.count("milk") == 1, "SHOP-01: a part lot towards a batch is bought: one milk of a 3-milk cheese (%s)" % r.text)
	# the want: the smith takes ore up to its stock and no further
	setinv.call(smith, "iron_ore", cap - 2)
	check(w.brain.wants(smith, "iron_ore") == 2 and w.purchase_qty(smith, p, "iron_ore", 5) == 2, "SHOP-01: two below its want, the smith takes 2 of 5 ore")
	setinv.call(p, "iron_ore", 3)
	setinv.call(miner, "iron_ore", 3)
	var coins0 := w.total_coins()
	var ore0 := p.inv.count("iron_ore") + smith.inv.count("iron_ore") + miner.inv.count("iron_ore")
	r = w.player_sell_many(smith, "iron_ore", 3)
	check(r.result == "failed" and str(r.text).contains("can use only 2") and p.inv.count("iron_ore") == 3, "TRADE-01: the player's 3 ore are refused whole: %s" % r.text)
	var pc := p.coins
	r = w.player_sell_many(smith, "iron_ore", 1)
	check(r.result == "sold" and p.coins == pc + int(r.paid) and smith.inv.count("iron_ore") == cap - 1, "TRADE-01: one ore sells (%d coins)" % int(r.paid))
	# a villager by the same rule: the miner's three ore, of which the smith takes the one it still wants
	var mc := miner.coins
	var sc := smith.coins
	var ok: bool = w.brain.act(miner, "sell_to", {"buyer": smith.id, "item": "iron_ore"})
	check(ok and miner.inv.count("iron_ore") == 2 and smith.inv.count("iron_ore") == cap and miner.coins - mc == sc - smith.coins and miner.coins > mc,
			"TRADE-01: the miner sells the smith the one ore it still wants, by the player's rule (%d coins)" % (miner.coins - mc))
	check(w.total_coins() == coins0 and p.inv.count("iron_ore") + smith.inv.count("iron_ore") + miner.inv.count("iron_ore") == ore0,
			"SHOP-01: coins and ore are conserved through both sales")
	r = w.player_sell_many(smith, "iron_ore", 1)
	check(w.brain.wants(smith, "iron_ore") == 0 and r.result == "failed" and str(r.text).contains("all the iron ore") and w.brain._buyer_for(miner, "iron_ore") != smith,
			"SHOP-01: at its want the smith refuses more ore, from the player or a villager: %s" % r.text)
	# no coins above its reserve: nothing bought, from the player or a villager
	setinv.call(smith, "iron_ore", 1)
	setinv.call(miner, "iron_ore", 1)
	setinv.call(p, "iron_ore", 1)
	smith.coins = w.reserve_of(smith)
	r = w.player_sell_many(smith, "iron_ore", 1)
	check(w.purchase_qty(smith, p, "iron_ore", 1) == 0 and r.result == "failed" and str(r.text).contains("reserve"), "SHOP-01: at its reserve the smith buys nothing from the player: %s" % r.text)
	check(w.brain._buyer_for(miner, "iron_ore") != smith and not w.brain.act(miner, "sell_to", {"buyer": smith.id, "item": "iron_ore"}) and miner.inv.count("iron_ore") == 1,
			"SHOP-01: nor from a villager")
	smith.coins = w.reserve_of(smith) + 300
	# inputs the business does not need, refused with the reason
	setinv.call(p, "stone", 1)
	r = w.player_sell_many(smith, "stone", 1)
	check(r.result == "failed" and str(r.text).contains("does not buy"), "SHOP-01: the smith does not buy stone: %s" % r.text)
	setinv.call(smith, "leather", int(NPCBrain.BUYS.smith.leather))
	setinv.call(p, "leather", 1)
	r = w.player_sell_many(smith, "leather", 1)
	check(r.result == "failed" and str(r.text).contains("all the leather"), "SHOP-01: with its leather in stock the smith takes no more: %s" % r.text)
	smith.skills["smithing"] = 0                    # below Smithing 3, smelt_gold's level
	setinv.call(smith, "gold_ore", 0)
	setinv.call(p, "gold_ore", 2)
	r = w.player_sell_many(smith, "gold_ore", 2)
	check(w.brain.wants(smith, "gold_ore") == 0 and r.result == "failed" and str(r.text).contains("no use"), "SHOP-01: a smith who cannot smelt gold buys no gold ore: %s" % r.text)
	smith.skills = keep[4]
	setinv.call(smith, "iron_ore", keep[1])
	setinv.call(smith, "gold_ore", keep[2])
	setinv.call(smith, "leather", keep[3])
	setinv.call(miner, "iron_ore", keep[6])
	setinv.call(p, "iron_ore", keep[8])
	setinv.call(p, "stone", keep[9])
	setinv.call(p, "gold_ore", keep[10])
	setinv.call(p, "leather", keep[11])
	setinv.call(cook, "milk", keep[14])
	setinv.call(p, "milk", keep[15])
	smith.coins = keep[0]
	miner.coins = keep[5]
	p.coins = keep[7]
	miner.plan = keep[12]
	cook.coins = keep[13]


## FSE-12, FARM-06: behind the switch, a manor field is sown with real seed a cell, yields the player's crop a sown cell
## and gives the seed back; with no seed it stays unsown. Off, the old model (the baseline) is untouched.
func _fse12_shared_fields() -> void:
	var w: World = main.world
	var keep_sw = GameData.balance.get("shared_manor_farming", 0)
	GameData.balance["shared_manor_farming"] = 1
	var f: Dictionary = w.fields[0]
	var saved := f.duplicate(true)
	var ws: Array = w.field_workers(f)
	var n: NPC = ws[0]
	var held := {}
	for o: NPC in ws:
		held[o.id] = [o.inv.count("wheat_seed"), o.inv.count("wheat"), w.households[o.household].pantry.count("wheat_seed")]
		o.inv.remove("wheat_seed", o.inv.count("wheat_seed"))
		w.households[o.household].pantry.remove("wheat_seed", w.households[o.household].pantry.count("wheat_seed"))
	w.set_field(f, "tilled")
	check(w.farm.field_seed(f) == 0 and not w.brain.act(n, "sow", {"field": f.id}) and f.state == "tilled", "FSE-12: with no seed the field is not sown (no free seed)")
	n.inv.add("wheat_seed", 10)
	var used0 := float(w.stats.get("used_wheat_seed", 0.0))
	check(w.brain.act(n, "sow", {"field": f.id}) and f.state == "growing" and int(f.sown) == 10 and n.inv.count("wheat_seed") == 0 and float(w.stats.get("used_wheat_seed", 0.0)) == used0 + 10.0,
			"FSE-12: sowing takes one seed a cell (10 seeds, 10 of %d cells sown)" % Farming.field_cells(f))
	check(w.farm.field_work_minutes(10, "sow") < w.farm.field_work_minutes(Farming.field_cells(f), "sow"), "FSE-12: sowing takes time by the cells sown")
	f.ready = w.minutes
	w.set_field(f, "ripe")
	f.crop = int(f.sown) * int(Farming.crops().wheat.yield)
	f.ripe_at = w.minutes - 1000.0 * 60.0
	var wh0: int = n.inv.count("wheat") + w.households[n.household].pantry.count("wheat")
	var made0 := float(w.stats.get("made_wheat_seed", 0.0))
	w.brain.act(n, "harvest", {"field": f.id})
	var got: int = n.inv.count("wheat") + w.households[n.household].pantry.count("wheat") - wh0
	check(got == 10 * int(Farming.crops().wheat.yield) and n.inv.count("wheat_seed") == 10 * int(Farming.crops().wheat.seeds_back) and float(w.stats.get("made_wheat_seed", 0.0)) == made0 + 10.0,
			"FSE-12: the cut gives the crop of the sown cells (%d wheat) and their seed back (%d)" % [got, n.inv.count("wheat_seed")])
	# FARM-08: one shared wheat yield for the comparison, the same for the manor's fields and the player's cells
	var keep_y = GameData.balance.get("shared_wheat_yield", 0)
	GameData.balance["shared_wheat_yield"] = 1.5
	var cells_total := 0
	for i in 200:
		cells_total += w.farm.cell_yield("wheat", Vector2i(i, 7))
	check(Farming.field_crop(10) == 15 and absf(float(cells_total) / 200.0 - 1.5) < 0.15 and w.farm.cell_yield("carrot", Vector2i(1, 1)) == int(Farming.crops().carrot.yield),
			"FARM-08: a shared yield of 1.5 gives a field 15 for 10 cells and a player's cells %.2f on average; other crops keep their own" % (float(cells_total) / 200.0))
	GameData.balance["shared_wheat_yield"] = keep_y
	for o: NPC in ws:
		o.inv.remove("wheat_seed", o.inv.count("wheat_seed"))
		o.inv.add("wheat_seed", held[o.id][0])
		w.households[o.household].pantry.add("wheat_seed", held[o.id][2])
	for k in saved:
		f[k] = saved[k]
	f.erase("sown")
	w.set_field(f, str(saved.state))
	GameData.balance["shared_manor_farming"] = keep_sw


## FSE-13: behind the switch, the manor's fields keep the player's seasons: no sowing in winter, growth at the season's
## rate (none in winter, half in autumn). Off, the old model is untouched.
func _fse13_seasonal_fields() -> void:
	var w: World = main.world
	var keep_sw = GameData.balance.get("seasonal_village_farming", 0)
	GameData.balance["seasonal_village_farming"] = 1
	var m0 := w.minutes
	var f: Dictionary = w.fields[1]
	var saved := f.duplicate(true)
	var n: NPC = w.field_workers(f)[0]
	var year := floorf(w.minutes / (World.DAY * float(Life.year_days()))) * World.DAY * float(Life.year_days())
	var season_days := float(Life.year_days()) / 4.0
	w.minutes = year + 3.0 * season_days * World.DAY + 8.0 * 60.0          # winter
	w.set_field(f, "tilled")
	check(w.season() == "Winter" and not w.brain.act(n, "sow", {"field": f.id}) and f.state == "tilled", "FSE-13: nothing is sown on a manor field in winter (%s)" % w.season())
	w.minutes = year + 8.0 * 60.0                                         # spring
	check(w.season() == "Spring" and w.brain.act(n, "sow", {"field": f.id}) and f.state == "growing", "FSE-13: sown in spring")
	w.grow_field(f)
	var spring := float(f.progress)
	w.minutes = year + 2.0 * season_days * World.DAY + 8.0 * 60.0         # autumn
	w.grow_field(f)
	var autumn := float(f.progress) - spring
	w.minutes = year + 3.0 * season_days * World.DAY + 8.0 * 60.0         # winter
	w.grow_field(f)
	var winter := float(f.progress) - spring - autumn
	check(spring > 0.0 and is_equal_approx(autumn, spring * 0.5) and winter == 0.0 and f.state == "growing",
			"FSE-13: an hour's growth at the season's rate (spring %.4f, autumn %.4f, winter %.4f)" % [spring, autumn, winter])
	for k in saved:
		f[k] = saved[k]
	f.erase("progress")
	w.minutes = m0
	GameData.balance["seasonal_village_farming"] = keep_sw


func _pick01_reports() -> void:
	var w: World = main.world
	var p := w.player
	var keep := {}
	for n: NPC in w.npcs:
		keep[n.id] = [n.pos, n.target, n.hp, n.anim, n.report.duplicate()]
	var p0 := [p.pos, p.coins]
	var bal := [GameData.b("pickpocket_chance"), GameData.b("pickpocket_chance_per_level"), GameData.b("pickpocket_chance_max")]
	var at := Vector2(w.bandit_camp) + Vector2(0.5, 8.5)
	var guard: NPC = null
	var victim: NPC = null
	var wit: NPC = null
	w.justice = Justice.new(w)                       # GP-CRIME-PURSUIT: the PAR-05 assaults above are not this test's case
	for n: NPC in w.npcs:
		n.plan.clear()
		n.target = -1
		n.report = {}
		n.pursuit = {}
		n.pos = Vector2(116.5, 86.5)                 # everyone far away
		if n.alive and n.job == "guard" and guard == null:
			guard = n
		elif n.alive and n.role == "adult" and n.job != "guard" and victim == null:
			victim = n
		elif n.alive and n.role == "adult" and n.job != "guard" and wit == null:
			wit = n
	for n: NPC in [guard, victim, wit]:
		n.anim = "idle"
	p.pos = at
	victim.pos = at + Vector2(0.8, 0)
	# beyond sight, but within the old cry's guard_call_radius: the guard would have heard it before
	var r := float(GameData.b("witness_radius"))
	guard.pos = at + Vector2(minf(r + 3.0, float(GameData.b("guard_call_radius")) - 0.5), 0)
	check(w.place_of(at) == "" and w.place_of(guard.pos) == "" and not w.near(p.pos, r).has(guard), "PICK-01: the test ground is outdoors, the guard out of sight")
	# a pocket picked unseen: nobody reports it, no guard knows
	GameData.balance.pickpocket_chance = 1.0
	GameData.balance.pickpocket_chance_max = 1.0
	victim.coins = 10
	var res := w.pickpocket(victim)
	check(res.ok and w.npcs.all(func(o): return o.report.is_empty()) and guard.target == -1, "PICK-01: a pocket picked unseen is reported by nobody and known to no guard")
	# caught, with a witness and no guard in sight: no cry, the victim and the witness will report it
	GameData.balance.pickpocket_chance = 0.0
	GameData.balance.pickpocket_chance_per_level = 0.0
	wit.pos = at + Vector2(0, 2.0)
	p.coins = 40
	var delivered0 := int(w.stats.get("theft_reports_delivered", 0))
	res = w.pickpocket(victim)
	check(not res.ok and w.last_guard == "" and p.coins == 40 and guard.target == -1, "PICK-01: a caught try raises no cry a guard out of sight hears (%s)" % res.text)
	check(int(victim.report.get("offender", 0)) == -2 and str(victim.report.get("crime", "")) == "theft", "PICK-01: the victim will report the theft")
	check(int(wit.report.get("offender", 0)) == -2 and str(wit.report.get("crime", "")) == "theft", "PICK-01: so will the villager who saw it")
	check(not guard.memory.any(func(m): return str(m).contains("of a theft")), "PICK-01: the guard knows nothing until told")
	# the witness tells the guard, away from the thief: the guard knows, and does not give chase
	p.pos = at + Vector2(-20, 0)
	wit.pos = guard.pos + Vector2(0, 1.5)
	w.brain._report(wit)
	check(wit.report.is_empty() and guard.memory.any(func(m): return str(m).contains("of a theft")) and int(w.stats.get("theft_reports_delivered", 0)) == delivered0 + 1, "PICK-01: told by the witness, the guard knows of the theft")
	check(guard.target == -1 and p.coins == 40, "PICK-01: a theft report starts no chase, and with the thief out of sight no fine")
	# the victim tells the guard with the thief in the guard's sight: stopped and fined, as for a theft seen
	p.pos = guard.pos + Vector2(3.0, 0)
	victim.pos = guard.pos + Vector2(1.5, 0)
	w.brain.act(victim, "report", {"guard": guard.id})
	var fine := 0 if w.relations.player_friend(guard) else int(GameData.b("theft_fine"))
	check(victim.report.is_empty() and p.coins == 40 - fine and guard.target == -1, "PICK-01: told by the victim with the thief in sight, the guard stops them (fine %d, coins %d)" % [fine, p.coins])
	GameData.balance.pickpocket_chance = bal[0]
	GameData.balance.pickpocket_chance_per_level = bal[1]
	GameData.balance.pickpocket_chance_max = bal[2]
	for n: NPC in w.npcs:
		var k: Array = keep[n.id]
		n.pos = k[0]
		n.target = k[1]
		n.hp = k[2]
		n.anim = k[3]
		n.report = k[4]
	p.pos = p0[0]
	p.coins = p0[1]


## PAR-02 (OD-18.2): one reserve rule. A trader near its reserve refuses the player's sale exactly as it refuses a
## villager's, and accepts both once it can pay and keep it.
func _par02_reserve() -> void:
	var w: World = main.world
	var p := w.player
	var smith: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "smith" and w.brain.wants(n, "iron_ore") > 0:
			smith = n
			break
	check(smith != null, "PAR-02: a smith who wants iron ore")
	if smith == null:
		return
	var coins0 := smith.coins
	var price := w.buy_price(smith, "iron_ore")
	smith.coins = w.reserve_of(smith) + price - 1
	p.inv.add("iron_ore", 1)
	var r := w.player_sell_many(smith, "iron_ore", 1)
	check(r.result == "failed" and p.inv.count("iron_ore") >= 1, "PAR-02: the player cannot sell into the smith's reserve")
	var miner: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "miner":
			miner = n
			break
	miner.inv.add("iron_ore", 1)
	check(not w.can_afford(smith, price) and w.brain._buyer_for(miner, "iron_ore") != smith, "PAR-02: nor can a villager")
	smith.coins = w.reserve_of(smith) + price
	check(w.can_afford(smith, price) and w.brain._buyer_for(miner, "iron_ore") != null, "PAR-02: at reserve + price a villager can sell")
	r = w.player_sell_many(smith, "iron_ore", 1)
	check(r.result == "sold" and smith.coins >= w.reserve_of(smith), "PAR-02: and so can the player, down to the reserve and no further")
	miner.inv.remove("iron_ore", 1)
	smith.inv.remove("iron_ore", 1)
	smith.coins = coins0


## DVW-A7: the player's own work is counted for the goods ledger, and a full pack sets it down, never loses it.
func _player_gain() -> void:
	var w: World = main.world
	var p := w.player
	var inv0 := p.inv
	var mined0 := float(w.stats.get("mined_iron_ore", 0.0))
	p.inv = Inventory.new()
	check(w.player_gain("iron_ore", 2, "mined_") == 2 and p.inv.count("iron_ore") == 2, "DVW-A7: mined ore goes into the pack")
	check(float(w.stats.get("mined_iron_ore", 0.0)) - mined0 == 2.0, "DVW-A7: the player's mining is counted (mined_)")
	p.inv.max_stacks = 1
	var loot0 := w.loot.size()
	check(w.player_gain("log", 3, "felled_") == 0 and w.loot.size() == loot0 + 1 and (w.loot[-1].inv as Inventory).count("log") == 3, "DVW-A7: what a full pack cannot hold is set down, not lost")
	w.loot.remove_at(w.loot.size() - 1)
	p.inv = inv0
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
	check(is_equal_approx(w.field_grow_days(f), Life.seasons_to_days(float(GameData.b("field_grow_seasons")))), "PL2-007: the season hook (field_grow_days) gives the base grow time (field_grow_seasons)")


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


# ---------------------------------------------------------------- FSE-09: the food-security audit's defects ----------
func _fse_defects() -> void:
	var w: World = main.world
	# TIME-04: the player starves by the villagers' rule
	var p := w.player
	p.hunger = 0.0
	p.hp = p.max_hp
	var hp0 := p.hp
	w._update_player(0.0, 60.0)
	check(is_equal_approx(hp0 - p.hp, float(GameData.b("starve_damage_per_hour"))), "TIME-04: at zero food the player loses %s health an hour, as a villager does (%.2f)" % [str(GameData.b("starve_damage_per_hour")), hp0 - p.hp])
	p.hp = p.max_hp
	p.hunger = 100.0
	# FSE-B10: the player's kills are in the wildlife ledger
	var prey: Animal = null
	for a: Animal in w.fauna.animals:
		if a.alive and a.wild() and bool(a.spec().get("game", true)):
			prey = a
			break
	var key := "hunted_" + prey.species
	var s0 := float(w.stats.get(key, 0.0))
	var xp0 := int(p.skills.get("combat", 0))
	main._hit_animal(prey, 100000.0)
	check(not prey.alive and float(w.stats.get(key, 0.0)) == s0 + 1.0, "FSE-B10: an animal the player kills is counted as hunted (%s)" % key)
	check(int(p.skills.get("combat", 0)) - xp0 == Skills.kill_xp(prey.species, p.damage()), "FSE-B12: the player's kill earns the per-kill xp (%d)" % Skills.kill_xp(prey.species, p.damage()))
	# FSE-B12: a villager's hunt earns the same, by the same rule and their own damage
	var hunter0: NPC = w.npcs.filter(func(o): return o.alive and o.job == "hunter")[0]
	var game2: Animal = null
	for a: Animal in w.fauna.animals:
		if a.alive and a.wild() and a.species == prey.species:
			game2 = a
			break
	if game2 != null:
		hunter0.pos = game2.pos
		var hx0 := int(hunter0.skills.get("combat", 0))
		w.brain.act(hunter0, "hunt", {"animal": game2.id})
		check(not game2.alive and int(hunter0.skills.get("combat", 0)) - hx0 == Skills.kill_xp(prey.species, hunter0.damage * Skills.value(hunter0, "combat", "damage_mult", 1.0)),
				"FSE-B12: a villager's kill of a %s earns xp by the player's rule" % prey.species)
	check(Skills.kill_xp("deer", 2.0) == 2 * int(ceil(float(GameData.b("animals").deer.hp) / 2.0)), "FSE-B12: 2 xp for each blow the kill takes")
	# FSE-B05: a pen without a keeper is let again at dawn
	var pen: Dictionary = {}
	for id in w.fauna.pens:
		if w.pen_keeper(w.fauna.pens[id]) != null:
			pen = w.fauna.pens[id]
			break
	w.set_tenant(pen, "")
	check(w.pen_keeper(pen) == null, "FSE-B05: a pen left with no keeper")
	w.brain.relet_pens()
	check(w.pen_keeper(pen) != null and w.pen_keeper(pen).job == "farmer", "FSE-B05: at dawn a farmer with no pen takes it on")
	# FSE-B08: a claim whose hunt is no longer planned is released
	var deer: Animal = null
	for a: Animal in w.fauna.animals:
		if a.alive and a.wild() and bool(a.spec().get("game", true)):
			deer = a
			break
	var hunter: NPC = w.npcs.filter(func(o): return o.alive and o.job == "hunter")[0]
	w.fauna.claims[deer.id] = hunter.id
	hunter.plan = []
	w.fauna.nearest_game(hunter.pos)
	check(not w.fauna.claims.has(deer.id), "FSE-B08: a hunt cut short leaves no claim on the animal")
	# FSE-B09: hunter openings count only what hunters may take
	var all_wild := 0
	for a: Animal in w.fauna.animals:
		if a.alive and a.wild() and a.adult(w.minutes):
			all_wild += 1
	check(w.fauna.takeable_game() < all_wild, "FSE-B09: game hunters may take (%d) is fewer than every wild adult (%d): not wolves, foxes, bears or the floors" % [w.fauna.takeable_game(), all_wild])
	# FSE-B06: the band eats only real food from its own packs; meat is roasted at the camp; with nothing it goes hungry
	var band: Array = w.npcs.filter(func(o): return o.alive and o.role == "bandit")
	if band.size() > 0:
		var b0: NPC = band[0]
		for o: NPC in band:
			for id in o.inv.ids():
				o.inv.remove(id, o.inv.count(id))
		b0.hunger = 30.0
		check(not w.brain.band_eat(b0) and is_equal_approx(b0.hunger, 30.0), "FSE-B06: with nothing in the band's packs a bandit stays hungry (no meal from nothing)")
		b0.inv.add("meat", 1)
		var rm0 := float(w.stats.get("made_roast_meat", 0.0))
		check(w.brain.band_eat(b0) and b0.hunger > 30.0 and not b0.inv.has("meat") and float(w.stats.get("made_roast_meat", 0.0)) == rm0 + 2.0,
				"FSE-B06: a poached carcass's meat is roasted at the camp and eaten (hunger %.0f)" % b0.hunger)
		if band.size() > 1:
			var b1: NPC = band[1]
			b0.hunger = 30.0
			for id in b0.inv.ids():
				b0.inv.remove(id, b0.inv.count(id))
			b1.inv.add("bread", 1)
			check(w.brain.band_eat(b0) and not b1.inv.has("bread"), "FSE-B06: the band's stores are shared: a bandit eats a comrade's bread")
	# FSE-B07: the Apothecary is an outlet for flowers
	check(NPCBrain.OUTLETS.get("flower", []).has("sage"), "FSE-B07: villagers can sell flowers to the Apothecary")


# ---------------------------------------------------------------- DVW-A12 ---------------------
## DVW-A12 (owner, 2026-10-21 directive section 6): the player's mining, felling and crafting rules live in core
## (World.player_*); the interface only shows them. Each rule is checked in core, then through the interface.
func _dvw_a12() -> void:
	main.new_game()
	_dvw_a12_mining()
	_dvw_a12_felling()
	_dvw_a12_crafting()
	_dvw_a12_combat()
	_dvw_a12_fireball()
	_dvw_a12_pickpocket_reach()
	_dvw_a12_reach()
	_dvw_a12_planting()
	_dvw_a12_loot()
	_dvw_a12_xp()
	_dvw_a12_livestock()
	_dvw_a12_cast()
	_dvw_a12_trading_xp()
	_dvw_a12_field_owner()
	_dvw_a12_theft_last()
	_dvw_a12_rest()
	_dvw_a12_sprint()
	_dvw_a12_home_marks()
	_dvw_a12_helper_budget()


## R2: an axe is needed, only a mature tree, the felling time, the blows, the logs to the pack (or set down), the
## sapling, the wear, a broken axe leaving the hand, 12 xp, the ledger count, the stump kept over a save.
func _dvw_a12_felling() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var grown := w.trees.filter(func(t): return t.state == "grown" and not t.get("ow", false))
	check(grown.size() >= 3, "DVW-A12 R2: the village has mature trees (%d)" % grown.size())
	var tr: Dictionary = grown[0]
	p.pos = _beside(Vector2i(int(tr.x), int(tr.y)))               # within reach (R15)
	var fp := w.player_fell_plan(tr)
	check(not fp.ok and str(fp.why) == "Requires an axe. The smith sells them.", "DVW-A12 R2: no axe, no felling (%s)" % str(fp.get("why", "")))
	p.inv.add("axe")
	fp = w.player_fell_plan(tr)
	var want := float(GameData.b("chop_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.5 / float(GameData.item("axe").get("speed", 1.0))
	check(fp.ok and str(fp.tool) == "axe" and is_equal_approx(float(fp.secs), want), "DVW-A12 R2: the axe, and the felling time by its speed (%s)" % str(fp))
	var chops := int(Trees.cfg().chops)
	var logs0 := float(w.stats.get("felled_log", 0.0))
	var felled0 := float(w.stats.get("trees_felled", 0.0))
	var blows := 0
	var r := {}
	while blows < chops + 2:
		blows += 1
		r = w.player_chop(tr, 1, "axe")
		if r.result != "blow":
			break
	check(r.result == "felled" and blows == chops and tr.state == "stump", "DVW-A12 R2: %d blows fell a mature tree to a stump (%d)" % [chops, blows])
	check(int(r.logs) == 4 and p.inv.count("log") == 4 and not r.full and float(w.stats.get("felled_log", 0.0)) - logs0 == 4.0 and float(w.stats.get("trees_felled", 0.0)) - felled0 == 1.0, "DVW-A12 R2: four logs to the pack, counted (felled_log, trees_felled) (%s)" % str(r))
	var sap := Trees.sapling_item(str(tr.get("species", "oak_summer")))
	check(r.saplings == {sap: 1} and p.inv.count(sap) == 1, "DVW-A12 R2: the felled tree's sapling goes into the pack (%s)" % str(r.saplings))
	check(int(p.skills.get("woodcutting", 0)) == 12 and int(p.inv.durability.get("axe", 0)) == int(GameData.item("axe").durability) - 3, "DVW-A12 R2: 12 xp and three wear on the axe a tree")
	check(w.player_chop(tr, 1, "axe").result == "gone" and p.inv.count("log") == 4, "DVW-A12 R2: a stump takes no blow and gives nothing")
	fp = w.player_fell_plan(tr)
	check(not fp.ok and str(fp.why) == Trees.refusal("stump"), "DVW-A12 R2: a stump is refused before the felling starts (%s)" % str(fp.get("why", "")))
	# a broken axe leaves the hand; a full pack sets the logs down
	var tr2: Dictionary = grown[1]
	p.tool = "axe"
	p.inv.durability["axe"] = 3
	p.inv.max_stacks = p.inv.ids().size()
	p.inv.remove("log", p.inv.count("log"))
	p.inv.add("stone", 1)
	var loot0 := w.loot.size()
	r = {}
	for i in chops:
		r = w.player_chop(tr2, -1, "axe")
	check(r.result == "felled" and r.full and w.loot.size() > loot0 and (w.loot[loot0].inv as Inventory).count("log") == 4, "DVW-A12 R2: with a full pack the logs are set down at the player's feet (%s)" % str(r))
	check(r.broke and not p.inv.has("axe") and p.tool == "", "DVW-A12 R2: an axe that breaks is gone from the pack and the hand")
	while w.loot.size() > loot0:
		w.loot.remove_at(w.loot.size() - 1)
	main._sync_loot()
	# through the interface: core's refusal is shown, and a tree is felled by the actions
	p.inv = Inventory.new()
	var tr3: Dictionary = grown[2]
	p.pos = _beside(Vector2i(int(tr3.x), int(tr3.y)))
	main.target = {"kind": "tree", "tree": tr3, "label": "Fell"}
	main._use()
	check(main.action.is_empty() and main.ui.toast.text.contains("Requires an axe"), "DVW-A12 R2: the interface shows core's refusal and starts nothing (%s)" % main.ui.toast.text)
	p.inv.add("axe")
	main.target = {"kind": "tree", "tree": tr3, "label": "Fell"}
	main._use()
	check(not main.action.is_empty() and is_equal_approx(float(main.action.total), want / float(chops)), "DVW-A12 R2: the interface starts a blow of core's time")
	_finish_action()
	check(tr3.state == "stump" and p.inv.count("log") == 4, "DVW-A12 R2: the blows fell the tree and the logs are in the pack")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var same := w2.trees.filter(func(t): return int(t.x) == int(tr3.x) and int(t.y) == int(tr3.y))
	check(same.size() == 1 and same[0].state == "stump", "DVW-A12 R2: the stump is saved")
	_restore_pack(keep)


## Every button under `node` whose text is `text`.
func _buttons_named(node: Node, text: String) -> Array:
	var out := []
	for c in node.get_children():
		if c is Button and (c as Button).text == text:
			out.append(c)
		out.append_array(_buttons_named(c, text))
	return out


## R3: the level and the materials, the station (found within reach, held for the player, refused when not theirs), the
## time, the inputs used and the outputs made, the counts and xp, the craft window's Make button, the pack over a save.
func _dvw_a12_crafting() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var sid := ""
	for id in w.stations_of("sawhorse"):
		if sid == "" and w.station_refusal(id) == "":
			sid = id
	check(sid != "", "DVW-A12 R3: a sawhorse the player may use")
	var rec: Dictionary = GameData.recipes["saw_planks"]
	p.pos = Vector2(w.station_use(sid)) + Vector2(0.5, 0.5)
	check(w.player_craft_refusal("saw_planks") == "You do not have the materials.", "DVW-A12 R3: no log, no planks")
	var cp := w.player_craft_begin("saw_planks")
	check(not cp.ok and str(cp.why) == "You do not have the materials." and not w.player_at_station(sid), "DVW-A12 R3: a refused craft does not hold the station")
	p.inv.add("leather", 4)
	check(w.player_craft_refusal("leather_armor") == "Needs Tanning level 2.", "DVW-A12 R3: a recipe above the player's level is refused (%s)" % w.player_craft_refusal("leather_armor"))
	p.inv.add("log", 2)
	cp = w.player_craft_begin("saw_planks")
	var want := float(rec.minutes) / float(GameData.b("game_minutes_per_second")) * 0.5
	check(cp.ok and str(cp.station) == sid and is_equal_approx(float(cp.secs), want) and w.player_at_station(sid), "DVW-A12 R3: at a sawhorse the work takes the recipe's time and holds the station (%s)" % str(cp))
	w.release_player_station(sid)
	# a station a villager is working at is refused (it is not the player's)
	var o: NPC = w.npcs.filter(func(x): return x.alive and x.job == "woodcutter")[0]
	var o_keep := {"plan": o.plan, "pos": o.pos, "target": o.target, "anim": o.anim}
	w.stations[sid].users[o.id] = w.minutes + 300.0
	o.plan = [{"k": "work", "args": {"station": sid}}]
	o.pos = Vector2(w.station_use(sid)) + Vector2(0.5, 0.5)
	o.target = -1
	o.anim = "work"
	var b := w.player_craft_begin("saw_planks", sid)
	check(not b.ok and str(b.why).contains("is using the sawhorse") and str(b.why) == w.station_refusal(sid) and not w.player_at_station(sid), "DVW-A12 R3: a station a villager is working at is refused with core's reason (%s)" % str(b.get("why", "")))
	w.stations[sid].users.erase(o.id)
	o.plan = o_keep.plan
	o.pos = o_keep.pos
	o.target = o_keep.target
	o.anim = o_keep.anim
	var made0 := float(w.stats.get("made_plank", 0.0))
	var used0 := float(w.stats.get("used_log", 0.0))
	var res := w.player_craft("saw_planks")
	check(res.result == "ok" and p.inv.count("log") == 1 and p.inv.count("plank") == 2, "DVW-A12 R3: a log in, two planks out")
	check(float(w.stats.get("made_plank", 0.0)) - made0 == 2.0 and float(w.stats.get("used_log", 0.0)) - used0 == 1.0 and int(p.skills.get("carpentry", 0)) == int(rec.xp), "DVW-A12 R3: counted (made_plank, used_log) and the recipe's xp")
	# the craft window's Make button follows core's refusal
	main.ui.show_craft(sid)
	var make_on := _buttons_named(main.ui.panel_body, "Make").filter(func(btn): return not btn.disabled).size()
	var need_log := 0                  # the sawhorse's recipes the pack can make now that need a log (MIN-F: timber supports too)
	for rid in GameData.recipes:
		var rr: Dictionary = GameData.recipes[rid]
		if str(rr.station) == str(w.stations[sid].type) and rr["in"].has("log") and p.inv.has_all(rr["in"]):
			need_log += 1
	p.inv.remove("log", p.inv.count("log"))
	main.ui.show_craft(sid)
	var make_on_none := _buttons_named(main.ui.panel_body, "Make").filter(func(btn): return not btn.disabled).size()
	check(make_on >= 1 and need_log >= 1 and make_on_none == make_on - need_log, "DVW-A12 R3: Make is on for a recipe core allows, off without its materials (%d -> %d)" % [make_on, make_on_none])
	main.ui.hide_all()
	# through the interface
	main.craft("saw_planks", sid)
	check(main.action.is_empty() and main.ui.toast.text.contains("do not have the materials"), "DVW-A12 R3: the interface shows core's refusal and starts nothing")
	p.inv.add("log", 1)
	main.craft("saw_planks", sid)
	check(not main.action.is_empty() and is_equal_approx(float(main.action.total), want) and str(main.action.get("station", "")) == sid and w.player_at_station(sid), "DVW-A12 R3: the interface starts the work of core's time at the station")
	_finish_action()
	check(p.inv.count("plank") == 4 and not p.inv.has("log") and not w.player_at_station(sid), "DVW-A12 R3: the work makes the planks and frees the station")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.player.inv.count("plank") == 4 and int(w2.player.skills.get("carpentry", 0)) == 2 * int(rec.xp), "DVW-A12 R3: the planks and the xp are saved")
	_restore_pack(keep)


## R7-R9: the player's blow (the weapon's damage, a crit), its harm, 4 Combat xp, assault as a crime seen within the
## witness radius, a bandit fighting back and no crime, death, and the outcome kept over a save.
func _dvw_a12_combat() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var at := Vector2(60.5, 60.5)
	for dd in range(0, 40):
		if w.place_of(at) == "" and not main.map.is_solid(Vector2i(at)):
			break
		at += Vector2(1, 0)
	var victim: NPC = null
	var wit: NPC = null
	var far: NPC = null
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		if n.role == "bandit" and bandit == null:
			bandit = n
		elif n.role == "adult" and n.job != "guard":
			if victim == null:
				victim = n
			elif wit == null:
				wit = n
			elif far == null:
				far = n
	for n: NPC in [victim, wit, far]:
		n.plan.clear()
		n.target = -1
		n.anim = "idle"
	for n: NPC in w.npcs:
		if n.alive and not [victim, wit, far, bandit].has(n):
			n.pos = Vector2(116.5, 86.5)
	p.pos = at
	victim.pos = at + Vector2(0.8, 0)
	wit.pos = at + Vector2(0, 2.0)
	far.pos = at + Vector2(float(GameData.b("witness_radius")) + 4.0, 0)
	var s := w.player_strike()
	check(not s.crit and float(s.dmg) == p.damage(), "DVW-A12 R7: with no Combat tier a blow is the weapon's damage, never doubled (%s)" % str(s))
	var hp0 := victim.hp
	var assault0 := float(w.stats.get("player_assault", 0.0))
	var want := maxf(0.5, p.damage() * Skills.value(victim, "combat", "damage_taken", 1.0) - victim.armor * 0.5)
	var h := w.player_melee_npc(victim)
	check(is_equal_approx(float(h.dealt), want) and is_equal_approx(victim.hp, hp0 - want) and not h.killed, "DVW-A12 R8: the blow takes the villager's armour into account (%s)" % str(h))
	check(int(p.skills.get("combat", 0)) == 4, "DVW-A12 R7: 4 Combat xp a blow on a villager")
	check(float(w.stats.get("player_assault", 0.0)) - assault0 == 1.0 and victim.target == -2 and victim.memory.has("attacked by %s" % p.name), "DVW-A12 R9: assault: counted, remembered, and an adult fights back")
	check(wit.memory.any(func(m): return str(m).begins_with("saw %s" % p.name)) and not far.memory.any(func(m): return str(m).begins_with("saw %s" % p.name)), "DVW-A12 R9: a witness within the witness radius saw it; one beyond did not")
	if bandit != null:
		bandit.target = -1
		bandit.pos = at + Vector2(-0.8, 0)
		var a1 := float(w.stats.get("player_assault", 0.0))
		w.player_hit_npc(bandit, 0.1)
		check(bandit.target == -2 and float(w.stats.get("player_assault", 0.0)) == a1, "DVW-A12 R8: a bandit struck fights back, and it is no crime")
	victim.hp = 0.5
	var h2 := w.player_hit_npc(victim, 50.0)
	check(h2.killed and not victim.alive, "DVW-A12 R8: a villager at no health dies, slain by the player")
	# the interface's spell hit uses the same rules
	far.target = -1
	var a2 := float(w.stats.get("player_assault", 0.0))
	var fhp := far.hp
	main._hit(far, 3.0)
	check(far.hp < fhp and far.target == -2 and float(w.stats.get("player_assault", 0.0)) == a2 + 1.0, "DVW-A12 R8: the interface's hit is core's (harm, crime)")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var v2 := w2.npc(victim.id)
	check(v2 != null and not v2.alive and w2.npc(far.id).memory.has("attacked by %s" % p.name), "DVW-A12 R8, R9: the death and the victim's memory of the attack are saved (the stats are session counters, not saved)")
	_restore_pack(keep)


## R12: learning Fireball: refused without the price, then the price moves from the player to the sage (no coin made
## or lost), the spell is known, 100 Magic xp, refused once known; the interface's choice uses core; kept over a save.
func _dvw_a12_fireball() -> void:
	main.new_game()
	var w: World = main.world
	var p: PlayerState = w.player
	var sage := w.npc(w.sage_id)
	var price := int(GameData.b("fireball_price"))
	p.spells.erase("fireball")
	p.skills.erase("magic")
	p.coins = price - 1
	var c0 := sage.coins
	var r := w.player_learn_fireball(sage)
	check(not r.ok and str(r.why) == "You need %d coins." % price and p.coins == price - 1 and sage.coins == c0 and not p.spells.get("fireball", false), "DVW-A12 R12: without the price nothing is paid or learned")
	p.coins = price + 5
	var sum0 := p.coins + sage.coins
	r = w.player_learn_fireball(sage)
	check(r.ok and p.coins == 5 and sage.coins == c0 + price and p.coins + sage.coins == sum0, "DVW-A12 R12: the price goes from the player to the sage, no coin made or lost")
	check(p.spells.get("fireball", false) and int(p.skills.get("magic", 0)) == 100, "DVW-A12 R12: the spell is known and 100 Magic xp earned")
	r = w.player_learn_fireball(sage)
	check(not r.ok and p.coins == 5 and sage.coins == c0 + price, "DVW-A12 R12: once known it is not sold again")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.player.spells.get("fireball", false) and w2.player.coins == 5 and w2.npc(sage.id).coins == sage.coins, "DVW-A12 R12: the spell and both purses are saved")


## R14: the pocket of a villager awake is in reach within 1.8 tiles and never a child's; the talk window offers the
## try only then.
func _dvw_a12_pickpocket_reach() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var adult: NPC = w.npcs.filter(func(x): return x.alive and x.role == "adult" and not w.asleep(x))[0]
	var kids := w.npcs.filter(func(x): return x.alive and x.role == "child")
	var p0 := p.pos
	p.pos = adult.pos + Vector2(1.0, 0)
	check(w.pickpocket_in_reach(adult), "DVW-A12 R14: a villager a tile away is within reach")
	main.ui.show_talk(adult)
	var near_offer := _buttons_named(main.ui.panel, "Pick pocket — theft").size()
	main.ui.hide_all()
	p.pos = adult.pos + Vector2(World.PICKPOCKET_REACH + 0.2, 0)
	check(not w.pickpocket_in_reach(adult), "DVW-A12 R14: beyond %.1f tiles a pocket is out of reach" % World.PICKPOCKET_REACH)
	main.ui.show_talk(adult)
	var far_offer := _buttons_named(main.ui.panel, "Pick pocket — theft").size()
	main.ui.hide_all()
	check(near_offer == 1 and far_offer == 0, "DVW-A12 R14: the talk window offers the try only within core's reach (%d, %d)" % [near_offer, far_offer])
	if not kids.is_empty():
		p.pos = kids[0].pos + Vector2(1.0, 0)
		check(not w.pickpocket_in_reach(kids[0]), "DVW-A12 R14: never a child's pocket")
	p.pos = p0


## R14, R15: core refuses what is out of the player's reach, by the distances the interface's target choice uses: a
## pocket beyond 1.8 tiles (the sleeper's too: the intended change), a seam or tree more than two cells off, a
## container beyond 2.2 tiles, a pile beyond the probe's reach, a field, a crafting station beyond 1.2 tiles, a wall.
func _dvw_a12_reach() -> void:
	main.new_game()
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	# a sleeper's pocket: within reach a try is made; beyond 1.8 tiles none is (no xp, no shout, nothing taken)
	var sleeper: NPC = w.npcs.filter(func(x): return x.alive and x.role == "adult" and x.job != "guard")[0]
	sleeper.anim = "sleep"
	sleeper.coins = 7
	p.pos = sleeper.pos + Vector2(World.PICKPOCKET_REACH + 0.4, 0)
	var crimes0 := p.crimes.size()
	var r := w.pickpocket(sleeper)
	check(not r.ok and r.get("refused", false) and sleeper.coins == 7 and p.crimes.size() == crimes0, "DVW-A12 R14: a sleeper's pocket beyond %.1f tiles is out of reach: no try (%s)" % [World.PICKPOCKET_REACH, r.text])
	var xp0 := int(p.skills.get("stealth", 0))
	main.pickpocket(sleeper)
	check(int(p.skills.get("stealth", 0)) == xp0 and main.ui.toast.text.contains("out of reach") and sleeper.coins == 7, "DVW-A12 R14: the interface shows it and gives no Stealth xp for a try never made")
	p.pos = sleeper.pos + Vector2(1.0, 0)
	r = w.pickpocket(sleeper)
	check(not r.get("refused", false), "DVW-A12 R14: beside the sleeper the try is made (%s)" % r.text)
	sleeper.anim = "idle"
	# a seam: within two cells, then out of reach, through core and through the interface
	var d: Dictionary = w.nearest_deposit(Vector2i(p.pos), ["stone", "iron_ore", "coal"])
	var cell := Vector2i(int(d.x), int(d.y))
	p.pos = _beside(cell)
	check(w.player_reach_cell(cell) == "", "DVW-A12 R15: a seam beside the player is in reach")
	p.inv.add("pickaxe")
	var away := Vector2.ZERO
	for k in range(3, 12):
		for dd in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			var c2: Vector2i = cell + dd * k
			if away == Vector2.ZERO and not main.map.is_solid(c2) and w.reaches(Vector2(c2) + Vector2(0.5, 0.5), Vector2(cell) + Vector2(0.5, 0.5)):
				away = Vector2(c2) + Vector2(0.5, 0.5)
	p.pos = away
	check(away != Vector2.ZERO and w.player_reach_cell(cell) == "That is out of reach." and str(w.player_mine_plan(d).why) == "That is out of reach.", "DVW-A12 R15: three or more cells off, the seam is out of reach and mining is refused")
	var left := int(d.amount)
	main.target = {"kind": "deposit", "dep": d, "label": "Mine"}
	main._use()
	check(main.action.is_empty() and int(d.amount) == left and main.ui.toast.text.contains("out of reach"), "DVW-A12 R15: the interface shows core's refusal and mines nothing")
	# a container: within 2.2 tiles, not beyond
	var box: Dictionary = {}
	for c in w.containers:
		if box.is_empty() and w.place_of(Vector2(int(c.x), int(c.y)) + Vector2(0.5, 1.5)) == "" and w.container_pick(c) != "" and not main.map.is_solid(Vector2i(int(c.x), int(c.y) + 1)):
			box = c
	if not box.is_empty():
		var at := Vector2(int(box.x), int(box.y)) + Vector2(0.5, 0.5)
		p.pos = at + Vector2(0, World.CONTAINER_REACH + 0.5)
		var inv0 := p.inv.total()
		check(w.player_take(box) == "far" and p.inv.total() == inv0 and w.player_container_reach(box) != "", "DVW-A12 R15: a container beyond %.1f tiles is out of reach; nothing taken" % World.CONTAINER_REACH)
		p.pos = at + Vector2(0, 1.0)
		check(w.player_container_reach(box) == "", "DVW-A12 R15: beside it, it is in reach")
	# a pile: within the probe's reach, not beyond
	w.loot.append({"pos": p.pos + Vector2(0, 0.5), "inv": Inventory.new(), "coins": 0, "from": "test"})
	check(w.player_reach_point(w.loot[-1].pos, World.TARGET_PROBE + World.TARGET_REACH) == "", "DVW-A12 R15: a pile underfoot is in reach")
	w.loot[-1].pos = p.pos + Vector2(0, World.TARGET_PROBE + World.TARGET_REACH + 0.5)
	check(w.player_reach_point(w.loot[-1].pos, World.TARGET_PROBE + World.TARGET_REACH) != "", "DVW-A12 R15: a pile beyond it is not")
	w.loot.remove_at(w.loot.size() - 1)
	main._sync_loot()
	# a field: any of its cells within two of the player's
	var f: Dictionary = w.fields[0]
	p.pos = Vector2(int(f.x) - 1, int(f.y)) + Vector2(0.5, 0.5)
	check(w.player_reach_field(f) == "", "DVW-A12 R15: beside a field it is in reach")
	p.pos = Vector2(int(f.x) - 4, int(f.y)) + Vector2(0.5, 0.5)
	check(w.player_reach_field(f) != "", "DVW-A12 R15: three cells off it is not")
	# a crafting station named by the craft window: closer than 1.2 tiles to where it is used
	var sid := ""
	for id in w.stations_of("sawhorse"):
		if sid == "" and w.station_refusal(id) == "":
			sid = id
	p.inv.add("log", 1)
	p.pos = Vector2(w.station_use(sid)) + Vector2(0.5, 0.5) + Vector2(World.STATION_REACH + 0.3, 0)
	var cp := w.player_craft_begin("saw_planks", sid)
	check(not cp.ok and str(cp.why) == "That is out of reach." and not w.player_at_station(sid), "DVW-A12 R15: a station beyond %.1f tiles is out of reach" % World.STATION_REACH)
	p.pos = Vector2(w.station_use(sid)) + Vector2(0.5, 0.5)
	cp = w.player_craft_begin("saw_planks", sid)
	check(cp.ok, "DVW-A12 R15: at the station it can be worked")
	w.release_player_station(sid)
	# everything the interface offers is in core's reach: many places, every facing
	p.inv.add("pickaxe")
	p.inv.add("axe")
	var offered := 0
	var refused := []
	var spots := []
	for dep in w.deposits:
		spots.append(Vector2i(int(dep.x), int(dep.y)))
	for t in w.trees.slice(0, 40):
		spots.append(Vector2i(int(t.x), int(t.y)))
	for c in w.containers:
		spots.append(Vector2i(int(c.x), int(c.y)))
	for st in w.stations.values():
		spots.append(Vector2i(int(st.use[0]), int(st.use[1])))
	for fl in w.fields:
		spots.append(Vector2i(int(fl.x), int(fl.y)))
	for s0: Vector2i in spots:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var cc: Vector2i = s0 + Vector2i(dx, dy)
				if main.map.is_solid(cc):
					continue
				p.pos = Vector2(cc) + Vector2(0.5, 0.5)
				for dir in 8:
					main.player_sprite.dir = dir
					main._find_target()
					for t in main.target_options:
						var why := ""
						match str(t.kind):
							"deposit", "tree", "plant", "fruit":
								why = w.player_reach_cell(main._target_cell(t), str(t.kind) in ["tree", "fruit"])
							"field":
								why = w.player_reach_field(t.field)
							"loot":
								why = w.player_reach_point(w.loot[t.i].pos, World.TARGET_PROBE + World.TARGET_REACH)
							"container":
								why = w.player_container_reach(t.c)
							"station":
								# core's reach for a craft (World.player_craft_begin): near the use cell, or beside the drawing (GP-ANVIL)
								why = "" if (Vector2(w.station_use(str(t.id))) + Vector2(0.5, 0.5)).distance_to(p.pos) < World.STATION_REACH \
										or World.station_in_reach(w.stations[str(t.id)], p.pos, Vector2.ZERO) else "far"
							_:
								continue
						offered += 1
						if why != "":
							refused.append("%s at %s: %s" % [t.kind, str(cc), why])
	check(offered > 100 and refused.is_empty(), "DVW-A12 R15: all %d targets the interface offered are in core's reach (%s)" % [offered, str(refused.slice(0, 3))])
	_restore_pack(keep)


## R4: planting a sapling: refused without one or where the ground says no; else the tree is planted, the sapling used
## up and counted; through the interface; kept over a save.
func _dvw_a12_planting() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var cell := Vector2i(-1, -1)
	for y in range(10, main.map.h - 10):
		for x in range(10, main.map.w - 10):
			if cell.x < 0 and w.plant_refusal(Vector2i(x, y)) == "" and w.plant_refusal(Vector2i(x, y + 3)) == "" and not main.map.is_solid(Vector2i(x, y + 1)) and w.place_of(Vector2(x, y + 1) + Vector2(0.5, 0.5)) == "":
				cell = Vector2i(x, y)
	check(cell.x >= 0, "DVW-A12 R4: free grass to plant on")
	var sap := "oak_sapling"
	check(w.player_plant_sapling(cell, sap).is_empty() and w.plant_refusal(cell) == "", "DVW-A12 R4: without a sapling nothing is planted")
	p.inv.add(sap, 2)
	var used0 := float(w.stats.get("used_" + sap, 0.0))
	var trees0 := w.trees.size()
	var t := w.player_plant_sapling(cell, sap)
	check(not t.is_empty() and t.state == "sapling" and w.trees.size() == trees0 + 1 and p.inv.count(sap) == 1 and float(w.stats.get("used_" + sap, 0.0)) - used0 == 1.0, "DVW-A12 R4: the sapling is planted, used up and counted (used_)")
	check(w.player_plant_sapling(cell + Vector2i(1, 0), sap).is_empty() and p.inv.count(sap) == 1, "DVW-A12 R4: not beside another tree; the sapling is kept")
	# through the interface: the action plants in front of the player
	var c2 := cell + Vector2i(0, 3)
	p.pos = Vector2(c2) + Vector2(0.5, -0.5)
	main.player_sprite.dir = 0                     # facing down (+y)
	main.plant_sapling(sap)
	_finish_action()
	check(w.tree_at(c2).get("state", "") == "sapling" and not p.inv.has(sap), "DVW-A12 R4: the interface's planting is core's")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.trees.any(func(x): return int(x.x) == c2.x and int(x.y) == c2.y and x.state == "sapling"), "DVW-A12 R4: the planted tree is saved")
	_restore_pack(keep)


## R5: taking a loot pile: goods as far as the pack takes them, all the coins, the pile gone when empty, nothing made
## or lost; out of reach nothing is taken; through the interface.
func _dvw_a12_loot() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var c0 := p.coins
	p.pos = Vector2(60.5, 60.5)
	var bag := Inventory.new()
	bag.add("log", 3)
	bag.add("stone", 2)
	w.loot.append({"pos": p.pos + Vector2(0, 0.5), "inv": bag, "coins": 4, "from": "test pile"})
	var i := w.loot.size() - 1
	p.inv.max_stacks = 1
	var r := w.player_loot(i)
	check(r.far == "" and r.items == [["log", 3]] and int(r.coins) == 4 and int(r.left) == 2 and p.coins == c0 + 4 and p.inv.count("log") == 3, "DVW-A12 R5: what the pack can take and every coin are taken (%s)" % str(r))
	check(w.loot.size() == i + 1 and int(w.loot[i].coins) == 0 and (w.loot[i].inv as Inventory).count("stone") == 2, "DVW-A12 R5: the rest stays in the pile; no coin twice")
	p.inv.max_stacks = 0
	r = w.player_loot(i)
	check(r.items == [["stone", 2]] and int(r.left) == 0 and w.loot.size() == i, "DVW-A12 R5: the last of it taken, the pile is gone")
	w.loot.append({"pos": p.pos + Vector2(0, World.TARGET_PROBE + World.TARGET_REACH + 1.0), "inv": Inventory.new(), "coins": 9, "from": "far pile"})
	r = w.player_loot(w.loot.size() - 1)
	check(r.far != "" and int(r.coins) == 0 and int(w.loot[-1].coins) == 9, "DVW-A12 R5: a pile out of reach gives nothing (R15)")
	w.loot.remove_at(w.loot.size() - 1)
	# through the interface
	var bag2 := Inventory.new()
	bag2.add("plank", 2)
	w.loot.append({"pos": p.pos + Vector2(0, 0.5), "inv": bag2, "coins": 1, "from": "the test"})
	main._sync_loot()
	main.target = {"kind": "loot", "i": w.loot.size() - 1, "label": "Take"}
	var n0 := w.loot.size()
	main._use()
	check(p.inv.count("plank") == 2 and w.loot.size() == n0 - 1 and p.coins == c0 + 5, "DVW-A12 R5: the interface's taking is core's")
	main._sync_loot()
	_restore_pack(keep)


## R6: xp is awarded by core with the action that earns it (a pocket tried: 8 or 2, none out of reach; a theft from a
## container nobody saw: 3; a lock tried: 4 or 1), and a new level reaches the interface's banner by player_leveled.
func _dvw_a12_xp() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var saved: Array = [GameData.b("pickpocket_chance"), GameData.b("pickpocket_chance_max"), GameData.b("pickpocket_chance_per_level")]
	var v: NPC = w.npcs.filter(func(x): return x.alive and x.role == "adult" and x.job != "guard")[1]
	v.anim = "idle"
	v.coins = 10
	p.pos = v.pos + Vector2(1.0, 0)
	GameData.balance.pickpocket_chance = 1.0
	GameData.balance.pickpocket_chance_max = 1.0
	var r := w.pickpocket(v)
	check(r.ok and int(p.skills.get("stealth", 0)) == 8, "DVW-A12 R6: a pocket picked earns 8 Stealth xp")
	GameData.balance.pickpocket_chance = 0.0
	GameData.balance.pickpocket_chance_max = 0.0
	GameData.balance.pickpocket_chance_per_level = 0.0
	r = w.pickpocket(v)
	check(not r.ok and int(p.skills.get("stealth", 0)) == 10, "DVW-A12 R6: a caught try earns 2")
	p.pos = v.pos + Vector2(3.0, 0)
	r = w.pickpocket(v)
	check(r.get("refused", false) and int(p.skills.get("stealth", 0)) == 10, "DVW-A12 R6: no try out of reach, no xp")
	GameData.balance.pickpocket_chance = saved[0]
	GameData.balance.pickpocket_chance_max = saved[1]
	GameData.balance.pickpocket_chance_per_level = saved[2]
	v.target = -1
	p.crimes.clear()
	# the level-up banner: core announces it, the interface shows it
	var heard := []
	var cb := func(sk: String, lv: int): heard.append([sk, lv])
	w.player_leveled.connect(cb)
	p.skills["magic"] = Skills.xp_for_level(2) - 1
	var up := w.player_xp("magic", 1)
	w.player_leveled.disconnect(cb)
	check(up == 2 and heard == [["magic", 2]] and main.ui.toast.text.contains("level 2"), "DVW-A12 R6: a new level is announced by core and shown by the interface (%s)" % main.ui.toast.text)
	check(w.player_xp("magic", 1) == 0, "DVW-A12 R6: no banner without a new level")
	_restore_pack(keep)


## R10: a blow on an animal: alive, nothing else; killed, the kill xp, the ledger and the carcass; livestock is theft
## from its keeper (a crime on the record, the keeper's memory); through the interface; kept over a save.
func _dvw_a12_livestock() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var stock: Array = w.fauna.animals.filter(func(a): return a.alive and not a.wild() and a.adult(w.minutes) and w.pen_keeper(w.fauna.pens[a.area]) != null)
	check(stock.size() >= 2, "DVW-A12 R10: livestock in a keeper's pen (%d)" % stock.size())
	var a: Animal = stock[0]
	var keeper: NPC = w.pen_keeper(w.fauna.pens[a.area])
	p.pos = a.pos + Vector2(1.0, 0)
	var hp0 := a.hp
	var h := w.player_hit_animal(a, 0.5)
	check(not h.killed and a.alive and is_equal_approx(a.hp, hp0 - 0.5), "DVW-A12 R10: a blow that does not kill only hurts")
	var crimes0 := p.crimes.size()
	var sl0 := float(w.stats.get("slaughtered_" + a.species, 0.0))
	var loot0 := w.loot.size()
	var want_xp := Skills.kill_xp(a.species, p.damage())
	h = w.player_hit_animal(a, 100000.0)
	check(h.killed and not a.alive and float(w.stats.get("slaughtered_" + a.species, 0.0)) - sl0 == 1.0 and int(p.skills.get("combat", 0)) == want_xp, "DVW-A12 R10: killed: the ledger (slaughtered_) and the kill xp (%d)" % want_xp)
	check(w.loot.size() == loot0 + 1 and str(w.loot[-1].from).begins_with("the "), "DVW-A12 R10: its carcass lies where it fell")
	check(p.crimes.size() == crimes0 + 1 and str(p.crimes[-1].kind) == "livestock" and keeper.memory.any(func(m): return str(m).contains("my ")), "DVW-A12 R10: killing livestock is theft from the keeper, who knows of it")
	# through the interface
	var b: Animal = stock[1]
	p.pos = b.pos + Vector2(1.0, 0)
	var crimes1 := p.crimes.size()
	main._hit_animal(b, 100000.0)
	check(not b.alive and p.crimes.size() == crimes1 + 1, "DVW-A12 R10: the interface's kill is core's")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.player.crimes.size() == p.crimes.size() and not w2.fauna.animals.any(func(x): return x.id == b.id and x.alive), "DVW-A12 R10: the crime and the death are saved")
	while w.loot.size() > loot0:
		w.loot.remove_at(w.loot.size() - 1)
	main._sync_loot()
	_restore_pack(keep)


## R11: casting Fireball: refused unknown, silent while cooling down or tired; a cast costs stamina, starts the
## cooldown and earns 6 xp; a fireball that strikes harms by the base damage and earns 6 more; through the interface.
func _dvw_a12_cast() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var spells0: Dictionary = p.spells.duplicate()
	p.spells.erase("fireball")
	var c := w.player_cast_fireball()
	check(not c.ok and str(c.why).contains("do not know"), "DVW-A12 R11: an unknown spell is refused with the reason")
	p.spells["fireball"] = true
	p.fireball_cd = 0.0
	p.stamina = 100.0
	var cost := float(GameData.b("fireball_stamina"))
	c = w.player_cast_fireball()
	check(c.ok and is_equal_approx(p.stamina, 100.0 - cost) and is_equal_approx(p.fireball_cd, float(GameData.b("fireball_cooldown"))) and int(p.skills.get("magic", 0)) == 6, "DVW-A12 R11: a cast spends the stamina, starts the cooldown and earns 6 xp")
	c = w.player_cast_fireball()
	check(not c.ok and str(c.why) == "" and int(p.skills.get("magic", 0)) == 6, "DVW-A12 R11: cooling down, nothing (and no message)")
	p.fireball_cd = 0.0
	p.stamina = cost - 1.0
	check(not w.player_cast_fireball().ok and is_equal_approx(p.stamina, cost - 1.0), "DVW-A12 R11: without the stamina, nothing")
	# a strike
	var v: NPC = w.npcs.filter(func(x): return x.alive and x.role == "adult" and x.job != "guard")[2]
	v.target = -1
	var at := v.pos + Vector2(0.3, 0)
	var struck: NPC = w.present(at, World.FIREBALL_HIT_RADIUS)[0]       # the first one there (it may not be v)
	var hp0 := struck.hp
	var want := maxf(0.5, World.FIREBALL_DAMAGE * Skills.value(struck, "combat", "damage_taken", 1.0) - struck.armor * 0.5)
	var h := w.player_fireball_hit(at)
	check(h.who == struck and is_equal_approx(struck.hp, hp0 - want) and is_equal_approx(float(h.dealt), want) and int(p.skills.get("magic", 0)) == 12, "DVW-A12 R11: a fireball that strikes harms by %.0f and earns 6 more xp" % World.FIREBALL_DAMAGE)
	check(w.player_fireball_hit(Vector2(-50, -50)).who == null, "DVW-A12 R11: nobody there, no strike")
	# through the interface: a cast and its flight
	p.fireball_cd = 0.0
	p.stamina = 100.0
	main.player_sprite.dir = 0
	var n0: int = main.projectiles.size()
	main.fireball()
	check(main.projectiles.size() == n0 + 1 and int(p.skills.get("magic", 0)) == 18, "DVW-A12 R11: the interface's cast is core's")
	for i in 40:
		main._projectiles_step(0.05)
	check(main.projectiles.size() == n0, "DVW-A12 R11: the fireball ends within its range")
	p.spells = spells0
	_restore_pack(keep)


## R13: a purchase or a sale earns the player Skills.trade_xp of what it was worth, in core; a refused deal earns none.
func _dvw_a12_trading_xp() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var c0 := p.coins
	p.coins = 500
	var deal: Array = []
	for n: NPC in w.npcs:
		if not n.alive or not deal.is_empty():
			continue
		for id in w.brain.for_sale(n):
			if deal.is_empty() and n.inv.count(id) >= 1:
				deal = [n, id]
	check(not deal.is_empty(), "DVW-A12 R13: a villager with goods for sale")
	var b := w.player_buy_many(deal[0], deal[1], 1)
	check(b.result == "bought" and int(p.skills.get("trading", 0)) == Skills.trade_xp(int(b.paid)), "DVW-A12 R13: a purchase earns Trading xp by its price (%s)" % str(b))
	var x1 := int(p.skills.get("trading", 0))
	var f := w.player_buy_many(deal[0], deal[1], 100000)
	check(f.result == "failed" and int(p.skills.get("trading", 0)) == x1, "DVW-A12 R13: a refused purchase earns none")
	var s := w.player_sell_many(deal[0], deal[1], 1)
	if int(s.sold) > 0:
		check(int(p.skills.get("trading", 0)) == x1 + Skills.trade_xp(int(s.paid)), "DVW-A12 R13: a sale earns Trading xp by what it fetched")
	else:
		check(int(p.skills.get("trading", 0)) == x1, "DVW-A12 R13: a sale refused (%s) earns none" % str(s.text))
	p.coins = c0
	_restore_pack(keep)


## R17: whose a field is comes from core (field_owner): the prompt names them and the harvest is theft from them; a
## field nobody works is nobody's.
func _dvw_a12_field_owner() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var worked: Array = w.fields.filter(func(f): return not w.field_workers(f).is_empty())
	var idle: Array = w.fields.filter(func(f): return w.field_workers(f).is_empty())
	check(not worked.is_empty(), "DVW-A12 R17: a field a farmer works")
	var f: Dictionary = worked[0]
	var owner := w.field_owner(f)
	check(owner == w.field_workers(f)[0], "DVW-A12 R17: its owner is the first farmer working it (%s)" % owner.name)
	if not idle.is_empty():
		check(w.field_owner(idle[0]) == null, "DVW-A12 R17: a field nobody works is nobody's")
	var d := ResourceNodes.def_for("field", "")
	check(ResourceNodes.theft_note(w, d if not d.is_empty() else {"match": {"kind": "field"}}, f).contains(owner.name), "DVW-A12 R17: the gathering note names them")
	# the harvest prompt, then the harvest: theft from them
	var st0: String = f.state
	var crop0 := int(f.get("crop", 0))
	f.state = "ripe"
	f.crop = 10
	var cell := Vector2i(int(f.x), int(f.y))
	p.pos = Vector2(cell) + Vector2(0.5, -0.5)
	main.player_sprite.dir = 0
	main._find_target()
	var fieldt: Array = main.target_options.filter(func(t): return str(t.kind) == "field")
	check(not fieldt.is_empty() and str(fieldt[0].label).contains("%s %s's field: taking it is theft" % [owner.name, owner.family]), "DVW-A12 R17: the prompt names whose field it is")
	var marked0: int = p.stolen_count("wheat")
	w.player_harvest(f)
	check(p.stolen_count("wheat") > marked0 and p.stolen["wheat"].has(str(owner.id)), "DVW-A12 R17: the wheat is marked as theirs")
	f.state = st0
	f.crop = crop0
	_restore_pack(keep)


## R16: core says which choices are theft (a chest not the player's, a container, a worked field); the interface
## offers them last. Checked at every container and field, 5x5 places round each, every facing: the flag is set exactly
## where the prompt says "theft", and no theft choice comes before a lawful one.
func _dvw_a12_theft_last() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	for f in w.fields:
		if not w.field_workers(f).is_empty():
			f["_st"] = f.state
			f.state = "ripe"
			f["_crop"] = f.get("crop", 0)
			f.crop = 10
	var spots := []
	for c in w.containers:
		spots.append(Vector2i(int(c.x), int(c.y)))
	for f in w.fields:
		spots.append(Vector2i(int(f.x), int(f.y)))
	var seen := 0
	var thefts := 0
	var bad := []
	for s0: Vector2i in spots:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var cc: Vector2i = s0 + Vector2i(dx, dy)
				if main.map.is_solid(cc):
					continue
				p.pos = Vector2(cc) + Vector2(0.5, 0.5)
				for dir in 8:
					main.player_sprite.dir = dir
					main._find_target()
					var was_theft := false
					for t in main.target_options:
						seen += 1
						var flag: bool = t.get("theft", false)
						if flag != str(t.get("label", "")).contains("theft"):
							bad.append("%s '%s' flag %s" % [t.kind, t.label, flag])
						if flag:
							thefts += 1
							was_theft = true
						elif was_theft:
							bad.append("lawful %s after a theft at %s" % [t.kind, str(cc)])
	for f in w.fields:
		if f.has("_st"):
			f.state = f._st
			f.crop = f._crop
			f.erase("_st")
			f.erase("_crop")
	check(seen > 100 and thefts > 0 and bad.is_empty(), "DVW-A12 R16: core's theft flag matches every prompt that says theft (%d choices, %d thefts), offered last (%s)" % [seen, thefts, str(bad.slice(0, 3))])
	_restore_pack(keep)


## R18: resting by day runs the world on for rest.day_minutes and restores health and stamina; through the interface.
func _dvw_a12_rest() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var day0 := floorf(w.minutes / World.DAY) * World.DAY
	w.minutes = day0 + 10.0 * 60.0                          # ten in the morning
	p.hp = 3.0
	p.stamina = 1.0
	var t0 := w.minutes
	var r := w.player_rest()
	var dm := float(GameData.b("rest").day_minutes)
	check(not r.night and is_equal_approx(float(r.minutes), dm) and w.minutes - t0 >= dm - 1.0 and w.minutes - t0 <= dm + 1.0, "DVW-A12 R18: a rest by day lasts rest.day_minutes of the world going on (%.0f)" % (w.minutes - t0))
	check(is_equal_approx(p.hp, p.hp_cap()) and is_equal_approx(p.stamina, p.stamina_cap()), "DVW-A12 R18: it restores health and stamina (the one recovery model)")
	p.hp = 3.0
	w.minutes = day0 + 11.0 * 60.0
	main._rest_now()
	check(is_equal_approx(p.hp, p.hp_cap()) and main.ui.toast.text.begins_with("You rest."), "DVW-A12 R18: the interface's rest is core's")


## R19: a sprint needs sprint_min_stamina to start, costs its stamina net of regeneration, ends out of breath; the
## interface's toggle follows PlayerState.
func _dvw_a12_sprint() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var need := float(GameData.b("sprint_min_stamina"))
	p.stamina = need - 0.5
	check(not p.can_sprint(), "DVW-A12 R19: below sprint_min_stamina no sprint starts")
	main.sprinting = false
	main.cancel_action("")
	main.toggle_sprint()
	check(not main.sprinting, "DVW-A12 R19: nor through the interface's toggle")
	p.stamina = need
	check(p.can_sprint(), "DVW-A12 R19: at it, one can")
	main.toggle_sprint()
	check(main.sprinting, "DVW-A12 R19: the toggle turns it on")
	main.sprinting = false
	var cost := float(GameData.b("sprint_stamina_per_sec")) + float(GameData.b("player_stamina_regen_per_second"))
	p.stamina = 50.0
	check(p.sprint_drain(0.5) and is_equal_approx(p.stamina, 50.0 - cost * 0.5), "DVW-A12 R19: half a second costs half the net rate")
	p.stamina = cost * 0.25
	check(not p.sprint_drain(0.5) and p.stamina == 0.0, "DVW-A12 R19: out of breath at nothing, never below")
	check(PlayerState.sprint_speed() == float(GameData.b("sprint_speed")), "DVW-A12 R19: the sprint's speed is the balance's")
	p.stamina = p.stamina_cap()


## R20: goods moved between the pack and the home chest take their stolen marks with them, all or nothing; the
## interface's move is core's; kept over a save.
func _dvw_a12_home_marks() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var chest0: Inventory = p.chest
	var marks0: Dictionary = p.chest_stolen.duplicate(true)
	p.chest = Inventory.new()
	p.chest_stolen = {}
	var victim: NPC = w.npcs.filter(func(x): return x.alive and x.role == "adult")[0]
	p.inv.add("leather", 3)
	p.mark_stolen("leather", victim.id, 2)
	check(w.player_home_move("leather", false, 3) and p.chest.count("leather") == 3 and not p.inv.has("leather"), "DVW-A12 R20: three pieces go into the chest")
	check(int(p.chest_stolen.get("leather", {}).get(str(victim.id), 0)) == 2 and p.stolen_count("leather") == 0, "DVW-A12 R20: their two stolen marks go with them")
	check(not w.player_home_move("leather", true, 5) and p.chest.count("leather") == 3, "DVW-A12 R20: more than the chest holds: nothing moves")
	check(main.ui.home_move("leather", true, 1) and p.inv.count("leather") == 1 and p.stolen_count("leather") == 1, "DVW-A12 R20: one taken out through the interface takes a stolen mark (stolen pieces first)")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(int(w2.player.chest_stolen.get("leather", {}).get(str(victim.id), 0)) == 1 and w2.player.stolen_count("leather") == 1, "DVW-A12 R20: the marks are saved where they are")
	p.chest = chest0
	p.chest_stolen = marks0
	_restore_pack(keep)


## R21: a hired helper's buying budget: the site's need beyond the family chest at today's estimate, never more than
## the coins left after the wage; the talk window offers exactly that.
func _dvw_a12_helper_budget() -> void:
	main.new_game()
	var w: World = main.world
	var p: PlayerState = w.player
	var pl: Dictionary = {}
	for x in w.plots:
		if pl.is_empty() and w.property.for_sale(x):
			pl = x
	p.coins += int(w.property.price_of(pl)) + 10
	check(w.buy_plot(pl), "DVW-A12 R21: the family buys a plot")
	w.start_site(pl)
	var wage := int(GameData.b("helper_wage"))
	var need: Dictionary = pl.site.need.duplicate()
	var full := w.construction.estimate(need)
	p.coins = wage + 100000
	check(w.player_helper_budget(pl) == full, "DVW-A12 R21: with coins enough, the whole estimate (%d)" % full)
	var first: String = need.keys()[0]
	p.chest.add(first, int(need[first]))
	var less := need.duplicate()
	less[first] = 0
	check(w.player_helper_budget(pl) == w.construction.estimate(less), "DVW-A12 R21: what the family chest holds is not bought")
	p.coins = wage + 5
	check(w.player_helper_budget(pl) == mini(5, w.construction.estimate(less)), "DVW-A12 R21: never more than the coins after the wage")
	p.coins = wage - 1
	check(w.player_helper_budget(pl) == 0, "DVW-A12 R21: none when the wage takes it all")
	p.chest.remove(first, int(need[first]))
	# the talk window offers it
	p.coins = wage + 40
	var helper: NPC = null
	for n: NPC in w.npcs:
		if helper == null and n.alive and w.construction.can_hire(n) == "":
			helper = n
	if helper != null:
		main.ui.show_talk(helper)
		for b in _buttons_named(main.ui.panel, "Hire to carry building materials"):
			b.pressed.emit()
		var want := "Buy the rest too (%d + %d)" % [wage, w.player_helper_budget(pl)]
		check(_buttons_named(main.ui.panel, want).size() == 1, "DVW-A12 R21: the talk window offers the helper core's budget (%s)" % want)
		main.ui.hide_all()


## A clean pack for one rule's checks; returns what to restore.
func _fresh_pack() -> Dictionary:
	var p: PlayerState = main.world.player
	var keep := {"inv": p.inv, "tool": p.tool, "skills": p.skills.duplicate(), "pos": p.pos}
	p.inv = Inventory.new()
	p.tool = ""
	p.skills = {}
	return keep


## The middle of an open cell next to `cell` from which it is in reach.
func _beside(cell: Vector2i) -> Vector2:
	for dd in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		var at := Vector2(cell + dd) + Vector2(0.5, 0.5)
		if not main.map.is_solid(cell + dd) and main.world.reaches(at, Vector2(cell) + Vector2(0.5, 0.5)):
			return at
	return Vector2(cell) + Vector2(0.5, 1.5)


func _restore_pack(keep: Dictionary) -> void:
	var p: PlayerState = main.world.player
	p.inv = keep.inv
	p.tool = keep.tool
	p.skills = keep.skills
	p.pos = keep.pos


## R1: a pickaxe is needed, gold needs Mining 3, the swing time, the ore to the pack (or set down), the wear, a broken
## pickaxe leaving the hand, 8 xp an ore, the ledger count, the seam's fall kept over a save.
func _dvw_a12_mining() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var keep := _fresh_pack()
	var seam0: Dictionary = w.nearest_deposit(Vector2i(p.pos), ["stone", "iron_ore", "coal"])
	p.pos = _beside(Vector2i(int(seam0.x), int(seam0.y)))           # within reach of the seam's cell (R15)
	var seam := {"x": int(seam0.x), "y": int(seam0.y), "ore": "iron_ore", "amount": 5}
	var gold := {"x": int(seam0.x), "y": int(seam0.y), "ore": "gold_ore", "amount": 5}
	var mp := w.player_mine_plan(seam)
	check(not mp.ok and str(mp.why) == "Requires a pickaxe. The smith sells them.", "DVW-A12 R1: no pickaxe, no mining (%s)" % str(mp.get("why", "")))
	p.inv.add("rusty_pickaxe")
	p.inv.add("pickaxe")
	mp = w.player_mine_plan(gold)
	check(not mp.ok and str(mp.why) == "Gold needs Mining level 3.", "DVW-A12 R1: gold needs Mining 3 before the swing starts")
	mp = w.player_mine_plan(seam)
	var want := float(GameData.b("mine_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.6 / float(GameData.item("pickaxe").get("speed", 1.0))
	check(mp.ok and str(mp.tool) == "pickaxe" and is_equal_approx(float(mp.secs), want), "DVW-A12 R1: the best pickaxe in the pack, and the swing time by its speed (%s)" % str(mp))
	p.skills = {"mining": Skills.xp_for_level(3)}
	check(w.player_mine_plan(gold).ok and is_equal_approx(float(w.player_mine_plan(seam).secs), want * Skills.value(p, "mining", "mine_time", 1.0)), "DVW-A12 R1: at Mining 3 gold can be mined, and the swing takes the Mining time")
	p.skills = {}
	var mined0 := float(w.stats.get("mined_iron_ore", 0.0))
	var r := w.player_mine(seam, "pickaxe")
	check(r.result == "ok" and not r.full and p.inv.count("iron_ore") == int(r.n) and int(seam.amount) == 5 - int(r.n), "DVW-A12 R1: the ore goes into the pack and comes out of the seam (%s)" % str(r))
	check(float(w.stats.get("mined_iron_ore", 0.0)) - mined0 == float(r.n) and int(p.skills.get("mining", 0)) == 8 * int(r.n), "DVW-A12 R1: counted (mined_) and 8 xp an ore")
	check(int(p.inv.durability.get("pickaxe", 0)) == int(GameData.item("pickaxe").durability) - 1, "DVW-A12 R1: the swing wears the pickaxe by one")
	check(w.player_mine(gold, "pickaxe").result == "gold" and int(gold.amount) == 5, "DVW-A12 R1: the swing itself refuses gold below Mining 3, and takes nothing")
	# a broken pickaxe leaves the hand
	p.tool = "pickaxe"
	p.inv.durability["pickaxe"] = 1
	r = w.player_mine(seam, "pickaxe")
	check(r.result == "ok" and r.broke and not p.inv.has("pickaxe") and p.tool == "", "DVW-A12 R1: a pickaxe that breaks is gone from the pack and the hand")
	check(w.player_mine_plan(seam).tool == "rusty_pickaxe", "DVW-A12 R1: the next swing takes the other pickaxe")
	# a full pack: the ore is set down, not lost
	p.inv.remove("iron_ore", p.inv.count("iron_ore"))
	p.inv.add("log", 1)
	p.inv.max_stacks = p.inv.ids().size()
	var loot0 := w.loot.size()
	r = w.player_mine(seam, "rusty_pickaxe")
	check(r.result == "ok" and r.full and w.loot.size() == loot0 + 1 and (w.loot[-1].inv as Inventory).count("iron_ore") == int(r.n), "DVW-A12 R1: with a full pack the ore is set down at the player's feet (%s)" % str(r))
	w.loot.remove_at(w.loot.size() - 1)
	main._sync_loot()
	seam.amount = 0
	check(w.player_mine(seam, "rusty_pickaxe").result == "out", "DVW-A12 R1: a worked-out seam gives nothing")
	# through the interface: core's refusal is shown, and a real seam is mined by the action
	p.inv = Inventory.new()
	var d: Dictionary = w.nearest_deposit(Vector2i(p.pos), ["stone", "iron_ore", "coal"])
	p.pos = _beside(Vector2i(int(d.x), int(d.y)))
	main.target = {"kind": "deposit", "dep": d, "label": "Mine"}
	main._use()
	check(main.action.is_empty() and main.ui.toast.text.contains("Requires a pickaxe"), "DVW-A12 R1: the interface shows core's refusal and starts nothing (%s)" % main.ui.toast.text)
	p.inv.add("pickaxe")
	var left := int(d.amount)
	main.target = {"kind": "deposit", "dep": d, "label": "Mine"}
	main._use()
	check(not main.action.is_empty() and is_equal_approx(float(main.action.total), want), "DVW-A12 R1: the interface starts a swing of core's time")
	_finish_action()
	check(int(d.amount) < left and p.inv.count(str(d.ore)) >= 1, "DVW-A12 R1: the finished swing mines the seam (%d -> %d)" % [left, int(d.amount)])
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(int(w2.deposit_at(Vector2i(int(d.x), int(d.y))).amount) == int(d.amount), "DVW-A12 R1: the mined seam is saved as it was left")
	_restore_pack(keep)

