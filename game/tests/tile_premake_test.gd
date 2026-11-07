extends SceneTree
## B25R2 playtest (owner 2026-11-07: "freeze for a second every other step" south of the starter village): a tile made during play
## changes the TileSet, and every layer drawn with it (the whole village, each overworld chunk) is updated again, about 150 ms for
## one new tile; walking into new ground, a new kind of tile came every few steps. MapView._make_all_tiles makes the tiles the
## overworld draws before any layer is drawn. Checked on the real game scene, seed 1 (every new game's world): the overworld drawn
## round every settlement and landmark, and along the road south to the nearest settlement, makes no new tile; the water and the
## animated village tiles still move. Counts, not wall-clock time (a slow runner cannot fail it, a fast one cannot hide it).
##   godot --headless --path game -s res://tests/tile_premake_test.gd

var main
var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_tile_premake/save.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func tiles() -> Dictionary:
	var out := {}
	var ts: TileSet = main.view.tileset
	for i in ts.get_source_count():
		var sid := ts.get_source_id(i)
		var src := ts.get_source(sid) as TileSetAtlasSource
		for k in src.get_tiles_count():
			out[[sid, src.get_tile_id(k)]] = true
	return out


func _run() -> void:
	main.new_game()
	await process_frame
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var before := tiles()
	check(before.size() > 1000 and int(main.view.make_tiles_usec) > 0, "the tiles the overworld draws are made at the start (%d, in %.0f ms)" % [before.size(), main.view.make_tiles_usec / 1000.0])
	var places: Array = []
	for st in ow.sites + ow.structures:
		places.append(Vector2((st.rect as Rect2i).get_center()))
	var home := Vector2(ow.village.get_center())
	var south: Dictionary = {}
	for st in ow.sites:
		var d := Vector2(st.center) - home
		if d.y > 20 and absf(d.x) < d.y and (south.is_empty() or d.length() < (Vector2(south.center) - home).length()):
			south = st
	if not south.is_empty():
		var r := RegionTravel.plan(w, Vector2i(ow.gates[0].out), Vector2i(south.center))
		var cells: PackedVector2Array = r.get("cells", PackedVector2Array())
		for i in range(0, cells.size(), 24):
			places.append(cells[i])
	main.ow_view.radius = 1                         # the chunk under each place and its eight neighbours (the game draws 5 x 5)
	var t0 := Time.get_ticks_msec()
	for p: Vector2 in places:
		main.ow_view.follow(p, p, 0.0, -1)          # every chunk round the place drawn at once, as a teleport draws them
	print("     drawn in %.0f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	var after := tiles()
	var made := after.keys().filter(func(k): return not before.has(k))
	check(places.size() > 20, "the overworld drawn round %d places: every settlement and landmark and the road south to %s" % [places.size(), str(south.get("name", "?"))])
	check(made.is_empty(), "no tile is made while the overworld is drawn (%d made: %s)" % [made.size(), str(made.slice(0, 8))])
	var ts: TileSet = main.view.tileset
	var water := ts.get_source(MapView.WATER_ATLAS) as TileSetAtlasSource
	check(water.get_tiles_count() > 0 and water.get_tile_animation_frames_count(water.get_tile_id(0)) == MapView.WATER_FRAMES, "the water's tiles keep their %d frames" % MapView.WATER_FRAMES)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
