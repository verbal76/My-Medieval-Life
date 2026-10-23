class_name JudgmentWeighting
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19; spec s.7, gate SJD-D): how judgment enters a choice. This is NOT a second NPC
## decision engine: the live decision code (NPCBrain and the systems it calls) still decides what an NPC may do and
## which candidates are feasible; it hands the feasible candidates here with their factor values and gets back a
## ranking and an explanation. Judgment is one weighted factor ("disposition") beside need, scarcity, price and
## urgency, so it influences the choice and never dictates it (owner, PROS-01: "an NPC with a strongly negative
## judgment of another character may still trade with that character when their need for iron outweighs the negative
## opinion"). An infeasible candidate is never chosen, whatever anyone thinks of it (spec invariant 5; s.20 "positive
## judgment never overrides feasibility").
##
## Factor values are milli-points on the spec's 0..100 scale (0..100000); weights are permille (judgment.json
## decision.profiles). utility = sum(weight x value) / 1000. A profile's forgo is the utility of doing without: an
## action must beat it. Selection: argmax, ties to the earliest candidate (the live code's own order of preference),
## or "margin", a seeded pick among those within `margin` of the best (SJD-Q09; no World.rng).


## Rank `candidates` for `chooser` under profile `profile` and choose. Each candidate: {id, counterparty (-1 none),
## feasible (default true), why (when not), factors: {name: 0..100000}}. Factors the profile weighs but a candidate
## does not give: disposition and ambivalence come from `store` (the chooser's judgment of the counterparty; neutral
## 50 with no store or no counterparty), sole_source is 100 points divided by the number of feasible candidates with
## a counterparty; any other is 0. `key` makes a margin pick reproducible (the decision's identity: day, item...).
## Returns {chosen: id, or "forgo", or null when nothing is feasible and there is no forgo, utility, trace: [...]}.
static func choose(store: JudgmentStore, cfg: Dictionary, chooser: int, profile: String, candidates: Array, key: Array = []) -> Dictionary:
	var dc: Dictionary = cfg.decision
	var prof: Dictionary = dc.profiles[profile]
	var weights: Dictionary = prof.weights
	var feasible := 0
	for cand in candidates:
		if bool(cand.get("feasible", true)) and int(cand.get("counterparty", -1)) != -1:
			feasible += 1
	var trace := []
	var best = null
	var best_u := 0
	var scored := []
	for cand in candidates:
		var row := {"id": cand.id, "counterparty": int(cand.get("counterparty", -1)), "feasible": bool(cand.get("feasible", true))}
		if not row.feasible:
			row.why = str(cand.get("why", "not feasible"))
			trace.append(row)
			continue
		var f: Dictionary = (cand.get("factors", {}) as Dictionary).duplicate()
		var cp := int(row.counterparty)
		if weights.has("disposition") and not f.has("disposition"):
			f.disposition = store.disposition(chooser, cp) if store != null and cp != -1 else int(dc.disposition_mid)
		if weights.has("ambivalence") and not f.has("ambivalence"):
			f.ambivalence = store.ambivalence(chooser, cp) if store != null and cp != -1 else 0
		if weights.has("sole_source") and not f.has("sole_source"):
			f.sole_source = 100000 / maxi(1, feasible) if cp != -1 else 0
		var parts := {}
		var u := 0
		var names := weights.keys()
		names.sort()
		for name in names:
			var wgt := trait_weight(cfg, store.world_seed if store != null else 0, chooser, str(name), int(weights[name]), store)
			var part := JudgmentMath.mul_div(wgt, JudgmentMath.clampi_(int(f.get(name, 0)), 0, 100000), 1000)
			parts[name] = part
			u += part
		row.factors = f
		row.contributions = parts
		row.utility = u
		trace.append(row)
		scored.append([u, cand.id])
		if best == null or u > best_u:
			best = cand.id
			best_u = u
	var forgo := int(prof.get("forgo", 0))
	if forgo > 0:
		trace.append({"id": "forgo", "feasible": true, "utility": forgo})
		if best == null or forgo > best_u:
			return {"chosen": "forgo", "utility": forgo, "trace": trace, "policy": "forgo"}
	if best == null:
		return {"chosen": null, "utility": 0, "trace": trace, "policy": "none feasible"}
	var policy := str(dc.selection)
	if policy == "margin":
		var near := []
		for s in scored:
			if int(s[0]) >= best_u - int(dc.margin):
				near.append(s[1])
		var seed_ := store.world_seed if store != null else 0
		if dc.has("runner_up_permille"):
			# SJD-Q09 "sometimes near-best": usually the best; with the seeded chance runner_up_permille, one of the other
			# options within the margin (chosen by a second seeded hash). Same inputs, same pick.
			near.erase(best)
			if not near.is_empty() and JudgmentMath.hash_ints([seed_, chooser, 7919] + key) % 1000 < int(dc.runner_up_permille):
				best = near[JudgmentMath.hash_ints([seed_, chooser] + key) % near.size()]
		elif near.size() > 1:
			var r := JudgmentMath.hash_ints([seed_, chooser] + key) % near.size()
			best = near[r]
		if best != null:
			for s in scored:
				if s[1] == best:
					best_u = int(s[0])
	return {"chosen": best, "utility": best_u, "trace": trace, "policy": policy}


## A factor's weight for this person (SJD-Q03, Q13): the profile's, moved by up to trait_spread_permille either way by a
## seeded hash of the person and the factor (0: everyone weighs alike).
## Then, for the disposition factor, moved by what life has done to them (store.weight_shift: SJD-Q13, bounded).
static func trait_weight(cfg: Dictionary, seed: int, person: int, factor: String, w: int, store: JudgmentStore = null) -> int:
	var spread := int(cfg.decision.get("trait_spread_permille", 0))
	var r := 0
	if spread > 0:
		r = JudgmentMath.hash_ints([seed, person, factor.hash()]) % (2 * spread + 1) - spread
	if store != null and factor == "disposition":
		r += store.weight_shift(person)
	if r == 0:
		return w
	return JudgmentMath.scale(w, JudgmentMath.ONE + r)


## A decision trace as readable lines (spec s.14 "Why did John buy iron despite -6.59?").
static func explain(result: Dictionary) -> String:
	var lines := []
	for row in result.trace:
		if not bool(row.get("feasible", true)):
			lines.append("%s: not feasible (%s)" % [str(row.id), str(row.get("why", ""))])
			continue
		var bits := []
		for k in (row.get("contributions", {}) as Dictionary):
			bits.append("%s %s" % [k, JudgmentMath.pts(int(row.contributions[k]))])
		lines.append("%s: %s%s" % [str(row.id), JudgmentMath.pts(int(row.utility)), (" = " + " + ".join(bits)) if not bits.is_empty() else ""])
	lines.append("chosen: %s (%s)" % [str(result.chosen), str(result.policy)])
	return "\n".join(lines)
