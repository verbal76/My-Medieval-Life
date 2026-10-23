extends SceneTree
## B14-07 (cliff steps cut with a pickaxe and Mining; wooden stairs and walkways of planks and nails with Crafting and a
## mallet) and DVW-A10 (no black holes: whatever can be entered can be left). A mountain top is out of reach until a way
## is made through its rim; the way runs both ways; it needs the tool, the skill, the materials and the stamina, and uses
## them by the existing rules; it is saved; a top's felled tree never grows back; no way runs from ground to ground; the
## village has no open cell nobody can walk to.
##   godot --headless --path game --script res://tests/terrain_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	test_village_has_no_pockets()
	var w := new_world()
	var sites := find_sites(w, 3)
	check(sites.size() >= 2, "mountains with a rim to climb are found near the village (%d)" % sites.size())
	if sites.size() >= 2:
		test_steps(w, sites[0])
		test_stairs(w, sites[1])
		test_save(w, sites[0])
		test_top_trees(w, sites[0])
	test_walkway()
	test_items()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


## Up to `n` places to climb (in scan order, from the chunks round the village): {from (open ground beside the rim),
## dir, span}, each on a different mountain top.
func find_sites(w: World, n: int, kind := "steps") -> Array:
	var o: Overworld = w.map.overworld
	var out := []
	var tops := {}
	for r in range(2, 9):
		for cy in range(-r, r + 1):
			for cx in range(-r, r + 1):
				if maxi(absi(cx), absi(cy)) != r:
					continue
				var ch := o.get_chunk(Vector2i(cx, cy))
				for i in Overworld.CHUNK * Overworld.CHUNK:
					var c := Vector2i(cx * Overworld.CHUNK + i % Overworld.CHUNK, cy * Overworld.CHUNK + i / Overworld.CHUNK)
					if not o.is_rim(c):
						continue
					for d: Vector2i in Terrain.DIRS:
						var from := c - d
						var s := Terrain.span(o, from, d)
						if s.is_empty() or str(s.kind) != kind or (kind == "steps" and bool(s.from_top)):
							continue
						var key := _region_key(w, s.to)
						if tops.has(key):
							continue
						tops[key] = true
						out.append({"from": from, "dir": d, "span": s})
						if out.size() >= n:
							return out
	return out


## A key for the top region a cell is on (its smallest reachable cell within 12 tiles), so sites are on different tops.
func _region_key(w: World, c: Vector2i) -> Vector2i:
	var best := c
	for k: Vector2i in Terrain.reachable(w, c, 12):
		if k.y < best.y or (k.y == best.y and k.x < best.x):
			best = k
	return best


func stand(w: World, at: Vector2i) -> PlayerState:
	var p := w.player
	p.pos = Vector2(at) + Vector2(0.5, 0.5)
	p.stamina = 100.0
	return p


func _target(w: World, p: PlayerState, c: Vector2i, what: String) -> Dictionary:
	for t in w.farm.targets_at(c, p):
		if str(t.get("what", "")) == what:
			return t
	return {}


func test_steps(w: World, site: Dictionary) -> void:
	var o: Overworld = w.map.overworld
	var from: Vector2i = site.from
	var top: Vector2i = site.span.to
	var rim: Vector2i = from + site.dir
	check(not Terrain.reachable(w, from, 30).has(top), "a mountain top is out of reach from the ground beside it")
	var p := stand(w, from)
	for id in p.inv.ids():
		if str(GameData.item(id).get("tool", "")) == "pickaxe":
			p.inv.items.erase(id)
	var t := _target(w, p, rim, "steps")
	check(not t.is_empty() and str(t.label).contains("Cut steps up the cliff") and str(t.label).contains("pickaxe") and bool(t.low),
		"facing the rim, \"Cut steps\" is offered with what it needs: \"%s\"" % str(t.get("label", "")))
	p.inv.add("pickaxe")
	check(str(_target(w, p, rim, "steps").label).contains("Mining level 2"), "a pickaxe is not enough: Mining 2 is needed")
	p.raise_to("mining", 2)
	t = _target(w, p, rim, "steps")
	check(not bool(t.low) and not str(t.label).contains("need"), "with a pickaxe and Mining 2 it can be done: \"%s\"" % str(t.label))
	var plan: Dictionary = w.farm.plan(t, p)
	check(bool(plan.ok) and float(plan.secs) > 0.0, "it takes time (%.0f s)" % float(plan.get("secs", 0)))
	var xp0 := int(p.skills.get("mining", 0))
	var st0 := p.stamina
	var said := str(plan.run.call().text)
	check(said.contains("steps"), "the steps are cut: \"%s\"" % said)
	for c in site.span.cells:
		check(o.works.has(c) and not o.is_solid(c) and Terrain.work_at(w, c) == "steps", "rim cell %s is steps now" % [c])
	check(p.stamina < st0 and int(p.skills.get("mining", 0)) > xp0 and int(p.inv.durability.get("pickaxe", 120)) < 120, "stamina spent, Mining learned, the pickaxe worn")
	var up := Terrain.reachable(w, from, 30)
	var down := Terrain.reachable(w, top, 30)
	check(up.has(top) and down.has(from), "the top is reached by the steps, and left by them (no black hole)")
	check(Terrain.span(o, from, site.dir).is_empty(), "the rim is open there: nothing more to cut")


func test_stairs(w: World, site: Dictionary) -> void:
	var o: Overworld = w.map.overworld
	var from: Vector2i = site.from
	var rim: Vector2i = from + site.dir
	var n: int = (site.span.cells as Array).size()
	var p := stand(w, from)
	p.inv.items.erase("plank")
	p.inv.items.erase("nails")
	p.inv.add("mallet")
	p.raise_to("carpentry", 2)
	var t := _target(w, p, rim, "stairs")
	check(str(t.label).contains("You need %d planks" % (3 * n)), "stairs need planks: \"%s\"" % str(t.label))
	p.inv.add("plank", 3 * n)
	p.inv.add("nails", 4 * n)
	var used0 := float(w.stats.get("used_plank", 0.0))
	t = _target(w, p, rim, "stairs")
	var plan: Dictionary = w.farm.plan(t, p)
	check(bool(plan.ok), "with a mallet, Carpentry 2, %d planks and %d nails the stairs can be built" % [3 * n, 4 * n])
	plan.run.call()
	check(not p.inv.has("plank") and not p.inv.has("nails") and float(w.stats.get("used_plank", 0.0)) - used0 == 3.0 * n,
		"the planks and nails are used up and counted (used_plank, the goods ledger)")
	check(Terrain.work_at(w, rim) == "stairs" and Terrain.reachable(w, from, 30).has(site.span.to) and Terrain.reachable(w, site.span.to, 30).has(from),
		"wooden stairs lead up, and down again")
	check(str(o.works[rim]).ends_with("_ns") == (site.dir.x == 0), "the stairs run the way they were built (%s)" % str(o.works[rim]))


func test_save(w: World, site: Dictionary) -> void:
	var rim: Vector2i = site.from + site.dir
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.map.overworld.works.size() == w.map.overworld.works.size() and not w2.map.overworld.is_solid(rim), "the ways are saved and loaded")
	var d := w.to_dict()
	d.overworld.erase("works")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w3.map.overworld.works.is_empty() and w3.map.overworld.is_solid(rim), "an older save loads with no ways (its tops out of reach as they were)")


## DVW-A10: a felled tree on a mountain top never grows back, so no way across a top closes behind anyone.
func test_top_trees(w: World, site: Dictionary) -> void:
	var o: Overworld = w.map.overworld
	var tree := {}
	for c: Vector2i in Terrain.reachable(w, site.span.to, 12):
		for d: Vector2i in Terrain.DIRS:
			var t := o.tree_at(c + d)
			if not t.is_empty() and o.is_top(c + d) and str(t.state) == "grown" and o.is_solid(c + d):
				tree = t
				break
		if not tree.is_empty():
			break
	if tree.is_empty():
		print("     (no grown tree on that top within reach: skipped)")
		return
	var cell := Vector2i(int(tree.x), int(tree.y))
	check(w.fell(tree, 0) > 0 and not o.is_solid(cell), "a top's tree can be felled, and its cell opens")
	w.minutes += 3.0 * 365.0 * World.DAY
	o.clock = w.minutes
	var again := o.tree_at(cell)
	check(not o.is_solid(cell) and str(again.get("state", "")) != "grown", "years later it has not grown back (%s)" % str(again.get("state", "")))


func test_walkway() -> void:
	for seed in [1, 2, 3]:
		var w := new_world(seed)
		var sites := find_sites(w, 1, "walkway")
		if sites.is_empty():
			continue
		var s: Dictionary = sites[0]
		var from: Vector2i = s.from
		var o: Overworld = w.map.overworld
		# stand on the first top: it is reached first by steps cut somewhere is not needed for the rule; place the player there
		var p := stand(w, from)
		p.inv.add("mallet")
		p.raise_to("carpentry", 2)
		var n: int = (s.span.cells as Array).size()
		p.inv.add("plank", 2 * n)
		p.inv.add("nails", 3 * n)
		check(o.is_top(from) and o.is_top(s.span.to), "two tops face each other across the rim (seed %d)" % seed)
		var t := _target(w, p, from + s.dir, "walkway")
		check(not t.is_empty() and _target(w, p, from + s.dir, "steps").is_empty(), "between tops a walkway is offered, not steps")
		var plan: Dictionary = w.farm.plan(t, p)
		check(bool(plan.ok), "with a mallet, Carpentry 2 and the materials it can be built")
		plan.run.call()
		check(Terrain.work_at(w, from + s.dir) == "walkway" and Terrain.reachable(w, from, 20).has(s.span.to) and Terrain.reachable(w, s.span.to, 20).has(from),
			"the walkway joins the two tops, both ways")
		return
	print("     (no two tops face each other across a thin rim near the village for seeds 1-3: walkway test skipped)")


## DVW-A10 in the village: every open cell can be walked to from the player's start (the map's pockets are sealed on load).
func test_village_has_no_pockets() -> void:
	var m := VillageMap.load_default()
	var sp = m.data.spawns.player
	var start := Vector2i(int(sp[0]), int(sp[1]))
	var seen := {start: true}
	var q := [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d: Vector2i in Terrain.DIRS:
			var n := c + d
			if not seen.has(n) and not m.is_solid(n):
				seen[n] = true
				q.append(n)
	var lost := 0
	for y in m.h:
		for x in m.w:
			if not m.is_solid(Vector2i(x, y)) and not seen.has(Vector2i(x, y)):
				lost += 1
	check(lost == 0, "every open cell of the village can be walked to from the start (%d sealed on load: %s)" % [m.sealed.size(), str(m.sealed)])
	check(Terrain.span(null, start, Vector2i(1, 0)).is_empty(), "no way without a world outside")


func test_items() -> void:
	var w := new_world()
	var p := w.player
	p.inv.add("iron_bar", 1)
	p.raise_to("smithing", 1)
	var n0 := p.inv.count("nails")
	check(str(w.work_craft(p, "forge_nails", p.inv).result) == "ok" and p.inv.count("nails") >= n0 + 12, "an iron bar is forged into a dozen nails at the anvil")
	p.inv.add("log", 1)
	p.inv.add("plank", 1)
	check(str(w.work_craft(p, "make_mallet", p.inv).result) == "ok" and p.tool_of("mallet") == "mallet", "a log and a plank make a mallet at the workbench")
	check(FileAccess.file_exists("res://assets/icons/nails.png") and FileAccess.file_exists("res://assets/icons/mallet.png"), "nails and the mallet have icons")
	for f in ["steps", "stairs_ns", "stairs_ew", "walkway_ns", "walkway_ew"]:
		check(ResourceLoader.exists("res://assets/terrain/%s.png" % f), "the %s tile is imported" % f)
