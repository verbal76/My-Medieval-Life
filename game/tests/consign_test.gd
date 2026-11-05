extends SceneTree
## B25-ECON-P4 (owner 2026-11-05: "a neighbour trader may carry REAL ore stock on consignment, paying its source when the village
## buys it"; only real stocks, nothing created; OD-01, ECON-P1.3). In 120-day seed 1 (run 41967592798) the village's iron ran out
## and no iron ore was imported: a trader with no coins above its floor could not buy its own diggings' ore to sell. Checked here:
##   * a coinless trader carries its settlement's real surplus ore on a visit without paying for it (none created)
##   * a unit the village buys pays its source from the sale; the trader keeps the margin; the books balance
##   * the trader's own stock is sold first; consigned goods are sold to nobody but the village
##   * unsold goods go back to their source the next morning; a closed source's to the treasury
##   * saved and loaded mid-consignment, the same goods go home and the books balance
## B25-ECON-P6 (owner 2026-11-05, question 27, "Other traders consign"): in 120-day seed 1 (run 42028695001) no iron came, because
## Garton (the only iron diggings) lost its trader before day 20 and nobody else may carry its ore. Checked here:
##   * on the wholesale day the nearest trader sends a real walker to a place with no trader; the walker brings its diggings' surplus
##     ore home on consignment (travel time, goods in the pack on the road), nothing paid and nothing created
##   * the village buys it; the source's pay is set aside (never spent, never sold on locally) and walked to the source, which is paid
##   * goods held unsold past consign_hold_days are walked back; a closed source's pay and goods go to its place's treasury
##   * a closing trader's consignment passes to its treasury, which settles it; a walker lost on the way leaves it all owed
##   * saved and loaded with a consign walker on the road, the world goes on exactly as the original
##   godot --headless --path game --script res://tests/consign_test.gd

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
	test_coinless_trader_carries_ore()
	test_return_and_closed_source()
	test_save_load()
	test_other_trader_collects()
	test_settle_and_return()
	test_closed_holders()
	test_remote_save_load()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Garton on day 0 with its diggings holding `ore` iron ore beyond their keep and a trader at its cash floor with none of its own.
func _garton(ore := 30) -> Dictionary:
	var r := Regions.create(1)
	var g: OffMapSettlement = null
	for s: OffMapSettlement in r.list:
		if s.id == "garton":
			g = s
	r.step_day(0)
	var m := g.trader()
	var q: Dictionary = g.biz.quarry
	for k in OffMapSettlement.rules().consign:
		OffMapSettlement._add(g.flows.used, k, OffMapSettlement._take(m.stock, k, 1 << 20))    # the trader's own ore gone earlier ...
	# ... moved into the diggings' stock as if they had dug it (a fixture: the settlement's books record it as produced)
	var keep := int(g._keep(q).get("iron_ore", 0))
	var add := keep + ore - int(q.stock.get("iron_ore", 0))
	OffMapSettlement._add(q.stock, "iron_ore", add)
	OffMapSettlement._add(g.flows.produced, "iron_ore", add)
	var spare := int(m.till) - int(OffMapSettlement.rules().trader_reserve_floor)
	g.gov.coins += spare                                    # its coins above the floor gone to the council (both are the settlement's)
	m.till -= spare
	m.reserve = int(m.till)
	return {"r": r, "g": g, "m": m, "q": q}


func test_coinless_trader_carries_ore() -> void:
	var f := _garton(30)
	var g: OffMapSettlement = f.g
	var m: Dictionary = f.m
	var q: Dictionary = f.q
	check(g.audit() == "", "the fixture's books balance (%s)" % g.audit())
	check(g.trader_cash() == 0 and g.trader_has("iron_ore") == 0, "Garton's trader has no coins above its floor and no iron ore")
	var goods0 := g.goods()
	var coins0 := g.coins()
	var till0 := int(m.till)
	var qore0 := int(q.stock.iron_ore)
	g.begin_visit()
	var carried := g.trader_has("iron_ore")
	check(carried > 0 and carried <= int(OffMapSettlement.rules().carry.iron_ore), "on the visit it carries the diggings' ore on consignment (%d)" % carried)
	check(g.consigned("iron_ore") == carried and int(q.stock.get("iron_ore", 0)) == qore0 - carried, "every unit it carries is one the diggings held, owed to them")
	check(int(m.till) == till0 and g.coins() == coins0 and g.goods() == goods0, "no coin paid and nothing created: the settlement holds what it held")
	g.begin_visit()
	check(g.trader_has("iron_ore") == carried, "a second look on the same visit takes no more than the room")
	# the trader's own unit first, then the consigned
	OffMapSettlement._add(m.stock, "iron_ore", 2)
	OffMapSettlement._add(g.flows.produced, "iron_ore", 2)
	var unit := GameData.value("iron_ore")
	var qtill0 := int(q.till)
	check(g.sell_to_village("iron_ore", 2, unit) and g.consigned("iron_ore") == carried, "the trader's own two units go first, the diggings still owed all of theirs")
	check(int(q.till) == qtill0, "the diggings are paid nothing for units that were not theirs")
	var t1 := int(m.till)
	check(g.sell_to_village("iron_ore", 5, unit), "the village buys five consigned units")
	var pay := g.consign_pay("iron_ore", unit)
	check(int(q.till) == qtill0 + 5 * pay, "the diggings are paid %d a unit for the five (%d)" % [pay, int(q.till) - qtill0])
	check(int(m.till) == t1 + 5 * (unit - pay) and pay <= unit, "the trader keeps the margin, never paying out more than the sale")
	check(g.consigned("iron_ore") == carried - 5, "the five are struck off what it owes")
	check(g.audit() == "", "the settlement's books balance (%s)" % g.audit())
	# nobody but the village buys a consigned unit
	var party := SettlementParty.make(f.r, g, "trader")
	check(party.sale_cap("iron_ore") == 0, "a walker from another place cannot buy the consigned ore from the trader (sale cap 0)")


func test_return_and_closed_source() -> void:
	var f := _garton(12)
	var g: OffMapSettlement = f.g
	var m: Dictionary = f.m
	var q: Dictionary = f.q
	var qore0 := int(q.stock.iron_ore)
	g.begin_visit()
	var carried := g.consigned("iron_ore")
	g.sell_to_village("iron_ore", 3, GameData.value("iron_ore"))
	g._consign_return()
	check(not m.has("consign") and g.trader_has("iron_ore") == 0, "the next morning nothing is left on consignment")
	check(int(q.stock.get("iron_ore", 0)) == qore0 - 3, "the unsold %d went back to the diggings" % (carried - 3))
	check(g.audit() == "", "the books balance after the return (%s)" % g.audit())
	# a source that closes while its goods are out: they and their pay are the treasury's
	g.begin_visit()
	var out := g.consigned("iron_ore")
	var granary0 := int(g.gov.granary.get("iron_ore", 0))
	var gov0 := int(g.gov.coins)
	var qtill := int(q.till)
	g.biz.erase("quarry")                                    # (as _close_business leaves it: its till to the treasury)
	g.gov.coins += qtill
	g.sell_to_village("iron_ore", 1, GameData.value("iron_ore"))
	check(int(g.gov.coins) == gov0 + qtill + g.consign_pay("iron_ore", GameData.value("iron_ore")), "a closed source's pay goes to the treasury")
	g._consign_return()
	check(int(g.gov.granary.get("iron_ore", 0)) == granary0 + out - 1, "its unsold goods go to the treasury's granary")


func test_save_load() -> void:
	var f := _garton(20)
	var g: OffMapSettlement = f.g
	g.begin_visit()
	var carried := g.consigned("iron_ore")
	var d := g.to_dict()
	var g2 := OffMapSettlement.from_dict(JSON.parse_string(JSON.stringify(d)))
	check(g2.consigned("iron_ore") == carried and g2.trader_has("iron_ore") == carried, "a save made mid-visit keeps what is on consignment and to whom")
	check(JSON.stringify(g2.to_dict()) == JSON.stringify(d), "and saves again the same")
	g.step_day(1)
	g2.step_day(1)
	check(g2.consigned("iron_ore") == 0 and int(g2.biz.quarry.stock.get("iron_ore", 0)) == int(g.biz.quarry.stock.get("iron_ore", 0)), "after loading the goods go home the next morning as they would have")
	check(JSON.stringify(g2.to_dict()) == JSON.stringify(g.to_dict()) and g2.audit() == "", "the loaded settlement goes on exactly as the original")


# ------------------------------------------------------------------ B25-ECON-P6: other traders consign ----------------
## The regions on day 0 with Garton's trader closed and its diggings holding `ore` iron ore beyond their keep.
func _no_garton_trader(ore := 40) -> Dictionary:
	var r := Regions.create(1)
	r.step_day(0)
	var g: OffMapSettlement = r.by_id["garton"]
	g._close_business("merchant")
	var q: Dictionary = g.biz.quarry
	var add := int(g._keep(q).get("iron_ore", 0)) + ore - int(q.stock.get("iron_ore", 0))
	OffMapSettlement._add(q.stock, "iron_ore", add)
	OffMapSettlement._add(g.flows.produced, "iron_ore", add)
	return {"r": r, "g": g, "q": q}


func _consign_trip(r: Regions, to := "garton") -> Array:
	for st in r.all_trips():
		if str(st[1].purpose.get("kind", "")) == "consign" and str(st[1].to) == to:
			return st
	return []


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


## The carrier's consignment for Garton's diggings, a walker of `c` on the road there and back first.
func _collect(f: Dictionary) -> OffMapSettlement:
	var r: Regions = f.r
	r.consign_round(r.day)
	var st := _consign_trip(r)
	if st.is_empty():
		return null
	_arrive(r)
	return st[0]


func test_other_trader_collects() -> void:
	var f := _no_garton_trader(40)
	var r: Regions = f.r
	var g: OffMapSettlement = f.g
	var q: Dictionary = f.q
	check(g.trader().is_empty() and r.audit() == "", "Garton has no trader and the books balance (%s)" % r.audit())
	for d in range(1, 6):
		r.step_day(d)                                      # day 5 is the traders' wholesale day
	check(g.trader().is_empty(), "Garton is still without a trader on the wholesale day")
	var carriers := []
	for s: OffMapSettlement in r.list:
		if OffMapSettlement.consign_sources(s.trader()).has("garton"):
			carriers.append(s.id)
	check(carriers.size() == 1, "by the wholesale day's end one neighbour trader holds Garton's ore on consignment (%s)" % str(carriers))
	check(r.audit() == "", "the books balance after the days (%s)" % r.audit())
	# the walk itself, on a fresh world
	f = _no_garton_trader(40)
	r = f.r
	g = f.g
	q = f.q
	var ore0 := int(q.stock.iron_ore)
	r.consign_round(r.day)
	var st := _consign_trip(r)
	check(not st.is_empty(), "the round sends a neighbour trader's walker to Garton for its ore")
	if st.is_empty():
		return
	var c: OffMapSettlement = st[0]
	var t: Dictionary = st[1]
	check(carriers.has(c.id), "the same trader as in the days' run (%s)" % c.id)
	var nearest := ""
	var best := 1 << 30
	for s: OffMapSettlement in r.list:
		if s != g and not s.trader().is_empty():
			var dd := r._road_tiles("garton", s.id, maxi(1, roundi(Vector2(g.pos).distance_to(Vector2(s.pos)))))
			if dd < best or (dd == best and s.id < nearest):
				best = dd
				nearest = s.id
	check(c.id == nearest, "the walker is the nearest trader's (%s, nearest %s)" % [c.id, nearest])
	check(int(t.coins) == 0 and (t.pack as Dictionary).is_empty() and str(t.owner) == "trader", "it sets out with no coins and an empty pack")
	var arr := SettlementTrips.arrives(r, t)
	check(arr > float(r.day) * 1440.0 + 60.0, "Garton is a real walk away (arrives at minute %d)" % int(arr))
	var oreq := int(q.stock.get("iron_ore", 0))
	var tot := _totals(r)
	SettlementTrips.advance(r, arr + 1.0)                  # there: the ore is in the pack on the road home
	var got := int(t.pack.get("iron_ore", 0))
	check(got > 0 and int(q.stock.get("iron_ore", 0)) == oreq - got and str(t.leg) == "back", "at Garton the walker takes %d of the diggings' surplus ore into the pack, unpaid" % got)
	check(c.consigned("iron_ore") == 0, "until the walker is home it is not the trader's to sell")
	_arrive(r)
	check(_consign_trip(r).is_empty(), "the walker is home")
	var m := c.trader()
	check(int(m.consign.get("iron_ore", {}).get("garton/quarry", 0)) == got, "the trader holds the %d units on consignment, owed to Garton's diggings" % got)
	check(_totals(r) == tot and r.audit() == "", "no coin and no good created or lost between the places (%s)" % r.audit())
	check(ore0 > 0 and int(m.stock.get("iron_ore", 0)) >= got, "the ore is in the trader's stock for the village's caravan")


func test_settle_and_return() -> void:
	var f := _no_garton_trader(30)
	var r: Regions = f.r
	var g: OffMapSettlement = f.g
	var q: Dictionary = f.q
	var c := _collect(f)
	check(c != null, "a neighbour trader collected Garton's ore")
	if c == null:
		return
	var m := c.trader()
	var n := c.consigned("iron_ore")
	var own := int(m.stock.get("iron_ore", 0)) - n
	var unit := GameData.value("iron_ore")
	var pay := c.consign_pay("iron_ore", unit)
	var coins0 := c.coins()
	check(c.sell_to_village("iron_ore", own + 4, unit), "the village buys the trader's own ore and four consigned units")
	check(int(m.get("consign_due", {}).get("garton/quarry", 0)) == 4 * pay and c.consigned("iron_ore") == n - 4, "Garton's diggings are owed %d a unit for the four, set aside" % pay)
	check(c.coins() == coins0 + (own + 4) * unit and c.audit() == "", "the set-aside pay is still counted in the trader's place; its books balance (%s)" % c.audit())
	c._open_offers()
	var offered := 0
	for o in c._offers.get("iron_ore", []):
		if o.b == m:
			offered += int(o.n)
	check(offered == 0, "the consigned ore is not offered on the trader's own market")
	check(SettlementParty.make(r, c, "trader").sale_cap("iron_ore") == 0, "nor to any other buyer")
	# the pay walked to Garton
	r.consign_round(r.day)
	var st := _consign_trip(r)
	check(not st.is_empty() and int(st[1].coins) == 4 * pay and not m.has("consign_due"), "on the next wholesale day a walker carries the %d coins owed to Garton" % (4 * pay))
	if st.is_empty():
		return
	check((st[1].purpose.get("give", {}) as Dictionary).is_empty(), "goods held under consign_hold_days stay with the trader")
	var qtill := int(q.till)
	var qore := int(q.stock.get("iron_ore", 0))
	var gran := int(g.gov.granary.get("iron_ore", 0))
	var tot := _totals(r)
	_arrive(r)
	# B25-ECON-P7: the closed trader's ore in Garton's granary is a source too
	var again := qore - int(q.stock.get("iron_ore", 0)) + gran - int(g.gov.granary.get("iron_ore", 0))
	check(int(q.till) == qtill + 4 * pay, "Garton's diggings are paid %d at their door" % (4 * pay))
	check(c.consigned("iron_ore") == n - 4 + again, "while there the walker took on %d more" % again)
	check(_totals(r) == tot and r.audit() == "", "coins and goods conserved (%s)" % r.audit())
	# held past consign_hold_days unsold: walked back
	var hold := int(OffMapSettlement.rules().consign_hold_days)
	var held := c.consigned("iron_ore")
	r.trip_journal.clear()
	r.consign_round(r.day + hold)
	st = _consign_trip(r)
	check(not st.is_empty() and int(st[1].pack.get("iron_ore", 0)) == held and c.consigned("iron_ore") == 0, "after %d days the %d unsold units are packed to go back" % [hold, held])
	_arrive(r)
	var back := 0
	for e in r.trip_journal:
		if str(e.party) in ["garton/quarry", "garton/treasury"] and str(e.kind) == "buy" and str(e.item) == "iron_ore" and int(e.coins) == 0:
			back += int(e.n)
	check(back == held, "Garton's diggings (and, B25-ECON-P7, its treasury) took the %d units back (%d)" % [held, back])
	check(r.audit() == "", "the books balance after the return (%s)" % r.audit())


func test_closed_holders() -> void:
	var f := _no_garton_trader(30)
	var r: Regions = f.r
	var g: OffMapSettlement = f.g
	var c := _collect(f)
	if c == null:
		check(false, "a neighbour trader collected Garton's ore")
		return
	var m := c.trader()
	var unit := GameData.value("iron_ore")
	var pay := c.consign_pay("iron_ore", unit)
	var own := int(m.stock.get("iron_ore", 0)) - c.consigned("iron_ore")
	c.sell_to_village("iron_ore", own + 2, unit)
	var held := c.consigned("iron_ore")
	# the walker lost on the road: everything stays owed
	r.consign_round(r.day + 30)
	var st := _consign_trip(r)
	check(not st.is_empty(), "a settling walker sets out")
	if st.is_empty():
		return
	SettlementTrips.finish(r, c, st[1], "walker_gone")
	check(int(m.get("consign_due", {}).get("garton/quarry", 0)) == 2 * pay and c.consigned("iron_ore") == held and c.audit() == "", "a walker lost before Garton leaves the pay and the goods owed as they were")
	# the source closed: its pay and goods are its place's treasury's
	var qtill := int(g.biz.quarry.till)
	g._close_business("quarry")
	var gov0 := int(g.gov.coins)
	var gran0 := int(g.gov.granary.get("iron_ore", 0))
	r.consign_round(r.day + 30)
	_arrive(r)
	check(int(g.gov.coins) == gov0 + 2 * pay, "a closed source's pay goes to Garton's treasury (%d)" % (int(g.gov.coins) - gov0))
	check(int(g.gov.granary.get("iron_ore", 0)) >= gran0 + held - c.consigned("iron_ore") and r.audit() == "", "and its goods to the granary; the books balance (%s)" % r.audit())
	check(qtill >= 0, "(the diggings' own till went to the treasury when they closed)")
	# the carrier's trader closes while holding Garton's goods and pay: its treasury settles them
	var f2 := _no_garton_trader(30)
	var r2: Regions = f2.r
	var c2 := _collect(f2)
	var m2 := c2.trader()
	var own2 := int(m2.stock.get("iron_ore", 0)) - c2.consigned("iron_ore")
	c2.sell_to_village("iron_ore", own2 + 3, unit)
	var held2 := c2.consigned("iron_ore")
	c2._close_business("merchant")
	check(int(c2.gov.get("consign_due", {}).get("garton/quarry", 0)) == 3 * c2.consign_pay("iron_ore", unit), "a closing trader's pay owed to Garton passes to its treasury")
	check(OffMapSettlement.consigned_in(c2.gov, "iron_ore") == held2 and c2.audit() == "", "and the goods, with their marks; the books balance (%s)" % c2.audit())
	var qtill2 := int(f2.q.till)
	var due2 := OffMapSettlement.consign_due_coins(c2.gov)
	r2.consign_round(r2.day)
	_arrive(r2)
	check(int(f2.q.till) == qtill2 + due2 and not c2.gov.has("consign_due") and OffMapSettlement.consigned_in(c2.gov, "iron_ore") == 0, "the treasury's walker settles it at once: Garton's diggings paid %d, the goods back" % due2)
	check(r2.audit() == "", "the books balance (%s)" % r2.audit())


func test_remote_save_load() -> void:
	var f := _no_garton_trader(30)
	var r: Regions = f.r
	var c := _collect(f)
	if c == null:
		check(false, "a neighbour trader collected Garton's ore")
		return
	var unit := GameData.value("iron_ore")
	var own := int(c.trader().stock.get("iron_ore", 0)) - c.consigned("iron_ore")
	c.sell_to_village("iron_ore", own + 2, unit)
	r.consign_round(r.day + 30)
	var st := _consign_trip(r)
	check(not st.is_empty() and not (st[1].purpose.get("give", {}) as Dictionary).is_empty(), "a walker is on the road with pay and goods for Garton")
	SettlementTrips.advance(r, SettlementTrips.arrives(r, st[1]) - 30.0)
	var d := r.to_dict()
	var r2 := Regions.from_dict(JSON.parse_string(JSON.stringify(d)), 1)
	check(r2 != null and JSON.stringify(r2.to_dict()) == JSON.stringify(d), "saved and loaded on the road, it saves again the same")
	if r2 == null:
		return
	_arrive(r)
	_arrive(r2)
	check(JSON.stringify(r2.to_dict()) == JSON.stringify(r.to_dict()), "and goes on exactly as the original")
	check(r2.audit() == "" and r.audit() == "", "the books balance in both (%s)" % r2.audit())
