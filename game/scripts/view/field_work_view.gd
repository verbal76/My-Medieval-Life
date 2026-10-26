class_name FieldWorkView
extends RefCounted
## GP-FARMER-TENDING (owner, 2026-10-24: "They should be walking through their field maybe with a shovel poking the ground every now
## and then"; Build 22): how a villager at work on a field is DRAWN. Presentation only: the simulation keeps the worker where it put
## them (NPC.pos, at the field's edge or the plot's first cell), for exactly the minutes, cells, seed, yield and tool wear it always
## had; this reads the work step the villager is in (which field or plot, which task, how much of it is done: the step's minutes
## and NPCBrain's work_left) and returns where to draw them and what they are doing at that moment of the work:
##  - the step is cut into stops, one about every STOP_MINUTES of game time (at least MIN_STOPS); at each stop the worker walks
##    (WALK_SHARE of the stop) to the next cell of their tour and then works it with a shovel (the swing frames, the shovel's icon
##    in the hand: the art packs have a shovel, no hoe);
##  - the tour runs through the field's own cells in rows, back and forth, starting at a cell that depends on the villager's id, so
##    two farmers on one field are spread over it; a family plot's batch tours exactly the cells the step works;
##  - the steps drawn so: the manor farmer's sowing and cutting (NPCBrain._farmer, acts "sow" and "harvest", the field in args),
##    the farmer tending the growing crop (the step marked with the field, NPCBrain._farmer), and work on a household's or the
##    church's farmland (FarmPlots._batch, act "fp_work", its cells in args: elders and volunteers too).
## Deterministic (no randomness, no clock but the step's own progress); nothing here is ever written to the world. A guest's copy
## draws from the step and work_left the host last sent (NetSync), so a guest sees the same tour, updated as the records come.

const STOP_MINUTES := 10.0     # game minutes of work per stop
const MIN_STOPS := 3
const WALK_SHARE := 0.3        # of each stop, the walk to its cell
const TOOL := "shovel"
const FIELD_ACTS := ["sow", "harvest"]


## {pos (tiles, the feet), anim ("walk" or "swing"), tool, facing, cell} for villager `n` at work on a field now; {} otherwise.
static func pose(w: World, n: NPC) -> Dictionary:
	if n == null or n.plan.is_empty() or str(n.plan[0].get("k", "")) != "work":
		return {}
	var s: Dictionary = n.plan[0]
	var cells := cells_of(w, s)
	if cells.is_empty():
		return {}
	var total := maxf(1.0, float(s.get("min", 0.0)))
	var done := clampf(total - n.work_left, 0.0, total)
	return pose_at(cells, n.id, done / total, total, n.pos)


## The cells a work step works or tends, in tour order (rows back and forth); [] for a step that is not field work.
static func cells_of(w: World, s: Dictionary) -> Array:
	var act := str(s.get("act", ""))
	var args: Dictionary = s.get("args", {}) if s.get("args") is Dictionary else {}
	if act == "fp_work":
		var out := []
		for c in args.get("cells", []):
			out.append(Vector2i(int(c[0]), int(c[1])))
		return out
	var fid := ""
	if act in FIELD_ACTS:
		fid = str(args.get("field", ""))
	elif act == "" and s.has("field"):
		fid = str(s.field)                    # tending: the farmer's watch over the growing crop (NPCBrain._farmer)
	if fid == "":
		return []
	for f in w.fields:
		if str(f.id) == fid:
			return field_tour(Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)))
	return []


## A field's cells in rows, left to right then right to left.
static func field_tour(r: Rect2i) -> Array:
	var out := []
	for j in r.size.y:
		for i in r.size.x:
			var x := r.position.x + (i if j % 2 == 0 else r.size.x - 1 - i)
			out.append(Vector2i(x, r.position.y + j))
	return out


## The pose at fraction `t` (0..1) of a step of `total` game minutes over `cells`, for villager `id` standing at `stand`.
static func pose_at(cells: Array, id: int, t: float, total: float, stand: Vector2) -> Dictionary:
	var stops := maxi(MIN_STOPS, roundi(total / STOP_MINUTES))
	var x := clampf(t, 0.0, 0.999999) * stops
	var k := int(floor(x))
	var into := x - k
	var start := (id * 37) % cells.size()       # two workers on one field start far apart
	var here := _spot(cells[(start + k) % cells.size()])
	var from := stand if k == 0 else _spot(cells[(start + k - 1) % cells.size()])
	if into < WALK_SHARE and from.distance_to(here) > 0.01:
		var at := from.lerp(here, into / WALK_SHARE)
		return {"pos": at, "anim": "walk", "tool": "", "facing": (here - from).normalized(), "cell": cells[(start + k) % cells.size()]}
	return {"pos": here, "anim": "swing", "tool": TOOL, "facing": Vector2.DOWN, "cell": cells[(start + k) % cells.size()]}


## Where a worker stands to work cell `c`: on it, the feet a little below its middle.
static func _spot(c: Vector2i) -> Vector2:
	return Vector2(c) + Vector2(0.5, 0.6)
