extends SceneTree
## DVW-B3-CHAPEL (owner, 2026-10-23): the chapel, its two clergy, offerings, relief from the church first, the church's farm plot
## (volunteers or the clergy), saves and a save from before the chapel. Run:
##   godot --headless --path game --script res://tests/chapel_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_places()
	test_offerings()
	test_wages()
	test_alms()
	test_relief_first()
	test_relief_bought()
	test_plot_work()
	test_player()
	test_player_volunteers()
	test_law_and_claims()
	test_save()
	test_old_save()
	test_b17_save()
	test_days()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func jobber(w: World, job: String) -> Array:
	return w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job == job)


## A household (index >= 3) with an adult, its pantry, stores and cash emptied: short of food.
func hungry_household(w: World) -> int:
	for h in range(3, w.households.size()):
		var ms: Array = w.brain._members(h)
		if ms.any(func(o: NPC) -> bool: return o.role == "adult" and not Chapel.is_clergy(o)):
			(w.households[h].pantry as Inventory).items.clear()
			for o: NPC in ms:
				o.inv.items.clear()
				w.treasury += o.coins          # (set aside: the coins stay in the village)
				o.coins = 0
			return h
	return -1


func adult_of(w: World, h: int) -> NPC:
	for o: NPC in w.brain._members(h):
		if o.role == "adult":
			return o
	return null


func test_places() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	check(c.present and w.buildings.has(c.bid) and str(w.buildings[c.bid].type) == "chapel", "a new world has the chapel building")
	var pr := jobber(w, "preacher")
	var asst := jobber(w, "church_assistant")
	check(pr.size() == 1 and asst.size() == 1, "one preacher and one church assistant")
	for n: NPC in pr + asst:
		check(n.workplace == "chapel" and n.household >= 0 and w.households[n.household].members.has(n.id) and w.building_door(n.home) != Vector2i.ZERO, "%s is housed and works at the chapel" % n.job)
	var m: Dictionary = w.brain.job_market()
	check(int(m.preacher.open) == 0 and int(m.church_assistant.open) == 0, "both places are filled in a new world")
	check(c.wage_of("preacher") < int(GameData.b("manor_wage_per_day")) and c.wage_of("church_assistant") < c.wage_of("preacher"), "the clergy's wage is low, below the manor's day wage")
	var fp: Dictionary = c.plot
	check(bool(fp.farm.fence) and w.farm_plots.plots().has(fp) and w.map.is_solid(Vector2i(int(fp.x), int(fp.y))) and not w.map.is_solid(Vector2i(int(fp.farm.gate[0]), int(fp.farm.gate[1]))), "the plot is fenced round, with its gate open")
	check(c.store.count("wheat_seed") == int(c.cfg().plot_seed), "a new world's church starts with its seed corn")
	var path := w.map.find_path(w.brain.beside(Vector2i(int(fp.farm.gate[0]), int(fp.farm.gate[1])), w.building_door(c.bid)), w.building_door(c.bid))
	check(not path.is_empty(), "the plot's gate and the chapel's door are reachable from each other")
	var dead: NPC = pr[0]
	dead.alive = false
	check(int(w.brain.job_market().preacher.open) == 1, "if the preacher dies the place opens in the labour market")


func test_offerings() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	for n: NPC in w.npcs:
		if n.alive and n.role in ["adult", "elder"]:
			n.coins += 60
	for h in range(3, w.households.size()):
		(w.households[h].pantry as Inventory).add("wheat", 40)
	var coins0 := w.total_coins()
	var wheat0 := 0
	for hh in w.households:
		wheat0 += (hh.pantry as Inventory).count("wheat")
	wheat0 += c.store.count("wheat")
	var r := c.offerings()
	check(int(r.coins) > 0 and c.coins == int(r.coins), "the pious give coins to the fund (%d)" % int(r.coins))
	check(int(r.wheat) > 0 and c.store.count("wheat") == int(r.wheat), "households give wheat to the store (%d)" % int(r.wheat))
	var wheat1 := c.store.count("wheat")
	for hh in w.households:
		wheat1 += (hh.pantry as Inventory).count("wheat")
	check(w.total_coins() == coins0 and wheat1 == wheat0, "offerings move coins and wheat, they make none")
	var low := 0
	for n: NPC in w.npcs:
		if n.alive and n.role in ["adult", "elder"] and c.piety(n) < float(c.cfg().min_piety):
			low += 1
	check(low > 0 and c.piety(w.npcs[3]) == c.piety(w.npcs[3]) and c.piety(w.npcs[3]) == new_world().chapel.piety(w.npcs[3]), "piety is a fixed number, the same in another world of the same seed; some give nothing")
	var poor: NPC = w.npcs[20]
	poor.coins = 3
	var before: int = poor.coins
	c.offerings()
	check(poor.coins == before, "someone with nothing above their reserve gives nothing")
	check(c.is_service_day() == ((w.day() + 1) % 7 == 0), "the weekly service day")


func test_wages() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	var pr: NPC = jobber(w, "preacher")[0]
	var asst: NPC = jobber(w, "church_assistant")[0]
	c.coins = 100
	var total0 := w.total_coins()
	var p0 := pr.coins
	var a0 := asst.coins
	c.evening()
	check(pr.coins == p0 + c.wage_of("preacher") and asst.coins == a0 + c.wage_of("church_assistant") and w.total_coins() == total0, "the wages are paid from the fund; coins are conserved")
	c.coins = 0
	c.evening_day = -1
	w.minutes += 1440.0
	c.evening()
	check(pr.coins == p0 + c.wage_of("preacher") and int(c.owed.get(str(pr.id), 0)) == c.wage_of("preacher"), "with an empty fund nothing is made: the wage is owed")
	c.coins = 100
	c.evening_day = -1
	w.minutes += 1440.0
	c.evening()
	check(pr.coins == p0 + 3 * c.wage_of("preacher") and c.owed.is_empty(), "what is owed is paid when the fund allows")


## CHAPEL-R2 (owner, 2026-10-23): the alms. On the service day, after the wages, the fund keeps what the clergy are owed and
## a week of their wages; the rest goes to adults and elders below their own necessity reserve, up to it, the households
## with the largest shortfall first. Coins conserved, never below the keep, never paid twice.
func test_alms() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	while not c.is_service_day():
		w.minutes += 1440.0
	var keep := 0
	for o: NPC in w.npcs:
		if Chapel.is_clergy(o):
			keep += c.wage_of(o.job) * int(Chapel.cfg().offering_every_days)
	# three poor households: their adults and elders hold nothing
	var poor := []
	for h in w.households.size():
		if poor.size() >= 3 or w.brain._members(h).is_empty():
			continue
		var ms: Array = w.brain._members(h).filter(func(o): return o.role in ["adult", "elder"] and not Chapel.is_clergy(o))
		if ms.is_empty():
			continue
		for o: NPC in ms:
			o.coins = 0
		poor.append(h)
	var short_of := func(h: int) -> int:
		return c.household_shortfall(h)
	var need0: int = short_of.call(poor[0]) + short_of.call(poor[1]) + short_of.call(poor[2])
	check(poor.size() == 3 and need0 > 0, "three households below their necessity reserve (short %d coins)" % need0)
	# one need per household: its shortfall is the household's need less every member's coins, the same whoever asks
	var h0: int = poor[0]
	var m0: Array = w.brain._members(h0)
	var held0 := 0
	for o: NPC in m0:
		held0 += o.coins
	check(short_of.call(h0) == maxi(0, int(w.necessity(m0[0]).need) - held0) and int(w.necessity(m0[0]).need) == int(w.necessity(m0[-1]).need),
			"a household's shortfall is its one need less all its members' coins (not each member's reserve)")
	# a fund too small: nothing below the keep is given
	c.coins = keep
	var total0 := w.total_coins()
	check(c.alms() == 0 and c.coins == keep and w.total_coins() == total0, "a fund at the keep (%d: a week of the clergy's wages) gives no alms" % keep)
	# a fund with plenty: every shortfall filled, the rest kept
	c.coins = keep + need0 + 5000
	total0 = w.total_coins()
	var all_short := 0
	for h in w.households.size():
		if not w.households[h].get("ended", false):
			all_short += short_of.call(h)
	var given := c.alms()
	check(given == all_short and short_of.call(poor[0]) == 0 and short_of.call(poor[1]) == 0 and short_of.call(poor[2]) == 0,
			"the alms fill every household's shortfall once (%d coins, the sum of the shortfalls %d)" % [given, all_short])
	check(w.total_coins() == total0 and c.coins == keep + need0 + 5000 - given and c.coins >= keep, "coins conserved; the fund keeps the rest")
	check(c.alms() == 0, "a second call the same day pays nobody twice")
	# a fund that cannot fill them all: the largest shortfall first, never below the keep
	for h in poor:
		for o: NPC in w.brain._members(h):
			if o.role in ["adult", "elder"] and not Chapel.is_clergy(o):
				o.coins = 0
	var s0: int = short_of.call(poor[0])
	var s1: int = short_of.call(poor[1])
	var s2: int = short_of.call(poor[2])
	var order := [[s0, poor[0]], [s1, poor[1]], [s2, poor[2]]]
	order.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	c.coins = keep + int(order[0][0])
	total0 = w.total_coins()
	c.alms()
	check(c.coins == keep and short_of.call(int(order[0][1])) == 0 and w.total_coins() == total0,
			"with too little for all, the household with the largest shortfall is filled first and the fund stops at the keep")
	# owed wages are kept back too
	c.owed = {"999999": 20}
	c.coins = keep + 20
	check(c.alms() == 0 and c.coins == keep + 20, "wages owed are kept back with the week's wages")
	c.owed = {}
	# the evening: offerings, then wages, then alms, once
	for h in poor:
		for o: NPC in w.brain._members(h):
			if o.role in ["adult", "elder"] and not Chapel.is_clergy(o):
				o.coins = 0
	c.coins = 3000
	c.evening_day = -1
	total0 = w.total_coins()
	c.evening()
	check(short_of.call(poor[0]) == 0 and w.total_coins() == total0 and int(w.stats.get("chapel_alms_coins", 0)) > 0, "the service day's evening gives the alms after the wages; coins conserved")
	var after := c.coins
	c.evening()
	check(c.coins == after, "the evening runs once a day")


func test_relief_first() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	var h := hungry_household(w)
	var n := adult_of(w, h)
	w.brain.update_market()
	check(w.brain.household_food_days(h) < float(GameData.b("relief_trigger_days")), "the household is short of food")
	c.store.add("wheat", 60)
	var planned := c.plan_ask(n)
	check(planned and n.plan.size() == 2 and n.plan[1].act == "church_ask", "a member of a household in need goes to the chapel to ask")
	check(not c.plan_ask(n), "once a day for the household")
	var wheat0 := c.store.count("wheat")
	check(w.brain.act(n, "church_ask", {}), "asking is answered")
	var days: float = w.brain.household_food_days(h)
	check(days >= float(GameData.b("relief_trigger_days")) and c.store.count("wheat") < wheat0, "the church fills the pantry from its store (%.1f days)" % days)
	check(int(w.stats.get("chapel_relieved", 0)) == 1, "counted as church relief")
	w.treasury = 5000
	var obligations: float = w.brain.daily_obligations()
	var given0 := int(w.stats.get("gov_relief_grain", 0)) + int(w.stats.get("gov_relief_bought", 0))
	var helped: int = w.brain._relief(obligations, obligations * float(GameData.b("treasury_reserve_days")))
	var given1 := int(w.stats.get("gov_relief_grain", 0)) + int(w.stats.get("gov_relief_bought", 0))
	var hh_pending: int = w.manor_work.pending_for(h)
	check(hh_pending == 0 and given1 >= given0, "the manor's relief then finds the household fed: it sent it nothing (pending %d)" % hh_pending)
	# an empty church gives nothing, and says so by doing nothing
	var w2 := new_world()
	var h3 := hungry_household(w2)
	var n3 := adult_of(w2, h3)
	w2.chapel.store.items.clear()
	w2.chapel.coins = 0
	check(not w2.chapel.can_give() and not w2.chapel.plan_ask(n3), "a church with nothing does not send anyone to ask")


func test_relief_bought() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	var h := hungry_household(w)
	var n := adult_of(w, h)
	w.brain.update_market()
	c.store.items.clear()
	c.coins = 200
	var total0 := w.total_coins()
	var pantry0: float = NPCBrain.store_points([w.households[h].pantry])
	c.ask(n)
	var pantry1: float = NPCBrain.store_points([w.households[h].pantry])
	check(c.coins < 200 and pantry1 > pantry0, "with no food in store the church buys food with its coins (%d spent)" % (200 - c.coins))
	check(w.total_coins() == total0, "the coins went to the sellers: none made or lost")
	check(int(w.stats.get("chapel_relief_bought", 0)) == 200 - c.coins, "counted")


func test_plot_work() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	var fp := w.farm_plots
	check(w.season() in (Farming.cfg().sow_seasons as Array), "the world begins in a sowing season (%s)" % w.season())
	# nobody volunteers: the clergy work the plot
	c.volunteers.clear()
	var asst: NPC = jobber(w, "church_assistant")[0]
	w.minutes = float(int(w.minutes / 1440.0)) * 1440.0 + 9.0 * 60.0
	check(c.plan_clergy(asst) and asst.plan.size() == 2 and asst.plan[1].act == "fp_work" and str(asst.plan[1].args.plot) == "church", "with no volunteers the clergy work the church plot")
	check(str(asst.plan[1].args.task) == "till", "the bare plot is ploughed first")
	var worked := 0
	for k in 120:
		if not c.plan_clergy(asst) or asst.plan.size() < 2 or not asst.plan[1].has("args"):
			break
		if not fp.act(asst, "fp_work", asst.plan[1].args):
			break
		worked += 1
		w.minutes += 60.0
	var inside := (int(c.plot.w) - 2) * (int(c.plot.h) - 2)
	var growing := 0
	for cell in fp.cells.values():
		if str(cell.plot) == "church" and cell.state == "growing":
			growing += 1
	check(growing == inside, "the clergy plough and sow every cell inside the fence (%d of %d, in %d work steps)" % [growing, inside, worked])
	check(c.store.count("wheat_seed") == int(c.cfg().plot_seed) - inside, "sown from the church's own seed")
	# a volunteer comes forward: the clergy keep the chapel
	var vol: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "elder" and c.piety(n) >= float(c.cfg().volunteer_piety):
			vol = n
			break
	if vol == null:
		for n: NPC in w.npcs:
			if n.alive and n.role == "elder":
				vol = n
				break
	c.dawn()
	check(not c.volunteers.is_empty() and c.volunteers.size() <= int(c.cfg().volunteers_max) and c.volunteers.all(func(id): return c.piety(w.npc(int(id))) >= float(c.cfg().volunteer_piety)), "the pious who have the time volunteer (%d)" % c.volunteers.size())
	c.volunteers = [vol.id]
	check(c.volunteers_able() >= 1 and c.plan_clergy(asst) and str(asst.doing) == "keeping the chapel", "with a volunteer the church assistant keeps the chapel")
	# ripe: the volunteer harvests it into the church's store
	for cell in fp.cells.values():
		if str(cell.plot) == "church":
			cell.state = "ripe"
			cell.progress = 1.0
	var wheat0 := c.store.count("wheat")
	check(c.plan_volunteer(vol) and vol.plan[1].args.task == "harvest", "the volunteer plans the harvest")
	var args: Dictionary = vol.plan[1].args
	check(fp.act(vol, "fp_work", args), "harvested")
	check(c.store.count("wheat") > wheat0, "the crop goes to the church's store (%d wheat)" % (c.store.count("wheat") - wheat0))
	# nobody else may work it
	var stranger: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job == "miner")[0]
	check(not fp.act(stranger, "fp_work", args), "a villager who did not volunteer does not work the plot")
	# seed bought with the fund
	for cell in fp.cells.values():
		if str(cell.plot) == "church":
			cell.state = "tilled"
			cell.crop = ""
	c.store.items.erase("wheat_seed")
	c.coins = 100
	var total0 := w.total_coins()
	c.dawn()
	check(c.store.count("wheat_seed") > 0 and c.coins < 100 and w.total_coins() == total0, "the fund buys seed from the sellers; coins are conserved")


func check_free(r: bool, what: String) -> void:
	check(r, what)


func test_player() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	var p := w.player
	p.coins = 50
	var total0 := w.total_coins()
	var r := c.player_offer_coins(20)
	check(r.ok and p.coins == 30 and c.coins == 20 and w.total_coins() == total0, "the player's coins go to the fund")
	check(not c.player_offer_coins(500).ok, "not more than the player has")
	p.inv.add("wheat", 3)
	check(c.player_offer_item("wheat", 2).ok and c.store.count("wheat") == 2 and p.inv.count("wheat") == 1, "the player's food goes to the store")
	check(not c.player_offer_item("iron_bar", 1).ok, "the chapel takes only food and seed")
	check(not c.player_ask().ok, "the player with coins is not given the church's food")
	p.coins = 2
	var a := c.player_ask()
	check(a.ok and p.inv.count("wheat") == 1 + 2, "a player with almost no coins is given what the church has (%s)" % a.text)
	check(not c.player_ask().ok, "once a day")


func act_of(w: World, c: Vector2i, task: String) -> Dictionary:
	for t in w.farm.targets_at(c, w.player, true):
		if str(t.get("act", "")) == "church" and str(t.task) == task:
			return t
	return {}


## B18-DP-12: the player volunteers on the church field by the villagers' rules and work path: the same cells and store, no pay.
func test_player_volunteers() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	var fp := w.farm_plots
	var p := w.player
	w.minutes = float(int(w.minutes / 1440.0)) * 1440.0 + 9.0 * 60.0
	var cell := Vector2i(int(c.plot.x) + 2, int(c.plot.y) + 2)
	check(fp.in_church_plot(cell) and not fp.in_church_plot(Vector2i(int(c.plot.x) - 3, int(c.plot.y))), "the church field is where the player may volunteer")
	var coins0 := p.coins
	var total0 := w.total_coins()
	var seed0 := c.store.count("wheat_seed")
	# till (the player's own time and stamina), then sow from the church's seed
	var t := act_of(w, cell, "till")
	check(not t.is_empty(), "the bare cell offers: %s" % str(t.get("label", "")))
	p.stamina = 100.0
	var pl: Dictionary = w.farm.plan(t, p)
	check(pl.ok and float(pl.secs) > 0.0, "tilling is planned as a timed action")
	pl.run.call()
	check(fp.cells.has(cell) and str(fp.cells[cell].state) == "tilled" and str(fp.cells[cell].plot) == "church" and p.stamina < 100.0, "the cell is tilled as the villagers' (a church cell), at the player's stamina cost")
	check(act_of(w, cell, "till").is_empty(), "a tilled cell is not tilled again")
	t = act_of(w, cell, "sow")
	check(not t.is_empty() and str(t.crop) == "wheat", "the tilled cell offers sowing: %s" % str(t.get("label", "")))
	pl = w.farm.plan(t, p)
	check(pl.ok, "sowing is planned")
	pl.run.call()
	check(str(fp.cells[cell].state) == "growing" and c.store.count("wheat_seed") == seed0 - 1 and p.inv.count("wheat_seed") == 0, "sown with the church's own seed")
	# parity: a villager volunteer's work_cell gives the same state on a second cell
	var cell2 := cell + Vector2i(1, 0)
	var vol: NPC = w.npcs.filter(func(n): return n.alive and n.role == "elder")[0]
	check(fp.work_cell(c.plot, cell2, "till", "", vol.inv, c.store) == "" and fp.work_cell(c.plot, cell2, "sow", "wheat", vol.inv, c.store) == "", "the villagers' work on the next cell")
	check(str(fp.cells[cell2].state) == str(fp.cells[cell].state) and str(fp.cells[cell2].crop) == str(fp.cells[cell].crop) and float(fp.cells[cell2].progress) == float(fp.cells[cell].progress), "the player's cell and the villager's are in the same state (parity)")
	check(not act_of(w, cell, "harvest").is_empty() == false, "a growing cell offers no harvest")
	# ripe: the crop goes to the church's store, nothing to the player
	fp.cells[cell].state = "ripe"
	fp.cells[cell].progress = 1.0
	var wheat0 := c.store.count("wheat")
	var seeds1 := c.store.count("wheat_seed")
	t = act_of(w, cell, "harvest")
	check(not t.is_empty(), "a ripe cell offers: %s" % str(t.get("label", "")))
	pl = w.farm.plan(t, p)
	check(pl.ok, "harvest is planned")
	var r: Dictionary = pl.run.call()
	check(c.store.count("wheat") > wheat0 and c.store.count("wheat_seed") == seeds1 + 1 and str(fp.cells[cell].state) == "tilled", "the crop and the seed back go to the church's store (%s)" % str(r.text))
	check(p.inv.count("wheat") == 0 and p.coins == coins0 and w.total_coins() == total0 and r.items.is_empty(), "the player gets no coin and no crop, and nothing is made")
	check(int(w.stats.get("chapel_player_volunteered_harvest", 0)) == 1, "the volunteering is recorded")
	# the same rules: a badly hurt player cannot, as a hurt villager cannot
	p.hp = 1.0
	check(act_of(w, cell, "sow").is_empty() and not w.farm.plan({"kind": "farm", "act": "church", "task": "sow", "cell": cell, "crop": "wheat"}, p).ok, "a badly hurt player is not offered the work, as a hurt villager would not go")
	var vhp := vol.hp
	vol.hp = 1.0
	check(not fp.able(vol) and not fp.able_player(p), "a hurt villager and a hurt player are alike unable")
	vol.hp = vhp
	p.hp = p.max_hp
	# a store without seed: nothing to sow, and the player's own seed may be used
	c.store.items.erase("wheat_seed")
	check(act_of(w, cell, "sow").is_empty(), "with no seed in the store or the pack there is nothing to sow")
	p.inv.add("wheat_seed", 1)
	t = act_of(w, cell, "sow")
	check(not t.is_empty() and w.farm.plan(t, p).ok, "the player's own seed may be sown, as a villager's")
	w.farm.plan(t, p).run.call()
	check(p.inv.count("wheat_seed") == 0 and str(fp.cells[cell].state) == "growing", "taken from the pack first")
	# a save keeps the player's work
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.farm_plots.cells.has(cell) and str(w2.farm_plots.cells[cell].plot) == "church" and str(w2.farm_plots.cells[cell].state) == "growing" and w2.chapel.store.count("wheat") == c.store.count("wheat"), "the work and the store survive a save")
	# the clergy and volunteers still work the same plot: the planner finds work for the assistant after the player's
	c.volunteers.clear()
	var asst: NPC = jobber(w, "church_assistant")[0]
	check(c.plan_clergy(asst), "the clergy still plan work on the plot")


func test_law_and_claims() -> void:
	var w := new_world()
	var pr: NPC = jobber(w, "preacher")[0]
	check(Law.teaches(pr) and Law.teacher_cap(pr) == 6 and Law.teacher_cap(jobber(w, "church_assistant")[0]) == 0, "the preacher teaches the law, to level 6")
	var r := Law.teach(w, World.PLAYER, pr)
	check(r.ok, "a lesson from the preacher: %s" % r.text)
	check(w.property.can_claim(w.chapel.plot_rect()) != "", "the church's plot cannot be claimed as land")
	var sums := w.construction._free_sums()
	var rect := w.chapel.plot_rect()
	var W: int = w.map.w
	var blocked := sums[(rect.end.y) * (W + 1) + rect.end.x] - sums[rect.position.y * (W + 1) + rect.end.x] - sums[rect.end.y * (W + 1) + rect.position.x] + sums[rect.position.y * (W + 1) + rect.position.x]
	check(blocked == rect.size.x * rect.size.y, "no one builds on the church's plot")


func test_save() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	c.coins = 77
	c.store.add("wheat", 9)
	c.volunteers = [5, 6]
	c.owed["12"] = 4
	c.asked[3] = 2
	var cell := Vector2i(int(c.plot.x) + 2, int(c.plot.y) + 2)
	w.farm_plots.cells[cell] = {"crop": "wheat", "state": "growing", "progress": 0.4, "plot": "church"}
	var total0 := w.total_coins()
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var c2: Chapel = w2.chapel
	check(c2.present and c2.coins == 77 and c2.store.count("wheat") == 9 and c2.volunteers == [5, 6] and int(c2.owed["12"]) == 4 and int(c2.asked[3]) == 2, "the chapel's fund, store, volunteers, wages owed and asking survive a save")
	check(w2.total_coins() == total0 and w2.farm_plots.cells.has(cell) and w2.map.is_solid(Vector2i(int(c.plot.x), int(c.plot.y))), "its coins, its crop and its fence too")
	check(jobber(w2, "preacher").size() == 1 and jobber(w2, "church_assistant").size() == 1 and w2.npcs.size() == w.npcs.size(), "and its clergy")
	check(JSON.stringify(JSON.parse_string(JSON.stringify(w2.to_dict().chapel))) == JSON.stringify(d.chapel), "saving again gives the same chapel")


func test_old_save() -> void:
	var w := new_world()
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	d.erase("chapel")
	d.buildings.erase(w.chapel.bid)
	for n in d.npcs:
		if str(n.get("job", "")) in ["preacher", "church_assistant"]:
			n.job = ""
			n.workplace = ""
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.chapel.present and w2.buildings.has(w2.chapel.bid) and w2.farm_plots.plots().has(w2.chapel.plot), "a save from before the chapel gets the chapel on free ground")
	check(w2.npcs.size() == w.npcs.size(), "no villager is made on load")
	var m: Dictionary = w2.brain.job_market()
	check(int(m.preacher.open) == 1 and int(m.church_assistant.open) == 1, "its labour market opens the preacher's and the assistant's places")
	check(w2.chapel.store.total() == 0 and w2.chapel.coins == 0, "an older world's church starts with nothing: no goods or coins are made")
	var free: NPC = w2.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job == "miner")[0]
	w2.brain._change_job(free, "preacher", "test")
	check(free.workplace == "chapel" and int(w2.brain.job_market().preacher.open) == 0, "the adult who takes the place works at the chapel")
	w2.index_interiors()
	check(w2.interiors.has(w2.chapel.bid), "the chapel has an interior")
	# the ground taken: something of a household's stands on the plot
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	d2.erase("chapel")
	d2.buildings.erase(w.chapel.bid)
	d2.farm_plots = {"cells": [[int(w.chapel.plot.x) + 2, int(w.chapel.plot.y) + 2, "wheat", "growing", 0.5, "plot9"]]}
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d2)
	check(not w3.chapel.present and not w3.buildings.has(w.chapel.bid) and int(w3.brain.job_market().preacher.open) == 0, "where something of the village's stands on the ground, there is no chapel and no places")


## A real Build 17 save (seed 7, 900 minutes; relations left out), loaded on the map with the chapel and ROOMS-18's relaid plots:
## plant ids no longer name the same cells, 16 of its wild plants have no cell on the map, and clues have moved.
func test_b17_save() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/b17_save_seed7.json"))
	var saved := {}
	for p in raw.plants:
		saved[Vector2i(int(p.x), int(p.y))] = p
	var picked := []
	for p in raw.plants:               # give some plants a state the fresh map would not: picked, regrowing
		if picked.size() < 40 and int(p.id.substr(2)) % 5 == 0:
			p.state = "picked"
			p.regrow = 99.0
			picked.append(Vector2i(int(p.x), int(p.y)))
	raw.prospecting = {"gen": 2, "taken": {"cGONE": [[3, 4, "player"]]}, "samples": {}, "bags": {}, "records": [], "next_sample": 1, "next_record": 1}
	raw.discovery = {"gen": 2, "dug": {"cGONE": [[3, 4, "player", 5]]}, "levels": {}, "history": []}
	# 1. the chapel cannot be placed (villagers' land is in the way): every saved plant stays, on its own cell, in its own state
	var w := World.new()
	w.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(raw)))
	var cells := {}
	for p in w.plants:
		cells[Vector2i(int(p.x), int(p.y))] = p
	var wrong := 0
	for c: Vector2i in saved:
		var p: Dictionary = cells.get(c, {})
		if p.is_empty() or str(p.kind) != str(saved[c].kind) or str(p.state) != str(saved[c].state):
			wrong += 1
	check(not w.chapel.present and w.plants.size() == raw.plants.size() and wrong == 0, "a Build 17 save keeps every plant on its cell in its state (none by id, none lost) while the chapel cannot be placed")
	check(picked.all(func(c): return cells[c].state == "picked" and float(cells[c].regrow) == 99.0), "the picked plants stay picked on the right cells")
	check(w.prospecting.taken.has("cGONE") and w.discovery.dug.has("cGONE"), "sample marks and trial pits of a clue the generator no longer makes are kept, not dropped")
	var again: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w1b := World.new()
	w1b.load_dict(VillageMap.load_default(), again)
	check(w1b.plants.size() == w.plants.size() and w1b.prospecting.taken.has("cGONE") and w1b.discovery.dug.has("cGONE"), "saved again and loaded, nothing changes")
	# 2. the villagers' land cleared: the chapel is placed; only the plants on its ground and its plot go, and are counted
	var d2: Dictionary = JSON.parse_string(JSON.stringify(raw))
	d2.plots = []
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d2)
	var on_ground := 0
	for c: Vector2i in saved:
		if w2.chapel.footprint_has(c):
			on_ground += 1
	check(w2.chapel.present and on_ground > 0 and w2.plants.size() == raw.plants.size() - on_ground and int(w2.stats.get("plants_lost_on_load", 0)) == on_ground,
			"with the chapel placed, the %d plants on its ground go (counted) and every other flower stays" % on_ground)
	check(w2.plants.all(func(p): return not w2.chapel.footprint_has(Vector2i(int(p.x), int(p.y)))), "no plant stands in the chapel or on its plot")
	# 3. a plant someone grew (SEED-02) on the ground blocks the site
	var d3: Dictionary = JSON.parse_string(JSON.stringify(raw))
	d3.plots = []
	var cell := Vector2i(int(w2.chapel.plot.x) + 1, int(w2.chapel.plot.y) + 1)
	d3.plants.append({"id": "pz1", "x": cell.x, "y": cell.y, "kind": "flower", "tile": 2657, "state": "ripe", "regrow": 0.0, "planted": true})
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d3)
	check(not w3.chapel.present and w3.plants.size() == raw.plants.size() + 1, "a planted plant on the chapel's ground blocks the site, and nothing is lost")


func test_days() -> void:
	var w := new_world()
	var coins0 := w.total_coins()
	for d in 14:
		for m in 1440:
			w.update(0.5)
			w.player.hunger = 100.0
	var inflow := 0
	for k in ["caravan_coins_in", "newcomer_coins_in", "scenario_coins_in", "outlaw_coins_in"]:
		inflow += int(w.stats.get(k, 0))
	inflow -= int(w.stats.get("caravan_coins_out", 0))
	print("ran 14 days: chapel fund %d, store wheat %d, wages %d, offerings %d coins, asked %d" % [w.chapel.coins, w.chapel.store.count("wheat"), int(w.stats.get("chapel_wages", 0)), int(w.stats.get("chapel_offering_coins", 0)), int(w.stats.get("chapel_asked", 0))])
	check(int(w.stats.get("chapel_offering_coins", 0)) > 0 and int(w.stats.get("chapel_wages", 0)) > 0, "the village gave at the services and the clergy were paid")
	var sown := 0
	for cell in w.farm_plots.cells.values():
		if str(cell.plot) == "church":
			sown += 1
	check(sown > 0, "the church's plot has been worked (%d cells)" % sown)
	check(w.total_coins() == coins0 + inflow, "coins stay accounted for over the 14 days: the fund, wages and offerings included (%d + %d from outside = %d)" % [coins0, inflow, w.total_coins()])
	check(jobber(w, "preacher").size() <= 1 and jobber(w, "church_assistant").size() <= 1, "still no more than one of each")
