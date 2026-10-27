class_name JudgmentAspiration
extends RefCounted
## EXPANSION 20 R5 (WDR-011-C; World Design Rule 011 as amended by the owner to six domains, 2026-10-27,
## docs/directives/2026-10-27_final_aspirations_decisions.md "FAD"; design docs/expansion20/R5_ASPIRATIONS_DESIGN.md):
## NPC aspirations. NOT a second decision engine: this layer only derives, for each adult villager, how much each of six
## domains matters to them now (priority), how well it is going (satisfaction) and how strongly it presses (pressure), and
## hands those to the one decision architecture (JudgmentWeighting.choose) as a factor ("aspiration", the yes-or-forgo
## profiles), as a scaling of the career and courting factors (job_choice, court_choice), and nowhere else. The family
## hierarchy (JudgmentFamily: children, spouse, parents, self) is never read or changed here, and survival pressure never
## enters the family_* profiles. Nothing here creates, moves or destroys a coin, a food point or an item: it reads the world
## and weighs options the live code already found feasible; a villager may fail and stay unmet (WDR-022: no hidden rescue).
##
## OFF by default: judgment.json "aspiration".enabled is false, and decision.integration.job_choice (its own flag) is
## false; with them off nothing here runs, no factor is added to any profile and the judgment section is written exactly
## as before (version 3, no "aspire" key). Every number is in judgment.json "aspiration" and is a PROVISIONAL agent value
## except the owner's hunger survival floor (25, decision.family.survival_floor_hunger) and the ~30% stubbornness share
## (traits.stubbornness_share_permille), both read from where they already live.
##
## The six domains (FAD Q6): food (and security), wealth, property (goods and property), profession, family (and
## household development), standing (social standing and recognition). Satisfaction and pressure are milli-points
## 0..100000, priorities permille (1000 = ordinary). Saved per person (the optional "aspire" key in the judgment section):
## the priority shifts life has made, yesterday's satisfaction bands, the morning's satisfaction, the leading domain and
## since when, recent setbacks and the decaying survival level. Temperament is a per-person hash, never saved; heirs get
## their own (no priority is inherited).
##
## Q7 (dialogue) is NOT implemented: the owner said it waits until this system works and has been reviewed. The seam is
## `lead_of(person)` and `domain_name(d)`: a later batch reads the leading aspiration from here through EventTalk and
## DialogueVoice; nothing here speaks.

const DOMAINS := ["food", "wealth", "property", "profession", "family", "standing"]
const FOOD := 0
const WEALTH := 1
const PROPERTY := 2
const PROFESSION := 3
const FAMILY := 4
const STANDING := 5
const ND := 6
const POSTS := ["reeve", "sage", "guard", "preacher", "church_assistant"]   # recognised existing posts (no office is invented)

static var override := {}           # economy_sim --aspiration / tests: merged into the "aspiration" section at configure

var store                           # the JudgmentStore this belongs to
var c := {}                         # the "aspiration" section, PROVISIONAL values
var enabled := false
var seed_ := 0
var rows := {}                      # person -> {shift: [6], band: [6] (-1 not yet set), sat: [6], lead, since, set: [6 x [days]], surv}
var foreign := {}                   # person -> {domain name: [shift, band, sat, setbacks]} for domain names this game does not know (carried, never dropped)
var foreign_names: Array = []       # those names, in the order first met
var unread := {}                    # a saved "aspire" section kept while the layer is off (written back unchanged)
var _hh := {}                       # dawn cache: household -> {homes, owned, plots}
var _holders := {}                  # dawn cache: holder ref -> [owned homes, leased homes, plots]
var _warned := false


func _init(owner_store, section: Dictionary, seed: int) -> void:
	store = owner_store
	seed_ = seed
	configure(section)


func configure(section: Dictionary) -> void:
	c = section.duplicate(true)
	for k in override:
		c[k] = override[k]
	enabled = bool(c.get("enabled", false))


func n_(key: String, fallback := 0) -> int:
	return int(c.get(key, fallback))


static func domain_name(d: int) -> String:
	return DOMAINS[d] if d >= 0 and d < ND else ""


# ---------------------------------------------------------------- priority (§5) ------------------
## Temperament at birth: 1000 +/- priority_spread by a seeded hash of the person and the domain (nothing stored).
func base_priority(person: int, d: int) -> int:
	var spread := n_("priority_spread", 300)
	if spread <= 0:
		return 1000
	return 1000 + JudgmentMath.hash_ints([seed_, person, 7001 + d]) % (2 * spread + 1) - spread


## Age: the young lean to family and work, the old to food and standing and away from career.
func age_adjust(age: float, d: int) -> int:
	var a := 0
	if age < float(n_("young_until", 25)):
		if d == FAMILY or d == PROFESSION:
			a += n_("young_step", 100)
	elif age > float(n_("old_from", 50)):
		if d == PROFESSION:
			a -= n_("old_profession_step", 200)
		elif d == FOOD or d == STANDING:
			a += n_("old_step", 100)
	return a


## Priority of `d` for `n`, permille, before survival pressure: temperament + age + what life has shifted.
func priority(n: NPC, d: int, w = null) -> int:
	var age := Life.npc_age(w, n) if w != null else 30.0
	var sh := 0
	if rows.has(n.id):
		sh = int(rows[n.id].shift[d])
	return maxi(0, base_priority(n.id, d) + age_adjust(age, d) + sh)


## Effective priority under survival level `surv` (permille 0..1000, §4): food rises, the others yield by yield_d, which a
## stubborn villager's hold softens; every domain keeps at least (1000 - yield) of its weight (nothing is cancelled).
func eff_priority(n: NPC, d: int, surv: int, w = null) -> int:
	var p := priority(n, d, w)
	if surv <= 0:
		return p
	if d == FOOD:
		return JudgmentMath.mul_div(p, 1000 + JudgmentMath.mul_div(surv, n_("boost_food", 2000), 1000), 1000)
	return JudgmentMath.mul_div(p, 1000 - JudgmentMath.mul_div(surv, yield_of(n.id, d), 1000), 1000)


func yield_of(person: int, d: int) -> int:
	var yb: Dictionary = c.get("yield_base", {})
	var base := int(yb.get(DOMAINS[d], 600))
	var stub: int = store.pers.stubbornness(person, store.now_minute() / 1440, store.now_minute() % 1440)
	var hold := JudgmentMath.mul_div(stub, n_("hold_share", 500), 1000)
	return maxi(n_("yield_floor", 200), JudgmentMath.mul_div(base, 1000 - hold, 1000))


# ---------------------------------------------------------------- survival (§4) ------------------
## The survival level now, permille: the highest of severe hunger, injury and recent danger the person knows of.
func raw_survival(n: NPC, w) -> int:
	var fam: Dictionary = store.cfg.decision.get("family", {})
	var floor_ := float(fam.get("survival_floor_hunger", 25))          # owner value
	var eat := float(GameData.b("eat_below"))
	var s := 0
	if n.hunger <= floor_:
		s = 1000
	elif n.hunger < eat:
		s = roundi((eat - n.hunger) / maxf(0.001, eat - floor_) * 1000.0)
	var hpf := float(int((fam.get("danger", {}) as Dictionary).get("hp_floor_permille", 200)))
	var inj := float(n_("injury_from", 700))
	var r := (n.hp / maxf(0.001, n.max_hp)) * 1000.0
	if r <= hpf:
		s = maxi(s, 1000)
	elif r < inj:
		s = maxi(s, roundi((inj - r) / maxf(0.001, inj - hpf) * 1000.0))
	return clampi(maxi(s, _danger(n, w)), 0, 1000)


## Recent violence the person knows of (their own memories, BAD facts of family "violence" within danger_days), counted
## twice when a victim is of their household. Violence memories are permanent (assault, killing), so the raw read is exact.
func _danger(n: NPC, w) -> int:
	var mem: Dictionary = store.memories.get(n.id, {})
	if mem.is_empty():
		return 0
	var vh := "violence".hash()
	var since: int = w.day() - n_("danger_days", 8)
	var step := n_("danger_step", 250)
	var s := 0
	for ev in mem:
		var m: PackedInt64Array = mem[ev]
		var t := int(m[JudgmentStore.M_TYPE])
		if store._pol[t] != -1 or store._famh[t] != vh or int(m[JudgmentStore.M_DAY]) < since:
			continue
		var k := 1
		if store.facts.has(ev) and n.household >= 0:
			for v in JudgmentStore._fact_people(store.facts[ev], 0):
				var o: NPC = w.npc(int(v)) if int(v) >= 0 else null
				if o != null and o.household == n.household:
					k = 2
					break
		s += step * k
	return mini(1000, s)


## The survival level a decision reads: it rises at once with hunger or injury, and falls only as the dawn lets it.
func survival(n: NPC, w) -> int:
	var saved := int(rows[n.id].surv) if rows.has(n.id) else 0
	return maxi(saved, raw_survival(n, w))


# ---------------------------------------------------------------- satisfaction (§2) --------------
func _hh_cache(w) -> void:
	_holders.clear()
	for r in w.property.records():
		if not w.property.is_home(r):
			continue
		for ref in [w.owner_of(r), w.tenant_of(r)]:
			if str(ref) == "":
				continue
			var e: Array = _holders.get(ref, [0, 0, 0])
			if str(ref) == w.owner_of(r) and w.tenant_of(r) == "":
				e[0] += 1
			elif str(ref) == w.tenant_of(r):
				e[1] += 1
			_holders[ref] = e
	for p in w.farm_plots.plots():
		for ref in [w.owner_of(p), w.tenant_of(p)]:
			if str(ref) != "":
				var e: Array = _holders.get(ref, [0, 0, 0])
				e[2] += 1
				_holders[ref] = e


func _holding(refs: Array) -> Array:
	var out := [0, 0, 0]
	for ref in refs:
		var e: Array = _holders.get(ref, [0, 0, 0])
		for i in 3:
			out[i] += int(e[i])
	return out


## Whether `n`'s household is short of coins for a housing goal it has (Construction.housing_goals, `short`).
static func goal_short(w, n: NPC) -> bool:
	if n.household < 0:
		return false
	var goals: Dictionary = w.construction.housing_goals(n.household)
	for k in goals:
		if int((goals[k] as Dictionary).get("short", 0)) > 0:
			return true
	return false


## Whether someone else in `n`'s household who is not an adult (a child, an elder) is hungry enough to eat.
static func dependants_unfed(w, n: NPC) -> bool:
	if n.household < 0:
		return false
	var eat := float(GameData.b("eat_below"))
	for m in w.households[n.household].members:
		var o: NPC = w.npc(int(m))
		if o != null and o != n and o.alive and o.role != "adult" and o.hunger < eat:
			return true
	return false


func satisfaction(n: NPC, w) -> Array:
	var econ: Dictionary = w.households[n.household].get("econ", {}) if n.household >= 0 and n.household < w.households.size() else {}
	var out := []
	out.resize(ND)
	# food and security
	var food := roundi(n.hunger * 1000.0)
	if not econ.is_empty():
		var savings := maxf(1.0, float(GameData.b("household_savings_days")))
		food = roundi(minf(float(econ.days) / savings, 1.0) * 100000.0) - n_("streak_step", 15000) * int(econ.streak)
		if n.hunger <= float(GameData.b("eat_below")):
			food = mini(food, n_("hunger_cap", 40000))
	out[FOOD] = clampi(food, 0, 100000)
	# wealth: half the purse against wealth_days of the household's cost, half the income against the person's share
	var cost := float(econ.get("cost", 1.0)) if not econ.is_empty() else 1.0
	var purse := float(w.property.purse(World.hh_ref(n.household))) if n.household >= 0 else float(n.coins)   # the household's members' coins, the person's own among them
	var share := cost / float(maxi(1, int(econ.get("adults", 1)))) if not econ.is_empty() else 1.0
	var wl := minf(purse / maxf(0.1, float(n_("wealth_days", 10)) * cost), 1.0) * 50000.0 + minf(n.avg_income(5) / maxf(0.1, share), 1.0) * 50000.0
	out[WEALTH] = clampi(roundi(wl), 0, 100000)
	# goods and property: owned home > leased > none; farmland adds; an unpaid housing goal and a missing tool take off
	var refs := [World.npc_ref(n.id)]
	if n.household >= 0:
		refs.append(World.hh_ref(n.household))
	var hold := _holding(refs)
	var pr := n_("home_owned", 60000) if int(hold[0]) > 0 else (n_("home_leased", 40000) if int(hold[1]) > 0 else n_("home_none", 15000))
	if int(hold[2]) > 0:
		pr += n_("land_points", 20000)
	if goal_short(w, n):
		pr -= n_("goal_short_points", 20000)
	if n.job != "" and w.brain.tool_short(n):
		pr -= n_("tool_short_points", 20000)
	out[PROPERTY] = clampi(pr, 0, 100000)
	out[PROFESSION] = profession_sat(n, w)
	# family and household development
	var fm := 0
	if n.partner == -1:
		fm = n_("family_courting", 35000) if w.relations.interests.has(n.id) else n_("family_single", 15000)
	else:
		var kids := false
		for cid in n.children:
			var k: NPC = w.npc(int(cid))
			if k != null and k.alive:
				kids = true
				break
		if not kids:
			fm = n_("family_partnered", 60000)
		else:
			fm = n_("family_children_secure", 90000) if bool(econ.get("sustainable", false)) else n_("family_children", 70000)
	out[FAMILY] = fm
	out[STANDING] = clampi(standing_value(n.id) + (n_("post_points", 20000) if n.job in POSTS else 0), 0, 100000)
	return out


## Profession: 0 without a job; else the mean level of the trade's skills over profession_level_full, or, for a trade with
## no listed skill, tenure over profession_tenure_full days.
func profession_sat(n: NPC, w) -> int:
	if n.job == "":
		return 0
	var sk := skill_fit(n, n.job)
	if sk >= 0:
		return sk
	return clampi((w.day() - n.job_since) * 100000 / maxi(1, n_("profession_tenure_full", 16)), 0, 100000)


## The person's level in `job`'s skills (skill_start.job_skills), 0..100000; -1 when the trade lists none. A skill never
## practised (0 xp) counts as level 0.
func skill_fit(n: NPC, job: String) -> int:
	var js: Dictionary = (GameData.b("skill_start") as Dictionary).get("job_skills", {})
	var list: Array = js.get(job, [])
	if list.is_empty():
		return -1
	var tot := 0
	for sk in list:
		tot += Skills.level(n, str(sk)) if int(n.skills.get(str(sk), 0)) > 0 else 0
	return clampi(tot * 100000 / (list.size() * maxi(1, n_("profession_level_full", 8))), 0, 100000)


## Room to improve in `job`'s skills, 0..100000, only when the person has some experience in them.
func growth_fit(n: NPC, job: String) -> int:
	var js: Dictionary = (GameData.b("skill_start") as Dictionary).get("job_skills", {})
	var list: Array = js.get(job, [])
	var tot := 0
	var any := false
	for sk in list:
		if int(n.skills.get(str(sk), 0)) > 0:
			any = true
			tot += maxi(0, Skills.max_level() - Skills.level(n, str(sk)))
	if not any:
		return 0
	return clampi(tot * 100000 / (list.size() * maxi(1, Skills.max_level())), 0, 100000)


# ---------------------------------------------------------------- standing (§3) ------------------
## Actual standing of `x`, 0..100000: the mean of every other villager's PERSONAL judgment of them (no family colour, so a
## family name never enters through standing; players keep no ledgers), clamped to +/- standing_span about the midpoint,
## plus recognition for being known by many. `exclude`: one observer left out (court_choice leaves out the chooser, whose
## own opinion is already the disposition factor: no ledger entry counts twice in one decision).
func standing_value(x: int, exclude := -1000000000) -> int:
	var mid := int(store.cfg.decision.disposition_mid)
	var sum := 0
	var cnt := 0
	var obs: Array = store.ledgers.keys()
	obs.sort()
	for o in obs:
		var oi := int(o)
		if oi == x or oi < 0 or oi == exclude:
			continue
		if JudgmentStore._lfind(store.ledgers[o], x) < 0:
			continue
		sum += store.personal_disposition(oi, x) - mid
		cnt += 1
	if cnt == 0:
		return mid
	var span := n_("standing_span", 50000)
	var v := mid + clampi(sum / cnt, -span, span) + mini(cnt, n_("recognition_full", 20)) * n_("recognition_step", 1000)
	return clampi(v, 0, 100000)


func standing_excluding(x: int, chooser: int) -> int:
	return standing_value(x, chooser)


# ---------------------------------------------------------------- pressure and lead ---------------
## [pressures x6, lead (-1 content)] for `n` from the saved morning satisfaction and the survival level now.
func pressures(n: NPC, w, surv := -1) -> Array:
	if not rows.has(n.id):
		return [[0, 0, 0, 0, 0, 0], -1]
	var s := survival(n, w) if surv < 0 else surv
	var sat: Array = rows[n.id].sat
	var pr := []
	var lead := -1
	var best := -1
	for d in ND:
		var p := JudgmentMath.mul_div(eff_priority(n, d, s, w), 100000 - int(sat[d]), 1000)
		pr.append(p)
		if p > best:
			best = p
			lead = d
	if best < n_("content_below", 15000):
		lead = -1
	return [pr, lead]


## The seam for dialogue (FAD Q7, a later batch): the person's leading aspiration at dawn ("" content or none).
func lead_of(person: int) -> String:
	return domain_name(int(rows[person].lead)) if rows.has(person) else ""


## The yes-or-forgo factor (§6.1): {value, domain, pressure, fit}. `serves` (a candidate key) overrides the fit table per
## domain name. Neutral (mid) when content, without a row, or when the leading domain does not bear on this choice.
func factor(chooser: int, profile: String, serves, w) -> Dictionary:
	var mid := int(store.cfg.decision.disposition_mid)
	var n: NPC = w.npc(chooser) if w != null and chooser >= 0 else null
	if n == null or not rows.has(chooser):
		return {"value": mid, "domain": "", "pressure": 0, "fit": 0, "surv": 0}
	var s := survival(n, w)
	var pl := pressures(n, w, s)
	var lead := int(pl[1])
	if lead < 0:
		return {"value": mid, "domain": "", "pressure": 0, "fit": 0, "surv": s}
	var dn: String = DOMAINS[lead]
	var fit := 0
	if serves is Dictionary and (serves as Dictionary).has(dn):
		fit = int(serves[dn])
	else:
		var spec = ((c.get("fit", {}) as Dictionary).get(profile, {}) as Dictionary).get(dn, 0)
		fit = _fit_of(spec, w, n)
	var p := mini(int(pl[0][lead]), n_("factor_cap", 50000))
	return {"value": clampi(mid + fit * p, 0, 100000), "domain": dn, "pressure": int(pl[0][lead]), "fit": fit, "surv": s}


## A fit table entry: -1, 0, 1, or a condition ("goal_short", "-goal_short", "unfed") that gives +/-1 when it holds, else 0.
static func _fit_of(spec, w, n: NPC) -> int:
	if spec is String:
		var neg := (spec as String).begins_with("-")
		var cond := (spec as String).trim_prefix("-")
		var holds := false
		if cond == "goal_short":
			holds = goal_short(w, n)
		elif cond == "unfed":
			holds = dependants_unfed(w, n)
		return (-1 if neg else 1) if holds else 0
	return clampi(int(spec), -1, 1)


## The weight multiplier (permille) for a factor scaled by domain `d` (job_choice skill and growth; court factors).
func scale_for(chooser: int, d: int, w) -> int:
	var n: NPC = w.npc(chooser) if w != null and chooser >= 0 else null
	if n == null:
		return 1000
	return eff_priority(n, d, survival(n, w), w)


# ---------------------------------------------------------------- the dawn (§5, §8) ----------------
## Once each morning, between the households' evaluation and the search for work (NPCBrain.dawn): every adult villager's
## satisfaction from that morning's state, the band crossings that are successes and setbacks, the survival level's
## decay, the leading aspiration. Persons walked in id order; no RNG.
func dawn(w) -> void:
	if not enabled:
		return
	_hh_cache(w)
	var today: int = w.day()
	var ids := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult":
			ids.append(n.id)
	ids.sort()
	var keep := {}
	for id in ids:
		keep[id] = true
		_dawn_one(w, w.npc(int(id)), today)
	for p in rows.keys():
		if not keep.has(p):
			rows.erase(p)                       # no longer an adult villager (died, grew old, moved away): nothing to carry
			foreign.erase(p)
	store._stat("aspire_dawns")


func _new_row() -> Dictionary:
	return {"shift": [0, 0, 0, 0, 0, 0], "band": [-1, -1, -1, -1, -1, -1], "sat": [0, 0, 0, 0, 0, 0], "lead": -1, "since": 0,
		"set": [[], [], [], [], [], []], "surv": 0}


func band_of(sat: int) -> int:
	var edges: Array = c.get("band_edges", [20000, 40000, 60000, 80000])
	var b := 0
	for e in edges:
		if sat >= int(e):
			b += 1
	return b


func _dawn_one(w, n: NPC, today: int) -> void:
	if not rows.has(n.id):
		rows[n.id] = _new_row()
	var r: Dictionary = rows[n.id]
	var sat := satisfaction(n, w)
	r.sat = sat
	for d in ND:
		var b := band_of(int(sat[d]))
		var old := int(r.band[d])
		if old >= 0 and b > old:
			_shift(w, n, d, -n_("success_step", 150), "success", today)
		elif old >= 0 and b < old:
			setback(w, n, d, today, "setback")
		r.band[d] = b
	# survival: rises at once, falls at most recover_per_day a day
	var before := int(r.surv)
	r.surv = maxi(raw_survival(n, w), before - n_("recover_per_day", 200))
	var step := maxi(1, n_("surv_record_step", 250))
	if int(r.surv) / step != before / step:
		_record(w, n, "survival", {"surv_before": before, "surv_after": int(r.surv)})
	var pl := pressures(n, w, int(r.surv))
	var lead := int(pl[1])
	if lead != int(r.lead):
		_record(w, n, "lead", {"lead_before": domain_name(int(r.lead)) if int(r.lead) >= 0 else "content",
			"lead_after": domain_name(lead) if lead >= 0 else "content", "pressure": int(pl[0][lead]) if lead >= 0 else 0, "surv": int(r.surv)})
		r.lead = lead
		r.since = today


## Setback response (FAD Q4, existing traits only): a holder of stubbornness perseveres (the domain gains priority by
## setback_step x stubbornness); the others adapt (it loses setback_step, faster with general wisdom), so another domain's
## pressure takes over. giveup_after setbacks in one domain within window_days reverse even a stubborn villager's shift.
func setback(w, n: NPC, d: int, today: int, cause: String) -> void:
	if not rows.has(n.id):
		rows[n.id] = _new_row()
	var r: Dictionary = rows[n.id]
	var win := n_("window_days", 8)
	var days: Array = (r.set[d] as Array).filter(func(x): return int(x) > today - win)
	days.append(today)
	var cap := maxi(1, n_("giveup_after", 3))
	while days.size() > cap:
		days.pop_front()
	r.set[d] = days
	var step := n_("setback_step", 150)
	var nm: int = store.now_minute()
	var stub: int = store.pers.stubbornness(n.id, nm / 1440, nm % 1440)
	var how := ""
	var delta := 0
	if days.size() >= cap:
		delta = -step
		how = "gave_up"
	elif stub > 0:
		delta = JudgmentMath.mul_div(step, stub, 1000)
		how = "persevered"
	else:
		delta = -JudgmentMath.mul_div(step, 1000 + store.pers.general_wisdom(n.id), 1000)
		how = "adapted"
	_shift(w, n, d, delta, cause + ":" + how, today)


func _shift(w, n: NPC, d: int, delta: int, cause: String, _today: int) -> void:
	var r: Dictionary = rows[n.id]
	var mx := n_("max_shift", 300)
	var before := int(r.shift[d])
	r.shift[d] = clampi(before + delta, -mx, mx)
	store._stat("aspire_" + cause.get_slice(":", 0))
	if int(r.shift[d]) != before:
		_record(w, n, "priority", {"domain": DOMAINS[d], "cause": cause, "shift_before": before, "shift_after": int(r.shift[d])})


## The loss of a partner, child or parent (JudgmentLive.on_death): a setback to the family domain, met by personality.
func on_loss(w, person: int) -> void:
	var n: NPC = w.npc(person) if person >= 0 else null
	if not enabled or n == null or not n.alive or n.role != "adult":
		return
	setback(w, n, FAMILY, w.day(), "loss")


## A marriage (JudgmentLive.on_marriage): property gains priority (a home of their own); family follows the state.
func on_marriage(w, person: int) -> void:
	var n: NPC = w.npc(person) if person >= 0 else null
	if not enabled or n == null or not n.alive or n.role != "adult":
		return
	if not rows.has(n.id):
		rows[n.id] = _new_row()
	_shift(w, n, PROPERTY, n_("marriage_step", 150), "marriage", w.day())


func _record(w, n: NPC, kind: String, facts: Dictionary) -> void:
	store._stat("aspire_event_" + kind)
	if store.rec != null:
		store.rec.aspiration_event(n.id, kind, facts)      # judgment/aspiration (recorder_codes.json)


## The configured job_choice flag needs the layer on: refused (with a logged reason) otherwise.
func job_choice_allowed() -> bool:
	if enabled:
		return true
	if not _warned:
		_warned = true
		push_warning("judgment: decision.integration.job_choice is set but aspiration.enabled is off; job_choice stays off (R5)")
	return false


# ---------------------------------------------------------------- saving (§7) --------------------
func is_empty() -> bool:
	return rows.is_empty() and unread.is_empty()


## The optional "aspire" key: {} when there is nothing to write (the section is then version 3, unchanged).
func to_dict() -> Dictionary:
	if not unread.is_empty():
		return unread.duplicate(true)
	if rows.is_empty():
		return {}
	var names: Array = DOMAINS.duplicate() + foreign_names
	var out := []
	var ps := rows.keys()
	ps.sort()
	for p in ps:
		var r: Dictionary = rows[p]
		var sh := (r.shift as Array).duplicate()
		var bd := (r.band as Array).duplicate()
		var st := (r.sat as Array).duplicate()
		var sb := (r.set as Array).duplicate(true)
		var fx: Dictionary = foreign.get(p, {})
		for fname in foreign_names:
			var v: Array = fx.get(fname, [0, -1, 0, []])
			sh.append(int(v[0]))
			bd.append(int(v[1]))
			st.append(int(v[2]))
			sb.append((v[3] as Array).duplicate())
		out.append([int(p), sh, bd, st, int(r.lead), int(r.since), sb, int(r.surv)])
	return {"v": 1, "domains": names, "rows": out}


## Load the "aspire" key. Columns are mapped by domain name; a name this game does not know is carried through to the
## next save. While the layer is off the section is kept unread and written back unchanged. Returns "" or why not read.
func load_dict(d: Dictionary) -> String:
	rows.clear()
	foreign.clear()
	foreign_names = []
	unread = {}
	if d.is_empty():
		return ""
	if int(d.get("v", 0)) != 1 or not (d.get("domains", null) is Array) or not (d.get("rows", null) is Array):
		unread = d.duplicate(true)
		return "aspiration section of an unknown layout: kept unread"
	if not enabled:
		unread = d.duplicate(true)
		return ""
	var names: Array = d.domains
	var map := []
	for nm in names:
		var i := DOMAINS.find(str(nm))
		map.append(i)
		if i < 0 and not foreign_names.has(str(nm)):
			foreign_names.append(str(nm))
	for row in d.rows:
		var p := int(row[0])
		var r := _new_row()
		var fx := {}
		for k in names.size():
			var vals := [int(row[1][k]), int(row[2][k]), int(row[3][k]), (row[6][k] as Array).map(func(x): return int(x))]
			if int(map[k]) >= 0:
				var di := int(map[k])
				r.shift[di] = vals[0]
				r.band[di] = vals[1]
				r.sat[di] = vals[2]
				r.set[di] = vals[3]
			else:
				fx[str(names[k])] = vals
		var lead := int(row[4])
		r.lead = int(map[lead]) if lead >= 0 and lead < map.size() else -1
		r.since = int(row[5])
		r.surv = int(row[7])
		rows[p] = r
		if not fx.is_empty():
			foreign[p] = fx
	return ""
