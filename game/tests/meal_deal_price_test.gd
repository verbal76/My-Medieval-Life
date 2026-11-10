extends SceneTree
## Found in batch 3's recorded campaign (42760291468, seed 2, F007 and the day-363 buy_food cluster): p:149 was refused bread 2776
## times in one day, "buyer_short_of_coins", from a seller with Trading skill. NPCBrain._plan_eat and _meal_choice judged a meal
## affordable at the seller's list price (World.sell_price), but the buy_food act asks the deal price (World.deal_price: the list
## price times deal_factor, which a skilled seller raises), so a buyer who could pay the list price but not the deal price was sent,
## refused, and sent again the next minute. A meal is planned only when the payer can pay what will actually be asked.
##   1 a buyer who can pay the list price but not a skilled seller's deal price is not sent to buy (no plan, so no refusal loop)
##   2 one who can pay the deal price buys it, and pays exactly the deal price
##   3 with two meals, one affordable at its deal price and one not, the affordable one is chosen
##   godot --headless --path game --script res://tests/meal_deal_price_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	case_cannot_pay_deal()
	case_can_pay_deal()
	case_cheaper_meal()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A world with one tavernkeeper `v` (skilled at trading, so asking above the list price) holding `stock`, every other food source
## emptied, and a hungry adult `n` of another household with an empty pantry. Returns {w, v, n}.
func setup(stock: Dictionary) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var v: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "tavernkeeper":
			v = o
			break
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != v and o.household >= 0 and o.household != v.household and o.role in ["adult", "elder"] \
				and o.job not in ["tavernkeeper", "guard", "cook"] and not w.brain._can_roast(o):
			n = o
			break
	for o: NPC in w.npcs:
		for f in NPCBrain.EDIBLE:
			o.inv.remove(f, o.inv.count(f))
		if o != n:
			o.hunger = 100.0
	for h in w.households:
		(h.pantry as Inventory).items.clear()
	for f in stock:
		v.inv.add(f, int(stock[f]))
	v.skills["trading"] = Skills.xp_for_level(10)    # a skilled seller: deal_factor above 1
	n.skills.erase("trading")
	n.hunger = 10.0
	n.plan.clear()
	n.pos = v.pos + Vector2(2, 0)
	for m in w.households[n.household].members:      # nobody else in the household can pay for them
		var o := w.npc(m)
		if o != null and o != n:
			o.coins = 0
	return {"w": w, "v": v, "n": n}


func _buy(n: NPC) -> Dictionary:
	for st in n.plan:
		if str(st.get("act", "")) == "buy_food":
			return st
	return {}


func case_cannot_pay_deal() -> void:
	var s := setup({"pottage": 3})
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.n
	var list := w.sell_price(v, "pottage")
	var deal := w.deal_price(list, n, v)
	check(deal > list, "fixture: the skilled seller asks more than the list price (list %d, deal %d)" % [list, deal])
	n.coins = list                                   # enough for the list price, short of the deal price
	var planned := 0
	for i in 60:
		n.plan.clear()
		n.hunger = 10.0
		w.brain._plan_eat(n)
		if not _buy(n).is_empty():
			planned += 1
	check(planned == 0, "a buyer with the list price but not the deal price is not sent to buy, in 60 decisions (%d planned)" % planned)
	check(n.coins == list and v.inv.count("pottage") == 3, "and nothing changes hands")
	w.dispose()


func case_can_pay_deal() -> void:
	var s := setup({"pottage": 3})
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.n
	var deal := w.deal_price(w.sell_price(v, "pottage"), n, v)
	n.coins = deal
	w.brain._plan_eat(n)
	var st := _buy(n)
	check(not st.is_empty(), "a buyer who can pay the deal price is sent to buy")
	if st.is_empty():
		w.dispose()
		return
	var vc := v.coins
	var ok: bool = w.brain.act(n, "buy_food", st.args)
	check(ok and n.coins == 0 and v.coins == vc + deal and n.inv.count("pottage") == 1, "and buys it for exactly the deal price (%d)" % deal)
	w.dispose()


func case_cheaper_meal() -> void:
	var s := setup({"roast_meat": 2, "pottage": 2})
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.n
	var cheap := mini(w.deal_price(w.sell_price(v, "pottage"), n, v), w.deal_price(w.sell_price(v, "roast_meat"), n, v))
	var dear := maxi(w.deal_price(w.sell_price(v, "pottage"), n, v), w.deal_price(w.sell_price(v, "roast_meat"), n, v))
	if cheap == dear:
		check(true, "(the two meals cost the same here: nothing to choose between)")
		w.dispose()
		return
	n.coins = cheap
	w.brain._plan_eat(n)
	var st := _buy(n)
	check(not st.is_empty(), "with coins for only the cheaper meal at its deal price, they are still sent to buy")
	if st.is_empty():
		w.dispose()
		return
	var ok: bool = w.brain.act(n, "buy_food", st.args)
	check(ok, "and the purchase succeeds (the affordable meal is the one chosen)")
	w.dispose()
