class_name LevelMap
extends RefCounted
## One underground level's map (MIN-A, docs/build17/MIN_A_ARCHITECTURE.md): its own collision and its own
## path-finder, laid in the surface's coordinates directly under the ground it belongs to: cell (x, y) of this map
## lies under cell (x, y) of the surface. Outside its region it is solid rock. Made by Underground (the registry and
## generator); no rendering here, so it runs headless. The surface's VillageMap is never touched by it.

var id := ""                      # stable name, e.g. "adit_gallery"
var level := -1                   # depth: -1 is the first level below the surface (0 is the surface itself)
var region := Rect2i()            # the surface cells it lies under
var solid: PackedByteArray        # 1 = rock, one byte per cell of the region, row by row
var astar := AStarGrid2D.new()


func _init(map_id: String, depth: int, r: Rect2i) -> void:
	id = map_id
	level = depth
	region = r
	solid.resize(r.size.x * r.size.y)
	solid.fill(1)


func in_level(c: Vector2i) -> bool:
	return region.has_point(c)


func _i(c: Vector2i) -> int:
	return (c.y - region.position.y) * region.size.x + (c.x - region.position.x)


func is_solid(c: Vector2i) -> bool:
	if not region.has_point(c):
		return true
	return solid[_i(c)] == 1


func set_solid(c: Vector2i, value: bool) -> void:
	if not region.has_point(c):
		return
	solid[_i(c)] = 1 if value else 0
	if astar.region == region:
		astar.set_point_solid(c, value)


## The A* over the region, as VillageMap._setup_astar sets up the village's (the same diagonal rule and heuristic).
func setup_astar() -> void:
	astar.region = region
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for c in cells():
		if is_solid(c):
			astar.set_point_solid(c, true)


## Every cell of the region, row by row.
func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			out.append(Vector2i(x, y))
	return out


## The walkable cells, row by row.
func floor_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in cells():
		if not is_solid(c):
			out.append(c)
	return out


## Rock cells beside the floor (its four neighbours): the cave's walls, row by row.
func wall_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in cells():
		if is_solid(c) and _touches_floor(c):
			out.append(c)
	return out


func _touches_floor(c: Vector2i) -> bool:
	for d: Vector2i in VillageMap.SIDES:
		if not is_solid(c + d):
			return true
	return false


## A route on this level only, clamped to its region; a rock end is moved to the nearest floor cell. Empty: none.
func find_path(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	from = from.clamp(region.position, region.end - Vector2i.ONE)
	to = to.clamp(region.position, region.end - Vector2i.ONE)
	if is_solid(to):
		to = nearest_walkable(to)
	if is_solid(from):
		from = nearest_walkable(from)
	if is_solid(from) or is_solid(to):
		return PackedVector2Array()
	return astar.get_point_path(from, to, true)


func nearest_walkable(c: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if not is_solid(n):
					return n
	return c


## The floor cells reachable from `from` by four-neighbour steps (cell -> true).
func reachable_from(from: Vector2i) -> Dictionary:
	var seen := {}
	if is_solid(from):
		return seen
	seen[from] = true
	var queue: Array[Vector2i] = [from]
	var qi := 0
	while qi < queue.size():
		var c: Vector2i = queue[qi]
		qi += 1
		for d: Vector2i in VillageMap.SIDES:
			var n := c + d
			if not seen.has(n) and not is_solid(n):
				seen[n] = true
				queue.append(n)
	return seen


## The map as text, one row per line ("#" rock, "." floor): for tests and determinism checks.
func to_text() -> String:
	var rows := PackedStringArray()
	for y in range(region.position.y, region.end.y):
		var row := ""
		for x in range(region.position.x, region.end.x):
			row += "#" if is_solid(Vector2i(x, y)) else "."
		rows.append(row)
	return "\n".join(rows)
