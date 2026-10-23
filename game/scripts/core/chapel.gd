class_name Chapel
extends RefCounted
## DVW-B3-CHAPEL (owner, 2026-10-23): the village chapel. A small chapel (the map's "chapel" building, village generator v9)
## with a clergy of two, a preacher and a church assistant, who are paid, low-wage villagers; offerings of coins and food; the
## church's own small farm plot; and food relief that comes from the church first.
##
## Money: the offerings fund (`coins`) holds coins that left villagers' and the player's purses; it pays the clergy's wage,
## buys relief food from sellers and gives what is left as alms to the poorest (alms), and every coin goes to a named person. Nothing is made: when the fund is empty the
## clergy are owed (up to `owed_days` of wages) and relief is the food in the store only. Food: the store holds food offered
## and the crop of the church's plot (FarmPlots, the households' own field code, worked by volunteers or the clergy).
## Relief: a household short of food (NPCBrain.household_food_days below relief_trigger_days) sends a member to ask
## (plan_ask, in the early morning and evening); the church fills its pantry first from its store, then by buying from the
## same sellers the manor's relief buys from (NPCBrain._relief_offers), with its own coins. The manor's relief (reeve_day, 17:00)
## sees the household's pantry as it then is, so it gives only what the church did not. Nothing is given to a household that
## did not ask, and nothing is hidden: a church with nothing to give gives nothing (WDR-022).
## Why people give (agent decision, docs/DECISIONS.md): each has a piety, a fixed number 0 to 1 from the world seed and
## their id. On the weekly service day those at or above min_piety give coin_share x their piety of the coins they hold above
## their OD-19 reserve and keep_coins, and their household gives goods_share x its piety of the wheat it holds beyond goods_keep_days
## of its own food.
## Saved in the World's optional key "chapel"; a save without it (made before the chapel) has the chapel founded on load
## where the ground is free (found), without creating a villager (the clergy's places open in the labour market).

const JOBS := ["preacher", "church_assistant"]
const KEY := "chapel"

var w
var present := false
var bid := ""                       # the chapel building's id
var coins := 0                      # the offerings fund
var store := Inventory.new()        # food offered and grown, and the plot's seed
var plot := {}                      # the church plot, a FarmPlots plot ({id, x, y, w, h, farm: {gate, fence}, church}); derived from the map
var volunteers: Array = []          # npc ids chosen this morning to work the plot
var asked := {}                     # household index -> the last day a member asked
var owed := {}                      # npc id (text) -> wages owed
var evening_day := -1               # the last day the evening business ran
var player_asked_day := -1
var booked := {}                    # household index -> the day a member is on the way to ask (not saved)


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("chapel")


static func is_clergy(n: NPC) -> bool:
	return n != null and n.alive and n.role == "adult" and JOBS.has(n.job)


# ---------------------------------------------------------------- founding -------------------
## Find the chapel and its plot on the map and set them up. `fresh`: a new world (the seed corn is a setup assumption); a save
## made before the chapel gets it on free ground, or none when something of the player's or a household's stands there.
func found(fresh: bool) -> void:
	present = false
	bid = ""
	for b in w.map.data.buildings:
		if str(b.type) == "chapel":
			bid = str(b.id)
	var cp: Array = w.map.data.get("church_plot", [])
	if bid == "" or cp.is_empty():
		return
	var p: Dictionary = (cp[0] as Dictionary).duplicate(true)
	var rect := Rect2i(int(p.x), int(p.y), int(p.w), int(p.h))
	if not w.buildings.has(bid):
		if not fresh and not _ground_free(rect):
			w.note("The village has no chapel: the ground for it is taken.")
			return
		for b in w.map.data.buildings:
			if str(b.id) == bid:
				w.buildings[bid] = (b as Dictionary).duplicate(true)
		w.set_owner(w.buildings[bid], World.MANOR)
		w.set_tenant(w.buildings[bid], "")
		if not fresh:
			w.note("The village has built a chapel, with a small farm plot beside it, on the open ground east of Mill Road.")
	plot = {"id": "church", "x": int(p.x), "y": int(p.y), "w": int(p.w), "h": int(p.h),
		"farm": {"gate": [int(p.gate[0]), int(p.gate[1])], "fence": true}, "church": true}
	present = true
	w.farm_plots._fence_solid(plot)
	if fresh:
		store.add(str(Farming.crops().wheat.seed), int(cfg().plot_seed))


func _chapel_rect() -> Rect2i:
	for b in w.map.data.buildings:
		if str(b.id) == bid:
			return Rect2i(int(b.x), int(b.y), int(b.w), int(b.h))
	return Rect2i()


## Whether nothing of a household's or the player's stands on the chapel's ground or the plot's (a save from before the chapel).
func _ground_free(plot_rect: Rect2i) -> bool:
	var rects := [plot_rect, _chapel_rect()]
	for r: Rect2i in rects:
		for pr in w.plots:
			if r.intersects(Rect2i(int(pr.x), int(pr.y), int(pr.w), int(pr.h))):
				return false
		for id in w.buildings:
			var b: Dictionary = w.buildings[id]
			if r.intersects(Rect2i(int(b.x), int(b.y), int(b.w), int(b.h))):
				return false
		for c: Vector2i in w.farm.cells:
			if r.has_point(c):
				return false
		for c: Vector2i in w.farm_plots.cells:
			if r.has_point(c):
				return false
		for id in w.fauna.pens:
			var pen: Dictionary = w.fauna.pens[id]
			if r.intersects(Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h))):
				return false
		for t in w.trees:
			if bool(t.get("planted", false)) and r.has_point(Vector2i(int(t.x), int(t.y))):
				return false
		for pl in w.plants:                 # SEED-02: a plant the player or a villager grew
			if bool(pl.get("planted", false)) and r.has_point(Vector2i(int(pl.x), int(pl.y))):
				return false
	return true


## Whether cell `c` lies on the chapel's building or its plot (false while the chapel is not placed).
func footprint_has(c: Vector2i) -> bool:
	return present and (plot_rect().has_point(c) or _chapel_rect().has_point(c))


func plot_rect() -> Rect2i:
	return FarmPlots.rect_of(plot) if present else Rect2i()


func door_cell() -> Vector2i:
	return w.building_door(bid) if present else Vector2i.ZERO


func wage_of(job: String) -> int:
	return int((cfg().wage as Dictionary).get(job, 0))


# ---------------------------------------------------------------- the clergy's places ---------
## The place of a clergy job in the labour market (NPCBrain.job_market): open (one place) while the chapel stands and nobody
## living holds the job. A new world has both filled; a save made before the chapel, or a death, opens it for an adult who
## becomes free. No villager is made for it.
func place(job: String) -> Dictionary:
	var open := 0
	if present and not w.npcs.any(func(o): return o.alive and o.role == "adult" and o.job == job):
		open = 1
	return {"pay": float(wage_of(job)), "open": open, "tool": "", "at": door_cell()}


# ---------------------------------------------------------------- piety and offerings ---------
## A fixed 0 to 1 for a person: from the world seed and their id only (integer arithmetic, the same on every machine).
func piety(n: NPC) -> float:
	var h: int = (((w.seed * 1103515245 + n.id * 12345 + 54321) * 2654435761) >> 7) & 0x7fffffff
	return float(h % 100) / 100.0


func _household_piety(h: int) -> float:
	var sum := 0.0
	var k := 0
	for o: NPC in w.brain._members(h):
		if o.role == "adult":
			sum += piety(o)
			k += 1
	return sum / float(k) if k > 0 else 0.0


func is_service_day() -> bool:
	return (w.day() + 1) % int(cfg().offering_every_days) == 0


## The weekly service: the pious give coins (a share of what they hold above their reserve) and their households wheat (a share
## of what lies beyond what they need). Returns {coins, wheat}.
func offerings() -> Dictionary:
	var gave_coins := 0
	var gave_wheat := 0
	for n: NPC in w.npcs:
		if not n.alive or n.role not in ["adult", "elder"] or n.household < 0 or n.coins <= 0:
			continue
		var pt := piety(n)
		if pt < float(cfg().min_piety):
			continue
		var spare: int = n.coins - w.reserve_of(n) - int(cfg().keep_coins)
		var give := floori(float(spare) * pt * float(cfg().coin_share)) if spare > 0 else 0
		if give >= 1:
			n.coins -= give
			coins += give
			gave_coins += give
	for h in w.households.size():
		if w.households[h].get("ended", false):
			continue
		var pt := _household_piety(h)
		if pt < float(cfg().min_piety):
			continue
		var pantry: Inventory = w.households[h].pantry
		var keep := ceili(w.brain.household_day_food(h) * float(cfg().goods_keep_days) / NPCBrain.food_points("wheat"))
		var spare := pantry.count("wheat") - keep
		var give := floori(float(spare) * pt * float(cfg().goods_share)) if spare > 0 else 0
		if give >= 1 and w.transfer(pantry, store, "wheat", give):
			gave_wheat += give
	if gave_coins > 0:
		w.stat("chapel_offering_coins", gave_coins)
	if gave_wheat > 0:
		w.stat("chapel_offering_wheat", gave_wheat)
	if gave_coins + gave_wheat > 0:
		w.note("The village gave %d coins and %d measures of wheat at the chapel's weekly service." % [gave_coins, gave_wheat])
	return {"coins": gave_coins, "wheat": gave_wheat}


## The player's offering of coins at the chapel: {ok, text}.
func player_offer_coins(amount: int) -> Dictionary:
	if not present:
		return {"ok": false, "text": "There is no chapel."}
	if amount < 1 or w.player.coins < amount:
		return {"ok": false, "text": "You have not the coins for that."}
	w.player.coins -= amount
	coins += amount
	w.stat("chapel_offering_coins", amount)
	return {"ok": true, "text": "You give %d coins to the chapel. It will go first to feeding those in need." % amount}


## The player's offering of goods (food and seed): {ok, text}.
func player_offer_item(id: String, qty: int) -> Dictionary:
	if not present:
		return {"ok": false, "text": "There is no chapel."}
	if not accepts(id):
		return {"ok": false, "text": "The chapel takes only food and seed corn."}
	if qty < 1 or not w.player.inv.has(id, qty):
		return {"ok": false, "text": "You do not have that."}
	if not w.transfer(w.player.inv, store, id, qty):
		return {"ok": false, "text": "It cannot be taken."}
	w.stat("chapel_offering_" + id, qty)
	return {"ok": true, "text": "You give %d %s to the chapel." % [qty, GameData.item_name(id).to_lower()]}


static func accepts(id: String) -> bool:
	return NPCBrain.EDIBLE.has(id) or Farming.is_seed(id)


## What the player may ask of the church, once a day, with few coins: some of its food. {ok, text}.
func player_ask() -> Dictionary:
	if not present:
		return {"ok": false, "text": "There is no chapel."}
	if player_asked_day == w.day():
		return {"ok": false, "text": "The church has done what it can for you today."}
	if w.player.coins > int(cfg().ask_player_max_coins):
		return {"ok": false, "text": "You have coins of your own; the church's food is for those who have none."}
	var left := int(cfg().ask_player_units)
	var given := []
	for f in NPCBrain.EDIBLE:
		var n := mini(left, store.count(f))
		if n > 0 and w.transfer(store, w.player.inv, f, n):
			left -= n
			given.append("%d %s" % [n, GameData.item_name(f).to_lower()])
		if left <= 0:
			break
	if given.is_empty():
		return {"ok": false, "text": "The church has no food to give just now."}
	player_asked_day = w.day()
	w.stat("chapel_relief_player", int(cfg().ask_player_units) - left)
	return {"ok": true, "text": "The church gives you %s." % ", ".join(given)}


# ---------------------------------------------------------------- relief ----------------------
func _store_points() -> float:
	return NPCBrain.store_points([store])


## Whether the church has anything to give a household in need: food in its store or coins to buy it with.
func can_give() -> bool:
	return present and (_store_points() > 0.0 or coins > 0)


## A villager's trip to ask for food, planned into n.plan (NPCBrain._plan_evening): one member of a household that is short
## of food, once a day. True when planned.
func plan_ask(n: NPC) -> bool:
	if not present or n.household < 0 or n.role not in ["adult", "elder"] or not can_give():
		return false
	var h := n.household
	var d: int = w.day()
	if int(asked.get(h, -1)) == d or int(booked.get(h, -1)) == d:
		return false
	if w.brain.household_food_days(h) >= float(GameData.b("relief_trigger_days")):
		return false
	booked[h] = d
	n.doing = "going to the chapel to ask for food"
	n.plan = [w.brain.go(door_cell()), w.brain.doit("church_ask", {})]
	return true


## A villager arrives at the chapel and asks for their household: the church gives first from its store, then buys with its coins.
func ask(n: NPC) -> bool:
	if not present or n.household < 0:
		return false
	asked[n.household] = w.day()
	booked.erase(n.household)
	w.stat("chapel_asked")
	var got := relieve(n.household)
	if got > 0.0:
		w.stat("chapel_relieved")
		w.brain.once("chapel_%d_%d" % [n.household, w.day()], "The chapel gave the %s household food." % w.households[n.household].family)
	return got > 0.0


## Fill household `h`'s pantry toward relief_fill_days of food, as the manor's relief does, but from the church: its store
## (grain in whole pots first, then any other food), then food bought with its coins from sellers (the manor's
## _relief_offers). Returns the food points given.
func relieve(h: int) -> float:
	var days: float = w.brain.household_food_days(h)
	if days >= float(GameData.b("relief_trigger_days")):
		return 0.0
	var pantry: Inventory = w.households[h].pantry
	var day_food: float = w.brain.household_day_food(h)
	var need: float = (float(GameData.b("relief_fill_days")) - days) * day_food
	var total := need
	var held := 0
	for inv: Inventory in w.brain.household_stores(h):
		held += inv.count("wheat")
	var pot := NPCBrain.pottage_batch()
	var wp := NPCBrain.food_points("wheat")
	var want := ceili(need / wp)
	want += (held + want) % pot
	var wheat := mini(want, store.count("wheat"))
	if wheat > 0 and w.transfer(store, pantry, "wheat", wheat):
		need -= float(wheat) * wp
		held += wheat
		w.stat("chapel_relief_wheat", wheat)
	for f in NPCBrain.EDIBLE:
		var pts := NPCBrain.food_points(f)
		if f == "wheat" or pts <= 0.0 or need <= 0.0 or not store.has(f):
			continue
		var k := mini(store.count(f), ceili(need / pts))
		if w.transfer(store, pantry, f, k):
			need -= float(k) * pts
			w.stat("chapel_relief_" + f, k)
	if need > 0.0 and coins > 0:
		var offers: Array = w.brain._relief_offers(h)
		var i := 0
		while need > 0.0 and i < offers.size() and coins > 0:
			var o: Dictionary = offers[i]
			var src: Inventory = o.inv
			if int(o.left) <= 0 or not src.has(o.item):
				i += 1
				continue
			var qty := 1
			if o.item == "wheat":
				qty = mini(pot - held % pot, mini(int(o.left), src.count("wheat")))
			var price: int = (w.sell_price(o.payee, o.item) if bool(o.trader) else int(o.price)) * qty
			if price > coins:
				break
			if not pantry.can_add(o.item) or not w.transfer(src, pantry, o.item, qty):
				i += 1
				continue
			var payee: NPC = o.payee
			payee.coins += price
			payee.earned += price
			coins -= price
			o.left = int(o.left) - qty
			need -= float(o.pts) * qty
			if o.item == "wheat":
				held += qty
			w.stat("chapel_relief_bought", price)
	var given := total - maxf(need, 0.0)
	if given > 0.0:
		w.stat("chapel_relief_points", given)
	return given


# ---------------------------------------------------------------- the day ---------------------
## Every morning: who volunteers for the plot, and the plot's seed. The pious who can spare the time (the old, those out of
## work, and the very pious after their day's work) work it unasked, the most pious first, up to volunteers_max.
func dawn() -> void:
	if not present:
		return
	volunteers.clear()
	var cands := []
	for n: NPC in w.npcs:
		if not n.alive or n.household < 0 or not w.farm_plots.able(n) or JOBS.has(n.job):
			continue
		var pt := piety(n)
		var free := n.role == "elder" or n.job == ""
		if pt >= float(cfg().evening_piety) or (free and pt >= float(cfg().volunteer_piety)):
			cands.append([-pt, n.id])
	cands.sort()
	for c in cands:
		if volunteers.size() >= int(cfg().volunteers_max):
			break
		volunteers.append(int(c[1]))
	_buy_seed()


## The seed the plot's empty tilled ground lacks, bought with the fund from farmers and the food merchant (their seed above
## what they keep), paid to them: the church buys, nothing is made.
func _buy_seed() -> void:
	if not w.farm.can_sow_now() or coins <= 0:
		return
	var seed := str(Farming.crops().wheat.seed)
	var empty := 0
	for c: Vector2i in w.farm_plots.cells:
		var cell: Dictionary = w.farm_plots.cells[c]
		if str(cell.plot) == "church" and cell.state == "tilled":
			empty += 1
	var need := empty - store.count(seed)
	var buyer: NPC = null
	for o: NPC in w.npcs:
		if is_clergy(o):
			buyer = o
			break
	if need <= 0 or buyer == null:
		return
	var price: int = w.farm.seed_item_price(seed, buyer)
	for o: NPC in w.npcs:
		if need <= 0 or coins < price:
			break
		if not w.farm.sells_seed(o):
			continue
		var keep := int(Farming.seed_cfg().seed_keep) if o.job == "farmer" else 0
		var qty := mini(need, mini(o.inv.count(seed) - keep, coins / price))
		if qty > 0 and w.transfer(o.inv, store, seed, qty):
			o.coins += price * qty
			o.earned += price * qty
			coins -= price * qty
			need -= qty
			w.stat("chapel_seed_bought", qty)


## 16:00, before the manor's evening business: on the service day the offerings, then the clergy's wages from the fund, then
## (service day) the alms from what is left (CHAPEL-R2).
func evening() -> void:
	if not present or evening_day == w.day():
		return
	evening_day = w.day()
	if is_service_day():
		offerings()
	var clergy: Array = w.npcs.filter(func(o): return is_clergy(o))
	clergy.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
	for n: NPC in clergy:
		var wage := wage_of(n.job)
		var due: int = wage + int(owed.get(str(n.id), 0))
		var pay := mini(due, coins)
		n.coins += pay
		n.earned += pay
		coins -= pay
		w.stat("chapel_wages", pay)
		var left := mini(due - pay, wage * int(cfg().owed_days))
		if left > 0:
			owed[str(n.id)] = left
		else:
			owed.erase(str(n.id))
	for k in owed.keys():
		var o: NPC = w.npc(int(k))
		if o == null or not o.alive:
			owed.erase(k)
	if is_service_day():
		alms()


## CHAPEL-R2 (owner, 2026-10-23, Priest + alms: "offerings keep the priest, and what is left goes as alms to the poorest
## households"; docs/directives/2026-10-23_chapel_alms_build18_decisions.md, _build18_overnight_completion_release.md). On the
## service day, after the offerings and the wages: the fund keeps what the clergy are owed and seven days of their wages (to
## the next service); the rest goes to the households short of their necessity reserve (World.necessity, OD-19/PAR-02A: the
## household's foreseeable need less the coins all its members hold), each up to that shortfall, the largest shortfall first,
## until it runs out. A household's need is one need: it is paid once, to one adult (else an elder; the lowest id), never to
## each member. What is left stays in the fund. Every coin goes to a named person; nothing is made, and the fund never goes
## below what it keeps. Returns the coins given.
func alms() -> int:
	if not present:
		return 0
	var keep := 0
	for o: NPC in w.npcs:
		if is_clergy(o):
			keep += wage_of(o.job) * int(cfg().offering_every_days)
	for k in owed:
		keep += int(owed[k])
	var pot := coins - keep
	if pot <= 0:
		return 0
	var rows := []                      # [shortfall, household, the member who receives it]
	for h in w.households.size():
		if w.households[h].get("ended", false):
			continue
		var members: Array = w.brain._members(h)
		var payee: NPC = null
		for role in ["adult", "elder"]:
			for o: NPC in members:
				if o.alive and o.role == role and (payee == null or o.id < payee.id):
					payee = o
			if payee != null:
				break
		if payee == null:
			continue
		var short := household_shortfall(h)
		if short > 0:
			rows.append([short, h, payee])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	var given := 0
	var helped := 0
	for r in rows:
		var give := mini(int(r[0]), pot)
		if give <= 0:
			break
		(r[2] as NPC).coins += give
		coins -= give
		pot -= give
		given += give
		helped += 1
	if given > 0:
		w.stat("chapel_alms_coins", given)
		w.stat("chapel_alms_households", helped)
		w.note("The chapel gave %d coins in alms to %d of the village's poorest households." % [given, helped])
	return given


## The coins household `h` lacks for its foreseeable necessities: its need (World.necessity, the same for every member) less
## what all its members hold. 0 when it has enough.
func household_shortfall(h: int) -> int:
	var members: Array = w.brain._members(h)
	if members.is_empty():
		return 0
	var nec: Dictionary = w.necessity(members[0])
	var held := 0
	for o: NPC in members:
		held += o.coins
	return maxi(0, int(nec.need) - held)


# ---------------------------------------------------------------- work on the plot ------------
func volunteers_able() -> int:
	var k := 0
	for id in volunteers:
		var o: NPC = w.npc(int(id))
		if o != null and w.farm_plots.able(o):
			k += 1
	return k


## A volunteer's work on the church plot, in the time their day leaves (NPCBrain._plan_evening, and an elder's day). True when planned.
func plan_volunteer(n: NPC) -> bool:
	if not present or not volunteers.has(n.id):
		return false
	return w.farm_plots.plan_church(n, n.role != "adult")


## A clergy member's working day: with volunteers to work the plot they keep the chapel; with none, they work it themselves
## (the owner: "if they don't volunteer then the clergy ... work the fields themselves"). True when planned.
func plan_clergy(n: NPC) -> bool:
	if not present:
		return false
	if volunteers_able() == 0 and not (n.job == "preacher" and is_service_day()) and w.farm_plots.plan_church(n, false):
		return true
	n.doing = "keeping the chapel" if n.job == "church_assistant" else "preaching at the chapel"
	n.plan = [w.brain.go(w.brain.wander_cell(door_cell(), 2)), w.brain.work(60, "", {}, "idle")]
	return true


## Whether `n` may work the church plot: a volunteer, or the clergy.
func may_work(n: NPC) -> bool:
	return present and (volunteers.has(n.id) or is_clergy(n))


# ---------------------------------------------------------------- save ------------------------
func to_dict() -> Dictionary:
	return {"present": present, "coins": coins, "store": store.to_dict(), "volunteers": volunteers.duplicate(), "asked": asked.duplicate(),
		"owed": owed.duplicate(), "evening_day": evening_day, "player_asked_day": player_asked_day}


## A saved chapel is read as it was; a save without the key (made before the chapel) has the chapel founded now.
func load_dict(d: Dictionary) -> void:
	if d.is_empty():
		found(false)
		return
	coins = int(d.get("coins", 0))
	store = Inventory.from_dict(d.get("store", {}))
	volunteers = (d.get("volunteers", []) as Array).map(func(v): return int(v))
	asked = {}
	for k in d.get("asked", {}):
		asked[int(k)] = int(d.asked[k])
	owed = (d.get("owed", {}) as Dictionary).duplicate()
	evening_day = int(d.get("evening_day", -1))
	player_asked_day = int(d.get("player_asked_day", -1))
	if bool(d.get("present", true)):
		found(false)
	else:
		present = false
