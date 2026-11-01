class_name SettlementProfile
extends RefCounted
## Expansion 18 (SET-A, SET-B; X18-CAPCOMP, X18-CAPNUM): the village's all-industry capability profile, MAINTAINED. Each
## dawn World._new_day calls update(): it recomputes, from the existing capability code (SettlementFacts.from_world +
## SettlementIndustries.evaluate, as SettlementReport reads them), the settlement's level in every industry, its
## EFFECTIVE level (the level within the facility limit, WorkExperience.facility_cap) and each industry's WORKFORCE
## level (WorkExperience.workforce), and keeps the level history (SettlementIndustries.record: last levels, the day each
## changed, the falls). The history is saved by SettlementSave under the optional key "x18_settlements" (no version bump);
## everything else is derived from the world and the saved experience record, so an old save derives it on load.
##
## A record and a planning metric only: it changes nobody's level, work or pay. The pay and output hooks (CapabilityHook)
## keep reading each worker's own EFFECTIVE level from WorkExperience, which the facility limit applies to and nothing
## here writes: a facility shortage lowers `effective` here, never the workforce experience (X18-CAPCOMP).
## Farming progression is not modelled (its numbers are not approved).
##
## State (World.settlement_caps): {levels: {industry: n}, since: {industry: day}, history: [{day, industry, from, to}],
## milestones: {industry: {"<level>": day first reached}}}.
## Snapshot (World.settlement_profile, not saved): {day, industries: {industry: {level, effective, workforce: {...}}},
## blocked: {industry: [unmet]}, reached: [{industry, level}] (milestones first reached at this update)}.
##
## B25-CAPABILITY (owner Decision 8, 2026-11-01, docs/directives/2026-11-01_nine_owner_decisions_consolidated.md):
## MILESTONES are kept apart from the current level. `levels` is today's operational capability and falls when people,
## facilities or resources are lost; `milestones` records the day each level of each industry was FIRST reached and never
## falls. A level is a new milestone only when it is above every level that industry has ever reached, so a level that
## falls and comes back (a tool broken and replaced, a miner away a day) is never announced again: the record is the
## hysteresis. Milestones a world already had when it was made, or that an older save already shows (its current levels and
## its saved level history), are recorded silently (`reached` lists only real new achievements). The record is presentation
## history: nothing in the simulation reads it, it changes no level, work, pay, coin or item.


## Recompute at `day`; returns the snapshot and records level changes into `state` (a state without levels is
## initialised silently from the world: a save from before this system has no history to invent).
static func update(w: World, state: Dictionary, day: int) -> Dictionary:
	var facts := SettlementFacts.from_world(w)
	var ev := SettlementIndustries.evaluate(facts)
	var reached := []
	if not state.has("levels") or (state.levels as Dictionary).is_empty():
		state.levels = ev.levels.duplicate()
		var since := {}
		for id in ev.levels:
			since[id] = day
		state.since = since
		state.history = []
		seed_milestones(state, day)
	else:
		if not state.has("milestones"):
			seed_milestones(state, -1)            # an older save: what it already shows is history, not news
		SettlementIndustries.record(state, ev.levels, day)
		reached = note_milestones(state, ev.levels, day)
	var inds := {}
	var ids: Array = ev.levels.keys()
	ids.sort()
	for id in ids:
		var wf: Dictionary = w.experience.workforce(str(id), w.minutes)
		inds[id] = {"level": int(ev.levels[id]), "effective": minf(float(ev.levels[id]), WorkExperience.facility_cap(str(id))),
			"workforce": wf}
	return {"day": day, "industries": inds, "blocked": ev.blocked, "reached": reached}


## The highest level `industry` has ever reached by the record (0 for none).
static func best(state: Dictionary, industry: String) -> int:
	var b := 0
	for k in (state.get("milestones", {}) as Dictionary).get(industry, {}):
		b = maxi(b, int(k))
	return b


## Record silently every level the state already shows: its current levels and every level its saved history reached, each
## at the first day the history shows it, else `day` (-1: before the record began).
static func seed_milestones(state: Dictionary, day: int) -> void:
	var top := {}
	for id in state.get("levels", {}):
		top[str(id)] = int(state.levels[id])
	for e in state.get("history", []):
		top[str(e.industry)] = maxi(int(top.get(str(e.industry), 0)), int(e.to))
	var ids := top.keys()
	ids.sort()
	var ms := {}
	for id in ids:
		var m := {}
		for l in range(1, int(top[id]) + 1):
			var first := day
			for e in state.get("history", []):
				if str(e.industry) == str(id) and int(e.to) >= l:
					first = int(e.day)
					break
			m[str(l)] = first
		if not m.is_empty():
			ms[id] = m
	state.milestones = ms


## Record the levels of `now_levels` above each industry's best ever as milestones reached on `day`; returns the new ones,
## [{industry, level}] in industry order (a rise of two levels records both and is announced once, at the higher).
static func note_milestones(state: Dictionary, now_levels: Dictionary, day: int) -> Array:
	var out := []
	var ids := now_levels.keys()
	ids.sort()
	for id in ids:
		var b := best(state, str(id))
		var now := int(now_levels[id])
		if now <= b:
			continue
		var m: Dictionary = (state.milestones as Dictionary).get(id, {})
		for l in range(b + 1, now + 1):
			m[str(l)] = day
		state.milestones[id] = m
		out.append({"industry": str(id), "level": now})
	return out


## The words of a village milestone (owner Decision 8's example): "Village Development: Mining Capability Level 2 Reached."
static func milestone_text(industry: String, level: int) -> String:
	var ind: Dictionary = (SettlementIndustries.data().industries as Dictionary).get(industry, {})
	return "Village Development: %s Capability Level %d Reached." % [str(ind.get("name", industry.capitalize())), level]


## Save: the state into the save dictionary under SettlementSave.KEY.
static func attach(save: Dictionary, state: Dictionary, day: int) -> void:
	if (state.get("levels", {}) as Dictionary).is_empty():
		return
	var s := SettlementSave.default_state()
	s.capabilities = {SettlementFacts.VILLAGE: state.duplicate(true)}
	s.day = day
	SettlementSave.attach(save, s)


## Load: {state, foreign}. A save without the section gives an empty state (derived at the first update); a section of
## an unknown format is kept as it is in `foreign` and written back, never reinterpreted.
static func extract(save: Dictionary) -> Dictionary:
	var s := SettlementSave.extract(save)
	if s.has("error"):
		return {"state": {}, "foreign": save.get(SettlementSave.KEY)}
	return {"state": ((s.capabilities as Dictionary).get(SettlementFacts.VILLAGE, {}) as Dictionary).duplicate(true), "foreign": null}
