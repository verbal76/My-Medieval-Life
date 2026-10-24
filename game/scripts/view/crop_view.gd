class_name CropView
extends Node2D
## VIS-CROP-01 (owner, B18-DIR Part 9): the plants on every field, drawn one 16 px plant per cell over the field's
## ground (the tilled-soil edge set every field cell now shares, so a field whose cells are in different states reads
## as one field). A child of the village's MapView, just over the field layer and under the characters, so it fades
## with the surface as the ground does.
##
## Looks only: it reads the fields' and cells' existing state and never changes it.
##  - growing: the crop's plant a quarter, half, three quarters or nearly grown, by its growth so far;
##  - ripe: the grown plant (for wheat, golden ears of grain);
##  - tilled: bare soil, except a manor wheat field cut since it was last ripe and not sown again (it was ripe once,
##    `ripe_at`, and is tilled now), which shows stubble, and a cell of a player's or a household's plot whose wheat was
##    cut (its `cut`, until it is sown again; other crops leave bare soil).
##  - GP-WHEAT-PICKED (owner 2026-10-24): a ripe manor field being cut shows stubble on the share of its cells that matches
##    the share of its crop taken (World.field_full_crop), or the share of a farmer's cutting done, the cells nearest the
##    harvester first (the player's first handful, World.player_harvest `cut_from`; a cutting farmer where they stand).
## The art is game/assets/tiles/crops.png (tools/import_game_assets.py _import_crops): a row per crop, columns 0-3
## growing, 4 ripe, 5 stubble (wheat).

const T := 16
const ROWS := {"wheat": 0, "carrot": 1, "potato": 2, "herb": 3}      # import_game_assets.py CROP_ORDER
const RIPE := 4
const STUBBLE := 5
const EVERY := 0.5          # seconds between looks at the fields (growth is slow; a harvest shows within this)

var world: World
var tex: Texture2D
var shown: Array = []       # [x, y, row, column] of every plant drawn, to redraw only on a change
var wait := 0.0


func setup(w: World) -> void:
	world = w
	tex = load("res://assets/tiles/crops.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	refresh()


func _process(dt: float) -> void:
	wait -= dt
	if wait <= 0.0:
		wait = EVERY
		refresh()


## Work out every plant to draw; redraw only when one changed.
func refresh() -> void:
	if world == null:
		return
	var now := plants()
	if now != shown:
		shown = now
		queue_redraw()


## [x, y, row, column] of every field cell that shows a plant or stubble, in a fixed order.
func plants() -> Array:
	var out := []
	for f in world.fields:                       # the manor's fields: wheat
		var col := field_column(f)
		if col < 0:
			continue
		var cut := cut_cells(f) if col == RIPE else {}
		for j in int(f.h):
			for i in int(f.w):
				var c := Vector2i(int(f.x) + i, int(f.y) + j)
				out.append([c.x, c.y, ROWS.wheat, STUBBLE if cut.has(c) else col])
	for cells: Dictionary in [world.farm.cells, world.farm_plots.cells]:
		var keys := cells.keys()
		keys.sort()
		for c: Vector2i in keys:
			var cell: Dictionary = cells[c]
			var col := stage_column(str(cell.state), float(cell.get("progress", 0.0)))
			if col >= 0 and ROWS.has(str(cell.crop)):
				out.append([c.x, c.y, int(ROWS[str(cell.crop)]), col])
			elif str(cell.state) == "tilled" and str(cell.get("cut", "")) == "wheat":
				out.append([c.x, c.y, ROWS.wheat, STUBBLE])          # GP-WHEAT-PICKED: cut wheat leaves stubble
	return out


## The column a manor field's cells show (-1: bare soil).
func field_column(f: Dictionary) -> int:
	match str(f.state):
		"tilled":
			return STUBBLE if f.has("ripe_at") else -1
		"ripe":
			return RIPE
		"growing":
			return stage_column("growing", field_growth(f))
	return -1


## GP-WHEAT-PICKED: the cells of a ripe manor field already cut, as a set: as many as the share cut (the crop taken since
## it ripened, or the furthest a farmer cutting it has got through the work), nearest the harvester first (ties by row,
## then column, so it is the same every time). Looks only.
func cut_cells(f: Dictionary) -> Dictionary:
	var n := int(f.w) * int(f.h)
	var full := world.field_full_crop(f)
	var share := 0.0 if full <= 0 else 1.0 - float(f.get("crop", full)) / float(full)
	var from := Vector2(float(f.x), float(f.y) + float(f.h))        # no harvester known: from the south-west corner
	if f.has("cut_from"):
		from = Vector2(float(f.cut_from[0]), float(f.cut_from[1]))
	for o: NPC in world.npcs:
		if o.plan.is_empty() or not o.alive:
			continue
		var st: Dictionary = o.plan[0]
		if str(st.get("k", "")) != "work" or str(st.get("act", "")) != "harvest" or str((st.get("args", {}) as Dictionary).get("field", "")) != str(f.id):
			continue
		var done := clampf(1.0 - o.work_left / maxf(float(st.get("min", 1.0)), 1.0), 0.0, 1.0)
		if done > share:
			share = done
			from = o.pos
	var k := clampi(floori(share * n + 1e-6), 0, n)
	if k == 0:
		return {}
	var cells := []
	for j in int(f.h):
		for i in int(f.w):
			var c := Vector2i(int(f.x) + i, int(f.y) + j)
			cells.append([(Vector2(c) + Vector2(0.5, 0.5)).distance_squared_to(from), j, i, c])
	cells.sort()
	var out := {}
	for e in cells.slice(0, k):
		out[e[3]] = true
	return out


## How far a manor field has grown, 0..1: its seasonal growth (FSE-13) or, on the clock, the share of its growing
## time gone by.
func field_growth(f: Dictionary) -> float:
	if f.has("progress") and float(f.get("ready", 0.0)) >= 1.0e17:
		return float(f.progress)
	var span: float = world.field_grow_days(f) * World.DAY
	return clampf(1.0 - (float(f.get("ready", world.minutes)) - world.minutes) / maxf(span, 1.0), 0.0, 1.0)


## The column for a state and growth: a growing plant's quarter (0-3), ripe, or -1 for bare tilled soil.
static func stage_column(state: String, growth: float) -> int:
	match state:
		"growing":
			return clampi(int(growth * 4.0), 0, 3)
		"ripe":
			return RIPE
	return -1


func _draw() -> void:
	if tex == null:
		return
	for p in shown:
		draw_texture_rect_region(tex, Rect2(int(p[0]) * T, int(p[1]) * T, T, T), Rect2(int(p[3]) * T, int(p[2]) * T, T, T))
