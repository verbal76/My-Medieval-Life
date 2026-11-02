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
## Why people give (X20-CHAPEL-FIX, owner 2026-11-01, docs/directives/2026-11-01_chapel_economy_correction.md): giving is
## voluntary. Each has a piety, a fixed number 0 to 1 from the world seed and their id; on the weekly service day each adult
## and elder who can spare a coin decides through the villagers' decision framework (offerings, _decide) whether to give, and
## a giver gives a varying, affordable share; households decide the same way about spare wheat. The fund keeps an operating
## reserve (operating_reserve) and gives the surplus as alms to the poorest households by hardship (alms). Its food store
## does the same (food_alms): it keeps a food reserve for the relief it has lately given and gives the food above it to the
## households shortest of food, the poorest first; what it holds spoils as any store does (Decay.dawn).
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
var spent_week := 0                 # X20-CHAPEL-FIX: coins spent on relief food and seed since the last service (saved)
var spent: Array = []               # the same for each of the last spend_weeks weeks (saved)
var relief_week := 0.0              # chapel food (2026-11-02): food points given as relief since the last service (saved)
var relief_hist: Array = []         # the same for each of the last spend_weeks weeks (saved)
var last_service := {}              # the last service's record: gifts, reserve, alms, recipients (instrumentation; not saved)
var gift_hist := {}                 # gift size -> how many gifts of it (instrumentation; not saved)


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


## X20-CHAPEL-FIX (owner, 2026-11-01, docs/directives/2026-11-01_chapel_economy_correction.md): what a household has and
## needs, read the same way for the gifts and the alms. {members, dependents, cash (its members' purses and its storefront's
## till), stock (the food and firewood it holds, valued at today's asking prices), wealth (cash + stock), line (what its
## essentials, food and a log a night, cost over line_days at today's prices), bracket (poor below one line of wealth,
## modest below comfortable_lines, else comfortable)}.
func household_means(h: int) -> Dictionary:
	var members: Array = w.brain._members(h)
	var gc: Dictionary = cfg().gift
	var days := float(cfg().alms_line_days)
	var stores: Array = [w.households[h].pantry]
	var cash := 0
	var need_pts := 0.0
	var deps := 0
	for o: NPC in members:
		stores.append(o.inv)
		cash += o.coins
		need_pts += NPCBrain.food_factor(o) * 24.0 * float(GameData.b("hunger_per_hour")) * days
		if o.role != "adult":
			deps += 1
	var home: String = str(members[0].home) if not members.is_empty() else ""
	if home != "" and w.buildings.has(home):
		cash += BusinessMoney.till_of(w.buildings[home])
	var logs := 0
	for inv: Inventory in stores:
		logs += inv.count("log")
	var food_price: float = w._market_price("food")
	var log_price: float = w._market_price("log")
	var stock := floori(NPCBrain.store_points(stores) * food_price + float(logs) * log_price)
	var line := ceili(need_pts * food_price + ceilf(days) * log_price)
	var wealth := cash + stock
	var bracket := "poor"
	if wealth >= line * int(gc.comfortable_lines):
		bracket = "comfortable"
	elif wealth >= line:
		bracket = "modest"
	return {"members": members.size(), "dependents": deps, "cash": cash, "stock": stock, "wealth": wealth, "line": line, "bracket": bracket}


## What `n` could give today without touching what they need: their coins above their OD-19 necessity reserve
## (World.reserve_of: their household's food, fuel, medicine and rent for the next days, less what the rest of the household
## holds) and keep_coins of savings. 0 when they cannot give.
func affordable(n: NPC) -> int:
	return maxi(0, n.coins - w.reserve_of(n) - int(cfg().gift.keep_coins))


## X20-CHAPEL-FIX: whether `chooser` gives this week, an individual choice through the villagers' one decision framework
## (JudgmentWeighting.choose, judgment.json profile chapel_offering): one candidate, "give", against doing without (forgo).
## Its factors, each 0..100 points: piety (their devotion), means (what they could spare, against means_full), occasion
## (this week's circumstances and mood, a seeded roll for this person and day), dependents (the children and elders their
## household feeds, per adult; it weighs against giving), and the giver's opinion of the preacher (the disposition, from
## their judgment when it is on; neutral otherwise). Piety moves the chance but decides nothing: a devout person may keep
## their money in a hard or sour week, and one of little faith may give in a good one. Returns the decision.
func _decide(chooser: int, pt: float, spare: int, full: int, deps: int, adults: int, salt: int) -> Dictionary:
	var preacher := -1
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "preacher":
			preacher = o.id
			break
	var f := {
		"piety": roundi(pt * 100000.0),
		"means": mini(100000, spare * 100000 / maxi(1, full)),
		"occasion": JudgmentMath.roll([w.seed, chooser, w.day(), salt]) * 100,
		"dependents": mini(100000, deps * int(cfg().gift.dependent_points) / maxi(1, adults)),
	}
	var jcfg: Dictionary = w.judgment.cfg if w.judgment != null else _jcfg()
	return JudgmentWeighting.choose(w.judgment, jcfg, chooser, "chapel_offering",
		[{"id": "give", "counterparty": preacher, "factors": f}], [w.day(), chooser, salt])


static var _jcfg_cache := {}


static func _jcfg() -> Dictionary:
	if _jcfg_cache.is_empty():
		_jcfg_cache = JudgmentStore.default_cfg()
	return _jcfg_cache


## How much a giver gives: a share of what they can spare, more for the devout and in a good week, at least 1, never more
## than they can spare.
func _amount(spare: int, share: float, pt: float, occasion: int) -> int:
	return clampi(floori(float(spare) * share * (0.5 + pt) * (0.5 + float(occasion) / 100000.0)), 1, spare)


## The weekly service (X20-CHAPEL-FIX: voluntary). Every adult and elder of a household is at the service and may give.
## One who cannot spare a coin (affordable() is 0) is not asked: unable, not unwilling. The others each decide (_decide);
## a giver gives _amount of what they can spare. Nobody is penalised or remembered for not giving: the choice touches no
## judgment, no reputation and no later decision. Each household, by its first adult, decides the same way whether to give
## some of the wheat it holds beyond goods_keep_days of its own food. Nothing is taken without a choice: no tithe, no
## deduction. Returns {coins, wheat} and records the service (stats chapel_*; last_service).
func offerings() -> Dictionary:
	var gc: Dictionary = cfg().gift
	var gave_coins := 0
	var gave_wheat := 0
	var means := {}
	var svc := {"day": w.day(), "present": 0, "unable": 0, "considered": 0, "donors": 0, "declined": 0, "coins": 0, "gifts": [],
		"by": {"poor": [0, 0, 0, 0, 0], "modest": [0, 0, 0, 0, 0], "comfortable": [0, 0, 0, 0, 0]}}    # present, unable, donors, declined, coins
	for n: NPC in w.npcs:
		if not n.alive or n.role not in ["adult", "elder"] or n.household < 0 or w.households[n.household].get("ended", false):
			continue
		if not means.has(n.household):
			means[n.household] = household_means(n.household)
		var m: Dictionary = means[n.household]
		var by: Array = svc.by[m.bracket]
		svc.present += 1
		by[0] += 1
		var spare := affordable(n)
		if spare < 1:
			svc.unable += 1
			by[1] += 1
			continue
		svc.considered += 1
		var pt := piety(n)
		var adults := maxi(1, int(m.members) - int(m.dependents))
		var r := _decide(n.id, pt, spare, int(gc.means_full_coins), int(m.dependents), adults, 7)
		if str(r.chosen) != "give":
			svc.declined += 1
			by[3] += 1
			continue
		var give := _amount(spare, float(gc.share), pt, JudgmentMath.roll([w.seed, n.id, w.day(), 7]) * 100)
		n.coins -= give
		coins += give
		gave_coins += give
		svc.donors += 1
		svc.coins += give
		svc.gifts.append(give)
		by[2] += 1
		by[4] += give
	for h in w.households.size():
		if w.households[h].get("ended", false):
			continue
		var who: NPC = null
		for o: NPC in w.brain._members(h):
			if o.alive and o.role == "adult" and (who == null or o.id < who.id):
				who = o
		if who == null:
			continue
		var pantry: Inventory = w.households[h].pantry
		var keep := ceili(w.brain.household_day_food(h) * float(cfg().goods_keep_days) / NPCBrain.food_points("wheat"))
		var spare := pantry.count("wheat") - keep
		if spare < 1:
			continue
		var m: Dictionary = means[h] if means.has(h) else household_means(h)
		var pt := _household_piety(h)
		var r := _decide(who.id, pt, spare, int(gc.means_full_wheat), int(m.dependents), maxi(1, int(m.members) - int(m.dependents)), 11)
		if str(r.chosen) != "give":
			w.stat("chapel_wheat_declined")
			continue
		var give := _amount(spare, float(cfg().goods_share), pt, JudgmentMath.roll([w.seed, who.id, w.day(), 11]) * 100)
		if w.transfer(pantry, store, "wheat", give):
			gave_wheat += give
			w.stat("chapel_wheat_donors")
	w.stat("chapel_services")
	w.stat("chapel_present", svc.present)
	w.stat("chapel_unable", svc.unable)
	w.stat("chapel_considered", svc.considered)
	w.stat("chapel_donors", svc.donors)
	w.stat("chapel_declined", svc.declined)
	for b in svc.by:
		var row: Array = svc.by[b]
		w.stat("chapel_present_" + b, row[0])
		w.stat("chapel_unable_" + b, row[1])
		w.stat("chapel_donors_" + b, row[2])
		w.stat("chapel_declined_" + b, row[3])
		w.stat("chapel_gift_coins_" + b, row[4])
	for g in svc.gifts:
		gift_hist[g] = int(gift_hist.get(g, 0)) + 1
	svc.wheat = gave_wheat
	last_service = svc
	if gave_coins > 0:
		w.stat("chapel_offering_coins", gave_coins)
	if gave_wheat > 0:
		w.stat("chapel_offering_wheat", gave_wheat)
	if gave_coins + gave_wheat > 0:
		w.note("At the chapel's weekly service %d villagers gave %d coins, and households %d measures of wheat." % [svc.donors, gave_coins, gave_wheat])
	return {"coins": gave_coins, "wheat": gave_wheat}


## The player's offering of coins at the chapel: {ok, text}.
func player_offer_coins(amount: int, actor: PlayerState = null) -> Dictionary:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("chapel.player_offer_coins", player_offer_coins.bind(amount), [amount])
	if actor != null and actor != w.player:
		return w.as_actor(actor, player_offer_coins.bind(amount))
	if not present:
		return {"ok": false, "text": "There is no chapel."}
	if amount < 1 or w.player.coins < amount:
		return {"ok": false, "text": "You have not the coins for that."}
	w.player.coins -= amount
	coins += amount
	w.stat("chapel_offering_coins", amount)
	return {"ok": true, "text": "You give %d coins to the chapel. It will go first to feeding those in need." % amount}


## The player's offering of goods (food and seed): {ok, text}.
func player_offer_item(id: String, qty: int, actor: PlayerState = null) -> Dictionary:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("chapel.player_offer_item", player_offer_item.bind(id, qty), [id, qty])
	if actor != null and actor != w.player:
		return w.as_actor(actor, player_offer_item.bind(id, qty))
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
func player_ask(actor: PlayerState = null) -> Dictionary:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("chapel.player_ask", player_ask.bind(), [])
	if actor != null and actor != w.player:
		return w.as_actor(actor, player_ask)
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
		if not w.brain.noted.has("chapel_%d_%d" % [n.household, w.day()]):
			JudgmentLive.on_news(w, "relief", "hhid:%d" % n.household, ["giver:chapel"], n.pos)     # A5: the household knows; those at the chapel saw
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
			spent_week += price
	var given := total - maxf(need, 0.0)
	if given > 0.0:
		w.stat("chapel_relief_points", given)
		relief_week += given
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
			spent_week += price * qty
			need -= qty
			w.stat("chapel_seed_bought", qty)


## 16:00, before the manor's evening business: on the service day the offerings, then the clergy's wages from the fund, then
## (service day) the alms from the surplus above the operating reserve (CHAPEL-R2, X20-CHAPEL-FIX).
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
		food_alms()


## X20-CHAPEL-FIX (owner, 2026-11-01): the chapel's operating reserve, what it keeps back on the service day for the costs it
## can foresee: its clergy's wages for operating_reserve_days, the wages it already owes, and what it has spent of late on
## relief food and seed (the mean of the last spend_weeks weeks, for the same days). Everything above it is surplus.
func operating_reserve() -> int:
	var days := int(cfg().operating_reserve_days)
	var keep := 0
	for o: NPC in w.npcs:
		if is_clergy(o):
			keep += wage_of(o.job) * days
	for k in owed:
		keep += int(owed[k])
	if not spent.is_empty():
		var sum := 0
		for s in spent:
			sum += int(s)
		keep += ceili(float(sum) / float(spent.size()) * float(days) / float(cfg().offering_every_days))
	return keep


## CHAPEL-R2 (owner, 2026-10-23: "offerings keep the priest, and what is left goes as alms to the poorest households"), as
## X20-CHAPEL-FIX (owner, 2026-11-01) corrects it. On the service day, after the offerings and the wages, the chapel keeps
## its operating reserve and gives the surplus as alms to the poorest households by genuine hardship. A household's means
## (household_means) count its cash, its storefront till and the value of the food and firewood it holds; a household whose
## wealth is alms_wealth_lines or more of its essentials line gets nothing, however little cash it has on the day (the
## wealthy who are short of coin are not poor). Each other household's hardship is the larger of its necessity shortfall
## (World.necessity: food, fuel, medicine and rent due, less what its members hold) and what its cash falls short of one
## line (food in the larder does not pay rent, buy firewood or let it trade). The poorest first: least wealth for each
## member (so dependants count), then the greater hardship, then the household's index; each is given up to its hardship,
## once, to one adult (else an elder; the lowest id). Every coin goes from the fund to a named person; the fund never goes
## below its reserve. Returns the coins given.
func alms() -> int:
	if not present:
		return 0
	spent.append(spent_week)
	while spent.size() > int(cfg().spend_weeks):
		spent.pop_front()
	spent_week = 0
	var keep := operating_reserve()
	var pot := coins - keep
	var svc: Dictionary = last_service if int(last_service.get("day", -1)) == w.day() else {"day": w.day()}
	svc.reserve = keep
	svc.fund_before_alms = coins
	svc.alms = 0
	svc.recipients = []
	last_service = svc
	if pot <= 0:
		return 0
	var rows := []                      # [wealth per member, -hardship, household, payee, means]
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
		var m := household_means(h)
		if int(m.wealth) >= int(m.line) * int(cfg().alms_wealth_lines):
			continue
		var hard := maxi(household_shortfall(h), int(m.line) - int(m.cash))
		if hard > 0:
			rows.append([int(m.wealth) * 1000 / maxi(1, int(m.members)), -hard, h, payee, m])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and (a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))))
	var given := 0
	var helped := 0
	for r in rows:
		var give := mini(-int(r[1]), pot)
		if give <= 0:
			break
		var m: Dictionary = r[4]
		(r[3] as NPC).coins += give
		coins -= give
		pot -= give
		given += give
		helped += 1
		svc.recipients.append({"household": int(r[2]), "bracket": m.bracket, "cash_before": int(m.cash), "cash_after": int(m.cash) + give,
			"wealth": int(m.wealth), "line": int(m.line), "members": int(m.members), "given": give})
	svc.alms = given
	if given > 0:
		w.stat("chapel_alms_coins", given)
		w.stat("chapel_alms_households", helped)
		w.note("The chapel gave %d coins in alms to %d of the village's poorest households." % [given, helped])
	return given


## Chapel food (2026-11-02; CHAPEL-R2 and X20-CHAPEL-FIX applied to the food store): the food the store keeps back, in food
## points: the mean relief it gave over the last spend_weeks weeks, for operating_reserve_days. What is above it is surplus.
func food_reserve() -> int:
	if relief_hist.is_empty():
		return 0
	var sum := 0.0
	for r in relief_hist:
		sum += float(r)
	return ceili(sum / float(relief_hist.size()) * float(cfg().operating_reserve_days) / float(cfg().offering_every_days))


## Chapel food (2026-11-02): on the service day, after the coin alms, the food in the store above food_reserve is given as alms,
## as the coins are (CHAPEL-R2, owner 2026-10-23: "what is left goes as alms to the poorest households"; X20-CHAPEL-FIX, owner
## 2026-11-01: after the operating reserve, the surplus goes in charitable alms by genuine hardship, food security among it).
## Food hardship: a household holding less than alms_line_days of food (NPCBrain.household_food_days: what it holds and what
## its coins would buy now) lacks the rest of those days' food; a household worth alms_wealth_lines lines or more
## (household_means) gets nothing. The poorest for each member first (wealth per member, then the greater shortfall, then the
## household's index), each given up to its shortfall, once, into its pantry: grain first, then the other food, in whole
## units, never taking the store below its reserve. Every unit moves from the store to a pantry (World.transfer); nothing is
## made. Returns the food points given.
func food_alms() -> float:
	if not present:
		return 0.0
	relief_hist.append(relief_week)
	while relief_hist.size() > int(cfg().spend_weeks):
		relief_hist.pop_front()
	relief_week = 0.0
	var keep := food_reserve()
	var pot := _store_points() - float(keep)
	var svc: Dictionary = last_service if int(last_service.get("day", -1)) == w.day() else {"day": w.day()}
	svc.food_reserve = keep
	svc.food_before_alms = roundi(_store_points())
	svc.food_alms = 0
	svc.food_recipients = 0
	last_service = svc
	if pot <= 0.0:
		return 0.0
	var line_days := float(cfg().alms_line_days)
	var rows := []                      # [wealth per member, -shortfall, household]
	for h in w.households.size():
		if w.households[h].get("ended", false) or w.brain._members(h).is_empty():
			continue
		var m := household_means(h)
		if int(m.wealth) >= int(m.line) * int(cfg().alms_wealth_lines):
			continue
		var days: float = w.brain.household_food_days(h)
		if days >= line_days:
			continue
		var short: float = (line_days - days) * w.brain.household_day_food(h)
		if short > 0.0:
			rows.append([int(m.wealth) * 1000 / maxi(1, int(m.members)), -short, h])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and (a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))))
	var order: Array = ["wheat"]
	for f in NPCBrain.EDIBLE:
		if f != "wheat":
			order.append(f)
	var given := 0.0
	var helped := 0
	for r in rows:
		if pot <= 0.0:
			break
		var need: float = -float(r[1])
		var pantry: Inventory = w.households[int(r[2])].pantry
		var got := 0.0
		for f in order:
			var pts := NPCBrain.food_points(f)
			if pts <= 0.0 or need <= 0.0 or not store.has(f):
				continue
			var k := mini(store.count(f), mini(ceili(need / pts), floori(pot / pts)))
			if k > 0 and w.transfer(store, pantry, f, k):
				need -= float(k) * pts
				pot -= float(k) * pts
				got += float(k) * pts
				w.stat("chapel_food_alms_" + f, k)
		if got > 0.0:
			given += got
			helped += 1
	svc.food_alms = roundi(given)
	svc.food_recipients = helped
	if given > 0.0:
		w.stat("chapel_food_alms_points", given)
		w.stat("chapel_food_alms_households", helped)
		w.note("The chapel gave food from its store to %d of the village's households shortest of food." % helped)
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
		"owed": owed.duplicate(), "evening_day": evening_day, "player_asked_day": player_asked_day, "spent_week": spent_week,
		"spent": spent.duplicate(), "relief_week": relief_week, "relief_hist": relief_hist.duplicate()}


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
	spent_week = int(d.get("spent_week", 0))                 # X20-CHAPEL-FIX: optional (a save from before it spent nothing it knows of)
	spent = (d.get("spent", []) as Array).map(func(v): return int(v))
	relief_week = float(d.get("relief_week", 0.0))             # chapel food (2026-11-02): optional (an older save gave none it knows of)
	relief_hist = (d.get("relief_hist", []) as Array).map(func(v): return float(v))
	if bool(d.get("present", true)):
		found(false)
	else:
		present = false
