extends SceneTree
## B25R1-Q8 (owner: "Bow.Pixel Low Grass ... looks like this is our winner"): the low grass tufts, checked in the real game
## scene, headless:
##   godot --headless --path game --script res://tests/low_grass_test.gd
## Tufts are drawn on the village's and the overworld's open grass, from the two Bow.Pixel atlases, by a fixed hash (the same
## cells and tufts every time); never on a road, path, field, water, building, tree, plant or object; drawing only (no
## collision, nothing walkable changes); and a tuft goes when something is drawn over its cell later.

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
	main.save_path = "user://test_saves/low_grass_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _in_atlas(v: int) -> bool:
	return v / 100000 == int(MapView.LOW_GRASS[0]) / 100000 or v / 100000 == int(MapView.LOW_GRASS[1]) / 100000


func _run() -> void:
	main.set_process(false)
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var view: MapView = main.view
	var m: VillageMap = w.map
	var tufts := MapView.low_grass()
	check((tufts.plain as Array).size() > 50 and (tufts.flowered as Array).size() > 50, "the tuft lists load (%d plain, %d flowered)" % [tufts.plain.size(), tufts.flowered.size()])
	check(MapView.grass_tuft(7, Vector2i(3, 4)) == MapView.grass_tuft(7, Vector2i(3, 4)), "a cell's tuft is a pure function of the seed and the cell")
	# --- the village
	var road := {}
	for c in m.data.road:
		road[Vector2i(int(c[0]), int(c[1]))] = true
	var flat := {}
	for g in m.overworld.tiles.grass:
		flat[int(g)] = true
	var cells: Array = view.grass_layer.get_used_cells() if view.grass_layer != null else []
	var bad := 0
	var wrong_art := 0
	for c: Vector2i in cells:
		var v := view.grass_value(c)
		wrong_art += 0 if _in_atlas(v) else 1
		if road.has(c) or m.is_solid(c) or not flat.has(view.tile_value(view.layer("ground0"), c)) or not w.tree_at(c).is_empty() \
				or not w.plant_at(c).is_empty():
			bad += 1
			continue
		for lname in view.layers:
			if str(lname) != "ground0" and (view.layers[lname] as TileMapLayer).get_cell_source_id(c) >= 0:
				bad += 1
				break
	var share := cells.size() * 100.0 / float(m.w * m.h)
	check(cells.size() > 300, "the village has low grass tufts (%d cells, %.1f%% of the map)" % [cells.size(), share])
	check(wrong_art == 0, "every village tuft is from the Bow.Pixel atlases (%d not)" % wrong_art)
	check(bad == 0, "no village tuft on a road, path, building, field, tree, plant, object or solid cell (%d of %d)" % [bad, cells.size()])
	var again := []
	for c: Vector2i in cells:
		again.append(view.grass_value(c))
	view.lay_grass(int(m.data.get("seed", 0)), m.overworld.tiles.grass, main._grass_open())
	var same: bool = view.grass_layer.get_used_cells().size() == cells.size()
	for k in cells.size():
		same = same and view.grass_value(cells[k]) == again[k]
	check(same, "laying the village's grass again gives the same cells and tufts")
	check(view.tileset.get_physics_layers_count() == 0, "the tufts have no collision (the tile set has no physics layer)")
	if not cells.is_empty():
		var c: Vector2i = cells[0]
		var solid_before := m.is_solid(c)
		view.set_tile(view.layer("below0"), c, MapView.SMALL_BOULDER_TILE)
		check(view.grass_value(c) == -1 and m.is_solid(c) == solid_before, "a tile drawn over a tuft's cell takes the tuft away, and nothing else changes")
	# --- the overworld, round a point well outside the village
	var ow: Overworld = m.overworld
	var ov: OverworldView = main.ow_view
	var at := Vector2(ow.village.end.x + 70, ow.village.get_center().y)
	ov.follow(at, at, 0.0, -1)
	var n := 0
	var obad := 0
	var lanes := RegionRoads.lane_cells(ow)
	for cc: Vector2i in ov.chunks:
		var layer: TileMapLayer = ov.chunks[cc].grass
		for c: Vector2i in layer.get_used_cells():
			n += 1
			var v := ov.grass_value(c)
			if not _in_atlas(v) or ow.is_road(c) or lanes.has(c) or ow.is_solid(c) or ow.is_water(c) or ow.site_building_at(c) \
					or ov.tile_value(ov.chunks[cc].objects, c) >= 0 or ov.tile_value(ov.chunks[cc].path, c) >= 0 or ow.village.has_point(c):
				obad += 1
	check(n > 500, "the overworld's loaded chunks have low grass tufts (%d in %d chunks)" % [n, ov.chunks.size()])
	check(obad == 0, "no overworld tuft on a road, street, water, rock, flower, bush, tree, building or the village (%d of %d)" % [obad, n])
	var first := Vector2i(-999999, 0)
	for cc: Vector2i in ov.chunks:
		var used: Array = (ov.chunks[cc].grass as TileMapLayer).get_used_cells()
		if not used.is_empty():
			first = used[0]
			break
	if first.x != -999999:
		ov.set_tile(ov.chunks[Overworld.chunk_of(first)].objects, first, int(ow.tiles.rock))
		check(ov.grass_value(first) == -1, "an object drawn on an overworld tuft's cell takes the tuft away")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
