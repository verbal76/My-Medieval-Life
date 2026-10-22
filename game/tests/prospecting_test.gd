extends SceneTree
## MIN-C prospecting (docs/build17/MIN_C_PROSPECTING.md; Mining spec stage 2, sections 4, 5 and 11): clues placed from
## the seed alone, some misleading, never in the deposits; the prospector's kit made only by the anvil recipe
## (work_craft); samples taken by one rule for the player and a villager, finite per clue, one a cell; the assay at a
## smith's forge for a fee and a coal, seeded, uncertain and never certain; findings known only to those told; a
## prospector's day (kit by a CON-01 order, samples, the assay, the report to the manor); coins and goods conserved;
## saves keep it all, and older saves load with none. Run headless:
##   godot --headless --path game --script res://tests/prospecting_test.gd

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
	_test_generation()
	_test_settlement_footprint()
	_test_kit()
	_test_sampling_parity()
	_test_assay()
	_test_uncertainty()
	_test_prospector_day()
	_test_saves()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _coins(w: World) -> int:
	return w.total_coins() - w.coin_sources


func _st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0))


## The first clue with a body (true) or without (false).
func _clue(w: World, with_body: bool) -> Dictionary:
	for c in w.prospecting.clues:
		if (c.body as Dictionary).is_empty() != with_body and (c.spots as Array).size() >= 4:
			return c
	return {}


func _smith_ready(w: World) -> NPC:
	var s: NPC = w.brain._first_with_job("smith")
	s.pos = Vector2(w.brain._workplace_cell(s)) + Vector2(0.5, 0.5)
	s.plan.clear()
	s.inv.add("coal", 4)
	return s


# ---------------------------------------------------------------- generation -----------------
func _test_generation() -> void:
	var a := _world(1)
	var b := _world(1)
	var c := _world(2)
	check(not a.prospecting.clues.is_empty(), "a world has prospecting clues (%d)" % a.prospecting.clues.size())
	check(a.prospecting.fingerprint() == b.prospecting.fingerprint(), "the same seed gives the same clues, bodies and spots")
	check(a.prospecting.fingerprint() != c.prospecting.fingerprint(), "another seed gives other clues")
	var trues := 0
	var falses := 0
	for s in [1, 2, 7]:
		var w := a if s == 1 else (c if s == 2 else _world(7))
		for cl in w.prospecting.clues:
			if (cl.body as Dictionary).is_empty():
				falses += 1
			else:
				trues += 1
	check(trues > 0 and falses > 0, "over seeds 1, 2 and 7 some clues lie over a body (%d) and some mislead (%d)" % [trues, falses])
	var ok := true
	for cl in a.prospecting.clues:
		var cell := Vector2i(int(cl.x), int(cl.y))
		if a.map.is_solid(cell) or not a.map.in_village(cell) or not a.deposit_at(cell).is_empty():
			ok = false
		for sp: Vector2i in cl.spots:
			if a.map.is_solid(sp) or Vector2(sp - cell).length() > float(cl.r) + 0.01:
				ok = false
		var body: Dictionary = cl.body
		if not body.is_empty() and Vector2(Vector2i(int(body.x), int(body.y)) - cell).length() > float(cl.r) * 1.5:
			ok = false
	check(ok, "every stain and sample spot is open village ground inside its area; a body lies within the area, not at a known place")
	var expect: int = a.map.data.deposits.size() + a.underground.seam_records().size()
	check(a.deposits.size() == expect, "no clue or body is a deposit record (deposits: %d, the map's and the gallery's)" % a.deposits.size())
	var rng0 := a.rng.state
	var again := Prospecting.generate(1, a.map)
	check(a.rng.state == rng0 and again.size() == a.prospecting.clues.size(), "generating clues draws nothing from world.rng")


# ---------------------------------------------------------------- the kit --------------------
## ORE-PLACE-01 (owner 2026-10-22): natural deposits belong outside the developed village. On representative seeds no
## stain, sample spot or mineral body lies in the settlement footprint (recomputed here from the village map and the
## margins, independently of Prospecting), clues and bodies remain on the wild ground, and the mine yard's seams stay.
func _test_settlement_footprint() -> void:
	var m := VillageMap.load_default()
	var d: Dictionary = m.data
	var fp: Dictionary = Prospecting.cfg().settlement
	var dev := {}
	var mark := func(x0: int, y0: int, w: int, h: int, mg: int) -> void:
		for y in range(y0 - mg, y0 + h + mg):
			for x in range(x0 - mg, x0 + w + mg):
				dev[Vector2i(x, y)] = true
	for key in ["buildings", "plots", "fields", "pens"]:
		for e in d[key]:
			mark.call(int(e.x), int(e.y), int(e.w), int(e.h), int(fp.structures))
	for c in d.road:
		mark.call(int(c[0]), int(c[1]), 1, 1, int(fp.roads))
	for e in d.stalls:
		mark.call(int(e.x), int(e.y), 1, 1, int(fp.market))
	check(int(fp.structures) > 0 and int(fp.roads) > 0 and int(fp.market) > 0, "the settlement footprint has margins (prospecting.json settlement)")
	for seed_value in [1, 2, 3, 4, 7, 11, 42, 1234]:
		var clues := Prospecting.generate(seed_value, m)
		var inside := 0
		var bodies := 0
		for c in clues:
			var cells: Array = [Vector2i(int(c.x), int(c.y))] + (c.spots as Array)
			if not (c.body as Dictionary).is_empty():
				bodies += 1
				cells.append(Vector2i(int(c.body.x), int(c.body.y)))
			for cell in cells:
				if dev.has(cell):
					inside += 1
		check(inside == 0, "seed %d: no stain, spot or body inside the settlement (%d clues, %d bodies)" % [seed_value, clues.size(), bodies])
		check(clues.size() >= 1 and bodies >= 1, "seed %d: ore evidence remains outside the settlement" % seed_value)
	check(d.deposits.size() == 15, "the mine yard keeps its 15 seams")
	var w := _world(3)
	var c0: Dictionary = w.prospecting.clues[0]
	var built := Vector2i(int(d.buildings[0].x), int(d.buildings[0].y))
	check(w.discovery.ground_refusal(c0, built) != "", "no trial pit inside the settlement")


func _test_kit() -> void:
	var w := _world(1)
	var p := w.player
	var r: Dictionary = GameData.recipes.get("forge_prospecting_kit", {})
	check(str(r.get("station", "")) == "anvil" and (r.get("out", {}) as Dictionary).has(Prospecting.KIT), "the kit is an anvil recipe (forge-made)")
	var c := _clue(w, true)
	var cell: Vector2i = c.spots[0]
	check(w.prospecting.sample_refusal(p, c, cell).contains("kit"), "without a kit no sample can be taken")
	for id in r["in"]:
		p.inv.add(id, int(r["in"][id]))
	var made := _st(w, "made_" + Prospecting.KIT)
	var res := w.player_craft("forge_prospecting_kit")
	check(res.result == "ok" and p.inv.has(Prospecting.KIT) and _st(w, "made_" + Prospecting.KIT) == made + 1,
			"the player forges a kit by work_craft, counted made_prospecting_kit")
	check(not p.inv.has("leather") and not p.inv.has("plank") or res.result != "ok", "its iron, plank and leather are used up")


# ---------------------------------------------------------------- sampling -------------------
func _test_sampling_parity() -> void:
	var w := _world(1)
	var p := w.player
	var n: NPC = w.brain._first_with_job("laborer")
	n.job = Prospecting.JOB
	p.inv.add(Prospecting.KIT)
	n.inv.add(Prospecting.KIT)
	var c := _clue(w, true)
	var pr := w.prospecting
	var left0 := pr.samples_left(c)
	var coins0 := _coins(w)
	var pxp := int(p.skills.get("mining", 0))
	var nxp := int(n.skills.get("mining", 0))
	var rp := pr.take_sample(p, c, c.spots[0])
	var rn := pr.take_sample(n, c, c.spots[1])
	check(rp.result == "ok" and rn.result == "ok", "the player and a villager each take a sample by one rule")
	check(p.inv.count(Prospecting.ITEM) == 1 and n.inv.count(Prospecting.ITEM) == 1 and pr.bag_of(p).size() == 1 and pr.bag_of(n).size() == 1,
			"each sample goes to its taker's pack with its origin in their bag")
	check(int(p.skills.get("mining", 0)) - pxp == int(n.skills.get("mining", 0)) - nxp and int(p.skills.get("mining", 0)) - pxp == int(Prospecting.cfg().sample_xp),
			"the same Mining xp for both (%d)" % int(Prospecting.cfg().sample_xp))
	var full := int(GameData.item(Prospecting.KIT).durability)
	check(int(p.inv.durability.get(Prospecting.KIT, full)) <= full and int(n.inv.durability.get(Prospecting.KIT, full)) <= full, "the kit wears for both")
	check(_st(w, "mined_" + Prospecting.ITEM) == 2 and pr.samples_left(c) == left0 - 2, "samples are counted mined_ore_sample and the clue's pool falls")
	check(pr.take_sample(p, c, c.spots[0]).result == "refused", "a cell sampled once cannot be sampled again")
	check(pr.sample_refusal(p, c, Vector2i(int(c.x), int(c.y)) + Vector2i(int(c.r) + 3, 0)) != "", "outside the search area nothing can be sampled")
	pr.take_sample(p, c, c.spots[2])
	pr.take_sample(n, c, c.spots[3])
	check(pr.samples_left(c) == 0 and pr.take_sample(p, c, c.spots[4] if c.spots.size() > 4 else c.spots[0]).result == "refused",
			"a clue gives samples_per_clue samples, then is sampled out (finite)")
	check(_coins(w) == coins0, "sampling moves no coins")
	# a sample dropped leaves the bag with it (oldest first)
	p.inv.remove(Prospecting.ITEM, 1)
	check(pr.bag_of(p).size() == 1, "a sample gone from the pack leaves the bag")


# ---------------------------------------------------------------- assay ----------------------
func _test_assay() -> void:
	var w := _world(1)
	var p := w.player
	var pr := w.prospecting
	var s := _smith_ready(w)
	p.inv.add(Prospecting.KIT)
	var c := _clue(w, true)
	pr.take_sample(p, c, c.spots[0])
	p.coins = 2
	check(pr.assay(p, s).why.contains("coins"), "an assay needs the fee")
	p.coins = 50
	var coal := s.inv.count("coal")
	s.inv.remove("coal", coal)
	check(pr.assayer_refusal(p, s).contains("coal"), "an assay needs the smith's coal")
	s.inv.add("coal", coal)
	var coins0 := _coins(w)
	var pc := p.coins
	var sc := s.coins
	var r := pr.assay(p, s)
	check(r.result == "ok", "the smith assays the player's sample at the forge")
	var fee := int(Prospecting.cfg().assay.fee)
	check(p.coins == pc - fee and s.coins == sc + fee and _coins(w) == coins0, "the fee passes from the player's purse to the smith's; no coin made or lost")
	check(s.inv.count("coal") == coal - 1 and _st(w, "used_coal") >= 1 and p.inv.count(Prospecting.ITEM) == 0 and _st(w, "used_" + Prospecting.ITEM) == 1,
			"the sample and a coal are used up and counted")
	check(str(s.doing).contains("assay") and not s.plan.is_empty() and str(s.plan[-1].get("act", "")) == "assay_done", "the smith works the forge for the assay's time")
	check(pr.assayer_refusal(p, s) != "", "a smith busy with an assay takes no other")
	var rec: Dictionary = r.record
	check(pr.knows(World.PLAYER, rec) and pr.knows(World.npc_ref(s.id), rec) and not pr.knows(World.MANOR, rec),
			"the reading is known to the player and the smith only")
	check(float(rec.confidence) < 1.0 and float(rec.confidence) <= float(Prospecting.cfg().assay.most), "an assay is never certain (%.2f)" % float(rec.confidence))
	check(pr.reading_text(rec) != "", "the reading in words: %s" % pr.reading_text(rec))
	# seeded: the same sample and assayer read the same, whatever world.rng does
	var sample := {"id": 77, "clue": str(c.id), "x": c.spots[0].x, "y": c.spots[0].y, "skill": 1}
	var r1 := pr.reading(sample, s)
	w.rng.randf()
	w.rng.randf()
	check(JSON.stringify(r1) == JSON.stringify(pr.reading(sample, s)), "a reading depends on the seed, the sample and the assayer, not on world.rng")
	var f := pr.findings(World.PLAYER)
	check(f.size() == 1 and str(f[0].clue) == str(c.id) and float(f[0].confidence) <= 0.95, "the player's findings: one clue, never certain")
	check(pr.findings(World.MANOR).is_empty(), "the manor knows nothing it was not told")
	# a sample of unknown origin cannot be assayed
	var w2 := _world(1)
	var s2 := _smith_ready(w2)
	w2.player.inv.add(Prospecting.ITEM)
	w2.player.coins = 50
	check(w2.prospecting.assay(w2.player, s2).why.contains("Nobody knows"), "a sample of unknown origin cannot be assayed")


# ---------------------------------------------------------------- uncertainty ----------------
func _test_uncertainty() -> void:
	var w := _world(1)
	var pr := w.prospecting
	var s: NPC = w.brain._first_with_job("smith")
	var t := _clue(w, true)
	var f := _clue(w, false)
	var found := 0
	var missed := 0
	var traces := 0
	var barren := 0
	var top := 0.0
	for i in 200:
		var cell_t: Vector2i = t.spots[i % t.spots.size()]
		var rt := pr.reading({"id": 1000 + i, "clue": str(t.id), "x": cell_t.x, "y": cell_t.y, "skill": 1}, s)
		if str(rt.ore) == str(t.body.ore):
			found += 1
			if absi(int(rt.grade) - int(t.body.grade)) > 2:
				missed += 1000
		elif str(rt.ore) == "":
			missed += 1
		var cell_f: Vector2i = f.spots[i % f.spots.size()]
		var rf := pr.reading({"id": 5000 + i, "clue": str(f.id), "x": cell_f.x, "y": cell_f.y, "skill": 1}, s)
		if str(rf.ore) == "":
			barren += 1
		else:
			traces += 1
		top = maxf(top, float(rf.confidence))
	check(found > 0 and missed > 0 and missed < 1000, "over a body most assays may find it, some miss it (found %d, missed %d), grades within two steps" % [found, missed])
	check(barren > traces and traces > 0, "over a misleading stain most assays find nothing, a few report traces (%d barren, %d traces)" % [barren, traces])
	var master := NPC.new()
	master.skills = {"smithing": Skills.xp_for_level(10)}
	var best := pr.reading({"id": 9, "clue": str(t.id), "x": t.spots[0].x, "y": t.spots[0].y, "skill": 10}, master)
	check(float(best.confidence) <= 0.9 + 0.001, "even a master smith's assay of a master's sample is not certain (%.2f)" % float(best.confidence))


# ---------------------------------------------------------------- a prospector's day ---------
func _test_prospector_day() -> void:
	var w := _world(1)
	var pr := w.prospecting
	var smith := _smith_ready(w)
	for id in GameData.recipes.forge_prospecting_kit["in"]:
		smith.inv.add(id, int(GameData.recipes.forge_prospecting_kit["in"][id]) + 1)
	var n: NPC = w.brain._first_with_job("laborer")
	w.brain._change_job(n, Prospecting.JOB, "a test")
	n.coins = 200
	n.plan.clear()
	var coins0 := _coins(w) + w.regions.coins()
	var goods0: Dictionary = Census.goods(w)
	var ordered := false
	var had_kit := false
	var guard := 0
	var me := World.npc_ref(n.id)
	var unreported := func() -> bool: return pr.records.any(func(r): return str(r.by) == me and str(r.ore) != "" and not pr.knows(World.MANOR, r))
	while guard < 1560 and (pr.records.filter(func(r): return str(r.by) == me).size() < 2 or unreported.call()):
		w.update(0.5)
		guard += 1
		if w.contracts.list.any(func(c): return str(c.item) == Prospecting.KIT):
			ordered = true
		if n.inv.has(Prospecting.KIT):
			had_kit = true
	var mine := pr.records.filter(func(r): return str(r.by) == World.npc_ref(n.id))
	check(ordered, "a prospector without a kit orders one from a smith by a CON-01 contract")
	check(had_kit and _st(w, "made_" + Prospecting.KIT) >= 1, "the smith forges it (work_craft) and it reaches the prospector")
	check(_st(w, "mined_" + Prospecting.ITEM) >= 2, "the prospector takes samples at the clues (%d)" % _st(w, "mined_" + Prospecting.ITEM))
	check(not mine.is_empty() and _st(w, "assays") >= 1, "and has them assayed by the smith (%d readings)" % mine.size())
	check(not unreported.call(), "every find is reported to the manor (%d of %d readings found traces)" % [mine.filter(func(r): return str(r.ore) != "").size(), mine.size()])
	check(_coins(w) + w.regions.coins() == coins0, "coins conserved over the prospector's day (fees, the kit's price)")
	var goods1: Dictionary = Census.goods(w)
	var held := int(goods1.get(Prospecting.ITEM, 0))
	check(held == _st(w, "mined_" + Prospecting.ITEM) - _st(w, "used_" + Prospecting.ITEM), "every sample is held or was assayed (%d held)" % held)
	check(int(goods1.get(Prospecting.KIT, 0)) == int(goods0.get(Prospecting.KIT, 0)) + _st(w, "made_" + Prospecting.KIT) - _st(w, "broke_" + Prospecting.KIT),
			"every kit is held, made or worn out")


# ---------------------------------------------------------------- saves ----------------------
func _test_saves() -> void:
	var w := _world(2)
	var pr := w.prospecting
	var s := _smith_ready(w)
	w.player.inv.add(Prospecting.KIT)
	w.player.coins = 100
	var c := _clue(w, true)
	pr.take_sample(w.player, c, c.spots[0])
	pr.take_sample(w.player, c, c.spots[1])
	pr.assay(w.player, s)
	var d := w.to_dict()
	check(int(d.save_version) == World.SAVE_VERSION and World.SAVE_VERSION >= 17, "no new save version of its own (17; 18 is CC-01)")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var p2 := w2.prospecting
	check(p2.fingerprint() == pr.fingerprint(), "the clues are the same after a load (generated from the seed)")
	check(p2.samples_left(p2.clue(str(c.id))) == pr.samples_left(c) and p2.sampled(p2.clue(str(c.id)), c.spots[0]), "the cells sampled are kept")
	check(p2.bag_of(w2.player).size() == 1 and p2.records.size() == 1 and JSON.stringify(p2.records[0]) == JSON.stringify(pr.records[0]),
			"the sample carried, its origin and the reading are kept exactly")
	check(p2.next_sample == pr.next_sample and p2.next_record == pr.next_record, "the id counters are kept")
	var s2 := _smith_ready(w2)
	check(p2.assay(w2.player, s2).result == "ok", "the sample carried over the save can still be assayed")
	var old: Dictionary = JSON.parse_string(JSON.stringify(d))
	old.erase("prospecting")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.prospecting.records.is_empty() and w3.prospecting.taken.is_empty() and not w3.prospecting.clues.is_empty(),
			"a save without prospecting (Build 16, or 17 before MIN-C) loads with clues and nothing sampled or known")
	old.save_version = 16
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), old)
	check(w4.prospecting != null and w4.prospecting.bag_of(w4.player).is_empty(), "a version 16 save loads too")
