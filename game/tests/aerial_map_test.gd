extends SceneTree
## B25R1-025 (owner 2026-11-05): the aerial Region and Village maps (AerialMap, RegionMapPanel, VillageMapPanel) are pictures
## of the player's own world, for two seeds: every explored chunk is drawn and nothing unexplored is; the pages hold each
## chunk where it belongs; a settlement's roofs and the village's buildings are drawn on their own tiles (the art the world
## shows there, pixel for pixel); the water is where the world's water is; a change in the world redraws that chunk alone; the
## close pictures are bounded; the maps open quickly once drawn; the player is marked where they stand; the Village map zooms,
## pans and still looks where it is tapped. Run:
##   godot --headless --path game --script res://tests/aerial_map_test.gd

const SHOT := preload("res://tests/aerial_map_shot.gd")

var failures := 0
var checks := 0
var main


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves/aerial_map"))
	main.save_path = "user://test_saves/aerial_map/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	for s in [1, 11]:
		await _seed(s)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _seed(s: int) -> void:
	SHOT.new_world(main, s)
	main.ui.hide_all()
	main.aerial_background = false
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var p: PlayerState = w.player
	SHOT.explore(main, ["wulstead"])
	var wul: Dictionary = ow.site("wulstead")
	p.pos = Vector2(wul.center) + Vector2(0.5, 3.5)
	Atlas.note_position(w, p)
	var a := AerialMap.of(main)
	check(a.world == w and a.ow == ow, "seed %d: the aerial maps are this world's (generation %d)" % [s, ow.gen])
	var t0 := Time.get_ticks_usec()
	a.refresh()
	while a.pump(1000000, true) > 0:
		pass
	var build_ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("seed %d: %d chunks drawn in %.0f ms (%.1f ms a chunk; generating chunks %.0f ms of it)" % [s, a.lo_drawn, build_ms, build_ms / maxf(1, a.lo_drawn), a.gen_usec / 1000.0])
	# discovery: every explored chunk drawn, nothing beyond
	var missing := 0
	for cc: Vector2i in p.explored:
		if a.lo_sig.get(cc, null) != a.sig(cc):
			missing += 1
	check(missing == 0 and not p.explored.is_empty(), "seed %d: every explored chunk is drawn (%d)" % [s, p.explored.size()])
	var leaked := 0
	var dark := 0
	for pg: Vector2i in a.pages:
		for cy in AerialMap.PAGE:
			for cx in AerialMap.PAGE:
				var cc := pg * AerialMap.PAGE + Vector2i(cx, cy)
				if a.shown(cc):
					continue
				dark += 1
				var img: Image = a.pages[pg].img
				var o := Vector2i(cx, cy) * Overworld.CHUNK * AerialMap.LO
				for q in [Vector2i(3, 3), Vector2i(31, 31), Vector2i(60, 7), Vector2i(9, 58)]:
					if img.get_pixelv(o + q).a > 0.0:
						leaked += 1
	check(leaked == 0 and dark > 0, "seed %d: the unexplored chunks in the pages stay clear (%d checked)" % [s, dark])
	# each chunk in its place in the pages
	var placed := 0
	var keys: Array = p.explored.keys()
	keys.sort()
	for cc: Vector2i in keys.slice(0, 6):
		var lo := a.compose(cc, AerialMap.LO)
		var pg := AerialMap.page_of(cc)
		var o := (cc - pg * AerialMap.PAGE) * Overworld.CHUNK * AerialMap.LO
		var same := true
		for q in [Vector2i(0, 0), Vector2i(17, 40), Vector2i(63, 63), Vector2i(40, 5)]:
			if not (a.pages[pg].img as Image).get_pixelv(o + q).is_equal_approx(lo.get_pixelv(q)):
				same = false
		placed += 1 if same else 0
	check(placed == 6, "seed %d: each chunk's picture sits where its tiles are in the pages (%d of 6)" % [s, placed])
	# the settlement's roofs on their own tiles: the close picture at a roof cell is that roof tile's own art
	var roofs := 0
	var roof_ok := 0
	var hi_cache := {}
	for sl in wul.slots:
		var stamp: Dictionary = ow.stamps.get(Overworld.slot_stamp(sl), ow.stamps.house)
		var r: Rect2i = sl.rect
		var swap: Dictionary = main.ow_view._look_swap(str(sl.get("look", "")))
		for lname in stamp.layers:
			if not str(lname).begins_with("above"):
				continue
			var j := int(stamp.h) / 3
			var i := int(stamp.w) / 2
			var v := int(stamp.layers[lname][j * int(stamp.w) + i])
			if not swap.is_empty():
				v = int(swap.get(str(v), v))
			var art := a.tile(v, AerialMap.HI) if v >= 0 else null
			if art == null or art.get_pixel(4, 4).a < 1.0:
				continue
			var cell := r.position + Vector2i(i, j)
			var cc := Overworld.chunk_of(cell)
			if not hi_cache.has(cc):
				hi_cache[cc] = a.compose(cc, AerialMap.HI)
			var px := (cell - cc * Overworld.CHUNK) * AerialMap.HI + Vector2i(4, 4)
			roofs += 1
			if (hi_cache[cc] as Image).get_pixelv(px).is_equal_approx(art.get_pixel(4, 4)):
				roof_ok += 1
			break
	check(roofs >= 10 and roof_ok >= roofs - 1, "seed %d: Wulstead's roofs are drawn on their own tiles (%d of %d)" % [s, roof_ok, roofs])
	# the water where the world's water is
	var wet := 0
	var blue := 0
	for cc: Vector2i in keys:
		var ch := ow.get_chunk(cc)
		var img: Image = null
		for q in ch.water.size():
			if ch.water[q] != 1:
				continue
			var cell := cc * Overworld.CHUNK + Vector2i(q % Overworld.CHUNK, q / Overworld.CHUNK)
			if not ow.tree_at(cell).is_empty() or not ow.tree_at(cell + Vector2i(0, 1)).is_empty() or not ow.tree_at(cell + Vector2i(0, 2)).is_empty():
				continue                                   # under a canopy, seen from above
			if img == null:
				img = a.compose(cc, AerialMap.LO)
			var c := img.get_pixelv((cell - cc * Overworld.CHUNK) * AerialMap.LO)
			wet += 1
			blue += 1 if c.b > c.r + 0.05 else 0
	check(wet == 0 or blue >= wet * 0.85, "seed %d: the explored streams and pools are drawn as water on their own tiles (%d of %d)" % [s, blue, wet])
	# the village's own buildings, as its view holds them
	var tav: Dictionary = w.buildings["b2"]
	var vcell := Vector2i(int(tav.x) + int(tav.w) / 2, int(tav.y) + 1)
	var top := -1
	for lay in w.map.data.layers:
		var l: TileMapLayer = main.view.layers.get(lay.name)
		var v: int = main.view.tile_value(l, vcell) if l != null else -1
		if v >= 0:
			var art := a.tile(v, AerialMap.HI)
			if art != null and art.get_pixel(4, 4).a >= 1.0:
				top = v
	var vimg := a.compose(Overworld.chunk_of(vcell), AerialMap.HI)
	var vart := a.tile(top, AerialMap.HI) if top >= 0 else null
	check(vart != null and vimg.get_pixelv((vcell - Overworld.chunk_of(vcell) * Overworld.CHUNK) * AerialMap.HI + Vector2i(4, 4)).is_equal_approx(vart.get_pixel(4, 4)),
			"seed %d: the tavern's roof is drawn on its own tile of the village" % s)
	# a change in the world redraws that chunk alone
	var spot := Vector2i.MAX
	for cc: Vector2i in keys:
		var ch := ow.get_chunk(cc)
		for q in range(200, ch.solid.size()):
			var cell := cc * Overworld.CHUNK + Vector2i(q % Overworld.CHUNK, q / Overworld.CHUNK)
			if ow.plant_refusal(cell) == "":
				spot = cell
				break
		if spot != Vector2i.MAX:
			break
	var before := a.compose(Overworld.chunk_of(spot), AerialMap.HI)
	a.hi_tex(Overworld.chunk_of(spot))
	a.pump_hi(1000000)
	ow.plant(spot, "oak_summer", ow.clock)
	a.refresh()
	var sc := Overworld.chunk_of(spot)
	check(a.queue.size() == 1 and a.queue[0] == sc and not a.hi.has(sc), "seed %d: a sapling planted redraws its chunk alone (queued %s)" % [s, str(a.queue)])
	a.pump(1000000, true)
	check(a.lo_sig[sc] == a.sig(sc) and a.compose(sc, AerialMap.HI).get_data() != before.get_data(), "seed %d: and the sapling is in its picture" % s)
	var nb := w.buildings.size()
	w.buildings["aerial_test"] = {"x": 60, "y": 60, "w": 5, "h": 4, "type": "house"}
	a.refresh()
	var vq := a.queue.size()
	w.buildings.erase("aerial_test")
	var vchunks := AerialMap._chunks_of(ow.village).size()
	check(vq > 0 and vq == vchunks and w.buildings.size() == nb, "seed %d: a building in the village redraws the village's chunks (%d)" % [s, vq])
	a.refresh()
	a.pump(1000000, true)
	# the close pictures are bounded
	var asked := 0
	for cc: Vector2i in keys + AerialMap._chunks_of(ow.village):
		a.hi_tex(cc)
		asked += 1
	a.pump_hi(100000000)
	check(asked > AerialMap.HI_KEEP and a.hi.size() <= AerialMap.HI_KEEP, "seed %d: at most %d close pictures are kept (%d of %d asked)" % [s, AerialMap.HI_KEEP, a.hi.size(), asked])
	# the maps open quickly once drawn; the player marked where they stand
	t0 = Time.get_ticks_usec()
	main.ui.show_map("region")
	var open_ms := (Time.get_ticks_usec() - t0) / 1000.0
	await _frames(3)
	var r: RegionMapPanel = main.ui.panel_body.find_children("*", "RegionMapPanel", true, false)[0]
	check(open_ms < 150.0, "seed %d: the Region map opens in %.1f ms once drawn (target under 100 on a desktop)" % [s, open_ms])
	check(r.aerial == a and a.queue.is_empty(), "seed %d: the Region map draws this world's aerial pages" % s)
	check(Rect2(Vector2.ZERO, r.map_size()).has_point(r.to_screen(p.pos)), "seed %d: the player is on the Region map where they stand" % s)
	main.ui.hide_all()
	main.ui.map_place = "wulstead"
	t0 = Time.get_ticks_usec()
	main.ui.show_map("village")
	open_ms = (Time.get_ticks_usec() - t0) / 1000.0
	await _frames(3)
	var v: VillageMapPanel = main.ui.panel_body.find_children("*", "VillageMapPanel", true, false)[0]
	check(open_ms < 150.0 and v.target == "wulstead", "seed %d: Wulstead's map opens in %.1f ms" % [s, open_ms])
	check(VillageMapPanel.known_sites(w).any(func(e): return e[0] == "wulstead") and not VillageMapPanel.known_sites(w).any(func(e): return e[0] == "bourton"),
			"seed %d: the settlements walked to can be mapped, those never seen cannot" % s)
	var names: Array = v.places_here().map(func(e): return str(e[0]))
	check(names.has("Wulstead") and names.has("Church"), "seed %d: Wulstead's map names the place and its church (%s)" % [s, ", ".join(names.slice(0, 8))])
	check(v.map_rect().has_point(v.player_point()) and v.player_point().distance_to(v.to_screen(p.pos)) < 0.5, "seed %d: the player is marked in Wulstead" % s)
	var z := v.zoom
	v.zoom_at(v.map_size() / 2.0, 2.0)
	check(v.zoom > z * 1.9, "seed %d: the Village map zooms" % s)
	var c0 := v.centre
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = v.map_size() / 2.0
	v._gui_input(press)
	var drag := InputEventScreenDrag.new()
	drag.position = press.position + Vector2(60, 0)
	drag.relative = Vector2(60, 0)
	v._gui_input(drag)
	var lift := InputEventScreenTouch.new()
	lift.position = drag.position
	v._gui_input(lift)
	check(v.centre.x < c0.x and main.ui.is_open("map"), "seed %d: a drag pans and does not close the map" % s)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_WHEEL_DOWN
	mb.pressed = true
	mb.position = v.map_size() / 2.0
	z = v.zoom
	v._gui_input(mb)
	check(v.zoom < z, "seed %d: the wheel zooms out" % s)
	await _frames(2)
	press.position = v.map_size() / 2.0
	lift.position = press.position
	v._gui_input(press)
	v._gui_input(lift)
	check(not main.ui.modal() and main.cam_free, "seed %d: a tap still looks there" % s)
	main.recenter()
	main.ui.map_place = ""
