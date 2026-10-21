class_name Farming
extends RefCounted
## PL2-015: farming and livestock by the player, on ground they own or lease. Headless: no nodes; main.gd
## offers the actions as targets (targets_at) and runs them as timed actions (plan), the tests call the
## same functions. Numbers are balance.json "farming"; the rules and open questions are in
## docs/BUILD_DECISIONS.md "Farming".
##
## Land: only a parcel the player holds (World.holds) whose ground has no building or building site on it.
## Clearing: a mature tree is felled (the axe, as anywhere), then its stump dug out; a young tree or a
## sapling is pulled up; a wild plant is grubbed up; a boulder is mined away (B8-026); each ends as
## "cleared" ground (nothing grows back). Tilling: one cell at a time, by hand (slow, very tiring) or with the
## hand plough (the baseline); each tilled cell joins the player's field (`cells`), whatever its shape.
## Crops: a tilled cell is sown with a seed, grows by hourly progress (the season's rate: none in winter),
## ripens, and is harvested for its yield and some seed back (seed saving).
## Animals: the player fences a pen of one species on their ground (planks), buys stock from a keeper (real
## animals out of the manor's pen, paid to the keeper), feeds it from the trough like the village's pens, and
## collects eggs, milk and wool, which the well-fed adults make (see daily_products).
## The manor's own fields (World.fields) and their farmers are untouched: nothing here is theirs to cut.

const COZY := 200000                  # atlas offset of the Cozy Farm tiles (as tools/build_village.py)
const GATE_TILE := 29 * 54 + 0
const FENCE := {"tl": 29 * 54 + 4, "t": 29 * 54 + 5, "tr": 29 * 54 + 6, "l": 30 * 54 + 4, "r": 30 * 54 + 6,
		"bl": 31 * 54 + 4, "b": 31 * 54 + 5, "br": 31 * 54 + 6}

var w
var cells := {}                       # Vector2i -> {crop, state: tilled | growing | ripe, progress 0..1}
var next_pen := 0                     # "pen_player0", "pen_player1", ...
var pen_why := ""                     # why the last build_pen failed


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("farming")


static func crops() -> Dictionary:
	return cfg().crops


## Game days of full-rate growth a crop needs: its `seasons` (calendar seasons) through Life (TIME-02).
static func crop_days(crop: String) -> float:
	return Life.seasons_to_days(float(crops()[crop].seasons))


## The crop a seed item sows, or "".
static func crop_of_seed(item: String) -> String:
	for id in crops():
		if str(crops()[id].seed) == item:
			return id
	return ""


# ---------------------------------------------------------------- land -----------------------
## The parcel the player holds that this cell lies in ({} if none).
func parcel_at(c: Vector2i) -> Dictionary:
	for p in w.plots:
		if Rect2i(int(p.x), int(p.y), int(p.w), int(p.h)).has_point(c) and w.holds(World.PLAYER, p):
			return p
	return {}


## Why this cell cannot be farmed or fenced, "" if it is the player's, open ground.
func land_refusal(c: Vector2i) -> String:
	if not w.map.in_village(c):
		return "Only land you own or lease can be farmed."
	var p := parcel_at(c)
	if p.is_empty():
		return "That is not your land: buy or lease ground from the manor first."
	if not p.site.is_empty() or str(p.get("building", "")) != "":
		return "There is a building or a building site on this ground."
	if w.place_of(Vector2(c) + Vector2(0.5, 0.5)) != "":
		return "Not indoors."
	for b in w.buildings.values():
		if Rect2i(int(b.x), int(b.y), int(b.w), int(b.h) + 1).has_point(c):
			return "Keep clear of the building."
	if w._road_cells().has(c) or w._exit_cells().has(c):
		return "Not on the road."
	for id in w.fauna.pens:
		var pen: Dictionary = w.fauna.pens[id]
		if Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h)).has_point(c):
			return "That is a pen."
	for k in w.containers:
		if int(k.x) == c.x and int(k.y) == c.y:
			return "Something stands there."
	return ""


## What stands on a cell that must go before it can be tilled or fenced: {kind: tree | plant | boulder |
## solid, ref} ({} if nothing). A mature tree's crown over the cell above its trunk does not count.
func obstacle(c: Vector2i) -> Dictionary:
	for t in w.trees:
		if int(t.x) == c.x and int(t.y) == c.y and t.state != "cleared":
			w.sync_tree(t)
			return {"kind": "tree", "ref": t}
	var dep: Dictionary = w.deposit_at(c)
	if not dep.is_empty() and int(dep.amount) > 0:
		return {"kind": "boulder", "ref": dep}
	for pl in w.plants:
		if int(pl.x) == c.x and int(pl.y) == c.y and pl.state != "cleared":
			return {"kind": "plant", "ref": pl}
	if w.map.is_solid(c):
		return {"kind": "solid", "ref": {}}
	return {}


func obstacle_name(o: Dictionary) -> String:
	match str(o.kind):
		"tree":
			return Trees.describe(str(o.ref.state)).to_lower()
		"plant":
			return "a wild plant"
		"boulder":
			return "a boulder"
	return "something in the way"


## Why a tree cannot be cleared by the player now, "" if it can: a mature tree is felled first (the axe), a
## stump or a growing tree is dug out with an axe, a sapling or a young tree is pulled up by hand.
func clear_tree_refusal(t: Dictionary, p: PlayerState) -> String:
	if parcel_at(Vector2i(int(t.x), int(t.y))).is_empty():
		return "That is not your land."
	match str(t.state):
		"grown":
			return "Fell the tree first, then dig out the stump."
		"cleared":
			return "It is cleared already."
		"stump", "growing":
			return "" if p.tool_of("axe") != "" else "Digging out a stump needs an axe. The smith sells them."
	return ""


## Dig out or pull up a tree that is no longer a mature one; the ground is cleared for good.
func clear_tree(t: Dictionary, p: PlayerState) -> String:
	var why := clear_tree_refusal(t, p)
	if why != "":
		return why
	if str(t.state) in ["stump", "growing"]:
		var cost := float(cfg().clear.stump_stamina)
		if p.stamina < cost:
			return "You are too tired: rest a moment."
		p.stamina -= cost
	t.state = "cleared"
	w.map.set_solid(Vector2i(int(t.x), int(t.y)), false)
	w.tree_changed.emit(t)
	w.stat("farm_cleared_tree")
	return ""


func clear_plant(pl: Dictionary) -> String:
	if parcel_at(Vector2i(int(pl.x), int(pl.y))).is_empty():
		return "That is not your land."
	pl.state = "cleared"
	w.tile_changed.emit(Vector2i(int(pl.x), int(pl.y)), World.PLANT_LAYER, -1)
	w.stat("farm_cleared_plant")
	return ""


func clear_seconds(t: Dictionary) -> float:
	return float(cfg().clear.stump_seconds) if str(t.state) in ["stump", "growing"] else float(cfg().clear.young_seconds)


# ---------------------------------------------------------------- tilling --------------------
## {seconds, stamina} one cell costs: by hand, or with the hand plough when the player carries one.
func till_cost(p: PlayerState) -> Dictionary:
	return cfg().till.plough if p.tool_of("plough") != "" else cfg().till.hand


func till_refusal(c: Vector2i, p: PlayerState) -> String:
	var why := land_refusal(c)
	if why != "":
		return why
	if cells.has(c):
		return "Already tilled."
	var o := obstacle(c)
	if not o.is_empty():
		return "Clear %s first." % obstacle_name(o)
	if p.stamina < float(till_cost(p).stamina):
		return "You are too tired to dig: rest a moment."
	return ""


## Till a cell: it joins the player's field. Takes the stamina, wears the plough. "" when done.
func till(c: Vector2i, p: PlayerState) -> String:
	var why := till_refusal(c, p)
	if why != "":
		return why
	var plough := p.tool_of("plough")
	p.stamina -= float(till_cost(p).stamina)
	if plough != "" and p.inv.wear(plough, 1):
		w.note("Your hand plough broke.")
		if p.tool == plough:
			p.tool = ""
	cells[c] = {"crop": "", "state": "tilled", "progress": 0.0}
	w.stat("farm_tilled")
	_show_around(c)
	return ""


# ---------------------------------------------------------------- sowing, growing, harvest ---
func season_rate() -> float:
	return float(cfg().season_rate.get(w.season(), 1.0))


func can_sow_now() -> bool:
	return (cfg().sow_seasons as Array).has(w.season())


func sow_refusal(c: Vector2i, crop: String, p: PlayerState) -> String:
	if not cells.has(c) or str(cells[c].state) != "tilled":
		return "Only tilled, empty soil can be sown."
	if not can_sow_now():
		return "Nothing sown in %s will grow: wait for spring." % w.season().to_lower()
	if not p.inv.has(str(crops()[crop].seed)):
		return "You have no %s." % GameData.item_name(str(crops()[crop].seed)).to_lower()
	return ""


func sow(c: Vector2i, crop: String, p: PlayerState) -> String:
	var why := sow_refusal(c, crop, p)
	if why != "":
		return why
	p.inv.remove(str(crops()[crop].seed), 1)
	w.stat("used_" + str(crops()[crop].seed))          # the seed is used up (SEED-02: the ledger counts it)
	cells[c] = {"crop": crop, "state": "growing", "progress": 0.0}
	w.stat("farm_sown_" + crop)
	_show_around(c)
	return ""


## Every game hour: sown cells grow by 1 / (crop_days * 24) of their crop, times the season's rate.
func hour() -> void:
	if cells.is_empty():
		return
	var rate := season_rate()
	if rate <= 0.0:
		return
	for c: Vector2i in cells:
		var cell: Dictionary = cells[c]
		if cell.state != "growing":
			continue
		cell.progress = float(cell.progress) + rate / (crop_days(str(cell.crop)) * 24.0)
		if float(cell.progress) >= 0.999999:
			cell.progress = 1.0
			cell.state = "ripe"
			_show(c)


## What a ripe cell gives: {item: n} for the crop and its seed; the cell is tilled and empty again.
func harvest_goods(c: Vector2i) -> Dictionary:
	var cell: Dictionary = cells.get(c, {})
	if cell.is_empty() or cell.state != "ripe":
		return {}
	var cr: Dictionary = crops()[cell.crop]
	var out := {str(cr.item): int(cr.yield)}
	if int(cr.seeds_back) > 0:
		out[str(cr.seed)] = int(cr.seeds_back)
	return out


func harvest(c: Vector2i, p: PlayerState) -> Dictionary:
	var out := harvest_goods(c)
	if out.is_empty():
		return {}
	for id in out:
		if not p.inv.can_add(id):
			return {}
	for id in out:
		p.inv.add(id, int(out[id]))
		w.stat("farm_harvest_" + id, float(out[id]))
	cells[c] = {"crop": "", "state": "tilled", "progress": 0.0}
	_show(c)
	return out


## Days until a growing cell is ripe at the present season's rate (INF in winter), for a prompt.
func days_left(c: Vector2i) -> float:
	var cell: Dictionary = cells[c]
	var rate := season_rate()
	if rate <= 0.0:
		return INF
	return (1.0 - float(cell.progress)) * crop_days(str(cell.crop)) / rate


## A building is marked out on the parcel: the field on it is ploughed under (crops and tilled soil are lost).
func give_up_cells(p: Dictionary) -> void:
	var r := Rect2i(int(p.x), int(p.y), int(p.w), int(p.h))
	var gone := 0
	for c in cells.keys():
		if r.has_point(c):
			cells.erase(c)
			gone += 1
			w.tile_changed.emit(c, "field", -1)
	if gone > 0:
		w.note("The field on the ground is ploughed under for the building (%d cells)." % gone)
		for c in cells.keys():
			if r.grow(1).has_point(c):
				_show(c)


## Why a building cannot be marked out on a parcel now ("" if it can): a player's pen stands on it.
func building_refusal(p: Dictionary) -> String:
	var r := Rect2i(int(p.x), int(p.y), int(p.w), int(p.h))
	for pen in player_pens():
		if r.intersects(Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h))):
			return "your %s pen stands on this ground" % pen.kind
	return ""


# ---------------------------------------------------------------- drawing --------------------
## The tile of a field cell: the pack's tilled, growing or ripe tile, closed at the edges of the field's
## shape (a cell with no field cell beside it on a side gets that side's edge tile).
func tile_for(c: Vector2i) -> int:
	var cell: Dictionary = cells[c]
	var base: int = w.map.data.tiles.field[{"tilled": "tilled", "growing": "growing", "ripe": "ripe"}[cell.state]]
	var cols := int(w.map.data.atlases[0].columns)
	var l := cells.has(c + Vector2i.LEFT)
	var r := cells.has(c + Vector2i.RIGHT)
	var u := cells.has(c + Vector2i.UP)
	var d := cells.has(c + Vector2i.DOWN)
	var col := 0 if (not l and not r) else (1 if not l else (3 if not r else 2))
	var row := 3 if (not u and not d) else (0 if not u else (2 if not d else 1))
	return base + row * cols + col


func _show(c: Vector2i) -> void:
	if cells.has(c):
		w.tile_changed.emit(c, "field", tile_for(c))


## A cell changed: it and its four neighbours are drawn again (their edges depend on it).
func _show_around(c: Vector2i) -> void:
	for dc in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_show(c + dc)


## Draw everything again: the field's cells and the pens' fences (a loaded world, main._apply_world_changes).
func show_all() -> void:
	for c: Vector2i in cells:
		_show(c)
	for pen in player_pens():
		_show_fence(pen)


# ---------------------------------------------------------------- pens -----------------------
func player_pens() -> Array:
	var out := []
	var ids: Array = w.fauna.pens.keys()
	ids.sort()
	for id in ids:
		if w.fauna.pens[id].get("player", false):
			out.append(w.fauna.pens[id])
	return out


func pen_rect(kind: String, at: Vector2i) -> Rect2i:
	var s: Array = cfg().pens[kind]
	return Rect2i(at, Vector2i(int(s[0]), int(s[1])))


## The rectangle of a pen of this kind in front of the player (the pen's middle `size/2 + 1` tiles ahead).
func pen_rect_ahead(kind: String, pos: Vector2, facing: Vector2) -> Rect2i:
	var s: Array = cfg().pens[kind]
	var front := pos + facing.normalized() * (maxf(float(s[0]), float(s[1])) / 2.0 + 1.0)
	return Rect2i(Vector2i(floori(front.x) - int(s[0]) / 2, floori(front.y) - int(s[1]) / 2), Vector2i(int(s[0]), int(s[1])))


func fence_cells(rect: Rect2i) -> Array:
	var out := []
	for j in rect.size.y:
		for i in rect.size.x:
			if i == 0 or j == 0 or i == rect.size.x - 1 or j == rect.size.y - 1:
				out.append(rect.position + Vector2i(i, j))
	return out


func pen_planks(rect: Rect2i) -> int:
	return ceili(float(fence_cells(rect).size() - 1) / float(cfg().fence_cells_per_plank))


func pen_refusal(kind: String, rect: Rect2i, p: PlayerState) -> String:
	if not cfg().pens.has(kind):
		return "A pen for what?"
	var gate := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y)
	var cs := []
	for j in rect.size.y:
		for i in rect.size.x:
			cs.append(rect.position + Vector2i(i, j))
	cs.append(gate + Vector2i.UP)                          # the cell the keeper feeds from
	for c: Vector2i in cs:
		var why := land_refusal(c)
		if why != "":
			return why
		if cells.has(c):
			return "Your field is in the way."
		var o := obstacle(c)
		if not o.is_empty():
			return "Clear %s first." % obstacle_name(o)
	if p.inv.count("plank") < pen_planks(rect):
		return "A %s pen needs %d planks." % [kind, pen_planks(rect)]
	return ""


## Fence a pen: the planks are used up, the fence is solid but for the gate, and the pen exists (empty).
## Returns the pen, or {} with `pen_why` set.
func build_pen(kind: String, rect: Rect2i, p: PlayerState) -> Dictionary:
	pen_why = pen_refusal(kind, rect, p)
	if pen_why != "":
		return {}
	p.inv.remove("plank", pen_planks(rect))
	w.stat("used_pen_plank", float(pen_planks(rect)))
	var gate := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y)
	var pen := {"id": "pen_player%d" % next_pen, "kind": kind, "x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y,
			"gate": [gate.x, gate.y], "feed_at": [gate.x, gate.y - 1], "trough": 0, "owner": World.PLAYER, "tenant": "", "player": true, "products": {}}
	next_pen += 1
	w.fauna.pens[pen.id] = pen
	_fence_solid(pen)
	_show_fence(pen)
	w.note("%s %s fenced a %s pen." % [p.name, p.family, kind])
	return pen


func _fence_solid(pen: Dictionary) -> void:
	var r := Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h))
	for c: Vector2i in fence_cells(r):
		w.map.set_solid(c, not (c.x == int(pen.gate[0]) and c.y == int(pen.gate[1])))


func _show_fence(pen: Dictionary) -> void:
	var r := Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h))
	for c: Vector2i in fence_cells(r):
		var i := c.x - r.position.x
		var j := c.y - r.position.y
		var edge: String = {Vector2i(0, 0): "tl", Vector2i(r.size.x - 1, 0): "tr", Vector2i(0, r.size.y - 1): "bl", Vector2i(r.size.x - 1, r.size.y - 1): "br"}.get(Vector2i(i, j), "")
		if edge == "":
			edge = "t" if j == 0 else ("b" if j == r.size.y - 1 else ("l" if i == 0 else "r"))
		w.tile_changed.emit(c, "below5", COZY + (GATE_TILE if (c.x == int(pen.gate[0]) and c.y == int(pen.gate[1])) else int(FENCE[edge])))


## The player's pen of a species with room for another animal ({} if none).
func pen_with_room(kind: String) -> Dictionary:
	for pen in player_pens():
		if pen.kind == kind and w.fauna.count(pen.id, kind) < w.fauna.cap(pen.id, kind):
			return pen
	return {}


# ---------------------------------------------------------------- animals --------------------
func animal_price(a: Animal) -> int:
	var base := int(cfg().animal_price[a.species])
	return base if a.adult(w.minutes) else maxi(1, roundi(base * float(cfg().young_price_share)))


## The animal of this sex a keeper can spare from a manor pen: not a newborn, and the pen keeps more than its
## breeding stock; the youngest first. null if none.
func spare_animal(src: Dictionary, sex: String) -> Animal:
	if w.fauna.count(src.id, src.kind) <= int(GameData.b("animals")[src.kind].keep):
		return null
	var best: Animal = null
	for a: Animal in w.fauna.animals:
		if not a.alive or a.area != src.id or a.sex != sex or a.stage(w.minutes) == "newborn":
			continue
		if best == null or a.born > best.born:
			best = a
	return best


func buy_refusal(src: Dictionary, sex: String, p: PlayerState) -> String:
	if src.get("player", false):
		return "That is your own pen."
	if not cfg().animal_price.has(src.kind):
		return "Nobody sells those."
	if pen_with_room(src.kind).is_empty():
		return "You need a %s pen with room: fence one on your ground." % src.kind
	var a := spare_animal(src, sex)
	if a == null:
		return "The keeper has no %s to spare." % ("female" if sex == "f" else "male")
	if p.coins < animal_price(a):
		return "You need %d coins." % animal_price(a)
	return ""


## Buy one animal from the keeper of a manor pen into your own pen of that kind. The coins go to the keeper (the
## manor's treasury if the pen has none); the animal is the keeper's real stock. "" when done.
func buy_animal(src: Dictionary, sex: String, p: PlayerState) -> String:
	var no := buy_refusal(src, sex, p)
	if no != "":
		return no
	var a := spare_animal(src, sex)
	var dst := pen_with_room(src.kind)
	var price := animal_price(a)
	p.coins -= price
	var keeper: NPC = w.pen_keeper(src)
	if keeper != null:
		keeper.coins += price
		keeper.earned += price
	else:
		w.treasury += price
	a.area = dst.id
	var cs: Array = w.fauna.cells(dst.id)
	a.pos = Vector2(cs[w.rng.randi() % cs.size()]) + Vector2(0.5, 0.5) if not cs.is_empty() else a.pos
	a.goal = Vector2.INF
	a.next_product = 0.0
	w.stat("farm_bought_" + a.species)
	w.note("%s %s bought a %s from %s." % [p.name, p.family, a.label().to_lower(), ("%s %s" % [keeper.name, keeper.family]) if keeper != null else "the manor's keeper"])
	return ""


## Morning: each well-fed adult in a pen makes its product when its time comes (eggs and milk of the
## females, wool of any); it waits in the pen, up to product_cap of each, until collected: by the player
## at their own pens, by the keeper at the village's (Build 13).
func daily_products() -> void:
	var now: float = w.minutes
	var ids: Array = w.fauna.pens.keys()
	ids.sort()
	for pid in ids:
		var pen: Dictionary = w.fauna.pens[pid]
		if not pen.has("products"):
			pen["products"] = {}
		var spec: Dictionary = cfg().products.get(pen.kind, {})
		if spec.is_empty():
			continue
		var made := {}
		for a: Animal in w.fauna.animals:
			if not a.alive or a.area != pen.id or a.stage(now) != "adult" or not w.fauna.well_fed(a):
				continue
			if str(spec.sex) != "any" and a.sex != str(spec.sex):
				continue
			if a.next_product <= 0.0:
				a.next_product = now + float(spec.days) * 1440.0
				continue
			if now < a.next_product:
				continue
			a.next_product = now + float(spec.days) * 1440.0
			made[spec.item] = int(made.get(spec.item, 0)) + int(spec.qty)
		var stock: Dictionary = pen.products
		for item in made:
			var before := int(stock.get(item, 0))
			stock[item] = mini(int(cfg().product_cap), before + int(made[item]))
			w.stat("farm_made_" + item, float(int(stock[item]) - before))


## What waits in a pen, as {item: n}.
func products_in(pen: Dictionary) -> Dictionary:
	var out := {}
	for id in pen.get("products", {}):
		if int(pen.products[id]) > 0:
			out[id] = int(pen.products[id])
	return out


## Take what waits in a player's pen into the pack, as much as fits. Returns {item: n} taken.
func collect(pen: Dictionary, p: PlayerState) -> Dictionary:
	var got := {}
	if not pen.get("player", false):
		return got                       # a keeper's pen: its eggs, milk and wool are the keeper's (Build 13)
	for id in products_in(pen):
		var n := 0
		for i in int(pen.products[id]):
			if p.inv.add(id, 1):
				n += 1
			else:
				break
		if n > 0:
			pen.products[id] = int(pen.products[id]) - n
			got[id] = n
			w.stat("made_" + id, float(n))           # a pen's products become goods when collected
	return got


# ---------------------------------------------------------------- seeds ----------------------
## Whether `n` deals in seed: the farmers, and the food stall's merchant.
func sells_seed(n: NPC) -> bool:
	return n.alive and (n.job == "farmer" or (n.job == "merchant" and str(w.stalls.get(n.workplace, {}).get("kind", "")) == "food"))


static func is_seed(id: String) -> bool:
	for c in crops().values():
		if str(c.seed) == id:
			return true
	return false


static func seed_cfg() -> Dictionary:
	return GameData.b("farming")


## The crops a villager sells seed for: those they hold seed of (Build 13: seed is real stock).
func seed_offers(n: NPC) -> Array:
	if not sells_seed(n):
		return []
	return crops().keys().filter(func(c): return n.inv.has(str(crops()[c].seed)))


# ---------------------------------------------------------------- the manor's fields, shared model (FSE-12) -----
## FSE-12, FARM-06 (owner, 2026-10-21: behind a test switch, compared before activation): with balance
## `shared_manor_farming` 1, the manor's fields follow the player's per-cell rules: sowing takes one seed a cell (the
## crop's seed, from the field's farmers' packs, then their households' pantries; as many cells as there is seed), each
## sown cell yields the crop's `yield` and gives back `seeds_back` seed to the cutter, and the work takes the player's
## time a cell (sowing, cutting, ploughing). Off (0), the old field model: a field yields field_yield, sown without seed.
static func shared_manor() -> bool:
	return int(GameData.b("shared_manor_farming")) == 1


## FSE-13 (owner, 2026-10-21: comparison first, then owner review): with balance `seasonal_village_farming` 1, the
## manor's fields follow the player's seasons: sown only in `sow_seasons`, growing an hour's share at `season_rate`
## (none in winter). Off (0), the old model: a field ripens field_grow_seasons after sowing whatever the season.
static func seasonal_fields() -> bool:
	return int(GameData.b("seasonal_village_farming")) == 1


static func field_cells(f: Dictionary) -> int:
	return int(f.w) * int(f.h)


## Game minutes a villager spends on `cells` cells of a manor field: sowing ("sow") or cutting and ploughing ("cut").
func field_work_minutes(cells: int, what: String) -> float:
	var gmps := float(GameData.b("game_minutes_per_second"))
	var per := float(cfg().sow_seconds) if what == "sow" else float(cfg().harvest_seconds) + float(cfg().till.plough.seconds)
	return maxf(15.0, per * gmps * cells)


## The seed the farmers of field `f` can sow it with now: their packs, then their households' pantries.
func field_seed(f: Dictionary) -> int:
	var seed := str(crops().wheat.seed)
	var n := 0
	for o: NPC in w.field_workers(f):
		n += o.inv.count(seed)
		if o.household >= 0 and o.household < w.households.size():
			n += (w.households[o.household].pantry as Inventory).count(seed)
	return n


## Sow field `f` (shared model): take one seed a cell, the sower's own first; the field's crop is what the sown cells
## will yield. Returns the cells sown (0: no seed).
func sow_field(n: NPC, f: Dictionary) -> int:
	var seed := str(crops().wheat.seed)
	var want := field_cells(f)
	var stores: Array = [n.inv]
	if n.household >= 0 and n.household < w.households.size():
		stores.append(w.households[n.household].pantry)
	for o: NPC in w.field_workers(f):
		if o != n:
			stores.append(o.inv)
			if o.household >= 0 and o.household < w.households.size() and not stores.has(w.households[o.household].pantry):
				stores.append(w.households[o.household].pantry)
	var sown := 0
	for inv: Inventory in stores:
		var k := mini(want - sown, inv.count(seed))
		if k > 0:
			inv.remove(seed, k)
			sown += k
	if sown > 0:
		w.stat("used_" + seed, float(sown))
		f.sown = sown
		f.crop = sown * int(crops().wheat.yield)
	return sown


## A cutter of a field sown under the shared model gets back `seeds_back` seed a sown cell (the player's rule).
func seed_back(n: NPC, f: Dictionary) -> void:
	var back := int(f.get("sown", 0)) * int(crops().wheat.seeds_back)
	if back > 0:
		n.inv.add(str(crops().wheat.seed), back)
		w.stat("made_" + str(crops().wheat.seed), float(back))
	f.sown = 0


## A farmer cutting a field keeps seed_keep of the crop back as wheat seed, up to seed_cap (seed saving);
## the rest of `wheat` is theirs as grain. Returns the grain left to add.
func save_seed(n: NPC, wheat: int) -> int:
	if n.job != "farmer" or wheat <= 0:
		return wheat
	var room := maxi(0, int(seed_cfg().seed_cap) - n.inv.count("wheat_seed"))
	var keep := mini(mini(int(seed_cfg().seed_keep), room), wheat)
	if keep > 0:
		n.inv.add("wheat_seed", keep)
		w.stat("farm_seed_saved", float(keep))
	return wheat - keep


func seed_price(crop: String) -> int:
	return seed_item_price(str(crops()[crop].seed), w.player)


## The planting material a seed seller deals in besides crop seed (MERCH-01): berry cuttings and wild flower seed
## (balance.json propagation.kinds), in a fixed order.
static func propagule_items() -> Array:
	var out := []
	var kinds: Dictionary = GameData.b("propagation").kinds
	var ks := kinds.keys()
	ks.sort()
	for k in ks:
		out.append(str(kinds[k].item))
	return out


## The cuttings and flower seed `n` sells: those a seed seller holds (real stock: the caravan's or bought from
## households, never made from nothing).
func propagule_offers(n: NPC) -> Array:
	if not sells_seed(n):
		return []
	return propagule_items().filter(func(id): return n.inv.has(id))


## The price of one seed, cutting or flower seed to `buyer` (the player or a villager alike, MERCH-01): the crop's
## seed_price or the kind's propagation price, less the buyer's Trading price_bonus (what the player always paid).
func seed_item_price(item: String, buyer) -> int:
	var base := 0.0
	var crop := crop_of_seed(item)
	if crop != "":
		base = float(crops()[crop].seed_price)
	else:
		base = float(World.propagation_cfg(World.propagates(item)).get("price", GameData.value(item)))
	return maxi(1, roundi(base * (1.0 - Skills.value(buyer, "trading", "price_bonus"))))


## Buy `qty` seeds of a crop from a villager's own stock; the coins are the villager's. "" when done.
func buy_seed(n: NPC, crop: String, qty: int, p: PlayerState) -> String:
	if not seed_offers(n).has(crop) or qty < 1:
		return "They have no seed of that."
	return buy_seed_item(n, str(crops()[crop].seed), qty, p)


## MERCH-01: `buyer` (the player or a villager: the same rule) buys `qty` of a seed seller's seed, cuttings or flower
## seed from the seller's own stock, at seed_item_price; the coins go to the seller (World.trade). "" when done.
func buy_seed_item(n: NPC, item: String, qty: int, buyer) -> String:
	if not sells_seed(n) or qty < 1 or not (is_seed(item) or propagule_items().has(item)):
		return "They have no seed of that."
	if not n.inv.has(item, qty):
		return "They have only %d." % n.inv.count(item)
	var price := seed_item_price(item, buyer)
	if int(buyer.coins) < price * qty:
		return "You need %d coins." % (price * qty)
	if not buyer.inv.can_add(item):
		return "Your pack is full."
	if not w.trade(buyer, n, item, qty, price):
		return "The trade fell through."
	w.stat("farm_seed_bought", float(qty))
	if buyer is NPC:
		w.stat("villager_seed_bought_" + item, float(qty))
	return ""


# ---------------------------------------------------------------- targets and actions --------
## The farm actions on offer for the cell in front of the player: [{kind: "farm", act, cell, label, id, low}]
## (act: harvest, sow, clear_tree, clear_plant, till; `low` ones are the last choice unless the plough is in hand,
## so Use still builds and talks as before).
func targets_at(c: Vector2i, p: PlayerState, exact := true) -> Array:
	var out := []
	if cells.has(c):
		var cell: Dictionary = cells[c]
		match str(cell.state):
			"ripe":
				var cr: Dictionary = crops()[cell.crop]
				out.append(_t("harvest", c, "Harvest %s (%d, and seed)" % [str(cr.name).to_lower(), int(cr.yield)]))
			"growing":
				var d := days_left(c)
				out.append({"kind": "info", "id": "grow:%d,%d" % [c.x, c.y], "text": "", "label": "%s growing: %s" % [crops()[cell.crop].name, ("ripe in about %.1f days" % d) if d != INF else "it will not grow in winter"]})
				out.back().text = out.back().label
			"tilled":
				var any := false
				for id in crops():
					var seed := str(crops()[id].seed)
					if p.inv.has(seed):
						any = true
						out.append(_t("sow", c, "Sow %s (%d %s)" % [str(crops()[id].name).to_lower(), p.inv.count(seed), GameData.item_name(seed).to_lower()], {"crop": id}))
				if not any:
					out.append({"kind": "info", "id": "tilled:%d,%d" % [c.x, c.y], "text": "Tilled soil. Seeds are sold by the farmers and the food stall's merchant.", "label": "Tilled soil: bring seed to sow it"})
		return out
	if land_refusal(c) != "":
		return out
	var o := obstacle(c)
	if not o.is_empty():
		if o.kind == "tree" and str(o.ref.state) != "grown":
			var t: Dictionary = o.ref
			var no := clear_tree_refusal(t, p)
			out.append(_t("clear_tree", c, ("Dig out the stump" if str(t.state) == "stump" else "Clear the %s" % Trees.describe(str(t.state)).to_lower().trim_prefix("a ")) if no == "" else no.trim_suffix("."), {"tree": t}))
		elif o.kind == "plant":
			out.append(_t("clear_plant", c, "Grub up the wild plant", {"plant": o.ref}))
		return out
	if exact:
		var cost := till_cost(p)
		out.append(_t("till", c, "Till the ground (%s, %.0f stamina)" % ["with the plough" if p.tool_of("plough") != "" else "by hand: slow", float(cost.stamina)], {"low": true}))
	return out


func _t(act: String, c: Vector2i, label: String, extra := {}) -> Dictionary:
	var t := {"kind": "farm", "act": act, "cell": c, "label": label, "id": "%s:%d,%d:%s" % [act, c.x, c.y, extra.get("crop", "")]}
	t.merge(extra)
	return t


## A farm target as a timed action: {ok, why, label, secs, anim, tool, run: Callable -> {items: {id: n}, text}}.
## main.gd runs `run` when the action's time is up; the tests call it at once.
func plan(t: Dictionary, p: PlayerState) -> Dictionary:
	var c: Vector2i = t.cell
	var bad := func(text: String) -> Dictionary: return {"ok": false, "why": text}
	match str(t.act):
		"till":
			var no := till_refusal(c, p)
			if no != "":
				return bad.call(no)
			var plough := p.tool_of("plough")
			return {"ok": true, "label": "Ploughing" if plough != "" else "Digging", "secs": float(till_cost(p).seconds), "anim": "swing" if plough != "" else "gather",
					"tool": plough, "run": func() -> Dictionary: return {"items": {}, "text": till(c, p)}}
		"sow":
			var no := sow_refusal(c, str(t.crop), p)
			if no != "":
				return bad.call(no)
			return {"ok": true, "label": "Sowing", "secs": float(cfg().sow_seconds), "anim": "gather", "tool": "",
					"run": func() -> Dictionary: return {"items": {}, "text": sow(c, str(t.crop), p)}}
		"harvest":
			for id in harvest_goods(c):
				if not p.inv.can_add(id):
					return bad.call("Your pack is full.")
			return {"ok": true, "label": "Harvesting", "secs": float(cfg().harvest_seconds), "anim": "gather", "tool": "",
					"run": func() -> Dictionary: return {"items": harvest(c, p), "text": ""}}
		"clear_tree":
			var tr: Dictionary = t.tree
			var no := clear_tree_refusal(tr, p)
			if no != "":
				return bad.call(no)
			var axe := p.tool_of("axe")
			return {"ok": true, "label": "Digging out", "secs": clear_seconds(tr), "anim": "swing" if axe != "" else "gather", "tool": axe,
					"run": func() -> Dictionary: return {"items": {}, "text": clear_tree(tr, p)}}
		"clear_plant":
			var pl: Dictionary = t.plant
			return {"ok": true, "label": "Grubbing up", "secs": float(cfg().clear.bush_seconds), "anim": "gather", "tool": "",
					"run": func() -> Dictionary: return {"items": {}, "text": clear_plant(pl)}}
	return bad.call("Nothing to do.")


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	var cs := []
	var keys := cells.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for c: Vector2i in keys:
		var cell: Dictionary = cells[c]
		cs.append([c.x, c.y, cell.crop, cell.state, cell.progress])
	return {"cells": cs, "next_pen": next_pen}


## Fauna.load_dict has put the player's pens back already; their fences are solid again here.
func load_dict(d: Dictionary) -> void:
	cells.clear()
	for e in d.get("cells", []):
		cells[Vector2i(int(e[0]), int(e[1]))] = {"crop": str(e[2]), "state": str(e[3]), "progress": float(e[4])}
	next_pen = int(d.get("next_pen", 0))
	for pen in player_pens():
		_fence_solid(pen)
