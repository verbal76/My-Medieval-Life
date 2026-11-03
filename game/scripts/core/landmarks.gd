class_name Landmarks
extends RefCounted
## B25R1-003 (owner directive 2026-11-03, section 1, "Discoverable locations"): the smaller places of the region that must be
## found on foot, each a real object of the world, never invented. A place the player has come within SEE tiles of gets a
## persistent icon on their Region map (PlayerState.landmarks, saved with them; an older save has none and loads with an empty
## set). The major settlements are not landmarks: they are common knowledge and always on the map (RegionMapPanel).
##
## The places (all() lists them from the world as it is now):
##   mine     a mine's way in on the surface: each Underground portal end on the surface (the village mine's adit, and a shaft
##            sunk by anyone, MIN-F2)
##   quarry   the village quarry yard, where its ore seams lie (village.json mine.yard), while any seam is left on the surface
##   camp     the bandit camp (World.bandit_camp, the map's own)
##   ore      an ore seam opened outside the village (Discovery: a trial pit's find, an ordinary World.deposits record)
##   region   B25R1-018: the region layout's landmarks built in the world (Bear Castle's bank, the chalk figures, the seven
##            grave-mounds, Saint Ann's Chapel, Higham's castle and abbey, Wulstead's fountain and canons, ...; id "region:<id>",
##            kind the layout's), from Overworld.landmark_places
## Pure reads of the world; only the player's own record changes.

const SEE := 10                 # tiles: a place this close (Chebyshev) is seen


## Every discoverable place there is now: [{id, kind, name, at: Vector2i}], in a fixed order.
static func all(w: World) -> Array:
	var out := []
	if w.underground != null:
		for po in w.underground.portals:
			for e in po.ends:
				if int(e.level) == Underground.SURFACE:
					var at := Vector2i(e.stand)
					if out.any(func(o): return o.kind == "mine" and (o.at as Vector2i).distance_to(at) <= 8.0):
						continue                      # one mouth with two passages (the adit and the cave under it): one place
					out.append({"id": "mine:" + str(po.id), "kind": "mine",
						"name": "Mine shaft" if str(po.get("kind", "")) == "shaft" else "Mine entrance", "at": at})
	var mine: Dictionary = w.map.data.get("mine", {})
	if mine.has("yard"):
		var yard := Vector2i(int(mine.yard[0]), int(mine.yard[1]))
		for d in w.deposits:
			if int(d.get("level", 0)) == 0 and w.map.in_village(Vector2i(int(d.x), int(d.y))) and int(d.get("amount", 0)) > 0:
				out.append({"id": "quarry", "kind": "quarry", "name": "Quarry and ore seams", "at": yard})
				break
	if w.bandit_camp != Vector2i.ZERO:
		out.append({"id": "bandit_camp", "kind": "camp", "name": "Bandit camp", "at": w.bandit_camp})
	for d in w.deposits:
		var c := Vector2i(int(d.x), int(d.y))
		if int(d.get("level", 0)) == 0 and not w.map.in_village(c) and int(d.get("amount", 0)) > 0:
			out.append({"id": "ore:%d,%d" % [c.x, c.y], "kind": "ore", "name": GameData.item_name(str(d.ore)) + " seam", "at": c})
	if w.map.overworld != null:                       # B25R1-018: the region's landmarks that stand in the world (Overworld.landmark_places)
		out.append_array(w.map.overworld.landmark_places())
	return out


## The places of all() this player has found and that are still there (their record, with the place's position now).
static func known(w: World, p: PlayerState) -> Array:
	var out := []
	for lm in all(w):
		if p.landmarks.has(str(lm.id)):
			out.append(lm)
	return out


## Each step of a player on the surface (Atlas.note_position): the places within SEE are found. Returns the names found now.
static func note(w: World, p: PlayerState) -> Array:
	var cell := Vector2i(p.pos.floor())
	if cell == p.landmark_cell:
		return []
	p.landmark_cell = cell
	var found := []
	for lm in all(w):
		var id := str(lm.id)
		var at: Vector2i = lm.at
		if p.landmarks.has(id) or maxi(absi(at.x - cell.x), absi(at.y - cell.y)) > SEE:
			continue
		p.landmarks[id] = {"kind": str(lm.kind), "name": str(lm.name), "x": at.x, "y": at.y, "day": w.day()}
		if w.recorder != null:                       # B25R1-016
			w.recorder.chronicle("landmark_discovered", p, {"place": "landmark:" + id, "object": "landmark:" + id, "action": str(lm.kind),
				"x": at.x, "y": at.y, "detail": str(lm.name)})
		found.append(str(lm.name))
	return found


# ------------------------------------------------------------------ save -------------------
static func to_save(p: PlayerState) -> Dictionary:
	return p.landmarks.duplicate(true)


static func load_into(p: PlayerState, d: Dictionary) -> void:
	p.landmarks = {}
	var src: Variant = d.get("landmarks", {})
	if src is Dictionary:
		for id in src:
			var e: Dictionary = src[id]
			p.landmarks[str(id)] = {"kind": str(e.get("kind", "")), "name": str(e.get("name", "")), "x": int(e.get("x", 0)),
				"y": int(e.get("y", 0)), "day": int(e.get("day", 0))}
