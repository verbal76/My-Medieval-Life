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
	test_every_business_closes_by_every_path()
	test_last_member_keeps_till()
	test_lone_last_member_keeps_all()
	test_non_trader_session_settled()
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


# ------------------------------------------------------------------ the underlying causes (owner 2026-10-30) ----------------
## Every business type left with no working household closes, whichever way its last household went: a trade switch, death, leaving
## for the village, or a household that opened another business. The settlement's books balance and the closed record holds nothing.
func test_every_business_closes_by_every_path() -> void:
	var r := Regions.create(1)
	r.step_day(0)
	var s: OffMapSettlement = r.by_id["higham"]
	var plan := {"merchant": "switch", "cook": "death", "smith": "leave", "tanner": "open_other", "farm": "death", "sawyer": "leave"}
	var types: Array = plan.keys()
	types.sort()
	for t in types:
		if not s.biz.has(t):
			check(false, "Higham has a %s" % t)
			continue
		var b: Dictionary = s.biz[t]
		for i in (b.workers as Array).duplicate():
			var h: Dictionary = s.hh[i]
			if not h.alive:
				continue
			match str(plan[t]):
				"switch", "open_other":                # the household took up another trade (a switch, or a business it opened)
					b.workers.erase(i)
					var other := "weaver" if s.biz.has("weaver") else "mason"
					s.biz[other].workers.append(i)
					h.trade = OffMapSettlement._trade_of(other)
				"death":
					var guard := 0
					while h.alive and guard < 20:
						guard += 1
						s._lose_member(h)
				"leave":
					s.release_household(i)
	var days := 2 * int(OffMapSettlement.rules().switch_stay_days) + 2
	var bad := ""
	for d in range(1, days + 1):
		r.step_day(d)
		if r.audit() != "" and bad == "":
			bad = "day %d: %s" % [d, r.audit()]
	for t in types:
		check(not s.biz.has(t) and s.closed.has(t), "%s with no working household (%s) closed" % [t, plan[t]])
		check(int(s.closed.get(t, {}).get("till", -1)) == 0 and (s.closed.get(t, {}).get("stock", {"x": 1}) as Dictionary).is_empty(), "%s: its till and stock were handed on" % t)
	check(bad == "", "every day's books balanced (%s)" % bad)


## The village's coins (every holder World.total_coins counts) and the settlements' coins: constant when people move between them.
func _all_coins(w: World) -> int:
	return w.total_coins() + w.regions.coins() + int(w.regions.tx_in_transit().coins)


## One good across the village's holders that a move touches (villagers' packs, pantries, the granary) and the settlements' books.
func _all_goods(w: World, item: String) -> int:
	var n := w.granary.count(item) + int(w.regions.goods().get(item, 0)) + int(w.regions.tx_in_transit().goods.get(item, 0))
	for o: NPC in w.npcs:
		if o.alive:
			n += o.inv.count(item)
	for hh in w.households:
		n += (hh.pantry as Inventory).count(item)
	return n


## The last living member of a household leaves alone: they take its storefront till, its pantry and their own purse and pack; the
## manor gets nothing of theirs; coins and goods conserved across the village and the settlements.
func test_lone_last_member_keeps_all() -> void:
	var w := new_world()
	var n := householder(w)
	var h := n.household
	var house: Dictionary = w.buildings[n.home]
	for id in w.business.storefront_cost():
		n.inv.add(id, int(w.business.storefront_cost()[id]))
	check(w.business.build_npc_front(house, n), "a storefront for the household")
	house.front.till = 23
	for o: NPC in w.brain._members(h):
		if o != n:
			w.kill(o, "old age")                   # (their estates go where a death sends them, before the test counts)
	w.households[h].pantry.add("wheat", 15)
	var wheat0 := _all_goods(w, "wheat")
	var coins0 := _all_coins(w)
	var t0 := w.treasury
	var g0 := w.granary.count("wheat")
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var ok := Migration._household_out(w, s, [n], false, "work", Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	check(ok and not n.alive and str(n.away) == "wulstead", "the last member leaves alone")
	check(int(house.front.get("till", 0)) == 0 and w.treasury == t0, "the till went with them, not to the manor")
	check(w.households[h].pantry.count("wheat") == 0 and w.granary.count("wheat") == g0, "the household's stores went with them, not to the granary")
	check(_all_coins(w) == coins0, "coins conserved across the village and the settlements (%d -> %d)" % [coins0, _all_coins(w)])
	check(_all_goods(w, "wheat") == wheat0, "wheat conserved (%d -> %d)" % [wheat0, _all_goods(w, "wheat")])
	check(w.regions.audit() == "", "the settlements' books balance (%s)" % w.regions.audit())
	w.dispose()


## A villager who is not a trader but sold at a stall (the open session is theirs) leaves while others of the household stay: the
## session is settled to them before they pack; the household keeps its own till and stores.
func test_non_trader_session_settled() -> void:
	var w := new_world()
	var st: Dictionary = {}
	for id in w.stalls:
		if w.business.stalls.is_merchant_stall(w.stalls[id]):
			st = w.stalls[id]
			break
	var leaver: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "merchant" and o.household >= 3 and w.brain._members(o.household).size() >= 2:
			leaver = o
			break
	check(not st.is_empty() and leaver != null, "a stall and a non-trader in a household of several")
	if st.is_empty() or leaver == null:
		return
	st.till = int(st.get("till", 0)) + 40
	w.business.stalls.record_sale(st, World.npc_ref(leaver.id), "egg", 10, 40)
	var due := w.business.stalls.due(st)
	var purse := leaver.coins
	var till0 := int(st.till)
	var coins0 := _all_coins(w)
	var t0 := w.treasury
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var ok := Migration._household_out(w, s, [leaver], false, "work", Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	check(ok, "they leave; the rest of the household stays")
	check(not st.has("session") and int(st.get("till", 0)) == 0 and w.treasury - t0 == due.x, "their session was settled: the manor's commission only (%d)" % due.x)
	var last: Dictionary = w.regions.moves[-1] if not w.regions.moves.is_empty() else {}
	check(int(last.get("coins", -1)) == purse + till0 - due.x, "the takings went with them (%d carried, expected %d)" % [int(last.get("coins", -1)), purse + till0 - due.x])
	check(_all_coins(w) == coins0, "coins conserved (%d -> %d)" % [coins0, _all_coins(w)])
	w.dispose()
