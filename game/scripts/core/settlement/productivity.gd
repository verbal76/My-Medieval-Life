class_name SettlementProductivity
extends RefCounted
## PROSPECTIVE (Expansion 18, Q18-11; PROS-18): how a capability level's output and pay multipliers act, without ever
## creating a raw material or a coin (owner master directive 2026-10-21 section 5, "Economic safeguards").
##
## Output: OutputMultiplier means FASTER WORK -- less time per unit of the existing work (World's mine_minutes and
## chop_minutes, a recipe's minutes, the farmers' field work). Every unit made still consumes its full recipe inputs, or
## takes one unit from its deposit, or one unit of a field's grown crop; when the inputs, the seam or the crop run out,
## a faster worker makes nothing more. There is no waste term of the settlement's own: the only existing one is the
## individual skill effect `save_chance` ("a practised hand wastes nothing", World.work_craft), which stays the
## worker's (below), so the settlement never reduces waste.
##
## Pay: AdjustedPay = BasePay x PayMultiplier, the base an existing wage or fee; the coins still move from a real purse
## to the worker (the multiplier changes the agreed amount, never creates the coins).
##
## No double counting (RESEARCH_DIGEST.md (e): Caplin et al.'s total return = a firm-specific part + a portable part,
## each counted once). The settlement capability is the PLACE-SPECIFIC component; a worker's own Skills (Skills.EFFECTS)
## are the PORTABLE component. Rules:
##   1. The settlement acts only on time per unit and on pay (SETTLEMENT_EFFECTS). It never adds to the quantity effects
##      the Skills own (extra ore, saved inputs, bonus units, extra logs, saplings: SKILL_QUANTITY_EFFECTS).
##   2. Where a Skill already shortens the same work (mine_time, chop_time, craft_time: a time factor t, 0.8 = 20% less
##      time), the two GAINS ADD over the base time: time = base / (1 + g_skill + g_place), with g_skill = 1 / t - 1 and
##      g_place =
##      OutputMultiplier - 1. They do not compound, and the settlement curve is defined net of the portable part (it is
##      calibrated as the place-specific share only, CAPABILITY_CURVES.md).
##   3. Pay: individual skill has no wage effect in the game (price_bonus is a price effect of the trading skill, not a
##      wage), so the pay multiplier is the only level effect on wages; it is never applied to prices.

const SETTLEMENT_EFFECTS := ["unit_time", "pay"]
const SKILL_QUANTITY_EFFECTS := ["ore_extra_chance", "save_chance", "bonus_chance", "log_bonus", "sapling_bonus"]
const SKILL_TIME_EFFECTS := {"mining": "mine_time", "forestry": "chop_time", "smithing": "craft_time", "carpentry": "craft_time",
	"tanning": "craft_time"}


## Minutes one unit takes: the base time, shortened by the worker's own skill (skill_time, the Skills time factor, 1.0 =
## none) and the settlement's level, their gains added over the base (rule 2). With a neutral level it is exactly the
## Skills' own time, base x skill_time.
static func unit_minutes(base: float, industry: String, level: int, skill_time := 1.0, profile := "", on_0_10 := false) -> float:
	var g_skill := 1.0 / maxf(0.05, skill_time) - 1.0
	var g_place := SettlementIndustries.output_multiplier(industry, level, profile, on_0_10) - 1.0
	return base / (1.0 + g_skill + g_place)


## Coins for a piece of paid work at a level: the existing base pay times the pay multiplier, rounded to whole coins.
static func adjusted_pay(base_pay: int, industry: String, level: int, profile := "") -> int:
	return roundi(float(base_pay) * SettlementIndustries.pay_multiplier(industry, level, profile))


## How many units of work fit in `minutes` at `per_unit` minutes each.
static func units_in(minutes: float, per_unit: float) -> int:
	return int(floor(minutes / per_unit + 1e-9))


## Mining for `minutes`: each unit takes one from the seam (deposit {ore, amount}) into `into`; never past what it holds.
## Returns {made, minutes}.
static func mine(deposit: Dictionary, into: Inventory, minutes: float, per_unit: float) -> Dictionary:
	var made := 0
	var n := units_in(minutes, per_unit)
	while made < n and int(deposit.amount) > 0 and into.can_add(str(deposit.ore)):
		deposit.amount = int(deposit.amount) - 1
		into.add(str(deposit.ore))
		made += 1
	return {"made": made, "minutes": made * per_unit}


## A recipe worked for `minutes`: each run takes its full inputs (GameData.recipes[id]["in"]) from `stock` and adds its
## outputs; it stops when an input runs short. Returns {runs, minutes, used: {item: n}, made: {item: n}}.
static func craft(recipe_id: String, stock: Inventory, minutes: float, per_unit: float) -> Dictionary:
	var rec: Dictionary = GameData.recipes[recipe_id]
	var runs := 0
	var n := units_in(minutes, per_unit)
	var used := {}
	var made := {}
	while runs < n and stock.has_all(rec["in"]):
		stock.remove_all(rec["in"])
		for id in rec["in"]:
			used[id] = int(used.get(id, 0)) + int(rec["in"][id])
		for id in rec["out"]:
			stock.add(id, int(rec["out"][id]))
			made[id] = int(made.get(id, 0)) + int(rec["out"][id])
		runs += 1
	return {"runs": runs, "minutes": runs * per_unit, "used": used, "made": made}


## A field cut for `minutes`: each unit takes one of the grown crop (field {crop}, the existing field_yield) into `into`.
## Faster work cuts it sooner; it never grows more (the crop is the land's, not the reaper's).
static func harvest(field: Dictionary, into: Inventory, minutes: float, per_unit: float, item := "wheat") -> Dictionary:
	var made := 0
	var n := units_in(minutes, per_unit)
	while made < n and int(field.crop) > 0:
		field.crop = int(field.crop) - 1
		into.add(item)
		made += 1
	return {"made": made, "minutes": made * per_unit}
