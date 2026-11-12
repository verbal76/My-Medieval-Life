extends SceneTree
## MML-NPC-01 "Failed pathfinding retried without back-off" (Audit 007; work package WP-2). A walk that finds no path (no route
## to the level, or no path on it) clears the plan and marks the villager lost, and the next tick (one game minute) decides
## again: when the new plan is a walk that fails too, the path search runs every minute, without end. (A villager walled in
## inside the village does not show it: the village grid's search returns the nearest reachable part of the way, so the walk
## "arrives" short.) Seed 1: an adult is set down on open ground 150 cells east of the village in the middle of the day, beyond
## a villager's path search, so every walk it plans fails. Checked:
##  1. over six game hours its decisions (each followed by a failed path search) stay bounded (a back-off: it waits, longer
##     each time, before deciding again), where without one they run once a game minute (360 times);
##  2. it shows as lost while it waits, and the waits are deterministic (two identical worlds wait identically);
##  3. brought back within reach it walks off within the longest wait (World.WALK_BACKOFF_MAX minutes) plus a little, and
##     its failure count is cleared by the first path found;
##  4. the count is saved: a world saved during the back-off loads with the same count and the waiting plan;
##  5. a villager whose walks succeed is untouched (no failure count).
##   godot --headless --path game -s res://tests/npc01_path_backoff_test.gd

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func run_hours(w: World, hours: float) -> void:
	var gmps := float(GameData.b("game_minutes_per_second"))
	for i in int(60.0 * hours / gmps / 0.5):
		w.update(0.5)


## A world at 9 in the morning of day 2 with one adult at home in the village set down on open ground 150 cells east of it:
## every errand it plans is in the village, farther than a villager's path search reaches (VillageMap.find_path_world,
## WORLD_PATH_CELLS), so each walk fails with no path. Returns [world, villager].
func stranded() -> Array:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	run_hours(w, 24.0 + 3.0)
	var pick: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.depth == 0 and n.journey.is_empty() and n.target == -1 and n.job != "guard" \
				and w.place_of(n.pos) == "" and homesteads_free(w, n):
			pick = n
			break
	if pick != null:
		pick.pos = Vector2(open_cell(w, Vector2i(w.map.w + 150, w.map.h / 2))) + Vector2(0.5, 0.5)
		pick.plan.clear()
		pick.path = PackedVector2Array()
	return [w, pick]


func open_cell(w: World, c: Vector2i) -> Vector2i:
	for k in 60:
		if not w.map.is_solid_world(c + Vector2i(0, k)):
			return c + Vector2i(0, k)
	return c


## A villager's failed-walk count (-1 where the game has none).
func pf(n: NPC) -> int:
	return int(n.get("path_fails")) if n != null and "path_fails" in n else -1


const MAX_WAIT := 60.0               # World.WALK_BACKOFF_MAX: the longest wait between attempts, in game minutes


func homesteads_free(w: World, n: NPC) -> bool:
	return not w.homesteads.drives(n) and not w.life.drives(n)


func _init() -> void:
	var r := stranded()
	var w: World = r[0]
	var n: NPC = r[1]
	check(n != null, "seed 1 has an adult at home at 9 in the morning")
	if n == null:
		print("%d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var start := n.cell()
	var dec0 := int(w.brain.decide_calls.get(n.id, 0))
	var lost_minutes := 0
	var gmps := float(GameData.b("game_minutes_per_second"))
	for i in int(60.0 * 6.0 / gmps / 0.5):
		w.update(0.5)
		if n.doing == "lost":
			lost_minutes += 1
	var decides := int(w.brain.decide_calls.get(n.id, 0)) - dec0
	var fails := pf(n)
	print("villager %d (%s): %d decisions (each a failed path search) and %d lost minutes in six game hours; failed walks counted %d" % [n.id, n.job, decides, lost_minutes, fails])
	check(n.cell() == start, "the stranded villager has not moved (%s)" % n.cell())
	check(decides <= 15, "it decided at most 15 times in six game hours, not once a minute (%d)" % decides)
	check(fails >= 2, "its failed walks are counted (%d)" % fails)
	check(n.doing == "lost" and lost_minutes >= 300, "it shows as lost while it waits ('%s'; lost in %d of the 360 minutes)" % [n.doing, lost_minutes])

	# 2. deterministic: a second, identical world waits identically
	var r2 := stranded()
	var w2: World = r2[0]
	var n2: NPC = r2[1]
	run_hours(w2, 6.0)
	check(n2 != null and n2.id == n.id and int(w2.brain.decide_calls.get(n2.id, 0)) - dec0 == decides and pf(n2) == pf(n) \
		and str(n2.plan) == str(n.plan), "a second identical world backs off identically (deterministic)")

	# 4. the count and the waiting plan are saved
	var l := World.new()
	l.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var ln := l.npc(n.id)
	check(ln != null and pf(ln) == pf(n) and pf(n) > 0 and is_equal_approx(float(ln.get("path_fail_at")), float(n.get("path_fail_at"))) \
		and str(ln.plan) == str(n.plan), "a save during the back-off keeps the count, its time and the waiting plan (%d, %s)" % [pf(ln), str(ln.plan) if ln != null else "-"])

	# 3. within reach again (brought back beside the village): it walks off within the longest wait
	n.pos = Vector2(open_cell(w, Vector2i(w.map.w + 4, w.map.h / 2))) + Vector2(0.5, 0.5)
	var back := n.cell()
	var limit := MAX_WAIT + 30.0
	var waited := 0.0
	while n.cell() == back and waited < limit:
		w.update(0.5)
		waited += 0.5 * gmps
	check(n.cell() != back, "within reach again, it walks off within %d minutes (after %d)" % [int(limit), int(waited)])
	check(pf(n) == 0, "its first path found clears the count (%d)" % pf(n))

	# 5. untouched elsewhere: villagers walking freely have no count
	var alive := w.npcs.filter(func(o: NPC): return o.alive)
	var counted := alive.filter(func(o: NPC): return pf(o) > 0)
	check(counted.size() <= alive.size() / 10, "villagers walking freely have no failure count (%d of %d have one)" % [counted.size(), alive.size()])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
