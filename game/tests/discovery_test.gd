extends SceneTree
## MIN-D finite deposit discovery and settlement mining capability (docs/build17/MIN_D_DISCOVERY.md; Mining spec stage 2,
## sections 3, 8, 9 and 11, phase D): nothing hidden in the deposits before a find is dug for; a trial pit by one rule
## for the player and a villager (time, wear, xp; most miss; a misleading stain never yields; finite pits a clue); a
## body opened only within reach, into an ordinary seam (same record, swing, host rock, counting) of a finite amount
## that is never refilled; capability levels derived from the village's real assets, rising and falling with them;
## adoption by the job rules (the prospector's place) and the manor's ordinary job board (survey, trial pit), paid for
## the labour; coins and goods conserved; determinism; saves keep it all and older saves load. Run headless:
##   godot --headless --path game --script res://tests/discovery_test.gd

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
	_test_hidden()
	_test_trial_parity()
	_test_opened_seam()
	_test_capability()
	_test_adoption()
	_test_commissioned()
	_test_saves()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _coins(w: World) -> int:
	return w.total_coins() - w.coin_sources + w.caravan_purse


func _st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0))


func _cheb(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## A clue with a body and a clear cell within reach of it ({clue, hit, miss}: a cell that strikes it and a clear cell
## that does not), or {}.
func _hit_clue(w: World) -> Dictionary:
	var reach := int(Discovery.cfg().trial.reach)
	for c in w.prospecting.clues:
		var body: Dictionary = c.body
		if body.is_empty():
			continue
		var hit := Vector2i(-1, -1)
		var miss := Vector2i(-1, -1)
		var bc := Vector2i(int(body.x), int(body.y))
		for cell: Vector2i in w.discovery.dig_cells(c, World.PLAYER):
			if _cheb(cell, bc) <= reach:
				if hit.x < 0:
					hit = cell
			elif miss.x < 0:
				miss = cell
		if hit.x >= 0 and miss.x >= 0:
			return {"clue": c, "hit": hit, "miss": miss}
	return {}


func _false_clue(w: World) -> Dictionary:
	for c in w.prospecting.clues:
		if (c.body as Dictionary).is_empty() and w.discovery.dig_cells(c, World.PLAYER).size() >= 2:
			return c
	return {}


func _miner(w: World) -> NPC:
	var n: NPC = w.brain._first_with_job("laborer")
	if n == null:
		n = w.brain._first_with_job("miner")
	if not n.inv.has("pickaxe"):
		n.inv.add("pickaxe")
	return n


func _smith_ready(w: World) -> NPC:
	var s: NPC = w.brain._first_with_job("smith")
	s.pos = Vector2(w.brain._workplace_cell(s)) + Vector2(0.5, 0.5)
	s.plan.clear()
	s.inv.add("coal", 6)
	return s


# ---------------------------------------------------------------- hidden until dug -----------
func _test_hidden() -> void:
	var a := _world(1)
	var b := _world(1)
	var expect: int = a.map.data.deposits.size() + a.underground.seam_records().size()
	check(a.deposits.size() == expect and not a.deposits.any(func(d): return d.has("found")),
			"a new world has no deposit from a find: bodies stay hidden geology (%d deposits)" % a.deposits.size())
	check(JSON.stringify(a.discovery.evaluate()) == JSON.stringify(b.discovery.evaluate()) and a.discovery.level() == b.discovery.level(),
			"the same seed gives the same capability (level %d)" % a.discovery.level())
	var ok := true
	for c in a.prospecting.clues:
		var body: Dictionary = c.body
		if body.is_empty():
			continue
		var base := 0
		for d in a.map.data.deposits:
			if str(d.ore) == str(body.ore):
				base = int(d.amount)
				break
		var amt := a.discovery.body_amount(str(body.ore), int(body.grade))
		if amt < 1 or amt > base:
			ok = false
	check(ok, "every body's amount is finite and no bigger than the village's own seam of that ore")
	var hits := 0
	var trues := 0
	for s in [1, 2, 7]:
		var w := a if s == 1 else _world(s)
		var reach := int(Discovery.cfg().trial.reach)
		for c in w.prospecting.clues:
			if (c.body as Dictionary).is_empty():
				continue
			trues += 1
			var bc := Vector2i(int(c.body.x), int(c.body.y))
			if w.discovery.dig_cells(c, World.PLAYER).any(func(cell): return _cheb(cell, bc) <= reach):
				hits += 1
	check(hits > 0 and hits <= trues, "over seeds 1, 2 and 7, %d of %d bodies can be reached by a trial pit on clear ground (the rest lie under roads, buildings or yards)" % [hits, trues])


# ---------------------------------------------------------------- the trial pit --------------
func _test_trial_parity() -> void:
	var w := _world(1)
	var dv := w.discovery
	var p := w.player
	var n := _miner(w)
	var h := _hit_clue(w)
	check(not h.is_empty(), "seed 1 has a clue whose body a trial pit can reach")
	var c: Dictionary = h.clue
	p.inv.durability.erase("pickaxe")
	if not p.inv.has("pickaxe"):
		p.inv.add("pickaxe")
	check(dv.trial_refusal(n, c, h.miss, "") != "" and dv.trial_refusal(n, c, h.miss, "axe").contains("pickaxe"), "a trial pit needs a pickaxe")
	var coins0 := _coins(w)
	var deps0 := w.deposits.size()
	var cells := dv.dig_cells(c, World.PLAYER)
	var miss2 := Vector2i(-1, -1)
	var bc := Vector2i(int(c.body.x), int(c.body.y))
	for cell: Vector2i in cells:
		if cell != h.miss and _cheb(cell, bc) > int(Discovery.cfg().trial.reach):
			miss2 = cell
			break
	var pxp := int(p.skills.get("mining", 0))
	var nxp := int(n.skills.get("mining", 0))
	var rp := dv.trial_dig(p, c, h.miss, "pickaxe")
	var rn := dv.trial_dig(n, c, miss2, "pickaxe") if miss2.x >= 0 else {"result": "skip"}
	check(rp.result == "ok" and (rp.found as Dictionary).is_empty(), "the player's trial pit away from the body finds nothing")
	check(rn.result == "ok" and (rn.found as Dictionary).is_empty(), "a villager's trial pit away from the body finds nothing")
	check(int(p.skills.get("mining", 0)) - pxp == int(n.skills.get("mining", 0)) - nxp and int(p.skills.get("mining", 0)) - pxp == int(Discovery.cfg().trial.xp),
			"the same Mining xp for both (%d)" % int(Discovery.cfg().trial.xp))
	check(_st(w, "trial_pits") == 2 and _st(w, "trial_misses") == 2 and dv.trials_left(c) == int(Discovery.cfg().trial.per_clue) - 2, "both pits are recorded and counted")
	check(dv.trial_dig(p, c, h.miss, "pickaxe").result == "refused", "a cell dug once cannot be dug again")
	check(w.deposits.size() == deps0 and _coins(w) == coins0, "a miss adds no deposit and moves no coin")
	# the hit: within reach of the body, by the villager
	var r := dv.trial_dig(n, c, h.hit, "pickaxe")
	var d: Dictionary = r.get("found", {})
	check(r.result == "ok" and not d.is_empty() and str(d.ore) == str(c.body.ore) and str(d.found) == str(c.id),
			"a trial pit within reach of the body opens it: a seam of %s" % str(c.body.ore))
	check(w.deposits.size() == deps0 + 1 and int(d.amount) == dv.body_amount(str(c.body.ore), int(c.body.grade)) and d.has("host"),
			"the seam is one ordinary deposit record of the body's finite amount (%d) with its host rock" % int(d.get("amount", 0)))
	check(_st(w, "found_" + str(c.body.ore)) == int(d.amount) and _st(w, "found_stone") == int(d.host.amount), "the find enters the books as found_<ore> and found_stone")
	check(w.map.is_solid(h.hit) and w.deposit_at(h.hit) == d and ResourceNodes.def_for_deposit(d).size() > 0, "it is solid rock found by deposit_at, a node of the same resources.json kind")
	check(dv.trial_dig(p, c, cells[cells.size() - 1], "pickaxe").why.contains("already been opened") or dv.trials_left(c) <= 0, "once opened, no more pits round that stain")
	check(_coins(w) == coins0, "trial pits move no coins")
	# a misleading stain never yields, and a clue takes at most per_clue pits
	var f := _false_clue(w)
	var dug := 0
	for cell: Vector2i in dv.dig_cells(f, World.PLAYER):
		var rr := dv.trial_dig(p, f, cell, "pickaxe")
		if rr.result == "ok":
			dug += 1
			if not (rr.found as Dictionary).is_empty():
				dug += 1000
	check(dug == mini(int(Discovery.cfg().trial.per_clue), dv.dig_cells(f, World.PLAYER).size() + dug) and dug <= int(Discovery.cfg().trial.per_clue),
			"a misleading stain yields nothing (%d pits) and a clue takes at most %d" % [dug, int(Discovery.cfg().trial.per_clue)])
	check(dv.ground_refusal(f, Vector2i(int(f.x), int(f.y)) + Vector2i(int(f.r) + 4, 0)) != "", "outside the search area nothing is dug")
	# determinism: the same pits in a second world of the seed give the same seam
	var w2 := _world(1)
	var n2 := _miner(w2)
	var c2 := w2.prospecting.clue(str(c.id))
	var r2 := w2.discovery.trial_dig(n2, c2, h.hit, "pickaxe")
	check(not (r2.found as Dictionary).is_empty() and int(r2.found.amount) == int(d.amount) and str(r2.found.ore) == str(d.ore),
			"the same seed and the same pit give the same seam (deterministic)")


# ---------------------------------------------------------------- the opened seam ------------
func _test_opened_seam() -> void:
	var w := _world(1)
	var dv := w.discovery
	var h := _hit_clue(w)
	var n := _miner(w)
	var d: Dictionary = dv.trial_dig(n, h.clue, h.hit, "pickaxe").found
	var amt := int(d.amount)
	var ore := str(d.ore)
	var p := w.player
	p.skills["mining"] = Skills.xp_for_level(5)            # gold needs Mining 3; the same gate as any seam
	p.inv.add("pickaxe")
	var xp0 := int(p.skills.mining)
	var r := w.work_mine(p, d, p.inv, "pickaxe")
	check(r.result == "ok" and int(d.amount) == amt - int(r.n) and _st(w, "mined_" + ore) == int(r.n),
			"the opened seam is mined by the same swing: one unit (or a skilled extra), counted mined_%s" % ore)
	check(int(p.skills.mining) - xp0 == 8 * int(r.n), "8 Mining xp a unit, as any seam")
	var guard := 0
	while int(d.amount) > 0 and guard < 400:
		p.inv.items.erase(ore)
		w.work_mine(p, d, p.inv, "pickaxe")
		p.inv.durability.erase("pickaxe")
		guard += 1
	check(int(d.amount) == 0 and _st(w, "mined_" + ore) == amt, "it is worked out after its finite amount (%d), never more" % amt)
	check(w.deposit_at(Vector2i(int(d.x), int(d.y))) == d.host and str(w.deposit_at(Vector2i(int(d.x), int(d.y))).ore) == "stone",
			"then its host rock is quarried for stone (MIN-B), as any worked-out seam")
	for i in 3:
		w.discovery.dawn()
	check(int(d.amount) == 0, "nothing refills it")
	# the economy_sim ledger: start (0) + found - end = mined
	check(_st(w, "found_" + ore) - int(d.amount) == _st(w, "mined_" + ore), "found_%s - left = mined_%s (the ledger balances)" % [ore, ore])


# ---------------------------------------------------------------- capability -----------------
func _strip(w: World, id: String) -> int:
	var n := 0
	for o: NPC in w.npcs:
		n += o.inv.count(id)
		o.inv.remove(id, o.inv.count(id))
	for hh in w.households:
		n += hh.pantry.count(id)
		hh.pantry.remove(id, hh.pantry.count(id))
	n += w.manor_work.yard.count(id)
	w.manor_work.yard.remove(id, w.manor_work.yard.count(id))
	return n


func _test_capability() -> void:
	var w := _world(1)
	var dv := w.discovery
	var lv0 := dv.level()
	check(lv0 == 1, "the settlers start at mining level 1: surface extraction (seams, miners, pickaxes, carrying) (level %d)" % lv0)
	check(not dv.evaluate().holds[1], "not level 2: no prospector, kit or recorded discovery")
	var picks := _strip(w, "pickaxe")
	w.player.inv.add("pickaxe", 3)
	dv.dawn()
	check(dv.level() == 0 and dv.history.size() == 1 and int(dv.history[0].to) == 0 and str(dv.history[0].why).contains("pickaxe"),
			"with every pickaxe gone the level falls to 0 (the player's own do not count); the history says why: %s" % str(dv.history[-1].why))
	var n := _miner(w)
	dv.dawn()
	check(dv.level() == 1 and dv.history.size() == 2, "a villager's pickaxe again: level 1 again (%d pickaxes were taken)" % picks)
	# level 2 needs a living prospector, a kit, an able smith and a forge, and a recorded discovery
	var pro: NPC = w.brain._first_with_job("laborer")
	if pro == n:
		pro = w.brain._first_with_job("woodcutter")
	w.brain._change_job(pro, Prospecting.JOB, "a test")
	w.player.inv.add(Prospecting.KIT)
	dv.dawn()
	check(dv.level() == 1 and (dv.evaluate().unmet.get(2, []) as Array).has(GameData.item_name(Prospecting.KIT).to_lower()), "a prospector without a kit (the player's does not count): still level 1")
	pro.inv.add(Prospecting.KIT)
	dv.dawn()
	check(dv.level() == 1 and (dv.evaluate().unmet.get(2, []) as Array) == ["a recorded discovery"], "with a kit but no discovery the manor knows: still level 1")
	# a real find: samples, a smith's assay, the prospector's report to the manor
	var s := _smith_ready(w)
	s.skills["smithing"] = Skills.xp_for_level(8)
	var h := _hit_clue(w)
	var c: Dictionary = h.clue
	pro.coins = 100
	var pr := w.prospecting
	var spots: Array = (c.spots as Array).duplicate()
	var bc := Vector2i(int(c.body.x), int(c.body.y))
	spots.sort_custom(func(x, y): return _cheb(x, bc) < _cheb(y, bc))
	for cell: Vector2i in spots.slice(0, 4):
		pr.take_sample(pro, c, cell)
		s.plan.clear()
		pr.assay(pro, s)
	var found_any := pr.records.any(func(r): return str(r.ore) != "")
	for r in pr.records.duplicate():
		pr.report(pro, int(r.id))
	dv.dawn()
	check(found_any and dv.level() == 2 and dv.history[-1].to == 2, "a find reported to the manor completes level 2: prospecting and assay")
	check(not dv.evaluate().holds[2] and not dv.evaluate().holds[3], "levels 3 and 4 do not hold: no pit ramps or timber supports exist yet (MIN-E, MIN-F)")
	pro.alive = false
	dv.dawn()
	check(dv.level() == 1 and str(dv.history[-1].why).contains("prospector"), "the prospector dies: the level falls back to 1 (%s)" % str(dv.history[-1].why))
	var rng0 := w.rng.state
	dv.evaluate()
	check(w.rng.state == rng0, "evaluating the capability draws nothing from world.rng and changes nothing")


# ---------------------------------------------------------------- adoption -------------------
func _test_adoption() -> void:
	var w := _world(1)
	var dv := w.discovery
	w.treasury = 5000
	var m: Dictionary = w.brain.job_market()
	check(m.has("prospector") and int(m.prospector.open) == 1, "at level 1 with unsampled ground and a funded manor the labour market opens a prospector's place")
	w.treasury = 0
	check(int(w.brain.job_market().prospector.open) == 0, "with an empty treasury it does not")
	w.treasury = 5000
	dv.levels[Discovery.INDUSTRY] = 0
	check(int(w.brain.job_market().prospector.open) == 1, "at level 0 it opens all the same: a capability level never gates (owner, Q18-9)")
	dv.levels[Discovery.INDUSTRY] = 1
	# an adult out of work weighs it by the ordinary job rules; with its pay made clearly best, they take it
	var mc: Dictionary = Discovery.cfg().manor
	var wage := int(mc.survey_wage)
	mc.survey_wage = 4000
	w.treasury = 100000
	var n: NPC = w.brain._first_with_job("laborer")
	n.job = ""
	n.left_job = ""
	for hh in w.households.size():
		w.brain.evaluate_household(hh)
	w.brain.seek_work()
	mc.survey_wage = wage
	check(w.npcs.filter(func(o): return o.alive and o.job == Prospecting.JOB).size() == 1, "an adult out of work takes the prospector's place (seek_work)")
	check(int(w.brain.job_market().prospector.open) == 0, "once one prospects, the place is closed")


# ---------------------------------------------------------------- the manor commissions -------
func _test_commissioned() -> void:
	var w := _world(1)
	var mw := w.manor_work
	var dv := w.discovery
	w.treasury = 5000
	mw.post_discovery()
	var sv: Array = mw.jobs.filter(func(j): return j.kind == "survey")
	check(sv.size() == 1 and not mw.jobs.any(func(j): return j.kind == "trial"), "the reeve posts one survey, and no trial pit while the manor knows no find")
	var mjobs := mw.jobs.size()
	dv.levels[Discovery.INDUSTRY] = 0
	mw.post_discovery()
	check(mw.jobs.size() == mjobs, "at level 0 the survey stays posted: a capability level never gates (owner, Q18-9)")
	dv.levels[Discovery.INDUSTRY] = 1
	mw.post_discovery()
	check(mw.jobs.filter(func(j): return j.kind == "survey").size() == 1, "one survey at a time")
	var j: Dictionary = sv[0]
	check(not mw.open_for(World.PLAYER).has(j), "a survey needs a prospector's kit")
	w.player.inv.add(Prospecting.KIT)
	check(mw.open_for(World.PLAYER).has(j), "with a kit the player may take it, as any villager")
	w.player.inv.remove(Prospecting.KIT)
	var smith := _smith_ready(w)
	var n: NPC = w.brain._first_with_job("laborer")
	w.brain._change_job(n, Prospecting.JOB, "a test")
	n.inv.add(Prospecting.KIT)
	n.coins = 60
	n.plan.clear()
	var coins0 := _coins(w)
	var goods0: Dictionary = Census.goods(w)
	var me := World.npc_ref(n.id)
	var clue_id := str(j.clue)
	var done := false
	var took := false
	for i in 2400:
		w.update(0.5)
		if mw.job_of(me) == j:
			took = true
		if took and not mw.jobs.has(j):
			done = true
			break
	check(took and done, "the prospector takes the survey, samples, has the samples assayed and reports (stat %d)" % _st(w, "surveys_reported"))
	var told := w.prospecting.records.filter(func(r): return str(r.clue) == clue_id and str(r.by) == me)
	check(told.size() == int(j.qty) and told.all(func(r): return w.prospecting.knows(World.MANOR, r)), "the manor knows every reading of the survey, barren or not (%d)" % told.size())
	check(_st(w, "manor_job_survey") == 1, "the survey is paid as the manor's work, whatever was found")
	check(_coins(w) == coins0, "coins conserved (wage from the treasury, fees to the smith)")
	var goods1: Dictionary = Census.goods(w)
	check(int(goods1.get(Prospecting.ITEM, 0)) - int(goods0.get(Prospecting.ITEM, 0)) == _st(w, "mined_" + Prospecting.ITEM) - _st(w, "used_" + Prospecting.ITEM),
			"every sample is held or was assayed")
	# level 2: the manor's best find gets a trial pit, dug by a villager with a pickaxe
	var h := _hit_clue(w)
	var c: Dictionary = h.clue
	var rec := {"id": 9000, "sample": 9000, "clue": str(c.id), "x": h.hit.x, "y": h.hit.y, "ore": str(c.body.ore), "grade": int(c.body.grade),
			"confidence": 0.8, "by": me, "assayer": World.npc_ref(smith.id), "day": 0, "known_by": [me]}
	w.prospecting.records.append(rec)          # the prospector's own reading (as an assay would leave it)
	w.prospecting.report(n, 9000)              # told to the manor, as MIN-C built
	dv.dawn()
	check(dv.level() == 2, "with the find recorded the village reaches level 2")
	mw.post_discovery()
	var tj: Array = mw.jobs.filter(func(x): return x.kind == "trial")
	check(tj.size() == 1, "the reeve posts a trial pit for the manor's find")
	var t: Dictionary = tj[0] if not tj.is_empty() else {}
	var digger := _miner(w)
	digger.plan.clear()
	var dref := World.npc_ref(digger.id)
	var deps0 := w.deposits.size()
	var pits0 := _st(w, "trial_pits")
	var coins1 := _coins(w)
	check(mw.take(t, dref) and mw.plan(digger), "a labourer with a pickaxe takes it")
	for i in 1600:
		w.update(0.5)
		if not mw.jobs.has(t):
			break
	check(not mw.jobs.has(t) and _st(w, "trial_pits") == pits0 + 1 and _st(w, "manor_job_trial") == 1, "the trial pit is dug and paid for the labour")
	check(w.deposits.size() == deps0 + (1 if t.get("found", false) else 0), "a seam is added only if the pit struck the body (found: %s)" % str(t.get("found", false)))
	check(_coins(w) == coins1, "coins conserved over the trial pit")


# ---------------------------------------------------------------- saves ----------------------
func _test_saves() -> void:
	var w := _world(2)
	var dv := w.discovery
	var h := _hit_clue(w)
	var n := _miner(w)
	dv.trial_dig(n, h.clue, h.miss, "pickaxe")
	var d: Dictionary = dv.trial_dig(n, h.clue, h.hit, "pickaxe").found
	w.work_mine(n, d, n.inv)
	dv.history.append({"day": 1, "industry": "mining", "from": 1, "to": 0, "why": "test"})
	w.treasury = 5000
	w.manor_work.post_discovery()
	var sd := w.to_dict()
	check(int(sd.save_version) == 17, "no new save version (17)")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(sd)))
	var d2 := w2.discovery.opened(str(h.clue.id))
	check(not d2.is_empty() and int(d2.amount) == int(d.amount) and int(d2.host.amount) == int(d.host.amount) and w2.map.is_solid(h.hit),
			"the opened seam keeps its amount and host rock, and its cell is rock again after a load")
	check(JSON.stringify(w2.discovery.to_dict()) == JSON.stringify(dv.to_dict()), "the pits, the levels and the history are kept exactly")
	check(w2.deposit_at(h.hit) == d2 and w2.discovery.trials_left(w2.prospecting.clue(str(h.clue.id))) == dv.trials_left(h.clue), "it is found by deposit_at and the pits left are the same")
	check(JSON.stringify(w2.manor_work.to_dict()) == JSON.stringify(w.manor_work.to_dict()), "the manor's survey job round-trips")
	var old: Dictionary = JSON.parse_string(JSON.stringify(sd))
	old.erase("discovery")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.discovery.dug.is_empty() and w3.discovery.history.is_empty() and w3.discovery.level() == w3.discovery.evaluate().level,
			"a save without discovery (Build 17 before MIN-D) loads with nothing dug and the level computed")
	old.erase("prospecting")
	old.save_version = 16
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), old)
	check(w4.discovery != null and w4.discovery.level() >= 0 and w4.prospecting.records.is_empty(), "a version 16 save loads too")
