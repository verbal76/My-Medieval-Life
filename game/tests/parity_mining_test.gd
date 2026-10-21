extends SceneTree
## Build 17 mining parity (docs/build17/MIN_PARITY_SHOVELS.md; owner directive 2026-10-21, the consolidated fourteen
## decisions): MIN-D2 the player counts toward the village's mining capability by exactly the villagers' rules while
## resident, and stops when not; MIN-SKILLCAP practitioners by skill and equipment, never job titles, and excavation
## open to any equipped worker; MIN-D3 a trial pit's earth recovered as goods, counted and conserved; MIN-SHOVEL the
## shovel's recipes (carpenter's haft, smith's blade, assembled), its wear, earth needing a shovel and rock a pickaxe (open
## pits, trial pits, tunnels), villagers making and buying them by the ordinary rules; MIN-RIGHTS digging refused on land
## another holds and open on common ground, with no permit; saves and determinism. Run headless:
##   godot --headless --path game --script res://tests/parity_mining_test.gd

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
	_test_capability_parity()
	_test_skills_not_titles()
	_test_trial_earth()
	_test_shovel()
	_test_tools_by_layer()
	_test_villagers_get_shovels()
	_test_rights()
	_test_saves()
	_test_determinism()
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


func _cheb(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Every pickaxe, kit and shovel out of the village (villagers, households, the yard) and the player's pack and chest.
func _strip_all(w: World) -> void:
	for id in ["pickaxe", "rusty_pickaxe", "prospecting_kit", "shovel"]:
		for o: NPC in w.npcs:
			o.inv.remove(id, o.inv.count(id))
		for hh in w.households:
			hh.pantry.remove(id, hh.pantry.count(id))
		w.manor_work.yard.remove(id, w.manor_work.yard.count(id))
		w.player.inv.remove(id, w.player.inv.count(id))
		w.player.chest.remove(id, w.player.chest.count(id))


## A house the player could live in (its id), for residency.
func _a_house(w: World) -> String:
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		if str(w.buildings[id].get("type", "")) in Property.HOME_TYPES:
			return str(id)
	return ""


func _adult(w: World, job: String, not_these := []) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == job and not not_these.has(o):
			return o
	return null


func _need(w: World, level: int, as_name: String) -> Dictionary:
	for l in Discovery.caps().industries.mining.levels:
		if int(l.level) == level:
			for n in l.needs:
				if str(n.get("as", "")) == as_name:
					return n
	return {}


# ---------------------------------------------------------------- MIN-D2 ---------------------
func _test_capability_parity() -> void:
	var w := _world(1)
	var dv := w.discovery
	var p := w.player
	_strip_all(w)
	p.home = ""
	p.inv.add("pickaxe")
	dv.dawn()
	var miner := _need(w, 1, "miner")
	check(dv.level() == 0 and not dv.practitioners(miner).has(p), "a player with no home in the village is no resident: their pickaxe does not count (level 0)")
	var house := _a_house(w)
	check(house != "", "the village has a house for the player to live in")
	p.home = house
	dv.dawn()
	check(dv.player_resident() and dv.practitioners(miner) == [p] and dv.level() == 1,
			"resident, the player is counted by the villagers' rule: their pickaxe and skill make level 1 (MIN-D-Q2)")
	check(p.inv.count("pickaxe") == 1 and dv.tool_stock("pickaxe") == 1, "counting moves nothing: the pickaxe stays in the player's pack")
	p.home = ""
	dv.dawn()
	check(dv.level() == 0 and str(dv.history[-1].why) != "", "leaving the home, the player is recalculated out at the next dawn (level 0: %s)" % str(dv.history[-1].why))
	# equal circumstances, equal contributions: a villager and the player, the same skill, the same tool in the same place
	p.home = house
	var v := _adult(w, "woodcutter")
	var xp := Skills.xp_for_level(3)
	p.skills["mining"] = xp
	v.skills["mining"] = xp
	var skilled := _need(w, 4, "skilled miner")
	var same := true
	for where in ["pack", "store", "none"]:
		for o in [p, v]:
			var inv: Inventory = o.inv
			inv.remove("pickaxe", inv.count("pickaxe"))
		p.chest.remove("pickaxe", p.chest.count("pickaxe"))
		if v.household >= 0:
			w.households[v.household].pantry.remove("pickaxe", w.households[v.household].pantry.count("pickaxe"))
		if where == "pack":
			p.inv.add("pickaxe")
			v.inv.add("pickaxe")
		elif where == "store":
			p.chest.add("pickaxe")
			if v.household >= 0:
				w.households[v.household].pantry.add("pickaxe")
		for need in [miner, skilled]:
			if dv.practitioner(p, need, {}) != dv.practitioner(v, need, {}):
				same = false
	check(same and v.household >= 0, "the player and a villager with the same skill and the same tool (in the pack, at home, or none) contribute the same, need by need")
	p.skills["mining"] = 0
	check(not dv.practitioner(p, skilled, {}) and dv.practitioner(v, skilled, {}) == (v.inv.count("pickaxe") > 0 or w.households[v.household].pantry.count("pickaxe") > 0),
			"no bonus: without Mining 3 the player is no skilled miner, whatever they hold")
	# a shared tool serves one member
	var hh: int = v.household
	var mates: Array = w.brain._members(hh).filter(func(o: NPC): return o.alive and o.role == "adult")
	for o: NPC in mates:
		o.inv.remove("pickaxe", o.inv.count("pickaxe"))
		o.skills["mining"] = 0
	w.households[hh].pantry.remove("pickaxe", w.households[hh].pantry.count("pickaxe"))
	w.households[hh].pantry.add("pickaxe")
	var counted := dv.practitioners(miner).filter(func(o): return mates.has(o)).size()
	check(mates.size() < 2 or counted == 1, "one pickaxe in a household's store makes one practitioner, not one each (%d of %d members)" % [counted, mates.size()])
	var r0 := w.rng.state
	var e1 := JSON.stringify(dv.evaluate())
	check(e1 == JSON.stringify(dv.evaluate()) and w.rng.state == r0, "the evaluation is deterministic and draws nothing from world.rng")
	# never a gate: a level-0 village's player still digs a trial pit
	p.home = ""
	_strip_all(w)
	dv.dawn()
	p.inv.add("shovel")
	var c: Dictionary = {}
	var cell := Vector2i(-1, -1)
	for cl in w.prospecting.clues:
		var cs := dv.dig_cells(cl, World.PLAYER)
		if not cs.is_empty():
			c = cl
			cell = cs[0]
			break
	check(dv.level() == 0 and cell.x >= 0 and dv.trial_refusal(p, c, cell, "shovel") == "", "at level 0 the player may still dig a trial pit: a level is never a gate (Q18-9)")


# ---------------------------------------------------------------- MIN-SKILLCAP ---------------
func _test_skills_not_titles() -> void:
	var w := _world(1)
	var dv := w.discovery
	_strip_all(w)
	w.player.home = ""
	var miner_need := _need(w, 1, "miner")
	var m := _adult(w, "miner")
	var wc := _adult(w, "woodcutter")
	wc.inv.add("pickaxe")
	var pr := dv.practitioners(miner_need)
	check(pr.has(wc) and (m == null or not pr.has(m)), "a woodcutter with a pickaxe counts as a miner; a 'miner' without one does not (skills and kit, not titles)")
	var kit_need := _need(w, 2, "prospector")
	var smith := _adult(w, "smith")
	var lab := _adult(w, "laborer")
	lab.inv.add(Prospecting.KIT)
	check(dv.practitioners(kit_need).has(lab) and not w.npcs.any(func(o): return o.job == Prospecting.JOB and dv.practitioners(kit_need).has(o) and not o.inv.has(Prospecting.KIT)),
			"a labourer with a prospector's kit counts as a prospector; the title alone counts for nothing")
	var exc := _need(w, 3, "excavator")
	check(not exc.has("jobs") and str(exc.get("tool", "")) == "shovel", "level 3's excavators are anyone with a shovel (no 'excavator' job is named)")
	var a := _adult(w, "farmer")
	var b := _adult(w, "cook")
	a.inv.add("shovel")
	b.inv.add("shovel")
	check(dv.practitioners(exc).size() >= 2, "two villagers of other trades with shovels are two excavators")
	check(_need(w, 2, "assayer").get("jobs", []) == ["smith"] and dv.practitioners(_need(w, 2, "assayer")).has(smith),
			"the assayer is the smith at the forge, the assay's own rule (owner MIN-C-Q3), with its Smithing level")
	check(not Discovery.caps().industries.mining.levels.any(func(l): return l.needs.any(func(n): return str(n.kind) == "practitioners" and n.has("jobs") and str(n.get("as", "")) != "assayer")),
			"no other mining need names a job")
	# excavation open to any equipped worker: the manor's excavate job is open to a farmer with a shovel
	w.treasury = 100000
	var pp := w.pits
	var site := Vector2i(-1, -1)
	for y in w.map.h:
		for x in w.map.w:
			if site.x < 0 and pp.site_open(Vector2i(x, y)) and pp.site_refusal(Vector2i(x, y)) == "":
				site = Vector2i(x, y)
	var pit := pp.open_pit(World.MANOR, site)
	var job := {"kind": "excavate", "qty": ManorWork.excavate_load(), "wage": ManorWork.excavate_wage(), "pit": int(pit.id)}
	w.manor_work._post(job)
	var aref := World.npc_ref(a.id)
	check(w.manor_work.open_for(aref).has(job), "a farmer with a shovel may take the manor's excavation (earth first)")
	var c2 := _adult(w, "tanner")
	check(c2 == null or not w.manor_work.open_for(World.npc_ref(c2.id)).has(job), "a worker with no digging tool may not")


# ---------------------------------------------------------------- MIN-D3 ---------------------
func _trial_spot(w: World) -> Dictionary:
	for cl in w.prospecting.clues:
		var cs := w.discovery.dig_cells(cl, World.PLAYER)
		if not cs.is_empty():
			return {"clue": cl, "cell": cs[0]}
	return {}


func _test_trial_earth() -> void:
	var w := _world(1)
	var dv := w.discovery
	var p := w.player
	p.inv.add("shovel")
	var t := _trial_spot(w)
	var g0: Dictionary = Census.goods(w)
	var loot0 := w.loot.size()
	var coins0 := _coins(w)
	var r := dv.trial_dig(p, t.clue, t.cell, "shovel")
	var earth := Discovery.trial_earth()
	check(r.result == "ok" and earth == {"topsoil": 2, "dirt": 3, "spoil": 3}, "a trial pit moves one cell of the open pit's earth down to the rock: 2 topsoil, 3 dirt, 3 spoil")
	var ok := true
	for id in earth:
		ok = ok and _st(w, "trial_ground_" + id) == int(earth[id]) and _st(w, "dug_" + id) == int(earth[id])
	check(ok, "each unit leaves the ground into the books (trial_ground_) and is counted as goods dug (dug_)")
	check(w.loot.size() == loot0 + 1 and Vector2i(w.loot[-1].pos.floor()) == Discovery.pile_cell(t.cell) and not str(w.loot[-1].from).begins_with("the "),
			"the earth lies in a spoil pile beside the pit (south of it), a pile that does not rot away")
	var g1: Dictionary = Census.goods(w)
	var moved := true
	for id in earth:
		moved = moved and int(g1.get(id, 0)) - int(g0.get(id, 0)) == int(earth[id])
	check(moved and _coins(w) == coins0, "the goods census rises by exactly the earth dug; no coin moves")
	# the economy ledger's pool: start + trial_ground_ - left (nothing stays in a trial pit) = dug - backfilled
	var bal := true
	for id in earth:
		bal = bal and _st(w, "trial_ground_" + id) - 0 == _st(w, "dug_" + id) - _st(w, "backfilled_" + id)
	check(bal, "the trial pit's ground balances in the books")
	# recovered and reused: the player picks it up and puts topsoil back into an open pit
	p.pos = Vector2(Discovery.pile_cell(t.cell)) + Vector2(0.5, 0.5)
	var got := w.player_loot(w.loot.size() - 1)
	check(str(got.far) == "" and p.inv.count("topsoil") >= 2 and p.inv.count("spoil") >= 3, "anyone may take the pile up and carry it (hauling)")
	var pp := w.pits
	var site := Vector2i(-1, -1)
	for y in w.map.h:
		for x in w.map.w:
			if site.x < 0 and pp.site_open(Vector2i(x, y)) and pp.site_refusal(Vector2i(x, y)) == "":
				site = Vector2i(x, y)
	var pit := pp.open_pit(World.PLAYER, site)
	var cell := OpenPits.cell_of(pit, 0)
	var n: NPC = w.brain._first_with_job("laborer")
	n.inv.add("shovel")
	n.pos = Vector2(pp.stand_for(pit, 0, cell)) + Vector2(0.5, 0.5)
	pp.dig(n, pit, cell, n.inv, "shovel")
	var top0 := p.inv.count("topsoil")
	var f := pp.backfill(pit, cell, p.inv)
	check(f.result == "ok" and p.inv.count("topsoil") == top0 - 1 and _st(w, "backfilled_topsoil") == 1, "trial-pit topsoil fills an open pit back (a counted reuse)")
	var src := FileAccess.get_file_as_string("res://scripts/core/discovery.gd") + FileAccess.get_file_as_string("res://scripts/core/npc_brain.gd")
	check(not src.contains("fill_tunnel") and not src.contains("auto_backfill"), "no villager backfills a tunnel on its own (the trial pit's earth is not sent below ground)")


# ---------------------------------------------------------------- MIN-SHOVEL -----------------
func _test_shovel() -> void:
	var it: Dictionary = GameData.item("shovel")
	check(str(it.get("tool", "")) == "shovel" and int(it.get("durability", 0)) > 0, "a shovel is a tool that wears (durability %d)" % int(it.get("durability", 0)))
	var rb: Dictionary = GameData.recipes["forge_shovel_blade"]
	var rh: Dictionary = GameData.recipes["make_shovel_haft"]
	var ra: Dictionary = GameData.recipes["assemble_shovel"]
	check(str(rb.station) == "anvil" and str(rb.skill) == "smithing" and (rb["in"] as Dictionary).has("iron_bar") and int(rb.minutes) > 0,
			"the blade is the smith's: iron at the anvil, Smithing, time")
	check(str(rh.station) == "workbench" and str(rh.skill) == "crafting" and (rh["in"] as Dictionary).has("plank") and int(rh.minutes) > 0,
			"the haft is the carpenter's: a plank at the workbench, Crafting, time")
	check(str(ra.station) == "workbench" and (ra["in"] as Dictionary).size() == 2 and int(ra["in"].shovel_haft) == 1 and int(ra["in"].shovel_blade) == 1 and int(ra.out.shovel) == 1,
			"a shovel is assembled from one haft and one blade at the workbench")
	# the player and a villager by one rule (work_craft)
	var w := _world(1)
	var p := w.player
	var v: NPC = w.brain._first_with_job("carpenter")
	for o in [p, v]:
		o.inv.add("iron_bar", 1)
		o.inv.add("plank", 1)
		o.skills["smithing"] = 0
		o.skills["crafting"] = 0
	var ok := true
	for o in [p, v]:
		for r in ["forge_shovel_blade", "make_shovel_haft", "assemble_shovel"]:
			var before: int = o.inv.count("shovel")
			ok = ok and w.work_craft(o, r, o.inv).result == "ok"
	check(ok and p.inv.count("shovel") >= 1 and v.inv.count("shovel") >= 1 and _st(w, "made_shovel") >= 2 and _st(w, "used_iron_bar") + _st(w, "used_plank") <= 4,
			"the player and a carpenter make a shovel by the same recipes, from real iron and wood, counted made_ and used_")
	# wear: like the pickaxe, a unit of wear a unit of earth unless Mining spares it; worn out it is gone
	var n: NPC = w.brain._first_with_job("laborer")
	n.inv.remove("shovel", n.inv.count("shovel"))
	n.inv.add("shovel")
	n.skills["mining"] = 0
	var full := int(it.durability)
	var pp := w.pits
	var site := Vector2i(-1, -1)
	for y in w.map.h:
		for x in w.map.w:
			if site.x < 0 and pp.site_open(Vector2i(x, y)) and pp.site_refusal(Vector2i(x, y)) == "":
				site = Vector2i(x, y)
	var pit := pp.open_pit(World.MANOR, site)
	var cell := OpenPits.cell_of(pit, 0)
	n.pos = Vector2(pp.stand_for(pit, 0, cell)) + Vector2(0.5, 0.5)
	pp.dig(n, pit, cell, n.inv, "shovel")
	check(int(n.inv.durability.get("shovel", full)) == full - int(OpenPits.cfg().wear), "each unit of earth wears the shovel (%d)" % int(OpenPits.cfg().wear))
	n.inv.durability["shovel"] = 1
	var r2 := pp.dig(n, pit, cell, n.inv, "shovel")
	check(r2.broke and not n.inv.has("shovel") and _st(w, "broke_shovel") == 1, "worn out, it breaks and is gone (replaced only by buying or making another)")


func _test_tools_by_layer() -> void:
	var w := _world(1)
	var pp := w.pits
	var site := Vector2i(-1, -1)
	for y in w.map.h:
		for x in w.map.w:
			if site.x < 0 and pp.site_open(Vector2i(x, y)) and pp.site_refusal(Vector2i(x, y)) == "":
				site = Vector2i(x, y)
	var pit := pp.open_pit(World.PLAYER, site)
	var mid := OpenPits.size() * OpenPits.size() / 2 + 1          # an inner, non-ramp cell
	while OpenPits.is_ramp(mid) or OpenPits.ring_of(mid) < 1:
		mid += 1
	var c := OpenPits.cell_of(pit, mid)
	var p := w.player
	p.inv.remove("pickaxe", p.inv.count("pickaxe"))
	p.inv.remove("rusty_pickaxe", p.inv.count("rusty_pickaxe"))
	p.inv.add("shovel", 3)
	p.pos = Vector2(pp.stand_for(pit, mid, c)) + Vector2(0.5, 0.5)
	var earth := OpenPits.cum(OpenPits.rock_depth())
	var dug := 0
	for k in earth:
		if pp.dig(p, pit, c, p.inv, OpenPits.held_tool(p, pp.tool_needed(pit, c))).result == "ok":
			dug += 1
	check(dug == earth and pp.tool_needed(pit, c) == "pickaxe", "a shovel digs the earth layers (%d units of topsoil, dirt and spoil) down to the rock" % earth)
	var why := pp.dig_refusal(p, pit, c, "shovel")
	check(OpenPits.cap(mid) <= earth or why.contains("pickaxe"), "the rock needs a pickaxe: a shovel is refused (%s)" % why)
	p.inv.add("pickaxe")
	check(OpenPits.cap(mid) <= earth or pp.dig(p, pit, c, p.inv, "pickaxe").result == "ok", "with a pickaxe the rock is broken")
	var c0 := OpenPits.cell_of(pit, 0)
	check(pp.dig_refusal(p, pit, c0, "pickaxe").contains("shovel"), "and a pickaxe will not dig topsoil")
	# trial pits: a shovel, not a pickaxe
	var t := _trial_spot(w)
	check(w.discovery.trial_refusal(p, t.clue, t.cell, "pickaxe").contains("shovel") and w.discovery.trial_refusal(p, t.clue, t.cell, "shovel") == "",
			"a trial pit (earth only) is dug with a shovel, not a pickaxe")
	# tunnels: rock with a pickaxe, rubble or fill (loose spoil) with a shovel
	var mw: MineWorks = w.mine_works
	var lm: LevelMap = w.underground.maps[0]
	var rock := Vector2i(-1, -1)
	for cc in lm.cells():
		if lm.is_solid(cc):
			rock = cc
			break
	check(rock.x >= 0 and mw.tool_kind(lm.level, rock) == "pickaxe", "below ground, rock is cut with a pickaxe")
	mw._set_held(lm.level, rock, 0, 2)
	check(mw.tool_kind(lm.level, rock) == "shovel", "fallen rubble or backfill (loose spoil) is dug out with a shovel")
	mw._set_held(lm.level, rock, 0, 0)


func _test_villagers_get_shovels() -> void:
	var w := _world(1)
	var b: NPCBrain = w.brain
	var carp: NPC = b._first_with_job("carpenter")
	var smith: NPC = b._first_with_job("smith")
	check(b._buyer_for(smith, "shovel_blade") == carp, "the smith's blade has a buyer: the carpenter, who keeps one on hand for shovels")
	carp.inv.add("plank", 2)
	carp.inv.add("shovel_blade", 1)
	carp.plan.clear()
	var merch := b._with_buy_role("merchant_goods")
	check(not merch.is_empty() and b.wants(merch[0], "shovel") > 0, "the goods merchant stocks shovels (made to its order, as mallets)")
	var planned := b._carpenter_shovel(carp)
	check(planned and carp.plan.any(func(s): return str(s.get("args", {}).get("recipe", "")) in ["assemble_shovel", "make_shovel_haft"]),
			"the carpenter sets to making one (%s)" % carp.doing)
	# a miner out of ore with an earthwork posted buys a shovel if one is for sale
	var mn: NPC = b._first_with_job("miner")
	mn.inv.remove("shovel", mn.inv.count("shovel"))
	var mref := World.npc_ref(mn.id)
	w.treasury = 100000
	var t := _trial_spot(w)
	w.manor_work._post({"kind": "trial", "qty": 1, "wage": int(Discovery.cfg().manor.trial_wage), "clue": str(t.clue.id), "site": [t.cell.x, t.cell.y]})
	check(w.manor_work.shovel_would_open(mref) and not w.manor_work.open_for(mref).any(func(j): return j.kind == "trial"),
			"a trial pit is closed to a miner without a shovel, and only for want of one")
	merch[0].inv.add("shovel")
	mn.coins = 200
	check(b._buy_tool(mn, "shovel") and mn.plan.any(func(s): return str(s.get("act", "")) == "buy_from" and str(s.args.item) == "shovel"),
			"the miner goes to buy one at the market with its own coins")
	mn.inv.add("shovel")
	check(w.manor_work.open_for(mref).any(func(j): return j.kind == "trial") and not w.manor_work.shovel_would_open(mref), "with it the trial pit is open to the miner")
	check(b.keeps(mn, "shovel"), "a miner keeps the shovel it works with")


# ---------------------------------------------------------------- MIN-RIGHTS -----------------
func _test_rights() -> void:
	var w := _world(1)
	var pp := w.pits
	var sites := []
	for y in w.map.h:
		for x in w.map.w:
			if pp.site_open(Vector2i(x, y)) and pp.site_refusal(Vector2i(x, y)) == "":
				sites.append(Vector2i(x, y))
	check(not sites.is_empty(), "common ground offers pit sites (%d)" % sites.size())
	var tr0 := w.treasury
	var c0 := _coins(w)
	var pit := pp.open_pit(World.PLAYER, sites[0])
	check(not pit.is_empty() and w.treasury == tr0 and _coins(w) == c0, "the player stakes a pit on common ground with no permit, fee or royalty to the manor")
	# land a household holds: a parcel bought on clear ground, then a pit or a trial pit on it is refused
	var hh := 0
	var href := World.hh_ref(hh)
	var refused_pit := false
	for o in sites.slice(1):
		var r := Rect2i(o, Vector2i(OpenPits.size(), OpenPits.size()))
		for m in w.brain._members(hh):
			(m as NPC).coins += 2000
		var parcel := w.property.claim(r, href)
		if parcel.is_empty():
			continue
		check(w.owner_of(parcel) == href, "a household buys the ground (%s)" % str(parcel.id))
		refused_pit = pp.site_refusal(o) != "" and pp.open_pit(World.PLAYER, o).is_empty()
		break
	check(refused_pit, "a pit on ground another party holds is refused")
	var trial_refused := false
	var dv := w.discovery
	for cl in w.prospecting.clues:
		for cell: Vector2i in dv.dig_cells(cl, World.PLAYER):
			var r := Rect2i(cell - Vector2i(1, 1), Vector2i(3, 3))
			var parcel := w.property.claim(r, href)
			if parcel.is_empty():
				continue
			w.player.inv.add("shovel")
			trial_refused = dv.ground_refusal(cl, cell) != "" and dv.trial_dig(w.player, cl, cell, "shovel").result == "refused"
			break
		if trial_refused:
			break
	check(trial_refused, "a trial pit on ground another party holds is refused")
	# the manor's own fields are refused too (land the manor holds), and no ground is the manor's merely by its rule
	var fld_refused := w.fields.is_empty()
	for f in w.fields:
		fld_refused = w.plant_refusal(Vector2i(int(f.x), int(f.y))) != ""
		break
	check(fld_refused, "the manor's fields are its land: no pit or trial pit there")
	# tunnels: cut only under the hill's bare rock, never under a parcel, a building or a field
	var bad := 0
	var cuttable := 0
	for lm: LevelMap in w.underground.maps:
		for c in lm.cells():
			if not lm.is_solid(c) or not lm.region.grow(-1).has_point(c) or not w.underground.under_rock(w.map, c):
				continue
			cuttable += 1
			for rec in w.property.records():
				if Rect2i(int(rec.x), int(rec.y), int(rec.w), int(rec.h)).has_point(c):
					bad += 1
			for f in w.fields:
				if Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(c):
					bad += 1
	check(cuttable > 0 and bad == 0, "no rock a tunnel may cut lies under land anyone holds (%d cuttable cells, %d under holdings)" % [cuttable, bad])
	var src := FileAccess.get_file_as_string("res://scripts/core/open_pit.gd") + FileAccess.get_file_as_string("res://scripts/core/discovery.gd") \
			+ FileAccess.get_file_as_string("res://scripts/core/mine_works.gd")
	check(not src.contains("royalt") and not src.contains("permit") and not src.contains("quota"), "no royalty, permit or quota anywhere in the digging rules")


# ---------------------------------------------------------------- saves and determinism -----
func _test_saves() -> void:
	var w := _world(2)
	var p := w.player
	p.inv.add("shovel")
	p.inv.wear("shovel", 7)
	var t := _trial_spot(w)
	w.discovery.trial_dig(p, t.clue, t.cell, "shovel")
	var sd := w.to_dict()
	check(int(sd.save_version) == 17, "no new save version (17)")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(sd)))
	check(w2.player.inv.count("shovel") == p.inv.count("shovel") and int(w2.player.inv.durability.get("shovel", 0)) == int(p.inv.durability.get("shovel", 0)),
			"a worn shovel loads as it was")
	var pile := w2.loot.filter(func(l): return str(l.from) == "a trial pit")
	check(pile.size() == 1 and (pile[0].inv as Inventory).count("dirt") == 3 and w2.discovery.dug_at(w2.prospecting.clue(str(t.clue.id)), t.cell),
			"the trial pit and its spoil pile load as they were")
	check(JSON.stringify(Census.goods(w2)) == JSON.stringify(Census.goods(w)), "the goods census is the same after the round trip")
	var old: Dictionary = JSON.parse_string(JSON.stringify(sd))
	old.save_version = 16
	old.erase("discovery")
	old.erase("pits")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.discovery != null and w3.discovery.dug.is_empty() and w3.discovery.level() == w3.discovery.evaluate().level, "an older save without the keys loads (nothing dug, the level recomputed)")


func _run(sd: int) -> String:
	var w := _world(sd)
	var p := w.player
	p.inv.add("shovel", 2)
	var n: NPC = w.brain._first_with_job("laborer")
	n.inv.add("shovel", 2)
	var dug := 0
	for cl in w.prospecting.clues:
		for cell in w.discovery.dig_cells(cl, World.PLAYER).slice(0, 2):
			w.discovery.trial_dig(p if dug % 2 == 0 else n, cl, cell, "shovel")
			dug += 1
	w.player.home = _a_house(w)
	return JSON.stringify([w.stats, w.loot.map(func(l): return [l.pos, (l.inv as Inventory).to_dict()]), w.rng.state, w.discovery.evaluate(), w.discovery.to_dict()])


func _test_determinism() -> void:
	var a := _run(1)
	check(a == _run(1), "the same seed and the same digs give the same stats, piles, rng and capability")
	check(a != _run(7), "another seed differs")
