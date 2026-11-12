extends SceneTree
## TRD-04 (Build 25 audit, WP-1): a shipment (EconTransactions.ship: goods in custody, price in escrow) closes by deliver, fail or
## settle_estate. The audit asked about one neither end can take. Reachability, from the code:
## - capped stores: only settlement parties ship (Regions.tx_ship), and a settlement party can hold any amount while it stands
##   (SettlementParty.can_hold is alive()), so "no room" at both ends cannot happen;
## - a party gone: deliver and fail both need both parties, and Regions._arrive (the settlement's daily ask, OffMapSettlement._deliver)
##   never called settle_estate, the LE-04 rule for "a settlement party dissolved". A shipment whose seller's business closed
##   (OffMapSettlement._close_business) while it was on the road was asked again every day for ever: goods in custody, coins in escrow.
##   The food trade now walks (SettlementTrips) and nothing ships new lines (Regions.ship_line, await_shipment have no caller), but a
##   save made with one on the road (Build 24 and earlier) loads it (OffMapSettlement.load_dict restores transit).
## The test makes that shipment, closes the seller, saves and loads, and asks for it on its due day (it waits) and once the lapse
## has passed (food_lapse_days): it must then be settled to the estates (goods to the seller's estate, the price back to the buyer),
## with every coin and every unit of wheat accounted for across the save.
##   godot --headless --path game --script res://tests/trd04_stranded_shipment_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_seller_gone()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Coins and wheat of the region with the authority's custody, escrow and outside flows: what conservation must keep.
func totals(w: World) -> Array:
	var r := w.regions
	var t: Dictionary = w.transactions.in_transit()
	var wheat := int(r.goods().get("wheat", 0)) + int(t.goods.get("wheat", 0)) + int(w.transactions.sunk.get("wheat", 0))
	return [r.coins() + int(t.coins) + int(w.transactions.outside_coins), wheat]


func test_seller_gone() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var r: Regions = w.regions
	r.step_day(w.day())
	var g: OffMapSettlement = r.by_id["garton"]
	var hi: OffMapSettlement = r.by_id["higham"]
	hi.biz.farm.stock["wheat"] = int(hi.biz.farm.stock.get("wheat", 0)) + 50
	g.trader().till = int(g.trader().till) + 400
	g.reopen_books()
	hi.reopen_books()
	var d := w.day()
	var tx := "settle_food/garton:900"
	var s: Dictionary = r.tx_ship(tx, "region:garton/trader", "region:higham/farm", "wheat", 10, 40, d + 1)
	check(bool(s.ok), "fixture: Garton's trader buys 10 wheat from Higham's farm for 40 coins, due day %d (%s)" % [d + 1, str(s.get("code", ""))])
	if not bool(s.ok):
		return
	g.await_shipment(tx, "trader", "wheat", 10, "region:higham/farm", d, d + 1, 40)
	var before := totals(w)
	hi._close_business("farm")                      # nobody left to work it: the farm closes while the wheat is on the road
	check(totals(w) == before, "fixture: the farm's closing moves nothing out of the books (%s, %s)" % [str(before), str(totals(w))])
	check(r.authority().get_shipment(tx).state == "open", "fixture: the shipment is still on the road")
	# saved and loaded with it on the road
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var r2 := w2.regions
	var g2: OffMapSettlement = r2.by_id["garton"]
	check(g2.transit.size() == 1 and w2.transactions.get_shipment(tx).get("state", "") == "open" and totals(w2) == before,
		"saved and loaded: the settlement still awaits it and every coin and unit is there (%s)" % str(totals(w2)))
	var till := int(g2.trader().till)
	g2.day = d + 1
	g2._deliver()
	check(g2.transit.size() == 1 and w2.transactions.get_shipment(tx).state == "open", "on its due day, with the seller gone, it waits (asked again the next day)")
	var lapse := int(OffMapSettlement.rules().get("food_lapse_days", 6))
	g2.day = d + 1 + lapse
	g2._deliver()
	var sh: Dictionary = w2.transactions.get_shipment(tx)
	check(str(sh.get("state", "")) != "open", "once %d days late it is closed, not asked for again for ever (state %s)" % [lapse, str(sh.get("state", ""))])
	check(g2.transit.is_empty(), "the settlement no longer awaits it")
	check(int(g2.trader().till) == till + 40, "the price comes back to Garton's trader (%d -> %d)" % [till, int(g2.trader().till)])
	check(totals(w2) == before, "no coin and no wheat is lost or made over the save and the settlement (%s, %s)" % [str(before), str(totals(w2))])
	check(r2.audit() == "", "the region's audit holds (%s)" % r2.audit())
	w.dispose()
	w2.dispose()
