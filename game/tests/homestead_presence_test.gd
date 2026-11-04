extends SceneTree
## B25R1-010 x B25R1-019 (repair 2026-11-04): one set of construction rules for a homesteader the player watches and one out
## of view. The same start (homestead_test's fixture: the young adult of seed 1 with the family's savings) is run twice, with
## the player and the view parked at the village (the homesteader far, calculated) and at the claim (live while at home,
## calculated on the road to market and back). Both builds must complete, with no worker lost or duplicated, no material lost
## or made, and delivered progress that never goes back; the build is also saved and loaded mid-way and must come back exactly.
##   godot --headless --path game --script res://tests/homestead_presence_test.gd

const ITEMS := ["log", "plank", "building_block", "stone", "rubble", "wheat", "bread", "meat", "fish"]
const DAYS := 12

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _hour(w: World) -> void:
	var steps := int(60.0 / (float(GameData.b("game_minutes_per_second")) * 0.5))
	for i in steps:
		w.update(0.5)


func _mine(hs: Homesteads) -> Array:
	return hs.claims.filter(func(c) -> bool: return str(c.get("path", "")) != "band")


## The coins in the world and the neighbours' books against what came in from outside (courier_live_test's census).
func _coin_gap(w: World) -> int:
	return w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village())


## homestead_test's goods flow rule: held(now) = held(start) + produced + imported - consumed - exported, {} when it balances.
func _leaks(w: World, g0: Dictionary, st0: Dictionary) -> Dictionary:
	var d := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(st0.get(k, 0))
	var now := SettlementHoldings.goods(w)
	var bad := {}
	for id in ITEMS:
		var produced: int = d.call("made_" + id) + d.call("mined_" + id) + d.call("felled_" + id) + d.call("farm_harvest_" + id) + d.call("dug_" + id) + d.call("cut_" + id)
		var consumed: int = d.call("eaten_" + id) + d.call("used_" + id) + d.call("used_building_" + id) + d.call("used_works_" + id) \
			+ d.call("used_repairs_" + id) + d.call("feed_eaten_" + id) + d.call("burned_" + id) + d.call("broke_" + id) + d.call("poached_lost_" + id) \
			+ d.call("spoiled_" + id) + d.call("wild_eaten_" + id) + d.call("backfilled_" + id) + d.call("filled_" + id)
		if id == "wheat":
			consumed += d.call("farm_seed_saved")
		var res: int = int(now.get(id, 0)) - (int(g0.get(id, 0)) + produced + d.call("imported_" + id) - consumed - d.call("exported_" + id))
		if res != 0:
			bad[id] = res
	return bad


## The fixture: seed 1's youngest founder the village can spare, given the family's savings (a conserved transfer from the manor),
## sets out. Returns [world, founder id, claim id].
func _start() -> Array:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var hs: Homesteads = w.homesteads
	var cands := []
	for h in w.households.size():
		var f: NPC = w.construction.founder_of(h)
		if f != null and Life.npc_age(w, f) <= 30.0 and hs.gate(h, [f]) == "":
			cands.append([w.property.purse(World.hh_ref(h)), h, f])
	cands.sort()
	if cands.is_empty():
		return [w, -1, ""]
	var h: int = cands[-1][1]
	var who: NPC = cands[-1][2]
	w.treasury -= 300
	who.coins += 300
	if not hs.begin(h, who, [who]):
		return [w, -1, ""]
	return [w, who.id, str(_mine(hs)[0].id)]


## Runs one variant; `near`: the player and the view stand at the claim's site. Returns what was seen.
func _run(near: bool) -> Dictionary:
	var st := _start()
	var w: World = st[0]
	var id0: int = st[1]
	var out := {"built_hour": -1, "regress": 0, "dup": 0, "lost": 0, "live_hours": 0, "far_hours": 0, "leaks": {}, "gap": 0, "ok": id0 >= 0}
	if id0 < 0:
		return out
	var hs: Homesteads = w.homesteads
	var cid: String = st[2]
	var g0 := SettlementHoldings.goods(w)
	var st0: Dictionary = w.stats.duplicate()
	var gap0 := _coin_gap(w)
	var best := 0
	for hour in DAYS * 24:
		var c: Dictionary = hs.claim(cid)
		if near:
			var at: Vector2 = Vector2(Homesteads.step_of(c)) + Vector2(3.5, 2.5)
			w.player.pos = at
			w.presence.set_view(w.host_player().pid, Presence.DEFAULT_VIEW, at)
		_hour(w)
		c = hs.claim(cid)
		var me: NPC = w.npc(id0)
		var copies := w.npcs.filter(func(o: NPC) -> bool: return o.id == id0).size()
		var ids := {}
		for o: NPC in w.npcs:
			if ids.has(o.id):
				out.dup += 1                           # any person twice in the world (a resident made live twice, a worker copied)
			ids[o.id] = true
		if copies > 1:
			out.dup += 1
		if copies == 0 or me == null or not me.alive:
			out.lost += 1
		elif w.presence.cell_live(me.cell()):
			out.live_hours += 1
		else:
			out.far_hours += 1
		if not c.site.is_empty():
			var got := 0
			for k in Homesteads.delivered(c):
				got += int(Homesteads.delivered(c)[k])
			if bool(c.site.done):
				got = 1 << 20
			if got < best:
				out.regress += 1
			best = maxi(best, got)
		if str(c.get("building", "")) != "" and int(out.built_hour) < 0:
			out.built_hour = hour
			break
	out.leaks = _leaks(w, g0, st0)
	out.gap = _coin_gap(w) - gap0
	w.dispose()
	return out


func _saved_mid_build() -> void:
	var st := _start()
	var w: World = st[0]
	var cid: String = st[2]
	if int(st[1]) < 0:
		check(false, "save mid-build: the fixture found a homesteader")
		return
	for hour in DAYS * 24:
		_hour(w)
		var c: Dictionary = w.homesteads.claim(cid)
		if str(c.status) == "claimed" and not Homesteads.delivered(c).is_empty():
			break
	var c0: Dictionary = w.homesteads.claim(cid)
	check(str(c0.status) == "claimed" and not Homesteads.delivered(c0).is_empty(), "save mid-build: the frame has some of its materials (%s)" % Homesteads.delivered(c0))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	check(w2.load_error == "", "the save loads (%s)" % w2.load_error)
	check(JSON.stringify(w2.homesteads.to_dict()) == JSON.stringify(w.homesteads.to_dict()), "the homesteads come back exactly: claims, frames, what each still needs, trips")
	var me: NPC = w.npc(int(st[1]))
	var me2: NPC = w2.npc(int(st[1]))
	check(me2 != null and me2.coins == me.coins and JSON.stringify(me2.inv.items) == JSON.stringify(me.inv.items) and me2.household == me.household,
		"the homesteader comes back with the same coins, pack and household")
	check(JSON.stringify(w2.households[me.household].pantry.items) == JSON.stringify(w.households[me.household].pantry.items), "and the household's stores")
	check(w2.total_coins() - w2.coin_sources == w.total_coins() - w.coin_sources and w2.npcs.size() == w.npcs.size(), "no coin and no person made or lost by the load")
	w.dispose()
	w2.dispose()


func _init() -> void:
	var far := _run(false)
	var near := _run(true)
	for pair in [["far", far], ["near", near]]:
		var nm: String = pair[0]
		var r: Dictionary = pair[1]
		check(bool(r.ok) and int(r.built_hour) >= 0, "%s: the house is built (hour %d)" % [nm, int(r.built_hour)])
		check(int(r.dup) == 0 and int(r.lost) == 0, "%s: the homesteader and everyone else is never duplicated or lost (%d, %d)" % [nm, int(r.dup), int(r.lost)])
		check(int(r.regress) == 0, "%s: the frame's delivered materials never go back" % nm)
		check((r.leaks as Dictionary).is_empty() and int(r.gap) == 0, "%s: no material or coin made or lost (goods %s, coins %+d)" % [nm, r.leaks, int(r.gap)])
	check(int(far.far_hours) > int(far.live_hours), "far: the homesteader is calculated at home (live only at the village market, where the player is: %d live, %d calculated hours)" % [int(far.live_hours), int(far.far_hours)])
	check(int(near.live_hours) > 0 and int(near.far_hours) > 0, "near: live at home and calculated on the road (%d live, %d calculated hours)" % [int(near.live_hours), int(near.far_hours)])
	check(int(near.built_hour) == int(far.built_hour), "the same build whether the player watches or not (hour %d near, %d far)" % [int(near.built_hour), int(far.built_hour)])
	_saved_mid_build()
	print("homestead_presence_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
