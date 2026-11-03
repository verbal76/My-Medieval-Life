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
## Layout (GEN_VERSION 1, and 2: see GEN_COMPATIBLE):
##  - Value-noise fields (several octaves each) give forest density, a clearing mask, rockiness,
##    tree species and flower meadows. A ridge field masked by a regional field gives mountain
##    ranges: coherent ridge lines that come and go. Mountains are drawn with the free tileset's
##    grass/cliff wangset (a raised plateau with a rocky rim) and every cell touching a cliff corner
##    is solid. Mountain cells are cut by wobbling "pass" corridors on a coarse lattice, so open
##    ground is always connected: no range or ring of cliffs closes the world into pockets.
##    B14-07: a mountain's top (inside its rim) is ground but for its trees and boulders, out of reach until the
##    player cuts steps or builds stairs or a walkway through the rim (Terrain; `works`, saved, never undone). The
##    generated chunk data is unchanged (the top flag is extra), so older saves keep their changes.
##  - Roads are a global network: a node on a jittered grid (NODE tiles apart), each joined to some
##    neighbours by a bent 4-connected polyline that depends only on the two nodes. Every chunk
##    rasterises the segments that touch it, so roads cross chunk seams unbroken. The village's four
##    exits (VillageMap.exits) are joined to the nearest nodes. A road and one tile round it never
##    hold a cliff, tree or rock.
##  - Trees and rocks are single solid cells, never within a cell of each other or of a cliff, so
##    they cannot wall anything in. Flowers and bushes are walkable decoration.

const GEN_VERSION := 4
## Generator versions whose saved changes still apply (their trees, rocks, flowers and roads are in the same cells): 2 (PL1-12,
## 2026-10-21) only draws the low red flower (tile 2656) among the wild flowers (overworld_tiles.json flowers), so a flower
## may be another colour than in version 1, and nothing else moved.
## B25R1-Q3 (owner 2026-11-03): GEN_VERSION 4 adds streams (_streams_round, below). A world keeps the generation it was made
## with (`gen`, saved): a save of 1, 2 or 3 is drawn by generation 3 exactly as before, with no streams (its trees, rocks and
## changes stay where they were); a new world is generation 4.
const GEN_COMPATIBLE := [1, 2, 3, 4]
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
	var top := PackedByteArray()         # 1 on a mountain top (all four corners cliff: inside the rim). B14-07: ground but for its
	                                     # trees and boulders, reached only by the steps, stairs or walkways the player makes
	var water := PackedByteArray()       # B25R1-Q3 (generation 4): 1 a stream or pool (solid), 2 a bridge (a road over water), 3 a
	                                     # waterfall (solid), 4 a ford (stepping stones: walkable); 0 dry
	var last_use := 0

var seed := 1
var gen := GEN_VERSION                   # B25R1-Q3: the generation this world is drawn with (load_dict: a save keeps its own; 1-3 -> 3)
var _stream_cache := {}                  # stream lattice cell -> its stream (a pure function of the seed; not saved)
var village := Rect2i(0, 0, 120, 90)
var gates: Array = []                    # {out: Vector2i, dir: Vector2i}: where the village's roads leave
var tiles := {}                          # overworld_tiles.json
var changes := {}                        # Vector2i -> a tree the player changed (felled, growing, planted): {x, y, species, state, regrow, born, ow, planted?}
var plant_changes := {}                  # Vector2i -> the game day a picked wild flower outside the village is ripe again (saved; PL2-006)
var rock_changes := {}                   # Vector2i -> uses left of a boulder the player has worked on (0: broken up and gone); saved like `changes`
var works := {}                          # B14-07: Vector2i -> a cliff rim cell made passable (Terrain): "steps" (cut), "stairs" or
                                         # "walkway" (built), with "_ns" / "_ew" for the way it runs; saved like `changes`
var works_version := 0                   # bumped on each change of `works` (the view redraws them)
var road_state := {}                     # B25R1-011 (RoadWear): Vector2i -> {u, t, p, d, dd}, the cells worn, paved or damaged
                                         # other than the generator and the clock alone give; saved ("roads", optional)
var road_dirty := {}                     # cells whose look changed since the view last drew them (not saved)
var road_rev := 0                        # bumped on each such change
var recorder = null                      # B25R1-016: the World's flight recorder (WorldRecorder.attach), null when off; never saved, never read by the game
var clock := 0.0                         # the game minute (World keeps it): changed trees grow lazily by it
## REGION-NAV-01 (owner 2026-11-02, Build 25 scope; docs/region_nav/IMPLEMENTATION_PLAN.md AD-1): the five neighbouring
## settlements stand in the overworld. Each is a cleared site (settlements.json "site" w x h) centred on the settlement's own
## position (OffMapSettlement.pos: x tiles across, miles x tiles_per_mile south of the village's centre, the one geography the
## regional trade already measures distances by), kept clear like the village (no cliff within VILLAGE_CLEAR, objects thinning
## from OBJECT_MARGIN) and joined to the road network like a village gate (to its three nearest road nodes). GEN_VERSION 3:
## only the sites and their joining roads differ from generation 2.
var closed := {}                         # REGION-NAV-01 AD-4: road node (Vector2i) -> true: it cannot be passed (close_node); not saved
var closed_rev := 0
var sites: Array = []                    # {id, name, kind, center: Vector2i, rect: Rect2i, slots: [{trade, stamp, rect, door, spot}]}, in settlements.json order
var _solid_rows := {}                    # stamp name -> its "solid" rows (village.json), for the site buildings
var stamps := {}                         # the village's building stamps (village.json), which the view paints the site buildings with
var _near_sites: Array = []
var dropped_in_sites := 0              # REGION-NAV-01: planted trees of an older save dropped because a site now stands there              # the sites near the chunk being generated (_generate), for _vdist
var cache := {}                          # Vector2i -> Chunk
var generated := 0                       # chunks generated so far (tests: the cache bound, no work for loaded chunks)
var _use := 0
var _segments := {}                      # segment key -> PackedInt32Array of x, y cells
var _links: Array = []                   # the gates' road polylines: {a, b, key}
var _gate_inner := {}                    # village cells a gate road joins (they count as road for the tile drawn)
var _wob := {}                           # axis noise cache
var _trails: Array = []                  # gate_trails() cache (not saved: a function of the seed)


static func create(world_seed: int, m: VillageMap) -> Overworld:
	var o := Overworld.new()
	o.seed = world_seed
	o.village = Rect2i(0, 0, m.w, m.h)
	o.tiles = JSON.parse_string(FileAccess.get_file_as_string("res://data/overworld_tiles.json"))
	for e in m.exits():
		o.gates.append({"out": e.out, "dir": e.dir})
	o._setup_gates()
	o.stamps = m.data.stamps
	for k in m.data.stamps:
		o._solid_rows[k] = m.data.stamps[k].get("solid", [])
	o._setup_sites(m.data.stamps)
	return o


## REGION-NAV-01: the settlement sites and the roads that join them to the network (see `sites`).
func _setup_sites(stamps: Dictionary) -> void:
	sites.clear()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/settlements.json"))
	var lay: Dictionary = data.site
	var origin := village.get_center()
	var si := 0
	for spec in data.settlements:
		var center := origin + Vector2i(int(spec.get("x", 0)), int(spec.miles) * int(data.tiles_per_mile))
		var trades: Array = (spec.trades as Dictionary).keys()
		var bw := int(stamps.house.w)
		var bh := int(stamps.house.h)
		var cols := int(lay.cols)
		var rows := ceili(trades.size() / float(cols))
		var size := Vector2i(cols * bw + (cols - 1) * int(lay.gap) + 2 * int(lay.margin), rows * (bh + int(lay.lane)) + 2 * int(lay.margin))
		var rect := Rect2i(center - size / 2, size)
		var slots := []
		for k in trades.size():
			var t := str(trades[k])
			var stamp := str((lay.stamps as Dictionary).get(t, "house"))
			var at := rect.position + Vector2i(int(lay.margin) + (k % cols) * (bw + int(lay.gap)), int(lay.margin) + (k / cols) * (bh + int(lay.lane)))
			var door := at + Vector2i(int(stamps[stamp].door[0]), int(stamps[stamp].door[1]))
			slots.append({"trade": t, "stamp": stamp, "rect": Rect2i(at, Vector2i(int(stamps[stamp].w), int(stamps[stamp].h))),
				"door": door, "spot": door + Vector2i(0, 1)})
		var gate := Vector2i(center.x, rect.end.y - int(lay.margin) - int(lay.lane) / 2 - 1)    # the lane under the last row: the road comes in here
		var far := Vector2i(center.x, rect.end.y + 14)                                          # straight down out of the site, as a village gate's road
		sites.append({"id": str(spec.id), "name": str(spec.name), "kind": str(spec.kind), "center": center, "rect": rect, "slots": slots,
			"gate": gate})
		_links.append({"a": gate, "b": far, "key": 2000 + si * 8})
		var ci := fdiv(far.x, NODE)
		var cj := fdiv(far.y, NODE)
		var near: Array = []
		for j in range(cj - 3, cj + 4):
			for i in range(ci - 3, ci + 4):
				var p := node_pos(i, j)
				var bb := Rect2i(mini(p.x, far.x), mini(p.y, far.y), absi(p.x - far.x), absi(p.y - far.y))
				if not _node_excluded(p) and not bb.grow(4).intersects(rect):
					near.append([(p - far).length_squared(), i, j, p])
		near.sort()
		for k in mini(3, near.size()):
			_links.append({"a": far, "b": near[k][3], "key": 2000 + si * 8 + 1 + k})
		si += 1


## REGION-NAV-01: whether a site's building stands on cell `c` (its stamp's solid cells; a building is not entered).
func site_building_at(c: Vector2i) -> bool:
	var st := site_at(c)
	if st.is_empty():
		return false
	for sl in st.slots:
		var r: Rect2i = sl.rect
		if r.has_point(c):
			var rows: Array = _solid_rows.get(str(sl.stamp), [])
			var ry := c.y - r.position.y
			var rx := c.x - r.position.x
			return ry < rows.size() and rx < str(rows[ry]).length() and str(rows[ry])[rx] == "1"
	return false


## REGION-NAV-01 AD-4: a walking route along the roads from village gate `gate` (an index into `gates`) to settlement `sid`'s
## lane: the gate's road out to its nodes, the road network from node to node (Dijkstra over the same edges the chunks draw,
## lengths in cells, ties by node order, so the same seed always gives the same route), and the settlement's road in to its
## lane. Cells, 4-connected, from the gate's outside cell to the site's gate cell. Empty when no road joins them (a journey then
## fails and is recorded).
func road_route(gate: int, sid: String, honour_closed := true) -> PackedVector2Array:
	return route_between(_gate_end(gate), _site_end(sid), honour_closed)


## REGION-NAV-01 AD-4: a road node that cannot be passed (`shut`), or opened again. A route through it is blocked: route_between
## finds another way or none. Not saved; nothing in play closes a road yet (tests do), so `closed` is empty in a normal game.
## closed_rev counts the changes, so a traveller on the road plans the way ahead again when one happens (Journeys).
func close_node(nd: Vector2i, shut := true) -> void:
	if shut == closed.has(nd):
		return
	if shut:
		closed[nd] = true
	else:
		closed.erase(nd)
	closed_rev += 1


## REGION-NAV-01 Q3 (owner 2026-11-03: one geography): the road route between two ends, each a village gate or a settlement
## (_gate_end, _site_end: {base: the link from the end to its far point, nodes: road node -> the link from the far point to it}).
## The regional trade's distances and the couriers' days are these routes' lengths (Regions.route_table), so travel and trade
## measure the same roads.
func route_between(ea: Dictionary, eb: Dictionary, honour_closed := true) -> PackedVector2Array:
	var shut: Dictionary = closed if honour_closed else {}
	if ea.is_empty() or eb.is_empty() or (ea.nodes as Dictionary).is_empty() or (eb.nodes as Dictionary).is_empty():
		return PackedVector2Array()
	var all_pts: Array = []
	for e in [ea, eb]:
		all_pts.append(Vector2i(_links[int(e.base)].a))
	var lo := Vector2i(mini(fdiv(all_pts[0].x, NODE), fdiv(all_pts[1].x, NODE)) - 4, mini(fdiv(all_pts[0].y, NODE), fdiv(all_pts[1].y, NODE)) - 4)
	var hi := Vector2i(maxi(fdiv(all_pts[0].x, NODE), fdiv(all_pts[1].x, NODE)) + 4, maxi(fdiv(all_pts[0].y, NODE), fdiv(all_pts[1].y, NODE)) + 4)
	var starts: Dictionary = ea.nodes
	var ends: Dictionary = eb.nodes
	var dist := {}
	var prev := {}
	var open: Array = []                          # [cost, j, i]
	for nd: Vector2i in starts:
		if shut.has(nd):
			continue
		var li: int = starts[nd]
		var c0 := _segment(Vector3i(li, 0, -1), _links[li].a, _links[li].b, int(_links[li].key)).size() / 2
		if not dist.has(nd) or c0 < int(dist[nd]):
			dist[nd] = c0
			open.append([c0, nd.y, nd.x])
	var goal := Vector2i(1 << 30, 0)
	var GOAL := Vector2i(1 << 29, 1 << 29)          # the destination's far point: reached from an end node over its road in
	while not open.is_empty():
		open.sort()
		var top: Array = open.pop_front()
		var nd := Vector2i(int(top[2]), int(top[1]))
		if nd == GOAL:
			break                                          # the shortest way, the road in counted
		if int(top[0]) > int(dist.get(nd, 1 << 30)):
			continue
		if ends.has(nd) and not shut.has(nd):
			var lb0: int = ends[nd]
			var whole := int(top[0]) + _segment(Vector3i(lb0, 0, -1), _links[lb0].a, _links[lb0].b, int(_links[lb0].key)).size() / 2
			if whole < int(dist.get(GOAL, 1 << 30)):
				dist[GOAL] = whole
				goal = nd
				open.append([whole, GOAL.y, GOAL.x])
		for e in _node_edges(nd):
			var nb: Vector2i = e[0]
			if nb.x < lo.x or nb.y < lo.y or nb.x > hi.x or nb.y > hi.y or shut.has(nb):
				continue
			var cost := int(top[0]) + int(e[1])
			if cost < int(dist.get(nb, 1 << 30)):
				dist[nb] = cost
				prev[nb] = [nd, e[2]]
				open.append([cost, nb.y, nb.x])
	if goal.x == 1 << 30:
		return PackedVector2Array()
	var out := PackedVector2Array()
	var chain: Array = []
	var at := goal
	while prev.has(at):
		chain.push_front([prev[at][0], at, prev[at][1]])
		at = prev[at][0]
	var base_a: int = ea.base
	var la: int = starts[at]
	_append_cells(out, _segment(Vector3i(base_a, 0, -1), _links[base_a].a, _links[base_a].b, int(_links[base_a].key)), false)
	_append_cells(out, _segment(Vector3i(la, 0, -1), _links[la].a, _links[la].b, int(_links[la].key)), false)
	for step in chain:
		var seg: Array = step[2]                      # [i, j, k, forward]
		var a := node_pos(int(seg[0]), int(seg[1]))
		var ni: int = int(seg[0]) + [1, 0, 1, -1][int(seg[2])]
		var nj: int = int(seg[1]) + [0, 1, 1, 1][int(seg[2])]
		var cells := _segment(Vector3i(int(seg[0]), int(seg[1]), int(seg[2])), a, node_pos(ni, nj), (int(seg[0]) * 7919 + int(seg[1]) * 104729 + int(seg[2])) & 0xFFFFFF)
		_append_cells(out, cells, not bool(seg[3]))
	var lb: int = ends[goal]
	var base_b: int = eb.base
	_append_cells(out, _segment(Vector3i(lb, 0, -1), _links[lb].a, _links[lb].b, int(_links[lb].key)), true)
	_append_cells(out, _segment(Vector3i(base_b, 0, -1), _links[base_b].a, _links[base_b].b, int(_links[base_b].key)), true)
	return out


## The road end of village gate `gate`: its base link (out -> far) and its node links.
func _gate_end(gate: int) -> Dictionary:
	if gate < 0 or gate >= gates.size():
		return {}
	var base := -1
	var nodes := {}
	for li in _links.size():
		var key := int(_links[li].key)
		if key < 2000 and (key - 1000) / 8 == gate:
			if (key - 1000) % 8 == 0:
				base = li
			else:
				nodes[_node_of(_links[li].b)] = li
	return {} if base < 0 else {"base": base, "nodes": nodes}


## The road end of settlement `sid`: its base link (lane -> far below the site) and its node links.
func _site_end(sid: String) -> Dictionary:
	var st := site(sid)
	if st.is_empty():
		return {}
	var si := sites.find(st)
	var base := -1
	var nodes := {}
	for li in _links.size():
		var key := int(_links[li].key)
		if key >= 2000 and (key - 2000) / 8 == si:
			if (key - 2000) % 8 == 0:
				base = li
			else:
				nodes[_node_of(_links[li].b)] = li
	return {} if base < 0 else {"base": base, "nodes": nodes}


## REGION-NAV-01 Q3: the road route between two settlements (cells from a's lane to b's lane).
func site_route(a: String, b: String) -> PackedVector2Array:
	return route_between(_site_end(a), _site_end(b))


## The road node a node position belongs to (the grid cell whose jittered node it is).
func _node_of(p: Vector2i) -> Vector2i:
	var ci := fdiv(p.x, NODE)
	var cj := fdiv(p.y, NODE)
	for j in range(cj - 1, cj + 2):
		for i in range(ci - 1, ci + 2):
			if node_pos(i, j) == p:
				return Vector2i(i, j)
	return Vector2i(ci, cj)


## The roads leaving node `nd`: [[neighbour node, length in cells, [i, j, k, forward]]], by the same rule the chunks draw
## them (_road_mask): both ends outside the village's exclusion, the edge present, and its box clear of the village.
func _node_edges(nd: Vector2i) -> Array:
	var out := []
	var keep := Rect2i(village.grow(10))
	var a := node_pos(nd.x, nd.y)
	if _node_excluded(a):
		return out
	for k in 4:
		for dir in [1, -1]:
			var dx: int = [1, 0, 1, -1][k]
			var dy: int = [0, 1, 1, 1][k]
			var si: int = nd.x if dir == 1 else nd.x - dx
			var sj: int = nd.y if dir == 1 else nd.y - dy
			var ni: int = si + dx
			var nj: int = sj + dy
			var pa := node_pos(si, sj)
			var pb := node_pos(ni, nj)
			if _node_excluded(pa) or _node_excluded(pb) or not _edge(si, sj, k):
				continue
			var bb := Rect2i(mini(pa.x, pb.x), mini(pa.y, pb.y), absi(pa.x - pb.x), absi(pa.y - pb.y))
			if bb.intersects(keep) or _crosses_site(bb):
				continue
			var cells := _segment(Vector3i(si, sj, k), pa, pb, (si * 7919 + sj * 104729 + k) & 0xFFFFFF)
			out.append([Vector2i(ni, nj) if dir == 1 else Vector2i(si, sj), cells.size() / 2, [si, sj, k, dir == 1]])
	return out


func _append_cells(out: PackedVector2Array, cells: PackedInt32Array, reverse: bool) -> void:
	var n := cells.size() / 2
	for q in n:
		var idx := (n - 1 - q) if reverse else q
		var c := Vector2(cells[idx * 2], cells[idx * 2 + 1])
		if out.is_empty() or out[out.size() - 1] != c:
			out.append(c)


## REGION-NAV-01: the settlement site containing cell `c`, or {}.
func site_at(c: Vector2i) -> Dictionary:
	for st in sites:
		if (st.rect as Rect2i).has_point(c):
			return st
	return {}


## REGION-NAV-01: the site with this settlement id, or {}.
func site(id: String) -> Dictionary:
	for st in sites:
		if str(st.id) == id:
			return st
	return {}


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


# ---------------------------------------------------------------- streams (B25R1-Q3) --------
## GEN_VERSION 4 (owner decision B25R1-Q3, 2026-11-03: winding streams with grassy banks and rocks, waterfalls over cliff
## edges into pools, bridges where roads cross). Global features like the roads, so they cross chunk seams unbroken: a
## stream may rise in each STREAM_LATTICE cell (hash), on high ground only (the mountain field fm above STREAM_HIGH), and runs
## downhill on fm a STREAM_STEP at a time, holding its heading (it turns at most 60 degrees a step, the wobble hashed), until
## the ground rises on every side (a pool there) or STREAM_STEPS steps (a pool). Where it leaves the mountain mask (fm and fe
## as the cliffs use them) a pool opens below the drop; a rim cell it crosses heading south is a waterfall. It never comes
## within VILLAGE_CLEAR + 6 tiles of the village or a settlement (it ends there in a pool). Rasterised per chunk as water
## corners (the "overworld" corner set's river colour): a corner within the stream's width of its line (0.8 tiles at the
## source to 1.7, each bank corner pushed in or out by its hash) or inside a pool. A cell with 2 or more water corners is
## water (solid) unless a road runs on it (a bridge) or it lies at one of the stream's fords (every FORD_EVERY steps off the
## mountains: shallow water with stepping stones, walked across, so no stream ever walls a stretch of country off). Pure integer and float arithmetic of the seed; no global random.
const STREAM_LATTICE := 176
const STREAM_STEP := 6
const STREAM_STEPS := 48
const STREAM_HIGH := 540
const STREAM_REACH := STREAM_STEP * STREAM_STEPS + 12
const STREAM_KEEP_CLEAR := VILLAGE_CLEAR + 6
const FORD_EVERY := 4                     # steps between fords (about 24 tiles): open ground stays joined across every stream
const FORD_R := 2.7                       # tiles round a ford point its stepping stones cover (wider than the stream)
var _area_fords: Array = []               # the fords near the chunk being generated (_water_corners), for _water_cell


## One sample of _field at world corner (x, y): the same value noise, so a stream follows the ground the chunks draw.
func _point(salt: int, periods: Array, x: int, y: int) -> int:
	var acc := 0
	var total := 0
	for k in periods.size():
		var p: int = periods[k]
		var wgt := 1 << (periods.size() - 1 - k)
		total += wgt
		var lx := fdiv(x, p)
		var ly := fdiv(y, p)
		var xx := _smooth(((x - lx * p) * 256) / p)
		var yy := _smooth(((y - ly * p) * 256) / p)
		var v00 := hash32(seed, lx, ly, salt * 8 + k) & 1023
		var v10 := hash32(seed, lx + 1, ly, salt * 8 + k) & 1023
		var v01 := hash32(seed, lx, ly + 1, salt * 8 + k) & 1023
		var v11 := hash32(seed, lx + 1, ly + 1, salt * 8 + k) & 1023
		var top := v00 + (((v10 - v00) * xx) >> 8)
		var bot := v01 + (((v11 - v01) * xx) >> 8)
		acc += (top + (((bot - top) * yy) >> 8)) * wgt
	return acc / total


func _height(p: Vector2i) -> int:
	return _point(2, [320, 160], p.x, p.y)


## Whether the mountain mask holds at p (as the cliffs: fm high and fe near its middle; passes and roads not counted).
func _mountain(p: Vector2i) -> bool:
	var reach := (_height(p) - 470) / 4
	return reach > 0 and absi(_point(1, [128, 64, 32], p.x, p.y) - 512) < reach


func _kept_clear(p: Vector2i) -> bool:
	if _rdist(village, p.x, p.y) < STREAM_KEEP_CLEAR:
		return true
	for st in sites:
		if _rdist(st.rect, p.x, p.y) < STREAM_KEEP_CLEAR:
			return true
	return false


## The stream rising in lattice cell (i, j), or {}: {pts: Array[Vector2] (its line), r: Array[float] (width at each point),
## pools: [[Vector2 centre, radius]], falls: Array[Vector2i] (where it leaves the mountain), box: Rect2i}. Cached.
func stream_at(i: int, j: int) -> Dictionary:
	var key := Vector2i(i, j)
	if _stream_cache.has(key):
		return _stream_cache[key]
	var out := {}
	if hash32(seed, i, j, 110) % 100 < 70:
		# a spring: the first of six hashed places in the cell on a mountain, else the first on high ground
		var src := RegionRoads.NONE
		for t in 6:
			var p := Vector2i(i * STREAM_LATTICE + 20 + hash32(seed, i, j, 111 + 2 * t) % (STREAM_LATTICE - 40),
				j * STREAM_LATTICE + 20 + hash32(seed, i, j, 112 + 2 * t) % (STREAM_LATTICE - 40))
			if _kept_clear(p) or _height(p) < STREAM_HIGH:
				continue
			if _mountain(p):
				src = p
				break
			if src == RegionRoads.NONE:
				src = p
		if src != RegionRoads.NONE:
			out = _trace(src, i * 7919 + j * 104729)
	_stream_cache[key] = out
	return out


func _trace(src: Vector2i, key: int) -> Dictionary:
	var pts: Array = [Vector2(src)]
	var rs: Array = [0.8]
	var pools: Array = []
	var falls: Array = []
	var fords: Array = []
	var at := src
	var dirs: Array[Vector2] = []
	for a in 12:
		dirs.append(Vector2.RIGHT.rotated(a * PI / 6.0))
	# the first heading: the steepest way down
	var hd := 0
	var best := 1 << 30
	for a in 12:
		var h := _height(at + Vector2i((dirs[a] * STREAM_STEP).round()))
		if h < best:
			best = h
			hd = a
	var was_mountain := _mountain(at)
	for k in STREAM_STEPS:
		var here := _height(at)
		var pick := -1
		var score := 1 << 30
		var bend := roundi(1.6 * sin(float(k) * 0.7 + float(hash32(seed, key, 0, 119) % 628) / 100.0))     # it meanders
		for t in [-2, -1, 0, 1, 2]:
			var a := posmod(hd + t, 12)
			var to := at + Vector2i((dirs[a] * STREAM_STEP).round())
			var sc := _height(to) * 4 + absi(t - bend) * 14 + hash32(seed, key, k, 113 + t) % 12
			if sc < score:
				score = sc
				pick = a
		var nxt := at + Vector2i((dirs[pick] * STREAM_STEP).round())
		if _height(nxt) > here + 6 or _kept_clear(nxt):
			break                                          # the ground rises all round, or the village is near: a pool here
		# a little wobble off the straight line, half way
		var mid := (Vector2(at) + Vector2(nxt)) / 2.0 + dirs[posmod(pick + 3, 12)] * (float(hash32(seed, key, k, 120) % 400) / 100.0 - 2.0)
		pts.append(mid)
		rs.append(minf(1.7, 0.8 + float(k) * 0.04))
		pts.append(Vector2(nxt))
		rs.append(minf(1.7, 0.82 + float(k) * 0.04))
		var mtn := _mountain(nxt)
		if k % FORD_EVERY == FORD_EVERY / 2 and not mtn and not was_mountain:
			fords.append(Vector2(nxt))                     # a ford: stepping stones across, so no stream walls the country off
		if was_mountain and not mtn:
			falls.append(nxt)
			pools.append([Vector2(nxt) + dirs[pick] * 2.0, 2.4 + float(hash32(seed, key, k, 121) % 10) / 10.0])
		was_mountain = mtn
		at = nxt
		hd = pick
	if pts.size() < 3:
		return {}
	pools.append([pts[pts.size() - 1], 2.6 + float(hash32(seed, key, 0, 122) % 12) / 10.0])      # where it ends: a pool
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var box := Rect2i(Vector2i(lo.floor()) - Vector2i(6, 6), Vector2i((hi - lo).ceil()) + Vector2i(13, 13))
	return {"pts": pts, "r": rs, "pools": pools, "falls": falls, "fords": fords, "box": box}


## The streams whose water may reach `area` (tiles), in lattice order.
func streams_in(area: Rect2i) -> Array:
	var out := []
	if gen < 4:
		return out
	var grown := area.grow(STREAM_REACH)
	for j in range(fdiv(grown.position.y, STREAM_LATTICE), fdiv(grown.end.y, STREAM_LATTICE) + 1):
		for i in range(fdiv(grown.position.x, STREAM_LATTICE), fdiv(grown.end.x, STREAM_LATTICE) + 1):
			var st := stream_at(i, j)
			if not st.is_empty() and (st.box as Rect2i).intersects(area):
				out.append(st)
	return out


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	var t := 0.0 if l2 == 0.0 else clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## The water corners of the GRID x GRID corners at (ox + i, oy + j): 1 water.
func _water_corners(ox: int, oy: int) -> PackedByteArray:
	var wc := PackedByteArray()
	wc.resize(GRID * GRID)
	var area := Rect2i(ox, oy, GRID, GRID)
	_area_fords.clear()
	for st in streams_in(area):
		for f in st.fords:
			if Rect2(area).grow(FORD_R + 1.0).has_point(f):
				_area_fords.append(f)
		var pts: Array = st.pts
		var rs: Array = st.r
		for q in range(pts.size() - 1):
			var a: Vector2 = pts[q]
			var b: Vector2 = pts[q + 1]
			var r: float = maxf(float(rs[q]), float(rs[q + 1]))
			var lo := Vector2i((a.min(b) - Vector2(r + 1, r + 1)).floor()) - Vector2i(ox, oy)
			var hi := Vector2i((a.max(b) + Vector2(r + 1, r + 1)).ceil()) - Vector2i(ox, oy)
			for j in range(maxi(0, lo.y), mini(GRID, hi.y + 1)):
				for i in range(maxi(0, lo.x), mini(GRID, hi.x + 1)):
					var k := j * GRID + i
					if wc[k] == 1:
						continue
					var wx := ox + i
					var wy := oy + j
					var bank := float(hash32(seed, wx, wy, 130) % 100) / 200.0 - 0.25
					if _seg_dist(Vector2(wx, wy), a, b) <= r + bank and _vdist(wx, wy) >= VILLAGE_CLEAR:
						wc[k] = 1
		for pool in st.pools:
			var c: Vector2 = pool[0]
			var r2: float = pool[1]
			for j in range(maxi(0, int(floor(c.y - r2 - 1)) - oy), mini(GRID, int(ceil(c.y + r2 + 1)) - oy + 1)):
				for i in range(maxi(0, int(floor(c.x - r2 - 1)) - ox), mini(GRID, int(ceil(c.x + r2 + 1)) - ox + 1)):
					var wx := ox + i
					var wy := oy + j
					var bank := float(hash32(seed, wx, wy, 131) % 100) / 100.0 - 0.5
					if Vector2(wx, wy).distance_to(c) <= r2 + bank and _vdist(wx, wy) >= VILLAGE_CLEAR:
						wc[j * GRID + i] = 1
	return wc


# ---------------------------------------------------------------- roads ----------------------
func _node_excluded(p: Vector2i) -> bool:
	if village.grow(24).has_point(p):
		return true
	for st in sites:                              # REGION-NAV-01: no road node in or right by a settlement
		if (st.rect as Rect2i).grow(12).has_point(p):
			return true
	return false


## REGION-NAV-01: whether a network road's box crosses a settlement (it is dropped there, as round the village: a settlement's
## own roads join it to the network).
func _crosses_site(bb: Rect2i) -> bool:
	for st in sites:
		if bb.intersects((st.rect as Rect2i).grow(2)):
			return true
	return false


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


## WORLD-LIFE-01: the trails that lead to the village, each a list of road cells from a road node out in the country to the
## gate's outside cell (the village edge): {gate, cells: Array[Vector2i]}. Ordered by gate, then nearest node; a pure function
## of the seed. Ambient walkers (Countryside) follow them; nothing here changes the roads or the chunks.
func gate_trails() -> Array:
	if not _trails.is_empty():
		return _trails
	var base := -1
	for li in _links.size():
		var l: Dictionary = _links[li]
		if int(l.key) >= 2000:
			continue                              # REGION-NAV-01: a settlement site's road, not a village gate's trail
		var j := (int(l.key) - 1000) % 8
		if j == 0:
			base = li
			continue
		var far_node := _segment(Vector3i(li, 0, -1), l.a, l.b, int(l.key))
		var out_far: PackedInt32Array = _segment(Vector3i(base, 0, -1), _links[base].a, _links[base].b, int(_links[base].key))
		var cells: Array[Vector2i] = []
		for q in range(far_node.size() - 2, -1, -2):
			cells.append(Vector2i(far_node[q], far_node[q + 1]))
		for q in range(out_far.size() - 4, -1, -2):          # from the cell before `far` (it is the last of far_node) down to the gate
			cells.append(Vector2i(out_far[q], out_far[q + 1]))
		_trails.append({"gate": (int(l.key) - 1000) / 8, "cells": cells})
	return _trails


## The cells of a road segment, cached by `key`: a network edge's (i, j, k) with k 0..3, or a link's (link index, 0, -1).
## REGION-NAV-01: links were keyed (-1, link index, 0), the same key as the network edge leaving node (-1, link index) east,
## so whichever was cached first was drawn for both; links now have their own key space (k = -1).
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
				if bb.intersects(keep) or _crosses_site(bb):
					continue                          # a road never runs through the village or a settlement: their own roads join the network
				_stamp(mask, _segment(Vector3i(i, j, k), a, b, (i * 7919 + j * 104729 + k) & 0xFFFFFF), ox, oy)
	var li := 0
	for l in _links:
		var a2: Vector2i = l.a
		var b2: Vector2i = l.b
		var box2 := Rect2i(mini(a2.x, b2.x) - 12, mini(a2.y, b2.y) - 12, absi(a2.x - b2.x) + 24, absi(a2.y - b2.y) + 24)
		if box2.intersects(Rect2i(ox, oy, AREA, AREA)):
			_stamp(mask, _segment(Vector3i(li, 0, -1), a2, b2, int(l.key)), ox, oy)
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
	var d := _rdist(village, x, y)
	for st in _near_sites:                    # REGION-NAV-01: a settlement site is kept clear like the village
		d = mini(d, _rdist(st.rect, x, y))
	return d


func _rdist(r: Rect2i, x: int, y: int) -> int:
	var dx := maxi(maxi(r.position.x - x, x - (r.end.x - 1)), 0)
	var dy := maxi(maxi(r.position.y - y, y - (r.end.y - 1)), 0)
	return maxi(dx, dy)


func _generate(cx: int, cy: int) -> Chunk:
	generated += 1
	var ox := cx * CHUNK - PAD
	var oy := cy * CHUNK - PAD
	_near_sites.clear()
	var site_reach := Rect2i(ox, oy, AREA, AREA).grow(VILLAGE_CLEAR + OBJECT_RAMP + 2)
	for st in sites:
		if (st.rect as Rect2i).intersects(site_reach):
			_near_sites.append(st)
	var fe := _field(ox, oy, 1, [128, 64, 32])
	var fm := _field(ox, oy, 2, [320, 160])
	var ff := _field(ox, oy, 3, [96, 48, 24])
	var fc := _field(ox, oy, 4, [24, 12])
	var fr := _field(ox, oy, 5, [72, 36])
	var fs := _field(ox, oy, 6, [160, 80])
	var fl := _field(ox, oy, 7, [28, 14])
	var road := _road_mask(ox, oy)
	var wc := _water_corners(ox, oy) if gen >= 4 else PackedByteArray()      # B25R1-Q3: generation 4's streams
	var wn := PackedByteArray()                   # water corners per cell (0-4)
	wn.resize(AREA * AREA)
	if not wc.is_empty():
		for j in AREA:
			for i in AREA:
				var k := j * GRID + i
				wn[j * AREA + i] = wc[k] + wc[k + 1] + wc[k + GRID] + wc[k + GRID + 1]
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
			if wn[q] > 0 or wn[q - AREA] > 0:
				continue                                  # B25R1-Q3: no tree or rock in a stream or on its bank
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
	ch.top.resize(cells)
	ch.water.resize(cells)
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
			ch.top[c] = inner[q]
			var corners: int = cliff[gk] | (cliff[gk + 1] << 1) | (cliff[gk + GRID + 1] << 2) | (cliff[gk + GRID] << 3)
			var opts: Array = cliff_tiles[corners]
			ch.ground[c] = opts[hash32(seed, wx, wy, 70) % opts.size()]
			if blocked[q] == 1:
				ch.solid[c] = 1
			if wn[q] > 0:
				_water_cell(ch, c, q, gk, wc, wn, blocked[q] == 1 and inner[q] == 0, road[q] == 1, wx, wy)
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
			elif blocked[q] == 0 and wn[q] == 0:
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


## B25R1-Q3: a cell with water corners: its ground is the river tile for its corners (a rim cell a stream runs through, north
## to south, the waterfall; another wet rim cell its river tile, or its cliff where only a corner is wet), it is water when two or
## more corners are (solid), a bridge where a road runs on it, and now and then a rock stands in open water.
func _water_cell(ch: Chunk, c: int, q: int, gk: int, wc: PackedByteArray, wn: PackedByteArray, rim: bool, on_road: bool, wx: int, wy: int) -> void:
	var bits: int = wc[gk] | (wc[gk + 1] << 1) | (wc[gk + GRID + 1] << 2) | (wc[gk + GRID] << 3)
	if bits == 5:
		bits = 7                                       # the set has no diagonal pair: the nearest it has
	elif bits == 10:
		bits = 11
	var river: Array = tiles.water.river
	if rim:
		if wn[q] < 2:
			return                                     # a corner of the rim wet: the rock stays
		var falls: bool = wn[q - AREA] >= 2 and wn[q + AREA] >= 2
		ch.ground[c] = int(tiles.water.fall) if falls else int(river[bits][0]) if not (river[bits] as Array).is_empty() else int(river[15][0])
		ch.water[c] = 3 if falls else 1
		ch.solid[c] = 1
		return
	if not (river[bits] as Array).is_empty():
		ch.ground[c] = int(river[bits][0])
	if wn[q] >= 2:
		if on_road:
			ch.water[c] = 2                            # a bridge: the road runs on over the water
			ch.solid[c] = 0
		elif _area_fords.any(func(f: Vector2): return f.distance_to(Vector2(wx, wy) + Vector2(0.5, 0.5)) <= FORD_R):
			ch.water[c] = 4                            # a ford: shallow water and stepping stones, walked across
			ch.solid[c] = 0
			if wn[q] == 4:
				ch.ground[c] = int(tiles.water.ford)   # the stones in open water; its banks keep their own shape
		else:
			ch.water[c] = 1
			ch.solid[c] = 1
			if wn[q] == 4 and hash32(seed, wx, wy, 132) % 100 < 3:
				ch.deco[c] = int(tiles.rock)           # a rock in the water


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
	if site_building_at(c):
		return true                                    # REGION-NAV-01: a settlement's building
	if works.has(c):
		return false                                   # B14-07: steps, stairs or a walkway through the cliff's rim
	var ch := get_chunk(chunk_of(c))
	var i := _cell_of(ch, c)
	if ch.water[i] == 1 or ch.water[i] == 3:
		return true                                    # B25R1-Q3: a stream, a pool or a waterfall (a bridge is walked on)
	if changes.has(c):
		# a felled, growing or planted tree: its recorded stage says. A query never grows a tree:
		# World.sync_tree does (hourly, and on use), keeping a tree from turning solid under someone.
		var t: Dictionary = changes[c]
		if ch.kind[i] != NO_TREE or ch.solid[i] == 0:
			return Trees.solid(str(t.state))
	if ch.deco[i] == int(tiles.rock) and ch.solid[i] != 0 and rock_changes.get(c, 1) == 0:
		return false                                   # a boulder broken up: open ground
	if ch.kind[i] != NO_TREE and ch.snow[i] != 2:
		if Trees.starts_mature(c.x, c.y):              # a generated tree: solid once its trunk has grown
			return true
		return Trees.solid(Trees.stage_at(clock - Trees.initial_born(c.x, c.y)))
	if ch.top[i] == 1 and ch.kind[i] == NO_TREE and ch.deco[i] < 0:
		return false                                   # B14-07: a mountain top is ground once reached (its trees and boulders stand)
	return ch.solid[i] != 0


## B25R1-Q3: whether cell `c` is water: a stream, a pool, a waterfall or a ford (a ford is walked across; a bridge is a road,
## not water). Generation 3 worlds: never.
func is_water(c: Vector2i) -> bool:
	if gen < 4 or village.has_point(c):
		return false
	var ch := get_chunk(chunk_of(c))
	var w: int = ch.water[_cell_of(ch, c)]
	return w == 1 or w == 3 or w == 4


## B25R1-Q3: whether cell `c` is a ford (shallow water with stepping stones: walkable).
func is_ford(c: Vector2i) -> bool:
	if gen < 4 or village.has_point(c):
		return false
	var ch := get_chunk(chunk_of(c))
	return ch.water[_cell_of(ch, c)] == 4


## B25R1-Q3: whether cell `c` is a bridge (a road over a stream).
func is_bridge(c: Vector2i) -> bool:
	if gen < 4 or village.has_point(c):
		return false
	var ch := get_chunk(chunk_of(c))
	return ch.water[_cell_of(ch, c)] == 2


const NO_WATER := Vector2i(-1048576, -1048576)


## B25R1-Q3: the water cell nearest `c` within `radius` tiles (Chebyshev rings, then row and column order), or NO_WATER (a
## generation 3 world has no streams: wells are the fallback).
func nearest_water(c: Vector2i, radius: int) -> Vector2i:
	if gen < 4:
		return NO_WATER
	if is_water(c):
		return c
	for r in range(1, radius + 1):
		var best := NO_WATER
		var bd := INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var n := c + Vector2i(dx, dy)
				if is_water(n):
					var d := Vector2(dx, dy).length()
					if d < bd:
						bd = d
						best = n
		if best != NO_WATER:
			return best
	return NO_WATER


## B25R1-Q3: where to stand to drink: the open cell beside the water nearest `c` within `radius` (the bank), or NO_WATER.
func nearest_water_access(c: Vector2i, radius: int) -> Vector2i:
	var wtr := nearest_water(c, radius)
	if wtr == NO_WATER:
		return NO_WATER
	var best := NO_WATER
	var bd := INF
	for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var n: Vector2i = wtr + d
		if not is_solid(n) and not is_bridge(n) and Vector2(n).distance_to(Vector2(c)) < bd:
			bd = Vector2(n).distance_to(Vector2(c))
			best = n
	return best


## B14-07: whether a cell is on a mountain top (inside the cliff's rim).
func is_top(c: Vector2i) -> bool:
	if village.has_point(c):
		return false
	var ch := get_chunk(chunk_of(c))
	return ch.top[_cell_of(ch, c)] == 1


## B14-07: whether a cell is the cliff's rim itself (the rock face round a mountain top: never a tree, a rock or a road),
## not yet cut or built through.
func is_rim(c: Vector2i) -> bool:
	if village.has_point(c) or works.has(c):
		return false
	var ch := get_chunk(chunk_of(c))
	var i := _cell_of(ch, c)
	return ch.solid[i] == 1 and ch.top[i] == 0 and ch.kind[i] == NO_TREE and ch.deco[i] < 0 and not is_road(c)


## B14-07: a rim cell made passable (Terrain.build). Saved; never undone, so a way up is a way down (DVW-A10).
func note_work(c: Vector2i, kind: String) -> void:
	works[c] = kind
	works_version += 1


## The small grey boulder standing on a cell outside the village (a solid rock of the generator, not a
## cliff or a mountain's decoration): a record like a village deposit {x, y, ore: "stone", amount,
## boulder: true, ow: true}, `amount` the pickaxe uses left, or {} if there is none or it is broken up.
## The generated rock is fresh; the player's work on it is in `rock_changes`.
func boulder_at(c: Vector2i) -> Dictionary:
	if not has_boulder(c):
		return {}
	var left: int = rock_changes.get(c, ResourceNodes.boulder_uses(c))
	if left <= 0:
		return {}
	return {"x": c.x, "y": c.y, "ore": "stone", "amount": left, "boulder": true, "ow": true}


## Whether the generator stood a boulder on this cell (broken up or not).
func has_boulder(c: Vector2i) -> bool:
	if village.has_point(c):
		return false
	var ch := get_chunk(chunk_of(c))
	var i := _cell_of(ch, c)
	return ch.deco[i] == int(tiles.rock) and ch.kind[i] == NO_TREE          # a mountain's boulders too (PL2-006)


## The wild flower standing on a cell outside the village (any generated flower decoration), as a
## plant record like the village's {id, x, y, kind: "flower", tile, state, regrow, ow: true}; {} if none.
## Ripe unless the player picked it and its day has not come (plant_changes).
func flower_at(c: Vector2i) -> Dictionary:
	if village.has_point(c):
		return {}
	var ch := get_chunk(chunk_of(c))
	var v: int = ch.deco[_cell_of(ch, c)]
	if v < 0:
		return {}
	var is_flower := false
	for t in tiles.flowers:                      # (JSON numbers: compare as ints)
		if int(t) == v:
			is_flower = true
	if not is_flower:
		return {}
	var back: int = plant_changes.get(c, 0)
	var day := int(clock / 1440.0)
	return {"id": "ow_%d_%d" % [c.x, c.y], "x": c.x, "y": c.y, "kind": "flower", "tile": v,
			"state": "picked" if back > day else "ripe", "regrow": float(back), "ow": true}


## Whether the flower here is picked and not yet grown back (the view does not draw it).
func flower_gone(c: Vector2i) -> bool:
	return plant_changes.get(c, 0) > int(clock / 1440.0)


func note_flower(c: Vector2i, ripe_day: int) -> void:
	plant_changes[c] = ripe_day


## Whether the boulder here has been broken up (the view does not draw it again).
func rock_gone(c: Vector2i) -> bool:
	return rock_changes.get(c, 1) <= 0


## Remember the uses left of a boulder the player worked on (saved).
func note_rock(c: Vector2i, left: int) -> void:
	rock_changes[c] = left


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
	var species := Trees.species_for(str(kd.group), cell.x, cell.y, ch.snow[i] == 2)      # snow only on the mountain tops, not on green highland
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
	if is_top(cell) and str(t.state) != "grown":
		t.regrow = 1.0e15                              # DVW-A10: a mountain top's felled tree never grows back: no way across it closes
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
	if not flat or ch.solid[i] == 1 or (ch.deco[i] >= 0 and not rock_gone(cell)):
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
	var flowers := []
	var fcells: Array = plant_changes.keys()
	fcells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for c: Vector2i in fcells:
		flowers.append([c.x, c.y, int(plant_changes[c])])
	var rocks := []
	var rcells: Array = rock_changes.keys()
	rcells.sort()
	for c: Vector2i in rcells:
		rocks.append([c.x, c.y, int(rock_changes[c])])
	var wk := []
	var wcells: Array = works.keys()
	wcells.sort()
	for c: Vector2i in wcells:
		wk.append([c.x, c.y, str(works[c])])
	var out := {"seed": seed, "gen": gen, "changes": list, "rocks": rocks, "flowers": flowers, "works": wk}
	if not road_state.is_empty():
		out["roads"] = RoadWear.to_save(self)     # B25R1-011 (optional: an older save has none)
	return out


## Apply saved changes: the seed is set by the caller (create); a save from another generator
## version keeps the seed but cannot place its changes (the trees are not where they were).
func load_dict(d: Dictionary) -> void:
	changes.clear()
	rock_changes.clear()
	plant_changes.clear()
	works.clear()
	works_version += 1
	road_state.clear()
	var g := int(d.get("gen", GEN_VERSION))
	var keep := 3 if g < 4 else mini(g, GEN_VERSION)          # B25R1-Q3: a world keeps its generation (1-3 are drawn as 3)
	if keep != gen:
		gen = keep
		cache.clear()                                    # chunks drawn by another generation are dropped
		_stream_cache.clear()
	for f in d.get("flowers", []):
		plant_changes[Vector2i(int(f[0]), int(f[1]))] = int(f[2])
	if not int(d.get("gen", GEN_VERSION)) in GEN_COMPATIBLE:
		return
	for r in d.get("rocks", []):
		rock_changes[Vector2i(int(r[0]), int(r[1]))] = int(r[2])
	for r in d.get("works", []):                       # B14-07 (older saves have none)
		works[Vector2i(int(r[0]), int(r[1]))] = str(r[2])
	RoadWear.load_into(self, d.get("roads", []))      # B25R1-011 (older saves have none)
	for e in d.get("changes", []):
		var cell := Vector2i(int(e.x), int(e.y))
		var t := {}
		if bool(e.get("planted", false)):
			if int(d.get("gen", GEN_VERSION)) < 3 and not site_at(cell).is_empty():
				dropped_in_sites += 1             # REGION-NAV-01: a tree planted where a settlement now stands (a generation-2 save)
				continue
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
