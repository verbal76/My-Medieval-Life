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
## Industries with no level forced keep their base. Profiles come from settlement_industries.json; the game's active
## profile is neutral and the analysis profiles are UNAPPROVED (Q18-11A).

static var forced := {}           # industry -> level 0..10 (analysis only); empty = off
static var profile := ""          # the profile the forced levels read; "" = the active one (neutral)


static func off() -> void:
	forced = {}
	profile = ""


static func time(base: float, industry: String) -> float:
	if forced.is_empty() or not forced.has(industry):
		return base
	return base / SettlementIndustries.output_multiplier(industry, int(forced[industry]), profile)


## A unit's work time where the worker's own Skill already shortens it (skill_time, the Skills time factor): off, exactly
## the existing base x skill_time; on, the two gains added over the base once each (no double counting,
## SettlementProductivity.unit_minutes).
static func work_time(base: float, industry: String, skill_time: float) -> float:
	if forced.is_empty() or not forced.has(industry):
		return base * skill_time
	return SettlementProductivity.unit_minutes(base, industry, int(forced[industry]), skill_time, profile)


static func pay(base: int, industry: String) -> int:
	if forced.is_empty() or not forced.has(industry):
		return base
	return roundi(float(base) * SettlementIndustries.pay_multiplier(industry, int(forced[industry]), profile))


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
