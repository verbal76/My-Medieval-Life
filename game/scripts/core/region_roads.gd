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


## The cells (Vector2i -> true) of the roads joining the village's gates and the settlements to one another: the "road" kind.
## Computed once per overworld (a pure function of the seed) and kept on it.
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
			for c in ow.route_between(ends[a], ends[b], false):
				cells[Vector2i(c)] = true
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
