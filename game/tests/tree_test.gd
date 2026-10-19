extends SceneTree
## The tree lifecycle in the real game scene, and only that (a focused check, about half a minute):
## chop a mature tree for wood (cut marks, the fall, a stump, no second harvest), let it regrow
## through its stages and chop it again, leave and come back (its chunk unloaded) and save and load,
## and collision and routes round trees. Run headless:
##   godot --headless --path game --script res://tests/tree_test.gd

var failures := 0
var checks := 0
var main
const TEST_SAVE := "user://test_saves/tree_test/save1.json"


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


## Bring a tree up to the clock and the view with it, as the game's twice-a-second poll does.
func _grow(w: World, t: Dictionary, minutes: float) -> void:
	w.minutes = minutes
	w.sync_tree(t)
	main.tree_view.update(w.player.pos, 0.6)


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var m: VillageMap = main.map
	var p: PlayerState = w.player
	var chops := int(Trees.cfg().chops)
	p.inv.add("axe")
	# a mature village tree with free ground to its west to stand on, and free ground to its east
	var tree := {}
	for t in w.trees:
		var c := Vector2i(int(t.x), int(t.y))
		if t.state == "grown" and c.x > 2 and not m.is_solid(c + Vector2i(-1, 0)) and not m.is_solid(c + Vector2i(1, 0)) \
				and w.place_of(Vector2(c) + Vector2(-0.5, 0.5)) == "" and not w._someone_on(c + Vector2i(-1, 0)):
			tree = t
			break
	check(not tree.is_empty(), "a mature village tree with free ground beside it")
	var cell := Vector2i(int(tree.x), int(tree.y))
	var tn: TreeView.TreeNode = main.tree_view.node_at(cell)
	check(tn != null and tn.drawn == "grown" and tn.texture != null, "it is drawn with its mature sprite (%s)" % tree.get("species", "?"))
	check(m.is_solid(cell), "its trunk is solid")

	# 4. collision and routes: the trunk blocks the player and villagers' routes; the canopy does not
	p.pos = Vector2(cell) + Vector2(-0.5, 0.5)
	var before := p.pos
	check(not main._try_move(Vector2(0.4, 0)) and p.pos == before, "walking into the trunk is blocked")
	var route := m.find_path(cell + Vector2i(-1, 0), cell + Vector2i(1, 0))
	check(route.size() > 2 and not route.has(Vector2(cell)), "a villager's route goes round the trunk (%d steps)" % route.size())

	# 1. chop it with the player's own action: a cut mark after the first blow, then the fall, logs, a stump
	var felled := []
	w.tree_felled.connect(func(t, side): felled.append(t), CONNECT_ONE_SHOT)
	p.pos = Vector2(cell) + Vector2(-0.5, 0.5)
	main.player_sprite.face(Vector2(1, 0))
	main._find_target()
	check(main.target.get("kind", "") == "tree", "Use offers the tree: \"%s\"" % main.target.get("label", ""))
	var logs0 := p.inv.count("log")
	var kids0: int = main.tree_view.get_child_count()
	main._use()
	var guard := 0
	while main.action.is_empty() == false and w.tree_hits(cell) == 0 and guard < 400:
		main._player_step(0.05)
		guard += 1
	check(w.tree_hits(cell) == 1 and tn.hits == 1 and tn.cuts != null and main.tree_view.get_child_count() > kids0,
			"the first blow leaves a cut mark and throws chips (%d hits)" % w.tree_hits(cell))
	check(p.inv.count("log") == logs0, "and gives no wood yet")
	_finish_action()
	var got := p.inv.count("log") - logs0
	check(got >= 4 and tree.state == "stump" and felled.size() == 1, "after %d blows it falls: %d logs, a stump" % [chops, got])
	check(tn.drawn == "stump" and tn.cuts == null and not m.is_solid(cell), "drawn as a stump, which is not solid")
	var gains: Array = main.ui.log_texts()
	check(gains.has("+%d %s" % [got, GameData.item_name("log")]) and not main.ui.toast.text.contains("log"), "the wood is a short line in the corner: %s" % [gains])
	# no second harvest
	check(w.fell(tree, 0) == 0 and w.chop_tree(tree, 1, 0).logs == 0, "a stump gives no more wood")
	main._find_target()
	var logs1 := p.inv.count("log")
	if main.target.get("kind", "") == "tree":
		main._use()
		_finish_action()
	check(p.inv.count("log") == logs1, "using the stump again gives nothing")
	p.pos = Vector2(cell) + Vector2(-0.5, 0.5)
	check(main._try_move(Vector2(0.6, 0)), "the player walks over the stump")

	# 2. it regrows by the clock through every stage, solid only once its trunk has grown, then is felled again
	var regrow_at := float(tree.regrow) * Trees.DAY
	p.pos = Vector2(cell) + Vector2(-3.5, 0.5)                     # nobody stands on it while it grows
	_grow(w, tree, regrow_at - 1.0)
	check(tree.state == "stump", "before its day it stays a stump")
	var at := regrow_at + 1.0
	_grow(w, tree, at)
	check(tree.state == "sapling" and tn.drawn == "sapling" and not m.is_solid(cell), "then a sapling, drawn so, not solid")
	at += Trees.stage_minutes("sapling")
	_grow(w, tree, at)
	check(tree.state == "young" and tn.drawn == "young" and not m.is_solid(cell), "then a young tree, not solid")
	at += Trees.stage_minutes("young")
	_grow(w, tree, at)
	check(tree.state == "growing" and tn.drawn == "growing" and m.is_solid(cell), "then a growing tree with a solid trunk")
	at += Trees.stage_minutes("growing")
	_grow(w, tree, at)
	check(tree.state == "grown" and tn.drawn == "grown" and m.is_solid(cell), "then mature again")
	var logs2 := 0
	for k in chops:
		logs2 += int(w.chop_tree(tree, -1, 0).logs)
	check(logs2 >= 4 and tree.state == "stump", "and felled again for wood (%d logs)" % logs2)

	# a tree never turns solid under someone: a young tree due to grow waits while the player stands there
	at = float(tree.regrow) * Trees.DAY + Trees.stage_minutes("sapling") + 1.0
	_grow(w, tree, at)
	check(tree.state == "young", "regrown to a young tree")
	p.pos = Vector2(cell) + Vector2(0.5, 0.5)
	_grow(w, tree, at + Trees.stage_minutes("young") + 1.0)
	check(tree.state == "young" and not m.is_solid(cell), "it does not become solid with the player on it")
	p.pos = Vector2(cell) + Vector2(-3.5, 0.5)
	_grow(w, tree, w.minutes + 1.0)
	check(tree.state == "growing" and m.is_solid(cell), "and grows once they step away")

	# 3. outside the village: fell a tree, leave until its chunk unloads, come back, save and load
	var o: Overworld = m.overworld
	var west: Vector2i = m.exits()[3].out
	var ot := {}
	for r in range(3, 40):
		for dy in range(-r, r + 1):
			var sc := west + Vector2i(-r, dy)
			var cand := w.tree_at(sc)
			if ot.is_empty() and not cand.is_empty() and cand.state == "grown" and Vector2i(int(cand.x), int(cand.y)) == sc:
				ot = cand
	check(not ot.is_empty(), "a mature tree outside the village")
	var oc := Vector2i(int(ot.x), int(ot.y))
	p.pos = Vector2(oc) + Vector2(-0.5, 0.5)
	main.camera.position = p.pos * 16.0
	main.ow_view.follow(p.pos, p.pos, 0.1, -1)
	check(main.tree_view.node_at(oc) != null and main.tree_view.node_at(oc).drawn == "grown", "drawn as a mature tree")
	var ologs := 0
	for k in chops:
		ologs += int(w.chop_tree(ot, -1, 0).logs)
	check(ologs >= 4 and not o.is_solid(oc) and main.tree_view.node_at(oc).drawn == "stump", "felled for %d logs: a stump, not solid" % ologs)
	var far := Vector2(oc) + Vector2(400.5, 0.5)
	p.pos = far
	main.camera.position = far * 16.0
	main.ow_view.follow(far, far, 0.1, -1)
	check(main.tree_view.node_at(oc) == null and not main.ow_view.chunks.has(Overworld.chunk_of(oc)), "far away its chunk is unloaded")
	p.pos = Vector2(oc) + Vector2(-0.5, 0.5)
	main.camera.position = p.pos * 16.0
	main.ow_view.follow(p.pos, p.pos, 0.1, -1)
	check(main.tree_view.node_at(oc) != null and main.tree_view.node_at(oc).drawn == "stump" and w.tree_at(oc).state == "stump",
			"back again it is still a stump (not a new tree)")
	check(w.chop_tree(w.tree_at(oc), -1, 0).logs == 0, "and gives no more wood")
	var village_state := str(tree.state)
	check(main.save_game(false), "the game saves")
	main.continue_game()
	var w2: World = main.world
	main.ow_view.follow(w2.player.pos, w2.player.pos, 0.1, -1)
	var vt := w2.tree_at(cell)
	check(not vt.is_empty() and vt.state == village_state and w2.map.is_solid(cell) == Trees.solid(village_state),
			"after loading the village tree is as it was (%s)" % vt.get("state", "?"))
	var ot2 := w2.tree_at(oc)
	check(not ot2.is_empty() and ot2.state == "stump" and not w2.map.overworld.is_solid(oc), "and the felled tree outside is still a stump")
	var n2: TreeView.TreeNode = main.tree_view.node_at(oc)
	check(n2 != null and n2.drawn == "stump", "drawn as a stump after loading")
	# every village tree is a lifecycle tree of the pack's species
	var species := {}
	var bad := 0
	for t in w2.trees:
		if t.state == "cleared":
			continue
		species[t.get("species", "")] = true
		if Trees.variant(str(t.get("species", ""))).is_empty():
			bad += 1
	check(bad == 0 and species.size() >= 3, "every village tree has a Living Forest species (%s)" % [species.keys()])
	_overworld_trees(w2)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Living Forest trees in the overworld (B8-005, B8-003): no tree tiles in the overworld's layers, one
## sprite per tree after crossing chunks back and forth, trunks collide and canopies do not, a canopy
## fades over the player behind it and the tree can still be harvested, drawn in the characters' order.
func _overworld_trees(w: World) -> void:
	var o: Overworld = w.map.overworld
	var tv: TreeView = main.tree_view
	var east: Vector2i = w.map.exits()[1].out
	var start := Vector2(east) + Vector2(0.5, 0.5)
	# the tiles drawn: no trunk, canopy or bottom tile of any tree kind in any chunk layer
	var tree_tiles := {}
	for k in o.tiles.trees:
		tree_tiles[int(k.trunk)] = true
		tree_tiles[int(k.top)] = true
		tree_tiles[int(k.bottom)] = true
	w.player.pos = start
	main.camera.position = start * 16.0
	main.ow_view.follow(start, start, 0.1, -1)
	var drawn := 0
	var stray := 0
	for cc in main.ow_view.chunks:
		var layers: Dictionary = main.ow_view.chunks[cc]
		for key in ["ground", "path", "objects", "tops"]:
			var l: TileMapLayer = layers[key]
			for cell in l.get_used_cells():
				drawn += 1
				if tree_tiles.has(main.ow_view.tile_value(l, cell) % 100000):
					stray += 1
	check(drawn > 1000 and stray == 0, "no tree tile is drawn in the overworld's layers (%d tiles looked at)" % drawn)
	var tops := 0
	for cc in main.ow_view.chunks:
		tops += (main.ow_view.chunks[cc].tops as TileMapLayer).get_used_cells().size()
	check(tops == 0, "and nothing stands in the canopy layers (%d)" % tops)
	# cross several chunks and come back: one sprite per tree, none for an unloaded chunk, none half drawn
	var bad_dup := 0
	var bad_orphan := 0
	var bad_tex := 0
	var seen := 0
	for step in [0, 1, 2, 3, 4, 3, 2, 1, 0, -1, 0]:
		var at := start + Vector2(step * 33.0, step * 11.0)
		main.camera.position = at * 16.0
		w.player.pos = at
		main.ow_view.follow(at, at, 0.1, -1)
		tv.update(at, 0.05)
		var want := {}
		for cc in main.ow_view.chunks:
			for t in o.chunk_trees(cc):
				want[Vector2i(int(t.x), int(t.y))] = true
		var kids := 0
		for c in tv.get_children():
			if c is TreeView.TreeNode and not c.is_queued_for_deletion():
				kids += 1
		for cell in want:
			var n: TreeView.TreeNode = tv.node_at(cell)
			if n == null:
				bad_orphan += 1
			elif n.texture == null or n.position != TreeView.base_of(n.rec):
				bad_tex += 1
		for cell in tv.nodes:
			if not want.has(cell) and not w.trees.any(func(t): return Vector2i(int(t.x), int(t.y)) == cell):
				bad_orphan += 1
		if kids != tv.nodes.size():
			bad_dup += 1
		seen += want.size()
	check(seen > 500 and bad_dup == 0 and bad_orphan == 0 and bad_tex == 0,
			"after crossing chunks there is one whole sprite per tree and none left behind (%d trees seen; duplicates %d, missing or stale %d, unfinished %d)" % [seen, bad_dup, bad_orphan, bad_tex])
	# a mature overworld tree: trunk solid, canopy cell open, canopy fades over the player behind it,
	# the tree still harvestable and drawn after the player when they stand south of it
	main.camera.position = start * 16.0
	w.player.pos = start
	main.ow_view.follow(start, start, 0.1, -1)
	var tree := {}
	for cc in main.ow_view.chunks:
		for t in o.chunk_trees(cc):
			var c := Vector2i(int(t.x), int(t.y))
			if tree.is_empty() and t.state == "grown" and not o.is_solid(c + Vector2i(0, -1)) and not o.is_solid(c + Vector2i(0, 1)) \
					and not o.is_solid(c + Vector2i(0, -2)) and not o.is_road(c) and o.chunk_in_village(cc) == false:
				tree = t
	check(not tree.is_empty(), "a mature tree outside the village with open ground north and south of it")
	var cell := Vector2i(int(tree.x), int(tree.y))
	var n: TreeView.TreeNode = tv.node_at(cell)
	check(o.is_solid(cell) and not o.is_solid(cell + Vector2i(0, -1)), "its trunk blocks and its canopy cell does not")
	w.player.inv.add("axe")
	var behind := Vector2(cell) + Vector2(0.5, -0.4)              # north of the trunk, under the canopy
	w.player.pos = behind
	for k in 12:
		tv.update(behind, 0.1)
	check(n.alpha_to < 1.0 and n.modulate.a <= TreeView.FADE_ALPHA + 0.01, "the canopy fades while the player is behind it (alpha %.2f)" % n.modulate.a)
	var found := ResourceNodes.node_at(w, cell, true)
	check(not found.is_empty() and found.def.id == "tree" and ResourceNodes.can_harvest(w, found.def, found.ref) == "" and w.tree_at(cell + Vector2i(0, -1)).get("x", -1) == cell.x,
			"the faded tree is still harvestable, trunk and canopy cell alike")
	var logs := 0
	for k in int(Trees.cfg().chops):
		logs += int(w.chop_tree(w.tree_at(cell), 1, 0).logs)
	check(logs >= 4, "and gives its logs through the fade (%d)" % logs)
	for k in 12:
		tv.update(Vector2(cell) + Vector2(4.5, 3.5), 0.1)
	check(n.modulate.a >= 0.99, "the canopy is back to full when the player leaves")
	check(main.actors.y_sort_enabled and tv.get_parent() == main.actors and tv.y_sort_enabled, "trees sit in the characters' y-sorted layer")
	var south := Vector2(cell) + Vector2(0.5, 1.6)
	check(south.y * 16.0 > n.position.y and Vector2(cell).y * 16.0 + 14.0 == n.position.y, "a player south of the trunk sorts after it (in front), north before it (behind)")

