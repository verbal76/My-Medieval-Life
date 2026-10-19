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
var hud_root: Control            # the HUD's own full-screen root: system bars kept clear, cutouts avoided per element
var status_box: PanelContainer   # health, hunger, stamina, coins and the clock, in the top-left corner
var test_safe := Rect2()         # tests only: a pretend display safe area (window pixels)
var test_cutouts: Array = []     # tests only: pretend display cutouts (camera holes), Rect2 in window pixels
var bars := {}
var bar_labels := {}             # meter key -> the words drawn on its bar ("Health 80/100")
var bar_danger := {}             # meter key -> true while that meter is low (B8-019)
var coins_label: Label
var clock_label: Label
var prompt_label: Label
var prompt_box: PanelContainer
var prompt_icon: TextureRect
var log_box: VBoxContainer
var toast: Label
var toast_t := 0.0
var toast_bottom := -160.0     # where the toast's bottom edge sits (above the prompt and the placing bar)
var action_bar: ProgressBar
var panel: PanelContainer
var panel_kind := ""
var panel_back := Callable()   # what X, Esc and the pad's B do in the open window (PL1-01); empty: close it
var inner_back := Callable()   # a window's own step back first (the wiki's previous page); returns true when it stepped
var settings_tab := "audio"
var panel_body: VBoxContainer
var title_label: Label
var top_row: HBoxContainer     # the window's title tab and X (the pack window draws its own)
var close_btn: Button
var touch_bar: HBoxContainer
var attack_btn: Button
var gather_btn: Button
var recenter_btn: Button       # shown while the camera is looking around, away from the player
var prompt_text := ""
var scheme := "kbm"
var place_bar: PanelContainer  # while placing a building: whether it may go here, Place and Cancel
var place_label: Label
## Where a new player finds money (owner, 2026-10-18): shown when a game starts and kept on the
## journal's quests page.
const EARNING_HINT := "For paid work, ask farmers, miners and woodcutters \"Any work for me?\", or the reeve at the manor. Sell ore to the smith, logs to the carpenter, hides to the tanner, and goods at the market stalls."
const OPENING_HINT := "For paid work, ask farmers, miners, woodcutters or the reeve \"Any work for me?\". Who buys what is in the journal."
const JOURNAL_PER_PAGE := 6    # lines on a journal page (a day heading counts as one)
const PARCHMENT := Color8(236, 222, 186)
const INK := Color8(58, 38, 22)
# the journal's Resources & Gathering page (show_resources): its words come from resources.json
# through ResourceNodes, except how Gather mode works (main.gd gather_button, select_resource,
# _gather_step) and the words for the registry's depletion and use kinds
const GATHER_STEPS := ["Activate Gather: tap the Gather button.",
	"Select a resource: tap or click it on the map.",
	"Your character walks to it and gathers it automatically.",
	"Gathering goes on until it is used up or something interrupts it: you walk away, you are hurt, your pack is full, or the tool is gone.",
	"Tap Gather again to leave Gather mode."]
const GATHER_KEYS := "Keyboard and mouse: press G, then click a resource, or stand in front of one and press Use (E)."
const GATHER_PAD := "Gamepad: press the D-pad down, then A in front of a resource. B closes this journal."
const RES_DEPLETION := {"finite": "Runs out: once worked out it does not come back.", "regrows": "Replenishes: it grows back.",
	"ripens": "Replenishes: it is sown and ripens again.", "breeds": "Replenishes: the animals breed."}
const RES_USE_KINDS := {"recipe": "Crafting", "building": "Building", "food": "Food", "fuel": "Fuel", "buyer": "Trade",
	"export": "Trade", "quest": "Quest", "manor_job": "Manor work", "feed": "Feed", "home_cooking": "Cooking",
	"granary": "Granary", "equip": "Equipment", "tool": "Tool"}
const RES_HEAD := Color8(122, 38, 22)       # the journal's heading red
const RES_WARN := Color8(150, 34, 14)
const RES_CARD := Color8(226, 206, 162)
const LOG_LINES := 2           # village events shown at once, newest last
const LOG_SECONDS := 3.0       # how long each stays before fading
const DANGER_AT := 0.25        # a meter below this fraction of its cap turns red and blinks
const DANGER_COLOUR := Color8(228, 52, 36)
const PROMPT_MAX_W := 360.0    # the contextual prompt and the message toast wrap at this width
const TOAST_MAX_W := 460.0
const METERS := {
	"hp": ["Health", "health", "Health: how much you can take. Rest at home, eat food that heals, or drink a tonic. At 0 you die."],
	"hunger": ["Food", "bread", "Food: falls slowly as time passes. At 0 you starve and lose health. Eat from the Pack to refill it."],
	"stamina": ["Stamina", "stamina", "Stamina: spent by casting Fireball. It refills by itself."],
}
const GAIN_SECONDS := 1.5      # a gain line ("+2 red berries") stays this long, then fades
const PROMPT := "res://assets/prompts/%s.png"
const USE_ICON := {"kbm": "keyboard_e", "gamepad": "xbox_button_a", "touch": "touch_tap"}
# the controls list, per scheme: [prompt icons, what they do] (Kenney Input Prompts)
const CONTROLS := {
	"touch": [[["touch_tap"], "Tap the ground to walk there; tap someone or something to walk to it and use it"],
		[["touch_finger_one"], "Gather turns gather mode on; then tap a seam, tree, ripe field, flower, berry bush or game to gather it until it runs out"],
		[["touch_finger_one"], "Attack turns attack mode on; then tap who to attack, and tap them again to strike"],
		[["touch_zoom_in"], "Pinch to zoom"],
		[["touch_swipe_two_move"], "Drag with two fingers to look around; Recenter brings the view back to you"],
		[["touch_finger_one"], "Map opens the village map; tap a spot on it to look there"]],
	"kbm": [[["keyboard_w", "keyboard_a", "keyboard_s", "keyboard_d"], "Move"],
		[["mouse_left"], "Walk to where you click, or use what you click next to you"],
		[["keyboard_e"], "Use"], [["keyboard_g"], "Gather mode: click a resource (or Use in front of one) to gather it until it runs out"],
		[["keyboard_space"], "Swing at what is in front of you"],
		[["mouse_right"], "Attack whoever you click"], [["keyboard_f"], "Fireball (once learned)"],
		[["keyboard_i"], "Pack"], [["keyboard_l"], "Skills"], [["keyboard_b"], "Journal"], [["keyboard_escape"], "Menu"],
		[["mouse_scroll"], "Zoom"], [["mouse_scroll", "mouse_move"], "Hold the wheel and drag to look around"],
		[["keyboard_c"], "Recenter the view on you"], [["keyboard_m"], "Village map"],
		[["keyboard_shift"], "Hold to sprint (it uses stamina)"], [["keyboard_q", "keyboard_tab"], "Next choice, when more than one thing can be used here"],
		[["keyboard_escape", "mouse_right"], "While working: stop at once"]],
	"gamepad": [[["xbox_stick_l"], "Move"], [["xbox_button_a"], "Use, or choose in a window"],
		[["xbox_button_x"], "Swing at what is in front of you"], [["xbox_dpad_down"], "Gather mode: A in front of a resource gathers it until it runs out"], [["xbox_button_y"], "Fireball (once learned)"],
		[["xbox_button_view"], "Pack"], [["xbox_rb"], "Skills"], [["xbox_button_menu"], "Menu (the journal is there)"],
		[["xbox_button_b"], "Close a window"],
		[["xbox_stick_r"], "Look around"], [["xbox_stick_r_press"], "Recenter the view on you"], [["xbox_lb"], "Village map"], [["xbox_lt", "xbox_rt"], "In a window: step through its buttons"],
		[["xbox_lt"], "Sprint on or off (it uses stamina)"], [["xbox_dpad_left", "xbox_dpad_right"], "Next choice, when more than one thing can be used here"],
		[["xbox_button_b"], "While working: stop at once"]],
}
# On a phone the interface keeps at least this far from the screen edges (interface units; the layout
# is 450 high): rounded corners on common phones cut off less than this.
const CORNER_MARGIN := Vector2(28, 14)
## The HUD's distance from the screen edges (interface units): small and the same in every corner.
## Windows keep CORNER_MARGIN; the HUD sits closer, moving only off a camera cutout it would overlap.
const HUD_MARGIN := {"desktop": 10.0, "phone": 12.0}
const BUTTON_MIN_WIDTH := 260.0       # window buttons are at least this wide, else as wide as their text
const PICKPOCKET_REACH := 1.8      # tiles: the talk window offers "Pick <name>'s pocket" this close
const SCHEME_NAMES :={"touch": "Touch", "kbm": "Keyboard and mouse", "gamepad": "Gamepad"}


func build(m) -> void:
	main = m
	layer = 20
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)                # under the windows' root: windows draw over the HUD
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.theme = _theme()
	hud_root.theme = root.theme
	_build_hud()
	_build_panel()
	fit_safe_area()
	get_viewport().size_changed.connect(fit_safe_area)


## Keep the whole interface inside the part of the screen that shows: the device's safe area (notches,
## cutouts, system bars), and on a phone at least CORNER_MARGIN from the edges, so windows, the
## status box and the corner buttons are not cut off by rounded screen corners.
func fit_safe_area() -> void:
	var inset: Array = _display_insets().safe       # left, top, right, bottom, in interface units
	if main.settings.phone:
		inset = [maxf(inset[0], CORNER_MARGIN.x), maxf(inset[1], CORNER_MARGIN.y),
			maxf(inset[2], CORNER_MARGIN.x), maxf(inset[3], CORNER_MARGIN.y)]
	root.offset_left = inset[0]
	root.offset_top = inset[1]
	root.offset_right = -inset[2]
	root.offset_bottom = -inset[3]
	_fit_hud()


## The display's safe area and cutouts in interface units ({safe: [left, top, right, bottom] insets,
## cutouts: [Rect2]}); the tests can pretend a phone with test_safe and test_cutouts.
func _display_insets() -> Dictionary:
	var win := Vector2(DisplayServer.window_get_size())
	var view := get_viewport().get_visible_rect().size
	if win.x <= 0 or win.y <= 0 or DisplayServer.get_name() == "headless":
		win = view                     # no real window (headless tests): window pixels are interface units
	var safe := test_safe
	var holes: Array = test_cutouts
	var real := DisplayServer.get_name() != "headless" and win.x > 0 and win.y > 0
	if test_safe == Rect2() and real:
		safe = Rect2(DisplayServer.get_display_safe_area())
	if test_cutouts.is_empty() and real and DisplayServer.has_method("get_display_cutouts"):
		holes = DisplayServer.get_display_cutouts()
	if safe == Rect2():
		safe = Rect2(Vector2.ZERO, win)
	var k := view / win if win.x > 0 and win.y > 0 else Vector2.ONE
	var cut := []
	for h in holes:
		var r: Rect2 = h
		cut.append(Rect2(r.position * k, r.size * k))
	return {"safe": [maxf(safe.position.x, 0.0) * k.x, maxf(safe.position.y, 0.0) * k.y,
			maxf(win.x - safe.end.x, 0.0) * k.x, maxf(win.y - safe.end.y, 0.0) * k.y], "cutouts": cut}


## The HUD (Build 7 B7-010, owner 2026-10-18): anchored to the corners of the usable screen with a small,
## even margin. System bars are kept clear (the safe area), but a camera cutout narrows the screen only
## where it is: an element it would overlap moves just past it, instead of the whole HUD moving in by the
## cutout's band on that side, plus a corner margin, plus a fixed position (what pushed the status box
## far from the corner on a phone with a camera hole).
func _fit_hud() -> void:
	var d := _display_insets()
	var inset: Array = d.safe.duplicate()
	var cutouts: Array = d.cutouts
	var view := get_viewport().get_visible_rect().size
	# a side whose whole safe-area band is a cutout touching that edge is not kept clear for the HUD
	for c: Rect2 in cutouts:
		if c.position.x <= 1.0 and absf(c.end.x - inset[0]) < 2.0:
			inset[0] = 0.0
		if c.position.y <= 1.0 and absf(c.end.y - inset[1]) < 2.0:
			inset[1] = 0.0
		if c.end.x >= view.x - 1.0 and absf(view.x - c.position.x - inset[2]) < 2.0:
			inset[2] = 0.0
		if c.end.y >= view.y - 1.0 and absf(view.y - c.position.y - inset[3]) < 2.0:
			inset[3] = 0.0
	hud_root.offset_left = inset[0]
	hud_root.offset_top = inset[1]
	hud_root.offset_right = -inset[2]
	hud_root.offset_bottom = -inset[3]
	var m: float = HUD_MARGIN["phone" if main.settings.phone else "desktop"]
	status_box.position = Vector2(m, m)
	log_box.offset_right = -m
	log_box.offset_top = m
	touch_bar.offset_right = -m
	touch_bar.offset_bottom = -m
	# then step off any cutout an element would overlap (once laid out)
	_avoid_cutouts.call_deferred(cutouts, m)


func _avoid_cutouts(cutouts: Array, m: float) -> void:
	var view := get_viewport().get_visible_rect().size
	for c: Rect2 in cutouts:
		for e: Control in [status_box, log_box, touch_bar]:
			var r := e.get_global_rect()
			if not r.intersects(c):
				continue
			var shift := Vector2.ZERO
			if c.size.x <= c.size.y:              # a hole at a side (landscape): step sideways off it
				shift.x = (c.end.x - r.position.x + m) if c.get_center().x < view.x / 2.0 else -(r.end.x - c.position.x + m)
			else:                                  # a notch along the top or bottom: step down or up
				shift.y = (c.end.y - r.position.y + m) if c.get_center().y < view.y / 2.0 else -(r.end.y - c.position.y + m)
			e.position += shift


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
	hud_root.add_child(hud)
	# anchored to the top-left corner of the usable screen, a small margin in (fit_safe_area)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _style(Color(WINDOW, 0.88)))
	box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status_box = box
	hud.add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)
	for key in ["hp", "hunger", "stamina"]:
		var m: Array = METERS[key]
		var h := HBoxContainer.new()
		var ic := _ui_icon(m[1], 24) if key != "hunger" else _item_icon_rect("bread", 24)
		ic.tooltip_text = m[2]
		ic.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(ic)
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(156, 18)
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.show_percentage = false
		pb.tooltip_text = m[2]
		var track := StyleBoxFlat.new()
		track.bg_color = SLATE
		pb.add_theme_stylebox_override("background", track)
		var fill := StyleBoxFlat.new()
		fill.bg_color = BAR_COLOURS[key]
		pb.add_theme_stylebox_override("fill", fill)
		var vl := Label.new()
		vl.set_anchors_preset(Control.PRESET_FULL_RECT)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vl.add_theme_font_size_override("font_size", 12)
		vl.add_theme_color_override("font_outline_color", Color.BLACK)
		vl.add_theme_constant_override("outline_size", 4)
		pb.add_child(vl)
		h.add_child(pb)
		v.add_child(h)
		bars[key] = pb
		bar_labels[key] = vl
	var row := HBoxContainer.new()
	row.add_child(_ui_icon("coins", 24))
	coins_label = Label.new()
	coins_label.custom_minimum_size = Vector2(56, 0)
	coins_label.tooltip_text = "Coins in your purse"
	coins_label.mouse_filter = Control.MOUSE_FILTER_PASS
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
	prompt_box.offset_bottom = -64
	prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_box.visible = false
	var ph := HBoxContainer.new()
	prompt_icon = TextureRect.new()
	prompt_icon.custom_minimum_size = Vector2(30, 30)
	prompt_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prompt_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prompt_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ph.add_child(prompt_icon)
	prompt_label = Label.new()
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 3)
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ph.add_child(prompt_label)
	ph.add_theme_constant_override("separation", 6)
	var pm := _style(Color(WINDOW, 0.88))
	pm.set_content_margin_all(6)
	prompt_box.add_theme_stylebox_override("panel", pm)
	prompt_box.add_child(ph)
	hud.add_child(prompt_box)

	toast = Label.new()
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast.offset_bottom = -160
	toast.add_theme_font_size_override("font_size", 17)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.visible = false
	_backed(toast)
	toast.add_theme_color_override("font_outline_color", Color.BLACK)
	toast.add_theme_constant_override("outline_size", 6)
	hud.add_child(toast)

	action_bar = ProgressBar.new()
	action_bar.set_anchors_preset(Control.PRESET_CENTER)
	action_bar.position = Vector2(-90, -70)       # above the player's head, clear of the prompt
	action_bar.custom_minimum_size = Vector2(180, 18)
	action_bar.show_percentage = false
	action_bar.visible = false
	hud.add_child(action_bar)

	touch_bar = HBoxContainer.new()
	touch_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	touch_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	touch_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	touch_bar.add_theme_constant_override("separation", 8)
	hud.add_child(touch_bar)
	for b in [["Use", "interact", "use"], ["Gather", "gather", "gather"], ["Attack", "attack", "attack"], ["Fire", "fireball", "fire"], ["Pack", "inventory", "pack"],
			["Skills", "skills", "skills"], ["Map", "map", "map"], ["Menu", "pause", "menu"]]:
		var btn := _tile_button(b[2], b[0], 72)
		btn.focus_mode = Control.FOCUS_NONE
		var act: String = b[1]
		btn.pressed.connect(func(): _touch_action(act))
		touch_bar.add_child(btn)
		if act == "attack":
			attack_btn = btn
		if act == "gather":
			gather_btn = btn
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
	_build_place_bar()


## The bar shown while placing a building (main.begin_placement), at the foot of the screen: what the
## footprint covers and whether it may go there, with Place and Cancel for touch (keys and the pad
## have E / A and Esc / B; the buttons never take focus, so those keys go to the map).
func _build_place_bar() -> void:
	place_bar = PanelContainer.new()
	place_bar.add_theme_stylebox_override("panel", _style(Color(WINDOW, 0.92)))
	place_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	place_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	place_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	place_bar.offset_bottom = -12
	place_bar.visible = false
	var v := VBoxContainer.new()
	place_bar.add_child(v)
	place_label = Label.new()
	place_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place_label.custom_minimum_size = Vector2(560, 0)
	place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place_label.add_theme_font_size_override("font_size", 18)
	v.add_child(place_label)
	var hint := Label.new()
	hint.name = "Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(PALE, 0.8))
	v.add_child(hint)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	for pair in [["Place here", func(): main.confirm_placement()], ["Cancel", func():
			main.end_placement()
			message("Building put off.")]]:
		var b := Button.new()
		b.text = pair[0]
		b.custom_minimum_size = Vector2(180, 48)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pair[1])
		h.add_child(b)
	hud.add_child(place_bar)


func show_placing(on: bool) -> void:
	place_bar.visible = on
	recenter_btn.visible = false if on else main.cam_free
	if on:
		toast.visible = false
	touch_bar.visible = not on and (main.settings.touch_buttons == "always" or (main.settings.touch_buttons == "auto" and scheme == "touch"))
	prompt("")
	(place_bar.find_child("Hint", true, false) as Label).text = {"touch": "Tap where it should stand; drag two fingers to look further.",
		"gamepad": "Left stick or d-pad moves it; A places it; B cancels.",
		"kbm": "The mouse or the arrow keys move it; click it or press E to place; Esc cancels."}.get(scheme, "")


func placing_text(text: String, ok: bool) -> void:
	place_label.text = text
	place_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.7) if ok else Color(1.0, 0.7, 0.6))


## The controls in use changed: touch buttons only for touch (unless set otherwise), and prompts
## name the key or pad button. With keys or a pad, panels get keyboard focus.
func set_scheme(s: String) -> void:
	scheme = s
	var mode: String = main.settings.touch_buttons
	touch_bar.visible = (mode == "always" or (mode == "auto" and s == "touch")) and not place_bar.visible
	if place_bar.visible:
		show_placing(true)                  # its hint follows the scheme
	recenter_btn.offset_bottom = -10.0 - (104.0 if touch_bar.visible else 0.0)
	prompt(prompt_text)
	if is_open("title"):
		show_title(main.can_continue())       # its controls list follows the scheme
	if panel.visible and s != "touch":
		_focus_first()


func set_gather_mode(on: bool) -> void:
	gather_btn.self_modulate = Color(1.0, 0.85, 0.4) if on else Color.WHITE
	gather_btn.text = "Gather ON" if on else "Gather"


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


## LT / RT step the focus back and forth through every enabled control of the open window, in
## order and wrapping round, whatever its layout (Build 8 report: the pad could not reach a button).
func cycle_focus(dir: int) -> void:
	var all := panel.find_children("*", "Control", true, false).filter(func(c): return (c is BaseButton or c is LineEdit or c is Slider) \
		and c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE and not (c is BaseButton and c.disabled))
	if all.is_empty():
		return
	var i := all.find(get_viewport().gui_get_focus_owner())
	(all[posmod(i + dir, all.size()) if i >= 0 else 0] as Control).grab_focus()


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
		"gather":
			main.gather_button()
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
	close_btn.pressed.connect(go_back)
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
	_meter_text("hp", "Health %d/%d" % [ceili(p.hp), int(p.hp_cap())], p.hp / maxf(1.0, p.hp_cap()))
	_meter_text("hunger", "Food %d%%" % ceili(p.hunger), p.hunger / 100.0)
	_meter_text("stamina", "Stamina %d/%d" % [int(p.stamina), int(p.stamina_cap())], p.stamina / maxf(1.0, p.stamina_cap()))
	coins_label.text = " %d" % p.coins
	clock_label.text = w.clock_text()
	# the prompt and toast follow their own size (a container's minimum size settles a frame late)
	if prompt_box.visible:
		_place_bottom(prompt_box, _prompt_bottom())
	if toast.visible:
		_place_bottom(toast, toast_bottom)
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


## A meter's words, and its danger state: below DANGER_AT of its cap the fill turns red and blinks.
func _meter_text(key: String, words: String, fraction: float) -> void:
	bar_labels[key].text = words
	var low := fraction < DANGER_AT
	bar_danger[key] = low
	var fill := bars[key].get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = DANGER_COLOUR if low else BAR_COLOURS[key]
	var blink := low and int(Time.get_ticks_msec() / 400) % 2 == 0
	bars[key].modulate = Color(1.0, 0.7, 0.65) if blink else Color.WHITE


## Where the prompt's bottom edge sits: just above the screen edge, or above the action buttons
## when the touch bar is showing (they fill the bottom of a phone).
func _prompt_bottom() -> float:
	if touch_bar != null and touch_bar.visible:
		return -(touch_bar.get_combined_minimum_size().y + 12.0 + 8.0)
	return -64.0


## Centre a bottom-anchored control on its own (re-measured) size, its bottom edge at `bottom`. A
## control that grows from its bottom edge keeps its old top when the words get shorter, and a
## wrapping label measured while it had no width is thousands of pixels tall.
func _place_bottom(c: Control, bottom: float) -> void:
	var m := c.get_combined_minimum_size()
	c.offset_left = -m.x / 2.0
	c.offset_right = m.x / 2.0
	c.offset_top = bottom - m.y
	c.offset_bottom = bottom


## Fit a label to its words: one line up to max_w, wrapped (at max_w) beyond that.
func _fit_label(l: Label, max_w: float) -> void:
	var f := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	var w := f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 4.0
	l.custom_minimum_size.x = max_w if w > max_w else 0.0     # the width first: a wrapping label measured at 0 is thousands of px tall
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if w > max_w else TextServer.AUTOWRAP_OFF


func prompt(text: String) -> void:
	prompt_text = text
	prompt_label.text = text
	_fit_label(prompt_label, PROMPT_MAX_W)
	_place_bottom(prompt_box, _prompt_bottom())
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


## Controls: the Controls tab of Settings (kept as an entry point for the title and pause menus).
func show_controls(back: Callable) -> void:
	show_settings(back, "controls")


func _controls_tab() -> void:
	_label("The game switches by itself to whichever you use.", 16)
	_label("The bars top left: Health (at 0 you die), Food (falls with time; at 0 you starve and lose health, so eat from the Pack) and Stamina (spent by casting Fireball, refills by itself). A bar turns red and blinks when it is low.", 15)
	for s in [scheme] + ["touch", "kbm", "gamepad"].filter(func(x): return x != scheme):
		_label(SCHEME_NAMES[s] + (" (in use)" if s == scheme else ""), 22, Color(1, 0.85, 0.5))
		_controls_list(s)


func message(text: String, seconds := 4.0) -> void:
	toast.text = text
	_fit_label(toast, TOAST_MAX_W)
	toast.visible = true
	toast_t = seconds
	toast_bottom = minf(-160.0, _prompt_bottom() - 56.0) if not place_bar.visible else -(place_bar.size.y + 24.0)    # above the placing bar
	_place_bottom(toast, toast_bottom)


## Something gained or a quick hint ("+2 red berries"): a short line in the top-right corner that
## fades quickly, keeping the middle of the screen clear for play (owner, 2026-10-18).
func gain(text: String, item := "") -> void:
	if item == "" or not ResourceLoader.exists(ICON % item):
		log_line(text, GAIN_SECONDS)
		var l: Label = log_box.get_child(log_box.get_child_count() - 1)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.size_flags_horizontal = Control.SIZE_SHRINK_END      # just the words, at the right edge
		return
	# with an item id: its pack icon left of the words, in one compact line
	var back := PanelContainer.new()
	back.name = "GainLine"
	var st := _style(Color(WINDOW, 0.88))
	st.set_content_margin_all(4)
	back.add_theme_stylebox_override("panel", st)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_item_icon_rect(item, 20))
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	row.add_child(l)
	back.add_child(row)
	_add_log(back, GAIN_SECONDS)


## A pack item's icon, sized for lines of text.
func _item_icon_rect(item: String, size: float) -> TextureRect:
	var t := _icon(item)
	t.custom_minimum_size = Vector2(size, size)
	t.name = "ItemIcon"
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## The words of the lines now in the corner log (a gain line with an icon keeps them in a child).
func log_texts() -> Array:
	var out := []
	for c in log_box.get_children():
		for n in [c] if c is Label else c.find_children("*", "Label", true, false):
			out.append(n.text)
	return out


func log_line(text: String, seconds := LOG_SECONDS) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 16)
	_backed(l)
	_add_log(l, seconds)


func _add_log(l: Control, seconds: float) -> void:
	log_box.add_child(l)
	while log_box.get_child_count() > LOG_LINES:
		var c := log_box.get_child(0)
		log_box.remove_child(c)
		c.queue_free()
	# each line stays a few seconds, then fades away (the full record is under Menu)
	var tw := l.create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(l, "modulate:a", 0.0, minf(1.0, seconds * 0.5))
	tw.tween_callback(l.queue_free)


# ---------------------------------------------------------------- panel helpers --------------
func modal() -> bool:
	return panel.visible


## True when a touch at this screen position lands on the interface rather than the map.
func blocks(pos: Vector2) -> bool:
	if panel.visible:
		return true
	for c in (touch_bar.get_children() if touch_bar.visible else []) + [status_box, recenter_btn, place_bar]:
		if c.visible and c.get_global_rect().has_point(pos):
			return true
	return false


func is_open(kind: String) -> bool:
	return panel.visible and panel_kind == kind


## X, Esc and the pad's B in a window (PL1-01): a window opened from another returns to it (Settings
## to the pause menu or the title screen), a window of play closes, and the title, character
## creation, origin and death screens do not close at all (closing the title left the world grey and paused).
func go_back() -> void:
	if not panel.visible or panel_kind in ["title", "origin", "death"]:
		return
	if inner_back.is_valid() and inner_back.call():
		return
	if panel_back.is_valid():
		var b := panel_back
		b.call()
	else:
		hide_all()


func hide_all() -> void:
	panel_back = Callable()
	inner_back = Callable()
	panel.visible = false
	hud.visible = true
	panel_kind = ""
	if main.world and main.running:
		main.paused = false


func _open(kind: String, title: String, pause := true) -> void:
	panel_kind = kind
	panel_back = Callable()
	inner_back = Callable()
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
	_button("Settings", func(): show_settings(func(): show_title(main.can_continue()), "audio"))
	if not main.settings.phone:
		_button("Quit", func(): main.get_tree().quit())
	_button("Controls", func(): show_controls(func(): show_title(main.can_continue())))
	_button("Wiki", func(): show_settings(func(): show_title(main.can_continue()), "wiki"))
	_button("Credits", show_credits)
	_controls_list(scheme)


## Every asset pack's creator, from game/data/credits.json (owner rule: everyone is credited).
func show_credits() -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	_open("credits", "Credits", true)
	panel_back = func(): show_title(main.can_continue())
	_label("My Medieval Life, by Hot Attic Games.", 18)
	for p in c.packs:
		_label("%s: %s (%s)" % [p.creator if p.creator != "to be confirmed" else "Creator to be confirmed", p.packs, p.licence], 15)
	_label(str(c.story), 15)
	_button("Back", func(): show_title(main.can_continue()))


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
	panel_back = func(): show_title(main.can_continue())
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
	_button("Back", func(): show_title(main.can_continue()), true, sexes).custom_minimum_size = Vector2(120, 52)
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
	_button("Build", show_build_menu)
	_button("Settings", func(): show_settings(show_pause, "audio"))
	_button("Controls", func(): show_controls(show_pause))
	_button("Wiki", func(): show_settings(show_pause, "wiki"))
	_button("Save and quit to title", func():
		main.save_game(false)
		main.running = false
		show_title(true))


const SETTINGS_TABS := [["audio", "Audio"], ["display", "Display"], ["interface", "Interface"], ["controls", "Controls"], ["wiki", "Wiki"]]


## Settings: one screen with tabs (Audio, Display, Interface, Controls, Wiki) and a Back button. Each
## change is applied and saved at once. `back` reopens the screen it came from (the title or the
## pause menu, or closes to play); X, Esc and the pad's B do the same, after stepping back inside the
## wiki. Opening it keeps the pause state it found, so closing restores play (PL1-01, PL1-02).
func show_settings(back: Callable, tab := "") -> void:
	var was_paused: bool = main.paused
	_open("settings", "Settings", was_paused)
	panel_back = back
	if tab != "":
		settings_tab = tab
	_settings_page()


func _settings_page() -> void:
	var back := panel_back
	for c in panel_body.get_children():
		panel_body.remove_child(c)
		c.queue_free()
	inner_back = Callable()
	var tabs := HFlowContainer.new()
	tabs.name = "SettingsTabs"
	panel_body.add_child(tabs)
	for t in SETTINGS_TABS:
		var id: String = t[0]
		var b := Button.new()
		b.text = t[1]
		b.name = "Tab_" + id
		b.toggle_mode = true
		b.button_pressed = id == settings_tab
		b.custom_minimum_size = Vector2(120, 48)
		b.pressed.connect(func():
			settings_tab = id
			_settings_page.call_deferred())
		tabs.add_child(b)
	match settings_tab:
		"audio":
			_settings_audio()
		"display":
			_settings_display()
		"interface":
			_settings_interface()
		"controls":
			_controls_tab()
		"wiki":
			var wk := WikiWindow.new()
			wk.open(self, panel_body)
			inner_back = wk.step_back
	_button("Back", back if back.is_valid() else hide_all)
	if scheme != "touch":
		var tb: Button = tabs.get_node_or_null("Tab_" + settings_tab)
		if tb:
			tb.grab_focus.call_deferred()


func _settings_audio() -> void:
	var st: GameSettings = main.settings
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
	_label("Sound volumes take effect once the game has sounds.", 14)


func _settings_display() -> void:
	var st: GameSettings = main.settings
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


func _settings_interface() -> void:
	var st: GameSettings = main.settings
	_choice("Interface size", ["small", "normal", "large"], st.ui_size, func(v): st.ui_size = v)
	_choice("On-screen buttons", ["auto", "always", "never"], st.touch_buttons, func(v): st.touch_buttons = v)


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
	var res := _button("Resources", func(): show_resources(), true, nav)
	res.custom_minimum_size = Vector2(200, 48)


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
	var mj: Dictionary = w.manor_work.job_of("player")
	if not mj.is_empty():
		out.append({"day": true, "text": "Work for the manor"})
		out.append({"day": false, "text": "%s, for %d coins (taken on day %d; it lapses if not done by the next morning)." % [w.manor_work.describe(mj), int(mj.wage), int(mj.day)]})
		out.append({"day": false, "text": _manor_next(mj)})
	if out.is_empty():
		out.append({"day": false, "text": "No quests. Look for people with a marker over their head."})
	out.append({"day": true, "text": "Earning money"})
	out.append({"day": false, "text": EARNING_HINT})
	return out


## The next step of the player's manor job, in words.
func _manor_next(j: Dictionary) -> String:
	var mw: ManorWork = main.world.manor_work
	match mw.step(j):
		"take":
			return "Next: collect it at %s." % (str(j.src) if j.kind == "haul" else "the manor's works yard")
		"put":
			if j.kind == "quarry":
				return "Next: bring %d stone to the manor's works yard (you have %d)." % [int(j.qty), main.world.player.inv.count("stone")]
			return "Next: take it to %s." % mw.dest_name(j.to)
		"mend":
			return "Next: mend %s." % str(j.get("place", "the road"))
	return ""


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


# ---------------------------------------------------------------- journal: resources ---------
## The journal's Resources & Gathering page (B7-012), built only from game/data/resources.json
## through ResourceNodes: how Gather mode works, every node the player may gather (where it is, the
## tool and where to get one, what it gives, whether it comes back, whose it is), then the keepers'
## animals. `node` opens one node: each product's uses and what it becomes, each of those a button
## to `item`, that product's own uses and sources, with Back to the node.
func show_resources(node := "", item := "") -> void:
	_open("journal", "Journal: resources", true)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	panel_body.add_child(nav)
	if node != "":
		var back := _button("Back", func(): show_resources(node if item != "" else ""), true, nav)
		back.custom_minimum_size = Vector2(160, 48)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(gap)
	for v in [["Village record", false], ["Quests", true]]:
		var b := _button(str(v[0]), func(): show_journal(-1, bool(v[1])), true, nav)
		b.custom_minimum_size = Vector2(200, 48)
	var sheet := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = PARCHMENT
	paper.border_color = Color8(120, 84, 48)
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(3)
	paper.set_content_margin_all(18)
	sheet.add_theme_stylebox_override("panel", paper)
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_body.add_child(sheet)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 8)
	sheet.add_child(lines)
	if item != "":
		_res_item_page(lines, item)
	elif node != "":
		_res_node_page(lines, node)
	else:
		_res_list(lines)


## The ids of the nodes the player may (`mine`) or may not gather, in resources.json's order.
func _res_ids(mine: bool) -> Array:
	return ResourceNodes.defs().keys().filter(func(id): return bool(ResourceNodes.def(id).get("player_harvest", false)) == mine)


func _res_list(lines: VBoxContainer) -> void:
	_res_text(lines, "How to gather", 24, RES_HEAD)
	for i in GATHER_STEPS.size():
		_res_text(lines, "%d. %s" % [i + 1, GATHER_STEPS[i]])
	_res_text(lines, GATHER_KEYS, 16)
	_res_text(lines, GATHER_PAD, 16)
	_res_text(lines, "What you can gather", 24, RES_HEAD)
	_res_text(lines, "Choose one to see what it is used for and what it becomes.", 16)
	for id in _res_ids(true):
		_res_card(lines, id)
	var kept := _res_ids(false)
	if kept.is_empty():
		return
	_res_text(lines, "Not yours to gather", 24, RES_HEAD)
	var notes := []
	for id in kept:
		var d := ResourceNodes.def(id)
		_res_text(lines, "%s: %s." % [str(d.name), _res_plain(str(d.where))])
		for t in [_res_plain(str(d.owner)), _res_plain(str(d.theft))]:
			if not notes.has(t):
				notes.append(t)
	for t in notes:
		_res_text(lines, t, 16, RES_WARN)


## One node on the list, as a card with its Uses button.
func _res_card(lines: VBoxContainer, id: String) -> void:
	var d := ResourceNodes.def(id)
	var card := PanelContainer.new()
	card.set_meta("node", id)
	var box := StyleBoxFlat.new()
	box.bg_color = RES_CARD
	box.border_color = Color8(150, 110, 70)
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", box)
	lines.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := _icon(str(d.icon))
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_res_facts(col, d, false)
	var open := _button("Uses", func(): show_resources(id), true, row)
	open.custom_minimum_size = Vector2(140, 56)
	open.size_flags_vertical = Control.SIZE_SHRINK_CENTER


## A node's facts: its name, where, tool and skill (and where to get the tool if the player has
## none), what it gives, whether it comes back, whose it is. `full`: the node's own page.
func _res_facts(col: VBoxContainer, d: Dictionary, full: bool) -> void:
	_res_text(col, str(d.name), 26 if full else 22, RES_HEAD)
	_res_text(col, "Where: %s." % _res_plain(str(d.where)))
	_res_text(col, _res_tool(d))
	var tool := str(d.get("tool", ""))
	if tool != "":
		var have := _res_have(tool)
		if have == "":
			_res_text(col, _res_plain(str(d.tool_hint)), 18, RES_WARN)
		elif full:
			_res_text(col, "You have: %s." % GameData.item_name(have), 16)
	var gives := HFlowContainer.new()
	gives.add_theme_constant_override("h_separation", 6)
	col.add_child(gives)
	_res_word(gives, "Gives each time:")
	var p := ResourceNodes.products(d)
	for id in p:
		gives.add_child(_icon(id))
		_res_word(gives, "%s x%d" % [GameData.item_name(id), int(p[id])])
	_res_text(col, str(RES_DEPLETION.get(str(d.depletion), str(d.depletion).capitalize())))
	if full:
		_res_text(col, _res_plain(str(d.regeneration), _res_scope(d)), 16)
	var theft := _res_plain(str(d.theft))
	var risky := not theft.begins_with("Never")
	if risky:
		_res_text(col, "Owner: %s" % _res_plain(str(d.owner)), 16)
		_res_text(col, theft, 18, RES_WARN)
	else:
		_res_text(col, "Owner: %s %s" % [_res_plain(str(d.owner)), theft], 16)


## "Tool: Pickaxe (required)  ·  Skill: Mining", from the node's tool, tool_required, skill and level.
func _res_tool(d: Dictionary) -> String:
	var tool := str(d.get("tool", ""))
	var s := "Tool: none needed" if tool == "" else "Tool: %s (%s)" % [tool.capitalize(), "required" if bool(d.get("tool_required", false)) else "helps"]
	var skill := str(d.get("skill", ""))
	if skill != "":
		s += "  ·  Skill: %s" % str(GameData.skills[skill].name)
		if int(d.get("level", 0)) > 1:
			s += " level %d" % int(d.level)
	return s


## The player's item of a tool type (a pickaxe), or of an item type (a weapon); "" if none.
func _res_have(tool: String) -> String:
	var p: PlayerState = main.world.player
	var t := p.tool_of(tool)
	if t != "":
		return t
	for id in p.inv.ids():
		if str(GameData.item(id).get("type", "")) == tool:
			return id
	return ""


func _res_node_page(lines: VBoxContainer, node: String) -> void:
	var d := ResourceNodes.def(node)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	lines.add_child(head)
	var icon := _icon(str(d.icon))
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	head.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(col)
	_res_facts(col, d, true)
	for id in ResourceNodes.products(d):
		_res_heading(lines, id)
		_res_uses(lines, id)
		_res_text(lines, "What it becomes", 20, RES_HEAD)
		var c := ResourceNodes.chain(id)
		if c.becomes.is_empty():
			_res_text(lines, "Nothing is made from it.", 16)
		_res_chain(lines, c, 0, node)


## A product followed from a node's page: its uses, what it becomes and where it comes from.
func _res_item_page(lines: VBoxContainer, item: String) -> void:
	_res_heading(lines, item)
	_res_uses(lines, item)
	_res_text(lines, "What it becomes", 20, RES_HEAD)
	var c := ResourceNodes.chain(item)
	if c.becomes.is_empty():
		_res_text(lines, "Nothing is made from it.", 16)
	_res_chain(lines, c, 0, "")
	_res_text(lines, "Where it comes from", 20, RES_HEAD)
	for s in ResourceNodes.sources_of(item):
		_res_text(lines, "•  " + _res_source_text(s))


func _res_heading(lines: VBoxContainer, item: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	lines.add_child(h)
	var icon := _icon(item)
	icon.custom_minimum_size = Vector2(48, 48)
	h.add_child(icon)
	var l := _res_text(h, GameData.item_name(item), 24, RES_HEAD)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _res_uses(lines: VBoxContainer, item: String) -> void:
	_res_text(lines, "Used for", 20, RES_HEAD)
	var uses := ResourceNodes.uses_of(item)
	if uses.is_empty():
		_res_text(lines, "Nothing uses it.", 16)
	for u in uses:
		_res_text(lines, "•  " + _res_use_text(u))


## One use (ResourceNodes.uses_of) in words: "Crafting: 1 makes Plank x2 at the sawhorse".
func _res_use_text(u: Dictionary) -> String:
	var kind := str(u.kind)
	var what := str(RES_USE_KINDS.get(kind, kind.capitalize()))
	match kind:
		"recipe":
			var makes := []
			for o in u.makes:
				makes.append("%s x%d" % [GameData.item_name(o), int(u.makes[o])])
			return "%s: %d makes %s at the %s" % [what, int(u.qty), ", ".join(makes), str(u.station)]
		"building":
			return "%s: %d for %s" % [what, int(u.qty), str(u.text).trim_prefix("building ")]
		"buyer":
			# a trade role in words: "merchant_raw" is the raw merchant
			var parts := str(u.id).split("_")
			parts.reverse()
			return "%s: bought by the %s (wants up to %d)" % [what, " ".join(parts), int(u.qty)]
		"quest":
			return "%s: %s (%d wanted)" % [what, str(u.text), int(u.qty)]
	return "%s: %s" % [what, _res_plain(str(u.text))]


## One source (ResourceNodes.sources_of) in words.
func _res_source_text(s: Dictionary) -> String:
	match str(s.kind):
		"node":
			return "Gathered: %s (%d each time)" % [str(s.text), int(s.qty)]
		"recipe":
			var uses := []
			for i in s.uses:
				uses.append("%d %s" % [int(s.uses[i]), GameData.item_name(i)])
			return "Made at the %s from %s (makes %d)" % [str(s.station), ", ".join(uses), int(s.qty)]
	return World.cap(_res_plain(str(s.text)))


## What an item becomes (ResourceNodes.chain), a line a step, indented; with `node`, each product
## is a button to its own page.
func _res_chain(lines: VBoxContainer, c: Dictionary, depth: int, node: String) -> void:
	for b in c.becomes:
		for t in b.then:
			var out := str(t.item)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			lines.add_child(row)
			var pad := Control.new()
			pad.custom_minimum_size = Vector2(32 * depth, 0)
			row.add_child(pad)
			_res_word(row, "→")
			row.add_child(_icon(out))
			var caption := "%s x%d" % [GameData.item_name(out), int(b.makes[out])]
			if node != "":
				var go := _button(caption, func(): show_resources(node, out), true, row)
				go.custom_minimum_size = Vector2(180, 48)
			else:
				_res_word(row, caption, RES_HEAD)
			var others := []
			for i in b.with:
				others.append("%d %s" % [int(b.with[i]), GameData.item_name(i)])
			var how := "at the %s" % str(b.station) + ((", with " + ", ".join(others)) if not others.is_empty() else "")
			var l := _res_text(row, how, 16)
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_res_chain(lines, t, depth + 1, node)


func _res_text(parent: Control, text: String, size := 18, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## A label that does not wrap (in a row of icons and words).
func _res_word(parent: Control, text: String, color := INK) -> Label:
	var l := _res_text(parent, text, 18, color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


## A registry text in the player's words: notes for developers in brackets ("(World._new_day)",
## "(main.gd _hit_animal)") and code names ("World.mine_unit") left out; balance keys
## ("tree_regrow_days") as their numbers, looked up under `scope` first ("animals.boar.").
func _res_plain(text: String, scope := "") -> String:
	var code := RegEx.create_from_string("[A-Za-z]\\w*\\.[A-Za-z_]\\w*|\\w+_\\w+|\\bP\\d")
	for m in RegEx.create_from_string("\\s*\\(([^()]*)\\)").search_all(text):
		if code.search(m.get_string(1)) != null:
			text = text.replace(m.get_string(), "")
	text = RegEx.create_from_string("\\b[A-Z]\\w*\\.[a-z_]\\w*\\s*").sub(text, "", true)
	for m in RegEx.create_from_string("\\b[a-z][a-z0-9]*(?:[._][a-z0-9]+)+\\b").search_all(text):
		var key := m.get_string()
		var words := key.replace("_", " ").replace(".", " ")
		var n := words
		for path in ([scope + key] if scope != "" else []) + [key]:
			var at = GameData.balance
			for part in str(path).split("."):
				at = at.get(part) if at is Dictionary else null
			if at is float or at is int:
				n = "%d" % int(at)
			elif at is Array and not (at as Array).is_empty():
				n = "–".join((at as Array).map(func(v): return "%d" % int(v)))
			if n != words:
				break
		if n != words and key.ends_with("_days"):
			n += " days"
		text = text.replace(key, n)
	return text.replace("  ", " ").replace(" .", ".").replace(" ,", ",").strip_edges()


## The balance scope of a node's numbers: "animals.boar." for boar, "" for others.
func _res_scope(d: Dictionary) -> String:
	var species := str(d.get("match", {}).get("species", ""))
	return "animals.%s." % species if species != "" else ""


func show_death() -> void:
	var p: PlayerState = main.world.player
	_open("death", "%s %s has died" % [p.name, p.family])
	_label(death_text(p.death_cause), 24, Color(1.0, 0.55, 0.45)).name = "DeathCause"
	_label("Death is permanent, but the village and your family go on. What %s carried lies where they fell, for anyone to take. Your heir keeps the family house and the chest, but starts with only what a wanderer carries and must learn everything anew." % p.name)
	_button("Continue as the heir", func(): main.continue_as_heir())


## The death screen's words for what took the last of the player's health (B8-020).
func death_text(src: String) -> String:
	match src:
		"hunger":
			return "You starved."
		"spoiled food":
			return "Spoiled food made you fatally sick."
		"":
			return "You died of your wounds."
	return "Killed by %s." % src


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
	# the manor's work (owner, 2026-10-18): the reeve offers its list of real jobs
	if n.job == "reeve":
		_talk_choice(choices, "Any work for me?", func(): show_manor_jobs(n))
	# paid work (owner: the player can work and earn money): asked for, never marked
	if w.quests.hires(n):
		_talk_choice(choices, "Any work for me?", func():
			var job: Dictionary = w.quests.hire_offer(n)
			if job.is_empty():
				_talk_view(n, w.quests.no_work_line(n))
			else:
				_talk_view(n, w.quests.line({"id": job.id, "giver": n.id}, "offer"), true, job.id))


## The reeve's list of the manor's open jobs, each with its wage (paid when it is done), or why there
## is none. The player takes one at a time.
func show_manor_jobs(reeve: NPC) -> void:
	var w: World = main.world
	var mw: ManorWork = w.manor_work
	var mine := mw.job_of("player")
	if not mine.is_empty():
		_talk_view(reeve, "Finish what you're doing for the manor first: %s." % _lower_first(mw.describe(mine)))
		return
	var open := mw.open_for("player")
	if open.is_empty():
		var any := mw.jobs.any(func(j): return j.taker == "")
		_talk_view(reeve, "The manor's chest can't spare a wage today. Ask me another day." if any
				else "There's nothing the manor needs carried, quarried or mended just now.")
		return
	_open("manor_jobs", "Work for the manor  ·  you have %d coins" % w.player.coins)
	_label("%s: \"This is what the manor needs doing. You're paid from the manor's chest when it's done.\"" % reeve.name, 18, Color(1, 0.85, 0.5))
	# the same job several times over (loads of one lot) is one line with how many there are
	var lines := []
	var seen := {}
	for j in open:
		var key := "%s|%d" % [mw.describe(j), int(j.wage)]
		if seen.has(key):
			seen[key].n += 1
		else:
			seen[key] = {"job": j, "n": 1}
			lines.append(seen[key])
	for line in lines.slice(0, 6):
		var j: Dictionary = line.job
		var h := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s  ·  %d coins%s" % [mw.describe(j), int(j.wage), ("  (%d such jobs)" % int(line.n)) if int(line.n) > 1 else ""]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", 18)
		h.add_child(l)
		panel_body.add_child(h)
		var job: Dictionary = j
		_button("Take it", func():
			if mw.take(job, "player"):
				message("Work for the manor: %s. It is written in your journal." % mw.describe(job))
				hide_all()
			else:
				message(mw.last_refusal)
				show_manor_jobs(reeve), true, h)
	_button("Back", func(): show_talk(reeve))


static func _lower_first(s: String) -> String:
	return s.substr(0, 1).to_lower() + s.substr(1)


## "I'll do it" or "Not now" to an offer: the villager's quest, or (`hire`) the work they offered.
func _offer_choices(n: NPC, choices: GridContainer, hire := "") -> void:
	var w: World = main.world
	_talk_choice(choices, "I'll do it", func():
		var q: Dictionary = w.quests.accept(n, hire)
		if q.is_empty():
			message(w.quests.last_refusal if w.quests.last_refusal != "" else "That is no longer on offer.")
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
func _talk_view(n: NPC, said: String, offering := false, hire := "", note := "", helping := false) -> void:
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
	if helping:
		_helper_choices(n, choices)
		_fit_talk(side, choices)
		return
	_quest_choices(n, choices)
	# hired help for the family's building site (owner rule: helpers are hired for coin and carry the
	# owner's goods): anyone out of work or labouring
	if w.construction.can_hire(n) == "" and not w.construction.sites_of(World.PLAYER).is_empty():
		_talk_choice(choices, "Hire to carry building materials", func():
			_talk_view(n, "A day's carrying for %d coins? I'll fetch what's in your chest, or buy what's wanting at the market with your money, and bring it to your site." % int(GameData.b("helper_wage")), false, "", "", true))
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
	# ...never a child's (owner, 2026-10-18: B8-010, keep disabled)
	if w.player.pos.distance_to(n.pos) <= PICKPOCKET_REACH and n.role != "child":
		_talk_choice(choices, "Pick pocket — theft", func(): main.pickpocket(n))
	_talk_choice(choices, "What do you do?", func(): _talk_view(n, Dialogue.work(w, n)))
	_talk_choice(choices, "How are things at home?", func(): _talk_view(n, Dialogue.home(w, n)))
	_talk_choice(choices, "Any news?", func(): _talk_view(n, Dialogue.news(w, n)))
	_talk_choice(choices, "Goodbye", hide_all)
	_fit_talk(side, choices)


## Hiring a helper for the day: for each of the family's sites, carry from the family chest only, or
## also buy what is missing with the player's coins (up to what the rest costs now).
func _helper_choices(n: NPC, choices: GridContainer) -> void:
	var w: World = main.world
	var c: Construction = w.construction
	var wage := int(GameData.b("helper_wage"))
	for p in c.sites_of(World.PLAYER).slice(0, 2):
		var pp: Dictionary = p
		var where := "" if c.sites_of(World.PLAYER).size() == 1 else " to " + w.property.describe(p)
		var hire := func(budget: int) -> void:
			var why := c.hire(World.PLAYER, n, pp, budget)
			if why != "":
				message(why)
				_talk_view(n, Dialogue.opening(w, n))
				return
			message("%s will carry%s for the rest of the working day." % [n.name, where])
			_talk_view(n, "Right. I'll get to it.")
		var need: Dictionary = pp.site.need.duplicate()
		for id in need.keys():
			need[id] = maxi(0, int(need[id]) - w.player.chest.count(id))
		var spend := mini(c.estimate(need), maxi(0, w.player.coins - wage))
		_talk_choice(choices, "From my chest%s (%d coins)" % [where, wage], func(): hire.call(0), w.player.coins >= wage)
		_talk_choice(choices, "Buy the rest too (%d + %d)" % [wage, spend], func(): hire.call(spend), w.player.coins >= wage and spend > 0)
	_talk_choice(choices, "Not now", func(): _talk_view(n, Dialogue.opening(w, n)))


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
	if n.role != "child":                 # never a child's pocket (owner, B8-010)
		_button("Pick pocket while asleep — theft", func():
			hide_all()
			main.pickpocket(n))
	_button("Let them sleep", hide_all)


func show_trade(n: NPC) -> void:
	var w: World = main.world
	var p := w.player
	if w.at_post(n):
		_open("trade", "Trade with %s %s (%s)  ·  you have %d coins" % [n.name, n.family, w.shop_name(n), p.coins])
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
	var no := w.station_refusal(station_id)
	if no != "":
		_label(no, 18, Color(1, 0.7, 0.55))
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
		_button("Make", func(): main.craft(rr, station_id), lv_ok and p.inv.has_all(rec.in) and no == "", h)
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
		var head := HBoxContainer.new()
		head.add_child(_ui_icon("skill_" + str(k), 28))          # the skill's glyph (owner, B7-013)
		var name_l := _label("%s — level %d  (%d / %d xp)" % [s.name, lv, into.x, into.y], 20, Color(1, 0.85, 0.5))
		panel_body.remove_child(name_l)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.add_child(name_l)
		panel_body.add_child(head)
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
	recenter_btn.visible = on and not place_bar.visible


# ---------------------------------------------------------------- building / home ------------
## What to build (Menu > Build, or H): a house, or a workshop once the family owns a house (owner
## rule: house first, then workshops), each with what it takes; then a place for it (main
## begin_placement). The family's unfinished sites are listed to open.
func show_build_menu() -> void:
	var w: World = main.world
	var c: Construction = w.construction
	_open("build_menu", "Build")
	_label("Choose what to build, then a place for it: anywhere the ground is clear and nobody else's. The manor sells or leases you the ground on the spot. Then a wooden frame goes up; bring the materials (or hire a helper: ask a villager out of work) and it stands when the last load is in.", 16)
	for kind in Construction.KINDS:
		var cost := c.cost_of(kind)
		var no := c.may_build(kind, World.PLAYER)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", 17)
		var st: Array = c.stations_of_kind(kind)
		l.text = "%s%s: %s" % [World.cap(Construction.kind_name(kind)), (" (" + " and ".join(st) + ")") if not st.is_empty() else "",
			", ".join(cost.keys().map(func(k): return "%d %s" % [int(cost[k]), GameData.item_name(k).to_lower()]))]
		if no != "":
			l.text += ". " + no
		h.add_child(l)
		var k: String = kind
		_button("Choose a place", func(): main.begin_placement(k), no == "", h)
		panel_body.add_child(h)
	var sites: Array = c.sites_of(World.PLAYER)
	if not sites.is_empty():
		_label("Your building sites:", 20, Color(1, 0.85, 0.5))
		for p in sites:
			var h := HBoxContainer.new()
			var l := Label.new()
			l.text = "%s: %d%% done" % [World.cap(w.property.describe(p)), roundi(w.site_progress(p) * 100.0)]
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			h.add_child(l)
			var pp: Dictionary = p
			_button("Open", func(): show_build(pp), true, h)
			panel_body.add_child(h)


## The ground chosen for a building: buy or lease it from the manor and mark out the site in one go
## (owner rule), or choose again.
func show_place_deal(kind: String, rect: Rect2i) -> void:
	var w: World = main.world
	var c: Construction = w.construction
	var t := c.ground_terms(rect)
	var cost := c.cost_of(kind)
	_open("place", "Build %s here" % Construction.kind_name(kind, true))
	_label("The ground %s is the manor's: %d coins, or %d a week (a building on leased ground goes to the manor if the lease ends). You have %d coins." % [
		w.where(rect), int(t.price), int(t.rent), w.player.coins], 17)
	_label("Then the frame goes up. The %s needs %s: bring them, or hire a helper." % [
		Construction.kind_name(kind), ", ".join(cost.keys().map(func(k): return "%d %s" % [int(cost[k]), GameData.item_name(k).to_lower()]))], 16)
	var mark := func(lease: bool) -> void:
		var p: Dictionary = c.place(kind, rect, World.PLAYER, lease)
		if p.is_empty():
			message("You cannot build there: %s." % c.why)
			return
		main.end_placement()
		message("The ground is yours%s and the frame is up. Bring the materials." % (" on lease" if lease else ""))
		show_build(p)
	_button("Buy the ground and mark out (%d coins)" % int(t.price), func(): mark.call(false), w.player.coins >= int(t.price))
	_button("Lease and mark out (%d a week)" % int(t.rent), func(): mark.call(true), w.player.coins >= int(t.rent))
	_button("Choose another place", func(): main.resume_placement())
	_button("Cancel", func():
		hide_all()
		main.end_placement())


## A parcel of ground: buy or lease it from the manor; once it is the family's, mark out what to build
## (a house, or a workshop after a house); then the site: what it still needs, deliver, give it up.
func show_build(pl: Dictionary) -> void:
	var w: World = main.world
	var c: Construction = w.construction
	var p := w.player
	_open("build", World.cap(w.property.describe(pl)))
	var price := w.property.price_of(pl)
	var rent := w.property.rent_of(pl)
	if w.property.for_sale(pl):
		_label("The manor sells this ground for %d coins, or leases it for %d coins a week (the first week paid now). The coins go to the manor. Once it is yours, you can mark out a house (or, once you own a house, a workshop): a wooden frame appears, you bring the materials, and when the last load is in, it stands. A building on leased ground goes to the manor if the lease ends." % [price, rent])
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
		_label("This is %s's." % w.ref_name(w.holder_of(pl)))
		return
	if w.tenant_of(pl) == World.PLAYER:
		_label("You lease this ground from the manor: %d coins a week, next due on day %d%s." % [int(pl.rent), int(pl.due_day) + 1,
				(", %d owed" % int(pl.arrears)) if int(pl.get("arrears", 0)) > 0 else ""], 16)
	if pl.site.is_empty():
		_label("Mark out a building here:")
		for kind in Construction.KINDS:
			var cost := c.cost_of(kind)
			var no := c.may_build(kind, World.PLAYER)
			if Vector2i(int(pl.w), int(pl.h)) != c.footprint(kind):
				no = "the ground is the wrong size"
			var k: String = kind
			_button("%s: %s" % [World.cap(Construction.kind_name(kind)), ", ".join(cost.keys().map(func(id): return "%d %s" % [int(cost[id]), GameData.item_name(id).to_lower()]))],
				func():
					w.start_site(pl, k, World.PLAYER)
					show_build(pl), no == "")
		return
	var kind := str(pl.site.get("kind", "house"))
	if pl.site.done:
		_label("%s stands here. The reeve keeps the manor's land office: buy, lease or sell land and houses there." % World.cap(w.property.describe(pl)))
		return
	var need: Dictionary = pl.site.need
	var done_part := w.site_progress(pl)
	_label("Building: %s, %d%% done. Still needed:" % [World.cap(Construction.kind_name(kind)), roundi(done_part * 100.0)])
	var bar := ProgressBar.new()
	bar.value = done_part * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.47, 0.72, 0.29)
	bar.add_theme_stylebox_override("fill", fill)
	panel_body.add_child(bar)
	for id in need:
		_item_row(id, int(need[id]), "(you carry %d, %d in your chest)" % [p.inv.count(id), p.chest.count(id)], "", func(): pass)
	var helpers: Array = c.contracts.filter(func(k): return str(k.site) == str(pl.id))
	for k in helpers:
		var hn: NPC = w.npc(int(k.worker))
		if hn:
			_label("%s %s is carrying for you today (%d of %d coins spent on materials)." % [hn.name, hn.family, int(k.spent), int(k.budget)], 16, Color(0.75, 1.0, 0.7))
	if helpers.is_empty():
		_label("A helper can carry for you: talk to a villager out of work or labouring and hire them for the day (%d coins)." % int(GameData.b("helper_wage")), 15)
	_button("Deliver what I carry", func():
		if w.deliver(pl, p.inv, World.PLAYER):
			message("%s is finished!" % World.cap(w.property.describe(pl)))
			hide_all()
		else:
			show_build(pl))
	_button("Give up the site (all materials come back)", func():
		var back := w.cancel_site(pl, p.inv)
		var words: Array = back.keys().map(func(k): return "%d %s" % [int(back[k]), GameData.item_name(k).to_lower()])
		message("The frame comes down. You take back %s." % (", ".join(words) if not words.is_empty() else "nothing; none was delivered"))
		show_build(pl))


## A workshop at its door: its stations, whose it is, and for its holder who else may use them
## (owner rule: used by the owner or tenant, others with permission). Leave for "all" lets every
## villager's craft go on there too.
func show_workshop(b: Dictionary) -> void:
	var w: World = main.world
	_open("workshop", World.cap(w.property.describe(b)))
	var st: Array = w.construction.stations_of_kind(str(b.get("kind", "")))
	_label("Inside: %s." % " and ".join(st.map(func(s): return "a " + s)), 17)
	if not w.holds(World.PLAYER, b):
		var mine := w.may_use(World.PLAYER, {"building": b.id})
		_label("It is %s's. %s" % [w.ref_name(w.holder_of(b)), "They let you use it." if mine else "You need their leave to use it."], 17)
		return
	var open_all: bool = (b.get("allow", []) as Array).has("all")
	_label("It is yours. %s" % ("Anyone may work here; the village's craftsmen use it when their own stations are taken." if open_all
			else "Only your family works here."), 17)
	_button("Keep it to my family" if open_all else "Let anyone work here", func():
		w.permit(b, "all", not open_all)
		show_workshop(b))


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
