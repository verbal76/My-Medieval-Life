extends SceneTree
## B25-ECON-P5 "Cleared by labour" (owner 2026-11-05): when households lack fields, villagers clear unused rough ground next to the
## village inside its lands as real work (days of labour), then till it; it ends when that ground is used up. In 120-day seed 1
## (run 41967592798) the adults rose from 61 to 77 while the farmers stayed at 12 (six manor fields, two farmers each). Checked here:
##   * the candidate ground: field-sized blocks of the village's own unused ground near the fields, finite, deterministic, clear of
##     roads, buildings, fields and the woods
##   * the reeve posts one clearing job only while every field has its farmers and an able adult is out of work
##   * the work is the existing rules': plants pulled, trees felled (logs through the felled_ ledger) and stumps dug out with an axe,
##     boulders broken with a pickaxe (stone through the mined_ ledger), cells tilled by hand, the time the player's, the logs and
##     stone to the works yard, the wage from the treasury
##   * a block all tilled is a new manor field, tilled, with two farmers' places open; the ground runs out
##   * saved and loaded mid-block it goes on the same; an older save loads with nothing cleared
##   godot --headless --path game --script res://tests/land_clearing_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_ground()
	test_posting()
	test_work_into_field()
	test_tree_and_boulder()
	test_save_load()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


## Every manor field given its farmers from the adults in other work (a fixture: the village's own job moves do this in play).
func _fill_fields(w: World) -> void:
	for f in w.fields:
		while w.field_workers(f).size() < int(GameData.b("field_workers_max")):
			var o := _adult(w)
			if o == null:
				for x: NPC in w.npcs:
					if x.alive and x.role == "adult" and x.job == "manor_hand":
						o = x
						break
			o.job = "farmer"
			o.workplace = str(f.id)


func _adult(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and not n.job in ["", "farmer", "manor_hand", "reeve"]:
			return n
	return null


func test_ground() -> void:
	var w := _world()
	var lc: LandClearing = w.clearing
	lc.find_blocks()
	check(not lc.blocks.is_empty() and lc.blocks.size() <= int(LandClearing.cfg().max_blocks), "rough ground is found next to the fields, a finite amount (%d blocks)" % lc.blocks.size())
	var f0: Dictionary = w.fields[0]
	var span := Rect2i(int(f0.x), int(f0.y), 0, 0)
	for f in w.fields:
		span = span.merge(Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)))
	var ok := true
	var road := {}
	for c in w.map.data.road:
		road[Vector2i(int(c[0]), int(c[1]))] = true
	for b in lc.blocks:
		var r := LandClearing.rect(b)
		if r.size != Vector2i(int(f0.w), int(f0.h)) or not span.grow(int(LandClearing.cfg().reach)).encloses(r):
			ok = false
		for f in w.fields:
			if Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).grow(1).intersects(r):
				ok = false
		for wd in w.map.data.woods:
			if Rect2i(int(wd.x), int(wd.y), int(wd.w), int(wd.h)).intersects(r):
				ok = false
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if road.has(Vector2i(x, y)):
					ok = false
		for bd in w.buildings.values():
			if Rect2i(int(bd.x), int(bd.y), int(bd.w), int(bd.h)).intersects(r):
				ok = false
	check(ok, "each block is a field's size, near the fields, and off the roads, buildings, fields and woods")
	var w2 := _world()
	w2.clearing.find_blocks()
	check(JSON.stringify(w2.clearing.blocks) == JSON.stringify(lc.blocks), "the same ground in the same order from the same seed")
	var rough := 0
	for b in lc.blocks:
		var r := LandClearing.rect(b)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if not w.farm.obstacle(Vector2i(x, y)).is_empty():
					rough += 1
	print("     blocks %s, cells with something to clear %d" % [JSON.stringify(lc.blocks), rough])


func test_posting() -> void:
	var w := _world()
	var mw: ManorWork = w.manor_work
	var most := int(GameData.b("field_workers_max"))
	_fill_fields(w)
	check(w.fields.all(func(f): return w.field_workers(f).size() >= most), "every manor field has its %d farmers" % most)
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job == "":
			n.job = "laborer"                       # (a fixture: everyone in work)
	mw.post_clearing()
	check(not mw.jobs.any(func(j): return j.kind == "clear"), "with everyone in work no ground is cleared")
	var idle := _adult(w)
	idle.job = ""
	mw.post_clearing()
	mw.post_clearing()
	check(mw.jobs.filter(func(j): return j.kind == "clear").size() == 1, "an adult out of work and every field worked: one clearing job is posted, never two")
	var farmer: NPC = w.field_workers(w.fields[0])[0]
	farmer.job = ""
	farmer.workplace = ""
	for j in mw.jobs.duplicate():
		if j.kind == "clear":
			mw.jobs.erase(j)
	mw.post_clearing()
	check(not mw.jobs.any(func(j): return j.kind == "clear"), "while a field has a farmer's place open, no ground is cleared")


func _clear_all(w: World, n: NPC, limit: int) -> Dictionary:
	var mw: ManorWork = w.manor_work
	var who := World.npc_ref(n.id)
	var out := {"jobs": 0, "pieces": 0, "minutes": 0.0, "paid": 0}
	for k in limit:
		mw.post_clearing()
		var open := mw.open_for(who).filter(func(j): return j.kind == "clear")
		if open.is_empty():
			break
		var j: Dictionary = open[0]
		var coins0 := n.coins
		if not mw.take(j, who):
			break
		var guard := 0
		while mw.job_of(who) == j and guard < 400:
			guard += 1
			if mw.step(j) == "clear":
				out.minutes += w.clearing.minutes_for(mw.clear_cell(j))
				out.pieces += 1
			mw.do_step(j, who, n.inv)
		out.jobs += 1
		out.paid += n.coins - coins0
		w.treasury += 50                               # (a fixture: the manor's chest kept able to pay)
		w.coin_sources += 50
	return out


func test_work_into_field() -> void:
	var w := _world()
	var mw: ManorWork = w.manor_work
	_fill_fields(w)
	var n := _adult(w)
	n.job = ""
	n.inv.add("axe")
	n.inv.add("pickaxe")
	w.treasury += 500
	w.coin_sources += 500
	var fields0 := w.fields.size()
	w.clearing.find_blocks()
	var nblocks := w.clearing.blocks.size()
	var b: Array = w.clearing.blocks[0]
	var area := int(b[2]) * int(b[3])
	var felled0 := float(w.stats.get("felled_log", 0.0))
	var mined0 := float(w.stats.get("mined_stone", 0.0))
	var yard_logs0 := mw.yard.count("log")
	var yard_stone0 := mw.yard.count("stone")
	var t0 := w.treasury
	var r := _clear_all(w, n, 40)
	check(w.fields.size() == fields0 + 1, "the block's cells all tilled, it is a new manor field (%d jobs, %d pieces of work)" % [r.jobs, r.pieces])
	var nf: Dictionary = w.fields[w.fields.size() - 1]
	check(nf.state == "tilled" and nf.owner == World.MANOR and int(nf.x) == int(b[0]) and int(nf.y) == int(b[1]) and int(nf.w) * int(nf.h) == area, "the field is the manor's, tilled, on that ground")
	check(r.minutes >= float(area) * float(Farming.cfg().till.hand.seconds) * float(GameData.b("game_minutes_per_second")), "it took real labour: %.0f game hours, at least the hand tilling of every cell" % (r.minutes / 60.0))
	check(r.paid > 0 and r.paid == r.jobs * int(LandClearing.cfg().wage), "each job paid its wage (%d coins)" % r.paid)
	check(w.treasury == t0 - r.paid + 50 * r.jobs, "the wages came from the treasury")
	var logs := int(float(w.stats.get("felled_log", 0.0)) - felled0)
	var stone := int(float(w.stats.get("mined_stone", 0.0)) - mined0)
	check(mw.yard.count("log") - yard_logs0 == logs and mw.yard.count("stone") - yard_stone0 == stone, "the logs (%d) and stone (%d) are counted by the felled_ and mined_ ledgers and went to the works yard" % [logs, stone])
	var cells_ok := true
	for y in range(int(nf.y), int(nf.y) + int(nf.h)):
		for x in range(int(nf.x), int(nf.x) + int(nf.w)):
			if not w.farm.obstacle(Vector2i(x, y)).is_empty():
				cells_ok = false
	check(cells_ok, "nothing is left standing on the new field")
	var jm: Dictionary = w.brain.job_market()
	check(int(jm.farmer.open) >= int(GameData.b("field_workers_max")), "the job market opens its farmers' places (%d)" % int(jm.farmer.open))
	# the ground runs out: every block cleared, nothing more is posted
	_fill_fields(w)
	n.job = ""
	n.workplace = ""
	var r2 := _clear_all(w, n, 400)
	check(w.fields.size() <= fields0 + nblocks and w.clearing.current().is_empty(), "the ground is used up: %d fields made in all, nothing left to clear" % (w.fields.size() - fields0))
	mw.post_clearing()
	check(not mw.jobs.any(func(j): return j.kind == "clear"), "and no clearing job is posted after")
	print("     second round: %d jobs, %d pieces" % [r2.jobs, r2.pieces])
	var logs2 := int(float(w.stats.get("felled_log", 0.0)) - felled0)
	var stone2 := int(float(w.stats.get("mined_stone", 0.0)) - mined0)
	var cleared := int(float(w.stats.get("land_cleared_plant", 0.0)) + float(w.stats.get("land_cleared_tree", 0.0)) + float(w.stats.get("land_cleared_stone", 0.0)))
	check(cleared > 0 and mw.yard.count("log") - yard_logs0 == logs2 and mw.yard.count("stone") - yard_stone0 == stone2, "over both blocks %d pieces of rough ground were cleared; the logs (%d) and stone (%d) all in the ledgers and the yard" % [cleared, logs2, stone2])


## A grown tree and a boulder on the ground (moved there: a fixture): felled with the axe into logs, broken with the pickaxe into
## stone, by the woodcutter's and the miner's own rules and ledgers; without the tools the worker leaves those cells.
func test_tree_and_boulder() -> void:
	var w := _world()
	var mw: ManorWork = w.manor_work
	_fill_fields(w)
	w.clearing.find_blocks()
	var b: Array = w.clearing.blocks[0]
	var tc := Vector2i(int(b[0]) + 2, int(b[1]))
	var bc := Vector2i(int(b[0]) + 4, int(b[1]))
	var tree: Dictionary = {}
	for t in w.trees:
		if str(t.state) == "grown" and Rect2i(0, 0, 30, 30).has_point(Vector2i(int(t.x), int(t.y))):
			tree = t
			break
	w.map.set_solid(Vector2i(int(tree.x), int(tree.y)), false)
	tree.x = tc.x
	tree.y = tc.y
	w.map.set_solid(tc, true)
	var rock: Dictionary = {}
	for r in w.boulders:
		if int(r.amount) > 0:
			rock = r
			break
	w.map.set_solid(Vector2i(int(rock.x), int(rock.y)), false)
	rock.x = bc.x
	rock.y = bc.y
	var units := int(rock.amount)
	w.map.set_solid(bc, true)
	var n := _adult(w)
	n.job = ""
	n.inv.remove("axe", n.inv.count("axe"))
	n.inv.remove("pickaxe", n.inv.count("pickaxe"))
	check(w.clearing.next_cell(b, n) != tc and w.clearing.tool_for(tc) == "axe" and w.clearing.tool_for(bc) == "pickaxe", "without an axe and a pickaxe the tree and the boulder are left for someone who has them")
	n.inv.add("axe")
	n.inv.add("pickaxe")
	w.treasury += 500
	w.coin_sources += 500
	var felled0 := float(w.stats.get("felled_log", 0.0))
	var mined0 := float(w.stats.get("mined_stone", 0.0))
	_clear_all(w, n, 3)
	var logs := int(float(w.stats.get("felled_log", 0.0)) - felled0)
	var stone := int(float(w.stats.get("mined_stone", 0.0)) - mined0)
	check(logs >= 4 and str(tree.state) == "cleared", "the tree is felled for %d logs and its stump dug out" % logs)
	check(stone == units and w.deposit_at(bc).is_empty(), "the boulder is broken into its %d stone and gone" % units)
	check(mw.yard.count("log") >= logs and mw.yard.count("stone") >= stone, "the logs and stone are in the works yard")


func test_save_load() -> void:
	var w := _world()
	var mw: ManorWork = w.manor_work
	_fill_fields(w)
	var n := _adult(w)
	n.job = ""
	n.inv.add("axe")
	n.inv.add("pickaxe")
	w.treasury += 200
	w.coin_sources += 200
	mw.post_clearing()
	var who := World.npc_ref(n.id)
	var j: Dictionary = mw.open_for(who).filter(func(x): return x.kind == "clear")[0]
	mw.take(j, who)
	for k in 30:
		if mw.job_of(who) != j:
			break
		mw.do_step(j, who, n.inv)
	var text := JSON.stringify(w.to_dict())
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(JSON.stringify(w2.clearing.to_dict()) == JSON.stringify(w.clearing.to_dict()) and not w2.clearing.tilled.is_empty(), "a save made mid-block keeps the ground and the cells tilled")
	var t2 := JSON.stringify(w2.to_dict())
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), JSON.parse_string(t2))
	check(JSON.stringify(w4.to_dict()) == t2, "load, save, load and save again: the same save")
	var old: Dictionary = JSON.parse_string(text)
	old.erase("clearing")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.clearing.tilled.is_empty() and not w3.clearing.found, "an older save loads with nothing cleared, the ground found at the first need")
