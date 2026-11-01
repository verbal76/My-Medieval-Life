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


# ---------------------------------------------------------------- EMP-PERM-01 --------------------
## A home of the player's own with its chest: a house built on ground bought from the manor (the coins and materials given
## here; earned and bought in play).
func player_home(w: World) -> void:
	if w.player.home != "" and w.buildings.has(w.player.home):
		return
	var sp = w.map.data.spawns.player
	var c: Construction = w.construction
	var rect := c.find_ground("house", Vector2i(int(sp[0]), int(sp[1])), World.PLAYER)
	w.player.coins += w.property.land_price(rect.size.x, rect.size.y)
	var p: Dictionary = c.place("house", rect, World.PLAYER)
	for id in p.site.need.duplicate():
		w.player.inv.add(id, int(p.site.need[id]))
	w.deliver(p, w.player.inv)
	w.property.set_home(str(p.building))


func employable(w: World) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.job in Construction.HIRABLE and w.employment.refusal(o) == "":
			return o
	return null


func test_employment() -> void:
	var w := world()
	w.judgment.cfg.decision.integration.work_accept = false     # the villager's own yes is the JudgmentLive test's; here the terms
	var any: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job in Construction.HIRABLE:
			any = o
			break
	if w.player.home == "":
		check(w.employment.refusal(any).begins_with("You need a home"), "no home with a chest: nobody can be employed to fill it")
	player_home(w)
	w.player.coins += 100
	var n := employable(w)
	check(n != null, "an adult without a trade of their own can be employed")
	check(w.employment.refusal(w.npc(w.sage_id)) != "", "a villager with a trade of their own cannot")
	var coins := w.total_coins()
	var pc := w.player.coins
	var nc := n.coins
	check(w.employment.employ(n, "miner") == "", "the player employs a miner")
	var wage := Employment.wage()
	check(n.job == "miner" and w.employment.is_employed(n), "their work is now mining for the player")
	check(w.player.coins == pc - wage and n.coins == nc + wage and w.total_coins() == coins, "the first day's wage moves from the player's purse to theirs; no coin made")
	check(w.employment.employ(n, "miner") != "", "the same villager cannot be employed twice")
	# a working morning: they go mining for the employer
	w.minutes = float(w.day()) * 1440.0 + 9 * 60
	if not n.inv.has("pickaxe"):
		n.inv.add("pickaxe", 1)            # the employee's own tool (bought with their own coins in play)
	n.plan.clear()
	check(w.employment.plan(n) and n.plan.any(func(s): return str(s.get("act", "")) == "emp_mine"), "in the working day the employee plans to mine a seam")
	var step: Dictionary = n.plan.filter(func(s): return str(s.get("act", "")) == "emp_mine")[0]
	var d: Dictionary = w.deposit_at(Vector2i(int(step.args.x), int(step.args.y)), int(step.args.get("level", 0)))
	var seam := int(d.amount)
	var ore := str(d.ore)
	var held := n.inv.count(ore)
	for i in 3:
		w.employment.act_mine(n, step.args)
	var dug := n.inv.count(ore) - held
	check(dug > 0 and seam - int(d.amount) == dug and int(w.employment.record_of(n).owed.get(ore, 0)) == dug, "the ore leaves the seam into their hands, owed to the employer (%d %s)" % [dug, ore])
	var chest: Inventory = w.construction.store_of(World.PLAYER)
	var in_chest := chest.count(ore)
	check(w.employment.act_deliver(n) and chest.count(ore) - in_chest == dug and n.inv.count(ore) == held, "carried home, the ore goes into the employer's chest: nothing made or lost")
	check(w.employment.carried(w.employment.record_of(n), n) == 0, "nothing more is owed")
	# the labour market leaves them where they are
	w.brain.seek_work()
	check(n.job == "miner" and w.employment.is_employed(n), "the morning labour market does not move a permanent employee")
	# each dawn the wage, from the purse; an unpaid wage ends it
	w.minutes += 1440.0
	pc = w.player.coins
	nc = n.coins
	coins = w.total_coins()
	w.employment.daily()
	check(w.player.coins == pc - wage and n.coins == nc + wage and w.total_coins() == coins, "the next day's wage is paid at dawn")
	w.employment.daily()
	check(w.player.coins == pc - wage, "paid once a day")
	var spare := w.player.coins
	w.player.coins = wage - 1
	w.minutes += 1440.0
	w.employment.daily()
	check(not w.employment.is_employed(n) and n.job == "miner", "an unpaid wage ends the employment (they keep their trade)")
	w.player.coins = spare
	# dismissal by the employer
	check(w.employment.employ(n, "miner") == "" and w.employment.dismiss(n) == "" and not w.employment.is_employed(n), "the employer can let their employee go")
	# save and load
	w.employment.employ(n, "miner")
	w.employment.record_of(n).owed = {"coal": 2}
	var wd: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(wd.has("employment") and int(wd.save_version) == World.SAVE_VERSION, "the employment is saved under its optional key (save_version unchanged)")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), wd)
	var r2: Dictionary = w2.employment.record_of(w2.npc(n.id))
	check(not r2.is_empty() and str(r2.employer) == World.PLAYER and int(r2.owed.coal) == 2 and int(r2.wage) == wage, "the employment is kept through save and load")
	wd.erase("employment")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), wd)
	check(w3.employment.is_empty(), "a save from before it loads with no employees")
	# a working day lived through: the employee really mines and brings the ore home, coins and goods kept
	var w4 := world(2)
	w4.judgment.cfg.decision.integration.work_accept = false
	player_home(w4)
	w4.player.coins += 100
	var e := employable(w4)
	w4.minutes = float(w4.day()) * 1440.0 + 7 * 60
	w4.employment.employ(e, "miner")
	if not e.inv.has("pickaxe"):
		e.inv.add("pickaxe", 1)
	e.plan.clear()
	var c4 := w4.total_coins() + 0
	var chest4: Inventory = w4.construction.store_of(World.PLAYER)
	var before := 0
	for o in Employment.ORES:
		before += chest4.count(o)
	for m in 11 * 60:
		w4.update(0.5)
		w4.player.hunger = 100.0
	var after := 0
	for o in Employment.ORES:
		after += chest4.count(o)
	check(int(w4.stats.get("employment_mined", 0)) > 0 and after > before, "in a lived working day the employee mines and the ore reaches the employer's chest (%d mined, %d delivered)" % [int(w4.stats.get("employment_mined", 0)), after - before])
	check(w4.total_coins() == c4, "coins are conserved through the lived working day (%d)" % c4)
