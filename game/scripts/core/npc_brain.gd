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
		"leather_armor": 2, "iron_armor": 2, "leather": 6, "hide": 6, "iron_bar": 6, "copper_bar": 6, "gold_bar": 4},
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

var w: World
var noted := {}          # one-off notes already written


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
	for i in 12:
		var c := around + Vector2i(w.rng.randi_range(-r, r), w.rng.randi_range(-r, r))
		if not w.map.is_solid(c):
			return c
	return around


func once(key: String, text: String) -> void:
	if not noted.has(key):
		noted[key] = true
		w.note(text)


# ---------------------------------------------------------------- deciding -------------------
func decide(n: NPC) -> void:
	var h := w.hour()
	n.hidden = false
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
	if h >= WORK_START and h < WORK_END and n.job != "":
		if _plan_job(n):
			return
	_plan_evening(n, h)


func _plan_sleep(n: NPC) -> void:
	n.doing = "going home to sleep"
	var until := WAKE + 24.0 if w.hour() >= SLEEP else WAKE
	var mins := (until - w.hour()) * 60.0
	n.plan = [go(w.building_door(n.home)), doit("enter"), work(maxf(mins, 10.0), "leave", {}, "idle")]


func _plan_evening(n: NPC, h: float) -> void:
	var hh: Dictionary = w.households[n.household]
	var dependants := 0
	for m in hh.members:
		var o := w.npc(m)
		if o and o.alive and o.role != "adult":
			dependants += 1
	var pantry: Inventory = hh.pantry
	var stocked := 0
	for f in FOOD:
		stocked += pantry.count(f)
	if n.coins >= 3 and pantry.count("log") < 1:
		var seller := _seller_of("log", n)
		if seller:
			n.doing = "buying firewood"
			n.plan = [go(_workplace_cell(seller)), doit("buy_from", {"vendor": seller.id, "item": "log", "qty": 1, "pantry": true})]
			return
	if n.coins >= 4 and stocked < dependants + 1:
		var v := _vendor_with_food(n)
		if v:
			n.doing = "buying food for the household"
			n.plan = [go(_workplace_cell(v)), doit("buy_food", {"vendor": v.id, "pantry": true})]
			return
	if h >= WORK_END and n.coins >= 3 and w.rng.randf() < 0.35:
		var counter := w.station_use(w.stations_of("tavern_counter")[0])
		n.doing = "at the tavern"
		n.plan = [go(wander_cell(counter + Vector2i(-6, 4), 3)), work(w.rng.randf_range(30, 70), "drink", {}, "idle")]
		return
	n.doing = "resting"
	n.plan = [go(wander_cell(w.building_door(n.home), 4), 0.8), work(w.rng.randf_range(20, 50), "", {}, "idle")]


func _plan_eat(n: NPC) -> bool:
	for f in FOOD:
		if n.inv.has(f):
			n.doing = "eating"
			n.plan = [work(10, "eat", {}, "idle")]
			return true
	var hh: Dictionary = w.households[n.household] if n.household >= 0 else {}
	if not hh.is_empty():
		for f in FOOD:
			if hh.pantry.has(f):
				n.doing = "going home to eat"
				n.plan = [go(w.building_door(n.home)), work(15, "eat_home", {}, "idle")]
				return true
	var payer := n
	if n.coins < 2 and n.role != "adult" and n.household >= 0:
		payer = _richest_in_household(n)     # the family's tab at the tavern
	if payer != null and payer.coins >= 2:
		var v := _vendor_with_food(n)
		if v:
			n.doing = "buying a meal" if payer == n else "eating on the family's tab"
			n.plan = [go(_workplace_cell(v)), doit("buy_food", {"vendor": v.id, "pantry": false, "payer": payer.id}), work(10, "eat", {}, "idle")]
			return true
	if payer != null and payer.coins >= 3:
		for o: NPC in w.npcs:
			if o.alive and o != n and not o.hidden and (o.job == "farmer" or buy_role(o) == "merchant_food") and o.inv.count("wheat") >= 2:
				n.doing = "buying grain for porridge"
				n.plan = [go(_workplace_cell(o) if o.job != "farmer" else o.cell()), doit("buy_from", {"vendor": o.id, "item": "wheat", "qty": 2, "payer": payer.id}), work(15, "eat", {}, "idle")]
				return true
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
		"sage":
			n.doing = "pondering lore"
			n.plan = [go(wander_cell(w.building_door("b_hut") if w.buildings.has("b_hut") else w.building_door(n.home), 3), 0.7), work(60, "", {}, "idle")]
			return true
	return false


func _richest_in_household(n: NPC) -> NPC:
	var best: NPC = null
	for m in w.households[n.household].members:
		var o := w.npc(m)
		if o and o.alive and o.role == "adult" and (best == null or o.coins > best.coins):
			best = o
	return best


func _idle_at_work(n: NPC, why: String) -> bool:
	n.doing = why
	n.plan = [go(_workplace_cell(n)), work(45, "", {}, "idle")]
	return true


func _miner(n: NPC) -> bool:
	if not n.inv.has("pickaxe"):
		return _get_tool(n, "pickaxe")
	var ores := _wanted_ores()
	if n.job == "laborer":
		var raw := _buyer_for(n, "stone")
		ores = ["stone"] if raw != null else ["coal"]
	var carried := 0
	for o in ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]:
		carried += n.inv.count(o)
	if carried >= int(GameData.b("carry_ore")):
		return _plan_sell_all(n)
	var d := w.nearest_deposit(n.cell(), ores)
	if d.is_empty():
		d = w.nearest_deposit(n.cell(), ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"])
	if d.is_empty():
		if carried > 0:
			return _plan_sell_all(n)
		once("mine_out_%d" % n.id, "%s %s finds no ore left to mine." % [n.name, n.family])
		n.job = ""
		return false
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
		if n.inv.has_all(rec.in):
			var st := _station_for(n, rec.station)
			n.doing = "working at the %s" % rec.station
			n.plan = [go(w.station_use(st)), work(float(rec.minutes), "craft", {"recipe": r}, "work", _station_at(st))]
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
	var f := _field(n.workplace)
	if f.is_empty():
		return false
	if n.inv.count("wheat") >= 8 and _buyer_for(n, "wheat") != null:
		return _plan_sell(n, "wheat")
	var spot := Vector2i(int(f.x) + w.rng.randi_range(0, int(f.w) - 1), int(f.y) + int(f.h))
	match f.state:
		"ripe":
			n.doing = "harvesting wheat"
			n.plan = [go(spot), work(90, "harvest", {"field": f.id}, "work")]
		"tilled":
			n.doing = "sowing"
			n.plan = [go(spot), work(45, "sow", {"field": f.id}, "work")]
		_:
			if n.inv.has("wheat") and _buyer_for(n, "wheat") != null:
				return _plan_sell(n, "wheat")
			n.doing = "tending the field"
			n.plan = [go(spot), work(60, "", {}, "work")]
	return true


func _hunter(n: NPC) -> bool:
	if n.inv.count("meat") >= 3 or n.inv.count("hide") >= 2:
		return _plan_sell_all(n)
	if w.deer <= 8:
		n.doing = "letting the deer recover"
		n.plan = [go(wander_cell(w.building_door(n.home), 4)), work(120, "", {}, "idle")]
		return true
	var c := wander_cell(Vector2i(w.rng.randi_range(4, 26) + (60 if w.rng.randf() < 0.5 else 0), w.rng.randi_range(4, 24)), 3)
	n.doing = "hunting in the woods"
	n.plan = [go(c), work(float(GameData.b("hunt_minutes")), "hunt", {}, "idle")]
	return true


func _guard(n: NPC, h: float) -> void:
	var on_duty := (h >= WAKE and h < SLEEP) if n.workplace == "day" else (h >= SLEEP - 1.0 or h < WAKE + 1.0)
	if not on_duty:
		var mins := 120.0
		n.doing = "off duty"
		n.plan = [go(w.building_door(n.home)), doit("enter"), work(mins, "leave", {}, "idle")]
		return
	var foe := _bandit_near(n.pos, 10.0)
	if foe:
		n.target = foe.id
		n.doing = "fighting %s" % foe.name
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
		if not o.alive or o.hidden or o.role == "bandit" or o.job == "guard" or o.coins < 3:
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
	for id in n.inv.ids():
		if not KEEPS.get(n.job, []).has(id) and not FOOD.has(id) and OUTLETS.has(id):
			return _plan_sell(n, id)
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
			if b != n and b.alive and wants(b, id) > 0 and b.coins >= w.buy_price(b, id):
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


func _vendor_with_food(n: NPC) -> NPC:
	var best: NPC = null
	var bd := 1e9
	for o: NPC in w.npcs:
		if not o.alive or o == n or o.hidden:
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


func _seller_of(id: String, buyer: NPC) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o != buyer and not o.hidden and (o.job == "carpenter" or buy_role(o) == "merchant_raw") and o.inv.has(id):
			return o
	return null


func _get_tool(n: NPC, tool: String) -> bool:
	for o: NPC in w.npcs:
		if o.alive and (o.job == "smith" or buy_role(o) == "merchant_goods") and o.inv.has(tool) and not KEEPS.get(o.job, []).has(tool):
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
		return false
	n.doing = "%s" % r.replace("_", " ")
	n.plan = [go(w.station_use(st)), work(float(rec.minutes), "craft", {"recipe": r}, "work", _station_at(st))]
	return true


func _station_for(_n: NPC, kind: String) -> String:
	var ids := w.stations_of(kind)
	return ids[0] if not ids.is_empty() else ""


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
		if o.alive and o.job == "guard" and not o.hidden and o.pos.distance_to(p) <= r:
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
			n.hidden = true
			n.doing = "asleep at home" if w.hour() >= SLEEP or w.hour() < WAKE else "at home"
			return true
		"leave":
			n.hidden = false
			return true
		"eat":
			for f in FOOD:
				if n.inv.has(f):
					n.inv.remove(f)
					n.hunger = minf(100.0, n.hunger + float(GameData.item(f).food))
					return true
			return false
		"eat_home":
			var pantry: Inventory = w.households[n.household].pantry
			for f in FOOD:
				if pantry.has(f):
					pantry.remove(f)
					n.hunger = minf(100.0, n.hunger + float(GameData.item(f).food))
					return true
			return false
		"drink":
			var keeper := _first_with_job("tavernkeeper")
			if keeper and keeper.inv.has("ale"):
				if w.trade(n, keeper, "ale", 1, w.sell_price(keeper, "ale")):
					n.inv.remove("ale")
					n.hunger = minf(100.0, n.hunger + float(GameData.item("ale").food))
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
			var qty := mini(n.inv.count(a.item), wants(b, a.item))
			var sold := 0
			while qty > 0:
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
			if n.inv.wear("pickaxe", 1):
				w.note("%s %s's pickaxe broke." % [n.name, n.family])
			return true
		"chop":
			var t := w.tree_at(Vector2i(int(a.x), int(a.y)))
			t.erase("claimed")
			var logs := w.fell(t, 0)
			if logs <= 0:
				return false
			n.inv.add("log", logs)
			if n.inv.wear("axe", 3):
				w.note("%s %s's axe broke." % [n.name, n.family])
			return true
		"craft":
			var rec: Dictionary = GameData.recipes[a.recipe]
			if not n.inv.remove_all(rec.in):
				return false
			for id in rec.out:
				n.inv.add(id, int(rec.out[id]))
			if rec.station == "anvil":
				n.inv.wear("hammer", 2)
			return true
		"harvest":
			var f := _field(a.field)
			if f.is_empty() or f.state != "ripe":
				return false
			n.inv.add("wheat", int(GameData.b("field_yield")))
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
			if w.deer <= 0:
				once("no_deer_%d" % w.day(), "The hunters find no deer left in the woods today.")
				return true
			w.deer -= 1
			n.inv.add("meat", 2)
			n.inv.add("hide", 1)
			return true
		"poach":
			if n.hunger < 60.0:
				n.hunger = 100.0
				if w.rng.randf() < 0.25 and w.deer > 0:
					w.deer -= 1
			return true
		"look_out":
			var foe := _bandit_near(n.pos, 10.0)
			if foe:
				n.target = foe.id
			return true
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
		if tnpc == null or not tnpc.alive or tnpc.hidden:
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
		if tnpc.target == -1:
			tnpc.target = n.id
		if tnpc.hp <= 0.0:
			w.kill(tnpc, "slain by %s" % n.name)
			n.target = -1


# ---------------------------------------------------------------- village events -------------
## Evening business at the manor: the reeve taxes wealth above a threshold, pays for repairs
## (planks and stone bought and used up) and gives relief to households with no food. Coins only
## move between people; the materials are consumed.
func reeve_day() -> void:
	var reeve := w.npc(w.reeve_id)
	if reeve == null or not reeve.alive:
		once("no_reeve_%d" % w.day(), "There is no reeve to keep the village's accounts.")
		return
	var thr := int(GameData.b("tax_threshold"))
	var taxed := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != reeve and o.coins > thr:
			var t := int((o.coins - thr) * float(GameData.b("tax_rate")))
			o.coins -= t
			reeve.coins += t
			taxed += t
	var budget := int(reeve.coins * float(GameData.b("repairs_budget_share")))
	var bought := 0
	for id in ["plank", "stone", "log"]:
		for o: NPC in w.npcs:
			if not o.alive or not (o.job == "carpenter" or buy_role(o) == "merchant_raw" or o.job == "laborer"):
				continue
			while o.inv.count(id) > 6 and budget > 0 and bought < 40:
				var price := w.buy_price(o, id)
				if price > budget or not w.trade(reeve, o, id, 1, price):
					break
				reeve.inv.remove(id)          # used up in repairs
				budget -= price
				bought += 1
	var relief := 0
	for hh in w.households:
		var food := 0
		for f in FOOD:
			food += hh.pantry.count(f)
		var cash := 0
		var members := 0
		for m in hh.members:
			var o := w.npc(m)
			if o and o.alive:
				members += 1
				cash += o.coins
		if members > 0 and food < members and cash < 4 * members:
			var gift := mini(reeve.coins, int(GameData.b("relief_coins_per_member")) * members)
			for m in hh.members:
				var o := w.npc(m)
				if o and o.alive and o.role == "adult" and gift > 0:
					o.coins += gift
					reeve.coins -= gift
					relief += gift
					break
	if taxed + bought + relief > 0:
		w.note("The reeve took %d coins in tax, bought %d loads for repairs and gave %d coins in relief." % [taxed, bought, relief])


func pay_guards() -> void:
	var reeve := w.npc(w.reeve_id)
	var wage := int(GameData.b("guard_wage_per_day"))
	var sage := w.npc(w.sage_id)
	if sage and sage.alive and reeve and reeve.alive and reeve.coins >= 4:
		reeve.coins -= 4
		sage.coins += 4
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard":
			if reeve and reeve.alive and reeve.coins >= wage:
				reeve.coins -= wage
				o.coins += wage
			else:
				once("unpaid_%d" % w.day(), "The reeve cannot pay the guards today.")


## A merchant caravan passes through: it buys the market's surplus. This is the village's only
## source of new coins (logged in coin_sources), and the goods leave the village.
func caravan() -> void:
	var budget := int(GameData.b("caravan_coins"))
	var bought := 0
	for o: NPC in w.npcs:
		if not o.alive or o.job != "merchant":
			continue
		var caps: Dictionary = BUYS.get(buy_role(o), {})
		if o.job == "smith":
			caps = {"iron_bar": 8, "pickaxe": 4, "axe": 4, "iron_sword": 4, "copper_sword": 4, "copper_bar": 8, "gold_bar": 2}
		for id in o.inv.ids():
			if not caps.has(id):
				continue
			var keep := int(caps.get(id, 6)) / 2
			var extra := o.inv.count(id) - keep
			while extra > 0 and budget > 0:
				var price := maxi(1, roundi(GameData.value(id) * 0.8))
				if price > budget:
					break
				o.inv.remove(id)
				o.coins += price
				o.earned += price
				budget -= price
				w.coin_sources += price
				bought += price
				extra -= 1
	w.note("A merchant caravan passes through and buys %d coins' worth from the market." % bought)
