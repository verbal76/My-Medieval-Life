extends SceneTree
## VER-CON-50ORE (owner, 2026-10-23): "include a focused real-world example of a 50-ore quantity contract using existing
## functionality. Verify actual production, inventory conservation, delivery, payment, and deadline behavior." One CON-01
## contract for 50 iron ore between the player and a real miner, made through the calls the talk window makes
## (Contracts.propose) and then run through the live World day by day (World.update), nothing stepped by hand. Asserted
## from real state: the ore is really mined (the goods ledger), arrives in lots, is paid per unit from the player's real
## coins, coins and ore are conserved, and the deadline is honoured or the contract lapses by the existing rule. A second
## short case runs the same 50 against a deadline the miner cannot keep, to show the lapse branch. No limit is changed.
##   godot --headless --path game --script res://tests/contract_50ore_test.gd

const Census := preload("res://tests/census.gd")
const STEP := 0.5
const QTY := 50
const PRICE := 8
const DAYS := 6

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		printerr("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_fifty_ore()
	test_fifty_ore_lapse()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _home(w: World) -> void:
	for id in w.buildings:
		if str(w.buildings[id].get("type", "")) == "house":
			w.player.home = id
			return


## One game day of the live world, as conservation_test runs it; the idle player is fed.
func _day(w: World) -> void:
	var steps := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for i in steps:
		w.update(STEP)
		w.player.hunger = 100.0


func _d(w: World, s0: Dictionary, k: String) -> int:
	return int(w.stats.get(k, 0)) - int(s0.get(k, 0))


## The ore ledger since `s0` (economy_sim's rule for one good): held(now) = held(start) + produced - consumed.
func _ore_residual(w: World, g0: int, s0: Dictionary) -> int:
	var id := "iron_ore"
	var produced := _d(w, s0, "made_" + id) + _d(w, s0, "mined_" + id) + _d(w, s0, "felled_" + id) + _d(w, s0, "dug_" + id) + _d(w, s0, "cut_" + id)
	var consumed := _d(w, s0, "used_" + id) + _d(w, s0, "used_building_" + id) + _d(w, s0, "used_works_" + id) + _d(w, s0, "used_repairs_" + id) \
		+ _d(w, s0, "broke_" + id) + _d(w, s0, "spoiled_" + id) + _d(w, s0, "burned_" + id) + _d(w, s0, "eaten_" + id)
	var net := _d(w, s0, "imported_" + id) - _d(w, s0, "exported_" + id)
	return int(Census.goods(w).get(id, 0)) - (g0 + produced + net - consumed)


func _leak(w: World, coins0: int, s0: Dictionary) -> int:
	var c_in := _d(w, s0, "caravan_coins_in") + _d(w, s0, "newcomer_coins_in") + _d(w, s0, "scenario_coins_in")
	return w.total_coins() - coins0 - c_in + _d(w, s0, "caravan_coins_out")


## The case: 50 iron ore at 8 a unit within 6 days, from the village's miner, delivered to the player's chest.
func test_fifty_ore() -> void:
	var w := _world()
	var m: NPC = w.brain._first_with_job("miner")
	if not m.inv.has("pickaxe"):
		m.inv.add("pickaxe")
	_home(w)
	w.player.pos = m.pos                      # face to face: 400 coins is a formal contract (Q18-13)
	w.player.coins = 1000
	var lot := int(Contracts.cfg().delivery_lot)
	# the existing limits answer for 50: none of max_open_player (3), max_open_per_seller (2), max_days (10) is reached
	check(QTY > lot and DAYS <= int(Contracts.cfg().max_days), "50 is more than one lot (%d) and %d days is inside max_days (%d)" % [lot, DAYS, int(Contracts.cfg().max_days)])
	var r := w.contracts.propose(World.PLAYER, m, "iron_ore", QTY, PRICE, DAYS)
	check(str(r.answer) == "accept" and r.has("contract"), "the miner accepts 50 iron ore at %d each in %d days (%s)" % [PRICE, DAYS, str(r.get("say", ""))])
	if not r.has("contract"):
		return
	var c: Dictionary = r.contract
	var total := QTY * PRICE
	check(str(c.route) == "mine" and int(c.reserved) == total and w.player.coins == 1000 - total, "by mining; %d coins set aside from the player's purse" % total)
	var ore0 := Census.goods(w).get("iron_ore", 0) as int
	var coins0 := w.total_coins()
	var stats0 := w.stats.duplicate()
	var miner0 := m.coins
	var chest0 := w.player.chest.count("iron_ore")
	var deadline := int(c.deadline_day)
	var day0 := w.day()
	var log := []
	var max_held := 0
	while str(c.state) == "accepted" and w.day() <= deadline + 1:
		_day(w)
		max_held = maxi(max_held, m.inv.count("iron_ore"))
		log.append("day %d: delivered %d, paid %d, miner holds %d, chest +%d, mined %d" % [w.day(), int(c.delivered), int(c.paid), m.inv.count("iron_ore"),
				w.player.chest.count("iron_ore") - chest0, _d(w, stats0, "mined_iron_ore")])
	for line in log:
		print("     ", line)
	print("     contract: state %s delivered %d paid %d, deadline day %d (end of day %d), ended day %s" % [c.state, int(c.delivered), int(c.paid), deadline, deadline + 1, str(c.get("ended_day", "-"))])
	# (b) deliveries in lots by the existing rule
	var drops: Array = (c.history as Array).filter(func(h): return str(h.what) == "deliver")
	var sizes := drops.map(func(h): return int(h.qty))
	print("     delivery lots: ", sizes)
	var lots_ok := not drops.is_empty()
	var left := QTY
	for h in drops:
		lots_ok = lots_ok and int(h.qty) >= mini(lot, left)       # never walks over fewer than a lot (or what is still owed)
		left -= int(h.qty)
	check(lots_ok and drops.size() > 1, "the ore came in %d deliveries, each at least a lot (%d) or what was still owed" % [drops.size(), lot])
	# (a) production: really mined, from the seams, not from nowhere
	var mined := _d(w, stats0, "mined_iron_ore")
	var delivered := int(c.delivered)
	check(mined >= delivered and delivered > 0, "the ledger shows %d iron ore mined while %d were delivered" % [mined, delivered])
	check(_d(w, stats0, "made_iron_ore") == 0 and _d(w, stats0, "imported_iron_ore") == 0, "none was made or imported; the ore came out of the seams")
	check(w.player.chest.count("iron_ore") - chest0 == delivered, "the player's chest holds exactly the %d delivered (+%d)" % [delivered, w.player.chest.count("iron_ore") - chest0])
	# (c) payment per unit, from the player's real coins to the miner
	check(int(c.paid) == delivered * PRICE and _d(w, stats0, "contract_paid") == int(c.paid) and _d(w, stats0, "contract_units") == delivered, "paid %d = %d units x %d (the world's contract_paid and contract_units agree)" % [int(c.paid), delivered, PRICE])
	check(w.player.coins == 1000 - int(c.paid) and int(c.reserved) == 0, "the player is out exactly the %d paid (purse %d), nothing left set aside" % [int(c.paid), w.player.coins])
	print("     miner's purse %d -> %d (it also spends on its own keep; the %d paid is in the conserved total)" % [miner0, m.coins, int(c.paid)])
	# (d) conservation
	var leak := _leak(w, coins0, stats0)
	check(leak == 0, "coins are conserved over %d days (total %d -> %d, leak %d)" % [w.day() - day0, coins0, w.total_coins(), leak])
	var res := _ore_residual(w, ore0, stats0)
	check(res == 0, "ore is conserved: held %d -> %d, mined %d, used %d, residual %d" % [ore0, int(Census.goods(w).get("iron_ore", 0)), mined, _d(w, stats0, "used_iron_ore"), res])
	var held := m.inv.count("iron_ore") + w.player.chest.count("iron_ore") + w.player.inv.count("iron_ore")
	check(held <= mined + 0 + ore0 and delivered <= mined, "ore with miner and player (%d) never exceeds what was mined (%d) plus what existed (%d)" % [held, mined, ore0])
	# (e) the deadline
	if str(c.state) == "fulfilled":
		check(delivered == QTY and int(c.paid) == total and w.day() <= deadline + 1, "50 reached in time: fulfilled with all %d paid, ended day %d (deadline day %d)" % [total, int(c.ended_day), deadline])
	else:
		check(str(c.state) == "lapsed" and int(c.reserved) == 0 and w.player.coins == 1000 - int(c.paid), "not reached: lapsed by the existing rule; %d delivered and %d paid stand, the rest returned" % [delivered, int(c.paid)])


## The other branch: the same 50, countered to a longer deadline (2 days is too few), then the player loses the home the
## miner brings ore to after the first day. The existing plan() only walks ore to a buyer who has a home; so no lot can
## arrive, the deadline passes, and the contract lapses at dawn by the existing rule: what was delivered and paid stands,
## the unpaid coins return to the player.
func test_fifty_ore_lapse() -> void:
	var w := _world()
	var m: NPC = w.brain._first_with_job("miner")
	if not m.inv.has("pickaxe"):
		m.inv.add("pickaxe")
	_home(w)
	w.player.pos = m.pos
	w.player.coins = 1000
	var r := w.contracts.propose(World.PLAYER, m, "iron_ore", QTY, PRICE, 2)
	check(str(r.answer) == "counter" and int(r.days) > 2, "50 in 2 days is countered with %d days (%s)" % [int(r.days), str(r.get("say", ""))])
	var r2 := w.contracts.propose(World.PLAYER, m, "iron_ore", QTY, PRICE, int(r.days))
	if not r2.has("contract"):
		check(false, "the counter's terms open the contract")
		return
	var c: Dictionary = r2.contract
	_day(w)                                              # the first day: some lots arrive
	var first := int(c.delivered)
	check(first > 0 and str(c.state) == "accepted", "a first day's lots arrive (%d delivered, %d paid)" % [first, int(c.paid)])
	w.player.home = ""                                   # the player has no home for the ore to be brought to (Contracts.plan: home_ok)
	var coins0 := w.total_coins()
	var stats0 := w.stats.duplicate()
	var deadline := int(c.deadline_day)
	while str(c.state) == "accepted" and w.day() <= deadline + 2:
		_day(w)
	print("     lapse case: state %s delivered %d paid %d reserved %d, deadline day %d, ended day %s" % [c.state, int(c.delivered), int(c.paid), int(c.reserved), deadline, str(c.get("ended_day", "-"))])
	check(str(c.state) == "lapsed" and int(c.ended_day) == deadline + 1, "the contract lapsed at the first dawn after its deadline (day %d)" % int(c.get("ended_day", -1)))
	check(int(c.delivered) == first and int(c.delivered) == int(c.paid) / PRICE and w.player.coins == 1000 - int(c.paid) and int(c.reserved) == 0, "what was delivered (%d) and paid (%d) stands; the unpaid coins went back (purse %d)" % [int(c.delivered), int(c.paid), w.player.coins])
	check(_leak(w, coins0, stats0) == 0, "coins conserved through the lapse")
