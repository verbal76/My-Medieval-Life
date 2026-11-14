extends SceneTree
## B42 (B25-MOVE-STUTTER-INV): BusinessDesks.faced_all runs every frame (Main._find_target, the "what can I use here" prompt) and
## listed every desk in the world, naming each, before keeping the one or two beside the player: 1.1 ms a frame at the start of
## the southern walk, 4.9 ms after five game minutes (docs/audits/2026-11-14_B42_MOVEMENT_STUTTER_MEASUREMENTS.md). It now
## lists only the desks within World.STATION_BESIDE (the only ones it can return). This test: the answers are the same as the
## whole list's at every point round every desk, facing each way, and BusinessDesks.all(w, near, reach) is the whole list
## filtered by distance, in the same order; and the call is cheaper.
##   godot --headless --path game -s res://tests/desks_faced_test.gd

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


## faced_all as it was before B42 (the whole list, then the tests): the reference.
static func faced_all_before(w: World, pos: Vector2, facing: Vector2) -> Array:
	var out := []
	var probe := pos + facing.normalized() * World.TARGET_PROBE if facing != Vector2.ZERO else pos
	for d in BusinessDesks.all(w):
		if str(d.kind) == "stall":
			continue
		var at: Vector2i = d.at
		var near := Vector2i(floori(probe.x), floori(probe.y)) == at
		if not near and (Vector2(at) + Vector2(0.5, 0.5)).distance_to(pos) <= World.STATION_BESIDE:
			near = World.station_in_reach({"use": [d.use.x, d.use.y], "at": [at.x, at.y]}, pos, facing) and Vector2i(floori(pos.x), floori(pos.y)) != d.use
		var reach: bool = w.reaches(pos, Vector2(at) + Vector2(0.5, 0.5)) or w.reaches(pos, Vector2(d.use) + Vector2(0.5, 0.5))
		if near and (Vector2(at) + Vector2(0.5, 0.5)).distance_to(pos) <= World.STATION_BESIDE and reach:
			out.append(d)
	return out


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	for i in 240:                                  # two game hours: stalls taken, shops open
		w.update(0.5)
	var desks := BusinessDesks.all(w)
	var kinds := {}
	for d in desks:
		kinds[str(d.kind)] = int(kinds.get(str(d.kind), 0)) + 1
	print("     %d desks: %s" % [desks.size(), str(kinds)])
	var points := 0
	var found := 0
	var differ := 0
	var listed_bad := 0
	for d in desks:
		var at := Vector2(d.at) + Vector2(0.5, 0.5)
		for dy in range(-12, 13):
			for dx in range(-12, 13):
				var pos := at + Vector2(dx, dy) * 0.25
				var want := desks.filter(func(e): return (Vector2(e.at) + Vector2(0.5, 0.5)).distance_to(pos) <= World.STATION_BESIDE)
				if BusinessDesks.all(w, pos, World.STATION_BESIDE) != want:
					listed_bad += 1
				for f in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO]:
					points += 1
					var a := BusinessDesks.faced_all(w, pos, f)
					if a != faced_all_before(w, pos, f):
						differ += 1
					found += a.size()
	check(desks.size() >= 5 and points > 10000, "%d points round the %d desks, five facings each" % [points, desks.size()])
	check(found > 100 and differ == 0, "faced_all answers as the whole list did at every one (%d desks found in all, %d answers differ)" % [found, differ])
	check(listed_bad == 0, "all(w, near, reach) is the whole list filtered by distance, in order (%d differ)" % listed_bad)
	# the cost of a call, in the village and out on the trail south (where the walk measured it growing)
	for p: Vector2 in [Vector2(w.player.pos), Vector2(195.5, 650.5)]:
		var t0 := Time.get_ticks_usec()
		for i in 300:
			faced_all_before(w, p, Vector2.DOWN)
		var t1 := Time.get_ticks_usec()
		for i in 300:
			BusinessDesks.faced_all(w, p, Vector2.DOWN)
		var t2 := Time.get_ticks_usec()
		var before := (t1 - t0) / 300.0 / 1000.0
		var after := (t2 - t1) / 300.0 / 1000.0
		check(after < before * 0.5, "at %s a call costs under half what it did (%.3f ms against %.3f)" % [str(p), after, before])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
