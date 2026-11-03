extends SceneTree
## REGION-NAV-01 S6, independent trade (plan AD-6). Acceptance (plan, S6): no forced trade; refusal; goods sold before arrival;
## funds limit; conservation; no instant transfer. Pure World. Run headless:
##   godot --headless --path game --script res://tests/region_trade_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _run(w: World, cond: Callable, max_minutes: float) -> bool:
	var until := w.minutes + max_minutes
	while w.minutes < until:
		w.update(0.5)
		if cond.call():
			return true
	return false


func coin_gap(w: World) -> int:
	return w.total_coins() + w.regions.coins() - (w.coin_sources + w.regions.net_paid_by_village())


## A keeper at Wulstead with something to sell, and a village adult free to go: [person, item, buyer].
func _seller(w: World) -> Array:
	for p in SettlementFolk.people(w, "wulstead"):
		if str(p.role) != "keeper" or not SettlementFolk.present(w, p):
			continue
		var o := SettlementFolk.offers(w, p)
		for line in o.sells:
			if int(line.n) >= 2 and int(line.price) > 0:
				return [p, str(line.item), int(line.price)]
	return []


func _adult(w: World, but: Array = []) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.home != "" and not n.job in ["guard", "reeve", "manor_hand", "sage"] and not but.has(n):
			return n
	return null


func _rec(p: Dictionary, item: String, side: String, qty: int, price: int, day: int) -> Dictionary:
	return {"about": str(p.ref), "person": str(p.name), "role": str(p.role), "place": str(p.settlement), "item": item, "side": side, "qty": qty,
		"price": price, "kind": "confirmed", "told_by": "npc:0", "collected_day": day, "heard_day": day}


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 3.0 * 1440.0 + 7.0 * 60.0
	w.regions.catch_up(w.day())
	w.minutes = 3.0 * 1440.0 + 11.0 * 60.0
	return w


func _init() -> void:
	_test_no_forced_trade()
	_test_buy_in_person()
	_test_sold_before_arrival()
	_test_sale_refused()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_no_forced_trade() -> void:
	var w := _world()
	var n := _adult(w)
	check(RegionTrade.consider(w, n) == "" and not Journeys.active(n), "with nothing told, nobody trades with the neighbours")
	var s := _seller(w)
	n.intel = [_rec(s[0], s[1], "have", 4, s[2], w.day() - 30)]
	check(RegionTrade.best_buy(w, n).is_empty(), "a stale record is not acted on")
	n.intel = [_rec(s[0], s[1], "have", 4, s[2], w.day())]
	n.coins = w.reserve_of(n)
	check(RegionTrade.best_buy(w, n).is_empty(), "with no coins above their reserve, nobody sets out to buy (funds limit)")
	RegionTrade.dawn(w)
	var any := false
	for o: NPC in w.npcs:
		if Journeys.active(o) and str(o.journey.get("purpose", {}).get("kind", "")) == "buy" and not bool(o.journey.purpose.get("seed", false)):     # (B25R1-009: the founding's seed travellers are not sent by RegionTrade)
			any = true
	check(not any, "a dawn with nothing worth it sends nobody (no forced trade)")


func _test_buy_in_person() -> void:
	var w := _world()
	var s := _seller(w)
	check(not s.is_empty(), "a Wulstead keeper has goods to sell (%s at %s)" % [s[1] if not s.is_empty() else "-", s[2] if not s.is_empty() else "-"])
	var p: Dictionary = s[0]
	var item: String = s[1]
	var n := _adult(w)
	n.coins = w.reserve_of(n) + 3 * int(s[2])                 # enough for three, not for four
	var gap0 := coin_gap(w)
	var have0 := n.inv.count(item)
	var party: SettlementParty = w.regions.party(str(p.ref))
	var cap0 := party.sale_cap(item)
	check(Journeys.start(w, n, "wulstead", {"kind": "buy", "about": str(p.ref), "item": item, "qty": 4, "price": int(s[2])}) == "", "%s sets out to buy %s at Wulstead" % [n.name, item])
	w.update(0.5)
	check(n.inv.count(item) == have0, "nothing arrives at once: the goods are at Wulstead until fetched")
	var stat := "region_trade_bought_" + item
	var bought := _run(w, func() -> bool: return float(w.stats.get(stat, 0.0)) > 0.0, 3 * 1440.0)
	check(bought and not w.map.overworld.site_at(n.cell()).is_empty(), "bought at Wulstead's site, in person (day %d, at %s)" % [w.day(), n.cell()])
	var got := int(w.stats.get(stat, 0.0))
	check(party.sale_cap(item) <= cap0 - got, "from the keeper's own stock (%d to sell now, %d before)" % [party.sale_cap(item), cap0])
	check(coin_gap(w) == gap0 and w.regions.audit() == "", "coins conserved across the boundary (gap %d, was %d); the settlements' books balance" % [coin_gap(w), gap0])
	check(_run(w, func() -> bool: return not Journeys.active(n), 3 * 1440.0) and n.inv.count(item) >= have0 + got - 0, "they carry it home")


## At the seller's side, at the moment of the trade: [world, buyer, person, item, price], the buyer standing at the person's door
## at 11:00 with a buying purpose for 4.
func _at_seller() -> Array:
	var w := _world()
	var s := _seller(w)
	var p: Dictionary = s[0]
	var n := _adult(w)
	n.journey = {"to": "wulstead", "purpose": {"kind": "buy", "about": str(p.ref), "item": s[1], "qty": 4, "price": int(s[2])}, "leg": "there", "since": w.day(), "gate": 0}
	n.pos = Vector2(p.spot) + Vector2(0.5, 1.5)
	n.intel = [_rec(p, s[1], "have", 4, int(s[2]), w.day())]
	return [w, n, p, s[1], int(s[2])]


func _test_sold_before_arrival() -> void:
	# funds limit: a purse holding three's price above its reserve buys three of the four wanted
	var x := _at_seller()
	var w: World = x[0]
	var n: NPC = x[1]
	var price: int = (w.regions.by_id["wulstead"] as OffMapSettlement).price(str(x[3]))
	n.coins = w.reserve_of(n) + 3 * price
	var gap0 := coin_gap(w)
	RegionTrade.act_buy(w, n)
	check(int(w.stats.get("region_trade_bought_" + str(x[3]), 0.0)) == 3 and n.coins == w.reserve_of(n) and coin_gap(w) == gap0, "funds limit: a purse with three's price above its reserve buys three of the four wanted, and keeps its reserve")
	# sold before arrival: the person's stock was bought up by someone else before the buyer stood at their door
	var y := _at_seller()
	w = y[0]
	n = y[1]
	var p: Dictionary = y[2]
	var item: String = y[3]
	n.coins = w.reserve_of(n) + 50
	var party: SettlementParty = w.regions.party(str(p.ref))
	var other := _adult(w, [n])
	w.treasury -= 200
	other.coins += 200
	var cap := party.sale_cap(item)
	var why := SettlementFolk.buy_from(w, World.npc_ref(other.id), p, item, cap) if cap > 0 else "nothing"
	check(why == "" and party.sale_cap(item) <= 0, "someone else bought all %d of it first" % cap)
	var c0 := n.coins
	gap0 = coin_gap(w)
	RegionTrade.act_buy(w, n)
	check(float(w.stats.get("region_trade_bought_" + item, 0.0)) == 0.0 and n.coins == c0, "sold before they came: nothing bought, nothing paid")
	check(n.intel.any(func(r): return str(r.kind) == "out_of_date"), "and they know the record is out of date (%s)" % str(n.intel[0].get("why", "")))
	check(coin_gap(w) == gap0 and w.regions.audit() == "", "coins conserved")
	# a buyer not at the person's door trades nothing (face to face only)
	var z := _at_seller()
	w = z[0]
	n = z[1]
	n.coins = w.reserve_of(n) + 50
	n.pos = Vector2(60, 60)
	RegionTrade.act_buy(w, n)
	check(float(w.stats.get("region_trade_bought_" + str(z[3]), 0.0)) == 0.0, "a buyer who is not at the seller's door buys nothing: no trade from afar")


func _test_sale_refused() -> void:
	var w := _world()
	var cs: CourierService = w.couriers
	_run(w, func() -> bool: return not cs.booth_of("village").is_empty() and cs.alive(str(cs.booth_of("village").keeper)), 2 * 1440.0)
	var maker: NPC = null
	var item := ""
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and not NPCBrain.TRADE_GOODS.get(o.job, []).is_empty() and o != w.npc(int(str(cs.booth_of("village").get("keeper", "npc:-1")).substr(4))):
			maker = o
			item = str(NPCBrain.TRADE_GOODS[o.job][0])
			break
	check(maker != null, "a village maker of %s (%s)" % [item, maker.name if maker else "-"])
	var keeper := {}
	for p in SettlementFolk.people(w, "wulstead"):
		if str(p.role) == "keeper":
			keeper = p
			break
	maker.inv.add(item, 4)
	var gap0 := coin_gap(w)
	var have0 := maker.inv.count(item)
	var told: int = 3 * (w.regions.by_id["wulstead"] as OffMapSettlement).price(item) + 1
	maker.intel = [_rec(keeper, item, "want", 4, told, w.day())]      # told a price well above what the place will pay now
	check(RegionTrade.sell(w, maker), "%s sends %s to %s by the courier's route, asking the price they were told (%d each)" % [maker.name, item, keeper.name, told])
	var job: Dictionary = cs.jobs[cs.jobs.size() - 1]
	var sent := int(job.items.get(item, 0))
	check(sent > 0 and maker.inv.count(item) == have0 - sent, "the goods leave them when booked, into the courier's care (not at once to the buyer; %d sent)" % sent)
	_run(w, func() -> bool: return str(job.state) in ["returned", "fulfilled"] or str(job.outcome) != "", 6 * 1440.0)
	check(str(job.outcome) == "no longer wanted", "the buyer's books will not pay that: refused on arrival (%s)" % str(job.outcome))
	_run(w, func() -> bool: return str(job.state) in ["returned", "fulfilled"], 6 * 1440.0)
	check(str(job.state) == "returned" and int((job.returned_items as Dictionary).get(item, 0)) == sent, "the goods come back to the sender (%d %s returned)" % [int((job.returned_items as Dictionary).get(item, 0)), item])
	check(coin_gap(w) == gap0 and w.regions.audit() == "", "coins conserved; the settlements' books balance")
