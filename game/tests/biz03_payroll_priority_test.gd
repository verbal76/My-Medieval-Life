extends SceneTree
## BIZ-03 (owner decision 2026-11-08, Option B; docs/directives/2026-11-09_overnight_autonomous_development.md): a business's
## employee payroll comes before the owner's withdrawals from its till, and hiring must afford the whole payroll with the new
## employee, not one wage.
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_payroll_first()
	test_hiring_budgets_payroll()
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


func candidate(w: World, b: Dictionary, trade := "smith") -> NPC:
	var sk: String = w.brain._trade_skill(trade)
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.job in Construction.HIRABLE and o.id != int(b.venture.keeper) \
				and w.employment.refusal(o, trade, Ventures.ref_of(b)) == "":
			if int(o.skills.get(sk, 0)) <= 0:
				o.skills[sk] = Skills.xp_for_level(1)
			return o
	return null



func test_payroll_first() -> void:
	var w := world()
	var r := open_one(w)
	var b: Dictionary = r[1]
	var v: Dictionary = b.venture
	var e := candidate(w, b)
	var wage: int = w.employment.market_wage("smith")
	v.till = wage * 10
	check(w.employment.hire_for(Ventures.ref_of(b), e, "smith", wage) == "", "fixture: a paid employee")
	w.minutes += 1440.0
	var owner: NPC = w.party(w.business.money.venture_owner(b))
	check(owner != null, "fixture: the household that owns the business")
	for o: NPC in w.brain._members(owner.household):
		o.coins = 0                                  # the owner's household is short of its own reserve: it would draw on the till
	v.till = wage                                    # exactly today's wage in the till
	var c0 := w.total_coins()
	check(w.employment.payroll_due(Ventures.ref_of(b)) == wage, "today's wage is owed (%d)" % wage)
	w.business.money.daily()
	check(int(v.till) >= wage, "the owner's withdrawal left today's wage in the till (till %d, wage %d)" % [int(v.till), wage])
	var ec := e.coins
	w.employment.daily()
	check(w.employment.is_employed(e) and e.coins == ec + wage, "the employee was paid and keeps the post")
	check(w.total_coins() == c0, "no coin made or lost")
	# with more than the wage, the owner still draws what is above it
	w.minutes += 1440.0
	v.till = wage + 40
	for o: NPC in w.brain._members(owner.household):
		o.coins = 0
	w.business.money.daily()
	check(int(v.till) >= wage and int(v.till) < wage + 40, "the owner drew only what was above the payroll (till %d)" % int(v.till))


func test_hiring_budgets_payroll() -> void:
	var w := world()
	var r := open_one(w)
	var b: Dictionary = r[1]
	var v: Dictionary = b.venture
	var e := candidate(w, b)
	var wage: int = w.employment.market_wage("smith")
	v.till = wage * 10
	check(w.employment.hire_for(Ventures.ref_of(b), e, "smith", wage) == "", "fixture: one paid employee already")
	var runway := int(Ventures.cfg().get("hire_runway_days", 7))
	var payroll: int = w.employment.payroll(Ventures.ref_of(b))
	check(payroll == wage, "the payroll is the one wage (%d)" % payroll)
	for st in w.ventures.trade_stations(b, "smith"):
		w.stations[st].capacity = 6                  # room at its stations, so the till alone decides
	for o: NPC in w.npcs:                            # willing hands with a little smithing, so a candidate exists
		if o.alive and o.role == "adult" and o.job in Construction.HIRABLE and int(o.skills.get("smithing", 0)) <= 0:
			o.skills["smithing"] = Skills.xp_for_level(1)
	smithy_full(w)
	check(bool(w.brain.skilled_place("smith").work), "fixture: the trade has work")
	var n0: int = w.employment.of_employer(Ventures.ref_of(b)).size()
	v.till = (payroll + wage) * runway - 1            # one wage's runway, but not the payroll's with a second employee
	w.ventures._hire(b)
	check(w.employment.of_employer(Ventures.ref_of(b)).size() == n0, "a till short of the whole payroll's runway hires nobody more")
	v.till = (payroll + wage) * runway                # the whole payroll's runway with the new wage
	w.ventures._hire(b)
	check(w.employment.of_employer(Ventures.ref_of(b)).size() == n0 + 1, "a till that carries the whole payroll takes on the next employee")
