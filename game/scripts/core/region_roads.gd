class_name RegionRoads
extends RefCounted
## B25R1-003 / B25R1-004 (owner directive 2026-11-03, sections 1 and 2): the region's roads read straight from the overworld's
## own road network (Overworld: the jittered node grid, its edges and the village gates' and settlements' links), without
## generating a chunk, so the Region map can draw every established road from day 1 exactly where the playable world has it,
## and the player's travel planner (RegionTravel) can join and follow it. The same edges, by the same rules, as
## Overworld._road_mask and Overworld._node_edges: a segment listed here is road cells in the world, walkable (a road and one
## tile round it never hold a cliff, tree or rock), and nothing else is listed (no decorative road).
##
## Two kinds, both real (docs/region_nav/ROADS_AUDIT_B25R1.md): "road", the cells of the roads that join the village and the
## settlements to one another (the routes the regional trade measures, Overworld.route_between), and "trail", the rest of the
## network. In the world both are drawn with the same dirt path tiles (the tileset has no stone road); the map tells them apart.
## Pure reads: nothing here changes the world, a chunk, a ledger, a coin or an item.

const NONE := Vector2i(-1073741824, -1073741824)       # no road node at that end of a segment


## Every road segment whose cells may lie in `area` (tiles): {cells: PackedInt32Array (x, y pairs), na, nb (road node grid ids
## at its two ends; NONE for a link's far end), link (index into Overworld._links, -1 for a network edge), base (true for a
## gate's or settlement's own spur, which ends at no node)}.
static func segments(ow: Overworld, area: Rect2i) -> Array:
	var out := []
	var keep := Rect2i(ow.village.grow(10))
	var i0 := Overworld.fdiv(area.position.x - 14, Overworld.NODE) - 2
	var i1 := Overworld.fdiv(area.end.x + 14, Overworld.NODE) + 1
	var j0 := Overworld.fdiv(area.position.y - 14, Overworld.NODE) - 2
	var j1 := Overworld.fdiv(area.end.y + 14, Overworld.NODE) + 1
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var a := ow.node_pos(i, j)
			if ow._node_excluded(a):
				continue
			for k in 4:
				var ni: int = i + [1, 0, 1, -1][k]
				var nj: int = j + [0, 1, 1, 1][k]
				var b := ow.node_pos(ni, nj)
				if ow._node_excluded(b) or not ow._edge(i, j, k):
					continue
				var box := Rect2i(mini(a.x, b.x) - 12, mini(a.y, b.y) - 12, absi(a.x - b.x) + 24, absi(a.y - b.y) + 24)
				if not box.intersects(area):
					continue
				var bb := Rect2i(mini(a.x, b.x), mini(a.y, b.y), absi(a.x - b.x), absi(a.y - b.y))
				if bb.intersects(keep) or ow._crosses_site(bb):
					continue
				out.append({"cells": ow._segment(Vector3i(i, j, k), a, b, (i * 7919 + j * 104729 + k) & 0xFFFFFF),
					"na": Vector2i(i, j), "nb": Vector2i(ni, nj), "link": -1, "base": false})
	for li in ow._links.size():
		var l: Dictionary = ow._links[li]
		var a2: Vector2i = l.a
		var b2: Vector2i = l.b
		var box2 := Rect2i(mini(a2.x, b2.x) - 12, mini(a2.y, b2.y) - 12, absi(a2.x - b2.x) + 24, absi(a2.y - b2.y) + 24)
		if not box2.intersects(area):
			continue
		var base := int(l.key) % 8 == 0
		out.append({"cells": ow._segment(Vector3i(li, 0, -1), a2, b2, int(l.key)), "na": NONE,
			"nb": NONE if base else ow._node_of(b2), "link": li, "base": base})
	return out


## The cells of the roads joining the village's gates and the settlements to one another (Vector2i -> how many of those routes
## pass along it, each pair of places once): the main roads. Computed once per overworld (a pure function of the seed), kept on it.
static func main_cells(ow: Overworld) -> Dictionary:
	if ow.has_meta("b25r1_main_roads"):
		return ow.get_meta("b25r1_main_roads")
	var cells := _pair_cells(ow, true)
	ow.set_meta("b25r1_main_roads", cells)
	return cells


## The busy count for paving (B25R1-Q1 "busy stretches"): as main_cells, over the pairs of the village and the towns only.
## The hamlets (B25R1-018 section 5) are small places off the main roads: their roads are main roads (dirt), but their pairs do
## not make a stretch busy. (Counted over every pair, the 15 places of Revision 1 made 120 pairs against STONE_HEAVY 14, and
## most main road cells read as stone: 4883 of 9368 on seed 1 after the settle merge, against 914 of 4648 at a8d3886.)
static func busy_cells(ow: Overworld) -> Dictionary:
	if ow.has_meta("b25r1_busy_roads"):
		return ow.get_meta("b25r1_busy_roads")
	var cells := _pair_cells(ow, false)
	ow.set_meta("b25r1_busy_roads", cells)
	return cells


static func _pair_cells(ow: Overworld, hamlets: bool) -> Dictionary:
	var cells := {}
	var ends: Array = []
	for g in ow.gates.size():
		ends.append(ow._gate_end(g))
	for st in ow.sites:
		ends.append(ow._site_end(str(st.id)) if hamlets or not bool(st.get("hamlet", false)) else {})
	var ng := ow.gates.size()
	for b in range(ng, ends.size()):
		if (ends[b] as Dictionary).is_empty():
			continue
		# each pair of places once (B25R1-018): the village's gates are one place, so a cell on the roads from several of its
		# gates to a settlement counts that pair once; then the busy count is how many pairs of places use a stretch, not how
		# many gates the village has (with one main road through the region every stretch would otherwise count as busy)
		for a in b:
			if a > 0 and a < ng:
				continue                          # the village's other gates: walked with gate 0 below
			if (ends[a] as Dictionary).is_empty():
				continue
			var seen := {}
			for g in (range(ng) if a == 0 else [a]):
				for c in ow.route_between(ends[g], ends[b], false):
					var ci := Vector2i(c)
					if not seen.has(ci):
						seen[ci] = true
						cells[ci] = int(cells.get(ci, 0)) + 1
	return cells


## "road" or "trail" for a segment of `segments`: a road when most of its cells are on the roads between places.
static func kind_of(ow: Overworld, seg: Dictionary) -> String:
	var main := main_cells(ow)
	var cells: PackedInt32Array = seg.cells
	var n := cells.size() / 2
	if n == 0:
		return "trail"
	var on := 0
	for q in n:
		if main.has(Vector2i(cells[q * 2], cells[q * 2 + 1])):
			on += 1
	return "road" if on * 2 >= n else "trail"


# ------------------------------------------------------------------ the road hierarchy (B25R1-Q1) ---------------
## Owner decision B25R1-Q1 (2026-11-03): three road types, from the network's own data, on the same cells (so walking, routes
## and saves are unchanged):
##   stone  improved sections: a main road's approach to the village and to each settlement (within STONE_NEAR tiles of a
##          way in: a gate or a side entry), and its most travelled stretches (at least STONE_HEAVY of the routes between the village and
##          the towns pass along it, busy_cells); and
##          each settlement's street (the middle row of each lane its doors open onto, lane_cells). The overworld has no rivers,
##          so there is no bridge or ford to pave.
##   road   the dirt roads between the places: the rest of main_cells.
##   trail  every other road cell of the network: the secondary ways off into the country.
const STONE_NEAR := 24
const STONE_HEAVY := 14


## Main road cell -> "stone" or "road" (cached on the overworld).
static func main_kinds(ow: Overworld) -> Dictionary:
	if ow.has_meta("b25r1_road_kinds"):
		return ow.get_meta("b25r1_road_kinds")
	var out := {}
	var main := main_cells(ow)
	var busy := busy_cells(ow)
	# B25R1-018: the approach is the road within STONE_NEAR of a way into a place (a village gate, a settlement's gate or side
	# entry) and the place's own ground, not every road within STONE_NEAR of its rectangle: a road round a settlement
	# (Overworld._site_ring) is a dirt road by it, not the paved way in
	var places: Array[Rect2i] = [ow.village]
	for g in ow.gates:
		places.append(Rect2i(Vector2i(g.out), Vector2i.ONE).grow(STONE_NEAR))
	for st in ow.sites:
		places.append(st.rect)
		for e: Vector2i in ow.site_entries(str(st.id)):
			places.append(Rect2i(e, Vector2i.ONE).grow(STONE_NEAR))
	for c: Vector2i in main:
		var stone := int(busy.get(c, 0)) >= STONE_HEAVY
		if not stone:
			for r in places:
				if r.has_point(c):
					stone = true
					break
		out[c] = "stone" if stone else "road"
	ow.set_meta("b25r1_road_kinds", out)
	return out


## The settlements' streets: the middle row of each lane under a row of buildings, from the site's margin to margin, on open
## ground (Vector2i -> true; cached). Walkable already (a lane is never built on); paving it changes no rule.
static func lane_cells(ow: Overworld) -> Dictionary:
	if ow.has_meta("b25r1_lanes"):
		return ow.get_meta("b25r1_lanes")
	var out := {}
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/settlements.json"))
	var lay: Dictionary = data.site
	var bh := int(ow.stamps.house.h)
	for st in ow.sites:
		if st.has("streets"):                       # B25R1-018: the site's own streets (Overworld._site_plan)
			for cells in st.streets:
				for c: Vector2i in cells:
					if not ow.site_building_at(c):
						out[c] = true
			continue
		var r: Rect2i = st.rect
		var rows := (r.size.y - 2 * int(lay.margin)) / (bh + int(lay.lane))
		for k in rows:
			var y := r.position.y + int(lay.margin) + k * (bh + int(lay.lane)) + bh + int(lay.lane) / 2
			for x in range(r.position.x + int(lay.margin), r.end.x - int(lay.margin)):
				var c := Vector2i(x, y)
				if not ow.site_building_at(c):
					out[c] = true
	ow.set_meta("b25r1_lanes", out)
	return out


## The type of a road cell: "stone", "road" or "trail" (a settlement's street is stone); "" for a cell that is no road.
static func cell_kind(ow: Overworld, c: Vector2i) -> String:
	# Perf (B25R1 gate on 2677ea7): the answer is the generator's alone (lanes, the chunk's road bit, the main road kinds:
	# nothing changes them after generation), so it is kept per cell. Without it a sweep over the stored road cells (the
	# recorder's roads_dawn, RoadWear.prune; sorted by column) asked Overworld.is_road for cells across the whole region, and
	# the chunk cache (MAX_CACHED) regenerated the same chunks again and again: 7.6 s a dawn at f60772f, 14.8 s with
	# 0c1aeb3's denser roads. Kept or not, every answer is the same; the memo is only emptied when it grows large.
	var memo: Dictionary
	if ow.has_meta("b25r1_cell_kinds"):
		memo = ow.get_meta("b25r1_cell_kinds")
	else:
		memo = {}
		ow.set_meta("b25r1_cell_kinds", memo)
	var k = memo.get(c)
	if k != null:
		return k
	if memo.size() > 200000:
		memo.clear()
	var out := "stone" if lane_cells(ow).has(c) else ("" if not ow.is_road(c) else str(main_kinds(ow).get(c, "trail")))
	memo[c] = out
	return out
