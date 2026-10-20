extends SceneTree
## OD-19 (owner, 2026-10-20) and PAR-02A: the reserve is a dynamic assessment of a household's foreseeable necessities,
## not a fixed coin floor (World.necessity, World.reserve_of, World.can_afford). The decision's nine scenarios.
## Run:
##   godot --headless --path game --script res://tests/reserve_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	scenarios(w)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func members(w: World, n: NPC) -> Array:
	return w.brain._members(n.household)


## Empty a household's food, logs and medicine (pantry and pockets), as if it had nothing put by.
func bare(w: World, n: NPC) -> void:
	var stores: Array = [w.households[n.household].pantry]
	for m: NPC in members(w, n):
		stores.append(m.inv)
	for inv: Inventory in stores:
		for id in NPCBrain.FOOD + NPCBrain.MEDICINES + ["log"]:
			inv.items.erase(id)


func scenarios(w: World) -> void:
	var fam: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and members(w, n).size() >= 3 and n.job == "farmer":
			fam = n
			break
	check(fam != null, "a farming family of three or more")
	var pantry: Inventory = w.households[fam.household].pantry
	# 1. well stocked, few expenses: nothing to keep back
	bare(w, fam)
	pantry.add("pottage", 60)
	pantry.add("log", 10)
	var r1 := w.necessity(fam)
	check(int(r1.food) == 0 and int(r1.fuel) == 0 and int(r1.need) == 0 and int(r1.reserve) == 0, "1. a well-stocked household with few expenses keeps nothing back (%s)" % str(r1))
	# 2. dependants and little food: a real reserve, larger for a larger household
	bare(w, fam)
	var r2 := w.necessity(fam)
	check(int(r2.food) > 0 and int(r2.fuel) > 0, "2. a household with dependants and no food keeps money for food and firewood (%s)" % str(r2))
	var lone: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and members(w, n).size() == 1:
			lone = n
			break
	if lone != null:
		bare(w, lone)
		check(int(w.necessity(lone).food) < int(r2.food), "   and one living alone needs less for food than a family")
	# 3. a merchant with goods but little cash: goods are not food; food in stock is
	var gm: NPC = w.npcs.filter(func(o): return o.alive and w.brain.buy_role(o) == "merchant_goods")[0]
	bare(w, gm)
	gm.inv.add("iron_sword", 3)
	gm.coins = 5
	var r3 := w.necessity(gm)
	check(int(r3.food) > 0, "3. a goods merchant with stock but no food still needs money for food (%s)" % str(r3))
	var fm: NPC = w.npcs.filter(func(o): return o.alive and w.brain.buy_role(o) == "merchant_food")[0]
	bare(w, fm)
	var bare_food := int(w.necessity(fm).food)
	fm.inv.add("pottage", 40)
	check(int(w.necessity(fm).food) < bare_food, "   a food merchant's own food stock lowers what they keep for food")
	# 4. an obligation falling due: the rent
	bare(w, fam)
	pantry.add("pottage", 60)
	pantry.add("log", 10)
	var lease: Dictionary = {}
	for r in w.property.records():
		if w.tenant_of(r) == World.hh_ref(fam.household):
			lease = r
			break
	if lease.is_empty():
		lease = w.property.records()[0]
	var keep := [w.tenant_of(lease), lease.get("rent", 0), lease.get("due_day", -1)]
	w.set_tenant(lease, World.hh_ref(fam.household), 7)
	lease.due_day = w.day() + 1
	check(int(w.necessity(fam).rent) == 7 + int(lease.get("arrears", 0)) and int(w.necessity(fam).need) >= 7, "4. rent falling due is kept back (%s)" % str(w.necessity(fam)))
	w.set_tenant(lease, str(keep[0]), int(keep[1]))
	lease.due_day = keep[2]
	# 5. food with reserved money; 6. stock only above the reserve
	bare(w, fam)
	w._reserve_cache.clear()
	var res := w.reserve_of(fam)
	for m: NPC in members(w, fam):
		if m != fam:
			m.coins = 0
	w._reserve_cache.clear()
	res = w.reserve_of(fam)
	fam.coins = maxi(1, res)
	check(res > 0 and w.can_afford(fam, mini(3, fam.coins), true), "5. a villager may spend reserved money on food for the household (%d reserved)" % res)
	check(not w.can_afford(fam, 3), "6. but not on goods or stock that would eat into it")
	fam.coins = res + 10
	check(w.can_afford(fam, 10) and not w.can_afford(fam, 11), "   above the reserve they may, and only so far")
	# 6b. a business purchase needed to keep earning: a trader out of an input of their trade may buy one unit with
	# reserved coins; with one in hand they work it before buying more (OD-19 section 3)
	var tanner: NPC = w.npcs.filter(func(o): return o.alive and o.job == "tanner")[0]
	bare(w, tanner)
	tanner.inv.items.erase("rabbit_pelt")
	for m: NPC in members(w, tanner):
		if m != tanner:
			m.coins = 0
	w._reserve_cache.clear()
	var tres := w.reserve_of(tanner)
	var pp := w.buy_price(tanner, "rabbit_pelt")
	tanner.coins = maxi(pp, tres - 1)
	check(tres > 0 and tanner.coins - pp < tres and w.can_afford(tanner, pp, false, "rabbit_pelt"), "6b. a tanner with no pelts buys one into their reserve, to keep earning (reserve %d)" % tres)
	tanner.inv.add("rabbit_pelt", 1)
	check(not w.can_afford(tanner, pp, false, "rabbit_pelt"), "   with one in hand, no more until it is worked")
	check(not w.can_afford(tanner, pp, false, "iron_ore"), "   and nothing outside their trade")
	tanner.inv.items.erase("rabbit_pelt")
	# 7. expected income that fails to arrive
	var guard: NPC = w.npcs.filter(func(o): return o.alive and o.job == "guard" and o.household >= 0)[0]
	bare(w, guard)
	var t0 := w.treasury
	w.treasury = 100000
	var with_pay := w.necessity(guard)
	w.treasury = 0
	var no_pay := w.necessity(guard)
	w.treasury = t0
	check(int(with_pay.income) > 0 and int(no_pay.income) == 0 and int(no_pay.need) > int(with_pay.need), "7. a guard counts on their wage while the manor can pay it, and keeps more back when it cannot (%d -> %d)" % [int(with_pay.need), int(no_pay.need)])
	# 8. the player: the same calculation, and the same rule when selling to a villager
	var pr := w.necessity(w.player)
	check(pr.has("reserve") and pr.has("food") and pr.has("rent"), "8. the player's foreseeable needs come from the same calculation (%s)" % str(pr))
	var smith: NPC = w.npcs.filter(func(o): return o.alive and o.job == "smith")[0]
	w._reserve_cache.clear()
	var sr := w.reserve_of(smith)
	var price := w.buy_price(smith, "iron_ore")
	smith.coins = sr + price - 1
	w.player.inv.add("iron_ore", 1)
	check(w.player_sell_many(smith, "iron_ore", 1).result == "failed" and not w.can_afford(smith, price), "   the smith will not buy into their reserve from the player, nor from a villager")
	# 9. changing needs, changing reserve
	bare(w, fam)
	var a := int(w.necessity(fam).need)
	pantry.add("pottage", 6)
	var b := int(w.necessity(fam).need)
	fam.hp = fam.max_hp * 0.2
	var c := int(w.necessity(fam).need)
	fam.hp = fam.max_hp
	check(b < a and c > b, "9. food in store lowers the reserve, an injury with no medicine raises it (%d, %d, %d)" % [a, b, c])
	# determinism: the same world, the same reserves
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 1)
	var same := true
	var w3 := World.new()
	w3.setup(VillageMap.load_default(), 1)
	for i in w2.npcs.size():
		same = same and w2.necessity(w2.npcs[i]) == w3.necessity(w3.npcs[i])
	check(same, "the reserve is deterministic: the same world gives the same reserves")
