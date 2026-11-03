class_name UIStyle
extends RefCounted
## B25R1-008 (owner directive 2026-11-03, section 7: "a consistent, professional medieval pixel-art interface"): the shared
## look of the polished windows (character creation, the origin story; the region map adopts it too). Framed wooden panels,
## sunken insets and a parchment page, pixel-art buttons with hover, pressed, disabled and selected states, colour swatches,
## and the type sizes and colours that go with them, all drawn from small images built here (no art file), at whole art
## pixels of `px` interface units (2 on a desktop window, 1 in the phone layout, whose interface unit is already 2.4 screen
## pixels), nearest-filtered so the edges stay crisp.
##
## Use: `node.theme = UIStyle.theme(px)` styles every Button, LineEdit and Label under `node`; `UIStyle.frame(px)` is the
## window's own panel; `UIStyle.inset(px)` and `UIStyle.parchment(px)` are boxes inside it; `UIStyle.button(b, "primary", px)`
## marks the main action and `"selected"` the chosen one of a set; `UIStyle.Swatch` is a colour button.

# colours: the game's dark wood, bronze trim and parchment (GameUI WINDOW, SLATE, PALE, PARCHMENT, INK)
const OUTLINE := Color8(20, 12, 7)
const WOOD := Color8(46, 31, 20)
const WOOD_DEEP := Color8(30, 20, 13)
const TRIM := Color8(156, 110, 58)
const TRIM_DARK := Color8(92, 60, 33)
const RIVET := Color8(232, 192, 110)
const TEXT := Color8(246, 236, 214)
const MUTED := Color8(200, 182, 150)
const GOLD := Color8(240, 196, 84)
const PARCH := Color8(234, 218, 178)
const PARCH_EDGE := Color8(190, 160, 112)
const INK := Color8(58, 38, 22)
const INK_RED := Color8(122, 38, 22)
# type sizes (interface units)
const TITLE := 24
const HEAD := 17
const BODY := 16
const SMALL := 13
const BUTTON := 17
const BUTTON_H := 40.0          # the least height of a button: a comfortable touch target in either layout

static var _cache := {}


## The window frame: an outline, a bronze rim with a gold rivet in each corner, a dark inner line, then the wood.
static func frame(px := 2) -> StyleBoxTexture:
	return _box("frame", px, 6, 10)


## A sunken box inside a window (the character preview, a group of controls).
static func inset(px := 2) -> StyleBoxTexture:
	return _box("inset", px, 3, 8)


## A parchment page (the origin story).
static func parchment(px := 2) -> StyleBoxTexture:
	return _box("parchment", px, 3, 14)


## A button's look: "normal", "primary" (the main action: gold) or "selected" (the chosen one of a set).
static func button(b: Button, kind := "normal", px := 2) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var look: String = state
		if kind == "selected" and state in ["normal", "hover"]:
			look = "selected"
		elif kind == "primary" and state != "disabled":
			look = "primary_" + ("pressed" if state.ends_with("pressed") else "hover" if state == "hover" else "normal")
		b.add_theme_stylebox_override(state, _box("btn_" + look, px, 3, 8, state.ends_with("pressed")))
	b.add_theme_stylebox_override("focus", _focus(px))
	var ink := INK if kind == "primary" else TEXT
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, GOLD if kind == "selected" else ink)
	b.add_theme_color_override("font_pressed_color", INK if kind == "primary" else PALE_TEXT)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

const PALE_TEXT := Color8(236, 214, 170)


## A theme for everything under a polished window: buttons, text fields and labels in this look.
static func theme(px := 2) -> Theme:
	var key := "theme%d" % px
	if _cache.has(key):
		return _cache[key]
	var t := Theme.new()
	t.default_font_size = BODY
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		t.set_stylebox(state, "Button", _box("btn_" + state, px, 3, 8, state.ends_with("pressed")))
	t.set_stylebox("focus", "Button", _focus(px))
	t.set_font_size("font_size", "Button", BUTTON)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", PALE_TEXT)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_hover_pressed_color", "Button", PALE_TEXT)
	t.set_color("font_disabled_color", "Button", Color(0.62, 0.58, 0.54))
	for state in ["normal", "read_only"]:
		t.set_stylebox(state, "LineEdit", _box("field", px, 3, 10))
	t.set_stylebox("focus", "LineEdit", _focus(px))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color(MUTED, 0.7))
	t.set_color("caret_color", "LineEdit", GOLD)
	t.set_font_size("font_size", "LineEdit", BODY + 1)
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", BODY)
	t.set_stylebox("panel", "PanelContainer", inset(px))
	_cache[key] = t
	return t


## A label in the polished windows' type: "title", "head", "body", "small", "muted", "ink" (on parchment), "ink_head".
static func label(text: String, kind := "body") -> Label:
	var l := Label.new()
	l.text = text
	var sizes := {"title": TITLE, "head": HEAD, "body": BODY, "small": SMALL, "muted": SMALL, "ink": BODY, "ink_head": HEAD + 3}
	var colours := {"title": GOLD, "head": GOLD, "body": TEXT, "small": TEXT, "muted": MUTED, "ink": INK, "ink_head": INK_RED}
	l.add_theme_font_size_override("font_size", int(sizes.get(kind, BODY)))
	l.add_theme_color_override("font_color", colours.get(kind, TEXT))
	if kind in ["title", "head"]:
		l.add_theme_color_override("font_shadow_color", Color(OUTLINE, 0.9))
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 2)
	return l


static func _focus(px: int) -> StyleBoxFlat:
	var f := StyleBoxFlat.new()
	f.draw_center = false
	f.border_color = GOLD
	f.set_border_width_all(px)
	f.anti_aliasing = false
	return f


## A nine-slice box from a small generated image: `border` art pixels of edge (each `px` interface units), `pad` units of
## content margin inside it. `sink`: the content sits one art pixel lower (a pressed button).
static func _box(kind: String, px: int, border: int, pad: int, sink := false) -> StyleBoxTexture:
	var key := "%s/%d" % [kind, px]
	if not _cache.has(key):
		var sb := StyleBoxTexture.new()
		sb.texture = ImageTexture.create_from_image(_image(kind, border, px))
		var m := (border + 1) * px
		sb.texture_margin_left = m
		sb.texture_margin_top = m
		sb.texture_margin_right = m
		sb.texture_margin_bottom = m
		sb.content_margin_left = m + pad
		sb.content_margin_right = m + pad
		sb.content_margin_top = m + pad * 0.5 + (px if sink else 0)
		sb.content_margin_bottom = m + pad * 0.5 - (px if sink else 0)
		if kind in ["frame", "parchment"]:
			sb.content_margin_top = m + pad
			sb.content_margin_bottom = m + pad
		_cache[key] = sb
	return _cache[key]


## The art of a box, (border * 2 + 2) art pixels square, scaled up by `px`.
static func _image(kind: String, border: int, px: int) -> Image:
	var n := border * 2 + 2
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var fill := WOOD
	match kind:
		"inset", "field":
			fill = WOOD_DEEP
		"parchment":
			fill = PARCH
	var face := {"btn_normal": Color8(118, 80, 46), "btn_hover": Color8(142, 98, 57), "btn_pressed": Color8(88, 58, 33),
		"btn_hover_pressed": Color8(98, 66, 38), "btn_disabled": Color8(74, 62, 52), "btn_selected": Color8(96, 70, 34),
		"btn_primary_normal": Color8(204, 152, 62), "btn_primary_hover": Color8(226, 176, 82), "btn_primary_pressed": Color8(160, 116, 44)}
	for y in n:
		for x in n:
			var c := fill
			var d := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))     # how far in from the edge
			var corner := (x == 0 or x == n - 1) and (y == 0 or y == n - 1)
			# on the top or the left edge (lit from the top left)
			var lit := (y < n / 2 and y <= x and y <= n - 1 - x) or (x < n / 2 and x <= y and x <= n - 1 - y)
			var in_corner := (x <= 3 or x >= n - 4) and (y <= 3 or y >= n - 4)
			if kind == "frame":
				if corner:
					c = Color(0, 0, 0, 0)
				elif in_corner and d >= 1:
					# a rivet: a 2 x 2 gold stud in a dark ring in each corner of the rim, its top-left pixel catching the light
					var sx := x - (1 if x <= 3 else n - 3)
					var sy := y - (1 if y <= 3 else n - 3)
					if sx in [0, 1] and sy in [0, 1]:
						c = Color8(255, 238, 176) if sx == 0 and sy == 0 else RIVET
					else:
						c = OUTLINE
				elif d == 0 or d == 4:
					c = OUTLINE
				elif d == 1:
					c = Color8(214, 166, 88) if lit else Color8(132, 90, 46)
				elif d == 2:
					c = TRIM if lit else TRIM_DARK
				elif d == 3:
					c = TRIM_DARK
			elif kind == "inset" or kind == "field":
				if d == 0:
					c = OUTLINE
				elif d == 1:
					c = Color8(16, 10, 6) if lit else Color8(96, 66, 38)
			elif kind == "parchment":
				if corner:
					c = Color(0, 0, 0, 0)
				elif d == 0:
					c = INK
				elif d == 1:
					c = PARCH_EDGE
			elif kind.begins_with("btn_"):
				var f: Color = face.get(kind, face.btn_normal)
				var pressed := kind.ends_with("pressed")
				if corner:
					c = Color(0, 0, 0, 0)
				elif d == 0:
					c = GOLD if kind == "btn_selected" else OUTLINE
				elif d == 1 and kind == "btn_selected":
					c = Color8(150, 108, 44)
				elif y == 1 or (y == 2 and not pressed):
					c = f.darkened(0.35) if pressed else f.lightened(0.28 if y == 1 else 0.12)
				elif y >= n - 3:
					c = f if pressed else f.darkened(0.3 if y == n - 2 else 0.15)
				else:
					c = f
			img.set_pixel(x, y, c)
	if px > 1:
		img.resize(n * px, n * px, Image.INTERPOLATE_NEAREST)
	return img


## A colour choice: a square of the colour in a dark outline, a gold ring when it is the one chosen; at least `side` units.
class Swatch extends Button:
	var colour := Color.WHITE
	var accent = null               # a second colour drawn in the corner (a skeleton's eye glow), or null
	var chosen := false

	func _init(c: Color, is_chosen: bool, side: float) -> void:
		colour = c
		chosen = is_chosen
		custom_minimum_size = Vector2(side, side)
		focus_mode = Control.FOCUS_ALL
		var empty := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			add_theme_stylebox_override(s, empty)

	func _draw() -> void:
		var r := Rect2(Vector2(3, 3), size - Vector2(6, 6))
		var hot := is_hovered() or has_focus()
		draw_rect(Rect2(Vector2.ZERO, size), UIStyle.GOLD if chosen else (UIStyle.TEXT if hot else UIStyle.OUTLINE), true)
		draw_rect(r.grow(-1.0) if chosen else r, UIStyle.OUTLINE, true)
		var inner := r.grow(-3.0 if chosen else -2.0)
		draw_rect(inner, colour, true)
		if accent != null:
			var q := inner.size * 0.45
			draw_rect(Rect2(inner.end - q, q), accent, true)
		if is_pressed():
			draw_rect(r.grow(-2.0), Color(0, 0, 0, 0.25), true)

	func _notification(what: int) -> void:
		if what in [NOTIFICATION_MOUSE_ENTER, NOTIFICATION_MOUSE_EXIT, NOTIFICATION_FOCUS_ENTER, NOTIFICATION_FOCUS_EXIT]:
			queue_redraw()
