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
##
## DANGER (owner 2026-10-23, docs/directives/2026-10-23_owner_answers_family_danger.md, "Shield and fetch help"): when a
## threat (a bandit, or a wolf or bear that is fighting someone) comes within danger.radius tiles of a dependant of the
## head who is out of doors, the head weighs `family_danger`: SHIELD (move between the threat and the dependants, send them
## home and run for a guard by the ordinary report, PAR-05), FIGHT (stand and fight; cornered, or stubborn, the head's
## readiness rises, in proportion to their health) or FLEE (only a head below the survival floor, danger.hp_floor_permille
## of their health, or the rare self-first temperament: "a sacrifice is never a suicide"). They can be hurt or killed doing
## it. Personality (the per-person weight spread) and stubbornness bend readiness, never the order of the family. Fire
## (the owner's third example) has no hook until a fire exists: `danger` reads threats from `_threats`, where it will join.

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
	if j.rec != null:
		j.rec.judgment_family(row)                     # REC-19 D5 / FAM-SAC-01: the family-priority factors in the recorder


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


# ---------------------------------------------------------------- danger ("shield and fetch help") ------
## Threats this tick: every bandit, every wolf or bear that is fighting someone, and (A7, GP-CRIME-PURSUIT) every player
## with a killing in their case (Justice) who is out; a head treats a killer as a threat only if they know who it is
## (danger: knows_killer: they saw it, heard the hue and cry, or believe a killing of that player). Kept for the tick on the store (keyed by
## the world clock, which moves every tick, so a save and load between ticks finds the same answer as a run that did not stop).
static func _threats(w) -> Array:
	var j: JudgmentStore = w.judgment
	var mnt: float = w.minutes
	if float(j.threat_cache.get("m", -1.0)) == mnt:
		return j.threat_cache.list
	var out := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			out.append({"kind": "bandit", "id": o.id, "pos": o.pos, "depth": o.depth, "npc": o})
	if w.fauna != null:
		for a in w.fauna.animals:
			if a.alive and a.anger != "" and bool(a.spec().get("people", false)):
				out.append({"kind": "beast", "id": -1, "pos": a.pos, "depth": 0, "animal": a})
	var refs: Array = w.justice.cases.keys() if w.justice != null else []
	refs.sort()
	for ref in refs:
		var p: PlayerState = w.player_of_ref(str(ref))
		if p != null and p.alive and not p.away and (w.justice.case_of(str(ref)).crimes as Array).any(func(cr): return str(cr.kind) == "killing" and str(cr.settled) != "lapsed"):
			out.append({"kind": "killer", "id": w.person_id(p), "pos": p.pos, "depth": p.map_level, "ref": str(ref), "player": p})
	j.threat_cache = {"m": mnt, "list": out}
	return out


## Whether head `n` meets a threat near their dependants and acts on it (the plan or target is set). False when there is
## no such threat, `n` is not the head, or the dependants are indoors or out of reach: the ordinary day goes on.
static func danger(w, n: NPC) -> bool:
	if n.household < 0 or n.role == "child" or n.job == "guard" or n.depth != 0:
		return false
	var th := _threats(w).filter(func(t): return str(t.kind) != "killer" or knows_killer(w, n, str(t.ref)))
	if th.is_empty():
		return false
	var c: Dictionary = cfg(w).get("danger", {})
	var radius := float(c.get("radius", 10.0))
	var reach := float(c.get("reach", 24.0))
	var close := false
	for t in th:
		if int(t.depth) == n.depth and n.pos.distance_to(t.pos) <= reach + radius:
			close = true
			break
	if not close or head(w, n.household) != n:
		return false
	var corner := float(c.get("cornered_radius", 2.5))
	var near := []
	var worst = null
	var worst_d := 1e9
	for m: NPC in w.brain._members(n.household):
		if m == n or m.depth != n.depth or tier(w, n, m) > TIER_PARENT or w.place_of(m.pos) != "":
			continue
		for t in th:
			var d: float = m.pos.distance_to(t.pos)
			if d <= radius and int(t.depth) == m.depth:
				if not near.has(m):
					near.append(m)
				if d < worst_d:
					worst_d = d
					worst = t
	if near.is_empty() or n.pos.distance_to(worst.pos) > reach:
		return false
	var f := {"family_danger_child": 0, "family_danger_spouse": 0, "family_danger_parent": 0}
	var cornered := worst_d <= corner or n.pos.distance_to(worst.pos) <= corner
	for m: NPC in near:
		var tt := tier(w, n, m)
		var key := "family_danger_child" if tt == TIER_CHILD else ("family_danger_spouse" if tt == TIER_SPOUSE else "family_danger_parent")
		f[key] = 100000
	var guard := false
	if worst.kind == "bandit" or worst.kind == "killer":
		var rng_ := float(GameData.b("report").range)
		for g: NPC in w.npcs:
			if g.alive and g.job == "guard" and g != n and not w.asleep(g) and g.pos.distance_to(n.pos) <= rng_:
				guard = true
				break
	var j: JudgmentStore = w.judgment
	var nm := j.now_minute()
	var stub := j.pers.stubbornness(n.id, nm / 1440, nm % 1440)
	var temper := self_first(w, n)
	var hp_frac := n.hp / maxf(1.0, n.max_hp)
	var hurt := clampi(int((1.0 - hp_frac) * 100000.0), 0, 100000)
	var floor_ := 100000 if hp_frac * 1000.0 < float(c.get("hp_floor_permille", 200)) else 0       # the survival floor: a sacrifice is never a suicide
	var opts := [
		{"id": "shield", "factors": _merge(f, {"guard_near": 100000 if guard else 0, "live_order": 100000})},
		{"id": "fight", "factors": _merge(f, {"cornered": clampi(int((100000.0 if cornered else 0.0) * hp_frac), 0, 100000), "stubborn_stand": clampi(int(float(stub) * 100.0 * hp_frac), 0, 100000)})},
		{"id": "flee", "factors": {"self_risk": hurt, "self_floor": floor_, "self_first_temperament": 100000 if temper else 0}}]
	var r := JudgmentWeighting.choose(j, j.cfg, n.id, "family_danger", opts, [w.day(), n.id, KEY, int(w.minutes / 10.0)])
	_record(w, n, "danger", r, {"threat": str(worst.kind), "dependants": near.size(), "cornered": cornered, "temperament": temper})
	match str(r.chosen):
		"fight":
			_fight(w, n, worst)
		"flee":
			_send_home(w, n, "running from danger")
		_:
			_shield(w, n, near, worst)
	return true


## A7: whether `n` knows player `ref` for a killer: they saw or heard of it as the case records it (Justice aware: the
## witnesses and the hue and cry's hearers), or they believe a killing of that player (a judgment memory, told or seen).
static func knows_killer(w, n: NPC, ref: String) -> bool:
	var c: Dictionary = w.justice.case_of(ref)
	if c.is_empty():
		return false
	if c.aware.has(str(n.id)) and str(c.crimes[int(c.aware[str(n.id)])].kind) == "killing":
		return true
	var p: PlayerState = w.player_of_ref(ref)
	for it in EventTalk.events(w, n):
		if str(it.type) == "killing" and (it.actors as Array).has(p):
			return true
	return false


static func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = b[k]
	return out


## Dependants out of doors go home; the head steps between the threat and the nearest of them and, for a bandit, will tell a guard.
static func _shield(w, n: NPC, near: Array, t: Dictionary) -> void:
	var nearest: NPC = near[0]
	for m: NPC in near:
		_send_home(w, m, "hurrying home from danger")
		if m.pos.distance_to(t.pos) < nearest.pos.distance_to(t.pos):
			nearest = m
	var dir: Vector2 = (t.pos - nearest.pos)
	var at := nearest.pos + (dir.normalized() * minf(1.5, dir.length()) if dir.length() > 0.01 else Vector2.ZERO)
	n.doing = "shielding the family"
	n.plan = [w.brain.go(Vector2i(floori(at.x), floori(at.y)), 1.3), w.brain.work(0.5, "", {}, "idle")]
	if str(t.kind) == "bandit" and n.report.is_empty():
		w.report_crime(n, int(t.id), "saw")                  # PAR-05: the next decision goes to the nearest guard (NPCBrain._report)
		w.judgment._stat("family_danger_reports")
	elif str(t.kind) == "killer" and n.report.is_empty():
		var c: Dictionary = w.justice.case_of(str(t.ref))
		w.report_crime(n, int(t.id), "sighting", "attack", str(t.ref), [int(c.aware.get(str(n.id), c.crimes.size() - 1))])     # A7: and tells a guard where
		w.judgment._stat("family_danger_reports")


## A bandit: the head takes it on (the ordinary fight). A beast: the head strikes it when within reach, else closes in.
static func _fight(w, n: NPC, t: Dictionary) -> void:
	n.doing = "defending the family"
	if str(t.kind) == "bandit":
		n.target = int(t.id)
		return
	if str(t.kind) == "killer":
		n.target = int(t.id)                                 # A7: the head stands against the killer, as against a bandit (MP C6: that player's own id)
		n.target_ref = str(t.ref)
		return
	var a: Animal = t.animal
	if n.pos.distance_to(a.pos) > 1.6:
		n.plan = [w.brain.go(Vector2i(floori(a.pos.x), floori(a.pos.y)), 1.3), w.brain.work(0.3, "", {}, "idle")]
		return
	n.anim = "sword"
	w.fauna.provoke(a, "npc:%d" % n.id)                      # it turns on the one who struck
	a.hp -= n.damage * Skills.value(n, "combat", "damage_mult", 1.0)
	Skills.gain(n, "combat", 4)
	n.plan = [w.brain.work(0.5, "", {}, "sword")]
	if a.hp <= 0.0:
		var bag: Inventory = w.fauna.kill(a)
		if bag.total() > 0:
			w.loot.append({"pos": a.pos, "inv": bag, "coins": 0, "from": "the " + a.label().to_lower(), "t": w.minutes})
		w.judgment._stat("family_danger_beast_killed")


static func _send_home(w, m: NPC, doing: String) -> void:
	if m.doing == doing or m.home == "" or not w.buildings.has(m.home):
		return
	m.doing = doing
	m.plan = [w.brain.go(w.building_door(m.home), 1.3), w.brain.doit("enter"), w.brain.work(20.0, "", {}, "idle")]
