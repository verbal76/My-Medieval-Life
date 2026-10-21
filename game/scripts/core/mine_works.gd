class_name MineWorks
extends RefCounted
## MIN-F: the works below the surface (Mining spec stage 4 and 5, phase F; docs/build17/MIN_F_UNDERGROUND.md): tunnels
## cut into the rock of a level, the timber supports a tunnel needs before it is extended, track laid on cells, and the
## minecart set down on it (a cart of kind "minecart", Carts). One rule for the player and a villager (PAR-01): every
## function takes `who` (PlayerState or NPC) and works from their own inventory, on the level they stand on.
##
## MIN-F2 (the owner's MIN-F-Q1..Q5 decisions, docs/directives/2026-10-21_build17_minf_q1_q5_decisions.md;
## docs/build17/MIN_F2_STRUCTURE.md):
##  - Q1 stability: every cell the works opened, and every shaft, is evaluated once a day at dawn from its own
##    surroundings (`stability`: the supports within reach by condition and distance, the backfill beside it, capped);
##    under the threshold it may collapse, by a hash of the world seed, the day and the cell (no global event). A
##    collapse fills the cell with rubble (the roof rock fallen in: spoil units, dug out again as spoil), blocks it, and
##    moves whoever stands there to the nearest floor. Supports and ladders lose condition every dawn and are repaired
##    with real goods; a support worn to nothing fails and is gone.
##  - Q2: a tunnel or shaft that opens a cell beside hidden ore (Underground.hidden, generated from the seed) exposes it
##    as an ordinary seam (Discovery.open_hidden): it was there before; nobody knew of it.
##  - Q3: a miner's minecart haul (cart_haul_plan, cart_fetch_plan, cart_act), chosen only when its walking cost is lower.
##  - Q4: shafts sunk from a level to the one below, a ladder set in them makes a portal of kind "shaft" (the level
##    router uses it; goods go in the climber's hands; a minecart never goes through one).
##  - Q5: backfill: spoil put back into a floor cell by the player's own hands or by a worker on the player's paid order
##    (ManorWork "backfill"); never otherwise. Full, the cell is solid; dug again, the fill comes back as spoil.
##
## Finite and conserved (OD-28, WDR-022): a rock cell holds the units of mine_works.json "cell"; each cut moves one unit
## into the cutter's inventory (cut_<item>; the books' `taken`), rubble comes out as spoil (`taken`), fill comes back as
## spoil (`fill_out`); spoil put back is filled_spoil. A support, track section or ladder is used up where it is placed.
##
## Saved under "mine_works" {gen, opened, cut, supports: [[level, x, y, condition]], track, cells: {"level,x,y": {fill,
## rubble}}, shafts: [{x, y, level, dug, landing, rubble, ladder, stand, door}], levels, taken, fill_out, last_dawn};
## absent keys are defaults (a support saved without a condition is whole). On load the deep levels are made, the opened
## cells are floor again, filled and collapsed cells solid, shafts' mouths open and their ladders portals, before anyone
## is put back.

signal changed(level: int, cell: Vector2i)   # a cell opened, filled or collapsed, a support, track, shaft or ladder changed

const GEN_VERSION := 2

static var _cfg := {}

var w: World
var opened: Array = []          # [level, x, y] of every cell cut through, in the order they opened
var _open_idx := {}             # "level,x,y" -> true for every opened cell
var cut := {}                   # "level,x,y" -> units cut from a rock cell not yet opened
var supports: Array = []        # [level, x, y, condition] of every timber support, in the order they were set up
var track := {}                 # Vector3i(level, x, y) -> true: a track section lies there
var cells := {}                 # "level,x,y" -> {fill, rubble}: spoil put back, rock fallen in (only cells holding any)
var shafts: Array = []          # {x, y, level (the top), dug, landing, rubble, ladder (condition, -1 none), stand, door}
var levels: Array = []          # the deep levels made by shafts (World.underground maps), shallowest first
var taken := {}                 # item -> units taken out of the ground (rock and rubble; the books)
var fill_out := 0               # spoil units of fill dug out again (the books)
var last_dawn := -1
var trapped := {}               # MIN-COLLAPSE: "player" or "npc:<id>" -> "level,x,y" of the cave-in they are trapped in
var supply: MineSupply          # MIN-EQUIP: who makes, buys and orders the equipment (not saved: it holds no state)


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/mine_works.json"))
	return _cfg


static func create(world: World) -> MineWorks:
	var m := MineWorks.new()
	m.w = world
	m.supply = MineSupply.new(world)
	return m


# ---------------------------------------------------------------- the rock -------------------
## Units a rock cell holds (5: 3 stone and 2 spoil).
static func cell_units() -> int:
	return _units(cfg().cell)


static func _units(column: Array) -> int:
	var n := 0
	for l in column:
		n += int(l.amount)
	return n


static func _column_item(column: Array, u: int) -> String:
	var k := u
	for l in column:
		if k < int(l.amount):
			return str(l.item)
		k -= int(l.amount)
	return ""


static func _column_minutes(column: Array, u: int) -> float:
	var k := u
	for l in column:
		if k < int(l.amount):
			return float(l.minutes)
		k -= int(l.amount)
	return float(column[column.size() - 1].minutes) if not column.is_empty() else 0.0


## The item of the `u`-th unit cut from a cell (0 first), "" past the last.
static func item_of(u: int) -> String:
	return _column_item(cfg().cell, u)


static func minutes_of(u: int) -> float:
	return _column_minutes(cfg().cell, u)


static func key(level: int, c: Vector2i) -> String:
	return "%d,%d,%d" % [level, c.x, c.y]


## The level an actor stands on: the player's, or a villager's depth.
func level_of(who) -> int:
	return w.player_level if who is PlayerState else int((who as NPC).depth)


static func _cell_of(who) -> Vector2i:
	return Vector2i(floori(who.pos.x), floori(who.pos.y))


## Units already cut from rock cell `c` of `level`.
func cut_at(level: int, c: Vector2i) -> int:
	return int(cut.get(key(level, c), 0))


func is_opened(level: int, c: Vector2i) -> bool:
	return _open_idx.has(key(level, c))


func fill_at(level: int, c: Vector2i) -> int:
	return int(cells.get(key(level, c), {}).get("fill", 0))


func rubble_at(level: int, c: Vector2i) -> int:
	return int(cells.get(key(level, c), {}).get("rubble", 0))


## Spoil a floor cell holds (fill and rubble): full at cell_units, then solid.
func held_at(level: int, c: Vector2i) -> int:
	return fill_at(level, c) + rubble_at(level, c)


func _set_held(level: int, c: Vector2i, fill: int, rubble: int) -> void:
	var k := key(level, c)
	if fill <= 0 and rubble <= 0:
		cells.erase(k)
	else:
		cells[k] = {"fill": maxi(0, fill), "rubble": maxi(0, rubble)}


func _map(level: int, c: Vector2i) -> LevelMap:
	return w.underground.map_at(level, c) if w.underground != null else null


## Why `c` on `level` is not rock a tunnel may be cut into ("" if it is), whoever cuts: the rock of a level's map (not
## its floor, not a seam's cell: seams are mined), under the hill's static rock with rock all round (Underground.
## under_rock) and inside the map's edge, beside an open face, and within reach of a timber support.
func rock_refusal(level: int, c: Vector2i) -> String:
	if level == 0 or w.underground == null:
		return "Tunnels are cut below ground; on the surface, dig an open pit."
	var lm := _map(level, c)
	if lm == null or not lm.is_solid(c):
		return "There is no rock to cut there."
	if held_at(level, c) > 0:
		return ""                                        # rubble or fill: dug out as spoil (clear_refusal)
	if not shaft_at(level, c).is_empty() or not shaft_at(level + 1, c).is_empty():
		return "That is a shaft."
	if not w.deposit_at(c, level).is_empty():
		return "That is a seam: mine it with your pickaxe."
	if not lm.region.grow(-1).has_point(c) or not w.underground.under_rock(w.map, c):
		return "The rock above is too thin there: the hill would give way."
	var face := false
	for d: Vector2i in VillageMap.SIDES:
		if not lm.is_solid(c + d):
			face = true
	if not face:
		return "Cut from an open face beside the tunnel."
	if not supported(level, c):
		return "Set up a timber support within %d cells first: unsupported rock is not cut." % int(cfg().support.reach)
	return ""


## Why the rubble or fill in `c` may not be dug out ("" if it may): a support within reach (the roof that fell, or the
## fill holding it, is only taken away under timber), from an open face.
func clear_refusal(level: int, c: Vector2i) -> String:
	if held_at(level, c) <= 0:
		return "There is nothing to dig out there."
	var lm := _map(level, c)
	var face := lm != null and not lm.is_solid(c)
	for d: Vector2i in VillageMap.SIDES:
		if lm != null and not lm.is_solid(c + d):
			face = true
	if not face:
		return "Dig from an open face beside it."
	if not supported(level, c):
		return "Set up a timber support within %d cells first: what holds the roof is not taken away unsupported." % int(cfg().support.reach)
	return ""


## The kind of tool cell `c` of `level` is worked with next (owner MIN-E-Q4, 2026-10-21: loose earth with a shovel, rock
## with a pickaxe): the rubble or fill a cell holds is loose spoil, shovelled out; rock is cut with `tool` (a pickaxe).
func tool_kind(level: int, c: Vector2i) -> String:
	return "shovel" if held_at(level, c) > 0 else str(cfg().tool)


## Why `who` cannot cut a unit from `c` with `tool` ("" if they can): a tool of the cell's kind (tool_kind: a pickaxe
## for rock, a shovel for rubble or fill), standing at the face on that level.
func dig_refusal(who, c: Vector2i, tool := "pickaxe") -> String:
	var level := level_of(who)
	var kind := tool_kind(level, c)
	if tool == "" or not who.inv.has(tool) or str(GameData.item(tool).get("tool", "")) != kind:
		return "You need a pickaxe to cut rock." if kind == str(cfg().tool) else "You need a shovel to dig out the loose spoil."
	var why := clear_refusal(level, c) if held_at(level, c) > 0 else rock_refusal(level, c)
	if why != "":
		return why
	var at := _cell_of(who)
	if at == c and is_trapped(who):
		return ""                                        # MIN-COLLAPSE: digging oneself out of the rubble
	if maxi(absi(at.x - c.x), absi(at.y - c.y)) > 1 or at == c or w.underground.is_solid(level, at):
		return "Stand at the face to cut it."
	return ""


## `who` cuts one unit from `c` of the level they stand on with `tool` (PAR-01: the same for everyone): from rock the
## cell's next unit (cut_<item>; `taken`); from a collapsed or filled cell its rubble first, then its fill, as spoil
## (cut_spoil; rubble is `taken`, fill `fill_out`: never stone or ore). The pickaxe wears, Mining xp. A rock cell's last
## unit opens it (floor, its A* at once) and exposes hidden ore beside it; a filled or collapsed cell is walkable again
## once it holds less than a full cell. Returns {result: "ok" | "refused", why, item, n, broke, up, opened, exposed}.
func dig(who, c: Vector2i, into: Inventory, tool := "pickaxe") -> Dictionary:
	var why := dig_refusal(who, c, tool)
	if why != "":
		return {"result": "refused", "why": why}
	var level := level_of(who)
	var k := key(level, c)
	var item := ""
	var done := false
	var exposed := []
	if held_at(level, c) > 0:
		item = "spoil"
		var fill := fill_at(level, c)
		var rubble := rubble_at(level, c)
		if rubble > 0:
			rubble -= 1
			taken[item] = int(taken.get(item, 0)) + 1
			w.stat("tunnel_rubble_cleared")
		else:
			fill -= 1
			fill_out += 1
			w.stat("tunnel_fill_dug")
		_set_held(level, c, fill, rubble)
		w._work_goods(who, into, item, 1, "cut_")
		if fill + rubble < cell_units() and _map(level, c).is_solid(c):
			_map(level, c).set_solid(c, false)
			_free_trapped(level, c)
			done = true
	else:
		var u := cut_at(level, c)
		item = item_of(u)
		w._work_goods(who, into, item, 1, "cut_")
		taken[item] = int(taken.get(item, 0)) + 1
		w.stat("tunnel_units_cut")
		u += 1
		done = u >= cell_units()
		if done:
			cut.erase(k)
			_open(level, c)
			w.stat("tunnel_cells_opened")
			exposed = expose_beside(level, c, Contracts.ref_of(who))
		else:
			cut[k] = u
	var broke := w._work_wear(who, tool, int(cfg().wear), "mining", "tool_wear_save")
	if broke and who is PlayerState and who.tool == tool:
		who.tool = ""
	var up := Skills.gain(who, "mining", int(cfg().xp))
	if done:
		changed.emit(level, c)
	return {"result": "ok", "why": "", "item": item, "n": 1, "broke": broke, "up": up, "opened": done, "exposed": exposed}


func _open(level: int, c: Vector2i) -> void:
	var k := key(level, c)
	if not _open_idx.has(k):
		opened.append([level, c.x, c.y])
		_open_idx[k] = true
	_map(level, c).set_solid(c, false)


## Q2: hidden ore in the four cells beside `c` (and `c` itself) is exposed as ordinary seams (Discovery.open_hidden).
## Returns the seams opened.
func expose_beside(level: int, c: Vector2i, ref: String) -> Array:
	var out := []
	if w.underground == null:
		return out
	for d in [Vector2i.ZERO] + VillageMap.SIDES:
		var h := w.underground.hidden_at(level, c + (d as Vector2i))
		if not h.is_empty():
			w.underground.hidden.erase(h)
			out.append(w.discovery.open_hidden(h, ref))
	return out


## Why `c` may not be cut now, whoever cuts ("" if it may): its rubble or fill (clear_refusal) or its rock (rock_refusal).
func cut_refusal(level: int, c: Vector2i) -> String:
	return clear_refusal(level, c) if held_at(level, c) > 0 else rock_refusal(level, c)


## The weakest support holding `c` is sound (at least stability.threshold of its condition): the manor's heading is
## cut only under sound timber.
func soundly_held(level: int, c: Vector2i) -> bool:
	var r := int(cfg().support.reach)
	var min_c := float(cfg().stability.threshold) * float(cfg().stability.full)
	for s in supports:
		if int(s[0]) == level and maxi(absi(int(s[1]) - c.x), absi(int(s[2]) - c.y)) <= r and float(s[3]) >= min_c:
			return true
	return false


## MIN-F2 (Q2): why the manor's tunnel job may not cut `c` ("" if it may): a cut that may be made, under sound timber,
## on a level villagers reach.
func face_refusal(level: int, c: Vector2i) -> String:
	if not w.villager_levels.has(level):
		return "No villager can reach that level."
	var why := cut_refusal(level, c)
	if why != "":
		return why
	return "" if soundly_held(level, c) else "The timber there is not sound."


## MIN-F2 (Q2): the face the manor's tunnel job cuts: on `level` (any level villagers reach when 0), the cell nearest
## `near` (the heading goes on) or else the first (maps in order, cells row by row) that face_refusal allows: chosen by
## the works alone, never by ore nobody knows of. {level, cell} or {}.
func manor_face(level := 0, near := Vector2i(-1, -1)) -> Dictionary:
	if w.underground == null:
		return {}
	var best := {}
	var bd := 1e9
	for m: LevelMap in w.underground.maps:
		if (level != 0 and m.level != level) or not w.villager_levels.has(m.level):
			continue
		for c in m.cells():
			if not m.is_solid(c) or face_refusal(m.level, c) != "":
				continue
			if near.x < 0:
				return {"level": m.level, "cell": c}
			var d := Vector2(c).distance_squared_to(Vector2(near))
			if d < bd:
				bd = d
				best = {"level": m.level, "cell": c}
	return best


## A villager's minutes for the next unit of `c` on `level`.
func npc_minutes_at(level: int, c: Vector2i, n: NPC) -> float:
	var mins := 25.0 if held_at(level, c) > 0 else minutes_of(cut_at(level, c))
	return mins * Skills.value(n, "mining", "mine_time", 1.0)


## The player's cut, timed as a mining swing (as OpenPits.player_secs).
func player_secs(c: Vector2i, tool: String) -> float:
	var lv := w.player_level
	var mins := 25.0 if held_at(lv, c) > 0 else minutes_of(cut_at(lv, c))
	return mins / float(GameData.b("game_minutes_per_second")) * 0.6 \
			/ float(GameData.item(tool).get("speed", 1.0)) * Skills.value(w.player, "mining", "mine_time", 1.0)


## A villager's minutes for the next unit of `c` (Mining mine_time).
func npc_minutes(n: NPC, c: Vector2i) -> float:
	var mins := 25.0 if held_at(n.depth, c) > 0 else minutes_of(cut_at(n.depth, c))
	return mins * Skills.value(n, "mining", "mine_time", 1.0)


# ---------------------------------------------------------------- supports -------------------
func _support_i(level: int, c: Vector2i) -> int:
	for i in supports.size():
		var s: Array = supports[i]
		if int(s[0]) == level and int(s[1]) == c.x and int(s[2]) == c.y:
			return i
	return -1


func support_at(level: int, c: Vector2i) -> bool:
	return _support_i(level, c) >= 0


## A support's condition (0..stability.full), -1 if none stands there.
func support_condition(level: int, c: Vector2i) -> int:
	var i := _support_i(level, c)
	return int(supports[i][3]) if i >= 0 else -1


## Whether a timber support stands within `support.reach` cells of `c` (the larger axis) on `level`.
func supported(level: int, c: Vector2i) -> bool:
	var r := int(cfg().support.reach)
	for s in supports:
		if int(s[0]) == level and maxi(absi(int(s[1]) - c.x), absi(int(s[2]) - c.y)) <= r:
			return true
	return false


## Why `who` cannot set up a timber support on floor cell `c` of their level ("" if they can): the support in their
## inventory (or `from`: MIN-EQUIP, a manor job's load holding the works yard's support and mallet), a mallet, floor
## below the surface, none there yet, within reach.
func support_refusal(who, c: Vector2i, from: Inventory = null) -> String:
	var sc: Dictionary = cfg().support
	var inv: Inventory = from if from != null else who.inv
	if not inv.has(str(sc.item)):
		return "You need a timber support (the carpenter's work: logs and planks at the sawhorse)."
	if not _has_tool_in(inv, str(sc.tool)):
		return "You need a mallet to set up a support."
	var level := level_of(who)
	if level == 0 or w.underground == null:
		return "Timber supports are set up below ground."
	if w.underground.is_solid(level, c):
		return "A support stands on the tunnel's floor."
	if support_at(level, c):
		return "A support stands there already."
	var at := _cell_of(who)
	if maxi(absi(at.x - c.x), absi(at.y - c.y)) > 1:
		return "That is out of reach."
	return ""


## `who` sets up a timber support on `c`: the support leaves their inventory (used_timber_support), the mallet wears,
## Crafting xp; it stands whole (stability.full). {result, why, broke, up}.
func place_support(who, c: Vector2i, from: Inventory = null) -> Dictionary:
	var why := support_refusal(who, c, from)
	if why != "":
		return {"result": "refused", "why": why}
	var sc: Dictionary = cfg().support
	var inv: Inventory = from if from != null else who.inv
	inv.remove(str(sc.item), 1)
	w.stat("used_" + str(sc.item))
	var level := level_of(who)
	supports.append([level, c.x, c.y, int(cfg().stability.full)])
	w.stat("supports_set_up")
	var broke := _wear(who, inv, str(sc.tool), int(sc.wear), str(sc.skill))
	var up := Skills.gain(who, str(sc.skill), int(sc.xp))
	changed.emit(level, c)
	return {"result": "ok", "why": "", "broke": broke, "up": up}


func support_count() -> int:
	return supports.size()


## Q1: why `who` cannot repair the worn support or ladder at `c` ("" if they can): something worn there (a support on
## their level at `c`, or a ladder in the shaft whose mouth is `c`), a mallet, the repair goods in their inventory,
## within reach.
func repair_refusal(who, c: Vector2i, from: Inventory = null) -> String:
	var level := level_of(who)
	var what := _repairable(level, c)
	if what == "":
		return "There is nothing worn there to repair."
	var rc: Dictionary = cfg()[what]
	var inv: Inventory = from if from != null else who.inv
	if not _has_tool_in(inv, str(rc.tool)):
		return "You need a mallet to repair it."
	if not inv.has_all(rc.repair):
		return "A repair needs %s." % _goods_words(rc.repair)
	var at := _cell_of(who)
	if maxi(absi(at.x - c.x), absi(at.y - c.y)) > 1:
		return "That is out of reach."
	return ""


func _repairable(level: int, c: Vector2i) -> String:
	var full := int(cfg().stability.full)
	var i := _support_i(level, c)
	if i >= 0 and int(supports[i][3]) < full:
		return "support"
	var sh := shaft_at(level, c)
	if not sh.is_empty() and int(sh.ladder) >= 0 and int(sh.ladder) < full:
		return "ladder"
	return ""


## Q1: `who` repairs the support or ladder at `c` with the repair goods (used_<item>), the mallet wears, Crafting xp: it
## is whole again. Backfill never does this. {result, why, what, broke, up}.
func repair(who, c: Vector2i, from: Inventory = null) -> Dictionary:
	var why := repair_refusal(who, c, from)
	if why != "":
		return {"result": "refused", "why": why}
	var level := level_of(who)
	var what := _repairable(level, c)
	var rc: Dictionary = cfg()[what]
	var inv: Inventory = from if from != null else who.inv
	for id in rc.repair:
		inv.remove(str(id), int(rc.repair[id]))
		w.stat("used_" + str(id), float(rc.repair[id]))
	var full := int(cfg().stability.full)
	if what == "support":
		supports[_support_i(level, c)][3] = full
	else:
		shaft_at(level, c).ladder = full
	w.stat(what + "s_repaired")
	var broke := _wear(who, inv, str(rc.tool), int(rc.wear), str(rc.skill))
	var up := Skills.gain(who, str(rc.skill), int(rc.xp))
	changed.emit(level, c)
	return {"result": "ok", "why": "", "what": what, "broke": broke, "up": up}


static func _goods_words(goods: Dictionary) -> String:
	var parts := []
	for id in goods:
		parts.append("%d %s" % [int(goods[id]), GameData.item_name(str(id)).to_lower()])
	return " and ".join(parts)


# ---------------------------------------------------------------- stability (Q1) -------------
## How well the roof over `c` is held (0..1): each support within reach adds its condition share times near_weight (at
## most a cell away) or far_weight; each four-neighbouring cell holding fill adds backfill_weight times its fill share,
## the backfill part capped at backfill_cap (so backfill alone never reaches the threshold, and it is never a support).
func stability(level: int, c: Vector2i) -> float:
	var st: Dictionary = cfg().stability
	var full := float(st.full)
	var r := int(cfg().support.reach)
	var s := 0.0
	for sp in supports:
		if int(sp[0]) != level:
			continue
		var d := maxi(absi(int(sp[1]) - c.x), absi(int(sp[2]) - c.y))
		if d <= r:
			s += float(sp[3]) / full * (float(st.near_weight) if d <= 1 else float(st.far_weight))
	var fp := 0.0
	for dv: Vector2i in VillageMap.SIDES:
		var f := fill_at(level, c + dv)
		if f > 0:
			fp += float(st.backfill_weight) * float(f) / float(cell_units())
	return minf(1.0, s + minf(fp, float(st.backfill_cap)))


## The day's chance (per mille) that open cell `c` collapses: (threshold - stability) x rate, 0 when held.
func collapse_chance(level: int, c: Vector2i) -> int:
	var st: Dictionary = cfg().stability
	var gap := float(st.threshold) - stability(level, c)
	return 0 if gap <= 0.0 else int(gap * float(st.rate) * 1000.0)


## The day's roll for a cell (0..999): a hash of the world seed, the day and the cell (deterministic, local).
func _roll(day: int, level: int, c: Vector2i) -> int:
	return Overworld.hash32(w.seed, 7001 + day, (level + 16) * 65536 + c.y * 256 + c.x, 77) % 1000


## Dawn (World._new_day): supports and ladders wear; then every open cell the works made, and every shaft, is weighed
## where it stands, and those that give way collapse (all weighed first, then fallen, so the order never matters).
func dawn() -> void:
	var day: int = w.day()
	if day == last_dawn:
		return
	last_dawn = day
	var st: Dictionary = cfg().stability
	var dec := int(st.decay_per_day)
	for s in supports.duplicate():
		s[3] = int(s[3]) - dec
		if int(s[3]) <= 0:
			supports.erase(s)
			w.stat("supports_failed")
			changed.emit(int(s[0]), Vector2i(int(s[1]), int(s[2])))
	for sh in shafts:
		if int(sh.ladder) >= 0:
			sh.ladder = int(sh.ladder) - dec
			if int(sh.ladder) <= 0:
				sh.ladder = -1
				_unlink(sh)
				w.stat("ladders_broken")
				w.note("A ladder in a shaft below ground has rotted through: it cannot be climbed until it is replaced.")
				changed.emit(int(sh.level), Vector2i(int(sh.x), int(sh.y)))
	var fall := []
	for o in opened:
		var lv := int(o[0])
		var c := Vector2i(int(o[1]), int(o[2]))
		var lm := _map(lv, c)
		if lm == null or lm.is_solid(c):
			continue                                     # filled, fallen in or a seam's: nothing open to fall
		var p := collapse_chance(lv, c)
		if p > 0 and _roll(day, lv, c) < p:
			fall.append([lv, c])
	var shaft_fall := []
	for sh in shafts:
		if int(sh.dug) <= 0 or int(sh.rubble) > 0:
			continue
		var c := Vector2i(int(sh.x), int(sh.y))
		var p := collapse_chance(int(sh.level), c)
		if p > 0 and _roll(day, int(sh.level) - 8, c) < p:
			shaft_fall.append(sh)
	for f in fall:
		collapse(int(f[0]), f[1])
	for sh in shaft_fall:
		_collapse_shaft(sh)
	_release_stale_claims(day)


## Cell `c` of `level` gives way: the roof rock falls in and fills it (rubble: spoil units, the cell's room less any fill
## it holds), it is solid, a support on it is crushed (track under it stays). MIN-COLLAPSE: each person on it survives or
## dies (`caught`); a cart or pile on it stays buried in the rubble until it is dug out. No goods are made or lost: the
## rubble is ground until it is dug out (counted then).
func collapse(level: int, c: Vector2i) -> void:
	var lm := _map(level, c)
	if lm == null or lm.is_solid(c):
		return
	var held := stability(level, c)                   # how well the roof was held as it fell (the survival rule's input)
	var rubble := cell_units() - fill_at(level, c)
	_set_held(level, c, fill_at(level, c), rubble)
	lm.set_solid(c, true)
	var i := _support_i(level, c)
	if i >= 0:
		supports.remove_at(i)
		w.stat("supports_crushed")
	w.stat("tunnel_collapses")
	w.stat("collapse_rubble", float(rubble))
	w.note("A tunnel below ground has caved in %s." % w.where(Rect2i(c.x, c.y, 1, 1)))
	caught(level, c, held)
	changed.emit(level, c)


## MIN-COLLAPSE (owner MIN-F2-Q2, Build 17: survive or die, no injury): every person on cell `c` of `level` as it fills
## (the player, villagers) survives when a hash of the world seed, the day, the cell and the person (0..999) is under
## collapse.survive_base + collapse.survive_per_held x `held` (how well the roof was held as it fell: a well-propped
## roof that gives way leaves more room to live) -- deterministic for a state and seed; the numbers are tunables for
## review, not policy. The dead die by the existing paths (World.kill for a villager: heir, household, notes, the
## brain's consequences; World.damage_player for the player: the heir takes over). A survivor scrambles into an open
## passage beside the cell (its four sides first, then the corners; the first open one in that order), if there is
## one; with none, they are trapped in the rubble (`trapped`) and stay there, unable to act, until someone digs the cell
## out (the trapped player may dig at it from inside). Nothing else moves them. Returns [[ref, survived], ...].
func caught(level: int, c: Vector2i, held: float) -> Array:
	var out := []
	var cc: Dictionary = cfg().collapse
	var lm := _map(level, c)
	var people := []
	if w.player.alive and w.player_level == level and _cell_of(w.player) == c:
		people.append(w.player)
	for n: NPC in w.npcs:
		if n.alive and n.depth == level and n.cell() == c:
			people.append(n)
	var survive := int(cc.survive_base) + int(float(cc.survive_per_held) * clampf(held, 0.0, 1.0))
	for who in people:
		var pk := -1 if who is PlayerState else int((who as NPC).id)
		var roll := Overworld.hash32(w.seed, 7301 + w.day(), (level + 16) * 65536 + c.y * 256 + c.x, pk + 2) % 1000
		var ref := World.PLAYER if who is PlayerState else World.npc_ref(int(who.id))
		if roll >= survive:
			w.stat("collapse_deaths")
			if who is PlayerState:
				w.damage_player(1.0e9, "crushed in a mine collapse")
			else:
				w.kill(who, "crushed in a mine collapse")
			out.append([ref, false])
			continue
		w.stat("collapse_survivors")
		var to := _escape(lm, c)
		if to.x >= 0:
			who.pos = Vector2(to) + Vector2(0.5, 0.5)
			w.stat("collapse_escaped")
		else:
			trapped[ref] = key(level, c)
			w.stat("collapse_trapped")
			w.note("Someone is trapped in the rubble below ground: the cave-in must be dug out to free them.")
		if who is NPC:
			(who as NPC).plan.clear()
		out.append([ref, true])
	return out


## The open passage a survivor steps into from `c`: its four sides, then its corners (a corner only when a side beside
## it is open, as anyone walks), the first open floor in that order; (-1, -1) if none.
static func _escape(lm: LevelMap, c: Vector2i) -> Vector2i:
	for d: Vector2i in VillageMap.SIDES:
		if not lm.is_solid(c + d):
			return c + d
	for d in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var n: Vector2i = c + d
		if not lm.is_solid(n) and (not lm.is_solid(Vector2i(n.x, c.y)) or not lm.is_solid(Vector2i(c.x, n.y))):
			return n
	return Vector2i(-1, -1)


## Whether `who` is trapped in a cave-in (MIN-COLLAPSE).
func is_trapped(who) -> bool:
	return trapped.has(World.PLAYER if who is PlayerState else World.npc_ref(int(who.id)))


## A cave-in cell dug open again frees whoever was trapped in it.
func _free_trapped(level: int, c: Vector2i) -> void:
	var k := key(level, c)
	for ref in trapped.keys():
		if str(trapped[ref]) == k:
			trapped.erase(ref)
			w.stat("collapse_freed")


# ---------------------------------------------------------------- shafts (Q4) ----------------
## The shaft whose mouth is `c` on `level` (its top level), or {}.
func shaft_at(level: int, c: Vector2i) -> Dictionary:
	for sh in shafts:
		if int(sh.level) == level and int(sh.x) == c.x and int(sh.y) == c.y:
			return sh
	return {}


static func shaft_units() -> int:
	return _units(cfg().shaft.units)


func _is_portal_cell(level: int, c: Vector2i) -> bool:
	for p in w.underground.portals:
		for e in p.ends:
			if int(e.level) == level and (e.stand == c or e.door == c):
				return true
	return false


## Why `who` cannot sink (or go on sinking) a shaft at floor cell `c` of their level ("" if they can): a pickaxe; not
## below shaft.deepest; the mouth a floor cell (or the shaft begun there) under the hill's rock, not a portal's cell,
## no support or track on it; supported; standing beside it; a new shaft may not cut its level in two; the landing below
## not a known seam and with a rock face beside it for the ladder.
func shaft_refusal(who, c: Vector2i, tool := "pickaxe") -> String:
	if tool == "" or not who.inv.has(tool) or str(GameData.item(tool).get("tool", "")) != str(cfg().tool):
		return "You need a pickaxe to sink a shaft."
	var level := level_of(who)
	if level == 0 or w.underground == null:
		return "Shafts are sunk from below ground; on the surface, dig an open pit."
	if level - 1 < int(cfg().shaft.deepest):
		return "The rock goes no deeper here."
	var lm := _map(level, c)
	if lm == null:
		return "There is no floor there."
	var sh := shaft_at(level, c)
	if sh.is_empty():
		if lm.is_solid(c) or held_at(level, c) > 0:
			return "A shaft is sunk from the floor."
		if not lm.region.grow(-1).has_point(c) or not w.underground.under_rock(w.map, c) or _is_portal_cell(level, c):
			return "No shaft can be sunk there."
		if support_at(level, c) or track_at(level, c):
			return "Clear the cell first (a support or track stands there)."
		if not _keeps_connected(lm, c):
			return "A shaft there would cut the passage in two."
		var below := _map(level - 1, c)
		if below != null:
			if not w.deposit_at(c, level - 1).is_empty():
				return "Below lies a seam: mine it from its own level."
			if _ladder_wall(below, c).x < 0 and below.is_solid(c) == false:
				return "There is no rock face below to set a ladder against."
	elif shaft_done(sh) and int(sh.rubble) <= 0:
		return "The shaft is sunk: set a ladder in it."
	if not supported(level, c):
		return "Set up a timber support within %d cells first: unsupported rock is not cut." % int(cfg().support.reach)
	var at := _cell_of(who)
	if maxi(absi(at.x - c.x), absi(at.y - c.y)) > 1 or at == c or lm.is_solid(at):
		return "Stand beside the shaft to dig it."
	return ""


## Whether every floor cell of `lm` still reached from its entrances is reached with `c` closed (DVW-A10 for a shaft's
## mouth). The entrances are the stands of the portals on its level.
func _keeps_connected(lm: LevelMap, c: Vector2i) -> bool:
	var starts: Array[Vector2i] = []
	for p in w.underground.portals:
		for e in p.ends:
			if int(e.level) == lm.level and not lm.is_solid(e.stand):
				starts.append(e.stand)
	if starts.is_empty():
		return true
	var before := {}
	for s in starts:
		before.merge(lm.reachable_from(s))
	lm.solid[lm._i(c)] = 1
	var after := {}
	for s in starts:
		if s != c:
			after.merge(lm.reachable_from(s))
	lm.solid[lm._i(c)] = 0
	return after.size() == before.size() - 1


## The rock face beside a landing a ladder stands against: the first of its four sides that is rock on that level.
static func _ladder_wall(below: LevelMap, c: Vector2i) -> Vector2i:
	for d: Vector2i in VillageMap.SIDES:
		if below.is_solid(c + d):
			return c + d
	return Vector2i(-1, -1)


func shaft_done(sh: Dictionary) -> bool:
	if int(sh.dug) < shaft_units():
		return false
	var below := _map(int(sh.level) - 1, Vector2i(int(sh.x), int(sh.y)))
	return below != null and not below.is_solid(Vector2i(int(sh.x), int(sh.y)))


## `who` digs one unit of the shaft at `c` (beginning it if none): its rubble first (spoil), then the shaft's column
## (shaft.units: cut_<item>), then, through to the level below (made if it is the first shaft to reach it), the landing's
## rock as an ordinary cell; the landing opens as floor and hidden ore beside it is exposed. The mouth is not walkable
## from the first unit. The pickaxe wears, Mining xp. {result, why, item, broke, up, done, exposed}.
func dig_shaft(who, c: Vector2i, into: Inventory, tool := "pickaxe") -> Dictionary:
	var why := shaft_refusal(who, c, tool)
	if why != "":
		return {"result": "refused", "why": why}
	var level := level_of(who)
	var lm := _map(level, c)
	var sh := shaft_at(level, c)
	if sh.is_empty():
		sh = {"x": c.x, "y": c.y, "level": level, "dug": 0, "landing": 0, "rubble": 0, "ladder": -1, "stand": [-1, -1], "door": [-1, -1]}
		shafts.append(sh)
		lm.set_solid(c, true)                           # an open hole: nobody walks over it
		w.stat("shafts_begun")
	var item := "spoil"
	var exposed := []
	var done := false
	if int(sh.rubble) > 0:
		sh.rubble = int(sh.rubble) - 1
		taken[item] = int(taken.get(item, 0)) + 1
	elif int(sh.dug) < shaft_units():
		item = _column_item(cfg().shaft.units, int(sh.dug))
		sh.dug = int(sh.dug) + 1
		taken[item] = int(taken.get(item, 0)) + 1
		if int(sh.dug) >= shaft_units():
			var below := _map(level - 1, c)
			if below == null:
				below = w.underground.add_level(level - 1, lm)
				levels.append(level - 1)
				w.stat("levels_opened")
			done = not below.is_solid(c)
	else:
		var below := _map(level - 1, c)
		item = item_of(int(sh.landing))
		sh.landing = int(sh.landing) + 1
		taken[item] = int(taken.get(item, 0)) + 1
		if int(sh.landing) >= cell_units():
			below.set_solid(c, false)
			done = true
	w._work_goods(who, into, item, 1, "cut_")
	w.stat("shaft_units_dug")
	if done:
		exposed = expose_beside(level - 1, c, Contracts.ref_of(who))
		w.stat("shafts_sunk")
		if int(sh.ladder) > 0:
			_link(sh)
	var broke := w._work_wear(who, tool, int(cfg().wear), "mining", "tool_wear_save")
	if broke and who is PlayerState and who.tool == tool:
		who.tool = ""
	var up := Skills.gain(who, "mining", int(cfg().xp))
	changed.emit(level, c)
	return {"result": "ok", "why": "", "item": item, "n": 1, "broke": broke, "up": up, "done": done, "exposed": exposed}


func shaft_secs(c: Vector2i, tool: String) -> float:
	var sh := shaft_at(w.player_level, c)
	var mins := 35.0 if sh.is_empty() else _column_minutes(cfg().shaft.units, int(sh.dug))
	return mins / float(GameData.b("game_minutes_per_second")) * 0.6 / float(GameData.item(tool).get("speed", 1.0)) \
			* Skills.value(w.player, "mining", "mine_time", 1.0)


## Why `who` cannot set a ladder into the shaft at `c` ("" if they can): a finished, clear shaft with no ladder, a ladder
## and a mallet, standing beside its mouth on its top level.
func ladder_refusal(who, c: Vector2i, from: Inventory = null) -> String:
	var inv: Inventory = from if from != null else who.inv
	var level := level_of(who)
	var sh := shaft_at(level, c)
	var lc: Dictionary = cfg().ladder
	if sh.is_empty():
		return "There is no shaft there."
	if not shaft_done(sh) or int(sh.rubble) > 0:
		return "The shaft is not through to the level below yet."
	if int(sh.ladder) >= 0:
		return "A ladder stands in the shaft already."
	if _ladder_wall(_map(level - 1, c), c).x < 0:
		return "There is no rock face below to set a ladder against."
	if not inv.has(str(lc.item)):
		return "You need a ladder (made at the workbench from planks and nails)."
	if not _has_tool_in(inv, str(lc.tool)):
		return "You need a mallet to set the ladder."
	var at := _cell_of(who)
	if maxi(absi(at.x - c.x), absi(at.y - c.y)) > 1 or at == c:
		return "Stand beside the shaft."
	return ""


## `who` sets a ladder into the shaft at `c`: the ladder leaves their inventory (used_ladder); the shaft becomes a portal
## (kind "shaft") between its mouth's stand on the top level and its landing below, which the level router uses.
func install_ladder(who, c: Vector2i, from: Inventory = null) -> Dictionary:
	var why := ladder_refusal(who, c, from)
	if why != "":
		return {"result": "refused", "why": why}
	var level := level_of(who)
	var sh := shaft_at(level, c)
	var lc: Dictionary = cfg().ladder
	var inv: Inventory = from if from != null else who.inv
	inv.remove(str(lc.item), 1)
	w.stat("used_" + str(lc.item))
	sh.ladder = int(cfg().stability.full)
	var at := _cell_of(who)
	var lm := _map(level, c)
	var stand := at if absi(at.x - c.x) + absi(at.y - c.y) == 1 else Vector2i(-1, -1)
	if stand.x < 0:
		for d: Vector2i in VillageMap.SIDES:
			if not lm.is_solid(c + d):
				stand = c + d
				break
	sh.stand = [stand.x, stand.y]
	var wall := _ladder_wall(_map(level - 1, c), c)
	sh.door = [wall.x, wall.y]
	_link(sh)
	w.stat("ladders_set")
	var broke := _wear(who, inv, str(lc.tool), int(lc.wear), str(lc.skill))
	var up := Skills.gain(who, str(lc.skill), int(lc.xp))
	changed.emit(level, c)
	return {"result": "ok", "why": "", "broke": broke, "up": up}


static func shaft_id(sh: Dictionary) -> String:
	return "shaft_%d_%d_%d" % [-int(sh.level), int(sh.x), int(sh.y)]


## The shaft's portal: the stand beside its mouth on the top level (door: the mouth), the landing below (door: the rock
## face the ladder stands against). Villagers' reachable levels follow.
func _link(sh: Dictionary) -> void:
	_unlink(sh)
	var c := Vector2i(int(sh.x), int(sh.y))
	var stand := Vector2i(int(sh.stand[0]), int(sh.stand[1]))
	var door := Vector2i(int(sh.door[0]), int(sh.door[1]))
	if stand.x < 0 or door.x < 0:
		return
	w.underground.add_portal({"id": shaft_id(sh), "kind": "shaft", "ends": [
		{"level": int(sh.level), "stand": stand, "door": c},
		{"level": int(sh.level) - 1, "stand": c, "door": door}]})
	w.villager_levels = w.underground.reachable_levels()


func _unlink(sh: Dictionary) -> void:
	if w.underground != null:
		w.underground.remove_portal(shaft_id(sh))
		w.villager_levels = w.underground.reachable_levels()


## The shaft gives way: rubble fills what was dug (spoil, dug out again first), the ladder is crushed, the portal goes.
func _collapse_shaft(sh: Dictionary) -> void:
	sh.rubble = int(sh.dug)
	if int(sh.ladder) >= 0:
		sh.ladder = -1
		w.stat("ladders_crushed")
	_unlink(sh)
	w.stat("shaft_collapses")
	w.stat("collapse_rubble", float(sh.rubble))
	var c := Vector2i(int(sh.x), int(sh.y))
	var below := _map(int(sh.level) - 1, c)
	if below != null and not below.is_solid(c):
		var held := stability(int(sh.level), c)
		below.set_solid(c, true)
		caught(int(sh.level) - 1, c, held)          # whoever stands at the ladder's foot
		sh.landing = 0
		sh.dug = maxi(0, int(sh.dug) - 1)            # the landing's roof is part of the fall: it is cut again
		sh.rubble = int(sh.rubble) + 1
	w.note("A shaft below ground has caved in.")
	changed.emit(int(sh.level), c)


# ---------------------------------------------------------------- backfill (Q5) --------------
## Why `who` cannot put a unit of spoil from `from` into floor cell `c` of their level ("" if they can): below ground, a
## floor cell under the hill's rock with room (not a portal's cell, a shaft or a collapsed cell), spoil to put, standing
## beside it (not on it); the unit that fills it needs nobody, no cart and no pile on it.
func fill_refusal(who, c: Vector2i, from: Inventory) -> String:
	var level := level_of(who)
	var why := fill_ground_refusal(level, c)
	if why != "":
		return why
	var item := str(cfg().backfill.item)
	if not from.has(item):
		return "You have no spoil to put back."
	var at := _cell_of(who)
	if maxi(absi(at.x - c.x), absi(at.y - c.y)) > 1 or at == c:
		return "Stand beside the passage to fill it."
	if fill_at(level, c) + 1 >= cell_units() and _occupied(level, c):
		return "Someone or something is in the way."
	return ""


## Whether floor cell `c` of `level` may take backfill at all ("" if it may): below ground, open floor under the hill's
## rock with room, not a portal's cell, a shaft's landing or a collapsed cell.
func fill_ground_refusal(level: int, c: Vector2i) -> String:
	if level == 0 or w.underground == null:
		return "Tunnels are backfilled below ground."
	var lm := _map(level, c)
	if lm == null or lm.is_solid(c) or rubble_at(level, c) > 0:
		return "There is no open passage there to fill."
	if _is_portal_cell(level, c) or not shaft_at(level + 1, c).is_empty():
		return "That way in and out is never filled."
	if not w.underground.under_rock(w.map, c):
		return "No passage to fill there."
	return ""


## Where a worker stands to fill `c`: the floor beside it nearest `from` (NPCBrain.beside, on its level).
func fill_stand(level: int, c: Vector2i, from: Vector2i) -> Vector2i:
	return w.brain.beside(c, from, level)


func _occupied(level: int, c: Vector2i) -> bool:
	if w.player_level == level and _cell_of(w.player) == c:
		return true
	for n: NPC in w.npcs:
		if n.alive and n.depth == level and n.cell() == c:
			return true
	for cart in w.carts.carts:
		if World.level_of(cart) == level and Vector2i((cart.pos as Vector2).floor()) == c:
			return true
	for l in w.loot:
		if World.level_of(l) == level and Vector2i((l.pos as Vector2).floor()) == c:
			return true
	return false


## `who` puts one unit of spoil from `from` into `c` (filled_spoil; the cell's fill): the passage fills a unit at a time
## and, full, is solid (its A* at once). Only the player's own hands or a worker on the player's order call this.
func fill(who, c: Vector2i, from: Inventory) -> Dictionary:
	var why := fill_refusal(who, c, from)
	if why != "":
		return {"result": "refused", "why": why}
	var level := level_of(who)
	var item := str(cfg().backfill.item)
	from.remove(item, 1)
	w.stat("filled_" + item)
	_set_held(level, c, fill_at(level, c) + 1, 0)
	var full := fill_at(level, c) >= cell_units()
	if full:
		_map(level, c).set_solid(c, true)
		w.stat("tunnel_cells_backfilled")
	changed.emit(level, c)
	return {"result": "ok", "why": "", "full": full, "fill": fill_at(level, c)}


func fill_secs() -> float:
	return float(cfg().backfill.minutes) / float(GameData.b("game_minutes_per_second")) * 0.6


## Spoil units lying in the ground as fill (the books: start + filled_spoil - fill_out = now).
func fill_in() -> int:
	var n := 0
	for k in cells:
		n += int(cells[k].get("fill", 0))
	return n


# ---------------------------------------------------------------- track ----------------------
func track_at(level: int, c: Vector2i) -> bool:
	return track.has(Vector3i(level, c.x, c.y))


## Whether track may lie on `c` of `level` (ground rule only): a level's floor; on the surface walkable open ground
## outdoors within `track.surface_reach` cells of a portal's surface stand (the mine's yard).
func track_ground_refusal(level: int, c: Vector2i) -> String:
	if level != 0:
		if w.underground == null or w.underground.is_solid(level, c):
			return "Track is laid on the tunnel's floor."
		return ""
	if not w.map.in_village(c) or w.map.is_solid(c) or w.place_of(Vector2(c) + Vector2(0.5, 0.5)) != "":
		return "Track is laid on open ground."
	var r := int(cfg().track.surface_reach)
	if w.underground != null:
		for p in w.underground.portals:
			for e in p.ends:
				if int(e.level) == 0 and maxi(absi(e.stand.x - c.x), absi(e.stand.y - c.y)) <= r:
					return ""
	return "Track is laid below ground and in the mine's yard, within %d cells of its mouth." % r


## Why `who` cannot lay a track section on `c` ("" if they can): the section in their inventory, a mallet, ground track
## may lie on, none there yet, within reach.
func track_refusal(who, c: Vector2i) -> String:
	var tc: Dictionary = cfg().track
	if not who.inv.has(str(tc.item)):
		return "You need a track section (made at the workbench from planks and nails)."
	if not _has_tool(who, str(tc.tool)):
		return "You need a mallet to lay track."
	var level := level_of(who)
	if track_at(level, c):
		return "Track is laid there already."
	var why := track_ground_refusal(level, c)
	if why != "":
		return why
	var at := _cell_of(who)
	if maxi(absi(at.x - c.x), absi(at.y - c.y)) > 1:
		return "That is out of reach."
	return ""


## `who` lays a track section on `c`: the section leaves their inventory (used_track_section), the mallet wears,
## Crafting xp. {result, why, broke, up}.
func lay_track(who, c: Vector2i) -> Dictionary:
	var why := track_refusal(who, c)
	if why != "":
		return {"result": "refused", "why": why}
	var tc: Dictionary = cfg().track
	who.inv.remove(str(tc.item), 1)
	w.stat("used_" + str(tc.item))
	var level := level_of(who)
	track[Vector3i(level, c.x, c.y)] = true
	w.stat("track_laid")
	var broke := w._work_wear(who, str(tc.tool), int(tc.wear), str(tc.skill), "")
	var up := Skills.gain(who, str(tc.skill), int(tc.xp))
	changed.emit(level, c)
	return {"result": "ok", "why": "", "broke": broke, "up": up}


## Track cells of a level, sorted (the views draw them).
func track_cells(level: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k: Vector3i in track:
		if k.x == level:
			out.append(Vector2i(k.y, k.z))
	out.sort()
	return out


func support_cells(level: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for s in supports:
		if int(s[0]) == level:
			out.append(Vector2i(int(s[1]), int(s[2])))
	return out


## The track route from `a` to `b` on `level` over four-way track cells (both on track), breadth first in a fixed side
## order; [] when the rails do not join them.
func track_route(level: int, a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not track_at(level, a) or not track_at(level, b):
		return out
	var prev := {a: a}
	var q: Array[Vector2i] = [a]
	var qi := 0
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		if c == b:
			break
		for d: Vector2i in VillageMap.SIDES:
			var n := c + d
			if not prev.has(n) and track_at(level, n) and (level == 0 or not w.underground.is_solid(level, n)):
				prev[n] = c
				q.append(n)
	if not prev.has(b):
		return out
	var c := b
	while c != a:
		out.push_front(c)
		c = prev[c]
	out.push_front(a)
	return out


# ---------------------------------------------------------------- the minecart ---------------
## Why `who` cannot set a minecart down on `c` ("" if they can): one in their inventory, track there on their level.
func minecart_refusal(who, c: Vector2i) -> String:
	if not who.inv.has(str(cfg().minecart.item)):
		return "You have no minecart."
	if not track_at(level_of(who), c):
		return "A minecart is set down on its rails: lay track first."
	return ""


## `who` sets a minecart down on track cell `c`: the item becomes a cart of kind minecart (Carts.place: used_minecart)
## owned by `owner` ("player" or "hh:<n>"), on their level. {result, why, cart}.
func set_down_minecart(who, owner: String, c: Vector2i) -> Dictionary:
	var why := minecart_refusal(who, c)
	if why != "":
		return {"result": "refused", "why": why}
	who.inv.remove(str(cfg().minecart.item), 1)
	var cart: Dictionary = w.carts.place(owner, Vector2(c) + Vector2(0.5, 0.5), "minecart", level_of(who))
	return {"result": "ok", "why": "", "cart": cart}


## Whether a minecart pulled through a portal can go: track on the stand it leaves and on the stand it reaches; never a
## shaft (a minecart does not climb a ladder: Q4).
func crossing_ok(leg_from: Dictionary, leg_to: Dictionary, portal := {}) -> bool:
	if str(portal.get("kind", "")) == "shaft":
		return false
	if int(leg_from.level) != 0 and int(leg_to.level) != 0 and int(leg_from.level) != int(leg_to.level):
		return false                                     # two levels below ground meet only by a shaft
	return track_at(int(leg_from.level), leg_from.stand) and track_at(int(leg_to.level), leg_to.stand)


func _has_tool_in(inv: Inventory, kind: String) -> bool:
	for id in inv.ids():
		if str(GameData.item(id).get("tool", "")) == kind:
			return true
	return false


## Wear the first tool of `kind` in `inv` (the worker's pack, or a job's load holding the works yard's tool) by
## `amount`, as World._work_wear does for a pack; a break is counted. True if it broke.
func _wear(who, inv: Inventory, kind: String, amount: int, skill: String) -> bool:
	if inv == who.inv:
		var own := ""
		for id in inv.ids():
			if str(GameData.item(id).get("tool", "")) == kind:
				own = id
				break
		return w._work_wear(who, own, amount, skill, "") if own != "" else false
	for id in inv.ids():
		if str(GameData.item(id).get("tool", "")) == kind:
			if inv.wear(id, amount):
				w.stat("broke_" + id)
				return true
			return false
	return false


func _has_tool(who, kind: String) -> bool:
	for id in who.inv.ids():
		if str(GameData.item(id).get("tool", "")) == kind:
			return true
	return false


# ---------------------------------------------------------------- minecart hauling (Q3) -------
## The path length (cells) a villager walks from `a` to `b` on `level`, 1e6 if there is no way.
func _walk_len(level: int, a: Vector2i, b: Vector2i) -> float:
	if a == b:
		return 0.0
	var p := w.underground.find_path(level, a, b) if level != 0 else w.map.find_path(a, b)
	if p.is_empty() or Vector2i(p[p.size() - 1]) != b:
		return 1e6
	var n := 0.0
	for i in range(1, p.size()):
		n += Vector2(p[i]).distance_to(Vector2(p[i - 1]))
	return n


## A minecart a miner `n` may use on their level: a minecart of their household (Carts.may_use) parked on track, not
## pulled, claimed by nobody else, with room; the nearest by walking, within `near` cells. {} if none.
func _usable_cart(n: NPC, near: float, need_room := 1) -> Dictionary:
	var ref := World.npc_ref(n.id)
	var best := {}
	var bd := near
	for c in w.carts.carts:
		if Carts.kind_of(c) != "minecart" or World.level_of(c) != n.depth or str(c.puller) != "":
			continue
		if str(c.get("claim", "")) not in ["", ref] or not w.carts.may_use(c, ref) or w.carts.room(c) < need_room:
			continue
		var cell := Vector2i((c.pos as Vector2).floor())
		if not track_at(n.depth, cell):
			continue
		var d := _walk_len(n.depth, n.cell(), cell)
		if d < bd:
			bd = d
			best = c
	return best


## The track cell joined by rail to `from` that is nearest (by walking) to the level's way out, and that walking distance.
func _unload_point(level: int, from: Vector2i) -> Array:
	var leg := w.underground.next_leg(level, 0)
	if leg.is_empty():
		return [Vector2i(-1, -1), 1e6]
	var exit: Vector2i = leg.from.stand
	var best := Vector2i(-1, -1)
	var bd := 1e6
	for c in track_cells(level):
		if track_route(level, from, c).is_empty():
			continue
		var d := _walk_len(level, c, exit)
		if d < bd:
			bd = d
			best = c
	return [best, bd]


## Q3, the costs a miner standing at the face weighs for a load of `load` units, in cells walked per unit (MIN_F2):
## carrying it out and coming back (2 x the walk to the way out, per carry_ore load) against the cart's (walking to it
## and back for each load, plus, per `trip` units, pulling it along the rails at track_speed, walking it back, and the
## walk out from the rails' end and back). {cart, unload, route, carry, cart_cost} or {} with no usable cart or route.
func haul_costs(n: NPC) -> Dictionary:
	if n.depth == 0 or w.underground == null:
		return {}
	var mc: Dictionary = cfg().minecart
	var cart := _usable_cart(n, float(mc.near_seam))
	if cart.is_empty():
		return {}
	var cc := Vector2i((cart.pos as Vector2).floor())
	var up := _unload_point(n.depth, cc)
	var unload: Vector2i = up[0]
	if unload.x < 0 or unload == cc:
		return {}
	var route := track_route(n.depth, cc, unload)
	var leg := w.underground.next_leg(n.depth, 0)
	var out_walk := _walk_len(n.depth, n.cell(), leg.from.stand)
	var carry := 2.0 * out_walk / float(GameData.b("carry_ore"))
	var access := _walk_len(n.depth, n.cell(), cc)
	var trip := float(route.size() - 1) * (1.0 / float(mc.track_speed) + 1.0) + 2.0 * float(up[1])
	var cart_cost := 2.0 * access / float(GameData.b("carry_ore")) + trip / float(mc.trip)
	return {"cart": cart, "unload": unload, "route": route, "carry": carry, "cart_cost": cart_cost}


## Q3: a miner at the face with a full load: if a usable minecart is near and its way is cheaper (haul_costs), the plan
## to put the load in it (claiming it), and, once it holds `trip` units or the seam is out, to pull it along the rails to
## their end nearest the way out and take the load from it there. [] to carry as before.
func cart_haul_plan(n: NPC, seam_left: bool) -> Array:
	var hc := haul_costs(n)
	if hc.is_empty() or float(hc.cart_cost) >= float(hc.carry):
		if not hc.is_empty():
			w.stat("minecart_declined")
		return []
	var b: NPCBrain = w.brain
	var cart: Dictionary = hc.cart
	var cc := Vector2i((cart.pos as Vector2).floor())
	var plan := [b.go(cc, 1.0, n.depth), b.doit("mc_load", {"cart": int(cart.id)})]
	var load := 0
	for o in ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]:
		load += n.inv.count(o)
	if (cart.store as Inventory).total() + load >= int(cfg().minecart.trip) or not seam_left:
		plan.append(b.doit("mc_hitch", {"cart": int(cart.id)}))
		for i in range(1, (hc.route as Array).size()):
			plan.append(b.go(hc.route[i], 1.0, n.depth))
		plan.append(b.doit("mc_unload", {"cart": int(cart.id)}))
		n.doing = "hauling ore by minecart"
	else:
		n.doing = "loading ore into a minecart"
	return plan


## Q3: before mining seam `d` below ground, a usable minecart left at the rails' far end is pulled back along them to
## the track cell nearest the seam (on the miner's way: only when the miner stands near the cart, never a detour).
func cart_fetch_plan(n: NPC, d: Dictionary) -> Array:
	if n.depth == 0 or World.level_of(d) != n.depth or w.underground == null:
		return []
	var mc: Dictionary = cfg().minecart
	var cart := _usable_cart(n, float(mc.near_seam), int(mc.trip))
	if cart.is_empty():
		return []
	var cc := Vector2i((cart.pos as Vector2).floor())
	var at := Vector2i(int(d.x), int(d.y))
	var best := Vector2i(-1, -1)
	var bd := float(mc.near_seam)
	for c in track_cells(n.depth):
		var dd := Vector2(c).distance_to(Vector2(at))
		if dd <= bd and not track_route(n.depth, cc, c).is_empty():
			bd = dd
			best = c
	if best.x < 0 or Vector2(cc).distance_to(Vector2(at)) <= float(mc.near_seam):
		return []
	var b: NPCBrain = w.brain
	var plan := [b.go(cc, 1.0, n.depth), b.doit("mc_hitch", {"cart": int(cart.id)})]
	var route := track_route(n.depth, cc, best)
	for i in range(1, route.size()):
		plan.append(b.go(route[i], 1.0, n.depth))
	plan.append(b.doit("mc_park", {"cart": int(cart.id)}))
	return plan


## The minecart steps of a miner's plan (NPCBrain.act): load the ore carried into the cart (as much as it has room for),
## take hold of it, let it go, or take its load and let it go (the claim is let go too). False ends the plan.
func cart_act(n: NPC, what: String, a: Dictionary) -> bool:
	if what == "mc_place":                          # MIN-EQUIP: the household's new minecart set on the rails
		var cell := Vector2i(int(a.get("x", -1)), int(a.get("y", -1)))
		var r := set_down_minecart(n, World.hh_ref(n.household), cell)
		if r.result == "ok":
			w.stat("minecarts_set_down_by_miners")
		return r.result == "ok"
	var cart: Dictionary = w.carts.by_id(int(a.get("cart", -1)))
	var ref := World.npc_ref(n.id)
	if cart.is_empty() or str(cart.get("claim", "")) not in ["", ref] or not w.carts.may_use(cart, ref):
		return false
	var store: Inventory = cart.store
	match what:
		"mc_load":
			if (cart.pos as Vector2).distance_to(n.pos) > 1.6:
				return false
			cart.claim = ref
			cart.claim_day = w.day()
			for o in ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]:
				var q := mini(n.inv.count(o), w.carts.room(cart))
				if q > 0 and store.can_add(o):
					w.transfer(n.inv, store, o, q)
					w.stat("minecart_loaded", float(q))
			return true
		"mc_hitch":
			cart.claim = ref
			cart.claim_day = w.day()
			return w.carts.hitch(cart, ref) == ""
		"mc_park":
			w.carts.park(cart)
			cart.erase("claim")
			cart.erase("claim_day")
			return true
		"mc_unload":
			w.carts.park(cart)
			for id in store.ids():
				w.transfer(store, n.inv, id, store.count(id))
			cart.erase("claim")
			cart.erase("claim_day")
			w.stat("minecart_hauls")
			return true
	return false


## A claim left from a day before (its miner was called away) is let go at dawn.
func _release_stale_claims(day: int) -> void:
	for c in w.carts.carts:
		if c.has("claim") and int(c.get("claim_day", day)) < day - 1 and str(c.puller) == "":
			c.erase("claim")
			c.erase("claim_day")


# ---------------------------------------------------------------- the books ------------------
## Units taken out of the ground so far, by item (rock cut and rubble cleared; fill dug again is `fill_out`): the
## ledger's pool, so start + cut_<item> = now + fill dug again (economy_sim).
func ground_cut() -> Dictionary:
	return taken.duplicate()


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	var tr := []
	var keys := track.keys()
	keys.sort()
	for k: Vector3i in keys:
		tr.append([k.x, k.y, k.z])
	var sh := []
	for s in shafts:
		sh.append(s.duplicate(true))
	return {"gen": GEN_VERSION, "opened": opened.duplicate(true), "cut": cut.duplicate(), "supports": supports.duplicate(true), "track": tr,
		"cells": cells.duplicate(true), "shafts": sh, "levels": levels.duplicate(), "taken": taken.duplicate(), "fill_out": fill_out,
		"last_dawn": last_dawn, "trapped": trapped.duplicate()}


## A saved state (absent: nothing cut, set up or laid). The deep levels are made first, then every opened cell is floor
## again, filled and collapsed cells solid, shafts' mouths open holes and their landings floor, ladders portals; a cell
## no level map holds any more (a changed generator) is left out.
func load_dict(d: Dictionary) -> void:
	opened = []
	_open_idx = {}
	cut = {}
	supports = []
	track = {}
	cells = {}
	shafts = []
	levels = []
	var full := int(cfg().stability.full)
	for lv in d.get("levels", []):
		var above: LevelMap = null
		for m: LevelMap in w.underground.maps:
			if m.level == int(lv) + 1:
				above = m
		if above != null:
			w.underground.add_level(int(lv), above)
			levels.append(int(lv))
	for o in d.get("opened", []):
		var c := Vector2i(int(o[1]), int(o[2]))
		if _map(int(o[0]), c) == null:
			continue
		_open(int(o[0]), c)
	var ck: Dictionary = d.get("cut", {})
	for k in ck:
		cut[str(k)] = int(ck[k])
	for s in d.get("supports", []):
		supports.append([int(s[0]), int(s[1]), int(s[2]), int(s[3]) if (s as Array).size() > 3 else full])
	for t in d.get("track", []):
		track[Vector3i(int(t[0]), int(t[1]), int(t[2]))] = true
	var cs: Dictionary = d.get("cells", {})
	for k in cs:
		var p: PackedStringArray = str(k).split(",")
		var lv := int(p[0])
		var c := Vector2i(int(p[1]), int(p[2]))
		var lm := _map(lv, c)
		if lm == null:
			continue
		_set_held(lv, c, int(cs[k].get("fill", 0)), int(cs[k].get("rubble", 0)))
		if held_at(lv, c) >= cell_units():
			lm.set_solid(c, true)
	for sd in d.get("shafts", []):
		var sh := {"x": int(sd.x), "y": int(sd.y), "level": int(sd.level), "dug": int(sd.dug), "landing": int(sd.get("landing", 0)),
			"rubble": int(sd.get("rubble", 0)), "ladder": int(sd.get("ladder", -1)),
			"stand": [int(sd.stand[0]), int(sd.stand[1])], "door": [int(sd.door[0]), int(sd.door[1])]}
		var c := Vector2i(int(sh.x), int(sh.y))
		var lm := _map(int(sh.level), c)
		if lm == null:
			continue
		shafts.append(sh)
		lm.set_solid(c, true)
		var below := _map(int(sh.level) - 1, c)
		if below != null and int(sh.dug) >= shaft_units() and int(sh.rubble) <= 0 and (int(sh.landing) >= cell_units() or not below.is_solid(c)):
			below.set_solid(c, false)
		if int(sh.ladder) > 0 and shaft_done(sh) and int(sh.rubble) <= 0:
			_link(sh)
	var tk: Dictionary = d.get("taken", {})
	for k in tk:
		taken[str(k)] = int(tk[k])
	fill_out = int(d.get("fill_out", 0))
	last_dawn = int(d.get("last_dawn", -1))
	trapped = {}
	var tp: Dictionary = d.get("trapped", {})
	for r in tp:
		trapped[str(r)] = str(tp[r])
