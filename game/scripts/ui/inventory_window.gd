class_name InventoryWindow
extends Control
## The pack window, drawn with Cozy Farm's inventory panel (imported by tools/import_game_assets.py):
## a tab strip (All, Food, Materials, Tools, Weapons, Armour, then Skills and Journal, which open
## those windows), the character panel (the player's figure in the portrait frame, the six gear slots
## around it, the name on the plate) and the 9 x 3 bag grid. Beside it, or below it on a narrow
## screen, the chosen item's name, what it does and what can be done with it.
##
## The art is drawn at a whole number of screen pixels per art pixel (nearest filtering), with its
## corner on a whole screen pixel, so it stays crisp at any window size. Tabs, gear slots and bag
## cells are flat buttons over the art, so touch, mouse, keys and the pad (focus moves between them
## by position) all work the same way.

const PANEL := "res://assets/ui/inventory_panel.png"
const TAB_STRIPS := "res://assets/ui/inventory_tabs.png"
const ICON := "res://assets/icons/%s.png"
const ART := Vector2(293, 132)      # the panel, with 8 px of headroom above the flat tabs
const STRIP := 16                   # rows of the tab strip image per tab (row i has tab i raised)
const TAB_X := 117                  # the first tab's inside; tabs are TAB_STEP apart
const TAB_STEP := 21
const TAB_W := 16
const BODY_TOP := 33                # where the panel's body (below the tabs) starts
# id, caption, icon, item types shown ("skills" and "journal" open those windows instead)
const TABS := [
	["all", "All", "res://assets/ui/tab_all.png", []],
	["food", "Food", "res://assets/icons/bread.png", ["food"]],
	["materials", "Materials", "res://assets/icons/log.png", ["resource"]],
	["tools", "Tools", "res://assets/icons/pickaxe.png", ["tool"]],
	["weapons", "Weapons", "res://assets/icons/iron_sword.png", ["weapon"]],
	["armour", "Armour", "res://assets/icons/iron_armor.png", ["armor", "head", "amulet", "ring"]],
	["skills", "Skills", "res://assets/ui/tab_skills.png", []],
	["journal", "Journal", "res://assets/ui/tab_journal.png", []],
]
const COLS := 9
const ROWS := 3
const CELL0 := Vector2(95, 52)      # the first bag cell's corner
const CELL_STEP := Vector2(21, 22)
const CELL := Vector2(18, 18)
# gear slot -> its cell on the character panel (left column, right column)
const GEAR_AT := {"head": Vector2(12, 52), "amulet": Vector2(12, 70), "armor": Vector2(12, 88),
	"weapon": Vector2(66, 52), "tool": Vector2(66, 70), "ring": Vector2(66, 88)}
const GEAR_NAMES := {"weapon": "In hand", "tool": "Tool", "armor": "Body", "head": "Head", "amulet": "Amulet", "ring": "Ring"}
const GEAR_HINT := {"weapon": "Nothing in hand. Wield a sword here.", "tool": "No tool in hand. Pickaxes and axes go here.",
	"armor": "Nothing worn. Clothes and armour go here.", "head": "Nothing worn. Caps and helmets go here.",
	"amulet": "Nothing worn. An amulet goes here.", "ring": "Nothing worn. A ring goes here."}
const KINDS := {"food": "Food", "resource": "Material", "tool": "Tool", "weapon": "Weapon", "armor": "Body armour",
	"head": "Headgear", "amulet": "Amulet", "ring": "Ring"}
const PORTRAIT := Rect2(36, 55, 24, 48)    # inside the portrait frame
const FIGURE := Rect2(8, 4, 16, 20)        # the figure within the sprite sheet's first 32 px frame
const PLATE := Rect2(22, 111, 52, 6)       # the name plate under the portrait
const DETAIL_W := 200.0                    # least width of the item details beside the panel
const DETAIL_H := 120.0                    # least height of the details below it
const GAP := 8.0
const INK := Color8(58, 38, 22)
const TAN := Color8(181, 150, 97)
const EDGE := Color8(92, 68, 53)
const PALE := Color8(246, 236, 214)
const GOLD := Color8(236, 196, 72)

var ui                       # GameUI
var tab := "all"
var selected := ""           # item id chosen in the bag, or "gear:<slot>"
var k := 1.0                 # interface units per art pixel
var px := 1.0                # screen pixels per interface unit
var origin := Vector2.ZERO   # the art's corner, local
var side := true             # details beside the art (else below)
var shown: Array = []        # item ids in the bag cells, in order
var cells: Array[Button] = []
var gear_buttons := {}
var tab_buttons: Array[Button] = []
var details: PanelContainer
var detail_box: VBoxContainer
var actions: BoxContainer
var tex := {}
var detail_rect := Rect2()
var _fitted := Vector4.ZERO


func setup(game_ui, open_tab: String) -> void:
	ui = game_ui
	tab = open_tab if TABS.any(func(t): return t[0] == open_tab and t[3] != []) else "all"
	name = "InventoryWindow"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the bag cells first: the window's first focus goes to the first cell
	for i in COLS * ROWS:
		var b := _flat_button()
		var ci: int = i
		b.pressed.connect(func(): _choose_cell(ci))
		cells.append(b)
	for slot in PlayerState.GEAR:
		var b := _flat_button()
		var sl: String = slot
		b.tooltip_text = GEAR_NAMES[sl]
		b.pressed.connect(func(): choose("gear:" + sl))
		gear_buttons[sl] = b
	for t in TABS:
		var b := _flat_button()
		var tid: String = t[0]
		b.tooltip_text = t[1]
		b.pressed.connect(func(): choose_tab(tid))
		# the tab's generous touch area is not its look: the focus ring is drawn tight round the icon (B8-012)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.focus_entered.connect(queue_redraw)
		b.focus_exited.connect(queue_redraw)
		tab_buttons.append(b)
	details = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = TAN
	st.border_color = EDGE
	st.set_border_width_all(3)
	st.set_content_margin_all(10)
	details.add_theme_stylebox_override("panel", st)
	add_child(details)
	detail_box = VBoxContainer.new()
	details.add_child(detail_box)
	refresh()


func _flat_button() -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# a slot button is exactly its slot: no theme margins or text height may make it larger (B8-012)
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", 1)
	add_child(b)
	return b


func _player() -> PlayerState:
	return ui.main.world.player


func _icon(path: String) -> Texture2D:
	if not tex.has(path):
		tex[path] = load(path) if ResourceLoader.exists(path) else null
	return tex[path]


## Item ids the open tab shows, in the pack's order.
func items_shown() -> Array:
	var p := _player()
	var types: Array = TABS.filter(func(t): return t[0] == tab)[0][3]
	return p.inv.ids().filter(func(id): return types.is_empty() or str(GameData.item(id).get("type", "")) in types)


## Cells past what the pack can hold (Inventory.max_stacks) are locked.
func locked(i: int) -> bool:
	var cap := _player().inv.max_stacks
	return cap > 0 and i >= cap


func choose_tab(id: String) -> void:
	match id:
		"skills":
			ui.show_skills()
		"journal":
			ui.show_journal(-1)
		_:
			tab = id
			if not selected.begins_with("gear:"):
				selected = ""
			refresh()
			if ui.scheme != "touch":
				tab_buttons[TABS.map(func(t): return t[0]).find(id)].grab_focus()


func _choose_cell(i: int) -> void:
	if i < shown.size():
		choose(shown[i])
	else:
		selected = ""
		refresh()


## Choose a bag item (its id) or a gear slot ("gear:<slot>") and show its details and actions.
## With the pad or keys, focus moves on to the first action (Wear, Eat...), so A then A wears it;
## up or left goes back to the item (Build 8 report: the pad could not reach the buttons).
func choose(what: String) -> void:
	var from := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	selected = what
	refresh()
	if ui.scheme != "touch" and actions != null and actions.get_child_count() > 0 and from is Button:
		var back: NodePath = from.get_path()
		for c in actions.get_children():
			(c as Button).focus_neighbor_top = back
		(actions.get_child(0) as Button).focus_neighbor_left = back
		(actions.get_child(0) as Button).grab_focus()


## Redraw the art and rebuild the details after anything changed.
func refresh() -> void:
	var p := _player()
	shown = items_shown()
	if selected != "" and not selected.begins_with("gear:") and not p.inv.has(selected):
		selected = ""
	for i in cells.size():
		var b: Button = cells[i]
		var lock := locked(i)
		b.disabled = lock
		b.focus_mode = Control.FOCUS_NONE if lock else Control.FOCUS_ALL
		b.tooltip_text = "Your pack holds %d kinds of things" % p.inv.max_stacks if lock else \
			(GameData.item_name(shown[i]) if i < shown.size() else "")
	_build_details()
	queue_redraw()


func _slot_of(id: String) -> String:
	var p := _player()
	for slot in PlayerState.GEAR:
		if p.get(slot) == id:
			return slot
	return ""


func _build_details() -> void:
	for c in detail_box.get_children():
		detail_box.remove_child(c)
		c.queue_free()
	var w: World = ui.main.world
	var p := _player()
	var head := HBoxContainer.new()
	detail_box.add_child(head)
	var title := _text("", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close: Button = ui._tile_button("close", "", 40)
	close.tooltip_text = "Close"
	close.pressed.connect(ui.hide_all)
	head.add_child(close)
	actions = BoxContainer.new()
	actions.vertical = side
	actions.add_theme_constant_override("separation", 6)
	var id := selected
	var slot := ""
	if selected.begins_with("gear:"):
		slot = selected.substr(5)
		id = p.get(slot)
		if id != "" and not p.inv.has(id):
			id = ""
	if id == "":
		if slot != "":
			title.text = GEAR_NAMES[slot]
			detail_box.add_child(_text(GEAR_HINT[slot], 16))
		else:
			title.text = "%s %s" % [p.name, p.family]
			detail_box.add_child(_text("%d of %d kinds carried. Tap a slot to see what is in it." % [p.inv.items.size(), p.inv.max_stacks], 16))
		_fit_details()
		return
	var it: Dictionary = GameData.item(id)
	var t: String = it.get("type", "")
	var count := p.inv.count(id)
	var worn := _slot_of(id)
	title.text = GameData.item_name(id) + (" x%d" % count if count > 1 else "")
	var lines: Array[String] = [KINDS.get(t, "Thing") + (", in use" if worn != "" else "") + ". Worth about %d coins." % GameData.value(id)]
	if it.has("food"):
		lines.append("Fills %d hunger%s." % [int(it.food), ", but it makes you sick" if it.has("harm") else ""])
	if it.has("heal"):
		lines.append("Restores %d health." % int(it.heal))
	if it.has("damage"):
		lines.append("Damage %d." % int(it.damage))
	if int(it.get("armor", 0)) > 0:
		lines.append("Armour %d." % int(it.armor))
	var bonus: Dictionary = it.get("bonus", {})
	if bonus.has("max_hp"):
		lines.append("+%d max health while worn." % int(bonus.max_hp))
	if bonus.has("max_stamina"):
		lines.append("+%d max stamina while worn." % int(bonus.max_stamina))
	if it.has("durability"):
		lines.append("Wear left: %d of %d." % [int(p.inv.durability.get(id, it.durability)), int(it.durability)])
	var crafts := ResourceNodes.uses_of(id).filter(func(u): return u.kind == "recipe")
	if not crafts.is_empty():
		lines.append("Used for: " + "; ".join(crafts.map(func(u): return _use_line(w, id, u))) + ".")
	if it.has("plant"):
		lines.append("Plant it on open grass in front of you (not on a road, a door, a field or beside another tree). It grows into a tree in a few days.")
	detail_box.add_child(_text("\n".join(lines), 16))
	detail_box.add_child(actions)
	var iid: String = id
	if it.has("food"):
		_action("Eat", func():
			var hp0 := p.hp
			w.player_eat(iid)
			ui.message("You eat the %s.%s" % [GameData.item_name(iid).to_lower(), "  It makes you sick." if p.hp < hp0 else ""])
			_after())
	elif t in PlayerState.GEAR:
		if worn != "":
			_action("Take off", func():
				w.player_unequip(worn)
				_after())
		else:
			_action({"tool": "Use", "weapon": "Wield"}.get(t, "Wear"), func():
				w.player_equip(iid)
				_after())
	if it.has("plant"):
		_action("Plant", func(): ui.main.plant_sapling(iid))
	_action("Drop", func():
		w.player_drop(iid, 1)
		ui.message("You put down a %s." % GameData.item_name(iid).to_lower())
		_after())
	if count > 1:
		_action("Drop all", func():
			w.player_drop(iid, p.inv.count(iid))
			_after())
	_fit_details()


## "Roast meat (with 1 log) at an oven: The Well House", so a player holding raw meat knows where it
## cooks (Build 8 question: can I cook this anywhere?).
func _use_line(w: World, item: String, u: Dictionary) -> String:
	var r: Dictionary = GameData.recipes[u.id]
	var other := []
	for k in r.in:
		if k != item:
			other.append("%d %s" % [int(r.in[k]), GameData.item_name(k).to_lower()])
	var places := []
	for sid in w.stations_of(str(u.station)):
		var bid = w.stations[sid].get("building")
		var b: Dictionary = w.buildings.get(bid, {}) if bid != null else {}
		var place := str(b.get("name", "")) if not b.is_empty() else ""
		if place != "" and not places.has(place):
			places.append(place)
	var makes := ", ".join(r.out.keys().map(func(o): return GameData.item_name(o)))
	return "%s%s at a %s%s" % [makes, (" (with %s)" % ", ".join(other)) if not other.is_empty() else "", str(u.station),
		(": " + ", ".join(places)) if not places.is_empty() else ""]


func _text(s: String, size: int) -> Label:
	var l := Label.new()
	l.text = s
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = maxf(detail_rect.size.x - 80.0, 60.0) if size > 18 else maxf(detail_rect.size.x - 26.0, 60.0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	return l


func _action(caption: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(120, 46)
	b.pressed.connect(cb)
	actions.add_child(b)


## After an action: show the change, and keep the pad's or keys' focus where it was.
func _after() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	var keep := cells.find(focus)
	refresh()
	if ui.scheme != "touch":
		if selected.begins_with("gear:"):
			gear_buttons[selected.substr(5)].grab_focus()
		elif selected != "" and shown.has(selected):
			cells[shown.find(selected)].grab_focus()
		else:
			cells[clampi(keep, 0, cells.size() - 1)].grab_focus()


# ---------------------------------------------------------------- layout and drawing ---------
func _process(_delta: float) -> void:
	var scroll := get_parent().get_parent() as Control if get_parent() else null
	if scroll and scroll.size.y > 100.0 and absf(custom_minimum_size.y - scroll.size.y) > 0.5:
		custom_minimum_size = Vector2(0, scroll.size.y)
	var g := get_global_transform_with_canvas().origin
	var now := Vector4(size.x, size.y, g.x + g.y * 0.001, _screen_scale())
	if now != _fitted:
		_fitted = now
		_layout()


## Screen pixels per interface unit (the window is stretched from the layout size).
func _screen_scale() -> float:
	var win := Vector2(DisplayServer.window_get_size())
	var view := get_viewport().get_visible_rect().size
	if DisplayServer.get_name() == "headless" or win.x <= 0.0 or view.x <= 0.0:
		return 1.0
	return win.x / view.x


func _layout() -> void:
	px = _screen_scale()
	var beside := minf((size.x - DETAIL_W - GAP) / ART.x, size.y / ART.y)
	var below := minf(size.x / ART.x, (size.y - DETAIL_H - GAP) / ART.y)
	side = beside >= below
	var n := maxf(1.0, floorf(maxf(beside, below) * px + 0.001))   # screen pixels per art pixel
	k = n / px
	var art := ART * k
	var want: Vector2
	var drect: Rect2
	if side:
		var dw := clampf(size.x - art.x - GAP, DETAIL_W, 380.0)
		want = Vector2((size.x - art.x - GAP - dw) / 2.0, (size.y - art.y) / 2.0)
		drect = Rect2(want.x + art.x + GAP, want.y + 8.0 * k, dw, art.y - 8.0 * k)
	else:
		var dh := clampf(size.y - art.y - GAP, DETAIL_H, 170.0)
		want = Vector2((size.x - art.x) / 2.0, (size.y - art.y - GAP - dh) / 2.0)
		drect = Rect2(want.x, want.y + art.y + GAP, art.x, dh)
	# put the art's corner on a whole screen pixel
	var g := get_global_transform_with_canvas().origin
	origin = ((g + want) * px).round() / px - g
	detail_rect = drect
	details.position = drect.position
	details.custom_minimum_size = drect.size
	details.size = drect.size
	_build_details()
	for i in cells.size():
		_place(cells[i], Rect2(CELL0 + CELL_STEP * Vector2(i % COLS, i / COLS), CELL))
	for slot in gear_buttons:
		_place(gear_buttons[slot], Rect2(GEAR_AT[slot], CELL))
	for i in tab_buttons.size():
		_place(tab_buttons[i], Rect2(TAB_X - 3 + TAB_STEP * i, 2, TAB_W + 6, BODY_TOP - 2))
	queue_redraw()


## The details keep the size the layout gave them (wrapped text is measured at that width).
func _fit_details() -> void:
	details.size = detail_rect.size


## Art pixels to local interface units.
func _r(r: Rect2) -> Rect2:
	return Rect2(origin + r.position * k, r.size * k)


func _place(b: Button, art: Rect2) -> void:
	var r := _r(art)
	b.position = r.position
	b.size = r.size
	b.custom_minimum_size = r.size


func _draw() -> void:
	var p := _player()
	var panel: Texture2D = _icon(PANEL)
	var strips: Texture2D = _icon(TAB_STRIPS)
	var ti: int = TABS.map(func(t): return t[0]).find(tab)
	draw_texture_rect_region(panel, _r(Rect2(0, STRIP, ART.x, ART.y - STRIP)), Rect2(0, STRIP, ART.x, ART.y - STRIP))
	draw_texture_rect_region(strips, _r(Rect2(0, 0, ART.x, STRIP)), Rect2(0, ti * STRIP, ART.x, STRIP))
	var font := get_theme_default_font()
	# the title where the tab strip leaves room, over the darkened game
	_outlined(font, Vector2(4, 13), "Pack", int(round(7.5 * k)), PALE)
	_outlined(font, Vector2(4, 25), "%d coins · %d of %d kinds" % [p.coins, p.inv.items.size(), p.inv.max_stacks], int(round(5.2 * k)), PALE)
	for i in TABS.size():
		var t: Texture2D = _icon(TABS[i][2])
		if t:
			draw_texture_rect(t, _r(Rect2(TAB_X + TAB_STEP * i, 10 if i == ti else 15, 16, 16)), false)
		if i < tab_buttons.size() and tab_buttons[i].has_focus():
			draw_rect(_r(tab_focus_rect(i)), PALE, false, 2.0)
	_draw_portrait(p, font)
	for slot in PlayerState.GEAR:
		var id: String = p.get(slot)
		var at: Vector2 = GEAR_AT[slot]
		if id != "" and p.inv.has(id):
			draw_texture_rect(_icon(ICON % id), _r(Rect2(at + Vector2(1, 1), Vector2(16, 16))), false)
		else:
			# an empty slot shows what goes there: the flat UI pack's brown glyph (owner, B7-013)
			draw_texture_rect(_icon("res://assets/ui/slot_%s.png" % slot), _r(Rect2(at + Vector2(2, 2), Vector2(14, 14))), false, Color(1, 1, 1, 0.8))
		if selected == "gear:" + slot:
			draw_rect(_r(Rect2(at, CELL)), PALE, false, k)
	var fs := maxi(11, int(round(5.5 * k)))
	for i in COLS * ROWS:
		var at := CELL0 + CELL_STEP * Vector2(i % COLS, i / COLS)
		if locked(i):
			_draw_lock(at)
			continue
		if i >= shown.size():
			continue
		var id: String = shown[i]
		var icon: Texture2D = _icon(ICON % id)
		if icon:
			draw_texture_rect(icon, _r(Rect2(at + Vector2(1, 1), Vector2(16, 16))), false)
		var n := p.inv.count(id)
		if n > 1:
			var s := str(n)
			var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos := origin + (at + CELL) * k - Vector2(w + 0.5 * k, 0.8 * k)
			draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(3, int(k * 1.2)), INK)
			draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PALE)
		if _slot_of(id) != "":
			draw_rect(_r(Rect2(at + Vector2(1, 1), Vector2(4, 4))), INK)       # worn: a gold mark in the corner
			draw_rect(_r(Rect2(at + Vector2(1.5, 1.5), Vector2(3, 3))), GOLD)
		if id == selected:
			draw_rect(_r(Rect2(at, CELL)), PALE, false, k)


## The art-pixel rectangle a focused tab is outlined with: its icon plus a pixel round it, the size
## of a bag cell, so tab, gear slot and bag cell highlights all fit their slot.
func tab_focus_rect(i: int) -> Rect2:
	var ti: int = TABS.map(func(t): return t[0]).find(tab)
	return Rect2(TAB_X + TAB_STEP * i - 1, (10 if i == ti else 15) - 1, 18, 18)


func _outlined(font: Font, art_pos: Vector2, s: String, size: int, colour: Color) -> void:
	var pos := origin + art_pos * k
	draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(4, size / 4), Color(0.1, 0.06, 0.03))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)


## The player's idle figure in the portrait frame, at a whole number of screen pixels per sprite
## pixel, and their name on the plate below.
func _draw_portrait(p: PlayerState, font: Font) -> void:
	var sheet: Texture2D = _icon(p.sprite)
	if sheet:
		var inside := _r(PORTRAIT)
		var m := floorf(minf(inside.size.x / FIGURE.size.x, inside.size.y / FIGURE.size.y) * px) / px
		var fig := FIGURE.size * m
		var at := ((get_global_transform_with_canvas().origin + inside.get_center() - fig / 2.0) * px).round() / px \
			- get_global_transform_with_canvas().origin
		draw_texture_rect_region(sheet, Rect2(at, fig), FIGURE)
	var fs := maxi(11, int(round(5.0 * k)))
	var plate := _r(PLATE)
	var nm := p.name
	var w := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := Vector2(plate.get_center().x - w / 2.0, plate.get_center().y + fs * 0.36)
	draw_string(font, pos, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


## A locked cell: darkened, with a small padlock drawn in art pixels.
func _draw_lock(at: Vector2) -> void:
	draw_rect(_r(Rect2(at + Vector2(1, 1), CELL - Vector2(2, 2))), Color(0.2, 0.13, 0.08, 0.55))
	var c := Color8(70, 50, 36)
	var hi := Color8(150, 120, 80)
	draw_rect(_r(Rect2(at + Vector2(6, 4), Vector2(6, 2))), c)      # shackle
	draw_rect(_r(Rect2(at + Vector2(6, 4), Vector2(1, 5))), c)
	draw_rect(_r(Rect2(at + Vector2(11, 4), Vector2(1, 5))), c)
	draw_rect(_r(Rect2(at + Vector2(5, 8), Vector2(8, 6))), c)      # body
	draw_rect(_r(Rect2(at + Vector2(6, 9), Vector2(6, 1))), hi)
	draw_rect(_r(Rect2(at + Vector2(8, 10), Vector2(2, 2))), Color8(30, 20, 14))   # keyhole
