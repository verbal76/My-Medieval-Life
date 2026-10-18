class_name Overworld
extends RefCounted
## The world around the village: an endless medieval landscape of meadows, woods, forests, rocky
## hills and mountain ranges, crossed by roads. Headless (no nodes): the view (OverworldView) and
## the collision (VillageMap.is_solid_world) both ask this class.
##
## It is a pure function of the world seed (CLAUDE.md section 6): the same seed and chunk always
## give the same chunk, on every platform and after the chunk was evicted from the cache. All the
## arithmetic is integer (a 32-bit hash, fixed-point interpolation); there is no global random, no
## wall-clock time, and no iteration over unordered collections where order matters. Nothing but
## the seed and the player's changes (felled trees) is ever saved.
##
## Space is tiles in the village's coordinates: the village is the rectangle (0,0)-(119,89) and stays
## exactly as its map says. The world is cut into CHUNK x CHUNK tile chunks, generated on demand and
## cached (bounded; least recently used evicted).
##
## Layout (GEN_VERSION 1):
##  - Value-noise fields (several octaves each) give forest density, a clearing mask, rockiness,
##    tree species and flower meadows. A ridge field masked by a regional field gives mountain
##    ranges: coherent ridge lines that come and go. Mountains are drawn with the free tileset's
##    grass/cliff wangset (a raised plateau with a rocky rim) and every cell touching a cliff corner
##    is solid. Mountain cells are cut by wobbling "pass" corridors on a coarse lattice, so open
##    ground is always connected: no range or ring of cliffs closes the world into pockets.
##  - Roads are a global network: a node on a jittered grid (NODE tiles apart), each joined to some
##    neighbours by a bent 4-connected polyline that depends only on the two nodes. Every chunk
##    rasterises the segments that touch it, so roads cross chunk seams unbroken. The village's four
##    exits (VillageMap.exits) are joined to the nearest nodes. A road and one tile round it never
##    hold a cliff, tree or rock.
##  - Trees and rocks are single solid cells, never within a cell of each other or of a cliff, so
##    they cannot wall anything in. Flowers and bushes are walkable decoration.

const GEN_VERSION := 1
const CHUNK := 32
const PAD := 4                           # cells computed round a chunk, so neighbours' rules need no other chunk
const AREA := CHUNK + 2 * PAD
const GRID := AREA + 1                   # noise samples (cell corners) over the area
const NODE := 96                         # road node spacing
const MAX_CACHED := 160                  # chunks kept
const VILLAGE_CLEAR := 14                # no cliff within this many tiles of the village
const OBJECT_MARGIN := 5                 # no tree or rock this close to the village ...
const OBJECT_RAMP := 20                  # ... and they thin out over the next tiles
const PASS_LATTICE := 72                 # distance between mountain passes
const NO_TREE := 255
const M := 0xFFFFFFFF

class Chunk extends RefCounted:
	var cx := 0
	var cy := 0
	var ground := PackedInt32Array()     # tile value per cell, row-major (-1 inside the village)
	var path := PackedInt32Array()       # road tile per cell, -1 none
	var deco := PackedInt32Array()       # flowers, bushes and rocks (objects layer), -1 none
	var solid := PackedByteArray()       # 1 = blocked
	var kind := PackedByteArray()        # tree kind per cell, NO_TREE where none
	var snow := PackedByteArray()        # 1 where the tree stands high (highland), 2 on a mountain top (inside the cliffs): snow-covered variants
	var trees := PackedInt32Array()      # x, y, kind of each tree (world cells); includes unreachable mountain trees
	var road := PackedByteArray()        # AREA x AREA road mask round the chunk (cell (x, y) at (y + PAD) * AREA + x + PAD)
	var last_use := 0

var seed := 1
var village := Rect2i(0, 0, 120, 90)
var gates: Array = []                    # {out: Vector2i, dir: Vector2i}: where the village's roads leave
var tiles := {}                          # overworld_tiles.json
var changes := {}                        # Vector2i -> a tree the player changed (felled, growing, planted): {x, y, species, state, regrow, born, ow, planted?}
var clock := 0.0                         # the game minute (World keeps it): changed trees grow lazily by it
var cache := {}                          # Vector2i -> Chunk
var generated := 0                       # chunks generated so far (tests: the cache bound, no work for loaded chunks)
var _use := 0
var _segments := {}                      # segment key -> PackedInt32Array of x, y cells
var _links: Array = []                   # the gates' road polylines: {a, b, key}
var _gate_inner := {}                    # village cells a gate road joins (they count as road for the tile drawn)
var _wob := {}                           # axis noise cache


static func create(world_seed: int, m: VillageMap) -> Overworld:
	var o := Overworld.new()
	o.seed = world_seed
	o.village = Rect2i(0, 0, m.w, m.h)
	o.tiles = JSON.parse_string(FileAccess.get_file_as_string("res://data/overworld_tiles.json"))
	for e in m.exits():
		o.gates.append({"out": e.out, "dir": e.dir})
	o._setup_gates()
	return o


# ---------------------------------------------------------------- integer noise --------------
## A 32-bit hash of four ints (every product stays under 2^63, so nothing overflows).
static func hash32(a: int, b: int, c: int, d: int = 0) -> int:
	var h: int = (((a & M) * 0x1B873593) & M) + (((b & M) * 0x5BD1E995) & M) + (((c & M) * 0x2C1B3C6D) & M) + (((d & M) * 0x297A2D39) & M)
	h &= M
	h ^= h >> 15
	h = (h * 0x45D9F3B) & M
	h ^= h >> 13
	h = (h * 0x119DE1F3) & M
	h ^= h >> 16
	return h


static func fdiv(a: int, b: int) -> int:
	return (a - posmod(a, b)) / b


static func chunk_of(c: Vector2i) -> Vector2i:
	return Vector2i(fdiv(c.x, CHUNK), fdiv(c.y, CHUNK))


## Smooth step of f in 0..256, scaled 0..256.
static func _smooth(f: int) -> int:
	return (f * f * (768 - 2 * f)) >> 16


## Per-sample lattice index (relative to the first lattice point) and smoothed weight, along one axis.
func _axis(o: int, period: int) -> Array:
	var idx := PackedInt32Array()
	var wt := PackedInt32Array()
	idx.resize(GRID)
	wt.resize(GRID)
	var l0 := fdiv(o, period)
	for i in GRID:
		var w := o + i
		var l := fdiv(w, period)
		idx[i] = l - l0
		wt[i] = _smooth(((w - l * period) * 256) / period)
	return [idx, wt, l0]


## A field of GRID x GRID samples (0..1023) at world cell corners (ox + i, oy + j): octaves of value
## noise, the first with `periods[0]` tiles between lattice points, each next half the weight.
func _field(ox: int, oy: int, salt: int, periods: Array) -> PackedInt32Array:
	var acc := PackedInt32Array()
	acc.resize(GRID * GRID)
	var total := 0
	for k in periods.size():
		var p: int = periods[k]
		var wgt := 1 << (periods.size() - 1 - k)
		total += wgt
		var ax := _axis(ox, p)
		var ay := _axis(oy, p)
		var ix: PackedInt32Array = ax[0]
		var sx: PackedInt32Array = ax[1]
		var iy: PackedInt32Array = ay[0]
		var sy: PackedInt32Array = ay[1]
		var lw: int = ix[GRID - 1] + 2
		var lh: int = iy[GRID - 1] + 2
		var lat := PackedInt32Array()
		lat.resize(lw * lh)
		for b in lh:
			for a in lw:
				lat[b * lw + a] = hash32(seed, ax[2] + a, ay[2] + b, salt * 8 + k) & 1023
		for j in GRID:
			var row0: int = iy[j] * lw
			var row1: int = row0 + lw
			var yy: int = sy[j]
			for i in GRID:
				var a: int = ix[i]
				var xx: int = sx[i]
				var v00: int = lat[row0 + a]
				var v10: int = lat[row0 + a + 1]
				var v01: int = lat[row1 + a]
				var v11: int = lat[row1 + a + 1]
				var top: int = v00 + (((v10 - v00) * xx) >> 8)
				var bot: int = v01 + (((v11 - v01) * xx) >> 8)
				acc[j * GRID + i] += (top + (((bot - top) * yy) >> 8)) * wgt
	for q in acc.size():
		acc[q] /= total
	return acc


## Smooth 1-D noise in -range..range at integer t (the wobble of a mountain pass).
func _noise1(salt: int, t: int, period: int, amp: int) -> int:
	var l := fdiv(t, period)
	var f := _smooth(((t - l * period) * 256) / period)
	var a := (hash32(seed, l, 0, salt) & 1023) - 512
	var b := (hash32(seed, l + 1, 0, salt) & 1023) - 512
	return ((a + (((b - a) * f) >> 8)) * amp) / 512


# ---------------------------------------------------------------- roads ----------------------
func _node_excluded(p: Vector2i) -> bool:
	return village.grow(24).has_point(p)


func node_pos(i: int, j: int) -> Vector2i:
	return Vector2i(i * NODE + 14 + hash32(seed, i, j, 21) % (NODE - 28), j * NODE + 14 + hash32(seed, i, j, 22) % (NODE - 28))


## Whether grid node (i, j) is joined to its east (0), south (1), south-east (2) or south-west (3)
## neighbour. A node left with no road at all is joined east.
func _edge(i: int, j: int, k: int) -> bool:
	var raw := _raw_edge(i, j, k)
	if k == 0 and not raw:
		return not (_raw_edge(i, j, 1) or _raw_edge(i, j, 2) or _raw_edge(i, j, 3) or _raw_edge(i - 1, j, 0)
				or _raw_edge(i, j - 1, 1) or _raw_edge(i - 1, j - 1, 2) or _raw_edge(i + 1, j - 1, 3))
	return raw


func _raw_edge(i: int, j: int, k: int) -> bool:
	return hash32(seed, i, j, 30 + k) % 100 < [62, 62, 16, 16][k]


## The cells of road segment `key`, joining a to b: waypoints along the way pushed sideways by the
## hash, 4-connected straight runs between them. Depends only on its arguments and the seed.
func _polyline(a: Vector2i, b: Vector2i, key: int) -> PackedInt32Array:
	var d := b - a
	var length := maxi(absi(d.x), absi(d.y)) + mini(absi(d.x), absi(d.y)) / 2
	var n := maxi(1, length / 14)
	var amp := mini(9, length / 10)
	var points: Array[Vector2i] = [a]
	for k in range(1, n):
		var base := a + d * k / n
		var off := ((hash32(seed, key, k, 50) % 2001) - 1000) * amp / 1000
		points.append(base + (Vector2i(0, off) if absi(d.x) >= absi(d.y) else Vector2i(off, 0)))
	points.append(b)
	var out := PackedInt32Array()
	out.append(a.x)
	out.append(a.y)
	for k in range(1, points.size()):
		var p: Vector2i = points[k - 1]
		var q: Vector2i = points[k]
		var dx := absi(q.x - p.x)
		var dy := absi(q.y - p.y)
		var sx := 1 if q.x > p.x else -1
		var sy := 1 if q.y > p.y else -1
		var x := p.x
		var y := p.y
		var ix := 0
		var iy := 0
		while ix < dx or iy < dy:
			if (1 + 2 * ix) * dy < (1 + 2 * iy) * dx:
				x += sx
				ix += 1
			else:
				y += sy
				iy += 1
			out.append(x)
			out.append(y)
	return out


func _setup_gates() -> void:
	_links.clear()
	_gate_inner.clear()
	var g := 0
	for e in gates:
		var out: Vector2i = e.out
		var dir: Vector2i = e.dir
		_gate_inner[out - dir] = true
		var far := out + dir * 16
		_links.append({"a": out, "b": far, "key": 1000 + g * 8})
		# the three nearest road nodes
		var ci := fdiv(far.x, NODE)
		var cj := fdiv(far.y, NODE)
		var near: Array = []
		for j in range(cj - 3, cj + 4):
			for i in range(ci - 3, ci + 4):
				var p := node_pos(i, j)
				if not _node_excluded(p):
					near.append([(p - far).length_squared(), i, j, p])
		near.sort()
		for k in mini(3, near.size()):
			_links.append({"a": far, "b": near[k][3], "key": 1000 + g * 8 + 1 + k})
		g += 1


func _segment(key: Vector3i, a: Vector2i, b: Vector2i, hkey: int) -> PackedInt32Array:
	var s: PackedInt32Array = _segments.get(key, PackedInt32Array())
	if s.is_empty():
		if _segments.size() > 800:
			_segments.clear()
		s = _polyline(a, b, hkey)
		_segments[key] = s
	return s


## The road cells of the AREA x AREA block whose top-left cell is (ox, oy).
func _road_mask(ox: int, oy: int) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(AREA * AREA)
	var keep := Rect2i(village.grow(10))
	var i0 := fdiv(ox - 14, NODE) - 2
	var i1 := fdiv(ox + AREA + 14, NODE) + 1
	var j0 := fdiv(oy - 14, NODE) - 2
	var j1 := fdiv(oy + AREA + 14, NODE) + 1
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var a := node_pos(i, j)
			if _node_excluded(a):
				continue
			for k in 4:
				var ni: int = i + [1, 0, 1, -1][k]
				var nj: int = j + [0, 1, 1, 1][k]
				var b := node_pos(ni, nj)
				if _node_excluded(b) or not _edge(i, j, k):
					continue
				var box := Rect2i(mini(a.x, b.x) - 12, mini(a.y, b.y) - 12, absi(a.x - b.x) + 24, absi(a.y - b.y) + 24)
				if not box.intersects(Rect2i(ox, oy, AREA, AREA)):
					continue
				var bb := Rect2i(mini(a.x, b.x), mini(a.y, b.y), absi(a.x - b.x), absi(a.y - b.y))
				if bb.intersects(keep):
					continue                          # a road never runs through the village: its exits join the network
				_stamp(mask, _segment(Vector3i(i, j, k), a, b, (i * 7919 + j * 104729 + k) & 0xFFFFFF), ox, oy)
	var li := 0
	for l in _links:
		var a2: Vector2i = l.a
		var b2: Vector2i = l.b
		var box2 := Rect2i(mini(a2.x, b2.x) - 12, mini(a2.y, b2.y) - 12, absi(a2.x - b2.x) + 24, absi(a2.y - b2.y) + 24)
		if box2.intersects(Rect2i(ox, oy, AREA, AREA)):
			_stamp(mask, _segment(Vector3i(-1, li, 0), a2, b2, int(l.key)), ox, oy)
		li += 1
	return mask


func _stamp(mask: PackedByteArray, cells: PackedInt32Array, ox: int, oy: int) -> void:
	for q in range(0, cells.size(), 2):
		var x := cells[q] - ox
		var y := cells[q + 1] - oy
		if x >= 0 and y >= 0 and x < AREA and y < AREA and not village.has_point(Vector2i(cells[q], cells[q + 1])):
			mask[y * AREA + x] = 1


# ---------------------------------------------------------------- chunks ---------------------
## Whether the village covers every cell of the chunk (nothing to generate or draw there).
func chunk_in_village(cc: Vector2i) -> bool:
	return village.encloses(Rect2i(cc.x * CHUNK, cc.y * CHUNK, CHUNK, CHUNK))


func get_chunk(cc: Vector2i) -> Chunk:
	var ch: Chunk = cache.get(cc)
	_use += 1
	if ch == null:
		ch = _generate(cc.x, cc.y)
		ch.last_use = _use
		cache[cc] = ch
		if cache.size() > MAX_CACHED:
			_evict()
	ch.last_use = _use
	return ch


func _evict() -> void:
	while cache.size() > MAX_CACHED:
		var oldest: Vector2i = Vector2i.ZERO
		var best := 1 << 60
		for k: Vector2i in cache:
			if cache[k].last_use < best:
				best = cache[k].last_use
				oldest = k
		cache.erase(oldest)


func _vdist(x: int, y: int) -> int:
	var dx := maxi(maxi(village.position.x - x, x - (village.end.x - 1)), 0)
	var dy := maxi(maxi(village.position.y - y, y - (village.end.y - 1)), 0)
	return maxi(dx, dy)


func _generate(cx: int, cy: int) -> Chunk:
	generated += 1
	var ox := cx * CHUNK - PAD
	var oy := cy * CHUNK - PAD
	var fe := _field(ox, oy, 1, [128, 64, 32])
	var fm := _field(ox, oy, 2, [320, 160])
	var ff := _field(ox, oy, 3, [96, 48, 24])
	var fc := _field(ox, oy, 4, [24, 12])
	var fr := _field(ox, oy, 5, [72, 36])
	var fs := _field(ox, oy, 6, [160, 80])
	var fl := _field(ox, oy, 7, [28, 14])
	var road := _road_mask(ox, oy)
	var open := PackedByteArray()                 # road and one cell round it
	open.resize(AREA * AREA)
	for j in range(1, AREA - 1):
		for i in range(1, AREA - 1):
			if road[j * AREA + i] == 1:
				for dj in range(-1, 2):
					for di in range(-1, 2):
						open[(j + dj) * AREA + i + di] = 1
	# passes: wobbling corridors on a lattice where mountains never stand
	var wob_x := PackedInt32Array()               # per row: where the vertical passes sit
	var wob_y := PackedInt32Array()
	wob_x.resize(GRID)
	wob_y.resize(GRID)
	var shift_x := hash32(seed, 0, 0, 41) % PASS_LATTICE
	var shift_y := hash32(seed, 0, 0, 42) % PASS_LATTICE
	for q in GRID:
		wob_x[q] = _noise1(43, oy + q, 44, 15) + shift_x
		wob_y[q] = _noise1(45, ox + q, 44, 15) + shift_y
	# cliff corners
	var cliff := PackedByteArray()
	cliff.resize(GRID * GRID)
	for j in GRID:
		for i in GRID:
			var k := j * GRID + i
			var reach := (fm[k] - 470) / 4
			if reach <= 0 or absi(fe[k] - 512) >= reach:
				continue
			var wx := ox + i
			var wy := oy + j
			if posmod(wx - wob_x[j] + 3, PASS_LATTICE) < 6 or posmod(wy - wob_y[i] + 3, PASS_LATTICE) < 6:
				continue
			if _vdist(wx, wy) < VILLAGE_CLEAR:
				continue
			# never beside a road: all four cells round the corner must be clear of road and its margin
			if (j > 0 and i > 0 and open[(j - 1) * AREA + i - 1] == 1) or (j > 0 and i < AREA and open[(j - 1) * AREA + i] == 1) \
					or (i > 0 and j < AREA and open[j * AREA + i - 1] == 1) or (i < AREA and j < AREA and open[j * AREA + i] == 1):
				continue
			cliff[k] = 1
	# cells: blocked by a cliff, deep inside one
	var blocked := PackedByteArray()
	var inner := PackedByteArray()
	blocked.resize(AREA * AREA)
	inner.resize(AREA * AREA)
	for j in AREA:
		for i in AREA:
			var k := j * GRID + i
			var n: int = cliff[k] + cliff[k + 1] + cliff[k + GRID] + cliff[k + GRID + 1]
			blocked[j * AREA + i] = 1 if n > 0 else 0
			inner[j * AREA + i] = 1 if n == 4 else 0
	# trees and rocks: candidates compete for the cell, so none are ever adjacent
	var cand := PackedByteArray()                 # 0 none, 1 tree, 2 rock, 3 mountain tree, 4 mountain boulder
	var prio := PackedInt32Array()
	cand.resize(AREA * AREA)
	prio.resize(AREA * AREA)
	for j in range(PAD - 1, PAD + CHUNK + 1):
		for i in range(PAD - 1, PAD + CHUNK + 1):
			var q := j * AREA + i
			var x := ox + i
			var y := oy + j
			var vd := _vdist(x, y)
			if vd < OBJECT_MARGIN or open[q] == 1 or open[q - AREA] == 1:
				continue
			var hv := hash32(seed, x, y, 60) & 1023
			prio[q] = hash32(seed, x, y, 61)
			if blocked[q] == 1:
				# a mountain top, a plateau nobody can reach: pines and boulders cover it, so it reads as wooded rock
				if inner[q] == 1:
					if hv < 520:
						cand[q] = 3
					elif hv < 640:
						cand[q] = 4
				continue
			var clear := true
			for dj in range(-1, 2):
				for di in range(-1, 2):
					if blocked[q + dj * AREA + di] == 1:
						clear = false
			if not clear:
				continue
			var k := j * GRID + i
			var ramp := clampi((vd - OBJECT_MARGIN) * 1024 / OBJECT_RAMP, 0, 1024)
			var tree_p := clampi(maxi(10, (ff[k] - 500) * 8), 0, 1000)
			if fc[k] < 220:
				tree_p /= 3                          # a clearing
			var rock_p := 2 + clampi((fr[k] - 600) * 2, 0, 100) + clampi((fm[k] - 460) / 3, 0, 60)
			if hv < rock_p * ramp / 1024:
				cand[q] = 2
			elif hv < (rock_p + tree_p) * ramp / 1024:
				cand[q] = 1
	var ch := Chunk.new()
	ch.cx = cx
	ch.cy = cy
	ch.road = road
	var cells := CHUNK * CHUNK
	ch.ground.resize(cells)
	ch.path.resize(cells)
	ch.deco.resize(cells)
	ch.solid.resize(cells)
	ch.kind.resize(cells)
	ch.kind.fill(NO_TREE)
	ch.snow.resize(cells)
	ch.path.fill(-1)
	ch.deco.fill(-1)
	var grass: Array = tiles.grass
	var cliff_tiles: Array = tiles.cliff
	var tree_kinds: Array = tiles.trees
	for y in CHUNK:
		for x in CHUNK:
			var wx := cx * CHUNK + x
			var wy := cy * CHUNK + y
			var c := y * CHUNK + x
			var i := x + PAD
			var j := y + PAD
			var q := j * AREA + i
			if village.has_point(Vector2i(wx, wy)):
				ch.ground[c] = -1
				continue
			var gk := j * GRID + i
			var corners: int = cliff[gk] | (cliff[gk + 1] << 1) | (cliff[gk + GRID + 1] << 2) | (cliff[gk + GRID] << 3)
			var opts: Array = cliff_tiles[corners]
			ch.ground[c] = opts[hash32(seed, wx, wy, 70) % opts.size()]
			if blocked[q] == 1:
				ch.solid[c] = 1
			if road[q] == 1:
				var bits := _road_bits(road, i, j, wx, wy)
				var popts: Array = tiles.dirt_path[bits if bits != 0 else 10]
				ch.path[c] = popts[hash32(seed, wx, wy, 71) % popts.size()]
				continue
			# the strongest candidate of the cell's 3 x 3 gets it
			var mine: int = cand[q]
			if mine != 0:
				for dj in range(-1, 2):
					for di in range(-1, 2):
						var o := q + dj * AREA + di
						if o != q and cand[o] != 0 and (prio[o] < prio[q] or (prio[o] == prio[q] and o < q)):
							mine = 0
			if mine == 2 or mine == 4:
				ch.deco[c] = int(tiles.rock)
				if mine == 2:
					ch.solid[c] = 1
			elif mine == 1 or mine == 3:
				var kidx := _tree_kind(tree_kinds, fs[gk], fm[gk], wx, wy, mine == 3)
				ch.kind[c] = kidx
				ch.snow[c] = 2 if mine == 3 else (1 if fm[gk] > 600 else 0)
				ch.trees.append(wx)
				ch.trees.append(wy)
				ch.trees.append(kidx)
				if mine == 1:
					ch.solid[c] = 1
			elif blocked[q] == 0:
				var hd := hash32(seed, wx, wy, 80) & 1023
				var vd := _vdist(wx, wy)
				var fl_p := clampi((fl[gk] - 560) / 2, 0, 90)
				var bush_p := 8 + clampi((ff[gk] - 500) / 2, 0, 260)
				if vd > 2 and hd < fl_p:
					var fls: Array = tiles.flowers
					ch.deco[c] = fls[hash32(seed, wx, wy, 81) % fls.size()]
				elif vd > 2 and hd < fl_p + bush_p:
					var bs: Array = tiles.bushes
					ch.deco[c] = bs[hash32(seed, wx, wy, 82) % bs.size()]
	return ch


func _road_bits(road: PackedByteArray, i: int, j: int, wx: int, wy: int) -> int:
	var bits := 0
	if road[(j - 1) * AREA + i] == 1 or _gate_inner.has(Vector2i(wx, wy - 1)):
		bits |= 1
	if road[j * AREA + i + 1] == 1 or _gate_inner.has(Vector2i(wx + 1, wy)):
		bits |= 2
	if road[(j + 1) * AREA + i] == 1 or _gate_inner.has(Vector2i(wx, wy + 1)):
		bits |= 4
	if road[j * AREA + i - 1] == 1 or _gate_inner.has(Vector2i(wx - 1, wy)):
		bits |= 8
	return bits


## The tree kind for a cell: regions of leafy, autumn or conifer woods, conifers on the highlands.
func _tree_kind(kinds: Array, species: int, highland: int, wx: int, wy: int, mountain: bool) -> int:
	var group: Array
	if mountain or highland > 520 or species > 640:
		group = ["conifer", "conifer", "conifer", "mixed", "autumn"]
	elif species < 400:
		group = ["leafy", "leafy", "mixed", "leafy"]
	else:
		group = ["leafy", "autumn", "mixed", "autumn", "mixed", "leafy"]
	var want: String = group[hash32(seed, wx, wy, 90) % group.size()]
	var of_group := []
	for k in kinds.size():
		if kinds[k].group == want:
			of_group.append(k)
	return of_group[hash32(seed, wx, wy, 91) % of_group.size()]


# ---------------------------------------------------------------- queries --------------------
func _cell_of(chunk: Chunk, c: Vector2i) -> int:
	return (c.y - chunk.cy * CHUNK) * CHUNK + (c.x - chunk.cx * CHUNK)


func is_solid(c: Vector2i) -> bool:
	if village.has_point(c):
		return false
	var ch := get_chunk(chunk_of(c))
	var i := _cell_of(ch, c)
	if changes.has(c):
		var t: Dictionary = changes[c]
		Trees.sync(t, clock)
		if ch.kind[i] != NO_TREE or ch.solid[i] == 0:
			return Trees.solid(str(t.state))          # a felled, growing or planted tree: the stage says
	if ch.kind[i] != NO_TREE and ch.snow[i] != 2:
		if Trees.starts_mature(c.x, c.y):              # a generated tree: solid once its trunk has grown
			return true
		return Trees.solid(Trees.stage_at(clock - Trees.initial_born(c.x, c.y)))
	return ch.solid[i] != 0


func is_road(c: Vector2i) -> bool:
	if village.has_point(c):
		return false
	var ch := get_chunk(chunk_of(c))
	return ch.road[(c.y - ch.cy * CHUNK + PAD) * AREA + c.x - ch.cx * CHUNK + PAD] == 1


## The generated tree of a cell (a fresh record, state grown), or {}. Not the player's changes.
func base_tree(cell: Vector2i) -> Dictionary:
	if village.has_point(cell):
		return {}
	var ch := get_chunk(chunk_of(cell))
	var i := _cell_of(ch, cell)
	var k: int = ch.kind[i]
	if k == NO_TREE:
		return {}
	var kd: Dictionary = tiles.trees[k]
	var species := Trees.species_for(str(kd.group), cell.x, cell.y, ch.snow[i] > 0)
	var born := Trees.initial_born(cell.x, cell.y)
	return {"x": cell.x, "y": cell.y, "trunk": int(kd.trunk), "top": int(kd.top), "bottom": int(kd.bottom), "species": species,
			"state": Trees.stage_at(clock - born), "regrow": 0.0, "born": born, "ow": true}


## The tree standing on cell c (or whose canopy covers it) as a dictionary like the village's trees
## ({x, y, species, state, regrow, born}, plus ow: true), or {}. A tree the player changed is the one
## in `changes`, brought up to the clock, so mutating it (World.fell) is the change.
func tree_at(c: Vector2i) -> Dictionary:
	for cell in [c, c + Vector2i(0, 1)]:
		if village.has_point(cell):
			continue
		if changes.has(cell):
			var t: Dictionary = changes[cell]
			Trees.sync(t, clock)
			return t
		var b := base_tree(cell)
		if not b.is_empty():
			return b
	return {}


## Remember a tree the player changed (it is saved); a generated tree grown back is the base world again.
func note_tree(t: Dictionary) -> void:
	var cell := Vector2i(int(t.x), int(t.y))
	if t.state == "grown" and not t.get("planted", false):
		changes.erase(cell)
	else:
		changes[cell] = t


## Plant a sapling at a cell the caller has checked (plant_refusal): a new changed tree.
func plant(cell: Vector2i, species: String, now: float) -> Dictionary:
	var t := {"x": cell.x, "y": cell.y, "trunk": -1, "top": -1, "bottom": -1, "species": species, "state": "sapling",
			"regrow": 0.0, "born": now, "ow": true, "planted": true}
	changes[cell] = t
	return t


## Every tree of a chunk as the view draws it: the generated ones (as the player left them) and the
## ones the player planted. Mountain trees nobody can reach are included.
func chunk_trees(cc: Vector2i) -> Array:
	var ch := get_chunk(cc)
	var out := []
	for q in range(0, ch.trees.size(), 3):
		var cell := Vector2i(ch.trees[q], ch.trees[q + 1])
		var t: Dictionary = changes.get(cell, {})
		if t.is_empty():
			t = base_tree(cell)
		else:
			Trees.sync(t, clock)
		out.append(t)
	var cells: Array = changes.keys()
	cells.sort()
	for c: Vector2i in cells:
		if chunk_of(c) == cc and changes[c].get("planted", false):
			Trees.sync(changes[c], clock)
			out.append(changes[c])
	return out


## Why a sapling cannot be planted at a cell outside the village, "" if it can: open grass, not the
## road or a cliff, no rock, flower or bush, no tree or stump there and none beside it.
func plant_refusal(cell: Vector2i) -> String:
	if village.has_point(cell):
		return "not here"
	var ch := get_chunk(chunk_of(cell))
	var i := _cell_of(ch, cell)
	if is_road(cell):
		return "You cannot plant on the road."
	var flat := false
	for g in (tiles.cliff[0] as Array):              # the flat grass tiles (JSON numbers are floats)
		flat = flat or int(g) == ch.ground[i]
	if not flat or ch.solid[i] == 1 or ch.deco[i] >= 0:
		return "The ground here is not open grass."
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var n := cell + Vector2i(dx, dy)
			if village.has_point(n):
				return "That is too near the village."
			var near: Dictionary = changes.get(n, {})
			if not near.is_empty():
				if str(near.state) != "cleared":
					return "There is a tree here already." if (dx == 0 and dy == 0) else "Too close to another tree."
			elif not base_tree(n).is_empty():
				return "There is a tree here already." if (dx == 0 and dy == 0) else "Too close to another tree."
			if is_road(n):
				return "Too close to the road."
	return ""


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	var cells: Array = changes.keys()
	cells.sort()
	var list := []
	for c: Vector2i in cells:
		var t: Dictionary = changes[c]
		var e := {"x": c.x, "y": c.y, "state": str(t.state), "regrow": float(t.regrow), "born": Trees.born_of(t), "species": str(t.species)}
		if t.get("planted", false):
			e["planted"] = true
		list.append(e)
	return {"seed": seed, "gen": GEN_VERSION, "changes": list}


## Apply saved changes: the seed is set by the caller (create); a save from another generator
## version keeps the seed but cannot place its changes (the trees are not where they were).
func load_dict(d: Dictionary) -> void:
	changes.clear()
	if int(d.get("gen", GEN_VERSION)) != GEN_VERSION:
		return
	for e in d.get("changes", []):
		var cell := Vector2i(int(e.x), int(e.y))
		var t := {}
		if bool(e.get("planted", false)):
			t = {"x": cell.x, "y": cell.y, "trunk": -1, "top": -1, "bottom": -1, "ow": true, "planted": true}
		else:
			t = base_tree(cell)
			if t.is_empty():
				continue
		t.state = str(e.state)
		t.regrow = float(e.regrow)
		t.born = float(e.get("born", 0.0))
		t.species = str(e.get("species", t.get("species", "oak_summer")))
		changes[cell] = t
