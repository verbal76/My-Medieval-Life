extends SceneTree
## SIM-F2 (owner D17, answer C, ENGINEERING): a failing purchase is not chosen again and again.
## Root cause: the dressers' trip to buy a mallet or an iron chisel (NPCBrain._fetch_dress_tool, and the stone in
## _fetch_dress_stone) was chosen on the seller's list price (World.sell_price), while buy_from pays the bargained price
## (World.deal_price: the seller's Trading raises it). A purse between the two planned a purchase the act refused, the empty
## plan chose it again at once, all day (recorder run 1: 328 failed chisel purchases; seed 1 at 87b69ab: 80 on day 2).
## Checks: the decision uses the act's own price and rule (buy_open); a purchase that failed anyway is held while the price,
## the seller's stock and the purse are unchanged, and for at most BUY_RETRY_MINUTES (buy_held); conservation of the act.
##   godot --headless --path game --script res://tests/sim_f2_test.gd

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
	var buyer: NPC = null
	var seller: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and buyer == null and n.job == "laborer":
			buyer = n
		if n.alive and n.role == "adult" and seller == null and b.buy_role(n) == "merchant_goods":
			seller = n
	check(buyer != null and seller != null, "a labourer and a goods merchant")
	for n: NPC in w.npcs:                      # only this seller has chisels, so the trip can only be to them
		if n != seller:
			n.inv.remove("chisel", n.inv.count("chisel"))
	buyer.inv.remove("chisel", buyer.inv.count("chisel"))
	seller.inv.add("chisel", 2)
	seller.skills["trading"] = Skills.xp_for_level(10)      # a master merchant: the bargained price is above the list price
	if w.asleep(seller):
		seller.anim = "idle"
	var list := w.sell_price(seller, "chisel")
	var deal := w.deal_price(list, buyer, seller)
	check(deal > list, "the seller's Trading puts the bargained price (%d) above the list price (%d)" % [deal, list])
	var reserve := w.reserve_of(buyer)

	# 1. the purse between the two prices: the old rule planned the trip, the act refuses it; the decision no longer chooses it
	buyer.coins = reserve + list
	check(buyer.coins - w.reserve_of(buyer) >= list, "the old list-price rule would have planned the trip")
	check(not b.buy_open(buyer, seller, "chisel"), "buy_open: the bargained price is not affordable above the reserve")
	buyer.plan.clear()
	check(not b._fetch_dress_tool(buyer, "chisel"), "the chisel trip is not chosen")
	check(buyer.plan.is_empty(), "and no plan is made")
	var coins0 := buyer.coins + seller.coins
	check(not b.act(buyer, "buy_from", {"vendor": seller.id, "item": "chisel", "qty": 1}), "the act itself refuses it, as before")
	check(buyer.coins + seller.coins == coins0 and seller.inv.count("chisel") == 2 and buyer.inv.count("chisel") == 0, "nothing moved")

	# 2. the failed purchase is held while nothing that decided it changed
	check(b.buy_failed.has(buyer.id), "the failure is remembered")
	check(b.buy_held(buyer, seller, "chisel"), "held: same price, stock and purse")
	buyer.coins += 1
	check(not b.buy_held(buyer, seller, "chisel"), "released when the purse changes")
	buyer.coins -= 1
	seller.inv.add("chisel", 1)
	check(not b.buy_held(buyer, seller, "chisel"), "released when the seller's stock changes")
	seller.inv.remove("chisel", 1)
	seller.skills["trading"] = 0
	check(not b.buy_held(buyer, seller, "chisel"), "released when the price changes")
	seller.skills["trading"] = Skills.xp_for_level(10)
	check(b.buy_held(buyer, seller, "chisel"), "held again with everything back as it was")
	w.minutes += NPCBrain.BUY_RETRY_MINUTES
	check(not b.buy_held(buyer, seller, "chisel"), "released after BUY_RETRY_MINUTES whatever happened (bounded)")
	w.minutes -= NPCBrain.BUY_RETRY_MINUTES

	# 3. with the bargained price in the purse the trip is chosen and the purchase goes through, ledger exact
	buyer.coins = w.reserve_of(buyer) + deal
	check(b.buy_open(buyer, seller, "chisel"), "affordable at the bargained price")
	check(b._fetch_dress_tool(buyer, "chisel"), "the trip is chosen")
	coins0 = buyer.coins + seller.coins
	check(b.act(buyer, "buy_from", {"vendor": seller.id, "item": "chisel", "qty": 1}), "and the purchase goes through")
	check(buyer.inv.count("chisel") == 1 and seller.inv.count("chisel") == 1 and buyer.coins + seller.coins == coins0, "one chisel moved, coins conserved")
	check(not b.buy_failed.has(buyer.id), "a purchase clears the remembered failure")

	# 4. a decision loop: the dresser, deciding every tick for an hour with the purse between the prices, never plans it
	buyer.inv.remove("chisel", 1)
	buyer.coins = w.reserve_of(buyer) + list
	var chosen := 0
	for i in 120:
		buyer.plan.clear()
		if b._fetch_dress_tool(buyer, "chisel"):
			chosen += 1
	check(chosen == 0, "120 decisions, the unaffordable chisel chosen %d times (was every time)" % chosen)

	print("\nsim_f2_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
