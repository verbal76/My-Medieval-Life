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
	print("%d checks, %d failures" % [checks, failures])
	w.dispose()
	quit(1 if failures > 0 else 0)
