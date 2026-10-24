class_name Justice
extends RefCounted
## GP-CRIME-PURSUIT step A1 (owner directive 2026-10-24, open item 03 A and D; docs/design/REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS.md
## J1): the authorities' file on each offender. One case per player, keyed by the player's reference ("player" for the
## host, "player:<pid>" for a guest; never the shared person id -2), so a guest's crime is never the host's.
##
## It extends the player's own crime record (PlayerState.crimes, which now also holds "assault", "guard_assault" and
## "killing"): each crime in a case points at its record entry (`rec`) and holds only what enforcement needs. It is not
## a second ledger of morality: the judgment GOOD/BAD ledgers, Relations' regard and notoriety stay as they are and
## stay authoritative for what people think; a case only drives what the guards do.
##
## Knowledge, never omniscience. A crime is in the case whether anyone saw it or not, but a guard knows of it only
## through the channels the world has: seeing it (World.raise_alarm, World.witness), being told (World.deliver_report),
## and (A3) the hue and cry and another guard's word. The tier a guard acts on is that of the crimes THAT guard knows.
## The last-known place is written only when a guard actually sees the offender (or is told where they were seen).
##
## A case is saved under the optional World key "justice" (absent in a Build 20 save: no cases; no save_version change).
## Numbers: balance.json "justice" (agent proposals; the hue and cry's earshot PROPOSED for the owner).
##
## Case: {offender: ref, name, opened: minute, crimes: [crime], known: {guard id: [crime index]}, aware: {villager id:
##   crime index} (who knows who did a violent crime: witnesses, the hue and cry's hearers), pursuers: {guard id: true},
##   last: [x, y, minute, level] (where a guard last saw them, or was told they were seen; [] never), guard_struck: blows
##   at guards, resisted: bool (struck a guard or killed again while a guard was on the case)}.
## Crime: {kind, day, t, victim, at: [x, y], seen: witnesses, rec: index in PlayerState.crimes, settled: "" | "fined" |
##   "yielded" | "taken" | "lapsed"}.
## Status (status()): "clear" (nothing outstanding that a guard knows), "pursued" (a guard is on it), "wanted" (outstanding
## and known, nobody on it now). A closed case (the offender died: owner answer 3, "case ends; stain stays") moves to
## `closed` (the last justice.closed_kept), with its resolution.

var w
var cases := {}            # offender ref -> case
var closed: Array = []     # the last closed cases (oldest first): case + {resolution, closed_t}
var _ringing := false      # A3: the bell's own learning does not ring it again


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("justice")


static func severity(kind: String) -> int:
	var s: Dictionary = cfg().severity
	return int(s.get(kind, s._default))


static func is_theft(kind: String) -> bool:
	return (cfg().theft_kinds as Array).has(kind)


static func is_violent(kind: String) -> bool:
	return (cfg().violent_kinds as Array).has(kind)


static func tier_rank(tier: String) -> int:
	return (cfg().tiers as Array).find(tier)


static func response(tier: String) -> Dictionary:
	return cfg().response[tier]


func is_empty() -> bool:
	return cases.is_empty() and closed.is_empty()


func case_of(ref: String) -> Dictionary:
	return cases.get(ref, {})


## The offender's case, opened when it is first needed.
func _open(ref: String) -> Dictionary:
	if cases.has(ref):
		return cases[ref]
	var p: PlayerState = w.player_of_ref(ref)
	var c := {"offender": ref, "name": ("%s %s" % [p.name, p.family]) if p != null else ref, "opened": w.minutes, "crimes": [],
		"known": {}, "aware": {}, "pursuers": {}, "last": [], "guard_struck": 0, "resisted": false}
	cases[ref] = c
	return c


## A crime by player `ref` (its record entry already appended to that player's crimes): `kind`, against `victim` (an NPC
## or null), at `at`, seen by `seen` people (the witnesses' count of the record). Returns the crime's index in the case.
## A blow at a guard or a killing while a guard is on the case is resistance (lethal force may follow, response.lethal).
func record(ref: String, kind: String, victim, at: Vector2, seen: int, rec := -1) -> int:
	var c := _open(ref)
	var pursued := not (c.pursuers as Dictionary).is_empty()
	var cr := {"kind": kind, "day": w.day(), "t": w.minutes, "victim": victim.id if victim != null else -1, "at": [at.x, at.y],
		"seen": seen, "rec": rec, "settled": "", "pursued": pursued}
	if kind == "guard_assault":
		c.guard_struck = int(c.guard_struck) + 1
		if pursued:
			c.resisted = true
	if kind == "killing" and pursued:
		# violence again with a guard already on the case; the blow that began this same attack (on this victim) counts
		# from when it fell, so a killing the guards answered as it happened is not resistance by itself
		var began_pursued := true
		for e in c.crimes:
			if str(e.kind) in ["assault", "guard_assault"] and int(e.victim) == int(cr.victim) and str(e.settled) == "":
				began_pursued = bool(e.get("pursued", true))
				break
		if began_pursued:
			c.resisted = true
	c.crimes.append(cr)
	if kind == "guard_assault" and _known_rank(c) >= tier_rank("murder"):
		c.resisted = true
	w.stat("justice_crimes_" + kind)
	return c.crimes.size() - 1


## The outstanding crime of `kind` against `victim_id` begun within `minutes` (blow after blow of one attack is one
## assault), or -1.
func recent(ref: String, kind: String, victim_id: int, minutes: float) -> int:
	var c: Dictionary = cases.get(ref, {})
	for i in range(c.get("crimes", []).size() - 1, -1, -1):
		var cr: Dictionary = c.crimes[i]
		if w.minutes - float(cr.t) > minutes:
			break
		if str(cr.kind) == kind and int(cr.victim) == victim_id and str(cr.settled) == "":
			return i
	return -1


## The minute the authorities last saw `ref` (-1 never).
func last_t(ref: String) -> float:
	var c: Dictionary = cases.get(ref, {})
	return float(c.last[2]) if not c.is_empty() and not (c.last as Array).is_empty() else -1.0


## Whether the trail guard `g` would follow is cold: the authorities last saw `ref` more than the tier's search_minutes
## (plus late_search_minutes for the walk there) ago.
func cold(g: NPC, ref: String) -> bool:
	var seen := maxf(last_t(ref), float(g.pursuit.get("t", -1.0)))
	return w.minutes - seen > float(response(tier_for(g, ref)).search_minutes) + float(cfg().late_search_minutes)


## When a search of `ref`'s case ends: search_minutes after the last sighting, with a few minutes to look for a guard who
## only now reaches the place. However many guards join, the hunt dies down that long after the offender was last seen.
func search_until(g: NPC, ref: String) -> float:
	var mins := float(response(tier_for(g, ref)).search_minutes)
	return maxf(maxf(last_t(ref), float(g.pursuit.get("t", -1.0))) + mins, w.minutes + minf(mins, float(cfg().late_search_minutes)))


## Guard `g` now knows of crimes `cis` of `ref`'s case (seeing them, being told, A3: hearing the hue and cry, another
## guard's word). Settled crimes are not learned. `at` (optional): where the offender was seen, at minute `t`.
func learn(g: NPC, ref: String, cis: Array, at := Vector2.INF, t := -1.0) -> void:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty() or g == null:
		return
	var key := str(g.id)
	var k: Array = c.known.get(key, [])
	for ci in cis:
		var i := int(ci)
		if i >= 0 and i < c.crimes.size() and not k.has(i) and str(c.crimes[i].settled) == "":
			k.append(i)
	k.sort()
	c.known[key] = k
	if at != Vector2.INF:
		saw_at(ref, at, t if t >= 0.0 else w.minutes, 0)
	if not _ringing:
		_ringing = true
		escalate(ref, cis)                      # A3: a second killing known rings the bell
		_ringing = false


## Where the offender was last seen by the authorities (a guard's eyes, or a place a report or the hue and cry named):
## kept only when newer than what the case holds.
func saw_at(ref: String, at: Vector2, t: float, level := 0) -> void:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return
	if (c.last as Array).is_empty() or float(c.last[2]) <= t:
		c.last = [at.x, at.y, t, level]


## The crimes guard `g` knows of in `ref`'s case that are still outstanding.
func known_by(g: NPC, ref: String) -> Array:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty() or g == null:
		return []
	return (c.known.get(str(g.id), []) as Array).filter(func(i): return str(c.crimes[int(i)].settled) == "")


## Whether guard `g` knows of anything outstanding against `ref`.
func knows(g: NPC, ref: String) -> bool:
	return not known_by(g, ref).is_empty()


## The tier of a set of crimes (indices into the case's crimes): multiple_murder for two or more killings (one at least
## outstanding; one already answered, by a fine or by being taken in, still counts: who kills again is a multiple
## murderer), murder for one outstanding, assault for any outstanding blow, repeated_theft for repeat_theft thefts within
## repeat_days (settled ones count towards the repeat, one must be outstanding), theft, else minor. Lapsed crimes count
## for nothing.
func tier_of(c: Dictionary, cis: Array) -> String:
	var kills := 0
	var answered := 0
	var blows := 0
	var thefts := 0
	for ci in cis:
		var cr: Dictionary = c.crimes[int(ci)]
		if str(cr.settled) != "":
			if str(cr.kind) == "killing" and str(cr.settled) != "lapsed":
				answered += 1
			continue
		match str(cr.kind):
			"killing":
				kills += 1
			"assault", "guard_assault":
				blows += 1
			_:
				if is_theft(str(cr.kind)):
					thefts += 1
	if kills >= 2 or (kills == 1 and answered >= 1):
		return "multiple_murder"
	if kills == 1:
		return "murder"
	if blows > 0:
		return "assault"
	if thefts > 0:
		var recent := 0
		for cr in c.crimes:
			if is_theft(str(cr.kind)) and w.day() - int(cr.day) <= int(cfg().repeat_days):
				recent += 1
		return "repeated_theft" if recent >= int(cfg().repeat_theft) else "theft"
	return "minor"


## The tier guard `g` acts on: of the crimes they know (tier_of weighs which are outstanding).
func tier_for(g: NPC, ref: String) -> String:
	var c: Dictionary = cases.get(ref, {})
	return "minor" if c.is_empty() or g == null else tier_of(c, c.known.get(str(g.id), []))


## The case's tier over every outstanding crime any guard knows of (what the authorities as a whole know).
func known_tier(ref: String) -> String:
	var c: Dictionary = cases.get(ref, {})
	return "minor" if c.is_empty() else tier_of(c, _known_all(c))


func _known_all(c: Dictionary) -> Array:
	var all := []
	for key in c.known:
		for i in c.known[key]:
			if not all.has(int(i)):
				all.append(int(i))
	all.sort()
	return all


func _known_rank(c: Dictionary) -> int:
	return tier_rank(tier_of(c, _known_all(c)))


## The case's severity score: the sum of severity() over outstanding crimes (all of them, known or not; diagnostics and
## the workbook; it never touches a ledger).
func score(ref: String) -> int:
	var c: Dictionary = cases.get(ref, {})
	var s := 0
	for cr in c.get("crimes", []):
		if str(cr.settled) == "":
			s += severity(str(cr.kind))
	return s


## "clear", "pursued" or "wanted" (see the header); "" when there is no open case.
func status(ref: String) -> String:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return ""
	if not (c.pursuers as Dictionary).is_empty():
		return "pursued"
	return "wanted" if not _known_all(c).filter(func(i): return str(c.crimes[i].settled) == "").is_empty() else "clear"


## Crimes `cis` (or, with [], every outstanding one) are settled `how` ("fined", "yielded", "taken", "lapsed"): they no
## longer count in any guard's tier. Returns how many were settled.
func settle(ref: String, cis: Array, how: String) -> int:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return 0
	var k := 0
	for i in c.crimes.size():
		if (cis.is_empty() or cis.has(i)) and str(c.crimes[i].settled) == "":
			c.crimes[i].settled = how
			k += 1
	if k > 0:
		w.stat("justice_settled_" + how, k)
	if cis.is_empty():
		c.resisted = false
	return k


## Dawn: an outstanding crime older than its tier's wanted_days lapses (murder never: wanted_days -1).
func dawn() -> void:
	for ref in cases.keys():
		var c: Dictionary = cases[ref]
		for i in c.crimes.size():
			var cr: Dictionary = c.crimes[i]
			if str(cr.settled) != "":
				continue
			var t := tier_of(c, [i]) if not is_theft(str(cr.kind)) else "theft"
			var days := int(response(t).wanted_days)
			if days >= 0 and w.day() - int(cr.day) > days:
				cr.settled = "lapsed"
				w.stat("justice_settled_lapsed")


## The offender died (owner answer 3, 2026-10-24: "Case ends; stain stays"): the case closes and nobody hunts the heir;
## the family's existing reputation (JudgmentBonds) carries the stain.
func on_death(ref: String) -> void:
	close(ref, "died")


func close(ref: String, resolution: String) -> void:
	if not cases.has(ref):
		return
	var c: Dictionary = cases[ref]
	cases.erase(ref)
	c.resolution = resolution
	c.closed_t = w.minutes
	c.pursuers = {}
	closed.append(c)
	while closed.size() > int(cfg().closed_kept):
		closed.pop_front()
	w.stat("justice_closed_" + resolution)



# ---------------------------------------------------------------- pursuit (A2)
## Guard `g` goes on `ref`'s case: "pursuing" (the offender is in sight: the chase, NPC.target -2) or "responding" (to a
## place: where a report or the hue and cry says they were, `at`; then a search there). A guard fighting someone else
## (a bandit) keeps that fight, and one already on another player's case stays on it.
## `t`: when the place `at` was seen (a report's minute); a guard already searching from a later sighting keeps its own.
func engage(g: NPC, ref: String, state: String, at := Vector2.INF, t := -1.0) -> void:
	var c: Dictionary = cases.get(ref, {})
	var p: PlayerState = w.player_of_ref(ref)
	if c.is_empty() or g == null or not g.alive or p == null or not p.alive:
		return
	if g.target != -1 and not Life.is_player_id(g.target):
		return
	if not g.pursuit.is_empty() and str(g.pursuit.ref) != ref:
		return
	if not knows(g, ref):
		return                                  # nothing outstanding that this guard knows of (settled, or never told)
	c.pursuers[str(g.id)] = true
	if state == "pursuing":
		var fresh: bool = g.pursuit.is_empty() or str(g.pursuit.state) != "pursuing"
		g.pursuit = {"ref": ref, "state": "pursuing", "at": [p.pos.x, p.pos.y], "t": w.minutes, "until": -1.0, "cells": [], "i": 0,
			"share": float(g.pursuit.get("share", w.minutes))}
		g.target = World.id_of_ref(ref)             # MP C6: the offender's own person id
		g.plan.clear()
		saw_at(ref, p.pos, w.minutes, p.map_level)
		g.doing = "chasing %s" % p.name
		if fresh:
			w.stat("justice_pursuits")
		return
	if Life.is_player_id(g.target) or (not g.pursuit.is_empty() and float(g.pursuit.get("t", -1.0)) > (t if t >= 0.0 else w.minutes)):
		return                                  # chasing, or searching from a later sighting than the report's
	var to := at if at != Vector2.INF else (Vector2(float(c.last[0]), float(c.last[1])) if not (c.last as Array).is_empty() else g.pos)
	var cells := search_cells(to, g, tier_for(g, ref))
	g.pursuit = {"ref": ref, "state": "responding", "at": [to.x, to.y], "t": t if t >= 0.0 else w.minutes, "until": -1.0, "cells": cells, "i": 1, "share": w.minutes}
	g.plan = [w.brain.go(Vector2i(int(cells[0][0]), int(cells[0][1])), 1.3), w.brain.doit("search_point")]
	g.doing = "answering a report"
	w.stat("justice_responses")


## A guard in a chase lost sight of the offender: the search of the last-known place and around it begins, for the
## tier's search_minutes (a tier with none lets the case go over to wanted at once).
func search(g: NPC) -> void:
	var p: Dictionary = g.pursuit
	var ref := str(p.ref)
	g.target = -1
	g.plan.clear()
	g.chase_route = false
	var mins := float(response(tier_for(g, ref)).search_minutes)
	if mins <= 0.0:
		release(g, "searched")
		return
	var at := Vector2(float(p.at[0]), float(p.at[1]))
	p.state = "searching"
	p.cells = search_cells(at, g, tier_for(g, ref))
	p.i = 0
	p.until = search_until(g, ref)
	var o: PlayerState = w.player_of_ref(ref)
	g.doing = "searching for %s" % (o.name if o != null else "someone")
	w.stat("justice_searches")


## A guard who was responding reached the place: the search begins there (the first place is behind it).
func begin_search(g: NPC) -> void:
	var p: Dictionary = g.pursuit
	var mins := float(response(tier_for(g, str(p.ref))).search_minutes)
	if mins <= 0.0:
		release(g, "searched")
		return
	p.state = "searching"
	p.until = search_until(g, str(p.ref))
	w.stat("justice_searches")


## The guard is off the case (the search ended, the case closed, the camp): no longer a pursuer; the case remembers.
func release(g: NPC, why: String) -> void:
	var ref := str(g.pursuit.get("ref", ""))
	if cases.has(ref):
		cases[ref].pursuers.erase(str(g.id))
	g.pursuit = {}
	if Life.is_player_id(g.target) and (ref == "" or g.target == World.id_of_ref(ref)):      # MP C6: only that case's player
		g.target = -1
	g.chase_route = false
	w.stat("justice_released_" + why)


## A guard deciding what to do next who knows of an outstanding crime by a player now in sight takes them on again: the
## wanted offender is remembered, never tracked (only sight finds them). True when it did.
func spot(g: NPC) -> bool:
	if not g.pursuit.is_empty():
		return false
	var refs := cases.keys()
	refs.sort()
	for ref in refs:
		if tier_rank(tier_for(g, ref)) < tier_rank("theft"):
			continue
		var p: PlayerState = w.player_of_ref(ref)
		if w.sees(g, p):
			engage(g, ref, "pursuing")
			w.stat("justice_reacquired")
			return true
	return false


## The places a guard looks, in order: the last-known spot `at`; then, up to the tier's search_points, the nearest hiding
## places (inside a building whose door is within search_tiles: the floor cell nearest its door) and open ground on the
## ways out (8 directions at half and full search_tiles), those leading on from where the guard came first. Fixed by the
## map and the positions (no random numbers).
func search_cells(at: Vector2, g: NPC, tier: String) -> Array:
	var first := [floori(at.x), floori(at.y)]
	var out := [first]
	var want := int(response(tier).search_points)
	if want <= 1:
		return out
	var r := float(cfg().search_tiles)
	var away := (at - g.pos).normalized() if at.distance_to(g.pos) > 0.5 else Vector2.RIGHT
	var cand := []                              # [key, x, y]
	var level := g.depth
	if level == 0:
		var ids: Array = w.interiors.keys()
		ids.sort()
		for id in ids:
			var b: Dictionary = w.buildings.get(id, {})
			var it: Dictionary = w.interiors[id]
			if b.is_empty() or not b.has("door") or (it.get("floor", []) as Array).is_empty():
				continue
			var door := Vector2(float(b.door[0]), float(b.door[1])) + Vector2(0.5, 0.5)
			if door.distance_to(at) > r:
				continue
			var best: Array = it.floor[0]
			for c in it.floor:
				if Vector2(float(c[0]), float(c[1])).distance_to(door) < Vector2(float(best[0]), float(best[1])).distance_to(door):
					best = c
			cand.append([_key(at, door, away, r), int(best[0]), int(best[1])])
	for k in 8:
		var dir := Vector2.RIGHT.rotated(TAU * k / 8.0)
		for f in [0.5, 1.0]:
			var c := _open_toward(at, at + dir * r * f, level)
			if c.x >= 0:
				cand.append([_key(at, Vector2(c) + Vector2(0.5, 0.5), away, r), c.x, c.y])
	cand.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and (a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))))
	for c in cand:
		if out.size() >= want:
			break
		var cell := [int(c[1]), int(c[2])]
		if not out.has(cell):
			out.append(cell)
	return out


static func _key(at: Vector2, c: Vector2, away: Vector2, r: float) -> float:
	var d := c - at
	var dot := d.normalized().dot(away) if d.length() > 0.01 else 1.0
	return snappedf(d.length() / r + (1.0 - dot) * 0.5, 0.0001)


## The open cell nearest `to` on the line back to `at` (walkable, outdoors on the surface), or (-1, -1).
func _open_toward(at: Vector2, to: Vector2, level: int) -> Vector2i:
	for s in range(10, -1, -1):
		var p := at.lerp(to, s / 10.0)
		var c := Vector2i(p.floor())
		if c.x < 0 or c.y < 0 or c.x >= w.map.w or c.y >= w.map.h:
			continue
		var solid: bool = w.map.is_solid(c) if level == 0 else w.underground.is_solid(level, c)
		if not solid and (level != 0 or w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == ""):
			return c
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- coordination and force (A3)
## What guard `g` knows passes to the guards in its sight (World.near: the one channel of sight), and theirs to it, at
## most every share_minutes: the crimes of each case either knows, and the newer last-known place. A free guard who
## now knows of an assault or worse joins: it goes to where the offender was last seen (responding), or takes them on
## if it sees them. Guards are never made: only those there are come. Event-light: one look round a minute per guard
## on a case, nothing for the rest.
func share_tick(g: NPC) -> void:
	if g.pursuit.is_empty() or w.minutes - float(g.pursuit.get("share", -1e9)) < float(cfg().share_minutes):
		return
	g.pursuit.share = w.minutes
	var ref := str(g.pursuit.ref)
	w.stat("justice_share_looks")
	for o: NPC in w.near(g.pos, float(GameData.b("witness_radius"))):
		if o == g or o.job != "guard":
			continue
		share(g, o, ref)


## Guard `a` and guard `b` (in each other's sight) share what they know of `ref`'s case.
func share(a: NPC, b: NPC, ref: String) -> void:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return
	var ka := known_by(a, ref)
	var kb := known_by(b, ref)
	learn(b, ref, ka)
	learn(a, ref, kb)
	if ka != known_by(b, ref) or kb != known_by(a, ref) or not ka.is_empty():
		w.stat("justice_shared")
	_join(b, a, ref)
	_join(a, b, ref)


## A guard who knows of an assault or worse and is free joins the hunt from what `from` knows (its last-known place).
func _join(g: NPC, from: NPC, ref: String) -> void:
	if g.target != -1 or not g.pursuit.is_empty() or tier_rank(tier_for(g, ref)) < tier_rank("assault"):
		return
	if w.minutes - last_t(ref) > float(response(tier_for(g, ref)).search_minutes):
		return                                  # the trail is cold: nobody is set searching by stale word
	var p: PlayerState = w.player_of_ref(ref)
	if w.sees(g, p):
		engage(g, ref, "pursuing")
	elif not from.pursuit.is_empty():
		engage(g, ref, "responding", Vector2(float(from.pursuit.at[0]), float(from.pursuit.at[1])), float(from.pursuit.t))
	if not g.pursuit.is_empty():
		w.stat("justice_joined")


## The hue and cry (owner answer 1, 2026-10-24: "a murder makes guards or villagers raise a shout or ring a bell, and
## everyone within earshot learns of it"; owner decision 2026-10-24, docs/directives/2026-10-24_multiplayer_batch_c_g2.md section 5:
## "local audible propagation through witnesses and existing communication mechanics. The village bell carries farther but does not
## instantly inform every NPC regardless of distance"). Raised from `at` by someone who saw crimes `cis` of `ref` (a witness of a
## killing, a guard struck, a pursuer who saw violence again).
##  - kind "hue_and_cry": a shout. It is heard by those awake within earshot of the one who shouts (World.near: witness_radius, the
##    same building or the open air, the same level: walls and rock stop it), and every villager who hears it takes up the cry where
##    they stand, so it travels from hearer to hearer; it dies away `radius` tiles from where it was raised (hue_and_cry_tiles). Nobody
##    out of earshot of every voice hears it, however near.
##  - kind "bell": the alarm bell, rung where the crime was: heard by those awake within `radius` (bell_tiles), indoors or out (a
##    bell carries through walls); its hearers do not ring it further.
## Every guard who hears learns of the crimes and where the offender was, and comes (a guard in sight of the offender takes them on);
## every villager learns who is cried after (the case's aware list, and their memory). Returns how many guards it reached.
func hue_and_cry(ref: String, cis: Array, at: Vector2, radius: float, kind := "hue_and_cry") -> int:
	var c: Dictionary = cases.get(ref, {})
	var p: PlayerState = w.player_of_ref(ref)
	if c.is_empty() or p == null:
		return 0
	var level: int = w.level_at(at)
	var guards := 0
	var heard := 0
	var shouts := 0
	var crime := _crime_words(c, cis)
	var hearers: Array = []
	if kind == "bell":
		for n: NPC in w.npcs:
			if n.alive and n.role != "bandit" and n.depth == level and not w.asleep(n) and n.pos.distance_to(at) <= radius:
				hearers.append(n)
	else:
		var earshot := float(GameData.b("witness_radius"))
		var reached := {}
		var voices: Array = [at]                    # where the cry is raised, then each hearer who takes it up
		while not voices.is_empty():
			var v: Vector2 = voices.pop_front()
			shouts += 1
			var near: Array = w.near(v, earshot)
			near.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
			for n: NPC in near:
				if reached.has(n.id) or n.role == "bandit" or n.pos.distance_to(at) > radius:
					continue
				reached[n.id] = true
				hearers.append(n)
				if n.job != "guard" and n.role != "child":
					voices.append(n.pos)            # they cry it on
	for n: NPC in hearers:
		heard += 1
		if n.job == "guard":
			learn(n, ref, cis, at, w.minutes)
			if n.target == -1 or Life.is_player_id(n.target):
				if w.sees(n, p):
					engage(n, ref, "pursuing")
				else:
					engage(n, ref, "responding", at, w.minutes)
			guards += 1
		else:
			for ci in cis:
				c.aware[str(n.id)] = maxi(int(c.aware.get(str(n.id), -1)), int(ci))
			var line := ("heard the alarm bell: %s %s" if kind == "bell" else "heard the hue and cry: %s %s") % [c.name, crime]
			if not n.memory.has(line):
				n.remember(line)
	c[kind + "_t"] = w.minutes
	w.stat("justice_" + kind)
	w.stat("justice_" + kind + "_guards", guards)
	w.stat("justice_" + kind + "_heard", heard)
	if shouts > 0:
		w.stat("justice_" + kind + "_voices", shouts)
	if w.recorder != null:
		w.recorder.occurrence("crime", kind, "crime", kind, w.recorder.ref_of(p), [[w.recorder.ref_of(p), "offender"]], [], "ok", "",
				"radius=%d heard=%d guards=%d crimes=%s" % [int(radius), heard, guards, str(cis)], {"x": int(at.x), "y": int(at.y)})
	return guards


## "killed Rose Dale", "attacked Hugh Reed": the gravest of the crimes, as the cry names it.
func _crime_words(c: Dictionary, cis: Array) -> String:
	var best := {}
	for ci in cis:
		var cr: Dictionary = c.crimes[int(ci)]
		if best.is_empty() or severity(str(cr.kind)) > severity(str(best.kind)):
			best = cr
	if best.is_empty():
		return "for a crime"
	var v: NPC = w.npc(int(best.victim))
	var who := ("%s %s" % [v.name, v.family]) if v != null else "someone"
	return ("killed %s" if str(best.kind) == "killing" else "attacked %s") % who


## After crimes of `ref` became known: a second killing known to the authorities rings the bell (the multiple-murder
## tier's alarm), once per killing, from where it was done; heard within bell_tiles.
func escalate(ref: String, cis: Array) -> void:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return
	var all := _known_all(c)
	var kills := all.filter(func(i): return str(c.crimes[i].kind) == "killing" and str(c.crimes[i].settled) != "lapsed").size()
	var outstanding := all.filter(func(i): return str(c.crimes[i].kind) == "killing" and str(c.crimes[i].settled) == "").size()
	if kills >= 2 and outstanding >= 1 and kills > int(c.get("bell_kills", 0)):
		c.bell_kills = kills
		var cr: Dictionary = c.crimes[int(cis.max())] if not cis.is_empty() else c.crimes[all.max()]
		hue_and_cry(ref, all, Vector2(float(cr.at[0]), float(cr.at[1])), float(cfg().bell_tiles), "bell")


## Whether guard `g` may kill `ref` (response.lethal of the tier g knows): never for theft and assault (they beat the
## offender down and take them in), for murder once the offender resisted (struck a guard, killed again with a guard on
## the case), always for multiple murder (owner answer 2: "a known multiple murderer who keeps fighting can still be killed").
func lethal(g: NPC, ref: String) -> bool:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return true
	var l := str(response(tier_for(g, ref)).lethal)
	return l == "always" or (l == "resist" and bool(c.resisted))


## A guard of `ref`'s case the player can yield to: one on the case or knowing of it, in sight; null when none, or when
## the player is not beaten (health above yield_below of its cap; owner answer 2: "a beaten player can yield").
func yield_guard(ref: String) -> NPC:
	var c: Dictionary = cases.get(ref, {})
	var p: PlayerState = w.player_of_ref(ref)
	if c.is_empty() or p == null or not p.alive or p.hp > float(cfg().yield_below) * p.hp_cap():
		return null
	var best: NPC = null
	for key in c.known:
		var g: NPC = w.npc(int(key))
		if g != null and knows(g, ref) and w.sees(g, p) and (best == null or g.pos.distance_to(p.pos) < best.pos.distance_to(p.pos)):
			best = g
	return best


## The offender yields to guard `g` ("yielded") or is beaten down and taken in by one who may not kill ("taken") (owner
## answer 2: "guards take them in and fine them heavily, and take stolen goods back"). The stolen goods they carry go
## back to their owners; they pay the tier's yield_fine plus the theft fine for the goods, to the manor's treasury
## (what they cannot pay is let go: they have nothing more); every outstanding crime is settled, every guard leaves the
## case. The morality ledgers are untouched: what people think of the deeds stays. Returns what the player is told.
func take_in(g: NPC, ref: String, how: String) -> String:
	var p: PlayerState = w.player_of_ref(ref)
	var c: Dictionary = cases.get(ref, {})
	if p == null or c.is_empty():
		return ""
	return w.as_actor(p, _take_in.bind(g, ref, how, c, p))


func _take_in(g: NPC, ref: String, how: String, c: Dictionary, p: PlayerState) -> String:
	var tier := known_tier(ref)
	var rec: Array = w.recorder.guard_begin(g) if w.recorder != null else []
	var back := {}
	var words := []
	p.trim_stolen()
	var ids: Array = p.stolen.keys()
	ids.sort()
	for id in ids:
		var owners: Array = (p.stolen[id] as Dictionary).keys()
		owners.sort_custom(func(a, b): return int(a) < int(b))
		for o in owners:
			var owner: NPC = w.npc(int(o))
			var k := mini(int(p.stolen[id][o]), p.inv.count(str(id)))
			if owner == null or not owner.alive or k <= 0 or not owner.inv.can_add(str(id)):
				continue
			p.inv.remove(str(id), k)
			owner.inv.add(str(id), k)
			p.unmark(str(id), int(o), k)
			back[id] = int(back.get(id, 0)) + k
			words.append("%d %s to %s" % [k, GameData.item_name(str(id)).to_lower(), owner.name])
			w.stat("justice_returned_items", k)
	for slot in ["weapon", "armor", "tool"]:
		if p.get(slot) != "" and not p.inv.has(p.get(slot)):
			p.set(slot, "")
	var fine := int(response(tier).yield_fine) + (World.theft_fine_for(back) if not back.is_empty() else 0)
	var paid := mini(fine, p.coins)
	p.coins -= paid
	w.treasury += paid
	w.stat("gov_fines", paid)
	settle(ref, [], how)
	for key in (c.pursuers as Dictionary).keys():
		var o: NPC = w.npc(int(key))
		if o != null:
			release(o, how)
	if g.target == World.id_of_ref(ref):
		g.target = -1
	g.plan.clear()
	for o: NPC in w.near(p.pos, float(GameData.b("witness_radius"))):
		if o.role != "bandit" and Life.is_player_id(o.target) and w.brain.foe_player(o) == p:
			o.target = -1                       # taken in: the villagers fighting them leave it to the guards
			o.plan.clear()
	g.remember("took %s in" % c.name)
	if w.recorder != null:
		w.recorder.guard_end(rec, g, null, fine, paid, false)
	w.note("The guard %s %s took %s in and fined them %d coins." % [g.name, g.family, c.name, paid])
	var text := ("You yield to the guard %s." % g.name) if how == "yielded" else ("The guard %s beats you down and takes you in." % g.name)
	if not words.is_empty():
		text += " The stolen goods go back: %s." % ", ".join(words)
	text += " You are fined %d coins%s." % [fine, "" if paid == fine else (" and can pay only %d" % paid)]
	return text


## A villager who knows whom the guards are after (the case's aware list: they saw the violence, or heard the hue and cry)
## and sees the offender will tell a guard where (a report, PAR-05's walk; at most once each sighting_minutes). Called
## when the villager decides what to do next, never by a scan of the village.
func sighting(n: NPC) -> bool:
	var refs := cases.keys()
	refs.sort()
	for ref in refs:
		var c: Dictionary = cases[ref]
		if not c.aware.has(str(n.id)) or status(ref) == "clear":
			continue
		var seen: Dictionary = c.get("sighted", {})
		if w.minutes - float(seen.get(str(n.id), -1e9)) < float(cfg().sighting_minutes):
			continue
		var p: PlayerState = w.player_of_ref(ref)
		if not w.sees(n, p):
			continue
		seen[str(n.id)] = w.minutes
		c.sighted = seen
		w.report_crime(n, World.id_of_ref(ref), "sighting", "attack", ref, [int(c.aware[str(n.id)])])
		w.stat("justice_sightings")
		return true
	return false

# ---------------------------------------------------------------- save
func to_dict() -> Dictionary:
	return {"cases": cases.duplicate(true), "closed": closed.duplicate(true)}


func load_dict(d: Dictionary) -> void:
	cases = {}
	for ref in d.get("cases", {}):
		cases[str(ref)] = _norm(d.cases[ref])
	closed = (d.get("closed", []) as Array).map(func(c): return _norm(c))


## JSON brings every number back a float: the indices and ids are ints again.
static func _norm(c: Dictionary) -> Dictionary:
	var o: Dictionary = c.duplicate(true)
	var known := {}
	for key in o.get("known", {}):
		known[str(key)] = (o.known[key] as Array).map(func(i): return int(i))
	o.known = known
	var aware := {}
	for key in o.get("aware", {}):
		aware[str(key)] = int(o.aware[key])
	o.aware = aware
	var pursuers := {}
	for key in o.get("pursuers", {}):
		pursuers[str(key)] = true
	o.pursuers = pursuers
	o.guard_struck = int(o.get("guard_struck", 0))
	o.resisted = bool(o.get("resisted", false))
	for cr in o.get("crimes", []):
		for k in ["day", "victim", "seen", "rec"]:
			cr[k] = int(cr.get(k, -1))
		cr.settled = str(cr.get("settled", ""))
		cr.pursued = bool(cr.get("pursued", false))
	return o
