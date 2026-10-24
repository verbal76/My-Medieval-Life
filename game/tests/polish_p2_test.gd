extends SceneTree
## GP-POLISH P2 (the owner's polish reports of 2026-10-24), checked in the real game scene, headless:
##   godot --headless --path game --script res://tests/polish_p2_test.gd
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
