extends SceneTree
## Expansion 20 LE-03: the transaction authority (EconTransactions; docs/expansion20/TRANSACTION_AUTHORITY.md). The owner's list
## (2026-10-30): two buyers for the last unit, several transactions on the same funds, interrupted and rejected transfers, save
## and load and replay, repeated transactions over days; plus single-use ids, every error code, shipments (custody, escrow,
## delivery, failure with refund, loss), village and settlement parties, conservation across the village, the settlements and
## transit, Regions.audit, determinism, and the economy switch (works with it off; claims only with it on).
## Run headless:  godot --headless --path game --script res://tests/le03_transactions_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(on := false) -> World:
	if on:
		var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		c.enabled = true
		EconomyFoundation.set_override(c)
	else:
		EconomyFoundation.set_override({})
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_ids_and_codes()
	test_last_unit()
	test_same_funds()
	test_shipments()
	test_interrupted_and_rejected()
	test_save_load_replay()
	test_days()
	test_village_claims()
	test_determinism()
	test_switch()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------------------------------------ helpers
func adult(w: World, k := 0) -> NPC:
	var i := 0
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.job in ["laborer", "farmer", "woodcutter", "carpenter"]:
			if i == k:
				return n
			i += 1
	return null


func traders(w: World) -> Array:
	var out := []
	for p: SettlementParty in w.regions.parties():
		if p.holder == "trader":
			out.append(p)
	return out


func r(n: NPC) -> String:
	return World.npc_ref(n.id)


## Everything that holds `item` and coins: village (total_coins, every pack and the player), the settlements, transit, sunk.
func world_total(w: World, item: String) -> Array:
	var g := 0
	for n: NPC in w.npcs:
		g += n.inv.count(item)
	g += w.player.inv.count(item)
	g += int(w.regions.goods().get(item, 0))
	var t := w.transactions.in_transit()
	g += int(t.goods.get(item, 0)) + int(w.transactions.sunk.get(item, 0))
	return [w.total_coins() + w.regions.coins() + int(t.coins), g]


func snap(w: World) -> String:
	var people := []
	for n: NPC in w.npcs:
		people.append([n.id, n.coins, n.inv.items])
	return JSON.stringify([people, w.player.coins, w.player.inv.items, w.regions.coins(), w.regions.goods(), w.coin_sources, w.transactions.shipments])


# ------------------------------------------------------------------------------------------------ ids and codes
func test_ids_and_codes() -> void:
	var w := new_world()
	var tx := w.transactions
	var a := adult(w)
	var b := adult(w, 1)
	a.inv.add("wheat", 3)
	b.coins = 50
	check(EconTransactions.parse_id("food/riverford:7") == ["food/riverford", 7], "a txid is <namespace>:<seq>")
	for bad in ["", "x", "x:", "x:0", "x:-2", "x:1.5", ":3", "a b:1"]:
		check(tx.exchange(bad, r(b), r(a), "wheat", 1, 2).code == "bad_id", "bad id refused: '%s'" % bad)
	var s0 := snap(w)
	check(tx.exchange("t:1", r(b), r(a), "wheat", 0, 2).code == "invalid_quantity", "a quantity of 0 is refused")
	check(tx.exchange("t:2", r(b), r(a), "wheat", 1, -1).code == "invalid_quantity", "a negative price is refused")
	check(tx.exchange("t:3", r(b), r(a), "coins", 1, 1).code == "invalid_quantity", "coins are not goods")
	check(tx.exchange("t:4", r(a), r(a), "wheat", 1, 1).code == "same_party", "no trade with oneself")
	check(tx.exchange("t:5", "npc:99999", r(a), "wheat", 1, 1).code == "unknown_party", "an unknown party is refused")
	check(tx.exchange("t:6", r(b), "manor", "iron_bar", 9999, 1).code == "no_stock", "the manor is a party (LE-04): more than its stores hold is refused")
	check(tx.exchange("t:7", r(b), r(a), "wheat", 9, 2).code == "no_stock", "more than the seller holds")
	check(tx.exchange("t:8", r(b), r(a), "wheat", 1, 999).code == "no_funds", "more than the buyer's purse")
	var dead := adult(w, 2)
	dead.alive = false
	check(tx.exchange("t:9", r(dead), r(a), "wheat", 1, 1).code == "party_unavailable", "a dead party is unavailable")
	dead.alive = true
	check(snap(w) == s0, "every rejection changed nothing")
	var ok := tx.exchange("t:10", r(b), r(a), "wheat", 2, 6)
	check(ok.ok and ok.code == "ok" and b.inv.count("wheat") >= 2 and b.coins == 44, "an exchange between villagers (through World.trade)")
	var again := tx.exchange("t:10", r(b), r(a), "wheat", 2, 6)
	check(again.ok and again.replay and b.coins == 44, "the same id again: a replay, nothing runs twice")
	check(tx.exchange("t:9", r(b), r(a), "wheat", 1, 1).replay and tx.exchange("t:9", r(b), r(a), "wheat", 1, 1).code == "party_unavailable",
		"an older id replays its stored outcome (a rejection stays a rejection)")
	check(not tx.exchange("t:4", r(b), r(a), "wheat", 1, 1).ok, "a rejected attempt is not retried under its old id")


# ------------------------------------------------------------------------------------------------ two buyers, last unit
func test_last_unit() -> void:
	var w := new_world()
	var tx := w.transactions
	var ts := traders(w)
	var sp: SettlementParty = ts[0]
	var bp: SettlementParty = ts[1]
	var item := "wheat"
	var have := sp.held(item)
	if have > 1:
		sp.remove(item, have - 1)               # the trader has one unit left
	elif have == 0:
		sp.add(item, 1)
	var a := adult(w)
	a.coins = 100
	bp.outside_coins(100)
	var a0 := a.inv.count(item)
	var b0 := bp.held(item)
	var before := world_total(w, item)
	var r1 := tx.exchange("last:1", bp.ref, sp.ref, item, 1, 4)
	var r2 := tx.exchange("last:2", r(a), sp.ref, item, 1, 4)
	check(r1.ok and not r2.ok and r2.code == "no_stock", "two buyers, the last unit: one gets it, the other is refused (%s)" % r2.code)
	check(sp.held(item) == 0 and a.inv.count(item) == a0 and bp.held(item) == b0 + 1, "the unit went once, to the first buyer")
	check(world_total(w, item) == before and w.regions.audit() == "", "conserved; regional books balance")


# ------------------------------------------------------------------------------------------------ the same funds
func test_same_funds() -> void:
	var w := new_world()
	var tx := w.transactions
	var ts := traders(w)
	var a := adult(w)
	a.coins = 10
	var sp: SettlementParty = ts[0]
	sp.add("wheat", 10)
	sp.add("log", 10)
	var before_w := world_total(w, "wheat")
	var r1 := tx.exchange("funds:1", r(a), sp.ref, "wheat", 2, 6)
	var r2 := tx.ship("funds:2", r(a), sp.ref, "log", 2, 6, w.day() + 2)
	var r3 := tx.exchange("funds:3", r(a), sp.ref, "log", 1, 4)
	check(r1.ok and not r2.ok and r2.code == "no_funds" and r3.ok and a.coins == 0, "several transactions on the same 10 coins: 6 then 4 pass, the 6 between is refused")
	check(world_total(w, "wheat") == before_w and w.regions.audit() == "", "conserved; regional books balance")
	var bp: SettlementParty = ts[1]
	var p0 := bp.purse()
	var x1 := tx.ship("funds:4", bp.ref, sp.ref, "wheat", 1, p0, w.day() + 3)
	var x2 := tx.exchange("funds:5", bp.ref, sp.ref, "wheat", 1, 1)
	check(x1.ok and not x2.ok and x2.code == "no_funds", "coins in escrow cannot be spent again (%s)" % x2.code)


# ------------------------------------------------------------------------------------------------ shipments
func test_shipments() -> void:
	var w := new_world()
	var tx := w.transactions
	var ts := traders(w)
	var sp: SettlementParty = ts[0]
	var bp: SettlementParty = ts[1]
	sp.add("wheat", 5)
	bp.outside_coins(40)
	var before := world_total(w, "wheat")
	var sh0 := sp.held("wheat")
	var bc0 := bp.purse()
	var o := tx.ship("food/x:1", bp.ref, sp.ref, "wheat", 5, 20, w.day() + 2)
	check(o.ok and o.state == "open" and sp.held("wheat") == sh0 - 5 and bp.purse() == bc0 - 20, "shipped: goods into custody, coins into escrow")
	check(int(tx.in_transit().coins) == 20 and int(tx.in_transit().goods.wheat) == 5, "in transit: 20 coins, 5 wheat")
	check(world_total(w, "wheat") == before, "conserved while in transit")
	check(not tx.exchange("food/x:2", "region:" + str(bp.id), sp.ref, "wheat", 1, 1).ok or sp.held("wheat") >= 0, "goods in transit cannot be sold again by the seller")
	check(tx.overdue(w.day() + 3).size() == 1 and tx.overdue(w.day()).is_empty(), "overdue by its due day (the caller decides)")
	var d := tx.deliver("food/x:1")
	check(d.ok and d.state == "delivered" and bp.held("wheat") >= 5, "delivered: the buyer has the goods")
	check(sp.purse() >= 20 and int(tx.in_transit().coins) == 0, "and the seller the coins; nothing left in transit")
	var d2 := tx.deliver("food/x:1")
	check(d2.ok and d2.code == "duplicate" and d2.replay, "delivering again: a duplicate, nothing moves")
	check(tx.fail("food/x:1", "late").code == "not_open", "a delivered shipment cannot then fail")
	check(world_total(w, "wheat") == before and w.regions.audit() == "", "conserved; regional books balance")
	# a failed delivery: everything goes back
	sp.add("wheat", 3)
	var before2 := world_total(w, "wheat")
	var p_s := sp.purse()
	var p_b := bp.purse()
	var h_s := sp.held("wheat")
	check(tx.ship("food/x:3", bp.ref, sp.ref, "wheat", 3, 9, w.day()).ok, "a second shipment")
	var f := tx.fail("food/x:3", "road blocked")
	check(f.ok and f.state == "returned" and sp.held("wheat") == h_s and sp.purse() == p_s and bp.purse() == p_b, "failed: goods back to the seller, coins refunded")
	check(tx.fail("food/x:3", "again").replay, "failing again is a duplicate")
	check(world_total(w, "wheat") == before2, "conserved")
	# lost in transit: the seller bears it, the buyer is refunded
	check(tx.ship("food/x:4", bp.ref, sp.ref, "wheat", 2, 8, w.day()).ok, "a third shipment")
	var l := tx.lose("food/x:4", "bandits")
	check(l.ok and l.state == "lost" and bp.purse() == p_b and int(tx.sunk.wheat) == 2, "lost: the buyer refunded, two wheat destroyed (a recorded sink)")
	check(world_total(w, "wheat") == before2, "conserved, counting the sink")
	check(tx.deliver("nope:1").code == "not_found", "an unknown shipment")
	# village to settlement and back
	var a := adult(w)
	a.coins = 30
	a.inv.add("log", 4)
	var cs := w.coin_sources
	var vb := world_total(w, "log")
	check(tx.ship("vill:1", sp.ref, r(a), "log", 4, 12, w.day()).ok and a.inv.count("log") >= 0, "a villager ships logs to a settlement")
	check(w.coin_sources == cs and int(w.stats.get("exported_log", 0)) >= 4, "the logs left the village (exported); no coin crossed yet")
	check(tx.deliver("vill:1").ok and w.coin_sources == cs + 12 and a.coins == 42, "delivered: the villager paid, the coins entered the village")
	check(world_total(w, "log") == vb and w.regions.audit() == "", "conserved; regional books balance")


# ------------------------------------------------------------------------------------------------ interrupted and rejected
func test_interrupted_and_rejected() -> void:
	var w := new_world()
	var tx := w.transactions
	var ts := traders(w)
	var sp: SettlementParty = ts[0]
	var bp: SettlementParty = ts[1]
	sp.add("wheat", 2)
	bp.outside_coins(10)
	var s0 := snap(w)
	check(not tx.exchange("rej:1", bp.ref, sp.ref, "wheat", 3, 3).ok and snap(w) == s0, "rejected (no stock): nothing changed")
	check(not tx.ship("rej:2", bp.ref, sp.ref, "wheat", 1, bp.purse() + 1, w.day()).ok and snap(w) == s0, "rejected shipment (no funds): nothing changed")
	check(tx.ship("rej:3", bp.ref, sp.ref, "wheat", 2, 4, w.day()).ok, "a shipment opens")
	# interrupted: the receiver can no longer take delivery; the shipment stays open, nothing lost or duplicated
	var a := adult(w)
	a.coins = 10
	sp.add("wheat", 1)
	check(tx.ship("rej:4", r(a), sp.ref, "wheat", 1, 2, w.day()).ok, "a villager's shipment")
	a.alive = false
	var t0 := world_total(w, "wheat")
	var d := tx.deliver("rej:4")
	check(not d.ok and d.code == "party_unavailable" and d.state == "open", "a buyer gone before delivery: refused, still open")
	check(world_total(w, "wheat") == t0, "nothing lost or duplicated meanwhile")
	var l := tx.lose("rej:4", "no one to take it")
	check(not l.ok, "a refund to a gone buyer is refused too (the estate's rule decides later, OD-LE-13B)")
	a.alive = true
	check(tx.deliver("rej:4").ok, "once the party is back, delivery completes")
	check(w.regions.audit() == "", "regional books balance")


# ------------------------------------------------------------------------------------------------ save, load, replay
func test_save_load_replay() -> void:
	var w := new_world()
	var tx := w.transactions
	var ts := traders(w)
	var sp: SettlementParty = ts[0]
	var bp: SettlementParty = ts[1]
	sp.add("wheat", 6)
	bp.outside_coins(30)
	check(tx.ship("sl:1", bp.ref, sp.ref, "wheat", 3, 9, w.day() + 2).ok, "a shipment open at the save")
	check(tx.exchange("sl:2", bp.ref, sp.ref, "wheat", 1, 3).ok, "an exchange before the save")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(d.has("transactions"), "saved under the optional key \"transactions\"")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(JSON.stringify(w2.transactions.to_dict()) == JSON.stringify(tx.to_dict()), "round trip identical")
	var sp2: SettlementParty = w2.regions.party(sp.ref)
	var bp2: SettlementParty = w2.regions.party(bp.ref)
	var before := world_total(w2, "wheat")
	var rep := w2.transactions.exchange("sl:2", bp.ref, sp.ref, "wheat", 1, 3)
	check(rep.replay and world_total(w2, "wheat") == before and bp2.held("wheat") == bp.held("wheat"), "replaying a committed id after load runs nothing")
	check(w2.transactions.ship("sl:1", bp.ref, sp.ref, "wheat", 3, 9, w.day()).replay, "re-opening the saved shipment after load is a replay")
	var r1 := tx.deliver("sl:1")
	var r2 := w2.transactions.deliver("sl:1")
	check(r1.ok and r2.ok and sp2.purse() == sp.purse() and bp2.held("wheat") == bp.held("wheat"), "delivery after load ends exactly as without the save")
	check(w2.transactions.deliver("sl:1").replay and world_total(w2, "wheat") == before, "and cannot run twice")
	var old: Dictionary = d.duplicate(true)
	old.erase("transactions")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.transactions != null and w3.transactions.is_empty() and not w3.to_dict().has("transactions"), "an older save (no key) loads with nothing, writes no key")


# ------------------------------------------------------------------------------------------------ over days
func test_days() -> void:
	var w := new_world()
	var tx := w.transactions
	var ts := traders(w)
	var sp: SettlementParty = ts[0]
	var bp: SettlementParty = ts[1]
	sp.add("wheat", 40)
	bp.outside_coins(200)
	var before := world_total(w, "wheat")
	var seq := 0
	var delivered := 0
	for day in 10:
		seq += 1
		var id := "days:%d" % seq
		if tx.ship(id, bp.ref, sp.ref, "wheat", 2, 6, w.day() + 1).ok:
			if day % 3 == 2:
				tx.fail(id, "turned back")
			else:
				tx.deliver(id)
				tx.deliver(id)                  # a retry on the same day
				delivered += 2
		seq += 1
		tx.exchange("days:%d" % seq, bp.ref, sp.ref, "wheat", 1, 3)
		tx.exchange("days:%d" % seq, bp.ref, sp.ref, "wheat", 1, 3)     # a replayed request
		w.minutes += World.DAY
	check(world_total(w, "wheat") == before and w.regions.audit() == "", "ten days of shipments, failures, retries and replays: conserved, books balance")
	check(tx.open_shipments().is_empty() and tx.journal.size() >= 20, "nothing left open; every committed step journalled (%d)" % tx.journal.size())
	check(int(tx.marks.days) == seq, "the namespace's mark is the last attempt")


# ------------------------------------------------------------------------------------------------ claims (economy on)
func test_village_claims() -> void:
	var w := new_world(true)
	var tx := w.transactions
	var sp: SettlementParty = traders(w)[0]
	var a := adult(w)
	a.coins = 20
	var b := w.economy.offers.post(EconOffers.BID, r(a), "plank", 5, 4, w.day() + 3, "", "market", 1, "input")
	check(b.ok, "the villager's bid holds its 20 coins")
	sp.add("leather", 2)
	var s0 := snap(w)
	check(tx.exchange("cl:1", r(a), sp.ref, "leather", 1, 5).code == "claimed" and snap(w) == s0, "economy on: coins a bid holds cannot buy something else from a settlement")
	sp.add("plank", 2)
	check(tx.exchange("cl:2", r(a), sp.ref, "plank", 2, 8).ok and w.economy.offers.remaining(int(b.id)) == 3, "a purchase of the bid's own item may use them (the bid yields)")
	check(w.economy.claims.audit().is_empty(), "no breach")


# ------------------------------------------------------------------------------------------------ determinism and the switch
func run() -> String:
	var w := new_world()
	var tx := w.transactions
	var ts := traders(w)
	var sp: SettlementParty = ts[0]
	var bp: SettlementParty = ts[1]
	sp.add("wheat", 9)
	bp.outside_coins(50)
	tx.ship("det:1", bp.ref, sp.ref, "wheat", 3, 9, w.day() + 1)
	tx.exchange("det:2", bp.ref, sp.ref, "wheat", 2, 6)
	tx.deliver("det:1")
	return JSON.stringify(w.to_dict())


func test_determinism() -> void:
	check(run() == run(), "the same transactions twice: byte-identical saves")


func test_switch() -> void:
	var w := new_world()
	check(w.economy == null and w.transactions != null and w.transactions.is_empty(), "economy off: the authority is built and empty")
	check(not w.to_dict().has("transactions"), "and writes no save key until used")
