class_name MapView
extends Node2D
## Draws the village tile layers. Ground, path and "below" layers sit under the characters;
## "above" layers (roofs, tree tops) are drawn over them.

const T := 16
const SMALL_BOULDER_TILE := 300000     # PL1-06: the extra "runtime" atlas (index 3, tile 0): the plain boulder drawn smaller, for small boulders
const ROAD_TILES := 400000             # B25R1-Q1: atlas 4, game/assets/tiles/road_tiles.png (tools/road_tiles.py): + row * 16 + connection index
const LARCHROW := 500000               # B25R1-Q8: atlas 5, Larchrow's Village & Cave sheet (tools/village_tile_sheets.py): + its tile_id (docs/assets/LARCHROW_TILES.md)
const LOW_GRASS := [600000, 700000]    # B25R1-Q8: atlases 6 and 7, Bow.Pixel's low grass sheets 1 and 2: + row * 20 + column
## The atlases added after village.json's own three and the runtime boulder, in atlas order from 4: [image, columns].
const EXTRA_ATLASES := [["res://assets/tiles/road_tiles.png", 16], ["res://assets/tiles/larchrow_village_cave.png", 16],
		["res://assets/tiles/low_grass_1.png", 20], ["res://assets/tiles/low_grass_2.png", 20],
		["res://assets/tiles/region_props.png", 8],   # atlas 8, B25R1-018: the region's prop sheet (tools/region_props.py)
		["res://assets/tiles/water_tiles.png", 8], ["res://assets/tiles/water_tiles.png", 8],   # atlases 9-10, B25R1-Q3: water (WATER_ATLAS animated, WATER_STILL_ATLAS still)
		["res://assets/tiles/fl_houses.png", 16]]   # atlas 11, B25R1-022: Fantasy Lands houses (tools/fl_houses.py; game/data/style_stamps.json)
const ROAD_STONE_ROWS := 4             # rows 0-3 stone road (paving variants), rows 4-5 dirt trail
const ROAD_TRAIL_ROW := 4
const ROAD_OVERGROWN_ROW := 6          # B25R1-011: rows 6-7 grown-over dirt road and trail, rows 8-9 damaged and broken stone
const ROAD_DAMAGED_ROW := 8
## B25R1-Q3: game/assets/tiles/water_tiles.png (tools/water_tiles.py), WATER_FRAMES animation frames a row: the last two
## EXTRA_ATLASES, 9 (animated, set up in _tile) and 10 (the same sheet, still).
const WATER_ATLAS := 9
const WATER_FRAMES := 8                # tools/water_tiles.py FRAMES; each frame water.json "frame_seconds" long
const WATER_STILL_ATLAS := 10          # B25R1-019: the same water sheet with no animation (its first frame): water out of the live range
## B25R1-Q8 (owner: "Bow.Pixel Low Grass ... looks like this is our winner"): low grass tufts scattered on open grass, drawing
## only (no collision, no data). A cell gets a tuft by a fixed hash of the world's seed and the cell: GRASS_PLAIN per cent a
## plain tuft, GRASS_FLOWERED per cent one with small flowers (game/data/low_grass.json, tools/low_grass_tufts.py: the first
## sheet only, one texture, so the tiles batch). One
## TileMapLayer for the village (lay_grass) and one a chunk in the overworld (OverworldView), so it is batched by the tile
## renderer's quadrants and culled with them; never on a road, path, field, water, building, tree, plant or object.
const GRASS_PLAIN := 18
const GRASS_FLOWERED := 5
const GRASS_SALT := 93
static var _tufts := {}
var grass_layer: TileMapLayer      # the village's tufts (lay_grass), null before
var grass_usec := 0                # how long laying them took (the perf harness reads it)

var tileset := TileSet.new()
var sources: Array[TileSetAtlasSource] = []
var columns: Array[int] = []
var layers := {}                 # layer name -> TileMapLayer
var above_layers: Array[TileMapLayer] = []   # the layers drawn over the characters, in draw order
var animated := {}               # first tile id -> frame count
var map: VillageMap
var sorted_of := {}              # an "above" layer -> its twin that is drawn among the characters (B8-025), see set_tile
var _sorted_parent: Node2D       # the y-sorted node the twins live in (the characters' own), null: no twins
var _canopy := {}                # tile ids that are tree canopies: never sorted (CanopyFade fades them)
const SORT_ORIGIN := 8           # a tile sorts by its cell's bottom edge (the tile's centre plus half a tile)
var roof_layers: Array[TileMapLayer] = []   # the "above" layers that are roofs (village.json roof_layers), in draw order


## `sorted_parent`: the characters' y-sorted node. With it, the overlay tiles of solid cells in the
## non-roof "above" layers (the upper half of an anvil, a bench, a rack, a wall top) are drawn among the
## characters by their cell's bottom edge, so someone standing south of the object is in front of it
## and someone north of it behind it, never clipped by its upper half (Build 8 report B8-025). Roofs,
## canopies and the overlays of cells one can walk through (a lintel, an awning) stay over everyone,
## except a building's front edge (GP-DRAW-UNDER-HOUSE): a solid roof-layer cell with no roof-layer tile
## south of it (the bottom row of the front wall) is drawn among the characters too, so someone standing
## on the grass in front of a house is drawn over its wall, not half under it (see _refront).
func build(m: VillageMap, above_parent: Node2D, sorted_parent: Node2D = null) -> void:
	map = m
	_sorted_parent = sorted_parent
	for pr in m.data.tiles.get("canopy", []):
		_canopy[int(pr[0])] = true
		_canopy[int(pr[1])] = true
	var roofs: Array = m.data.get("roof_layers", [])
	tileset.tile_size = Vector2i(T, T)
	for a in m.data.atlases:
		var src := TileSetAtlasSource.new()
		src.texture = load(a.image)
		src.texture_region_size = Vector2i(T, T)
		sources.append(src)
		columns.append(int(a.columns))
		tileset.add_source(src)
	_add_small_boulder(m)
	_add_road_tiles()
	for k in m.data.animated:
		animated[int(k)] = m.data.animated[k].size()
	for lay in m.data.layers:
		var layer := TileMapLayer.new()
		layer.name = lay.name
		layer.tile_set = tileset
		if lay.z == "above":
			layer.z_index = 10
			above_parent.add_child(layer)
			above_layers.append(layer)
			if roofs.has(lay.name):
				roof_layers.append(layer)
			if sorted_parent != null:
				var twin := TileMapLayer.new()
				twin.name = str(lay.name) + "_sorted"
				twin.tile_set = tileset
				twin.y_sort_enabled = true
				sorted_parent.add_child(twin)
				sorted_of[layer] = twin
		else:
			add_child(layer)
		layers[lay.name] = layer
		var d: Array = lay.data
		for i in d.size():
			var v := int(d[i])
			if v >= 0:
				set_tile(layer, Vector2i(i % m.w, i / m.w), v)
	if not sorted_of.is_empty():                 # once every roof layer is in (a later layer can roof a cell's south)
		for layer in roof_layers:
			var twin: TileMapLayer = sorted_of[layer]
			for cell in layer.get_used_cells() + twin.get_used_cells():
				_refront(cell)


## B25R1-Q1, B25R1-Q8: the atlases from the fifth on (EXTRA_ATLASES): the stone road and trail tiles (ROAD_TILES), drawn by
## OverworldView on those road cells; Larchrow's village and cave sheet (LARCHROW); Bow.Pixel's low grass (LOW_GRASS).
func _add_road_tiles() -> void:
	if sources.size() != 4:
		return
	for e in EXTRA_ATLASES:
		var src := TileSetAtlasSource.new()
		src.texture = load(str(e[0]))
		src.texture_region_size = Vector2i(T, T)
		sources.append(src)
		columns.append(int(e[1]))
		tileset.add_source(src)


## The fourth atlas: one tile, the paid atlas's plain boulder scaled down (nearest) and stood on the
## bottom of its cell, so a small boulder reads smaller than a large one (the full sprite).
func _add_small_boulder(m: VillageMap) -> void:
	if sources.size() != 3:
		return
	GameData.ensure()
	var id := int(GameData.resources.deposit_tiles.boulder)
	var atlas: Image = sources[0].texture.get_image()
	var cols := int(m.data.atlases[0].columns)
	var tile := atlas.get_region(Rect2i((id % cols) * T, (id / cols) * T, T, T))
	tile.convert(Image.FORMAT_RGBA8)
	tile.resize(10, 10, Image.INTERPOLATE_NEAREST)
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	img.blit_rect(tile, Rect2i(0, 0, 10, 10), Vector2i(3, T - 10))
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(T, T)
	sources.append(src)
	columns.append(1)
	tileset.add_source(src)


func set_tile(layer: TileMapLayer, cell: Vector2i, v: int) -> void:
	if v >= 0:
		_grass_off(cell)                  # B25R1-Q8: anything drawn on a cell (a building, a road, a stump) takes its tuft away
	var twin: TileMapLayer = sorted_of.get(layer)
	if twin != null and roof_layers.has(layer):
		twin.erase_cell(cell)
		_put(layer, cell, v)
		_refront(cell)                    # this cell, and the one above (its south neighbour changed)
		_refront(cell + Vector2i.UP)
		return
	if twin != null:
		if v < 0:
			twin.erase_cell(cell)
		elif map != null and map.is_solid(cell) and not _canopy.has(v % 100000):
			layer.erase_cell(cell)
			layer = twin                     # drawn among the characters, by its cell's bottom edge
		else:
			twin.erase_cell(cell)
	_put(layer, cell, v)


func _put(layer: TileMapLayer, cell: Vector2i, v: int) -> void:
	if v < 0:
		layer.erase_cell(cell)
		return
	var atlas := v / 100000
	var t := v % 100000
	var coords := Vector2i(t % columns[atlas], t / columns[atlas])
	var src := sources[atlas]
	if not src.has_tile(coords):
		src.create_tile(coords)
		src.get_tile_data(coords, 0).y_sort_origin = SORT_ORIGIN
		if atlas == WATER_ATLAS:                    # B25R1-Q3: the water's own frames, left to right
			src.set_tile_animation_frames_count(coords, WATER_FRAMES)
			var secs := float(Overworld.water_cfg().get("frame_seconds", 0.15))
			for f in WATER_FRAMES:
				src.set_tile_animation_frame_duration(coords, f, secs)
		elif animated.has(t):
			src.set_tile_animation_columns(coords, animated[t])
			src.set_tile_animation_frames_count(coords, animated[t])
			for f in animated[t]:
				src.set_tile_animation_frame_duration(coords, f, 0.12)
	layer.set_cell(cell, atlas, coords)


## GP-DRAW-UNDER-HOUSE: a building's front edge is drawn among the characters. A cell is on it when it is solid,
## has a tile in a roof layer and the cell south of it has none (the wall's bottom row; a door is open ground, so
## it stays over everyone). Its roof-layer tiles then live in the layers' y-sorted twins, sorted by the cell's
## bottom edge: a character on the ground in front (feet below that edge) is drawn over the wall, one inside or
## behind is drawn under it. Every other roof tile stays over everyone (a villager indoors stays under the roof).
## Decided from the cells alone, whatever order the tiles are set in (a building built in play sets its stamp
## row by row), and cells keep their place in RoofFade's lifted copies (it lifts the twins' cells too).
func _refront(cell: Vector2i) -> void:
	if map == null or roof_layers.is_empty() or sorted_of.is_empty():
		return
	var front := map.is_solid(cell) and _roofed(cell) and not _roofed(cell + Vector2i.DOWN)
	for layer in roof_layers:
		var twin: TileMapLayer = sorted_of.get(layer)
		if twin == null:
			continue
		var from: TileMapLayer = layer if front else twin
		var to: TileMapLayer = twin if front else layer
		var id := from.get_cell_source_id(cell)
		if id < 0:
			continue
		to.set_cell(cell, id, from.get_cell_atlas_coords(cell), from.get_cell_alternative_tile(cell))
		from.erase_cell(cell)


## Whether any roof layer (or its sorted twin) has a tile at `cell`.
func _roofed(cell: Vector2i) -> bool:
	for layer in roof_layers:
		if layer.get_cell_source_id(cell) >= 0:
			return true
		var twin: TileMapLayer = sorted_of.get(layer)
		if twin != null and twin.get_cell_source_id(cell) >= 0:
			return true
	return false


## The tile value (atlas * 100000 + tile id, as in village.json) at a cell of a layer, or -1. A roof layer's
## front-edge cell (in its sorted twin) reads as the layer's own.
func tile_value(layer: TileMapLayer, cell: Vector2i) -> int:
	if layer.get_cell_source_id(cell) < 0 and roof_layers.has(layer) and sorted_of.has(layer):
		layer = sorted_of[layer]
	var atlas := layer.get_cell_source_id(cell)
	if atlas < 0:
		return -1
	var coords := layer.get_cell_atlas_coords(cell)
	return atlas * 100000 + coords.y * columns[atlas] + coords.x


func layer(name: String) -> TileMapLayer:
	return layers.get(name)


## B25R1-Q8: the tufts' tile values by kind ({plain, flowered}), read once.
static func low_grass() -> Dictionary:
	if _tufts.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/low_grass.json"))
		_tufts = d if d is Dictionary else {"plain": [], "flowered": []}
	return _tufts


## The tuft a cell of open grass shows (a tile value of atlas 6 or 7), -1 for none: a pure function of the seed and the cell.
static func grass_tuft(seed: int, cell: Vector2i) -> int:
	var h := Overworld.hash32(seed, cell.x, cell.y, GRASS_SALT)
	var roll := h % 100
	var t := low_grass()
	var list: Array = t.plain if roll < GRASS_PLAIN else t.flowered if roll < GRASS_PLAIN + GRASS_FLOWERED else []
	return -1 if list.is_empty() else int(list[(h >> 8) % list.size()])


## Whether this view can draw the tufts (its TileSet has the low grass atlases).
func has_grass_art() -> bool:
	return sources.size() > int(LOW_GRASS[1]) / 100000


## B25R1-Q8: scatter the tufts over the village's open grass: cells whose base ground is one of `grass` (the flat grass tile
## values), with nothing in any other layer, not solid, and `open` (the caller's own exclusions: roads, fields, trees, plants)
## true. Drawn in one layer just over the paths, under the pits, crops and everything else. Returns how many were laid.
func lay_grass(seed: int, grass: Array, open: Callable) -> int:
	if map == null or not has_grass_art():
		return 0
	var t0 := Time.get_ticks_usec()
	if grass_layer != null:
		grass_layer.queue_free()
	var flat := {}
	for g in grass:
		flat[int(g)] = true
	grass_layer = TileMapLayer.new()
	grass_layer.name = "grass"
	grass_layer.tile_set = tileset
	grass_layer.rendering_quadrant_size = 32
	add_child(grass_layer)
	var under: TileMapLayer = layers.get("path1", layers.get("ground0"))
	if under != null:
		move_child(grass_layer, under.get_index() + 1)
	var n := 0
	for y in map.h:
		for x in map.w:
			var cell := Vector2i(x, y)
			var tuft := grass_tuft(seed, cell)
			if tuft < 0 or map.is_solid(cell) or not _bare(cell, flat) or not open.call(cell):
				continue
			_put(grass_layer, cell, tuft)
			n += 1
	grass_usec = Time.get_ticks_usec() - t0
	return n


## The cell's base ground is plain grass and no other layer (nor a sorted twin) draws anything there.
func _bare(cell: Vector2i, flat: Dictionary) -> bool:
	for lname in layers:
		var l: TileMapLayer = layers[lname]
		if str(lname) == "ground0":
			if not flat.has(tile_value(l, cell)):
				return false
		elif l.get_cell_source_id(cell) >= 0:
			return false
		var twin: TileMapLayer = sorted_of.get(l)
		if twin != null and twin.get_cell_source_id(cell) >= 0:
			return false
	return true


## The tuft on a cell goes (something else is drawn there now). OverworldView looks in the cell's chunk.
func _grass_off(cell: Vector2i) -> void:
	if grass_layer != null:
		grass_layer.erase_cell(cell)


## The tuft drawn on a cell, -1 for none (tests).
func grass_value(cell: Vector2i) -> int:
	return -1 if grass_layer == null else tile_value(grass_layer, cell)
