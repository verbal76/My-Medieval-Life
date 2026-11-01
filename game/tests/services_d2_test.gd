extends SceneTree
## Decision 2 (owner 2026-11-01, informal services and expanded service contracts) and CON-03..CON-08 (owner 2026-10-21,
## CON02-S-1..6) in the one contract engine (Contracts, ContractServices; docs/expansion20/SERVICES.md):
##  - terms: what may be offered (pay structures, retention, advances; a favour carries no money terms);
##  - Decision 2: a favour (nothing paid) only between friends, partners and kin; informal work below the signing line;
##  - CON-03 advances: set aside, drawn only for the named expense (assay fees) as it is paid, the rest returned;
##  - CON-04 pay structures: for results only (nothing for a barren unit), base plus bonus;
##  - CON-05 retention and disputes before the reeve: either party may prevail; coins only move;
##  - CON-06 farm labour: the crop goes to the owner's store, never the worker's; the player as hired hand and as employer;
##  - CON-07 villager hiring: only a genuine need its own hands cannot meet; none when they can;
##  - CON-08 the separate service signing line (null: the 50-coin goods line);
##  - experience for the work, coin and goods conservation, save and load (older records), determinism.
##   godot --headless --path game --script res://tests/services_d2_test.gd

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
	test_terms()
	test_favour()
	test_on_result_survey_with_advance()
	test_base_bonus_and_retention()
	test_disputes()
	test_harvest_hired_by_household()
	test_harvest_own_hands()
	test_harvest_player_as_hand()
	test_harvest_player_as_employer()
	test_signing_line()
	test_save_load()
	test_determinism()
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


func player_pit(w: World) -> Dictionary:
	for y in w.map.h:
		for x in w.map.w:
			var o := Vector2i(x, y)
			if w.pits.site_open(o) and w.pits.site_refusal(o) == "":
				return w.pits.open_pit(World.PLAYER, o)
	return {}


func miner(w: World) -> NPC:
	var m: NPC = w.brain._first_with_job("miner")
	for t in ["pickaxe", "shovel"]:
		if not m.inv.has(t):
			m.inv.add(t)
	w.player.pos = m.pos
	return m


func smith_ready(w: World) -> NPC:
	var s: NPC = w.brain._first_with_job("smith")
	s.pos = Vector2(w.brain._workplace_cell(s)) + Vector2(0.5, 0.5)
	s.inv.add("coal", 10)
	return s


func clue_near(w: World, at: Vector2) -> Dictionary:
	var best := {}
	for c in w.prospecting.clues:
		if w.prospecting.samples_left(c) >= 3 and (best.is_empty() or at.distance_to(Vector2(int(c.x), int(c.y))) < at.distance_to(Vector2(int(best.x), int(best.y)))):
			best = c
	return best


func home(w: World) -> String:
	for id in w.buildings:
		if str(w.buildings[id].get("type", "")) == "house":
			return id
	return ""


## Drive a villager seller through its plans (as services_test.run).
func run(w: World, n: NPC, most := 80) -> int:
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
		for o: NPC in w.npcs:
			if o.job == "smith":
				o.plan = []
	return made


func friends(w: World, a: int, b: int) -> void:
	w.relations.tie(a, b).friends = true


## A household with a home and an adult, and a leased plot near the player's start with `n` ripe wheat cells (a fixture: the cells
## are set ripe directly). Returns {h, b (its first adult), plot}.
func household_field(w: World, n: int) -> Dictionary:
	var fp: FarmPlots = w.farm_plots
	for h in w.households.size():
		if not w.buildings.has(str(w.households[h].home)):
			continue
		var members: Array = w.brain._members(h)
		members.sort_custom(func(x: NPC, y: NPC) -> bool: return x.id < y.id)
		var b: NPC = null
		for o: NPC in members:
			if o.alive and o.role == "adult":
				b = o
				break
		if b == null:
			continue
		var sp = w.map.data.spawns.player
		var r: Rect2i = fp.find_ground(Vector2i(5, 5), Vector2i(int(sp[0]), int(sp[1])), h)
		var ref := World.hh_ref(h)
		b.coins += 50
		var p := fp.claim(r, ref, true)
		if p.is_empty():
			continue
		var inner := r.grow(-1)
		var k := 0
		for y in range(inner.position.y, inner.end.y):
			for x in range(inner.position.x, inner.end.x):
				if k < n:
					fp.cells[Vector2i(x, y)] = {"crop": "wheat", "state": "ripe", "progress": 1.0, "plot": str(p.id)}
					k += 1
		return {"h": h, "b": b, "plot": p}
	return {}


func contract_of(w: World, kind: String) -> Dictionary:
	for c in w.contracts.list:
		if Contracts.is_service(c) and str(c.service) == kind:
			return c
	return {}


# ---------------------------------------------------------------- tests ----------------------
func test_terms() -> void:
	var dig := {"service": "dig", "site": {"pit": 0}}
	var harvest := {"service": "harvest", "site": {"plot": "x"}}
	var survey := {"service": "survey", "site": {"clue": "x"}}
	var fee := int(Prospecting.cfg().assay.fee)
	check(ContractServices.terms_refusal(dig, 4, 5, {}) == "", "no terms: paid for the work done, as before (CON-04's working default)")
	check(ContractServices.terms_refusal({}, 4, 5, {"pay": "on_result"}) != "", "goods take no service terms")
	check(ContractServices.terms_refusal(dig, 4, 5, {"pay": "barter"}) != "", "an unknown pay structure is refused")
	check(ContractServices.terms_refusal(dig, 4, 0, {"pay": "favour"}) == "", "a favour asks nothing")
	check(ContractServices.terms_refusal(dig, 4, 3, {"pay": "favour"}) != "" and ContractServices.terms_refusal(dig, 4, 0, {"pay": "favour", "retain": 0.25}) != "",
			"a favour carries no price and nothing held back")
	check(ContractServices.terms_refusal(harvest, 4, 1, {"pay": "on_result"}) != "", "a harvest has no separate result to pay for")
	check(ContractServices.terms_refusal(dig, 4, 5, {"pay": "base_bonus"}) != "" and ContractServices.terms_refusal(dig, 4, 5, {"pay": "base_bonus", "bonus_each": 2}) == "",
			"a base and bonus names its bonus")
	check(ContractServices.terms_refusal(dig, 4, 5, {"retain": 0.9}) != "" and ContractServices.terms_refusal(dig, 4, 5, {"retain": 0.25}) == "",
			"no more than retain_max held back")
	check(ContractServices.terms_refusal(dig, 4, 5, {"advance": {"amount": 4, "purpose": "assay_fee"}}) != "", "a dig has no expense an advance may meet")
	check(ContractServices.terms_refusal(survey, 2, 5, {"advance": {"amount": 2 * fee + 1, "purpose": "assay_fee"}}) != "",
			"an advance cannot be more than the expense it is for (CON-03: no unrestricted transfer)")
	check(ContractServices.terms_refusal(survey, 2, 5, {"advance": {"amount": 2 * fee, "purpose": "assay_fee"}}) == "", "the assay fees may be advanced")
	var c := {"kind": "service", "qty": 4, "price_each": 5, "terms": {"pay": "base_bonus", "bonus_each": 2, "retain": 0.25}}
	check(Contracts.set_aside(c) == 4 * 5 + 4 * 2, "a base and bonus sets aside the most it could pay")
	check(ContractServices.pay_for(c, 2, 1) == 2 * 5 + 2 and ContractServices.hold_of(c, 12) == 3, "pay by the structure; a quarter held back")
	check(ContractServices.price_needed(6, {"pay": "on_result"}) == 12 and ContractServices.price_needed(6, {}) == 6, "paid for results only, a worker asks result_premium more")


## Decision 2: work done for nothing between friends; a stranger asks pay; nothing is set aside or paid; the work trains the worker.
func test_favour() -> void:
	var w := new_world()
	var p := player_pit(w)
	var m := miner(w)
	w.player.coins = 100
	w.player.home = home(w)
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	var r := w.contracts.propose(World.PLAYER, m, "", 3, 0, 4, [], svc, {"pay": "favour"})
	check(not r.has("contract") and str(r.say).contains("not for nothing"), "a villager who is not a friend will not work for nothing (\"%s\")" % str(r.say))
	friends(w, Life.PLAYER_ID, m.id)
	m.coins = maxi(m.coins, w.reserve_of(m) + 10)
	var c0 := coins(w)
	var pc0 := w.player.coins
	var xp0 := int(m.skills.get("mining", 0))
	r = w.contracts.propose(World.PLAYER, m, "", 3, 0, 4, [], svc, {"pay": "favour"})
	check(r.has("contract"), "a friend agrees to dig as a favour (\"%s\")" % str(r.get("say", "")))
	if not r.has("contract"):
		return
	var c: Dictionary = r.contract
	check(int(c.reserved) == 0 and w.player.coins == pc0, "nothing is set aside")
	check(not Contracts.formal_of(Contracts.set_aside(c), Contracts.svc_of(c)), "a favour is never a formal contract")
	var r2 := w.contracts.propose(World.PLAYER, m, "", 1, 0, 4, [], svc, {"pay": "favour"})
	check(not r2.has("contract"), "one favour at a time (\"%s\")" % str(r2.get("say", "")))
	run(w, m)
	check(int(c.delivered) == 3 and str(c.state) == "fulfilled" and int(c.paid) == 0, "the work is done and nothing paid (%d done)" % int(c.delivered))
	check(int(m.skills.get("mining", 0)) > xp0, "the work trains the worker (Decision 2 (8))")
	check(float(w.stats.get("service_favours_done", 0)) >= 1.0, "counted as a favour done")
	check(coins(w) == c0 and w.player.coins == pc0, "no coin moved")


## CON-03 and CON-04: a survey paid for results only, its assay fees advanced. The advance is drawn as each fee is paid, the seller
## needs none of its own coins for them, a barren reading pays nothing, and what is left comes back.
func test_on_result_survey_with_advance() -> void:
	var w := new_world()
	var m := miner(w)
	m.inv.add(Prospecting.KIT)
	m.coins = w.reserve_of(m)                      # nothing to spare for fees of its own
	smith_ready(w)
	w.player.coins = 1000
	var cl := clue_near(w, m.pos)
	var svc := {"service": "survey", "site": {"clue": str(cl.id)}}
	var fee := int(Prospecting.cfg().assay.fee)
	var no_adv := w.contracts.evaluate(m, World.PLAYER, "", 2, 50, 4, svc, {"pay": "on_result"})
	check(str(no_adv.answer) == "reject", "with no coins to spare for the fees, it cannot take the survey (\"%s\")" % str(no_adv.say))
	var terms := {"pay": "on_result", "advance": {"amount": 2 * fee, "purpose": "assay_fee"}}
	var ev := w.contracts.evaluate(m, World.PLAYER, "", 2, 1, 4, svc, terms)
	check(str(ev.answer) == "counter" and int(ev.price_each) >= ContractServices.price_needed(int(ev.min_price), terms),
			"paid for results only, the price a unit is countered up for the risk (%d)" % int(ev.price_each))
	var price := int(ev.price_each)
	var c0 := coins(w)
	var r := w.contracts.propose(World.PLAYER, m, "", 2, price, 4, [], svc, terms)
	check(r.has("contract"), "with the fees advanced it agrees (\"%s\")" % str(r.get("say", "")))
	if not r.has("contract"):
		return
	var c: Dictionary = r.contract
	check(int(c.reserved) == 2 * price + 2 * fee and int(c.advance) == 2 * fee, "the price of every unit and the advance are set aside")
	var mc0 := m.coins
	run(w, m)
	var found := 0
	for rec in w.prospecting.records:
		if (c.sids as Array).has(int(rec.sample)) and str(rec.ore) != "":
			found += 1
	check(int(c.delivered) == 2 and str(c.state) == "fulfilled", "two readings told (%d)" % int(c.delivered))
	check(int(c.get("advance_spent", 0)) == 2 * fee and (c.history as Array).filter(func(h): return str(h.what) == "advance").size() == 2,
			"the advance met the two assay fees, each on the record (auditable)")
	check(int(c.paid) == found * price and int(c.results) == found, "paid only for the readings that showed ore (%d of 2)" % found)
	check(m.coins == mc0 + found * price, "the seller is left with its pay only: the fees came from the advance, not its purse")
	check(int(c.reserved) == 0 and int(c.advance) == 0, "the rest came back to the buyer")
	check(coins(w) == c0, "coins only moved (%d)" % (coins(w) - c0))


## CON-04 base and bonus with CON-05 retention: the bonus only for a dig that brings stone, a quarter of each payment held until the
## work is complete, then released; coins conserved throughout.
func test_base_bonus_and_retention() -> void:
	var w := new_world()
	var p := player_pit(w)
	var m := miner(w)
	w.player.coins = 1000
	w.player.home = home(w)
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	var price := ceili(ContractServices.going(svc)) + 3
	var terms := {"pay": "base_bonus", "bonus_each": 2, "retain": 0.25}
	var c0 := coins(w)
	var r := w.contracts.propose(World.PLAYER, m, "", 3, price, 4, [], svc, terms)
	check(r.has("contract"), "a dig with a base, a bonus and a retention is agreed (\"%s\")" % str(r.get("say", "")))
	if not r.has("contract"):
		return
	var c: Dictionary = r.contract
	check(int(c.reserved) == 3 * (price + 2), "the most it could pay is set aside")
	var mc0 := m.coins
	var held_max := 0
	for i in 80:
		m.plan = []
		if not w.contracts.plan(m):
			break
		for st in m.plan.duplicate():
			if str(st.k) == "go":
				m.pos = Vector2(st.to) + Vector2(0.5, 0.5)
			elif st.has("act"):
				w.brain.act(m, str(st.act), st.get("args", {}))
		held_max = maxi(held_max, int(c.get("retained", 0)))
		if coins(w) != c0:
			check(false, "coins conserved at every step (step %d)" % i)
	check(str(c.state) == "fulfilled" and int(c.delivered) == 3, "the work is done")
	check(held_max > 0, "a share was held back while the work went on (%d)" % held_max)
	var due := 3 * price + int(c.results) * 2
	check(int(c.paid) == due and m.coins == mc0 + due and int(c.retained) == 0, "on completion the retention is released: paid %d of %d" % [int(c.paid), due])
	check((c.history as Array).any(func(h): return str(h.what) == "release"), "the release is on the record")
	check(coins(w) == c0, "coins only moved")


## CON-05: a retention left when a contract ends early is ruled on by the reeve, on the agreement and the records: either side may
## prevail; brought by a party or, after dispute_days, ruled on at dawn all the same.
func test_disputes() -> void:
	for case in ["buyer_cancels", "seller_cancels", "dawn"]:
		var w := new_world()
		var p := player_pit(w)
		var m := miner(w)
		w.player.coins = 1000
		w.player.home = home(w)
		var svc := {"service": "dig", "site": {"pit": int(p.id)}}
		var price := ceili(ContractServices.going(svc)) + 3
		var r := w.contracts.propose(World.PLAYER, m, "", 6, price, 4, [], svc, {"retain": 0.5})
		if not r.has("contract"):
			check(false, "contract for %s (\"%s\")" % [case, str(r.get("say", ""))])
			continue
		var c: Dictionary = r.contract
		var c0 := coins(w)
		for i in 6:                                 # two units dug
			m.plan = []
			if not w.contracts.plan(m) or int(c.delivered) >= 2:
				break
			for st in m.plan.duplicate():
				if str(st.k) == "go":
					m.pos = Vector2(st.to) + Vector2(0.5, 0.5)
				elif st.has("act"):
					w.brain.act(m, str(st.act), st.get("args", {}))
		var kept := int(c.retained)
		var mc := m.coins
		w.contracts.cancel(c, World.PLAYER if case != "seller_cancels" else World.npc_ref(m.id))
		var pc := w.player.coins
		check(Contracts.in_dispute(c) and int(c.reserved) == kept and kept > 0, "%s: the %d coins held back stay held, in dispute" % [case, kept])
		check(coins(w) == c0, "%s: coins conserved while in dispute" % case)
		if case == "dawn":
			w.minutes += float(int(ContractServices.cfg().dispute_days)) * World.DAY
			w.contracts.dawn()
			check(not Contracts.in_dispute(c) and m.coins == mc + kept, "after dispute_days the reeve rules all the same: the buyer ended it, so the worker prevails")
		else:
			var said := w.contracts.dispute(c, World.PLAYER)
			check(said.begins_with("The reeve rules"), "%s: the player brings it before the reeve (\"%s\")" % [case, said])
			if case == "buyer_cancels":
				check(m.coins == mc + kept and str(c.dispute.to) == World.npc_ref(m.id), "the buyer ended it with the work done to the agreement: the worker prevails")
			else:
				check(w.player.coins == pc + kept and str(c.dispute.to) == World.PLAYER, "the worker gave it up unfinished: the buyer prevails")
		check(int(c.reserved) == 0 and coins(w) == c0, "%s: nothing confiscated, coins only moved" % case)
		check(w.contracts.dispute(c, World.PLAYER) != "" and not Contracts.in_dispute(c), "%s: ruled once only" % case)


## CON-06 and CON-07: a household whose members cannot cut its ripe field hires a villager of another household; the crop goes into
## its pantry, never the worker's pack; the worker is paid each cell and the work trains Farming.
func test_harvest_hired_by_household() -> void:
	var w := new_world()
	var f := household_field(w, 6)
	check(not f.is_empty(), "a household with a field of 6 ripe cells")
	if f.is_empty():
		return
	var h := int(f.h)
	var b: NPC = f.b
	for o: NPC in w.brain._members(h):
		o.hp = o.max_hp * 0.1                       # every member too hurt to work the field (FarmPlots.able)
	b.coins = w.reserve_of(b) + 200
	var pantry: Inventory = w.households[h].pantry
	var wheat0 := pantry.count("wheat")
	var c0 := coins(w)
	var g0 := Census.goods(w)
	ContractServices.npc_hire(w.contracts)
	var c := contract_of(w, "harvest")
	check(not c.is_empty() and str(c.buyer) == World.npc_ref(b.id) and str(c.state) in ["accepted", "signing"],
			"the household's first adult hires help to cut it (%s)" % str(c.get("state", "none")))
	if c.is_empty() or not Contracts.is_open(c):
		return
	check(int(c.qty) == 6, "for the cells its own hands cannot cut")
	var s: NPC = w.contracts._npc_of(str(c.seller))
	check(s.household != h, "a villager of another household")
	var sc0 := s.coins
	var sw0 := s.inv.count("wheat")
	var fxp0 := int(s.skills.get("farming", 0))
	run(w, s)
	check(str(c.state) == "fulfilled" and int(c.delivered) == 6, "the field is cut (%d cells)" % int(c.delivered))
	check(pantry.count("wheat") == wheat0 + 18 and s.inv.count("wheat") == sw0, "the crop is the owner's: into the household's pantry, none in the worker's pack")
	check(s.coins == sc0 + int(c.paid) and int(c.paid) == 6 * int(c.price_each), "the worker is paid each cell")
	check(int(s.skills.get("farming", 0)) > fxp0, "the work trains Farming")
	check(coins(w) == c0, "coins only moved")
	var g1 := Census.goods(w)
	check(int(g1.get("wheat", 0)) - int(g0.get("wheat", 0)) == int(w.stats.get("farm_harvest_wheat", 0)), "the only new wheat is the harvest itself")


func test_harvest_own_hands() -> void:
	var w := new_world()
	var f := household_field(w, 6)
	if f.is_empty():
		check(false, "a household field")
		return
	var b: NPC = f.b
	b.coins = w.reserve_of(b) + 200
	var own0 := float(w.stats.get("service_hire_own_hands", 0))
	ContractServices.npc_hire(w.contracts)
	check(contract_of(w, "harvest").is_empty() and float(w.stats.get("service_hire_own_hands", 0)) > own0,
			"a household able to cut its own field hires nobody (no fabricated demand)")


## The player as the hired hand (Decision 2 (7), equivalent rules): a household's offer, taken up; the farm target on its ripe cells
## cuts them into the household's pantry and pays the player.
func test_harvest_player_as_hand() -> void:
	var w := new_world()
	var f := household_field(w, 2)
	if f.is_empty():
		check(false, "a household field")
		return
	var b: NPC = f.b
	b.coins = w.reserve_of(b) + 100
	var p: Dictionary = f.plot
	var svc := {"service": "harvest", "site": {"plot": str(p.id)}}
	var o := w.contracts.offer_to_player(b, "", 2, 1, 2, svc)
	check(w.contracts.accept_offer(o) == "", "the player takes up the household's offer")
	var cells := ContractServices.ripe_cells(w.contracts, World.npc_ref(b.id), str(p.id))
	var pantry: Inventory = w.households[int(f.h)].pantry
	var wheat0 := pantry.count("wheat")
	var pw0 := w.player.inv.count("wheat")
	var pc0 := w.player.coins
	var xp0 := int(w.player.skills.get("farming", 0))
	for cell: Vector2i in cells:
		var ts: Array = w.farm.targets_at(cell, w.player)
		check(not ts.is_empty() and str(ts[0].act) == "contract_harvest", "the ripe cell offers the hired harvest")
		var pl: Dictionary = w.farm.plan(ts[0], w.player)
		check(bool(pl.ok), "as a timed action")
		pl.run.call()
	check(str(o.state) == "fulfilled" and w.player.coins == pc0 + 2, "both cells cut and paid")
	check(pantry.count("wheat") == wheat0 + 6 and w.player.inv.count("wheat") == pw0, "the crop went to the household, not the player")
	check(int(w.player.skills.get("farming", 0)) > xp0, "the player earns the Farming the work trains")
	var other: Vector2i = cells[0]
	check(w.farm.targets_at(other, w.player).all(func(t): return str(t.get("act", "")) != "contract_harvest"), "with the contract done, nothing more to cut")


## The player as employer: a villager cuts the player's own field (Farming's cells on ground the player holds) into their chest.
func test_harvest_player_as_employer() -> void:
	var w := new_world()
	var fp: FarmPlots = w.farm_plots
	w.player.coins = 200
	w.player.home = home(w)
	var sp = w.map.data.spawns.player
	var r: Rect2i = fp.find_ground(Vector2i(4, 4), Vector2i(int(sp[0]), int(sp[1])), 0)
	var p := fp.claim(r, World.PLAYER, true)
	check(not p.is_empty(), "the player leases a field")
	if p.is_empty():
		return
	w.player.home = home(w)                        # (the land office re-reads the player's home on a claim)
	var cs := [r.position + Vector2i(1, 1), r.position + Vector2i(2, 1)]
	for c: Vector2i in cs:
		w.farm.cells[c] = {"crop": "wheat", "state": "ripe", "progress": 1.0}
	var s: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "farmer":
			s = o
			break
	var svc := {"service": "harvest", "site": {"plot": str(p.id)}}
	check(ContractServices.options(w.contracts, World.PLAYER).any(func(x): return str(x.service) == "harvest"), "the talk window offers to have the field harvested")
	var chest0 := w.player.chest.count("wheat")
	var sw0 := s.inv.count("wheat")
	var c0 := coins(w)
	var rr := w.contracts.propose(World.PLAYER, s, "", 2, 2, 3, [], svc)
	if str(rr.get("answer", "")) == "counter":
		rr = w.contracts.propose(World.PLAYER, s, "", int(rr.qty), int(rr.price_each), int(rr.days), rr.history, svc)
	check(rr.has("contract"), "a villager agrees to cut it (\"%s\")" % str(rr.get("say", "")))
	if not rr.has("contract"):
		return
	run(w, s)
	check(str(rr.contract.state) == "fulfilled" and w.player.chest.count("wheat") == chest0 + 6 and s.inv.count("wheat") == sw0,
			"the crop is brought into the player's chest, not kept by the worker (%s, %d done, chest %d)" % [str(rr.contract.state), int(rr.contract.delivered), w.player.chest.count("wheat") - chest0])
	check(coins(w) == c0, "coins only moved")
	w.player.home = ""
	check(ContractServices.site_refusal(w.contracts, World.PLAYER, svc) != "", "with no home there is nowhere for a hired hand to bring the crop")


## CON-08: the services' own signing line, null until the owner sets it (the 50-coin goods line meanwhile), then independent.
func test_signing_line() -> void:
	var cfg: Dictionary = ContractServices.cfg()
	var dig := {"service": "dig", "site": {"pit": 0}}
	check(cfg.get("formal_total", 0) == null, "the services' line is unset until the owner names it")
	check(Contracts.formal_of(50, dig) and not Contracts.formal_of(49, dig), "meanwhile the 50-coin line applies to services too")
	cfg.formal_total = 100
	check(not Contracts.formal_of(60, dig) and Contracts.formal_of(100, dig) and Contracts.formal(60), "set, it is the services' own, the goods line unchanged")
	cfg.formal_total = null


## New keys saved and loaded; a record from an older save (no terms beyond CON-02's, no retention or advance) loads as paid for the
## work done.
func test_save_load() -> void:
	var w := new_world()
	var p := player_pit(w)
	var m := miner(w)
	w.player.coins = 1000
	w.player.home = home(w)
	var svc := {"service": "dig", "site": {"pit": int(p.id)}}
	var r := w.contracts.propose(World.PLAYER, m, "", 4, ceili(ContractServices.going(svc)) + 3, 4, [], svc, {"pay": "base_bonus", "bonus_each": 1, "retain": 0.25})
	if not r.has("contract"):
		check(false, "a contract to save")
		return
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.contracts.to_dict()))
	var k2 := Contracts.new(w)
	k2.load_dict(d)
	var c2: Dictionary = k2.get_contract(int(r.contract.id))
	check(str(c2.terms.pay) == "base_bonus" and int(c2.terms.bonus_each) == 1 and is_equal_approx(float(c2.terms.retain), 0.25) and c2.retained is int,
			"the terms and retention come back typed")
	var old := d.duplicate(true)
	for c in old.list:
		c.terms = {"pay": "on_delivery", "partial": true, "all_at_once": false, "deposit": 0}
		for key in ["retained", "advance", "results"]:
			c.erase(key)
	var k3 := Contracts.new(w)
	k3.load_dict(old)
	var c3: Dictionary = k3.get_contract(int(r.contract.id))
	check(int(c3.retained) == 0 and int(c3.advance) == 0 and ContractServices.pay_for(c3, 2, 0) == 2 * int(c3.price_each), "an older record loads paid for the work done")


func test_determinism() -> void:
	var out := []
	for i in 2:
		var w := new_world(7)
		var f := household_field(w, 5)
		if f.is_empty():
			check(false, "a household field")
			return
		for o: NPC in w.brain._members(int(f.h)):
			o.hp = o.max_hp * 0.1
		(f.b as NPC).coins = w.reserve_of(f.b) + 200
		ContractServices.npc_hire(w.contracts)
		var c := contract_of(w, "harvest")
		if not c.is_empty() and Contracts.is_open(c):
			run(w, w.contracts._npc_of(str(c.seller)))
		out.append(JSON.stringify(w.contracts.to_dict()))
	check(out[0] == out[1], "two runs of one seed hire and cut alike")
