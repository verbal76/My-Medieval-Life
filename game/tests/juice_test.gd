extends SceneTree
## JUICE J1/J2 (owner Decision 9, 2026-11-01; docs/juice/PRELIMINARY_ASSESSMENT.md), in the real game scene: the effects
## helper (view/effects.gd) is bounded, culled and calmed by Reduce effects; effects follow real events (a seam mined, a
## health fall, a building finished, a seam worked out, a villager's blow at the anvil); none draws on World.rng; the corner
## log's two lanes (the player's own above the village's) never grow past LOG_LINES and keep each lane's newest line; the
## purse counts to its new value; the settings are saved.
##   godot --headless --path game --script res://tests/juice_test.gd

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/juice_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_helper_tests()
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var fx: GameEffects = main.fx
	check(fx != null and fx.get_parent() == main, "the game has one effects helper")
	main._fx_step()
	# ---- no World.rng draw: every presentation trigger, with the world's generator compared before and after
	var rng0: int = w.rng.state
	var p := w.player
	fx.burst("stone", p.pos * main.T)
	main._player_fx("sparks")
	main._player_fx("earth", Vector2i(p.pos))
	main._fx_tile_changed(Vector2i(p.pos), "below", int(main.map.data.tiles.depleted_rock))
	main._fx_building_added({"x": int(p.pos.x) - 2, "y": int(p.pos.y) - 3, "w": 5, "h": 4})
	main.ui.gain("+1 Iron ore", "iron_ore")
	main.ui.village("A test note")
	main.ui.personal("Mining is now level 2!", "", "skill", 4.0)
	p.coins += 25
	main.ui.update_hud()
	main._sync_sprites()
	for i in 20:
		fx.step(0.05)
	check(w.rng.state == rng0, "no effect, line, flinch or coin count draws on World.rng (state %d -> %d)" % [rng0, w.rng.state])
	check(fx.live() <= GameEffects.CAP, "the pool stays bounded in play (%d live)" % fx.live())
	_lane_tests()
	_coin_tests()
	await _flinch_tests()
	_event_tests()
	_settings_tests()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## The helper alone: bounded, culled, Reduce effects, its particles gone after their life, unknown kinds ignored.
func _helper_tests() -> void:
	var fx := GameEffects.new()
	root.add_child(fx)
	var n := 0
	for i in 100:
		n += fx.burst("sparks", Vector2(10, 10))
	check(fx.live() == GameEffects.CAP and n == GameEffects.CAP, "a hundred bursts never hold more than the cap (%d)" % fx.live())
	check(fx.get_child_count() == GameEffects.CAP, "the sprites are pooled: as many nodes as the cap, no more")
	for i in 40:
		fx.step(0.05)
	check(fx.live() == 0, "every particle is gone within two seconds")
	n = 0
	for i in 5:
		n += fx.burst("stone", Vector2(10, 10))
	check(fx.get_child_count() == GameEffects.CAP, "spent sprites are reused, not added")
	fx.clear()
	fx.focus = Vector2.ZERO
	check(fx.burst("dust", Vector2(GameEffects.CULL_TILES * 16.0 + 40.0, 0)) == 0, "a burst beyond the culling distance draws nothing")
	check(fx.burst("dust", Vector2(20, 0)) > 0, "one within it draws")
	check(fx.burst("no_such_kind", Vector2.ZERO) == 0, "an unknown kind draws nothing")
	fx.clear()
	fx.reduce = true
	check(fx.burst("stone", Vector2.ZERO) == 1, "Reduce effects: a burst is one puff")
	var s: Sprite2D = fx.get_child(0)
	var at := s.position
	fx.step(0.2)
	check(s.position == at, "Reduce effects: the puff does not fly")
	var lbl := Label.new()
	root.add_child(lbl)
	fx.flash(lbl)
	check(lbl.modulate == Color.WHITE, "Reduce effects: no flash")
	fx.reduce = false
	fx.flash(lbl)
	check(lbl.modulate != Color.WHITE, "without it, a flash")
	lbl.queue_free()
	# the swing's stroke frame comes round once a cycle (ActorSprite.take_impact)
	var a := ActorSprite.new()
	root.add_child(a)
	a.setup("res://assets/characters/" + _any_sheet())
	a.play("swing")
	var hits := 0
	for i in 60:
		a._process(1.0 / 60.0)
		if a.take_impact():
			hits += 1
	check(hits >= 1 and hits <= 3, "a swing's blow lands once a cycle (%d in a second)" % hits)
	a.queue_free()
	fx.queue_free()


func _any_sheet() -> String:
	var d := DirAccess.open("res://assets/characters")
	for f in d.get_files():
		if f.ends_with(".png"):
			return f
	return ""


## The corner log's lanes: the player's own above the village's, never more than LOG_LINES, each keeping its newest line.
func _lane_tests() -> void:
	var ui: GameUI = main.ui
	for c in ui.log_box.get_children():
		c.free()
	for i in 4:
		ui.village("village event %d" % i)
	ui.gain("+1 Iron ore", "iron_ore")
	var kids: Array = ui.log_box.get_children()
	check(kids.size() == ui.LOG_LINES, "the box keeps its size: %d lines" % kids.size())
	check(ui.log_texts(GameUI.LANE_PERSONAL) == ["+1 Iron ore"] and ui.log_texts(GameUI.LANE_VILLAGE) == ["village event 3"],
		"a gain is not lost behind village news: the newest of each (%s)" % str(ui.log_texts()))
	check(str(kids[0].get_meta("lane")) == GameUI.LANE_PERSONAL, "the player's own lane is above the village's")
	for i in 5:
		ui.gain("+%d red berries" % i, "red_berries")
	check(ui.log_box.get_child_count() == ui.LOG_LINES and ui.log_texts(GameUI.LANE_VILLAGE) == ["village event 3"],
		"nor is the village news pushed out by a run of gains")
	for c in ui.log_box.get_children():
		c.free()
	ui.village("only village 1")
	ui.village("only village 2")
	check(ui.log_texts(GameUI.LANE_VILLAGE).size() == 2, "a lane alone may use both lines")
	# a skill level is the player's own: the personal lane, and kept on the journal's Messages page
	var before: int = main.world.player_messages().size()
	main._level_up("mining", 3)
	check(ui.log_texts(GameUI.LANE_PERSONAL).any(func(t): return str(t).begins_with("Mining is now level 3")),
		"a skill level shows in the personal lane")
	check(main.world.player_messages().size() == before + 1, "and is kept in the journal (category skill)")
	# World.note reaches the village lane (the API for village announcements)
	main.world.note("The village has a milestone")
	check(ui.log_texts(GameUI.LANE_VILLAGE).any(func(t): return str(t).contains("The village has a milestone")),
		"World.note goes to the village lane")
	var long_text := "A very long personal announcement that would be wider than the corner log if it were not wrapped at all, then more words"
	ui.personal(long_text)
	var r: Rect2 = ui.log_box.get_child(0).get_global_rect() if ui.log_box.get_child_count() > 0 else Rect2()
	check(ui.log_box.get_combined_minimum_size().x <= 440.0, "a long personal line wraps within the box's width (%.0f)" % ui.log_box.get_combined_minimum_size().x)


## The purse counts to its new value, says by how much, and shows a new world's purse at once.
func _coin_tests() -> void:
	var ui: GameUI = main.ui
	var p: PlayerState = main.world.player
	main.settings.reduce_effects = false
	ui.update_hud()
	var c0: int = p.coins
	p.coins = c0 + 40
	ui._coins_step(p.coins, 0.0)
	check(ui.coin_delta != null and ui.coin_delta.visible and ui.coin_delta.text == "+40", "a gain shows +40 beside the purse")
	ui._coins_step(p.coins, 0.1)
	var mid := int(ui.coins_label.text)
	check(mid > c0 and mid < c0 + 40, "the number counts up (%d between %d and %d)" % [mid, c0, c0 + 40])
	ui._coins_step(p.coins, 1.0)
	check(int(ui.coins_label.text) == c0 + 40, "and settles on the purse")
	p.coins = c0
	ui._coins_step(p.coins, 0.0)
	check(ui.coin_delta.text == "-40", "a payment shows -40")
	main.settings.reduce_effects = true
	p.coins = c0 + 7
	ui._coins_step(p.coins, 0.0)
	check(int(ui.coins_label.text) == c0 + 7, "Reduce effects: the number changes at once")
	main.settings.reduce_effects = false
	ui._coins_step(p.coins, 2.0)
	check(ui.coin_delta.get_global_rect().intersects(ui.log_box.get_global_rect()) == false, "the amount never sits over the corner log")


## The flinch: the hurt frames when health actually fell, not for a slow loss; the work goes on after it.
func _flinch_tests() -> void:
	var w: World = main.world
	var p := w.player
	main._sync_sprites()
	var hp0 := p.hp
	p.hp = hp0 - 5.0
	main._sync_sprites()
	check(main.player_sprite.anim == "hurt", "the player flinches when a blow takes health")
	main.player_sprite.play("swing")
	check(main.player_sprite.anim == "hurt", "the flinch plays through before other work")
	for i in 30:
		main.player_sprite._process(1.0 / 60.0)
	check(main.player_sprite.anim == "swing", "then the work it broke into goes on")
	main.player_sprite.play("idle")
	p.hp -= 0.2
	main._sync_sprites()
	check(main.player_sprite.anim != "hurt", "a slow loss (starving) does not flinch")
	p.hp = hp0
	main._sync_sprites()
	# a villager beside the player, in view (the camera settled on the player first)
	main.camera.reset_smoothing()
	await process_frame
	await process_frame
	for n: NPC in w.npcs:
		if not n.alive or n.anim == "sleep" or w.place_of(n.pos) != "":
			continue
		var pos0 := n.pos
		n.pos = p.pos + Vector2(1, 0)
		main._sync_sprites()
		var s: ActorSprite = main.sprites.get(n.id)
		if s == null or not s.visible:
			n.pos = pos0
			continue
		n.hp -= 3.0
		main._sync_sprites()
		check(s.anim == "hurt", "a villager in view flinches when struck (%s)" % n.name)
		n.hp += 3.0
		n.pos = pos0
		main._sync_sprites()
		return
	var cam: Vector2 = main.camera.get_screen_center_position() / main.T
	check(false, "a villager in view to strike (player %s, camera %s)" % [str(p.pos), str(cam)])


## Effects from real events: a seam mined by the player, a villager's blow at the anvil, a building finished, a seam worked out.
func _event_tests() -> void:
	var w: World = main.world
	var fx: GameEffects = main.fx
	var p := w.player
	p.inv.add("pickaxe")
	p.hunger = 100.0
	for d in w.deposits:
		if int(d.get("level", 0)) == 0 and int(d.get("amount", 0)) >= 4:
			var cell := Vector2i(int(d.x), int(d.y))
			var c: Vector2i = w.brain.beside(cell, cell + Vector2i(0, 1))
			p.pos = Vector2(c) + Vector2(0.5, 0.5)
			main.player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - p.pos)
			main._find_target()
			main._fx_step()
			fx.focus = p.pos * main.T            # the camera follows the player (its smoothing lags a moment behind)
			var b0 := fx.bursts
			var a0 := int(d.amount)
			main.interact()
			var steps := 0
			while not main.action.is_empty() and steps < 400:
				main._player_step(0.25)
				steps += 1
			check(int(d.amount) == a0 - 1 and fx.bursts > b0, "a seam mined: one unit taken, and its chips and dust drawn")
			break
	# a villager at work at the anvil: their blow throws sparks
	var anvil := ""
	for id in w.stations:
		if str(w.stations[id].type) == "anvil":
			anvil = str(id)
			break
	var n: NPC = w.npcs[0]
	var plan0: Array = n.plan
	n.plan = [{"k": "work", "act": "craft", "args": {"station": anvil}}]
	var sp: ActorSprite = main.sprites.get(n.id)
	var pos0 := n.pos
	n.pos = p.pos + Vector2(1, 0)
	fx.clear()
	var b1 := fx.bursts
	main._work_fx(n, sp)
	check(anvil != "" and fx.bursts > b1, "a villager's blow at the anvil throws sparks")
	n.plan = [{"k": "work", "act": "hunt", "args": {}}]
	var b2 := fx.bursts
	main._work_fx(n, sp)
	check(fx.bursts == b2, "a hunter's swing throws nothing")
	n.plan = plan0
	n.pos = pos0
	var b3 := fx.bursts
	main._fx_building_added({"x": int(p.pos.x), "y": int(p.pos.y), "w": 6, "h": 5})
	check(fx.bursts > b3, "a building finished: dust along its front")
	var b4 := fx.bursts
	main._fx_tile_changed(Vector2i(p.pos), "below", -1)
	check(fx.bursts == b4, "a tile cleared is not a seam worked out: nothing")
	main._fx_tile_changed(Vector2i(p.pos), "below", int(main.map.data.tiles.depleted_rock))
	check(fx.bursts > b4, "a seam worked out: a grey puff")
	# Reduce effects reaches the helper and the trees
	main.settings.reduce_effects = true
	main._fx_step()
	check(fx.reduce and main.tree_view.reduce, "Reduce effects reaches the effects and the trees' chips")
	main.settings.reduce_effects = false
	main._fx_step()


func _settings_tests() -> void:
	var ui: GameUI = main.ui
	ui.show_settings(func(): pass, "interface")
	var words: String = " ".join(ui.panel_body.find_children("*", "Label", true, false).map(func(l): return l.text))
	check(words.contains("Reduce effects") and words.contains("No blinking"), "Settings, Interface: Reduce effects and No blinking")
	ui.hide_all()
	main.settings.reduce_effects = true
	main.settings.no_blink = true
	main.settings.save_file()
	var again := GameSettings.new()
	again.load_file()
	check(again.reduce_effects and again.no_blink, "both are saved")
	main.settings.reduce_effects = false
	main.settings.no_blink = false
	main.settings.save_file()
