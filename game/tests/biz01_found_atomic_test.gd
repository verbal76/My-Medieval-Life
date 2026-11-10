extends SceneTree
## BIZ-01 and BIZ-02 (Build 25 audit): founding a business (Ventures.found) is all or nothing. Before the fix an employed founder's
## employment was ended (BIZ-01), and an expanding business's till paid its household for the premises (BIZ-02), before the
## purchase or the marking out of the site could still fail; a failed founding then left the founder out of work, or the coins
## moved from the till to the household for premises never had. Each case here makes the founding fail as it can in play (the
## ground taken by someone else in the meantime; a workshop no longer for sale) and checks nothing changed: the employment record,
## the business's till and its costs, the household's purse, the coins in the world.
##   godot --headless --path game --script res://tests/biz01_found_atomic_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_build_fails()
	test_buy_fails()
	test_expansion_build_fails()
	test_expansion_buy_fails()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	w.judgment.cfg.decision.integration.work_accept = false      # the villager's own yes is JudgmentLive's test; here the terms
	return w


func of_job(w: World, job: String) -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.job == job)


# ------------------------------------------------- the fixtures of business_ownership_test.gd
func smithy_full(w: World) -> void:
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var d := {}
		for kind in NPCBrain.TRADE_STATIONS.smith:
			for st in w.stations_of(kind):
				if w.ventures.venture_at(st).is_empty():
					d[st] = {"smith": day}
		past.append(d)
	w.station_load = {"day": w.day(), "today": {}, "past": past}


func all_full(w: World) -> void:
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var d := {}
		for kind in NPCBrain.TRADE_STATIONS.smith:
			for st in w.stations_of(kind):
				d[st] = {"smith": day * float(w.stations[st].get("capacity", 1))}
		past.append(d)
	w.station_load = {"day": w.day(), "today": {}, "past": past}


func founder(w: World) -> NPC:
	var s: NPC = null
	for o: NPC in of_job(w, "smith"):
		if s == null or Skills.level(o, "smithing") > Skills.level(s, "smithing"):
			s = o
	var key := World.npc_ref(s.id)
	if not w.experience.minutes.has(key):
		w.experience.minutes[key] = {}
	w.experience.minutes[key]["smithing"] = 480.0 * 60.0
	s.coins += 3000
	w.brain.evaluate_household(s.household)
	return s


func open_one(w: World) -> Array:
	var s := founder(w)
	smithy_full(w)
	w.ventures.found(s, w.ventures.eligible(s))
	var hh: Dictionary = w.households[s.household]
	var p: Dictionary = w.plot(str(hh.build))
	var pantry: Inventory = hh.pantry
	for id in p.site.need.duplicate():
		pantry.add(id, int(p.site.need[id]))
	w.deliver(p, pantry)
	var b: Dictionary = w.buildings.get(str(p.get("building", "")), {})
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	return [s, b]


## `s` works for the player (a permanent employment record, as Employment.employ makes one; paid for today).
func employ(w: World, s: NPC) -> Dictionary:
	var rec := {"npc": s.id, "employer": World.PLAYER, "role": "smith", "wage": 10, "since": w.day(), "paid_day": w.day(), "owed": {}}
	w.employment.list.append(rec)
	return rec


## Someone else (the player) takes the chosen ground in the meantime.
func take_ground(w: World, rect: Rect2i) -> void:
	w.player.coins += w.property.land_price(rect.size.x, rect.size.y)
	var p: Dictionary = w.property.claim(rect, World.PLAYER)
	check(not p.is_empty(), "fixture: the ground is taken by someone else first (%s)" % str(rect))


## A finished building that is not on sale.
func not_for_sale(w: World) -> Dictionary:
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = w.buildings[id]
		if not b.has("sale"):
			return b
	return {}


func state(w: World, s: NPC, b: Dictionary = {}) -> Dictionary:
	var hh: Dictionary = w.households[s.household]
	return {"rec": w.employment.record_of(s).duplicate(true), "purse": w.property.purse(World.hh_ref(s.household)),
		"coins": w.total_coins(), "till": int(b.venture.till) if b.has("venture") else -1,
		"costs": (b.venture.get("costs", {}) as Dictionary).duplicate(true) if b.has("venture") else {},
		"build": str(hh.get("build", "")), "venture": hh.has("venture"), "plots": w.plots.size(), "job": s.job}


func unchanged(before: Dictionary, after: Dictionary, what: String) -> void:
	for k in before:
		check(str(before[k]) == str(after[k]), "%s: %s unchanged (%s -> %s)" % [what, k, str(before[k]), str(after[k])])


# ------------------------------------------------- BIZ-01
func test_build_fails() -> void:
	var w := world()
	var s := founder(w)
	smithy_full(w)
	var opt: Dictionary = w.ventures.eligible(s)
	check(not opt.is_empty() and opt.has("rect"), "fixture: the smith may found a smithy on ground of its own")
	if opt.is_empty():
		return
	employ(w, s)
	take_ground(w, opt.rect)
	var before := state(w, s)
	check(not w.ventures.found(s, opt), "the founding fails: the ground is no longer free")
	unchanged(before, state(w, s), "a failed build")
	check(w.employment.is_employed(s), "the founder is still employed")


func test_buy_fails() -> void:
	var w := world()
	var s := founder(w)
	var b := not_for_sale(w)
	check(not b.is_empty(), "fixture: a building not on sale")
	employ(w, s)
	var before := state(w, s)
	check(not w.ventures.found(s, {"buy": b, "kind": "smithy", "start": 0, "need": 0, "spare": 0}), "the founding fails: the workshop is not for sale")
	unchanged(before, state(w, s), "a failed purchase")


# ------------------------------------------------- BIZ-02
func test_expansion_build_fails() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	check(b.has("venture"), "fixture: the smithy is open")
	if not b.has("venture"):
		return
	all_full(w)
	b.venture.till = 5000
	var opt: Dictionary = w.ventures.expansion(s)
	check(not opt.is_empty() and opt.has("rect"), "fixture: the business may open a standalone workshop")
	if opt.is_empty():
		return
	take_ground(w, opt.rect)
	var before := state(w, s, b)
	check(not w.ventures.found(s, opt), "the expansion fails: the ground is no longer free")
	unchanged(before, state(w, s, b), "a failed expansion build")


func test_expansion_buy_fails() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	if not b.has("venture"):
		return
	all_full(w)
	b.venture.till = 5000
	var opt: Dictionary = w.ventures.expansion(s)
	if opt.is_empty():
		return
	var other := not_for_sale(w)
	opt = opt.duplicate()
	opt.erase("rect")
	opt.buy = other
	opt.start = 40
	var before := state(w, s, b)
	check(not w.ventures.found(s, opt), "the expansion fails: the workshop is no longer for sale")
	unchanged(before, state(w, s, b), "a failed expansion purchase")
