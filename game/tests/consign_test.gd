extends SceneTree
## B25-ECON-P4 (owner 2026-11-05: "a neighbour trader may carry REAL ore stock on consignment, paying its source when the village
## buys it"; only real stocks, nothing created; OD-01, ECON-P1.3). In 120-day seed 1 (run 41967592798) the village's iron ran out
## and no iron ore was imported: a trader with no coins above its floor could not buy its own diggings' ore to sell. Checked here:
##   * a coinless trader carries its settlement's real surplus ore on a visit without paying for it (none created)
##   * a unit the village buys pays its source from the sale; the trader keeps the margin; the books balance
##   * the trader's own stock is sold first; consigned goods are sold to nobody but the village
##   * unsold goods go back to their source the next morning; a closed source's to the treasury
##   * saved and loaded mid-consignment, the same goods go home and the books balance
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
