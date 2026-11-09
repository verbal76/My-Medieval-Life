extends SceneTree
## Long-run economy report: one line per game day of food made and eaten, exports, missed
## meals by cause, prices, employment, household independence, coins, deaths, plus a CSV and a
## household table. Diagnostics only: it reads the world and changes nothing in it (except the
## optional poorly-managed-village switches below, which set up a scenario before day 1).
##   godot --headless --path game --script res://tests/econ_report.gd -- --days 30 [--seed 1] [--csv path]
##     [--neglect-livestock] [--fields N] [--farmers N]
##
## A household counts as independent on a day when it received no relief from the reeve, nobody in
## it fell below 20 hunger, and its wealth (cash plus pantry food at 1 coin per 20 food points) did
## not fall by more than a fifth over the last 3 days, unless it still holds a day's living costs
## (6 coins a person). Relief is read as a cash rise at the reeve's 17:00 business for households
## that meet the game's relief condition (less pantry food than members and under 4 coins each).

const FOOD_POINTS := {"wheat": 20.0, "pottage": 40.0, "roast_meat": 60.0, "ale": 10.0}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var days := 30
	var csv := ""
	var seed := 1
	for i in args.size():
		if args[i] == "--days":
			days = int(args[i + 1])
		elif args[i] == "--csv":
			csv = args[i + 1]
		elif args[i] == "--seed":
			seed = int(args[i + 1])
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	# poorly managed villages, to check that neglect has consequences
	if "--neglect-livestock" in args:
		for id in w.fauna.pens:
			w.fauna.pens[id].owner = -1
			w.fauna.pens[id].trough = 0
	if "--fields" in args:
		var keep_fields := int(args[args.find("--fields") + 1])
		while w.fields.size() > keep_fields:
			var f: Dictionary = w.fields.pop_back()
			for n: NPC in w.npcs:
				if n.workplace == f.id:
					n.workplace = w.fields[w.fields.size() - 1].id
					w.fields[w.fields.size() - 1].owner.append(n.id)
	if "--farmers" in args:
		var keep := int(args[args.find("--farmers") + 1])
		for n: NPC in w.npcs:
			if n.job == "farmer":
				if keep > 0:
					keep -= 1
				else:
					n.job = "manor_hand"
					for f in w.fields:
						f.owner.erase(n.id)
	var deaths_today := []
	var starved_today := [0]
	var killed_today := [0]
	w.event.connect(func(t: String):
		if "has died (starvation)" in t:
			starved_today[0] += 1
		elif "has died (slain" in t and not t.contains("bandit"):
			killed_today[0] += 1)
	w.npc_died.connect(func(n):
		if n.role != "bandit":
			deaths_today.append("%s %s (%s, household cash %d)" % [n.name, n.family, n.job if n.job != "" else n.role, _cash(w, n.household)]))
	# per adult: game day of first income; per household: relief, independence
	var first_income := {}
	var start_earned := {}
	for n: NPC in w.npcs:
		start_earned[n.id] = n.earned
	var relief := {}               # household -> coins received from the reeve
	var indep_days := {}           # household -> list of bool per day
	var wealth_hist := {}          # household -> list of wealth per day
	var rows := []
	var header := "day,alive,made_wheat,made_pottage,made_roast,made_ale,made_meat,eaten_points,need_points,feed_wheat,exported_food,missed_no_money,missed_no_food,stock_points,coins,poor_households,no_tool_workers,trees,ore,livestock,wild,starved,killed,working,no_work,independent_households,relief_coins,wheat_price,pottage_price,market_food_points,treasury,tax,gov_wages,gov_repairs,gov_relief_bought,gov_relief_grain,gov_procurement,granary,hh_wealth_median,hh_wealth_p25,hh_gini,insecure_households,unsustainable_households,job_changes,deaths"
	rows.append(header)
	print(header)
	var prev := {}
	var steps_per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for d in days:
		var low_hunger := {}
		for h in w.households.size():
			low_hunger[h] = 100.0
		var relief_today := 0
		for i in steps_per_day:
			var hour_before := int(w.hour())
			var before := []
			var eligible := []
			if hour_before == 16:
				for h in w.households.size():
					before.append(_cash(w, h))
					var pantry_food := 0
					for f in ["roast_meat", "pottage", "wheat", "ale"]:
						pantry_food += w.households[h].pantry.count(f)
					eligible.append(_living(w, h) > 0 and pantry_food < _living(w, h) and _cash(w, h) < 4 * _living(w, h))
			w.update(0.5)
			if hour_before == 16 and int(w.hour()) == 17:
				# the reeve's evening business ran in this step: a household whose cash rose got relief
				for h in w.households.size():
					var gain: int = _cash(w, h) - int(before[h])
					if gain > 0 and eligible[h]:
						relief[h] = int(relief.get(h, 0)) + gain
						relief_today += gain
						low_hunger[h] = minf(low_hunger[h], -1.0)        # marks relief for the day
			if i % 60 == 0:
				for n: NPC in w.npcs:
					if n.alive and n.household >= 0:
						low_hunger[n.household] = minf(low_hunger[n.household], n.hunger)
		for n: NPC in w.npcs:
			if n.role == "adult" and not first_income.has(n.id) and n.earned > int(start_earned[n.id]):
				first_income[n.id] = d + 1
		var indep := 0
		for h in w.households.size():
			if _living(w, h) == 0:
				continue
			var wealth: float = _cash(w, h) + _food(w, h) / 20.0
			if not wealth_hist.has(h):
				wealth_hist[h] = []
			wealth_hist[h].append(wealth)
			var hist: Array = wealth_hist[h]
			var holding: bool = hist.size() < 4 or wealth >= 0.8 * float(hist[hist.size() - 4]) or wealth >= 6.0 * _living(w, h)
			var ok: bool = low_hunger[h] >= 20.0 and holding
			if not indep_days.has(h):
				indep_days[h] = []
			indep_days[h].append(ok)
			if ok:
				indep += 1
		var st: Dictionary = w.stats.duplicate()
		var delta := func(k: String) -> float: return float(st.get(k, 0.0)) - float(prev.get(k, 0.0))
		var alive := 0
		var stock := 0.0
		var no_tool := 0
		var working := 0
		var no_work := 0
		for n: NPC in w.npcs:
			if not n.alive or n.role == "bandit":
				continue
			alive += 1
			for f in FOOD_POINTS:
				stock += n.inv.count(f) * float(FOOD_POINTS[f])
			if (n.job in ["miner", "laborer"] and not n.inv.has("pickaxe")) or (n.job == "woodcutter" and not n.inv.has("axe")):
				no_tool += 1
			if n.role == "adult":
				if n.job == "" or n.doing in ["lost"]:
					no_work += 1
				else:
					working += 1
		var poor := 0
		for h in w.households.size():
			var hh: Dictionary = w.households[h]
			for f in FOOD_POINTS:
				stock += hh.pantry.count(f) * float(FOOD_POINTS[f])
			var living := _living(w, h)
			if living > 0 and _cash(w, h) < 2 * living:
				poor += 1
		# household wealth (the reeve's coins are the treasury, not his household's) and food security
		var wealths := []
		var insecure := 0
		for h in w.households.size():
			var living := _living(w, h)
			if living == 0:
				continue
			var cash := _cash(w, h)
			wealths.append(cash + _food(w, h) / 20.0)
			if _food_days(w, h, cash) < 2.0:
				insecure += 1
		var dist := _distribution(wealths)
		var unsustainable := 0
		for hh in w.households:
			var e: Dictionary = hh.get("econ", {})
			if not e.is_empty() and not bool(e.sustainable):
				unsustainable += 1
		var exported := 0.0
		for f in FOOD_POINTS:
			exported += delta.call("exported_" + f) * float(FOOD_POINTS[f])
		var trees := 0
		for t in w.trees:
			if t.state == "grown":
				trees += 1
		var ore := 0
		for dp in w.deposits:
			ore += int(dp.amount)
		var livestock := 0
		var wild := 0
		for a: Animal in w.fauna.animals:
			if a.wild():
				wild += 1
			else:
				livestock += 1
		# the cheapest price a villager would pay, and what the food sellers hold
		var wheat_price := 0
		var pottage_price := 0
		var market := 0.0
		for n: NPC in w.npcs:
			if not n.alive:
				continue
			var food_seller: bool = n.job == "tavernkeeper" or w.brain.buy_role(n) == "merchant_food"
			if (n.job == "farmer" or w.brain.buy_role(n) == "merchant_food") and n.inv.count("wheat") >= 2:
				var p := w.sell_price(n, "wheat")
				if wheat_price == 0 or p < wheat_price:
					wheat_price = p
			if food_seller:
				for f in ["pottage", "roast_meat", "ale"]:
					market += n.inv.count(f) * float(FOOD_POINTS[f])
				if n.inv.has("pottage"):
					var p := w.sell_price(n, "pottage")
					if pottage_price == 0 or p < pottage_price:
						pottage_price = p
		var row := [d + 1, alive, delta.call("made_wheat"), delta.call("made_pottage"), delta.call("made_roast_meat"), delta.call("made_ale"),
			delta.call("made_meat"), delta.call("eaten_food"), w.brain.village_day_food(), delta.call("feed_eaten_wheat"),
			exported, delta.call("missed_meal_no_money"), delta.call("missed_meal_no_food_for_sale"), stock, w.total_coins(), poor, no_tool,
			trees, ore, livestock, wild, starved_today[0], killed_today[0], working, no_work, indep, relief_today, wheat_price, pottage_price,
			market, w.treasury, delta.call("gov_tax"), delta.call("gov_wages"), delta.call("gov_repairs"),
			delta.call("gov_relief_bought"), delta.call("gov_relief_grain"), delta.call("gov_procurement"), w.granary.count("wheat"),
			dist[0], dist[1], dist[2], insecure, unsustainable, delta.call("job_changes"), "; ".join(deaths_today)]
		var line := ",".join(row.map(func(v): return str(int(v)) if v is float else str(v)))
		rows.append(line)
		print(line)
		prev = st
		deaths_today.clear()
		starved_today[0] = 0
		killed_today[0] = 0
	print("--- households: members at start/end, relief received, days independent, independent from day")
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		var flags: Array = indep_days.get(h, [])
		var from_day := -1
		for k in range(flags.size() - 1, -1, -1):
			if not flags[k]:
				from_day = k + 2
				break
		if from_day == -1:
			from_day = 1
		var yes := flags.count(true)
		print("  %2d %-11s members %d -> %d  relief %4d  independent %3d/%3d days  steadily from day %s" % [h, hh.family, hh.members.size(), _living(w, h),
			int(relief.get(h, 0)), yes, flags.size(), str(from_day) if from_day <= flags.size() else "never"])
	var fi := first_income.values()
	fi.sort()
	var adults := 0
	for n: NPC in w.npcs:
		if n.role == "adult":
			adults += 1
	print("--- first income: %d of %d adults earned anything; median day %s; last day %s" % [fi.size(), adults,
		str(fi[fi.size() / 2]) if not fi.is_empty() else "-", str(fi.back()) if not fi.is_empty() else "-"])
	print("--- coins by job (alive), and food/wheat held by job")
	var by_job := {}
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		var k: String = n.job if n.job != "" else n.role
		if not by_job.has(k):
			by_job[k] = [0, 0, 0, 0, 0]
		by_job[k][0] += 1
		by_job[k][1] += n.coins
		by_job[k][2] += n.inv.count("wheat")
		by_job[k][3] += n.inv.count("pottage") + n.inv.count("roast_meat")
		by_job[k][4] += n.earned
	for k in by_job:
		print("  %-13s n=%3d coins=%5d earned=%6d wheat=%4d cooked=%4d" % [k, by_job[k][0], by_job[k][1], by_job[k][4], by_job[k][2], by_job[k][3]])
	print("--- ledger totals")
	var keys := w.stats.keys()
	keys.sort()
	for k in keys:
		print("  %s = %d" % [k, int(w.stats[k])])
	if csv != "":
		var fa := FileAccess.open(csv, FileAccess.WRITE)
		fa.store_string("\n".join(rows) + "\n")
	w.dispose()
	quit()


## Days of food a household can cover: its pantry (grain counted as cooked at home, 2 wheat ->
## 6 pottage) plus what its cash buys as grain (about 60 food points a coin).
func _food_days(w: World, h: int, cash: int) -> float:
	var p: Inventory = w.households[h].pantry
	var pts := p.count("pottage") * 40.0 + p.count("roast_meat") * 60.0 + p.count("ale") * 10.0 + p.count("wheat") * 120.0
	pts += cash * 60.0
	return pts / maxf(1.0, w.brain.household_day_food(h))          # members weighted by age, as in the game


## [median, 25th percentile, Gini] of household wealth.
func _distribution(v: Array) -> Array:
	if v.is_empty():
		return [0, 0, 0]
	var s := v.duplicate()
	s.sort()
	var total := 0.0
	var cum := 0.0
	for i in s.size():
		total += float(s[i])
		cum += float(s[i]) * (2 * (i + 1) - s.size() - 1)
	var gini := cum / (s.size() * total) if total > 0.0 else 0.0
	return [s[s.size() / 2], s[s.size() / 4], int(gini * 100)]


func _living(w: World, h: int) -> int:
	var c := 0
	for m in w.households[h].members:
		var o: NPC = w.npc(m)
		if o and o.alive:
			c += 1
	return c


func _cash(w: World, h: int) -> int:
	var c := 0
	for m in w.households[h].members:
		var o: NPC = w.npc(m)
		if o and o.alive:
			c += o.coins
	return c


func _food(w: World, h: int) -> float:
	var hh: Dictionary = w.households[h]
	var pts := 0.0
	for f in FOOD_POINTS:
		pts += hh.pantry.count(f) * float(FOOD_POINTS[f])
	return pts                         # the pantry: what a member carries is often stock for trade
