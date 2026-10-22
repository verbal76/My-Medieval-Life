class_name FarmPlots
extends RefCounted
## Family farmland (FARM-01..05, FARM-07, FARM-09, FSE-14/15; owner Q9 and Q11, 2026-10-21,
## docs/directives/2026-10-21_build16_master_completion_directive.md section 4): any household, the player's
## or a villager's, takes a rectangle of ground of any size from the manor, leased or bought, and develops it
## by the same rules: clear it, fence it with a gate, plough, sow real seed, tend, harvest.
##
## Land: a farm plot is an ordinary land-office parcel (Property.claim) marked `farm: {gate: [x, y], fence:
## bool}`, so ownership, the weekly lease, arrears, eviction, escheat and the land office's lists are the
## existing ones (Property). Prices are the existing ones, no new coefficient: bought at Property.land_price
## (plot_price by area), leased at weekly_rent_share of that a week (Property.rent_of; first week at once).
## A 16 to 30 cell plot leases at 2 coins, the approved FARM-07 baseline; bought land pays no rent.
## Clearing: nothing is grubbed up for free (Property.claim grub false); the holder clears by the farming
## actions (Farming for the player, clear() here for villagers, the player's rules: an axe for a stump).
## Fence: the player pen's rule (Farming.fence_cells, pen_planks: a plank per 3 fence cells, the gate free)
## plus farm_plot.gate_stone stone for the gate (the one provisional number, awaiting the owner), from real
## inventory; the fence is solid but for the gate, which opens onto ground reachable from the village.
## Fields: the player's cells are Farming.cells, as on any ground they hold; a villager household's are
## `cells` here, with Farming's rules and numbers (one seed a cell, the season's growth, yield, seed back, the
## work's seconds), and the harvest goes into the household's pantry (its family chest, FSE-18).
## Work (FARM-04): any able member (an adult; an elder for the light work: sowing, harvesting, pulling up
## plants and saplings), in the time their day leaves (an adult after work or when out of work, an elder by
## day), at the player's time a cell, faster with a plough in the pack or the chest. No farming skill exists.
## Uptake (FARM-05): daily(): a household weighs its food (days of food below household_savings_days, or a
## living it cannot sustain), able hands, its coins above its necessity reserve (World.necessity), the
## season (sowing possible), and free ground near home; the plot's size is its land requirement (FSE-15).

const LIGHT := ["harvest", "sow", "clear"]          # tasks an elder takes on (clear: plants and saplings only)
const BATCH_MINUTES := 60.0                          # a work step covers at most this many game minutes of cells (pacing only)

var w
var cells := {}        # Vector2i -> {crop, state: tilled | growing | ripe, progress, plot}: villager households' field cells
var busy := {}         # Vector2i -> game minute until which a member is on the way to work it (not saved)
var tried := {}        # "npc id:item" -> the day a member last went to buy it for the plot (once a day; not saved)
var why := ""          # why the last claim() failed


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("farm_plot")


# ---------------------------------------------------------------- plots ----------------------
static func is_farm(p: Dictionary) -> bool:
	return p.has("farm")


static func rect_of(p: Dictionary) -> Rect2i:
	return Rect2i(int(p.x), int(p.y), int(p.w), int(p.h))


## The rectangle with `a` and `b` as opposite corners (both cells included), as a drag marks it.
static func rect_between(a: Vector2i, b: Vector2i) -> Rect2i:
	var lo := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	return Rect2i(lo, Vector2i(absi(a.x - b.x) + 1, absi(a.y - b.y) + 1))


func gate_of(p: Dictionary) -> Vector2i:
	var g: Array = p.farm.get("gate", [-1, -1])
	return Vector2i(int(g[0]), int(g[1]))


## Every farm plot, by registry order.
func plots() -> Array:
	return w.plots.filter(func(p): return is_farm(p))


func plots_of(ref: String) -> Array:
	return plots().filter(func(p): return w.holds(ref, p))


## The farm plot a cell lies in ({} if none).
func plot_at(c: Vector2i) -> Dictionary:
	for p in plots():
		if rect_of(p).has_point(c):
			return p
	return {}


func on_fence_line(p: Dictionary, c: Vector2i) -> bool:
	var r := rect_of(p)
	return r.has_point(c) and not r.grow(-1).has_point(c)


# ---------------------------------------------------------------- prices (Q11) ---------------
## {price, rent}: what the manor asks for this ground, bought outright or leased a week: Property's land price
## by area and its weekly rent rule (Property.rent_of of bare ground), the house plot's prices scaled by area.
func terms(rect: Rect2i) -> Dictionary:
	var price: int = w.property.land_price(rect.size.x, rect.size.y)
	return {"price": price, "rent": maxi(1, ceili(price * float(GameData.b("weekly_rent_share"))))}


# ---------------------------------------------------------------- where (Q11) ----------------
## The gate of a plot on this ground: the middle of a side (top, bottom, left, right, in that order) whose
## outside cell is open and reachable from the village (the door rule buildings follow,
## Construction.can_place); (-1, -1) when no side qualifies.
func gate_for(rect: Rect2i) -> Vector2i:
	var mid := rect.position + rect.size / 2
	var sides := [[Vector2i(mid.x, rect.position.y), Vector2i.UP], [Vector2i(mid.x, rect.end.y - 1), Vector2i.DOWN],
		[Vector2i(rect.position.x, mid.y), Vector2i.LEFT], [Vector2i(rect.end.x - 1, mid.y), Vector2i.RIGHT]]
	var sp = w.map.data.spawns.player
	var home := Vector2i(int(sp[0]), int(sp[1]))
	if w.map.is_solid(home):
		home = w.map.nearest_walkable(home)
	for s in sides:
		var out: Vector2i = s[0] + s[1]
		if not w.map.in_village(out) or w.map.is_solid(out) or rect.has_point(out):
			continue
		var path: PackedVector2Array = w.map.find_path(out, home)
		if not path.is_empty() and Vector2i(path[path.size() - 1]) == home:
			return s[0]
	return Vector2i(-1, -1)


## Why farmland cannot be marked out on this rectangle, "" if it can: at least 3x3 (a fence round one cell),
## the land office's check (Property.can_claim: inside the village, nobody's land, no building, field, pen,
## stall, station, container, seam, grown tree, road or solid ground), no building's door step or the way out of
## the village inside it, and a gate that opens onto reachable ground.
func refusal(rect: Rect2i) -> String:
	if rect.size.x < 3 or rect.size.y < 3:
		return "too small: at least 3x3 (a fence round one cell)"
	var no: String = w.property.can_claim(rect)
	if no != "":
		return no
	for b in w.property.records():
		if Rect2i(int(b.x), int(b.y), int(b.w), int(b.h) + 1).intersects(rect):
			return "the way to %s" % w.property.describe(b)
	for c: Vector2i in w._exit_cells():
		if rect.has_point(c):
			return "the way out of the village"
	if gate_for(rect).x < 0:
		return "nobody could reach a gate"
	return ""


## The rectangle's refusal for `ref` taking it on these terms: the ground's, then the money (Q11: insufficient
## funds prevent the deal).
func deal_refusal(rect: Rect2i, ref: String, lease: bool) -> String:
	var no := refusal(rect)
	if no != "":
		return no
	var t := terms(rect)
	var cost := int(t.rent) if lease else int(t.price)
	if w.property.purse(ref) < cost:
		return ("you need %d coins" % cost) if ref == World.PLAYER else "they cannot pay %d coins" % cost
	return ""


## Mark out farmland and lease or buy it from the manor (Property.claim: the first week's rent, or the price, goes
## to the treasury at once). Nothing on it is cleared for free. Returns the parcel, or {} with the reason in `why`.
func claim(rect: Rect2i, ref: String, lease: bool) -> Dictionary:
	why = deal_refusal(rect, ref, lease)
	if why != "":
		return {}
	var g := gate_for(rect)
	var p: Dictionary = w.property.claim(rect, ref, lease, false, {"farm": {"gate": [g.x, g.y], "fence": false}})
	if p.is_empty():
		why = w.property.why
		return {}
	w.stat("farm_plot_leased" if lease else "farm_plot_bought")
	w.stat("farm_plot_cells", float(rect.size.x * rect.size.y))
	return p


# ---------------------------------------------------------------- the fence and gate (Q9, FARM-02) --
## What fencing this plot takes: the pen rule on its perimeter (planks) and the gate's stone.
func fence_cost(p: Dictionary) -> Dictionary:
	return {"plank": w.farm.pen_planks(rect_of(p)), "stone": int(cfg().gate_stone)}


static func have(stores: Array, id: String) -> int:
	var n := 0
	for inv: Inventory in stores:
		n += inv.count(id)
	return n


## Why `ref` cannot fence the plot now with what `stores` hold, "" if they can: theirs, not fenced yet, every
## fence cell cleared and unfarmed, the materials in hand.
func fence_refusal(p: Dictionary, ref: String, stores: Array) -> String:
	if not is_farm(p):
		return "That is not farmland."
	if not w.holds(ref, p):
		return "That is not your land."
	if bool(p.farm.get("fence", false)):
		return "It is fenced already."
	for c: Vector2i in w.farm.fence_cells(rect_of(p)):
		var o: Dictionary = w.farm.obstacle(c)
		if not o.is_empty():
			return "Clear %s on the fence line first." % w.farm.obstacle_name(o)
		if cells.has(c) or w.farm.cells.has(c):
			return "The field is in the way of the fence."
	var cost := fence_cost(p)
	for id in cost:
		if have(stores, id) < int(cost[id]):
			return "The fence and gate need %d planks and %d stone." % [int(cost.plank), int(cost.stone)]
	return ""


## Put up the fence and gate: the materials are taken from `stores` in order and used up (counted as used_, the
## goods ledger's drain), the fence is solid but for the gate. "" when done.
func build_fence(p: Dictionary, ref: String, stores: Array) -> String:
	var no := fence_refusal(p, ref, stores)
	if no != "":
		return no
	var cost := fence_cost(p)
	for id in cost:
		var left := int(cost[id])
		for inv: Inventory in stores:
			var k := mini(left, inv.count(id))
			inv.remove(id, k)
			left -= k
		w.stat("used_" + id, float(cost[id]))
		w.stat("farm_fence_" + id, float(cost[id]))
	p.farm.fence = true
	_fence_solid(p)
	_show_fence(p)
	w.note("%s fenced %s." % [w.ref_name(ref, true), w.property.describe(p)])
	return ""


func _fence_solid(p: Dictionary) -> void:
	var g := gate_of(p)
	for c: Vector2i in w.farm.fence_cells(rect_of(p)):
		w.map.set_solid(c, c != g)


func _show_fence(p: Dictionary) -> void:
	var r := rect_of(p)
	var g := gate_of(p)
	for c: Vector2i in w.farm.fence_cells(r):
		var i := c.x - r.position.x
		var j := c.y - r.position.y
		var edge: String = {Vector2i(0, 0): "tl", Vector2i(r.size.x - 1, 0): "tr", Vector2i(0, r.size.y - 1): "bl", Vector2i(r.size.x - 1, r.size.y - 1): "br"}.get(Vector2i(i, j), "")
		if edge == "":
			edge = "t" if j == 0 else ("b" if j == r.size.y - 1 else ("l" if i == 0 else "r"))
		w.tile_changed.emit(c, "below5", Farming.COZY + (Farming.GATE_TILE if c == g else int(Farming.FENCE[edge])))


## Farming.till_refusal's farmland rule (FARM-02, the player's and the villagers' alike): on farmland, only
## inside a fence that stands. "" where the rule does not apply.
func till_block(c: Vector2i) -> String:
	var p := plot_at(c)
	if p.is_empty():
		return ""
	if not bool(p.farm.get("fence", false)):
		return "Put up the farmland's fence and gate first."
	if on_fence_line(p, c):
		return "That is the fence line."
	return ""


# ---------------------------------------------------------------- the households' fields (FARM-03) --
static func fcfg() -> Dictionary:
	return Farming.cfg()


## The game minutes one cell of `task` takes (the player's seconds at the game's clock), `plough` in hand or not.
func task_minutes(task: String, plough: bool, c := Vector2i(-1, -1)) -> float:
	var secs := 0.0
	match task:
		"harvest":
			secs = float(fcfg().harvest_seconds)
		"sow":
			secs = float(fcfg().sow_seconds)
		"till":
			secs = float(fcfg().till.plough.seconds if plough else fcfg().till.hand.seconds)
		"clear":
			var o: Dictionary = w.farm.obstacle(c)
			secs = w.farm.clear_seconds(o.ref) if not o.is_empty() and o.kind == "tree" else float(fcfg().clear.bush_seconds)
	return maxf(1.0, secs * float(GameData.b("game_minutes_per_second")))


## A plough a store holds (the best, as PlayerState.tool_of picks), "" if none.
static func plough_in(inv: Inventory) -> String:
	var best := ""
	for id in inv.ids():
		if GameData.item(id).get("tool", "") == "plough" and (best == "" or float(GameData.item(id).get("speed", 1.0)) > float(GameData.item(best).get("speed", 1.0))):
			best = id
	return best


func _pantry(n: NPC) -> Inventory:
	return w.households[n.household].pantry if n.household >= 0 and n.household < w.households.size() else Inventory.new()


## Why a villager cannot till this cell of their household's plot, "" if they can.
func till_refusal(p: Dictionary, c: Vector2i) -> String:
	var no := till_block(c)
	if no != "":
		return no
	if not rect_of(p).has_point(c):
		return "Not on the plot."
	if cells.has(c) or w.farm.cells.has(c):
		return "Already tilled."
	var o: Dictionary = w.farm.obstacle(c)
	if not o.is_empty():
		return "Clear %s first." % w.farm.obstacle_name(o)
	return ""


func till(p: Dictionary, c: Vector2i, n: NPC) -> String:
	var no := till_refusal(p, c)
	if no != "":
		return no
	for inv: Inventory in [n.inv, _pantry(n)]:
		var pl := plough_in(inv)
		if pl != "":
			if inv.wear(pl, 1):
				w.stat("broke_" + pl)
			break
	cells[c] = {"crop": "", "state": "tilled", "progress": 0.0, "plot": str(p.id)}
	w.stat("farm_tilled")
	w.stat("farm_plot_tilled")
	_show_around(c)
	return ""


## Sow a tilled cell with one seed from `stores` (the worker's pack, then the pantry): the player's rule.
func sow(c: Vector2i, crop: String, stores: Array) -> String:
	if not cells.has(c) or str(cells[c].state) != "tilled":
		return "Only tilled, empty soil can be sown."
	if not w.farm.can_sow_now():
		return "Nothing sown now will grow."
	var seed := str(Farming.crops()[crop].seed)
	for inv: Inventory in stores:
		if inv.remove(seed, 1):
			w.stat("used_" + seed)
			cells[c].crop = crop
			cells[c].state = "growing"
			cells[c].progress = 0.0
			w.stat("farm_sown_" + crop)
			w.stat("farm_plot_sown")
			_show_around(c)
			return ""
	return "No %s." % GameData.item_name(seed).to_lower()


## What a ripe cell gives, as Farming.harvest_goods: the crop's yield (the shared per-cell yield) and its seed back.
func harvest_goods(c: Vector2i) -> Dictionary:
	var cell: Dictionary = cells.get(c, {})
	if cell.is_empty() or cell.state != "ripe":
		return {}
	var cr: Dictionary = Farming.crops()[cell.crop]
	var out := {str(cr.item): w.farm.cell_yield(str(cell.crop), c)}
	if int(cr.seeds_back) > 0:
		out[str(cr.seed)] = int(cr.seeds_back)
	return out


## Harvest a ripe cell into `into` (the household's pantry); the cell is tilled and empty again.
func harvest(c: Vector2i, into: Inventory) -> Dictionary:
	var out := harvest_goods(c)
	if out.is_empty():
		return {}
	if not into.can_add_all(out):
		return {}
	for id in out:
		into.add(id, int(out[id]))
		w.stat("farm_harvest_" + id, float(out[id]))
		w.stat("farm_plot_harvest_" + id, float(out[id]))
	cells[c] = {"crop": "", "state": "tilled", "progress": 0.0, "plot": str(cells[c].plot)}
	_show(c)
	return out


## Clear what stands on a cell of the plot by the player's rules (Farming.clear_tree_refusal): a plant or a
## sapling or young tree by hand, a stump or a growing tree with an axe (the worker's or the household's); a
## grown tree or a boulder is not cleared here. "" when done.
func clear(p: Dictionary, c: Vector2i, n: NPC) -> String:
	if not rect_of(p).has_point(c):
		return "Not on the plot."
	var o: Dictionary = w.farm.obstacle(c)
	if o.is_empty():
		return "Nothing to clear."
	match str(o.kind):
		"plant":
			o.ref.state = "cleared"
			w.tile_changed.emit(c, World.PLANT_LAYER, -1)
			w.stat("farm_cleared_plant")
			return ""
		"tree":
			var t: Dictionary = o.ref
			if str(t.state) == "grown":
				return "A grown tree is felled first."
			if str(t.state) in ["stump", "growing"] and not (n.inv.has("axe") or _pantry(n).has("axe")):
				return "Digging out a stump needs an axe."
			t.state = "cleared"
			w.map.set_solid(c, false)
			w.tree_changed.emit(t)
			w.stat("farm_cleared_tree")
			return ""
	return "That cannot be cleared by hand."


## Every game hour the households' sown cells grow by Farming's rule (the season's rate, the crop's days).
func hour() -> void:
	if cells.is_empty():
		return
	var rate: float = w.farm.season_rate()
	if rate <= 0.0:
		return
	for c: Vector2i in cells:
		var cell: Dictionary = cells[c]
		if cell.state != "growing":
			continue
		cell.progress = float(cell.progress) + rate / (Farming.crop_days(str(cell.crop)) * 24.0)
		if float(cell.progress) >= 0.999999:
			cell.progress = 1.0
			cell.state = "ripe"
			_show(c)


# ---------------------------------------------------------------- household work (FARM-04) -------
## Whether `n` can work the family plot now: alive, an adult or an elder, not badly hurt (rest.seek_below).
func able(n: NPC) -> bool:
	return n.alive and n.household >= 0 and n.role in ["adult", "elder"] and n.hp >= n.max_hp * float(GameData.b("rest").seek_below)


## The next piece of work on the household's plots for `n`, planned into n.plan. True when planned. Called by
## NPCBrain in the time a member's day leaves (an adult's evening or a day out of work, an elder's day).
func plan_work(n: NPC) -> bool:
	if not able(n):
		return false
	var ref := World.hh_ref(n.household)
	var light := n.role != "adult"
	for p in plots_of(ref):
		if _plan_on(n, p, light):
			return true
	return false


func _free(c: Vector2i) -> bool:
	return float(busy.get(c, -1.0)) < float(w.minutes)


func _sorted(cs: Array) -> Array:
	cs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return cs


func _plan_on(n: NPC, p: Dictionary, light: bool) -> bool:
	var r := rect_of(p)
	var inner := r.grow(-1)
	var pantry := _pantry(n)
	# 1. harvest what is ripe
	var ripe := []
	var empty := []
	for c: Vector2i in cells:
		if str(cells[c].plot) == str(p.id) and _free(c):
			if cells[c].state == "ripe":
				ripe.append(c)
			elif cells[c].state == "tilled":
				empty.append(c)
	if not ripe.is_empty():
		return _batch(n, p, "harvest", _sorted(ripe), false)
	# 2. sow tilled soil in the sowing seasons, with seed held or bought
	if not empty.is_empty() and w.farm.can_sow_now():
		var crop := _seed_crop([n.inv, pantry])
		if crop != "":
			return _batch(n, p, "sow", _sorted(empty), false, crop)
		if _plan_buy_seed(n, empty.size()):
			return true
	# 3. clear the ground (light: plants and saplings only)
	var obst := []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			var o: Dictionary = w.farm.obstacle(c)
			if o.is_empty() or not _free(c):
				continue
			if o.kind == "plant" or (o.kind == "tree" and str(o.ref.state) in ["sapling", "young"]):
				obst.append(c)
			elif not light and o.kind == "tree" and str(o.ref.state) in ["stump", "growing"] and (n.inv.has("axe") or pantry.has("axe")):
				obst.append(c)
	if not obst.is_empty():
		return _batch(n, p, "clear", obst, false)
	if light:
		return false
	# 4. the fence and gate, with materials in hand or bought
	if not bool(p.farm.get("fence", false)):
		var ref := World.hh_ref(n.household)
		var no := fence_refusal(p, ref, [n.inv, pantry])
		if no == "":
			n.doing = "fencing the family's farmland"
			var g := gate_of(p)
			n.plan = [w.brain.go(w.brain.beside(g, n.cell())), w.brain.work(15.0, "fp_fence", {"plot": str(p.id)}, "work", g)]
			return true
		if no.begins_with("The fence and gate need"):
			return _plan_buy_materials(n, p)
		return false
	# 5. plough the cleared ground inside the fence
	var open := []
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			var c := Vector2i(x, y)
			if _free(c) and till_refusal(p, c) == "":
				open.append(c)
	if not open.is_empty():
		return _batch(n, p, "till", open, plough_in(n.inv) != "" or plough_in(pantry) != "")
	return false


## Plan a work step on as many cells as BATCH_MINUTES allows (at least one), the cells kept for `n` meanwhile.
func _batch(n: NPC, p: Dictionary, task: String, cs: Array, plough: bool, crop := "") -> bool:
	var take := []
	var mins := 0.0
	for c: Vector2i in cs:
		var m := task_minutes(task, plough, c)
		if not take.is_empty() and mins + m > BATCH_MINUTES:
			break
		take.append(c)
		mins += m
	for c: Vector2i in take:
		busy[c] = w.minutes + mins + 180.0
	var first: Vector2i = take[0]
	var stand: Vector2i = first if not w.map.is_solid(first) else w.brain.beside(first, n.cell())
	n.doing = {"harvest": "harvesting the family's plot", "sow": "sowing the family's plot", "clear": "clearing the family's farmland",
		"till": "ploughing the family's plot"}[task]
	# X18 HOOK (Expansion 18, X18-CAPNUM farming F1): off in the game (exactly `mins`); in analysis, faster tilling, sowing and
	# cutting only: the cells, seed and crop are the same, never more yield
	var dur := mins if task == "clear" else CapabilityHook.time(mins, "farming", n)
	n.plan = [w.brain.go(stand), w.brain.work(dur, "fp_work", {"plot": str(p.id), "task": task, "crop": crop,
		"cells": take.map(func(c: Vector2i) -> Array: return [c.x, c.y])}, "work", first)]
	return true


## The crop a household sows from the seed it holds: wheat first, then the others by id; "" with none.
func _seed_crop(stores: Array) -> String:
	var ids: Array = Farming.crops().keys()
	ids.sort()
	ids.erase("wheat")
	ids.push_front("wheat")
	for id in ids:
		if have(stores, str(Farming.crops()[id].seed)) > 0:
			return id
	return ""


## The nearest awake seller of `item` among the villagers (`sells`), with stock beyond what they keep; null if none.
func _seller(n: NPC, item: String, sells: Callable, keep: Callable) -> NPC:
	var best: NPC = null
	var bd := INF
	for o: NPC in w.npcs:
		if o == n or not o.alive or w.asleep(o) or not sells.call(o) or o.inv.count(item) - int(keep.call(o)) <= 0:
			continue
		var d := n.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best


## Seed for `cells` cells from a seed seller (the food stall's merchant, a farmer above the seed they keep), by
## the player's rule (Farming.buy_seed_item through the buy_seed step), only with coins above the reserve.
func _plan_buy_seed(n: NPC, want: int) -> bool:
	var ids: Array = Farming.crops().keys()
	ids.sort()
	ids.erase("wheat")
	ids.push_front("wheat")
	for crop in ids:
		var seed := str(Farming.crops()[crop].seed)
		var v := _seller(n, seed, func(o: NPC) -> bool: return w.farm.sells_seed(o),
			func(o: NPC) -> int: return int(Farming.seed_cfg().seed_keep) if o.job == "farmer" else 0)
		if v == null:
			continue
		var keep := int(Farming.seed_cfg().seed_keep) if v.job == "farmer" else 0
		var qty := mini(want, v.inv.count(seed) - keep)
		var price: int = w.farm.seed_item_price(seed, n)
		while qty > 0 and not w.can_afford(n, price * qty):
			qty -= 1
		if qty <= 0 or not _first_try(n, seed):
			return false
		n.doing = "buying seed for the family's plot"
		n.plan = [w.brain.go(w.brain._workplace_cell(v) if v.job != "farmer" else v.cell()), w.brain.doit("buy_seed", {"vendor": v.id, "item": seed, "qty": qty})]
		return true
	return false


## The fence's missing planks or stone from their sellers (Construction.SELLERS), with coins above the reserve.
func _plan_buy_materials(n: NPC, p: Dictionary) -> bool:
	var cost := fence_cost(p)
	var stores := [n.inv, _pantry(n)]
	for id in ["plank", "stone"]:
		var short := int(cost[id]) - have(stores, id)
		if short <= 0:
			continue
		var v := _seller(n, id, func(o: NPC) -> bool: return w.construction._sells(o, id), func(o: NPC) -> int: return w.construction._keeps(o, id))
		if v == null:
			return false
		var qty := mini(short, v.inv.count(id) - w.construction._keeps(v, id))
		var price: int = w.sell_price(v, id)
		while qty > 0 and not w.can_afford(n, price * qty):
			qty -= 1
		if qty <= 0 or not _first_try(n, id):
			return false
		n.doing = "buying %s for the family's fence" % GameData.item_name(id).to_lower()
		n.plan = [w.brain.go(w.brain._workplace_cell(v) if v.job != "laborer" else v.cell()), w.brain.doit("buy_from", {"vendor": v.id, "item": id, "qty": qty})]
		return true
	return false


## A member goes to buy an item for the plot once a day at most (a sale that falls through is not chased all evening).
func _first_try(n: NPC, item: String) -> bool:
	var key := "%d:%s" % [n.id, item]
	if int(tried.get(key, -1)) == w.day():
		return false
	if tried.size() > 2000:
		tried.clear()
	tried[key] = w.day()
	return true


## A member's farm steps (NPCBrain.act): the work on the cells, re-checked when it is done; the fence.
func act(n: NPC, what: String, a: Dictionary) -> bool:
	var p: Dictionary = w.plot(str(a.get("plot", "")))
	if p.is_empty() or not is_farm(p) or n.household < 0 or not w.holds(World.hh_ref(n.household), p):
		return false
	var pantry := _pantry(n)
	if what == "fp_fence":
		return build_fence(p, World.hh_ref(n.household), [n.inv, pantry]) == ""
	var done := 0
	for e in a.get("cells", []):
		var c := Vector2i(int(e[0]), int(e[1]))
		busy.erase(c)
		var res := "x"
		match str(a.task):
			"harvest":
				res = "" if not harvest(c, pantry).is_empty() else "x"
			"sow":
				res = sow(c, str(a.crop), [n.inv, pantry])
			"till":
				res = till(p, c, n)
			"clear":
				res = clear(p, c, n)
		if res == "":
			done += 1
	return done > 0


# ---------------------------------------------------------------- the households' choice (FARM-05) --
## FSE-15: the field cells a household needs to grow a year's food: its daily need (members weighted by age) over
## a year, against what one cell nets a year: the shared wheat yield (FARM-08) as cooked grain (one valuation,
## NPCBrain.food_points) for each crop the sowing seasons allow at their growth rate (Farming.season_rate over the
## calendar). The seed is not counted against it: a cell gives back its seeds_back, the one seed it was sown with.
## Capped by the household's labour (labour_cells). The game models no crop losses besides the seed.
func land_requirement(h: int) -> int:
	var need: float = w.brain.household_day_food(h) * float(Life.year_days())
	return mini(maxi(1, ceili(need / maxf(0.001, cell_food_per_year()))), labour_cells(h))


## The cells a household's able members can keep sown and harvested, crop after crop: the time their days leave
## (an adult's evening from WORK_END to SLEEP, or the working day when out of work; an elder's working day) over one
## crop's days, at the player's minutes a cell for sowing and harvesting (ploughing is done once). At least 1.
func labour_cells(h: int) -> int:
	var per_cell := task_minutes("sow", false) + task_minutes("harvest", false)
	var day_minutes := 0.0
	for o: NPC in w.brain._members(h):
		if not able(o):
			continue
		if o.role == "adult" and o.job != "":
			day_minutes += (NPCBrain.SLEEP - NPCBrain.WORK_END) * 60.0
		else:
			day_minutes += (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	return maxi(1, floori(day_minutes * Farming.crop_days("wheat") / per_cell))


## Food points one wheat cell nets in a year of the calendar's seasons.
func cell_food_per_year() -> float:
	var crops := 0.0
	var rates: Dictionary = fcfg().season_rate
	for s in GameData.b("calendar").seasons:
		if (fcfg().sow_seasons as Array).has(s):
			crops += float(rates.get(s, 1.0)) * Life.seasons_to_days(1.0) / Farming.crop_days("wheat")
	var seed_net := float(int(Farming.crops().wheat.seeds_back) - 1)
	return crops * (Farming.wheat_yield() + minf(0.0, seed_net)) * NPCBrain.food_points("wheat")


## The smallest plot whose inside holds `k` cells: a fence round a near-square field.
static func plot_size(k: int) -> Vector2i:
	var iw := maxi(1, ceili(sqrt(float(k))))
	var ih := maxi(1, ceili(float(k) / iw))
	return Vector2i(iw + 2, ih + 2)


## What developing a plot of this size will cost a household at today's prices: the fence materials it lacks
## (Construction.estimate) and the seed it lacks for the inside, at the seed sellers' price.
func development_cost(h: int, size: Vector2i) -> int:
	var stores: Array = w.brain.household_stores(h)
	var need := {}
	var fence := {"plank": w.farm.pen_planks(Rect2i(Vector2i.ZERO, size)), "stone": int(cfg().gate_stone)}
	for id in fence:
		var short := int(fence[id]) - have(stores, id)
		if short > 0:
			need[id] = short
	var cost: int = w.construction.estimate(need) if not need.is_empty() else 0
	var seed_short := (size.x - 2) * (size.y - 2) - have(stores, str(Farming.crops().wheat.seed))
	if seed_short > 0:
		cost += seed_short * int(Farming.crops().wheat.seed_price)
	return cost


## Each morning: households weigh taking farmland (FARM-05), a household with no one able to work gives up a lease
## it holds (the land office's end_lease), and the soil of a plot follows its holder (the player's cells are
## Farming's, a household's are here).
func daily() -> void:
	_follow_holders()
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false):
			continue
		var ref := World.hh_ref(h)
		var mine := plots_of(ref)
		if not mine.is_empty():
			if not w.brain._members(h).any(func(o: NPC) -> bool: return able(o)):
				for p in mine:
					if w.tenant_of(p) == ref:
						w.property.end_lease(p, ref)
			continue
		consider(h)


## Whether household `h` takes up farmland today, and on what terms; the plot it took, or {}. Some do, some do not:
## the need (food days under household_savings_days, or a living it cannot sustain), an able adult, a season to sow
## in, free ground near home, and coins above the household's necessity reserve for the first week's rent (or the
## price, when it can buy outright) and the fence and seed it lacks; the size is its land requirement, smaller
## when the money does not reach.
func consider(h: int) -> Dictionary:
	var hh: Dictionary = w.households[h]
	var members: Array = w.brain._members(h)
	if members.is_empty() or str(hh.home) == "" or not w.buildings.has(str(hh.home)):
		return {}
	if not w.farm.can_sow_now():
		return {}
	if not members.any(func(o: NPC) -> bool: return o.role == "adult" and able(o)):
		return {}
	var days: float = w.brain.household_food_days(h)
	var sustainable := bool((hh.get("econ", {}) as Dictionary).get("sustainable", true))
	if days >= float(GameData.b("household_savings_days")) and sustainable:
		return {}
	var ref := World.hh_ref(h)
	var spare: int = w.property.purse(ref) - int(w.necessity(members[0]).need)
	var k := land_requirement(h)
	var size := Vector2i.ZERO
	var lease := true
	while k >= 1:
		var s := plot_size(k)
		var t := terms(Rect2i(Vector2i.ZERO, s))
		var dev := development_cost(h, s)
		if spare >= int(t.price) + dev:
			size = s
			lease = false
			break
		if spare >= int(t.rent) + dev:
			size = s
			break
		k -= 1
	if size == Vector2i.ZERO:
		w.stat("farm_plot_cannot_afford")
		return {}
	var rect := find_ground(size, w.building_door(str(hh.home)), h)
	if rect.size == Vector2i.ZERO:
		w.stat("farm_plot_no_ground")
		return {}
	var p := claim(rect, ref, lease)
	if not p.is_empty():
		w.stat("farm_plot_households")
	return p


## Free ground of this size for a household's plot, nearest `near` first (deterministic: by distance, row,
## column): legal farmland (refusal), no boulder on it, and no stump or growing tree unless the household has an
## axe to dig it out. A zero rectangle when none is found.
func find_ground(size: Vector2i, near: Vector2i, h: int) -> Rect2i:
	var W: int = w.map.w
	var sums: PackedInt32Array = w.construction._free_sums()
	var axe := have(w.brain.household_stores(h), "axe") > 0
	var cands := []
	for y in range(1, w.map.h - size.y):
		for x in range(1, W - size.x):
			var blocked := sums[(y + size.y) * (W + 1) + x + size.x] - sums[y * (W + 1) + x + size.x] - sums[(y + size.y) * (W + 1) + x] + sums[y * (W + 1) + x]
			if blocked == 0:
				cands.append([(Vector2i(x, y) + size / 2 - near).length_squared(), y, x])
	cands.sort()
	var tried := 0
	for cnd in cands:
		var rect := Rect2i(int(cnd[2]), int(cnd[1]), size.x, size.y)
		if not _ground_ok(rect, axe):
			continue
		tried += 1
		if refusal(rect) == "":
			return rect
		if tried >= 400:
			break
	return Rect2i()


func _ground_ok(rect: Rect2i, axe: bool) -> bool:
	for b in w.boulders:
		if rect.has_point(Vector2i(int(b.x), int(b.y))) and int(b.amount) > 0:
			return false
	if not axe:
		for t in w.trees:
			if str(t.state) in ["stump", "growing"] and rect.has_point(Vector2i(int(t.x), int(t.y))):
				return false
	return true


## The soil of a plot follows whoever holds it: a household's cells on a plot the player now holds become the
## player's field cells (Farming.cells), and the player's on a plot a household now holds become the household's.
func _follow_holders() -> void:
	for p in plots():
		var holder: String = w.holder_of(p)
		var r := rect_of(p)
		if holder == World.PLAYER:
			for c: Vector2i in cells.keys():
				if str(cells[c].plot) == str(p.id):
					w.farm.cells[c] = {"crop": cells[c].crop, "state": cells[c].state, "progress": cells[c].progress}
					cells.erase(c)
		elif holder.begins_with("hh:"):
			for c: Vector2i in w.farm.cells.keys():
				if r.has_point(c):
					var e: Dictionary = w.farm.cells[c]
					cells[c] = {"crop": e.crop, "state": e.state, "progress": e.progress, "plot": str(p.id)}
					w.farm.cells.erase(c)


# ---------------------------------------------------------------- drawing --------------------
## The ground tile of a household field cell: Farming's tilled-soil set whatever the cell's state, edged where the
## field ends; the crop is drawn over it by CropView (VIS-CROP-01), so a plot part sown reads as one field.
func tile_for(c: Vector2i) -> int:
	var base: int = w.map.data.tiles.field.tilled
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


func _show_around(c: Vector2i) -> void:
	for dc in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_show(c + dc)


## Draw the households' fields and every farm fence again (a loaded world).
func show_all() -> void:
	for c: Vector2i in cells:
		_show(c)
	for p in plots():
		if bool(p.farm.get("fence", false)):
			_show_fence(p)


# ---------------------------------------------------------------- save -----------------------
## Saved with the World ("farm_plots"); a save without it has no household fields. The plots themselves are
## land-office parcels saved with World.plots (their `farm` record: gate and fence).
func to_dict() -> Dictionary:
	var cs := []
	var keys := cells.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for c: Vector2i in keys:
		var cell: Dictionary = cells[c]
		cs.append([c.x, c.y, cell.crop, cell.state, cell.progress, cell.plot])
	return {"cells": cs}


## World.plots are loaded already: the fences that stand are solid again.
func load_dict(d: Dictionary) -> void:
	cells.clear()
	busy.clear()
	for e in d.get("cells", []):
		cells[Vector2i(int(e[0]), int(e[1]))] = {"crop": str(e[2]), "state": str(e[3]), "progress": float(e[4]), "plot": str(e[5])}
	for p in plots():
		p.farm.gate = [int(p.farm.gate[0]), int(p.farm.gate[1])]
		if bool(p.farm.get("fence", false)):
			_fence_solid(p)
