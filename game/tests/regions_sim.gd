extends SceneTree
## Diagnostic (SET-C-SIM): the five off-map settlements alone, with no village trading, for N days. Prints each
## settlement's population, coins by holder, food days and the time one step takes, then checks the books (audit) at every
## sample and stops with a FATAL line if a coin or good does not balance (SIM-01). Changes nothing in the repository.
## With --report it also keeps (SET-D) each business opening and closing by trade and day, and a count of generations by watching births:
## a person present at the start is generation 0, a baby is one more than the later of its couple's two (matched by settlement, birth day
## and sex, so approximate when two babies share both), and prints the facts at the end and at day 100 (read from the same run).
##   godot --headless --path game --script res://tests/regions_sim.gd -- --days 90 [--seed 1] [--every 10] [--report]

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
	var report := "--report" in args
	var events := {}                                       # settlement id -> [[day, "open"|"close", trade]]
	var known := {}                                        # settlement id -> business types last seen
	var gen := {}                                          # "id|born|sex" -> generation
	var gen_births := {}                                   # settlement id -> {generation: births}
	var seen_born := {}
	var founders := {}
	for o: OffMapSettlement in r.list:
		events[o.id] = []
		known[o.id] = o.biz.keys()
		gen_births[o.id] = {}
		founders[o.id] = o.population()
		for h in o.hh:
			for m in h.mem:
				gen["%s|%d|%d" % [o.id, int(m[0]), int(m[1])]] = 0
	var t_all := 0
	for d in days:
		var t := Time.get_ticks_usec()
		r.step_day(d)
		t_all += Time.get_ticks_usec() - t
		if report:
			for o: OffMapSettlement in r.list:
				for bt in o.biz.keys():
					if not known[o.id].has(bt):
						events[o.id].append([d + 1, "open", bt])
				for bt in known[o.id]:
					if not o.biz.has(bt):
						events[o.id].append([d + 1, "close", bt])
				known[o.id] = o.biz.keys()
				for h in o.hh:
					for m in h.mem:
						var key := "%s|%d|%d" % [o.id, int(m[0]), int(m[1])]
						if int(m[0]) == o.day and not seen_born.has(key + "|" + str(h.id)):
							seen_born[key + "|" + str(h.id)] = true
							var g := 0
							for x in h.mem:
								if int(x[2]) == 1:
									g = maxi(g, int(gen.get("%s|%d|%d" % [o.id, int(x[0]), int(x[1])], 0)))
							gen[key] = g + 1
							gen_births[o.id][g + 1] = int(gen_births[o.id].get(g + 1, 0)) + 1
			if d + 1 == 100 or d == days - 1:
				_report(r, d + 1, events, gen_births, founders)
		if d % every == every - 1 or d == days - 1:
			var bad := r.audit()
			print("day %d: %d people, %d coins%s" % [d + 1, r.population(), r.coins(), ("  FATAL " + bad) if bad != "" else ""])
			for s in r.summary():
				print("   %-9s pop %3d hh %2d hungry %2d hunger-deaths %2d born %3d age-deaths %3d formed %3d coins %5d (hh %4d tills %4d treasury %4d trader %4d) food %.1f d horses %d wage_short %d relief %d biz %d opened %d closed %d" % [s.id, s.population, s.households, s.hungry, s.deaths, s.births, s.age_deaths, s.households_formed, s.coins, s.household_coins, s.tills, s.treasury, s.trader, s.pantry_days, s.horses, s.wage_short, s.relief, s.businesses, s.biz_opened, s.biz_closed])
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


func _report(r: Regions, day: int, events: Dictionary, gen_births: Dictionary, founders: Dictionary) -> void:
	print("== report at day %d (%.1f calendar years of %d days)" % [day, float(day) / float(Life.year_days()), Life.year_days()])
	for o: OffMapSettlement in r.list:
		var opened := []
		var closed := []
		for e in events[o.id]:
			if int(e[0]) <= day:
				(opened if e[1] == "open" else closed).append("%s@%d" % [e[2], e[0]])
		var emp := {}
		var working := 0
		for h in o.hh:
			if h.alive:
				var k := str(h.trade)
				emp[k] = int(emp.get(k, 0)) + 1
				if k != "official":
					working += 1
		var born_alive := 0
		var founders_alive := 0
		var adult_born := 0
		for h in o.hh:
			if h.alive:
				for m in h.mem:
					if int(m[0]) < 0:
						founders_alive += 1
					else:
						born_alive += 1
						if o._age(m) >= float(Life.cfg().adolescent_until):
							adult_born += 1
		var sm: Dictionary = {}
		for s in r.summary():
			if s.id == o.id:
				sm = s
		print("  %-9s pop %3d (start %3d; start-people alive %3d, born in run and alive %3d, of them adult %3d) births %3d hunger-deaths %2d age-deaths %3d formed %3d hh %2d (working %2d)" % [o.id, sm.population, founders[o.id], founders_alive, born_alive, adult_born, sm.births, sm.deaths, sm.age_deaths, sm.households_formed, sm.households, working])
		print("            businesses %d, opened %s, closed %s; coins %d food %.1f d; households by trade %s" % [sm.businesses, ",".join(opened), ",".join(closed), sm.coins, sm.pantry_days, str(emp)])
		print("            births by generation (0 = people at the start) %s" % str(gen_births[o.id]))
