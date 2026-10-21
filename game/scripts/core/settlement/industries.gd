class_name SettlementIndustries
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-B; PROS-18, wip/expansion18-preparation): a settlement's capability per industry.
##
## Spec s.4: "Each settlement maintains an industry capability profile, derived from the actual capabilities of its
## residents and infrastructure." A level is DERIVED from a facts snapshot (SettlementFacts: living practitioners with
## their jobs and skills, goods held, structures, transport, records, portals, and the external mining level), never
## stored as truth and never a bonus: nothing here moves a coin or an item, and a level gives no villager a skill. A
## level holds when every need of it and of every level below it holds, so it falls as soon as one stops holding (the
## last smith dies, the forge is gone, the last hammer breaks). Data: res://data/settlement_industries.json
## (mml-capabilities/1, the SET-A schema sketched in Build 17's MIN_A_ARCHITECTURE.md s.9).
##
## Mining is "external": its level comes from MIN-D through MiningCapabilityAdapter (facts.external.mining) and is
## never computed here.

const PATH := "res://data/settlement_industries.json"
const FORMAT := "mml-capabilities/1"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _data


## Industry ids in evaluation order: every industry after the industries its needs name (ties by id).
static func order(d: Dictionary = {}) -> Array:
	if d.is_empty():
		d = data()
	var inds: Dictionary = d.industries
	var ids := inds.keys()
	ids.sort()
	var out := []
	var guard := 0
	while out.size() < ids.size() and guard <= ids.size():
		guard += 1
		for id in ids:
			if out.has(id):
				continue
			var ready := true
			for dep in deps(inds[id]):
				if not out.has(dep) and inds.has(dep):
					ready = false
			if ready:
				out.append(id)
	return out


## The industries an industry's needs name (through "industry" needs, also inside "any").
static func deps(ind: Dictionary) -> Array:
	var out := []
	for lv in ind.get("levels", []):
		for need in lv.needs:
			_need_deps(need, out)
	out.sort()
	return out


static func _need_deps(need: Dictionary, out: Array) -> void:
	if need.kind == "industry" and not out.has(str(need.id)):
		out.append(str(need.id))
	elif need.kind == "any":
		for sub in need.of:
			_need_deps(sub, out)


## Problems with the data (empty when valid): the format, unknown need kinds, levels out of order, references to
## unknown industries and cycles among industries.
static func validate(d: Dictionary) -> Array:
	var bad := []
	if str(d.get("format", "")) != FORMAT:
		bad.append("format is not " + FORMAT)
	var kinds: Array = d.get("need_kinds", [])
	var inds: Dictionary = d.get("industries", {})
	for id in inds:
		var ind: Dictionary = inds[id]
		if ind.has("external"):
			if int(ind.get("max_level", 0)) <= 0:
				bad.append("%s: external industry without max_level" % id)
			continue
		var n := 0
		for lv in ind.get("levels", []):
			n += 1
			if int(lv.level) != n:
				bad.append("%s: level %d out of order" % [id, int(lv.level)])
			for need in lv.needs:
				_check_need(id, need, kinds, inds, bad)
	if order(d).size() != inds.size():
		bad.append("a cycle among industries' needs")
	return bad


static func _check_need(id: String, need: Dictionary, kinds: Array, inds: Dictionary, bad: Array) -> void:
	if not kinds.has(need.get("kind", "")):
		bad.append("%s: unknown need kind %s" % [id, str(need.get("kind", ""))])
	elif need.kind == "industry" and not inds.has(str(need.get("id", ""))):
		bad.append("%s: needs unknown industry %s" % [id, str(need.get("id", ""))])
	elif need.kind == "any":
		for sub in need.get("of", []):
			_check_need(id, sub, kinds, inds, bad)


## Each industry's level for a facts snapshot: {industry: level}.
static func levels(facts: Dictionary, d: Dictionary = {}) -> Dictionary:
	return evaluate(facts, d).levels


## Levels plus the reasons each industry stops where it does: {levels: {id: n}, blocked: {id: [unmet need text]}}
## (spec s.11: causes traceable to real inputs).
static func evaluate(facts: Dictionary, d: Dictionary = {}) -> Dictionary:
	if d.is_empty():
		d = data()
	var inds: Dictionary = d.industries
	var lv := {}
	var blocked := {}
	for id in order(d):
		var ind: Dictionary = inds[id]
		if ind.has("external"):
			var ext: Dictionary = (facts.get("external", {}) as Dictionary).get(str(ind.external), {})
			lv[id] = clampi(int(ext.get("level", 0)), 0, int(ind.max_level))
			blocked[id] = [] if lv[id] > 0 else ["%s capability (%s)" % [id, str(ext.get("source", "none"))]]
			continue
		var level := 0
		var why := []
		for l in ind.levels:
			var unmet := []
			for need in l.needs:
				if not holds(need, facts, lv):
					unmet.append(describe(need))
			if not unmet.is_empty():
				why = unmet
				break
			level = int(l.level)
		lv[id] = level
		blocked[id] = why
	return {"levels": lv, "blocked": blocked}


## Whether one need holds for the facts and the levels found so far. The vocabulary is MIN-D's capabilities.json
## (practitioners {jobs | job, skill, min_level, count, as}, station {type}, structure {what}, transport {any: handcart |
## carry}, deposit_access {level}, records, portal) plus stock, industry and any.
static func holds(need: Dictionary, facts: Dictionary, lv: Dictionary) -> bool:
	match str(need.kind):
		"practitioners":
			var jobs: Array = need.get("jobs", [need.job] if need.has("job") else [])
			var c := 0
			for p in facts.get("practitioners", []):
				if not jobs.is_empty() and not jobs.has(str(p.job)):
					continue
				if need.has("skill") and int((p.get("skills", {}) as Dictionary).get(str(need.skill), 0)) < int(need.get("min_level", 1)):
					continue
				c += 1
			return c >= int(need.get("count", 1))
		"tool_stock":
			var tools: Dictionary = facts.get("tools", facts.get("stock", {}))
			return int(tools.get(str(need.tool), 0)) >= int(need.get("count", 1))
		"stock":
			return int((facts.get("stock", {}) as Dictionary).get(str(need.item), 0)) >= int(need.get("count", 1))
		"station":
			return int((facts.get("stations", {}) as Dictionary).get(str(need.type), 0)) >= int(need.get("count", 1))
		"structure":
			return int((facts.get("structures", {}) as Dictionary).get(str(need.what), 0)) >= int(need.get("count", 1))
		"transport":
			for m in need.any:
				if int((facts.get("transport", {}) as Dictionary).get(str(m), 0)) > 0:
					return true
			return false
		"deposit_access":
			return (facts.get("deposit_access", []) as Array).has(int(need.get("level", 0)))
		"records":
			return int((facts.get("records", {}) as Dictionary).get(str(need.what), 0)) >= int(need.get("count", 1))
		"portal":
			for depth in facts.get("portals", []):
				if int(depth) <= int(need.get("min_depth", -1)):
					return true
			return false
		"industry":
			return int(lv.get(str(need.id), 0)) >= int(need.min)
		"any":
			for sub in need.of:
				if holds(sub, facts, lv):
					return true
			return false
	return false


static func describe(need: Dictionary) -> String:
	match str(need.kind):
		"practitioners":
			var jobs: Array = need.get("jobs", [need.job] if need.has("job") else [])
			var who := str(need.as) if need.has("as") else ("/".join(jobs) if not jobs.is_empty() else "worker")
			if need.has("skill"):
				who += " with %s %d+" % [str(need.skill), int(need.get("min_level", 1))]
			return "%d %s" % [int(need.get("count", 1)), who]
		"tool_stock":
			return "%d %s" % [int(need.get("count", 1)), str(need.tool)]
		"stock":
			return "%d %s in store" % [int(need.get("count", 1)), str(need.item)]
		"station":
			return "%d %s" % [int(need.get("count", 1)), str(need.type)]
		"structure":
			return "%d %s" % [int(need.get("count", 1)), str(need.what)]
		"transport":
			return "transport: " + " or ".join(need.any)
		"deposit_access":
			return "ore to reach at level %d" % int(need.get("level", 0))
		"records":
			return "%d %s record" % [int(need.get("count", 1)), str(need.what)]
		"portal":
			return "a way down to depth %d" % int(need.get("min_depth", -1))
		"industry":
			return "%s level %d" % [str(need.id), int(need.min)]
		"any":
			return "(" + " or ".join(need.of.map(func(s): return describe(s))) + ")"
	return str(need)


## Specialization across settlements (spec s.4 "Settlement specialization", s.11 "different industry profiles"): for
## each settlement, its industries ranked by how far its level stands above the mean level of the other settlements
## (ties by industry id). Only industries above zero are listed. `profiles`: {settlement_id: {industry: level}}.
## Population plays no part: a small mining village outranks a larger farming town in mining.
static func specialization(profiles: Dictionary) -> Dictionary:
	var ids := profiles.keys()
	ids.sort()
	var inds := []
	for sid in ids:
		for k in profiles[sid]:
			if not inds.has(k):
				inds.append(k)
	inds.sort()
	var out := {}
	for sid in ids:
		var rows := []
		for k in inds:
			var mine := int((profiles[sid] as Dictionary).get(k, 0))
			if mine <= 0:
				continue
			var others := 0.0
			for o in ids:
				if o != sid:
					others += float((profiles[o] as Dictionary).get(k, 0))
			var mean := others / float(maxi(1, ids.size() - 1))
			rows.append({"industry": k, "level": mine, "lead": float(mine) - mean})
		rows.sort_custom(func(a, b): return a.lead > b.lead or (a.lead == b.lead and str(a.industry) < str(b.industry)))
		out[sid] = rows
	return out


## Q18-9 (owner, 2026-10-21): a level's only effects are on pay and production output, never permission. The factor an
## industry's level applies to its workers' pay, and to its output: data (effects.pay_factor / output_factor, a list
## indexed by level); 1.0 when the data names none (every factor is 1.0 until the owner sets them, Q18-11). Nothing in
## the settlement model refuses or blocks an activity because of a level.
static func pay_factor(industry: String, level: int) -> float:
	return _factor("pay_factor", industry, level)


static func output_factor(industry: String, level: int) -> float:
	return _factor("output_factor", industry, level)


static func _factor(which: String, industry: String, level: int) -> float:
	var e: Dictionary = data().get("effects", {})
	var row: Array = (e.get(which, {}) as Dictionary).get(industry, [])
	if row.is_empty():
		return float(e.get("default_factor", 1.0))
	return float(row[clampi(level, 0, row.size() - 1)])


## The industry whose output factor scales a good ("" if none).
static func industry_of(item: String) -> String:
	var outs: Dictionary = (data().get("effects", {}) as Dictionary).get("outputs", {})
	var ks := outs.keys()
	ks.sort()
	for k in ks:
		if (outs[k] as Array).has(item):
			return str(k)
	return ""


## The leader in one industry among settlements: the highest level, ties to the lower settlement id ("" if none has it).
static func leader(profiles: Dictionary, industry: String) -> String:
	var ids := profiles.keys()
	ids.sort()
	var best := ""
	var best_lv := 0
	for sid in ids:
		var l := int((profiles[sid] as Dictionary).get(industry, 0))
		if l > best_lv:
			best = sid
			best_lv = l
	return best


## The history a settlement keeps (the save keeps only this: last levels and the day each changed; spec "can regress").
## `state`: {levels: {id: n}, since: {id: day}, history: [{day, industry, from, to}]}; returns the changes made.
static func record(state: Dictionary, now_levels: Dictionary, day: int, keep := 40) -> Array:
	if not state.has("levels"):
		state.levels = {}
		state.since = {}
		state.history = []
	var changes := []
	var ids := now_levels.keys()
	ids.sort()
	for id in ids:
		var old := int(state.levels.get(id, 0))
		var now := int(now_levels[id])
		if not state.levels.has(id) or old != now:
			if state.levels.has(id) or now > 0:
				var ch := {"day": day, "industry": id, "from": old, "to": now}
				changes.append(ch)
				state.history.append(ch)
			state.levels[id] = now
			state.since[id] = day
	while state.history.size() > keep:
		state.history.pop_front()
	return changes
