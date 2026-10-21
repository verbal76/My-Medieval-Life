extends SceneTree
## PROSPECTIVE (Expansion 18, PROS-18; wip/expansion18-preparation): the settlement capability and specialization
## model (SET-B), the provisional mining adapter (MIN-D stand-in), the read-only settlement report and holdings, and
## the provisional save section. Nothing here is live gameplay.
##   godot --headless --path game --script res://tests/settlement_test.gd

const Census := preload("res://tests/census.gd")

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
	test_data()
	test_levels_from_facts()
	test_mining_adapter()
	test_min_d_schema()
	test_specialization()
	test_history()
	test_live_village()
	test_save_section()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------------------ fixtures
func smithy_facts() -> Dictionary:
	return {"id": "forge_town", "population": 30,
		"practitioners": [{"job": "smith", "skills": {"smithing": 4}}, {"job": "carpenter", "skills": {"crafting": 2}},
			{"job": "woodcutter", "skills": {"woodcutting": 2}}],
		"stock": {"hammer": 1, "axe": 1}, "stations": {"anvil": 1, "forge": 1, "sawhorse": 1},
		"transport": {"handcart": 0}, "records": {}, "portals": [],
		"external": {"mining": {"level": 0, "source": "fixture"}}}


func test_data() -> void:
	var d := SettlementIndustries.data()
	check(SettlementIndustries.validate(d).is_empty(), "settlement_industries.json is valid (%s)" % str(SettlementIndustries.validate(d)))
	check(d.industries.mining.has("external") and not d.industries.mining.has("levels"),
		"mining is external: no mining level is defined or computed by the settlement model")
	var order := SettlementIndustries.order(d)
	check(order.find("forestry") < order.find("carpentry") and order.find("carpentry") < order.find("smithing")
		and order.find("mining") < order.find("smithing"), "industries are evaluated after those they need (%s)" % str(order))
	var bad := d.duplicate(true)
	bad.industries.forestry.levels[0].needs.append({"kind": "industry", "id": "carpentry", "min": 1})
	check(SettlementIndustries.validate(bad).has("a cycle among industries' needs"), "a cycle among industries is refused")
	bad = d.duplicate(true)
	bad.industries.trade.levels[0].needs.append({"kind": "magic_points", "n": 3})
	check(not SettlementIndustries.validate(bad).is_empty(), "an unknown need kind is refused")


func test_levels_from_facts() -> void:
	var f := smithy_facts()
	var ev := SettlementIndustries.evaluate(f)
	check(ev.levels.smithing == 1, "a smith, an anvil and a forge make a smithy (smithing 1; got %d)" % ev.levels.smithing)
	check(ev.blocked.smithing.size() > 0, "and what stops toolmaking is named (%s)" % str(ev.blocked.smithing))
	check(ev.levels.carpentry == 1 and ev.levels.forestry == 1, "a carpenter with a sawhorse and a woodcutter with an axe (carpentry 1, forestry 1)")
	# toolmaking needs iron: a mine (mining 1) or iron bars in store
	f.stock.iron_bar = 4
	check(SettlementIndustries.levels(f).smithing == 2, "iron bars in store open toolmaking (smithing 2)")
	f.stock.erase("iron_bar")
	f.external.mining.level = 1
	check(SettlementIndustries.levels(f).smithing == 2, "so does a working mine (mining 1, from the adapter)")
	# the last hammer breaks: toolmaking stops, the smithy stays
	f.stock.erase("hammer")
	check(SettlementIndustries.levels(f).smithing == 1, "without a hammer toolmaking falls back to a smithy")
	f.stock.hammer = 1
	# the smith dies: no smithing at all, whatever the anvil and forge
	f.practitioners = f.practitioners.filter(func(p): return p.job != "smith")
	check(SettlementIndustries.levels(f).smithing == 0, "the loss of the last smith ends smithing (spec s.4: population loss erodes capacity)")
	# a skilled non-smith does not make a smithy: the job is a need of level 1 (a level needs every level below it)
	f.practitioners.append({"job": "laborer", "skills": {"smithing": 9}})
	check(SettlementIndustries.levels(f).smithing == 0, "a skilled laborer without the trade does not open smithing 2 without smithing 1")
	# the forest gone (woodcutter dead): carpentry 1 needs forestry 1
	var g := smithy_facts()
	g.practitioners = g.practitioners.filter(func(p): return p.job != "woodcutter")
	check(SettlementIndustries.levels(g).carpentry == 0, "carpentry needs forestry's output (industry interdependence)")
	# population plays no part: the same facts with 300 people give the same levels
	var h := smithy_facts()
	h.population = 300
	check(SettlementIndustries.levels(h) == SettlementIndustries.levels(smithy_facts()), "levels do not follow population")
	check(SettlementIndustries.levels(smithy_facts()) == SettlementIndustries.levels(smithy_facts()), "the same facts give the same levels")


## The mining dimension comes only through the adapter, mapped to MIN-D's interface (wip/b17-mind b0506db; not on this
## branch, so a fake World stands in for it).
func test_mining_adapter() -> void:
	var fx := MiningCapabilityAdapter.fixture({"pit_town": {"level": 3, "portals": [-1], "records": {"discovery": 2},
		"deposit_access": [0], "local_supply": {"iron_ore": 40}, "unmet": {4: ["timber support"]}}})
	var c0 := fx.capability("pit_town")
	check(c0.level == 3 and c0.provisional and c0.unmet.has(4), "a fixture gives its mining level and what stops the next, marked provisional")
	check(fx.capability("elsewhere").level == 0, "a settlement the fixture does not know has mining 0")
	check(fx.portals("pit_town") == [-1] and int(fx.records("pit_town").discovery) == 2 and fx.deposit_access("pit_town") == [0]
		and int(fx.local_supply("pit_town").iron_ore) == 40, "and its portals, discovery records, deposit access and own ore")
	check(MiningCapabilityAdapter.fixture({"x": {"level": 9}}).capability("x").level == 4, "a level is clamped to 0..4")
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var live := MiningCapabilityAdapter.live(w)
	var c := live.capability(SettlementFacts.VILLAGE)
	check(not live.has_min_d() and c.level == 0 and c.source == "unavailable", "on this branch (no MIN-D) the live adapter reports mining unavailable, level 0, invents nothing")
	check(int(live.local_supply("village").get("iron_ore", 0)) > 0, "the village's own unworked seams count as its ore supply (Build 16 stand-in)")
	var f := SettlementFacts.from_world(w, live)
	var before: int = SettlementIndustries.levels(f).mining
	for d in w.deposits:
		d.amount = 0                          # every seam worked out: the settlement model must not notice by itself
	check(SettlementIndustries.levels(SettlementFacts.from_world(w, live)).mining == before,
		"the settlement model never reads deposits: emptying the seams changes no mining level by itself")
	check(live.local_supply("village").is_empty(), "worked-out seams leave the village no ore of its own")
	# MIN-D's real interface, faked: World.discovery.evaluate/level/history/manor_finds, the reachable seams
	var fake := FakeMinDWorld.new()
	var a := MiningCapabilityAdapter.live(fake)
	var m := a.capability("village")
	check(a.has_min_d() and m.level == 2 and m.last_dawn == 1 and m.source == "min-d",
		"with MIN-D the level is Discovery.evaluate's (2), the last dawn's (1) reported beside it")
	check(m.since_day == 7 and m.history.size() == 1 and m.unmet.has(3), "and its history (changed day 7) and unmet needs come from MIN-D")
	check(a.capability("hollow").source == "unavailable", "MIN-D models the village only: another settlement is unavailable")
	check(int(a.records("village").discovery) == 1 and a.portals("village") == [-1], "records are the manor's finds; portals the underground's")
	check(a.deposit_access("village") == [0] and int(a.local_supply("village").get("iron_ore", 0)) == 30 and not a.local_supply("village").has("coal"),
		"deposit access and the village's own ore count only seams villagers reach (an unreachable coal seam is not counted)")
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 1)
	var lv := SettlementIndustries.levels(SettlementFacts.from_world(w2, a))
	check(lv.mining == 2, "the industry model takes mining from MIN-D through the adapter (2), never re-derives it")
	fake.discovery.lv = 0
	check(a.local_supply("village").is_empty(), "at mining 0 (nobody can dig) the village's seams are not its supply")


## Schema compatibility (evidence for the one-evaluator plan, DESIGN.md section 8): MIN-D's mining block, copied as a
## TEST FIXTURE (tests/fixtures/x18_min_d_mining.json; the live mining level is never computed this way), evaluated by
## SettlementIndustries from facts, gives the levels MIN-D documents (MIN_D_DISCOVERY.md section 2).
func test_min_d_schema() -> void:
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/x18_min_d_mining.json"))
	var d := SettlementIndustries.data().duplicate(true)
	d.industries.mining = fx.industries.mining           # not external: the evaluator reads MIN-D's needs directly
	check(SettlementIndustries.validate(d).is_empty(), "MIN-D's mining needs validate in the settlement schema (%s)" % str(SettlementIndustries.validate(d)))
	var f := {"practitioners": [{"job": "miner", "skills": {"mining": 2}}], "tools": {"pickaxe": 1},
		"transport": {"carry": 1}, "deposit_access": [0], "stations": {}, "records": {}}
	check(SettlementIndustries.levels(f, d).mining == 1, "a miner, a pickaxe, carrying and reachable ore: surface extraction (1)")
	f.practitioners.append({"job": "prospector", "skills": {}})
	f.practitioners.append({"job": "smith", "skills": {"smithing": 1}})
	f.stations.forge = 1
	f.tools.prospecting_kit = 1
	f.records.discovery = 1
	check(SettlementIndustries.levels(f, d).mining == 2, "with a prospector, a smith as assayer, a forge, a kit and a find: prospecting and assay (2)")
	f.practitioners.append({"job": "excavator", "skills": {}})
	f.practitioners.append({"job": "excavator", "skills": {}})
	f.transport.handcart = 1
	f.portals = [-1]
	check(SettlementIndustries.levels(f, d).mining == 2, "no pit ramp or timber support exists: 3 and 4 cannot hold (as MIN-D)")
	f.tools.erase("pickaxe")
	var ev := SettlementIndustries.evaluate(f, d)
	check(ev.levels.mining == 0 and ev.blocked.mining.has("1 pickaxe"), "the last pickaxe gone: 0, with the reason (as MIN-D's regression)")


class FakeDiscovery:
	extends RefCounted
	var lv := 2
	var history := [{"day": 7, "industry": "mining", "from": 0, "to": 1, "why": ""}, {"day": 9, "industry": "smithing", "from": 0, "to": 1, "why": ""}]
	func evaluate(_industry := "mining") -> Dictionary:
		return {"level": lv, "holds": [true, true, false, false], "unmet": {3: ["2 excavators"], 4: ["a way below ground"]}}
	func level(_industry := "mining") -> int:
		return 1
	func manor_finds() -> Array:
		return [{"ore": "iron_ore"}]


class FakeUnderground:
	extends RefCounted
	var portals := [{"ends": [{"level": 0}, {"level": -1}]}]


class FakeMinDWorld:
	extends RefCounted
	var discovery := FakeDiscovery.new()
	var underground := FakeUnderground.new()
	var deposits := [{"x": 1, "y": 1, "ore": "iron_ore", "amount": 30}, {"x": 2, "y": 2, "ore": "coal", "amount": 12, "far": true},
		{"x": 3, "y": 3, "ore": "iron_ore", "amount": 0}]
	func _quarry_sources(ores: Array) -> Array:
		return deposits.filter(func(d): return ores.has(d.ore))
	func villagers_reach(d: Dictionary) -> bool:
		return not d.get("far", false)
	func level_of(_d: Dictionary) -> int:
		return 0


## Spec s.3 and s.11: a small mining village can outclass a larger farming town in mining; profiles differ.
func test_specialization() -> void:
	var small := {"id": "hollow", "population": 12,
		"practitioners": [{"job": "miner", "skills": {"mining": 5}}, {"job": "smith", "skills": {"smithing": 3}}],
		"stock": {"hammer": 1, "pickaxe": 3}, "stations": {"anvil": 1, "forge": 1},
		"external": {"mining": {"level": 3}}}
	var big_prac := []
	for i in 10:
		big_prac.append({"job": "farmer", "skills": {}})
	big_prac.append({"job": "merchant", "skills": {"trading": 4}})
	var big := {"id": "wheatby", "population": 90, "practitioners": big_prac,
		"stock": {"plough": 2}, "structures": {"field": 12, "stall": 3}, "transport": {"handcart": 2},
		"external": {"mining": {"level": 1}}}
	var prof := {"hollow": SettlementIndustries.levels(small), "wheatby": SettlementIndustries.levels(big)}
	check(SettlementIndustries.leader(prof, "mining") == "hollow", "the small mining village leads the region in mining (%s)" % str(prof))
	check(SettlementIndustries.leader(prof, "farming") == "wheatby", "the larger farming town leads in farming")
	var spec := SettlementIndustries.specialization(prof)
	check(str(spec.hollow[0].industry) == "mining" and str(spec.wheatby[0].industry) in ["farming", "trade"],
		"each settlement's specialization is its own (hollow: %s; wheatby: %s)" % [spec.hollow[0].industry, spec.wheatby[0].industry])
	check(prof.hollow != prof.wheatby, "the two settlements have different industry profiles")


func test_history() -> void:
	var st := {}
	var ch := SettlementIndustries.record(st, {"smithing": 1, "trade": 0}, 3)
	check(ch.size() == 1 and int(st.since.smithing) == 3 and int(st.levels.trade) == 0, "a first record notes the levels held, from that day")
	ch = SettlementIndustries.record(st, {"smithing": 1, "trade": 0}, 4)
	check(ch.is_empty(), "nothing changed, nothing recorded")
	ch = SettlementIndustries.record(st, {"smithing": 0, "trade": 0}, 9)
	check(ch.size() == 1 and int(ch[0].from) == 1 and int(ch[0].to) == 0 and int(st.since.smithing) == 9, "a level that falls is recorded (regression)")


## The live village as a settlement: facts, levels, and the report, read without changing anything.
func test_live_village() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var f := SettlementFacts.from_world(w)
	var ev := SettlementIndustries.evaluate(f)
	print("     the village: population %d, levels %s" % [f.population, str(ev.levels)])
	check(f.population == w.alive_count() - w.alive_count("bandit"), "the village's population is its living villagers")
	check(ev.levels.smithing >= 1 and ev.levels.farming >= 1 and ev.levels.trade >= 1 and ev.levels.forestry >= 1,
		"the starting village has a smithy, fields, a market and woodcutters")
	# the report is read-only: the save is byte for byte the same after it
	var before := JSON.stringify(w.to_dict())
	var rep := SettlementReport.village(w)
	check(JSON.stringify(w.to_dict()) == before, "building the report changes nothing in the World")
	check(int(rep.coins_total) == w.total_coins(), "the report's coins by holder add up to World.total_coins (%d)" % w.total_coins())
	check(rep.goods_total == Census.goods(w), "the report's goods are the census's goods (one census)")
	var grouped := {}
	for grp in rep.goods:
		for id in rep.goods[grp]:
			grouped[id] = int(grouped.get(id, 0)) + int(rep.goods[grp][id])
	check(grouped == rep.goods_total, "every good falls in exactly one group (market, private, public, player, loot)")
	check(int(rep.outside.caravan_purse) == w.caravan_purse, "the caravan's purse is reported apart, outside the village")
	# the smiths die: smithing falls; the anvil and forge stay
	for n: NPC in w.npcs:
		if n.job == "smith":
			n.alive = false
	check(SettlementIndustries.levels(SettlementFacts.from_world(w)).smithing == 0, "when the village's smiths die, its smithing falls to 0")
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 1)
	check(JSON.stringify(SettlementFacts.from_world(w2)) == JSON.stringify(SettlementFacts.from_world(_fresh(1))),
		"the same seed gives the same facts (determinism)")


func _fresh(s: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), s)
	return w


func test_save_section() -> void:
	var w := _fresh(2)
	var save := w.to_dict()
	var st := SettlementSave.extract(save)
	check(st.capabilities.is_empty() and st.regions.is_empty() and str(st.format) == SettlementSave.FORMAT,
		"a save without the section (every save before Expansion 18) gives the default settlement state")
	var caps := {}
	SettlementIndustries.record(caps, SettlementIndustries.levels(SettlementFacts.from_world(w)), 0)
	SettlementIndustries.record(caps, {"smithing": 0}, 4)
	st.capabilities["village"] = caps
	var region := SettlementLedger.make({"id": "eastmarch", "pos": [400, 10], "population": 60, "coins": 500,
		"stock": {"wheat": 40, "iron_ore": 12}, "needs": {"bread": 2.0}, "production": {"iron_ore": 1.5}})
	SettlementSave.store_regions(st, [region])
	st.day = 4
	SettlementSave.attach(save, st)
	var text := JSON.stringify(save)
	var back: Dictionary = JSON.parse_string(text)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), back)
	check(w2.total_coins() == w.total_coins() and w2.npcs.size() == w.npcs.size(), "a save carrying the section loads in the live game unchanged")
	var st2 := SettlementSave.extract(back)
	check(JSON.stringify(st2.capabilities) == JSON.stringify(st.capabilities), "the capability history round-trips through JSON")
	var r2: SettlementLedger = SettlementSave.regions(st2)[0]
	check(r2.coins == 500 and r2.stock.count("iron_ore") == 12 and r2.pos == Vector2i(400, 10) and is_equal_approx(float(r2.production.iron_ore), 1.5),
		"an off-map settlement round-trips (coins, stock, place, production)")
	check(int(st2.day) == 4, "and the day")
	back[SettlementSave.KEY].format = "mml-settlements/99"
	check(SettlementSave.extract(back).has("error"), "a section of an unknown format is refused, not reinterpreted")
