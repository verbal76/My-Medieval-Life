extends SceneTree
## The overworld (B8-011): deterministic chunks, roads without seams, a world you can walk across,
## regions, collision, streaming, felled trees and saves. The first half needs no scene; the second
## drives the real game scene. Run headless:
##   godot --headless --path game --script res://tests/overworld_test.gd

var failures := 0
var checks := 0
var main
const TEST_SAVE := "user://test_saves/overworld_test/save1.json"


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var tp := Time.get_ticks_msec()
	_test_determinism()
	print("determinism ", Time.get_ticks_msec() - tp); tp = Time.get_ticks_msec()
	_test_roads()
	print("roads ", Time.get_ticks_msec() - tp); tp = Time.get_ticks_msec()
	_test_traversable(1)
	_test_traversable(2)
	print("traversable ", Time.get_ticks_msec() - tp); tp = Time.get_ticks_msec()
	_test_roads_reachable()
	print("reachable ", Time.get_ticks_msec() - tp); tp = Time.get_ticks_msec()
	_test_regions()
	print("overworld core tests took ", Time.get_ticks_msec() - t0, " ms")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = TEST_SAVE
	process_frame.connect(_run_scene, CONNECT_ONE_SHOT)


func _world(seed_value: int) -> Overworld:
	return Overworld.create(seed_value, VillageMap.load_default())


func _fingerprint(ch: Overworld.Chunk) -> int:
	return hash([ch.ground, ch.path, ch.deco, ch.solid, ch.kind, ch.trees, ch.road])


# ---------------------------------------------------------------- core ----------------------
func _test_determinism() -> void:
	var a := _world(1)
	var b := _world(1)
	var coords := [Vector2i(5, -3), Vector2i(-7, 4), Vector2i(0, 3), Vector2i(12, 12), Vector2i(-1, -1), Vector2i(3, 2)]
	var first := []
	for c in coords:
		first.append(_fingerprint(a.get_chunk(c)))
	for k in coords.size():
		check(_fingerprint(b.get_chunk(coords[k])) == first[k], "chunk %s: a second world of the same seed generates it identically" % [coords[k]])
	# evict everything (far more chunks than the cache keeps), then ask again
	var n0 := a.generated
	for y in range(40, 40 + 14):
		for x in range(40, 40 + 14):
			a.get_chunk(Vector2i(x, y))
	check(a.cache.size() <= Overworld.MAX_CACHED, "the chunk cache is bounded (%d <= %d)" % [a.cache.size(), Overworld.MAX_CACHED])
	check(not a.cache.has(coords[0]), "the first chunk was evicted")
	for k in coords.size():
		check(_fingerprint(a.get_chunk(coords[k])) == first[k], "chunk %s is identical after eviction" % [coords[k]])
	check(a.generated > n0, "evicted chunks were generated again")
	var c := _world(2)
	var differ := 0
	for k in coords.size():
		if _fingerprint(c.get_chunk(coords[k])) != first[k]:
			differ += 1
	check(differ == coords.size(), "a different seed gives different chunks (%d of %d)" % [differ, coords.size()])
	# nothing is generated again for a chunk that is cached
	var g := a.generated
	for i in 32:
		a.is_solid(Vector2i(53 * 32 + i, 53 * 32 + 3))
	check(a.generated == g, "asking for the cells of a cached chunk generates nothing")
	# the village is not the overworld's
	check(not a.is_solid(Vector2i(50, 50)) and not a.is_road(Vector2i(50, 50)), "inside the village the overworld holds nothing")
	var ms := Time.get_ticks_msec()
	var w := _world(3)
	for y in 6:
		for x in 6:
			w.get_chunk(Vector2i(20 + x, 20 + y))
	var per := float(Time.get_ticks_msec() - ms) / 36.0
	print("chunk generation: %.1f ms each" % per)
	check(per < 400.0, "a chunk generates in well under half a second (%.0f ms)" % per)


func _test_roads() -> void:
	var o := _world(1)
	# seams: a chunk's padded road mask agrees with its neighbours' own, so roads cross unbroken
	var agree := 0
	var disagree := 0
	var crossing := 0
	var P := Overworld.PAD
	var A := Overworld.AREA
	for cy in range(-8, 9, 2):
		for cx in range(-8, 9, 2):
			var a := o.get_chunk(Vector2i(cx, cy))
			var east := o.get_chunk(Vector2i(cx + 1, cy))
			var south := o.get_chunk(Vector2i(cx, cy + 1))
			for k in 32:
				for d in P:
					# A's view of the east neighbour's first columns, and of the south neighbour's first rows
					var ae: int = a.road[(k + P) * A + 32 + P + d]
					var be: int = east.road[(k + P) * A + P + d]
					var as_: int = a.road[(32 + P + d) * A + k + P]
					var bs: int = south.road[(P + d) * A + k + P]
					if ae == be and as_ == bs:
						agree += 1
					else:
						disagree += 1
				if a.road[(k + P) * A + 31 + P] == 1 and east.road[(k + P) * A + P] == 1:
					crossing += 1
	check(disagree == 0, "chunk seams: roads agree across every edge (%d cells agree, %d differ)" % [agree, disagree])
	check(crossing > 20, "many roads cross chunk edges (%d crossings)" % crossing)
	# a road followed cell by cell from a village exit runs through many chunks without a break
	var m := VillageMap.load_default()
	var seen := {}
	var chunks := {}
	for e in m.exits():
		var start: Vector2i = e.out
		check(o.is_road(start), "the village exit %s is a road cell" % [start])
		var queue: Array[Vector2i] = [start]
		seen[start] = true
		var qi := 0
		while qi < queue.size() and queue.size() < 6000:
			var c: Vector2i = queue[qi]
			qi += 1
			chunks[Overworld.chunk_of(c)] = true
			for d: Vector2i in VillageMap.SIDES:
				var n := c + d
				if not seen.has(n) and o.is_road(n):
					seen[n] = true
					queue.append(n)
	check(seen.size() >= 3000, "the roads from the village's exits run on, joined (%d cells)" % seen.size())
	check(chunks.size() >= 40, "and through many chunks (%d)" % chunks.size())
	# roads and the cell round them are never solid
	var blocked := 0
	var roads := 0
	for cy in range(-4, 5):
		for cx in range(-4, 5):
			for y in 32:
				for x in 32:
					var cell := Vector2i(cx * 32 + x, cy * 32 + y)
					if not o.is_road(cell):
						continue
					roads += 1
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							var n := cell + Vector2i(dx, dy)
							if not m.in_village(n) and o.is_solid(n):
								blocked += 1
	check(roads > 500 and blocked == 0, "a road and the cells round it are never blocked (%d road cells, %d blocked)" % [roads, blocked])


## Flood fill over open cells from `from`, inside `box`. Returns the visited set.
func _flood(o: Overworld, from: Array, box: Rect2i) -> Dictionary:
	var seen := {}
	var queue: Array[Vector2i] = []
	for f in from:
		if not o.is_solid(f):
			seen[f] = true
			queue.append(f)
	var qi := 0
	while qi < queue.size():
		var c: Vector2i = queue[qi]
		qi += 1
		for d: Vector2i in VillageMap.SIDES:
			var n := c + d
			if box.has_point(n) and not seen.has(n) and not o.village.has_point(n) and not o.is_solid(n):
				seen[n] = true
				queue.append(n)
	return seen


func _test_traversable(seed_value: int) -> void:
	var m := VillageMap.load_default()
	var o := Overworld.create(seed_value, m)
	var exits: Array = m.exits()
	check(exits.size() == 4, "the village has four ways out (%d)" % exits.size())
	for e in exits:
		var out: Vector2i = e.out
		# a band 130 cells wide, running 330 cells out from the village in the exit's direction
		var d: Vector2i = e.dir
		var along := out + d * 330
		var box := Rect2i(mini(out.x, along.x) - (65 if d.x == 0 else 0), mini(out.y, along.y) - (65 if d.y == 0 else 0),
				absi(along.x - out.x) + (130 if d.x == 0 else 1), absi(along.y - out.y) + (130 if d.y == 0 else 1))
		var seen := _flood(o, [out], box)
		var far := 0
		for c: Vector2i in seen:
			var dist: int = (c.x - out.x) * d.x + (c.y - out.y) * d.y
			far = maxi(far, dist)
		check(far >= 300, "seed %d: walking out of the village %s reaches %d tiles away (%d cells open)" % [seed_value, ["north", "east", "south", "west"][e.side], far, seen.size()])


func _test_roads_reachable() -> void:
	var m := VillageMap.load_default()
	var o := Overworld.create(1, m)
	var box := Rect2i(-120, -120, 360, 330)
	var from := []
	for e in m.exits():
		from.append(e.out)
	var seen := _flood(o, from, box)
	var roads := 0
	var lost := []
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var c := Vector2i(x, y)
			if o.is_road(c):
				roads += 1
				if not seen.has(c):
					lost.append(c)
	check(roads > 800 and lost.is_empty(), "every road cell of the sample area is reachable on foot from the village (%d roads, %d cut off %s)" % [roads, lost.size(), lost.slice(0, 5)])


func _test_regions() -> void:
	var o := _world(1)
	var m := VillageMap.load_default()
	var cells := 0
	var trees := 0
	var cliffs := 0
	var tree_pairs := 0
	var tree_agree := 0
	var cliff_agree := 0
	var blocks := {}                           # 16 x 16 block -> trees in it
	for cy in range(-10, 0):
		for cx in range(-8, 8):
			var ch := o.get_chunk(Vector2i(cx, cy))
			for y in 32:
				for x in 32:
					var i := y * 32 + x
					cells += 1
					var tree := ch.kind[i] != Overworld.NO_TREE and ch.solid[i] == 1
					var cliff := ch.solid[i] == 1 and ch.kind[i] == Overworld.NO_TREE and ch.deco[i] < 0
					trees += 1 if tree else 0
					cliffs += 1 if cliff else 0
					if tree:
						var key := Vector2i(cx * 2 + x / 16, cy * 2 + y / 16)
						blocks[key] = int(blocks.get(key, 0)) + 1
					if x < 31:
						var j := i + 1
						var tree2 := ch.kind[j] != Overworld.NO_TREE and ch.solid[j] == 1
						var cliff2 := ch.solid[j] == 1 and ch.kind[j] == Overworld.NO_TREE and ch.deco[j] < 0
						tree_pairs += 1
						tree_agree += 1 if tree == tree2 else 0
						cliff_agree += 1 if cliff == cliff2 else 0
	var pt := float(trees) / cells
	var pc := float(cliffs) / cells
	var base_t := pt * pt + (1.0 - pt) * (1.0 - pt)
	var base_c := pc * pc + (1.0 - pc) * (1.0 - pc)
	var got_c := float(cliff_agree) / tree_pairs
	check(pc > 0.03 and pc < 0.5, "mountains cover a part of the land (%.0f%%)" % (pc * 100.0))
	check(got_c > base_c + 0.05 and got_c > 0.9, "mountains are coherent ranges: neighbours agree %.3f against %.3f for scattered cells" % [got_c, base_c])
	# forests are regions: the trees per 16 x 16 block vary far more than if scattered at random
	var counts := []
	for by in range(-20, 0):
		for bx in range(-16, 16):
			counts.append(int(blocks.get(Vector2i(bx, by), 0)))
	var mean := 0.0
	for v in counts:
		mean += v
	mean /= counts.size()
	var variance := 0.0
	for v in counts:
		variance += (v - mean) * (v - mean)
	variance /= counts.size()
	var random_var := 256.0 * pt * (1.0 - pt)
	check(pt > 0.01 and variance > 3.0 * random_var, "forests are regions: tree counts per block vary %.1f against %.1f for random scatter (%.1f%% trees)" % [variance, random_var, pt * 100.0])
	check(base_t > 0.0, "region figures computed")


# ---------------------------------------------------------------- scene ---------------------
func _run_scene() -> void:
	main.new_game()
	var w: World = main.world
	var m: VillageMap = main.map
	var o: Overworld = m.overworld
	check(o != null and o.seed == w.seed, "a new game has an overworld of the world's seed")
	var R := int(GameData.b("overworld_chunk_radius"))
	check(main.ow_view.loaded_count() > 0, "chunks are drawn round the start (%d)" % main.ow_view.loaded_count())
	# the village is as it was: outside it is still a wall to the village simulation
	check(m.is_solid(Vector2i(-1, 5)) and m.is_solid(Vector2i(120, 5)) and m.w == 120 and m.h == 90, "the village simulation still ends at its map's edge")
	# collision: a solid overworld tree and boulder block the player; open ground does not
	var tree_cell := Vector2i.ZERO
	var rock_cell := Vector2i.ZERO
	for cx in range(-6, 0):
		for cy in range(-4, 0):
			var ch := o.get_chunk(Vector2i(cx, cy))
			for y in range(1, 31):
				for x in range(2, 31):
					var i := y * 32 + x
					var cell := Vector2i(cx * 32 + x, cy * 32 + y)
					if ch.solid[i] == 1 and not o.is_solid(cell + Vector2i(-1, 0)) and not o.is_solid(cell + Vector2i(-1, 1)) and not o.is_solid(cell + Vector2i(-1, -1)):
						if ch.kind[i] != Overworld.NO_TREE and tree_cell == Vector2i.ZERO:
							tree_cell = cell
						elif ch.deco[i] == int(o.tiles.rock) and ch.kind[i] == Overworld.NO_TREE and rock_cell == Vector2i.ZERO:
							rock_cell = cell
	check(tree_cell != Vector2i.ZERO and rock_cell != Vector2i.ZERO, "found a tree %s and a boulder %s to walk into" % [tree_cell, rock_cell])
	for target in [tree_cell, rock_cell]:
		w.player.pos = Vector2(target.x - 0.5, target.y + 0.5)
		var before: Vector2 = w.player.pos
		var moved: bool = main._try_move(Vector2(0.3, 0))
		check(not moved and w.player.pos == before, "a solid overworld cell %s blocks the player's step" % [target])
		check(main._try_move(Vector2(-0.3, 0)), "and the player can step away from it")
	# tapping a goal outside the village: the route works over the overworld
	var start := Vector2(44.5, 53.5)
	var west: Vector2i = m.exits()[3].out
	var open_west := _flood(o, [west], Rect2i(-45, west.y - 25, 46, 50))      # open ground reachable from the west exit
	var far_cell := west
	for c: Vector2i in open_west:
		if c.x < far_cell.x or (c.x == far_cell.x and c.y < far_cell.y):
			far_cell = c
	var goal := Vector2(far_cell) + Vector2(0.5, 0.5)
	check(far_cell.x < -25, "a goal 25 tiles or more outside the village's west edge: %s" % [far_cell])
	w.player.pos = start
	main.move_to = goal
	var guard := 0
	while main.move_to != Vector2.INF and guard < 4000:
		main._player_step(0.04)
		guard += 1
	check(w.player.pos.distance_to(goal) < 1.5, "tap-to-walk crosses the village edge to a goal outside it (%s, %d steps)" % [w.player.pos, guard])
	check(not m.is_solid_world(Vector2i(floori(w.player.pos.x), floori(w.player.pos.y))), "and ends on open ground")
	main.move_to = start
	guard = 0
	while main.move_to != Vector2.INF and guard < 4000:
		main._player_step(0.04)
		guard += 1
	check(w.player.pos.distance_to(start) < 1.5, "and back to the village square (%s, %d steps)" % [w.player.pos, guard])
	# walking the road out with the keys' own step: pressed move_right along an east-west stretch
	var e: Dictionary = m.exits()[3]
	w.player.pos = Vector2(e.out) + Vector2(0.5, 0.5)
	var x0: float = w.player.pos.x
	Input.action_press("move_left")
	for i in 100:
		main._player_step(0.04)
	Input.action_release("move_left")
	check(w.player.pos.x < x0 - 2.0 or main._blocked_corners(w.player.pos + Vector2(-0.3, 0)) > 0, "walking with the keys works outside the village")
	# a far goal (beyond the route search): the player walks straight and slides, without errors
	w.player.pos = Vector2(e.out) + Vector2(0.5, 0.5)
	main.move_to = Vector2(-400.5, 72.5)
	for i in 500:
		main._player_step(0.04)
	check(main._blocked_corners(w.player.pos) == 0, "a far tap walks on over open ground, never into a solid cell")
	main.move_to = Vector2.INF
	# streaming: walk 25 chunks away and back; what is held stays bounded
	var home := Vector2(60.5, 72.5)
	var snap := {}
	for c in [Vector2i(-30, 40), Vector2i(-35, 70), Vector2i(-50, 75)]:
		snap[c] = main.ow_view.ground_value(c)
	var most_nodes := 0
	var most_cache := 0
	var gen_before := 0
	for step in 26:
		var at := Vector2(-40.5 - step * 32.0, 72.5 + step * 7.0)
		w.player.pos = at
		main.camera.position = at * 16.0
		main.follow_at = at * 16.0
		for k in 4:
			main.ow_view.follow(at, at, 0.1, -1)
		most_nodes = maxi(most_nodes, main.ow_view.loaded_count())
		most_cache = maxi(most_cache, o.cache.size())
	check(most_nodes <= (2 * R + 3) * (2 * R + 3), "walking 26 chunks away keeps at most %d chunk nodes drawn (%d)" % [(2 * R + 3) * (2 * R + 3), most_nodes])
	check(most_cache <= Overworld.MAX_CACHED, "and the generated chunks held stay bounded (%d)" % most_cache)
	await process_frame                  # freed chunk nodes go at the frame's end
	check(main.ow_view.get_child_count() <= (2 * R + 3) * (2 * R + 3) + 1, "the view holds no nodes of chunks it freed (%d children)" % main.ow_view.get_child_count())
	var gen := o.generated
	var at_now: Vector2 = w.player.pos
	for k in 60:
		main.ow_view.follow(at_now, at_now, 0.016)
	check(o.generated == gen, "frames over loaded chunks generate nothing")
	var back: Vector2 = home
	main.camera.position = back * 16.0
	for k in 3:
		main.ow_view.follow(back, back, 0.1, -1)
	for c in snap:
		check(main.ow_view.ground_value(c) == snap[c] and (snap[c] == -1 or snap[c] >= 100000), "returning shows the same tiles at %s" % [c])
		# trees outside the village are lifecycle trees of the one model, drawn as sprites: felled, saved,
		# loaded, regrown by the clock, planted, grown; kept across unloading and reloading chunks
		var tree := {}
		var tcell := Vector2i.ZERO
		for cy in range(-5, 0):
			for cx in range(-5, 0):
				var ch := o.get_chunk(Vector2i(cx, cy))
				for q in range(0, ch.trees.size(), 3):
					var cell := Vector2i(ch.trees[q], ch.trees[q + 1])
					if tree.is_empty() and o.is_solid(cell):
						var cand := w.tree_at(cell)
						if cand.state == "grown":
							tree = cand
							tcell = cell
		check(not tree.is_empty() and tree.get("ow", false) and tree.state == "grown", "a mature tree outside the village is found by World.tree_at %s" % [tcell])
		w.player.pos = Vector2(tcell) + Vector2(-0.5, 0.5)
		main.ow_view.follow(w.player.pos, w.player.pos, 0.1, -1)
		var tn: TreeView.TreeNode = main.tree_view.node_at(tcell)
		check(tn != null and tn.drawn == "grown" and tn.texture != null, "it is drawn as a sprite")
		check(w.chop_tree(tree, -1, 0).logs == 0 and w.tree_hits(tcell) == 1 and tn.hits == 1 and tn.cuts != null, "a blow leaves a cut mark and no logs")
		var logs := w.fell(tree, 0)
		check(logs == 4 and not o.is_solid(tcell) and o.changes.has(tcell), "felling it gives logs, opens the cell and records the change")
		check(w.fell(tree, 0) == 0, "and not twice")
		check(tn.drawn == "stump" and tn.cuts == null, "the view shows the stump")
		var cc := Overworld.chunk_of(tcell)
		var d := o.to_dict()
		check(d.keys().size() == 3 and d.changes.size() == 1 and int(d.seed) == o.seed, "only the seed and the change are saved, never the terrain")
		# the chunk unloads and loads again: the stump is still a stump
		var far := Vector2(tcell) + Vector2(400.5, 0.5)
		w.player.pos = far
		main.camera.position = far * 16.0
		main.ow_view.follow(far, far, 0.1, -1)
		check(main.tree_view.node_at(tcell) == null and not main.ow_view.chunks.has(cc), "far away the chunk's trees are not drawn")
		w.player.pos = Vector2(tcell) + Vector2(-0.5, 0.5)
		main.camera.position = w.player.pos * 16.0
		main.ow_view.follow(w.player.pos, w.player.pos, 0.1, -1)
		check(main.tree_view.node_at(tcell) != null and main.tree_view.node_at(tcell).drawn == "stump", "back again the stump is drawn, not a tree")
		check(main.save_game(false), "the game saves")
		main.continue_game()
		var w2: World = main.world
		var o2: Overworld = main.map.overworld
		check(w2 != w and o2.seed == o.seed and o2.changes.has(tcell) and o2.changes[tcell].state == "stump", "after loading the seed and the felled tree are back")
		check(not o2.is_solid(tcell) and w2.tree_at(tcell).state == "stump", "the stump is walkable and still a stump")
		var o3 := _world(o.seed)
		check(_fingerprint(o3.get_chunk(cc)) == _fingerprint(o2.get_chunk(cc)), "the terrain around it regenerates identically from the seed")
		# regrowth by the clock: a stump, a sapling, young, growing, mature, and the world is as generated
		var t2: Dictionary = o2.changes[tcell]
		w2.minutes = float(t2.regrow) * Trees.DAY + 1.0
		w2.sync_tree(t2)
		check(t2.state == "sapling" and not o2.is_solid(tcell), "after its days it is a sapling, not solid")
		w2.minutes = float(t2.born) + Trees.stage_minutes("sapling") + Trees.stage_minutes("young") + 1.0
		w2.sync_tree(t2)
		check(t2.state == "growing" and o2.is_solid(tcell), "then a growing tree with a solid trunk")
		w2.minutes += Trees.stage_minutes("growing")
		w2.sync_tree(t2)
		check(t2.state == "grown" and not o2.changes.has(tcell) and o2.is_solid(tcell), "then a mature tree again: the change is gone and the world is as generated")
		# every overworld tree is a lifecycle tree: several species and stages, in patches, none on a road or exit
		o3.clock = 7.0 * 60.0
		var kinds := {}
		var stages := {}
		var alike := 0
		var pairs := 0
		var on_road := 0
		var trees_seen := 0
		for cy in range(-3, 6):
			for cx in range(-3, 6):
				var by := {}
				var list: Array = o3.chunk_trees(Vector2i(cx, cy))
				for t in list:
					by[Vector2i(int(t.x), int(t.y))] = t
				for t in list:
					trees_seen += 1
					kinds[t.species] = true
					stages[t.state] = true
					var tc := Vector2i(int(t.x), int(t.y))
					if o2.is_road(tc) or o2.chunk_in_village(Overworld.chunk_of(tc)):
						on_road += 1
					for gate in main.map.exits():
						if tc == gate.out or tc == gate.edge:
							on_road += 1
					for dd in [Vector2i(2, 0), Vector2i(0, 2), Vector2i(3, 0), Vector2i(0, 3)]:
						var other: Dictionary = by.get(tc + dd, {})
						if not other.is_empty():
							pairs += 1
							alike += 1 if other.species == t.species else 0
		check(trees_seen > 200 and on_road == 0, "%d overworld trees, none on a road or an exit" % trees_seen)
		check(kinds.size() >= 4 and stages.size() >= 3, "they are of several species and stages: %s %s" % [kinds.keys(), stages.keys()])
		check(pairs == 0 or (alike < pairs * 9 / 10 and alike > pairs / 8), "in patches, not all alike (%d of %d near pairs alike)" % [alike, pairs])
		# the whole journey, with the player's own actions: out of the village, fell a mature tree for logs and a
		# sapling, plant it, let it grow, leave until its chunk unloads, come back, save, load: the tree is a mature tree
		var p: PlayerState = w2.player
		p.inv.add("axe")
		var spot := Vector2i(-1000, -1000)
		var west2: Vector2i = main.map.exits()[3].out
		for r in range(3, 40):
			for dy in range(-r, r + 1):
				var sc := west2 + Vector2i(-r, dy)
				var tr := w2.tree_at(sc)
				if spot.x < -999 and not tr.is_empty() and tr.state == "grown" and Vector2i(int(tr.x), int(tr.y)) == sc and not o2.is_solid(sc + Vector2i(1, 0)):
					spot = sc
		check(spot.x > -999, "a mature tree beside the west road to fell")
		var goal2 := Vector2(spot.x + 1, spot.y) + Vector2(0.5, 0.5)
		w2.player.pos = Vector2(main.map.exits()[3].edge) + Vector2(0.5, 0.5)
		main.move_to = goal2
		guard = 0
		while main.move_to != Vector2.INF and guard < 4000:
			main._player_step(0.04)
			guard += 1
		check(w2.player.pos.distance_to(goal2) < 2.5, "walked out of the village to the tree (%s, %d steps)" % [w2.player.pos, guard])
		w2.player.pos = goal2
		main.player_sprite.face(Vector2(-1, 0))
		main._find_target()
		check(main.target.get("kind", "") == "tree", "Use offers the tree: %s" % main.target.get("label", ""))
		var logs0 := p.inv.count("log")
		main._use()
		guard = 0
		while not main.action.is_empty() and guard < 2000:
			main._player_step(0.05)
			guard += 1
		var trj := w2.tree_at(spot)
		check(p.inv.count("log") == logs0 + 4 and trj.state == "stump", "felled blow by blow: 4 logs and a stump")
		var sap := p.inv.count("oak_sapling") + p.inv.count("pine_sapling")
		check(sap >= 1, "and a sapling in the pack")
		var sid := "oak_sapling" if p.inv.count("oak_sapling") > 0 else "pine_sapling"
		# plant it on the free grass in front of the player
		var plant_at := Vector2i(-1000, -1000)
		var reasons := {}
		for r in range(2, 9):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var c2 := spot + Vector2i(dx, dy)
					for face in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
						var stand := Vector2i((Vector2(c2) - face).floor())
						reasons[w2.plant_refusal(c2)] = true
						if plant_at.x < -999 and w2.plant_refusal(c2) == "" and not o2.is_solid(stand):
							w2.player.pos = Vector2(c2) + Vector2(0.5, 0.5) - face
							main.player_sprite.face(face)
							plant_at = c2
		check(plant_at.x > -999, "free grass in front of the player %s %s" % [w2.player.pos, reasons.keys()])
		main.plant_sapling(sid)
		guard = 0
		while not main.action.is_empty() and guard < 2000:
			main._player_step(0.05)
			guard += 1
		var pl := w2.tree_at(plant_at)
		check(not pl.is_empty() and pl.state == "sapling" and pl.planted and not o2.is_solid(plant_at) and p.inv.count(sid) == sap - 1, "planted: a sapling that is not solid, one sapling fewer")
		check(main.tree_view.node_at(plant_at) != null and main.tree_view.node_at(plant_at).drawn == "sapling", "drawn as a sapling")
		check(w2.plant_refusal(plant_at) != "" and w2.plant_refusal(plant_at + Vector2i(1, 0)) != "", "no second sapling on or beside it")
		w2.minutes += Trees.stage_minutes("sapling") + Trees.stage_minutes("young") + 1.0
		main.tree_view.update(w2.player.pos, 0.6)
		check(pl.state == "growing" and o2.is_solid(plant_at) and main.tree_view.node_at(plant_at).drawn == "growing", "the view follows the clock: growing, solid")
		w2.minutes += Trees.stage_minutes("growing")
		main.tree_view.update(w2.player.pos, 0.6)
		check(pl.state == "grown" and main.tree_view.node_at(plant_at).drawn == "grown", "and mature")
		# leave until the chunk is unloaded, return
		var gone := Vector2(plant_at) + Vector2(-400.5, 0.5)
		w2.player.pos = gone
		main.camera.position = gone * 16.0
		main.ow_view.follow(gone, gone, 0.1, -1)
		check(main.tree_view.node_at(plant_at) == null, "its chunk unloaded: the tree is not drawn")
		w2.player.pos = Vector2(plant_at) + Vector2(0.5, 1.5)
		main.camera.position = w2.player.pos * 16.0
		main.ow_view.follow(w2.player.pos, w2.player.pos, 0.1, -1)
		check(main.tree_view.node_at(plant_at) != null and main.tree_view.node_at(plant_at).drawn == "grown", "back again it is a mature tree")
		check(main.save_game(false), "saved")
		main.continue_game()
		w2 = main.world
		main.ow_view.follow(w2.player.pos, w2.player.pos, 0.1, -1)
		var pl2 := w2.tree_at(plant_at)
		check(not pl2.is_empty() and pl2.state == "grown" and pl2.species == pl.species and w2.map.overworld.is_solid(plant_at), "after loading the planted tree is a mature tree of the same species")
		check(main.tree_view.node_at(plant_at) != null and main.tree_view.node_at(plant_at).drawn == "grown", "and drawn so")
		check(w2.tree_at(spot).state == "stump" or w2.tree_at(spot).state == "sapling", "and the felled one is still on its way back")
		# the village's own trees: the map's trees and its edge woodland, all of the model
		check(w2.trees.size() >= main.map.data.trees.size(), "the village's trees are all there")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
