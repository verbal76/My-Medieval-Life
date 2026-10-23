extends SceneTree
## REC-F1: a producer holding goods nobody buys waits for the 30 minutes its plan says, rather than deciding again every
## tick. World._run_plan loads a work step's minutes only after a walk or an act, so a plan that is a lone work step
## (NPCBrain._plan_sell with no buyer, a woodcutter waiting for trees) ended on the next tick. Checks: the wait lasts
## its minutes with no further decide(); it then ends; and once a buyer exists the next plan carries the goods to them.
##   godot --headless --path game --script res://tests/recf1_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var b: NPCBrain = w.brain
	var seller: NPC = null
	var buyers: Array = []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and b.buy_role(n) == "merchant_goods":
			buyers.append(n)
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job == "stonecutter" or (seller == null and n.alive and n.role == "adult" and n.job != "" and b.buy_role(n) != "merchant_goods"):
			seller = n
			break
	check(seller != null, "a villager to hold the goods")
	# nobody buys feathers (merchant_goods only): take the goods buyers out of the village
	for o: NPC in buyers:
		o.alive = false
	NPC.roles_version += 1
	check(b._buyer_for(seller, "feather") == null, "no buyer for feathers")
	seller.inv.add("feather", 3)
	seller.plan.clear()
	var before := int(b.decide_calls.get(seller.id, 0))
	check(b._plan_sell(seller, "feather"), "the producer plans with no buyer")
	check(seller.plan.size() == 1 and seller.plan[0].k == "work" and float(seller.plan[0].min) == 30.0, "the plan is one 30-minute wait")
	check(seller.work_left == 30.0, "the wait is loaded with its own minutes")
	# 29 game minutes, a minute at a time: the plan stands and nobody decides again
	for i in 29:
		w._run_plan(seller, 0.5, 1.0)
	check(not seller.plan.is_empty(), "after 29 minutes the wait is still the plan")
	check(int(b.decide_calls.get(seller.id, 0)) == before, "and decide() was not called again")
	for i in 3:
		w._run_plan(seller, 0.5, 1.0)
	check(seller.plan.is_empty(), "the wait ends after its 30 minutes, to decide afresh")
	# a buyer appears: the next plan takes the goods to them
	for o: NPC in buyers:
		o.alive = true
	NPC.roles_version += 1
	var buyer: NPC = b._buyer_for(seller, "feather")
	if buyer == null:
		print("note: no goods buyer would take feathers in this village state (coins); buyer check skipped")
	else:
		seller.plan.clear()
		b._plan_sell(seller, "feather")
		check(seller.plan.size() == 2 and seller.plan[0].k == "go" and seller.plan[1].act == "sell_to", "with a buyer, the goods are taken to them at once")
	_test_simf9(w, b)
	_test_blocked_chase(w, b)
	print("%d checks, %d failures" % [checks, failures])
	w.dispose()
	quit(1 if failures > 0 else 0)


## SIM-F9 (owner 2026-10-23): the same opening-wait defect in eating, taking medicine and a homeless villager's bed. Each
## plan is one work step with its own minutes (10 to eat, 10 to dress a wound, the bed's own rest); a stale spent count left
## from the previous step must not end it at once.
func _lone_lasts(w: World, n: NPC, mins: float, what: String) -> void:
	check(n.plan.size() == 1 and n.plan[0].k == "work" and float(n.plan[0].min) == mins, what + ": one %d-minute step" % int(mins))
	check(n.work_left == mins, what + ": loaded with its own minutes")
	for i in int(mins) - 1:
		w._run_plan(n, 0.5, 1.0)
	check(not n.plan.is_empty(), what + ": still under way a minute before its end")
	for i in 3:
		w._run_plan(n, 0.5, 1.0)
	check(n.plan.is_empty(), what + ": ends after its minutes")


func _test_simf9(w: World, b: NPCBrain) -> void:
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "guard":
			n = o
			break
	# eating cooked food in hand
	n.inv.add("pottage", 1)
	n.plan.clear()
	n.work_left = -7.0                                  # the stale count a finished step leaves behind
	check(b._plan_eat(n), "a villager with cooked food plans to eat")
	_lone_lasts(w, n, 10.0, "eating")
	# dressing a wound with a medicine in hand
	n.hp = 1.0
	n.inv.add("linen_bandage", 1)
	n.plan.clear()
	n.work_left = -7.0
	check(b._plan_heal(n), "a hurt villager with a bandage plans to dress the wound")
	_lone_lasts(w, n, 10.0, "dressing a wound")
	n.hp = n.max_hp
	# a homeless villager resting: the bed's own minutes
	var home := n.home
	n.home = ""
	n.plan.clear()
	n.work_left = -7.0
	b._plan_bed(n, 120.0)
	_lone_lasts(w, n, 120.0, "a homeless villager's rest")
	n.home = home



## SIM-F4 (recorder run 2): a chase walks straight at its target; a wall between them held the chaser on the spot for good
## (no plan, no new decision, so a bandit stalking starved). A blocked chase is now given up and the bandit goes to camp.
func _test_blocked_chase(w: World, b: NPCBrain) -> void:
	var bandit: NPC = null
	var prey: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit" and bandit == null:
			bandit = o
		elif o.alive and o.role == "adult" and o.job != "guard" and prey == null:
			prey = o
	check(bandit != null and prey != null, "a bandit and a villager to chase")
	var found := Vector2i(-1, -1)
	for y in range(2, w.map.h - 2):
		for x in range(4, w.map.w - 6):
			var c := Vector2i(x, y)
			if w.map.is_solid(c) and w.map.is_solid(c + Vector2i(1, 0)) and w.map.is_solid(c + Vector2i(2, 0)) \
					and not w.map.is_solid(c + Vector2i.LEFT) and not w.map.is_solid(c + Vector2i(4, 0)) \
					and w.place_of(Vector2(x - 0.5, y + 0.5)) == "" and w.place_of(Vector2(x + 4.5, y + 0.5)) == "":
				found = c
				break
		if found.x >= 0:
			break
	check(found.x >= 0, "a wall three tiles thick with open ground on both sides")
	bandit.pos = Vector2(found.x - 0.02, found.y + 0.5)      # just short of the wall, the prey beyond it
	prey.pos = Vector2(found.x + 4.5, found.y + 0.5)
	bandit.depth = 0
	prey.depth = 0
	bandit.hp = bandit.max_hp
	bandit.target = prey.id
	bandit.plan.clear()
	b.fight(bandit, 0.5)
	check(bandit.target == -1, "a chase blocked by a wall is given up (the chaser is free to decide again)")
	check(not bandit.plan.is_empty() and str(bandit.plan[0].k) == "go", "the bandit heads back to the camp")
	check(w.map.is_solid(bandit.cell()) == false, "the chaser is not left inside the wall")
