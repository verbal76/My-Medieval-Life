extends SceneTree
## GP-POLISH P2 (the owner's polish reports of 2026-10-24), checked in the real game scene, headless:
##   godot --headless --path game --script res://tests/polish_p2_test.gd
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
