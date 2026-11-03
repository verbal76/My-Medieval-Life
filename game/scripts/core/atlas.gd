class_name Atlas
extends RefCounted
## REGION-NAV-01 (owner directives 2026-11-02, regional economy master and Build 25 scope correction; docs/region_nav/
## IMPLEMENTATION_PLAN.md AD-8): what a player knows of the region, kept on their own PlayerState and saved with it.
##
##   places    settlement id -> {how: "visited" | "told", day, by}: a settlement's place is known by walking into its site
##             (Overworld.site_at) or by being told by someone who knows it (learn_place: a settlement's own people, a
##             traveller, an envoy). Knowing where a place is tells nothing of its trade: that is learned from its people.
##   explored  overworld chunk -> a 16-byte summary of the ground the player has seen there (summarize: one class per 8 x 8
##             tile block, read from the generated chunk itself), the 3 x 3 chunks round the player as they walk.
## The region map (RegionMapPanel) draws explored ground as it is and the rest dark; B25R1-003: every settlement is on it from day 1
## whatever `places` holds (places is extra knowledge, e.g. for trade), and Landmarks keeps the smaller places found on foot.
## Pure reads of the overworld; nothing here changes the world, a ledger, a coin or an item.

const BLOCK := 8                                   # tiles a summary class covers along each side
const PER := Overworld.CHUNK / BLOCK               # blocks per chunk side (4)
enum { UNKNOWN, GRASS, WOOD, ROCK, ROAD, SITE, VILLAGE }


## The ground of chunk `cc` as PER x PER classes (row-major): ROAD where any cell of the block is road, SITE inside a
## settlement's site, VILLAGE inside the village, else the majority of trees (WOOD), blocked ground without a tree (ROCK)
## and open ground (GRASS). Generated terrain only (the player's felled trees do not change the map).
static func summarize(ow: Overworld, cc: Vector2i) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(PER * PER)
	var ch := ow.get_chunk(cc)
	var x0 := cc.x * Overworld.CHUNK
	var y0 := cc.y * Overworld.CHUNK
	for by in PER:
		for bx in PER:
			var counts := [0, 0, 0]               # grass, wood, rock
			var road := false
			var mid := Vector2i(x0 + bx * BLOCK + BLOCK / 2, y0 + by * BLOCK + BLOCK / 2)
			var cls := UNKNOWN
			if ow.village.has_point(mid):
				cls = VILLAGE
			elif not ow.site_at(mid).is_empty():
				cls = SITE
			else:
				for dy in BLOCK:
					for dx in BLOCK:
						var cx := bx * BLOCK + dx
						var cy := by * BLOCK + dy
						var i := cy * Overworld.CHUNK + cx
						if ch.road[(cy + Overworld.PAD) * Overworld.AREA + cx + Overworld.PAD] == 1:
							road = true
						if ch.kind[i] != Overworld.NO_TREE:
							counts[1] += 1
						elif ch.solid[i] != 0:
							counts[2] += 1
						else:
							counts[0] += 1
				if road:
					cls = ROAD
				elif counts[1] >= counts[0] and counts[1] >= counts[2]:
					cls = WOOD
				elif counts[2] > counts[0]:
					cls = ROCK
				else:
					cls = GRASS
			out[by * PER + bx] = cls
	return out


## Each step of a player in the overworld (World.update): the chunks round them are explored once, and a settlement whose
## site they walk into becomes known to them ("visited"). Returns the id of a settlement just discovered, or "".
static func note_position(w: World, p: PlayerState) -> String:
	var ow: Overworld = w.map.overworld
	if ow == null or not p.alive or p.map_level != 0:
		return ""
	var cell := Vector2i(p.pos.floor())
	var cc := Overworld.chunk_of(cell)
	if cc != p.atlas_chunk:
		p.atlas_chunk = cc
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var k := cc + Vector2i(dx, dy)
				if not p.explored.has(k) and not ow.chunk_in_village(k):
					p.explored[k] = summarize(ow, k)
	if cell != p.wear_cell:
		p.wear_cell = cell
		RoadWear.foot(ow, cell, not w.carts.pulled_by(w.player_ref(p)).is_empty())     # B25R1-011: the player's footfall
		if w.recorder != null:
			WaterNotes.crossed(w, p, w.player_ref(p), cell)       # B25R1-017: a bridge or ford crossed
	for nm in Landmarks.note(w, p):                  # B25R1-003: the smaller places, found on foot (an icon on the map)
		w.stat("landmark_found")
		if p == w.player:
			w.note("You mark %s on your map." % nm.to_lower())
	if ow.village.has_point(cell):
		return ""
	var st := ow.site_at(cell)
	if st.is_empty() or p.places.has(str(st.id)):
		return ""
	p.places[str(st.id)] = {"how": "visited", "day": w.day(), "by": ""}
	w.stat("place_discovered_visited")
	if p == w.player:
		w.note("You come to %s, a %s." % [str(st.name), str(st.kind)])
	return str(st.id)


## A player is told where a settlement lies by someone who knows it (`by`: their reference). Nothing more than its place.
## Returns true when it was new to them.
static func learn_place(w: World, p: PlayerState, settlement: String, by: String) -> bool:
	if p.places.has(settlement) or w.map.overworld == null or w.map.overworld.site(settlement).is_empty():
		return false
	p.places[settlement] = {"how": "told", "day": w.day(), "by": by}
	w.stat("place_discovered_told")
	return true


# ------------------------------------------------------------------ save -------------------
static func places_to_save(p: PlayerState) -> Dictionary:
	return p.places.duplicate(true)


static func explored_to_save(p: PlayerState) -> Array:
	var keys: Array = p.explored.keys()
	keys.sort()
	var out := []
	for k: Vector2i in keys:
		out.append([k.x, k.y, Marshalls.raw_to_base64(p.explored[k])])
	return out


static func load_into(p: PlayerState, d: Dictionary) -> void:
	p.places = (d.get("places", {}) as Dictionary).duplicate(true)
	for k in p.places:
		p.places[k].day = int(p.places[k].get("day", 0))
	p.explored.clear()
	for e in d.get("explored", []):
		p.explored[Vector2i(int(e[0]), int(e[1]))] = Marshalls.base64_to_raw(str(e[2]))
