extends SceneTree
## B42 (B25-MOVE-STUTTER-INV): after the chunk prefetch went to a worker, the next main-thread stall of the walk south was the
## drawing of a chunk (OverworldView._build: median 7 ms, 11 frames over 50 ms on the southern walk at load 7-9). A chunk is
## now drawn in parts over frames (OverworldView._build_begin/_build_part, build_budget_usec a frame). This test, walking at
## the game's pace south from the village gate:
##  1. no frame of the walk places more than MOST_TILES tiles (MapView._put: the drawing work, counted, so the check does not
##     depend on the machine's load), with the view's budget at 0 (one part a frame); a chunk drawn whole places 2,000-4,000.
##     The frame times are printed as evidence (they vary with the load);
##  2. every chunk drawn in parts, with every change that reached it while it was drawn, is the chunk drawn whole now: every
##     cell of every layer (ground, grass, path, objects, tops, the settlement buildings' layers, its works).
##   godot --headless --path game -s res://tests/chunk_slice_test.gd [-- whole]
## `whole` draws each chunk at once in one frame (slice_builds off, as before): the failing case.

const MOST_TILES := 700
const STEP := 0.075              # tiles a frame: walking pace at 60 fps (4.5 tiles a second)
const FRAMES := 3600

var main
var checks := 0
var failures := 0
var frames := 0
var route: PackedVector2Array
var idx := 0
var worst := 0.0
var times: Array = []                  # ms drawing chunks, each frame of the walk with any
var most_tiles := 0
var tiles0 := 0
var whole_tiles := 0
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
	main.ow_view.set("build_budget_usec", 0)
	tiles0 = int(main.ow_view.get("tiles_put")) if main.ow_view.get("tiles_put") != null else 0
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
	var tp := int(main.ow_view.get("tiles_put")) if main.ow_view.get("tiles_put") != null else 0
	if frames > 60:                              # (after the first view is drawn)
		most_tiles = maxi(most_tiles, tp - tiles0)
		if b > 0.0:
			worst = maxf(worst, b)
			times.append([frames, b, parts, tp - tiles0])
	tiles0 = tp
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
	if v.get("_job") != null:
		while not (v.get("_job") as Dictionary).is_empty():
			v.call("_build_part")
	var keys: Array = v.chunks.keys()
	keys.sort()
	var bad := 0
	var n := 0
	var whole: Array = []
	for cc: Vector2i in keys:
		var a := snap(v, cc)
		v._free(cc)
		var t0 := Time.get_ticks_usec()
		var p0 := int(v.get("tiles_put")) if v.get("tiles_put") != null else 0
		v._build(cc)
		whole.append((Time.get_ticks_usec() - t0) / 1000.0)
		whole_tiles = maxi(whole_tiles, (int(v.get("tiles_put")) if v.get("tiles_put") != null else 0) - p0)
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
	whole.sort()
	var med: float = whole[whole.size() / 2] if not whole.is_empty() else 0.0
	times.sort_custom(func(x, y): return x[1] > y[1])
	for e in times.slice(0, 5):
		print("     slow frame %d: drawing chunks %.2f ms, %d tiles (%s)" % [e[0], e[1], e[3], e[2]])
	var hist := PackedStringArray()
	for t in [5, 10, 15, 20, 30]:
		hist.append(">%d ms: %d" % [t, times.filter(func(e): return e[1] > t).size()])
	print("     %d frames, %.0f tiles south to y %.0f, load %s; frames drawing chunks %d (%s), worst %.2f ms; a chunk drawn whole: median %.2f ms, up to %d tiles; %d chunks drawn before their data was ready" % [
			frames, float(idx), w.player.pos.y, _load(), times.size(), ", ".join(hist), worst, med, whole_tiles, int(v.get("built_ungenerated")) - gen0 if v.get("built_ungenerated") != null else -1])
	check(most_tiles > 0 and most_tiles <= MOST_TILES, "no frame of the walk places more than %d tiles (most %d; a chunk drawn whole up to %d)" % [MOST_TILES, most_tiles, whole_tiles])
	check(n >= 20 and bad == 0, "every drawn chunk (%d) is the chunk drawn whole now, cell for cell in every layer (%d differ)" % [n, bad])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


static func _load() -> String:
	var out: Array = []
	OS.execute("cat", ["/proc/loadavg"], out)
	return str(out[0]).strip_edges().get_slice(" ", 0) if not out.is_empty() else "?"
