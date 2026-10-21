extends SceneTree
## PROSPECTIVE harness (Expansion 18, SET-C caravan replacement plan; PROS-18): runs the live village with the
## CURRENT caravan (CARAVAN-TMP, the 30-coin daily allowance) unchanged, and beside it, in shadow, asks what genuine
## regional trade would have done at each caravan visit: three finite off-map settlements (tests/fixtures/
## x18_regions.json) with their own stocks, needs, production and closed purses, trading with a read-only snapshot of
## the village through RegionalMarket and TradeRoutes. The shadow never writes to the World (checked); it compares
## the money and goods the caravan moves, and the coins its allowance creates, with what demand-driven trade moves.
## See docs/expansion18/CARAVAN_REPLACEMENT.md.
##   godot --headless --path game --script res://tests/caravan_compare.gd -- [--days 10] [--seed 1] [--income 0] [--out f.json]
## Integrity checks (pass/fail): the shadow leaves the World untouched; the regions' books balance and every shadow
## transfer is matched; shadow trade conserves coins; the live currency balances (start + in - out = end).
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
	var regions := []
	var links := []
	for r in fx.regions:
		var l := SettlementLedger.make(r)
		l.income_per_day = income
		regions.append(l)
		links.append([SettlementFacts.VILLAGE, str(r.id), int(r.link.tiles), r.link.mix])
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var every := maxi(1, int(GameData.b("caravan_every_days")))
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	var coins0 := w.total_coins()
	var stats_start := w.stats.duplicate()
	var stats_prev := w.stats.duplicate()
	var prev_day := 0
	var rows := []
	var tot := {"actual_in": 0, "actual_out": 0, "allowance": 0, "shadow_in": 0, "shadow_out": 0, "visits": 0}
	var unmet_reasons := {}
	var buyer_kinds := {}
	var untouched_checked := false
	print("day | caravan: coins in / out, allowance created | genuine trade (shadow): coins in / out | region purses")
	for day in days:
		var visit := day % every == 1
		var shadow := {}
		if visit:
			var needs := SettlementReport.measured_use(stats_prev, w.stats, float(maxi(1, day - prev_day)))
			stats_prev = w.stats.duplicate()
			prev_day = day
			var before := ""
			if not untouched_checked:
				before = JSON.stringify(w.to_dict())
			shadow = _shadow(w, needs, regions, links, day)
			if not untouched_checked:
				check(JSON.stringify(w.to_dict()) == before, "the shadow regional trade leaves the World untouched")
				untouched_checked = true
		var s0 := w.stats.duplicate()
		var purse0 := w.caravan_purse
		for i in per_day:
			w.update(STEP)
			w.player.hunger = 100.0                      # the idle player is fed, as in economy_sim
		for r: SettlementLedger in regions:
			r.tick(day)
		if not visit:
			continue
		var d := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(s0.get(k, 0))
		var c_in: int = d.call("caravan_coins_in")
		var c_out: int = d.call("caravan_coins_out")
		var allowance := (w.caravan_purse - purse0) + c_in - c_out
		var row := {"day": day, "actual_in": c_in, "actual_out": c_out, "allowance": allowance,
			"exported": _prefixed(w.stats, s0, "exported_"), "imported": _prefixed(w.stats, s0, "imported_"),
			"shadow_in": int(shadow.coins_in), "shadow_out": int(shadow.coins_out), "shadow_sold": shadow.sold,
			"shadow_bought": shadow.bought, "shadow_buyers": shadow.buyers, "unmet": shadow.unmet, "purses": regions.map(func(r): return r.coins)}
		for k in shadow.buyers:
			buyer_kinds[k] = int(buyer_kinds.get(k, 0)) + int(shadow.buyers[k])
		rows.append(row)
		for k in ["actual_in", "actual_out", "allowance", "shadow_in", "shadow_out"]:
			tot[k] += int(row[k])
		tot.visits += 1
		for u in shadow.unmet:
			var key := "%s:%s" % [str(u.buyer).get_slice("/", 0), str(u.reason)]
			unmet_reasons[key] = int(unmet_reasons.get(key, 0)) + int(u.units)
		print("%3d | %4d / %4d, %4d | %4d / %4d | %s" % [day, c_in, c_out, allowance, int(shadow.coins_in), int(shadow.coins_out), str(row.purses)])
	# integrity
	for r: SettlementLedger in regions:
		check(r.balanced() == "", "%s's books balance over the run (%s)" % [r.id, r.balanced()])
	var dd := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(stats_start.get(k, 0))
	var leak: int = w.total_coins() - coins0 - (dd.call("caravan_coins_in") + dd.call("newcomer_coins_in")) + dd.call("caravan_coins_out")
	check(leak == 0, "the live village's currency balances over %d days with the caravan unchanged (leak %d)" % [days, leak])
	print("TOTALS over %d caravan visits (%d days, seed %d, regional income %d a day):" % [tot.visits, days, seed, income])
	print("  current caravan: village coins in %d, out %d, net %+d; coins created by the allowance %d" % [tot.actual_in, tot.actual_out, tot.actual_in - tot.actual_out, tot.allowance])
	print("  genuine trade:   village coins in %d, out %d, net %+d; coins created 0 (closed purses: %d left of %d)" % [tot.shadow_in, tot.shadow_out,
		tot.shadow_in - tot.shadow_out, regions.reduce(func(a, r): return a + r.coins, 0), (fx.regions as Array).reduce(func(a, r): return a + int(r.coins), 0) + income * days * regions.size()])
	print("  genuine trade, village purchases by buyer kind (coins, carriage included): %s" % str(buyer_kinds))
	print("  unmet (buyer:reason units): %s" % str(unmet_reasons))
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify({"format": "x18-caravan-compare/0", "seed": seed, "days": days, "income": income,
			"totals": tot, "unmet": unmet_reasons, "visits": rows}, "  "))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## One visit's genuine trade, in shadow: the village as read-only snapshots of its parties (owner Q18-10: anyone may
## buy -- its traders, households and treasury, each with its own purse; each fetches what it buys itself or pays a
## carter; SettlementReport.parties), with its measured daily food use; the regions as they stand. Region-side changes
## persist (their purses and stocks are real within the shadow); the village snapshots are thrown away. No carter is
## offered on either side: the live game has no rule for hiring one between settlements (Q18-12), so a party that
## cannot travel (the treasury) buys nothing here.
func _shadow(w: World, needs: Dictionary, regions: Array, links: Array, day: int) -> Dictionary:
	var vs := SettlementReport.parties(w, needs)
	var ls := vs + regions
	var coins_before := 0
	for l: SettlementLedger in ls:
		coins_before += l.coins
	var routes := TradeRoutes.table(ls, links)
	var p := RegionalMarket.plan(ls, routes)
	var r := RegionalMarket.execute(p, ls, day)
	var coins_after := 0
	for l: SettlementLedger in ls:
		coins_after += l.coins
	check(coins_after == coins_before, "day %d: shadow trade conserves coins (%d)" % [day, coins_before])
	check(RegionalMarket.matched(ls, day) == "", "day %d: every shadow transfer is matched" % day)
	check(r.done.all(func(l): return l.carriage == "self" or int(l.fee_total) > 0), "day %d: nothing is delivered free" % day)
	var village := {}
	for l: SettlementLedger in vs:
		village[l.id] = l.kind
	var out := {"coins_in": 0, "coins_out": 0, "sold": {}, "bought": {}, "unmet": [], "buyers": {}}
	for line in r.done:
		if village.has(line.seller):
			out.coins_in += int(line.total)
			out.sold[line.item] = int(out.sold.get(line.item, 0)) + int(line.units)
		elif village.has(line.buyer):
			out.coins_out += int(line.total) + int(line.fee_total)
			out.bought[line.item] = int(out.bought.get(line.item, 0)) + int(line.units)
			var k: String = village[line.buyer]
			out.buyers[k] = int(out.buyers.get(k, 0)) + int(line.total) + int(line.fee_total)
	out.unmet = p.unmet
	return out


func _prefixed(now: Dictionary, then: Dictionary, prefix: String) -> Dictionary:
	var o := {}
	for k in now:
		if str(k).begins_with(prefix):
			var n := int(now[k]) - int(then.get(k, 0))
			if n != 0:
				o[str(k).substr(prefix.length())] = n
	return o
