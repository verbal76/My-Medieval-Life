extends SceneTree
## GP-MINE-WOOD-FRAME (owner playtest 2026-10-26: a wooden frame over the wall under a seam "is blocking a deposit"). The
## frame was a timber support (WorksView), drawn standing 6 px up into the cell above, as a doorway: under a seam its cap
## beam cut through the deposit. Checked here, presentation only:
##   - a support's drawing lies wholly inside its own cell, beam either way, sound or sagging, at every floor cell of every
##     level (so it can never cover a seam beside it);
##   - its beam lies across the passage (north-south where rock is north and south);
##   - every level reached from the surface draws its way out (WayOutMark) at its portal's door: rock, never a seam, the
##     stand open floor beside it; a shaft's ladder is not taken for one;
##   - nothing in the simulation changes: placing a support in the test's own world is not needed (the drawing is a pure
##     function of the cell), and the level maps, deposits and portals are only read.
##   godot --headless --path game --script res://tests/mine_frame_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var u: Underground = w.underground
	var outside := []
	var floors := 0
	for lm: LevelMap in u.maps:
		for f in lm.floor_cells():
			floors += 1
			var o := Vector2(f) * 16.0
			var cell := Rect2(o, Vector2(16, 16))
			for ns in [false, true]:
				for sag in [0.0, 1.0]:
					for part in WorksView.support_parts(o, ns, sag):
						if not cell.encloses(part[0]):
							outside.append("%s %s ns=%s sag=%s" % [lm.id, f, ns, sag])
	check(floors > 50 and outside.is_empty(), "a support is drawn wholly inside its own cell at every floor cell of every level (%d cells) %s" % [floors, outside.slice(0, 4)])
	# the beam lies across the passage
	var across_ok := true
	var tried := 0
	for lm: LevelMap in u.maps:
		var wv := WorksView.new()
		wv.setup(w.mine_works, lm.level)
		for f in lm.floor_cells():
			var n := int(lm.is_solid(f + Vector2i(0, -1))) + int(lm.is_solid(f + Vector2i(0, 1)))
			var e := int(lm.is_solid(f + Vector2i(-1, 0))) + int(lm.is_solid(f + Vector2i(1, 0)))
			if n > e:
				tried += 1
				across_ok = across_ok and wv._support_runs_ns(f)
			elif e > n:
				tried += 1
				across_ok = across_ok and not wv._support_runs_ns(f)
		wv.free()
	check(tried > 0 and across_ok, "in a passage the beam lies across it (%d passage cells)" % tried)
	# the way out
	for lm: LevelMap in u.maps:
		var mark := WayOutMark.new()
		mark.setup(w, lm)
		var want := 0
		for p in u.portals:
			if str(p.get("kind", "")) != "shaft":
				for i in 2:
					if int(p.ends[i].level) == lm.level and int(p.ends[1 - i].level) == 0:
						want += 1
		var good := mark.doors.size() == want and want > 0
		for d in mark.doors:
			var c: Vector2i = d[0]
			good = good and w.deposit_at(c, lm.level).is_empty() and (d[1] as Vector2).length() > 0.9
		check(good, "%s: its way out to the surface is drawn at the portal's door, never on a seam (%d)" % [lm.id, mark.doors.size()])
		mark.free()
	w.dispose()
	print("mine_frame_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
