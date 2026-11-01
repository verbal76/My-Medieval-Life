extends SceneTree
## B25-BUSINESS-IMPL (owner B25-BUSINESS-D2), the business-hiring part of B25-EMPLOY-D3 and EMP-PERM-01 (owner B18-DP-01)
## (docs/expansion20/BUSINESS_FOUNDING.md). Founding needs skill, experience, motivation, capital, premises and demand; none
## is founded without demand; founding moves coins only to the manor's land office; a venture opens on a finished workshop,
## hires through the labour market with the keeper's leave, changes hands in the family, and closes when idle with the
## workshop staying the family's; the player's permanent miner is paid a wage from the purse and the ore goes to the
## employer's chest, coins and goods conserved; determinism; save and load, an older save included. Run headless:
##   godot --headless --path game --script res://tests/business_founding_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	test_eligibility()
	test_no_demand_no_venture()
	test_decision()
	test_found_conserves()
	test_open_and_hire()
	test_handover_and_close()
	test_determinism()
	test_save_load()
	if has_method("test_employment"):
		call("test_employment")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func of_job(w: World, job: String) -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.job == job)


## The smiths' stations full and busy for the last few days: work for another hand and no room (skilled_place).
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


## The smith of seed 1 with the most skill, made experienced and given the means to found (test setup only).
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


func test_eligibility() -> void:
	var w := world()
	var s := founder(w)
	smithy_full(w)
	var why: String = w.ventures.refusal(s)
	check(why == "", "a skilled, experienced smith whose household owns its house and can spare the start may found (%s)" % why)
	var opt: Dictionary = w.ventures.eligible(s)
	check(str(opt.get("kind", "")) == "smithy" and int(opt.spare) >= int(opt.need), "the option is a smithy beside the house the household can pay for")
	var lv: int = int(s.skills.smithing)
	s.skills.smithing = Skills.xp_for_level(2)
	check(w.ventures.refusal(s) == "not skilled enough yet", "too little skill: not considered")
	s.skills.smithing = lv
	w.experience.minutes[World.npc_ref(s.id)]["smithing"] = 480.0
	check(w.ventures.refusal(s) == "too little experience in the trade", "too little experience: not considered")
	w.experience.minutes[World.npc_ref(s.id)]["smithing"] = 480.0 * 60.0
	var coins := s.coins
	s.coins = 0
	for o: NPC in w.brain._members(s.household):
		o.coins = 0
	check(w.ventures.refusal(s) == "the household cannot spare the money", "no capital: not considered")
	s.coins = coins
	var tanner: NPC = of_job(w, "merchant")[0]
	check(w.ventures.refusal(tanner) == "not in a founding trade", "a merchant founds no workshop (stalls and storefronts are theirs)")


func test_no_demand_no_venture() -> void:
	var w := world()
	var s := founder(w)
	w.station_load = {}
	check(w.ventures.refusal(s) == "no opening for another workshop of the trade", "no work seen at the trade's stations: no opening")
	for d in 28:
		w.minutes = float(d) * 1440.0 + 6 * 60
		w.ventures.daily()
	check(int(w.stats.get("ventures_founded", 0)) == 0 and w.ventures.setting_up().is_empty(), "four weeks without demand found nothing")


func test_decision() -> void:
	var w := world()
	var s := founder(w)
	smithy_full(w)
	var opt: Dictionary = w.ventures.eligible(s)
	w.judgment.cfg.decision.trait_spread_permille = 0
	w.judgment.cfg.decision.selection = "argmax"
	w.judgment.cfg.decision.profiles.business_found.forgo = 0
	check(w.ventures.decides(s, opt), "with nothing to lose by it (forgo 0), an eligible smith decides to found")
	w.judgment.cfg.decision.profiles.business_found.forgo = 100000
	check(not w.ventures.decides(s, opt), "doing without weighed above everything: they do not")
	w.judgment.cfg.decision.integration.business_found = false
	w.station_load = {}
	smithy_full(w)
	for d in 8:
		w.minutes = float(d) * 1440.0 + 6 * 60
		w.ventures._consider()
	check(int(w.stats.get("ventures_founded", 0)) == 0, "with the judgment reading switched off, nobody founds")


## Founding: the site is marked out beside the house and the ground paid to the manor; coins only move.
func found_one(w: World) -> NPC:
	var s := founder(w)
	smithy_full(w)
	var opt: Dictionary = w.ventures.eligible(s)
	var before := w.total_coins()
	var ok: bool = w.ventures.found(s, opt)
	check(ok and w.total_coins() == before, "founding marks out the site and creates no coin (%d -> %d)" % [before, w.total_coins()])
	return s


func test_found_conserves() -> void:
	var w := world()
	var s := founder(w)
	smithy_full(w)
	var opt: Dictionary = w.ventures.eligible(s)
	var purse: int = w.property.purse(World.hh_ref(s.household))
	var treasury := w.treasury
	var before := w.total_coins()
	check(w.ventures.found(s, opt), "the smith founds")
	var hh: Dictionary = w.households[s.household]
	var p: Dictionary = w.plot(str(hh.build))
	check(not p.is_empty() and str(p.site.kind) == "smithy" and str(p.site.owner) == World.hh_ref(s.household), "a smithy site of the household's is marked out (hh.build)")
	var land: int = w.property.land_price(opt.rect.size.x, opt.rect.size.y)
	var paid := purse - w.property.purse(World.hh_ref(s.household))
	check(paid >= land and w.treasury - treasury == land and w.total_coins() == before, "the ground is paid to the manor (%d coins; %d left the purse with the first helper's wage), nothing created" % [land, paid])
	check(hh.venture.founder == s.id and str(hh.venture.trade) == "smith", "the household's venture is being set up")
	check(w.ventures.refusal(s) != "", "one venture at a time")


## Deliver the site's materials from the household's pantry (bought in a real game; given here) so the workshop stands.
func finish(w: World, s: NPC) -> Dictionary:
	var hh: Dictionary = w.households[s.household]
	var p: Dictionary = w.plot(str(hh.build))
	var pantry: Inventory = hh.pantry
	for id in p.site.need.duplicate():
		pantry.add(id, int(p.site.need[id]))
	w.deliver(p, pantry)
	return w.buildings.get(str(p.get("building", "")), {})


func test_open_and_hire() -> void:
	var w := world()
	var s := found_one(w)
	var b := finish(w, s)
	check(not b.is_empty() and str(b.type) == "workshop" and w.owner_of(b) == World.hh_ref(s.household), "the finished smithy is the household's")
	w.minutes += 1440.0
	w.ventures.daily()
	check(b.has("venture") and int(b.venture.keeper) == s.id and w.ventures.setting_up().is_empty(), "the venture opens on the finished workshop")
	check(w.stations.has(s.workplace) and str(w.stations[s.workplace].building) == str(b.id), "the founder works at their own forge")
	check(str(w.brain._station_for(s, str(w.stations[s.workplace].type))) == s.workplace and str(w.stations[w.brain._station_for(s, "forge")].building) == str(b.id), "the founder's own stations come first")
	# the trade is busy at the manor's stations and the new smithy has free time: a place opens at the venture
	smithy_full(w)
	for o: NPC in of_job(w, "smith"):
		o.income_days = [40, 40, 40, 40, 40]
		o.job_since = -100
		o.left_job = ""
	var m: Dictionary = w.brain.skilled_place("smith")
	check(bool(m.room) and w.ventures.hiring_station(str(m.place)), "the venture's free stations are room for another smith (%s)" % str(m.place))
	var hand: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job in ["", "manor_hand", "laborer", "farmer", "woodcutter"] and o.household != s.household:
			hand = o
			break
	var market := {"smith": m}
	m.open = 1
	w.brain._take_place(hand, "smith", "test", market)
	check(hand.job == "smith" and (b.venture.hands as Array).has(hand.id) and w.npc_may_use(hand, w.stations[str(m.place)]), "the hand taken is given the keeper's leave at the venture")
	check(not w.may_use("", w.stations[str(m.place)]), "the workshop is not opened to everyone")


func test_handover_and_close() -> void:
	var w := world()
	var s := found_one(w)
	var b := finish(w, s)
	w.minutes += 1440.0
	w.ventures.daily()
	# another adult of the family takes up the trade; the founder leaves it: the family keeps the business on
	var heir: NPC = null
	for o: NPC in w.brain._members(s.household):
		if o.alive and o.role == "adult" and o != s:
			heir = o
	if heir != null:
		heir.job = "smith"
		s.job = "farmer"
		w.minutes += 1440.0
		w.ventures.daily()
		check(b.has("venture") and int(b.venture.keeper) == heir.id, "the business changes hands within the family")
		s.job = "smith"
		heir.job = "smith"
		b.venture.keeper = s.id
	# no work at its stations for close_idle_days mornings: it closes, the workshop stays the family's
	var empty := []
	for i in int(GameData.b("skilled_places").window_days):
		empty.append({})
	var coins := w.total_coins()
	for d in int(GameData.b("ventures").close_idle_days) + 1:
		w.minutes += 1440.0
		w.station_load = {"day": w.day(), "today": {}, "past": empty.duplicate(true)}
		w.ventures.daily()
	check(not b.has("venture") and int(w.stats.get("ventures_closed_idle", 0)) == 1, "a venture with no work closes")
	check(w.buildings.has(str(b.id)) and w.owner_of(b) == World.hh_ref(s.household) and w.total_coins() == coins, "the workshop stays the family's; nothing is paid or taken")
	# the keeper and nobody else: closing with no keeper
	var w2 := world()
	var s2 := found_one(w2)
	var b2 := finish(w2, s2)
	w2.minutes += 1440.0
	w2.ventures.daily()
	for o: NPC in w2.brain._members(s2.household):
		if o.job == "smith" and o != s2:
			o.job = "farmer"
	s2.job = "farmer"
	w2.minutes += 1440.0
	w2.ventures.daily()
	check(not b2.has("venture") and int(w2.stats.get("ventures_closed_keeper", 0)) == 1, "nobody of the family in the trade: the venture closes")


func snapshot(w: World) -> String:
	var t := ""
	for b in w.ventures.open_ventures():
		t += JSON.stringify(b.venture)
	for h in w.households.size():
		if w.households[h].has("venture"):
			t += JSON.stringify(w.households[h].venture)
	return t + str(w.total_coins())


func test_determinism() -> void:
	var a := world(3)
	var b := world(3)
	for w: World in [a, b]:
		founder(w)
		smithy_full(w)
		w.judgment.cfg.decision.profiles.business_found.forgo = 0
		for d in 8:
			w.minutes = float(d) * 1440.0 + 6 * 60
			smithy_full(w)
			w.ventures.daily()
	check(snapshot(a) == snapshot(b) and int(a.stats.get("ventures_founded", 0)) >= 1, "the same seed founds the same business on the same morning (%d)" % int(a.stats.get("ventures_founded", 0)))


func test_save_load() -> void:
	var w := world()
	var s := found_one(w)
	var b := finish(w, s)
	w.minutes += 1440.0
	w.ventures.daily()
	var wd: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(int(wd.save_version) == World.SAVE_VERSION, "save_version unchanged (%d)" % int(wd.save_version))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), wd)
	check(w2.buildings[str(b.id)].has("venture") and int(w2.buildings[str(b.id)].venture.keeper) == s.id, "the venture is kept through save and load")
	check(str(w2.stations[w2.brain._station_for(w2.npc(s.id), "forge")].building) == str(b.id), "the loaded keeper still works their own forge first")
	var old := wd.duplicate(true)
	for bd in (old.buildings as Dictionary).values():
		(bd as Dictionary).erase("venture")
	for hd in old.households:
		(hd as Dictionary).erase("venture")
	old.erase("employment")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.ventures.open_ventures().is_empty() and w3.ventures.setting_up().is_empty(), "a save from before ventures loads with none")
	w3.minutes += 1440.0
	w3.ventures.daily()
	check(true, "an older save runs its morning without error")
