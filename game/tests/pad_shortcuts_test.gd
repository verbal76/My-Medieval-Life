extends SceneTree
## GP-QTY-PICKER-CONTROLLER and GP-SKILLS-RT (owner, 2026-10-26), in the real game scene, with the pad's events pushed
## through the viewport as a controller sends them:
## - every quantity picker (stall Put up, a gift, buying, selling, a chest) takes X to the least (1) and Y to the most the
##   caller allows (the coins, the stock, what is carried and wanted, the room) in one press, shows the X / Y prompt with a
##   gamepad, and the press neither confirms nor reaches another control; keyboard, mouse and touch are as before;
## - RT opens Skills in play (once per pull, however the axis wobbles), closes it on the next pull like RB; inside a window
##   it still steps through the buttons and opens nothing; RB keeps opening Skills.
##   godot --headless --path game --script res://tests/pad_shortcuts_test.gd

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/pad_shortcuts_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func picker() -> QuantityPicker:
	return main.ui.panel_body.find_child("QuantityPicker", true, false)


func pad(button: int) -> void:
	for down in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = button
		e.pressed = down
		root.push_input(e)
		await process_frame


func rt(value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_TRIGGER_RIGHT
	e.axis_value = value
	root.push_input(e)
	await process_frame


## X then Y on the open picker: the least, then the most the caller set; nothing confirmed, the window still open.
func min_max(where: String, want_max: int) -> void:
	var qp := picker()
	if qp == null:
		check(false, "%s: a quantity picker is open" % where)
		return
	var fired := [0]
	qp.confirmed.connect(func(_q): fired[0] += 1)
	check(qp.pad_row != null and qp.pad_row.visible, "%s: the X Min / Y Max prompt shows with a gamepad" % where)
	await pad(JOY_BUTTON_Y)
	check(qp.qty == want_max and qp.qty == qp.max_qty, "%s: Y sets the most allowed in one press (%d of %d)" % [where, qp.qty, want_max])
	await pad(JOY_BUTTON_X)
	check(qp.qty == 1, "%s: X sets the least, 1, in one press (%d)" % [where, qp.qty])
	await pad(JOY_BUTTON_Y)
	check(fired[0] == 0 and picker() == qp and main.ui.modal(), "%s: the press confirms nothing and the window stays" % where)


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var p := w.player
	var ui = main.ui
	ui.set_scheme("gamepad")
	await frames()
	# --- GP-SKILLS-RT ---
	ui.hide_all()
	await frames()
	await rt(1.0)
	check(ui.panel_kind == "skills", "RT in play opens Skills")
	for v in [0.9, 1.0, 0.8, 1.0]:
		await rt(v)                                   # one pull, the axis wobbling: never a second toggle
	check(ui.panel_kind == "skills", "one pull of RT opens it once, however the axis moves while held")
	await rt(0.0)
	var focus0: Control = main.get_viewport().gui_get_focus_owner()
	await rt(1.0)
	check(ui.panel_kind == "skills" and main.get_viewport().gui_get_focus_owner() != focus0, "in the Skills window RT steps through its buttons, as in any window")
	await rt(0.0)
	ui.hide_all()
	await frames()
	ui.show_talk(w.npcs.filter(func(n): return n.alive and n.role != "bandit")[0])
	await frames()
	await rt(1.0)
	await rt(0.0)
	check(ui.panel_kind == "talk", "inside a talk window RT never opens Skills")
	ui.hide_all()
	await frames()
	for down in [true, false]:                        # RB through the Input singleton, as the game reads its actions
		var e := InputEventJoypadButton.new()
		e.button_index = JOY_BUTTON_RIGHT_SHOULDER
		e.pressed = down
		Input.parse_input_event(e)
		await process_frame
	await frames()
	check(ui.panel_kind == "skills", "RB still opens Skills")
	ui.hide_all()
	check(GameUI.CONTROLS.gamepad.any(func(r): return r[0].has("xbox_rt") and str(r[1]).begins_with("Skills")), "the controller guide shows RT for Skills")
	check(GameUI.CONTROLS.gamepad.any(func(r): return r[0].has("xbox_button_x") and r[0].has("xbox_button_y") and str(r[1]).contains("quantity")), "the controller guide shows X / Y in a quantity choice")
	# --- GP-QTY-PICKER-CONTROLLER ---
	var a: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "guard":
			a = o
			break
	p.inv.add("herbal_poultice", 12)
	p.pos = a.pos + Vector2(0.8, 0)
	ui.show_gifts(a)
	await frames()
	for b in ui.panel_body.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(GameData.item_name("herbal_poultice")):
			(b as Button).pressed.emit()
			break
	await frames()
	var held := p.inv.count("herbal_poultice")
	await min_max("gift", picker().max_qty if picker() else -1)
	check(p.inv.count("herbal_poultice") == held, "gift: nothing was given by X or Y")
	ui.hide_all()
	# the stall's Put up
	p.coins = 300
	check(w.business.rent() == "", "a pitch rented")
	var s: Dictionary = w.business.mine()
	p.inv.add("pottage", 9)
	StallWindow.show(ui, str(s.id), {"id": "pottage", "mode": "put"})
	await frames()
	await min_max("stall put-up", w.business.listable("pottage"))
	check(int(s.stock.get("pottage", 0)) == 0, "stall put-up: nothing went up by X or Y")
	ui.hide_all()
	# buying and selling at a merchant
	var m: NPC = null
	var sell_id := ""
	for o: NPC in w.npcs:
		if o.alive and o.job == "merchant" and not w.brain.for_sale(o).is_empty():
			m = o
			break
	check(m != null, "a merchant with goods")
	if m != null:
		var buy_id: String = str(w.brain.for_sale(m)[0])
		p.coins = 5000
		ui.show_trade(m, {"id": buy_id, "mode": "buy"})
		await frames()
		var mx_buy: int = picker().max_qty if picker() else -1
		check(mx_buy >= 1 and mx_buy <= m.inv.count(buy_id), "buy: the most is bounded by the stock (%d of %d)" % [mx_buy, m.inv.count(buy_id)])
		var c0 := p.coins
		await min_max("buy", mx_buy)
		check(p.coins == c0, "buy: X or Y spent nothing")
		ui.hide_all()
		p.coins = 0
		ui.show_trade(m, {"id": buy_id, "mode": "buy"})
		await frames()
		check(picker() != null and picker().max_qty == 0 and picker().pad_row == null, "buy with no coins: nothing to choose, so no shortcut can pick an amount")
		await pad(JOY_BUTTON_Y)
		check(picker() != null and picker().qty == 0 and p.inv.count(buy_id) >= 0 and p.coins == 0, "buy with no coins: Y does nothing")
		ui.hide_all()
		for id in GameData.items:
			if w.brain.wants(m, id) > 0:
				sell_id = id
				break
		if sell_id != "":
			p.inv.add(sell_id, 6)
			ui.show_trade(m, {"id": sell_id, "mode": "sell"})
			await frames()
			var mx_sell: int = w.purchase_qty(m, p, sell_id, p.inv.count(sell_id))
			if mx_sell > 0:
				await min_max("sell", mx_sell)
			else:
				check(picker() != null and picker().max_qty == 0, "sell: the merchant takes none now, and the picker offers none")
			ui.hide_all()
	# keyboard and mouse: unchanged (no X / Y prompt; the Max button still sets the most)
	ui.set_scheme("kbm")
	ui.show_gifts(a)
	await frames()
	for b in ui.panel_body.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(GameData.item_name("herbal_poultice")):
			(b as Button).pressed.emit()
			break
	await frames()
	var qp := picker()
	check(qp != null and not qp.pad_row.visible, "with keyboard and mouse no pad prompt shows")
	qp.max_btn.pressed.emit()
	check(qp.qty == qp.max_qty, "the Max button still works")
	ui.hide_all()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
