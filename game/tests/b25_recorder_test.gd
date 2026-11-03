extends SceneTree
## B25R1-016 (owner directive 2026-11-03): the flight recorder's living-world vocabulary (docs/design/FLIGHT_RECORDER.md
## section 9). WorldRecorder.chronicle writes one event with the kind's system and stage, the person's stable ref and live
## context, a decision with its alternatives, faction changes and summary rows that the coin audit does not count twice; an
## unknown kind is counted. The road hooks record formation, paving and fading; landmarks their discovery; the dawn census the
## population and clans. Recording changes nothing: the road state and the world are identical with and without it.
## Run headless:
##   godot --headless --path game --script res://tests/b25_recorder_test.gd

var failures := 0
var checks := 0
var tmp_root := ""


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	tmp_root = OS.get_cache_dir() + "/mml_b25_recorder_test_%d" % int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(tmp_root)
	test_codes_table()
	test_chronicle()
	test_roads()
	test_landmark_and_census()
	test_adapters()
	test_recording_changes_nothing()
	print("%d checks, %d failures" % [checks, failures])
	_remove(tmp_root)
	quit(1 if failures > 0 else 0)


func _remove(path: String) -> void:
	for d in DirAccess.get_directories_at(path):
		_remove(path + "/" + d)
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func sub(name: String) -> String:
	var p := tmp_root + "/" + name
	DirAccess.make_dir_recursive_absolute(p)
	return p


func run_minutes(w: World, minutes: int) -> void:
	for i in minutes:
		w.update(0.5)
		w.player.hunger = 100.0


func rows(rec: WorldRecorder, table: String) -> Array:
	rec.flush()
	return RecorderArchive.read_table(FlightRecorder._abs(rec.dir), table)


func evs(rec: WorldRecorder, subtype: String) -> Array:
	return rows(rec, "event").filter(func(e): return e.subtype == subtype)


func of_event(rec: WorldRecorder, table: String, ev: int) -> Array:
	return rows(rec, table).filter(func(r): return int(r.event) == ev)


func ctx(rec: WorldRecorder, ev: int) -> Dictionary:
	var out := {}
	for f in of_event(rec, "factor", ev):
		out["%s.%s" % [f.option, f.factor]] = f.value
	return out


## A cell of open country whose generated level is grass.
func grass_cell(ow: Overworld) -> Vector2i:
	for x in range(ow.village.end.x + 6, ow.village.end.x + 200):
		var c := Vector2i(x, ow.village.position.y + 40)
		if RoadWear.base_level(ow, c) == 0 and not ow.road_state.has(c):
			return c
	return Vector2i(-1, -1)


# ----------------------------------------------------------------------------
func test_codes_table() -> void:
	var codes := FlightRecorder.default_codes()
	var ch: Dictionary = codes.get("chronicle", {})
	var bad := []
	for k in ch:
		var s: Array = ch[k]
		if s.size() != 5 or not (codes.systems as Array).has(s[0]) or not (codes.subsystems as Array).has(s[1]) or not (codes.categories as Array).has(s[2]):
			bad.append(k)
	check(bad.is_empty(), "every chronicle kind names a listed system, subsystem and category (bad: %s)" % str(bad))
	var stages := []
	for k in ch:
		if str(k).begins_with("homestead_") and int(ch[k][3]) > 0:
			if not stages.has(int(ch[k][3])):
				stages.append(int(ch[k][3]))
	stages.sort()
	check(stages == [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] and int(ch.life_transition[3]) == 1, "the twelve homestead stages each have their own kinds (stage 1 is life_transition): %s" % str(stages))
	for src_kind in ["recruit_circumstance", "recruit_sought", "recruit_contact", "recruit_accepted", "recruit_rejected", "recruit_joined",
			"bandit_departed", "bandit_reintegrated", "runaway_evaluated", "runaway_outcome", "settlement_affiliation", "raid", "journey_end",
			"road_formed", "road_paved", "landmark_discovered", "wild_production"]:
		check(ch.has(src_kind), "the vocabulary has " + src_kind)


func test_chronicle() -> void:
	var w := new_world()
	var rec := WorldRecorder.attach(w, {"root": sub("chron")})
	run_minutes(w, 61)                              # past the first hour: the coin audit has its balances
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0:
			n = o
			break
	var before_alerts := int(rec.counts.alert)
	var ev := rec.chronicle("homestead_evaluated", n, {"trigger": "household_crowded", "track": "young_adult", "chosen": "homestead",
		"alternatives": [["stay", true, 400, ""], ["homestead", true, 700, ""], ["migrate", false, 0, "no_signal"]],
		"needs": {"food_days": 2.5, "purse": 12}, "factors": {"ambition": 600}, "related": {"parent": ["p:%d" % n.mother]},
		"summary": [["p:%d" % n.id, "coins", n.coins, n.coins + 5]], "reason": "crowded_house", "object": "homestead:test"})
	var e: Array = rows(rec, "event").filter(func(r): return int(r.id) == ev)
	check(e.size() == 1 and e[0].system == "homestead" and e[0].category == "homestead" and e[0].actor == "p:%d" % n.id,
		"chronicle: one event, system and category from the table, the actor the person's permanent ref")
	check(not e.is_empty() and e[0].rule == "household_crowded" and e[0].reason == "crowded_house" and e[0].object == "homestead:test",
		"chronicle: trigger as rule, the system's own reason, the object thread")
	var c := ctx(rec, ev)
	check(str(c.get("ctx.name", "")) == "%s %s" % [n.name, n.family] and float(c.get("ctx.age", -1)) > 0 and str(c.get("ctx.stage", "")) == "adult"
		and str(c.get("ctx.household", "")) == "hh:%d" % n.household and str(c.get("ctx.faction", "")) == "village" and int(c.get("ctx.stage_no", 0)) == 2,
		"chronicle: name, age, life stage, household, faction and stage number read from the live record (%s)" % str(c))
	check(float(c.get("needs.food_days", 0)) == 2.5 and int(c.get("judgment.ambition", 0)) == 600 and str(c.get("ctx.track", "")) == "young_adult",
		"chronicle: needs, judgment factors and the track as factor rows")
	var dec := of_event(rec, "decision", ev)
	var alts := of_event(rec, "alternative", ev)
	check(dec.size() == 1 and dec[0].chosen == "homestead" and dec[0].kind == "life_choice" and alts.size() == 3,
		"chronicle: the decision and its three alternatives")
	check(of_event(rec, "participant", ev).any(func(p): return p.role == "parent"), "chronicle: related people as participants")
	var sc := of_event(rec, "state_change", ev)
	check(sc.size() == 1 and sc[0].authority == "summary", "chronicle: a restated coin move is a summary row")
	run_minutes(w, 61)
	check(rows(rec, "alert").filter(func(a): return str(a.rule).begins_with("coin.") and str(a.entities) == "p:%d" % n.id).is_empty(),
		"the summary row is not counted by the coin audit (no unattributed alert for the person)")
	var ev2 := rec.chronicle("recruit_joined", n.id, {"faction_before": "village", "faction": "clan:bandit", "legal_before": "lawful", "legal": "outlaw", "source": "voluntary"})
	var sc2 := of_event(rec, "state_change", ev2)
	check(sc2.size() == 2 and sc2.any(func(s): return s.prop == "faction" and s.before == "village" and s.after == "clan:bandit"),
		"chronicle: faction and legal standing as state changes on the same ref (an int id resolves to the NPC)")
	var ev3 := rec.chronicle("no_such_kind", null, {})
	check(ev3 > 0 and int(rec.unknown_codes.get("chronicle:no_such_kind", 0)) == 1, "an unknown kind is written and counted in unknown_codes")
	rec.unknown_codes.erase("chronicle:no_such_kind")
	check(rec.unknown_codes.is_empty(), "every other code used is listed (%s)" % str(rec.unknown_codes))
	w.dispose()


func test_roads() -> void:
	var w := new_world()
	var rec := WorldRecorder.attach(w, {"root": sub("roads")})
	var ow: Overworld = w.map.overworld
	check(ow.recorder == rec, "attach gives the overworld the recorder")
	var c := grass_cell(ow)
	check(c.x >= 0, "a grass cell outside the village (%s)" % str(c))
	rec.roads_dawn(ow)
	for i in 20:
		RoadWear.foot(ow, c)
	check(RoadWear.level(ow, c) == 1, "twenty steps wear a trail")
	var formed := evs(rec, "road_formed").filter(func(e): return e.object == "cell:%d,%d" % [c.x, c.y])
	check(formed.size() == 1, "one road_formed event when the grass became a trail")
	if not formed.is_empty():
		var lv := of_event(rec, "state_change", int(formed[0].id)).filter(func(s): return s.prop == "level")
		check(lv.size() == 1 and int(lv[0].before) == 0 and int(lv[0].after) == 1, "its level row: 0 -> 1")
	rec.roads_dawn(ow)                               # today's dawn (already seen): nothing new
	ow.clock += 1440.0 * 2.0
	rec.roads_dawn(ow)
	check(RoadWear.level(ow, c) == 0 and evs(rec, "road_faded").size() == 1, "two days unwalked: the trail faded, one road_faded event at dawn")
	check(evs(rec, "roads_day").size() >= 2, "a roads_day census each dawn")
	var c2 := grass_cell(ow)
	for i in 40:
		RoadWear.foot(ow, c2)
	RoadWear.pave(ow, c2, "npc:%d" % w.npcs[0].id)
	var paved := evs(rec, "road_paved")
	check(paved.size() == 1 and paved[0].actor == "p:%d" % w.npcs[0].id and paved[0].object == "cell:%d,%d" % [c2.x, c2.y],
		"paving: one road_paved event naming the paver by their permanent ref")
	w.dispose()


func test_landmark_and_census() -> void:
	var w := new_world()
	var rec := WorldRecorder.attach(w, {"root": sub("census")})
	var all := Landmarks.all(w)
	check(not all.is_empty(), "the world has landmarks")
	if not all.is_empty():
		var lm: Dictionary = all[0]
		w.player.pos = Vector2(lm.at) + Vector2(0.5, 0.5)
		w.player.landmark_cell = Vector2i(-999, -999)
		Landmarks.note(w, w.player)
		var found := evs(rec, "landmark_discovered")
		check(found.size() == 1 and found[0].settlement == "landmark:" + str(lm.id) and found[0].actor == WorldRecorder.ref_of(w.player),
			"landmark_discovered: the place and the player's ref")
	run_minutes(w, 25 * 60)
	var pop := evs(rec, "population_day")
	check(not pop.is_empty(), "a population_day census at dawn")
	if not pop.is_empty():
		var c := ctx(rec, int(pop[0].id))
		var alive := 0
		for n: NPC in w.npcs:
			if n.alive:
				alive += 1
		check(int(c.get("needs.alive", -1)) > 0 and c.has("needs.households") and c.has("needs.stage:adult"), "the census has the living, households and life stages (%d alive now)" % alive)
	var bandits := w.npcs.filter(func(n): return n.alive and n.role == "bandit").size()
	var cc := evs(rec, "clan_census")
	check(bandits == 0 or cc.any(func(e): return e.settlement == "clan:bandit"), "a clan_census row for the village camp's band when it has members (%d)" % bandits)
	w.dispose()


## The same footfall and the same day with and without the recorder: the road state and the world are identical.
func test_recording_changes_nothing() -> void:
	var a := new_world()
	var b := new_world()
	WorldRecorder.attach(b, {"root": sub("same")})
	for w in [a, b]:
		var ow: Overworld = w.map.overworld
		var c := grass_cell(ow)
		for i in 30:
			RoadWear.foot(ow, c)
		RoadWear.pave(ow, c + Vector2i(1, 0))
		ow.clock += 1440.0
		RoadWear.prune(ow)
		run_minutes(w, 26 * 60)
	check(JSON.stringify(RoadWear.to_save(a.map.overworld)) == JSON.stringify(RoadWear.to_save(b.map.overworld)), "the road state is identical with the recorder on")
	check(JSON.stringify(a.to_dict(), "", true).md5_text() == JSON.stringify(b.to_dict(), "", true).md5_text() and a.rng.state == b.rng.state,
		"the world and its random state are identical with the recorder on")
	a.dispose()
	b.dispose()


## The other systems' own calls (Journeys.record -> journey_event, Homesteads / LifeDecisions -> life_event) land on the vocabulary.
func test_adapters() -> void:
	var w := new_world()
	var rec := WorldRecorder.attach(w, {"root": sub("adapt")})
	var n: NPC = w.npcs.filter(func(o): return o.alive and o.role == "adult")[0]
	rec.journey_event(n.id, World.npc_ref(n.id), "started", {"from": "village", "to": "higham", "purpose": {"kind": "buy"}, "trigger": "buy", "coins": 9})
	rec.journey_event(n.id, World.npc_ref(n.id), "arrived", {"to": "higham", "since": 0})
	rec.journey_event(n.id, World.npc_ref(n.id), "ended", {"to": "higham", "how": "died"})
	var b := evs(rec, "journey_begin")
	var e := evs(rec, "journey_end")
	check(b.size() == 1 and e.size() == 1 and b[0].object == e[0].object and b[0].object.begins_with("journey:%d:" % n.id) and e[0].outcome == "failed" and e[0].reason == "died",
		"journey_event: begin and end share the journey's object key; a death on the road ends it failed")
	check(evs(rec, "journey_leg").size() == 1 and evs(rec, "journey_leg")[0].settlement == "settlement:higham", "journey_event: the arrival is a leg at the settlement")
	rec.life_event("homestead_set_out", {"claim": "hs1", "household": "hh:30", "from": "hh:%d" % n.household, "people": [n.id], "path": "young", "site": [200, 40], "why": "crowded", "day": 0})
	rec.life_event("homestead_built", {"claim": "hs1", "owner": "hh:30", "cost": {}, "house": "b1", "day": 0})
	var res := evs(rec, "homestead_residence")
	check(evs(rec, "homestead_travel_begin").size() == 1 and res.size() == 1 and res[0].actor == "p:%d" % n.id and res[0].object == "homestead:hs1",
		"life_event: set out and built map to travel_begin and residence on the founder, the claim as homestead:hs1")
	check(str(ctx(rec, int(res[0].id)).get("ctx.track", "")) == "young_adult", "life_event: the claim's track is remembered (young -> young_adult)")
	rec.life_event("band_recruit", {"person": n.id, "leader": w.npcs[0].id, "answer": "accept", "source": "displaced", "band": 4, "age": 20.0, "day": 0})
	var j := evs(rec, "recruit_joined")
	check(j.size() == 1 and evs(rec, "recruit_accepted").size() == 1 and str(ctx(rec, int(j[0].id)).get("ctx.source", "")) == "displaced_adult",
		"life_event: an accepted recruit is accepted and joined, source displaced_adult")
	rec.life_event("water_source_selected", {"claim": "hs1", "source": "stream", "cell": [200, 41], "distance": 6, "day": 0})
	rec.life_event("settlement_attempt_failed", {"person": n.id, "reason": "no_water", "day": 0})
	var fa := evs(rec, "settlement_attempt_failed")
	check(evs(rec, "water_source_selected").size() == 1 and fa.size() == 1 and fa[0].outcome == "failed" and fa[0].reason == "no_water",
		"life_event: B25R1-017 water source and a failed settlement attempt (outcome failed, reason no_water)")
	rec.life_event("something_new", {"day": 0, "person": n.id})
	var u := evs(rec, "unmapped_event")
	check(u.size() == 1 and u[0].detail == "life_event:something_new", "life_event: an unknown kind is kept as unmapped_event (the exception report lists it)")
	check(rec.unknown_codes.is_empty(), "the adapters use listed codes only (%s)" % str(rec.unknown_codes))
	w.dispose()
