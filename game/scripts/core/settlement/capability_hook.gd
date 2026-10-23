class_name CapabilityHook
extends RefCounted
## Expansion 18 (X18-CAPNUM, X18-CAPCOMP): the one switch through which the LIVE production and wage code feels a
## capability level. `forced` is an analysis override (game/tests/economy_sim.gd --capability L --cap-profile NAME) and is
## empty in the game; the game's own path is the per-worker one (below). A site with no worker and no forced level
## returns its base unchanged (the hook sites are marked "X18 HOOK").
##
## time(base, industry): the existing work time of one unit (a swing, a felling, a recipe run, a field's sowing or cutting)
##   divided by OutputMultiplier(industry, level): faster work. The work still ends in the existing rule that takes the
##   ore from the seam, the inputs from the pack, the crop from the field: capability never creates a resource.
## pay(base, industry): an existing wage times PayMultiplier(industry, level), paid from the same purse by the same rule.
## Industries with no level forced keep their base. A forced level is on the 0-10 scale, so mining (MIN-D's own stage
## scale, unmapped in the game) is forced like the others in analysis runs. Profiles come from settlement_industries.json;
## the active profile is the owner's "approved" one (Q18-11A closed, X18-CAPNUM, 2026-10-22).
## ON IN THE GAME since 2026-10-23 (owner answers D1-D9, X18-CAPCOMP, X18-CAPNUM): the World binds its WorkExperience
## record (`bind`), and every hook site reads the working villager's (or the player's) own EFFECTIVE level (WorkExperience
## .effective_level: experience within the facility limit; none now, D2), the tables read between whole levels (D5).
## `forced` (analysis runs) still overrides it per industry.
## Farming (F1) is a work rate only: its hook sites shorten tilling, sowing, cutting, pen feeding and collecting (milk,
## wool, eggs); the field, seed, growth, crop and animal produce are untouched (yield_fixed). Its pay applies to paid farm
## labour at a game-set base rate (the harvest hand's wage, Quests.promised), never to crop prices or negotiated terms.

static var forced := {}           # industry -> level 0..10 (analysis only); empty = no forced level
static var profile := ""          # the profile the forced levels read; "" = the active one
## X18-CAPCOMP (owner 2026-10-22, answered 2026-10-23): the PER-WORKER path. Individual experience is the basis of
## individual performance and pay, so the modifiers read each worker's own level (WorkExperience.effective_level).
static var per_worker := false
static var experience: WorkExperience = null
## Analysis runs (tests/capability_metrics.gd) read the forced levels alone, as before: `bind` does nothing then.
static var analysis := false


## Switch the per-worker path on for this world's experience record (World calls it when it is made, loaded and updated).
static func bind(record: WorkExperience) -> void:
	if analysis:
		return
	per_worker = true
	experience = record


## Everything off: no forced level, no per-worker path (analysis baselines, tests of the unmodified rules).
static func off() -> void:
	forced = {}
	profile = ""
	per_worker = false
	experience = null
	analysis = false


## The level the modifiers read for `who` (an NPC, the player, or a key "player" / "npc:<id>") in `industry`, or -1 for
## none (the base applies): a forced analysis level; else the worker's own EFFECTIVE level on the per-worker path, real
## valued (the tables interpolate between whole levels, owner D5).
static func level_for(industry: String, who = null) -> float:
	if forced.has(industry):
		return float(forced[industry])
	if per_worker and experience != null and who != null:
		return experience.effective_level(WorkExperience.key_of(who), industry)
	return -1.0


## The work rate (output multiplier) of `who` in `industry`: 1.0 for none. A cutter's share of a field is minutes x this
## (owner D7: work done in base-minute equivalents).
static func rate(industry: String, who = null) -> float:
	var l := level_for(industry, who)
	if l < 0.0:
		return 1.0
	return SettlementIndustries.output_multiplier(industry, l, profile, true)


static func time(base: float, industry: String, who = null) -> float:
	var l := level_for(industry, who)
	if l < 0.0:
		return base
	return base / SettlementIndustries.output_multiplier(industry, l, profile, true)


## A unit's work time where the worker's own Skill already shortens it (skill_time, the Skills time factor): off, exactly
## the existing base x skill_time; on, the two gains added over the base once each (no double counting,
## SettlementProductivity.unit_minutes).
static func work_time(base: float, industry: String, skill_time: float, who = null) -> float:
	var l := level_for(industry, who)
	if l < 0.0:
		return base * skill_time
	return SettlementProductivity.unit_minutes(base, industry, l, skill_time, profile, true)


## A wage at a base rate for a known worker `who`; rounded to the nearest whole coin (owner D8: as before, 6.24 is 6, no
## carried fractions). With no worker (a wage posted to nobody yet) the base stands; the manor's board and the harvest
## hand set the wage when the worker takes the job (owner D6).
static func pay(base: int, industry: String, who = null) -> int:
	var l := level_for(industry, who)
	if l < 0.0:
		return base
	return roundi(float(base) * SettlementIndustries.pay_multiplier(industry, l, profile, true))


## The productive industry a recipe belongs to, by its station (forge, anvil: smithing; sawhorse: carpentry; workbench:
## tanning when it works hides, pelts or leather, else the industry of its output in effects.outputs, e.g. a handcart:
## carpentry). Cooking, brewing, weaving and sewing have no industry in the settlement schema yet: "" (no effect).
static func recipe_industry(rid: String) -> String:
	var rec: Dictionary = GameData.recipes.get(rid, {})
	match str(rec.get("station", "")):
		"forge", "anvil":
			return "smithing"
		"sawhorse":
			return "carpentry"
		"workbench":
			for id in rec.get("in", {}):
				if id in ["hide", "rabbit_pelt", "leather"]:
					return "tanning"
			for id in rec.get("out", {}):
				var ind := SettlementIndustries.industry_of(str(id))
				if ind != "":
					return ind
	return ""
