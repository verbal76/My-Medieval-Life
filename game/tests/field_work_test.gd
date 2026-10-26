extends SceneTree
## GP-FARMER-TENDING (owner, 2026-10-24; Build 22): a villager at work on a field is drawn moving between its cells, stopping now and
## then to work the ground with a shovel (FieldWorkView), and nothing of the simulation changes:
##  - over a sowing, cutting or tending step the drawn worker visits several cells of the field (inside it, not at its edge), walks
##    between them and swings the shovel at each; the same for a family plot's batch (its own cells);
##  - the pose is a pure function of the step and its progress (the same twice);
##  - a farmer of the running village, tending a growing field, is drawn that way;
##  - presentation only: a world whose villagers' poses are read every tick runs exactly as one never read (the whole save equal).
##   godot --headless --path game --script res://tests/field_work_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_tour_through_field()
	test_plot_batch()
	test_live_farmer()
	test_presentation_only()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	return w


func _farmer(w: World) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.job == "farmer" and not w.brain._field(n.workplace).is_empty():
			return n
	return null


## Sample the pose over the whole step: {cells (distinct worked cells), walk, swing, inside (every worked cell in `r`), tool}.
func _sample(w: World, n: NPC, r: Rect2i) -> Dictionary:
	var out := {"cells": {}, "walk": 0, "swing": 0, "inside": true, "tool": true, "poses": []}
	var total := float(n.plan[0].min)
	for i in 200:
		n.work_left = total * (1.0 - i / 200.0)
		var fw := FieldWorkView.pose(w, n)
		if fw.is_empty():
			out.inside = false
			continue
		out.poses.append(fw)
		if fw.anim == "swing":
			out.swing += 1
			out.cells[fw.cell] = true
			out.inside = out.inside and r.has_point(fw.cell) and r.has_point(Vector2i(floori(fw.pos.x), floori(fw.pos.y)))
			out.tool = out.tool and fw.tool == "shovel"
		else:
			out.walk += 1
	return out


func test_tour_through_field() -> void:
	var w := _world()
	var n := _farmer(w)
	check(n != null, "a farmer with a field")
	if n == null:
		return
	var f: Dictionary = w.brain._field(n.workplace)
	var r := Rect2i(int(f.x), int(f.y), int(f.w), int(f.h))
	var edge := Vector2(int(f.x) + 0.5, int(f.y) + int(f.h) + 0.5)       # where the simulation stands them (NPCBrain._farmer: below the field)
	for st in [w.brain.work(45.0, "sow", {"field": f.id}, "work"), w.brain.work(90.0, "harvest", {"field": f.id, "min": 90.0}, "work")]:
		var tend: Dictionary = w.brain.work(60.0, "", {}, "idle")
		tend["field"] = f.id
		for s in [st, tend]:
			n.plan = [s]
			n.pos = edge
			var got := _sample(w, n, r)
			var what := str(s.get("act", "")) if str(s.get("act", "")) != "" else "tending"
			check(got.cells.size() >= 3 and got.inside, "%s: the farmer is drawn on %d cells inside the field, not at its edge" % [what, got.cells.size()])
			check(got.swing > 0 and got.walk > 0 and got.tool, "%s: walks between them and works each with the shovel (%d swing, %d walk samples)" % [what, got.swing, got.walk])
			check(n.pos == edge and float(n.plan[0].min) == float(s.min), "%s: the simulated place and the step's minutes are untouched" % what)
			n.work_left = float(s.min) * 0.4
			check(JSON.stringify(FieldWorkView.pose(w, n)) == JSON.stringify(FieldWorkView.pose(w, n)), "%s: the pose is the same when read twice" % what)
	# an idle step without a field, and a walk, are drawn as before
	n.plan = [w.brain.work(30.0, "", {}, "idle")]
	check(FieldWorkView.pose(w, n).is_empty(), "a wait that is not on a field is not field work")
	n.plan = [w.brain.go(Vector2i(int(f.x), int(f.y)))]
	check(FieldWorkView.pose(w, n).is_empty(), "walking to the field is drawn as the walk it is")
	w.dispose()


func test_plot_batch() -> void:
	var w := _world()
	var n: NPC = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult")[0]
	var cs := [[10, 10], [11, 10], [12, 10], [13, 10]]
	n.plan = [w.brain.work(40.0, "fp_work", {"plot": "x", "task": "sow", "crop": "wheat", "cells": cs}, "work", Vector2i(10, 10))]
	var got := _sample(w, n, Rect2i(10, 10, 4, 1))
	check(got.cells.size() >= 3 and got.inside and got.tool, "a family plot's batch: drawn working %d of its own cells with the shovel" % got.cells.size())
	w.dispose()


func test_live_farmer() -> void:
	var w := _world(2)
	var seen := {}
	var found: NPC = null
	for i in 2400:                                       # the village runs; a farmer of a growing field tends it (NPCBrain._farmer)
		w.player.hunger = 100.0
		w.update(0.5)
		for n: NPC in w.npcs:
			if n.alive and n.job == "farmer" and not n.plan.is_empty() and n.plan[0].k == "work" and n.plan[0].has("field"):
				found = n
				break
		if found != null:
			break
	check(found != null, "a farmer of the running village tends a field")
	if found == null:
		w.dispose()
		return
	var f: Dictionary = w.brain._field(found.workplace)
	var fw := FieldWorkView.pose(w, found)
	check(not fw.is_empty() and Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).has_point(fw.cell), "and is drawn on the field's own cells (%s)" % str(fw.get("cell")))
	w.dispose()


func test_presentation_only() -> void:
	var a := _world(3)
	var b := _world(3)
	var posed := 0
	for i in 1200:
		a.player.hunger = 100.0
		b.player.hunger = 100.0
		a.update(0.5)
		b.update(0.5)
		for n: NPC in b.npcs:
			if n.alive and not FieldWorkView.pose(b, n).is_empty():
				posed += 1
	check(posed > 0, "villagers were drawn at field work on the way (%d poses read)" % posed)
	check(JSON.stringify(a.to_dict()) == JSON.stringify(b.to_dict()), "reading the poses changes nothing: the two worlds are identical")
	a.dispose()
	b.dispose()
