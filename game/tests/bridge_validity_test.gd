extends SceneTree
## B25R2 playtest repair (owner directive 2026-11-06, item 6, "Invalid looping bridge geometry"): every bridge the generator lays
## must carry a road from one bank to the other. A bridge is a connected group of bridge cells (Overworld.is_bridge); the land cells
## touching it are grouped by the land they stand on (a flood fill round the bridge that never crosses water). A bridge whose land
## ends all lie on one connected piece of land crosses nothing: it is a useless loop over the water and back. Checked over the whole
## region on several seeds (curved rivers, wide courses, layout crossings).
##   godot --headless --path game -s res://tests/bridge_validity_test.gd [-- seeds=1,2,3]

const NEAR_LAND := 2              # tiles round a run over the water searched for land joining its two ends: the bank right beside it
const LOOP_CELLS := 4             # cells over the water before a run back to the same bank is a chain of bridge (a loop)

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	GameData.ensure()
	var seeds := [1, 2, 3, 4, 5, 7, 11, 42]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seeds="):
			seeds = Array(a.substr(6).split(",")).map(func(s): return int(s))
	for seed in seeds:
		_seed(int(seed))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## The region the settlements span (the village and every site), grown a margin.
static func region(ow: Overworld) -> Rect2i:
	var r := Rect2i(ow.village)
	for st in ow.sites:
		r = r.merge(Rect2i(st.rect))
	return r.grow(160)


## Every place a road crosses water in `area`: the road's own cells (RegionRoads.segments, as the chunks draw them) walked in order;
## a run of water or bridge cells is entered from land cell a and left to land cell b. The watercourse under the run's middle
## (Overworld.streams_in, its nearest segment) decides the banks: a and b on opposite sides is a crossing; on the same side the road
## went over the water and came back to the bank it left (a loop). [{at, cells, same_bank: bool}]
static func crossings(ow: Overworld, area: Rect2i) -> Array:
	var out := []
	var seen := {}
	for seg in RegionRoads.segments(ow, area):
		var sc: PackedInt32Array = seg.cells
		var n := sc.size() / 2
		var k := 1
		while k < n:
			var c := Vector2i(sc[2 * k], sc[2 * k + 1])
			if not _wet(ow, c) or not area.has_point(c):
				k += 1
				continue
			var e := k
			while e < n and _wet(ow, Vector2i(sc[2 * e], sc[2 * e + 1])):
				e += 1
			if e >= n:
				break                                  # the road ends on the water: not a crossing to judge here
			var a := Vector2i(sc[2 * (k - 1)], sc[2 * (k - 1) + 1])
			var b := Vector2i(sc[2 * e], sc[2 * e + 1])
			var mid := Vector2i(sc[2 * ((k + e - 1) / 2)], sc[2 * ((k + e - 1) / 2) + 1])
			var key := "%d,%d-%d,%d" % [mini(a.x, b.x), mini(a.y, b.y), maxi(a.x, b.x), maxi(a.y, b.y)]
			if not seen.has(key):
				seen[key] = true
				var run: Array[Vector2i] = []
				for q in range(k, e):
					run.append(Vector2i(sc[2 * q], sc[2 * q + 1]))
				out.append({"at": mid, "cells": e - k, "same_bank": _land_joined(ow, a, b, run)})
			k = e + 1
	return out


## A cell of a crossing: water, a bridge or a ford (a ford is crossed on foot, so it is part of the crossing, not a bank).
static func _wet(ow: Overworld, c: Vector2i) -> bool:
	return ow.is_bridge(c) or ow.is_water(c) or ow.is_ford(c)


## Whether land cells a and b (a road's run over the water between them) are joined over dry land close by: a flood fill from a
## over land (no water, bridge or ford) within NEAR_LAND tiles of the run reaches b. Then the road could have stayed on the bank and
## the run over the water is a useless loop; across a river, a braided river's channels or a lake, the water parts them.
static func _land_joined(ow: Overworld, a: Vector2i, b: Vector2i, run: Array[Vector2i]) -> bool:
	var lo := a.min(b)
	var hi := a.max(b)
	for c in run:
		lo = lo.min(c)
		hi = hi.max(c)
	var box := Rect2i(lo, hi - lo + Vector2i.ONE).grow(NEAR_LAND)
	var seen := {a: true}
	var todo: Array[Vector2i] = [a]
	while not todo.is_empty():
		var q: Vector2i = todo.pop_back()
		if q == b:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = q + d
			if seen.has(n) or not box.has_point(n) or _wet(ow, n):
				continue
			seen[n] = true
			todo.append(n)
	return false


func _seed(seed: int) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var ow: Overworld = w.map.overworld
	var area := region(ow)
	var t := Time.get_ticks_msec()
	var xs := crossings(ow, area)
	# a loop: LOOP_CELLS or more cells out over the water and back to the same bank (the reported chain of bridge sections); a
	# shorter run back to the same bank is a road clipping the water's edge, reported (not hidden) but not a chain of bridge
	var back := xs.filter(func(x): return bool(x.same_bank))
	var bad := back.filter(func(x): return int(x.cells) >= LOOP_CELLS)
	print("     seed %d: %d road crossings of water in %s; %d loops of %d+ cells back to the same bank, %d shorter edge clips (%d ms)" % [seed,
			xs.size(), str(area), bad.size(), LOOP_CELLS, back.size() - bad.size(), Time.get_ticks_msec() - t])
	for x in back:
		print("       %s: %d cells at (%d, %d)" % ["LOOP" if int(x.cells) >= LOOP_CELLS else "edge clip", int(x.cells), (x.at as Vector2i).x, (x.at as Vector2i).y])
	check(not xs.is_empty() and bad.is_empty(), "seed %d: no road runs out over the water and back to the bank it left (%d crossings, %d loops)" % [seed, xs.size(), bad.size()])
