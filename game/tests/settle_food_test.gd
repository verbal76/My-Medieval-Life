extends SceneTree
## X20-SETTLE-FOOD (owner REG-BUY-D1, 2026-10-23; finding REG-X20-D3; owner direction 2026-10-30: one transaction mechanism): a
## settlement short of food buys it from another settlement on the traders' wholesale day (Regions.food_round): RegionalMarket plans
## the deal at the seller's own price, and the world's transaction authority (World.transactions, LE-03) ships it -- the seller's goods
## into transit custody and the buyer's price into escrow, then delivered (goods to the buyer, price to the seller) at the due day's
## step, or failed (goods back, price refunded). Checked here:
##   * a real purchase with goods and coins conserved and booked; audits hold (settlements + transit)
##   * reserves (REG-BUY-P1 release); a short place sells none; genuine surplus is sold
##   * failure: no supplier, too dear, no money, no room to carry; rejected transfers move nothing; competing transfers on the same
##     funds or the same last food; two buyers for the last food
##   * delivery once; save/load and replay mid-road; older saves
##   * interrupted delivery (buyer unavailable) and failure with refund; abandonment (no household left)
##   * imported food kept for the place's people; repeated trade over many rounds; decline and starvation as outcomes, not defects
##   * the flight recorder's events
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
	test_two_buyers_last_food()
	test_competing_transfers()
	test_idempotent_replay()
	test_interrupted_delivery()
	test_abandoned_buyer()
	test_imported_not_resold()
	test_repeated_trade_and_decline()
	test_no_world_no_trade()
	test_determinism()
	test_recorder()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------ fixtures ----------------
## A world whose settlements stand at the world's day, with Garton short of food (empty pantries and food stocks, a trader with
## `garton_till` coins to spend) and Higham with a farm full of wheat its own households do not need (their pantries full).
func _world(garton_till := 400) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var r: Regions = w.regions
	r.step_day(w.day())
	_short(r, "garton", garton_till)
	var hi: OffMapSettlement = r.by_id["higham"]
	for h in hi.hh:
		h.pantry = {"wheat": 40}
	hi.biz.farm.stock["wheat"] = 300
	hi.biz.farm.till = 1000                       # it pays its way: no cash-shortfall sales
	for s: OffMapSettlement in r.list:
		if s.id != "garton" and s.id != "higham":
			for h in s.hh:
				h.pantry = {"wheat": 40}           # provided for, with no farm surplus to sell
			for t in s.biz:
				s.biz[t].stock.erase("wheat")
	for s: OffMapSettlement in r.list:
		s.reopen_books()
		s._pcache = {}
	return w


func _short(r: Regions, id: String, till: int) -> void:
	var s: OffMapSettlement = r.by_id[id]
	for h in s.hh:
		h.pantry = {}
		h.credit = 0.0
	for t in s.biz:
		for f in s.food_items():
			s.biz[t].stock.erase(f)
	s.gov.granary = {}
	s.trader().till = till
	s.trader().reserve = 0
	s.reopen_books()
	s._pcache = {}


## The region's coins and goods, transit included (Regions.coins/goods count the settlements' custody and escrow).
func _totals(r: Regions) -> Array:
	var g := r.goods()
	var ks := g.keys()
	ks.sort()
	var o := {}
	for k in ks:
		o[k] = g[k]
	return [r.coins(), JSON.stringify(o)]


# ------------------------------------------------------------------ tests ----------------
func test_purchase_and_books() -> void:
	var w := _world()
	var r := w.regions
	var g: OffMapSettlement = r.by_id["garton"]
	var hi: OffMapSettlement = r.by_id["higham"]
	check(float(g.wants()._food_pts) > 0.0, "Garton's people hold under three days of food: it wants food")
	var before := _totals(r)
	var want0 := float(g.wants()._food_pts)
	var till0 := int(g.trader().till)
	var farm0 := int(hi.biz.farm.till)
	var wheat0 := int(hi.biz.farm.stock.wheat)
	var res := r.food_round(w.day())
	check(res.lines.size() >= 1, "a purchase is made (%d lines)" % res.lines.size())
	var line: Dictionary = res.lines[0] if not res.lines.is_empty() else {}
	check(str(line.get("buyer", "")) == "garton/trader" and str(line.get("seller", "")) == "higham/farm", "Garton's trader buys from Higham's farm (%s <- %s)" % [line.get("buyer"), line.get("seller")])
	check(int(line.get("unit_price", 0)) == hi.price("wheat"), "at Higham's own floating price (%d)" % hi.price("wheat"))
	var n := int(line.get("units", 0))
	var paid := int(line.get("total", 0))
	var sh := w.transactions.get_shipment(str(line.get("tx", "")))
	check(str(sh.get("state", "")) == "open" and str(sh.get("buyer", "")) == "region:garton/trader" and str(sh.get("seller", "")) == "region:higham/farm",
		"the transaction authority holds it as an open shipment (%s)" % str(line.get("tx")))
	check(int(g.trader().till) == till0 - paid and int(hi.biz.farm.till) == farm0, "the price is in escrow: out of the buyer's till, not yet the seller's")
	check(int(hi.biz.farm.stock.wheat) == wheat0 - n and int(g.trader().stock.get("wheat", 0)) == 0, "the wheat is in transit: out of the farm, not yet in Garton")
	check(int(r.tx_in_transit().coins) == paid and int(r.tx_in_transit().goods.get("wheat", 0)) == n, "transit holds exactly the price and the wheat")
	check(g.audit() == "" and hi.audit() == "" and r.audit() == "", "audits hold (%s)" % r.audit())
	check(_totals(r) == before, "nothing made or lost: the region's coins and goods, transit included, are the same")
	check(int(g.flows.food_bought) == n and int(hi.flows.food_sold) == n, "food counts on both sides")
	var want1 := float(g.wants()._food_pts)
	check(absf(want1 - maxf(0.0, want0 - float(n) * OffMapSettlement._pts("wheat"))) < 1e-6, "food on the road counts against the want (%.0f -> %.0f)" % [want0, want1])
	w.dispose()


func test_delivery_once() -> void:
	var w := _world()
	var r := w.regions
	var g: OffMapSettlement = r.by_id["garton"]
	var hi: OffMapSettlement = r.by_id["higham"]
	var d := w.day()
	var res := r.food_round(d)
	var line: Dictionary = res.lines[0]
	var due := int(g.transit[0].due)
	check(due > d and str(g.transit[0].tx) == str(line.tx), "Garton awaits the shipment, due day %d" % due)
	var farm0 := int(hi.biz.farm.till)
	for dd in range(d + 1, due):
		g.step_day(dd)
		check(g.transit.size() == 1, "day %d: still on the road" % dd)
	g.step_day(due)
	check(g.transit.is_empty() and int(g.flows.food_delivered) == int(line.units), "delivered at the due day's step (%d)" % int(line.units))
	check(str(w.transactions.get_shipment(str(line.tx)).state) == "delivered", "the authority closed it as delivered")
	check(int(hi.biz.farm.till) == farm0 + int(line.total), "the escrowed price reached the grower on delivery")
	check(g.audit() == "" and hi.audit() == "" and r.audit() == "", "audits hold after delivery (%s)" % r.audit())
	check(int(r.tx_in_transit().coins) == 0 and (r.tx_in_transit().goods as Dictionary).is_empty(), "nothing left in transit")
	var delivered := int(g.flows.food_delivered)
	var farm1 := int(hi.biz.farm.till)
	g.step_day(due + 1)
	g.step_day(due + 2)
	check(int(g.flows.food_delivered) == delivered and int(hi.biz.farm.till) == farm1, "and never again")
	w.dispose()


func test_save_load_in_transit() -> void:
	var w := _world()
	var r := w.regions
	var d := w.day()
	r.food_round(d)
	r.day = d
	var e: Dictionary = r.by_id["garton"].transit[0].duplicate()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	var r2 := w2.regions
	var g2: OffMapSettlement = r2.by_id["garton"]
	check(g2.transit.size() == 1 and str(g2.transit[0].tx) == str(e.tx) and int(g2.transit[0].due) == int(e.due), "the awaited shipment is saved and loaded")
	check(str(w2.transactions.get_shipment(str(e.tx)).get("state", "")) == "open", "and the authority's open shipment with it")
	check(r2.audit() == "" and _totals(r2) == _totals(r), "the loaded books balance and match (%s)" % r2.audit())
	var paid := int(g2.flows.outside_coins_out)
	for dd in range(d + 1, int(e.due) + 3):
		g2.step_day(dd)
	check(int(g2.flows.food_delivered) == int(e.n) and g2.transit.is_empty(), "after loading it is delivered once")
	check(int(g2.flows.outside_coins_out) == paid, "no second payment")
	check(r2.food_seq == r.food_seq, "the attempt numbers are saved")
	check(r2.audit() == "", "audit holds (%s)" % r2.audit())
	w.dispose()
	w2.dispose()


func test_old_save_loads() -> void:
	var r := Regions.create(2)
	for d in 3:
		r.step_day(d)
	var dd: Dictionary = JSON.parse_string(JSON.stringify(r.to_dict()))
	dd.erase("food_seq")
	for sd in dd.settlements:
		sd.erase("transit")
		for k in ["food_bought", "food_sold", "food_delivered", "food_unmet"]:
			sd.flows.erase(k)
	var r2 := Regions.from_dict(dd, 2)
	check(r2 != null and r2.audit() == "", "a save from before the food trade loads and balances")
	check(r2.list.all(func(s): return s.transit.is_empty() and int(s.flows.food_bought) == 0) and r2.food_seq.is_empty(), "with nothing on the road")
	for d in range(3, 20):
		r2.step_day(d)
	check(r2.audit() == "", "and runs on (%s)" % r2.audit())


func test_reserves_respected() -> void:
	# Higham's own households have nothing: its claim covers the farm's wheat, so it releases none
	var w := _world()
	var r := w.regions
	var hi: OffMapSettlement = r.by_id["higham"]
	for h in hi.hh:
		h.pantry = {}
	hi.biz.farm.stock["wheat"] = 60
	hi.reopen_books()
	var wheat0 := int(hi.biz.farm.stock.wheat)
	var res := r.food_round(w.day())
	check(res.lines.filter(func(l): return str(l.seller).begins_with("higham/")).is_empty() and int(hi.biz.farm.stock.wheat) == wheat0,
		"Higham sells none of its households' food")
	check(res.unmet.any(func(u): return str(u.buyer) == "garton/trader" and str(u.reason) == "no supplier"), "Garton goes without: no supplier")
	check(r.audit() == "", "audits hold")
	w.dispose()
	# the release follows the claim: a farm sells only what is above it (genuine surplus), never more
	var w3 := _world()
	var r3 := w3.regions
	var hi3: OffMapSettlement = r3.by_id["higham"]
	for h in hi3.hh:
		h.pantry = {"wheat": 2}
	hi3.biz.farm.stock["wheat"] = 120
	hi3.reopen_books()
	var rel := hi3.food_release(["wheat"])
	var spare := int(hi3.biz.farm.stock.wheat) - int(hi3._keep(hi3.biz.farm).get("wheat", 0)) - ceili(float(OffMapSettlement.btype("farm").feed) * float(hi3.biz.farm.horses) * float(GameData.b("reserve_days")))
	var expect := mini(spare, floori(maxf(0.0, float(spare) * OffMapSettlement._pts("wheat") - hi3.food_claim_pts()) / OffMapSettlement._pts("wheat")))
	check(int(rel.get("farm", {}).get("wheat", 0)) == maxi(0, expect), "the farm may sell only the wheat above the claim (%d of %d)" % [int(rel.get("farm", {}).get("wheat", 0)), spare])
	var res3 := r3.food_round(w3.day())
	var sold := 0
	for l in res3.lines:
		if str(l.seller) == "higham/farm":
			sold += int(l.units)
	check(sold <= maxi(0, expect), "and sells no more (%d)" % sold)
	w3.dispose()
	# a settlement that is itself short is not a seller, even with wheat in a farm's stock
	var w2 := _world()
	var r2 := w2.regions
	var hi2: OffMapSettlement = r2.by_id["higham"]
	for h in hi2.hh:
		h.pantry = {}
	hi2.biz.farm.stock["wheat"] = 5
	hi2.reopen_books()
	check(float(hi2.wants()._food_pts) > 0.0, "Higham is short itself")
	var res2 := r2.food_round(w2.day())
	check(res2.lines.filter(func(l): return str(l.seller).begins_with("higham/")).is_empty(), "and sells nothing")
	w2.dispose()


func test_failures() -> void:
	# funds: the trader's till is at its floor
	var w := _world(int(OffMapSettlement.rules().trader_reserve_floor))
	var r := w.regions
	var before := _totals(r)
	var res := r.food_round(w.day())
	check(res.lines.is_empty() and res.unmet.any(func(u): return str(u.buyer) == "garton/trader" and str(u.reason) == "funds"), "no money to spare: nothing bought (funds)")
	check(_totals(r) == before and r.by_id["garton"].transit.is_empty() and r.audit() == "", "and nothing moved")
	check(int(r.by_id["garton"].flows.food_unmet) > 0, "the shortfall is counted")
	w.dispose()
	# failed negotiation: Higham's wheat is dearer than Garton's trader will pay (Garton holds two days' food: short, not desperate)
	var w2 := _world()
	var r2 := w2.regions
	var g2: OffMapSettlement = r2.by_id["garton"]
	for h in g2.hh:
		h.pantry = {"wheat": ceili(2.0 * g2._need_pts(h) / OffMapSettlement._pts("wheat"))}
	g2.reopen_books()
	var hi: OffMapSettlement = r2.by_id["higham"]
	hi.prices["wheat"] = float(GameData.value("wheat")) * float(GameData.b("price_max"))
	hi._pcache = {}
	var will := RegionalMarket.willing(SettlementParty.make(r2, g2, "trader"), "wheat")
	var res2 := r2.food_round(w2.day())
	check(hi.price("wheat") > will and res2.lines.is_empty() and res2.unmet.any(func(u): return str(u.reason) == "price"),
		"too dear (%d > %d): no deal (price)" % [hi.price("wheat"), will])
	check(r2.audit() == "", "audits hold")
	w2.dispose()
	# no one short: the round changes nothing
	var w3 := World.new()
	w3.setup(VillageMap.load_default(), 1)
	var r3 := w3.regions
	r3.step_day(w3.day())
	for s: OffMapSettlement in r3.list:
		for h in s.hh:
			h.pantry = {"wheat": 60}
		s.reopen_books()
	var snap := JSON.stringify(r3.to_dict())
	var res3 := r3.food_round(w3.day())
	check(res3.lines.is_empty() and res3.unmet.is_empty() and JSON.stringify(r3.to_dict()) == snap and w3.transactions.is_empty(),
		"with no settlement short, the round changes nothing")
	w3.dispose()


func test_carriage_limit() -> void:
	var w := _world(5000)
	var r := w.regions
	var g: OffMapSettlement = r.by_id["garton"]
	var cap := RegionalMarket.self_capacity(SettlementParty.make(r, g, "trader"))
	var res := r.food_round(w.day())
	var n := 0
	for l in res.lines:
		n += int(l.units)
	check(g.horses() == 0 and cap == TradeRoutes.capacity({"carry": 1}), "Garton has no horses: its trader carries a pack (%d)" % cap)
	check(n <= cap and n > 0, "one load a round: %d bought of a %d-unit pack" % [n, cap])
	check(res.unmet.any(func(u): return str(u.reason) == "no carriage"), "the rest goes unbought (no carriage)")
	w.dispose()


## Two short places, one seller with only a little to spare: the food is sold once, the neediest first, the other goes without.
func test_two_buyers_last_food() -> void:
	var w := _world()
	var r := w.regions
	_short(r, "netherton", 400)
	var hi: OffMapSettlement = r.by_id["higham"]
	for h in hi.hh:
		h.pantry = {"wheat": ceili(maxf(3.5, float(GameData.b("reserve_days"))) * hi._need_pts(h) / OffMapSettlement._pts("wheat"))}   # provided for
	hi.biz.farm.stock["wheat"] = int(hi._keep(hi.biz.farm).get("wheat", 0)) + ceili(float(OffMapSettlement.btype("farm").feed) * float(hi.biz.farm.horses) * float(GameData.b("reserve_days"))) + 9
	hi.reopen_books()
	hi._pcache = {}
	var rel := int(hi.food_release(["wheat"]).get("farm", {}).get("wheat", 0))
	var before := _totals(r)
	var res := r.food_round(w.day())
	var sold := 0
	for l in res.lines:
		if str(l.seller) == "higham/farm":
			sold += int(l.units)
	check(rel > 0 and rel <= 9, "Higham can spare only a few units (%d)" % rel)
	check(sold <= rel and sold > 0, "the last of it is sold once: %d of %d" % [sold, rel])
	check(res.unmet.any(func(u): return str(u.reason) in ["no supplier", "no carriage"]), "a buyer goes without, with its reason")
	check(_totals(r) == before and r.audit() == "", "nothing duplicated or lost (%s)" % r.audit())
	w.dispose()


## Shipments competing for the same coins or the same last food: the first goes, the next is refused whole with the authority's code,
## and a rejected attempt is retried under a new id.
func test_competing_transfers() -> void:
	var w := _world(60)
	var r := w.regions
	var g: OffMapSettlement = r.by_id["garton"]
	var hi: OffMapSettlement = r.by_id["higham"]
	var d := w.day()
	var a := r.tx_ship("settle_food/test:1", "region:garton/trader", "region:higham/farm", "wheat", 10, 40, d + 2)
	check(bool(a.ok), "the first shipment (40 of 60 coins) goes")
	var till := int(g.trader().till)
	var b := r.tx_ship("settle_food/test:2", "region:garton/trader", "region:higham/farm", "wheat", 10, 40, d + 2)
	check(not bool(b.ok) and str(b.code) == "no_funds" and int(g.trader().till) == till, "the second on the same purse is refused: no_funds, nothing moves")
	var stock := int(hi.biz.farm.stock.wheat)
	var ne: OffMapSettlement = r.by_id["netherton"]
	ne.trader().till = 100000
	ne.reopen_books()
	var c := r.tx_ship("settle_food/test:3", "region:netherton/trader", "region:higham/farm", "wheat", stock + 1, 1, d + 2)
	check(not bool(c.ok) and str(c.code) == "no_stock" and int(hi.biz.farm.stock.wheat) == stock, "more than the seller still holds: no_stock")
	var c2 := r.tx_ship("settle_food/test:4", "region:netherton/trader", "region:higham/farm", "wheat", stock, stock, d + 2)
	check(bool(c2.ok) and int(hi.biz.farm.stock.get("wheat", 0)) == 0, "retried under a new id for what is there, it goes")
	var c3 := r.tx_ship("settle_food/test:5", "region:garton/trader", "region:higham/farm", "wheat", 1, 1, d + 2)
	check(not bool(c3.ok) and str(c3.code) == "no_stock", "the last food cannot be sold twice")
	check(str(r.tx_ship("settle_food/test:6", "region:nowhere/trader", "region:higham/farm", "wheat", 1, 1, d).code) == "unknown_party", "an unknown party: unknown_party")
	check(str(r.tx_ship("settle_food/test:7", "region:garton/trader", "region:higham/farm", "wheat", 0, 1, d).code) == "invalid_quantity", "no units: invalid_quantity")
	check(str(r.tx_ship("bad id", "region:garton/trader", "region:higham/farm", "wheat", 1, 1, d).code) == "bad_id", "a malformed id: bad_id")
	check(r.audit().begins_with("shipment settle_food/test:"), "a shipment no settlement awaits is an orphan the audit names (%s)" % r.audit())
	r.tx_fail("settle_food/test:1", "test")
	r.tx_fail("settle_food/test:4", "test")
	check(int(g.trader().till) == till + 40 and int(hi.biz.farm.stock.wheat) == stock + 10, "failed shipments return the goods and refund the price")
	check(r.audit() == "", "books balance (%s)" % r.audit())
	w.dispose()


## A replayed id, a retried phase-2 call or a loaded save never applies a transfer twice.
func test_idempotent_replay() -> void:
	var w := _world()
	var r := w.regions
	var g: OffMapSettlement = r.by_id["garton"]
	var hi: OffMapSettlement = r.by_id["higham"]
	var d := w.day()
	var res := r.food_round(d)
	var tx := str(res.lines[0].tx)
	var paid := int(g.flows.outside_coins_out)
	var again := r.tx_ship(tx, "region:garton/trader", "region:higham/farm", "wheat", 1, 1, d + 2)
	check(bool(again.replay) and int(g.flows.outside_coins_out) == paid, "the same id again is a replay: nothing executes")
	var t1 := r.tx_deliver(tx)
	var farm := int(hi.biz.farm.till)
	var t2 := r.tx_deliver(tx)
	check(bool(t1.ok) and bool(t2.ok) and str(t2.code) == "duplicate" and int(hi.biz.farm.till) == farm, "deliver twice: the second is a duplicate, no second payment")
	check(str(r.tx_fail(tx, "late").code) == "not_open", "a different close after delivery: not_open")
	# the settlement still awaits it (delivered early by hand here); at its step it learns it is delivered and counts it once
	g.step_day(int(g.transit[0].due))
	check(g.transit.is_empty() and int(g.flows.food_delivered) == int(res.lines[0].units), "the settlement counts the delivery once")
	check(r.audit() == "", "audit holds (%s)" % r.audit())
	w.dispose()


## The buyer cannot take the goods when they arrive (its trader gone): the shipment stays open with goods and coins where they are
## (the lapse's refund cannot reach a buyer that is gone either): never lost, never twice; with a trader again, it is delivered. And a
## shipment failed by the authority returns the goods and refunds the price; the settlement records that it never arrived.
func test_interrupted_delivery() -> void:
	var w := _world()
	var r := w.regions
	var g: OffMapSettlement = r.by_id["garton"]
	var d := w.day()
	r.food_round(d)
	var e: Dictionary = g.transit[0].duplicate()
	var m: Dictionary = g.trader().duplicate(true)
	g.gov.coins += int(m.till)                     # the trader's own books handed to the council, so the test loses nothing itself
	for k in m.stock:
		OffMapSettlement._add(g.gov.granary, k, int(m.stock[k]))
	g.biz.erase("merchant")
	g.reopen_books()
	var lapse := int(OffMapSettlement.rules().food_lapse_days)
	for dd in range(d + 1, int(e.due) + lapse + 2):
		g.step_day(dd)
	check(g.transit.size() == 1 and str(w.transactions.get_shipment(str(e.tx)).state) == "open", "undeliverable: it stays open, awaited")
	check(int(r.tx_in_transit().goods.get("wheat", 0)) == int(e.n), "its goods still in custody, nothing lost")
	check(r.audit() == "", "audit holds (%s)" % r.audit())
	m.till = 0
	m.stock = {}
	g.biz["merchant"] = m
	g.reopen_books()
	g.step_day(int(e.due) + lapse + 2)
	check(g.transit.is_empty() and str(w.transactions.get_shipment(str(e.tx)).state) == "delivered", "with a trader again it is delivered, once")
	check(r.audit() == "", "audit holds (%s)" % r.audit())
	w.dispose()
	var w2 := _world()
	var r2 := w2.regions
	var g2: OffMapSettlement = r2.by_id["garton"]
	var hi2: OffMapSettlement = r2.by_id["higham"]
	r2.food_round(w2.day())
	var e2: Dictionary = g2.transit[0]
	var till := int(g2.trader().till)
	var wheat := int(hi2.biz.farm.stock.wheat)
	var f := r2.tx_fail(str(e2.tx), "the road was flooded")
	check(bool(f.ok) and int(g2.trader().till) == till + int(e2.coins) and int(hi2.biz.farm.stock.wheat) == wheat + int(e2.n), "fail: goods back to the farm, price back to the trader")
	g2.step_day(int(e2.due))
	check(g2.transit.is_empty() and int(g2.flows.food_delivered) == 0 and g2.journal.any(func(j): return "never arrived" in str(j.text)), "the settlement drops it and records that it never arrived")
	check(r2.audit() == "", "audit holds (%s)" % r2.audit())
	w2.dispose()


## A buyer whose people are all gone when the food arrives: delivered once to its trader, reported with no household left.
func test_abandoned_buyer() -> void:
	var w := _world()
	var r := w.regions
	var g: OffMapSettlement = r.by_id["garton"]
	var d := w.day()
	r.food_round(d)
	var n := int(g.transit[0].n)
	var due := int(g.transit[0].due)
	var events := []
	g.trade_hook = func(what, info): events.append([what, info])
	for h in g.hh:
		h.alive = false
	for dd in range(d + 1, due + 1):
		g.step_day(dd)
	check(g.transit.is_empty() and int(g.flows.food_delivered) == n, "the food still arrives, once")
	check(events.size() == 1 and int(events[0][1].households) == 0, "and the delivery reports no household left (recorded as interrupted)")
	check(r.audit() == "", "nothing lost (%s)" % r.audit())
	w.dispose()


func test_imported_not_resold() -> void:
	var w := _world()
	var r := w.regions
	var g: OffMapSettlement = r.by_id["garton"]
	r.food_round(w.day())
	g.day = int(g.transit[0].due)
	g._deliver()                                   # without the morning market taking it, to see the mark
	var have := int(g.trader().stock.get("wheat", 0))
	check(have > 0 and int(g.trader().imported.wheat) == have, "the delivered wheat is marked imported (%d)" % have)
	check(g.trader_has("wheat") == 0 and not g.sell_to_village("wheat", 1, 3), "it is not offered to the village's caravan")
	check(SettlementParty.make(r, g, "trader").sale_cap("wheat") == 0, "nor to another settlement")
	g.release_imported()
	check(g.trader_has("wheat") == have, "once the place is provided for it is ordinary stock")
	check(r.audit() == "", "audit holds")
	w.dispose()


## Many rounds into a place that grows no food: it buys what it can each round and may still decline and starve. That is an outcome;
## a leak, a duplicate, a negative stock, an orphaned shipment or food that never arrives would be a defect, and none occurs.
func test_repeated_trade_and_decline() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var r := w.regions
	var d0 := w.day()
	r.step_day(d0)
	var g: OffMapSettlement = r.by_id["garton"]
	for t in g.biz:
		g.biz[t].out = {}
		for f in g.food_items():
			g.biz[t].stock.erase(f)
	g.trader().till = 2000
	g.reopen_books()
	var pop0 := g.population()
	var rounds := 0
	var bad := ""
	for d in range(d0 + 1, d0 + 91):
		r.step_day(d)
		if r.food_last.get("day", -1) == d and r.food_last.lines.any(func(l): return str(l.buyer) == "garton/trader"):
			rounds += 1
		var a := r.audit()
		if a != "" and bad == "":
			bad = "day %d: %s" % [d, a]
		var gd := r.goods()
		for k in gd:
			if int(gd[k]) < 0 and bad == "":
				bad = "day %d: %d %s" % [d, int(gd[k]), k]
	var on_road := 0
	for e in g.transit:
		on_road += int(e.n)
	check(bad == "", "90 days of rounds: every audit holds, no negative stock, no orphaned shipment (%s)" % bad)
	check(rounds >= 3, "Garton bought food in %d rounds" % rounds)
	check(int(g.flows.food_delivered) + on_road == int(g.flows.food_bought), "every unit bought arrived once or is still on the road (%d bought, %d arrived, %d on the road)" % [int(g.flows.food_bought), int(g.flows.food_delivered), on_road])
	var sold := 0
	var bought := 0
	for s: OffMapSettlement in r.list:
		sold += int(s.flows.food_sold)
		bought += int(s.flows.food_bought)
	check(sold == bought, "units sold = units bought across the region (%d)" % sold)
	print("     outcome: Garton %d -> %d people, %d hunger deaths, %d units bought, %d unmet (an outcome, not a check)" % [pop0, g.population(), int(g.flows.deaths), int(g.flows.food_bought), int(g.flows.food_unmet)])
	w.dispose()


## Settlements with no world (a diagnostic) have no transaction authority: they buy nothing and change nothing by it.
func test_no_world_no_trade() -> void:
	var r := Regions.create(1)
	r.step_day(0)
	_short(r, "garton", 400)
	r.by_id["higham"].biz.farm.stock["wheat"] = 300
	r.by_id["higham"].reopen_books()
	var res := r.food_round(5)
	check(res.lines.is_empty() and res.unmet.any(func(u): return str(u.reason) == "no_authority") and r.audit() == "", "no authority, no purchase")


func test_determinism() -> void:
	check(_run(3) == _run(3), "two worlds of the same seed trade food identically over 60 days")


func _run(seed_: int) -> String:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	var r := w.regions
	var d0 := w.day()
	r.step_day(d0)
	_short(r, "garton", 600)
	for d in range(d0 + 1, d0 + 61):
		r.step_day(d)
	check(r.audit() == "", "seed %d: the region's audit holds (%s)" % [seed_, r.audit()])
	var out := JSON.stringify(r.to_dict()) + JSON.stringify(w.transactions.to_dict())
	w.dispose()
	return out


func test_recorder() -> void:
	var w := _world()
	var root := OS.get_cache_dir() + "/mml_settle_food_%d" % int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(root)
	var rec := WorldRecorder.attach(w, {"root": root})
	var r: Regions = w.regions
	var g: OffMapSettlement = r.by_id["garton"]
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
