extends SceneTree
## SIM-GATE-01 (owner, 2026-10-24): the focused probes of the pre-build simulation gate (tools/sim_suite.py), each a small
## reproduction on the real World that writes one JSON result. They change nothing in the game.
##   godot --headless --path game --script res://tests/sim_probes.gd -- --probe saveload [--seed 1] [--days 2] --out r.json
##   godot --headless --path game --script res://tests/sim_probes.gd -- --probe pursuit [--seed 1] [--record DIR] --out r.json
##   godot --headless --path game --script res://tests/sim_probes.gd -- --probe manhunt [--seed 1] --out r.json
##   godot --headless --path game --script res://tests/sim_probes.gd -- --probe playtest [--seed 1] --out r.json
## saveload: a world run for --days is saved (World.to_dict, as JSON text, sorted keys, as the game writes it), loaded into a
##   new World and saved again. Nothing may be dropped or changed (numbers compared by value: 1780 = 1780.0); a key the loader
##   adds (a default filled in) is listed, not failed; the people, coins and items must match; and a second round trip must
##   change nothing at all. Integrity, not resumption: load_dict reseeds the random generator (seed + minutes) by design and a
##   resumed run is not designed (PERF-06), so the two worlds are not compared after more play.
## pursuit: the owner's corner case (docs/design/REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS.md sections 8-9): a guard chasing the player
##   on the far side of a wall with a walkable way round it. The approved requirement GP-CRIME-PURSUIT says the corner must not
##   end the chase and the guard reaches the player by path; the result says whether this build does (`meets_requirement`).
## manhunt (GP-CRIME-PURSUIT A1-A3): the whole village running (World.update), day 1: the player kills a villager in sight
##   of a witness and a guard. Measured: the hue and cry (guards reached out of sight; owner answer 1), the guard's chase,
##   its search of the last-known place once the player is out of sight (never of where the player is), the case wanted
##   when the search ends, the wanted status and the guards' knowledge after save and load (with nobody tracking the player),
##   and a beaten player yielding (owner answer 2): case settled, the fine in the treasury, no coin made or lost.
## playtest (Build 21 recorder audit, owner directive 2026-10-24 section 6): the owner's playtest corrections that a running
##   village can show, measured hour by hour over --days (default 3) of the whole village, then the band killed and watched
##   until outlaws come back (BANDIT-RETURN) and make camp: bandits not dying at once or vanishing without a death, at the
##   camp (or out stalking) at night, coming back a season after the last died; nobody standing on a solid (wall) cell;
##   every station's use cell open, in reach and reached by a path (GP-ANVIL); a villager asked twice the same day does not
##   tell the same news again (GP-DIALOGUE A6). Measured, reported; the gate never blocks on these (they are known-defect
##   watches, not approved thresholds). Static map facts (a trail to every door, GP-BACK-DOORS) are tests/test_village.py's.

const STEP := 0.5                    # economy_sim's step: one game minute


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: String) -> String:
		return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback
	GameData.ensure()
	var probe := str(arg.call("--probe", ""))
	var seed := int(arg.call("--seed", "1"))
	var out := str(arg.call("--out", ""))
	var r := {}
	match probe:
		"saveload":
			r = saveload(seed, int(arg.call("--days", "2")))
		"pursuit":
			r = pursuit(seed, str(arg.call("--record", "")))
		"manhunt":
			r = manhunt(seed)
		"playtest":
			r = playtest(seed, int(arg.call("--days", "3")))
		_:
			printerr("sim_probes: --probe saveload|pursuit|manhunt|playtest")
			quit(2)
			return
	r.probe = probe
	r.seed = seed
	print("PROBE " + JSON.stringify(r))
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify(r, " ", true))
		f.close()
	quit(0)


func new_world(seed: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func run_minutes(w: World, minutes: int) -> void:
	for i in minutes:
		w.update(STEP)
		w.player.hunger = 100.0


func totals(w: World) -> Dictionary:
	var items := 0
	for n: NPC in w.npcs:
		items += n.inv.total() if n.inv.has_method("total") else n.inv.items.size()
	return {"people": w.people.size(), "npcs": w.npcs.size(), "alive": w.npcs.filter(func(n): return n.alive).size(),
		"coins": w.total_coins(), "treasury": w.treasury, "households": w.households.size(), "items": items}


func saveload(seed: int, days: int) -> Dictionary:
	var w := new_world(seed)
	run_minutes(w, days * World.DAY + 11 * 60)             # into a working morning, people mid-errand
	var t0 := Time.get_ticks_msec()
	var text1 := JSON.stringify(w.to_dict(), "", true)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(text1))
	var text2 := JSON.stringify(w2.to_dict(), "", true)
	var ms := Time.get_ticks_msec() - t0
	var a := totals(w)
	var b := totals(w2)
	# Every difference between the two saves, by kind: "added" (a key the first save lacked, filled in by the loader),
	# "dropped" (a key lost), "changed" (a value that differs). Numbers are compared by value (1780 = 1780.0).
	var diffs := []
	if text1 != text2:
		diff_paths(norm(JSON.parse_string(text1)), norm(JSON.parse_string(text2)), "", diffs)
	var kinds := {"added": 0, "dropped": 0, "changed": 0}
	for d in diffs:
		kinds[d.kind] += 1
	# the second round trip must change nothing at all (a loaded save saves as it loaded)
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(text2))
	var text3 := JSON.stringify(w3.to_dict(), "", true)
	var stable := JSON.stringify(norm(JSON.parse_string(text2)), "", true) == JSON.stringify(norm(JSON.parse_string(text3)), "", true)
	w3.dispose()
	var r := {"ok": a == b and int(kinds.dropped) == 0 and int(kinds.changed) == 0 and stable, "identical_text": text1 == text2,
		"differences": kinds, "examples": diffs.slice(0, 20), "second_round_trip_identical": stable, "before": a, "after": b,
		"save_bytes": text1.length(), "save_load_ms": ms, "day": w.day()}
	w.dispose()
	w2.dispose()
	return r


## A JSON value with every whole-number float written as an integer (JSON has one number type; the comparison is by value).
func norm(v):
	if v is Dictionary:
		var o := {}
		for k in v:
			o[k] = norm(v[k])
		return o
	if v is Array:
		return v.map(func(x): return norm(x))
	if v is float and is_equal_approx(v, roundf(v)) and absf(v) < 9.0e15:
		return int(v)
	return v


## Collect the differences between two JSON values (at most 500): {path, kind, before, after}.
func diff_paths(a, b, path: String, out: Array) -> void:
	if out.size() >= 500:
		return
	if a is Dictionary and b is Dictionary:
		var keys: Array = a.keys()
		for k in b:
			if not a.has(k):
				keys.append(k)
		keys.sort()
		for k in keys:
			var p := "%s.%s" % [path, k] if path != "" else str(k)
			if not a.has(k):
				out.append({"path": p, "kind": "added", "before": null, "after": JSON.stringify(b[k]).left(120)})
			elif not b.has(k):
				out.append({"path": p, "kind": "dropped", "before": JSON.stringify(a[k]).left(120), "after": null})
			elif JSON.stringify(a[k], "", true) != JSON.stringify(b[k], "", true):
				diff_paths(a[k], b[k], p, out)
		return
	if a is Array and b is Array and a.size() == b.size():
		for i in a.size():
			if JSON.stringify(a[i], "", true) != JSON.stringify(b[i], "", true):
				diff_paths(a[i], b[i], "%s[%d]" % [path, i], out)
		return
	out.append({"path": path, "kind": "changed", "before": JSON.stringify(a).left(120), "after": JSON.stringify(b).left(120)})


## A wall between a guard and the player, with a way round it: cells A and B on one row, 6 to 10 apart, both open, a solid
## cell between them, and a path from A to B no longer than 4 times the straight distance.
func corner_site(w: World) -> Dictionary:
	var m := w.map
	for y in range(8, m.h - 8):
		for x in range(8, m.w - 8):
			for gap in [8, 6, 10]:
				var a := Vector2i(x, y)
				var b := Vector2i(x + gap, y)
				if m.is_solid(a) or m.is_solid(b) or w.place_of(Vector2(a)) != "" or w.place_of(Vector2(b)) != "":
					continue
				var blocked := false
				for k in range(1, gap):
					blocked = blocked or m.is_solid(Vector2i(x + k, y))
				if not blocked:
					continue
				var path := m.find_path(a, b)
				if path.size() > 1 and path.size() <= gap * 4 and Vector2(b).distance_to(Vector2(w.bandit_camp)) > 14.0:
					return {"a": a, "b": b, "path": path.size()}
	return {}


func pursuit(seed: int, record: String) -> Dictionary:
	var w := new_world(seed)
	run_minutes(w, World.DAY + 11 * 60)                  # day 1, 11:00
	var rec: WorldRecorder = WorldRecorder.attach(w, {"root": record}) if record != "" else null
	var site := corner_site(w)
	var guards := w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")
	if site.is_empty() or guards.is_empty():
		w.dispose()
		return {"ok": false, "error": "no corner site or no guard on this map", "meets_requirement": false}
	var g: NPC = guards[0]
	var a: Vector2i = site.a
	var b: Vector2i = site.b
	g.pos = Vector2(a) + Vector2(0.5, 0.5)
	g.plan.clear()
	g.depth = 0
	w.player.pos = Vector2(b) + Vector2(0.5, 0.5)
	w.player_level = 0
	g.target = Life.PLAYER_ID
	var start_d := g.pos.distance_to(w.player.pos)
	var min_d := start_d
	var held_ticks := 0
	var dropped_at := -1
	var hp0 := w.player.hp
	for i in 120:                                         # two game hours (one real minute) of chase
		var ppos := w.player.pos
		w.update(STEP)
		w.player.pos = ppos                               # the player stands still behind the wall
		w.player.hunger = 100.0
		min_d = minf(min_d, g.pos.distance_to(w.player.pos))
		if Life.is_player_id(g.target):
			held_ticks += 1
		elif dropped_at < 0:
			dropped_at = i
		if not w.player.alive:
			break
	var reason := ""
	if rec != null:
		rec.hour()
		rec.flush()
		for e in RecorderArchive.read_table(FlightRecorder._abs(rec.dir), "event"):
			if e.subtype == "chase_guard" and e.actor == "p:%d" % g.id:
				reason = str(e.reason)
				break
	var reached := min_d <= 1.5 or w.player.hp < hp0
	var r := {"site": {"guard": [a.x, a.y], "player": [b.x, b.y], "path_cells": site.path, "straight_tiles": snappedf(start_d, 0.01)},
		"chase_held_minutes": held_ticks, "dropped_after_minutes": dropped_at, "closest_tiles": snappedf(min_d, 0.01), "reached_player": reached,
		"end_reason": reason, "guard_doing_after": g.doing, "meets_requirement": reached and reason != "blocked", "ok": true,
		"requirement": "GP-CRIME-PURSUIT: a corner does not end the chase; the guard reaches the player by path"}
	w.dispose()
	return r



func manhunt(seed: int) -> Dictionary:
	var w := new_world(seed)
	run_minutes(w, World.DAY + 10 * 60)                  # day 1, 10:00
	var p := w.player
	p.max_hp = 9999.0
	p.hp = 9999.0
	var guards := w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "guard")
	var victims := w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n.depth == 0 and w.place_of(n.pos) == "")
	if guards.is_empty() or victims.size() < 2:
		w.dispose()
		return {"ok": false, "error": "no guard or no villager outdoors", "meets_requirement": false}
	# the scene: a victim outdoors, a guard 5 tiles off, a witness 3 tiles off (moved there: the probe stages the crime)
	var v: NPC = victims[0]
	var g: NPC = guards[0]
	var wit: NPC = victims[1]
	for o in [g, wit]:
		o.plan.clear()
		o.anim = "idle"
		o.depth = 0
	var at := v.pos
	g.pos = _open_near(w, at, 5.0)
	wit.pos = _open_near(w, at, 3.0)
	p.pos = at + Vector2(0.5, 0)
	p.map_level = 0
	var coins0 := w.total_coins()
	for k in 30:
		if w.player_hit_npc(v, 20.0).killed:
			break
	var r := {"killed": not v.alive, "tier": w.justice.known_tier("player"), "hue_and_cry": int(w.stats.get("justice_hue_and_cry", 0)),
		"hue_and_cry_guards": int(w.stats.get("justice_hue_and_cry_guards", 0)), "guards": guards.size(), "chasing_after_crime": g.target == Life.PLAYER_ID}
	# flight: the player is set 35 tiles off (out of anyone's sight); the village runs a game hour
	var seen_at := p.pos
	p.pos = _open_near(w, at, 35.0)
	var hideout := p.pos
	var closest := 1e9
	var searched := false
	var searched_last_known := false
	for i in 60:
		w.update(STEP)
		p.pos = hideout
		p.hunger = 100.0
		closest = minf(closest, g.pos.distance_to(hideout))
		if str(g.pursuit.get("state", "")) == "searching":
			searched = true
			var lk: Array = g.pursuit.at
			searched_last_known = searched_last_known or Vector2(float(lk[0]), float(lk[1])).distance_to(seen_at) < 3.0
	var c: Dictionary = w.justice.case_of("player")
	r.searched = searched
	r.searched_from_last_known = searched_last_known
	r.guard_closest_to_hideout = snappedf(closest, 0.01)
	r.last_known_is_hideout = not (c.get("last", []) as Array).is_empty() and Vector2(float(c.last[0]), float(c.last[1])).distance_to(hideout) < 1.0
	r.guards_knowing = guards.filter(func(o: NPC) -> bool: return w.justice.knows(o, "player")).size()
	r.hunting = guards.filter(func(o: NPC) -> bool: return not o.pursuit.is_empty()).size()
	# the search runs out: the case goes over to wanted
	w.minutes += float(Justice.response(str(r.tier)).search_minutes) + 1.0
	for i in 4:
		w.update(STEP)
		p.pos = hideout
	run_minutes(w, 30)
	p.pos = hideout
	r.status_after_search = w.justice.status("player")
	r.on_case_after_search = guards.filter(func(o: NPC) -> bool: return not o.pursuit.is_empty()).map(func(o: NPC) -> String: return "%d %s until %.0f now %.0f t %.0f" % [o.id, str(o.pursuit.state), float(o.pursuit.until), w.minutes, float(o.pursuit.t)])
	# save and load the wanted world
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	r.status_after_load = w2.justice.status("player")
	r.guards_knowing_after_load = w2.npcs.filter(func(o: NPC) -> bool: return o.alive and o.job == "guard" and w2.justice.knows(o, "player")).size()
	r.tier_after_load = w2.justice.known_tier("player")
	# the wanted player walks up to a guard who knows, is beaten and yields
	var g2: NPC = w2.npc(g.id)
	g2.plan.clear()
	g2.anim = "idle"
	w2.player.pos = _open_near(w2, g2.pos, 3.0)
	w2.player.max_hp = 40.0
	w2.player.hp = 5.0
	w2.player.coins = 40
	var t0 := w2.treasury
	var c0 := w2.total_coins()
	var y := w2.player_yield()
	r.yielded = bool(y.ok)
	r.yield_text = str(y.text)
	r.status_after_yield = w2.justice.status("player")
	r.fine_paid = w2.treasury - t0
	r.coins_conserved = w2.total_coins() == c0 and w.total_coins() <= coins0 + w.coin_sources
	r.meets_requirement = bool(r.killed) and int(r.hue_and_cry) >= 1 and bool(r.searched) and bool(r.searched_from_last_known) \
			and not bool(r.last_known_is_hideout) and str(r.status_after_search) == "wanted" and str(r.status_after_load) == "wanted" \
			and int(r.guards_knowing_after_load) >= 1 and bool(r.yielded) and str(r.status_after_yield) == "clear" and int(r.fine_paid) > 0 \
			and w2.total_coins() == c0
	r.requirement = "GP-CRIME-PURSUIT A1-A3: the hue and cry; a search of the last-known place, never of where the player is; wanted after the search and after save and load; a beaten player yields, fined to the treasury"
	r.ok = true
	w.dispose()
	w2.dispose()
	return r


## The open outdoor cell `d` tiles from `at` in the first of 16 directions that has one (and a path from `at`).
func _open_near(w: World, at: Vector2, d: float) -> Vector2:
	for k in 16:
		var c := Vector2i((at + Vector2.RIGHT.rotated(TAU * k / 16.0) * d).floor())
		if not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == "" and w.map.find_path(Vector2i(at.floor()), c).size() > 0:
			return Vector2(c) + Vector2(0.5, 0.5)
	return at


# ---------------------------------------------------------------- playtest -----------------------
func playtest(seed: int, days: int) -> Dictionary:
	var w := new_world(seed)
	var camp := Vector2(w.bandit_camp) + Vector2(0.5, 0.5)
	var bandits := {}                        # id -> {name, first (minute), died (minute or -1), cause}
	var cause_of := {}
	var last_cause := [""]
	w.event.connect(func(t: String):
		var at := t.find("has died (")
		if at >= 0:
			last_cause[0] = t.substr(at + 10, t.rfind(")") - at - 10))
	w.npc_died.connect(func(n: NPC):
		cause_of[n.id] = last_cause[0]
		last_cause[0] = "")
	var on_wall := [0]                       # (an array: the closure below counts into it)
	var on_wall_examples := []
	var night := {"samples": 0, "at_camp": 0, "stalking": 0, "elsewhere": 0, "elsewhere_examples": []}
	var vanished := []
	var watch := func() -> void:
		for n: NPC in w.npcs:
			if n.role == "bandit":
				if not bandits.has(n.id):
					bandits[n.id] = {"name": n.name, "first": w.minutes, "died": -1.0, "cause": ""}
				if not n.alive and float(bandits[n.id].died) < 0.0:
					bandits[n.id].died = w.minutes
					bandits[n.id].cause = str(cause_of.get(n.id, "(no death recorded)"))
			if n.alive and n.depth == 0 and w.map.is_solid(Vector2i(floori(n.pos.x), floori(n.pos.y))):
				on_wall[0] += 1
				if on_wall_examples.size() < 8:
					on_wall_examples.append("day %d %02d:00 %s %s (%s) at %s" % [w.day(), w.hour(), n.name, n.family, n.doing, str(Vector2i(n.pos.floor()))])
		for id in bandits:
			if float(bandits[id].died) < 0.0 and (w.npc(int(id)) == null or not w.by_id.has(int(id))):
				if not vanished.has(id):
					vanished.append(id)
		var h := w.hour()
		if h >= 1 and h <= 3:
			for n: NPC in w.npcs:
				if n.alive and n.role == "bandit":
					night.samples += 1
					if n.pos.distance_to(camp) <= 8.0:
						night.at_camp += 1
					elif n.doing == "stalking" or n.target != -1:
						night.stalking += 1
					else:
						night.elsewhere += 1
						if (night.elsewhere_examples as Array).size() < 6:
							night.elsewhere_examples.append("day %d %02d:00 %s (%s) %.0f tiles from camp" % [w.day(), h, n.name, n.doing, n.pos.distance_to(camp)])
	var stations0 := _stations_check(w)
	watch.call()
	for hr in days * 24:
		run_minutes(w, 60)
		watch.call()
	var stations1 := _stations_check(w)
	var first_band: Array = bandits.keys()
	var alive0 := w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "bandit").size()
	# the band is killed (as the player or the guards might); outlaws should come back a season later and make camp
	for n: NPC in w.npcs.duplicate():
		if n.alive and n.role == "bandit":
			w.kill(n, "slain in the probe")
	var killed_day := w.day()
	var arrived0 := int(w.stats.get("outlaws_arrived", 0))
	var wait := Outlaws.wait_days()
	var back_at := -1
	for hr in (wait + 2) * 24:
		run_minutes(w, 60)
		watch.call()
		if back_at < 0 and int(w.stats.get("outlaws_arrived", 0)) > arrived0:
			back_at = w.day()
	var newcomers := w.npcs.filter(func(n: NPC) -> bool: return n.role == "bandit" and not first_band.has(n.id))
	var new_alive := newcomers.filter(func(n: NPC) -> bool: return n.alive)
	var new_at_camp := new_alive.filter(func(n: NPC) -> bool: return n.pos.distance_to(camp) <= 8.0 or n.doing == "stalking" or n.target != -1)
	# gossip: each grown villager asked for news twice in one day
	var told := 0
	var repeated := 0
	var rep_examples := []
	for n: NPC in w.npcs:
		if not n.alive or n.role != "adult" or n.depth != 0:
			continue
		var a := Dialogue.news(w, n)
		var b := Dialogue.news(w, n)
		var fresh := a.split(". ", false)
		var again := 0
		for sent: String in fresh:
			if sent.length() > 25 and b.contains(sent.strip_edges().trim_suffix(".")):
				again += 1
		if a != b or again > 0:
			told += 1
		if again > 0:
			repeated += 1
			if rep_examples.size() < 4:
				rep_examples.append("%s %s: %s | then: %s" % [n.name, n.family, a.left(160), b.left(160)])
	var quick := []
	for id in bandits:
		var lived := float(bandits[id].died) - float(bandits[id].first) if float(bandits[id].died) >= 0.0 else -1.0
		if lived >= 0.0 and lived < 120.0 and not str(bandits[id].cause).contains("probe"):
			quick.append("%s died %.0f minutes after appearing (%s)" % [bandits[id].name, lived, bandits[id].cause])
	var deaths := []
	for id in bandits:
		if float(bandits[id].died) >= 0.0 and not str(bandits[id].cause).contains("probe"):
			deaths.append("%s day %d (%s)" % [bandits[id].name, int(float(bandits[id].died) / World.DAY), bandits[id].cause])
	var r := {"days": days, "bandits_at_start": first_band.size(), "bandits_alive_before_kill": alive0, "bandit_deaths_in_play": deaths,
		"bandits_dead_within_2_hours": quick, "bandits_vanished_without_death": vanished.size(), "night": night,
		"band_killed_day": killed_day, "season_days": wait, "outlaws_back_day": back_at, "outlaws_arrived": int(w.stats.get("outlaws_arrived", 0)) - arrived0,
		"outlaws_alive": new_alive.size(), "outlaws_at_camp_or_stalking": new_at_camp.size(),
		"on_solid_cell_npc_hours": on_wall[0], "on_solid_examples": on_wall_examples,
		"stations_day0": stations0, "stations_end": stations1,
		"gossip": {"asked": told, "repeated": repeated, "examples": rep_examples}, "coins_total_end": w.total_coins(), "ok": true}
	r.bandits_ok = quick.is_empty() and vanished.is_empty() and (back_at >= 0 and new_alive.size() >= 2)
	r.walls_ok = on_wall[0] == 0
	r.stations_ok = (stations0.bad as Array).is_empty() and (stations1.bad as Array).is_empty()
	r.gossip_ok = repeated == 0
	w.dispose()
	return r


## GP-ANVIL: every station's use cell is open ground, no other station stands on it, the station is in reach from it, and a
## path leads to it from the village's open ground (the player's start).
func _stations_check(w: World) -> Dictionary:
	var bad := []
	var from := Vector2i(w.player.pos.floor())
	var ats := {}
	for id in w.stations:
		var st: Dictionary = w.stations[id]
		if st.has("at"):
			ats[Vector2i(int(st.at[0]), int(st.at[1]))] = id
	var ids: Array = w.stations.keys()
	ids.sort()
	for id in ids:
		var st: Dictionary = w.stations[id]
		var use := Vector2i(int(st.use[0]), int(st.use[1]))
		if w.map.is_solid(use):
			bad.append("%s: its use cell %s is solid" % [id, str(use)])
		elif ats.has(use) and str(ats[use]) != str(id):
			bad.append("%s: its use cell %s holds %s" % [id, str(use), ats[use]])
		elif not World.station_in_reach(st, Vector2(use) + Vector2(0.5, 0.5), Vector2.ZERO):
			bad.append("%s: not in reach from its use cell" % id)
		elif use != from and w.map.find_path(from, use).size() == 0:
			bad.append("%s: no path to its use cell %s" % [id, str(use)])
	return {"stations": ids.size(), "bad": bad}
