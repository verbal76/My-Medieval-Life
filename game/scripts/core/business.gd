class_name Business
extends RefCounted
## The player's market stall (PL1-10, stages 1 and 2; docs/BUILD_DECISIONS.md "Player businesses").
##
## Stage 1: the manor keeps a few open market pitches (World.stalls entries with `pitch: true`, drawn beside
## the merchants' stalls). The player rents one for stall_rent_day coins a day (paid to the manor's treasury at
## the first morning and then each morning; the first day is paid on renting), moves goods from the pack into the
## stall's sale stock, sets a price per item, edits or removes listings, reads the stock and the sales record,
## collects the till, and closes the stall without losing anything. Rent not paid (from the pack, then the
## till) for stall_evict_days mornings gives the pitch back: the unsold goods and the till return to the
## player, whatever does not fit the pack lies at the stall as loot. Sales happen only while the player is at
## the stall (within stall_range tiles of it); there is no attendant yet (stage 4).
##
## Stage 2: villagers buy from the open stall only for needs they really have (needs()), with their own coins
## (never below a cash floor), only when the price is not above what they would pay the merchants (ceiling()),
## and the goods go into their pack (or their household's pantry). Needs are the ones the brain already
## models: a trade's stock thresholds (NPCBrain.BUYS / wants), a missing tool, the guards' gear, the
## household's firewood and food (NPCBrain._plan_provision), and the materials open building sites ask for
## (Construction.open_need). A met need buys nothing more. Evaluated once an hour (hour()), at most
## stall_buyers_per_hour buyers walk to the stall (a "buy_stall" step in their plan, resolved by arrive()).
##
## State lives in the stall's own dict (saved with World.stalls): tenant, stock {id: qty}, prices {id: coins},
## sales [{day, hour, who, item, qty, price}], till, earned, paid_day, missed.

const PITCHES := [{"id": "pitch0", "x": 42, "y": 61}, {"id": "pitch1", "x": 50, "y": 61}]
const AWNING := [1890, 3502]          # the merchants' stall art (ground layer "below0"), two tiles wide
const PRICE_CAP := 4                  # a listing may be priced up to this many times the item's value

var w: World
var heading := {}                     # npc id -> game hour they set out for the stall (not saved)


func _init(world: World) -> void:
	w = world


# ---------------------------------------------------------------- pitches --------------------
## Add the manor's open pitches (new worlds, and saves made before they existed) and draw them.
static func add_pitches(world: World, m: VillageMap) -> void:
	var lay: Dictionary = {}
	for l in m.data.layers:
		if str(l.name) == "below0":
			lay = l
	for p in PITCHES:
		var id: String = p.id
		if not world.stalls.has(id):
			# made as a loaded one is (JSON numbers), so a save of an upgraded old save is the same as of the next load
			world.stalls[id] = JSON.parse_string(JSON.stringify({"id": id, "x": int(p.x), "y": int(p.y), "use": [int(p.x), int(p.y) + 1],
				"kind": "pitch", "pitch": true, "owner": World.MANOR, "tenant": ""}))
		if not lay.is_empty():
			for k in 2:
				lay.data[int(p.y) * m.w + int(p.x) + k] = AWNING[k]
		for k in 2:
			m.set_solid(Vector2i(int(p.x) + k, int(p.y)), true)


static func is_pitch(s: Dictionary) -> bool:
	return bool(s.get("pitch", false))


func mine() -> Dictionary:
	for id in sorted_ids():
		var s: Dictionary = w.stalls[id]
		if is_pitch(s) and w.tenant_of(s) == World.PLAYER:
			return s
	return {}


func sorted_ids() -> Array:
	var ids: Array = w.stalls.keys()
	ids.sort()
	return ids


func free_pitch() -> Dictionary:
	for id in sorted_ids():
		var s: Dictionary = w.stalls[id]
		if is_pitch(s) and w.tenant_of(s) == "":
			return s
	return {}


static func rent_day() -> int:
	return int(GameData.b("stall_rent_day"))


func use_cell(s: Dictionary) -> Vector2:
	return Vector2(int(s.use[0]) + 0.5, int(s.use[1]) + 0.5)


func stock_of(s: Dictionary) -> Dictionary:
	return s.get("stock", {})


func price_of(s: Dictionary, id: String) -> int:
	return int(s.get("prices", {}).get(id, GameData.value(id)))


## Why the player cannot rent now, or "".
func rent_refusal() -> String:
	if not mine().is_empty():
		return "You already rent a stall."
	if free_pitch().is_empty():
		return "Every open pitch is let."
	if w.player.coins < rent_day():
		return "You need %d coins for the first day's rent." % rent_day()
	return ""


## Rent the first free pitch: the first day is paid now. "" when done, else why not.
func rent() -> String:
	var why := rent_refusal()
	if why != "":
		return why
	var s := free_pitch()
	if not w.property._pay_manor(World.PLAYER, rent_day()):
		return "You cannot pay the rent."
	w.set_tenant(s, World.PLAYER)
	s.stock = {}
	s.prices = {}
	s.sales = []
	s.till = 0
	s.earned = 0
	s.paid_day = w.day()
	s.missed = 0
	w.stat("stall_rented")
	w.note("%s %s rented a market stall for %d coins a day." % [w.player.name, w.player.family, rent_day()])
	return ""


# ---------------------------------------------------------------- the player's stock ---------
## How many of an item in the pack may be put up: not goods marked stolen (no fencing through a stall).
func listable(id: String) -> int:
	return maxi(0, w.player.inv.count(id) - w.player.stolen_count(id, false))


func can_list(id: String) -> bool:
	return GameData.items.has(id) and GameData.value(id) > 0


## Move `qty` of an item from the pack to the sale stock. "" when done, else why not.
func list_item(s: Dictionary, id: String, qty: int) -> String:
	if w.tenant_of(s) != World.PLAYER:
		return "That is not your stall."
	if not can_list(id) or qty <= 0:
		return "That cannot be sold."
	if qty > listable(id):
		return "You do not have that many that you can sell."
	if not s.stock.has(id) and s.stock.size() >= int(GameData.b("stall_max_listings")):
		return "The stall has room for %d kinds of goods." % int(GameData.b("stall_max_listings"))
	w.player.inv.remove(id, qty)
	s.stock[id] = int(s.stock.get(id, 0)) + qty
	if not s.prices.has(id):
		s.prices[id] = GameData.value(id)
	return ""


## Take `qty` back to the pack (all or nothing); the price is forgotten with the last of it.
func unlist(s: Dictionary, id: String, qty: int) -> String:
	var have := int(s.stock.get(id, 0))
	if qty <= 0 or qty > have:
		return "The stall does not hold that many."
	if not w.player.inv.can_add(id):
		return "Your pack is full."
	s.stock[id] = have - qty
	w.player.inv.add(id, qty)
	if int(s.stock[id]) == 0:
		s.stock.erase(id)
		s.prices.erase(id)
	return ""


func set_price(s: Dictionary, id: String, price: int) -> String:
	if not s.stock.has(id):
		return "That is not for sale at your stall."
	if price < 1 or price > GameData.value(id) * PRICE_CAP:
		return "A price from 1 to %d coins." % (GameData.value(id) * PRICE_CAP)
	s.prices[id] = price
	return ""


## Collect the till into the purse; the coins taken.
func collect(s: Dictionary) -> int:
	var t := int(s.get("till", 0))
	w.player.coins += t
	s.till = 0
	return t


## Give the pitch back with nothing lost: the unsold goods and the till return to the player; what does not
## fit the pack lies at the stall (loot). No refund of rent paid. Returns a summary line.
func close(s: Dictionary, because := "You closed your stall.") -> String:
	var bag := Inventory.new()
	var back := 0
	for id in s.stock.keys():
		var n := int(s.stock[id])
		if w.player.inv.add(id, n):
			back += n
		else:
			bag.add(id, n)
	var coins := collect(s)
	var left := bag.total()
	if left > 0:
		w.loot.append({"pos": use_cell(s), "inv": bag, "coins": 0, "from": "your stall"})
	for k in ["stock", "prices", "sales", "till", "earned", "paid_day", "missed"]:
		s.erase(k)
	w.set_tenant(s, "")
	w.stat("stall_closed")
	return "%s %d goods returned to your pack%s%s." % [because, back, (", %d coins from the till" % coins) if coins > 0 else "",
		(", %d left at the stall" % left) if left > 0 else ""]


# ---------------------------------------------------------------- rent ------------------------
## Each morning: the day's rent, from the purse and then the till. Unpaid, selling stops; after
## stall_evict_days unpaid mornings the pitch is taken back (close()).
func daily() -> void:
	var s := mine()
	if s.is_empty() or int(s.get("paid_day", 0)) >= w.day():
		return
	var owed := rent_day() * (w.day() - int(s.paid_day))
	var from_till := mini(maxi(0, owed - w.player.coins), int(s.till))
	if w.player.coins + from_till >= owed:
		s.till = int(s.till) - from_till
		w.player.coins += from_till
		w.property._pay_manor(World.PLAYER, owed)
		w.stat("stall_rent_paid", owed)
		s.paid_day = w.day()
		s.missed = 0
		return
	s.missed = int(s.get("missed", 0)) + 1
	if int(s.missed) >= int(GameData.b("stall_evict_days")):
		w.note("The manor took back %s's market stall: the rent was not paid." % w.player.name)
		var line := close(s, "The manor took back your stall: the rent was not paid.")
		w.note(line)
	else:
		w.note("You could not pay the stall's rent (%d coins). Sales are stopped until you do; the manor takes it back after %d days." % [owed, int(GameData.b("stall_evict_days"))])


## Pay what is owed now (the window's button): "" when done, else why not.
func pay_arrears(s: Dictionary) -> String:
	var owed := rent_day() * maxi(1, w.day() - int(s.get("paid_day", 0)))
	if w.player.coins < owed:
		return "You need %d coins." % owed
	w.property._pay_manor(World.PLAYER, owed)
	w.stat("stall_rent_paid", owed)
	s.paid_day = w.day()
	s.missed = 0
	return ""


# ---------------------------------------------------------------- selling ----------------------
## Sales run only while the player is at the open stall and the rent is not owing.
func attended(s: Dictionary) -> bool:
	return w.tenant_of(s) == World.PLAYER and int(s.get("missed", 0)) == 0 \
		and w.player.pos.distance_to(use_cell(s)) <= float(GameData.b("stall_range"))


## What a villager will pay at most, per piece: the cheapest price among those who sell the item in the
## village now (the merchants, the smith and the carpenter), or the dearest ordinary price when nobody does;
## a little more for an urgent need (urgency 0..2).
func ceiling(id: String, urgency: int) -> int:
	var alt := maxi(1, roundi(GameData.value(id) * float(GameData.b("price_max"))))
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.inv.has(id) and not NPCBrain.KEEPS.get(o.job, []).has(id) and \
				(o.job in ["smith", "carpenter", "cook", "tavernkeeper", "merchant", "farmer", "woodcutter"]):
			alt = mini(alt, w.sell_price(o, id))
	return floori(alt * (1.0 + float(GameData.b("stall_urgency_step")) * urgency))


func cash_floor(n: NPC) -> int:
	return int(GameData.b("trader_cash_floor")) if NPCBrain.BUYS.has(w.brain.buy_role(n)) else int(GameData.b("stall_buyer_floor"))


## What an adult really needs: [{item, qty, urgency (0..2), pantry}], most urgent first. Merchants and
## children do not shop for stock or play.
func needs(n: NPC) -> Array:
	var out := []
	if not n.alive or n.role != "adult" or n.job == "merchant":
		return out
	var b: NPCBrain = w.brain
	var caps: Dictionary = NPCBrain.BUYS.get(b.buy_role(n), {})
	for id in caps:                       # a trade restocks when under half its stock cap
		var gap: int = b.wants(n, id)
		if gap > 0 and n.inv.count(id) * 2 < int(caps[id]):
			out.append({"item": id, "qty": gap, "urgency": 1 if n.inv.count(id) == 0 else 0, "pantry": false})
	if n.job in ["carpenter", "smith", "laborer"]:      # what open building sites ask for (construction.gd)
		for id in ["plank", "stone", "log", "iron_bar"]:
			var short: int = w.construction.open_need(id) - n.inv.count(id)
			if short > 0 and (Construction.SELLERS.get(id, []) as Array).has(b.buy_role(n)):
				out.append({"item": id, "qty": short, "urgency": 1, "pantry": false})
	var tool := "pickaxe" if n.job in ["miner", "laborer"] else ("axe" if n.job == "woodcutter" else "")
	if tool != "" and not n.inv.has(tool):
		out.append({"item": tool, "qty": 1, "urgency": 2, "pantry": false})
	if n.job == "guard":
		for id in NPCBrain.KEEPS.guard:
			if not n.inv.has(id):
				out.append({"item": id, "qty": 1, "urgency": 1, "pantry": false})
	if n.household >= 0 and n.household < w.households.size() and w.party("hh:%d" % n.household) == n:
		var hh: Dictionary = w.households[n.household]
		if (hh.pantry as Inventory).count("log") < 1:
			out.append({"item": "log", "qty": 2, "urgency": 2, "pantry": true})
		var short: int = b._dependants(hh) + 1 - b._stocked(hh)
		if short > 0:
			for id in ["wheat", "pottage", "roast_meat", "bread"]:
				out.append({"item": id, "qty": short * (2 if id == "wheat" else 1), "urgency": 2 if b._stocked(hh) == 0 else 1, "pantry": true})
	out.sort_custom(func(x, y): return int(x.urgency) > int(y.urgency))
	return out


## The purchase this villager would make at the stall now, or {}: the first need the stall can meet at a
## price inside the ceiling and within what the villager can pay above their cash floor.
func offer(n: NPC, s: Dictionary) -> Dictionary:
	for need in needs(n):
		var id: String = need.item
		var have := int(s.stock.get(id, 0))
		if have <= 0:
			continue
		var price := price_of(s, id)
		if price > ceiling(id, int(need.urgency)):
			continue
		var afford := (n.coins - cash_floor(n)) / price
		var qty := mini(mini(int(need.qty), have), mini(afford, int(GameData.b("stall_buy_max"))))
		if qty >= 1 and n.inv.can_add(id):
			return {"item": id, "qty": qty, "price": price, "pantry": bool(need.pantry)}
	return {}


## Every game hour: while the player is at the open stall, send the first few villagers with a need it can meet
## (idle ones, nearest id first) to walk over and buy.
func hour() -> void:
	var s := mine()
	var h := w.day() * 24 + int(w.hour())
	for id in heading.keys():
		if h - int(heading[id]) >= 2:
			heading.erase(id)
	if s.is_empty() or not attended(s) or s.stock.is_empty():
		return
	var sent := 0
	for n: NPC in w.npcs:
		if sent >= int(GameData.b("stall_buyers_per_hour")):
			break
		if heading.has(n.id) or not n.alive or n.role != "adult" or w.asleep(n) or not _free(n):
			continue
		if n.pos.distance_to(use_cell(s)) > float(GameData.b("stall_walk_range")):
			continue
		var o := offer(n, s)
		if o.is_empty():
			continue
		n.doing = "going to the market stall to buy %s" % GameData.item_name(o.item).to_lower()
		n.plan = [w.brain.go(Vector2i(int(s.use[0]), int(s.use[1]))), w.brain.doit("buy_stall", {"stall": s.id, "item": o.item, "pantry": o.pantry})]
		heading[n.id] = h
		sent += 1


func _free(n: NPC) -> bool:
	return n.plan.is_empty() or (n.plan[0].k == "work" and n.plan[0].get("anim", "") == "idle")


## The villager reaches the stall (the "buy_stall" step): everything is checked again, since the player may have
## left, changed the price or sold out. True when something was bought.
func arrive(n: NPC, a: Dictionary) -> bool:
	heading.erase(n.id)
	var s: Dictionary = w.stalls.get(str(a.stall), {})
	if s.is_empty() or not attended(s):
		return false
	var o := offer(n, s)
	if o.is_empty() or o.item != str(a.item):
		return false
	return sell(s, n, o.item, int(o.qty), int(o.price), bool(o.pantry))


## One sale at the stall: coins from the buyer to the till, goods from the stock to the buyer (or the
## household's pantry). All or nothing.
func sell(s: Dictionary, n: NPC, id: String, qty: int, price: int, pantry := false) -> bool:
	var total := qty * price
	var dest: Inventory = (w.households[n.household].pantry as Inventory) if pantry else n.inv
	if qty <= 0 or int(s.stock.get(id, 0)) < qty or n.coins < total or not dest.can_add(id):
		return false
	s.stock[id] = int(s.stock[id]) - qty
	if int(s.stock[id]) == 0:
		s.stock.erase(id)
		s.prices.erase(id)
	dest.add(id, qty)
	n.coins -= total
	n.spent += total
	s.till = int(s.till) + total
	s.earned = int(s.earned) + total
	s.sales.append({"day": w.day(), "hour": int(w.hour()), "who": "%s %s" % [n.name, n.family], "item": id, "qty": qty, "price": price})
	while s.sales.size() > int(GameData.b("stall_sales_log")):
		s.sales.pop_front()
	w.stat("stall_sold_" + id, qty)
	w.stat("stall_coins", total)
	w.player.gain("trading", 2)
	w.note("%s %s bought %d %s from your stall for %d coins." % [n.name, n.family, qty, GameData.item_name(id).to_lower(), total])
	return true


## Coins held in stall tills (counted with the village's money, so totals still balance).
func tills() -> int:
	var t := 0
	for id in w.stalls:
		t += int(w.stalls[id].get("till", 0))
	return t
