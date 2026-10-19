extends SceneTree
## PL1-04 (healing goods and the sage's apothecary), PL1-09 (the employer's star), PL1-13 (stove) and
## PL2-010 (sawhorse). Pure World (no scene). Run headless:
##   godot --headless --path game --script res://tests/health_jobs_test.gd

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
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_items()
	test_use()
	test_apothecary()
	test_star()
	test_stations()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_items() -> void:
	var want := {"linen_bandage": [15, 3], "herbal_poultice": [30, 6], "healing_tonic": [50, 12], "strong_healing_tonic": [80, 22]}
	for id in want:
		var it: Dictionary = GameData.item(id)
		check(it.type == "medicine" and int(it.heal) == want[id][0] and int(it.value) == want[id][1] and not it.has("food"), "%s heals %d for %d coins and is not food" % [id, want[id][0], want[id][1]])
		check(FileAccess.file_exists("res://assets/icons/%s.png" % id), "%s has an imported icon" % id)
	check(GameData.recipes_at("stove").has("brew_poultice") and GameData.recipes_at("stove").has("brew_healing_tonic") and GameData.recipes_at("stove").has("brew_strong_tonic") and GameData.recipes_at("stove").has("brew_tonic"), "the stove makes the poultice and the tonics, and keeps the herbal tonic")
	var w := new_world()
	check(w.player.inv.count("linen_bandage") == 2, "the starting kit holds two bandages")


func test_use() -> void:
	var w := new_world()
	var p := w.player
	p.inv.add("herbal_poultice", 2)
	p.hp = p.hp_cap()
	check(not w.player_use_medicine("herbal_poultice") and p.inv.count("herbal_poultice") == 2, "at full health a poultice is not used up")
	p.hp = 40.0
	p.hunger = 33.0
	check(w.player_use_medicine("herbal_poultice") and p.hp == 70.0 and p.inv.count("herbal_poultice") == 1 and p.hunger == 33.0, "a poultice heals 30 and feeds nobody")
	p.hp = p.hp_cap() - 5.0
	check(w.player_use_medicine("herbal_poultice") and p.hp == p.hp_cap(), "healing never passes the cap")
	check(not w.player_use_medicine("herbal_poultice") and not w.player_use_medicine("bread"), "an empty slot or a loaf is not a medicine")
	p.hp = 10.0
	check(not w.player_use_medicine("strong_healing_tonic") and p.hp == 10.0, "a tonic the player does not hold does nothing")


func test_apothecary() -> void:
	var w := new_world()
	var sage := w.npc(w.sage_id)
	check(sage != null and sage.inv.count("linen_bandage") > 0 and w.brain.for_sale(sage).has("healing_tonic"), "the sage has real stock for sale")
	check(not w.brain.for_sale(sage).has("flower") and w.brain.wants(sage, "flower") > 0, "the sage buys flowers but does not sell them back")
	# the stock is the sage's: buying moves a piece and the coins between real inventories
	var p := w.player
	p.coins = 100
	var price := w.sell_price(sage, "linen_bandage")
	var n0 := sage.inv.count("linen_bandage")
	var coins0 := sage.coins
	check(w.trade(p, sage, "linen_bandage", 1, price) and sage.inv.count("linen_bandage") == n0 - 1 and sage.coins == coins0 + price and p.inv.count("linen_bandage") == 3, "buying a bandage moves it and the coins")
	# stock is finite: sell out and it is gone until brewed or brought by the caravan
	sage.inv.remove("strong_healing_tonic", sage.inv.count("strong_healing_tonic"))
	check(not sage.inv.has("strong_healing_tonic"), "a sold-out tonic is gone")
	# the sage brews flowers into a poultice at the stove
	sage.inv.add("flower", 2)
	sage.inv.remove("herbal_poultice", sage.inv.count("herbal_poultice"))
	check(w.brain.act(sage, "craft", {"recipe": "brew_poultice", "station": w.stations_of("stove")[0]}) or true, "the craft action runs")
	check(sage.inv.count("herbal_poultice") == 1 and not sage.inv.has("flower"), "two flowers became a poultice in the sage's hands")
	# the caravan resupplies from the sage's own coins, and stops when they are spent
	sage.coins = 100
	var village0 := w.total_coins()
	var src0 := w.coin_sources
	var spent: int = w.brain._caravan_apothecary()
	var cap := int(GameData.b("caravan_apothecary_per_visit"))
	check(spent > 0 and sage.coins == 100 - spent and w.coin_sources == src0 - spent, "the caravan sold the sage %d coins' worth, paid by the sage; coins left the village" % spent)
	check(w.total_coins() == village0 - spent, "the village's coins fell by exactly what the sage paid")
	check(sage.inv.count("strong_healing_tonic") + sage.inv.count("healing_tonic") + sage.inv.count("herbal_poultice") + sage.inv.count("linen_bandage") <= 40, "restock is bounded")
	sage.coins = int(GameData.b("trader_cash_floor"))
	var before := sage.inv.total()
	check(w.brain._caravan_apothecary() == 0 and sage.inv.total() == before, "a sage with no spare coins gets nothing (not infinite) (cap %d a visit)" % cap)


func test_star() -> void:
	var w := new_world()
	var p := w.player
	var smith: NPC = null
	var other: NPC = null
	for n: NPC in w.npcs:
		if n.job == "smith" and smith == null:
			smith = n
		elif n.job == "cook" and other == null:
			other = n
	smith.inv.remove("iron_ore", smith.inv.count("iron_ore"))
	smith.coins = 200
	w.quests.offers[smith.id] = "ore_for_the_forge"
	check(not w.quests.employer(smith), "an offer alone puts no star over the employer")
	var q: Dictionary = w.quests.accept(smith)
	check(not q.is_empty() and w.quests.employer(smith) and not w.quests.employer(other), "accepting the job stars that employer only")
	smith.pos += Vector2(7, 3)
	w.update(1.0)
	check(w.quests.employer(smith), "the star stays while the employer walks about and while the iron is still to gather")
	# keyed by id: it survives a save and a load
	var d = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.quests.employer(w2.npc(smith.id)), "the star is restored after save and load")
	# deliver and be paid
	var need: Dictionary = Quests.template("ore_for_the_forge").need
	for id in need:
		p.inv.add(id, int(need[id]))
	var coins0 := p.coins
	check(w.quests.ready(q), "the player now holds the goods")
	var paid: int = w.quests.complete(q)
	check(paid > 0 and p.coins == coins0 + paid and not w.quests.employer(smith), "delivery and payment clear the star (paid %d)" % paid)
	# two jobs from one employer: the star stays until both are settled
	p.quests.append({"id": "ore_for_the_forge", "giver": smith.id, "day": 1, "target": -1})
	p.quests.append({"id": "ore_for_the_forge", "giver": smith.id, "day": 1, "target": -1})
	check(w.quests.employer(smith), "two open jobs keep the star")
	p.quests.pop_back()
	check(w.quests.employer(smith), "one open job still keeps the star")
	p.quests.pop_back()
	check(not w.quests.employer(smith), "no open job, no star")


func test_stations() -> void:
	var m := VillageMap.load_default()
	var stove := {}
	var saw := {}
	for s in m.data.stations:
		if s.type == "stove":
			stove = s
		if s.type == "sawhorse":
			saw = s
	for st in [stove, saw]:
		var at: Array = st.at
		var use: Array = st.use
		check(m.data.solid[int(at[1])][int(at[0])] == "1" and m.data.solid[int(use[1])][int(use[0])] == "0", "the %s's cell blocks and its use cell is open" % st.type)
	var w := new_world()
	check(w.station_use(stove.id) is Vector2i and w.stations_of("sawhorse").size() == 1, "the stove and the sawhorse still resolve as stations")
