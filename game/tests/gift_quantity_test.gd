extends SceneTree
## GP-GIFT-QUANTITY (owner, 2026-10-24: "I just gave somebody 35 herbal poultices. By accident"), in the real game scene:
## choosing a gift opens the quantity picker at one; Give moves exactly the number chosen; Cancel moves none; one of a kind
## goes at once; five at once is one gift (the regard of one gift); tapping Enter over and over through the windows never
## moves a stack. The gift code moved one item a call before too: the owner's path was not found in the code (no window
## gives a stack), so the picker and the input checks here are the guard against it.
##   godot --headless --path game --script res://tests/gift_quantity_test.gd

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
	main.save_path = "user://test_saves/gift_quantity_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func picker() -> QuantityPicker:
	return main.ui.panel_body.find_child("QuantityPicker", true, false)


func press_item(id: String) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(GameData.item_name(id)) and (b as Button).is_visible_in_tree():
			(b as Button).pressed.emit()
			return true
	return false


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var p := w.player
	var a: NPC = null
	var b: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "guard":
			if a == null:
				a = o
			elif b == null and o.household != a.household:
				b = o
	p.inv.add("herbal_poultice", 35)
	p.pos = a.pos + Vector2(0.8, 0)
	var ui = main.ui
	ui.show_gifts(a)
	await frames()
	check(press_item("herbal_poultice") and picker() != null and picker().qty == 1, "choosing a gift asks how many, starting at one")
	picker().cancel()
	await frames()
	check(p.inv.count("herbal_poultice") == 35 and ui.panel_kind == "gifts", "Cancel gives nothing")
	press_item("herbal_poultice")
	await frames()
	picker().confirmed.emit(picker().qty)
	await frames()
	check(p.inv.count("herbal_poultice") == 34 and a.inv.count("herbal_poultice") >= 1, "Give at one moves exactly one")
	# five at once: one gift's regard
	var t0: float = float(w.relations.peek(w.acting_id(), b.id).regard)
	var e1: Dictionary = w.relations.gift_effect(w.acting_id(), b, "herbal_poultice")
	ui.show_gifts(b)
	await frames()
	press_item("herbal_poultice")
	await frames()
	picker().confirmed.emit(5)
	await frames()
	var t1: float = float(w.relations.peek(w.acting_id(), b.id).regard)
	check(p.inv.count("herbal_poultice") == 29 and b.inv.count("herbal_poultice") >= 5, "the number chosen, five, moves")
	check(absf((t1 - t0) - float(e1.regard)) < 0.01, "five at once is one gift's regard (%.2f, one gift %.2f)" % [t1 - t0, float(e1.regard)])
	# one of a kind goes at once
	p.inv.add("flower", 1)
	ui.show_gifts(b)
	await frames()
	var f0 := b.inv.count("flower")
	press_item("flower")
	await frames()
	check(picker() == null and p.inv.count("flower") == 0 and b.inv.count("flower") == f0 + 1, "a single item is given at once, no picker")
	# tapping Enter again and again from the gift window: at most one moves each time the picker is confirmed, never a stack
	ui.scheme = "kbm"
	ui.show_gifts(a)
	await frames(4)
	var before := p.inv.count("herbal_poultice")
	for k in 40:
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_ENTER
		ev.keycode = KEY_ENTER
		ev.pressed = true
		root.push_input(ev)
		await process_frame
		var up: InputEventKey = ev.duplicate()
		up.pressed = false
		root.push_input(up)
		await frames(2)
	check(before - p.inv.count("herbal_poultice") <= 1, "tapping Enter forty times moves at most one poultice (%d moved)" % (before - p.inv.count("herbal_poultice")))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
