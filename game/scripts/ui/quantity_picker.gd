class_name QuantityPicker
extends PanelContainer
## The one "how many?" control (PL1-03, PL2-012): the merchant's Buy and Sell, and the chest's Store and
## Take, all use it. Item name, an info line (unit price, stock or owned), a slider with - / + / Max, the
## chosen quantity, a live total, Confirm and Cancel. It only chooses a number; the caller does the
## move (World.trade / World.transfer, both all-or-nothing) in `on_confirm.call(qty)`, so Cancel changes
## nothing. Keyboard, mouse, pad (the slider takes left/right) and touch all work on the same buttons.
## GP-QTY-PICKER-CONTROLLER (owner 2026-10-26): on a pad, X sets the least (1) and Y the most (max_qty, which every caller
## computes from what is carried, the coins, the buyer's coins, the room and the stock) in one press each, shown under the
## slider when the gamepad is in use; the press is consumed, so it never reaches another control.

signal confirmed(qty: int)
signal cancelled

var qty := 1
var max_qty := 0
var unit_price := -1            # coins each; -1 = no money involved (storage)
var prices: Array = []          # coins for each unit in turn when they differ (World.player_quote); overrides unit_price
var verb := "Buy"
var coins_after := Callable()   # optional: qty -> text for the live total line
var slider: HSlider
var qty_label: Label
var total_label: Label
var confirm_btn: Button
var cancel_btn: Button
var minus_btn: Button
var plus_btn: Button
var max_btn: Button
var pad_row: HBoxContainer       # GP-QTY-PICKER-CONTROLLER: the X Min / Y Max prompt, shown with a gamepad
const PAD_MIN := JOY_BUTTON_X
const PAD_MAX := JOY_BUTTON_Y


## Most you can buy when each unit has its own price (`prices`, in order): units while the coins last.
static func buy_max_priced(prices: Array, coins: int, room := true) -> int:
	if not room:
		return 0
	var n := 0
	var spent := 0
	for c in prices:
		if spent + int(c) > coins:
			break
		spent += int(c)
		n += 1
	return n


## Most you can sell when each unit has its own price: what you carry and the buyer wants (the length of
## `prices`), and as many as the buyer's own coins pay for.
static func sell_max_priced(prices: Array, merchant_coins: int) -> int:
	return buy_max_priced(prices, merchant_coins)


## `info` is the line under the name ("2 coins each · 8 in stock"); `why_not` is shown instead of the
## slider when max is 0.
func setup(title: String, info: String, max_n: int, p_verb: String, p_unit_price := -1, why_not := "") -> QuantityPicker:
	max_qty = maxi(0, max_n)
	verb = p_verb
	unit_price = p_unit_price
	qty = 1 if max_qty > 0 else 0
	name = "QuantityPicker"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(52, 38, 28)
	sb.border_color = Color8(222, 178, 64)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(10)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	v.add_child(_label(title, 22, Color8(255, 217, 128)))
	v.add_child(_label(info, 16, Color8(246, 236, 214)))
	if max_qty <= 0:
		v.add_child(_label(why_not if why_not != "" else "Nothing to move.", 16, Color8(255, 178, 140)))
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		minus_btn = _small("-", func(): set_qty(qty - 1))
		row.add_child(minus_btn)
		slider = HSlider.new()
		slider.min_value = 1
		slider.max_value = maxi(2, max_qty)         # a 1..1 range cannot be dragged; the cap is enforced in set_qty
		slider.step = 1
		slider.value = 1
		slider.editable = max_qty > 1
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.custom_minimum_size = Vector2(140, 48)
		slider.focus_mode = Control.FOCUS_ALL
		slider.value_changed.connect(func(x: float): set_qty(int(x)))
		row.add_child(slider)
		plus_btn = _small("+", func(): set_qty(qty + 1))
		row.add_child(plus_btn)
		max_btn = _small("Max", func(): set_qty(max_qty))
		max_btn.custom_minimum_size.x = 80
		row.add_child(max_btn)
		v.add_child(row)
		pad_row = HBoxContainer.new()
		pad_row.name = "PadPrompts"
		pad_row.add_theme_constant_override("separation", 6)
		for pr in [["xbox_button_x", "Min (1)"], ["xbox_button_y", "Max (%d)" % max_qty]]:
			var t := TextureRect.new()
			var path := "res://assets/prompts/%s.png" % pr[0]
			if ResourceLoader.exists(path):
				t.texture = load(path)
			t.custom_minimum_size = Vector2(28, 28)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pad_row.add_child(t)
			var l := _label(pr[1], 16, Color8(246, 236, 214))
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			pad_row.add_child(l)
		pad_row.visible = false
		v.add_child(pad_row)
	qty_label = _label("", 18, Color8(246, 236, 214))
	v.add_child(qty_label)
	total_label = _label("", 18, Color8(255, 217, 128))
	v.add_child(total_label)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	confirm_btn = Button.new()
	confirm_btn.custom_minimum_size = Vector2(150, 48)
	confirm_btn.pressed.connect(confirm)
	btns.add_child(confirm_btn)
	cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 48)
	cancel_btn.pressed.connect(cancel)
	btns.add_child(cancel_btn)
	v.add_child(btns)
	_refresh()
	return self


func total() -> int:
	return total_for(qty)


## Coins for `n` units: the sum of the first `n` unit prices, or n x the single price.
func total_for(n: int) -> int:
	if not prices.is_empty():
		var t := 0
		for i in mini(n, prices.size()):
			t += int(prices[i])
		return t
	return n * unit_price if unit_price >= 0 else 0


func set_qty(n: int) -> void:
	if max_qty <= 0:
		return
	qty = clampi(n, 1, max_qty)
	_refresh()


## Confirm: only a quantity inside 1..max goes out.
func confirm() -> void:
	if qty >= 1 and qty <= max_qty:
		confirmed.emit(qty)


func cancel() -> void:
	cancelled.emit()


## GP-QTY-PICKER-CONTROLLER: the pad's one-press least and most. Taken in _input, before the focused control sees it, and
## marked handled, so X or Y never also presses a button or reaches the game (X is Attack, Y Fireball in play).
func _input(e: InputEvent) -> void:
	if not (e is InputEventJoypadButton) or not e.pressed or max_qty <= 0 or not is_visible_in_tree():
		return
	if e.button_index == PAD_MIN or e.button_index == PAD_MAX:
		set_qty(1 if e.button_index == PAD_MIN else max_qty)
		get_viewport().set_input_as_handled()


## The pad prompts show while the game is played with a gamepad (GameUI.scheme), wherever the picker sits.
func _ui_scheme() -> String:
	var n := get_parent()
	while n != null and not n is GameUI:
		n = n.get_parent()
	return str((n as GameUI).scheme) if n != null else ""


## The whole box in view once it is laid out (TRADE-AXE-01: opened from a row far down a list, the window kept its
## scroll and the box stayed above it, out of sight), whatever the controls; focus alone scrolled only to the slider.
func _enter_tree() -> void:
	_show_whole.call_deferred()
	if pad_row != null:
		pad_row.visible = _ui_scheme() == "gamepad"


func _show_whole() -> void:
	for i in 2:
		if not is_inside_tree():
			return                        # closed or rebuilt before it was laid out: nothing to show
		await get_tree().process_frame
	if not is_inside_tree():
		return
	var p := get_parent()
	while p != null and not p is ScrollContainer:
		p = p.get_parent()
	if p != null:
		(p as ScrollContainer).ensure_control_visible(self)


## Put keyboard/pad focus on the slider (or Cancel when there is nothing to choose).
func focus_default() -> void:
	if not is_inside_tree():
		if not tree_entered.is_connected(focus_default):
			tree_entered.connect(focus_default, CONNECT_ONE_SHOT | CONNECT_DEFERRED)     # focus once it is on screen
		return
	if slider != null and slider.editable:
		slider.grab_focus()
	elif confirm_btn != null and not confirm_btn.disabled:
		confirm_btn.grab_focus()
	elif cancel_btn != null:
		cancel_btn.grab_focus()


func _refresh() -> void:
	if qty_label == null:
		return
	qty_label.text = "Quantity: %d of %d" % [qty, max_qty] if max_qty > 0 else "Quantity: none"
	if unit_price >= 0:
		total_label.text = ("Total: %d coins" % total()) if max_qty > 0 else ""
		if coins_after.is_valid() and max_qty > 0:
			total_label.text += "  " + str(coins_after.call(qty))
	else:
		total_label.text = ""
	if slider != null and int(slider.value) != qty:
		slider.set_value_no_signal(qty)
	confirm_btn.text = ("%s %d" % [verb, qty]) if max_qty > 0 else verb
	confirm_btn.disabled = max_qty <= 0
	if minus_btn != null:
		minus_btn.disabled = qty <= 1
		plus_btn.disabled = qty >= max_qty
		max_btn.disabled = qty >= max_qty


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _small(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(52, 48)
	b.pressed.connect(cb)
	return b
