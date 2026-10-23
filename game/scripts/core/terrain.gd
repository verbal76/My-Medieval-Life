class_name Terrain
extends RefCounted
## B14-07 (owner, 2026-10-19: cliff steps cut with a pickaxe and Mining; wooden stairs and walkways of planks and nails,
## built with Carpentry and a mallet) with DVW-A10 (no black holes: nowhere anyone can go and not come back from).
##
## The mountains of the world outside the village (Overworld) are plateaus inside a rim of cliff. Their tops are ground,
## but for the trees and boulders on them, reachable only through the rim. Facing the rim, the player can make a way
## through it, one to `max_span` rim cells deep, straight on to the ground beyond:
##   steps    cut into the rock: a pickaxe and Mining (the game's carving skill); from the ground up to a top, or down;
##   stairs   built of planks and nails: a mallet and Carpentry; up or down, as steps;
##   walkway  built of planks and nails, from one top across the rim to another top (between raised edges).
## A way made is never undone (Overworld.works, saved), and every way runs both ways, so whoever goes up can come down
## (DVW-A10). A top's felled tree never grows back (Overworld.note_tree) and nothing can be planted there, so a top's open
## ground only grows: nothing closes behind anyone. A way never runs from ground to ground (no tunnelling through a range).
##
## The materials, the tool's wear and the skill's experience are the existing rules' (World._work_wear, Skills.gain); the
## numbers are balance.json terrain_works. Player only: villagers keep to the village (they never walk the overworld).

const DIRS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


static func cfg() -> Dictionary:
	return GameData.b("terrain_works")


## The way through the rim from `from` (where one stands) heading `dir`: {cells (the rim cells, in order), to (the cell
## beyond), from_top, to_top, kind: "steps" (up or down: steps or stairs) or "walkway" (top to top)}, or {} when there
## is no rim there, it is deeper than max_span, or what lies beyond is not open ground or leads from ground to ground.
static func span(o: Overworld, from: Vector2i, dir: Vector2i) -> Dictionary:
	if o == null or not dir in DIRS:
		return {}
	var cells := []
	var c := from + dir
	while o.is_rim(c) and cells.size() <= int(cfg().max_span):
		cells.append(c)
		c += dir
	if cells.is_empty() or cells.size() > int(cfg().max_span) or o.is_solid(c) or o.is_solid(from) or o.village.has_point(c):
		return {}
	var from_top := o.is_top(from)
	var to_top := o.is_top(c)
	if not from_top and not to_top:
		return {}                                          # ground to ground: that would be a tunnel through the range
	return {"cells": cells, "to": c, "from_top": from_top, "to_top": to_top, "kind": "walkway" if from_top and to_top else "steps"}


## "3 planks", "4 nails", "1 plank".
static func count_of(id: String, n: int) -> String:
	var name := GameData.item_name(id).to_lower()
	return "%d %s" % [n, name + ("s" if n != 1 and not name.ends_with("s") else "")]


## The way's run as a suffix: "_ns" (north-south) or "_ew".
static func run_of(dir: Vector2i) -> String:
	return "_ns" if dir.x == 0 else "_ew"


## What making `what` ("steps", "stairs", "walkway") over `n` rim cells takes: {tool (a tool kind), skill, level, items
## (item -> count), seconds, stamina, wear (tool wear), xp}.
static func cost(what: String, n: int) -> Dictionary:
	var k: Dictionary = cfg()[what]
	var items := {}
	for id in k.get("items", {}):
		items[id] = int(k["items"][id]) * n
	return {"tool": str(k.tool), "skill": str(k.skill), "level": int(k.level), "items": items, "seconds": float(k.seconds) * n,
		"stamina": float(k.stamina) * n, "wear": int(k.wear) * n, "xp": int(k.xp) * n}


## Why the player cannot make `what` over this span now ("" when they can): the tool, the skill level, the materials, the
## stamina.
static func refusal(w: World, p: PlayerState, what: String, s: Dictionary) -> String:
	if s.is_empty():
		return "There is no way through the rock here."
	if what == "walkway" and str(s.kind) != "walkway":
		return "A walkway runs from one mountain top to another."
	if what != "walkway" and str(s.kind) == "walkway":
		return "Between two tops, build a walkway."
	var k := cost(what, (s.cells as Array).size())
	if p.tool_of(str(k.tool)) == "":
		return "You need a %s." % GameData.item_name(str(k.tool)).to_lower()
	if p.level(str(k.skill)) < int(k.level):
		return "You need %s level %d." % [str(GameData.skills[str(k.skill)].name), int(k.level)]
	for id in k.items:
		if p.inv.count(id) < int(k.items[id]):
			return "You need %s (you have %d)." % [count_of(id, int(k.items[id])), p.inv.count(id)]
	if p.stamina < float(k.stamina):
		return "You are too tired: it takes %d stamina." % int(k.stamina)
	return ""


## The choices facing cell `c` from where the player stands (Farming.targets_at): cut steps, build stairs, build a
## walkway, as farm-style targets {kind: "farm", act: "terrain", what, cell, label, low}. A choice the player cannot make
## yet is still shown, with what it needs, so the way is discoverable.
static func targets_at(w: World, c: Vector2i, p: PlayerState) -> Array:
	var o: Overworld = w.map.overworld
	if o == null or not o.is_rim(c):
		return []
	var at := Vector2i(floori(p.pos.x), floori(p.pos.y))
	var dir := c - at
	if not dir in DIRS:
		return []
	var s := span(o, at, dir)
	if s.is_empty():
		return []
	var n := (s.cells as Array).size()
	var whither := "across to the next top" if str(s.kind) == "walkway" else ("up the cliff" if not bool(s.from_top) else "down the cliff")
	var out := []
	for what in (["walkway"] if str(s.kind) == "walkway" else ["steps", "stairs"]):
		var k := cost(what, n)
		var no := refusal(w, p, what, s)
		var need := ", ".join(k.items.keys().map(func(id): return count_of(id, int(k.items[id]))))
		var label := "%s %s (%d deep%s)" % [{"steps": "Cut steps", "stairs": "Build wooden stairs", "walkway": "Build a walkway"}[what], whither, n,
				(": " + need) if need != "" else ""]
		out.append({"kind": "farm", "act": "terrain", "what": what, "cell": c, "dir": dir, "label": label if no == "" else "%s: %s" % [label, no.trim_suffix(".")],
				"id": "terrain:%s:%d,%d" % [what, c.x, c.y], "low": no != ""})
	return out


## The action for a terrain target, as Farming.plan returns it: {ok, why} or {ok, label, secs, anim, tool, run}.
static func plan(w: World, t: Dictionary, p: PlayerState) -> Dictionary:
	var o: Overworld = w.map.overworld
	var at := Vector2i(floori(p.pos.x), floori(p.pos.y))
	var what := str(t.what)
	var s := span(o, at, t.dir)
	var no := refusal(w, p, what, s)
	if no != "":
		return {"ok": false, "why": no}
	var k := cost(what, (s.cells as Array).size())
	var secs := float(k.seconds) * (Skills.value(p, "mining", "mine_time", 1.0) if what == "steps" else Skills.value(p, str(k.skill), "craft_time", 1.0))
	var dir: Vector2i = t.dir
	return {"ok": true, "label": "Cutting steps" if what == "steps" else "Building", "secs": secs, "anim": "swing", "tool": p.tool_of(str(k.tool)),
			"run": func() -> Dictionary: return {"items": {}, "text": build(w, p, what, at, dir)}}


## Make the way: the materials are used (used_<item>, the goods ledger), the tool wears, the stamina is spent and the
## skill gains; the rim cells become steps, stairs or a walkway. Returns the message ("" never: it always says what
## happened); a refusal leaves everything as it was.
static func build(w: World, p: PlayerState, what: String, from: Vector2i, dir: Vector2i) -> String:
	var o: Overworld = w.map.overworld
	var s := span(o, from, dir)
	var no := refusal(w, p, what, s)
	if no != "":
		return no
	var cells: Array = s.cells
	var k := cost(what, cells.size())
	if not p.inv.remove_all(k.items):
		return "You lack the materials."
	for id in k.items:
		w.stat("used_" + id, float(k.items[id]))
	p.stamina -= float(k.stamina)
	var tool := p.tool_of(str(k.tool))
	if w._work_wear(p, tool, int(k.wear), str(k.skill), "tool_wear_save" if what == "steps" else ""):
		w.note("Your %s broke." % GameData.item_name(tool).to_lower())
	p.gain(str(k.skill), int(k.xp))
	var kind := ("steps" if what == "steps" else what) + run_of(dir)
	for c: Vector2i in cells:
		o.note_work(c, kind)
	w.stat("terrain_" + what)
	return {"steps": "You cut steps through the rock.", "stairs": "You build wooden stairs against the cliff.",
		"walkway": "You build a walkway across to the other top."}[what] + " The way runs both ways."


## The kind of way at a cell ("steps", "stairs", "walkway"), or "".
static func work_at(w: World, c: Vector2i) -> String:
	var o: Overworld = w.map.overworld
	if o == null or not o.works.has(c):
		return ""
	return str(o.works[c]).get_slice("_", 0)


## DVW-A10: the open cells reachable from `from` by four-neighbour steps over the world's collision (VillageMap.
## is_solid_world), within `radius` tiles (a bound: the world is endless). Used by the tests to show a top reached by a
## way is left by it, and that ground stays connected.
static func reachable(w: World, from: Vector2i, radius: int) -> Dictionary:
	var seen := {from: true}
	var q := [from]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d: Vector2i in DIRS:
			var n := c + d
			if seen.has(n) or absi(n.x - from.x) > radius or absi(n.y - from.y) > radius or w.map.is_solid_world(n):
				continue
			seen[n] = true
			q.append(n)
	return seen
