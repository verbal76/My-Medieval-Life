class_name LevelView
extends MapView
## Draws one underground level (LevelMap; MIN-A, docs/build17/MIN_A_ARCHITECTURE.md): a dark ground under and round
## its region, the floor, the rock walls beside the floor, the deeper rock (shaded), the seams with the same ore
## sprites as the surface's (resources.json "deposit_tiles"; World.deposits records with this level), and a darkness
## overlay round the player that is atmosphere only (clear round the player, never hiding them or the path). The
## tiles are the village's own atlases (the TileSet is the village MapView's): the gallery's walls are the rock of the
## hill top above them. Main shows it, faded in, while the player is on its level, and fades the surface out.
## MIN-F: a tunnel cell cut open is redrawn with its neighbours (redraw_around: floor, new walls); the level's track
## and timber supports are drawn by a WorksView over the floor; a cave's floor may be shaded (tiles.floor_shade).

const DARK_Z := 9                     # over the characters, under the surface's "above" layers (faded out below)
const DARK_TILES := 100.0             # the overlay's width in tiles (wider than any zoom shows)

var level_map: LevelMap
var floor_layer: TileMapLayer
var deep_layer: TileMapLayer
var wall_layer: TileMapLayer
var seam_layer: TileMapLayer
var works_view: WorksView
var way_out: Node2D
var dark: Sprite2D
var _floors: Array = []
var _walls: Array = []


func setup_level(src: MapView, w: World, lm: LevelMap, spec: Dictionary) -> void:
	level_map = lm
	tileset = src.tileset
	sources = src.sources
	columns = src.columns
	animated = src.animated
	var tiles: Dictionary = spec.tiles
	var g: Array = tiles.get("ground", [0.07, 0.06, 0.06])
	var ground := ColorRect.new()
	ground.color = Color(float(g[0]), float(g[1]), float(g[2]))
	ground.position = Vector2(lm.region.position - Vector2i(60, 60)) * T
	ground.size = Vector2(lm.region.size + Vector2i(120, 120)) * T
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	floor_layer = _layer()
	var fs := float(tiles.get("floor_shade", 1.0))
	floor_layer.modulate = Color(fs, fs, fs)
	deep_layer = _layer()
	var shade := float(tiles.get("deep_shade", 0.45))
	deep_layer.modulate = Color(shade, shade, shade)
	wall_layer = _layer()
	seam_layer = _layer()
	_floors = tiles.floor
	_walls = tiles.wall
	var seam_cells := _seam_cells(w)
	for c in lm.cells():
		_draw_cell(w, c, seam_cells)
	way_out = WayOutMark.new()
	way_out.setup(w, lm)                     # GP-MINE-WOOD-FRAME: the way up to the surface, lit, at the passage's end
	add_child(way_out)
	works_view = WorksView.new()
	works_view.setup(w.mine_works, lm.level)
	add_child(works_view)
	dark = Sprite2D.new()
	dark.texture = _dark_texture()
	dark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	dark.scale = Vector2.ONE * DARK_TILES * T / float(dark.texture.get_width())
	dark.z_index = DARK_Z
	add_child(dark)


func _seam_cells(w: World) -> Dictionary:
	var out := {}
	for d in w.deposits:
		if World.level_of(d) == level_map.level and level_map.in_level(Vector2i(int(d.x), int(d.y))):
			out[Vector2i(int(d.x), int(d.y))] = d
	return out


## One cell: floor (and under a seam), the seam's sprite, a wall beside the floor, or the deeper rock.
func _draw_cell(w: World, c: Vector2i, seam_cells: Dictionary) -> void:
	var lm := level_map
	var pick := Overworld.hash32(c.x, c.y, 77, lm.level)
	set_tile(floor_layer, c, int(_floors[pick % _floors.size()]) if not lm.is_solid(c) or seam_cells.has(c) else -1)
	set_tile(wall_layer, c, -1)
	set_tile(deep_layer, c, -1)
	if seam_cells.has(c):
		var d: Dictionary = seam_cells[c]
		var quarried: bool = int(d.amount) <= 0 and d.has("host") and int(d.host.amount) <= 0      # MIN-B: the rock is gone
		if not quarried:
			set_seam(c, int(w.map.data.tiles.ore[str(d.ore)]) if int(d.amount) > 0 else int(w.map.data.tiles.depleted_rock))
	elif lm.is_solid(c) and lm._touches_floor(c):
		set_tile(wall_layer, c, int(_walls[pick % _walls.size()]))
	elif lm.is_solid(c):
		set_tile(deep_layer, c, int(_walls[pick % _walls.size()]))


## MIN-F: a tunnel cell was cut open: it and the rock round it are drawn again (the new floor, the new walls).
func redraw_around(w: World, c: Vector2i) -> void:
	var seam_cells := _seam_cells(w)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if level_map.in_level(c + Vector2i(dx, dy)):
				_draw_cell(w, c + Vector2i(dx, dy), seam_cells)


func _layer() -> TileMapLayer:
	var l := TileMapLayer.new()
	l.tile_set = tileset
	add_child(l)
	return l


## A seam's sprite changed (worked out): World.level_tile_changed.
func set_seam(cell: Vector2i, value: int) -> void:
	set_tile(seam_layer, cell, value)


## Keep the darkness centred on the player (tiles).
func follow(player_pos: Vector2) -> void:
	dark.position = player_pos * T


## Clear within about 3 tiles of the player, darkening to 55 % by about 10 tiles (atmosphere only, MIN-A).
static func _dark_texture() -> GradientTexture2D:
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.06, 0.2, 1.0])
	gr.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.55)])
	var t := GradientTexture2D.new()
	t.gradient = gr
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
