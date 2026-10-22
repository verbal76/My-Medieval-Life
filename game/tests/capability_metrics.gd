extends RefCounted
## PROSPECTIVE (Expansion 18, X18-SIM; PROS-18): the capability-analysis switch and measurements for economy_sim.gd.
## Analysis only; changes nothing unless its arguments are given.
##   --capability L          force capability level L (0-10) on the implemented industries (CapabilityHook)
##   --cap-profile NAME      the profile those levels read (default the active one, "approved", X18-CAPNUM; UNAPPROVED
##                           candidates: conservative, moderate, aggressive, ...)
##   --cap-industries a,b    the industries forced (default: mining, forestry, farming, smithing, carpentry, tanning)
##   --cap-scenario NAME     a start-state change made with existing data and systems:
##        resource_poor   the village's seams and boulders hold 40% of their ore and stone; fields yield 2/3 (field_yield)
##        resource_rich   seams and boulders hold twice as much; fields yield 4/3
##        labour_poor     one in four villagers of the productive trades leaves the village at the start (World.kill with
##                        the cause "left the village"; their goods pass to heirs; vacancies follow the B8-016 rules)
##        labour_rich     six newcomers arrive at the start and take productive posts (NPCBrain._newcomer_for, the B8-016
##                        succession newcomer: their purses are counted as coins from outside, as every newcomer's are)
##   --cap-report            print a "CAPABILITY {json}" line at the end (also on whenever any argument above is given)
## The production systems themselves are the game's: the switch only shortens each unit's work time (OutputMultiplier)
## and raises the manor's quarry and mending wages (PayMultiplier); ore still comes from seams, inputs from packs, crops
## from fields.

const IMPLEMENTED := ["mining", "forestry", "farming", "smithing", "carpentry", "tanning"]
const JOB_INDUSTRY := {"miner": "mining", "woodcutter": "forestry", "farmer": "farming", "smith": "smithing",
	"carpenter": "carpentry", "tanner": "tanning"}
const PRICE_ITEMS := ["wheat", "bread", "log", "plank", "iron_ore", "iron_bar", "pickaxe", "axe", "leather", "stone"]


static func _arg(args: Array, name: String, fallback: String) -> String:
	return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback


static func wanted(args: Array) -> bool:
	for a in ["--capability", "--cap-profile", "--cap-scenario", "--cap-report", "--cap-industries"]:
		if a in args:
			return true
	return false


## Before World.setup: the forced levels and the field-yield part of a scenario.
static func pre_setup(args: Array) -> Dictionary:
	CapabilityHook.off()
	CapabilityHook.analysis = true          # forced levels alone: the per-worker path (the game's own) is not bound
	var info := {"level": int(_arg(args, "--capability", "-1")), "profile": _arg(args, "--cap-profile", ""),
		"scenario": _arg(args, "--cap-scenario", "normal"), "industries": IMPLEMENTED.duplicate()}
	if "--cap-industries" in args:
		info.industries = Array(_arg(args, "--cap-industries", "").split(","))
	if int(info.level) >= 0 and str(info.profile) != "":
		for ind in info.industries:
			CapabilityHook.forced[ind] = int(info.level)
		CapabilityHook.profile = str(info.profile)
	match str(info.scenario):
		"resource_poor":
			GameData.balance["field_yield"] = roundi(float(GameData.b("field_yield")) * 2.0 / 3.0)
		"resource_rich":
			GameData.balance["field_yield"] = roundi(float(GameData.b("field_yield")) * 4.0 / 3.0)
	return info


## After World.setup, before the simulation's opening books: the rest of the scenario.
static func post_setup(info: Dictionary, w: World) -> void:
	match str(info.scenario):
		"resource_poor", "resource_rich":
			var f := 0.4 if str(info.scenario) == "resource_poor" else 2.0
			for d in w.deposits:
				d.amount = maxi(1, roundi(float(d.amount) * f))
			for b in w.boulders:
				b.amount = maxi(1, roundi(float(b.amount) * f))
		"labour_poor":
			var k := 0
			for n: NPC in w.npcs.duplicate():
				if n.alive and n.role == "adult" and JOB_INDUSTRY.has(n.job):
					k += 1
					if k % 4 == 0:
						w.kill(n, "left the village")
		"labour_rich":
			var jobs := ["miner", "miner", "woodcutter", "farmer", "smith", "carpenter"]
			for job in jobs:
				var model: NPC = null
				for n: NPC in w.npcs:
					if n.alive and n.job == job:
						model = n
						break
				if model == null:
					continue
				w.brain._newcomer_for({"job": job, "workplace": model.workplace, "home": "", "household": -1, "day": w.day(),
					"who": "(scenario)"})


## The opening measurements.
static func snapshot(w: World) -> Dictionary:
	var earned := {}
	var spent := {}
	for n: NPC in w.npcs:
		earned[n.id] = n.earned
		spent[n.id] = n.spent
	var dep := {}
	for d in w.deposits + w.boulders:
		dep[str(d.ore)] = int(dep.get(str(d.ore), 0)) + int(d.amount)
	return {"stats": w.stats.duplicate(), "earned": earned, "spent": spent, "deposits": dep, "treasury": w.treasury,
		"hh_purses": _hh_purses(w)}


static func _hh_purses(w: World) -> Array:
	var out := []
	for h in w.households.size():
		if not w.brain._members(h).is_empty():
			out.append(w.property.purse(World.hh_ref(h)))
	return out


static func gini(v: Array) -> float:
	var xs := v.map(func(x): return maxf(0.0, float(x)))
	xs.sort()
	var n := xs.size()
	var total := 0.0
	for x in xs:
		total += x
	if n == 0 or total <= 0.0:
		return 0.0
	var cum := 0.0
	for i in n:
		cum += float(i + 1) * xs[i]
	return (2.0 * cum) / (float(n) * total) - float(n + 1) / float(n)


## Units made by each industry: from the economy ledger's counters (mined_, felled_, made_), by the industry of each
## recipe's outputs (CapabilityHook.recipe_industry) and the farmers' grain.
static func _units(w: World, s0: Dictionary) -> Dictionary:
	var d := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(s0.get(k, 0))
	var out := {"mining": 0, "forestry": 0, "farming": 0, "smithing": 0, "carpentry": 0, "tanning": 0}
	for k in w.stats:
		if str(k).begins_with("mined_"):
			out.mining += d.call(str(k))
	out.forestry = d.call("felled_log")
	out.farming = d.call("made_wheat")
	var seen := {}
	for rid in GameData.recipes:
		var ind := CapabilityHook.recipe_industry(rid)
		if ind == "" or not out.has(ind):
			continue
		for id in GameData.recipes[rid]["out"]:
			var key := "%s|%s" % [ind, id]
			if seen.has(key):
				continue
			seen[key] = true
			out[ind] += d.call("made_" + str(id))
	return out


static func report(info: Dictionary, w: World, s0: Dictionary, days: int) -> Dictionary:
	var units := _units(w, s0.stats)
	var workers := {}
	var pay := {}
	var cost := {}
	for n: NPC in w.npcs:
		if not JOB_INDUSTRY.has(n.job):
			continue
		var ind: String = JOB_INDUSTRY[n.job]
		if n.alive:
			workers[ind] = int(workers.get(ind, 0)) + 1
		pay[ind] = int(pay.get(ind, 0)) + n.earned - int(s0.earned.get(n.id, 0))
		cost[ind] = int(cost.get(ind, 0)) + n.spent - int(s0.spent.get(n.id, 0))
	var per_worker_day := {}
	for ind in units:
		per_worker_day[ind] = snappedf(float(units[ind]) / maxf(1.0, float(workers.get(ind, 0))) / maxf(1.0, float(days)), 0.001)
	# businesses: every villager whose trade buys (NPCBrain.BUYS): coins earned minus spent over the run
	var biz := {"n": 0, "profit": 0, "losing": 0, "broke": 0}
	var by_role := {}
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		var role: String = w.brain.buy_role(n)
		if not NPCBrain.BUYS.has(role):
			continue
		var p := (n.earned - int(s0.earned.get(n.id, 0))) - (n.spent - int(s0.spent.get(n.id, 0)))
		biz.n += 1
		biz.profit += p
		by_role[role] = int(by_role.get(role, 0)) + p
		if p < 0:
			biz.losing += 1
		if n.coins <= 0:
			biz.broke += 1
	biz["by_role"] = by_role
	# households: purse and days of food in the pantry and packs
	var purses := _hh_purses(w)
	var food_days := []
	var broke_hh := 0
	for h in w.households.size():
		var ms: Array = w.brain._members(h)
		if ms.is_empty():
			continue
		var pts := 0.0
		for f in NPCBrain.FOOD:
			pts += float((w.households[h].pantry as Inventory).count(f)) * float(GameData.item(f).food)
			for o: NPC in ms:
				pts += float(o.inv.count(f)) * float(GameData.item(f).food)
		food_days.append(pts / maxf(1.0, w.brain.household_day_food(h)))
		if w.property.purse(World.hh_ref(h)) <= 0:
			broke_hh += 1
	purses.sort()
	food_days.sort()
	var med := func(a: Array) -> float: return float(a[a.size() / 2]) if not a.is_empty() else 0.0
	var mean := func(a: Array) -> float: return a.reduce(func(x, y): return x + float(y), 0.0) / maxf(1.0, float(a.size()))
	# resources
	var dep := {}
	for d in w.deposits + w.boulders:
		dep[str(d.ore)] = int(dep.get(str(d.ore), 0)) + int(d.amount)
	var used := {}
	for k in w.stats:
		if str(k).begins_with("used_") and not str(k).begins_with("used_building_"):
			var n2 := int(w.stats[k]) - int(s0.stats.get(k, 0))
			if n2 > 0:
				used[str(k).substr(5)] = n2
	# availability and prices at the market
	var avail := {}
	var prices := {}
	for id in PRICE_ITEMS:
		var held := 0
		var p := 0
		for n: NPC in w.npcs:
			if n.alive and w.brain.buy_role(n) in SettlementHoldings.MARKET_ROLES:
				held += n.inv.count(id)
				if p == 0 and n.inv.count(id) > 0:
					p = w.sell_price(n, id)
		avail[id] = held
		prices[id] = p
	var st := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(s0.stats.get(k, 0))
	var alive := 0
	for n: NPC in w.npcs:
		if n.alive and n.role != "bandit":
			alive += 1
	return {"profile": str(info.profile), "level": int(info.level), "scenario": str(info.scenario), "days": days,
		"industries": info.industries, "units": units, "workers": workers, "units_per_worker_day": per_worker_day,
		"labour_pay": pay, "production_cost": cost, "wages_paid_gov": st.call("gov_wages"),
		"manor_job_wages": st.call("manor_job_wages"), "business": biz,
		"households": {"n": purses.size(), "purse_mean": snappedf(mean.call(purses), 0.1), "purse_median": med.call(purses),
			"food_days_median": snappedf(med.call(food_days), 0.01), "broke": broke_hh},
		"gini_households": snappedf(gini(purses), 0.001),
		"deposits_start": s0.deposits, "deposits_end": dep, "used": used, "market_stock": avail, "prices": prices,
		"caravan": {"in": st.call("caravan_coins_in"), "out": st.call("caravan_coins_out")},
		"alive": alive, "missed_meals_no_money": st.call("missed_meal_no_money"),
		"missed_meals_no_food": st.call("missed_meal_no_food_for_sale"), "treasury_end": w.treasury}
