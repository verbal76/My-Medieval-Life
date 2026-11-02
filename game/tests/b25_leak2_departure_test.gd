extends SceneTree
## B25-LEAK2 (GitHub Actions run 41403541582, seed 2, --market: "FATAL day 180 seed 2: currency leak -2"): a villager with a tool on
## LE-05 rent moved to a settlement (Migration). Nothing settled the rental when they left, so at the next dawn it ended "lost" and
## the rest of the deposit (2 coins), owed to a renter who was no longer there, left the world as an outside flow (estate_out_coins):
## World.coin_sources fell, but no boundary flow the village books (caravan_coins_in/out, newcomer_, outlaw_, scenario_) moved, so
## economy_sim's currency ledger broke. Now Migration._pre_leave settles a leaver's rentals and paid-repair orders to their own purse
## (it goes with them, booked as migrant coins), and an escrow refund owed to a party no longer there goes to its estate.
## Each path checks both coin identities economy_sim uses: total - coin_sources, and total - (booked flows in - out).
## Run headless:  godot --headless --path game --script res://tests/b25_leak2_departure_test.gd

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


func new_world() -> World:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	c.market.rental = true
	c.market.paid_repair = true
	EconomyFoundation.set_override(c)
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_renter_leaves_with_tool()
	test_renter_leaves_without_tool()
	test_renter_gone_unsettled()
	test_repair_customer_leaves()
	test_repair_smith_leaves()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _st(w: World, k: String) -> int:
	return int(w.stats.get(k, 0.0))


## economy_sim's ledger: the coins less what the village booked as crossing its boundary (constant unless coins are made or lost).
func booked(w: World) -> int:
	return w.total_coins() - (_st(w, "caravan_coins_in") + _st(w, "newcomer_coins_in") + _st(w, "scenario_coins_in") + _st(w, "outlaw_coins_in")
		- _st(w, "caravan_coins_out"))


## The coin invariant of the LE-05 tests: the world's coins less what crossed its boundary.
func ledger(w: World) -> int:
	return w.total_coins() - w.coin_sources


func adults(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 0)


## A woodcutter without an axe (the renter) and another villager, not of its household, with two new axes (the owner).
func pair(w: World) -> Array:
	var r: NPC = w.npcs.filter(func(n): return n.alive and n.job == "woodcutter")[0]
	var o: NPC = adults(w).filter(func(n): return n.job != "woodcutter" and n.job != "smith" and n.household != r.household and n.job != "merchant")[0]
	r.inv.remove(T, r.inv.count(T))
	r.inv.durability.erase(T)
	r.coins = 100
	o.inv.remove(T, o.inv.count(T))
	o.inv.add(T, 2)
	o.inv.durability.erase(T)
	o.coins = 20
	return [r, o]


func settlement(w: World) -> OffMapSettlement:
	var ids: Array = w.regions.by_id.keys()
	ids.sort()
	return w.regions.by_id[ids[0]]


## `who` moves to a settlement as a work move does (Migration._work_out's steps). `pre`: the steps before packing are run (false: as
## before B25-LEAK2, when nothing settled a leaver's rentals). Returns the coins they took.
func leave(w: World, who: NPC, pre := true) -> int:
	var s := settlement(w)
	if pre:
		Migration._pre_leave(w, [who])
	var pantry := Migration._take_own(w, [who])
	var load_ := Migration._pack(w, [who], pantry)
	s.receive_person(load_.people[0], int(load_.coins), load_.goods, Migration.hiring(s) if Migration.hiring(s) != "" else "farm")
	Migration._gone(w, s, [who], load_, pantry, "work")
	return int(load_.coins)


func test_renter_leaves_with_tool() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	check(rs.open(r, o, T).ok, "a rental whose renter moves away holding the axe")
	r.inv.wear(T, 12)
	var c0 := ledger(w)
	var b0 := booked(w)
	var out0 := _st(w, "estate_out_coins")
	var oc := o.coins
	var fee := EconRentals.fee_for(T, 12)
	var purse := r.coins + EconRentals.deposit_for(T) - fee
	var took := leave(w, r)
	var rec: Dictionary = rs.records.values()[0]
	check(str(rec.state) == "settled" and rs.escrow() == 0 and o.inv.count(T) == 2 and o.coins == oc + fee,
		"settled before they pack: the axe back to its owner, the wear used (%d) paid" % fee)
	check(took == purse, "the rest of the deposit went into their purse and left with them (%d coins)" % took)
	check(ledger(w) == c0 and booked(w) == b0 and _st(w, "estate_out_coins") == out0, "no coin made or lost: both ledgers hold, nothing left as an outside flow")
	rs.dawn(w.day() + 1)
	check(str(rec.state) == "settled" and ledger(w) == c0 and booked(w) == b0, "the next dawn ends nothing more (no 'lost' rental)")


func test_renter_leaves_without_tool() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	check(rs.open(r, o, T).ok, "a rental whose renter moves away no longer holding the axe")
	var other: NPC = adults(w).filter(func(n): return n != r and n != o and not n.inv.has(T))[0]
	w.transfer(r.inv, other.inv, T, 1)
	var c0 := ledger(w)
	var b0 := booked(w)
	var out0 := _st(w, "estate_out_coins")
	var oc := o.coins
	var fee := mini(EconRentals.deposit_for(T), EconRentals.fee_for(T, 120))
	var purse := r.coins + EconRentals.deposit_for(T) - fee
	var took := leave(w, r)
	check(str(rs.records.values()[0].state) == "settled" and rs.escrow() == 0 and o.coins == oc + fee and took == purse,
		"settled to them before they pack: the whole lent value to the owner, the rest of the deposit with them")
	check(ledger(w) == c0 and booked(w) == b0 and _st(w, "estate_out_coins") == out0, "both ledgers hold")


## The run's path: a renter who is no longer there (a save from before the fix, where they left with the rental open) when the dawn
## ends the rental "lost". The rest of the deposit goes to their estate in the village, never out of the world.
func test_renter_gone_unsettled() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	check(rs.open(r, o, T).ok, "a rental left open when its renter moved away (as before B25-LEAK2)")
	r.inv.wear(T, 30)
	rs.dawn(w.day() + 1)                                    # a dawn's fee paid: the whole lent value less it is owed back at a loss
	leave(w, r, false)                                      # the axe goes with them
	var rec: Dictionary = rs.records.values()[0]
	check(str(rec.state) == "open" and rs.escrow() > 0, "the rental is still open, its deposit escrowed in the village")
	var c0 := ledger(w)
	var b0 := booked(w)
	var out0 := _st(w, "estate_out_coins")
	var t0 := w.treasury
	var hh0 := 0
	for n: NPC in w.npcs:
		if n.alive and n.household == r.household:
			hh0 += n.coins
	var refund := EconRentals.deposit_for(T) - mini(EconRentals.deposit_for(T), EconRentals.fee_for(T, int(rec.lent_wear)) - int(rec.paid))
	check(refund > 0, "a part of the deposit (%d) is owed back to the renter" % refund)
	rs.dawn(w.day() + 2)
	var hh1 := 0
	for n: NPC in w.npcs:
		if n.alive and n.household == r.household:
			hh1 += n.coins
	check(str(rec.state) == "lost" and rs.escrow() == 0, "the dawn ends it 'lost' (the renter does not hold the axe)")
	check(_st(w, "estate_out_coins") == out0 and (hh1 - hh0) + (w.treasury - t0) >= refund,
		"the rest of the deposit (%d) goes to the renter's estate, not out of the world" % refund)
	check(ledger(w) == c0 and booked(w) == b0, "both ledgers hold (before the fix: booked off by %d, the run's 'currency leak')" % -refund)


## A smith and a woodcutter of another household with a worn axe (le05_paid_repair_test's pair).
func repair_pair(w: World) -> Array:
	var sm: NPC = w.npcs.filter(func(n): return n.alive and n.job == "smith")[0]
	var c: NPC = w.npcs.filter(func(n): return n.alive and n.job == "woodcutter" and n.role == "adult" and n.household != sm.household)[0]
	sm.inv.add("iron_bar", 4)
	sm.inv.add("plank", 2)
	c.inv.remove(T, c.inv.count(T))
	c.inv.add(T)
	c.inv.durability[T] = 36
	c.coins = 200
	return [sm, c]


func test_repair_customer_leaves() -> void:
	var w := new_world()
	var p: Array = repair_pair(w)
	var sm: NPC = p[0]
	var c: NPC = p[1]
	var rp: EconRepairs = w.economy.repairs
	var price := rp.quote(sm, c.inv, T)
	check(price > 0 and rp.open(c, sm, T, price).ok and rp.escrow() == price, "a paid repair whose customer moves away (price %d)" % price)
	var c0 := ledger(w)
	var b0 := booked(w)
	var out0 := _st(w, "estate_out_coins")
	var took := leave(w, c)
	check(str(rp.records.values()[0].state) == "cancelled" and rp.escrow() == 0 and took == 200, "refunded before they pack: the price leaves with them")
	check(ledger(w) == c0 and booked(w) == b0 and _st(w, "estate_out_coins") == out0, "both ledgers hold")


func test_repair_smith_leaves() -> void:
	var w := new_world()
	var p: Array = repair_pair(w)
	var sm: NPC = p[0]
	var c: NPC = p[1]
	var rp: EconRepairs = w.economy.repairs
	var price := rp.quote(sm, c.inv, T)
	check(rp.open(c, sm, T, price).ok, "a paid repair whose smith moves away")
	var c0 := ledger(w)
	var b0 := booked(w)
	leave(w, sm)
	check(str(rp.records.values()[0].state) == "cancelled" and rp.escrow() == 0 and c.coins == 200, "the customer is refunded in full")
	check(ledger(w) == c0 and booked(w) == b0, "both ledgers hold")
