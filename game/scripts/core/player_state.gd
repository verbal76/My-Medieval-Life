class_name PlayerState
extends RefCounted
## The player character: the same inventory, coin and recipe rules as NPCs, plus skills,
## equipment and the family line that continues after permanent death.

var name := "Wat"
var family := "Ashdown"
var generation := 1
var sprite := "res://assets/characters/player_00.png"
var heir_sprite := "res://assets/characters/player_01.png"
var pos := Vector2.ZERO
var inv := Inventory.new()
var coins := 0
var hp := 40.0
var max_hp := 40.0
var hunger := 100.0
var stamina := 100.0
var skills := {}              # skill -> xp
var weapon := ""              # equipped item id
var armor := ""
var tool := ""                # the tool in hand (a pickaxe or an axe)
var head := ""                # a cap or helmet
var amulet := ""
var ring := ""
var sex := "male"             # chosen at character creation
var look := "player_m0_basic" # appearance id (game/data/appearances.json)
var crimes: Array = []        # {day, kind, what, victim, witnesses}: what the village saw the player do
var stolen := {}              # item id -> {owner npc id (string): count}: carried goods their owner knows as theirs
var chest_stolen := {}        # the same marks for goods kept in the home chest (they keep their marks there)
var quests: Array = []          # accepted side quests: {id, giver, day, target} (scripts/core/quests.gd)
var spells := {}              # "fireball": true
var fireball_cd := 0.0
var attack_cd := 0.0
var home := ""                # the house the family lives in, one of those it holds (World.property.homes_of("player")): the
                              # heir's respawn point, its bed and chest ("" = homeless). What the family owns or
                              # leases is in the land registry under the owner reference "player" (World "ownership")
var chest := Inventory.new()  # the family chest, kept in the home (it moves with the family; out of reach while homeless)
var alive := true
var deaths := 0

## The gear slots, in the order the pack window lists them. An item goes in the slot named by its
## type (items.json); the item stays in the pack while it is worn.
const GEAR := ["weapon", "tool", "armor", "head", "amulet", "ring"]
const BASE_STAMINA := 100.0


func _init() -> void:
	inv.max_stacks = 24


func level(skill: String) -> int:
	var xp := int(skills.get(skill, 0))
	var lv := 1
	while xp >= 100 * lv:
		xp -= 100 * lv
		lv += 1
	return lv


func xp_into_level(skill: String) -> Vector2i:
	var xp := int(skills.get(skill, 0))
	var lv := 1
	while xp >= 100 * lv:
		xp -= 100 * lv
		lv += 1
	return Vector2i(xp, 100 * lv)


## Adds xp; returns the new level if it went up, else 0.
func gain(skill: String, xp: int) -> int:
	var before := level(skill)
	skills[skill] = int(skills.get(skill, 0)) + xp
	var after := level(skill)
	return after if after > before else 0


## Being taught (a quest's "teach"): the skill goes up to the start of level `lv` if it is below
## it. Returns whether it went up.
func raise_to(skill: String, lv: int) -> bool:
	if level(skill) >= lv:
		return false
	skills[skill] = 50 * lv * (lv - 1)             # 100 + 200 + ... + 100 (lv - 1): the start of level lv
	return true


func damage() -> float:
	var d := 2.0
	if weapon != "" and inv.has(weapon):
		d = float(GameData.item(weapon).get("damage", 2))
	var lv := level("combat")
	if lv >= 2:
		d *= 1.2
	if lv >= 4:
		d *= 1.2
	return d


## The tool of a kind the player uses: the one in hand if it is of that kind, else the best carried.
func tool_of(kind: String) -> String:
	if tool != "" and inv.has(tool) and GameData.item(tool).get("tool", "") == kind:
		return tool
	var best := ""
	for id in inv.ids():
		if GameData.item(id).get("tool", "") == kind and (best == "" or float(GameData.item(id).get("speed", 1.0)) > float(GameData.item(best).get("speed", 1.0))):
			best = id
	return best


## Armour from what is worn on the body and the head.
func defense() -> float:
	var d := 0.0
	for id in [armor, head]:
		if id != "" and inv.has(id):
			d += float(GameData.item(id).get("armor", 0))
	return d


## The sum of one bonus ("max_hp", "max_stamina") over the gear worn (items.json "bonus").
func bonus(stat: String) -> float:
	var total := 0.0
	for slot in GEAR:
		var id: String = get(slot)
		if id != "" and inv.has(id):
			total += float(GameData.item(id).get("bonus", {}).get(stat, 0))
	return total


## Most health and stamina the player can have, with what the gear worn adds.
func hp_cap() -> float:
	return max_hp + bonus("max_hp")


func stamina_cap() -> float:
	return BASE_STAMINA + bonus("max_stamina")


## Health and stamina above the caps (after taking off a ring or an amulet) come down to them.
func fit_caps() -> void:
	hp = minf(hp, hp_cap())
	stamina = minf(stamina, stamina_cap())


## Stolen goods (owner rule): each carried piece taken from someone is marked with whose it was, so
## the owner knows it if it is offered back to them. Marks never outnumber what is carried: goods
## eaten, dropped, sold, stored or used up lose their marks (trim_stolen), the lowest owner id first.
func mark_stolen(id: String, owner: int, n := 1) -> void:
	if n <= 0:
		return
	var m: Dictionary = stolen.get(id, {})
	m[str(owner)] = int(m.get(str(owner), 0)) + n
	stolen[id] = m
	trim_stolen()


## Take up to `n` marks of `id` off: `owner`'s first, then anyone's.
func unmark(id: String, owner: int, n := 1) -> void:
	var m: Dictionary = stolen.get(id, {})
	var k := mini(n, int(m.get(str(owner), 0)))
	if k > 0:
		m[str(owner)] = int(m[str(owner)]) - k
		n -= k
	for o in _owners(id):
		if n <= 0:
			break
		var t := mini(n, int(m[o]))
		m[o] = int(m[o]) - t
		n -= t
	_tidy(id)


## The whole carried stack of `id` went into the home chest (or came out of it): its marks go with it,
## so the chest does not wash stolen goods clean.
func store_marks(id: String) -> void:
	_move_marks(stolen, chest_stolen, id)


func take_marks(id: String) -> void:
	_move_marks(chest_stolen, stolen, id)
	trim_stolen()


static func _move_marks(from: Dictionary, to: Dictionary, id: String) -> void:
	if not from.has(id):
		return
	var m: Dictionary = to.get(id, {})
	for o in from[id]:
		m[o] = int(m.get(o, 0)) + int(from[id][o])
	to[id] = m
	from.erase(id)


func trim_stolen() -> void:
	for id in stolen.keys():
		var over := stolen_count(id, false) - inv.count(id)
		if over > 0:
			unmark(id, -1, over)
		_tidy(id)


## How many carried `id` are stolen.
func stolen_count(id: String, trim := true) -> int:
	if trim:
		trim_stolen()
	var t := 0
	for o in stolen.get(id, {}):
		t += int(stolen[id][o])
	return t


func _owners(id: String) -> Array:
	var keys: Array = stolen.get(id, {}).keys()
	keys.sort_custom(func(a, b): return int(a) < int(b))
	return keys


func _tidy(id: String) -> void:
	if not stolen.has(id):
		return
	var m: Dictionary = stolen[id]
	for o in m.keys():
		if int(m[o]) <= 0:
			m.erase(o)
	if m.is_empty():
		stolen.erase(id)


func to_dict() -> Dictionary:
	return {
		"name": name, "family": family, "generation": generation, "sprite": sprite, "heir_sprite": heir_sprite,
		"pos": [pos.x, pos.y], "inv": inv.to_dict(), "coins": coins, "hp": hp, "max_hp": max_hp,
		"hunger": hunger, "stamina": stamina, "skills": skills.duplicate(), "weapon": weapon, "armor": armor,
		"spells": spells.duplicate(), "home": home, "chest": chest.to_dict(),
		"alive": alive, "deaths": deaths, "tool": tool, "head": head, "amulet": amulet, "ring": ring, "sex": sex, "look": look, "crimes": crimes.duplicate(true),
		"quests": quests.duplicate(true), "stolen": stolen.duplicate(true), "chest_stolen": chest_stolen.duplicate(true),
	}


static func from_dict(d: Dictionary) -> PlayerState:
	var p := PlayerState.new()
	for k in ["name", "family", "sprite", "heir_sprite", "weapon", "armor", "home"]:
		p.set(k, str(d[k]))
	for k in ["generation", "coins", "deaths"]:
		p.set(k, int(d[k]))
	for k in ["hp", "max_hp", "hunger", "stamina"]:
		p.set(k, float(d[k]))
	p.pos = Vector2(float(d.pos[0]), float(d.pos[1]))
	p.inv = Inventory.from_dict(d.inv)
	p.chest = Inventory.from_dict(d.chest)
	for k in d.skills:
		p.skills[k] = int(d.skills[k])
	p.spells = d.spells.duplicate()
	# saves before property (1-4) list owned plots in "plots": World._migrate_property reads them
	p.alive = bool(d.alive)
	p.tool = str(d.get("tool", ""))                   # older saves: no tool slot, no look, no record
	for k in ["head", "amulet", "ring"]:               # older saves: no head, amulet or ring slot
		p.set(k, str(d.get(k, "")))
	p.sex = str(d.get("sex", "male"))
	p.look = str(d.get("look", ""))
	p.crimes = d.get("crimes", []).duplicate(true)
	p.quests = d.get("quests", []).duplicate(true)
	var marks: Dictionary = d.get("stolen", {})           # older saves: nothing marked
	for id in marks:
		for o in marks[id]:
			p.mark_stolen(str(id), int(o), int(marks[id][o]))
	p.chest_stolen = d.get("chest_stolen", {}).duplicate(true)
	return p
