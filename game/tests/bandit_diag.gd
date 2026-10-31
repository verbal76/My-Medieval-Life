extends RefCounted
## X20-BANDIT-AI (owner directive 2026-10-31, docs/directives/2026-10-31_sjdh_c4_bandit_intelligence.md): read-only bandit
## diagnostics for long runs (game/tests/economy_sim.gd). Nothing here changes the world: it reads positions, targets,
## plans, health and the village's notes. Every game minute (one harness tick) it keeps each living bandit's last state:
## health, its target, what it is doing, who has it as their target (and what they are), how many hostile adults and how
## many other bandits stand within NEAR tiles, the distance to the camp, and whether it is retreating (heading for the camp
## hurt, no target). At a bandit's death it prints a `BANDIT_DEATH {...}` line from the state of the minute before, with the
## phase it died in:
##   robbing            it had a target of its own that was not attacking it (a chase or a robbery under way)
##   fighting_back      its target was one of those attacking it
##   caught_retreating  a retreat had begun and not reached the camp: hurt below the line where fight() gives up (30%), or
##                      making for the camp with someone after it (whatever it was doing when struck again)
##   disengaged         no target, not retreating (lurking, resting, at market, stalking a watch)
## and by whom: a guard, a victim (someone it robbed or attacked in the last RECENT minutes), a family head defending
## ("defending the family"), several at once (organised: two or more with it as their target), or others.
## It also counts robberies from the village's notes ("X robbed Y Z of N coins"), robberies that took nothing, and the same
## bandit robbing the same victim again within RECENT minutes, and prints a `BANDITS {...}` line at each checkpoint.

const NEAR := 8.0
const RECENT := 30.0          # game minutes

var last := {}                # bandit id -> its state the minute before
var engaged := {}             # bandit id -> {t0, max_hostile, max_band, retreats, retreat_from_hp}
var robs: Array = []          # [minute, bandit name, victim "name family", coins, item]
var deaths: Array = []        # the BANDIT_DEATH rows
var victims := {}             # bandit id -> {victim id: last minute it targeted them}
var counts := {"robberies": 0, "robberies_nothing": 0, "rerob_same_victim": 0, "bandit_deaths": 0, "retreat_starts": 0,
	"retreats_survived": 0, "outnumbered_minutes": 0, "fought_outnumbered_minutes": 0, "band_assist_minutes": 0}
var retreating := {}          # bandit id -> minute a retreat began (cleared when it reaches the camp alive or dies)


func tick(w: World) -> void:
	var by_target := {}
	for o: NPC in w.npcs:
		if o.alive and o.target >= 0:
			if not by_target.has(o.target):
				by_target[o.target] = []
			by_target[o.target].append(o)
	for b: NPC in w.npcs:
		if not b.alive or b.role != "bandit":
			continue
		var att: Array = by_target.get(b.id, [])
		var hostile := 0
		var band := 0
		if b.target >= 0 or not att.is_empty():
			for o: NPC in w.npcs:
				if not o.alive or o == b or o.depth != b.depth or o.pos.distance_to(b.pos) > NEAR:
					continue
				if o.role == "bandit":
					band += 1
				elif o.role == "adult" or o.role == "elder" or o.job == "guard":
					if not w.asleep(o) and w.place_of(o.pos) == "":
						hostile += 1
		if b.target >= 0 and b.target != -2 and w.npc(b.target) != null:
			if not victims.has(b.id):
				victims[b.id] = {}
			victims[b.id][b.target] = w.minutes
		var dcamp := b.pos.distance_to(Vector2(w.bandit_camp))
		var to_camp := false
		if not b.plan.is_empty() and (b.plan[0] as Dictionary).has("to"):
			to_camp = Vector2(b.plan[0].to).distance_to(Vector2(w.bandit_camp)) < 4.0
		var low := b.hp < b.max_hp * 0.3
		var retreat := b.target < 0 and (low or (to_camp and dcamp > 6.0 and not att.is_empty()))
		if retreat and not retreating.has(b.id):
			retreating[b.id] = w.minutes
			counts.retreat_starts += 1
		elif retreating.has(b.id) and dcamp < 3.0 and att.is_empty():
			retreating.erase(b.id)
			counts.retreats_survived += 1
		if hostile > band + 1:
			counts.outnumbered_minutes += 1
			if b.target >= 0:
				counts.fought_outnumbered_minutes += 1
		if band > 0 and not att.is_empty():
			counts.band_assist_minutes += 1
		var who := []
		for o: NPC in att:
			var kind := "guard" if o.job == "guard" else ("bandit" if o.role == "bandit" else ("family" if o.doing == "defending the family" else "villager"))
			var recent: Dictionary = victims.get(b.id, {})
			if kind == "villager" and recent.has(o.id) and w.minutes - float(recent[o.id]) <= RECENT:
				kind = "victim"
			who.append([o.id, kind, snappedf(o.pos.distance_to(b.pos), 0.1)])
		last[b.id] = {"day": w.day(), "min": int(fmod(w.minutes, World.DAY)), "hp": snappedf(b.hp, 0.1), "max_hp": b.max_hp, "target": b.target,
			"doing": b.doing, "attackers": who, "hostile_near": hostile, "band_near": band, "camp": snappedf(dcamp, 0.1),
			"retreating": retreating.has(b.id), "retreat_since": float(retreating.get(b.id, -1.0)), "to_camp": to_camp}


func on_note(w: World, t: String) -> void:
	var at := t.find(" robbed ")
	if at < 0 or not t.contains(" coins"):
		return
	var m := RegEx.create_from_string("^(.+?) robbed (.+) of (\\d+) coins(?: and a (.+))?\\.$").search(t)
	if m == null:
		return
	counts.robberies += 1
	var nothing := int(m.get_string(3)) == 0 and m.get_string(4) == ""
	if nothing:
		counts.robberies_nothing += 1
	for r in robs:
		if str(r[1]) == m.get_string(1) and str(r[2]) == m.get_string(2) and w.minutes - float(r[0]) <= RECENT:
			counts.rerob_same_victim += 1
			break
	robs.append([w.minutes, m.get_string(1), m.get_string(2), int(m.get_string(3)), m.get_string(4)])
	if robs.size() > 64:
		robs.pop_front()


func on_died(w: World, n: NPC, cause: String) -> void:
	if n.role != "bandit":
		return
	counts.bandit_deaths += 1
	var s: Dictionary = last.get(n.id, {})
	var phase := "unknown"
	if not s.is_empty():
		var fighting_back := false
		for a in s.get("attackers", []):
			fighting_back = fighting_back or int(a[0]) == int(s.target)
		if bool(s.retreating):
			phase = "caught_retreating"          # a retreat had begun (hurt, or making for the camp with someone on it)
		elif int(s.target) < 0:
			phase = "disengaged"
		else:
			phase = "fighting_back" if fighting_back else "robbing"
	var by := "none"
	var kinds := {}
	for a in s.get("attackers", []):
		kinds[str(a[1])] = int(kinds.get(str(a[1]), 0)) + 1
	if (s.get("attackers", []) as Array).size() >= 2:
		by = "organised"
	elif kinds.size() == 1:
		by = str(kinds.keys()[0])
	retreating.erase(n.id)
	var row := {"day": w.day(), "id": n.id, "name": n.name, "cause": cause, "phase": phase, "by": by, "attacker_kinds": kinds, "last": s}
	deaths.append(row)
	print("BANDIT_DEATH " + JSON.stringify(row))


func line(w: World) -> String:
	var alive := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			alive += 1
	var by_phase := {}
	var by_who := {}
	for r in deaths:
		by_phase[r.phase] = int(by_phase.get(r.phase, 0)) + 1
		by_who[r.by] = int(by_who.get(r.by, 0)) + 1
	return "BANDITS " + JSON.stringify({"day": w.day(), "alive": alive, "arrived": int(w.stats.get("outlaws_arrived", 0)),
		"came_of_age": int(w.stats.get("came_of_age_in_clan", 0)), "counts": counts, "deaths_by_phase": by_phase, "deaths_by_who": by_who})
