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
	var gains: Array = main.ui.log_box.get_children().map(func(c): return c.text)
	check(gains.has("+%d logs" % got) and not main.ui.toast.text.contains("logs"), "the wood is a short line in the corner: %s" % [gains])
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
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
