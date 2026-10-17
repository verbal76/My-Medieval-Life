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
var spells := {}              # "fireball": true
var fireball_cd := 0.0
var attack_cd := 0.0
var home := ""                # building id of the player's own house ("" = sleeps at the inn)
var chest := Inventory.new()  # storage in the player's house
var plots: Array = []         # plot ids owned
var alive := true
var deaths := 0


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


func defense() -> float:
	if armor != "" and inv.has(armor):
		return float(GameData.item(armor).get("armor", 0))
	return 0.0


func to_dict() -> Dictionary:
	return {
		"name": name, "family": family, "generation": generation, "sprite": sprite, "heir_sprite": heir_sprite,
		"pos": [pos.x, pos.y], "inv": inv.to_dict(), "coins": coins, "hp": hp, "max_hp": max_hp,
		"hunger": hunger, "stamina": stamina, "skills": skills.duplicate(), "weapon": weapon, "armor": armor,
		"spells": spells.duplicate(), "home": home, "chest": chest.to_dict(), "plots": plots.duplicate(),
		"alive": alive, "deaths": deaths,
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
	p.plots = d.plots.duplicate()
	p.alive = bool(d.alive)
	return p
