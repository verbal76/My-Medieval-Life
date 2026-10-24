extends SceneTree
## GP-MARKET-SHELVES (owner directives 2026-10-24: build21_craftpix_market_stalls, build21_final_execution), in the real game
## scene: every market stall is drawn as the owner's Craftpix shelf among the characters, its old tiles off the drawn map,
## its cells as solid as before; it shows the goods actually on offer, up to ten kinds standing on its two boards, the
## player's pitch from its stock, a merchant's stall from what the merchant at it offers (nothing while they are away), and
## follows listing and unlisting; the shelves move no goods and no coins; a guest's copy of the world (the stalls and
## villagers it is sent) shows the same shelves.
##   godot --headless --path game --script res://tests/market_shelf_test.gd

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
	main.save_path = "user://test_saves/market_shelf_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func shelf(id: String) -> StallShelf:
	return main.stall_display_view.shelves.get(id)


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var biz: Business = w.business
	var sdv: StallDisplayView = main.stall_display_view
	sdv.refresh()
	var ids: Array = w.stalls.keys()
	ids.sort()
	check(ids.size() >= 10 and ids.all(func(id): return shelf(id) != null and shelf(id).get_parent() == main.actors), "every market stall has a shelf among the characters (%d)" % ids.size())
	var tex := StallShelf.texture_of("light")
	check(tex != null and tex.get_width() == 53 and tex.get_height() == 43 and StallShelf.texture_of("dark") != null, "the shelves are the imported 53 x 43 Craftpix units")
	var b0 := main.view.layer("below0") as TileMapLayer
	var cleared := true
	var solid := true
	for id in ids:
		var s: Dictionary = w.stalls[id]
		for k in 2:
			var c := Vector2i(int(s.x) + k, int(s.y))
			cleared = cleared and b0.get_cell_source_id(c) < 0
			solid = solid and w.map.is_solid(c)
		solid = solid and shelf(id).position == Vector2((int(s.x) + 1) * 16, (int(s.y) + 1) * 16)
	check(cleared, "the stalls' old table, crate and awning tiles are off the drawn map")
	check(solid, "every stall's two cells are as solid as before (collision unchanged), its shelf on the footprint")
	# the ten slots stand on the boards, inside the shelf
	var inside := true
	for i in 10:
		var r := Rect2(StallShelf.slot_pos(i), Vector2(8, 8))
		var art := Rect2(Vector2(-StallShelf.HALF_W, -StallShelf.H + StallShelf.DROP), Vector2(StallShelf.W, StallShelf.H))
		inside = inside and art.encloses(r) and int(r.end.y) == -StallShelf.H + StallShelf.DROP + int(StallShelf.BOTTOMS[floori(i / 5.0)]) + 1
	var row0 := range(5).map(func(i): return StallShelf.slot_pos(i))
	check(inside and row0[4].x + 8 <= StallShelf.W - StallShelf.HALF_W - 4, "ten goods fit on the two boards, each standing on its board, none past the posts")
	# the player's pitch: listing and unlisting
	var p := w.player
	p.coins = 200
	check(biz.rent() == "", "the player rents a pitch")
	var mine: Dictionary = biz.mine()
	var id0 := str(mine.id)
	sdv.refresh()
	check(shelf(id0).goods.is_empty(), "an empty stall shows an empty shelf")
	var ten := ["wheat", "bread", "pottage", "apple", "cheese", "iron_ore", "plank", "pickaxe", "ale", "herbal_poultice", "log"]
	for i in ten.size():
		p.inv.add(ten[i], 12 - i)
	var coins0 := w.total_coins()
	for i in 3:
		biz.list_item(mine, ten[i], 12 - i)
	sdv.refresh()
	check(shelf(id0).goods == ["wheat", "bread", "pottage"], "a partly stocked stall shows its three kinds (%s)" % str(shelf(id0).goods))
	for i in range(3, ten.size()):
		biz.list_item(mine, ten[i], 12 - i)
	sdv.refresh()
	check(shelf(id0).goods.size() == 10 and shelf(id0).goods == ten.slice(0, 10), "eleven kinds listed: the ten most held show, one display a kind (%s)" % str(shelf(id0).goods))
	var stock_before: Dictionary = mine.stock.duplicate()
	for k in 5:
		sdv.refresh()
	check(mine.stock == stock_before and w.total_coins() == coins0, "drawing the shelves moves no goods and no coins")
	biz.unlist(mine, "wheat", int(mine.stock.wheat))
	sdv.refresh()
	check(not shelf(id0).goods.has("wheat") and shelf(id0).goods.has("log"), "a kind taken off the stall leaves the shelf, the next one shows")
	# a merchant's stall: what the merchant offers while at it, nothing while away
	var merchant: NPC = null
	for n: NPC in w.npcs:
		if n.job == "merchant" and w.stalls.has(n.workplace) and merchant == null:
			merchant = n
	check(merchant != null, "a merchant with a stall")
	if merchant != null:
		var sid := merchant.workplace
		merchant.pos = w.shop_post(merchant)
		merchant.target = -1
		w.minutes = 1440.0 + 10.0 * 60.0
		var want := biz.merchant_goods(merchant, 10)
		sdv.refresh()
		check(biz.stalls.is_open(w.stalls[sid]) and not want.is_empty() and shelf(sid).goods == want, "a merchant at the stall: the shelf shows what they offer (%s)" % str(want))
		merchant.pos = Vector2(5.5, 5.5)
		sdv.refresh()
		check(shelf(sid).goods.is_empty(), "the merchant away: the shelf is empty")
		merchant.pos = w.shop_post(merchant)
	# a guest's copy: the same shelves from the sections the host sends
	var copy := World.new()
	copy.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var a: Array = biz.shelves()
	var b: Array = copy.business.shelves()
	check(JSON.stringify(a) == JSON.stringify(b), "a copy of the world made from its save shows the same shelves (as a guest's)")
	copy.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
