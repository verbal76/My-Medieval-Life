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
