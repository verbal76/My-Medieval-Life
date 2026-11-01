extends SceneTree
## LE-05 construction hiring (design s.9 "Construction: bid for materials, hire"; OD-LE-03 D02 broader part behind
## market.negotiated_wages): a building household's helper agrees its day's wage when hired (EconMarket.wage_bargain, the manor's
## rule) only with the Living Economy on and that flag; with the economy on the wage moves through the transaction authority
## (World.transactions.transfer_coins, "wage"), each payer's part validated against its claims; economy off: exactly as before.
## Run headless:  godot --headless --path game --script res://tests/le05_construction_hire_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(on: bool, negotiated := false) -> World:
	if on:
		var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		c.enabled = true
		c.market.negotiated_wages = negotiated
		EconomyFoundation.set_override(c)
	else:
		EconomyFoundation.set_override({})
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_off()
	test_on_posted()
	test_on_negotiated()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func ledger(w: World) -> int:
	return w.total_coins() - w.coin_sources


## A household of two or more living adults (the employer) and a worker of another household.
func cast(w: World) -> Array:
	var hh := -1
	for h in w.households.size():
		if w.brain._members(h).filter(func(o: NPC) -> bool: return o.role == "adult").size() >= 2:
			hh = h
			break
	var worker: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.household != hh)[0]
	return [hh, worker]


func wage_ops(w: World) -> int:
	return w.transactions.journal.filter(func(e): return str(e.op) == "coins:wage").size()


func test_off() -> void:
	var w := new_world(false)
	var cs: Array = cast(w)
	var ref := World.hh_ref(int(cs[0]))
	var n: NPC = cs[1]
	var base := int(GameData.b("helper_wage"))
	check(w.construction.helper_wage_for(ref, n) == base, "economy off: a household's helper is paid the posted wage (%d)" % base)
	var c0 := ledger(w)
	var e0 := n.earned
	check(w.construction._pay(ref, n, base) and n.earned == e0 + base and ledger(w) == c0 and wage_ops(w) == 0,
		"economy off: the wage moves as before (no authority journal line); coins conserved")


func test_on_posted() -> void:
	var w := new_world(true, false)
	var cs: Array = cast(w)
	var ref := World.hh_ref(int(cs[0]))
	var n: NPC = cs[1]
	var base := int(GameData.b("helper_wage"))
	check(w.construction.helper_wage_for(ref, n) == base, "economy on, negotiated_wages off (shipped): the posted wage")
	# the household's members pay richest first; force a split across two payers
	var payers: Array = w.property._payers(ref)
	for o: NPC in payers:
		o.coins = 0
	payers[0].coins = base - 1
	payers[1].coins = 5
	var c0 := ledger(w)
	var e0 := n.earned
	var s0: int = payers[0].spent + payers[1].spent
	check(w.construction._pay(ref, n, base) and n.earned == e0 + base and ledger(w) == c0, "economy on: the wage is paid in full; coins conserved")
	check(wage_ops(w) == 2 and payers[0].coins == 0 and payers[1].coins == 4 and payers[0].spent + payers[1].spent == s0 + base,
		"through the authority: one 'wage' transfer per payer (richest first), booked as spending and earnings")
	payers[1].coins = 1
	var c1 := ledger(w)
	check(not w.construction._pay(ref, n, base) and payers[1].coins == 1 and ledger(w) == c1 and wage_ops(w) == 2, "short of the wage: nothing moves")
	var tp: int = w.player.coins
	w.player.coins = 50
	check(w.construction.helper_wage_for(World.PLAYER, n) == base and w.construction._pay(World.PLAYER, n, base) and w.player.coins == 50 - base and wage_ops(w) == 3,
		"the player's hire: the posted wage, through the authority")
	w.player.coins = tp


func test_on_negotiated() -> void:
	var w := new_world(true, true)
	var cs: Array = cast(w)
	var ref := World.hh_ref(int(cs[0]))
	var n: NPC = cs[1]
	var base := int(GameData.b("helper_wage"))
	var top := roundi(float(base) * float(w.economy.market.p("wage_max_factor", 1.25)))
	var wg := w.construction.helper_wage_for(ref, n)
	check(wg == w.economy.market.wage_bargain(base, World.npc_ref(n.id)) and wg >= base and wg <= top,
		"negotiated_wages on: a household's helper agrees its wage when hired (%d, between %d and %d), the manor's rule" % [wg, base, top])
	n.coins = 0
	var poor := w.construction.helper_wage_for(ref, n)
	n.coins = 10000
	var rich := w.construction.helper_wage_for(ref, n)
	check(poor <= rich, "a comfortable worker asks more than one in need of coin (%d vs %d)" % [poor, rich])
	check(w.construction.helper_wage_for(World.PLAYER, n) == base, "the player's hire stays at the posted wage the window states")
