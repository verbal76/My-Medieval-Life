extends SceneTree
## BIZ-08 (Build 25 audit, docs/audits/2026-11-08_build25_master_audit_register.md): a business's hands are kept as villager ids
## in its record; a save stores them as JSON numbers, which load as floats, and Array.has(int) does not match a float, so after a
## load in the middle of a day a hand could not use the business's benches until the next morning's check rewrote the list.
## Hands must be recognised the same before and after a save and load.
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	var w := world()
	var kb := open_one(w)
	var b: Dictionary = kb[1]
	check(not b.is_empty() and b.has("venture"), "fixture: an open smithy")
	var hand: NPC = null
	for o: NPC in of_job(w, "smith"):
		if o.id != int(b.venture.keeper):
			hand = o
			break
	check(hand != null, "fixture: another smith")
	var st: String = w.ventures.trade_stations(b, "smith")[0]
	w.ventures.took_place(hand, st)
	var kind := str(w.stations[st].type)
	check(not w.ventures.stations_for(hand, kind).is_empty(), "before saving: the hand may use the smithy's %s" % kind)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var h2: NPC = w2.npc(hand.id)
	check(h2 != null and not w2.ventures.stations_for(h2, kind).is_empty(), "after a save and load the same day: the hand still may use it")
	var b2: Dictionary = w2.buildings[str(b.id)]
	w2.ventures.took_place(h2, st)
	check((b2.venture.hands as Array).size() == 1, "taking the place again after a load does not list the hand twice (%s)" % str(b2.venture.hands))
	w.dispose()
	w2.dispose()
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


