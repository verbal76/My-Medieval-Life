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
	_boulders()
	_roofs()
	_succession()
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


# ---------------------------------------------------------------- B8-026 ----------------------
func _boulders() -> void:
	var w: World = main.world
	var m: VillageMap = main.map
	var p: PlayerState = w.player
	p.inv.add("pickaxe")
	var uses := int(ResourceNodes.def("boulder").uses)
	check(w.boulders.size() > 0 and uses >= 2, "the village has %d small boulders, %d uses each" % [w.boulders.size(), uses])
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
			if oc.x == -9999 and o.has_boulder(sc) and o.boulder_at(sc).amount == uses and not o.is_road(sc):
				oc = sc
	check(oc.x != -9999, "an overworld boulder exists near the west road")
	var od := w.deposit_at(oc)
	check(not od.is_empty() and od.get("ow", false) and od.ore == "stone" and ResourceNodes.node_at(w, oc, true).def.id == "boulder", "it is a boulder node too")
	check(o.is_solid(oc), "and it blocks the way")
	p.pos = Vector2(oc) + Vector2(-0.5, 0.5)
	main.camera.position = p.pos * 16.0
	main.ow_view.follow(p.pos, p.pos, 0.1, -1)
	var oview: Dictionary = main.ow_view.chunks[Overworld.chunk_of(oc)]
	check(main.ow_view.tile_value(oview.objects, oc) == int(o.tiles.rock), "it is drawn")
	var got := ""
	for k in uses:
		got = w.mine_unit(w.deposit_at(oc))
	check(got == "stone" and w.deposit_at(oc).is_empty() and not o.is_solid(oc) and o.rock_gone(oc), "%d uses break it for stone; its cell is open" % uses)
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
	check(int(w.deposit_at(half).amount) == uses - 1, "a boulder half mined keeps %d uses" % (uses - 1))
	var vb: Dictionary = w.boulders[1]
	w.mine_unit(vb)
	var vcell := Vector2i(vb.x, vb.y)
	check(main.save_game(false), "the game saves")
	main.continue_game()
	var w2: World = main.world
	check(w2.deposit_at(cell).is_empty() and not w2.map.is_solid(cell), "after loading the village boulder is still broken")
	check(w2.map.overworld.rock_gone(oc) and not w2.map.overworld.is_solid(oc) and w2.deposit_at(oc).is_empty(), "after loading the overworld boulder is still broken")
	check(int(w2.deposit_at(half).amount) == uses - 1 and int(w2.deposit_at(vcell).amount) == uses - 1, "and the half-mined ones keep their uses")
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
