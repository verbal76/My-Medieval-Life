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

const GEN_VERSION := 6
## Generator versions whose saved changes still apply (their trees, rocks, flowers and roads are in the same cells): 2 (PL1-12,
## 2026-10-21) only draws the low red flower (tile 2656) among the wild flowers (overworld_tiles.json flowers), so a flower
## may be another colour than in version 1, and nothing else moved.
## B25R1-018 / B25R1-Q5 (owner 2026-11-03: "Don't worry about saved games"): generation 4 lays the region out anew (the
## settlements at the region layout's anchors, the main roads along its routes, the Downs, the waste and the Wood Perilous as
## their own country; the water worker's courses), so an older generation's changes are not applied (the save is refused by
## SaveStore.MIN_VERSION before it gets here).
## Generation 5 (B25R1-018, the audit's "assessed, not started": Bear Hill and Higham's castle knoll): raised ground from the
## layout's `raised` landmarks (`raised`, `_raised_corner`): Bear Hill's top a rock-rimmed plateau of open turf round Bear Castle,
## climbed by the roads that cut through its rim; the white castle on a knoll above the town, its gate reached by steps cut in
## the knoll's rim (`fixed_works`). The chalk figures moved a little west, onto the hill's slope below the rim. Cells and objects
## on and round them changed, so a generation 4 world is refused like the older ones (World.load_dict, its message; the file kept).
## (It also covers B25R1-022's house styles: the southern settlements' styled houses and the elite houses change those sites'
## slots and stamps, which a generation 4 world's changes did not see.)
## Generation 6 (B25R1 flyover repair, 2026-11-05): the canonical water runs through and round the settlements, kept only off
## their built ground and bridged where it meets their streets (_water_clear, _setup_built); Coldlake and the Netherton stream
## laid round the settlements' houses (region_layout.json); a site's streets end where its roads come in (_trim_entries) and
## a street no building fronts is not laid (SitePlan._trim). Water, streets and so cells changed round every settlement, so a
## generation 5 world is refused like the older ones (owner B25R1-Q5: "Don't worry about saved games").
const GEN_COMPATIBLE := [6]
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
const VNODE := 1 << 20                   # B25R1-018: a route node's id is (VNODE + index, VNODE), apart from the grid nodes'
const ROUTE_KEY := 3000                  # link keys of the main routes and their joins (gates 1000+, sites 2000+)
const SITE_ROUTE_REACH := 110            # a site joins every main route passing this near (tiles)
const M := 0xFFFFFFFF
const SITE_PLAN := preload("res://scripts/core/site_plan.gd")   # B25R1-018: the organic settlement layout

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
	var flow := PackedByteArray()        # B25R1-017: the water's flow direction (1-8 E, SE, S, SW, W, NW, N, NE; 0 still; 9 foam)
	var level := PackedByteArray()       # B25R1-017: the water's level (its course's order: 1 stream, 2 river); 0 dry
	var bank := PackedByteArray()        # B25R1-017: a dry cell's height above the nearest water (tiles, 1-6), 0 water, 255 far
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
var structures: Array = []               # B25R1-018: the region's landmarks built in the country ({id, name, kind, rect, slots}), drawn as the sites' buildings
var _marks := {}                         # B25R1-018: cell corner -> true where chalk is cut into the turf (a hill figure, an earthwork's bank)
var _chalk_cells := {}                   # B25R1-018 (lead review: "the chalk figure reads as sand blobs"): cell -> true on a hill
                                         # figure's carved line, drawn with the chalk path tiles (region_props.png rows 1-2)
var _bank_cells := {}                    # cell -> true on Bear Castle's ring bank (Cozy Farm's rough turf, drawn as a 9-slice)
var _mark_zones: Array = []              # [Rect2i]: round them the turf is kept whole, so the cut chalk reads as the figure it is
var styles := {}                         # B25R1-022: house styles (style_stamps.json "styles": {style: {homes, elite}}), see slot_stamp
var wall_kit := {}                       # B25R1-018: the battlemented wall kit (region_stamps.json "wall"), composed into walls by _wall_stamp
var _near_sites: Array = []
## B25R1-018 (generation 5): raised ground ({id, kind "disc" (at, r) or "rect" (top: the top's cells), box: the corners' reach})
## and the ways the generator cuts through its rim ({Vector2i: "steps_ns" ...}, as `works` but never saved: a function of the
## seed and the layout). Both set by _setup_raised.
var raised: Array = []
var fixed_works := {}                    # (the knoll's steps from _setup_raised; a road's steps up a rim added as its chunk is generated)
## B25R1-010 (Homesteads): the houses and frames standing on homestead claims, {id, stamp ("house", or "" for a frame), rect,
## door, frame, tile} or, for a claim's pen and well being dug, {id, stamp "", rect, door, layers: [{cell: tile}], solid: {cell: true}}
## (Wilds.overworld_entries): collided here (home_building_at, as a settlement's building) and drawn by OverworldView. Set by
## Homesteads (from its saved claims, on load too); not saved here. homes_version counts the changes (the view redraws).
var homes: Array = []
var homes_version := 0
var dropped_in_sites := 0              # REGION-NAV-01: planted trees of an older save dropped because a site now stands there              # the sites near the chunk being generated (_generate), for _vdist
var cache := {}                          # Vector2i -> Chunk
var generated := 0                       # chunks generated so far (tests: the cache bound, no work for loaded chunks)
var _use := 0
var _segments := {}                      # segment key -> PackedInt32Array of x, y cells
var _links: Array = []                   # the gates' road polylines: {a, b, key}
var _gate_inner := {}                    # village cells a gate road joins (they count as road for the tile drawn)
var _wob := {}                           # axis noise cache
var _trails: Array = []                  # gate_trails() cache (not saved: a function of the seed)
## B25R1-018: the main routes (RegionGeo.routes): their control points are road nodes of their own ("route nodes"), joined in
## order by links, and joined to the sites, the village's gates and the nearest grid nodes. All a pure function of the seed.
var _vpos: Array[Vector2i] = []          # route node index -> position
var _vidx := {}                          # position -> route node index
var _vadj: Array = []                    # route node index -> [[neighbour node id (Vector2i), link index]]
var _junction := {}                      # grid node id -> [[route node id, link index]]
var _site_vlinks := {}                   # site index -> {node id: [link index, base link index]}
var _site_bases := {}                    # site index -> {side: base link index} (side 0 N, 1 E, 2 S, 3 W; S is the lane's base)
var _gate_vlinks := {}                   # gate index -> {node id: link index}
var route_kind := {}                     # link index -> the route's kind ("main", "dirt", "ancient", "side")


static func create(world_seed: int, m: VillageMap) -> Overworld:
	var o := Overworld.new()
	o.seed = world_seed
	water_cfg()                                   # B25R1-Q3: the water's tuning (game/data/water.json)
	o.village = Rect2i(0, 0, m.w, m.h)
	o.tiles = JSON.parse_string(FileAccess.get_file_as_string("res://data/overworld_tiles.json"))
	for e in m.exits():
		o.gates.append({"out": e.out, "dir": e.dir})
	o._setup_gates()
	o.stamps = (m.data.stamps as Dictionary).duplicate()   # (a copy: the sites add their civic stamps, the village's stay as they are)
	var civic = JSON.parse_string(FileAccess.get_file_as_string("res://data/region_stamps.json"))
	if civic is Dictionary:                          # B25R1-018: the civic buildings and the wall kit (tools/build_region_stamps.py)
		o.wall_kit = civic.get("wall", {})
		for k in (civic.get("stamps", {}) as Dictionary):
			o.stamps[k] = civic.stamps[k]
	var styled = JSON.parse_string(FileAccess.get_file_as_string("res://data/style_stamps.json")) if FileAccess.file_exists("res://data/style_stamps.json") else null
	if styled is Dictionary:                         # B25R1-022: Fantasy Lands houses fitted to the house footprints (tools/fl_houses.py)
		o.styles = styled.get("styles", {})
		for k in (styled.get("stamps", {}) as Dictionary):
			o.stamps[k] = styled.stamps[k]
	for k in o.stamps:
		o._solid_rows[k] = o.stamps[k].get("solid", [])
	o._setup_sites(o.stamps)
	o._setup_structures()
	o._setup_raised()
	o._setup_routes()
	o._trim_entries()
	o._setup_built()
	return o


## Generation 6 (B25R1 flyover repair): a site's street runs out to its edge on a side only where a road comes in by that side
## (its base link, _site_side); the other sides' ways in (the plan's entry_cells) are taken off its streets, so none ends in
## the grass at the site's edge (Wulstead's west and east lanes, the hamlets' north stubs, Higham's Way east and west).
func _trim_entries() -> void:
	for si in sites.size():
		var st: Dictionary = sites[si]
		var ec: Array = st.get("entry_cells", [])
		if ec.size() != 4:
			continue
		var bases: Dictionary = _site_bases.get(si, {})
		var gone := {}
		for side in 4:
			if side == 2 or bases.has(side):
				continue                                   # (the south side is the lane's own base: always a way in)
			for c: Vector2i in ec[side]:
				gone[c] = true
		if gone.is_empty():
			continue
		var kept_streets: Array = []
		for cells in st.streets:
			var kept: Array[Vector2i] = []
			for c: Vector2i in cells:
				if not gone.has(c):
					kept.append(c)
			if not kept.is_empty():
				kept_streets.append(kept)
		st.streets = kept_streets


## Generation 6 (B25R1 flyover repair; owner directive 2026-11-03 section 8, B25R1-017): the settlements' and the country
## landmarks' built ground, each building's and yard piece's rect grown by BUILT_CLEAR (and a walled town's whole walls):
## a canonical course runs through or round a settlement on any ground but this (_water_clear), so it is never erased where
## it crosses a settlement's cleared ground, and no building ever stands in the water.
const BUILT_CLEAR := 2
var _built := {}


func _setup_built() -> void:
	_built.clear()
	for st in sites + structures:
		for sl in st.slots + st.get("props", []):
			# (street furniture, a lamp or a signpost, keeps only its own cells: one at a street's edge where a course crosses
			# it would hold the water off both sides of the bridge)
			var small := str(sl.get("stamp", "")) in ["lamp", "signpost"]
			var r: Rect2i = (sl.rect as Rect2i).grow(0 if small else BUILT_CLEAR)
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					_built[Vector2i(x, y)] = true


## REGION-NAV-01: the settlement sites and the roads that join them to the network (see `sites`).
func _setup_sites(stamps: Dictionary) -> void:
	sites.clear()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/settlements.json"))
	var lay: Dictionary = data.site
	var origin := village.get_center()
	var si := 0
	for spec in data.settlements:
		var center := origin + Vector2i(int(spec.get("x", 0)), int(spec.miles) * int(data.tiles_per_mile))
		if RegionGeo.has_anchor(str(spec.id)):
			center = RegionGeo.anchor(str(spec.id))       # B25R1-018 (GEN_VERSION 4): the region layout's anchor
		var plan := _site_plan(spec, center, stamps, lay, si)
		var rect: Rect2i = plan.rect
		var slots: Array = plan.slots
		var gate: Vector2i = plan.gate
		var far := Vector2i(gate.x, rect.end.y + 14)                                            # straight down out of the site, as a village gate's road
		sites.append({"id": str(spec.id), "name": str(spec.name), "kind": str(spec.kind), "center": center, "rect": rect, "slots": slots,
			"gate": gate, "streets": plan.streets, "square": plan.square, "walled": bool(plan.get("walled", false)),
			"props": plan.get("props", []), "entries": plan.get("entries", []), "hamlet": bool(spec.get("hamlet", false)),
			"entry_cells": plan.get("entry_cells", [])})
		_links.append({"a": gate, "b": far, "key": 2000 + si * 8})
		si += 1
	for k0 in sites.size():                        # B25R1-018: joined to the grid once every site stands (a link never crosses another site)
		var far: Vector2i = Vector2i(sites[k0].gate.x, (sites[k0].rect as Rect2i).end.y + 14)
		var ci := fdiv(far.x, NODE)
		var cj := fdiv(far.y, NODE)
		var near: Array = []
		for j in range(cj - 3, cj + 4):
			for i in range(ci - 3, ci + 4):
				var p := node_pos(i, j)
				var bb := Rect2i(mini(p.x, far.x), mini(p.y, far.y), absi(p.x - far.x), absi(p.y - far.y))
				if not _node_excluded(p) and not bb.grow(4).intersects(sites[k0].rect) and not _crosses_site(bb):
					near.append([(p - far).length_squared(), i, j, p])
		near.sort()
		for k in mini(3, near.size()):
			_links.append({"a": far, "b": near[k][3], "key": 2000 + k0 * 8 + 1 + k})


## B25R1-018 phase 3: a settlement laid out along its streets. Every household of the founding has a home (a house stamp; slot
## {kind "home", hh: the household id, trade ""}), every business a building (its trade's stamp, as before: {kind "work",
## trade}), the officials their hall, and a few spare houses stand empty for the households formed later ({kind "home", hh -1}).
## Streets run east-west, the buildings on their north side with the doors opening onto them (the stamps' doors are at the
## bottom); a main street runs north-south through the middle, where the routes come in and go on, and the middle street opens
## into a square (the market). Rows differ in length and start, the gaps between houses vary: a pure function of the seed and
## the settlement, never a grid. Sizes from the layout's `plan` ({row: buildings a street, spare}; by kind otherwise).
func _site_plan(spec: Dictionary, center: Vector2i, stamps: Dictionary, lay: Dictionary, si: int) -> Dictionary:
	var plan: Dictionary = {}
	for s in RegionGeo.data().settlements:
		if str(s.id) == str(spec.id):
			plan = s.get("plan", {})
	var sp = SITE_PLAN.new()
	sp.ow = self
	return sp.plan_site(spec, center, stamps, lay, si, plan)

## B25R1-018 phase 3: a battlemented wall round a w x h rectangle, from the castle sample's kit (wall_kit, region_stamps.json):
## the walls along the north and south sides 9 rows deep (merlons, walkway, parapet, the stone face the street sees), those
## along the west and east sides 5 wide, running over the north wall and onto the south wall's walkway as the sample's do; a
## gate 7 wide in the north and south walls at each x of `gates_n` and `gates_s` (from the left edge), between two towers; a
## banner on the face every 12 tiles. Layers below0 (the wall) and below1 (the banners), every wall cell solid.
func _wall_stamp(w: int, h: int, gates_n: Array, gates_s: Array) -> Dictionary:
	var kh: Array = wall_kit.h
	var kv: Array = wall_kit.v
	var ke: Array = wall_kit.end
	var wall := PackedInt32Array()
	wall.resize(w * h)
	wall.fill(-1)
	var flag := PackedInt32Array()
	flag.resize(w * h)
	flag.fill(-1)
	var put := func(x: int, y: int, v: int) -> void:
		if x >= 0 and y >= 0 and x < w and y < h:
			wall[y * w + x] = v
	for north in [true, false]:
		var y0 := 0 if north else h - 9
		for r in 9:
			for x in w:
				put.call(x, y0 + r, int(kh[r][x % 8]))
		var gates: Array = gates_n if north else gates_s
		for gx in gates:
			for x in range(int(gx) - 3, int(gx) + 4):
				for r in 9:
					wall[(y0 + r) * w + clampi(x, 0, w - 1)] = -1
			for tx in [int(gx) - 8, int(gx) + 4]:           # the gate's towers: the side walls' pattern over the walkway
				for r in range(1 if north else 0, 4):
					for c in 5:
						put.call(tx + c, y0 + r, int(kv[(y0 + r) % 4][c]))
			for r in range(4, 9):
				put.call(int(gx) - 4, y0 + r, int(ke[r - 4]))
		for bx in range(6, w - 6, 12):
			var clear := true
			for gx in gates:
				clear = clear and absi(bx - int(gx)) > 6
			if clear:
				flag[(y0 + 4) * w + bx] = int(wall_kit.banner[0])
				flag[(y0 + 5) * w + bx] = int(wall_kit.banner[1])
	for x0 in [0, w - 5]:
		for y in range(1, h - 5):                  # down to the south wall's walkway; its parapet and face run on beneath
			for c in 5:
				put.call(x0 + c, y, int(kv[y % 4][c]))
	for r in range(4, 9):
		put.call(w - 1, h - 9 + r, int(ke[r - 4]))
		put.call(w - 6, r, int(ke[r - 4]))
	var solid: Array = []
	for y in h:
		var row := ""
		for x in w:
			row += "1" if wall[y * w + x] >= 0 else "0"
		solid.append(row)
	return {"w": w, "h": h, "door": [w / 2, h - 1], "layers": {"below0": Array(wall), "below1": Array(flag)}, "solid": solid}


## B25R1-018: the main routes of the region layout as road nodes and links (see _vpos), and their joins to the sites, the
## gates and the grid network. A route's control points give its course (the meander along the country: round Bear Hill, over
## the Downs by the Greenway, the straight causeway over Higham's meadows, BONE-C7-P003); each link between two is drawn with
## the network's own bent polyline. A site joins each route passing within SITE_ROUTE_REACH by a link from the side of the site
## facing it; a site no route passes near (a hamlet off in the country) gets a side road of its own to the nearest route node,
## bent through a few points of its own (_side_road). Order: the file's routes in order, then the sites, then the gates.
func _setup_routes() -> void:
	_vpos.clear()
	_vidx.clear()
	_vadj.clear()
	_junction.clear()
	_site_vlinks.clear()
	_site_bases.clear()
	_gate_vlinks.clear()
	route_kind.clear()
	var n := 0
	var through := {}                             # site index -> [route node indices that join it]: a route passing a settlement
	for r in RegionGeo.routes():
		var prev := -1
		var last_p := Vector2i.ZERO
		for p: Vector2i in r.points:
			var in_site := -1
			for si in sites.size():
				if (sites[si].rect as Rect2i).grow(6).has_point(p):
					in_site = si
			if in_site >= 0 and prev <= -2 and -2 - prev != in_site:
				# B25R1-018: straight from one settlement into the next (no point of the route between them): a node half way,
				# where both join, so the route is not broken between them
				var mid := (last_p + p) / 2
				var free := not bool(sites[-2 - prev].get("walled", false)) and not bool(sites[in_site].get("walled", false))
				for sj in sites.size():                # (a walled town is left by its gates: the way on is found round it)
					free = free and not (sites[sj].rect as Rect2i).grow(1).has_point(mid)
				if free:
					var mv := _vnode(mid)
					for s2 in [-2 - prev, in_site]:
						var tm: Array = through.get(s2, [])
						tm.append(mv)
						through[s2] = tm
			last_p = p
			if in_site >= 0:                          # the route goes into the settlement here and out again: it is split at it
				if prev >= 0:
					var t: Array = through.get(in_site, [])
					t.append(prev)
					through[in_site] = t
				prev = -2 - in_site
				continue
			var cur := _vnode(p)
			if prev >= 0:
				_route_link(prev, cur, str(r.kind))
			elif prev <= -2:
				var t2: Array = through.get(-2 - prev, [])
				t2.append(cur)
				through[-2 - prev] = t2
			prev = cur
	for si in through:
		for vi in through[si]:
			_site_join(si, vi, "main")
	var lone: Array = []                          # sites no main route passes near: a side road each, below
	for si in sites.size():
		var st: Dictionary = sites[si]
		var best := {}                            # route id -> [d2, node index]
		for r in RegionGeo.routes():
			var near := -1
			var nd := 1 << 40
			for p: Vector2i in r.points:
				if not _vidx.has(p):
					continue                          # a point inside a settlement (the route was split there)
				var d2 := (p - (st.center as Vector2i)).length_squared()
				if d2 < nd:
					nd = d2
					near = _vidx[p]
			if nd <= SITE_ROUTE_REACH * SITE_ROUTE_REACH:
				best[str(r.id)] = near
		var joined := {}
		for e in (_site_vlinks.get(si, {}) as Dictionary):
			joined[int(e.x) - VNODE] = true
		for rid in best:
			var vi: int = best[rid]
			if joined.has(vi):
				continue
			joined[vi] = true
			_site_join(si, vi, "main")
		if joined.is_empty():
			lone.append(si)
	# B25R1-018 (repair 2026-11-04): the side roads once every site the main routes reach is joined, so a hamlet's road may
	# join a neighbour's way in (its far point, a route node) rather than run past the neighbour to a node beyond it
	for si in lone:
		_side_road(si)
	for si in sites.size():
		_site_ring(si)
	for g in gates.size():
		var far: Vector2i = _links[_gate_base(g)].b
		var vi := _nearest_vnode(far)
		if vi >= 0 and (_vpos[vi] - far).length_squared() <= 160 * 160:
			var li := _links.size()
			_links.append({"a": far, "b": _vpos[vi], "key": ROUTE_KEY + li})
			route_kind[li] = "main"
			_gate_vlinks[g] = {_vid(vi): li}
			_vadj[vi].append([Vector2i(-1 - g, -1), li])   # (a gate end: route_between never walks into it from a node)
	# each route node joins the nearest grid node in reach, so the country trails meet the main roads; but not a route node
	# that is a layout crossing (a bridge's or ford's own point, at the water's edge): a trail from it would leave from the
	# bridge's end along the bank, beside the land road (seed 1, the fair bridge: from (-169,128), not the road at (-170,129))
	var crossing_at := {}
	for xg in (RegionGeo.data().get("crossings", []) as Array):
		crossing_at[Vector2i(int(xg.x), int(xg.y))] = true
	# generation 6 (B25R1 flyover: "parallel paths 1-3 tiles apart" by Fallowley and Ewedean, where every point of two ring roads
	# sent its own trail to the same grid node): a point that is only on a ring road sends none, and a grid node takes one trail,
	# from the nearest route node that would send one
	var best_of := {}                                   # grid node -> [d2, route node index]
	if gen >= 6:
		for vi in _vpos.size():
			var g6 := _trail_target(vi, crossing_at)
			if g6.is_empty():
				continue
			var cur: Array = best_of.get(g6[0], [])
			if cur.is_empty() or int(g6[1]) < int(cur[0]):
				best_of[g6[0]] = [int(g6[1]), vi]
	for vi in _vpos.size():
		var p: Vector2i = _vpos[vi]
		if crossing_at.has(p):
			continue
		if gen >= 6:
			var g6 := _trail_target(vi, crossing_at)
			if g6.is_empty() or int(best_of[g6[0]][1]) != vi:
				continue
		var ci := fdiv(p.x, NODE)
		var cj := fdiv(p.y, NODE)
		var near: Array = []
		for j in range(cj - 1, cj + 2):
			for i in range(ci - 1, ci + 2):
				var q := node_pos(i, j)
				if not _node_excluded(q) and (q - p).length_squared() <= 60 * 60 and not _crosses_site(Rect2i(mini(p.x, q.x), mini(p.y, q.y), absi(p.x - q.x), absi(p.y - q.y))):
					near.append([(q - p).length_squared(), j, i, q])
		if near.is_empty():
			continue
		near.sort()
		var gn := Vector2i(int(near[0][2]), int(near[0][1]))
		var li2 := _links.size()
		_links.append({"a": p, "b": near[0][3], "key": ROUTE_KEY + li2})
		route_kind[li2] = "trail"
		_vadj[vi].append([gn, li2])
		var js: Array = _junction.get(gn, [])
		js.append([_vid(vi), li2])
		_junction[gn] = js


## The grid node route node `vi` would send its country trail to and how far: [grid node, d2]; [] none (a crossing's own point,
## a point only on ring roads, no grid node in reach).
func _trail_target(vi: int, crossing_at: Dictionary) -> Array:
	var p: Vector2i = _vpos[vi]
	if crossing_at.has(p):
		return []
	var ring_only := not (_vadj[vi] as Array).is_empty()
	for e in _vadj[vi]:
		var li: int = int(e[1])
		ring_only = ring_only and str(route_kind.get(li if li >= 0 else -1 - li, "")) == "ring"
	if ring_only:
		return []
	var ci := fdiv(p.x, NODE)
	var cj := fdiv(p.y, NODE)
	var near: Array = []
	for j in range(cj - 1, cj + 2):
		for i in range(ci - 1, ci + 2):
			var q := node_pos(i, j)
			if not _node_excluded(q) and (q - p).length_squared() <= 60 * 60 and not _crosses_site(Rect2i(mini(p.x, q.x), mini(p.y, q.y), absi(p.x - q.x), absi(p.y - q.y))):
				near.append([(q - p).length_squared(), j, i, q])
	if near.is_empty():
		return []
	near.sort()
	return [Vector2i(int(near[0][2]), int(near[0][1])), int(near[0][0])]


func _vid(vi: int) -> Vector2i:
	return Vector2i(VNODE + vi, VNODE)


func _vnode(p: Vector2i) -> int:
	if not _vidx.has(p):
		_vidx[p] = _vpos.size()
		_vpos.append(p)
		_vadj.append([])
	return _vidx[p]


func _route_link(va: int, vb: int, kind: String) -> int:
	var li := _links.size()
	_links.append({"a": _vpos[va], "b": _vpos[vb], "key": ROUTE_KEY + li})
	route_kind[li] = kind
	_vadj[va].append([_vid(vb), li])
	_vadj[vb].append([_vid(va), -1 - li])       # walked from b to a: the link reversed
	return li


func _nearest_vnode(p: Vector2i) -> int:
	var best := -1
	var bd := 1 << 40
	for vi in _vpos.size():
		var d2 := (_vpos[vi] - p).length_squared()
		if d2 < bd:
			bd = d2
			best = vi
	return best


func _gate_base(g: int) -> int:
	for li in _links.size():
		if int(_links[li].key) == 1000 + g * 8:
			return li
	return -1


## The far point of site `si`'s side facing `toward` (its base link made on first use: side 2, south, is the lane's own base).
func _site_side(si: int, toward: Vector2i, force := -1) -> Array:
	var st: Dictionary = sites[si]
	var r: Rect2i = st.rect
	var side := _side_of(si, toward) if force < 0 else force
	var bases: Dictionary = _site_bases.get(si, {})
	if bases.is_empty():
		for li in _links.size():
			if int(_links[li].key) == 2000 + si * 8:
				bases[2] = li
		_site_bases[si] = bases
	if not bases.has(side):
		var gy: int = (st.gate as Vector2i).y           # the lane under the last row runs margin to margin: open at both ends
		var a: Vector2i = [Vector2i((st.center as Vector2i).x, r.position.y), Vector2i(r.end.x - 1, gy), Vector2i(st.gate),
			Vector2i(r.position.x, gy)][side]
		if (st.get("entries", []) as Array).size() == 4:
			a = st.entries[side]                      # B25R1-018: where the site's own streets reach its edge
		var dir: Vector2i = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][side]
		var far := a + dir * 13
		var li := _links.size()
		_links.append({"a": a, "b": far, "key": ROUTE_KEY + li})
		route_kind[li] = "site"
		bases[side] = li
	return [bases[side], Vector2i(_links[bases[side]].b)]


## Which side of site `si` (0 north, 1 east, 2 south, 3 west) a road toward `toward` leaves by (pure).
func _side_of(si: int, toward: Vector2i) -> int:
	var st: Dictionary = sites[si]
	var d := toward - (st.center as Vector2i)
	var side := 2
	if absi(d.x) > absi(d.y) * 2 and not bool(st.get("walled", false)):
		side = 1 if d.x > 0 else 3                     # (a walled town is entered by its north and south gates only)
	elif d.y < 0:
		side = 0
	if (st.get("entries", []) as Array).size() == 4:     # B25R1-018: a side whose road out would cross a settlement is passed over
		var order := [side, 0, 2, 1, 3] if not bool(st.get("walled", false)) else [side, 0, 2]
		for sd in order:
			var fp: Vector2i = st.entries[sd] + [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][sd] * 13
			var bb := Rect2i(mini(fp.x, toward.x), mini(fp.y, toward.y), absi(fp.x - toward.x) + 1, absi(fp.y - toward.y) + 1).grow(2)
			var hit := false
			for s2 in sites:
				hit = hit or bb.intersects(s2.rect)
			if not hit:
				side = sd
				break
	return side


## The far point _site_side would give for `toward`, without making its base link (the same side choice, the same point).
func _side_far(si: int, toward: Vector2i, force := -1) -> Vector2i:
	var st: Dictionary = sites[si]
	var r: Rect2i = st.rect
	var side := _side_of(si, toward) if force < 0 else force
	var bases: Dictionary = _site_bases.get(si, {})
	if bases.has(side):
		return Vector2i(_links[bases[side]].b)
	if bases.is_empty() and side == 2:
		for li in _links.size():
			if int(_links[li].key) == 2000 + si * 8:
				return Vector2i(_links[li].b)
	var gy: int = (st.gate as Vector2i).y
	var a: Vector2i = [Vector2i((st.center as Vector2i).x, r.position.y), Vector2i(r.end.x - 1, gy), Vector2i(st.gate), Vector2i(r.position.x, gy)][side]
	if (st.get("entries", []) as Array).size() == 4:
		a = st.entries[side]
	return a + [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][side] * 13


func _site_join(si: int, vi: int, kind: String, force := -1) -> void:
	var sb := _site_side(si, _vpos[vi], force)
	var li := _links.size()
	_links.append({"a": sb[1], "b": _vpos[vi], "key": ROUTE_KEY + li})
	route_kind[li] = kind
	var m: Dictionary = _site_vlinks.get(si, {})
	m[_vid(vi)] = [li, int(sb[0])]
	_site_vlinks[si] = m
	var fv := _vnode(sb[1])                            # the side's far point is a route node too: through traffic goes round the site
	_vadj[fv].append([_vid(vi), li])
	_vadj[vi].append([_vid(fv), -1 - li])


## B25R1-018: a road round site `si` joining the far points of its sides (and its four corners, 10 tiles out), so a route that
## comes to a settlement from one side goes on from another without walking through its buildings. Phase 3 lays the
## settlements' own streets along the routes; until then this is their way round.
const RING_STRETCH := 40.0


func _site_ring(si: int) -> void:
	var bases: Dictionary = _site_bases.get(si, {})
	if bases.size() < 2:
		return
	var r: Rect2i = (sites[si].rect as Rect2i).grow(13)
	var ring: Array[Vector2i] = []
	var corners := [r.position, Vector2i(r.end.x, r.position.y), r.end, Vector2i(r.position.x, r.end.y)]
	for side in 4:
		if bases.has(side):
			ring.append(Vector2i(_links[bases[side]].b))
		ring.append(corners[(side + 1) % 4] if side < 3 else corners[0])
	# generation 6: which legs run alongside a road or the water (_ring_leg_free), judged first; they are left out only while
	# the far points of the site's sides stay joined round the ring without them (else every leg is laid, as before)
	var skip := {}
	var fars := {}
	for side in 4:
		if bases.has(side):
			fars[ring.find(Vector2i(_links[bases[side]].b))] = true
	if gen >= 6:
		var li_base := _links.size()
		for k in ring.size():
			var a: Vector2i = ring[k]
			var b: Vector2i = ring[(k + 1) % ring.size()]
			if a == b:
				continue
			var parts := maxi(1, int(ceil((b - a).length() / RING_STRETCH)))
			var legs: Array[PackedInt32Array] = []
			for q in parts:
				legs.append(_polyline(a + (b - a) * q / parts, a + (b - a) * (q + 1) / parts, ROUTE_KEY + li_base + k * 8 + q))
			if not _ring_leg_free(legs):
				skip[k] = true
		if not skip.is_empty():
			# the ring cut at its skipped legs: the points from just after one skip round to the next are one group
			var n := ring.size()
			var start: int = (int(skip.keys().min()) + 1) % n
			var grp := {}
			var g := 0
			for t in n:
				var k := (start + t) % n
				grp[k] = g
				if skip.has(k):
					g += 1
			var groups := {}
			for k in fars:
				groups[grp[k]] = true
			if groups.size() > 1:
				skip.clear()
	for k in ring.size():
		var a: Vector2i = ring[k]
		var b: Vector2i = ring[(k + 1) % ring.size()]
		var bb := Rect2i(mini(a.x, b.x), mini(a.y, b.y), absi(a.x - b.x) + 1, absi(a.y - b.y) + 1).grow(2)
		var hit := false
		for sj in sites.size():                    # B25R1-018: not through a neighbouring settlement (they stand closer now)
			hit = hit or (sj != si and bb.intersects(sites[sj].rect))
		# (repair 2026-11-04) nor the cells the link would have, its wobble included: seed 7's ring round Higham passed the
		# box test 4 tiles from Garton and wobbled onto its houses
		if a == b or hit or skip.has(k):
			continue
		# (repair 2026-11-04) laid in stretches of at most RING_STRETCH tiles, so its wobble (a tenth of a stretch) stays near
		# the ring's line, and only when none of the cells it would have lies on a neighbour's ground: a long ring leg wobbled
		# up to 9 tiles, onto Garton's houses beside Higham on seed 7
		var parts := maxi(1, int(ceil((b - a).length() / RING_STRETCH)))
		var pts: Array[Vector2i] = []
		for q in parts + 1:
			pts.append(a + (b - a) * q / parts)
		var li0 := _links.size()
		var clear := true
		var legs: Array[PackedInt32Array] = []
		for q in parts:
			legs.append(_polyline(pts[q], pts[q + 1], ROUTE_KEY + li0 + q))
			clear = clear and not _cells_on_site(legs[q], si)
		if clear:
			for q in parts:
				_route_link(_vnode(pts[q]), _vnode(pts[q + 1]), "ring")
				_note_road_cells(legs[q])


## Generation 6 (B25R1 flyover: "parallel paths 1-3 tiles apart", rings drawn as straight frames beside the rivers): a ring leg
## is not laid where it would run alongside a road already laid (RING_BESIDE_ROAD of its cells within two tiles of one, its
## ends apart, where it joins) or alongside the canonical water (RING_BESIDE_WATER of its cells within four tiles of a course's
## edge: the water would be kept off it for that whole way). The rest of the ring still goes round; a side cut off from it is
## reached by its own road and the country trails.
const RING_BESIDE_ROAD := 10
const RING_BESIDE_WATER := 6
var _road_cells := {}                     # cells of the links laid so far (_setup_routes; the ring legs' test), not saved


func _note_road_cells(cells: PackedInt32Array) -> void:
	for q in range(0, cells.size(), 2):
		_road_cells[Vector2i(cells[q], cells[q + 1])] = true


func _ring_leg_free(legs: Array[PackedInt32Array]) -> bool:
	if _road_cells.is_empty():
		for l in _links:
			_note_road_cells(_polyline(l.a, l.b, int(l.key)))
	var n := 0
	for cells in legs:
		n += cells.size() / 2
	var k := 0
	var beside_road := 0
	var beside_water := 0
	for cells in legs:
		for q in range(0, cells.size(), 2):
			var c := Vector2i(cells[q], cells[q + 1])
			if k >= 6 and k < n - 6:
				var near := false
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						near = near or _road_cells.has(c + Vector2i(dx, dy))
				if near:
					beside_road += 1
			if _near_canon(Vector2(c) + Vector2(0.5, 0.5), 4.0):
				beside_water += 1
			k += 1
	return beside_road < RING_BESIDE_ROAD and beside_water < RING_BESIDE_WATER


## Whether point p lies within `extra` tiles of a canonical course's water (its line and width).
func _near_canon(p: Vector2, extra: float) -> bool:
	for cc in anchored_courses():
		if not Rect2(cc.box).grow(extra).has_point(p):
			continue
		var pts: Array = cc.pts
		for q in range(pts.size() - 1):
			if _seg_dist(p, pts[q], pts[q + 1]) <= maxf(float(cc.r[q]), float(cc.r[q + 1])) + extra:
				return true
	return false


## A hamlet's own road to the nearest route node: a few bent points between (each pushed sideways by the hash, up to a fifth
## of the way's length), every one a route node, so the way winds like a farm road rather than running ruler-straight.
## B25R1-018 (repair 2026-11-04): every settlement's ground is impassable to it. The nearest route node is taken whose way
## (the side's far point, the bent points, the node), widened by the most a road's wobble moves it (_polyline), keeps off
## every other settlement's rectangle and off this one's; the nearer nodes are tried first, so a hamlet whose nearest node is
## clear keeps the road it had. (Before, the straight way to the nearest node could run through a neighbour's houses: seed 1's
## road to Elmcote through Milton, seed 2's and seed 7's to Mileham through Brookhurst.)
const SIDE_TRIES := 24


func _side_road(si: int) -> void:
	var st: Dictionary = sites[si]
	var order: Array = []
	for vi in _vpos.size():
		order.append([(_vpos[vi] - (st.center as Vector2i)).length_squared(), vi])
	if order.is_empty():
		return
	order.sort()
	var pick: int = int(order[0][1])                  # (none clear in reach: the nearest, as before)
	var pts: Array = []
	var side := -1
	var walled := bool(st.get("walled", false))
	for k in mini(SIDE_TRIES, order.size()):
		var vi: int = int(order[k][1])
		# the side facing the node first, then the others (a side whose way out lies on a neighbour's ground is no way out)
		var first_side := _side_of(si, _vpos[vi])
		for sd in [first_side] + ([0, 2] if walled else [0, 1, 2, 3]):
			if sd == first_side and pts.size() > 0:
				break
			var cand := _side_points(si, vi, sd)
			if _side_clear(si, cand):
				pick = vi
				pts = cand
				side = sd
				break
		if not pts.is_empty():
			break
	if pts.is_empty():
		# no node in reach has a clear way: the nearest node whose way goes clear round one settlement's corner (14 tiles out,
		# as its ring road), the shortest such way first
		for k in mini(SIDE_TRIES, order.size()):
			var vi: int = int(order[k][1])
			var best: Array = []
			var bl := 1 << 30
			for sd in ([0, 2] if walled else [0, 1, 2, 3]):
				var far := _side_far(si, _vpos[vi], sd)
				for sj in sites.size():
					var g: Rect2i = (sites[sj].rect as Rect2i).grow(14)
					for cn: Vector2i in [g.position, Vector2i(g.end.x, g.position.y), g.end, Vector2i(g.position.x, g.end.y)]:
						var cand: Array = [far, cn, _vpos[vi]]
						var l := int((cn - far).length() + (_vpos[vi] - cn).length())
						if l < bl and _side_clear(si, cand):
							bl = l
							best = cand
							side = sd
			if not best.is_empty():
				pick = vi
				pts = best
				break
	if pts.is_empty():
		pts = _side_points(si, pick)
	var prev := -1
	var first := -1
	for k in range(1, pts.size() - 1):
		var cur := _vnode(pts[k])
		if prev >= 0:
			_route_link(prev, cur, "side")
		else:
			first = cur
		prev = cur
	if prev >= 0:
		_route_link(prev, pick, "side")
		_site_join(si, first, "side", side)
	else:
		_site_join(si, pick, "side", side)


## The way of site `si`'s side road to route node `vi`: the side's far point, the bent points, the node (pure: no link made).
func _side_points(si: int, vi: int, force := -1) -> Array:
	var from := _side_far(si, _vpos[vi], force)
	var to: Vector2i = _vpos[vi]
	var d := to - from
	var steps := clampi(int(d.length()) / 60, 1, 6)
	var out: Array = [from]
	for k in range(1, steps):
		var base := from + d * k / steps
		var off := ((hash32(seed, si, k, 905) % 2001) - 1000) * int(d.length()) / 5000
		var perp := Vector2i(-d.y, d.x)
		out.append(base + Vector2i(perp.x * off / maxi(1, int(d.length())), perp.y * off / maxi(1, int(d.length()))))
	out.append(to)
	return out


## Whether any of `cells` (x, y pairs) lies on a settlement's ground other than site `own`'s.
func _cells_on_site(cells: PackedInt32Array, own: int) -> bool:
	for sj in sites.size():
		if sj == own:
			continue
		var r: Rect2i = sites[sj].rect
		for q in range(0, cells.size(), 2):
			if r.has_point(Vector2i(cells[q], cells[q + 1])):
				return true
	return false


## Whether each leg of `pts`, widened by its wobble (_polyline's amplitude) and a tile, misses every settlement's rectangle.
func _side_clear(si: int, pts: Array) -> bool:
	for k in range(1, pts.size()):
		var a: Vector2i = pts[k - 1]
		var b: Vector2i = pts[k]
		var d := b - a
		var length := maxi(absi(d.x), absi(d.y)) + mini(absi(d.x), absi(d.y)) / 2
		var pad := mini(9, length / 10) + 1
		var n := maxi(1, maxi(absi(d.x), absi(d.y)))
		for sj in sites.size():
			var r: Rect2i = (sites[sj].rect as Rect2i).grow(pad if sj != si else 0)
			var box := Rect2i(mini(a.x, b.x), mini(a.y, b.y), absi(d.x) + 1, absi(d.y) + 1)
			if not box.intersects(r):
				continue
			for q in n + 1:
				if r.has_point(a + d * q / n):
					return false
	return true


## B25R1-022: the stamp a site slot is drawn with and whose cells are solid: its house style's stamp ("style", the same footprint,
## rect and door as its layout stamp) or the layout stamp itself.
static func slot_stamp(sl: Dictionary) -> String:
	var st := str(sl.get("style", ""))
	return st if st != "" else str(sl.stamp)


## REGION-NAV-01: whether a site's building stands on cell `c` (its stamp's solid cells; a building is not entered).
func site_building_at(c: Vector2i) -> bool:
	var st := site_at(c)
	if st.is_empty():
		return false
	for sl in st.slots + st.get("props", []):        # (any slot: a town's walls stand round its buildings, their rects overlap; the yards)
		var r: Rect2i = sl.rect
		if r.has_point(c):
			var rows: Array = _solid_rows.get(slot_stamp(sl), [])
			var ry := c.y - r.position.y
			var rx := c.x - r.position.x
			if ry < rows.size() and rx < str(rows[ry]).length() and str(rows[ry])[rx] == "1":
				return true
	return false


## B25R1-022 (owner: "roofs removable like our current ones for going inside"): the site building whose inside cell `c` is,
## {} none: a cell of a slot's rect that is open (not solid) and under the building's roof (an "above" tile of its stamp there),
## so the doorway and the rooms behind it. The view lifts that building's roof (OverworldView). Pure lookup, no state.
func site_inside_at(c: Vector2i) -> Dictionary:
	var st := site_at(c)
	if st.is_empty():
		return {}
	for sl in st.slots:
		var r: Rect2i = sl.rect
		if not r.has_point(c):
			continue
		var sn := slot_stamp(sl)
		var rows: Array = _solid_rows.get(sn, [])
		var ry := c.y - r.position.y
		var rx := c.x - r.position.x
		if ry >= rows.size() or rx >= str(rows[ry]).length() or str(rows[ry])[rx] != "0":
			continue
		var sd: Dictionary = stamps.get(sn, {})
		for ln in (sd.get("layers", {}) as Dictionary):
			if str(ln).begins_with("above") and int(sd.layers[ln][ry * int(sd.w) + rx]) >= 0:
				return sl
	return {}


## B25R1-018: whether cell `c` is a solid part of a landmark built in the country (structures).
func structure_at(c: Vector2i) -> bool:
	for st in structures:
		if (st.rect as Rect2i).has_point(c):
			for sl in st.slots:
				var r: Rect2i = sl.rect
				if r.has_point(c):
					var rows: Array = _solid_rows.get(str(sl.stamp), [])
					if str(rows[c.y - r.position.y])[c.x - r.position.x] == "1":
						return true
	return false


## B25R1-018 (owner directive 2026-11-03 section 3: "real world locations ... not merely labels on the map"): the landmarks of the
## region layout that stand in the country, built from its `object`: "structure" a building or the grave-mounds (a chapel, the
## seven barrows in a row on their low hill), "figure" chalk cut into the turf in the figure's shape (the tree and bears of
## Bear Hill's westward bent), "ring" the bank of an earthwork of the ancient folk (Bear Castle: a ring of chalk-scarred bank
## round the hill top, broken in places, BONE-C4-P005). No mechanics: they are places to find (Landmarks).
func _setup_structures() -> void:
	structures.clear()
	_marks.clear()
	_chalk_cells.clear()
	_bank_cells.clear()
	_mark_zones.clear()
	for lm in RegionGeo.landmarks():
		var at: Vector2i = lm.at
		match str(lm.object):
			"structure":
				var slots := []
				if str(lm.kind) == "barrows":
					for k in 7:                                # in a row along the hill, a little out of line
						var b := at + Vector2i(-21 + k * 6, (hash32(seed, at.x, k, 951) % 3) - 1)
						slots.append(_lm_slot("barrow", b, "%s_%d" % [lm.id, k]))
				else:
					var sd: Dictionary = stamps.church
					slots.append(_lm_slot("church", at - Vector2i(int(sd.w) / 2, int(sd.h) - 1), str(lm.id)))
				var rect: Rect2i = slots[0].rect
				for sl in slots:
					rect = rect.merge(sl.rect)
				structures.append({"id": str(lm.id), "name": str(lm.name), "kind": str(lm.kind), "rect": rect.grow(2), "slots": slots})
			"figure":
				var rows: Array = lm.figure
				var sc := maxi(1, int(lm.scale))
				var top := at - Vector2i(str(rows[0]).length() * sc / 2, rows.size() * sc / 2)
				_mark_zones.append(Rect2i(top, Vector2i(str(rows[0]).length() * sc, rows.size() * sc)).grow(6))
				for j in rows.size():                          # the figure's strokes, a white line cut into the whole turf
					for i in str(rows[j]).length():
						if str(rows[j])[i] == "X":
							for dy in sc:
								for dx in sc:
									_chalk_cells[top + Vector2i(i * sc + dx, j * sc + dy)] = true
			"ring":
				var r := maxi(4, int(lm.r))
				_mark_zones.append(Rect2i(at, Vector2i.ONE).grow(r + 6))
				for y in range(-r - 2, r + 3):                 # a bank three cells broad round the hill top (integer distance: the same
					for x in range(-r - 2, r + 3):             # on every machine), broken by four gaps where the ways went in
						var d2 := x * x + y * y
						if d2 < (r - 1) * (r - 1) or d2 > (r + 2) * (r + 2):
							continue
						var gapped := false
						for g in 4:
							var gd: Vector2i = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][g]
							var off := (hash32(seed, g, 0, 952) % 5) - 2
							if (x * gd.x + y * gd.y) > 0 and absi(x * gd.y - y * gd.x - off) <= 1:
								gapped = true
						if not gapped:
							_bank_cells[at + Vector2i(x, y)] = true


## B25R1-018 (generation 5; owner directive 2026-11-03 section 3, "Bear Hill ... Bear Castle", section 4, "white castle on its
## knoll"): the raised ground of the layout's landmarks that carry `raised`, drawn with the mountains' grass/cliff corners (a
## rock rim round a top of open turf, B14-07) but never covered with their pines and boulders:
##  - {"r": R}: a top about R tiles round the landmark (its outline wanders a tile or two with the seed), climbed by steps
##    where a road crosses the rim (_generate: every road over the hill is a way up, and runs on over the top);
##  - {"site": S, "slot": ID, "margin": [W, N, E, S]}: a top the size of settlement S's slot ID grown by those tiles on its
##    west, north, east and south (its corners rounded), with
##    steps cut through the rim below the slot's door, three wide, the one way up (fixed_works).
func _setup_raised() -> void:
	raised.clear()
	fixed_works.clear()
	if gen < 5:
		return
	for lm in RegionGeo.landmarks():
		var rz: Dictionary = lm.get("raised", {})
		if rz.is_empty():
			continue
		if rz.has("r"):
			var r := int(rz.r)
			var at: Vector2i = lm.at
			raised.append({"id": str(lm.id), "kind": "disc", "at": at, "r": r, "box": Rect2i(at, Vector2i.ONE).grow(r + 3)})
		elif rz.has("site"):
			var st := site(str(rz.site))
			for sl in st.get("slots", []):
				if str(sl.get("id", "")) != str(rz.slot):
					continue
				var mg: Array = rz.get("margin", [2, 2, 2, 2])          # west, north, east, south
				var top: Rect2i = (sl.rect as Rect2i).grow_individual(int(mg[0]), int(mg[1]), int(mg[2]), int(mg[3]))
				raised.append({"id": str(lm.id), "kind": "rect", "top": top, "box": top.grow(1)})
				var door: Vector2i = sl.door
				for dx in range(-1, 2):                  # the rim's south row (its corners the top's last row's lower ones)
					fixed_works[Vector2i(door.x + dx, top.end.y)] = "steps_ns"


## B25R1-018: whether the cell corner (x, y) (a cell's top-left corner) is on raised ground (_setup_raised).
func _raised_corner(x: int, y: int) -> bool:
	return _raised_id(x, y) != ""


## B25R1-018: the id of the raised ground (its landmark's) a cell stands on, its top or its rim, "" none. A settlement's site
## may reach onto it (Netherton lies under Bear Hill; Higham's castle stands on its knoll): its rim there is the hill's, not
## something the site was not cleared of.
func raised_at(c: Vector2i) -> String:
	for d: Vector2i in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var id := _raised_id(c.x + d.x, c.y + d.y)
		if id != "":
			return id
	return ""


func _raised_id(x: int, y: int) -> String:
	for rz in raised:
		if not (rz.box as Rect2i).has_point(Vector2i(x, y)):
			continue
		if str(rz.kind) == "disc":
			var d: Vector2i = Vector2i(x, y) - (rz.at as Vector2i)
			var rr: int = int(rz.r) * 8 + (_point(33, [12, 6], x, y) - 512) * 12 / 512     # eighths of a tile: +-1.5 tiles
			if (d.x * d.x + d.y * d.y) * 64 <= rr * rr:
				return str(rz.id)
		else:
			var t: Rect2i = rz.top
			if x < t.position.x or x > t.end.x or y < t.position.y or y > t.end.y:
				continue
			if (x == t.position.x or x == t.end.x) and (y == t.position.y or y == t.end.y):
				continue                                 # the corners rounded
			return str(rz.id)
	return ""


## B25R1-018: the way through a cliff's rim at `c`: one the player made (works) or one the generator cut (fixed_works), "" none.
func way_at(c: Vector2i) -> String:
	return str(works.get(c, fixed_works.get(c, "")))


func _lm_slot(stamp: String, at: Vector2i, id: String) -> Dictionary:
	var sd: Dictionary = stamps[stamp]
	var door := at + Vector2i(int(sd.door[0]), int(sd.door[1]))
	return {"kind": "civic", "trade": "", "stamp": stamp, "hh": -1, "rect": Rect2i(at, Vector2i(int(sd.w), int(sd.h))), "door": door,
		"spot": door + Vector2i(0, 1), "look": "", "id": id}


## B25R1-018: the landmarks of the region that stand in the world, as Landmarks places: [{id, kind, name, at}] (at: the door or
## foot of the thing itself). A landmark whose `object` is empty is not a world object yet and is left out.
func landmark_places() -> Array:
	var out := []
	for lm in RegionGeo.landmarks():
		var ob := str(lm.object)
		var at: Vector2i = lm.at
		if ob == "":
			continue
		if ob.begins_with("site:"):
			var parts := ob.substr(5).split("/")
			var st := site(parts[0])
			if st.is_empty():
				continue
			var found := false
			if parts[1] == "square" and (st.square as Rect2i).size.x > 0:
				at = (st.square as Rect2i).get_center()
				found = true
			for sl in st.slots:
				if str(sl.get("id", "")) == parts[1]:
					at = sl.spot
					found = true
					break
			if not found:
				continue
		elif ob == "structure":
			for s2 in structures:
				if str(s2.id) == str(lm.id):
					at = s2.slots[0].spot
		out.append({"id": "region:" + str(lm.id), "kind": str(lm.kind), "name": str(lm.name).capitalize() if str(lm.name).begins_with("the ") else str(lm.name), "at": at})
	return out


## B25R1-010: whether a homestead's house stands on cell `c`: its stamp's solid cells above its bottom row, the doorway open
## (World._built_collision's rule for a house built in the village, so the house is entered the same way).
func home_building_at(c: Vector2i) -> bool:
	for hm in homes:
		var r: Rect2i = hm.rect
		if not r.has_point(c):
			continue
		if hm.has("solid"):
			if (hm.solid as Dictionary).has(c):
				return true                            # B25R1-014: a claim pen's fence (Wilds.overworld_entries)
			continue
		if str(hm.stamp) == "":
			continue
		var ry := c.y - r.position.y
		if ry >= r.size.y - 1 or c == Vector2i(hm.door) - Vector2i(0, 1):
			return false
		var rows: Array = _solid_rows.get(str(hm.stamp), [])
		var rx := c.x - r.position.x
		return ry >= rows.size() or (rx < str(rows[ry]).length() and str(rows[ry])[rx] == "1")
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
	# B25R1-018: one road between two places, the same both ways: the search always runs from the end with the lower base link
	# and the cells are reversed for the other direction (the search seeds its start nodes without the area bound its ends
	# are reached under, so the two directions could find different ways)
	if not ea.is_empty() and not eb.is_empty() and int(ea.base) > int(eb.base):
		var back := _route_search(eb, ea, honour_closed)
		back.reverse()
		return back
	return _route_search(ea, eb, honour_closed)


func _route_search(ea: Dictionary, eb: Dictionary, honour_closed: bool) -> PackedVector2Array:
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
		var c0 := _seg_len(li) + _seg_len(int((ea.get("base_of", {}) as Dictionary).get(nd, ea.base)))
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
			var whole := int(top[0]) + _seg_len(lb0) + _seg_len(int((eb.get("base_of", {}) as Dictionary).get(nd, eb.base)))
			if whole < int(dist.get(GOAL, 1 << 30)):
				dist[GOAL] = whole
				goal = nd
				open.append([whole, GOAL.y, GOAL.x])
		for e in _node_edges(nd):
			var nb: Vector2i = e[0]
			if (nb.x < VNODE and (nb.x < lo.x or nb.y < lo.y or nb.x > hi.x or nb.y > hi.y)) or shut.has(nb):
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
	var base_a: int = int((ea.get("base_of", {}) as Dictionary).get(at, ea.base))
	var la: int = starts[at]
	_append_cells(out, _segment(Vector3i(base_a, 0, -1), _links[base_a].a, _links[base_a].b, int(_links[base_a].key)), false)
	if la >= 0:
		_append_cells(out, _segment(Vector3i(la, 0, -1), _links[la].a, _links[la].b, int(_links[la].key)), false)
	for step in chain:
		var seg: Array = step[2]                      # [i, j, k, forward], or ["L", link, forward] (B25R1-018: a route link)
		if seg[0] is String:
			var l: Dictionary = _links[int(seg[1])]
			_append_cells(out, _segment(Vector3i(int(seg[1]), 0, -1), l.a, l.b, int(l.key)), not bool(seg[2]))
			continue
		var a := node_pos(int(seg[0]), int(seg[1]))
		var ni: int = int(seg[0]) + [1, 0, 1, -1][int(seg[2])]
		var nj: int = int(seg[1]) + [0, 1, 1, 1][int(seg[2])]
		var cells := _segment(Vector3i(int(seg[0]), int(seg[1]), int(seg[2])), a, node_pos(ni, nj), (int(seg[0]) * 7919 + int(seg[1]) * 104729 + int(seg[2])) & 0xFFFFFF)
		_append_cells(out, cells, not bool(seg[3]))
	var lb: int = ends[goal]
	var base_b: int = int((eb.get("base_of", {}) as Dictionary).get(goal, eb.base))
	if lb >= 0:
		_append_cells(out, _segment(Vector3i(lb, 0, -1), _links[lb].a, _links[lb].b, int(_links[lb].key)), true)
	_append_cells(out, _segment(Vector3i(base_b, 0, -1), _links[base_b].a, _links[base_b].b, int(_links[base_b].key)), true)
	return out


func _seg_len(li: int) -> int:
	if li < 0:
		return 0                                      # a site side's own far point: no link beyond its base
	return _segment(Vector3i(li, 0, -1), _links[li].a, _links[li].b, int(_links[li].key)).size() / 2


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
	for nd in _gate_vlinks.get(gate, {}):           # B25R1-018: the main route the gate's road joins
		nodes[nd] = _gate_vlinks[gate][nd]
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
	var base_of := {}                               # B25R1-018: a route joined from another side of the site leaves by that side
	var vl: Dictionary = _site_vlinks.get(si, {})
	for nd in vl:
		nodes[nd] = int(vl[nd][0])
		base_of[nd] = int(vl[nd][1])
	for side in (_site_bases.get(si, {}) as Dictionary):  # each side's far point is a route node: a way in from there needs only the base
		var bl: int = _site_bases[si][side]
		var fp: Vector2i = _links[bl].b
		if _vidx.has(fp):
			nodes[_vid(int(_vidx[fp]))] = -1
			base_of[_vid(int(_vidx[fp]))] = bl
	return {} if base < 0 else {"base": base, "nodes": nodes, "base_of": base_of}


## B25R1-018: the cells where roads enter settlement `sid`: the lane gate and each side's way in (a route arriving from
## another side ends there).
func site_entries(sid: String) -> Array:
	var st := site(sid)
	if st.is_empty():
		return []
	var out := [Vector2i(st.gate)]
	for side in (_site_bases.get(sites.find(st), {}) as Dictionary):
		var c: Vector2i = _links[_site_bases[sites.find(st)][side]].a
		if not out.has(c):
			out.append(c)
	return out


## REGION-NAV-01 Q3: the road route between two settlements (cells from a's lane to b's lane).
func site_route(a: String, b: String) -> PackedVector2Array:
	return route_between(_site_end(a), _site_end(b))


## The road node a node position belongs to (the grid cell whose jittered node it is).
func _node_of(p: Vector2i) -> Vector2i:
	if _vidx.has(p):
		return _vid(int(_vidx[p]))
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
	if nd.x >= VNODE:                                 # B25R1-018: a route node: its links
		for e in _vadj[nd.x - VNODE]:
			var nb: Vector2i = e[0]
			if nb.x < 0:
				continue                              # a site's or gate's join: only ever its own end
			var li: int = int(e[1])
			var fwd := li >= 0
			var lx := li if fwd else -1 - li
			out.append([nb, _seg_len(lx), ["L", lx, fwd]])
		return out
	for e in _junction.get(nd, []):                   # the route nodes joined to this grid node (link: route node -> grid node)
		out.append([e[0], _seg_len(int(e[1])), ["L", int(e[1]), false]])
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
			if _node_excluded(pa) or _node_excluded(pb) or not _edge_live(si, sj, k):
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


# ---------------------------------------------------------------- water (B25R1-Q3, B25R1-017) --------
## GEN_VERSION 4 (owner decision B25R1-Q3 and directive B25R1-017, 2026-11-03: winding streams and rivers with grassy banks,
## rocks and shallows, flowing water, waterfalls at real drops into pools, bridges where routes cross; docs/design/WATER.md).
## Global features like the roads, so they cross chunk seams unbroken, each a COURSE (river_at, stream_at): a line of points in
## downstream order with a width at each, its pools, falls and fords, an order (1 stream, 2 river) and the course it joins.
##  - Rivers (order 2): one may rise in each RIVER_LATTICE cell (hash), on high ground (the mountain field fm above
##    STREAM_HIGH), and runs RIVER_STEPS steps, 1.6 tiles wide at its spring widening to 3.4, ending in a lake.
##  - Streams (order 1): one may rise in each STREAM_LATTICE cell, at a spring on the mountains (the cliffs' mask) or else on
##    high ground, up to STREAM_STEPS steps, 0.8 to 1.7 wide; a stream that reaches a river ends in it (it joins: a network).
##  - Both run downhill on fm a STREAM_STEP at a time, turning at most 60 degrees a step and meandering (hashed), and end in a
##    pool where the ground rises all round; where one leaves the mountains a foaming pool opens below the drop; a cliff rim
##    cell it runs through north to south is a waterfall (only there: a genuine drop). None comes within STREAM_KEEP_CLEAR tiles
##    of the village or a settlement. Every FORD_EVERY steps off the mountains a ford: shallow water with stepping stones,
##    walked across, so no course walls a stretch of country off.
## Rasterised per chunk as water corners (the "overworld" corner set's river colour): a corner within a course's width of its
## line (each bank corner pushed in or out by its hash) or inside a pool. A cell with 2 or more water corners is water (solid)
## unless a road runs on it (a bridge) or a ford. Each water cell keeps its course's flow direction (the downstream heading,
## one of eight; 0 still in pools, 9 foaming under a fall), its level (the course's order) and each dry cell near water its
## bank height (tiles above the water's edge, the floodplain): the data a later rain and flood system changes through the
## hooks set_level / on_level_changed / seasonal_flow (water_level reads them; nothing changes them now). Pure integer and
## float arithmetic of the seed; no global random; a chunk never depends on the order chunks are made in.
## The tuning (EA-01: one place per decision) is game/data/water.json, read once into these (water_cfg).
static var W: Dictionary = {}
static var STREAM_LATTICE := 176
static var STREAM_STEP := 6
static var STREAM_STEPS := 48
static var STREAM_HIGH := 540
static var RIVER_LATTICE := 352
static var RIVER_STEPS := 110
static var RIVER_HIGH := 500
static var RIVER_REACH := 6 * 110 + 16
static var STREAM_REACH := RIVER_REACH
static var STREAM_KEEP_CLEAR := VILLAGE_CLEAR + 6
static var FORD_EVERY := 4                # steps between fords (about 24 tiles): open ground stays joined across every course
static var FORD_R := 2.7                  # tiles round a ford point its stepping stones cover on a stream (a river's: its width + 1)
static var BANK_REACH := 6                # tiles beyond a course's edge whose bank height is kept (the floodplain)


## game/data/water.json into the tuning above (once).
static func water_cfg() -> Dictionary:
	if not W.is_empty():
		return W
	W = JSON.parse_string(FileAccess.get_file_as_string("res://data/water.json"))
	STREAM_STEP = int(W.step)
	STREAM_LATTICE = int(W.stream.lattice)
	STREAM_STEPS = int(W.stream.steps)
	STREAM_HIGH = int(W.stream.high)
	RIVER_LATTICE = int(W.river.lattice)
	RIVER_STEPS = int(W.river.steps)
	RIVER_HIGH = int(W.river.high)
	RIVER_REACH = STREAM_STEP * RIVER_STEPS + 16
	STREAM_REACH = RIVER_REACH
	STREAM_KEEP_CLEAR = VILLAGE_CLEAR + int(W.keep_clear_extra)
	FORD_EVERY = int(W.ford_every_steps)
	FORD_R = float(W.ford_radius)
	BANK_REACH = int(W.bank_reach)
	return W
const FLOW_STILL := 0
const FLOW_FOAM := 9
var _wc_order := PackedByteArray()          # the course order per corner of the chunk being generated (_is_fall)
var _ford_ok := {}                           # ford point -> no road within FORD_BRIDGE_CLEAR of it (_ford_clear)
var _area_fords: Array = []               # [point, radius, along] of the fords near the chunk being generated (_water_corners)
var _river_cache := {}                    # river lattice cell -> its course (a pure function of the seed; not saved)
var _anchored: Array = []                 # B25R1-018: the canonical courses (anchored_courses), traced once
var _anchored_done := false
var _forced: Array = []                   # B25R1-018: [centre, radius, kind (bridge, stone_bridge, ford)] the canonical crossings
var _downs := Rect2i()                    # B25R1-018: the waterless Downs (no stream rises or runs there): its bounding rect
var _downs_poly := PackedVector2Array()   # and its outline (the layout's polygon), when given
## Weather hooks (B25R1-017; docs/design/WATER.md). Nothing sets them in Build 25 Revision 1: the water is constant.
var seasonal_flow := 1.0                  # a factor on every course's flow and level (seasons: a later system sets it)
var level_override := {}                  # Vector2i -> a water level set by set_level (rain, flood); not saved yet
var on_level_changed: Callable            # called (cell, old level, new level) by set_level


## One sample of _field at world corner (x, y): the same value noise, so a course follows the ground the chunks draw.
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


## The ground's height at p (the mountain field): courses run down it.
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


## B25R1-018 (owner directive 2026-11-03, the regional world reconstruction, section 8): the canonical water. The region
## layout (game/data/region_layout.json, format mml-region-layout/1, the region workstream's) gives, in absolute overworld
## tiles of the village frame:
##  - rivers[]: {id, name, order, width (tiles), points [[x, y]...] upstream to downstream, joins (the course it ends in),
##    passes_settlement [ids]} : each traced through its points with the generator's own meander (a bend that is nought at
##    every point, so the course passes exactly through each), with fords, pools and falls as any course has; a course that
##    passes a settlement may come within the settlements' clearance, never onto its built ground;
##  - crossings[]: {kind ford | bridge, x, y, course, material}: a crossing the road keeps there (a ford; a bridge of the road's
##    type, or of stone when material is stone);
##  - downs: {rect, polygon, springs "none", water_ok [landmark ids]}: the waterless Downs, where no generated stream rises or
##    runs; the landmarks it names (kind pool, x, y, r) are its only water (a still pool).
## Loaded once; with the seed's roads, a pure function of the seed.
func anchored_courses() -> Array:
	if _anchored_done:
		return _anchored
	_anchored_done = true
	_anchored.clear()
	_forced.clear()
	_downs = Rect2i()
	_downs_poly = PackedVector2Array()
	if gen < 4:
		return _anchored
	var spec := {}
	for path in ["res://data/region_layout.json"]:
		if FileAccess.file_exists(path):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if d is Dictionary and (d as Dictionary).has("rivers"):
				spec = d
				break
	if spec.is_empty():
		return _anchored
	var dn: Dictionary = spec.get("downs", {})
	if dn.has("rect"):
		var r: Array = dn.rect
		_downs = Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
	for v in dn.get("polygon", []):
		_downs_poly.append(Vector2(float(v[0]), float(v[1])))
	var widths := {}
	var k := 0
	for rv in spec.rivers:
		var pts: Array = []
		for v in rv.points:
			pts.append(Vector2(float(v[0]), float(v[1])))
		widths[str(rv.id)] = float(rv.get("width", 2))
		if pts.size() >= 2:
			_anchored.append(_trace_through(pts, rv, 7001 + k * 131))
		k += 1
	for cr in spec.get("crossings", []):
		var kind := str(cr.kind)
		if kind == "bridge" and str(cr.get("material", "")) == "stone":
			kind = "stone_bridge"
		_forced.append([Vector2(float(cr.x), float(cr.y)) + Vector2(0.5, 0.5), float(widths.get(str(cr.get("course", "")), 2.0)) / 2.0 + 4.0, kind])
	for lm in spec.get("landmarks", []):
		if str(lm.get("kind", "")) == "pool" and str(lm.id) in (dn.get("water_ok", []) as Array):
			var at := Vector2(float(lm.x), float(lm.y))
			_anchored.append({"id": "canon:" + str(lm.id), "name": str(lm.get("name", lm.id)), "order": 1, "pts": [at, at],
				"r": [0.5, 0.5], "heading": [FLOW_STILL], "pools": [[at, float(lm.get("r", 3)), false]], "falls": [], "fords": [],
				"joins": "", "length": 0.0, "box": Rect2i(Vector2i(at.floor()), Vector2i.ONE).grow(int(lm.get("r", 3)) + 3),
				"canonical": true, "passes": []})
	return _anchored


## A canonical course through its control points: STREAM_STEP-tile steps between each pair, bent off the straight line by a
## meander that is nought at both ends (so it meets every point), the width growing from width[0] to width[1].
func _trace_through(ctrl: Array, cs: Dictionary, key: int) -> Dictionary:
	var order := int(cs.get("order", 1))
	var w0 := maxf(0.8, float(cs.get("width", 2)) / 2.0 * 0.85)        # a canonical course widens a little downstream
	var w1 := maxf(0.9, float(cs.get("width", 2)) / 2.0)
	var amp := float(W.canonical_meander.river if order >= 2 else W.canonical_meander.stream)
	var total := 0.0
	for q in range(ctrl.size() - 1):
		total += (ctrl[q] as Vector2).distance_to(ctrl[q + 1])
	var pts: Array = [ctrl[0]]
	var rs: Array = [w0]
	var heads: Array = []
	var fords: Array = []
	var pools: Array = []
	var falls: Array = []
	var done := 0.0
	var step := 0
	var was_mountain := _mountain(Vector2i((ctrl[0] as Vector2).round()))
	for q in range(ctrl.size() - 1):
		var a: Vector2 = ctrl[q]
		var b: Vector2 = ctrl[q + 1]
		var n := maxi(1, int(ceil(a.distance_to(b) / float(STREAM_STEP))))
		var side := (b - a).normalized().orthogonal()
		var phase := float(hash32(seed, key, q, 150) % 628) / 100.0
		for k in range(1, n + 1):
			var f := float(k) / float(n)
			var p := a.lerp(b, f) + side * amp * sin(PI * f) * sin(f * PI * 2.0 + phase) if k < n else b
			heads.append(_dir8(p - (pts[pts.size() - 1] as Vector2)))
			done += (pts[pts.size() - 1] as Vector2).distance_to(p)
			pts.append(p)
			rs.append(lerpf(w0, w1, clampf(done / maxf(total, 1.0), 0.0, 1.0)))
			step += 1
			var cell := Vector2i(p.round())
			var mtn := _mountain(cell)
			if step % FORD_EVERY == FORD_EVERY / 2 and not mtn and not was_mountain and not _near_forced(p, 10.0):
				fords.append([p, float(rs[rs.size() - 1]) + 1.0, (p - (pts[pts.size() - 2] as Vector2)).normalized()])
			if was_mountain and not mtn:
				falls.append(cell)
				pools.append([p, float(rs[rs.size() - 1]) + 1.2, true])
			was_mountain = mtn
	if bool(cs.get("end_pool", false)):
		pools.append([pts[pts.size() - 1], w1 + 1.6, false])
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var box := Rect2i(Vector2i(lo.floor()) - Vector2i(8, 8), Vector2i((hi - lo).ceil()) + Vector2i(17, 17))
	return {"id": "canon:" + str(cs.id), "name": str(cs.get("name", cs.id)), "order": order, "pts": pts, "r": rs, "heading": heads,
		"pools": pools, "falls": falls, "fords": fords, "joins": ("canon:" + str(cs.joins)) if str(cs.get("joins", "")) != "" else "",
		"length": done, "box": box, "canonical": true, "passes": (cs.get("passes_settlement", []) as Array).duplicate()}


func _near_forced(p: Vector2, extra: float) -> bool:
	for f in _forced:
		if (f[0] as Vector2).distance_to(p) <= float(f[1]) + extra:
			return true
	return false


## B25R1-018: the canonical crossing at cell `c` ("bridge", "stone_bridge" or "ford"), or "".
func forced_crossing(c: Vector2i) -> String:
	anchored_courses()
	var p := Vector2(c) + Vector2(0.5, 0.5)
	for f in _forced:
		if (f[0] as Vector2).distance_to(p) <= float(f[1]):
			return str(f[2])
	return ""


## B25R1-018: whether a cell lies in the waterless Downs.
func in_downs(p: Vector2i) -> bool:
	anchored_courses()
	if not _downs.has_point(p):
		return false
	return _downs_poly.size() < 3 or Geometry2D.is_point_in_polygon(Vector2(p), _downs_poly)


## The river rising in river lattice cell (i, j), or {} (see course_at for its keys). Cached.
func river_at(i: int, j: int) -> Dictionary:
	var key := Vector2i(i, j)
	if _river_cache.has(key):
		return _river_cache[key]
	var out := {}
	if hash32(seed, i, j, 140) % 100 < int(W.river.chance):
		for t in 6:
			var p := Vector2i(i * RIVER_LATTICE + 40 + hash32(seed, i, j, 141 + 2 * t) % (RIVER_LATTICE - 80),
				j * RIVER_LATTICE + 40 + hash32(seed, i, j, 142 + 2 * t) % (RIVER_LATTICE - 80))
			if not _kept_clear(p) and not in_downs(p) and _height(p) >= RIVER_HIGH:
				out = _trace(p, i * 6007 + j * 90001 + 77, 2, "river:%d,%d" % [i, j], [])
				break
	_river_cache[key] = out
	return out


## The stream rising in stream lattice cell (i, j), or {}: a course (see course_at). Cached.
func stream_at(i: int, j: int) -> Dictionary:
	var key := Vector2i(i, j)
	if _stream_cache.has(key):
		return _stream_cache[key]
	var out := {}
	if hash32(seed, i, j, 110) % 100 < int(W.stream.chance):
		# a spring: the first of six hashed places in the cell on a mountain, else the first on high ground
		var src := RegionRoads.NONE
		for t in 6:
			var p := Vector2i(i * STREAM_LATTICE + 20 + hash32(seed, i, j, 111 + 2 * t) % (STREAM_LATTICE - 40),
				j * STREAM_LATTICE + 20 + hash32(seed, i, j, 112 + 2 * t) % (STREAM_LATTICE - 40))
			if _kept_clear(p) or in_downs(p) or _height(p) < STREAM_HIGH:
				continue
			if _mountain(p):
				src = p
				break
			if src == RegionRoads.NONE:
				src = p
		if src != RegionRoads.NONE:
			var reach := Rect2i(src, Vector2i.ONE).grow(STREAM_STEP * STREAM_STEPS + 8)
			out = _trace(src, i * 7919 + j * 104729, 1, "stream:%d,%d" % [i, j], rivers_in(reach))
	_stream_cache[key] = out
	return out


## A course: {id, order (1 stream, 2 river), pts: Array[Vector2] (its line, downstream), r: Array[float] (width at each
## point), heading: Array[int] (the flow direction of each segment, 1-8: E, SE, S, SW, W, NW, N, NE), pools: [[centre,
## radius, foam]], falls: Array[Vector2i], fords: [[point, radius]], joins (the id of the river it ends in, or ""), length
## (tiles), box: Rect2i}. `into`: the rivers a stream may end in.
func _trace(src: Vector2i, key: int, order: int, id: String, into: Array) -> Dictionary:
	var steps := RIVER_STEPS if order == 2 else STREAM_STEPS
	var kind: Dictionary = W.river if order == 2 else W.stream
	var w0 := float(kind.width[0])
	var w1 := float(kind.width[1])
	var pts: Array = [Vector2(src)]
	var rs: Array = [w0]
	var heads: Array = []
	var pools: Array = []
	var falls: Array = []
	var fords: Array = []
	var joins := ""
	var length := 0.0
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
	for k in steps:
		var here := _height(at)
		var pick := -1
		var score := 1 << 30
		var bend := roundi(float(kind.meander) * sin(float(k) * (0.45 if order == 2 else 0.7) + float(hash32(seed, key, 0, 119) % 628) / 100.0))     # it meanders (a river in wider, gentler bends)
		for t in [-2, -1, 0, 1, 2]:
			var a := posmod(hd + t, 12)
			var to := at + Vector2i((dirs[a] * STREAM_STEP).round())
			var sc := _height(to) * 4 + absi(t - bend) * 14 + hash32(seed, key, k, 113 + t) % 12
			if sc < score:
				score = sc
				pick = a
		var nxt := at + Vector2i((dirs[pick] * STREAM_STEP).round())
		if _height(nxt) > here + 6 or _kept_clear(nxt) or in_downs(nxt):
			break                                          # the ground rises all round, the village is near or the Downs begin: a pool
		var wk := minf(w1, w0 + float(k) * (w1 - w0) / 24.0)
		# a stream that reaches a river ends in it: the junction is the nearest point of the river's line
		var met := _meets(Vector2(nxt), into)
		if not met.is_empty():
			pts.append(met.at)
			rs.append(wk)
			heads.append(_dir8(Vector2(met.at) - Vector2(at)))
			length += Vector2(at).distance_to(met.at)
			joins = str(met.id)
			break
		# a little wobble off the straight line, half way
		var mid := (Vector2(at) + Vector2(nxt)) / 2.0 + dirs[posmod(pick + 3, 12)] * (float(hash32(seed, key, k, 120) % 400) / 100.0 - 2.0)
		heads.append(_dir8(mid - Vector2(at)))
		heads.append(_dir8(Vector2(nxt) - mid))
		pts.append(mid)
		rs.append(wk)
		pts.append(Vector2(nxt))
		rs.append(wk)
		length += Vector2(at).distance_to(mid) + mid.distance_to(Vector2(nxt))
		var mtn := _mountain(nxt)
		if k % FORD_EVERY == FORD_EVERY / 2 and not mtn and not was_mountain:
			fords.append([Vector2(nxt), maxf(FORD_R, wk + 1.0), (Vector2(nxt) - mid).normalized()])      # stepping stones across, so no course walls the country off
		if was_mountain and not mtn:
			falls.append(nxt)
			pools.append([Vector2(nxt) + dirs[pick] * 2.0, maxf(wk + 1.0, 2.4 + float(hash32(seed, key, k, 121) % 10) / 10.0), true])
		was_mountain = mtn
		at = nxt
		hd = pick
	if pts.size() < 3:
		return {}
	if joins == "":
		var end_r := float(kind.end_pool) + float(hash32(seed, key, 0, 122) % 12) / 10.0
		pools.append([pts[pts.size() - 1], end_r, false])     # where it ends: a pool (a river's a lake)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var box := Rect2i(Vector2i(lo.floor()) - Vector2i(8, 8), Vector2i((hi - lo).ceil()) + Vector2i(17, 17))
	return {"id": id, "order": order, "pts": pts, "r": rs, "heading": heads, "pools": pools, "falls": falls, "fords": fords,
		"joins": joins, "length": length, "box": box}


## The eight-way flow direction of a step d: 1 E, 2 SE, 3 S, 4 SW, 5 W, 6 NW, 7 N, 8 NE.
static func _dir8(d: Vector2) -> int:
	return posmod(roundi(d.angle() / (PI / 4.0)), 8) + 1


## Where p comes within a river's width (plus a tile) of one of `rivers`: {at: the nearest point of its line, id}, else {}.
func _meets(p: Vector2, rivers: Array) -> Dictionary:
	for rv in rivers:
		if not Rect2(rv.box).grow(2.0).has_point(p):
			continue
		var pts: Array = rv.pts
		for q in range(pts.size() - 1):
			var a: Vector2 = pts[q]
			var b: Vector2 = pts[q + 1]
			if _seg_dist(p, a, b) <= float(rv.r[q]) + 3.0:
				var ab := b - a
				var t := 0.0 if ab.length_squared() == 0.0 else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
				return {"at": a + ab * t, "id": rv.id}
	return {}


## The rivers whose water may reach `area`, in lattice order.
func rivers_in(area: Rect2i) -> Array:
	var out := []
	if gen < 4:
		return out
	for c in anchored_courses():
		if int(c.order) >= 2 and (c.box as Rect2i).intersects(area.grow(RIVER_REACH)):
			out.append(c)                              # B25R1-018: the canonical rivers first
	var grown := area.grow(RIVER_REACH)
	for j in range(fdiv(grown.position.y, RIVER_LATTICE), fdiv(grown.end.y, RIVER_LATTICE) + 1):
		for i in range(fdiv(grown.position.x, RIVER_LATTICE), fdiv(grown.end.x, RIVER_LATTICE) + 1):
			var rv := river_at(i, j)
			if not rv.is_empty() and (rv.box as Rect2i).intersects(area):
				out.append(rv)
	return out


## Every course (rivers first, then streams, each in lattice order) whose water may reach `area` (tiles).
func streams_in(area: Rect2i) -> Array:
	var out := rivers_in(area).filter(func(c): return (c.box as Rect2i).intersects(area))
	if gen < 4:
		return out
	for c in anchored_courses():
		if int(c.order) == 1 and (c.box as Rect2i).intersects(area):
			out.append(c)                              # B25R1-018: the canonical streams
	var grown := area.grow(STREAM_STEP * STREAM_STEPS + 12)
	for j in range(fdiv(grown.position.y, STREAM_LATTICE), fdiv(grown.end.y, STREAM_LATTICE) + 1):
		for i in range(fdiv(grown.position.x, STREAM_LATTICE), fdiv(grown.end.x, STREAM_LATTICE) + 1):
			var st := stream_at(i, j)
			if not st.is_empty() and (st.box as Rect2i).intersects(area):
				out.append(st)
	return out


## B25R1-017: the course graph of an area, for the map and a later weather system: {id: {order, joins, length, catchment,
## flow, tributaries: [ids]}}. A river's catchment is its own length and its tributaries' (those found within the area and
## the reach round it); a stream's its own. flow = order x seasonal_flow (a relative discharge; constant now).
func course_graph(area: Rect2i) -> Dictionary:
	var out := {}
	var cs := streams_in(area)
	for c in cs:
		out[str(c.id)] = {"order": int(c.order), "joins": str(c.joins), "length": float(c.length), "catchment": float(c.length),
			"flow": float(c.order) * seasonal_flow, "tributaries": []}
	for c in cs:
		var j := str(c.joins)
		if j != "" and out.has(j):
			out[j].tributaries.append(str(c.id))
			out[j].catchment = float(out[j].catchment) + float(c.length)
	return out


## B25R1-018: whether water may lie at corner (wx, wy) for its settlements: never within VILLAGE_CLEAR of the village or a
## settlement, except that a course passing a settlement (`passes`, the layout's passes_settlement) keeps only off its built
## ground (its site and a tile round it).
## Generation 6 (B25R1 flyover repair): a canonical course (`canonical`) keeps off the village's clearance and the built ground
## only (_built: every building and yard piece and BUILT_CLEAR round it, a walled town's walls), beside or through any
## settlement; where it meets a street it is bridged like a road (_generate). Before, it was cut off for its whole way across a
## settlement's rectangle (and VILLAGE_CLEAR round one it did not "pass"): Upmeads Water by Rushford, the Netherton stream at
## Netherton and Wendholt, Coldlake through Mileham, Garton and Higham.
func _water_clear(wx: int, wy: int, passes: Array, canonical := false) -> bool:
	if _rdist(village, wx, wy) < VILLAGE_CLEAR:
		return false
	if canonical and gen >= 6:
		return not _built.has(Vector2i(wx, wy))
	for st in _near_sites:
		var lim := 2 if str(st.id) in passes else VILLAGE_CLEAR
		if _rdist(st.rect, wx, wy) < lim:
			return false
	return true


## B25R1-017 (owner: "keep ... existing roads dry"): whether water may lie on corner (i, j) of the area given the roads round
## it: off the road and its one-tile margin, yes; on them (one of the corner's four cells), only where the course crosses it, its heading
## (`along`) at least 50 degrees off the road's own line there (the principal axis of the road cells in the 5 x 5 round the
## corner); where a road runs along a course the road keeps to the bank, dry.
func _water_may_cross(road: PackedByteArray, open: PackedByteArray, i: int, j: int, along: Vector2) -> bool:
	if road.is_empty():
		return true
	var on := false                                    # the road and the tile round it (kept clear, as of cliffs and trees)
	for cell in [[i - 1, j - 1], [i, j - 1], [i - 1, j], [i, j]]:
		var x: int = cell[0]
		var y: int = cell[1]
		if x >= 0 and y >= 0 and x < AREA and y < AREA and (open[y * AREA + x] == 1 if not open.is_empty() else road[y * AREA + x] == 1):
			on = true
	if not on:
		return true
	# B25R1-018: a canonical ford: the road goes through the water there, whatever else meets it. A canonical bridge needs no
	# exception (every road crosses on a straight leg square to the course, _crossing_legs, which the angle rule below lets
	# through), so another road ending beside it stays dry instead of making a stub of bridge
	if not _forced.is_empty() and forced_crossing(Vector2i(_wc_ox + i, _wc_oy + j)) == "ford":
		return true
	if along.length_squared() == 0.0:
		return false                                   # a pool keeps off the road
	var sxx := 0.0
	var syy := 0.0
	var sxy := 0.0
	var n := 0
	for dy in range(-3, 3):
		for dx in range(-3, 3):
			var x := i + dx
			var y := j + dy
			if x >= 0 and y >= 0 and x < AREA and y < AREA and road[y * AREA + x] == 1:
				var fx := float(dx) + 0.5
				var fy := float(dy) + 0.5
				sxx += fx * fx
				syy += fy * fy
				sxy += fx * fy
				n += 1
	if n < 3:
		return true
	var axis := 0.5 * atan2(2.0 * sxy, sxx - syy)
	return absf(sin(along.angle() - axis)) >= float(W.road_cross_min_sin)


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	var t := 0.0 if l2 == 0.0 else clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## The water corners of the GRID x GRID corners at (ox + i, oy + j): [wc (1 water), flow (the claiming course's direction,
## FLOW_STILL in a pool, FLOW_FOAM in a fall's pool), order (1 stream, 2 river), bank (tiles from the nearest water's edge,
## 0-BANK_REACH, 255 beyond)].
var _wc_ox := 0
var _wc_oy := 0


func _water_corners(ox: int, oy: int, road := PackedByteArray(), open := PackedByteArray()) -> Array:
	_wc_ox = ox
	_wc_oy = oy
	anchored_courses()
	var wc := PackedByteArray()
	var fl := PackedByteArray()
	var od := PackedByteArray()
	var bk := PackedByteArray()
	wc.resize(GRID * GRID)
	fl.resize(GRID * GRID)
	od.resize(GRID * GRID)
	bk.resize(GRID * GRID)
	bk.fill(255)
	var area := Rect2i(ox, oy, GRID, GRID)
	_area_fords.clear()
	for st in streams_in(area):
		for f in st.fords:
			if Rect2(area).grow(float(f[1]) + 1.0).has_point(f[0]) and _ford_clear(f[0]):
				_area_fords.append(f)
		var pts: Array = st.pts
		var rs: Array = st.r
		var heads: Array = st.heading
		var passes: Array = st.get("passes", [])
		var canon := bool(st.get("canonical", false))
		for q in range(pts.size() - 1):
			var a: Vector2 = pts[q]
			var b: Vector2 = pts[q + 1]
			var r: float = maxf(float(rs[q]), float(rs[q + 1]))
			var reach := r + float(BANK_REACH) + 1.0
			var lo := Vector2i((a.min(b) - Vector2(reach, reach)).floor()) - Vector2i(ox, oy)
			var hi := Vector2i((a.max(b) + Vector2(reach, reach)).ceil()) - Vector2i(ox, oy)
			for j in range(maxi(0, lo.y), mini(GRID, hi.y + 1)):
				for i in range(maxi(0, lo.x), mini(GRID, hi.x + 1)):
					var k := j * GRID + i
					var wx := ox + i
					var wy := oy + j
					var d := _seg_dist(Vector2(wx, wy), a, b)
					var bank := float(hash32(seed, wx, wy, 130) % 100) / 200.0 - 0.25
					if d <= r + bank and _water_clear(wx, wy, passes, canon) and _water_may_cross(road, open, i, j, b - a):
						if wc[k] == 0 or int(st.order) > od[k]:
							wc[k] = 1
							fl[k] = int(heads[mini(q, heads.size() - 1)])
							od[k] = int(st.order)
						bk[k] = 0
					elif d - r < float(BANK_REACH) + 0.5:
						bk[k] = mini(bk[k], maxi(1, roundi(d - r)))
		for pool in st.pools:
			var c: Vector2 = pool[0]
			var r2: float = pool[1]
			for j in range(maxi(0, int(floor(c.y - r2 - 1)) - oy), mini(GRID, int(ceil(c.y + r2 + 1)) - oy + 1)):
				for i in range(maxi(0, int(floor(c.x - r2 - 1)) - ox), mini(GRID, int(ceil(c.x + r2 + 1)) - ox + 1)):
					var wx := ox + i
					var wy := oy + j
					var bank := float(hash32(seed, wx, wy, 131) % 100) / 100.0 - 0.5
					if Vector2(wx, wy).distance_to(c) <= r2 + bank and _water_clear(wx, wy, passes, canon) and _water_may_cross(road, open, i, j, Vector2.ZERO):
						var k := j * GRID + i
						wc[k] = 1
						fl[k] = FLOW_FOAM if bool(pool[2]) else FLOW_STILL
						od[k] = maxi(od[k], int(st.order))
						bk[k] = 0
	return [wc, fl, od, bk]

# ---------------------------------------------------------------- roads ----------------------
func _node_excluded(p: Vector2i) -> bool:
	if village.grow(24).has_point(p):
		return true
	for st in sites:                              # REGION-NAV-01: no road node in or right by a settlement
		if (st.rect as Rect2i).grow(12).has_point(p):
			return true
	# B25R1-018: no country trail on the Downs ("never a road to call a road", BONE-C3-P037), across the waste or through the
	# Wood Perilous (one beaten way, BONE-C8-P002): their only ways are the layout's routes
	var reg := RegionGeo.region_at(p.x, p.y)
	return reg == "downs" or reg == "dry_waste" or reg == "wood_perilous"


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


## Generation 6 (owner, flyover 2026-11-05: roads "fade into open ground rather than connect clearly to destinations"): a country
## trail is laid only between grid nodes that are alive: a node with a settlement's, gate's or main route's road to it, or with
## at least two trails to living nodes (looked along up to SPUR_DEPTH nodes), so no trail runs out to a node and stops there in
## the grass (a spur left where its neighbours fell in a settlement's, the village's or a region's exclusion).
const SPUR_DEPTH := 3
var _alive := {}                          # Vector3i(i, j, depth) -> bool (a pure function of the seed and the links; not saved)
var _anchors := {}                        # node positions a link of the network ends at


func _edge_live(i: int, j: int, k: int) -> bool:
	if not _edge(i, j, k):
		return false
	if gen < 6:
		return true
	return _node_alive(i, j, SPUR_DEPTH) and _node_alive(i + [1, 0, 1, -1][k], j + [0, 1, 1, 1][k], SPUR_DEPTH)


func _edge_open(si: int, sj: int, k: int) -> bool:
	var a := node_pos(si, sj)
	var b := node_pos(si + [1, 0, 1, -1][k], sj + [0, 1, 1, 1][k])
	if _node_excluded(a) or _node_excluded(b) or not _edge(si, sj, k):
		return false
	var bb := Rect2i(mini(a.x, b.x), mini(a.y, b.y), absi(a.x - b.x), absi(a.y - b.y))
	return not bb.intersects(Rect2i(village.grow(10))) and not _crosses_site(bb)


func _node_alive(i: int, j: int, depth: int) -> bool:
	var key := Vector3i(i, j, depth)
	if _alive.has(key):
		return _alive[key]
	if _anchors.is_empty():
		for l in _links:
			_anchors[Vector2i(l.a)] = true
			_anchors[Vector2i(l.b)] = true
	var ok := _anchors.has(node_pos(i, j)) or _junction.has(Vector2i(i, j))
	if not ok:
		var n := 0
		for k in 4:
			for dir in [1, -1]:
				var dx: int = [1, 0, 1, -1][k]
				var dy: int = [0, 1, 1, 1][k]
				var si: int = i if dir == 1 else i - dx
				var sj: int = j if dir == 1 else j - dy
				if not _edge_open(si, sj, k):
					continue
				var oi: int = i + dx if dir == 1 else i - dx
				var oj: int = j + dy if dir == 1 else j - dy
				if depth == 0 or _node_alive(oi, oj, depth - 1):
					n += 1
		ok = n >= 2
	if _alive.size() > 20000:
		_alive.clear()
	_alive[key] = ok
	return ok


func _raw_edge(i: int, j: int, k: int) -> bool:
	return hash32(seed, i, j, 30 + k) % 100 < [46, 46, 14, 14][k]   # B25R1-018: sparser country trails (a network, not a grid)


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
	return _crossing_legs(out) if gen >= 4 else out


## B25R1-017/018, EA-01 (coordinator 2026-11-03: straight bridges): where a road's cells cross a stream or river, the run
## over the water is replaced by one straight, axis-aligned leg from bank to bank, square to the course's main direction
## there, starting and ending CROSS_MARGIN tiles past the water; the road reaches the leg's ends over dry land (where the
## road tiles turn cleanly). A layout crossing (crossings[]) near the run fixes the leg's line through its point. Pure: the
## courses are global and the cells depend only on the polyline and the seed, so every chunk draws the same road.
const CROSS_MARGIN := 2


func _crossing_legs(cells: PackedInt32Array) -> PackedInt32Array:
	var n := cells.size() / 2
	if n < 3:
		return cells
	var lo := Vector2i(cells[0], cells[1])
	var hi := lo
	for k in n:
		lo = Vector2i(mini(lo.x, cells[2 * k]), mini(lo.y, cells[2 * k + 1]))
		hi = Vector2i(maxi(hi.x, cells[2 * k]), maxi(hi.y, cells[2 * k + 1]))
	var box := Rect2i(lo, hi - lo + Vector2i.ONE).grow(12)
	var segs: Array = []                          # [a, b, half-width] of the course segments near the road
	for crs in streams_in(box):
		var pts: Array = crs.pts
		var rs: Array = crs.r
		for k in range(1, pts.size()):
			var a: Vector2 = pts[k - 1]
			var b: Vector2 = pts[k]
			var w := float(rs[mini(k, rs.size() - 1)])
			if Rect2(a, Vector2.ZERO).expand(b).grow(w + 4.0).intersects(Rect2(box)):
				segs.append([a, b, w])
	if segs.is_empty():
		return cells
	var wet := func(c: Vector2i, extra: float) -> int:      # the index of the course segment whose water covers c, else -1
		var p := Vector2(c) + Vector2(0.5, 0.5)
		for si in segs.size():
			if _seg_dist(p, segs[si][0], segs[si][1]) <= float(segs[si][2]) + extra:
				return si
		return -1
	var out := PackedInt32Array()
	var k := 0
	var plain := 1                                    # cells from here on were appended as they were (after the last leg)
	while k < n:
		var c := Vector2i(cells[2 * k], cells[2 * k + 1])
		var si: int = wet.call(c, 0.5)
		if si < 0 or k == 0:
			out.append(c.x)
			out.append(c.y)
			k += 1
			continue
		# a run over the water: from the last cell clear of it (a) to the first clear after (b)
		var e := k
		while e < n and wet.call(Vector2i(cells[2 * e], cells[2 * e + 1]), float(CROSS_MARGIN)) >= 0:
			e += 1
		var s := k
		while s > plain and wet.call(Vector2i(cells[2 * (s - 1)], cells[2 * (s - 1) + 1]), float(CROSS_MARGIN)) >= 0:
			s -= 1
		if e >= n and s > plain and s > 0 and wet.call(Vector2i(cells[2 * (s - 1)], cells[2 * (s - 1) + 1]), float(CROSS_MARGIN)) < 0:
			# EA-01: the road ends by the water (a trail meeting a bridge's foot): it reaches its end over land, round the
			# water's edge, if one of the two right-angled ways there stays dry (else as drawn)
			var a0 := Vector2i(cells[2 * (s - 1)], cells[2 * (s - 1) + 1])
			var z := Vector2i(cells[2 * (n - 1)], cells[2 * (n - 1) + 1])
			for corner in [Vector2i(z.x, a0.y), Vector2i(a0.x, z.y)]:
				var way := PackedInt32Array()
				_append_line(way, a0, corner)
				_append_line(way, corner, z)
				var dry := true
				for q in range(0, way.size() - 2, 2):
					if wet.call(Vector2i(way[q], way[q + 1]), 0.5) >= 0:
						dry = false
				if dry:
					out.resize(2 * (out.size() / 2 - (k - s)))
					out.append_array(way)
					return out
		if e >= n or s <= 0 or wet.call(Vector2i(cells[2 * (s - 1)], cells[2 * (s - 1) + 1]), float(CROSS_MARGIN)) >= 0:
			out.append(c.x)
			out.append(c.y)
			k += 1
			continue                                  # the road starts or ends in the water: left as drawn
		var a := Vector2i(cells[2 * (s - 1)], cells[2 * (s - 1) + 1])
		var b := Vector2i(cells[2 * e], cells[2 * e + 1])
		var dir: Vector2 = (segs[si][1] as Vector2) - (segs[si][0] as Vector2)
		var o: Vector2 = segs[si][0]
		if signf(dir.cross(Vector2(a) - o)) == signf(dir.cross(Vector2(b) - o)):
			out.append(c.x)                           # the road touches the water and comes back on the same bank (it runs
			out.append(c.y)                           # along it): no crossing; the water keeps off it (_water_may_cross)
			k += 1
			continue
		var ns := absf(dir.x) >= absf(dir.y)          # the course runs east-west: the leg runs north-south
		var mid := Vector2(a + b) * 0.5
		var fc := _forced_near(mid, 8.0)
		if fc != Vector2.INF:
			mid = fc
		var line := roundi(mid.x) if ns else roundi(mid.y)
		var axis := Vector2i(0, 1) if ns else Vector2i(1, 0)
		var at := Vector2i(line, roundi(mid.y)) if ns else Vector2i(roundi(mid.x), line)
		# the leg's ends: out along the line from the water's middle until CROSS_MARGIN clear of every course
		var sign := 1 if Vector2(b - a).dot(Vector2(axis)) >= 0.0 else -1
		var p0 := at
		var p1 := at
		var guard := 0
		while wet.call(p0, float(CROSS_MARGIN)) >= 0 and guard < 40:
			p0 -= axis * sign
			guard += 1
		guard = 0
		while wet.call(p1, float(CROSS_MARGIN)) >= 0 and guard < 40:
			p1 += axis * sign
			guard += 1
		# s - 1 .. a is kept (already appended up to k - 1; drop the run's cells appended from s on)
		var keep := s
		out.resize(2 * (out.size() / 2 - (k - keep)))
		_append_line(out, a, p0)
		_append_line(out, p0, p1)
		_append_line(out, p1, b)
		k = e + 1
		plain = k
	return out


## The 4-connected cells after `from` up to and including `to` (straight runs as _polyline draws them).
static func _append_line(out: PackedInt32Array, from: Vector2i, to: Vector2i) -> void:
	var dx := absi(to.x - from.x)
	var dy := absi(to.y - from.y)
	var sx := 1 if to.x > from.x else -1
	var sy := 1 if to.y > from.y else -1
	var x := from.x
	var y := from.y
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


## B25R1-018: the centre of the layout crossing within r of p, else Vector2.INF.
func _forced_near(p: Vector2, r: float) -> Vector2:
	anchored_courses()
	for f in _forced:
		if (f[0] as Vector2).distance_to(p) <= r + float(f[1]):
			return f[0]
	return Vector2.INF


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
				if _node_excluded(b) or not _edge_live(i, j, k):
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
	for st in sites + structures:                   # (B25R1-018: a landmark built in the country stands in its own clearing)
		if (st.rect as Rect2i).intersects(site_reach):
			_near_sites.append(st)
	var fe := _field(ox, oy, 1, [128, 64, 32])
	var fm := _field(ox, oy, 2, [320, 160])
	var ff := _field(ox, oy, 3, [96, 48, 24])
	var fc := _field(ox, oy, 4, [24, 12])
	var fr := _field(ox, oy, 5, [72, 36])
	var fs := _field(ox, oy, 6, [160, 80])
	var fl := _field(ox, oy, 7, [28, 14])
	# B25R1-018: the kind of country at each cell corner (RegionGeo; R_* codes) and a patch field for its bare ground
	var reg := _region_codes(ox, oy)
	var fp := _field(ox, oy, 8, [14, 7])
	var fq := _field(ox, oy, 9, [6, 3])           # B25R1-018 chalk polish: the Downs' bare chalk in small scattered scars, not pits
	var here := Rect2i(ox, oy, GRID, GRID)
	for z: Rect2i in _mark_zones:                 # chalk cut in the turf (a hill figure, an earthwork's bank): bare at those corners,
		if not z.intersects(here):                # whole turf round them
			continue
		for gj in GRID:
			for gi in GRID:
				var cw := Vector2i(ox + gi, oy + gj)
				if z.has_point(cw):
					var gk := gj * GRID + gi
					var cut := _marks.has(cw)
					if cut:
						reg[gk] = R_DOWNS
					fp[gk] = 1000 if cut else 0
					fq[gk] = 1000 if cut else 0
	var road := _road_mask(ox, oy)
	var open := PackedByteArray()                 # road and one cell round it
	open.resize(AREA * AREA)
	for j in range(1, AREA - 1):
		for i in range(1, AREA - 1):
			if road[j * AREA + i] == 1:
				for dj in range(-1, 2):
					for di in range(-1, 2):
						open[(j + dj) * AREA + i + di] = 1
	# generation 6: for the water a settlement's streets count as road (a course crossing one is bridged, one running along it
	# keeps to the bank), so a canonical course through a settlement leaves its streets passable
	var wroad := road
	var wopen := open
	if gen >= 6 and not _near_sites.is_empty():
		var lanes := RegionRoads.lane_cells(self)
		var any := false
		for j in AREA:
			for i in AREA:
				if lanes.has(Vector2i(ox + i, oy + j)):
					if not any:
						wroad = road.duplicate()
						wopen = open.duplicate()
						any = true
					wroad[j * AREA + i] = 1
		if any:
			for j in range(1, AREA - 1):
				for i in range(1, AREA - 1):
					if wroad[j * AREA + i] == 1:
						for dj in range(-1, 2):
							for di in range(-1, 2):
								wopen[(j + dj) * AREA + i + di] = 1
	var wdata: Array = _water_corners(ox, oy, wroad, wopen) if gen >= 4 else []
	_wc_order = wdata[2] if gen >= 4 else PackedByteArray()    # B25R1-Q3: generation 4's streams and rivers
	var wc: PackedByteArray = wdata[0] if gen >= 4 else PackedByteArray()
	var wn := PackedByteArray()                   # water corners per cell (0-4)
	wn.resize(AREA * AREA)
	if not wc.is_empty():
		for j in AREA:
			for i in AREA:
				var k := j * GRID + i
				wn[j * AREA + i] = wc[k] + wc[k + 1] + wc[k + GRID] + wc[k + GRID + 1]
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
	var rzc := PackedByteArray()                  # B25R1-018 (generation 5): corners on raised ground (Bear Hill, the castle knoll)
	rzc.resize(GRID * GRID)
	var rz_here := false
	for rz in raised:
		if (rz.box as Rect2i).intersects(here):
			rz_here = true
	for j in GRID:
		for i in GRID:
			var k := j * GRID + i
			if rz_here and _raised_corner(ox + i, oy + j):
				rzc[k] = 1
				cliff[k] = 1                          # (roads too: a road on the top runs on it, and climbs the rim by steps)
				continue
			var reach := (fm[k] - 470) / 4
			if reach <= 0 or absi(fe[k] - 512) >= reach:
				continue
			var wx := ox + i
			var wy := oy + j
			if posmod(wx - wob_x[j] + 3, PASS_LATTICE) < 6 or posmod(wy - wob_y[i] + 3, PASS_LATTICE) < 6:
				continue
			if _vdist(wx, wy) < VILLAGE_CLEAR:
				continue
			if reg[k] != R_NONE and reg[k] != R_HILLS:
				continue                          # B25R1-018: the region's own country has no rock-rimmed ranges (open downs, waste, wood, vales)
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
				# a mountain top, a plateau nobody can reach: pines and boulders cover it, so it reads as wooded rock (raised ground
				# of the layout is open turf: B25R1-018)
				var gq := j * GRID + i
				if inner[q] == 1 and rzc[gq] + rzc[gq + 1] + rzc[gq + GRID] + rzc[gq + GRID + 1] == 0:
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
			match int(reg[k]):                        # B25R1-018: each country its own cover (docs/design/REGION_RECONSTRUCTION_B25R1.md)
				R_DOWNS:                              # "no trees thereon" (BONE-C4-P006): a lone thorn at most, a few sarsens
					tree_p = 3
					rock_p = mini(rock_p, 6)
				R_WASTE:                              # "rough waste ... a few bushes scattered" (BONE-C8-P002): stony, treeless
					tree_p = 0
					rock_p = 18 + rock_p / 2
				R_WOOD:                               # "a wood thick with trees, and no break in them" (BONE-C8-P002)
					tree_p = maxi(tree_p, 620)
					rock_p = mini(rock_p, 8)
				R_VALE:                               # "more of wild-wood trees" (BONE-C7-P007)
					tree_p = maxi(tree_p, 260)
				R_VINE:                               # vineyards and orchards on the hill-sides (BONE-C7-P004): orchard rows
					tree_p = 1000 if (posmod(x, 5) == 0 and posmod(y, 5) == 0 and fl[k] > 560) else 0
					rock_p = mini(rock_p, 3)
				R_FARM:                               # meadows and tillage: hedgerow trees and copses, not forest
					tree_p = tree_p / 8 if fc[k] >= 220 else tree_p / 3
					rock_p = mini(rock_p, 6)
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
	ch.flow.resize(cells)
	ch.level.resize(cells)
	ch.bank.resize(cells)
	ch.bank.fill(255)
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
			if corners == 0:                          # B25R1-018: chalk on the Downs, bare earth in the waste (the free tileset's corner sets)
				var soil := _soil_bits(reg, fp, fq, gk)
				if soil.x != 0:
					opts = (tiles.chalk if soil.y == 1 else tiles.dry)[soil.x]
			ch.ground[c] = opts[hash32(seed, wx, wy, 70) % opts.size()]
			if blocked[q] == 1:
				ch.solid[c] = 1
				if road[q] == 1 and inner[q] == 0 and rzc[gk] + rzc[gk + 1] + rzc[gk + GRID] + rzc[gk + GRID + 1] > 0:
					# B25R1-018: a road up raised ground climbs its rim by steps cut in the rock (walked on; drawn as the B14-07 steps,
					# running toward the top). Recorded in fixed_works (a function of the seed: the same on every generation).
					ch.solid[c] = 0
					var ns := inner[q - AREA] == 1 or inner[q + AREA] == 1
					fixed_works[Vector2i(wx, wy)] = "steps_ns" if ns else "steps_ew"
			if wn[q] > 0:
				_water_cell(ch, c, q, gk, wdata, wn, blocked[q] == 1 and inner[q] == 0, wroad[q] == 1, wx, wy,
					_is_fall(q, wn, blocked, inner), _is_fall(q - AREA, wn, blocked, inner) or _is_fall(q - 2 * AREA, wn, blocked, inner) or _is_fall(q - 3 * AREA, wn, blocked, inner),
					_road_shallows(q, wroad, wopen, wn), _is_fall(q - AREA, wn, blocked, inner), _road_near(q, wroad, 3))
			elif not wdata.is_empty():
				ch.bank[c] = (wdata[3] as PackedByteArray)[gk]       # B25R1-017: the floodplain's height above the water
			if road[q] != 1 and (_chalk_cells.has(Vector2i(wx, wy)) or _bank_cells.has(Vector2i(wx, wy))):
				ch.path[c] = _figure_tile(Vector2i(wx, wy))   # B25R1-018: a hill figure's chalk line, an earthwork's bank
				continue
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
				var wood := reg[gk] == R_WOOD or reg[gk] == R_VALE   # beech and the wild-wood: broadleaf
				var kidx := _tree_kind(tree_kinds, 100 if wood else fs[gk], 0 if wood else fm[gk], wx, wy, mine == 3)
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
				match int(reg[gk]):                   # B25R1-018
					R_DOWNS:
						bush_p = 6
						fl_p = fl_p / 2 + 10
					R_WASTE:
						bush_p = 40
						fl_p = 0
					R_VINE:                           # the vine rows: bushes along every third row where the vineyard lies
						bush_p = 1024 if (posmod(wy, 3) == 0 and fl[gk] <= 560 and fc[gk] > 380) else 4
					R_FARM:
						fl_p += 20
						bush_p /= 2
				if vd > 2 and hd < fl_p:
					var fls: Array = tiles.flowers
					ch.deco[c] = fls[hash32(seed, wx, wy, 81) % fls.size()]
				elif vd > 2 and hd < fl_p + bush_p:
					var bs: Array = tiles.bushes
					ch.deco[c] = bs[hash32(seed, wx, wy, 82) % bs.size()]
	return ch


## B25R1-Q3: a cell with water corners: its ground is the water tile for its corners and its flow (a rim cell a course runs
## through, north to south, the waterfall: a genuine drop; another wet rim cell its water tile, or its cliff where only a
## corner is wet), it is water when two or more corners are (solid), a bridge where a road runs on it, a ford at the course's
## fords, and now and then a rock stands in open water. B25R1-017: its flow, level and bank are kept.
## B25R1-017: whether area cell q is a waterfall: a cliff rim cell (blocked, not inside the rim) with water above and below
## it, a mountain top just above (or the rim, then the top) and no top below: water leaving the raised ground over its edge.
func _is_fall(q: int, wn: PackedByteArray, blocked: PackedByteArray, inner: PackedByteArray) -> bool:
	if q - 2 * AREA < 0 or q + AREA >= AREA * AREA:
		return false
	if blocked[q] != 1 or inner[q] != 0 or wn[q] < 2 or wn[q - AREA] < 2 or wn[q + AREA] < 2:
		return false
	# EA-01 (coordinator 2026-11-04): a fall only where its art fits: a stream (order 1, one or two tiles wide); a river
	# over a rim is rapids (_water_cell)
	if not _wc_order.is_empty():
		var gk := (q / AREA) * GRID + q % AREA
		if maxi(maxi(_wc_order[gk], _wc_order[gk + 1]), maxi(_wc_order[gk + GRID], _wc_order[gk + GRID + 1])) != 1:
			return false
	return (inner[q - AREA] == 1 or (blocked[q - AREA] == 1 and inner[q - 2 * AREA] == 1)) and inner[q + AREA] == 0


## EA-01 (coordinator 2026-11-04: a crossing that has a bridge needs no ford): whether no road runs within
## water.json "ford_bridge_clear" tiles of ford point p (a road near a course crosses it there on a bridge). Global and cached:
## the same answer for every chunk.
func _ford_clear(p: Vector2) -> bool:
	var key := Vector2i(p.round())
	if _ford_ok.has(key):
		return _ford_ok[key]
	var r := int(W.get("ford_bridge_clear", 12))
	var mask := _road_mask(key.x - AREA / 2, key.y - AREA / 2)
	var ok := true
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var i := AREA / 2 + dx
			var j := AREA / 2 + dy
			if ok and i >= 0 and j >= 0 and i < AREA and j < AREA and mask[j * AREA + i] == 1 and dx * dx + dy * dy <= r * r:
				ok = false
	if _ford_ok.size() > 4000:
		_ford_ok.clear()
	_ford_ok[key] = ok
	return ok


## B25R1-017, EA-01: whether point p is on ford f [point, radius, along]: within its radius of the point and on the band
## straight across the course there (water.json "ford_band": half its width in tiles), so a ford is a line of stepping
## stones from bank to bank, not a field of them.
func _in_ford(f: Array, p: Vector2) -> bool:
	var d := p - (f[0] as Vector2)
	if d.length() > float(f[1]):
		return false
	return f.size() < 3 or absf(d.dot(f[2] as Vector2)) <= float(W.get("ford_band", 1.3))


## B25R1-017: whether area cell q is water at a road's edge (the tile beside the road) that flanks no crossing: kept
## walkable as shallows, so a road running beside a course is never pinched. Water beside a bridge or ford stays deep.
## EA-01: whether a road cell lies within r cells of area cell q (a bridge's or ford's surroundings: no rocks there).
func _road_near(q: int, road: PackedByteArray, r: int) -> bool:
	var i := q % AREA
	var j := q / AREA
	for y in range(maxi(0, j - r), mini(AREA, j + r + 1)):
		for x in range(maxi(0, i - r), mini(AREA, i + r + 1)):
			if road[y * AREA + x] == 1:
				return true
	return false


func _road_shallows(q: int, road: PackedByteArray, open: PackedByteArray, wn: PackedByteArray) -> bool:
	if open.is_empty() or open[q] != 1 or road[q] == 1:
		return false
	for d in [-AREA - 1, -AREA, -AREA + 1, -1, 1, AREA - 1, AREA, AREA + 1]:
		var n: int = q + d
		if n >= 0 and n < AREA * AREA and road[n] == 1 and wn[n] >= 2:
			return false                               # beside a road cell on the water: a crossing's flank
	return true


func _water_cell(ch: Chunk, c: int, q: int, gk: int, wdata: Array, wn: PackedByteArray, rim: bool, on_road: bool, wx: int, wy: int,
		fall := false, below_fall := false, shallows := false, foot := false, road_near := false) -> void:
	var wc: PackedByteArray = wdata[0]
	var fl: PackedByteArray = wdata[1]
	var od: PackedByteArray = wdata[2]
	var bits: int = wc[gk] | (wc[gk + 1] << 1) | (wc[gk + GRID + 1] << 2) | (wc[gk + GRID] << 3)
	if bits == 5:
		bits = 7                                       # the set has no diagonal pair: the nearest it has
	elif bits == 10:
		bits = 11
	var flow := 0
	var order := 0
	for k in [gk, gk + 1, gk + GRID + 1, gk + GRID]:
		if wc[k] == 1:
			if order == 0 or fl[k] == FLOW_FOAM:
				flow = fl[k]
			order = maxi(order, od[k])
	if below_fall and not rim:
		flow = FLOW_FOAM                               # the pool just below a waterfall foams
	ch.flow[c] = flow
	ch.bank[c] = 0
	var river: Array = tiles.water.river
	# EA-01: one of the art's looks per cell (other ripples, a bank tuft on a corner step), so no lattice of streaks shows
	var cols := int(tiles.water.cols)
	var look := hash32(seed, wx, wy, 133) % int(tiles.water.looks) * int(tiles.water.look_rows)
	var tile := int(tiles.water.flow_base) + (look + flow * 16 + bits) * cols if not (river[bits] as Array).is_empty() else -1
	if rim:
		if wn[q] < 2:
			return                                     # a corner of the rim wet: the rock stays
		# a waterfall only where the water leaves a mountain top over its rim, heading down (south, as the rock face is
		# drawn): the top above, the low ground below. Elsewhere a wet rim cell is plain water cut through the rock.
		var falls: bool = fall
		# EA-01: elsewhere the course runs over the rim as rapids: foaming water, never the fall tile
		if not falls:
			ch.flow[c] = FLOW_FOAM
		ch.ground[c] = int(tiles.water.fall) if falls else int(tiles.water.flow_base) + (look + FLOW_FOAM * 16 + (bits if tile >= 0 else 15)) * cols
		ch.water[c] = 3 if falls else 1
		ch.level[c] = order
		ch.solid[c] = 1
		return
	if tile >= 0:
		ch.ground[c] = tile
	if foot and wn[q] == 4:
		ch.ground[c] = int(tiles.water.fall_foot)      # EA-01: the fall runs on into the cell below and splashes there
	if wn[q] >= 2:
		ch.level[c] = order
		if on_road and forced_crossing(Vector2i(wx, wy)) == "ford":
			ch.water[c] = 4                            # B25R1-018: a canonical ford: the road goes through the shallows (its edges: shallows)
			ch.solid[c] = 0
			ch.ground[c] = int(tiles.water.ford)       # EA-01: the stones all the way, so the way across shows (bank to bank)
		elif on_road:
			ch.water[c] = 2                            # a bridge: the road runs on over the water
			ch.solid[c] = 0
		elif shallows:
			ch.water[c] = 4                            # the shallows at a road's edge: walked through, no stones drawn
			ch.solid[c] = 0
		elif _area_fords.any(func(f: Array): return _in_ford(f, Vector2(wx, wy) + Vector2(0.5, 0.5))):
			ch.water[c] = 4                            # a ford: shallow water and stepping stones, walked across
			ch.solid[c] = 0
			if wn[q] == 4:
				ch.ground[c] = int(tiles.water.ford)   # the stones in open water; its banks keep their own shape
		else:
			ch.water[c] = 1
			ch.solid[c] = 1
			if wn[q] == 4 and not road_near and hash32(seed, wx, wy, 132) % 1000 < int(W.rock_in_water_permille) \
					and not _area_fords.any(func(f: Array): return (f[0] as Vector2).distance_to(Vector2(wx, wy)) <= float(f[1]) + 3.0):
				ch.deco[c] = int(tiles.rock)           # a rock in the water


## B25R1-018: region codes per cell corner of the area (GRID x GRID), from RegionGeo with the seed's edge jitter.
const R_NONE := 0
const R_DOWNS := 1
const R_WASTE := 2
const R_WOOD := 3
const R_VINE := 4
const R_VALE := 5
const R_FARM := 6
const R_HILLS := 7
const _R_OF := {"downs": R_DOWNS, "waste": R_WASTE, "great wood": R_WOOD, "vineyards": R_VINE, "wildwood valley": R_VALE,
	"farmland": R_FARM, "meadows": R_FARM, "hills": R_HILLS}


func _region_codes(ox: int, oy: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(GRID * GRID)
	for j in GRID:
		for i in GRID:
			out[j * GRID + i] = int(_R_OF.get(RegionGeo.kind_at(ox + i, oy + j, seed), R_NONE))
	return out


## The bare-ground corners of the cell whose top-left corner is `gk`: (bits, 1 chalk | 2 dry earth), (0, 0) when all grass.
## Bits as the cliff corners: 0 top-left, 1 top-right, 2 bottom-right, 3 bottom-left.
func _soil_bits(reg: PackedByteArray, fp: PackedInt32Array, fq: PackedInt32Array, gk: int) -> Vector2i:
	var bits := 0
	var kind := 0
	var idx := [gk, gk + 1, gk + GRID + 1, gk + GRID]
	for b in 4:
		var k: int = idx[b]
		if reg[k] == R_DOWNS and _chalk(fp[k], fq[k]):
			bits |= 1 << b
			kind = maxi(kind, 1)
		elif reg[k] == R_WASTE and fp[k] > 400:
			bits |= 1 << b
			kind = 2
	if kind == 2:                                       # a corner of chalk beside dry earth: drawn as earth (no chalk/earth tiles)
		bits = 0
		for b in 4:
			var k2: int = idx[b]
			if (reg[k2] == R_WASTE and fp[k2] > 400) or (reg[k2] == R_DOWNS and _chalk(fp[k2], fq[k2])):
				bits |= 1 << b
	return Vector2i(bits, kind)


## B25R1-018: bare chalk on the Downs where the turf is thin: small scars (the fine field high) gathered where the broad one is
## high too, so the down-turf stays whole between them.
static func _chalk(broad: int, fine: int) -> bool:
	return broad > 560 and fine > 760


## B25R1-018: the tile of a chalk-figure cell (the chalk path tile for its 4-neighbour bits, region_props.png 800008 + bits) or
## of a bank cell (Cozy Farm's rough-turf 3 x 3 patch as a 9-slice by which neighbours are bank).
func _figure_tile(c: Vector2i) -> int:
	if _chalk_cells.has(c):
		var bits := 0
		for k in 4:
			if _chalk_cells.has(c + [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][k]):
				bits |= 1 << k
		return 800008 + (bits if bits != 0 else 10)
	var row := 0 if not _bank_cells.has(c + Vector2i(0, -1)) else 2 if not _bank_cells.has(c + Vector2i(0, 1)) else 1
	var col := 0 if not _bank_cells.has(c + Vector2i(-1, 0)) else 2 if not _bank_cells.has(c + Vector2i(1, 0)) else 1
	return 200000 + row * 54 + col


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
	if site_building_at(c) or structure_at(c):
		return true                                    # REGION-NAV-01: a settlement's building (B25R1-018: or a landmark's)
	if not homes.is_empty() and home_building_at(c):
		return true                                    # B25R1-010: a homestead's house
	if works.has(c) or fixed_works.has(c):
		return false                                   # B14-07: steps, stairs or a walkway through the cliff's rim (B25R1-018: or the generator's)
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


## B25R1-017: the stable id of the crossing (a bridge or a ford) cell `c` belongs to: "crossing:bridge:<x>,<y>" or
## "crossing:ford:<x>,<y>", the first cell (by row, then column) of its joined cells; "" when `c` is no crossing. Cached.
var _crossing_ids := {}
var _crossing_boxes := {}
var crossings_seen := {}                 # "<who>|<crossing>" -> the game day it was last recorded (not saved; flight recorder)


func crossing_id(c: Vector2i) -> String:
	if _crossing_ids.has(c):
		return _crossing_ids[c]
	var kind := "bridge" if is_bridge(c) else "ford" if is_ford(c) else ""
	if kind == "":
		return ""
	var seen := {c: true}
	var todo: Array[Vector2i] = [c]
	var k := 0
	var first := c
	while k < todo.size() and todo.size() < 200:
		var at: Vector2i = todo[k]
		k += 1
		if at.y < first.y or (at.y == first.y and at.x < first.x):
			first = at
		for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var n: Vector2i = at + d
			if not seen.has(n) and (is_bridge(n) if kind == "bridge" else is_ford(n)):
				seen[n] = true
				todo.append(n)
	var id := "crossing:%s:%d,%d" % [kind, first.x, first.y]
	var lo := first
	var hi := first
	for cell: Vector2i in seen:
		_crossing_ids[cell] = id
		lo = lo.min(cell)
		hi = hi.max(cell)
	_crossing_boxes[id] = Rect2i(lo, hi - lo + Vector2i.ONE)
	return id


## B25R1-017: the cells a crossing covers (its bounding box): a bridge runs the long way of it.
func crossing_box(c: Vector2i) -> Rect2i:
	var id := crossing_id(c)
	return _crossing_boxes.get(id, Rect2i(c, Vector2i.ONE))


## B25R1-017: the flow direction of a water cell (1-8 E, SE, S, SW, W, NW, N, NE downstream; 0 still; 9 foaming), 0 when dry.
func flow_at(c: Vector2i) -> int:
	if gen < 4 or village.has_point(c):
		return 0
	var ch := get_chunk(chunk_of(c))
	return ch.flow[_cell_of(ch, c)]


## B25R1-017: the water level of a cell (its course's order, 1 stream, 2 river, times seasonal_flow; a level set_level gave
## wins), 0 for dry ground. The weather extension's reading point.
func water_level(c: Vector2i) -> float:
	if level_override.has(c):
		return float(level_override[c])
	if gen < 4 or village.has_point(c):
		return 0.0
	var ch := get_chunk(chunk_of(c))
	return float(ch.level[_cell_of(ch, c)]) * seasonal_flow


## B25R1-017: a dry cell's height above the nearest water's edge in tiles (the floodplain, 1-6), 0 for water, 255 when far.
func bank_height(c: Vector2i) -> int:
	if gen < 4 or village.has_point(c):
		return 255
	var ch := get_chunk(chunk_of(c))
	return ch.bank[_cell_of(ch, c)]


## B25R1-017: the weather extension's writing point (rain and floods): set a cell's water level; on_level_changed hears it.
## Nothing calls it in Build 25 Revision 1 (the water is constant); a later system also decides what a level means for
## walking, saving and drawing.
func set_level(c: Vector2i, lvl: float) -> void:
	var old := water_level(c)
	level_override[c] = lvl
	if on_level_changed.is_valid():
		on_level_changed.call(c, old, lvl)


## B25R1-Q3: whether cell `c` is a bridge (a road over a stream).
func is_bridge(c: Vector2i) -> bool:
	if gen < 4 or village.has_point(c):
		return false
	var ch := get_chunk(chunk_of(c))
	return ch.water[_cell_of(ch, c)] == 2


const NO_WATER := Vector2i(1 << 30, 0)          # B25R1-017: the agreed "none" of nearest_water (the homestead worker's signature)


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


## B25R1-017: the waterfall cell nearest `c` within `radius` tiles (Chebyshev rings), or NO_WATER.
func nearest_fall(c: Vector2i, radius: int) -> Vector2i:
	if gen < 4:
		return NO_WATER
	for r in range(0, radius + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var n := c + Vector2i(dx, dy)
				if village.has_point(n):
					continue
				var ch := get_chunk(chunk_of(n))
				if ch.water[_cell_of(ch, n)] == 3:
					return n
	return NO_WATER


## B25R1-Q3: where to stand to drink: the open cell beside the water nearest `c` within `radius` (the bank), or NO_WATER.
## B25R1-018: `wells` (optional) is the one well registry's lookup, `w.wilds.wells_near` (cell, radius) -> nearest first,
## each a well record (its cell as `cell`, or `x` and `y`) or a Vector2i: Overworld keeps no well data and has no World, so
## the caller passes it; a well nearer than the stream's bank wins (its own cell: a well is stood at). nearest_water stays
## streams only, with its agreed signature.
func nearest_water_access(c: Vector2i, radius: int, wells: Callable = Callable()) -> Vector2i:
	var well := NO_WATER
	if wells.is_valid():
		var list: Variant = wells.call(c, radius)
		if list is Array and not (list as Array).is_empty():
			var e: Variant = list[0]
			if e is Vector2i:
				well = e
			elif e is Dictionary:
				well = Vector2i(e.cell) if (e as Dictionary).has("cell") else Vector2i(int(e.get("x", 0)), int(e.get("y", 0)))
	var bank := _bank_access(c, radius)
	if well == NO_WATER:
		return bank
	if bank == NO_WATER or Vector2(well).distance_to(Vector2(c)) <= Vector2(bank).distance_to(Vector2(c)):
		return well
	return bank


func _bank_access(c: Vector2i, radius: int) -> Vector2i:
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
	if village.has_point(c) or works.has(c) or fixed_works.has(c):
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
		_river_cache.clear()
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
