extends SceneTree
## PROSPECTIVE (Expansion 19, PROS-19; spec s.13): the judgment prototype's cost with large populations, no World. For
## 100, 500 and 2000 people it simulates days of synthetic social life: households of four (kin), friends, a stream of
## significant events (thefts, help, assaults, gifts) seen by nearby people, hours spent together (gossip), trade
## choices weighed by judgment, and the dawn (fading, forgetting, expiry). It reports time per simulated day by part,
## the dawn's single-call cost (a frame hitch), memory, store sizes and save size and time, and checks the bounds the
## design promises (memories per person within capacity, facts within the horizon) and determinism (same hash twice).
## It does not assert speed: the numbers are measurements for the proposed budgets (docs/expansion19/PROGRESS.md).
##   godot --headless --path game --script res://tests/judgment_perf.gd [-- --sizes 100,500,2000 --days 40]

var failures := 0
var checks := 0
const EVENTS_PER_PERSON := 0.5      # significant events a person a day (generous: today's village sees far fewer)
const WITNESSES := 4
const MEETINGS_PER_PERSON := 3      # hours a day spent with someone (Relations.share pairs)
const DECISIONS_PER_PERSON := 2     # trade choices weighed by judgment a day
const TYPES := ["theft", "help_minor", "assault", "gift", "trade_fair", "help_build"]


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
	if "--sizes" in args:
		sizes = Array(str(args[args.find("--sizes") + 1]).split(",")).map(func(x): return int(x))
	if "--days" in args:
		days = int(args[args.find("--days") + 1])
	var rows := []
	for n in sizes:
		rows.append(run(n, days, true))
	var again := run(sizes[0], mini(days, 10), false)
	var first := run(sizes[0], mini(days, 10), false)
	check(again.hash == first.hash, "determinism: the same %d-person run twice ends in the same state hash" % sizes[0])
	print("\nRESULTS (ms per simulated day, averaged over the last half of %d days; memory in MB)" % days)
	print("people | events/day | total ms/day | events | gossip | decisions | dawn (one call) | facts | memories | contributions | ledgers | mem MB | save KB | save ms | load ms")
	for r in rows:
		print("%6d | %10d | %12.2f | %6.2f | %6.2f | %9.2f | %15.2f | %5d | %8d | %13d | %7d | %6.1f | %7.0f | %7.1f | %7.1f" % [r.n, r.events_day,
			r.total_ms, r.ev_ms, r.gossip_ms, r.dec_ms, r.dawn_ms, r.counts.facts, r.counts.memories, r.counts.contributions, r.counts.ledgers,
			r.mem_mb, r.save_kb, r.save_ms, r.load_ms])
	print("JSON " + JSON.stringify(rows))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## One population of `n` for `days` days. Households of four are kin; each person has two friends in the next
## household; events and meetings fall among neighbours (a ring of clusters of 20), as people meet where they live
## and work. All choices come from JudgmentMath's seeded hash.
func run(n: int, days: int, report: bool) -> Dictionary:
	var social := JudgmentSocial.new()
	for i in n:
		var h := i / 4 * 4
		for k in range(h, mini(n, h + 4)):
			if k != i:
				social.set_kin(i, k)
		social.set_friends(i, (i + 4) % n)
		social.set_friends(i, (i + 5) % n)
	var mem0 := OS.get_static_memory_usage()
	var j := JudgmentStore.new(JudgmentStore.default_cfg(), social, 11)
	var cfg := j.cfg
	var events_day := int(n * EVENTS_PER_PERSON)
	var sums := {"ev": 0, "gossip": 0, "dec": 0, "dawn": 0}
	var measured := 0
	var dawn_max := 0
	for d in days:
		var t0 := Time.get_ticks_usec()
		j.advance_day(d)
		var t1 := Time.get_ticks_usec()
		for e in events_day:
			var actor := JudgmentMath.hash_ints([d, e, 1]) % n
			var other := (actor + 1 + JudgmentMath.hash_ints([d, e, 2]) % 19) % n
			var type: String = TYPES[JudgmentMath.hash_ints([d, e, 3]) % TYPES.size()]
			var bad := str(j.definition(type).polarity) == "BAD"
			var ev := j.publish(type, [actor], [other] if bad else [], [] if bad else [other])
			var seen := []
			for k in WITNESSES:
				seen.append((other + 1 + JudgmentMath.hash_ints([d, e, 4, k]) % 19) % n)
			j.observe_all(ev, seen)
		var t2 := Time.get_ticks_usec()
		for p in n:
			for k in MEETINGS_PER_PERSON:
				j.meet(p, (p + 1 + JudgmentMath.hash_ints([d, p, 5, k]) % 19) % n)
		var t3 := Time.get_ticks_usec()
		for p in n:
			for k in DECISIONS_PER_PERSON:
				var cands := []
				for c in 3:
					var who := (p + 1 + JudgmentMath.hash_ints([d, p, 6, k, c]) % 19) % n
					cands.append({"id": who, "counterparty": who, "factors": {"necessity": 60000, "affordability": 50000 + c * 10000, "urgency": 40000}})
				JudgmentWeighting.choose(j, cfg, p, "trade_buy", cands)
		var t4 := Time.get_ticks_usec()
		dawn_max = maxi(dawn_max, t1 - t0)
		if d >= days / 2:
			measured += 1
			sums.dawn += t1 - t0
			sums.ev += t2 - t1
			sums.gossip += t3 - t2
			sums.dec += t4 - t3
	var mem_mb := float(OS.get_static_memory_usage() - mem0) / 1048576.0
	var counts := j.counts()
	var cap := int(cfg.memory.capacity)
	var over := 0
	for o in j.memories:
		if (j.memories[o] as Dictionary).size() > cap:
			over += 1
	var ts := Time.get_ticks_usec()
	var text := JSON.stringify(j.to_dict())
	var save_us := Time.get_ticks_usec() - ts
	ts = Time.get_ticks_usec()
	var j2 := JudgmentStore.new(cfg, social, 11)
	var err := j2.load_dict(JSON.parse_string(text))
	var load_us := Time.get_ticks_usec() - ts
	var h := j.state_hash()
	if report:
		check(over == 0, "%d people: nobody holds more than %d memories" % [n, cap])
		check(counts.facts <= events_day * (int(cfg.memory.horizon_days) + 1), "%d people: facts stay within the horizon (%d)" % [n, counts.facts])
		check(err == "" and j2.state_hash() == h, "%d people: the save loads back to the same state" % n)
		print("%d people: %s; stats %s" % [n, JSON.stringify(counts), JSON.stringify(j.stats)])
	var ms := func(us: int) -> float:
		return float(us) / 1000.0 / maxf(1.0, float(measured))
	var row := {"n": n, "days": days, "events_day": events_day, "ev_ms": ms.call(sums.ev), "gossip_ms": ms.call(sums.gossip),
		"dec_ms": ms.call(sums.dec), "dawn_ms": ms.call(sums.dawn), "dawn_max_ms": float(dawn_max) / 1000.0,
		"counts": counts, "mem_mb": mem_mb, "save_kb": float(text.length()) / 1024.0, "save_ms": float(save_us) / 1000.0,
		"load_ms": float(load_us) / 1000.0, "hash": h}
	row.total_ms = float(row.ev_ms) + float(row.gossip_ms) + float(row.dec_ms) + float(row.dawn_ms)
	return row
