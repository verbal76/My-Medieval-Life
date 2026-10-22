extends SceneTree
## MIN-E open-pit excavation (docs/build17/MIN_E_OPEN_PIT.md; Mining spec stage 3, sections 6, 7 and 11, phase E):
## sites on clear common ground only, the same each game of a seed; one dig rule for the player and a villager (same
## item, xp and refusals, PAR-01); every unit dug leaves the pit's finite ground and is counted, earth lies on the spoil
## heaps, backfill puts it back (ground + dug - backfilled = the pit's whole ground, at every step, and the goods census
## moves by exactly that); terraces and a ramp, no walkable pit cell ever cut off (DVW-A10), every one reachable by the
## village's path-finder; a body within reach of a cell dug down to the rock opens as an ordinary seam (OD-28), mined by
## work_mine; the manor stakes a pit only for a find no trial can reach and pays a load's digging from the treasury
## (coins conserved); a level-0 village still digs and the manor still posts (Q18-9), a finished ramp is a reported
## structure; determinism; saves keep it all and older saves load with no pits. Run headless:
##   godot --headless --path game --script res://tests/openpit_test.gd

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
	_test_sites()
	_test_parity()
	_test_conservation()
	_test_cut_off()
	_test_exposure()
	_test_manor()
	_test_level0()
	_test_determinism()
	_test_saves()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0))


func _coins(w: World) -> int:
	return w.total_coins() - w.coin_sources + w.caravan_purse


func _sites(w: World) -> Array:
	var out := []
	for y in w.map.h:
		for x in w.map.w:
			var o := Vector2i(x, y)
			if w.pits.site_open(o) and w.pits.site_refusal(o) == "":
				out.append(o)
	return out


## A labourer (or miner) with a pickaxe and a shovel, moved off the pit.
func _digger(w: World) -> NPC:
	var n: NPC = w.brain._first_with_job("laborer")
	if n == null:
		n = w.brain._first_with_job("miner")
	if not n.inv.has("pickaxe"):
		n.inv.add("pickaxe")
	if not n.inv.has("shovel"):
		n.inv.add("shovel")
	return n


## Everyone off the ground of pit `p` and its border, so no dig is refused for a person standing there.
func _clear(w: World, p: Dictionary) -> void:
	var far := Vector2(w.manor_work.yard_cell()) + Vector2(0.5, 0.5)
	var block := OpenPits.rect(p).grow(2)
	for n: NPC in w.npcs:
		if block.has_point(n.cell()):
			n.pos = far
			n.plan.clear()
	if block.has_point(Vector2i(w.player.pos.floor())):
		w.player.pos = far


## Every walkable cell of the pit is reached by the village's path-finder from its border (DVW-A10).
func _reachable(w: World, p: Dictionary) -> bool:
	var start := Vector2i(-1, -1)
	var border := OpenPits.rect(p).grow(1)
	for y in range(border.position.y, border.end.y):
		for x in range(border.position.x, border.end.x):
			var c := Vector2i(x, y)
			if start.x < 0 and not OpenPits.rect(p).has_point(c) and not w.map.is_solid(c):
				start = c
	for i in OpenPits.size() * OpenPits.size():
		var c := OpenPits.cell_of(p, i)
		if w.map.is_solid(c):
			continue
		var path := w.map.find_path(start, c)
		if path.is_empty() or Vector2i(path[path.size() - 1]) != c:
			return false
	return true


func _sum(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n


## Ground + dug - backfilled = the whole ground, item by item (the pit's own ledger).
func _pit_ledger_ok(w: World, start_dug := {}, start_fill := {}) -> bool:
	var vol := {}
	for p in w.pits.pits:
		var v := OpenPits.volume(p)
		for id in v:
			vol[id] = int(vol.get(id, 0)) + int(v[id])
	var left := w.pits.ground_left()
	for id in vol:
		var dug := _st(w, "dug_" + id) - int(start_dug.get(id, 0))
		var back := _st(w, "backfilled_" + id) - int(start_fill.get(id, 0))
		if int(left.get(id, 0)) + dug - back != int(vol[id]) or _st(w, "pit_ground_" + id) != int(vol[id]):
			return false
	return true


# ---------------------------------------------------------------- sites ----------------------
func _test_sites() -> void:
	var counts := []
	for sd in [1, 2, 7]:
		counts.append(_sites(_world(sd)).size())
	check(counts.all(func(n): return n > 0), "every seed has clear ground for a pit (sites %s)" % JSON.stringify(counts))
	var a := _sites(_world(7))
	var b := _sites(_world(7))
	check(JSON.stringify(a) == JSON.stringify(b), "the same seed gives the same sites")
	var w := _world(1)
	var pp := w.pits
	var road := Vector2i(int(w.map.data.road[40][0]), int(w.map.data.road[40][1]))
	check(pp.site_refusal(road - Vector2i(2, 2)) != "", "no pit is staked over the road")
	var o: Vector2i = _sites(w)[0]
	var p := pp.open_pit(World.PLAYER, o)
	check(not p.is_empty() and (p.heaps as Array).size() == int(OpenPits.cfg().heaps), "a pit is staked with its spoil heaps")
	var vol := OpenPits.volume(p)
	check(_st(w, "pit_ground_topsoil") == int(vol.topsoil) and _st(w, "pit_ground_stone") == int(vol.stone) and _sum(vol) == 160,
			"its whole ground enters the books when it is staked (%s)" % JSON.stringify(vol))
	var inside := OpenPits.cell_of(p, 6)
	var edge := OpenPits.rect(p).position - Vector2i(1, 1)
	var heap := Vector2i(int(p.heaps[0].x), int(p.heaps[0].y))
	check(w.plant_refusal(inside) != "" and w.plant_refusal(edge) != "" and w.plant_refusal(heap) != "",
			"nothing is planted (or a trial pit dug) in the pit, on its border or on a heap")
	check(w.property.can_claim(Rect2i(OpenPits.rect(p).position, Vector2i(3, 3))) != "" and pp.site_refusal(o + Vector2i(2, 0)) != "",
			"no land is claimed over it and no second pit overlaps it")
	check(not w.map.is_solid(inside) and not w.map.is_solid(heap), "a staked pit blocks nothing until it is dug, an empty heap nothing")


## MIN-E-Q4: the tool `who` digs cell `c` of pit `p` with next (a shovel for earth, a pickaxe for rock).
func _tool(pp: OpenPits, who, p: Dictionary, c: Vector2i) -> String:
	return OpenPits.held_tool(who, pp.tool_needed(p, c))


# ---------------------------------------------------------------- parity ---------------------
func _test_parity() -> void:
	var w := _world(1)
	var pp := w.pits
	var p := pp.open_pit(World.PLAYER, _sites(w)[0])
	_clear(w, p)
	var pl := w.player
	if not pl.inv.has("pickaxe"):
		pl.inv.add("pickaxe")
	if not pl.inv.has("shovel"):
		pl.inv.add("shovel")
	var n := _digger(w)
	var a := OpenPits.cell_of(p, 0)
	var b := OpenPits.cell_of(p, 4)
	check(pp.dig_refusal(n, p, a, "").contains("shovel") and pp.dig_refusal(pl, p, a, "axe").contains("shovel") and pp.dig_refusal(pl, p, a, "pickaxe").contains("shovel"),
			"digging topsoil needs a shovel, for both (owner MIN-E-Q4; a pickaxe will not do)")
	var pxp := int(pl.skills.get("mining", 0))
	var nxp := int(n.skills.get("mining", 0))
	var t0 := pl.inv.count("topsoil")
	var rp := pp.dig(pl, p, a, pl.inv, _tool(pp, pl, p, a))
	var rn := pp.dig(n, p, b, n.inv, _tool(pp, n, p, b))
	check(rp.result == "ok" and rn.result == "ok" and str(rp.item) == "topsoil" and str(rn.item) == "topsoil", "the player and a villager dig the same layer by the same rule")
	check(int(pl.skills.get("mining", 0)) - pxp == int(OpenPits.cfg().xp) and int(n.skills.get("mining", 0)) - nxp == int(OpenPits.cfg().xp),
			"the same Mining xp for both (%d a unit)" % int(OpenPits.cfg().xp))
	check(pl.inv.count("topsoil") == t0 + 1 and n.inv.count("topsoil") >= 1 and _st(w, "dug_topsoil") == 2, "each unit goes to the digger and is counted dug_topsoil")
	check(not w.map.is_solid(a), "a cell with topsoil left is still walkable ground")
	pp.dig(pl, p, a, pl.inv, _tool(pp, pl, p, a))
	check(w.map.is_solid(a) and OpenPits.depth_of(int(p.dug[0])) == 1, "stripped of its topsoil, an edge cell is a step down: solid")
	var ramp := OpenPits.cell_of(p, OpenPits.size() / 2)
	pp.dig(n, p, ramp, n.inv, _tool(pp, n, p, ramp))
	pp.dig(n, p, ramp, n.inv, _tool(pp, n, p, ramp))
	check(not w.map.is_solid(ramp), "the ramp stays walkable as it is dug")


# ---------------------------------------------------------------- conservation ---------------
func _test_conservation() -> void:
	var w := _world(1)
	var pp := w.pits
	var p := pp.open_pit(World.PLAYER, _sites(w)[0])
	_clear(w, p)
	var n := _digger(w)
	n.inv.add("pickaxe", 30)
	n.inv.add("shovel", 30)
	var g0 := Census.goods(w)
	var digs := 0
	var ledger_ok := true
	var reach_ok := true
	var stuck := false
	while true:
		var c := pp.next_dig(p, n.cell(), n.cell())        # the digger may step off its own cell to dig it
		if c.x < 0:
			break
		n.pos = Vector2(pp.stand_for(p, OpenPits.index(p, c), n.cell())) + Vector2(0.5, 0.5)
		var r := pp.dig(n, p, c, n.inv, _tool(pp, n, p, c))
		if r.result != "ok":
			stuck = true
			break
		digs += 1
		if not n.inv.has("pickaxe"):
			n.inv.add("pickaxe")
		if not n.inv.has("shovel"):
			n.inv.add("shovel")
		if digs % 12 == 0:
			pp.tip(p, n.inv)
			ledger_ok = ledger_ok and _pit_ledger_ok(w)
			reach_ok = reach_ok and _reachable(w, p)
	pp.tip(p, n.inv)
	var vol := OpenPits.volume(p)
	check(not stuck and digs == _sum(vol) and pp.done(p), "the whole pit is dug, unit by unit, with no dig ever stuck (%d units)" % digs)
	check(ledger_ok and _pit_ledger_ok(w) and _sum(pp.ground_left()) == 0, "ground + dug = the pit's whole ground at every step, and nothing is left")
	check(reach_ok and _reachable(w, p), "every walkable pit cell is reachable by the path-finder at every step (DVW-A10)")
	var g1 := Census.goods(w)
	var moved := true
	for id in vol:
		if int(g1.get(id, 0)) - int(g0.get(id, 0)) != int(vol[id]) or _st(w, "dug_" + id) != int(vol[id]):
			moved = false
	check(moved, "the goods census rises by exactly what was dug, item by item (%s)" % JSON.stringify(vol))
	var heaped := pp.goods()
	check(int(heaped.get("topsoil", 0)) == int(vol.topsoil) and int(heaped.get("dirt", 0)) == int(vol.dirt) and int(heaped.get("spoil", 0)) == int(vol.spoil) and not heaped.has("stone"),
			"all the earth lies on the spoil heaps, the stone with the digger (%d stone)" % n.inv.count("stone"))
	check(w.map.is_solid(Vector2i(int(p.heaps[0].x), int(p.heaps[0].y))), "a heap holding earth is a solid cell")
	var terraces := true
	for i in OpenPits.size() * OpenPits.size():
		if OpenPits.depth_of(int(p.dug[i])) != OpenPits.target(i) or w.map.is_solid(OpenPits.cell_of(p, i)) == OpenPits.is_ramp(i):
			terraces = false
	check(terraces and pp.ramp_done(p), "terraces: the edge 2 layers deep, the next ring 3, the middle 4; the ramp walkable, the rest solid")
	# backfill: the last dug goes back first; the ground rises by it
	var a := OpenPits.cell_of(p, 0)
	var held := Census.goods(w)
	check(pp.fill_refusal(p, a, n.inv) != "", "nothing goes back without the earth it needs")
	pp.take(p, "dirt", 3, n.inv)
	pp.take(p, "topsoil", 2, n.inv)
	var filled := 0
	for k in 5:
		if pp.backfill(p, a, n.inv).result == "ok":
			filled += 1
	check(filled == 5 and int(p.dug[0]) == 0 and not w.map.is_solid(a) and _st(w, "backfilled_dirt") == 3 and _st(w, "backfilled_topsoil") == 2,
			"a cell filled back (3 dirt, then 2 topsoil) is level ground again, counted backfilled_")
	var g2 := Census.goods(w)
	check(_pit_ledger_ok(w) and int(g2.get("dirt", 0)) == int(held.get("dirt", 0)) - 3 and int(g2.get("topsoil", 0)) == int(held.get("topsoil", 0)) - 2 and _reachable(w, p),
			"backfill moves goods back into the ground, the books balance and the pit stays reachable")


# ---------------------------------------------------------------- DVW-A10 --------------------
func _test_cut_off() -> void:
	var w := _world(2)
	var pp := w.pits
	var p := pp.open_pit(World.PLAYER, _sites(w)[0])
	_clear(w, p)
	var n := _digger(w)
	var s := OpenPits.size()
	var at := func(x: int, y: int) -> Vector2i: return OpenPits.cell_of(p, y * s + x)
	for xy in [[4, 3], [3, 4], [3, 2]]:
		pp.dig(n, p, at.call(xy[0], xy[1]), n.inv, _tool(pp, n, p, at.call(xy[0], xy[1])))
		pp.dig(n, p, at.call(xy[0], xy[1]), n.inv, _tool(pp, n, p, at.call(xy[0], xy[1])))
	var d: Vector2i = at.call(2, 3)
	var x: Vector2i = at.call(3, 3)
	check(pp.dig(n, p, d, n.inv, _tool(pp, n, p, d)).result == "ok", "the first unit of a cell that holds the way to another is dug (it stays level)")
	var r := pp.dig(n, p, d, n.inv, _tool(pp, n, p, d))
	check(r.result == "refused" and str(r.why).contains("cut off") and not w.map.is_solid(d), "the dig that would wall a level cell in is refused (%s)" % str(r.why))
	check(pp.dig(n, p, x, n.inv, _tool(pp, n, p, x)).result == "ok" and pp.dig(n, p, x, n.inv, _tool(pp, n, p, x)).result == "ok", "the enclosed cell itself can be dug first")
	check(pp.dig(n, p, d, n.inv, _tool(pp, n, p, d)).result == "ok" and _reachable(w, p), "then the other, and the pit stays reachable")


# ---------------------------------------------------------------- exposure -------------------
## A clue's body and the site nearest it from which a cell dug to the rock reaches it: {clue, origin, cells}, or {}.
func _exposable(w: World) -> Dictionary:
	var reach := int(OpenPits.cfg().expose_reach)
	for c in w.prospecting.clues:
		var body: Dictionary = c.body
		if body.is_empty():
			continue
		var o := w.pits.best_site(Vector2(int(body.x), int(body.y)))
		if o.x <= -1000:
			continue
		var cells := []
		for i in OpenPits.size() * OpenPits.size():
			var cc := OpenPits.cell_of({"x": o.x, "y": o.y}, i)
			if not OpenPits.is_ramp(i) and OpenPits.target(i) >= OpenPits.rock_depth() and maxi(absi(cc.x - int(body.x)), absi(cc.y - int(body.y))) <= reach:
				cells.append(i)
		if not cells.is_empty():
			return {"clue": c, "origin": o, "cells": cells}
	return {}


func _test_exposure() -> void:
	var found := false
	for sd in [1, 7]:
		var w := _world(sd)
		var e := _exposable(w)
		if e.is_empty():
			continue
		found = true
		var pp := w.pits
		var c: Dictionary = e.clue
		var p := pp.open_pit(World.PLAYER, e.origin)
		_clear(w, p)
		var n := _digger(w)
		n.inv.add("pickaxe", 20)
		n.inv.add("shovel", 20)
		var deps := w.deposits.size()
		var seam := {}
		var guard := 0
		while seam.is_empty() and guard < 400:
			guard += 1
			var cell := pp.next_dig(p, n.cell())
			if cell.x < 0:
				break
			var r := pp.dig(n, p, cell, n.inv, _tool(pp, n, p, cell))
			if r.result == "ok" and not (r.exposed as Dictionary).is_empty():
				seam = r.exposed
			pp.tip(p, n.inv)
		check(not seam.is_empty() and str(seam.ore) == str(c.body.ore) and str(seam.found) == str(c.id) and int(seam.pit) == int(p.id),
				"seed %d: digging down to the rock beside the body opens it: a seam of %s" % [sd, str(c.body.ore)])
		if seam.is_empty():
			continue
		var sc := Vector2i(int(seam.x), int(seam.y))
		check(w.deposits.size() == deps + 1 and seam.has("host") and int(seam.amount) == w.discovery.body_amount(str(c.body.ore), int(c.body.grade)),
				"it is one ordinary deposit record of the body's finite amount (%d), with host rock" % int(seam.amount))
		check(_st(w, "found_" + str(c.body.ore)) == int(seam.amount) and _st(w, "pit_seams") == 1 and w.map.is_solid(sc) and w.deposit_at(sc) == seam,
				"counted found_%s, solid, found by deposit_at" % str(c.body.ore))
		check(pp.dig_ground_refusal(p, sc).contains("seam"), "the pit is not dug through the seam: it is mined")
		var stand := pp.stand_beside(sc, sc)
		n.pos = Vector2(stand) + Vector2(0.5, 0.5)
		var m0 := _st(w, "mined_" + str(seam.ore))
		var a0 := int(seam.amount)
		var mr := w.work_mine(n, seam, n.inv)
		check(stand.x >= 0 and mr.result in ["ok", "gold"] and (mr.result == "gold" or (int(seam.amount) < a0 and _st(w, "mined_" + str(seam.ore)) == m0 + a0 - int(seam.amount))),
				"the seam is mined by work_mine from the pit beside it, counted mined_ (%s)" % str(mr.result))
		check(w.discovery.trial_dig(n, c, sc, "shovel").result == "refused", "the clue is opened: no trial pit finds it again")
	check(found, "seed 1 or 7 has a body an open pit can reach")


# ---------------------------------------------------------------- the manor ------------------
func _test_manor() -> void:
	var w: World = null
	var e := {}
	for sd in [1, 7]:
		w = _world(sd)
		e = _exposable(w)
		if not e.is_empty():
			break
	check(not e.is_empty(), "a find an open pit can reach exists")
	if e.is_empty():
		return
	var c: Dictionary = e.clue
	var pr: Prospecting = w.prospecting
	var dv: Discovery = w.discovery
	var mw: ManorWork = w.manor_work
	w.treasury = 5000
	pr.records.append({"id": 9001, "sample": 9001, "clue": str(c.id), "x": int(c.body.x), "y": int(c.body.y), "ore": str(c.body.ore),
			"grade": 3, "confidence": 0.9, "by": World.MANOR, "assayer": World.MANOR, "day": 0, "known_by": [World.MANOR]})
	mw.post_pits()
	var trial_first: bool = w.pits.pits.is_empty() or dv.next_cell(c).x < 0
	check(trial_first, "while a trial pit can still reach the find, the manor stakes no open pit for it")
	var used := []
	for k in int(Discovery.cfg().trial.per_clue):
		used.append([0, 0, World.MANOR, 0])
	dv.dug[str(c.id)] = used
	mw.post_pits()
	var p := w.pits.manor_pit()
	var j := {}
	for jj in mw.jobs:
		if jj.kind == "excavate":
			j = jj
	check(not p.is_empty() and str(p.owner) == World.MANOR and str(p.for) == str(c.id), "with the trial pits used up, the manor stakes an open pit for its find")
	check(not j.is_empty() and int(j.pit) == int(p.id) and int(j.qty) == int(GameData.b("carry_ore")) and int(j.wage) == ManorWork.excavate_wage(),
			"and posts one excavate job: a load of %d at the quarry rate (%d coins)" % [int(j.get("qty", 0)), ManorWork.excavate_wage()])
	mw.post_pits()
	check(mw.jobs.filter(func(x): return x.kind == "excavate").size() == 1, "one excavate job at a time")
	_clear(w, p)
	var n := _digger(w)
	var who := World.npc_ref(n.id)
	var coins0 := _coins(w)
	var g0 := Census.goods(w)
	var c0 := n.coins
	var t0 := w.treasury
	check(mw.take(j, who), "a labourer takes it")
	var steps := 0
	while not mw.job_of(who).is_empty() and steps < 40:
		steps += 1
		mw.do_step(j, who, n.inv)
		if not n.inv.has("pickaxe"):
			n.inv.add("pickaxe")
		if not n.inv.has("shovel"):
			n.inv.add("shovel")
	var dug := _st(w, "dug_topsoil") + _st(w, "dug_dirt") + _st(w, "dug_spoil") + _st(w, "dug_stone")
	check(mw.job_of(who).is_empty() and dug == int(j.qty) and n.coins - c0 == int(j.wage) and t0 - w.treasury == int(j.wage),
			"the load is dug and tipped, the wage paid from the treasury (%d units, %d coins)" % [dug, n.coins - c0])
	check(_coins(w) == coins0, "coins are conserved")
	var g1 := Census.goods(w)
	var earth := 0
	for id in OpenPits.earth_items():
		earth += int(g1.get(id, 0)) - int(g0.get(id, 0))
	check(earth + int(g1.get("stone", 0)) - int(g0.get("stone", 0)) == dug and _sum(w.pits.goods()) == earth and _pit_ledger_ok(w),
			"the earth is on the pit's heaps, nothing made or lost (%d)" % earth)
	check(_st(w, "manor_job_excavate") == 1, "counted as manor work done")
	# the villager's own plan: walk beside the pit and dig
	mw.post_pits()
	var j2 := {}
	for jj in mw.jobs:
		if jj.kind == "excavate":
			j2 = jj
	check(not j2.is_empty() and mw.take(j2, who) and mw.plan(n) and n.plan.size() == 2 and n.plan[1].get("act", "") == "mj_step",
			"the next load is planned: walk beside the cell, then dig")
	var before := _st(w, "pit_units_dug")
	for k in 600:
		if _st(w, "pit_units_dug") > before:
			break
		if n.plan.is_empty() and not mw.job_of(who).is_empty():
			mw.plan(n)
		w.update(0.5)
	check(_st(w, "pit_units_dug") > before, "the villager walks there and digs by its plan (%d units)" % (_st(w, "pit_units_dug") - before))


# ---------------------------------------------------------------- Q18-9 ----------------------
func _test_level0() -> void:
	var w := _world(2)
	w.player.home = ""                            # MIN-D2: no resident player
	for o: NPC in w.npcs:                         # MIN-SKILLCAP: level 1 needs a resident able to mine (a pickaxe), not a job title
		o.inv.remove("pickaxe", o.inv.count("pickaxe"))
	for hh in w.households:
		hh.pantry.remove("pickaxe", hh.pantry.count("pickaxe"))
	w.manor_work.yard.remove("pickaxe", w.manor_work.yard.count("pickaxe"))
	var dv := w.discovery
	check(dv.evaluate().level == 0, "a village where nobody holds a pickaxe is at mining level 0")
	var pp := w.pits
	var p := pp.open_pit(World.PLAYER, _sites(w)[0])
	_clear(w, p)
	var n: NPC = w.brain._first_with_job("laborer")
	if n == null:
		n = w.brain._first_with_job("miner")
	if not n.inv.has("pickaxe"):
		n.inv.add("pickaxe")
	if not n.inv.has("shovel"):
		n.inv.add("shovel")
	var ok := true
	for i in OpenPits.size() * OpenPits.size():
		if OpenPits.is_ramp(i):
			while int(p.dug[i]) < OpenPits.cap(i):
				ok = ok and pp.dig(n, p, OpenPits.cell_of(p, i), n.inv, _tool(pp, n, p, OpenPits.cell_of(p, i))).result == "ok"
				if not n.inv.has("pickaxe"):
					n.inv.add("pickaxe")
				if not n.inv.has("shovel"):
					n.inv.add("shovel")
	check(ok and pp.ramp_done(p), "a level-0 village's villager still digs (the ramp, to its floor): levels gate nothing (Q18-9)")
	n.inv.remove("pickaxe", n.inv.count("pickaxe"))     # (the pickaxe the ramp's rock took goes again, for the report below)
	check(dv.structures("pit_ramp") == 1 and dv.need_holds({"kind": "structure", "what": "pit_ramp", "count": 1}),
			"the finished ramp is counted as a pit_ramp structure for the capability report")
	check(dv.evaluate().level == 0, "and the level is only reported: still 0")


# ---------------------------------------------------------------- determinism ----------------
func _run(sd: int) -> String:
	var w := _world(sd)
	var pp := w.pits
	var p := pp.open_pit(World.PLAYER, _sites(w)[0])
	_clear(w, p)
	var n := _digger(w)
	for k in 40:
		var c := pp.next_dig(p, n.cell())
		if c.x < 0:
			break
		pp.dig(n, p, c, n.inv, _tool(pp, n, p, c))
		if k % 7 == 0:
			pp.tip(p, n.inv)
	return JSON.stringify(pp.to_dict()) + JSON.stringify(n.inv.to_dict()) + str(w.rng.state) + JSON.stringify(w.stats)


func _test_determinism() -> void:
	var a := _run(7)
	check(a == _run(7), "the same seed and the same digs give the same pit, goods, rng and books")
	check(a != _run(2), "another seed differs")


# ---------------------------------------------------------------- saves ----------------------
func _test_saves() -> void:
	var w := _world(1)
	var pp := w.pits
	var p := pp.open_pit(World.PLAYER, _sites(w)[0])
	_clear(w, p)
	var n := _digger(w)
	for k in 30:
		var c := pp.next_dig(p, n.cell())
		pp.dig(n, p, c, n.inv, _tool(pp, n, p, c))
		if not n.inv.has("pickaxe"):
			n.inv.add("pickaxe")
		if not n.inv.has("shovel"):
			n.inv.add("shovel")
	pp.tip(p, n.inv)
	var sd := w.to_dict()
	check(int(sd.save_version) == World.SAVE_VERSION and World.SAVE_VERSION >= 17 and sd.has("pits"), "no new save version of its own (17; 18 is CC-01); the pits are saved")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(sd)))
	check(JSON.stringify(w2.pits.to_dict()) == JSON.stringify(pp.to_dict()), "every pit's depths and heaps round-trip exactly")
	var same := true
	var block := OpenPits.rect(p).grow(3)
	for y in range(block.position.y, block.end.y):
		for x in range(block.position.x, block.end.x):
			if w2.map.is_solid(Vector2i(x, y)) != w.map.is_solid(Vector2i(x, y)):
				same = false
	check(same, "the pit's cells and heaps are as solid after a load as before")
	check(JSON.stringify(Census.goods(w2)) == JSON.stringify(Census.goods(w)) and JSON.stringify(w2.pits.ground_left()) == JSON.stringify(pp.ground_left()),
			"the goods (heaps included) and the ground left are the same after a load")
	var old: Dictionary = JSON.parse_string(JSON.stringify(sd))
	old.erase("pits")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.pits != null and w3.pits.pits.is_empty() and not w3.map.is_solid(OpenPits.cell_of(p, 0)), "a save without pits (Build 17 before MIN-E) loads with none")
	old.erase("discovery")
	old.erase("prospecting")
	old.save_version = 16
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), old)
	check(w4.pits != null and w4.pits.pits.is_empty(), "a version 16 save loads too")
