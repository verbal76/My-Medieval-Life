class_name JudgmentBandit
extends RefCounted
## X20-BANDIT-AI (owner directive 2026-10-31, docs/directives/2026-10-31_sjdh_c4_bandit_intelligence.md; SJD-H C4): a bandit
## in danger weighs what to do as a villager head does (JudgmentFamily.danger), by the same shared interface
## (JudgmentWeighting.choose), with its own personality (the per-person weight spread, stubbornness, anger) and nothing
## added to health, damage or speed. Design: docs/expansion20/BANDIT_AI_DESIGN.md.
##
## When: every game minute a bandit is engaged (it has a target, or someone has it as theirs), from NPCBrain.fight.
## What it can know (no omniscience): the people it can see (World.near: within witness_radius, awake, in the same place)
## and who of them is coming at it; guards on duty in sight; its fellow bandits in sight and which of them is under attack;
## its own health; what it has been through (its practical-wisdom record: routs it survived, JudgmentPersonality); and the
## deaths of bandits it knows of (death news it saw or was told by the band, JudgmentStore news memories).
## The options (profile bandit_danger, judgment.json; numbers PROVISIONAL agent values):
##   press      go on with what it was doing (the robbery, or the fight it is in): live_order, the numbers on its side
##   retreat    break off and make for the camp, where the band is (regroup): outnumbered, hurt, wariness
##   break_out  strike the one barring the way to the camp (cornered: a foe within cornered_radius between it and the camp)
##   defend     go to the aid of a fellow bandit under attack, by what it thinks of them (Relations regard, friends) and the odds
## A retreat once begun holds while the way is open (no turning back into a fight it chose to leave); struck while retreating
## it weighs again (break out, or keep going). Below the existing survival line (30% of its health) it always retreats, as
## before. Off unless judgment is attached and decision.integration.bandit_danger is set (the Build 18 path is untouched).

const FLAG := "bandit_danger"
const KEY := 6113


static func cfg(w) -> Dictionary:
	return (w.judgment.cfg.decision.get("bandit", {}) as Dictionary)


static func on(w) -> bool:
	return JudgmentLive.on(w, FLAG)


## What `b` can see of the danger around it: {threats: [NPC], attackers: [NPC], allies: [NPC], ally_in_need: NPC or null,
## blocker: NPC or null}. Threats are those coming at it (their target is b) and guards on duty; allies are other bandits.
static func perceive(w, b: NPC) -> Dictionary:
	var c := cfg(w)
	var r := float(GameData.b("witness_radius"))
	var seen: Array = w.near(b.pos, r)
	var threats := []
	var attackers := []
	var allies := []
	var in_need = null
	var best_regard := -1.0
	for o: NPC in seen:
		if o == b or not o.alive or o.depth != b.depth:
			continue
		if o.role == "bandit":
			allies.append(o)
			continue
		if o.target == b.id:
			attackers.append(o)
			threats.append(o)
		elif o.job == "guard":
			threats.append(o)
	for a: NPC in allies:
		var foes := 0
		for o: NPC in seen:
			if o.alive and o.role != "bandit" and o.target == a.id:
				foes += 1
		if foes > 0:
			var reg := float(w.relations.peek(b.id, a.id).regard)
			if reg > best_regard:
				best_regard = reg
				in_need = a
	var blocker = null
	var corner := float(c.get("cornered_radius", 2.5))
	var home := Vector2(escape_cell(w, b, attackers)) + Vector2(0.5, 0.5) - b.pos
	if home.length() > corner:
		for o: NPC in attackers:
			var d: Vector2 = o.pos - b.pos
			if d.length() <= corner and d.normalized().dot(home.normalized()) > 0.5:
				blocker = o
				break
	return {"threats": threats, "attackers": attackers, "allies": allies, "ally_in_need": in_need, "blocker": blocker}


## Where `b` falls back to: the camp, where the band is; at the camp already (within camp_radius), away from those coming at it,
## escape_tiles out, to the nearest open cell (a camp it cannot hold is no refuge: falling back to where it stands is no retreat).
static func escape_cell(w, b: NPC, attackers: Array) -> Vector2i:
	var c := cfg(w)
	var camp := Vector2(w.bandit_camp) + Vector2(0.5, 0.5)
	if b.pos.distance_to(camp) > float(c.get("camp_radius", 6.0)) or attackers.is_empty():
		return w.bandit_camp
	var from := Vector2.ZERO
	for o: NPC in attackers:
		from += o.pos
	from /= float(attackers.size())
	var away := b.pos - from
	if away.length() < 0.01:
		away = b.pos - camp if b.pos.distance_to(camp) > 0.01 else Vector2.RIGHT
	var to := b.pos + away.normalized() * float(c.get("escape_tiles", 14.0))
	return w.map.nearest_walkable(Vector2i(floori(to.x), floori(to.y)))


## The fall-back plan: to the escape cell, and if that is not the camp, lying low there a while (no hiding mechanic exists; a
## bandit out of sight of its pursuers waits before going home).
static func fall_back(w, b: NPC, attackers: Array) -> void:
	var to := escape_cell(w, b, attackers)
	b.plan = [w.brain.go(to, 1.2)]
	if to != w.bandit_camp:
		b.plan.append(w.brain.work(float(cfg(w).get("lie_low_minutes", 45)), "", {}, "idle"))
		b.doing = "slipping away from the camp"
	else:
		b.doing = "falling back to the camp"


## How wary `b` is from what it has been through and heard (0..100000): each rout it survived (its own experience,
## JudgmentPersonality CH_MISTAKE "bandit_routed") and each bandit's violent death it knows of (death news, seen or told
## by the band) within wary_days.
static func wariness(w, b: NPC) -> int:
	var c := cfg(w)
	var j: JudgmentStore = w.judgment
	var days := int(c.get("wary_days", 8))
	var today: int = j.now_minute() / 1440
	var routs: int = j.pers.recent(b.id, JudgmentPersonality.CH_MISTAKE, JudgmentPersonality.kind_code("bandit_routed"), today, days) if j.pers.active else 0
	var losses := 0
	var deathh := "death".hash()
	for ev in j.memories.get(b.id, {}):
		var m: PackedInt64Array = j.memories[b.id][ev]
		if str(j._types[m[JudgmentStore.M_TYPE]]) != "death" or int(m[JudgmentStore.M_DAY]) < today - days:
			continue
		if (j.fact_tags.get(ev, []) as Array).has("bandit") and (j.fact_tags.get(ev, []) as Array).has("cause:slain"):
			losses += 1
	return clampi(routs * int(c.get("wary_per_rout", 25000)) + losses * int(c.get("wary_per_loss", 15000)), 0, 100000)


## Weigh and act. Returns true when the bandit acted (the caller's fight step is over for this tick).
static func decide(w, b: NPC) -> bool:
	var j: JudgmentStore = w.judgment
	var c := cfg(w)
	var p := perceive(w, b)
	var threats: Array = p.threats
	var allies: Array = p.allies
	var retreating: bool = w.brain.bandit_retreat.has(b.id)
	if threats.is_empty() and p.ally_in_need == null:
		return false
	var side := allies.size() + 1
	var hp_frac := b.hp / maxf(1.0, b.max_hp)
	var outnumbered := clampi(int((float(threats.size()) / float(side) - 1.0) * 100000.0), 0, 100000)
	var advantage := clampi(int((float(side) / float(maxi(1, threats.size())) - 1.0) * 100000.0), 0, 100000)
	var opts := []
	# a robber robs; it does not stay to kill the villagers who turn on it (Population, the wiki: "robs rather than kills"): against
	# a villager (no guard) fighting the band it presses no fight; it falls back, breaks out if cornered, or stands by a fellow
	var tn: NPC = w.npc(b.target) if b.target >= 0 else null
	var quarrel: bool = tn != null and tn.job != "guard" and tn.role != "bandit" and tn.target >= 0 and w.npc(tn.target) != null and w.npc(tn.target).role == "bandit"
	if not retreating and not quarrel:
		opts.append({"id": "press", "counterparty": b.target if b.target >= 0 else -1, "factors": {"live_order": 100000, "advantage": advantage, "able": int(hp_frac * 100000.0)}})
	opts.append({"id": "retreat", "factors": {"outnumbered": outnumbered, "hurt": int((1.0 - hp_frac) * 100000.0), "wary": wariness(w, b), "under_way": 100000 if retreating and p.blocker == null else 0}})
	if p.blocker != null:
		opts.append({"id": "break_out", "counterparty": p.blocker.id, "factors": {"cornered": int(hp_frac * 100000.0)}})
	if p.ally_in_need != null and not retreating:
		var a: NPC = p.ally_in_need
		var t: Dictionary = w.relations.peek(b.id, a.id)
		var bond := clampi(int(float(t.regard) * 1000.0) + (int(c.get("friend_bond", 30000)) if bool(t.friends) else 0), 0, 100000)
		opts.append({"id": "defend", "counterparty": -1, "factors": {"bond": bond, "advantage": advantage}})
	var nm := j.now_minute()
	var r := JudgmentWeighting.choose(j, j.cfg, b.id, FLAG, opts, [w.day(), b.id, KEY, nm])
	var ch := str(r.chosen)
	j._stat("bandit_" + ch)
	match ch:
		"retreat":
			if not retreating:
				w.brain.bandit_retreat[b.id] = nm
				if hp_frac < 0.5 or outnumbered >= 100000:
					JudgmentLive.costly_mistake(w, b.id, "bandit_routed", float(c.get("rout_cost_points", 2.0)))     # learnt: it was driven off
			if w.recorder != null and b.target >= 0:
				w.recorder.chase_end(b, "bandit_retreat")
			b.target = -1
			fall_back(w, b, p.attackers)
			return true
		"break_out":
			w.brain.bandit_retreat.erase(b.id)
			b.target = p.blocker.id
			b.doing = "breaking out"
			return false
		"defend":
			var foe: NPC = null
			for o: NPC in w.near(p.ally_in_need.pos, float(GameData.b("witness_radius"))):
				if o.alive and o.role != "bandit" and o.target == p.ally_in_need.id:
					foe = o
					break
			if foe != null:
				b.target = foe.id
				b.doing = "standing by %s" % p.ally_in_need.name
			return false
	return false


## A bandit has been struck (NPCBrain.fight, the blow's noise): its fellow bandits who see it, free and not falling back, weigh
## going to its aid (bond: what each thinks of it, advantage: the numbers) against keeping on with what they were doing, or
## falling back themselves when the odds they see are bad. Not universal loyalty: a stranger in the band is left to it.
static func on_struck(w, b: NPC, attacker: NPC) -> void:
	if attacker == null or not attacker.alive:
		return
	var j: JudgmentStore = w.judgment
	var c := cfg(w)
	for a: NPC in w.near(b.pos, float(GameData.b("witness_radius"))):
		if a == b or a.role != "bandit" or not a.alive or a.target != -1 or w.brain.bandit_retreat.has(a.id) or a.depth != b.depth:
			continue
		var p := perceive(w, a)
		var side: int = (p.allies as Array).size() + 1
		var foes := maxi(1, (p.threats as Array).size() + (0 if (p.threats as Array).has(attacker) else 1))
		var advantage := clampi(int((float(side) / float(foes) - 1.0) * 100000.0), 0, 100000)
		var outnumbered := clampi(int((float(foes) / float(side) - 1.0) * 100000.0), 0, 100000)
		var t: Dictionary = w.relations.peek(a.id, b.id)
		var bond := clampi(int(float(t.regard) * 1000.0) + (int(c.get("friend_bond", 30000)) if bool(t.friends) else 0), 0, 100000)
		var opts := [{"id": "keep_on", "factors": {"live_order": 100000}},
			{"id": "defend", "factors": {"bond": bond, "advantage": advantage}},
			{"id": "retreat", "factors": {"outnumbered": outnumbered, "wary": wariness(w, a)}}]
		var r := JudgmentWeighting.choose(j, j.cfg, a.id, FLAG, opts, [w.day(), a.id, b.id, KEY + 1, j.now_minute()])
		j._stat("bandit_aid_" + str(r.chosen))
		match str(r.chosen):
			"defend":
				a.target = attacker.id
				a.plan.clear()
				a.doing = "standing by %s" % b.name
			"retreat":
				w.brain.bandit_retreat[a.id] = j.now_minute()
				fall_back(w, a, [attacker])
