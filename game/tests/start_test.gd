extends SceneTree
## The first-play acceptance path, driven through the real game scene and its panels: create a
## named character with a chosen look, read the origin, check the starting kit, equip, mine,
## harvest, eat, fight and loot a bandit, talk to a villager, save and reload. Run headless:
##   godot --headless --path game --script res://tests/start_test.gd

var main
var failures := 0
var steps := []


const TEST_SAVE := "user://test_saves/start_test/save1.json"


func check(cond: bool, what: String) -> void:
	steps.append(("ok   " if cond else "FAIL ") + what)
	print(steps[-1])
	if not cond:
		failures += 1


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("interact"):
		print("FAIL the game's main script did not load (a script error above): stopping")
		quit(1)
		return
	main.save_path = TEST_SAVE        # never the player's own save
	_clear_saves()
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
		JOY_BUTTON_LEFT_SHOULDER: "xbox_lb", JOY_BUTTON_RIGHT_SHOULDER: "xbox_rb", JOY_BUTTON_RIGHT_STICK: "xbox_stick_r_press", JOY_BUTTON_DPAD_DOWN: "xbox_dpad_down",
		JOY_BUTTON_DPAD_LEFT: "xbox_dpad_left", JOY_BUTTON_DPAD_RIGHT: "xbox_dpad_right", JOY_BUTTON_DPAD_UP: "xbox_dpad_up",
		JOY_BUTTON_LEFT_STICK: "xbox_stick_l_press"}
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
	for action in ["journal", "build"]:                  # FR-04: the Journal and Build menus have pad buttons
		check(InputMap.action_get_events(action).any(func(ev): return ev is InputEventJoypadButton), "the %s has a gamepad button" % action)
	# on a phone the interface keeps clear of rounded screen corners
	main.settings.phone = true
	ui.fit_safe_area()
	check(ui.root.offset_left >= GameUI.CORNER_MARGIN.x and ui.root.offset_top >= GameUI.CORNER_MARGIN.y
		and ui.root.offset_right <= -GameUI.CORNER_MARGIN.x and ui.root.offset_bottom <= -GameUI.CORNER_MARGIN.y, "on a phone, windows and buttons keep clear of the screen corners")
	# B7-010: the status box sits a small margin from the top-left corner of the usable screen, the
	# action bar from the bottom-right; a camera hud_hole moves only what it would overlap
	await process_frame
	var hm: float = GameUI.HUD_MARGIN.phone
	var hud_sb: Rect2 = ui.status_box.get_global_rect()
	var hud_view: Vector2 = main.get_viewport().get_visible_rect().size
	check(absf(hud_sb.position.x - hm) < 1.0 and absf(hud_sb.position.y - hm) < 1.0, "the status box is anchored %d units from the top-left corner (%s)" % [hm, hud_sb.position])
	var hud_tb: Rect2 = ui.touch_bar.get_global_rect()
	check(absf(hud_view.x - hud_tb.end.x - hm) < 1.0 and absf(hud_view.y - hud_tb.end.y - hm) < 1.0, "the action bar is anchored %d units from the bottom-right corner" % hm)
	var winp := Vector2(DisplayServer.window_get_size())
	if winp.x <= 0 or winp.y <= 0 or DisplayServer.get_name() == "headless":
		winp = hud_view
	var kk := hud_view / winp
	var hud_hole := Rect2(0, 20.0 / kk.y, 60.0 / kk.x, 60.0 / kk.y)          # a camera hud_hole near the top-left (window pixels)
	ui.test_safe = Rect2(hud_hole.end.x, 0, winp.x - hud_hole.end.x, winp.y)
	ui.test_cutouts = [hud_hole]
	ui.fit_safe_area()
	await process_frame
	hud_sb = ui.status_box.get_global_rect()
	var hud_hole_ui := Rect2(hud_hole.position * kk, hud_hole.size * kk)
	check(not hud_sb.intersects(hud_hole_ui) and hud_sb.position.x < hud_hole_ui.end.x + 2.0 * hm + 1.0 and absf(hud_sb.position.y - hm) < 1.0,
		"with a camera hud_hole there, the status box steps just past it, not a whole band inward (%s, hud_hole %s)" % [hud_sb.position, hud_hole_ui])
	check(ui.root.offset_left >= hud_hole_ui.end.x, "windows still keep clear of the cutout's band")
	ui.test_safe = Rect2()
	ui.test_cutouts = []
	ui.fit_safe_area()
	main.settings.phone = false
	ui.fit_safe_area()
	# 1-3. character creation: a name, a family, a female look in a tunic
	check(ui.is_open("title"), "the title screen opens")
	ui.set_scheme("kbm")
	ui.show_title(main.can_continue())
	for i in 4:
		await process_frame
	check(ui.body_scroll.scroll_vertical == 0, "the title opens at its top, its buttons in view (FR-05; was scrolled into the controls list)")
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
	check(_texts(ui.panel_body).contains("%d coins" % int(GameData.b("start_coins_player"))) and not _texts(ui.panel_body).contains("five coins"), "the origin story names the real starting coins")
	_press("Begin")
	check(not ui.modal() and not main.paused and main.running, "into the village")
	check(ui.toast.visible and ui.toast.text.contains("Any work for me?") and ui.toast.text.contains("reeve") and ui.toast.text.contains("journal"),
			"the opening message says where paid work is, and that the journal says who buys what: %s" % ui.toast.text)

	# the starting kit (balance.json)
	check(p.hp == 100.0 and p.max_hp == 100.0 and p.coins == 20, "100 health and 20 coins (owner, provisional)")
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

	# 7-8. the pack window (Cozy Farm's panel): the bag grid, tabs, and equipping from it
	ui.show_inventory()
	check(ui.is_open("inventory"), "the inventory opens")
	var pack_win: InventoryWindow = ui.inventory_window()
	check(pack_win != null and pack_win.cells.size() == 27 and pack_win.tab_buttons.size() == 8 and pack_win.gear_buttons.size() == 6, "a 9 x 3 bag grid, 8 tabs and 6 gear slots")
	check(p.inv.max_stacks == 24 and pack_win.cells.slice(0, 24).all(func(b): return not b.disabled) \
		and pack_win.cells.slice(24).all(func(b): return b.disabled and b.focus_mode == Control.FOCUS_NONE), "24 cells can be used; the last 3 are locked")
	check(not _press("Wield") and not _press("Drop"), "no actions until a slot is chosen")
	pack_win.cells[pack_win.shown.find("rusty_sword")].pressed.emit()
	check(pack_win.selected == "rusty_sword", "tapping a cell chooses its item")
	check(_press("Wield"), "a Wield button for the sword")
	check(p.weapon == "rusty_sword", "the rusty sword is in hand")
	pack_win.choose("rusty_pickaxe")
	check(_press("Use") and p.tool == "rusty_pickaxe", "the rusty pickaxe is the tool")
	var tab_shows := {"food": ["bread", "linen_bandage", "rotten_apple"], "materials": [], "tools": ["rusty_pickaxe"], "weapons": ["rusty_sword"],
		"armour": ["plain_clothes"], "all": ["bread", "linen_bandage", "plain_clothes", "rotten_apple", "rusty_pickaxe", "rusty_sword"]}
	for t in tab_shows:
		pack_win.tab_buttons[pack_win.TABS.map(func(x): return x[0]).find(t)].pressed.emit()
		check(pack_win.tab == t and pack_win.items_shown() == tab_shows[t], "the %s tab shows %s" % [t, pack_win.items_shown()])
	pack_win.tab_buttons[6].pressed.emit()
	check(ui.is_open("skills"), "the Skills tab opens the skills window")
	ui.show_inventory()
	ui.inventory_window().tab_buttons[7].pressed.emit()
	check(ui.is_open("journal"), "the Journal tab opens the journal")
	# the new gear: a cap on the head, an amulet and a ring, from the Armour tab
	for id in ["leather_cap", "copper_ring", "amulet"]:
		p.inv.add(id)
	ui.show_inventory("armour")
	pack_win = ui.inventory_window()
	check(pack_win.tab == "armour" and pack_win.items_shown() == ["amulet", "copper_ring", "leather_cap", "plain_clothes"], "the Armour tab shows worn gear and jewellery")
	var def0 := p.defense()
	var stam0 := p.stamina_cap()
	var hpcap0 := p.hp_cap()
	pack_win.choose("leather_cap")
	check(_press("Wear") and p.head == "leather_cap" and p.defense() == def0 + 1.0, "the leather cap is worn and adds 1 armour")
	pack_win.choose("copper_ring")
	check(_press("Wear") and p.ring == "copper_ring" and p.stamina_cap() == stam0 + 5.0, "the copper ring is worn: +5 max stamina")
	pack_win.choose("amulet")
	check(_press("Wear") and p.amulet == "amulet" and p.hp_cap() == hpcap0 + 5.0, "the amulet is worn: +5 max health")
	pack_win.gear_buttons["ring"].pressed.emit()
	check(pack_win.selected == "gear:ring" and _press("Take off") and p.ring == "" and p.stamina_cap() == stam0, "the ring slot's Take off removes it")
	check(not _press("Take off"), "an empty slot has nothing to take off")
	# with the pad (Build 8 report, Xbox controller on Windows): choosing a cell moves focus to its
	# first action, A then wears it, and up or left goes back to the cell
	var scheme0: String = ui.scheme
	ui.set_scheme("gamepad")
	ui.show_inventory("armour")
	pack_win = ui.inventory_window()
	if p.armor != "":
		main.world.player_unequip("armor")
		pack_win.refresh()
	var clothes_cell: Button = pack_win.cells[pack_win.items_shown().find("plain_clothes")]
	clothes_cell.grab_focus()
	clothes_cell.pressed.emit()                       # A on the focused cell
	var pad_focus: Control = main.get_viewport().gui_get_focus_owner()
	check(pad_focus is Button and (pad_focus as Button).text == "Wear", "after choosing with the pad, focus is on Wear (%s)" % (pad_focus.text if pad_focus is Button else str(pad_focus)))
	check(pad_focus is Button and pad_focus.get_node(pad_focus.focus_neighbor_top) == clothes_cell and pad_focus.get_node(pad_focus.focus_neighbor_left) == clothes_cell, "up and left from Wear go back to the item")
	if pad_focus is Button:
		(pad_focus as Button).pressed.emit()          # A again
	check(p.armor == "plain_clothes", "A on Wear puts the clothes on")
	check(main.get_viewport().gui_get_focus_owner() == pack_win.cells[pack_win.items_shown().find("plain_clothes")], "and focus returns to the item")
	ui.set_scheme(scheme0)
	ui.hide_all()
	pack_win.choose("copper_ring")
	_press("Wear")
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
	for off in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, 4), Vector2(0, -4), Vector2(-3, 3), Vector2(3, 3)]:
		var clear := true                           # 4 tiles off with open ground all the way (the camp's spot depends on the seed)
		var side: Vector2 = off.normalized().orthogonal() * 0.45
		for k in range(0, 17):
			for sd in [-side, Vector2.ZERO, side]:
				var c: Vector2 = bandit.pos + off * (float(k) / 16.0) + sd
				if main.map.is_solid_world(Vector2i(floori(c.x), floori(c.y))):
					clear = false
		if clear:
			p.pos = bandit.pos + off
			break
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
	var open_at := p.pos + Vector2(2, 0)
	for off in [Vector2(2, 0), Vector2(-2, 0), Vector2(0, 2), Vector2(0, -2), Vector2(3, 3)]:
		if main._creature_at(p.pos + off) == null:        # open ground: nobody (another bandit) there
			open_at = p.pos + off
			break
	main._tap(main.get_canvas_transform() * (open_at * main.T))
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
		var tn: TreeView.TreeNode = main.tree_view.node_at(trunk)
		check(tn != null and tn.texture != null and tn.drawn == "grown", "a mature tree is drawn as a sprite")
		check(main.view.tile_value(main.view.layer("above0"), trunk + Vector2i.UP) != int(tree.top) or int(tree.top) < 0, "its old tile canopy is gone")
		p.pos = Vector2(trunk) + Vector2(0.5, -0.8)
		main.tree_view.update(p.pos, 1.0)
		check(tn.modulate.a < 0.5, "the canopy over the player fades")
		p.pos = Vector2(trunk) + Vector2(0.5, 3.5)
		main.tree_view.update(p.pos, 1.0)
		check(tn.modulate.a >= 0.99, "the canopy is whole again once the player leaves")
		# felled while faded: the stump is drawn whole and nothing of the canopy stays
		p.pos = Vector2(trunk) + Vector2(0.5, -0.8)
		main.tree_view.update(p.pos, 1.0)
		w.fell(tree, 0)
		main.tree_view.update(p.pos, 1.0)
		check(tn.drawn == "stump" and tn.modulate.a >= 0.99, "a tree felled while its canopy is faded leaves a whole stump")
	# generator v6: the village draws no tree as tiles (Shade's sample districts are gone), so there is no tile canopy to fade
	var canopy_tops := {}
	for pair in w.map.data.tiles.canopy:
		canopy_tops[int(pair[0])] = true
		canopy_tops[int(pair[1])] = true
	var tile_crowns := 0
	for lay in main.view.layers.values():
		for ccell in (lay as TileMapLayer).get_used_cells():
			if canopy_tops.has(main.view.tile_value(lay, ccell)):
				tile_crowns += 1
	check(tile_crowns == 0 and w.map.decor_trees().is_empty(), "no tile canopy is left in the village's layers (%d)" % tile_crowns)
	# a tap on a villager who is walking away: follow, catch up and talk
	var walker: NPC = null
	for i in 400:
		w.update(0.1)
		for n: NPC in w.npcs:
			if n.alive and not main._covered(n) and not w.asleep(n) and n.role == "adult" and n.anim == "walk" and n.path.size() - n.path_i > 8:
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
			if n.alive and not main._covered(n) and not w.asleep(n) and n.role == "adult" and Dialogue.busy(n) and n.target == -1 and not Dialogue.met(w, n) and not Dialogue.attacked(w, n) and Dialogue.theft_seen(w, n) == "":
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
		if n.alive and not main._covered(n) and not w.asleep(n) and n.role != "bandit" and not Dialogue.busy(n) and not w.at_post(n):
			idle_one = n            # (a shopkeeper at their post opens the shop instead: tested with the shops)
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

	# shops: a tavern tk at the counter serves; using the counter opens the shop
	var tk := w.tavern_keeper()
	tk.pos = w.shop_post(tk)
	tk.plan = [w.brain.work(600, "", {}, "idle")]
	tk.target = -1
	var counter: Dictionary = w.stations[w.stations_of("tavern_counter")[0]]
	p.pos = tk.pos + Vector2(0, 1.0)
	main.player_sprite.face(Vector2(0, -1))
	main._find_target()
	check(main.target.get("kind", "") == "shop" and main.target.label == "Trade with %s (tavern)" % tk.name, "facing the keeper at the counter: \"%s\"" % main.target.get("label", ""))
	main.interact()
	check(ui.is_open("trade") and ui.title_label.text.to_lower().begins_with(("Trade with %s" % tk.name).to_lower()), "using it opens %s's shop: %s" % [tk.name, ui.title_label.text])
	var coins_before := p.coins
	p.coins += 20
	var opened := _press("Buy")
	var picker: QuantityPicker = ui.panel_body.get_node_or_null("QuantityPicker")
	if picker != null:
		picker.confirm()
	check(opened and picker != null and p.coins < coins_before + 20, "bought something from the tavern (%d coins left)" % p.coins)
	check(_press("Talk to %s" % tk.name) and ui.is_open("talk"), "the shop has a Talk button")
	ui.hide_all()
	main.approach(tk)
	check(ui.is_open("trade") and not main.bubbles.has(tk.id), "approached at the counter, the keeper serves at once (no brush-off)")
	ui.hide_all()
	check(main._usable_at(Vector2(int(counter.use[0]) + 0.5, int(counter.use[1]) + 0.5)) != Vector2.INF, "a tap on the counter is a use of it")
	# a stall with its merchant away: its goods can be taken, and the prompt says it is theft
	var sid: String = w.stalls.keys()[0]
	var merchant: NPC = w.party(w.tenant_of(w.stalls[sid]))
	merchant.pos = Vector2(int(w.stalls[sid].use[0]) + 0.5, int(w.stalls[sid].use[1]) + 6.5)
	for o: NPC in w.npcs:                    # nobody else at the stall either: it is left alone
		if o != merchant and o.pos.distance_to(Vector2(int(w.stalls[sid].x), int(w.stalls[sid].y))) < 4.0:
			o.pos = merchant.pos + Vector2(1.0, 0.0)
	stand_by(Vector2i(int(w.stalls[sid].x), int(w.stalls[sid].y)))
	check(str(main.target.get("label", "")).ends_with("(%s %s's) — theft" % [merchant.name, merchant.family]) or str(main.target.get("label", "")).begins_with("Empty"), "a stall left alone: \"%s\"" % main.target.get("label", ""))
	merchant.pos = w.shop_post(merchant)
	merchant.plan = [w.brain.work(600, "", {}, "idle")]
	stand_by(Vector2i(int(w.stalls[sid].x), int(w.stalls[sid].y)))
	check(str(main.target.get("label", "")) == "Trade with %s (%s)" % [merchant.name, w.shop_name(merchant)], "with the merchant there: \"%s\"" % main.target.get("label", ""))
	# taking food from a tavern table: theft, said in the prompt, the dish goes into the pack
	var table: Dictionary = {}
	for c in w.containers:
		if c.kind == "table" and c.inv.total() > 0:
			table = c
			break
	check(not table.is_empty(), "a tavern table has food on it")
	stand_by(Vector2i(int(table.x), int(table.y)))
	var dish: String = w.container_pick(table)
	check(main.target.get("label", "") == "Take %s (the tavern's) — theft" % GameData.item_name(dish).to_lower(), "the prompt says what happens: \"%s\"" % main.target.get("label", ""))
	var crimes_before := p.crimes.size()
	var dishes := p.inv.count(dish)
	p.coins = 50
	main.interact()
	var stopped := w.last_guard != ""
	check(p.crimes.size() == crimes_before + 1 and p.crimes[-1].kind == "theft" and (p.inv.count(dish) == dishes + 1 or stopped), "took the %s: theft%s" % [dish, " (a guard stopped it)" if stopped else ""])
	check(table.inv.total() == 0 or stopped, "the table is empty")
	# a pickpocket's choice in the conversation with someone beside the player
	var mark: NPC = null
	for n: NPC in w.npcs:
		if n.alive and not main._covered(n) and not w.asleep(n) and n.role == "adult" and n.job != "guard" and not w.at_post(n) and n != v:
			mark = n
			break
	mark.pos = p.pos + Vector2(1.0, 0)
	mark.plan = [w.brain.work(600, "", {}, "idle")]
	ui.show_talk(mark)
	var crimes_now := p.crimes.size()
	check(_press("Pick pocket — theft") and not ui.is_open("talk"), "the conversation offers to pick %s's pocket" % mark.name)
	check(p.crimes.size() == crimes_now + 1 and p.crimes[-1].kind == "pickpocket", "the pickpocket is on the record (%s)" % ("unseen" if p.crimes[-1].witnesses == 0 else "caught"))

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
	# a controller connected to a phone: the touch buttons go at once, without a press; unplugged, they return
	var was_phone: bool = main.settings.phone
	main.settings.phone = true
	main.scheme = "touch"
	ui.set_scheme("touch")
	main._on_joy_connection(0, true)
	check(main.scheme == "gamepad" and not ui.touch_bar.visible, "a controller connected to a phone hides the touch buttons and uses the pad's controls")
	main._on_joy_connection(0, false)
	check(main.scheme == ("touch" if Input.get_connected_joypads().is_empty() else "gamepad") and ui.touch_bar.visible == Input.get_connected_joypads().is_empty(), "unplugged, the phone goes back to touch")
	check(not main.is_pad("uinput-fpc") and not main.is_pad("Goodix Fingerprint") and not main.is_pad("gf_input") and not main.is_pad("Bluetooth Keyboard")
			and main.is_pad("Xbox Wireless Controller") and main.is_pad("DualSense Wireless Controller") and main.is_pad(""),
		"a phone's fingerprint reader or a keyboard reported as a joypad is not a controller; real pads are")
	main.settings.phone = was_phone
	main._input(pad)
	# the pack with a pad: focus starts on the first bag cell and moves between cells and tabs by
	# position, skipping locked cells; B closes it
	ui.show_inventory()
	var pack: InventoryWindow = ui.inventory_window()
	await process_frame
	await process_frame
	check(pack.get_viewport().gui_get_focus_owner() == pack.cells[0], "the pack's first bag cell has the pad's focus")
	var inside := Rect2(Vector2.ZERO, pack.size).grow(0.5)
	check(pack.cells.all(func(c): return inside.encloses(Rect2(c.position, c.size))) and inside.encloses(Rect2(pack.details.position, pack.details.size)), "the panel and the details fit the window")
	check(pack.cells[0].find_valid_focus_neighbor(SIDE_RIGHT) == pack.cells[1] and pack.cells[0].find_valid_focus_neighbor(SIDE_BOTTOM) == pack.cells[9] \
		and pack.cells[0].find_valid_focus_neighbor(SIDE_TOP) in pack.tab_buttons, "the pad moves right and down the grid, and up to the tabs")
	check(pack.cells[23].find_valid_focus_neighbor(SIDE_RIGHT) != pack.cells[24], "focus skips the locked cells")
	var pad_b := InputEventJoypadButton.new()
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = true
	main._unhandled_input(pad_b)
	check(not ui.modal(), "the pad's B closes the pack")
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
	var home_was := home_q.pos
	home_q.pos = Vector2(w.home_cell(home_q, "bed")) + Vector2(0.5, 0.5)       # inside, under the roof
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
	home_q.pos = home_was
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
	# paid work: a farmer at harvest hires the player; the wage comes from the farmer's purse
	var farmer_h: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "farmer" and not w.quests.field_of(n).is_empty() and w.quests.active_from(n).is_empty() and not w.quests.offers.has(n.id):
			farmer_h = n
			break
	var fld: Dictionary = w.quests.field_of(farmer_h)
	w.set_field(fld, "ripe")
	fld.crop = int(GameData.b("field_yield"))
	farmer_h.coins = 20
	ui.show_talk(farmer_h)
	check(_press("Any work for me?") and _speech().contains("24 wheat"), "a farmer at harvest offers a day's work: %s" % _speech())
	check(_press("I'll do it") and w.player.quests.any(func(q): return q.id == "work_the_harvest"), "accepting takes on the work")
	ui.show_journal(-1, true)
	var jtext: String = " ".join(ui.panel_body.find_children("*", "Label", true, false).map(func(l): return l.text))
	check(jtext.contains("Work the harvest") and jtext.contains("for 6 coins"), "the journal lists the work and its wage")
	check(jtext.contains("Earning money") and jtext.contains("the reeve at the manor"), "the journal's quests page keeps the note on earning money")
	ui.hide_all()
	var crimes0 := p.crimes.size()
	var marks0 := p.stolen_count("wheat")
	for i in 4:
		w.player_harvest(fld)
	check(p.crimes.size() == crimes0 and p.stolen_count("wheat") == marks0, "cutting the wheat one was hired to cut is not theft (crimes %d -> %d, marks %d -> %d)" % [crimes0, p.crimes.size(), marks0, p.stolen_count("wheat")])
	var wage0 := p.coins
	var coins_all := w.total_coins()
	var purse_h := farmer_h.coins
	var held_q: Dictionary = w.quests.active_from(farmer_h)
	ui.show_talk(farmer_h)
	check(int(held_q.get("reserved", 0)) == 6 and _press("Here you are") and p.coins == wage0 + 6 and farmer_h.coins == purse_h and w.total_coins() == coins_all,
			"handing in the wheat pays the wage the farmer set aside from their purse")
	ui.hide_all()
	# a skill quest: the tanner teaches Crafting for two hides, under the scroll marker
	var tanner: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "tanner":
			tanner = n
			break
	tanner.inv.remove("hide", tanner.inv.count("hide"))
	w.quests.offers.erase(tanner.id)
	w.quests.refresh()
	w.quests.offers[tanner.id] = "the_tanners_craft"         # (the dawn's offers may be full already)
	tanner.pos = main.camera.get_screen_center_position() / main.T + Vector2(2, 0)     # markers show within sight of the camera
	main._sync_diamonds()
	check(main.diamonds.has(tanner.id) and main.diamonds[tanner.id].texture.resource_path.ends_with("skill.png"), "the tanner with a skill to teach shows the scroll")
	ui.show_talk(tanner)
	check(_press("Need any help?") and _speech().contains("2 hide"), "the tanner asks for hides: %s" % _speech())
	check(_press("I'll do it"), "accepting the tanner's quest")
	p.inv.add("hide", 2)
	ui.show_talk(tanner)
	var note: Label = null
	check(_press("Here you are"), "handing in the hides")
	note = ui.panel_body.find_child("Note", true, false)
	check(p.level("crafting") == 2 and note != null and note.text.contains("Crafting is now level 2") and note.text.contains("leather armour"), "the talk window says what was learned: %s" % (note.text if note else "no note"))
	ui.hide_all()

	# 19-20. save, reload, and the state is the same
	var snap := {"name": p.name, "look": p.look, "sprite": p.sprite, "coins": p.coins, "hp": int(p.hp),
		"weapon": p.weapon, "tool": p.tool, "armor": p.armor, "head": p.head, "amulet": p.amulet, "ring": p.ring, "wheat": p.inv.count("wheat"), "crimes": p.crimes.size(),
		"minutes": int(w.minutes), "pos": Vector2i(p.pos)}
	main.save_game(false)
	main.continue_game()
	var q: PlayerState = main.world.player
	var now := {"name": q.name, "look": q.look, "sprite": q.sprite, "coins": q.coins, "hp": int(q.hp),
		"weapon": q.weapon, "tool": q.tool, "armor": q.armor, "head": q.head, "amulet": q.amulet, "ring": q.ring, "wheat": q.inv.count("wheat"), "crimes": q.crimes.size(),
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
		if a.alive and not a.wild() and w2.pen_keeper(w2.fauna.pens[a.area]) != null:
			beast = a
			break
	var keeper: NPC = w2.pen_keeper(w2.fauna.pens[beast.area])
	var kind := beast.label().to_lower()
	var kp0 := keeper.pos
	keeper.pos = w2.player.pos + Vector2(40, 0)      # out of sight: PAR-05, the keeper cannot know who did it
	keeper.anim = "idle"
	main._hit_animal(beast, 9999.0)
	check(Dialogue.animal_killed(w2, keeper) == "" and keeper.memory.has("found my %s dead" % kind), "PAR-05: a keeper who did not see it finds their %s dead, and does not know who killed it" % kind)
	beast = null
	for a: Animal in w2.fauna.animals:
		if a.alive and not a.wild() and w2.pen_keeper(w2.fauna.pens[a.area]) == keeper:
			beast = a
			break
	if beast == null:
		for a: Animal in w2.fauna.animals:
			if a.alive and not a.wild() and w2.pen_keeper(w2.fauna.pens[a.area]) != null:
				beast = a
				break
	keeper = w2.pen_keeper(w2.fauna.pens[beast.area])
	kind = beast.label().to_lower()
	keeper.pos = w2.player.pos + Vector2(1.5, 0)     # in sight
	keeper.anim = "idle"
	main._hit_animal(beast, 9999.0)
	keeper.pos = kp0
	check(not Dialogue.attacked(w2, keeper) and Dialogue.animal_killed(w2, keeper) == kind, "the keeper who saw it remembers that the player killed their %s" % kind)
	check(Dialogue.opening(w2, keeper).contains(kind), "and says so: \"%s\"" % Dialogue.opening(w2, keeper))

	# 23. inside a building its roof fades, and only its roof; who is inside shows to the player inside
	# and is under the roof to the player outside (owner decision: roof fade, one entry mechanic)
	var pi: World = main.world
	var a3: TileMapLayer = main.view.layer("above3")
	var in5 := Vector2i(int(pi.interiors["b5"].floor[0][0]), int(pi.interiors["b5"].floor[0][1]))
	var in6 := Vector2i(int(pi.interiors["b6"].floor[0][0]), int(pi.interiors["b6"].floor[0][1]))
	check(a3.get_cell_source_id(in5) != -1 and a3.get_cell_source_id(in6) != -1, "the houses' roofs cover their insides")
	var resident: NPC = null
	for n: NPC in pi.npcs:
		if n.alive and n.home == "b5" and n.role == "adult":
			resident = n
			break
	resident.pos = Vector2(pi.home_cell(resident, "chest")) + Vector2(0.5, 0.5)
	resident.plan = [pi.brain.work(600, "", {}, "idle")]
	resident.anim = "idle"
	var outside_at := Vector2(pi.building_door("b5")) + Vector2(0.5, 1.5)
	pi.player.pos = outside_at
	main.camera.position = pi.player.pos * main.T
	main._sync_sprites()
	check(main._covered(resident) and not main.sprites[resident.id].visible, "from outside, someone inside a house is under its roof")
	pi.player.pos = Vector2(in5) + Vector2(0.5, 0.5)
	main.camera.position = pi.player.pos * main.T
	main.camera.reset_smoothing()
	main.camera.force_update_scroll()
	main._sync_sprites()
	main.roofs.update("b5", pi.interiors["b5"].roof, RoofFade.ALPHA, 1.0)
	check(main.roofs.current == "b5" and main.roofs.alpha <= 0.01 and a3.get_cell_source_id(in5) == -1, "inside house b5 its roof fades out")
	check(a3.get_cell_source_id(in6) != -1, "the next house's roof stays")
	main._sync_sprites()
	check(not main._covered(resident) and main.sprites[resident.id].visible, "inside, the player sees %s" % resident.name)
	main._find_target()
	resident.anim = "sleep"
	resident.pos = Vector2(pi.home_cell(resident, "bed")) + Vector2(0.5, 0.5)
	main._sync_sprites()
	var bed := pi.home_spot(resident, "bed")
	var rs: ActorSprite = main.sprites[resident.id]
	check(rs.visible and rs.pose == "lie" and (rs.position + Vector2(0, ActorSprite.LIE_BODY_Y).rotated(rs.rotation) * rs.scale.x).distance_to((Vector2(int(bed.at[0]), int(bed.at[1])) + Vector2(0.5, 0.5)) * main.T) < 3.0, "asleep, %s lies in their bed" % resident.name)
	resident.anim = "idle"
	pi.player.pos = outside_at
	main._sync_sprites()
	main.roofs.update("", [], 1.0, 1.0)
	main.roofs.update("", [], 1.0, 1.0)
	check(main.roofs.current == "" and a3.get_cell_source_id(in5) != -1, "outside again, the roof comes back")
	# owner rules: behind the eaves a roof fades only part way, and not in passing; no door flicker
	var area5 := {}
	for c in pi.interiors["b5"].area:
		area5[Vector2i(int(c[0]), int(c[1]))] = true
	var eave := Vector2i(-1, -1)
	for c in pi.interiors["b5"].roof:
		if not area5.has(Vector2i(int(c[0]), int(c[1]))):
			eave = Vector2i(int(c[0]), int(c[1]))
			break
	var r5: Array = pi.interiors["b5"].roof
	main.roofs.follow("", [], "b5", r5, 0.2)
	check(main.roofs.current == "", "passing behind the eaves does not fade the roof")
	main.roofs.follow("", [], "b5", r5, 0.3)
	for k in 4:
		main.roofs.follow("", [], "b5", r5, 0.1)
	check(main.roofs.current == "b5" and absf(main.roofs.alpha - RoofFade.EAVES_ALPHA) < 0.01 and not main.roofs.is_open("b5"), "staying behind the eaves fades the roof part way, so the player shows")
	main.roofs.follow("b5", r5, "b5", r5, 1.0)
	check(main.roofs.is_open("b5") and main.roofs.alpha <= 0.01, "going inside lifts it fully at once")
	main.roofs.follow("", [], "", [], 0.1)
	main.roofs.follow("b5", r5, "b5", r5, 0.1)
	check(main.roofs.current == "b5" and main.roofs.alpha <= 0.01, "a step out of the door and back does not flicker the roof")
	main.roofs.follow("", [], "", [], 0.5)
	for k in 6:
		main.roofs.follow("", [], "", [], 0.1)
	check(main.roofs.current == "", "out for good, the roof comes back")
	check(eave != Vector2i(-1, -1), "b5 has eaves outside its floor")
	# owner rule: sleepers are not untouchable; sleep limits awareness
	resident.anim = "sleep"
	resident.pos = Vector2(pi.home_cell(resident, "bed")) + Vector2(0.5, 0.5)
	pi.player.pos = resident.pos + Vector2(0.6, 0)
	check(pi.present(pi.player.pos, 2.0).has(resident) and not pi.near(pi.player.pos, 2.0).has(resident), "a sleeper is there to reach but sees nothing")
	main.approach(resident)
	check(ui.is_open("sleeper") and pi.asleep(resident), "using a sleeper offers to wake them or try their pocket")
	ui.hide_all()
	var saw_ok := false
	var saw_fumble := false
	for k in 40:
		resident.anim = "sleep"
		resident.coins = 5
		var mem_before := resident.memory.size()
		var pr := pi.pickpocket(resident)
		if pr.ok and pi.asleep(resident):
			saw_ok = true
		elif not pr.ok and not pi.asleep(resident) and resident.memory.size() > mem_before:
			saw_fumble = true
		pi.player.crimes.clear()
		if saw_ok and saw_fumble:
			break
	check(saw_ok, "a sleeper's pocket can be picked without waking them")
	check(saw_fumble, "a fumble wakes them, and they remember it")
	resident.memory.clear()
	resident.anim = "sleep"
	check(pi.wake(resident) and not pi.asleep(resident), "waking someone gets them up")
	resident.anim = "sleep"
	var other: NPC = null
	for n: NPC in pi.npcs:
		if n.alive and n != resident and n.role == "adult" and n.home == resident.home:
			other = n
			break
	if other:
		other.anim = "sleep"
		other.pos = resident.pos + Vector2(1, 0)
	main._hit(resident, 0.1)
	check(not pi.asleep(resident) and (other == null or not pi.asleep(other)), "a blow wakes the sleeper and the noise wakes the room")
	resident.target = -1
	pi.player.crimes.clear()
	# a house the player builds: the same inside, roof fade, bed and chest
	var pl2: Dictionary = pi.plots[1]
	pi.player.coins += int(pl2.price)
	pi.buy_plot(pl2)
	pi.start_site(pl2)
	var cost: Dictionary = GameData.b("house_cost")
	for id in cost:
		pi.player.inv.add(id, int(cost[id]))
	pi.deliver(pl2, pi.player.inv)
	var hid := "house_" + str(pl2.id)
	pi.player.home = hid
	var hin: Dictionary = pi.interiors[hid]
	var hbed: Dictionary = (hin.spots as Array).filter(func(s): return s.kind == "bed")[0]
	pi.player.pos = Vector2(int(hbed.use[0]), int(hbed.use[1])) + Vector2(0.5, 0.5)
	main.player_sprite.face(Vector2(int(hbed.at[0]), int(hbed.at[1])) - Vector2(int(hbed.use[0]), int(hbed.use[1])))
	main._sync_sprites()
	main.roofs.update(hid, hin.roof, 1.0)
	check(main.roofs.current == hid and a3.get_cell_source_id(Vector2i(int(hbed.use[0]), int(hbed.use[1]))) == -1, "inside the house the player built, its roof fades too")
	main._find_target()
	check(main.target.get("kind", "") == "rest", "the bed in the player's house rests (%s)" % main.target.get("label", ""))
	var hchest: Dictionary = (hin.spots as Array).filter(func(s): return s.kind == "chest")[0]
	pi.player.pos = Vector2(int(hchest.use[0]), int(hchest.use[1])) + Vector2(0.5, 0.5)
	main.player_sprite.face(Vector2(int(hchest.at[0]), int(hchest.at[1])) - Vector2(int(hchest.use[0]), int(hchest.use[1])))
	main._find_target()
	check(main.target.get("kind", "") == "home", "its chest opens the family's store (%s)" % main.target.get("label", ""))
	pi.player.pos = Vector2(pi.building_door(hid)) + Vector2(0.5, 0.5)
	main._find_target()
	check(main.target.get("kind", "") == "home", "and the door still offers rest and the chest")

	# 24. land and houses: a house whose family died out is the manor's; at its door the player buys
	# it, it shows at the reeve's land office with the house they built, and they choose their home
	var gone := ""
	for hh in pi.households:
		if gone == "" and pi.buildings[hh.home].type == "house" and hh.members.all(func(m): return not pi.npc(int(m)).job in ["farmer", "merchant"]):
			gone = hh.home
	for m in pi.households[pi.household_in(gone)].members:
		pi.kill(pi.npc(int(m)), "fever")
	pi.player.pos = Vector2(pi.building_door(gone)) + Vector2(0.5, 0.5)
	main._find_target()
	check(main.target.get("kind", "") == "property" and str(main.target.get("label", "")).contains("empty, the manor's"), "at an empty house's door: %s" % main.target.get("label", ""))
	pi.player.coins = 500
	main.interact()
	check(ui.is_open("land") and _press("Buy (%d)" % int(GameData.b("house_price"))) and pi.owner_of(pi.buildings[gone]) == World.PLAYER, "the player buys the empty house at its door")
	check(pi.player.home == hid and pi.property.homes_of(World.PLAYER).size() == 2, "the home stays the house they built; they hold two")
	ui.hide_all()
	main._find_target()
	check(main.target.get("kind", "") == "property" and str(main.target.label).contains("make it your home"), "its door offers to make it the home: %s" % main.target.get("label", ""))
	var reeve: NPC = pi.npc(pi.reeve_id)
	ui.show_talk(reeve)
	check(_press("Land and houses") and ui.is_open("land") and _press("Make it home") and pi.player.home == gone, "at the reeve's land office the player makes it their home")
	ui.hide_all()
	ui.show_land(reeve)
	var land_text := " ".join(ui.panel_body.find_children("*", "Label", true, false).map(func(l): return (l as Label).text))
	check(not land_text.contains("plot0") and not land_text.contains("(b") and not land_text.contains("parcel"), "the land office names places without internal ids")
	ui.hide_all()

	# 25. build anywhere (property phase 2): Menu > Build, choose a workshop, move its footprint
	# (red where it may not go, green where it may), place it, buy the ground, the frame goes up
	var cons: Construction = pi.construction
	ui.show_pause()
	check(_press("Build") and ui.is_open("build_menu"), "the menu opens the build window")
	check(_press("Choose a place") and not main.placing.is_empty() and ui.place_bar.visible and main.ghost.visible and main.paused, "choosing a house starts placing it: the footprint shows, the game waits")
	main.end_placement()
	var b5r := Rect2i(int(pi.buildings["b5"].x), int(pi.buildings["b5"].y), 9, 10)
	main.begin_placement("smithy")
	main.move_ghost_to(b5r.get_center())
	check(not main.ghost.legal and ui.place_label.text.contains("cannot go here"), "over a house the footprint is red: %s" % ui.place_label.text)
	main.confirm_placement()
	check(not ui.modal() and not main.placing.is_empty(), "and it cannot be placed there")
	var build_spot := Rect2i(Vector2i(-1, -1), cons.footprint("smithy"))
	for y in range(1, 30):            # the first place in the woods held only by a mature tree (the trees have no fixed places)
		for x in range(1, 100):
			if build_spot.position.x < 0 and cons.can_place("smithy", Rect2i(Vector2i(x, y), cons.footprint("smithy")), World.PLAYER).contains("fell it first"):
				build_spot.position = Vector2i(x, y)
	for t in pi.trees:
		if t.state == "grown" and (build_spot.has_point(Vector2i(int(t.x), int(t.y))) or Vector2i(int(t.x), int(t.y)) == cons.door_step("smithy", build_spot)):
			pi.fell(t, 0)
	main.move_ghost_to(build_spot.position + build_spot.size / 2)
	check(main.place_rect() == build_spot and main.ghost.legal and ui.place_label.text.contains("coins or"), "on clear ground it is green, with the ground's price: %s" % ui.place_label.text)
	Input.action_press("move_left")
	main._placing_step(0.2)
	Input.action_release("move_left")
	check(main.place_rect().position == build_spot.position + Vector2i(-1, 0), "the arrow keys (or the stick) move it a tile")
	main.move_ghost_to(build_spot.position + build_spot.size / 2)
	pi.player.coins = 300
	main.confirm_placement()
	check(ui.is_open("place"), "placing it opens the deal for the ground")
	var gp: int = cons.ground_terms(build_spot).price
	check(_press("Buy the ground and mark out") and main.placing.is_empty() and ui.is_open("build"), "buying the ground marks out the site in the same step")
	var ws: Dictionary = cons.sites_of(World.PLAYER).filter(func(x): return int(x.x) == build_spot.position.x and int(x.y) == build_spot.position.y)[0] if not cons.sites_of(World.PLAYER).is_empty() else {}
	check(not ws.is_empty() and str(ws.site.kind) == "smithy" and pi.owner_of(ws) == World.PLAYER and pi.player.coins == 300 - gp, "the smithy's site is the player's; %d coins paid for the ground" % gp)
	ui.hide_all()
	# hire a helper in conversation: the materials from the family chest
	var hired: NPC = null
	for o: NPC in pi.npcs:
		if o.alive and o.role == "adult" and o.job in ["miner", "woodcutter", "laborer"] and o.household >= 0 and not pi.asleep(o) and o.target == -1:
			hired = o
			break
	hired.job = ""
	hired.workplace = ""
	hired.pos = pi.player.pos + Vector2(1.0, 0)
	hired.plan = [pi.brain.work(600, "", {}, "idle")]
	for id in ws.site.need:
		pi.player.chest.add(id, int(ws.site.need[id]))
	ui.show_talk(hired)
	check(_press("Hire to carry building materials"), "a villager out of work can be hired to carry building materials")
	var purse := pi.player.coins
	check(_press("From my chest") and not cons.contract_of(hired).is_empty() and pi.player.coins == purse - int(GameData.b("helper_wage")), "hired for the day's wage from the chest")
	ui.hide_all()
	# the finished smithy: its door offers who may use it
	var wbag := Inventory.new()
	for id in ws.site.need:
		wbag.add(id, int(ws.site.need[id]))
	pi.deliver(ws, wbag, World.PLAYER)
	var wid := "workshop_" + str(ws.id)
	check(pi.buildings.has(wid) and main.roofs != null, "the smithy is finished")
	pi.player.pos = Vector2(pi.building_door(wid)) + Vector2(0.5, 0.5)
	main._find_target()
	check(main.target.get("kind", "") == "workshop", "its door: %s" % main.target.get("label", ""))
	main.interact()
	check(ui.is_open("workshop") and _press("Let anyone work here") and (pi.buildings[wid].allow as Array).has("all"), "its owner lets anyone work there")
	ui.hide_all()
	# inside, the forge is the player's to use; the village's forge waits while the smith works it
	var forge := "ws_%s_forge" % wid
	pi.player.pos = Vector2(pi.station_use(forge)) + Vector2(0.5, 0.5)
	main.player_sprite.face(Vector2(1, -1))
	main._find_target()
	check(main.target.get("kind", "") == "station" and str(main.target.get("id", "")) == forge and str(main.target.label) == "Use the forge", "inside the smithy: %s" % main.target.get("label", ""))
	main._sync_sprites()
	check(pi.place_of(pi.player.pos) == wid, "the forge stands inside the smithy")
	main.roofs.follow(pi.place_of(pi.player.pos), pi.interiors[wid].roof, pi.roof_over(pi.player.pos), pi.interiors[wid].roof, 1.0)
	main.roofs.follow(pi.place_of(pi.player.pos), pi.interiors[wid].roof, pi.roof_over(pi.player.pos), pi.interiors[wid].roof, 1.0)
	check(main.roofs.current == wid and main.roofs.alpha <= 0.01, "inside the smithy its roof fades")
	var the_smith: NPC = null
	for o: NPC in pi.npcs:
		if o.alive and o.job == "smith" and the_smith == null:
			the_smith = o
	pi.stations["s4"].users[the_smith.id] = pi.minutes + 300.0
	the_smith.plan = [pi.brain.go(pi.station_use("s4")), pi.brain.work(40, "craft", {"recipe": "smelt_iron", "station": "s4"})]
	ui.show_craft("s4")
	var makes: Array = _buttons(ui.panel_body, []).filter(func(b): return b.text == "Make")
	check(not makes.is_empty() and makes.all(func(b): return b.disabled), "at a station a villager is working, the player waits (Make is off)")
	the_smith.plan.clear()
	ui.hide_all()

	_resources_tests()
	_gather_tests()
	_save_safety_tests()
	_save_meta_tests()
	_collision_tests()
	_hit_feedback_tests()
	_roof_tests()
	_pad_cycle_tests()
	_sign_tests()
	await _b8_ui_tests()
	await _pl_trade_ui_tests()
	_child_size_tests()
	_animal_size_tests()
	await _actions_tests()

	_clear_saves()
	print("%d steps, %d failures" % [steps.size(), failures])
	quit(1 if failures else 0)


## Step the player (movement, gathering, actions) without advancing the village.
func run_frames(n: int, dt := 0.1) -> void:
	for i in n:
		main._player_step(dt)


## Tap the screen where a map position is drawn (touch and mouse go through main._tap).
func tap_at(wpos: Vector2) -> void:
	main._tap(main.get_canvas_transform() * (wpos * main.T))


## Gather mode (B7-012) and tapping resources (B7-011), through the real input routing.
func _gather_tests() -> void:
	main.new_game()
	var w: World = main.world
	var p := w.player
	var ui = main.ui
	ui.hide_all()
	# the button: on and off; Gather and Attack exclude each other
	main.gather_button()
	check(main.gather_mode and ui.gather_btn.text == "Gather ON", "Gather turns gather mode on (the button shows it)")
	main.attack_button()
	check(main.attack_mode and not main.gather_mode and ui.gather_btn.text == "Gather", "Attack turns Gather off")
	main.gather_button()
	check(main.gather_mode and not main.attack_mode, "and Gather turns Attack off")
	# a seam: tap it, the player walks there and mines it cycle after cycle until it runs out
	var dep: Dictionary = {}
	for d in w.deposits:
		if d.ore == "iron_ore" and (dep.is_empty() or Vector2(d.x, d.y).distance_to(p.pos) < Vector2(dep.x, dep.y).distance_to(p.pos)):
			dep = d
	dep.amount = 3
	var cell := Vector2i(int(dep.x), int(dep.y))
	p.pos = Vector2(w.brain.beside(cell, cell + Vector2i(0, 1))) + Vector2(4.5, 3.5)
	if w.map.is_solid(Vector2i(floori(p.pos.x), floori(p.pos.y))):
		p.pos = Vector2(w.brain.beside(cell, cell + Vector2i(0, 1))) + Vector2(0.5, 0.5)
	var ore0 := p.inv.count("iron_ore")
	var stamina0 := p.stamina
	tap_at(Vector2(cell) + Vector2(0.5, 0.5))
	check(not main.gather.is_empty() and str(main.gather.def.match.kind) == "deposit" and main.gather.ref == dep, "in Gather mode a tap on a seam chooses it")
	main._sync_gather_mark()
	check(main.gather_mark.visible, "the chosen seam is outlined")
	var guard := 0
	while not main.gather.is_empty() and guard < 20000:
		run_frames(1, 0.05)
		guard += 1
	check(int(dep.amount) == 0 and p.inv.count("iron_ore") >= ore0 + 3, "the player walks to it and mines it, cycle after cycle, until it is worked out (%d ore)" % (p.inv.count("iron_ore") - ore0))
	check(main.gather.is_empty() and main.gather_mode, "then gathering stops and Gather mode stays on")
	check(p.stamina >= stamina0, "mining costs no stamina (the existing rule; ResourceNodes action_cost)")
	# no tool: a tree without an axe says so and does nothing
	p.inv.remove("axe", p.inv.count("axe"))
	var tree: Dictionary = {}
	for t in w.trees:
		if t.state == "grown" and (tree.is_empty() or Vector2(t.x, t.y).distance_to(p.pos) < Vector2(tree.x, tree.y).distance_to(p.pos)):
			tree = t
	tap_at(Vector2(int(tree.x), int(tree.y) - 1) + Vector2(0.5, 0.5))          # its canopy
	check(main.gather.is_empty() and ui.toast.text.to_lower().contains("axe"), "a tree tapped on its canopy, without an axe: \"%s\"" % ui.toast.text)
	# with an axe it is felled once (a tree gives its logs in one cycle), and gathering stops
	p.inv.add("axe")
	var logs0 := p.inv.count("log")
	tap_at(Vector2(int(tree.x), int(tree.y) - 1) + Vector2(0.5, 0.5))
	guard = 0
	while not main.gather.is_empty() and guard < 20000:
		run_frames(1, 0.05)
		guard += 1
	check(str(tree.state) != "grown" and p.inv.count("log") > logs0, "with an axe the tree is felled (%d logs) and gathering stops at the stump" % (p.inv.count("log") - logs0))
	# moving cancels gathering; Gather stays on (from a few tiles away: the felling left the player by the tree)
	p.pos = Vector2(w.map.nearest_walkable(cell + Vector2i(6, 5))) + Vector2(0.5, 0.5)
	dep.amount = 5
	tap_at(Vector2(cell) + Vector2(0.5, 0.5))
	run_frames(4, 0.05)
	Input.action_press("move_left")
	run_frames(1)
	Input.action_release("move_left")
	check(main.gather.is_empty() and main.gather_mode, "moving by hand stops gathering; Gather mode stays on")
	# Gather off cancels walking and gathering
	tap_at(Vector2(cell) + Vector2(0.5, 0.5))
	run_frames(1)
	main.gather_button()
	check(main.gather.is_empty() and main.move_to == Vector2.INF and not main.gather_mode, "Gather off cancels the walk and the gathering")
	# a full pack stops it
	main.gather_button()
	var stacks := p.inv.max_stacks
	p.inv.max_stacks = p.inv.items.size()
	p.inv.remove("iron_ore", p.inv.count("iron_ore"))
	p.inv.max_stacks = p.inv.items.size()
	tap_at(Vector2(cell) + Vector2(0.5, 0.5))
	run_frames(6, 0.05)
	check(main.gather.is_empty() and ui.toast.text.contains("pack is full"), "a full pack stops gathering: \"%s\"" % ui.toast.text)
	p.inv.max_stacks = stacks
	# a farmer's field: warned once, then taken (theft, as by hand)
	var f: Dictionary = w.fields[0]
	w.set_field(f, "ripe")
	f.crop = 12
	var crimes0 := p.crimes.size()
	var fc := Vector2(int(f.x) + 1, int(f.y) + 1) + Vector2(0.5, 0.5)
	tap_at(fc)
	check(main.gather.is_empty() and ui.toast.text.contains("theft"), "a farmer's field: a warning first (\"%s\")" % ui.toast.text)
	tap_at(fc)
	guard = 0
	while not main.gather.is_empty() and guard < 20000:
		run_frames(1, 0.05)
		guard += 1
	check(int(f.crop) == 0 and p.crimes.size() > crimes0, "tapped again it is harvested to the end, as theft (crimes %d -> %d)" % [crimes0, p.crimes.size()])
	# out of Gather mode, a tap on a seam walks to it and mines it once
	main.gather_button()
	dep.amount = 5
	tap_at(Vector2(cell) + Vector2(0.5, 0.5))
	guard = 0
	while not main.gather.is_empty() and guard < 20000:
		run_frames(1, 0.05)
		guard += 1
	check(int(dep.amount) in [3, 4], "without Gather mode, a tap on a seam walks there and mines once (%d left)" % int(dep.amount))
	# keys and pad: Use in front of a seam in Gather mode chooses it
	main.gather_button()
	stand_by(cell)
	main.interact()
	check(not main.gather.is_empty() and main.gather.ref == dep, "in Gather mode, Use in front of a seam chooses it (keys and pad)")
	# unreachable: walled in, the player gives up with a message
	main.stop_gather("")
	var walls := []
	for dc in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		if not w.map.is_solid(cell + dc):
			walls.append(cell + dc)
			w.map.set_solid(cell + dc, true)
	p.pos = Vector2(cell) + Vector2(6.5, 6.5)
	if w.map.is_solid(Vector2i(floori(p.pos.x), floori(p.pos.y))):
		p.pos = Vector2(cell) + Vector2(-5.5, 6.5)
	tap_at(Vector2(cell) + Vector2(0.5, 0.5))
	guard = 0
	while not main.gather.is_empty() and guard < 20000:
		run_frames(1, 0.05)
		guard += 1
	check(ui.toast.text.contains("can't reach"), "a seam that cannot be reached: \"%s\"" % ui.toast.text)
	for c in walls:
		w.map.set_solid(c, false)
	# game: in Gather mode a tap on a wild animal hunts it (the weapon, as attack mode strikes)
	main.stop_gather("")
	var game: Animal = null
	for an: Animal in w.fauna.animals:
		if an.alive and an.wild():
			game = an
			break
	p.pos = game.pos + Vector2(2.0, 0)
	main._creature_at(game.pos)
	tap_at(game.pos - Vector2(0, 0.4))
	check(not main.gather.is_empty() and main.gather.ref == game and main.chase == game, "in Gather mode a tap on wild game hunts it")
	main.stop_gather("")
	check(main.chase == null, "and stopping drops the chase")
	# gathering is not saved: a save mid-gather loads with nothing chosen
	tap_at(Vector2(cell) + Vector2(0.5, 0.5))
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(not JSON.stringify(d).contains("gather") and w2.total_coins() == w.total_coins(), "gathering is not part of a save; the save loads unchanged")
	w2.dispose()
	main.stop_gather("")
	_plant_gather_tests()


## Flowers and berry bushes (B8-015, B8-016): walked over, tapped, used and gathered in Gather mode.
func _plant_gather_tests() -> void:
	var w: World = main.world
	var p := w.player
	var ui = main.ui
	ui.hide_all()
	main.stop_gather("")
	if main.gather_mode:
		main.gather_button()
	# SEED-03: berry bushes bear only in their seasons (the game starts in spring): the clock is moved on to summer
	while not w.plant_in_season("redberry") or not w.plant_in_season("blueberry"):
		w.minutes += 1440.0
	w.season_plants()
	main._show_plants()
	var bush: Dictionary = {}
	var flower: Dictionary = {}
	for pl in w.plants:
		if pl.state == "ripe" and pl.kind == "redberry" and bush.is_empty():
			bush = pl
		if pl.state == "ripe" and pl.kind == "flower" and flower.is_empty():
			flower = pl
	var cell := Vector2i(bush.x, bush.y)
	# walking onto the plant's cell is allowed, and Use there offers to pick it
	check(not w.map.is_solid(cell), "the player may stand on a berry bush's cell")
	p.pos = Vector2(cell) + Vector2(0.5, 0.5)
	main.player_sprite.face(Vector2(0, 1))
	main._find_target()
	check(not main.target.is_empty() and main.target.kind == "plant" and main.target.label.to_lower().contains("red berries"), "the interact prompt offers the berries: \"%s\"" % str(main.target.get("label", "")))
	var b0 := p.inv.count("red_berries")
	main.interact()
	run_frames(60, 0.05)
	check(p.inv.count("red_berries") == b0 + 2 and bush.state == "picked", "Use picks the berries (%d) and the bush is bare" % (p.inv.count("red_berries") - b0))
	# a tap on a ripe flower (not in Gather mode) walks there and picks it once
	p.pos = Vector2(flower.x, flower.y) + Vector2(3.5, 0.5)
	if w.map.is_solid(Vector2i(floori(p.pos.x), floori(p.pos.y))):
		p.pos = Vector2(flower.x, flower.y) + Vector2(-3.5, 0.5)
	var f0 := p.inv.count("flower")
	tap_at(Vector2(flower.x, flower.y) + Vector2(0.5, 0.5))
	var guard := 0
	while (not main.gather.is_empty() or p.inv.count("flower") == f0) and guard < 4000:
		run_frames(1, 0.05)
		guard += 1
	check(p.inv.count("flower") == f0 + 1 and flower.state == "picked", "a tap on a flower walks there and picks it (once)")
	# Gather mode: a tap on a bare bush says so; a ripe bush is walked to and picked
	main.gather_button()
	tap_at(Vector2(cell) + Vector2(0.5, 0.5))
	check(main.gather.is_empty() and ui.toast.text.to_lower().contains("picked"), "Gather mode on a bare bush says it is picked: \"%s\"" % ui.toast.text)
	var other: Dictionary = {}
	for pl in w.plants:
		if pl.state == "ripe" and pl.kind == "blueberry" and (other.is_empty() or Vector2(pl.x, pl.y).distance_to(p.pos) < Vector2(other.x, other.y).distance_to(p.pos)):
			other = pl
	var c2 := Vector2i(other.x, other.y)
	var bb0 := p.inv.count("blueberries")
	tap_at(Vector2(c2) + Vector2(0.5, 0.5))
	check(not main.gather.is_empty() and str(main.gather.def.match.kind) == "plant" and main.gather.ref == other, "in Gather mode a tap on a berry bush chooses it")
	main._sync_gather_mark()
	check(main.gather_mark.visible, "the chosen bush is outlined")
	guard = 0
	while not main.gather.is_empty() and guard < 20000:
		run_frames(1, 0.05)
		guard += 1
	check(p.inv.count("blueberries") == bb0 + 2 and other.state == "picked" and main.gather.is_empty() and main.gather_mode, "Gather mode walks to the bush, picks it, and stops (Gather stays on)")
	var gains: Array = ui.log_texts()
	check(gains.any(func(t): return t.begins_with("+2 ")) and not ui.toast.text.begins_with("You pick") and not ui.prompt_text.begins_with("Picking"),
			"a pick is a short line in the corner, not a banner in the middle: %s, toast \"%s\"" % [gains, ui.toast.text])
	# a full pack refuses
	main.stop_gather("")
	var third: Dictionary = {}
	for pl in w.plants:
		if pl.state == "ripe" and pl.kind == "flower":
			third = pl
			break
	var held := p.inv.count("flower")
	var n := 0
	while p.inv.can_add("flower") and n < 500:
		p.inv.add("flower")
		n += 1
	if not p.inv.can_add("flower"):
		tap_at(Vector2(third.x, third.y) + Vector2(0.5, 0.5))
		guard = 0
		while not main.gather.is_empty() and guard < 4000:
			run_frames(1, 0.05)
			guard += 1
		check(third.state == "ripe" and ui.toast.text.contains("pack is full"), "a full pack stops picking: \"%s\"" % ui.toast.text)
	p.inv.remove("flower", p.inv.count("flower") - held)
	main.stop_gather("")
	main.gather_button()


func _texts(node: Node) -> String:
	return "\n".join(node.find_children("*", "", true, false).filter(func(c): return c is Label or c is Button).map(func(c): return c.text))


## The journal's Resources & Gathering page (B7-012): built from resources.json through ResourceNodes.
func _resources_tests() -> void:
	var ui = main.ui
	# it opens from the journal, beside Quests
	ui.show_journal(-1)
	check(_press("Resources") and ui.is_open("journal") and ui.title_label.text == "JOURNAL: RESOURCES", "the journal's Resources button opens Resources & Gathering")
	var text := _texts(ui.panel_body)
	check(text.contains("How to gather") and GameUI.GATHER_STEPS.all(func(t): return text.contains(t)), "the page starts with the Gather mode steps")
	check(text.contains("press G") and text.contains("D-pad down"), "and the keyboard and gamepad ways to gather")
	# exactly the player-harvestable nodes, each with its name, tool and products from the data
	var want := ResourceNodes.defs().keys().filter(func(id): return bool(ResourceNodes.def(id).player_harvest))
	var cards: Array = ui.panel_body.find_children("*", "PanelContainer", true, false).filter(func(c): return c.has_meta("node"))
	check(cards.map(func(c): return c.get_meta("node")) == want, "it lists exactly the player-harvestable nodes %s" % [want])
	var bad := []
	for c in cards:
		var d := ResourceNodes.def(c.get_meta("node"))
		var ct := _texts(c)
		var ok: bool = ct.contains(str(d.name)) and ct.contains(ui._res_tool(d)) and ct.contains("Uses")
		if str(d.tool) != "":
			ok = ok and ct.contains(str(d.tool).capitalize())
		for id in ResourceNodes.products(d):
			ok = ok and ct.contains("%s x%d" % [GameData.item_name(id), int(ResourceNodes.products(d)[id])])
		if not ok:
			bad.append(c.get_meta("node"))
	check(bad.is_empty(), "each node shows its name, tool and products from resources.json %s" % [bad])
	var kept := ResourceNodes.defs().keys().filter(func(id): return not bool(ResourceNodes.def(id).player_harvest))
	check(text.contains("Not yours to gather") and kept.all(func(id): return text.contains(str(ResourceNodes.def(id).name))), "the keepers' animals are under Not yours to gather")
	check(not text.contains(".gd") and not text.contains("World.") and not text.contains("_days"), "no code names reach the player")
	# with no axe, the tree's card says where to get one
	var tree_card: Control = cards.filter(func(c): return c.get_meta("node") == "tree")[0]
	check(main.world.player.tool_of("axe") != "" or _texts(tree_card).contains(str(ResourceNodes.def("tree").tool_hint).left(20)), "without the tool, the card says where to get one")
	# a node's page: its product's uses are uses_of, its chain is chain
	var open: Button = _buttons(tree_card, []).filter(func(b): return b.text == "Uses")[0]
	open.pressed.emit()
	text = _texts(ui.panel_body)
	var uses := ResourceNodes.uses_of("log")
	check(not uses.is_empty() and uses.all(func(u): return text.contains(ui._res_use_text(u))), "the tree's page lists every use of a log (%d)" % uses.size())
	check(uses.any(func(u): return u.kind == "recipe" and u.station == "sawhorse") and uses.any(func(u): return u.kind == "building"), "a log's uses include a sawhorse recipe and a building cost")
	check(text.contains("Crafting: 1 makes Plank x2 at the sawhorse") and text.contains("Building: "), "both are on the page")
	# follow the chain: log -> plank (sawhorse) -> pickaxe (anvil)
	check(_press("Plank x2") and _texts(ui.panel_body).contains("Pickaxe x1") and _texts(ui.panel_body).contains("at the anvil"), "following a plank shows what it becomes (a pickaxe at the anvil)")
	text = _texts(ui.panel_body)
	check(ResourceNodes.uses_of("plank").all(func(u): return text.contains(ui._res_use_text(u))) and text.contains("Where it comes from"), "the plank's own uses and sources")
	check(_press("Back") and _texts(ui.panel_body).contains(str(ResourceNodes.def("tree").name)) and _press("Back") and _texts(ui.panel_body).contains("How to gather"), "Back returns to the node, then to the list")
	# every button is a touch target and focusable for the pad
	var small := _buttons(ui.panel_body, []).filter(func(b): return b.get_combined_minimum_size().y < 48 or b.focus_mode == Control.FOCUS_NONE)
	check(small.is_empty(), "every button on the page is at least 48 px tall and focusable")
	# the other journal pages still work, and B closes the page
	check(_press("Quests") and ui.title_label.text == "JOURNAL: QUESTS" and _texts(ui.panel_body).contains("Earning money"), "Quests still opens the quests page")
	check(_press("Village record") and ui.title_label.text == "JOURNAL" and _press("Resources"), "and the village record, with Resources beside it")
	var pad_b := InputEventJoypadButton.new()
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = true
	main._unhandled_input(pad_b)
	check(not ui.modal(), "B on the gamepad closes it")


func _clear_saves() -> void:
	var dir := TEST_SAVE.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(f)))


func _raw(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<missing>"


func _put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


## The kept copies in the test save folder whose name contains `state` ("unreadable", "newer").
func _kept(state: String) -> Array:
	var dir := TEST_SAVE.get_base_dir()
	return Array(DirAccess.get_files_at(dir)).filter(func(f): return f.contains("." + state + "-")).map(func(f): return dir.path_join(f))


## Player data is never lost: a save that cannot be read is moved aside unchanged before anything
## writes, the backup is used when it can be, failed writes leave the last save alone, and the
## messages say exactly what happened (owner, 2026-10-18: the audit's save-overwrite finding).
## PL1-11 stage 1: a save carries its world's identity for moving it between devices.
func _save_meta_tests() -> void:
	main.new_game()
	var read := func() -> Dictionary:
		return JSON.parse_string(FileAccess.get_file_as_string(main.save_path)).get("meta", {})
	check(main.save_game(false), "(portable saves) the game saves")
	var m1: Dictionary = read.call()
	check(str(m1.get("save_id", "")).length() >= 12 and int(m1.get("saved_at", 0)) > 0 and m1.has("play_seconds") and m1.get("platform", "") != ""
			and m1.get("character", "") == main.world.player.name, "a save records its world id, times, play time, device and character: %s" % [m1])
	main.save_game(false)
	check(read.call().get("save_id") == m1.save_id, "saving again keeps the same world id")
	main.continue_game()
	main.save_game(false)
	check(read.call().get("save_id") == m1.save_id and read.call().get("created") == m1.created, "after loading, the world id and its creation time carry on")
	check(not FileAccess.get_file_as_string(main.save_path).contains(OS.get_user_data_dir()), "the save holds no device path")
	main.new_game()
	main.save_game(false)
	check(read.call().get("save_id") != m1.save_id, "a new game is a new world id")
	# SAVE-02/08 (owner 2026-10-20): the builds a world was played in, and sections this build does not know
	check(read.call().get("builds", []).size() >= 1 and str(read.call().get("build", "")) != "", "a save records the build that wrote it and the builds it has passed through")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.save_path))
	d["future_section"] = {"kept": [1, 2, 3]}
	_put(main.save_path, JSON.stringify(d, "", true, true))
	main.continue_game()
	main.save_game(false)
	var after: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.save_path))
	check(after.get("future_section", {}) == {"kept": [1.0, 2.0, 3.0]}, "a section this build does not know survives loading and saving unchanged")
	# the Saves tab: copy, import and keep a copy up to date
	main.ui.show_settings(Callable(), "saves")
	var labels := []
	for b: Button in _buttons(main.ui.panel_body, []):
		labels.append(b.text)
	check(labels.has("Copy my save to a file...") and labels.has("Import a save file...") and labels.has("Keep a copy up to date..."), "Settings has a Saves tab to copy, import and keep a copy (%s)" % [labels])
	main.ui.hide_all()
	var copy := TEST_SAVE.get_base_dir().path_join("outside/copy.json")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(copy.get_base_dir()))
	main.settings.save_copy = copy
	main.save_game(false)
	check(FileAccess.get_file_as_string(copy) == FileAccess.get_file_as_string(main.save_path), "a linked copy is updated every time the game saves")
	main.settings.save_copy = ""
	var r: Dictionary = main.import_save_from(copy)
	check(r.ok and main.running and main.world != null, "importing a copy continues that world (%s)" % r.get("reason", ""))


func _save_safety_tests() -> void:
	var ui = main.ui
	SaveStore.fail_at = ""
	# 1. a damaged save with no backup: kept byte for byte, a new game starts, and its saves go elsewhere
	_clear_saves()
	var damaged := "{\"save_version\": 8, \"seed\": 1, \"minutes\": 4"
	_put(TEST_SAVE, damaged)
	main.continue_game()
	var kept := _kept("unreadable")
	check(kept.size() == 1 and _raw(kept[0]) == damaged, "a damaged save is kept unchanged under a new name (%s)" % [kept])
	var msg: String = ui.toast.text
	check(msg.contains("could not be read") and msg.contains("damaged") and not kept.is_empty() and msg.contains(kept[0].get_file()) and msg.contains("A new game was started"), "the message says what happened and where the save was kept: %s" % msg)
	check(main.save_game(false) and kept.size() == 1 and _raw(kept[0]) == damaged, "saving the new game never touches the kept file")
	main.autosave_hour = -5
	main._process(0.01)
	check(_raw(kept[0]) == damaged, "nor does an autosave")
	# 2. a save from a newer version: kept, and the message names the versions
	_clear_saves()
	var newer := "{\"save_version\": %d, \"format\": \"mml-save/%d\"}" % [World.SAVE_VERSION + 1, World.SAVE_VERSION + 1]
	_put(TEST_SAVE, newer)
	main.continue_game()
	kept = _kept("newer")
	msg = ui.toast.text
	check(kept.size() == 1 and _raw(kept[0]) == newer and not FileAccess.file_exists(TEST_SAVE + ".tmp"), "a newer version's save is kept unchanged")
	check(msg.contains("newer version") and msg.contains("save version %d" % (World.SAVE_VERSION + 1)) and msg.contains(kept[0].get_file()) if not kept.is_empty() else false, "the message names the newer version: %s" % msg)
	main.save_game(false)
	check(_raw(kept[0]) == newer if not kept.is_empty() else false, "and the new game's save does not overwrite it")
	# 3. a damaged save with a good backup: the backup is loaded, the damaged file kept
	_clear_saves()
	main.new_game()
	main.world.player.coins = 111
	main.save_game(false)
	main.world.player.coins = 222
	main.save_game(false)                                # the 111-coin save is now the backup
	check(FileAccess.file_exists(TEST_SAVE + SaveStore.BAK), "a second save keeps the first as the backup")
	_put(TEST_SAVE, "\u0000\u0000 garbage")
	var garbage := _raw(TEST_SAVE)
	main.continue_game()
	kept = _kept("unreadable")
	msg = ui.toast.text
	check(main.world.player.coins == 111, "the backup is loaded (coins %d)" % main.world.player.coins)
	check(kept.size() == 1 and _raw(kept[0]) == garbage and msg.contains("backup") and msg.contains("loaded instead"), "the damaged file is kept and the message says the backup was loaded: %s" % msg)
	# 4. only a backup left (a crash between the two renames): Continue is offered and loads it
	_clear_saves()
	main.new_game()
	main.world.player.coins = 333
	main.save_game(false)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(TEST_SAVE), ProjectSettings.globalize_path(TEST_SAVE + SaveStore.BAK))
	check(main.can_continue(), "with only the backup left, the title still offers Continue")
	main.continue_game()
	check(main.world.player.coins == 333 and ui.toast.text.contains("backup"), "and Continue loads it, saying so")
	# 4b. DVW-A2: the save and its backup both damaged: an earlier day's dated backup is loaded
	_clear_saves()
	main.new_game()
	main.world.player.coins = 444
	SaveStore.today = "2026-10-01"
	main.save_game(false)
	main.save_game(false)                                # the 444-coin save is kept under 2026-10-01
	SaveStore.today = ""
	check(SaveStore.dated_backups(TEST_SAVE).size() == 1, "the game's save keeps a dated backup")
	_put(TEST_SAVE, "garbage")
	_put(TEST_SAVE + SaveStore.BAK, "garbage too")
	main.continue_game()
	check(main.world.player.coins == 444 and ui.toast.text.contains("2026-10-01") and ui.toast.text.contains("loaded instead"), "with save and backup damaged, the dated backup is loaded, saying which day: %s" % ui.toast.text)
	# 5. a failed write: the last save stays exactly as it was, and the player is told
	_clear_saves()
	main.new_game()
	main.save_game(false)
	var good := _raw(TEST_SAVE)
	main.world.player.coins = 999
	for step in ["open", "write", "verify", "backup", "replace"]:
		SaveStore.fail_at = step
		var saved: bool = main.save_game(true)
		check(not saved and _raw(TEST_SAVE) == good and not FileAccess.file_exists(TEST_SAVE + ".tmp"), "a save that fails at '%s' leaves the last save unchanged" % step)
		check(ui.toast.text.contains("Could not save") and ui.toast.text.contains("Your last save is unchanged"), "and says so: %s" % ui.toast.text)
	SaveStore.fail_at = ""
	check(main.save_game(false) and _raw(TEST_SAVE) != good, "the next save works again")
	# 6. a damaged save that cannot even be moved aside: saving stays off, the file untouched
	_clear_saves()
	_put(TEST_SAVE, damaged)
	SaveStore.fail_at = "preserve"
	main.continue_game()
	SaveStore.fail_at = ""
	msg = ui.toast.text
	check(main.save_blocked != "" and msg.contains("saving is off"), "if it cannot be moved aside, saving is turned off and the player is told: %s" % msg)
	check(not main.save_game(false) and _raw(TEST_SAVE) == damaged, "and nothing writes over it")
	main.save_blocked = ""
	# 7. a new character over an existing game keeps the old game as save1.previous.json
	_clear_saves()
	main.new_game()
	main.world.player.coins = 444
	main.save_game(false)
	var old := _raw(TEST_SAVE)
	var looks: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/appearances.json")).looks
	main.new_game({"name": "Ada", "family": "Test", "sex": looks[0].sex, "look": looks[0].id, "sprite": looks[0].sprite})
	var prev: String = TEST_SAVE.get_basename() + main.PREVIOUS_SUFFIX
	check(_raw(prev) == old, "starting a new character keeps the previous game, unchanged, as %s" % prev.get_file())
	main.resume_after_origin()
	check(_raw(prev) == old and main.world.player.name == "Ada", "the new game's first save leaves it alone")
	ui.hide_all()


## Hold a direction for `secs` of player steps (keys or the stick).
func _hold(action: String, secs: float) -> void:
	Input.action_press(action)
	for i in int(secs / 0.05):
		main._player_step(0.05)
	Input.action_release(action)


## Nobody gets trapped (Build 8 reports: just inside a door; between trees): the player slides into
## a doorway they are not lined up with, can always walk out of something solid that appeared under
## them, and a tree never grows back under someone's feet.
func _collision_tests() -> void:
	main.new_game()
	var w: World = main.world
	var p := w.player
	main.ui.hide_all()
	# the tavern's one-tile exit, the player 0.45 of a tile off line: holding down walks out of it
	var tav: Dictionary = main.map.data.buildings.filter(func(b): return b.type == "tavern")[0]
	var exit := Vector2i(int(tav.door[0]), int(tav.door[1]))
	check(not main.map.is_solid(exit) and main.map.is_solid(exit + Vector2i(-1, 0)) and main.map.is_solid(exit + Vector2i(1, 0)), "the tavern's exit is one tile wide")
	p.pos = Vector2(exit.x + 0.05, exit.y - 0.5)
	check(main._blocked_corners(p.pos) == 0, "the player stands just inside, off line with the doorway")
	_hold("move_down", 2.0)
	check(p.pos.y > exit.y + 1.0, "holding down slides into the doorway and out (at %s)" % p.pos)
	_hold("move_up", 2.0)
	check(p.pos.y < exit.y - 0.3, "and back in")
	# something solid appears under the player: walking still gets them out
	var spot := Vector2i(exit.x, exit.y + 4)
	p.pos = Vector2(spot) + Vector2(0.5, 0.5)
	main.map.set_solid(spot, true)
	check(main._blocked_corners(p.pos) == 4, "the cell under the player is now blocked")
	_hold("move_right", 1.0)
	check(main._blocked_corners(p.pos) == 0 and p.pos.x > spot.x + 1.2, "the player walks out of it (at %s)" % p.pos)
	main.map.set_solid(spot, false)
	# a young tree does not grow solid under the player; it does once they step away
	var t: Dictionary = w.trees.filter(func(t): return t.state == "grown")[0]
	var tc := Vector2i(int(t.x), int(t.y))
	w.fell(t, 0)
	t.state = "young"
	t.born = w.minutes - Trees.stage_minutes("sapling") - Trees.stage_minutes("young") - 1.0
	main.map.set_solid(tc, false)
	p.pos = Vector2(tc) + Vector2(0.5, 0.5)
	w._grow_trees()
	check(t.state == "young" and not main.map.is_solid(tc), "a young tree under the player's feet waits")
	p.pos = Vector2(tc) + Vector2(4.5, 0.5)
	w._grow_trees()
	check(t.state == "growing" and main.map.is_solid(tc), "and grows solid once they step away")


## A blow that lands shows (Build 8 report: attacking a cow showed nothing): health drops, the
## target flashes, and a health bar over it shows what is left.
func _hit_feedback_tests() -> void:
	var near_a: Animal = main.world.fauna.animals.filter(func(x): return x.alive)[0]
	main.world.player.pos = near_a.pos + Vector2(1, 0)
	main.recenter()
	main._sync_sprites()
	var drawn: Array = main.world.fauna.animals.filter(func(x): return x.alive and main.animal_sprites.has(x.id))
	check(not drawn.is_empty(), "an animal is on screen")
	if drawn.is_empty():
		return
	var a: Animal = drawn[0]
	var hp0 := a.hp
	main._hit_animal(a, 1.0)
	var s: Node2D = main.animal_sprites.get(a.id)
	var bar: Node2D = s.get_node_or_null("HpBar") if s else null
	check(a.hp == hp0 - 1.0, "the blow takes 1 health (%.1f -> %.1f)" % [hp0, a.hp])
	check(bar != null and bar.visible and (bar.get_node("Fill") as ColorRect).size.x < 16.0, "a health bar over the animal shows the loss")
	check(s != null and s.modulate != Color.WHITE, "the animal flashes")


## The roof of the building the player is in stays lifted everywhere inside its outline, also on
## cells its interior list missed (Build 8 report: roofs flicker while inside).
func _roof_tests() -> void:
	var w: World = main.world
	var tav: Dictionary = main.map.data.buildings.filter(func(b): return b.type == "tavern")[0]
	var area := {}
	for c in tav.interior.area:
		area[Vector2i(int(c[0]), int(c[1]))] = true
	var a0: Vector2i = area.keys().filter(func(c): return not main.map.is_solid(c))[0]
	var gap := Vector2i(-1, -1)
	for y in range(int(tav.y), int(tav.y) + int(tav.h) - 1):
		for x in range(int(tav.x), int(tav.x) + int(tav.w)):
			var c := Vector2i(x, y)
			if gap.x < 0 and not area.has(c) and not main.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == "":
				gap = c
	w.player.pos = Vector2(a0) + Vector2(0.5, 0.5)
	for i in 20:
		main._sync_sprites()
	check(main.roofs.is_open(tav.id), "inside the tavern its roof is lifted")
	check(gap.x >= 0, "the tavern has a walkable cell its interior list missed (%s)" % gap)
	if gap.x >= 0:
		w.player.pos = Vector2(gap) + Vector2(0.5, 0.5)
		var steady := true
		for i in 30:
			main._sync_sprites()
			steady = steady and main.roofs.is_open(tav.id)
		check(steady, "on that cell the roof stays lifted, no flicker")


## LT / RT step through every enabled button of an open window and wrap round (Build 8 report:
## the pad should reach every active button).
func _pad_cycle_tests() -> void:
	var ui = main.ui
	ui.show_talk(main.world.npcs.filter(func(n): return n.alive and n.role != "bandit")[0])
	ui._focus_first()
	var all: Array = ui.panel.find_children("*", "Control", true, false).filter(func(c): return (c is BaseButton or c is LineEdit or c is Slider) \
		and c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE and not (c is BaseButton and c.disabled))
	var seen := {}
	var start: Control = main.get_viewport().gui_get_focus_owner()
	for i in all.size() + 1:
		seen[main.get_viewport().gui_get_focus_owner()] = true
		for v in [1.0, 0.0]:
			var ev := InputEventJoypadMotion.new()
			ev.axis = JOY_AXIS_TRIGGER_RIGHT
			ev.axis_value = v
			main._unhandled_input(ev)
	check(all.size() > 1 and all.all(func(c): return seen.has(c)), "RT reaches every enabled control of the talk window (%d)" % all.size())
	check(main.get_viewport().gui_get_focus_owner() == all[(all.find(start) + 1) % all.size()], "and wraps round")
	ui.hide_all()


## A sign with the family's name by a house's door when the player is near (Build 8 request).
func _sign_tests() -> void:
	var w: World = main.world
	var hid := ""
	for id in w.buildings:
		if str(w.buildings[id].type) == "house" and w.home_family(str(id)) != "":
			hid = str(id)
			break
	var b: Dictionary = w.buildings[hid]
	w.player.pos = Vector2(float(b.door[0]) + 0.5, float(b.door[1]) + 2.5)
	main._sync_sprites()
	var sg: Label = main.house_signs.get(hid)
	check(sg != null and sg.visible and sg.text == w.home_family(hid), "by %s's door a sign reads %s" % [hid, sg.text if sg else "nothing"])
	w.player.pos = Vector2(float(b.door[0]), float(b.door[1])) + Vector2(40, 0)
	main._sync_sprites()
	check(not sg.visible, "far away the sign is not shown")


## Children are drawn at half size, adults at full size (owner, 2026-10-18).
func _child_size_tests() -> void:
	var w: World = main.world
	var kid: NPC = w.npcs.filter(func(n): return n.alive and n.role == "child")[0]
	var adult: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult")[0]
	w.player.pos = kid.pos + Vector2(1, 0)
	main.recenter()
	main._sync_sprites()
	check(is_equal_approx(main.sprites[kid.id].scale.x, 0.5), "a child is drawn at half size")
	var kid_born := kid.born
	kid.born = w.minutes - 20.0 * Life.year_minutes()      # B8-029: size follows age (adolescents 0.75), not the role
	kid.role = "adult"
	main._sync_sprites()
	check(is_equal_approx(main.sprites[kid.id].scale.x, 1.0), "grown up, full size")
	kid.born = w.minutes - 14.0 * Life.year_minutes()
	main._sync_sprites()
	check(is_equal_approx(main.sprites[kid.id].scale.x, 0.75), "an adolescent is drawn at three quarters")
	kid.born = kid_born
	kid.role = "child"
	w.player.pos = adult.pos + Vector2(1, 0)
	main.recenter()
	main._sync_sprites()
	check(is_equal_approx(main.sprites[adult.id].scale.x, 1.0), "an adult is full size")


## Young animals are drawn at half size until grown, then full size (owner, 2026-10-18); B8-029: a species with
## baby art (every one but the boar) draws the baby sheet at full scale instead.
func _animal_size_tests() -> void:
	var w: World = main.world
	var a: Animal = w.fauna.animals.filter(func(x): return x.alive)[0]
	var pos0 := a.pos
	a.pos = main.camera.get_screen_center_position() / main.T      # in view
	var born0 := a.born
	a.born = w.minutes                                 # just born
	main._sync_animals()
	var s: Node2D = main.animal_sprites.get(a.id)
	var has_baby: bool = a.baby_skin() != ""
	check(s != null and is_equal_approx(s.scale.x, 1.0 if has_baby else 0.5) and s.baby == has_baby, "a young animal draws its baby sheet at full size, or half size with no baby art (%s)" % a.species)
	a.born = w.minutes - 1440.0 * (Animal.stage_days(a.spec(), "grow") + 1.0)   # grown
	main._sync_animals()
	check(s != null and is_equal_approx(s.scale.x, 1.0) and not s.baby, "grown, full size on the adult sheet")
	var boar := w.fauna.spawn("woods_w", "boar", "f", null)
	boar.pos = main.camera.get_screen_center_position() / main.T
	main._sync_animals()
	check(is_equal_approx(main.animal_sprites[boar.id].scale.x, 0.5), "a newborn boar (no baby art) is drawn at half size")
	w.fauna.remove(boar)
	a.born = born0
	a.pos = pos0


## Build 8 interface fixes: gain icons, compact prompt, HUD meters, death cause, inventory highlights.
func _b8_ui_tests() -> void:
	var ui: GameUI = main.ui
	var w: World = main.world
	var p := w.player
	ui.hide_all()
	# B8-009: a gain with an item id shows that item's icon beside the words
	for c in ui.log_box.get_children():
		c.free()
	ui.gain("+1 Iron ore", "iron_ore")
	var line: Node = ui.log_box.get_child(ui.log_box.get_child_count() - 1)
	var icon: TextureRect = line.find_child("ItemIcon", true, false)
	check(icon != null and icon.texture == load("res://assets/icons/iron_ore.png") and icon.custom_minimum_size.x <= 24.0
		and ui.log_texts().has("+1 Iron ore"), "a gain with an item id shows the item's icon and words in one compact line")
	ui.gain("Plain note")
	check(ui.log_texts().has("Plain note") and ui.log_box.get_child(ui.log_box.get_child_count() - 1) is Label, "a gain without an item is still a plain line")
	ui.gain("+1 Mystery", "no_such_item")
	check(ui.log_texts().has("+1 Mystery"), "an unknown item id falls back to the plain line")
	# B8-013: the contextual prompt and the toast fit their words
	ui.prompt("Fell this tree")
	await process_frame
	await process_frame
	check(ui.prompt_box.size.x < GameUI.PROMPT_MAX_W - 20.0 and ui.prompt_label.get_theme_font_size("font_size") <= 16,
		"a short prompt is a compact box (%d px wide, was 480+)" % ui.prompt_box.size.x)
	ui.prompt("An unusually long prompt that goes on and on about what the use button will do here and why one should care about it at all")
	await process_frame
	await process_frame
	check(ui.prompt_box.size.x <= GameUI.PROMPT_MAX_W + 80.0, "a long prompt wraps at a limit (%d px)" % ui.prompt_box.size.x)
	ui.prompt("")
	ui.message("A short hint.")
	await process_frame
	await process_frame
	check(ui.toast.size.x < 300.0 and ui.toast.size.y < 80.0, "a short message is a small toast (%s)" % ui.toast.size)
	ui.message("Gather: tap a seam, a tree, a ripe field, a flower, a berry bush or game; you gather it until it runs out. Tap Gather again to stop.")
	await process_frame
	await process_frame
	check(ui.toast.size.x <= GameUI.TOAST_MAX_W + 1.0 and ui.toast.size.y < 140.0, "a long message wraps at %d px (%s)" % [GameUI.TOAST_MAX_W, ui.toast.size])
	ui.toast_t = 0.01
	# B8-019: every meter has words, and a low one switches to its danger state
	var hp0 := p.hp
	var hunger0 := p.hunger
	var stamina0 := p.stamina
	p.hp = p.hp_cap()
	p.hunger = 80.0
	p.stamina = p.stamina_cap()
	ui.update_hud()
	check(ui.bar_labels.hp.text == "%d/%d" % [int(p.hp_cap()), int(p.hp_cap())] and ui.bar_labels.hunger.text == "80/100" and ui.bar_labels.stamina.text == "%d/%d" % [int(p.stamina_cap()), int(p.stamina_cap())],
		"the meters are labelled: %s / %s / %s" % [ui.bar_labels.hp.text, ui.bar_labels.hunger.text, ui.bar_labels.stamina.text])
	check(not ui.bar_danger.hunger and not ui.bar_danger.hp and not ui.bar_danger.stamina, "full meters are not in danger")
	p.hunger = 10.0
	p.hp = p.hp_cap() * 0.1
	p.stamina = 5.0
	ui.update_hud()
	check(ui.bar_danger.hunger and ui.bar_danger.hp and ui.bar_danger.stamina and (ui.bars.hunger.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == GameUI.DANGER_COLOUR,
		"low meters turn to the danger state (red)")
	check(ui.bars.hunger.tooltip_text.contains("starve") and ui.bars.stamina.tooltip_text.contains("Fireball"), "the meters' tooltips say why they change")
	p.hp = hp0
	p.hunger = hunger0
	p.stamina = stamina0
	ui.update_hud()
	# B8-012: highlights fit their slots (tabs, gear slots and bag cells all use a bag-cell sized box)
	ui.show_inventory()
	var iw: InventoryWindow = ui.inventory_window()
	iw._layout()
	var cell_px := InventoryWindow.CELL * iw.k
	var ok := true
	for i in iw.tab_buttons.size():
		var r := iw._r(iw.tab_focus_rect(i))
		ok = ok and is_equal_approx(r.size.x, cell_px.x) and is_equal_approx(r.size.y, cell_px.y)
		var icon_r := iw._r(Rect2(InventoryWindow.TAB_X + InventoryWindow.TAB_STEP * i, 10 if iw.TABS[i][0] == iw.tab else 15, 16, 16))
		ok = ok and r.encloses(icon_r)
	check(ok, "a tab's focus box is a bag-cell sized box round its icon")
	var same := true
	for slot in iw.gear_buttons:
		var b: Button = iw.gear_buttons[slot]
		same = same and b.get_rect().is_equal_approx(iw._r(Rect2(InventoryWindow.GEAR_AT[slot], InventoryWindow.CELL)))
	for i in iw.cells.size():
		same = same and iw.cells[i].get_rect().is_equal_approx(iw._r(Rect2(InventoryWindow.CELL0 + InventoryWindow.CELL_STEP * Vector2(i % InventoryWindow.COLS, i / InventoryWindow.COLS), InventoryWindow.CELL)))
	check(same, "gear slot and bag cell buttons are exactly their slots (k %.2f, cell %s, gear %s)" % [iw.k, iw.cells[0].get_rect(), iw.gear_buttons.weapon.get_rect()])
	check(iw.tab_buttons[0].get_theme_stylebox("focus") is StyleBoxEmpty, "tab buttons draw no oversized focus ring of their own")
	ui.hide_all()
	# B8-020: the death screen names the cause
	p.hp = 5.0
	w.damage_player(100.0, "hunger")
	check(not p.alive and p.death_cause == "hunger", "starvation is recorded as the cause of death")
	ui.show_death()
	var cl: Label = ui.panel_body.find_child("DeathCause", true, false)
	check(cl != null and cl.text == "You starved.", "the death screen says \"You starved.\"")
	var saved := PlayerState.from_dict(p.to_dict())
	check(saved.death_cause == "hunger" and saved.last_damage == "hunger", "the cause survives a save and load")
	ui.hide_all()
	p.alive = true
	p.deaths -= 1
	p.hp = hp0
	p.hp = 5.0
	w.damage_player(100.0, "Wat the guard")
	check(not p.alive and p.death_cause == "Wat the guard", "a combat kill records who struck")
	ui.show_death()
	cl = ui.panel_body.find_child("DeathCause", true, false)
	check(cl != null and cl.text == "Killed by Wat the guard.", "the death screen says who killed you")
	ui.hide_all()
	p.alive = true
	p.deaths -= 1
	p.hp = hp0
	p.death_cause = ""
	p.last_damage = ""


# ---------------------------------------------------------------- Build 8 actions ---------------
func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


## LT pulled all the way (a trigger is an axis, not a button); `down` false lets it go.
func _lt(down := true) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_TRIGGER_LEFT
	e.axis_value = 1.0 if down else 0.0
	return e


func _pad(button: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = true
	return e


## A seam with `amount` left, the player beside it facing it, a pickaxe in the pack.
func _at_seam(amount := 8) -> Dictionary:
	var w: World = main.world
	var d := w.nearest_deposit(Vector2i(w.player.pos), ["iron_ore", "stone", "coal"])
	d.amount = amount
	stand_by(Vector2i(d.x, d.y))
	return d


func _last_gain() -> Array:
	return main.gain_log[-1] if not main.gain_log.is_empty() else ["", ""]


## B8-006 .. 014, 027: one Use is one cycle and the swing ends; B, Esc, right-click and a tap cancel
## with nothing awarded; the Pack opens mid-work; a person by a station does not hide it; sprint.
func _actions_tests() -> void:     # a coroutine: a few steps wait for the next frame
	main.new_game()
	var w: World = main.world
	var p := w.player
	var ui = main.ui
	ui.hide_all()
	if main.gather_mode:
		main.gather_button()
	p.inv.add("axe", 1)
	var pick := p.tool_of("pickaxe")
	check(pick != "", "(actions) the player has a pickaxe")

	# B8-006 / B8-007: one Use = one cycle; the pickaxe is in hand for it; then idle
	var d := _at_seam()
	check(main.target.get("kind", "") == "deposit", "(actions) standing at a seam offers it")
	var ore: String = d.ore
	var ore0 := p.inv.count(ore)
	main.gain_log.clear()
	main.interact()
	check(not main.action.is_empty() and main.player_sprite.anim == "swing" and main.player_sprite.tool_item == pick,
			"mining starts the swing animation with the pickaxe (%s) in hand, not a sword or staff" % pick)
	finish_action()
	var mined := p.inv.count(ore) - ore0
	check(mined >= 1 and int(d.amount) == 8 - mined, "one Use mined one cycle (%d %s), the seam keeps the rest (%d)" % [mined, ore, int(d.amount)])
	check(main.action.is_empty() and main.player_sprite.anim == "idle" and main.player_sprite.tool_item == "", "the swing stops: the player is back to idle with the tool put away")
	check(_last_gain() == [ore, "+%d %s" % [mined, GameData.item_name(ore)]], "the notice goes through gain with the item id: %s" % [_last_gain()])
	run_frames(40, 0.05)
	check(main.action.is_empty() and p.inv.count(ore) == ore0 + mined and main.player_sprite.anim == "idle", "nothing repeats on its own: no second cycle, still idle")

	# B8-006: a felling is one Use; the axe is in hand; idle after the tree falls
	var tree := {}
	for tr in w.trees:
		if tr.state == "grown":
			tree = tr
			break
	stand_by(Vector2i(int(tree.x), int(tree.y)))
	var logs0 := p.inv.count("log")
	main.gain_log.clear()
	main.interact()
	check(main.player_sprite.anim == "swing" and main.player_sprite.tool_item == p.tool_of("axe"), "chopping holds the axe (%s)" % main.player_sprite.tool_item)
	finish_action()
	check(p.inv.count("log") > logs0 and main.action.is_empty() and main.player_sprite.anim == "idle", "the tree falls, logs are collected and the swing stops")
	check(main.gain_log.any(func(g): return g[0] == "log" and g[1] == "+%d %s" % [p.inv.count("log") - logs0, GameData.item_name("log")]), "the logs notice carries the item id: %s" % [main.gain_log])

	# harvesting: the arms-forward gathering animation, ended, with the item id
	var ripe := {}
	for f in w.fields:
		w.set_field(f, "ripe")
		f.crop = int(GameData.b("field_yield"))
		ripe = f
		break
	p.pos = Vector2(int(ripe.x), int(ripe.y)) + Vector2(0.5, 1.5)
	main.player_sprite.face(Vector2(0, -1))
	main._find_target()
	main.gain_log.clear()
	if main.target.get("kind", "") == "field":
		main.interact()
		check(main.player_sprite.anim == "gather", "harvesting plays the gathering animation")
		finish_action()
		check(main.player_sprite.anim == "idle" and _last_gain()[0] == "wheat", "harvest ends in idle, with the wheat's id in the notice: %s" % [_last_gain()])

	# B8-011: B, Esc, right-click and a tap cancel at once, nothing awarded, movement is back
	for how in ["B", "Esc", "right-click", "tap"]:
		d = _at_seam()
		ore0 = p.inv.count(ore)
		var amount0 := int(d.amount)
		main.gain_log.clear()
		main.interact()
		run_frames(3, 0.05)
		check(not main.action.is_empty(), "(%s) mining is under way" % how)
		match how:
			"B":
				main._unhandled_input(_pad(JOY_BUTTON_B))
			"Esc":
				main._unhandled_input(_key(KEY_ESCAPE))
			"right-click":
				var m := InputEventMouseButton.new()
				m.button_index = MOUSE_BUTTON_RIGHT
				m.pressed = true
				main._unhandled_input(m)
			"tap":
				tap_at(p.pos + Vector2(2, 0))
		check(main.action.is_empty() and main.player_sprite.anim == "idle" and not ui.modal() and not main.paused, "(%s) cancels: the animation stops and no window opened" % how)
		run_frames(40, 0.05)
		check(p.inv.count(ore) == ore0 and int(d.amount) == amount0 and main.gain_log.is_empty(), "(%s) nothing awarded: the seam and the pack are as they were" % how)
		var x0 := p.pos
		Input.action_press("move_down")
		run_frames(6, 0.05)
		Input.action_release("move_down")
		check(p.pos != x0 and main.player_sprite.anim == "walk", "(%s) movement is back" % how)
		run_frames(2, 0.05)
	# Esc with nothing to cancel is still the pause menu
	main._unhandled_input(_key(KEY_ESCAPE))
	check(ui.modal(), "Esc with no work under way still opens the menu")
	ui.hide_all()

	# Gather mode: B stops the continuous gathering too, and Gather mode stays on
	d = _at_seam(5)
	main.gather_button()
	var hit := ResourceNodes.node_at(w, Vector2i(int(d.x), int(d.y)), true)
	main.select_resource(hit, true)
	run_frames(10, 0.05)
	main._unhandled_input(_pad(JOY_BUTTON_B))
	check(main.gather.is_empty() and main.action.is_empty() and main.gather_mode and main.player_sprite.anim in ["idle", "walk"], "B stops Gather mode's continuous gathering; Gather mode stays on")
	main.gather_button()

	# B8-010: the Pack opens mid-action: the work stops, nothing is awarded, controls work after closing
	d = _at_seam()
	ore0 = p.inv.count(ore)
	var amt0 := int(d.amount)
	main.interact()
	run_frames(3, 0.05)
	Input.action_press("inventory")
	run_frames(1, 0.05)
	Input.action_release("inventory")
	await process_frame          # the press is over for the next frame (a press counts as "just pressed" for the whole frame)
	check(ui.is_open("inventory") and main.action.is_empty() and main.player_sprite.anim == "idle", "the Pack opens while mining and the work is stopped")
	run_frames(60, 0.05)
	main._process(0.05)
	check(p.inv.count(ore) == ore0 and int(d.amount) == amt0, "nothing was awarded, and nothing is collected twice while the Pack is open")
	ui.hide_all()
	check(not main.paused and not ui.modal(), "closing the Pack gives the game back")
	run_frames(40, 0.05)
	check(p.inv.count(ore) == ore0 and main.action.is_empty(), "closing it does not resume or repeat the work")
	d = _at_seam()
	ore = d.ore
	ore0 = p.inv.count(ore)
	main.interact()
	finish_action()
	check(p.inv.count(ore) > ore0 and main.player_sprite.anim == "idle", "Use works again after the Pack: one fresh cycle collected")
	# a window opened by other means (a touch button) mid-action stops it the same way
	_at_seam()
	main.interact()
	run_frames(2, 0.05)
	ui.show_skills()
	main._process(0.05)
	check(main.action.is_empty(), "any window that opens mid-action stops it")
	ui.hide_all()

	# B8-014: a person by a station: both are offered and the station can be used
	var st_id := ""
	for id in w.stations:
		if w.stations[id].type in ["forge", "anvil", "workbench", "sawhorse", "stove", "oven"]:
			st_id = id
			break
	var st: Dictionary = w.stations[st_id]
	p.pos = Vector2(int(st.use[0]) + 0.5, int(st.use[1]) + 0.5)
	main.player_sprite.face(Vector2(0, 1))
	var bystander: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult")[0]
	bystander.anim = "idle"
	bystander.pos = p.pos + main.facing_vec() * 0.9
	main._find_target()
	var kinds: Array = main.target_options.map(func(t): return str(t.kind))
	check(kinds.has("station") and (kinds.has("npc") or kinds.has("shop")), "(station + person) both are offered: %s" % [kinds])
	check(ui.prompt_text.contains("\n") and ui.prompt_text.contains("next"), "the prompt names the next choice on a second line: \"%s\"" % ui.prompt_text.replace("\n", " | "))
	var first: String = main.target.kind
	main._unhandled_input(_key(KEY_Q))
	check(main.target.kind != first, "Q chooses the other one (%s -> %s)" % [first, main.target.kind])
	main._player_step(0.016)
	check(main.target.kind != first, "the choice holds from frame to frame")
	main._unhandled_input(_pad(JOY_BUTTON_DPAD_LEFT))
	check(main.target.kind == first, "the D-pad goes back")
	main._unhandled_input(_key(KEY_TAB))
	check(main.target.kind != first and main.tab_cycled == Engine.get_process_frames(), "Tab chooses the next one and does not open the Pack with it")
	if main.target.kind != "station":
		main.cycle_target(1)
	check(main.target.kind == "station", "the station can be chosen")
	main.interact()
	check(ui.is_open("craft"), "and used (A / E): its window opens with the person standing beside it")
	ui.hide_all()
	bystander.pos = p.pos + Vector2(20, 0)
	main._find_target()
	check(not main.target_options.any(func(t): return t.kind == "npc") and main.target_options.any(func(t): return t.kind == "station"), "with the person gone the station is still offered, and they are not")
	# a villager at the seam the player faces (owner, Build 13 playtest): A mines it, Y (pad) or T (keys) talks
	var seam := _at_seam()
	main.target_pref = ""
	bystander.anim = "idle"
	bystander.plan.clear()
	bystander.pos = p.pos + main.facing_vec() * 0.9
	main._find_target()
	check(main.target.get("kind", "") == "deposit" and main.talk_alt.get("npc") == bystander, "with a villager at the seam, A is the seam and the villager is offered to talk (%s)" % main.target.get("kind", ""))
	main.scheme = "gamepad"
	ui.set_scheme("gamepad")
	main._find_target()
	check(ui.prompt_text.contains("Y: Talk to") or ui.prompt_text.contains("Y: Trade with"), "the prompt shows Y to talk: \"%s\"" % ui.prompt_text.replace("\n", " | "))
	var spells_before: Dictionary = p.spells.duplicate()
	p.spells["fireball"] = true
	Input.action_press("fireball")
	main._player_step(0.016)
	Input.action_release("fireball")
	check(ui.is_open("talk") or ui.is_open("trade"), "Y talks to the villager instead of casting")
	p.spells = spells_before
	ui.hide_all()
	main.scheme = "kbm"
	ui.set_scheme("kbm")
	main._find_target()
	check(ui.prompt_text.contains("T: "), "on a keyboard the prompt says T")
	Input.action_press("talk")
	main._player_step(0.016)
	Input.action_release("talk")
	check(ui.is_open("talk") or ui.is_open("trade"), "T talks to them")
	ui.hide_all()
	main._find_target()
	var seam_left := int(seam.amount)
	main.interact()
	finish_action()
	check(int(seam.amount) < seam_left, "and A / E still mines the seam with the villager beside it")
	bystander.pos = p.pos + Vector2(20, 0)
	main._find_target()
	check(main.talk_alt.is_empty(), "with nobody beside it, no talk is offered")

	# B8-027: sprint
	var open := _open_stretch()
	var walk_step := _step_x(open, false)
	var sprint_step := _step_x(open, true)
	check(walk_step > 0.0 and absf(sprint_step / walk_step - float(GameData.b("sprint_speed"))) < 0.05, "Shift held sprints at %.2fx the walking speed (%.3f vs %.3f tiles a step)" % [sprint_step / walk_step, sprint_step, walk_step])
	check(main.player_sprite.speed_scale == float(GameData.b("sprint_speed")), "the walking animation runs faster while sprinting")
	main.sprinting = false
	p.stamina = 100.0
	Input.action_press("sprint")
	Input.action_press("move_right")
	var st0 := p.stamina
	for i in 20:
		p.pos = open
		w.update(0.05)
		main._player_step(0.05)
	check(absf((st0 - p.stamina) - float(GameData.b("sprint_stamina_per_sec")) * 1.0) < 1.5, "a second of sprinting costs about sprint_stamina_per_sec (%.1f)" % (st0 - p.stamina))
	var guard := 0
	while main.sprinting and guard < 400:
		p.pos = open
		w.update(0.05)
		main._player_step(0.05)
		guard += 1
	check(not main.sprinting and p.stamina < float(GameData.b("sprint_min_stamina")), "sprint ends when stamina runs out (%.1f left)" % p.stamina)
	p.pos = open
	main._player_step(0.05)
	check(absf((p.pos.x - open.x) / 0.05 - float(GameData.b("player_tiles_per_second"))) < 0.3 and not main.sprinting, "and the player is back to the walking speed, though Shift is still held")
	Input.action_release("sprint")
	Input.action_release("move_right")
	await process_frame
	main._player_step(0.05)
	# LT toggles on a pad; L3 no longer does anything for sprint
	p.stamina = 100.0
	main._unhandled_input(_pad(JOY_BUTTON_LEFT_STICK))
	check(not main.sprinting, "L3 does not sprint any more")
	main._unhandled_input(_lt())
	main._unhandled_input(_lt(false))
	check(main.sprinting, "LT turns sprint on with one press")
	Input.action_press("move_right")
	p.pos = open
	main._player_step(0.05)
	check(main.sprinting and absf((p.pos.x - open.x) - walk_step * float(GameData.b("sprint_speed"))) < 0.02, "LT sprint keeps going without holding the trigger")
	Input.action_release("move_right")
	main.sprinting = true
	main._unhandled_input(_lt())
	check(not main.sprinting, "LT again turns it off")
	main._unhandled_input(_lt())
	check(not main.sprinting, "holding LT down is one press, not a toggle every frame")
	main._unhandled_input(_lt(false))
	# the keyboard toggle option
	GameData.balance["sprint_toggle"] = true
	main._unhandled_input(_key(KEY_SHIFT))
	check(main.sprinting, "with sprint_toggle, Shift toggles sprint on")
	main._unhandled_input(_key(KEY_SHIFT))
	check(not main.sprinting, "and off")
	GameData.balance["sprint_toggle"] = false
	# never during work or attacks
	main.sprinting = false
	_at_seam()
	main.interact()
	main.toggle_sprint()
	main._unhandled_input(_lt())
	main._unhandled_input(_lt(false))
	main._player_step(0.05)
	check(not main.sprinting, "no sprint while harvesting")
	finish_action()
	p.stamina = 100.0
	main.sprinting = true
	p.attack_cd = 0.0
	main.attack()
	check(not main.sprinting, "no sprint while attacking")
	main.swing.cancel()
	main.player_sprite.play("idle")
	# touch: a Run button on the touch bar latches sprint (Build 13), same speed and cost as LT and Shift
	ui.set_scheme("touch")
	await process_frame
	var run_btn: Button = ui.sprint_btn
	check(run_btn != null and ui.touch_bar.visible and run_btn.get_parent() == ui.touch_bar and run_btn.text == "Run", "the touch bar has a Run button")
	main.sprinting = false
	main.sprint_latched = false
	p.stamina = 100.0
	run_btn.pressed.emit()
	check(main.sprint_latched and run_btn.text == "Run ON", "Run lights up when pressed")
	main._player_step(0.05)
	check(main.sprint_latched, "standing still keeps Run on, ready for the next walk")
	Input.action_press("move_right")
	p.pos = open
	var run_st0 := p.stamina
	main._player_step(0.05)
	check(main.sprinting and absf((p.pos.x - open.x) - walk_step * float(GameData.b("sprint_speed"))) < 0.02 and p.stamina < run_st0, "walking with Run on runs at the sprint speed and spends stamina")
	Input.action_release("move_right")
	run_btn.pressed.emit()
	check(not main.sprint_latched and not main.sprinting and run_btn.text == "Run", "Run pressed again turns it off")
	p.stamina = float(GameData.b("sprint_min_stamina")) - 1.0
	run_btn.pressed.emit()
	check(not main.sprint_latched and run_btn.text == "Run", "Run cannot start without the stamina for it")
	p.stamina = float(GameData.b("sprint_min_stamina")) + 0.5
	run_btn.pressed.emit()
	Input.action_press("move_right")
	for i in 40:
		p.pos = open
		main._player_step(0.05)
	Input.action_release("move_right")
	check(not main.sprint_latched and not main.sprinting and run_btn.text == "Run", "out of stamina, Run goes off by itself")
	# the touch bar with Run fits the screen and overlaps nothing, at a 16:9, a 20:9 phone and a 4:3 shape
	var size0 := get_root().content_scale_size
	for sz in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(960, 720)]:
		get_root().content_scale_size = sz
		ui.fit_safe_area()
		await process_frame
		await process_frame
		var view: Rect2 = main.get_viewport().get_visible_rect()
		var bar: Rect2 = ui.touch_bar.get_global_rect()
		var clash := []
		for c in [ui.status_box, ui.log_box]:
			if c.visible and c.get_global_rect().intersects(bar):
				clash.append(c.name)
		check(view.encloses(bar) and clash.is_empty() and run_btn.get_global_rect().size.x >= 64.0, "at %s the touch bar with Run is on screen and clear of the HUD (%s, clash %s)" % [sz, bar, clash])
	get_root().content_scale_size = size0
	ui.fit_safe_area()
	ui.set_scheme("kbm")


## Six free cells in a row to the east, for the sprint measurements: the first one's centre.
func _open_stretch() -> Vector2:
	var m: VillageMap = main.world.map
	var best := Vector2.ZERO
	var bd := INF
	var mid := Vector2(m.w, m.h) / 2.0
	for y in range(8, m.h - 8):
		for x in range(8, m.w - 12):
			if range(6).all(func(i): return not m.is_solid(Vector2i(x + i, y)) and not m.is_solid(Vector2i(x + i, y + 1)) and not m.is_solid(Vector2i(x + i, y - 1))):
				var c := Vector2(x, y) + Vector2(0.5, 0.5)
				if c.distance_to(mid) < bd:
					bd = c.distance_to(mid)
					best = c
	return best


## How far one 0.05 s step east takes the player, with Shift held or not.
func _step_x(at: Vector2, sprint: bool) -> float:
	var p: PlayerState = main.world.player
	main.sprinting = false
	p.stamina = 100.0
	p.pos = at
	if sprint:
		Input.action_press("sprint")
	Input.action_press("move_right")
	main._player_step(0.05)
	Input.action_release("move_right")
	Input.action_release("sprint")
	var dx: float = p.pos.x - at.x
	main.sprinting = false
	return dx


## PL1-03, PL2-012, PL1-05, PL1-08, PL2-003: the quantity control, storage focus, bar numbers,
## consumable effect text and dialogue sentences.
func _pl_trade_ui_tests() -> void:
	var ui = main.ui
	var w: World = main.world
	var p := w.player
	ui.set_scheme("kbm")
	# -- the limits: each unit has its own price (Build 13), units count while the coins last
	check(QuantityPicker.buy_max_priced([2, 2, 3, 3, 4], 9) == 3 and QuantityPicker.buy_max_priced([2, 2, 3], 100) == 3, "buy max counts units while the coins cover them, up to the stock")
	check(QuantityPicker.buy_max_priced([5], 4) == 0 and QuantityPicker.buy_max_priced([1, 1], 9, false) == 0, "and is 0 without the coins for one or room in the pack")
	check(QuantityPicker.sell_max_priced([10, 10, 9, 9], 29) == 3 and QuantityPicker.sell_max_priced([], 100) == 0, "sell max stops where the buyer's own coins run out")
	# -- prices follow supply: a seller's price rises as stock runs down, a buyer's falls as they fill up
	var goods: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "merchant" and w.brain.buy_role(n) == "merchant_goods")[0]
	goods.inv.items.erase("iron_sword")
	goods.inv.add("iron_sword", 3)
	var up: Array = w.player_quote(goods, "iron_sword", 3, true)
	check(up[0] < up[1] and up[1] < up[2], "buying swords one by one, each costs more as the stock runs down (%s)" % [up])
	goods.inv.items.erase("iron_bar")
	var down: Array = w.player_quote(goods, "iron_bar", 6, false)
	check(down[0] > down[-1] and range(5).all(func(i): return down[i] >= down[i + 1]), "selling bars, each fetches the same or less as the buyer fills up (%s)" % [down])
	# -- buying through the real window: the bill is the sum of the unit prices
	var keeper: NPC = w.tavern_keeper()
	keeper.inv.items.erase("ale")
	keeper.inv.add("ale", 30)
	p.coins = 17
	var ale0 := p.inv.count("ale")
	var all0 := p.coins + keeper.coins
	var aq: Array = w.player_quote(keeper, "ale", 30, true)
	var amax := QuantityPicker.buy_max_priced(aq, 17)
	ui.show_trade(keeper, {"id": "ale", "mode": "buy"})
	var qp: QuantityPicker = ui.panel_body.get_node_or_null("QuantityPicker")
	check(qp != null and amax > 3 and qp.max_qty == amax and qp.qty == 1, "the buy control opens at 1 with max %d" % amax)
	qp.set_qty(99)
	var amax_bill := 0
	for i in amax:
		amax_bill += int(aq[i])
	check(qp.qty == amax and qp.total() == amax_bill and qp.total_label.text.contains(str(amax_bill)), "the quantity clamps to the max and the total is live (%s)" % qp.total_label.text)
	qp.slider.value = 3
	check(qp.qty == 3 and qp.total() == int(aq[0]) + int(aq[1]) + int(aq[2]), "the slider sets the quantity and the total sums the unit prices")
	qp.cancel()
	check(ui.panel_body.get_node_or_null("QuantityPicker") == null and p.coins == 17 and p.inv.count("ale") == ale0 and keeper.inv.count("ale") == 30,
		"Cancel changes nothing")
	ui.show_trade(keeper, {"id": "ale", "mode": "buy"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	qp.set_qty(3)
	var bill3 := qp.total()
	var keeper_coins0 := keeper.coins
	qp.confirm()
	check(p.coins == 17 - bill3 and p.inv.count("ale") == ale0 + 3 and keeper.inv.count("ale") == 27 and keeper.coins == keeper_coins0 + bill3,
		"Buy moves coins and goods together, at the summed price")
	check(p.coins + keeper.coins == all0, "no coins appear or vanish")
	p.coins = 0
	ui.show_trade(keeper, {"id": "ale", "mode": "buy"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	check(qp.max_qty == 0 and qp.confirm_btn.disabled, "with too few coins nothing can be confirmed")
	qp.confirm()
	check(p.coins == 0 and keeper.inv.count("ale") == 27, "a refused buy moves nothing")
	p.coins = 50
	check(w.player_buy_many(keeper, "ale", 3).result == "bought" and w.player_buy_many(keeper, "ale", 99).bought == 0, "player_buy_many refuses more than the stock, whole")
	# -- selling: the buyer pays each unit's falling price from their own coins
	p.inv.items.erase("iron_bar")
	p.inv.add("iron_bar", 6)
	goods.inv.items.erase("iron_bar")
	goods.coins = 1000
	p.coins = 10
	var tot := p.coins + goods.coins
	var sq: Array = w.player_quote(goods, "iron_bar", 6, false)
	var sbill := 0
	for c in sq:
		sbill += int(c)
	ui.show_trade(goods, {"id": "iron_bar", "mode": "sell"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	check(qp != null and qp.max_qty == 6 and qp.total_for(6) == sbill, "sell max is what you carry (6), totalled unit by unit (%d)" % sbill)
	qp.cancel()
	check(p.inv.count("iron_bar") == 6 and p.coins == 10, "Cancel on a sale changes nothing")
	ui.show_trade(goods, {"id": "iron_bar", "mode": "sell"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	qp.set_qty(6)
	qp.confirm()
	check(p.inv.count("iron_bar") == 0 and goods.inv.count("iron_bar") == 6 and p.coins == 10 + sbill and p.coins + goods.coins == tot, "Sell moves goods and coins together")
	check(sbill < 6 * int(sq[0]), "six bars fetch less than six at the opening price (%d < %d)" % [sbill, 6 * int(sq[0])])
	# a buyer without the money cannot buy (Build 13 economy rule 1)
	p.inv.add("iron_bar", 4)
	goods.inv.items.erase("iron_bar")
	var q4: Array = w.player_quote(goods, "iron_bar", 4, false)
	goods.coins = w.reserve_of(goods) + int(q4[0]) + int(q4[1]) + 1     # PAR-02, OD-19: the buyer keeps their reserve
	ui.show_trade(goods, {"id": "iron_bar", "mode": "sell"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	check(qp.max_qty == 2, "a poor buyer limits the sale to what their coins pay for (2)")
	var gc := goods.coins
	check(w.player_sell_many(goods, "iron_bar", 3).sold == 0 and p.inv.count("iron_bar") == 4 and goods.coins == gc, "selling more than the buyer can pay for is refused whole")
	goods.coins = 0
	check(w.player_sell_many(goods, "iron_bar", 1).sold == 0 and goods.coins == 0, "a buyer with no coins buys nothing")
	p.inv.items.erase("iron_bar")
	ui.hide_all()
	# -- B on a pad (and Esc) closes only an open quantity control, never the window under it (Build 13)
	ui.set_scheme("gamepad")
	goods.inv.add("iron_sword", 1)
	p.coins = 500
	ui.show_trade(goods, {"id": "iron_sword", "mode": "buy"})
	check(ui.panel_body.get_node_or_null("QuantityPicker") != null, "a quantity control is open over the trade window")
	main._unhandled_input(_pad(JOY_BUTTON_B))
	await process_frame
	check(ui.is_open("trade") and ui.panel_body.find_child("QuantityPicker", true, false) == null, "B closes only the quantity control; the trade window stays")
	check(p.coins == 500, "and nothing was bought")
	main._unhandled_input(_pad(JOY_BUTTON_B))
	await process_frame
	check(not ui.panel.visible, "a second B closes the trade window")
	ui.show_trade(goods, {"id": "iron_sword", "mode": "buy"})
	main._unhandled_input(_key(KEY_ESCAPE))
	await process_frame
	check(ui.is_open("trade") and ui.panel_body.find_child("QuantityPicker", true, false) == null, "Esc does the same on a keyboard")
	ui.hide_all()
	p.chest.items.clear()
	p.inv.add("coal", 3)
	ui.show_home({"id": "coal", "from": "pack"})
	check(ui.panel_body.find_child("QuantityPicker", true, false) != null, "the store control is open over the home chest")
	main._unhandled_input(_pad(JOY_BUTTON_B))
	await process_frame
	await process_frame
	check(ui.panel.visible and ui.panel_body.find_child("QuantityPicker", true, false) == null and p.inv.count("coal") == 3, "B closes only the store control; the chest window stays and nothing moved")
	var fo: Control = ui.get_viewport().gui_get_focus_owner()
	check(fo != null and ui.panel.is_ancestor_of(fo), "focus stays in the chest window for the pad (%s)" % (fo.name if fo else "none"))
	ui.set_scheme("kbm")
	# -- storage
	ui.hide_all()
	p.chest.items.clear()
	p.inv.items.clear()
	for id in ["bread", "coal", "log"]:
		p.inv.add(id, 3)
	ui.show_home({"id": "coal", "from": "pack"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	check(qp != null and qp.max_qty == 3, "the store control offers up to the stack")
	qp.set_qty(1)
	qp.confirm()
	await process_frame
	await process_frame
	check(p.inv.count("coal") == 2 and p.chest.count("coal") == 1, "storing 1 of a stack moves exactly 1")
	check(_focus_item(ui) == "Coal", "after a partial deposit focus stays on the same item (%s)" % _focus_item(ui))
	ui.show_home({"id": "coal", "from": "pack"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	qp.set_qty(qp.max_qty)
	qp.confirm()
	await process_frame
	await process_frame
	check(p.inv.count("coal") == 0 and p.chest.count("coal") == 3, "storing the rest empties the pack stack")
	check(_focus_item(ui) == "Log", "after the stack is gone focus moves to the next item in its place (%s)" % _focus_item(ui))
	ui.show_home({"id": "log", "from": "pack"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	qp.set_qty(3)
	qp.confirm()
	await process_frame
	await process_frame
	check(_focus_item(ui) == GameData.item_name("bread"), "after the last item is stored focus moves to the previous one (%s)" % _focus_item(ui))
	ui.show_home({"id": "coal", "from": "chest"})
	qp = ui.panel_body.get_node_or_null("QuantityPicker")
	qp.cancel()
	await process_frame
	await process_frame
	check(ui.panel_kind == "home", "Cancel keeps the storage window open")
	ui.show_home()
	for b in ui.panel_body.find_children("*", "Button", true, false):
		if b.text == "Store all":
			b.pressed.emit()
			break
	check(p.inv.count("bread") == 0 and p.chest.count("bread") == 3, "Store all moves the whole pack")
	for b in ui.panel_body.find_children("*", "Button", true, false):
		if b.text == "Take all":
			b.pressed.emit()
			break
	check(p.chest.items.is_empty() and p.inv.count("coal") == 3, "Take all brings everything back")
	# focus scrolls a long list into view
	var ids: Array = GameData.items.keys().slice(0, 40)
	p.inv.items.clear()
	for id in ids:
		p.chest.add(id, 1)
	ui.show_home()
	await process_frame
	await process_frame
	var last: Button = null
	for b in ui.panel_body.find_children("*", "Button", true, false):
		if b.text == "Take":
			last = b
	last.grab_focus()
	await process_frame
	await process_frame
	await process_frame
	check(ui.body_scroll.scroll_vertical > 0 and ui.body_scroll.get_global_rect().encloses(last.get_global_rect().grow(-2)),
		"focus on a row far down scrolls it into view (scroll %d)" % ui.body_scroll.scroll_vertical)
	p.chest.items.clear()
	ui.hide_all()
	# -- bars: plain current/max
	p.hp = 85.0
	p.hunger = 80.0
	p.stamina = 42.0
	ui.update_hud()
	check(ui.bar_labels.hp.text == "85/%d" % int(p.hp_cap()) and ui.bar_labels.hunger.text == "80/100" and ui.bar_labels.stamina.text == "42/%d" % int(p.stamina_cap()),
		"the bars read n/max: %s %s %s" % [ui.bar_labels.hp.text, ui.bar_labels.hunger.text, ui.bar_labels.stamina.text])
	check(GameUI.bar_words(120.0, 100.0) == "100/100" and GameUI.bar_words(9.2, 150.0) == "10/150", "bar text follows the maximum and never passes it")
	p.hp = p.hp_cap()
	p.stamina = p.stamina_cap()
	# -- consumables
	var ok := true
	var n_eff := 0
	for id in GameData.items:
		var it: Dictionary = GameData.items[id]
		if not it.has("food") and not it.has("heal"):
			continue
		var t := GameData.effect_text(id)
		n_eff += 1
		ok = ok and (int(it.get("food", 0)) <= 0 or t.contains("%d Food" % int(it.food))) and (not it.has("heal") or t.contains("%d Health" % int(it.heal))) and (not it.has("harm") or t.contains("Harms %d" % int(it.harm)))
	check(ok and n_eff > 0, "every consumable's effect text equals its item data (%d items)" % n_eff)
	check(GameData.effect_text("coal") == "", "a non-consumable has no effect text")
	for med in ["linen_bandage", "herbal_poultice", "healing_tonic", "strong_healing_tonic"]:
		check(GameData.effect_text(med) == "Restores %d Health" % int(GameData.item(med).heal), "%s shows its healing (%s)" % [med, GameData.effect_text(med)])
	var heal_id := ""
	for id in GameData.items:
		if GameData.items[id].has("heal") and GameData.items[id].has("food") and not GameData.items[id].has("harm"):
			heal_id = id
			break
	p.inv.items.erase(heal_id)
	p.hp = 1.0
	p.hunger = 10.0
	var f: float = GameData.item(heal_id).food
	var h: float = GameData.item(heal_id).heal
	p.inv.add(heal_id, 1)
	check(w.player_eat(heal_id) and is_equal_approx(p.hunger, 10.0 + f) and is_equal_approx(p.hp, 1.0 + h), "using it applies exactly the listed effects")
	check(not w.player_eat(heal_id) and is_equal_approx(p.hunger, 10.0 + f), "a second use with none left does nothing")
	p.inv.items.erase("coal")
	check(not w.player_eat("coal"), "a non-food cannot be used and nothing is consumed")
	ui.show_trade(keeper)
	check(_texts(ui.panel_body).contains("Restores") or keeper.inv.ids().filter(func(i): return GameData.effect_text(i) != "").is_empty(), "shop rows list a consumable's effects")
	ui.hide_all()
	# -- dialogue
	w.note("Walter Reed sold two logs to the carpenter")
	w.note("Your work for the manor lapsed: \"Bread\" was not done in time.")
	w.note("Hobbs Smith bought coal from the smith")
	w.note("Hobbs Smith bought coal from the smith")
	check(Dialogue.possessive("Reed") == "Reed's" and Dialogue.possessive("Hobbs") == "Hobbs'", "possessives: Reed's, Hobbs'")
	check(Dialogue.sentence("walter sold logs") == "Walter sold logs." and Dialogue.sentence("Is it?") == "Is it?", "lines are closed as sentences")
	var bad := []
	var seen := 0
	var rx_dot := RegEx.create_from_string("\\.\\.|\\. \\.|  |\\s[,.!?]|'s's|\\b[a-z]\\d+\\b|\\. [a-z]")
	for n: NPC in w.npcs.slice(0, 60):
		if not n.alive or n.role == "bandit":
			continue
		if n.id % 5 == 0:
			n.remember("found 3 wheat from f9 missing")
		for t in [Dialogue.opening(w, n), Dialogue.work(w, n), Dialogue.home(w, n), Dialogue.news(w, n), Dialogue.brush_off(w, n)]:
			seen += 1
			var sents := Array(str(t).split(". ")).map(func(s: String): return s.strip_edges())
			var dup := false
			for i in range(1, sents.size()):
				dup = dup or (sents[i] == sents[i - 1] and sents[i] != "")
			if dup or rx_dot.search(str(t)) != null or str(t).contains("Your work") or str(t).contains("Someone took 3 wheat from f"):
				bad.append("%s: %s" % [n.name, t])
	check(bad.is_empty(), "%d generated lines are clean %s" % [seen, bad.slice(0, 3)])


## The item name on the row holding keyboard/pad focus ("Coal"), or "".
func _focus_item(ui) -> String:
	var f = ui.get_viewport().gui_get_focus_owner()
	if f == null or f.get_parent() == null:
		return ""
	for c in f.get_parent().get_children():
		if c is Label:
			return (c as Label).text.get_slice(" x", 0)
	return ""
