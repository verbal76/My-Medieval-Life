class_name Luxury
extends RefCounted
## DVW-B3-LUX (owner, 2026-10-23, docs/directives/2026-10-23_owner_answers_coin_sinks.md: "luxury imports, costly caravan goods
## (spices, fine cloth, jewellery) bought for status, the coins leaving with the caravan"): a coin sink people choose.
##
## Where they come from: a luxury is a good a trader of the neighbouring settlements holds in its own stock (Wulstead's and
## Higham-on-the-Way's, game/data/settlements.json "start"; GAME EXPANSION, from beyond the map). The caravan sells only what
## the traders on the road that day hold (Regions.seller_for), so a luxury is limited by that stock: nothing is made for the
## sale, and a settlement's stock that has run out sells no more.
##
## Money: the buyer's coins go into the selling trader's till (OffMapSettlement.sell_to_village: its stock falls by the unit
## and its books show the coins from the village) and leave the village (World.coin_sources falls), as for every coin the
## village pays the caravan. Villagers' and the player's coins, the traders' goods and tills move together; nothing is made.
##
## Who buys: a villager on a visit day (NPCBrain.caravan, after the day's other trade) with a taste for such things, only
## from what they hold beyond their OD-19 reserve (World.reserve_of) and some savings, never when their household is short of
## food. The player buys through the context action beside the caravan's wagon, under the ordinary rules of coins and pack.
## Luxuries are kept: nothing eats or uses them up and no recipe takes them (spices are not an ingredient of any recipe). A
## villager's ownership is their pack's (Inventory, saved with the villager).
##
## "For status": the game has no standing measure for villagers in Build 18 (regard is between two people, Relations; notoriety
## is the player's crimes), so ownership has no effect yet beyond being held and shown. The judgment system (Expansion 19) is
## where it will count; `held_by` and `owned` are the reading points. Not invented here.
##
## Deterministic: no random draws. A taste is hashed from the world seed and the person's id; the order of buyers is by spare
## coins then id. All numbers: balance.json "luxury" (agent proposals, provisional).


static func cfg() -> Dictionary:
	return GameData.b("luxury")


static func items() -> Array:
	return cfg().items


static func is_luxury(id: String) -> bool:
	return (cfg().items as Array).has(id)


## What the caravan asks for one unit: the item's value times the markup, in whole coins.
static func price(id: String) -> int:
	return maxi(1, roundi(float(GameData.value(id)) * float(cfg().markup)))


## A villager's taste for luxuries, a fixed 0 to 1 from the world seed and their id (nothing they do changes it).
static func taste(w, n: NPC) -> float:
	var h: int = (((w.seed * 2246822519 + n.id * 3266489917 + 668265263) * 2654435761) >> 9) & 0x7fffffff
	return float(h % 100) / 100.0


## The coins a person holds beyond their OD-19 reserve and their savings: what a luxury may be bought with.
static func spare(w, n: NPC) -> int:
	return n.coins - w.reserve_of(n) - int(cfg().keep_coins)


static func owned(n: NPC, id: String) -> int:
	return n.inv.count(id)


## How many of each luxury the villagers hold and the player's pack holds: {id: units}. The reading point for a standing
## system (see the class note).
static func held_by(w) -> Dictionary:
	var out := {}
	for id in items():
		var k := 0
		for n: NPC in w.npcs:
			if n.alive:
				k += n.inv.count(id)
		if w.player != null:
			k += w.player.inv.count(id)
		out[id] = k
	return out


## The luxury a villager would buy now from the traders `on_road`, or "": the dearest that costs no more than spend_share of
## their spare coins, is held by a trader on the road, and of which they own fewer than own_max.
static func pick(w, n: NPC, on_road: Array) -> String:
	var sp := spare(w, n)
	for id: String in items():
		var p := price(id)
		if float(p) > float(sp) * float(cfg().spend_share):
			continue
		if n.inv.count(id) >= int(cfg().own_max.get(id, 1)) or not n.inv.can_add(id):
			continue
		if w.regions.seller_for(id, on_road) != null:
			return id
	return ""


## The villagers' buying on a visit day: at most buyers_per_visit, the most spare coin first. Returns the coins paid.
static func visit(w, on_road: Array) -> int:
	var c := cfg()
	var cands := []
	for n: NPC in w.npcs:
		if not n.alive or n.role != "adult" or taste(w, n) < float(c.min_taste):
			continue
		var sp := spare(w, n)
		if sp <= 0 or n.household < 0 or n.household >= w.households.size():
			continue
		cands.append([sp, n])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]) or (int(a[0]) == int(b[0]) and (a[1] as NPC).id < (b[1] as NPC).id))
	var paid := 0
	var bought := []
	for cand in cands:
		if bought.size() >= int(c.buyers_per_visit):
			break
		var n: NPC = cand[1]
		if w.brain.household_food_days(n.household) < float(c.min_food_days):
			continue
		var id := pick(w, n, on_road)
		if id == "":
			continue
		var p := price(id)
		var seller: OffMapSettlement = w.regions.seller_for(id, on_road)
		if not seller.sell_to_village(id, 1, p):
			continue
		n.coins -= p
		n.spent += p
		n.inv.add(id)
		w.coin_sources -= p
		w.stat("caravan_coins_out", p)               # the village's ledger of what it pays the caravan (economy_sim, conservation_test)
		w.stat("imported_" + id)                     # the goods crossing in (the item ledger of economy_sim)
		w.stat("luxury_bought_" + id)
		w.stat("luxury_coins", p)
		paid += p
		bought.append("%s %s a %s" % [n.name, n.family, GameData.item_name(id).to_lower()])
	if not bought.is_empty():
		w.note("From the caravan, %s (%d coins in all, paid to the traders)." % [", ".join(bought), paid])
	return paid


# ------------------------------------------------------------------ the player ----------------
## What the wagon offers the player now: [{id, price, left}] for each luxury a trader on the road today still holds; empty
## when the caravan is not in the village.
static func offers(w) -> Array:
	var out := []
	if not w.farm.caravan_here():
		return out
	var road: Array = w.regions.visiting(w.day())
	for id: String in items():
		var s: OffMapSettlement = w.regions.seller_for(id, road)
		if s != null:
			var left := 0
			for t: OffMapSettlement in road:
				left += t.trader_has(id)
			out.append({"id": id, "price": price(id), "left": left})
	return out


## "" when the player may buy one `id` now, else why not.
static func refusal(w, p: PlayerState, id: String) -> String:
	if not is_luxury(id):
		return "The caravan does not sell that."
	if not w.farm.caravan_here():
		return "The caravan is not here."
	if w.regions.seller_for(id, w.regions.visiting(w.day())) == null:
		return "None of the traders here has any."
	if p.coins < price(id):
		return "You need %d coins." % price(id)
	if not p.inv.can_add(id):
		return p.inv.full_text(id)
	return ""


## The player buys one `id` from the trader on the road that holds the most: the goods leave its stock and the coins go into
## its till and leave the village. "" when done.
static func buy(w, p: PlayerState, id: String) -> String:
	var no := refusal(w, p, id)
	if no != "":
		return no
	var seller: OffMapSettlement = w.regions.seller_for(id, w.regions.visiting(w.day()))
	var cost := price(id)
	if not seller.sell_to_village(id, 1, cost):
		return "The trade fell through."
	p.coins -= cost
	p.inv.add(id)
	w.coin_sources -= cost
	w.stat("caravan_coins_out", cost)
	w.stat("imported_" + id)
	w.stat("luxury_bought_" + id)
	w.stat("luxury_coins", cost)
	w.stat("luxury_player_" + id)
	w.note("%s %s bought %s from the caravan's trader from %s for %d coins." % [p.name, p.family, GameData.item_name(id).to_lower(), seller.name, cost])
	return ""
