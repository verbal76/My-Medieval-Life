class_name VillageMap
extends RefCounted
## The village layout from data/village.json (built by tools/build_village.py): size, tile layers,
## collision and the static entities. Also owns path-finding. No rendering here, so the
## simulation runs headless.

var w: int
var h: int
var data: Dictionary
var solid: PackedByteArray        # 1 = blocked; buildings and the world change it at runtime
var astar := AStarGrid2D.new()


static func load_default() -> VillageMap:
	var m := VillageMap.new()
	var text := FileAccess.get_file_as_string("res://data/village.json")
	m.data = JSON.parse_string(text)
	m.w = int(m.data.w)
	m.h = int(m.data.h)
	m.solid.resize(m.w * m.h)
	for y in m.h:
		var row: String = m.data.solid[y]
		for x in m.w:
			m.solid[y * m.w + x] = 1 if row[x] == "1" else 0
	m._setup_astar()
	return m


func _setup_astar() -> void:
	astar.region = Rect2i(0, 0, w, h)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for y in h:
		for x in w:
			if solid[y * w + x]:
				astar.set_point_solid(Vector2i(x, y), true)
	# roads are quicker to walk
	for c in data.road:
		astar.set_point_weight_scale(Vector2i(int(c[0]), int(c[1])), 0.6)


func is_solid(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return true
	return solid[c.y * w + c.x] == 1


func set_solid(c: Vector2i, value: bool) -> void:
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return
	solid[c.y * w + c.x] = 1 if value else 0
	astar.set_point_solid(c, value)


func find_path(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	if is_solid(to):
		to = nearest_walkable(to)
	if is_solid(from):
		from = nearest_walkable(from)
	return astar.get_point_path(from, to, true)


func nearest_walkable(c: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if not is_solid(n):
					return n
	return c
