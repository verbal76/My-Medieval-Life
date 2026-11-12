extends SceneTree
## MML-INV-02, food spoilage by storage condition (owner 2026-11-10, docs/directives/2026-11-10_blocked_decisions_wp1.md: F1(b),
## F2(b), F3(b), F4(a), F5(b), F6(b); off by default until full validation; docs/design/INV02_SPOILAGE_PROPOSAL.md). Checks, with
## the switch on (Decay.storage_on) and off (balance.json decay.storage.enabled, false as shipped):
##   - the shipped switch is off, and off nothing new spoils (stash, homestead chest, trough, courier care, settlements) and the
##     eating order is today's;
##   - each storage class's multiplier on a known stack, holder by holder (packs carried, pantries home, granary cellar, tables
##     open, the stash home and a barrel cellar, homestead chests home, troughs open);
##   - the off-map settlements' food spoils into the audited `spoiled` flow (OffMapSettlement.audit, Regions.audit), saved;
##   - food in courier care: booths at the home rate, loads on the road carried; the sender bears it (no refund, the payment asked
##     scaled to what arrives); the booth's store stays its deposits plus the loads waiting there;
##   - an away guest's pack and chest keep; an active guest's spoil;
##   - villagers eat their most perishable food first;
##   - conservation: every unit lost from the village census is counted spoiled_<item>;
##   - determinism: two worlds of the same seed spoil alike; save/load in the middle spoils on as the unsaved world.
##   godot --headless --path game --script res://tests/inv02_spoilage_test.gd
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func census(w: World, id: String) -> int:
	return int(SettlementHoldings.goods(w).get(id, 0))


## True when `lost` is what the rule takes from `c0` units at `r` x `m` a day: the whole part, or one more.
func rule_loss(lost: int, c0: int, r: float, m: float) -> bool:
	var q := float(c0) * r * m
	return lost == floori(q) or lost == floori(q) + 1


func world(on: bool, seed := 4242) -> World:
	Decay.storage_on = on
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func barrel_id(w: World) -> String:
	for c in w.containers:
		if str(c.kind) == "barrel":
			return str(c.id)
	return ""


func table(w: World) -> Dictionary:
	for c in w.containers:
		if str(c.kind) == "table" and c.has("inv"):
			return c
	return {}


func first_pen(w: World) -> String:
	var ids: Array = w.fauna.pens.keys()
	ids.sort()
	return str(ids[0]) if not ids.is_empty() else ""


## Food put in every holder the switch concerns (the same in every world it is called on).
func stock(w: World) -> void:
	w.chests.stash["inv02_chest"] = Inventory.new()
	w.chests.stash["inv02_chest"].add("milk", 1000)
	var b := barrel_id(w)
	if b != "":
		w.chests.stash[b] = Inventory.new()
		w.chests.stash[b].add("milk", 1000)
	if w.homesteads != null and not w.homesteads.claims.is_empty():
		(w.homesteads.claims[0].store as Inventory).add("milk", 1000)
	var pen := first_pen(w)
	if pen != "":
		w.fauna.pens[pen].trough = 1000
	w.granary.add("milk", 1000)
	w.households[0].pantry.add("milk", 1000)
	w.npcs[0].inv.add("milk", 1000)
	var t := table(w)
	if not t.is_empty():
		(t.inv as Inventory).add("milk", 1000)


## A deposit, a load waiting at a booth and a load on the road, all milk, at the first booth; returns [booth, waiting, on road].
func courier_stock(w: World) -> Array:
	var cs := w.couriers
	var b: Dictionary = cs.booths[0]
	var sender := "npc:%d" % w.npcs[1].id
	(b.store as Inventory).add("milk", 1000)
	b.deposits[sender] = {"coins": 0, "items": {"milk": 1000}}
	var order := {"kind": "route", "sender": sender, "recipient": "npc:%d" % w.npcs[2].id, "items": {"milk": 500},
		"collect": {"kind": "coins", "amount": 100}}
	var waiting := cs._job(order, {"fee": 0, "days": 1.0}, "npc:%d" % w.npcs[3].id)
	waiting.state = "at_booth"
	waiting.booth = str(b.id)
	(b.store as Inventory).add("milk", 500)
	var road := cs._job(order, {"fee": 0, "days": 1.0}, "npc:%d" % w.npcs[3].id)
	road.state = "in_transit"
	road.cargo = {"milk": 500}
	return [b, waiting, road]


func booth_balanced(b: Dictionary, w: World) -> bool:
	var want := {}
	for who in b.deposits:
		for id in b.deposits[who].items:
			want[id] = int(want.get(id, 0)) + int(b.deposits[who].items[id])
	for j in w.couriers.jobs:
		if str(j.state) == "at_booth" and str(j.booth) == str(b.id):
			for id in j.items:
				want[id] = int(want.get(id, 0)) + int(j.items[id])
	return int(want.get("milk", 0)) == (b.store as Inventory).count("milk")


func _init() -> void:
	GameData.ensure()
	Decay.storage_on = false
	check(not bool(GameData.b("decay").storage.enabled) and not Decay.on(), "the shipped switch is off (balance.json decay.storage.enabled)")
	test_off()
	test_classes()
	test_settlements()
	test_couriers()
	test_away_guest()
	test_eat_order()
	test_determinism_and_save()
	Decay.storage_on = false
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


func test_off() -> void:
	var w := world(false)
	stock(w)
	var parts := courier_stock(w)
	var pen := first_pen(w)
	var t := table(w)
	var t0: int = (t.inv as Inventory).count("milk")
	Decay.dawn(w)
	check(int(w.chests.stash["inv02_chest"].count("milk")) == 1000, "off: a stash does not spoil (today's rule)")
	check(w.homesteads.claims.is_empty() or (w.homesteads.claims[0].store as Inventory).count("milk") == 1000, "off: a homestead chest does not spoil")
	check(pen == "" or int(w.fauna.pens[pen].trough) == 1000, "off: a trough does not spoil")
	check(int(parts[0].deposits.values()[0].items.milk) == 1000 and int(parts[1].items.milk) == 500 and int(parts[2].cargo.milk) == 500,
		"off: food in courier care does not spoil")
	check(rule_loss(t0 - (t.inv as Inventory).count("milk"), t0, 0.1, 1.0), "off: a table spoils at the base rate (no class)")
	check(not w.stats.has("inv02_spoiled_tables"), "off: no INV-02 diagnostics are counted")
	var s: OffMapSettlement = w.regions.list[0]
	s.step_day(s.day + 1)
	check(not s.flows.has("spoiled"), "off: a settlement keeps no spoiled flow (its books are as before)")
	check(Decay.eat_order(NPCBrain.EDIBLE) == NPCBrain.EDIBLE, "off: the eating order is today's (NPCBrain.EDIBLE)")
	w.dispose()


func test_classes() -> void:
	var w := world(true)
	check(Decay.smul("open") == 1.5 and Decay.smul("carried") == 1.0 and Decay.smul("home") == 1.0 and Decay.smul("cellar") == 0.5,
		"on: the classes are open 1.5, carried 1.0, home 1.0, cellar 0.5 (F1(b))")
	stock(w)
	var b := barrel_id(w)
	var pen := first_pen(w)
	var t := table(w)
	var before := {"pack": w.npcs[0].inv.count("milk"), "pantry": w.households[0].pantry.count("milk"), "granary": w.granary.count("milk"),
		"table": (t.inv as Inventory).count("milk"), "trough": int(w.fauna.pens[pen].trough)}
	var g0 := census(w, "milk") + census(w, "wheat")
	var s0 := float(w.stats.get("spoiled_milk", 0.0)) + float(w.stats.get("spoiled_wheat", 0.0))
	Decay.dawn(w)
	check(rule_loss(int(before.pack) - w.npcs[0].inv.count("milk"), int(before.pack), 0.1, 1.0), "a villager's pack spoils at the carried rate")
	check(rule_loss(int(before.pantry) - w.households[0].pantry.count("milk"), int(before.pantry), 0.1, 1.0), "a pantry spoils at the home rate")
	check(rule_loss(int(before.granary) - w.granary.count("milk"), int(before.granary), 0.1, 0.5), "the granary keeps at the cellar rate")
	check(rule_loss(int(before.table) - (t.inv as Inventory).count("milk"), int(before.table), 0.1, 1.5), "a table spoils at the open rate")
	check(rule_loss(1000 - int(w.chests.stash["inv02_chest"].count("milk")), 1000, 0.1, 1.0), "a chest in the stash spoils at the home rate")
	check(b != "" and rule_loss(1000 - int(w.chests.stash[b].count("milk")), 1000, 0.1, 0.5), "a barrel keeps at the cellar rate")
	check(not w.homesteads.claims.is_empty() and rule_loss(1000 - (w.homesteads.claims[0].store as Inventory).count("milk"), 1000, 0.1, 1.0),
		"a homestead chest spoils at the home rate")
	check(rule_loss(int(before.trough) - int(w.fauna.pens[pen].trough), int(before.trough), 0.004, 1.5), "a trough's wheat spoils at the open rate")
	var lost := g0 - census(w, "milk") - census(w, "wheat")
	var counted := int(float(w.stats.get("spoiled_milk", 0.0)) + float(w.stats.get("spoiled_wheat", 0.0)) - s0)
	check(lost > 0 and lost == counted, "conservation: every unit gone from the village census is counted spoiled_ (%d lost, %d counted)" % [lost, counted])
	check(w.stats.has("inv02_spoiled_stash") and w.stats.has("inv02_spoiled_troughs"), "on: the per-holder diagnostics are counted")
	w.dispose()


func test_settlements() -> void:
	var w := world(true)
	var s: OffMapSettlement = w.regions.list[0]
	check(s.audit() == "", "a settlement's books balance before")
	var h: Dictionary = {}
	for x in s.hh:
		if bool(x.alive):
			h = x
			break
	var p0 := int(h.pantry.get("milk", 0)) + 1000
	var g0 := int(s.gov.granary.get("milk", 0)) + 1000
	OffMapSettlement._add(h.pantry, "milk", 1000)
	OffMapSettlement._add(s.gov.granary, "milk", 1000)
	OffMapSettlement._add(s.flows.produced, "milk", 2000)        # the test's own milk, booked as made so the books still balance
	var goods0 := int(s.goods().get("milk", 0))
	s._spoil()
	var pl := p0 - int(h.pantry.get("milk", 0))
	var gl := g0 - int(s.gov.granary.get("milk", 0))
	check(rule_loss(pl, p0, 0.1, 1.0), "a settlement's pantry spoils at the home rate (%d of %d)" % [pl, p0])
	check(rule_loss(gl, g0, 0.1, 0.5), "a settlement's granary keeps at the cellar rate (%d of %d)" % [gl, g0])
	var booked := int(s.flows.get("spoiled", {}).get("milk", 0))
	check(booked == goods0 - int(s.goods().get("milk", 0)), "every unit a settlement lost is in its spoiled flow (%d)" % booked)
	check(s.audit() == "", "the settlement's audit balances with the spoiled flow (%s)" % s.audit())
	check(w.regions.audit() == "", "Regions.audit balances (%s)" % w.regions.audit())
	var back := OffMapSettlement.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	check(int(back.flows.get("spoiled", {}).get("milk", -1)) == booked and back.audit() == "", "the spoiled flow is saved and a loaded settlement's audit balances")
	var d1 := s.day + 1
	s.step_day(d1)
	check(s.audit() == "" and int(s.flows.spoiled.get("milk", 0)) > booked, "a settlement's own day spoils its food, audited")
	w.dispose()


func test_couriers() -> void:
	var w := world(true)
	var parts := courier_stock(w)
	var b: Dictionary = parts[0]
	var waiting: Dictionary = parts[1]
	var road: Dictionary = parts[2]
	var sender := str(road.sender)
	var coins0: int = w.couriers.coins_of(sender)
	check(booth_balanced(b, w), "fixture: the booth's store is its deposits plus the loads waiting there")
	var g0 := census(w, "milk")
	var s0 := float(w.stats.get("spoiled_milk", 0.0))
	var lost: int = w.couriers.spoil_day(w, Decay.smul("home"), Decay.smul("carried"))
	var dep := int(b.deposits[sender].items.milk)
	check(rule_loss(1000 - dep, 1000, 0.1, 1.0), "a deposit at a booth spoils at the home rate (%d left)" % dep)
	check(rule_loss(500 - int(waiting.items.milk), 500, 0.1, 1.0), "a load waiting at a booth spoils at the home rate")
	check(rule_loss(500 - int(road.cargo.milk), 500, 0.1, 1.0), "a load on the road spoils at the carried rate")
	check(int(road.items.milk) == int(road.cargo.milk), "the delivery's line follows its load (what is left is what is delivered)")
	check(booth_balanced(b, w), "the booth's store is still its deposits plus the loads waiting there")
	check(g0 - census(w, "milk") == lost and int(float(w.stats.get("spoiled_milk", 0.0)) - s0) == lost,
		"every unit lost in courier care is counted spoiled_milk (%d)" % lost)
	check(w.couriers.coins_of(sender) == coins0, "the sender bears the loss: nothing is refunded")
	var left := int(road.items.milk)
	w.couriers._spoiled_terms(road, 1.0)
	check(int(road.collect.amount) == 100 * left / 500, "the payment asked on arrival is scaled to what arrives (%d of 100)" % int(road.collect.amount))
	w.couriers._spoiled_terms(road, 1.0)
	check(int(road.collect.amount) == 100 * left / 500, "and scaled once only")
	var back := CourierService.from_dict(w, JSON.parse_string(JSON.stringify(w.couriers.to_dict())))
	var rj: Dictionary = {}
	for j in back.jobs:
		if str(j.id) == str(road.id):
			rj = j
	check(not rj.is_empty() and int(rj.spoiled.milk) == int(road.spoiled.milk), "what spoiled in the courier's care is saved with the delivery")
	w.dispose()


func test_away_guest() -> void:
	var w := world(true)
	var gu := PlayerState.new()
	gu.name = "Gwen"
	Identity.register_player(w, gu)
	check(w.add_guest(gu), "fixture: a guest joins")
	gu.inv.add("milk", 1000)
	gu.chest.add("milk", 1000)
	gu.away = true
	Decay.dawn(w)
	check(gu.inv.count("milk") == 1000 and gu.chest.count("milk") == 1000, "on: an away guest's pack and chest keep (F5(b))")
	gu.away = false
	Decay.dawn(w)
	check(gu.inv.count("milk") < 1000 and gu.chest.count("milk") < 1000, "on: an active guest's pack and chest spoil")
	w.dispose()
	var off := world(false)
	var g2 := PlayerState.new()
	g2.name = "Gwen"
	Identity.register_player(off, g2)
	off.add_guest(g2)
	g2.inv.add("milk", 1000)
	g2.away = true
	Decay.dawn(off)
	check(g2.inv.count("milk") < 1000, "off: an away guest's pack spoils as today")
	off.dispose()


func test_eat_order() -> void:
	Decay.storage_on = true
	var order := Decay.eat_order(NPCBrain.EDIBLE)
	check(order[0] == "milk" and order[order.size() - 1] == "wheat", "on: the most perishable first (milk), grain last (%s)" % str(order))
	for which in [true, false]:
		var w := world(which)
		var n: NPC = w.npcs[0]
		for f in NPCBrain.EDIBLE:
			n.inv.remove(f, n.inv.count(f))
		n.inv.add("cheese", 1)
		n.inv.add("milk", 1)
		n.hunger = 10.0
		w.brain.act(n, "eat", {})
		if which:
			check(n.inv.count("milk") == 0 and n.inv.count("cheese") == 1, "on: a villager eats the milk before the cheese (F6(b))")
		else:
			check(n.inv.count("cheese") == 0 and n.inv.count("milk") == 1, "off: a villager eats in today's order (cheese first)")
		w.dispose()


func spoil_day(w: World) -> void:
	w.minutes += World.DAY
	Decay.dawn(w)
	for s: OffMapSettlement in w.regions.list:
		s.day += 1
		s._spoil()


func fingerprint(w: World) -> String:
	var regions := {}
	for s: OffMapSettlement in w.regions.list:
		regions[s.id] = [s.goods(), s.flows.get("spoiled", {})]
	var deps := []
	for b in w.couriers.booths:
		deps.append([b.id, b.deposits, (b.store as Inventory).to_dict()])
	var claims := []
	for c in w.homesteads.claims:
		claims.append((c.store as Inventory).to_dict())
	var troughs := {}
	for id in w.fauna.pens:
		troughs[str(id)] = int(w.fauna.pens[id].trough)
	return JSON.stringify([SettlementHoldings.goods(w), regions, deps, claims, troughs], "", true)     # (stats are a run's, not saved)


func test_determinism_and_save() -> void:
	var a := world(true, 77)
	var b := world(true, 77)
	for w: World in [a, b]:
		stock(w)
		courier_stock(w)
		for s: OffMapSettlement in w.regions.list:
			OffMapSettlement._add(s.gov.granary, "milk", 500)
			OffMapSettlement._add(s.flows.produced, "milk", 500)
	for i in 3:
		spoil_day(a)
		spoil_day(b)
	check(fingerprint(a) == fingerprint(b) and a.stats.get("spoiled_total") == b.stats.get("spoiled_total"),
		"determinism: two worlds of the same seed spoil exactly alike")
	var text := JSON.stringify(a.to_dict(), "", true, true)
	var c := World.new()
	c.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(fingerprint(c) == fingerprint(a), "save/load in the middle: the loaded world holds the same food")
	var sa := float(a.stats.get("spoiled_total", 0.0))
	var sc := float(c.stats.get("spoiled_total", 0.0))
	for i in 3:
		spoil_day(a)
		spoil_day(c)
	check(float(a.stats.spoiled_total) - sa == float(c.stats.spoiled_total) - sc and float(a.stats.spoiled_total) > sa,
		"save/load in the middle: the loaded world counts the same spoilage after loading")
	check(fingerprint(c) == fingerprint(a), "save/load in the middle: the loaded world spoils on exactly as the unsaved one")
	var bad := ""
	for s: OffMapSettlement in c.regions.list:
		bad += s.audit()
	check(bad == "", "the loaded settlements' books still balance (%s)" % bad)
	a.dispose()
	b.dispose()
	c.dispose()
