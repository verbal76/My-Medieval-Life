extends SceneTree
## Found in the simulation batch's recorded campaign (42734194963, seed 1, finding F002 and the day-243 cluster): a hungry villager
## whose household pays for their meal (NPCBrain._payer_for: the family's purse, or its richest member) was sent to buy that meal
## from the food seller nearest them (_vendor_with_food) even when the payer WAS that seller. World.trade refuses a trade with oneself
## ("invalid_trade"), the plan failed, and the same plan was made again the next minute: p:64 was refused 1262 times in one day. The
## seller is never the payer for their own goods. Owner 2026-11-10 (B25-SELFTRADE-VAL-01): "Do not consider this defect fully resolved
## merely because the self-trade is prevented." So each case is checked for what the villager then does:
##   1 a dependant whose household's only coins are the seller's, with another vendor in the village: fed there, the seller paying
##   2 the same with no other food anywhere: no purchase is planned in 240 successive decisions (so no trade is attempted or
##     refused: no retry loop), nothing changes hands. The villager then goes hungry while the seller's stock is for sale: whether
##     a seller's household may eat that stock is a design question for the owner (B25-SELFTRADE-VAL-01 report), not decided here
##   3 a household with a second member who can pay: that member pays the seller
##   4 a dependent child: as 1
##   5 the seller hungry themselves: eats from their own stock, no trade
##   6 the villager with coins of their own: buys from the seller (control)
## and in every case the household's coins and food are conserved (what leaves one holder reaches another).
##   godot --headless --path game --script res://tests/self_trade_payer_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	case_other_vendor(false)
	case_other_vendor(true)
	case_no_other_source()
	case_second_payer()
	case_seller_hungry()
	case_own_coins()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A world with tavernkeeper `v` the richest in a household that also holds `hungry` (a penniless adult, or a child), the only
## food on sale in the village v's pottage (and, with `second`, a second vendor's). Returns {w, v, hungry, other}.
func setup(child: bool, second: bool) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var v: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "tavernkeeper" and o.household >= 0:
			v = o
			break
	var hungry: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != v and o.job not in ["tavernkeeper", "guard"] and (o.role == "child" if child else o.role in ["adult", "elder"]):
			hungry = o
			break
	if hungry.household >= 0:
		w.households[hungry.household].members.erase(hungry.id)
	hungry.household = v.household
	if not w.households[v.household].members.has(hungry.id):
		w.households[v.household].members.append(hungry.id)
	for m in w.households[v.household].members:
		var o := w.npc(m)
		if o != null and o != v:
			o.coins = 0
	v.coins = 500
	v.inv.add("pottage", 5)
	for o: NPC in w.npcs:
		if o != v and (o.job == "tavernkeeper" or w.brain.buy_role(o) == "merchant_food"):
			for f in NPCBrain.COOKED:
				o.inv.remove(f, o.inv.count(f))
		if o != hungry:
			o.hunger = 100.0
	var other: NPC = null
	if second:
		for o: NPC in w.npcs:
			if o.alive and o != v and o != hungry and o.role == "adult" and o.household >= 0 and o.household != v.household \
					and (o.job == "tavernkeeper" or w.brain.buy_role(o) == "merchant_food"):
				other = o
				break
		if other == null:
			for o: NPC in w.npcs:
				if o.alive and o != v and o != hungry and o.role == "adult" and o.household >= 0 and o.household != v.household and o.job not in ["guard"]:
					other = o
					break
			w.brain._change_job(other, "tavernkeeper", "test")
		other.inv.add("pottage", 5)
		other.pos = v.pos + Vector2(30, 0)
	(w.households[v.household].pantry as Inventory).items.clear()
	hungry.inv.items.clear()
	hungry.hunger = 10.0
	hungry.plan.clear()
	hungry.pos = v.pos + Vector2(2, 0)
	return {"w": w, "v": v, "hungry": hungry, "other": other}


func _acts(n: NPC) -> Array:
	return n.plan.filter(func(s): return s.has("act")).map(func(s): return [str(s.act), s.get("args", {})])


func _buy(n: NPC) -> Dictionary:
	for st in n.plan:
		if str(st.get("act", "")) in ["buy_food", "buy_from"]:
			return st.get("args", {})
	return {}


## Coins of the village's people and households plus every cooked meal held: what a sale moves stays inside this sum.
func _totals(w: World) -> Array:
	var c := 0
	var food := 0
	for o: NPC in w.npcs:
		c += o.coins
		for f in NPCBrain.COOKED:
			food += o.inv.count(f)
	for h in w.households:
		for f in NPCBrain.COOKED:
			food += (h.pantry as Inventory).count(f)
	return [c, food]


func case_other_vendor(child: bool) -> void:
	var s := setup(child, true)
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.hungry
	var t0 := _totals(w)
	w.brain._plan_eat(n)
	var a := _buy(n)
	var who := "a dependent child" if child else "a penniless dependant"
	check(not a.is_empty() and int(a.get("vendor", -1)) != v.id, "%s of the seller's household with another vendor in the village is sent to that vendor (plan %s)" % [who, str(_acts(n))])
	check(int(a.get("payer", n.id)) == v.id, "and the seller pays for it there, from the household's purse (payer %s)" % str(a.get("payer", "self")))
	check(_totals(w) == t0, "planning moves no coin or food")
	w.dispose()


func case_no_other_source() -> void:
	var s := setup(false, false)
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.hungry
	for o: NPC in w.npcs:                            # nothing else to eat or buy anywhere: the seller's pottage is the only food
		if o != v:
			for f in NPCBrain.EDIBLE + ["wheat"]:
				o.inv.remove(f, o.inv.count(f))
	for h in w.households:
		(h.pantry as Inventory).items.clear()
	var t0 := _totals(w)
	var c0 := v.coins
	var attempts := 0
	for minute in 240:                               # four hours of the hungry villager re-deciding every minute
		n.plan.clear()
		n.hunger = 10.0
		w.brain._plan_eat(n)
		if not _buy(n).is_empty():
			attempts += 1
	check(attempts == 0, "with the seller the only payer and the only food, no purchase is planned in 240 decisions (%d planned%s)" % [attempts, "" if attempts == 0 else ": " + str(_acts(n))])
	check(_totals(w) == t0 and v.coins == c0, "nothing changes hands (coins and meals as before)")
	w.dispose()


func case_second_payer() -> void:
	var s := setup(false, false)
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.hungry
	var payer: NPC = null
	for m in w.households[v.household].members:
		var o := w.npc(m)
		if o != null and o != v and o != n and o.alive and o.role in ["adult", "elder"]:
			payer = o
			break
	if payer == null:                                # give the household a second adult
		for o: NPC in w.npcs:
			if o.alive and o != v and o != n and o.role == "adult" and o.household >= 0 and o.household != v.household and o.job not in ["guard", "tavernkeeper"]:
				w.households[o.household].members.erase(o.id)
				o.household = v.household
				w.households[v.household].members.append(o.id)
				payer = o
				break
	payer.coins = 40
	w.brain._plan_eat(n)
	var a := _buy(n)
	check(int(a.get("vendor", -1)) == v.id and int(a.get("payer", -1)) == payer.id,
		"with a second member who can pay, that member pays the seller for the meal (plan %s)" % str(_acts(n)))
	w.dispose()


func case_seller_hungry() -> void:
	var s := setup(false, false)
	var w: World = s.w
	var v: NPC = s.v
	v.hunger = 10.0
	v.plan.clear()
	w.brain._plan_eat(v)
	check(_buy(v).is_empty() and _acts(v).any(func(x): return x[0] == "eat"), "the seller hungry eats from their own stock, no trade (plan %s)" % str(_acts(v)))
	w.dispose()


func case_own_coins() -> void:
	var s := setup(false, false)
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.hungry
	n.coins = 50
	w.brain._plan_eat(n)
	var a := _buy(n)
	check(int(a.get("vendor", -1)) == v.id and int(a.get("payer", n.id)) == n.id, "with coins of their own they buy the meal from the tavernkeeper (control)")
	w.dispose()
