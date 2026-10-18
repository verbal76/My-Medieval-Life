class_name GameData
extends RefCounted
## Static game data from res://data/*.json (items, recipes, skills, balance, quests). Loaded once.

static var items := {}
static var recipes := {}
static var skills := {}
static var balance := {}
static var quests := []                   # side quests (res://data/quests.json)
static var _loaded := false


static func ensure() -> void:
	if _loaded:
		return
	items = _read("res://data/items.json").items
	recipes = _read("res://data/recipes.json").recipes
	skills = _read("res://data/skills.json").skills
	balance = _read("res://data/balance.json")
	quests = _read("res://data/quests.json").quests
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
