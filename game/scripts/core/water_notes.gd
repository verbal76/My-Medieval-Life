class_name WaterNotes
extends RefCounted
## B25R1-017 (owner directive 2026-11-03, section 7: "Bridge construction, use, and relevant travel failures. Travel route
## choices involving crossings"): the flight recorder's notes of water, in the recorder's own vocabulary
## (recorder_codes.json, docs/design/FLIGHT_RECORDER.md section 9): bridge_used, route_crossing, travel_blocked_by_water.
## Each is one guarded call (the caller checks w.recorder != null), reads what the travel and walking systems already did,
## and never draws, decides or changes state. Ids are stable: a crossing is Overworld.crossing_id
## ("crossing:<bridge|ford>:<x>,<y>", its first cell), passed as `object`; a person is the recorder's own p:<id>.


## A person stepped onto cell `c`: when it is a bridge, note its use once a person, bridge and game day.
static func crossed(w: World, who, ref: String, c: Vector2i) -> void:
	var ow: Overworld = w.map.overworld
	if ow == null or ow.gen < 4 or not ow.is_bridge(c):
		return
	var id := ow.crossing_id(c)
	var key := ref + "|" + id
	if int(ow.crossings_seen.get(key, -1)) == w.day():
		return
	ow.crossings_seen[key] = w.day()
	w.recorder.chronicle("bridge_used", who, {"object": id, "place": id, "x": c.x, "y": c.y})


## The crossings a planned route makes: {bridges, fords, first: the first crossing's id ("" none)}.
static func route_crossings(w: World, cells: PackedVector2Array) -> Dictionary:
	var ow: Overworld = w.map.overworld
	var out := {"bridges": 0, "fords": 0, "first": ""}
	if ow == null or ow.gen < 4:
		return out
	var seen := {}
	for v in cells:
		var c := Vector2i(v)
		var id := ow.crossing_id(c)
		if id == "" or seen.has(id):
			continue
		seen[id] = true
		if id.begins_with("crossing:bridge"):
			out.bridges += 1
		else:
			out.fords += 1
		if out.first == "":
			out.first = id
	return out


## route_crossing's `chosen`: the crossing kind the route takes first (bridge or ford), or detour when it goes round water
## it came near without crossing.
static func chosen(xs: Dictionary) -> String:
	if str(xs.first).begins_with("crossing:bridge"):
		return "bridge"
	if str(xs.first).begins_with("crossing:ford"):
		return "ford"
	return "detour"
