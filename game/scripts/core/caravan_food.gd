class_name CaravanFood
extends RefCounted
## REG-BUY-01 (Expansion 18; owner Q18-10, "anyone may purchase goods from another settlement"): the PLAYER buys food from the
## caravan's wagon, the parity of what the village's households, treasury and food businesses already do on a visit day
## (NPCBrain._caravan_food) and of the luxury purchase (Luxury.buy). Same rules for everyone: the food is what a trader on the road
## holds (its own stock; the settlement's selling policy, REG-BUY-P1, has already decided what its businesses released to the trader),
## at the cheapest trader's floating price for that food (OffMapSettlement.food_price), paid into that trader's till, the coins leaving
## the village (World.coin_sources falls) and the unit crossing in (`imported_`). Nothing is made; a trader's stock that has run out
## sells no more. The foods are the settlements' (wheat, pottage, roast meat, bread, cheese) and raw meat, whatever a trader's stock holds of them.
## Deterministic: no draws; foods in a fixed order.

const FOODS := ["wheat", "bread", "cheese", "pottage", "roast_meat", "meat"]          # the settlements' foods (settlements.json rules.foods) and raw meat (OffMapSettlement.food_items)


## What the wagon offers the player now: [{id, price, left}] for each food a trader on the road holds; empty when the caravan is
## not in the village.
static func offers(w) -> Array:
	var out := []
	if not w.farm.caravan_here():
		return out
	var road: Array = w.regions.visiting(w.day())
	for id: String in FOODS:
		var s: OffMapSettlement = w.regions.food_seller(id, road)
		if s != null:
			var left := 0
			for t: OffMapSettlement in road:
				left += t.trader_has(id)
			out.append({"id": id, "price": s.food_price(id), "left": left})
	return out


## "" when the player may buy one `id` now, else why not.
static func refusal(w, p: PlayerState, id: String) -> String:
	if not FOODS.has(id):
		return "The caravan does not sell that."
	if not w.farm.caravan_here():
		return "The caravan is not here."
	var s: OffMapSettlement = w.regions.food_seller(id, w.regions.visiting(w.day()))
	if s == null:
		return "None of the traders here has any."
	if p.coins < s.food_price(id):
		return "You need %d coins." % s.food_price(id)
	if not p.inv.can_add(id):
		return p.inv.full_text(id)
	return ""


## The player buys one `id` from the cheapest trader on the road that holds it. "" when done.
static func buy(w, p: PlayerState, id: String) -> String:
	var no := refusal(w, p, id)
	if no != "":
		return no
	var seller: OffMapSettlement = w.regions.food_seller(id, w.regions.visiting(w.day()))
	var cost := seller.food_price(id)
	if not seller.sell_to_village(id, 1, cost):
		return "The trade fell through."
	w.note_settlement_trade(p, seller)
	p.coins -= cost
	p.inv.add(id)
	w.coin_sources -= cost
	w.stat("caravan_coins_out", cost)
	w.stat("imported_" + id)
	w.stat("caravan_food_units")
	w.stat("caravan_food_coins", cost)
	w.stat("caravan_food_player", cost)
	return ""
