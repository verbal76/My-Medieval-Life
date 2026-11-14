extends SceneTree
## B42 (B25-MOVE-STUTTER-INV): after the chunk prefetch went to a worker, the next main-thread stall of the walk south was the
## drawing of a chunk (OverworldView._build: median 7 ms, 11 frames over 50 ms on the southern walk at load 7-9). A chunk is
## now drawn in parts over frames (OverworldView._build_begin/_build_part, build_budget_usec a frame). This test, walking at
## the game's pace south from the village gate:
##  1. no frame spends more than BUILD_MS drawing chunks, but at most MOST_OVER (preemption on a loaded machine);
##  2. every chunk drawn in parts, with every change that reached it while it was drawn, is the chunk drawn whole now: every
##     cell of every layer (ground, grass, path, objects, tops, the settlement buildings' layers, its works).
##   godot --headless --path game -s res://tests/chunk_slice_test.gd [-- whole]
## `whole` draws each chunk at once in one frame (slice_builds off, as before): the failing case.

const BUILD_MS := 10.0
const MOST_OVER := 3
const STEP := 0.075              # tiles a frame: walking pace at 60 fps (4.5 tiles a second)
const FRAMES := 3600

var main
var checks := 0
var failures := 0
var frames := 0
var route: PackedVector2Array
var idx := 0
var worst := 0.0
var over := 0
var built := 0
var gen0 := 0
var made_seen := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_chunk_slice/save.json"
	process_frame.connect(_begin, CONNECT_ONE_SHOT)


func _begin() -> void:
	main.new_game()
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var gate := Vector2i(ow.gates[0].out)
	for g in ow.gates:
		if g.out.y > gate.y:
			gate = Vector2i(g.out)
	route = RegionTravel.plan(w, gate, Vector2i(195, 700)).cells          # seed 1: by Wendholt toward Milton (the owner's way)
	w.player.pos = Vector2(gate) + Vector2(0.5, 0.5)
	main.ow_view.set("profiling", true)
	main.ow_view.set("log_made", true)
	if OS.get_cmdline_user_args().has("whole"):
		main.ow_view.set("slice_builds", false)
	check(main.ow_view.get("slice_builds") == true, "the view draws chunks in parts (slice_builds)")
	process_frame.connect(_frame)


func _frame() -> void:
	frames += 1
	var w: World = main.world
	var pr: Dictionary = main.ow_view.get("prof")
	var b := float(int(pr.get("ow:build", 0))) / 1000.0
	var parts := ", ".join(PackedStringArray(["begin", "cells", "grass", "trees", "sites, works"].map(func(k): return "%s %.1f" % [k, int(pr.get("ow:build(%s)" % k, 0)) / 1000.0])))
	main.ow_view.set("prof", {})
	if frames == 30:
		gen0 = int(main.ow_view.get("built_ungenerated")) if main.ow_view.get("built_ungenerated") != null else 0
	var ml: Array = main.ow_view.get("made_log") if main.ow_view.get("made_log") != null else []
	while made_seen < ml.size():
		print("     frame %d: a tile made in play: atlas %d index %d" % [frames, int(ml[made_seen][0]), int(ml[made_seen][1])])
		made_seen += 1
	if frames > 60:                              # (after the first view is drawn)
		worst = maxf(worst, b)
		if b > BUILD_MS:
			over += 1
			print("     frame %d: drawing chunks %.2f ms (%s); now at %s" % [frames, b, parts, str((main.ow_view.get("_job") as Dictionary).duplicate().erase("ch") if false else [main.ow_view._job.get("cc"), main.ow_view._job.get("stage"), main.ow_view._job.get("row")])])
	var left := STEP
	while left > 0.0 and idx < route.size():
		var t := route[idx] + Vector2(0.5, 0.5)
		var d := w.player.pos.distance_to(t)
		if d <= left:
			w.player.pos = t
			left -= d
			idx += 1
		else:
			w.player.pos += (t - w.player.pos) / d * left
			left = 0.0
	if frames < FRAMES and idx < route.size():
		return
	process_frame.disconnect(_frame)
	_finish()


static func snap(v: OverworldView, cc: Vector2i) -> String:
	var c: Dictionary = v.chunks[cc]
	var parts := PackedStringArray()
	var layers: Array = []
	for k in ["ground", "grass", "path", "objects", "tops"]:
		layers.append([k, c[k]])
	var ki := 0
	for n in (c.root as Node2D).get_children():
		ki += 1
		if n is TileMapLayer and not (n as TileMapLayer) in [c.ground, c.grass, c.path, c.objects, c.tops]:
			layers.append(["root child %d (z %d)" % [ki, (n as TileMapLayer).z_index], n])
	for l in c.site_above:
		if is_instance_valid(l) and (l as Node).get_parent() != c.root:
			layers.append(["sorted", l])
	for e in layers:
		var l: TileMapLayer = e[1]
		var cells := l.get_used_cells()
		cells.sort()
		var s := PackedStringArray()
		for cell in cells:
			s.append("%d,%d:%d:%s:%d" % [cell.x, cell.y, l.get_cell_source_id(cell), str(l.get_cell_atlas_coords(cell)), l.get_cell_alternative_tile(cell)])
		parts.append("%s[%d] %s" % [e[0], cells.size(), ";".join(s)])
	var works: Node = c.works
	parts.append("works %d" % (works.get_child_count() if works != null else -1))
	parts.append("children %s" % ",".join(PackedStringArray((c.root as Node2D).get_children().map(func(n): return n.get_class()))))
	return "\n".join(parts)


func _finish() -> void:
	var v: OverworldView = main.ow_view
	var w: World = main.world
	print("     %d frames, %.0f tiles south to y %.0f; drawing chunks: worst %.2f ms a frame, %d frames over %.0f ms; %d chunks drawn before their data was ready (generated on the main thread)" % [
			frames, float(idx), w.player.pos.y, worst, over, BUILD_MS, int(v.get("built_ungenerated")) - gen0])
	check(over <= MOST_OVER, "no frame of the walk spends over %.0f ms drawing chunks, but at most %d (%d; worst %.2f ms)" % [BUILD_MS, MOST_OVER, over, worst])
	while not (v.get("_job") as Dictionary).is_empty():
		v.call("_build_part")
	var keys: Array = v.chunks.keys()
	keys.sort()
	var bad := 0
	var n := 0
	for cc: Vector2i in keys:
		var a := snap(v, cc)
		v._free(cc)
		v.slice_builds = false
		v._build(cc)
		v.slice_builds = true
		n += 1
		var b := snap(v, cc)
		if b != a:
			bad += 1
			if bad <= 2:
				var la := a.split("\n")
				var lb := b.split("\n")
				for k in mini(la.size(), lb.size()):
					if la[k] != lb[k]:
						print("     chunk %s differs: %s ... | %s ..." % [str(cc), la[k].left(160), lb[k].left(160)])
						break
	check(n >= 20 and bad == 0, "every drawn chunk (%d) is the chunk drawn whole now, cell for cell in every layer (%d differ)" % [n, bad])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
