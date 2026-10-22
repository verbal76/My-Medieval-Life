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
## - Caps (experience days): mining, forestry 12; farming, trade, tanning 18; carpentry, smithing 24 (`caps_days`).
## - Individual level = 10 x min(days, cap) / cap: straight-line, 0-10, real-valued. Each worker's own; nobody inherits
##   another's (a master beside an apprentice changes neither).
## - Workforce level of an industry: the hours-weighted average of the individual levels of the workers active in it in
##   the last season (`window_game_days`, 2 game days; active = any hours in the window). A REPORTING AND PLANNING metric
##   only, never applied to anyone's work or pay. With nobody active: "no active workers" (never 0).
## NOT DECIDED by the owner, so not here: starting experience (new worlds and old saves start empty), facility caps on
## the effective level, thresholds. Tracking starts empty and stays so until the starting-experience rule is approved.
##
## Hours come from the game's own work steps, mapped to industries as the capability hook maps them (`industry_of_step`):
## the mining swing, felling, a recipe by its station, the farm tasks the owner listed, the manor's quarrying (a mining
## swing) and mending. Everything else is unattributed (DESIGN.md section 9b lists the open cases).

const KEY := "x18_experience"              # optional save key: a save without it loads with empty tracking
const FORMAT := "mml-x18-experience/0"
const PLAYER := "player"

var minutes := {}      # person key -> {industry: minutes worked, ever, in this settlement}
var recent := {}       # game hour index -> {person key: {industry: minutes}} for the activity window
var foreign := {}      # a loaded section of an unknown format, kept untouched (tracking then records nothing)


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
	return PLAYER if who is PlayerState else World.npc_ref(int(who.id))


## The industry a work step belongs to, from what the game already knows; "" when it is none or not decided.
## `job_kind` answers a manor job's kind (mj_step) when given.
static func industry_of_step(act: String, args: Dictionary, job_kind := "") -> String:
	match act:
		"mine", "mj_mine":
			return "mining"
		"chop":
			return "forestry"
		"craft":
			return CapabilityHook.recipe_industry(str(args.get("recipe", "")))
		"harvest", "sow", "feed_pen", "collect_pen":
			return "farming"
		"fp_work":
			return "farming" if str(args.get("task", "")) in ["till", "sow", "harvest"] else ""
		"mj_step":
			return "carpentry" if job_kind == "mend" else ""
	return ""


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


## A worker's own level in an industry (0-10, real-valued).
func level(who_key: String, industry: String) -> float:
	return level_of_days(industry, days(who_key, industry))


## The person leaves the settlement (death, emigration): their experience goes with them.
func forget(who_key: String) -> void:
	minutes.erase(who_key)
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
	var tot := 0.0
	for k in ks:
		sum += float(w[k]) * level(str(k), industry)
		tot += float(w[k])
	return {"industry": industry, "active": ks.size(), "hours": tot / 60.0, "level": sum / tot, "status": "ok"}


## Save section (optional key): {} when nothing is recorded, so a world nobody has worked in saves as before.
func to_dict() -> Dictionary:
	if not foreign.is_empty():
		return foreign.duplicate(true)            # a section of a format this code does not know is kept, never reinterpreted
	if minutes.is_empty():
		return {}
	var r := {}
	for h in recent:
		r[str(h)] = (recent[h] as Dictionary).duplicate(true)
	return {"format": FORMAT, "minutes": minutes.duplicate(true), "recent": r}


func load_dict(d: Dictionary) -> void:
	minutes = {}
	recent = {}
	foreign = {}
	if d.is_empty():
		return
	if str(d.get("format", "")) != FORMAT:
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
