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
##
## Build 19 (Expansion 19 complete): two more things enter beside the factors, both recorded in the trace.
##   - The family name colours the disposition (JudgmentStore.colour: the inherited impression, capped at a quarter of the
##     chooser's strongest personal judgment). It only colours: when the result is a refusal (forgo) that the personal
##     judgment alone would not have made, the choice is made again without the colour (X19-BOND-LIMITS: inherited
##     reputation alone can never cause a refusal).
##   - SJD-H C1 (owner 2026-10-31): the disposition factor is the chooser's opinion read with decision.opinion_gain_permille
##     (opinion()): 50 + gain x NET, so an opinion of a point or two (what the approved severities and decay give) is felt in a
##     choice; the store's disposition stays the spec's 50 + NET.
##   - SJD-H C5 (mixed feelings): the factors trust, fear, loyalty and ambivalence are read apart from the opinion (fill()), each
##     weighed by its own per-person weight, so dislike, fear, dependence, loyalty, respect and remembered help or harm compete
##     and are never collapsed into one score. A negative weight counts against an option.
##   - Tiers (C1): a candidate may carry "tier": the live rule cannot tell the candidates of one tier apart, so the caller
##     gives them the same live_order, and of those of one tier with identical factors (and stubbornness penalty) only the
##     first is weighed: the live rule's pick among equals stands, and judgment decides between comparable options.
##   - Stubbornness (a holder only, X19-PERS-FORMULA): a penalty on every option that means dealing with someone the chooser
##     resents or giving up the choice they made last time in this decision, scaled stubbornness x (1 - wisdom of this
##     kind); while angry enough for the stubborn override the penalties are decisive.
static func choose(store: JudgmentStore, cfg: Dictionary, chooser: int, profile: String, candidates: Array, key: Array = []) -> Dictionary:
	var r := _choose(store, cfg, chooser, profile, candidates, key, true)
	if store != null and bool(r.get("coloured", false)) and str(r.chosen) == "forgo":
		var r2 := _choose(store, cfg, chooser, profile, candidates, key, false)
		if r2.chosen != null and str(r2.chosen) != "forgo":
			r2.policy = "the family name alone cannot refuse"
			r2.colour_blocked = true
			store._stat("colour_refusal_blocked")
			r = r2
	if store != null and bool(r.get("stubborn", false)):
		store.remember_choice(chooser, str(r.dkey), str(r.token))
	if store != null and store.rec != null:
		store.rec.judgment_choice(chooser, profile, key, r)     # REC-19 D5 / REC-STORE: every alternative and factor, in full
	return r


static func _choose(store: JudgmentStore, cfg: Dictionary, chooser: int, profile: String, candidates: Array, key: Array, with_colour: bool) -> Dictionary:
	var dc: Dictionary = cfg.decision
	var prof: Dictionary = dc.profiles[profile]
	var weights: Dictionary = prof.weights
	# R5 aspirations (WDR-011-C; off by default): with the layer on, the yes-or-forgo profiles gain the one "aspiration" factor
	# and court_choice its courting factors (judgment.json aspiration); profiles with scaled_by (job_choice skill and growth,
	# the courting factors) scale those weights by the chooser's effective priority of a domain. Off: nothing here runs, the
	# weights and the trace are exactly as before. Never a family_* profile (FAMILY-01 stays the rule it is).
	var asp: JudgmentAspiration = store.asp if store != null and store.asp != null and store.asp.enabled else null
	var scaled: Dictionary = {}
	if asp != null:
		var fw: Dictionary = asp.c.get("factor_weights", {})
		if fw.has(profile):
			weights = weights.duplicate()
			weights["aspiration"] = int(fw[profile])
		elif profile == "court_choice" or profile == "proposal_accept":      # whom to court, and (WDR-011-Q8 A) whether to accept
			weights = (((asp.c.get("court", {}) as Dictionary).get("weights", {})) as Dictionary).duplicate()
			scaled = ((asp.c.get("court", {}) as Dictionary).get("scaled_by", {}) as Dictionary)
		if prof.has("scaled_by"):
			scaled = prof.scaled_by
	var feasible := 0
	var only_cp := 0
	var real := 0
	for cand in candidates:
		if bool(cand.get("feasible", true)):
			var cpx := int(cand.get("counterparty", -1))
			if cpx != -1:
				feasible += 1
			real += 1
			only_cp = cpx
	# stubbornness (holders only): how heavily it weighs here, and what the chooser did last time in this decision
	var sw := 0
	var pen: Array = [0, 0, 0]
	var last := ""
	var dkey := ""
	var overriding := false
	if store != null and store.pers.active:
		var nm := store.now_minute()
		sw = store.pers.stubborn_weight(chooser, profile, nm / 1440, nm % 1440)
		overriding = store.pers.overriding(chooser, nm / 1440, nm % 1440)
		if sw > 0 or overriding:
			pen = store.pers.penalties()
			dkey = str(JudgmentMath.hash_ints([profile.hash(), only_cp if real == 1 else 0]))
			last = store.last_token(chooser, dkey)
	var trace := []
	var best = null
	var best_u := 0
	var scored := []
	var tokens := {}
	var coloured := false
	var tiered := {}                       # a tier's signature -> the first candidate weighed with it
	for cand in candidates:
		var row := {"id": cand.id, "counterparty": int(cand.get("counterparty", -1)), "feasible": bool(cand.get("feasible", true))}
		if not row.feasible:
			row.why = str(cand.get("why", "not feasible"))
			trace.append(row)
			continue
		var f: Dictionary = (cand.get("factors", {}) as Dictionary).duplicate()
		var cp := int(row.counterparty)
		var col := _fill(store, cfg, profile, weights, chooser, cp, f, with_colour)
		if col != 0:
			row.colour = col
			coloured = coloured or col < 0
		if weights.has("sole_source") and not f.has("sole_source"):
			f.sole_source = 100000 / maxi(1, feasible) if cp != -1 else 0
		if asp != null and weights.has("aspiration") and not f.has("aspiration"):
			var af := asp.factor(chooser, profile, cand.get("serves", null), store.world)
			f.aspiration = int(af.value)
			row.aspiration = af                 # the leading domain, its pressure, the fit and the survival level (recorder)
		var parts := {}
		var u := 0
		var names := weights.keys()
		names.sort()
		for name in names:
			var wgt := trait_weight(cfg, store.world_seed if store != null else 0, chooser, str(name), int(weights[name]), store)
			if asp != null and scaled.has(name):
				var mult := asp.scale_for(chooser, JudgmentAspiration.DOMAINS.find(str(scaled[name])), store.world)
				wgt = JudgmentMath.mul_div(wgt, mult, 1000)
				if not row.has("scale"):
					row.scale = {}
				row.scale[name] = mult               # the priority multiplier applied to this weight (recorder)
			var part := JudgmentMath.mul_div(wgt, JudgmentMath.clampi_(int(f.get(name, 0)), 0, 100000), 1000)
			parts[name] = part
			u += part
		var tok := str(cp) if cp != -1 else str(cand.id)
		tokens[cand.id] = tok
		var st_total := 0
		if sw > 0 or overriding:
			var st := _stubborn_penalty(store, chooser, cp, tok, last, sw, overriding, pen)
			if st.total > 0:
				u -= int(st.total)
				row.stubborn = st
				st_total = int(st.total)
		if cand.has("tier"):
			var sig := _signature(cand.tier, f, st_total, weights)
			if tiered.has(sig):
				row.why = "indistinguishable from %s" % str(tiered[sig])     # the live rule's pick among equals stands
				row.collapsed = true
				row.factors = f                    # recorded as weighed (REC-STORE): it scored as the one it equals, it just does not compete
				row.contributions = parts
				row.utility = u
				trace.append(row)
				if store != null:
					store._stat("tier_collapsed")
				continue
			tiered[sig] = cand.id
		row.factors = f
		row.contributions = parts
		row.utility = u
		trace.append(row)
		scored.append([u, cand.id])
		if best == null or u > best_u:
			best = cand.id
			best_u = u
	var forgo := int(prof.get("forgo", 0))
	var result := {}
	if forgo > 0:
		var fu := forgo
		var asp_off := 0
		if asp != null and weights.has("aspiration"):
			# neutral = off: doing without is credited the factor's midpoint at this person's weight, so a neutral aspiration
			# (content, or a domain this choice does not bear on) changes no answer
			asp_off = JudgmentMath.mul_div(trait_weight(cfg, store.world_seed, chooser, "aspiration", int(weights.aspiration), store), int(dc.disposition_mid), 1000)
			fu += asp_off
		if sw > 0 or overriding:
			var sf := _stubborn_penalty(store, chooser, -1, "forgo", last, sw, overriding, pen)
			fu -= int(sf.total)
		var frow := {"id": "forgo", "feasible": true, "utility": fu}
		if asp_off != 0:
			frow.forgo_aspiration_offset = asp_off
		trace.append(frow)
		if best == null or fu > best_u:
			result = {"chosen": "forgo", "utility": fu, "trace": trace, "policy": "forgo"}
	if result.is_empty() and best == null:
		result = {"chosen": null, "utility": 0, "trace": trace, "policy": "none feasible"}
	if result.is_empty():
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
				var rr := JudgmentMath.hash_ints([seed_, chooser] + key) % near.size()
				best = near[rr]
			if best != null:
				for s in scored:
					if s[1] == best:
						best_u = int(s[0])
		result = {"chosen": best, "utility": best_u, "trace": trace, "policy": policy}
	result.coloured = coloured
	if sw > 0 or overriding:
		result.stubborn = true
		result.dkey = dkey
		result.token = "forgo" if str(result.chosen) == "forgo" else str(tokens.get(result.chosen, ""))
	return result


## The stubbornness penalty of one option (milli-points): dealing with someone resented (resentment above 0), and giving up
## the choice made last time (`tok` differs from `last`), each scaled by `sw` (stubbornness x (1 - wisdom), permille);
## under the stubborn override both are decisive (the override penalty, unscaled).
static func _stubborn_penalty(store: JudgmentStore, chooser: int, cp: int, tok: String, last: String, sw: int, overriding: bool, pen: Array) -> Dictionary:
	var resent := 0
	var swit := 0
	var ovr := 0
	var resented := cp != -1 and store.bonds.resentment(chooser, cp) > 0
	if resented:
		resent = JudgmentMath.mul_div(int(pen[0]), sw, 1000)
		if overriding:
			ovr += int(pen[2])
	if last != "" and tok != last:
		swit = JudgmentMath.mul_div(int(pen[1]), sw, 1000)
		if overriding:
			ovr += int(pen[2])
	return {"resent": resent, "switch": swit, "override": ovr, "total": resent + swit + ovr}


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


## The chooser's opinion of `cp` as a decision reads it (C1): [factor milli-points, the family name's colour as applied].
## The store's personal disposition (50 + NET, spec s.7.3) has its distance from neutral multiplied by the opinion gain
## (decision.opinion_gain_permille, or the profile's own) and is clamped to 0..100 points; then the family name's colour,
## multiplied by the same gain, is added and clamped again (as the choice always has: personal, then colour). Neutral (no
## opinion) is exactly 50 points whatever the gain.
static func opinion(store: JudgmentStore, cfg: Dictionary, profile: String, chooser: int, cp: int, with_colour := true) -> Array:
	var dc: Dictionary = cfg.decision
	var mid := int(dc.disposition_mid)
	if store == null or cp == -1:
		return [mid, 0]
	var g := gain(cfg, profile)
	var d := JudgmentMath.clampi_(mid + JudgmentMath.mul_div(store.personal_disposition(chooser, cp) - mid, g, 1000), 0, 100000)
	if not with_colour:
		return [d, 0]
	var col := store.colour(chooser, cp)
	if col == 0:
		return [d, 0]
	col = JudgmentMath.mul_div(col, g, 1000)
	return [JudgmentMath.clampi_(d + col, 0, 100000), col]


## The opinion gain of `profile`, permille (1000: the spec's 1:1 reading).
static func gain(cfg: Dictionary, profile: String) -> int:
	var dc: Dictionary = cfg.decision
	var prof: Dictionary = (dc.profiles as Dictionary).get(profile, {})
	return int(prof.get("opinion_gain_permille", dc.get("opinion_gain_permille", 1000)))


## The factors `profile` weighs that the candidate's own `f` does not give, filled in place from the store (judgment's side of
## a choice, C1 and C5), each read apart: disposition (opinion()), ambivalence, trust, fear, loyalty. Returns the colour applied
## to the disposition (0 when none). A factor nobody gives (price, respect) stays absent and weighs 0.
static func _fill(store: JudgmentStore, cfg: Dictionary, profile: String, weights: Dictionary, chooser: int, cp: int, f: Dictionary, with_colour: bool) -> int:
	var dc: Dictionary = cfg.decision
	var known := store != null and cp != -1
	var col := 0
	if weights.has("disposition") and not f.has("disposition"):
		var o := opinion(store, cfg, profile, chooser, cp, with_colour)
		f.disposition = int(o[0])
		col = int(o[1])
	if weights.has("ambivalence") and not f.has("ambivalence"):
		# SJD-Q04 'wary but willing': strong GOOD and BAD at once, from the effective (decayed plus permanent) parts, read on the
		# decision's scale (the opinion gain)
		f.ambivalence = JudgmentMath.clampi_(JudgmentMath.mul_div(store.ambivalence(chooser, cp), gain(cfg, profile), 1000), 0, 100000) if known else 0
	if weights.has("trust") and not f.has("trust"):
		f.trust = store.trust_factor(chooser, cp) if known else int(dc.disposition_mid)
	if weights.has("fear") and not f.has("fear"):
		f.fear = store.fear_of(chooser, cp, int(dc.get("fear_permille_per_point", 25000))) if known else 0
	if weights.has("loyalty") and not f.has("loyalty"):
		var lo := 0
		if known and store.social != null and cp != chooser:
			if store.social.kin(chooser, cp):
				lo = int(dc.get("kin_loyalty", 100000))
			elif store.social.friends(chooser, cp):
				lo = int(dc.get("friend_loyalty", 70000))
		f.loyalty = lo
	return col


## The factors a choice under `profile` would weigh for `chooser` and counterparty `cp`, given the caller's `f` (tests and
## diagnostics: the same fill as choose()).
static func fill(store: JudgmentStore, cfg: Dictionary, profile: String, chooser: int, cp: int, f: Dictionary) -> Dictionary:
	var out := f.duplicate()
	var prof: Dictionary = cfg.decision.profiles[profile]
	_fill(store, cfg, profile, prof.weights, chooser, cp, out, true)
	return out


## A candidate's identity within its tier: the tier, every factor the profile weighs but live_order (sorted by name) and its
## stubbornness penalty. A factor weighed 0 cannot tell two candidates apart.
static func _signature(tier, f: Dictionary, stubborn: int, weights: Dictionary) -> String:
	var names := f.keys()
	names.sort()
	var parts := [str(tier), str(stubborn)]
	for k in names:
		if str(k) != "live_order" and int(weights.get(k, 0)) != 0:
			parts.append("%s=%d" % [k, int(f[k])])
	return "|".join(parts)
