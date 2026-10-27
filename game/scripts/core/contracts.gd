class_name Contracts
extends RefCounted
## CON-01 (owner directive 2026-10-21 section 5; defaults OD-29, approved provisionally): negotiated goods-procurement
## contracts, the first slice (goods only). One character offers another payment for a quantity of an item: item,
## quantity and price per unit, and a deadline, all chosen by the buyer. It is an offer, not a command: the seller
## accepts, rejects with its reason, or counteroffers (price, quantity or a later deadline), judged from what it can
## really do (evaluate). The same record and the same rules serve player to NPC, NPC to player and NPC to NPC.
##
## Evaluation weighs each of the directive's questions from signals that already exist (no judgment system: that is
## Expansion 19's, and plugs into price_terms): can it come by the goods (means: stock, mining, felling, its field,
## a recipe, a seller), skills and tools, the quantity by the deadline (work time, less a risk_margin), the price
## against the going price, the inputs' cost and its usual earnings (alternatives), its existing obligations (open
## contracts, manor tool orders, a manor job, a site's carrying, a stall post), its household's needs (OD-19), its tie
## with the buyer (friends, partners and kin get a friend's price) and risk (payment is set aside; a buyer who ended
## contracts with it early pays more). Counters go both ways: a seller counters a buyer (evaluate), and a villager
## buyer answers a seller's counter, or the player's counter to its standing offer, by one rule (buyer_answer).
##
## Services (CON-02, owner 2026-10-21): a contract may be for work instead of goods (kind "service"): the same record,
## evaluation, counters, signing, reservation, lapse and save, with the work's own part in ContractServices (what a
## seller can do, the going rate, how a villager does the next unit through the existing work system). A unit of work
## is paid, like a unit of goods, only when it is really done (_pay_units, the one place a contract pays).
##
## The record is the Living Economy design's Contract (docs/build17/PROCUREMENT_CONTRACTS.md section 3) in its
## smallest form: {id, buyer, seller (World refs: "player", "npc:<id>", "manor"), item, qty, price_each, deadline_day,
## terms {pay, partial, all_at_once, deposit}, state (offered, signing, accepted, fulfilled, lapsed,
## cancelled), delivered,
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
## Signing (owner Q18-13, 2026-10-21): an ordinary small agreement (under formal_total coins, a provisional line) is
## concluded where it is made; a formal contract only face to face (face_to_face; the manor by its reeve), never
## remotely and at once. The player proposes or accepts one in person through the talk window; a villager buyer whose
## formal order is agreed in principle at a distance holds a "signing" record (nothing set aside) and walks to the
## seller (plan, act "contract_sign", npc_sign), where the seller answers afresh; one never signed within offer_days
## lapses. A courier-notary for parties who cannot meet is Expansion 18's (X18-Q13) and not built.
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
	if who is PlayerState and (who as PlayerState).party != "":
		return (who as PlayerState).party            # MP C3: a guest is its own party ("player:<line>")
	return World.PLAYER


## The relations id of a party (a player's person id: -2 the host's line), or -1 for the manor.
static func rel_id(ref: String) -> int:
	if World.is_player_ref(ref):
		return World.id_of_ref(ref) if World.id_of_ref(ref) != -1 else Life.PLAYER_ID
	return World.ref_id(ref) if ref.begins_with("npc:") else -1


func _npc_of(ref: String) -> NPC:
	return w.npc(World.ref_id(ref)) if ref.begins_with("npc:") else null


func _alive(ref: String) -> bool:
	if World.is_player_ref(ref) or ref == World.MANOR:
		return true
	var n := _npc_of(ref)
	return n != null and n.alive


func _coins(ref: String) -> int:
	if World.is_player_ref(ref):
		return w.player_for(ref).coins
	if ref == World.MANOR:
		return w.treasury
	var n := _npc_of(ref)
	return n.coins if n else 0


func _add_coins(ref: String, k: int) -> void:
	if World.is_player_ref(ref):
		w.player_for(ref).coins += k
	elif ref == World.MANOR:
		w.treasury += k
	else:
		_npc_of(ref).coins += k


func _pack(ref: String) -> Inventory:
	if World.is_player_ref(ref):
		return w.player_for(ref).inv
	var n := _npc_of(ref)
	return n.inv if n else null


## Q18-13 (owner, 2026-10-21): formal commercial contracts are signed, ordinary small agreements are not. The line is a
## provisional agent default (docs/build17/CON01_COMPLETION.md): a contract worth formal_total coins or more is formal.
static func formal(total: int) -> bool:
	return total >= int(cfg().formal_total)


## The body that stands for a party when signing: the villager, the player, or for the manor its reeve (the manor's
## representative the game already uses). null when there is none.
func _signer(ref: String):
	if World.is_player_ref(ref):
		return w.player_for(ref) if w.player_for(ref).alive else null
	if ref == World.MANOR:
		var r := w.npc(w.reeve_id)
		return r if r != null and r.alive else null
	var n := _npc_of(ref)
	return n if n != null and n.alive else null


## Q18-13: the two parties (or the manor's reeve) are face to face: within sign_reach tiles of each other, in the same
## place and on the same level (World.present's rule). No remote instant signing: a formal contract is concluded only
## so. A courier-notary carrying documents to a party who cannot meet is Expansion 18's (X18-Q13), not built here.
func face_to_face(a_ref: String, b_ref: String) -> bool:
	var a = _signer(a_ref)
	var b = _signer(b_ref)
	if a == null or b == null or a == b:
		return false
	var reach := float(cfg().sign_reach)
	if a is NPC and b is NPC:
		return w.present((a as NPC).pos, reach).has(b)
	if a is PlayerState and b is PlayerState:          # MP-INTERACT-01: two players, each where they stand
		var pa: PlayerState = a
		var pb: PlayerState = b
		return pa.map_level == pb.map_level and w.place_of(pa.pos) == w.place_of(pb.pos) and pa.pos.distance_to(pb.pos) <= reach
	var n: NPC = b if a is PlayerState else a
	return w.present(w.player.pos, reach).has(n)


## Whether `buyer_ref` already has an order for `id` (any item when "") open, offered or waiting to be signed.
func waiting_on(buyer_ref: String, id := "") -> bool:
	for c in list:
		if c.buyer == buyer_ref and str(c.state) in ["accepted", "offered", "signing"] and (id == "" or c.item == id):
			return true
	return false


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
		if str(c.state) in ["accepted", "offered"] and ((World.is_player_ref(c.buyer) and c.seller == me) or (World.is_player_ref(c.seller) and c.buyer == me)):
			out.append(c)
	return out


## The units of `id` villager `n` still owes on its open contracts: stock it keeps back from sale (NPCBrain.reserve).
func held_for(n: NPC, id: String) -> int:
	return held_for_ref(World.npc_ref(n.id), id)


## The same by actor ref (a villager's "npc:<id>" or the player's): the one read of what a seller still owes. The economy
## foundation's reservations read it, so a reservation can never cover goods a contract already holds (RECON-01).
func held_for_ref(ref: String, id: String) -> int:
	var k := 0
	for c in list:
		if is_open(c) and c.seller == ref and c.item == id:
			k += left(c)
	return k


## Coins set aside for open contracts (part of the village's money, not spendable; World.total_coins).
func reserved_total() -> int:
	var t := 0
	for c in list:
		t += int(c.get("reserved", 0))
	return t


# ---------------------------------------------------------------- evaluation -----------------
## What `n` has already promised (the directive's "existing obligations"), read from every mechanism that binds a
## villager's time, so the one evaluation weighs them all while each stays settled by its own module: its open
## contracts as seller; the manor's tool orders it is forging (EQ-19, World.manor_orders); a manor job (ManorWork); a
## day's carrying at a building site (Construction); a post at the player's stall (Business).
func obligations(n: NPC) -> Dictionary:
	var me := World.npc_ref(n.id)
	return {"contracts": open_of(me, "seller").size(),
		"tool_orders": w.manor_orders.filter(func(x): return int(x.smith) == n.id).size(),
		"manor_job": not w.manor_work.job_of(me).is_empty(),
		"site": not w.construction.contract_of(n).is_empty(),
		"attendant": w.business != null and w.business.is_attendant(n)}


## Game minutes a villager can give contract work from now to the end of day `deadline_day` (work hours only, a
## share of them: walking, eating and other work take the rest), split with its other open contracts and the tool
## orders it is forging; today is already promised if it holds a manor job, a site's carrying or a stall post.
func _work_minutes(n: NPC, days: int) -> float:
	var day_len := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var now := fmod(w.minutes, World.DAY)
	var today := clampf(NPCBrain.WORK_END * 60.0 - maxf(now, NPCBrain.WORK_START * 60.0), 0.0, day_len)
	var mins := (today + float(maxi(0, days - 1)) * day_len) * float(cfg().work_share)
	var ob := obligations(n)
	if ob.manor_job or ob.site or ob.attendant:
		mins -= minf(today, mins)
	return mins / float(1 + int(ob.contracts) + int(ob.tool_orders))


## Units of work time can be trusted to give, with a margin kept for what may go wrong (the directive's "risk and
## uncertainty": a seam that runs thin, a tree farther off, a slow day): risk_margin of the estimate is not promised.
static func _by_time(units: float) -> int:
	return floori(units / (1.0 + float(cfg().risk_margin)))


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
			out.cap = mini(w.quests.deposit_left(id), _by_time(float(out.rate) * mins))
			out.route = "mine"
	elif id == "log":
		if not n.inv.has("axe"):
			out.why = "tool:axe"
		elif w.nearest_tree(n.cell(), 70.0).is_empty():
			out.why = "source"
		else:
			out.rate = (4.0 + Skills.value(n, "woodcutting", "log_bonus")) / (float(GameData.b("chop_minutes")) * Skills.value(n, "woodcutting", "chop_time", 1.0))
			out.cap = _by_time(float(out.rate) * mins)
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
			var by_time := _by_time(mins / (float(rec.minutes) * Skills.value(n, str(rec.skill), "craft_time", 1.0))) * per
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


## The goods route (means) or, for a service, ContractServices.means: one shape for evaluate.
func _means(n: NPC, id: String, days: int, price_each: int, svc: Dictionary) -> Dictionary:
	return means(n, id, days, price_each) if svc.is_empty() else ContractServices.means(self, n, svc, days)


## A stand-in record for the words of a service not yet agreed.
func _svc_rec(buyer_ref: String, svc: Dictionary, qty: int) -> Dictionary:
	return {"buyer": buyer_ref, "service": svc.service, "site": svc.get("site", {}), "qty": qty}


## A contract in words: "8 iron ore" or "dig 6 from your open pit north of the mine".
func describe(c: Dictionary) -> String:
	if is_service(c):
		return ContractServices.words(self, c)
	return "%d %s" % [int(c.qty), GameData.item_name(str(c.item)).to_lower()]


static func is_service(c: Dictionary) -> bool:
	return str(c.get("kind", "goods")) == "service"


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


## The least `n` takes for a unit of `id` from `buyer_ref` (price_terms' "min").
func min_price(n: NPC, buyer_ref: String, id: String, m: Dictionary, svc := {}) -> int:
	return int(price_terms(n, buyer_ref, id, m, svc).min)


## How `n` prices a unit of `id` for `buyer_ref`, term by term (the directive's list; every input already exists):
##  going        what the goods would fetch anyway: the item's value, or what its best buyer pays now;
##  cost         what the unit costs it: a bought unit's price and a coin, or a recipe's inputs at their value;
##  alternatives what the same work time earns it in its usual trade (its average daily income over the last days,
##               NPC.avg_income, spread over the units a day's contract work yields), times opportunity_weight;
##  household    its household's needs (OD-19): short of its reserve it takes a sure income for less (needy_factor),
##               with its reserve covered it asks the full price (comfortable_factor);
##  relationship a friend, partner or kin is given the friend's price (Relations friend_price), as a friend carries
##               for free (CRT-06);
##  risk         payment is no risk (the buyer's coins are set aside at acceptance); a buyer who ended a contract
##               with it early within keep_days is asked cancel_premium more for each such contract.
## min = the largest of going, cost and alternatives, times (household - relationship + risk), at least a coin.
## Deterministic: no random draws. A judgment system (memory, trust, reputation) is Expansion 19's and plugs in here.
func price_terms(n: NPC, buyer_ref: String, id: String, m: Dictionary, svc := {}) -> Dictionary:
	var going := float(GameData.value(id)) if svc.is_empty() else ContractServices.going(svc)   # CON-02: the job board's rate for the work
	var b: NPC = w.brain._buyer_for(n, id) if svc.is_empty() and NPCBrain.OUTLETS.has(id) and n.inv.has(id) else null
	if b != null:
		var p: Array = w.sale_prices(b, n, id, 1)
		if not p.is_empty():
			going = maxf(going, float(p[0]))
	var cost := 0.0
	if str(m.route) == "service":
		cost = float(m.cost)                       # CON-02: what the seller pays out for a unit of the work (an assay fee)
	elif str(m.route) == "buy":
		cost = float(m.cost) + 1.0
	elif str(m.route) == "craft" and GameData.recipes.has(str(m.recipe)):
		var rec: Dictionary = GameData.recipes[str(m.recipe)]
		for i in rec["in"]:
			cost += float(GameData.value(i)) * float(rec["in"][i])
		cost /= maxf(1.0, float(rec.out[id]))
	var alt := 0.0
	if float(m.rate) > 0.0:
		var per_day := float(m.rate) * (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0 * float(cfg().work_share)
		alt = n.avg_income() / per_day * float(cfg().opportunity_weight)
	var household := float(cfg().needy_factor) if n.coins < w.reserve_of(n) else float(cfg().comfortable_factor)
	var rid := rel_id(buyer_ref)
	var close := rid != -1 and close_to(n, rid)
	var relationship := float(Relations.cfg().friend_price) if close else 0.0
	var let_down := ended_early_by(buyer_ref, World.npc_ref(n.id))
	var risk := float(cfg().cancel_premium) * float(let_down)
	var f := household - relationship + risk
	return {"going": going, "cost": cost, "alternatives": alt, "household": household, "close": close, "relationship": relationship,
		"cancelled_on_me": let_down, "risk": risk, "min": maxi(1, roundi(maxf(going, maxf(cost, alt)) * f))}


## A friend, partner or kin of `n` (Relations, Life.kin): the ties that get a friend's price.
func close_to(n: NPC, rid: int) -> bool:
	if w.relations.friends(rid, n.id) or n.partner == rid:
		return true
	if Life.is_player_id(rid):
		var pl: PlayerState = w.player_of_id(rid)             # MP C3: that player, whoever is acting
		return pl != null and (pl.partner == n.id or Life.kin(n.id, n.mother, n.father, rid, pl.mother, pl.father))
	var o := w.npc(rid)
	return o != null and Life.kin(n.id, n.mother, n.father, o.id, o.mother, o.father)


## Contracts `buyer_ref` ended early with `seller_ref` (cancelled after acceptance by the buyer) still on record.
func ended_early_by(buyer_ref: String, seller_ref: String) -> int:
	var k := 0
	for c in list:
		if str(c.state) == "cancelled" and c.buyer == buyer_ref and c.seller == seller_ref and not (c.history as Array).is_empty():
			var last: Dictionary = c.history[-1]
			if str(last.what) == "cancel" and str(last.by) == buyer_ref:
				k += 1
	return k


## The seller's answer to an offer, the one judgment for every buyer (the player, a villager or the manor):
## {answer: "accept" | "counter" | "reject", say (its words), qty, price_each, days, route, recipe, min_price}.
## Hard limits: it never accepts what it cannot do. A counter offers its least price, the quantity it can manage, or
## the later deadline that makes the whole quantity possible.
## `terms` records each of the directive's questions as judged (feasible, route, why, capacity, obligations, the price
## terms of price_terms), so a test or a later judgment system can read why the answer was given.
## CON-02: `svc` ({service, site}) asks for work instead of goods (`id` ""): the same judgment, with the service's
## means (ContractServices.means) and its going rate.
func evaluate(n: NPC, buyer_ref: String, id: String, qty: int, price_each: int, days: int, svc := {}) -> Dictionary:
	var r := {"answer": "reject", "say": "", "qty": qty, "price_each": price_each, "days": days, "route": "", "recipe": "", "min_price": 0, "terms": {}}
	if n == null or not n.alive:
		r.say = "There is nobody to answer."
		return r
	if n.role != "adult":
		r.say = "I'm too young to take that on." if n.role == "child" else "I'm past taking on work like that."
		return r
	var site_why := "" if svc.is_empty() else ContractServices.site_refusal(self, buyer_ref, svc)
	if buyer_ref == World.npc_ref(n.id) or (svc.is_empty() and GameData.item(id).is_empty()) or site_why != "" \
			or qty <= 0 or price_each <= 0 or days <= 0:
		r.say = site_why if site_why != "" else "That's no kind of offer."
		return r
	if World.is_player_ref(buyer_ref) and w.relations.notoriety() >= int(cfg().notoriety_refuse):
		r.say = "I'll not deal with you. Folk say what you've done."
		return r
	var ob := obligations(n)
	r.terms.obligations = ob
	if int(ob.contracts) >= int(cfg().max_open_per_seller):
		r.say = "I've promised all the work I can take on already."
		return r
	var bare := GameData.item_name(id).to_lower() if svc.is_empty() else "that work"
	var item := _phrase(bare)
	var m := _means(n, id, days, price_each, svc)
	var can := int(m.stock) + int(m.cap)
	r.route = m.route
	r.recipe = m.recipe
	var pt := price_terms(n, buyer_ref, id, m, svc)
	r.min_price = int(pt.min)
	r.terms.merge(pt)
	r.terms.merge({"route": m.route, "why": m.why, "stock": m.stock, "capacity": m.cap})
	if can <= 0 and not (float(m.rate) > 0.0 and str(m.route) in ["mine", "chop", "craft", "service"]):
		match str(m.why):
			"tool:pickaxe", "tool:axe", "tool:shovel":
				r.say = ("I've no %s to get %s with." % [str(m.why).get_slice(":", 1), item]) if svc.is_empty() else ("I've no %s for that work." % str(m.why).get_slice(":", 1))
			"tool:kit":
				r.say = "I've no prospector's kit to take samples with."
			"skill":
				r.say = "I haven't the skill for %s." % item
			"station":
				r.say = "I've nowhere to make %s." % item
			"materials":
				r.say = "I've not the makings of %s, and nobody sells them cheap enough." % item
			"coins":
				r.say = "I'd have to buy %s, and I can't spare the coins to." % item
			"source":
				r.say = "There's no %s to be had where I could get it." % bare
			_:
				r.say = "I've no way to come by %s." % item
		return r
	var c_qty := qty
	var c_days := days
	if can < qty:
		# time-bound work (mining, felling, making) may manage it all, or at least something, given more days
		var more := days
		var by_more := can
		if float(m.rate) > 0.0 and str(m.route) in ["mine", "chop", "craft", "service"]:
			while more < int(cfg().max_days) and by_more < qty:
				more += 1
				by_more = int(_means(n, id, more, price_each, svc).cap) + int(m.stock)
		if by_more >= qty:
			c_days = more
		elif can > 0:
			c_qty = can
		elif by_more > 0:
			c_days = more                                # nothing by its deadline (the time is promised elsewhere)
			c_qty = by_more
		else:
			r.say = "I've not the time to get %s by then, with what I've promised already." % item
			r.terms.why = "time"
			return r
	if w.judgment != null and JudgmentLive.on(w, "contract_accept"):        # PROSPECTIVE (PROS-19, Q14): off unless judgment is attached
		var unwilling := JudgmentLive.contract_refusal(w, n, buyer_ref)
		if unwilling != "":
			r.say = unwilling
			r.terms.judgment = true
			return r
	var c_price := maxi(price_each, int(r.min_price))
	if c_qty == qty and c_days == days and c_price == price_each:
		r.answer = "accept"
		if svc.is_empty():
			r.say = "Done. %d %s at %d each, by the end of day %d." % [qty, item, price_each, w.day() + days]
		else:
			r.say = "Done: I'll %s, %d a unit, by the end of day %d." % [ContractServices.words(self, _svc_rec(buyer_ref, svc, qty)), price_each, w.day() + days]
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


## A noun phrase for an item name in a refusal: plural and mass goods stand bare ("coal", "nails"), the rest take
## "a"/"an" ("an axe"). Wording only.
static func _phrase(name: String) -> String:
	if name == "that work" or name in ["ale", "coal", "cheese", "dirt", "leather", "milk", "pottage", "spoil", "stone", "topsoil", "wheat", "wool", "feathers", "nails"]:
		return name
	for tail in [" ore", " meat", " cloth", " clothes", "berries"]:
		if name.ends_with(tail):
			return name
	return ("an " if name.substr(0, 1) in ["a", "e", "i", "o", "u"] else "a ") + name


## `qty` of an item name, counted ("3 axes", "1 axe", "10 coal"): mass and plural goods stand bare as in _phrase.
## Wording only.
static func counted(qty: int, name: String) -> String:
	if qty == 1 or _phrase(name) == name:
		return "%d %s" % [qty, name]
	if name.ends_with("s") or name.ends_with("x") or name.ends_with("ch") or name.ends_with("sh"):
		return "%d %ses" % [qty, name]
	if name.ends_with("y") and not name.substr(name.length() - 2, 1) in ["a", "e", "i", "o", "u"]:
		return "%d %sies" % [qty, name.substr(0, name.length() - 1)]
	return "%d %ss" % [qty, name]


# ---------------------------------------------------------------- making a contract ----------
## Why `buyer_ref` cannot set `total` coins aside now ("" when it can): the player from their purse; a villager only
## from what is left above its OD-19 reserve (a purchase for its trade, World.can_afford's rule); the manor from the
## treasury.
func fund_refusal(buyer_ref: String, total: int) -> String:
	if World.is_player_ref(buyer_ref):
		return "" if w.player_for(buyer_ref).coins >= total else "You haven't %d coins to set aside for it." % total
	if buyer_ref == World.MANOR:
		return "" if w.treasury >= total else "The manor cannot set aside %d coins." % total
	var b := _npc_of(buyer_ref)
	if b == null or not b.alive:
		return "The buyer is gone."
	return "" if b.coins - total >= w.reserve_of(b) else "%s cannot set aside %d coins without touching what the household needs." % [b.name, total]


func _new_record(buyer_ref: String, seller_ref: String, id: String, qty: int, price_each: int, days: int, history: Array, svc := {}) -> Dictionary:
	var c := {"id": next_id, "buyer": buyer_ref, "seller": seller_ref, "item": id, "qty": qty, "price_each": price_each,
		"days": days, "deadline_day": w.day() + days - 1, "state": "offered", "delivered": 0, "paid": 0, "reserved": 0, "route": "",
		"recipe": "", "made_day": w.day(),
		"terms": {"pay": "on_delivery", "partial": true, "all_at_once": false, "deposit": 0},
		"history": history.duplicate(true)}
	if not svc.is_empty():                         # CON-02: a service, paid per unit of work done from the same reservation
		c.kind = "service"
		c.item = ""
		c.service = str(svc.service)
		c.site = (svc.get("site", {}) as Dictionary).duplicate(true)
		c.load = {}
		c.sids = []
	next_id += 1
	return c


## An offer from `buyer_ref` to villager `n`: it is judged (evaluate) and, if accepted, the contract opens with the
## buyer's coins set aside. Returns the evaluation plus "contract" (the record) when one opened, or a refusal
## ("answer": "refused", "say") when the buyer cannot make the offer. `history` carries earlier rounds of the talk.
func propose(buyer_ref: String, n: NPC, id: String, qty: int, price_each: int, days: int, history := [], svc := {}) -> Dictionary:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("contracts.propose", propose.bind(buyer_ref, n, id, qty, price_each, days, history, svc), [buyer_ref, n, id, qty, price_each, days, history, svc])
	if World.is_player_ref(buyer_ref) and open_of(w.acting_ref(), "buyer").size() >= int(cfg().max_open_player):
		return {"answer": "refused", "say": "You have as many contracts open as you can keep track of (%d)." % int(cfg().max_open_player)}
	var why := fund_refusal(buyer_ref, qty * price_each)
	if why != "":
		return {"answer": "refused", "say": why}
	var hist: Array = history.duplicate(true)
	hist.append({"day": w.day(), "by": buyer_ref, "what": "offer", "qty": qty, "price_each": price_each, "days": days})
	var r := evaluate(n, buyer_ref, id, qty, price_each, days, svc)
	hist.append({"day": w.day(), "by": World.npc_ref(n.id), "what": str(r.answer), "qty": int(r.qty), "price_each": int(r.price_each), "days": int(r.days)})
	r.history = hist
	if r.answer != "accept":
		return r
	var seller_ref := World.npc_ref(n.id)
	if formal(qty * price_each) and not face_to_face(buyer_ref, seller_ref):
		# Q18-13: no remote instant signing. Agreed in principle only; nothing is set aside until they meet.
		if World.is_player_ref(buyer_ref):
			return {"answer": "meet", "say": "A contract worth %d coins is signed face to face. Come and see me." % (qty * price_each), "history": hist}
		var p := _new_record(buyer_ref, seller_ref, id, qty, price_each, days, hist, svc)
		p.state = "signing"
		p.route = r.route
		p.recipe = r.recipe
		list.append(p)
		w.stat("contracts_to_sign")
		r.signing = p
		return r
	var c := _new_record(buyer_ref, seller_ref, id, qty, price_each, days, hist, svc)
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
	if is_service(c):
		w.stat("service_contracts_made")
		if s:
			s.remember("promised to %s for %s" % [describe(c), w.ref_name(c.buyer)])
		var bs := _npc_of(c.buyer)
		if bs:
			bs.remember("hired %s to %s" % [w.ref_name(c.seller), describe(c)])
		w.stat("contracts_made")
		w.note("%s agreed to %s for %s at %d a unit by day %d." % [w.ref_name(c.seller, true), describe(c), w.ref_name(c.buyer), int(c.price_each), int(c.deadline_day) + 1])
		return true
	if s:
		s.remember("promised %d %s to %s" % [int(c.qty), GameData.item_name(c.item).to_lower(), w.ref_name(c.buyer)])
	var b := _npc_of(c.buyer)
	if b:
		b.remember("ordered %d %s from %s" % [int(c.qty), GameData.item_name(c.item).to_lower(), w.ref_name(c.seller)])
	w.stat("contracts_made")
	w.note("%s agreed to supply %s with %d %s at %d each by day %d." % [w.ref_name(c.seller, true), w.ref_name(c.buyer), int(c.qty),
			GameData.item_name(c.item).to_lower(), int(c.price_each), int(c.deadline_day) + 1])
	return true


## MP-INTERACT-01 (owner, 2026-10-27): a contract between two players, agreed by both (the buyer's offer and the seller's
## acceptance are World.player_offer and player_answer, MP-D8's consent). The same record and rules as with a villager: the
## buyer's coins are set aside now, the seller is paid unit by unit on delivery (deliver), partial delivery, either may cancel
## (cancel), past its deadline it lapses at dawn with the coins back to the buyer; a formal one only face to face; each side's
## limit of open contracts. Goods only (a service between players has no way for a player to do the units: CON-02's work is a
## villager's). Returns the open record, or the reason it could not open (nothing set aside or recorded).
func open_between(buyer_ref: String, seller_ref: String, id: String, qty: int, price_each: int, days: int) -> Variant:
	if not World.is_player_ref(buyer_ref) or not World.is_player_ref(seller_ref) or buyer_ref == seller_ref:
		return "That cannot be agreed."
	for r in [buyer_ref, seller_ref]:
		if open_of(r).size() >= int(cfg().max_open_player):
			return "%s as many contracts open as can be kept track of (%d)." % ["You have" if r == w.acting_ref() else w.ref_name(r, true) + " has", int(cfg().max_open_player)]
	if formal(qty * price_each) and not face_to_face(buyer_ref, seller_ref):
		return "A contract worth %d coins is signed face to face." % (qty * price_each)
	var why := fund_refusal(buyer_ref, qty * price_each)
	if why != "":
		return "%s cannot set aside %d coins for it." % [w.ref_name(buyer_ref, true), qty * price_each]
	var c := _new_record(buyer_ref, seller_ref, id, qty, price_each, days,
			[{"day": w.day(), "by": buyer_ref, "what": "offer", "qty": qty, "price_each": price_each, "days": days},
			 {"day": w.day(), "by": seller_ref, "what": "accept", "qty": qty, "price_each": price_each, "days": days}])
	if not _open(c):
		return "%s cannot set aside %d coins for it." % [w.ref_name(buyer_ref, true), qty * price_each]
	return c


## A villager's offer to the player (the player is the seller): kept as an "offered" record until the player accepts
## it (accept_offer), declines it, or it lapses after offer_days. Nothing is set aside until it is accepted.
func offer_to_player(b: NPC, id: String, qty: int, price_each: int, days: int, svc := {}) -> Dictionary:
	var c := _new_record(World.npc_ref(b.id), w.acting_ref(), id, qty, price_each, days,
			[{"day": w.day(), "by": World.npc_ref(b.id), "what": "offer", "qty": qty, "price_each": price_each, "days": days}], svc)
	list.append(c)
	w.stat("contract_offers_to_player")
	if svc.is_empty():
		w.note("%s is looking for %d %s at %d each, which nobody in the village can supply: ask them about a contract." % [w.ref_name(c.buyer, true),
				qty, GameData.item_name(id).to_lower(), price_each])
	else:
		w.note("%s would hire you to %s at %d a unit: ask them about a contract." % [w.ref_name(c.buyer, true), describe(c), price_each])
	return c


## The player takes up a villager's standing offer: its coins are set aside now. "" or the reason it cannot open.
func accept_offer(c: Dictionary, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("contracts.accept_offer", accept_offer.bind(c), [c])
	if actor != null and actor != w.player:
		return w.as_actor(actor, accept_offer.bind(c))
	if str(c.state) != "offered" or not World.is_player_ref(c.seller):
		return "That offer no longer stands."
	if open_of(w.acting_ref(), "seller").size() >= int(cfg().max_open_player):
		return "You have as many contracts open as you can keep track of (%d)." % int(cfg().max_open_player)
	if formal(int(c.qty) * int(c.price_each)) and not face_to_face(c.buyer, w.acting_ref()):
		return "A contract worth %d coins is signed face to face: go and see %s." % [int(c.qty) * int(c.price_each), w.ref_name(c.buyer)]
	var why := fund_refusal(c.buyer, int(c.qty) * int(c.price_each))
	if why != "" or not _open(c):
		_end(c, "cancelled", "the buyer can no longer pay")
		return why if why != "" else "They can no longer pay what they offered."
	c.history.append({"day": w.day(), "by": w.acting_ref(), "what": "accept", "qty": int(c.qty), "price_each": int(c.price_each), "days": int(c.days)})
	return ""


## The player, offered a villager's order (the player is the seller), puts other terms back. The villager answers by
## buyer_answer from the terms it first offered (the same rule villager buyers use on a seller's counter): if it agrees,
## the contract opens at the player's terms with its coins set aside ("contract" in the answer); a counter of its own
## becomes the standing offer's terms; a refusal leaves its offer standing as it was. Nothing is set aside before.
func counter_offer(c: Dictionary, qty: int, price_each: int, days: int, actor: PlayerState = null) -> Dictionary:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("contracts.counter_offer", counter_offer.bind(c, qty, price_each, days), [c, qty, price_each, days])
	if actor != null and actor != w.player:
		return w.as_actor(actor, counter_offer.bind(c, qty, price_each, days))
	if str(c.get("state", "")) != "offered" or not World.is_player_ref(c.seller):
		return {"answer": "refused", "say": "That offer no longer stands."}
	var b := _npc_of(c.buyer)
	var first: Dictionary = c.history[0] if not (c.history as Array).is_empty() else c
	var unit := 1 if is_service(c) else mini(maxi(1, w.brain.batch_unit(b, c.item)) if b != null else 1, int(first.qty))
	c.history.append({"day": w.day(), "by": w.acting_ref(), "what": "counter", "qty": qty, "price_each": price_each, "days": days})
	var r := buyer_answer(b, c.item, int(first.qty), int(first.price_each), unit, qty, price_each, days)
	c.history.append({"day": w.day(), "by": c.buyer, "what": str(r.answer), "qty": int(r.qty), "price_each": int(r.price_each), "days": int(r.days)})
	match str(r.answer):
		"accept":
			c.qty = qty
			c.price_each = price_each
			c.days = days
			var why := accept_offer(c)
			if why != "":
				return {"answer": "refused", "say": why}
			r.contract = c
		"counter":
			c.qty = int(r.qty)
			c.price_each = int(r.price_each)
			c.days = int(r.days)
	return r


## A villager buyer's answer to terms a seller puts back (a seller's counteroffer to its order, or the player's counter
## to its offer): the one rule every villager buyer uses. It takes no fewer than `unit` (what is of use to it) and no
## more than the `own_qty` it asked for, pays at most npc_counter_tolerance above `own_price`, waits at most max_days,
## and sets aside only coins above its OD-19 reserve (fund_refusal). Terms inside all of these are agreed; otherwise it
## counters with the nearest terms it would agree to, or refuses with its reason.
## {answer: "accept" | "counter" | "reject", say, qty, price_each, days}.
func buyer_answer(b: NPC, id: String, own_qty: int, own_price: int, unit: int, qty: int, price_each: int, days: int) -> Dictionary:
	var r := {"answer": "reject", "say": "", "qty": qty, "price_each": price_each, "days": days}
	if b == null or not b.alive or b.role != "adult":
		r.say = "There is nobody to answer."
		return r
	if qty <= 0 or price_each <= 0 or days <= 0:
		r.say = "That's no kind of offer."
		return r
	var item := GameData.item_name(id).to_lower() if id != "" else "units of work"
	if qty < unit:
		r.say = "Fewer than %d %s is no use to me." % [unit, item]
		return r
	var top := maxi(own_price, floori(float(own_price) * float(cfg().npc_counter_tolerance)))
	var c_qty := mini(qty, own_qty)
	var c_price := mini(price_each, top)
	var c_days := mini(days, int(cfg().max_days))
	var me := World.npc_ref(b.id)
	while c_qty >= unit and fund_refusal(me, c_qty * c_price) != "":
		c_qty -= 1
	if c_qty < unit:
		r.say = "I can't set aside the coins for that."
		return r
	if c_qty == qty and c_price == price_each and c_days == days:
		r.answer = "accept"
		r.say = "Agreed: %d %s at %d each in %d days." % [qty, item, price_each, days]
		return r
	r.answer = "counter"
	r.qty = c_qty
	r.price_each = c_price
	r.days = c_days
	var parts := []
	if c_price < price_each:
		parts.append("%d each is the most I'd pay" % c_price)
	if c_qty < qty:
		parts.append(("%d is all I want" if c_qty == own_qty else "%d is all I can pay for") % c_qty)
	if c_days < days:
		parts.append("I need them within %d days" % c_days)
	var said := "; ".join(parts) + "."
	r.say = said.substr(0, 1).to_upper() + said.substr(1)
	return r


func decline_offer(c: Dictionary) -> void:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		w.mirror("contracts.decline_offer", decline_offer.bind(c), [c])
		return
	if str(c.state) == "offered":
		c.history.append({"day": w.day(), "by": c.seller, "what": "decline", "qty": int(c.qty), "price_each": int(c.price_each), "days": int(c.days)})
		_end(c, "cancelled", "declined")


# ---------------------------------------------------------------- delivery -------------------
## Hand over up to `units` of the contract's item from the seller's pack to `into` (the buyer's pack, or the player's
## chest when delivered to their home), each unit paid from the coins set aside. One step: the goods move and the coins
## move, or nothing does. Returns the units delivered.
func deliver(c: Dictionary, units: int, into: Inventory = null, actor: PlayerState = null) -> int:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("contracts.deliver", deliver.bind(c, units, into), [c, units, into])
	if actor != null and actor != w.player:
		return w.as_actor(actor, deliver.bind(c, units, into))
	if not is_open(c) or not _alive(c.buyer) or not _alive(c.seller) or is_service(c):
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
	if World.is_player_ref(c.seller):
		w.player_for(c.seller).trim_stolen()
	to.add(c.item, units)
	_pay_units(c, units)
	return units


## `units` of a contract are done (goods handed over, or units of a service's work performed): each is paid from the
## coins set aside, never past qty or the reservation, and recorded; the last fulfils the contract (a service once
## nothing of the buyer's is still carried, ContractServices.finished). The one place a contract pays its seller.
func _pay_units(c: Dictionary, units: int) -> void:
	units = mini(units, left(c))
	var pay := units * int(c.price_each)
	if units <= 0 or pay > int(c.reserved):
		return
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
	if is_service(c):
		w.stat("service_units", units)
		w.stat("service_paid", pay)
	c.history.append({"day": w.day(), "by": c.seller, "what": "work" if is_service(c) else "deliver", "qty": units, "price_each": int(c.price_each), "days": 0})
	_maybe_finish(c)


## A contract with every unit done (a service also with nothing of the buyer's still carried) is fulfilled: a promise
## kept earns regard.
func _maybe_finish(c: Dictionary) -> void:
	if not is_open(c) or left(c) > 0 or (is_service(c) and not ContractServices.finished(c)):
		return
	_end(c, "fulfilled", "")
	if w.judgment != null:
		JudgmentLive.on_deal(w, "trade_fair", rel_id(c.seller), rel_id(c.buyer), int(c.paid))      # PROSPECTIVE (PROS-19): a promise kept
	var s := _npc_of(c.seller)
	var rid := rel_id(c.seller)
	var other := _npc_of(c.buyer)
	if other != null and rid != -1:
		w.relations.helped(rid, other, float(Relations.cfg().help_regard) * 0.5)    # a promise kept earns regard
	elif s != null and rel_id(c.buyer) != -1:
		w.relations.helped(rel_id(c.buyer), s, float(Relations.cfg().help_regard) * 0.5)


## The {service, site} of a service record ({} for goods).
static func svc_of(c: Dictionary) -> Dictionary:
	return {"service": str(c.service), "site": c.get("site", {})} if is_service(c) else {}


## A villager's service work step (NPCBrain act "svc_step"): ContractServices does the work through its system.
func svc_step(n: NPC, id: int) -> bool:
	var c := get_contract(id)
	if c.is_empty() or not is_open(c) or c.seller != World.npc_ref(n.id) or not is_service(c) or not _alive(c.buyer):
		return false
	return ContractServices.step(self, n, c)


## Goods carried for buyers on service contracts (the census counts them).
func goods() -> Dictionary:
	return ContractServices.goods(self)


## The villager buyer's signing at the end of its walk to the seller (NPCBrain act "contract_sign"; Q18-13). Face to
## face, the seller answers the offer afresh (evaluate: its means may have changed on the way); its counter is met by
## buyer_answer's rule. Agreed, the buyer's coins are set aside now and the contract runs from today; refused, the
## agreement ends with nothing set aside or moved. Not face to face (the seller has moved on): false, the buyer tries
## again. True when the meeting settled it either way.
func npc_sign(n: NPC, id: int) -> bool:
	var c := get_contract(id)
	var me := World.npc_ref(n.id)
	if c.is_empty() or str(c.state) != "signing" or c.buyer != me:
		return false
	var s := _npc_of(c.seller)
	if s == null or not s.alive:
		_end(c, "cancelled", "the seller is gone")
		return false
	if not face_to_face(me, c.seller):
		return false
	var r := evaluate(s, me, c.item, int(c.qty), int(c.price_each), int(c.days), svc_of(c))
	c.history.append({"day": w.day(), "by": c.seller, "what": str(r.answer), "qty": int(r.qty), "price_each": int(r.price_each), "days": int(r.days)})
	if str(r.answer) == "counter":
		var unit := 1 if is_service(c) else mini(maxi(1, w.brain.batch_unit(n, c.item)), int(c.qty))
		if str(buyer_answer(n, c.item, int(c.qty), int(c.price_each), unit, int(r.qty), int(r.price_each), int(r.days)).answer) == "accept":
			c.qty = int(r.qty)
			c.price_each = int(r.price_each)
			c.days = int(r.days)
			r.answer = "accept"
	if str(r.answer) != "accept" or fund_refusal(me, int(c.qty) * int(c.price_each)) != "" or not _open(c):
		c.history.append({"day": w.day(), "by": me, "what": "unsigned", "qty": int(c.qty), "price_each": int(c.price_each), "days": int(c.days)})
		_end(c, "cancelled", "not agreed when they met")
		w.stat("contracts_unsigned")
		return true
	c.route = r.route
	c.recipe = r.recipe
	c.history.append({"day": w.day(), "by": me, "what": "sign", "qty": int(c.qty), "price_each": int(c.price_each), "days": int(c.days)})
	w.stat("contracts_signed")
	return true


## The villager seller's delivery at the end of its walk (NPCBrain act "contract_deliver"): to a villager buyer's
## pack, or to the player's chest at their home.
func npc_deliver(n: NPC, id: int) -> bool:
	var c := get_contract(id)
	if c.is_empty() or c.seller != World.npc_ref(n.id):
		return false
	if World.is_player_ref(c.buyer):
		var bp: PlayerState = w.player_for(c.buyer)              # MP C3: the buyer's own chest, whoever is acting (a villager delivers)
		if bp.home == "" or not w.buildings.has(bp.home):
			return false
		return deliver(c, n.inv.count(c.item), bp.chest) > 0
	return deliver(c, n.inv.count(c.item)) > 0


# ---------------------------------------------------------------- ending ---------------------
## The coins still set aside go back to the buyer and the contract ends in `state`.
func _end(c: Dictionary, state: String, why: String) -> void:
	if is_service(c):
		ContractServices.release(self, c)          # CON-02: anything of the buyer's still carried goes back
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
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("contracts.cancel", cancel.bind(c, by_ref), [c, by_ref])
	if not is_open(c):
		return "That contract is not open."
	if by_ref != c.buyer and by_ref != c.seller:
		return "Only those who made it can end it."
	c.history.append({"day": w.day(), "by": by_ref, "what": "cancel", "qty": int(c.delivered), "price_each": int(c.price_each), "days": 0})
	_end(c, "cancelled", "ended by %s" % w.ref_name(by_ref))
	w.stat("contracts_cancelled")
	if is_service(c):
		w.note("%s ended the contract to %s (%d of %d done)." % [w.ref_name(by_ref, true), describe(c), int(c.delivered), int(c.qty)])
	else:
		w.note("%s ended the contract for %s (%d of %d delivered)." % [w.ref_name(by_ref, true), GameData.item_name(c.item).to_lower(), int(c.delivered), int(c.qty)])
	return ""


## Past its deadline: the contract lapses, the set-aside coins go back to the buyer, and the seller who let the buyer
## down loses regard with them (no money penalty, OD-29).
func _lapse(c: Dictionary) -> void:
	c.history.append({"day": w.day(), "by": "", "what": "lapse", "qty": int(c.delivered), "price_each": int(c.price_each), "days": 0})
	_end(c, "lapsed", "the deadline passed")
	w.stat("contracts_lapsed")
	if w.judgment != null:
		JudgmentLive.on_deal(w, "trade_cheat", rel_id(c.seller), rel_id(c.buyer), maxi(1, int(c.qty) - int(c.delivered)) * int(c.price_each))   # PROSPECTIVE (PROS-19): a promise broken
	var a := rel_id(c.buyer)
	var b := rel_id(c.seller)
	if a != -1 and b != -1:
		var t: Dictionary = w.relations.tie(a, b)
		w.relations._raise(t, -float(cfg().default_regard), 0.0, false, Vector2i(a, b))
	var buyer := _npc_of(c.buyer)
	if buyer:
		buyer.remember("let down by %s over %s" % [w.ref_name(c.seller), describe(c) if is_service(c) else GameData.item_name(c.item).to_lower()])
	if is_service(c):
		w.note("The contract for %s to %s for %s lapsed: %d of %d done." % [w.ref_name(c.seller), describe(c), w.ref_name(c.buyer), int(c.delivered), int(c.qty)])
	else:
		w.note("The contract for %d %s from %s to %s lapsed: %d delivered." % [int(c.qty), GameData.item_name(c.item).to_lower(),
				w.ref_name(c.seller), w.ref_name(c.buyer), int(c.delivered)])


## Dawn: contracts past their deadline lapse, offers to the player past offer_days are withdrawn, ended records older
## than keep_days are dropped, then businesses short of an input nobody sells may order it (npc_orders).
func dawn() -> void:
	var d: int = w.day()
	for c in list:
		if is_open(c) and d > int(c.deadline_day):
			_lapse(c)
		elif str(c.state) in ["offered", "signing"] and d - int(c.made_day) >= int(cfg().offer_days):
			_end(c, "cancelled", "the offer was not taken up" if str(c.state) == "offered" else "never signed")
	list = list.filter(func(c): return str(c.state) in ["accepted", "offered", "signing"] or d - int(c.get("ended_day", d)) <= int(cfg().keep_days))
	npc_orders()


## A villager died: its contracts end and the coins set aside go back to the buyer first (a dead buyer's pass on with
## the rest of what it leaves: World.kill calls this before the inheritance).
func on_death(n: NPC) -> void:
	var me := World.npc_ref(n.id)
	for c in list:
		if (is_open(c) or str(c.state) in ["offered", "signing"]) and (c.buyer == me or c.seller == me):
			_end(c, "cancelled", "%s died" % n.name)


## The player died: their contracts end; coins they set aside go back to their purse (left where they fell, with the
## rest: World.continue_as_heir), coins villagers set aside for the player's goods go back to them.
func on_player_died() -> void:
	for c in list:
		if (is_open(c) or str(c.state) == "offered") and (w.is_acting_ref(c.buyer) or w.is_acting_ref(c.seller)):     # MP Batch B: the dying player's own
			_end(c, "cancelled", "the player died")


# ---------------------------------------------------------------- villagers at work ----------
## A villager with an open contract works toward it (NPCBrain.decide, working hours): it delivers what it holds (a lot
## at a time, or all that is still owed), then gets more by the contract's route: mines the ore, fells a tree, makes
## the recipe or buys from a seller. Harvests and stock come from its usual work (false: its trade plans the day).
func plan(n: NPC) -> bool:
	var me := World.npc_ref(n.id)
	for c in list:
		# Q18-13: a buyer with a formal contract agreed in principle walks to the seller to sign it face to face
		if str(c.state) == "signing" and c.buyer == me:
			var s := _npc_of(c.seller)
			if s == null or not s.alive:
				continue
			n.doing = "going to %s to sign for %s" % [s.name, GameData.item_name(c.item).to_lower()]
			n.plan = [w.brain.go(w.brain.beside(s.cell(), n.cell(), s.depth), 1.0, s.depth), w.brain.doit("contract_sign", {"id": int(c.id)})]
			return true
	for c in list:
		if not is_open(c) or c.seller != me or not _alive(c.buyer):
			continue
		if is_service(c):
			if ContractServices.plan(self, n, c):    # CON-02: the work, through its own system
				return true
			continue
		var owed := left(c)
		var held := n.inv.count(c.item)
		var lot := mini(owed, int(cfg().delivery_lot))
		var home_ok: bool = not World.is_player_ref(c.buyer) or (w.player.home != "" and w.buildings.has(w.player.home))
		if held >= lot and home_ok:
			n.doing = "delivering %s to %s" % [GameData.item_name(c.item).to_lower(), w.ref_name(c.buyer)]
			var at: Vector2i = w.building_door(w.player.home) if World.is_player_ref(c.buyer) else w.brain._workplace_cell(_npc_of(c.buyer))
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
					n.plan = [w.brain.go(w.brain.beside(at, n.cell())), w.brain.work(CapabilityHook.work_time(float(GameData.b("chop_minutes")), "forestry", Skills.value(n, "woodcutting", "chop_time", 1.0), n),   # X18 HOOK: off in the game
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


## A villager buyer meets seller `s`'s counter `r` to its order (own_qty at own_price) if buyer_answer agrees to the
## counter's terms: the contract then opens on them (or, formal and at a distance, awaits signing face to face), with
## the talk on record. True if it did. Every villager order
## (businesses' inputs, MIN-C prospectors' kits) answers a counter through this.
func meet_counter(b: NPC, s: NPC, id: String, own_qty: int, own_price: int, unit: int, r: Dictionary) -> bool:
	if str(r.get("answer", "")) != "counter":
		return false
	if str(buyer_answer(b, id, own_qty, own_price, unit, int(r.qty), int(r.price_each), int(r.days)).answer) != "accept":
		return false
	var a := propose(World.npc_ref(b.id), s, id, int(r.qty), int(r.price_each), int(r.days), r.history)
	return a.has("contract") or a.has("signing")


func _offered_by(b: NPC) -> bool:
	var me := World.npc_ref(b.id)
	return list.any(func(c): return str(c.state) in ["offered", "signing"] and c.buyer == me)


func _order(b: NPC, id: String, qty: int, price: int, days: int) -> bool:
	var me := World.npc_ref(b.id)
	var sellers := []
	for s: NPC in w.npcs:
		if s != b and s.alive and s.role == "adult":
			sellers.append(s)
	if JudgmentLive.on(w, "contract_seller"):                # PROSPECTIVE (PROS-19, Q14): the buyer asks the one it thinks best of first
		sellers = JudgmentLive.seller_order(w, b, sellers, [w.day(), id.hash()])
	for s: NPC in sellers:
		var r := propose(me, s, id, qty, price, days)
		if r.has("contract") or r.has("signing"):           # signed here, or to be signed when the buyer reaches the seller
			return true
		if meet_counter(b, s, id, qty, price, w.brain.batch_unit(b, id), r):
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
		# a record from an earlier Build 17 save may lack the newer keys: the defaults it was made under
		for k in ["route", "recipe"]:
			r[k] = str(r.get(k, ""))
		if not r.get("terms") is Dictionary:
			r.terms = {"pay": "on_delivery", "partial": true, "all_at_once": false, "deposit": 0}
		if not r.get("history") is Array:
			r.history = []
		if is_service(r):                          # CON-02: the work's progress
			var ld := {}
			for k in r.get("load", {}):
				ld[k] = int(r.load[k])
			r.load = ld
			r.sids = (r.get("sids", []) as Array).map(func(x): return int(x))
			var site: Dictionary = r.get("site", {})
			if site.has("pit"):
				site.pit = int(site.pit)
			r.site = site
			if r.has("cell"):
				r.cell = [int(r.cell[0]), int(r.cell[1])]
		list.append(r)
