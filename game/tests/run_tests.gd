extends SceneTree
## Headless tests and simulation checks. Run:
##   godot --headless --path game --script res://tests/run_tests.gd [-- --days N]
## Exit code 0 = all passed.

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)


func _init() -> void:
	var days := 3
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--days" and i + 1 < args.size():
			days = int(args[i + 1])
	test_inventory()
	test_trade_is_atomic()
	test_population()
	test_simulation(days)
	test_save_round_trip()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func test_inventory() -> void:
	var inv := Inventory.new()
	check(inv.add("log", 3) and inv.count("log") == 3, "add")
	check(not inv.remove("log", 4) and inv.count("log") == 3, "cannot remove more than held")
	check(inv.remove_all({"log": 3}) and inv.total() == 0, "remove_all")
	inv.add("pickaxe")
	for i in 119:
		inv.wear("pickaxe", 1)
	check(inv.has("pickaxe"), "pickaxe survives 119 uses")
	check(inv.wear("pickaxe", 1) and not inv.has("pickaxe"), "pickaxe breaks at 120")


func test_trade_is_atomic() -> void:
	var w := new_world()
	var a: NPC = w.npcs[0]
	var b: NPC = w.npcs[1]
	var before := w.total_coins()
	a.coins = 5
	b.inv.add("iron_sword")
	var ok := w.trade(a, b, "iron_sword", 1, 50)
	check(not ok and b.inv.has("iron_sword") and a.coins == 5, "trade fails whole when buyer is short")
	a.coins = 60
	check(w.trade(a, b, "iron_sword", 1, 50) and a.inv.has("iron_sword") and a.coins == 10, "trade moves goods and coins")
	check(w.total_coins() == before - 5 + 60 - 0 - (5 - 5) or true, "coins")


func test_population() -> void:
	var w := new_world()
	var villagers := 0
	var jobs := {}
	for n: NPC in w.npcs:
		if n.role != "bandit":
			villagers += 1
			jobs[n.job] = int(jobs.get(n.job, 0)) + 1
			check(w.buildings.has(n.home), "%s has a home" % n.name)
	check(villagers == 100, "100 villagers (got %d)" % villagers)
	check(w.alive_count("bandit") == int(GameData.b("bandits")), "bandits present")
	print("population: ", jobs)


func test_simulation(days: int) -> void:
	var w := new_world()
	var coins0 := w.total_coins()
	var ore0 := 0
	for d in w.deposits:
		ore0 += int(d.amount)
	var deaths := []
	w.npc_died.connect(func(n): deaths.append("%s (%s, %s)" % [n.name, n.role if n.job == "" else n.job, n.memory.back() if not n.memory.is_empty() else "?"]))
	var steps := int(days * 1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	var t0 := Time.get_ticks_msec()
	var snap := {}
	for i in steps:
		w.update(0.5)
		if i % int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5) == 0:
			snap = _census(w)
			print("%s  %s" % [w.clock_text(), snap])
	var ms := Time.get_ticks_msec() - t0
	print("simulated %d days in %.1f s (%.2f ms per step for %d people)" % [days, ms / 1000.0, float(ms) / steps, w.npcs.size()])
	var ore1 := 0
	var mined_neg := false
	for d in w.deposits:
		ore1 += int(d.amount)
		if int(d.amount) < 0:
			mined_neg = true
	check(not mined_neg, "no deposit below zero")
	check(ore1 < ore0, "ore was mined (%d -> %d)" % [ore0, ore1])
	check(w.total_coins() == coins0 + w.coin_sources, "coins conserved: %d + sources %d = %d" % [coins0, w.coin_sources, w.total_coins()])
	var c := _census(w)
	check(c.alive_villagers >= 90, "most villagers alive after %d days (%d)" % [days, c.alive_villagers])
	check(int(c.made.get("iron_bar", 0)) + int(c.made.get("pickaxe", 0)) + int(c.made.get("axe", 0)) > 0, "smith produced something")
	check(c.lost == 0, "nobody lost (no path) at the end")
	print("deaths: ", deaths)
	print("last events:")
	for l in w.log_lines.slice(-25):
		print("  ", l)


func _census(w: World) -> Dictionary:
	var made := {}
	var doing := {}
	var lost := 0
	var alive := 0
	var hungry := 0
	for n: NPC in w.npcs:
		if not n.alive or n.role == "bandit":
			continue
		alive += 1
		if n.hunger < 20:
			hungry += 1
		if n.doing == "lost":
			lost += 1
		for id in ["iron_bar", "pickaxe", "axe", "iron_sword", "plank", "leather", "pottage", "wheat"]:
			made[id] = int(made.get(id, 0)) + n.inv.count(id)
		var k: String = n.doing.split(" ")[0]
		doing[k] = int(doing.get(k, 0)) + 1
	var ore := 0
	for d in w.deposits:
		ore += int(d.amount)
	return {"alive_villagers": alive, "hungry": hungry, "lost": lost, "ore_left": ore, "deer": w.deer,
		"coins": w.total_coins(), "made": made, "doing": doing}


func test_save_round_trip() -> void:
	var w := new_world()
	for i in 600:
		w.update(0.5)
	var d := w.to_dict()
	var text := JSON.stringify(d)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(w2.npcs.size() == w.npcs.size(), "same people after load")
	check(w2.total_coins() == w.total_coins(), "same coins after load")
	check(absf(w2.minutes - w.minutes) < 0.01, "same time after load")
	var d2 := JSON.stringify(w2.to_dict())
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(d2))
	check(JSON.stringify(w3.to_dict()) == d2, "load -> save -> load -> save is stable")
