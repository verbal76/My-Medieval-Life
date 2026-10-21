class_name MineSupply
extends RefCounted
## MIN-EQUIP (owner MIN-F2-Q1, Build 17; docs/build17/MIN_EQUIP_COLLAPSE.md): who makes the underground's equipment, who
## needs it, and how it reaches them, with the systems that already exist. Holds no state of its own (MineWorks.supply):
## orders are World.manor_orders, goods lie in inventories and the manor's works yard, jobs are on ManorWork's board.
##
##  - The makers: the carpenter makes timber supports (sawhorse: a log and two planks), ladders (workbench: planks and
##    the smith's nails), mallets and minecarts (workbench: its own wheels and the smith's axles and ironwork, the
##    handcart's parts chain), each only for a buyer who needs it (made to order, NPCBrain.MADE_TO_ORDER's pattern). The
##    smith's part is the metal: nails (ladders, track sections, ladder repairs), cart axles and ironwork (minecarts),
##    forged as it already does for a buyer. Repair goods are the carpenter's planks and the smith's nails.
##  - The manor's needs (`manor_needs`), weighed each evening by the reeve: a timber support when it would post a tunnel
##    job (its works lack stone and it could pay one) but no face below ground is held by sound timber, and a face
##    could be cut if one were set up; repair goods for each support worn below `supply.repair_at` that holds a cell
##    the works opened; a ladder for each finished shaft whose ladder has rotted or been crushed; and a mallet for its
##    works yard when any of that work is to be done and the yard has none. It buys what a maker or merchant holds, from
##    the treasury above its floor (as NPCBrain._support_trades buys tools), into the works yard; what nobody holds it
##    orders from a carpenter, paying its worth in advance (World.manor_orders, delivered to the yard by
##    NPCBrain._deliver_orders); and it posts "shore" jobs (ManorWork) to set up, repair or set the ladder with the
##    yard's goods and mallet, paid at the job board's own rates.
##  - A miner's household's minecart (`minecart_wanted`): a miner whose seam lies below ground, with track there that
##    would make a minecart's haul cheaper than carrying (MineWorks.haul_costs' rule, as if a cart stood on the rails
##    nearest the seam), and no minecart in the household: the carpenter makes one for them, and the miner buys it with
##    their own coins and sets it down on those rails.
##  - Not done by anyone on their own, because no rule of need calls for it: laying track (a minecart pays only on
##    track and track only with a minecart: no villager makes that outlay; the player lays it), and sinking shafts (they
##    lead only to rock nobody knows holds anything). Replacing a shaft's ladder is a need (the way in is lost).

var w: World

## The recipe that makes each piece of equipment (the carpenter's).
const RECIPE := {"timber_support": "make_timber_support", "ladder": "make_ladder", "mallet": "make_mallet", "minecart": "build_minecart"}


func _init(world: World) -> void:
	w = world


static func cfg() -> Dictionary:
	return MineWorks.cfg().supply


# ---------------------------------------------------------------- the manor's needs ----------
## The manor would post a tunnel job now (ManorWork.post_tunnels' own conditions, short of a sound support).
func tunnel_wanted() -> bool:
	var mwk: ManorWork = w.manor_work
	if mwk._works_stock("stone") >= 2 * int(ManorWork.cfg("mend_load")):
		return false
	return mwk.can_fund({"wage": ManorWork.excavate_wage()}, "")


## A rock face on a level villagers reach whose only want is a support, and the floor cell beside it to set one on:
## {level, face, site}, or {}. The heading's last cell (the works' last opened cell on that level) is followed first;
## otherwise the first by maps in order, cells row by row.
func unsupported_face() -> Dictionary:
	var mw: MineWorks = w.mine_works
	if w.underground == null:
		return {}
	var best := {}
	var bd := 1e9
	for m: LevelMap in w.underground.maps:
		if not w.villager_levels.has(m.level):
			continue
		var last := Vector2i(-1, -1)
		for o in mw.opened:
			if int(o[0]) == m.level:
				last = Vector2i(int(o[1]), int(o[2]))
		for c in m.cells():
			if not m.is_solid(c) or not mw.rock_refusal(m.level, c).begins_with("Set up a timber support"):
				continue
			if not w.underground.hidden_at(m.level, c).is_empty():
				continue                                 # (never chosen by hidden ore: it is simply rock nobody can cut yet)
			var site := _prop_site(m, c)
			if site.x < 0:
				continue
			var d := 0.0 if last.x < 0 else Vector2(c).distance_squared_to(Vector2(last))
			if d < bd:
				bd = d
				best = {"level": m.level, "face": c, "site": site}
				if last.x < 0:
					return best
	return best


## The floor cell beside face `c` a support may stand on: open floor, no support, track, fill or shaft on it, not a
## portal's cell; the first of the four sides in order.
func _prop_site(m: LevelMap, c: Vector2i) -> Vector2i:
	var mw: MineWorks = w.mine_works
	for d: Vector2i in VillageMap.SIDES:
		var s := c + d
		if m.is_solid(s) or mw.support_at(m.level, s) or mw.track_at(m.level, s) or mw.held_at(m.level, s) > 0:
			continue
		if not mw.shaft_at(m.level + 1, s).is_empty() or mw._is_portal_cell(m.level, s):
			continue
		return s
	return Vector2i(-1, -1)


## Supports worn below supply.repair_at (of stability.full) that hold an open cell the works made, on levels villagers
## reach, weakest first: [{level, cell}].
func repairs_wanted() -> Array:
	var mw: MineWorks = w.mine_works
	var at := int(cfg().repair_at)
	var r := int(MineWorks.cfg().support.reach)
	var rows := []
	for s in mw.supports:
		var lv := int(s[0])
		if int(s[3]) >= at or not w.villager_levels.has(lv):
			continue
		var holds := false
		for o in mw.opened:
			if int(o[0]) == lv and maxi(absi(int(o[1]) - int(s[1])), absi(int(o[2]) - int(s[2]))) <= r:
				var lm := mw._map(lv, Vector2i(int(o[1]), int(o[2])))
				if lm != null and not lm.is_solid(Vector2i(int(o[1]), int(o[2]))):
					holds = true
		if holds:
			rows.append([int(s[3]), lv, int(s[1]), int(s[2])])
	rows.sort()
	return rows.map(func(x): return {"level": int(x[1]), "cell": Vector2i(int(x[2]), int(x[3]))})


## Finished shafts whose ladder is gone (rotted or crushed), from a level villagers reach: [{level, cell}].
func ladders_wanted() -> Array:
	var mw: MineWorks = w.mine_works
	var out := []
	for sh in mw.shafts:
		if int(sh.ladder) < 0 and int(sh.rubble) <= 0 and mw.shaft_done(sh) and w.villager_levels.has(int(sh.level)):
			out.append({"level": int(sh.level), "cell": Vector2i(int(sh.x), int(sh.y))})
	return out


## The shore work the manor wants done now: [{mode: prop | repair | ladder, level, cell}] (prop: set a support up on
## `cell` for the face; repair: the support at `cell`; ladder: the shaft whose mouth is `cell`), not yet on the board.
func shore_wanted() -> Array:
	var out := []
	var on_board := func(mode: String, lv: int, c: Vector2i) -> bool:
		return w.manor_work.jobs.any(func(j): return j.kind == "shore" and str(j.mode) == mode and int(j.level) == lv \
				and int(j.site[0]) == c.x and int(j.site[1]) == c.y)
	if tunnel_wanted() and w.mine_works.manor_face().is_empty() and not w.manor_work.jobs.any(func(j): return j.kind == "shore" and str(j.mode) == "prop"):
		var f := unsupported_face()
		if not f.is_empty():
			out.append({"mode": "prop", "level": int(f.level), "cell": f.site})
	for r in repairs_wanted():
		if not on_board.call("repair", int(r.level), r.cell):
			out.append({"mode": "repair", "level": int(r.level), "cell": r.cell})
	for l in ladders_wanted():
		if not on_board.call("ladder", int(l.level), l.cell):
			out.append({"mode": "ladder", "level": int(l.level), "cell": l.cell})
	return out


## The goods one shore job takes from the yard (besides the mallet).
static func goods_for(mode: String) -> Dictionary:
	match mode:
		"prop":
			return {str(MineWorks.cfg().support.item): 1}
		"repair":
			return (MineWorks.cfg().support.repair as Dictionary).duplicate()
		"ladder":
			return {str(MineWorks.cfg().ladder.item): 1}
	return {}


## What the manor needs bought for the shore work it wants ({item: qty}): its goods, and a mallet, less what the works
## yard and the jobs' loads already hold and what is on order.
func manor_needs() -> Dictionary:
	var need := {}
	var wanted := shore_wanted()
	for j in w.manor_work.jobs:
		if j.kind == "shore" and j.taker == "":
			wanted.append({"mode": str(j.mode)})            # posted, waiting for a worker: its goods are still needed
	if wanted.is_empty():
		return need
	for s in wanted:
		var g := goods_for(str(s.mode))
		for id in g:
			need[id] = int(need.get(id, 0)) + int(g[id])
	need["mallet"] = 1
	var yard: Inventory = w.manor_work.yard
	for id in need.keys():
		var have := yard.count(id)
		for j in w.manor_work.jobs:
			have += (j.load as Inventory).count(id)
		for x in w.manor_orders:
			if int(x["for"]) == -1 and str(x.tool) == id:
				have += 1
		need[id] = int(need[id]) - have
		if int(need[id]) <= 0:
			need.erase(id)
	return need


## The reeve's evening (NPCBrain.reeve_day): the manor buys what its shore work needs from whoever holds it (a carpenter,
## smith or merchant, at their price, from the treasury above its floor) into the works yard; what nobody holds and a
## carpenter can make, it orders from that carpenter (paid its worth in advance). Then the shore jobs are posted where
## the yard holds their goods. Returns the coins spent.
func procure() -> int:
	var need := manor_needs()
	var floor_coins: float = w.brain.daily_obligations() * float(GameData.b("manor_support_floor_days"))
	var spent := 0
	var ids := need.keys()
	ids.sort()
	for id in ids:
		var left := int(need[id])
		while left > 0:
			var seller := _holder(str(id))
			if seller == null:
				break
			var price := w.sell_price(seller, str(id))
			if w.treasury - price < floor_coins:
				return spent
			seller.inv.remove(str(id))
			w.manor_work.yard.add(str(id))
			seller.coins += price
			seller.earned += price
			w.treasury -= price
			spent += price
			left -= 1
			w.stat("gov_mine_equipment", price)
			w.stat("gov_bought_" + str(id))
		while left > 0 and RECIPE.has(str(id)):
			var maker := _maker(str(id))
			if maker == null:
				break
			var advance := int(ceil(GameData.value(str(id))))
			if w.treasury - advance < floor_coins:
				return spent
			maker.coins += advance
			maker.earned += advance
			w.treasury -= advance
			spent += advance
			w.manor_orders.append({"smith": maker.id, "tool": str(id), "for": -1, "paid": advance, "day": w.day()})
			w.stat("gov_mine_equipment", advance)
			w.stat("gov_ordered_" + str(id))
			left -= 1
	return spent


## Who holds `id` for sale: a carpenter, a smith or a merchant (not what they keep for their own work or an order).
func _holder(id: String) -> NPC:
	for v: NPC in w.npcs:
		if v.alive and (v.job in ["carpenter", "smith"] or w.brain.buy_role(v) in ["merchant_goods", "merchant_raw"]) and v.inv.has(id) \
				and not w.brain.keeps(v, id):
			return v
	return null


## A carpenter who can make `id` (the skill) and has fewest of the manor's orders open (under manor_orders_per_smith).
func _maker(id: String) -> NPC:
	var best: NPC = null
	var bn := 1 << 30
	for v: NPC in w.npcs:
		if not v.alive or v.job != "carpenter" or not w.brain._can_make(v, RECIPE[id]):
			continue
		var k := w.manor_orders.filter(func(x): return int(x.smith) == v.id).size()
		if k < int(GameData.b("manor_orders_per_smith")) and k < bn:
			bn = k
			best = v
	return best


# ---------------------------------------------------------------- a miner's minecart ---------
## Whether miner `n`'s household needs a minecart: their nearest seam lies below ground, track on that level runs from
## within minecart.near_seam of it to a rails' end toward the way out, a cart standing there would make the haul cheaper
## than carrying (MineWorks.haul_costs' costs), and the household has none (set down or carried). {} or {cell, level,
## seam} (the rails' cell nearest the seam, where the cart is set down).
func minecart_wanted(n: NPC) -> Dictionary:
	if n.job != "miner" or n.household < 0 or not n.alive:
		return {}
	var mw: MineWorks = w.mine_works
	if not w.carts.of(World.hh_ref(n.household), "minecart").is_empty():
		return {}
	for m in w.households[n.household].members:
		var o := w.npc(int(m))
		if o != null and o.alive and o.inv.has("minecart"):
			return {}
	var d: Dictionary = w.nearest_seam(n, ["iron_ore", "coal", "copper_ore", "stone"])
	if d.is_empty() or World.level_of(d) == 0:
		return {}
	var lv := World.level_of(d)
	var mc: Dictionary = MineWorks.cfg().minecart
	var stand: Vector2i = w.brain.beside(Vector2i(int(d.x), int(d.y)), Vector2i(int(d.x), int(d.y)), lv)
	var best := Vector2i(-1, -1)
	var bd := float(mc.near_seam)
	for c in mw.track_cells(lv):
		var dd := mw._walk_len(lv, stand, c)
		if dd <= bd:
			bd = dd
			best = c
	if best.x < 0:
		return {}
	var up: Array = mw._unload_point(lv, best)
	if (up[0] as Vector2i).x < 0 or up[0] == best:
		return {}
	var route := mw.track_route(lv, best, up[0])
	var leg := w.underground.next_leg(lv, 0)
	if leg.is_empty():
		return {}
	var carry := 2.0 * mw._walk_len(lv, stand, leg.from.stand) / float(GameData.b("carry_ore"))
	var cart := 2.0 * bd / float(GameData.b("carry_ore")) + (float(route.size() - 1) * (1.0 / float(mc.track_speed) + 1.0) + 2.0 * float(up[1])) / float(mc.trip)
	if cart >= carry:
		return {}
	return {"cell": best, "level": lv}


## A miner whose household needs a minecart buys one a maker holds, with their own coins, and sets it down on the
## rails by their seam (the plan), when they can pay; [] otherwise (the carpenter makes one meanwhile: carpenter_work).
func miner_cart_plan(n: NPC) -> Array:
	var want := minecart_wanted(n)
	if want.is_empty():
		return []
	var seller: NPC = null
	for v: NPC in w.npcs:
		if v.alive and v != n and not w.asleep(v) and (v.job == "carpenter" or w.brain.buy_role(v) == "merchant_goods") and v.inv.has("minecart") \
				and not w.brain.keeps(v, "minecart"):
			seller = v
			break
	if seller == null or not w.can_afford(n, w.deal_price(w.sell_price(seller, "minecart"), n, seller)):
		return []
	var b: NPCBrain = w.brain
	n.doing = "buying a minecart for the mine"
	w.stat("minecart_purchases_planned")
	return [b.go(b._workplace_cell(seller)), b.doit("buy_from", {"vendor": seller.id, "item": "minecart", "qty": 1}),
		b.go(want.cell, 1.0, int(want.level)), b.doit("mc_place", {"x": want.cell.x, "y": want.cell.y})]


# ---------------------------------------------------------------- the carpenter's work -------
## The carpenter's mining work (NPCBrain's carpenter, first): the manor's orders (supports, ladders, mallets), then a
## minecart a miner's household needs (only when nobody holds one), each from its own materials: what it lacks it saws
## (planks from logs) or buys (the smith's nails, axles and ironwork; cart wheels it makes). True when a plan is made.
func carpenter_work(n: NPC) -> bool:
	var b: NPCBrain = w.brain
	for x in w.manor_orders:
		if int(x.smith) != n.id or n.inv.has(str(x.tool)) or not RECIPE.has(str(x.tool)):
			continue
		if _make(n, RECIPE[str(x.tool)], "for the manor"):
			return true
	var needed := false
	for o: NPC in w.npcs:
		if o.alive and o.job == "miner" and not minecart_wanted(o).is_empty():
			needed = true
			break
	if not needed:
		return false
	for v: NPC in w.npcs:
		if v.alive and v.inv.has("minecart") and (v.job in ["carpenter"] or b.buy_role(v) == "merchant_goods"):
			return false                                 # one is ready for them to buy
	return _make(n, RECIPE.minecart, "for a miner's household")


## Make recipe `r` (the carpenter's), or the step toward it: a missing cart wheel made, planks sawn from logs, a part
## bought from the smith or a merchant (NPCBrain._parts_trip). True when a plan is made.
func _make(n: NPC, r: String, why: String) -> bool:
	var b: NPCBrain = w.brain
	var rec: Dictionary = GameData.recipes[r]
	if not b._can_make(n, r):
		return false
	if n.inv.has_all(rec["in"]):
		if b._do_recipe(n, r):
			n.doing = "making a %s %s" % [GameData.item_name(str(rec.out.keys()[0])).to_lower(), why]
			w.stat("equipment_made_" + str(rec.out.keys()[0]))
			return true
		return false
	var buy := {}
	for id in rec["in"]:
		var short := int(rec["in"][id]) - n.inv.count(id)
		if short <= 0:
			continue
		if id == "cart_wheel" and n.inv.has_all(GameData.recipes.make_cart_wheel["in"]):
			return b._do_recipe(n, "make_cart_wheel")
		if id == "plank" and n.inv.has_all(GameData.recipes.saw_planks["in"]):
			return b._do_recipe(n, "saw_planks")
		if id in ["plank", "log", "cart_wheel"]:
			return false                                 # its own trade's stock: it waits for logs (bought as ever)
		buy[id] = int(rec["in"][id])
	if buy.is_empty():
		return false
	var plan := b._parts_trip(n, buy, 0)
	if plan.is_empty():
		return false
	n.doing = "buying %s %s" % [", ".join(buy.keys().map(func(i): return GameData.item_name(str(i)).to_lower())), why]
	n.plan = plan
	return true
