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
## CHAPEL-PURPOSE (owner, 2026-11-02, docs/directives/2026-11-02_chapel_economic_purpose_correction.md): the chapel maintains
## itself and does not enrich itself. Its food goes out by two programmes (the relief section): an emergency round every
## dawn and evening that finds households in imminent hunger itself, and the weekly food alms to households under the
## 14-day hardship line (alms_line_days, the coin alms' line); both are carried to the household (parcels), never teleported.
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
var parcels: Array = []             # CHAPEL-PURPOSE: food given and on its way, the chapel's until delivered (saved):
                                    # {id, hh (-1: going back to the store), at [x, y], inv, day, urgent, why (relief|alms), carrier (npc id or -1), held}
var next_parcel := 1                # (saved)
var missed := {}                    # household index -> the last day a member missed a meal for want of food (saved)
# instrumentation only (CHAPEL-PURPOSE section 6; read by economy_sim, never by a rule; not saved)
var diag_eval := {}                 # household -> {day, days, emergency | alms}: its last assessment
var diag_offered := {}              # household -> the last day food was set aside for it
var diag_delivered := {}            # household -> the last day food reached it
var diag_asked := {}                # household -> the last day a member asked
var diag_unhelped := {}             # household -> [day, reason]: the last time it qualified and was not brought to the line
var diag_helped := {}               # households given emergency food (set)
var diag_recipients := {}           # households food reached (set)
var diag_alms_recipients := {}      # households given coin alms (set)
var death_log: Array = []           # each starvation death: the household's and the chapel's position (on_starved)


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
## some of the wheat it holds beyond alms_line_days of its own food (CHAPEL-PURPOSE: a household inside the 14-day hardship
## line the chapel's alms use has no food to spare, so food given as alms is not offered back). Nothing is taken without a choice: no tithe, no
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
		var keep := ceili(w.brain.household_day_food(h) * float(cfg().alms_line_days) / NPCBrain.food_points("wheat"))
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
## CHAPEL-PURPOSE (owner, 2026-11-02, docs/directives/2026-11-02_chapel_economic_purpose_correction.md): the chapel's food
## exists to feed people in hardship. Two programmes, one store:
##  - emergency relief (relief_round), every dawn and every evening at 16:00: the chapel looks for households in imminent
##    hunger itself (under relief_trigger_days of food, NPCBrain.household_food_days, counting food already on its way from
##    the chapel; or a member missed a meal for want of food within missed_meal_days and it holds under relief_fill_days),
##    nobody need walk to ask. It gives from its whole store (the food reserve is kept for this) and, when that is not
##    enough, buys with its coins from the sellers the manor's relief buys from (NPCBrain._relief_offers). Fairly: first
##    every such household is brought to one day of food, those whose people are missing meals first, then those with
##    children or elders, then the fewest days; then all of them, the fewest days first, toward relief_fill_days.
##  - ordinary food alms (food_alms), on the service day: the store's food above its emergency reserve (food_reserve) goes
##    to households under the owner's 14-day hardship line (alms_line_days, the line the coin alms use), not to the
##    well-off (alms_wealth_lines), the fewest days of food first, each raised in turn so the food is shared out rather
##    than spent on the first household.
## The food that spoils fastest leaves first (give_order: the store records no ages, so the shortest-keeping food is the
## food nearest to spoiling; grain, which keeps longest, last). Nothing is teleported: what the chapel gives is set aside
## in a parcel, the chapel's until it reaches the household, lying where it is (the chapel's door, or a seller's when it
## was bought), and it is carried there by the clergy or the volunteers (plan_deliver; the most urgent first, up to
## manor_jobs.haul_max units a trip), or fetched by a member of the household (plan_ask, ask: one who comes to the chapel
## takes home what is waiting for the household). Parcels spoil like any store. The manor's relief counts a parcel made
## today or yesterday as on its way (NPCBrain._relief), so the two do not both give. WDR-022: a chapel with nothing gives
## nothing, and a household it cannot reach in time may still go hungry.
func _store_points() -> float:
	return NPCBrain.store_points([store])


## Whether the church has anything to give a household in need: food in its store or coins to buy it with.
func can_give() -> bool:
	return present and (_store_points() > 0.0 or coins > 0)


## The order food leaves the store: the edible goods that spoil fastest first (balance decay.spoil), then the rest in
## NPCBrain.EDIBLE's order; grain (wheat 0.004 a day) last of the perishables.
static func give_order() -> Array:
	var ids: Array = NPCBrain.EDIBLE.duplicate()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ra := Decay.rate(a)
		var rb := Decay.rate(b)
		return ra > rb or (ra == rb and NPCBrain.EDIBLE.find(a) < NPCBrain.EDIBLE.find(b)))
	return ids


## A member of `n`'s household missed a meal for want of food (NPCBrain, the missed-meal path): remembered for the
## emergency round's priority.
func note_missed(n: NPC) -> void:
	if present and n != null and n.household >= 0:
		missed[n.household] = w.day()


func is_missing_meals(h: int) -> bool:
	return int(missed.get(h, -1000)) >= w.day() - int(cfg().missed_meal_days)


func _vulnerable(h: int) -> bool:
	return w.brain._members(h).any(func(o: NPC) -> bool: return o.role in ["child", "elder"])


## The parcels on their way to household `h` (made on day `since` or later).
func parcels_for(h: int, since := -1000000) -> Array:
	return parcels.filter(func(p: Dictionary) -> bool: return int(p.hh) == h and int(p.day) >= since)


## The food points on their way to household `h` from the chapel (parcels made on day `since` or later): what they add to
## the household's own stores.
func pending_points(h: int, since := -1000000) -> float:
	var ps := parcels_for(h, since)
	if ps.is_empty():
		return 0.0
	var stores: Array = w.brain.household_stores(h)
	var invs: Array = stores.duplicate()
	for p in ps:
		invs.append(p.inv)
	return NPCBrain.store_points(invs) - NPCBrain.store_points(stores)


## Household `h`'s days of food (NPCBrain.household_food_days) with what the chapel has on its way to it.
func projected_days(h: int) -> float:
	return w.brain.household_food_days(h) + pending_points(h) / maxf(1.0, w.brain.household_day_food(h))


func _wheat_of(h: int) -> int:
	var k := 0
	for inv: Inventory in w.brain.household_stores(h):
		k += inv.count("wheat")
	for p in parcels_for(h):
		k += (p.inv as Inventory).count("wheat")
	return k


## The household rows the sharing works on: {h, days, day_food, wheat, prio (0 missing meals, 1 children or elders, 2
## other), tie (a second key: wealth for each member in the alms; 0 in relief), start}.
func _row(h: int, d: float, tie: int) -> Dictionary:
	var prio := 0 if is_missing_meals(h) else (1 if _vulnerable(h) else 2)
	return {"h": h, "days": d, "day_food": maxf(1.0, w.brain.household_day_food(h)), "wheat": _wheat_of(h), "prio": prio, "tie": tie, "start": d}


static func _before(a: Dictionary, b: Dictionary, prio_first: bool) -> bool:
	var ka := [int(a.prio), float(a.days)] if prio_first else [float(a.days), int(a.prio)]
	var kb := [int(b.prio), float(b.days)] if prio_first else [float(b.days), int(b.prio)]
	ka.append_array([int(a.tie), int(a.h)])
	kb.append_array([int(b.tie), int(b.h)])
	for i in ka.size():
		if ka[i] != kb[i]:
			return ka[i] < kb[i]
	return false


## A parcel of the chapel's food for household `h` lying at `at` (merged with one of today's still waiting there).
func _parcel(h: int, at: Vector2i, urgent: bool, why: String) -> Dictionary:
	for p in parcels:
		if int(p.hh) == h and int(p.carrier) < 0 and not bool(p.held) and int(p.at[0]) == at.x and int(p.at[1]) == at.y \
				and bool(p.urgent) == urgent and str(p.why) == why and int(p.day) == w.day():
			return p
	var p := {"id": next_parcel, "hh": h, "at": [at.x, at.y], "inv": Inventory.new(), "day": w.day(), "urgent": urgent, "why": why,
		"carrier": -1, "held": false}
	next_parcel += 1
	parcels.append(p)
	diag_offered[h] = w.day()
	return p


## Share up to `pot` food points of the store among `rows`, set aside in parcels at the chapel's door: a portion at a time
## (a pot's grain, or one unit of other food, the fastest-spoiling first) to the row first by _before among those still
## under `target` days, until none is under it or the pot or the store is spent. Returns the points set aside.
func _share_store(rows: Array, target: float, pot: float, urgent: bool, why: String, prio_first: bool) -> float:
	var order := give_order()
	var batch := NPCBrain.pottage_batch()
	var given := 0.0
	var at := door_cell()
	while pot > 0.0:
		var best := {}
		for r in rows:
			if float(r.days) < target and (best.is_empty() or _before(r, best, prio_first)):
				best = r
		if best.is_empty():
			break
		var f := ""
		var qty := 0
		for id in order:
			var pts := NPCBrain.food_points(id)
			if pts <= 0.0 or not store.has(id):
				continue
			var q := 1
			if id == "wheat":
				q = mini(store.count("wheat"), batch - int(best.wheat) % batch)
			if float(q) * pts <= pot + 0.001:
				f = id
				qty = q
				break
		if f == "":
			break
		var p := _parcel(int(best.h), at, urgent, why)
		if not w.transfer(store, p.inv, f, qty):
			break
		var got := float(qty) * NPCBrain.food_points(f)
		pot -= got
		given += got
		best.days = float(best.days) + got / float(best.day_food)
		if f == "wheat":
			best.wheat = int(best.wheat) + qty
		w.stat("chapel_%s_%s" % [why, f], qty)
	return given


## Buy food for `rows` with the fund toward `target` days, in _before order, from the sellers the manor's relief buys from
## (NPCBrain._relief_offers: cheapest food point first), paid to them; what is bought is the chapel's, set aside in a
## parcel where it lies (the seller's) to be carried. Returns the points bought.
func _buy_for(rows: Array, target: float, prio_first: bool) -> float:
	var ordered := rows.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _before(a, b, prio_first))
	var batch := NPCBrain.pottage_batch()
	var given := 0.0
	for r in ordered:
		if coins <= 0:
			break
		var need := (target - float(r.days)) * float(r.day_food)
		if need <= 0.0:
			continue
		var offers: Array = w.brain._relief_offers(int(r.h))
		var i := 0
		while need > 0.0 and i < offers.size() and coins > 0:
			var o: Dictionary = offers[i]
			var src: Inventory = o.inv
			if int(o.left) <= 0 or not src.has(o.item):
				i += 1
				continue
			var qty := 1
			if o.item == "wheat":
				qty = mini(batch - int(r.wheat) % batch, mini(int(o.left), src.count("wheat")))
			var price: int = (w.sell_price(o.payee, o.item) if bool(o.trader) else int(o.price)) * qty
			if price > coins:
				break
			if src == (o.payee as NPC).inv and not w.claims_release(o.payee, o.item, qty):
				i += 1                           # LE-03: no claim on it broken (nothing while the economy is off)
				continue
			var p := _parcel(int(r.h), o.cell, true, "relief")
			if not w.transfer(src, p.inv, o.item, qty):
				i += 1
				continue
			var payee: NPC = o.payee
			payee.coins += price
			payee.earned += price
			coins -= price
			o.left = int(o.left) - qty
			var got := float(o.pts) * qty
			need -= got
			given += got
			r.days = float(r.days) + got / float(r.day_food)
			if o.item == "wheat":
				r.wheat = int(r.wheat) + qty
			w.stat("chapel_relief_bought", price)
			w.stat("chapel_relief_bought_" + str(o.item), qty)
			spent_week += price
	return given


## The emergency round (dawn and 16:00, and when someone asks): see the section note. Returns the food points set aside.
func relief_round() -> float:
	if not present:
		return 0.0
	release_stale()
	var trig := float(GameData.b("relief_trigger_days"))
	var fill := float(GameData.b("relief_fill_days"))
	var rows := []
	for h in w.households.size():
		if w.households[h].get("ended", false) or w.brain._members(h).is_empty():
			continue
		var d := projected_days(h)
		if d < trig or (is_missing_meals(h) and d < fill):
			rows.append(_row(h, d, 0))
	for r in rows:
		diag_eval[int(r.h)] = {"day": w.day(), "days": snappedf(float(r.days), 0.01), "emergency": true}
	if rows.is_empty():
		return 0.0
	w.stat("chapel_emergency_found", rows.size())
	var given := _share_store(rows, 1.0, _store_points(), true, "relief", true)
	given += _share_store(rows, fill, _store_points(), true, "relief", false)
	if coins > 0:
		given += _buy_for(rows, 1.0, true)
		given += _buy_for(rows, fill, false)
	for r in rows:
		var h := int(r.h)
		if float(r.days) > float(r.start):
			w.stat("chapel_relief_households")
			diag_helped[h] = true
		if float(r.days) < trig:
			var why := "chapel_empty" if _store_points() <= 0.0 and coins <= 0 else ("fund_spent" if coins <= 0 else "none_for_sale")
			_unhelped(h, why)
	if given > 0.0:
		w.stat("chapel_relief_points", given)
		relief_week += given
	return given


## Instrumentation: a household that qualified and was not brought to the line, and why (read by economy_sim; no rule reads it).
func _unhelped(h: int, why: String) -> void:
	w.stat("chapel_unhelped_" + why)
	diag_unhelped[h] = [w.day(), why]


## A villager's trip to the chapel, planned into n.plan (NPCBrain._plan_evening): to take home food the chapel has waiting
## for the household at its door, or, for a household short of food (under relief_trigger_days, counting food on its way),
## to ask. One member a day. True when planned.
func plan_ask(n: NPC) -> bool:
	if not present or n.household < 0 or n.role not in ["adult", "elder"]:
		return false
	var h := n.household
	var d: int = w.day()
	if int(booked.get(h, -1)) == d:
		return false
	var waiting := _waiting(h)
	if waiting.is_empty():
		if int(asked.get(h, -1)) == d or not can_give() or projected_days(h) >= float(GameData.b("relief_trigger_days")):
			return false
	booked[h] = d
	n.doing = "going to the chapel to ask for food" if waiting.is_empty() else "going to the chapel for the church's food"
	n.plan = [w.brain.go(door_cell()), w.brain.doit("church_ask", {})]
	return true


## The parcels for household `h` waiting at the chapel's door with nobody carrying them.
func _waiting(h: int) -> Array:
	var c := door_cell()
	return parcels.filter(func(p: Dictionary) -> bool: return int(p.hh) == h and int(p.carrier) < 0 and not bool(p.held) \
		and int(p.at[0]) == c.x and int(p.at[1]) == c.y)


## A villager arrives at the chapel for their household: the chapel runs its emergency round (it gives to the asker's
## household if it is short, and to any other in the same need), and the asker takes home what is waiting for the household
## at the door (up to a load), to put in its pantry (church_deliver). True when they carry something home.
func ask(n: NPC) -> bool:
	if not present or n.household < 0:
		return false
	var h := n.household
	booked.erase(h)
	if _waiting(h).is_empty():
		asked[h] = w.day()
		w.stat("chapel_asked")
		diag_asked[h] = w.day()
	relief_round()
	var got := 0.0
	var units := 0
	var steps := []
	for p in _waiting(h):
		if units >= int(GameData.b("manor_jobs").haul_max):
			break
		p.carrier = n.id
		_pick(p)
		units += (p.inv as Inventory).total()
		got += NPCBrain.store_points([p.inv])
		steps.append(w.brain.doit("church_deliver", {"p": int(p.id)}))
	if steps.is_empty():
		return false
	n.doing = "carrying the church's food home"
	n.plan.append(w.brain.go(_dest(h)))
	n.plan.append_array(steps)
	w.stat("chapel_fetched")
	w.stat("chapel_relieved")
	if not w.brain.noted.has("chapel_%d_%d" % [h, w.day()]):
		JudgmentLive.on_news(w, "relief", "hhid:%d" % h, ["giver:chapel"], n.pos)     # A5: the household knows; those at the chapel saw
	w.brain.once("chapel_%d_%d" % [h, w.day()], "The chapel gave the %s household food." % w.households[h].family)
	return got > 0.0


## Where a parcel for household `h` is taken: its house's door; a household between homes, where a member is; a parcel
## with no household any more (h -1) goes back to the chapel's door.
func _dest(h: int) -> Vector2i:
	if h < 0:
		return door_cell()
	var home := str(w.households[h].get("home", ""))
	if home != "" and w.buildings.has(home):
		return w.building_door(home)
	var ms: Array = w.brain._members(h)
	return (ms[0] as NPC).cell() if not ms.is_empty() else door_cell()


func parcel(id: int) -> Dictionary:
	for p in parcels:
		if int(p.id) == id:
			return p
	return {}


## Take up parcel `p` (its carrier's): a load of at most manor_jobs.haul_max units; the rest stays where it lies, a parcel of its own.
func _pick(p: Dictionary) -> void:
	var cap := int(GameData.b("manor_jobs").haul_max)
	var inv: Inventory = p.inv
	if inv.total() > cap:
		var rest := {"id": next_parcel, "hh": p.hh, "at": (p.at as Array).duplicate(), "inv": Inventory.new(), "day": p.day, "urgent": p.urgent,
			"why": p.why, "carrier": -1, "held": false}
		next_parcel += 1
		var over := inv.total() - cap
		var ids := inv.ids()
		ids.reverse()
		for id in ids:
			var k := mini(over, inv.count(id))
			if k > 0 and w.transfer(inv, rest.inv, id, k):
				over -= k
		parcels.append(rest)
	p.held = true


## A clergy member's or volunteer's carrying round, planned into n.plan: the most urgent parcel nobody carries (emergency
## relief first, then the oldest), from where it lies to its household. True when planned.
func plan_deliver(n: NPC) -> bool:
	if not present or parcels.is_empty() or not (is_clergy(n) or volunteers.has(n.id)) or not w.farm_plots.able(n):
		return false
	release_stale()
	var best := {}
	for p in parcels:
		if int(p.carrier) >= 0:
			continue
		if best.is_empty() or (bool(p.urgent) and not bool(best.urgent)) or (bool(p.urgent) == bool(best.urgent) \
				and (int(p.day) < int(best.day) or (int(p.day) == int(best.day) and int(p.id) < int(best.id)))):
			best = p
	if best.is_empty():
		return false
	best.carrier = n.id
	var h := int(best.hh)
	n.doing = "carrying the church's food to the %s household" % str(w.households[h].family) if h >= 0 else "carrying the church's food back"
	n.plan = [w.brain.go(Vector2i(int(best.at[0]), int(best.at[1]))), w.brain.doit("church_pickup", {"p": int(best.id)}),
		w.brain.go(_dest(h)), w.brain.doit("church_deliver", {"p": int(best.id)})]
	w.stat("chapel_carry_trips")
	return true


## The carrier takes up the parcel where it lies (NPCBrain.act "church_pickup").
func pickup(n: NPC, a: Dictionary) -> bool:
	var p := parcel(int(a.get("p", -1)))
	if p.is_empty() or int(p.carrier) != n.id:
		return false
	if not bool(p.held):
		_pick(p)
	return true


## The carrier puts the parcel into its household's pantry (back into the chapel's store when the household is gone)
## (NPCBrain.act "church_deliver"). What does not fit stays in the parcel, set down where the carrier stands.
func deliver(n: NPC, a: Dictionary) -> bool:
	var p := parcel(int(a.get("p", -1)))
	if p.is_empty() or int(p.carrier) != n.id or not bool(p.held):
		return false
	var h := int(p.hh)
	if h >= 0 and (w.households[h].get("ended", false) or w.brain._members(h).is_empty()):
		h = -1
	var into: Inventory = store if h < 0 else w.households[h].pantry
	var inv: Inventory = p.inv
	var pts := NPCBrain.store_points([inv])
	for id in inv.ids():
		w.transfer(inv, into, id, inv.count(id))
	var moved := pts - NPCBrain.store_points([inv])
	if h >= 0 and moved > 0.0:
		w.stat("chapel_delivered_points", moved)
		w.stat("chapel_delivered_%s_points" % str(p.why), moved)
		w.stat("chapel_deliveries")
		diag_delivered[h] = w.day()
		diag_recipients[h] = true
	elif h < 0:
		w.stat("chapel_returned_points", moved)
	if inv.total() == 0:
		parcels.erase(p)
	else:
		var c := n.cell()
		p.at = [c.x, c.y]
		p.carrier = -1
		p.held = false
	return true


## Parcels whose carrier no longer means to carry them (dead, or their plan was given up) are set down where the carrier
## stands, for another to take; a parcel for a household that has ended goes back to the store when it still lies at the
## chapel's door, and is carried back there otherwise.
func release_stale() -> void:
	var door := door_cell()
	for p in parcels.duplicate():
		var c := int(p.carrier)
		if c >= 0:
			var o: NPC = w.npc(c)
			var pid := int(p.id)
			var live: bool = o != null and o.alive and o.plan.any(func(s) -> bool: return str(s.get("k", "")) == "do" \
				and str(s.get("act", "")).begins_with("church_") and int((s.get("args", {}) as Dictionary).get("p", -1)) == pid)
			if not live:
				if bool(p.held) and o != null:
					var cell := o.cell()
					p.at = [cell.x, cell.y]
				p.held = false
				p.carrier = -1
				w.stat("chapel_carry_dropped")
		var h := int(p.hh)
		if h >= 0 and (w.households[h].get("ended", false) or w.brain._members(h).is_empty()):
			if int(p.carrier) < 0 and int(p.at[0]) == door.x and int(p.at[1]) == door.y:
				var inv: Inventory = p.inv
				for id in inv.ids():
					w.transfer(inv, store, id, inv.count(id))
				parcels.erase(p)
			else:
				p.hh = -1


## Every unit in the chapel's parcels (the census: SettlementHoldings counts them as the chapel's).
func parcel_goods() -> Dictionary:
	var g := {}
	for p in parcels:
		var inv: Inventory = p.inv
		for id in inv.items:
			g[id] = int(g.get(id, 0)) + int(inv.items[id])
	return g


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
	relief_round()                      # CHAPEL-PURPOSE: the morning's emergency round


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
			w.stat("chapel_seed_coins", price * qty)


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
	relief_round()                      # CHAPEL-PURPOSE: emergency relief before anything discretionary
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
		diag_alms_recipients[int(r[2])] = true
		svc.recipients.append({"household": int(r[2]), "bracket": m.bracket, "cash_before": int(m.cash), "cash_after": int(m.cash) + give,
			"wealth": int(m.wealth), "line": int(m.line), "members": int(m.members), "given": give})
	svc.alms = given
	if given > 0:
		w.stat("chapel_alms_coins", given)
		w.stat("chapel_alms_households", helped)
		w.note("The chapel gave %d coins in alms to %d of the village's poorest households." % [given, helped])
	return given


## The food the store keeps back, in food points: its modest emergency reserve (CHAPEL-PURPOSE section 1). The chapel keeps
## food for nothing else: its clergy are paid wages and eat at their own households' tables, it keeps no animals, and its
## seed corn is seed (not food) and is never given. The reserve is the emergency relief it has given lately (the mean of
## the last spend_weeks weeks) for food_reserve_days: one week, until the next service, while the plot keeps cropping. Food
## above it goes as food alms to households under the hardship line; the emergency round may use the reserve itself.
func food_reserve() -> int:
	if relief_hist.is_empty():
		return 0
	var sum := 0.0
	for r in relief_hist:
		sum += float(r)
	return ceili(sum / float(relief_hist.size()) * float(cfg().food_reserve_days) / float(cfg().offering_every_days))


## The ordinary food alms (CHAPEL-PURPOSE section 1; CHAPEL-R2, X20-CHAPEL-FIX), on the service day after the coin alms: the
## store's food above food_reserve goes to the households under the owner's 14-day hardship line (alms_line_days, the line
## the coin alms use: NPCBrain.household_food_days, its stores and what its coins buy now, with what the chapel has on its
## way to it), except those worth alms_wealth_lines lines or more (household_means). Shared fairly: a portion at a time to
## the household with the fewest days of food (then missing meals, then children or elders, then the least wealth for
## each member, then its index), until each reaches the line or the surplus is spent; the fastest-spoiling food first.
## Set aside in parcels at the chapel's door, carried or fetched (plan_deliver, plan_ask). Returns the food points given.
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
	var line_days := float(cfg().alms_line_days)
	var rows := []
	for h in w.households.size():
		if w.households[h].get("ended", false) or w.brain._members(h).is_empty():
			continue
		var m := household_means(h)
		if int(m.wealth) >= int(m.line) * int(cfg().alms_wealth_lines):
			continue
		var d := projected_days(h)
		if d < line_days:
			rows.append(_row(h, d, int(m.wealth) * 1000 / maxi(1, int(m.members))))
			diag_eval[h] = {"day": w.day(), "days": snappedf(d, 0.01), "alms": true}
	w.stat("chapel_food_alms_eligible", rows.size())
	var given := 0.0
	if pot > 0.0:
		given = _share_store(rows, line_days, pot, false, "alms", false)
	var helped := 0
	for r in rows:
		if float(r.days) > float(r.start):
			helped += 1
		if float(r.days) < line_days:
			_unhelped(int(r.h), "alms_reserve" if pot <= 0.0 else "alms_surplus_spent")
	svc.food_alms = roundi(given)
	svc.food_recipients = helped
	if given > 0.0:
		w.stat("chapel_food_alms_points", given)
		w.stat("chapel_food_alms_households", helped)
		w.note("The chapel set aside food from its store for %d of the village's households short of food." % helped)
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
	if plan_deliver(n):                 # CHAPEL-PURPOSE: food waiting to be carried comes before the field
		return true
	return w.farm_plots.plan_church(n, n.role != "adult")


## A clergy member's working day: with volunteers to work the plot they keep the chapel; with none, they work it themselves
## (the owner: "if they don't volunteer then the clergy ... work the fields themselves"). True when planned.
func plan_clergy(n: NPC) -> bool:
	if not present:
		return false
	if plan_deliver(n):                 # CHAPEL-PURPOSE: carrying food to a household in need comes first
		return true
	if volunteers_able() == 0 and not (n.job == "preacher" and is_service_day()) and w.farm_plots.plan_church(n, false):
		return true
	n.doing = "keeping the chapel" if n.job == "church_assistant" else "preaching at the chapel"
	n.plan = [w.brain.go(w.brain.wander_cell(door_cell(), 2)), w.brain.work(60, "", {}, "idle")]
	return true


## Instrumentation (CHAPEL-PURPOSE section 5), read only: `n` is about to die of hunger (World._update_npc). Records the
## household's food and coins, the chapel's food and fund, its last assessment of the household, whether it asked, was
## offered food, has food on its way (and whether anyone is carrying it) or received some, and the last reason it went
## unhelped. Reads plain values only (no price is looked up: a price lookup fills the hour's price cache), so it changes
## nothing in the world.
func on_starved(n: NPC) -> void:
	if not present or n.household < 0:
		return
	var h := n.household
	var stores: Array = w.brain.household_stores(h)
	var hc := 0
	for o: NPC in w.brain._members(h):
		hc += o.coins
	var day_food := maxf(1.0, w.brain.household_day_food(h))
	var on_way := 0.0
	var carried := 0
	var pend := 0
	for p in parcels_for(h):
		on_way += NPCBrain.store_points([p.inv])
		pend += 1
		if int(p.carrier) >= 0:
			carried += 1
	var ev: Dictionary = diag_eval.get(h, {})
	var qualified: bool = not ev.is_empty() and int(ev.day) >= w.day() - 1
	var cp := _store_points()
	var rec := {"day": w.day(), "hour": snappedf(w.hour(), 0.1), "npc": n.id, "role": n.role, "hh": h, "members": w.brain._members(h).size(),
		"hh_points": snappedf(NPCBrain.store_points(stores), 1), "hh_stores_days": snappedf(NPCBrain.store_points(stores) / day_food, 0.01), "hh_coins": hc,
		"chapel_points": snappedf(cp, 1), "chapel_coins": coins, "last_eval": ev, "qualified_recently": qualified,
		"asked_day": int(diag_asked.get(h, -1)), "offered_day": int(diag_offered.get(h, -1)), "delivered_day": int(diag_delivered.get(h, -1)),
		"parcels_pending": pend, "parcels_carried": carried, "points_on_way": snappedf(on_way, 1), "unhelped": diag_unhelped.get(h, []),
		"missing_meals": is_missing_meals(h)}
	death_log.append(rec)
	w.stat("chapel_starved")
	if qualified:
		w.stat("chapel_starved_eligible")
	if qualified and (cp > 0.0 or coins > 0):
		w.stat("chapel_starved_eligible_chapel_had_means")


## Whether `n` may work the church plot: a volunteer, or the clergy.
func may_work(n: NPC) -> bool:
	return present and (volunteers.has(n.id) or is_clergy(n))


# ---------------------------------------------------------------- save ------------------------
func to_dict() -> Dictionary:
	return {"present": present, "coins": coins, "store": store.to_dict(), "volunteers": volunteers.duplicate(), "asked": asked.duplicate(),
		"owed": owed.duplicate(), "evening_day": evening_day, "player_asked_day": player_asked_day, "spent_week": spent_week,
		"spent": spent.duplicate(), "relief_week": relief_week, "relief_hist": relief_hist.duplicate(),
		"parcels": parcels.map(func(p: Dictionary) -> Dictionary: return {"id": p.id, "hh": p.hh, "at": (p.at as Array).duplicate(), "inv": (p.inv as Inventory).to_dict(),
			"day": p.day, "urgent": p.urgent, "why": p.why, "carrier": p.carrier, "held": p.held}),
		"next_parcel": next_parcel, "missed": missed.duplicate()}


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
	# CHAPEL-PURPOSE: optional (a save from before it has no food on its way and no missed meals it knows of)
	parcels = (d.get("parcels", []) as Array).map(func(p) -> Dictionary: return {"id": int(p.id), "hh": int(p.hh), "at": [int(p.at[0]), int(p.at[1])],
		"inv": Inventory.from_dict(p.get("inv", {})), "day": int(p.day), "urgent": bool(p.urgent), "why": str(p.why), "carrier": int(p.carrier), "held": bool(p.held)})
	next_parcel = int(d.get("next_parcel", 1))
	missed = {}
	for k in d.get("missed", {}):
		missed[int(k)] = int(d.missed[k])
	if bool(d.get("present", true)):
		found(false)
	else:
		present = false
