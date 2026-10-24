extends SceneTree
## Guard pursuit of the player (REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS step S3; owner directive 2026-10-24, open item 03 B
## and G: "Turning one corner does not terminate pursuit"). Rebuilt from the audit's reproduction: a guard 8 tiles from
## the player with a wall between them and a walkable way round it.
##   - the guard chasing the player follows the path round the wall and reaches them;
##   - a bandit chasing the player, and a guard chasing a bandit, still give up at the wall (SIM-F4, unchanged);
##   - a report that reaches a guard too far off to chase sends the guard to the reported place, where they take on
##     the offender if they are still there; one within reach takes them on at once, as before.
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
