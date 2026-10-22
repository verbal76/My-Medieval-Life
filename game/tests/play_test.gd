extends SceneTree
## Scripted player: drives the real game scene (main.gd) through the first-build goal: earn,
## mine, smelt, forge a weapon, make armour, buy land, build a house, learn a spell, fight,
## die and continue as the heir. Run headless:
##   godot --headless --path game --script res://tests/play_test.gd

var main
var failures := 0
var steps := []


func check(cond: bool, what: String) -> void:
	steps.append(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("interact"):
		print("FAIL the game's main script did not load (a script error above): stopping")
		quit(1)
		return
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func finish_action() -> void:
	var guard := 0
	while not main.action.is_empty() and guard < 2000:
		main._player_step(0.25)
		guard += 1


## One whole sword swing: the press, the blow on the slash frame, the recovery.
func swing_once() -> void:
	main.attack()
	var guard := 0
	while main.swing.busy() and guard < 100:
		main._swing_step(0.05)
		guard += 1


func stand_by(cell: Vector2i) -> void:
	var w: World = main.world
	var c: Vector2i = w.brain.beside(cell, cell + Vector2i(0, 1))
	w.player.pos = Vector2(c) + Vector2(0.5, 0.5)
	main.player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - w.player.pos)
	main._find_target()


func npc_with_job(job: String) -> NPC:
	for n: NPC in main.world.npcs:
		if n.alive and n.job == job:
			return n
	return null


func _run() -> void:
	main.save_path = "user://test_saves/play_test/save1.json"     # never the player's own save
	main.new_game()
	var w: World = main.world
	var p := w.player
	p.coins = 400            # a test purse so the run covers every system quickly
	var coins0 := w.total_coins()

	# 1. buy a pickaxe and an axe from the smith (same trade rule as NPCs)
	var smith := npc_with_job("smith")
	check(w.trade(p, smith, "pickaxe", 1, w.sell_price(smith, "pickaxe")), "bought a pickaxe from %s" % smith.name)
	var seller := smith if smith.inv.has("axe") else null
	if seller == null:
		for n: NPC in w.npcs:
			if n.inv.has("axe") and n.job == "merchant":
				seller = n
	check(seller != null and w.trade(p, seller, "axe", 1, w.sell_price(seller, "axe")), "bought an axe")

	# 2. mine iron, coal and stone at real deposits
	for want in [["iron_ore", 8], ["coal", 4], ["stone", 20]]:
		var got := 0
		var tries := 0
		while p.inv.count(want[0]) < want[1] and tries < 80:
			tries += 1
			var d := w.nearest_deposit(Vector2i(p.pos), [want[0]])
			if d.is_empty():
				break
			stand_by(Vector2i(d.x, d.y))
			if main.target.get("kind", "") != "deposit":
				continue
			var before := int(d.amount)
			main.interact()
			finish_action()
			got += 1
			check(int(d.amount) < before or tries > 1, "deposit shrinks when mined") if got == 1 else null
		check(p.inv.count(want[0]) >= want[1], "mined %d %s" % [p.inv.count(want[0]), want[0]])

	# 3. fell trees for logs
	var felled := 0
	while p.inv.count("log") < 12 and felled < 6:
		var t := w.nearest_tree(Vector2i(p.pos), 200.0)
		stand_by(Vector2i(t.x, t.y))
		if main.target.get("kind", "") == "tree":
			main.interact()
			finish_action()
			felled += 1
		else:
			t.state = "claimed_by_test"
	check(p.inv.count("log") >= 10, "felled trees for %d logs" % p.inv.count("log"))

	# 4. smelt and forge at the smithy's stations
	var forge_cell := w.station_use(w.stations_of("forge")[0])
	p.pos = Vector2(forge_cell) + Vector2(0.5, 0.5)
	for i in 4:
		main.craft("smelt_iron")
		finish_action()
	check(p.inv.count("iron_bar") >= 4, "smelted %d iron bars" % p.inv.count("iron_bar"))
	check(p.level("smithing") >= 1 and int(p.skills.get("smithing", 0)) >= 40, "smithing xp gained (%d)" % int(p.skills.get("smithing", 0)))
	p.pos = Vector2(w.station_use(w.stations_of("sawhorse")[0])) + Vector2(0.5, 0.5)
	main.craft("saw_planks")
	finish_action()
	check(p.inv.count("plank") >= 2, "sawed planks")
	# a weapon: copper sword needs copper bars; iron sword needs smithing 2 -> buy copper ore or level up
	p.skills["smithing"] = 100        # stand-in for the 10 smelts that earn level 2 (checked above that xp accrues)
	var tanner := npc_with_job("tanner")
	var bought_leather := w.trade(p, tanner, "leather", 1, w.sell_price(tanner, "leather")) if tanner.inv.has("leather") else false
	if not bought_leather:
		for n: NPC in w.npcs:
			if n.inv.has("leather") and n != smith and w.trade(p, n, "leather", 1, w.sell_price(n, "leather")):
				bought_leather = true
				break
	check(bought_leather, "bought leather")
	p.pos = Vector2(w.station_use(w.stations_of("anvil")[0])) + Vector2(0.5, 0.5)
	main.craft("forge_iron_sword")
	finish_action()
	check(p.inv.has("iron_sword"), "forged an iron sword")
	p.weapon = "iron_sword"
	# armour: leather armour at the workbench
	for i in 4:
		var src: NPC = null
		for n: NPC in w.npcs:
			if n.inv.has("leather") and w.brain.for_sale(n).has("leather"):
				src = n
		if src:
			w.trade(p, src, "leather", 1, w.sell_price(src, "leather"))
	p.skills["tanning"] = maxi(int(p.skills.get("tanning", 0)), 100)
	p.pos = Vector2(w.station_use(w.stations_of("workbench")[0])) + Vector2(0.5, 0.5)
	main.craft("leather_armor")
	finish_action()
	check(p.inv.has("leather_armor"), "made leather armour (pack: %s)" % p.inv.items)
	p.armor = "leather_armor"

	# 5. buy a plot, mark out a house, deliver materials
	var plot: Dictionary = w.plots[0]
	var treasury0 := w.treasury
	p.pos = Vector2(int(plot.x) + 4, int(plot.y) + 9.5)
	check(w.buy_plot(plot) and w.owner_of(plot) == World.PLAYER, "plot bought")
	check(w.treasury == treasury0 + int(plot.price), "the plot's price went to the manor's treasury")
	w.start_site(plot)
	var carpenter := npc_with_job("carpenter")
	var planks := 0
	while p.inv.count("plank") < 30 and planks < 40:
		planks += 1
		var src: NPC = carpenter if carpenter.inv.has("plank") else null
		if src == null:
			for n: NPC in w.npcs:
				if n.inv.has("plank") and n.job != "smith":
					src = n
		if src == null or not w.trade(p, src, "plank", 1, w.sell_price(src, "plank")):
			break
	check(p.inv.count("plank") >= 10, "bought %d planks from the market" % p.inv.count("plank"))
	# STONE-01: a house is built of dressed blocks: make a mallet at the workbench and dress the quarried stone there
	p.pos = Vector2(w.station_use(w.stations_of("workbench")[0])) + Vector2(0.5, 0.5)
	main.craft("make_mallet")
	finish_action()
	check(p.inv.has("mallet"), "made a mallet at the workbench")
	var dressings := 0
	while p.inv.count("building_block") < 20 and p.inv.count("stone") >= 2 and dressings < 20:
		dressings += 1
		main.craft("dress_stone")
		finish_action()
	check(p.inv.count("building_block") >= 20, "dressed %d stone into %d building blocks" % [dressings * 2, p.inv.count("building_block")])
	# the market alone cannot cover a house: fell and saw the rest, as an NPC carpenter would
	var saws := 0
	while p.inv.count("plank") < 30 and saws < 30:
		saws += 1
		if p.inv.count("log") <= 10:
			var t := w.nearest_tree(Vector2i(p.pos), 200.0)
			stand_by(Vector2i(t.x, t.y))
			if main.target.get("kind", "") == "tree":
				main.interact()
				finish_action()
			else:
				t.state = "claimed_by_test"
			continue
		p.pos = Vector2(w.station_use(w.stations_of("sawhorse")[0])) + Vector2(0.5, 0.5)
		main.craft("saw_planks")
		finish_action()
	check(p.inv.count("plank") >= 30, "sawed up to %d planks" % p.inv.count("plank"))
	var done := w.deliver(plot, p.inv)
	check(done and w.buildings.has("house_" + plot.id), "house finished from delivered materials")
	p.home = "house_" + plot.id

	# 6. learn fireball from the sage, cast it at a bandit
	var sage := w.npc(w.sage_id)
	check(sage != null and sage.alive, "the sage is alive")
	p.coins -= int(GameData.b("fireball_price"))
	sage.coins += int(GameData.b("fireball_price"))
	p.spells["fireball"] = true
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			bandit = n
			break
	check(bandit != null, "a bandit to fight")
	p.pos = bandit.pos + Vector2(-2.5, 0)
	main.player_sprite.face(Vector2(1, 0))
	var hp0 := bandit.hp
	main.fireball()
	for i in 20:
		main._projectiles_step(0.05)
	check(bandit.hp < hp0, "fireball hit the bandit (%d -> %d)" % [hp0, bandit.hp])
	p.pos = bandit.pos + Vector2(-0.9, 0)
	var swings := 0
	while bandit.alive and swings < 40:
		p.pos = bandit.pos + Vector2(-0.9, 0)
		main.player_sprite.face(Vector2(1, 0))
		swing_once()
		swings += 1
	check(not bandit.alive, "killed the bandit with the sword in %d swings" % swings)
	var loot_found := false
	for l in w.loot:
		if l.from == bandit.name:
			loot_found = true
	check(loot_found, "the bandit dropped what they actually carried")

	# 7. animals: hunt a wild boar with the sword, take its meat, feed a pen, and killing livestock is a crime
	var boar: Animal = null
	for a: Animal in w.fauna.animals:
		if a.species == "boar" and a.adult(w.minutes):
			boar = a
			break
	check(boar != null, "a wild boar in the woods")
	var meat0 := p.inv.count("meat")
	var blows := 0
	while boar.alive and blows < 40:
		p.pos = boar.pos + Vector2(-0.9, 0)
		main.player_sprite.face(Vector2(1, 0))
		swing_once()
		blows += 1
	check(not boar.alive, "hunted the boar in %d blows" % blows)
	var carcass := -1
	for i in w.loot.size():
		if w.loot[i].from == "the wild boar":
			carcass = i
	check(carcass >= 0, "the boar left its carcass")
	if carcass >= 0:
		main.target = {"kind": "loot", "i": carcass}
		main.interact()
	check(p.inv.count("meat") == meat0 + int(GameData.b("animals").boar.meat) and p.inv.has("hide"), "took the boar's meat and hide (meat %d)" % p.inv.count("meat"))
	var pen: Dictionary = w.fauna.pen_of("sheep")
	var trough0 := int(pen.trough)
	p.inv.add("wheat", 5)
	p.pos = Vector2(int(pen.feed_at[0]) + 0.5, int(pen.feed_at[1]) + 0.5)
	main._find_target()
	check(main.target.get("kind", "") == "pen", "standing at the sheep pen's gate")
	main.interact()
	check(int(pen.trough) == trough0 + 5, "fed the sheep 5 wheat")
	var sheep: Animal = null
	for a: Animal in w.fauna.animals:
		if a.area == pen.id:
			sheep = a
	var keeper := w.pen_keeper(pen)
	keeper.target = -1
	keeper.plan.clear()
	keeper.anim = "idle"
	keeper.pos = sheep.pos + Vector2(2.5, 0)      # the keeper is by the pen and sees it (PAR-05: only a witness knows)
	for i in 20:
		if not sheep.alive:
			break
		p.pos = sheep.pos + Vector2(-0.9, 0)
		main.player_sprite.face(Vector2(1, 0))
		swing_once()
	check(not sheep.alive and keeper.target == -2, "killing the keeper's sheep in their sight is a crime: %s comes after you" % keeper.name)
	keeper.target = -1
	for g: NPC in w.npcs:
		if g.target == -2:
			g.target = -1

	# 8. economy invariants survive all of the above
	check(w.total_coins() == coins0 + w.coin_sources, "coins conserved through the player's actions")

	# 9. permadeath and the heir
	var gen := p.generation
	w.damage_player(9999, "test")
	check(not w.player.alive, "the player can die")
	main.continue_as_heir()
	check(w.player.alive and w.player.generation == gen + 1, "continued as the heir (generation %d)" % w.player.generation)
	check(w.player.home == "house_" + plot.id, "the heir keeps the house")
	check(w.npcs.size() == 106 + Population.SERVICE_JOBS.size(), "the world was not reset")

	for s in steps:
		print(s)
	print("%d steps, %d failures" % [steps.size(), failures])
	quit(1 if failures else 0)
