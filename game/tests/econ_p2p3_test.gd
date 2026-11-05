extends SceneTree
## B25-ECON-P2 and B25-ECON-P3 (owner decisions 2026-11-05; evidence: the 120-day seed 1 run 41967592798 and
## docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md: every adult out of work at day 120 had come of age in the run with
## no coins and no tool, while elders held 68 iron ore, 47 coal, 24 iron bars, 8 pickaxes and 7 axes).
## P2: the household buys a member's first work tool from its own purse when it can afford it (its keep respected), from a
## real seller at market price; the place needing the tool is open to them; no manor lending; coins only move.
## P3: elders and adults between jobs offer trade stock they no longer use through the existing sell rule at market prices;
## not food or necessities, not a tool a household member still needs, not a work tool while between jobs.
##   godot --headless --path game --script res://tests/econ_p2p3_test.gd

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
	test_first_tool_bought_by_household()
	test_first_tool_keep_respected()
	test_elder_sells_stock()
	test_kept_stock()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 10.0 * 60.0          # day 1, 10:00: shops open, sellers awake
	return w


## A household of at least two living members: [household, the young adult with no job, coins or tool, another member].
func young_and_kin(w: World) -> Array:
	for h in w.households.size():
		var ms: Array = w.brain._members(h)
		if ms.size() < 2 or w.households[h].get("ended", false) or w.households[h].has("homestead"):
			continue
		var n: NPC = ms[0]
		var kin: NPC = ms[1]
		if n.job != "":
			w.brain._change_job(n, "", "test: between jobs")
		n.role = "adult"
		n.coins = 0
		for t in ["axe", "pickaxe"]:
			n.inv.remove(t, n.inv.count(t))
		w.experience.minutes.erase(World.npc_ref(n.id))
		for o: NPC in ms:
			o.plan.clear()
		return [h, n, kin]
	return []


## A seller of pickaxes, awake and at work (the smith).
func pickaxe_seller(w: World) -> NPC:
	var s: NPC = w.brain._first_with_job("smith")
	s.inv.add("pickaxe", 2)
	s.anim = "idle"
	return s


func test_first_tool_bought_by_household() -> void:
	var w := new_world()
	var hk := young_and_kin(w)
	var n: NPC = hk[1]
	var kin: NPC = hk[2]
	var s := pickaxe_seller(w)
	var price: int = w.brain.tool_price(n, "pickaxe")
	kin.coins = 1000
	check(price > 0 and w.brain.first_tool_help(n, "miner", "pickaxe", price) == price,
			"a coinless young adult's household puts up a first pickaxe's price (%d)" % price)
	var market: Dictionary = w.brain.job_market()
	market.miner.open = 1
	var jobs: Array = (w.brain._job_options(n, market)[2] as Array).map(func(o): return str(o[0]))
	check(jobs.has("miner"), "the miner's place is open to them though they have no coins of their own (%s)" % [jobs])
	w.brain._change_job(n, "miner", "test")
	check(not w.brain.tool_short(n), "with the household behind them they are not counted short of the tool")
	var total0 := w.total_coins()
	var hh0: int = w.property.purse(World.hh_ref(n.household))
	w.brain._get_tool(n, "pickaxe")
	check(str(n.doing) == "buying a new pickaxe" and not n.plan.is_empty(), "they go to buy it (%s)" % n.doing)
	check(int(w.stats.get("household_first_tools", 0)) == 1 and n.coins > 0, "the household handed them the coins (%d)" % n.coins)
	if n.plan.is_empty():
		return
	var step: Dictionary = n.plan[-1]
	var seller := w.npc(int(step.args.get("vendor", -1)))
	check(seller != null and seller.inv.has("pickaxe"), "from a real seller holding one")
	if seller == null:
		return
	var paid: int = w.deal_price(w.sell_price(seller, "pickaxe"), n, seller)
	var sc0 := seller.coins
	n.pos = Vector2(w.brain._workplace_cell(seller))
	check(w.brain.act(n, "buy_from", step.args), "and buys it")
	check(n.inv.has("pickaxe") and seller.coins == sc0 + paid, "the pickaxe is theirs; the seller has the market price (%d)" % paid)
	check(w.property.purse(World.hh_ref(n.household)) == hh0 - paid and w.total_coins() == total0, "paid from the household's purse; coins only moved")
	check(w.manor_orders.filter(func(x): return int(x["for"]) == n.id).is_empty(), "no manor order or advance")
	# a worker already in the trade (a recorded working day) is not helped: their tool is the manor's order (EQ-19)
	n.inv.remove("pickaxe", 1)
	n.coins = 0
	w.experience.minutes[World.npc_ref(n.id)] = {"mining": 480.0 * 3}
	check(w.brain.first_tool_help(n, "miner", "pickaxe", price) == 0, "a replacement tool is not a first tool: no household help")
	s.inv.remove("pickaxe", s.inv.count("pickaxe"))


func test_first_tool_keep_respected() -> void:
	var w := new_world()
	var hk := young_and_kin(w)
	var h: int = hk[0]
	var n: NPC = hk[1]
	var kin: NPC = hk[2]
	pickaxe_seller(w)
	var price: int = w.brain.tool_price(n, "pickaxe")
	var keep: int = w.construction._keep(h, w.brain._members(h).size())
	for o: NPC in w.brain._members(h):
		o.coins = 0
	kin.coins = keep + price - 1                   # one coin short of the price above the household's keep
	check(w.brain.first_tool_help(n, "miner", "pickaxe", price) == 0, "a household that would dip into its keep does not buy it")
	var market: Dictionary = w.brain.job_market()
	market.miner.open = 1
	var jobs: Array = (w.brain._job_options(n, market)[2] as Array).map(func(o): return str(o[0]))
	check(not jobs.has("miner"), "nor is the miner's place theirs to take")
	kin.coins = keep + price
	check(w.brain.first_tool_help(n, "miner", "pickaxe", price) == price, "with the price above its keep it does")


## An elder of a household holding trade stock: [elder, household].
func elder_with_stock(w: World) -> Array:
	var hk := young_and_kin(w)
	var e: NPC = hk[2]
	if e.job != "":
		w.brain._change_job(e, "", "retired in old age")
	e.role = "elder"
	e.hunger = 100.0
	e.hp = e.max_hp
	e.coins = 50
	for id in e.inv.ids():
		e.inv.remove(id, e.inv.count(id))
	return [e, hk[0], hk[1]]


func test_elder_sells_stock() -> void:
	var w := new_world()
	var eh := elder_with_stock(w)
	var e: NPC = eh[0]
	e.inv.add("iron_ore", 6)
	var total0 := w.total_coins()
	w.brain.decide(e)
	check(str(e.doing).begins_with("taking iron ore to"), "an elder holding iron ore takes it to a buyer (%s)" % e.doing)
	if e.plan.is_empty():
		return
	var step: Dictionary = e.plan[-1]
	var buyer := w.npc(int(step.args.get("buyer", -1)))
	check(buyer != null and NPCBrain.OUTLETS.iron_ore.has(w.brain.buy_role(buyer)), "to one of the trade's own buyers (%s)" % (buyer.job if buyer else "-"))
	if buyer == null:
		return
	var qty: int = w.purchase_qty(buyer, e, "iron_ore", 6)
	var price := 0
	for c in w.sale_prices(buyer, e, "iron_ore", qty):
		price += int(c)
	var c0 := e.coins
	e.pos = Vector2(w.brain._workplace_cell(buyer))
	check(w.brain.act(e, "sell_to", step.args), "and sells it")
	check(qty > 0 and e.inv.count("iron_ore") == 6 - qty and e.coins == c0 + price, "%d sold at the buyer's market price (%d)" % [qty, price])
	check(w.total_coins() == total0, "coins only moved")
	# an adult between jobs does the same
	var n: NPC = eh[2]
	n.inv.add("coal", 4)
	n.hunger = 100.0
	n.hp = n.max_hp
	var ok := false
	for id in n.inv.ids():
		if w.brain._plan_sell_stock(n):
			ok = str(n.doing).begins_with("taking ")
			break
	check(ok, "an adult between jobs offers their trade stock too (%s)" % n.doing)


func test_kept_stock() -> void:
	var w := new_world()
	var eh := elder_with_stock(w)
	var e: NPC = eh[0]
	var n: NPC = eh[2]
	e.inv.add("wheat", 5)
	e.inv.add("log", 3)
	e.inv.add("iron_sword", 1)
	e.inv.add("flower_seed", 2)
	check(not w.brain._plan_sell_stock(e), "food, firewood, a sword and seed are not offered as stock")
	e.inv.add("pickaxe", 1)
	w.brain._change_job(n, "miner", "test")
	n.inv.remove("pickaxe", n.inv.count("pickaxe"))
	check(w.brain.stock_kept(e, "pickaxe") and not w.brain._plan_sell_stock(e), "a pickaxe a miner of the household lacks is kept")
	n.inv.add("pickaxe", 1)
	check(not w.brain.stock_kept(e, "pickaxe"), "once that miner has one, the elder's spare pickaxe is stock to sell")
	w.brain._change_job(n, "", "test: between jobs")
	check(w.brain.stock_kept(n, "pickaxe"), "an adult between jobs keeps a work tool (the next place may need it)")
	var a: NPC = w.brain._first_with_job("smith")
	a.inv.add("iron_ore", 3)
	check(not w.brain._plan_sell_stock(a), "a working adult is not covered by this rule")
