class_name SettlementHoldings
extends RefCounted
## Where every good and coin in the village is held, by holder (a census). Read-only: it moves nothing.
##
## PROSPECTIVE (Expansion 18, PROS-18; wip/expansion18-preparation). The holder walk is the one that was
## tests/census.gd (economy_sim.gd's ledger and the DVW-A6 save conservation test), moved here unchanged so
## the settlement report (SET-B/C) can run in the game, where tests/ is not exported; tests/census.gd now
## delegates here, so there is still one census (CLAUDE.md: one implementation per concern).
##
## Goods holders: villagers, markets (the market roles and the tables), household pantries, the granary,
## troughs, building sites and carried loads, the player (pack, chest, premises), loot, the manor's work,
## carts, villagers' built stalls, goods carried on service contracts (CON-02) and the open pits' spoil (MIN-E). The
## Build 17 holders were moved here from tests/census.gd at the SYNC-17 merge (cd7439c). Coin holders: the same split as World.total_coins (coins/sum equals it).

const MARKET_ROLES := ["merchant_raw", "merchant_food", "merchant_goods", "tavernkeeper"]


static func holders(w: World) -> Dictionary:
	var g := {"npcs": {}, "markets": {}, "households": {}, "granary": {}, "troughs": {}, "sites": {}, "player": {}, "loot": {}, "manor_work": {}, "chapel": {}}
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
	if w.chapel != null:
		add.call(g.chapel, w.chapel.store)           # DVW-B3-CHAPEL: food offered and grown, and the plot's seed
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
		for src in [s.get("stock", {}), s.get("store", {}), s.get("work", {})]:
			for id in src:
				g.player[id] = int(g.player.get(id, 0)) + int(src[id])
	g["stalls"] = {}
	for s in w.business.stalls.npc_built():        # villagers' built market stalls: their sale stock (STALL-02)
		for id in s.get("stock", {}):
			g.stalls[id] = int(g.stalls.get(id, 0)) + int(s.stock[id])
	g["contracts"] = {}
	var cg: Dictionary = w.contracts.goods()       # CON-02 (Build 17): goods dug for buyers and still carried on service contracts
	for id in cg:
		g.contracts[id] = int(cg[id])
	g["booths"] = {}
	if w.couriers != null:                         # REG-COURIER-01: goods waiting at the courier booths (for a departure, or deposited for a sender)
		var bg: Dictionary = w.couriers.held_goods()
		for id in bg:
			g.booths[id] = int(bg[id])
	g["pits"] = {}
	if w.pits != null:                             # MIN-E (Build 17): earth lying on the open pits' spoil heaps
		var pg: Dictionary = w.pits.goods()
		for id in pg:
			g.pits[id] = int(pg[id])
	for id in w.fauna.pens:
		var tr := int(w.fauna.pens[id].trough)
		if tr > 0:
			g.troughs.wheat = int(g.troughs.get("wheat", 0)) + tr
	return g


## Every good's total over all holders.
static func goods(w: World) -> Dictionary:
	return total(holders(w))


## The sum of a holders dictionary ({holder: {item: n}}) by item.
static func total(g: Dictionary) -> Dictionary:
	var out := {}
	for k in g:
		for id in g[k]:
			out[id] = int(out.get(id, 0)) + int(g[k][id])
	return out


## The village's coins by holder, the same terms World.total_coins adds (their sum equals it): the player, the
## manor's treasury, quest rewards and manor work set aside, villagers (market roles apart), loot and the
## player's tills. The caravan's purse is outside the village and is not here.
static func coins(w: World) -> Dictionary:
	var c := {"player": w.player.coins, "treasury": w.treasury, "reserved": 0, "npcs": 0, "markets": 0, "loot": 0, "tills": 0, "chapel": w.chapel.coins if w.chapel != null else 0}
	if w.quests:
		c.reserved += w.quests.reserved_total()
	if w.manor_work:
		c.reserved += w.manor_work.reserved_total()
	if w.contracts:
		c.reserved += w.contracts.reserved_total()    # CON-01 (Build 17): buyers' coins set aside for contracts
	for a: NPC in w.npcs:
		if w.brain.buy_role(a) in MARKET_ROLES:
			c.markets += a.coins
		else:
			c.npcs += a.coins
	for l in w.loot:
		c.loot += int(l.coins)
	if w.business:
		c.tills += w.business.tills()
	if w.couriers != null:
		c["booths"] = w.couriers.held_coins()      # REG-COURIER-01: fees held at the booths until the work is done, and proceeds deposited
	return c


static func coin_sum(c: Dictionary) -> int:
	var n := 0
	for k in c:
		n += int(c[k])
	return n
