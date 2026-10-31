extends SceneTree
## Expansion 20 LE-04 (design s.17 "Organic finance, merchants and manor behavior", gate "Costs, default and refusal paths"):
## the transaction authority's village parties (the manor, a household, the chapel, tills), the manor buying and commissioning
## tools through the economy (a CON-01 contract the smith may accept, counter or refuse; escrow, delivery, lapse), conservation,
## saves, and the switch. Nothing asserts that anyone prospers.
## Run headless:  godot --headless --path game --script res://tests/le04_test.gd

const Census := preload("res://tests/census.gd")
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(on := true, drive := true) -> World:
	if on:
		var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		c.enabled = true
		c.market.drive = drive
		EconomyFoundation.set_override(c)
	else:
		EconomyFoundation.set_override({})
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_village_parties()
	test_manor_buys_tool()
	test_manor_commissions_tool()
	test_commission_refused_and_lapsed()
	test_business_accounts()
	test_estate_claims()
	test_speculation()
	test_negotiated_wages()
	test_settle_estate()
	test_replay_after_load()
	test_switch()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func adult(w: World, job := "") -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and (job == "" or n.job == job):
			return n
	return null


func ledger(w: World) -> Array:
	return [w.total_coins() + w.regions.coins() + int(w.transactions.in_transit().coins), Census.goods(w)]


# ------------------------------------------------------------------------------------------------ parties
func test_village_parties() -> void:
	var w := new_world(false)
	var tx := w.transactions
	var a := adult(w)
	var hr := World.hh_ref(a.household)
	var head: NPC = w.party(hr)
	a.inv.add("wheat", 5)
	w.treasury += 100
	var before := ledger(w)
	var t0 := w.treasury
	var r := tx.exchange("v:1", World.MANOR, World.npc_ref(a.id), "wheat", 3, 6)
	check(r.ok and w.treasury == t0 - 6 and w.granary.count("wheat") >= 3, "the manor buys a villager's wheat: treasury pays, granary holds it")
	var pantry: Inventory = w.households[a.household].pantry
	pantry.add("log", 4)
	before[1]["log"] = int(before[1].get("log", 0)) + 4          # the test's own addition
	var hc := head.coins
	var c0 := w.chapel.coins
	w.chapel.coins += 20
	r = tx.exchange("v:2", "chapel", hr, "log", 2, 4)
	check(r.ok and head.coins == hc + 4 and w.chapel.store.count("log") >= 2, "a household sells from its pantry; its head is paid (purses not pooled); the chapel buys")
	var front := ""
	for id in w.stalls:
		front = "stall:" + str(id)
		break
	var st: Dictionary = tx._till(front)
	st.till = 10
	r = tx.exchange("v:3", front, World.npc_ref(a.id), "wheat", 1, 2)
	check(not r.ok and r.code == "no_room", "a till holds coins, never goods (%s)" % r.code)
	r = tx.exchange("v:4", World.npc_ref(a.id), front, "wheat", 1, 2)
	check(not r.ok and r.code == "no_stock", "and sells none")
	if ledger(w) != [before[0] + 30, before[1]]:
		printerr("  %s vs %s" % [str(ledger(w)[0]), str(before[0])])
		var g: Dictionary = Census.goods(w)
		for k in g:
			if int(g[k]) != int(before[1].get(k, 0)):
				printerr("  goods %s %d -> %d" % [k, int(before[1].get(k, 0)), int(g[k])])
	check(ledger(w)[0] == before[0] + 30 and Census.goods(w) == before[1], "conserved (the chapel's 20 and the till's 10 added by the test)")
	# a household with nobody left cannot pay
	for m in w.households[a.household].members:
		var o := w.npc(int(m))
		if o != null:
			o.alive = false
	r = tx.exchange("v:5", hr, World.npc_ref(adult(w).id), "wheat", 1, 1)
	check(not r.ok, "an ended or empty household is no party (%s)" % r.code)
	check(c0 >= 0, "chapel present")


# ------------------------------------------------------------------------------------------------ the manor buys a tool
func needer(w: World) -> NPC:
	var wc := adult(w, "woodcutter")
	wc.inv.remove("axe", wc.inv.count("axe"))
	return wc


func strip_tools(w: World, tool: String) -> void:
	for n: NPC in w.npcs:
		if n.job != "woodcutter":
			n.inv.remove(tool, n.inv.count(tool))
	w.granary.remove(tool, w.granary.count(tool))


func test_manor_buys_tool() -> void:
	var w := new_world()
	strip_tools(w, "axe")
	var wc := needer(w)
	var sm := adult(w, "smith")
	sm.inv.add("axe", 1)
	w.treasury = 500
	var before := ledger(w)
	var t0 := w.treasury
	var spent: int = w.brain._support_trades(1.0)
	check(wc.inv.has("axe") and spent > 0 and w.treasury == t0 - spent, "the manor buys the smith's axe through the authority and hands it over (%d coins)" % spent)
	check(w.transactions.journal.any(func(j): return str(j.txid).begins_with("manor_tools:") and j.buyer == "manor"), "recorded as a transaction of the manor's")
	check(ledger(w) == before, "conserved")
	check(w.manor_orders.is_empty(), "no advance order made while the market drives")


# ------------------------------------------------------------------------------------------------ commission (CON-01)
func test_manor_commissions_tool() -> void:
	var w := new_world()
	strip_tools(w, "axe")
	var wc := needer(w)
	var sm := adult(w, "smith")
	sm.inv.remove("axe", sm.inv.count("axe"))
	for id in GameData.recipes.get("forge_axe", {}).get("in", {}):
		sm.inv.add(id, int(GameData.recipes.forge_axe["in"][id]) * 2)
	w.treasury = 500
	var before := ledger(w)
	var t0 := w.treasury
	w.brain._support_trades(1.0)
	var m := w.economy.market
	var cid := -1
	for id in m.tool_orders:
		if int(m.tool_orders[id]) == wc.id:
			cid = int(id)
	var c: Dictionary = w.contracts.get_contract(cid)
	check(cid >= 0 and Contracts.is_open(c) and c.buyer == "manor" and c.item == "axe", "with none on sale the manor commissions a smith by contract (%s)" % str(m.stats))
	if cid < 0:
		return
	check(w.treasury == t0 - int(c.reserved) and int(c.reserved) > 0, "the treasury's coins are escrowed, not advanced")
	check(ledger(w) == before, "conserved (escrow counted)")
	w.brain._support_trades(1.0)
	check(m.tool_orders.size() == 1, "no second commission for the same worker")
	sm.inv.add("axe", 1)                      # forged (the test's: the ledger expects one more axe)
	before[1]["axe"] = int(before[1].get("axe", 0)) + 1
	var paid := int(c.reserved)
	check(w.contracts.deliver(c, 1) == 1 and w.granary.has("axe"), "delivered into the manor's stores; the smith paid from escrow")
	check(c.state == "fulfilled" and sm.earned >= paid, "the contract is fulfilled")
	w.brain._support_trades(1.0)
	check(wc.inv.has("axe") and m.tool_orders.is_empty(), "the tool goes to the worker it was commissioned for; the commission closes")
	check(ledger(w) == before, "conserved end to end")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(JSON.stringify(w2.economy.to_dict()) == JSON.stringify(w.economy.to_dict()), "saved and loaded identically")


func test_commission_refused_and_lapsed() -> void:
	var w := new_world()
	strip_tools(w, "axe")
	var wc := needer(w)
	for n: NPC in w.npcs:
		if n.job == "smith":
			for id in n.inv.ids():
				n.inv.remove(id, n.inv.count(id))     # no materials, no tool: it cannot promise one
	w.treasury = 500
	var t0 := w.treasury
	w.brain._support_trades(1.0)
	var m := w.economy.market
	if m.tool_orders.is_empty():
		check(w.treasury == t0 and int(m.stats.get("manor_tool_refused", 0)) > 0 and not wc.inv.has("axe"), "a smith who cannot do it refuses; nothing is spent; the worker waits (a valid outcome)")
	else:
		var cid := int(m.tool_orders.keys()[0])
		var c: Dictionary = w.contracts.get_contract(cid)
		var held := int(c.reserved)
		w.minutes += World.DAY * (int(c.days) + 1)
		w.contracts.dawn()
		w.brain._support_trades(1.0)
		check(not Contracts.is_open(w.contracts.get_contract(cid)) and w.treasury == t0 and m.tool_orders.is_empty(),
			"a commission not met lapses: the escrow returns to the treasury (%d), the order closes" % held)
	# an unaffordable commission is never made
	w.treasury = 0
	m.tool_orders = {}
	var n0 := w.contracts.list.size()
	w.brain._support_trades(1.0)
	check(w.contracts.list.size() == n0 and w.treasury == 0, "an empty treasury commissions nothing (the floor holds)")


func test_switch() -> void:
	var w := new_world(false)
	strip_tools(w, "axe")
	var wc := needer(w)
	w.treasury = 500
	w.brain._support_trades(1.0)
	check(w.economy == null and (not w.manor_orders.is_empty() or wc.inv.has("axe")), "economy off: EQ-19's advance or purchase as before")
	check(not w.to_dict().has("transactions"), "economy off and no authority call: no transactions key")


# ------------------------------------------------------------------------------------------------ business accounts (OD-LE-04 D03, OD-LE-07 D06)
func storefront(w: World) -> Array:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.home != "" and w.buildings.has(o.home) \
				and w.holds(World.hh_ref(o.household), w.buildings[o.home]) and w.business.front_place(w.buildings[o.home]).size() > 0:
			var house: Dictionary = w.buildings[o.home]
			for id in w.business.storefront_cost():
				o.inv.add(id, int(w.business.storefront_cost()[id]))
			assert(w.business.build_npc_front(house, o))
			return [o, house]
	return []


func test_business_accounts() -> void:
	var w := new_world()
	var pair := storefront(w)
	var o: NPC = pair[0]
	var house: Dictionary = pair[1]
	var tref := "front:" + str(house.id)
	var owner: NPC = w.party(w.business.money.front_owner(house))
	check(w.economy.actors.controller(tref) != "" and owner != null, "one owner per business: the storefront's till has exactly one controller (%s)" % w.economy.actors.controller(tref))
	house.front.till = 200
	var all := w.total_coins()
	var e0 := owner.earned
	w.business.money.daily()
	var lines: Array = w.transactions.journal.filter(func(j): return str(j.op).begins_with("coins:") and (j.seller == tref or j.buyer == tref))
	check(not lines.is_empty() and w.total_coins() == all, "the day's owner pay or draw is a recorded transfer through the authority (%s), conserved" % str(lines.map(func(j): return j.op)))
	check(owner.earned == e0, "a distribution is not income: the owner's earned is unchanged")
	# a contribution of coins a bid holds back is refused (no silent use of committed money)
	owner.coins = 10
	var b := w.economy.offers.post(EconOffers.BID, World.npc_ref(owner.id), "plank", 2, 5, w.day() + 3, "", "market", 1, "input")
	check(b.ok, "a bid holds the owner's 10 coins")
	var t0 := int(house.front.till)
	check(not w.business.money.to_till(house, owner, 5) and int(house.front.till) == t0 and owner.coins == 10, "a contribution of coins a bid holds back is refused")
	w.economy.offers.withdraw(int(b.id))
	check(w.business.money.to_till(house, owner, 5) and int(house.front.till) == t0 + 5, "freed, the contribution is made and recorded")
	check(w.business.money.from_till(house, owner, 3) and owner.coins == 8, "and a distribution back")
	check(w.transactions.journal.filter(func(j): return str(j.op) in ["coins:contribution", "coins:distribution"]).size() == 2, "both journalled")
	# economy off: the same moves, unrecorded, exactly as before
	var w2 := new_world(false)
	var p2 := storefront(w2)
	var h2: Dictionary = p2[1]
	var o2: NPC = p2[0]
	o2.coins = 20
	check(w2.business.money.to_till(h2, o2, 5) and int(h2.front.till) == 5 and o2.coins == 15 and w2.transactions.is_empty(), "economy off: a contribution as before, nothing recorded")


# ------------------------------------------------------------------------------------------------ estate claims (OD-LE-13B D12)
func smith_with_order(w: World, paid: int, coins: int) -> NPC:
	var sm := adult(w, "smith")
	var wc := adult(w, "woodcutter")
	sm.coins = coins
	sm.inv.remove("axe", sm.inv.count("axe"))
	w.manor_orders.append({"smith": sm.id, "tool": "axe", "for": wc.id, "paid": paid, "day": w.day()})
	return sm


func heirs_coins(w: World, n: NPC) -> int:
	var k := 0
	if n.household >= 0:
		for m in w.households[n.household].members:
			var o := w.npc(int(m))
			if o != null and o.alive and o != n:
				k += o.coins
	return k


func test_estate_claims() -> void:
	# advance 10, estate 6: the manor recovers 6, writes off 4; the heirs' own purses are untouched
	var w := new_world()
	var sm := smith_with_order(w, 10, 6)
	var t0 := w.treasury
	var h0 := heirs_coins(w, sm)
	var all := w.total_coins()
	w.kill(sm, "old age")
	check(w.treasury == t0 + 6 and w.manor_orders.is_empty(), "a smith who died owing an advance: the manor recovers what the estate holds (6 of 10), the rest written off")
	check(heirs_coins(w, sm) == h0, "the heirs' own coins are untouched (nothing of the estate was left to inherit)")
	check(w.total_coins() == all, "conserved")
	check(w.transactions.journal.any(func(j): return str(j.op) == "estate:manor_order" and int(j.total) == 6), "recorded through the authority")
	# estate larger than the claim: only the advance is taken; the heirs inherit the rest by the existing rule
	var w2 := new_world()
	var sm2 := smith_with_order(w2, 10, 30)
	var t2 := w2.treasury
	var all2 := w2.total_coins()
	w2.kill(sm2, "old age")
	check(w2.treasury == t2 + 10 and w2.total_coins() == all2, "an estate larger than the claim pays the 10 owed, no more")
	# the paid-for good already made: it goes to the worker, no coins claimed
	var w3 := new_world()
	var sm3 := smith_with_order(w3, 10, 30)
	sm3.inv.add("axe", 1)
	var wc: NPC = w3.npc(int(w3.manor_orders.back()["for"]))
	wc.inv.remove("axe", wc.inv.count("axe"))
	var t3 := w3.treasury
	w3.kill(sm3, "old age")
	check(wc.inv.has("axe") and w3.treasury == t3, "the tool the manor paid for, already forged, goes to its worker; no coin claim")
	# economy off: as before (the order stays until it lapses)
	var w4 := new_world(false)
	var sm4 := smith_with_order(w4, 10, 6)
	var t4 := w4.treasury
	w4.kill(sm4, "old age")
	check(w4.manor_orders.size() == 1 and w4.treasury == t4, "economy off: the existing lapse rule, unchanged")


# ------------------------------------------------------------------------------------------------ speculation (OD-LE-11 D10)
func test_speculation() -> void:
	var w := new_world()
	var m := w.economy.market
	var mr: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and w.brain.buy_role(n) == "merchant_raw":
			mr = n
	var item := ""
	var ids: Array = NPCBrain.BUYS.get("merchant_raw", {}).keys()
	ids.sort()
	for id in ids:
		mr.inv.remove(id, mr.inv.count(id))
		if item == "" and w.brain.wants(mr, id) > 0:
			item = id
	var ref := World.npc_ref(mr.id)
	check(m.spec_need(mr, item).is_empty(), "knowing of no seller, a merchant does not speculate")
	var v := GameData.value(item)
	var a := adult(w, "farmer")
	var b := adult(w, "laborer")
	w.economy.knowledge.learn(ref, World.npc_ref(a.id), item, EconKnowledge.SELLS, maxi(1, roundi(v * 0.6)), "in_person")
	w.economy.knowledge.learn(ref, World.npc_ref(b.id), item, EconKnowledge.BUYS, roundi(v * 1.5), "in_person")
	var need := m.spec_need(mr, item)
	check(not need.is_empty() and int(need.qty) <= w.brain.wants(mr, item) and int(need.limit) < int(need.resale), "a cheap ask and a better bid it knows of: worth stocking, within its caps (%s)" % str(need))
	mr.coins = 100 + w.reserve_of(mr)
	m.spec_cursor = w.npcs.find(mr) - 1
	var posted := m.speculate(w.day())
	check(posted.size() == 1, "it bids for the good (one speculation a dawn)")
	if posted.size() == 1:
		var o := w.economy.offers.get_offer(int(posted[0]))
		check(o.need == "stock" and int(o.qty) * int(o.price_each) <= int(float(w.spendable(mr)) * 0.3) + int(o.price_each), "only a share of its spendable coins is at risk (%d x %d)" % [int(o.qty), int(o.price_each)])
		# the opportunity gone (the cheap ask no longer known): withdrawn at review
		w.economy.knowledge.entries.clear()
		w.economy.knowledge.load_dict(w.economy.knowledge.to_dict())
		w.minutes += World.DAY
		m.review(w.day())
		check(w.economy.offers.get_offer(int(posted[0])).state != "open", "with the opportunity gone the speculative bid is withdrawn")
	check(m.to_dict().get("spec_cursor", -1) != -1, "its round-robin cursor is saved (bounded state)")
	var full := new_world()
	check(full.economy.market.p("speculation", false) == true, "on with the market (provisional)")


# ------------------------------------------------------------------------------------------------ negotiated wages (OD-LE-03 D02, off flag)
func test_negotiated_wages() -> void:
	var w := new_world()
	var job := {"kind": "mend", "wage": 10}
	var n := adult(w, "laborer")
	var who := World.npc_ref(n.id)
	var base: int = w.manor_work.wage_for(job, who)
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	check(c.market.negotiated_wages == false and c.market.services == false, "shipped: negotiated wages and services off")
	c.enabled = true
	c.market.negotiated_wages = true
	EconomyFoundation.set_override(c)
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 1)
	var n2 := w2.npc(n.id)
	n2.coins = 5000
	var rich: int = w2.manor_work.wage_for(job, who)
	n2.coins = 0
	var poor: int = w2.manor_work.wage_for(job, who)
	check(poor == base and rich >= base and rich <= roundi(base * 1.25), "flag on: a needy worker takes the existing wage (%d), a comfortable one asks more within the cap (%d)" % [poor, rich])
	check(w.manor_work.wage_for(job, who) == base, "flag off: the existing wage, unchanged")


# ------------------------------------------------------------------------------------------------ settle to estate (Worker B's gap)
func total(w: World, item: String) -> Array:
	var t: Dictionary = w.transactions.in_transit()
	return [w.total_coins() + w.regions.coins() + int(t.coins) + w.transactions.outside_coins,
		int(Census.goods(w).get(item, 0)) + int(w.regions.goods().get(item, 0)) + int(t.goods.get(item, 0)) + int(w.transactions.sunk.get(item, 0))]


func trader(w: World) -> SettlementParty:
	for p: SettlementParty in w.regions.parties():
		if p.holder == "trader":
			return p
	return null


## X20-TXN-REPLAY-FIELDS: an id replayed after a save and load answers exactly what its first call answered, every field of the
## result kept (an estate claim's `paid` and `written_off`), with the same types; the saved past results stay bounded.
func test_replay_after_load() -> void:
	var w := new_world(false)
	var tx := w.transactions
	var a := adult(w)
	a.coins = 7
	var first := tx.estate_claim("estate:1", a, World.MANOR, 10, "test")
	var ex := tx.exchange("rp:1", World.MANOR, World.npc_ref(a.id), "wheat", 1, 1)       # refused (no stock): its outcome is kept too
	check(int(first.paid) == 7 and int(first.written_off) == 3, "an estate claim pays what the estate holds (7 of 10)")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var again := w2.transactions.estate_claim("estate:1", w2.npc(a.id), World.MANOR, 10, "test")
	var want := first.duplicate()
	want.replay = true
	check(again == want, "replayed after a load: exactly the first answer, paid and written_off included (%s vs %s)" % [str(again), str(want)])
	check(typeof(again.get("paid")) == TYPE_INT, "with the same types (paid a whole number)")
	var ex2 := w2.transactions.exchange("rp:1", World.MANOR, World.npc_ref(a.id), "wheat", 1, 1)
	var want2 := ex.duplicate()
	want2.replay = true
	check(ex2 == want2, "a refused call replays as refused, the same code")
	check(JSON.stringify(w2.transactions.to_dict()) == JSON.stringify(tx.to_dict()), "the authority's save round-trips identically")
	var old: Dictionary = d.duplicate(true)               # a save written before this change: the past results held only the base fields
	for e in old.transactions.outcomes["estate"]:
		(e[1] as Dictionary).erase("paid")
		(e[1] as Dictionary).erase("written_off")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	var r3 := w3.transactions.estate_claim("estate:1", w3.npc(a.id), World.MANOR, 10, "test")
	check(bool(r3.replay) and bool(r3.ok) and not r3.has("paid"), "an older save loads; its replay answers what it kept")
	for i in 80:
		w2.transactions.exchange("rp:%d" % (i + 2), World.MANOR, World.npc_ref(a.id), "wheat", 1, 1)
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w2.to_dict(), "", true, true)))
	check((w4.transactions.outcomes["rp"] as Array).size() == w4.transactions.keep_outcomes, "still bounded (%d kept per namespace)" % w4.transactions.keep_outcomes)


func test_settle_estate() -> void:
	var w := new_world(false)
	var tx := w.transactions
	var sp := trader(w)
	sp.add("wheat", 6)
	var a := adult(w, "laborer")
	a.coins = 30
	var heir: NPC = null
	for m in w.households[a.household].members:
		var o := w.npc(int(m))
		if o != null and o.alive and o != a:
			heir = o
	check(tx.ship("est:1", World.npc_ref(a.id), sp.ref, "wheat", 3, 12, w.day() + 2).ok, "a villager's shipment from a settlement")
	check(tx.settle_estate("est:1", "x").code == "not_departed", "both parties there: settle to estate refused (use deliver or fail)")
	var before := total(w, "wheat")
	var s0 := sp.held("wheat")
	a.alive = false
	check(tx.deliver("est:1").code == "party_unavailable" and tx.fail("est:1", "x").code == "party_unavailable", "the buyer gone: neither delivery nor refund can complete")
	var h0 := heir.coins if heir != null else 0
	var r := tx.settle_estate("est:1", "buyer died")
	check(r.ok and r.state == "settled" and sp.held("wheat") == s0 + 3, "settled to the estate: the goods back to the seller")
	if heir != null:
		check(w.party(World.hh_ref(a.household)).coins >= 12 or heir.coins == h0 + 12, "the escrow to the dead buyer's household (its head)")
	check(total(w, "wheat") == before and w.regions.audit() == "", "conserved; regional books balance")
	check(tx.settle_estate("est:1", "again").replay and total(w, "wheat") == before, "idempotent: settling again changes nothing")
	# a household with nobody left: to the manor
	var b := adult(w, "farmer")
	b.coins = 20
	check(tx.ship("est:2", World.npc_ref(b.id), sp.ref, "wheat", 1, 5, w.day()).ok, "a second shipment")
	for m in w.households[b.household].members:
		var o := w.npc(int(m))
		if o != null:
			o.alive = false
	var t0 := w.treasury
	before = total(w, "wheat")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(tx.settle_estate("est:2", "household gone").ok and w.treasury == t0 + 5, "nobody of the buyer's household left: the escrow escheats to the manor")
	check(total(w, "wheat") == before, "conserved")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var t2 := w2.treasury
	check(w2.transactions.settle_estate("est:2", "after load").ok and w2.treasury == t2 + 5 and w2.transactions.settle_estate("est:2", "x").replay,
		"after a save and load: settled once, the same way")
