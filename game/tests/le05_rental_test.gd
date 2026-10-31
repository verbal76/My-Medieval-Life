extends SceneTree
## LE05-RENTAL (owner directive 2026-10-31, docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md, LE-05 B; behind the
## Living Economy switch): a worker short of its trade's tool rents a spare from a willing owner through the transaction authority.
## Each path with exact coin and item conservation: opening, the daily fee, return at the term's end, breakage, loss (theft, sale,
## a gift), the renter's death, the owner's death (its estate succeeds), a player's and a guest's rental by the host's verbs (own
## rental only, repeated requests safe), the choice weighed against buying and doing without, save/load and replay, the switch off.
## Run headless:  godot --headless --path game --script res://tests/le05_rental_test.gd

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


func new_world(on := true, rental := true) -> World:
	if on:
		var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		c.enabled = true
		c.market.rental = rental
		EconomyFoundation.set_override(c)
	else:
		EconomyFoundation.set_override({})
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_switch()
	test_open_and_return()
	test_broken()
	test_lost()
	test_renter_dies()
	test_owner_dies()
	test_player_and_guest()
	test_choice()
	test_save_and_replay()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func adults(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household >= 0)


## Every axe in the world (every holder, the settlements, transit).
func axes(w: World) -> int:
	return int(SettlementHoldings.goods(w).get(T, 0)) + int(w.regions.goods().get(T, 0)) + int(w.transactions.in_transit().goods.get(T, 0))


## The coin invariant: the world's coins less what crossed its boundary (escrow, settlements) never changes by itself.
func ledger(w: World) -> int:
	return w.total_coins() - w.coin_sources


## Nobody but `o` has an axe to spare (the test's lender is the only one).
func only_lender(w: World, o: NPC, keep: Array) -> void:
	for v: NPC in w.npcs:
		if v != o and not keep.has(v) and w.economy.rentals.spare(v, T) > 0:
			v.inv.remove(T, w.economy.rentals.spare(v, T))


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
	r.skills["woodcutting"] = 0
	return [r, o]


func test_switch() -> void:
	var off := new_world(false)
	var p: Array = pair(off)
	check(off.economy == null and off.player_rent_tool(p[1], T) == "Nobody rents out tools here.", "economy off: no rental anywhere")
	var c0: int = p[0].coins
	off.brain._get_tool(p[0], T)
	check(not str(p[0].plan).contains("rent_from") and p[0].coins == c0, "economy off: a worker short of an axe goes on as before (buy or wait)")
	var norent := new_world(true, false)
	check(norent.economy != null and not norent.economy.rentals.active() and norent.economy.rentals.consider(norent.npcs[0], T, null).act == "buy",
		"economy on, market.rental off: nothing rents")
	check(not JSON.stringify(off.to_dict()).contains("rentals"), "economy off: the save has no rental key")


func test_open_and_return() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	var c0 := ledger(w)
	var a0 := axes(w)
	var dep := EconRentals.deposit_for(T)
	var res := rs.open(r, o, T)
	check(res.ok and r.inv.count(T) == 1 and o.inv.count(T) == 1 and r.coins == 100 - dep and rs.escrow() == dep,
		"opening: one axe to the renter, its deposit (%d, the axe's value) escrowed" % dep)
	check(rs.owner_of(World.npc_ref(r.id), T) == World.npc_ref(o.id), "the owner stays identifiable while it is lent")
	check(ledger(w) == c0 and axes(w) == a0, "opening: no coin or axe made or lost")
	check(rs.open(r, o, T).code == "already_renting", "a second rental of the same tool is refused")
	var replay: Dictionary = w.transactions.lend(str(res.txid), World.npc_ref(r.id), World.npc_ref(o.id), T, dep)
	check(replay.replay and r.inv.count(T) == 1 and rs.escrow() == dep and ledger(w) == c0, "the authority's id is single-use: a replay moves nothing")
	r.inv.wear(T, 30)                                       # a day's work: 30 of 120 uses
	var fee := EconRentals.fee_for(T, 30)
	var oc := o.coins
	rs.dawn(w.day() + 1)
	check(o.coins == oc + fee and r.coins == 100 - dep - fee and ledger(w) == c0, "the dawn's fee: the value of the wear used (%d coins for 30 uses), renter to owner" % fee)
	rs.dawn(w.day() + 2)
	check(o.coins == oc + fee, "a day without use costs nothing more")
	var rec: Dictionary = rs.open_for(World.npc_ref(r.id), T).duplicate()
	rs.dawn(int(rec.due_day))
	check(rs.open_for(World.npc_ref(r.id), T).is_empty() and o.inv.count(T) == 2 and int(o.inv.durability.get(T, 0)) == 90 and not r.inv.has(T),
		"at the term's end the axe goes back to its owner with its wear (90 of 120 left)")
	check(r.coins == 100 - fee and rs.escrow() == 0 and ledger(w) == c0 and axes(w) == a0, "the deposit comes back less nothing more owed; coins and axes conserved")


func test_broken() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	var c0 := ledger(w)
	var a0 := axes(w)
	var b0 := float(w.stats.get("broke_axe", 0.0))
	check(rs.open(r, o, T).ok, "a rental to break")
	var dep := EconRentals.deposit_for(T)
	var oc := o.coins
	check(w._work_wear(r, T, 999, "woodcutting", "") and not r.inv.has(T), "the axe breaks in the renter's work")
	var fee := EconRentals.fee_for(T, 120)
	check(rs.open_for(World.npc_ref(r.id), T).is_empty() and o.coins == oc + fee and r.coins == 100 - dep + (dep - fee),
		"broken: the owner is paid the axe's whole lent durability (%d), the renter gets the rest of its deposit" % fee)
	check(ledger(w) == c0 and axes(w) + int(float(w.stats.get("broke_axe", 0.0)) - b0) == a0, "coins conserved; the axe counted broken, nothing else lost")


func test_lost() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	var thief: NPC = adults(w).filter(func(n): return n != r and n != o and not n.inv.has(T))[0]
	var c0 := ledger(w)
	var a0 := axes(w)
	check(rs.open(r, o, T).ok, "a rental to lose")
	r.inv.wear(T, 40)
	w.transfer(r.inv, thief.inv, T, 1)                      # stolen, sold or given: the renter no longer holds it
	var oc := o.coins
	var rc := r.coins
	rs.dawn(w.day() + 1)
	var fee := EconRentals.fee_for(T, 120)
	check(rs.open_for(World.npc_ref(r.id), T).is_empty() and o.coins == oc + fee and r.coins == rc + EconRentals.deposit_for(T) - fee,
		"lost (stolen, sold, given away): the renter pays the whole lent value from its deposit")
	check(thief.inv.has(T) and int(thief.inv.durability.get(T, 0)) == 80 and ledger(w) == c0 and axes(w) == a0,
		"the axe stays where it went, with its wear; coins and axes conserved")
	var rec: Dictionary = rs.records.values()[0]
	check(str(rs._end(rec, "returned", "x", r.inv).code) == "not_open" and str(rec.state) == "lost", "a closed rental changes state once")


func test_renter_dies() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	check(rs.open(r, o, T).ok, "a rental whose renter dies")
	r.inv.wear(T, 12)
	var c0 := ledger(w)
	var a0 := axes(w)
	var oc := o.coins
	var fee := EconRentals.fee_for(T, 12)
	w.kill(r, "test")
	var rec: Dictionary = rs.records.values().filter(func(x): return str(x.renter) == World.npc_ref(r.id))[0]
	check(str(rec.state) == "settled" and o.inv.count(T) == 2 and int(o.inv.durability.get(T, 0)) == 108 and o.coins == oc + fee,
		"the dead renter's rented axe goes back to its owner, not to its heirs; the owner is paid the wear used (%d)" % fee)
	check(ledger(w) == c0 and axes(w) == a0 and rs.escrow() == 0, "the rest of the deposit goes to the renter's estate; coins and axes conserved")


func test_owner_dies() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	check(rs.open(r, o, T).ok, "a rental whose owner dies")
	var c0 := ledger(w)
	var a0 := axes(w)
	w.kill(o, "test")
	var rec: Dictionary = rs.open_for(World.npc_ref(r.id), T)
	var est := str(rec.get("owner", ""))
	check(not rec.is_empty() and est != World.npc_ref(o.id) and (est.begins_with("hh:") or est == World.MANOR), "the owner's estate succeeds it in the rental (%s)" % est)
	r.inv.wear(T, 24)
	rs.dawn(w.day() + 1)
	rs.dawn(int(rec.due_day))
	check(rs.open_for(World.npc_ref(r.id), T).is_empty() and not r.inv.has(T) and ledger(w) == c0 and axes(w) == a0,
		"at the term's end the axe goes to the estate (inherited), the fee to it; coins and axes conserved")


func test_player_and_guest() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	var pl := w.player
	o.inv.add(T, 1)                                         # three: two to lend
	pl.inv.remove(T, pl.inv.count(T))
	pl.coins = 100
	o.pos = pl.pos + Vector2(1, 0)
	var g := guest(w)
	g.inv.remove(T, g.inv.count(T))
	g.coins = 100
	g.pos = o.pos + Vector2(0, 1)
	var c0 := ledger(w)
	check(w.player_rent_tool(o, T) == "" and pl.inv.has(T) and rs.owner_of(World.PLAYER, T) == World.npc_ref(o.id), "the player rents an axe from a villager")
	check(w.player_rent_tool(o, T) != "" and pl.inv.count(T) == 1, "asking again changes nothing (one rental of a tool at a time)")
	check(w.player_rent_tool(o, T, g) == "" and g.inv.has(T) and rs.owner_of(Contracts.ref_of(g), T) == World.npc_ref(o.id), "a guest rents its own, under its own reference")
	check(w.player_rent_tool(o, T, g) != "", "a guest's repeated request is safe")
	pl.inv.remove(T, 1)                                     # the host's own axe goes elsewhere: it cannot give back the guest's
	g.inv.wear(T, 6)
	check(w.player_return_tool(T, g) == "" and not g.inv.has(T) and rs.open_for(Contracts.ref_of(g), T).is_empty(), "the guest gives back its own rental")
	check(w.player_return_tool(T, g) != "", "giving back twice does nothing the second time")
	check(w.player_return_tool(T) != "" and not rs.open_for(World.PLAYER, T).is_empty(), "the host does not hold its rented axe: it cannot give it back")
	check(ledger(w) == c0, "coins conserved through the players' rentals")
	check(NetActions.VERBS.has("player_rent_tool") and NetActions.VERBS.has("player_return_tool"), "rent and return are host verbs for a guest")


func guest(w: World) -> PlayerState:
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Fairlight"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.pos = w.player.pos + Vector2(1, 0)
	g.net_key = "ab".repeat(32)
	w.add_guest(g)
	return g


func test_choice() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	only_lender(w, o, [r])
	# nobody sells an axe; an owner has a spare; the renter can pay the deposit: renting is weighed and chosen
	var c := rs.consider(r, T, null)
	check(str(c.act) == "rent" and c.owner == o, "with no axe on sale and a spare to lend, the worker rents (%s)" % str(c.act))
	check(str(rs.consider(r, T, null).act) == "wait", "weighed once a day: the day's choice holds")
	# the same, but it cannot pay the deposit: it does without for now (no free equipment)
	rs.considered.clear()
	r.coins = EconRentals.deposit_for(T) - 1
	check(str(rs.consider(r, T, null).act) == "wait", "without the deposit it waits: no free tool")
	# an owner with no need of coin lends to someone it is neutral about, not to someone it strongly dislikes; in need, it may
	rs.considered.clear()
	r.coins = 100
	o.coins = 5000
	check(rs.owner_willing(o, World.npc_ref(r.id), T), "a comfortable owner lends to a renter it has no opinion of")
	w.judgment.set_ledger(o.id, r.id, 0, 90000)
	check(not rs.owner_willing(o, World.npc_ref(r.id), T) and str(rs.consider(r, T, null).act) == "wait", "a comfortable owner who strongly dislikes the renter refuses; the renter waits")
	o.coins = 0
	check(rs.owner_willing(o, World.npc_ref(r.id), T), "an owner in need of coin lends even to someone it dislikes (judgment weighs, need can outweigh it)")
	# a seller has one and the renter weighs buying it against renting from an owner it dislikes
	var w2 := new_world()
	var p2: Array = pair(w2)
	var r2: NPC = p2[0]
	var o2: NPC = p2[1]
	var seller: NPC = w2.npcs.filter(func(n): return n.alive and n.job == "smith")[0]
	only_lender(w2, o2, [r2, seller])
	seller.inv.add(T, 2)
	r2.coins = 200
	w2.judgment.set_ledger(r2.id, o2.id, 0, 90000)
	var c2 := w2.economy.rentals.consider(r2, T, seller)
	check(str(c2.act) == "buy", "a worker who dislikes the only lender buys the axe on sale instead (%s)" % str(c2.act))
	# the manor's tool is on its way (EQ-19): the existing way of getting one; it does not rent
	var w3 := new_world()
	var p3: Array = pair(w3)
	w3.manor_orders.append({"smith": -1, "tool": T, "for": p3[0].id, "paid": 0, "day": w3.day()})
	check(str(w3.economy.rentals.consider(p3[0], T, null).act) == "buy", "with the manor's tool coming it does not rent (the existing path waits)")
	# in play: the worker walks to the owner and the rental is made there
	var w4 := new_world()
	var p4: Array = pair(w4)
	var r4: NPC = p4[0]
	for v: NPC in w4.npcs:
		if v.alive and v != p4[1] and (v.job == "smith" or w4.brain.buy_role(v) == "merchant_goods"):
			v.inv.remove(T, v.inv.count(T))
	r4.plan = []
	w4.brain._get_tool(r4, T)
	check(str(r4.plan).contains("rent_from"), "the brain plans the walk to the owner (%s)" % r4.doing)
	var c4 := ledger(w4)
	for i in 6 * 60 * 2:
		w4.update(0.5)
		if r4.inv.has(T):
			break
	check(r4.inv.has(T) and w4.economy.rentals.owner_of(World.npc_ref(r4.id), T) == World.npc_ref(p4[1].id), "in play the woodcutter rents the axe and goes to work")
	check(int(w4.stats.get("rent_opened", 0)) == 1, "one rental made")


func test_save_and_replay() -> void:
	var w := new_world()
	var p: Array = pair(w)
	var r: NPC = p[0]
	var o: NPC = p[1]
	var rs: EconRentals = w.economy.rentals
	var res := rs.open(r, o, T)
	r.inv.wear(T, 18)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check((d.economy as Dictionary).has("rentals") and (d.economy.rentals.records as Array).size() == 1, "the open rental is saved under economy.rentals")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var rs2: EconRentals = w2.economy.rentals
	check(JSON.stringify(rs2.to_dict()) == JSON.stringify(rs.to_dict()), "it loads back exactly")
	var r2 := w2.npc(r.id)
	var o2 := w2.npc(o.id)
	var c0 := ledger(w2)
	check(w2.transactions.lend(str(res.txid), World.npc_ref(r2.id), World.npc_ref(o2.id), T, EconRentals.deposit_for(T)).replay and r2.inv.count(T) == 1,
		"after a load the same id replays and moves nothing")
	var due := int(rs2.open_for(World.npc_ref(r2.id), T).due_day)
	rs.dawn(due)
	rs2.dawn(due)
	check(o2.coins == o.coins and r2.coins == r.coins and o2.inv.durability.get(T, -1) == o.inv.durability.get(T, -1) and ledger(w2) == c0,
		"the loaded world settles exactly as the one that went on (deterministic)")
	check(rs2.records.size() <= rs2.keep_closed + rs2.open_records().size(), "closed rentals are kept bounded")
	# an older economy save (no rentals key) loads with none
	var e: Dictionary = (d.economy as Dictionary).duplicate()
	e.erase("rentals")
	var back := EconomyFoundation.attach(w2, e)
	check(back != null and back.rentals.is_empty(), "an economy save from before LE-05 loads with no rentals")
