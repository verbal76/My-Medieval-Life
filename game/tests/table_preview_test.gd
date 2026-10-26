extends SceneTree
## GP-TABLE-ITEMS (owner clarification 2026-10-24: tables are not item-pickup containers; they show a visual preview of the
## merchandise the business offers, with no transaction), in the real game scene:
##   * each business desk's table (the tavern's counter, the smithy's ledger table, the sawmill's table) shows the goods its
##     business offers (its keeper's goods for sale, NPCBrain.for_sale), on the drawn table either side of the ledger;
##   * the preview follows the real listings: a new good appears, a sold-out one goes, nothing for sale shows nothing;
##   * the tavern's tables show the dish the tavern serves while it serves it; a table with nothing on it is a preview, not
##     something to take: its prompt says to buy at the counter, and nothing can be taken from it;
##   * looking moves nothing: coins and goods are the same after any number of previews.
##   godot --headless --path game --script res://tests/table_preview_test.gd

const Census := preload("res://tests/census.gd")

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
	main.save_path = "user://test_saves/table_preview_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _at(previews: Array, c: Vector2i) -> Array:
	for p in previews:
		if int(p.x) == c.x and int(p.y) == c.y:
			return p.goods
	return []


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var biz: Business = w.business
	var arm: String = w.stations_of("armory_counter")[0]
	var tav: String = w.stations_of("tavern_counter")[0]
	var saw: String = w.stations_of("sawmill_counter")[0]
	var coins0 := w.total_coins()
	var goods0 := JSON.stringify(Census.goods(w))
	var pv := biz.desk_previews()
	for i in 50:                                         # looking moves nothing
		biz.desk_previews()
		w.table_offer()
		w.show_tables()
	check(w.total_coins() == coins0 and JSON.stringify(Census.goods(w)) == goods0, "previews move no coins and no goods")
	# --- the smithy's table: the smith's goods either side of the ledger
	var smith := biz.desk_keeper(arm)
	var cells := BusinessDesks.table_cells(w, BusinessDesks.by_id(w, arm))
	check(cells == [Vector2i(70, 43), Vector2i(72, 43)], "the smithy's goods are shown either side of the open ledger (%s)" % str(cells))
	var shown: Array = _at(pv, cells[0]) + _at(pv, cells[1])
	check(smith != null and smith.job == "smith" and shown == biz.merchant_goods(smith, 4) and not shown.is_empty(), "they are what the smith offers (%s)" % str(shown))
	check(BusinessDesks.table_cells(w, BusinessDesks.by_id(w, tav)) == [Vector2i(44, 40), Vector2i(46, 40)], "the tavern's counter shows its goods either side of its ledger")
	var tk := biz.desk_keeper(tav)
	var tshown: Array = _at(pv, Vector2i(44, 40)) + _at(pv, Vector2i(46, 40))
	check(tk != null and tk.job == "tavernkeeper" and tshown == biz.merchant_goods(tk, 4), "what the tavernkeeper offers (%s)" % str(tshown))
	check(BusinessDesks.table_cells(w, BusinessDesks.by_id(w, saw)) == [Vector2i(68, 25)], "the sawmill's one-cell table")
	# --- it follows the listings
	var carp := biz.desk_keeper(saw)
	if carp != null:
		carp.inv.items.clear()
		check(_at(biz.desk_previews(), Vector2i(68, 25)).is_empty(), "a keeper with nothing for sale: an empty table")
		carp.inv.add("plank", 9)
		check(_at(biz.desk_previews(), Vector2i(68, 25)) == ["plank"], "planks to sell: planks on the table")
		carp.inv.add("cart_wheel", 12)
		check(_at(biz.desk_previews(), Vector2i(68, 25)) == ["cart_wheel", "plank"], "a new good shows, most held first")
		carp.inv.remove("cart_wheel", 12)
		check(_at(biz.desk_previews(), Vector2i(68, 25)) == ["plank"], "sold out: it goes")
	var sdv: StallDisplayView = main.stall_display_view
	sdv.refresh()
	check(sdv.shown.any(func(e): return int(e.x) == 70 and int(e.y) == 43), "the view draws the desks' tables (StallDisplayView)")
	# --- the tavern's tables: a preview of what is served, nothing to take
	var table := {}
	for c in w.containers:
		if c.kind == "table":
			table = c
			break
	for id in table.inv.ids():                             # the keeper takes back what was set out (as at closing)
		w.transfer(table.inv, tk.inv, id, table.inv.count(id))
	if not w.table_offer().has(str(table.dish)):
		tk.inv.add(str(table.dish), 10)
	check(not table.is_empty() and w.table_previews(table), "an empty tavern table whose dish the tavern serves is a preview (%s)" % str(table.get("dish", "")))
	var drawn := {}
	w.tile_changed.connect(func(cell, _l, v): drawn[cell] = v)
	w.show_tables()
	check(int(drawn.get(Vector2i(int(table.x), int(table.y)), -1)) == int(table.tile), "it is drawn with its dish")
	var tgt: Dictionary = main._container_target(table)
	check(str(tgt.kind) == "info" and str(tgt.label).contains("buy it at the counter") and not tgt.get("theft", false), "its prompt says to buy at the counter, no taking (%s)" % str(tgt.label))
	var pack := JSON.stringify(w.player.inv.items)
	w.player.pos = Vector2(int(table.x), int(table.y)) + Vector2(0.5, 1.5)
	var took := w.player_take(table)
	check(took == "" and JSON.stringify(w.player.inv.items) == pack and w.player.crimes.is_empty(), "nothing can be taken from it (%s)" % took)
	for k in tk.inv.ids():
		if str(k) == str(table.dish):
			tk.inv.remove(k, tk.inv.count(k))
	drawn.clear()
	w.show_tables()
	check(int(drawn.get(Vector2i(int(table.x), int(table.y)), 0)) == -1 and not w.table_previews(table), "the tavern no longer serving it: the bare table")
	# --- no table or desk cell is an item container
	var cont := {}
	for c in w.containers:
		cont[Vector2i(int(c.x), int(c.y))] = true
	check(not (cells + [Vector2i(44, 40), Vector2i(46, 40), Vector2i(68, 25)]).any(func(c): return cont.has(c)), "no desk table is an item container")
	print("\ntable_preview_test: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	quit(1 if failures > 0 else 0)
