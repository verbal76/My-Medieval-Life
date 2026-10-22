class_name CourierWindow
extends RefCounted
## PROSPECTIVE (Expansion 18, X18-Q12-POST; PROS-18): the courier contract window, "like online postage": choose the
## service (regular route or special delivery), item and quantity, a recipient you know (a person or a business), where to
## deliver (from the world's records), whether the courier collects payment (money or an item and how much) and whether
## the proceeds come back to you or wait at your booth; for a special delivery, the courier and your offer. "Review"
## shows the delivery instruction and the fee, worked out by CourierService (the rules are in core; this window only shows
## them and collects the choices, DVW-A12); "Confirm" books it. Built from GameUI's own widgets, like the other windows.
## Not reachable from the live game yet (no menu entry until integration); tests/courier_window_shot.gd opens it.

var ui: GameUI
var service: CourierService
var sender := "player"
var choice := {"kind": 1, "item": 0, "qty": 1, "recipient": 0, "where": 0, "collect": false, "pay_kind": 0, "pay_amount": 0,
	"proceeds": 0, "courier": 0, "offer": 0}
var review := ""


func _init(game_ui: GameUI, courier_service: CourierService) -> void:
	ui = game_ui
	service = courier_service


func _items() -> Array:
	return service.inv_of(sender).ids()


func _recipients() -> Array:
	return service.known_recipients(sender)


func _couriers() -> Array:
	var out := []
	for b in service.booths:
		if str(b.keeper).begins_with("npc:") and service.alive(str(b.keeper)):
			out.append(str(b.keeper))
	return out


## The order the current choices describe (what CourierService books).
func order() -> Dictionary:
	var items := _items()
	var recs := _recipients()
	var o := {"sender": sender, "items": {}, "kind": "route" if int(choice.kind) == 0 else "special"}
	if not items.is_empty():
		o.items = {str(items[clampi(int(choice.item), 0, items.size() - 1)]): int(choice.qty)}
	if not recs.is_empty():
		var r: Dictionary = recs[clampi(int(choice.recipient), 0, recs.size() - 1)]
		o.recipient = r.ref
		o.recipient_kind = r.kind
		var locs := service.locations(str(r.ref))
		var l: Dictionary = locs[clampi(int(choice.where), 0, locs.size() - 1)]
		o.settlement = l.settlement
		o.where = l
	if bool(choice.collect):
		var kinds := ["coins"] + _items()
		var k: String = kinds[clampi(int(choice.pay_kind), 0, kinds.size() - 1)]
		o.collect = {"kind": "coins", "amount": int(choice.pay_amount)} if k == "coins" else {"kind": "item", "item": k, "amount": int(choice.pay_amount)}
	o.proceeds = "deliver" if int(choice.proceeds) == 0 else "deposit"
	var cs := _couriers()
	if not cs.is_empty():
		o.courier = cs[clampi(int(choice.courier), 0, cs.size() - 1)]
	if o.kind == "route":
		for r in service.routes:
			if str(service.booth(str(r.to)).settlement) == str(o.get("settlement", "")):
				o.route = r.id
	return o


func show() -> void:
	ui._open("courier", "Courier")
	if review != "":                                 # the assembled instruction first, where it is seen, then the form
		ui._label(review, 18, Color(1, 0.9, 0.6))
		ui._button("Confirm", func(): _confirm())
	var grid := GridContainer.new()
	grid.columns = 2
	ui.panel_body.add_child(grid)
	_row(grid, "Service", ["Regular route (flat fee a load)", "Special delivery (negotiated)"], "kind")
	var items := _items()
	_row(grid, "Item", items.map(func(id): return "%s (you have %d)" % [GameData.item_name(id), service.inv_of(sender).count(id)]), "item")
	_spin(grid, "Quantity", 1, maxi(1, service.inv_of(sender).count(str(items[clampi(int(choice.item), 0, items.size() - 1)])) if not items.is_empty() else 1), "qty")
	var recs := _recipients()
	_row(grid, "Recipient", recs.map(func(r): return "%s (%s)" % [r.name, "business" if r.kind == "business" else "person"]), "recipient")
	var where := []
	if not recs.is_empty():
		where = service.locations(str(recs[clampi(int(choice.recipient), 0, recs.size() - 1)].ref)).map(func(l): return "%s, %s" % [l.what, l.settlement])
	_row(grid, "Deliver to", where, "where")
	_check(grid, "Collect payment", "collect")
	_row(grid, "Payment in", ["coins"] + items.map(func(id): return GameData.item_name(id)), "pay_kind")
	_spin(grid, "Amount", 0, 9999, "pay_amount")
	_row(grid, "Proceeds", ["Bring them to me", "Deposit them at my booth"], "proceeds")
	if int(choice.kind) == 1:
		_row(grid, "Courier", _couriers().map(func(c): return service._entry(c, "person", "").name), "courier")
		_spin(grid, "Your offer (coins)", 0, 9999, "offer")
	ui._button("Review the delivery", func():
		var o := order()
		var why := service.refusal(o) if o.has("recipient") else "Choose someone you know to deliver to."
		review = why if why != "" else service.describe(o)
		show())


func _confirm() -> void:
	var o := order()
	var res := {}
	if o.kind == "route":
		res = service.book_route(o)
	else:
		var n := service.negotiate(o, int(choice.offer))
		if str(n.answer) != "accept":
			review = "%s (counter-offer: %d coins)" % [str(n.get("say", "No.")), int(n.fee)]
			choice.offer = int(n.fee)
			show()
			return
		res = service.book_special(o, int(n.fee))
	review = str(res.error) if res.has("error") else "Booked: %s" % service.describe(o)
	show()


func _label_cell(grid: GridContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	grid.add_child(l)


func _row(grid: GridContainer, text: String, options: Array, key: String) -> void:
	_label_cell(grid, text)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(360, 40)
	for o in options:
		ob.add_item(str(o))
	if options.is_empty():
		ob.add_item("(none)")
		ob.disabled = true
	ob.select(clampi(int(choice[key]), 0, maxi(0, options.size() - 1)))
	ob.item_selected.connect(func(i: int):
		choice[key] = i
		review = ""
		show())
	grid.add_child(ob)


func _spin(grid: GridContainer, text: String, lo: int, hi: int, key: String) -> void:
	_label_cell(grid, text)
	var sb := SpinBox.new()
	sb.min_value = lo
	sb.max_value = hi
	sb.value = clampi(int(choice[key]), lo, hi)
	sb.custom_minimum_size = Vector2(160, 40)
	sb.value_changed.connect(func(v: float):
		choice[key] = int(v)
		review = "")
	grid.add_child(sb)


func _check(grid: GridContainer, text: String, key: String) -> void:
	_label_cell(grid, text)
	var cb := CheckBox.new()
	cb.button_pressed = bool(choice[key])
	cb.toggled.connect(func(on: bool):
		choice[key] = on
		review = ""
		show())
	grid.add_child(cb)
