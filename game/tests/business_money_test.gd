extends SceneTree
## ECON-P3 (owner 2026-10-23): business money and household money are separate. A villager household's storefront keeps
## its sales in its own till; each morning the household draws what its necessity reserve lacks, the owner pays
## themselves a share above the till's working reserve, and a till below it is topped up from spendable coins; the
## player moves money between purse and till by choice, and the shop's expenses come from its till first. Coins are
## conserved, old saves load unchanged, and the same seed gives the same result. Run:
##   godot --headless --path game --script res://tests/business_money_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   ", what)
	else:
		failures += 1
		print("FAIL ", what)


func _init() -> void:
	GameData.ensure()
	_storefront()
	_player()
	var a := _signature()
	var b := _signature()
	check(a == b, "the same seed gives the same tills and purses (%s)" % a)
	print("business_money_test: %d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A world on day 1, 10:00 with a villager keeping a storefront at their household's house.
func _world() -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 10.0 * 60.0
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.home != "" and w.buildings.has(o.home) \
				and w.holds(World.hh_ref(o.household), w.buildings[o.home]) and w.business.front_place(w.buildings[o.home]).size() > 0:
			n = o
			break
	var house: Dictionary = w.buildings[n.home]
	house["front"] = w.business.front_place(house)
	w.front_keepers[n.home] = n.id
	n.plan.clear()
	n.target = -1
	n.pos = Vector2(int(house.front.use[0]) + 0.5, int(house.front.use[1]) + 0.5)
	n.inv.add("herbal_poultice", 6)
	return {"w": w, "n": n, "house": house}


func _storefront() -> void:
	var s := _world()
	var w: World = s.w
	var n: NPC = s.n
	var house: Dictionary = s.house
	check(w.at_post(n) and w.business.money.keeping(n) == house, "the keeper stands at the household's storefront")
	var all := w.total_coins()
	var purse := n.coins
	w.player.coins += 100
	all += 100
	check(w.trade(w.player, n, "herbal_poultice", 2, 6), "the player buys two poultices at the counter")
	check(n.coins == purse and BusinessMoney.till_of(house) == 12, "the sale (12 coins) went to the storefront's till, not the keeper's purse")
	check(w.total_coins() == all and w.business.tills() == 12, "the till counts in the village's coins; none made or lost")
	# a villager who is not at the counter keeps what they sell
	var other: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != n and o.household >= 0:
			other = o
			break
	other.inv.add("herbal_poultice", 1)
	var oc := other.coins
	check(w.trade(w.player, other, "herbal_poultice", 1, 5) and other.coins == oc + 5 and BusinessMoney.till_of(house) == 12, "a sale by anyone not keeping the counter stays in their purse")
	all = w.total_coins()

	# necessity first: a household short of its reserve draws from the till, below the working reserve
	house.front.till = 40
	var reserve := w.reserve_of(n)
	n.coins = maxi(0, reserve - 15)
	var short := maxi(0, reserve - n.coins)
	var draw := mini(short, 40)
	var pay := int(float(40 - draw - BusinessMoney.reserve_coins()) * BusinessMoney.payout_share())
	var before := n.coins
	all = w.total_coins()
	w.business.money.daily()
	check(n.coins == before + draw + maxi(0, pay), "the household drew its shortfall (%d) and the owner paid themselves %d from the till" % [draw, maxi(0, pay)])
	check(BusinessMoney.till_of(house) == 40 - draw - maxi(0, pay), "the till holds the rest (%d)" % BusinessMoney.till_of(house))
	check(w.total_coins() == all, "moving money between till and purse creates and loses nothing")

	# the owner's share only above the working reserve
	house.front.till = BusinessMoney.reserve_coins()
	n.coins = reserve + 50
	before = n.coins
	w.business.money.daily()
	check(n.coins == before and BusinessMoney.till_of(house) == BusinessMoney.reserve_coins(), "a till at its working reserve pays nothing out")

	# a till below the reserve is topped up from spendable coins only
	house.front.till = 3
	n.coins = reserve + 4
	all = w.total_coins()
	w.business.money.daily()
	check(BusinessMoney.till_of(house) == 3 + mini(BusinessMoney.reserve_coins() - 3, 4) and n.coins == reserve + 4 - mini(BusinessMoney.reserve_coins() - 3, 4),
			"the top-up came from coins above the necessity reserve, never below it")
	house.front.till = 3
	n.coins = maxi(0, reserve - 1)
	w.business.money.daily()
	check(BusinessMoney.till_of(house) <= 3 and w.spendable(n) == 0, "a household at or below its reserve puts nothing into the till")

	# an ended household's till goes to the manor
	house.front.till = 25
	var tenant_was: String = house.get("tenant", "")
	var owner_was: String = house.owner
	house.owner = "hh:99999"
	house.tenant = ""
	var t0 := w.treasury
	all = w.total_coins()
	w.business.money.daily()
	check(w.treasury == t0 + 25 and BusinessMoney.till_of(house) == 0 and w.total_coins() == all, "nobody left of the household: the till goes to the manor, conserved")
	house.owner = owner_was
	house.tenant = tenant_was

	# saves: an older save has no till; a newer one keeps it
	house.front.till = 17
	house.front["earned"] = 30
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(BusinessMoney.till_of(w2.buildings[house.id]) == 17 and w2.total_coins() == w.total_coins(), "save and load keep the till and every coin")
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	for b: Dictionary in old.buildings.values():
		if b.has("front"):
			b.front.erase("till")
			b.front.erase("earned")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(BusinessMoney.till_of(w3.buildings[house.id]) == 0 and w3.business.tills() == w3.business.tills(), "a save made before tills reads as empty tills: nothing moves on load")
	var c0 := w3.total_coins()
	w3.business.money.daily()
	check(w3.total_coins() == c0, "and the first morning on an older save keeps every coin")


func _player() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 10.0 * 60.0
	w.player.coins = 200
	check(w.business.rent() == "", "the player rents a pitch")
	var s: Dictionary = w.business.mine()
	var all := w.total_coins()
	check(w.business.deposit(s, 30) == "" and int(s.till) == 30 and w.total_coins() == all, "the player puts 30 coins into the till of their own choice")
	check(w.business.deposit(s, 100000) != "" and int(s.till) == 30, "more than the purse holds is refused")
	check(w.business.withdraw(s, 10) == "" and int(s.till) == 20 and w.total_coins() == all, "and takes 10 back out")
	check(w.business.withdraw(s, 500) != "" and int(s.till) == 20, "more than the till holds is refused")
	# expenses come from the till first
	var rent := w.business.rent_of(s)
	s.till = rent
	var purse := int(w.player.coins)
	check(w.business._charge(s, rent) and int(s.till) == 0 and w.player.coins == purse + rent, "the stall's rent is paid from its till first (the coins pass through the purse and the caller pays them)")
	# the purse covers only what the till cannot, and only above the necessity reserve
	s.till = 0
	var reserve := w.reserve_of(w.player)
	w.player.coins = reserve + rent - 1
	check(not w.business._charge(s, rent) and w.player.coins == reserve + rent - 1, "a purse that would dip into the necessity reserve is not drawn on, and nothing moves")
	w.player.coins = reserve + rent + 3
	check(w.business._charge(s, rent), "with coins above the reserve the purse covers the shortfall")
	check(w.spendable(w.player) == maxi(0, int(w.player.coins) - w.reserve_of(w.player)), "World.spendable is the purse above the necessity reserve")


func _signature() -> String:
	var s := _world()
	var w: World = s.w
	var n: NPC = s.n
	w.trade_hook = Callable()
	w.player.coins += 50
	w.trade(w.player, n, "herbal_poultice", 3, 7)
	n.coins = 5
	for i in 3:
		w.minutes += 1440.0
		w.business.money.daily()
	return "till %d purse %d total %d" % [BusinessMoney.till_of(s.house), n.coins, w.total_coins()]
