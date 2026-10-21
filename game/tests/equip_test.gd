extends SceneTree
## MIN-EQUIP and MIN-COLLAPSE (owner MIN-F2-Q1 and Q2, docs/directives/2026-10-21_build17_minf2_q1_q2_decisions.md;
## docs/build17/MIN_EQUIP_COLLAPSE.md): the equipment's recipes for the player and a carpenter alike; the carpenter
## makes the manor's order and it is delivered to the works yard (the advance from the treasury, no coin made); the manor
## buys and orders only for a real need, posts shore work paid from the treasury, and a labourer sets the support up and
## repairs a worn one with the yard's goods; a miner's household buys a minecart only when rails make it pay; coins and
## goods conserved; a person caught in a collapse survives or dies, deterministically, the dead by the existing death
## path, survivors into the passage beside or trapped; saves keep it all. Run headless:
##   godot --headless --path game --script res://tests/equip_test.gd

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
	_test_recipes()
	_test_order_made_and_delivered()
	_test_manor_procurement_and_shoring()
	_test_repair_job()
	_test_household_minecart()
	_test_collapse_outcomes()
	_test_survivors()
	_test_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- helpers --------------------
func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0))


func _job(w: World, job: String) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.job == job and n.role == "adult":
			return n
	return null


func _gallery(w: World) -> LevelMap:
	return w.underground.level_map("adit_gallery")


## Run the villager's plan through (its steps, the world's carts), at most `steps` quarter seconds.
func _run(w: World, n: NPC, steps := 2000) -> void:
	for k in steps:
		if n.plan.is_empty():
			return
		w._run_plan(n, 0.25, 0.5)
		w.carts.update(0.25)


## A day passes for the mine only (its dawn).
func _next_day(w: World) -> void:
	w.minutes += 1440.0
	w.mine_works.dawn()


func _morning(w: World) -> void:
	w.minutes = floorf(w.minutes / 1440.0) * 1440.0 + 8.0 * 60.0


# ---------------------------------------------------------------- 1 recipes and parity ------
func _test_recipes() -> void:
	var w := _world()
	var c := _job(w, "carpenter")
	var p := w.player
	for r in ["make_timber_support", "make_ladder", "build_minecart"]:
		var rec: Dictionary = GameData.recipes[r]
		for id in rec["in"]:
			c.inv.add(id, int(rec["in"][id]))
			p.inv.add(id, int(rec["in"][id]))
		var out: String = rec.out.keys()[0]
		var c0 := c.inv.count(out)
		var p0 := p.inv.count(out)
		var rc := w.work_craft(c, r, c.inv)
		var rp := w.work_craft(p, r, p.inv)
		check(rc.result == "ok" and rp.result == "ok" and c.inv.count(out) >= c0 + 1 and p.inv.count(out) >= p0 + 1,
				"%s: the carpenter and the player make it by the same recipe (%s at the %s)" % [out, JSON.stringify(rec["in"]), rec.station])
	check(GameData.recipes.make_ladder["in"].has("nails") and GameData.recipes.forge_nails.station == "anvil", "a ladder takes the smith's nails (forged at the anvil): both trades' work")
	check(GameData.recipes.build_minecart["in"].has("cart_axle") and GameData.recipes.forge_cart_axle.station == "anvil" and GameData.recipes.build_minecart["in"].has("cart_wheel"),
			"a minecart is the carpenter's body and wheels on the smith's axles and ironwork (the handcart's parts chain)")
	check((MineWorks.cfg().support.repair as Dictionary).has("plank") and (MineWorks.cfg().ladder.repair as Dictionary).has("nails"), "repairs take the carpenter's planks and the smith's nails")


# ---------------------------------------------------------------- 2 made to order -------------
func _test_order_made_and_delivered() -> void:
	var w := _world()
	var c := _job(w, "carpenter")
	var sup: MineSupply = w.mine_works.supply
	w.treasury = 3000
	var coins0 := w.total_coins()
	var t0 := w.treasury
	var c0 := c.coins
	# an order the manor would place (procure's own step for an item nobody holds)
	var maker := sup._maker("timber_support")
	check(maker == c, "a carpenter who can make supports takes the manor's order")
	var advance := int(ceil(GameData.value("timber_support")))
	w.treasury -= advance
	c.coins += advance
	w.manor_orders.append({"smith": c.id, "tool": "timber_support", "for": -1, "paid": advance, "day": w.day()})
	check(w.total_coins() == coins0, "the advance moves coins from the treasury to the carpenter, none made")
	c.inv.add("log", 2)
	c.inv.add("plank", 4)
	c.plan.clear()
	_morning(w)
	var planned := sup.carpenter_work(c)
	check(planned and str(c.doing).contains("for the manor"), "the carpenter sets to the manor's order (%s)" % c.doing)
	var log0 := c.inv.count("log")
	_run(w, c, 3000)
	check(c.inv.count("timber_support") >= 1 and c.inv.count("log") < log0 and _st(w, "made_timber_support") >= 1, "the support is made from the carpenter's own log and planks (made_timber_support)")
	check(w.brain.keeps(c, "timber_support"), "it is kept for the order, not sold to anyone else")
	var y0 := w.manor_work.yard.count("timber_support")
	w.brain._deliver_orders()
	check(w.manor_work.yard.count("timber_support") == y0 + 1 and c.inv.count("timber_support") == 0 and w.manor_orders.is_empty(),
			"at the reeve's evening it is delivered into the manor's works yard and the order is done")
	check(w.total_coins() == coins0 and w.treasury == t0 - advance and c.coins == c0 + advance, "paid once, in advance, from the treasury (%d coins)" % advance)


# ---------------------------------------------------------------- 3 the manor's procurement --
## A world where the works lack stone (the tunnel job's own rule) and a face could be cut if a support stood by it.
func _needy() -> World:
	var w := _world()
	w.treasury = 3000
	w.manor_work.yard.remove("stone", w.manor_work.yard.count("stone"))
	return w


func _test_manor_procurement_and_shoring() -> void:
	var w0 := _world()
	w0.treasury = 3000
	w0.manor_work.yard.add("stone", 40)
	check(w0.mine_works.supply.manor_needs().is_empty(), "with its works stocked with stone the manor needs no support (no need, no purchase)")
	var w := _needy()
	var sup: MineSupply = w.mine_works.supply
	var f := sup.unsupported_face()
	check(not f.is_empty() and sup.tunnel_wanted() and w.mine_works.manor_face().is_empty(), "the works lack stone and no face is held: a face is chosen to be propped (%s)" % str(f.get("face", "")))
	var need := sup.manor_needs()
	check(int(need.get("timber_support", 0)) == 1 and int(need.get("mallet", 0)) == 1, "the manor needs one support and a mallet for its yard (%s)" % JSON.stringify(need))
	var coins0 := w.total_coins()
	var spent := sup.procure()
	var orders := w.manor_orders.filter(func(x): return int(x["for"]) == -1)
	check(spent > 0 and orders.size() == 2 and w.total_coins() == coins0, "nobody holds them, so both are ordered from a carpenter, paid in advance from the treasury (%d coins)" % spent)
	check(sup.manor_needs().is_empty(), "with them on order nothing more is bought")
	# each carpenter with an order makes it (its own stock: logs and planks, as it buys them)
	_morning(w)
	var made := 0
	for x in w.manor_orders.duplicate():
		var c: NPC = w.npc(int(x.smith))
		c.inv.add("log", 2)
		c.inv.add("plank", 4)
		for k in 4:
			c.plan.clear()
			if c.inv.has(str(x.tool)) or not w.mine_works.supply.carpenter_work(c):
				break
			_run(w, c, 3000)
		if c.inv.has(str(x.tool)):
			made += 1
	check(made == 2, "the carpenters make the support and the mallet they were ordered (%d of 2)" % made)
	w.brain._deliver_orders()
	check(w.manor_work.yard.count("timber_support") == 1 and w.manor_work.yard.count("mallet") == 1, "both are delivered to the works yard")
	w.manor_work.post_shore()
	var jobs: Array = w.manor_work.jobs.filter(func(j): return j.kind == "shore")
	check(jobs.size() == 1 and str(jobs[0].mode) == "prop" and int(jobs[0].wage) == int(ManorWork.cfg("mend_wage")), "the reeve posts a shore job to set the support up (the mending rate, %d)" % int(ManorWork.cfg("mend_wage")))
	if jobs.is_empty():
		return
	var j: Dictionary = jobs[0]
	var n := _job(w, "laborer")
	n.plan.clear()
	n.depth = 0
	n.pos = Vector2(w.manor_work.yard_cell()) + Vector2(0.5, 1.5)
	var nc0 := n.coins
	var t0 := w.treasury
	coins0 = w.total_coins()
	check(w.manor_work.take(j, World.npc_ref(n.id)) and w.treasury == t0 - int(j.wage), "a labourer takes it; the wage is set aside from the treasury")
	w.manor_work.plan(n)
	var done := false
	for k in 4000:
		w.update(0.5)
		if w.manor_work.job(int(j.id)).is_empty():
			done = true
			break
	var site := Vector2i(int(j.site[0]), int(j.site[1]))
	check(done and w.mine_works.support_at(int(j.level), site) and w.manor_work.yard.count("mallet") == 1 and w.manor_work.yard.count("timber_support") == 0,
			"the labourer carries the support and the mallet down, sets it up beside the face and brings the mallet back")
	check(n.coins - nc0 >= int(j.wage) and w.total_coins() == coins0, "paid from the treasury; no coin made or lost")
	check(not w.mine_works.manor_face().is_empty(), "the face is now held by sound timber: the manor's tunnel job can be posted")
	w.manor_work.post_tunnels()
	check(w.manor_work.jobs.any(func(x): return x.kind == "tunnel"), "and the reeve posts it")


# ---------------------------------------------------------------- 4 repairs ------------------
func _test_repair_job() -> void:
	var w := _needy()
	var lm := _gallery(w)
	var mw := w.mine_works
	# a support holding an opened cell (cut by a hand), worn below the repair line
	var n := _job(w, "laborer")
	var face: Array = []
	for f0 in lm.floor_cells():
		for d: Vector2i in VillageMap.SIDES:
			var c := f0 + d
			if face.is_empty() and lm.is_solid(c) and w.deposit_at(c, -1).is_empty() and lm.region.grow(-1).has_point(c) and w.underground.under_rock(w.map, c) and w.underground.hidden_at(-1, c).is_empty():
				face = [f0, c]
	n.depth = -1
	n.pos = Vector2(face[0]) + Vector2(0.5, 0.5)
	n.inv.add("timber_support")
	n.inv.add("mallet")
	if not n.inv.has("pickaxe"):
		n.inv.add("pickaxe")
	mw.place_support(n, face[0])
	for k in MineWorks.cell_units():
		mw.dig(n, face[1], n.inv)
	n.inv.remove("mallet", n.inv.count("mallet"))
	mw.supports[0][3] = int(MineWorks.cfg().supply.repair_at) - 50
	var reps := mw.supply.repairs_wanted()
	check(reps.size() == 1 and reps[0].cell == face[0], "a support worn below the repair line that holds a cut cell is wanted repaired")
	w.manor_work.yard.add("plank", 2)
	w.manor_work.yard.add("mallet")
	var p0 := w.manor_work.yard.count("plank")
	w.manor_work.post_shore()
	var jobs: Array = w.manor_work.jobs.filter(func(j): return j.kind == "shore" and str(j.mode) == "repair")
	check(jobs.size() == 1, "with planks and a mallet in the yard the reeve posts a repair job")
	if jobs.is_empty():
		return
	var j: Dictionary = jobs[0]
	n.depth = 0
	n.pos = Vector2(w.manor_work.yard_cell()) + Vector2(0.5, 1.5)
	n.plan.clear()
	w.manor_work.take(j, World.npc_ref(n.id))
	_morning(w)
	w.manor_work.plan(n)
	for k in 4000:
		w.update(0.5)
		if w.manor_work.job(int(j.id)).is_empty():
			break
	check(mw.support_condition(-1, face[0]) == int(MineWorks.cfg().stability.full) and w.manor_work.yard.count("plank") == p0 - 1 and w.manor_work.yard.count("mallet") == 1,
			"repaired with one of the yard's planks (used up), the mallet back in the yard")


# ---------------------------------------------------------------- 5 a household's minecart ---
func _test_household_minecart() -> void:
	var w := _world()
	var lm := _gallery(w)
	var mw := w.mine_works
	var miner := _job(w, "miner")
	# only the gallery's seams are left (a miner below)
	for d in w.deposits:
		if World.level_of(d) == 0:
			d.amount = 0
			if d.has("host"):
				d.host.amount = 0
	for b in w.boulders:
		b.amount = 0
	miner.depth = -1
	miner.pos = Vector2(w.underground.portals[0].ends[1].stand) + Vector2(0.5, 0.5)
	check(mw.supply.minecart_wanted(miner).is_empty(), "with no track a miner's household wants no minecart (no need without rails)")
	# rails from the miner's seam to the mouth (laid as a player would)
	var d: Dictionary = w.nearest_seam(miner, ["iron_ore", "coal", "copper_ore", "stone"])
	var lv := World.level_of(d)
	var stand: Vector2i = w.brain.beside(Vector2i(int(d.x), int(d.y)), Vector2i(int(d.x), int(d.y)), lv)
	var inner: Vector2i = w.underground.portals[0].ends[1].stand
	var p := w.player
	p.pos = Vector2(w.underground.portals[0].ends[0].stand) + Vector2(0.5, 0.5)
	w.player_through(Vector2.UP)
	p.inv.add("mallet")
	var route: Array[Vector2i] = []
	for pt in lm.find_path(inner + Vector2i(0, -1), stand):
		var c := Vector2i(pt)
		if not route.is_empty() and route[route.size() - 1].x != c.x and route[route.size() - 1].y != c.y:
			route.append(Vector2i(c.x, route[route.size() - 1].y))
		route.append(c)
	p.inv.add("track_section", route.size())
	for c in route:
		p.pos = Vector2(c) + Vector2(0.5, 0.5)
		mw.lay_track(p, c)
	p.pos = Vector2(w.underground.portals[0].ends[1].stand) + Vector2(0.5, 0.5)
	w.player_through(Vector2.DOWN)
	var want := mw.supply.minecart_wanted(miner)
	check(not want.is_empty() or route.size() < 4, "with rails from the far seam toward the mouth the household needs a minecart (%s, rails %d)" % [str(want), route.size()])
	if want.is_empty():
		return
	var c := _job(w, "carpenter")
	for id in GameData.recipes.build_minecart["in"]:
		c.inv.add(id, int(GameData.recipes.build_minecart["in"][id]))
	c.plan.clear()
	_morning(w)
	check(mw.supply.carpenter_work(c) and str(c.doing).contains("household"), "the carpenter makes one for the miner's household (%s)" % c.doing)
	_run(w, c, 4000)
	check(c.inv.count("minecart") == 1, "the minecart is made")
	miner.coins = 400
	var coins0 := w.total_coins()
	var mc0 := miner.coins
	var cc0 := c.coins
	miner.plan = mw.supply.miner_cart_plan(miner)
	check(not miner.plan.is_empty(), "the miner plans to buy it with their own coins and set it on the rails")
	_run(w, miner, 6000)
	var carts: Array = w.carts.of(World.hh_ref(miner.household), "minecart")
	check(carts.size() == 1 and mw.track_at(-1, Vector2i((carts[0].pos as Vector2).floor())) and World.level_of(carts[0]) == -1,
			"bought, it is set down on the rails by the seam, the household's")
	check(mc0 - miner.coins == c.coins - cc0 and mc0 > miner.coins and w.total_coins() == coins0, "the coins go from the miner to the carpenter (%d), none made" % (mc0 - miner.coins))
	check(mw.supply.minecart_wanted(miner).is_empty(), "with a minecart the household wants no second one")


# ---------------------------------------------------------------- 6 survive or die ----------
## A cut cell with a person on it, ready to cave in: [w, cell, person].
func _caved(seed_value: int, base: int, per: int, use_player := false) -> Array:
	var w := _world(seed_value)
	var lm := _gallery(w)
	var mw := w.mine_works
	MineWorks.cfg().collapse.survive_base = base
	MineWorks.cfg().collapse.survive_per_held = per
	var n := _job(w, "laborer")
	var face: Array = []
	for f0 in lm.floor_cells():
		for d: Vector2i in VillageMap.SIDES:
			var c := f0 + d
			if face.is_empty() and lm.is_solid(c) and w.deposit_at(c, -1).is_empty() and lm.region.grow(-1).has_point(c) and w.underground.under_rock(w.map, c) and w.underground.hidden_at(-1, c).is_empty():
				face = [f0, c]
	n.depth = -1
	n.pos = Vector2(face[0]) + Vector2(0.5, 0.5)
	n.inv.add("timber_support")
	n.inv.add("mallet")
	if not n.inv.has("pickaxe"):
		n.inv.add("pickaxe")
	mw.place_support(n, face[0])
	for k in MineWorks.cell_units():
		mw.dig(n, face[1], n.inv)
	mw.supports.clear()
	var who = n
	if use_player:
		w.player.pos = Vector2(w.underground.portals[0].ends[0].stand) + Vector2(0.5, 0.5)
		w.player_through(Vector2.UP)
		w.player.pos = Vector2(face[1]) + Vector2(0.5, 0.5)
		who = w.player
		n.pos = Vector2(face[0]) + Vector2(0.5, 0.5)
	else:
		n.pos = Vector2(face[1]) + Vector2(0.5, 0.5)
	return [w, face[1], who]


func _test_collapse_outcomes() -> void:
	var base0 := int(MineWorks.cfg().collapse.survive_base)
	var per0 := int(MineWorks.cfg().collapse.survive_per_held)
	# the same state and seed: the same outcome
	var outs := []
	for k in 2:
		var t := _caved(1, base0, per0)
		var w: World = t[0]
		w.mine_works.collapse(-1, t[1])
		outs.append([(t[2] as NPC).alive, (t[2] as NPC).cell()])
	check(outs[0] == outs[1], "the same state and seed give the same outcome (%s)" % str(outs[0]))
	var lives := {}
	for s in [1, 2, 3, 4, 5, 6, 7, 8]:
		var t := _caved(s, base0, per0)
		var w: World = t[0]
		w.mine_works.collapse(-1, t[1])
		lives[(t[2] as NPC).alive] = true
	check(lives.size() == 2, "over eight worlds some caught in an unsupported collapse live and some die (survival at %d per mille unheld)" % base0)
	# death by the existing path: heir, notes, household
	var t2 := _caved(1, 0, 0)
	var w2: World = t2[0]
	var dead: NPC = t2[2]
	dead.inv.add("coal", 3)
	var heir: NPC = w2._heir(dead)
	var heir_coal := heir.inv.count("coal") if heir != null else 0
	w2.mine_works.collapse(-1, t2[1])
	check(not dead.alive and _st(w2, "collapse_deaths") == 1 and w2.log_lines.any(func(l): return str(l).contains("crushed in a mine collapse")),
			"with no chance of surviving the villager dies, by World.kill, noted in the village's records")
	check(heir == null or heir.inv.count("coal") >= heir_coal + 3, "what they carried passes to their heir by the existing inheritance")
	var hh_mem := false
	if dead.household >= 0:
		for m in w2.households[dead.household].members:
			var o := w2.npc(int(m))
			if o != null and o.alive and o.memory.any(func(x): return str(x).contains("crushed in a mine collapse")):
				hh_mem = true
	check(dead.household < 0 or hh_mem, "their household remembers how they died")
	# the player: the existing player death
	var t3 := _caved(1, 0, 0, true)
	var w3: World = t3[0]
	w3.mine_works.collapse(-1, t3[1])
	check(not w3.player.alive and str(w3.player.death_cause).contains("mine collapse") and w3.player.deaths == 1, "a player caught dies by the existing player death (%s)" % str(w3.player.death_cause))
	MineWorks.cfg().collapse.survive_base = base0
	MineWorks.cfg().collapse.survive_per_held = per0
	check(int(MineWorks.cfg().collapse.survive_base) == base0, "(the tunables restored: %d + %d x stability)" % [base0, per0])


# ---------------------------------------------------------------- 7 survivors ----------------
func _test_survivors() -> void:
	var t := _caved(1, 1000, 0)
	var w: World = t[0]
	var c: Vector2i = t[1]
	var n: NPC = t[2]
	var lm := _gallery(w)
	w.mine_works.collapse(-1, c)
	var d := maxi(absi(n.cell().x - c.x), absi(n.cell().y - c.y))
	check(n.alive and d == 1 and not lm.is_solid(n.cell()) and not w.mine_works.is_trapped(n), "a survivor scrambles into the passage beside the cave-in (%s), nowhere farther" % str(n.cell()))
	# no way out: trapped in the rubble until it is dug out
	var t2 := _caved(2, 1000, 0)
	var w2: World = t2[0]
	var c2: Vector2i = t2[1]
	var n2: NPC = t2[2]
	var lm2 := _gallery(w2)
	var opened_by_test: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var o := c2 + Vector2i(dx, dy)
			if o != c2 and not lm2.is_solid(o):
				lm2.set_solid(o, true)                    # (a fixture: the passages round it already fallen)
				opened_by_test.append(o)
	w2.mine_works.collapse(-1, c2)
	check(n2.alive and n2.cell() == c2 and w2.mine_works.is_trapped(n2) and _st(w2, "collapse_trapped") == 1, "with no open passage beside it the survivor is trapped in the rubble, where they were")
	var pos0 := n2.pos
	for k in 40:
		w2._update_npc(n2, 0.5)
	check(n2.pos == pos0 and n2.depth == -1 and n2.plan.is_empty(), "trapped, they cannot walk away or be moved to the surface: they wait")
	for o in opened_by_test:
		lm2.set_solid(o, false)
	var digger := _job(w2, "miner")
	digger.depth = -1
	digger.pos = Vector2(opened_by_test[0]) + Vector2(0.5, 0.5)
	if not digger.inv.has("pickaxe"):
		digger.inv.add("pickaxe")
	digger.inv.add("timber_support")
	digger.inv.add("mallet")
	w2.mine_works.place_support(digger, opened_by_test[0])
	var freed := false
	for k in MineWorks.cell_units():
		w2.mine_works.dig(digger, c2, digger.inv)
		if not w2.mine_works.is_trapped(n2):
			freed = true
			break
	check(freed and not lm2.is_solid(c2) and _st(w2, "collapse_freed") == 1, "dug out (the first unit of rubble taken opens the cell), they are free")


# ---------------------------------------------------------------- 8 saves --------------------
func _test_save() -> void:
	var t := _caved(2, 1000, 0)
	var w: World = t[0]
	var c: Vector2i = t[1]
	var n: NPC = t[2]
	var lm := _gallery(w)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if Vector2i(dx, dy) != Vector2i.ZERO and not lm.is_solid(c + Vector2i(dx, dy)):
				lm.set_solid(c + Vector2i(dx, dy), true)
	w.mine_works.collapse(-1, c)
	w.manor_orders.append({"smith": _job(w, "carpenter").id, "tool": "ladder", "for": -1, "paid": 14, "day": w.day()})
	w.manor_work.yard.add("timber_support")
	w.manor_work._post({"kind": "shore", "mode": "prop", "level": -1, "site": [c.x, c.y], "qty": 1, "wage": 4})
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
	check(JSON.stringify(d2.mine_works) == JSON.stringify(d.mine_works) and w2.mine_works.is_trapped(w2.npc(n.id)), "the trapped survivor and the works round-trip")
	check(JSON.stringify(d2.manor_orders) == JSON.stringify(d.manor_orders) and JSON.stringify(d2.manor_work.jobs) == JSON.stringify(d.manor_work.jobs),
			"the manor's equipment order and its shore job round-trip")
