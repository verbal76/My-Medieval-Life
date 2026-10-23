class_name BusinessWorks
extends RefCounted
## B18-DP-01 (owner, 2026-10-23), PL1-10 stage 4: an attendant works the player's own workshop stations. This is the
## ONGOING EMPLOYEE model (the attendant the player hired under the existing hire and wage rules, Business.hire); it is not a
## contract (CON-01 / CON-02 are priced agreements for one job, docs/build18/EMPLOYMENT_AND_CONTRACTS.md).
##
## The player chooses what to make: production orders on the stall or shop (`orders`: {recipe, left} makes that many
## batches, {recipe, keep} keeps that many of the recipe's goods in the premises' stock, store and workroom), and sets
## materials aside in the premises' workroom (`work`, item -> count, moved from and back to the pack; nothing is bought or
## made from nothing). The attendant is a real villager (NPCBrain plans their day through Business.plan_attendant): in the
## working day they walk to a station of the player's own buildings and work the REAL recipe (World.work_craft, the one way
## the player and every villager make a recipe: the recipe's skill level, its tool from the worker's own pack, a practised
## hand's savings and bonus unit, the xp, the same time); the inputs leave the workroom only when the work is done and the
## goods come out into the premises' stock (priced at the market value if new) or, when that is full or they cannot be
## sold, stay in the workroom. One craft, then an hour minding the counter, then the next: while they are at the bench the
## counter is not minded, so nothing sells then unless the player is near. Missing materials, skill, tool or a free station
## stop the work (the reason is kept in `works_note` and shown in the window); the wage is the existing one, from the till.
##
## State in the premises' own dict (saved with it; absent = no orders, an empty workroom): orders [{recipe, left|keep}],
## work {item: qty}, works_note. Goods in the workroom are held and decay like the stock (Decay, SettlementHoldings).

const MAX_ORDERS := 6                 # presentation limits of the window, not balance
const MAX_BATCHES := 50
const MAX_KEEP := 99
const MIND_MINUTES := 60.0            # the hour at the counter between two crafts

var w: World
var biz: Business


func _init(world: World, business: Business) -> void:
	w = world
	biz = business


# ---------------------------------------------------------------- what can be made ---------------
## The player's own stations (the stations of buildings they own or lease), in id order.
func stations() -> Array:
	var out := []
	var ids: Array = w.stations.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = w.buildings.get(str(w.stations[id].get("building", "")), {})
		if not b.is_empty() and w.holds(World.PLAYER, b):
			out.append(id)
	return out


func station_kinds() -> Array:
	var out := []
	for id in stations():
		var t := str(w.stations[id].type)
		if not out.has(t):
			out.append(t)
	return out


## The recipes the player's own stations can make, in id order.
func recipes() -> Array:
	var out := []
	var kinds := station_kinds()
	var ids: Array = GameData.recipes.keys()
	ids.sort()
	for r in ids:
		if kinds.has(str(GameData.recipes[r].station)):
			out.append(r)
	return out


func orders(s: Dictionary) -> Array:
	return s.get("orders", [])


func work_of(s: Dictionary) -> Dictionary:
	return s.get("work", {})


func work_total(s: Dictionary) -> int:
	var t := 0
	for id in work_of(s):
		t += int(s.work[id])
	return t


## The main product of a recipe (its first output).
static func product(recipe: String) -> String:
	return str(GameData.recipes[recipe].out.keys()[0])


## How many of the recipe's product the premises hold (stock, back room and workroom).
func held(s: Dictionary, recipe: String) -> int:
	var id := product(recipe)
	return int(s.get("stock", {}).get(id, 0)) + int(s.get("store", {}).get(id, 0)) + int(work_of(s).get(id, 0))


# ---------------------------------------------------------------- the player's choices ---------
func order_refusal(s: Dictionary, recipe: String, batches: int, keep: int) -> String:
	if not biz.is_mine(s):
		return "That is not your stall."
	if not GameData.recipes.has(recipe) or not recipes().has(recipe):
		return "None of your stations makes that."
	if (batches <= 0) == (keep <= 0):
		return "Choose a number of batches or a stock to keep."
	if batches > MAX_BATCHES or keep > MAX_KEEP:
		return "Too many."
	for o in orders(s):
		if str(o.recipe) == recipe:
			return "That is ordered already."
	if orders(s).size() >= MAX_ORDERS:
		return "There is room for %d orders." % MAX_ORDERS
	return ""


## Order `batches` batches of a recipe, or (keep > 0) keep that many of its goods in stock. "" when done, else why not.
func add_order(s: Dictionary, recipe: String, batches: int, keep := 0) -> String:
	var why := order_refusal(s, recipe, batches, keep)
	if why != "":
		return why
	if not s.has("orders"):
		s.orders = []
	s.orders.append({"recipe": recipe, "keep": keep} if keep > 0 else {"recipe": recipe, "left": batches})
	return ""


func cancel_order(s: Dictionary, i: int) -> void:
	if i >= 0 and i < orders(s).size():
		s.orders.remove_at(i)
		if s.orders.is_empty():
			s.erase("orders")
			s.erase("works_note")


## Set materials aside from the pack in the workroom. "" when done, else why not.
func stock_work(s: Dictionary, id: String, qty: int) -> String:
	if not biz.is_mine(s):
		return "That is not your stall."
	if qty <= 0 or not GameData.items.has(id) or qty > biz.listable(id):
		return "You do not have that many that you can set aside."
	w.player.inv.remove(id, qty)
	if not s.has("work"):
		s.work = {}
	s.work[id] = int(s.work.get(id, 0)) + qty
	return ""


## Bring materials or goods from the workroom back to the pack.
func fetch_work(s: Dictionary, id: String, qty: int) -> String:
	var have := int(work_of(s).get(id, 0))
	if qty <= 0 or qty > have:
		return "The workroom does not hold that many."
	if not w.player.inv.can_add(id):
		return w.player.inv.full_text(id)
	w.player.inv.add(id, qty)
	s.work[id] = have - qty
	if int(s.work[id]) == 0:
		s.work.erase(id)
	if s.work.is_empty():
		s.erase("work")
	return ""


## Put goods from the workroom up for sale (the listing rules of Business.list_item). "" when done, else why not.
func shelve(s: Dictionary, id: String, qty: int) -> String:
	var have := int(work_of(s).get(id, 0))
	if qty <= 0 or qty > have or not biz.can_list(id):
		return "That cannot be put up."
	if not s.stock.has(id) and s.stock.size() >= biz.listing_cap(s):
		return "It has room for %d kinds of goods." % biz.listing_cap(s)
	s.work[id] = have - qty
	if int(s.work[id]) == 0:
		s.work.erase(id)
	if s.work.is_empty():
		s.erase("work")
	s.stock[id] = int(s.stock.get(id, 0)) + qty
	if not s.prices.has(id):
		s.prices[id] = GameData.value(id)
	return ""


## Everything in the workroom back to the pack (or lying at the premises) when the premises close. Returns the count that
## did not fit.
func clear_into(s: Dictionary, bag: Inventory) -> int:
	var back := 0
	for id in work_of(s).keys():
		var n := int(s.work[id])
		if w.player.inv.add(id, n):
			back += n
		else:
			bag.add(id, n)
	s.erase("work")
	s.erase("orders")
	s.erase("works_note")
	return back


# ---------------------------------------------------------------- the attendant's work ----------
## A station of `kind` among the player's own with room for one more worker (the villagers' rule, NPCBrain._station_for), or "".
func free_station(n: NPC, kind: String) -> String:
	for id in stations():
		var st: Dictionary = w.stations[id]
		if str(st.type) != kind:
			continue
		var users: Dictionary = st.users
		for u in users.keys():
			var o := w.npc(int(u))
			if float(users[u]) < w.minutes or o == null or not o.alive or o.target != -1 \
					or not o.plan.any(func(p): return str(p.get("args", {}).get("station", "")) == id):
				users.erase(u)
		var player_there := 1 if float(st.get("player_until", -1.0)) > w.minutes else 0
		if users.has(n.id) or users.size() + player_there < int(st.get("capacity", 1)):
			return id
	return ""


## Why `n` cannot make `recipe` from this premises' workroom now, or "".
func why_not(s: Dictionary, n: NPC, recipe: String) -> String:
	var rec: Dictionary = GameData.recipes[recipe]
	if n.level(str(rec.skill)) < int(rec.level):
		return "%s needs %s level %d for %s" % [n.name, str(rec.skill), int(rec.level), recipe.replace("_", " ")]
	if rec.has("tool") and w.craft_tool(n, recipe) == "-":
		return "%s has no %s to work with" % [n.name, str(rec.tool)]
	var short := []
	for id in rec["in"]:
		if int(work_of(s).get(id, 0)) < int(rec["in"][id]):
			short.append("%d %s" % [int(rec["in"][id]) - int(work_of(s).get(id, 0)), GameData.item_name(id).to_lower()])
	if not short.is_empty():
		return "the workroom lacks " + ", ".join(short)
	if not station_kinds().has(str(rec.station)):
		return "you have no %s" % str(rec.station)
	return ""


## The first order the attendant can start now: {recipe, station} or {}. When none can, `works_note` says why the first
## could not.
func next_job(s: Dictionary, n: NPC) -> Dictionary:
	var reasons := []
	for o in orders(s):
		var r := str(o.recipe)
		if not GameData.recipes.has(r):
			continue
		if int(o.get("keep", 0)) > 0 and held(s, r) >= int(o.keep):
			continue
		if int(o.get("keep", 0)) <= 0 and int(o.get("left", 0)) <= 0:
			continue
		var why := why_not(s, n, r)
		if why == "":
			var st := free_station(n, str(GameData.recipes[r].station))
			if st != "":
				return {"recipe": r, "station": st}
			why = "every %s is busy" % str(GameData.recipes[r].station)
		reasons.append(why)
	if reasons.is_empty():
		s.erase("works_note")
	else:
		s.works_note = "Nothing started: " + "; ".join(reasons) + "."
	return {}


## The attendant's plan when there is work to do (Business.plan_attendant): to the station, the work, back to the counter and
## an hour minding it. False when there is none.
func plan_work(s: Dictionary, n: NPC) -> bool:
	if orders(s).is_empty():
		return false
	var job := next_job(s, n)
	if job.is_empty():
		return false
	var rec: Dictionary = GameData.recipes[job.recipe]
	var st: String = job.station
	var mins := CapabilityHook.work_time(float(rec.minutes), CapabilityHook.recipe_industry(job.recipe), Skills.value(n, str(rec.skill), "craft_time", 1.0), n)
	w.stations[st].users[n.id] = w.minutes + w.map.data.w + mins + 60.0
	n.doing = "making %s for the player's %s" % [str(job.recipe).replace("_", " "), "shop" if Business.is_shop(s) else "stall"]
	var b: NPCBrain = w.brain
	n.plan = [b.go(w.station_use(st)), b.work(mins, "craft", {"recipe": job.recipe, "station": st, "biz": str(s.id)}, "work", b._station_at(st)),
		b.go(biz.counter_cell(s)), b.work(MIND_MINUTES, "", {}, "idle")]
	n.plan[3]["industry"] = "trade"
	return true


## The craft is done (the "craft" step of a plan made above): the real recipe through World.work_craft on the workroom's
## materials, the goods into the premises. False when it could not be made (the reason is kept).
func finish(n: NPC, a: Dictionary) -> bool:
	var s: Dictionary = biz.record(str(a.biz))
	var r := str(a.recipe)
	if s.is_empty() or not biz.is_mine(s) or biz.attendant_of(s) != n or not GameData.recipes.has(r):
		return false
	var rec: Dictionary = GameData.recipes[r]
	var tmp := Inventory.new()
	for id in work_of(s):
		tmp.add(id, int(s.work[id]))
	var before: Dictionary = tmp.items.duplicate()
	var res := w.work_craft(n, r, tmp)
	if str(res.result) != "ok":
		s.works_note = "%s could not make %s (%s)." % [n.name, r.replace("_", " "), str(res.result)]
		return false
	var made := {}
	for id in rec.out:
		var k := tmp.count(id) - int(before.get(id, 0))
		if k > 0:
			made[id] = k
	s.work = {}
	for id in tmp.ids():
		if tmp.count(id) > 0:
			s.work[id] = tmp.count(id)
	for id in made:
		if shelve(s, id, int(made[id])) == "":
			w.stat("business_made_shelved_" + id, float(made[id]))
	if s.work.is_empty():
		s.erase("work")
	for o in orders(s):
		if str(o.recipe) == r and int(o.get("left", 0)) > 0:
			o.left = int(o.left) - 1
			break
	for i in range(orders(s).size() - 1, -1, -1):
		if int(orders(s)[i].get("keep", 0)) <= 0 and int(orders(s)[i].get("left", 0)) <= 0:
			s.orders.remove_at(i)
	if orders(s).is_empty():
		s.erase("orders")
	s.erase("works_note")
	w.stat("business_crafts")
	return true


## Text for the window: what the orders stand at.
func order_text(s: Dictionary, o: Dictionary) -> String:
	var r := str(o.recipe)
	if int(o.get("keep", 0)) > 0:
		return "%s: keep %d in stock (%d now)" % [r.replace("_", " "), int(o.keep), held(s, r)]
	return "%s: %d batch%s to make" % [r.replace("_", " "), int(o.left), "" if int(o.left) == 1 else "es"]
