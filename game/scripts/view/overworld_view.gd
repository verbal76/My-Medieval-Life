class_name OverworldView
extends MapView
## Draws the overworld (Overworld) as a ring of chunks round the camera. Each loaded chunk is a node
## with four TileMapLayers: ground, road, objects (tree trunks, rocks, flowers, bushes) and tree tops
## (drawn over the characters, faded by a CanopyFade while the player stands behind one). Chunks
## are built a few per frame as the camera moves, and freed once they are more than one chunk
## beyond the ring, so what is held is bounded whatever distance is walked. The village's own
## MapView draws the village; the cells inside it are not drawn here. The tiles, the atlases and
## the TileSet are the village MapView's (the art is the same packs).

const BUILD_PER_FRAME := 3

var overworld: Overworld
var radius := 2                       # chunks beyond the camera's chunk that are kept drawn
var chunks := {}                      # chunk coordinates -> {root, ground, path, objects, tops}
var canopy: CanopyFade
var tree_sink: TreeView               # draws the chunks' trees as sprites (set by Main); the tiles here are ground, roads and decoration
var tops_set := {}                    # canopy top tile -> true
var _center := Vector2i(1 << 30, 1 << 30)
var _pending: Array[Vector2i] = []


func setup(src: MapView, o: Overworld, load_radius: int) -> void:
	overworld = o
	radius = load_radius
	tileset = src.tileset
	sources = src.sources
	columns = src.columns
	animated = src.animated
	var pairs := []
	for k in o.tiles.trees:
		pairs.append([int(k.top), int(k.bottom)])
		tops_set[int(k.top)] = true
	canopy = CanopyFade.new()
	add_child(canopy)
	canopy.setup(self, pairs)


## Keep the chunks round `center` (tiles) drawn, building at most `budget` this call (a negative
## budget builds them all: a first view, a teleport), and fade canopies over `feet`.
func follow(center: Vector2, feet: Vector2, delta: float, budget := BUILD_PER_FRAME) -> void:
	var cc := Overworld.chunk_of(Vector2i(floori(center.x), floori(center.y)))
	if cc != _center:
		_center = cc
		_pending.clear()
		var want: Array = []
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var c := cc + Vector2i(dx, dy)
				if not chunks.has(c) and not overworld.chunk_in_village(c):
					want.append([dx * dx + dy * dy, c.y, c.x, c])
		want.sort()
		for w in want:
			_pending.append(w[3])
		for c: Vector2i in chunks.keys():
			if maxi(absi(c.x - cc.x), absi(c.y - cc.y)) > radius + 1:
				_free(c)
	var n := 0
	while not _pending.is_empty() and (budget < 0 or n < budget):
		var c: Vector2i = _pending.pop_front()
		if not chunks.has(c):
			_build(c)
			n += 1
	if budget < 0 and tree_sink != null:
		tree_sink.flush()
	canopy.update(feet, delta)


func _layer(root: Node2D, z: int) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.tile_set = tileset
	l.z_index = z
	l.rendering_quadrant_size = 32
	root.add_child(l)
	return l


func _build(cc: Vector2i) -> void:
	var ch := overworld.get_chunk(cc)
	var root := Node2D.new()
	root.name = "chunk_%d_%d" % [cc.x, cc.y]
	add_child(root)
	var ground := _layer(root, 0)
	var path := _layer(root, 0)
	var objects := _layer(root, 0)
	var tops := _layer(root, 10)
	var x0 := cc.x * Overworld.CHUNK
	var y0 := cc.y * Overworld.CHUNK
	for y in Overworld.CHUNK:
		for x in Overworld.CHUNK:
			var i := y * Overworld.CHUNK + x
			var cell := Vector2i(x0 + x, y0 + y)
			if ch.ground[i] >= 0:
				set_tile(ground, cell, ch.ground[i])
			if ch.path[i] >= 0:
				set_tile(path, cell, ch.path[i])
			if ch.deco[i] >= 0 and not overworld.rock_gone(cell) and not overworld.flower_gone(cell):    # a broken boulder or a picked flower stays gone
				var v: int = ch.deco[i]
				if v == int(overworld.tiles.rock) and ResourceNodes.boulder_small(cell) and sources.size() > 3:
					v = MapView.SMALL_BOULDER_TILE
				set_tile(objects, cell, v)
	if tree_sink != null:
		tree_sink.load_chunk(cc, overworld.chunk_trees(cc))
	chunks[cc] = {"root": root, "ground": ground, "path": path, "objects": objects, "tops": tops}
	above_layers.append(tops)


func _free(cc: Vector2i) -> void:
	canopy.restore_all()                  # faded tiles go back to their layers before the layer goes
	if tree_sink != null:
		tree_sink.unload_chunk(cc)
	var c: Dictionary = chunks[cc]
	above_layers.erase(c.tops)
	c.root.queue_free()
	chunks.erase(cc)


## A tile of the objects ("below") or tree-top ("above") layer changed at a cell (a felled tree
## stump, a sapling, a regrown tree): the same call World.tile_changed makes for the village.
func apply_change(cell: Vector2i, kind: String, value: int) -> void:
	if kind == "below":
		var c: Dictionary = chunks.get(Overworld.chunk_of(cell), {})
		if not c.is_empty():
			set_tile(c.objects, cell, value)
		return
	if kind != "above":
		return
	canopy.restore_all()
	# a tree's top and bottom tiles both sit in the layer of the chunk that holds its trunk, which
	# for a top tile (the cell above the trunk) may be the chunk below
	var below := Overworld.chunk_of(cell + Vector2i.DOWN)
	var own := Overworld.chunk_of(cell)
	var target := below if tops_set.has(value) else own
	for cc in [own, below]:
		var c: Dictionary = chunks.get(cc, {})
		if not c.is_empty() and (cc == target or value < 0):
			set_tile(c.tops, cell, value)


func loaded_count() -> int:
	return chunks.size()


## The tile value drawn on a cell's ground layer, or -1 (tests).
func ground_value(cell: Vector2i) -> int:
	var c: Dictionary = chunks.get(Overworld.chunk_of(cell), {})
	return -1 if c.is_empty() else tile_value(c.ground, cell)
