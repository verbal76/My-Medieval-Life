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
	var cells := {}
	var ends: Array = []
	for g in ow.gates.size():
		ends.append(ow._gate_end(g))
	for st in ow.sites:
		ends.append(ow._site_end(str(st.id)))
	for a in ends.size():
		for b in range(a + 1, ends.size()):
			if a < ow.gates.size() and b < ow.gates.size():
				continue                          # gate to gate goes round the village: not a road between places
			var seen := {}
			for c in ow.route_between(ends[a], ends[b], false):
				var ci := Vector2i(c)
				if not seen.has(ci):
					seen[ci] = true
					cells[ci] = int(cells.get(ci, 0)) + 1
	ow.set_meta("b25r1_main_roads", cells)
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
##   stone  improved sections: a main road's approach to the village and to each settlement (within STONE_NEAR tiles of its
##          rectangle), and its most travelled stretches (at least STONE_HEAVY of the routes between places pass along it); and
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
	var places: Array[Rect2i] = [ow.village.grow(STONE_NEAR)]
	for st in ow.sites:
		places.append((st.rect as Rect2i).grow(STONE_NEAR))
	for c: Vector2i in main:
		var stone := int(main[c]) >= STONE_HEAVY
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
	if lane_cells(ow).has(c):
		return "stone"
	if not ow.is_road(c):
		return ""
	return str(main_kinds(ow).get(c, "trail"))
