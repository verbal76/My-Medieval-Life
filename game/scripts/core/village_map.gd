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
var overworld: Overworld          # the world around the village (null: the village alone, as in the simulation tests)


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


## Collision for the player and projectiles: the village's own map inside it, the overworld outside.
## (The village simulation, its path-finding and building placement keep using is_solid: outside the
## village is a wall to them.)
func is_solid_world(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return overworld != null and overworld.is_solid(c)
	return solid[c.y * w + c.x] == 1


func in_village(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h


func set_solid(c: Vector2i, value: bool) -> void:
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return
	solid[c.y * w + c.x] = 1 if value else 0
	astar.set_point_solid(c, value)


func find_path(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	from = from.clamp(Vector2i.ZERO, Vector2i(w - 1, h - 1))      # the village's grid only: villagers never leave it
	to = to.clamp(Vector2i.ZERO, Vector2i(w - 1, h - 1))
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


## A route for the player: the village grid when both ends are in the village, else a small A* over
## the cells between them (world collision), at most WORLD_PATH_CELLS across. Empty: no route found
## (or too far); the caller then walks straight and slides along what is in the way.
const WORLD_PATH_CELLS := 140


func find_path_world(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	if in_village(from) and in_village(to):
		return find_path(from, to)
	var lo := Vector2i(mini(from.x, to.x), mini(from.y, to.y)) - Vector2i(10, 10)
	var hi := Vector2i(maxi(from.x, to.x), maxi(from.y, to.y)) + Vector2i(11, 11)
	if hi.x - lo.x > WORLD_PATH_CELLS or hi.y - lo.y > WORLD_PATH_CELLS:
		return PackedVector2Array()
	var g := AStarGrid2D.new()
	g.region = Rect2i(lo, hi - lo)
	g.cell_size = Vector2(1, 1)
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	g.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	g.update()
	for y in range(lo.y, hi.y):
		for x in range(lo.x, hi.x):
			if is_solid_world(Vector2i(x, y)):
				g.set_point_solid(Vector2i(x, y), true)
	if g.is_point_solid(from):
		from = _nearest_open(g, from)
	if g.is_point_solid(to):
		to = _nearest_open(g, to)
	return g.get_point_path(from, to, true)


func _nearest_open(g: AStarGrid2D, c: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if g.region.has_point(n) and not g.is_point_solid(n):
					return n
	return c


const SIDES := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]       # north, east, south, west


## Where the player can walk out of the village: for each side of the map, the road cell nearest that
## side and a trail of clear grass from it to the map's edge. Each is {side, road, trail (cells from
## the road to the edge cell, inclusive), edge, dir (outward), out (the cell just outside)}. The
## overworld joins its road network to `out`; Main draws the trail as dirt path so the road visibly
## leaves the village. A side with no walkable way out is left out.
func exits() -> Array:
	var objects := PackedByteArray()          # cells holding a decoration: the trail goes round them when it can
	objects.resize(w * h)
	for lay in data.layers:
		var n: String = lay.name
		if not (n.begins_with("below") or n.begins_with("above")):
			continue
		var d: Array = lay.data
		for i in d.size():
			if int(d[i]) >= 0:
				objects[i] = 1
	var cells := []
	for c in data.road:
		cells.append(Vector2i(int(c[0]), int(c[1])))
	var res := []
	for side in 4:
		var best := Vector2i(-1, -1)
		var best_key := INF
		for c: Vector2i in cells:
			if is_solid(c):
				continue
			var depth: int = [c.y, w - 1 - c.x, h - 1 - c.y, c.x][side]
			var along: int = c.x if side % 2 == 0 else c.y
			var mid: int = w / 2 if side % 2 == 0 else h / 2
			var key := float(depth) * 1000.0 + absi(along - mid) + (c.x + c.y * 0.001)       # nearest the side, then the middle
			if key < best_key:
				best_key = key
				best = c
		if best.x < 0:
			continue
		for strict in [true, false]:
			var found := _trail(best, side, objects if strict else PackedByteArray())
			if not found.is_empty():
				var edge: Vector2i = found[found.size() - 1]
				res.append({"side": side, "road": best, "trail": found, "edge": edge, "dir": SIDES[side], "out": edge + (SIDES[side] as Vector2i)})
				break
	return res


## Shortest 4-neighbour walk over open cells from `from` to any cell on map side `side`.
func _trail(from: Vector2i, side: int, objects: PackedByteArray) -> Array:
	var prev := {from: from}
	var queue: Array[Vector2i] = [from]
	var qi := 0
	var goal := Vector2i(-1, -1)
	while qi < queue.size():
		var c: Vector2i = queue[qi]
		qi += 1
		var on_edge: bool = [c.y == 0, c.x == w - 1, c.y == h - 1, c.x == 0][side]
		if on_edge:
			goal = c
			break
		for d: Vector2i in SIDES:
			var n := c + d
			if not in_village(n) or prev.has(n) or is_solid(n):
				continue
			if not objects.is_empty() and objects[n.y * w + n.x] == 1:
				continue
			prev[n] = c
			queue.append(n)
	if goal.x < 0:
		return []
	var out := [goal]
	while out[0] != from:
		out.push_front(prev[out[0]])
	return out
