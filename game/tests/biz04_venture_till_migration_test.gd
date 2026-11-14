extends SceneTree
## BIZ-04 (owner decision 2026-11-08, docs/directives/2026-11-09_overnight_autonomous_development.md): a living household that
## migrates keeps its business money: its venture's till goes with it, as its storefront tills do (TILL-D1), not to the manor.
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	Migration.walk = false            # REG-05 (B42): what crosses at the move is checked at once (a world with no roads); the walk is reg05_household_walks_test
	test_venture_till_travels()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	w.judgment.cfg.decision.integration.work_accept = false      # the villager's own yes is JudgmentLive's test; here the terms
	return w


func of_job(w: World, job: String) -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.job == job)


## The goods ledger the conservation suite reads: every item held anywhere (packs, stores, sites, tills of goods).


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


## Every smith station busy, the businesses' own included: work for the trade and no room anywhere.


func found_one(w: World) -> NPC:
	var s := founder(w)
	smithy_full(w)
	w.ventures.found(s, w.ventures.eligible(s))
	return s


func finish(w: World, s: NPC) -> Dictionary:
	var hh: Dictionary = w.households[s.household]
	var p: Dictionary = w.plot(str(hh.build))
	var pantry: Inventory = hh.pantry
	for id in p.site.need.duplicate():
		pantry.add(id, int(p.site.need[id]))
	w.deliver(p, pantry)
	return w.buildings.get(str(p.get("building", "")), {})


## A founded, built and opened smithy of seed `seed`'s best smith: [keeper, workshop].


func open_one(w: World) -> Array:
	var s := found_one(w)
	var b := finish(w, s)
	w.minutes += 1440.0
	w.station_load = {}                   # no demand read this morning: the business opens and hires nobody yet
	w.ventures.daily()
	return [s, b]


# ---------------------------------------------------------------- D1 ------------------------------



func test_venture_till_travels() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	var v: Dictionary = b.venture
	check(not v.is_empty() and int(v.household) == s.household, "fixture: an open business run by the keeper's household")
	v.till = 57
	var h := s.household
	var ms: Array = w.brain._members(h)
	var purses := 0
	for o: NPC in ms:
		purses += o.coins
	var t0 := w.treasury
	var src0 := w.coin_sources
	var st: OffMapSettlement = w.regions.by_id["wulstead"]
	# the property sale (PROP-06, where present) is the manor's purchase; measure the till alone
	var sold := 0
	for rec in w.property.held_by(World.hh_ref(h)):
		if w.owner_of(rec) == World.hh_ref(h):
			sold += w.property.sale_value(rec)
	var ok := Migration._household_out(w, st, ms, true, "work", Migration.hiring(st) if Migration.hiring(st) != "" else "farm")
	check(ok, "the household leaves")
	check(int(b.venture.get("till", 0)) == 0 if b.has("venture") else true, "the business's till is empty after they left")
	check(w.treasury <= t0, "the manor gained nothing from the till (treasury %d -> %d; %d of property would be bought with PROP-06)" % [t0, w.treasury, sold])
	var crossed: int = src0 - w.coin_sources
	check(crossed >= purses + 57, "the till's 57 coins went with the household (%d crossed, purses %d)" % [crossed, purses])
