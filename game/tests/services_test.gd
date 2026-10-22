extends SceneTree
## CON-02 (owner directive 2026-10-21 sections 2-4, 6): service contracts inside the one CON-01 engine. A service is
## offered, judged (the seller's skills, tools, time, obligations, household, alternatives, relationship and risk),
## countered and signed like goods; it is fulfilled only by work done through the existing systems (a unit dug by
## OpenPits.dig, a reading assayed and told by Prospecting), each unit paid from the coins set aside at agreement. All
## three directions; feasibility; work actually done; reservation and payment accounting; expiry and cancellation;
## save and load; determinism; goods contracts, the manor's jobs and paid work quests untouched.
##   godot --headless --path game --script res://tests/services_test.gd

const Census := preload("res://tests/census.gd")

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
	test_dig_player_hires_villager()
	test_survey_player_hires_villager()
	test_survey_npc_to_npc()
	test_survey_npc_to_player()
	test_feasibility_and_counters()
	test_signing_and_obligations()
	test_lapse_and_cancel()
	test_save_load()
	test_determinism()
	test_other_rules_untouched()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- helpers --------------------
func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	w.minutes = float(w.day()) * World.DAY + 8.0 * 60.0
	return w


func coins(w: World) -> int:
	return w.total_coins() - w.coin_sources


func goods(w: World) -> Dictionary:
	return Census.goods(w)


func _sites(w: World) -> Array:
	var out := []
	for y in w.map.h:
		for x in w.map.w:
			var o := Vector2i(x, y)
			if w.pits.site_open(o) and w.pits.site_refusal(o) == "":
				out.append(o)
				if out.size() >= 2:
					return out
	return out


func player_pit(w: World) -> Dictionary:
	var s := _sites(w)
	return w.pits.open_pit(World.PLAYER, s[0]) if not s.is_empty() else {}


func miner(w: World) -> NPC:
	var m: NPC = w.brain._first_with_job("miner")
	if not m.inv.has("pickaxe"):
		m.inv.add("pickaxe")
	if not m.inv.has("shovel"):
		m.inv.add("shovel")                   # MIN-E-Q4: a pit's earth is dug with a shovel
	w.player.pos = m.pos               # face to face (Q-C6/Q-C7)
	return m


func smith_ready(w: World) -> NPC:
	var s: NPC = w.brain._first_with_job("smith")
	s.pos = Vector2(w.brain._workplace_cell(s)) + Vector2(0.5, 0.5)
	s.inv.add("coal", 10)
	return s


## A clue with samples left, the nearest to `at`.
func clue_near(w: World, at: Vector2) -> Dictionary:
	var best := {}
	for c in w.prospecting.clues:
		if w.prospecting.samples_left(c) >= 3 and (best.is_empty() or at.distance_to(Vector2(int(c.x), int(c.y))) < at.distance_to(Vector2(int(best.x), int(best.y)))):
			best = c
	return best


## Drive a villager seller through its plans: walk (it is put where it walks), work, act. Steps until nothing is
## planned or `most` plans; returns the plans made.
func run(w: World, n: NPC, most := 60) -> int:
	var made := 0
	for i in most:
		n.plan = []
		if not w.contracts.plan(n):
			break
		made += 1
		for st in n.plan.duplicate():
			if str(st.k) == "go":
				n.pos = Vector2(st.to) + Vector2(0.5, 0.5)
			elif st.has("act"):
				w.brain.act(n, str(st.act), st.get("args", {}))
		for o: NPC in w.npcs:                       # a smith's assay is done at once here (its forge work is not run)
			if o.job == "smith":
				o.plan = []
	return made


func home(w: World) -> String:
	for id in w.buildings:
		if str(w.buildings[id].get("type", "")) == "house":
			return id
	return ""


# ---------------------------------------------------------------- tests ----------------------
## Player to NPC: a miner digs the player's open pit; each unit dug by OpenPits.dig is paid; earth is tipped on the
## pit's heaps and stone brought to the player's chest; nothing is made but the pit's own ground.
func test_dig_player_hires_villager() -> void:
	var w := new_world()
	var p := player_pit(w)
	check(not p.is_empty(), "the player stakes an open pit")
	if p.is_empty():
		return
	var m := miner(w)
	w.player.coins = 1000
	w.player.home = home(w)
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	var price := ceili(ContractServices.going(svc)) + 2
	var c0 := coins(w)
	var dug0 := _dug(p)
	var g0 := goods(w)
	var r := w.contracts.propose(World.PLAYER, m, "", 6, price, 3, [], svc)
	check(r.has("contract"), "a miner with a pickaxe and a shovel agrees to dig 6 units of the player's pit (\"%s\")" % str(r.get("say", "")))
	if not r.has("contract"):
		return
	var c: Dictionary = r.contract
	check(str(c.kind) == "service" and int(c.reserved) == 6 * price and w.player.coins == 1000 - 6 * price and coins(w) == c0,
			"the player's coins for the work are set aside at agreement, still counted")
	check(_dug(p) == dug0 and int(c.delivered) == 0 and int(c.paid) == 0, "agreeing does no work and pays nothing")
	run(w, m)
	check(_dug(p) == dug0 + 6 and int(c.delivered) == 6 and int(c.paid) == 6 * price and int(c.reserved) == 0, "the miner dug 6 units, each paid as dug (%d dug)" % (_dug(p) - dug0))
	check(str(c.state) == "fulfilled" and (c.load as Dictionary).is_empty(), "fulfilled once the earth is tipped and nothing is carried")
	check(coins(w) == c0, "coins only moved (%d)" % (coins(w) - c0))
	var g1 := goods(w)
	var made := 0
	for id in g1:
		made += int(g1[id]) - int(g0.get(id, 0))
	for id in g0:
		if not g1.has(id):
			made -= int(g0[id])
	check(made == 6 and _sum(w.pits.goods()) + w.player.chest.count("stone") >= 6 - int(c.load.get("stone", 0)),
			"the only new goods are the 6 units out of the pit's own ground, on its heaps (%d)" % made)
	check(not m.memory.is_empty(), "the miner remembers the promise")


func _dug(p: Dictionary) -> int:
	var t := 0
	for v in p.dug:
		t += int(v)
	return t


func _sum(d: Dictionary) -> int:
	var t := 0
	for k in d:
		t += int(d[k])
	return t


## Player to NPC: a survey. The seller samples with its own kit, pays the assay fees, and tells the player each
## reading; a reading counts and is paid only once told.
func test_survey_player_hires_villager() -> void:
	var w := new_world()
	var m := miner(w)
	m.inv.add(Prospecting.KIT)
	m.coins = 400
	smith_ready(w)
	w.player.coins = 1000
	var cl := clue_near(w, m.pos)
	var svc := {"service": "survey", "site": {"clue": str(cl.id)}}
	var price := ceili(ContractServices.going(svc)) + 4
	var c0 := coins(w)
	var r := w.contracts.propose(World.PLAYER, m, "", 2, price, 4, [], svc)
	check(r.has("contract"), "a villager with a kit agrees to survey a stain for the player (\"%s\")" % str(r.get("say", "")))
	if not r.has("contract"):
		return
	var c: Dictionary = r.contract
	var known0 := w.prospecting.findings(World.PLAYER).size()
	var fees0 := float(w.stats.get("assay_fees", 0.0))
	run(w, m)
	check(int(c.delivered) == 2 and str(c.state) == "fulfilled" and int(c.paid) == 2 * price, "two readings taken, assayed and told, each paid (%d done)" % int(c.delivered))
	check(w.prospecting.findings(World.PLAYER).size() > known0 or w.prospecting.records.filter(func(x): return w.prospecting.knows(World.PLAYER, x)).size() >= 2,
			"the player now knows the readings")
	check(float(w.stats.get("assay_fees", 0.0)) - fees0 == 2.0 * float(Prospecting.cfg().assay.fee), "the seller paid the assay fees (its cost of the work)")
	check(coins(w) == c0, "coins only moved (%d)" % (coins(w) - c0))


## NPC to NPC: the same engine, a villager hiring a villager.
func test_survey_npc_to_npc() -> void:
	var w := new_world()
	var m := miner(w)
	m.inv.add(Prospecting.KIT)
	m.coins = 400
	smith_ready(w)
	var b: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != m and o.job == "farmer":
			b = o
			break
	b.coins = 2000
	b.pos = m.pos
	var cl := clue_near(w, m.pos)
	var svc := {"service": "survey", "site": {"clue": str(cl.id)}}
	var c0 := coins(w)
	var r := w.contracts.propose(World.npc_ref(b.id), m, "", 2, 30, 4, [], svc)
	check(r.has("contract") and int(r.contract.reserved) == 60, "a villager hires another to survey, its coins set aside")
	if not r.has("contract"):
		return
	var c: Dictionary = r.contract
	b.pos = Vector2(w.brain._workplace_cell(b)) + Vector2(0.5, 0.5)
	run(w, m)
	check(str(c.state) == "fulfilled" and int(c.paid) == 60 and w.prospecting.records.filter(func(x): return w.prospecting.knows(World.npc_ref(b.id), x)).size() >= 2,
			"the seller walks to the buyer and tells it the readings face to face; paid in full")
	check(coins(w) == c0, "coins only moved")


## NPC to player: a villager's offer to hire the player; the player does the work through the same systems
## (their own kit, a smith's assay) and reports it face to face.
func test_survey_npc_to_player() -> void:
	var w := new_world()
	var b: NPC = w.brain._first_with_job("farmer")
	b.coins = 2000
	var smith := smith_ready(w)
	var cl := clue_near(w, w.player.pos)
	var svc := {"service": "survey", "site": {"clue": str(cl.id)}}
	var c := w.contracts.offer_to_player(b, "", 2, 12, 4, svc)
	check(str(c.state) == "offered" and str(c.kind) == "service" and int(c.reserved) == 0, "a villager offers to hire the player for a survey; nothing set aside yet")
	var dear := w.contracts.counter_offer(c, 2, 30, 4)
	check(str(dear.answer) == "counter" and int(c.price_each) == floori(12 * float(Contracts.cfg().npc_counter_tolerance)), "the player asks more; the villager counters with the most it pays")
	w.player.pos = b.pos
	var ok := w.contracts.counter_offer(c, 2, int(c.price_each), 4)
	check(str(ok.answer) == "accept" and str(c.state) == "accepted" and int(c.reserved) == 2 * int(c.price_each), "agreed face to face: its coins are set aside")
	w.player.inv.add(Prospecting.KIT)
	w.player.coins = 100
	var c0 := coins(w)
	check(ContractServices.player_report(w.contracts, c) == 0 and int(c.paid) == 0, "with no work done, nothing can be reported or paid")
	var taken := 0
	for cell: Vector2i in cl.spots:
		if taken >= 2:
			break
		if w.prospecting.take_sample(w.player, cl, cell).result == "ok":
			taken += 1
	w.player.pos = smith.pos
	for i in 2:
		smith.plan = []
		w.prospecting.assay(w.player, smith)
	w.player.pos = b.pos
	var told := ContractServices.player_report(w.contracts, c)
	check(told == 2 and str(c.state) == "fulfilled" and int(c.paid) == 2 * int(c.price_each), "the player's two readings are told and paid (%d)" % told)
	check(ContractServices.player_report(w.contracts, c) == 0 and int(c.paid) == 2 * int(c.price_each), "reported work is not paid twice")
	check(coins(w) == c0, "coins only moved")


## Feasibility and counters: no tool, no pit of the buyer's, not enough time; a low price countered; the buyer meets it.
func test_feasibility_and_counters() -> void:
	var w := new_world()
	var p := player_pit(w)
	var m := miner(w)
	w.player.coins = 2000
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	var wc: NPC = w.brain._first_with_job("woodcutter")
	wc.inv.remove("pickaxe", wc.inv.count("pickaxe"))
	wc.inv.remove("shovel", wc.inv.count("shovel"))
	w.player.pos = wc.pos
	var r := w.contracts.propose(World.PLAYER, wc, "", 4, 10, 3, [], svc)
	check(str(r.answer) == "reject" and str(r.say).contains("shovel"), "no shovel for the earth, no digging: \"%s\"" % str(r.say))
	r = w.contracts.propose(World.PLAYER, m, "", 4, 10, 3, [], {"service": "dig", "site": {"pit": 999}})
	check(str(r.answer) == "reject" and str(r.say).contains("no such pit"), "no such pit: \"%s\"" % str(r.say))
	var sm: NPC = w.brain._first_with_job("smith")
	w.player.pos = m.pos
	var mp := w.pits.open_pit(World.MANOR, _sites(w)[0]) if _sites(w).size() > 0 else {}
	if not mp.is_empty():
		r = w.contracts.propose(World.PLAYER, m, "", 4, 10, 3, [], {"service": "dig", "site": {"pit": int(mp.id)}})
		check(str(r.answer) == "reject" and str(r.say).contains("not yours"), "the player cannot hire digging in the manor's pit: \"%s\"" % str(r.say))
	m.income_days = [80, 80, 80, 80, 80]           # a miner who earns well asks more than a coin a unit
	r = w.contracts.propose(World.PLAYER, m, "", 3, 1, 3, [], svc)
	check(str(r.answer) == "counter" and int(r.price_each) == int(r.min_price) and int(r.price_each) > 1 and w.contracts.reserved_total() == 0,
			"a price of 1 is countered with the least the miner takes (%d); nothing set aside" % int(r.price_each))
	var again := w.contracts.propose(World.PLAYER, m, "", int(r.qty), int(r.price_each), int(r.days), r.history, svc)
	check(again.has("contract") and (again.contract.history as Array).size() == 4, "meeting the counter makes the contract, the talk on record")
	var t: Dictionary = r.terms
	check(t.has("alternatives") and t.has("household") and t.has("relationship") and t.has("risk") and t.has("obligations") and float(t.going) == ContractServices.going(svc),
			"the service is judged on every term, at the job board's going rate (%s)" % str(t.going))
	var big := w.contracts.evaluate(m, World.PLAYER, "", 200, 50, 1, svc)
	check(str(big.answer) == "counter" and (int(big.days) > 1 or int(big.qty) < 200), "more work than the time allows is countered (%s: %d in %d days, \"%s\")" % [str(big.answer), int(big.qty), int(big.days), str(big.say)])
	var nokit := w.contracts.evaluate(sm, World.PLAYER, "", 2, 50, 3, {"service": "survey", "site": {"clue": str(w.prospecting.clues[0].id)}})
	check(str(nokit.answer) == "reject" and str(nokit.say).contains("kit"), "no kit, no survey: \"%s\"" % str(nokit.say))


## Signing (Q-C6/Q-C7) applies to services; obligations: the manor's job board and tool orders count against the time.
func test_signing_and_obligations() -> void:
	var w := new_world()
	var p := player_pit(w)
	var m := miner(w)
	w.player.coins = 2000
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	w.player.pos = Vector2(2, 2)
	while not w.present(w.player.pos, 3.0).is_empty():
		w.player.pos += Vector2(3, 0)
	var r := w.contracts.propose(World.PLAYER, m, "", 6, 10, 3, [], svc)
	check(str(r.answer) == "meet" and w.contracts.reserved_total() == 0, "a formal service contract (60 coins) is not agreed at a distance")
	r = w.contracts.propose(World.PLAYER, m, "", 2, 10, 3, [], svc)
	check(r.has("contract"), "a small one (20 coins) is, unsigned")
	var before := int(ContractServices.means(w.contracts, m, svc, 1).cap)
	var j := {"kind": "haul", "qty": 1, "wage": 1}
	w.manor_work._post(j)
	w.manor_work.take(j, World.npc_ref(m.id))
	var after := int(ContractServices.means(w.contracts, m, svc, 1).cap)
	check(bool(w.contracts.obligations(m).manor_job) and after < before, "a manor job today leaves less time for the work (%d, before %d)" % [after, before])


## Lapse and cancellation: the coins set aside come back; what was done stays paid; anything carried goes to its place.
func test_lapse_and_cancel() -> void:
	var w := new_world()
	var p := player_pit(w)
	var m := miner(w)
	w.player.coins = 2000
	w.player.home = home(w)
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "", 6, 10, 2, [], svc).get("contract", {})
	check(not c.is_empty(), "a dig contract")
	if c.is_empty():
		return
	var c0 := coins(w)
	# dig two units, then cancel while the earth is still carried
	for i in 2:
		m.plan = []
		w.contracts.plan(m)
		for st in m.plan:
			if str(st.k) == "go":
				m.pos = Vector2(st.to) + Vector2(0.5, 0.5)
			elif st.has("act"):
				w.brain.act(m, str(st.act), st.get("args", {}))
	check(int(c.delivered) == 2 and _sum(c.load) == 2, "two units dug and still carried")
	var heaps0 := _sum(w.pits.goods())
	check(w.contracts.cancel(c, World.PLAYER) == "" and int(c.reserved) == 0 and w.player.coins == 2000 - 20 and (c.load as Dictionary).is_empty(),
			"cancelled: the two units stay paid, the rest comes back")
	check(_sum(w.pits.goods()) - heaps0 + w.player.chest.count("stone") >= 2 and coins(w) == c0, "the carried earth goes onto the pit's heaps; coins only moved")
	var c2: Dictionary = w.contracts.propose(World.PLAYER, m, "", 3, 10, 1, [], svc).get("contract", {})
	check(not c2.is_empty(), "another, due today")
	if c2.is_empty():
		return
	w.minutes += World.DAY
	w.contracts.dawn()
	check(str(c2.state) == "lapsed" and int(c2.reserved) == 0 and w.player.coins == 1980, "undone past its day it lapses: the coins come back")


## Save and load mid-work: progress, the load and the reservation are kept; nothing is paid twice.
func test_save_load() -> void:
	var w := new_world()
	var p := player_pit(w)
	var m := miner(w)
	w.player.coins = 2000
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	var c: Dictionary = w.contracts.propose(World.PLAYER, m, "", 4, 10, 3, [], svc).get("contract", {})
	m.plan = []
	w.contracts.plan(m)
	for st in m.plan:
		if str(st.k) == "go":
			m.pos = Vector2(st.to) + Vector2(0.5, 0.5)
		elif st.has("act"):
			w.brain.act(m, str(st.act), st.get("args", {}))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var c2: Dictionary = w2.contracts.get_contract(int(c.id))
	check(str(c2.kind) == "service" and int(c2.delivered) == 1 and int(c2.reserved) == 30 and _sum(c2.load) == 1 and int(c2.site.pit) == int(p.id),
			"saved and loaded mid-work: progress, load and coins set aside")
	check(w2.total_coins() == w.total_coins() and goods(w2) == goods(w), "every coin and good is there after loading")
	var m2: NPC = w2.npc(m.id)
	run(w2, m2)
	check(str(c2.state) == "fulfilled" and int(c2.paid) == 40 and int(c2.delivered) == 4, "after loading only the rest is done and paid (%d paid)" % int(c2.paid))
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	old.contracts.list = (old.contracts.list as Array).filter(func(x): return str(x.get("kind", "goods")) != "service")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.contracts.goods().is_empty(), "a save with goods contracts only (CON-01) loads with no service work")


## The same world and the same work: the same records.
func test_determinism() -> void:
	var out := []
	for i in 2:
		var w := new_world(2)
		var p := player_pit(w)
		var m := miner(w)
		w.player.coins = 2000
		w.contracts.propose(World.PLAYER, m, "", 5, 10, 3, [], {"service": "dig", "site": {"pit": int(p.id)}})
		run(w, m)
		out.append(JSON.stringify([w.contracts.to_dict(), p.dug, w.pits.goods()]))
	check(out[0] == out[1], "two runs of one seed dig the same cells and keep the same records")


## The manor's job board and paid work quests keep their own payment rules; a goods contract is untouched by services.
func test_other_rules_untouched() -> void:
	var w := new_world()
	var p := player_pit(w)
	var m := miner(w)
	w.player.coins = 2000
	w.treasury = 2000
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	var sc: Dictionary = w.contracts.propose(World.PLAYER, m, "", 2, 10, 3, [], svc).get("contract", {})
	var j := {"kind": "haul", "qty": 1, "wage": 7}
	w.manor_work._post(j)
	var t0 := w.treasury
	check(w.manor_work.take(j, World.npc_ref(m.id)) and w.treasury == t0 - 7 and int(j.reserved) == 7, "a manor job still sets its wage aside from the treasury")
	var mc := m.coins
	w.manor_work._finish(j, World.npc_ref(m.id))
	check(m.coins == mc + 7 and int(sc.reserved) == 20, "and pays it in full on finishing; the service's own reservation is untouched")
	var gc: Dictionary = w.contracts.propose(World.PLAYER, m, "iron_ore", 2, 30, 3).get("contract", {})
	m.inv.add("iron_ore", 2)
	check(not gc.is_empty() and w.contracts.deliver(gc, 2) == 2 and str(gc.state) == "fulfilled" and int(gc.paid) == 60, "a goods contract is delivered and paid as before")
	check(w.contracts.deliver(sc, 1) == 0 and int(sc.delivered) == 0, "a service cannot be 'delivered' as goods: only work done counts")
	var f: NPC = w.brain._first_with_job("farmer")
	f.coins = 100
	var t := Quests.template("work_the_mine")
	var mm: NPC = w.brain._first_with_job("miner")
	mm.inv.remove("iron_ore", mm.inv.count("iron_ore"))
	mm.coins = 100
	check(Quests.promised(t) == int(t.wage) and t.get("hire", false), "a paid work quest still promises its whole wage (full or nothing)")
