extends SceneTree
## GP-POLISH P2 (the owner's polish reports of 2026-10-24), checked in the real game scene, headless:
##   godot --headless --path game --script res://tests/polish_p2_test.gd
## GP-PACK-DETAIL-FIT: every item's details and action buttons in the pack lie inside the screen, on a phone in landscape
## (2000 x 1119, 2404 x 1080, 2000 x 1145; the phone layout), 16:9, 16:10 and a Steam Deck, at each interface size.
## GP-WHEAT-PICKED: cutting a ripe wheat field shows stubble on the cells cut, nearest the harvester first, kept through a
## save; a cut wheat cell of the player's farm shows stubble.
## GP-DRAW-UNDER-HOUSE: every building's front edge is drawn among the characters, so whoever stands in front is drawn
## over it (house_front_shot.gd shows it).

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		printerr("FAIL: " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("new_game"):
		print("FAIL the game's main script did not load: stopping")
		quit(1)
		return
	main.save_path = "user://test_saves/polish_p2_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	main.new_game()
	_draw_under_house()
	_wheat_picked()
	_back_doors()
	await _pack_fit()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## GP-DRAW-UNDER-HOUSE (owner: "the character is half under the house").
func _draw_under_house() -> void:
	var view: MapView = main.view
	var map: VillageMap = main.map
	check(not view.roof_layers.is_empty(), "draw order: the map has roof layers")
	var roofed := func(c: Vector2i) -> bool:
		for l in view.roof_layers:
			if view.tile_value(l, c) >= 0:
				return true
		return false
	var fronts := 0
	var over := 0
	var wrong := 0
	for l in view.roof_layers:
		var twin: TileMapLayer = view.sorted_of.get(l)
		if twin == null:
			wrong += 1
			continue
		if twin.get_parent() != main.actors or not twin.y_sort_enabled:
			wrong += 1
		for c: Vector2i in l.get_used_cells():
			if map.is_solid(c) and not roofed.call(c + Vector2i.DOWN):
				over += 1              # a front-edge cell drawn over everyone: the reported fault
		for c: Vector2i in twin.get_used_cells():
			fronts += 1
			if not (map.is_solid(c) and not roofed.call(c + Vector2i.DOWN)):
				wrong += 1             # only the front edge is sorted: the rest of a roof stays over a villager indoors
	check(fronts > 100, "draw order: the buildings' front edges are drawn among the characters (%d cells)" % fronts)
	check(over == 0, "draw order: no front-edge cell of a building is drawn over the characters (%d)" % over)
	check(wrong == 0, "draw order: only front-edge cells are sorted, in the characters' own y-sorted node (%d wrong)" % wrong)
	# the first house: someone standing on the grass in front is sorted after the wall
	var b: Dictionary = main.world.buildings.values()[0]
	var door := Vector2i(int(b.door[0]), int(b.door[1]))
	var x := door.x + 1
	var y := int(b.y) + int(b.h)
	while y > int(b.y) and not roofed.call(Vector2i(x, y)):
		y -= 1
	var stand_y: float = (y + 1 + 0.16) * main.T            # the nearest the feet come to the wall (Main.BODY)
	var wall_y: int = (y + 1) * main.T                     # the wall tile sorts by its cell's bottom edge (MapView.SORT_ORIGIN)
	check(stand_y > wall_y, "draw order: the feet in front of %s sort after its wall (%.1f > %d)" % [str(b.id), stand_y, wall_y])
	# the lifted roof takes the front edge with it (inside, the room shows), and puts it back
	var roofs: RoofFade = main.roofs
	var roof_cells: Array = main.world.interiors[str(b.id)].roof if main.world.interiors.has(str(b.id)) else []
	if not roof_cells.is_empty():
		roofs.update(str(b.id), roof_cells, RoofFade.ALPHA, 0.0)
		var left := 0
		for l in view.roof_layers:
			var twin: TileMapLayer = view.sorted_of[l]
			for c in roof_cells:
				if twin.get_cell_source_id(Vector2i(int(c[0]), int(c[1]))) >= 0:
					left += 1
		check(left == 0, "draw order: lifting %s's roof lifts its front edge too (%d cells left)" % [str(b.id), left])
		roofs.restore_all()
		check(roofed.call(Vector2i(x, y)), "draw order: the front edge comes back when the roof does")


## GP-WHEAT-PICKED (owner: "when i harvest the wheat it doesnt turn into a picked wheat sprite").
func _wheat_picked() -> void:
	var w: World = main.world
	var cv: CropView = main.crop_view
	var f: Dictionary = w.fields[0]
	w.set_field(f, "ripe")
	f.crop = int(GameData.b("field_yield"))
	f.crop_full = int(f.crop)
	var n := int(f.w) * int(f.h)
	check(cv.cut_cells(f).is_empty(), "wheat: a ripe field nobody has cut shows no stubble")
	var corner := Vector2(int(f.x) + int(f.w) + 0.5, int(f.y) + int(f.h) - 0.5)    # beside its south-east corner
	w.player.pos = corner
	var took := 0
	var guard := 0
	while took * 2 < int(f.crop_full) and guard < 1000:
		took += w.player_harvest(f)
		guard += 1
	var cut := cv.cut_cells(f)
	var want := floori(float(took) / float(f.crop_full) * n + 1e-6)
	check(cut.size() == want and want > 0, "wheat: %d of %d taken, %d of %d cells show stubble (%d)" % [took, int(f.crop_full), cut.size(), n, want])
	var near := Vector2i(int(f.x) + int(f.w) - 1, int(f.y) + int(f.h) - 1)
	var far := Vector2i(int(f.x), int(f.y))
	check(cut.has(near) and not cut.has(far), "wheat: the cells nearest the harvester are cut first")
	cv.refresh()
	var stubble := cv.plants().filter(func(e): return e[3] == CropView.STUBBLE and Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(Vector2i(e[0], e[1])))
	var ripe := cv.plants().filter(func(e): return e[3] == CropView.RIPE and Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(Vector2i(e[0], e[1])))
	check(stubble.size() == want and ripe.size() == n - want, "wheat: the view draws %d stubble and %d ripe cells" % [stubble.size(), ripe.size()])
	# kept through a save (the field's own record, as JSON)
	var again: Dictionary = JSON.parse_string(JSON.stringify(f))
	var w2: World = w
	var saved: Dictionary = f.duplicate(true)
	f.clear()
	f.merge(again)
	check(cv.cut_cells(f) == cut, "wheat: the cut cells are the same after a save and load")
	f.clear()
	f.merge(saved)
	# a field from a save made before GP-WHEAT-PICKED: no crop_full, no cut_from; a share still shows, from a corner
	f.erase("crop_full")
	f.erase("cut_from")
	check(cv.cut_cells(f).size() == floori((1.0 - float(f.crop) / float(w2.field_full_crop(f))) * n + 1e-6), "wheat: an older save's half-cut field shows its share")
	# cut to the end: tilled, all stubble (as before)
	while int(f.crop) > 0 and guard < 3000:
		w.player_harvest(f)
		guard += 1
	check(str(f.state) == "tilled" and not f.has("cut_from") and cv.field_column(f) == CropView.STUBBLE, "wheat: a field cut to the end is tilled and shows stubble")
	# the player's farm: a cut wheat cell shows stubble until sown again, through a save
	var c := Vector2i(int(f.x), int(f.y) - 3)
	w.farm.cells[c] = {"crop": "wheat", "state": "ripe", "progress": 1.0}
	var got := w.farm.harvest(c, w.player)
	check(not got.is_empty() and str(w.farm.cells[c].get("cut", "")) == "wheat", "wheat: the player's cut wheat cell remembers it was cut")
	check(cv.plants().has([c.x, c.y, CropView.ROWS.wheat, CropView.STUBBLE]), "wheat: the player's cut wheat cell shows stubble")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.farm.to_dict()))
	w.farm.load_dict(d)
	check(str(w.farm.cells[c].get("cut", "")) == "wheat", "wheat: the cut cell is kept through a save")
	d.cells = d.cells.map(func(e): return e.slice(0, 5))      # a save from before GP-WHEAT-PICKED
	w.farm.load_dict(d)
	check(not w.farm.cells[c].has("cut"), "wheat: an older save's farm loads (no cut mark)")
	w.farm.cells.erase(c)


## GP-BACK-DOORS (owner: "Doors shouldn't show on the back roofs of houses like that"): seen from outside, a door under a
## roof is not drawn over the roof; a front door's copy over the doorway is still taken out (VIS-DOOR-01).
func _back_doors() -> void:
	var view: MapView = main.view
	var dv: DoorView = main.door_view
	var back := 0
	var front := 0
	for d in dv.doors:
		var cell: Vector2i = d.cell
		var copy := false
		var roof := false
		for l in view.above_layers:
			var v := view.tile_value(l, cell)
			if v >= 0:
				if DoorView.DOOR_COPY.has(v % 100000):
					copy = true
				else:
					roof = true
		check(not copy, "doors: no copy of the door over %s's doorway %s" % [d.building, str(cell)])
		if roof:
			back += 1
		elif dv.stripped.has(cell):
			front += 1
	check(back >= 2, "doors: the back doors under a roof keep the roof over them (%d: the tavern's, the smithy's)" % back)
	check(front >= 25, "doors: the front doors' copies are taken out as before (%d)" % front)
	var tavern := Vector2i(38, 38)
	var roofed := false
	for l in view.above_layers:
		if view.tile_value(l, tavern) >= 0:
			roofed = true
	check(roofed, "doors: the tavern's back door (38, 38) stays under its roof")


## Sets the window to `sz` and the phone or desktop layout at interface size `ui_size`, as Main.apply_settings does.
func _screen(sz: Vector2i, phone: bool, ui_size: String) -> void:
	root.size = sz
	main.settings.phone = phone
	main.settings.ui_size = ui_size
	main.settings.apply(self)


## The controls of `node` that a player can press (buttons), visible.
func _pressables(node: Node, out: Array) -> Array:
	for c in node.get_children():
		if c is BaseButton and (c as Control).is_visible_in_tree():
			out.append(c)
		_pressables(c, out)
	return out


## Whether every visible button under `node` lies inside the visible screen (a pixel of slack); the misfits, named.
func _outside(node: Node) -> Array:
	var view := root.get_visible_rect().grow(1.0)
	var bad := []
	for b: Control in _pressables(node, []):
		var r := b.get_global_rect()
		var scrolled := false                    # in a window's scrolling body: below the screen is reached by scrolling
		var up := b.get_parent()
		while up != null and up != node:
			if up is ScrollContainer and (up as ScrollContainer).vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED \
					and view.encloses((up as Control).get_global_rect()):
				scrolled = true
			up = up.get_parent()
		if scrolled:
			r = Rect2(r.position.x, view.position.y + 2.0, r.size.x, 1.0)      # across only
		if r.size.x > 0.0 and not view.encloses(r):
			bad.append("%s %s" % [(b as Button).text if b is Button else b.name, str(r)])
	return bad


## GP-PACK-DETAIL-FIT (owner: "bottom options are off the screen", Ale x2 and others).
func _pack_fit() -> void:
	var w: World = main.world
	var p: PlayerState = w.player
	var ui = main.ui
	var sizes := [[Vector2i(2000, 1119), true], [Vector2i(2404, 1080), true], [Vector2i(2000, 1145), true],
		[Vector2i(1920, 1080), false], [Vector2i(1920, 1200), false], [Vector2i(1280, 800), false]]
	var ids: Array = GameData.items.keys()
	ids.sort()
	var longest := []                      # [text length, id], the ten longest descriptions
	var saved_ui: String = main.settings.ui_size
	for si in sizes.size():
		for ui_size in (["normal", "large", "small"] if si < 2 else ["normal"]):
			_screen(sizes[si][0], sizes[si][1], ui_size)
			ui.show_inventory()
			await process_frame
			await process_frame
			var pack: InventoryWindow = ui.inventory_window()
			var try: Array = ids if (si == 0 and ui_size == "normal") else longest.map(func(e): return e[1])
			var bad := []
			for id in try:
				var had := p.inv.count(id)
				p.inv.add(id, 2)
				pack.choose_tab(GameData.category(id))
				pack.choose(id)
				await process_frame
				await process_frame
				if si == 0 and ui_size == "normal":
					var n := 0
					for l in pack.detail_text.get_children():
						n += (l as Label).text.length()
					longest.append([n, id])
				var out := _outside(pack)
				if pack.actions.get_child_count() < 2:
					out.append("only %d actions" % pack.actions.get_child_count())
				if not out.is_empty():
					bad.append("%s: %s" % [id, str(out)])
				p.inv.remove(id, p.inv.count(id) - had)
			if si == 0 and ui_size == "normal":
				longest.sort()
				longest.reverse()
				longest = longest.slice(0, 10)
				check(not longest.is_empty(), "pack fit: the longest descriptions are %s" % str(longest.slice(0, 3)))
			check(bad.is_empty(), "pack fit at %s (%s, %s): every item's buttons are on screen (%d items) %s" % [str(sizes[si][0]), "phone" if sizes[si][1] else "desktop", ui_size, try.size(), str(bad.slice(0, 3))])
			ui.hide_all()
	# the talk window and the stall window (with its put-up dialog) at the same sizes: nothing cut off at the right
	var farmer: NPC = null
	for n: NPC in w.npcs:
		if n.job == "farmer" and farmer == null:
			farmer = n
	p.coins = 100
	w.business.rent()
	var stall: Dictionary = w.business.mine()
	p.inv.add("pottage", 58)
	w.business.list_item(stall, "pottage", 3)
	for si in sizes.size():
		for ui_size in (["normal", "large", "small"] if si < 2 else ["normal"]):
			_screen(sizes[si][0], sizes[si][1], ui_size)
			var where := "%s (%s, %s)" % [str(sizes[si][0]), "phone" if sizes[si][1] else "desktop", ui_size]
			ui.show_talk(farmer)
			await process_frame
			await process_frame
			var out := _outside(ui.panel)
			check(out.is_empty() and ui.close_btn.is_visible_in_tree(), "talk window fits at %s %s" % [where, str(out.slice(0, 3))])
			StallWindow.show(ui, str(stall.id), {"id": "pottage", "mode": "put"})
			await process_frame
			await process_frame
			out = _outside(ui.panel)
			check(out.is_empty(), "stall window and its put-up dialog fit at %s %s" % [where, str(out.slice(0, 3))])
			ui.hide_all()
	_screen(Vector2i(1280, 720), false, saved_ui)
