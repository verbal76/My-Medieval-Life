class_name JudgmentFamily
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19; FAMILY-01, owner directive 2026-10-23 "Family sacrifice and responsibility"):
## the responsible parent or guardian puts those in their care first: children, then spouse, then parents, then self.
## NOT a second AI: three existing decision points (the household's meal, who pays on the family's tab, the evening's
## choice between paid work and leisure) ask this module, behind the decision.integration flag `family_first`
## (see JudgmentLive.on); with judgment off nothing here is reached and the game is Build 18.
##
## The household (owner's answers): the head is the father when both parents live in the household, else the existing
## responsible adult (Construction.responsible_adult: a mother, a widow, a grandparent raising grandchildren). Children =
## every child in the household (own, the spouse's, taken in); spouse = the head's partner; parents = the head's and the
## spouse's parents; anyone else is outside the hierarchy. Serving order when food is short: children, spouse, parents,
## the head. Each person defers only to those of a lower tier number, and only down to a survival floor (enough hunger
## left to keep working and protecting), so a sacrifice is never a suicide. Personality changes how much and how early
## (the person's own seeded weights, JudgmentWeighting.trait_weight, move where the choice flips), never the order,
## which is this module's rule, not a weighed choice. Only a rare, extreme temperament (a holder of stubbornness, one
## in extreme_share_permille of them, a fixed hash of the world seed and the id) eats earlier; that is recorded as the
## factor self_first_temperament. Each weighed decision goes through JudgmentWeighting.choose and its trace (rows with
## factors and contributions) is kept in JudgmentStore.family_trace for the recorder (XEXPL-01).

const TIER_CHILD := 0
const TIER_SPOUSE := 1
const TIER_PARENT := 2
const TIER_OTHER := 3
const TIER_HEAD := 4
const FLAG := "family_first"
const KEY := 4391


static func cfg(w) -> Dictionary:
	return w.judgment.cfg.decision.get("family", {}) as Dictionary


## The household's head for the family hierarchy (the father by default when both parents live in it), or null.
static func head(w, h: int) -> NPC:
	if h < 0 or h >= w.households.size() or bool(w.households[h].get("ended", false)):
		return null
	var ra: NPC = w.construction.responsible_adult(h)
	if ra == null:
		return null
	if ra.sex != "male" and ra.partner >= 0:
		var p: NPC = w.npc(ra.partner)
		if p != null and p.alive and p.household == h and p.sex == "male" and p.role == "adult" and w.construction._parent_here(p) and w.construction._parent_here(ra):
			return p
	return ra


static func _parent_of(o: NPC, x: NPC) -> bool:
	return x != null and (x.mother == o.id or x.father == o.id)


## `o`'s place in the head's hierarchy.
static func tier(w, hd: NPC, o: NPC) -> int:
	if o == hd:
		return TIER_HEAD
	if o.role == "child":
		return TIER_CHILD
	if o.id == hd.partner:
		return TIER_SPOUSE
	if _parent_of(o, hd) or (hd.partner >= 0 and _parent_of(o, w.npc(hd.partner))):
		return TIER_PARENT
	return TIER_OTHER


## Whether `n` has the rare extreme temperament that sometimes puts self first: a fixed hash, never a roll per decision.
static func self_first(w, n: NPC) -> bool:
	var j: JudgmentStore = w.judgment
	return j.pers.holds_stubbornness(n.id) and JudgmentMath.hash_ints([j.world_seed, n.id, 6263]) % 1000 < int(cfg(w).get("extreme_share_permille", 0))


## The unmet need of those `n` is answerable to: deficits (100 - hunger) of the household members of a lower tier than
## `n` (children, spouse, parents; the head answers to all three, others to those before them) who are hungry enough
## to eat. {"tier": t, "need": [child, spouse, parent], "count": unfed members}.
static func unfed(w, hd: NPC, n: NPC) -> Dictionary:
	var t := tier(w, hd, n)
	var need := [0, 0, 0]
	var count := 0
	if t == TIER_OTHER or t == TIER_CHILD:
		return {"tier": t, "need": need, "count": 0}
	var below := float(GameData.b("eat_below"))
	for m: NPC in w.brain._members(n.household):
		if m == n:
			continue
		var tm := tier(w, hd, m)
		if tm >= t or tm > TIER_PARENT or m.hunger >= below:
			continue
		need[tm] += int(ceil(100.0 - m.hunger))
		count += 1
	return {"tier": t, "need": need, "count": count}


static func _needs_factors(need: Array) -> Dictionary:
	return {"family_child_need": clampi(int(need[0]) * 1000, 0, 100000), "family_spouse_need": clampi(int(need[1]) * 1000, 0, 100000),
		"family_parent_need": clampi(int(need[2]) * 1000, 0, 100000)}


## Keep the decision's trace for the recorder and count it.
static func _record(w, who: NPC, kind: String, r: Dictionary, extra := {}) -> void:
	var j: JudgmentStore = w.judgment
	var row := {"day": w.day(), "hour": snappedf(w.hour(), 0.1), "who": who.id, "household": who.household, "kind": kind,
		"chosen": str(r.chosen), "utility": int(r.utility), "trace": r.trace}
	for k in extra:
		row[k] = extra[k]
	j.family_trace.append(row)
	while j.family_trace.size() > int(cfg(w).get("trace_cap", 64)):
		j.family_trace.pop_front()
	j._stat("family_%s_%s" % [kind, str(r.chosen)])


## Whether `n` leaves the food to those they answer to: "pantry" (the household's store; `price` ignored) or "buy" (a meal
## bought at `price` with the family's coins). False when there is nobody hungry below them, when the food or coin is
## enough for all, or when the choice weighed against the survival floor says eat. A deferring adult does not eat or
## spend; they go on working.
static func defers(w, n: NPC, kind: String, price := 0) -> bool:
	if n.household < 0 or n.role == "child" or not n.alive:
		return false
	var hd := head(w, n.household)
	if hd == null:
		return false
	var u := unfed(w, hd, n)
	if int(u.count) == 0:
		return false
	var need_sum := int(u.need[0]) + int(u.need[1]) + int(u.need[2])
	if kind == "pantry":
		var pts := NPCBrain.store_points([w.households[n.household].pantry])
		if pts >= float(need_sum + maxi(0, int(ceil(100.0 - n.hunger)))):
			return false                     # enough for everyone: nothing to give up
	else:
		var others := 0
		for m: NPC in w.brain._members(n.household):
			if m != n:
				others += m.coins
		if n.coins - price + others >= int(u.count) * price:
			return false                     # the rest of the family's coin covers those below, with the meal bought
	var c := cfg(w)
	var f := _needs_factors(u.need)
	var temper := self_first(w, n)
	var floor_ := float(c.get("survival_floor_hunger", 25))
	var eat_f := {"self_need": clampi(int(100.0 - n.hunger) * 1000, 0, 100000),
		"self_floor": 100000 if n.hunger <= floor_ else 0,
		"self_first_temperament": 100000 if temper and n.hunger <= float(c.get("self_first_hunger", 40)) else 0}
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, n.id, "family_meal",
			[{"id": "defer", "factors": f}, {"id": "eat", "factors": eat_f}], [w.day(), n.id, KEY])
	_record(w, n, "meal_" + kind, r, {"tier": int(u.tier), "temperament": temper})
	return str(r.chosen) == "defer"


## Who pays `price` for `n`'s meal in place of "the richest pays": the head's purse, down to the coin floor, when `n` is
## someone the head answers for (a child, the spouse, a parent). Null: the live rule stands (n is the head, outside the
## hierarchy, or the head cannot pay without going under the floor).
static func payer(w, n: NPC, price: int) -> NPC:
	if n.household < 0:
		return null
	var hd := head(w, n.household)
	if hd == null or hd == n:
		return null
	var t := tier(w, hd, n)
	if t > TIER_PARENT:
		return null
	var c := cfg(w)
	var temper := self_first(w, hd)
	var coin_floor := int(c.get("self_first_coin_floor", 10)) if temper else int(c.get("coin_floor", 3))
	if hd.coins - price < coin_floor:
		return null
	var need := [0, 0, 0]
	need[t] = 100
	var f := _needs_factors(need)
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, hd.id, "family_pay",
			[{"id": "head_pays", "factors": f}, {"id": "richest_pays", "factors": {"live_order": 100000}}], [w.day(), n.id, KEY])
	_record(w, hd, "pay", r, {"for": n.id, "tier": t, "price": price, "temperament": temper})
	return hd if str(r.chosen) == "head_pays" else null


## Whether `n` (a parent or guardian) should look for paid work before leisure: those they answer to are hungry, the
## household's food does not cover them and `n` has few coins. True when the choice goes to work.
static func prefers_work(w, n: NPC) -> bool:
	if n.household < 0 or n.role != "adult":
		return false
	var hd := head(w, n.household)
	if hd == null:
		return false
	var u := unfed(w, hd, n)
	if int(u.count) == 0:
		return false
	var need_sum := int(u.need[0]) + int(u.need[1]) + int(u.need[2])
	if NPCBrain.store_points([w.households[n.household].pantry]) >= float(need_sum):
		return false
	var c := cfg(w)
	if n.coins >= int(c.get("work_coins_below", 20)):
		return false
	var f := _needs_factors(u.need)
	f["family_coin_short"] = clampi((int(c.get("work_coins_below", 20)) - n.coins) * 5000, 0, 100000)
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, n.id, "family_work",
			[{"id": "work", "factors": f}, {"id": "leisure", "factors": {"live_order": 100000}}], [w.day(), n.id, KEY])
	_record(w, n, "work", r, {"tier": int(u.tier)})
	return str(r.chosen) == "work"
