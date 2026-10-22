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
var inv := Inventory.new():
	set(v):
		inv = v
		_hook_pack()
## INV-18: the pack's upgrade stage, 0 to 2 (PACK_CAPS: 9, 18, 27 positions in each of the eight categories: one
## row of the 3 x 9 grid, then the second, then the third; owner INV-Q2). Saved. Raised only by buying the next row
## from the tailor (TAILOR-18), or directly by tests and the screenshot path.
var pack_level := 0:
	set(v):
		pack_level = clampi(v, 0, PACK_CAPS.size() - 1)
		_hook_pack()
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
var look := "player_m0_basic" # appearance id of Builds 7-17 (game/data/appearances.json); "" since CC-01
var appearance := {}          # CC-01: the look as a recipe {picks, swatches} (CharacterLook); {} = drawn from `sprite`
var heir_appearance := {}     # the look a relative heir takes (as heir_sprite)
var born := 0.0               # game minutes (B8-029); the player ages on the world calendar (Life.age_years)
var mother := -1              # npc id of a parent still in the village, -1 none (an heir who was a villager's child)
var father := -1
var partner := -1             # npc id, -1 none (Life.partner_player)
var children: Array = []      # npc ids: the children the player's family line can continue through
var crimes: Array = []        # {day, kind, what, victim, witnesses}: what the village saw the player do
var stolen := {}              # item id -> {owner npc id (string): count}: carried goods their owner knows as theirs
var chest_stolen := {}        # the same marks for goods kept in the home chest (they keep their marks there)
var quests: Array = []          # accepted side quests: {id, giver, day, target, reserved, wage (a harvest hand's, fixed at acceptance)} (scripts/core/quests.gd)
var spells := {}              # "fireball": true
var fireball_cd := 0.0
var attack_cd := 0.0
var home := ""                # the house the family lives in, one of those it holds (World.property.homes_of("player")): the
                              # heir's respawn point, its bed and chest ("" = homeless). What the family owns or
                              # leases is in the land registry under the owner reference "player" (World "ownership")
var chest := Inventory.new()  # the family chest, kept in the home (it moves with the family; out of reach while homeless)
var alive := true
var deaths := 0
var last_damage := ""        # the source of the last damage taken ("hunger", an attacker's name...)
var death_cause := ""        # the source that took hp to 0 (the death screen says it)

## The gear slots, in the order the pack window lists them. An item goes in the slot named by its
## type (items.json). The worn unit stays in the one store (`inv`) but takes no backpack position (INV-18).
const GEAR := ["weapon", "tool", "armor", "head", "amulet", "ring"]
const BASE_STAMINA := 100.0
## INV-18: positions per category at each pack_level (a 3 x 9 grid, one more row each upgrade; owner INV-Q2).
const PACK_CAPS := [9, 18, 27]
const PACK_COLUMNS := 9
const PACK_ROWS := 3


func _init() -> void:
	_hook_pack()


## The player's pack has a capacity per category and no overall kind limit (the 24 kinds of Builds 7-17 are gone).
func _hook_pack() -> void:
	if inv == null:
		return
	inv.max_stacks = 0
	inv.category_cap = PACK_CAPS[pack_level]
	inv.worn_fn = worn_counts


func pack_cap() -> int:
	return PACK_CAPS[pack_level]


## {item id: units worn}: what the gear slots hold (each item has one slot, so at most 1).
func worn_counts() -> Dictionary:
	var d := {}
	for slot in GEAR:
		var id := str(get(slot))
		if id != "":
			d[id] = int(d.get(id, 0)) + 1
	return d


## INV-18: "" when `slot` can come to hold `id` ("" = take off what is there); otherwise why not, naming the
## category the displaced item would go back to ("Armour inventory full: 18 of 18 slots."). It is refused only
## when the displaced item needs a new position and its category has none: the change is all or nothing.
func gear_refusal(slot: String, id: String) -> String:
	var old := str(get(slot))
	if old == "" or old == id or not inv.has(old) or inv.category_cap <= 0:
		return ""
	var cat := GameData.category(old)
	var before := inv.used(cat)
	set(slot, id)
	var after := inv.used(cat)
	set(slot, old)
	if after > before and after > inv.category_cap:
		return inv.full_text(old)
	return ""


func level(skill: String) -> int:
	return Skills.level(self, skill)


## (xp into the level, xp the level needs; 0 at the top level).
func xp_into_level(skill: String) -> Vector2i:
	return Skills.progress(int(skills.get(skill, 0)))


## Adds xp; returns the new level if it went up, else 0.
func gain(skill: String, xp: int) -> int:
	return Skills.gain(self, skill, xp)


## Being taught (a quest's "teach"): the skill goes up to the start of level `lv` if it is below
## it. Returns whether it went up.
func raise_to(skill: String, lv: int) -> bool:
	if level(skill) >= lv:
		return false
	skills[skill] = Skills.xp_for_level(lv)        # the start of level lv
	return true


func damage() -> float:
	var d := 2.0
	if weapon != "" and inv.has(weapon):
		d = float(GameData.item(weapon).get("damage", 2))
	return d * Skills.value(self, "combat", "damage_mult", 1.0)


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


## DVW-A12 R19 (B8-027): a sprint can start only with balance sprint_min_stamina.
func can_sprint() -> bool:
	return stamina >= float(GameData.b("sprint_min_stamina"))


## DVW-A12 R19: `delta` seconds of sprinting cost sprint_stamina_per_sec, net of the regeneration the world has just
## added (player_stamina_regen_per_second); never below 0. False when that leaves no breath (the sprint ends).
func sprint_drain(delta: float) -> bool:
	stamina = maxf(0.0, stamina - (float(GameData.b("sprint_stamina_per_sec")) + float(GameData.b("player_stamina_regen_per_second"))) * delta)
	return stamina > 0.0


## DVW-A12 R19: how much faster a sprint is than a walk (balance sprint_speed).
static func sprint_speed() -> float:
	return float(GameData.b("sprint_speed"))


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


## `qty` of `id` (default: the whole stack) went into the home chest or came out of it: that many marks
## go with them (stolen pieces first), so the chest does not wash stolen goods clean.
func store_marks(id: String, qty := -1) -> void:
	_move_marks(stolen, chest_stolen, id, qty)


func take_marks(id: String, qty := -1) -> void:
	_move_marks(chest_stolen, stolen, id, qty)
	trim_stolen()


static func _move_marks(from: Dictionary, to: Dictionary, id: String, qty := -1) -> void:
	if not from.has(id):
		return
	var m: Dictionary = to.get(id, {})
	var owners: Array = from[id].keys()
	owners.sort_custom(func(a, b): return int(a) < int(b))
	var left := qty if qty >= 0 else 1 << 30
	for o in owners:
		var k := mini(left, int(from[id][o]))
		if k <= 0:
			continue
		m[o] = int(m.get(o, 0)) + k
		from[id][o] = int(from[id][o]) - k
		left -= k
	to[id] = m
	var rest := 0
	for o in from[id]:
		rest += int(from[id][o])
	if rest <= 0:
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
		"alive": alive, "deaths": deaths, "last_damage": last_damage, "death_cause": death_cause, "tool": tool, "head": head, "amulet": amulet, "ring": ring, "sex": sex, "look": look, "appearance": appearance.duplicate(true), "heir_appearance": heir_appearance.duplicate(true), "born": born, "mother": mother, "father": father, "partner": partner, "children": children.duplicate(), "crimes": crimes.duplicate(true),
		"quests": quests.duplicate(true), "stolen": stolen.duplicate(true), "chest_stolen": chest_stolen.duplicate(true),
		"pack_level": pack_level,
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
	# INV-18 (save 19): a save of 18 or before had one pack of 24 kinds; every item, count and wear loads as saved
	# and the pack takes the category rule (pack_level 0 when absent). A category holding more kinds than its
	# capacity keeps them all and takes no new kind until under it (nothing is dropped)
	p.pack_level = int(d.get("pack_level", 0))
	p.inv = Inventory.from_dict(d.inv)
	p.chest = Inventory.from_dict(d.chest)
	for k in d.skills:
		p.skills[k] = int(d.skills[k])
	p.spells = d.spells.duplicate()
	# saves before property (1-4) list owned plots in "plots": World._migrate_property reads them
	p.alive = bool(d.alive)
	p.last_damage = str(d.get("last_damage", ""))     # older saves: no cause recorded
	p.death_cause = str(d.get("death_cause", ""))
	p.tool = str(d.get("tool", ""))                   # older saves: no tool slot, no look, no record
	for k in ["head", "amulet", "ring"]:               # older saves: no head, amulet or ring slot
		p.set(k, str(d.get(k, "")))
	p.sex = str(d.get("sex", "male"))
	p.look = str(d.get("look", ""))
	# CC-01 (save 18): the look is a recipe; a save of 17 or before holds only the look's id and sheets, which
	# migrate to the recipe the importer baked them from (game/data/appearances.json); any other sheet (a
	# villager's child, the old default) has no recipe and stays drawn from that sheet
	if d.has("appearance"):
		p.appearance = CharacterLook.normalize(d.appearance)
		p.heir_appearance = CharacterLook.normalize(d.get("heir_appearance", {}))
	else:
		p.appearance = CharacterLook.from_legacy(p.look, p.sprite)
		p.heir_appearance = CharacterLook.from_legacy("", p.heir_sprite)
	p.born = float(d.get("born", 0.0))
	for k in ["mother", "father", "partner"]:
		p.set(k, int(d.get(k, -1)))
	p.children = (d.get("children", []) as Array).map(func(c): return int(c))
	p.crimes = d.get("crimes", []).duplicate(true)
	p.quests = d.get("quests", []).duplicate(true)
	for q in p.quests:
		if q.has("reserved"):
			q.reserved = int(q.reserved)               # coins set aside stay whole numbers
	var marks: Dictionary = d.get("stolen", {})           # older saves: nothing marked
	for id in marks:
		for o in marks[id]:
			p.mark_stolen(str(id), int(o), int(marks[id][o]))
	p.chest_stolen = d.get("chest_stolen", {}).duplicate(true)
	return p
