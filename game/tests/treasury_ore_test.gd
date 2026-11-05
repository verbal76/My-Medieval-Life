extends SceneTree
## B25-ECON-P7 (owner 2026-11-05, "Recover stranded settlement treasury ore", docs/directives/2026-11-05_b25r1_treasury_ore_recovery.md):
## ore a closed quarry, mine or trader leaves in a settlement's treasury granary stays available to the economy through the existing
## consignment (B25-ECON-P4 own trader, B25-ECON-P6 neighbour traders): the treasury is one more consignment source ("treasury"),
## paid trader_pays_share when the village buys, its unsold goods walked or handed back; the granary keeps the working stock its own
## businesses' recipes need and another place's goods it holds. Checked here:
##   * a closed quarry's ore in the granary is carried by the place's own trader on a visit, a coinless trader too (no funds needed:
##     nothing is paid until the village buys); the village's purchase pays the treasury; the unsold goes back to the granary
##   * the granary keeps the smith's working stock and another place's goods it holds (local reserve protection)
##   * a closed trader's ore in the granary is collected by the nearest neighbour trader's walker, sold, and its pay walked to the
##     treasury; competing neighbours: one walker at a time, never more than the spare
##   * a collection that cannot be made (the granary emptied before the walker arrives) moves nothing and loses nothing
##   * saved and loaded with treasury ore in a walker's pack, the world goes on exactly as the original
##   * every step: coins and goods conserved across the places, Regions.audit clean
##   godot --headless --path game --script res://tests/treasury_ore_test.gd

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
	test_closed_quarry_own_trader()
	test_local_reserve()
	test_closed_trader_neighbour()
	test_competing_neighbours()
	test_own_trader_first_claim()
	test_failed_collection()
	test_save_load()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _totals(r: Regions) -> Array:
	var c := 0
	var g := {}
	for s: OffMapSettlement in r.list:
		c += s.coins()
		for k in s.goods():
			g[k] = int(g.get(k, 0)) + int(s.goods()[k])
	return [c, g]


func _arrive(r: Regions) -> void:
	SettlementTrips.advance(r, float(r.day + 100) * 1440.0)


func _consign_trips(r: Regions, to := "garton") -> Array:
	var out := []
	for st in r.all_trips():
		if str(st[1].purpose.get("kind", "")) == "consign" and str(st[1].to) == to:
			out.append(st)
	return out


## Garton's trader with no coins above its floor and no ore of its own; its quarry closed with `ore` iron ore, which (the trader
## unable to buy any) all goes to the treasury's granary.
func _closed_quarry(ore := 50) -> Dictionary:
	var r := Regions.create(1)
	r.step_day(0)
	var g: OffMapSettlement = r.by_id["garton"]
	var m := g.trader()
	for k in OffMapSettlement.rules().consign:
		OffMapSettlement._add(g.flows.used, k, OffMapSettlement._take(m.stock, k, 1 << 20))
	var spare := int(m.till) - int(OffMapSettlement.rules().trader_reserve_floor)
	g.gov.coins += spare
	m.till -= spare
	m.reserve = int(m.till)
	var q: Dictionary = g.biz.quarry
	var add := ore - int(q.stock.get("iron_ore", 0))
	OffMapSettlement._add(q.stock, "iron_ore", add)
	OffMapSettlement._add(g.flows.produced, "iron_ore", add)
	g._close_business("quarry")
	return {"r": r, "g": g, "m": m}


## Garton with no trader: its trader closed holding `ore` iron ore (to the granary), its quarry's stock down to its keep.
func _closed_trader(ore := 40) -> Dictionary:
	var r := Regions.create(1)
	r.step_day(0)
	var g: OffMapSettlement = r.by_id["garton"]
	var m := g.trader()
	var add := ore - int(m.stock.get("iron_ore", 0))
	OffMapSettlement._add(m.stock, "iron_ore", add)
	OffMapSettlement._add(g.flows.produced, "iron_ore", add)
	var q: Dictionary = g.biz.quarry
	for k in OffMapSettlement.rules().consign:
		var over := int(q.stock.get(k, 0)) - int(g._keep(q).get(k, 0))
		if over > 0:
			OffMapSettlement._add(g.flows.used, k, OffMapSettlement._take(q.stock, k, over))
	g._close_business("merchant")
	return {"r": r, "g": g}


func test_closed_quarry_own_trader() -> void:
	var f := _closed_quarry(50)
	var r: Regions = f.r
	var g: OffMapSettlement = f.g
	var m: Dictionary = f.m
	var gran0 := int(g.gov.granary.get("iron_ore", 0))
	check(not g.biz.has("quarry") and gran0 == 50 and g.trader_cash() == 0, "the closed quarry's 50 iron ore are in Garton's granary; its trader has no coins above its floor")
	check(r.audit() == "", "the fixture's books balance (%s)" % r.audit())
	var spare := g.granary_spare("iron_ore")
	var keep := int(g._keep(g.biz.smith).get("iron_ore", 0))
	check(spare == gran0 - keep and keep > 0, "the granary may let go %d: all but the smith's working stock of %d" % [spare, keep])
	var coins0 := g.coins()
	var goods0 := g.goods()
	var till0 := int(m.till)
	g.begin_visit()
	var carried := g.consigned("iron_ore")
	var room := int(OffMapSettlement.rules().carry.iron_ore)
	check(carried == mini(room, spare) and int(m.consign.iron_ore.get("treasury", 0)) == carried, "on a visit its own trader carries %d of it on consignment, owed to the treasury" % carried)
	check(int(g.gov.granary.get("iron_ore", 0)) == gran0 - carried, "taken from the granary, not created")
	check(int(m.till) == till0 and g.coins() == coins0 and g.goods() == goods0 and g.audit() == "", "no coin paid (a coinless trader carries it), the place holds what it held (%s)" % g.audit())
	var unit := GameData.value("iron_ore")
	var pay := g.consign_pay("iron_ore", unit)
	var gov0 := int(g.gov.coins)
	check(g.sell_to_village("iron_ore", 6, unit), "the village buys six units")
	check(int(g.gov.coins) == gov0 + 6 * pay and int(m.till) == till0 + 6 * (unit - pay), "the treasury is paid %d a unit, the trader keeps the margin" % pay)
	check(g.coins() == coins0 + 6 * unit and g.audit() == "", "Garton gains exactly the village's %d coins (%s)" % [6 * unit, g.audit()])
	check(SettlementParty.make(r, g, "trader").sale_cap("iron_ore") == 0, "the treasury's ore is sold to nobody but the village")
	g._consign_return()
	check(int(g.gov.granary.get("iron_ore", 0)) == gran0 - 6 and not m.has("consign") and g.audit() == "", "the next morning the unsold %d go back to the granary" % (carried - 6))


func test_local_reserve() -> void:
	var f := _closed_quarry(10)
	var g: OffMapSettlement = f.g
	var keep := int(g._keep(g.biz.smith).get("iron_ore", 0))
	check(int(g.gov.granary.get("iron_ore", 0)) == 10 and keep >= 10 and g.granary_spare("iron_ore") == 0, "10 units, under the smith's working stock of %d: nothing spare" % keep)
	g.begin_visit()
	check(g.consigned("iron_ore") == 0 and int(g.gov.granary.get("iron_ore", 0)) == 10, "its trader takes none of it")
	g._consign_return()
	# another place's goods the treasury holds to send home are not its to let go
	var f2 := _closed_quarry(keep + 20)
	var g2: OffMapSettlement = f2.g
	g2.gov["consign"] = {"iron_ore": {"higham/smith": 15}}       # (as _consign_to_treasury leaves them: in the granary, marked)
	check(g2.granary_spare("iron_ore") == 5, "of %d in the granary, %d the smith's and 15 Higham's: 5 spare (%d)" % [keep + 20, keep, g2.granary_spare("iron_ore")])
	g2.begin_visit()
	check(g2.consigned("iron_ore") == 5 and int(g2.gov.granary.get("iron_ore", 0)) == keep + 15, "its trader carries the 5; the smith's stock and Higham's goods stay")
	check(g2.granary_spare("coal") == maxi(0, int(g2.gov.granary.get("coal", 0)) - int(g2._keep(g2.biz.smith).get("coal", 0))), "coal by the same rule")
	check(g2.granary_spare("wheat") == 0 and g2.granary_spare("stone") == 0, "only the consignment goods (ore and coal), never food or stone")
	# the smith closed: nothing local needs the ore any more
	var f3 := _closed_quarry(10)
	var g3: OffMapSettlement = f3.g
	g3._close_business("smith")
	check(g3.granary_spare("iron_ore") == int(g3.gov.granary.get("iron_ore", 0)) and g3.granary_spare("iron_ore") >= 10, "with the smith closed all of it is spare (%d)" % g3.granary_spare("iron_ore"))


func test_closed_trader_neighbour() -> void:
	var f := _closed_trader(40)
	var r: Regions = f.r
	var g: OffMapSettlement = f.g
	var gran0 := int(g.gov.granary.get("iron_ore", 0))
	var spare := g.granary_spare("iron_ore")
	check(g.trader().is_empty() and gran0 >= 40 and spare > 0, "Garton's trader closed; its %d iron ore are in the granary (%d spare)" % [gran0, spare])
	check(r.audit() == "", "the books balance (%s)" % r.audit())
	var tot := _totals(r)
	r.consign_round(r.day)
	var sts := _consign_trips(r)
	check(sts.size() == 1, "the round sends one neighbour trader's walker to Garton")
	if sts.size() != 1:
		return
	var c: OffMapSettlement = sts[0][0]
	var t: Dictionary = sts[0][1]
	check(int(t.coins) == 0 and (t.pack as Dictionary).is_empty(), "it sets out with no coins (none needed) and an empty pack")
	SettlementTrips.advance(r, SettlementTrips.arrives(r, t) + 1.0)
	var got := int(t.pack.get("iron_ore", 0))
	check(got > 0 and got <= spare and int(g.gov.granary.get("iron_ore", 0)) == gran0 - got, "at Garton it takes %d of the granary's spare into the pack, unpaid" % got)
	check(_totals(r) == tot and r.audit() == "", "conserved on the road (%s)" % r.audit())
	_arrive(r)
	var m := c.trader()
	check(int(m.consign.get("iron_ore", {}).get("garton/treasury", 0)) == got, "home, %s's trader holds the %d units owed to Garton's treasury" % [c.id, got])
	check(_totals(r) == tot and r.audit() == "", "conserved home (%s)" % r.audit())
	var unit := GameData.value("iron_ore")
	var own := int(m.stock.get("iron_ore", 0)) - c.consigned("iron_ore")
	var pay := c.consign_pay("iron_ore", unit)
	check(c.sell_to_village("iron_ore", own + 3, unit) and int(m.consign_due.get("garton/treasury", 0)) == 3 * pay, "the village buys three; %d set aside for Garton's treasury" % (3 * pay))
	var gov0 := int(g.gov.coins)
	tot = _totals(r)
	r.consign_round(r.day)
	_arrive(r)
	check(int(g.gov.coins) == gov0 + 3 * pay and not m.has("consign_due"), "the next round's walker pays Garton's treasury the %d at its door" % (3 * pay))
	var again := c.consigned("iron_ore") - (got - 3)
	check(again >= 0 and _totals(r) == tot and r.audit() == "", "(collecting %d more while there) coins and goods conserved (%s)" % [again, r.audit()])
	# held past the hold: walked back to the granary
	var held := c.consigned("iron_ore")
	var gran1 := int(g.gov.granary.get("iron_ore", 0))
	r.consign_round(r.day + int(OffMapSettlement.rules().consign_hold_days))
	var back := _consign_trips(r)
	check(back.size() == 1 and int(back[0][1].pack.get("iron_ore", 0)) == held, "after the hold the %d unsold go back by walker" % held)
	SettlementTrips.advance(r, SettlementTrips.arrives(r, back[0][1]) + 1.0)
	check(int(g.gov.granary.get("iron_ore", 0)) >= gran1 + held - int(back[0][1].pack.get("iron_ore", 0)) and r.audit() == "", "into Garton's granary (%s)" % r.audit())


func test_competing_neighbours() -> void:
	var f := _closed_trader(100)
	var r: Regions = f.r
	var g: OffMapSettlement = f.g
	var spare := g.granary_spare("iron_ore")
	var room := int(OffMapSettlement.rules().carry.iron_ore)
	check(spare > room, "Garton's granary holds more spare iron ore (%d) than one trader has room for (%d)" % [spare, room])
	var tot := _totals(r)
	r.consign_round(r.day)
	r.consign_round(r.day)
	var sts := _consign_trips(r)
	var carriers := []
	for s: OffMapSettlement in r.list:
		if s != g and not s.trader().is_empty():
			carriers.append(s.id)
	check(carriers.size() >= 2, "more than one neighbour has a trader (%s)" % str(carriers))
	check(sts.size() == 1, "two rounds: one walker on the way, not one per trader (%d)" % sts.size())
	if sts.is_empty():
		return
	var nearest := ""
	var best := 1 << 30
	for s: OffMapSettlement in r.list:
		if s != g and not s.trader().is_empty():
			var dd := r._road_tiles("garton", s.id, maxi(1, roundi(Vector2(g.pos).distance_to(Vector2(s.pos)))))
			if dd < best or (dd == best and s.id < nearest):
				best = dd
				nearest = s.id
	var first: OffMapSettlement = sts[0][0]
	check(first.id == nearest, "the nearest trader's (%s)" % nearest)
	_arrive(r)
	var h1 := first.consigned("iron_ore")
	check(h1 > 0 and h1 <= room - (int(first.trader().stock.get("iron_ore", 0)) - h1), "it takes no more than its carry room (%d)" % h1)
	check(_totals(r) == tot and r.audit() == "", "conserved (%s)" % r.audit())
	# the next round: the first has no room left; the next nearest trader with room collects what is still spare
	var left := g.granary_spare("iron_ore")
	check(left == spare - h1, "%d still spare in the granary" % left)
	r.consign_round(r.day)
	var s2 := _consign_trips(r)
	check(s2.size() == 1 and s2[0][0] != first, "a second trader's walker goes (%s)" % (s2[0][0].id if not s2.is_empty() else "none"))
	if s2.is_empty():
		return
	_arrive(r)
	var h2: int = s2[0][0].consigned("iron_ore")
	check(h2 > 0 and h2 <= left and first.consigned("iron_ore") == h1, "it takes %d of the %d left, never the first's units" % [h2, left])
	check(int(g.gov.granary.get("iron_ore", 0)) == int(g._keep(g.biz.smith).get("iron_ore", 0)) + spare - h1 - h2, "the granary lost exactly what the two carry; the smith's stock stays")
	check(_totals(r) == tot and r.audit() == "", "conserved (%s)" % r.audit())


## Owner decision 32 with B25-ECON-P7: a place WITH a trader keeps its trader's first claim on its granary ore, as much as it can
## carry; a neighbour's walker may take only the rest.
func test_own_trader_first_claim() -> void:
	var f := _closed_quarry(100)
	var r: Regions = f.r
	var g: OffMapSettlement = f.g
	var m: Dictionary = f.m
	var room := int(OffMapSettlement.rules().carry.iron_ore) - int(m.stock.get("iron_ore", 0))
	var spare := g.granary_spare("iron_ore")
	check(spare > room and g.consign_spare("iron_ore") == spare - room, "Garton keeps its own trader's room (%d) of the granary's %d spare; %d open to neighbours" % [room, spare, g.consign_spare("iron_ore")])
	var tot := _totals(r)
	r.consign_round(r.day)
	var sts := _consign_trips(r)
	check(sts.size() == 1, "a neighbour's walker goes for the rest")
	if sts.is_empty():
		return
	_arrive(r)
	var c: OffMapSettlement = sts[0][0]
	var got := int((c.trader().get("consign", {}) as Dictionary).get("iron_ore", {}).get("garton/treasury", 0))
	check(got > 0 and got <= spare - room, "it takes %d, never the own trader's share" % got)
	check(g.granary_spare("iron_ore") >= room, "the own trader's share is still in the granary (%d)" % g.granary_spare("iron_ore"))
	g.begin_visit()
	check(int(m.consign.get("iron_ore", {}).get("treasury", 0)) == room, "and its own trader carries it on the next visit (%d)" % room)
	check(_totals(r) == tot and r.audit() == "", "conserved (%s)" % r.audit())


func test_failed_collection() -> void:
	var f := _closed_trader(40)
	var r: Regions = f.r
	var g: OffMapSettlement = f.g
	r.consign_round(r.day)
	var sts := _consign_trips(r)
	check(sts.size() == 1, "a walker sets out for the granary's ore")
	if sts.is_empty():
		return
	# before it arrives the ore is gone (say the reopened smith's), all but the protected stock
	var spare := g.granary_spare("iron_ore")
	OffMapSettlement._add(g.flows.used, "iron_ore", OffMapSettlement._take(g.gov.granary, "iron_ore", spare))
	var tot := _totals(r)
	var gov0 := int(g.gov.coins)
	var gran0 := int(g.gov.granary.get("iron_ore", 0))
	_arrive(r)
	var c: OffMapSettlement = sts[0][0]
	check(c.consigned("iron_ore") == 0 and int(g.gov.granary.get("iron_ore", 0)) == gran0, "the walker comes home empty; the protected stock stays")
	check(int(g.gov.coins) == gov0 and _totals(r) == tot and r.audit() == "", "nothing paid, nothing lost (%s)" % r.audit())
	# a walker lost on the way home: the treasury's goods in the pack are still owed to it
	var f2 := _closed_trader(40)
	var r2: Regions = f2.r
	r2.consign_round(r2.day)
	var st2 := _consign_trips(r2)
	if st2.is_empty():
		check(false, "a walker sets out (second world)")
		return
	SettlementTrips.advance(r2, SettlementTrips.arrives(r2, st2[0][1]) + 1.0)
	var got := int(st2[0][1].pack.get("iron_ore", 0))
	var tot2 := _totals(r2)
	SettlementTrips.finish(r2, st2[0][0], st2[0][1], "walker_gone")
	check(got > 0 and int(st2[0][0].trader().consign.iron_ore.get("garton/treasury", 0)) == got, "a walker lost on the road home: the %d units stay owed to Garton's treasury" % got)
	check(_totals(r2) == tot2 and r2.audit() == "", "conserved (%s)" % r2.audit())


func test_save_load() -> void:
	var f := _closed_trader(40)
	var r: Regions = f.r
	r.consign_round(r.day)
	var sts := _consign_trips(r)
	if sts.is_empty():
		check(false, "a walker sets out")
		return
	SettlementTrips.advance(r, SettlementTrips.arrives(r, sts[0][1]) + 30.0)
	check(int(sts[0][1].pack.get("iron_ore", 0)) > 0, "treasury ore in the walker's pack on the road home")
	var d := r.to_dict()
	var r2 := Regions.from_dict(JSON.parse_string(JSON.stringify(d)), 1)
	check(r2 != null and JSON.stringify(r2.to_dict()) == JSON.stringify(d), "saved and loaded on the road, it saves again the same")
	if r2 == null:
		return
	_arrive(r)
	_arrive(r2)
	for k in 6:
		r.step_day(r.day + 1)
		r2.step_day(r2.day + 1)
	check(JSON.stringify(r2.to_dict()) == JSON.stringify(r.to_dict()), "and goes on exactly as the original for six days")
	check(r2.audit() == "" and r.audit() == "", "the books balance in both (%s)" % r2.audit())
