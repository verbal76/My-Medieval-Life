class_name NPCBrain
extends RefCounted
## Decides what each NPC does next and carries out the actions. Every action uses the World's
## rules (atomic trades, finite deposits, recipes that consume inputs), the same ones the player
## uses. Plans are short lists of steps: go somewhere, work for some game minutes, do an action.

const WORK_START := 7.0
const WORK_END := 18.0
const SLEEP := 21.5
const WAKE := 6.0

# what each job buys, with the stock it stops buying at
const BUYS := {
	"smith": {"iron_ore": 30, "copper_ore": 20, "gold_ore": 10, "coal": 30, "plank": 10, "leather": 6},
	"carpenter": {"log": 30},
	"tanner": {"hide": 15},
	"cook": {"wheat": 60, "meat": 15, "log": 10},
	"tavernkeeper": {"pottage": 60, "roast_meat": 20, "ale": 20},
	"merchant_raw": {"iron_ore": 20, "copper_ore": 15, "coal": 20, "stone": 40, "log": 20, "plank": 20},
	"merchant_food": {"pottage": 20, "roast_meat": 10, "ale": 15, "wheat": 20, "meat": 10},
	"merchant_goods": {"pickaxe": 4, "axe": 4, "hammer": 2, "copper_sword": 3, "iron_sword": 3,
		"leather_armor": 2, "iron_armor": 2, "leather": 6, "hide": 6, "iron_bar": 6, "copper_bar": 6, "gold_bar": 4,
		# crafted gear that had no buyer (B7-003, owner 2026-10-18): the goods merchant takes a few,
		# like the other made goods, and the caravan carries the surplus away
		"copper_ring": 3, "gold_ring": 2, "amulet": 2, "leather_cap": 3, "iron_helmet": 2},
}
# items an NPC keeps for its own work and will not sell
const KEEPS := {"miner": ["pickaxe"], "laborer": ["pickaxe"], "woodcutter": ["axe"], "smith": ["hammer"],
	"guard": ["iron_sword", "leather_armor"], "bandit": ["copper_sword"]}
# who to sell each item to, in order of preference
const OUTLETS := {
	"iron_ore": ["smith", "merchant_raw"], "copper_ore": ["smith", "merchant_raw"], "gold_ore": ["smith", "merchant_goods"],
	"coal": ["smith", "merchant_raw"], "stone": ["merchant_raw"], "log": ["carpenter", "cook", "merchant_raw"],
	"plank": ["smith", "merchant_raw"], "wheat": ["cook", "merchant_food"], "meat": ["cook", "merchant_food"],
	"hide": ["tanner", "merchant_goods"], "leather": ["smith", "merchant_goods"],
	"pottage": ["tavernkeeper", "merchant_food"], "roast_meat": ["tavernkeeper", "merchant_food"], "ale": ["tavernkeeper", "merchant_food"],
	"pickaxe": ["merchant_goods"], "axe": ["merchant_goods"], "iron_sword": ["merchant_goods"], "copper_sword": ["merchant_goods"],
	"hammer": ["merchant_goods"], "iron_bar": ["merchant_goods"], "leather_armor": ["merchant_goods"],
}
const FOOD := ["roast_meat", "pottage", "wheat", "ale"]
const COOKED := ["roast_meat", "pottage", "ale"]
# the mine's raw output: finite, and the forge's and the builders' own input. The caravan sells it to
# the village (when the seams are worked out) but does not carry the village's away (B7-007)
const NOT_EXPORTED := ["iron_ore", "copper_ore", "gold_ore", "coal", "stone"]

var w: World
var noted := {}          # one-off notes already written
## Diagnostics only (tests/economy_sim.gd): when on, every missed meal is logged as
## [day, hour, job or role, why, coins of the richest in the household]. Never read by the game.
var track_misses := false
var miss_log: Array = []


func _init(world: World) -> void:
	w = world


# ---------------------------------------------------------------- plan helpers ---------------
func go(c: Vector2i, speed := 1.0) -> Dictionary:
	return {"k": "go", "to": c, "speed": speed}


func work(minutes: float, act := "", args := {}, anim := "work", face = null) -> Dictionary:
	var s := {"k": "work", "min": minutes, "anim": anim}
	if act != "":
		s.act = act
		s.args = args
	if face != null:
		s.face = face
	return s


func doit(act: String, args := {}) -> Dictionary:
	return {"k": "do", "act": act, "args": args}


func beside(c: Vector2i, from: Vector2i) -> Vector2i:
	var best := c
	var bd := 1e9
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
		var n: Vector2i = c + d
		if not w.map.is_solid(n):
			var dd := from.distance_to(n)
			if dd < bd:
				bd = dd
				best = n
	return best


func wander_cell(around: Vector2i, r: int) -> Vector2i:
	var here := w.place_of(Vector2(around))      # nobody strolls into someone else's house
	for i in 12:
		var c := around + Vector2i(w.rng.randi_range(-r, r), w.rng.randi_range(-r, r))
		if not w.map.is_solid(c) and w.place_of(Vector2(c)) == here:
			return c
	return around


func once(key: String, text: String) -> void:
	if not noted.has(key):
		noted[key] = true
		w.note(text)


# ---------------------------------------------------------------- deciding -------------------
func decide(n: NPC) -> void:
	var h := w.hour()
	if n.anim == "sleep":
		n.anim = "idle"                    # up from bed
	if n.role == "bandit":
		_bandit(n, h)
		return
	if n.hunger < float(GameData.b("eat_below")) and _plan_eat(n):
		return
	if n.job == "guard":
		_guard(n, h)
		return
	if h >= SLEEP or h < WAKE:
		_plan_sleep(n)
		return
	if n.role == "child":
		var spot := w.building_door(n.home) if w.rng.randf() < 0.6 else Vector2i(w.map.data.spawns.player[0], w.map.data.spawns.player[1])
		n.doing = "playing"
		n.plan = [go(wander_cell(spot, 6), 0.9), work(w.rng.randf_range(20, 60), "", {}, "idle")]
		return
	if n.role == "elder":
		var spot := w.building_door(n.home) if w.rng.randf() < 0.7 else w.station_use(w.stations_of("well")[0])
		n.doing = "taking the air"
		n.plan = [go(wander_cell(spot, 3), 0.6), work(w.rng.randf_range(40, 90), "", {}, "idle")]
		return
	# hired to carry building materials (or carrying for their own new house): the day's work
	if h >= WORK_START and h < WORK_END and w.construction.plan_helper(n):
		return
	# a job taken for the manor is carried on to the end (ManorWork)
	if h >= WORK_START and h < WORK_END and w.manor_work.plan(n):
		return
	if h >= WORK_START and h < WORK_END and n.job != "":
		if h < 12.0 and _day_labour(n):
			return
		if _plan_job(n):
			return
	_plan_evening(n, h)


func _plan_sleep(n: NPC) -> void:
	n.doing = "going home to sleep"
	var until := WAKE + 24.0 if w.hour() >= SLEEP else WAKE
	var mins := (until - w.hour()) * 60.0
	_plan_bed(n, maxf(mins, 10.0))


## Go home through the door to one's own bed (World.home_spot) and lie in it for `mins` game minutes.
## A home without a bed or pallet: the door step, standing.
func _plan_bed(n: NPC, mins: float) -> void:
	if w.home_spot(n, "bed").is_empty():
		n.plan = [go(w.building_door(n.home)), doit("enter"), work(mins, "leave", {}, "idle")]
		return
	n.plan = [go(w.home_cell(n, "bed")), doit("enter"), work(mins, "leave", {}, "sleep")]


## Stock the household's pantry: firewood when it has none, grain (or cooked food) when it holds fewer
## units than it has members. Done in the evening, and by a guard whenever the shops are open (B7-015:
## a guard's duty and bed left no evening, so a guard's household pantry stayed empty and the guard
## went hungry in the night while the village held weeks of food). True when a trip is planned.
func _plan_provision(n: NPC) -> bool:
	var hh: Dictionary = w.households[n.household]
	var dependants := _dependants(hh)
	var stocked := _stocked(hh)
	if n.coins >= 3 and (hh.pantry as Inventory).count("log") < 1:
		var seller := _seller_of("log", n)
		if seller:
			n.doing = "buying firewood"
			n.plan = [go(_workplace_cell(seller)), doit("buy_from", {"vendor": seller.id, "item": "log", "qty": 1, "pantry": true})]
			return true
	if n.coins >= 4 and stocked < dependants + 1:
		# grain to cook at home feeds a family for far less than meals bought at the tavern
		var grain := _grain_seller(n)
		if grain:
			n.doing = "buying grain for the household"
			n.plan = [go(_workplace_cell(grain) if grain.job != "farmer" else grain.cell()), doit("buy_from", {"vendor": grain.id, "item": "wheat", "qty": 2, "pantry": true})]
			return true
		var v := _vendor_with_food(n)
		if v:
			n.doing = "buying food for the household"
			n.plan = [go(_workplace_cell(v)), doit("buy_food", {"vendor": v.id, "pantry": true})]
			return true
	return false


func _dependants(hh: Dictionary) -> int:
	var dependants := 0
	for m in hh.members:
		var o := w.npc(m)
		if o and o.alive and o.role != "adult":
			dependants += 1
	return dependants


## Food units in the household pantry.
func _stocked(hh: Dictionary) -> int:
	var stocked := 0
	for f in FOOD:
		stocked += (hh.pantry as Inventory).count(f)
	return stocked


func _plan_evening(n: NPC, h: float) -> void:
	if _plan_provision(n):
		return
	var hh: Dictionary = w.households[n.household]
	var dependants := _dependants(hh)
	var stocked := _stocked(hh)
	# an evening at the tavern only when the household is provided for and there is coin to spare
	if h >= WORK_END and n.coins >= int(GameData.b("tavern_spare_coins")) and stocked >= dependants + 1 and w.rng.randf() < 0.35:
		var counter := w.station_use(w.stations_of("tavern_counter")[0])
		n.doing = "at the tavern"
		n.plan = [go(wander_cell(counter + Vector2i(-6, 4), 3)), work(w.rng.randf_range(30, 70), "drink", {}, "idle")]
		return
	n.doing = "resting"
	n.plan = [go(wander_cell(w.building_door(n.home), 4), 0.8), work(w.rng.randf_range(20, 50), "", {}, "idle")]


func _plan_eat(n: NPC) -> bool:
	for f in COOKED:
		if n.inv.has(f):
			n.doing = "eating"
			n.plan = [work(10, "eat", {"cooked_only": true}, "idle")]
			return true
	var hh: Dictionary = w.households[n.household] if n.household >= 0 else {}
	if not hh.is_empty():
		var home_food := n.inv.has("wheat")
		for f in FOOD:
			if hh.pantry.has(f):
				home_food = true
		if home_food:
			n.doing = "going home to eat"
			n.plan = [go(w.home_cell(n, "table")), work(15, "eat_home", {}, "idle")]
			return true
	elif n.inv.has("wheat"):
		n.doing = "eating"
		n.plan = [work(10, "eat", {}, "idle")]
		return true
	var payer := n
	if n.coins < 2 and n.household >= 0:
		payer = _richest_in_household(n)     # the family's tab at the tavern, for anyone without coin
	if payer != null and payer.coins >= 2:
		var v := _vendor_with_food(n)
		if v:
			n.doing = "buying a meal" if payer == n else "eating on the family's tab"
			n.plan = [go(_workplace_cell(v)), doit("buy_food", {"vendor": v.id, "pantry": false, "payer": payer.id}), work(10, "eat", {}, "idle")]
			return true
	if payer != null and payer.coins >= 3:
		for o: NPC in w.npcs:
			if o.alive and o != n and not w.asleep(o) and (o.job == "farmer" or buy_role(o) == "merchant_food") and o.inv.count("wheat") - reserve(o, "wheat") >= 2:
				n.doing = "buying grain for porridge"
				n.plan = [go(_workplace_cell(o) if o.job != "farmer" else o.cell()), doit("buy_from", {"vendor": o.id, "item": "wheat", "qty": 2, "payer": payer.id}),
						go(w.home_cell(n, "table")), work(15, "eat_home", {}, "idle")]
				return true
	w.stat("missed_meal_" + ("no_money" if payer == null or payer.coins < 2 else "no_food_for_sale"))
	if track_misses:
		miss_log.append([w.day(), snappedf(w.hour(), 0.1), n.job if n.job != "" else n.role, "no_money" if payer == null or payer.coins < 2 else "no_food_for_sale", payer.coins if payer else 0, n.household, n.coins, n.hunger, w.households[n.household].pantry.items.duplicate() if n.household >= 0 else {}, n.doing])
	once("hungry_%d_%d" % [n.id, w.day()], "%s %s is hungry and cannot get food." % [n.name, n.family])
	return false


# ---------------------------------------------------------------- jobs -----------------------
func _plan_job(n: NPC) -> bool:
	match n.job:
		"miner", "laborer":
			return _miner(n)
		"woodcutter":
			return _woodcutter(n)
		"carpenter":
			if n.inv.count("plank") >= 30:
				return _plan_sell(n, "plank") if _buyer_for(n, "plank") else _idle_at_work(n, "waiting for orders")
			return _crafter(n, ["saw_planks"])
		"smith":
			return _smith(n)
		"tanner":
			return _crafter(n, ["tan_leather"])
		"cook":
			return _cook(n)
		"farmer":
			return _farmer(n)
		"hunter":
			return _hunter(n)
		"tavernkeeper", "merchant", "reeve":
			n.doing = {"tavernkeeper": "serving at the tavern", "merchant": "minding the stall", "reeve": "keeping the manor"}[n.job]
			n.plan = [go(_workplace_cell(n)), work(60, "", {}, "idle")]
			return true
		"manor_hand":
			for f in w.fields:
				if w.field_workers(f).is_empty():
					n.job = "farmer"
					n.left_job = "manor_hand"
					n.job_since = w.day()
					n.workplace = f.id
					once("takes_field_%d" % n.id, "%s %s takes over the untended field %s." % [n.name, n.family, f.id])
					evaluate_household(n.household)
					return _farmer(n)
			# the manor's hands do its open work (unpaid by the job: they have a day's wage); with none,
			# they wait at the manor
			if w.manor_work.seek(n):
				return true
			n.doing = "waiting for the manor's work"
			n.plan = [go(wander_cell(w.building_door(_manor_id()), 5)), work(90, "", {}, "idle")]
			return true
		"sage":
			n.doing = "pondering lore"
			n.plan = [go(wander_cell(w.building_door("b_hut") if w.buildings.has("b_hut") else w.building_door(n.home), 3), 0.7), work(60, "", {}, "idle")]
			return true
	return false


## A death changes the household and the village's work: a pen whose keeper died passes to another
## farmer (the same household first), a stall falls vacant (the manor lets it again:
## Property.relet_stalls), and the household re-evaluates its living.
func on_death(n: NPC) -> void:
	_hand_over_pens(n)
	_give_up_stall(n)
	w.construction.on_death(n)
	w.manor_work.on_death(n)
	if n.household >= 0:
		evaluate_household(n.household)


## A pen whose keeper died or left farming passes to another farmer (the same household first).
func _hand_over_pens(n: NPC) -> void:
	for id in w.fauna.pens:
		var pen: Dictionary = w.fauna.pens[id]
		if w.tenant_of(pen) != World.npc_ref(n.id):
			continue
		var next: NPC = null
		for o: NPC in w.npcs:
			if o.alive and o != n and o.job == "farmer" and _keeper_pen(o).is_empty() and (next == null or (o.household == n.household and next.household != n.household)):
				next = o
		w.set_tenant(pen, World.npc_ref(next.id) if next else "")
		if next:
			w.note("%s %s takes over the %s pen from %s." % [next.name, next.family, pen.kind, n.name])


func _manor_id() -> String:
	for id in w.buildings:
		if w.buildings[id].type == "manor":
			return id
	return w.npc(w.reeve_id).home


## Who pays on the family tab: the member with the most coins who can buy, an elder as well as an
## adult (a household's cash feeds all of it, as the manor's relief assumes).
func _richest_in_household(n: NPC) -> NPC:
	var best: NPC = null
	for m in w.households[n.household].members:
		var o := w.npc(m)
		if o and o.alive and o.role in ["adult", "elder"] and (best == null or o.coins > best.coins):
			best = o
	return best


## A worker whose own trade has nothing to do asks the reeve for the manor's work, as the player can
## (agent decision under the owner's equal-rules directive, 2026-10-18); with none, they wait at work.
func _idle_at_work(n: NPC, why: String) -> bool:
	if n.role == "adult" and w.hour() < float(GameData.b("manor_jobs").get("latest_start", 15)) and w.manor_work.seek(n):
		return true
	n.doing = why
	n.plan = [go(_workplace_cell(n)), work(45, "", {}, "idle")]
	return true


func _miner(n: NPC) -> bool:
	if not n.inv.has("pickaxe"):
		for o in ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]:
			if n.inv.has(o) and _buyer_for(n, o) != null:
				return _plan_sell_all(n)
		return _get_tool(n, "pickaxe")
	var ores := _wanted_ores()
	if n.job == "laborer":
		var raw := _buyer_for(n, "stone")
		ores = ["stone"] if raw != null else ["coal"]
	var carried := 0
	for o in ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]:
		carried += n.inv.count(o)
	if carried >= int(GameData.b("carry_ore")):
		return _plan_sell_all(n)       # sells whatever has a buyer first
	ores = ores.filter(func(o: String) -> bool: return _buyer_for(n, o) != null)
	var d: Dictionary = w.nearest_deposit(n.cell(), ores) if not ores.is_empty() else {}
	if d.is_empty():
		# the wanted seams are worked out: mine only what someone will still buy
		var sellable := []
		for o in ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]:
			if _buyer_for(n, o) != null:
				sellable.append(o)
		if not sellable.is_empty():
			d = w.nearest_deposit(n.cell(), sellable)
	if d.is_empty():
		if carried > 0:
			return _plan_sell_all(n)
		if w.nearest_deposit(n.cell(), ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]).is_empty():
			# the mine is worked out: the manor takes on those who lose their living
			_change_job(n, "manor_hand", "the mine is worked out")
			return false
		return _idle_at_work(n, "waiting for ore buyers")
	var at := Vector2i(d.x, d.y)
	n.doing = "mining %s" % GameData.item_name(d.ore).to_lower()
	n.plan = [go(beside(at, n.cell())), work(float(GameData.b("mine_minutes")), "mine", {"x": d.x, "y": d.y}, "work", at)]
	return true


func _wanted_ores() -> Array:
	var smith := _first_with_job("smith")
	if smith == null:
		return ["iron_ore", "coal"]
	if smith.inv.count("coal") * 2 < smith.inv.count("iron_ore"):
		return ["coal"]
	if w.rng.randf() < 0.15:
		return ["copper_ore"]
	return ["iron_ore", "coal"]


func _woodcutter(n: NPC) -> bool:
	if not n.inv.has("axe"):
		# sell what was felled before the axe broke; the carpenters may be waiting for it
		if n.inv.has("log") and _buyer_for(n, "log") != null:
			return _plan_sell_all(n)
		return _get_tool(n, "axe")
	if n.inv.count("log") >= int(GameData.b("carry_logs")):
		return _plan_sell_all(n)
	var t := w.nearest_tree(n.cell(), 70.0)
	if t.is_empty():
		if n.inv.has("log"):
			return _plan_sell_all(n)
		n.doing = "waiting for trees to grow"
		n.plan = [work(60, "", {}, "idle")]
		return true
	t.claimed = n.id
	var at := Vector2i(t.x, t.y)
	n.doing = "felling a tree"
	n.plan = [go(beside(at, n.cell())), work(float(GameData.b("chop_minutes")), "chop", {"x": t.x, "y": t.y}, "work", at)]
	return true


func _crafter(n: NPC, recipes: Array) -> bool:
	for r in recipes:
		var rec: Dictionary = GameData.recipes[r]
		if n.inv.has_all(rec.in) and _do_recipe(n, r):        # reserves the station, or tries the next recipe
			n.doing = "working at the %s" % rec.station
			return true
	# nothing to work on: sell surplus, else wait at the bench for deliveries
	for id in n.inv.items:
		if not KEEPS.get(n.job, []).has(id) and _overstock(n, id):
			return _plan_sell(n, id)
	n.doing = "waiting for materials"
	n.plan = [go(_workplace_cell(n)), work(30, "", {}, "idle")]
	return true


func _smith(n: NPC) -> bool:
	var inv := n.inv
	if inv.has_all({"iron_ore": 2, "coal": 1}) and inv.count("iron_bar") < 12:
		return _do_recipe(n, "smelt_iron")
	if inv.has_all({"copper_ore": 2, "coal": 1}) and inv.count("copper_bar") < 6:
		return _do_recipe(n, "smelt_copper")
	# the goods merchant is the smith's wholesale buyer (B7-016): tools beyond the smith's own go to its stall
	for id in ["pickaxe", "axe", "iron_sword", "copper_sword"]:
		if inv.count(id) > 1 and _buyer_for(n, id) != null:
			return _plan_sell(n, id)
	# forge whatever is scarcest
	var wants := []
	for r in ["forge_pickaxe", "forge_axe", "forge_iron_sword", "forge_hammer", "forge_copper_sword", "forge_iron_armor"]:
		var out: String = GameData.recipes[r].out.keys()[0]
		var cap := 1 if out in ["hammer", "iron_armor"] else 3
		if inv.count(out) < cap and inv.has_all(GameData.recipes[r].in):
			wants.append([inv.count(out), r])
	wants.sort()
	if not wants.is_empty():
		return _do_recipe(n, wants[0][1])
	if inv.count("plank") < 2 and inv.count("iron_bar") >= 2 and n.coins >= 6:
		var c := _first_with_job("carpenter")
		if c and c.inv.has("plank"):
			n.doing = "fetching planks"
			n.plan = [go(_workplace_cell(c)), doit("buy_from", {"vendor": c.id, "item": "plank", "qty": 3})]
			return true
	for id in ["pickaxe", "axe", "iron_sword", "copper_sword"]:
		if inv.count(id) > 3:
			return _plan_sell(n, id)
	n.doing = "tending the forge, waiting for ore"
	n.plan = [go(_workplace_cell(n)), work(30, "", {}, "idle")]
	return true


func _cook(n: NPC) -> bool:
	var food := 0
	for f in COOKED:
		food += n.inv.count(f)
	if food >= 12:
		return _plan_sell(n, _most(n, COOKED))
	if n.inv.has_all({"meat": 1, "log": 1}) and n.inv.count("roast_meat") < 6:
		return _do_recipe(n, "roast_meat")
	if n.inv.has("wheat", 3) and n.inv.count("ale") < 4 and w.rng.randf() < 0.3:
		return _do_recipe(n, "brew_ale")
	if n.inv.has("wheat", 2):
		return _do_recipe(n, "cook_pottage")
	if food > 0:
		return _plan_sell(n, _most(n, COOKED))
	n.doing = "waiting for wheat"
	n.plan = [go(_workplace_cell(n)), work(30, "", {}, "idle")]
	return true


func _farmer(n: NPC) -> bool:
	if _keeper(n):
		return true
	var f := _field(n.workplace)
	if f.is_empty():
		return false
	if n.inv.count("wheat") - reserve(n, "wheat") >= 8 and _buyer_for(n, "wheat") != null:
		return _plan_sell(n, "wheat")
	var spot := Vector2i(int(f.x) + w.rng.randi_range(0, int(f.w) - 1), int(f.y) + int(f.h))
	# a field whose farmer hired the player to bring in the harvest is left to them (Quests)
	match "hired" if f.state == "ripe" and not w.quests.hired_on(f).is_empty() else f.state:
		"ripe":
			n.doing = "harvesting wheat"
			n.plan = [go(spot), work(90, "harvest", {"field": f.id}, "work")]
		"tilled":
			n.doing = "sowing"
			n.plan = [go(spot), work(45, "sow", {"field": f.id}, "work")]
		_:
			if n.inv.count("wheat") > reserve(n, "wheat") and _buyer_for(n, "wheat") != null:
				return _plan_sell(n, "wheat")
			# the crop grows by itself: the farmer keeps watch, without swinging a tool at nothing
			# (Build 8 report: villagers swinging tools with no visible work)
			n.doing = "watching the crop grow"
			n.plan = [go(spot), work(60, "", {}, "idle")]
	return true


## A farmer who keeps a pen feeds it from their wheat and slaughters what the pen cannot hold.
func _keeper_pen(n: NPC) -> Dictionary:
	for id in w.fauna.pens:
		if w.tenant_of(w.fauna.pens[id]) == World.npc_ref(n.id):
			return w.fauna.pens[id]
	return {}


## Stock an NPC holds back instead of selling: a keeper keeps four days of feed for the pen.
func reserve(n: NPC, id: String) -> int:
	if id != "wheat" or n.job != "farmer":
		return 0
	var pen := _keeper_pen(n)
	return 0 if pen.is_empty() else w.fauna.daily_need(pen) * (1 if w.famine() else 4)


func _keeper(n: NPC) -> bool:
	var pen := _keeper_pen(n)
	if pen.is_empty():
		return false
	if n.inv.has("meat") or n.inv.has("hide"):
		var buyer := _buyer_for(n, "meat" if n.inv.has("meat") else "hide")
		if buyer != null:
			return _plan_sell(n, "meat" if n.inv.has("meat") else "hide")
	var at := Vector2i(int(pen.feed_at[0]), int(pen.feed_at[1]))
	var need := w.fauna.daily_need(pen)
	if w.famine():
		# people come first: the herd is cut back to its breeding stock for meat, and only that
		# stock is fed grain
		var cut: Animal = w.fauna.surplus(pen, true)
		if cut != null and w.fauna.count(pen.id, pen.kind) > int(GameData.b("animals")[pen.kind].keep) + 1:
			once("famine_cull_%d_%d" % [n.id, w.day()], "Food is short: %s %s slaughters the %s down to the breeding stock." % [n.name, n.family, GameData.b("animals")[pen.kind].name.to_lower()])
			n.doing = "slaughtering a %s for the hungry" % pen.kind
			n.plan = [go(at), work(30, "slaughter", {"pen": pen.id, "animal": cut.id}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))]
			return true
	if int(pen.trough) < need * 2:
		var feed_step := work(15, "feed_pen", {"pen": pen.id}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))
		n.doing = "feeding the %s" % GameData.b("animals")[pen.kind].name.to_lower()
		if n.inv.has("wheat"):
			n.plan = [go(at), feed_step]
			return true
		# no grain in hand: the household's store first, then buy feed
		var pantry: Inventory = w.households[n.household].pantry
		if pantry.has("wheat"):
			n.plan = [go(w.home_cell(n, "chest")), doit("take_pantry", {"item": "wheat", "qty": need * 3}), go(at), feed_step]
			return true
		var qty := need * 3
		for o: NPC in w.npcs:
			if o.alive and o != n and not w.asleep(o) and (o.job == "farmer" or buy_role(o) == "merchant_food") \
					and o.inv.count("wheat") - reserve(o, "wheat") >= qty and n.coins >= w.sell_price(o, "wheat") * qty:
				n.plan = [go(_workplace_cell(o) if o.job != "farmer" else o.cell()), doit("buy_from", {"vendor": o.id, "item": "wheat", "qty": qty}), go(at), feed_step]
				return true
		# no feed to be had and not enough for tomorrow morning: cull beyond the breeding stock and
		# sell the meat for feed money
		var cull: Animal = w.fauna.surplus(pen, true) if int(pen.trough) < need else null
		if cull != null:
			once("cull_%d_%d" % [n.id, w.day()], "%s %s has no feed for the %s and culls one." % [n.name, n.family, GameData.b("animals")[pen.kind].name.to_lower()])
			n.doing = "culling a %s" % pen.kind
			n.plan = [go(at), work(30, "slaughter", {"pen": pen.id, "animal": cull.id}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))]
			return true
	var spare: Animal = w.fauna.surplus(pen)
	if spare != null:
		n.doing = "slaughtering a %s" % pen.kind
		n.plan = [go(at), work(30, "slaughter", {"pen": pen.id, "animal": spare.id}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))]
		return true
	return false


func _hunter(n: NPC) -> bool:
	if n.inv.count("meat") >= 4 or n.inv.count("hide") >= 2:
		return _plan_sell_all(n)
	var prey: Animal = w.fauna.nearest_game(n.pos)
	if prey == null:
		n.doing = "letting the game recover"
		n.plan = [go(wander_cell(w.building_door(n.home), 4)), work(120, "", {}, "idle")]
		return true
	w.fauna.claims[prey.id] = n.id
	n.doing = "hunting %s" % prey.label().to_lower()
	n.plan = [go(beside(prey.cell(), n.cell())), work(float(GameData.b("hunt_minutes")), "hunt", {"animal": prey.id}, "work", prey.cell())]
	return true


func _guard(n: NPC, h: float) -> void:
	var on_duty := (h >= WAKE and h < SLEEP) if n.workplace == "day" else (h >= SLEEP - 1.0 or h < WAKE + 1.0)
	var shops_open := h >= WORK_START and h < WORK_END
	if not on_duty:
		if shops_open and _plan_provision(n):
			return
		var mins := 120.0
		n.doing = "off duty"
		_plan_bed(n, mins)
		return
	var foe := _bandit_near(n.pos, 10.0)
	if foe:
		n.target = foe.id
		n.doing = "fighting %s" % foe.name
		return
	if shops_open and _plan_provision(n):          # on the rounds: a trip to the market for the household
		return
	var post: Vector2i = w.guard_posts[w.rng.randi() % w.guard_posts.size()]
	n.doing = "on patrol"
	n.plan = [go(post), doit("look_out")]


func _bandit(n: NPC, h: float) -> void:
	var night := h >= 21.0 or h < 4.5
	if night:
		var prey = _prey_for(n)
		if prey != null:
			n.target = prey.id if prey is NPC else -2
			n.doing = "stalking"
			return
	n.doing = "lurking at the camp"
	n.plan = [go(wander_cell(w.bandit_camp, 3)), work(w.rng.randf_range(30, 90), "poach", {}, "idle")]


func _prey_for(n: NPC):
	if w.player.alive and w.player.pos.distance_to(n.pos) < 18.0:
		return w.player
	var best = null
	var bd := 40.0
	for o: NPC in w.npcs:
		if not o.alive or w.place_of(o.pos) != "" or o.role == "bandit" or o.job == "guard" or o.coins < 3:
			continue
		if _guard_near(o.pos, 14.0):
			continue
		var d: float = o.pos.distance_to(Vector2(w.bandit_camp))
		if d < bd:
			bd = d
			best = o
	return best


# ---------------------------------------------------------------- trading helpers ------------
func _plan_sell_all(n: NPC) -> bool:
	var unsold := ""
	for id in n.inv.ids():
		if not KEEPS.get(n.job, []).has(id) and not FOOD.has(id) and OUTLETS.has(id):
			if _buyer_for(n, id) != null:
				return _plan_sell(n, id)
			unsold = id
	if unsold != "":
		return _plan_sell(n, unsold)       # reports that nobody buys it
	return false


func _plan_sell(n: NPC, id: String) -> bool:
	var buyer := _buyer_for(n, id)
	if buyer == null:
		once("no_buyer_%s_%d" % [id, n.id], "%s %s cannot find anyone to buy %s." % [n.name, n.family, GameData.item_name(id).to_lower()])
		n.doing = "holding unsold %s" % GameData.item_name(id).to_lower()
		n.plan = [work(30, "", {}, "idle")]
		return true
	n.doing = "taking %s to %s" % [GameData.item_name(id).to_lower(), buyer.name]
	n.plan = [go(_workplace_cell(buyer)), doit("sell_to", {"buyer": buyer.id, "item": id})]
	return true


func _buyer_for(n: NPC, id: String) -> NPC:
	for outlet in OUTLETS.get(id, []):
		for b in _with_buy_role(outlet):
			if b != n and b.alive and wants(b, id) > 0 and b.coins - w.buy_price(b, id) >= int(GameData.b("trader_cash_floor")):
				return b
	return null


func _with_buy_role(role: String) -> Array:
	var out := []
	for o: NPC in w.npcs:
		if o.alive and buy_role(o) == role:
			out.append(o)
	return out


func buy_role(o: NPC) -> String:
	if o.job == "merchant" and w.stalls.has(o.workplace):
		return "merchant_" + w.stalls[o.workplace].kind
	return o.job


## How many of `id` this NPC will still buy.
func wants(o: NPC, id: String) -> int:
	var caps: Dictionary = BUYS.get(buy_role(o), {})
	if not caps.has(id):
		return 0
	return maxi(0, int(caps[id]) - o.inv.count(id))


## What this NPC will sell to a customer.
func for_sale(o: NPC) -> Array:
	var out := []
	for id in o.inv.ids():
		if KEEPS.get(o.job, []).has(id):
			continue
		if o.role == "child" or o.role == "bandit":
			continue
		out.append(id)
	return out


func _overstock(n: NPC, id: String) -> bool:
	var caps: Dictionary = BUYS.get(buy_role(n), {})
	return n.inv.count(id) > int(caps.get(id, 6)) + 4


## A household cooks its grain over the hearth: the cook's pottage recipe (2 wheat -> 6 pottage),
## when the pantry has no cooked food left. Grain the eater carries goes into the pot too.
func _cook_at_home(n: NPC, pantry: Inventory) -> void:
	for f in COOKED:
		if pantry.has(f):
			return
	var rec: Dictionary = GameData.recipes["cook_pottage"]
	var need := int(rec.in.wheat)
	if pantry.count("wheat") < need and n.inv.has("wheat"):
		w.transfer(n.inv, pantry, "wheat", mini(need - pantry.count("wheat"), n.inv.count("wheat")))
	if pantry.count("wheat") >= need:
		pantry.remove("wheat", need)
		pantry.add("pottage", int(rec.out.pottage))
		w.stat("made_pottage", float(rec.out.pottage))
		w.stat("used_wheat", float(need))
		w.stat("home_cooked")


## The nearest farmer or food merchant with grain to spare.
func _grain_seller(n: NPC) -> NPC:
	var best: NPC = null
	var bd := 1e9
	for o: NPC in w.npcs:
		if not o.alive or o == n or w.asleep(o) or not (o.job == "farmer" or buy_role(o) == "merchant_food"):
			continue
		if o.inv.count("wheat") - reserve(o, "wheat") < 2:
			continue
		var d := n.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best


func _vendor_with_food(n: NPC) -> NPC:
	var best: NPC = null
	var bd := 1e9
	for o: NPC in w.npcs:
		if not o.alive or o == n or w.asleep(o):
			continue
		if o.job != "tavernkeeper" and buy_role(o) != "merchant_food":
			continue
		var has := false
		for f in COOKED:
			if o.inv.has(f):
				has = true
		if not has:
			continue
		var d := n.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best


## Who sells `id` to a household: the carpenters and the raw-goods merchants, and for firewood a
## woodcutter with logs in hand too (B7-016: a woodcutter whose buyers were out of coin could not sell
## what households needed and had the money to buy).
func _seller_of(id: String, buyer: NPC) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o != buyer and not w.asleep(o) and (o.job == "carpenter" or buy_role(o) == "merchant_raw") and o.inv.has(id):
			return o
	if id == "log":
		for o: NPC in w.npcs:
			if o.alive and o != buyer and not w.asleep(o) and o.job == "woodcutter" and o.inv.has(id):
				return o
	return null


func _get_tool(n: NPC, tool: String) -> bool:
	# the goods merchant retails tools (the smith's wholesale buyer, B7-016); the smith sells what the merchant lacks
	for role in ["merchant_goods", "smith"]:
		for o: NPC in w.npcs:
			if o.alive and ((o.job == "smith") if role == "smith" else (buy_role(o) == role)) and o.inv.has(tool) and not KEEPS.get(o.job, []).has(tool):
				if n.coins >= w.sell_price(o, tool):
					n.doing = "buying a new %s" % tool
					n.plan = [go(_workplace_cell(o)), doit("buy_from", {"vendor": o.id, "item": tool, "qty": 1})]
					return true
	once("no_tool_%d_%d" % [n.id, w.day()], "%s %s has no %s and cannot get one." % [n.name, n.family, tool])
	n.doing = "out of work: needs a %s" % tool
	n.plan = [go(wander_cell(w.building_door(n.home), 4)), work(90, "", {}, "idle")]
	return true


func _do_recipe(n: NPC, r: String) -> bool:
	var rec: Dictionary = GameData.recipes[r]
	var st := _station_for(n, rec.station)
	if st == "":
		w.stat("station_busy_" + str(rec.station))
		return false
	# the station is reserved for the walk there and the work, plus an hour's slack
	w.stations[st].users[n.id] = w.minutes + w.map.data.w + float(rec.minutes) + 60.0
	n.doing = "%s" % r.replace("_", " ")
	n.plan = [go(w.station_use(st)), work(float(rec.minutes), "craft", {"recipe": r, "station": st}, "work", _station_at(st))]
	return true


## A station of this kind with room for one more worker (a station holds `capacity` workers, 1 unless
## the village data says otherwise); "" if all are taken. Lapsed reservations and the dead are cleared.
## Only stations the villager may use count (a workshop is its holder's, and those given leave:
## World.npc_may_use), and the player working at one takes a place (World.reserve_for_player).
func _station_for(n: NPC, kind: String) -> String:
	for id in w.stations_of(kind):
		var st: Dictionary = w.stations[id]
		if not w.npc_may_use(n, st):
			continue
		var users: Dictionary = st.users
		for u in users.keys():
			var o := w.npc(int(u))
			if float(users[u]) < w.minutes or o == null or not o.alive:
				users.erase(u)
		var player_there := 1 if float(st.get("player_until", -1.0)) > w.minutes else 0
		if users.has(n.id) or users.size() + player_there < int(st.get("capacity", 1)):
			return id
	return ""


func release_station(n: NPC, st: String) -> void:
	if w.stations.has(st):
		w.stations[st].users.erase(n.id)


func _station_at(id: String) -> Vector2i:
	var s: Dictionary = w.stations[id]
	return Vector2i(int(s.at[0]), int(s.at[1]))


func _workplace_cell(o: NPC) -> Vector2i:
	if w.stations.has(o.workplace):
		return w.station_use(o.workplace)
	if w.stalls.has(o.workplace):
		var s: Dictionary = w.stalls[o.workplace]
		return Vector2i(int(s.use[0]), int(s.use[1]))
	if o.workplace == "manor":
		return w.building_door(o.home)
	return o.cell()


func _field(id: String) -> Dictionary:
	for f in w.fields:
		if f.id == id:
			return f
	return {}


func _first_with_job(job: String) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.job == job:
			return o
	return null


func _most(n: NPC, ids: Array) -> String:
	var best: String = ids[0]
	for id in ids:
		if n.inv.count(id) > n.inv.count(best):
			best = id
	return best


func _guard_near(p: Vector2, r: float) -> bool:
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard" and not w.asleep(o) and o.pos.distance_to(p) <= r:
			return true
	return false


func _bandit_near(p: Vector2, r: float) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit" and o.pos.distance_to(p) <= r:
			return o
	return null


# ---------------------------------------------------------------- actions --------------------
func act(n: NPC, what: String, a: Dictionary) -> bool:
	match what:
		"enter":
			n.doing = "asleep at home" if w.hour() >= SLEEP or w.hour() < WAKE else "at home"
			return true
		"leave":
			n.anim = "idle"
			return true
		"eat":
			for f in (COOKED if a.get("cooked_only", false) else FOOD):
				if n.inv.has(f):
					n.inv.remove(f)
					n.hunger = minf(100.0, n.hunger + float(GameData.item(f).food))
					w.stat("eaten_food", float(GameData.item(f).food))
					w.stat("eaten_" + f)
					return true
			return false
		"eat_home":
			var pantry: Inventory = w.households[n.household].pantry
			_cook_at_home(n, pantry)
			for f in FOOD:
				if pantry.has(f):
					pantry.remove(f)
					n.hunger = minf(100.0, n.hunger + float(GameData.item(f).food))
					w.stat("eaten_food", float(GameData.item(f).food))
					w.stat("eaten_" + f)
					return true
			return false
		"drink":
			var keeper := _first_with_job("tavernkeeper")
			if keeper and keeper.inv.has("ale"):
				if w.trade(n, keeper, "ale", 1, w.sell_price(keeper, "ale")):
					n.inv.remove("ale")
					n.hunger = minf(100.0, n.hunger + float(GameData.item("ale").food))
					w.stat("eaten_food", float(GameData.item("ale").food))
					w.stat("eaten_ale")
			return true
		"buy_food":
			var v := w.npc(int(a.vendor))
			if v == null or not v.alive:
				return false
			var payer := w.npc(int(a.get("payer", n.id)))
			if payer == null or not payer.alive:
				payer = n
			for f in COOKED:
				if v.inv.has(f) and w.trade(payer, v, f, 1, w.sell_price(v, f)):
					if payer != n:
						w.transfer(payer.inv, n.inv, f, 1)
					if a.pantry:
						w.transfer(n.inv, w.households[n.household].pantry, f, 1)
					return true
			return false
		"buy_from":
			var v := w.npc(int(a.vendor))
			if v == null or not v.alive:
				return false
			var buyer := w.npc(int(a.get("payer", n.id)))
			if buyer == null or not buyer.alive:
				buyer = n
			var qty := mini(int(a.qty), v.inv.count(a.item))
			while qty > 0 and not w.trade(buyer, v, a.item, qty, w.sell_price(v, a.item)):
				qty -= 1
			if qty > 0 and buyer != n:
				w.transfer(buyer.inv, n.inv, a.item, qty)
			if qty > 0 and a.get("pantry", false):
				w.transfer(n.inv, w.households[n.household].pantry, a.item, qty)
			return qty > 0
		"sell_to":
			var b := w.npc(int(a.buyer))
			if b == null or not b.alive:
				return false
			var qty := mini(n.inv.count(a.item) - reserve(n, a.item), wants(b, a.item))
			var sold := 0
			while qty > 0 and b.coins - w.buy_price(b, a.item) >= int(GameData.b("trader_cash_floor")):
				if w.trade(b, n, a.item, 1, w.buy_price(b, a.item)):
					sold += 1
					qty -= 1
				else:
					break
			return sold > 0
		"mine":
			var d := w.deposit_at(Vector2i(int(a.x), int(a.y)))
			var ore := w.mine_unit(d)
			if ore == "":
				return false
			n.inv.add(ore)
			w.stat("mined_" + ore)
			if n.inv.wear("pickaxe", 1):
				w.stat("broke_pickaxe")
				w.note("%s %s's pickaxe broke." % [n.name, n.family])
			return true
		"chop":
			var t := w.tree_at(Vector2i(int(a.x), int(a.y)))
			t.erase("claimed")
			var logs := w.fell(t, 0)
			if logs <= 0:
				return false
			n.inv.add("log", logs)
			w.stat("trees_felled")
			w.stat("felled_log", logs)
			if n.inv.wear("axe", 3):
				w.stat("broke_axe")
				w.note("%s %s's axe broke." % [n.name, n.family])
			return true
		"craft":
			var rec: Dictionary = GameData.recipes[a.recipe]
			release_station(n, a.get("station", ""))
			if not n.inv.remove_all(rec.in):
				return false
			for id in rec.out:
				n.inv.add(id, int(rec.out[id]))
				w.stat("made_" + id, float(rec.out[id]))
			for id in rec.in:
				w.stat("used_" + id, float(rec.in[id]))
			if rec.station == "anvil":
				if n.inv.wear("hammer", 2):
					w.stat("broke_hammer")
			return true
		"harvest":
			var f := _field(a.field)
			if f.is_empty() or f.state != "ripe" or not w.quests.hired_on(f).is_empty():
				return false                                       # (left to the player hired to cut it)
			n.inv.add("wheat", w.take_crop(f, 1 << 30))          # whatever is left on the field
			# the farm's livestock is fed from the farm's crop: feed goes to the pen of any keeper
			# who shares this field before anything is sold
			for pid in w.fauna.pens:
				var pen: Dictionary = w.fauna.pens[pid]
				var need := w.fauna.daily_need(pen)
				var days := 1 if w.famine() else 4
				var keeper := w.pen_keeper(pen)
				if keeper and keeper.workplace == f.id and int(pen.trough) < need * days and need > 0:
					n.plan.push_front(work(15, "feed_pen", {"pen": pen.id, "qty": need * days - int(pen.trough)}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1]))))
					n.plan.push_front(go(Vector2i(int(pen.feed_at[0]), int(pen.feed_at[1]))))
			var pantry: Inventory = w.households[n.household].pantry
			var keep := maxi(0, 10 - pantry.count("wheat"))
			w.transfer(n.inv, pantry, "wheat", mini(keep, n.inv.count("wheat")))
			w.set_field(f, "tilled")
			return true
		"sow":
			var f := _field(a.field)
			if f.is_empty() or f.state != "tilled":
				return false
			w.set_field(f, "growing")
			return true
		"hunt":
			var prey: Animal = w.fauna.by_id(int(a.animal))
			w.fauna.claims.erase(int(a.animal))
			if prey == null or prey.pos.distance_to(n.pos) > 3.0:
				return true            # it got away; the hunter picks another
			w.stat("hunted_" + prey.species)
			var bag: Inventory = w.fauna.kill(prey)
			for id in bag.ids():
				n.inv.add(id, bag.count(id))
			return true
		"mj_step", "mj_mine":
			return w.manor_work.act(n, what, a)
		"day_labour":
			var wage := int(GameData.b("day_labour_wage"))
			if w.treasury >= wage:
				w.treasury -= wage
				n.coins += wage
				n.earned += wage
				w.stat("gov_wages", wage)
				w.stat("gov_day_labour", wage)
			return true
		"take_pantry":
			var pantry: Inventory = w.households[n.household].pantry
			w.transfer(pantry, n.inv, a.item, mini(int(a.qty), pantry.count(a.item)))
			return true
		"feed_pen":
			var pen: Dictionary = w.fauna.pens[a.pen]
			w.fauna.feed(pen, n.inv, int(a.get("qty", maxi(1, w.fauna.daily_need(pen) * 3 - int(pen.trough)))))
			return true
		"slaughter":
			var beast: Animal = w.fauna.by_id(int(a.animal))
			if beast == null or beast.area != a.pen:
				return true
			once("slaughter_%d_%d" % [n.id, w.day()], "%s %s slaughtered a %s." % [n.name, n.family, beast.label()])
			w.stat("slaughtered_" + beast.species)
			var meat: Inventory = w.fauna.kill(beast)
			for id in meat.ids():
				n.inv.add(id, meat.count(id))
			return true
		"poach":
			if n.hunger < 60.0:
				n.hunger = 100.0
				if w.rng.randf() < 0.25:
					var game: Animal = w.fauna.nearest_game(Vector2(w.bandit_camp), 30.0)
					if game != null:
						w.stat("poached_" + game.species)
						var eaten: Inventory = w.fauna.kill(game)          # eaten at the camp
						for id in eaten.ids():
							w.stat("poached_lost_" + id, eaten.count(id))
			return true
		"look_out":
			var foe := _bandit_near(n.pos, 10.0)
			if foe:
				n.target = foe.id
			return true
		"helper_take", "helper_buy", "helper_deliver":
			return w.construction.act(n, what, a)
	return true


# ---------------------------------------------------------------- fighting -------------------
func fight(n: NPC, dt: float) -> void:
	var tpos: Vector2
	var tdead := false
	var tnpc: NPC = null
	if n.target == -2:
		tpos = w.player.pos
		tdead = not w.player.alive
	else:
		tnpc = w.npc(n.target)
		# gone, or into a building the fighter is not in (a door between them); a sleeper is still
		# a target (owner rule: sleeping is not immunity) and wakes when struck
		if tnpc == null or not tnpc.alive or (w.place_of(tnpc.pos) != "" and w.place_of(tnpc.pos) != w.place_of(n.pos)):
			tdead = true
		else:
			tpos = tnpc.pos
	if tdead or (n.role == "bandit" and n.hp < n.max_hp * 0.3):
		n.target = -1
		n.plan.clear()
		if n.role == "bandit":
			n.plan = [go(w.bandit_camp, 1.2)]
		return
	var d := tpos - n.pos
	if d.length() > 25.0 or (n.job == "guard" and tpos.distance_to(Vector2(w.bandit_camp)) < 12.0):
		n.target = -1
		n.plan.clear()
		return
	n.facing = d
	if d.length() > 1.1:
		n.anim = "walk"
		n.pos += d.normalized() * minf(d.length() - 0.9, float(GameData.b("walk_tiles_per_second")) * 1.3 * dt)
		if w.map.is_solid(n.cell()):
			n.pos -= d.normalized() * float(GameData.b("walk_tiles_per_second")) * 1.3 * dt
		return
	if n.attack_cd > 0.0:
		return
	n.attack_cd = 1.0
	n.anim = "sword"
	n.plan = []
	# a bandit robs ordinary villagers rather than killing them
	if n.role == "bandit" and tnpc != null and tnpc.job != "guard":
		var take := tnpc.coins / 2
		tnpc.coins -= take
		n.coins += take
		var stolen := ""
		for id in tnpc.inv.ids():
			if not KEEPS.get(tnpc.job, []).has(id):
				tnpc.inv.remove(id)
				n.inv.add(id)
				stolen = id
				break
		tnpc.remember("robbed by %s" % n.name)
		w.note("%s robbed %s %s of %d coins%s." % [n.name, tnpc.name, tnpc.family, take,
			(" and a " + GameData.item_name(stolen).to_lower()) if stolen != "" else ""])
		n.target = -1
		n.plan = [go(w.bandit_camp, 1.2)]
		return
	if n.target == -2:
		w.damage_player(n.damage, n.name)
	else:
		tnpc.hp -= maxf(0.5, n.damage - tnpc.armor * 0.5)
		w.wake_near(tnpc.pos, float(GameData.b("sleep_wake_radius")))    # the blow wakes them, and the noise others
		if tnpc.target == -1:
			tnpc.target = n.id
		if tnpc.hp <= 0.0:
			w.kill(tnpc, "slain by %s" % n.name)
			n.target = -1


# ---------------------------------------------------------------- village events -------------
## The manor's evening business (owner-approved B3 plan). The treasury is the manor's, not the
## reeve's purse, so it goes on if the reeve dies. Every coin and grain moves between named
## parties and is counted in the ledger (w.stats gov_*).
##  1. tax: per household, on its cash above what a household of its size needs to live and trade:
##     12% while the treasury holds under 10 days of its obligations (wages), 6% up to 30 days,
##     none above;
##  2. emergency relief comes before everything but wages (pay_guards): see 5;
##  3. repairs (planks, stone, logs, iron bars for fittings), bought from the village's sellers
##     with money beyond 3 days of wages;
##  4. the granary buys farmers' genuine surplus with money above the 10-day reserve, never in a
##     famine and never what a farm needs for its household or its animals;
##  5. relief: a household that can cover under 2 days of food (pantry plus what its cash buys)
##     gets food into its pantry up to 3 days: granary grain first, then grain or cooked food the
##     manor buys for it. A household under 1 day of food is helped even below the reserve, down
##     to one day of wages. A household that keeps needing relief is named in the log.
func reeve_day() -> void:
	update_market()
	var obligations := daily_obligations()
	var reserve := obligations * float(GameData.b("treasury_reserve_days"))
	var taxed := 0
	if w.treasury < obligations * float(GameData.b("treasury_tax_holiday_days")):
		var rate := float(GameData.b("tax_rate_low_treasury")) if w.treasury < reserve else float(GameData.b("tax_rate_normal"))
		for h in w.households.size():
			var members := _members(h)
			if members.is_empty():
				continue
			var cash := 0
			for o: NPC in members:
				cash += o.coins
			var exempt := int(GameData.b("tax_exemption_base")) + int(GameData.b("tax_exemption_per_member")) * members.size()
			var t := int(maxi(0, cash - exempt) * rate)
			members.sort_custom(func(x: NPC, y: NPC) -> bool: return x.coins > y.coins or (x.coins == y.coins and x.id < y.id))
			for o: NPC in members:
				if t <= 0:
					break
				var take := mini(t, o.coins)
				o.coins -= take
				w.treasury += take
				taxed += take
				t -= take
				w.stat("gov_tax", take)
	# relief first (it is bought before anything optional), then repairs and the granary
	var relief := _relief(obligations, reserve)
	var budget := int(maxf(0.0, w.treasury - 3.0 * obligations) * float(GameData.b("repairs_budget_share")))
	var bought := 0
	# stone for the works from the village's own seams, when the yard lacks it (a job for the reeve's list)
	if budget > 0:
		w.manor_work.post_quarry()
	var quarrying: bool = w.manor_work.jobs.any(func(j): return j.kind == "quarry")
	for id in ["plank", "stone", "log", "iron_bar"]:          # iron bars: fittings and nails, from the smiths
		if id == "stone" and quarrying:
			continue                          # the manor's own stone is being quarried
		for o: NPC in w.npcs:
			if not o.alive or not (o.job in ["carpenter", "laborer", "smith"] or buy_role(o) == "merchant_raw"):
				continue
			while o.inv.count(id) > 6 + w.construction.open_need(id) and budget > 0 and bought < 40 and w.manor_work.works_want():
				var price := w.buy_price(o, id)
				if price > budget:
					break
				# paid now; it waits at the seller's, the manor's, to be carried to the works yard and used
				# in mending (ManorWork: used_repairs_ when used)
				w.manor_work.consign(o.inv, _workplace_cell(o), id, 1, {"kind": "yard"}, "repairs", _seller_words(o))
				o.coins += price
				o.earned += price
				w.treasury -= price
				budget -= price
				bought += 1
				w.stat("gov_repairs", price)
	var works := _public_works(obligations)
	var grain := 0
	var target := int(village_day_food() * float(GameData.b("granary_target_days")) / 120.0)
	if not w.famine() and w.food_days >= float(GameData.b("relief_fill_days")):
		for o: NPC in w.npcs:
			if not o.alive or not (o.job == "farmer" or buy_role(o) == "merchant_food"):
				continue
			while w.granary.count("wheat") + w.manor_work.bound("granary", "wheat") < target and surplus_wheat(o) > 0:
				var price := w.buy_price(o, "wheat")
				if w.treasury - price < reserve:
					break
				# bought now; it waits at the farmer's, the manor's, to be carried to the granary
				w.manor_work.consign(o.inv, _workplace_cell(o), "wheat", 1, {"kind": "granary"}, "granary", _seller_words(o))
				o.coins += price
				o.earned += price
				w.treasury -= price
				grain += 1
				w.stat("gov_procurement", price)
				w.stat("gov_granary_in", 1)
	if taxed + bought + grain + relief > 0:
		w.note("The manor took %d coins in tax, bought %d loads for repairs and %d grain for the granary, and gave %d households food." % [taxed, bought, grain, relief])
	if works > 0:
		w.note("The manor bought %d loads of planks, iron and stone for its public works." % works)
	w.manor_work.refresh()


## Public works: money the treasury holds beyond its tax-holiday level (30 days of wages) is not
## left idle. A share of the excess is spent each day on planks from the carpenters, iron bars from
## the smiths and stone, used up in building and mending (bridges, the mill race, walls). Only
## while there is a reeve to commission them: without one the money lies idle. Returns loads used.
func _public_works(obligations: float) -> int:
	var reeve := w.npc(w.reeve_id)
	if reeve == null or not reeve.alive:
		return 0
	var excess := w.treasury - obligations * float(GameData.b("treasury_tax_holiday_days"))
	var budget := int(maxf(0.0, excess) * float(GameData.b("public_works_share")))
	var keep: Dictionary = GameData.b("public_works_seller_keeps")
	var used := 0
	for id in ["plank", "iron_bar", "stone"]:
		for o: NPC in w.npcs:
			if not o.alive or not o.job in ["carpenter", "smith", "merchant", "laborer"] or w.asleep(o):
				continue
			# what open building sites still need stays on sale for their builders (audit: public
			# works would starve builders)
			while o.inv.count(id) > int(keep.get(id, 6)) + w.construction.open_need(id) and budget > 0 and used < int(GameData.b("public_works_max_loads")) and w.manor_work.works_want():
				var price := w.buy_price(o, id)
				if price > budget:
					break
				# to the works yard, to be used in mending (ManorWork)
				w.manor_work.consign(o.inv, _workplace_cell(o), id, 1, {"kind": "yard"}, "works", _seller_words(o))
				o.coins += price
				o.earned += price
				w.treasury -= price
				budget -= price
				used += 1
				w.stat("gov_public_works", price)
	return used


## Food relief into household pantries. Returns how many households were helped.
func _relief(obligations: float, reserve: float) -> int:
	var helped := 0
	for h in w.households.size():
		var members := _members(h)
		if members.is_empty():
			continue
		var days := household_food_days(h)
		if days >= float(GameData.b("relief_trigger_days")):
			continue
		# relief already on its way is awaited; under a day of food it is brought at once
		if w.manor_work.pending_for(h) > 0:
			if days < 1.0:
				w.manor_work.deliver_now(h)
				helped += 1
				_note_relief(h)
			continue
		# relief is carried to the household (a job), unless it has under a day of food: then at once
		var urgent := days < 1.0
		var pantry: Inventory = w.households[h].pantry
		var need := (float(GameData.b("relief_fill_days")) - days) * household_day_food(h)
		var wheat := mini(ceili(need / 120.0), w.granary.count("wheat"))
		if urgent and wheat < ceili(need / 120.0):
			# the manor's grain still at the farmers' for the granary goes straight to them
			var sent := w.manor_work.take_bound("granary", "wheat", ceili(need / 120.0) - wheat, pantry)
			need -= sent * 120.0
			w.stat("gov_relief_grain", sent)
		if wheat > 0:
			if urgent:
				w.transfer(w.granary, pantry, "wheat", wheat)
			else:
				w.manor_work.consign(w.granary, w.manor_work.yard_cell(), "wheat", wheat, {"kind": "pantry", "hh": h}, "relief", "the manor's granary")
			need -= wheat * 120.0
			w.stat("gov_relief_grain", wheat)
		# what the granary cannot give, the manor buys for the household: an emergency (under a day of
		# food) may spend down to one day of wages, otherwise only money above the reserve
		var floor_coins := obligations if days < 1.0 else reserve
		while need > 0.0:
			var seller := _relief_seller()
			if seller == null:
				break
			var item := "wheat" if seller.inv.has("wheat") and surplus_wheat(seller) > 0 else "pottage"
			var price := w.sell_price(seller, item)
			if w.treasury - price < floor_coins or not seller.inv.has(item):
				break
			if urgent:
				seller.inv.remove(item)
				pantry.add(item)
			else:
				w.manor_work.consign(seller.inv, _workplace_cell(seller), item, 1, {"kind": "pantry", "hh": h}, "relief", _seller_words(seller))
			seller.coins += price
			seller.earned += price
			w.treasury -= price
			need -= 120.0 if item == "wheat" else 40.0
			w.stat("gov_relief_bought", price)
			w.stat("gov_relief_bought_" + item, 1)
		if need < (float(GameData.b("relief_fill_days")) - days) * household_day_food(h):
			helped += 1
			_note_relief(h)
	return helped


## Where a seller's goods wait for the manor's carriers, in words: "Clement Ward the smith's".
func _seller_words(o: NPC) -> String:
	return "%s %s the %s's" % [o.name, o.family, o.job if o.job != "merchant" else "merchant"]


## Grain from a farmer's surplus first, then cooked food from a food seller.
func _relief_seller() -> NPC:
	for o: NPC in w.npcs:
		if o.alive and (o.job == "farmer" or buy_role(o) == "merchant_food") and surplus_wheat(o) > 0:
			return o
	for o: NPC in w.npcs:
		if o.alive and (o.job == "tavernkeeper" or buy_role(o) == "merchant_food") and o.inv.has("pottage"):
			return o
	return null


## A household that keeps needing relief is named, once a week: relief is not meant to hide a living
## that does not pay.
func _note_relief(h: int) -> void:
	var hh: Dictionary = w.households[h]
	var days: Array = hh.get("relief_days", [])
	days.append(w.day())
	days = days.filter(func(d) -> bool: return int(d) > w.day() - 7)
	hh.relief_days = days
	if days.size() >= int(GameData.b("chronic_relief_days")):
		once("chronic_%d_%d" % [h, w.day() / 7], "The %s household has needed the manor's food on %d of the last 7 days: its work does not keep it fed." % [hh.family, days.size()])
		w.stat("gov_chronic_relief_households")


## Wheat a farmer or food merchant can spare without short-changing anyone: a farmer keeps food for
## the household (3 days), the livestock feed reserve and a buffer; a merchant keeps half its stock
## for the market.
func surplus_wheat(o: NPC) -> int:
	return maxi(0, o.inv.count("wheat") - keep_wheat(o))


func keep_wheat(o: NPC) -> int:
	var keep := int(GameData.b("granary_keep_buffer"))
	if o.job == "farmer":
		keep += reserve(o, "wheat") + ceili(household_day_food(o.household) * float(GameData.b("granary_keep_household_days")) / 120.0)
	else:
		keep += int(BUYS.get(buy_role(o), {}).get("wheat", 0)) / 2
	return keep


func _day_food() -> float:
	return 24.0 * float(GameData.b("hunger_per_hour"))


## How much a villager eats compared with an adult. The owner's living-world design counts a
## household's food per member, adjusted for age-dependent consumption. Villagers have no ages yet,
## so the role decides: a child gets hungry `child_food_factor` as fast (World._update_npc) and so
## eats that share of an adult's food. Every food reckoning weights members by this.
static func food_factor(o: NPC) -> float:
	return float(GameData.b("child_food_factor")) if o.role == "child" else 1.0


## Food points a group of villagers eats in a day, each weighted by food_factor.
static func people_day_food(people: Array) -> float:
	var t := 0.0
	for o: NPC in people:
		t += food_factor(o)
	return t * 24.0 * float(GameData.b("hunger_per_hour"))


## A household's daily food need (points): its living members, weighted by age.
func household_day_food(h: int) -> float:
	return people_day_food(_members(h))


## The village's daily food need (points): every living villager (not the bandits), weighted by age.
func village_day_food() -> float:
	return people_day_food(w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role != "bandit"))


func daily_obligations() -> float:
	var n := 4.0 + float(GameData.b("reeve_wage_per_day"))
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard":
			n += float(GameData.b("guard_wage_per_day"))
		elif o.alive and o.job == "manor_hand":
			n += float(GameData.b("manor_wage_per_day"))
	return n


func _members(h: int) -> Array:
	var out := []
	if h < 0:
		return out
	for m in w.households[h].members:
		var o := w.npc(m)
		if o and o.alive:
			out.append(o)
	return out


## Days of food a household can cover from its pantry (grain counted as cooked at home) and what
## its cash can buy (about 60 food points a coin), but only up to the household's share of the
## food actually for sale: coins buy nothing when the market is empty. Days are counted against the
## household's own need, members weighted by age (a child eats less), and its share of the market
## is its share of the village's need.
func household_food_days(h: int) -> float:
	var p: Inventory = w.households[h].pantry
	var pts := p.count("pottage") * 40.0 + p.count("roast_meat") * 60.0 + p.count("ale") * 10.0 + p.count("wheat") * 120.0
	var members := _members(h)
	var cash := 0
	for o: NPC in members:
		cash += o.coins
	var need := household_day_food(h)
	var share := market_food_points * need / maxf(1.0, village_day_food())
	pts += minf(cash * 60.0, share)
	return pts / maxf(1.0, need)


## Food for sale in the village: cooked food at the tavern and food stalls, and the grain farmers and
## merchants can spare. Updated each morning and before the evening's relief.
var market_food_points := 0.0


var market_wheat_price := 3


func update_market() -> void:
	var pts := 0.0
	market_wheat_price = int(GameData.value("wheat"))
	var cheapest := 0
	for o: NPC in w.npcs:
		if not o.alive:
			continue
		if o.job == "tavernkeeper" or buy_role(o) == "merchant_food":
			pts += o.inv.count("pottage") * 40.0 + o.inv.count("roast_meat") * 60.0 + o.inv.count("ale") * 10.0
		if o.job == "farmer" or buy_role(o) == "merchant_food":
			pts += surplus_wheat(o) * 120.0
			if o.inv.count("wheat") >= 2:
				var p := w.sell_price(o, "wheat")
				if cheapest == 0 or p < cheapest:
					cheapest = p
	market_food_points = pts
	if cheapest > 0:
		market_wheat_price = cheapest


## Wages from the treasury: the sage, the reeve, the guards and the manor's hands.
func pay_guards() -> void:
	var sage := w.npc(w.sage_id)
	if sage and sage.alive and w.treasury >= 4:
		w.treasury -= 4
		sage.coins += 4
		sage.earned += 4
		w.stat("gov_wages", 4)
	var rv := w.npc(w.reeve_id)
	var rw := int(GameData.b("reeve_wage_per_day"))
	if rv and rv.alive and w.treasury >= rw:
		w.treasury -= rw
		rv.coins += rw
		rv.earned += rw
		w.stat("gov_wages", rw)
	var wage := int(GameData.b("guard_wage_per_day"))
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard":
			if w.treasury >= wage:
				w.treasury -= wage
				o.coins += wage
				o.earned += wage
				w.stat("gov_wages", wage)
			else:
				once("unpaid_%d" % w.day(), "The manor cannot pay the guards today.")
	var hand_wage := int(GameData.b("manor_wage_per_day"))
	if w.treasury < 2.0 * daily_obligations():
		# the manor cannot keep everyone on: the most recently hired hand is let go
		var last: NPC = null
		for o: NPC in w.npcs:
			if o.alive and o.job == "manor_hand" and (last == null or o.job_since > last.job_since or (o.job_since == last.job_since and o.id > last.id)):
				last = o
		if last:
			_change_job(last, "", "the manor can no longer pay its hands")
	for o: NPC in w.npcs:
		# a hand hired out for the day to carry building materials was paid by the employer
		if o.alive and o.job == "manor_hand" and w.construction.contract_of(o).is_empty():
			if w.treasury >= hand_wage:
				w.treasury -= hand_wage
				o.coins += hand_wage
				o.earned += hand_wage
				w.stat("gov_wages", hand_wage)
			else:
				once("unpaid_hands_%d" % w.day(), "The manor cannot pay its hands today.")


# ---------------------------------------------------------------- households and work ------
## A household's economic position, recomputed every morning and right after an event that changes
## it (a death, a job change; marriage, births and adoption will call it too). Stored in hh.econ:
## members, adults, dependants, daily food need (points) and cost (food at today's grain price plus
## firewood), income (members' average daily earnings over 5 days), balance, days of food in hand
## (pantry plus what its cash can buy), its runway (days its cash and sellable trade stock would last),
## whether it is sustainable (income covers costs, or it holds 10 days of food or runway), and for how
## many mornings in a row it has not been.
func evaluate_household(h: int, daily := false) -> Dictionary:
	var hh: Dictionary = w.households[h]
	var members := _members(h)
	if members.is_empty():
		hh.econ = {}
		return hh.econ
	var adults := 0
	var income := 0.0
	for o: NPC in members:
		if o.role == "adult":
			adults += 1
		income += o.avg_income(5)
	var need := household_day_food(h)
	var cost := need / 120.0 * market_wheat_price + float(GameData.value("log"))
	var days := household_food_days(h)
	# what the household could live on: cash, plus the trade stock its members could sell (a smith's
	# iron, a merchant's goods) at what buyers pay, counted only while someone is buying it
	var assets := 0.0
	for o: NPC in members:
		assets += o.coins
		for id in o.inv.ids():
			if not NPCBrain.FOOD.has(id) and not KEEPS.get(o.job, []).has(id) and _buyer_for(o, id) != null:
				assets += mini(o.inv.count(id), wants(_buyer_for(o, id), id)) * GameData.value(id) * float(GameData.b("sell_ratio"))
	var runway := assets / maxf(0.1, cost)
	var savings := float(GameData.b("household_savings_days"))
	var sustainable := income >= cost or days >= savings or runway >= savings
	var streak := int(hh.get("unsustainable_days", 0))
	if daily:
		streak = 0 if sustainable else streak + 1
		hh.unsustainable_days = streak
	hh.econ = {"members": members.size(), "adults": adults, "dependants": members.size() - adults, "need": need,
		"cost": cost, "income": income, "balance": income - cost, "days": days, "runway": runway, "sustainable": sustainable, "streak": streak}
	return hh.econ


## The jobs open to a villager who needs better work, built from the village's existing jobs: what
## those doing them have actually earned lately, and how many more the work can take. Skilled trades
## (smith, carpenter, tanner, cook, tavern, merchant) need training the game does not have, and
## government posts are appointed, so neither is open here.
func job_market() -> Dictionary:
	var earn := {}
	var heads := {}
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.income_days.size() >= 3:
			earn[o.job] = float(earn.get(o.job, 0.0)) + o.avg_income(5)
			heads[o.job] = int(heads.get(o.job, 0)) + 1
	var count := func(job: String) -> int:
		var c := 0
		for o: NPC in w.npcs:
			if o.alive and o.job == job:
				c += 1
		return c
	var avg := func(job: String, fallback: float) -> float:
		return float(earn[job]) / int(heads[job]) if heads.has(job) else fallback
	var market := {}
	var wage := float(GameData.b("manor_wage_per_day"))
	var reserve := daily_obligations() * float(GameData.b("treasury_reserve_days"))
	market["manor_hand"] = {"pay": wage, "open": maxi(0, int((w.treasury - reserve) / (wage * float(GameData.b("manor_hire_runway_days"))))),
		"tool": "", "at": w.building_door(_manor_id())}
	var field_open := 0
	for f in w.fields:
		field_open += maxi(0, int(GameData.b("field_workers_max")) - _field_workers(f))
	market["farmer"] = {"pay": avg.call("farmer", 0.0), "open": field_open, "tool": "", "at": Vector2i(int(w.fields[0].x), int(w.fields[0].y))}
	var trees := 0
	for t in w.trees:
		if t.state == "grown":
			trees += 1
	market["woodcutter"] = {"pay": avg.call("woodcutter", 0.0), "open": maxi(0, trees / int(GameData.b("trees_per_woodcutter")) - count.call("woodcutter")),
		"tool": "axe", "at": Vector2i(15, 15)}
	var game := 0
	for a: Animal in w.fauna.animals:
		if a.wild() and a.adult(w.minutes):
			game += 1
	market["hunter"] = {"pay": avg.call("hunter", 0.0), "open": maxi(0, game / int(GameData.b("game_per_hunter")) - count.call("hunter")),
		"tool": "", "at": Vector2i(15, 15)}
	var ore := 0
	for dp in w.deposits:
		ore += int(dp.amount)
	market["miner"] = {"pay": avg.call("miner", 0.0), "open": maxi(0, ore / int(GameData.b("ore_per_miner")) - count.call("miner") - count.call("laborer")),
		"tool": "pickaxe", "at": Vector2i(w.map.data.mine.yard[0], w.map.data.mine.yard[1])}
	return market


func _field_workers(f: Dictionary) -> int:
	return w.field_workers(f).size()


## Every morning: the unemployed, and adults whose household has not been able to live on its income
## for several mornings and who earn less than their share of its costs, look for better work. They
## weigh what each open job actually pays against the cost of a tool and the walk from home, and only
## move for a clear gain. A taken opening is gone for the next villager. Deterministic: households in
## order, members by id.
func seek_work() -> void:
	var market := job_market()
	var cooldown := int(GameData.b("job_switch_cooldown_days"))
	for h in w.households.size():
		var econ: Dictionary = w.households[h].get("econ", {})
		if econ.is_empty():
			continue
		var members := _members(h)
		members.sort_custom(func(x: NPC, y: NPC) -> bool: return x.id < y.id)
		for n: NPC in members:
			if n.role != "adult" or n.job in ["guard", "reeve", "sage"]:
				continue
			var unemployed := n.job == ""
			var share := float(econ.cost) / maxi(1, int(econ.adults))
			if not unemployed:
				var settling := n.left_job != "" and w.day() - n.job_since < cooldown     # just changed jobs: give it time
				if int(econ.streak) < int(GameData.b("mobility_unsustainable_days")) or settling:
					continue
				if n.income_days.size() < 5 or n.avg_income(5) >= share:
					continue
			var current := 0.0 if unemployed else n.avg_income(5)
			var best := ""
			var best_score := -1e9
			var home := w.building_door(n.home)
			for job in ["manor_hand", "farmer", "woodcutter", "hunter", "miner"]:
				var opt: Dictionary = market[job]
				if int(opt.open) <= 0 or job == n.job:
					continue
				if job == n.left_job and w.day() - n.job_since < int(GameData.b("job_return_days")):
					continue
				var setup := 0.0
				if opt.tool != "" and not n.inv.has(opt.tool):
					var seller := _seller_of(opt.tool, n)
					if seller == null or n.coins < w.sell_price(seller, opt.tool):
						continue
					setup = w.sell_price(seller, opt.tool) / 10.0
				var score: float = float(opt.pay) - setup - Vector2(home).distance_to(Vector2(opt.at)) / 60.0
				if score > best_score:
					best_score = score
					best = job
			if best == "":
				if unemployed:
					once("no_work_%d_%d" % [n.id, w.day()], "%s %s looks for work and finds none." % [n.name, n.family])
				continue
			if not unemployed and best_score < maxf(current * float(GameData.b("job_switch_margin")), current + float(GameData.b("job_switch_min_gain"))):
				continue
			market[best].open = int(market[best].open) - 1
			var why := "out of work" if unemployed else "%s did not keep the household fed" % (n.job.replace("_", " ") + " work")
			_change_job(n, best, why)


## A merchant's stall falls vacant when they die or change work.
func _give_up_stall(n: NPC) -> void:
	if w.stalls.has(n.workplace) and w.tenant_of(w.stalls[n.workplace]) == World.npc_ref(n.id):
		w.set_tenant(w.stalls[n.workplace], "")


## Take up a job (or lose one: job ""). The old workplace is given up: a stall falls vacant, a pen
## passes to another farmer, a field is left (its workers are those whose workplace it is). The
## household re-evaluates at once. `place`: the stall a new merchant is let (Property.relet_stalls).
func _change_job(n: NPC, job: String, why: String, place := "") -> void:
	var old := n.job
	_give_up_stall(n)
	if old == "farmer" and not _keeper_pen(n).is_empty():
		_hand_over_pens(n)
	n.left_job = old
	n.job = job
	n.job_since = w.day()
	n.plan.clear()
	match job:
		"manor_hand":
			n.workplace = "manor"
		"farmer":
			var pick: Dictionary = {}
			for f in w.fields:
				if _field_workers(f) < int(GameData.b("field_workers_max")) and (pick.is_empty() or _field_workers(f) < _field_workers(pick)):
					pick = f
			n.workplace = pick.id if not pick.is_empty() else ""
		"woodcutter", "hunter":
			n.workplace = "forest"
		"miner":
			n.workplace = "mine"
		"merchant":
			n.workplace = place
			w.set_tenant(w.stalls[place], World.npc_ref(n.id))
		_:
			n.workplace = ""
	if job == "":
		w.note("%s %s loses the work as %s: %s." % [n.name, n.family, old.replace("_", " "), why])
	elif old == "":
		w.note("%s %s takes work as a %s (%s)." % [n.name, n.family, job.replace("_", " "), why])
	else:
		w.note("%s %s leaves work as a %s to be a %s: %s." % [n.name, n.family, old.replace("_", " "), job.replace("_", " "), why])
	w.stat("job_changes")
	if n.household >= 0:
		evaluate_household(n.household)


## Day labour at the manor: an adult of a household short of food who has earned nothing today may
## work a day for a wage while the treasury is above its reserve. Food producers stay at their work.
var earned_at_dawn := {}
var laboured_today := {}


func dawn(record := true) -> void:
	update_market()
	if record:
		for o: NPC in w.npcs:
			if o.alive and earned_at_dawn.has(o.id):
				o.income_days.append(o.earned - int(earned_at_dawn[o.id]))
				if o.income_days.size() > 7:
					o.income_days.pop_front()
	earned_at_dawn.clear()
	laboured_today.clear()
	for o: NPC in w.npcs:
		earned_at_dawn[o.id] = o.earned
	if record:
		for h in w.households.size():
			evaluate_household(h, true)
		seek_work()
		w.quests.drop_failed()
		w.quests.refresh()


func _day_labour(n: NPC) -> bool:
	if n.role != "adult" or n.job in ["guard", "reeve", "manor_hand", "sage", "", "farmer", "cook", "hunter", "tavernkeeper"] or laboured_today.has(n.id):
		return false
	if n.earned != int(earned_at_dawn.get(n.id, n.earned)) or household_food_days(n.household) >= float(GameData.b("relief_trigger_days")):
		return false
	# a real job from the manor's work, or none (owner, 2026-10-18: no pay for standing about, no
	# work guaranteed); paid when it is done (ManorWork)
	if not w.manor_work.seek(n):
		return false
	laboured_today[n.id] = true
	return true


## A merchant caravan passes through. It is a finite regional market (B7-014, agent decision under the
## owner's authorization of 2026-10-18; every number provisional): it holds a purse (World.caravan_purse),
## which gains the regional demand for the village's goods (`caravan_allowance` coins a day, up to
## `caravan_float`, tapering to nothing as the village's coins reach `caravan_ceiling_per_head` a head)
## and every coin the village pays it for ore, coal and stone; it spends from it, at
## most `caravan_coins` a visit, and never pays out a coin it does not hold. It sells first, then buys
## the market's surplus (never the mine's raw ore, coal and stone, NOT_EXPORTED) at 0.8 x value, the smiths' work first (their ore is paid for in the metal goods
## the caravan carries off), one unit at a time from each seller in turn so a short purse is shared.
## The village's currency can therefore grow only by the allowance, and never past its ceiling; the
## goods leave the village; the coins are logged in coin_sources.
func caravan() -> void:
	var every := maxi(1, int(GameData.b("caravan_every_days")))
	var float_coins := int(GameData.b("caravan_float"))
	if w.caravan_purse < float_coins:
		# the region's demand tops the purse up, less and less as the village's coins near their ceiling
		var ceiling := float(GameData.b("caravan_ceiling_per_head")) * float(w.alive_count() - w.alive_count("bandit"))
		var room := clampf(1.0 - float(w.total_coins()) / maxf(1.0, ceiling), 0.0, 1.0)
		w.caravan_purse = mini(float_coins, w.caravan_purse + roundi(float(GameData.b("caravan_allowance")) * every * room))
	var sold := _caravan_imports()
	var stone := _caravan_stone()
	var budget := mini(int(GameData.b("caravan_coins")), w.caravan_purse)
	var bought := 0
	# merchants do not sell the village's food away when there is less than a few days of it (the
	# village's need weighted by age, as everywhere)
	var food := 0.0
	for o: NPC in w.npcs:
		if o.alive and o.role != "bandit":
			for f in FOOD:
				food += o.inv.count(f) * float(GameData.item(f).food)
	for hh in w.households:
		for f in FOOD:
			food += hh.pantry.count(f) * float(GameData.item(f).food)
	for f in FOOD:
		food += w.table_food(f) * float(GameData.item(f).food)
	var keep_food := food < village_day_food() * float(GameData.b("caravan_food_reserve_days"))
	var lines := []                # [seller, item, units for sale]
	for o: NPC in w.npcs:
		if not o.alive or not o.job in ["merchant", "smith"]:
			continue
		var caps: Dictionary = BUYS.get(buy_role(o), {})
		if o.job == "smith":
			caps = {"iron_bar": 8, "pickaxe": 4, "axe": 4, "iron_sword": 4, "copper_sword": 4, "copper_bar": 8, "gold_bar": 2}
		for id in o.inv.ids():
			if not caps.has(id) or NOT_EXPORTED.has(id) or (keep_food and (FOOD.has(id) or id == "meat")):
				continue
			var extra := o.inv.count(id) - int(caps.get(id, 6)) / 2
			if extra > 0:
				lines.append([o, id, extra])
	# the smiths' lines first (they pay for ore with the metal goods the caravan takes), then the others
	var smiths := lines.filter(func(l): return (l[0] as NPC).job == "smith")
	var others := lines.filter(func(l): return (l[0] as NPC).job != "smith")
	for group in [smiths, others]:
		var first: int = (w.day() / every) % maxi(1, group.size())          # who is served first turns
		var moved := true
		while moved and budget > 0:
			moved = false
			for k in group.size():
				var line: Array = group[(k + first) % group.size()]
				var o: NPC = line[0]
				var id: String = line[1]
				var price := maxi(1, roundi(GameData.value(id) * 0.8))
				if int(line[2]) <= 0 or price > budget:
					continue
				line[2] = int(line[2]) - 1
				o.inv.remove(id)
				w.stat("exported_" + id)
				o.coins += price
				o.earned += price
				budget -= price
				w.caravan_purse -= price
				w.coin_sources += price
				w.stat("caravan_coins_in", price)
				w.stat("caravan_in_" + buy_role(o), price)
				bought += price
				moved = true
	w.note("A merchant caravan passes through, buys %d coins' worth from the market%s%s." % [bought,
		(" and sells %d coins' worth of ore and coal to the smiths" % sold) if sold > 0 else "",
		(" and %d stone to the market" % stone) if stone > 0 else ""])


## When the village's own seams of an ore (or coal) are worked out, the caravan brings it: each
## smith buys up to `caravan_import_stock` at the caravan's price while keeping the trader cash
## floor. The coins leave the village (coin_sources falls). Returns the coins spent.
func _caravan_imports() -> int:
	var left := {}
	for d in w.deposits:
		left[d.ore] = int(left.get(d.ore, 0)) + int(d.amount)
	var stock: Dictionary = GameData.b("caravan_import_stock")
	var spent := 0
	for o: NPC in w.npcs:
		if not o.alive or o.job != "smith":
			continue
		for id in stock:
			if int(left.get(id, 0)) > int(GameData.b("caravan_import_when_left")):
				continue
			var price := maxi(1, roundi(GameData.value(id) * float(GameData.b("caravan_import_markup"))))
			while o.inv.count(id) < int(stock[id]) and o.coins - price >= int(GameData.b("trader_cash_floor")):
				o.coins -= price
				o.spent += price
				o.inv.add(id)
				w.coin_sources -= price
				w.caravan_purse += price
				w.stat("caravan_coins_out", price)
				spent += price
				w.stat("imported_" + id)
	return spent


func _stone_scarce() -> bool:
	return w.quests.deposit_left("stone") <= int(GameData.b("caravan_import_when_left"))


## Stone (owner, 2026-10-18; B7-007): once the village's own stone is worked out, the caravan brings
## a cart of it from a quarry on its road: at most caravan_stone.load a visit, bought there at its
## value and sold at value times caravan_stone.markup (the cartage of a heavy, cheap load). The
## raw-goods merchants, the village's stone sellers (Construction.SELLERS), buy it up to their
## stock cap while keeping the trader cash floor; what they cannot pay for goes back with the cart.
## The coins leave the village (coin_sources falls). Returns the stone sold.
func _caravan_stone() -> int:
	if not _stone_scarce():
		return 0
	var cfg: Dictionary = GameData.b("caravan_stone")
	var cart := int(cfg.load)
	var price := maxi(1, roundi(GameData.value("stone") * float(cfg.markup)))
	var sold := 0
	for o: NPC in w.npcs:
		if not o.alive or buy_role(o) != "merchant_raw":
			continue
		while cart > 0 and wants(o, "stone") > 0 and o.coins - price >= int(GameData.b("trader_cash_floor")):
			o.coins -= price
			o.spent += price
			o.inv.add("stone")
			w.coin_sources -= price
			w.caravan_purse += price
			w.stat("imported_stone")
			w.stat("caravan_stone_coins", price)
			w.stat("caravan_coins_out", price)
			cart -= 1
			sold += 1
	return sold
