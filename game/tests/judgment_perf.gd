extends SceneTree
## PROSPECTIVE (Expansion 19, PROS-19; spec s.13): the judgment prototype's cost with large populations, no World. For
## each population it simulates days of synthetic social life tick by tick (60 ticks a game hour, economy_sim's step), as
## the game runs: households of four (kin), friends, significant events (thefts, help, assaults, gifts) seen by nearby
## people, hours spent together (gossip, 7:00 to 21:00, all of an hour's meetings at its first tick, as Relations.hour
## does), trade choices weighed by judgment (one after another through the working hours), and the daily update (begun at
## dawn, sliced over the hours). A tick is a frame: its cost is compared with the per-frame budget.
## Gossip "spread" queues the hour's meetings and tells gossip.pump_per_tick a tick (round 3, gossip.timing "hour");
## "now" tells them at once (rounds 1 and 2); both are run up to 500 people and must end in the same state. "scheduled"
## (gossip.timing "scheduled", a design option) tells each at its own minute of the hour: measured, different results.
## Two event rates: "live", what the live village produced with judgment on (7 events in 10 days for about 110 people,
## economy_sim.gd --judgment), and "stress", 0.5 a person a day (about 80 times more).
## It reports time per simulated day by part, the worst frame (median of the days' worst, and the worst of all), the
## daily update's worst tick, the cost of a weighed choice, memory, store sizes and save size and time, and checks the
## bounds the design promises (memories within capacity, facts within the horizon), the save round trip, spread = now,
## and determinism. It does not assert speed: the numbers are measurements for the budgets (docs/expansion19/DESIGN.md).
##   godot --headless --path game --script res://tests/judgment_perf.gd [-- --sizes 100,500,2000 --days 40 --rates live,stress]

var failures := 0
var checks := 0
const RATES := {"live": 0.0064, "stress": 0.5}   # significant events a person a day
const WITNESSES := 4
const MEETINGS_PER_PERSON := 3      # hours a day spent with someone (Relations.share pairs), 7:00 to 21:00
const DECISIONS_PER_PERSON := 2     # trade choices weighed by judgment a day, 7:00 to 18:00
const TYPES := ["theft", "help_minor", "assault", "gift", "trade_fair", "help_build"]
const TICKS := 60                   # ticks a game hour (economy_sim's step: one game minute)


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var sizes := [100, 500, 2000]
	var days := 40
	var rates := ["live", "stress"]
	if "--sizes" in args:
		sizes = Array(str(args[args.find("--sizes") + 1]).split(",")).map(func(x): return int(x))
	if "--days" in args:
		days = int(args[args.find("--days") + 1])
	if "--rates" in args:
		rates = Array(str(args[args.find("--rates") + 1]).split(","))
	var rows := []
	for rate in rates:
		for n in sizes:
			var r := run(n, days, str(rate), true, "spread")
			rows.append(r)
			if n <= 500:
				var now := run(n, days, str(rate), false, "now")
				rows.append(now)
				check(now.hash == r.hash, "%s, %d people: gossip spread over ticks ends in the same state as gossip told at once" % [rate, n])
				var sch := run(n, days, str(rate), false, "scheduled")
				rows.append(sch)
				print("%s, %d people: scheduled timing (a design option) differs from the hour timing by design: %s" % [rate, n, "same state" if sch.hash == r.hash else "different state"])
	var a := run(sizes[0], mini(days, 10), str(rates[-1]), false)
	var b := run(sizes[0], mini(days, 10), str(rates[-1]), false)
	check(a.hash == b.hash, "determinism: the same %d-person run twice ends in the same state hash" % sizes[0])
	print("\nRESULTS (ms per simulated day, averaged over the last half of %d days; a frame is one tick, %d a game hour; memory in MB)" % [days, TICKS])
	print("rate   | people | gossip    | ms/day | events | gossip | decisions | update | frame p99 / p99.9 / worst | idle tick worst | update worst tick | us/choice | memories | ledgers | mem MB | save KB | save ms | load ms")
	for r in rows:
		print("%-6s | %6d | %-9s | %6.1f | %6.2f | %6.2f | %9.2f | %6.2f | %5.2f / %5.2f / %6.2f | %15.2f | %17.2f | %9.1f | %8d | %7d | %6.1f | %7.0f | %7.1f | %7.1f" % [r.rate, r.n, r.gossip,
			r.total_ms, r.ev_ms, r.gossip_ms, r.dec_ms, r.dawn_ms, r.p99_frame_ms, r.p999_frame_ms, r.max_frame_ms, r.idle_max_ms, r.max_update_ms, r.us_per_choice,
			r.counts.memories, r.counts.ledgers, r.mem_mb, r.save_kb, r.save_ms, r.load_ms])
	print("JSON " + JSON.stringify(rows))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## One population of `n` for `days` days at event rate `rate`. Households of four are kin; each person has two friends
## in the next household; events and meetings fall among neighbours (a ring of clusters of 20), as people meet where
## they live and work. All choices come from JudgmentMath's seeded hash. Each game hour is TICKS ticks (economy_sim's
## step: a game minute); a tick is one frame. Tick 0 has the daily update's slice, the hour's events and the hour's
## meetings (Relations.hour runs them all at once): told at once (`gossip` "now", as rounds 1 and 2) or queued and told
## gossip.pump_per_tick a tick ("spread"). The hour's trade choices fall one after another over its ticks, as villagers
## decide.
func run(n: int, days: int, rate: String, report: bool, gossip := "spread") -> Dictionary:
	var social := JudgmentSocial.new()
	for i in n:
		var h := i / 4 * 4
		for k in range(h, mini(n, h + 4)):
			if k != i:
				social.set_kin(i, k)
		social.set_friends(i, (i + 4) % n)
		social.set_friends(i, (i + 5) % n)
	var mem0 := OS.get_static_memory_usage()
	var config := JudgmentStore.default_cfg()
	if gossip == "scheduled":
		config.gossip.timing = "scheduled"
	var j := JudgmentStore.new(config, social, 11)
	var cfg := j.cfg
	var sliced := j.has_method("begin_day")
	var spread := gossip != "now" and j.has_method("meet_hourly")
	var per_day := float(n) * float(RATES[rate])
	var sums := {"ev": 0, "gossip": 0, "dec": 0, "dawn": 0}
	var measured := 0
	var max_hour := 0
	var max_update := 0
	var max_frame := 0
	var choices := 0
	var day_update_max := []
	var day_frame_max := []
	var worst_parts := [0, 0, 0, 0]         # the worst frame's update, events, gossip, decisions (us)
	var frames := PackedInt64Array()        # every measured tick's cost (us): percentiles
	var idle_max := 0                       # the worst tick that did no judgment work at all: the machine's noise floor
	var max_tick_tellings := 0              # the most tellings in one tick, and the most beliefs taken in (deterministic
	var max_tick_beliefs := 0               # workload counts, free of the shared machine's timing noise)
	var ev_count := 0
	for d in days:
		var due := int(floor(per_day * (d + 1))) - int(floor(per_day * d))     # a fractional rate spread evenly over the days
		var part := {"ev": 0, "gossip": 0, "dec": 0, "dawn": 0}
		var today_max := 0
		var today_frame := 0
		for hr in 24:
			var hour_us := 0
			var dec_from := n * (hr - 7) / 11 if hr >= 7 and hr < 18 else 0
			var dec_to := n * (hr - 6) / 11 if hr >= 7 and hr < 18 else 0
			for tick in TICKS:
				var tell0 := int(j.stats.get("tellings", 0))
				var bel0 := int(j.stats.get("beliefs", 0))
				var t0 := Time.get_ticks_usec()
				if tick == 0:
					if hr == 6:
						if sliced:
							j.call("begin_day", d)
						else:
							j.advance_day(d)
					if sliced:
						j.call("dawn_hour")
				var t1 := Time.get_ticks_usec()
				if tick == 0:
					for e in range(due * hr / 24, due * (hr + 1) / 24):
						var actor := JudgmentMath.hash_ints([d, e, 1]) % n
						var other := (actor + 1 + JudgmentMath.hash_ints([d, e, 2]) % 19) % n
						var type: String = TYPES[JudgmentMath.hash_ints([d, e, 3]) % TYPES.size()]
						var bad := str(j.definition(type).polarity) == "BAD"
						var ev := j.publish(type, [actor], [other] if bad else [], [] if bad else [other])
						var seen := []
						for k in WITNESSES:
							seen.append((other + 1 + JudgmentMath.hash_ints([d, e, 4, k]) % 19) % n)
						j.observe_all(ev, seen)
						ev_count += 1
				var t2 := Time.get_ticks_usec()
				if tick == 0 and hr >= 7 and hr < 21:
					for p in range(n * (hr - 7) / 14, n * (hr - 6) / 14):
						for k in MEETINGS_PER_PERSON:
							var q := (p + 1 + JudgmentMath.hash_ints([d, p, 5, k]) % 19) % n
							if spread:
								j.call("meet_hourly", p, q, d * 1440 + hr * 60)
							else:
								j.meet(p, q)
				if spread:
					j.call("gossip_tick", d * 1440 + hr * 60 + tick)
				var t3 := Time.get_ticks_usec()
				for p in range(dec_from + (dec_to - dec_from) * tick / TICKS, dec_from + (dec_to - dec_from) * (tick + 1) / TICKS):
					for k in DECISIONS_PER_PERSON:
						var cands := []
						for c in 3:
							var who := (p + 1 + JudgmentMath.hash_ints([d, p, 6, k, c]) % 19) % n
							cands.append({"id": who, "counterparty": who, "factors": {"necessity": 60000, "affordability": 50000 + c * 10000, "urgency": 40000}})
						JudgmentWeighting.choose(j, cfg, p, "trade_buy", cands)
						if d >= days / 2:
							choices += 1
				var t4 := Time.get_ticks_usec()
				part.dawn += t1 - t0
				part.ev += t2 - t1
				part.gossip += t3 - t2
				part.dec += t4 - t3
				hour_us += t4 - t0
				if d >= days / 2:
					max_update = maxi(max_update, t1 - t0)
					today_max = maxi(today_max, t1 - t0)
					frames.append(t4 - t0)
					max_tick_tellings = maxi(max_tick_tellings, int(j.stats.get("tellings", 0)) - tell0)
					max_tick_beliefs = maxi(max_tick_beliefs, int(j.stats.get("beliefs", 0)) - bel0)
					var busy: bool = (tick == 0) or (spread and j.call("gossip_queued") > 0) or dec_to > dec_from
					if not busy:
						idle_max = maxi(idle_max, t4 - t0)
					if t4 - t0 > max_frame:
						worst_parts = [t1 - t0, t2 - t1, t3 - t2, t4 - t3]
					max_frame = maxi(max_frame, t4 - t0)
					today_frame = maxi(today_frame, t4 - t0)
			if d >= days / 2:
				max_hour = maxi(max_hour, hour_us)
		if d >= days / 2:
			measured += 1
			day_update_max.append(today_max)
			day_frame_max.append(today_frame)
			for k in part:
				sums[k] += part[k]
	if spread:
		j.call("flush_gossip")
	if sliced:
		j.call("finish_dawn")
	var mem_mb := float(OS.get_static_memory_usage() - mem0) / 1048576.0
	var counts := j.counts()
	var cap := int(cfg.memory.capacity)
	var over := 0
	var permanent := 0
	for o in j.memories:
		var ordinary := 0
		for ev in j.memories[o]:
			if (j.memories[o][ev][JudgmentStore.M_FLAGS] & 1) == 0:
				ordinary += 1
			else:
				permanent += 1
		if ordinary > cap:
			over += 1
	var old_ordinary := 0                   # facts past the horizon that are not permanent records (Q11): must be none
	for ev in j.facts:
		if int(j.facts[ev][JudgmentStore.F_DAY]) < days - 1 - int(cfg.memory.horizon_days) and j._perm[j.facts[ev][JudgmentStore.F_TYPE]] == 0 and not j._perm_refs.has(ev):
			old_ordinary += 1
	var ts := Time.get_ticks_usec()
	var text := JSON.stringify(j.to_dict())
	var save_us := Time.get_ticks_usec() - ts
	ts = Time.get_ticks_usec()
	var j2 := JudgmentStore.new(cfg, social, 11)
	var err := j2.load_dict(JSON.parse_string(text))
	var load_us := Time.get_ticks_usec() - ts
	var h := j.state_hash()
	if report:
		check(over == 0, "%s, %d people: nobody holds more than %d ordinary memories (%d permanent memories besides, Q11)" % [rate, n, cap, permanent])
		check(old_ordinary == 0, "%s, %d people: every fact older than the horizon is a permanent record (%d facts in all)" % [rate, n, int(counts.facts)])
		check(err == "" and j2.state_hash() == h, "%s, %d people: the save loads back to the same state" % [rate, n])
		print("%s, %d people: %d events; %s; stats %s" % [rate, n, ev_count, JSON.stringify(counts), JSON.stringify(j.stats)])
		print("%s, %d people: time (us) %s" % [rate, n, JSON.stringify(j.timing)])
	var ms := func(us: int) -> float:
		return float(us) / 1000.0 / maxf(1.0, float(measured))
	var row := {"permanent_memories": permanent, "rate": rate, "n": n, "days": days, "events_day": int(round(per_day)), "ev_ms": ms.call(sums.ev), "gossip_ms": ms.call(sums.gossip),
		"dec_ms": ms.call(sums.dec), "dawn_ms": ms.call(sums.dawn), "max_hour_ms": float(max_hour) / 1000.0, "max_update_ms": float(max_update) / 1000.0, "median_update_max_ms": _median(day_update_max) / 1000.0,
		"max_frame_ms": float(max_frame) / 1000.0, "median_frame_max_ms": _median(day_frame_max) / 1000.0, "gossip": gossip if spread else "now", "worst_frame_parts_us": worst_parts,
		"max_tick_tellings": max_tick_tellings, "max_tick_beliefs": max_tick_beliefs,
		"p99_frame_ms": _pct(frames, 0.99) / 1000.0, "p999_frame_ms": _pct(frames, 0.999) / 1000.0, "idle_max_ms": float(idle_max) / 1000.0,
		"us_per_choice": float(sums.dec) / maxf(1.0, float(choices)), "sliced": sliced,
		"counts": counts, "mem_mb": mem_mb, "save_kb": float(text.length()) / 1024.0, "save_ms": float(save_us) / 1000.0,
		"load_ms": float(load_us) / 1000.0, "hash": h}
	row.total_ms = float(row.ev_ms) + float(row.gossip_ms) + float(row.dec_ms) + float(row.dawn_ms)
	return row


static func _median(xs: Array) -> float:
	if xs.is_empty():
		return 0.0
	var v := xs.duplicate()
	v.sort()
	return float(v[v.size() / 2])


static func _pct(xs: PackedInt64Array, q: float) -> float:
	if xs.is_empty():
		return 0.0
	var v := xs.duplicate()
	v.sort()
	return float(v[mini(v.size() - 1, int(q * v.size()))])
