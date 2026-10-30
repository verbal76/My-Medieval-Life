extends SceneTree
## X20-SETTLE-FOOD (owner REG-BUY-D1, 2026-10-23; finding REG-X20-D3): a settlement short of food buys it from another settlement
## through the settlements' existing regional market (Regions.food_round -> RegionalMarket.plan / execute over SettlementParty), on
## the traders' wholesale day, at the seller's own price, with the goods travelling home before anyone can eat them.
##   * a real purchase: the buyer's trader pays the farm that grew the wheat; both settlements book matched regional lines; audits hold
##   * reserves: a place releases only food above its own households' claim (the caravan's REG-BUY-P1 rules); a short place sells none
##   * failure: no supplier, too dear (price), no money (funds), no room to carry (one load a round) -- nothing moves, it is recorded
##   * transport: the goods are the buyer's from the sale, on the road (in its books), delivered once at the due day's step
##   * save/load mid-road: delivered once, no second payment; an older save without the keys loads
##   * interrupted delivery: no trader left to take it -> the council's granary; never lost, never twice
##   * imported food stays for the place's own people (not resold on the caravan) until it is provided for
##   * the flight recorder writes purchase, unmet and delivery events with listed codes
##   godot --headless --path game --script res://tests/settle_food_test.gd

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
	test_purchase_and_books()
	test_delivery_once()
	test_save_load_in_transit()
	test_old_save_loads()
	test_reserves_respected()
	test_failures()
	test_carriage_limit()
	test_interrupted_delivery()
	test_imported_not_resold()
	test_determinism()
	test_recorder()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------ fixtures ----------------
## Five settlements at day 0, with Garton short of food (empty pantries and food stocks, a trader with coins to spend) and Higham
## with a farm full of wheat its own households do not need (full pantries, so its claim is nil).
func _region(garton_till := 400) -> Regions:
	var r := Regions.create(1)
	r.step_day(0)
	var g: OffMapSettlement = r.by_id["garton"]
	for h in g.hh:
		h.pantry = {}
		h.credit = 0.0
	for t in g.biz:
		for f in g.food_items():
			g.biz[t].stock.erase(f)
	g.gov.granary = {}
	g.trader().till = garton_till
	g.trader().reserve = 0
	var hi: OffMapSettlement = r.by_id["higham"]
	for h in hi.hh:
		h.pantry = {"wheat": 40}
	hi.biz.farm.stock["wheat"] = 300
	hi.biz.farm.till = 1000                       # it pays its way: no cash-shortfall sales
	for s: OffMapSettlement in r.list:
		if s.id != "garton" and s.id != "higham":
			for h in s.hh:
				h.pantry = {"wheat": 40}           # provided for, but with nothing to spare (no farm surplus)
			for t in s.biz:
				s.biz[t].stock.erase("wheat")
			s.trader().stock.erase("wheat")
	for s: OffMapSettlement in r.list:
		s.reopen_books()
		s._pcache = {}
	return r


func _totals(r: Regions) -> Array:
	return [r.coins(), JSON.stringify(_sorted(r.goods()))]


func _sorted(d: Dictionary) -> Dictionary:
	var ks := d.keys()
	ks.sort()
	var o := {}
	for k in ks:
		o[k] = d[k]
	return o


func _day_of(r: Regions) -> int:
	return 5                                      # a wholesale day (road_trade_every_days 6: d % 6 == 5)


# ------------------------------------------------------------------ tests ----------------
func test_purchase_and_books() -> void:
	var r := _region()
	var g: OffMapSettlement = r.by_id["garton"]
	var hi: OffMapSettlement = r.by_id["higham"]
	check(float(g.wants()._food_pts) > 0.0, "Garton's people hold under three days of food: it wants food")
	var before := _totals(r)
	var want0 := float(g.wants()._food_pts)
	var till0 := int(g.trader().till)
	var farm0 := int(hi.biz.farm.till)
	var wheat0 := int(hi.biz.farm.stock.wheat)
	var res := r.food_round(5)
	check(res.lines.size() >= 1, "a purchase is made (%d lines)" % res.lines.size())
	var line: Dictionary = res.lines[0] if not res.lines.is_empty() else {}
	check(str(line.get("buyer", "")) == "garton/trader" and str(line.get("seller", "")) == "higham/farm", "Garton's trader buys from Higham's farm (%s <- %s)" % [line.get("buyer"), line.get("seller")])
	check(int(line.get("unit_price", 0)) == hi.price("wheat"), "at Higham's own floating price (%d)" % hi.price("wheat"))
	var n := int(line.get("units", 0))
	var paid := int(line.get("total", 0))
	check(int(g.trader().till) == till0 - paid and int(hi.biz.farm.till) == farm0 + paid, "the price leaves the buyer's till and enters the grower's")
	check(int(hi.biz.farm.stock.wheat) == wheat0 - n, "the wheat leaves the farm")
	check(int(g.trader().stock.get("wheat", 0)) == 0 and g.transit.size() == 1 and int(g.transit[0].n) == n, "and is on the road: not in Garton's hands yet")
	check(int(g.goods().get("wheat", 0)) == n, "but already Garton's (in its books)")
	check(int(g.flows.regional_in.get("wheat", 0)) == n and int(hi.flows.regional_out.get("wheat", 0)) == n
		and int(g.flows.regional_coins_out) == paid and int(hi.flows.regional_coins_in) == paid, "both settlements book matched regional lines")
	check(g.audit() == "" and hi.audit() == "" and r.audit() == "", "audits hold (%s)" % r.audit())
	check(_totals(r) == before, "nothing made or lost: the region's coins and goods are the same")
	check(RegionalMarket.matched([r.party("garton/trader"), r.party("higham/farm")]) == "", "the journal pairs the sale and the purchase")
	check(int(g.flows.food_bought) == n and int(hi.flows.food_sold) == n, "food counts on both sides")
	var want1 := float(g.wants()._food_pts)
	check(absf(want1 - maxf(0.0, want0 - float(n) * OffMapSettlement._pts("wheat"))) < 1e-6, "food on the road counts against the want (%.0f -> %.0f)" % [want0, want1])


func test_delivery_once() -> void:
	var r := _region()
	var g: OffMapSettlement = r.by_id["garton"]
	r.food_round(5)
	var e: Dictionary = g.transit[0]
	var n := int(e.n)
	var due := int(e.due)
	check(due > 5, "the goods arrive after a trip (due day %d)" % due)
	var pre := _totals(r)
	# steps before the due day deliver nothing (the market may sell other goods; the wheat is still on the road)
	for d in range(6, due):
		g.step_day(d)
		check(g.transit.size() == 1, "day %d: still on the road" % d)
	g.step_day(due)
	check(g.transit.is_empty() and int(g.flows.food_delivered) == n, "delivered at the due day's step (%d)" % n)
	check(g.audit() == "", "Garton's audit holds after delivery (%s)" % g.audit())
	var delivered := int(g.flows.food_delivered)
	g.step_day(due + 1)
	g.step_day(due + 2)
	check(int(g.flows.food_delivered) == delivered and g.transit.is_empty(), "and never again")
	check(r.audit() == "", "the region's audit still holds")
	check(pre[0] == r.coins(), "no coin made by the delivery")


func test_save_load_in_transit() -> void:
	var r := _region()
	var g: OffMapSettlement = r.by_id["garton"]
	r.food_round(5)
	r.day = 5
	var e: Dictionary = g.transit[0].duplicate()
	var paid := int(g.flows.regional_coins_out)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(r.to_dict()))
	var r2 := Regions.from_dict(saved, 1)
	var g2: OffMapSettlement = r2.by_id["garton"]
	check(g2.transit.size() == 1 and int(g2.transit[0].n) == int(e.n) and int(g2.transit[0].due) == int(e.due) and g2.ship_seq == g.ship_seq,
		"the shipment on the road is saved and loaded")
	check(r2.audit() == "", "the loaded books balance (%s)" % r2.audit())
	for d in range(6, int(e.due) + 3):
		r.step_day(d)
		r2.step_day(d)
	check(int(g2.flows.food_delivered) == int(e.n) and g2.transit.is_empty(), "after loading it is delivered once")
	check(int(g2.flows.regional_coins_out) >= paid and int(r2.by_id["higham"].flows.regional_coins_in) == int(r2.by_id["garton"].flows.regional_coins_out) + _other_regional_out(r2, "garton"),
		"no second payment for it")
	check(JSON.stringify(r.to_dict()) == JSON.stringify(r2.to_dict()), "the loaded world goes on exactly as the one that was never saved")
	# a wholesale day already done is not done again when the save is loaded on it
	var r3 := Regions.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())), 1)
	var bought := int(r3.by_id["garton"].flows.food_bought)
	r3.step_day(r.day)
	check(int(r3.by_id["garton"].flows.food_bought) == bought, "a day already stepped is not traded twice")


func _other_regional_out(r: Regions, except: String) -> int:
	var n := 0
	for s: OffMapSettlement in r.list:
		if s.id != except and s.id != "higham":
			n -= int(s.flows.regional_coins_in) - int(s.flows.regional_coins_out)
	n -= int(r.by_id[except].flows.regional_coins_in)
	n += int(r.by_id["higham"].flows.regional_coins_out)
	return n


func test_old_save_loads() -> void:
	var r := Regions.create(2)
	for d in 3:
		r.step_day(d)
	var dd: Dictionary = JSON.parse_string(JSON.stringify(r.to_dict()))
	for sd in dd.settlements:
		sd.erase("transit")
		sd.erase("ship_seq")
		for k in ["food_bought", "food_sold", "food_delivered", "food_unmet"]:
			sd.flows.erase(k)
	var r2 := Regions.from_dict(dd, 2)
	check(r2 != null and r2.audit() == "", "a save from before the food trade loads and balances")
	check(r2.list.all(func(s): return s.transit.is_empty() and s.ship_seq == 0 and int(s.flows.food_bought) == 0), "with nothing on the road")
	for d in range(3, 20):
		r2.step_day(d)
	check(r2.audit() == "", "and runs on (%s)" % r2.audit())


func test_reserves_respected() -> void:
	# Higham's own households have nothing: its claim covers the farm's wheat, so it releases none
	var r := _region()
	var hi: OffMapSettlement = r.by_id["higham"]
	for h in hi.hh:
		h.pantry = {}
	hi.biz.farm.stock["wheat"] = 60
	hi.reopen_books()
	var claim_units := hi.food_claim_pts() / OffMapSettlement._pts("wheat")
	var wheat0 := int(hi.biz.farm.stock.wheat)
	var res := r.food_round(5)
	check(claim_units >= 60.0 or float(hi.wants()._food_pts) > 0.0, "Higham's households need the wheat (claim %.0f units)" % claim_units)
	check(res.lines.filter(func(l): return str(l.seller).begins_with("higham/")).is_empty() and int(hi.biz.farm.stock.wheat) == wheat0,
		"Higham sells none of its households' food")
	check(res.unmet.any(func(u): return str(u.buyer) == "garton/trader" and str(u.reason) == "no supplier"), "Garton goes without: no supplier")
	check(r.audit() == "", "audits hold")
	# a settlement that is itself short is not a seller, even with wheat in a farm's stock
	var r2 := _region()
	var hi2: OffMapSettlement = r2.by_id["higham"]
	for h in hi2.hh:
		h.pantry = {}
	hi2.biz.farm.stock["wheat"] = 5
	hi2.reopen_books()
	check(float(hi2.wants()._food_pts) > 0.0, "Higham is short itself")
	var res2 := r2.food_round(5)
	check(res2.lines.filter(func(l): return str(l.seller).begins_with("higham/")).is_empty(), "and sells nothing")
	# the release follows the claim: what Higham sells never takes its households below their claim
	var r3 := _region()
	var hi3: OffMapSettlement = r3.by_id["higham"]
	for h in hi3.hh:
		h.pantry = {"wheat": 2}
	hi3.biz.farm.stock["wheat"] = 120
	hi3.reopen_books()
	var rel := hi3.food_release(["wheat"])
	var spare := int(hi3.biz.farm.stock.wheat) - int(hi3._keep(hi3.biz.farm).get("wheat", 0)) - ceili(float(OffMapSettlement.btype("farm").feed) * float(hi3.biz.farm.horses) * float(GameData.b("reserve_days")))
	var expect := mini(spare, floori(maxf(0.0, float(spare) * OffMapSettlement._pts("wheat") - hi3.food_claim_pts()) / OffMapSettlement._pts("wheat")))
	check(int(rel.get("farm", {}).get("wheat", 0)) == maxi(0, expect), "the farm may sell only the wheat above the claim (%d of %d)" % [int(rel.get("farm", {}).get("wheat", 0)), spare])
	var res3 := r3.food_round(5)
	var sold := 0
	for l in res3.lines:
		if str(l.seller) == "higham/farm":
			sold += int(l.units)
	check(sold <= maxi(0, expect), "and sells no more (%d)" % sold)


func test_failures() -> void:
	# funds: the trader's till is at its floor
	var r := _region(int(OffMapSettlement.rules().trader_reserve_floor))
	var before := _totals(r)
	var res := r.food_round(5)
	check(res.lines.is_empty() and res.unmet.any(func(u): return str(u.buyer) == "garton/trader" and str(u.reason) == "funds"), "no money to spare: nothing bought (funds)")
	check(_totals(r) == before and r.by_id["garton"].transit.is_empty() and r.audit() == "", "and nothing moved")
	check(int(r.by_id["garton"].flows.food_unmet) > 0, "the shortfall is counted")
	# price: Higham's wheat is dearer than Garton's trader will pay
	var r2 := _region()
	var g2: OffMapSettlement = r2.by_id["garton"]
	for h in g2.hh:                               # two days' food in hand: short, but not desperate (willing to pay less)
		h.pantry = {"wheat": ceili(2.0 * g2._need_pts(h) / OffMapSettlement._pts("wheat"))}
	g2.reopen_books()
	var hi: OffMapSettlement = r2.by_id["higham"]
	hi.prices["wheat"] = float(GameData.value("wheat")) * float(GameData.b("price_max"))
	hi._pcache = {}
	var will := RegionalMarket.willing(SettlementParty.make(r2, r2.by_id["garton"], "trader"), "wheat")
	var res2 := r2.food_round(5)
	if hi.price("wheat") > will:
		check(res2.lines.is_empty() and res2.unmet.any(func(u): return str(u.reason) == "price"), "too dear (%d > %d): no deal (price)" % [hi.price("wheat"), will])
	else:
		check(false, "the price test needs Higham's price (%d) above Garton's willingness (%d)" % [hi.price("wheat"), will])
	check(r2.audit() == "", "audits hold")
	# no one short: no round at all, nothing touched
	var r3 := Regions.create(1)
	r3.step_day(0)
	for s: OffMapSettlement in r3.list:
		for h in s.hh:
			h.pantry = {"wheat": 60}
		s.reopen_books()
	var snap := JSON.stringify(r3.to_dict())
	var res3 := r3.food_round(5)
	check(res3.lines.is_empty() and res3.unmet.is_empty() and JSON.stringify(r3.to_dict()) == snap, "with no settlement short, the round changes nothing")
	# a refused line (the goods gone between plan and execute) moves nothing
	var r4 := _region()
	var ls := [r4.party("garton/trader"), r4.party("higham/farm")]
	var line := {"seller": "higham/farm", "buyer": "garton/trader", "item": "wheat", "units": 500, "unit_price": 2, "total": 1000,
		"carriage": "self", "carrier": "", "fee_each": 0, "fee_total": 0, "days": 0.3}
	var before4 := _totals(r4)
	var e := RegionalMarket.execute({"lines": [line], "unmet": [], "lost": []}, ls, 5)
	check(e.refused.size() == 1 and _totals(r4) == before4 and r4.audit() == "", "a line that no longer holds is refused whole")


func test_carriage_limit() -> void:
	var r := _region(5000)
	var g: OffMapSettlement = r.by_id["garton"]
	var cap := RegionalMarket.self_capacity(SettlementParty.make(r, g, "trader"))
	var res := r.food_round(5)
	var n := 0
	for l in res.lines:
		n += int(l.units)
	check(g.horses() == 0 and cap == TradeRoutes.capacity({"carry": 1}), "Garton has no horses: its trader carries a pack (%d)" % cap)
	check(n <= cap, "one load a round: %d bought of a %d-unit pack" % [n, cap])
	check(res.unmet.any(func(u): return str(u.reason) == "no carriage"), "the rest goes unbought (no carriage)")


func test_interrupted_delivery() -> void:
	var r := _region()
	var g: OffMapSettlement = r.by_id["garton"]
	r.food_round(5)
	var n := int(g.transit[0].n)
	var due := int(g.transit[0].due)
	# the trader is gone (its books handed to the council first, so nothing is lost by the test itself)
	var m: Dictionary = g.trader()
	g.gov.coins += int(m.till)
	for k in m.stock:
		OffMapSettlement._add(g.gov.granary, k, int(m.stock[k]))
	g.biz.erase("merchant")
	check(g.audit() == "", "the books balance with the trader gone")
	var gran := int(g.gov.granary.get("wheat", 0))
	for d in range(6, due + 1):
		g.step_day(d)
	check(g.transit.is_empty() and int(g.flows.food_delivered) == n, "the wheat still arrives")
	check(int(g.gov.granary.get("wheat", 0)) == gran + n, "into the council's granary")
	check(g.journal.any(func(j): return "granary" in str(j.text)), "and the settlement's record says why")
	check(g.audit() == "", "nothing lost (%s)" % g.audit())


func test_imported_not_resold() -> void:
	var r := _region()
	var g: OffMapSettlement = r.by_id["garton"]
	r.food_round(5)
	var due := int(g.transit[0].due)
	# deliver without the morning market taking it, to see the mark
	g.day = due
	g._deliver()
	var have := int(g.trader().stock.get("wheat", 0))
	check(have > 0 and int(g.trader().imported.wheat) == have, "the delivered wheat is marked imported (%d)" % have)
	check(g.trader_has("wheat") == 0 and not g.sell_to_village("wheat", 1, 3), "it is not offered to the village's caravan")
	check(SettlementParty.make(r, g, "trader").sale_cap("wheat") == 0, "nor to another settlement")
	g._imported_left()
	g.release_imported()
	check(g.trader_has("wheat") == have, "once the place is provided for it is ordinary stock")
	check(g.audit() == "", "audit holds")


func test_determinism() -> void:
	var a := _run(3, 150)
	var b := _run(3, 150)
	check(a == b, "two runs of the same seed are identical (food trade included)")


func _run(seed_: int, days: int) -> String:
	var r := Regions.create(seed_)
	for d in days:
		r.step_day(d)
	check(r.audit() == "", "seed %d day %d: the region's audit holds (%s)" % [seed_, days, r.audit()])
	return JSON.stringify(r.to_dict())


func test_recorder() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var root := OS.get_cache_dir() + "/mml_settle_food_%d" % int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(root)
	var rec := WorldRecorder.attach(w, {"root": root})
	var r: Regions = w.regions
	r.step_day(w.day())
	var g: OffMapSettlement = r.by_id["garton"]
	for h in g.hh:
		h.pantry = {}
		h.credit = 0.0
	for t in g.biz:
		for f in g.food_items():
			g.biz[t].stock.erase(f)
	g.gov.granary = {}
	g.trader().till = 400
	g.trader().reserve = 0
	var hi: OffMapSettlement = r.by_id["higham"]
	for h in hi.hh:
		h.pantry = {"wheat": 40}
	hi.biz.farm.stock["wheat"] = 300
	hi.biz.farm.till = 1000
	var res := r.food_round(w.day())
	var due := int(g.transit[0].due) if not g.transit.is_empty() else 0
	for d in range(w.day() + 1, due + 1):
		g.step_day(d)
	rec.flush()
	var evs: Array = RecorderArchive.read_table(FlightRecorder._abs(rec.dir), "event")
	var bought := evs.filter(func(e): return e.subtype == "settlement_food_purchase" and e.outcome == "ok")
	var arrived := evs.filter(func(e): return e.subtype == "settlement_food_delivery")
	var unmet := evs.filter(func(e): return e.subtype == "settlement_food_unmet")
	check(res.lines.size() > 0 and bought.size() == res.lines.size(), "each purchase is a recorded event (%d)" % bought.size())
	check(arrived.size() == 1 and arrived[0].outcome == "ok", "the delivery is recorded")
	check(unmet.size() == res.unmet.size(), "each shortfall is recorded with its reason (%d)" % unmet.size())
	check(rec.unknown_codes.is_empty(), "no code outside recorder_codes.json (%s)" % str(rec.unknown_codes))
	w.dispose()
