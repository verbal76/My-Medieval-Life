extends SceneTree
## LE-05 paid commercial repair (owner directive 2026-10-31, docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md, LE-05 A:
## "Paid commercial repair services and their associated financial transactions may depend on the economy system"; register
## LE05-RENTAL-REPAIR, LE-05; EconRepairs). Behind the Living Economy switch and market.paid_repair. Each path with exact coin and item
## conservation: the switch, the quote, the order (price into escrow), the smith's work in play paid from escrow, a refund when not done
## in time or the tool went, the customer's and the smith's death, the choice weighed against doing without, save/load and replay.
## Run headless:  godot --headless --path game --script res://tests/le05_paid_repair_test.gd

const T := "axe"

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(on := true, paid := true) -> World:
	if on:
		var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		c.enabled = true
		c.market.paid_repair = paid
		EconomyFoundation.set_override(c)
	else:
		EconomyFoundation.set_override(EconomyFoundation.off_config())
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_switch()
	test_quote()
	test_order_and_work()
	test_refunds()
	test_deaths()
	test_choice()
	test_save_and_replay()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## The coin invariant: the world's coins less what crossed its boundary never changes by itself.
func ledger(w: World) -> int:
	return w.total_coins() - w.coin_sources


func wear_to(inv: Inventory, id: String, left: int) -> void:
	if not inv.has(id):
		inv.add(id)
	inv.durability[id] = left


## A smith (stocked with the axe's materials, nothing else to do) and a woodcutter of another household with a 70%-worn axe.
func pair(w: World) -> Array:
	var sm: NPC = w.npcs.filter(func(n): return n.alive and n.job == "smith")[0]
	var c: NPC = w.npcs.filter(func(n): return n.alive and n.job == "woodcutter" and n.role == "adult" and n.household != sm.household)[0]
	for id in ["iron_ore", "copper_ore", "gold_ore"]:
		sm.inv.remove(id, sm.inv.count(id))
	sm.inv.add("iron_bar", 4)
	sm.inv.add("plank", 2)
	sm.inv.durability.erase("hammer")
	c.inv.remove(T, c.inv.count(T))
	wear_to(c.inv, T, 36)                                     # 84 of 120 uses gone
	c.coins = 200
	# keep it to this one smith
	for o: NPC in w.npcs:
		if o != sm and o.job == "smith":
			o.inv.remove("iron_bar", o.inv.count("iron_bar"))
	return [sm, c]


func test_switch() -> void:
	var off := new_world(false)
	check(off.economy == null, "economy off: no paid repair is built")
	var p: Array = pair(off)
	var c0 := ledger(off)
	off.brain._smith(p[0])
	check(not str(p[0].plan).contains("order") and ledger(off) == c0, "economy off: a smith's day is as before (no order)")
	check(not JSON.stringify(off.to_dict()).contains("repairs"), "economy off: the save has no repairs key")
	var nopay := new_world(true, false)
	var q: Array = pair(nopay)
	check(not nopay.economy.repairs.active() and nopay.economy.repairs.consider(q[1], T).act == "none", "economy on, market.paid_repair off: nobody orders")
	nopay.economy.repairs.on_wear(q[1], T)
	check(nopay.economy.repairs.candidates.is_empty(), "paid_repair off: wear marks nobody")


func test_quote() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var sm: NPC = p[0]
	var c: NPC = p[1]
	var t := World.repair_terms(c.inv, T)
	var k := 0.0
	for inp in t["in"]:
		k += float(w.sell_price(sm, str(inp))) * float(t["in"][inp])
	k += float(t.minutes) * sm.avg_income() / ((NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0)
	var q := w.economy.repairs.quote(sm, c.inv, T)
	check(q == maxi(1, int(ceil(k - 0.000001))) and q > 0, "the quote: the repair's materials at the smith's prices plus its minutes at its earnings (%d coins)" % q)
	check(w.economy.repairs.quote(sm, Inventory.new(), T) == 0, "nothing worn: no quote")


func test_order_and_work() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var sm: NPC = p[0]
	var c: NPC = p[1]
	var rp: EconRepairs = w.economy.repairs
	var c0 := ledger(w)
	var used0 := int(w.stats.get("used_iron_bar", 0.0))
	var t := World.repair_terms(c.inv, T)
	var price := rp.quote(sm, c.inv, T)
	var res := rp.open(c, sm, T, price)
	check(res.ok and c.coins == 200 - price and rp.escrow() == price and ledger(w) == c0, "the order: the price (%d) leaves the customer into escrow; coins conserved" % price)
	check(rp.open(c, sm, T, price).code == "already_ordered", "a second order for the same tool is refused")
	var rec: Dictionary = rp.open_for(World.npc_ref(c.id), T)
	var replay: Dictionary = w.transactions.hold_coins(str(res.txid), World.npc_ref(c.id), price, "repair")
	check(replay.replay and rp.escrow() == price and c.coins == 200 - price, "the authority's id is single-use: a replay moves nothing")
	var job := rp.job_for(sm)
	check(not job.is_empty() and job.holder == c and str(job.item) == T, "the smith finds the order")
	# the smith's day: it goes to the anvil and mends the customer's axe; the price is paid on completion
	var sc := sm.coins
	sm.plan = []
	var n0 := float(w.stats.get("paid_repair_done", 0.0))
	for i in 2 * 24 * 60 * 2:
		w.update(0.5)
		if float(w.stats.get("paid_repair_done", 0.0)) > n0:
			break
	check(float(w.stats.get("paid_repair_done", 0.0)) > n0 and not c.inv.durability.has(T) and c.inv.count(T) == 1,
		"in play the smith mends the customer's axe where it lies (the axe stays the customer's)")
	check(str(rec.state) == "done" and rp.escrow() == 0 and int(w.stats.get("paid_repair_coins", 0.0)) == price and sm.earned > 0,
		"the escrow is paid to the smith as its earnings (%d)" % price)
	check(ledger(w) == c0, "coins conserved over the day (ledger %d -> %d)" % [c0, ledger(w)])
	check(int(w.stats.get("used_iron_bar", 0.0)) - used0 >= int(t["in"].iron_bar) and c.inv.count(T) == 1 and int(w.stats.get("repaired_axe", 0.0)) == 1,
		"the repair used the forge share of materials (counted used_<input>) and made no axe: the customer still holds its one")


func test_refunds() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var sm: NPC = p[0]
	var c: NPC = p[1]
	var rp: EconRepairs = w.economy.repairs
	var c0 := ledger(w)
	var price := rp.quote(sm, c.inv, T)
	rp.open(c, sm, T, price)
	var rec: Dictionary = rp.open_for(World.npc_ref(c.id), T)
	rp.dawn(int(rec.due_day))
	check(str(rec.state) == "open", "still open on its last day")
	rp.dawn(int(rec.due_day) + 1)
	check(str(rec.state) == "cancelled" and c.coins == 200 and rp.escrow() == 0 and ledger(w) == c0, "not done in time: the price comes back whole")
	rp.open(c, sm, T, price)
	var r2: Dictionary = rp.open_for(World.npc_ref(c.id), T)
	c.inv.remove(T, 1)
	c.inv.durability.erase(T)
	rp.dawn(w.day())
	check(str(r2.state) == "cancelled" and c.coins == 200 and ledger(w) == c0, "the tool went (sold, lost): refunded")
	wear_to(c.inv, T, 36)
	rp.open(c, sm, T, price)
	var r3: Dictionary = rp.open_for(World.npc_ref(c.id), T)
	EconomyFoundation.set_override({"enabled": true, "market": {"drive": true, "paid_repair": false}})
	rp.cfg = {"drive": true, "paid_repair": false}
	rp.dawn(w.day())
	check(str(r3.state) == "cancelled" and c.coins == 200 and rp.escrow() == 0 and ledger(w) == c0, "paid_repair switched off: open orders are refunded at the next dawn")


func test_deaths() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var sm: NPC = p[0]
	var c: NPC = p[1]
	var rp: EconRepairs = w.economy.repairs
	var c0 := ledger(w)
	var price := rp.quote(sm, c.inv, T)
	rp.open(c, sm, T, price)
	var rec: Dictionary = rp.open_for(World.npc_ref(c.id), T)
	w.kill(sm, "old age")
	check(str(rec.state) == "cancelled" and c.coins == 200 and ledger(w) == c0, "the smith died: the customer is refunded")
	var w2 := new_world()
	var p2: Array = pair(w2)
	var rp2: EconRepairs = w2.economy.repairs
	var c2 := ledger(w2)
	rp2.open(p2[1], p2[0], T, rp2.quote(p2[0], p2[1].inv, T))
	var r2: Dictionary = rp2.open_for(World.npc_ref(p2[1].id), T)
	w2.kill(p2[1], "old age")
	check(str(r2.state) == "settled" and rp2.escrow() == 0 and ledger(w2) == c2, "the customer died: refunded to its estate; coins conserved")


func test_choice() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var sm: NPC = p[0]
	var c: NPC = p[1]
	var rp: EconRepairs = w.economy.repairs
	wear_to(c.inv, T, 100)
	rp.on_wear(c, T)
	check(rp.candidates.is_empty(), "a little-worn axe (under repair.npc_min_missing) marks nobody")
	wear_to(c.inv, T, 36)
	rp.on_wear(c, T)
	check(rp.candidates.has(World.npc_ref(c.id)), "an axe worn past the share marks its holder for the dawn")
	c.coins = 0
	var ch := rp.consider(c, T)
	check(str(ch.act) == "wait", "without the coins the order is infeasible: it does without for now")
	c.coins = 200
	var kin: Array = w.npcs.filter(func(n): return n.alive and n != sm and n.household == sm.household and sm.household >= 0 and n.role == "adult")
	if not kin.is_empty():
		wear_to(kin[0].inv, T, 20)
		check(rp.consider(kin[0], T).act == "none", "a smith's own household is mended for nothing (the existing path), not paid")
	var c0 := ledger(w)
	var picks := {}
	for d in 3:
		var w3 := new_world()
		var q: Array = pair(w3)
		w3.economy.repairs.on_wear(q[1], T)
		w3.economy.repairs.dawn(w3.day())
		picks[d] = [str(w3.economy.repairs.open_records().map(func(r): return [r.customer, r.smith, r.price])), ledger(w3)]
	check(picks[0] == picks[1] and picks[1] == picks[2], "deterministic: the same world weighs and orders the same way (%s)" % str(picks[0][0]))
	check(float(w.stats.get("paid_repair_weighed", 0.0)) >= 1.0 and ledger(w) == c0, "weighed through the shared engine; nothing moved by weighing")


func test_save_and_replay() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var rp: EconRepairs = w.economy.repairs
	var price := rp.quote(p[0], p[1].inv, T)
	rp.open(p[1], p[0], T, price)
	rp.candidates["npc:9999"] = true
	var c0 := ledger(w)
	var s := JSON.stringify(w.to_dict())
	check(s.contains("\"repairs\""), "economy on: the open order is saved (economy.repairs)")
	var back := World.new()
	back.load_dict(VillageMap.load_default(), JSON.parse_string(s))
	check(back.economy.repairs.escrow() == price and back.economy.repairs.to_dict() == rp.to_dict() and ledger(back) == c0,
		"load: the order, its escrow and the candidates come back exactly; the ledger matches")
	# switched off: the section is parked and its escrow still counted
	EconomyFoundation.set_override(EconomyFoundation.off_config())
	var parked := World.new()
	parked.load_dict(VillageMap.load_default(), JSON.parse_string(s))
	check(parked.economy == null and EconomyFoundation.parked_coins(parked.economy_foreign) == price and ledger(parked) == c0,
		"economy off on that save: the section parked, its %d coins of escrow still counted (ledger exact)" % price)
	check(JSON.stringify(parked.to_dict()).contains("\"repairs\""), "and written back unchanged")
