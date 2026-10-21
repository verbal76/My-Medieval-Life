extends SceneTree
## MIN-F underground works and MIN-H caves (docs/build17/MIN_F_UNDERGROUND.md, owner OD-29, OD-28, Q18-9): the natural
## cave under the hill is the same for a seed, reachable from its own mouth and lies under the rock; the adit gallery is
## unchanged by it; the cave's seams are ordinary deposit records; the player crosses the cave's mouth and villagers are
## routed through it; where levels stack the rules see the level of whoever stands there. A tunnel is cut only within
## reach of a timber support set up from real goods; every unit cut is counted and conserved; the player and a villager
## cut by the same rule; track is laid from real goods; a minecart on track carries real goods along it, stays on its
## rails, and goes through a mouth only where track lies on both sides; saves round-trip it all and older saves load; a
## level-0 village still mines (nothing is gated by a capability level). Run headless:
##   godot --headless --path game --script res://tests/underground_ext_test.gd

const Census := preload("res://tests/census.gd")

var failures := 0
var checks := 0
var main
const TEST_SAVE := "user://test_saves/underground_ext_test/save1.json"
const ADIT_SEED1_MD5 := "e9d80cba55d2bcf74d8b2a492661a392"     # the adit gallery of seed 1 before MIN-F (unchanged)


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	_test_cave_generation()
	_test_cave_entry()
	_test_stacked_levels()
	_test_supports()
	_test_cutting()
	_test_parity()
	_test_track_and_minecart()
	_test_minecart_through_the_mouth()
	_test_save_load()
	_test_determinism()
	_test_level_zero_mines()
	_test_villager_into_cave()
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


func _st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0))


func _cave(w: World) -> LevelMap:
	return w.underground.level_map("hill_cave")


func _gallery(w: World) -> LevelMap:
	return w.underground.level_map("adit_gallery")


## The first floor cell of a level (row order) with a rock cell beside it that a tunnel may be cut into once a support
## stands near: [floor, rock].
func _face(w: World, lm: LevelMap) -> Array:
	for f in lm.floor_cells():
		for d: Vector2i in VillageMap.SIDES:
			var c := f + d
			if lm.is_solid(c) and w.deposit_at(c, lm.level).is_empty() and lm.region.grow(-1).has_point(c) and w.underground.under_rock(w.map, c):
				return [f, c]
	return []


## A route four-way: a diagonal step goes round by its side cell (track is laid four ways; the A* allows a diagonal
## only where both side cells are open).
func _four(path: PackedVector2Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for pt in path:
		var c := Vector2i(pt)
		if not out.is_empty():
			var last: Vector2i = out[out.size() - 1]
			if last.x != c.x and last.y != c.y:
				out.append(Vector2i(c.x, last.y))
		out.append(c)
	return out


## A villager made a tunneller for the test: a pickaxe and a mallet, standing on `cell` of `level`.
func _hand(w: World, level: int, cell: Vector2i) -> NPC:
	var n: NPC = w.brain._first_with_job("laborer")
	if n == null:
		n = w.npcs[0]
	n.plan.clear()
	n.depth = level
	n.pos = Vector2(cell) + Vector2(0.5, 0.5)
	if not n.inv.has("pickaxe"):
		n.inv.add("pickaxe")
	if not n.inv.has("mallet"):
		n.inv.add("mallet")
	return n


## The player below on `level` at `cell` (walked in through the level's own mouth).
func _player_below(w: World, level: int, cell: Vector2i) -> PlayerState:
	var p := w.player
	for por in w.underground.portals:
		if int(por.ends[1].level) == level:
			p.pos = Vector2(por.ends[0].stand) + Vector2(0.5, 0.5)
			w.player_through(Vector2(por.ends[1].stand - por.ends[0].stand))
	p.pos = Vector2(cell) + Vector2(0.5, 0.5)
	return p


# ---------------------------------------------------------------- the cave (MIN-H) -----------
func _test_cave_generation() -> void:
	var m := VillageMap.load_default()
	var u1 := Underground.create(1, m)
	var lg := u1.level_map("adit_gallery")
	var fp := "%s %d %s\n%s" % [lg.id, lg.level, str(lg.region), lg.to_text()]
	for sd in u1.seams:
		if int(sd.level) == -1:
			fp += "|%d,%d,%s,%d" % [int(sd.x), int(sd.y), str(sd.ore), int(sd.amount)]
	check(fp.md5_text() == ADIT_SEED1_MD5, "the adit gallery of seed 1 is exactly as before the cave was added")
	var a := u1.fingerprint()
	check(a == Underground.create(1, VillageMap.load_default()).fingerprint(), "the gallery and the cave are identical for a seed")
	var cave_texts := {}
	for s in [1, 2, 3, 7, 12345]:
		var u := Underground.create(s, m)
		var lm := u.level_map("hill_cave")
		cave_texts[lm.to_text()] = true
		var mouth: Dictionary = u.portals[1]
		var inner: Vector2i = mouth.ends[1].stand
		var floors := lm.floor_cells()
		var bad_reach := 0
		var bad_rock := 0
		for c in floors:
			var p := lm.find_path(inner, c)
			if p.is_empty() or Vector2i(p[p.size() - 1]) != c:
				bad_reach += 1
			if c != inner and not u.under_rock(m, c):
				bad_rock += 1
		check(lm.level == -2 and floors.size() >= 30 and not lm.is_solid(inner) and str(mouth.id) == "cave_mouth" and int(mouth.ends[0].level) == 0,
				"seed %d: a natural cave of %d floor cells on level -2, open at its own mouth %s" % [s, floors.size(), str(inner)])
		check(bad_reach == 0 and lm.reachable_from(inner).size() == floors.size(), "seed %d: every cave floor cell is reachable from its mouth by the level's own A*" % s)
		check(bad_rock == 0, "seed %d: the cave lies only under the hill's rock, a cell deep all round (but its mouth)" % s)
		var cs := u.seams.filter(func(x): return int(x.level) == -2)
		var walls := {}
		for c in lm.wall_cells():
			walls[c] = true
		var ok := cs.size() == 3
		var kinds := {}
		for sd in cs:
			kinds[str(sd.ore)] = true
			if not walls.has(Vector2i(int(sd.x), int(sd.y))) or not _static_rock(m, Vector2i(int(sd.x), int(sd.y))) or int(sd.amount) <= 0:
				ok = false
		check(ok and kinds.size() == 3, "seed %d: three seams on the cave's walls (coal, iron ore, copper ore), the village's own amounts" % s)
	check(cave_texts.size() >= 3, "other seeds give other caves (%d shapes in 5 seeds)" % cave_texts.size())
	var w := _world(1)
	check(w.villager_levels == [0, -1, -2] and w.deposits.filter(func(d): return World.level_of(d) == -2).size() == 3 and w.deposits.filter(func(d): return World.level_of(d) == -2).all(func(d): return d.has("host")),
			"the cave's seams are ordinary World.deposits records with their host rock (MIN-B), on a level villagers reach")
	var st := w.rng.state
	Underground.create(w.seed, w.map)
	check(w.rng.state == st, "making the cave draws nothing from the world's random stream")


func _test_cave_entry() -> void:
	var w := _world(1)
	var p := w.player
	var mouth: Dictionary = w.underground.portals[1]
	var outer: Vector2i = mouth.ends[0].stand
	var inner: Vector2i = mouth.ends[1].stand
	check(not w.map.is_solid(outer) and w.map.is_solid(inner), "the cave's mouth: a walkable stand before the hill's rock face")
	p.pos = Vector2(outer) + Vector2(0.5, 0.5)
	var r := w.player_through(Vector2.UP)
	check(r.get("level", 0) == -2 and w.player_level == -2 and Vector2i(p.pos.floor()) == inner and str(r.get("portal", "")) == "cave_mouth",
			"pushing into the cave's mouth takes the player to level -2 at its inner mouth")
	check(w.solid_for_player(Vector2i(48, 40)) and not w.solid_for_player(inner), "below, the cave's own map is the collision (rock off it)")
	var lm := _cave(w)
	var far: Vector2i = lm.floor_cells()[lm.floor_cells().size() - 1]
	var path := w.path_for_player(inner, far)
	check(not path.is_empty() and Vector2i(path[path.size() - 1]) == far, "the player's tap-walk routes on the cave's floor")
	var back := w.player_through(Vector2.DOWN)
	check(back.get("level", -9) == 0 and Vector2i(p.pos.floor()) == outer, "and walking out comes back to the stand before the mouth")
	check(w.underground.next_leg(0, -2).portal.id == "cave_mouth" and w.underground.next_leg(-1, -2).portal.id == "adit",
			"the router reaches the cave through its mouth (from the gallery: out through the adit first)")


## Where the cave lies under the gallery, a point is on the level of whoever stands there.
func _test_stacked_levels() -> void:
	var w := _world(1)
	var both := Vector2i(-1, -1)
	for c in _gallery(w).floor_cells():
		if not _cave(w).is_solid(c):
			both = c
			break
	check(both.x >= 0 and w.underground.levels_at(w.map, both) == [-1, -2], "a cell %s is floor of both the gallery and the cave below it" % str(both))
	var p := _player_below(w, -2, both)
	var n := _hand(w, -1, both)
	n.pos = Vector2(both) + Vector2(0.25, 0.75)
	check(w.level_at(p.pos) == -2 and w.level_at(n.pos) == -1, "the player there is on the cave's level, the villager on the gallery's")
	check(not w.present(p.pos, 3.0).has(n) and not w.near(p.pos, 3.0).has(n) and not w.reaches(p.pos, n.pos),
			"neither sees nor reaches the other through the rock between")
	n.depth = -2
	check(w.present(p.pos, 3.0).has(n), "on the cave's level both, they meet")


# ---------------------------------------------------------------- supports (MIN-F) -----------
func _test_supports() -> void:
	var w := _world(1)
	var lm := _gallery(w)
	var face := _face(w, lm)
	var n := _hand(w, -1, face[0])
	var mw := w.mine_works
	check(mw.support_refusal(n, face[0]).contains("timber support"), "a support needs a timber support in the pack")
	n.inv.add("timber_support", 2)
	n.inv.remove("mallet", n.inv.count("mallet"))
	check(mw.support_refusal(n, face[0]).contains("mallet"), "and a mallet")
	n.inv.add("mallet")
	check(mw.support_refusal(n, face[1]).contains("floor"), "it stands on the floor, never in the rock")
	var s0 := n.inv.count("timber_support")
	var u0 := _st(w, "used_timber_support")
	var g0 := Census.goods(w)
	var r := mw.place_support(n, face[0])
	check(r.result == "ok" and n.inv.count("timber_support") == s0 - 1 and _st(w, "used_timber_support") == u0 + 1 and mw.support_at(-1, face[0]),
			"set up, the support leaves the pack (used_timber_support) and stands on its cell")
	check(int(Census.goods(w).get("timber_support", 0)) == int(g0.get("timber_support", 0)) - 1, "the goods census loses exactly the one support set up")
	check(mw.support_refusal(n, face[0]).contains("already"), "one support a cell")
	check(w.discovery.structures("timber_support") == 1, "the capability evaluator counts the support as a structure (reported only, Q18-9)")
	var p := w.player
	p.pos = Vector2(30.5, 40.5)
	p.inv.add("timber_support")
	p.inv.add("mallet")
	check(mw.support_refusal(p, Vector2i(30, 41)).contains("below ground"), "on the surface no support is set up")


# ---------------------------------------------------------------- cutting (MIN-F) ------------
func _test_cutting() -> void:
	var w := _world(1)
	var lm := _gallery(w)
	var mw := w.mine_works
	var face := _face(w, lm)
	var f: Vector2i = face[0]
	var c: Vector2i = face[1]
	var n := _hand(w, -1, f)
	n.inv.add("timber_support", 3)
	check(mw.dig_refusal(n, c).contains("timber support"), "unsupported rock is not cut: %s" % mw.dig_refusal(n, c))
	var seam: Dictionary = w.deposits.filter(func(d): return World.level_of(d) == -1)[0]
	check(mw.rock_refusal(-1, Vector2i(int(seam.x), int(seam.y))).contains("seam"), "a seam's cell is mined, never cut as tunnel rock")
	check(mw.rock_refusal(-1, lm.region.position).contains("thin"), "the map's edge rock is never cut: the hill would give way")
	check(mw.rock_refusal(0, Vector2i(30, 40)).contains("open pit"), "on the surface there is no tunnel to cut (OD-29: open pits stay up there)")
	mw.place_support(n, f)
	var deep := Vector2i(-1, -1)
	for cc in lm.cells():
		if lm.is_solid(cc) and not lm._touches_floor(cc) and mw.supported(-1, cc) and w.deposit_at(cc, -1).is_empty() and w.underground.under_rock(w.map, cc):
			deep = cc
			break
	if deep.x >= 0:
		check(mw.rock_refusal(-1, deep).contains("open face"), "rock with no floor beside it is not cut: only an open face")
	n.inv.remove("pickaxe", n.inv.count("pickaxe"))
	check(mw.dig_refusal(n, c, "pickaxe").contains("pickaxe"), "cutting needs a pickaxe")
	n.inv.add("pickaxe")
	n.pos = Vector2(f) + Vector2(4.5, 0.5) if lm.is_solid(f + Vector2i(4, 0)) == false else Vector2(f) + Vector2(0.5, 3.5)
	if Vector2i(n.pos.floor()).distance_to(c) > 1.5:
		check(mw.dig_refusal(n, c).contains("Stand"), "the cutter stands at the face")
	n.pos = Vector2(f) + Vector2(0.5, 0.5)
	var g0 := Census.goods(w)
	var gc0 := mw.ground_cut()
	var items := []
	var xp0 := int(n.skills.get("mining", 0))
	var opened := false
	var rock_until_last := true
	for k in MineWorks.cell_units():
		if not lm.is_solid(c):
			rock_until_last = false
		var r := mw.dig(n, c, n.inv)
		items.append(str(r.item))
		opened = bool(r.get("opened", false))
	check(items == ["stone", "stone", "stone", "spoil", "spoil"] and opened and rock_until_last, "a rock cell gives 3 stone then 2 spoil, one a cut, and opens with the last (%s)" % str(items))
	check(not lm.is_solid(c) and not lm.find_path(w.underground.portals[0].ends[1].stand, c).is_empty() and mw.opened.size() == 1,
			"the cell cut through is floor of the gallery, reached from the adit by its A* at once")
	check(int(n.skills.get("mining", 0)) - xp0 == MineWorks.cell_units() * int(MineWorks.cfg().xp), "Mining xp a unit (%d)" % int(MineWorks.cfg().xp))
	check(_st(w, "cut_stone") == 3 and _st(w, "cut_spoil") == 2 and _st(w, "tunnel_cells_opened") == 1, "each unit is counted cut_<item>")
	var g1 := Census.goods(w)
	var gc1 := mw.ground_cut()
	var conserved := true
	for id in ["stone", "spoil"]:
		var rise := int(g1.get(id, 0)) - int(g0.get(id, 0))
		var fell := int(gc1.get(id, 0)) - int(gc0.get(id, 0))
		if rise != fell or rise != _st(w, "cut_" + id):
			conserved = false
	check(conserved, "the goods census rises by exactly what left the rock, item by item (nothing from nothing)")
	check(mw.rock_refusal(-1, c).contains("no rock"), "a cell cut through has nothing more to give")
	# cutting on: further cells within the support's reach, then refused beyond it
	var cut_more := 0
	var refused_far := false
	for k in 40:
		var next := Vector2i(-1, -1)
		var far := Vector2i(-1, -1)
		for cc in lm.cells():
			var why := mw.rock_refusal(-1, cc)
			if why == "" and next.x < 0:
				next = cc
			elif why.contains("timber support") and far.x < 0:
				far = cc
		if far.x >= 0:
			refused_far = true
		if next.x < 0:
			break
		for d: Vector2i in VillageMap.SIDES:
			if not lm.is_solid(next + d):
				n.pos = Vector2(next + d) + Vector2(0.5, 0.5)
		for u in MineWorks.cell_units():
			mw.dig(n, next, n.inv)
		cut_more += 1
	check(cut_more >= 1 and refused_far, "more cells are cut within the support's reach (%d), and rock beyond it waits for another support" % cut_more)
	var all_reach := lm.reachable_from(w.underground.portals[0].ends[1].stand)
	check(all_reach.size() == lm.floor_cells().size(), "every floor cell, old and cut, is still reached from the adit (DVW-A10)")
	var out_of_rock := 0
	for o in mw.opened:
		if not w.underground.under_rock(w.map, Vector2i(int(o[1]), int(o[2]))):
			out_of_rock += 1
	check(out_of_rock == 0, "every cell cut lies under the hill's rock with rock all round (the tunnels are bounded by the hill)")


func _test_parity() -> void:
	var w := _world(2)
	var lm := _gallery(w)
	var mw := w.mine_works
	var face := _face(w, lm)
	var f: Vector2i = face[0]
	var n := _hand(w, -1, f)
	n.inv.add("timber_support")
	mw.place_support(n, f)
	var cells := []
	for d: Vector2i in VillageMap.SIDES:
		if mw.rock_refusal(-1, f + d) == "":
			cells.append(f + d)
	if cells.size() < 2:
		for cc in lm.cells():
			if mw.rock_refusal(-1, cc) == "" and not cells.has(cc):
				cells.append(cc)
	var p := _player_below(w, -1, f)
	if not p.inv.has("pickaxe"):
		p.inv.add("pickaxe")
	var pc: Vector2i = cells[0]
	var nc: Vector2i = cells[1]
	for d: Vector2i in VillageMap.SIDES:
		if not lm.is_solid(nc + d):
			n.pos = Vector2(nc + d) + Vector2(0.5, 0.5)
		if not lm.is_solid(pc + d):
			p.pos = Vector2(pc + d) + Vector2(0.5, 0.5)
	var pxp := int(p.skills.get("mining", 0))
	var nxp := int(n.skills.get("mining", 0))
	var p0 := p.inv.count("stone")
	var rp := mw.dig(p, pc, p.inv, "pickaxe")
	var rn := mw.dig(n, nc, n.inv, "pickaxe")
	check(rp.result == "ok" and rn.result == "ok" and rp.item == rn.item and rp.item == "stone", "the player and a villager cut the same unit by the same rule (%s, %s)" % [rp.get("why", ""), rn.get("why", "")])
	check(int(p.skills.get("mining", 0)) - pxp == int(n.skills.get("mining", 0)) - nxp, "the same Mining xp for both")
	check(p.inv.count("stone") == p0 + 1, "the player's unit goes to the pack")
	var q := w.player.inv
	q.remove("pickaxe", q.count("pickaxe"))
	n.inv.remove("pickaxe", n.inv.count("pickaxe"))
	check(mw.dig_refusal(p, pc).contains("pickaxe") and mw.dig_refusal(n, nc).contains("pickaxe"), "neither cuts without a pickaxe")


# ---------------------------------------------------------------- track and minecart ---------
func _test_track_and_minecart() -> void:
	var w := _world(1)
	var lm := _gallery(w)
	var mw := w.mine_works
	var inner: Vector2i = w.underground.portals[0].ends[1].stand
	var far: Vector2i = lm.floor_cells()[0]
	var route := _four(lm.find_path(inner, far))
	var n := _hand(w, -1, inner)
	check(mw.track_refusal(n, inner).contains("track section"), "track needs a track section")
	n.inv.add("track_section", route.size())
	var t0 := n.inv.count("track_section")
	for pt in route:
		n.pos = Vector2(pt) + Vector2(0.5, 0.5)
		var r := mw.lay_track(n, Vector2i(pt))
		if r.result != "ok":
			check(false, "track laid on %s: %s" % [str(pt), r.why])
	check(n.inv.count("track_section") == t0 - route.size() and _st(w, "used_track_section") == route.size() and mw.track_cells(-1).size() == route.size(),
			"a run of %d track sections is laid from the adit inward, one a cell, each used up" % route.size())
	n.inv.add("track_section")
	check(mw.track_refusal(n, Vector2i(route[0])).contains("already"), "one section a cell")
	check(mw.track_ground_refusal(-1, lm.region.position) != "", "no track in the rock")
	check(mw.track_ground_refusal(0, Vector2i(48, 11)) == "" and mw.track_ground_refusal(0, Vector2i(10, 80)) != "",
			"on the surface track is laid only in the mine's yard, near a mouth")
	# the minecart: built from real parts (the recipe), set down on track only
	var bench := n.inv
	for id in GameData.recipes.build_minecart["in"]:
		bench.add(id, int(GameData.recipes.build_minecart["in"][id]))
	var made := w.work_craft(n, "build_minecart", bench)
	check(made.result == "ok" and n.inv.count("minecart") >= 1 and _st(w, "made_minecart") >= 1, "a minecart is built at the workbench from wheels, axles, ironwork and planks")
	n.pos = Vector2(inner) + Vector2(0.5, 0.5)
	var off := Vector2i(-1, -1)
	for c in lm.floor_cells():
		if not mw.track_at(-1, c):
			off = c
			break
	check(mw.minecart_refusal(n, off).contains("track"), "a minecart is set down on its rails only")
	var mc0 := n.inv.count("minecart")
	var sd := mw.set_down_minecart(n, World.hh_ref(n.household), inner)
	var cart: Dictionary = sd.get("cart", {})
	check(sd.result == "ok" and Carts.kind_of(cart) == "minecart" and World.level_of(cart) == -1 and n.inv.count("minecart") == mc0 - 1 and _st(w, "used_minecart") == 1,
			"set down, the minecart is a cart of its own kind on the gallery's level (used_minecart)")
	check((cart.store as Inventory).max_stacks == int(MineWorks.cfg().minecart.stacks) and w.carts.of(World.hh_ref(n.household)).is_empty() and w.carts.of(World.hh_ref(n.household), "minecart").size() == 1,
			"it holds its stacks; the household's market runs (handcarts) do not take it")
	check(w.carts.near(Vector2(inner) + Vector2(0.5, 0.5), 1.0).is_empty() and w.carts.near(Vector2(inner) + Vector2(0.5, 0.5), 1.0, -1) == cart,
			"it is found on its own level, not on the surface above")
	# real goods ride along the track
	var ore: Dictionary = w.deposits.filter(func(d): return World.level_of(d) == -1 and d.ore != "stone")[0]
	n.pos = Vector2(w.brain.beside(Vector2i(int(ore.x), int(ore.y)), Vector2i(n.pos.floor()), -1)) + Vector2(0.5, 0.5)
	var bag := Inventory.new()
	for k in 4:
		w.work_mine(n, ore, bag)
	var mined := bag.total()
	for id in bag.ids():
		(cart.store as Inventory).add(id, bag.count(id))
		bag.remove(id, bag.count(id))
	var g0 := Census.goods(w)
	var p := _player_below(w, -1, Vector2i(route[route.size() - 1]))
	cart.pos = Vector2(route[route.size() - 1]) + Vector2(0.5, 0.5)
	cart.owner = World.PLAYER
	check(w.carts.hitch(cart, World.PLAYER) == "", "the player takes hold of the minecart")
	check(w.carts.pull_speed_for(cart) > Carts.pull_speed(), "on its rails a minecart is pulled faster than a handcart (%.2f against %.2f)" % [w.carts.pull_speed_for(cart), Carts.pull_speed()])
	var on_track := true
	var steps := 0
	for i in range(route.size() - 1, -1, -1):        # walk the route back to the adit, a little at a time
		var goal := Vector2(route[i]) + Vector2(0.5, 0.5)
		for k in 20:
			p.pos = p.pos.move_toward(goal, 0.2)
			w.carts.update(0.1)
			steps += 1
			if not mw.track_at(-1, Vector2i((cart.pos as Vector2).floor())):
				on_track = false
	check(on_track and str(cart.puller) == World.PLAYER, "pulled along the track, the minecart stays on its rails all the way (%d steps)" % steps)
	check((cart.pos as Vector2).distance_to(Vector2(inner) + Vector2(0.5, 0.5)) < 1.6, "and comes to the adit's inner mouth behind the player (%s)" % str(cart.pos))
	check(int(Census.goods(w).get("iron_ore", 0) + Census.goods(w).get("coal", 0) + Census.goods(w).get("copper_ore", 0)) == int(g0.get("iron_ore", 0) + g0.get("coal", 0) + g0.get("copper_ore", 0))
			and (cart.store as Inventory).total() == mined, "the %d units of ore in it are carried, not made or lost (the goods census unchanged)" % mined)
	check(float(cart.get("worn", 0.0)) > 0.0, "the minecart wears by the tiles pulled (DVW-B4), as a handcart")
	# off the rails it stays where they end
	var end := Vector2(cart.pos)
	var off_cell := Vector2i(-1, -1)
	for c in lm.floor_cells():
		if not mw.track_at(-1, c) and Vector2(c).distance_to(Vector2(p.pos)) < 6.0 and not lm.find_path(Vector2i(p.pos.floor()), c).is_empty():
			off_cell = c
	var walk := lm.find_path(Vector2i(p.pos.floor()), off_cell)
	for pt in walk:
		for k in 10:
			p.pos = p.pos.move_toward(Vector2(pt) + Vector2(0.5, 0.5), 0.2)
			w.carts.update(0.1)
	var stayed := true
	if not mw.track_at(-1, Vector2i((cart.pos as Vector2).floor())):
		stayed = false
	check(stayed, "walked off the track, the minecart stays on its rails (%s, puller '%s')" % [str(cart.pos), str(cart.puller)])
	if p.pos.distance_to(cart.pos) > float(MineWorks.cfg().minecart.let_go):
		check(str(cart.puller) == "" and _st(w, "minecart_let_go") >= 1, "far enough off, the puller lets go of it")
	check(end.distance_to(cart.pos) < 3.0, "it did not leave the rails to follow")


func _test_minecart_through_the_mouth() -> void:
	var w := _world(1)
	var lm := _gallery(w)
	var mw := w.mine_works
	var adit: Dictionary = w.underground.portals[0]
	var outer: Vector2i = adit.ends[0].stand
	var inner: Vector2i = adit.ends[1].stand
	var n := _hand(w, -1, inner)
	n.inv.add("track_section", 3)
	n.inv.add("minecart")
	mw.lay_track(n, inner)
	var sd := mw.set_down_minecart(n, World.PLAYER, inner)
	var cart: Dictionary = sd.cart
	(cart.store as Inventory).add("coal", 5)
	w.stats["mined_coal"] = float(_st(w, "mined_coal") + 5)        # the test's coal, entered in the books
	var p := _player_below(w, -1, inner)
	w.carts.hitch(cart, World.PLAYER)
	var r := w.player_through(Vector2.DOWN)
	check(r.has("refused") and w.player_level == -1 and str(r.refused).contains("rails"), "without track outside the mouth, the minecart does not go out: %s" % str(r.get("refused", "")))
	p.pos = Vector2(outer) + Vector2(0.5, 0.5)
	w.player_level = 0
	n.depth = 0
	n.pos = Vector2(outer) + Vector2(0.5, 0.5)
	check(mw.lay_track(n, outer).result == "ok", "track is laid on the stand outside the adit (the mine's yard)")
	n.depth = -1
	n.pos = Vector2(inner) + Vector2(0.5, 0.5)
	w.player_level = -1
	p.pos = Vector2(inner) + Vector2(0.5, 0.5)
	cart.pos = Vector2(inner) + Vector2(0.5, 1.0)
	var g0 := Census.goods(w)
	r = w.player_through(Vector2.DOWN)
	check(r.get("level", -9) == 0 and World.level_of(cart) == 0 and Vector2i((cart.pos as Vector2).floor()) == outer and str(cart.puller) == World.PLAYER,
			"with track on both sides, the minecart comes out of the adit with the player, on its rails")
	check(Census.goods(w) == g0 and (cart.store as Inventory).count("coal") == 5 and _st(w, "minecart_crossings") == 1, "with its load, nothing made or lost")
	# a villager pulling a minecart goes through by the same rule
	w.carts.park(cart)
	cart.owner = World.hh_ref(n.household)
	n.depth = 0
	n.pos = Vector2(outer) + Vector2(0.5, 0.5)
	check(w.carts.hitch(cart, World.npc_ref(n.id)) == "", "a villager of its household takes hold of it")
	var leg := w.underground.next_leg(0, -1)
	w._npc_through(n, leg, {})
	check(n.depth == -1 and World.level_of(cart) == -1 and Vector2i((cart.pos as Vector2).floor()) == inner, "and takes it back into the gallery through the adit, as the player does")
	var hc := w.carts.place(World.hh_ref(n.household), Vector2(outer) + Vector2(0.5, 0.5))
	w.carts.park(cart)
	n.depth = 0
	n.pos = Vector2(outer) + Vector2(0.5, 0.5)
	w.carts.hitch(hc, World.npc_ref(n.id))
	w._npc_through(n, leg, {})
	check(n.depth == -1 and World.level_of(hc) == 0 and str(hc.puller) == "", "a handcart is still set down at the mouth (no rails for it)")


# ---------------------------------------------------------------- saves ----------------------
func _test_save_load() -> void:
	var w := _world(3)
	var lm := _gallery(w)
	var mw := w.mine_works
	var face := _face(w, lm)
	var n := _hand(w, -1, face[0])
	n.inv.add("timber_support", 2)
	n.inv.add("track_section", 2)
	n.inv.add("minecart")
	mw.place_support(n, face[0])
	for k in MineWorks.cell_units():
		mw.dig(n, face[1], n.inv)
	var half := Vector2i(-1, -1)
	for cc in lm.cells():
		if mw.rock_refusal(-1, cc) == "":
			half = cc
			break
	for d: Vector2i in VillageMap.SIDES:
		if not lm.is_solid(half + d):
			n.pos = Vector2(half + d) + Vector2(0.5, 0.5)
	mw.dig(n, half, n.inv)
	mw.dig(n, half, n.inv)
	n.pos = Vector2(face[0]) + Vector2(0.5, 0.5)
	mw.lay_track(n, face[0])
	mw.lay_track(n, face[1])
	var sd := mw.set_down_minecart(n, World.PLAYER, face[1])
	(sd.cart.store as Inventory).add("stone", 3)
	n.inv.remove("stone", 3)
	var cl := _cave(w)
	var p := _player_below(w, -2, cl.floor_cells()[cl.floor_cells().size() / 2])
	var d := w.to_dict()
	check(d.has("mine_works") and int(d.save_version) == 17 and int(d.underground.player_level) == -2, "the save is still version 17, with the works and the player in the cave")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var lm2 := _gallery(w2)
	var mw2 := w2.mine_works
	check(not lm2.is_solid(face[1]) and lm2.is_solid(half) and mw2.cut_at(-1, half) == 2 and mw2.support_at(-1, face[0]) and mw2.track_at(-1, face[1]),
			"loaded: the cell cut through is floor again, the half-cut cell keeps its 2 units cut, the support and the track stand")
	check(not lm2.find_path(w2.underground.portals[0].ends[1].stand, face[1]).is_empty(), "the reopened cell is on the gallery's A* at once")
	var c2: Dictionary = w2.carts.carts.filter(func(c): return Carts.kind_of(c) == "minecart")[0]
	check(World.level_of(c2) == -1 and (c2.store as Inventory).count("stone") == 3 and (c2.store as Inventory).max_stacks == int(MineWorks.cfg().minecart.stacks),
			"the minecart loads on its level with its load")
	check(w2.player_level == -2 and w2.player.pos.is_equal_approx(p.pos), "the player loads in the cave where they stood")
	check(JSON.stringify(w2.to_dict().mine_works) == JSON.stringify(d.mine_works) and JSON.stringify(w2.to_dict().carts) == JSON.stringify(d.carts),
			"saved again, the works and the carts are unchanged")
	check(mw2.ground_cut() == mw.ground_cut(), "the books of the rock cut are the same after the load")
	# a save from before MIN-F: no "mine_works", carts without kind or level
	var old: Dictionary = JSON.parse_string(JSON.stringify(d))
	old.erase("mine_works")
	old.carts.carts = (old.carts.carts as Array).filter(func(c): return not c.has("kind"))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.mine_works.opened.is_empty() and w3.mine_works.supports.is_empty() and w3.mine_works.track.is_empty() and _gallery(w3).is_solid(face[1]),
			"a version 17 save from before MIN-F loads with nothing cut, set up or laid")
	var v16: Dictionary = JSON.parse_string(JSON.stringify(old))
	v16.save_version = 16
	v16.erase("underground")
	v16.deposits = (v16.deposits as Array).filter(func(x): return int(x.get("level", 0)) == 0)
	v16.player.pos = [30.5, 40.5]
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), v16)
	check(w4.player_level == 0 and w4.deposits.filter(func(x): return World.level_of(x) == -2).size() == 3 and w4.villager_levels == [0, -1, -2],
			"a version 16 save loads on the surface with the cave's seams full")


func _test_determinism() -> void:
	var prints := []
	for k in 2:
		var w := _world(7)
		var lm := _gallery(w)
		var mw := w.mine_works
		var face := _face(w, lm)
		var n := _hand(w, -1, face[0])
		n.inv.add("timber_support", 2)
		mw.place_support(n, face[0])
		for i in 12:
			var next := Vector2i(-1, -1)
			for cc in lm.cells():
				if mw.rock_refusal(-1, cc) == "":
					next = cc
					break
			if next.x < 0:
				break
			for d: Vector2i in VillageMap.SIDES:
				if not lm.is_solid(next + d):
					n.pos = Vector2(next + d) + Vector2(0.5, 0.5)
			mw.dig(n, next, n.inv)
		prints.append(JSON.stringify(mw.to_dict()) + lm.to_text() + str(w.rng.state) + JSON.stringify(n.inv.to_dict()))
	check(prints[0] == prints[1], "the same seed and the same cuts give the same tunnels, goods and random stream")


## Q18-9: nothing is gated by a capability level: a level-0 village mines the gallery and the cave, and cuts tunnels.
func _test_level_zero_mines() -> void:
	var w := _world(1)
	w.player.home = ""                            # MIN-D2: no resident player
	for o: NPC in w.npcs:                         # MIN-SKILLCAP: level 1 needs someone able to mine (a pickaxe), not a job title
		o.inv.remove("pickaxe", o.inv.count("pickaxe"))
	for hh in w.households:
		hh.pantry.remove("pickaxe", hh.pantry.count("pickaxe"))
	w.manor_work.yard.remove("pickaxe", w.manor_work.yard.count("pickaxe"))
	w.discovery.dawn()
	check(w.discovery.level() == 0, "a village where nobody holds a pickaxe is at mining level 0")
	var n: NPC = w.brain._first_with_job("laborer")
	n.plan.clear()
	n.inv.add("pickaxe")
	n.inv.add("mallet")
	var cave_seam: Dictionary = w.deposits.filter(func(d): return World.level_of(d) == -2 and d.ore == "coal")[0]
	n.depth = -2
	n.pos = Vector2(w.brain.beside(Vector2i(int(cave_seam.x), int(cave_seam.y)), Vector2i(int(cave_seam.x), int(cave_seam.y)), -2)) + Vector2(0.5, 0.5)
	var a0 := int(cave_seam.amount)
	var r := w.work_mine(n, cave_seam, n.inv)
	check(r.result == "ok" and int(cave_seam.amount) < a0 and _st(w, "mined_coal") >= 1, "a level-0 village's villager mines the cave's coal by the surface's own swing")
	var lm := _gallery(w)
	var face := _face(w, lm)
	n.depth = -1
	n.pos = Vector2(face[0]) + Vector2(0.5, 0.5)
	n.inv.add("timber_support")
	check(w.mine_works.place_support(n, face[0]).result == "ok" and w.mine_works.dig(n, face[1], n.inv).result == "ok" and w.discovery.level() == 0,
			"and sets up a support and cuts the rock, the level still 0 (reported, never a gate)")


## A miner whose ore is left only in the cave walks in through its mouth, mines there and comes out with the ore.
func _test_villager_into_cave() -> void:
	var w := _world(1)
	for d in w.deposits:
		if World.level_of(d) != -2:
			d.amount = 0
			if d.has("host"):
				d.host.amount = 0
	for b in w.boulders:
		b.amount = 0
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
	var m0 := {}
	for o in ["iron_ore", "coal", "copper_ore"]:
		m0[o] = _st(w, "mined_" + o)
	var cross0 := _st(w, "portal_crossings")
	var went_in := false
	var mined_in := false
	var out_with_ore := false
	var bad_level := 0
	var ore_of := func(n: NPC) -> int: return n.inv.count("iron_ore") + n.inv.count("coal") + n.inv.count("copper_ore")
	var last: int = ore_of.call(miner)
	for k in 6000:
		w.update(0.5)
		for n: NPC in w.npcs:
			if n.alive and n.depth != 0 and w.underground.is_solid(n.depth, n.cell()):
				bad_level += 1
			if n.alive and n.depth != w.level_at(n.pos):
				bad_level += 1
		var ore: int = ore_of.call(miner)
		if miner.depth == -2:
			went_in = true
			if ore > last:
				mined_in = true
		elif mined_in and miner.depth == 0 and ore > 0:
			out_with_ore = true
			break
		last = ore
	check(went_in, "a miner walks into the cave through its mouth when its seams are the village's last (MIN-H, the router)")
	check(mined_in, "they mine a cave seam there")
	check(out_with_ore, "and carry the ore out through the cave's mouth")
	check(_st(w, "portal_crossings") - cross0 >= 2 and bad_level == 0, "the crossings are counted and every villager's level agrees with the ground under them (%d disagreements)" % bad_level)
	var fell := {}
	for d in w.deposits:
		var f: int = int(start["%d,%d,%d" % [World.level_of(d), int(d.x), int(d.y)]]) - int(d.amount)
		fell[d.ore] = int(fell.get(d.ore, 0)) + f
	var ok := true
	for o in m0:
		if int(fell.get(o, 0)) != _st(w, "mined_" + o) - int(m0[o]):
			ok = false
	check(ok, "every unit taken from the cave is counted mined_<ore>, unit for unit")


# ---------------------------------------------------------------- the scene ------------------
func _run_scene() -> void:
	main.new_game()
	var w: World = main.world
	check(main.level_views.size() == 2 and main.surface_works != null, "two level views (the gallery and the cave) and the yard's track view are built")
	var spec: Dictionary = w.underground.specs["hill_cave"]
	var door := Vector2i(int(spec.portal.door[0]), int(spec.portal.door[1]))
	check(main.view.tile_value(main.view.layer(str(spec.mouth.layer)), door) == int(spec.mouth.tile), "the cave's mouth is drawn in the hill's rock face")
	var p := w.player
	var mouth: Dictionary = w.underground.portals[1]
	p.pos = Vector2(mouth.ends[0].stand) + Vector2(0.5, 0.5)
	main._through_portal(Vector2.UP)
	main._sync_levels(0.0)
	var cave_view: LevelView = main.level_views["hill_cave"]
	var gal_view: LevelView = main.level_views["adit_gallery"]
	check(w.player_level == -2 and cave_view.visible and not gal_view.visible and main.view.modulate.a == 0.0,
			"walking into the cave's mouth shows the cave alone, the surface faded out")
	# cut a cell in the cave: the view draws it as floor
	var lm := _cave(w)
	var face := _face(w, lm)
	p.pos = Vector2(face[0]) + Vector2(0.5, 0.5)
	p.inv.add("pickaxe")
	p.inv.add("mallet")
	p.inv.add("timber_support")
	w.mine_works.place_support(p, face[0])
	for k in MineWorks.cell_units():
		w.mine_works.dig(p, face[1], p.inv, p.tool_of("pickaxe"))
	check(not lm.is_solid(face[1]) and cave_view.floor_layer.get_cell_source_id(face[1]) >= 0 and cave_view.wall_layer.get_cell_source_id(face[1]) < 0,
			"a cell cut open is drawn as floor in the cave's view at once")
	for cc in lm.cells():                              # stand at a face that may be cut, facing it
		if w.mine_works.rock_refusal(-2, cc) != "":
			continue
		for d: Vector2i in VillageMap.SIDES:
			if not lm.is_solid(cc + d):
				p.pos = Vector2(cc + d) + Vector2(0.5, 0.5)
				main.player_sprite.face(Vector2(-d))
		break
	main._find_target()
	var labels: Array = main.target_options.map(func(t): return str(t.get("label", "")))
	print("  targets at the face: ", labels)
	check(labels.any(func(l): return l.begins_with("Cut into the rock") or l.begins_with("The rock face")), "at the new face the player is offered the rock to cut")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
