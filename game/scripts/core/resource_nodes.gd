class_name ResourceNodes
extends RefCounted
## The village's harvestable resource nodes, read-only: what each kind of node is (res://data/
## resources.json, GameData.resources), where its instances are in a World, what is left, and whether
## the player can harvest one now. It changes nothing: mining, felling, harvesting and hunting stay in
## World, main.gd and NPCBrain. Gather mode and the journal use only this API.
##
## A node definition ("def") is a Dictionary from resources.json "nodes", with its "id" added: name,
## category, origin, match, where, verb, action_label, action (interact | attack), tool (an item
## "tool" type such as "pickaxe", "weapon" for hunting, "" for none), tool_required, tool_hint,
## skill, level, yields, depletion, owner, theft, npc_harvest, player_harvest, gather, range (tiles),
## icon (an item id), sources, status. docs/systems/RESOURCE_NODE_MANIFEST.md lists them all.
##
## An instance ("ref") is the World's own record: a deposit or tree or field Dictionary
## (World.deposits, World.trees, World.fields) or an Animal (World.fauna.animals).
##
## Numbers in resources.json written as strings are balance.json keys, dotted for nested ones
## ("animals.boar.meat"): `number` resolves them.

const NEIGHBOURS := [Vector2i.ZERO, Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]   # main.gd _find_target's order


# ---------------------------------------------------------------- definitions ----------------
## Every node definition, by id.
static func defs() -> Dictionary:
	GameData.ensure()
	return GameData.resources.nodes


## The ids of every node definition, sorted.
static func ids() -> Array:
	var out := defs().keys()
	out.sort()
	return out


## One node definition, or {} for an unknown id.
static func def(id: String) -> Dictionary:
	return defs().get(id, {})


## A number from resources.json: an int or float as it is, a string as a balance.json key (dotted
## for a nested one, "animals.boar.meat").
static func number(v) -> float:
	if v is String:
		var at = GameData.balance
		for part in (v as String).split("."):
			at = at[part]
		return float(at)
	return float(v)


## The definition for an instance's kind: a deposit's ore, a tree, a field, an animal's species.
static func def_for(kind: String, key := "") -> Dictionary:
	for id in ids():
		var m: Dictionary = defs()[id].match
		if m.kind != kind:
			continue
		if kind == "deposit" and m.ore != key:
			continue
		if kind == "animal" and m.species != key:
			continue
		return defs()[id]
	return {}


## What one harvest cycle yields: item id -> count (balance keys resolved). An animal's is an
## adult's; a young one gives half the meat and no hide (Fauna.kill).
static func products(d: Dictionary) -> Dictionary:
	var out := {}
	for id in d.get("yields", {}):
		var n := int(number(d.yields[id]))
		if n > 0:
			out[id] = n
	return out


# ---------------------------------------------------------------- instances ------------------
## Every instance of a node kind in the world (worked-out seams, stumps, unripe fields included;
## dead animals are gone from the world).
static func instances(world: World, d: Dictionary) -> Array:
	var m: Dictionary = d.get("match", {})
	match str(m.get("kind", "")):
		"deposit":
			return world.deposits.filter(func(dp): return dp.ore == m.ore)
		"tree":
			return world.trees.duplicate()
		"field":
			return world.fields.duplicate()
		"animal":
			return world.fauna.animals.filter(func(a: Animal): return a.alive and a.species == m.species)
	return []


## The harvestable instance at a cell or beside it (its four neighbours, in the order the player's
## interaction looks), as {def, ref}; {} if none. Instances that cannot be harvested now (a worked-out
## seam, a stump, a field not ripe, the keeper's animals) are found too: can_harvest says why.
static func node_at(world: World, cell: Vector2i) -> Dictionary:
	for dc: Vector2i in NEIGHBOURS:
		var c: Vector2i = cell + dc
		var dep := world.deposit_at(c)
		if not dep.is_empty():
			return _found(def_for("deposit", str(dep.ore)), dep)
		var t := world.tree_at(c)
		if not t.is_empty():
			return _found(def_for("tree"), t)
		for f in world.fields:
			if Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(c):
				return _found(def_for("field"), f)
		for a: Animal in world.fauna.animals:
			if a.alive and a.cell() == c:
				return _found(def_for("animal", a.species), a)
	return {}


static func _found(d: Dictionary, ref) -> Dictionary:
	return {} if d.is_empty() else {"def": d, "ref": ref}


## Where an instance stands: a seam's or a tree trunk's cell, a field's middle cell, an animal's cell.
static func cell_of(_world: World, d: Dictionary, ref) -> Vector2i:
	match str(d.get("match", {}).get("kind", "")):
		"deposit", "tree":
			return Vector2i(int(ref.x), int(ref.y))
		"field":
			return Vector2i(int(ref.x) + int(ref.w) / 2, int(ref.y) + int(ref.h) / 2)
		"animal":
			return (ref as Animal).cell()
	return Vector2i.ZERO


## Units of the node's first product an instance holds now: a seam's amount, a grown tree's logs (4,
## before any skill bonus), a ripe field's crop, an animal's meat (half for a young one); 0 when there
## is nothing to take.
static func remaining(world: World, d: Dictionary, ref) -> int:
	match str(d.get("match", {}).get("kind", "")):
		"deposit":
			return maxi(0, int(ref.amount))
		"tree":
			return int(products(d).get("log", 0)) if ref.state == "grown" else 0
		"field":
			return maxi(0, int(ref.get("crop", 0))) if ref.state == "ripe" else 0
		"animal":
			var a := ref as Animal
			if a == null or not a.alive:
				return 0
			var meat := int(a.spec().meat)
			return meat if a.adult(world.minutes) else maxi(1, meat / 2)
	return 0


## Whether the player can harvest this instance now: "" if so, else the reason, in the game's words.
## Theft is not a refusal: a field worked by a farmer can be harvested, and theft_note says whose it is.
static func can_harvest(world: World, d: Dictionary, ref) -> String:
	if d.is_empty() or ref == null:
		return "There is nothing here to gather."
	var p := world.player
	if not bool(d.get("player_harvest", false)):
		return "These belong to the keeper. Killing them is theft."
	match str(d.match.kind):
		"deposit":
			if int(ref.amount) <= 0:
				return "The seam is worked out."
		"tree":
			match str(ref.state):
				"stump":
					return "Only a stump is left. It grows back in a few days."
				"sapling":
					return "The sapling is not grown yet."
				"cleared":
					return "The ground was cleared for building. Nothing grows here now."
		"field":
			if ref.state == "tilled":
				return "The field is not sown yet."
			if ref.state != "ripe":
				return "The wheat is not ripe yet."
			if int(ref.get("crop", 0)) <= 0:
				return "Nothing left to harvest."
		"animal":
			if not (ref as Animal).alive:
				return "It is gone."
	if bool(d.get("tool_required", false)) and p.tool_of(str(d.tool)) == "":
		return str(d.tool_hint)
	if str(d.get("skill", "")) != "" and int(d.get("level", 0)) > 1 and p.level(str(d.skill)) < int(d.level):
		return "Needs %s level %d." % [GameData.skills[d.skill].name, int(d.level)]
	return ""


## Whose an instance's yield is, when taking it is theft: "Fenn Ward's field: taking it is theft"
## (the words of the player's prompt), or "" when it is nobody's.
static func theft_note(world: World, d: Dictionary, ref) -> String:
	match str(d.get("match", {}).get("kind", "")):
		"field":
			for fo: NPC in world.field_workers(ref):
				return "%s %s's field: taking it is theft" % [fo.name, fo.family]
		"animal":
			var a := ref as Animal
			if a != null and not a.wild() and world.fauna.pens.has(a.area):
				var k := world.pen_keeper(world.fauna.pens[a.area])
				if k != null:
					return "%s %s's %s: killing it is theft" % [k.name, k.family, a.label()]
				return "The keeper's %s: killing it is theft" % a.label()
	return ""
