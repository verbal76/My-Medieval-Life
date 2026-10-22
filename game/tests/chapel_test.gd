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
	test_relief_first()
	test_relief_bought()
	test_plot_work()
	test_player()
	test_law_and_claims()
	test_save()
	test_old_save()
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
