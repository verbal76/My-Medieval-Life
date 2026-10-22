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
	var s: Dictionary = biz.record(id)
	var p := w.player
	if s.is_empty():
		if w.buildings.has(id):                  # a room with a counter and no shop open yet
			FitWindow.show(ui, id)
			return
		return
	if not biz.is_mine(s):
		if Stalls.is_built(s):
			_others_view(ui, w, s)
			return
		_rent_view(ui, w, s)
		return
	var shop := Business.is_shop(s)
	var built := Stalls.is_built(s)
	var rent := biz.rent_of(s)
	var b: Dictionary = biz.building_of(s)
	var what := "shop" if shop else "stall"
	ui._open("stall", ("Your shop  ·  a %s  ·  " % w.fitting.trade(b) if shop else ("Your larger market stall  ·  " if bool(s.get("large", false)) else "Your market stall  ·  ")) + "you have %d coins" % p.coins)
	if not pick.is_empty():
		_picker(ui, w, s, pick)
	var owing := int(s.get("missed", 0)) > 0
	var here := biz.attended(s)
	if biz.stalls.is_market(s):
		_session_section(ui, w, s, id)
	if built:
		pass                                  # no rent: the 5% sales lease (the session section above)
	elif owing:
		ui._label("%s owing: sales are stopped. Pay %d coins to open again; the manor takes it back if it stays unpaid." % ["Licence" if shop else "Rent", rent * maxi(1, w.day() - int(s.paid_day))], 17, COLD)
		ui._button("Pay the %s" % ("licence" if shop else "rent"), func():
			var why := biz.pay_arrears(s)
			ui.message(why if why != "" else "Paid.")
			show(ui, id), p.coins >= rent)
	else:
		var att := biz.attendant_of(s)
		var line := "%s %d coins a day, paid through day %d. " % ["Licence" if shop else "Rent", rent, int(s.paid_day) + 1]
		if att != null and biz.attendant_present(s):
			line += "%s %s is at the counter: villagers who need these goods will come, whether or not you are here." % [att.name, att.family]
		elif here:
			line += "You are at the %s: villagers who need these goods will come." % what
		elif att != null:
			line += "%s %s minds it in the working day; nobody sells before they are at the counter." % [att.name, att.family]
		else:
			line += "Sales happen only while you stand at the %s (within %d tiles) or an attendant is at it." % [what, int(GameData.b("stall_range"))]
		ui._label(line, 16, GOLD if here or (att != null and biz.attendant_present(s)) else COLD)
	var till := int(s.till)
	ui._label("Till: %d coins  ·  taken so far: %d coins" % [till, int(s.earned)], 18)
	var costs: Dictionary = s.get("costs", {})
	var parts := []
	for k in costs:
		parts.append("%s %d" % [k, int(costs[k])])
	ui._label("Revenue %d  ·  expenses %d (%s)  ·  profit %s%d coins" % [int(s.earned), biz.expenses(s), ", ".join(parts) if not parts.is_empty() else "none yet",
		"+" if biz.profit(s) >= 0 else "", biz.profit(s)], 16, GOLD if biz.profit(s) >= 0 else COLD)
	ui._label("Goods are not costed; expenses are rent or licence, upgrades and wages.", 13)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 8)
	ui.panel_body.add_child(acts)
	if till > 0 and not biz.stalls.is_market(s):
		ui._button("Collect %d coins" % till, func():
			ui.message("You collect %d coins from the till." % biz.collect(s))
			show(ui, id), true, acts)
	if not built:
		ui._button("Give up the pitch" if not shop else "Close the shop", func():
			ui.message(biz.close(s))
			ui.hide_all(), true, acts)
	if shop:
		ui._button("Fit out the room", func(): FitWindow.show(ui, id), true, acts)
		ui._label(w.fitting.summary(b), 14)
	elif not bool(s.get("large", false)) and not built:
		var why := biz.upgrade_refusal(s)
		ui._button("Larger stall: %d coins, then %d a day" % [int(GameData.b("stall_large_cost")), int(GameData.b("stall_large_rent_day"))], func():
			var r := biz.upgrade(s)
			ui.message(r if r != "" else "Your stall is larger now: more goods, a display, a wider reach.")
			show(ui, id), why == "", acts)
		ui._label("A larger stall holds %d kinds of goods (now %d) and has a display that draws buyers from %.1f times as far." % [int(GameData.b("stall_large_listings")), biz.listing_cap(s), float(GameData.b("stall_large_reach"))], 14)
	if built:
		ui._label("Your own stall: no rent. Closing settles the sales; the unsold goods stay in it. Take them back below.", 14)
	else:
		ui._label(("Giving up the pitch settles the sales and returns every item and the rest of the till to you." if not shop else "Closing returns every item and the till to you.") + (" The counter and shelves stay in the room." if shop else ""), 14)
		_attendant_section(ui, w, s, id)
	ui._label("For sale (%d of %d kinds):" % [s.stock.size(), biz.listing_cap(s)], 20, Color(1, 0.85, 0.5))
	var stock: Dictionary = s.stock
	if stock.is_empty():
		ui._label("Nothing yet. Put goods up from your pack below.", 15)
	var ids := stock.keys()
	ids.sort()
	var large := bool(s.get("large", false))
	for item in ids:
		var it: String = item
		var h := HBoxContainer.new()
		h.add_child(ui._icon(it))
		var l := Label.new()
		l.text = "%s x%d   %d coins each  (market %d)%s" % [GameData.item_name(it), int(stock[it]), biz.price_of(s, it), GameData.value(it), "  [on display]" if str(s.get("display", "")) == it else ""]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var specs := [["Price", "price"], ["Take back", "back"]]
		for spec in specs:
			var bt := Button.new()
			bt.text = spec[0]
			bt.custom_minimum_size = Vector2(104, 48)
			var mode: String = spec[1]
			bt.pressed.connect(func(): show(ui, id, {"id": it, "mode": mode}))
			h.add_child(bt)
		if large:
			var db := Button.new()
			db.text = "Undisplay" if str(s.get("display", "")) == it else "Display"
			db.custom_minimum_size = Vector2(104, 48)
			db.pressed.connect(func():
				var r := biz.set_display(s, "" if str(s.get("display", "")) == it else it)
				ui.message(r if r != "" else "Display set.")
				show(ui, id))
			h.add_child(db)
		ui.panel_body.add_child(h)
	if shop and biz.store_cap(s) > 0:
		ui._label("Back room (%d of %d pieces; refills a shelf that sells out):" % [biz.store_total(s), biz.store_cap(s)], 20, Color(1, 0.85, 0.5))
		if s.store.is_empty():
			ui._label("Empty. Store spare goods from your pack below.", 15)
		var sids: Array = s.store.keys()
		sids.sort()
		for item in sids:
			var it: String = item
			ui._item_row(it, int(s.store[it]), "in the back room", "Bring out", func(): show(ui, id, {"id": it, "mode": "fetch"}))
	elif shop:
		ui._label("Stock chests (in Fit out) give the shop a back room for spare stock.", 14)
	ui._label("In your pack:", 20, Color(1, 0.85, 0.5))
	var any := false
	for item in p.inv.ids():
		var it: String = item
		if biz.can_list(it) and biz.listable(it) > 0:
			any = true
			var row := ui._item_row(it, p.inv.count(it), "market value %d coins" % GameData.value(it), "Put up", func(): show(ui, id, {"id": it, "mode": "put"}))
			if shop and biz.store_cap(s) > 0 and row != null:
				var sb := Button.new()
				sb.text = "Store"
				sb.custom_minimum_size = Vector2(90, 48)
				sb.pressed.connect(func(): show(ui, id, {"id": it, "mode": "store"}))
				row.get_parent().add_child(sb)
	if not any:
		ui._label("Nothing in your pack to sell.", 15)
	ui._label("Sales:", 20, Color(1, 0.85, 0.5))
	var sales: Array = s.sales
	if sales.is_empty():
		ui._label("No sales yet.", 15)
	for i in range(sales.size() - 1, maxi(-1, sales.size() - 9), -1):
		var e: Dictionary = sales[i]
		ui._label("Day %d, %02d:00  %s bought %d %s for %d coins%s" % [int(e.day) + 1, int(e.hour), e.who, int(e.qty), GameData.item_name(e.item).to_lower(), int(e.qty) * int(e.price),
			{"attendant": "  (sold by your attendant)", "unattended": "  (sold while you were away)"}.get(str(e.get("by", "")), "")], 15)
	_to_top.call_deferred(ui)          # after the focus has been given: a rebuilt window reads from its top


## Hiring, paying and letting go of the person who minds the counter (PL1-10 stage 4).
static func _attendant_section(ui: GameUI, w: World, s: Dictionary, id: String) -> void:
	var biz: Business = w.business
	var att := biz.attendant_of(s)
	ui._label("Attendant:", 20, Color(1, 0.85, 0.5))
	if att != null:
		ui._label("%s %s, %d coins a day from the till or your purse. They stand at the counter in the working day (7 to 18), sleep at night, and sell only what villagers really need." % [att.name, att.family, biz.wage()], 15)
		ui._button("Let %s go" % att.name, func():
			biz.dismiss(s)
			ui.message("%s no longer works for you." % att.name)
			show(ui, id))
		return
	var cands := biz.candidates()
	if cands.is_empty():
		ui._label("Nobody is free to hire: attendants are adults without a trade of their own (out of work, manor hands or labourers).", 15)
		return
	ui._label("Hire an adult without a trade, %d coins a day (today's wage now):" % biz.wage(), 15)
	var shown := 0
	for n: NPC in cands:
		if shown >= 5:
			break
		shown += 1
		var who := n
		var h := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s %s%s" % [who.name, who.family, {"manor_hand": "  (manor hand)", "laborer": "  (labourer)"}.get(who.job, "")]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var hb := Button.new()
		hb.text = "Hire"
		hb.disabled = w.player.coins + int(s.till) < biz.wage()
		hb.custom_minimum_size = Vector2(110, 48)
		hb.pressed.connect(func():
			var r := biz.hire(s, who)
			ui.message(r if r != "" else "%s will mind the counter." % who.name)
			show(ui, id))
		h.add_child(hb)
		ui.panel_body.add_child(h)


## OPEN STALL / CLOSE STALL and the session's settlement (STALL-03..05, owner 2026-10-21 Q8, Q13): what the open
## session has sold (held in the till, not to be taken until it is closed), what closing would pay the manor, the
## last settlement.
static func _session_section(ui: GameUI, w: World, s: Dictionary, id: String) -> void:
	var st: Stalls = w.business.stalls
	var open := st.is_open(s)
	var held := st.unsettled(s)
	var due := st.due(s)
	if open:
		ui._label(("OPEN: villagers who need these goods come and buy, whether or not you are here." if Stalls.is_built(s)
				else "OPEN: it sells while you or your attendant are at it.") + " It closes by itself when it sells out.", 16, GOLD)
	else:
		ui._label("CLOSED: nothing sells until you open it. Restock it below, then open it again.", 16, COLD)
	ui._label("This session: %d coins of sales, held in the till until the stall is closed. On closing the manor takes %d%% of the sales: %d coins now%s; the rest is yours." % [held, Stalls.pct(), due.x,
			(" (%d hundredths of a coin carried to the next settlement)" % due.y) if due.y > 0 else ""], 15)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	ui.panel_body.add_child(row)
	if open:
		ui._button("Close the stall and settle", func():
			ui.message("You close the stall. " + st.settle_text(s, st.close(s)))
			show(ui, id), true, row)
	else:
		var why := st.open_refusal(s, World.PLAYER)
		ui._button("Open the stall", func():
			var r := st.open(s, World.PLAYER)
			ui.message(r if r != "" else "Your stall is open.")
			show(ui, id), why == "", row)
		if held > 0 or int(s.get("till", 0)) > 0:
			ui._button("Settle the till", func():
				ui.message(st.settle_text(s, st.close(s)))
				show(ui, id), true, row)
	var log: Array = s.get("settlements", [])
	if not log.is_empty():
		var e: Dictionary = log[-1]
		ui._label("Last settled day %d, %02d:00 (%s): sales %d, to the manor %d, to you %d." % [int(e.day) + 1, int(e.hour), str(e.why), int(e.gross), int(e.commission), int(e.net)], 14)


## Someone else's built stall: whose it is and whether it is open (buying is done by the villagers who need its goods).
static func _others_view(ui: GameUI, w: World, s: Dictionary) -> void:
	var st: Stalls = w.business.stalls
	ui._open("stall", "A market stall")
	ui._label("%s's market stall: %s." % [w.ref_name(w.holder_of(s), true), "open" if st.is_open(s) else "closed"], 17)
	var stock: Dictionary = s.get("stock", {})
	var ids: Array = stock.keys()
	ids.sort()
	for it in ids:
		ui._label("%s x%d, %d coins each" % [GameData.item_name(it), int(stock[it]), w.business.price_of(s, it)], 15)
	ui._button("Close", ui.hide_all)


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
	var mode: String = pick.mode
	var up := mode == "put" or mode == "store"
	var mx := 0
	var info := ""
	match mode:
		"put":
			mx = biz.listable(id)
			info = "You carry %d. They go up at %d coins each (change it after)." % [w.player.inv.count(id), biz.price_of(s, id)]
		"store":
			mx = mini(biz.listable(id), biz.store_cap(s) - biz.store_total(s))
			info = "You carry %d. The back room has room for %d more; it refills the shelf when this sells out." % [w.player.inv.count(id), biz.store_cap(s) - biz.store_total(s)]
		"fetch":
			mx = int(s.get("store", {}).get(id, 0))
			info = "The back room holds %d. They come back to your pack." % mx
		_:
			mx = int(s.stock.get(id, 0))
			info = "It holds %d. They come back to your pack." % mx
	var verb := {"put": "Put up", "store": "Store", "fetch": "Bring out"}.get(mode, "Take back") as String
	var qp := QuantityPicker.new().setup(verb + " " + nm, info, mx, verb, -1,
		"Nothing to move." if up else w.player.inv.full_text(id) if not w.player.inv.can_add(id) else "Nothing to move.")
	qp.cancelled.connect(func(): show(ui, sid))
	qp.confirmed.connect(func(q: int):
		var why := ""
		match mode:
			"put":
				why = biz.list_item(s, id, q)
			"store":
				why = biz.store_item(s, id, q)
			"fetch":
				why = biz.fetch(s, id, q)
			_:
				why = biz.unlist(s, id, q)
		ui.message(why if why != "" else ("%d %s %s." % [q, nm.to_lower(), {"put": "put up for sale", "store": "stored in the back room"}.get(mode, "back in your pack")])))
	qp.confirmed.connect(func(_q: int): show(ui, sid))
	ui.panel_body.add_child(qp)
	ui.panel_body.move_child(qp, 0)
	if ui.scheme != "touch":
		qp.focus_default.call_deferred()
