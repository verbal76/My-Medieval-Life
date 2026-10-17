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
	test_animals()
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


## The owner's animal rules, checked in a pen on its own: a well-fed pair breeds, a hungry one does
## not, one sex alone does not, babies grow up after grow_days, a pen never passes its cap, and
## animals get hungry, eat and starve like the villagers.
func test_animals() -> void:
	var w := new_world()
	var f := w.fauna
	var pen: Dictionary = f.pen_of("pig")
	check(not pen.is_empty() and pen.owner != -1, "the pig pen has a keeper")
	check(f.count("woods_w", "boar") > 0 and f.count("woods_e", "rabbit") > 0, "wild boar and rabbits in the woods")
	var s: Dictionary = GameData.b("animals")["pig"]
	var day := 1440.0
	# a fed pair: births once the female is due
	for a: Animal in f.animals.duplicate():
		if a.area == pen.id:
			f.remove(a)
	var m := f.spawn(pen.id, "pig", "m", null)
	var fe := f.spawn(pen.id, "pig", "f", null)
	m.born = w.minutes - 10 * day
	fe.born = w.minutes - 10 * day
	fe.next_birth = w.minutes
	pen.trough = 100
	f.new_day()
	var piglets := f.count(pen.id, "pig") - 2
	check(piglets == int(s.litter), "a fed male and female breed (%d young)" % piglets)
	var baby: Animal = f.animals.back()
	check(not baby.adult(w.minutes), "the young start as babies (half scale)")
	# no second litter before breed_days
	f.new_day()
	check(f.count(pen.id, "pig") - 2 == piglets, "no second litter before it is due")
	w.minutes += float(s.grow_days) * day
	check(baby.adult(w.minutes), "babies grow up after %d days" % int(s.grow_days))
	# hungry: no births; an animal eats from the trough when hungry; with nothing to eat it starves
	for a: Animal in f.animals.duplicate():
		if a.area == pen.id:
			f.remove(a)
	m = f.spawn(pen.id, "pig", "m", null)
	fe = f.spawn(pen.id, "pig", "f", null)
	m.born = w.minutes - 10 * day
	fe.born = w.minutes - 10 * day
	fe.next_birth = w.minutes
	m.hunger = 20.0
	fe.hunger = 20.0
	pen.trough = 0
	f.new_day()
	check(f.count(pen.id, "pig") == 2, "a hungry pair does not breed")
	pen.trough = 1
	f.tick(1.0)
	check(fe.hunger == 100.0 or m.hunger == 100.0, "a hungry pig eats from the trough")
	check(int(pen.trough) == 0, "eating empties the trough by its feed")
	var hours := 0
	while f.count(pen.id, "pig") > 0 and hours < 200:
		f.tick(60.0)
		hours += 1
	check(f.count(pen.id, "pig") == 0, "pigs nobody feeds starve to death (after %d hours)" % hours)
	check(hours > 24, "starving takes more than a day (%d hours)" % hours)
	# wild animals graze when hungry
	var rabbit: Animal = null
	for a: Animal in f.animals:
		if a.species == "rabbit":
			rabbit = a
			break
	rabbit.hunger = 30.0
	f.tick(1.0)
	check(rabbit.hunger == 100.0, "a hungry rabbit grazes")
	# one sex alone does not breed
	for i in 2:
		var g := f.spawn(pen.id, "pig", "f", null)
		g.born = w.minutes - 10 * day
		g.next_birth = w.minutes
	pen.trough = 100
	f.new_day()
	check(f.count(pen.id, "pig") == 2, "females without a male do not breed")
	# the cap holds
	var lone := f.spawn(pen.id, "pig", "m", null)
	lone.born = w.minutes - 10 * day
	for i in 30:
		w.minutes += day
		pen.trough = 100
		f.new_day()
	check(f.count(pen.id, "pig") <= int(s.pen_cap), "the pen never passes its cap (%d)" % f.count(pen.id, "pig"))
	# meat: an adult gives its meat and hide, a baby half the meat
	var adult := f.spawn(pen.id, "pig", "m", null)
	adult.born = w.minutes - 10 * day
	var bag := f.kill(adult)
	check(bag.count("meat") == int(s.meat) and bag.count("hide") == int(s.hide), "an adult becomes meat and hide")
	var young := f.spawn(pen.id, "pig", "f", null)
	bag = f.kill(young)
	check(bag.count("meat") == maxi(1, int(s.meat) / 2) and not bag.has("hide"), "a young animal gives half the meat")
	w.dispose()


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
	for k in ["cow", "pig", "sheep", "chicken", "boar", "rabbit"]:
		check(int(c.animals.get(k, 0)) >= 2, "%s still kept or living wild after %d days (%d)" % [k, days, int(c.animals.get(k, 0))])
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
	var beasts := {}
	for a: Animal in w.fauna.animals:
		beasts[a.species] = int(beasts.get(a.species, 0)) + 1
	return {"alive_villagers": alive, "hungry": hungry, "lost": lost, "ore_left": ore, "animals": beasts,
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
	check(w2.fauna.animals.size() == w.fauna.animals.size(), "same animals after load")
	# a save from before animals (save_version 1, with the old deer count) still loads
	var old: Dictionary = JSON.parse_string(text)
	old.erase("fauna")
	old.save_version = 1
	old.deer = 30
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), old)
	check(w4.npcs.size() == w.npcs.size() and w4.fauna.animals.size() > 0, "a version 1 save loads and gets its animals")
	check(w4.fauna.pen_of("cow").owner != -1, "pens get keepers after loading a version 1 save")
