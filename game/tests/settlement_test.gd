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
	test_rule_parity()
	test_save_section()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------------------ fixtures
func smithy_facts() -> Dictionary:
	return {"id": "forge_town", "population": 30,
		"practitioners": [{"job": "smith", "skills": {"smithing": 4}, "tools": {"hammer": 1}}, {"job": "carpenter", "skills": {"crafting": 2}},
			{"job": "woodcutter", "skills": {"woodcutting": 2}, "tools": {"axe": 1}}],
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
	# the smith's hammer breaks: nobody has the tool, so nobody practises (Build 17 MIN-SKILLCAP: skill and tool)
	f.practitioners[0].tools = {}
	check(SettlementIndustries.levels(f).smithing == 0, "without a hammer of their own or their household's the smith practises nothing (skill and tool)")
	f.practitioners[0].store = "hh0"
	f.stores = {"hh0": {"hammer": 1}}
	check(SettlementIndustries.levels(f).smithing == 2, "a hammer in the household's store serves them (MIN-SKILLCAP: own pack or shared store)")
	f.practitioners.append({"job": "", "skills": {"smithing": 7}, "store": "hh0"})
	f.practitioners.append({"job": "", "skills": {"smithing": 7}, "store": "hh0"})
	check(SettlementIndustries.practitioner_count({"kind": "practitioners", "skill": "smithing", "min_level": 1, "tool": "hammer"}, f) == 1,
		"one shared hammer serves one practitioner, however many in the household have the skill")
	check(SettlementIndustries.levels(f).smithing == 2, "so two skilled housemates and one hammer are no master smithy (needs 2 with hammers)")
	f.stores.hh0.hammer = 3
	check(SettlementIndustries.levels(f).smithing == 3, "three hammers in the store: two masters practise (smithing 3)")
	f.stores.hh0.hammer = 1
	f.practitioners = f.practitioners.slice(0, 3)
	f.practitioners[0].tools = {"hammer": 1}
	f.erase("stores")
	# the smith dies: no smithing at all, whatever the anvil and forge
	f.practitioners = f.practitioners.filter(func(p): return p.job != "smith")
	check(SettlementIndustries.levels(f).smithing == 0, "the loss of the last smith ends smithing (spec s.4: population loss erodes capacity)")
	# skill and tool, never title (MIN-SKILLCAP): a laborer with the skill and a hammer practises; without the tool not
	f.practitioners.append({"job": "laborer", "skills": {"smithing": 9}})
	check(SettlementIndustries.levels(f).smithing == 0, "a skilled laborer without a hammer does not practise smithing")
	f.practitioners[-1].tools = {"hammer": 1}
	check(SettlementIndustries.levels(f).smithing == 2, "with a hammer the same laborer does: capability by skill and tool, never job title")
	f.practitioners[-1].skills = {}
	check(SettlementIndustries.levels(f).smithing == 1, "with the hammer and no smithing learned they practise at the floor level (Skills level 1)")
	f.practitioners.pop_back()
	# the forest gone (woodcutter dead): carpentry 1 needs forestry 1
	var g := smithy_facts()
	g.practitioners = g.practitioners.filter(func(p): return p.job != "woodcutter")
	check(SettlementIndustries.levels(g).carpentry == 0, "carpentry needs forestry's output (industry interdependence)")
	# population plays no part: the same facts with 300 people give the same levels
	var h := smithy_facts()
	h.population = 300
	check(SettlementIndustries.levels(h) == SettlementIndustries.levels(smithy_facts()), "levels do not follow population")
	check(SettlementIndustries.levels(smithy_facts()) == SettlementIndustries.levels(smithy_facts()), "the same facts give the same levels")


## The mining dimension comes only through the adapter, mapped to MIN-D's interface (Build 17 cd7439c, merged at SYNC-17:
## the live World now carries MIN-D; a fake World still tests the interface's edges).
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
	check(live.has_min_d() and c.source == "min-d" and c.level == int(w.discovery.evaluate("mining").level),
		"the live adapter reads MIN-D: mining level %d, Discovery.evaluate's own" % c.level)
	check(int(live.local_supply("village").get("iron_ore", 0)) > 0, "the village's own reachable seams count as its ore supply")
	for d in w.deposits:
		d.amount = 0                          # every seam worked out
	check(SettlementIndustries.levels(SettlementFacts.from_world(w, live)).mining == int(w.discovery.evaluate("mining").level),
		"the settlement model takes mining from MIN-D whatever happens to the seams: never its own derivation")
	var left := live.local_supply("village")
	left.erase("stone")                       # Build 17 (MIN-B, STONE-01): a worked-out seam's host rock and the boulders stay quarriable
	check(left.is_empty(), "worked-out seams leave the village no ore of its own, only quarry stone (%s)" % str(live.local_supply("village")))
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
	# owner Q18-9: the level never decides it; the real conditions do (reachable ore, an adult with a pickaxe)
	fake.discovery.lv = 0
	check(int(a.local_supply("village").get("iron_ore", 0)) == 30,
		"at mining level 0, with ore within reach, a miner and a pickaxe, the village still counts its own ore (Q18-9: no gate)")
	(fake.npcs[0] as NPC).inv.remove("pickaxe")
	check(a.local_supply("village").is_empty(), "with nobody holding a pickaxe (pack, household or yard) its seams are not its supply")
	fake.manor_work.yard.add("pickaxe")
	check(a.local_supply("village").is_empty(), "a pickaxe in the manor's yard makes nobody a miner (Build 17 MIN-SKILLCAP: one's own pack or household store)")
	(fake.npcs[0] as NPC).inv.add("pickaxe")
	(fake.npcs[0] as NPC).alive = false
	check(a.local_supply("village").is_empty(), "with no living resident nobody can dig, whatever the tools")


## Schema compatibility (evidence for the one-evaluator plan, DESIGN.md section 8): MIN-D's mining block, copied as a
## TEST FIXTURE (tests/fixtures/x18_min_d_mining.json; the live mining level is never computed this way), evaluated by
## SettlementIndustries from facts, gives the levels MIN-D documents (MIN_D_DISCOVERY.md section 2).
func test_min_d_schema() -> void:
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/x18_min_d_mining.json"))
	var d := SettlementIndustries.data().duplicate(true)
	d.industries.mining = fx.industries.mining           # not external: the evaluator reads MIN-D's needs directly
	check(SettlementIndustries.validate(d).is_empty(), "MIN-D's mining needs validate in the settlement schema (%s)" % str(SettlementIndustries.validate(d)))
	var f := {"practitioners": [{"job": "", "skills": {"mining": 2}, "tools": {"pickaxe": 1}}], "tools": {"pickaxe": 1},
		"transport": {"carry": 1}, "deposit_access": [0], "stations": {}, "records": {}}
	check(SettlementIndustries.levels(f, d).mining == 1, "a resident with mining and a pickaxe, carrying and reachable ore: surface extraction (1)")
	f.practitioners.append({"job": "", "skills": {}, "tools": {"prospecting_kit": 1}})
	f.practitioners.append({"job": "smith", "skills": {"smithing": 1}})
	f.stations.forge = 1
	f.tools.prospecting_kit = 1
	f.records.discovery = 1
	check(SettlementIndustries.levels(f, d).mining == 2, "with a prospector's kit in skilled hands, a smith as assayer, a forge and a find: prospecting and assay (2)")
	f.practitioners.append({"job": "", "skills": {}, "tools": {"shovel": 1}})
	f.practitioners.append({"job": "", "skills": {}, "tools": {"shovel": 1}})
	f.transport.handcart = 1
	f.portals = [-1]
	check(SettlementIndustries.levels(f, d).mining == 2, "two diggers with shovels, but no pit ramp or timber support exists: 3 and 4 cannot hold (as MIN-D)")
	f.structures = {"pit_ramp": 1}
	check(SettlementIndustries.levels(f, d).mining == 3, "a pit ramp dug: open-pit excavation (3), two shovel-holders at the floor level")
	f.practitioners[0].tools = {}
	f.tools.erase("pickaxe")
	var ev := SettlementIndustries.evaluate(f, d)
	check(ev.levels.mining == 0 and ev.blocked.mining.has("1 pickaxe") and ev.blocked.mining.has("1 miner with mining 1+ and a pickaxe"),
		"the last pickaxe gone: 0, with the reasons (as MIN-D's regression; %s)" % str(ev.blocked.mining))


class FakeDiscovery:
	extends RefCounted
	var lv := 2
	var world
	func practitioners(need: Dictionary) -> Array:          # Build 17's rule, enough of it for the fake: own pack
		return (world.npcs as Array).filter(func(n): return n.alive and n.inv.has(str(need.get("tool", ""))))
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


class FakeYard:
	extends RefCounted
	var yard := Inventory.new()


class FakeMinDWorld:
	extends RefCounted
	var discovery := FakeDiscovery.new()
	var underground := FakeUnderground.new()
	func _init() -> void:
		discovery.world = self
	var npcs := [_miner()]
	var households := []
	var manor_work := FakeYard.new()
	static func _miner() -> NPC:
		var n := NPC.new()
		n.role = "adult"
		n.job = "miner"
		n.inv.add("pickaxe")
		return n
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
		"practitioners": [{"job": "miner", "skills": {"mining": 5}}, {"job": "smith", "skills": {"smithing": 3}, "tools": {"hammer": 1}}],
		"stock": {"hammer": 1, "pickaxe": 3}, "stations": {"anvil": 1, "forge": 1},
		"external": {"mining": {"level": 3}}}
	var big_prac := []
	for i in 10:
		big_prac.append({"job": "farmer", "skills": {}})
	big_prac[0].tools = {"plough": 1}
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
	check(int(rep.outside.settlement_coins) == w.regions.coins(), "the neighbouring settlements' coins are reported apart, outside the village")
	# owner Q18-10: anyone may buy; the village's parties partition its purses and goods without counting twice
	var ps := SettlementReport.parties(w, {"wheat": 10.0, "bread": 4.0})
	var pt := SettlementReport.party_totals(ps)
	var want_coins := w.treasury
	var want_goods := w.granary.items.duplicate()
	for n: NPC in w.npcs:
		if n.alive and n.role != "bandit":
			want_coins += n.coins
			for id in n.inv.items:
				want_goods[id] = int(want_goods.get(id, 0)) + int(n.inv.items[id])
	for hh in w.households:
		for id in hh.pantry.items:
			want_goods[id] = int(want_goods.get(id, 0)) + int(hh.pantry.items[id])
	check(int(pt.coins) == want_coins and pt.goods == want_goods, "the village's parties hold every villager's purse and pack, the pantries, the treasury and granary, once (%d coins)" % want_coins)
	var kinds := {}
	for l: SettlementLedger in ps:
		kinds[l.kind] = int(kinds.get(l.kind, 0)) + 1
	print("     the village's parties: %s" % str(kinds))
	check(kinds.has("trader") and kinds.has("household") and int(kinds.get("treasury", 0)) == 1, "traders, households and the treasury may each buy")
	var manor: SettlementLedger = ps.filter(func(l): return l.kind == "treasury")[0]
	check(not manor.can_travel and manor.sale_limit is Dictionary and (manor.sale_limit as Dictionary).is_empty(),
		"the treasury cannot fetch goods itself (it needs a carter) and the granary is not for sale")
	var hh0: SettlementLedger = ps.filter(func(l): return l.kind == "household")[0]
	var hh_id := int(hh0.id.get_slice(":", 1))
	var pantry_ok := true
	for id in w.households[hh_id].pantry.items:
		if int((hh0.sale_limit as Dictionary).get(id, 0)) > hh0.stock.count(id) - int(w.households[hh_id].pantry.items[id]):
			pantry_ok = false
	check(pantry_ok and hh0.needs.has("wheat") and not hh0.needs.has("plank"), "a household needs its share of the village's food, and its pantry is not for sale")
	check(JSON.stringify(w.to_dict()) == before, "taking the parties changes nothing in the World")
	# the smiths die (the only hammer holders at the start): smithing falls; the anvil and forge stay
	for n: NPC in w.npcs:
		if n.job == "smith":
			n.alive = false
	check(SettlementIndustries.levels(SettlementFacts.from_world(w)).smithing == 0, "when the village's smiths die, its smithing falls to 0")
	# Build 17's rule (MIN-SKILLCAP): smithing is practised by whoever has the skill and a hammer to hand, never by title.
	# Take every hammer out of reach (packs, pantries, the player's pack and chest): smithing falls to 0 with the smiths alive.
	var w3 := _fresh(1)
	for n: NPC in w3.npcs:
		n.inv.remove("hammer", n.inv.count("hammer"))
	for hh in w3.households:
		hh.pantry.remove("hammer", hh.pantry.count("hammer"))
	w3.player.inv.remove("hammer", w3.player.inv.count("hammer"))
	w3.player.chest.remove("hammer", w3.player.chest.count("hammer"))
	check(SettlementIndustries.levels(SettlementFacts.from_world(w3)).smithing == 0, "with no hammer anyone can use, the village's smithing falls to 0")
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 1)
	check(JSON.stringify(SettlementFacts.plain(SettlementFacts.from_world(w2))) == JSON.stringify(SettlementFacts.plain(SettlementFacts.from_world(_fresh(1)))),
		"the same seed gives the same facts (determinism)")


## SYNC-17 (PROS-18 correction): the settlement evaluator invents no eligibility rule. On the live village it asks
## Discovery itself; on a snapshot (an abstract settlement's facts) its mirror of Build 17's rule must give Discovery's
## counts, for every practitioners need in both data files, including a shared household tool that serves one member
## only and the resident player counted by the villagers' rule.
func test_rule_parity() -> void:
	var needs := []
	for src in [SettlementIndustries.data(), JSON.parse_string(FileAccess.get_file_as_string("res://data/capabilities.json"))]:
		for ind in src.industries:
			for l in src.industries[ind].get("levels", []):
				for n in l.needs:
					if str(n.kind) == "practitioners":
						needs.append(n)
	check(needs.size() >= 10, "every practitioners need of both files is compared (%d)" % needs.size())
	var w := _fresh(1)
	var compare := func(what: String) -> void:
		var f := SettlementFacts.from_world(w)
		var snap := SettlementFacts.plain(f)
		var bad := []
		for n in needs:
			var want: int = (w.discovery.practitioners(n) as Array).size()
			if SettlementIndustries.practitioner_count(n, f) != want or SettlementIndustries.practitioner_count(n, snap) != want:
				bad.append("%s: %d/%d, Discovery %d" % [SettlementIndustries.describe(n),
					SettlementIndustries.practitioner_count(n, f), SettlementIndustries.practitioner_count(n, snap), want])
		check(bad.is_empty(), "%s: the evaluator and its snapshot give Discovery's practitioner counts %s" % [what, str(bad)])
	compare.call("the starting village")
	# a shared tool counts once: one pickaxe in a pantry, several members of that household with none of their own
	var hh := -1
	for i in w.households.size():
		var members: Array = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.household == i)
		if members.size() >= 2:
			hh = i
			for o: NPC in members:
				o.inv.remove("pickaxe", o.inv.count("pickaxe"))
			break
	check(hh >= 0, "a household of two adults or more exists to share a tool")
	w.households[hh].pantry.add("pickaxe")
	var miner := {"kind": "practitioners", "skill": "mining", "min_level": 1, "tool": "pickaxe"}
	var before := SettlementIndustries.practitioner_count(miner, SettlementFacts.plain(SettlementFacts.from_world(w)))
	w.households[hh].pantry.add("pickaxe")
	check(SettlementIndustries.practitioner_count(miner, SettlementFacts.plain(SettlementFacts.from_world(w))) == before + 1,
		"a second pickaxe in the same pantry serves one more member, no more")
	compare.call("with a household sharing pickaxes")
	# the resident player counts by the villagers' rule: not while homeless, then with their chest as their store
	w.player.chest.add("hammer")
	w.player.chest.add("shovel")
	compare.call("a homeless player with tools in the chest")
	var homes := w.buildings.keys()
	homes.sort()
	w.player.home = str(homes[0])
	check(w.discovery.player_resident(), "the player with a home is a resident (MIN-D-Q2)")
	compare.call("the resident player")
	w.player.inv.add("pickaxe")
	compare.call("the resident player with a pickaxe in the pack")


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
