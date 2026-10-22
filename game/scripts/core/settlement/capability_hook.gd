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
static var profile := ""          # the profile the forced levels read; "" = the active one (neutral)


static func off() -> void:
	forced = {}
	profile = ""


static func time(base: float, industry: String) -> float:
	if forced.is_empty() or not forced.has(industry):
		return base
	return base / SettlementIndustries.output_multiplier(industry, int(forced[industry]), profile, true)


## A unit's work time where the worker's own Skill already shortens it (skill_time, the Skills time factor): off, exactly
## the existing base x skill_time; on, the two gains added over the base once each (no double counting,
## SettlementProductivity.unit_minutes).
static func work_time(base: float, industry: String, skill_time: float) -> float:
	if forced.is_empty() or not forced.has(industry):
		return base * skill_time
	return SettlementProductivity.unit_minutes(base, industry, int(forced[industry]), skill_time, profile, true)


static func pay(base: int, industry: String) -> int:
	if forced.is_empty() or not forced.has(industry):
		return base
	return roundi(float(base) * SettlementIndustries.pay_multiplier(industry, int(forced[industry]), profile, true))


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
