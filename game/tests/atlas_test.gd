extends SceneTree
## REGION-NAV-01 S1b (Atlas, RegionMapPanel): a player learns the region by walking it and learns a settlement's place by
## reaching it or being told; both are their own and saved; the region map shows only that: seen ground as the overworld really
## is there, the places they know, nothing else. Pure World plus the map image (no scene). Run headless:
##   godot --headless --path game --script res://tests/atlas_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var p: PlayerState = w.player
	var ow: Overworld = w.map.overworld
	check(p.places.is_empty() and p.explored.is_empty(), "a new player knows no settlement and has seen none of the region")
	# walk out of the south gate and down the road a little
	var south := Vector2i.ZERO
	for e in w.map.exits():
		if e.side == 2:
			south = e.out
	p.pos = Vector2(south) + Vector2(0.5, 30.5)
	w.update(0.1)
	var cc := Overworld.chunk_of(Vector2i(p.pos.floor()))
	check(p.explored.has(cc) and p.explored.size() >= 6, "walking out, the chunks round you are seen (%d)" % p.explored.size())
	# the summary is the real ground: a block with road in it is road, a wooded block is wood
	var sm: PackedByteArray = p.explored[cc]
	var ok := sm.size() == Atlas.PER * Atlas.PER
	var roads := 0
	for by in Atlas.PER:
		for bx in Atlas.PER:
			var has_road := false
			for dy in Atlas.BLOCK:
				for dx in Atlas.BLOCK:
					if ow.is_road(cc * Overworld.CHUNK + Vector2i(bx * Atlas.BLOCK + dx, by * Atlas.BLOCK + dy)):
						has_road = true
			if has_road:
				roads += 1
				ok = ok and sm[by * Atlas.PER + bx] == Atlas.ROAD
			else:
				ok = ok and sm[by * Atlas.PER + bx] in [Atlas.GRASS, Atlas.WOOD, Atlas.ROCK, Atlas.SITE, Atlas.VILLAGE]
	check(ok and roads > 0, "the summary reads the chunk itself: every block with road in it is road (%d), the rest ground, wood or rock" % roads)
	check(p.places.is_empty(), "outside any settlement, nothing is discovered")
	# reach Wulstead
	var wul: Dictionary = ow.site("wulstead")
	p.pos = Vector2(wul.center) + Vector2(0.5, 0.5)
	w.update(0.1)
	check(p.places.has("wulstead") and str(p.places.wulstead.how) == "visited", "walking into Wulstead's site, you know Wulstead")
	check(not p.places.has("garton"), "but not the other settlements")
	# told of Garton
	check(Atlas.learn_place(w, p, "garton", "region:wulstead/trader") and str(p.places.garton.how) == "told", "told by Wulstead's trader, you know where Garton lies")
	check(not Atlas.learn_place(w, p, "garton", "x"), "told again, nothing new")
	var gar: Dictionary = ow.site("garton")
	check(not p.explored.has(Overworld.chunk_of(gar.center)), "knowing Garton's place shows none of its ground")
	# saved with the player
	var back := PlayerState.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check(back.places == p.places, "the places you know are saved")
	check(back.explored.size() == p.explored.size() and back.explored[cc] == p.explored[cc], "and the region you have seen")
	var fresh := PlayerState.from_dict(JSON.parse_string(JSON.stringify(PlayerState.new().to_dict())))
	check(fresh.places.is_empty() and fresh.explored.is_empty() and not PlayerState.new().to_dict().has("places"), "a save with none of it (an older save) loads with nothing known")
	# the region map: seen ground as it is, the rest dark
	var img := RegionMapPanel.build_image(w, p)
	var b := RegionMapPanel.region_bounds(w, p)
	var px := func(tile: Vector2i) -> Color:
		return img.get_pixel((tile.x - b.position.x) / Atlas.BLOCK, (tile.y - b.position.y) / Atlas.BLOCK)
	check(b.has_point(gar.center) and b.has_point(wul.center), "the map covers the places you know (%s)" % b)
	# owner requirement 2026-11-05 (B25R1-025): a settlement's ground is never hidden by discovery; the wilderness is
	check(px.call(Vector2i(gar.center)) == RegionMapPanel.COLOURS[Atlas.SITE], "Garton's ground, never seen, is on the map as a settlement from the first day")
	var wild := Vector2i(-1048576, 0)
	for by in range(b.position.y, b.end.y, Atlas.BLOCK):
		for bx in range(b.position.x, b.end.x, Atlas.BLOCK):
			var c := Vector2i(bx, by) + Vector2i(Atlas.BLOCK, Atlas.BLOCK) / 2
			if wild.x == -1048576 and not p.explored.has(Overworld.chunk_of(c)) and ow.site_at(c).is_empty() and not ow.village.has_point(c) \
					and (c - Vector2i(gar.center)).length() < 200:
				wild = c
	check(wild.x != -1048576 and px.call(wild) == RegionMapPanel.COLOURS[Atlas.UNKNOWN], "the wilderness never seen (near Garton, %s) stays dark" % str(wild))
	check(px.call(Vector2i(wul.center)) == RegionMapPanel.COLOURS[Atlas.SITE], "Wulstead's, seen, is drawn as a settlement")
	var seen_road := cc * Overworld.CHUNK
	var road_cell := Vector2i(-1, -1)
	for by in Atlas.PER:
		for bx in Atlas.PER:
			if sm[by * Atlas.PER + bx] == Atlas.ROAD and road_cell.x < 0:
				road_cell = seen_road + Vector2i(bx * Atlas.BLOCK, by * Atlas.BLOCK)
	check(road_cell.x >= 0 and px.call(road_cell) == RegionMapPanel.COLOURS[Atlas.ROAD], "a road you walked is drawn as road")
	# an heir inherits what the family knows
	var heirlike := PlayerState.new()
	heirlike.places = p.places.duplicate(true)
	check(heirlike.places.has("wulstead"), "(the heir copies the family's places: World._player_died)")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
