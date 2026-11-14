extends SceneTree
## B42 (B25-MOVE-STUTTER-INV; owner 2026-11-14, "the character would advance, briefly freeze, advance again, and freeze again"
## walking south along the trails): the chunk prepared ahead of the walk (OverworldView._prefetch) was generated on the main
## thread, 26-140 ms a chunk, on several frames in a row at every chunk crossing (152 of the 215 frames over 50 ms on the southern
## walk, docs/audits/2026-11-14_B42_MOVEMENT_STUTTER_MEASUREMENTS.md). It is now generated on a background thread by a private
## Overworld and adopted into the world's cache. This test:
##  1. the worker's chunks are the world's own: a private Overworld laid out the way the worker lays it out (on a thread),
##     generating the chunks along the route south and round it, gives every field of every chunk, and the rim steps it records,
##     exactly as the world's own get_chunk does;
##  2. in the game scene, walking south from the village gate, the view's prefetch takes under PREFETCH_MS of the main thread on
##     every frame (before: each chunk's generation, 26-140 ms), chunks are adopted from the worker, and each adopted chunk
##     equals a fresh generation of it.
##   godot --headless --path game -s res://tests/chunk_prefetch_test.gd [-- sync]
## `sync` walks with the old main-thread prefetch (async_prefetch off): the failing case, for the record.

const PREFETCH_MS := 15.0        # a frame's _prefetch over this is counted (a chunk's generation is 26 ms or more, 70 ms loaded)
const MOST_OVER := 5             # at most this many (preemption on a loaded machine; the old main-thread prefetch: 64 here)
const WORST_MS := 50.0           # and none over this
const STEP := 0.3                # tiles the walk moves a frame (4 x walking pace: more crossings in fewer frames)
const FRAMES := 1500

var main
var checks := 0
var failures := 0
var frames := 0
var route: PackedVector2Array
var idx := 0
var worst_prefetch := 0.0
var over := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	GameData.ensure()
	_part1()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_chunk_prefetch/save.json"
	process_frame.connect(_begin, CONNECT_ONE_SHOT)


static func same(a: Overworld.Chunk, b: Overworld.Chunk) -> bool:
	for f in ["cx", "cy", "ground", "path", "deco", "solid", "kind", "snow", "trees", "road", "top", "water", "flow", "level", "bank"]:
		if a.get(f) != b.get(f):
			print("     differs: chunk (%d, %d) field %s" % [a.cx, a.cy, f])
			return false
	return true


func _route_chunks(w: World) -> Array:
	var ow: Overworld = w.map.overworld
	var gate := Vector2i(ow.gates[0].out)
	for g in ow.gates:
		if g.out.y > gate.y:
			gate = Vector2i(g.out)
	var r := RegionTravel.plan(w, gate, Vector2i(195, 700))       # seed 1: Milton, by Wendholt (the owner's way south)
	var want := {}
	var out: Array = []
	for p in (r.get("cells", []) as Array):
		var cc := Overworld.chunk_of(Vector2i(p))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var c: Vector2i = cc + Vector2i(dx, dy)
				if not want.has(c) and not ow.chunk_in_village(c):
					want[c] = true
					out.append(c)
	return out


## 1: the private Overworld (as the worker makes it, on a thread) against the world's own.
func _part1() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var ow: Overworld = w.map.overworld
	var todo := _route_chunks(w)
	var snap := VillageMap.new()
	snap.w = w.map.w
	snap.h = w.map.h
	snap.data = {"stamps": (w.map.data.stamps as Dictionary).duplicate(true)}
	var gates: Array = []
	for g in ow.gates:
		gates.append({"out": g.out, "dir": g.dir})
	var th := Thread.new()
	th.start(func() -> Dictionary:
		var o := Overworld.create(ow.seed, snap, ow.gen, gates)
		var res := {}
		for cc: Vector2i in todo:
			res[cc] = o._generate(cc.x, cc.y)
		return {"chunks": res, "works": o.fixed_works.duplicate()})
	var got: Dictionary = th.wait_to_finish()
	var bad := 0
	for cc: Vector2i in todo:
		if not same(got.chunks[cc], ow.get_chunk(cc)):
			bad += 1
	check(todo.size() > 60 and bad == 0, "the worker's private Overworld (made on a thread) generates %d chunks along the way south and round it exactly as the world's own get_chunk (%d differ)" % [todo.size(), bad])
	var wbad := 0
	var wn := 0
	for cc: Vector2i in todo:
		for y in Overworld.CHUNK:
			for x in Overworld.CHUNK:
				var c := Vector2i(cc.x * Overworld.CHUNK + x, cc.y * Overworld.CHUNK + y)
				if ow.fixed_works.has(c) or got.works.has(c):
					wn += 1
					if str(ow.fixed_works.get(c, "")) != str(got.works.get(c, "")):
						wbad += 1
	check(wbad == 0, "the rim steps the generation records (fixed_works) are the same: %d cells, %d differ" % [wn, wbad])


func _begin() -> void:
	main.new_game()
	var w: World = main.world
	var ow: Overworld = w.map.overworld
	var gate := Vector2i(ow.gates[0].out)
	for g in ow.gates:
		if g.out.y > gate.y:
			gate = Vector2i(g.out)
	var r := RegionTravel.plan(w, gate, Vector2i(195, 700))
	route = r.cells
	w.player.pos = Vector2(gate) + Vector2(0.5, 0.5)
	main.ow_view.set("profiling", true)
	if OS.get_cmdline_user_args().has("sync"):
		main.ow_view.set("async_prefetch", false)
	check(main.ow_view.get("async_prefetch") == true, "the view prepares chunks ahead on a background thread (async_prefetch)")
	process_frame.connect(_frame)


func _frame() -> void:
	frames += 1
	var w: World = main.world
	var pf := float(int((main.ow_view.get("prof") as Dictionary).get("ow:prefetch", 0))) / 1000.0
	var pc := float(int((main.ow_view.get("prof") as Dictionary).get("ow:prefetch(collect)", 0))) / 1000.0
	if pf > PREFETCH_MS:
		print("     frame %d: prefetch %.2f ms (collecting %.2f)" % [frames, pf, pc])
	main.ow_view.set("prof", {})
	if frames > 5:
		worst_prefetch = maxf(worst_prefetch, pf)
		if pf > PREFETCH_MS:
			over += 1
	# the player is carried along the route (the view follows the player; the walk itself is tested elsewhere)
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
	var adopted := int(main.ow_view.get("prefetch_adopted"))
	print("     %d frames, %.0f tiles south to y %.0f; prefetch on the main thread: worst %.2f ms, %d frames over %.0f ms; %d chunks adopted from the worker" % [
			frames, float(idx), w.player.pos.y, worst_prefetch, over, PREFETCH_MS, adopted])
	check(over <= MOST_OVER and worst_prefetch < WORST_MS, "the view's prefetch holds the main thread over %.0f ms on at most %d frames (%d) and never %.0f ms (worst %.2f ms)" % [PREFETCH_MS, MOST_OVER, over, WORST_MS, worst_prefetch])
	check(adopted >= 10, "chunks prepared ahead come from the worker: %d adopted" % adopted)
	# every chunk in the cache equals a fresh generation (the adopted ones included)
	var ow: Overworld = w.map.overworld
	var fresh := Overworld.create(ow.seed, w.map, ow.gen, ow.gates)
	var bad := 0
	for cc: Vector2i in ow.cache:
		if not same(ow.cache[cc], fresh._generate(cc.x, cc.y)):
			bad += 1
	check(bad == 0, "every chunk in the world's cache (%d, the adopted ones among them) equals a fresh generation of it (%d differ)" % [ow.cache.size(), bad])
	if main.ow_view.has_method("_pf_stop"):
		main.ow_view.call("_pf_stop")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
