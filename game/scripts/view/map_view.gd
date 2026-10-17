class_name MapView
extends Node2D
## Draws the village tile layers. Ground, path and "below" layers sit under the characters;
## "above" layers (roofs, tree tops) are drawn over them.

const T := 16

var tileset := TileSet.new()
var sources: Array[TileSetAtlasSource] = []
var columns: Array[int] = []
var layers := {}                 # layer name -> TileMapLayer
var animated := {}               # first tile id -> frame count
var map: VillageMap


func build(m: VillageMap, above_parent: Node2D) -> void:
	map = m
	tileset.tile_size = Vector2i(T, T)
	for a in m.data.atlases:
		var src := TileSetAtlasSource.new()
		src.texture = load(a.image)
		src.texture_region_size = Vector2i(T, T)
		sources.append(src)
		columns.append(int(a.columns))
		tileset.add_source(src)
	for k in m.data.animated:
		animated[int(k)] = m.data.animated[k].size()
	for lay in m.data.layers:
		var layer := TileMapLayer.new()
		layer.name = lay.name
		layer.tile_set = tileset
		if lay.z == "above":
			layer.z_index = 10
			above_parent.add_child(layer)
		else:
			add_child(layer)
		layers[lay.name] = layer
		var d: Array = lay.data
		for i in d.size():
			var v := int(d[i])
			if v >= 0:
				set_tile(layer, Vector2i(i % m.w, i / m.w), v)


func set_tile(layer: TileMapLayer, cell: Vector2i, v: int) -> void:
	if v < 0:
		layer.erase_cell(cell)
		return
	var atlas := v / 100000
	var t := v % 100000
	var coords := Vector2i(t % columns[atlas], t / columns[atlas])
	var src := sources[atlas]
	if not src.has_tile(coords):
		src.create_tile(coords)
		if animated.has(t):
			src.set_tile_animation_columns(coords, animated[t])
			src.set_tile_animation_frames_count(coords, animated[t])
			for f in animated[t]:
				src.set_tile_animation_frame_duration(coords, f, 0.12)
	layer.set_cell(cell, atlas, coords)


func layer(name: String) -> TileMapLayer:
	return layers.get(name)
