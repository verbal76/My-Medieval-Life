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
		return float(balance_at(v))
	return float(v)


## A balance.json value by key, dotted for a nested one ("farming.caravan_seed_stock").
static func balance_at(key: String):
	GameData.ensure()
	var at = GameData.balance
	for part in key.split("."):
		at = at[part]
	return at


## The definition for an instance's kind: a deposit's ore, a tree, a field, an animal's species.
static func def_for(kind: String, key := "") -> Dictionary:
	for id in ids():
		var m: Dictionary = defs()[id].match
		if m.kind != kind:
			continue
		if kind in ["deposit", "boulder"] and m.ore != key:
			continue
		if kind == "animal" and m.species != key:
			continue
		if kind == "plant" and m.plant != key:
			continue
		if kind == "fruit_tree" and m.species != key:
			continue
		return defs()[id]
	return {}


## The definition of a deposit record: a seam of its ore, or (`boulder: true`) one of the small grey
## boulders, which give stone from a node of their own (B8-026). The sprite decides nothing: the record
## does (VillageMap.normalise_rocks draws each with the tile of its kind, "deposit_tiles").
static func def_for_deposit(dep: Dictionary) -> Dictionary:
	return def_for("boulder" if dep.get("boulder", false) else "deposit", str(dep.ore))


## Boulder sizes (PL1-06): a cell's boulder is small (the smaller sprite, `uses_small` pickaxe uses)
## or large (the full sprite, `uses`), from a hash of the cell alone, so it is the same in every game and
## needs no saving: only the uses left are saved.
const SMALL_BOULDER_PERCENT := 55


static func boulder_small(c: Vector2i) -> bool:
	var h: int = ((c.x * 73856093) ^ (c.y * 19349663) ^ 0x5bd1e995) & 0x7fffffff
	h = ((h >> 7) ^ h) & 0x7fffffff
	return h % 100 < SMALL_BOULDER_PERCENT


## Pickaxe uses (and stone) a fresh boulder on this cell holds.
static func boulder_uses(c: Vector2i) -> int:
	var d := def("boulder")
	return int(d.uses_small) if boulder_small(c) else int(d.uses)


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
			var out := world.deposits.filter(func(dp): return dp.ore == m.ore)
			if m.ore == "stone":                 # MIN-B: the host rock of worked-out ore seams is quarried as stone
				for dp in world.deposits:
					if dp.has("host") and int(dp.amount) <= 0:
						out.append(dp.host)
			return out
		"boulder":
			return world.boulders.filter(func(b): return int(b.amount) > 0)
		"tree":
			return world.trees.duplicate()
		"field":
			return world.fields.duplicate()
		"plant":
			return world.plants.filter(func(pl): return pl.kind == m.plant and pl.state != "cleared")
		"animal":
			return world.fauna.animals.filter(func(a: Animal): return a.alive and a.species == m.species)
		"clue":                                  # MIN-C: the prospecting clues (Prospecting.generate)
			return world.prospecting.clues.duplicate() if world.prospecting != null else []
	return []


## The harvestable instance at a cell or beside it (its four neighbours, in the order the player's
## interaction looks), as {def, ref}; {} if none. Instances that cannot be harvested now (a worked-out
## seam, a stump, a field not ripe, the keeper's animals) are found too: can_harvest says why.
## `exact`: only the cell itself (a tap or click names one thing; a tree counts on its trunk and
## the canopy cell above it, World.tree_at).
## It looks on the level the player is on (MIN-A): below the surface only the level's seams are there.
static func node_at(world: World, cell: Vector2i, exact := false) -> Dictionary:
	for dc: Vector2i in ([Vector2i.ZERO] if exact else NEIGHBOURS):
		var c: Vector2i = cell + dc
		var dep := world.deposit_at(c, world.player_level)
		if not dep.is_empty():
			return _found(def_for_deposit(dep), dep)
		if world.player_level != 0:
			continue
		var t := world.tree_at(c)
		if not t.is_empty():
			return _found(def_for("tree"), t)
		var pl := world.plant_at(c)
		if not pl.is_empty():
			return _found(def_for("plant", str(pl.kind)), pl)
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
		"deposit", "boulder", "tree", "plant", "clue":
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
		"deposit", "boulder":
			return maxi(0, int(ref.amount))
		"clue":
			return maxi(0, world.prospecting.samples_left(ref))
		"tree":
			return int(products(d).get("log", 0)) if ref.state == "grown" else 0
		"field":
			return maxi(0, int(ref.get("crop", 0))) if ref.state == "ripe" else 0
		"plant":
			return int(products(d).values()[0]) if ref.state == "ripe" else 0
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
		"deposit", "boulder":
			if int(ref.amount) <= 0:
				return "The seam is worked out." if str(d.match.kind) == "deposit" else "The boulder is broken up."
			if str(ref.get("ore", "")) == "gold_ore" and not Skills.has(p, "mining", "gold"):
				return "Gold needs Mining level 3."
		"tree":
			var why := Trees.refusal(str(ref.state))        # only a mature tree can be felled
			if why != "":
				return why
		"plant":
			if ref.state == "picked" and not world.plant_in_season(str(ref.get("kind", ""))):      # SEED-03
				return "Bare, or picked: it bears only in %s." % " and ".join(PackedStringArray(GameData.b("plant_seasons")[str(ref.kind)])).to_lower()
			if ref.state == "picked":
				return "Already picked. It grows back in a few days."
			if ref.state == "young":
				return "Young: it bears in a few days, in its season."
			if ref.state != "ripe":
				return "Nothing grows here now."
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
		"clue":
			if world.prospecting.samples_left(ref) <= 0:
				return "The ground round this stain has been sampled out."
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


# ---------------------------------------------------------------- uses and sources -----------
## Every use of an item, as {kind, id, qty, text, source}: kind is
##  - "recipe": a recipe consumes `qty` (id: the recipe; station, makes: its output);
##  - "buyer": a trade buys it, up to a stock of `qty` (id: NPCBrain.buy_role, from NPCBrain.BUYS);
##  - "export": the caravan buys it (NPCBrain.caravan);
##  - "building": a building of kind `id` takes `qty` (Construction.cost_of);
##  - "quest": a quest asks for `qty` (id: the quest);
##  - "food": eaten for `qty` food points;
##  - "equip": worn or wielded in the `id` slot (an item type);
##  - "tool": the tool a node needs (id: the node);
##  - the `use` of a resources.json "materials" note (fuel, feed, manor_job, home_cooking, granary, tool).
## Sorted by kind, then id. Data-derived uses come from the live data; notes from resources.json.
static func uses_of(item: String) -> Array:
	GameData.ensure()
	var out := []
	for r in _sorted(GameData.recipes):
		var rec: Dictionary = GameData.recipes[r]
		if rec.in.has(item):
			out.append({"kind": "recipe", "id": r, "qty": int(rec.in[item]), "station": str(rec.station), "makes": rec.out.duplicate(),
				"text": "%s at the %s" % [str(r).replace("_", " "), rec.station], "source": "game/data/recipes.json"})
	for role in _sorted(NPCBrain.BUYS):
		if NPCBrain.BUYS[role].has(item):
			out.append({"kind": "buyer", "id": role, "qty": int(NPCBrain.BUYS[role][item]), "text": "bought by the %s" % str(role).replace("_", " "),
				"source": "game/scripts/core/npc_brain.gd::wants"})
	if exported(item):
		out.append({"kind": "export", "id": "caravan", "qty": 0, "text": "bought by the passing caravan", "source": str(GameData.resources.exports.source)})
	var costs := {"house": GameData.b("house_cost")}
	for k in GameData.b("workshop_cost"):
		costs[k] = GameData.b("workshop_cost")[k]
	for k in _sorted(costs):
		if costs[k].has(item):
			out.append({"kind": "building", "id": k, "qty": int(costs[k][item]), "text": "building %s" % Construction.kind_name(k, true),
				"source": "game/scripts/core/construction.gd::cost_of"})
	for q in GameData.quests:
		if q.get("need", {}).has(item):
			out.append({"kind": "quest", "id": str(q.id), "qty": int(q.need[item]), "text": str(q.title), "source": "game/data/quests.json"})
	var it := GameData.item(item)
	if int(it.get("food", 0)) > 0:
		out.append({"kind": "food", "id": item, "qty": int(it.food), "text": "eaten (%d food)" % int(it.food), "source": "game/data/items.json"})
	if str(it.get("type", "")) in ["tool", "weapon", "armor", "head", "ring", "amulet"]:
		out.append({"kind": "equip", "id": str(it.type), "qty": 1, "text": "worn or used as a %s" % it.type, "source": "game/data/items.json"})
	if it.has("tool"):
		for id in ids():
			if str(def(id).get("tool", "")) == str(it.tool) and bool(def(id).get("tool_required", false)):
				out.append({"kind": "tool", "id": id, "qty": 1, "text": "the tool for %s" % str(def(id).verb).to_lower(), "source": "game/data/resources.json"})
	for n in GameData.resources.get("materials", {}).get(item, []):
		out.append({"kind": str(n.use), "id": item, "qty": 0, "text": str(n.text), "source": str(n.source)})
	out.sort_custom(ResourceNodes._by_kind_id)
	return out


## Whether the caravan buys this item: from a merchant (any item in a merchant's BUYS) or a smith
## (resources.json exports.smith_caps, the caps in NPCBrain.caravan).
static func exported(item: String) -> bool:
	GameData.ensure()
	if NPCBrain.NOT_EXPORTED.has(item):
		return false                              # the mine's raw output is not carried away
	for role in NPCBrain.BUYS:
		if str(role).begins_with("merchant_") and NPCBrain.BUYS[role].has(item):
			return true
	return GameData.resources.exports.smith_caps.has(item)


## Every source of an item, as {kind, id, qty, text, source}: kind is "node" (a node's yield per
## cycle), "recipe" (a recipe makes `qty`; uses: its inputs), "start_kit" (the player's start kit),
## "start_stock" (a one-time stock the code gives at the start: villagers, pantries, the granary) or
## "import" (the caravan). Sorted by kind, then id.
static func sources_of(item: String) -> Array:
	GameData.ensure()
	var out := []
	for id in ids():
		var p := products(def(id))
		if p.has(item):
			out.append({"kind": "node", "id": id, "qty": int(p[item]), "text": str(def(id).name), "source": "game/data/resources.json"})
	for r in _sorted(GameData.recipes):
		var rec: Dictionary = GameData.recipes[r]
		if rec.out.has(item):
			out.append({"kind": "recipe", "id": r, "qty": int(rec.out[item]), "station": str(rec.station), "uses": rec.in.duplicate(),
				"text": "%s at the %s" % [str(r).replace("_", " "), rec.station], "source": "game/data/recipes.json"})
	var kit: Dictionary = GameData.b("player_start_items")
	if kit.has(item):
		out.append({"kind": "start_kit", "id": "player_start_items", "qty": int(kit[item]), "text": "the player's start kit", "source": "game/data/balance.json"})
	var i := 0
	for n in GameData.resources.get("code_sources", []):
		if n.items.has(item):
			out.append({"kind": "start_stock", "id": "start_%d" % i, "qty": 0, "text": str(n.text), "source": str(n.source)})
		i += 1
	for n in GameData.resources.get("imports", []):
		var items: Array = n.get("items", [])
		if n.has("items_key"):
			items = (balance_at(str(n.items_key)) as Dictionary).keys()
		if items.has(item):
			out.append({"kind": "import", "id": "caravan", "qty": 0, "text": str(n.text), "source": str(n.source)})
	out.sort_custom(ResourceNodes._by_kind_id)
	return out


## What an item eventually becomes through recipes, `depth` steps deep:
## {item, becomes: [{recipe, station, with: the recipe's other inputs, makes: its outputs,
## then: [the chain of each output, one step less deep]}]}. An item already on the path is not
## followed again.
static func chain(item: String, depth := 3, _path := []) -> Dictionary:
	GameData.ensure()
	var out := {"item": item, "becomes": []}
	if depth <= 0 or _path.has(item):
		return out
	var path: Array = _path + [item]
	for r in _sorted(GameData.recipes):
		var rec: Dictionary = GameData.recipes[r]
		if not rec.in.has(item):
			continue
		var others: Dictionary = rec.in.duplicate()
		others.erase(item)
		var then := []
		for o in _sorted(rec.out):
			then.append(chain(o, depth - 1, path))
		out.becomes.append({"recipe": r, "station": str(rec.station), "with": others, "makes": rec.out.duplicate(), "then": then})
	return out


static func _sorted(d: Dictionary) -> Array:
	var k := d.keys()
	k.sort()
	return k


static func _by_kind_id(a: Dictionary, b: Dictionary) -> bool:
	return a.kind < b.kind or (a.kind == b.kind and str(a.id) < str(b.id))
