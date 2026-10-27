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

	# 5. the defect class closed (lead, 2026-10-27): the parts trip (cart and plough parts), firewood and grain plan only
	# what buy_from would sell at the bargained price, partial orders in the affordable quantity, and hold a failed one
	var smith: NPC = null
	for n: NPC in w.npcs:
		if smith == null and n.alive and n.role == "adult" and n.job == "smith":
			smith = n
	smith.inv.add("iron_bar", 4)
	if w.asleep(smith):
		smith.anim = "idle"
	var bar_seller: NPC = b._part_seller("iron_bar", buyer)
	check(bar_seller != null, "someone sells iron bars")
	bar_seller.skills["trading"] = Skills.xp_for_level(10)
	buyer.inv.remove("iron_bar", buyer.inv.count("iron_bar"))
	var bl := w.sell_price(bar_seller, "iron_bar")
	var bd := w.deal_price(bl, buyer, bar_seller)
	check(bd > bl, "iron bars: bargained %d above list %d" % [bd, bl])
	buyer.coins = w.reserve_of(buyer) + bl * 2
	check(b._parts_trip(buyer, {"iron_bar": 2}).is_empty(), "parts trip: a purse for two at the list price but not at the bargained price: no trip (was planned, then refused)")
	buyer.coins = w.reserve_of(buyer) + bd * 2 - 1
	check(b._parts_trip(buyer, {"iron_bar": 2}).is_empty(), "parts trip: one coin short of both parts: no partial trip (the parts make one thing)")
	buyer.coins = w.reserve_of(buyer) + bd * 2
	var trip := b._parts_trip(buyer, {"iron_bar": 2})
	check(trip.size() == 2 and int(trip[-1].args.qty) == 2, "parts trip: both bars affordable at the bargained price: the trip is planned")
	b.buy_failed[buyer.id] = {"vendor": bar_seller.id, "item": "iron_bar", "price": bd, "stock": bar_seller.inv.count("iron_bar"), "purse": buyer.coins, "at": w.minutes}
	check(b._parts_trip(buyer, {"iron_bar": 2}).is_empty(), "parts trip: a failed purchase of the same part, nothing changed: held")
	b.buy_failed.erase(buyer.id)
	# firewood and grain for the household (the pantry: the whole purse)
	var hh: Dictionary = w.households[buyer.household]
	var pantry: Inventory = hh.pantry
	for id in pantry.ids():
		pantry.remove(id, pantry.count(id))
	var wood: NPC = b._seller_of("log", buyer)
	check(wood != null, "someone sells logs")
	wood.skills["trading"] = Skills.xp_for_level(10)
	var ll := w.sell_price(wood, "log")
	var ld := w.deal_price(ll, buyer, wood)
	buyer.coins = maxi(3, ll)
	buyer.plan.clear()
	var planned_fw := b._plan_provision(buyer) and buyer.doing == "buying firewood"
	if ld > buyer.coins:
		check(not planned_fw, "firewood: %d coins, list %d, bargained %d: not chosen (was chosen on the list price)" % [buyer.coins, ll, ld])
	else:
		check(planned_fw, "firewood: affordable at the bargained price (%d): chosen" % ld)
	buyer.coins = maxi(3, ld)
	buyer.plan.clear()
	check(b._plan_provision(buyer) and buyer.doing == "buying firewood", "firewood: with the bargained price in the purse it is chosen")
	b.buy_failed[buyer.id] = {"vendor": wood.id, "item": "log", "price": ld, "stock": wood.inv.count("log"), "purse": buyer.coins, "at": w.minutes}
	buyer.plan.clear()
	buyer.doing = "idle"
	var again := b._plan_provision(buyer) and buyer.doing == "buying firewood" and int(buyer.plan[-1].args.vendor) == wood.id
	check(not again, "firewood: a failed purchase from p:%d, nothing changed: not chosen again (%s)" % [wood.id, buyer.doing])
	b.buy_failed.erase(buyer.id)
	pantry.add("log", 1)
	var grain: NPC = b._grain_seller(buyer)
	if grain != null:
		grain.skills["trading"] = Skills.xp_for_level(10)
		var gd := w.deal_price(w.sell_price(grain, "wheat"), buyer, grain)
		buyer.coins = maxi(4, gd)                          # one unit at the bargained price, not two
		buyer.plan.clear()
		var chose := b._plan_provision(buyer) and buyer.doing == "buying grain for the household"
		check(chose and int(buyer.plan[-1].args.qty) == buyer.coins / gd, "grain: the order is the %d unit(s) the purse pays for at %d, not 2" % [buyer.coins / gd, gd])
		b.buy_failed[buyer.id] = {"vendor": grain.id, "item": "wheat", "price": gd, "stock": grain.inv.count("wheat"), "purse": buyer.coins, "at": w.minutes}
		buyer.plan.clear()
		buyer.doing = "idle"
		var again_g := b._plan_provision(buyer) and buyer.doing == "buying grain for the household" and int(buyer.plan[-1].args.vendor) == grain.id
		check(not again_g, "grain: a failed purchase, nothing changed: not chosen again (%s)" % buyer.doing)
		b.buy_failed.erase(buyer.id)
	else:
		check(false, "a grain seller to test with")

	print("\nsim_f2_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
