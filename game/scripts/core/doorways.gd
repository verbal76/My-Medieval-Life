class_name Doorways
extends RefCounted
## ROOMS-18 (owner OD-05, 2026-10-23): inner doorways between the rooms of one property.
##
## Rooms are separate buildings standing against one another (docs/BUILD_DECISIONS.md "Modular property"); where two
## of them stand side by side on the same property, their side walls meet. A doorway is a gap cut through both walls
## at one row, made of what the stamps already draw (the wall tile goes, the room's own floor shows in its place;
## nothing is drawn that was not drawn before). It exists only where nothing is in the way: the wall cell on each
## side must be the plain side wall, and the floor cell just inside it must be free of furniture and reachable from the
## room's street door. So it is derived, never saved: the same buildings give the same doorway on every load, and
## nothing earlier is changed (no furniture is moved, the street doors stay). Rooms stacked north and south have a
## yard between their walls and no shared wall, so they get no doorway.
##
## Pure rules and queries; World.index_interiors opens the cells (collision, interior area and floor), the view
## (main.gd) draws the gap, Construction.find_module_slot prefers ground where a doorway can be cut.

const WALL := 278                  # the stamps' plain side wall tile (below0), at both side walls, every wall row


## Rows of a stamp where a doorway can be cut through its east (or west) wall: the wall cell is the plain wall, the
## floor cell just inside is free and reachable from the room's door.
static func open_rows(stamp: Dictionary, east: bool) -> Array:
	var out := []
	if stamp.is_empty() or not stamp.has("interior"):
		return out
	var w := int(stamp.w)
	var h := int(stamp.h)
	var solid: Array = stamp.solid
	var floor := {}
	for c in stamp.interior.floor:
		floor[Vector2i(int(c[0]), int(c[1]))] = true
	var seen := _reached(stamp, floor)
	var wall_x := w - 1 if east else 0
	var in_x := w - 2 if east else 1
	var below0: Array = stamp.layers.get("below0", [])
	for y in h:
		if below0.is_empty() or int(below0[y * w + wall_x]) != WALL or str(solid[y])[wall_x] != "1":
			continue
		if floor.has(Vector2i(in_x, y)) and str(solid[y])[in_x] == "0" and seen.has(Vector2i(in_x, y)):
			out.append(y)
	return out


## The stamp's walkable floor cells reached from its street door.
static func _reached(stamp: Dictionary, floor: Dictionary) -> Dictionary:
	var seen := {}
	var door := Vector2i(int(stamp.interior.doors[0][0]), int(stamp.interior.doors[0][1]))
	var todo := [door]
	seen[door] = true
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if seen.has(n) or not floor.has(n) or str((stamp.solid as Array)[n.y])[n.x] != "0":
				continue
			seen[n] = true
			todo.append(n)
	return seen


## The map row of a doorway between a room with stamp `sa` at row `ya` and the room east of it (`sb` at row `yb`,
## standing against its east wall), or -1 when their walls offer none at a common row.
static func row_between(sa: Dictionary, ya: int, sb: Dictionary, yb: int) -> int:
	var east := open_rows(sa, true)
	var west := open_rows(sb, false)
	for y in range(maxi(ya, yb), mini(ya + int(sa.h), yb + int(sb.h))):
		if east.has(y - ya) and west.has(y - yb):
			return y
	return -1


## Every doorway the finished rooms of the world's properties have: [{a, b, y, cells: [Vector2i, Vector2i],
## inside: [Vector2i, Vector2i]}], `a` the west room, `cells` the two wall cells (a's, then b's) and `inside` the floor
## cells just inside them. Rooms of one property only, standing wall to wall; sorted, so deterministic.
static func find(w: World) -> Array:
	var out := []
	var ids: Array = w.buildings.keys()
	ids.sort()
	var rooms := []
	for id in ids:
		var b: Dictionary = w.buildings[id]
		if World.is_built(b) and not w.property.parcel_under(b).is_empty():
			rooms.append(b)
	for a: Dictionary in rooms:
		for b: Dictionary in rooms:
			if str(a.id) == str(b.id) or int(a.x) + int(a.w) != int(b.x):
				continue
			if w.property.estate_id(w.property.parcel_under(a)) != w.property.estate_id(w.property.parcel_under(b)):
				continue
			var y := row_between(w.stamp_of(a), int(a.y), w.stamp_of(b), int(b.y))
			if y < 0:
				continue
			var ax := int(a.x) + int(a.w) - 1
			out.append({"a": str(a.id), "b": str(b.id), "y": y, "cells": [Vector2i(ax, y), Vector2i(int(b.x), y)],
				"inside": [Vector2i(ax - 1, y), Vector2i(int(b.x) + 1, y)]})
	return out


## An interior with the doorway cells of its building added to its area and floor (so a person in the gap is inside
## this building, under its roof) and listed under "inner": [[x, y, other building's id]].
static func add_to(it: Dictionary, id: String, doorways: Array) -> Dictionary:
	var out: Dictionary = it
	for d: Dictionary in doorways:
		for k in 2:
			if str([d.a, d.b][k]) != id:
				continue
			if not out.has("inner"):
				out = it.duplicate(true)
				out.inner = []
			var c: Vector2i = d.cells[k]
			out.area.append([c.x, c.y])
			out.floor.append([c.x, c.y])
			out.inner.append([c.x, c.y, str([d.b, d.a][k])])
	return out
