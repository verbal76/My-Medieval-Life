class_name OpenPits
extends RefCounted
## MIN-E open-pit excavation (Mining spec stage 3, sections 6, 7 and 11, phase E; docs/build17/MIN_E_OPEN_PIT.md).
##
## Where: on the surface (owner OD-29: open pits stay on the surface; the underground is MIN-F's), in the village grid.
## A pit is a square of `size` cells staked on clear common ground (the layout's open ground, clear now, no road,
## building, parcel, field, pen, market, station, tree, plant or farmland) with a border of walkable ground round it (a
## road may run by: the way round stays open), and `heaps` spoil heap cells beside it. The map has one plane (MIN_A_ARCHITECTURE.md section 3), so depth is per cell:
## every cell keeps how many units have been dug from it (`dug`), and the layers under every cell are the same finite
## table (open_pit.json: topsoil, dirt, spoil, then stone). Whole layers dug are the cell's depth; a cell of ring r is
## dug to `ring_depth[r]`, so the sides are terraced. The ramp cells (one per ring, from the north edge to the middle)
## are walkable at every depth; every other cell dug below the surface is solid (a terrace wall, a cut). A dig that
## would leave a walkable cell of the pit cut off from its border is refused (DVW-A10: no unreachable pit cell).
##
## Digging (PAR-01: one rule for the player and a villager): the layer's tool (owner MIN-E-Q4, 2026-10-21: a shovel
## for the earth, topsoil, dirt and spoil; a pickaxe for the rock; open_pit.json layers' `tool`), one unit at a time, the unit's layer item into
## the digger's inventory (or a manor job's load), counted dug_<item>; the tool wears, Mining xp is earned. When a
## cell other than the ramp is dug down to the rock layer, a prospecting body within `expose_reach` cells is opened
## there as an ordinary seam (Discovery.expose: the trial pit's own rule; OD-28: one deposit system everywhere); its ore
## and host rock are mined by World.work_mine like any seam and never refilled. Nothing is made: the ground of a pit is a
## finite pool counted pit_ground_<item> when the pit is staked, and every unit leaves it as dug_<item> or comes back
## by backfill (backfilled_<item>, the last dug first). Earth (topsoil, dirt, spoil) is tipped onto the pit's spoil
## heaps (an Inventory each, solid while it holds anything: storage has a place and a cost), taken back from them, or
## carried away like any goods; stone is kept (the manor's goes to the works yard). Saved with the world ("pits").
##
## The manor commissions a pit (ManorWork "excavate", paid for the labour from the treasury like its other jobs) only
## for a find it knows that no trial pit can reach any more, near the readings it knows: digging may miss (WDR-022).
## The settlement's capability evaluator counts a finished ramp as a "pit_ramp" structure; no level gates anything
## (owner Q18-9).

signal changed

const GEN_VERSION := 1

static var _cfg := {}

var w: World
var pits: Array = []       # {id, x, y, owner, for (a clue id or ""), day, dug: [units per cell, row-major], heaps: [{x, y, inv}]}
var next_id := 1
var _open := PackedByteArray()   # the static layout's open ground (Prospecting._open_cells)


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/open_pit.json"))
	return _cfg


static func create(world: World) -> OpenPits:
	var p := OpenPits.new()
	p.w = world
	p._open = Prospecting._open_cells(world.map)
	return p


# ---------------------------------------------------------------- the layers -----------------
static func size() -> int:
	return int(cfg().size)


static func layers() -> Array:
	return cfg().layers


## Units in the layers above layer `k` (cum(0) = 0, cum(layers) = a full column).
static func cum(k: int) -> int:
	var n := 0
	for i in mini(k, layers().size()):
		n += int(layers()[i].amount)
	return n


## Whole layers dug when `dug` units are out of a cell.
static func depth_of(dug: int) -> int:
	var k := 0
	while k < layers().size() and cum(k + 1) <= dug:
		k += 1
	return k


## The item of the `u`-th unit dug from a cell (0 the first).
static func item_of(u: int) -> String:
	for k in layers().size():
		if u < cum(k + 1):
			return str(layers()[k].item)
	return ""


## The kind of tool the `u`-th unit of a cell is dug with (open_pit.json layers' `tool`: "shovel" for the earth,
## "pickaxe" for the rock); "" past the last layer.
static func tool_of(u: int) -> String:
	for k in layers().size():
		if u < cum(k + 1):
			return str(layers()[k].get("tool", "pickaxe"))
	return ""


## The earth above the rock under one cell, by item, top first (a trial pit's column, MIN-D-Q3): [[item, units], ...].
static func earth_column() -> Array:
	var out := []
	for k in rock_depth():
		out.append([str(layers()[k].item), int(layers()[k].amount)])
	return out


## The item `who` (the player or a villager) would dig with for a tool of `kind` ("" if they hold none): the player's
## chosen tool of that kind or their best (PlayerState.tool_of); a villager's of that id, else any of that kind.
static func held_tool(who, kind: String) -> String:
	if kind == "" or who == null:
		return ""
	if who is PlayerState:
		return who.tool_of(kind)
	if who.inv.has(kind):
		return kind
	for id in who.inv.ids():
		if str(GameData.item(id).get("tool", "")) == kind:
			return id
	return ""


static func tool_word(kind: String) -> String:
	return GameData.item_name(kind).to_lower() if GameData.items.has(kind) else kind


static func minutes_of(u: int) -> float:
	for k in layers().size():
		if u < cum(k + 1):
			return float(layers()[k].minutes)
	return 0.0


## The depth (whole layers) at which a cell reaches the rock layer.
static func rock_depth() -> int:
	for k in layers().size():
		if layers()[k].get("rock", false):
			return k
	return layers().size()


## Earth: the layers' items that are not kept (they go onto the spoil heaps).
static func earth_items() -> Array:
	var out := []
	for l in layers():
		if not l.get("keep", false) and not out.has(str(l.item)):
			out.append(str(l.item))
	return out


static func ring_of(i: int) -> int:
	var s := size()
	var x := i % s
	var y := i / s
	return mini(mini(x, y), mini(s - 1 - x, s - 1 - y))


## Whole layers cell `i` is dug to: its ring's depth (the terraces).
static func target(i: int) -> int:
	var rd: Array = cfg().ring_depth
	return mini(int(rd[mini(ring_of(i), rd.size() - 1)]), layers().size())


static func cap(i: int) -> int:
	return cum(target(i))


## The ramp: one cell per ring on the middle column, from the north edge down to the middle.
static func is_ramp(i: int) -> bool:
	var s := size()
	return i % s == s / 2 and i / s <= (s - 1) / 2


# ---------------------------------------------------------------- places ---------------------
static func rect(p: Dictionary) -> Rect2i:
	return Rect2i(int(p.x), int(p.y), size(), size())


static func cell_of(p: Dictionary, i: int) -> Vector2i:
	return Vector2i(int(p.x) + i % size(), int(p.y) + i / size())


static func index(p: Dictionary, c: Vector2i) -> int:
	if not rect(p).has_point(c):
		return -1
	return (c.y - int(p.y)) * size() + (c.x - int(p.x))


func pit(id: int) -> Dictionary:
	for p in pits:
		if int(p.id) == id:
			return p
	return {}


func pit_at(c: Vector2i) -> Dictionary:
	for p in pits:
		if rect(p).has_point(c):
			return p
	return {}


## {pit, i} of the spoil heap on cell `c`, or {}.
func heap_at(c: Vector2i) -> Dictionary:
	for p in pits:
		for i in (p.heaps as Array).size():
			if int(p.heaps[i].x) == c.x and int(p.heaps[i].y) == c.y:
				return {"pit": p, "i": i}
	return {}


## Why nothing else may be put on cell `c` ("" if it is not a pit's): the pit, its border and its heaps.
func ground_refusal(c: Vector2i) -> String:
	for p in pits:
		if rect(p).grow(1).has_point(c):
			return "That ground is an open pit."
		for h in p.heaps:
			if int(h.x) == c.x and int(h.y) == c.y:
				return "That is a spoil heap."
	return ""


## The land office's check (Property.can_claim): no land is claimed over a pit, its border or its heaps.
func claim_refusal(r: Rect2i) -> String:
	for p in pits:
		if rect(p).grow(1).intersects(r):
			return "an open pit"
		for h in p.heaps:
			if r.has_point(Vector2i(int(h.x), int(h.y))):
				return "a spoil heap"
	return ""


func _static_open(c: Vector2i) -> bool:
	var m := w.map
	return m.in_village(c) and c.x >= 0 and c.y >= 0 and c.x < m.w and c.y < m.h and _open[c.y * m.w + c.x] == 1


func _someone_on(c: Vector2i) -> bool:
	if w.player_level == 0 and Vector2i(w.player.pos.floor()) == c:
		return true
	for n: NPC in w.npcs:
		if n.alive and n.depth == 0 and n.cell() == c:
			return true
	return false


## Something lying or parked on the cell (a cart, a pile of goods) that a cut would bury.
func _something_on(c: Vector2i) -> bool:
	for k in w.carts.carts:
		if Vector2i((k.pos as Vector2).floor()) == c:
			return true
	for l in w.loot:
		if World.level_of(l) == 0 and Vector2i((l.pos as Vector2).floor()) == c:
			return true
	return false


## A seam record on the cell (opened in the pit, MIN-D): the seam's own rules hold its cell.
func _seam_on(c: Vector2i) -> Dictionary:
	for d in w.deposits:
		if int(d.x) == c.x and int(d.y) == c.y and World.level_of(d) == 0:
			return d
	return {}


# ---------------------------------------------------------------- staking a pit --------------
## Where a pit lies when it is staked from the cell `ahead` of someone facing `dir`: the near side's border runs
## through `ahead`, the pit beyond it.
static func origin_ahead(ahead: Vector2i, dir: Vector2) -> Vector2i:
	var s := size()
	var h := s / 2
	if absf(dir.x) > absf(dir.y):
		return Vector2i(ahead.x + 1, ahead.y - h) if dir.x > 0 else Vector2i(ahead.x - s, ahead.y - h)
	return Vector2i(ahead.x - h, ahead.y + 1) if dir.y >= 0 else Vector2i(ahead.x - h, ahead.y - s)


## A cheap first look (no plant or land check): the pit lies on the layout's open ground and its border on walkable
## ground of the village, all clear now.
func site_open(origin: Vector2i) -> bool:
	var s := size()
	var inner := Rect2i(origin, Vector2i(s, s))
	for y in range(origin.y - 1, origin.y + s + 1):
		for x in range(origin.x - 1, origin.x + s + 1):
			var c := Vector2i(x, y)
			if not w.map.in_village(c) or w.map.is_solid(c) or (inner.has_point(c) and not _static_open(c)):
				return false
	return true


## Why a pit cannot be staked at `origin` ("" if it can): the pit on clear common ground (the layout's open ground;
## nothing planted, built, claimed, farmed, parked or standing there now), a border of walkable ground round it that no
## other pit holds (a road may run by: the way round stays open), and room beside it for its spoil heaps.
func site_refusal(origin: Vector2i) -> String:
	var s := size()
	var inner := Rect2i(origin, Vector2i(s, s))
	for y in range(origin.y - 1, origin.y + s + 1):
		for x in range(origin.x - 1, origin.x + s + 1):
			var c := Vector2i(x, y)
			if not w.map.in_village(c) or w.map.is_solid(c):
				return "The ground there is not clear enough for a pit."
			var other := ground_refusal(c)
			if other != "":
				return other
			if not inner.has_point(c):
				continue
			if not _static_open(c):
				return "The ground there is not clear enough for a pit."
			var why := w.plant_refusal(c)
			if why != "":
				return why
			if not w.farm_plots.plot_at(c).is_empty() or not w.farm.parcel_at(c).is_empty():
				return "That is farmland."
			if _something_on(c):
				return "Something lies on that ground."
			if _someone_on(c):
				return "Someone is standing there."
	if _heap_cells(origin).size() < int(cfg().heaps):
		return "There is no room beside it for the spoil."
	return ""


## The cells for the spoil heaps of a pit at `origin`: two cells out from the pit (outside its border), nearest the
## middle of its south side first, each on clear open ground with clear ground all round (a lone solid cell in open
## ground cuts no path), and apart from each other.
func _heap_cells(origin: Vector2i) -> Array:
	var s := size()
	var ring := Rect2i(origin - Vector2i(2, 2), Vector2i(s + 4, s + 4))
	var south := Vector2(origin.x + s / 2, origin.y + s + 1)
	var cands := []
	for y in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			if x != ring.position.x and x != ring.end.x - 1 and y != ring.position.y and y != ring.end.y - 1:
				continue
			cands.append([Vector2(x, y).distance_squared_to(south), y, x])
	cands.sort()
	var out := []
	for k in cands:
		var c := Vector2i(int(k[2]), int(k[1]))
		if out.any(func(o: Vector2i) -> bool: return maxi(absi(o.x - c.x), absi(o.y - c.y)) <= 1):
			continue
		if not _static_open(c) or w.plant_refusal(c) != "" or _something_on(c):
			continue
		var clear := true
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var nc := c + Vector2i(dx, dy)
				if not w.map.in_village(nc) or w.map.is_solid(nc):
					clear = false
		if not clear:
			continue
		out.append(c)
		if out.size() >= int(cfg().heaps):
			break
	return out


## Stake a pit at `origin` for `owner` (World.PLAYER or World.MANOR; `for_clue`: the find it is dug for). The ground
## inside enters the books (pit_ground_<item>, a finite pool). Returns the pit, or {} if the site is refused.
func open_pit(owner: String, origin: Vector2i, for_clue := "") -> Dictionary:
	if site_refusal(origin) != "":
		return {}
	var s := size()
	var p := {"id": next_id, "x": origin.x, "y": origin.y, "owner": owner, "for": for_clue, "day": w.day(), "dug": [], "heaps": []}
	next_id += 1
	for i in s * s:
		(p.dug as Array).append(0)
	for c: Vector2i in _heap_cells(origin):
		(p.heaps as Array).append({"x": c.x, "y": c.y, "inv": Inventory.new()})
	pits.append(p)
	var vol := volume(p)
	for id in vol:
		w.stat("pit_ground_" + str(id), float(vol[id]))
	w.stat("pits_opened")
	w.note(("You mark out an open pit %s." if World.is_player_ref(owner) else World.cap(w.ref_name(owner, true)) + " marks out an open pit %s.") % w.where(rect(p)))
	changed.emit()
	return p


# ---------------------------------------------------------------- what a pit holds -----------
## The whole ground a pit is dug through, by item.
static func volume(_p: Dictionary) -> Dictionary:
	var out := {}
	for i in size() * size():
		for u in cap(i):
			var id := item_of(u)
			out[id] = int(out.get(id, 0)) + 1
	return out


## The ground still in a pit, by item (the pool: volume - dug + backfilled).
static func left(p: Dictionary) -> Dictionary:
	var out := {}
	for i in size() * size():
		for u in range(int(p.dug[i]), cap(i)):
			var id := item_of(u)
			out[id] = int(out.get(id, 0)) + 1
	return out


## The ground left in every pit, by item (the economy ledger's pool).
func ground_left() -> Dictionary:
	var out := {}
	for p in pits:
		var l := left(p)
		for id in l:
			out[id] = int(out.get(id, 0)) + int(l[id])
	return out


## Goods lying on the spoil heaps, by item (the goods census counts them).
func goods() -> Dictionary:
	var out := {}
	for p in pits:
		for h in p.heaps:
			for id in (h.inv as Inventory).ids():
				out[id] = int(out.get(id, 0)) + (h.inv as Inventory).count(id)
	return out


func depth_at(p: Dictionary, i: int) -> int:
	return depth_of(int(p.dug[i]))


func walkable(p: Dictionary, i: int) -> bool:
	return is_ramp(i) or depth_at(p, i) == 0


func done(p: Dictionary) -> bool:
	for i in size() * size():
		if int(p.dug[i]) < cap(i):
			return false
	return true


## The kinds of digging tool `who` holds, of those the pit's layers need (["shovel", "pickaxe"], or fewer).
static func kinds_held(who) -> Array:
	var out := []
	for l in layers():
		var k := str(l.get("tool", "pickaxe"))
		if not out.has(k) and held_tool(who, k) != "":
			out.append(k)
	return out


## The ramp is dug to its depth on every ring: the pit's floor can be walked to (a "pit_ramp" structure, MIN-D).
func ramp_done(p: Dictionary) -> bool:
	for i in size() * size():
		if is_ramp(i) and int(p.dug[i]) < cap(i):
			return false
	return true


func ramps_done() -> int:
	return pits.filter(func(p): return ramp_done(p)).size()


# ---------------------------------------------------------------- digging --------------------
## Where someone stands to dig cell `i` of pit `p`: the open neighbour (of eight) nearest `from`, or (-1, -1).
func stand_for(p: Dictionary, i: int, from: Vector2i) -> Vector2i:
	return stand_beside(cell_of(p, i), from)


## The open neighbour (of eight) of cell `at` nearest `from` (a pit cell to dig, a heap to tip on), or (-1, -1).
func stand_beside(at: Vector2i, from: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bd := 1e9
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var c: Vector2i = at + Vector2i(dx, dy)
			if (dx == 0 and dy == 0) or not w.map.in_village(c) or w.map.is_solid(c):
				continue
			var d := Vector2(c).distance_squared_to(Vector2(from))
			if d < bd:
				bd = d
				best = c
	return best


## Why cell `c` of pit `p` cannot be dug one unit now, whoever digs ("" if it can). `mover`: a cell whose stander is
## the digger, who will step off it to dig (a villager planning from where it stands).
func dig_ground_refusal(p: Dictionary, c: Vector2i, mover := Vector2i(-1, -1)) -> String:
	var i := index(p, c)
	if i < 0:
		return "That is not part of the pit."
	if not _seam_on(c).is_empty():
		return "A seam is open there: mine it."
	if int(p.dug[i]) >= cap(i):
		return "The ramp is dug to its depth here." if is_ramp(i) else "This part of the pit is dug down to its floor."
	if c != mover and _someone_on(c):
		return "Someone is standing there."
	if _something_on(c):
		return "Something lies there."
	if stand_for(p, i, c).x < 0:
		return "Nobody can stand beside it to dig."
	if walkable(p, i) and not is_ramp(i) and depth_of(int(p.dug[i]) + 1) > 0 and not _connected_without(p, i):
		return "Digging there would cut off the rest of the pit."
	return ""


## The kind of tool cell `c` of pit `p` is dug with next ("shovel" or "pickaxe"; "" outside the pit or dug out).
func tool_needed(p: Dictionary, c: Vector2i) -> String:
	var i := index(p, c)
	return tool_of(int(p.dug[i])) if i >= 0 else ""


## Why `who` cannot dig cell `c` of pit `p` with `tool` ("" if they can): the tool must be of the kind the cell's next
## layer is dug with (a shovel for the earth, a pickaxe for the rock).
func dig_refusal(who, p: Dictionary, c: Vector2i, tool := "pickaxe") -> String:
	var need := tool_needed(p, c)
	if need != "" and (tool == "" or not who.inv.has(tool) or str(GameData.item(tool).get("tool", "")) != need):
		return "You need a %s to dig %s." % [tool_word(need), GameData.item_name(item_of(int(p.dug[index(p, c)]))).to_lower()]
	return dig_ground_refusal(p, c)


## Whether every walkable cell of the pit but `skip` is still reached from its border by four-way steps (DVW-A10).
func _connected_without(p: Dictionary, skip: int) -> bool:
	var block := rect(p).grow(1)
	var seen := {}
	var todo: Array = []
	for y in range(block.position.y, block.end.y):
		for x in range(block.position.x, block.end.x):
			var c := Vector2i(x, y)
			if not rect(p).has_point(c) and not w.map.is_solid(c):
				seen[c] = true
				todo.append(c)
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for dv in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nc: Vector2i = c + dv
			var ni := index(p, nc)
			if ni < 0 or ni == skip or seen.has(nc) or w.map.is_solid(nc):
				continue
			seen[nc] = true
			todo.append(nc)
	for i in size() * size():
		var c := cell_of(p, i)
		if i != skip and not w.map.is_solid(c) and not seen.has(c):
			return false
	return true


## `who` (the player or a villager) digs one unit from cell `c` of pit `p` with `tool`, by one rule (PAR-01): the unit
## of the cell's next layer goes to `into` (counted dug_<item>), the layer's tool (a shovel or a pickaxe) wears (`wear`; Mining's tool_wear_save may
## spare it) and the work earns `xp` Mining xp. A cell dug through a whole layer goes down a step; one dug down to the
## rock (not the ramp) opens a prospecting body within reach as a seam. Returns {result: "ok" | "refused", why, item,
## n, broke, up, exposed (the seam opened, or {})}.
func dig(who, p: Dictionary, c: Vector2i, into: Inventory, tool := "pickaxe") -> Dictionary:
	var why := dig_refusal(who, p, c, tool)
	if why != "":
		return {"result": "refused", "why": why}
	var i := index(p, c)
	var before := depth_at(p, i)
	var item := item_of(int(p.dug[i]))
	p.dug[i] = int(p.dug[i]) + 1
	w._work_goods(who, into, item, 1, "dug_")
	w.stat("pit_units_dug")
	var broke := w._work_wear(who, tool, int(cfg().wear), "mining", "tool_wear_save")
	if broke and who is PlayerState and who.tool == tool:
		who.tool = ""
	var up := Skills.gain(who, "mining", int(cfg().xp))
	var exposed := {}
	if depth_at(p, i) != before:
		_sync(p, i)
		if depth_at(p, i) == rock_depth() and not is_ramp(i):
			exposed = _expose(p, c, Contracts.ref_of(who))
		if done(p):
			w.note("The open pit %s is dug to its floor." % w.where(rect(p)))
	changed.emit()
	return {"result": "ok", "why": "", "item": item, "n": 1, "broke": broke, "up": up, "exposed": exposed}


## A cell dug down to the rock: the first body (the clues' generation order) within `expose_reach` cells that no pit
## or trial has opened is opened on this cell, an ordinary seam (Discovery.expose). Misleading stains hold no body.
func _expose(p: Dictionary, c: Vector2i, ref: String) -> Dictionary:
	if w.prospecting == null or w.discovery == null:
		return {}
	var reach := int(cfg().expose_reach)
	for cl in w.prospecting.clues:
		var body: Dictionary = cl.get("body", {})
		if body.is_empty() or not w.discovery.opened(str(cl.id)).is_empty():
			continue
		if maxi(absi(int(body.x) - c.x), absi(int(body.y) - c.y)) <= reach:
			var d := w.discovery.expose(cl, c, ref)
			d["pit"] = int(p.id)
			w.stat("pit_seams")
			return d
	return {}


## The cell of pit `p` to dig next from `from`: the shallowest diggable cell first (the pit goes down a bench at a
## time: all the topsoil, then the dirt...), then the outer rings, then the nearest. (-1, -1) if none can be dug now.
## `mover`: the planner's own cell (it steps off it to dig, so it may be the one chosen). `kinds`: when given, only
## cells whose next unit is dug with a tool of one of those kinds (what the digger holds).
func next_dig(p: Dictionary, from: Vector2i, mover := Vector2i(-1, -1), kinds := []) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bk := []
	for i in size() * size():
		var c := cell_of(p, i)
		if not kinds.is_empty() and not kinds.has(tool_of(int(p.dug[i]))):
			continue
		if dig_ground_refusal(p, c, mover) != "":
			continue
		var k := [depth_at(p, i), ring_of(i), Vector2(c).distance_squared_to(Vector2(from)), i]
		if bk.is_empty() or k < bk:
			bk = k
			best = c
	return best


## How long the player's dig of the next unit of cell `i` takes (seconds), timed as their mining swing is.
func player_secs(p: Dictionary, i: int, tool: String) -> float:
	return minutes_of(int(p.dug[i])) / float(GameData.b("game_minutes_per_second")) * 0.6 / float(GameData.item(tool).get("speed", 1.0)) \
			* Skills.value(w.player, "mining", "mine_time", 1.0)


# ---------------------------------------------------------------- backfill -------------------
## Why `who` cannot put a unit back into cell `c` of pit `p` from `from` ("" if they can): the last unit dug goes back
## first, so it must be that item.
func fill_refusal(p: Dictionary, c: Vector2i, from: Inventory) -> String:
	var i := index(p, c)
	if i < 0:
		return "That is not part of the pit."
	if int(p.dug[i]) <= 0:
		return "Nothing has been dug here."
	if not _seam_on(c).is_empty():
		return "A seam is open there."
	var item := item_of(int(p.dug[i]) - 1)
	if not from.has(item):
		return "You need %s to fill it back." % GameData.item_name(item).to_lower()
	return ""


## A unit of the cell's last dug layer goes back from `from` into cell `c` (counted backfilled_<item>): the pool of the
## ground rises by it. A cell filled back up a whole layer is walkable again at the surface. Returns {result, why, item}.
func backfill(p: Dictionary, c: Vector2i, from: Inventory, actor: PlayerState = null) -> Dictionary:
	if actor != null and actor != w.player:
		return w.as_actor(actor, backfill.bind(p, c, from))
	var why := fill_refusal(p, c, from)
	if why != "":
		return {"result": "refused", "why": why}
	var i := index(p, c)
	var item := item_of(int(p.dug[i]) - 1)
	from.remove(item)
	p.dug[i] = int(p.dug[i]) - 1
	w.stat("backfilled_" + item)
	_sync(p, i)
	changed.emit()
	return {"result": "ok", "why": "", "item": item}


# ---------------------------------------------------------------- spoil heaps ----------------
## What the pit's heaps can hold together: its earth (the earth layers of its whole ground), shared out.
func heap_cap(p: Dictionary) -> int:
	var vol := volume(p)
	var n := 0
	for id in earth_items():
		n += int(vol.get(id, 0))
	return ceili(float(n) / float(maxi(1, (p.heaps as Array).size())))


## Earth from `from` onto pit `p`'s spoil heaps (each up to heap_cap; `force` past it, for goods given back when a job
## ends). An empty heap's cell must be clear: it becomes solid while it holds anything. Returns {item: units moved}.
func tip(p: Dictionary, from: Inventory, force := false, actor: PlayerState = null) -> Dictionary:
	if actor != null and actor != w.player:
		return w.as_actor(actor, tip.bind(p, from, force))
	var moved := {}
	var hcap := heap_cap(p)
	for id in earth_items():
		for h in p.heaps:
			var hv: Inventory = h.inv
			var c := Vector2i(int(h.x), int(h.y))
			var n := from.count(id)
			if n <= 0:
				break
			if hv.total() == 0 and (_someone_on(c) or _something_on(c)):
				continue
			var room := n if force else mini(n, hcap - hv.total())
			if room <= 0:
				continue
			w.transfer(from, hv, id, room)
			moved[id] = int(moved.get(id, 0)) + room
			w.map.set_solid(c, true)
	if not moved.is_empty():
		changed.emit()
	return moved


## Earth on `from`'s heaps that `from` could take: true when some heap holds `id`.
func heap_count(p: Dictionary, id: String) -> int:
	var n := 0
	for h in p.heaps:
		n += (h.inv as Inventory).count(id)
	return n


## Up to `qty` of `id` from pit `p`'s heaps into `into` (as much as it takes). A heap emptied opens its cell again.
func take(p: Dictionary, id: String, qty: int, into: Inventory, actor: PlayerState = null) -> int:
	if actor != null and actor != w.player:
		return w.as_actor(actor, take.bind(p, id, qty, into))
	var got := 0
	for h in p.heaps:
		var hv: Inventory = h.inv
		while got < qty and hv.count(id) > 0 and into.can_add(id):
			if not w.transfer(hv, into, id, 1):
				break
			got += 1
		if hv.total() == 0:
			w.map.set_solid(Vector2i(int(h.x), int(h.y)), false)
	if got > 0:
		changed.emit()
	return got


# ---------------------------------------------------------------- collision ------------------
## A pit cell's collision from its depth (the seam's own rules hold a cell with a seam record).
func _sync(p: Dictionary, i: int) -> void:
	var c := cell_of(p, i)
	if not _seam_on(c).is_empty():
		return
	w.map.set_solid(c, not walkable(p, i))


func sync_all() -> void:
	for p in pits:
		for i in size() * size():
			_sync(p, i)
		for h in p.heaps:
			w.map.set_solid(Vector2i(int(h.x), int(h.y)), (h.inv as Inventory).total() > 0)


# ---------------------------------------------------------------- the manor ------------------
## The manor's pit it still wants dug: staked for a find not yet opened, with cells not yet down to the rock.
func manor_wants(p: Dictionary) -> bool:
	if p.is_empty() or str(p.owner) != World.MANOR:
		return false
	if str(p.get("for", "")) != "" and not w.discovery.opened(str(p.for)).is_empty():
		return false
	for i in size() * size():
		if not is_ramp(i) and depth_at(p, i) < rock_depth() and int(p.dug[i]) < cap(i):
			return true
	return false


func manor_pit() -> Dictionary:
	for p in pits:
		if manor_wants(p):
			return p
	return {}


## Where the manor would stake a pit for a find it knows: {clue, origin} for the most certain find (at least
## Discovery manor.min_confidence) not yet opened, with no pit dug for it before, that no trial pit can reach any more
## (its pits used up, or no clear cell left), at the clear site nearest the readings it knows; {} with none. The
## capability level is never a gate (owner, Q18-9).
func manor_target() -> Dictionary:
	var mc: Dictionary = Discovery.cfg().manor
	var dv: Discovery = w.discovery
	var finds := dv.manor_finds()
	finds.sort_custom(func(a, b): return float(a.confidence) > float(b.confidence) or (float(a.confidence) == float(b.confidence) and str(a.clue) < str(b.clue)))
	var done_for := {}
	for f in finds:
		if float(f.confidence) < float(mc.min_confidence) or done_for.has(str(f.clue)):
			continue
		done_for[str(f.clue)] = true
		var c: Dictionary = w.prospecting.clue(str(f.clue))
		if c.is_empty() or not dv.opened(str(c.id)).is_empty():
			continue
		if pits.any(func(p): return str(p.get("for", "")) == str(c.id)):
			continue
		if dv.trials_left(c) > 0 and dv.next_cell(c).x >= 0:
			continue                       # a trial pit first: it is the cheaper way to look
		var o := best_site(dv.aim(c, World.MANOR))
		if o.x > -1000:
			return {"clue": c, "origin": o}
	return {}


## The clear site whose middle is nearest `aim`, within `manor.site_search` cells of it; (-1000, -1000) with none.
func best_site(aim: Vector2) -> Vector2i:
	var s := size()
	var r := int(cfg().manor.site_search)
	var cands := []
	var mid := Vector2i(roundi(aim.x), roundi(aim.y))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var o := mid + Vector2i(dx, dy) - Vector2i(s / 2, s / 2)
			if site_open(o):
				cands.append([(Vector2(o) + Vector2(s / 2, s / 2)).distance_squared_to(aim), o.y, o.x])
	cands.sort()
	for k in cands:
		var o := Vector2i(int(k[2]), int(k[1]))
		if site_refusal(o) == "":
			return o
	return Vector2i(-1000, -1000)


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	var ps := []
	for p in pits:
		var d: Dictionary = p.duplicate(true)
		d.heaps = (p.heaps as Array).map(func(h): return {"x": int(h.x), "y": int(h.y), "inv": (h.inv as Inventory).to_dict()})
		ps.append(d)
	return {"gen": GEN_VERSION, "next_id": next_id, "pits": ps}


## A save without pits (Build 16, or Build 17 before MIN-E) loads with none. The cells' collision is set from the
## depths dug and the heaps held (a seam opened in a pit keeps its own).
func load_dict(d: Dictionary) -> void:
	pits.clear()
	next_id = int(d.get("next_id", 1))
	var n := size() * size()
	for pd in d.get("pits", []):
		var dug: Array = (pd.get("dug", []) as Array).map(func(v): return int(v))
		dug.resize(n)
		for i in n:
			dug[i] = clampi(int(dug[i]) if dug[i] != null else 0, 0, cap(i))
		var p := {"id": int(pd.id), "x": int(pd.x), "y": int(pd.y), "owner": str(pd.get("owner", World.MANOR)), "for": str(pd.get("for", "")),
				"day": int(pd.get("day", 0)), "dug": dug, "heaps": []}
		for h in pd.get("heaps", []):
			(p.heaps as Array).append({"x": int(h.x), "y": int(h.y), "inv": Inventory.from_dict(h.get("inv", {}))})
		pits.append(p)
	sync_all()
