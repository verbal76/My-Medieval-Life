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
## State (World.settlement_caps): {levels: {industry: n}, since: {industry: day}, history: [{day, industry, from, to}]}.
## Snapshot (World.settlement_profile, not saved): {day, industries: {industry: {level, effective, workforce: {...}}},
## blocked: {industry: [unmet]}}.


## Recompute at `day`; returns the snapshot and records level changes into `state` (a state without levels is
## initialised silently from the world: a save from before this system has no history to invent).
static func update(w: World, state: Dictionary, day: int) -> Dictionary:
	var facts := SettlementFacts.from_world(w)
	var ev := SettlementIndustries.evaluate(facts)
	if not state.has("levels") or (state.levels as Dictionary).is_empty():
		state.levels = ev.levels.duplicate()
		var since := {}
		for id in ev.levels:
			since[id] = day
		state.since = since
		state.history = []
	else:
		SettlementIndustries.record(state, ev.levels, day)
	var inds := {}
	var ids: Array = ev.levels.keys()
	ids.sort()
	for id in ids:
		var wf: Dictionary = w.experience.workforce(str(id), w.minutes)
		inds[id] = {"level": int(ev.levels[id]), "effective": minf(float(ev.levels[id]), WorkExperience.facility_cap(str(id))),
			"workforce": wf}
	return {"day": day, "industries": inds, "blocked": ev.blocked}


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
