extends SceneTree
## GP-STALL-PRICE-ON-PUTUP (owner, 2026-10-24: "you should set the price as you sell it, not after"), in the real game scene:
## the stall's Put up dialog holds a price row under the quantity, starting at the price asked now (the market value for
## a new kind), raised and lowered with - and + or typed; Put up lists the goods at that price; the price can still be
## changed afterwards; the workroom's Put up does the same, and its Set aside and Bring back move what they say.
##   godot --headless --path game --script res://tests/stall_putup_test.gd

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
	main.save_path = "user://test_saves/stall_putup_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func find(name: String) -> Node:
	return main.ui.panel_body.find_child(name, true, false)


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var biz: Business = w.business
	var p := w.player
	p.coins = 200
	check(biz.rent() == "", "a pitch rented")
	var s: Dictionary = biz.mine()
	var sid := str(s.id)
	p.inv.add("pottage", 10)
	StallWindow.show(main.ui, sid, {"id": "pottage", "mode": "put"})
	await frames()
	var pe = find("PutUpPrice")
	var qp: QuantityPicker = find("QuantityPicker")
	check(pe != null and qp != null and pe.price == GameData.value("pottage"), "Put up shows the number and the price together, from the market value (%s)" % (str(pe.price) if pe else "-"))
	for b in pe.find_children("*", "Button", true, false):
		if (b as Button).text == "+":
			(b as Button).pressed.emit()
			(b as Button).pressed.emit()
	var want: int = GameData.value("pottage") + 2
	check(pe.price == want, "+ raises the price (%d)" % pe.price)
	qp.qty = 3
	qp.confirmed.emit(3)
	await frames()
	check(int(s.stock.get("pottage", 0)) == 3 and biz.price_of(s, "pottage") == want and p.inv.count("pottage") == 7, "Put up lists three at the chosen price %d" % biz.price_of(s, "pottage"))
	StallWindow.show(main.ui, sid, {"id": "pottage", "mode": "put"})
	await frames()
	check(find("PutUpPrice").price == want, "putting more up starts at the price asked now")
	find("QuantityPicker").cancelled.emit()
	await frames()
	check(biz.set_price(s, "pottage", want + 1) == "" and biz.price_of(s, "pottage") == want + 1, "the price can still be changed afterwards")
	# typed: a price beyond the cap is held at the cap
	StallWindow.show(main.ui, sid, {"id": "pottage", "mode": "put"})
	await frames()
	var edit: LineEdit = find("PutUpPrice").find_child("PriceEdit", true, false)
	edit.text_changed.emit("99999")
	check(find("PutUpPrice").price == GameData.value("pottage") * Business.PRICE_CAP, "a typed price is held to the cap")
	find("QuantityPicker").cancelled.emit()
	await frames()
	# the workroom's verbs: Set aside, Bring back, Put up (with its price)
	p.inv.add("plank", 6)
	StallWindow.show(main.ui, sid, {"id": "plank", "mode": "wput"})
	await frames()
	find("QuantityPicker").confirmed.emit(4)
	await frames()
	check(int(biz.works.work_of(s).get("plank", 0)) == 4 and p.inv.count("plank") == 2, "Set aside moves planks from the pack into the workroom")
	StallWindow.show(main.ui, sid, {"id": "plank", "mode": "wfetch"})
	await frames()
	find("QuantityPicker").confirmed.emit(1)
	await frames()
	check(int(biz.works.work_of(s).get("plank", 0)) == 3 and p.inv.count("plank") == 3, "Bring back moves one back to the pack")
	StallWindow.show(main.ui, sid, {"id": "plank", "mode": "shelve"})
	await frames()
	check(find("PutUpPrice") != null, "the workroom's Put up has the price row too")
	find("PutUpPrice")._put(GameData.value("plank") + 1)
	find("QuantityPicker").confirmed.emit(2)
	await frames()
	check(int(s.stock.get("plank", 0)) == 2 and int(biz.works.work_of(s).get("plank", 0)) == 1 and biz.price_of(s, "plank") == GameData.value("plank") + 1,
		"the workroom's Put up moves two from the workroom to sale at the chosen price")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
