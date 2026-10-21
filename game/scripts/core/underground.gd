class_name Underground
extends RefCounted
## The underground levels and the entrances that join them to the surface (MIN-A, owner OD-29: separate underground
## maps tied to their surface places; docs/build17/MIN_A_ARCHITECTURE.md). Each level map (LevelMap) lies in the
## surface's own coordinates, directly under the ground it belongs to; a level is a depth (0 the surface, -1 the first
## level below), and two maps of one level never overlap, so (level, x, y) names one cell of the world.
##
## Generated from the world's seed by integer hashing (Overworld.hash32, salts of its own) and the village's static
## layout (village.json "solid"), never from world.rng or runtime state, and never in the overworld's chunks: the same
## seed gives the same galleries on every machine. Not saved: World.load_dict makes it again from the seed. The
## galleries and their seams are described by data/underground.json (mml-underground/1).

const GEN_VERSION := 1
const SURFACE := 0

var seed := 1
var maps: Array = []                   # LevelMap, sorted by id
var portals: Array = []                # {id, ends: [{level, stand: Vector2i, door: Vector2i}, {...}]}
var seams: Array = []                  # the generated seams, as deposit records {x, y, ore, amount, level}
var specs := {}                        # map id -> its gallery entry in underground.json (tiles, for the view)


static func create(world_seed: int, village: VillageMap) -> Underground:
	var u := Underground.new()
	u.seed = world_seed
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/underground.json"))
	var galleries: Array = data.galleries.duplicate()
	galleries.sort_custom(func(a, b): return str(a.id) < str(b.id))
	for g in galleries:
		u._make_gallery(g, village)
	return u


# ---------------------------------------------------------------- lookups --------------------
## The level map holding a cell of a level, or null (rock everywhere off the maps).
func map_at(level: int, c: Vector2i) -> LevelMap:
	for m: LevelMap in maps:
		if m.level == level and m.in_level(c):
			return m
	return null


func level_map(id: String) -> LevelMap:
	for m: LevelMap in maps:
		if m.id == id:
			return m
	return null


## Collision below the surface (level < 0). Everything off a map is rock.
func is_solid(level: int, c: Vector2i) -> bool:
	var m := map_at(level, c)
	return m == null or m.is_solid(c)


## A route on one level below the surface, on the map that holds `from`; empty if none.
func find_path(level: int, from: Vector2i, to: Vector2i) -> PackedVector2Array:
	var m := map_at(level, from)
	if m == null:
		return PackedVector2Array()
	return m.find_path(from, to)


## The crossing an actor on `cell` of `level` makes by stepping in direction `dir`: the portal whose end there has
## `cell` as its stand and whose door `dir` points at. {portal, from: the end left, to: the end reached}, or {}.
func portal_from(level: int, cell: Vector2i, dir: Vector2) -> Dictionary:
	if dir.length() < 0.1:
		return {}
	for p in portals:
		for i in 2:
			var e: Dictionary = p.ends[i]
			if int(e.level) != level or e.stand != cell:
				continue
			var toward := Vector2(e.door - e.stand)
			if dir.normalized().dot(toward.normalized()) > 0.6:
				return {"portal": p, "from": e, "to": p.ends[1 - i]}
	return {}


## The first crossing on the way from level `from` to level `to` (the level router: a breadth-first search over the
## portals, which are few): {portal, from: the end to walk to on `from`, to: the end arrived at}, or {} if no way.
## Portals are taken in their sorted order, so the route is the same on every machine.
func next_leg(from: int, to: int) -> Dictionary:
	if from == to:
		return {}
	var first := {from: {}}
	var queue := [from]
	var qi := 0
	while qi < queue.size():
		var lv: int = queue[qi]
		qi += 1
		for p in portals:
			for i in 2:
				var e: Dictionary = p.ends[i]
				var o: Dictionary = p.ends[1 - i]
				if int(e.level) != lv or first.has(int(o.level)):
					continue
				var leg: Dictionary = first[lv] if lv != from else {"portal": p, "from": e, "to": o}
				first[int(o.level)] = leg
				if int(o.level) == to:
					return leg
				queue.append(int(o.level))
	return {}


## The level a point lies on as far as the ground can tell: the floor of a level map, and the rock walls beside it
## (where its seams are), under the surface's static rock are that level's (the galleries lie only there, with a cell
## of rock all round their floor, MIN-A); anything else is the surface's. Not for stacked levels (one level so far).
func level_at(village: VillageMap, c: Vector2i) -> int:
	for m: LevelMap in maps:
		if not m.in_level(c) or not _static_solid(village, c):
			continue
		if not m.is_solid(c) or m._touches_floor(c):
			return m.level
	return SURFACE


## The end of a portal on `level` whose door is `cell` ({} none): a tap on the adit means "go in".
func portal_door(level: int, cell: Vector2i) -> Dictionary:
	for p in portals:
		for e in p.ends:
			if int(e.level) == level and e.door == cell:
				return e
	return {}


## Fresh copies of the generated seams (World.setup puts them in World.deposits).
func seam_records() -> Array:
	return seams.map(func(s): return s.duplicate())


## The gallery's map and seams as text (tests: identical for a seed).
func fingerprint() -> String:
	var parts := PackedStringArray()
	for m: LevelMap in maps:
		parts.append("%s %d %s\n%s" % [m.id, m.level, str(m.region), m.to_text()])
	for s in seams:
		parts.append("%d,%d,%d,%s,%d" % [int(s.level), int(s.x), int(s.y), str(s.ore), int(s.amount)])
	return "\n".join(parts)


# ---------------------------------------------------------------- generation -----------------
## 0..n-1 from the hash of the seed, a salt and a cell.
func _roll(salt: int, a: int, b: int, n: int) -> int:
	return Overworld.hash32(seed, salt, a, b) % n


static func _static_solid(village: VillageMap, c: Vector2i) -> bool:
	if not village.in_village(c):
		return false
	return str(village.data.solid[c.y])[c.x] == "1"


## One gallery under a surface place: the 4-connected rock of the village's static layout that holds the portal's
## door is the ground it may lie under (the mine hill for the adit). Floor only under that rock; winding passages
## from the entrance, chambers where they end, one smoothing pass, then only what the entrance reaches is kept.
func _make_gallery(g: Dictionary, village: VillageMap) -> void:
	var level := int(g.level)
	var surface_stand := Vector2i(int(g.portal.stand[0]), int(g.portal.stand[1]))
	var door := Vector2i(int(g.portal.door[0]), int(g.portal.door[1]))
	var inside := door - surface_stand + door             # one step further in, beyond the adit's mouth
	# the rock it lies under: flood the static solid cells from the door, within the cap
	var cap := Rect2i(door - Vector2i(int(g.max_half_w), int(g.max_depth)), Vector2i(2 * int(g.max_half_w) + 1, int(g.max_depth) + 1))
	var rock := {door: true}
	var queue: Array[Vector2i] = [door]
	var qi := 0
	while qi < queue.size():
		var c: Vector2i = queue[qi]
		qi += 1
		for d: Vector2i in VillageMap.SIDES:
			var n := c + d
			if not rock.has(n) and cap.has_point(n) and _static_solid(village, n):
				rock[n] = true
				queue.append(n)
	var lo := door
	var hi := door
	for c: Vector2i in rock:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var region := Rect2i(lo, hi - lo + Vector2i.ONE).grow(1)
	region = region.merge(Rect2i(surface_stand, Vector2i.ONE))     # the daylight mouth (rock below) is on the map
	# floor only where the rock above is at least a cell deep all round: no surface walker stands beside the floor
	var allowed := func(c: Vector2i) -> bool:
		if not region.grow(-1).has_point(c):
			return false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if not rock.has(c + Vector2i(dx, dy)):
					return false
		return true
	var open := {}
	var carve := func(c: Vector2i) -> void:
		if allowed.call(c):
			open[c] = true
	# the way in: the inner mouth under the adit and a short straight passage into the hill
	var keep := [door]
	open[door] = true
	for k in int(g.entry_len):
		var c := door + (inside - door) * (k + 1)
		carve.call(c)
		keep.append(c)
	var start: Vector2i = keep[keep.size() - 1]
	var dirs := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]
	var ends: Array[Vector2i] = []
	for wk in int(g.worms):
		var at := start
		var dir: int = [4, 0, 6, 5, 7][wk % 5]                    # west, east, inward, then the diagonals
		for s in int(g.worm_steps):
			var turn: int = [-1, 0, 0, 1][_roll(11 + wk, s, 0, 4)]
			dir = posmod(dir + turn, 8)
			var nxt: Vector2i = at + (dirs[dir] as Vector2i)
			var tries := 0
			while not allowed.call(nxt) and tries < 8:
				dir = posmod(dir + (1 if _roll(12 + wk, s, tries, 2) == 0 else -1) * (1 + tries / 2), 8)
				nxt = at + (dirs[dir] as Vector2i)
				tries += 1
			if not allowed.call(nxt):
				break
			if dir % 2 == 1:
				carve.call(Vector2i(nxt.x, at.y))                # a diagonal step keeps the passage four-connected
			at = nxt
			carve.call(at)
			if _roll(13 + wk, s, 1, 100) < int(g.wide_percent):
				for d: Vector2i in VillageMap.SIDES:
					carve.call(at + d)                           # the passage widens here
		ends.append(at)
	# chambers: irregular blobs where the first passages end
	for ci in mini(int(g.chambers), ends.size()):
		var cc: Vector2i = ends[ci]
		var rx := int(g.chamber_rx[0]) + _roll(21, ci, 0, int(g.chamber_rx[1]) - int(g.chamber_rx[0]) + 1)
		var ry := int(g.chamber_ry[0]) + _roll(22, ci, 0, int(g.chamber_ry[1]) - int(g.chamber_ry[0]) + 1)
		for dy in range(-ry, ry + 1):
			for dx in range(-rx, rx + 1):
				var inside2 := dx * dx * ry * ry + dy * dy * rx * rx
				var lim := rx * rx * ry * ry
				var wob := (_roll(23, cc.x + dx, cc.y + dy, 100) - 50) * lim / 160     # an uneven edge
				if inside2 <= lim + wob:
					carve.call(cc + Vector2i(dx, dy))
	# one smoothing pass: rock nearly surrounded by floor opens, a floor cell alone closes
	var after := open.duplicate()
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var c := Vector2i(x, y)
			if not allowed.call(c) or keep.has(c):
				continue
			var n8 := 0
			for d in dirs:
				if open.has(c + (d as Vector2i)):
					n8 += 1
			if not open.has(c) and n8 >= 5:
				after[c] = true
			elif open.has(c) and n8 <= 1:
				after.erase(c)
	open = after
	var m := LevelMap.new(str(g.id), level, region)
	for c: Vector2i in open:
		m.solid[m._i(c)] = 0
	# no black holes (DVW-A10): only the floor the entrance reaches stays floor
	var reach := m.reachable_from(door)
	for c in m.floor_cells():
		if not reach.has(c):
			m.solid[m._i(c)] = 1
	m.setup_astar()
	maps.append(m)
	maps.sort_custom(func(a: LevelMap, b: LevelMap): return a.id < b.id)
	specs[m.id] = g
	portals.append({"id": str(g.portal.id), "ends": [
		{"level": SURFACE, "stand": surface_stand, "door": door},
		{"level": level, "stand": door, "door": surface_stand}]})
	_place_seams(g, m, village, rock, door)


## The gallery's seams: on wall cells (rock beside the floor) under the surface rock, away from the entrance, no two
## side by side, in a hashed order; each the village's own amount for its ore (village.json "deposits"), unless the
## gallery's data names one. Ordinary deposit records with the level.
func _place_seams(g: Dictionary, m: LevelMap, village: VillageMap, rock: Dictionary, door: Vector2i) -> void:
	var amount_of := {}
	for d in village.data.deposits:
		if not amount_of.has(str(d.ore)):
			amount_of[str(d.ore)] = int(d.amount)
	var cands := []
	for c in m.wall_cells():
		if not rock.has(c) or maxi(absi(c.x - door.x), absi(c.y - door.y)) <= 2:
			continue
		cands.append([Overworld.hash32(seed, 41, c.x, c.y), c.y, c.x])
	cands.sort()
	var taken := {}
	var ci := 0
	for spec in g.seams:
		for k in int(spec.count):
			while ci < cands.size():
				var c := Vector2i(int(cands[ci][2]), int(cands[ci][1]))
				ci += 1
				var crowded := false
				for d: Vector2i in VillageMap.SIDES:
					if taken.has(c + d):
						crowded = true
				if crowded:
					continue
				taken[c] = true
				var ore := str(spec.ore)
				seams.append({"x": c.x, "y": c.y, "ore": ore, "amount": int(spec.get("amount", amount_of.get(ore, 0))), "level": m.level})
				break
