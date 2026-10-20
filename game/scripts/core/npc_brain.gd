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
	"tanner": {"hide": 15, "rabbit_pelt": 15, "wool": 12},          # wool: woven into cloth (Build 13)
	"sage": {"flower": 20, "linen_bandage": 8},   # flowers for poultices and tonics (PL1-04); bandages the tanner sews (Build 13)
	"cook": {"wheat": 60, "meat": 15, "log": 10, "egg": 20, "milk": 12, "cheese": 10, "carrot": 20, "potato": 20},    # the last five: the player's farm goods (PL2-015)
	"tavernkeeper": {"pottage": 60, "roast_meat": 20, "ale": 20, "bread": 12, "cheese": 8},    # bread and cheese: the tavern's suppers (Build 13)
	"merchant_raw": {"iron_ore": 20, "copper_ore": 15, "coal": 20, "stone": 40, "log": 20, "plank": 20},
	"merchant_food": {"pottage": 20, "roast_meat": 10, "ale": 15, "wheat": 20, "meat": 10,
		"egg": 20, "milk": 10, "cheese": 10, "carrot": 20, "potato": 20, "bread": 15,
		"red_berries": 15, "blueberries": 15, "apple": 15},    # households' gathered berries and apples, brought to market (B14)
	"merchant_goods": {"pickaxe": 4, "axe": 4, "hammer": 2, "copper_sword": 3, "iron_sword": 3,
		"leather_armor": 2, "iron_armor": 2, "leather": 6, "hide": 6, "rabbit_pelt": 6, "feather": 20, "wool": 20, "wool_cloth": 10, "iron_bar": 6, "copper_bar": 6, "gold_bar": 4,
		# crafted gear that had no buyer (B7-003, owner 2026-10-18): the goods merchant takes a few,
		# like the other made goods, and the caravan carries the surplus away
		"copper_ring": 3, "gold_ring": 2, "amulet": 2, "leather_cap": 3, "iron_helmet": 2,
		"herbal_poultice": 8},                     # households' home-brewed poultices, brought to market (B14)
}
# items an NPC keeps for its own work and will not sell
const KEEPS := {"sage": ["flower"], "miner": ["pickaxe"], "laborer": ["pickaxe"], "woodcutter": ["axe"], "smith": ["hammer"],
	# seed is sold only through the seed offer (Farming.buy_seed, Build 13)
	"farmer": ["wheat_seed", "carrot_seed", "potato_seed", "herb_seed"], "merchant": ["wheat_seed", "carrot_seed", "potato_seed", "herb_seed"],
	"guard": ["iron_sword", "leather_armor"], "bandit": ["copper_sword"]}
# who to sell each item to, in order of preference
const OUTLETS := {
	"iron_ore": ["smith", "merchant_raw"], "copper_ore": ["smith", "merchant_raw"], "gold_ore": ["smith", "merchant_goods"],
	"coal": ["smith", "merchant_raw"], "stone": ["merchant_raw"], "log": ["carpenter", "cook", "merchant_raw"],
	"plank": ["smith", "merchant_raw"], "wheat": ["cook", "merchant_food"], "meat": ["cook", "merchant_food"],
	"hide": ["tanner", "merchant_goods"], "rabbit_pelt": ["tanner", "merchant_goods"], "feather": ["merchant_goods"], "leather": ["smith", "merchant_goods"],
	"pottage": ["tavernkeeper", "merchant_food"], "roast_meat": ["tavernkeeper", "merchant_food"], "ale": ["tavernkeeper", "merchant_food"],
	"egg": ["cook", "merchant_food"], "milk": ["cook", "merchant_food"], "cheese": ["tavernkeeper", "cook", "merchant_food"],
	"carrot": ["cook", "merchant_food"], "potato": ["cook", "merchant_food"], "wool": ["tanner", "merchant_goods"], "wool_cloth": ["merchant_goods"],
	"bread": ["tavernkeeper", "merchant_food"], "linen_bandage": ["sage"],
	"red_berries": ["merchant_food"], "blueberries": ["merchant_food"], "apple": ["merchant_food"], "herbal_poultice": ["merchant_goods"],
	"pickaxe": ["merchant_goods"], "axe": ["merchant_goods"], "iron_sword": ["merchant_goods"], "copper_sword": ["merchant_goods"],
	"hammer": ["merchant_goods"], "iron_bar": ["merchant_goods"], "leather_armor": ["merchant_goods"],
}
const FOOD := ["roast_meat", "pottage", "wheat", "ale", "cheese", "bread", "red_berries", "blueberries", "apple"]
const COOKED := ["roast_meat", "pottage", "ale", "cheese", "bread"]     # cheese and egg bread: the cook's, from the pens (Build 13)
# the mine's raw output: finite, and the forge's and the builders' own input. The caravan sells it to
# the village (when the seams are worked out) but does not carry the village's away (B7-007)
const NOT_EXPORTED := ["iron_ore", "copper_ore", "gold_ore", "coal", "stone"]

var w: World
var noted := {}          # one-off notes already written
## Diagnostics only (tests/economy_sim.gd): when on, every missed meal is logged as
## [day, hour, job or role, why, coins of the richest in the household]. Never read by the game.
var track_misses := false
var miss_log: Array = []
var _roles := {}         # trading role -> its villagers (_with_buy_role)
var _roles_key := []


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


## B8-007: how a villager at work looks: [animation, tool item]. Mining, felling, smithing, building and
## hunting show the swing (the throw frames) with the matching tool's icon in the hand, as the player's
## do; picking, sowing and feeding the arms-forward gather frames; anything else the old work frames.
func work_look(n: NPC) -> Array:
	if n.plan.is_empty() or n.plan[0].k != "work":
		return [n.anim, ""]
	var s: Dictionary = n.plan[0]
	match str(s.get("act", "")):
		"mine", "mj_mine":
			return ["swing", "pickaxe"]
		"chop":
			return ["swing", "axe"]
		"mj_step":
			return ["swing", "hammer"]
		"hunt", "slaughter":
			return ["swing", "rusty_sword"]
		"harvest", "sow", "feed_pen":
			return ["gather", ""]
		"craft":
			var st: String = str(w.stations[s.args.station].type) if w.stations.has(s.args.get("station", "")) else ""
			if st in ["anvil", "forge", "workbench", "sawhorse"]:
				return ["swing", "hammer"]
			return ["gather", ""]
	return [str(s.get("anim", "work")), ""]


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


## The home meal (PL1-07): walk to one's own chair and eat seated (World.home_spot "chair", found in the
## home's stool tiles by Furniture); a home without a chair eats standing at its table as before. The
## plan's length and the eating are unchanged, so no schedule moves.
func _home_meal(n: NPC) -> Array:
	var chair := w.home_spot(n, "chair")
	if chair.is_empty():
		return [go(w.home_cell(n, "table")), work(15, "eat_home", {}, "idle")]
	return [go(Vector2i(int(chair.use[0]), int(chair.use[1]))), work(15, "eat_home", {}, "sit")]


# ---------------------------------------------------------------- deciding -------------------
func decide(n: NPC) -> void:
	var h := w.hour()
	if n.anim == "sleep" or n.anim == "sit":
		n.anim = "idle"                    # up from bed, or from the chair (PL1-07)
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
	# minding the player's stall or shop (PL1-10 stage 4)
	if h >= WORK_START and h < WORK_END and w.business.plan_attendant(n):
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


# ---------------------------------------------------------------- home production (B14) --------
## Medicines in the order a villager reaches for them: the least that will do first.
const MEDICINES := ["linen_bandage", "herbal_poultice", "healing_tonic", "strong_healing_tonic"]


static func hp_cfg() -> Dictionary:
	return GameData.b("home_production")


## A hurt villager (below medicine_use_below of their health) treats themselves (owner, Build 14:
## villagers make medicine for their own use): a medicine they carry or the household keeps, at home;
## else one bought from the Apothecary with their own coins. Villagers do not otherwise heal.
func _plan_heal(n: NPC) -> bool:
	if n.role == "bandit" or n.hp >= n.max_hp * float(hp_cfg().medicine_use_below):
		return false
	for m in MEDICINES:
		if n.inv.has(m):
			n.doing = "dressing a wound"
			n.plan = [work(10, "use_medicine", {}, "idle")]
			return true
	var pantry: Inventory = w.households[n.household].pantry if n.household >= 0 else null
	if pantry != null:
		for m in MEDICINES:
			if pantry.has(m):
				n.doing = "going home to dress a wound"
				n.plan = [go(w.home_cell(n, "chest")), work(10, "use_medicine", {"pantry": true}, "idle")]
				return true
	var sellers: Array = [w.npc(w.sage_id)]
	for hid in w.front_keepers:                       # a household's storefront keeper sells its poultices (B14)
		var k := w.npc(int(w.front_keepers[hid]))
		if k != null and w.at_post(k):
			sellers.append(k)
	var best: NPC = null
	var item := ""
	for o: NPC in sellers:
		if o == null or not o.alive or w.asleep(o) or o == n:
			continue
		for m in MEDICINES:
			if o.inv.has(m) and n.coins >= w.sell_price(o, m) and (best == null or n.pos.distance_to(o.pos) < n.pos.distance_to(best.pos)):
				best = o
				item = m
				break
	if best != null:
		n.doing = "buying medicine"
		var at := _workplace_cell(best) if best.id == w.sage_id else Vector2i(best.pos)
		n.plan = [go(at), doit("buy_from", {"vendor": best.id, "item": item, "qty": 1}), work(10, "use_medicine", {}, "idle")]
		return true
	return false


## Evening work for the household (B14): forage ripe wild plants near home (flowers for medicine,
## berries for the pantry) and brew flowers into poultices at the home's hearth. Everything comes from
## real plants and the household's own stock; a household keeps poultice_keep poultices and
## berries_keep berries.
func _plan_home_work(n: NPC) -> bool:
	if n.role != "adult" or n.household < 0 or n.home == "":
		return false
	var cfg := hp_cfg()
	var pantry: Inventory = w.households[n.household].pantry
	var house: Dictionary = w.buildings.get(n.home, {})
	if _plan_market_run(n, house) or _plan_storefront(n, house) or _plan_cart(n, house):
		return true
	var keep := int(cfg.poultice_keep) + (int(cfg.storefront_stock) if house.has("front") else 0)     # a storefront household makes some to sell
	var flowers := pantry.count("flower") + n.inv.count("flower")
	var brew: Dictionary = GameData.recipes["brew_poultice"]
	if pantry.count("herbal_poultice") < keep and flowers >= int(brew["in"].flower):
		n.doing = "brewing a poultice at home"
		n.plan = [go(w.home_cell(n, "hearth")), work(float(brew.minutes), "home_brew", {}, "work")]
		return true
	var want := ""
	if pantry.count("herbal_poultice") < keep and flowers < int(brew["in"].flower):
		want = "flower"
	elif pantry.count("red_berries") + pantry.count("blueberries") + pantry.count("apple") < int(cfg.berries_keep):
		want = "berry"
	if want == "":
		return false
	if want == "berry":                                  # an apple tree in fruit near home serves as well as a bush (B14)
		var ft := _fruit_tree_near(w.building_door(n.home), float(cfg.forage_range))
		var bush := _wild_plant_near(w.building_door(n.home), want, float(cfg.forage_range))
		var door := Vector2(w.building_door(n.home))
		if not ft.is_empty() and (bush.is_empty() or door.distance_to(Vector2(int(ft.x), int(ft.y))) < door.distance_to(Vector2(int(bush.x), int(bush.y)))):
			n.doing = "picking apples"
			n.plan = [go(beside(Vector2i(int(ft.x), int(ft.y)), n.cell())), work(15, "pick_fruit", {"x": int(ft.x), "y": int(ft.y)}, "gather"),
					go(w.home_cell(n, "chest")), doit("store_home", {})]
			return true
	var pl := _wild_plant_near(w.building_door(n.home), want, float(cfg.forage_range))
	if pl.is_empty():
		return false
	n.doing = "gathering %s" % ("wild flowers" if want == "flower" else "berries")
	n.plan = [go(_forage_cell(pl)), work(10, "forage", {"plant": str(pl.id)}, "gather"),
			go(w.home_cell(n, "chest")), doit("store_home", {})]
	return true


## Where a villager stands to pick a plant: its own cell if open, else the open cell below it; (-1, -1) if neither.
func _forage_cell(pl: Dictionary) -> Vector2i:
	var c := Vector2i(int(pl.x), int(pl.y))
	if not w.map.is_solid(c):
		return c
	if not w.map.is_solid(c + Vector2i(0, 1)):
		return c + Vector2i(0, 1)
	return Vector2i(-1, -1)


## A household's storefront (B14, owner: villagers bring home-made goods to a counter at their house).
## With a counter: an adult takes the household's surplus (poultices and berries beyond what it keeps)
## to it and keeps it for the evening, selling to the player and to villagers like any shopkeeper.
## Without one: an industrious adult (coins of their own above storefront_coins, the household's medicine
## already in store, room by the door) buys the materials from the carpenter or the timber stall and the
## smith or the goods stall with their own coins, and builds it.
func _plan_storefront(n: NPC, house: Dictionary) -> bool:
	if house.is_empty() or not w.holds(World.hh_ref(n.household), house):
		return false
	var cfg := hp_cfg()
	var pantry: Inventory = w.households[n.household].pantry
	if house.has("front"):
		var keeper := w.npc(int(w.front_keepers.get(str(house.id), -1)))
		if keeper != null and keeper != n and keeper.alive and w.at_post(keeper):
			return false
		var stock := 0
		for id in front_goods(n.household):
			stock += int(front_goods(n.household)[id])
		for id in FRONT_WARES:
			stock += n.inv.count(id)
		if stock <= 0 or w.hour() >= float(cfg.storefront_close_hour):
			return false
		for id in front_goods(n.household):
			w.transfer(pantry, n.inv, id, int(front_goods(n.household)[id]))
		w.front_keepers[str(house.id)] = n.id
		var f: Dictionary = house.front
		n.doing = "keeping the %s storefront" % n.family
		n.plan = [go(Vector2i(int(f.use[0]), int(f.use[1]))), work(float(cfg.storefront_minutes), "", {}, "idle", Vector2i(int(f.x), int(f.y)))]
		return true
	if n.coins < int(cfg.storefront_coins) or pantry.count("herbal_poultice") < int(cfg.poultice_keep) or w.business.front_place(house).is_empty():
		return false
	var plan := []
	var cost := Business.storefront_cost()
	for id in cost:
		var short := int(cost[id]) - n.inv.count(id)
		if short <= 0:
			continue
		var seller := _seller_of(id, n) if id != "iron_bar" else _bar_seller(n)
		if seller == null or seller.inv.count(id) < short:
			return false
		plan.append_array([go(_workplace_cell(seller) if seller.job != "smith" else seller.cell()), doit("buy_from", {"vendor": seller.id, "item": id, "qty": short})])
	plan.append_array([go(w.building_door(n.home) + Vector2i(0, 1)), work(60, "build_front", {}, "work")])
	n.doing = "building a storefront"
	n.plan = plan
	return true


## What a storefront household sells: medicine and berries beyond what the household keeps.
const FRONT_WARES := ["herbal_poultice", "red_berries", "blueberries", "apple"]


func front_goods(h: int) -> Dictionary:
	var cfg := hp_cfg()
	var pantry: Inventory = w.households[h].pantry
	var out := {}
	var extra := pantry.count("herbal_poultice") - int(cfg.poultice_keep)
	if extra > 0:
		out["herbal_poultice"] = extra
	var spare := pantry.count("red_berries") + pantry.count("blueberries") + pantry.count("apple") - int(cfg.berries_keep)     # the household keeps berries_keep of berries and apples
	for id in ["apple", "red_berries", "blueberries"]:
		var e := mini(spare, pantry.count(id))
		if e > 0:
			out[id] = e
			spare -= e
	return out


## Who sells iron bars: the smith or the goods stall, with one to spare.
func _bar_seller(n: NPC) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o != n and not w.asleep(o) and (o.job == "smith" or buy_role(o) == "merchant_goods") and o.inv.count("iron_bar") > 1:
			return o
	return null


## Where a household parks its cart: the first open cell beside the house door's step (B14).
func cart_spot(home: String) -> Vector2i:
	var door := w.building_door(home)
	for off in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(2, 1), Vector2i(-2, 1), Vector2i(0, 2)]:
		var c: Vector2i = door + off
		if not w.map.is_solid(c):
			return c
	return door + Vector2i(0, 1)


## A market run (B14, owner: "this is how they move house made goods to a market"): an adult of a household
## with a parked cart and carts.trip_min or more surplus goods in store (front_goods) takes the cart, loads the
## surplus, pulls it to the merchants who buy each good, sells, and brings the cart home; whatever is not sold
## goes back into the store. Only the household's own members use its cart.
func _plan_market_run(n: NPC, house: Dictionary) -> bool:
	if house.is_empty() or w.hour() >= float(hp_cfg().storefront_close_hour) - 2.0:
		return false
	var cart := {}
	for c in w.carts.of(World.hh_ref(n.household)):
		if str(c.puller) == "":
			cart = c
	if cart.is_empty():
		return false
	var goods := front_goods(n.household)
	var total := 0
	var stops := []
	for id in goods:
		total += int(goods[id])
		var b := _buyer_for(n, id)
		if b != null:
			stops.append([b, id])
	if total < int(Carts.cfg().trip_min) or stops.is_empty():
		return false
	var plan := [go(Vector2i(cart.pos)), doit("cart_hitch", {"cart": int(cart.id)}), work(float(Carts.cfg().load_minutes), "cart_load", {}, "work")]
	for st in stops:
		plan.append_array([go(_workplace_cell(st[0])), doit("cart_sell", {"buyer": st[0].id, "item": st[1]})])
	plan.append_array([go(cart_spot(n.home)), doit("cart_park", {})])
	n.doing = "taking the household's goods to market by cart"
	n.plan = plan
	w.stat("cart_market_runs")
	return true


## Carts (B14, owner: "a recipe for carts using the materials we have ... a smithy, a carpenter"). The
## carpenter saws cart wheels from its planks and assembles handcarts for sale at a workbench, buying the
## axle and the ironwork from the smith with its own coins; the smith forges those (NPCBrain._smith).
func _carpenter_carts(n: NPC) -> bool:
	var cfg: Dictionary = GameData.b("carts")
	var rec: Dictionary = GameData.recipes["build_handcart"]
	if n.inv.count("handcart") < int(cfg.handcart_stock):
		if n.inv.has_all(rec["in"]) and _do_recipe(n, "build_handcart"):
			n.doing = "building a handcart"
			return true
		if n.inv.count("cart_wheel") >= int(rec["in"].cart_wheel) and n.inv.count("plank") >= int(rec["in"].plank):
			var plan := _parts_trip(n, {"cart_axle": rec["in"].cart_axle, "cart_ironwork": rec["in"].cart_ironwork}, int(cfg.cart_coins) / 3)
			if not plan.is_empty():
				n.doing = "buying ironwork for a handcart"
				n.plan = plan
				return true
	if n.inv.count("cart_wheel") < int(cfg.wheel_stock) and n.inv.count("plank") >= int(cfg.wheel_min_planks) and _do_recipe(n, "make_cart_wheel"):
		n.doing = "making a cart wheel"
		return true
	return false


## Who sells a cart part or a handcart: a carpenter, smith or merchant holding one (the nearest first).
func _part_seller(id: String, n: NPC) -> NPC:
	var best: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != n and not w.asleep(o) and (o.job in ["carpenter", "smith"] or o.job == "merchant") and o.inv.has(id) \
				and (best == null or o.pos.distance_to(n.pos) < best.pos.distance_to(n.pos)):
			best = o
	return best


## The walk to buy the parts `need` ({id: qty}) that `n` lacks, with their own coins, keeping `floor`
## coins in hand; [] if a part has no seller or they cannot pay. Planks also come from the timber stall.
func _parts_trip(n: NPC, need: Dictionary, floor := 0) -> Array:
	var plan := []
	var cost := 0
	for id in need:
		var short := int(need[id]) - n.inv.count(id)
		if short <= 0:
			continue
		var o := _seller_of(id, n) if id == "plank" else _part_seller(id, n)
		if o == null or o.inv.count(id) < short:
			return []
		cost += w.sell_price(o, id) * short
		plan.append_array([go(_workplace_cell(o) if o.job != "smith" else o.cell()), doit("buy_from", {"vendor": o.id, "item": id, "qty": short})])
	if n.coins - cost < floor:
		return []
	return plan


## Whether a household has a handcart: set down (Carts), in its store or carried by a member.
func household_cart(h: int) -> bool:
	if w.households[h].pantry.has("handcart") or not w.carts.of(World.hh_ref(h)).is_empty():
		return true
	for m in w.households[h].members:
		var o := w.npc(m)
		if o != null and o.inv.has("handcart"):
			return true
	return false


## A storefront household gets a handcart to take its goods to market (B14): an adult with cart_coins of
## their own buys the parts they lack (wheels from the carpenter, the axle and the ironwork from the smith,
## planks) and assembles it at a workbench, or buys a finished one from the carpenter when that is cheaper
## or the parts are not to be had. Either way it goes into the household's store.
func _plan_cart(n: NPC, house: Dictionary) -> bool:
	var cfg: Dictionary = GameData.b("carts")
	if not house.has("front") or n.coins < int(cfg.cart_coins) or household_cart(n.household):
		return false
	var rec: Dictionary = GameData.recipes["build_handcart"]
	var parts := 0
	var parts_plan := _parts_trip(n, rec["in"])
	for id in rec["in"]:
		var short := int(rec["in"][id]) - n.inv.count(id)
		var o := _seller_of(id, n) if id == "plank" else _part_seller(id, n)
		if short > 0 and o != null:
			parts += w.sell_price(o, id) * short
	var bench := _station_for(n, "workbench") if not parts_plan.is_empty() or n.inv.has_all(rec["in"]) else ""
	var maker := _part_seller("handcart", n)
	var whole := w.sell_price(maker, "handcart") if maker != null else 1 << 30
	var home := [go(w.home_cell(n, "chest")), doit("store_home", {})]
	if bench != "" and (parts < whole or maker == null):
		w.stations[bench].users[n.id] = w.minutes + w.map.data.w * 3 + float(rec.minutes) + 120.0
		n.doing = "gathering parts for a handcart"
		n.plan = parts_plan + [go(w.station_use(bench)), work(float(rec.minutes), "craft", {"recipe": "build_handcart", "station": bench}, "work", _station_at(bench))] + home
		return true
	if maker != null and n.coins >= whole:
		n.doing = "buying a handcart"
		n.plan = [go(_workplace_cell(maker) if maker.job != "smith" else maker.cell()), doit("buy_from", {"vendor": maker.id, "item": "handcart", "qty": 1})] + home
		return true
	return false


## The nearest village fruit tree with ripe fruit within `r` of `at`, {} if none (B14).
func _fruit_tree_near(at: Vector2i, r: float) -> Dictionary:
	var best := {}
	var bd := r
	for t in w.trees:
		if t.has("species") and Trees.fruit_ripe(t, w.day(), w.season()):
			var d := Vector2(at).distance_to(Vector2(int(t.x), int(t.y)))
			if d <= bd:
				bd = d
				best = t
	return best


## The nearest ripe village plant of a kind ("flower", or "berry" for either bush) within `r` of `at`.
func _wild_plant_near(at: Vector2i, kind: String, r: float) -> Dictionary:
	var best := {}
	var bd := r
	for pl in w.plants:
		if pl.state != "ripe":
			continue
		var k := str(pl.kind)
		if not (k == kind or (kind == "berry" and k in ["redberry", "blueberry"])):
			continue
		var d := Vector2(at).distance_to(Vector2(int(pl.x), int(pl.y)))
		if d <= bd and _forage_cell(pl) != Vector2i(-1, -1):
			bd = d
			best = pl
	return best


## Food units in the household pantry.
func _stocked(hh: Dictionary) -> int:
	var stocked := 0
	for f in FOOD:
		stocked += (hh.pantry as Inventory).count(f)
	return stocked


func _plan_evening(n: NPC, h: float) -> void:
	if _plan_heal(n):
		return
	if _plan_provision(n):
		return
	if _plan_home_work(n):
		return
	var hh: Dictionary = w.households[n.household]
	var dependants := _dependants(hh)
	var stocked := _stocked(hh)
	# a single villager with coins or a gift to spare seeks out the one they court, or a friend (CRT-11)
	if h >= WORK_END and stocked >= dependants + 1 and _plan_seek_company(n):
		return
	# an evening at the tavern only when the household is provided for and there is coin to spare
	if h >= WORK_END and n.coins >= int(GameData.b("tavern_spare_coins")) and stocked >= dependants + 1 and w.rng.randf() < 0.35:
		var counter := w.station_use(w.stations_of("tavern_counter")[0])
		n.doing = "at the tavern"
		n.plan = [go(wander_cell(counter + Vector2i(-6, 4), 3)), work(w.rng.randf_range(30, 70), "drink", {}, "idle")]
		return
	n.doing = "resting"
	n.plan = [go(wander_cell(w.building_door(n.home), 4), 0.8), work(w.rng.randf_range(20, 50), "", {}, "idle")]


## CRT-11 (owner: "if the single character has extra money and resources it should make them want to spend
## more time around other characters"): an unpartnered adult with relations.seek.coins or a gift in hand, on
## seek.chance of evenings (without the means, seek.poor_chance), goes to spend time beside the one they are courting (or, with no interest yet, the
## friend they think most of); with seek.gift_coins to spare and nothing to give, they first buy a gift (ale
## from the tavern keeper, or a loaf from a food seller). Being near is what builds the tie (Relations.hour);
## the gift is given at dawn. Villagers without the means court more slowly. A household putting money by for
## a home (Construction.saving_for_home, HOUSE-04) buys no gifts: the evening is still spent together.
func _plan_seek_company(n: NPC) -> bool:
	var sk: Dictionary = Relations.cfg().seek
	if n.role != "adult" or n.partner != -1:
		return false
	var has_gift := false
	for id in ["flower", "ale", "bread", "apple", "red_berries", "blueberries"]:
		has_gift = has_gift or n.inv.has(id)
	var means := n.coins >= int(sk.coins) or has_gift
	if w.rng.randf() >= (float(sk.chance) if means else float(sk.poor_chance)):
		return false
	var r: Relations = w.relations
	var who: NPC = w.npc(int(r.interests.get(n.id, -1))) if r.interests.has(n.id) else null
	if who == null:
		var best := -1.0
		for k in r.ties:
			var ids: PackedStringArray = str(k).split(":")
			if int(ids[0]) != n.id and int(ids[1]) != n.id:
				continue
			var o := w.npc(int(ids[1]) if int(ids[0]) == n.id else int(ids[0]))
			var t: Dictionary = r.ties[k]
			if o != null and o.alive and bool(t.friends) and float(t.regard) > best:
				best = float(t.regard)
				who = o
	if who == null or not who.alive or w.asleep(who):
		return false
	n.plan = []
	if not has_gift and n.coins >= int(sk.gift_coins) and not w.construction.saving_for_home(n):
		for v: NPC in w.npcs:
			if v.alive and v != n and not w.asleep(v) and ((v.job == "tavernkeeper" and v.inv.has("ale")) or (buy_role(v) == "merchant_food" and v.inv.has("bread"))):
				n.plan.append(go(_workplace_cell(v)))
				n.plan.append(doit("buy_from", {"vendor": v.id, "item": "ale" if v.job == "tavernkeeper" else "bread", "qty": 1}))
				break
	n.doing = "spending time with %s" % who.name
	n.plan.append(go(wander_cell(who.cell(), 1), 0.8))
	n.plan.append(work(w.rng.randf_range(40, 90), "", {}, "idle"))
	w.stat("evenings_seeking_company")
	return true


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
			n.plan = _home_meal(n)
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
						] + _home_meal(n)
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
			if _carpenter_carts(n):
				return true
			if n.inv.count("plank") >= 30:
				return _plan_sell(n, "plank") if _buyer_for(n, "plank") else _idle_at_work(n, "waiting for orders")
			return _crafter(n, ["saw_planks"])
		"smith":
			return _smith(n)
		"tanner":
			return _tanner(n)
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
			# the apothecary: flowers bought from foragers become poultices and tonics at the stove
			if n.inv.count("herbal_poultice") < 8 and n.inv.has("flower", 2) and _do_recipe(n, "brew_poultice"):
				return true
			if n.inv.count("healing_tonic") < 6 and n.inv.has("flower", 5) and _do_recipe(n, "brew_healing_tonic"):
				return true
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
	_open_vacancy(n)
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
		if not keeps(n, id) and _overstock(n, id):
			return _plan_sell(n, id)
	n.doing = "waiting for materials"
	n.plan = [go(_workplace_cell(n)), work(30, "", {}, "idle")]
	return true


## The tanner (Build 13): hides and pelts to leather, wool to cloth, and cloth to bandages for the
## Apothecary when the sage wants them. Everything comes out of the tanner's own stock.
func _tanner(n: NPC) -> bool:
	var sage := w.npc(w.sage_id)
	if n.inv.has("linen_bandage") and sage != null and sage.alive and wants(sage, "linen_bandage") > 0:
		return _plan_sell(n, "linen_bandage")
	var list := ["tan_leather", "tan_pelts"]
	if n.inv.count("wool_cloth") < 4:
		list.append("weave_cloth")
	if sage != null and sage.alive and wants(sage, "linen_bandage") >= 3 and n.inv.count("linen_bandage") < 3:
		list.append("sew_bandages")
	return _crafter(n, list)


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
	# the manor's orders first (EQ-19): the tools it paid for in advance
	for x in w.manor_orders:
		if int(x.smith) == n.id and inv.count(str(x.tool)) == 0:
			var r := "forge_" + str(x.tool)
			if GameData.recipes.has(r) and inv.has_all(GameData.recipes[r].in):
				return _do_recipe(n, r)
	# forge whatever is scarcest
	var wants := []
	for r in ["forge_pickaxe", "forge_axe", "forge_iron_sword", "forge_hammer", "forge_copper_sword", "forge_iron_armor", "forge_lockpicks", "forge_padlock", "forge_cart_axle", "forge_cart_ironwork"]:
		var out: String = GameData.recipes[r].out.keys()[0]
		var cap := 1 if out in ["hammer", "iron_armor", "padlock", "cart_axle", "cart_ironwork"] else 3
		if inv.count(out) < cap and inv.has_all(GameData.recipes[r].in):
			wants.append([inv.count(out), r])
	wants.sort()
	if not wants.is_empty():
		return _do_recipe(n, wants[0][1])
	# with nothing to forge, the forge's inputs from the raw-goods merchant once the mine no longer brings them (EQ-07): the
	# caravan's ore and coal (B7-007) sat unsold at the merchant while the axes wore out, the woodcutters
	# stopped felling and the carpenter, and every house site, ran out of planks
	if inv.count("iron_bar") < 2 and n.coins >= 10:
		for id in ["coal", "iron_ore"]:
			var short := (2 if id == "coal" else 4) - inv.count(id)
			if short <= 0:
				continue
			for v: NPC in w.npcs:
				if v.alive and v != n and buy_role(v) == "merchant_raw" and v.inv.count(id) > 0 and not w.asleep(v):
					n.doing = "buying %s for the forge" % GameData.item_name(id).to_lower()
					n.plan = [go(_workplace_cell(v)), doit("buy_from", {"vendor": v.id, "item": id, "qty": short})]
					w.stat("forge_bought_" + id)
					return true
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
	for f in ["cheese", "bread"]:                   # the table's goods go out fresh to the tavern and the stall (Build 13)
		if n.inv.count(f) >= 2 and _buyer_for(n, f) != null:
			return _plan_sell(n, f)
	if n.inv.has_all({"meat": 1, "log": 1}) and n.inv.count("roast_meat") < 6:
		return _do_recipe(n, "roast_meat")
	if n.inv.has("wheat", 3) and n.inv.count("ale") < 4 and w.rng.randf() < 0.3:
		return _do_recipe(n, "brew_ale")
	# the pens' milk and eggs (Build 13): cheese and egg bread at the kitchen's preparation table
	if n.inv.has("milk", 3) and n.inv.count("cheese") < 6 and _do_recipe(n, "press_cheese"):
		return true
	if n.inv.has_all({"egg": 1, "wheat": 2}) and n.inv.count("bread") < 6 and _do_recipe(n, "bake_egg_bread"):
		return true
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
	var st: String = f.state
	if st == "ripe" and not w.field_cuttable(f):
		st = "standing"                            # ripe in sight for a while before the cutting (PL2-007)
	match "hired" if f.state == "ripe" and not w.quests.hired_on(f).is_empty() else st:
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
	# the pen's eggs, milk and wool (Build 13): collected at the gate, then sold to the cook and the tanner
	if not w.farm.products_in(pen).is_empty():
		n.doing = "collecting from the %s" % GameData.b("animals")[pen.kind].name.to_lower()
		n.plan = [go(Vector2i(int(pen.feed_at[0]), int(pen.feed_at[1]))), work(10, "collect_pen", {"pen": pen.id}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))]
		return true
	var sells := ["meat", "hide", "feather", "egg", "milk", "wool"].filter(func(i): return n.inv.has(i))
	if not sells.is_empty():
		var buyer := _buyer_for(n, sells[0])
		if buyer != null:
			return _plan_sell(n, sells[0])
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
	if n.inv.count("meat") >= 4 or n.inv.count("hide") >= 2 or n.inv.count("rabbit_pelt") >= 3 or n.inv.count("feather") >= 6:
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
	var lost := _loot_to_recover(n)
	if not lost.is_empty():
		n.doing = "recovering what was left lying"
		n.plan = [go(Vector2i(floori(lost.pos.x), floori(lost.pos.y))), doit("recover_loot")]
		return
	var post: Vector2i = w.guard_posts[w.rng.randi() % w.guard_posts.size()]
	n.doing = "on patrol"
	n.plan = [go(post), doit("look_out")]


## OD-16 (a), EQ-20 (owner 2026-10-20: "guards recover loot to the treasury"): the nearest loot holding coins that has
## lain `loot_recover_hours` within `guard_loot_range` tiles of a guard on duty, or {}. Loot is stamped when first seen.
func _loot_to_recover(n: NPC) -> Dictionary:
	var best: Dictionary = {}
	var bd := float(GameData.b("guard_loot_range"))
	for l in w.loot:
		if int(l.coins) <= 0:
			continue
		if not l.has("t"):
			l.t = w.minutes
		if w.minutes - float(l.t) < float(GameData.b("loot_recover_hours")) * 60.0:
			continue
		var d: float = n.pos.distance_to(l.pos)
		if d < bd and _bandit_near(l.pos, 8.0) == null:
			bd = d
			best = l
	return best


func _bandit(n: NPC, h: float) -> void:
	var night := h >= 21.0 or h < 4.5
	if night:
		var prey = _prey_for(n)
		if prey != null:
			n.target = prey.id if prey is NPC else -2
			n.doing = "stalking"
			return
	if not night and h >= WORK_START and h < WORK_END and _bandit_market(n):
		return
	n.doing = "lurking at the camp"
	n.plan = [go(wander_cell(w.bandit_camp, 3)), work(w.rng.randf_range(30, 90), "poach", {}, "idle")]


## OD-16 (a), EQ-20 (owner 2026-10-20: "bandits spend their hoards at the market"): by day a bandit holding
## `bandit_spend_min` coins slips into the market and buys up to `bandit_spend_units` of food from a seller no
## guard stands near (within 10 tiles), so stolen coins return to the village's traders.
func _bandit_market(n: NPC) -> bool:
	if n.coins < int(GameData.b("bandit_spend_min")) or n.hp < n.max_hp * 0.6:
		return false
	for v: NPC in w.npcs:
		if not v.alive or v.role == "bandit" or not (buy_role(v) == "merchant_food" or v.job == "cook") or w.asleep(v):
			continue
		var at := _workplace_cell(v)
		if _guard_near(Vector2(at), 10.0):
			continue
		for f in FOOD:
			if v.inv.has(f) and w.sell_price(v, f) <= n.coins:
				var qty := mini(int(GameData.b("bandit_spend_units")), n.coins / maxi(1, w.sell_price(v, f)))
				n.doing = "slipping into the market"
				n.plan = [go(at), doit("buy_from", {"vendor": v.id, "item": f, "qty": qty})]
				w.stat("bandit_market_trips")
				return true
	return false


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
		if not keeps(n, id) and not FOOD.has(id) and OUTLETS.has(id):
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


## The living villagers who hold a trading role, in villager order. Kept between calls and rebuilt when
## anyone's job, workplace or life changes, a villager is added or removed, or a stall is added (PERF-04:
## the buyer searches were a third of the simulation's time). Callers only read the list.
func _with_buy_role(role: String) -> Array:
	var key := [NPC.roles_version, w.npcs.size(), w.npcs[-1].id if not w.npcs.is_empty() else -1, w.stalls.size()]
	if key != _roles_key:
		_roles_key = key
		_roles.clear()
	if not _roles.has(role):
		var out := []
		for o: NPC in w.npcs:
			if o.alive and buy_role(o) == role:
				out.append(o)
		_roles[role] = out
	return _roles[role]


func buy_role(o: NPC) -> String:
	if o.job == "merchant" and w.stalls.has(o.workplace):
		return "merchant_" + w.stalls[o.workplace].kind
	return o.job


## What a villager keeps rather than sells: their trade's tools (KEEPS) and, while they build their own
## household's home, the axe they fell its timber with (HOUSE-04).
func keeps(o: NPC, id: String) -> bool:
	if KEEPS.get(o.job, []).has(id):
		return true
	if o.job == "smith" and w.manor_orders.any(func(x): return int(x.smith) == o.id and str(x.tool) == id):
		return true                                   # forged for the manor's order (EQ-19)
	return id == "axe" and o.household >= 0 and o.household < w.households.size() \
			and str(w.households[o.household].get("build", "")) != "" and w.construction.responsible_adult(o.household) == o


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
		if keeps(o, id):
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


## Which meal `payer` buys from `v` (Build 13): the most food for the coin at today's prices, which rise
## as the vendor's stock runs low, so cheap pottage gives way to egg bread when the pot is nearly empty.
## Someone with coins to spare sometimes treats the household to cheese. "" if nothing is affordable.
func _meal_choice(payer: NPC, v: NPC, menu: Array = COOKED) -> String:
	var spare := payer.coins >= int(GameData.b("tavern_spare_coins"))
	if spare and v.inv.has("cheese") and payer.coins >= w.sell_price(v, "cheese") and w.rng.randf() < float(GameData.b("cheese_treat_chance")):
		return "cheese"
	var best := ""
	var best_v := -1.0
	for f in menu:
		if not v.inv.has(f):
			continue
		var price := w.sell_price(v, f)
		if price > payer.coins:
			continue
		var per := float(GameData.item(f).food) / float(maxi(1, price))
		if per > best_v:
			best_v = per
			best = f
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


## The tool a trade cannot work without (the woodcutter's axe, the miner's pickaxe).
const JOB_TOOL := {"woodcutter": "axe", "miner": "pickaxe"}


## What a tool costs `n` to replace now: the cheapest seller's price (the goods merchant, the smith), or -1
## when nobody has one for sale.
func tool_price(n: NPC, tool: String) -> int:
	var best := -1
	for o: NPC in w.npcs:
		if o.alive and o != n and (o.job == "smith" or buy_role(o) == "merchant_goods") and o.inv.has(tool) and not keeps(o, tool):
			var p := w.sell_price(o, tool)
			best = p if best < 0 else mini(best, p)
	return best


## A worker whose trade needs a tool they have not got and cannot pay for: out of work in all but name
## (EQ-07: a woodcutter whose axe broke after she put her coins into her house earned a coin or two a day
## and never got either back).
func tool_short(n: NPC) -> bool:
	var tool: String = JOB_TOOL.get(n.job, "")
	if tool == "" or n.inv.has(tool) or not _order_for(n).is_empty():
		return false                                  # (a tool the manor ordered for them is being forged, EQ-19)
	var p := tool_price(n, tool)
	return p < 0 or n.coins < p


## How many of each work tool the village's own people need now (EQ-07): workers whose trade needs a tool
## they lack, and builders of their own household's home who have no axe to fell its timber with.
func local_tool_need() -> Dictionary:
	var need := {"axe": 0, "pickaxe": 0}
	for o: NPC in w.npcs:
		if not o.alive or o.role != "adult":
			continue
		var tool: String = JOB_TOOL.get(o.job, "")
		if tool != "" and not o.inv.has(tool):
			need[tool] = int(need[tool]) + 1
		elif tool != "axe" and not o.inv.has("axe") and o.household >= 0 and str(w.households[o.household].get("build", "")) != "" \
				and w.construction.responsible_adult(o.household) == o:
			need.axe = int(need.axe) + 1
	return need


func _get_tool(n: NPC, tool: String) -> bool:
	# the goods merchant retails tools (the smith's wholesale buyer, B7-016); the smith sells what the merchant lacks
	for role in ["merchant_goods", "smith"]:
		for o: NPC in w.npcs:
			if o.alive and ((o.job == "smith") if role == "smith" else (buy_role(o) == role)) and o.inv.has(tool) and not keeps(o, tool):
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
			if float(users[u]) < w.minutes or o == null or not o.alive or o.target != -1 \
					or not o.plan.any(func(s): return str(s.get("args", {}).get("station", "")) == id):
				users.erase(u)             # lapsed, dead, fighting or moved on to another task (PL2-001)
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
				# a supper with the ale (Build 13): a hungry drinker buys the tavern's bread or cheese, the best
				# plate for the coin (cheese as a treat), out of the keeper's own stock
				if n.hunger < float(GameData.b("tavern_supper_hunger")):
					var plate := _meal_choice(n, keeper, ["bread", "cheese"])
					if plate != "" and w.trade(n, keeper, plate, 1, w.sell_price(keeper, plate)):
						n.inv.remove(plate)
						n.hunger = minf(100.0, n.hunger + float(GameData.item(plate).food))
						w.stat("eaten_food", float(GameData.item(plate).food))
						w.stat("eaten_" + plate)
			return true
		"build_front":
			return w.business.build_npc_front(w.buildings.get(n.home, {}), n)
		"use_medicine":
			var from: Inventory = w.households[n.household].pantry if a.get("pantry", false) and n.household >= 0 else n.inv
			for m in MEDICINES:
				if from.has(m) and n.hp < n.max_hp:
					from.remove(m)
					n.hp = minf(n.max_hp, n.hp + float(GameData.item(m).heal))
					w.stat("npc_used_" + m)
					w.stat("used_" + m)                   # consumed, as when the player uses one (EQ-10)
					return true
			return false
		"forage":
			var pl := {}
			for p in w.plants:
				if str(p.id) == str(a.plant):
					pl = p
			var got: Dictionary = w.pick_plant(pl)
			for id in got:
				n.inv.add(id, int(got[id]))
				w.stat("villager_foraged_" + id, float(got[id]))
			return not got.is_empty()
		"store_home":
			var pantry: Inventory = w.households[n.household].pantry
			for id in ["flower", "red_berries", "blueberries", "apple"]:
				if n.inv.has(id):
					w.transfer(n.inv, pantry, id, n.inv.count(id))
			while n.inv.has("handcart"):                  # B14: a household's handcart is set down at its house
				n.inv.remove("handcart", 1)
				w.carts.place(World.hh_ref(n.household), Vector2(cart_spot(n.home)) + Vector2(0.5, 0.5))
			return true
		"pick_fruit":
			var t := w.tree_at(Vector2i(int(a.x), int(a.y)))
			var got := w.pick_fruit(t)
			for id in got:
				n.inv.add(id, int(got[id]))
				w.stat("villager_picked_" + id, float(got[id]))
			return not got.is_empty()
		"cart_hitch":
			var c: Dictionary = w.carts.by_id(int(a.cart))
			return not c.is_empty() and w.carts.hitch(c, World.npc_ref(n.id)) == ""
		"cart_load":
			var c: Dictionary = w.carts.pulled_by(World.npc_ref(n.id))
			if c.is_empty():
				return false
			var goods := front_goods(n.household)
			for id in goods:
				w.transfer(w.households[n.household].pantry, c.store, id, int(goods[id]))
			return true
		"cart_sell":
			var c: Dictionary = w.carts.pulled_by(World.npc_ref(n.id))
			if c.is_empty() or not (c.store as Inventory).has(a.item):
				return false
			w.transfer(c.store, n.inv, a.item, (c.store as Inventory).count(a.item))
			act(n, "sell_to", {"buyer": a.buyer, "item": a.item})
			if n.inv.has(a.item):                         # what the buyer would not take goes back in the cart
				w.transfer(n.inv, c.store, a.item, n.inv.count(a.item))
			return true
		"cart_park":
			var c: Dictionary = w.carts.pulled_by(World.npc_ref(n.id))
			if c.is_empty():
				return false
			if (c.store as Inventory).total() > 0:       # unsold goods go back into the household's store
				for id in (c.store as Inventory).ids():
					w.transfer(c.store, w.households[n.household].pantry, id, (c.store as Inventory).count(id))
			w.carts.park(c)
			return true
		"home_brew":
			var pantry: Inventory = w.households[n.household].pantry
			var rec: Dictionary = GameData.recipes["brew_poultice"]
			if n.inv.has("flower"):
				w.transfer(n.inv, pantry, "flower", n.inv.count("flower"))
			if not pantry.has_all(rec["in"]):
				return false
			pantry.remove_all(rec["in"])
			for id in rec.out:
				pantry.add(id, int(rec.out[id]))
				w.stat("made_" + id, float(rec.out[id]))
			for id in rec["in"]:
				w.stat("used_" + id, float(rec["in"][id]))
			w.stat("home_brewed")
			return true
		"collect_pen":
			var pen: Dictionary = w.fauna.pens.get(str(a.pen), {})
			if pen.is_empty():
				return false
			for id in w.farm.products_in(pen):
				var k := int(pen.products[id])
				if n.inv.can_add(id):
					n.inv.add(id, k)
					pen.products[id] = 0
					w.stat("keeper_collected_" + id, float(k))
					w.stat("made_" + id, float(k))       # a pen's products become goods when collected
			return true
		"buy_food":
			var v := w.npc(int(a.vendor))
			if v == null or not v.alive:
				return false
			var payer := w.npc(int(a.get("payer", n.id)))
			if payer == null or not payer.alive:
				payer = n
			var f := _meal_choice(payer, v)
			if f != "" and w.trade(payer, v, f, 1, w.sell_price(v, f)):
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
		"buy_stall":
			return w.business.arrive(n, a)       # a villager at the player's market stall (PL1-10)
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
			if f.is_empty() or not w.field_cuttable(f) or not w.quests.hired_on(f).is_empty():
				return false                                       # (left to the player hired to cut it)
			n.inv.add("wheat", w.farm.save_seed(n, w.take_crop(f, 1 << 30)))   # whatever is left on the field, less the seed kept back
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
		"recover_loot":
			for l in w.loot:
				if int(l.coins) > 0 and n.pos.distance_to(l.pos) < 1.6:
					var c := int(l.coins)
					l.coins = 0
					w.treasury += c                  # the manor's, for the village (EQ-20)
					w.stat("gov_loot_recovered", c)
					if (l.inv as Inventory).total() == 0:
						w.loot.erase(l)
					w.note("%s %s brings %d coins left lying to the manor." % [n.name, n.family, c])
					return true
			return false
		"look_out":
			var foe := _bandit_near(n.pos, 10.0)
			if foe:
				n.target = foe.id
			return true
		"helper_take", "helper_buy", "helper_own", "helper_deliver":
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
			if not keeps(tnpc, id):
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
		# the death screen names who struck: "Wat the guard", "Rob the bandit", or just the name
		var who := n.job if n.job != "" else ("bandit" if n.role == "bandit" else "")
		w.damage_player(n.damage, n.name + (" the " + who if who != "" else ""))
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
	var tools := _support_trades(obligations)        # tools for the essential trades come before optional spending (EQ-19)
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
	if tools > 0:
		w.note("The manor spent %d coins keeping the village's workers in tools." % tools)
	if taxed + bought + grain + relief > 0:
		w.note("The manor took %d coins in tax, bought %d loads for repairs and %d grain for the granary, and gave %d households food." % [taxed, bought, grain, relief])
	if works > 0:
		w.note("The manor bought %d loads of planks, iron and stone for its public works." % works)
	w.manor_work.refresh()


## OD-16 (b), EQ-19 (owner 2026-10-20: "the manor uses its treasury to keep the smithy and woodlands working: it buys
## iron and tools for the village's workers, or lends to the smith against future output"). Each evening, for every
## worker short of their trade's tool (tool_needers: a woodcutter without an axe, a miner without a pickaxe, a builder of
## the household's own home without an axe), in id order: a tool on sale at the goods merchant's or the smith's is
## bought from the treasury and handed to them; with none on sale, a smith is paid its worth in advance
## (World.manor_orders, at most `manor_orders_per_smith` open each), which buys the forge's ore and coal, and the tool
## goes to the worker when it is forged (_deliver_orders). The treasury keeps `manor_support_floor_days` of its
## obligations. Coins and tools only move. Returns the coins spent.
func _support_trades(obligations: float) -> int:
	_deliver_orders()
	var floor_coins := obligations * float(GameData.b("manor_support_floor_days"))
	var spent := 0
	for pair in tool_needers():
		var o: NPC = pair[0]
		var tool: String = pair[1]
		if not _order_for(o).is_empty():
			continue
		var seller: NPC = null
		for role in ["merchant_goods", "smith"]:
			for v: NPC in w.npcs:
				if seller == null and v.alive and ((v.job == "smith") if role == "smith" else (buy_role(v) == role)) and v.inv.has(tool) and not keeps(v, tool):
					seller = v
		if seller != null:
			var price := w.sell_price(seller, tool)
			if w.treasury - price < floor_coins:
				break
			seller.inv.remove(tool)
			o.inv.add(tool)
			seller.coins += price
			seller.earned += price
			w.treasury -= price
			spent += price
			w.stat("gov_tools", price)
			w.stat("gov_tool_given_" + tool)
			continue
		var smith: NPC = null
		for v: NPC in w.npcs:
			if v.alive and v.job == "smith" and w.manor_orders.filter(func(x): return int(x.smith) == v.id).size() < int(GameData.b("manor_orders_per_smith")) \
					and (smith == null or v.coins < smith.coins):
				smith = v
		if smith == null:
			continue
		var advance := int(ceil(GameData.value(tool)))
		if w.treasury - advance < floor_coins:
			break
		smith.coins += advance
		smith.earned += advance
		w.treasury -= advance
		spent += advance
		w.manor_orders.append({"smith": smith.id, "tool": tool, "for": o.id, "paid": advance, "day": w.day()})
		w.stat("gov_tools", advance)
		w.stat("gov_tool_advance_" + tool)
	return spent


## The workers short of a work tool, in id order: [worker, tool] (local_tool_need's people).
func tool_needers() -> Array:
	var out := []
	for o: NPC in w.npcs:
		if not o.alive or o.role != "adult":
			continue
		var tool: String = JOB_TOOL.get(o.job, "")
		if tool != "" and not o.inv.has(tool):
			out.append([o, tool])
		elif tool != "axe" and not o.inv.has("axe") and o.household >= 0 and str(w.households[o.household].get("build", "")) != "" \
				and w.construction.responsible_adult(o.household) == o:
			out.append([o, "axe"])
	return out


## The manor's open order for this worker's tool, or {}.
func _order_for(o: NPC) -> Dictionary:
	for x in w.manor_orders:
		if int(x["for"]) == o.id:
			return x
	return {}


## Tools forged on the manor's orders go to the worker they were paid for (or, if that worker no longer needs one,
## to the next worker short of that tool); an order whose smith has died or left the trade lapses.
func _deliver_orders() -> void:
	for x in w.manor_orders.duplicate():
		var smith := w.npc(int(x.smith))
		if smith == null or not smith.alive or smith.job != "smith":
			w.manor_orders.erase(x)
			w.stat("gov_tool_order_lapsed")
			continue
		var tool := str(x.tool)
		if not smith.inv.has(tool):
			continue
		var to: NPC = null
		var first := w.npc(int(x["for"]))
		if first != null and first.alive and not first.inv.has(tool):
			to = first
		else:
			for pair in tool_needers():
				if pair[1] == tool and _order_for(pair[0]).is_empty():
					to = pair[0]
					break
		if to == null:
			continue                                  # kept at the forge until a worker needs it
		smith.inv.remove(tool)
		to.inv.add(tool)
		w.manor_orders.erase(x)
		w.stat("gov_tool_delivered_" + tool)


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
			if not NPCBrain.FOOD.has(id) and not keeps(o, id) and _buyer_for(o, id) != null:
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
			var unemployed := n.job == "" or tool_short(n)
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
					var price := tool_price(n, opt.tool)     # the smith or the goods merchant sells tools (not the timber sellers)
					if price < 0 or n.coins < price:
						continue
					setup = price / 10.0
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
			var left := n.job
			var left_place := n.workplace
			_change_job(n, best, why)
			_post_left(n, left, left_place)


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
		"smith", "carpenter", "tanner", "cook", "tavernkeeper":
			n.workplace = place                      # the workstation of the trade (succession)
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


# ---------------------------------------------------------------- succession ----------------
## Essential trades are handed on (B8-016, owner 2026-10-19: "Apprentice, then newcomer"). A skilled
## trade (smith, carpenter, tanner, cook, tavernkeeper, merchant) is kept at the strength the village
## began with; of farmers, woodcutters and miners (whom the job market refills while any remain) at
## least one must work. When one dies, the post, its workstation and its home are open for
## `succession_days`; then an adult without a trade takes it (an apprentice: the dead worker's own
## household first), and with none a newcomer comes with the next caravan, at the latest
## `newcomer_max_days` after the death, bringing a purse of their own (counted as coming into the
## village, World.coin_sources) and lodging in the dead worker's household, house or another empty
## house. Death stays permanent: nobody is resurrected. World.vacancies is the saved list.
const SKILLED := ["smith", "carpenter", "tanner", "cook", "tavernkeeper", "merchant"]
const FLOOR_JOBS := ["farmer", "woodcutter", "miner"]
const APPRENTICE_FROM := ["", "manor_hand", "laborer"]          # the adults who can be taken on, in order of preference


## How many hold a trade when the village is whole: the starting count for a skilled trade, one for the rest.
static func staff_target(job: String) -> int:
	return int(Population.JOBS.get(job, 1)) if SKILLED.has(job) else 1


func is_essential(job: String) -> bool:
	return SKILLED.has(job) or FLOOR_JOBS.has(job)


func living_in(job: String) -> int:
	var c := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == job:
			c += 1
	return c


func open_posts(job: String) -> int:
	var c := 0
	for v in w.vacancies:
		if v.job == job:
			c += 1
	return c


## A death in an essential trade opens its post (called from on_death), unless the trade is still at
## strength or posts are already open for every missing hand.
func _open_vacancy(n: NPC) -> void:
	if n.role != "adult" or not is_essential(n.job):
		return
	# A retiring worker is still an adult in the trade when this runs: do not count them as staff.
	var staying := living_in(n.job) - (1 if n.alive else 0)
	if staying + open_posts(n.job) >= staff_target(n.job):
		return
	var heir := w._heir(n)                            # who inherited the master's tools (World._inherit)
	w.vacancies.append({"job": n.job, "workplace": n.workplace, "home": n.home, "household": n.household, "day": w.day(),
			"who": "%s %s" % [n.name, n.family], "heir": heir.id if heir != null else -1})
	w.note("The post of %s, left by %s, is open: an apprentice or a newcomer will take it." % [n.job.replace("_", " "), "%s %s" % [n.name, n.family]])


## An essential trade left for other work (seek_work) is handed on as after a death: its post opens when
## the trade falls below strength, so the forge or the woodland is not left empty for good (EQ-07).
func _post_left(n: NPC, job: String, place: String) -> void:
	if job == "" or not is_essential(job) or living_in(job) + open_posts(job) >= staff_target(job):
		return
	w.vacancies.append({"job": job, "workplace": place, "home": n.home, "household": n.household,
			"day": w.day(), "who": "%s %s" % [n.name, n.family], "heir": n.id, "left_by": n.id})
	w.stat("posts_left_" + job)
	w.note("%s %s leaves the post of %s: an apprentice or a newcomer will take it." % [n.name, n.family, job.replace("_", " ")])


## Every morning: posts open for succession_days are filled by an apprentice; one nobody can fill waits
## for the caravan, and after newcomer_max_days a newcomer comes without it.
func succession_dawn() -> void:
	var wait := int(GameData.b("succession_days"))
	var latest := int(GameData.b("newcomer_max_days"))
	for v in w.vacancies.duplicate():
		var age: int = w.day() - int(v.day)
		if age < wait:
			continue
		if living_in(v.job) >= staff_target(v.job):
			w.vacancies.erase(v)                     # filled some other way (a stall let again)
			continue
		var a := _apprentice_for(v)
		if a != null:
			w.vacancies.erase(v)
			_install(a, v, "apprenticed to the late %s" % v.who)
		elif age >= latest:
			w.vacancies.erase(v)
			_newcomer_for(v)


## The caravan brings newcomers for posts nobody could take (called from caravan()).
func succession_caravan() -> void:
	var wait := int(GameData.b("succession_days"))
	for v in w.vacancies.duplicate():
		if w.day() - int(v.day) < wait:
			continue
		if living_in(v.job) >= staff_target(v.job):
			w.vacancies.erase(v)
			continue
		var a := _apprentice_for(v)
		w.vacancies.erase(v)
		if a != null:
			_install(a, v, "apprenticed to the late %s" % v.who)
		else:
			_newcomer_for(v)


## An adult without a trade (or a labourer or manor hand), the dead worker's household first, then by
## id; a merchant also needs the coins to stock a stall. null if there is none. (B8-029: children now grow up
## at 16 and become adults without a trade, so they are in this pool; adolescents of 12-16 are not: adults only.)
func _apprentice_for(v: Dictionary) -> NPC:
	var best: NPC = null
	var best_key := 1 << 30
	for o: NPC in w.npcs:
		if not o.alive or o.role != "adult" or not APPRENTICE_FROM.has(o.job) or o.id == int(v.get("left_by", -1)):
			continue                                   # (not the worker who just left the trade)
		if v.job == "merchant" and o.coins < int(GameData.b("stall_min_coins")):
			continue
		var key := APPRENTICE_FROM.find(o.job) * 100000 + (0 if (int(v.household) >= 0 and o.household == int(v.household)) else 50000) + o.id
		if key < best_key:
			best_key = key
			best = o
	return best


## Put someone in the post: the job, the workstation (or stall) and, with the trade's tool, the tools.
func _install(n: NPC, v: Dictionary, why: String) -> void:
	var place := str(v.workplace)
	if v.job == "merchant":
		var t := w.tenant_of(w.stalls[place]) if w.stalls.has(place) else "x"
		if t != "" and w.party(t) != null and w.party(t).alive:
			place = ""                                # the stall was let again meanwhile: another one that is vacant
			for sid in _sorted_keys(w.stalls):
				if w.tenant_of(w.stalls[sid]) == "":
					place = str(sid)
					break
		if place == "":
			return
	_change_job(n, str(v.job), why, place)
	for tool in KEEPS.get(v.job, []):
		if n.inv.has(tool) or GameData.item(tool).get("tool", "") == "":
			continue
		var from := _late_masters_tool(v, tool, n)
		if from != null:
			from.inv.remove(tool)                    # the master's tools pass on from whoever inherited them
			n.inv.add(tool)
			w.stat("succession_tool_passed")
		elif why == "a newcomer":
			n.inv.add(tool)                          # a newcomer brings the tools of their trade (EQ-10)
			w.stat("imported_" + tool)
		# an apprentice with no tool to take over buys one (tool_short) or works without
	w.stat("successions")
	w.stat("succession_" + str(v.job))


## Who holds the late master's tool and does not need it: the heir (World._inherit), else someone of
## the master's household (lowest id, so the choice is deterministic). null when the tool is gone.
func _late_masters_tool(v: Dictionary, tool: String, taker: NPC) -> NPC:
	var spare := func(o: NPC) -> bool:
		return o != null and o.alive and o != taker and o.inv.has(tool) and not keeps(o, tool)
	var heir := w.npc(int(v.get("heir", -1)))
	if spare.call(heir):
		return heir
	if int(v.get("household", -1)) < 0:
		return null
	for o: NPC in w.npcs:
		if o.household == int(v.household) and spare.call(o):
			return o
	return null


func _sorted_keys(d: Dictionary) -> Array:
	var k := d.keys()
	k.sort()
	return k


func _next_npc_id() -> int:
	var top := 0
	for o: NPC in w.npcs:
		top = maxi(top, o.id)
	return top + 1


## A newcomer takes the post, the workstation and a home: with the dead worker's household if it lives
## (a lodger in its house), else its old house leased from the manor, else another empty house, else a
## room with the smallest household. Their purse is new money from outside (coin_sources).
func _newcomer_for(v: Dictionary) -> NPC:
	var n := NPC.new()
	n.id = _next_npc_id()
	n.role = "adult"
	n.name = Population.FIRST[w.rng.randi() % Population.FIRST.size()]
	n.family = Population.FAMILY[w.rng.randi() % Population.FAMILY.size()]
	n.sex = Life.sex_of_name(n.name)                 # B8-029: a grown newcomer, no kin here
	n.born = Life.born_for_age(w.rng.randf_range(20.0, 45.0), w.minutes)
	n.sprite = "res://assets/characters/villager_%02d.png" % (n.id % 48)
	n.coins = int(GameData.b("newcomer_coins"))
	n.hunger = 100.0
	w.coin_sources += n.coins                        # the purse comes in from outside
	w.stat("newcomer_coins_in", n.coins)
	w.npcs.append(n)
	w.by_id[n.id] = n
	var h := int(v.household)
	if h >= 0 and h < w.households.size() and not w.households[h].get("ended", false) and not _members(h).is_empty() \
			and w.buildings.has(str(w.households[h].home)):
		_lodge(n, h)                                 # with the dead worker's family
	else:
		var nh := {"id": w.households.size(), "family": n.family, "home": "", "members": [n.id], "pantry": Inventory.new(), "founded_day": w.day()}
		w.households.append(nh)
		n.household = int(nh.id)
		var homes := []
		if w.buildings.has(str(v.home)):
			homes.append(str(v.home))
		var ids: Array = w.buildings.keys()
		ids.sort()
		for id in ids:
			if not homes.has(id):
				homes.append(id)
		for id in homes:
			var b: Dictionary = w.buildings[id]
			if w.property.is_home(b) and w.property.for_sale(b) and n.coins >= w.property.rent_of(b):
				if w.property.lease(b, World.hh_ref(int(nh.id))) == "":
					nh.home = id
					n.home = id
					break
		if str(nh.home) == "":
			var host := -1                           # no house to lease: a room with the smallest household
			for hh in w.households:
				if hh.get("ended", false) or int(hh.id) == int(nh.id) or not w.buildings.has(str(hh.home)) or _members(int(hh.id)).is_empty():
					continue
				if host < 0 or _members(int(hh.id)).size() < _members(host).size():
					host = int(hh.id)
			w.households.erase(nh)
			_lodge(n, host)
	n.pos = Vector2(w.building_door(n.home)) + Vector2(0.5, 0.5)
	w.note("%s %s arrives with the caravan to take the late %s's post as %s." % [n.name, n.family, v.who, str(v.job).replace("_", " ")])
	_install(n, v, "a newcomer")
	return n


## Join a household as a lodger: its family name, its house.
func _lodge(n: NPC, h: int) -> void:
	n.household = h
	n.family = str(w.households[h].family)
	n.home = str(w.households[h].home)
	w.households[h].members.append(n.id)


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
		succession_dawn()
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
	succession_caravan()                             # newcomers for the posts nobody could take (B8-016)
	var every := maxi(1, int(GameData.b("caravan_every_days")))
	var float_coins := int(GameData.b("caravan_float"))
	if w.caravan_purse < float_coins:
		# the region's demand tops the purse up, less and less as the village's coins near their ceiling
		var ceiling := float(GameData.b("caravan_ceiling_per_head")) * float(w.alive_count() - w.alive_count("bandit"))
		var room := clampf(1.0 - float(w.total_coins()) / maxf(1.0, ceiling), 0.0, 1.0)
		w.caravan_purse = mini(float_coins, w.caravan_purse + roundi(float(GameData.b("caravan_allowance")) * every * room))
	var sold := _caravan_imports()
	var stone := _caravan_stone()
	_caravan_apothecary()
	_caravan_seeds()
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
	# tools the village's own people need are not sold away (EQ-07, "economic recovery from missing work
	# tools"): as many as there are workers short of one, and builders without an axe, stay for sale here
	var tool_need := local_tool_need()
	var tool_stock := {}
	for o: NPC in w.npcs:
		if o.alive and (o.job == "smith" or buy_role(o) == "merchant_goods"):
			for t in tool_need:
				if not keeps(o, t):
					tool_stock[t] = int(tool_stock.get(t, 0)) + o.inv.count(t)
	var lines := []                # [seller, item, units for sale]
	# OD-16 (c), EQ-21 (owner 2026-10-20: "the caravan buys more of what the village over-produces (meat, hides)"): from
	# the producers too, what they hold beyond `caravan_producer_keep` (hunters' meat, hides and pelts, tanners' leather)
	var keep_of: Dictionary = GameData.b("caravan_producer_keep")
	for o: NPC in w.npcs:
		if not o.alive or not o.job in ["hunter", "tanner"]:
			continue
		for id in keep_of:
			if (o.job == "tanner" and id != "leather") or (keep_food and id == "meat"):
				continue
			var extra := o.inv.count(id) - int(keep_of[id])
			if extra > 0:
				lines.append([o, id, extra])
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
				if tool_need.has(id) and int(tool_stock.get(id, 0)) <= int(tool_need[id]):
					line[2] = 0                              # kept for a villager who needs it
					w.stat("caravan_tool_kept_" + id)
					continue
				tool_stock[id] = int(tool_stock.get(id, 0)) - 1
				line[2] = int(line[2]) - 1
				o.inv.remove(id)
				w.stat("exported_" + id)
				o.coins += price
				o.earned += price
				budget -= price
				w.caravan_purse -= price
				w.coin_sources += price
				w.stat("caravan_coins_in", price)
				w.stat("caravan_in_" + (buy_role(o) if buy_role(o) != "" else o.job), price)
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


## The caravan's medicines (PL1-04): each visit it sells the sage up to caravan_apothecary_per_visit
## pieces, the scarcest first, towards caravan_apothecary_stock, at base value from the sage's own coins
## (above the trader cash floor). Finite: it stops when the sage cannot pay.
func _caravan_apothecary() -> int:
	var sage := w.npc(w.sage_id)
	if sage == null or not sage.alive:
		return 0
	var stock: Dictionary = GameData.b("caravan_apothecary_stock")
	var spent := 0
	for k in int(GameData.b("caravan_apothecary_per_visit")):
		var pick := ""
		var worst := 1.0
		for id in stock:
			var fill := float(sage.inv.count(id)) / float(stock[id])
			if fill < worst and sage.coins - GameData.value(id) >= int(GameData.b("trader_cash_floor")):
				worst = fill
				pick = id
		if pick == "":
			break
		var price := GameData.value(pick)
		sage.coins -= price
		sage.spent += price
		sage.inv.add(pick)
		w.coin_sources -= price
		w.caravan_purse += price
		w.stat("caravan_coins_out", price)
		w.stat("imported_" + pick)
		spent += price
	return spent


## The caravan's seed (Build 13 economy rule 3): each visit it sells the food merchant up to
## caravan_seed_per_visit seeds, the scarcest first, towards caravan_seed_stock, at seed value from the
## merchant's own coins above the trader cash floor. Finite like the apothecary's resupply.
func _caravan_seeds() -> int:
	var cfg: Dictionary = GameData.b("farming")
	var stock: Dictionary = cfg.caravan_seed_stock
	var spent := 0
	for o: NPC in w.npcs:
		if not o.alive or o.job != "merchant" or not w.farm.sells_seed(o):
			continue
		for k in int(cfg.caravan_seed_per_visit):
			var pick := ""
			var worst := 1.0
			for id in stock:
				var fill := float(o.inv.count(id)) / float(stock[id])
				if fill < worst and o.coins - GameData.value(id) >= int(GameData.b("trader_cash_floor")) and o.inv.can_add(id):
					worst = fill
					pick = id
			if pick == "":
				break
			var price := GameData.value(pick)
			o.coins -= price
			o.spent += price
			o.inv.add(pick)
			w.coin_sources -= price
			w.caravan_purse += price
			w.stat("caravan_coins_out", price)
			w.stat("imported_" + pick)
			spent += price
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
