extends SceneTree
## The first-play acceptance path, driven through the real game scene and its panels: create a
## named character with a chosen look, read the origin, check the starting kit, equip, mine,
## harvest, eat, fight and loot a bandit, talk to a villager, save and reload. Run headless:
##   godot --headless --path game --script res://tests/start_test.gd

var main
var failures := 0
var steps := []


func check(cond: bool, what: String) -> void:
	steps.append(("ok   " if cond else "FAIL ") + what)
	print(steps[-1])
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func finish_action() -> void:
	var guard := 0
	while not main.action.is_empty() and guard < 2000:
		main._player_step(0.25)
		guard += 1


func stand_by(cell: Vector2i) -> void:
	var w: World = main.world
	var c: Vector2i = w.brain.beside(cell, cell + Vector2i(0, 1))
	w.player.pos = Vector2(c) + Vector2(0.5, 0.5)
	main.player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - w.player.pos)
	main._find_target()


func _buttons(node: Node, out: Array) -> Array:
	for c in node.get_children():
		if c is Button:
			out.append(c)
		_buttons(c, out)
	return out


## What the villager in the open talk window says.
func _speech() -> String:
	var l: Label = main.ui.panel_body.find_child("Speech", true, false)
	return l.text if l else ""


func _press(text: String) -> bool:
	for b: Button in _buttons(main.ui.panel_body, []):
		if b.text.begins_with(text) and not b.disabled:
			b.pressed.emit()
			return true
	return false


## Two walkable cells about 6 apart with a solid cell on the straight line between them, and a
## path between them (the player must go around).
func _blocked_pair(w: World) -> Array:
	var m: VillageMap = w.map
	for y in range(5, m.h - 5):
		for x in range(5, m.w - 10):
			var a := Vector2i(x, y)
			var b := Vector2i(x + 6, y)
			if m.is_solid(a) or m.is_solid(b) or not m.is_solid(Vector2i(x + 3, y)):
				continue
			var path := m.find_path(a, b)
			if path.size() > 7 and path.size() < 20:
				return [a, b]
	return []


func _run() -> void:
	var ui = main.ui
	# every gamepad button the game binds is on the controls list (RB, Skills, was missing)
	var pad_prompt := {JOY_BUTTON_A: "xbox_button_a", JOY_BUTTON_B: "xbox_button_b", JOY_BUTTON_X: "xbox_button_x",
		JOY_BUTTON_Y: "xbox_button_y", JOY_BUTTON_BACK: "xbox_button_view", JOY_BUTTON_START: "xbox_button_menu",
		JOY_BUTTON_LEFT_SHOULDER: "xbox_lb", JOY_BUTTON_RIGHT_SHOULDER: "xbox_rb", JOY_BUTTON_RIGHT_STICK: "xbox_stick_r_press"}
	var listed := {}
	for row in GameUI.CONTROLS.gamepad:
		for icon in row[0]:
			listed[icon] = true
	var unlisted := []
	for action in InputMap.get_actions():
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton and not str(action).begins_with("ui_"):
				if not listed.has(pad_prompt.get(ev.button_index, "?")):
					unlisted.append("%s (button %d)" % [action, ev.button_index])
	check(unlisted.is_empty(), "every gamepad button is on the controls list %s" % [unlisted])
	# on a phone the interface keeps clear of rounded screen corners
	main.settings.phone = true
	ui.fit_safe_area()
	check(ui.root.offset_left >= GameUI.CORNER_MARGIN.x and ui.root.offset_top >= GameUI.CORNER_MARGIN.y
		and ui.root.offset_right <= -GameUI.CORNER_MARGIN.x and ui.root.offset_bottom <= -GameUI.CORNER_MARGIN.y, "on a phone, windows and buttons keep clear of the screen corners")
	main.settings.phone = false
	ui.fit_safe_area()
	# 1-3. character creation: a name, a family, a female look in a tunic
	check(ui.is_open("title"), "the title screen opens")
	_press("New game")
	check(ui.is_open("creation"), "character creation opens")
	_press("Female")
	var looks: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/appearances.json")).looks
	var tunic: Dictionary = looks.filter(func(l): return l.sex == "female" and l.outfit != "basic")[1]
	ui.show_creation({"name": "", "family": "", "sex": "female", "look": tunic.id})
	_press("Begin")
	check(ui.is_open("creation") and main.world == null, "a character needs a name")
	ui.show_creation({"name": "Ada", "family": "Thorne", "sex": "female", "look": tunic.id})
	var edits: Array = ui.panel_body.find_children("*", "LineEdit", true, false)
	check(edits.size() == 2, "name and family fields")
	# typing into the family field stays there (a phone keyboard sends key events)
	main._input(InputEventScreenTouch.new())
	edits[1].grab_focus()
	var typed := InputEventKey.new()
	typed.keycode = KEY_B
	typed.unicode = 98
	typed.pressed = true
	main._input(typed)
	check(get_root().gui_get_focus_owner() == edits[1] and main.scheme == "touch", "typing in the family name keeps focus there")
	var pad_press := InputEventJoypadButton.new()
	pad_press.button_index = JOY_BUTTON_A
	pad_press.pressed = true
	main._input(pad_press)
	check(get_root().gui_get_focus_owner() == edits[1], "switching controls does not move focus out of the field in use")
	main._input(InputEventScreenTouch.new())
	_press("Begin")
	var w: World = main.world
	var p := w.player
	check(w != null and p.name == "Ada" and p.family == "Thorne" and p.sex == "female", "created Ada Thorne (female)")
	check(p.look == tunic.id and p.sprite == tunic.sprite and main.player_sprite != null, "the chosen look is the player's sprite (%s)" % p.sprite.get_file())
	# 4-5. the origin story, then the village
	check(ui.is_open("origin") and main.paused, "the origin story is shown and the world waits")
	_press("Begin")
	check(not ui.modal() and not main.paused and main.running, "into the village")

	# the starting kit (balance.json)
	check(p.hp == 100.0 and p.max_hp == 100.0 and p.coins == 5, "100 health and 5 coins")
	for id in ["rusty_sword", "rusty_pickaxe", "bread", "rotten_apple", "plain_clothes"]:
		check(p.inv.count(id) == 1, "carries %s" % GameData.item_name(id))
	check(p.armor == "plain_clothes" and p.weapon == "" and p.tool == "", "wearing plain clothes, nothing in hand")

	# 6. moving: a tap away from the player walks there
	var start := p.pos
	var goal := start
	for dir in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var open := true
		for k in range(1, 5):
			if main.map.is_solid(Vector2i(start + dir * k)):
				open = false
		if open:
			goal = start + dir * 3.0
			break
	main.move_to = goal
	for i in 40:
		main._player_step(0.1)
	check(p.pos.distance_to(start) > 1.0, "tap-to-walk moves the player (%.1f tiles)" % p.pos.distance_to(start))

	# 7-8. the inventory, and equipping from it
	ui.show_inventory("")
	check(ui.is_open("inventory"), "the inventory opens")
	check(_press("Wield"), "a Wield button for the sword")
	check(p.weapon == "rusty_sword", "the rusty sword is in hand")
	ui.show_inventory("")
	check(_press("Use") and p.tool == "rusty_pickaxe", "the rusty pickaxe is the tool")
	ui.hide_all()

	# 9-10. mine a deposit with the rusty pickaxe
	var coins0 := w.total_coins()
	var src0: int = w.coin_sources
	var d := w.nearest_deposit(Vector2i(p.pos), ["stone", "iron_ore", "coal"])
	stand_by(Vector2i(d.x, d.y))
	check(main.target.get("kind", "") == "deposit", "standing at a deposit")
	var ore: String = d.ore
	var amount0 := int(d.amount)
	var dur0 := int(p.inv.durability.get("rusty_pickaxe", GameData.item("rusty_pickaxe").durability))
	main.interact()
	finish_action()
	check(p.inv.count(ore) >= 1 and int(d.amount) < amount0, "mined %d %s" % [p.inv.count(ore), ore])
	check(int(p.inv.durability.get("rusty_pickaxe", 0)) < dur0, "the pickaxe wears (%d -> %d)" % [dur0, int(p.inv.durability.get("rusty_pickaxe", 0))])

	# 11-12. harvest a ripe field (the farmers': theft, seen by those nearby)
	var field: Dictionary = {}
	for f in w.fields:
		if f.state != "ripe":
			w.set_field(f, "ripe")
			f.crop = int(GameData.b("field_yield"))
		field = f
		break
	var cell := Vector2i(int(field.x), int(field.y))
	p.pos = Vector2(cell) + Vector2(0.5, 1.5)
	main.player_sprite.face(Vector2(0, -1))
	main._find_target()
	var crop0 := int(field.crop)
	var made0 := float(w.stats.get("made_wheat", 0.0))
	if main.target.get("kind", "") == "field":
		main.interact()
		finish_action()
	else:
		w.player_harvest(field)
	var hand := int(GameData.b("harvest_handful"))
	check(p.inv.count("wheat") == hand and int(field.crop) == crop0 - hand, "harvested %d wheat; the field has %d left" % [p.inv.count("wheat"), int(field.crop)])
	check(float(w.stats.get("made_wheat", 0.0)) - made0 == hand, "harvested wheat is counted as made, not created")
	check(p.crimes.size() == 1 and p.crimes[0].kind == "theft", "taking a farmer's wheat is recorded as theft (%d saw it)" % (p.crimes[0].witnesses if p.crimes.size() else 0))

	# 13. eat: bread feeds, the rotten apple feeds a little and hurts
	p.hunger = 40.0
	ui.show_inventory("")
	var hp0 := p.hp
	check(w.player_eat("bread") and p.hunger == 90.0 and not p.inv.has("bread"), "ate the bread (hunger 40 -> %d)" % int(p.hunger))
	check(w.player_eat("rotten_apple") and p.hp < hp0, "the rotten apple hurts (%d -> %d health)" % [int(hp0), int(p.hp)])
	ui.hide_all()

	# 14-17. fight a bandit with the rusty sword: take damage, win, loot what it carried
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			bandit = n
			break
	var carried: Array = bandit.inv.ids()
	p.hp = 100.0
	var hp_fight := p.hp
	# touch: Attack turns attack mode on; a tap on the bandit puts the sword on it; the player walks
	# over and strikes once, and each further tap on it is another strike
	p.pos = bandit.pos + Vector2(-4.0, 0)
	main.chase = null
	main.attack_button()
	check(main.attack_mode and main.chase == null, "Attack turns attack mode on")
	var tap_on := func(who) -> void:
		main._tap(main.get_canvas_transform() * ((who.pos - Vector2(0, 0.4)) * main.T))
	tap_on.call(bandit)
	check(main.chase == bandit and main.attack_mode, "tapping the bandit marks it")
	main._sync_sprites()
	check(main.target_marker.visible, "the sword marker shows over the bandit")
	var hp_b := bandit.hp
	var fight_steps := 0
	while bandit.hp == hp_b and fight_steps < 200:
		fight_steps += 1
		main._player_step(0.1)
		w.update(0.1)
	check(bandit.hp < hp_b and p.pos.distance_to(bandit.pos) <= 1.1, "walked to the bandit and struck it once")
	var hp_one := bandit.hp
	for i in 15:
		main._player_step(0.1)
		w.update(0.1)
	check(bandit.hp == hp_one or not bandit.alive, "no more strikes without another tap")
	var taps := 0
	while bandit.alive and fight_steps < 900 and p.alive:
		fight_steps += 1
		if not main.strike_pending:
			tap_on.call(bandit)
			taps += 1
		main._player_step(0.1)
		w.update(0.1)
	var swings := fight_steps
	main._player_step(0.1)
	check(main.chase == null and main.attack_mode, "the mark is gone with the bandit; attack mode stays on (%d taps)" % taps)
	# tapping open ground walks there; the Attack button again turns the mode off
	main._tap(main.get_canvas_transform() * ((p.pos + Vector2(2, 0)) * main.T))
	check(main.chase == null and main.move_to != Vector2.INF, "in attack mode, a tap on open ground walks there")
	main.attack_button()
	check(not main.attack_mode, "Attack again turns attack mode off")
	main.move_to = Vector2.INF
	check(p.hp < hp_fight, "the bandit fought back (health %d -> %d)" % [int(hp_fight), int(p.hp)])
	check(main.blood_layer.get_child_count() >= 1, "the slain bandit leaves blood on the ground")
	check(not bandit.alive and p.alive, "killed the bandit with the rusty sword (%.1f s)" % (swings * 0.1))
	var bag := -1
	for i in w.loot.size():
		if w.loot[i].from == bandit.name:
			bag = i
	check(bag >= 0, "the bandit left what it carried")
	if bag >= 0:
		var held: Array = w.loot[bag].inv.ids()
		check(carried.all(func(id): return held.has(id)), "the bag holds the bandit's own things: %s" % ", ".join(held))
		var inv0 := p.inv.total()
		main.target = {"kind": "loot", "i": bag}
		main.interact()
		check(p.inv.total() > inv0, "looted the bag")
	check(w.total_coins() - w.coin_sources == coins0 - src0, "coins conserved through mining, the fight and the looting")

	# tap-to-walk goes around walls and trees: a goal behind an obstacle is reached
	var route := _blocked_pair(w)
	check(not route.is_empty(), "found a spot with an obstacle in the straight line")
	if not route.is_empty():
		p.pos = Vector2(route[0]) + Vector2(0.5, 0.5)
		main.chase = null
		main.attack_mode = false
		main.move_to = Vector2(route[1]) + Vector2(0.5, 0.5)
		var t := 0
		while main.move_to != Vector2.INF and t < 400:
			main._player_step(0.05)
			t += 1
		check(p.pos.distance_to(Vector2(route[1]) + Vector2(0.5, 0.5)) < 0.3, "walked around the obstacle to the tapped spot (%.1f s)" % (t * 0.05))
	# walking behind a tree: its canopy fades while the player is under it, and comes back after
	var tree := {}
	for tr in w.trees:
		if tr.state == "grown" and int(tr.get("claimed", -1)) == -1 and w.map.is_solid(Vector2i(int(tr.x), int(tr.y))):
			tree = tr
			break
	check(not tree.is_empty(), "a standing tree to walk behind")
	if not tree.is_empty():
		var trunk := Vector2i(int(tree.x), int(tree.y))
		var top := trunk + Vector2i.UP
		var above0: TileMapLayer = main.view.layer("above0")
		p.pos = Vector2(top) + Vector2(0.5, 0.6)
		main.canopy.update(p.pos, 1.0)
		check(main.canopy.is_faded(top) and main.canopy.is_faded(trunk), "the canopy over the player fades")
		check(above0.get_cell_source_id(top) == -1, "the faded canopy is drawn from its own layer")
		p.pos = Vector2(top) + Vector2(0.5, -3.0)
		main.canopy.update(p.pos, 1.0)
		check(not main.canopy.is_faded(top) and main.view.tile_value(above0, top) == int(tree.top) and main.view.tile_value(above0, trunk) == int(tree.bottom), "the canopy is whole again once the player leaves")
		# felled while faded: the canopy is gone and does not come back
		p.pos = Vector2(top) + Vector2(0.5, 0.6)
		main.canopy.update(p.pos, 1.0)
		w.fell(tree, 0)
		main.canopy.update(p.pos, 1.0)
		check(not main.canopy.is_faded(top) and above0.get_cell_source_id(top) == -1 and above0.get_cell_source_id(trunk) == -1, "a tree felled while its canopy is faded leaves no canopy")
	# the trees in Shade's sample districts (their own Tree Top layer) fade the same way
	var sample_top := Vector2i(-1, -1)
	var canopy_tops := {}
	for pair in w.map.data.tiles.canopy:
		canopy_tops[int(pair[0])] = int(pair[1])
	for y in range(30, 60):
		for x in range(1, 29):
			var c := Vector2i(x, y)
			var v: int = main.view.tile_value(main.view.layer("above2"), c)
			if canopy_tops.has(v) and main.view.tile_value(main.view.layer("above2"), c + Vector2i.DOWN) == canopy_tops[v] and not w.map.is_solid(c):
				sample_top = c
				break
		if sample_top.x >= 0:
			break
	check(sample_top.x >= 0, "a tree in sample village 1")
	if sample_top.x >= 0:
		main.canopy.update(Vector2(sample_top) + Vector2(0.5, 0.6), 1.0)
		check(main.canopy.is_faded(sample_top) and main.canopy.is_faded(sample_top + Vector2i.DOWN), "a sample village tree's canopy fades over the player")
		main.canopy.update(Vector2(sample_top) + Vector2(0.5, -4.0), 1.0)
		check(not main.canopy.is_faded(sample_top) and main.view.layer("above2").get_cell_source_id(sample_top) != -1, "and comes back")
	# a tap on a villager who is walking away: follow, catch up and talk
	var walker: NPC = null
	for i in 400:
		w.update(0.1)
		for n: NPC in w.npcs:
			if n.alive and not n.hidden and n.role == "adult" and n.anim == "walk" and n.path.size() - n.path_i > 8:
				walker = n
				break
		if walker:
			break
	if walker:
		# stand about 6 tiles from them, somewhere the player can walk from
		var spot: Vector2i = w.map.nearest_walkable(walker.cell() + Vector2i(6, 0))
		p.pos = Vector2(spot) + Vector2(0.5, 0.5)
	check(walker != null, "a villager walking somewhere")
	if walker:
		main._tap(main.get_canvas_transform() * ((walker.pos - Vector2(0, 0.4)) * main.T))
		check(main.talk_to == walker, "tapping a villager sets them as the one to talk to")
		var steps_t := 0
		while main.talk_to != null and steps_t < 600:
			main._player_step(0.05)
			w.update(0.05)
			steps_t += 1
		# caught up with them: someone still walking somewhere calls out a line and carries on;
		# someone who has stopped talks
		if main.bubbles.has(walker.id):
			check(not ui.is_open("talk") and main.bubbles[walker.id].label.text != "", "followed %s, who is busy: \"%s\" in a bubble, no talk window (%.1f s)" % [walker.name, main.bubbles[walker.id].label.text, steps_t * 0.05])
		else:
			check(ui.is_open("talk"), "followed %s and the talk opened (%.1f s)" % [walker.name, steps_t * 0.05])
		ui.hide_all()

	# a busy villager (walking somewhere or at work) calls out in a bubble; a stranger's line
	# differs from the line once they have met the player
	var busy_one: NPC = null
	for i in 400:
		for n: NPC in w.npcs:
			if n.alive and not n.hidden and n.role == "adult" and Dialogue.busy(n) and n.target == -1 and not Dialogue.met(w, n) and not Dialogue.attacked(w, n) and Dialogue.theft_seen(w, n) == "":
				busy_one = n
				break
		if busy_one:
			break
		w.update(0.1)
	check(busy_one != null, "a busy villager to speak to")
	if busy_one:
		ui.hide_all()
		var stranger_line := Dialogue.brush_off(w, busy_one)
		main.approach(busy_one)
		check(not ui.is_open("talk") and main.bubbles.has(busy_one.id), "%s is busy (%s): a bubble, and the talk window stays shut" % [busy_one.name, busy_one.doing])
		check(main.bubbles[busy_one.id].label.text == stranger_line, "a stranger gets: \"%s\"" % stranger_line)
		Dialogue.meet(w, busy_one)
		var friend_line := Dialogue.brush_off(w, busy_one)
		check(friend_line != stranger_line and Dialogue.met(w, busy_one), "once met, the brush-off is friendlier: \"%s\"" % friend_line)
		main.bubbles[busy_one.id].left = 0.0
		main._sync_bubbles()
		check(not main.bubbles.has(busy_one.id), "the bubble goes after a few seconds")
	var idle_one: NPC = null
	for n: NPC in w.npcs:
		if n.alive and not n.hidden and n.role != "bandit" and not Dialogue.busy(n):
			idle_one = n
			break
	if idle_one:
		main.approach(idle_one)
		check(ui.is_open("talk") and not main.bubbles.has(idle_one.id), "%s is not busy (%s): the conversation opens" % [idle_one.name, idle_one.doing])
		ui.hide_all()
	else:
		check(false, "a villager who is not busy")

	# 18. talk to a villager
	var v: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult":
			v = n
			break
	p.pos = v.pos + Vector2(-0.8, 0)
	main.player_sprite.face(Vector2(1, 0))
	main._find_target()
	if main.target.get("kind", "") == "npc":
		main.interact()
	else:
		ui.show_talk(v)
	check(ui.is_open("talk"), "talked to %s %s" % [v.name, v.family])
	# the talk is a conversation: what they say, in quotes, not the simulation's numbers
	var said := _speech()
	check(said.length() > 4 and not said.contains("/100") and not said.contains("Hunger") and not said.contains("coins"), "%s says: %s" % [v.name, said])
	check(Dialogue.met(w, v), "talking records that they have met the player")
	check(_press("What do you do?") and ui.is_open("talk") and _speech() != said, "asking what they do changes what they say: %s" % _speech())
	var before := _speech()
	check(_press("How are things at home?") and _speech() != before, "asking about home: %s" % _speech())
	check(_press("Any news?") and _speech() != "", "asking for news: %s" % _speech())
	check(_press("Goodbye") and not ui.is_open("talk"), "Goodbye closes the talk")
	# someone who saw the player steal says so
	p.pos = v.pos + Vector2(-0.8, 0)
	w.witness("theft", "3 wheat from %s" % w.fields[0].id, null)
	ui.show_talk(v)
	check(_speech().contains("saw you take 3 wheat"), "a witness to a theft mentions it: %s" % _speech())
	var cold := Dialogue.brush_off(w, v)
	check(cold.contains("Thief") or cold.contains("saw what you did") or cold.contains("Stay away"), "and, busy, answers coldly: \"%s\"" % cold)
	ui.hide_all()

	# the journal: the village record on book pages, opening at the latest, with page turning
	for i in 30:
		w.note("journal test entry %d" % i)
	ui.show_journal(-1)
	check(ui.is_open("journal"), "the journal opens")
	var page_text: String = " ".join(ui.panel_body.find_children("*", "Label", true, false).map(func(l): return l.text))
	check(page_text.contains("journal test entry 29") and page_text.contains("Day 1"), "it opens at the latest pages, under the day's heading")
	check(_press("Earlier") and not " ".join(ui.panel_body.find_children("*", "Label", true, false).map(func(l): return l.text)).contains("journal test entry 29"), "Earlier turns back a page")
	check(_press("Later"), "Later turns forward again")
	ui.hide_all()

	# the village log shows only the latest lines, each fading after a few seconds
	for i in 4:
		ui.log_line("event %d" % i)
	var shown: Array = ui.log_box.get_children().filter(func(c): return not c.is_queued_for_deletion())
	check(shown.size() == ui.LOG_LINES and shown[-1].text == "event 3", "only the latest %d village events are shown" % ui.LOG_LINES)

	# looking around: two fingers drag the view off the player, Recenter brings it back, one finger still walks
	ui.hide_all()
	main.move_to = Vector2.INF
	main.talk_to = null
	main._input(InputEventScreenTouch.new())
	var touch_at := func(i: int, at: Vector2, down: bool) -> void:
		var t := InputEventScreenTouch.new()
		t.index = i
		t.position = at
		t.pressed = down
		main._unhandled_input(t)
	var drag_to := func(i: int, at: Vector2) -> void:
		var dr := InputEventScreenDrag.new()
		dr.index = i
		dr.position = at
		main._unhandled_input(dr)
	main._sync_sprites()
	var zoom1: float = main.camera.zoom.x
	var mid: Vector2 = get_root().get_visible_rect().size / 2.0
	# move the fingers away from the map's middle, so the view moves towards it (not into an edge)
	var toward: Vector2 = (p.pos - Vector2(w.map.w, w.map.h) / 2.0).normalized() * 30.0
	touch_at.call(0, mid + Vector2(-60, 0), true)
	touch_at.call(1, mid + Vector2(60, 0), true)
	for k in range(1, 6):
		drag_to.call(0, mid + Vector2(-60, 0) + toward * k)
		drag_to.call(1, mid + Vector2(60, 0) + toward * k)
	touch_at.call(0, mid + Vector2(-60, 0) + toward * 5, false)
	touch_at.call(1, mid + Vector2(60, 0) + toward * 5, false)
	main._sync_sprites()
	check(main.cam_free and main.camera.position.distance_to(p.pos * main.T) > 20.0 and ui.recenter_btn.visible,
		"a two-finger drag moves the view off the player (%.0f px) and shows Recenter" % main.camera.position.distance_to(p.pos * main.T))
	check(is_equal_approx(main.camera.zoom.x, zoom1), "dragging without spreading the fingers keeps the zoom")
	check(main.move_to == Vector2.INF and main.talk_to == null, "lifting two fingers does not walk")
	for i in 3:
		main._process(0.1)
	check(main.cam_free and main.camera.position == main.cam_at, "the view stays where it was dragged while the world runs")
	ui.recenter_btn.pressed.emit()
	main._sync_sprites()
	check(not main.cam_free and main.camera.position == p.pos * main.T and not ui.recenter_btn.visible, "Recenter follows the player again and hides")
	# one finger: a tap on open ground still walks there
	var spot := Vector2.INF
	for off in [Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]:
		var c: Vector2 = p.pos + off
		if not w.map.is_solid(Vector2i(c)) and main._creature_at(c) == null:
			spot = c
			break
	var spot_screen: Vector2 = main.get_canvas_transform() * (spot * main.T)
	touch_at.call(0, spot_screen, true)
	touch_at.call(0, spot_screen, false)
	check(main.move_to != Vector2.INF and main.move_to.distance_to(spot) < 0.1, "a single tap still sets a walk target")
	main.move_to = Vector2.INF
	# the village map: the Map button opens and closes it
	var map_btn: Button = null
	for b in ui.touch_bar.get_children():
		if b.text == "Map":
			map_btn = b
	check(map_btn != null and ui.touch_bar.visible, "a Map button on the touch bar")
	map_btn.pressed.emit()
	check(ui.is_open("map") and main.paused, "the Map button opens the village map (the world waits)")
	var mv: VillageMapPanel = ui.panel_body.get_child(0)
	await process_frame
	var img := VillageMapPanel.image_for(w.map, w)
	check(img.get_width() == w.map.w and img.get_height() == w.map.h, "the map image is the village's size (%dx%d)" % [img.get_width(), img.get_height()])
	var tavern: Dictionary = w.buildings["b2"]
	check(img.get_pixel(int(tavern.x) + 3, int(tavern.y) + 3).is_equal_approx(VillageMapPanel.ROOF), "buildings are drawn on the map")
	var r: Rect2 = mv.map_rect()
	check(r.size.y > 200.0 and r.end.y <= mv.size.y and r.end.x <= mv.size.x + 0.5, "the map fits the window (%.0fx%.0f)" % [r.size.x, r.size.y])
	check(r.has_point(mv.player_point()) and mv.player_point().distance_to(r.position + p.pos * r.size.x / w.map.w) < 0.5, "the player is marked on the map")
	check(mv.places().any(func(pl): return pl[0] == "The Well House"), "the named buildings are labelled")
	map_btn.pressed.emit()
	check(not ui.modal() and not main.paused, "the Map button closes it again")
	var m_key := InputEventKey.new()
	m_key.physical_keycode = KEY_M
	m_key.pressed = true
	main._unhandled_input(m_key)
	check(ui.is_open("map"), "M opens the map")
	main._unhandled_input(m_key)
	check(not ui.modal(), "M closes it")
	# a tap on the map looks there
	ui.toggle_map()
	mv = ui.panel_body.get_child(0)
	await process_frame
	var tap_map := InputEventScreenTouch.new()
	tap_map.pressed = true
	tap_map.position = mv.map_rect().get_center()
	mv._gui_input(tap_map)
	check(not ui.modal() and main.cam_free and ui.recenter_btn.visible, "a tap on the map closes it and looks there")
	var c_key := InputEventKey.new()
	c_key.physical_keycode = KEY_C
	c_key.pressed = true
	main._unhandled_input(c_key)
	check(not main.cam_free, "C recenters")

	# the controls follow the input in use
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	main._input(pad)
	check(main.scheme == "gamepad" and not ui.touch_bar.visible and ui.prompt_icon.texture.resource_path.ends_with("xbox_button_a.png"), "a gamepad press switches to gamepad controls (no touch buttons)")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	main._input(touch)
	check(main.scheme == "touch" and ui.touch_bar.visible, "a touch switches back to touch controls")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	main._input(key)
	check(main.scheme == "kbm" and not ui.touch_bar.visible, "a key press switches to keyboard and mouse")
	# settings: changed, saved, read back; the interface size relayouts and keeps the map's size
	var zoom0: float = main.camera.zoom.x / main.view_scale
	ui.show_settings(ui.hide_all)
	check(ui.is_open("settings"), "the settings screen opens")
	main.settings.ui_size = "large"
	main.settings.music = 0.3
	main.apply_settings()
	check(is_equal_approx(main.camera.zoom.x / main.view_scale, zoom0) and get_root().content_scale_size.y == int(main.settings.layout_height()), "a larger interface keeps the map the same size")
	var again := GameSettings.new()
	again.load_file()
	check(again.ui_size == "large" and is_equal_approx(again.music, 0.3), "settings are saved")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.3), "the music bus follows the setting")
	main.settings.ui_size = "normal"
	main.settings.music = 0.8
	main.apply_settings()
	ui.hide_all()

	# quests through the screens: the sage's diamond, a side quest accepted, handed in, and the story
	var sage: NPC = w.npc(w.sage_id)
	p.pos = sage.pos + Vector2(0, 2)
	main.camera.position = p.pos * main.T
	main.camera.reset_smoothing()
	main.camera.force_update_scroll()
	main._sync_diamonds()
	check(main.diamonds.has(sage.id) and main.diamonds[sage.id].texture.resource_path.ends_with("story.png"), "the story pennant floats over the sage")
	var cook_q: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "cook":
			cook_q = n
			break
	w.quests.offers[cook_q.id] = "wood_for_the_hearth"
	check(w.quests.marker(cook_q) == "wood", "a cook asking for firewood shows the log marker")
	# a quest giver gone indoors keeps a marker, over their house door
	var home_q: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and w.buildings.has(n.home) and n != cook_q and n != sage:
			home_q = n
			break
	w.quests.offers[home_q.id] = "food_for_the_family"
	home_q.hidden = true
	var door_cell := w.building_door(home_q.home)
	p.pos = Vector2(door_cell) + Vector2(0.5, 2.5)
	main.camera.position = p.pos * main.T
	main.camera.reset_smoothing()
	main.camera.force_update_scroll()
	main._sync_diamonds()
	check(main.diamonds.has(home_q.id) and absf(main.diamonds[home_q.id].position.x - (door_cell.x + 0.5) * main.T) < 1.0, "a quest giver at home shows the marker over the house door")
	var roof_z := 0
	for l in main.view.above_layers:
		roof_z = maxi(roof_z, l.z_index)
	check(main.diamonds[home_q.id].z_index > roof_z and main.target_marker.z_index > roof_z, "quest and target markers draw over roofs and tree canopies")
	home_q.hidden = false
	w.quests.offers.erase(home_q.id)
	p.pos = sage.pos + Vector2(0, 2)
	ui.show_talk(cook_q)
	check(_press("Need any help?") and _speech().contains("5 log"), "asking for work hears the request")
	check(_press("I'll do it") and w.player.quests.any(func(q): return q.id == "wood_for_the_hearth"), "accepting takes the quest")
	ui.show_journal(-1, true)
	var qtext: String = " ".join(ui.panel_body.find_children("*", "Label", true, false).map(func(l): return l.text))
	check(qtext.contains("Wood for the hearth") and qtext.contains("The sage in the north"), "the journal's quest page lists both quests")
	ui.hide_all()
	p.inv.add("log", 5)
	cook_q.coins = 30
	var purse0 := p.coins
	ui.show_talk(cook_q)
	check(_press("Here you are") and p.coins == purse0 + 10 and not p.inv.has("log"), "handing in the logs pays the reward")
	ui.hide_all()
	p.coins += 60
	ui.show_talk(sage)
	check(_speech().contains("Fifty coins"), "the sage speaks of the story quest")
	check(_press("Learn Fireball") and p.spells.get("fireball", false) and not w.player.quests.any(func(q): return q.id == "the_sage_in_the_north"), "learning Fireball from the sage completes the story quest")
	check(_speech().contains("Fire does not forgive"), "the sage gives his parting words")
	ui.hide_all()
	main._sync_diamonds()
	check(not main.diamonds.has(sage.id), "the sage's pennant is gone")

	# 19-20. save, reload, and the state is the same
	var snap := {"name": p.name, "look": p.look, "sprite": p.sprite, "coins": p.coins, "hp": int(p.hp),
		"weapon": p.weapon, "tool": p.tool, "armor": p.armor, "wheat": p.inv.count("wheat"), "crimes": p.crimes.size(),
		"minutes": int(w.minutes), "pos": Vector2i(p.pos)}
	main.save_game(false)
	main.continue_game()
	var q: PlayerState = main.world.player
	var now := {"name": q.name, "look": q.look, "sprite": q.sprite, "coins": q.coins, "hp": int(q.hp),
		"weapon": q.weapon, "tool": q.tool, "armor": q.armor, "wheat": q.inv.count("wheat"), "crimes": q.crimes.size(),
		"minutes": int(main.world.minutes), "pos": Vector2i(q.pos)}
	check(main.world != w, "a fresh world was loaded from the save")
	check(now == snap, "the save restores the player: %s" % (str(now) + " vs " + str(snap) if now != snap else "name, look, coins, health, equipment, wheat, crimes, time, place"))

	# camera dead zone: small steps inside the middle box leave the view still; walking on pushes it
	var pz: PlayerState = main.world.player
	pz.pos = Vector2(main.map.w, main.map.h) / 2.0
	main.recenter()
	var still: Vector2 = main._follow(pz.pos * main.T)
	pz.pos += Vector2(1.5, 1.0)
	check(main._follow(pz.pos * main.T) == still, "a step inside the dead zone does not move the camera")
	var box: Vector2 = main.get_viewport().get_visible_rect().size / main.camera.zoom * main.DEAD_ZONE / 2.0
	pz.pos += Vector2(30.0, 0.0)
	var pushed: Vector2 = main._follow(pz.pos * main.T)
	check(pushed.x > still.x and absf(pz.pos.x * main.T - pushed.x - box.x) < 0.01, "walking past its edge pushes the camera along, the player at the box's edge")
	main.recenter()
	check(main.follow_at.distance_to(pz.pos * main.T) < 0.01, "Recenter centres the view on the player")

	# 21. a villager who has met the player never forgets it, however much else happens to them
	var w2: World = main.world
	var acquaintance: NPC = w2.npcs.filter(func(n): return n.alive and n.role == "adult")[0]
	Dialogue.meet(w2, acquaintance)
	for i in 20:
		acquaintance.remember("busy day %d" % i)
	check(Dialogue.met(w2, acquaintance) and acquaintance.memory.size() == 8, "a villager stays acquainted with the player after many other memories")
	# 22. killing a villager's livestock: the keeper remembers the animal, not an attack on them
	var beast: Animal = null
	for a: Animal in w2.fauna.animals:
		if a.alive and not a.wild() and int(w2.fauna.pens[a.area].owner) != -1:
			beast = a
			break
	var keeper: NPC = w2.npc(int(w2.fauna.pens[beast.area].owner))
	var kind := beast.label().to_lower()
	main._hit_animal(beast, 9999.0)
	check(not Dialogue.attacked(w2, keeper) and Dialogue.animal_killed(w2, keeper) == kind, "the keeper remembers that the player killed their %s" % kind)
	check(Dialogue.opening(w2, keeper).contains(kind), "and says so: \"%s\"" % Dialogue.opening(w2, keeper))

	print("%d steps, %d failures" % [steps.size(), failures])
	quit(1 if failures else 0)
