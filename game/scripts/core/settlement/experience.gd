class_name WorkExperience
extends RefCounted
## PROSPECTIVE (Expansion 18, X18-CAPCOMP part 1; owner decision 2026-10-22,
## docs/directives/2026-10-22_x18_capcomp_experience_decision.md): each person's industry experience, from the hours they
## actually work in that industry in this settlement. A RECORD ONLY: nothing in the game reads it to change behaviour
## (the capability hook stays off; CapabilityHook's per-worker path is prepared, not enabled).
##
## - Experience: 1 experience day per 8 game hours of work in an industry (`experience.minutes_per_day`, 480). It never
##   decays and is never reduced by facilities, other workers or time away; it leaves with the person (`forget`, at
##   death or departure: World prunes it at dawn).
## - Caps (experience days): mining, forestry 12; farming, trade, tanning 18; carpentry, masonry, smithing 24 (`caps_days`).
## - Individual level = 10 x min(days, cap) / cap: straight-line, 0-10, real-valued. Each worker's own; nobody inherits
##   another's (a master beside an apprentice changes neither).
## - Workforce level of an industry: the hours-weighted average of the individual levels of the workers active in it in
##   the last season (`window_game_days`, 2 game days; active = any hours in the window). A REPORTING AND PLANNING metric
##   only, never applied to anyone's work or pay. With nobody active: "no active workers" (never 0).
## Starting experience (owner D1, 2026-10-22, docs/directives/2026-10-22_x18_d1_starting_experience.md): once, for a
## new world and for a save that has no experience section, each villager's (adult or elder, as PAR-01A) experience days
## in an industry = cap x their recorded Skills level in the industry's skill / 10 (SKILL_OF), counted only where they
## hold xp in that skill (a level-1 floor with no xp is no recorded history: requirement 4); farming, which has no
## skill, from the PAR-01A working-history rule itself (farming_start_days). The player gets none (PAR-01A: "the player
## gets none"). Seeding never touches saved experience, adds no hours to the season's window (it is not recent work)
## and is marked done in the save (`seeded`); the days given are kept apart in `start` for the record.
## Owner D2/D3 (2026-10-23): effective level = experience level (no facility limit now; `wear_cap` is the seam for a
## later wear rule); no threshold on any level; bands novice / journeyman / master name levels for the player (`band`).
##
## Hours come from the game's own work steps, mapped to industries as the capability hook maps them (`industry_of_step`):
## the mining swing, felling, a recipe by its station, the farm tasks the owner listed, the manor's quarrying (a mining
## swing) and mending. Everything else is unattributed (DESIGN.md section 9b lists the open cases).

const KEY := "x18_experience"              # optional save key: a save without it loads with empty tracking
const FORMAT := "mml-x18-experience/1"     # 1: D1 starting experience (seeded, start); 0: records only (read, never seeded)
const FORMAT_0 := "mml-x18-experience/0"
## The skill whose recorded level gives an industry's starting experience (owner D1; farming has none: farming_start_days).
const SKILL_OF := {"mining": "mining", "forestry": "woodcutting", "smithing": "smithing", "carpentry": "carpentry",
	"masonry": "masonry", "tanning": "tanning", "trade": "trading"}
const PLAYER := "player"

var minutes := {}      # person key -> {industry: minutes worked, ever, in this settlement}
var recent := {}       # game hour index -> {person key: {industry: minutes}} for the activity window
var foreign := {}      # a loaded section of an unknown format, kept untouched (tracking then records nothing)
var seeded := false    # owner D1: the one-time starting experience has been given (never again)
var start := {}        # person key -> {industry: experience days given by D1}, for the record


static func cfg() -> Dictionary:
	return SettlementIndustries.data().get("experience", {})


static func cap_days(industry: String) -> float:
	return float((cfg().get("caps_days", {}) as Dictionary).get(industry, 0.0))


## The level of `days` of experience in `industry`: 10 x min(days, cap) / cap (0 for an industry without a cap).
static func level_of_days(industry: String, days: float) -> float:
	var cap := cap_days(industry)
	if cap <= 0.0:
		return 0.0
	return float(SettlementIndustries.max_level()) * minf(maxf(days, 0.0), cap) / cap


## The key a person is recorded under: "npc:<id>" (World.npc_ref), or "player".
static func key_of(who) -> String:
	if who is String:
		return who                                  # already a key ("player" or "npc:<id>", as the manor's job board names its takers)
	return PLAYER if who is PlayerState else World.npc_ref(int(who.id))


## The industry a work step belongs to, from what the game already knows; "" when it is none. Owner D4 (2026-10-23,
## docs/directives/2026-10-23_owner_answers_x18_d4_d9.md, "Use the table"): trade at a stall -> trade (the merchant's
## hours at the stall: a step carries `industry`, see World._note_work); slaughter, clearing ground, fencing farmland ->
## farming; survey, trial pits, excavation, tunnelling, shoring, backfill, service-contract digging -> mining;
## hunting, foraging, picking, building, hauling and carting -> none. `job_kind` answers a manor job's kind (mj_step).
## Agent decisions (docs/DECISIONS.md): the prospector's rock sampling (`prospect`) is survey work -> mining; assays and
## the manor's mending stay as they were (an assay none; mending carpentry, approved with the first mapping).
static func industry_of_step(act: String, args: Dictionary, job_kind := "") -> String:
	match act:
		"mine", "mj_mine", "prospect", "svc_step":
			return "mining"
		"chop":
			return "forestry"
		"craft":
			return CapabilityHook.recipe_industry(str(args.get("recipe", "")))
		"harvest", "sow", "feed_pen", "collect_pen", "slaughter", "fp_fence":
			return "farming"
		"fp_work":
			return "farming" if str(args.get("task", "")) in ["till", "sow", "harvest", "clear"] else ""
		"mj_step":
			if job_kind == "mend":
				return "carpentry"
			return "mining" if job_kind in ["survey", "trial", "excavate", "tunnel", "shore", "backfill"] else ""
	return ""


## Owner D3 (2026-10-23): no threshold attaches to the 0-10 levels (nothing is gated by a level); where a level reaches
## the player it is named by band. Ranges are an agent decision (docs/DECISIONS.md): novice below 3, journeyman 3 to
## below 7, master 7 and above (`experience.bands` in settlement_industries.json: [{name, below}] in order).
static func band(level: float) -> String:
	var bands: Array = cfg().get("bands", [])
	for b in bands:
		if level < float(b.below):
			return str(b.name)
	return str(bands[bands.size() - 1].name) if not bands.is_empty() else ""


## Record `mins` game minutes of work by `who_key` in `industry`, at game time `now` (minutes).
func credit(who_key: String, industry: String, mins: float, now: float) -> void:
	if industry == "" or mins <= 0.0 or not foreign.is_empty():
		return
	var m: Dictionary = minutes.get(who_key, {})
	m[industry] = float(m.get(industry, 0.0)) + mins
	minutes[who_key] = m
	var h := int(floor(now / 60.0))
	var b: Dictionary = recent.get(h, {})
	var bw: Dictionary = b.get(who_key, {})
	bw[industry] = float(bw.get(industry, 0.0)) + mins
	b[who_key] = bw
	recent[h] = b
	_trim(now)


func _trim(now: float) -> void:
	var oldest := int(floor(now / 60.0)) - int(round(window_minutes() / 60.0))
	for h in recent.keys():
		if int(h) < oldest:
			recent.erase(h)


static func window_minutes() -> float:
	return float(cfg().get("window_game_days", 2)) * 1440.0


func days(who_key: String, industry: String) -> float:
	return float((minutes.get(who_key, {}) as Dictionary).get(industry, 0.0)) / float(cfg().get("minutes_per_day", 480))


## A worker's own level in an industry (0-10, real-valued): their WORKFORCE (experience) level.
func level(who_key: String, industry: String) -> float:
	return level_of_days(industry, days(who_key, industry))


## The facility limit on effective capability in an industry, 0-10 (`facilities.caps`). Owner D2 (2026-10-23): no
## limit now, so with no cap given it is the top of the scale. See wear_cap for the later rule.
static func facility_cap(industry: String) -> float:
	var caps: Dictionary = (SettlementIndustries.data().get("facilities", {}) as Dictionary).get("caps", {})
	return clampf(float(caps.get(industry, SettlementIndustries.max_level())), 0.0, float(SettlementIndustries.max_level()))


## THE SEAM FOR A FUTURE WEAR CAP (owner D2, 2026-10-23: "No limit now; wear later"). When facilities gain a condition
## (worn or damaged stations), a worn facility caps the effective level of whoever works at it: change this one function
## to return that cap (0-10) for the industry (and the worker's station, `who_key`). Today nothing wears, so no limit.
## Experience itself is never touched by it: effective_level only reads it.
static func wear_cap(_industry: String, _who_key := "") -> float:
	return float(SettlementIndustries.max_level())


## A worker's EFFECTIVE level (owner Q18-11B, X18-CAPCOMP: each worker's own): their experience level within the
## facility limit (`cap`, or facility_cap). Kept apart from experience by structure: it is computed, never stored, and
## nothing here writes `minutes`, so a facility shortage can never erase experience.
func effective_level(who_key: String, industry: String, cap := -1.0) -> float:
	return minf(minf(level(who_key, industry), cap if cap >= 0.0 else facility_cap(industry)), wear_cap(industry, who_key))


## Owner D1: a person's starting experience days in `industry` from their recorded skill (0 without xp in it).
static func start_days(industry: String, who, w: World) -> float:
	if industry == "farming":
		return farming_start_days(who, w)
	var xp := int(who.skills.get(str(SKILL_OF.get(industry, "")), 0))
	if xp <= 0:
		return 0.0
	return cap_days(industry) * float(Skills.level_of(xp)) / 10.0


## Owner D1 farming sub-option (a): farming's start from the PAR-01A working-history rule, exactly as PAR-01A gives a
## trade skill (Skills.start_xp): a farmer's tenure = min(working years since skill_start.from_age x lerp(tenure_min, 1,
## Skills.tenure_share), max_tenure_years); xp = round(tenure x xp_per_year); level = Skills.level_of(xp) on the skills'
## own curve; days = cap x level / 10. Only for the farmer's trade (PAR-01A gives a trade's history to that trade only),
## no history beyond what PAR-01A defines, no new random draw (the share is PAR-01A's id-and-seed hash).
static func farming_start_days(who, w: World) -> float:
	if not who is NPC or (who as NPC).job != "farmer":
		return 0.0
	var c: Dictionary = GameData.b("skill_start")
	var working := maxf(0.0, Life.npc_age(w, who) - float(c.from_age))
	var tenure := minf(working * lerpf(float(c.tenure_min), 1.0, clampf(Skills.tenure_share(w, who), 0.0, 1.0)), float(c.max_tenure_years))
	var xp := roundi(tenure * float(c.xp_per_year))
	if xp <= 0:
		return 0.0
	return cap_days("farming") * float(Skills.level_of(xp)) / 10.0


## Owner D1: give the starting experience once. Does nothing when it was given before, when any experience is already
## recorded (never overwritten, reset or regenerated) or when the section is of a format this code does not read.
func seed_once(w: World) -> void:
	if seeded or not minutes.is_empty() or not foreign.is_empty():
		return
	var per_day := float(cfg().get("minutes_per_day", 480))
	var inds: Array = (cfg().get("caps_days", {}) as Dictionary).keys()
	inds.sort()
	for n: NPC in w.npcs:
		if not n.alive or not n.role in ["adult", "elder"]:
			continue
		var k := World.npc_ref(n.id)
		for ind in inds:
			var dd := start_days(str(ind), n, w)
			if dd <= 0.0:
				continue
			var m: Dictionary = minutes.get(k, {})
			m[str(ind)] = dd * per_day
			minutes[k] = m
			var st: Dictionary = start.get(k, {})
			st[str(ind)] = dd
			start[k] = st
	seeded = true


## The person leaves the settlement (death, emigration): their experience goes with them.
func forget(who_key: String) -> void:
	minutes.erase(who_key)
	start.erase(who_key)
	for h in recent:
		(recent[h] as Dictionary).erase(who_key)


## The industry's workforce level at game time `now`: {active, hours, level} with level the hours-weighted average of the
## active workers' own levels; {active: 0, status: "no active workers"} with none (never a level of 0).
func workforce(industry: String, now: float) -> Dictionary:
	var oldest := int(floor(now / 60.0)) - int(round(window_minutes() / 60.0))
	var w := {}
	var hs := recent.keys()
	hs.sort()
	for h in hs:
		if int(h) < oldest:
			continue
		var b: Dictionary = recent[h]
		for k in b:
			var mins := float((b[k] as Dictionary).get(industry, 0.0))
			if mins > 0.0:
				w[k] = float(w.get(k, 0.0)) + mins
	if w.is_empty():
		return {"industry": industry, "active": 0, "status": "no active workers"}
	var ks := w.keys()
	ks.sort()
	var sum := 0.0
	var eff := 0.0
	var tot := 0.0
	for k in ks:
		sum += float(w[k]) * level(str(k), industry)
		eff += float(w[k]) * effective_level(str(k), industry)
		tot += float(w[k])
	return {"industry": industry, "active": ks.size(), "hours": tot / 60.0, "level": sum / tot, "effective": eff / tot, "band": band(eff / tot), "status": "ok"}


## Save section (optional key): {} when nothing is recorded, so a world nobody has worked in saves as before.
func to_dict() -> Dictionary:
	if not foreign.is_empty():
		return foreign.duplicate(true)            # a section of a format this code does not know is kept, never reinterpreted
	if minutes.is_empty() and not seeded:
		return {}
	var r := {}
	for h in recent:
		r[str(h)] = (recent[h] as Dictionary).duplicate(true)
	return {"format": FORMAT, "seeded": seeded, "start": start.duplicate(true), "minutes": minutes.duplicate(true), "recent": r}


func load_dict(d: Dictionary) -> void:
	minutes = {}
	recent = {}
	foreign = {}
	seeded = false
	start = {}
	if d.is_empty():
		return
	if not str(d.get("format", "")) in [FORMAT, FORMAT_0]:
		foreign = d.duplicate(true)               # unknown format: kept as it is and written back, not read, never dropped
		return
	for k in d.get("minutes", {}):
		var m := {}
		for ind in d.minutes[k]:
			m[str(ind)] = float(d.minutes[k][ind])
		minutes[str(k)] = m
	for h in d.get("recent", {}):
		var b := {}
		for k in d.recent[h]:
			var bw := {}
			for ind in d.recent[h][k]:
				bw[str(ind)] = float(d.recent[h][k][ind])
			b[str(k)] = bw
		recent[int(h)] = b
	seeded = bool(d.get("seeded", false))
	for k in d.get("start", {}):
		var st := {}
		for ind in d.start[k]:
			st[str(ind)] = float(d.start[k][ind])
		start[str(k)] = st
