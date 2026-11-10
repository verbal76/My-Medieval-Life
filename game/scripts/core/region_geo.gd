class_name RegionGeo
extends RefCounted
## B25R1-018 (owner directive 2026-11-03, regional world reconstruction): the region's fixed geography, read from
## game/data/region_layout.json (mml-region-layout/1; docs/design/REGION_RECONSTRUCTION_B25R1.md): the settlements' anchors, the
## regions (the Downs, the waste, the Wood Perilous, the vine country, the meadows), the landmarks and the main routes' control
## points. Overworld (GEN_VERSION 4) asks it what kind of country a cell is in, and lays its sites and main roads from it;
## Landmarks lists its landmarks. The water courses and crossings in the same file are the water worker's (Overworld water).
##
## Pure and static: the file is the same for every world, so nothing here depends on the seed or is saved. A region's edge is
## the polygon's, softened by a small per-cell jitter from the seed (`region_at` with a seed), so it never reads as a ruled line.
## Lookups are cached on a coarse grid (CELL tiles), so a chunk costs a few polygon tests, not one per cell.

const CELL := 8                         # the cache's grid, in tiles
const JITTER := 6                       # tiles a region's edge wanders either way

static var _data := {}
static var _regions: Array = []         # [{id, kind, poly: PackedVector2Array, box: Rect2}] in file order (the first match wins)
static var _cache := {}                 # Vector2i (coarse cell) -> region id ("" none)
static var _anchors := {}               # settlement id -> Vector2i
static var _downs := PackedVector2Array()
## KI-09: two threads lay out overworlds at once (the game's, and AerialMap's settlements worker: its own Overworld.create and
## chunks), and both fill `_cache`. An unguarded insert from both corrupted the heap ("double free or corruption", SIGABRT,
## demo_test on a runner without the aerial disk cache). The cache and the one-time load are taken under this lock; what is
## computed between (the regions' polygons, read-only once loaded) needs none. A lookup's answer depends on the cell alone, so
## which thread fills an entry changes nothing.
static var _lock := Mutex.new()


static func data() -> Dictionary:
	if _data.is_empty():
		_lock.lock()
		_load()
		_lock.unlock()
	return _data


static func _load() -> void:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/region_layout.json"))
		assert(d is Dictionary and str(d.get("format", "")) == "mml-region-layout/1", "bad data file region_layout.json")
		_downs = _poly(d.downs.polygon)
		# the Downs first: a cell on them is Downs whatever else the regions' rough boxes say
		_regions.append({"id": "downs", "kind": "downs", "poly": _downs, "box": _box(_downs)})
		for r in d.regions:
			var p := _poly(r.polygon)
			var wb := int(r.get("edge_wobble", 0))
			_regions.append({"id": str(r.id), "kind": str(r.kind), "poly": p, "box": _box(p).grow(wb), "wobble": wb})
		for s in d.settlements:
			_anchors[str(s.id)] = Vector2i(int(s.x), int(s.y))
		_data = d                                # (last: another thread that sees it loaded sees the tables complete)


static func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


static func _box(p: PackedVector2Array) -> Rect2:
	var r := Rect2(p[0], Vector2.ZERO)
	for v in p:
		r = r.expand(v)
	return r


## The anchor (village frame tiles) of settlement or hamlet `id`, or (-1 << 20, 0) when the layout has none.
static func anchor(id: String) -> Vector2i:
	data()
	return _anchors.get(id, Vector2i(-(1 << 20), 0))


static func has_anchor(id: String) -> bool:
	data()
	return _anchors.has(id)


## The id of the region cell (x, y) lies in ("downs", "dry_waste", "wood_perilous", "vine_country", ...), "" outside them all.
## With a seed, the edge wanders by up to JITTER tiles (deterministic: the seed and the cell only).
static func region_at(x: int, y: int, seed := 0) -> String:
	data()
	if seed != 0:
		x += (Overworld.hash32(seed, x >> 3, y >> 3, 901) % (2 * JITTER + 1)) - JITTER
		y += (Overworld.hash32(seed, x >> 3, y >> 3, 902) % (2 * JITTER + 1)) - JITTER
	var cc := Vector2i(Overworld.fdiv(x, CELL), Overworld.fdiv(y, CELL))
	_lock.lock()
	var hit = _cache.get(cc)
	_lock.unlock()
	if hit != null:
		return hit
	var at := Vector2(cc.x * CELL + CELL / 2, cc.y * CELL + CELL / 2)
	var id := ""
	for r in _regions:
		var p := at
		if int(r.get("wobble", 0)) > 0:
			p += _wobble(at, int(r.wobble))
		if (r.box as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, r.poly):
			id = str(r.id)
			break
	_lock.lock()
	_cache[cc] = id
	_lock.unlock()
	return id


## Generation 6 (owner, flyover 2026-11-05: "the southern forest boundary is unusually straight and rectangular"): a region with
## `edge_wobble` W in the layout has its edge moved by a smooth wave of up to W tiles (value noise over WOBBLE_PERIOD tiles, the
## same for every world: the layout is), so a ruled polygon side reads as a natural edge; its extent is the same on average.
const WOBBLE_PERIOD := 56


static func _wobble(at: Vector2, w: int) -> Vector2:
	return Vector2(_wave(at, 911), _wave(at, 912)) * float(w)


static func _wave(at: Vector2, salt: int) -> float:
	var acc := 0.0
	for k in 2:
		var per := float(WOBBLE_PERIOD >> k)
		var gx := floorf(at.x / per)
		var gy := floorf(at.y / per)
		var fx := at.x / per - gx
		var fy := at.y / per - gy
		fx = fx * fx * (3.0 - 2.0 * fx)
		fy = fy * fy * (3.0 - 2.0 * fy)
		var v := func(i: int, j: int) -> float:
			return float(Overworld.hash32(0, int(gx) + i, int(gy) + j, salt * 4 + k) % 2001) / 1000.0 - 1.0
		var top: float = lerpf(v.call(0, 0), v.call(1, 0), fx)
		var bot: float = lerpf(v.call(0, 1), v.call(1, 1), fx)
		acc += lerpf(top, bot, fy) * (0.7 if k == 0 else 0.3)
	return acc


static func in_downs(x: int, y: int) -> bool:
	return region_at(x, y) == "downs"


## The kind of country: "downs", "waste", "great wood", "vineyards", "wildwood valley", "farmland", "meadows", "hills" or "".
static func kind_at(x: int, y: int, seed := 0) -> String:
	var id := region_at(x, y, seed)
	if id == "":
		return ""
	for r in _regions:
		if str(r.id) == id:
			return str(r.kind)
	return ""


## The region's display name for `id` ("the Downs", "the Wood Perilous"), "" if none.
static func region_name(id: String) -> String:
	var d := data()
	if id == "downs":
		return str(d.downs.name)
	for r in d.regions:
		if str(r.id) == id:
			return str(r.name)
	return ""


## The layout's landmarks: [{id, name, kind, at: Vector2i, r, label, object, figure, scale, raised}] in file order (raised: the
## raised ground the overworld gives it, {} none; Overworld._setup_raised).
static func landmarks() -> Array:
	var out := []
	for l in data().landmarks:
		out.append({"id": str(l.id), "name": str(l.name), "kind": str(l.kind), "at": Vector2i(int(l.x), int(l.y)), "r": int(l.get("r", 0)),
			"label": str(l.get("label", "")), "object": str(l.get("object", "")), "figure": l.get("figure", []), "scale": int(l.get("scale", 1)),
			"raised": l.get("raised", {})})
	return out


## The main routes' control points: [{id, kind, points: Array[Vector2i]}] in file order.
static func routes() -> Array:
	var out := []
	for r in data().routes:
		var pts: Array[Vector2i] = []
		for p in r.points:
			pts.append(Vector2i(int(p[0]), int(p[1])))
		out.append({"id": str(r.id), "kind": str(r.kind), "points": pts})
	return out
