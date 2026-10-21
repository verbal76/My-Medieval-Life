class_name MineWorks
extends RefCounted
## MIN-F: the works below the surface (Mining spec stage 4 and 5, phase F; docs/build17/MIN_F_UNDERGROUND.md): tunnels
## cut into the rock of a level, the timber supports a tunnel needs before it is extended, track laid on cells, and the
## minecart set down on it (a cart of kind "minecart", Carts). One rule for the player and a villager (PAR-01): every
## function takes `who` (PlayerState or NPC) and works from their own inventory, on the level they stand on.
##
## Finite and conserved (OD-28, WDR-022): a rock cell holds the units of mine_works.json "cell" (3 stone, then 2 spoil);
## each cut moves one unit into the cutter's inventory (counted cut_<item>); the last unit opens the cell as floor of
## its level (LevelMap.set_solid, its own A* at once). Only the hill's rock with rock all round may be cut (the rule of
## every level's floor, Underground.under_rock), so the tunnels are bounded by the hill. A support or a track section is
## used up where it is placed (used_<item>); nothing is given back. Collapse is not simulated: a support is what lets a
## tunnel be extended (a cell is cut only within `support.reach` of one), nothing more is claimed.
##
## Saved under "mine_works" {gen, opened: [[level, x, y], ...], cut: {"level,x,y": units}, supports: [[level, x, y]],
## track: [[level, x, y]]}; absent (a save from before MIN-F): nothing cut, placed or laid. On load the opened cells are
## made floor again before anyone is put back on them.

signal changed(level: int, cell: Vector2i)   # a cell opened, a support set up or a track laid (the views redraw it)

const GEN_VERSION := 1

static var _cfg := {}

var w: World
var opened: Array = []          # [level, x, y] of every cell cut through, in the order they opened
var cut := {}                   # "level,x,y" -> units cut from a rock cell not yet opened
var supports: Array = []        # [level, x, y] of every timber support, in the order they were set up
var track := {}                 # Vector3i(level, x, y) -> true: a track section lies there


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/mine_works.json"))
	return _cfg


static func create(world: World) -> MineWorks:
	var m := MineWorks.new()
	m.w = world
	return m


# ---------------------------------------------------------------- the rock -------------------
## Units a rock cell holds (5: 3 stone and 2 spoil).
static func cell_units() -> int:
	var n := 0
	for l in cfg().cell:
		n += int(l.amount)
	return n


## The item of the `u`-th unit cut from a cell (0 first), "" past the last.
static func item_of(u: int) -> String:
	var k := u
	for l in cfg().cell:
		if k < int(l.amount):
			return str(l.item)
		k -= int(l.amount)
	return ""


static func minutes_of(u: int) -> float:
	var k := u
	for l in cfg().cell:
		if k < int(l.amount):
			return float(l.minutes)
		k -= int(l.amount)
	return 0.0


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


## Why `c` on `level` is not rock a tunnel may be cut into ("" if it is), whoever cuts: the rock of a level's map (not
## its floor, not a seam's cell: seams are mined), under the hill's static rock with rock all round (Underground.
## under_rock) and inside the map's edge, beside an open face, and within reach of a timber support.
func rock_refusal(level: int, c: Vector2i) -> String:
	if level == 0 or w.underground == null:
		return "Tunnels are cut below ground; on the surface, dig an open pit."
	var lm := w.underground.map_at(level, c)
	if lm == null or not lm.is_solid(c):
		return "There is no rock to cut there."
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


## Why `who` cannot cut a unit from `c` with `tool` ("" if they can): a pickaxe, standing at the face on that level.
func dig_refusal(who, c: Vector2i, tool := "pickaxe") -> String:
	if tool == "" or not who.inv.has(tool) or str(GameData.item(tool).get("tool", "")) != str(cfg().tool):
		return "You need a pickaxe to cut rock."
	var level := level_of(who)
	var why := rock_refusal(level, c)
	if why != "":
		return why
	var at := _cell_of(who)
	if maxi(absi(at.x - c.x), absi(at.y - c.y)) > 1 or w.underground.is_solid(level, at):
		return "Stand at the face to cut it."
	return ""


## `who` cuts one unit from rock cell `c` of the level they stand on with `tool` (PAR-01: the same for everyone): the
## unit goes to `into` (counted cut_<item>), the pickaxe wears `wear` (Mining's tool_wear_save may spare it), `xp`
## Mining xp. The cell's last unit opens it: floor of its level, its A* at once (`opened`). Returns {result: "ok" |
## "refused", why, item, n, broke, up, opened}.
func dig(who, c: Vector2i, into: Inventory, tool := "pickaxe") -> Dictionary:
	var why := dig_refusal(who, c, tool)
	if why != "":
		return {"result": "refused", "why": why}
	var level := level_of(who)
	var k := key(level, c)
	var u := cut_at(level, c)
	var item := item_of(u)
	w._work_goods(who, into, item, 1, "cut_")
	w.stat("tunnel_units_cut")
	u += 1
	var done := u >= cell_units()
	if done:
		cut.erase(k)
		opened.append([level, c.x, c.y])
		w.underground.map_at(level, c).set_solid(c, false)
		w.stat("tunnel_cells_opened")
	else:
		cut[k] = u
	var broke := w._work_wear(who, tool, int(cfg().wear), "mining", "tool_wear_save")
	if broke and who is PlayerState and who.tool == tool:
		who.tool = ""
	var up := Skills.gain(who, "mining", int(cfg().xp))
	if done:
		changed.emit(level, c)
	return {"result": "ok", "why": "", "item": item, "n": 1, "broke": broke, "up": up, "opened": done}


## The player's cut, timed as a mining swing (as OpenPits.player_secs).
func player_secs(c: Vector2i, tool: String) -> float:
	return minutes_of(cut_at(w.player_level, c)) / float(GameData.b("game_minutes_per_second")) * 0.6 \
			/ float(GameData.item(tool).get("speed", 1.0)) * Skills.value(w.player, "mining", "mine_time", 1.0)


## A villager's minutes for the next unit of `c` (Mining mine_time).
func npc_minutes(n: NPC, c: Vector2i) -> float:
	return minutes_of(cut_at(n.depth, c)) * Skills.value(n, "mining", "mine_time", 1.0)


# ---------------------------------------------------------------- supports -------------------
func support_at(level: int, c: Vector2i) -> bool:
	for s in supports:
		if int(s[0]) == level and int(s[1]) == c.x and int(s[2]) == c.y:
			return true
	return false


## Whether a timber support stands within `support.reach` cells of `c` (the larger axis) on `level`.
func supported(level: int, c: Vector2i) -> bool:
	var r := int(cfg().support.reach)
	for s in supports:
		if int(s[0]) == level and maxi(absi(int(s[1]) - c.x), absi(int(s[2]) - c.y)) <= r:
			return true
	return false


## Why `who` cannot set up a timber support on floor cell `c` of their level ("" if they can): the support in their
## inventory, a mallet, floor below the surface, none there yet, within reach.
func support_refusal(who, c: Vector2i) -> String:
	var sc: Dictionary = cfg().support
	if not who.inv.has(str(sc.item)):
		return "You need a timber support (the carpenter's work: logs and planks at the sawhorse)."
	if not _has_tool(who, str(sc.tool)):
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
## Crafting xp. {result, why, broke, up}.
func place_support(who, c: Vector2i) -> Dictionary:
	var why := support_refusal(who, c)
	if why != "":
		return {"result": "refused", "why": why}
	var sc: Dictionary = cfg().support
	who.inv.remove(str(sc.item), 1)
	w.stat("used_" + str(sc.item))
	var level := level_of(who)
	supports.append([level, c.x, c.y])
	w.stat("supports_set_up")
	var broke := w._work_wear(who, str(sc.tool), int(sc.wear), str(sc.skill), "")
	var up := Skills.gain(who, str(sc.skill), int(sc.xp))
	changed.emit(level, c)
	return {"result": "ok", "why": "", "broke": broke, "up": up}


func support_count() -> int:
	return supports.size()


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


## Whether a minecart pulled through a portal can go: track on the stand it leaves and on the stand it reaches.
func crossing_ok(leg_from: Dictionary, leg_to: Dictionary) -> bool:
	return track_at(int(leg_from.level), leg_from.stand) and track_at(int(leg_to.level), leg_to.stand)


func _has_tool(who, kind: String) -> bool:
	for id in who.inv.ids():
		if str(GameData.item(id).get("tool", "")) == kind:
			return true
	return false


# ---------------------------------------------------------------- the books ------------------
## Units cut from the rock so far, by item (the cells opened and the units of cells being cut): the ledger's pool, so
## start + cut_<item> = now (economy_sim).
func ground_cut() -> Dictionary:
	var out := {}
	var add := func(units: int) -> void:
		for u in units:
			var it := item_of(u)
			out[it] = int(out.get(it, 0)) + 1
	for _o in opened:
		add.call(cell_units())
	var keys := cut.keys()
	keys.sort()
	for k in keys:
		add.call(int(cut[k]))
	return out


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	var tr := []
	var keys := track.keys()
	keys.sort()
	for k: Vector3i in keys:
		tr.append([k.x, k.y, k.z])
	return {"gen": GEN_VERSION, "opened": opened.duplicate(true), "cut": cut.duplicate(), "supports": supports.duplicate(true), "track": tr}


## A saved state (absent: nothing cut, set up or laid). Every opened cell becomes floor of its level again; a cell no
## level map holds any more (a changed generator) is left out.
func load_dict(d: Dictionary) -> void:
	opened = []
	cut = {}
	supports = []
	track = {}
	for o in d.get("opened", []):
		var c := Vector2i(int(o[1]), int(o[2]))
		var lm: LevelMap = w.underground.map_at(int(o[0]), c) if w.underground != null else null
		if lm == null:
			continue
		lm.set_solid(c, false)
		opened.append([int(o[0]), c.x, c.y])
	var ck: Dictionary = d.get("cut", {})
	for k in ck:
		cut[str(k)] = int(ck[k])
	for s in d.get("supports", []):
		supports.append([int(s[0]), int(s[1]), int(s[2])])
	for t in d.get("track", []):
		track[Vector3i(int(t[0]), int(t[1]), int(t[2]))] = true
