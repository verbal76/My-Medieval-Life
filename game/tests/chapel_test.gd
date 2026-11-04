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
	test_food_alms()
	test_fair_share()
	test_oldest_first()
	test_emergency()
	test_transfer()
	test_relief_bought()
	test_reserve_audit()
	test_store_spoils()
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


## What anyone thinks or remembers of anyone (the judgment store's facts, memories, contributions and ledgers), as text.
func opinions(w: World) -> String:
	if w.judgment == null:
		return ""
	var d: Dictionary = w.judgment.to_dict()
	return JSON.stringify([d.get("facts"), d.get("memories"), d.get("contrib"), d.get("ledgers")])


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


## X20-CHAPEL-FIX (owner, 2026-11-01): giving is voluntary. Each adult and elder who can spare a coin decides through the
## decision framework; piety moves the chance but never decides; amounts vary and are affordable; those who cannot spare are
## counted unable, not unwilling; nothing is taken without a choice and nobody is penalised for declining.
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
	var judge0 := opinions(w)
	var r := c.offerings()
	var s: Dictionary = c.last_service
	check(int(r.coins) > 0 and c.coins == int(r.coins) and int(s.coins) == int(r.coins), "some choose to give coins to the fund (%d)" % int(r.coins))
	check(int(s.donors) > 0 and int(s.declined) > 0 and int(s.donors) + int(s.declined) == int(s.considered) and int(s.considered) + int(s.unable) == int(s.present),
			"giving is a choice: of %d who could give, %d gave and %d chose not to; %d could not spare a coin" % [s.considered, s.donors, s.declined, s.unable])
	check(int(r.wheat) > 0 and c.store.count("wheat") == int(r.wheat), "households choose to give wheat to the store (%d)" % int(r.wheat))
	var wheat1 := c.store.count("wheat")
	for hh in w.households:
		wheat1 += (hh.pantry as Inventory).count("wheat")
	check(w.total_coins() == coins0 and wheat1 == wheat0, "offerings move coins and wheat, they make none")
	check(opinions(w) == judge0, "giving or declining touches nobody's opinion, memory or ledger: no penalty, no reputation")
	var sizes := {}
	for g in s.gifts:
		sizes[g] = true
	check(sizes.size() > 1, "gifts vary in size (%d different amounts)" % sizes.size())
	check(c.piety(w.npcs[3]) == new_world().chapel.piety(w.npcs[3]), "piety is a fixed number, the same in another world of the same seed")
	# unable: nothing above the reserve and savings -> not asked, gives nothing, counted as unable
	var poor: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and not Chapel.is_clergy(n):
			poor = n
			break
	poor.coins = 3
	check(c.affordable(poor) == 0, "someone with nothing above their reserve and savings cannot spare a coin")
	var before: int = poor.coins
	var unable0 := int(w.stats.get("chapel_unable", 0))
	c.offerings()
	check(poor.coins == before and int(w.stats.get("chapel_unable", 0)) > unable0, "they give nothing and are counted unable, not unwilling")
	# over many weeks: piety moves the chance, it decides nothing; a giver never gives more than they can spare
	var gave := {}
	var declined := {}
	var over := 0
	for week in 16:
		w.minutes += 1440.0 * 7.0
		for n: NPC in w.npcs:
			if n.alive and n.role in ["adult", "elder"]:
				n.coins = w.reserve_of(n) + int(Chapel.cfg().gift.keep_coins) + 1 + (n.id * 7 + week * 3) % 25     # a modest spare, 1 to 25
		var spare := {}
		var held := {}
		for n: NPC in w.npcs:
			spare[n.id] = c.affordable(n)
			held[n.id] = n.coins
		c.offerings()
		for n: NPC in w.npcs:
			if not n.alive or n.role not in ["adult", "elder"] or n.household < 0 or int(spare[n.id]) < 1:
				continue
			var g: int = int(held[n.id]) - n.coins
			if g > int(spare[n.id]):
				over += 1
			if g > 0:
				gave[n.id] = int(gave.get(n.id, 0)) + 1
			else:
				declined[n.id] = int(declined.get(n.id, 0)) + 1
	var devout_declined := 0
	var faithless_gave := 0
	var devout_rate := [0, 0]
	var faithless_rate := [0, 0]
	for n: NPC in w.npcs:
		var pt := c.piety(n)
		var g := int(gave.get(n.id, 0))
		var d := int(declined.get(n.id, 0))
		if pt >= 0.8:
			devout_declined += 1 if d > 0 else 0
			devout_rate[0] += g
			devout_rate[1] += g + d
		elif pt <= 0.2:
			faithless_gave += 1 if g > 0 else 0
			faithless_rate[0] += g
			faithless_rate[1] += g + d
	check(over == 0, "nobody ever gives more than they can spare")
	check(devout_declined > 0, "the devout sometimes keep their coins (%d devout villagers declined at least once)" % devout_declined)
	check(faithless_gave > 0, "those of little faith sometimes give (%d gave at least once)" % faithless_gave)
	check(devout_rate[1] > 0 and faithless_rate[1] > 0 and devout_rate[0] * faithless_rate[1] > faithless_rate[0] * devout_rate[1],
			"the devout give more often (%d of %d choices) than those of little faith (%d of %d)" % [devout_rate[0], devout_rate[1], faithless_rate[0], faithless_rate[1]])
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


## CHAPEL-R2 (owner, 2026-10-23) as X20-CHAPEL-FIX (owner, 2026-11-01) corrects it: on the service day, after the wages, the fund
## keeps its operating reserve (the clergy's wages for operating_reserve_days, wages owed, recent relief and seed spending) and
## gives the surplus to the poorest households by hardship: not gated by the food they hold, never to the wealthy short of
## coin, each up to its hardship, once. Coins conserved, never below the reserve.
func test_alms() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	while not c.is_service_day():
		w.minutes += 1440.0
	var days := int(Chapel.cfg().operating_reserve_days)
	var keep := 0
	for o: NPC in w.npcs:
		if Chapel.is_clergy(o):
			keep += c.wage_of(o.job) * days
	check(c.operating_reserve() == keep, "with nothing owed or spent the reserve is the clergy's wages for %d days (%d)" % [days, keep])
	c.spent_week = 70
	c.coins = 0
	c.alms()
	check(c.spent == [70] and c.spent_week == 0 and c.operating_reserve() == keep + 70 * days / 7, "recent relief and seed spending is kept back too")
	c.spent = []
	# three poor households: no coins, but each with a full larder (food alone does not make them secure)
	var poor := []
	for h in w.households.size():
		if poor.size() >= 3 or w.brain._members(h).is_empty():
			continue
		var ms: Array = w.brain._members(h)
		if ms.any(func(o): return Chapel.is_clergy(o)) or not ms.any(func(o): return o.role == "adult"):
			continue
		for o: NPC in ms:
			w.treasury += o.coins
			o.coins = 0
		(w.households[h].pantry as Inventory).add("wheat", 30)
		poor.append(h)
	for h in poor:
		var m := c.household_means(h)
		check(int(m.cash) == 0 and int(m.stock) > 0 and maxi(c.household_shortfall(h), int(m.line)) > c.household_shortfall(h) and int(m.wealth) < int(m.line) * int(Chapel.cfg().alms_wealth_lines),
				"household %d holds food but no coins: its hardship (%d) is more than its necessity shortfall (%d), and it is not wealthy (wealth %d, line %d)" % [h, m.line, c.household_shortfall(h), m.wealth, m.line])
	# one rich household short of coin today: wealth far above the line, excluded
	var rich := -1
	for h in w.households.size():
		if not poor.has(h) and not w.brain._members(h).is_empty() and w.brain._members(h).any(func(o): return o.role == "adult" and not Chapel.is_clergy(o)):
			rich = h
			break
	for o: NPC in w.brain._members(rich):
		w.treasury += o.coins
		o.coins = 0
	(w.households[rich].pantry as Inventory).add("wheat", 3000)
	var rm := c.household_means(rich)
	check(int(rm.cash) == 0 and int(rm.wealth) >= int(rm.line) * int(Chapel.cfg().alms_wealth_lines), "a household rich in stores but short of coin today")
	# a fund at the reserve gives nothing
	c.coins = keep
	var total0 := w.total_coins()
	check(c.alms() == 0 and c.coins == keep and w.total_coins() == total0, "a fund at its reserve (%d) gives no alms" % keep)
	# a fund with plenty: the poor are helped to one line of cash, the rich get nothing, the rest is kept
	c.coins = keep + 5000
	total0 = w.total_coins()
	var given := c.alms()
	var helped := (c.last_service.recipients as Array).map(func(r): return int(r.household))
	check(given > 0 and helped.has(poor[0]) and helped.has(poor[1]) and helped.has(poor[2]), "the alms reach the poor households with food but no coins (%d coins to %d)" % [given, helped.size()])
	check(not helped.has(rich), "the wealthy short of coin get nothing")
	var ok := true
	for r in c.last_service.recipients:
		if int(r.given) < 1 or int(r.cash_after) != int(r.cash_before) + int(r.given):
			ok = false
	for h in poor:
		var m := c.household_means(h)
		if int(m.cash) < int(m.line) and c.coins > keep:
			ok = false
	check(ok, "each recipient is given up to its hardship, and the poor are brought to their line while the fund allows")
	check(w.total_coins() == total0 and c.coins == keep + 5000 - given and c.coins >= keep, "coins conserved; the fund keeps its reserve and what is left")
	check(c.alms() == 0, "a second call the same day pays nobody twice")
	# a fund that cannot help them all: the poorest for each member first, never below the reserve
	for h in poor:
		for o: NPC in w.brain._members(h):
			w.treasury += o.coins
			o.coins = 0
	c.coins = keep + 1
	total0 = w.total_coins()
	c.alms()
	var first: Dictionary = c.last_service.recipients[0] if not c.last_service.recipients.is_empty() else {}
	check(c.coins == keep and w.total_coins() == total0 and int(first.get("given", 0)) == 1, "with too little for all the fund stops at its reserve")
	var poorest := 999999999
	for h in w.households.size():
		if w.households[h].get("ended", false) or w.brain._members(h).is_empty():
			continue
		if not w.brain._members(h).any(func(o: NPC) -> bool: return o.alive and o.role in ["adult", "elder"]):
			continue                          # alms are paid to an adult or elder (Chapel.alms): the band's household (B25R1-Q2 a), all bandits, has none
		var m := c.household_means(h)
		if int(m.wealth) < int(m.line) * int(Chapel.cfg().alms_wealth_lines) and maxi(c.household_shortfall(h), int(m.line) - int(m.cash)) > 0:
			poorest = mini(poorest, int(m.wealth) * 1000 / int(m.members))
	check(not first.is_empty() and int(first.wealth) * 1000 / int(first.members) <= poorest + 1000, "the poorest household for each member is helped first")
	# owed wages are kept back too
	c.owed = {"999999": 20}
	c.coins = keep + 20
	check(c.alms() == 0 and c.coins == keep + 20, "wages owed are kept back with the reserve")
	c.owed = {}
	# the evening: offerings, then wages, then alms, once
	for h in poor:
		for o: NPC in w.brain._members(h):
			w.treasury += o.coins
			o.coins = 0
	c.coins = 3000
	c.evening_day = -1
	total0 = w.total_coins()
	c.evening()
	check(w.total_coins() == total0 and int(w.stats.get("chapel_alms_coins", 0)) > 0 and c.household_means(poor[0]).cash > 0, "the service day's evening gives the alms after the wages; coins conserved")
	var after := c.coins
	c.evening()
	check(c.coins == after, "the evening runs once a day")


## CHAPEL-PURPOSE (owner 2026-11-02): the store keeps only its emergency reserve (recent emergency relief for
## food_reserve_days); the food above it is set aside for the households under the 14-day hardship line (alms_line_days, the
## coin alms' line), shared, the wealthy excluded; it is the chapel's until carried; nothing is made.
func test_food_alms() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	while not c.is_service_day():
		w.minutes += 1440.0
	w.brain.update_market()
	var wp := NPCBrain.food_points("wheat")
	var line := float(Chapel.cfg().alms_line_days)
	check(line == 14.0, "the food alms use the owner's 14-day hardship line, the coin alms' line")
	var short := []
	for h in range(3, w.households.size()):
		if short.size() >= 2:
			break
		var ms: Array = w.brain._members(h)
		if ms.any(func(o): return Chapel.is_clergy(o)) or not ms.any(func(o): return o.role == "adult"):
			continue
		(w.households[h].pantry as Inventory).items.clear()
		for o: NPC in ms:
			o.inv.items.clear()
			w.treasury += o.coins
			o.coins = 0
		short.append(h)
	var rich := -1
	for h in w.households.size():
		if not short.has(h) and not w.brain._members(h).is_empty() and not w.brain._members(h).any(func(o): return Chapel.is_clergy(o)):
			rich = h
			break
	(w.households[rich].pantry as Inventory).add("wheat", 3000)
	# a household with 8 days of food: above the old 6-day line, under the 14-day one
	var mid := -1
	for h in range(3, w.households.size()):
		if short.has(h) or h == rich or w.brain._members(h).is_empty() or w.brain._members(h).any(func(o): return Chapel.is_clergy(o)):
			continue
		mid = h
		break
	(w.households[mid].pantry as Inventory).items.clear()
	for o: NPC in w.brain._members(mid):
		o.inv.items.clear()
		w.treasury += o.coins
		o.coins = 0
	(w.households[mid].pantry as Inventory).add("wheat", ceili(8.0 * w.brain.household_day_food(mid) / wp / 2.0) * 2)
	var mid_days: float = w.brain.household_food_days(mid)
	check(mid_days > 6.0 and mid_days < line, "a household with %.1f days of food: inside the hardship line" % mid_days)
	var mid_wheat := (w.households[mid].pantry as Inventory).count("wheat")
	c.offerings()
	check((w.households[mid].pantry as Inventory).count("wheat") == mid_wheat, "a household inside the hardship line offers no wheat (it would be given back as alms)")
	check(w.brain.household_food_days(short[0]) < line and w.brain.household_food_days(rich) >= line, "two households short of food, one with plenty")
	# the reserve: recent emergency relief for food_reserve_days
	c.relief_week = 0.0
	c.relief_hist = []
	check(c.food_reserve() == 0, "with no relief given lately the food reserve is nothing")
	c.relief_hist = [700.0]
	check(c.food_reserve() == ceili(700.0 * float(Chapel.cfg().food_reserve_days) / float(Chapel.cfg().offering_every_days)), "the reserve is the recent emergency relief for food_reserve_days (%d)" % int(Chapel.cfg().food_reserve_days))
	# a store at its reserve gives nothing
	c.relief_hist = []
	c.store.items.clear()
	c.store.add("wheat", 10)
	c.relief_week = 10.0 * wp * float(Chapel.cfg().offering_every_days) / float(Chapel.cfg().food_reserve_days)
	check(is_zero_approx(c.food_alms()) and c.store.count("wheat") == 10 and c.parcels.is_empty(), "a store at its reserve gives no food")
	check(int(w.stats.get("chapel_unhelped_alms_reserve", 0)) >= 2, "the households it could not help are counted, with the reason (the reserve)")
	# a large store: the households under the line get food set aside, the rich nothing
	c.relief_hist = []
	c.relief_week = 0.0
	c.store.add("wheat", 2000)
	var items0: int = c.store.count("wheat") + _pantry_wheat(w) + _parcel_wheat(c)
	var rich0 := (w.households[rich].pantry as Inventory).count("wheat")
	var pantry0 := _pantry_wheat(w)
	var coins0 := w.total_coins()
	var given := c.food_alms()
	check(given > 0.0 and int(c.last_service.food_recipients) >= 3, "the surplus is set aside for the households under the line (%.0f points to %d)" % [given, int(c.last_service.food_recipients)])
	check(_pantry_wheat(w) == pantry0 and not c.parcels.is_empty(), "nothing appears in a pantry: the food waits in parcels, the chapel's, to be carried")
	for h in short + [mid]:
		check(c.projected_days(h) >= line - 0.01, "household %d has 14 days of food with what is on its way (%.1f)" % [h, c.projected_days(h)])
	check(c.parcels_for(rich).is_empty() and (w.households[rich].pantry as Inventory).count("wheat") == rich0, "the household rich in stores gets nothing")
	check(c.store.count("wheat") + _pantry_wheat(w) + _parcel_wheat(c) == items0 and w.total_coins() == coins0, "every unit moved from the store to a parcel: none made or lost, no coins moved")
	check(int(w.stats.get("chapel_alms_wheat", 0)) == 2010 - c.store.count("wheat"), "counted")
	var door := c.door_cell()
	check(c.parcels.all(func(p): return int(p.at[0]) == door.x and int(p.at[1]) == door.y and not bool(p.urgent) and str(p.why) == "alms"), "the alms wait at the chapel's door")
	var left := c.store.count("wheat")
	c.food_alms()
	check(c.store.count("wheat") == left, "a second call gives nothing more: what is on its way counts")
	# saved and loaded: the record and the parcels
	c.relief_week = 123.0
	c.note_missed(adult_of(w, short[0]))
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(is_equal_approx(w2.chapel.relief_week, 123.0) and w2.chapel.relief_hist.size() == c.relief_hist.size(), "the relief record survives a save")
	check(w2.chapel.parcels.size() == c.parcels.size() and _parcel_wheat(w2.chapel) == _parcel_wheat(c) and w2.chapel.next_parcel == c.next_parcel \
		and w2.chapel.is_missing_meals(short[0]), "the parcels on their way and the missed meals survive a save")
	var d2: Dictionary = d.duplicate(true)
	for k in ["relief_week", "relief_hist", "parcels", "next_parcel", "missed"]:
		(d2.chapel as Dictionary).erase(k)
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d2)
	check(is_zero_approx(w3.chapel.relief_week) and w3.chapel.relief_hist.is_empty() and w3.chapel.parcels.is_empty() and w3.chapel.missed.is_empty(), "a save from before it loads with no relief record and nothing on its way")


func _parcel_wheat(c: Chapel) -> int:
	var k := 0
	for p in c.parcels:
		k += (p.inv as Inventory).count("wheat")
	return k


## Households emptied of food and coins (index >= 3, no clergy, with an adult): `k` of them.
func emptied(w: World, k: int) -> Array:
	var out := []
	for h in range(3, w.households.size()):
		if out.size() >= k:
			break
		var ms: Array = w.brain._members(h)
		if ms.any(func(o): return Chapel.is_clergy(o)) or not ms.any(func(o): return o.role == "adult"):
			continue
		(w.households[h].pantry as Inventory).items.clear()
		for o: NPC in ms:
			o.inv.items.clear()
			w.treasury += o.coins
			o.coins = 0
		out.append(h)
	return out


## CHAPEL-PURPOSE: a surplus too small for all is shared, the fewest days first, not spent on the first household.
func test_fair_share() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	w.brain.update_market()
	var hs := emptied(w, 3)
	c.store.items.clear()
	c.store.add("wheat", 6)                  # three pots for three households
	c.relief_hist = []
	c.relief_week = 0.0
	var rows := []
	for h in hs:
		rows.append(c._row(h, c.projected_days(h), 0))
	c._share_store(rows, float(Chapel.cfg().alms_line_days), 6.0 * NPCBrain.food_points("wheat"), false, "alms", false)
	var got := hs.map(func(h): return _parcel_wheat_for(c, h))
	check(got.all(func(k): return k == 2), "three households each get a pot, none all six (%s)" % str(got))


func _parcel_wheat_for(c: Chapel, h: int) -> int:
	var k := 0
	for p in c.parcels_for(h):
		k += (p.inv as Inventory).count("wheat")
	return k


## CHAPEL-PURPOSE: the food nearest to spoiling (the fastest-spoiling: the store records no ages) leaves first; grain last.
func test_oldest_first() -> void:
	var order := Chapel.give_order()
	check(order.find("milk") < order.find("pottage") and order.find("pottage") < order.find("wheat") and order[-1] != "milk", "the give order puts the fastest-spoiling food first (%s)" % str(order.slice(0, 4)))
	var keeps := true
	for i in range(1, order.size()):
		if Decay.rate(order[i]) > Decay.rate(order[i - 1]):
			keeps = false
	check(keeps, "the order follows the spoil rates")
	var w := new_world()
	var c: Chapel = w.chapel
	w.brain.update_market()
	var hs := emptied(w, 1)
	c.store.items.clear()
	c.store.add("wheat", 40)
	c.store.add("milk", 2)
	c.relief_hist = []
	c.relief_week = 0.0
	c.food_alms()
	var milk := 0
	for p in c.parcels_for(hs[0]):
		milk += (p.inv as Inventory).count("milk")
	check(c.store.count("milk") == 0 and milk == 2, "the milk is given before the grain")


## CHAPEL-PURPOSE: the emergency round finds households in imminent hunger itself, every day (no one need ask), gives from
## the whole store (its reserve included), those missing meals first, then children and elders; its parcels are carried
## before the ordinary alms.
func test_emergency() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	w.brain.update_market()
	var hs := emptied(w, 2)
	var a: int = hs[0]
	var b: int = hs[1]
	c.note_missed(adult_of(w, b))
	check(c.is_missing_meals(b) and not c.is_missing_meals(a), "a member of one household missed a meal for want of food")
	c.store.items.clear()
	c.coins = 0
	var one_day := ceili(w.brain.household_day_food(b) / NPCBrain.food_points("wheat"))
	one_day += one_day % 2
	c.store.add("wheat", one_day)            # about one day for the household that missed meals
	c.relief_hist = [100000.0]               # a large reserve: the emergency round uses it all the same
	check(c.food_reserve() > 0, "a food reserve is kept")
	c.relief_round()
	check(_parcel_wheat_for(c, b) >= 2 and _parcel_wheat_for(c, b) >= _parcel_wheat_for(c, a), "the household missing meals is served first (%d, other %d)" % [_parcel_wheat_for(c, b), _parcel_wheat_for(c, a)])
	check(int(w.stats.get("chapel_emergency_found", 0)) >= 2 and int(w.stats.get("chapel_asked", 0)) == 0, "found without anyone asking")
	check(int(w.stats.get("chapel_unhelped_chapel_empty", 0)) >= 1, "a household still short with the chapel empty is counted as unhelped, with the reason")
	check(c.parcels.all(func(p): return bool(p.urgent) and str(p.why) == "relief"), "emergency parcels are urgent")
	# with enough for both: each brought to one day first, then toward relief_fill_days
	var w2 := new_world()
	var c2: Chapel = w2.chapel
	w2.brain.update_market()
	var hs2 := emptied(w2, 2)
	c2.store.items.clear()
	c2.coins = 0
	c2.store.add("wheat", 400)
	c2.relief_round()
	for h in hs2:
		check(c2.projected_days(h) >= float(GameData.b("relief_fill_days")) - 0.01, "household %d brought to %d days of food (%.1f)" % [h, int(GameData.b("relief_fill_days")), c2.projected_days(h)])
	# an alms parcel and an emergency parcel: a clergy member carries the emergency first
	c2.store.add("wheat", 200)
	var alms := c2._parcel(hs2[0], c2.door_cell(), false, "alms")
	w2.transfer(c2.store, alms.inv, "wheat", 2)
	alms.day = w2.day() - 3                  # older, but not urgent
	var cl: NPC = jobber(w2, "church_assistant")[0]
	check(c2.plan_deliver(cl), "the church assistant takes up a parcel")
	var picked := c2.parcel(int(cl.plan[1].args.p))
	check(bool(picked.urgent), "the emergency parcel before the older alms")
	# the evening: emergency relief before the coin alms
	var w3 := new_world()
	var c3: Chapel = w3.chapel
	while not c3.is_service_day():
		w3.minutes += 1440.0
	w3.brain.update_market()
	emptied(w3, 1)
	c3.store.items.clear()
	c3.coins = c3.operating_reserve() + 30
	c3.evening_day = -1
	var total0 := w3.total_coins()
	c3.evening()
	check(int(w3.stats.get("chapel_relief_bought", 0)) > 0 and w3.total_coins() == total0, "on the service day the emergency is bought for before the alms are given; coins conserved")


## CHAPEL-PURPOSE: legitimate transfer. The food is the chapel's until a person carries it: a clergy member walks to it,
## takes up a load (manor_jobs.haul_max units), walks to the house and puts it in the pantry; a member who comes to the
## chapel takes home what waits there. The manor's relief does not give what the chapel is bringing.
func test_transfer() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	w.brain.update_market()
	var hs := emptied(w, 1)
	var h: int = hs[0]
	c.store.items.clear()
	c.coins = 0
	c.store.add("wheat", 400)
	var census0 := _census_wheat(w)
	c.relief_round()
	var pantry := w.households[h].pantry as Inventory
	check(pantry.count("wheat") == 0 and _parcel_wheat_for(c, h) > 0, "set aside, not yet in the pantry")
	check(_census_wheat(w) == census0, "the census counts the parcels as the chapel's: nothing made or lost")
	# the manor sees the food on its way
	w.treasury = 5000
	var obligations: float = w.brain.daily_obligations()
	var g0 := int(w.stats.get("gov_relief_grain", 0)) + int(w.stats.get("gov_relief_bought", 0))
	w.brain._relief(obligations, obligations * float(GameData.b("treasury_reserve_days")))
	check(w.manor_work.pending_for(h) == 0 and int(w.stats.get("gov_relief_grain", 0)) + int(w.stats.get("gov_relief_bought", 0)) == g0, "the manor's relief counts the chapel's food on its way and sends nothing")
	# a clergy member carries it
	var cl: NPC = jobber(w, "preacher")[0]
	var want := _parcel_wheat_for(c, h)
	check(c.plan_deliver(cl) and cl.plan.size() == 4 and cl.plan[1].act == "church_pickup" and cl.plan[3].act == "church_deliver", "the preacher plans the walk: to the food, take it up, to the house, put it in")
	check(cl.plan[2].to == c._dest(h), "to the household's door")
	var pid := int(cl.plan[1].args.p)
	check(not c.plan_deliver(jobber(w, "church_assistant")[0]) or int(jobber(w, "church_assistant")[0].plan[1].args.p) != pid, "nobody else takes the same parcel")
	check(w.brain.act(cl, "church_pickup", {"p": pid}), "taken up")
	var load := (c.parcel(pid).inv as Inventory).total()
	check(load <= int(GameData.b("manor_jobs").haul_max), "a load of at most %d units (%d)" % [int(GameData.b("manor_jobs").haul_max), load])
	check(w.brain.act(cl, "church_deliver", {"p": pid}) and pantry.count("wheat") == load and c.parcel(pid).is_empty(), "put into the pantry on arrival")
	check(_census_wheat(w) == census0, "still nothing made or lost")
	# a carrier whose plan is given up sets the load down where they stand; another may take it up there
	var cl2: NPC = jobber(w, "church_assistant")[0]
	if c.plan_deliver(cl2):
		var p2 := int(cl2.plan[1].args.p)
		w.brain.act(cl2, "church_pickup", {"p": p2})
		cl2.plan.clear()
		c.release_stale()
		var pp := c.parcel(p2)
		check(int(pp.carrier) == -1 and not bool(pp.held) and int(pp.at[0]) == cl2.cell().x and int(pp.at[1]) == cl2.cell().y, "an abandoned load lies where its carrier stood, for another to carry")
	# a household member fetching: they come for what is waiting at the door and take it home
	var w2 := new_world()
	var c2: Chapel = w2.chapel
	w2.brain.update_market()
	var h2: int = emptied(w2, 1)[0]
	var n := adult_of(w2, h2)
	c2.store.items.clear()
	c2.coins = 0
	c2.store.add("wheat", 60)
	check(c2.plan_ask(n) and n.plan[1].act == "church_ask", "a member of a household short of food goes to the chapel")
	n.plan.clear()
	check(w2.brain.act(n, "church_ask", {}), "asking is answered")
	var pantry2 := w2.households[h2].pantry as Inventory
	check(pantry2.count("wheat") == 0 and n.plan.size() >= 2 and n.plan[0].to == c2._dest(h2) and n.plan[1].act == "church_deliver", "they carry it home")
	for s in n.plan.duplicate():
		if str(s.get("k", "")) == "do":
			w2.brain.act(n, s.act, s.args)
	check(pantry2.count("wheat") > 0 and w2.brain.household_food_days(h2) >= float(GameData.b("relief_trigger_days")), "and put it in the pantry (%.1f days)" % w2.brain.household_food_days(h2))
	check(int(w2.stats.get("chapel_relieved", 0)) == 1 and int(w2.stats.get("chapel_asked", 0)) == 1, "counted as church relief")
	# an empty church gives nothing, and says so by doing nothing
	var w3 := new_world()
	var h3: int = emptied(w3, 1)[0]
	w3.chapel.store.items.clear()
	w3.chapel.coins = 0
	check(not w3.chapel.can_give() and not w3.chapel.plan_ask(adult_of(w3, h3)), "a church with nothing does not send anyone to ask")


func _census_wheat(w: World) -> int:
	var g: Dictionary = SettlementHoldings.holders(w)
	var k := 0
	for part in g:
		if g[part] is Dictionary:
			k += int((g[part] as Dictionary).get("wheat", 0))
	return k


## CHAPEL-PURPOSE: with no food in store the emergency round buys with the fund, paid to the sellers; the food is the
## chapel's where it was bought, to be carried from there.
func test_relief_bought() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	var h: int = emptied(w, 1)[0]
	w.brain.update_market()
	c.store.items.clear()
	c.coins = 200
	var total0 := w.total_coins()
	c.relief_round()
	check(c.coins < 200 and c.pending_points(h) > 0.0, "with no food in store the church buys food with its coins (%d spent)" % (200 - c.coins))
	check(w.total_coins() == total0, "the coins went to the sellers: none made or lost")
	check(int(w.stats.get("chapel_relief_bought", 0)) == 200 - c.coins, "counted")
	var door := c.door_cell()
	check(c.parcels.any(func(p): return int(p.at[0]) != door.x or int(p.at[1]) != door.y), "bought food lies at the seller's, to be carried from there")


## CHAPEL-PURPOSE section 2, the reserve audit: the fund keeps the clergy's wages for operating_reserve_days, wages owed and
## its recent relief and seed spending; nothing for undesigned projects. Section 5-6: the death record reads and changes nothing.
func test_reserve_audit() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	var wages := 0
	for o: NPC in w.npcs:
		if Chapel.is_clergy(o):
			wages += c.wage_of(o.job)
	c.spent = []
	c.owed = {}
	check(c.operating_reserve() == wages * int(Chapel.cfg().operating_reserve_days), "the reserve is wages only when nothing is owed or spent (%d)" % c.operating_reserve())
	check(c.operating_reserve() < 200, "a modest reserve: %d coins" % c.operating_reserve())
	# the death record changes nothing
	var h: int = emptied(w, 1)[0]
	var n := adult_of(w, h)
	var before := JSON.stringify(w.to_dict())
	var rng0: int = w.rng.state
	c.on_starved(n)
	check(JSON.stringify(w.to_dict()) == before and w.rng.state == rng0 and c.death_log.size() == 1, "the starvation record reads the world and changes nothing")
	check(c.death_log[0].has("chapel_points") and c.death_log[0].has("hh_coins") and c.death_log[0].has("parcels_pending"), "it records the household's and the chapel's position")


func _pantry_wheat(w: World) -> int:
	var k := 0
	for hh in w.households:
		k += (hh.pantry as Inventory).count("wheat")
	return k


## DVW-B4: the chapel's store spoils as every store does.
func test_store_spoils() -> void:
	var w := new_world()
	var c: Chapel = w.chapel
	c.store.add("wheat", 5000)
	var before := c.store.count("wheat")
	Decay.dawn(w)
	var lost := before - c.store.count("wheat")
	check(lost >= floori(5000 * float((GameData.b("decay").spoil as Dictionary).wheat)) and lost > 0 and int(w.stats.get("chapel_spoiled", 0)) == lost, "the chapel's grain spoils at the store rate (%d of 5000)" % lost)


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
