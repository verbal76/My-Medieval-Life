class_name RoadWear
extends RefCounted
## B25R1-011 (owner directives 2026-11-03: "The heavier a road or path is used, it should start to upgrade by percentage.
## Grass traveled enough turns to a path. We should be able to upgrade sections of road with stone by clicking on it and
## having the materials. Villages can upgrade their own roads by paying a worker and supplying stone"; refined: "Main dirt
## roads fade very slowly, dirt paths that come from usage fade faster. Main dirt roads we need to keep at least visible so
## we don't lose navigation, but they can get grown over slightly ... there is no upkeep cost but usage. Stone roads can get
## damaged and cause problems for carts and need materials to fix, but damage is slow").
##
## Levels of a cell of the open country (outside the village): 0 grass, 1 trail, 2 dirt road, 3 stone road. Its base level
## is the generated one (RegionRoads.cell_kind). Walkers raise it, time lowers it, paving makes it stone:
##  - footfall: each time a walker (the player, a villager, a traveller) steps onto a cell it gains FOOT percent (a cart
##    CART_FOOT); every 100 percent above its base is one level up (grass -> trail -> dirt road), at most a dirt road;
##  - usage paths fade: a cell's gained percent falls by FADE a day without footfall, level by level, back to its base and
##    never below it (the generated network never goes: routes, the map and the regional geography keep it);
##  - generated roads and trails overgrow: unwalked for OVERGROWN_DAYS they look grown over (overgrown(): a drawing state,
##    still road, still on the map, still preferred), and a step clears it; no coin or material upkeep;
##  - stone: damage grows with traffic, a cart's passage stone_cart_multiplier times a walker's step (stone_wear), and very
##    slowly with time (stone_age); at DAMAGED it looks worn, at BROKEN it is broken: a cart is slowed there (cart_factor),
##    walking is not; repair (stone) clears it.
## Time is the game day (Overworld.clock), evaluated lazily from the day of the last change, so nothing has to tick every
## cell. Only cells that differ from what the generator and the clock alone give are stored (Overworld.road_state, saved;
## an older save has none), pruned each dawn when back to that (bounded). No wall clock, no random draw; the result never
## depends on dictionary order. Inside the village nothing wears: the village map's own streets are its own.

const FOOT := 5.0              # percent a step
const CART_FOOT := 10.0
const FADE := 12.0             # percent a day a usage path loses without footfall
const OVERGROWN_DAYS := 12     # a generated road unwalked this many days looks grown over
# stone damage: balance.json road_wear (stone_foot, stone_cart_multiplier, stone_age_per_day): a cart much more than a walker
const DAMAGED := 40.0
const BROKEN := 75.0
const CART_BROKEN := 0.6       # a cart's speed on broken stone (walking is unchanged)
const CART_DAMAGED := 0.85
const PAVE_STONE := 2          # stone to pave a cell (agent decision, docs/DECISIONS.md 2026-11-03)
const REPAIR_STONE := 1        # stone to repair a damaged stone cell
const LEVEL_NAMES := ["grass", "trail", "dirt road", "stone road"]


static func _cfg(key: String, fallback: float) -> float:
	var d: Dictionary = GameData.b("road_wear") if GameData.b("road_wear") is Dictionary else {}
	return float(d.get(key, fallback))


## Percent of damage a day time alone does to stone (very small).
static func stone_age() -> float:
	return _cfg("stone_age_per_day", 0.25)


## Percent of damage one passage does to a stone cell: a walker's, or a cart's (stone_cart_multiplier times as much).
static func stone_wear(cart: bool) -> float:
	var foot := _cfg("stone_foot", 0.05)
	return foot * _cfg("stone_cart_multiplier", 12.0) if cart else foot


static func day_of(ow: Overworld) -> int:
	return int(floor(ow.clock / 1440.0))


static func base_level(ow: Overworld, c: Vector2i) -> int:
	match RegionRoads.cell_kind(ow, c):
		"trail":
			return 1
		"road":
			return 2
		"stone":
			return 3
	return 0


static func _e(ow: Overworld, c: Vector2i) -> Dictionary:
	return ow.road_state.get(c, {})


## The percent a cell has gained above its base, now (after fading since its last step).
static func gained(ow: Overworld, c: Vector2i) -> float:
	var e := _e(ow, c)
	if e.is_empty():
		return 0.0
	return maxf(0.0, float(e.get("u", 0.0)) - maxf(0.0, float(day_of(ow) - int(e.get("t", 0)))) * FADE)


## The cell's level now: 0 grass, 1 trail, 2 dirt road, 3 stone road.
static func level(ow: Overworld, c: Vector2i) -> int:
	if ow.village.has_point(c):
		return 0
	var e := _e(ow, c)
	if bool(e.get("p", false)):
		return 3
	var b := base_level(ow, c)
	if b >= 3:
		return 3
	return mini(2, b + int(floor(gained(ow, c) / 100.0)))


## Whether the cell is road of any kind now (generated or worn in).
static func is_way(ow: Overworld, c: Vector2i) -> bool:
	return level(ow, c) >= 1


## Days since a walker last stepped here (a generated road never walked counts from day 0).
static func idle_days(ow: Overworld, c: Vector2i) -> int:
	return day_of(ow) - int(_e(ow, c).get("t", 0))


## A generated road or trail grown over by want of walkers (drawing only: it stays road).
static func overgrown(ow: Overworld, c: Vector2i) -> bool:
	var b := base_level(ow, c)
	return b in [1, 2] and level(ow, c) == b and not bool(_e(ow, c).get("p", false)) and idle_days(ow, c) >= OVERGROWN_DAYS


## A stone cell's damage now, 0-100.
static func damage(ow: Overworld, c: Vector2i) -> float:
	if level(ow, c) < 3:
		return 0.0
	var e := _e(ow, c)
	var since := int(e.get("dd", 0))
	return clampf(float(e.get("d", 0.0)) + float(day_of(ow) - since) * stone_age(), 0.0, 100.0)


## "", "damaged" or "broken" for a stone cell.
static func damage_state(ow: Overworld, c: Vector2i) -> String:
	var d := damage(ow, c)
	return "broken" if d >= BROKEN else "damaged" if d >= DAMAGED else ""


## A cart's speed factor on this cell (stone damage hampers carts; 1 elsewhere).
static func cart_factor(ow: Overworld, c: Vector2i) -> float:
	match damage_state(ow, c):
		"broken":
			return CART_BROKEN
		"damaged":
			return CART_DAMAGED
	return 1.0


## A drawing state that changed (the view redraws the cell and its neighbours).
static func _touched(ow: Overworld, c: Vector2i) -> void:
	ow.road_dirty[c] = true
	ow.road_rev += 1


## A walker steps onto cell `c` of the open country (`cart`: pulling a cart).
static func foot(ow: Overworld, c: Vector2i, cart := false) -> void:
	if ow == null or ow.village.has_point(c):
		return
	var day := day_of(ow)
	var lv := level(ow, c)
	var look := visual(ow, c)
	var e: Dictionary = ow.road_state.get(c, {})
	if lv >= 3:
		e.d = damage(ow, c) + stone_wear(cart)
		e.dd = day
		e.t = day
	else:
		var b := base_level(ow, c)
		var cap := float((2 - b) * 100 + 50)             # a little above the top level, so a road holds a few days unwalked
		e.u = minf(cap, gained(ow, c) + (CART_FOOT if cart else FOOT))
		e.t = day
	ow.road_state[c] = e
	if visual(ow, c) != look:
		_touched(ow, c)


## Pave cell `c` with stone (it never fades back; its damage starts at 0). Callers take the stone.
static func pave(ow: Overworld, c: Vector2i) -> void:
	var e: Dictionary = ow.road_state.get(c, {})
	e.p = true
	e.d = 0.0
	e.dd = day_of(ow)
	e.t = day_of(ow)
	ow.road_state[c] = e
	_touched(ow, c)


## Repair a stone cell: its damage back to 0. Callers take the stone.
static func repair(ow: Overworld, c: Vector2i) -> void:
	var e: Dictionary = ow.road_state.get(c, {})
	e.d = 0.0
	e.dd = day_of(ow)
	ow.road_state[c] = e
	_touched(ow, c)


## Why cell `c` cannot be paved or repaired now ("" when it can), and what it would take: {why, mode, stone}.
static func work_for(ow: Overworld, c: Vector2i) -> Dictionary:
	if ow == null or ow.village.has_point(c):
		return {"why": "The village's own streets are not paved this way.", "mode": "", "stone": 0}
	var lv := level(ow, c)
	if lv == 0:
		return {"why": "That is not a road or a path: only a road or a path can be paved.", "mode": "", "stone": 0}
	if lv == 3:
		if damage(ow, c) < DAMAGED:
			return {"why": "That stone road is sound.", "mode": "", "stone": 0}
		return {"why": "", "mode": "repair", "stone": REPAIR_STONE}
	return {"why": "", "mode": "pave", "stone": PAVE_STONE}


## The tile look of a cell: "" (grass), "trail", "trail_overgrown", "road", "road_overgrown", "stone", "stone_damaged",
## "stone_broken".
static func visual(ow: Overworld, c: Vector2i) -> String:
	var lv := level(ow, c)
	match lv:
		0:
			return ""
		1:
			return "trail_overgrown" if overgrown(ow, c) else "trail"
		2:
			return "road_overgrown" if overgrown(ow, c) else "road"
	var ds := damage_state(ow, c)
	return "stone" if ds == "" else "stone_" + ds


## Dawn: forget the cells that are back to what the generator and the clock alone give (bounded memory).
static func prune(ow: Overworld) -> void:
	var drop := []
	for c: Vector2i in ow.road_state:
		var e: Dictionary = ow.road_state[c]
		if bool(e.get("p", false)):
			continue
		if base_level(ow, c) >= 3:
			if absf(float(e.get("d", 0.0)) + float(day_of(ow) - int(e.get("dd", 0))) * stone_age() - float(day_of(ow)) * stone_age()) < 0.01:
				drop.append(c)                    # its damage is a never-walked cell's: the default
			continue
		if gained(ow, c) <= 0.0 and idle_days(ow, c) >= OVERGROWN_DAYS:
			drop.append(c)
	for c in drop:
		ow.road_state.erase(c)


# ------------------------------------------------------------------ the busiest ways --------------
## The road cells the village would pave or repair first: damaged stone, then the busiest dirt road and worn paths within
## `reach` tiles of the village, by the routes along them (RegionRoads.main_cells) and their footfall, ties by row and column.
## [{cell, mode}] in that order, at most `most`.
static func village_targets(ow: Overworld, reach: int, most: int) -> Array:
	var area := ow.village.grow(reach)
	var main := RegionRoads.main_cells(ow)
	var cand := []
	for c: Vector2i in main:
		if area.has_point(c) and not ow.village.has_point(c):
			var lv := level(ow, c)
			if lv == 3 and damage(ow, c) >= DAMAGED:
				cand.append([0, -int(damage(ow, c)), c.y, c.x, "repair"])
			elif lv == 2:
				cand.append([1, -int(main[c]) * 100 - int(gained(ow, c)), c.y, c.x, "pave"])
	for c: Vector2i in ow.road_state:
		if area.has_point(c) and not main.has(c) and not ow.village.has_point(c) and level(ow, c) == 2 and base_level(ow, c) < 2:
			cand.append([1, -int(gained(ow, c)), c.y, c.x, "pave"])
	cand.sort()
	var out := []
	for k in mini(most, cand.size()):
		out.append({"cell": Vector2i(int(cand[k][3]), int(cand[k][2])), "mode": str(cand[k][4])})
	return out


# ------------------------------------------------------------------ save -------------------
static func to_save(ow: Overworld) -> Array:
	var cells: Array = ow.road_state.keys()
	cells.sort()
	var out := []
	for c: Vector2i in cells:
		var e: Dictionary = ow.road_state[c]
		out.append([c.x, c.y, snappedf(float(e.get("u", 0.0)), 0.01), int(e.get("t", 0)), 1 if bool(e.get("p", false)) else 0,
			snappedf(float(e.get("d", 0.0)), 0.01), int(e.get("dd", 0))])
	return out


static func load_into(ow: Overworld, list: Array) -> void:
	ow.road_state.clear()
	for r in list:
		var e := {"u": float(r[2]), "t": int(r[3]), "d": float(r[5]), "dd": int(r[6])}
		if int(r[4]) == 1:
			e.p = true
		ow.road_state[Vector2i(int(r[0]), int(r[1]))] = e
	ow.road_rev += 1
