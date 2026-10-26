class_name GearOrders
extends RefCounted
## ARMOR-CATALOG-01, WEAPON-CATALOG-01 (owner, 2026-10-26; Build 22): every piece of the armour and weapon catalogue is made
## to order by the trade that makes it, the village's armourers: the smith (metal armour, helmets and every weapon, at the
## anvil, Smithing), the tanner (leather and cloth armour, French hats, the mage's hats and hoods, at the workbench) and the
## tailor (plain hats, bandanas and hoods). The item's "order" ({maker, fee, bring}) says who makes it, the fee for the work,
## and, for a Cultural or Rare piece (a commission), the special materials the buyer must bring.
##
## An order is the item's own recipe (recipes.json, or the generated weapon catalogue) worked by the maker, by the rule every
## crafter follows (World.work_craft): the maker needs the recipe's skill level, and it is done while the buyer waits. The
## inputs: what the buyer must bring comes out of the buyer's pack; the rest from the maker's own stock, and whatever the
## maker lacks from the buyer's pack too (then it is not charged). The price: the fee plus every unit the maker supplies at
## its base value. Conservation: the buyer's materials go into the maker's pack, the coins from the buyer's purse to the
## maker's, the recipe turns the inputs into the piece (counted used_ and made_ as any craft), and the piece goes to the
## buyer: nothing is made from nothing or lost. A practised hand's saving (save_chance) leaves the saved inputs with the
## maker, as for any crafter; gear never gets a bonus unit. No randomness beyond work_craft's own draws.


const MAKERS := ["smith", "tanner", "tailor"]


## The trade that makes `id` ("" for an item nobody makes to order).
static func maker_job(id: String) -> String:
	return str(GameData.item(id).get("order", {}).get("maker", ""))


## Whether villager `n` takes orders: a living adult of a maker trade.
static func takes_orders(n: NPC) -> bool:
	return n != null and n.alive and n.role == "adult" and MAKERS.has(n.job)


## The recipe that makes `id` ("" if none).
static func recipe_of(id: String) -> String:
	for prefix in ["forge_", "sew_"]:
		if GameData.recipes.has(prefix + id):
			return prefix + id
	var found := ""                              # an older item's recipe of another name (leather_armor, leather_cap)
	for r in GameData.recipes:
		if (GameData.recipes[r].out as Dictionary).has(id) and (found == "" or str(r) < found):
			found = str(r)
	return found


## Every item `job` makes to order, armour first (items.json order), then the weapon catalogue (table order).
static func catalogue(job: String) -> Array:
	var out := []
	for id in GameData.items:
		if maker_job(str(id)) == job:
			out.append(str(id))
	return out


## The terms of `p` ordering `id` from `n` now: {why ("" if it can be done), recipe, fee, price, from_maker: {item: qty},
## from_player: {item: qty} (what is brought, and what the maker lacks)}.
static func terms(w: World, n: NPC, id: String, p: PlayerState) -> Dictionary:
	var out := {"why": "", "recipe": recipe_of(id), "fee": 0, "price": 0, "from_maker": {}, "from_player": {}}
	var o: Dictionary = GameData.item(id).get("order", {})
	if o.is_empty() or out.recipe == "":
		out.why = "Nobody makes that to order."
		return out
	if not takes_orders(n) or n.job != str(o.maker):
		out.why = "%s does not make that: ask the %s." % [n.name if n != null else "They", str(o.maker)]
		return out
	var away := w.service_absence(n)
	if away != "":
		out.why = away
		return out
	var r: Dictionary = GameData.recipes[out.recipe]
	var need := int(r.level)
	if Skills.level(n, str(r.skill)) < need:
		out.why = "%s cannot make it yet: it needs %s %d (%s has %d)." % [n.name, GameData.skills[str(r.skill)].name, need, n.name, Skills.level(n, str(r.skill))]
		return out
	var bring: Dictionary = o.get("bring", {})
	var short := []
	for k in r["in"]:
		var q := int(r["in"][k])
		var b := mini(q, int(bring.get(k, 0)))
		var spare := maxi(0, n.inv.count(k) - w.brain.reserve(n, k))
		var m := mini(q - b, spare)
		var from_p := q - m
		if from_p > 0:
			out.from_player[k] = from_p
			if p.inv.count(k) < from_p:
				short.append("%d %s" % [from_p - p.inv.count(k), GameData.item_name(k).to_lower()])
		if m > 0:
			out.from_maker[k] = m
	out.fee = int(o.fee)
	out.price = out.fee
	for k in out.from_maker:
		out.price += int(out.from_maker[k]) * GameData.value(k)
	if not short.is_empty():
		out.why = "You need %s more for it." % ", ".join(short)
	elif p.coins < int(out.price):
		out.why = "It costs %d coins; you have %d." % [int(out.price), p.coins]
	elif not p.inv.can_add(id):
		out.why = p.inv.full_text(id)
	return out


## `p` orders `id` from `n` (World.player_order_gear, which makes `p` the acting player). Returns {ok, why, paid, item,
## brought}.
static func order(w: World, n: NPC, id: String, p: PlayerState) -> Dictionary:
	var t := terms(w, n, id, p)
	if str(t.why) != "":
		return {"ok": false, "why": t.why, "paid": 0, "item": id, "brought": {}}
	var moved := []
	for k in t.from_player:
		if not w.transfer(p.inv, n.inv, k, int(t.from_player[k])):
			for m in moved:                      # all or nothing: what was handed over comes back
				w.transfer(n.inv, p.inv, m, int(t.from_player[m]))
			return {"ok": false, "why": "%s has no room for your %s." % [n.name, GameData.item_name(k).to_lower()], "paid": 0, "item": id, "brought": {}}
		moved.append(k)
	var made := w.work_craft(n, str(t.recipe), n.inv)
	if str(made.result) != "ok" or not n.inv.has(id):
		for k in t.from_player:                  # (never expected: terms checked it) the brought goods go back
			w.transfer(n.inv, p.inv, k, mini(int(t.from_player[k]), n.inv.count(k)))
		return {"ok": false, "why": "%s could not make it." % n.name, "paid": 0, "item": id, "brought": {}}
	var price := int(t.price)
	p.coins -= price
	n.coins += price
	n.earned += price
	w.transfer(n.inv, p.inv, id, 1)
	w.stat("gear_orders")
	w.stat("gear_order_fees", float(price))
	return {"ok": true, "why": "", "paid": price, "item": id, "brought": t.from_player}


## The words of an order's materials: "3 iron bar, 1 leather".
static func amounts(d: Dictionary) -> String:
	var parts := []
	for k in d:
		parts.append("%d %s" % [int(d[k]), GameData.item_name(k).to_lower()])
	return ", ".join(parts) if not parts.is_empty() else "nothing"
