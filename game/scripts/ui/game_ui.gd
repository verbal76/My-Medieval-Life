class_name GameUI
extends CanvasLayer
## HUD and panels, built in code. Large touch targets (at least 48 px) and readable text.

const ICON := "res://assets/icons/%s.png"

var main
var root: Control
var hud: Control
var bars := {}
var coins_label: Label
var clock_label: Label
var prompt_label: Label
var log_box: VBoxContainer
var toast: Label
var toast_t := 0.0
var action_bar: ProgressBar
var panel: PanelContainer
var panel_kind := ""
var panel_body: VBoxContainer
var title_label: Label
var font_scale := 1.0
var touch_bar: HBoxContainer


func build(m) -> void:
	main = m
	layer = 20
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 18
	root.theme = theme
	_build_hud()
	_build_panel()


func _style(color: Color, border := Color(0.55, 0.42, 0.25)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(10)
	return s


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _style(Color(0.08, 0.06, 0.04, 0.78)))
	box.position = Vector2(12, 12)
	hud.add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)
	for b in [["hp", "Health", Color(0.8, 0.2, 0.2)], ["hunger", "Hunger", Color(0.85, 0.6, 0.2)], ["stamina", "Stamina", Color(0.25, 0.6, 0.9)]]:
		var h := HBoxContainer.new()
		var l := Label.new()
		l.text = b[1]
		l.custom_minimum_size = Vector2(80, 0)
		h.add_child(l)
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(170, 20)
		pb.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = b[2]
		pb.add_theme_stylebox_override("fill", fill)
		h.add_child(pb)
		v.add_child(h)
		bars[b[0]] = pb
	var row := HBoxContainer.new()
	var ci := TextureRect.new()
	ci.texture = load(ICON % "coins")
	ci.custom_minimum_size = Vector2(24, 24)
	ci.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(ci)
	coins_label = Label.new()
	row.add_child(coins_label)
	clock_label = Label.new()
	clock_label.custom_minimum_size = Vector2(150, 0)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(clock_label)
	v.add_child(row)

	log_box = VBoxContainer.new()
	log_box.position = Vector2(-470, 12)
	log_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	log_box.custom_minimum_size = Vector2(458, 0)
	log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(log_box)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-300, -150)
	prompt_label.custom_minimum_size = Vector2(600, 0)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 6)
	hud.add_child(prompt_label)

	toast = Label.new()
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2(-380, 150)
	toast.custom_minimum_size = Vector2(760, 0)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_outline_color", Color.BLACK)
	toast.add_theme_constant_override("outline_size", 6)
	hud.add_child(toast)

	action_bar = ProgressBar.new()
	action_bar.set_anchors_preset(Control.PRESET_CENTER)
	action_bar.position = Vector2(-90, 40)
	action_bar.custom_minimum_size = Vector2(180, 18)
	action_bar.show_percentage = false
	action_bar.visible = false
	hud.add_child(action_bar)

	touch_bar = HBoxContainer.new()
	touch_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	touch_bar.position = Vector2(-560, -84)
	touch_bar.add_theme_constant_override("separation", 8)
	hud.add_child(touch_bar)
	for b in [["Use", "interact"], ["Attack", "attack"], ["Fire", "fireball"], ["Pack", "inventory"], ["Skills", "skills"], ["Menu", "pause"]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(84, 64)
		btn.focus_mode = Control.FOCUS_NONE
		var act: String = b[1]
		btn.pressed.connect(func(): _touch_action(act))
		touch_bar.add_child(btn)


func _touch_action(act: String) -> void:
	match act:
		"interact":
			main.interact()
		"attack":
			main.attack()
		"fireball":
			main.fireball()
		"inventory":
			toggle_inventory()
		"skills":
			toggle_skills()
		"pause":
			show_pause()


func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.12, 0.09, 0.06, 0.96)))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(760, 520)
	panel.position = Vector2(-380, -280)
	panel.visible = false
	root.add_child(panel)
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	var top := HBoxContainer.new()
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(96, 48)
	close.pressed.connect(hide_all)
	top.add_child(close)
	outer.add_child(top)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(740, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	panel_body = VBoxContainer.new()
	panel_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel_body)


# ---------------------------------------------------------------- hud ------------------------
func update_hud() -> void:
	var w: World = main.world
	if w == null:
		return
	var p := w.player
	bars.hp.max_value = p.max_hp
	bars.hp.value = p.hp
	bars.hunger.value = p.hunger
	bars.stamina.value = p.stamina
	coins_label.text = " %d" % p.coins
	clock_label.text = w.clock_text()
	var a: Dictionary = main.action
	action_bar.visible = not a.is_empty()
	if not a.is_empty():
		action_bar.max_value = a.total
		action_bar.value = a.total - a.left
	if toast_t > 0.0:
		toast_t -= get_process_delta_time()
		if toast_t <= 0.0:
			toast.text = ""


func prompt(text: String) -> void:
	prompt_label.text = ("[E]  " + text) if text != "" else ""


func message(text: String) -> void:
	toast.text = text
	toast_t = 4.0


func log_line(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	log_box.add_child(l)
	while log_box.get_child_count() > 5:
		var c := log_box.get_child(0)
		log_box.remove_child(c)
		c.queue_free()


# ---------------------------------------------------------------- panel helpers --------------
func modal() -> bool:
	return panel.visible


func is_open(kind: String) -> bool:
	return panel.visible and panel_kind == kind


func hide_all() -> void:
	panel.visible = false
	panel_kind = ""
	if main.world and main.running:
		main.paused = false


func _open(kind: String, title: String, pause := true) -> void:
	panel_kind = kind
	title_label.text = title
	for c in panel_body.get_children():
		panel_body.remove_child(c)
		c.queue_free()
	panel.visible = true
	if pause:
		main.paused = true


func _label(text: String, size := 18, color := Color(0.95, 0.9, 0.8)) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	panel_body.add_child(l)
	return l


func _button(text: String, cb: Callable, enabled := true, parent: Control = null) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.disabled = not enabled
	b.pressed.connect(cb)
	(parent if parent else panel_body).add_child(b)
	return b


func _icon(id: String) -> TextureRect:
	var t := TextureRect.new()
	var path := ICON % id
	if ResourceLoader.exists(path):
		t.texture = load(path)
	t.custom_minimum_size = Vector2(32, 32)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t


func _item_row(id: String, count: int, text: String, btn: String, cb: Callable, enabled := true) -> void:
	var h := HBoxContainer.new()
	h.add_child(_icon(id))
	var l := Label.new()
	l.text = "%s x%d   %s" % [GameData.item_name(id), count, text]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	if btn != "":
		var b := Button.new()
		b.text = btn
		b.custom_minimum_size = Vector2(110, 48)
		b.disabled = not enabled
		b.pressed.connect(cb)
		h.add_child(b)
	panel_body.add_child(h)


# ---------------------------------------------------------------- title / pause / death ------
func show_title(can_continue: bool) -> void:
	_open("title", "My Medieval Life  (working title: The Well)", false)
	_label("A living village of a hundred people who work, trade, eat and sleep whether or not you are watching. You are one of them.")
	_button("Continue", func(): main.continue_game(), can_continue)
	_button("New game", func(): main.new_game())
	_button("Quit", func(): main.get_tree().quit())
	_label("Controls: WASD/arrows or tap to move · E or tap next to something to use it · Space to attack · F for fireball (once learned) · I pack · L skills · Esc menu · mouse wheel or pinch to zoom. Gamepad supported.", 15)


func show_pause() -> void:
	_open("pause", "Paused")
	_button("Resume", hide_all)
	_button("Save", func(): main.save_game())
	_button("Village record (events)", show_events)
	_button("Text size", func():
		font_scale = {1.0: 1.3, 1.3: 1.6, 1.6: 1.0}[font_scale]
		root.theme.default_font_size = int(18 * font_scale)
		message("Text size %d%%" % int(font_scale * 100)))
	_button("Save and quit to title", func():
		main.save_game(false)
		main.running = false
		show_title(true))


func show_events() -> void:
	_open("events", "What has happened in the village")
	for l in main.world.log_lines.slice(-40):
		_label(l, 15)


func show_death() -> void:
	var p: PlayerState = main.world.player
	_open("death", "%s %s has died" % [p.name, p.family])
	_label("Death is permanent, but the village and your family go on. What %s carried lies where they fell. Your heir keeps the family house, the chest and half of what was learned." % p.name)
	_button("Continue as the heir", func(): main.continue_as_heir())


# ---------------------------------------------------------------- people ---------------------
func show_talk(n: NPC) -> void:
	var w: World = main.world
	_open("talk", "%s %s" % [n.name, n.family] if n.role != "bandit" else n.name)
	var role := n.job if n.job != "" else n.role
	_label("%s. Right now: %s." % [role.capitalize(), n.doing])
	if n.household >= 0:
		var hh: Dictionary = w.households[n.household]
		_label("Household: the %s family, %d people, living at %s." % [hh.family, hh.members.size(), w.buildings[hh.home].get("name", "a house")], 15)
	_label("Hunger %d/100 · coins %d · has earned %d and spent %d." % [int(n.hunger), n.coins, n.earned, n.spent], 15)
	if not n.memory.is_empty():
		_label("Remembers: " + "; ".join(n.memory), 15)
	if n.role == "bandit":
		_label("\"Your purse or your life.\"")
		return
	var sale: Array = w.brain.for_sale(n)
	var buys: Dictionary = NPCBrain.BUYS.get(w.brain.buy_role(n), {})
	if not sale.is_empty() or not buys.is_empty():
		_button("Trade", func(): show_trade(n))
	if n.id == w.sage_id:
		var price := int(GameData.b("fireball_price"))
		var known: bool = w.player.spells.get("fireball", false)
		_label("\"Fire answers those who learn its rules. I can teach you to call it.\"")
		_button("Learn Fireball (%d coins)" % price if not known else "You know Fireball", func():
			if w.player.coins >= price:
				w.player.coins -= price
				n.coins += price
				w.player.spells["fireball"] = true
				w.player.gain("magic", 100)
				message("You learned Fireball. Press F (or the Fire button) to cast it; it uses stamina.")
				hide_all()
			else:
				message("You need %d coins." % price), not known)
	if n.id == w.reeve_id:
		_label("\"Land by the east houses is for sale. Find the plots past the last houses and buy one there; the coins come to me.\"")


func show_trade(n: NPC) -> void:
	var w: World = main.world
	var p := w.player
	_open("trade", "Trade with %s %s  (you have %d coins)" % [n.name, n.family, p.coins])
	var sale: Array = w.brain.for_sale(n)
	_label("They sell:", 20, Color(1, 0.85, 0.5))
	if sale.is_empty():
		_label("Nothing right now.", 15)
	for id in sale:
		var price := maxi(1, roundi(w.sell_price(n, id) * w.player_price_factor(true)))
		var nn := n
		_item_row(id, n.inv.count(id), "%d coins each" % price, "Buy", func():
			if w.trade(p, nn, id, 1, price):
				main._xp("trading", 2)
			else:
				message("You cannot afford that, or your pack is full.")
			show_trade(nn), p.coins >= price)
	var buys: Dictionary = NPCBrain.BUYS.get(w.brain.buy_role(n), {})
	_label("They buy:", 20, Color(1, 0.85, 0.5))
	var any := false
	for id in p.inv.ids():
		if w.brain.wants(n, id) > 0:
			any = true
			var price := maxi(1, roundi(w.buy_price(n, id) * w.player_price_factor(false)))
			var nn := n
			_item_row(id, p.inv.count(id), "%d coins each" % price, "Sell", func():
				if w.trade(nn, p, id, 1, price):
					main._xp("trading", 2)
				else:
					message("They cannot afford it right now.")
				show_trade(nn), n.coins >= price)
	if not any:
		_label("Nothing you carry (they want: %s)." % ", ".join(buys.keys().map(func(k): return GameData.item_name(k))) if not buys.is_empty() else "They are not buying.", 15)


# ---------------------------------------------------------------- crafting -------------------
func show_craft(station_id: String) -> void:
	var w: World = main.world
	var st: Dictionary = w.stations[station_id]
	var p := w.player
	_open("craft", "The %s" % st.type)
	for r in GameData.recipes_at(st.type):
		var rec: Dictionary = GameData.recipes[r]
		var ins := ", ".join(rec.in.keys().map(func(k): return "%d %s (%d)" % [int(rec.in[k]), GameData.item_name(k), p.inv.count(k)]))
		var outs := ", ".join(rec.out.keys().map(func(k): return "%d %s" % [int(rec.out[k]), GameData.item_name(k)]))
		var lv_ok := p.level(rec.skill) >= int(rec.level)
		var h := HBoxContainer.new()
		h.add_child(_icon(rec.out.keys()[0]))
		var l := Label.new()
		l.text = "%s  <-  %s   [%s %d]" % [outs, ins, GameData.skills[rec.skill].name, int(rec.level)]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var rr: String = r
		_button("Make", func(): main.craft(rr), lv_ok and p.inv.has_all(rec.in), h)
		panel_body.add_child(h)


# ---------------------------------------------------------------- inventory ------------------
func toggle_inventory() -> void:
	if is_open("inventory"):
		hide_all()
	else:
		show_inventory("")


func show_inventory(filter: String) -> void:
	var w: World = main.world
	var p := w.player
	_open("inventory", "Pack (%d of %d kinds)" % [p.inv.items.size(), p.inv.max_stacks])
	var search := LineEdit.new()
	search.placeholder_text = "Search…"
	search.text = filter
	search.custom_minimum_size = Vector2(0, 48)
	search.text_submitted.connect(func(t): show_inventory(t))
	panel_body.add_child(search)
	_label("Weapon: %s · Armour: %s" % [GameData.item_name(p.weapon) if p.weapon != "" else "none", GameData.item_name(p.armor) if p.armor != "" else "none"], 15)
	for id in p.inv.ids():
		if filter != "" and GameData.item_name(id).to_lower().find(filter.to_lower()) < 0:
			continue
		var it: Dictionary = GameData.item(id)
		var t: String = it.get("type", "")
		var iid: String = id
		if t == "food":
			_item_row(id, p.inv.count(id), "", "Eat", func():
				p.inv.remove(iid)
				p.hunger = minf(100.0, p.hunger + float(it.food))
				show_inventory(filter))
		elif t == "weapon" or t == "armor":
			_item_row(id, p.inv.count(id), "", "Equip", func():
				if t == "weapon":
					p.weapon = iid
				else:
					p.armor = iid
				show_inventory(filter))
		elif id == "wheat":
			_item_row(id, p.inv.count(id), "", "Eat raw", func():
				p.inv.remove(iid)
				p.hunger = minf(100.0, p.hunger + 20.0)
				show_inventory(filter))
		else:
			_item_row(id, p.inv.count(id), "", "", func(): pass)


# ---------------------------------------------------------------- skills ---------------------
func toggle_skills() -> void:
	if is_open("skills"):
		hide_all()
	else:
		show_skills()


func show_skills() -> void:
	var p: PlayerState = main.world.player
	_open("skills", "Skills — %s %s, generation %d" % [p.name, p.family, p.generation])
	var keys := GameData.skills.keys()
	for k in keys:
		var s: Dictionary = GameData.skills[k]
		var lv := p.level(k)
		var into := p.xp_into_level(k)
		_label("%s — level %d  (%d / %d xp)" % [s.name, lv, into.x, into.y], 20, Color(1, 0.85, 0.5))
		var h := HBoxContainer.new()
		var levels: Array = s.unlocks.keys()
		levels.sort()
		for l in levels:
			var b := Label.new()
			var got := lv >= int(l)
			b.text = ("[x] " if got else "[ ] ") + "L%s: %s" % [l, s.unlocks[l]]
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.custom_minimum_size = Vector2(170, 0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", 14)
			b.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6) if got else Color(0.7, 0.7, 0.7))
			h.add_child(b)
		panel_body.add_child(h)


# ---------------------------------------------------------------- building / home ------------
func show_build(pl: Dictionary) -> void:
	var w: World = main.world
	var p := w.player
	_open("build", "Building plot")
	if pl.owner == "":
		_label("This plot is for sale for %d coins. The coins go to the reeve. Once it is yours, you can mark out a house: a wooden frame appears, you bring the materials, and when the last load is in, the house stands." % int(pl.price))
		_button("Buy for %d coins" % int(pl.price), func():
			var reeve := w.npc(w.reeve_id)
			if p.coins < int(pl.price) or reeve == null:
				message("You need %d coins." % int(pl.price))
				return
			p.coins -= int(pl.price)
			reeve.coins += int(pl.price)
			pl.owner = "player"
			p.plots.append(pl.id)
			w.note("%s %s bought %s from the reeve." % [p.name, p.family, pl.id])
			show_build(pl), p.coins >= int(pl.price))
		return
	if pl.owner != "player":
		_label("This plot belongs to someone else.")
		return
	if pl.site.is_empty():
		var cost: Dictionary = GameData.b("house_cost")
		_label("Mark out a house here? It will need: " + ", ".join(cost.keys().map(func(k): return "%d %s" % [int(cost[k]), GameData.item_name(k)])))
		_button("Mark out a house", func():
			w.start_site(pl)
			show_build(pl))
		return
	if pl.site.done:
		_label("Your house stands here.")
		return
	var need: Dictionary = pl.site.need
	_label("Building: House. Still needed:")
	for id in need:
		_item_row(id, int(need[id]), "(you carry %d)" % p.inv.count(id), "", func(): pass)
	_button("Deliver what I carry", func():
		if w.deliver(pl, p.inv):
			p.home = "house_" + pl.id
			message("Your house is finished! Use its door to rest and to store things.")
			hide_all()
		else:
			show_build(pl))


func show_home() -> void:
	var w: World = main.world
	var p := w.player
	_open("home", "%s family house" % p.family)
	_button("Rest until morning (saves the game)", func():
		hide_all()
		main.rest())
	_label("Chest:", 20, Color(1, 0.85, 0.5))
	for id in p.chest.ids():
		var iid: String = id
		_item_row(id, p.chest.count(id), "", "Take", func():
			w.transfer(p.chest, p.inv, iid, p.chest.count(iid))
			show_home())
	_label("Your pack:", 20, Color(1, 0.85, 0.5))
	for id in p.inv.ids():
		var iid: String = id
		_item_row(id, p.inv.count(id), "", "Store", func():
			w.transfer(p.inv, p.chest, iid, p.inv.count(iid))
			show_home())
