class_name Contracts
extends RefCounted
## CON-01 (owner directive 2026-10-21 section 5; defaults OD-29, approved provisionally): negotiated goods-procurement
## contracts, the first slice (goods only). One character offers another payment for a quantity of an item: item,
## quantity and price per unit, and a deadline, all chosen by the buyer. It is an offer, not a command: the seller
## accepts, rejects with its reason, or counteroffers (price, quantity or a later deadline), judged from what it can
## really do (evaluate). The same record and the same rules serve player to NPC, NPC to player and NPC to NPC.
##
## The record is the Living Economy design's Contract (docs/build17/PROCUREMENT_CONTRACTS.md section 3) in its
## smallest form: {id, buyer, seller (World refs: "player", "npc:<id>", "manor"), item, qty, price_each, deadline_day,
## terms {pay, partial, all_at_once, deposit}, state (offered, accepted, fulfilled, lapsed, cancelled), delivered,
## paid, reserved, route, made_day, history [{day, by, what, qty, price_each, days}]}. Saved with the world.
##
## Policy (OD-29 defaults): paid on delivery, unit by unit; the buyer's coins for the unpaid value are set aside at
## acceptance (`reserved`, counted in World.total_coins through reserved_total, as Quests and ManorWork do), so the
## buyer cannot spend them elsewhere; partial delivery is allowed (all at once only if the buyer asks); cancelling pays
## only for what was delivered (already paid); past its deadline a contract lapses at dawn: the set-aside coins go back
## to the buyer and, if the goods did not all come, the tie between the two loses regard; no money penalty; no
## renegotiation after acceptance (cancel and offer again). A party's death ends the contract and returns the coins
## first (on_death, before what the dead leave passes on).
##
## Conservation: this module is the only code that moves contract goods and coins. A delivery is one step: the seller's
## units leave its pack and reach the buyer only if both can (Inventory), and exactly units x price_each leaves the
## reservation for the seller's purse; delivered never passes qty, paid never passes qty x price_each. No coin or good
## is made or destroyed. Deterministic: no random draws; contracts are kept in id order; villagers are visited in
## World.npcs order.

var w: World
var list: Array = []               # every contract on record, in id order (ended ones kept keep_days)
var next_id := 1


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("contracts")


# ---------------------------------------------------------------- parties --------------------
static func ref_of(who) -> String:
	if who is NPC:
		return World.npc_ref(who.id)
	return World.PLAYER


## The relations id of a party (Life.PLAYER_ID for the player), or -1 for the manor.
static func rel_id(ref: String) -> int:
	if ref == World.PLAYER:
		return Life.PLAYER_ID
	return World.ref_id(ref) if ref.begins_with("npc:") else -1


func _npc_of(ref: String) -> NPC:
	return w.npc(World.ref_id(ref)) if ref.begins_with("npc:") else null


func _alive(ref: String) -> bool:
	if ref == World.PLAYER or ref == World.MANOR:
		return true
	var n := _npc_of(ref)
	return n != null and n.alive


func _coins(ref: String) -> int:
	if ref == World.PLAYER:
		return w.player.coins
	if ref == World.MANOR:
		return w.treasury
	var n := _npc_of(ref)
	return n.coins if n else 0


func _add_coins(ref: String, k: int) -> void:
	if ref == World.PLAYER:
		w.player.coins += k
	elif ref == World.MANOR:
		w.treasury += k
	else:
		_npc_of(ref).coins += k


func _pack(ref: String) -> Inventory:
	if ref == World.PLAYER:
		return w.player.inv
	var n := _npc_of(ref)
	return n.inv if n else null


# ---------------------------------------------------------------- queries --------------------
func get_contract(id: int) -> Dictionary:
	for c in list:
		if int(c.id) == id:
			return c
	return {}


static func is_open(c: Dictionary) -> bool:
	return str(c.state) == "accepted"


static func left(c: Dictionary) -> int:
	return int(c.qty) - int(c.delivered)


## The open contracts `ref` is a party to (as buyer, seller, or either), in id order.
func open_of(ref: String, side := "") -> Array:
	var out := []
	for c in list:
		if is_open(c) and ((side != "seller" and c.buyer == ref) or (side != "buyer" and c.seller == ref)):
			out.append(c)
	return out


## Open contracts and standing offers between the player and this villager.
func with_player(n: NPC) -> Array:
	var me := World.npc_ref(n.id)
	var out := []
	for c in list:
		if str(c.state) in ["accepted", "offered"] and ((c.buyer == World.PLAYER and c.seller == me) or (c.seller == World.PLAYER and c.buyer == me)):
			out.append(c)
	return out


## The units of `id` villager `n` still owes on its open contracts: stock it keeps back from sale (NPCBrain.reserve).
func held_for(n: NPC, id: String) -> int:
	var me := World.npc_ref(n.id)
	var k := 0
	for c in list:
		if is_open(c) and c.seller == me and c.item == id:
			k += left(c)
	return k


## Coins set aside for open contracts (part of the village's money, not spendable; World.total_coins).
func reserved_total() -> int:
	var t := 0
	for c in list:
		t += int(c.get("reserved", 0))
	return t


# ---------------------------------------------------------------- evaluation -----------------
## Game minutes a villager can give contract work from now to the end of day `deadline_day` (work hours only, a
## share of them: walking, eating and other work take the rest), split with its other open contracts.
func _work_minutes(n: NPC, days: int) -> float:
	var day_len := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var now := fmod(w.minutes, World.DAY)
	var today := clampf(NPCBrain.WORK_END * 60.0 - maxf(now, NPCBrain.WORK_START * 60.0), 0.0, day_len)
	var mins := (today + float(maxi(0, days - 1)) * day_len) * float(cfg().work_share)
	if not w.manor_work.job_of(World.npc_ref(n.id)).is_empty() or not w.construction.contract_of(n).is_empty():
		mins -= minf(today, mins)                    # today already promised to the manor or a building site
	return mins / float(1 + open_of(World.npc_ref(n.id), "seller").size())


## How `n` could come by `id`: {stock, rate (units per work minute), cap (units by the deadline besides stock),
## route, recipe, cost (coins a unit when bought), why (the reason when there is no way)}.
## Routes: "stock" (what it holds, less what it keeps and owes), "mine" (a pickaxe and a seam of it, by its skill),
## "chop" (an axe and a grown tree), "harvest" (its own ripe field), "craft" (a recipe it has the skill for, with the
## inputs in hand), "buy" (another villager sells it cheaper than the contract pays). Not limited to its trade: anyone
## with the tool, the skill and the source can do it.
func means(n: NPC, id: String, days: int, price_each := 1 << 30) -> Dictionary:
	var out := {"stock": 0, "rate": 0.0, "cap": 0, "route": "", "recipe": "", "cost": 0, "why": "none"}
	if not w.brain.keeps(n, id):
		out.stock = maxi(0, n.inv.count(id) - w.brain.reserve(n, id))
		if NPCBrain.FOOD.has(id) and n.household >= 0:
			out.stock = maxi(0, int(out.stock) - ceili(w.brain.household_day_food(n.household) / maxf(1.0, NPCBrain.food_points(id))))
	var mins := _work_minutes(n, days)
	var ores := ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]
	if id in ores:
		if not n.inv.has("pickaxe"):
			out.why = "tool:pickaxe"
		elif not w.brain._can_mine(n, id):
			out.why = "skill"
		elif w.quests.deposit_left(id) <= 0:
			out.why = "source"
		else:
			out.rate = 1.0 / (float(GameData.b("mine_minutes")) * Skills.value(n, "mining", "mine_time", 1.0))
			out.cap = mini(w.quests.deposit_left(id), floori(float(out.rate) * mins))
			out.route = "mine"
	elif id == "log":
		if not n.inv.has("axe"):
			out.why = "tool:axe"
		elif w.nearest_tree(n.cell(), 70.0).is_empty():
			out.why = "source"
		else:
			out.rate = (4.0 + Skills.value(n, "woodcutting", "log_bonus")) / (float(GameData.b("chop_minutes")) * Skills.value(n, "woodcutting", "chop_time", 1.0))
			out.cap = floori(float(out.rate) * mins)
			out.route = "chop"
	elif id == "wheat" and n.job == "farmer":
		var f: Dictionary = w.brain._field(n.workplace)
		if not f.is_empty() and str(f.state) == "ripe" and w.quests.hired_on(f).is_empty():
			out.cap = int(f.get("crop", 0))
			out.route = "harvest"
		else:
			out.why = "source"
	if str(out.route) == "":
		for r in _recipes_for(id):
			var rec: Dictionary = GameData.recipes[r]
			if not w.brain._can_make(n, r):
				out.why = "skill"
				continue
			if w.stations_of(str(rec.station)).filter(func(s): return w.npc_may_use(n, w.stations[s])).is_empty():
				out.why = "station"
				continue
			var batches := 1 << 20
			for i in rec["in"]:
				batches = mini(batches, (n.inv.count(i) - (w.brain.reserve(n, i) if i != id else 0)) / int(rec["in"][i]))
			var per := int(rec.out[id])
			var by_time := floori(mins / (float(rec.minutes) * Skills.value(n, str(rec.skill), "craft_time", 1.0))) * per
			if batches <= 0:
				out.why = "materials"
				continue
			out.cap = mini(batches * per, by_time)
			out.rate = float(per) / float(rec.minutes)
			out.route = "craft"
			out.recipe = r
			break
	if str(out.route) == "":
		var v := _vendor(n, id, price_each)
		if v != null:
			var cost := w.deal_price(w.sell_price(v, id), n, v)
			var free := maxi(0, n.coins - w.reserve_of(n))
			out.cap = mini(v.inv.count(id) - w.brain.reserve(v, id), free / maxi(1, cost))
			if int(out.cap) > 0:
				out.route = "buy"
				out.cost = cost
			else:
				out.why = "coins"
	if int(out.stock) > 0 and str(out.route) == "":
		out.route = "stock"
	return out


func _recipes_for(id: String) -> Array:
	var out := []
	for r in GameData.recipes:
		if (GameData.recipes[r].out as Dictionary).has(id):
			out.append(r)
	out.sort()
	return out


## Another villager selling `id` to `n` below `price_each` (the cheapest, then the lowest id), or null.
func _vendor(n: NPC, id: String, price_each := 1 << 30) -> NPC:
	var best: NPC = null
	var best_p := price_each
	for o: NPC in w.npcs:
		if o == n or not o.alive or o.role != "adult" or w.brain.keeps(o, id) or o.inv.count(id) - w.brain.reserve(o, id) <= 0:
			continue
		if NPCBrain.BUYS.get(w.brain.buy_role(o), {}).has(id) and o.job != "merchant":
			continue                                  # a trade's own materials are not for sale (World.local_supply's rule)
		var p := w.deal_price(w.sell_price(o, id), n, o)
		if p < best_p:
			best = o
			best_p = p
	return best


## The least `n` takes for a unit of `id` from `buyer_ref`: what the goods would fetch anyway (the item's value, or what
## its best buyer pays now), at least the bought cost and a coin, by its household's needs (OD-19: one short of its
## reserve takes a sure income for less) and its tie with the buyer (a friend's price).
func min_price(n: NPC, buyer_ref: String, id: String, m: Dictionary) -> int:
	var base := float(GameData.value(id))
	var b: NPC = w.brain._buyer_for(n, id) if NPCBrain.OUTLETS.has(id) and n.inv.has(id) else null
	if b != null:
		var p: Array = w.sale_prices(b, n, id, 1)
		if not p.is_empty():
			base = maxf(base, float(p[0]))
	if str(m.route) == "buy":
		base = maxf(base, float(m.cost) + 1.0)
	var f := float(cfg().needy_factor) if n.coins < w.reserve_of(n) else float(cfg().comfortable_factor)
	var rid := rel_id(buyer_ref)
	if rid != -1 and w.relations.friends(rid, n.id):
		f -= float(Relations.cfg().friend_price)
	return maxi(1, roundi(base * f))


## The seller's answer to an offer, the one judgment for every buyer (the player, a villager or the manor):
## {answer: "accept" | "counter" | "reject", say (its words), qty, price_each, days, route, recipe, min_price}.
## Hard limits: it never accepts what it cannot do. A counter offers its least price, the quantity it can manage, or
## the later deadline that makes the whole quantity possible.
func evaluate(n: NPC, buyer_ref: String, id: String, qty: int, price_each: int, days: int) -> Dictionary:
	var r := {"answer": "reject", "say": "", "qty": qty, "price_each": price_each, "days": days, "route": "", "recipe": "", "min_price": 0}
	if n == null or not n.alive:
		r.say = "There is nobody to answer."
		return r
	if n.role != "adult":
		r.say = "I'm too young to take that on." if n.role == "child" else "I'm past taking on work like that."
		return r
	if buyer_ref == World.npc_ref(n.id) or GameData.item(id).is_empty() or qty <= 0 or price_each <= 0 or days <= 0:
		r.say = "That's no kind of offer."
		return r
	if buyer_ref == World.PLAYER and w.relations.notoriety() >= int(cfg().notoriety_refuse):
		r.say = "I'll not deal with you. Folk say what you've done."
		return r
	if open_of(World.npc_ref(n.id), "seller").size() >= int(cfg().max_open_per_seller):
		r.say = "I've promised all the work I can take on already."
		return r
	var item := GameData.item_name(id).to_lower()
	var m := means(n, id, days, price_each)
	var can := int(m.stock) + int(m.cap)
	r.route = m.route
	r.recipe = m.recipe
	r.min_price = min_price(n, buyer_ref, id, m)
	if can <= 0:
		match str(m.why):
			"tool:pickaxe", "tool:axe":
				r.say = "I've no %s to get %s with." % [str(m.why).get_slice(":", 1), item]
			"skill":
				r.say = "I haven't the skill for %s." % item
			"station":
				r.say = "I've nowhere to make %s." % item
			"materials":
				r.say = "I've not the makings of %s, and nobody sells them cheap enough." % item
			"coins":
				r.say = "I'd have to buy %s, and I can't spare the coins to." % item
			"source":
				r.say = "There's no %s to be had where I could get it." % item
			_:
				r.say = "I've no way to come by %s." % item
		return r
	var c_qty := qty
	var c_days := days
	if can < qty:
		var rate_day := float(m.rate) * (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0 * float(cfg().work_share)
		var more := days
		if rate_day > 0.0 and str(m.route) in ["mine", "chop", "craft"]:
			while more < int(cfg().max_days) and int(means(n, id, more, price_each).cap) + int(m.stock) < qty:
				more += 1
		if more > days and int(means(n, id, more, price_each).cap) + int(m.stock) >= qty:
			c_days = more
		else:
			c_qty = can
	var c_price := maxi(price_each, int(r.min_price))
	if c_qty == qty and c_days == days and c_price == price_each:
		r.answer = "accept"
		r.say = "Done. %d %s at %d each, by the end of day %d." % [qty, item, price_each, w.day() + days]
		return r
	r.answer = "counter"
	r.qty = c_qty
	r.days = c_days
	r.price_each = c_price
	var parts := []
	if c_price > price_each:
		parts.append("not at %d each; %d is the least I'd take" % [price_each, c_price])
	if c_qty < qty:
		parts.append("I can manage %d, not %d" % [c_qty, qty])
	if c_days > days:
		parts.append("give me %d days, not %d" % [c_days, days])
	var said := "; ".join(parts) + "."
	r.say = said.substr(0, 1).to_upper() + said.substr(1)
	return r


# ---------------------------------------------------------------- making a contract ----------
## Why `buyer_ref` cannot set `total` coins aside now ("" when it can): the player from their purse; a villager only
## from what is left above its OD-19 reserve (a purchase for its trade, World.can_afford's rule); the manor from the
## treasury.
func fund_refusal(buyer_ref: String, total: int) -> String:
	if buyer_ref == World.PLAYER:
		return "" if w.player.coins >= total else "You haven't %d coins to set aside for it." % total
	if buyer_ref == World.MANOR:
		return "" if w.treasury >= total else "The manor cannot set aside %d coins." % total
	var b := _npc_of(buyer_ref)
	if b == null or not b.alive:
		return "The buyer is gone."
	return "" if b.coins - total >= w.reserve_of(b) else "%s cannot set aside %d coins without touching what the household needs." % [b.name, total]


func _new_record(buyer_ref: String, seller_ref: String, id: String, qty: int, price_each: int, days: int, history: Array) -> Dictionary:
	var c := {"id": next_id, "buyer": buyer_ref, "seller": seller_ref, "item": id, "qty": qty, "price_each": price_each,
		"days": days, "deadline_day": w.day() + days - 1, "state": "offered", "delivered": 0, "paid": 0, "reserved": 0, "route": "",
		"recipe": "", "made_day": w.day(),
		"terms": {"pay": "on_delivery", "partial": true, "all_at_once": false, "deposit": 0},
		"history": history.duplicate(true)}
	next_id += 1
	return c


## An offer from `buyer_ref` to villager `n`: it is judged (evaluate) and, if accepted, the contract opens with the
## buyer's coins set aside. Returns the evaluation plus "contract" (the record) when one opened, or a refusal
## ("answer": "refused", "say") when the buyer cannot make the offer. `history` carries earlier rounds of the talk.
func propose(buyer_ref: String, n: NPC, id: String, qty: int, price_each: int, days: int, history := []) -> Dictionary:
	if buyer_ref == World.PLAYER and open_of(World.PLAYER, "buyer").size() >= int(cfg().max_open_player):
		return {"answer": "refused", "say": "You have as many contracts open as you can keep track of (%d)." % int(cfg().max_open_player)}
	var why := fund_refusal(buyer_ref, qty * price_each)
	if why != "":
		return {"answer": "refused", "say": why}
	var hist: Array = history.duplicate(true)
	hist.append({"day": w.day(), "by": buyer_ref, "what": "offer", "qty": qty, "price_each": price_each, "days": days})
	var r := evaluate(n, buyer_ref, id, qty, price_each, days)
	hist.append({"day": w.day(), "by": World.npc_ref(n.id), "what": str(r.answer), "qty": int(r.qty), "price_each": int(r.price_each), "days": int(r.days)})
	r.history = hist
	if r.answer != "accept":
		return r
	var c := _new_record(buyer_ref, World.npc_ref(n.id), id, qty, price_each, days, hist)
	c.route = r.route
	c.recipe = r.recipe
	if not _open(c):
		return {"answer": "refused", "say": fund_refusal(buyer_ref, qty * price_each)}
	r.contract = c
	return r


## Set the buyer's coins aside and open the contract. False (nothing changed) if they cannot be set aside.
func _open(c: Dictionary) -> bool:
	var total := int(c.qty) * int(c.price_each)
	if _coins(c.buyer) < total:
		return false
	_add_coins(c.buyer, -total)
	c.reserved = total
	c.state = "accepted"
	c.deadline_day = w.day() + int(c.days) - 1        # the last day it may be delivered on (days counts today)
	if not list.has(c):
		list.append(c)
	var s := _npc_of(c.seller)
	if s:
		s.remember("promised %d %s to %s" % [int(c.qty), GameData.item_name(c.item).to_lower(), w.ref_name(c.buyer)])
	var b := _npc_of(c.buyer)
	if b:
		b.remember("ordered %d %s from %s" % [int(c.qty), GameData.item_name(c.item).to_lower(), w.ref_name(c.seller)])
	w.stat("contracts_made")
	w.note("%s agreed to supply %s with %d %s at %d each by day %d." % [w.ref_name(c.seller, true), w.ref_name(c.buyer), int(c.qty),
			GameData.item_name(c.item).to_lower(), int(c.price_each), int(c.deadline_day) + 1])
	return true


## A villager's offer to the player (the player is the seller): kept as an "offered" record until the player accepts
## it (accept_offer), declines it, or it lapses after offer_days. Nothing is set aside until it is accepted.
func offer_to_player(b: NPC, id: String, qty: int, price_each: int, days: int) -> Dictionary:
	var c := _new_record(World.npc_ref(b.id), World.PLAYER, id, qty, price_each, days,
			[{"day": w.day(), "by": World.npc_ref(b.id), "what": "offer", "qty": qty, "price_each": price_each, "days": days}])
	list.append(c)
	return c


## The player takes up a villager's standing offer: its coins are set aside now. "" or the reason it cannot open.
func accept_offer(c: Dictionary) -> String:
	if str(c.state) != "offered" or c.seller != World.PLAYER:
		return "That offer no longer stands."
	if open_of(World.PLAYER, "seller").size() >= int(cfg().max_open_player):
		return "You have as many contracts open as you can keep track of (%d)." % int(cfg().max_open_player)
	var why := fund_refusal(c.buyer, int(c.qty) * int(c.price_each))
	if why != "" or not _open(c):
		_end(c, "cancelled", "the buyer can no longer pay")
		return why if why != "" else "They can no longer pay what they offered."
	c.history.append({"day": w.day(), "by": World.PLAYER, "what": "accept", "qty": int(c.qty), "price_each": int(c.price_each), "days": int(c.days)})
	return ""


func decline_offer(c: Dictionary) -> void:
	if str(c.state) == "offered":
		c.history.append({"day": w.day(), "by": c.seller, "what": "decline", "qty": int(c.qty), "price_each": int(c.price_each), "days": int(c.days)})
		_end(c, "cancelled", "declined")


# ---------------------------------------------------------------- delivery -------------------
## Hand over up to `units` of the contract's item from the seller's pack to `into` (the buyer's pack, or the player's
## chest when delivered to their home), each unit paid from the coins set aside. One step: the goods move and the coins
## move, or nothing does. Returns the units delivered.
func deliver(c: Dictionary, units: int, into: Inventory = null) -> int:
	if not is_open(c) or not _alive(c.buyer) or not _alive(c.seller):
		return 0
	var from := _pack(c.seller)
	var to: Inventory = into if into != null else _pack(c.buyer)
	if from == null or to == null:
		return 0
	units = mini(mini(units, left(c)), from.count(c.item))
	if c.get("terms", {}).get("all_at_once", false) and units < left(c):
		return 0                                         # the buyer asked for it all at once
	var pay := units * int(c.price_each)
	if units <= 0 or pay > int(c.reserved) or not to.can_add(c.item):
		return 0
	from.remove(c.item, units)
	if c.seller == World.PLAYER:
		w.player.trim_stolen()
	to.add(c.item, units)
	c.reserved = int(c.reserved) - pay
	c.paid = int(c.paid) + pay
	c.delivered = int(c.delivered) + units
	_add_coins(c.seller, pay)
	var s := _npc_of(c.seller)
	if s:
		s.earned += pay
	var b := _npc_of(c.buyer)
	if b:
		b.spent += pay
	w.stat("contract_units", units)
	w.stat("contract_paid", pay)
	c.history.append({"day": w.day(), "by": c.seller, "what": "deliver", "qty": units, "price_each": int(c.price_each), "days": 0})
	if left(c) <= 0:
		_end(c, "fulfilled", "")
		var rid := rel_id(c.seller)
		var other := _npc_of(c.buyer)
		if other != null and rid != -1:
			w.relations.helped(rid, other, float(Relations.cfg().help_regard) * 0.5)    # a promise kept earns regard
		elif s != null and rel_id(c.buyer) != -1:
			w.relations.helped(rel_id(c.buyer), s, float(Relations.cfg().help_regard) * 0.5)
	return units


## The villager seller's delivery at the end of its walk (NPCBrain act "contract_deliver"): to a villager buyer's
## pack, or to the player's chest at their home.
func npc_deliver(n: NPC, id: int) -> bool:
	var c := get_contract(id)
	if c.is_empty() or c.seller != World.npc_ref(n.id):
		return false
	if c.buyer == World.PLAYER:
		if w.player.home == "" or not w.buildings.has(w.player.home):
			return false
		return deliver(c, n.inv.count(c.item), w.player.chest) > 0
	return deliver(c, n.inv.count(c.item)) > 0


# ---------------------------------------------------------------- ending ---------------------
## The coins still set aside go back to the buyer and the contract ends in `state`.
func _end(c: Dictionary, state: String, why: String) -> void:
	var held := int(c.get("reserved", 0))
	c.reserved = 0
	if held > 0:
		_add_coins(c.buyer, held)
	c.state = state
	c.ended_day = w.day()
	if why != "":
		c.why = why


## Either party ends an open contract: what was delivered has been paid; the rest of the set-aside coins go back to
## the buyer. No fee (OD-29). "" or the reason it cannot.
func cancel(c: Dictionary, by_ref: String) -> String:
	if not is_open(c):
		return "That contract is not open."
	if by_ref != c.buyer and by_ref != c.seller:
		return "Only those who made it can end it."
	c.history.append({"day": w.day(), "by": by_ref, "what": "cancel", "qty": int(c.delivered), "price_each": int(c.price_each), "days": 0})
	_end(c, "cancelled", "ended by %s" % w.ref_name(by_ref))
	w.stat("contracts_cancelled")
	w.note("%s ended the contract for %s (%d of %d delivered)." % [w.ref_name(by_ref, true), GameData.item_name(c.item).to_lower(), int(c.delivered), int(c.qty)])
	return ""


## Past its deadline: the contract lapses, the set-aside coins go back to the buyer, and the seller who let the buyer
## down loses regard with them (no money penalty, OD-29).
func _lapse(c: Dictionary) -> void:
	c.history.append({"day": w.day(), "by": "", "what": "lapse", "qty": int(c.delivered), "price_each": int(c.price_each), "days": 0})
	_end(c, "lapsed", "the deadline passed")
	w.stat("contracts_lapsed")
	var a := rel_id(c.buyer)
	var b := rel_id(c.seller)
	if a != -1 and b != -1:
		var t: Dictionary = w.relations.tie(a, b)
		w.relations._raise(t, -float(cfg().default_regard), 0.0, false)
	var buyer := _npc_of(c.buyer)
	if buyer:
		buyer.remember("let down by %s over %s" % [w.ref_name(c.seller), GameData.item_name(c.item).to_lower()])
	w.note("The contract for %d %s from %s to %s lapsed: %d delivered." % [int(c.qty), GameData.item_name(c.item).to_lower(),
			w.ref_name(c.seller), w.ref_name(c.buyer), int(c.delivered)])


## Dawn: contracts past their deadline lapse, offers to the player past offer_days are withdrawn, ended records older
## than keep_days are dropped, then businesses short of an input nobody sells may order it (npc_orders).
func dawn() -> void:
	var d: int = w.day()
	for c in list:
		if is_open(c) and d > int(c.deadline_day):
			_lapse(c)
		elif str(c.state) == "offered" and d - int(c.made_day) >= int(cfg().offer_days):
			_end(c, "cancelled", "the offer was not taken up")
	list = list.filter(func(c): return str(c.state) in ["accepted", "offered"] or d - int(c.get("ended_day", d)) <= int(cfg().keep_days))
	npc_orders()


## A villager died: its contracts end and the coins set aside go back to the buyer first (a dead buyer's pass on with
## the rest of what it leaves: World.kill calls this before the inheritance).
func on_death(n: NPC) -> void:
	var me := World.npc_ref(n.id)
	for c in list:
		if (is_open(c) or str(c.state) == "offered") and (c.buyer == me or c.seller == me):
			_end(c, "cancelled", "%s died" % n.name)


## The player died: their contracts end; coins they set aside go back to their purse (left where they fell, with the
## rest: World.continue_as_heir), coins villagers set aside for the player's goods go back to them.
func on_player_died() -> void:
	for c in list:
		if (is_open(c) or str(c.state) == "offered") and (c.buyer == World.PLAYER or c.seller == World.PLAYER):
			_end(c, "cancelled", "the player died")


# ---------------------------------------------------------------- villagers at work ----------
## A villager with an open contract works toward it (NPCBrain.decide, working hours): it delivers what it holds (a lot
## at a time, or all that is still owed), then gets more by the contract's route: mines the ore, fells a tree, makes
## the recipe or buys from a seller. Harvests and stock come from its usual work (false: its trade plans the day).
func plan(n: NPC) -> bool:
	var me := World.npc_ref(n.id)
	for c in list:
		if not is_open(c) or c.seller != me or not _alive(c.buyer):
			continue
		var owed := left(c)
		var held := n.inv.count(c.item)
		var lot := mini(owed, int(cfg().delivery_lot))
		var home_ok: bool = c.buyer != World.PLAYER or (w.player.home != "" and w.buildings.has(w.player.home))
		if held >= lot and home_ok:
			n.doing = "delivering %s to %s" % [GameData.item_name(c.item).to_lower(), w.ref_name(c.buyer)]
			var at: Vector2i = w.building_door(w.player.home) if c.buyer == World.PLAYER else w.brain._workplace_cell(_npc_of(c.buyer))
			n.plan = [w.brain.go(at), w.brain.doit("contract_deliver", {"id": int(c.id)})]
			return true
		if held >= owed:
			continue                                  # all in hand: the player collects it (no home to bring it to)
		match str(c.route):
			"mine":
				var d: Dictionary = w.nearest_seam(n, [c.item]) if n.inv.has("pickaxe") else {}     # MIN-A/B: any level, quarry rock too
				if not d.is_empty():
					n.doing = "mining %s for %s" % [GameData.item_name(c.item).to_lower(), w.ref_name(c.buyer)]
					n.plan = w.brain.seam_steps(n, d, "mine", {})
					return true
			"chop":
				var t: Dictionary = w.nearest_tree(n.cell(), 70.0) if n.inv.has("axe") else {}
				if not t.is_empty():
					t.claimed = n.id
					var at := Vector2i(int(t.x), int(t.y))
					n.doing = "felling a tree for %s" % w.ref_name(c.buyer)
					n.plan = [w.brain.go(w.brain.beside(at, n.cell())), w.brain.work(float(GameData.b("chop_minutes")) * Skills.value(n, "woodcutting", "chop_time", 1.0),
							"chop", {"x": t.x, "y": t.y}, "work", at)]
					return true
			"craft":
				var r := str(c.recipe)
				if GameData.recipes.has(r) and n.inv.has_all(GameData.recipes[r]["in"]) and w.brain._do_recipe(n, r):
					n.doing = "making %s for %s" % [GameData.item_name(c.item).to_lower(), w.ref_name(c.buyer)]
					return true
			"buy":
				var v := _vendor(n, c.item, int(c.price_each))
				if v != null and n.coins - w.reserve_of(n) >= w.deal_price(w.sell_price(v, c.item), n, v):
					n.doing = "buying %s for %s" % [GameData.item_name(c.item).to_lower(), w.ref_name(c.buyer)]
					n.plan = [w.brain.go(w.brain._workplace_cell(v)), w.brain.doit("buy_from", {"vendor": v.id, "item": c.item, "qty": owed - held})]
					return true
	return false


## NPC to NPC (parity): each dawn a few businesses (npc_orders_per_day, in villager order) holding none of an input their
## trade works and wants, which nobody in the village has for sale, order it by the same offer (order_input). A buyer
## with an open order or a standing offer orders nothing more.
func npc_orders() -> void:
	var made := 0
	for b: NPC in w.npcs:
		if made >= int(cfg().npc_orders_per_day):
			return
		if order_input(b):
			made += 1


## One business's order: the first input (in id order) it lacks, wants a batch of (NPCBrain.wants) and cannot buy from
## anyone (_vendor), at its price (its buying price, at least the item's value), as many as its coins above its OD-19
## reserve set aside. Offered to each villager in turn: the first who accepts, or whose counter it can meet within
## npc_counter_tolerance, takes it; with nobody able, the offer stands for the player (offer_to_player). True if an
## order was made or offered.
func order_input(b: NPC) -> bool:
	if not b.alive or b.role != "adult" or not open_of(World.npc_ref(b.id), "buyer").is_empty() or _offered_by(b):
		return false
	var buys: Dictionary = NPCBrain.BUYS.get(w.brain.buy_role(b), {})
	var ids := buys.keys()
	ids.sort()
	for id in ids:
		var unit: int = w.brain.batch_unit(b, id)
		var want: int = w.brain.wants(b, id)
		if b.inv.count(id) > 0 or unit <= 0 or want < unit or _vendor(b, id) != null:
			continue
		var price: int = maxi(w.deal_price(World.buy_price_at(id, 0), b, null), GameData.value(id))
		var qty := want
		while qty > 0 and fund_refusal(World.npc_ref(b.id), qty * price) != "":
			qty -= 1
		if qty < unit:
			continue
		_order(b, id, qty, price, int(cfg().npc_order_days))
		return true
	return false


func _offered_by(b: NPC) -> bool:
	var me := World.npc_ref(b.id)
	return list.any(func(c): return str(c.state) == "offered" and c.buyer == me)


func _order(b: NPC, id: String, qty: int, price: int, days: int) -> bool:
	var me := World.npc_ref(b.id)
	for s: NPC in w.npcs:
		if s == b or not s.alive or s.role != "adult":
			continue
		var r := propose(me, s, id, qty, price, days)
		if r.has("contract"):
			return true
		if str(r.answer) == "counter" and int(r.qty) >= w.brain.batch_unit(b, id) \
				and float(r.price_each) <= float(price) * float(cfg().npc_counter_tolerance) and int(r.days) <= int(cfg().max_days):
			r = propose(me, s, id, int(r.qty), int(r.price_each), int(r.days), r.history)
			if r.has("contract"):
				return true
	offer_to_player(b, id, qty, price, days)
	return false


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	return {"next_id": next_id, "list": list.duplicate(true)}


## Older saves have no contracts: none open, nothing set aside.
func load_dict(d: Dictionary) -> void:
	next_id = int(d.get("next_id", 1))
	list = []
	for c in d.get("list", []):
		var r: Dictionary = c.duplicate(true)
		for k in ["id", "qty", "price_each", "days", "deadline_day", "delivered", "paid", "reserved", "made_day"]:
			r[k] = int(r.get(k, 0))
		if r.has("ended_day"):
			r.ended_day = int(r.ended_day)
		list.append(r)
