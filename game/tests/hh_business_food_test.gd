extends SceneTree
## B25-HH-BIZFOOD-D1 (owner 2026-11-10, docs/directives/2026-11-10_household_food_property_permissions.md s.1): "A food seller's own
## household may consume food from the seller's business inventory without making a purchase. A baker should not have a dependent
## child starving while edible bread sits in the family's own business inventory." NPCBrain._plan_eat's last resort before going
## hungry: a member of a food seller's household with nothing at home and nothing they can buy takes one cooked meal from the
## seller's stock (World.transfer, no trade, no coins: never a purchase from oneself, B25-SELFTRADE-VAL-01) and eats it. Checked:
##   1 a penniless dependant (and a child) eats from the family stock: exactly one meal leaves the stock, no coins move anywhere
##   2 the seller eats their own stock (as before)
##   3 too little stock for two hungry members: the first takes the last meal, the second's act takes nothing and nothing is
##     duplicated; the second's next decision does not plan it again (no retry loop)
##   4 stock held by a reservation (LE-03 claims) is not taken
##   5 an unrelated household's member is never sent to it, and the act refuses them with nothing moved
##   6 a member who can buy food still buys as before (the stock is a last resort)
##   7 the same after a save and load, and the same on two identical worlds (deterministic)
##   godot --headless --path game --script res://tests/hh_business_food_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	case_dependant(false)
	case_dependant(true)
	case_seller_eats()
	case_scarce_stock()
	case_reserved_stock()
	case_unrelated()
	case_can_buy()
	case_save_load_and_replay()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A world where tavernkeeper `v` holds `meals` pottage and nothing else in the village is edible or for sale; `hungry` (a penniless
## adult, or a child) is in v's household with an empty pantry. Returns {w, v, hungry}.
func setup(child := false, meals := 3, seed := 1) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var v: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "tavernkeeper" and o.household >= 0:
			v = o
			break
	var hungry: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != v and o.job not in ["tavernkeeper", "guard", "cook"] and not w.brain._can_roast(o) \
				and (o.role == "child" if child else o.role in ["adult", "elder"]):
			hungry = o                                   # (a cook can always cook at home: not the case under test)
			break
	_join(w, hungry, v.household)
	for o: NPC in w.npcs:
		for f in NPCBrain.EDIBLE:
			o.inv.remove(f, o.inv.count(f))
		o.hunger = 100.0
		if o != v:
			o.coins = 0
	for h in w.households:
		(h.pantry as Inventory).items.clear()
	v.coins = 500
	v.inv.add("pottage", meals)
	hungry.hunger = 10.0
	hungry.plan.clear()
	hungry.pos = v.pos + Vector2(2, 0)
	return {"w": w, "v": v, "hungry": hungry}


func _join(w: World, n: NPC, h: int) -> void:
	if n.household >= 0:
		w.households[n.household].members.erase(n.id)
	n.household = h
	if not w.households[h].members.has(n.id):
		w.households[h].members.append(n.id)


func _coins(w: World) -> int:
	var c := w.treasury
	for o: NPC in w.npcs:
		c += o.coins
	return c


func _meals(w: World) -> int:
	var m := 0
	for o: NPC in w.npcs:
		for f in NPCBrain.COOKED:
			m += o.inv.count(f)
	return m


func _step(n: NPC, act: String) -> Dictionary:
	for st in n.plan:
		if str(st.get("act", "")) == act:
			return st
	return {}


## Plans `n`'s meal and performs the family-stock act and the eating as World.update would. Returns {planned, took, ate}.
func _eat_once(w: World, n: NPC) -> Dictionary:
	n.plan.clear()
	w.brain._plan_eat(n)
	var st := _step(n, "eat_family_stock")
	if st.is_empty():
		return {"planned": false, "took": false, "ate": false}
	var took: bool = w.brain.act(n, "eat_family_stock", st.args)
	var ate: bool = took and w.brain.act(n, "eat", {"cooked_only": true})
	return {"planned": true, "took": took, "ate": ate}


func case_dependant(child: bool) -> void:
	var s := setup(child)
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.hungry
	var c0 := _coins(w)
	var vc := v.coins
	var stock0 := v.inv.count("pottage")
	var h0 := n.hunger
	var r := _eat_once(w, n)
	var who := "a dependent child" if child else "a penniless dependant"
	check(bool(r.planned) and bool(r.took), "%s of the seller's household with nothing at home or for sale takes a meal from the family stock" % who)
	check(v.inv.count("pottage") == stock0 - 1, "exactly one meal leaves the business stock (%d -> %d)" % [stock0, v.inv.count("pottage")])
	check(bool(r.ate) and n.hunger > h0 and n.inv.count("pottage") == 0, "and it is eaten, not kept: hunger %.0f -> %.0f, none left in hand" % [h0, n.hunger])
	check(_coins(w) == c0 and v.coins == vc and n.coins == 0, "no coin moves anywhere (village %d, seller %d)" % [_coins(w), v.coins])
	w.dispose()


func case_seller_eats() -> void:
	var s := setup()
	var w: World = s.w
	var v: NPC = s.v
	v.hunger = 10.0
	v.plan.clear()
	w.brain._plan_eat(v)
	check(_step(v, "eat_family_stock").is_empty() and _step(v, "buy_food").is_empty() and not _step(v, "eat").is_empty(),
		"the seller eats their own stock directly (no act, no trade)")
	w.dispose()


func case_scarce_stock() -> void:
	var s := setup(false, 1)
	var w: World = s.w
	var v: NPC = s.v
	var a: NPC = s.hungry
	var b: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != v and o != a and o.role in ["adult", "elder"] and o.job not in ["tavernkeeper", "guard", "cook"] and not w.brain._can_roast(o):
			b = o
			break
	_join(w, b, v.household)
	b.coins = 0
	b.hunger = 10.0
	b.pos = v.pos + Vector2(3, 0)
	a.plan.clear()
	b.plan.clear()
	w.brain._plan_eat(a)
	w.brain._plan_eat(b)
	var sa := _step(a, "eat_family_stock")
	var sb := _step(b, "eat_family_stock")
	check(not sa.is_empty() and not sb.is_empty(), "two hungry members both plan to eat from the one meal in stock")
	var m0 := _meals(w)
	if sa.is_empty() or sb.is_empty():
		w.dispose()
		return
	var ta: bool = w.brain.act(a, "eat_family_stock", sa.args)
	var tb: bool = w.brain.act(b, "eat_family_stock", sb.args)
	check(ta and not tb, "the first takes it, the second's act takes nothing")
	check(_meals(w) == m0 and v.inv.count("pottage") == 0 and a.inv.count("pottage") == 1 and b.inv.count("pottage") == 0,
		"no meal is duplicated or lost: one meal, now in the first member's hand")
	var again := 0
	for i in 60:
		b.plan.clear()
		w.brain._plan_eat(b)
		if not _step(b, "eat_family_stock").is_empty() or not _step(b, "buy_food").is_empty():
			again += 1
	check(again == 0, "with the stock gone the second member plans no family meal or purchase in 60 decisions (%d)" % again)
	w.dispose()


func case_reserved_stock() -> void:
	var s := setup(false, 2)
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.hungry
	if w.economy == null:
		check(true, "(the Living Economy is off: no reservations to respect)")
		w.dispose()
		return
	var r: Dictionary = w.economy.reservations.reserve(Contracts.ref_of(v), "pottage", 2, "test: promised to a buyer")
	check(not r.is_empty(), "fixture: both of the seller's meals are reserved")
	n.plan.clear()
	w.brain._plan_eat(n)
	check(_step(n, "eat_family_stock").is_empty() and v.inv.count("pottage") == 2, "reserved stock is not taken by the household (stock still %d)" % v.inv.count("pottage"))
	var took: bool = w.brain.act(n, "eat_family_stock", {"from": v.id})
	check(not took and v.inv.count("pottage") == 2, "and the act refuses it with nothing moved")
	w.dispose()


func case_unrelated() -> void:
	var s := setup()
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.hungry
	var other: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != v and o != n and o.household >= 0 and o.household != v.household and o.role in ["adult", "elder"] and o.job not in ["tavernkeeper", "guard", "cook"] and not w.brain._can_roast(o):
			other = o
			break
	other.hunger = 10.0
	other.coins = 0
	other.pos = v.pos + Vector2(2, 0)
	(w.households[other.household].pantry as Inventory).items.clear()
	other.plan.clear()
	w.brain._plan_eat(other)
	check(_step(other, "eat_family_stock").is_empty(), "a hungry member of an unrelated household is not sent to the seller's stock")
	var stock0 := v.inv.count("pottage")
	var c0 := _coins(w)
	var took: bool = w.brain.act(other, "eat_family_stock", {"from": v.id})
	check(not took and v.inv.count("pottage") == stock0 and _coins(w) == c0, "and a forced act refuses them: nothing moved, no coins")
	w.dispose()


func case_can_buy() -> void:
	var s := setup()
	var w: World = s.w
	var v: NPC = s.v
	var n: NPC = s.hungry
	n.coins = 50
	n.plan.clear()
	w.brain._plan_eat(n)
	var buy := _step(n, "buy_food")
	check(_step(n, "eat_family_stock").is_empty() and not buy.is_empty() and int(buy.args.vendor) == v.id and int(buy.args.get("payer", n.id)) == n.id,
		"a member with coins of their own buys as before (the family stock is a last resort)")
	w.dispose()


func case_save_load_and_replay() -> void:
	var s := setup()
	var w: World = s.w
	var n: NPC = s.hungry
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var n2 := w2.npc(n.id)
	var r1 := _eat_once(w, n)
	var r2 := _eat_once(w2, n2)
	check(r1 == r2 and bool(r1.took), "after a save and load the same member takes the same meal from the family stock (%s, %s)" % [str(r1), str(r2)])
	check(JSON.stringify(w.npc(s.v.id).inv.items) == JSON.stringify(w2.npc(s.v.id).inv.items) and n.hunger == n2.hunger, "and the stock and hunger match")
	var a := setup()
	var b := setup()
	var ra := _eat_once(a.w, a.hungry)
	var rb := _eat_once(b.w, b.hungry)
	check(ra == rb and JSON.stringify(a.v.inv.items) == JSON.stringify(b.v.inv.items), "two identical worlds give the same result (deterministic)")
	w.dispose()
	w2.dispose()
	a.w.dispose()
	b.w.dispose()
