extends SceneTree
## B25-F015-FOOD-01 (owner 2026-11-10, docs/directives/2026-11-10_seed2_findings_f015_p99.md). Found in the recorded campaigns:
## batch 3 (42760291468, seed 1, F015: p:144) and fbfd6ad (42788018729, seed 2: p:92 Alice Lambert, homestead hs3): a lone
## homesteader starved holding coins. p:92 set out on day 224 with 28 coins left after the house's materials, held no food,
## went to the village market on day 225 at hunger 0, sold a log, bought nothing to eat and died that evening. The death's
## record: household food units 0, household "food days" 13.03, no cooked food on any stall, the traders carrying 1585 units.
## Two causes: NPCBrain.household_food_days counts coins as the food they could buy, so the homestead's trip and its food
## errand (both "below food_low_days / food_target_days") saw 13 days of food in 28 coins and bought none; and the market
## meal step bought only a cooked meal (none on sale) with no fallback to the edible grain the farmers sold. Now the
## homestead's food decisions read the food it holds (household_food_held_days, coins not counted; household_food_days stays
## as the purchasing-capacity measure the relief rules use), and a hungry homesteader with no cooked meal they can pay for
## buys grain (edible as it is, the player's rule, FSE-00) through buy_from's own rule and eats. Checked:
##   1 the two measures: a household with coins and no food holds 0 days of food, and still has the capacity to buy some
##   2 at market, hungry, no cooked meal on sale anywhere, grain at a farmer: they buy grain and eat it (coins and grain conserved)
##   3 at market, not hungry, nothing held, coins in the purse: the food errand buys grain for the homestead's pantry
##   4 a cooked meal on sale only above what they can pay (the deal price): not sent to be refused; grain bought instead
##   5 no food on sale anywhere: no purchase planned, nothing created or moved (a shortage stays a shortage)
##   6 the same plan after a save and load and on two identical worlds (deterministic)
##   godot --headless --path game --script res://tests/homestead_food_held_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	case_measures()
	case_hungry_no_meal()
	case_stock_pantry()
	case_meal_too_dear()
	case_no_food()
	case_save_load_and_replay()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A homesteader `n` (begun by Homesteads.begin, as homestead_test does) standing at the village market with `coins` and no
## food, their claim `c`, a market trip `trip`; every cooked meal in the village taken off sale and a farmer `f` holding grain.
func setup(coins := 28, seed := 1) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var hs: Homesteads = w.homesteads
	var cands := []
	for h in w.households.size():
		var o: NPC = w.construction.founder_of(h)
		if o != null and Life.npc_age(w, o) <= 30.0 and hs.gate(h, [o]) == "":
			cands.append([w.property.purse(World.hh_ref(h)), h, o])
	cands.sort()
	var n: NPC = cands[-1][2]
	w.treasury -= 300
	n.coins += 300                                  # the family's savings for the start (a conserved transfer, as homestead_test)
	hs.begin(int(cands[-1][1]), n, [n])
	var c := hs.claim_of(n)
	for o: NPC in w.npcs:                           # no cooked meal for sale anywhere; the farmers' grain stays
		if o.job == "tavernkeeper" or w.brain.buy_role(o) == "merchant_food":
			for f in NPCBrain.COOKED:
				o.inv.remove(f, o.inv.count(f))
	var f: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "farmer" and o != n:
			f = o
			break
	f.inv.add("wheat", 20)
	for e in NPCBrain.EDIBLE + ["meat"]:
		n.inv.remove(e, n.inv.count(e))
	(w.households[n.household].pantry as Inventory).items.clear()
	w.treasury += n.coins - coins
	n.coins = coins
	n.pos = f.pos + Vector2(2, 0)
	n.plan.clear()
	w.minutes = float(w.day()) * 1440.0 + 11.0 * 60.0     # late morning, shops open
	w.brain.market_food_points = 100000.0           # a well-supplied market, as in the campaign (the traders carried 1585 units)
	var trip := {"claim": str(c.id), "leg": "market", "n": 0, "day": w.day(), "tried": {}}
	return {"w": w, "n": n, "c": c, "f": f, "trip": trip}


func _step(n: NPC, act: String) -> Dictionary:
	for st in n.plan:
		if str(st.get("act", "")) == act:
			return st
	return {}


func _totals(w: World) -> Array:
	var coins := w.treasury
	var wheat := w.granary.count("wheat")
	for o: NPC in w.npcs:
		coins += o.coins
		wheat += o.inv.count("wheat")
	for h in w.households:
		wheat += (h.pantry as Inventory).count("wheat")
	return [coins, wheat]


func _held(w: World, h: int) -> float:
	return float(w.brain.call("household_food_held_days", h)) if w.brain.has_method("household_food_held_days") else -1.0


func case_measures() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.n
	var held := _held(w, n.household)
	var cap: float = w.brain.household_food_days(n.household)
	check(held == 0.0, "a homestead with 28 coins and no food holds 0 days of food (%.2f): coins are not food held" % held)
	check(cap >= float(Homesteads.cfg().food_target_days), "and its purchasing capacity is still measured: %.2f days of food its coins could buy (at least food_target_days, as p:92's 13.03)" % cap)
	w.dispose()


func case_hungry_no_meal() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.n
	var f: NPC = s.f
	n.hunger = 5.0
	var t0 := _totals(w)
	var planned: bool = w.homesteads._errand(n, s.c, s.trip)
	var buy := _step(n, "buy_from")
	check(planned and not buy.is_empty() and str(buy.args.item) == "wheat", "hungry at market with no cooked meal on sale: they go to buy grain (doing %s, plan %s)" % [n.doing, str(buy.get("args", {}))])
	if buy.is_empty():
		w.dispose()
		return
	var h0 := n.hunger
	f = w.npc(int(buy.args.vendor))                 # the grain seller chosen (the nearest with grain to spare)
	var fc := f.coins
	var nc := n.coins
	var up0 := w.deal_price(w.sell_price(f, "wheat"), n, f)
	var ok: bool = w.brain.act(n, "buy_from", buy.args)
	var q := int(buy.args.qty)
	var eat := false
	for st in n.plan:
		if str(st.get("act", "")) in ["eat", "eat_home"]:
			eat = w.brain.act(n, str(st.act), st.get("args", {}))
	var up := up0
	check(ok and nc - n.coins == up * q and f.coins == fc + up * q, "the grain is bought by the ordinary trade at the deal price (%d x %d = %d coins, received by the seller)" % [q, up, nc - n.coins])
	check(eat and n.hunger > h0, "and they eat (hunger %.0f -> %.0f)" % [h0, n.hunger])
	var t1 := _totals(w)
	check(t1[0] == t0[0] and t1[1] == t0[1] - 1, "coins conserved, and exactly the one unit eaten leaves the grain (%s -> %s)" % [str(t0), str(t1)])
	w.dispose()


func case_stock_pantry() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.n
	n.hunger = 90.0
	var bought := false
	for i in 12:
		if not w.homesteads._errand(n, s.c, s.trip):
			break
		var st := _step(n, "buy_from")
		if not st.is_empty() and str(st.args.item) == "wheat" and bool(st.args.get("pantry", false)):
			bought = w.brain.act(n, "buy_from", st.args)
			break
		n.plan.clear()
	var p: Inventory = w.households[n.household].pantry
	check(bought and p.count("wheat") > 0, "not hungry, nothing held, coins in the purse: the trip buys grain for the homestead's pantry (%d)" % p.count("wheat"))
	w.dispose()


func case_meal_too_dear() -> void:
	var s := setup(4)
	var w: World = s.w
	var n: NPC = s.n
	var v: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "tavernkeeper" and not w.asleep(o):
			v = o
			break
	v.inv.add("roast_meat", 2)
	var meal := w.deal_price(w.sell_price(v, "roast_meat"), n, v)
	var grain := w.deal_price(w.sell_price(s.f, "wheat"), n, s.f)
	if meal <= n.coins or grain > n.coins:
		n.coins = maxi(grain, 1)
		w.treasury += 4 - n.coins
	meal = w.deal_price(w.sell_price(v, "roast_meat"), n, v)
	check(meal > n.coins and grain <= n.coins, "fixture: a meal at %d, more than the purse %d; grain at %d" % [meal, n.coins, grain])
	n.hunger = 5.0
	w.homesteads._errand(n, s.c, s.trip)
	var food := _step(n, "buy_food")
	var buy := _step(n, "buy_from")
	check(food.is_empty(), "they are not sent to buy a meal they cannot pay for (plan %s)" % str(food.get("args", {})))
	check(not buy.is_empty() and str(buy.args.item) == "wheat" and w.brain.act(n, "buy_from", buy.args), "they buy the grain they can pay for instead")
	w.dispose()


func case_no_food() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.n
	for o: NPC in w.npcs:
		if o != n:
			for e in NPCBrain.EDIBLE:
				o.inv.remove(e, o.inv.count(e))
	n.hunger = 5.0
	var t0 := _totals(w)
	var bought := 0
	for i in 12:
		if not w.homesteads._errand(n, s.c, s.trip):
			break
		if not _step(n, "buy_food").is_empty() or (not _step(n, "buy_from").is_empty() and str(_step(n, "buy_from").args.item) in NPCBrain.EDIBLE):
			bought += 1
		n.plan.clear()
	check(bought == 0, "with no food on sale anywhere, no food purchase is planned (%d)" % bought)
	check(_totals(w) == t0 and n.hunger == 5.0, "and nothing is created or moved: the shortage stays (%s)" % str(_totals(w)))
	w.dispose()


func case_save_load_and_replay() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.n
	n.hunger = 5.0
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var n2 := w2.npc(n.id)
	w.homesteads._errand(n, s.c, s.trip.duplicate(true))
	w2.homesteads._errand(n2, w2.homesteads.claim_of(n2), s.trip.duplicate(true))
	check(JSON.stringify(n.plan) == JSON.stringify(n2.plan) and not _step(n, "buy_from").is_empty(), "after a save and load the same plan (%s)" % n2.doing)
	var a := setup()
	var b := setup()
	(a.n as NPC).hunger = 5.0
	(b.n as NPC).hunger = 5.0
	a.w.homesteads._errand(a.n, a.c, a.trip)
	b.w.homesteads._errand(b.n, b.c, b.trip)
	check(JSON.stringify((a.n as NPC).plan) == JSON.stringify((b.n as NPC).plan), "two identical worlds give the same plan (deterministic)")
	w.dispose()
	w2.dispose()
	a.w.dispose()
	b.w.dispose()
