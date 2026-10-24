extends SceneTree
## Guard pursuit of the player (REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS step S3; owner directive 2026-10-24, open item 03 B
## and G: "Turning one corner does not terminate pursuit"). Rebuilt from the audit's reproduction: a guard 8 tiles from
## the player with a wall between them and a walkable way round it.
##   - the guard chasing the player follows the path round the wall and reaches them;
##   - a bandit chasing the player, and a guard chasing a bandit, still give up at the wall (SIM-F4, unchanged);
##   - a report that reaches a guard too far off to chase sends the guard to the reported place, where they take on
##     the offender if they are still there; one within reach takes them on at once, as before.
## GP-CRIME-PURSUIT A2 (the pursuit state machine, on the case record):
##   - a guard on a case who loses sight searches the last-known place (never where the player really is), then nearby;
##   - sight restored brings the chase back; turning a corner or running past 25 tiles does not end it;
##   - a search that finds nothing ends with the case wanted: the guard remembers, a later sighting starts the chase again;
##   - the hunt survives save and load; the authorities never know where the player is unless someone sees them.
## Run headless:
##   godot --headless --path game --script res://tests/pursuit_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	test_corner()
	test_sim_f4_unchanged()
	test_late_report()
	test_case_chase()
	test_search_and_wanted()
	test_report_responds()
	test_wanted_save_load()
	print("pursuit_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _open(w: World, c: Vector2i) -> bool:
	return not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == ""


func _guard(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard":
			return n
	return null


## The audit's corner: a solid run of 3..13 cells on a row, open 3 cells before it and 2 after, with a path round.
## Returns [a, b] (chaser's cell, target's cell) and clears everyone else from around it.
func _corner(w: World, keep: Array) -> Array:
	for y in range(50, 130):
		for x in range(50, 170):
			if not w.map.is_solid(Vector2i(x, y)):
				continue
			var k := 0
			while w.map.is_solid(Vector2i(x + k, y)) and k < 14:
				k += 1
			if k < 3 or k >= 14:
				continue
			var a := Vector2i(x - 3, y)
			var b := Vector2i(x + k + 2, y)
			if not (_open(w, a) and _open(w, b)) or w.map.is_solid(Vector2i(x - 1, y)) or w.map.is_solid(Vector2i(x + k, y)):
				continue
			if w.map.find_path(a, b).size() == 0 or Vector2(b).distance_to(Vector2(w.bandit_camp)) < 14.0:
				continue
			for n: NPC in w.npcs:
				if not keep.has(n) and n.alive and n.pos.distance_to(Vector2(a)) < 20.0:
					n.pos = Vector2(a) + Vector2(60, 60)
			return [a, b]
	return []


func _chase(w: World, chaser: NPC, seconds: float) -> float:
	var t := 0.0
	while chaser.target != -1 and t < seconds:
		w.brain.fight(chaser, 0.05)
		t += 0.05
		if chaser.anim == "sword":
			break
	return t


func test_corner() -> void:
	var w := _world()
	var g := _guard(w)
	var ab := _corner(w, [g])
	check(not ab.is_empty(), "a wall with a way round it")
	var a: Vector2i = ab[0]
	var b: Vector2i = ab[1]
	g.pos = Vector2(a) + Vector2(0.5, 0.5)
	w.player.pos = Vector2(b) + Vector2(0.5, 0.5)
	g.target = Life.PLAYER_ID
	g.plan.clear()
	print("     guard %s at %s, player at %s (%.1f tiles), path round the wall %d steps" % [g.name, a, b, g.pos.distance_to(w.player.pos), w.map.find_path(a, b).size()])
	var hp0 := w.player.hp
	var t := _chase(w, g, 20.0)
	print("     after %.2f s: target %d, guard at %s, %.2f tiles from the player, anim %s" % [t, g.target, g.pos, g.pos.distance_to(w.player.pos), g.anim])
	check(g.target == Life.PLAYER_ID, "the guard does not give up the chase at the wall")
	check(g.pos.distance_to(w.player.pos) <= 1.2, "the guard goes round it and reaches the player")
	check(g.anim == "sword" and w.player.hp < hp0, "and strikes")
	check(not w.map.is_solid(g.cell()), "never walking through the wall")
	# the player moves on round the corner: the guard re-routes after them
	w.player.pos = Vector2(a) + Vector2(0.5, 0.5)
	g.attack_cd = 0.0
	t = _chase(w, g, 25.0)
	check(g.target == Life.PLAYER_ID and g.pos.distance_to(w.player.pos) <= 1.2, "when the player goes back round the wall, the guard follows again (%.2f s)" % t)
	w.dispose()


func test_sim_f4_unchanged() -> void:
	var w := _world()
	var bandit: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			bandit = n
			break
	var g := _guard(w)
	var ab := _corner(w, [g, bandit])
	var a: Vector2i = ab[0]
	var b: Vector2i = ab[1]
	# a bandit chasing the player at the wall gives up and goes back to the camp (SIM-F4)
	bandit.pos = Vector2(a) + Vector2(0.5, 0.5)
	w.player.pos = Vector2(b) + Vector2(0.5, 0.5)
	bandit.target = Life.PLAYER_ID
	bandit.plan.clear()
	g.pos = Vector2(a) + Vector2(60, 60)
	_chase(w, bandit, 20.0)
	check(bandit.target == -1 and not bandit.plan.is_empty() and bandit.plan[0].k == "go", "a bandit blocked by a wall gives up the player and heads for the camp, as before (SIM-F4)")
	# a guard chasing a bandit at the wall gives up as before
	bandit.pos = Vector2(b) + Vector2(0.5, 0.5)
	bandit.target = -1
	bandit.plan.clear()
	w.player.pos = Vector2(b) + Vector2(30, 0)
	g.pos = Vector2(a) + Vector2(0.5, 0.5)
	g.target = bandit.id
	g.plan.clear()
	_chase(w, g, 20.0)
	check(g.target == -1 and g.pos.distance_to(Vector2(a) + Vector2(0.5, 0.5)) < 4.0, "a guard blocked by a wall gives up a bandit, as before (SIM-F4)")
	w.dispose()


func test_late_report() -> void:
	var w := _world()
	var g := _guard(w)
	var witness: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard":
			witness = n
			break
	# the place of the attack, out in the open; the guard 35 tiles away
	var at := Vector2(116.5, 86.5)
	for y in range(70, 110):
		var ok := false
		for x in range(90, 150):
			if _open(w, Vector2i(x, y)) and _open(w, Vector2i(x - 35, y)) and w.map.find_path(Vector2i(x - 35, y), Vector2i(x, y)).size() > 0:
				at = Vector2(x + 0.5, y + 0.5)
				ok = true
				break
		if ok:
			break
	w.player.pos = at
	witness.pos = at + Vector2(1, 0)
	w.report_crime(witness, Life.PLAYER_ID, "saw")
	check(witness.report.has("at"), "the report keeps where the player was seen")
	g.pos = at - Vector2(35, 0)
	g.target = -1
	g.plan.clear()
	w.deliver_report(witness, g)
	if g.target != -1:
		w.brain.fight(g, 0.05)        # before the fix: the chase of a far offender is dropped here
	print("     after the report: target %d, doing '%s', plan %s" % [g.target, g.doing, g.plan.map(func(s): return s.k)])
	check(not g.plan.is_empty() and g.plan[0].k == "go" and Vector2(g.plan[0].to).distance_to(at) < 2.0, "a guard too far off to chase sets out for the reported place, not dropping it")
	var gm := float(GameData.b("game_minutes_per_second"))
	var t := 0.0
	while not g.plan.is_empty() and g.target == -1 and t < 60.0:
		w._run_plan(g, 0.05, 0.05 * gm)
		t += 0.05
	print("     after %.1f s: guard at %s (%.1f tiles from the place), target %d" % [t, g.pos, g.pos.distance_to(at), g.target])
	check(g.target == Life.PLAYER_ID, "and, finding the player still there, takes them on")
	# a report within reach is answered at once, as before
	var w2 := _world()
	var g2 := _guard(w2)
	var v2: NPC = null
	for n: NPC in w2.npcs:
		if n.alive and n.role == "adult" and n.job != "guard":
			v2 = n
			break
	w2.player.pos = g2.pos + Vector2(8, 0)
	w2.report_crime(v2, Life.PLAYER_ID, "saw")
	g2.target = -1
	w2.deliver_report(v2, g2)
	check(g2.target == Life.PLAYER_ID, "a guard within reach of the offender takes them on at once, as before")
	w.dispose()
	w2.dispose()


# ------------------------------------------------------------------ A2: the pursuit state machine ----------
## An open stretch away from the camp; everyone but `keep` moved off; nobody in `keep` asleep.
func _stage(w: World, keep: Array) -> Vector2:
	for y in range(60, 120):
		for x in range(60, 160):
			var c := Vector2i(x, y)
			var ok := true
			for dx in range(-3, 4):
				ok = ok and _open(w, c + Vector2i(dx, 0))
			if not ok or Vector2(c).distance_to(Vector2(w.bandit_camp)) < 40.0:
				continue
			var at := Vector2(c) + Vector2(0.5, 0.5)
			for n: NPC in w.npcs:
				if not keep.has(n) and n.alive and n.pos.distance_to(at) < 45.0:
					n.pos = at + Vector2(0, 60) if at.y < 100 else at - Vector2(0, 60)
			for n: NPC in keep:
				n.anim = "idle"
				n.plan.clear()
				n.depth = 0
			w.player.pos = at
			return at
	return Vector2.ZERO


func _adult(w: World, skip := []) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard" and not skip.has(n):
			return n
	return null


## An open cell `d` tiles from `at` (any direction), outdoors, with a path to it.
func _away(w: World, at: Vector2, d: float) -> Vector2:
	for k in 16:
		var c := Vector2i((at + Vector2.RIGHT.rotated(TAU * k / 16.0) * d).floor())
		if _open(w, c) and w.map.find_path(Vector2i(at.floor()), c).size() > 0:
			return Vector2(c) + Vector2(0.5, 0.5)
	return at + Vector2(d, 0)


## The guard's own updates only (the rest of the village holds still), `secs` real seconds in 0.05 s ticks, while `until`.
func _tick(w: World, g: NPC, secs: float, until := Callable()) -> float:
	var t := 0.0
	while t < secs:
		w.minutes += 0.05 * float(GameData.b("game_minutes_per_second"))
		w._update_npc(g, 0.05)
		t += 0.05
		if until.is_valid() and until.call():
			break
	return t


## A guard who saw an assault is on the case, chasing; a wall with a way round it does not end it.
func test_case_chase() -> void:
	var w := _world()
	var g := _guard(w)
	var v := _adult(w)
	var at := _stage(w, [g, v])
	g.pos = at + Vector2(4, 0)
	v.pos = at + Vector2(0.6, 0)
	w.player.hp = 9999.0
	w.player_hit_npc(v, 1.0)
	check(g.target == Life.PLAYER_ID and str(g.pursuit.get("state", "")) == "pursuing" and str(g.pursuit.ref) == "player", "a guard who saw the assault is on the player's case, chasing")
	check(w.justice.status("player") == "pursued", "the case is being pursued")
	w.dispose()


func test_search_and_wanted() -> void:
	var w := _world()
	var g := _guard(w)
	var v := _adult(w)
	var at := _stage(w, [g, v])
	g.pos = at + Vector2(4, 0)
	v.pos = at + Vector2(0.6, 0)
	v.max_hp = 9999.0
	v.hp = 9999.0
	w.player.hp = 9999.0
	w.player_hit_npc(v, 1.0)
	v.target = -1
	var seen_at := w.player.pos
	# the player gets clean away, 30 tiles: out of sight (and past the old 25-tile give-up)
	var gone := _away(w, at, 30.0)
	w.player.pos = gone
	_tick(w, g, 0.1)
	print("     after losing sight: target %d, pursuit %s, plan %s" % [g.target, str(g.pursuit.get("state", "")), g.plan.map(func(s): return str(s.get("to", s.k)))])
	check(g.target == -1 and str(g.pursuit.get("state", "")) == "searching", "out of sight the guard searches; the case is not dropped")
	check(Vector2(float(g.pursuit.at[0]), float(g.pursuit.at[1])).distance_to(seen_at) < 0.01, "from where they last saw the player")
	check(not g.plan.is_empty() and Vector2(g.plan[0].to).distance_to(seen_at) < 1.5, "and they go to the last-known place first, not where the player is")
	var c: Dictionary = w.justice.case_of("player")
	check(Vector2(float(c.last[0]), float(c.last[1])).distance_to(seen_at) < 0.01, "the authorities know only the last place the player was seen")
	var cells: Array = g.pursuit.cells
	check(cells.size() >= 3 and cells.size() <= int(Justice.response("assault").search_points), "a bounded search: %d places (the last-known, then nearby)" % cells.size())
	# the search goes on, never closer to the player's real place by any knowledge
	_tick(w, g, 6.0)
	check(str(g.pursuit.get("state", "")) == "searching" and g.target == -1, "still searching a while later (%s)" % g.doing)
	# sight restored: the chase is back
	w.player.pos = g.pos + Vector2(3, 0) if _open(w, Vector2i((g.pos + Vector2(3, 0)).floor())) else g.pos + Vector2(0, 3)
	_tick(w, g, 0.1)
	check(g.target == Life.PLAYER_ID and str(g.pursuit.state) == "pursuing", "seen again, the guard takes up the chase (reacquire)")
	# away again, and the search runs out: the case goes over to wanted
	w.player.pos = _away(w, g.pos, 30.0)
	_tick(w, g, 0.1)
	w.minutes += float(Justice.response("assault").search_minutes) + 1.0
	_tick(w, g, 0.1)
	check(g.pursuit.is_empty() and w.justice.status("player") == "wanted", "a search that finds nothing ends: the player is wanted (%s)" % w.justice.status("player"))
	check(w.justice.knows(g, "player"), "the guard still knows of the assault")
	var last: Array = w.justice.case_of("player").last
	check(Vector2(float(last[0]), float(last[1])).distance_to(w.player.pos) > 5.0, "and does not know where the player is now")
	# on the rounds, the wanted player comes into sight: the chase begins again
	g.plan.clear()
	g.target = -1
	w.player.pos = g.pos + Vector2(3, 0) if _open(w, Vector2i((g.pos + Vector2(3, 0)).floor())) else g.pos + Vector2(0, 3)
	w.brain.decide(g)
	check(g.target == Life.PLAYER_ID and str(g.pursuit.get("state", "")) == "pursuing", "the guard on the rounds recognises the wanted player and chases again")
	w.dispose()


func test_wanted_save_load() -> void:
	var w := _world()
	var g := _guard(w)
	var v := _adult(w)
	var at := _stage(w, [g, v])
	g.pos = at + Vector2(4, 0)
	v.pos = at + Vector2(0.6, 0)
	v.max_hp = 9999.0
	v.hp = 9999.0
	w.player.hp = 9999.0
	w.player_hit_npc(v, 1.0)
	w.player.pos = _away(w, at, 30.0)
	_tick(w, g, 0.1)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var g2 := w2.npc(g.id)
	check(str(g2.pursuit.get("state", "")) == "searching" and str(g2.pursuit.ref) == "player" and int(g2.pursuit.i) == int(g.pursuit.i), "a guard's search survives save and load")
	check(w2.justice.status("player") == "pursued" and w2.justice.tier_for(g2, "player") == "assault", "and so does the case")
	_tick(w2, g2, 0.2)
	check(g2.target == -1 and not g2.plan.is_empty() and Vector2(g2.plan[0].to).distance_to(w2.player.pos) > 5.0, "after loading the guard goes on searching, not to the player")
	# once wanted (search over), save and load: still wanted, still not tracked
	w2.minutes += float(Justice.response("assault").search_minutes) + 1.0
	_tick(w2, g2, 0.1)
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict()))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d2)
	check(w3.justice.status("player") == "wanted" and w3.justice.knows(w3.npc(g.id), "player"), "a wanted status survives save and load")
	check(w3.npc(g.id).pursuit.is_empty() and w3.npc(g.id).target == -1, "with nobody tracking the player")
	w.dispose()
	w2.dispose()
	w3.dispose()


## A report on a case reaching a guard who does not see the player: the guard goes to where the player was seen and
## searches there; a guard who sees the player takes them on.
func test_report_responds() -> void:
	var w := _world()
	var g := _guard(w)
	var g2: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard" and n != g:
			g2 = n
			break
	var v := _adult(w)
	var wit := _adult(w, [v])
	var at := _stage(w, [v, wit, g, g2])
	g.pos = at + Vector2(0, 50)
	g2.pos = at + Vector2(0, -50)
	v.pos = at + Vector2(0.6, 0)
	v.max_hp = 9999.0
	v.hp = 9999.0
	wit.pos = at + Vector2(-3, 0)
	w.player_hit_npc(v, 1.0)
	check((wit.report.get("cis", []) as Array).size() == 1, "the witness will report the assault")
	var seen_at := w.player.pos
	w.player.pos = _away(w, at, 30.0)
	g.pos = wit.pos + Vector2(2, 0)
	w.deliver_report(wit, g)
	check(g.target == -1 and str(g.pursuit.get("state", "")) == "responding" and not g.plan.is_empty() and Vector2(g.plan[0].to).distance_to(seen_at) < 1.5,
			"told, a guard who cannot see the player goes to where they were seen")
	check(w.justice.knows(g, "player") and w.justice.status("player") == "pursued", "and is on the case")
	_tick(w, g, 30.0, func() -> bool: return str(g.pursuit.get("state", "")) != "responding")
	check(str(g.pursuit.get("state", "")) == "searching", "there, the guard searches (%s, %.1f tiles from the place)" % [g.doing, g.pos.distance_to(seen_at)])
	# a second report, the player in the guard's sight: taken on at once
	w.report_crime(wit, Life.PLAYER_ID, "saw", "attack", "player", [0])
	w.player.pos = g2.pos + Vector2(3, 0) if _open(w, Vector2i((g2.pos + Vector2(3, 0)).floor())) else g2.pos + Vector2(0, 3)
	g2.anim = "idle"
	w.deliver_report(wit, g2)
	check(g2.target == Life.PLAYER_ID and str(g2.pursuit.get("state", "")) == "pursuing", "a guard told who sees the player takes them on at once")
	w.dispose()
