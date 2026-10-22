extends SceneTree
## PROSPECTIVE harness (Expansion 18, SET-C caravan replacement plan and Q18-11 curve analysis; PROS-18): runs the live
## village with the CURRENT caravan (since ECON-P1.3 the traders of the five neighbouring settlements, Regions; the CARAVAN-TMP 30-coin daily allowance is gone) and beside it, in shadow, asks
## what genuine regional trade would have done at each caravan visit: three finite off-map settlements
## (tests/fixtures/x18_regions.json) with their own stocks, needs, production, reserves and closed purses, trading with
## read-only snapshots of the village's parties (owner Q18-10: anyone may buy) through RegionalMarket and TradeRoutes.
## The shadow never writes to the World (checked).
##
## Shadow SETS run side by side over the same village, each with its own copy of the regions:
##   --profiles a,b,...  one set per capability profile (analysis only; default "neutral", the active one): the regions'
##                       production and carters' pay take that profile's multipliers (never creating raw materials)
##   --local             one more set, "neutral+local": the village's parties buy from each other first (the local
##                       market), so only what the village cannot meet itself is sought abroad (deficit analysis)
## Each set reports coins in and out, unmet need by reason, and a decomposition of the village's balance (purchases by
## item and buyer kind, goods bought abroad that the village held for sale, surplus nobody abroad wanted, carriage).
##   godot --headless --path game --script res://tests/caravan_compare.gd -- [--days 10] [--seed 1] [--income 0]
##       [--profiles neutral,owner_candidate] [--local] [--out f.json]
## Integrity checks (pass/fail): the shadow leaves the World untouched; every set's regions' books balance and every
## shadow transfer is matched; shadow trade conserves coins; nothing is delivered free; the live currency balances.
## Economic outcomes are measured and printed, never pass/fail (WDR-022).

const STEP := 0.5

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: String) -> String:
		return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback
	var days := int(arg.call("--days", "10"))
	var seed := int(arg.call("--seed", "1"))
	var income := int(arg.call("--income", "0"))
	var out := str(arg.call("--out", ""))
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/x18_regions.json"))
	var links := []
	for r in fx.regions:
		links.append([SettlementFacts.VILLAGE, str(r.id), int(r.link.tiles), r.link.mix])
	var sets := []
	for name in str(arg.call("--profiles", "neutral")).split(","):
		sets.append(_new_set(fx, income, name, false))
	if "--local" in args:
		sets.append(_new_set(fx, income, "neutral", true))
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var every := maxi(1, int(GameData.b("caravan_every_days")))
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	var coins0 := w.total_coins()
	var stats_start := w.stats.duplicate()
	var stats_prev := w.stats.duplicate()
	var prev_day := 0
	var tot := {"actual_in": 0, "actual_out": 0, "allowance": 0, "visits": 0}
	var rows := []
	var untouched_checked := false
	print("day | caravan: coins in / out, allowance | shadow sets: coins in / out")
	for day in days:
		var visit := day % every == 1
		var shadows := []
		if visit:
			var needs := SettlementReport.measured_use(stats_prev, w.stats, float(maxi(1, day - prev_day)))
			stats_prev = w.stats.duplicate()
			prev_day = day
			var before := ""
			if not untouched_checked:
				before = JSON.stringify(w.to_dict())
			for s in sets:
				shadows.append(_shadow(w, needs, s, links, day))
			if not untouched_checked:
				check(JSON.stringify(w.to_dict()) == before, "the shadow regional trade leaves the World untouched")
				untouched_checked = true
		var s0 := w.stats.duplicate()
		for i in per_day:
			w.update(STEP)
			w.player.hunger = 100.0                      # the idle player is fed, as in economy_sim
		for s in sets:
			for r: SettlementLedger in s.regions:
				r.tick(day)
		if not visit:
			continue
		var d := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(s0.get(k, 0))
		var c_in: int = d.call("caravan_coins_in")
		var c_out: int = d.call("caravan_coins_out")
		var allowance := 0                              # the allowance is gone (ECON-P1.3): the traders pay with the coins in their tills
		tot.actual_in += c_in
		tot.actual_out += c_out
		tot.allowance += allowance
		tot.visits += 1
		rows.append({"day": day, "actual_in": c_in, "actual_out": c_out, "allowance": allowance,
			"exported": _prefixed(w.stats, s0, "exported_"), "imported": _prefixed(w.stats, s0, "imported_"),
			"shadows": shadows.map(func(x): return {"set": x.set, "in": x.coins_in, "out": x.coins_out})})
		var line := "%3d | %4d / %4d, %4d |" % [day, c_in, c_out, allowance]
		for x in shadows:
			line += " %s %d / %d;" % [x.set, int(x.coins_in), int(x.coins_out)]
		print(line)
	# integrity
	for s in sets:
		for r: SettlementLedger in s.regions:
			check(r.balanced() == "", "%s: %s's books balance over the run (%s)" % [s.name, r.id, r.balanced()])
	var dd := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(stats_start.get(k, 0))
	var leak: int = w.total_coins() - coins0 - (dd.call("caravan_coins_in") + dd.call("newcomer_coins_in")) + dd.call("caravan_coins_out")
	check(leak == 0, "the live village's currency balances over %d days with the caravan unchanged (leak %d)" % [days, leak])
	print("TOTALS over %d caravan visits (%d days, seed %d, regional income %d a day):" % [tot.visits, days, seed, income])
	print("  current caravan: village coins in %d, out %d, net %+d; coins created by the allowance %d" % [tot.actual_in, tot.actual_out, tot.actual_in - tot.actual_out, tot.allowance])
	var start_purses: int = (fx.regions as Array).reduce(func(a, r): return a + int(r.coins), 0) + income * days * (fx.regions as Array).size()
	var report := []
	for s in sets:
		var t: Dictionary = s.tot
		print("  set %s: village coins in %d, out %d, net %+d; coins created 0; region purses %d of %d" % [s.name, t.in, t.out, int(t.in) - int(t.out),
			s.regions.reduce(func(a, r): return a + r.coins, 0), start_purses])
		print("    purchases by buyer kind %s; by item (top) %s" % [str(t.by_kind), str(_top(t.by_item, 6))])
		print("    sales abroad by item (top) %s" % str(_top(t.sold_item, 6)))
		print("    bought abroad though the village held it for sale: %d coins %s" % [int(t.local_avail), str(_top(t.local_avail_item, 4))])
		print("    village surplus no region wanted (value at price): %d coins %s" % [int(t.no_outlet), str(_top(t.no_outlet_item, 4))])
		print("    village unmet by reason (units, value) %s; region unmet %s" % [str(t.unmet_village), str(t.unmet_regions)])
		print("    carriage fees paid %d; trip-days of buyers' own collection %.1f; households short of funds (visit-household pairs) %d of %d" % [int(t.fees), float(t.trip_days), int(t.hh_funds), int(t.hh_seen)])
		report.append({"set": s.name, "profile": s.profile, "local": s.local, "totals": t,
			"purses": s.regions.map(func(r): return r.coins), "reserves": s.regions.map(func(r): return r.reserves)})
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify({"format": "x18-caravan-compare/1", "seed": seed, "days": days, "income": income,
			"caravan": tot, "sets": report, "visits": rows}, "  "))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _new_set(fx: Dictionary, income: int, profile: String, local: bool) -> Dictionary:
	var regions := []
	for r in fx.regions:
		var l := SettlementLedger.make(r)
		l.income_per_day = income
		l.profile = profile
		regions.append(l)
	return {"name": profile + ("+local" if local else ""), "profile": profile, "local": local, "regions": regions,
		"tot": {"in": 0, "out": 0, "by_kind": {}, "by_item": {}, "sold_item": {}, "local_avail": 0, "local_avail_item": {},
			"no_outlet": 0, "no_outlet_item": {}, "unmet_village": {}, "unmet_regions": {}, "fees": 0, "trip_days": 0.0,
			"hh_funds": 0, "hh_seen": 0, "local_trade": 0}}


## One visit's genuine trade for one shadow set: the village as fresh read-only snapshots of its parties (owner Q18-10:
## anyone may buy -- traders, households, villagers, the manor -- each fetching what it buys itself; no carter is offered,
## Q18-12), with its measured daily food use; the set's regions as they stand (their changes persist within the set).
func _shadow(w: World, needs: Dictionary, s: Dictionary, links: Array, day: int) -> Dictionary:
	var vs := SettlementReport.parties(w, needs)
	var ls: Array = vs + s.regions
	var coins_before := 0
	for l: SettlementLedger in ls:
		coins_before += l.coins
	var village := {}
	var vsupply := {}            # the village's goods for sale at the start of the visit
	for l: SettlementLedger in vs:
		village[l.id] = l
		for item in l.stock.items:
			var n := RegionalMarket.supply(l, item)
			if n > 0:
				vsupply[item] = int(vsupply.get(item, 0)) + n
	var routes := TradeRoutes.table(ls, links)
	var p := RegionalMarket.plan(ls, routes, [], bool(s.local))
	var r := RegionalMarket.execute(p, ls, day)
	var coins_after := 0
	for l: SettlementLedger in ls:
		coins_after += l.coins
	check(coins_after == coins_before, "%s day %d: shadow trade conserves coins (%d)" % [s.name, day, coins_before])
	check(RegionalMarket.matched(ls, day) == "", "%s day %d: every shadow transfer is matched" % [s.name, day])
	check(r.done.all(func(l): return l.carriage in ["self", "local"] or int(l.fee_total) > 0), "%s day %d: nothing is delivered free" % [s.name, day])
	var t: Dictionary = s.tot
	var out := {"set": s.name, "coins_in": 0, "coins_out": 0}
	var sold := {}
	var avail_left := vsupply.duplicate()
	for line in r.done:
		var from_v := village.has(line.seller)
		var to_v := village.has(line.buyer)
		if from_v and to_v:
			t.local_trade += int(line.total)
			avail_left[line.item] = int(avail_left.get(line.item, 0)) - int(line.units)
			continue
		if from_v:
			out.coins_in += int(line.total) + int(line.fee_total)
			sold[line.item] = int(sold.get(line.item, 0)) + int(line.units)
			t.sold_item[line.item] = int(t.sold_item.get(line.item, 0)) + int(line.total)
			avail_left[line.item] = int(avail_left.get(line.item, 0)) - int(line.units)
		elif to_v:
			var cost := int(line.total) + int(line.fee_total)
			out.coins_out += cost
			var k: String = (village[line.buyer] as SettlementLedger).kind
			t.by_kind[k] = int(t.by_kind.get(k, 0)) + cost
			t.by_item[line.item] = int(t.by_item.get(line.item, 0)) + cost
			t.fees += int(line.fee_total)
			t.trip_days += float(line.days)
	# bought abroad though the village held it for sale (only meaningful without the local market)
	for line in r.done:
		if village.has(line.buyer) and not village.has(line.seller):
			var held := mini(int(line.units), maxi(0, int(avail_left.get(line.item, 0))))
			if held > 0:
				avail_left[line.item] = int(avail_left[line.item]) - held
				t.local_avail += held * int(line.unit_price)
				t.local_avail_item[line.item] = int(t.local_avail_item.get(line.item, 0)) + held * int(line.unit_price)
	# surplus no region wanted: what the village still had for sale after the visit, at price
	for item in vsupply:
		var left := int(vsupply[item]) - int(sold.get(item, 0))
		if left > 0:
			t.no_outlet += left * RegionalMarket.ask(item)
			t.no_outlet_item[item] = int(t.no_outlet_item.get(item, 0)) + left * RegionalMarket.ask(item)
	var hh_short := {}
	for u in p.unmet:
		if village.has(u.buyer):
			var key := str(u.reason)
			var row: Array = t.unmet_village.get(key, [0, 0])
			t.unmet_village[key] = [int(row[0]) + int(u.units), int(row[1]) + int(u.units) * RegionalMarket.ask(str(u.item))]
			if key == "funds" and (village[u.buyer] as SettlementLedger).kind == "household":
				hh_short[u.buyer] = true
		else:
			t.unmet_regions[str(u.reason)] = int(t.unmet_regions.get(str(u.reason), 0)) + int(u.units)
	t.hh_funds += hh_short.size()
	t.hh_seen += vs.filter(func(l): return l.kind == "household").size()
	t.in += int(out.coins_in)
	t.out += int(out.coins_out)
	return out


func _top(d: Dictionary, n: int) -> Dictionary:
	var ks := d.keys()
	ks.sort_custom(func(a, b): return int(d[a]) > int(d[b]) or (int(d[a]) == int(d[b]) and str(a) < str(b)))
	var o := {}
	for k in ks.slice(0, n):
		o[k] = d[k]
	return o


func _prefixed(now: Dictionary, then: Dictionary, prefix: String) -> Dictionary:
	var o := {}
	for k in now:
		if str(k).begins_with(prefix):
			var n := int(now[k]) - int(then.get(k, 0))
			if n != 0:
				o[str(k).substr(prefix.length())] = n
	return o
