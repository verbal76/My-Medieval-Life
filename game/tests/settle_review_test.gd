extends SceneTree
## Build 24 review findings in the settlement layer (lead, 2026-10-30), each pinned by a test that failed before its fix:
##   1. a settlement trader nobody is left to work closes by the existing closing rule (OffMapSettlement._close_idle skipped the
##      merchant): its till goes to the council, its stock to the granary, and it trades no more;
##   2. TILL-D1: when the villagers leaving are everyone left in their household (a lone last member, a part move that empties it),
##      the household's storefront till goes with them, not to the manor (Migration._pre_leave -> BusinessMoney.keep_tills_of);
##   3. a market trader who leaves has their own stall session settled to them before they pack (Stalls.settle: the commission to
##      the manor, the rest to their purse, which goes with them), not to the manor an hour later.
##   godot --headless --path game --script res://tests/settle_review_test.gd

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
	test_idle_trader_closes()
	test_closing_trader_takes_in_shipments()
	test_last_member_keeps_till()
	test_leaving_trader_settles_stall()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 10.0 * 60.0
	return w


func test_idle_trader_closes() -> void:
	var r := Regions.create(1)
	r.step_day(0)
	var s: OffMapSettlement = r.by_id["netherton"]
	var m: Dictionary = s.trader()
	for i in m.workers:
		s.hh[i].trade = "farmer"                   # the trader's household took up farming (or left): nobody works the trade
	m.workers = []
	var till := int(m.till)
	var gov0 := int(s.gov.coins)
	var days := int(OffMapSettlement.rules().switch_stay_days) + int(OffMapSettlement.rules().switch_every_days) + 1
	for d in range(1, days + 1):
		r.step_day(d)
	check(s.trader().is_empty() and s.closed.has("merchant"), "a trader nobody works closes after %d days (by the closing rule)" % days)
	check(int(s.closed.get("merchant", {}).get("till", -1)) == 0 and (s.closed.get("merchant", {}).get("stock", {"x": 1}) as Dictionary).is_empty() and gov0 >= 0 and till >= 0,
		"its till went to the council and its stock to the granary (the closed record holds nothing)")
	check(s.trader_cash() == 0 and s.trader_has("wheat_seed") == 0 and not s.sell_to_village("wheat_seed", 1, 1), "and it trades no more")
	check(s.audit() == "" and r.audit() == "", "books balance (%s)" % r.audit())
	check(s.journal.any(func(j): return "closed" in str(j.text)), "the settlement records the closing")


## A trader that closes while food it bought is on the road: the shipment is delivered at once (the seller paid) and the food goes
## to the granary with the rest of its stock; nothing stays open waiting for a trader who is gone.
func test_closing_trader_takes_in_shipments() -> void:
	var w := new_world()
	var r := w.regions
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
	for s: OffMapSettlement in r.list:
		s.reopen_books()
	var res := r.food_round(w.day())
	check(not res.lines.is_empty() and g.transit.size() == 1, "Garton's trader bought food that is on the road")
	var e: Dictionary = g.transit[0].duplicate()
	var farm := int(hi.biz.farm.till)
	g._close_business("merchant")
	check(g.trader().is_empty() and g.transit.is_empty(), "the trader closes and nothing is left awaited")
	check(str(w.transactions.get_shipment(str(e.tx)).state) == "delivered" and int(hi.biz.farm.till) == farm + int(e.coins), "the shipment was delivered and the grower paid")
	check(int(g.gov.granary.get("wheat", 0)) >= int(e.n), "the food went to the granary with the trader's stock")
	check(r.audit() == "", "books balance (%s)" % r.audit())
	w.dispose()


## A household adult whose household holds their house and has room for a storefront.
func householder(w: World) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 3 and o.home != "" and w.buildings.has(o.home) \
				and w.holds(World.hh_ref(o.household), w.buildings[o.home]) and w.business.front_place(w.buildings[o.home]).size() > 0:
			return o
	return null


func test_last_member_keeps_till() -> void:
	var w := new_world()
	var n := householder(w)
	var h := n.household
	var house: Dictionary = w.buildings[n.home]
	for id in w.business.storefront_cost():
		n.inv.add(id, int(w.business.storefront_cost()[id]))
	check(w.business.build_npc_front(house, n), "a storefront for the household")
	house.front.till = 37
	var ms: Array = w.brain._members(h)
	var carried := 37
	for o: NPC in ms:
		carried += o.coins
	var src0 := w.coin_sources
	var t0 := w.treasury
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	# not a "whole household" move, but the leavers are everyone left in it
	var ok := Migration._household_out(w, s, ms, false, "work", Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	check(ok, "the household's members leave together (a part move that empties it)")
	check(int(house.front.get("till", 0)) == 0 and w.treasury == t0, "its storefront till went with them, not to the manor (treasury %d -> %d)" % [t0, w.treasury])
	check(src0 - w.coin_sources == carried, "the coins that crossed are their purses and the till (%d, expected %d)" % [src0 - w.coin_sources, carried])
	w.dispose()


func test_leaving_trader_settles_stall() -> void:
	var w := new_world()
	var m: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "merchant" and w.stalls.has(o.workplace) and w.business.stalls.is_merchant_stall(w.stalls[o.workplace]) \
				and w.tenant_of(w.stalls[o.workplace]) == World.npc_ref(o.id) and o.household >= 3:
			m = o
			break
	check(m != null, "a merchant with a market stall")
	if m == null:
		return
	var st: Dictionary = w.stalls[m.workplace]
	st.till = int(st.get("till", 0)) + 60
	w.business.stalls.record_sale(st, World.npc_ref(m.id), "wheat", 20, 60)
	var due := w.business.stalls.due(st)
	var ms: Array = w.brain._members(m.household)
	var purses := 0
	for o: NPC in ms:
		purses += o.coins
	var till := int(st.till)
	var src0 := w.coin_sources
	var t0 := w.treasury
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var ok := Migration._household_out(w, s, ms, true, "work", Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	check(ok, "the merchant's household leaves")
	check(int(st.get("till", 0)) == 0 and not st.has("session"), "the stall's session was settled before they went")
	check(w.treasury - t0 == due.x, "the manor took only its commission (%d), not the takings (treasury +%d)" % [due.x, w.treasury - t0])
	check(src0 - w.coin_sources == purses + till - due.x, "the rest went with them in the merchant's purse (%d crossed, expected %d)" % [src0 - w.coin_sources, purses + till - due.x])
	# an hour later nothing is left to escheat
	var t1 := w.treasury
	for i in 60:
		w.update(1.0)
	check(int(w.stats.get("stall_net_escheat", 0)) == 0, "nothing of theirs escheats to the manor afterwards (treasury %d -> %d)" % [t1, w.treasury])
	w.dispose()
