class_name CapabilityHook
extends RefCounted
## PROSPECTIVE (Expansion 18, X18-SIM; PROS-18): the one switch through which the LIVE production and wage code can feel a
## capability level, for analysis runs only (game/tests/economy_sim.gd --capability L --cap-profile NAME). OFF by
## default: `forced` is empty, so every call returns its base unchanged and the game behaves exactly as without it (the
## hook sites are marked "X18 HOOK"; the economy simulation's fingerprint is identical with the hook off).
##
## time(base, industry): the existing work time of one unit (a swing, a felling, a recipe run, a field's sowing or cutting)
##   divided by OutputMultiplier(industry, level): faster work. The work still ends in the existing rule that takes the
##   ore from the seam, the inputs from the pack, the crop from the field: capability never creates a resource.
## pay(base, industry): an existing wage times PayMultiplier(industry, level), paid from the same purse by the same rule.
## Industries with no level forced keep their base. A forced level is on the 0-10 scale, so mining (MIN-D's own stage
## scale, unmapped in the game) is forced like the others in analysis runs. Profiles come from settlement_industries.json;
## the active profile is the owner's "approved" one (Q18-11A closed, X18-CAPNUM, 2026-10-22).
## STAYS OFF IN THE GAME until the reconciliation (agent decision, X18-CAPNUM): the multipliers apply to the EFFECTIVE level
## (Q18-11B), and no live 0-10 level exists until the owner approves how workforce and effective levels are composed
## (X18-CAPCOMP); the settlement model's own levels are threshold steps (0-3), and reading them as 0-10 would invent a
## rule. A forced level stands for both the workforce and the effective level (no facility cap is invented).
## Farming (F1) is a work rate only: its hook sites shorten tilling, sowing, cutting, pen feeding and collecting (milk,
## wool, eggs); the field, seed, growth, crop and animal produce are untouched (yield_fixed). Its pay applies to paid farm
## labour at a game-set base rate (the harvest hand's wage, Quests.promised), never to crop prices or negotiated terms.

static var forced := {}           # industry -> level 0..10 (analysis only); empty = off
static var profile := ""          # the profile the forced levels read; "" = the active one
## X18-CAPCOMP part 1 (owner 2026-10-22): the PER-WORKER path, prepared and NOT ENABLED. Individual experience is the basis
## of individual performance and pay, so the modifiers will read each worker's own level (WorkExperience.level), not a
## settlement level: the Q18-11B effective level is each worker's own effective level. Nothing in the game sets
## `per_worker` or `experience`; until the facility and starting-experience rules are approved the hook stays off.
static var per_worker := false
static var experience: WorkExperience = null


static func off() -> void:
	forced = {}
	profile = ""
	per_worker = false
	experience = null


## The level the modifiers read for `who` in `industry`, or -1 for none (the base applies): a forced analysis level;
## else, only on the prepared per-worker path, the worker's own EFFECTIVE level (WorkExperience.effective_level:
## experience within the facility limit; none approved, so equal to experience), as whole levels (floor; the rounding
## rule is open, DECISIONS_PENDING.md D5).
static func level_for(industry: String, who = null) -> int:
	if forced.has(industry):
		return int(forced[industry])
	if per_worker and experience != null and who != null:
		return int(floor(experience.effective_level(WorkExperience.key_of(who), industry)))
	return -1


static func time(base: float, industry: String, who = null) -> float:
	var l := level_for(industry, who)
	if l < 0:
		return base
	return base / SettlementIndustries.output_multiplier(industry, l, profile, true)


## A unit's work time where the worker's own Skill already shortens it (skill_time, the Skills time factor): off, exactly
## the existing base x skill_time; on, the two gains added over the base once each (no double counting,
## SettlementProductivity.unit_minutes).
static func work_time(base: float, industry: String, skill_time: float, who = null) -> float:
	var l := level_for(industry, who)
	if l < 0:
		return base * skill_time
	return SettlementProductivity.unit_minutes(base, industry, l, skill_time, profile, true)


## A wage at a base rate; `who` the worker when the wage is set for a known worker (a job posted to nobody yet keeps
## the settlement path).
static func pay(base: int, industry: String, who = null) -> int:
	var l := level_for(industry, who)
	if l < 0:
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
