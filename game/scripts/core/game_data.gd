class_name GameData
extends RefCounted
## Static game data from res://data/*.json (items, recipes, skills, balance, quests, resources). Loaded once.

static var items := {}
static var recipes := {}
static var skills := {}
static var skill_cfg := {}                # skills.json whole: the xp curve and ranks (see Skills)
static var balance := {}
static var quests := []                   # side quests (res://data/quests.json)
static var resources := {}                # resource nodes and uses (res://data/resources.json; read through ResourceNodes)
static var _loaded := false


static func ensure() -> void:
	if _loaded:
		return
	items = _read("res://data/items.json").items
	recipes = _read("res://data/recipes.json").recipes
	skill_cfg = _read("res://data/skills.json")
	skills = skill_cfg.skills
	balance = _read("res://data/balance.json")
	quests = _read("res://data/quests.json").quests
	resources = _read("res://data/resources.json")
	for id in resources.nodes:
		resources.nodes[id].id = id
	_loaded = true


static func _read(path: String) -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(d is Dictionary, "bad data file " + path)
	return d


static func b(key: String):
	ensure()
	return balance[key]


static func item(id: String) -> Dictionary:
	ensure()
	return items.get(id, {})


static func item_name(id: String) -> String:
	return item(id).get("name", id)


## What eating or drinking `id` does, read from the item's own data (the same fields World.player_eat
## applies: "heal" health, "food" hunger, "stamina"; "harm" is the damage it does). Medicines have "heal"
## and no "food" (World.player_use_medicine). [] for a non-consumable.
static func effects(id: String) -> Array:
	var it := item(id)
	var out := []
	if not it.has("food") and not it.has("heal"):
		return out
	if int(it.get("heal", 0)) > 0:
		out.append(["Health", int(it.heal)])
	if int(it.get("food", 0)) > 0:
		out.append(["Food", int(it.food)])
	if int(it.get("stamina", 0)) > 0:
		out.append(["Stamina", int(it.stamina)])
	return out


## "Restores 12 Health / 4 Food" (plus " / Harms 3 Health" for spoiled food), or "" for a non-consumable.
static func effect_text(id: String) -> String:
	var parts := []
	for e in effects(id):
		parts.append("%d %s" % [e[1], e[0]])
	if parts.is_empty():
		return ""
	var s := "Restores " + " / ".join(parts)
	var harm := int(item(id).get("harm", 0))
	if harm > 0:
		s += " / Harms %d Health" % harm
	return s


static func value(id: String) -> int:
	return int(item(id).get("value", 1))


static func recipes_at(station: String) -> Array:
	ensure()
	var out := []
	for r in recipes:
		if recipes[r].station == station:
			out.append(r)
	out.sort()
	return out
