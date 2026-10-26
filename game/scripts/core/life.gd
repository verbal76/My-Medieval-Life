class_name Life
extends RefCounted
## B8-029: the calendar, ages, life stages, partners, births, old-age death and the family line.
##
## Owner-approved design (2026-10-19, DECISIONS.md; every number is in balance.json "calendar" and
## "life", provisional per docs/BUILD_DECISIONS.md):
##  - one calendar on the world clock: a year is `year_days` game days in `seasons` of `season_days`;
##    ages are in those years and a pure function of `born` and the clock, so unloaded areas and
##    reloads stay consistent;
##  - stages: child (to 12), adolescent (12-16), adult (16-55), elder (55+). `NPC.role` follows age
##    (child covers adolescents: no full jobs; adult; elder) and is updated at dawn and on load; bandits
##    age but keep their role. The sage and the reeve serve for life (their role stays "adult");
##  - households are NOT families. Relationships are explicit links on NPC and PlayerState: mother,
##    father, partner, children. Partners are made by courting (Relations; the player's accepted proposal ends in `partner_player`);
##    births are only to partners; nothing is ever inferred from a shared house;
##  - old age: a daily chance from `mortality_from` rising to certain death at `mortality_certain_at`;
##  - inheritance and the player's heir follow the family graph (heir_of, player_heir_child).
## The player is -2 wherever an NPC id is expected (PLAYER_ID), as in NPC.target.

const PLAYER_ID := -2


## True when a person id (NPC.target, a tie, a family link, a judgment id) names a player character's family line. MP Batch A1:
## the one place that decides it. MP Batch C: the host's line is the legacy -2 (ID-D1, every save); a guest's line is the negative of
## its line's pid (World.person_id: -(line), at or below -World.BAND_START), so a guest has ties, family links, judgment and foes of
## its own, recognized without a world at hand (no NPC, -1 "none" or -3 FORMER_PLAYER is ever that low). World.player_of_id finds the
## living character. Single player has only -2: unchanged.
static func is_player_id(id: int) -> bool:
	return id == PLAYER_ID or id <= -World.BAND_START


const FORMER_PLAYER := -3              # the dead player of an earlier generation, in the links of their kin
const FEMALE := ["Agnes", "Alice", "Amice", "Avice", "Beatrice", "Cecily", "Denise", "Edith", "Ellen", "Emma",
	"Hawise", "Isabel", "Joan", "Juliana", "Katherine", "Lettice", "Mabel", "Margery", "Matilda", "Petronilla",
	"Rose", "Sabina", "Sybil", "Alys", "Maud", "Red Ankarette"]
const PLAYER_HEIR_NAMES := ["Alys", "Hob", "Maud", "Piers", "Emma", "Jack", "Agnes", "Will"]


static func cfg() -> Dictionary:
	return GameData.b("life")


# ---------------------------------------------------------------- calendar -------------------
## Bumped whenever a family link (mother, father, partner, children) is made, so what is derived from the family graph
## (JudgmentBonds' relatives by distance) can be kept until it changes. Not saved; the derived values are rebuilt after a load.
static var kin_version := 0


static func year_days() -> int:
	return maxi(1, int(GameData.b("calendar").year_days))


static func year_minutes() -> float:
	return World.DAY * year_days()


# ---------------------------------------------------------------- time units (TIME-02) -------
## The one conversion layer between calendar time and the world clock (OD-21, docs/design/TIME_MODEL.md).
## Calendar values (ages, lifespans, breeding, growth, seasonal regrowth) are written in balance.json in
## years (`_years`) or seasons (`_seasons`) and read through these functions, so they keep their meaning
## in years if `calendar.year_days` changes. Operational values (hours, days of work, food-days, wages)
## are read as they are and never pass through here. No second clock: everything is World.minutes.
## At 8 days a year every conversion is exact (a power of two), so the results are the old day counts.

## Number of seasons in a year.
static func season_count() -> int:
	return maxi(1, (GameData.b("calendar").seasons as Array).size())


## Game days in `years` calendar years.
static func years_to_days(years: float) -> float:
	return years * year_days()


## Game days in `seasons` calendar seasons (a season is year_days / season_count days).
static func seasons_to_days(seasons: float) -> float:
	return seasons * year_days() / float(season_count())


## Calendar years in `days` game days.
static func days_to_years(days: float) -> float:
	return days / year_days()


## Game minutes in `years` calendar years.
static func years_to_minutes(years: float) -> float:
	return years_to_days(years) * World.DAY


## Game minutes in `seasons` calendar seasons.
static func seasons_to_minutes(seasons: float) -> float:
	return seasons_to_days(seasons) * World.DAY


## A yearly rate (expected events per calendar year, as a hazard) as the daily rate a dawn roll uses.
static func per_year_to_per_day(per_year: float) -> float:
	return per_year / year_days()


## A [low, high] range in calendar seasons as whole game days (the regrowth draws are of whole days).
static func season_range_days(r: Array) -> Vector2i:
	return Vector2i(roundi(seasons_to_days(float(r[0]))), roundi(seasons_to_days(float(r[1]))))


## Age in years of someone born at game minute `born`, at game minute `now`.
static func age_years(born: float, now: float) -> float:
	return (now - born) / year_minutes()


## The game minute of a birth `years` years before `now`.
static func born_for_age(years: float, now: float) -> float:
	return now - years * year_minutes()


## Year of the calendar, from 1.
static func year(now: float) -> int:
	return int(floor(now / year_minutes())) + 1


## 0-based day within the year.
static func day_of_year(now: float) -> int:
	return int(floor(now / World.DAY)) % year_days()


static func season_index(now: float) -> int:
	var c: Dictionary = GameData.b("calendar")
	var lens: Array = c.season_days
	var d := day_of_year(now)
	for i in lens.size() - 1:
		if d < int(lens[i]):
			return i
		d -= int(lens[i])
	return lens.size() - 1


static func season(now: float) -> String:
	return str(GameData.b("calendar").seasons[season_index(now)])


## "Spring, Year 1  Day 3  07:00" (Day: of the year).
static func clock_text(now: float) -> String:
	var h := int(fmod(now, World.DAY) / 60.0)
	var m := int(fmod(now, 60.0))
	return "%s, Year %d  Day %d  %02d:%02d" % [season(now), year(now), day_of_year(now) + 1, h, m]


# ---------------------------------------------------------------- stages ---------------------
static func stage_of(age: float) -> String:
	var c := cfg()
	if age < float(c.child_until):
		return "child"
	if age < float(c.adolescent_until):
		return "adolescent"
	if age < float(c.elder_from):
		return "adult"
	return "elder"


static func stage(n: NPC, now: float) -> String:
	return stage_of(age_years(n.born, now))


static func npc_age(w: World, n: NPC) -> float:
	return age_years(n.born, w.minutes)


## The role an age gives. Bandits keep theirs; the sage and the reeve serve for life.
static func role_for(w: World, n: NPC) -> String:
	if n.role == "bandit":
		return "bandit"
	match stage(n, w.minutes):
		"child", "adolescent":
			return "child"
		"elder":
			return "adult" if n.job in ["reeve", "sage"] else "elder"
	return "adult"


## Drawn size of a villager (child 0.5, adolescent 0.75, else 1).
static func npc_scale(n: NPC, now: float) -> float:
	match stage(n, now):
		"child":
			return float(cfg().child_scale)
		"adolescent":
			return float(cfg().adolescent_scale)
	return 1.0


static func walk_factor(n: NPC) -> float:
	return float(cfg().elder_speed) if n.role == "elder" else 1.0


## Daily chance of dying of old age at `age` years.
static func death_chance(age: float) -> float:
	var c := cfg()
	var from := float(c.mortality_from)
	var at := float(c.mortality_certain_at)
	if age < from:
		return 0.0
	if age >= at:
		return 1.0
	return minf(1.0, per_year_to_per_day(float(c.mortality_yearly_max)) * pow((age - from) / (at - from), float(c.mortality_curve)))


## Update every villager's role from their age (dawn and load). A worker who turns elder retires: the
## post opens like a death's (NPCBrain succession) and the household re-evaluates. A child who turns 16 is
## an adult without a trade: job market, apprenticeship and succession take it from there.
static func sync_roles(w: World) -> void:
	for n: NPC in w.npcs:
		if not n.alive or n.role == "bandit":
			continue
		var r := role_for(w, n)
		if r != n.role:
			var was := n.role
			_set_role(w, n, r)
			if w.recorder != null and n.role != was:
				w.recorder.role_changed(n, was)      # REC-19: ageing into a role


static func _set_role(w: World, n: NPC, r: String) -> void:
	var who := "%s %s" % [n.name, n.family]
	if n.role == "adult" and r == "elder":
		w.brain._open_vacancy(n)
		if n.job != "":
			w.brain._change_job(n, "", "retired in old age")
		w.construction.on_death(n)
		w.manor_work.on_death(n)
		n.max_hp = 20.0
		n.hp = minf(n.hp, n.max_hp)
		n.role = "elder"
		n.plan.clear()
		w.note("%s grows old and retires." % who)
		w.stat("retired")
	elif r == "adult" and n.clan == "bandit" and Guardianship.leave_camp(w, n) == "":
		# FAM-07 (owner, clarified 2026-10-20): staying with the band is one possible outcome, not a mandatory one. With no
		# kin or household able to take the young adult in, they stay and run with the band: a bandit's health and blow,
		# nothing made for them. (Their own weighing of the choice is FAM-08: NPC Judgment, bandit factions.)
		n.role = "bandit"
		n.max_hp = 25.0
		n.hp = n.max_hp
		n.damage = 4.0
		n.plan.clear()
		w.note("%s comes of age among the bandits and stays with the band." % who)
		w.stat("came_of_age_in_clan")
	elif r == "adult":
		n.role = "adult"
		n.max_hp = 30.0
		n.hp = minf(n.max_hp, n.hp + 15.0)
		n.plan.clear()
		w.note("%s comes of age." % who)
		w.stat("came_of_age")
		if w.judgment != null:
			JudgmentLive.on_come_of_age(w, n)         # X19-STORY-LIFE: the parents will tell them the family stories
	else:
		n.role = r
		n.plan.clear()


# ---------------------------------------------------------------- relationships --------------
static func sex_of_name(name: String) -> String:
	return "female" if FEMALE.has(name) else "male"


static func parent_of(w: World, id: int) -> Object:
	return w.player_of_id(id) if is_player_id(id) else w.npc(id)          # MP C5: that player's line, whoever is acting


## Is this person's partner alive and recorded as theirs?
static func has_partner(w: World, n: NPC) -> bool:
	if is_player_id(n.partner):
		var pp := w.player_of_id(n.partner)                       # MP C5: the player whose partner they are
		return pp != null and pp.alive and pp.partner == n.id
	if n.partner >= 0:
		var o := w.npc(n.partner)
		return o != null and o.alive and o.partner == n.id
	return false


static func kin(a_id: int, a_mother: int, a_father: int, b_id: int, b_mother: int, b_father: int) -> bool:
	if a_mother == b_id or a_father == b_id or b_mother == a_id or b_father == a_id:
		return true
	return (a_mother != -1 and a_mother == b_mother) or (a_father != -1 and a_father == b_father)


static func _link_partners(a: NPC, b: NPC) -> void:
	a.partner = b.id
	b.partner = a.id
	kin_version += 1


static func _link_child(c: NPC, mother, father, w: World = null) -> void:
	if mother != null:
		c.mother = (w.person_id(mother) if w != null else PLAYER_ID) if mother is PlayerState else (mother as NPC).id     # MP C5: a guest parent's own id
		mother.children.append(c.id)
	if father != null:
		c.father = (w.person_id(father) if w != null else PLAYER_ID) if father is PlayerState else (father as NPC).id
		father.children.append(c.id)
	kin_version += 1


## The starting population's explicit families, ages and sexes: derived from the households,
## deterministic from the seed (own RNG: the population's other draws are unchanged). A household's
## first adult man and woman are recorded as partners, its elders likewise; its children get them (or its
## one adult of either sex) as parents, with ages that fit. Recorded once here as explicit links.
static func seed_population(w: World) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = w.seed * 104729 + 7
	var c := cfg()
	var now := w.minutes
	var a_lo := float(c.start_adult_age[0])
	var a_hi := float(c.start_adult_age[1])
	for n: NPC in w.npcs:
		n.sex = sex_of_name(n.name)
	var byid := {}
	for n: NPC in w.npcs:
		byid[n.id] = n
	for hh in w.households:
		var adults: Array = []
		var elders: Array = []
		var kids: Array = []
		for id in hh.members:
			var n: NPC = byid[int(id)]
			match n.role:
				"adult":
					adults.append(n)
				"elder":
					elders.append(n)
				"child":
					kids.append(n)
		var couple := _pair(adults)                                 # [man, woman] or []
		var anchor: NPC = null                                      # the mother (or the one adult) of the children
		if not couple.is_empty():
			_link_partners(couple[0], couple[1])
			anchor = couple[1]
		elif not adults.is_empty():
			anchor = adults[0]
		var have_kids := not kids.is_empty()
		for n: NPC in adults:
			var age := rng.randf_range(a_lo, a_hi)
			if n == anchor and have_kids:
				age = rng.randf_range(maxf(a_lo, 28.0), minf(a_hi, 42.0))
			if n.job == "sage":
				age = rng.randf_range(50.0, 54.0)
			n.born = born_for_age(age, now)
		if not couple.is_empty():                                   # the man's age follows the woman's
			couple[0].born = born_for_age(clampf(npc_age(w, couple[1]) + rng.randf_range(-4.0, 8.0), a_lo, a_hi), now)
		var e_lo := float(c.start_elder_age[0])
		var e_hi := float(c.start_elder_age[1])
		for n: NPC in elders:
			n.born = born_for_age(rng.randf_range(e_lo, e_hi), now)
		var eo := _pair(elders)
		if not eo.is_empty():
			_link_partners(eo[0], eo[1])
			eo[0].born = born_for_age(clampf(npc_age(w, eo[1]) + rng.randf_range(-6.0, 6.0), e_lo, e_hi), now)
		for k: NPC in kids:
			var top := float(c.start_child_age[1])
			if anchor != null:
				top = minf(top, npc_age(w, anchor) - 16.0)
			k.born = born_for_age(rng.randf_range(float(c.start_child_age[0]), maxf(float(c.start_child_age[0]), top)), now)
			if anchor != null:
				if not couple.is_empty():
					_link_child(k, couple[1], couple[0])
				elif anchor.sex == "female":
					_link_child(k, anchor, null)
				else:
					_link_child(k, null, anchor)
	for n: NPC in w.npcs:
		if n.role == "bandit":
			n.born = born_for_age(rng.randf_range(20.0, 45.0), now)


## [man, woman] of the first opposite-sex pair in the list, or [].
static func _pair(list: Array) -> Array:
	var m: NPC = null
	var f: NPC = null
	for n: NPC in list:
		if n.sex == "male" and m == null:
			m = n
		elif n.sex == "female" and f == null:
			f = n
	return [m, f] if m != null and f != null else []


static func init_player(w: World) -> void:
	var r: Array = cfg().player_start_age
	var span := int(r[1]) - int(r[0])
	w.player.born = born_for_age(float(r[0]) + (w.seed % (span + 1)), w.minutes)


# ---------------------------------------------------------------- dawn -----------------------
## Every dawn (World._new_day, before the brain's morning): roles, old-age deaths, new couples, births.
static func dawn(w: World) -> void:
	sync_roles(w)
	_natural_deaths(w)
	w.relations.dawn()                 # friendship and courting; villagers court and marry (CRT-04)
	sync_couple_homes(w)               # MP-PLAYER-FAMILY: a player couple's household lives in their home (nothing in single player)
	births(w)
	Guardianship.dawn(w)               # FAM-02..05: orphaned children are taken in by kin or a villager household
	Outlaws.dawn(w)                    # BANDIT-RETURN: a season after the band is gone, 2 or 3 outlaws arrive
	_player_dawn(w)


static func _natural_deaths(w: World) -> void:
	for n: NPC in w.npcs.duplicate():
		if not n.alive:
			continue
		var p := death_chance(npc_age(w, n))
		if p > 0.0 and (p >= 1.0 or w.rng.randf() < p):
			w.stat("old_age_deaths")
			w.kill(n, "old age")


static func _player_dawn(w: World) -> void:
	if w.player_list().size() > 1:
		for pl: PlayerState in w.active_players():       # a guest away (MP-D1) is out of play
			w.as_actor(pl, _player_dawn_one.bind(w))
		return
	_player_dawn_one(w)


static func _player_dawn_one(w: World) -> void:
	var p := w.player
	if not p.alive:
		return
	var q := death_chance(age_years(p.born, w.minutes))
	if q > 0.0 and (q >= 1.0 or w.rng.randf() < q):
		p.alive = false
		p.hp = 0.0
		p.death_cause = "old age"
		p.last_damage = "old age"
		p.deaths += 1
		w.note("%s %s died (old age)." % [p.name, p.family])
		if w.recorder != null:
			w.recorder.player_died(p, "old age")     # REC-19


static func _living_in(w: World, h: int) -> int:
	var c := 0
	for m in w.households[h].members:
		var o := w.npc(int(m))
		if o != null and o.alive:
			c += 1
	return c


## Whether a household's house has a sleeping place free (for `joining`, whether it would still fit with
## them: a partner joining their partner shares that bed). Beds are shared as Construction.beds_needed says.
static func has_room(w: World, h: int, joining: NPC = null) -> bool:
	if h < 0 or h >= w.households.size():
		return false
	var hh: Dictionary = w.households[h]
	if hh.get("ended", false) or not w.buildings.has(str(hh.home)):
		return false
	var beds: int = w.construction.beds_in(str(hh.home))
	if joining != null:
		return beds >= w.construction.beds_needed(h, joining)
	return beds > w.construction.beds_needed(h)


# ---------------------------------------------------------------- partners -------------------
## Partners are made by courting (Relations: gifts, time together, courting, a proposal; CRT-01/04). A new
## couple moves under one roof when one home has room (_move_in), else lives apart until one has or they
## found a household (Construction.couples_needing_home, EQ-07).


## Put the pair under one roof: nothing to do if they share a household; otherwise the one whose household
## is not fixed moves into the other's home if it has a free bed. False if no home can take them.
static func _move_in(w: World, a: NPC, b: NPC) -> bool:
	if a.household == b.household and a.household >= 0:
		return true
	# a partner whose household is building its own home stays with it and the other joins them, lodging
	# where they lodge until the house stands (EQ-07: a founder who paired moved into the partner's house
	# and the half-built house was abandoned for good); two partners each building stay apart for now
	var a_builds := _building(w, a)
	var b_builds := _building(w, b)
	if a_builds and b_builds:
		return false
	if a_builds != b_builds:
		var host: NPC = a if a_builds else b
		var mover: NPC = b if a_builds else a
		if not _may_move(w, mover):
			return false
		var was := mover.household
		(w.households[was].members as Array).erase(mover.id)
		w.brain._lodge(mover, host.household)
		mover.home = host.home
		mover.plan.clear()
		if was >= 0 and not w.property._anyone_alive(was):
			w.property.household_ended(was)
		return true
	for pair in [[a, b], [b, a]]:                              # [mover, host]
		var mover: NPC = pair[0]
		var host: NPC = pair[1]
		if host.household < 3 or not has_room(w, host.household, mover) or not _may_move(w, mover):
			continue
		var old := mover.household
		(w.households[old].members as Array).erase(mover.id)
		w.brain._lodge(mover, host.household)
		mover.plan.clear()
		if old >= 0 and not w.property._anyone_alive(old):
			w.property.household_ended(old)
		return true
	return false


## Whether `n`'s household is building its own home.
static func _building(w: World, n: NPC) -> bool:
	return n.household >= 0 and n.household < w.households.size() and str(w.households[n.household].get("build", "")) != ""


## Whether `n` may leave their household to live with a partner: not from the founding households, not the
## reeve, the sage or a guard (their posts come with a house), not a parent with young children at home.
static func _may_move(w: World, n: NPC) -> bool:
	if n.household < 3 or n.id == w.reeve_id or n.id == w.sage_id or n.job == "guard":
		return false
	for cid in n.children:
		var k := w.npc(int(cid))
		if k != null and k.alive and k.role == "child" and k.household == n.household:
			return false
	return true


## Why the player cannot be partners with this villager ("" if they can).
static func partner_refusal(w: World, n: NPC) -> String:
	var p := w.player
	var lo := float(cfg().partner_min_age)
	if not p.alive or p.partner >= 0 or is_player_id(p.partner):
		return "You already have a partner."
	if age_years(p.born, w.minutes) < lo:
		return "You are too young."
	if n.role != "adult" or npc_age(w, n) < lo:
		return "%s does not want that." % n.name
	if has_partner(w, n):
		return "%s is already spoken for." % n.name
	if kin(w.acting_id(), p.mother, p.father, n.id, n.mother, n.father) or p.children.has(n.id) or n.adoptive.has(w.acting_id()):
		return "%s is your kin." % n.name
	return ""


## The player and an unpartnered adult become partners (an explicit link both ways; the partner keeps their
## own home and household): the end of a proposal they accepted (Relations.propose). "" if made, else the reason.
static func partner_player(w: World, n: NPC) -> String:
	var why := partner_refusal(w, n)
	if why != "":
		return why
	w.player.partner = n.id
	n.partner = w.acting_id()                  # MP C5: a guest's partner names that guest's line
	kin_version += 1
	w.stat("partnerships")
	if w.recorder != null:
		w.recorder.partnered(w.player, n)      # REC-19
	w.note("%s %s and %s %s become partners." % [w.player.name, w.player.family, n.name, n.family])
	return ""


# ---------------------------------------------------------------- births ---------------------
## Births to partners: a woman of 18-42 with a living partner, food in the household and no child in the
## last `birth_min_gap_years`. No free bed is needed (owner, 2026-10-19): the crowding a baby causes is what
## sends a grown member out to found a household (Construction.crowded, EQ-08). The chance a day is 1 in
## `birth_interval_years` years of days. The child records both parents (the player is -2).
static func births(w: World) -> void:
	var c := cfg()
	var chance := 1.0 / (float(c.birth_interval_years) * year_days())
	for n: NPC in w.npcs.duplicate():
		if not n.alive or n.sex != "female" or n.role != "adult" or not has_partner(w, n):
			continue
		var father = w.player_of_id(n.partner) if is_player_id(n.partner) else w.npc(n.partner)
		if father != null and father.sex != n.sex:          # couples of one sex have no children (CRT-07)
			_try_birth(w, n, n.household, father, chance)
	for p: PlayerState in w.active_players():              # MP C5: every player in play (single player: the one)
		if p.alive and p.sex == "female" and p.partner >= 0:
			var o := w.npc(p.partner)
			if o != null and o.alive and o.partner == w.person_id(p) and o.sex != p.sex:
				_try_birth(w, p, o.household, o, chance)
		elif p.alive and p.sex == "female" and is_player_id(p.partner):
			# MP-PLAYER-FAMILY (owner, 2026-10-24): a woman married to a man who is a player (in play or away) has children by the same
			# rules (ages, food, interval, chance), raised in the couple's household; a couple of one sex never has (CRT-07)
			var q := w.player_of_id(p.partner)
			if q != null and q.alive and q.partner == w.person_id(p) and q.sex != p.sex:
				var h := couple_household(w, p, q)
				if h >= 0 and w.buildings.has(str(w.households[h].home)):
					_try_birth(w, p, h, q, chance)


static func _try_birth(w: World, mother, h: int, father, chance: float) -> bool:
	var c := cfg()
	var born_at: float = mother.born
	var age: float = age_years(born_at, w.minutes)
	if age < float(c.birth_mother_min_age) or age > float(c.birth_mother_max_age):
		return false
	if h < 0 or w.brain.household_food_days(h) < float(c.birth_min_food_days):
		return false
	for cid in mother.children:
		var k := w.npc(int(cid))
		if k != null and age_years(k.born, w.minutes) < float(c.birth_min_gap_years) and not k.adoptive.has(w.id_of_party(mother)):     # a child taken in is no birth
			return false
	if w.rng.randf() >= chance:
		return false
	birth(w, mother, father, h)
	return true


## Create a newborn villager of household `h`, recording the parents (NPC or PlayerState; either may be null).
static func birth(w: World, mother, father, h: int) -> NPC:
	var hh: Dictionary = w.households[h]
	var k := NPC.new()
	k.id = w.brain._next_npc_id()
	k.sex = "female" if w.rng.randf() < 0.5 else "male"
	var names: Array = Population.FIRST.filter(func(s: String) -> bool: return sex_of_name(s) == k.sex)
	k.name = names[w.rng.randi() % names.size()]
	k.family = str(hh.family)
	k.household = h
	k.home = str(hh.home)
	if not w.buildings.has(k.home):          # a household still building its house lodges: the baby lives with its parents (EQ-17)
		for p in [mother, father]:
			if p != null and w.buildings.has(str(p.home)):
				k.home = str(p.home)
				break
	k.role = "child"
	k.born = w.minutes
	k.hp = 15.0
	k.max_hp = 15.0
	k.hunger = 100.0
	k.pos = Vector2(w.building_door(k.home)) + Vector2(0.5, 0.5) if w.buildings.has(k.home) else (mother.pos if mother != null else w.player.pos)
	k.sprite = "res://assets/characters/villager_%02d.png" % (k.id % 48)
	_link_child(k, mother, father, w)
	hh.members.append(k.id)
	w.npcs.append(k)
	w.by_id[k.id] = k
	Identity.register_npc(w, k, "birth")
	w.stat("births")
	if w.recorder != null:
		w.recorder.birth(k, mother, father, h)      # REC-19
	var m_name: String = mother.name if mother != null else father.name
	w.note("A %s, %s, is born to %s." % ["girl" if k.sex == "female" else "boy", k.name, m_name])
	return k


# ---------------------------------------------------------------- player couples -------------
## MP-PLAYER-FAMILY (owner decisions 2026-10-24, docs/directives/2026-10-24_owner_decision_player_marriage_children.md; save 23):
## two married players have a household of their own, a household record like any other (World.households: family, home, members,
## pantry) with the key "couple": the two players' person ids (World.person_id), the host's line first (sorted high to low). Its
## members are villagers only, as in every household: the couple's children, born to them (births) or taken in (Guardianship.player_adopt).
## The players are not members (they are no villagers); while either of them lives (in play or away) the household is cared for: it is
## not orphaned (Guardianship.orphans), it does not end (Property._anyone_alive), and the village leaves its housing and lodging to the
## players (Construction.daily, newcomers and migrants never lodge there, no orphan is placed there but by kin). Its home is the
## couple's: the first of them with a home (sync_couple_homes, every dawn and on load). It is founded when the two marry
## (World.player_answer) and, for a couple married in a save of version 22, on load (ensure_couple_households). A couple without a
## home has no children (a newborn lives in its household's house; the household of a villager always has one or lodges).


## The two players' person ids as a couple key: [higher, lower] (the host's -2 first).
static func couple_key(w: World, a: PlayerState, b: PlayerState) -> Array:
	var ia := w.person_id(a)
	var ib := w.person_id(b)
	return [maxi(ia, ib), mini(ia, ib)]


## Whether household record `hh` is a player couple's.
static func is_couple(hh: Dictionary) -> bool:
	return hh.has("couple") and not hh.get("ended", false)


## Whether household `h` is a player couple's household (not ended).
static func is_couple_h(w: World, h: int) -> bool:
	return h >= 0 and h < w.households.size() and is_couple(w.households[h])


## The living players of a couple household (each a parent of its children), in the key's order.
static func couple_parents(w: World, h: int) -> Array:
	var out := []
	if not is_couple_h(w, h):
		return out
	for id in w.households[h].couple:
		var p: PlayerState = w.player_of_id(int(id)) if is_player_id(int(id)) else null
		if p != null and p.alive and not out.has(p):
			out.append(p)
	return out


## The household of the married players `a` and `b`, or -1.
static func couple_household(w: World, a: PlayerState, b: PlayerState) -> int:
	if a == null or b == null:
		return -1
	var key := couple_key(w, a, b)
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if is_couple(hh) and int(hh.couple[0]) == int(key[0]) and int(hh.couple[1]) == int(key[1]):
			return h
	return -1


## The couple's household, founded if they have none yet: the family name of the first of the key (the host's line first), the
## home of the first of them with one ("" while they have none), no members, an empty pantry. Returns its index.
static func found_couple_household(w: World, a: PlayerState, b: PlayerState) -> int:
	var h := couple_household(w, a, b)
	if h >= 0:
		return h
	var key := couple_key(w, a, b)
	var first: PlayerState = w.player_of_id(int(key[0]))
	var nh := {"id": w.households.size(), "family": first.family, "home": "", "members": [], "pantry": Inventory.new(), "couple": key,
		"founded_day": w.day()}
	w.households.append(nh)
	_sync_couple_home(w, int(nh.id))
	w.stat("couple_households")
	return int(nh.id)


## Every pair of living players married to each other has its household (save 22 had none; idempotent: a couple that has one keeps
## it). On load, and nothing at all in single player.
static func ensure_couple_households(w: World) -> int:
	var made := 0
	var list := w.player_list()
	for i in list.size():
		var a: PlayerState = list[i]
		if not a.alive or not is_player_id(a.partner):
			continue
		var b := w.player_of_id(a.partner)
		if b == null or b == a or not b.alive or b.partner != w.person_id(a) or list.find(b) < i:
			continue
		if couple_household(w, a, b) < 0:
			found_couple_household(w, a, b)
			made += 1
	return made


## Each couple household's home follows the couple: the first of them (the key's order) with a house of their own. While neither has
## one the children stay where they lived. Members who lived in the old home move with it.
static func sync_couple_homes(w: World) -> void:
	for h in w.households.size():
		if is_couple(w.households[h]):
			_sync_couple_home(w, h)


static func _sync_couple_home(w: World, h: int) -> void:
	var hh: Dictionary = w.households[h]
	for id in hh.couple:
		var p: PlayerState = w.player_of_id(int(id)) if is_player_id(int(id)) else null
		if p == null or not p.alive or str(p.home) == "" or not w.buildings.has(str(p.home)):
			continue
		if str(hh.home) != str(p.home):
			var was := str(hh.home)
			hh.home = str(p.home)
			for m in hh.members:
				var o := w.npc(int(m))
				if o != null and o.alive and (o.home == was or o.home == ""):
					o.home = str(p.home)
		return


## The parents of a person as person ids: mother and father (as born, -1 unknown), then the adoptive parents who took them in
## (MP-PLAYER-FAMILY: both spouses of a player couple).
static func parent_ids(n) -> Array:
	var out := [int(n.mother), int(n.father)]
	if n is NPC:
		for id in (n as NPC).adoptive:
			if not out.has(int(id)):
				out.append(int(id))
	return out


# ---------------------------------------------------------------- inheritance ----------------
## The family heir of a dead villager (owner order, 2026-10-19): the eldest adult child, then the partner, then
## other kin (parents, then siblings, eldest first), then a minor child; null when the family has no one alive
## (the household fallback in World._heir then applies).
static func heir_of(w: World, n: NPC) -> NPC:
	var kids := _alive(w, n.children)
	var adult_kids := kids.filter(func(o: NPC) -> bool: return o.role != "child")
	if not adult_kids.is_empty():
		return _eldest(adult_kids)
	if n.partner >= 0:
		var pr := w.npc(n.partner)
		if pr != null and pr.alive and pr.partner == n.id:
			return pr
	var others: Array = _alive(w, [n.mother, n.father])
	if not others.is_empty():
		return _eldest(others)
	var sibs: Array = []
	for pid in [n.mother, n.father]:
		var par := parent_of(w, int(pid)) if int(pid) != -1 else null
		if par != null:
			sibs.append_array(_alive(w, par.children))
	sibs = sibs.filter(func(o: NPC) -> bool: return o != n)
	if not sibs.is_empty():
		return _eldest(sibs)
	if not kids.is_empty():
		return _eldest(kids)
	return null


static func _alive(w: World, ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		var o := w.npc(int(id)) if int(id) >= 0 else null
		if o != null and o.alive and not out.has(o):
			out.append(o)
	return out


static func _eldest(list: Array) -> NPC:
	var best: NPC = null
	for o: NPC in list:
		if best == null or o.born < best.born or (o.born == best.born and o.id < best.id):
			best = o
	return best


## The player's eldest living child of 16 or more, or null (then the heir is a relative, as before).
static func player_heir_child(w: World) -> NPC:
	var cands := _alive(w, w.player.children).filter(func(o: NPC) -> bool: return npc_age(w, o) >= float(cfg().adolescent_until) and o.role != "bandit")
	return _eldest(cands) if not cands.is_empty() else null


## The child becomes the new player character: it leaves the village's people (what it carried is left at its
## home door), keeping its name, sprite, age and sex; the player's other children stay villagers.
static func make_heir(w: World, heir: PlayerState, kid: NPC, parent: PlayerState) -> void:
	heir.name = kid.name
	heir.sprite = kid.sprite
	heir.born = kid.born
	heir.sex = kid.sex
	heir.mother = kid.mother
	heir.father = kid.father
	kin_version += 1
	heir.look = ""
	heir.appearance = {}                   # CC-01: drawn from the child's own (baked) sheet
	if kid.household >= 0:
		(w.households[kid.household].members as Array).erase(kid.id)
	var bag := Inventory.new()
	for id in kid.inv.ids():
		bag.add(id, kid.inv.count(id))
	if bag.total() > 0 or kid.coins > 0:
		w.loot.append({"pos": kid.pos, "inv": bag, "coins": kid.coins, "from": kid.name})
	# ID-01: the child keeps their own permanent id and record (their history, ties and family links stay theirs, and the id is never
	# issued again); the record is a person who became the player, not a villager and not a body: empty-handed (what they carried is
	# in the loot above), not alive, drawn by nobody.
	kid.inv = Inventory.new()
	kid.coins = 0
	kid.plan.clear()
	kid.target = -1
	kid.alive = false
	kid.became_player = true
	w.stat("child_heirs")


## The player is about to be replaced by an heir: every link to "the player" (-2) now names an ancestor
## who is gone (-3), so the new player's own links never mix with their siblings'.
static func retire_player_id(w: World, dead: PlayerState = null) -> void:
	var line := w.person_id(dead) if dead != null else PLAYER_ID
	# MP C5: a guest's line retires to the dead character's own permanent id (ID-01: a person, now an ancestor, never a player again);
	# the host's line keeps the Build 18 rule (-3), so single player is unchanged
	var former := FORMER_PLAYER if line == PLAYER_ID else dead.pid
	for n: NPC in w.npcs:
		for k in ["mother", "father", "partner"]:
			if int(n.get(k)) == line:
				n.set(k, former)
	for q: PlayerState in w.player_list():         # MP-D8: a player partnered with the dead (two players' marriage)
		if q != dead and q.partner == line:
			q.partner = former
	for n: NPC in w.npcs:                          # MP-PLAYER-FAMILY: an adopted child's adoptive parent is the dead, as an ancestor
		for i in n.adoptive.size():
			if int(n.adoptive[i]) == line:
				n.adoptive[i] = former
	for hh in w.households:                        # and the couple's household names the dead as such (the heir is not the spouse)
		if hh.has("couple"):
			for i in (hh.couple as Array).size():
				if int(hh.couple[i]) == line:
					hh.couple[i] = former
