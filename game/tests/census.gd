extends RefCounted
## Where every good in a world is held, by holder (a census): villagers, markets, household pantries,
## the granary, troughs, building sites and carried loads, the player (pack, chest, premises), loot, the
## manor's work and carts. One count for the economy simulation's ledger (economy_sim.gd) and the save
## conservation test (DVW-A6), so both see the same goods.
##   const Census := preload("res://tests/census.gd")

const MARKET_ROLES := ["merchant_raw", "merchant_food", "merchant_goods", "tavernkeeper"]


static func holders(w: World) -> Dictionary:
	var g := {"npcs": {}, "markets": {}, "households": {}, "granary": {}, "troughs": {}, "sites": {}, "player": {}, "loot": {}, "manor_work": {}}
	var add := func(to: Dictionary, inv: Inventory) -> void:
		for id in inv.items:
			to[id] = int(to.get(id, 0)) + int(inv.items[id])
	for n: NPC in w.npcs:
		add.call(g.markets if w.brain.buy_role(n) in MARKET_ROLES else g.npcs, n.inv)
	for hh in w.households:
		add.call(g.households, hh.pantry)
	for c in w.containers:
		if c.kind == "table":
			add.call(g.markets, c.inv)
	add.call(g.granary, w.granary)
	add.call(g.player, w.player.inv)
	add.call(g.player, w.player.chest)
	for l in w.loot:
		add.call(g.loot, l.inv)
	var mg: Dictionary = w.manor_work.goods()      # the manor's lots, works yard and job loads
	for id in mg:
		g.manor_work[id] = int(g.manor_work.get(id, 0)) + int(mg[id])
	for src in [w.site_goods(), w.construction.carried()]:
		for id in src:
			g.sites[id] = int(g.sites.get(id, 0)) + int(src[id])
	g["carts"] = {}
	for c in w.carts.carts:                        # goods riding in carts (B14)
		add.call(g.carts, c.store)
	for s in w.business.premises():                # the player's stall and shops: sale stock and back store
		for src in [s.get("stock", {}), s.get("store", {})]:
			for id in src:
				g.player[id] = int(g.player.get(id, 0)) + int(src[id])
	g["stalls"] = {}
	for s in w.business.stalls.npc_built():        # villagers' built market stalls: their sale stock (STALL-02)
		for id in s.get("stock", {}):
			g.stalls[id] = int(g.stalls.get(id, 0)) + int(s.stock[id])
	for id in w.fauna.pens:
		var tr := int(w.fauna.pens[id].trough)
		if tr > 0:
			g.troughs.wheat = int(g.troughs.get("wheat", 0)) + tr
	return g


## Every good's total over all holders.
static func goods(w: World) -> Dictionary:
	var out := {}
	var g := holders(w)
	for k in g:
		for id in g[k]:
			out[id] = int(out.get(id, 0)) + int(g[k][id])
	return out
