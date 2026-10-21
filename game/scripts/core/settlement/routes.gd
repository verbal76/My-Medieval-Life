class_name TradeRoutes
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-C/E; PROS-18): trade-route and transport planning (spec s.5 "Logistics: cart
## capacity, roads, travel time ... constrain quantity"; s.8 "roads, bridges ... and carts affect costs and throughput").
##
## Carriage is never free and never folded into the goods' price (owner Q18-10, 2026-10-21): the buyer fetches the
## goods on its own trip (no coin; its own capacity), or pays a willing carter a fee: the carters' wages for the round
## trip (balance helper_wage, the manor's day wage) spread over a full load, paid to the carter, so no coin is
## destroyed or created by distance (DESIGN.md "Transport cost"). Terrain lengthens a route: each tile
## costs settlement_industries.json transport.terrain[kind] tiles of travel (road 1, open ground more, rough more
## still); solid ground is impassable. Carts are the existing B14 handcarts: a settlement's handcarts (facts.transport)
## set how much a trip can carry; with none, its people carry on their backs ("carrier").
##
## Routes come two ways: a path over a grid of terrain (grid_route: Dijkstra, 4 neighbours, ties broken by cell order,
## so the same grid always gives the same path) -- usable on the overworld through overworld_classifier -- or an
## abstract length and terrain mix for off-map settlements (abstract_route).

static func cfg() -> Dictionary:
	return SettlementIndustries.data().transport


static func terrain_factor(kind: String) -> float:
	var t: Dictionary = cfg().terrain
	return float(t.get(kind, -1.0)) if kind != "solid" else -1.0


## The cheapest path from `a` to `b` over cells inside `bounds`, where classify(cell) -> "road" | "open" | "rough" |
## "solid". Returns {found, cells: [Vector2i], tiles, effective} (effective: tiles weighted by terrain).
static func grid_path(a: Vector2i, b: Vector2i, classify: Callable, bounds: Rect2i) -> Dictionary:
	var dist := {a: 0.0}
	var prev := {}
	var heap := [[0.0, a.y, a.x]]
	var done := {}
	while not heap.is_empty():
		var top: Array = _pop(heap)
		var c := Vector2i(int(top[2]), int(top[1]))
		if done.has(c):
			continue
		done[c] = true
		if c == b:
			break
		for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			var n: Vector2i = c + d
			if not bounds.has_point(n) or done.has(n):
				continue
			var f := terrain_factor(str(classify.call(n)))
			if f <= 0.0:
				continue
			var nd := float(dist[c]) + f
			if not dist.has(n) or nd < float(dist[n]) - 1e-9:
				dist[n] = nd
				prev[n] = c
				_push(heap, [nd, n.y, n.x])
	if not done.has(b):
		return {"found": false, "cells": [], "tiles": 0, "effective": 0.0}
	var cells := [b]
	var c2 := b
	while c2 != a:
		c2 = prev[c2]
		cells.push_front(c2)
	return {"found": true, "cells": cells, "tiles": cells.size() - 1, "effective": float(dist[b])}


static func _less(x: Array, y: Array) -> bool:
	if x[0] != y[0]:
		return x[0] < y[0]
	if x[1] != y[1]:
		return x[1] < y[1]
	return x[2] < y[2]


static func _push(h: Array, e: Array) -> void:
	h.append(e)
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) / 2
		if _less(h[i], h[p]):
			var t = h[i]
			h[i] = h[p]
			h[p] = t
			i = p
		else:
			break


static func _pop(h: Array) -> Array:
	var top: Array = h[0]
	var last: Array = h.pop_back()
	if not h.is_empty():
		h[0] = last
		var i := 0
		while true:
			var l := 2 * i + 1
			var r := l + 1
			var m := i
			if l < h.size() and _less(h[l], h[m]):
				m = l
			if r < h.size() and _less(h[r], h[m]):
				m = r
			if m == i:
				break
			var t = h[i]
			h[i] = h[m]
			h[m] = t
			i = m
	return top


## The overworld as terrain for grid_path: its roads, open ground and solid cells (cliffs, water, trees, rocks).
static func overworld_classifier(ow) -> Callable:
	return func(c: Vector2i) -> String:
		if ow.is_solid(c):
			return "solid"
		return "road" if ow.is_road(c) else "open"


## The mode a settlement hauls with: a handcart when it has one, else carried on the back.
static func mode_for(transport: Dictionary) -> String:
	return "handcart" if int(transport.get("handcart", 0)) > 0 else "carrier"


## Units a party can carry in one round of trade: each handcart's load, or with none, each of its carriers' packs
## (transport.carry people; 1 when not given; 0 when it has nobody to carry).
static func capacity(transport: Dictionary) -> int:
	var modes: Dictionary = cfg().modes
	var carts := int(transport.get("handcart", 0))
	if carts > 0:
		return carts * int(modes.handcart.units)
	return int(transport.get("carry", 1)) * int(modes.carrier.units)


## A route of `effective` terrain-weighted tiles hauled in `mode`: days there and back, and the haulage cost a unit
## (the carters' wages for the round trip spread over a full load, rounded up; at least 1 when the trip costs anything).
static func costed(from: String, to: String, tiles: int, effective: float, mode: String) -> Dictionary:
	var m: Dictionary = cfg().modes[mode]
	var days := effective / float(m.tiles_per_day)
	var wage := float(GameData.b("helper_wage")) * float(cfg().carters_per_trip) * days * 2.0
	var per_unit := int(ceil(wage / float(m.units) - 1e-9))
	return {"from": from, "to": to, "mode": mode, "tiles": tiles, "effective": effective, "days": days,
		"cost_per_unit": per_unit, "units": int(m.units)}


## A route found on a grid between two settlements' positions; {} when none exists (cut off: no trade).
static func grid_route(a: SettlementLedger, b: SettlementLedger, classify: Callable, bounds: Rect2i) -> Dictionary:
	var p := grid_path(a.pos, b.pos, classify, bounds)
	if not p.found:
		return {}
	var r := costed(a.settlement, b.settlement, int(p.tiles), float(p.effective), "carrier")
	r.cells = p.cells
	return r


## An off-map route: `tiles` long with a mix of terrain ({road: share, open: share, rough: share}, shares summing to 1).
static func abstract_route(from: String, to: String, tiles: int, mix: Dictionary, mode: String) -> Dictionary:
	var eff := 0.0
	var ks := mix.keys()
	ks.sort()
	for k in ks:
		eff += float(tiles) * float(mix[k]) * maxf(0.0, terrain_factor(str(k)))
	return costed(from, to, tiles, eff, mode)


## A route table for RegionalMarket, between PLACES (a party's `settlement`): {"a>b": route}, both directions.
## `links`: [[place_a, place_b, tiles, mix]] for abstract links. A route is the way, its length and days; the carriage
## fee is worked out for whoever hauls (the buyer's own trip costs no coin; a carter's fee in its own mode;
## RegionalMarket). cost_per_unit here is a carrier's, for reports.
static func table(ledgers: Array, links: Array) -> Dictionary:
	var places := {}
	for l: SettlementLedger in ledgers:
		places[l.settlement] = true
	var out := {}
	for k in links:
		var a: String = str(k[0])
		var b: String = str(k[1])
		if not places.has(a) or not places.has(b):
			continue
		out[a + ">" + b] = abstract_route(a, b, int(k[2]), k[3], "carrier")
		out[b + ">" + a] = abstract_route(b, a, int(k[2]), k[3], "carrier")
	return out


## A route table found on a grid between every pair of places (pairs with no path get no route).
static func grid_table(ledgers: Array, classify: Callable, bounds: Rect2i) -> Dictionary:
	var out := {}
	var ls := ledgers.duplicate()
	ls.sort_custom(func(x, y): return x.id < y.id)
	for i in ls.size():
		for j in ls.size():
			if i == j or ls[i].settlement == ls[j].settlement or out.has(ls[i].settlement + ">" + ls[j].settlement):
				continue
			var r := grid_route(ls[i], ls[j], classify, bounds)
			if not r.is_empty():
				out[ls[i].settlement + ">" + ls[j].settlement] = r
	return out
