class_name GameUI
extends CanvasLayer
## HUD and panels, built in code. Large touch targets (at least 48 px) and readable text.

const ICON := "res://assets/icons/%s.png"
const UI := "res://assets/ui/%s.png"
# the flat UI pack's dark scheme (Flat Game UI Icon Pack, set 3), recoloured from navy to wood brown
const WINDOW := Color8(43, 29, 19)
const SLATE := Color8(111, 74, 44)          # the button tile's colour (tools/import_game_assets.py UI_WOOD)
const PALE := Color8(236, 214, 170)          # parchment: focus outlines, slider fill
const BAR_COLOURS := {"hp": Color8(173, 34, 19), "hunger": Color8(122, 176, 58), "stamina": Color8(222, 178, 64)}

var main
var root: Control
var hud: Control
var bars := {}
var coins_label: Label
var clock_label: Label
var prompt_label: Label
var prompt_box: PanelContainer
var prompt_icon: TextureRect
var log_box: VBoxContainer
var toast: Label
var toast_t := 0.0
var action_bar: ProgressBar
var panel: PanelContainer
var panel_kind := ""
var panel_body: VBoxContainer
var title_label: Label
var top_row: HBoxContainer     # the window's title tab and X (the pack window draws its own)
var close_btn: Button
var touch_bar: HBoxContainer
var attack_btn: Button
var recenter_btn: Button       # shown while the camera is looking around, away from the player
var prompt_text := ""
var scheme := "kbm"
const JOURNAL_PER_PAGE := 6    # lines on a journal page (a day heading counts as one)
const PARCHMENT := Color8(236, 222, 186)
const INK := Color8(58, 38, 22)
const LOG_LINES := 2           # village events shown at once, newest last
const LOG_SECONDS := 3.0       # how long each stays before fading
const PROMPT := "res://assets/prompts/%s.png"
const USE_ICON := {"kbm": "keyboard_e", "gamepad": "xbox_button_a", "touch": "touch_tap"}
# the controls list, per scheme: [prompt icons, what they do] (Kenney Input Prompts)
const CONTROLS := {
	"touch": [[["touch_tap"], "Tap the ground to walk there; tap next to someone or something to use it"],
		[["touch_finger_one"], "Attack turns attack mode on; then tap who to attack, and tap them again to strike"],
		[["touch_zoom_in"], "Pinch to zoom"],
		[["touch_swipe_two_move"], "Drag with two fingers to look around; Recenter brings the view back to you"],
		[["touch_finger_one"], "Map opens the village map; tap a spot on it to look there"]],
	"kbm": [[["keyboard_w", "keyboard_a", "keyboard_s", "keyboard_d"], "Move"],
		[["mouse_left"], "Walk to where you click, or use what you click next to you"],
		[["keyboard_e"], "Use"], [["keyboard_space"], "Swing at what is in front of you"],
		[["mouse_right"], "Attack whoever you click"], [["keyboard_f"], "Fireball (once learned)"],
		[["keyboard_i"], "Pack"], [["keyboard_l"], "Skills"], [["keyboard_b"], "Journal"], [["keyboard_escape"], "Menu"],
		[["mouse_scroll"], "Zoom"], [["mouse_scroll", "mouse_move"], "Hold the wheel and drag to look around"],
		[["keyboard_c"], "Recenter the view on you"], [["keyboard_m"], "Village map"]],
	"gamepad": [[["xbox_stick_l"], "Move"], [["xbox_button_a"], "Use, or choose in a window"],
		[["xbox_button_x"], "Swing at what is in front of you"], [["xbox_button_y"], "Fireball (once learned)"],
		[["xbox_button_view"], "Pack"], [["xbox_rb"], "Skills"], [["xbox_button_menu"], "Menu (the journal is there)"],
		[["xbox_button_b"], "Close a window"],
		[["xbox_stick_r"], "Look around"], [["xbox_stick_r_press"], "Recenter the view on you"], [["xbox_lb"], "Village map"]],
}
# On a phone the interface keeps at least this far from the screen edges (interface units; the layout
# is 450 high): rounded corners on common phones cut off less than this.
const CORNER_MARGIN := Vector2(28, 14)
const BUTTON_MIN_WIDTH := 260.0       # window buttons are at least this wide, else as wide as their text
const PICKPOCKET_REACH := 1.8      # tiles: the talk window offers "Pick <name>'s pocket" this close
const SCHEME_NAMES :={"touch": "Touch", "kbm": "Keyboard and mouse", "gamepad": "Gamepad"}


func build(m) -> void:
	main = m
	layer = 20
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.theme = _theme()
	_build_hud()
	_build_panel()
	fit_safe_area()
	get_viewport().size_changed.connect(fit_safe_area)


## Keep the whole interface inside the part of the screen that shows: the device's safe area (notches,
## cutouts, system bars), and on a phone at least CORNER_MARGIN from the edges, so windows, the
## status box and the corner buttons are not cut off by rounded screen corners.
func fit_safe_area() -> void:
	var win := Vector2(DisplayServer.window_get_size())
	var view := get_viewport().get_visible_rect().size
	var inset := [0.0, 0.0, 0.0, 0.0]               # left, top, right, bottom, in interface units
	if win.x > 0 and win.y > 0 and DisplayServer.get_name() != "headless":
		var safe := Rect2(DisplayServer.get_display_safe_area())
		var k := view / win
		inset = [maxf(safe.position.x, 0.0) * k.x, maxf(safe.position.y, 0.0) * k.y,
			maxf(win.x - safe.end.x, 0.0) * k.x, maxf(win.y - safe.end.y, 0.0) * k.y]
	if main.settings.phone:
		inset = [maxf(inset[0], CORNER_MARGIN.x), maxf(inset[1], CORNER_MARGIN.y),
			maxf(inset[2], CORNER_MARGIN.x), maxf(inset[3], CORNER_MARGIN.y)]
	root.offset_left = inset[0]
	root.offset_top = inset[1]
	root.offset_right = -inset[2]
	root.offset_bottom = -inset[3]


## A dark box behind text drawn over the map, so it reads on bright ground.
func _backed(l: Label) -> void:
	var s := _style(Color(WINDOW, 0.88))
	s.set_content_margin_all(8)
	l.add_theme_stylebox_override("normal", s)


## Every button, field and slider is drawn with the UI pack's slate button tile; windows in its
## near-black, square like the pack's.
func _theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22
	var tex: Texture2D = load(UI % "button")
	var states := {"normal": Color(1, 1, 1), "hover": Color(1.35, 1.35, 1.4), "pressed": Color(0.7, 0.7, 0.75),
		"disabled": Color(0.55, 0.55, 0.55), "hover_pressed": Color(1.2, 1.2, 1.25)}
	for k in states:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.modulate_color = states[k]
		sb.set_content_margin_all(10)
		t.set_stylebox(k, "Button", sb)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = PALE
	focus.set_border_width_all(2)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", PALE)
	t.set_color("font_disabled_color", "Button", Color(0.6, 0.6, 0.62))
	for k in ["normal", "focus", "read_only"]:
		var le := StyleBoxTexture.new()
		le.texture = tex
		le.set_content_margin_all(10)
		if k == "focus":
			t.set_stylebox(k, "LineEdit", focus)
		else:
			t.set_stylebox(k, "LineEdit", le)
	var track := StyleBoxTexture.new()
	track.texture = tex
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", track)
	var filled := StyleBoxFlat.new()
	filled.bg_color = PALE
	filled.content_margin_top = 6
	filled.content_margin_bottom = 6
	t.set_stylebox("grabber_area", "HSlider", filled)
	t.set_stylebox("grabber_area_highlight", "HSlider", filled)
	t.set_stylebox("panel", "PanelContainer", _style(WINDOW))
	t.set_color("font_color", "Label", Color8(246, 236, 214))
	return t


func _style(color: Color, border := SLATE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(2)
	s.set_content_margin_all(10)
	return s


## A button showing one of the UI pack's icon tiles (the tile is the button), with a caption under it.
func _tile_button(icon: String, caption: String, size: float) -> Button:
	var b := Button.new()
	b.icon = load(UI % icon)
	b.expand_icon = true
	b.text = caption
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.flat = true
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_outline_color", Color.BLACK)
	b.add_theme_constant_override("outline_size", 5)
	b.custom_minimum_size = Vector2(size, size + (22.0 if caption != "" else 0.0))
	return b


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _style(Color(WINDOW, 0.88)))
	box.position = Vector2(12, 12)
	hud.add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)
	for b in [["hp", "health", "Health"], ["hunger", "hunger", "Hunger"], ["stamina", "stamina", "Stamina"]]:
		var h := HBoxContainer.new()
		var ic := _ui_icon(b[1], 24)
		ic.tooltip_text = b[2]
		h.add_child(ic)
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(152, 14)
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.show_percentage = false
		var track := StyleBoxFlat.new()
		track.bg_color = SLATE
		pb.add_theme_stylebox_override("background", track)
		var fill := StyleBoxFlat.new()
		fill.bg_color = BAR_COLOURS[b[0]]
		pb.add_theme_stylebox_override("fill", fill)
		h.add_child(pb)
		v.add_child(h)
		bars[b[0]] = pb
	var row := HBoxContainer.new()
	row.add_child(_ui_icon("coins", 24))
	coins_label = Label.new()
	coins_label.custom_minimum_size = Vector2(56, 0)
	coins_label.add_theme_font_size_override("font_size", 18)
	row.add_child(coins_label)
	clock_label = Label.new()
	clock_label.custom_minimum_size = Vector2(104, 0)
	clock_label.add_theme_font_size_override("font_size", 18)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(clock_label)
	v.add_child(row)

	log_box = VBoxContainer.new()
	log_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	log_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	log_box.offset_right = -12
	log_box.offset_top = 12
	log_box.custom_minimum_size = Vector2(420, 0)
	log_box.add_theme_constant_override("separation", 4)
	log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(log_box)

	# what "use" would do here, with the key, pad button or touch icon for it
	prompt_box = PanelContainer.new()
	prompt_box.add_theme_stylebox_override("panel", _style(Color(WINDOW, 0.88)))
	prompt_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	prompt_box.offset_bottom = -96
	prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_box.visible = false
	var ph := HBoxContainer.new()
	prompt_icon = TextureRect.new()
	prompt_icon.custom_minimum_size = Vector2(40, 40)
	prompt_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prompt_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ph.add_child(prompt_icon)
	prompt_label = Label.new()
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.custom_minimum_size = Vector2(480, 0)
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ph.add_child(prompt_label)
	prompt_box.add_child(ph)
	hud.add_child(prompt_box)

	toast = Label.new()
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast.custom_minimum_size = Vector2(620, 0)
	toast.offset_bottom = -160
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.visible = false
	_backed(toast)
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
	touch_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	touch_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	touch_bar.offset_right = -10
	touch_bar.offset_bottom = -10
	touch_bar.add_theme_constant_override("separation", 8)
	hud.add_child(touch_bar)
	for b in [["Use", "interact", "use"], ["Attack", "attack", "attack"], ["Fire", "fireball", "fire"], ["Pack", "inventory", "pack"],
			["Skills", "skills", "skills"], ["Map", "map", "map"], ["Menu", "pause", "menu"]]:
		var btn := _tile_button(b[2], b[0], 72)
		btn.focus_mode = Control.FOCUS_NONE
		var act: String = b[1]
		btn.pressed.connect(func(): _touch_action(act))
		touch_bar.add_child(btn)
		if act == "attack":
			attack_btn = btn
	# Recenter sits above the touch bar's right end, in every control scheme, while looking around
	recenter_btn = _tile_button("recenter", "Recenter", 72)
	recenter_btn.focus_mode = Control.FOCUS_NONE
	recenter_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	recenter_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	recenter_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	recenter_btn.offset_right = -10
	recenter_btn.visible = false
	recenter_btn.pressed.connect(func(): main.recenter())
	hud.add_child(recenter_btn)


## The controls in use changed: touch buttons only for touch (unless set otherwise), and prompts
## name the key or pad button. With keys or a pad, panels get keyboard focus.
func set_scheme(s: String) -> void:
	scheme = s
	var mode: String = main.settings.touch_buttons
	touch_bar.visible = mode == "always" or (mode == "auto" and s == "touch")
	recenter_btn.offset_bottom = -10.0 - (104.0 if touch_bar.visible else 0.0)
	prompt(prompt_text)
	if is_open("title"):
		show_title(FileAccess.file_exists(main.SAVE_PATH))       # its controls list follows the scheme
	if panel.visible and s != "touch":
		_focus_first()


func set_attack_mode(on: bool) -> void:
	attack_btn.self_modulate = Color(1.0, 0.45, 0.4) if on else Color.WHITE
	attack_btn.text = "Attack ON" if on else "Attack"


func _ui_icon(name: String, size: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(UI % name)
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t


## Give the first control of the open window keyboard/pad focus, unless something in it has focus.
func _focus_first() -> void:
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and panel.is_ancestor_of(owner):
		return
	for c in panel_body.find_children("*", "Control", true, false):
		if (c is Button or c is LineEdit or c is Slider) and c.is_visible_in_tree() and not (c is Button and c.disabled):
			c.grab_focus()
			return


func _touch_action(act: String) -> void:
	match act:
		"interact":
			main.interact()
		"attack":
			main.attack_button()
		"fireball":
			main.fireball()
		"inventory":
			toggle_inventory()
		"skills":
			toggle_skills()
		"map":
			toggle_map()
		"pause":
			show_pause()


func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(WINDOW))
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["offset_left", "offset_top"]:
		panel.set(side, 8)
	for side in ["offset_right", "offset_bottom"]:
		panel.set(side, -8)
	panel.visible = false
	root.add_child(panel)
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	# the title in a slate tab, the pack's X tile to close, as in the pack's windows
	var top := HBoxContainer.new()
	top_row = top
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	var tab := StyleBoxTexture.new()
	tab.texture = load(UI % "button")
	tab.content_margin_left = 18
	tab.content_margin_right = 18
	tab.content_margin_top = 4
	tab.content_margin_bottom = 4
	title_label.add_theme_stylebox_override("normal", tab)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	top.add_child(gap)
	close_btn = _tile_button("close", "", 52)
	close_btn.pressed.connect(hide_all)
	top.add_child(close_btn)
	outer.add_child(top)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	bars.hp.max_value = p.hp_cap()
	bars.hp.value = p.hp
	bars.stamina.max_value = p.stamina_cap()
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
			toast.visible = false


func prompt(text: String) -> void:
	prompt_text = text
	prompt_label.text = text
	prompt_icon.texture = load(PROMPT % USE_ICON.get(scheme, "touch_tap"))
	prompt_box.visible = text != ""


## The controls for a scheme as rows of input icons and what they do.
func _controls_list(s: String) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	for row in CONTROLS[s]:
		var icons := HBoxContainer.new()
		icons.custom_minimum_size = Vector2(150, 0)
		for name in row[0]:
			var t := TextureRect.new()
			t.texture = load(PROMPT % name)
			t.custom_minimum_size = Vector2(40, 40)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icons.add_child(t)
		grid.add_child(icons)
		var l := Label.new()
		l.text = row[1]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", 18)
		grid.add_child(l)
	panel_body.add_child(grid)


func show_controls(back: Callable) -> void:
	_open("controls", "Controls", main.paused)
	_label("The game switches by itself to whichever you use.", 16)
	for s in [scheme] + ["touch", "kbm", "gamepad"].filter(func(x): return x != scheme):
		_label(SCHEME_NAMES[s] + (" (in use)" if s == scheme else ""), 22, Color(1, 0.85, 0.5))
		_controls_list(s)
	_button("Back", back)


func message(text: String) -> void:
	toast.text = text
	toast.visible = true
	toast_t = 4.0


func log_line(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 16)
	_backed(l)
	log_box.add_child(l)
	while log_box.get_child_count() > LOG_LINES:
		var c := log_box.get_child(0)
		log_box.remove_child(c)
		c.queue_free()
	# each line stays a few seconds, then fades away (the full record is under Menu)
	var tw := l.create_tween()
	tw.tween_interval(LOG_SECONDS)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)


# ---------------------------------------------------------------- panel helpers --------------
func modal() -> bool:
	return panel.visible


## True when a touch at this screen position lands on the interface rather than the map.
func blocks(pos: Vector2) -> bool:
	if panel.visible:
		return true
	for c in (touch_bar.get_children() if touch_bar.visible else []) + [hud.get_child(0), recenter_btn]:
		if c.visible and c.get_global_rect().has_point(pos):
			return true
	return false


func is_open(kind: String) -> bool:
	return panel.visible and panel_kind == kind


func hide_all() -> void:
	panel.visible = false
	hud.visible = true
	panel_kind = ""
	if main.world and main.running:
		main.paused = false


func _open(kind: String, title: String, pause := true) -> void:
	panel_kind = kind
	title_label.text = title.to_upper()
	close_btn.visible = not kind in ["title", "origin", "death", "creation"]
	for c in panel_body.get_children():
		panel_body.remove_child(c)
		c.queue_free()
	panel_body.size_flags_vertical = Control.SIZE_FILL
	panel.add_theme_stylebox_override("panel", _style(WINDOW))
	top_row.visible = true
	hud.visible = true
	for side in ["offset_left", "offset_top"]:
		panel.set(side, 8)
	for side in ["offset_right", "offset_bottom"]:
		panel.set(side, -8)
	panel.visible = true
	if pause:
		main.paused = true
	if scheme != "touch":
		_focus_first.call_deferred()


func _label(text: String, size := 18, color := Color8(246, 236, 214)) -> Label:
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
	if parent == null:
		# a button in a window is as wide as its words (at least BUTTON_MIN_WIDTH), centred, not a
		# bar across the screen (owner: "they are buttons")
		b.custom_minimum_size.x = BUTTON_MIN_WIDTH
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	_button("New game", func(): show_creation({}))
	_button("Settings", func(): show_settings(func(): show_title(FileAccess.file_exists(main.SAVE_PATH))))
	if not main.settings.phone:
		_button("Quit", func(): main.get_tree().quit())
	_button("Controls", func(): show_controls(func(): show_title(FileAccess.file_exists(main.SAVE_PATH))))
	_controls_list(scheme)


## Character creation: name, family, male or female, and a look (face and clothes) from
## game/data/appearances.json, with a preview of the sprite the player will walk around as.
func show_creation(spec: Dictionary) -> void:
	var looks: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/appearances.json")).looks
	var sx: String = spec.get("sex", "male")
	var look: String = spec.get("look", "")
	var mine := looks.filter(func(l): return l.sex == sx and l.outfit == "basic") + looks.filter(func(l): return l.sex == sx and l.outfit != "basic")
	if look == "" or mine.filter(func(l): return l.id == look).is_empty():
		look = mine[0].id
	_open("creation", "Who are you?", false)
	var names := HBoxContainer.new()
	panel_body.add_child(names)
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Your name"
	name_edit.text = spec.get("name", "")
	name_edit.max_length = 16
	name_edit.custom_minimum_size = Vector2(0, 52)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(name_edit)
	var fam_edit := LineEdit.new()
	fam_edit.placeholder_text = "Family name"
	fam_edit.text = spec.get("family", "")
	fam_edit.max_length = 16
	fam_edit.custom_minimum_size = Vector2(0, 52)
	fam_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(fam_edit)
	var current := func() -> Dictionary:
		return {"name": name_edit.text.strip_edges(), "family": fam_edit.text.strip_edges(), "sex": sx, "look": look}
	var sexes := HBoxContainer.new()
	panel_body.add_child(sexes)
	for choice in ["male", "female"]:
		var c: String = choice
		var b := _button(("> " if c == sx else "") + c.capitalize(), func():
			var nxt: Dictionary = current.call()
			nxt.sex = c
			nxt.look = ""
			show_creation(nxt), true, sexes)
		b.custom_minimum_size = Vector2(150, 52)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sexes.add_child(gap)
	_button("Back", func(): show_title(FileAccess.file_exists(main.SAVE_PATH)), true, sexes).custom_minimum_size = Vector2(120, 52)
	var begin := _button("Begin", func():
		var spec2: Dictionary = current.call()
		if spec2.name == "":
			message("Give your character a name.")
			return
		if spec2.family == "":
			spec2.family = "Wanderer"
		spec2.sprite = looks.filter(func(l): return l.id == look)[0].sprite
		main.new_game(spec2), true, sexes)
	begin.custom_minimum_size = Vector2(160, 52)
	var row := HBoxContainer.new()
	panel_body.add_child(row)
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(128, 128)
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture = _look_frame(looks.filter(func(l): return l.id == look)[0].sprite)
	row.add_child(preview)
	var grid := GridContainer.new()
	grid.columns = 4
	row.add_child(grid)
	for l in mine:
		var lid: String = l.id
		var b := Button.new()
		b.icon = _look_frame(l.sprite)
		b.expand_icon = true
		b.custom_minimum_size = Vector2(72, 72)
		b.tooltip_text = "%s clothes" % ("plain" if l.outfit == "basic" else "tunic")
		b.modulate = Color(1, 1, 1) if lid == look else Color(0.75, 0.75, 0.75)
		b.pressed.connect(func():
			var nxt: Dictionary = current.call()
			nxt.look = lid
			show_creation(nxt))
		grid.add_child(b)
	_label("Top row: plain clothes. Bottom row: a tunic.", 16)


func _look_frame(sheet: String) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = load(sheet)
	at.region = Rect2(8, 8, 16, 16)          # the figure within the first 32 x 32 frame
	return at


## The origin: a short, skippable story. Nothing in it is a quest.
func show_origin() -> void:
	var p: PlayerState = main.world.player
	_open("origin", "%s %s" % [p.name, p.family], true)
	_label("You worked another family's farm three valleys over until the harvest failed and the farmer could no longer feed you. There were hard words, and you left before dawn.")
	_label("You carry what you could: a rusty sword that was your father's, a pickaxe nobody wanted, a loaf of bread, an apple going soft, and five coins.")
	_label("This is the first village you have seen with smoke in its chimneys. A hundred people live here, and every one of them has their own work and their own worries. None of them owes you anything.")
	_label("Find a way to live.", 20, Color(1, 0.85, 0.5))
	_button("Begin", func():
		hide_all()
		main.resume_after_origin())


func show_pause() -> void:
	_open("pause", "Paused")
	_button("Resume", hide_all)
	_button("Save", func(): main.save_game())
	_button("Journal", func(): show_journal(-1))
	_button("Settings", func(): show_settings(show_pause))
	_button("Controls", func(): show_controls(show_pause))
	_button("Save and quit to title", func():
		main.save_game(false)
		main.running = false
		show_title(true))


## Settings: sound, display (windows only on a computer), interface size and touch buttons. Each
## change is applied and saved at once; `back` reopens the screen it came from.
func show_settings(back: Callable) -> void:
	var st: GameSettings = main.settings
	var was_paused: bool = main.paused
	_open("settings", "Settings", was_paused)
	for row in [["Master volume", "master"], ["Music", "music"], ["Sound effects", "sfx"]]:
		var key: String = row[1]
		var sl := HSlider.new()
		sl.min_value = 0
		sl.max_value = 100
		sl.step = 5
		sl.value = float(st.get(key)) * 100.0
		sl.custom_minimum_size = Vector2(320, 44)
		sl.value_changed.connect(func(v: float):
			st.set(key, v / 100.0)
			main.apply_settings())
		_setting_row(row[0], sl)
	if not st.phone:
		_choice("Display", ["windowed", "fullscreen", "borderless"], st.display, func(v):
			st.display = v)
		var sizes: Array = st.sizes_that_fit().map(func(z: Vector2i): return "%dx%d" % [z.x, z.y])
		var now := "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]
		_choice("Window size", sizes, now if now in sizes else sizes[-1], func(v):
			var xy: PackedStringArray = str(v).split("x")
			st.window_size = Vector2i(int(xy[0]), int(xy[1]))
			st.display = "windowed")
		_choice("VSync", ["on", "off"], "on" if st.vsync else "off", func(v): st.vsync = v == "on")
	_choice("Frame rate cap", ["none", "30", "60", "120"], "none" if st.max_fps == 0 else str(st.max_fps), func(v):
		st.max_fps = 0 if v == "none" else int(v))
	_choice("Interface size", ["small", "normal", "large"], st.ui_size, func(v): st.ui_size = v)
	_choice("On-screen buttons", ["auto", "always", "never"], st.touch_buttons, func(v): st.touch_buttons = v)
	_label("Controls switch by themselves to touch, gamepad or keyboard and mouse, whichever you use. Sound volumes take effect once the game has sounds.", 14)
	_button("Back", back)


func _setting_row(text: String, control: Control) -> void:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(control)
	panel_body.add_child(h)


## A setting with a few values: the button shows the current one and steps to the next.
func _choice(text: String, values: Array, current: String, set_value: Callable) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(220, 48)
	b.text = current.capitalize() if not current.contains("x") else current
	var i := [values.find(current)]
	b.pressed.connect(func():
		i[0] = (i[0] + 1) % values.size()
		var v: String = values[i[0]]
		set_value.call(v)
		b.text = v.capitalize() if not v.contains("x") else v
		main.apply_settings())
	_setting_row(text, b)


## The journal: the village record written into a book, two parchment pages at a time, under a
## heading for each day. `spread` is the pair of pages shown; -1 opens at the latest.
func show_journal(spread: int, quests_page := false) -> void:
	var items := _quest_items() if quests_page else _journal_items()
	var pages := maxi(1, ceili(float(items.size()) / JOURNAL_PER_PAGE))
	var spreads := ceili(pages / 2.0)
	spread = spreads - 1 if spread < 0 else clampi(spread, 0, spreads - 1)
	_open("journal", "Journal: quests" if quests_page else "Journal", true)
	var book := HBoxContainer.new()
	book.add_theme_constant_override("separation", 0)
	book.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_body.add_child(book)
	for side in 2:
		var page := spread * 2 + side
		var sheet := PanelContainer.new()
		var paper := StyleBoxFlat.new()
		paper.bg_color = PARCHMENT
		paper.border_color = Color8(120, 84, 48)
		paper.set_border_width_all(3)
		paper.set_corner_radius_all(3)
		paper.content_margin_left = 22
		paper.content_margin_right = 22
		paper.content_margin_top = 16
		paper.content_margin_bottom = 12
		sheet.add_theme_stylebox_override("panel", paper)
		sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sheet.custom_minimum_size = Vector2(0, 300)
		var lines := VBoxContainer.new()
		lines.add_theme_constant_override("separation", 6)
		sheet.add_child(lines)
		var on_page := items.slice(page * JOURNAL_PER_PAGE, (page + 1) * JOURNAL_PER_PAGE)
		if not on_page.is_empty() and not on_page[0].day:
			# a page that starts mid-day repeats the day's heading, as a diary would
			for k in range(page * JOURNAL_PER_PAGE - 1, -1, -1):
				if items[k].day:
					on_page.push_front({"day": true, "text": "%s, continued" % items[k].text})
					break
		for it in on_page:
			var l := Label.new()
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if it.day:
				l.text = it.text
				l.add_theme_font_size_override("font_size", 20)
				l.add_theme_color_override("font_color", Color8(122, 38, 22))
			else:
				l.text = it.text
				l.add_theme_font_size_override("font_size", 16)
				l.add_theme_color_override("font_color", INK)
			lines.add_child(l)
		var gap := Control.new()
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lines.add_child(gap)
		var num := Label.new()
		num.text = "%d" % (page + 1) if page < pages else ""
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if side == 1 else HORIZONTAL_ALIGNMENT_LEFT
		num.add_theme_font_size_override("font_size", 14)
		num.add_theme_color_override("font_color", Color(INK, 0.6))
		lines.add_child(num)
		book.add_child(sheet)
		if side == 0:
			var spine := ColorRect.new()
			spine.color = Color8(92, 58, 34)
			spine.custom_minimum_size = Vector2(10, 0)
			book.add_child(spine)
	var nav := HBoxContainer.new()
	panel_body.add_child(nav)
	var earlier := _button("Earlier", func(): show_journal(spread - 1, quests_page), spread > 0, nav)
	earlier.custom_minimum_size = Vector2(160, 48)
	var where := Label.new()
	where.text = "Pages %d–%d of %d" % [spread * 2 + 1, mini(spread * 2 + 2, pages), pages] if items.size() > 0 else "Nothing written yet"
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(where)
	var later := _button("Later", func(): show_journal(spread + 1, quests_page), spread < spreads - 1, nav)
	var other := _button("Village record" if quests_page else "Quests", func(): show_journal(-1, not quests_page), true, nav)
	other.custom_minimum_size = Vector2(200, 48)
	later.custom_minimum_size = Vector2(160, 48)


## The village record as journal lines: a heading when the day changes, then each entry with its
## time ("[Day 3  07:24] text" in the log).
## The player's quests as journal lines: the title as a heading, then who asked, what is wanted
## and whether it is ready.
func _quest_items() -> Array:
	var w: World = main.world
	var out := []
	for q in w.player.quests:
		var t := Quests.template(q.id)
		var giver: NPC = w.npc(int(q.giver))
		out.append({"day": true, "text": ("%s (story)" % t.title) if t.get("story", false) else str(t.title)})
		var who := "%s %s" % [giver.name, giver.family] if giver else "someone"
		if t.get("hire", false):
			out.append({"day": false, "text": "Work for %s, taken on day %d, for %d coins. It lapses if not done by the end of day %d." % [who, int(q.day), int(t.wage), int(q.day) + int(t.get("days", 1))]})
		else:
			out.append({"day": false, "text": "Asked by %s on day %d." % [who, int(q.day)]})
		var want: String
		if t.has("learn"):
			want = "Learn %s from %s (%d coins)." % [str(t.learn).capitalize(), who, int(GameData.b("fireball_price"))]
		elif t.has("need"):
			var need := []
			for id in t.need:
				need.append("%d %s (have %d)" % [int(t.need[id]), GameData.item_name(id).to_lower(), w.player.inv.count(id)])
			want = "Bring " + ", ".join(need) + "."
			if t.has("harvest"):
				want += " Cut it from their field (%d of %d cut)." % [int(q.get("harvested", 0)), int(t.harvest)]
			if t.has("teach"):
				want += " They will teach you %s." % str(GameData.skills[t.teach.skill].name)
		else:
			var target: NPC = w.npc(int(q.target))
			want = "Deal with %s." % (target.name if target else "the thief")
		out.append({"day": false, "text": want + ("  Ready: go back to them." if w.quests.ready(q) else "")})
	if out.is_empty():
		out.append({"day": false, "text": "No quests. Look for people with a green diamond over their head."})
	return out


func _journal_items() -> Array:
	var out := []
	var day := ""
	for entry in main.world.log_lines:
		var line: String = entry
		var close := line.find("] ")
		var stamp: String = line.substr(1, close - 1) if line.begins_with("[") and close > 0 else ""
		var text: String = line.substr(close + 2) if stamp != "" else line
		var parts := stamp.split("  ")
		var d: String = parts[0] if parts.size() == 2 else ""
		if d != day:
			day = d
			out.append({"day": true, "text": d})
		out.append({"day": false, "text": ("%s  %s" % [parts[1], text]) if parts.size() == 2 else text})
	return out


func show_death() -> void:
	var p: PlayerState = main.world.player
	_open("death", "%s %s has died" % [p.name, p.family])
	_label("Death is permanent, but the village and your family go on. What %s carried lies where they fell, for anyone to take. Your heir keeps the family house and the chest, but starts with only what a wanderer carries and must learn everything anew." % p.name)
	_button("Continue as the heir", func(): main.continue_as_heir())


# ---------------------------------------------------------------- people ---------------------
## A conversation: the villager's portrait, who they are, and what they say (Dialogue builds it from
## the simulation), with the choices under it. A question replaces what they say with the answer.
func show_talk(n: NPC) -> void:
	var w: World = main.world
	var said := Dialogue.opening(w, n)
	# the giver of an unfinished story quest speaks of it first
	var q: Dictionary = w.quests.active_from(n)
	if not q.is_empty() and Quests.template(q.id).get("story", false):
		said = w.quests.line(q, "offer")
	Dialogue.meet(w, n)
	_talk_view(n, said)


## The quest choices with this villager: their offer, or the request the player took on.
func _quest_choices(n: NPC, choices: GridContainer) -> void:
	var w: World = main.world
	var q: Dictionary = w.quests.active_from(n)
	if not q.is_empty() and not Quests.template(q.id).get("story", false):
		if w.quests.ready(q):
			_talk_choice(choices, "Here you are", func():
				var t := Quests.template(q.id)
				var thanks := w.quests.line(q, "thanks")
				var paid: int = w.quests.complete(q)
				if paid == -2:
					_talk_view(n, w.quests.line(q, "unpaid"))
					return
				var learned: String = w.quests.last_learned
				if t.get("hire", false):
					message("Work done: %s (+%d coins wage)" % [t.title, paid])
				else:
					message("Quest done: %s%s%s" % [t.title, (" (+%d coins)" % paid) if paid > 0 else "", (". " + learned) if learned != "" else ""])
				_talk_view(n, thanks, false, "", ("You learned: " + learned) if learned != "" else ""))
		else:
			_talk_choice(choices, "About your request", func(): _talk_view(n, w.quests.line(q, "waiting")))
		return
	var offer: Dictionary = w.quests.offer_of(n)
	if not offer.is_empty():
		_talk_choice(choices, "Need any help?", func():
			_talk_view(n, w.quests.line({"id": offer.id, "giver": n.id}, "offer"), true))
	# paid work (owner: the player can work and earn money): asked for, never marked
	if w.quests.hires(n):
		_talk_choice(choices, "Any work for me?", func():
			var job: Dictionary = w.quests.hire_offer(n)
			if job.is_empty():
				_talk_view(n, w.quests.no_work_line(n))
			else:
				_talk_view(n, w.quests.line({"id": job.id, "giver": n.id}, "offer"), true, job.id))


## "I'll do it" or "Not now" to an offer: the villager's quest, or (`hire`) the work they offered.
func _offer_choices(n: NPC, choices: GridContainer, hire := "") -> void:
	var w: World = main.world
	_talk_choice(choices, "I'll do it", func():
		var q: Dictionary = w.quests.accept(n, hire)
		if q.is_empty():
			message("You have too many tasks already (%d)." % int(GameData.b("quest_max_active")))
			_talk_view(n, Dialogue.opening(w, n))
			return
		if hire != "":
			message("Hired: %s. It is written in your journal." % Quests.template(q.id).title)
			_talk_view(n, "Good. Come and find me when it's done, and you'll have your wage.")
			return
		message("New quest: %s. It is written in your journal." % Quests.template(q.id).title)
		_talk_view(n, "Good. Come back when it's done."))
	_talk_choice(choices, "Not now", func(): _talk_view(n, Dialogue.opening(w, n)))


## `note` is a line under the speech, not spoken (what a teacher taught the player).
func _talk_view(n: NPC, said: String, offering := false, hire := "", note := "") -> void:
	var w: World = main.world
	_open("talk", Dialogue.full_name(n))
	var tall: float = main.settings.layout_height()
	panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL       # the talk fills the window; choices at the foot
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_body.add_child(row)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _style(SLATE, PALE))
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(frame)
	var face := TextureRect.new()
	face.texture = _look_frame(n.sprite)
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var side := clampf(roundf(tall * 0.32 / 16.0) * 16.0, 128.0, 224.0)      # whole multiples of the 16 px figure
	face.custom_minimum_size = Vector2(side, side)
	frame.add_child(face)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	var who := Label.new()
	who.text = Dialogue.describe(w, n)
	who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	who.add_theme_font_size_override("font_size", 20)
	who.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	right.add_child(who)
	var paper := StyleBoxFlat.new()
	paper.bg_color = PARCHMENT
	paper.border_color = Color8(120, 84, 48)
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(6)
	paper.set_content_margin_all(14)
	var speech_box := PanelContainer.new()
	speech_box.add_theme_stylebox_override("panel", paper)
	speech_box.custom_minimum_size = Vector2(0, side - 40.0)
	speech_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(speech_box)
	var speech := Label.new()
	speech.name = "Speech"
	speech.text = "“%s”" % said
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.add_theme_font_size_override("font_size", 22)
	speech.add_theme_color_override("font_color", INK)
	speech.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech_box.add_child(speech)
	if note != "":
		var learned := Label.new()
		learned.name = "Note"
		learned.text = note
		learned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		learned.add_theme_font_size_override("font_size", 20)
		learned.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
		right.add_child(learned)
	# the choices: what the old talk window offered, then questions, then goodbye
	var choices := GridContainer.new()
	choices.columns = 3
	choices.add_theme_constant_override("h_separation", 8)
	choices.add_theme_constant_override("v_separation", 8)
	panel_body.add_child(choices)
	if n.role == "bandit":
		_talk_choice(choices, "Goodbye", hide_all)
		_fit_talk(side, choices)
		return
	if offering:
		_offer_choices(n, choices, hire)
		_fit_talk(side, choices)
		return
	_quest_choices(n, choices)
	var sale: Array = w.brain.for_sale(n)
	var buys: Dictionary = NPCBrain.BUYS.get(w.brain.buy_role(n), {})
	if not sale.is_empty() or not buys.is_empty():
		_talk_choice(choices, "Trade", func(): show_trade(n))
	if n.id == w.sage_id:
		var price := int(GameData.b("fireball_price"))
		var known: bool = w.player.spells.get("fireball", false)
		_talk_choice(choices, "Learn Fireball (%d coins)" % price if not known else "You know Fireball", func():
			if w.player.coins >= price:
				w.player.coins -= price
				n.coins += price
				w.player.spells["fireball"] = true
				w.player.gain("magic", 100)
				var story: Dictionary = w.quests.active_from(n)
				var thanks := w.quests.line(story, "thanks") if not story.is_empty() else ""
				w.quests.on_learned("fireball")
				message("You learned Fireball. Press F (or the Fire button) to cast it; it uses stamina.")
				if thanks != "":
					_talk_view(n, thanks)
				else:
					hide_all()
			else:
				message("You need %d coins." % price), not known)
	if n.id == w.reeve_id:
		_talk_choice(choices, "Land and houses", func(): show_land(n))
	# owner rule: the player may pick the pocket of someone beside them (World.pickpocket)
	if w.player.pos.distance_to(n.pos) <= PICKPOCKET_REACH:
		_talk_choice(choices, "Pick pocket — theft", func(): main.pickpocket(n))
	_talk_choice(choices, "What do you do?", func(): _talk_view(n, Dialogue.work(w, n)))
	_talk_choice(choices, "How are things at home?", func(): _talk_view(n, Dialogue.home(w, n)))
	_talk_choice(choices, "Any news?", func(): _talk_view(n, Dialogue.news(w, n)))
	_talk_choice(choices, "Goodbye", hide_all)
	_fit_talk(side, choices)


## The talk sits at the foot of the screen, only as tall as it needs, so the village shows above
## it (on a phone it needs nearly the whole height).
func _fit_talk(side: float, choices: GridContainer) -> void:
	var rows := ceili(choices.get_child_count() / float(choices.columns))
	var needed := 76.0 + side + 34.0 + rows * 56.0 + 16.0
	panel.offset_top = maxf(8.0, root.get_rect().size.y - 8.0 - needed)


func _talk_choice(parent: Control, text: String, cb: Callable, enabled := true) -> void:
	var b := _button(text, cb, enabled, parent)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


## Someone asleep (owner rule: sleeping limits awareness, not interaction): wake them and talk, try
## their pocket while they sleep (easier; a fumble wakes them), or leave them be. Attacking works as
## on anyone (attack mode); the blow wakes them.
func show_sleeper(n: NPC) -> void:
	var w: World = main.world
	_open("sleeper", "%s %s, asleep" % [n.name, n.family], main.paused)
	_label("%s is asleep." % n.name)
	_button("Wake %s" % n.name, func():
		w.wake(n)
		hide_all()
		message("You wake %s." % n.name)
		show_talk(n))
	_button("Pick pocket while asleep — theft", func():
		hide_all()
		main.pickpocket(n))
	_button("Let them sleep", hide_all)


func show_trade(n: NPC) -> void:
	var w: World = main.world
	var p := w.player
	if w.at_post(n):
		_open("trade", "Buy from %s %s (%s)  ·  you have %d coins" % [n.name, n.family, w.shop_name(n), p.coins])
	else:
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
			var hot := p.stolen_count(id)
			_item_row(id, p.inv.count(id), "%d coins each%s" % [price, ("  ·  %d stolen" % hot) if hot > 0 else ""], "Sell", func():
				var r: Dictionary = w.player_sell(nn, id, price)
				if r.result == "sold":
					main._xp("trading", 2)
					show_trade(nn)
				elif r.result == "failed":
					message(r.text)
					show_trade(nn)
				else:
					hide_all()
					message(r.text), n.coins >= price)
	if not any:
		_label("Nothing you carry (they want: %s)." % ", ".join(buys.keys().map(func(k): return GameData.item_name(k))) if not buys.is_empty() else "They are not buying.", 15)
	if n.role != "bandit":
		var talker := n
		_button("Talk to %s" % n.name, func(): show_talk(talker))


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
		show_inventory()


## The pack window (scripts/ui/inventory_window.gd): Cozy Farm's inventory panel with the tabs, the
## character and gear slots and the bag grid, over the darkened game. `tab` is the tab to open.
func show_inventory(tab := "all") -> void:
	_open("inventory", "Pack")
	top_row.visible = false
	hud.visible = false               # the pack window shows the coins itself
	var dim := StyleBoxFlat.new()
	dim.bg_color = Color(0.05, 0.03, 0.02, 0.85)
	panel.add_theme_stylebox_override("panel", dim)
	for side in ["offset_left", "offset_top", "offset_right", "offset_bottom"]:
		panel.set(side, 0)
	panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var win := InventoryWindow.new()
	panel_body.add_child(win)
	win.setup(self, tab)


## The open pack window, or null.
func inventory_window() -> InventoryWindow:
	return panel_body.get_node_or_null("InventoryWindow") as InventoryWindow if is_open("inventory") else null


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


# ---------------------------------------------------------------- village map ----------------
func toggle_map() -> void:
	if is_open("map"):
		hide_all()
	elif not modal() and main.running and main.world != null:
		show_map()


## The whole village drawn small, with the named places, your home and where you are
## (scripts/ui/village_map_view.gd). Close it with Map, the X, M, the pad's B or LB, or Back.
func show_map() -> void:
	_open("map", "Village map")
	var m := VillageMapPanel.new()
	panel_body.add_child(m)
	m.setup(main)


func show_recenter(on: bool) -> void:
	recenter_btn.visible = on


# ---------------------------------------------------------------- building / home ------------
func show_build(pl: Dictionary) -> void:
	var w: World = main.world
	var p := w.player
	_open("build", "Building plot")
	var price := w.property.price_of(pl)
	var rent := w.property.rent_of(pl)
	if w.property.for_sale(pl):
		_label("The manor sells this plot for %d coins, or leases it for %d coins a week (the first week paid now). The coins go to the manor. Once it is yours, you can mark out a house: a wooden frame appears, you bring the materials, and when the last load is in, the house stands. A house on leased ground goes to the manor if the lease ends." % [price, rent])
		_button("Buy for %d coins" % price, func():
			var why: String = w.property.buy(pl, World.PLAYER)
			if why != "":
				message(why)
				return
			show_build(pl), p.coins >= price)
		_button("Lease for %d coins a week" % rent, func():
			var why: String = w.property.lease(pl, World.PLAYER)
			if why != "":
				message(why)
				return
			show_build(pl), p.coins >= rent)
		return
	if not w.holds(World.PLAYER, pl):
		_label("This plot is %s's." % w.ref_name(w.holder_of(pl)))
		return
	if w.tenant_of(pl) == World.PLAYER:
		_label("You lease this plot from the manor: %d coins a week, next due on day %d%s." % [int(pl.rent), int(pl.due_day) + 1,
				(", %d owed" % int(pl.arrears)) if int(pl.get("arrears", 0)) > 0 else ""], 16)
	if pl.site.is_empty():
		var cost: Dictionary = GameData.b("house_cost")
		_label("Mark out a house here? It will need: " + ", ".join(cost.keys().map(func(k): return "%d %s" % [int(cost[k]), GameData.item_name(k)])))
		_button("Mark out a house", func():
			w.start_site(pl)
			show_build(pl))
		return
	if pl.site.done:
		_label("Your house stands here. The reeve keeps the manor's land office: buy, lease or sell land and houses there.")
		return
	var need: Dictionary = pl.site.need
	var done_part := w.site_progress(pl)
	_label("Building: House, %d%% done. Still needed:" % roundi(done_part * 100.0))
	var bar := ProgressBar.new()
	bar.value = done_part * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.47, 0.72, 0.29)
	bar.add_theme_stylebox_override("fill", fill)
	panel_body.add_child(bar)
	for id in need:
		_item_row(id, int(need[id]), "(you carry %d)" % p.inv.count(id), "", func(): pass)
	_button("Deliver what I carry", func():
		if w.deliver(pl, p.inv):
			p.home = "house_" + pl.id
			message("Your house is finished! Use its door to rest and to store things.")
			hide_all()
		else:
			show_build(pl))
	_button("Give up the site (all materials come back)", func():
		var back := w.cancel_site(pl, p.inv)
		var words: Array = back.keys().map(func(k): return "%d %s" % [int(back[k]), GameData.item_name(k).to_lower()])
		message("The frame comes down. You take back %s." % (", ".join(words) if not words.is_empty() else "nothing; none was delivered"))
		show_build(pl))


## The manor's land office, kept by the reeve (owner rules: the manor sells and lets land and houses,
## rent weekly): what the family holds, to make a home of, sell back or give up, and what the manor
## offers, to buy or lease. Prices are provisional (balance.json "_property_note").
func show_land(reeve: NPC = null) -> void:
	var w: World = main.world
	_open("land", "Land and houses")
	_label("The manor's land office. You have %d coins; rent is taken from your purse each week. Selling or giving up your home moves you to another house you hold, or leaves you homeless (the family chest waits for your next house)." % w.player.coins, 16)
	var again := func(): show_land(reeve)
	_label("Yours:", 20, Color(1, 0.85, 0.5))
	var mine: Array = w.property.held_by(World.PLAYER)
	if mine.is_empty():
		_label("Nothing yet.", 16)
	for t in mine:
		_deal_row(t, again)
	_label("The manor offers:", 20, Color(1, 0.85, 0.5))
	var offers: Array = w.property.market()
	if offers.is_empty():
		_label("Nothing for sale or to let just now.", 16)
	for t in offers:
		_deal_row(t, again)
	if reeve != null:
		_button("Talk to %s" % reeve.name, func(): show_talk(reeve))


## One house or piece of land on its own (at its door).
func show_deal(thing: Dictionary) -> void:
	var w: World = main.world
	_open("land", "House" if w.property.is_home(thing) else "Land")
	_label("You have %d coins. The reeve at the manor keeps the land office." % w.player.coins, 16)
	_deal_row(thing, func(): show_deal(thing))


## A line of the land office: what it is and its terms, with the deals the player can make.
func _deal_row(t: Dictionary, again: Callable) -> void:
	var w: World = main.world
	var pr: Property = w.property
	var p := w.player
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 17)
	var text := pr.describe(t)
	text = text[0].to_upper() + text.substr(1)
	h.add_child(l)
	var act := func(result: String, done: String) -> void:
		message(result if result != "" else done)
		again.call()
	if w.holds(World.PLAYER, t):
		var head: Dictionary = pr.head(t)
		if w.owner_of(head) == World.PLAYER:
			text += ": yours"
		else:
			text += ": leased, %d coins a week, next due day %d" % [int(head.rent), int(head.due_day) + 1]
			if int(head.get("arrears", 0)) > 0:
				text += ", %d owed" % int(head.arrears)
		for r in pr.unit(t):
			if pr.is_home(r) and str(r.id) == p.home:
				text += " (your home)"
			elif pr.is_home(r):
				var id := str(r.id)
				_button("Make it home", func(): act.call(pr.set_home(id), "This is your home now: rest and keep the family chest here."), true, h)
		if w.owner_of(head) == World.PLAYER:
			var value := pr.sale_value(t)
			_button("Sell (%d)" % value, func(): act.call(pr.sell(t, World.PLAYER), "Sold to the manor for %d coins." % value), true, h)
		else:
			_button("End lease", func(): act.call(pr.end_lease(t, World.PLAYER), "The lease is ended."), true, h)
	else:
		var price := pr.price_of(t)
		var rent := pr.rent_of(t)
		text += ": %d coins, or %d a week" % [price, rent]
		_button("Buy (%d)" % price, func(): act.call(pr.buy(t, World.PLAYER), "Bought from the manor for %d coins." % price), p.coins >= price and pr.for_sale(t), h)
		_button("Lease (%d a week)" % rent, func(): act.call(pr.lease(t, World.PLAYER), "Leased for %d coins a week; the first week is paid." % rent), p.coins >= rent and pr.for_sale(t), h)
	l.text = text
	panel_body.add_child(h)


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
			if w.transfer(p.chest, p.inv, iid, p.chest.count(iid)):
				p.take_marks(iid)
			show_home())
	_label("Your pack:", 20, Color(1, 0.85, 0.5))
	for id in p.inv.ids():
		var iid: String = id
		_item_row(id, p.inv.count(id), "", "Store", func():
			if w.transfer(p.inv, p.chest, iid, p.inv.count(iid)):
				p.store_marks(iid)
			show_home())
