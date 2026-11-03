class_name RegionTravel
extends RefCounted
## B25R1-006 (owner directive 2026-11-03, section 4, "Tap anywhere to travel"): the player's chosen destination and the route to
## it. The player taps any point of the Region map; plan() checks it can be stood on and reached on foot, and lays out a walking
## route from where they stand: the established roads where that is reasonably efficient (an off-road cell counts OFF_ROAD road
## cells), the road network followed node to node by the same edges the world draws (RegionRoads, Overworld._node_edges), then
## off the road to the point itself. The character walks it in the real world (TravelDriver feeds Main's own move_to walking: no
## teleport, time, hunger and encounters go on), and any manual input suspends it.
##
## PlayerState.travel (saved, optional): {x, y, active}: the destination cell and whether the character is walking to it now.
## The route is never saved: it is planned again from where the player stands (a loaded save, Resume). A destination that can no
## longer be reached is refused with a message, never walked at for ever (TravelDriver gives up after bounded attempts).
## Player-only: nothing here touches an NPC, a ledger, a coin, an item or the world's random numbers.

const OFF_ROAD := 1.8          # an off-road cell costs this many road cells (roads are preferred where reasonably efficient)
const NEAR := 192              # tiles round a point searched for a road to join (two road-node spacings)
const CHECK := 110             # an off-road leg at most this long (each axis) is checked on foot by the pathfinder
const SNAP := 4                # a tapped cell that cannot be stood on moves to the nearest open cell this close
const TRIES := 4               # road ends tried when the last leg off the road finds no way
const POCKET := 40             # open ground reaching this far round a point is not a closed pocket (enclosed)


## Whether `c` can be stood on in the open world (the surface; a settlement's building or a tree cannot).
static func _open(w: World, c: Vector2i) -> bool:
	return not w.map.is_solid_world(c)


## B25R1-017: why no way was found, for the flight recorder: "water_no_crossing" when water lies round the destination,
## else "unreachable".
static func _no_way(ow: Overworld, dest: Vector2i) -> String:
	return "water_no_crossing" if ow.nearest_water(dest, 6) != Overworld.NO_WATER else "unreachable"


## The open cell nearest `c` within SNAP (itself when open), or NONE.
static func snap(w: World, c: Vector2i) -> Vector2i:
	if _open(w, c):
		return c
	for r in range(1, SNAP + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) == r and _open(w, c + Vector2i(dx, dy)):
					return c + Vector2i(dx, dy)
	return RegionRoads.NONE


static func _oct(a: Vector2i, b: Vector2i) -> float:
	var dx := absi(a.x - b.x)
	var dy := absi(a.y - b.y)
	return maxi(dx, dy) + 0.4142 * mini(dx, dy)


## B25R1-011: the cost of going straight from a to b: a cell that is a way (generated or worn in by footfall, RoadWear) costs
## one, open country OFF_ROAD, so a path worn across the country is preferred as a road is.
static func _line_cost(w: World, a: Vector2i, b: Vector2i) -> float:
	var ow: Overworld = w.map.overworld
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	if n == 0:
		return 0.0
	var per := _oct(a, b) / float(n)
	var cost := 0.0
	for k in range(1, n + 1):
		var c := Vector2i((Vector2(a).lerp(Vector2(b), k / float(n))).round())
		cost += per * (1.0 if RoadWear.is_way(ow, c) else OFF_ROAD)
	return cost


## Whether the pathfinder walks from a to b (it returns a partial path when it cannot reach b: the last cell must be b).
static func walkable(w: World, a: Vector2i, b: Vector2i) -> bool:
	if a == b:
		return true
	var path := w.map.find_path_world(a, b)
	return not path.is_empty() and Vector2i(path[path.size() - 1]).distance_to(b) <= 1.5


## Whether open ground round `c` is a closed pocket (a mountain top inside its rim, a ring of trees): the cells reached from it
## run out before any lies POCKET tiles away. A pocket is never reached on foot, however far from a road it lies.
static func enclosed(w: World, c: Vector2i) -> bool:
	var seen := {c: true}
	var todo: Array[Vector2i] = [c]
	var k := 0
	while k < todo.size():
		var at: Vector2i = todo[k]
		k += 1
		if maxi(absi(at.x - c.x), absi(at.y - c.y)) >= POCKET:
			return false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = at + d
			if not seen.has(n) and _open(w, n):
				seen[n] = true
				todo.append(n)
	return true


## The ways from point `p` onto the road network: node grid id -> {cost, cells: PackedVector2Array from p to the node}.
## In the village, by its gates' roads; in a settlement, by its own road; elsewhere, off the road to the nearest cell of each
## road segment near it (both ways along it).
static func _attach(w: World, p: Vector2i) -> Dictionary:
	var ow: Overworld = w.map.overworld
	var out := {}
	var ends: Array = []                                    # [first cell walked to, its end dictionary]
	if ow.village.has_point(p):
		for g in ow.gates.size():
			ends.append([Vector2i(ow.gates[g].out), ow._gate_end(g)])
	elif not ow.site_at(p).is_empty():
		var st := ow.site_at(p)
		ends.append([Vector2i(st.gate), ow._site_end(str(st.id))])
	for e in ends:
		var end: Dictionary = e[1]
		if end.is_empty():
			continue
		var base: Dictionary = ow._links[int(end.base)]
		var base_cells := ow._segment(Vector3i(int(end.base), 0, -1), base.a, base.b, int(base.key))
		for nd: Vector2i in end.nodes:
			var li: int = end.nodes[nd]
			var l: Dictionary = ow._links[li]
			var lc := ow._segment(Vector3i(li, 0, -1), l.a, l.b, int(l.key))
			var cells := PackedVector2Array([Vector2(p)])
			_add(cells, base_cells, 0, base_cells.size() / 2 - 1)
			_add(cells, lc, 0, lc.size() / 2 - 1)
			var cost := absi(p.x - Vector2i(e[0]).x) + absi(p.y - Vector2i(e[0]).y) + base_cells.size() / 2 + lc.size() / 2
			_keep(out, nd, cost, cells)
	if not ends.is_empty():
		return out
	for seg in RegionRoads.segments(ow, Rect2i(p - Vector2i(NEAR, NEAR), Vector2i(NEAR, NEAR) * 2)):
		if bool(seg.base):
			continue
		var sc: PackedInt32Array = seg.cells
		var n := sc.size() / 2
		var q := 0
		var bd := INF
		for k in n:
			var d := _oct(p, Vector2i(sc[k * 2], sc[k * 2 + 1]))
			if d < bd:
				bd = d
				q = k
		if bd > NEAR:
			continue
		var off := bd * OFF_ROAD
		if seg.nb != RegionRoads.NONE:
			var cells := PackedVector2Array([Vector2(p)])
			_add(cells, sc, q, n - 1)
			_keep(out, seg.nb, off + (n - 1 - q), cells)
		if seg.na != RegionRoads.NONE:
			var cells2 := PackedVector2Array([Vector2(p)])
			_add(cells2, sc, q, 0)
			_keep(out, seg.na, off + q, cells2)
	return out


static func _keep(out: Dictionary, nd: Vector2i, cost: float, cells: PackedVector2Array) -> void:
	if not out.has(nd) or cost < float(out[nd].cost):
		out[nd] = {"cost": cost, "cells": cells}


## Cells a..b (inclusive, either direction) of an x, y cell list, appended without repeating the last cell.
static func _add(out: PackedVector2Array, cells: PackedInt32Array, a: int, b: int) -> void:
	var step := 1 if b >= a else -1
	var q := a
	while true:
		var c := Vector2(cells[q * 2], cells[q * 2 + 1])
		if out.is_empty() or out[out.size() - 1] != c:
			out.append(c)
		if q == b:
			break
		q += step


static func _reversed(cells: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in range(cells.size() - 1, -1, -1):
		out.append(cells[q])
	return out


## The cheapest way over the road network from the start attachments to the goal attachments (Dijkstra over the same edges
## the chunks draw, ties by node order, so the same seed always gives the same route): {cost, cells} or {}.
static func _network(ow: Overworld, starts: Dictionary, goals: Dictionary, lo: Vector2i, hi: Vector2i) -> Dictionary:
	var dist := {}
	var prev := {}
	var open: Array = []
	for nd: Vector2i in starts:
		if ow.closed.has(nd):
			continue
		dist[nd] = float(starts[nd].cost)
		open.append([float(starts[nd].cost), nd.y, nd.x])
	var best := INF
	var goal := RegionRoads.NONE
	while not open.is_empty():
		open.sort()
		var top: Array = open.pop_front()
		if float(top[0]) >= best:
			break
		var nd := Vector2i(int(top[2]), int(top[1]))
		if float(top[0]) > float(dist.get(nd, INF)):
			continue
		if goals.has(nd):
			var whole := float(top[0]) + float(goals[nd].cost)
			if whole < best:
				best = whole
				goal = nd
		for e in ow._node_edges(nd):
			var nb: Vector2i = e[0]
			if nb.x < lo.x or nb.y < lo.y or nb.x > hi.x or nb.y > hi.y or ow.closed.has(nb):
				continue
			var cost := float(top[0]) + float(e[1])
			if cost < float(dist.get(nb, INF)):
				dist[nb] = cost
				prev[nb] = [nd, e[2]]
				open.append([cost, nb.y, nb.x])
	if goal == RegionRoads.NONE:
		return {}
	var chain: Array = []
	var at := goal
	while prev.has(at):
		chain.push_front(prev[at][1])
		at = prev[at][0]
	var cells := PackedVector2Array()
	for c in starts[at].cells:
		cells.append(c)
	for seg in chain:                                         # [i, j, k, forward]
		var i := int(seg[0])
		var j := int(seg[1])
		var k := int(seg[2])
		var ni: int = i + [1, 0, 1, -1][k]
		var nj: int = j + [0, 1, 1, 1][k]
		var sc := ow._segment(Vector3i(i, j, k), ow.node_pos(i, j), ow.node_pos(ni, nj), (i * 7919 + j * 104729 + k) & 0xFFFFFF)
		var n := sc.size() / 2
		if bool(seg[3]):
			_add(cells, sc, 0, n - 1)
		else:
			_add(cells, sc, n - 1, 0)
	for c in goals[goal].cells:
		if cells.is_empty() or cells[cells.size() - 1] != c:
			cells.append(c)
	return {"cost": best, "cells": cells, "goal": goal}


## A walking route from `from` to the tapped cell `to`: {ok: true, dest, cells (waypoints: road cells one by one, an off-road
## leg as its two ends), road (cells walked on the road network), direct (true when it goes straight off the road)} or
## {ok: false, why}. The destination must be on the surface, open (or an open cell within SNAP of it) and reachable on foot.
static func plan(w: World, from: Vector2i, to: Vector2i) -> Dictionary:
	var ow: Overworld = w.map.overworld
	if ow == null:
		return {"ok": false, "why": "There is no open country to travel in."}
	if w.player_level != Underground.SURFACE:
		return {"ok": false, "why": "Come up to the surface first."}
	var dest := snap(w, to)
	if dest == RegionRoads.NONE:
		if ow.is_water(to):                              # B25R1-017: the middle of a river: no bank within reach
			return {"ok": false, "why": "That is open water: pick the bank, a bridge or a ford.", "reason": "water_destination"}
		return {"ok": false, "why": "You cannot stand there: pick open ground.", "reason": "solid"}
	if dest == from:
		return {"ok": false, "why": "You are already there."}
	if not ow.village.has_point(dest) and ow.site_at(dest).is_empty() and enclosed(w, dest):
		return {"ok": false, "why": "There is no way there on foot that you can find.", "reason": _no_way(ow, dest)}
	var direct := {}
	var span := Vector2i(absi(dest.x - from.x), absi(dest.y - from.y))
	var both_village := ow.village.has_point(from) and ow.village.has_point(dest)
	var same_site := not ow.site_at(from).is_empty() and ow.site_at(from) == ow.site_at(dest)
	if both_village or same_site or (span.x <= CHECK and span.y <= CHECK):
		if both_village or walkable(w, from, dest):
			direct = {"cost": _oct(from, dest) if both_village or same_site else _line_cost(w, from, dest),
				"cells": PackedVector2Array([Vector2(from), Vector2(dest)])}
	if both_village or same_site:
		return {"ok": true, "dest": dest, "cells": direct.cells, "road": 0, "direct": true} if not direct.is_empty() \
				else {"ok": false, "why": "There is no way there on foot."}
	var starts := _attach(w, from)
	var goals_out := _attach(w, dest)
	var goals := {}
	for nd: Vector2i in goals_out:
		goals[nd] = {"cost": goals_out[nd].cost, "cells": _reversed(goals_out[nd].cells)}
	var lo := Vector2i(mini(Overworld.fdiv(from.x, Overworld.NODE), Overworld.fdiv(dest.x, Overworld.NODE)) - 4,
		mini(Overworld.fdiv(from.y, Overworld.NODE), Overworld.fdiv(dest.y, Overworld.NODE)) - 4)
	var hi := Vector2i(maxi(Overworld.fdiv(from.x, Overworld.NODE), Overworld.fdiv(dest.x, Overworld.NODE)) + 4,
		maxi(Overworld.fdiv(from.y, Overworld.NODE), Overworld.fdiv(dest.y, Overworld.NODE)) + 4)
	var by_road := {}
	var wild := ow.site_at(dest).is_empty() and not ow.village.has_point(dest)
	for t in TRIES:
		if starts.is_empty() or goals.is_empty():
			break
		var r := _network(ow, starts, goals, lo, hi)
		if r.is_empty():
			break
		if not wild:
			by_road = r
			break
		# the last leg leaves the road for the point itself: it must be walkable (a mountain top inside its rim is not)
		var cells: PackedVector2Array = goals[r.goal].cells
		var join := Vector2i(cells[0])
		var leg := Vector2i(absi(dest.x - join.x), absi(dest.y - join.y))
		if leg.x > CHECK or leg.y > CHECK or walkable(w, join, dest):
			by_road = r
			break
		goals.erase(r.goal)
	if by_road.is_empty() and direct.is_empty():
		return {"ok": false, "why": "There is no way there on foot that you can find.", "reason": _no_way(ow, dest)}
	if direct.is_empty() or (not by_road.is_empty() and float(by_road.cost) < float(direct.cost)):
		var main := RegionRoads.main_cells(ow)
		return {"ok": true, "dest": dest, "cells": by_road.cells, "road": _on_road(w, by_road.cells), "direct": false,
			"main": _count(by_road.cells, main)}
	return {"ok": true, "dest": dest, "cells": direct.cells, "road": 0, "direct": true}


static func _on_road(w: World, cells: PackedVector2Array) -> int:
	var n := 0
	for c in cells:
		if w.map.overworld.is_road(Vector2i(c)):
			n += 1
	return n


static func _count(cells: PackedVector2Array, among: Dictionary) -> int:
	var n := 0
	for c in cells:
		if among.has(Vector2i(c)):
			n += 1
	return n


# ------------------------------------------------------------------ the destination --------------
static func has_destination(p: PlayerState) -> bool:
	return not p.travel.is_empty()


static func destination(p: PlayerState) -> Vector2i:
	return Vector2i(int(p.travel.get("x", 0)), int(p.travel.get("y", 0)))


static func active(p: PlayerState) -> bool:
	return has_destination(p) and bool(p.travel.get("active", false))


## Choose `cell` as the destination and set off (a plan that fails changes nothing and says why). Returns the plan.
static func choose(w: World, p: PlayerState, cell: Vector2i) -> Dictionary:
	var r := plan(w, Vector2i(p.pos.floor()), cell)
	if bool(r.ok):
		p.travel = {"x": int(r.dest.x), "y": int(r.dest.y), "active": true}
	return r


static func dismiss(p: PlayerState) -> void:
	p.travel = {}


static func suspend(p: PlayerState) -> void:
	if has_destination(p):
		p.travel.active = false


## The name of a destination: the settlement or the village it lies in, a landmark the player knows beside it, else a plain
## "the marked place".
static func place_name(w: World, p: PlayerState, c: Vector2i) -> String:
	var ow: Overworld = w.map.overworld
	if ow != null:
		if ow.village.has_point(c):
			return "your home village"
		var st := ow.site_at(c)
		if not st.is_empty():
			return str(st.name)
	for id in p.landmarks:
		var lm: Dictionary = p.landmarks[id]
		if Vector2i(int(lm.x), int(lm.y)).distance_to(c) <= 4.0:
			return str(lm.name)
	return "the marked place"


## "12 mi S" from `a` to `b`: miles by the regional scale (settlements.json tiles_per_mile), and one of eight directions.
static func bearing(a: Vector2, b: Vector2, tiles_per_mile := 12.0) -> String:
	var d := b - a
	var miles := d.length() / tiles_per_mile
	var dist := ("%.1f mi" % miles) if miles < 10.0 else ("%d mi" % roundi(miles))
	if d.length() < 2.0:
		return "here"
	var names := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]                    # screen y grows southward
	var k := posmod(roundi(d.angle() / (PI / 4.0)), 8)
	return "%s %s" % [dist, names[k]]


# ------------------------------------------------------------------ save -------------------
static func to_save(p: PlayerState) -> Dictionary:
	return {"x": int(p.travel.x), "y": int(p.travel.y), "active": bool(p.travel.get("active", false))}


static func load_into(p: PlayerState, d: Dictionary) -> void:
	var t: Variant = d.get("travel", {})
	p.travel = {}
	if t is Dictionary and (t as Dictionary).has("x") and (t as Dictionary).has("y"):
		p.travel = {"x": int(t.x), "y": int(t.y), "active": bool(t.get("active", false))}
