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
	"carpenter": {"log": 30, "shovel_blade": 1},      # MIN-SHOVEL: one smith's blade on hand for a shovel to order
	"tanner": {"hide": 15, "rabbit_pelt": 15, "wool": 12},          # wool: woven into cloth (Build 13)
	"sage": {"flower": 20, "linen_bandage": 8, "ale": 2},   # flowers for poultices and tonics (PL1-04); bandages the tanner sews (Build 13); ale for the strong tonic (PAR-04)
	"cook": {"wheat": 60, "meat": 15, "log": 10, "egg": 20, "milk": 12, "cheese": 10, "carrot": 20, "potato": 20},    # the last five: the player's farm goods (PL2-015)
	"tavernkeeper": {"pottage": 60, "roast_meat": 20, "ale": 20, "bread": 12, "cheese": 8},    # bread and cheese: the tavern's suppers (Build 13)
	"stonecutter": {"stone": 12},      # X18-STONECUT: raw stone to dress, bought with its own coins; only while it holds a mallet and an iron chisel (batch_unit)
	"merchant_raw": {"iron_ore": 20, "copper_ore": 15, "coal": 20, "stone": 40, "rubble": 20, "log": 20, "plank": 20,
		"building_block": 20},        # STONE-01: dressed blocks kept for builders, as the stone was
	"merchant_food": {"pottage": 20, "roast_meat": 10, "ale": 15, "wheat": 20, "meat": 10,
		"egg": 20, "milk": 10, "cheese": 10, "carrot": 20, "potato": 20, "bread": 15,
		"red_berries": 15, "blueberries": 15, "apple": 15,    # households' gathered berries and apples, brought to market (B14)
		"flower_seed": 4, "red_berry_cutting": 4, "blue_berry_cutting": 4},   # MERCH-01: households' saved planting material, sold on as seed
	"merchant_goods": {"pickaxe": 4, "axe": 4, "hammer": 2, "copper_sword": 3, "iron_sword": 3,
		"leather_armor": 2, "iron_armor": 2, "leather": 6, "hide": 6, "rabbit_pelt": 6, "feather": 20, "wool": 20, "wool_cloth": 10, "iron_bar": 6, "copper_bar": 6, "gold_bar": 4,
		# crafted gear that had no buyer (B7-003, owner 2026-10-18): the goods merchant takes a few,
		# like the other made goods, and the caravan carries the surplus away
		"copper_ring": 3, "gold_ring": 2, "amulet": 2, "leather_cap": 3, "iron_helmet": 2, "plough": 2,     # plough: PAR-04
		"herbal_poultice": 8,                      # households' home-brewed poultices, brought to market (B14)
		"nails": 24, "mallet": 2, "chisel": 2,     # STONE-06: the smith's iron chisels, forged to order for the dressers; B14-07: the stuff of wooden stairs and walkways, forged and made to order (PAR-04)
		"shovel": 2},                              # MIN-SHOVEL (owner MIN-E-Q4): diggers' shovels, assembled to order
}
# SHOP-01 (owner, 2026-10-20 section 6): the stations each producing trade works at. Their recipes (recipes.json) are
# what its purchases of their inputs are for: it buys an input only for a recipe it has the skill for, up to its want
# (batch_unit, wants). Goods in BUYS that no recipe of the trade consumes are stock it holds for sale or use.
const TRADE_STATIONS := {"smith": ["forge", "anvil"], "carpenter": ["sawhorse", "workbench"], "tanner": ["workbench"], "stonecutter": ["workbench"],
	"sage": ["stove"], "cook": ["stove", "prep", "oven"]}
# items an NPC keeps for its own work and will not sell
const KEEPS := {"sage": ["flower"], "miner": ["pickaxe", "shovel"], "prospector": ["prospecting_kit"], "laborer": ["pickaxe", "shovel", "mallet", "chisel"], "stonecutter": ["mallet", "chisel"], "woodcutter": ["axe"], "smith": ["hammer"],
	# seed is sold only through the seed offer (Farming.buy_seed, Build 13)
	"farmer": ["wheat_seed", "carrot_seed", "potato_seed", "herb_seed"], "merchant": ["wheat_seed", "carrot_seed", "potato_seed", "herb_seed", "flower_seed", "red_berry_cutting", "blue_berry_cutting"],
	"guard": ["iron_sword", "leather_armor"], "bandit": ["copper_sword"]}
# who to sell each item to, in order of preference
const OUTLETS := {
	"iron_ore": ["smith", "merchant_raw"], "copper_ore": ["smith", "merchant_raw"], "gold_ore": ["smith", "merchant_goods"],
	"coal": ["smith", "merchant_raw"], "stone": ["merchant_raw"], "rubble": ["merchant_raw"], "building_block": ["merchant_raw"], "log": ["carpenter", "cook", "merchant_raw"],
	"plank": ["smith", "merchant_raw"], "wheat": ["cook", "merchant_food"], "meat": ["cook", "merchant_food"],
	"hide": ["tanner", "merchant_goods"], "rabbit_pelt": ["tanner", "merchant_goods"], "feather": ["merchant_goods"], "leather": ["smith", "merchant_goods"],
	"pottage": ["tavernkeeper", "merchant_food"], "roast_meat": ["tavernkeeper", "merchant_food"], "ale": ["tavernkeeper", "merchant_food", "sage"],
	"flower": ["sage"],                       # FSE-B07: the Apothecary buys foragers' flowers (BUYS.sage)
	"egg": ["cook", "merchant_food"], "milk": ["cook", "merchant_food"], "cheese": ["tavernkeeper", "cook", "merchant_food"],
	"carrot": ["cook", "merchant_food"], "potato": ["cook", "merchant_food"], "wool": ["tanner", "merchant_goods"], "wool_cloth": ["merchant_goods"],
	"bread": ["tavernkeeper", "merchant_food"], "linen_bandage": ["sage"],
	"red_berries": ["merchant_food"], "blueberries": ["merchant_food"], "apple": ["merchant_food"], "herbal_poultice": ["merchant_goods"],
	# MERCH-01: the seed seller (the food stall) buys households' surplus cuttings and flower seed
	"flower_seed": ["merchant_food"], "red_berry_cutting": ["merchant_food"], "blue_berry_cutting": ["merchant_food"],
	"pickaxe": ["merchant_goods"], "axe": ["merchant_goods"], "iron_sword": ["merchant_goods"], "copper_sword": ["merchant_goods"],
	"hammer": ["merchant_goods"], "iron_bar": ["merchant_goods"], "leather_armor": ["merchant_goods"],
	# PAR-04 (owner OD-18.4): the made goods only the player used to make, and where their makers sell them
	"copper_ring": ["merchant_goods"], "gold_ring": ["merchant_goods"], "amulet": ["merchant_goods"], "iron_helmet": ["merchant_goods"],
	"leather_cap": ["merchant_goods"], "gold_bar": ["merchant_goods"], "plough": ["merchant_goods"],
	"nails": ["merchant_goods"], "mallet": ["merchant_goods"], "chisel": ["merchant_goods"],     # STONE-06; B14-07: the smith's nails, the carpenter's mallets
	"shovel": ["merchant_goods"], "shovel_blade": ["carpenter"],   # MIN-SHOVEL: the carpenter's shovels, the smith's blades for them
}
const FOOD := ["roast_meat", "pottage", "wheat", "ale", "cheese", "bread", "red_berries", "blueberries", "apple"]
const COOKED := ["roast_meat", "pottage", "ale", "cheese", "bread"]     # cheese and egg bread: the cook's, from the pens (Build 13)
# What a villager eats as it is, as the player does (World.player_eat; owner directive 2026-10-20, FSE-00 section 1: the
# same rules for food for everyone): FOOD and the pens' and gardens' raw produce. (B7-015: a keeper starved holding 318 eggs.)
const EDIBLE := ["roast_meat", "pottage", "wheat", "ale", "cheese", "bread", "red_berries", "blueberries", "apple", "egg", "milk", "carrot", "potato"]
# the mine's raw output: finite, and the forge's and the builders' own input. The caravan sells it to
# the village (when the seams are worked out) but does not carry the village's away (B7-007)
const NOT_EXPORTED := ["iron_ore", "copper_ore", "gold_ore", "coal", "stone", "rubble", "building_block"]     # STONE-01: blocks are the village's stone, dressed

var w: World
var noted := {}          # one-off notes already written
## Diagnostics only (tests/economy_sim.gd): when on, every missed meal is logged as
## [day, hour, job or role, why, coins of the richest in the household]. Never read by the game.
var track_misses := false
var miss_log: Array = []
var _roles := {}         # trading role -> its villagers (_with_buy_role)
var _roles_key := []
var _consumers := {}     # "job/item" -> the recipes of the job's stations that consume the item (batch_unit)


func _init(world: World) -> void:
	w = world


# ---------------------------------------------------------------- plan helpers ---------------
## A walk to cell `c` on `level` (MIN-A: World._walk routes it through a portal when the walker is on another level;
## the key is left out on the surface, so surface plans are as they were).
func go(c: Vector2i, speed := 1.0, level := 0) -> Dictionary:
	if level != 0:
		return {"k": "go", "to": c, "speed": speed, "level": level}
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
		"prospect":
			return ["swing", "hammer"]
		"chop":
			return ["swing", "axe"]
		"mj_step":
			if str(w.manor_work.job(int(s.get("args", {}).get("job", -1))).get("kind", "")) == "excavate":
				return ["swing", "pickaxe"]            # MIN-E: the manor's open pit is dug with a pickaxe
			return ["swing", "hammer"]
		"svc_step":                                    # CON-02: digging a pit with a pickaxe, sampling with the kit's hammer
			var sc: Dictionary = w.contracts.get_contract(int(s.get("args", {}).get("id", -1)))
			return ["swing", "pickaxe" if str(sc.get("service", "")) == "dig" else "hammer"]
		"hunt", "slaughter":
			return ["swing", "rusty_sword"]
		"harvest", "sow", "feed_pen", "fp_work":
			return ["gather", ""]
		"craft":
			var st: String = str(w.stations[s.args.station].type) if w.stations.has(s.args.get("station", "")) else ""
			if st in ["anvil", "forge", "workbench", "sawhorse"]:
				return ["swing", "hammer"]
			return ["gather", ""]
	return [str(s.get("anim", "work")), ""]


## REC-F1: a standing wait, the only step of its plan. World._run_plan loads a work step's minutes (`work_left`) only
## when a walk ends or an act finishes before it; a plan that BEGINS with a work step inherited the previous step's
## spent (<= 0) count and ended on the next tick, so decide() ran again every tick (hundreds of times a day for a
## producer holding unsold goods). This loads the wait's own minutes, so the wait lasts as long as the plan says.
func wait(n: NPC, minutes: float) -> Dictionary:
	n.work_left = minutes
	return work(minutes, "", {}, "idle")


## A work step that opens a plan (no walk before it): World._run_plan loads a step's minutes only after a walk or an
## act, so an opening step must load its own or it inherits the last step's spent count and ends at once (REC-F1,
## SIM-F9: eating, medicine and a homeless villager's bed). The step keeps its own stated minutes.
func first(n: NPC, step: Dictionary) -> Dictionary:
	n.work_left = float(step.min)
	return step


func doit(act: String, args := {}) -> Dictionary:
	return {"k": "do", "act": act, "args": args}


func beside(c: Vector2i, from: Vector2i, level := 0) -> Vector2i:
	var best := c
	var bd := 1e9
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
		var n: Vector2i = c + d
		if not (w.map.is_solid(n) if level == 0 else w.underground.is_solid(level, n)):      # MIN-A: on the seam's own level
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
## REC-F1 diagnostics only (read by tests/recf1_measure.gd, never by behaviour): top-level decisions per villager id, and
## performed actions by kind.
var decide_calls := {}
var act_calls := {}


func decide(n: NPC) -> void:
	decide_calls[n.id] = int(decide_calls.get(n.id, 0)) + 1
	var rec = w.recorder
	if rec == null:
		_decide(n)
		return
	var pre: Dictionary = rec.decide_begin(n)          # REC-19: a read-only record of the decision (never changes the choice)
	rec.decide_end(pre, n, _decide(n))


## The priority chain: the first branch that makes a plan wins. Returns the winning branch's id (game/data/recorder_codes.json
## "decision_chain" lists them in this order); the return value is read only by the flight recorder.
func _decide(n: NPC) -> String:
	var h := w.hour()
	if n.anim == "sleep" or n.anim == "sit":
		n.anim = "idle"                    # up from bed, or from the chair (PL1-07)
	if n.role == "bandit":
		_bandit(n, h)
		return "bandit"
	if n.clan == "bandit":
		_clan_child(n, h)
		return "clan_child"
	if not n.report.is_empty() and _report(n):
		return "report"
	if JudgmentLive.on(w, JudgmentFamily.FLAG) and JudgmentFamily.danger(w, n):      # FAMILY-01: shield the family, fetch help
		return "family_danger"
	if n.hunger < float(GameData.b("eat_below")) and _plan_eat(n):
		return "eat"
	if (h >= WAKE and h < SLEEP) and _plan_rest_hurt(n):
		return "rest_hurt"
	if n.job == "guard":
		_guard(n, h)
		return "guard"
	if h >= SLEEP or h < WAKE:
		_plan_sleep(n)
		return "sleep"
	if w.feast.plan_attend(n):                 # DVW-B3-FEAST: an invited guest goes to the tavern in the evening
		return "feast"
	if n.role == "child":
		var spot := w.building_door(n.home) if w.rng.randf() < 0.6 else Vector2i(w.map.data.spawns.player[0], w.map.data.spawns.player[1])
		n.doing = "playing"
		n.plan = [go(wander_cell(spot, 6), 0.9), work(w.rng.randf_range(20, 60), "", {}, "idle")]
		return "child_play"
	if n.role == "elder":
		if w.farm_plots.plan_work(n):          # FARM-04: an elder's light work on the family's farmland, by day
			return "elder_farm"
		if w.chapel.plan_volunteer(n):         # DVW-B3-CHAPEL: or on the church's plot, when they volunteered
			return "elder_chapel"
		var spot := w.building_door(n.home) if w.rng.randf() < 0.7 else w.station_use(w.stations_of("well")[0])
		n.doing = "taking the air"
		n.plan = [go(wander_cell(spot, 3), 0.6), work(w.rng.randf_range(40, 90), "", {}, "idle")]
		return "elder_air"
	# hired to carry building materials (or carrying for their own new house): the day's work
	if h >= WORK_START and h < WORK_END and w.construction.plan_helper(n):
		return "construction_helper"
	# minding the player's stall or shop (PL1-10 stage 4)
	if h >= WORK_START and h < WORK_END and w.business.plan_attendant(n):
		return "stall_attendant"
	# a job taken for the manor is carried on to the end (ManorWork)
	if h >= WORK_START and h < WORK_END and w.manor_work.plan(n):
		return "manor_work"
	# a contract it accepted is worked on and delivered (CON-01, Contracts.plan)
	if h >= WORK_START and h < WORK_END and w.contracts.plan(n):
		return "contract"
	if h >= WORK_START and h < WORK_END and n.job != "":
		if h < 12.0 and _day_labour(n):
			return "day_labour"
		if _plan_job(n):
			return "job"
	_plan_evening(n, h)
	return "evening"


func _plan_sleep(n: NPC) -> void:
	n.doing = "going home to sleep"
	var until := WAKE + 24.0 if w.hour() >= SLEEP else WAKE
	var mins := (until - w.hour()) * 60.0
	_plan_bed(n, maxf(mins, 10.0), true)


## Go home through the door to one's own bed (World.home_spot) and lie in it for `mins` game minutes. A home without a
## bed or pallet: the door step, standing; with no home, rest where one stands. The rest ends in rest_end: a rest to the morning (`to_morning`) or of rest.day_minutes
## restores health as the player's does (World.rest_recover, PAR-03).
func _plan_bed(n: NPC, mins: float, to_morning := false) -> void:
	var done := work(mins, "rest_end", {"min": mins, "morning": to_morning}, "sleep")
	if n.home == "":
		done.anim = "idle"
		n.plan = [first(n, done)]
		return
	if w.home_spot(n, "bed").is_empty():
		done.anim = "idle"
		n.plan = [go(w.building_door(n.home)), doit("enter"), done]
		return
	n.plan = [go(w.home_cell(n, "bed")), doit("enter"), done]


## PAR-03: a villager badly hurt (below rest.seek_below of their health) dresses the wound if a medicine is to hand
## (_plan_heal), else goes home to rest for rest.day_minutes, as the player rests. True when planned.
func _plan_rest_hurt(n: NPC) -> bool:
	if n.hp >= n.max_hp * float(GameData.b("rest").seek_below):
		return false
	if _plan_heal(n):
		return true
	n.doing = "resting a wound"
	_plan_bed(n, float(GameData.b("rest").day_minutes))
	return true


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
			n.plan = [first(n, work(10, "use_medicine", {}, "idle"))]
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


## MERCH-01: a farmer whose household holds less than seed_keep wheat seed (their pack and the pantry) buys the
## shortfall from a seed seller's stock (the food stall's merchant) with their own coins, by the player's rule
## (Farming.buy_seed_item) and within the household's reserve (OD-19).
func _plan_buy_seed(n: NPC) -> bool:
	if n.job != "farmer" or n.household < 0:
		return false
	var seed := str(Farming.crops().wheat.seed)
	var have := n.inv.count(seed) + (w.households[n.household].pantry as Inventory).count(seed)
	var short := int(Farming.seed_cfg().seed_keep) - have
	if short <= 0:
		return false
	for o: NPC in w.npcs:
		if o == n or o.job != "merchant" or not w.farm.sells_seed(o) or w.asleep(o) or not o.inv.has(seed):
			continue
		var qty := mini(short, o.inv.count(seed))
		if not w.can_afford(n, w.farm.seed_item_price(seed, n) * qty):
			return false
		n.doing = "buying seed"
		n.plan = [go(_workplace_cell(o)), doit("buy_seed", {"vendor": o.id, "item": seed, "qty": qty})]
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
	if _plan_market_run(n, house) or _plan_storefront(n, house) or w.business.stalls.plan_npc(n, house) or _plan_cart(n, house):     # stalls: STALL-06
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
const FRONT_WARES := ["herbal_poultice", "red_berries", "blueberries", "apple", "flower_seed", "red_berry_cutting", "blue_berry_cutting"]


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
	var keep_cut := int(GameData.b("propagation").household_keep)     # SEED-04: planting material kept, the rest sold
	for id in Farming.propagule_items():
		if pantry.count(id) > keep_cut:
			out[id] = pantry.count(id) - keep_cut
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


## PAR-04 (owner OD-18.4): the carpenter makes a plough at the workbench when the goods merchant wants one, buying the
## two iron bars it needs with its own coins (from whoever holds them).
func _carpenter_goods(n: NPC) -> bool:
	if n.inv.count("plough") > 0:
		return _plan_sell(n, "plough") if _buyer_for(n, "plough") != null else false
	if _buyer_for(n, "plough") == null or not _can_make(n, "craft_plough"):
		return false
	var rec: Dictionary = GameData.recipes["craft_plough"]
	if n.inv.has_all(rec["in"]) and _do_recipe(n, "craft_plough"):
		n.doing = "making a plough"
		return true
	if n.inv.count("plank") >= int(rec["in"].plank):
		var plan := _parts_trip(n, {"iron_bar": rec["in"].iron_bar}, n.coins / 2)
		if not plan.is_empty():
			n.doing = "buying iron for a plough"
			n.plan = plan
			return true
	return false


## B14-07, PAR-04: the carpenter makes a mallet (make_mallet: a log and a plank at the workbench) only for a buyer who wants
## one, and sells what it has made to that buyer; with no buyer, or without the skill or the wood, it goes on with its
## other work (false).
func _carpenter_mallet(n: NPC) -> bool:
	if n.inv.count("mallet") > 0 and not keeps(n, "mallet"):   # (one made for the manor's order is not for sale: MIN-EQUIP)
		return _plan_sell(n, "mallet") if _buyer_for(n, "mallet") != null else false
	if not _can_make(n, "make_mallet") or not n.inv.has_all(GameData.recipes["make_mallet"]["in"]):
		return false
	if _buyer_for(n, "mallet") == null:
		return false
	if _do_recipe(n, "make_mallet"):
		n.doing = "making a mallet"
		return true
	return false


## MIN-SHOVEL (owner MIN-E-Q4, 2026-10-21): the carpenter makes a shovel only for a buyer who wants one (the goods
## merchant's stock, as mallets): a haft from a plank at the workbench (make_shovel_haft), fitted with the iron blade the
## smith forges and sells it (forge_shovel_blade; the carpenter keeps one on hand, BUYS), assembled at the workbench
## (assemble_shovel), and sold to that buyer. Without a buyer, the skill, the plank or the blade it goes on with its other
## work (false). Nothing is made from nothing: every part is a recipe's, every sale a purchase.
func _carpenter_shovel(n: NPC) -> bool:
	if n.inv.count("shovel") > 0:
		return _plan_sell(n, "shovel") if _buyer_for(n, "shovel") != null else false
	if _buyer_for(n, "shovel") == null or not _can_make(n, "assemble_shovel"):
		return false
	if n.inv.has_all(GameData.recipes["assemble_shovel"]["in"]) and _do_recipe(n, "assemble_shovel"):
		n.doing = "making a shovel"
		return true
	if n.inv.count("shovel_haft") < 1 and _can_make(n, "make_shovel_haft") and n.inv.has_all(GameData.recipes["make_shovel_haft"]["in"]) \
			and _do_recipe(n, "make_shovel_haft"):
		n.doing = "making a shovel haft"
		return true
	return false


## STONE-01 (owner decision 2026-10-21: "Quarry extraction → Raw stone → Stoneworking → Finished building blocks →
## Construction"): the labourer is the village's stoneworker. While building blocks are wanted (the raw-goods merchant
## buys them for builders, or open sites need more than anyone has on sale) a labourer with a mallet dresses the raw
## stone they hold into blocks at a workbench (dress_stone, the player's recipe: two stone, half an hour, Masonry 1)
## and sells them on; without a mallet they buy one (the goods merchant's, made by the carpenter); without stone in
## hand they quarry it as before (false: _miner), or, when no stone is left to quarry or the merchant has all the stone
## it will take, buy the merchant's (quarried stone, or the caravan's). Nothing is dressed for nobody: with no demand, false and the day goes on as before.
func _mason(n: NPC) -> bool:
	if n.role != "adult":
		return false
	if n.inv.count("building_block") > 0 and _buyer_for(n, "building_block") != null:
		return _plan_sell(n, "building_block")
	if not _block_demand(n):
		return false
	var rec: Dictionary = GameData.recipes["dress_stone"]
	if n.level(str(rec.skill)) < int(rec.level):
		return false
	var miss := w.craft_tool_missing(n, "dress_stone")
	if miss != "":
		return _fetch_dress_tool(n, miss)
	if n.inv.has_all(rec["in"]):
		if _do_recipe(n, "dress_stone"):
			n.doing = "dressing stone into building blocks"
			return true
		return false
	if n.job == "laborer" and _buyer_for(n, "stone") != null and not w.nearest_seam(n, ["stone"]).is_empty():
		return false                                    # quarry it (_miner: a labourer quarries stone while it sells)
	return _fetch_dress_stone(n)


## STONE-01, STONE-06: a trip to buy the dressing tool `kind` (the mallet: the carpenter's, the iron chisel: the smith's,
## either from the goods merchant) with the villager's own coins above their reserve; false when none is for sale.
func _fetch_dress_tool(n: NPC, kind: String) -> bool:
	var maker := "smith" if kind == "chisel" else "carpenter"
	for o: NPC in w.npcs:
		if o.alive and o != n and not w.asleep(o) and (o.job == maker or buy_role(o) == "merchant_goods") \
				and o.inv.has(kind) and not keeps(o, kind) and n.coins - w.reserve_of(n) >= w.sell_price(o, kind):
			n.doing = "buying %s to dress stone" % ("an iron chisel" if kind == "chisel" else "a " + kind)
			n.plan = [go(_workplace_cell(o)), doit("buy_from", {"vendor": o.id, "item": kind, "qty": 1})]
			return true
	return false


## STONE-01: a trip to buy the stone one batch of dressing is short of from the raw-goods merchant (or a labourer's), with
## the villager's own coins above their reserve; false when none is for sale or they cannot pay.
func _fetch_dress_stone(n: NPC) -> bool:
	var short := int(GameData.recipes["dress_stone"]["in"]["stone"]) - n.inv.count("stone")
	for v: NPC in _with_buy_role("merchant_raw"):
		if v != n and not w.asleep(v) and v.inv.count("stone") >= short and n.coins - w.reserve_of(n) >= w.sell_price(v, "stone") * short:
			n.doing = "buying stone to dress"
			n.plan = [go(_workplace_cell(v)), doit("buy_from", {"vendor": v.id, "item": "stone", "qty": short})]
			return true
	return false


## X18-STONECUT (owner B18-DP-09, X18-STONECUT: an independent trade and business in the ordinary economy): the
## stonecutter buys raw stone with its own coins, dresses it (_mason: the one recipe, the mallet and the chisel, a workbench,
## Masonry) only while someone will buy blocks, and sells them to the raw-goods merchant and to builders. No free stone, no
## customer guaranteed: with none it waits, earns nothing and, as any villager, in time looks for other work (seek_work).
func _stonecutter(n: NPC) -> bool:
	if n.inv.count("rubble") > 0 and _buyer_for(n, "rubble") != null:
		return _plan_sell(n, "rubble")                   # the dressing's rubble goes to the raw-goods merchant, for the manor's mending
	if _mason(n):
		return true
	n.doing = "waiting for stone to dress and customers for blocks"
	n.plan = [go(_workplace_cell(n)), work(60, "", {}, "idle")]
	return true


## STONE-01: whether building blocks are wanted now: a buyer takes them from `n` (the raw-goods merchant's stock for
## builders), or the open building sites need more than the blocks on sale.
func _block_demand(n: NPC) -> bool:
	if _buyer_for(n, "building_block") != null:
		return true
	var held := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and (o.job == "laborer" or buy_role(o) == "merchant_raw"):
			held += o.inv.count("building_block")
	return w.construction.open_need("building_block") > held


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
		n.plan = parts_plan + [go(w.station_use(bench)), work(CapabilityHook.work_time(float(rec.minutes), "carpentry", Skills.value(n, "carpentry", "craft_time", 1.0), n), "craft", {"recipe": "build_handcart", "station": bench}, "work", _station_at(bench))] + home
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
	if _plan_buy_seed(n):
		return
	if w.chapel.plan_ask(n):                   # DVW-B3-CHAPEL: a household short of food asks the church first
		return
	if w.farm_plots.plan_work(n):              # FARM-04: the family's farmland, in the time the day leaves
		return
	if w.chapel.plan_volunteer(n):             # DVW-B3-CHAPEL: a volunteer on the church's plot
		return
	if _plan_home_work(n):
		return
	var hh: Dictionary = w.households[n.household]
	var dependants := _dependants(hh)
	var stocked := _stocked(hh)
	var family_first_work := false
	if JudgmentLive.on(w, JudgmentFamily.FLAG) and JudgmentFamily.prefers_work(w, n):
		family_first_work = true                  # FAMILY-01: hungry dependants and short coin: paid work before leisure
		if _family_labour(n):
			return
	# a single villager with coins or a gift to spare seeks out the one they court, or a friend (CRT-11)
	if h >= WORK_END and not family_first_work and stocked >= dependants + 1 and _plan_seek_company(n):
		return
	# an evening at the tavern only when the household is provided for and there is coin to spare
	if h >= WORK_END and not family_first_work and n.coins >= int(GameData.b("tavern_spare_coins")) and stocked >= dependants + 1 and w.rng.randf() < 0.35:
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
			n.plan = [first(n, work(10, "eat", {"cooked_only": true}, "idle"))]
			return true
	var hh: Dictionary = w.households[n.household] if n.household >= 0 else {}
	var gives_way := JudgmentLive.on(w, JudgmentFamily.FLAG) and JudgmentFamily.defers(w, n, "pantry")      # FAMILY-01: the family eats first
	if not hh.is_empty() and not gives_way:
		var home_food := n.inv.has("wheat") or _can_roast(n)
		for f in EDIBLE:
			if hh.pantry.has(f):
				home_food = true
		if home_food:
			n.doing = "going home to eat"
			n.plan = _home_meal(n)
			return true
	# raw food in hand (eggs, milk, fruit, roots) is eaten as it is, as the player eats it (FSE-00 section 1)
	for f in EDIBLE:
		if f != "wheat" and not COOKED.has(f) and n.inv.has(f):
			n.doing = "eating"
			n.plan = [first(n, work(10, "eat", {"item": f}, "idle"))]
			return true
	if hh.is_empty() and n.inv.has("wheat"):
		n.doing = "eating"
		n.plan = [first(n, work(10, "eat", {}, "idle"))]
		return true

	# who pays is decided at the price asked (B7-015: a fixed 2-coin test sent people with 2 coins to a vendor whose
	# cheapest meal cost 3 to 5, again and again until they starved, while the household's tab could have paid)
	var payer: NPC = null
	var priced := false                    # food was on sale to someone
	var v := _vendor_with_food(n)
	if v and JudgmentLive.on(w, JudgmentFamily.FLAG) and JudgmentFamily.defers(w, n, "buy", _cheapest_meal(v)):
		gives_way = true
		v = null
	if v:
		priced = true
		payer = _payer_for(n, _cheapest_meal(v))      # the family's tab at the tavern, for anyone without the coin
		if payer != null:
			n.doing = "buying a meal" if payer == n else "eating on the family's tab"
			n.plan = [go(_workplace_cell(v)), doit("buy_food", {"vendor": v.id, "pantry": false, "payer": payer.id}), work(10, "eat", {}, "idle")]
			return true
	for o: NPC in w.npcs:
		if gives_way:
			break
		if o.alive and o != n and not w.asleep(o) and (o.job == "farmer" or buy_role(o) == "merchant_food") and o.inv.count("wheat") - reserve(o, "wheat") >= 2:
			priced = true
			payer = _payer_for(n, w.sell_price(o, "wheat") * 2)
			if payer != null:
				n.doing = "buying grain for porridge"
				n.plan = [go(_workplace_cell(o) if o.job != "farmer" else o.cell()), doit("buy_from", {"vendor": o.id, "item": "wheat", "qty": 2, "payer": payer.id}),
						] + _home_meal(n)
				return true
			break
	if gives_way:
		return false                       # FAMILY-01: leaves the food to those in their care, down to the survival floor
	var why := "no_money" if priced else "no_food_for_sale"
	w.stat("missed_meal_" + why)
	if track_misses:
		var best := _richest_in_household(n) if n.household >= 0 else n
		miss_log.append([w.day(), snappedf(w.hour(), 0.1), n.job if n.job != "" else n.role, why, best.coins if best else n.coins, n.household, n.coins, n.hunger, w.households[n.household].pantry.items.duplicate() if n.household >= 0 else {}, n.doing])
	once("hungry_%d_%d" % [n.id, w.day()], "%s %s is hungry and cannot get food." % [n.name, n.family])
	return false


# ---------------------------------------------------------------- jobs -----------------------
func _plan_job(n: NPC) -> bool:
	match n.job:
		"miner", "laborer":
			if n.job == "laborer" and _mason(n):         # STONE-01: blocks dressed to demand
				return true
			return _miner(n)
		"woodcutter":
			return _woodcutter(n)
		"stonecutter":                       # X18-STONECUT: an independent trade: dresses stone it bought, sells the blocks
			return _stonecutter(n)
		"prospector":
			return w.prospecting.plan(n)          # MIN-C: clues, samples and the assayer (Prospecting.plan)
		"carpenter":
			if w.mine_works.supply.carpenter_work(n):   # MIN-EQUIP: the manor's supports, ladders, mallets; a miner's minecart
				return true
			if _carpenter_carts(n):
				return true
			if _carpenter_goods(n):
				return true
			if _carpenter_mallet(n):                 # B14-07
				return true
			if _carpenter_shovel(n):                 # MIN-SHOVEL
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
		"tavernkeeper", "merchant", "reeve", "tailor", "barber":
			if n.job == "reeve" and w.hour() < float(GameData.b("manor_jobs").get("latest_start", 15)) and w.manor_work.reeve_fallback(n):
				return true          # LOG-01: an unclaimed delivery with no free manor hand
			n.doing = {"tavernkeeper": "serving at the tavern", "merchant": "minding the stall", "reeve": "keeping the manor",
				"tailor": "sewing at the pitch", "barber": "waiting at the barber's pitch"}[n.job]
			n.plan = [go(_workplace_cell(n)), work(60, "", {}, "idle")]
			if n.job == "merchant":
				n.plan[1]["industry"] = "trade"      # X18-D4: the hours a trader keeps the stall open are trade experience
			return true
		"preacher", "church_assistant":
			return w.chapel.plan_clergy(n)          # DVW-B3-CHAPEL: keeping the chapel; with no volunteers, the church's plot
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
			# PAR-04: the Apothecary keeps a few herbal tonics, and the strong tonic once its sage can brew it
			if n.inv.count("strong_healing_tonic") < 2 and n.inv.count("healing_tonic") >= 4 and n.inv.has("ale") and _can_make(n, "brew_strong_tonic") \
					and _do_recipe(n, "brew_strong_tonic"):
				return true
			if n.inv.count("herbal_tonic") < 3 and n.inv.has("flower", 3) and _do_recipe(n, "brew_tonic"):
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


## FSE-B05: a pen with no keeper (its keeper died or left farming when no other farmer was free) goes, each dawn, to a
## farmer who has none, as an empty stall goes to a merchant (Property.relet_stalls). Before, it stayed untended for good
## and its animals starved.
func relet_pens() -> void:
	var ids := w.fauna.pens.keys()
	ids.sort()
	for id in ids:
		var pen: Dictionary = w.fauna.pens[id]
		if w.pen_keeper(pen) != null:
			continue
		for o: NPC in w.npcs:
			if o.alive and o.job == "farmer" and _keeper_pen(o).is_empty():
				w.set_tenant(pen, World.npc_ref(o.id))
				w.note("%s %s takes on the %s pen, which had no keeper." % [o.name, o.family, pen.kind])
				break


func _manor_id() -> String:
	for id in w.buildings:
		if w.buildings[id].type == "manor":
			return id
	return w.npc(w.reeve_id).home


## Who pays on the family tab: the member with the most coins who can buy, an elder as well as an
## adult (a household's cash feeds all of it, as the manor's relief assumes).
## Who pays `price` for `n`'s food: `n` when they have it, else the household member with the most coins when they have
## it (the family's tab), else nobody.
func _payer_for(n: NPC, price: int) -> NPC:
	if JudgmentLive.on(w, JudgmentFamily.FLAG):
		var parent := JudgmentFamily.payer(w, n, price)      # FAMILY-01: the responsible parent's purse first, for those in their care
		if parent != null:
			return parent
	if n.coins >= price:
		return n
	if n.household < 0:
		return null
	var best := _richest_in_household(n)
	return best if best != null and best.coins >= price else null


## The cheapest cooked meal `v` has on sale, at its asking price (what _meal_choice can buy at the least).
func _cheapest_meal(v: NPC) -> int:
	var low := 1 << 30
	for f in COOKED:
		if v.inv.has(f):
			low = mini(low, w.sell_price(v, f))
	return low


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
	var mcp := w.mine_works.supply.miner_cart_plan(n) if carried == 0 else []
	if not mcp.is_empty():
		n.plan = mcp                   # MIN-EQUIP: the household's minecart, bought with the miner's coins and set on the rails
		return true
	if carried >= int(GameData.b("carry_ore")):
		var haul := w.mine_works.cart_haul_plan(n, not w.nearest_seam(n, ores).is_empty()) if n.depth != 0 else []
		if not haul.is_empty():
			n.plan = haul              # MIN-F2 (Q3): into a minecart when its way is cheaper than carrying out
			return true
		return _plan_sell_all(n)       # sells whatever has a buyer first
	ores = ores.filter(func(o: String) -> bool: return _buyer_for(n, o) != null and _can_mine(n, o))
	var d: Dictionary = w.nearest_seam(n, ores) if not ores.is_empty() else {}        # MIN-A: the gallery's seams too
	if d.is_empty():
		# MIN-D, MIN-E: a miner whose ore is worked out digs the manor's trial pit or open pit for new ore, if posted (paid work)
		if n.job == "miner" and w.hour() < float(GameData.b("manor_jobs").get("latest_start", 15)):
			if w.manor_work.seek_kind(n, ["trial", "excavate", "tunnel"]):
				return true
			# MIN-SHOVEL: posted earthwork it could do only with a shovel: it buys one, if one is for sale and it can pay
			if OpenPits.held_tool(n, "shovel") == "" and w.manor_work.shovel_would_open(World.npc_ref(n.id)) and _buy_tool(n, "shovel"):
				return true
		# the wanted seams are worked out: mine only what someone will still buy
		var sellable := []
		for o in ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"]:
			if _buyer_for(n, o) != null and _can_mine(n, o):
				sellable.append(o)
		if not sellable.is_empty():
			d = w.nearest_seam(n, sellable)
	if d.is_empty():
		if carried > 0:
			return _plan_sell_all(n)
		if w.nearest_seam(n, ["iron_ore", "coal", "copper_ore", "stone", "gold_ore"].filter(func(o: String) -> bool: return _can_mine(n, o))).is_empty():
			# the mine is worked out: the manor takes on those who lose their living
			_change_job(n, "manor_hand", "the mine is worked out")
			return false
		return _idle_at_work(n, "waiting for ore buyers")
	n.doing = "mining %s" % GameData.item_name(d.ore).to_lower()
	n.plan = w.mine_works.cart_fetch_plan(n, d) + seam_steps(n, d, "mine", {})     # MIN-F2 (Q3): a minecart brought along, on the way
	return true


## MIN-A: the steps to work seam `d` on whatever level it lies: walk beside it on its level (the router takes the
## walker through the portal) and swing; the act's args name the seam by level and cell.
func seam_steps(n: NPC, d: Dictionary, act: String, args: Dictionary) -> Array:
	var at := Vector2i(d.x, d.y)
	var lv := World.level_of(d)
	var a := args.duplicate()
	a.x = d.x
	a.y = d.y
	if lv != 0:
		a.level = lv
	var from := n.cell() if n.depth == lv else at
	# X18 HOOK (Expansion 18, X18-SIM): CapabilityHook is off in the game (exactly base x skill time); analysis runs only
	var mins := CapabilityHook.work_time(float(GameData.b("mine_minutes")), "mining", Skills.value(n, "mining", "mine_time", 1.0), n)
	return [go(beside(at, from, lv), 1.0, lv), work(mins, act, a, "work", at)]


## PAR-01: whether `n` may work a seam of `ore` (gold ore needs Mining level 3, as for the player).
func _can_mine(n: NPC, ore: String) -> bool:
	return ore != "gold_ore" or Skills.has(n, "mining", "gold")


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
		n.plan = [wait(n, 60)]
		return true
	t.claimed = n.id
	var at := Vector2i(t.x, t.y)
	n.doing = "felling a tree"
	var mins := CapabilityHook.work_time(float(GameData.b("chop_minutes")), "forestry", Skills.value(n, "woodcutting", "chop_time", 1.0), n)   # X18 HOOK
	n.plan = [go(beside(at, n.cell())), work(mins, "chop", {"x": t.x, "y": t.y}, "work", at)]
	return true


## PAR-01: whether `n` has the skill level recipe `r` needs (the player's requirement), and the tool it names
## (STONE-01: the mallet to dress stone; World.craft_tool).
func _can_make(n: NPC, r: String) -> bool:
	var rec: Dictionary = GameData.recipes[r]
	return n.level(str(rec.skill)) >= int(rec.level) and (not rec.has("tool") or w.craft_tool(n, r) != "-")


## Goods made only for a buyer (PAR-04): the maker sells all it has of them.
const MADE_TO_ORDER := ["iron_helmet", "copper_ring", "amulet", "gold_ring", "gold_bar", "leather_cap", "plough", "nails", "mallet", "chisel", "shovel_blade",
	"timber_support", "ladder", "minecart"]       # MIN-EQUIP: the carpenter's, for the manor's orders and a miner's household


func _crafter(n: NPC, recipes: Array) -> bool:
	var fixed := _first_ready(n, recipes)
	recipes = by_return(n, recipes)                 # WDR-012-C: the better return under local prices first
	if fixed != "" and _first_ready(n, recipes) != fixed:
		w.stat("spec_switches")
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


## WDR-012-C (owner B18-DP-08): what one batch of recipe `r` is expected to return `n` under the actual local prices: the
## products at the price a seller in their position asks (World.sell_price: dearer as their stock runs low, cheaper among
## many local sellers) less the inputs at what they would cost to replace at the local asking price. Nothing is invented:
## the same prices the player meets (World.sell_price_at).
func recipe_return(n: NPC, r: String) -> float:
	var rec: Dictionary = GameData.recipes[r]
	var got := 0.0
	for id in rec.out:
		got += float(rec.out[id]) * float(w.sell_price(n, id))
	var cost := 0.0
	for id in rec["in"]:
		cost += float(rec["in"][id]) * float(World.sell_price_at(id, 0, w.local_supply(id, n.pos, n)))
	return got - cost


## `recipes` ordered by expected return, best first; equal returns keep the order given (deterministic).
func by_return(n: NPC, recipes: Array) -> Array:
	var keyed := []
	for i in recipes.size():
		keyed.append([recipe_return(n, recipes[i]), i, recipes[i]])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	return keyed.map(func(k: Array) -> String: return k[2])


func _first_ready(n: NPC, recipes: Array) -> String:
	for r in recipes:
		if n.inv.has_all(GameData.recipes[r]["in"]):
			return r
	return ""


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
	for id in ["leather_cap", "leather_armor"]:        # PAR-04: for a buyer, once the hides are tanned
		if n.inv.count(id) > 0 and _buyer_for(n, id) != null:
			return _plan_sell(n, id)
		if _buyer_for(n, id) != null and _can_make(n, id):
			list.append(id)
	return _crafter(n, list)


func _smith(n: NPC) -> bool:
	var inv := n.inv
	if inv.has_all({"iron_ore": 2, "coal": 1}) and inv.count("iron_bar") < 12:
		return _do_recipe(n, "smelt_iron")
	if inv.has_all({"copper_ore": 2, "coal": 1}) and inv.count("copper_bar") < 6:
		return _do_recipe(n, "smelt_copper")
	# PAR-04: gold ore is smelted when someone wants the bar or a gold ring, and the smith has Smithing 3
	if inv.has_all({"gold_ore": 2, "coal": 1}) and inv.count("gold_bar") < 2 and _can_make(n, "smelt_gold") \
			and (_buyer_for(n, "gold_bar") != null or _buyer_for(n, "gold_ring") != null):
		return _do_recipe(n, "smelt_gold")
	# the goods merchant is the smith's wholesale buyer (B7-016): tools beyond the smith's own go to its stall
	for id in ["pickaxe", "axe", "iron_sword", "copper_sword"]:
		if inv.count(id) > 1 and _buyer_for(n, id) != null:
			return _plan_sell(n, id)
	for id in MADE_TO_ORDER:                      # PAR-04: made for a buyer, so all of it goes
		if id == "gold_bar" and _buyer_for(n, "gold_ring") != null and _can_make(n, "forge_gold_ring"):
			continue                              # (a bar a wanted ring needs is forged into it first)
		if inv.count(id) > 0 and _buyer_for(n, id) != null:
			return _plan_sell(n, id)
	# the manor's orders first (EQ-19): the tools it paid for in advance. While one is open the forge keeps its iron
	# for it and fetches what the tool still lacks (the plank from the carpenter, ore and coal from the raw-goods
	# merchant), instead of working the bars into something else
	for x in w.manor_orders:
		if int(x.smith) != n.id or inv.count(str(x.tool)) > 0:
			continue
		var r := "forge_" + str(x.tool)
		if not GameData.recipes.has(r):
			continue
		if inv.has_all(GameData.recipes[r].in):
			return _do_recipe(n, r)
		if _fetch_for_order(n, GameData.recipes[r].in):
			return true
	# forge whatever is scarcest (not with the iron an open order of the manor's is waiting for)
	var ordered := w.manor_orders.any(func(x): return int(x.smith) == n.id and inv.count(str(x.tool)) == 0)
	var wants := []
	var for_buyer := []                           # the recipes a buyer wants made (WDR-012-C: they come before goods for stock)
	for r in ["forge_pickaxe", "forge_axe", "forge_iron_sword", "forge_hammer", "forge_copper_sword", "forge_iron_armor", "forge_lockpicks", "forge_padlock", "forge_cart_axle", "forge_cart_ironwork"]:
		if ordered and (GameData.recipes[r].in as Dictionary).has("iron_bar"):
			continue
		var out: String = GameData.recipes[r].out.keys()[0]
		var cap := 1 if out in ["hammer", "iron_armor", "padlock", "cart_axle", "cart_ironwork"] else 3
		if inv.count(out) < cap and inv.has_all(GameData.recipes[r].in) and _can_make(n, r):
			wants.append([inv.count(out), r])
	# PAR-04: the jewellery, the helmet and nails (B14-07) only for a buyer who wants them
	for r in ["forge_iron_helmet", "forge_copper_ring", "forge_amulet", "forge_gold_ring", "forge_nails", "forge_shovel_blade", "forge_chisel"]:
		if ordered and (GameData.recipes[r].in as Dictionary).has("iron_bar"):
			continue
		var out: String = GameData.recipes[r].out.keys()[0]
		if inv.count(out) < 1 and inv.has_all(GameData.recipes[r].in) and _can_make(n, r) and _buyer_for(n, out) != null:
			wants.append([inv.count(out), r])
			for_buyer.append(r)
	wants.sort()
	if not wants.is_empty():
		var rs: Array = wants.map(func(x: Array) -> String: return x[1])
		if not for_buyer.is_empty():
			rs = rs.filter(func(r: String) -> bool: return for_buyer.has(r))       # a buyer's want is demand: it goes before stock
		var best: String = by_return(n, rs)[0]         # WDR-012-C: what pays best under local prices, not the scarcest first
		if best != wants[0][1]:
			w.stat("spec_switches")
		return _do_recipe(n, best)
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


## What a smith still lacks for a tool the manor ordered (EQ-19): a plank from the carpenter, or the ore and coal
## for the bars from the raw-goods merchant. True when a trip is planned.
func _fetch_for_order(n: NPC, need: Dictionary) -> bool:
	var inv := n.inv
	if inv.count("plank") < int(need.get("plank", 0)):
		var c := _first_with_job("carpenter")
		if c != null and c.inv.has("plank") and n.coins >= w.sell_price(c, "plank") and not w.asleep(c):
			n.doing = "fetching a plank for the manor's order"
			n.plan = [go(_workplace_cell(c)), doit("buy_from", {"vendor": c.id, "item": "plank", "qty": 1})]
			return true
	var bars_short := int(need.get("iron_bar", 0)) - inv.count("iron_bar")
	if bars_short > 0:
		for id in ["coal", "iron_ore"]:
			var short := bars_short * (1 if id == "coal" else 2) - inv.count(id)
			if short <= 0:
				continue
			for v: NPC in w.npcs:
				if v.alive and v != n and buy_role(v) == "merchant_raw" and v.inv.count(id) > 0 and not w.asleep(v) and n.coins >= w.sell_price(v, id):
					n.doing = "buying %s for the manor's order" % GameData.item_name(id).to_lower()
					n.plan = [go(_workplace_cell(v)), doit("buy_from", {"vendor": v.id, "item": id, "qty": short})]
					return true
	return false


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
	# PAR-04: with no egg, plain flatbread when someone wants bread
	if n.inv.has("wheat", 3) and not n.inv.has("egg") and n.inv.count("bread") < 2 and _buyer_for(n, "bread") != null and _do_recipe(n, "knead_flatbread"):
		return true
	if n.inv.has("wheat", 2):
		return _do_recipe(n, "cook_pottage")
	if food > 0:
		return _plan_sell(n, _most(n, COOKED))
	n.doing = "waiting for wheat"
	n.plan = [go(_workplace_cell(n)), work(30, "", {}, "idle")]
	return true


## FARM-08-Q-CROP: each cutter's work on field `f` when `n` finishes its cutting (`done` minutes): `n`'s whole cutting
## and, for every other farmer of the field cutting it now, the minutes already worked; those stop cutting (their step
## ends with their share). A farmer not cutting at that moment did no cutting work and gets no share. Owner D7
## (2026-10-23): work is minutes x the cutter's own work rate (CapabilityHook.rate: 1.0 with no experience effect), so a
## faster cutter's share follows the ground cut, not the clock. id -> base-minute equivalents.
func _cutting_shares(n: NPC, f: Dictionary, done: float) -> Dictionary:
	var out := {n.id: maxf(done, 0.001) * CapabilityHook.rate("farming", n)}
	for o: NPC in w.field_workers(f):
		if o == n or o.plan.is_empty() or o.plan[0].k != "work" or str(o.plan[0].get("act", "")) != "harvest" \
				or str(o.plan[0].get("args", {}).get("field", "")) != str(f.id):
			continue
		var worked := float(o.plan[0].min) - o.work_left
		if worked <= 0.0:
			continue
		out[o.id] = worked * CapabilityHook.rate("farming", o)       # X18-D7: work done, in base-minute equivalents
		o.plan.pop_front()
		if not o.plan.is_empty() and o.plan[0].k == "work":
			o.work_left = float(o.plan[0].min)
	return out


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
			var cut := CapabilityHook.time(w.farm.field_work_minutes(int(f.get("sown", 0)), "cut") if Farming.shared_manor() else 90.0, "farming", n)   # X18 HOOK
			n.plan = [go(spot), work(cut, "harvest", {"field": f.id, "min": cut}, "work")]   # min: this cutter's share of the work (FARM-08-Q-CROP)
		"tilled":
			if Farming.seasonal_fields() and not w.farm.can_sow_now():
				n.doing = "waiting for the sowing season"     # FSE-13: no sowing in winter, as for the player
				n.plan = [go(spot), work(60, "", {}, "idle")]
				return true
			if Farming.shared_manor() and w.farm.field_seed(f) <= 0:
				n.doing = "no seed to sow the field"          # FSE-12: no seed, no sowing (no free seed)
				w.stat("field_unsown_no_seed")
				n.plan = [go(spot), work(60, "", {}, "idle")]
				return true
			n.doing = "sowing"
			var sow := CapabilityHook.time(w.farm.field_work_minutes(mini(Farming.field_cells(f), w.farm.field_seed(f)), "sow") if Farming.shared_manor() else 45.0, "farming", n)   # X18 HOOK
			n.plan = [go(spot), work(sow, "sow", {"field": f.id}, "work")]
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


## Stock an NPC holds back instead of selling: a keeper keeps four days of feed for the pen, and anyone what it still
## owes on its contracts (CON-01).
func reserve(n: NPC, id: String) -> int:
	var owed: int = w.contracts.held_for(n, id) if w.contracts else 0
	if id != "wheat" or n.job != "farmer":
		return owed
	var pen := _keeper_pen(n)
	return owed + (0 if pen.is_empty() else w.fauna.daily_need(pen) * (1 if w.famine() else 4))


## FARM-08B: the feed a keeper still lacks to hold its reserve (0 for anyone keeping no pen): a buyer of wheat whom
## the farmers keep grain in hand for (_sale_stock), as they do for the cook and the food merchant.
func feed_want(o: NPC) -> int:
	return maxi(0, reserve(o, "wheat") - o.inv.count("wheat"))


func _keeper(n: NPC) -> bool:
	var pen := _keeper_pen(n)
	if pen.is_empty():
		return false
	# the pen's eggs, milk and wool (Build 13): collected at the gate, then sold to the cook and the tanner
	if not w.farm.products_in(pen).is_empty():
		n.doing = "collecting from the %s" % GameData.b("animals")[pen.kind].name.to_lower()
		# X18 HOOK (X18-CAPNUM farming F1): off in the game (exactly 10); collecting eggs, milking, shearing: faster, the same products
		n.plan = [go(Vector2i(int(pen.feed_at[0]), int(pen.feed_at[1]))), work(CapabilityHook.time(10.0, "farming", n), "collect_pen", {"pen": pen.id}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))]
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
			n.plan = [go(at), work(30, "slaughter", {"pen": pen.id, "animal": cut.id, "why": "famine"}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))]
			return true
	if int(pen.trough) < need * 2:
		# X18 HOOK (X18-CAPNUM F1): off in the game (exactly 15); the same feed
		var feed_step := work(CapabilityHook.time(15.0, "farming", n), "feed_pen", {"pen": pen.id}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))
		n.doing = "feeding the %s" % GameData.b("animals")[pen.kind].name.to_lower()
		if n.inv.has("wheat"):
			n.plan = [go(at), feed_step]
			return true
		# no grain in hand: the household's store first, then buy feed
		var pantry: Inventory = w.households[n.household].pantry
		if pantry.has("wheat"):
			n.plan = [go(w.home_cell(n, "chest")), doit("take_pantry", {"item": "wheat", "qty": need * 3}), go(at), feed_step]
			return true
		# FARM-08B: as much of three days' feed as a seller can spare and the keeper can pay for, as the player may buy
		# any number (buy_from sells a part lot): from the seller who can supply the most (the first of equals)
		var seller: NPC = null
		var qty := 0
		var offered := false
		for o: NPC in w.npcs:
			if o.alive and o != n and not w.asleep(o) and (o.job == "farmer" or buy_role(o) == "merchant_food"):
				var spare := o.inv.count("wheat") - reserve(o, "wheat")
				offered = offered or spare > 0
				var can := mini(mini(need * 3, spare), n.coins / maxi(1, w.sell_price(o, "wheat")))
				if can > qty:
					seller = o
					qty = can
		if seller != null:
			n.plan = [go(_workplace_cell(seller) if seller.job != "farmer" else seller.cell()), doit("buy_from", {"vendor": seller.id, "item": "wheat", "qty": qty}), go(at), feed_step]
			return true
		# no feed to be had and not enough for tomorrow morning: cull beyond the breeding stock and
		# sell the meat for feed money
		w.stat("keeper_no_feed_" + str(pen.kind))       # FARM-08B: a keeper found no grain to feed with (counted, changes nothing)
		if offered:
			w.stat("keeper_no_coins_" + str(pen.kind))  # of which: grain was for sale, but the keeper could not pay for one
		var cull: Animal = w.fauna.surplus(pen, true) if int(pen.trough) < need else null
		if cull != null:
			once("cull_%d_%d" % [n.id, w.day()], "%s %s has no feed for the %s and culls one." % [n.name, n.family, GameData.b("animals")[pen.kind].name.to_lower()])
			n.doing = "culling a %s" % pen.kind
			n.plan = [go(at), work(30, "slaughter", {"pen": pen.id, "animal": cull.id, "why": "no_feed"}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))]
			return true
	var spare: Animal = w.fauna.surplus(pen)
	if spare != null:
		n.doing = "slaughtering a %s" % pen.kind
		n.plan = [go(at), work(30, "slaughter", {"pen": pen.id, "animal": spare.id, "why": "surplus"}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1])))]
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
	_take_guard_post(n)
	if Decay.plan_rearm(w, n):            # DVW-B4: armour worn out is bought again from a seller, with its own coins
		return
	var on_duty := (h >= WAKE and h < SLEEP) if n.workplace == "day" else (h >= SLEEP - 1.0 or h < WAKE + 1.0)
	var shops_open := h >= WORK_START and h < WORK_END
	if not on_duty:
		if shops_open and _plan_provision(n):
			return
		var mins := 120.0
		n.doing = "off duty"
		_plan_bed(n, mins)
		return
	var foe := _bandit_seen(n)
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
		if int(l.coins) <= 0 or World.level_of(l) != 0:      # MIN-A: guards do not go below the surface
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
	# SIM-F4 (owner 2026-10-24, "heal at camp"): a badly hurt bandit rests at the camp as a hurt villager rests at home
	# (below rest.seek_below of their health, for rest.day_minutes, restored by World.rest_recover, PAR-03)
	if n.hp < n.max_hp * float(GameData.b("rest").seek_below):
		var mins := float(GameData.b("rest").day_minutes)
		n.doing = "resting at the camp"
		n.plan = [go(wander_cell(w.bandit_camp, 2)), work(mins, "rest_end", {"min": mins, "morning": false}, "sleep")]
		return
	var night := h >= 21.0 or h < 4.5
	if night:
		var prey = _prey_for(n)
		if prey != null:
			n.target = prey.id if prey is NPC else Life.PLAYER_ID
			n.doing = "stalking"
			return
	if not night and h >= WORK_START and h < WORK_END and _bandit_market(n):
		return
	n.doing = "lurking at the camp"
	n.plan = [go(wander_cell(w.bandit_camp, 3)), work(w.rng.randf_range(30, 90), "poach", {}, "idle")]


## OD-16 (a), EQ-20 (owner 2026-10-20: "bandits spend their hoards at the market"): by day a bandit who can afford one
## item of food slips into the market and buys up to `bandit_spend_units` of it from a seller no guard stands near
## (within 10 tiles), so stolen coins return to the village's traders. SIM-F4 (owner 2026-10-24): however hurt, and from
## the first item's price, not a 15-coin hoard (a hurt band with coins starved before).
func _bandit_market(n: NPC) -> bool:
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


## FSE-B06: a bandit or a clan child eats only real food, from the band's stores: the packs of the living bandits, the
## eater's own first (food bought at the market or stolen, game they poached). Raw meat is roasted at the camp fire, the
## oven's recipe (1 meat -> 2 roast meat) on deadwood from the wood, as no log is carried there (an explicit difference
## from the village recipe, put to the owner). Eats until no longer hungry; true if anything was eaten. With nothing in the
## stores the band goes hungry (WDR-022: a band may go hungry).
func band_eat(n: NPC) -> bool:
	var band: Array = [n] + w.npcs.filter(func(o: NPC) -> bool: return o != n and o.alive and o.role == "bandit")
	var ate := false
	var roast: Dictionary = GameData.recipes["roast_meat"]
	while n.hunger < 90.0:
		var got := ""
		for o: NPC in band:
			for f in EDIBLE:
				if o.inv.has(f):
					got = f
					o.inv.remove(f)
					break
			if got == "" and o.inv.count("meat") >= int(roast.in.meat):
				o.inv.remove("meat", int(roast.in.meat))
				w.stat("used_meat", float(roast.in.meat))
				o.inv.add("roast_meat", int(roast.out.roast_meat))
				w.stat("made_roast_meat", float(roast.out.roast_meat))
				w.stat("camp_roasted")
				got = "roast_meat"
				o.inv.remove(got)
			if got != "":
				break
		if got == "":
			break
		n.hunger = minf(100.0, n.hunger + float(GameData.item(got).food))
		w.stat("eaten_food", float(GameData.item(got).food))
		w.stat("eaten_" + got)
		ate = true
	return ate


## A child of the bandit clan (FAM-07): eats with the band at the camp when hungry (the camp's meal, as the bandits'
## own poaching), sleeps there at night and plays about it by day; never goes stalking.
func _clan_child(n: NPC, h: float) -> void:
	if n.hunger < float(GameData.b("eat_below")):
		n.doing = "eating at the bandits' camp"
		n.plan = [go(wander_cell(w.bandit_camp, 2)), work(15, "camp_meal", {}, "idle")]
		return
	if h >= SLEEP or h < WAKE:
		n.doing = "sleeping at the bandits' camp"
		n.plan = [go(wander_cell(w.bandit_camp, 2)), work(120, "rest_end", {"min": 120.0}, "sleep")]
		return
	n.doing = "playing about the bandits' camp"
	n.plan = [go(wander_cell(w.bandit_camp, 4), 0.9), work(w.rng.randf_range(20, 60), "", {}, "idle")]


func _prey_for(n: NPC):
	if w.player.alive and w.player.pos.distance_to(n.pos) < 18.0 and w.player_level == n.depth:
		return w.player
	var best = null
	var bd := 40.0
	for o: NPC in w.npcs:
		if not o.alive or o.depth != n.depth or w.place_of(o.pos) != "" or o.role == "bandit" or o.clan != "" or o.job == "guard" or o.coins < 3:
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
		n.plan = [wait(n, 30)]
		return true
	n.doing = "taking %s to %s" % [GameData.item_name(id).to_lower(), buyer.name]
	n.plan = [go(_workplace_cell(buyer)), doit("sell_to", {"buyer": buyer.id, "item": id})]
	return true


func _buyer_for(n: NPC, id: String) -> NPC:
	if JudgmentLive.on(w, "trade_sell"):
		return JudgmentLive.pick_buyer(w, self, n, id)      # PROSPECTIVE (PROS-19, Q14): off unless judgment is attached
	for outlet in OUTLETS.get(id, []):
		for b in _with_buy_role(outlet):
			if b != n and b.alive and w.purchase_qty(b, n, id, maxi(1, n.inv.count(id))) > 0:     # TRADE-01: the one rule
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
	if o.job == "carpenter":                          # MIN-EQUIP: only as many as the manor has ordered from it are held back
		var ordered := w.manor_orders.filter(func(x): return int(x.smith) == o.id and str(x.tool) == id).size()
		if ordered > 0 and o.inv.count(id) <= ordered:
			return true
	return id == "axe" and o.household >= 0 and o.household < w.households.size() \
			and str(w.households[o.household].get("build", "")) != "" and w.construction.responsible_adult(o.household) == o


## How many of `id` this NPC will still buy (SHOP-01): of an input its trade works (TRADE_STATIONS), none when it lacks
## the skill for every recipe that takes it; otherwise what keeps its holding at or below its want: its trade's stock
## (BUYS) rounded up to whole batches (batch_unit), capped by that same stock. A part lot towards a batch is bought.
## What it can pay for is World.purchase_qty's part.
func wants(o: NPC, id: String) -> int:
	var caps: Dictionary = BUYS.get(buy_role(o), {})
	if not caps.has(id):
		return 0
	var unit := batch_unit(o, id)
	if unit <= 0:
		return 0
	var want := mini(ceili(float(caps[id]) / unit) * unit, int(caps[id]))
	return maxi(0, want - o.inv.count(id))


## SHOP-01: the smallest batch in which `o` works `id`: of the recipes at its trade's stations (TRADE_STATIONS) that
## consume it, the least any it has the skill for (_can_make) takes; 0 when it can make none of them (it has no use for
## the input); 1 for goods no recipe of its trade consumes (stock for sale or use).
func batch_unit(o: NPC, id: String) -> int:
	var key: String = o.job + "/" + id
	if not _consumers.has(key):
		var rs := []
		for r in GameData.recipes:
			var rec: Dictionary = GameData.recipes[r]
			if (rec["in"] as Dictionary).has(id) and TRADE_STATIONS.get(o.job, []).has(str(rec.station)):
				rs.append(r)
		_consumers[key] = rs
	var rs: Array = _consumers[key]
	if rs.is_empty():
		return 1
	var unit := 0
	for r in rs:
		var q := int(GameData.recipes[r]["in"][id])
		if _can_make(o, r) and (unit == 0 or q < unit):
			unit = q
	return unit


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
	if pantry.count("wheat") >= need and w.work_craft(n, "cook_pottage", pantry).result == "ok":
		w.stat("home_cooked")
		return
	# raw meat is roasted at the hearth with a log, the player's home recipe (FSE-00 section 1, B7-015: hunters' families
	# starved holding meat nobody would buy and they could not cook)
	for id in ["meat", "log"]:
		if not pantry.has(id) and n.inv.has(id):
			w.transfer(n.inv, pantry, id, 1)
	if pantry.has("meat") and pantry.has("log") and w.work_craft(n, "roast_meat", pantry).result == "ok":
		w.stat("home_roasted")


## FSE-18 (owner, 2026-10-20: "keep the family food in a ... chest ... communal"): a villager at home puts the food they
## carry for eating into the household's pantry, its family chest. Trade stock stays in the pack for sale (a food
## vendor's stock; a producer's goods as far as buyers will take them, _sale_stock), the rest goes in; and a trader stocks
## the chest up to the household's reserve horizon (OD-19's reserve_days) before keeping the rest to sell. (B7-015 after
## FSE-17: elders starved while a member carried 79 milk no buyer would take.)
## What each producing trade makes to sell, so keeps back from the family chest as far as buyers take it (_sale_stock).
const TRADE_GOODS := {"woodcutter": ["log"], "hunter": ["meat"], "farmer": ["wheat", "egg", "milk", "meat"], "laborer": ["log"]}


func stock_family_chest(n: NPC) -> void:
	if n.household < 0 or n.household >= w.households.size() or w.households[n.household].get("ended", false):
		return
	var pantry: Inventory = w.households[n.household].pantry
	var short := household_day_food(n.household) * float(GameData.b("reserve_days")) - store_points([pantry])
	var carrying_for_work := not w.construction.contract_of(n).is_empty()     # a helper's loads are the site's
	for f in EDIBLE + ["meat", "log"]:
		if f == "log" and carrying_for_work:
			continue
		var c := n.inv.count(f)
		if c <= 0:
			continue
		var put := c - mini(c, _sale_stock(n, f))
		if short > 0.0 and put < c and food_points(f) > 0.0:     # the top-up is food; firewood is not
			put = maxi(put, mini(c, ceili(short / maxf(1.0, food_points(f)))))
		if put > 0 and w.transfer(n.inv, pantry, f, put):
			short -= float(put) * food_points(f)
			w.stat("family_chest_stocked", put)
	# and the firewood to cook the chest's meat, from trade stock too, as far as the reserve horizon needs (B7-015 after
	# FSE-18, seed 4: two children starved beside 7 raw meat while a member kept 18 logs for sale)
	var horizon := ceili(household_day_food(n.household) * float(GameData.b("reserve_days")) / food_points("meat"))
	var logs := mini(mini(pantry.count("meat"), horizon) - pantry.count("log"), n.inv.count("log"))
	if logs > 0 and not carrying_for_work and w.transfer(n.inv, pantry, "log", logs):
		w.stat("family_chest_stocked", logs)


## How many of `f` that `n` carries are trade stock: all of a food vendor's (the tavern, the cook, the food merchant sell
## from what they carry) and all of a trade's inputs (BUYS: a carpenter's logs); of what a producer's trade makes
## (TRADE_GOODS), what it keeps back (a keeper's pen feed) and what buyers will take now (the outlets' wants). Anything else
## is the family's (B7-015 after FSE-18: an elder carried 7 logs as if for sale while another starved beside raw meat).
func _sale_stock(n: NPC, f: String) -> int:
	if n.job in ["tavernkeeper", "cook"] or buy_role(n) == "merchant_food" or BUYS.get(buy_role(n), {}).has(f):
		return n.inv.count(f)
	if not TRADE_GOODS.get(n.job, []).has(f):
		return 0
	var k := reserve(n, f)
	for o: NPC in w.npcs:
		if o.alive and o != n and o.household != n.household and OUTLETS.get(f, []).any(func(r): return o.job == r or buy_role(o) == r):
			k += wants(o, f)
		elif f == "wheat" and o.alive and o != n and o.household != n.household:
			k += feed_want(o)                   # FARM-08B: a pen keeper short of feed buys grain too
	return k


## Whether `n`'s household can roast meat at home now: meat and a log between its pantry and `n`.
func _can_roast(n: NPC) -> bool:
	var p: Inventory = w.households[n.household].pantry
	return (p.has("meat") or n.inv.has("meat")) and (p.has("log") or n.inv.has("log"))


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
	if JudgmentLive.on(w, "trade_buy_from"):
		return JudgmentLive.pick_seller(w, self, id, buyer)  # PROSPECTIVE (PROS-19, Q14): off unless judgment is attached
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
	if _buy_tool(n, tool):
		return true
	once("no_tool_%d_%d" % [n.id, w.day()], "%s %s has no %s and cannot get one." % [n.name, n.family, tool])
	n.doing = "out of work: needs a %s" % tool
	n.plan = [go(wander_cell(w.building_door(n.home), 4)), work(90, "", {}, "idle")]
	return true


## A trip to buy `tool` from whoever sells it (the goods merchant first, the smith's wholesale buyer, B7-016; then the
## smith; MIN-SHOVEL: then the carpenter, who makes shovels): false when nobody has one for sale it can pay for.
func _buy_tool(n: NPC, tool: String) -> bool:
	for role in ["merchant_goods", "smith", "carpenter"]:
		if role == "carpenter" and tool != "shovel":
			continue
		for o: NPC in w.npcs:
			if o.alive and ((o.job == role) if role in ["smith", "carpenter"] else (buy_role(o) == role)) and o.inv.has(tool) and not keeps(o, tool):
				if n.coins >= w.sell_price(o, tool):
					n.doing = "buying a new %s" % tool
					n.plan = [go(_workplace_cell(o)), doit("buy_from", {"vendor": o.id, "item": tool, "qty": 1})]
					return true
	return false


func _do_recipe(n: NPC, r: String) -> bool:
	var rec: Dictionary = GameData.recipes[r]
	if n.level(str(rec.skill)) < int(rec.level):        # PAR-01: the player's requirement
		w.stat("skill_short_" + r)
		return false
	if rec.has("tool") and w.craft_tool(n, r) == "-":     # STONE-01: the recipe's tool, as for the player
		return false
	var st := _station_for(n, rec.station)
	if st == "":
		w.stat("station_busy_" + str(rec.station))
		return false
	# the station is reserved for the walk there and the work, plus an hour's slack
	w.stations[st].users[n.id] = w.minutes + w.map.data.w + float(rec.minutes) + 60.0
	n.doing = "%s" % r.replace("_", " ")
	var mins := CapabilityHook.work_time(float(rec.minutes), CapabilityHook.recipe_industry(r), Skills.value(n, str(rec.skill), "craft_time", 1.0), n)   # X18 HOOK
	n.plan = [go(w.station_use(st)), work(mins, "craft", {"recipe": r, "station": st}, "work", _station_at(st))]
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
	if o.workplace == "chapel" and w.chapel != null and w.chapel.present:
		return w.chapel.door_cell()
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
		if o.alive and o.job == "guard" and not w.asleep(o) and o.pos.distance_to(p) <= r and o.depth == w.level_at(p):     # MIN-A: one level
			return true
	return false


## A bandit `n` can see (PAR-05: within witness_radius and in the same place, the sight anyone has), or null.
func _bandit_seen(n: NPC) -> NPC:
	var here := w.place_of(n.pos)
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit" and o.pos.distance_to(n.pos) <= float(GameData.b("witness_radius")) and w.place_of(o.pos) == here and o.depth == n.depth:
			return o
	return null


## PAR-05: a villager who knows of an attack tells a guard. One in sight hears it at once (World.deliver_report);
## otherwise they go to the nearest awake guard within report.range tiles (the walk and a "report" step), and
## failing that keep it until they meet one. The report lapses after report.hours. True when a walk is planned.
func _report(n: NPC) -> bool:
	var cfg: Dictionary = GameData.b("report")
	if w.minutes - float(n.report.t) > float(cfg.hours) * 60.0 or not w.offender_alive(int(n.report.offender)):
		n.report = {}
		return false
	var best: NPC = null
	for g: NPC in w.npcs:
		if g.alive and g.job == "guard" and g != n and not w.asleep(g) and g.pos.distance_to(n.pos) <= float(cfg.range) \
				and (best == null or g.pos.distance_to(n.pos) < best.pos.distance_to(n.pos)):
			best = g
	if best == null:
		return false
	if w.near(n.pos, float(GameData.b("witness_radius"))).has(best):
		w.deliver_report(n, best)
		return false
	n.doing = "going to tell a guard"
	n.plan = [go(best.cell()), doit("report", {"guard": best.id})]
	return true


func _bandit_near(p: Vector2, r: float) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit" and o.pos.distance_to(p) <= r:
			return o
	return null


# ---------------------------------------------------------------- actions --------------------
func act(n: NPC, what: String, a: Dictionary) -> bool:
	act_calls[what] = int(act_calls.get(what, 0)) + 1
	match what:
		"enter":
			n.doing = "asleep at home" if w.hour() >= SLEEP or w.hour() < WAKE else "at home"
			if n.household >= 0 and n.home == str(w.households[n.household].home):
				stock_family_chest(n)                # FSE-18: home, the family's food goes in the chest
			return true
		"leave":
			n.anim = "idle"
			return true
		"report":                             # PAR-05: at the guard (if they are still within sight)
			var g := w.npc(int(a.guard))
			if not n.report.is_empty() and g != null and g.alive and w.near(n.pos, float(GameData.b("witness_radius"))).has(g):
				w.deliver_report(n, g)
			return true
		"rest_end":                           # a rest that ran its course (PAR-03)
			n.anim = "idle"
			w.rest_recover(n, float(a.get("min", 0.0)), bool(a.get("morning", false)))
			return true
		"eat":
			for f in ([str(a.item)] if a.has("item") else (COOKED if a.get("cooked_only", false) else EDIBLE)):
				if n.inv.has(f):
					n.inv.remove(f)
					n.hunger = minf(100.0, n.hunger + float(GameData.item(f).food))
					w.stat("eaten_food", float(GameData.item(f).food))
					w.stat("eaten_" + f)
					return true
			return false
		"eat_home":
			var pantry: Inventory = w.households[n.household].pantry
			stock_family_chest(n)                    # FSE-18
			_cook_at_home(n, pantry)
			for f in EDIBLE:
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
				var ale := w.deal_price(w.sell_price(keeper, "ale"), n, keeper)
				if w.trade(n, keeper, "ale", 1, ale):
					w.deal_xp(n, keeper, ale)
					n.inv.remove("ale")
					n.hunger = minf(100.0, n.hunger + float(GameData.item("ale").food))
					w.stat("eaten_food", float(GameData.item("ale").food))
					w.stat("eaten_ale")
				# a supper with the ale (Build 13): a hungry drinker buys the tavern's bread or cheese, the best
				# plate for the coin (cheese as a treat), out of the keeper's own stock
				if n.hunger < float(GameData.b("tavern_supper_hunger")):
					var plate := _meal_choice(n, keeper, ["bread", "cheese"])
					var pp := w.deal_price(w.sell_price(keeper, plate), n, keeper) if plate != "" else 0
					if plate != "" and w.trade(n, keeper, plate, 1, pp):
						w.deal_xp(n, keeper, pp)
						n.inv.remove(plate)
						n.hunger = minf(100.0, n.hunger + float(GameData.item(plate).food))
						w.stat("eaten_food", float(GameData.item(plate).food))
						w.stat("eaten_" + plate)
			return true
		"build_front":
			return w.business.build_npc_front(w.buildings.get(n.home, {}), n)
		"build_stall":
			return w.business.stalls.npc_build(n, a)        # a household's market stall (STALL-06)
		"use_medicine":
			var from: Inventory = w.households[n.household].pantry if a.get("pantry", false) and n.household >= 0 else n.inv
			for m in MEDICINES:
				if from.has(m) and n.hp < n.max_hp:
					from.remove(m)
					n.hp = minf(n.max_hp, n.hp + float(GameData.item(m).heal))
					w.stat("npc_used_" + m)
					Skills.gain(n, "healing", Skills.action_xp("treat"))     # DVW-B8
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
			if not got.is_empty():                        # SEED-04: a cutting or seed by the player's rule, saved at home
				var cut := w.propagation_drop(pl)
				for id in cut:
					n.inv.add(id, int(cut[id]))
					w.stat("made_" + id, float(cut[id]))
			return not got.is_empty()
		"store_home":
			var pantry: Inventory = w.households[n.household].pantry
			for id in ["flower", "red_berries", "blueberries", "apple"] + Farming.propagule_items():
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
			if not pantry.has_all(rec["in"]) or w.work_craft(n, "brew_poultice", pantry).result != "ok":
				return false
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
			var fp := w.deal_price(w.sell_price(v, f), payer, v) if f != "" else 0
			if f != "" and w.trade(payer, v, f, 1, fp):
				w.deal_xp(payer, v, fp)
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
			var up := w.deal_price(w.sell_price(v, a.item), buyer, v)
			var for_need: bool = a.get("pantry", false) or World.is_necessity(a.item) or JOB_TOOL.get(buyer.job, "") == a.item
			while qty > 0 and not for_need and not w.can_afford(buyer, up * qty):
				qty -= 1                          # stock and materials: only what leaves the household's reserve (OD-19)
			while qty > 0 and not w.trade(buyer, v, a.item, qty, up):
				qty -= 1
			if qty > 0:
				w.deal_xp(buyer, v, up * qty)
			if qty > 0 and buyer != n:
				w.transfer(buyer.inv, n.inv, a.item, qty)
			if qty > 0 and a.get("pantry", false):
				w.transfer(n.inv, w.households[n.household].pantry, a.item, qty)
			return qty > 0
		"buy_seed":                                       # MERCH-01: a villager buys seed by the player's rule
			var v := w.npc(int(a.vendor))
			if v == null or not v.alive:
				return false
			return w.farm.buy_seed_item(v, str(a.item), mini(int(a.qty), v.inv.count(str(a.item))), n) == ""
		"contract_deliver":                                # CON-01: goods handed over on a contract, paid from the coins set aside
			return w.contracts.npc_deliver(n, int(a.id))
		"contract_sign":                                   # CON-01, Q18-13: a formal contract signed face to face
			return w.contracts.npc_sign(n, int(a.id))
		"svc_step":                                        # CON-02: a unit of a service contract's work, by its own system
			return w.contracts.svc_step(n, int(a.id))
		"buy_stall":
			return w.business.arrive(n, a)       # a villager at the player's market stall (PL1-10)
		"stall_stock":
			return w.business.stalls.npc_stock(n, a)        # the household's surplus into its stall, opened (STALL-06)
		"sell_to":
			var b := w.npc(int(a.buyer))
			if b == null or not b.alive:
				return false
			# TRADE-01: the business takes what World.purchase_qty allows, the player's rule, in one atomic sale
			var qty := w.purchase_qty(b, n, a.item, n.inv.count(a.item) - reserve(n, a.item))
			if qty <= 0:
				return false
			var paid := 0
			for c in w.sale_prices(b, n, a.item, qty):
				paid += int(c)
			if not w.trade(b, n, a.item, qty, 0, paid):
				return false
			w.deal_xp(b, n, paid)
			return true
		"mine":
			var d := w.deposit_at(Vector2i(int(a.x), int(a.y)), int(a.get("level", 0)))
			var r := w.work_mine(n, d, n.inv)                   # the player's swing (PAR-01)
			if r.result != "ok":
				return false
			if r.broke:
				w.note("%s %s's pickaxe broke." % [n.name, n.family])
			return true
		"chop":
			var t := w.tree_at(Vector2i(int(a.x), int(a.y)))
			t.erase("claimed")
			var logs := w.fell(t, int(Skills.value(n, "woodcutting", "log_bonus")))
			if logs <= 0:
				return false
			if w.work_felled(n, logs, n.inv).broke:           # the player's felling (PAR-01)
				w.note("%s %s's axe broke." % [n.name, n.family])
			return true
		"prospect":                                       # MIN-C: a rock sample from a clue's area, the player's rule
			return w.prospecting.npc_sample(n, a)
		"assay":                                          # MIN-C: the samples carried to a smith at the forge
			return w.prospecting.npc_assay(n, a)
		"assay_done":                                     # MIN-C: the smith's assay at the forge is over
			release_station(n, a.get("station", ""))
			return true
		"report_find":                                    # MIN-C: a prospector tells the manor of its finds
			return w.prospecting.report(n, int(a.id))
		"craft":
			release_station(n, a.get("station", ""))
			if a.has("biz"):
				return w.business.works.finish(n, a)       # B18-DP-01: the player's attendant at the player's own station
			return w.work_craft(n, a.recipe, n.inv).result == "ok"     # the player's crafting (PAR-01, PAR-04)
		"harvest":
			var f := _field(a.field)
			if f.is_empty() or not w.field_cuttable(f) or not w.quests.hired_on(f).is_empty():
				return false                                       # (left to the player hired to cut it)
			# FARM-08-Q-CROP + FARM-CROP-SEED (owner, 2026-10-22/23): the seed kept back and the rest of the crop belong to the
			# farmers who cut it, by their work (minutes x their own work rate, X18-D7), whoever finishes first; the others
			# stop cutting, their share in hand
			var shares := _cutting_shares(n, f, float(a.get("min", 90.0)))
			var taken := w.take_crop(f, 1 << 30)               # whatever is on the field (the shared model's cells' crop)
			var sp := w.farm.seed_pool(f, taken)
			var crop: int = int(sp.grain)
			var shared := Farming.shared_manor()
			var seed_split := Farming.split_crop(int(sp.pool), shares)
			if seed_split.is_empty() and int(sp.pool) > 0:
				seed_split[n.id] = int(sp.pool)
			var sids := seed_split.keys()
			sids.sort()
			for id in sids:
				var sc: NPC = n if int(id) == n.id else w.npc(int(id))
				var back := int(seed_split[id])
				var kept := w.farm.keep_seed(sc, back, shared)
				if not shared:
					crop += back - kept                        # seed that finds no room stays grain, as before
			# the farm's livestock is fed from the farm's crop: feed goes to the pen of any keeper
			# who shares this field before anything is shared out; the cutter carries it there
			var feed := 0
			for pid in w.fauna.pens:
				var pen: Dictionary = w.fauna.pens[pid]
				var need := w.fauna.daily_need(pen)
				var days := 1 if w.famine() else 4
				var keeper := w.pen_keeper(pen)
				if keeper and keeper.workplace == f.id and int(pen.trough) < need * days and need > 0:
					feed += mini(need * days - int(pen.trough), crop - feed)
					n.plan.push_front(work(15, "feed_pen", {"pen": pen.id, "qty": need * days - int(pen.trough)}, "work", Vector2i(int(pen.gate[0]), int(pen.gate[1]))))
					n.plan.push_front(go(Vector2i(int(pen.feed_at[0]), int(pen.feed_at[1]))))
			n.inv.add("wheat", feed)
			var split := Farming.split_crop(crop - feed, shares)
			if split.is_empty() and crop - feed > 0:
				split[n.id] = crop - feed
			var ids := split.keys()
			ids.sort()
			for id in ids:
				var c: NPC = n if int(id) == n.id else w.npc(int(id))
				c.inv.add("wheat", int(split[id]))
				if c.household >= 0:
					var pantry: Inventory = w.households[c.household].pantry
					var keep := maxi(0, 10 - pantry.count("wheat"))
					w.transfer(c.inv, pantry, "wheat", mini(keep, int(split[id])))
			w.set_field(f, "tilled")
			return true
		"sow":
			var f := _field(a.field)
			if f.is_empty() or f.state != "tilled" or (Farming.seasonal_fields() and not w.farm.can_sow_now()):
				return false
			if Farming.shared_manor() and w.farm.sow_field(n, f) <= 0:
				return false
			w.set_field(f, "growing")
			return true
		"hunt":
			var prey: Animal = w.fauna.by_id(int(a.animal))
			w.fauna.claims.erase(int(a.animal))
			if prey == null or prey.pos.distance_to(n.pos) > 3.0:
				return true            # it got away; the hunter picks another
			w.stat("hunted_" + prey.species)
			Skills.gain(n, "hunting", Skills.action_xp("hunt"))     # DVW-B8: the hunt trains Hunting, as the player's
			Skills.gain(n, "combat", Skills.kill_xp(prey.species, n.damage * Skills.value(n, "combat", "damage_mult", 1.0)))     # per kill, the player's rule (FSE-B12)
			var bag: Inventory = w.fauna.kill(prey)
			for id in bag.ids():
				n.inv.add(id, bag.count(id))
			return true
		"mj_step", "mj_mine":
			return w.manor_work.act(n, what, a)
		"mc_load", "mc_hitch", "mc_park", "mc_unload", "mc_place":
			return w.mine_works.cart_act(n, what, a)       # MIN-F2 (Q3): a miner's minecart haul
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
			w.stat("slaughter_%s_%s" % [str(a.get("why", "other")), beast.species])     # FARM-08B: why (famine, no_feed, surplus)
			Skills.gain(n, "combat", Skills.kill_xp(beast.species, n.damage * Skills.value(n, "combat", "damage_mult", 1.0)))     # as the player's kill (FSE-B12)
			var meat: Inventory = w.fauna.kill(beast)
			for id in meat.ids():
				n.inv.add(id, meat.count(id))
			return true
		"serve_counter":                      # a keeper's turn at a skilled trade's counter (CTR-02)
			return w.counters.served(n, str(a.counter))
		"camp_meal":                          # a clan child eats with the band (FAM-07), from the band's stores
			if band_eat(n):
				w.stat("clan_child_meals")
			return true
		"poach":
			if n.hunger < 60.0 and not band_eat(n) and w.rng.randf() < 0.25:
				var game: Animal = w.fauna.nearest_game(Vector2(w.bandit_camp), 30.0)
				if game != null:
					w.stat("poached_" + game.species)
					var bag: Inventory = w.fauna.kill(game)          # carried to the camp, then cooked and eaten
					for id in bag.ids():
						n.inv.add(id, bag.count(id))
					band_eat(n)
			return true
		"recover_loot":
			for l in w.loot:
				if int(l.coins) > 0 and n.pos.distance_to(l.pos) < 1.6 and World.level_of(l) == 0:
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
			var foe := _bandit_seen(n)
			if foe:
				n.target = foe.id
			return true
		"helper_take", "helper_buy", "helper_own", "helper_deliver":
			return w.construction.act(n, what, a)
		"church_ask":                           # DVW-B3-CHAPEL: asking the church for food
			return w.chapel.ask(n)
		"fp_work", "fp_fence":                  # FARM-02..04: work on the family's farmland (FarmPlots)
			return w.farm_plots.act(n, what, a)
	return true


# ---------------------------------------------------------------- fighting -------------------
func fight(n: NPC, dt: float) -> void:
	if w.recorder != null:
		w.recorder.chase_tick(n)      # SIM-GATE-01: a chase opens when the target is new (reads only)
	var tpos: Vector2
	var tdead := false
	var tnpc: NPC = null
	if Life.is_player_id(n.target):
		tpos = w.player.pos
		tdead = not w.player.alive or w.player_level != n.depth        # MIN-A: rock between them
	else:
		tnpc = w.npc(n.target)
		# gone, or into a building the fighter is not in (a door between them); a sleeper is still
		# a target (owner rule: sleeping is not immunity) and wakes when struck; or on another level (MIN-A)
		if tnpc == null or not tnpc.alive or (w.place_of(tnpc.pos) != "" and w.place_of(tnpc.pos) != w.place_of(n.pos)) or tnpc.depth != n.depth:
			tdead = true
		else:
			tpos = tnpc.pos
	if tdead or (n.role == "bandit" and n.hp < n.max_hp * 0.3):
		if w.recorder != null:
			w.recorder.chase_end(n, "target_gone" if tdead else "bandit_low_hp")      # SIM-GATE-01
		n.target = -1
		n.plan.clear()
		if n.role == "bandit":
			n.plan = [go(w.bandit_camp, 1.2)]
		return
	var d := tpos - n.pos
	if d.length() > 25.0 or (n.job == "guard" and tpos.distance_to(Vector2(w.bandit_camp)) < 12.0):
		if w.recorder != null:
			w.recorder.chase_end(n, "out_of_range" if d.length() > 25.0 else "near_bandit_camp")      # SIM-GATE-01
		n.target = -1
		n.plan.clear()
		return
	n.facing = d
	if d.length() > 1.1:
		n.anim = "walk"
		n.pos += d.normalized() * minf(d.length() - 0.9, float(GameData.b("walk_tiles_per_second")) * 1.3 * dt)
		if w.map.is_solid(n.cell()):
			n.pos -= d.normalized() * float(GameData.b("walk_tiles_per_second")) * 1.3 * dt
			# SIM-F4 (recorder run 2): the chase walks straight at the target, so a wall or fence between them held the
			# chaser on the spot for good, never deciding again (bandits starved stalking). A blocked chase is given up as
			# one whose target is gone.
			if w.recorder != null:
				w.recorder.chase_end(n, "blocked")      # SIM-GATE-01: the corner case (GP-CRIME-PURSUIT)
			n.target = -1
			n.plan.clear()
			if n.role == "bandit":
				n.plan = [go(w.bandit_camp, 1.2)]
		return
	if n.attack_cd > 0.0:
		return
	n.attack_cd = 1.0 * Skills.value(n, "combat", "attack_time", 1.0)     # the player's Combat rule (PAR-01)
	if w.recorder != null:
		w.recorder.chase_strike(n)      # SIM-GATE-01
	n.anim = "sword"
	n.plan = []
	if w.judgment != null:
		w.judgment.note_blow(n.id, n.target)        # X19-EVENT-Q: who struck first in this fight, so an answer is not judged as an attack
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
		if w.recorder != null:
			w.recorder.robbery(n, tnpc, take, stolen)      # REC-19
		var aware: Dictionary = w.aware_of_attack(n.pos, tnpc)
		if w.judgment != null:
			JudgmentLive.on_robbery(w, n, tnpc, take + (GameData.value(stolen) if stolen != "" else 0), aware)    # PROSPECTIVE (PROS-19)
		w.raise_alarm(aware, n.id)       # who sees it; the victim reports it (PAR-05)
		w.note("%s robbed %s %s of %d coins%s." % [n.name, tnpc.name, tnpc.family, take,
			(" and a " + GameData.item_name(stolen).to_lower()) if stolen != "" else ""])
		if w.recorder != null:
			w.recorder.chase_end(n, "robbed")      # SIM-GATE-01
		n.target = -1
		n.plan = [go(w.bandit_camp, 1.2)]
		return
	var dmg := w.npc_blow(n)
	Skills.gain(n, "combat", 4)                        # a blow at a person: the player's 4 xp (PAR-01)
	if Life.is_player_id(n.target):
		# the death screen names who struck: "Wat the guard", "Rob the bandit", or just the name
		var who := n.job if n.job != "" else ("bandit" if n.role == "bandit" else "")
		w.damage_player(dmg, n.name + (" the " + who if who != "" else ""))
	else:
		w.harm_npc(tnpc, dmg)
		w.wake_near(tnpc.pos, float(GameData.b("sleep_wake_radius")))    # the blow wakes them, and the noise others
		if tnpc.target == -1:
			tnpc.target = n.id
		if n.role == "bandit":
			w.raise_alarm(w.aware_of_attack(n.pos, tnpc), n.id)   # who sees it; the victim reports it (PAR-05)
		if tnpc.hp <= 0.0:
			w.kill(tnpc, "slain by %s" % n.name)
			if w.judgment != null and tnpc.role != "bandit":
				JudgmentLive.on_killing(w, tnpc, n.id)         # PROSPECTIVE (PROS-19): a villager's killing
			if w.recorder != null:
				w.recorder.chase_end(n, "target_slain")      # SIM-GATE-01
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
	var rec_pass: int = w.recorder.pass_begin("reeve_day") if w.recorder != null else 0      # REC-19: tax, relief, tools, works, granary are its children
	update_market()
	_reeve_succession()
	_guard_posts()
	var obligations := daily_obligations()
	var reserve := obligations * float(GameData.b("treasury_reserve_days"))
	var taxed := 0
	var tax := TaxPolicy.step(w.tax_state, float(w.treasury), obligations, w.day())   # DVW-B5: banded, announced
	for line: String in tax.notes:
		w.note(line)
	var rate := float(tax.rate)
	if rate > 0.0:
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
				if w.recorder != null:
					w.recorder.manor_flow("tax", o, take, true)      # REC-19
	# relief first (it is bought before anything optional), then repairs and the granary
	var relief := _relief(obligations, reserve)
	var tools := _support_trades(obligations)        # tools for the essential trades come before optional spending (EQ-19)
	var budget := int(maxf(0.0, w.treasury - 3.0 * obligations) * float(GameData.b("repairs_budget_share")))
	var bought := 0
	# stone for the works from the village's own seams, when the yard lacks it (a job for the reeve's list)
	if budget > 0:
		w.manor_work.post_quarry()
	w.manor_work.post_discovery()                    # MIN-D: a survey or a trial pit, as the village's mining capability allows
	w.manor_work.post_pits()                         # MIN-E: a load of the manor's open pit, or a pit staked for a find out of a trial's reach
	w.manor_work.post_tunnels()                      # MIN-F2: a load cut at a supported face below ground, while the works lack stone
	w.mine_works.supply.procure()                    # MIN-EQUIP: the supports, repair goods, ladders and mallet its shore work needs
	w.manor_work.post_shore()                        # MIN-EQUIP: set up, repair or ladder below ground, with the yard's goods
	var quarrying: bool = w.manor_work.jobs.any(func(j): return j.kind == "quarry")
	for id in ["plank", "stone", "rubble", "log", "iron_bar"]:          # iron bars: fittings and nails, from the smiths; rubble (STONE-04) mends as stone does
		if id == "stone" and quarrying:
			continue                          # the manor's own stone is being quarried
		for o: NPC in w.npcs:
			if not o.alive or not (o.job in ["carpenter", "laborer", "smith", "stonecutter"] or buy_role(o) == "merchant_raw"):
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
				if w.recorder != null:
					w.recorder.manor_flow("repairs", o, price, false)      # REC-19
	var works := _public_works(obligations)
	var grain := 0
	var target := int(village_day_food() * float(GameData.b("granary_target_days")) / food_points("wheat"))
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
				if w.recorder != null:
					w.recorder.manor_flow("granary", o, price, false)      # REC-19
				w.stat("gov_granary_in", 1)
	if tools > 0:
		w.note("The manor spent %d coins keeping the village's workers in tools." % tools)
	if taxed + bought + grain + relief > 0:
		w.note("The manor took %d coins in tax, bought %d loads for repairs and %d grain for the granary, and gave %d households food." % [taxed, bought, grain, relief])
	if works > 0:
		w.note("The manor bought %d loads of planks, iron and stone for its public works." % works)
	w.manor_work.refresh()
	if w.recorder != null:
		w.recorder.pass_end(rec_pass, "tax=%d repairs_loads=%d granary_grain=%d households_helped=%d tools=%d works_loads=%d" % [taxed, bought, grain, relief, tools, works])      # REC-19


## EQ-04 (owner, 2026-10-19: "When leadership changes, government should continue"). The manor's business (tax, relief,
## wages) never needed the reeve, but public works wait for one, and before this a dead reeve was never replaced. The
## office is handed on by the succession of posts the trades use (B8-016: succession_dawn, succession_caravan): when the
## reeve is dead or gone, the evening's business opens the post (World.vacancies, saved); after `succession_days` an
## adult without a trade takes it (the late reeve's household first), else a newcomer comes with the caravan, at the latest
## `newcomer_max_days` on. The evening after, the new reeve takes up the office (World.reeve_id, the manor). The choice of
## successor is the trades' rule, used until the owner sets one for the office (an open policy question).
func _reeve_succession() -> void:
	var rv := w.npc(w.reeve_id)
	if rv != null and rv.alive and rv.job == "reeve":
		return
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "reeve" and (rv == null or o.id != rv.id):
			w.reeve_id = o.id
			o.workplace = "manor"
			w.stat("reeve_successions")
			w.note("%s %s is the new reeve: the manor's business goes on." % [o.name, o.family])
			return
	if open_posts("reeve") > 0:
		return
	var who := "%s %s" % [rv.name, rv.family] if rv != null else "the reeve"
	w.vacancies.append({"job": "reeve", "workplace": "manor", "home": rv.home if rv != null else "", "household": rv.household if rv != null else -1,
			"day": w.day(), "who": who, "heir": -1})
	if w.recorder != null:
		w.recorder.vacancy_opened(w.vacancies[-1], "the reeve's office")      # REC-19
	w.note("The office of reeve, left by %s, is open: someone of the village or a newcomer will take it." % who)


## EQ-04: the watch is kept at the strength the village began with (Population.JOBS.guard). Guards are not a trade
## (nobody takes the post up by the job market), so a post left by a dead guard was never filled. Each evening, while
## the watch is short and the treasury can pay one more guard as it pays a new manor hand (above its reserve,
## `treasury_reserve_days`, with `manor_hire_runway_days` of the wage to spare: the hiring line the job board uses), one
## guard's post opens in World.vacancies and the succession of posts fills it as a trade's (an adult without a trade,
## else a caravan newcomer). The new guard takes the thinner shift and a guard's training (_take_guard_post); the sword
## and armour come from the late guard's heir or household when one holds them spare (_install), or a newcomer brings
## them; nothing else is given.
func _guard_posts() -> void:
	var missing := int(Population.JOBS.guard) - living_in("guard") - open_posts("guard")
	if missing <= 0:
		return
	var obligations := daily_obligations()
	var reserve := obligations * float(GameData.b("treasury_reserve_days"))
	var wage := float(GameData.b("guard_wage_per_day"))
	if float(w.treasury) - reserve < wage * float(GameData.b("manor_hire_runway_days")):
		w.stat("guard_post_unaffordable")
		return
	w.vacancies.append({"job": "guard", "workplace": _guard_shift(null), "home": "", "household": -1, "day": w.day(),
			"who": "a guard of the watch", "heir": -1})
	w.stat("guard_posts_opened")
	if w.recorder != null:
		w.recorder.vacancy_opened(w.vacancies[-1], "the watch is %d short" % missing)      # REC-19
	w.note("The manor opens a guard's post: the watch is %d short." % missing)


## The shift with fewer guards on it ("day" first when equal), not counting `except`.
func _guard_shift(except: NPC) -> String:
	var day := 0
	var night := 0
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard" and o != except:
			if o.workplace == "day":
				day += 1
			elif o.workplace == "night":
				night += 1
	return "day" if day <= night else "night"


## A guard new to the post (EQ-04: taken up through the succession of posts) gets its shift and a guard's training
## (Population.GUARD_STATS), never below what they already have. Nothing is given but the training.
func _take_guard_post(n: NPC) -> void:
	if n.workplace == "day" or n.workplace == "night":
		return
	n.workplace = _guard_shift(n)
	var g: Dictionary = Population.GUARD_STATS
	n.max_hp = maxf(n.max_hp, float(g.hp))
	n.damage = maxf(n.damage, float(g.damage))
	n.armor = maxf(n.armor, float(g.armor))
	w.stat("guards_taken_on")


## OD-16 (b), EQ-19 (owner 2026-10-20: "the manor uses its treasury to keep the smithy and woodlands working: it buys
## iron and tools for the village's workers, or lends to the smith against future output"). Each evening, for every
## worker short of their trade's tool (tool_needers: a woodcutter without an axe, a miner without a pickaxe, a builder of
## the household's own home without an axe), in id order: a tool on sale at the goods merchant's or the smith's is
## bought from the treasury and handed to them; with none on sale, a smith is paid its worth in advance
## (World.manor_orders, at most `manor_orders_per_smith` open each), which buys the forge's ore and coal, and the tool
## goes to the worker when it is forged (_deliver_orders); an order not met within `manor_order_days` lapses. The treasury keeps `manor_support_floor_days` of its
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
			if w.recorder != null:
				w.recorder.manor_flow("tools", seller, price, false)      # REC-19
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
		if w.recorder != null:
			w.recorder.manor_flow("tools", smith, advance, false)      # REC-19
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
## to the next worker short of that tool); an order whose smith has died or left the trade, or that is older than
## `manor_order_days`, lapses, so its worker is counted short of the tool again and may seek other work.
func _deliver_orders() -> void:
	for x in w.manor_orders.duplicate():
		var smith := w.npc(int(x.smith))
		if smith == null or not smith.alive or smith.job not in ["smith", "carpenter"] or w.day() - int(x.day) > int(GameData.b("manor_order_days")):
			w.manor_orders.erase(x)                   # (an order not met in time lapses: its worker is free to seek other work)
			w.stat("gov_tool_order_lapsed")
			continue
		var tool := str(x.tool)
		if not smith.inv.has(tool):
			continue
		if int(x["for"]) == -1:                       # MIN-EQUIP: ordered for the manor's works yard
			smith.inv.remove(tool)
			w.manor_work.yard.add(tool)
			w.manor_orders.erase(x)
			w.stat("gov_equipment_delivered_" + tool)
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
	for id in ["plank", "iron_bar", "stone", "rubble"]:
		for o: NPC in w.npcs:
			if not o.alive or not o.job in ["carpenter", "smith", "merchant", "laborer", "stonecutter"] or w.asleep(o):
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
				if w.recorder != null:
					w.recorder.manor_flow("works", o, price, false)      # REC-19
	return used


## Food relief into household pantries. Returns how many households were helped.
func _relief(obligations: float, reserve: float) -> int:
	var helped := 0
	# the hungriest first (B7-015: helped in the order of their number, a household with no food at all waited behind
	# others still holding most of two days, and went without when the food for sale ran out before its turn)
	var order := []
	for h in w.households.size():
		if not _members(h).is_empty():
			var d := household_food_days(h)
			if d < float(GameData.b("relief_trigger_days")):
				order.append([d, h])
	order.sort_custom(func(x, y): return x[0] < y[0] or (x[0] == y[0] and x[1] < y[1]))
	for e in order:
		var h: int = e[1]
		var days: float = e[0]
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
		var want := ceili(need / food_points("wheat"))
		var held := 0
		for inv: Inventory in household_stores(h):
			held += inv.count("wheat")
		want += (held + want) % pottage_batch()          # whole pots: with what the household holds, grain to cook
		var wheat := mini(want, w.granary.count("wheat"))
		if urgent and wheat < want:
			# the manor's grain still at the farmers' for the granary goes straight to them
			var sent := w.manor_work.take_bound("granary", "wheat", want - wheat, pantry)
			need -= sent * food_points("wheat")
			held += sent
			w.stat("gov_relief_grain", sent)
		if wheat > 0:
			if urgent:
				w.transfer(w.granary, pantry, "wheat", wheat)
			else:
				w.manor_work.consign(w.granary, w.manor_work.yard_cell(), "wheat", wheat, {"kind": "pantry", "hh": h}, "relief", "the manor's granary")
			need -= wheat * food_points("wheat")
			held += wheat
			w.stat("gov_relief_grain", wheat)
		# TREAS-01: the manor's other food in its granary (a house's stores fallen to the manor, Property.household_ended,
		# or carried back from an ended household's work) is its own stock as much as the grain: it is given before any
		# coin is spent buying food (before, it was counted in the village's food days but never given out)
		if need > 0.0:
			need -= _relief_from_granary(h, need, urgent)
		# what the granary cannot give, the manor buys for the household: an emergency (under a day of
		# food) may spend down to one day of wages, otherwise only money above the reserve
		var floor_coins := obligations if days < 1.0 else reserve
		var offers := _relief_offers(h) if need > 0.0 else []
		var k := 0
		while need > 0.0 and k < offers.size():
			var o: Dictionary = offers[k]
			var src: Inventory = o.inv
			if int(o.left) <= 0 or not src.has(o.item):
				k += 1
				continue
			var qty := 1
			if o.item == "wheat":                # grain in whole pots, with what the household holds (store_points)
				qty = mini(pottage_batch() - held % pottage_batch(), mini(int(o.left), src.count("wheat")))
			var price: int = (w.sell_price(o.payee, o.item) if bool(o.trader) else int(o.price)) * qty
			if w.treasury - price < floor_coins:
				break
			# TREAS-01 (owner, 2026-10-21: "The purchased goods become actual manor inventory. The manor can then use
			# legitimately owned supplies through the existing relief system"): what is bought becomes the manor's before it
			# is given; an emergency's goes through the granary at once, a carried one waits in the manor's lot
			var moved := false
			if urgent and pantry.can_add(o.item):
				moved = w.transfer(src, w.granary, o.item, qty) and w.transfer(w.granary, pantry, o.item, qty)
			elif not urgent:
				moved = w.manor_work.consign(src, o.cell, o.item, qty, {"kind": "pantry", "hh": h}, "relief", o.words)
			if not moved:
				k += 1                           # nothing changed hands, so nothing is paid
				continue
			var payee: NPC = o.payee
			payee.coins += price
			payee.earned += price
			w.treasury -= price
			o.left = int(o.left) - qty
			need -= float(o.pts) * qty
			if o.item == "wheat":
				held += qty
			w.stat("gov_relief_bought", price)
			if w.recorder != null:
				w.recorder.manor_flow("relief", payee, price, false)      # REC-19
			w.stat("gov_relief_bought_" + str(o.item), qty)
		if need < (float(GameData.b("relief_fill_days")) - days) * household_day_food(h):
			helped += 1
			_note_relief(h)
	return helped


## TREAS-01: relief from the manor's own food other than grain (the granary's grain is given first, in whole pots, by
## _relief): every edible the granary holds, in EDIBLE's order, up to `need` points for household `h`; given at once in an
## emergency, else left at the manor's door for its carriers. Nothing is bought. Returns the food points given.
func _relief_from_granary(h: int, need: float, urgent: bool) -> float:
	var given := 0.0
	var pantry: Inventory = w.households[h].pantry
	for f in EDIBLE:
		var pts := food_points(f)
		if f == "wheat" or pts <= 0.0 or need - given <= 0.0 or not w.granary.has(f):
			continue
		var n := mini(w.granary.count(f), ceili((need - given) / pts))
		var ok := w.transfer(w.granary, pantry, f, n) if urgent else \
				w.manor_work.consign(w.granary, w.manor_work.yard_cell(), f, n, {"kind": "pantry", "hh": h}, "relief", "the manor's granary")
		if ok:
			given += float(n) * pts
			w.stat("gov_relief_stock", n)
			w.stat("gov_relief_stock_" + f, n)
	return given


## FSE-17 (owner, 2026-10-20: "Relief should check all possible food stores"): what relief can buy for household `h`
## after the granary and the manor's grain, cheapest food point first. Every food seller's edible stock (the tavern, the
## cook, the food merchant; farmers' grain beyond what they keep, and their pens' eggs and milk); raw meat from hunters
## and keepers when `h` has the logs to roast it; and other households' food beyond what they need for themselves over
## the reserve horizon (OD-19's reserve_days), at its base value, paid to that household. Each offer: {inv, item, left,
## pts, price, trader, payee, cell, words}. Bought, never made: everything comes out of someone's store, paid for.
func _relief_offers(h: int) -> Array:
	var out := []
	var logs := 0
	for inv: Inventory in household_stores(h):
		logs += inv.count("log")
	for o: NPC in w.npcs:
		if not o.alive or o.household == h or o.role == "bandit" or w.asleep(o):
			continue
		var food_seller := o.job in ["tavernkeeper", "cook"] or buy_role(o) == "merchant_food"
		for f in EDIBLE + ["meat"]:
			var n := 0
			if f == "wheat":
				n = surplus_wheat(o) if o.job == "farmer" or food_seller else 0
			elif f == "meat":
				n = mini(o.inv.count("meat"), logs) if o.job in ["hunter", "farmer"] or food_seller else 0
			elif food_seller or (o.job == "farmer" and f in ["egg", "milk"]):
				n = o.inv.count(f)
			if n > 0:
				out.append({"inv": o.inv, "item": f, "left": n, "pts": food_points(f), "price": w.sell_price(o, f), "trader": true,
					"payee": o, "cell": _workplace_cell(o) if o.workplace != "" else _store_cell(o.home, o), "words": _seller_words(o)})
	for h2 in w.households.size():
		var mem := _members(h2)
		if h2 == h or mem.is_empty():
			continue
		var spare := store_points([w.households[h2].pantry]) - household_day_food(h2) * float(GameData.b("reserve_days"))
		var head := _richest_in_household(mem[0])
		if spare <= 0.0 or head == null:
			continue
		for f in EDIBLE:
			var c: int = w.households[h2].pantry.count(f)
			var n := mini(c, floori(spare / maxf(1.0, food_points(f))))
			if n > 0:
				out.append({"inv": w.households[h2].pantry, "item": f, "left": n, "pts": food_points(f), "price": GameData.value(f), "trader": false,
					"payee": head, "cell": _store_cell(str(w.households[h2].home), head), "words": "the %s household's" % str(w.households[h2].get("family", ""))})
				spare -= float(n) * food_points(f)
	out.sort_custom(func(x, y): return float(x.price) / float(x.pts) < float(y.price) / float(y.pts))
	return out


## Where relief's carriers collect from a store kept at `home`: its door, or where `o` stands when the home is not one of
## the village's buildings (a household between homes; 634 script errors in a year run before, each one ending that
## evening's relief).
func _store_cell(home: String, o: NPC) -> Vector2i:
	return w.building_door(home) if w.buildings.has(home) else o.cell()


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
		keep += reserve(o, "wheat") + ceili(household_day_food(o.household) * float(GameData.b("granary_keep_household_days")) / food_points("wheat"))
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
## What one `id` is worth as food to a household (FSE-17, and the one valuation the village's food days, a household's
## days and reserve, and relief all use): its food as eaten, except wheat, which a household cooks into pottage at its
## hearth (cook_pottage: 2 wheat make 6 pottage, 120 points a wheat; raw it is 20), and meat, roasted at the hearth with a
## log (roast_meat: 1 meat and 1 log make 2 roast meat, 120 points).
static func food_points(id: String) -> float:
	var r: Dictionary = {}
	if id == "wheat":
		r = GameData.recipes["cook_pottage"]
	elif id == "meat":
		r = GameData.recipes["roast_meat"]
	if r.is_empty():
		return float(GameData.item(id).get("food", 0))
	var out: String = r.out.keys()[0]
	return float(r.out[out]) * float(GameData.item(out).food) / float(r["in"][id])


## The food points in `stores` (inventories): everything edible, grain as cooked, and raw meat as roasted for as many
## logs as the stores hold (FSE-17: a household's food is reckoned from all it holds).
static func store_points(stores: Array) -> float:
	var pts := 0.0
	var meat := 0
	var logs := 0
	var wheat := 0
	for inv: Inventory in stores:
		for f in EDIBLE:
			if f != "wheat":
				pts += float(inv.count(f)) * food_points(f)
		meat += inv.count("meat")
		logs += inv.count("log")
		wheat += inv.count("wheat")
	# grain is worth its pottage only in whole pots (2 wheat); an odd grain is eaten raw (B7-015, seed 4: a lone
	# elder starved on one relief grain a day, valued as cooked, which no pot could be made from)
	var odd := wheat % pottage_batch()
	return pts + float(wheat - odd) * food_points("wheat") + float(odd) * float(GameData.item("wheat").food) \
		+ float(mini(meat, logs)) * food_points("meat")


## The wheat one pot of pottage takes (the hearth's cook_pottage).
static func pottage_batch() -> int:
	return int(GameData.recipes["cook_pottage"]["in"].wheat)


## A household's stores: its pantry and what each member carries.
func household_stores(h: int) -> Array:
	var stores: Array = [w.households[h].pantry]
	for o: NPC in _members(h):
		stores.append(o.inv)
	return stores


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
			n += float(manor_hand_wage())
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
	var pts := store_points(household_stores(h))     # all it holds, members' pockets included (FSE-17)
	var members := _members(h)
	var cash := 0
	for o: NPC in members:
		cash += o.coins
	var need := household_day_food(h)
	var share := market_food_points * need / maxf(1.0, village_day_food())
	# coins count only for the food they can buy now: whole units of the cheapest food on sale (a household with 2
	# coins when a meal costs 3 can buy nothing; valuing a coin at a fixed 60 points let such households starve
	# while the relief rule saw days of food)
	var unit: Array = w.cheapest_food_unit()
	if int(unit[0]) > 0:
		pts += minf(float(cash / int(unit[0])) * float(unit[1]), share)
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
			for f in EDIBLE:
				if f != "wheat":                  # grain counts below, beyond what the seller keeps
					pts += o.inv.count(f) * food_points(f)
		if o.job == "farmer" or buy_role(o) == "merchant_food":
			pts += surplus_wheat(o) * food_points("wheat")
			if o.inv.count("wheat") >= 2:
				var p := w.sell_price(o, "wheat")
				if cheapest == 0 or p < cheapest:
					cheapest = p
	market_food_points = pts
	if cheapest > 0:
		market_wheat_price = cheapest


## Wages from the treasury: the sage, the reeve, the guards and the manor's hands.
func pay_guards() -> void:
	var rec_pass: int = w.recorder.pass_begin("pay_guards") if w.recorder != null else 0      # REC-19: wages and layoffs are its children
	var sage := w.npc(w.sage_id)
	if sage and sage.alive and w.treasury >= 4:
		w.treasury -= 4
		sage.coins += 4
		sage.earned += 4
		w.stat("gov_wages", 4)
		if w.recorder != null:
			w.recorder.manor_flow("wage", sage, 4, false)      # REC-19
	var rv := w.npc(w.reeve_id)
	var rw := int(GameData.b("reeve_wage_per_day"))
	if rv and rv.alive and w.treasury >= rw:
		w.treasury -= rw
		rv.coins += rw
		rv.earned += rw
		w.stat("gov_wages", rw)
		if w.recorder != null:
			w.recorder.manor_flow("wage", rv, rw, false)      # REC-19
	var wage := int(GameData.b("guard_wage_per_day"))
	for o: NPC in w.npcs:
		if o.alive and o.job == "guard":
			if w.treasury >= wage:
				w.treasury -= wage
				o.coins += wage
				o.earned += wage
				w.stat("gov_wages", wage)
				if w.recorder != null:
					w.recorder.manor_flow("wage", o, wage, false)      # REC-19
			else:
				if w.recorder != null:
					w.recorder.wage_unpaid("guard " + str(o.id))      # REC-19
				once("unpaid_%d" % w.day(), "The manor cannot pay the guards today.")
	var hand_wage := manor_hand_wage()
	if w.treasury < 2.0 * daily_obligations():
		# the manor cannot keep everyone on: the most recently hired hand is let go
		var last: NPC = null
		for o: NPC in w.npcs:
			if o.alive and o.job == "manor_hand" and (last == null or o.job_since > last.job_since or (o.job_since == last.job_since and o.id > last.id)):
				last = o
		if last:
			_change_job(last, "", "the manor can no longer pay its hands")
			if w.recorder != null:
				w.recorder.layoff(last)      # REC-19
	for o: NPC in w.npcs:
		# a hand hired out for the day to carry building materials was paid by the employer
		if o.alive and o.job == "manor_hand" and w.construction.contract_of(o).is_empty():
			if w.treasury >= hand_wage:
				w.treasury -= hand_wage
				o.coins += hand_wage
				o.earned += hand_wage
				w.stat("gov_wages", hand_wage)
				if w.recorder != null:
					w.recorder.manor_flow("wage", o, hand_wage, false)      # REC-19
			else:
				if w.recorder != null:
					w.recorder.wage_unpaid("manor hand " + str(o.id))      # REC-19
				once("unpaid_hands_%d" % w.day(), "The manor cannot pay its hands today.")
	if w.recorder != null:
		w.recorder.pass_end(rec_pass)      # REC-19


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
	var cost := need / food_points("wheat") * market_wheat_price + float(GameData.value("log"))
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
	var wage := float(manor_hand_wage())
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
	var game: int = w.fauna.takeable_game()        # FSE-B09: only what hunters may take
	market["hunter"] = {"pay": avg.call("hunter", 0.0), "open": maxi(0, game / int(GameData.b("game_per_hunter")) - count.call("hunter")),
		"tool": "", "at": Vector2i(15, 15)}
	var ore := 0
	for dp in w.deposits:
		if w.villagers_reach(dp):          # MIN-A: ore on a level no villager can reach yet opens no places
			ore += int(dp.amount)
	ore += w.quarry_stone_left()            # MIN-B: the stone left to quarry is work too
	market["miner"] = {"pay": avg.call("miner", 0.0), "open": maxi(0, ore / int(GameData.b("ore_per_miner")) - count.call("miner") - count.call("laborer")),
		"tool": "pickaxe", "at": Vector2i(w.map.data.mine.yard[0], w.map.data.mine.yard[1])}
	market["prospector"] = w.discovery.prospector_place(avg.call("prospector", 0.0))     # MIN-D: adoption by the job rules
	market["stonecutter"] = stonecutter_place(avg.call("stonecutter", 0.0))               # X18-STONECUT: adoption by the job rules
	for sj in Population.SERVICE_JOBS:
		market[sj] = service_place(sj)
	for cj in Population.CLERGY:
		market[cj] = w.chapel.place(cj)             # DVW-B3-CHAPEL: the clergy's places, open when nobody holds them
	return market


## X18-STONECUT: the stonecutter's place in the labour market. One place, open while nobody living cuts stone for a living,
## blocks are wanted (_block_demand: the raw-goods merchant buys them or open sites need more than anyone holds) and raw
## stone is on sale to buy (a raw-goods merchant holds enough for a batch). The pay is what stonecutters have earned a day,
## else the manor's day wage; the trade's tool, the iron chisel, is the setup a villager weighs (seek_work). Nothing is
## promised: the place is a chance, and a stonecutter whose blocks do not sell is paid nothing and moves on as any other.
func stonecutter_place(avg_pay: float) -> Dictionary:
	var open := 0
	var stone := int(GameData.recipes["dress_stone"]["in"]["stone"])
	if living_in("stonecutter") == 0 and _blocks_wanted() and _with_buy_role("merchant_raw").any(func(v: NPC) -> bool: return v.inv.count("stone") >= stone):
		open = 1
	var at := Vector2i.ZERO
	var benches := w.stations_of("workbench")
	if not benches.is_empty():
		at = w.station_use(benches[0])
	return {"pay": avg_pay if avg_pay > 0.0 else float(GameData.b("manor_wage_per_day")), "open": open, "tool": "chisel", "at": at}


## X18-STONECUT: whether anyone would buy building blocks now, whoever dresses them (the raw-goods merchant has room and
## coins for them, or the open sites need more than the village's labourers and merchants hold).
func _blocks_wanted() -> bool:
	for v: NPC in _with_buy_role("merchant_raw"):
		if wants(v, "building_block") > 0 and v.coins > w.reserve_of(v):
			return true
	var held := 0
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and (o.job in ["laborer", "stonecutter"] or buy_role(o) == "merchant_raw"):
			held += o.inv.count("building_block")
	return w.construction.open_need("building_block") > held


## WDR-012-C hiring competition (owner B18-DP-08). The manor's day wage for a hand: the established wage plus the raise it
## has had to offer to fill its places (World.wage_offers). Every hand is paid the same, the treasury pays it, and the
## manor takes on only as many as its treasury can pay at that wage (job_market), so a raise never breaks the books.
func manor_hand_wage() -> int:
	return int(GameData.b("manor_wage_per_day")) + int((w.wage_offers.get("manor_hand", {}) as Dictionary).get("raise", 0))


## Called at the end of each morning's seek_work with the places the manor still has open and how many villagers looked for
## work that morning and did not take them. Places that stay open `unfilled_days` mornings with seekers about raise the
## offer one step (up to `raise_max`); places that are filled `unfilled_days` mornings in a row ease it one step. The
## seekers choose by the ordinary job-switch rule, now with the better pay in the score.
func _hiring_competition(open_left: int, seekers: int) -> void:
	var cfg: Dictionary = GameData.b("hiring_competition")
	var o: Dictionary = (w.wage_offers.get("manor_hand", {"raise": 0, "short": 0, "met": 0}) as Dictionary).duplicate()
	var raise0 := int(o.raise)
	if open_left > 0 and seekers > 0:
		o.short = int(o.short) + 1
		o.met = 0
		if int(o.short) >= int(cfg.unfilled_days) and int(o.raise) < int(cfg.raise_max):
			o.raise = int(o.raise) + int(cfg.raise_step)
			o.short = 0
			w.stat("wage_offers_raised")
			if w.recorder != null:
				w.recorder.wage_offer("raised", raise0, int(o.raise), open_left, seekers)      # REC-19
			w.note("The manor cannot fill its places and offers its hands %d coins a day." % (int(GameData.b("manor_wage_per_day")) + int(o.raise)))
	elif open_left <= 0 and int(o.raise) > 0:
		o.met = int(o.met) + 1
		o.short = 0
		if int(o.met) >= int(cfg.unfilled_days):
			o.raise = maxi(0, int(o.raise) - int(cfg.raise_step))
			o.met = 0
			w.stat("wage_offers_eased")
			if w.recorder != null:
				w.recorder.wage_offer("eased", raise0, int(o.raise), open_left, seekers)      # REC-19
	if int(o.raise) > 0 or int(o.short) > 0 or int(o.met) > 0 or w.wage_offers.has("manor_hand"):
		w.wage_offers["manor_hand"] = o


## WDR-012-C relocation (owner B18-DP-08): a merchant whose household is not living on the stall (the same test that sends
## a villager looking for other work) moves to a vacant stall of the manor's market, of the same kind (their stock suits it),
## where what they hold would fetch clearly more under the local supply there (World.local_supply: fewer rivals within the
## radius, a dearer price) by the job-switch margin. Their old stall is let again as any vacant one (Property.relet_stalls).
## NPC villagers only: the player decides for themselves where to trade, under the same prices.
func _relocate_stall(n: NPC) -> bool:
	if not w.stalls.has(n.workplace) or w.tenant_of(w.stalls[n.workplace]) != World.npc_ref(n.id):
		return false
	var cur: Dictionary = w.stalls[n.workplace]
	var best := ""
	var best_value := stall_value(n, cur) * float(GameData.b("job_switch_margin"))
	var ids: Array = w.stalls.keys()
	ids.sort()
	for sid in ids:
		var s: Dictionary = w.stalls[sid]
		if Business.is_pitch(s) or s.get("built", false) or str(s.get("kind", "")) != str(cur.kind) or w.tenant_of(s) != "":
			continue
		var v := stall_value(n, s)
		if v > best_value:
			best_value = v
			best = sid
	if best == "":
		return false
	var old := n.workplace
	w.set_tenant(cur, "")
	w.set_tenant(w.stalls[best], World.npc_ref(n.id))
	n.workplace = best
	n.left_job = "merchant"                    # just changed place: time to settle, as after a job change
	n.job_since = w.day()
	n.plan.clear()
	w.stat("stall_relocations")
	w.note("%s %s moves the trade from %s to %s, where it should sell better." % [n.name, n.family, old, best])
	return true


## What `n`'s goods in hand would fetch, at the asking prices there, if sold from stall `s`.
func stall_value(n: NPC, s: Dictionary) -> float:
	var at := Vector2(int(s.use[0]), int(s.use[1]))
	var v := 0.0
	for id in n.inv.items:
		var q := n.inv.count(id)
		if q > 0 and GameData.value(id) > 0 and not keeps(n, id):
			v += float(q) * float(World.sell_price_at(id, q, w.local_supply(id, at, n)))
	return v


## TAILOR-18, BARBER-18: the place of a service trade in the labour market. Open (one place) while nobody living holds the
## trade and its manor pitch is free (a pitch whose tenant has died or left the trade is freed first): a new world has the
## trade filled; a save made before it, or a trade whose holder has died, opens its place for an adult who becomes free.
## No villager is made for it.
func service_place(job: String) -> Dictionary:
	var s := Business.service_pitch(w, job)
	var open := 0
	if not s.is_empty():
		var t: NPC = w.party(w.tenant_of(s))
		if w.tenant_of(s) != "" and (t == null or not t.alive or t.job != job):
			w.set_tenant(s, "")
		if w.tenant_of(s) == "" and not w.npcs.any(func(o): return o.alive and o.role == "adult" and o.job == job):
			open = 1
	return {"pay": float(GameData.b("manor_wage_per_day")), "open": open, "tool": "", "at": Vector2i(int(s.x), int(s.y) + 1) if not s.is_empty() else Vector2i.ZERO}


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
	# EQ-03: a hunter in woods with no game left above its floors (Fauna.takeable_game: the keep and the hunters' spare,
	# by real counts) has no work to do, and looks for other work as an adult out of work does
	var no_game: bool = w.fauna.takeable_game() == 0
	var seekers := 0               # WDR-012-C: villagers looking for work this morning
	for h in w.households.size():
		var econ: Dictionary = w.households[h].get("econ", {})
		if econ.is_empty():
			continue
		var members := _members(h)
		members.sort_custom(func(x: NPC, y: NPC) -> bool: return x.id < y.id)
		for n: NPC in members:
			if n.role != "adult" or n.job in ["guard", "reeve", "sage", "tailor", "barber", "preacher", "church_assistant"]:
				continue
			var unemployed := n.job == "" or tool_short(n) or (n.job == "hunter" and no_game)
			var share := float(econ.cost) / maxi(1, int(econ.adults))
			if not unemployed:
				var settling := n.left_job != "" and w.day() - n.job_since < cooldown     # just changed jobs: give it time
				if int(econ.streak) < int(GameData.b("mobility_unsustainable_days")) or settling:
					continue
				if n.income_days.size() < 5 or n.avg_income(5) >= share:
					continue
				if n.job == "merchant" and _relocate_stall(n):         # WDR-012-C: first to a better stall
					continue
			seekers += 1
			var current := 0.0 if unemployed else n.avg_income(5)
			var best := ""
			var best_score := -1e9
			var home := w.building_door(n.home)
			for job in ["manor_hand", "farmer", "woodcutter", "hunter", "miner", "prospector", "stonecutter", "tailor", "barber", "preacher", "church_assistant"]:
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
	_hiring_competition(int(market.manor_hand.open), seekers)


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
		"miner", "prospector":
			n.workplace = "mine"
		"merchant":
			n.workplace = place
			w.set_tenant(w.stalls[place], World.npc_ref(n.id))
		"smith", "carpenter", "tanner", "cook", "tavernkeeper":
			n.workplace = place                      # the workstation of the trade (succession)
		"stonecutter":
			n.workplace = ""                          # X18-STONECUT: works at the workbench a free one gives (_station_for)
			for st in w.stations_of("workbench"):
				if w.npc_may_use(n, w.stations[st]):
					n.workplace = st
					break
		"tailor", "barber":
			Business.let_service_pitch(w, n, job)
		"preacher", "church_assistant":
			n.workplace = "chapel"                   # DVW-B3-CHAPEL
		_:
			n.workplace = ""
	if job == "":
		w.note("%s %s loses the work as %s: %s." % [n.name, n.family, old.replace("_", " "), why])
	elif old == "":
		w.note("%s %s takes work as a %s (%s)." % [n.name, n.family, job.replace("_", " "), why])
	else:
		w.note("%s %s leaves work as a %s to be a %s: %s." % [n.name, n.family, old.replace("_", " "), job.replace("_", " "), why])
	w.stat("job_changes")
	if w.recorder != null:
		w.recorder.job_changed(n, old, job, why, place)      # REC-19
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
	return int(Population.JOBS.get(job, 1)) if SKILLED.has(job) or job == "guard" else 1     # the watch too (EQ-04, _guard_posts)


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
	if w.recorder != null:
		w.recorder.vacancy_opened(w.vacancies[-1], "left by death or retirement")      # REC-19
	w.note("The post of %s, left by %s, is open: an apprentice or a newcomer will take it." % [n.job.replace("_", " "), "%s %s" % [n.name, n.family]])


## An essential trade left for other work (seek_work) is handed on as after a death: its post opens when
## the trade falls below strength, so the forge or the woodland is not left empty for good (EQ-07).
func _post_left(n: NPC, job: String, place: String) -> void:
	if job == "" or not is_essential(job) or living_in(job) + open_posts(job) >= staff_target(job):
		return
	w.vacancies.append({"job": job, "workplace": place, "home": n.home, "household": n.household,
			"day": w.day(), "who": "%s %s" % [n.name, n.family], "heir": n.id, "left_by": n.id})
	w.stat("posts_left_" + job)
	if w.recorder != null:
		w.recorder.vacancy_opened(w.vacancies[-1], "left for other work")      # REC-19
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
		if (t != "" and w.party(t) != null and w.party(t).alive) or (w.stalls.has(place) and Business.is_pitch(w.stalls[place])):
			place = ""                                # the stall was let again meanwhile: another one that is vacant
			for sid in _sorted_keys(w.stalls):
				# only a merchants' stall: a pitch is the player's to rent (PL1-10) and a built stall its builder's or,
				# once their household is gone, the manor's (STALL-01); neither is let to a merchant
				if w.tenant_of(w.stalls[sid]) == "" and not Business.is_pitch(w.stalls[sid]):
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
	if w.recorder != null:
		w.recorder.vacancy_filled(n, v, why)      # REC-19


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


## ID-01: a new person's id, from the world's one counter (never an id that was used, whether or not its record still exists).
func _next_npc_id() -> int:
	return w.new_person_id()


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
	Identity.register_npc(w, n, "newcomer")
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
	Identity.sync_name(w, n)


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
		w.contracts.dawn()                           # CON-01: lapses, withdrawn offers, businesses' orders
		w.credit.dawn()                              # TRADE-CREDIT: debts fall due, are repaid or default; households short of food barter or borrow
		Decay.dawn(w)                                # DVW-B4: a day's spoilage of stored food and wear of what is worn


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


## FAMILY-01: the manor's paid work for a parent whose dependants are hungry (the day-labour rule's own conditions, without
## its household-food gate or job list: the family's need is the reason). No new job type.
func _family_labour(n: NPC) -> bool:
	if n.job in ["guard", "reeve", "manor_hand"] or laboured_today.has(n.id) or w.hour() >= float(GameData.b("manor_jobs").get("latest_start", 15)):
		return false
	if n.earned != int(earned_at_dawn.get(n.id, n.earned)) or not w.manor_work.seek(n):
		return false
	laboured_today[n.id] = true
	w.stat("family_first_labour")
	return true


## The caravan passes through (every `caravan_every_days`, at noon): the traders of the five neighbouring settlements
## (Regions; ECON-P1.3, owner 2026-10-23: "their traders, carrying only what they actually have and paying with their actual
## coins; the daily allowance goes away"). Whichever traders are on the road today (Regions.visiting: the nearer settlements
## come more often) sell the village what they hold (ore, coal, stone, medicines, seed) and buy the market's and the
## producers' surplus at 0.8 x value, one unit at a time, each to the seller that needs the sale most (EQ-22:
## caravan_line_need), but only what their settlement still wants (OffMapSettlement.wants) and only with the coins in
## the trader's own till above its floor. Nothing is bought for coins the trader does not hold and nothing is sold that it
## does not carry. The village's currency changes only by what the village pays them and what they pay it; the goods
## cross the boundary the same way; the coins are logged in coin_sources.
func caravan() -> void:
	Migration.visit(w)                               # MIGRATE-18: people travel with the caravan, a real migrant before a made newcomer
	succession_caravan()                             # newcomers for the posts nobody could take (B8-016)
	var on_road: Array = w.regions.begin_visit(w.day())
	var sold := _caravan_imports(on_road)
	var stone := _caravan_stone(on_road)
	_caravan_apothecary(on_road)
	_caravan_seeds(on_road)
	var food_in := _caravan_food(on_road)             # REG-BUY-01: the traders' food, to the buyers that cannot find it in the village
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
		var caps: Dictionary = export_caps(o)
		for id in o.inv.ids():
			if not caps.has(id) or NOT_EXPORTED.has(id) or (keep_food and (FOOD.has(id) or id == "meat")):
				continue
			var extra := o.inv.count(id) - int(caps.get(id, 6)) / 2
			if extra > 0:
				lines.append([o, id, extra])
	# EQ-22 (owner 2026-10-21: "allocate purchasing according to actual demand and need"): no seller is served first
	# for its trade. Each unit goes to the line whose seller needs the sale most (caravan_line_need: its surplus over
	# what it keeps, and the coins its trade's inputs still want), ties to the lower seller id and then item; a unit
	# sold lowers that need, so a short purse goes where the need is, neither in turn nor shared out equally.
	var restock := {}              # seller id -> coins its trade's missing inputs cost (they do not change this visit)
	for line in lines:
		var o: NPC = line[0]
		if not restock.has(o.id):
			restock[o.id] = restock_cost(o)
	while true:
		var best: Array = []
		var best_need := -1.0
		for line in lines:
			var o: NPC = line[0]
			var id: String = line[1]
			if int(line[2]) <= 0 or w.regions.buyer_for(id, maxi(1, roundi(GameData.value(id) * 0.8)), on_road) == null:
				continue
			var need := caravan_line_need(o, id, int(line[2]), int(restock[o.id]))
			if best.is_empty() or need > best_need or (need == best_need and (o.id < (best[0] as NPC).id
					or (o.id == (best[0] as NPC).id and id < str(best[1])))):
				best = line
				best_need = need
		if best.is_empty():
			break
		var o: NPC = best[0]
		var id: String = best[1]
		var price := maxi(1, roundi(GameData.value(id) * 0.8))
		if tool_need.has(id) and int(tool_stock.get(id, 0)) <= int(tool_need[id]):
			best[2] = 0                              # kept for a villager who needs it
			w.stat("caravan_tool_kept_" + id)
			continue
		tool_stock[id] = int(tool_stock.get(id, 0)) - 1
		best[2] = int(best[2]) - 1
		var buyer: OffMapSettlement = w.regions.buyer_for(id, price, on_road)
		buyer.buy_from_village(id, 1, price)             # the trader pays from its own till; the goods enter its stock
		w.note_settlement_trade(o, buyer)                # REG-COURIER-01: a dealing with that trader (a record only)
		o.inv.remove(id)
		w.stat("exported_" + id)
		o.coins += price
		o.earned += price
		w.coin_sources += price
		w.stat("caravan_coins_in", price)
		w.stat("caravan_in_" + (buy_role(o) if buy_role(o) != "" else o.job), price)
		bought += price
	Luxury.visit(w, on_road)                         # DVW-B3-LUX: spare coins buy the traders' costly goods, which they keep
	w.note("Traders from %s pass through, buy %d coins' worth from the market%s%s%s." % [", ".join(on_road.map(func(r): return r.name)), bought,
		(" and sells %d coins' worth of ore and coal to the smiths" % sold) if sold > 0 else "",
		(" and %d stone to the market" % stone) if stone > 0 else "",
		(" and sell %d coins' worth of food they can spare" % food_in) if food_in > 0 else ""])


## What the inputs a trader's trade buys (BUYS of its role) and it lacks would cost at their value: what it
## needs coins for to keep working and stocked (EQ-22).
func restock_cost(o: NPC) -> int:
	var cost := 0
	for id in BUYS.get(buy_role(o), {}):
		cost += wants(o, id) * GameData.value(id)
	return cost


## How much a seller needs the caravan to buy one more unit of `id`, of which it has `extra` for sale (EQ-22,
## owner 2026-10-21; the measure is an agent proposal): the share of its holding of `id` that is surplus over what
## it keeps (0 to 1), plus the share of its inputs' cost (`restock`) its coins cannot pay (0 to 1). A seller well
## stocked, or with the coins to restock, needs the sale less than one short of its trade's inputs and coins.
## What the caravan, and the couriers a business posts goods by (CourierService.villagers_post), take from a merchant or smith: item ->
## the most they stock; their surplus is what they hold beyond half of it.
func export_caps(o: NPC) -> Dictionary:
	if o.job == "smith":
		return {"iron_bar": 8, "pickaxe": 4, "axe": 4, "iron_sword": 4, "copper_sword": 4, "copper_bar": 8, "gold_bar": 2}
	return BUYS.get(buy_role(o), {})


func caravan_line_need(o: NPC, id: String, extra: int, restock: int) -> float:
	var held := maxi(1, o.inv.count(id))
	var surplus := clampf(float(extra) / float(held), 0.0, 1.0)
	var short := 0.0
	if restock > 0:
		short = clampf(float(restock - o.coins) / float(restock), 0.0, 1.0)
	return surplus + short


## When the village's own seams of an ore (or coal) are worked out, the caravan brings it: each
## smith buys up to `caravan_import_stock` at the caravan's price while keeping the trader cash
## floor. The coins leave the village (coin_sources falls). Returns the coins spent.
func _caravan_imports(on_road := []) -> int:
	if on_road.is_empty():
		on_road = w.regions.begin_visit(w.day())
	var left := {}
	for d in w.deposits:
		if w.villagers_reach(d):           # MIN-A: the village's own ore is what its workers can reach
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
			while o.inv.count(id) < int(stock[id]) and w.can_afford(o, price, false, id):
				var seller: OffMapSettlement = w.regions.seller_for(id, on_road)
				if seller == null:
					break                          # no trader on the road carries any
				seller.sell_to_village(id, 1, price)
				w.note_settlement_trade(o, seller)
				o.coins -= price
				o.spent += price
				o.inv.add(id)
				w.coin_sources -= price
				w.stat("caravan_coins_out", price)
				spent += price
				w.stat("imported_" + id)
	return spent


## The caravan's medicines (PL1-04): each visit it sells the sage up to caravan_apothecary_per_visit
## pieces, the scarcest first, towards caravan_apothecary_stock, at base value from the sage's own coins
## (above the trader cash floor). Finite: it stops when the sage cannot pay.
func _caravan_apothecary(on_road := []) -> int:
	if on_road.is_empty():
		on_road = w.regions.begin_visit(w.day())
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
			if fill < worst and w.can_afford(sage, GameData.value(id)) and w.regions.seller_for(id, on_road) != null:
				worst = fill
				pick = id
		if pick == "":
			break
		var price := GameData.value(pick)
		var from_trader: OffMapSettlement = w.regions.seller_for(pick, on_road)
		from_trader.sell_to_village(pick, 1, price)
		w.note_settlement_trade(sage, from_trader)
		sage.coins -= price
		sage.spent += price
		sage.inv.add(pick)
		w.coin_sources -= price
		w.stat("caravan_coins_out", price)
		w.stat("imported_" + pick)
		spent += price
	return spent


## The caravan's seed (Build 13 economy rule 3): each visit it sells the food merchant up to
## caravan_seed_per_visit seeds, the scarcest first, towards caravan_seed_stock, at seed value from the
## merchant's own coins above the trader cash floor. Finite like the apothecary's resupply.
func _caravan_seeds(on_road := []) -> int:
	if on_road.is_empty():
		on_road = w.regions.begin_visit(w.day())
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
				if fill < worst and w.can_afford(o, GameData.value(id)) and o.inv.can_add(id) and w.regions.seller_for(id, on_road) != null:
					worst = fill
					pick = id
			if pick == "":
				break
			var price := GameData.value(pick)
			var from_trader: OffMapSettlement = w.regions.seller_for(pick, on_road)
			from_trader.sell_to_village(pick, 1, price)
			w.note_settlement_trade(o, from_trader)
			o.coins -= price
			o.spent += price
			o.inv.add(pick)
			w.coin_sources -= price
			w.stat("caravan_coins_out", price)
			w.stat("imported_" + pick)
			spent += price
	return spent


## Food from the traders (REG-BUY-01, owner Q18-10 "anyone may purchase goods from another settlement"; REG-BUY-D1 and REG-BUY-P1
## say what the settlements release, OffMapSettlement.stock_trader_food). Villagers' existing buyers buy what the village's own
## sellers cannot supply, one unit at a time from the cheapest trader on the road (Regions.food_seller: a settlement's prices
## float), each under the rule it already follows, and the coins and goods cross the border as every caravan trade does
## (coin_sources, imported_*, caravan_coins_out):
##  - households, in the order of their number: a household whose foreseeable food need over reserve_days (World.necessity's
##    food, in points) is not covered by what it holds and that finds no grain seller or food vendor in the village
##    (_grain_seller, _vendor_with_food, the paths _plan_provision and _plan_eat take) buys, with the coins its members hold
##    (food is a necessity: can_afford's for_need);
##  - the settlement's treasury: the granary's target (granary_target_days) less what it holds and what the farmers and food
##    merchants can still spare it this evening (surplus_wheat), paid from money above treasury_reserve_days of obligations,
##    the rule of the evening's procurement (reeve_day); in a famine, when that procurement does not buy, the farmers' surplus
##    is not counted on;
##  - food businesses (the food merchant, the cook, the tavern): the stock BUYS says they keep (wants), less what the village's
##    sellers hold for sale (_local_food_for_sale), when they can afford it (World.can_afford).
## Returns the coins paid.
func _caravan_food(on_road := []) -> int:
	if on_road.is_empty():
		on_road = w.regions.begin_visit(w.day())
	var spent := 0
	spent += _caravan_food_households(on_road)
	spent += _caravan_food_treasury(on_road)
	spent += _caravan_food_businesses(on_road)
	return spent


## One unit of `item` from the cheapest trader on the road at its settlement's price; returns the price paid, 0 when none sells it
## (the unit has left the trader's stock and its coins are in the till: the caller pays and keeps the goods).
func _food_unit(item: String, on_road: Array, limit := 1 << 30) -> int:
	var seller: OffMapSettlement = w.regions.food_seller(item, on_road)
	if seller == null:
		return 0
	var price := seller.food_price(item)
	if price > limit or not seller.sell_to_village(item, 1, price):
		return 0
	w.coin_sources -= price
	w.stat("caravan_coins_out", price)
	w.stat("imported_" + item)
	w.stat("caravan_food_units")
	w.stat("caravan_food_coins", price)
	return price


## The cheapest food per food point that a trader on the road sells (`allowed`: the foods the buyer can use), "" when none.
func _cheapest_road_food(on_road: Array, allowed: Array) -> String:
	var best := ""
	var best_cost := INF
	for f in allowed:
		var s: OffMapSettlement = w.regions.food_seller(f, on_road)
		if s == null or food_points(f) <= 0.0:
			continue
		var cost := float(s.food_price(f)) / food_points(f)
		if cost < best_cost:
			best_cost = cost
			best = f
	return best


func _caravan_food_households(on_road: Array) -> int:
	var spent := 0
	var days := float(GameData.b("reserve_days"))
	var allowed := ["wheat", "pottage", "roast_meat", "bread", "cheese"]          # eaten from the pantry as they are (raw meat needs logs to roast)
	for h in w.households.size():
		var mem := _members(h)
		if mem.is_empty():
			continue
		var gap := people_day_food(mem) * days - store_points(household_stores(h))
		if gap <= 0.0:
			continue
		var head := _richest_in_household(mem[0])
		if head == null or _grain_seller(head) != null or _vendor_with_food(head) != null:
			continue                                   # the village can still feed it: the villagers' own paths do
		var pantry: Inventory = w.households[h].pantry
		while gap > 0.0:
			var item := _cheapest_road_food(on_road, allowed)
			if item == "" or not pantry.can_add(item):
				break
			var seller: OffMapSettlement = w.regions.food_seller(item, on_road)
			var price := seller.food_price(item)
			var payer := _payer_for(head, price)
			if payer == null or not w.can_afford(payer, price, true):
				break
			if _food_unit(item, on_road, price) == 0:
				break
			payer.coins -= price
			payer.spent += price
			pantry.add(item)
			gap -= food_points(item)
			spent += price
			w.stat("caravan_food_households", price)
	return spent


func _caravan_food_treasury(on_road: Array) -> int:
	var obligations := daily_obligations()
	var reserve := obligations * float(GameData.b("treasury_reserve_days"))
	var target := int(village_day_food() * float(GameData.b("granary_target_days")) / food_points("wheat"))
	var gap := target - w.granary.count("wheat") - w.manor_work.bound("granary", "wheat")
	if not w.famine() and w.food_days >= float(GameData.b("relief_fill_days")):
		for o: NPC in w.npcs:
			if o.alive and (o.job == "farmer" or buy_role(o) == "merchant_food"):
				gap -= surplus_wheat(o)                 # this evening's procurement buys these first
	var spent := 0
	while gap > 0:
		var seller: OffMapSettlement = w.regions.food_seller("wheat", on_road)
		if seller == null:
			break
		var price := seller.food_price("wheat")
		if w.treasury - price < reserve or _food_unit("wheat", on_road, price) == 0:
			break
		w.treasury -= price
		w.granary.add("wheat")
		gap -= 1
		spent += price
		w.stat("caravan_food_treasury", price)
		w.stat("gov_granary_in", 1)
	return spent


## What the village's sellers hold for sale of food `id` besides `buyer` (the sellers _relief_offers lists: farmers' grain beyond
## what they keep, the food vendors' stock, farmers' eggs and milk, hunters' and farmers' meat).
func _local_food_for_sale(id: String, buyer: NPC) -> int:
	var n := 0
	for o: NPC in w.npcs:
		if not o.alive or o == buyer or o.role == "bandit":
			continue
		var vendor := o.job in ["tavernkeeper", "cook"] or buy_role(o) == "merchant_food"
		if id == "wheat":
			n += surplus_wheat(o) if o.job == "farmer" or vendor else 0
		elif vendor or (o.job == "farmer" and id in ["egg", "milk", "meat"]) or (o.job == "hunter" and id == "meat"):
			n += o.inv.count(id)
	return n


func _caravan_food_businesses(on_road: Array) -> int:
	var spent := 0
	for o: NPC in w.npcs:
		if not o.alive or not (o.job in ["tavernkeeper", "cook"] or buy_role(o) == "merchant_food"):
			continue
		var caps: Dictionary = BUYS.get(buy_role(o), {})
		for id in ["wheat", "meat", "pottage", "roast_meat", "bread", "cheese"]:
			if not caps.has(id):
				continue
			var want := wants(o, id) - _local_food_for_sale(id, o)
			while want > 0:
				var seller: OffMapSettlement = w.regions.food_seller(id, on_road)
				if seller == null:
					break
				var price := seller.food_price(id)
				if not w.can_afford(o, price, false, id) or not o.inv.can_add(id) or _food_unit(id, on_road, price) == 0:
					break
				o.coins -= price
				o.spent += price
				o.inv.add(id)
				want -= 1
				spent += price
				w.stat("caravan_food_businesses", price)
	return spent


func _stone_scarce() -> bool:
	return w.quests.deposit_left("stone") <= int(GameData.b("caravan_import_when_left"))


## Stone (owner, 2026-10-18; B7-007): once the village's own stone is worked out, the caravan brings
## a cart of it from a quarry on its road: at most caravan_stone.load a visit, bought there at its
## value and sold at value times caravan_stone.markup (the cartage of a heavy, cheap load). The
## raw-goods merchants, the village's stone sellers (Construction.SELLERS), buy it up to their
## stock cap while keeping the trader cash floor; what they cannot pay for goes back with the cart.
## The coins leave the village (coin_sources falls). Returns the stone sold.
func _caravan_stone(on_road := []) -> int:
	if not _stone_scarce():
		return 0
	if on_road.is_empty():
		on_road = w.regions.begin_visit(w.day())
	var cfg: Dictionary = GameData.b("caravan_stone")
	var cart := int(cfg.load)
	var price := maxi(1, roundi(GameData.value("stone") * float(cfg.markup)))
	var sold := 0
	for o: NPC in w.npcs:
		if not o.alive or buy_role(o) != "merchant_raw":
			continue
		while cart > 0 and wants(o, "stone") > 0 and w.can_afford(o, price, false, "stone"):
			var seller: OffMapSettlement = w.regions.seller_for("stone", on_road)
			if seller == null:
				break
			seller.sell_to_village("stone", 1, price)
			w.note_settlement_trade(o, seller)
			o.coins -= price
			o.spent += price
			o.inv.add("stone")
			w.coin_sources -= price
			w.stat("imported_stone")
			w.stat("caravan_stone_coins", price)
			w.stat("caravan_coins_out", price)
			cart -= 1
			sold += 1
	return sold
