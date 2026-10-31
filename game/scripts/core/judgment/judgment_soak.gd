class_name JudgmentSoak
extends RefCounted
## SJD-G (Gate G, full soak and calibration; spec s.5.2, s.15.1, s.16): read-only measurements of a judgment store for long
## runs (game/tests/economy_sim.gd prints one `JUDGE {...}` line at each checkpoint). Nothing here changes the store or the
## world: no gossip is told, no dawn update applied, no ledger brought up to date. Values are read from the stored records;
## a ledger entry's fading part is decayed on a local copy to the store's day with the store's own integer steps
## (JudgmentStore._ldecay), so the distribution is what a decision reading it today would see. Meetings still queued (at
## most the current hour's) are not told first, so a checkpoint can lag them by an hour; the counts say how many.
##
## What it reports (spec s.5.2 "scores can inflate as event count grows"; s.15.1 "no duplicate moral postings, no runaway
## score inflation"):
##   n      record counts (facts, permanent facts kept, memories and permanent memories, contributions, ledger entries,
##          observers, trust pairs, history records, meetings still queued)
##   net    the effective NET (fading decayed + permanent, milli-points) over every ledger entry: percentiles, extremes,
##          signs, how many are 10/25/50 points or more from 0, and how many put the disposition (mid 50 + NET) at its
##          0 or 100 bound
##   life   the lifetime GOOD and BAD totals (never decayed: the spec's preserved historical totals): p99 and max
##   perm   entries with a permanent (murder/assault) part
##   cmax   the most contributions behind one entry (how many deeds one observer holds against one subject)
##   subj   per subject, the mean effective NET over their observers: lowest, highest, how many at -10 or below, and the
##          player's (id -2) when judged
##   twins  live facts identical in every field (type, day, revision, value, actors, victims, beneficiaries) to another,
##          by type: candidates for a duplicate moral posting, to be explained one by one (a legitimate repeat or a defect)
##   stats  the store's own counters (cumulative), timing its microseconds by part (cumulative)


static func metrics(j: JudgmentStore) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var out := {"d": j.day}
	# counts
	var nm := 0
	var nperm := 0
	for o in j.memories:
		var mem: Dictionary = j.memories[o]
		nm += mem.size()
		for ev in mem:
			if ((mem[ev] as PackedInt64Array)[JudgmentStore.M_FLAGS] & 1) == 1:
				nperm += 1
	var nc := 0
	for o in j.contrib:
		for ev in j.contrib[o]:
			nc += (j.contrib[o][ev] as PackedInt64Array).size() / 3
	var ntrust := 0
	for a in j.trust:
		ntrust += (j.trust[a] as Dictionary).size()
	var kept := 0
	for ev in j.facts:
		if j.kept_type((j.facts[ev] as PackedInt64Array)[JudgmentStore.F_TYPE]) or j._perm_refs.has(ev):
			kept += 1
	# ledgers, effective values
	var nets := PackedInt64Array()
	var lg := PackedInt64Array()
	var lb := PackedInt64Array()
	var sat := 0
	var perm_e := 0
	var perm_max := 0
	var cmax := 0
	var far := [0, 0, 0]
	var signs := [0, 0, 0]
	var by_subj := {}
	var mid := int(j.c("decision").get("disposition_mid", 50000))
	for o in j.ledgers:
		var rec: Array = j.ledgers[o]
		var subs: PackedInt64Array = rec[0]
		var v: PackedInt64Array = rec[1]
		for i in subs.size():
			var b := JudgmentStore.L_W * i
			var fg := v[b + 3]
			var fb := v[b + 4]
			if j._decay > 0:
				for k in maxi(0, j.day - v[b + 7]):
					if fg == 0 and fb == 0:
						break
					fg -= j._decay_step(fg)
					fb -= j._decay_step(fb)
			var n := fg + v[b + 5] - fb - v[b + 6]
			nets.append(n)
			lg.append(v[b])
			lb.append(v[b + 1])
			cmax = maxi(cmax, v[b + 2])
			if v[b + 5] != 0 or v[b + 6] != 0:
				perm_e += 1
				perm_max = maxi(perm_max, maxi(v[b + 5], v[b + 6]))
			if mid + n <= 0 or mid + n >= 100000:
				sat += 1
			signs[0 if n < 0 else (1 if n == 0 else 2)] += 1
			for q in 3:
				if absi(n) >= [10000, 25000, 50000][q]:
					far[q] += 1
			var s := int(subs[i])
			var row: Array = by_subj.get(s, [0, 0])
			row[0] += n
			row[1] += 1
			by_subj[s] = row
	nets.sort()
	lg.sort()
	lb.sort()
	var lo := 0
	var hi := 0
	var low_n := 0
	var first := true
	for s in by_subj:
		var m := int(by_subj[s][0]) / maxi(1, int(by_subj[s][1]))
		if first or m < lo:
			lo = m
		if first or m > hi:
			hi = m
		first = false
		if m <= -10000:
			low_n += 1
	var subj := {"n": by_subj.size(), "mean_min": lo, "mean_max": hi, "at_or_below_-10": low_n}
	if by_subj.has(-2):
		subj.player = [int(by_subj[-2][0]) / maxi(1, int(by_subj[-2][1])), int(by_subj[-2][1])]
	# identical live facts
	var seen := {}
	var twins := {}
	for ev in j.facts:
		var f: PackedInt64Array = j.facts[ev]
		if int(ev) >= JudgmentStore.NEWS_BASE:
			continue
		var key := str(f)
		if seen.has(key):
			var ty: String = j._types[f[JudgmentStore.F_TYPE]]
			twins[ty] = int(twins.get(ty, 0)) + 1
		else:
			seen[key] = true
	out.n = {"facts": j.facts.size(), "facts_kept_permanent": kept, "memories": nm, "memories_permanent": nperm, "contributions": nc,
		"ledger_entries": nets.size(), "observers": j.ledgers.size(), "trust": ntrust, "history": j.history.size(),
		"queued_meetings": j.gossip_queued()}
	out.net = {"p1": _pct(nets, 10), "p5": _pct(nets, 50), "p50": _pct(nets, 500), "p95": _pct(nets, 950), "p99": _pct(nets, 990),
		"min": nets[0] if not nets.is_empty() else 0, "max": nets[-1] if not nets.is_empty() else 0, "neg_zero_pos": signs,
		"abs_ge_10_25_50": far, "disposition_at_bound": sat}
	out.life = {"good_p99": _pct(lg, 990), "good_max": lg[-1] if not lg.is_empty() else 0, "bad_p99": _pct(lb, 990), "bad_max": lb[-1] if not lb.is_empty() else 0}
	out.perm = {"entries": perm_e, "max": perm_max}
	out.cmax = cmax
	out.subj = subj
	out.twins = twins
	out.stats = j.stats.duplicate()
	out.timing = j.timing.duplicate()
	out.us = Time.get_ticks_usec() - t0
	return out


## The value at `permille` of a sorted array (nearest rank), 0 when empty.
static func _pct(a: PackedInt64Array, permille: int) -> int:
	if a.is_empty():
		return 0
	return a[mini(a.size() - 1, (a.size() * permille) / 1000)]
