class_name StallWindow
extends RefCounted
## The market stall window (PL1-10): rent a pitch, move goods from the pack to the stall with the
## QuantityPicker, set each price (a typed value or - / +), take goods back, read the stock and the sales
## record, collect the till, pay owed rent, close the stall. Built inside the game UI's panel with its own
## helpers, so keyboard, mouse, pad (buttons, the picker's slider) and touch all work the same way.
## The rules are in Business; this only asks.

const COLD := Color8(255, 178, 140)
const GOLD := Color8(255, 217, 128)


## The price control: a typed value with - / +, Set and Cancel. Only chooses a number.
class PriceEditor extends PanelContainer:
	signal confirmed(price: int)
	signal cancelled
	var price := 1
	var max_price := 1
	var edit: LineEdit
	var set_btn: Button

	func setup(title: String, info: String, current: int, p_max: int) -> PriceEditor:
		price = current
		max_price = p_max
		name = "PriceEditor"
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
		v.add_child(_lab(title, 22, Color8(255, 217, 128)))
		v.add_child(_lab(info, 16, Color8(246, 236, 214)))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(_btn("-", func(): _put(price - 1)))
		edit = LineEdit.new()
		edit.name = "PriceEdit"
		edit.text = str(price)
		edit.custom_minimum_size = Vector2(110, 48)
		edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
		edit.text_changed.connect(func(t: String): _typed(t))
		edit.text_submitted.connect(func(_t: String): confirm())
		row.add_child(edit)
		row.add_child(_btn("+", func(): _put(price + 1)))
		var unit := _lab("coins each", 18, Color8(246, 236, 214))
		unit.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(unit)
		v.add_child(row)
		var btns := HBoxContainer.new()
		btns.add_theme_constant_override("separation", 8)
		set_btn = _btn("Set price", confirm)
		set_btn.custom_minimum_size = Vector2(150, 48)
		btns.add_child(set_btn)
		var c := _btn("Cancel", func(): cancelled.emit())
		c.custom_minimum_size = Vector2(120, 48)
		btns.add_child(c)
		v.add_child(btns)
		_refresh()
		return self

	func _typed(t: String) -> void:
		price = clampi(int(t) if t.is_valid_int() else 0, 0, max_price)
		set_btn.disabled = price < 1

	func _put(n: int) -> void:
		price = clampi(n, 1, max_price)
		_refresh()

	func _refresh() -> void:
		edit.text = str(price)
		set_btn.disabled = price < 1

	func confirm() -> void:
		if price >= 1 and price <= max_price:
			confirmed.emit(price)

	func focus_default() -> void:
		edit.grab_focus()
		edit.select_all()

	func _lab(text: String, size: int, color: Color) -> Label:
		var l := Label.new()
		l.text = text
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", color)
		return l

	func _btn(text: String, cb: Callable) -> Button:
		var b := Button.new()
		b.text = text
		b.custom_minimum_size = Vector2(52, 48)
		b.pressed.connect(cb)
		return b


static func show(ui: GameUI, id: String, pick := {}) -> void:
	var w: World = ui.main.world
	var biz: Business = w.business
	var s: Dictionary = w.stalls[id]
	var p := w.player
	if w.tenant_of(s) != World.PLAYER:
		_rent_view(ui, w, s)
		return
	var rent := Business.rent_day()
	ui._open("stall", "Your market stall  ·  you have %d coins" % p.coins)
	if not pick.is_empty():
		_picker(ui, w, s, pick)
	var owing := int(s.get("missed", 0)) > 0
	var here := biz.attended(s)
	if owing:
		ui._label("Rent owing: sales are stopped. Pay %d coins to open again; the manor takes the pitch back if it stays unpaid." % (rent * maxi(1, w.day() - int(s.paid_day))), 17, COLD)
		ui._button("Pay the rent", func():
			var why := biz.pay_arrears(s)
			ui.message(why if why != "" else "Rent paid.")
			show(ui, id), p.coins >= rent)
	else:
		ui._label("Rent %d coins a day, paid through day %d. %s" % [rent, int(s.paid_day) + 1,
			"You are at the stall: villagers who need these goods will come." if here else
			"Sales happen only while you stand at the stall (within %d tiles)." % int(GameData.b("stall_range"))], 16, GOLD if here else COLD)
	var till := int(s.till)
	ui._label("Till: %d coins  ·  taken so far: %d coins" % [till, int(s.earned)], 18)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 8)
	ui.panel_body.add_child(acts)
	if till > 0:
		ui._button("Collect %d coins" % till, func():
			ui.message("You collect %d coins from the till." % biz.collect(s))
			show(ui, id), true, acts)
	ui._button("Close the stall", func():
		ui.message(biz.close(s))
		ui.hide_all(), true, acts)
	ui._label("Closing returns every item and the till to you.", 14)
	ui._label("For sale:", 20, Color(1, 0.85, 0.5))
	var stock: Dictionary = s.stock
	if stock.is_empty():
		ui._label("Nothing yet. Put goods up from your pack below.", 15)
	var ids := stock.keys()
	ids.sort()
	for item in ids:
		var it: String = item
		var h := HBoxContainer.new()
		h.add_child(ui._icon(it))
		var l := Label.new()
		l.text = "%s x%d   %d coins each  (market %d)" % [GameData.item_name(it), int(stock[it]), biz.price_of(s, it), GameData.value(it)]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		for spec in [["Price", "price"], ["Take back", "back"]]:
			var b := Button.new()
			b.text = spec[0]
			b.custom_minimum_size = Vector2(104, 48)
			var mode: String = spec[1]
			b.pressed.connect(func(): show(ui, id, {"id": it, "mode": mode}))
			h.add_child(b)
		ui.panel_body.add_child(h)
	ui._label("In your pack:", 20, Color(1, 0.85, 0.5))
	var any := false
	for item in p.inv.ids():
		var it: String = item
		if biz.can_list(it) and biz.listable(it) > 0:
			any = true
			ui._item_row(it, p.inv.count(it), "market value %d coins" % GameData.value(it), "Put up", func(): show(ui, id, {"id": it, "mode": "put"}))
	if not any:
		ui._label("Nothing in your pack to sell.", 15)
	ui._label("Sales:", 20, Color(1, 0.85, 0.5))
	var sales: Array = s.sales
	if sales.is_empty():
		ui._label("No sales yet.", 15)
	for i in range(sales.size() - 1, maxi(-1, sales.size() - 9), -1):
		var e: Dictionary = sales[i]
		ui._label("Day %d, %02d:00  %s bought %d %s for %d coins" % [int(e.day) + 1, int(e.hour), e.who, int(e.qty), GameData.item_name(e.item).to_lower(), int(e.qty) * int(e.price)], 15)
	_to_top.call_deferred(ui)          # after the focus has been given: a rebuilt window reads from its top


static func _to_top(ui: GameUI) -> void:
	var scroller := ui.panel_body.get_parent() as ScrollContainer
	if scroller != null and ui.panel_kind == "stall":
		scroller.scroll_vertical = 0


static func _rent_view(ui: GameUI, w: World, s: Dictionary) -> void:
	var biz: Business = w.business
	ui._open("stall", "Market pitch  ·  you have %d coins" % w.player.coins)
	ui._label("An open pitch in the market, kept by the manor. Rent it for %d coins a day (the first day now, then each morning from your purse or the till), put your goods up at your own prices, and stand by the stall while you sell: villagers buy only what they really need, with their own coins." % Business.rent_day(), 17)
	var why := biz.rent_refusal()
	if why != "":
		ui._label(why, 17, COLD)
	ui._button("Rent it for %d coins a day" % Business.rent_day(), func():
		var r := biz.rent()
		ui.message(r if r != "" else "You rent the stall.")
		show(ui, str(s.id)), why == "")
	ui._button("Not now", ui.hide_all)


## The quantity control for Put up / Take back, or the price control, at the top of the window.
static func _picker(ui: GameUI, w: World, s: Dictionary, pick: Dictionary) -> void:
	var biz: Business = w.business
	var id: String = pick.id
	var nm := GameData.item_name(id)
	var sid: String = s.id
	if pick.mode == "price":
		var cap := GameData.value(id) * Business.PRICE_CAP
		var pe := PriceEditor.new().setup("Price for %s" % nm, "Market value %d coins; you may ask 1 to %d." % [GameData.value(id), cap], biz.price_of(s, id), cap)
		pe.cancelled.connect(func(): show(ui, sid))
		pe.confirmed.connect(func(n: int):
			var why := biz.set_price(s, id, n)
			ui.message(why if why != "" else "%s now %d coins each." % [nm, n])
			show(ui, sid))
		ui.panel_body.add_child(pe)
		ui.panel_body.move_child(pe, 0)
		if ui.scheme != "touch":
			pe.focus_default.call_deferred()
		return
	var put: bool = pick.mode == "put"
	var mx := biz.listable(id) if put else int(s.stock.get(id, 0))
	var info := ("You carry %d. They go up at %d coins each (change it after)." % [w.player.inv.count(id), biz.price_of(s, id)]) if put else \
		"The stall holds %d. They come back to your pack." % mx
	var qp := QuantityPicker.new().setup(("Put up " if put else "Take back ") + nm, info, mx, "Put up" if put else "Take back", -1,
		"Nothing to move." if put else "Your pack is full." if not w.player.inv.can_add(id) else "Nothing to move.")
	qp.cancelled.connect(func(): show(ui, sid))
	qp.confirmed.connect(func(q: int):
		var why := biz.list_item(s, id, q) if put else biz.unlist(s, id, q)
		ui.message(why if why != "" else ("%d %s %s." % [q, nm.to_lower(), "put up for sale" if put else "back in your pack"])))
	qp.confirmed.connect(func(_q: int): show(ui, sid))
	ui.panel_body.add_child(qp)
	ui.panel_body.move_child(qp, 0)
	if ui.scheme != "touch":
		qp.focus_default.call_deferred()
