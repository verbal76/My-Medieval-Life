class_name LifeDecisions
extends RefCounted
## B25R1-014 (owner directive 2026-11-03, docs/directives/2026-11-03_b25r1_outlaw_communities.md: the four decisions on
## B25R1-010 and B25R1-013; design docs/design/HOMESTEADING_B25R1.md sections 7-11): the life-course choices that move people
## between the village, the open country and the bandits, through the ONE decision architecture the village already has (the
## live rules find what is feasible; JudgmentWeighting.choose chooses, with personality, judgment and aspirations, as
## Ventures' business_found does). Not a random percentage: a brake limits the outcome, the reasoning makes the choice.
##
##   homestead_choice   at household formation (Construction._found, _found_couple: young adults) and, for an established
##                      adult, at a relocation event (a long housing wait, widowhood, a lost post); candidates village /
##                      homestead. Brakes: young homesteads at most young_share of formations (cumulative and over
##                      window_days), adults at most adult_share of their evaluations: population safeguards, never a chance.
##   runaway_choice     a young person (12-15; under 12 only in severe, sustained deprivation) of a household whose hardship
##                      record (consecutive bad dawns, net of good ones; a parent's death or a lost home) crosses its
##                      threshold, at most once a season unless a new major event; candidates stay, seek_help (kin or a
##                      willing household, Guardianship's own order), work_home (a hand's place: adults only, never a
##                      child), run_settlement (walk the road and join a neighbouring settlement, Migration's own move),
##                      survive_alone (a household of their own: 15 and over), seek_band (walk to the bandits' camp). Also
##                      displaced adults (a household long unable to live, no home) weigh stay / seek_band.
##   recruit_answer     a separate decision by the band's eldest bandit when someone reaches the camp asking to join:
##                      reject, dependant (a child: a clan member who is never a fighter, FAM-07's standing) or accept (an
##                      adult: a bandit by the coming-of-age rule; no gear, skill or coin given).
##   bandit_leave       an adult bandit, once a season, weighs leaving: family in the village, fear (wounds, the band's
##                      dead), lawful work open, ambition, the band's size; leaving keeps everything (identity, crimes,
##                      relationships, pack, wounds) and joins kin or a willing household, or founds a household seeking a home.
## Everyone stays one record (World.npcs, World.people); nobody is spawned or erased. Each choice is traced by the flight
## recorder like any judged choice. Switches: judgment.json decision.integration.<profile> (each off: nothing here decides).
## Deterministic: no random number (seasonal turns and margins are hashes of the seed, the person and the day). Saved
## (World "life", optional). Numbers: balance.json "life_decisions" (agent proposals, provisional).

const FORMAT := "mml-life/1"

var w: World
var hardship := {}       # str(household) -> {bad, home, adults, event: day of the last major event}
var seen := {}           # str(person) -> the day they last weighed a life choice (runaway, outlaw, leaving the band)
var formations := {}     # str(person) -> the day they were first counted at a household formation (once each)
var history: Array = []  # [day, kind]: form_young, home_young, form_adult, home_adult, runaway_<outcome>, recruit_<answer>, left_band
var pending := {}        # str(npc id) -> {go: "band", from: household}: walking to the bandits' camp to ask to join
var runaways := {}       # str(npc id) -> {from, day, outcome, age}: who ran and where (saved, for the families and the metrics)
var counts := {}


func _init(world: World) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("life_decisions")


func _count(key: String, k := 1) -> void:
	counts[key] = int(counts.get(key, 0)) + k
	w.stat("life_" + key, float(k))


func _hist(kind: String) -> void:
	history.append([w.day(), kind])


func _in_window(kind: String, days: int) -> int:
	var c := 0
	for e in history:
		if str(e[1]) == kind and w.day() - int(e[0]) < days:
			c += 1
	return c


func _total(kind: String) -> int:
	return int(counts.get("total_" + kind, 0))


func _note_total(kind: String) -> void:
	counts["total_" + kind] = int(counts.get("total_" + kind, 0)) + 1
	_hist(kind)


func on(profile: String) -> bool:
	return JudgmentLive.on(w, profile)


func _asp() -> JudgmentAspiration:
	return w.judgment.asp if w.judgment != null and w.judgment.asp != null and w.judgment.asp.enabled else null


## A person's turn this season: a hash of the seed and their id picks one dawn in each season (Ventures.looks_today's way).
func _turn(id: int) -> bool:
	var every := maxi(1, ceili(Life.seasons_to_days(1.0)))
	return (w.day() + JudgmentMath.hash_ints([w.seed, id, 8233]) % every) % every == 0


func _choose(chooser: int, profile: String, cands: Array, key: Array) -> String:
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, chooser, profile, cands, key)
	return str(r.chosen) if r.chosen != null else ""


static func _clamp(v: float) -> int:
	return clampi(roundi(v), 0, 100000)


# ---------------------------------------------------------------- homesteading -------------------
## Homesteads.decider: who of `leaving` (household `h`, at a formation or a relocation event `path`) chooses to homestead, or
## null. Counts the formation once a person; the brake first (no candidate past it); then the choice.
func homestead_decider(h: int, founder: NPC, leaving: Array, path: String) -> NPC:
	if not on("homestead_choice") or _asp() == null:
		return null
	var cf := cfg()
	var kind := "young" if path == "young" else "adult"
	for o: NPC in leaving:
		if not formations.has(str(o.id)):
			formations[str(o.id)] = w.day()
			_note_total("form_" + kind)
	if w.homesteads.gate(h, leaving) != "":
		return null                                  # the village cannot spare them now (Homesteads.gate counts why)
	var share := float(cf.young_share) if kind == "young" else float(cf.adult_share)
	var forms := _total("form_" + kind)
	var homes := _total("home_" + kind)
	if float(homes) + 0.5 > share * float(forms):
		_count("brake_" + kind)
		_rec("homestead_brake", {"person": founder.id, "path": kind, "formations": forms, "homesteads": homes})
		return null                                  # the population safeguard: no homestead is on offer now
	var forms_w := _in_window("form_" + kind, int(cf.window_days))
	if _in_window("home_" + kind, int(cf.window_days)) >= maxi(1, ceili(share * float(forms_w))):
		_count("brake_window_" + kind)
		return null
	var who: NPC = null
	for o: NPC in leaving:
		if o.role == "adult" and (who == null or Life.npc_age(w, o) < Life.npc_age(w, who)):
			who = o
	if who == null:
		return null
	var site := w.homesteads.find_site(who)
	if site.is_empty():
		_count("no_site")
		return null
	var cands := [{"id": "village", "factors": _village_factors(who, h)}, {"id": "homestead", "factors": _homestead_factors(who, h, site)}]
	_count("weighed_" + kind)
	var pick := _choose(who.id, "homestead_choice", cands, [w.day(), who.id, 1])
	_rec("homestead_choice", {"person": who.id, "household": World.hh_ref(h), "path": kind, "chosen": pick, "site": [site.lay.land.position.x, site.lay.land.position.y],
		"eligible_formations": forms})
	if pick != "homestead":
		return null
	w.homesteads.pending_site = site
	return who


## Homesteads._go: a homestead really set out (after the decision, the gates and the coins): counted against the brake.
func homestead_started(path: String) -> void:
	_note_total("home_" + ("young" if path == "young" else "adult"))


## What staying in the village offers: the status quo, a home to be had (the market or ground), places in the labour market,
## the family round them.
func _village_factors(n: NPC, h: int) -> Dictionary:
	var asp := _asp()
	var surv := asp.survival(n, w)
	var homes := w.property.market().filter(func(r): return w.property.is_home(r) or w.property.is_home(w.property.unit(r).back())).size()
	var open := 0
	var market: Dictionary = w.brain.job_market()
	for j in market:
		open += int(market[j].get("open", 0))
	var kin := 0
	for pid in [n.mother, n.father, n.partner] + (n.children as Array):
		var k := w.npc(int(pid)) if int(pid) >= 0 else null
		if k != null and k.alive and not w.homesteads.away(k):
			kin += 1
	var fam := asp.eff_priority(n, JudgmentAspiration.FAMILY, surv, w)
	return {"live_order": 100000, "housing": _clamp(minf(1.0, homes / 2.0) * 50000.0 + 50000.0), "jobs": _clamp(minf(1.0, open / 4.0) * 100000.0),
		"family": _clamp(minf(1.0, kin / 4.0) * float(fam) / 1000.0 * 100000.0)}


## What the homestead offers and costs: owning land and a house (the property aspiration's priority against its satisfaction),
## the land's fit to their trade, the money in hand, the village's poor prosperity, taxes (minor), and isolation and danger.
func _homestead_factors(n: NPC, h: int, site: Dictionary) -> Dictionary:
	var asp := _asp()
	var surv := asp.survival(n, w)
	var sat: Array = asp.satisfaction(n, w)
	var prop := asp.eff_priority(n, JudgmentAspiration.PROPERTY, surv, w)
	var prof := asp.eff_priority(n, JudgmentAspiration.PROFESSION, surv, w)
	var sc: Dictionary = w.homesteads._score({"lay": site.lay, "anchor": site.anchor}, n.job, n)
	var start := ceili(w.construction.estimate(w.construction.cost_of("house")) * float(GameData.b("found_start_share")))
	var spare := w.property.purse(World.hh_ref(h))
	var rate := TaxPolicy.rate_of(int(w.tax_state.band)) if w.tax_state.has("band") else 0.0
	return {"property": _clamp(float(prop) / 1000.0 * float(100000 - int(sat[JudgmentAspiration.PROPERTY]))),
		"trade_fit": _clamp(float(prof) / 1000.0 * clampf(float(sc.score) * 100000.0, 0.0, 100000.0)),
		"capital": _clamp(float(spare) / float(maxi(1, start * 3)) * 100000.0),
		"prosperity": _clamp((1.0 - clampf(w.food_days / 10.0, 0.0, 1.0)) * 100000.0),
		"tax": _clamp(rate * 100000.0 / 0.3),
		"isolation": _clamp(float(sc.market) / float(maxi(1, int(Homesteads.cfg().road_to))) * 60000.0 + float(sc.danger) * 40000.0)}


## The secondary path (D2): an established adult at a relocation event (a housing goal waited long, widowed, out of work):
## evaluated on their own seasonal turn only, never parents of young children (Construction._may_found), never one who
## holds a business, a post or obligations (the gates), with the adults' much smaller allowance.
func _adults_dawn() -> void:
	if not on("homestead_choice") or _asp() == null:
		return
	var cf := cfg()
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false) or hh.has("homestead") or Life.is_couple(hh) or hh.has("venture"):
			continue
		var waited := false
		for g in w.construction.housing_goals(h).values():
			waited = waited or w.day() - int(g.get("since", w.day())) >= int(cf.adult_wait_days)
		for o: NPC in w.brain._members(h):
			if o.role != "adult" or Life.npc_age(w, o) <= float(Homesteads.cfg().young_max_age) or not _turn(o.id) or not w.construction._may_found(o):
				continue
			var widowed := o.partner >= 0 and w.npc(o.partner) != null and not w.npc(o.partner).alive
			var jobless := o.job == "" and w.day() - o.job_since > int(cf.adult_wait_days)
			if not (waited or widowed or jobless):
				continue
			var leaving: Array = [o]
			var p := w.npc(o.partner) if o.partner >= 0 else null
			if p != null and p.alive and p.household == h:
				if not w.construction._may_found(p):
					continue
				leaving.append(p)
			if w.homesteads.gate(h, leaving) != "":
				continue
			var who := homestead_decider(h, o, leaving, "adult")
			if who != null and w.homesteads.begin(h, who, leaving, "adult"):
				return                                   # one a morning at most


# ---------------------------------------------------------------- hardship -----------------------
## Each dawn, after the households' positions (NPCBrain.evaluate_household): a household's hardship record. A bad dawn (the
## household cannot live on its income and holds under a day of food, or a child of it is badly hungry) adds one; a good dawn
## takes off good_decay (improvement counts). A major event (a parent dead since yesterday, the home lost) is dated.
func _hardship_dawn() -> void:
	var cf := cfg()
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false):
			hardship.erase(str(h))
			continue
		var members: Array = w.brain._members(h)
		if members.is_empty():
			continue
		var econ: Dictionary = hh.get("econ", {})
		var hungry_child := false
		var adults := 0
		for o: NPC in members:
			if o.role == "child" and o.hunger < float(cf.hungry_child_below):
				hungry_child = true
			if o.role != "child":
				adults += 1
		var bad: bool = hungry_child or (not econ.is_empty() and not bool(econ.get("sustainable", true)) and w.brain.household_food_days(h) < 1.0)
		var r: Dictionary = hardship.get(str(h), {"bad": 0, "home": str(hh.home), "adults": adults, "event": -999})
		r.bad = int(r.bad) + 1 if bad else maxi(0, int(r.bad) - int(cf.good_decay))
		if adults < int(r.get("adults", adults)) or (str(r.get("home", "")) != "" and str(hh.home) == ""):
			r.event = w.day()                          # a parent or guardian lost, or the home
		r.adults = adults
		r.home = str(hh.home)
		hardship[str(h)] = r


# ---------------------------------------------------------------- runaways -----------------------
func _runaways_dawn() -> void:
	if not on("runaway_choice"):
		return
	var cf := cfg()
	var season := maxi(1, ceili(Life.seasons_to_days(1.0)))
	var ran_village := _in_window("ran", int(cf.window_days))
	for n: NPC in w.npcs.duplicate():
		if not n.alive or n.clan != "" or n.role == "bandit" or n.household < 0 or pending.has(str(n.id)) or not n.journey.is_empty():
			continue
		var r: Dictionary = hardship.get(str(n.household), {})
		if r.is_empty():
			continue
		var age := Life.npc_age(w, n)
		var young := n.role == "child" and age >= float(cf.runaway_min_age)
		var little := n.role == "child" and age < float(cf.runaway_min_age) and age >= float(cf.little_min_age)
		var displaced := n.role == "adult" and str(w.households[n.household].home) == "" and int(w.households[n.household].get("unsustainable_days", 0)) >= int(cf.displaced_days)
		if not (young or little or displaced):
			continue
		var need := int(cf.runaway_days) * (int(cf.little_factor) if little else 1)
		var event := w.day() - int(r.event) < season
		var last := int(seen.get(str(n.id), -9999))
		if int(r.bad) < need and not (event and int(r.bad) >= need / 2):
			continue
		if w.day() - last < season and not (event and int(r.event) > last):
			continue
		seen[str(n.id)] = w.day()
		if ran_village >= maxi(1, int(cf.runaways_per_window)):
			_count("brake_runaway")
			continue
		if last_ran_from(n.household) >= 0 and w.day() - last_ran_from(n.household) < int(cf.household_gap_days):
			_count("brake_runaway_household")
			continue
		var out := _weigh_runaway(n, r, little, displaced)
		_count("runaway_weighed")
		if out != "stay" and out != "":
			ran_village += 1


func last_ran_from(h: int) -> int:
	var best := -1
	for id in runaways:
		if int(runaways[id].from) == h:
			best = maxi(best, int(runaways[id].day))
	return best


## The young person's (or displaced adult's) choice and its consequence. Returns the outcome.
func _weigh_runaway(n: NPC, r: Dictionary, little: bool, displaced: bool) -> String:
	var cf := cfg()
	var age := Life.npc_age(w, n)
	var maturity := clampf((age - float(cf.little_min_age)) / (16.0 - float(cf.little_min_age)), 0.0, 1.0)
	var hard := _clamp(float(r.bad) / float(maxi(1, int(cf.runaway_days) * 2)) * 100000.0)
	var carer := w.construction.responsible_adult(n.household)
	var loyal := 50000
	if carer != null and carer != n and w.judgment != null:
		loyal = clampi(int(w.judgment.disposition(n.id, carer.id)), 0, 100000)
	var tiers: Dictionary = Guardianship.candidates(w, n) if not displaced else {}
	var help_h := -1
	for tier in ["parent", "grandparent", "relative", "villager"]:
		for hh in tiers.get(tier, []):
			if int(hh) != n.household and help_h < 0:
				help_h = int(hh)
	var band := Outlaws.band_alive(w)
	var ev := 100000 if w.day() - int(r.get("event", -999)) < maxi(1, ceili(Life.seasons_to_days(1.0))) else 0     # a parent or the home just lost
	var cands := [{"id": "stay", "factors": {"live_order": 100000, "loyalty": loyal, "youth": _clamp((1.0 - maturity) * 100000.0)}}]
	cands.append({"id": "seek_help", "feasible": help_h >= 0, "why": "nobody can take them in", "factors": {"hardship": hard,
		"refuge": 100000, "youth": _clamp((1.0 - maturity) * 100000.0), "event": ev}})
	cands.append({"id": "work_home", "feasible": n.role == "adult", "why": "too young for a place", "factors": {"hardship": hard}})
	var sid := _known_settlement()
	cands.append({"id": "run_settlement", "feasible": not little and age >= float(cf.travel_min_age) and sid != "", "why": "too young, or no settlement known",
		"factors": {"hardship": hard, "maturity": _clamp(maturity * 100000.0), "escape": hard, "event": ev}})
	cands.append({"id": "survive_alone", "feasible": not little and (age >= float(cf.alone_min_age) or n.role == "adult"), "why": "too young to live alone",
		"factors": {"hardship": hard, "maturity": _clamp(maturity * 100000.0), "danger": 100000, "event": ev}})
	cands.append({"id": "seek_band", "feasible": not little and band, "why": "no band nearby", "factors": {"hardship": hard,
		"maturity": _clamp(maturity * 100000.0), "escape": hard, "danger": 60000, "loyalty_left": 100000 - loyal, "event": ev}})
	var profile := "runaway_choice"
	var out := _choose(n.id, profile, cands, [w.day(), n.id, 2])
	if out == "" or out == "forgo":
		out = "stay"
	_count("runaway_" + out)
	_rec("runaway_choice", {"person": n.id, "household": World.hh_ref(n.household), "age": snappedf(age, 0.1), "hardship": int(r.bad), "event": ev > 0,
		"displaced": displaced, "chosen": out})
	if out == "stay":
		return out
	var from := n.household
	runaways[str(n.id)] = {"from": from, "day": w.day(), "outcome": out, "age": snappedf(age, 0.1)}
	_hist("ran")
	_hist("runaway_" + out)
	JudgmentLive.on_news(w, "ran_away", "npc:%d" % n.id, [], n.pos)    # the family knows; the rest hear it told
	_rec("runaway_departed", {"person": n.id, "origin": World.hh_ref(from), "destination": {"seek_help": World.hh_ref(help_h), "run_settlement": sid,
		"seek_band": "band", "survive_alone": "alone", "work_home": "home"}.get(out, "")})
	_rec("runaway_outcome", {"person": n.id, "action": {"seek_help": "sheltered", "work_home": "employed", "run_settlement": "relocated", "survive_alone": "independent",
		"seek_band": "pending"}.get(out, out)})
	match out:
		"seek_help":
			Guardianship.move(w, n, help_h, "refuge")
			w.note("%s %s leaves a hard home and is taken in by the %s household." % [n.name, n.family, w.households[help_h].family])
		"work_home":
			w.note("%s %s looks for work to help the household." % [n.name, n.family])
		"run_settlement":
			if Journeys.start(w, n, sid, {"kind": "runaway"}) == "":
				w.note("%s %s runs away from home, down the road to %s." % [n.name, n.family, w.map.overworld.site(sid).name])
			else:
				runaways[str(n.id)].outcome = "stay"
		"survive_alone":
			_found_alone(n)
		"seek_band":
			pending[str(n.id)] = {"go": "band", "from": from}
			n.plan.clear()
			w.note("%s %s runs away from home towards the bandits' camp." % [n.name, n.family])
	return out


## The first neighbouring settlement this person would know of (the nearest by its road, Journeys' gate), "" none.
func _known_settlement() -> String:
	var ow: Overworld = w.map.overworld
	if ow == null or ow.sites.is_empty():
		return ""
	return str(ow.sites[0].id)


## Survive alone: a household of their own with no home (the village's rules for the homeless then apply: rest by the manor,
## relief, whatever work their age allows). Their pack goes with them; nothing is given.
func _found_alone(n: NPC) -> void:
	var old := n.household
	var nid := w.households.size()
	w.households.append({"id": nid, "family": n.family, "home": "", "members": [n.id], "pantry": Inventory.new(), "founded_from": old,
		"founded_day": w.day(), "runaway": true})
	(w.households[old].members as Array).erase(n.id)
	n.household = nid
	n.home = ""
	n.plan.clear()
	w.note("%s %s runs away from home to fend for themselves." % [n.name, n.family])
	if not w.property._anyone_alive(old):
		w.property.household_ended(old)
	w.brain.evaluate_household(old)
	w.brain.evaluate_household(nid)


## REGION-NAV-01 journey hook: a runaway at the settlement they ran to joins it (Migration's own move: the same person, their
## purse and pack cross the boundary as a migrant's do). True when this took the traveller.
func at_site(n: NPC) -> bool:
	if str(n.journey.get("purpose", {}).get("kind", "")) != "runaway" or w.regions == null:
		return false
	var s: OffMapSettlement = null
	for st: OffMapSettlement in w.regions.list:
		if st.id == str(n.journey.to):
			s = st
	if s == null:
		return false
	Journeys.end(w, n, "runaway")
	var ms := [n]
	Migration._pre_leave(w, ms)
	var load_ := Migration._pack(w, ms)
	s.receive_person(load_.people[0], int(load_.coins), load_.goods, "farm")
	Migration._gone(w, s, ms, load_, null, "hunger")
	s.note("%s arrives from the village, a runaway, and is taken into a household." % n.name)
	_count("runaway_arrived_settlement")
	return true


# ---------------------------------------------------------------- the band -----------------------
## A runaway or displaced adult on their way to the bandits' camp: driven here (World._update_npc) until they reach it.
func drives(n: NPC) -> bool:
	return pending.has(str(n.id))


func plan(n: NPC) -> void:
	var b: NPCBrain = w.brain
	n.doing = "running to the bandits' camp"
	n.plan = [b.go(b.wander_cell(w.bandit_camp, 2)), b.doit("life", {"step": "band"})]


func act(n: NPC, a: Dictionary) -> bool:
	if str(a.get("step", "")) != "band" or not pending.has(str(n.id)):
		return false
	pending.erase(str(n.id))
	_recruit_answer(n)
	return true


## The band answers (a decision of its own, by its eldest bandit): reject, take a child in as a dependant (never a fighter), or
## accept an adult. Nothing is given to the recruit.
func _recruit_answer(n: NPC) -> String:
	var leader: NPC = null
	var size := 0
	var food := 0.0
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			size += 1
			food += NPCBrain.store_points([o.inv])
			if leader == null or o.born < leader.born:
				leader = o
	if leader == null or not on("recruit_answer"):
		_count("recruit_none")
		return "reject"
	var child := n.role == "child"
	var kin := false
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit" and (Life.kin(n.id, n.mother, n.father, o.id, o.mother, o.father)):
			kin = true
	var per := food / float(maxi(1, size))
	var cands := [{"id": "reject", "factors": {"live_order": 100000, "band_full": _clamp(float(size) / float(maxi(1, int(cfg().band_full))) * 100000.0)}},
		{"id": "dependant", "feasible": child, "why": "a grown recruit", "counterparty": n.id, "factors": {"use": 50000, "kin": 100000 if kin else 0,
			"food": _clamp(per / 400.0 * 100000.0)}},
		{"id": "accept", "feasible": not child, "why": "a child", "counterparty": n.id, "factors": {"need": _clamp((1.0 - float(size) / float(maxi(1, int(cfg().band_full)))) * 100000.0),
			"kin": 100000 if kin else 0, "health": _clamp(n.hp / maxf(1.0, n.max_hp) * 100000.0), "food": _clamp(per / 400.0 * 100000.0)}}]
	var ans := _choose(leader.id, "recruit_answer", cands, [w.day(), n.id, 3])
	if ans == "" or ans == "forgo":
		ans = "reject"
	_count("recruit_" + ans)
	_hist("recruit_" + ans)
	var source := "runaway" if runaways.has(str(n.id)) else ("displaced" if n.role == "adult" else "child")
	_rec("band_recruit", {"person": n.id, "leader": leader.id, "answer": ans, "source": source, "band": size, "age": snappedf(Life.npc_age(w, n), 0.1)})
	if runaways.has(str(n.id)):
		runaways[str(n.id)].band = ans
	match ans:
		"dependant", "accept":
			if runaways.has(str(n.id)):
				_rec("runaway_outcome", {"person": n.id, "action": "joined_outlaws"})
	match ans:
		"dependant":
			_join_band(n, false)
			w.note("The bandits take %s %s in at their camp." % [n.name, n.family])
		"accept":
			_join_band(n, true)
			w.note("The bandits take %s %s into the band." % [n.name, n.family])
		_:
			w.note("The bandits send %s %s away." % [n.name, n.family])
			n.plan.clear()
	return ans


## Joining the band: a child as a clan dependant (Guardianship.join_clan's standing: never prey, never in a fight), an adult as a
## bandit (the role a clan child takes at coming of age, its health and blow untouched). Name, age, family tree, relationships,
## skills, pack and purse are kept; the household keeps them in its records (mother, father) and learns of it.
func _join_band(n: NPC, fighter: bool) -> void:
	var old := n.household
	if old >= 0:
		(w.households[old].members as Array).erase(n.id)
	n.household = -1
	n.home = ""
	n.workplace = ""
	n.job = ""
	n.plan.clear()
	if fighter:
		n.role = "bandit"
		Outlaws.after_load(w)                          # (the band is alive again: its clock stops)
	else:
		n.clan = "bandit"
	JudgmentLive.on_news(w, "joined_band", "npc:%d" % n.id, [], n.pos)
	if old >= 0 and not w.property._anyone_alive(old):
		w.property.household_ended(old)
	elif old >= 0:
		w.brain.evaluate_household(old)


## Decision 4: each adult bandit, on their seasonal turn, weighs leaving the band for ordinary life.
func _bandits_dawn() -> void:
	if not on("bandit_leave"):
		return
	var size := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			size += 1
	var market: Dictionary = w.brain.job_market()
	var open := 0
	for j in market:
		open += int(market[j].get("open", 0))
	var dead := 0                                      # the band's dead the band knows of (their records stay in World.npcs)
	for o: NPC in w.npcs:
		if not o.alive and o.role == "bandit" and o.away == "":
			dead += 1
	for n: NPC in w.npcs.duplicate():
		if not n.alive or n.role != "bandit" or not _turn(n.id) or n.target != -1:
			continue
		var family := 0
		for pid in [n.mother, n.father, n.partner] + (n.children as Array):
			var k := w.npc(int(pid)) if int(pid) >= 0 else null
			if k != null and k.alive and k.role != "bandit" and k.clan == "":
				family += 1
		var asp := _asp()
		var amb := asp.eff_priority(n, JudgmentAspiration.PROFESSION, asp.survival(n, w), w) if asp != null else 1000
		var cands := [{"id": "stay", "factors": {"live_order": 100000, "band": _clamp(float(size) / 6.0 * 100000.0)}},
			{"id": "leave", "factors": {"family": _clamp(float(family) / 2.0 * 100000.0), "fear": _clamp((1.0 - n.hp / maxf(1.0, n.max_hp)) * 100000.0 + minf(float(dead), 5.0) * 8000.0),
				"lawful_work": _clamp(minf(float(open), 4.0) / 4.0 * 100000.0), "ambition": clampi((amb - 500) * 100, 0, 100000)}}]
		_count("leave_weighed")
		if _choose(n.id, "bandit_leave", cands, [w.day(), n.id, 4]) == "leave":
			leave_band(n)


## An adult bandit leaves for ordinary life (Decision 4): no longer a bandit, everything else kept (identity, crimes and cases,
## relationships, skills, pack, purse, wounds). They join a parent, kin or a willing household by Guardianship's order, else
## found a household of their own, which seeks a home by the village's rules. They walk from the camp themselves.
func leave_band(n: NPC) -> String:
	n.role = "adult"
	n.target = -1
	n.plan.clear()
	var tiers := Guardianship.candidates(w, n)
	var tier := ""
	for t in ["parent", "grandparent", "relative", "villager"]:
		if not (tiers.get(t, []) as Array).is_empty():
			Guardianship.move(w, n, int(tiers[t][0]), "former bandit")
			tier = t
			break
	if tier == "":
		var nid := w.households.size()
		w.households.append({"id": nid, "family": n.family if n.family != "" else n.name, "home": "", "members": [n.id], "pantry": Inventory.new(),
			"founded_day": w.day(), "former_band": true})
		n.household = nid
		n.home = ""
		if n.family == "":
			n.family = n.name
		w.brain.evaluate_household(nid)
		tier = "own"
	_count("left_band")
	_count("left_band_to_" + tier)
	_rec("band_left", {"person": n.id, "to": tier, "household": World.hh_ref(n.household)})
	_rec("bandit_reintegrated", {"person": n.id, "action": "new_household" if tier == "own" else "household", "tier": tier, "household": World.hh_ref(n.household)})
	_hist("left_band")
	JudgmentLive.on_news(w, "left_band", "npc:%d" % n.id, [], n.pos)
	w.note("%s %s leaves the bandits for an ordinary life (%s)." % [n.name, n.family, tier])
	if not Outlaws.band_alive(w):
		Outlaws.on_death(w, n)                         # the band's clock starts as at its last death
	return tier


# ---------------------------------------------------------------- daily ---------------------------
## Each dawn, after the construction and the homesteads (World._new_day).
func dawn() -> void:
	_hardship_dawn()
	_adults_dawn()
	_runaways_dawn()
	_bandits_dawn()
	var keep := int(cfg().window_days) * 3
	while not history.is_empty() and w.day() - int(history[0][0]) > keep:
		history.pop_front()


func report() -> Dictionary:
	var band := 0
	var clan := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			band += 1
		elif o.alive and o.clan == "bandit":
			clan += 1
	return {"band": band, "clan_children": clan, "runaways": runaways.size(), "counts": counts.duplicate()}


func to_dict() -> Dictionary:
	return {"format": FORMAT, "hardship": hardship.duplicate(true), "seen": seen.duplicate(), "formations": formations.duplicate(),
		"history": history.duplicate(true), "pending": pending.duplicate(true), "runaways": runaways.duplicate(true), "counts": counts.duplicate()}


func load_dict(d: Dictionary) -> void:
	hardship = (d.get("hardship", {}) as Dictionary).duplicate(true)
	seen = (d.get("seen", {}) as Dictionary).duplicate()
	formations = (d.get("formations", {}) as Dictionary).duplicate()
	history = (d.get("history", []) as Array).duplicate(true)
	pending = (d.get("pending", {}) as Dictionary).duplicate(true)
	runaways = (d.get("runaways", {}) as Dictionary).duplicate(true)
	counts = (d.get("counts", {}) as Dictionary).duplicate()


## B25R1-016 (the 365-day flight recorder): every stage of a homestead's life and every life choice is offered to the recorder,
## read only (never a state change, never a random number): recorder.life_event(kind, data) when the recorder has it (its
## vocabulary is the recorder worker's, wip/b25r1-recorder); people by their Identity ids, households "hh:<n>", claims by id.
func _rec(kind: String, data: Dictionary) -> void:
	if w.recorder != null and w.recorder.has_method("life_event"):
		data["day"] = w.day()
		w.recorder.life_event(kind, data)


# ---------------------------------------------------------------- scenario entry points ---------
## B25R1-016: documented start conditions for the recorder's targeted-scenario harness and the tests. They set a record or run
## a decision exactly as the dawn would; the game's rules and weights are unchanged (no probability is raised).
## A household's hardship record: `bad` dawns of it, a major event (a parent or the home lost) on `event_day` (-999 none).
func set_hardship(h: int, bad: int, event_day := -999) -> void:
	hardship[str(h)] = {"bad": bad, "home": str(w.households[h].home), "adults": w.brain._members(h).filter(func(o: NPC) -> bool: return o.role != "child").size(),
		"event": event_day}


## The runaway choice for `n` now, on their household's record (as _runaways_dawn does once the threshold is met). The outcome.
func weigh_runaway(n: NPC) -> String:
	var r: Dictionary = hardship.get(str(n.household), {})
	if r.is_empty():
		return ""
	seen[str(n.id)] = w.day()
	var little := n.role == "child" and Life.npc_age(w, n) < float(cfg().runaway_min_age)
	return _weigh_runaway(n, r, little, n.role == "adult")


## The band's answer to `n` asking to join at the camp. "reject", "dependant" or "accept".
func recruit(n: NPC) -> String:
	return _recruit_answer(n)
