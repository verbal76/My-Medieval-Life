class_name BusinessDesks
extends RefCounted
## GP-BUSINESS-DESK (owner, 2026-10-24: "that table, that person is standing near is where the smithy does business. So maybe
## you click on that and it asks if you want to talk to the smithy to buy something or sell something. Or speak to a courier.
## Just make that the business desk, like in all businesses."): every business does its business at one desk, a drawn desk or
## counter in its premises. Using it opens a short menu (Main, GameUI.show_desk): trade with the keeper or, when the keeper is
## away, what the counter rules allow (ring for service, the goods left on a stall); and the courier where the business keeps
## a courier booth, which stands at the desk (CourierService.open_shop_booth), never on a work station.
##
## The desks, read from the world's records (nothing new is saved):
##   * counters: the tavern's counter (The Well House), the armory's counter, the table with the open ledger (the Smithy and
##     Armory: smiths and tanners), and the sawmill's table with stools (generator v15; the carpenters);
##   * market stalls with a keeper: the merchants' stalls, the tailor's and the barber's pitches, every built stall (a
##     villager's, the courier's, a player's own);
##   * storefronts (a household's counter by its door) and a player's shop in a fitted room (its counter).
## A business with no drawn desk keeps none: the sage's hut holds only a bed (the sage is traded with by talking, as before).

const COUNTER_TYPES := ["tavern_counter", "armory_counter", "sawmill_counter"]


## Every desk: {id, kind ("counter" | "stall" | "front" | "shop"), post (the station or stall id the shop rules use, or the
## building id), at (the desk's cell), use (where its keeper stands), building, name}. In a fixed order.
static func all(w: World) -> Array:
	var out := []
	for t in COUNTER_TYPES:
		for id in w.stations_of(t):
			out.append(_counter(w, str(id)))
	for id in w.business.sorted_ids():
		var s: Dictionary = w.stalls[id]
		if s.has("x") and (w.tenant_of(s) != "" or Stalls.is_built(s)):
			out.append({"id": str(id), "kind": "stall", "post": str(id), "at": Vector2i(int(s.x), int(s.y)),
				"use": Vector2i(int(s.use[0]), int(s.use[1])) if s.has("use") else Vector2i(int(s.x), int(s.y) + 1), "building": "", "name": stall_name(w, s)})
	var ids: Array = w.buildings.keys()
	ids.sort()
	for bid in ids:
		var b: Dictionary = w.buildings[bid]
		if b.has("front"):
			var f: Dictionary = b.front
			out.append({"id": "front:" + str(bid), "kind": "front", "post": str(bid), "at": Vector2i(int(f.x), int(f.y)),
				"use": Vector2i(int(f.use[0]), int(f.use[1])), "building": str(bid), "name": front_name(w, b)})
		elif b.has("shop") and not bool(b.shop.get("front", false)):
			var e: Dictionary = w.fitting.entry(b, "counter")
			if not e.is_empty():
				out.append({"id": "shop:" + str(bid), "kind": "shop", "post": str(bid), "at": Vector2i(int(e.at[0]), int(e.at[1])) if e.has("at") else Vector2i(int(e.use[0]), int(e.use[1])),
					"use": Vector2i(int(e.use[0]), int(e.use[1])), "building": str(bid), "name": "%s's shop" % w.ref_name(w.holder_of(b), true)})
	return out


static func _counter(w: World, id: String) -> Dictionary:
	var st: Dictionary = w.stations[id]
	var b: Dictionary = w.buildings.get(str(st.get("building", "")), {})
	return {"id": id, "kind": "counter", "post": id, "at": Vector2i(int(st.at[0]), int(st.at[1])), "use": Vector2i(int(st.use[0]), int(st.use[1])),
		"building": str(st.get("building", "")), "name": str(b.get("name", "the counter"))}


static func by_id(w: World, id: String) -> Dictionary:
	for d in all(w):
		if str(d.id) == id:
			return d
	return {}


## "Sabina's ore and timber stall", "the tailor's pitch", "Wat's market stall".
static func stall_name(w: World, s: Dictionary) -> String:
	if str(s.get("service", "")) != "":
		return "the %s's pitch" % str(s.service)
	var who := w.ref_name(w.holder_of(s), true) if Stalls.is_built(s) else w.ref_name(w.tenant_of(s), true)
	if Stalls.is_built(s):
		return "%s's market stall" % who
	return "%s's %s" % [who, {"raw": "ore and timber stall", "food": "food stall", "goods": "tools and arms stall"}.get(str(s.get("kind", "")), "stall")]


static func front_name(w: World, b: Dictionary) -> String:
	return "%s's storefront" % w.ref_name(w.holder_of(b), true)


## The desk business `ref` ("npc:<id>" or a player ref) keeps, or {}: the stall it keeps, else the counter of the building it
## works in, else (a player) its own storefront or shop.
static func of_business(w: World, ref: String) -> Dictionary:
	var desks := all(w)
	for d in desks:
		if str(d.kind) == "stall" and (w.tenant_of(w.stalls[d.post]) == ref or w.holder_of(w.stalls[d.post]) == ref):
			return d
	if ref.begins_with("npc:"):
		var n: NPC = w.npc(int(ref.trim_prefix("npc:")))
		if n == null:
			return {}
		var bid := str(w.stations[n.workplace].get("building", "")) if w.stations.has(n.workplace) else ""
		for d in desks:
			if str(d.kind) == "counter" and bid != "" and str(d.building) == bid:
				return d
		return {}
	for d in desks:
		if str(d.kind) in ["front", "shop"] and w.holder_of(w.buildings[d.building]) == ref and w.buildings[d.building].has("shop"):
			return d
	return {}


## The counter, storefront and shop desks the player at `pos`, facing `facing`, stands beside and faces (the rule the work
## stations use, World.station_in_reach: on the keeper's cell facing the desk, or within reach of the desk facing it). Stalls
## are offered by the stall's own cells (Main._find_target), as before.
static func faced_all(w: World, pos: Vector2, facing: Vector2) -> Array:
	var out := []
	var probe := pos + facing.normalized() * World.TARGET_PROBE if facing != Vector2.ZERO else pos
	for d in all(w):
		if str(d.kind) == "stall":
			continue
		var at: Vector2i = d.at
		var near := Vector2i(floori(probe.x), floori(probe.y)) == at
		if not near and (Vector2(at) + Vector2(0.5, 0.5)).distance_to(pos) <= World.STATION_BESIDE:
			near = World.station_in_reach({"use": [d.use.x, d.use.y], "at": [at.x, at.y]}, pos, facing) and Vector2i(floori(pos.x), floori(pos.y)) != d.use
		if near and (Vector2(at) + Vector2(0.5, 0.5)).distance_to(pos) <= World.STATION_BESIDE and w.reaches(pos, Vector2(at) + Vector2(0.5, 0.5)):
			out.append(d)
	return out


## The village courier booth standing at desk `d` (its cell), or {}.
static func booth_at(w: World, d: Dictionary) -> Dictionary:
	if w.couriers == null or d.is_empty():
		return {}
	for b in w.couriers.booths:
		if str(b.settlement) == SettlementFacts.VILLAGE and Vector2i(int(b.x), int(b.y)) == d.at:
			return b
	return {}


## Whether the village booth `b` stands at a desk (it is then offered from the desk's menu, not on its own).
static func booth_on_desk(w: World, b: Dictionary) -> bool:
	for d in all(w):
		if Vector2i(int(b.x), int(b.y)) == d.at:
			return true
	return false
