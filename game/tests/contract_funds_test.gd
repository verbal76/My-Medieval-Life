extends SceneTree
## B25-CONTRACT-FUNDS-D1 (owner 2026-11-10, docs/directives/2026-11-10_contract_commitments_legacy_save_repair.md, decision 1):
## "Correct contract acceptance so merchants account for coins already committed to market bids, existing contracts, and other
## enforceable obligations ... Do not allow merchants to accept obligations they cannot fund merely because their total purse
## appears sufficient ... Prevent double-counting commitments." Found with B25-INV-P52-BLOCKS (campaign 42788018729 seed 1: the
## merchant p:52 accepted contract 963 and then could not buy the blocks: its coins were held by its own open bids).
## Contracts.means' "buy" route sized what a seller can take on by coins - reserve: the whole purse, counting coins the LE-03
## claims hold for its bids, and coins it will need for the purchases of the buy-route contracts it already holds (those are
## not reserved anywhere until it buys). Now it counts World.claims_free_coins (the rule fund_refusal already uses for the buyer)
## less the purchases its open buy-route contracts still need, at the cost recorded when each was agreed. A buyer's coins set
## aside for a contract leave its purse (_open), so they are not counted twice; an advance (CON-03) still lowers the unit cost.
## Checked:
##   1 a merchant whose coins are all held by its own bids takes on no buy-route contract it cannot fund (capacity 0, refused)
##   2 with the coins free it can (the capacity the purse above the reserve allows)
##   3 two contracts in turn: the second is sized by what the first will still need (no double counting of the same coins)
##   4 a contract the merchant already holds the goods for adds no purchase commitment
##   5 accepting changes no coins or goods (conservation); deterministic on two identical worlds
##   godot --headless --path game --script res://tests/contract_funds_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	c.market.drive = true
	EconomyFoundation.set_override(c)
	case_bids_hold_coins()
	case_two_contracts()
	case_held_goods()
	case_conservation_and_replay()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A merchant `n` with `coins` and no building blocks, a labourer `v` selling 40 blocks. Returns {w, n, v, cost}.
func setup(coins := 200, seed := 1) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var n: NPC = null
	var v: NPC = null
	for o: NPC in w.npcs:
		if n == null and o.alive and o.role == "adult" and o.job == "merchant":
			n = o
	for o: NPC in w.npcs:
		if v == null and o.alive and o.role == "adult" and o != n and o.job in ["laborer", "stonecutter"]:
			v = o
	for o: NPC in w.npcs:
		if o != v:
			o.inv.remove("building_block", o.inv.count("building_block"))
	v.inv.add("building_block", 40)
	w.treasury += n.coins - coins
	n.coins = coins
	var cost := w.deal_price(w.sell_price(v, "building_block"), n, v)
	return {"w": w, "n": n, "v": v, "cost": cost}


func _cap(w: World, n: NPC) -> Dictionary:
	return w.contracts.means(n, "building_block", 5, 1 << 20)


func _accept(w: World, n: NPC, qty: int) -> Dictionary:
	var price := 99
	var r: Dictionary = w.contracts.evaluate(n, "player", "building_block", qty, price, 5)
	if str(r.answer) != "accept":
		return {}
	var c: Dictionary = w.contracts._new_record("player", World.npc_ref(n.id), "building_block", qty, price, 5, [])
	c.route = str(r.route)
	c.terms.merge(r.terms)
	c.state = "accepted"
	w.contracts.list.append(c)
	return c


func case_bids_hold_coins() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.n
	var spare := n.coins - w.reserve_of(n)
	var held: Dictionary = w.economy.reservations.reserve(Contracts.ref_of(n), EconReservations.COINS, n.coins, "test: the merchant's own open bids")
	check(not held.is_empty() and w.claims_free_coins(n, "building_block") == 0, "fixture: the merchant's %d coins are all held by its own bids" % n.coins)
	var m := _cap(w, n)
	check(int(m.cap) == 0 and str(m.route) != "buy", "with every coin held by its bids it can take on no purchase (capacity %d, route %s)" % [int(m.cap), str(m.route)])
	var r: Dictionary = w.contracts.evaluate(n, "player", "building_block", 6, 99, 5)
	check(str(r.answer) != "accept", "and a 6-block contract is not accepted (answer %s: %s)" % [str(r.answer), str(r.say)])
	w.economy.reservations.release(int(held.id))
	m = _cap(w, n)
	var want := mini(40, spare / maxi(1, int(s.cost)))
	check(str(m.route) == "buy" and int(m.cap) == want, "with the coins free again it can take on %d (the purse above the reserve at %d each; capacity %d)" % [want, int(s.cost), int(m.cap)])
	w.dispose()


func case_two_contracts() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.n
	var cost := int(s.cost)
	w._reserve_cache.clear()
	var r0 := w.reserve_of(n)
	w.treasury += n.coins - (r0 + 20 * cost)
	n.coins = r0 + 20 * cost                      # coins (not the seller's 40 blocks) are what limits it: 20 blocks' worth
	w._reserve_cache.clear()
	var spare := n.coins - w.reserve_of(n)
	var first := 15
	var c1 := _accept(w, n, first)
	check(not c1.is_empty() and str(c1.route) == "buy", "fixture: a first contract for %d blocks taken on by buying (%s)" % [first, str(c1.get("route", ""))])
	var m := _cap(w, n)
	var left := maxi(0, (spare - first * cost) / cost)
	check(int(m.cap) == left, "a second contract is sized by what the first will still need: capacity %d (expected %d, not %d again)" % [int(m.cap), left, spare / cost])
	w.dispose()


func case_held_goods() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.n
	n.inv.add("building_block", 6)
	var c1 := _accept(w, n, 6)
	check(not c1.is_empty(), "fixture: a contract for 6 blocks the merchant already holds (route %s)" % str(c1.get("route", "")))
	n.inv.remove("building_block", 6)
	n.inv.add("building_block", 6)
	var m := _cap(w, n)
	var spare := n.coins - w.reserve_of(n)
	var free_cap := mini(40, spare / int(s.cost))
	check(int(m.cap) == free_cap or str(c1.get("route", "")) != "buy", "goods already in hand add no purchase commitment (capacity %d of %d)" % [int(m.cap), free_cap])
	w.dispose()


func case_conservation_and_replay() -> void:
	var a := setup()
	var b := setup()
	var w: World = a.w
	var c0 := w.total_coins()
	var g0: int = (a.v as NPC).inv.count("building_block") + (a.n as NPC).inv.count("building_block")
	var ra: Dictionary = w.contracts.evaluate(a.n, "player", "building_block", 6, 99, 5)
	var rb: Dictionary = b.w.contracts.evaluate(b.n, "player", "building_block", 6, 99, 5)
	check(w.total_coins() == c0 and (a.v as NPC).inv.count("building_block") + (a.n as NPC).inv.count("building_block") == g0, "evaluating a contract moves no coins or goods")
	check(JSON.stringify(ra) == JSON.stringify(rb), "two identical worlds give the same answer (deterministic)")
	a.w.dispose()
	b.w.dispose()
