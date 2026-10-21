extends SceneTree
## MIN-F2: the owner's MIN-F-Q1..Q5 decisions (docs/directives/2026-10-21_build17_minf_q1_q5_decisions.md section 10;
## docs/build17/MIN_F2_STRUCTURE.md): 1 collapse and support deterioration; 2 repair and replacement consume real goods;
## 3 hidden ore exposed by tunnelling and depleted, never known before; 4 the manor's tunnel job done and paid; 5 the
## minecart preferred when cheaper, carrying otherwise; 6 shafts between levels, villagers through them, goods by hand
## only; 7 a backfill order the player made and paid, done by a worker; 8 no backfill without the player; 9 backfill's
## limited structural effect; 10 backfill dug out again and conserved; 11 save, load and deterministic replay. Run:
##   godot --headless --path game --script res://tests/underground_struct_test.gd

const Census := preload("res://tests/census.gd")

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
	_test_collapse()
	_test_repair()
	_test_hidden_ore()
	_test_manor_tunnel()
	_test_minecart_preference()
	_test_shafts()
	_test_backfill_order()
	_test_no_autonomous_backfill()
	_test_backfill_structure()
	_test_backfill_dug_again()
	_test_save_and_replay()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- helpers --------------------
func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0))


func _gallery(w: World) -> LevelMap:
	return w.underground.level_map("adit_gallery")


func _cave(w: World) -> LevelMap:
	return w.underground.level_map("hill_cave")


## The first floor cell (row order) with a rock cell beside it a tunnel may be cut into under a support: [floor, rock].
func _face(w: World, lm: LevelMap, skip := {}) -> Array:
	for f in lm.floor_cells():
		for d: Vector2i in VillageMap.SIDES:
			var c := f + d
			if skip.has(c):
				continue
			if lm.is_solid(c) and w.deposit_at(c, lm.level).is_empty() and lm.region.grow(-1).has_point(c) and w.underground.under_rock(w.map, c) \
					and w.underground.hidden_at(lm.level, c).is_empty() and w.mine_works.shaft_at(lm.level, c).is_empty():
				return [f, c]
	return []


func _hand(w: World, level: int, cell: Vector2i, job := "laborer") -> NPC:
	var n: NPC = w.brain._first_with_job(job)
	if n == null:
		n = w.npcs[0]
	n.plan.clear()
	n.depth = level
	n.pos = Vector2(cell) + Vector2(0.5, 0.5)
	for t in ["pickaxe", "mallet"]:
		if not n.inv.has(t):
			n.inv.add(t)
	return n


func _stand_beside(n: NPC, lm: LevelMap, c: Vector2i) -> void:
	for d: Vector2i in VillageMap.SIDES:
		if not lm.is_solid(c + d):
			n.pos = Vector2(c + d) + Vector2(0.5, 0.5)
			return


## Cut cell c open completely (the hand stands beside it).
func _cut(w: World, n: NPC, lm: LevelMap, c: Vector2i) -> bool:
	_stand_beside(n, lm, c)
	var ok := true
	for k in MineWorks.cell_units():
		ok = ok and w.mine_works.dig(n, c, n.inv).result == "ok"
	return ok and not lm.is_solid(c)


## A world one day on, its dawn run (MineWorks.dawn only: nothing else moves).
func _next_day(w: World) -> void:
	w.minutes += 1440.0
	w.mine_works.dawn()


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


## A tunnel cell cut under a support at its face: [w, n, lm, support cell, cut cell].
func _tunnel(seed_value := 1) -> Array:
	var w := _world(seed_value)
	var lm := _gallery(w)
	var face := _face(w, lm)
	var n := _hand(w, -1, face[0])
	n.inv.add("timber_support", 4)
	w.mine_works.place_support(n, face[0])
	_cut(w, n, lm, face[1])
	return [w, n, lm, face[0], face[1]]


# ---------------------------------------------------------------- 1 collapse -----------------
func _test_collapse() -> void:
	var t := _tunnel()
	var w: World = t[0]
	var n: NPC = t[1]
	var lm: LevelMap = t[2]
	var s: Vector2i = t[3]
	var c: Vector2i = t[4]
	var mw := w.mine_works
	var full := int(MineWorks.cfg().stability.full)
	check(mw.is_opened(-1, c) and mw.stability(-1, c) >= float(MineWorks.cfg().stability.threshold) and mw.collapse_chance(-1, c) == 0,
			"a cell cut beside a sound support is held (stability %.2f, no chance of collapse)" % mw.stability(-1, c))
	var rng0 := w.rng.state
	_next_day(w)
	check(mw.support_condition(-1, s) == full - int(MineWorks.cfg().stability.decay_per_day) and w.rng.state == rng0,
			"a dawn wears the support by decay_per_day; the weighing draws nothing from the world's random stream")
	var natural_before := lm.floor_cells().size()
	var fell_day := -1
	var chance_seen := 0
	for d in 200:
		if mw.collapse_chance(-1, c) > 0 and chance_seen == 0:
			chance_seen = d
		n.pos = Vector2(c) + Vector2(0.5, 0.5)               # someone stands in the passage
		_next_day(w)
		if lm.is_solid(c):
			fell_day = w.day()
			break
	check(chance_seen > 0 and fell_day > 0, "as the support wears the cell weakens (a chance from about day %d) and caves in on day %d" % [chance_seen, fell_day])
	check(mw.rubble_at(-1, c) == MineWorks.cell_units() and lm.is_solid(c) and _st(w, "tunnel_collapses") == 1, "the collapse fills the cell with rubble (%d units) and blocks it" % mw.rubble_at(-1, c))
	check(not lm.is_solid(n.cell()) and n.cell() != c, "whoever stood there steps out to the nearest floor (%s)" % str(n.cell()))
	var p := lm.find_path(w.underground.portals[0].ends[1].stand, c)
	check(p.is_empty() or Vector2i(p[p.size() - 1]) != c, "the level's paths no longer go through the fallen cell")
	check(lm.floor_cells().size() == natural_before - 1, "only that cell changed: the natural gallery is never weighed (no global event)")
	var t2 := _tunnel()
	var w2: World = t2[0]
	for d in 200:
		_next_day(w2)
		if (t2[2] as LevelMap).is_solid(t2[4]):
			break
	check(w2.day() == fell_day, "the same world and the same work collapse on the same day (deterministic, by the cell and the day)")
	# unsupported: an open cell with no support has the greatest chance
	var t3 := _tunnel()
	var w3: World = t3[0]
	w3.mine_works.supports.clear()
	var ch: int = w3.mine_works.collapse_chance(-1, t3[4])
	check(ch == int(float(MineWorks.cfg().stability.threshold) * float(MineWorks.cfg().stability.rate) * 1000.0),
			"an unsupported excavation has the full chance (%d per mille a day)" % ch)
	# clearing the rubble is real excavation: support first, then spoil comes out
	var g0 := Census.goods(w)
	var sp0 := n.inv.count("spoil")
	mw.supports.clear()
	check(mw.dig_refusal(n, c).contains("timber support"), "fallen rock is not dug out unsupported")
	n.pos = Vector2(s) + Vector2(0.5, 0.5)
	if mw.support_at(-1, s):
		mw.supports.clear()
	mw.place_support(n, s)
	var items := []
	_stand_beside(n, lm, c)
	for k in MineWorks.cell_units():
		items.append(str(mw.dig(n, c, n.inv).get("item", "")))
	check(items.all(func(i): return i == "spoil") and not lm.is_solid(c) and mw.rubble_at(-1, c) == 0, "the rubble comes out as spoil only (%s) and the passage reopens" % str(items))
	check(n.inv.count("spoil") - sp0 == MineWorks.cell_units() and int(Census.goods(w).get("spoil", 0)) - int(g0.get("spoil", 0)) == MineWorks.cell_units(),
			"each unit cleared is in the digger's pack: the goods census rises by exactly the rubble")


# ---------------------------------------------------------------- 2 repair -------------------
func _test_repair() -> void:
	var t := _tunnel()
	var w: World = t[0]
	var n: NPC = t[1]
	var s: Vector2i = t[3]
	var mw := w.mine_works
	for d in 20:
		_next_day(w)
	var worn := mw.support_condition(-1, s)
	n.pos = Vector2(s) + Vector2(0.5, 0.5)
	n.inv.remove("plank", n.inv.count("plank"))
	check(worn < int(MineWorks.cfg().stability.full) and mw.repair_refusal(n, s).contains("plank"), "a worn support (%d) needs a plank to repair" % worn)
	n.inv.add("plank", 2)
	var u0 := _st(w, "used_plank")
	var r := mw.repair(n, s)
	check(r.result == "ok" and mw.support_condition(-1, s) == int(MineWorks.cfg().stability.full) and n.inv.count("plank") == 1 and _st(w, "used_plank") == u0 + 1,
			"repaired with one plank (used up, counted) it is whole again")
	# worn to nothing it fails and is gone; a new one is set up from real goods
	for d in 200:
		_next_day(w)
		if not mw.support_at(-1, s):
			break
	check(not mw.support_at(-1, s) and _st(w, "supports_failed") == 1, "a support never repaired wears out and fails")
	var ts := n.inv.count("timber_support")
	check(mw.place_support(n, s).result == "ok" and n.inv.count("timber_support") == ts - 1, "it is replaced by setting up another, from the pack")


# ---------------------------------------------------------------- 3 hidden ore ---------------
func _test_hidden_ore() -> void:
	var w := _world(1)
	var lm := _gallery(w)
	var mw := w.mine_works
	var hid: Array = w.underground.hidden.filter(func(h): return int(h.level) == -1)
	check(hid.size() == 2 and w.deposits.all(func(d): return w.underground.hidden_at(World.level_of(d), Vector2i(int(d.x), int(d.y))).is_empty()),
			"the gallery's rock holds two hidden seams, none of them in World.deposits")
	check(Underground.create(1, w.map).fingerprint() == w.underground.fingerprint(), "the hidden ore is part of the world's generation from the seed (the same every time)")
	var h: Dictionary = hid[0]
	var hc := Vector2i(int(h.x), int(h.y))
	var known := false
	for n: NPC in w.npcs:
		var d: Dictionary = w.nearest_seam(n, [str(h.ore)])
		if not d.is_empty() and int(d.x) == hc.x and int(d.y) == hc.y and World.level_of(d) == -1:
			known = true
	check(not known and w.deposit_at(hc, -1).is_empty(), "no villager's search finds it: nobody knows of hidden ore")
	# a tunnel toward it: the rock between is the earlier workings (a fixture), the last cell cut under a support
	var target := Vector2i(-1, -1)
	for d: Vector2i in VillageMap.SIDES:
		var c := hc + d
		if lm.is_solid(c) and lm.region.grow(-1).has_point(c) and w.underground.under_rock(w.map, c) and w.deposit_at(c, -1).is_empty():
			target = c
			break
	var prev := {}
	var q: Array[Vector2i] = [target]
	prev[target] = target
	var reach := Vector2i(-1, -1)
	var qi := 0
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		if not lm.is_solid(c):
			reach = c
			break
		for d: Vector2i in VillageMap.SIDES:
			var nb := c + d
			if prev.has(nb) or not lm.region.grow(-1).has_point(nb) or not w.underground.under_rock(w.map, nb) or not w.deposit_at(nb, -1).is_empty() \
					or not w.underground.hidden_at(-1, nb).is_empty():
				continue
			prev[nb] = c
			q.append(nb)
	var path: Array[Vector2i] = []
	var c2 := prev.get(reach, target) as Vector2i
	while c2 != target:
		path.append(c2)
		c2 = prev[c2]
	for pc in path:
		mw._open(-1, pc)                                  # the workings already driven to here
	var stand: Vector2i = path[path.size() - 1] if not path.is_empty() else reach
	var n := _hand(w, -1, stand)
	n.inv.add("timber_support")
	mw.place_support(n, stand)
	var found0 := _st(w, "found_" + str(h.ore))
	var ex := []
	for k in MineWorks.cell_units():
		var r := mw.dig(n, target, n.inv)
		ex.append_array(r.get("exposed", []))
	var seam: Dictionary = w.deposit_at(hc, -1)
	check(ex.size() == 1 and not seam.is_empty() and str(seam.ore) == str(h.ore) and int(seam.amount) == int(h.amount) and seam.has("host"),
			"cutting the cell beside it exposes it: an ordinary seam of %d %s with host rock, on its level" % [int(h.amount), str(h.ore)])
	check(_st(w, "found_" + str(h.ore)) - found0 == int(h.amount) and w.underground.hidden_at(-1, hc).is_empty(), "it enters the books as found_%s and is hidden no more" % str(h.ore))
	var mined := 0
	n.inv.add("pickaxe", 30)
	for k in 200:
		var r := w.work_mine(n, w.deposit_at(hc, -1), n.inv)
		if r.result != "ok":
			break
		mined += int(r.n)
		if int(seam.amount) <= 0:
			break
	check(int(seam.amount) == 0 and mined == int(h.amount), "mined by work_mine it is worked out unit by unit (%d)" % mined)
	var d2 := World.new()
	d2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var rec: Array = d2.deposits.filter(func(x): return World.level_of(x) == -1 and int(x.x) == hc.x and int(x.y) == hc.y)
	check(rec.size() == 1 and int(rec[0].amount) == 0 and d2.underground.hidden_at(-1, hc).is_empty(), "saved and loaded, it stays worked out: never regenerated, never hidden again")
	check(not d2.underground.hidden.is_empty() and d2.underground.hidden.all(func(x): return d2.deposit_at(Vector2i(int(x.x), int(x.y)), int(x.level)).is_empty()),
			"the ore still hidden stays out of the deposits after a load")


# ---------------------------------------------------------------- 4 manor tunnel job ---------
func _test_manor_tunnel() -> void:
	var w := _world(1)
	var lm := _gallery(w)
	var mw := w.mine_works
	var mwork := w.manor_work
	check(mw.manor_face().is_empty(), "with no support anywhere the manor has no face to tunnel")
	var face := _face(w, lm)
	var hand := _hand(w, -1, face[0], "manor_hand")
	hand.inv.add("timber_support")
	mw.place_support(hand, face[0])
	hand.depth = 0
	hand.pos = Vector2(48.5, 12.5)
	w.treasury = 2000
	mwork.yard.remove("stone", mwork.yard.count("stone"))
	mwork.post_tunnels()
	var jobs: Array = mwork.jobs.filter(func(j): return j.kind == "tunnel")
	check(jobs.size() == 1 and int(jobs[0].wage) == ManorWork.excavate_wage() and int(jobs[0].level) == -1, "the reeve posts one tunnel job at the supported face (wage %d, the quarry rate)" % int(jobs[0].wage) if not jobs.is_empty() else "the reeve posts one tunnel job")
	if jobs.is_empty():
		return
	var j: Dictionary = jobs[0]
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "laborer":
			n = o
			break
	if n == null:
		n = w.npcs[1]
	if not n.inv.has("pickaxe"):
		n.inv.add("pickaxe")
	n.depth = 0
	n.pos = Vector2(48.5, 11.5)
	n.plan.clear()
	var coins0 := w.total_coins()
	var t0 := w.treasury
	var nc0 := n.coins
	var opened0 := mw.opened.size()
	var stone_yard0 := mwork.yard.count("stone")
	var taken0 := mw.ground_cut()
	check(mwork.take(j, World.npc_ref(n.id)) and w.treasury == t0 - int(j.wage), "a labourer takes it: its wage is set aside from the treasury")
	w.minutes = floorf(w.minutes / 1440.0) * 1440.0 + 8.0 * 60.0
	mwork.plan(n)
	var done := false
	for k in 3000:
		w.update(0.5)
		if mwork.job(int(j.id)).is_empty():
			done = true
			break
	var taken1 := mw.ground_cut()
	var cut := int(taken1.get("stone", 0)) + int(taken1.get("spoil", 0)) - int(taken0.get("stone", 0)) - int(taken0.get("spoil", 0))
	check(done and cut == int(j.qty), "the labourer walks below, cuts a load of %d at the face and the job is done (%d cut)" % [int(j.qty), cut])
	check(mw.opened.size() > opened0, "the tunnel is longer: real rock was cut (%d cells opened)" % (mw.opened.size() - opened0))
	check(mwork.yard.count("stone") > stone_yard0 and n.inv.count("stone") == 0, "the stone is in the works yard, not the worker's pack")
	check(n.coins - nc0 >= int(j.wage) and w.total_coins() == coins0, "the wage is paid from the treasury's funds; no coin is made or lost")


# ---------------------------------------------------------------- 5 minecart preference -----
## A household minecart on track from beside a gallery seam to the rails' end near the adit; the miner at the seam.
func _cart_world() -> Array:
	var w := _world(1)
	var lm := _gallery(w)
	var mw := w.mine_works
	var inner: Vector2i = w.underground.portals[0].ends[1].stand
	var far := Vector2i(-1, -1)
	var bd := -1.0
	for d in w.deposits:
		if World.level_of(d) == -1 and str(d.ore) != "stone":
			var st: Vector2i = w.brain.beside(Vector2i(int(d.x), int(d.y)), inner, -1)
			var dist := mw._walk_len(-1, inner, st)
			if dist < 1e5 and dist > bd:
				bd = dist
				far = st
	var route := _four(lm.find_path(inner + Vector2i(0, -1), far))
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "miner":
			n = o
			break
	n.plan.clear()
	n.depth = -1
	for t in ["mallet"]:
		n.inv.add(t)
	n.inv.add("track_section", route.size() + 2)
	for pt in route:
		n.pos = Vector2(pt) + Vector2(0.5, 0.5)
		mw.lay_track(n, pt)
	n.inv.add("minecart")
	n.pos = Vector2(far) + Vector2(0.5, 0.5)
	mw.set_down_minecart(n, World.hh_ref(n.household), far)
	return [w, n, lm, far, route]


func _test_minecart_preference() -> void:
	var t := _cart_world()
	var w: World = t[0]
	var n: NPC = t[1]
	var mw := w.mine_works
	var far: Vector2i = t[3]
	var cart: Dictionary = w.carts.carts.filter(func(c): return Carts.kind_of(c) == "minecart")[0]
	for o in ["iron_ore", "coal", "copper_ore", "stone"]:
		n.inv.remove(o, n.inv.count(o))
	n.inv.add("iron_ore", int(GameData.b("carry_ore")))
	var hc := mw.haul_costs(n)
	check(not hc.is_empty() and float(hc.cart_cost) < float(hc.carry), "at the far seam the cart's way is cheaper (%.2f against %.2f cells walked a unit)" % [float(hc.get("cart_cost", 0)), float(hc.get("carry", 0))])
	var g0 := Census.goods(w)
	var plan := mw.cart_haul_plan(n, true)
	check(not plan.is_empty() and str(plan[1].get("act", "")) == "mc_load", "the miner plans to load the minecart rather than carry out")
	n.plan = plan
	for k in 200:
		if n.plan.is_empty():
			break
		w._run_plan(n, 0.25, 0.5)
		w.carts.update(0.25)
	check((cart.store as Inventory).count("iron_ore") == int(GameData.b("carry_ore")) and n.inv.count("iron_ore") == 0 and str(cart.get("claim", "")) == World.npc_ref(n.id),
			"the load is in the cart's own store, and the cart is claimed for this miner")
	var other: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != n and o.household == n.household and o.role == "adult":
			other = o
	if other != null:
		other.depth = -1
		other.pos = n.pos
		other.inv.add("iron_ore", 6)
		check(mw.cart_haul_plan(other, true).is_empty(), "another of the household cannot claim the cart while it is claimed")
		other.inv.remove("iron_ore", 6)
		other.depth = 0
	# fill it to a trip, then haul along the rails to their end and take the load
	var hauled := false
	var added := 0
	for trip in 6:
		n.inv.add("iron_ore", int(GameData.b("carry_ore")))
		added += int(GameData.b("carry_ore"))
		w.stats["mined_iron_ore"] = float(_st(w, "mined_iron_ore") + int(GameData.b("carry_ore")))
		n.pos = Vector2(far) + Vector2(0.5, 0.5)
		n.plan = mw.cart_haul_plan(n, true)
		var off_rails := 0
		for k in 600:
			if n.plan.is_empty():
				break
			w._run_plan(n, 0.25, 0.5)
			w.carts.update(0.25)
			if not mw.track_at(-1, Vector2i((cart.pos as Vector2).floor())):
				off_rails += 1
		if _st(w, "minecart_hauls") > 0:
			hauled = off_rails == 0
			break
	var unload: Array = mw._unload_point(-1, far)
	check(hauled and Vector2i((cart.pos as Vector2).floor()).distance_to(unload[0]) <= 1.5 and (cart.store as Inventory).total() == 0,
			"full, the miner pulls it along the rails to their end by the adit and takes the load out (on the rails all the way)")
	check(n.inv.count("iron_ore") >= int(MineWorks.cfg().minecart.trip) and not cart.has("claim") and str(cart.puller) == "", "the load is in the miner's pack; the cart is let go and unclaimed")
	check(int(Census.goods(w).get("iron_ore", 0)) - int(g0.get("iron_ore", 0)) == added, "every unit loaded, hauled and taken out is the same ore: the census rises only by the %d units the test handed over" % added)
	# manual fallback: the miner at the rails' end (near the way out) carries; and with no cart at all
	n.pos = Vector2(unload[0]) + Vector2(0.5, 0.5)
	check(mw.cart_haul_plan(n, true).is_empty(), "at the rails' end by the way out, carrying is cheaper: the miner carries")
	var t2 := _cart_world()
	var w2: World = t2[0]
	var n2: NPC = t2[1]
	w2.carts.carts.clear()
	n2.inv.add("iron_ore", 6)
	check(w2.mine_works.cart_haul_plan(n2, true).is_empty(), "with no minecart the miner carries by hand, as before")
	var t3 := _cart_world()
	var w3: World = t3[0]
	var n3: NPC = t3[1]
	var c3: Dictionary = w3.carts.carts.filter(func(c): return Carts.kind_of(c) == "minecart")[0]
	(c3.store as Inventory).add("stone", int(MineWorks.cfg().minecart.capacity))
	n3.inv.add("iron_ore", 6)
	check(w3.mine_works.cart_haul_plan(n3, true).is_empty() and w3.carts.room(c3) == 0, "a full cart (capacity %d) is not chosen" % int(MineWorks.cfg().minecart.capacity))
	# the miner's own decision (NPCBrain._miner) takes the cart when it is practical
	var t4 := _cart_world()
	var w4: World = t4[0]
	var n4: NPC = t4[1]
	n4.inv.add("iron_ore", 6)
	w4.minutes = floorf(w4.minutes / 1440.0) * 1440.0 + 9.0 * 60.0
	n4.plan.clear()
	w4.brain.decide(n4)
	check(n4.plan.any(func(s): return str(s.get("act", "")) == "mc_load"), "the miner's own work decision chooses the minecart at the far seam (%s)" % n4.doing)


# ---------------------------------------------------------------- 6 shafts -------------------
## The first gallery floor cell a shaft may be sunk at to the cave, with a support near: [w, n, s].
func _shaft_world(seed_value := 1) -> Array:
	var w := _world(seed_value)
	var lm := _gallery(w)
	var mw := w.mine_works
	var n := _hand(w, -1, lm.floor_cells()[0])
	n.inv.add("timber_support", 4)
	n.inv.add("ladder", 2)
	for s in lm.floor_cells():
		var beside := Vector2i(-1, -1)
		for d: Vector2i in VillageMap.SIDES:
			if not lm.is_solid(s + d):
				beside = s + d
		if beside.x < 0:
			continue
		n.pos = Vector2(beside) + Vector2(0.5, 0.5)
		var placed := false
		if not mw.supported(-1, s):
			if mw.support_refusal(n, beside) != "":
				continue
			mw.place_support(n, beside)
			placed = true
		if mw.shaft_refusal(n, s) == "" and not _cave(w).is_solid(s) and mw._ladder_wall(_cave(w), s).x >= 0:
			return [w, n, s]
		if placed:
			mw.supports.pop_back()
			n.inv.add("timber_support")
	return [w, n, Vector2i(-1, -1)]


func _test_shafts() -> void:
	var t := _shaft_world()
	var w: World = t[0]
	var n: NPC = t[1]
	var s: Vector2i = t[2]
	var mw := w.mine_works
	var lm := _gallery(w)
	check(s.x >= 0, "a gallery cell over the cave is found for a shaft (%s)" % str(s))
	if s.x < 0:
		return
	var items := []
	var r := {}
	for k in 20:
		r = mw.dig_shaft(n, s, n.inv)
		if r.result != "ok":
			break
		items.append(str(r.item))
		if r.done:
			break
	check(r.get("done", false) and items.size() == MineWorks.shaft_units() and lm.is_solid(s) and not _cave(w).is_solid(s),
			"the shaft is dug unit by unit (%s) through to the cave; its mouth is an open hole, its landing the cave's floor" % str(items))
	check(_st(w, "cut_stone") + _st(w, "cut_spoil") >= MineWorks.shaft_units(), "every unit of the shaft is real rock in the digger's pack (cut_)")
	var cart_n := n
	var l0 := n.inv.count("ladder")
	check(mw.ladder_refusal(n, s) == "" and mw.install_ladder(n, s).result == "ok" and n.inv.count("ladder") == l0 - 1 and _st(w, "used_ladder") == 1,
			"a ladder from the pack is set into it (used_ladder)")
	var sp: Array = w.underground.portals.filter(func(p): return str(p.get("kind", "")) == "shaft")
	check(sp.size() == 1 and str(w.underground.next_leg(-1, -2).portal.id) == str(sp[0].id), "the shaft is a portal: the router goes from the gallery to the cave through it")
	# a villager walks from the gallery into the cave by the ladder, carrying ore, never through the surface
	var cave_goal: Vector2i = _cave(w).floor_cells()[0]
	var v := n
	v.inv.add("coal", 3)
	var coal0 := v.inv.count("coal")
	v.plan = [w.brain.go(cave_goal, 1.0, -2)]
	var x0 := _st(w, "portal_crossings")
	var surfaced := false
	for k in 2000:
		w._run_plan(v, 0.25, 0.5)
		if v.depth == 0:
			surfaced = true
		if v.plan.is_empty():
			break
	check(v.depth == -2 and v.cell() == cave_goal and not surfaced and _st(w, "portal_crossings") == x0 + 1,
			"a villager goes down the ladder to the cave without going up to the surface")
	check(v.inv.count("coal") == coal0, "and carries their goods down in their own hands")
	# a minecart never goes through the shaft
	var stand: Vector2i = sp[0].ends[0].stand
	var p := w.player
	p.pos = Vector2(w.underground.portals[0].ends[0].stand) + Vector2(0.5, 0.5)
	w.player_through(Vector2.UP)
	p.pos = Vector2(stand) + Vector2(0.5, 0.5)
	p.inv.add("track_section", 2)
	p.inv.add("mallet")
	p.inv.add("minecart")
	mw.lay_track(p, stand)
	var md := mw.set_down_minecart(p, World.PLAYER, stand)
	w.carts.hitch(md.cart, World.PLAYER)
	var rr := w.player_through(Vector2(s - stand))
	check(rr.has("refused") and str(rr.refused).contains("ladder") and w.player_level == -1, "a minecart is not taken up or down a ladder: %s" % str(rr.get("refused", "")))
	w.carts.park(md.cart)
	var down := w.player_through(Vector2(s - stand))
	check(down.get("level", 0) == -2 and Vector2i(p.pos.floor()) == s, "the player climbs down the ladder to its foot in the cave")
	var up := w.player_through(Vector2(Vector2i(int(sp[0].ends[1].door.x), int(sp[0].ends[1].door.y)) - s))
	check(up.get("level", 0) == -1, "and back up")
	check(World.level_of(md.cart) == -1, "the minecart stayed on the gallery's level")
	# a deeper level: a shaft from the cave makes level -3, bounded at shaft.deepest
	var cl := _cave(w)
	var hn := _hand(w, -2, cl.floor_cells()[0])
	hn.inv.add("timber_support", 6)
	var deep_s := Vector2i(-1, -1)
	for c in cl.floor_cells():
		var bes := Vector2i(-1, -1)
		for d: Vector2i in VillageMap.SIDES:
			if not cl.is_solid(c + d):
				bes = c + d
		if bes.x < 0 or c == s:
			continue
		hn.pos = Vector2(bes) + Vector2(0.5, 0.5)
		if not mw.supported(-2, c) and mw.support_refusal(hn, bes) == "":
			mw.place_support(hn, bes)
		if mw.shaft_refusal(hn, c) == "":
			deep_s = c
			break
	var maps0 := w.underground.maps.size()
	var r2 := {}
	for k in 30:
		r2 = mw.dig_shaft(hn, deep_s, hn.inv)
		if r2.result != "ok" or r2.done:
			break
	var lm3: LevelMap = w.underground.map_at(-3, deep_s)
	check(r2.get("done", false) and w.underground.maps.size() == maps0 + 1 and lm3 != null and not lm3.is_solid(deep_s) and mw.levels == [-3],
			"a shaft from the cave makes level -3 (all rock but its landing, cut as an ordinary cell)")
	check(w.underground.hidden.any(func(h): return int(h.level) == -3), "the new level's rock holds hidden ore by the same generator")
	var lr := hn.inv.count("ladder")
	hn.inv.add("ladder")
	mw.install_ladder(hn, deep_s)
	check(w.villager_levels.has(-3) and not w.underground.next_leg(0, -3).is_empty(), "with its ladder, level -3 is on villagers' routes (%s)" % str(w.villager_levels))
	var deepest := int(MineWorks.cfg().shaft.deepest)
	hn.depth = deepest
	check(mw.shaft_refusal(hn, deep_s).contains("deeper"), "no shaft is sunk below level %d" % deepest)
	hn.depth = -2
	# the shaft's stability: unsupported it caves in; the ladder is crushed and the way closed
	mw.supports = mw.supports.filter(func(sp2): return int(sp2[0]) != -1)
	var fell := false
	for d in 60:
		_next_day(w)
		if int(mw.shaft_at(-1, s).rubble) > 0:
			fell = true
			break
	check(fell and int(mw.shaft_at(-1, s).ladder) < 0 and w.underground.portals.filter(func(pp): return str(pp.id) == MineWorks.shaft_id(mw.shaft_at(-1, s))).is_empty(),
			"an unsupported shaft caves in: rubble in it, its ladder crushed, the way closed")


# ---------------------------------------------------------------- 7 backfill order -----------
## A cut cell in the gallery (beside a sound support) a player's order fills: [w, cell].
func _fill_world(seed_value := 1) -> Array:
	var t := _tunnel(seed_value)
	var w: World = t[0]
	var n: NPC = t[1]
	n.depth = 0
	n.pos = Vector2(30.5, 40.5)
	return [w, t[4], t[2]]


func _test_backfill_order() -> void:
	var t := _fill_world()
	var w: World = t[0]
	var c: Vector2i = t[1]
	var lm: LevelMap = t[2]
	var mw := w.mine_works
	var mwork := w.manor_work
	var p := w.player
	p.coins = 50
	p.inv.add("spoil", 10)
	var coins0 := w.total_coins()
	var pc0 := p.coins
	check(mwork.order_backfill(-1, c, MineWorks.cell_units()) == "", "the player orders the passage backfilled")
	var j: Dictionary = mwork.backfill_order(-1, c)
	check(not j.is_empty() and p.coins == pc0 - int(j.wage) and int(j.reserved) == int(j.wage) and w.total_coins() == coins0,
			"the order's wage (%d coins) is the player's, held in the order (no coin made or lost)" % int(j.get("wage", 0)))
	check(mwork.open_for("npc:%d" % w.npcs[0].id).filter(func(x): return x.kind == "backfill").is_empty(), "no worker takes it before there is spoil to carry")
	var depot := Vector2i(int(j.depot[0]), int(j.depot[1]))
	check(depot == w.underground.portals[0].ends[0].stand, "its depot is the adit's surface stand")
	mwork.stock_backfill(j, p.inv, 10)
	check((j.stock as Inventory).count("spoil") == 10 and p.inv.count("spoil") == 0, "the player leaves 10 spoil at the depot")
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "laborer":
			n = o
	if n == null:
		n = w.npcs[2]
	n.plan.clear()
	n.depth = 0
	n.pos = Vector2(depot) + Vector2(0, 1.5)
	var nc0 := n.coins
	var who := World.npc_ref(n.id)
	check(mwork.open_for(who).has(j) and mwork.take(j, who), "a labourer takes the player's order through the job board")
	w.minutes = floorf(w.minutes / 1440.0) * 1440.0 + 8.0 * 60.0
	mwork.plan(n)
	var fill_seen := []
	for k in 4000:
		w.update(0.5)
		var f := mw.fill_at(-1, c)
		if fill_seen.is_empty() or fill_seen[fill_seen.size() - 1] != f:
			fill_seen.append(f)
		if mwork.job(int(j.id)).is_empty():
			break
	check(mwork.job(int(j.id)).is_empty() and mw.fill_at(-1, c) == MineWorks.cell_units() and lm.is_solid(c),
			"the worker carries the spoil down and fills the passage unit by unit (%s): full, it is blocked" % str(fill_seen))
	var path := lm.find_path(w.underground.portals[0].ends[1].stand, c)
	check(path.is_empty() or Vector2i(path[path.size() - 1]) != c, "no path goes through the filled passage")
	check(n.coins - nc0 == int(j.wage) and w.total_coins() == coins0, "the worker is paid the order's wage, the player's coins")
	var left := 0
	for l in w.loot:
		left += (l.inv as Inventory).count("spoil")
	check(_st(w, "filled_spoil") == MineWorks.cell_units() and mw.fill_in() == MineWorks.cell_units() and left + n.inv.count("spoil") == 10 - MineWorks.cell_units(),
			"exactly the units placed left the depot (filled_spoil %d); the rest is left lying at the depot" % _st(w, "filled_spoil"))
	# cancelled part way: what is placed stays, the wage goes back
	var t2 := _fill_world()
	var w2: World = t2[0]
	var c2: Vector2i = t2[1]
	w2.player.coins = 50
	w2.player.inv.add("spoil", 8)
	w2.manor_work.order_backfill(-1, c2, MineWorks.cell_units())
	var j2: Dictionary = w2.manor_work.backfill_order(-1, c2)
	w2.manor_work.stock_backfill(j2, w2.player.inv, 8)
	var n2: NPC = w2.npcs[2]
	for o: NPC in w2.npcs:
		if o.alive and o.role == "adult" and o.job == "laborer":
			n2 = o
	n2.plan.clear()
	n2.depth = 0
	n2.pos = Vector2(int(j2.depot[0]), int(j2.depot[1])) + Vector2(0.5, 1.5)
	w2.manor_work.take(j2, World.npc_ref(n2.id))
	w2.minutes = floorf(w2.minutes / 1440.0) * 1440.0 + 8.0 * 60.0
	w2.manor_work.plan(n2)
	for k in 4000:
		w2.update(0.5)
		if int(j2.placed) >= 2:
			break
	var mid: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
	var placed := int(j2.placed)
	var pc := w2.player.coins
	var coins2 := w2.total_coins()
	w2.manor_work.cancel_backfill(j2)
	var spoil_loot := 0
	for l in w2.loot:
		spoil_loot += (l.inv as Inventory).count("spoil")
	check(placed >= 2 and w2.mine_works.fill_at(-1, c2) == placed and w2.player.coins == pc + int(j2.wage) and w2.total_coins() == coins2,
			"cancelled after %d units, the fill placed stays and the wage held goes back to the player" % placed)
	check(spoil_loot == 8 - placed, "the spoil not placed is left lying (the worker's load where they stood, the depot's at the depot): nothing refunded by magic")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), mid)
	var j3: Dictionary = w3.manor_work.backfill_order(-1, c2)
	check(not j3.is_empty() and int(j3.placed) == placed and w3.mine_works.fill_at(-1, c2) == placed and (j3.stock as Inventory).total() + j3.load.total() == 8 - placed,
			"saved part way, the order loads with its fill, its spoil and its progress")


# ---------------------------------------------------------------- 8 no autonomous backfill ----
func _test_no_autonomous_backfill() -> void:
	var t := _tunnel(2)
	var w: World = t[0]
	var mw := w.mine_works
	for n: NPC in w.npcs:
		n.inv.add("spoil", 10)                       # spoil everywhere, dangerous tunnels, nothing ordered
	w.manor_work.yard.add("spoil", 30)
	w.stats["cut_spoil"] = float(_st(w, "cut_spoil") + 10 * w.npcs.size() + 30)
	mw.supports.clear()
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	var posted := false
	for k in per_day * 2:
		w.update(0.5)
		if w.manor_work.jobs.any(func(j): return j.kind == "backfill"):
			posted = true
	check(not posted and mw.fill_in() == 0 and _st(w, "filled_spoil") == 0, "two days with spoil in every pack and an unsupported tunnel: nobody backfills anything without the player")
	var callers := 0
	var order_callers := 0
	for f in ["res://scripts/core/npc_brain.gd", "res://scripts/core/world.gd", "res://scripts/core/manor_work.gd", "res://scripts/core/mine_works.gd",
			"res://scripts/core/open_pit.gd", "res://scripts/core/contracts.gd", "res://scripts/core/contract_services.gd"]:
		var src := FileAccess.get_file_as_string(f)
		callers += src.count("mine_works.fill(")
		order_callers += src.count("order_backfill(") - src.count("func order_backfill(")
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(callers == 1 and order_callers == 0 and main_src.count("order_backfill(") == 1,
			"in the code, a fill is placed only by the player's own hands (main) or the player's order (ManorWork's backfill step), and only main makes an order")


# ---------------------------------------------------------------- 9 backfill's structural effect
func _test_backfill_structure() -> void:
	var t := _tunnel()
	var w: World = t[0]
	var n: NPC = t[1]
	var lm: LevelMap = t[2]
	var s: Vector2i = t[3]
	var c: Vector2i = t[4]
	var mw := w.mine_works
	# a passage beside the cell to fill: a floor neighbour other than the support's cell, or one cut for it
	var nb := Vector2i(-1, -1)
	for d: Vector2i in VillageMap.SIDES:
		if not lm.is_solid(c + d) and c + d != s and mw.fill_ground_refusal(-1, c + d) == "":
			nb = c + d
	if nb.x < 0:
		for d: Vector2i in VillageMap.SIDES:
			if mw.rock_refusal(-1, c + d) == "" and _cut(w, n, lm, c + d):
				nb = c + d
				break
	check(nb.x >= 0, "a passage beside the cell is there to fill (%s)" % str(nb))
	if nb.x < 0:
		return
	n.depth = 0
	n.pos = Vector2(30.5, 40.5)
	mw.supports[0][3] = 400                           # a weak support
	var cond := mw.support_condition(-1, s)
	var s0 := mw.stability(-1, c)
	var p0 := mw.collapse_chance(-1, c)
	var p := w.player
	p.pos = Vector2(w.underground.portals[0].ends[0].stand) + Vector2(0.5, 0.5)
	w.player_through(Vector2.UP)
	p.pos = Vector2(c) + Vector2(0.5, 0.5)
	p.inv.add("spoil", 10)
	for k in MineWorks.cell_units():
		mw.fill(p, nb, p.inv)
	var s1 := mw.stability(-1, c)
	var p1 := mw.collapse_chance(-1, c)
	check(mw.fill_at(-1, nb) == MineWorks.cell_units() and s1 > s0 and p1 < p0,
			"a filled passage beside the cell adds to its stability (%.2f -> %.2f) and lowers its daily chance of collapse (%d -> %d per mille)" % [s0, s1, p0, p1])
	check(is_equal_approx(s1 - s0, float(MineWorks.cfg().stability.backfill_weight)), "by backfill_weight for one full neighbour (%.2f): limited, by quantity and placement" % (s1 - s0))
	check(mw.support_condition(-1, s) == cond, "backfill never mends the timber (the support is still %d)" % cond)
	mw.supports.clear()
	var sb := mw.stability(-1, c)
	check(sb <= float(MineWorks.cfg().stability.backfill_cap) + 0.0001 and sb < float(MineWorks.cfg().stability.threshold) and mw.collapse_chance(-1, c) > 0,
			"backfill alone is no support: at most %.2f, under the threshold, the cell can still cave in (%.2f)" % [float(MineWorks.cfg().stability.backfill_cap), sb])


# ---------------------------------------------------------------- 10 backfill dug again ------
func _test_backfill_dug_again() -> void:
	var t := _tunnel()
	var w: World = t[0]
	var n: NPC = t[1]
	var lm: LevelMap = t[2]
	var c: Vector2i = t[4]
	var mw := w.mine_works
	var p := w.player
	p.pos = Vector2(w.underground.portals[0].ends[0].stand) + Vector2(0.5, 0.5)
	w.player_through(Vector2.UP)
	_stand_p(p, lm, c)
	p.inv.add("spoil", MineWorks.cell_units())
	w.stats["cut_spoil"] = float(_st(w, "cut_spoil") + MineWorks.cell_units())
	var g0 := Census.goods(w)
	for k in MineWorks.cell_units():
		mw.fill(p, c, p.inv)
	check(lm.is_solid(c) and mw.fill_in() == MineWorks.cell_units() and int(Census.goods(w).get("spoil", 0)) == int(g0.get("spoil", 0)) - MineWorks.cell_units(),
			"filled, the spoil left the goods and lies in the passage as fill (%d units)" % mw.fill_in())
	var stone0 := _st(w, "cut_stone")
	var items := []
	_stand_beside(n, lm, c)
	for k in MineWorks.cell_units():
		var r := mw.dig(n, c, n.inv)
		items.append(str(r.get("item", "")))
		if k == 0:
			check(not lm.is_solid(c), "once a unit is dug out the passage is open again")
	check(items.all(func(i): return i == "spoil") and _st(w, "cut_stone") == stone0 and mw.fill_out == MineWorks.cell_units(),
			"dug out again, the fill comes back as spoil only, never stone or ore (%s)" % str(items))
	check(Census.goods(w) == g0 and mw.fill_in() == 0, "the goods census is back where it was: placed units = removed units")


func _stand_p(p: PlayerState, lm: LevelMap, c: Vector2i) -> void:
	for d: Vector2i in VillageMap.SIDES:
		if not lm.is_solid(c + d):
			p.pos = Vector2(c + d) + Vector2(0.5, 0.5)
			return


# ---------------------------------------------------------------- 11 save and replay ---------
func _scenario(seed_value: int) -> World:
	var t := _shaft_world(seed_value)
	var w: World = t[0]
	var n: NPC = t[1]
	var s: Vector2i = t[2]
	var mw := w.mine_works
	if s.x >= 0:
		for k in 20:
			var r := mw.dig_shaft(n, s, n.inv)
			if r.result != "ok" or r.done:
				break
		mw.install_ladder(n, s)
	var lm := _gallery(w)
	var skip := {}
	if s.x >= 0:
		skip[s] = true
	var face := _face(w, lm, skip)
	n.pos = Vector2(face[0]) + Vector2(0.5, 0.5)
	if mw.support_refusal(n, face[0]) == "":
		mw.place_support(n, face[0])
	_cut(w, n, lm, face[1])
	w.player.coins = 40
	w.player.inv.add("spoil", 3)
	if w.manor_work.order_backfill(-1, face[1], 3) == "":
		w.manor_work.stock_backfill(w.manor_work.backfill_order(-1, face[1]), w.player.inv, 3)
	for d in 45:
		_next_day(w)
	return w


func _test_save_and_replay() -> void:
	var w := _scenario(3)
	var mw := w.mine_works
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
	check(JSON.stringify(d2.mine_works) == JSON.stringify(d.mine_works), "the works round-trip whole: supports' conditions, shafts, ladders, levels, fill, rubble, the books")
	check(JSON.stringify(d2.manor_work.jobs) == JSON.stringify(d.manor_work.jobs) and JSON.stringify(d2.carts) == JSON.stringify(d.carts), "the backfill order and the carts round-trip")
	check(w2.underground.fingerprint() == w.underground.fingerprint() and w2.underground.portals.size() == w.underground.portals.size(),
			"the levels (the deep one too), their hidden ore and the shaft's portal are as before (nothing hidden revealed)")
	var solid_same := true
	for m: LevelMap in w.underground.maps:
		var m2: LevelMap = w2.underground.level_map(m.id)
		if m2 == null or m2.to_text() != m.to_text():
			solid_same = false
	check(solid_same, "every level's floor, filled, fallen and shaft cells load as they were")
	for k in 20:
		_next_day(w)
		_next_day(w2)
	check(JSON.stringify(w.to_dict().mine_works) == JSON.stringify(w2.to_dict().mine_works), "twenty more dawns give the same wear and collapses in the saved and the loaded world")
	var a := _scenario(5)
	var b := _scenario(5)
	check(JSON.stringify(a.to_dict().mine_works) == JSON.stringify(b.to_dict().mine_works) and a.rng.state == b.rng.state, "the same seed and actions replay to the same works and random stream")
	var c := _scenario(7)
	check(JSON.stringify(c.to_dict().mine_works) != JSON.stringify(a.to_dict().mine_works), "another seed gives other works")
	var old: Dictionary = JSON.parse_string(JSON.stringify(d))
	for s in old.mine_works.supports:
		(s as Array).resize(3)
	old.mine_works.erase("cells")
	old.mine_works.erase("shafts")
	old.mine_works.erase("levels")
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), old)
	check(w4.mine_works.supports.all(func(s): return int(s[3]) == int(MineWorks.cfg().stability.full)) and w4.mine_works.shafts.is_empty(),
			"a save from before MIN-F2 loads: its supports whole, no shafts, fill or rubble")
