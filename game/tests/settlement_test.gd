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
		"stock": {"hammer": 1, "axe": 1}, "structures": {"anvil": 1, "forge": 1, "sawhorse": 1},
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


## The mining dimension comes only through the adapter (MIN-D is not final and not on this branch).
func test_mining_adapter() -> void:
	var fx := MiningCapabilityAdapter.fixture({"pit_town": {"level": 3, "portals": [-1], "records": {"discovery": 2}}})
	check(fx.capability("pit_town").level == 3 and fx.capability("pit_town").provisional, "a fixture gives its mining level, marked provisional")
	check(fx.capability("elsewhere").level == 0, "a settlement the fixture does not know has mining 0")
	check(fx.portals("pit_town") == [-1] and int(fx.records("pit_town").discovery) == 2, "and its portals and discovery records")
	check(MiningCapabilityAdapter.fixture({"x": {"level": 9}}).capability("x").level == 4, "a level is clamped to 0..4")
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var live := MiningCapabilityAdapter.live(w)
	var c := live.capability(SettlementFacts.VILLAGE)
	check(c.level == 0 and c.source == "unavailable", "on this branch (no MIN-D) the live adapter reports mining unavailable, level 0, invents nothing")
	var f := SettlementFacts.from_world(w, live)
	var before: int = SettlementIndustries.levels(f).mining
	for d in w.deposits:
		d.amount = 0                          # every seam worked out: the settlement model must not notice by itself
	check(SettlementIndustries.levels(SettlementFacts.from_world(w, live)).mining == before,
		"the settlement model never reads deposits: emptying the seams changes no mining level by itself")
	var fake := FakeMinD.new()
	var through := MiningCapabilityAdapter.live(fake)
	check(through.capability("village").level == 2 and through.capability("village").source == "min-d",
		"when a World offers mining_capability (MIN-D's provisional hook) the adapter reads it")


class FakeMinD:
	extends RefCounted
	func mining_capability(_id: String) -> Dictionary:
		return {"level": 2, "since_day": 5}


## Spec s.3 and s.11: a small mining village can outclass a larger farming town in mining; profiles differ.
func test_specialization() -> void:
	var small := {"id": "hollow", "population": 12,
		"practitioners": [{"job": "miner", "skills": {"mining": 5}}, {"job": "smith", "skills": {"smithing": 3}}],
		"stock": {"hammer": 1, "pickaxe": 3}, "structures": {"anvil": 1, "forge": 1},
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
