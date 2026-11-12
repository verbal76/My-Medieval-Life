extends SceneTree
## REG-02 debt part (owner decision 2026-11-10, B25-REG02-DEBT-D1, option (b) as qualified): a villager who leaves for a settlement
## settles their debts as they pack. Before the fix a debt with a party gone from the village stayed "open" for ever: Credit.dawn
## skipped it (the party is not alive), so it was neither repaid nor recorded as a default.
## Checks: a leaver who can pay repays the debt (coins move, both ledgers unchanged); one who cannot defaults (recorded, kept);
## a debt owed TO a leaver is repaid by a debtor who can, else stays open (not written off); a debt between two leavers stays
## as it is; the result survives a save and load.
## Run headless:  godot --headless --path game --script res://tests/reg02_departure_debts_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	test_debtor_pays()
	test_debtor_defaults()
	test_creditor_leaves_paid()
	test_creditor_leaves_unpaid_stays_open()
	test_both_leave_together()
	test_save_load_keeps_outcome()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0.0))


func ledger(w: World) -> int:
	return w.total_coins() - w.coin_sources


func booked(w: World) -> int:
	return w.total_coins() - (_st(w, "caravan_coins_in") + _st(w, "newcomer_coins_in") + _st(w, "scenario_coins_in") + _st(w, "outlaw_coins_in")
		- _st(w, "caravan_coins_out"))


## Two adults of different households, neither the reeve nor a guard (free to move).
func pair(w: World) -> Array:
	var ad: Array = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 0 and not n.job in ["reeve", "guard", "preacher"])
	var a: NPC = ad[0]
	for b: NPC in ad:
		if b.household != a.household:
			return [a, b]
	return []


func debt(w: World, creditor: NPC, debtor: NPC, value: int) -> Dictionary:
	var d := {"id": w.credit.next_id, "creditor": Credit.ref_of(creditor), "debtor": Credit.ref_of(debtor), "item": "bread", "qty": 1,
			"value": value, "made": w.day(), "due": w.day() + 3, "state": Credit.OPEN, "ended": -1}
	w.credit.next_id += 1
	w.credit.debts.append(d)
	return d


func settlement(w: World) -> OffMapSettlement:
	var ids: Array = w.regions.by_id.keys()
	ids.sort()
	return w.regions.by_id[ids[0]]


## `ms` move to a settlement as a work move does (Migration's packing steps).
func leave(w: World, ms: Array) -> void:
	var s := settlement(w)
	Migration._pre_leave(w, ms)
	var pantry := Migration._take_own(w, ms)
	var load_ := Migration._pack(w, ms, pantry)
	for i in load_.people.size():
		s.receive_person(load_.people[i], int(load_.coins) if i == 0 else 0, load_.goods if i == 0 else {}, Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	Migration._gone(w, s, ms, load_, pantry, "work")


func dawns(w: World, n: int) -> void:
	for i in n:
		w.credit.dawn()


func test_debtor_pays() -> void:
	var w := new_world()
	var p := pair(w)
	var cre: NPC = p[0]
	var deb: NPC = p[1]
	deb.coins = 50
	var c0 := cre.coins
	var d := debt(w, cre, deb, 12)
	var l0 := ledger(w)
	var b0 := booked(w)
	leave(w, [deb])
	check(str(d.state) == Credit.REPAID, "a leaver who can pay repays the debt as they pack (state %s)" % d.state)
	check(cre.coins == c0 + 12, "the creditor who stays received the 12 coins")
	check(ledger(w) == l0 and booked(w) == b0, "coins conserved: both ledgers unchanged (%d/%d -> %d/%d)" % [l0, b0, ledger(w), booked(w)])


func test_debtor_defaults() -> void:
	var w := new_world()
	var p := pair(w)
	var cre: NPC = p[0]
	var deb: NPC = p[1]
	deb.coins = 5
	var c0 := cre.coins
	var d := debt(w, cre, deb, 12)
	leave(w, [deb])
	dawns(w, 10)
	check(str(d.state) == Credit.DEFAULTED, "a leaver who cannot pay has a recorded default, not an open debt for ever (state %s)" % d.state)
	check(cre.coins == c0, "nothing was taken from or given to the creditor")
	check(w.credit.debts.has(d), "the default stays on the record")


func test_creditor_leaves_paid() -> void:
	var w := new_world()
	var p := pair(w)
	var cre: NPC = p[0]
	var deb: NPC = p[1]
	deb.coins = 400
	var d := debt(w, cre, deb, 12)
	var l0 := ledger(w)
	var b0 := booked(w)
	var d0 := deb.coins
	leave(w, [cre])
	check(str(d.state) == Credit.REPAID, "a debtor who stays and can pay repays a leaving creditor (state %s)" % d.state)
	check(deb.coins == d0 - 12, "the debtor paid 12 coins")
	check(ledger(w) == l0 and booked(w) == b0, "coins conserved when the creditor leaves with the repayment")


func test_creditor_leaves_unpaid_stays_open() -> void:
	var w := new_world()
	var p := pair(w)
	var cre: NPC = p[0]
	var deb: NPC = p[1]
	deb.coins = 0
	var d := debt(w, cre, deb, 12)
	leave(w, [cre])
	check(str(d.state) == Credit.OPEN, "a debt owed to a leaver that cannot be paid now stays open (not written off)")


func test_both_leave_together() -> void:
	var w := new_world()
	var p := pair(w)
	var cre: NPC = p[0]
	var deb: NPC = p[1]
	deb.coins = 50
	var d := debt(w, cre, deb, 12)
	leave(w, [cre, deb])
	check(str(d.state) == Credit.OPEN, "a debt between two who leave together continues between them")


func test_save_load_keeps_outcome() -> void:
	var w := new_world()
	var p := pair(w)
	var cre: NPC = p[0]
	var deb: NPC = p[1]
	deb.coins = 5
	var d := debt(w, cre, deb, 12)
	leave(w, [deb])
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.credit.to_dict()))
	var c2 := Credit.new(w)
	c2.load_dict(saved)
	var found := c2.debts.filter(func(x) -> bool: return int(x.id) == int(d.id))
	check(found.size() == 1 and str(found[0].state) == Credit.DEFAULTED, "the recorded default survives a save and load")
