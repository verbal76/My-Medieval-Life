extends SceneTree
## Diagnostic (SET-C-SIM): the five off-map settlements alone, with no village trading, for N days. Prints each
## settlement's population, coins by holder, food days and the time one step takes, then checks the books (audit) at every
## sample and stops with a FATAL line if a coin or good does not balance (SIM-01). Changes nothing in the repository.
##   godot --headless --path game --script res://tests/regions_sim.gd -- --days 90 [--seed 1] [--every 10]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: String) -> String:
		return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback
	var days := int(arg.call("--days", "90"))
	var seed := int(arg.call("--seed", "1"))
	var every := maxi(1, int(arg.call("--every", "10")))
	GameData.ensure()
	OffMapSettlement.profile = "--profile" in args
	var r := Regions.create(seed)
	print("founded: %d people, %d coins" % [r.population(), r.coins()])
	var t_all := 0
	for d in days:
		var t := Time.get_ticks_usec()
		r.step_day(d)
		t_all += Time.get_ticks_usec() - t
		if d % every == every - 1 or d == days - 1:
			var bad := r.audit()
			print("day %d: %d people, %d coins%s" % [d + 1, r.population(), r.coins(), ("  FATAL " + bad) if bad != "" else ""])
			for s in r.summary():
				print("   %-9s pop %3d hh %2d hungry %2d deaths %2d coins %5d (hh %4d tills %4d treasury %4d trader %4d) food %.1f d horses %d wage_short %d relief %d" % [s.id, s.population, s.households, s.hungry, s.deaths, s.coins, s.household_coins, s.tills, s.treasury, s.trader, s.pantry_days, s.horses, s.wage_short, s.relief])
			var detail := str(arg.call("--detail", ""))
			if detail != "":
				var o: OffMapSettlement = r.by_id[detail]
				for bt in o.biz:
					var b: Dictionary = o.biz[bt]
					print("     %-9s workers %d till %5d paid/worker/day %.1f stock %s" % [bt, b.workers.size(), b.till, float(b.paid) / maxf(1.0, float(b.workers.size())) / float(days), str(b.stock)])
				print("     prices ", o.prices.keys().map(func(k): return "%s=%.1f" % [k, o.prices[k]]))
				print("     flows used ", o.flows.used, " produced ", o.flows.produced)
				print("     unmet ", o.flows.unmet)
				print("     treasury ", o.gov)
				var f: Dictionary = o.flows
				print("     treasury per day: tolls %.1f, household tax %.1f, business tax %.1f; officials %.1f, day labour %.1f; wages paid %.1f, wage short %.1f" % [float(f.tolls) / days, float(f.tax_households) / days, float(f.tax_businesses) / days, float(f.official_pay) / days, float(f.day_labour) / days, float(f.wages_paid) / days, float(f.wage_short) / days])
				var line := ""
				for h in o.hh:
					line += "%s:%d%s/%d/%dh  " % [str(h.trade).substr(0, 4), int(h.adults) + int(h.children), "" if h.alive else "X", int(h.coins), int(h.hungry)]
				print("     households ", line)
			if bad != "":
				quit(1)
				return
	print("step cost: %.3f ms a day for all five (%d days)" % [float(t_all) / 1000.0 / float(days), days])
	if OffMapSettlement.profile:
		print("phases (ms a day): ", OffMapSettlement.laps.keys().map(func(k): return "%s %.2f" % [k, float(OffMapSettlement.laps[k]) / 1000.0 / float(days)]))
	quit(0)
