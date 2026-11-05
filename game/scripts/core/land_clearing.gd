class_name LandClearing
extends RefCounted
## B25-ECON-P5 "Cleared by labour" (owner 2026-11-05: when households lack fields, villagers clear unused rough ground next to the
## village inside the village's lands as real work, days of labour, then till it; it ends when that ground is used up). In 120-day
## seed 1 (run 41967592798) the village's adults rose from 61 to 77 while its farmers stayed at 12: six manor fields of two farmers.
##
##   ground   the candidate blocks are rectangles of the village's own map, the biggest that fit first up to a manor field's size
##            (at least min_side x min_side and min_cells), nearest the fields among equals, looked for when none is in hand
##            (find_blocks, deterministic, saved): every cell is ground nobody uses (no road,
##            door trail, building, plot or farmland, pen, field, stall, station, chest, seam, pit, church plot, the village's
##            woods, water or wall), a cell's margin from fields and buildings kept; rough ground may hold wild plants, saplings,
##            trees, stumps and boulders. A block something else has taken since is dropped (block_ok). Finite: when the blocks are
##            used up there is no more.
##   want     the reeve posts one "clear" job at a time on the manor's board (ManorWork.post_clearing) while every manor field has
##            its field_workers_max farmers and an able adult has no work (wanted): the households lack fields.
##   work     a job is `cells_per_job` pieces of work on the block (a piece: one obstacle cleared, a boulder broken a unit, a cell tilled), worked one cell at a time by the existing rules, in the block's order:
##            a wild plant is pulled up; a sapling or young tree pulled up by hand; a grown tree is felled with an axe (World.fell
##            and work_felled: its logs are the village's through the felled_ ledger); a stump or growing tree dug out with an axe
##            (FarmPlots' rule); a boulder broken with a pickaxe a unit at a time (World.work_mine: its stone through the mined_
##            ledger); open ground is tilled by hand (Farming's hand tilling). Logs and stone ride in the job's load to the manor's
##            works yard. The time is the player's for the same work (Farming clear and till seconds, chop_minutes, mine_minutes).
##   field    when the block's last cell is tilled it becomes a manor field (World.fields: owner the manor, state tilled), and the
##            job market opens its farmers' places as for any field (NPCBrain.job_market). Its seed is the farmers' own (no free seed).
## Paid as any manor job (ManorWork: the wage set aside from the treasury when taken, paid when done). Nothing is created: the logs,
## stone and the ground were the village's. Every number is provisional (balance.json land_clearing; agent proposal).

var w
var blocks: Array = []        # [x, y, w, h] the candidate ground, nearest first (null-free once found)
var found := false            # whether find_blocks has run (saved)
var tilled: Dictionary = {}   # "x,y" (a block's origin) -> [cell index in the block, ...] tilled so far
var made := 0                 # fields made from cleared ground
var _ok_hour := -1            # the game hour current() last checked its block (the check reads the whole map; not saved)
var _scan_day := -1           # the day find_blocks last looked (not saved: a look finds the same from the same world)


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("land_clearing")


static func key(b: Array) -> String:
	return "%d,%d" % [int(b[0]), int(b[1])]


static func rect(b: Array) -> Rect2i:
	return Rect2i(int(b[0]), int(b[1]), int(b[2]), int(b[3]))


# ---------------------------------------------------------------- the ground -----------------
## The cells nobody may clear: a cell marked 1 is used (or is water or wall).
func _used_mask() -> PackedByteArray:
	var W: int = w.map.w
	var H: int = w.map.h
	var m := PackedByteArray()
	m.resize(W * H)
	var mark := func(r: Rect2i) -> void:
		r = r.intersection(Rect2i(0, 0, W, H))
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				m[y * W + x] = 1
	var clearable := {}
	for t in w.trees:
		if str(t.state) != "cleared":
			clearable[Vector2i(int(t.x), int(t.y))] = true
	for b in w.boulders:
		if int(b.amount) > 0:
			clearable[Vector2i(int(b.x), int(b.y))] = true
	for y in H:
		for x in W:
			if w.map.is_solid(Vector2i(x, y)) and not clearable.has(Vector2i(x, y)):
				m[y * W + x] = 1
	for c in w.map.data.road + w.map.data.get("door_trails", []):
		mark.call(Rect2i(int(c[0]), int(c[1]), 1, 1))
	for r in w.property.records():
		mark.call(Rect2i(int(r.x), int(r.y), int(r.w), int(r.h) + 1).grow(1))      # a building's front row and a cell round it
	for r in w.fields + w.fauna.pens.values() + w.map.data.get("woods", []):
		mark.call(Rect2i(int(r.x), int(r.y), int(r.w), int(r.h)).grow(1))
	if w.chapel != null and w.chapel.present:
		mark.call(w.chapel.plot_rect().grow(1))
	for id in w.stalls:
		mark.call(Rect2i(int(w.stalls[id].x), int(w.stalls[id].y), 1, 1).grow(1))
		mark.call(Rect2i(int(w.stalls[id].use[0]), int(w.stalls[id].use[1]), 1, 1))
	for id in w.stations:
		mark.call(Rect2i(int(w.stations[id].at[0]), int(w.stations[id].at[1]), 1, 1).grow(1))
		mark.call(Rect2i(int(w.stations[id].use[0]), int(w.stations[id].use[1]), 1, 1))
	for e in w.containers:
		mark.call(Rect2i(int(e.x), int(e.y), 1, 1))
	for d in w.deposits:
		if w.level_of(d) == 0:
			mark.call(Rect2i(int(d.x), int(d.y), 1, 1).grow(1))
	if w.pits != null:
		for p in w.pits.pits:
			mark.call(OpenPits.rect(p).grow(1))
			for h in p.heaps:
				mark.call(Rect2i(int(h.x), int(h.y), 1, 1))
	return m


## The candidate blocks: rectangles of unused ground within `reach` cells of the manor's fields, the biggest that fit first (a
## manor field's own size at most, min_side by min_side cells and min_cells in all at least), the nearest to the fields among
## equals, a cell apart from each other. Deterministic (the map's own cells, in order). Looked for at a need when none is in
## hand (current), so ground freed or left over later is found too; finite: the village's map holds only so much.
func find_blocks() -> void:
	found = true
	_scan_day = w.day()
	blocks = []
	if w.fields.is_empty():
		return
	var lc := cfg()
	var fw := int(w.fields[0].w)
	var fh := int(w.fields[0].h)
	var span := Rect2i(int(w.fields[0].x), int(w.fields[0].y), 0, 0)
	for f in w.fields:
		if not f.has("cleared_day"):                 # the village's own fields: ground cleared since does not stretch the reach
			span = span.merge(Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)))
	var near := span.grow(int(lc.reach))
	var centre := span.get_center()
	var m := _used_mask()
	var W: int = w.map.w
	var H: int = w.map.h
	var sizes := []
	for sw in range(int(lc.min_side), fw + 1):
		for sh in range(int(lc.min_side), fh + 1):
			if sw * sh >= int(lc.min_cells):
				sizes.append(Vector2i(sw, sh))
	sizes.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x * a.y > b.x * b.y or (a.x * a.y == b.x * b.y and (a.x > b.x or (a.x == b.x and a.y > b.y))))
	for k in int(lc.max_blocks):
		var sums := PackedInt32Array()
		sums.resize((W + 1) * (H + 1))
		for y in H:
			var row := 0
			for x in W:
				row += m[y * W + x]
				sums[(y + 1) * (W + 1) + x + 1] = sums[y * (W + 1) + x + 1] + row
		var pick := Rect2i()
		for size: Vector2i in sizes:
			var best := -1
			for y in range(maxi(1, near.position.y), mini(H - size.y, near.end.y - size.y) + 1):
				for x in range(maxi(1, near.position.x), mini(W - size.x, near.end.x - size.x) + 1):
					var used := sums[(y + size.y) * (W + 1) + x + size.x] - sums[y * (W + 1) + x + size.x] - sums[(y + size.y) * (W + 1) + x] + sums[y * (W + 1) + x]
					if used != 0:
						continue
					var d := (Rect2i(x, y, size.x, size.y).get_center() - centre).length_squared()
					if best < 0 or d < best:
						best = d
						pick = Rect2i(x, y, size.x, size.y)
			if best >= 0:
				break
		if pick.size == Vector2i.ZERO:
			break
		blocks.append([pick.position.x, pick.position.y, pick.size.x, pick.size.y])
		var g := pick.grow(1).intersection(Rect2i(0, 0, W, H))      # the next keeps a cell apart
		for y in range(g.position.y, g.end.y):
			for x in range(g.position.x, g.end.x):
				m[y * W + x] = 1


## Whether block `b` is still unused ground (nothing has been built, fenced or dug on it since it was found).
func block_ok(b: Array) -> bool:
	var m := _used_mask()
	var r := rect(b)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if m[y * w.map.w + x] == 1:
				return false
	return true


## The block being cleared or next to be, {} when the ground is used up. A block that is no longer free is dropped (and its tilling).
func current() -> Array:
	if blocks.is_empty() and _scan_day != w.day():
		find_blocks()                                # none in hand: look again (once a day at most)
	var hour := int(w.minutes / 60.0)
	while not blocks.is_empty():
		var b: Array = blocks[0]
		if _ok_hour == hour or block_ok(b):
			_ok_hour = hour
			return b
		tilled.erase(key(b))
		blocks.pop_front()
		_ok_hour = -1
		w.stat("land_clearing_blocks_lost")
	return []


## The rectangles being cleared now (other uses of the ground keep off them: Construction._free_sums).
func reserved() -> Array:
	var out := []
	if not blocks.is_empty() and tilled.has(key(blocks[0])):
		out.append(rect(blocks[0]))
	return out


## The households lack fields: every manor field has its farmers and an able adult has no work.
func wanted() -> bool:
	var most := int(GameData.b("field_workers_max"))
	for f in w.fields:
		if w.field_workers(f).size() < most:
			return false
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "":
			return true
	return false


# ---------------------------------------------------------------- the work -------------------
## The tool kind clearing cell `c` needs ("" by hand; "axe", "pickaxe"), or "-" when it cannot be cleared at all.
func tool_for(c: Vector2i) -> String:
	var o: Dictionary = w.farm.obstacle(c)
	if o.is_empty():
		return ""
	match str(o.kind):
		"plant":
			return ""
		"tree":
			return "" if str(o.ref.state) in ["sapling", "young"] else "axe"
		"boulder":
			return "pickaxe"
	return "-"


static func _has(who, kind: String) -> bool:
	if who == null:
		return false
	if kind == "axe":
		return FarmPlots.has_axe(who.inv)
	return OpenPits.held_tool(who, kind) != ""


## The next cell of block `b` that `who` can work with what they hold (row by row), Vector2i(-1, -1) when none.
func next_cell(b: Array, who) -> Vector2i:
	var r := rect(b)
	var done: Array = tilled.get(key(b), [])
	for i in r.size.x * r.size.y:
		if done.has(i):
			continue
		var c := r.position + Vector2i(i % r.size.x, i / r.size.x)
		var t := tool_for(c)
		if t == "-" or (t != "" and not _has(who, t)):
			continue
		return c
	return Vector2i(-1, -1)


## Game minutes `c`'s next piece of work takes (the player's time for it).
func minutes_for(c: Vector2i) -> float:
	var gm := float(GameData.b("game_minutes_per_second"))
	var o: Dictionary = w.farm.obstacle(c)
	var fc: Dictionary = Farming.cfg()
	if o.is_empty():
		return float(fc.till.hand.seconds) * gm
	match str(o.kind):
		"plant":
			return float(fc.clear.bush_seconds) * gm
		"tree":
			if str(o.ref.state) == "grown":
				return float(GameData.b("chop_minutes")) * float(cfg().fell_chops)
			return w.farm.clear_seconds(o.ref) * gm
		"boulder":
			return float(GameData.b("mine_minutes"))
	return 60.0


## One piece of work at cell `c` of block `b` by `who` (an NPC), its yield into `load`. Returns true when it was done (an obstacle
## cleared or broken a unit, or the cell tilled), false when it could not be.
func work(b: Array, c: Vector2i, who, load: Inventory) -> bool:
	var o: Dictionary = w.farm.obstacle(c)
	if not o.is_empty():
		match str(o.kind):
			"plant":
				o.ref.state = "cleared"
				w.tile_changed.emit(c, World.PLANT_LAYER, -1)
				w.stat("land_cleared_plant")
			"tree":
				var t: Dictionary = o.ref
				if str(t.state) == "grown":
					var logs: int = w.fell(t, int(Skills.value(who, "woodcutting", "log_bonus")))
					var r: Dictionary = w.work_felled(who, logs, load)
					if r.broke and who is NPC:
						w.note("%s %s's axe broke clearing ground for the manor." % [who.name, who.family])
				else:
					t.state = "cleared"
					w.map.set_solid(c, false)
					w.tree_changed.emit(t)
				w.stat("land_cleared_tree")
			"boulder":
				var r: Dictionary = w.work_mine(who, o.ref, load)
				if str(r.get("result", "")) != "ok":
					return false
				if r.broke and who is NPC:
					w.note("%s %s's pickaxe broke clearing ground for the manor." % [who.name, who.family])
				w.stat("land_cleared_stone")
		return true
	var r := rect(b)
	var i := (c.y - r.position.y) * r.size.x + (c.x - r.position.x)
	if not tilled.has(key(b)):
		tilled[key(b)] = []
	if not (tilled[key(b)] as Array).has(i):
		tilled[key(b)].append(i)
		w.stat("land_tilled_cells")
		_show_cell(b, i)
	if (tilled[key(b)] as Array).size() >= r.size.x * r.size.y:
		_make_field(b)
	return true


## The block's last cell is tilled: it is a manor field from now on, tilled and ready for its farmers' seed.
func _make_field(b: Array) -> void:
	tilled.erase(key(b))
	blocks.erase(b)
	made += 1
	var ids := {}
	for f in w.fields:
		ids[str(f.id)] = true
	var k := made
	while ids.has("fc%d" % k):
		k += 1
	var f := {"id": "fc%d" % k, "x": int(b[0]), "y": int(b[1]), "w": int(b[2]), "h": int(b[3]), "state": "tilled", "crop": 0,
		"ready": 0.0, "ripe_at": 0.0, "owner": World.MANOR, "tenant": "", "cleared_day": w.day()}
	w.fields.append(f)
	w.set_field(f, "tilled")
	w.stat("fields_cleared")
	w.note("New ground is broken for the manor: a field %s is cleared and tilled, and two farmers' places are open on it." % w.where(rect(b)))


func _show_cell(b: Array, i: int) -> void:
	var r := rect(b)
	var base: int = w.map.data.tiles.field.tilled
	var cols := int(w.map.data.atlases[0].columns)
	w.tile_changed.emit(r.position + Vector2i(i % r.size.x, i / r.size.x), "field",
		World.field_cell_tile(base, r.size.x, r.size.y, i % r.size.x, i / r.size.x, cols))


## Draw the tilled cells of the block in hand (after a load; the fields draw themselves).
func show_all() -> void:
	for b in blocks:
		for i in tilled.get(key(b), []):
			_show_cell(b, int(i))


# ---------------------------------------------------------------- saving ---------------------
func to_dict() -> Dictionary:
	return {"found": found, "blocks": blocks.duplicate(true), "tilled": tilled.duplicate(true), "made": made}


func load_dict(d: Dictionary) -> void:
	found = bool(d.get("found", false))
	blocks = []
	for b in d.get("blocks", []):
		blocks.append([int(b[0]), int(b[1]), int(b[2]), int(b[3])])
	tilled = {}
	var t: Dictionary = d.get("tilled", {})
	for k in t:
		tilled[str(k)] = (t[k] as Array).map(func(v): return int(v))
	made = int(d.get("made", 0))
