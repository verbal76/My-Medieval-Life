class_name Skills
extends RefCounted
## The skill curve and tiers (PL2-005), read from res://data/skills.json. Pure functions: the xp a
## level needs, the level an xp total is, the tier effects a player has (`value`), and the text the
## skills window and the wiki print for them (generated from the same numbers the code reads).
## Saves keep their xp numbers untouched; only the level they work out to follows this curve.

## Every effect key a tier may define, how it prints, and the file that reads it. `mode`: pct (x100),
## less (1 - x as a percentage), mult (x as "1.5"), int, sec (seconds), flag (the text alone).
## tests/skills_test.gd checks every key in skills.json is here and that the file named reads it.
const EFFECTS := {
	"ore_extra_chance": {"fmt": "%s chance of an extra ore a swing", "mode": "pct", "code": "scripts/core/world.gd"},
	"tool_wear_save": {"fmt": "%s chance a swing does not wear the pickaxe", "mode": "pct", "code": "scripts/core/world.gd"},
	"mine_time": {"fmt": "swings take %s less time", "mode": "less", "code": "scripts/main.gd"},
	"gold": {"fmt": "Mine gold ore", "mode": "flag", "code": "scripts/core/world.gd"},
	"log_bonus": {"fmt": "extra logs from each tree: %s", "mode": "int", "code": "scripts/main.gd"},
	"chop_time": {"fmt": "chopping takes %s less time", "mode": "less", "code": "scripts/main.gd"},
	"axe_wear_save": {"fmt": "%s chance a blow does not wear the axe", "mode": "pct", "code": "scripts/core/world.gd"},
	"sapling_bonus": {"fmt": "%s chance of a second sapling from a felled tree", "mode": "pct", "code": "scripts/main.gd"},
	"craft_time": {"fmt": "work at the station takes %s less time", "mode": "less", "code": "scripts/main.gd"},
	"save_chance": {"fmt": "%s chance the materials are not used up", "mode": "pct", "code": "scripts/core/world.gd"},
	"bonus_chance": {"fmt": "%s chance of one extra unit when the product is not gear", "mode": "pct", "code": "scripts/core/world.gd"},
	"damage_mult": {"fmt": "damage x%s", "mode": "mult", "code": "scripts/core/player_state.gd"},
	"attack_time": {"fmt": "swings come %s sooner", "mode": "less", "code": "scripts/main.gd"},
	"damage_taken": {"fmt": "%s less damage taken", "mode": "less", "code": "scripts/core/world.gd"},
	"crit_chance": {"fmt": "%s chance of a double-damage blow", "mode": "pct", "code": "scripts/main.gd"},
	"fireball_cooldown": {"fmt": "Fireball cooldown %s", "mode": "sec", "code": "scripts/main.gd"},
	"fireball_damage": {"fmt": "Fireball damage x%s", "mode": "mult", "code": "scripts/main.gd"},
	"fireball_stamina": {"fmt": "Fireball costs %s less stamina", "mode": "less", "code": "scripts/main.gd"},
	"price_bonus": {"fmt": "%s better prices (buying and selling)", "mode": "pct", "code": "scripts/core/world.gd"},
	"pickpocket_steps": {"fmt": "pickpocket chance %s", "mode": "pickpocket", "code": "scripts/core/world.gd"},
	"guard_radius": {"fmt": "a guard hears a caught try only within %s of the usual distance", "mode": "pct", "code": "scripts/core/world.gd"},
}


static func cfg() -> Dictionary:
	GameData.ensure()
	return GameData.skill_cfg


static func max_level() -> int:
	return int(cfg().max_level)


## The xp to climb from level `lv` to the next.
static func step(lv: int) -> int:
	return roundi(float(cfg().step_base) * lv * (1.0 + float(cfg().step_growth) * (lv - 1)))


## The xp total at which `lv` begins (level 1 begins at 0).
static func xp_for_level(lv: int) -> int:
	var total := 0
	for l in range(1, mini(lv, max_level())):
		total += step(l)
	return total


static func level_of(xp: int) -> int:
	var lv := 1
	while lv < max_level() and xp >= xp_for_level(lv + 1):
		lv += 1
	return lv


## (xp into the level, xp the level needs); at the top level the needed part is 0.
static func progress(xp: int) -> Vector2i:
	var lv := level_of(xp)
	return Vector2i(xp - xp_for_level(lv), 0 if lv >= max_level() else step(lv))


static func rank(lv: int) -> String:
	var best := ""
	var best_l := 0
	for k in cfg().ranks:
		if int(k) <= lv and int(k) >= best_l:
			best_l = int(k)
			best = str(cfg().ranks[k])
	return best


static func tier_levels(skill: String) -> Array:
	var ls: Array = GameData.skills[skill].tiers.keys().map(func(k): return int(k))
	ls.sort()
	return ls


## PAR-01 (owner OD-18.1): the player and every villager keep their skills the same way (`skills`: skill -> xp) and
## climb the same curve. `who` is a PlayerState or an NPC.
static func level(who, skill: String) -> int:
	return level_of(int(who.skills.get(skill, 0)))


## Combat xp for killing an animal (hunting or slaughter), one rule for the player and villagers (FSE-B12): 2 xp for
## each blow the kill takes at the killer's damage (`damage`, before chance doubling): the player's old 2 xp a blow, given
## once at the kill so a villager's single hunting act earns the same as the player's chase.
static func kill_xp(species: String, damage: float) -> int:
	var hp := float(GameData.b("animals")[species].hp)
	return 2 * int(ceil(hp / maxf(damage, 0.5)))


## Adds xp to `who`; returns the new level if it went up, else 0.
static func gain(who, skill: String, xp: int) -> int:
	if xp <= 0:
		return 0
	var before := level(who, skill)
	who.skills[skill] = int(who.skills.get(skill, 0)) + xp
	var after := level(who, skill)
	return after if after > before else 0


## PAR-01A (owner's final directive, section 2): the presumed history of an established villager before the world
## begins, {skill: xp}: a tenure in `job` of a fixed share (`share`, 0..1, the person's own) of the working years their
## age allows, from skill_start.tenure_min of them up to all, capped at max_tenure_years, at xp_per_year, in that
## trade's skills only. Used only by seed_villagers.
static func start_xp(job: String, age_years: float, share: float) -> Dictionary:
	var c: Dictionary = GameData.b("skill_start")
	var working := maxf(0.0, age_years - float(c.from_age))
	var tenure := minf(working * lerpf(float(c.tenure_min), 1.0, clampf(share, 0.0, 1.0)), float(c.max_tenure_years))
	var out := {}
	for sk in c.job_skills.get(job, []):
		out[str(sk)] = roundi(tenure * float(c.xp_per_year))
	return out


## A person's fixed share of their working years spent in their trade (start_xp): from their id and the world seed.
static func tenure_share(w: World, n: NPC) -> float:
	return float(posmod(n.id * 7919 + int(w.seed) * 104729, 1000)) / 999.0


## The one-time starting allocation (PAR-01A): only at World.setup (a new world's settlers) and when a save from
## before skills existed (save_version < 15) is loaded. Experience already recorded is never replaced. Deterministic.
static func seed_villagers(w: World) -> void:
	for n: NPC in w.npcs:
		if n.alive and n.skills.is_empty() and n.role in ["adult", "elder", "bandit"]:
			var job := n.job if n.role != "bandit" else "guard"
			n.skills = start_xp(job, Life.npc_age(w, n), tenure_share(w, n))


## The value of a tier effect for the player or a villager: the highest tier at or below their level that defines
## the key, else `default`.
static func value(who, skill: String, key: String, default := 0.0) -> float:
	return value_at(level(who, skill), skill, key, default)


static func value_at(lv: int, skill: String, key: String, default := 0.0) -> float:
	GameData.ensure()
	var out := default
	var tiers: Dictionary = GameData.skills[skill].tiers
	for l in tier_levels(skill):
		if l > lv:
			break
		var fx: Dictionary = tiers[str(l)].get("effects", {})
		if fx.has(key):
			out = float(fx[key])
	return out


static func has(who, skill: String, key: String) -> bool:
	return value(who, skill, key) > 0.0


## Items that are gear (never doubled by a bonus roll).
static func is_gear(id: String) -> bool:
	var it: Dictionary = GameData.item(id)
	return it.has("damage") or it.has("armor") or it.has("tool") or it.has("bonus")


## The xp a trade of `coins` earns: a little for any, more for a big deal.
static func trade_xp(coins: int) -> int:
	return clampi(2 + coins / 5, 2, 30)


static func describe(key: String, v: float) -> String:
	var e: Dictionary = EFFECTS[key]
	var s := ""
	match str(e.mode):
		"pct": s = "%d%%" % roundi(v * 100.0)
		"less": s = "%d%%" % roundi((1.0 - v) * 100.0)
		"mult": s = String.num(v, 2)
		"int": s = "%d" % int(v)
		"sec": s = "%ss" % String.num(v, 1)
		"pickpocket":
			var c := minf(float(GameData.b("pickpocket_chance")) + float(GameData.b("pickpocket_chance_per_level")) * v, float(GameData.b("pickpocket_chance_max")))
			s = "%d%%" % roundi(c * 100.0)
	return str(e.fmt) % s if "%s" in str(e.fmt) else str(e.fmt)


## One line for a tier: its text, then each effect's numbers, then the recipes it opens.
static func tier_text(skill: String, lv: int) -> String:
	var t: Dictionary = GameData.skills[skill].tiers.get(str(lv), {})
	var parts := []
	if str(t.get("text", "")) != "":
		parts.append(str(t.text))
	for key in t.get("effects", {}):
		var d := describe(str(key), float(t.effects[key]))
		if d != str(t.get("text", "")):
			parts.append(d)
	var rec := recipes_at(skill, lv)
	if not rec.is_empty():
		parts.append("recipes: " + ", ".join(rec))
	return "; ".join(parts)


## Names of the recipes whose skill and level are exactly `lv`.
static func recipes_at(skill: String, lv: int) -> Array:
	GameData.ensure()
	var out := []
	for r in GameData.recipes:
		var rec: Dictionary = GameData.recipes[r]
		if str(rec.skill) == skill and int(rec.level) == lv:
			out.append(GameData.item_name(str(rec.out.keys()[0])).to_lower())
	out.sort()
	return out


## Levels that have something to show: a tier or a recipe.
static func shown_levels(skill: String) -> Array:
	var ls := tier_levels(skill)
	for r in GameData.recipes.values():
		if str(r.skill) == skill and not ls.has(int(r.level)):
			ls.append(int(r.level))
	ls.sort()
	return ls
