extends SceneTree
## Expansion 18, REG-PARTY-01 (owner Q18-10, 2026-10-21: "Anyone may purchase goods from another settlement, including
## individual villagers, households, merchants, businesses, and settlement treasuries"): one trading-party interface over the five
## settlements (SettlementParty), which RegionalMarket and CourierService use instead of the prospective SettlementLedger.
##   - every holder of every settlement is a party (trader, businesses, treasury, living households) and addresses by
##     "region:<settlement>/<holder>"; an unknown one is refused
##   - each holder kind buys from and sells to another settlement's holder, through RegionalMarket, moving the settlement's OWN
##     coins and goods; every transfer is a matched `regional_*` flow line on both settlements and OffMapSettlement.audit and
##     Regions.audit balance after every one
##   - the courier service's hand-overs are `outside_*` lines; a stepped day afterwards still balances
##   - deterministic: the same seed and the same rounds give the same books
##   godot --headless --path game --script res://tests/party_test.gd

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
	test_addressing()
	test_reads_and_writes_the_settlements_books()
	test_every_kind_buys_and_sells()
	test_carriage_and_refusals()
	test_outside_exchanges()
	test_unknown_refused()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world_total(r: Regions) -> Dictionary:
	return {"coins": r.coins(), "goods": r.goods()}


## A fresh set of settlements stepped a few days so tills, stocks and households are in their working state.
func founded(seed_ := 1, days := 4) -> Regions:
	var r := Regions.create(seed_)
	for d in days:
		r.step_day(d)
	return r


## The first household still living (REG-DEMO-01: a household can close in the first days, e.g. its only adult marries).
func _living_hh(s: OffMapSettlement) -> Dictionary:
	for h in s.hh:
		if h.alive:
			return h
	return {}


func test_addressing() -> void:
	var r := founded()
	var ps := r.parties()
	var kinds := {}
	for p: SettlementParty in ps:
		kinds[p.kind] = int(kinds.get(p.kind, 0)) + 1
	check(kinds.has("trader") and kinds.has("business") and kinds.has("treasury") and kinds.has("household"),
		"every holder kind is a party (%s)" % str(kinds))
	check(int(kinds.trader) == 5 and int(kinds.treasury) == 5, "five traders and five treasuries")
	var living := 0
	for s: OffMapSettlement in r.list:
		living += s.households()
	check(int(kinds.household) == living, "one party for each living household (%d)" % living)
	var ids := ps.map(func(p): return p.id)
	var sorted := ids.duplicate()
	sorted.sort()
	check(ids == sorted and ids.size() == ids.duplicate().size(), "listed in id order")
	var seen := {}
	for i in ids:
		seen[i] = true
	check(seen.size() == ids.size(), "every id is unique")
	var t := r.party("region:garton/trader")
	check(t != null and t.ref == "region:garton/trader" and t.settlement == "garton" and t.kind == "trader", "region:garton/trader names Garton's trader")
	check(r.party("garton/trader").id == t.id, "the prefix is optional")
	check(t.pos == r.by_id["garton"].pos, "and its place is the settlement's (%s)" % str(t.pos))
	var hh := r.party("garton/hh:%d" % _living_hh(r.by_id["garton"]).id)
	check(hh != null and hh.kind == "household", "a household is addressed by its id")
	var tr := r.party("garton/treasury")
	check(tr != null and tr.kind == "treasury", "the treasury is addressed as treasury")
	var b := ps.filter(func(p): return p.kind == "business" and p.settlement == "garton")
	check(not b.is_empty() and r.party("garton/" + b[0].holder).id == b[0].id, "a business by its type (%s)" % b[0].holder)


func test_reads_and_writes_the_settlements_books() -> void:
	var r := founded()
	var s: OffMapSettlement = r.by_id["garton"]
	var t := r.party("garton/trader")
	check(t.coins == int(s.trader().till) and t.purse() == t.coins, "the trader's coins are its till (%d)" % t.coins)
	var live := _living_hh(s)
	var h := r.party("garton/hh:%d" % int(live.id))
	check(h.purse() == int(live.coins) and h.held("wheat") == int(live.pantry.get("wheat", 0)), "a household's are its purse and pantry")
	check(r.party("garton/treasury").purse() == s.treasury(), "the treasury's are its coins")
	var g := r.party("garton/treasury")
	var g0: int = int(s.gov.granary.get("wheat", 0))
	check(g.add("wheat", 3) and int(s.gov.granary.get("wheat", 0)) == g0 + 3, "an add goes straight into the settlement's granary")
	check(g.remove("wheat", 3) and int(s.gov.granary.get("wheat", 0)) == g0, "and a remove out of it")
	check(not g.remove("wheat", 100000), "taking more than it holds is refused")
	check(not g.outside_coins(-1000000), "and paying more than it has")
	check(s.audit() == "", "the add and remove were `outside_*` lines: the settlement's audit balances (%s)" % s.audit())


func totals_of(ps: Array) -> Dictionary:
	var c := 0
	var g := {}
	for p: SettlementParty in ps:
		c += p.purse()
		var items := p.held_items()
		for k in items:
			g[k] = int(g.get(k, 0)) + int(items[k])
	return {"coins": c, "goods": g}


## Take every settlement's present books as the opening books (a hand-set purse or stock is outside the flow lines).
func _reopen(r: Regions) -> void:
	for s: OffMapSettlement in r.list:
		s.reopen_books()


func _set_stock(p: SettlementParty, item: String, n: int) -> void:
	var g: Dictionary = p._goods()
	if n > 0:
		g[item] = n
	else:
		g.erase(item)


func _set_purse(p: SettlementParty, c: int) -> void:
	var rec := p.record()
	rec[p._purse_key()] = c


func test_every_kind_buys_and_sells() -> void:
	# each holder kind as the SELLER of plank to a trader in another settlement and as the BUYER of iron_bar from a trader
	for kind in ["trader", "business", "treasury", "household"]:
		var r := founded()
		var sa: OffMapSettlement = r.by_id["garton"]
		var sb: OffMapSettlement = r.by_id["higham"]
		var mine: SettlementParty = null
		for p: SettlementParty in r.parties("garton"):
			if p.kind == kind:
				mine = p
				break
		var trader := r.party("higham/trader")
		check(mine != null, "[%s] Garton has one" % kind)
		# SELLER: a surplus of planks (no use for them: a sale cap that allows it) and a want at the other end
		var held_item := "plank"
		_set_stock(mine, held_item, 60)
		_reopen(r)
		_set_purse(trader, 400)
		_set_stock(trader, held_item, 0)
		_reopen(r)
		mine.refresh()
		trader.refresh()
		var cap := mine.sale_cap(held_item)
		check(cap >= 0, "[%s] it has a sale cap for what it holds (%d)" % [kind, cap])
		# the buyer wants planks: its need, the households of Higham use them from the basket; make the trader's want explicit
		trader.set_option("capabilities", {})
		var ledger := [mine, trader]
		var before := world_total(r)
		var p1 := _forced_plan(mine, trader, held_item, mini(cap if cap >= 0 else 60, 20), 3)
		var e := RegionalMarket.execute(p1, ledger, 5)
		if cap > 0:
			check(e.done.size() == 1 and e.refused.is_empty(), "[%s] as SELLER: its planks go to Higham's trader (%d)" % [kind, e.done.size()])
			check(mine.held(held_item) == 60 - int(p1.lines[0].units) and trader.held(held_item) == int(p1.lines[0].units),
				"[%s] and leave its holder, enter the buyer's" % kind)
			check(sa.flows.regional_out.get(held_item, 0) == int(p1.lines[0].units) and sb.flows.regional_in.get(held_item, 0) == int(p1.lines[0].units),
				"[%s] each settlement carries its `regional_*` goods line" % kind)
			check(sa.flows.regional_coins_in == int(p1.lines[0].total) and sb.flows.regional_coins_out == int(p1.lines[0].total),
				"[%s] and the matching coin line" % kind)
		else:
			check(e.done.is_empty(), "[%s] with nothing beyond what it keeps, nothing is sold" % kind)
		check(sa.audit() == "" and sb.audit() == "" and r.audit() == "", "[%s] both audits balance after the sale (%s)" % [kind, r.audit()])
		check(world_total(r) == before, "[%s] the five settlements hold the same coins and goods as before" % kind)
		check(RegionalMarket.matched(ledger) == "", "[%s] every transfer is matched" % kind)
		# BUYER: Higham's trader sells iron bars to this holder, which cannot reach it unless it travels or hires; the
		# conservation and refusal checks do not depend on carriage, so the exchange is applied as the market would
		var sell_item := "iron_bar"
		_set_stock(trader, sell_item, 30)
		_set_purse(mine, 300)
		_reopen(r)
		mine.refresh()
		trader.refresh()
		var line := {"seller": trader.id, "buyer": mine.id, "item": sell_item, "units": 6, "unit_price": RegionalMarket.ask(sell_item),
			"total": 6 * RegionalMarket.ask(sell_item), "carriage": "self", "carrier": "", "fee_each": 0, "fee_total": 0, "days": 1.0}
		var before2 := world_total(r)
		var e2 := RegionalMarket.execute({"lines": [line], "unmet": [], "lost": []}, [mine, trader], 6)
		check(e2.done.size() == 1, "[%s] as BUYER: it buys 6 iron bars from Higham's trader" % kind)
		check(mine.held(sell_item) == 6 and mine.purse() == 300 - int(line.total) and trader.held(sell_item) == 24,
			"[%s] goods in, coins out of its own purse" % kind)
		check(sa.audit() == "" and sb.audit() == "" and r.audit() == "" and world_total(r) == before2, "[%s] audits balance; nothing made or lost" % kind)
		check(RegionalMarket.matched([mine, trader]) == "", "[%s] matched" % kind)
		# a buyer that cannot pay is refused whole
		_set_purse(mine, 1)
		_reopen(r)
		var e3 := RegionalMarket.execute({"lines": [line], "unmet": [], "lost": []}, [mine, trader], 7)
		check(e3.done.is_empty() and e3.refused.size() == 1 and mine.purse() == 1 and r.audit() == "", "[%s] a buyer short of coins is refused and nothing moves" % kind)


## A one-line plan, as the market would make it, with a flat per-unit price.
func _forced_plan(seller: SettlementParty, buyer: SettlementParty, item: String, units: int, fee_each: int) -> Dictionary:
	var u: int = maxi(0, units)
	var ask := RegionalMarket.ask(item)
	if u == 0:
		return {"lines": [], "unmet": [], "lost": []}
	return {"lines": [{"seller": seller.id, "buyer": buyer.id, "item": item, "units": u, "unit_price": ask, "total": u * ask,
		"carriage": "self", "carrier": "", "fee_each": 0, "fee_total": 0, "days": 1.0}], "unmet": [], "lost": []}


func test_carriage_and_refusals() -> void:
	var r := founded()
	var sa: OffMapSettlement = r.by_id["garton"]
	var sb: OffMapSettlement = r.by_id["higham"]
	var seller := r.party("garton/trader")
	var buyer := r.party("higham/treasury")
	var carter := r.party("higham/trader")
	carter.set_option("carts_for_hire", true)
	_set_stock(seller, "plank", 80)
	_set_purse(buyer, 500)
	_set_purse(carter, 20)
	_reopen(r)
	seller.refresh()
	buyer.refresh()
	check(not buyer.can_travel and buyer.transport.carry == 0, "a treasury cannot travel: it must hire a carter")
	var ask := RegionalMarket.ask("plank")
	var line := {"seller": seller.id, "buyer": buyer.id, "item": "plank", "units": 10, "unit_price": ask, "total": 10 * ask,
		"carriage": "carter", "carrier": carter.id, "fee_each": 2, "fee_total": 20, "days": 1.0}
	var before := world_total(r)
	var plan := {"lines": [line], "unmet": [], "lost": []}
	var e := RegionalMarket.execute(plan, [seller, buyer, carter], 3)
	check(e.done.size() == 1, "a carter hauls for the treasury's coins")
	check(buyer.purse() == 500 - 10 * ask - 20 and carter.purse() == 40, "the fee goes from the buyer to the carter, the price to the seller")
	check(sa.flows.regional_coins_in == 10 * ask and sb.flows.regional_coins_out == 10 * ask, "Garton took the price; the fee stayed inside Higham (buyer and carter share a settlement): no flow line for it")
	check(sb.flows.regional_in.get("plank", 0) == 10 and sa.flows.regional_out.get("plank", 0) == 10, "the planks are matched lines")
	check(r.audit() == "" and world_total(r) == before and RegionalMarket.matched([seller, buyer, carter]) == "", "audits balance, matched, nothing made")
	# unknown carter, no goods, a plan referring to a party that is not there
	var missing := RegionalMarket.execute({"lines": [line.merged({"carrier": "higham/nobody"}, true)], "unmet": [], "lost": []}, [seller, buyer, carter], 4)
	check(missing.refused.size() == 1 and r.audit() == "", "a carter that is not there refuses the line whole")
	_set_stock(seller, "plank", 2)
	_reopen(r)
	var short := RegionalMarket.execute(plan, [seller, buyer, carter], 4)
	check(short.refused.size() == 1 and seller.held("plank") == 2, "a seller short of goods is refused whole")
	check(r.audit() == "", "and the books still balance")


func test_outside_exchanges() -> void:
	var r := founded()
	var s: OffMapSettlement = r.by_id["wulstead"]
	var p := r.party("wulstead/hh:1")
	var ledger := SettlementLedger.make({"id": "village/npc:9", "settlement": "village", "coins": 100, "stock": {"plank": 10}})
	var pantry0 := p.held("wheat")
	var c0 := p.purse()
	_set_stock(p, "plank", 5)
	s.reopen_books()
	var sold := p.deal("sell", ledger, "plank", 4, 8, 2)
	ledger.deal("buy", p, "plank", 4, 8, 2)
	check(sold and p.held("plank") == 1 and p.purse() == c0 + 8, "a party sells to a fixture party outside the five")
	check(int(s.flows.outside_out.get("plank", 0)) == 4 and int(s.flows.outside_coins_in) == 8, "as `outside_*` flow lines")
	check(s.audit() == "" and ledger.balanced() == "", "its audit and the ledger's both balance (%s %s)" % [s.audit(), ledger.balanced()])
	check(r.audit() == "", "and the five together")
	# a household in the same settlement trades with no flow line
	var q := r.party("wulstead/treasury")
	var out0: int = s.flows.regional_coins_in
	_set_stock(p, "plank", 5)
	s.reopen_books()
	p.deal("sell", q, "plank", 2, 6, 3)
	q.deal("buy", p, "plank", 2, 6, 3)
	check(s.flows.regional_coins_in == out0 and s.audit() == "", "an exchange inside one settlement moves its holders only: no flow line")
	check(p.journal.any(func(e): return e.kind == "sell" and e.with == q.id), "(it is in the party's journal)")


func test_unknown_refused() -> void:
	var r := founded()
	check(r.party("region:nowhere/trader") == null, "an unknown settlement is no party")
	check(r.party("region:garton/blacksmith") == null, "an unknown holder is no party")
	check(r.party("region:garton/hh:99999") == null and r.party("region:garton/hh:x") == null, "an unknown household is no party")
	check(r.party("garton") == null and r.party("") == null, "a bare settlement or an empty reference is none")
	var t := r.party("garton/trader")
	check(not t.deal("sell", r.party("higham/trader"), "plank", 1_000_000, 1, 0), "a sale of goods it does not hold is refused")
	check(not t.deal("buy", r.party("higham/trader"), "plank", 1, 1_000_000_000, 0), "a purchase it cannot pay for is refused")
	check(r.audit() == "" and r.journal.is_empty(), "and nothing was booked")
	var c := CourierService.new(null)
	c.regions[t.id] = t
	check(c.alive("region:garton/trader") and not c.alive("region:garton/nobody") and c.place_of("region:garton/trader") == "garton",
		"the courier service knows a party by the same reference and its place")


func test_determinism() -> void:
	var a := _market_rounds()
	var b := _market_rounds()
	check(a == b, "the same seed and rounds give the same books (%d bytes)" % a.length())
	var c := _market_rounds(2)
	check(c != a, "and another seed gives other ones")


## Five settlements, ten days, a regional market round every day over every holder; returns the books as text and checks the
## audit after each round.
func _market_rounds(seed_ := 1) -> String:
	var r := Regions.create(seed_)
	var routes := r.route_table()
	var trades := 0
	var bad := ""
	for d in 10:
		r.step_day(d)
		var ps := r.parties()
		var plan := RegionalMarket.plan(ps, routes)
		var e := RegionalMarket.execute(plan, ps, d)
		trades += e.done.size()
		if r.audit() != "" and bad == "":
			bad = "day %d: %s" % [d, r.audit()]
		if RegionalMarket.matched(ps, d) != "" and bad == "":
			bad = "day %d unmatched" % d
	if seed_ == 1:
		check(bad == "", "ten days of whole-region market rounds: every audit balances and every transfer is matched (%s; %d trades)" % [bad, trades])
	return JSON.stringify(r.to_dict(), "", true, true) + str(r.journal.size())
