extends SceneTree
## PROSPECTIVE (Expansion 19, FAMILY-01; owner directive 2026-10-23 "Family sacrifice and responsibility"): a household's
## responsible parent or guardian serves those in their care first (children, spouse, parents, then self), down to a
## survival floor, inside the judgment decision engine and behind its switch. Run headless:
##   godot --headless --path game --script res://tests/family_first_test.gd

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
	test_config()
	test_off_is_build_18()
	test_hierarchy()
	test_meal_order()
	test_survival_floor()
	test_spending()
	test_work_over_leisure()
	test_guardians()
	test_temperament()
	test_danger()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A fresh village with a hand-built household: father F (male adult), mother M, children K1 K2, the father's mother G (elder),
## the mother's father G2 (elder), and a taken-in orphan O (a child of no one here). Pantry empty, everyone fed.
func new_world(on := true, seed := 1) -> Dictionary:
	JudgmentLive.test_disabled = not on                 # Build 19 ships judgment on; the Build 18 path is the explicit off
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	JudgmentLive.test_disabled = false
	var pool := []
	for n: NPC in w.npcs:
		if n.alive and n.role != "bandit" and n.clan == "" and n.job != "guard" and n.household >= 0 and pool.size() < 8:
			pool.append(n)
	var f: NPC = pool[0]
	var h := f.household
	for n: NPC in pool:
		if n.household != h and n.household >= 0:
			(w.households[n.household].members as Array).erase(n.id)
	w.households[h].members = []
	var fam := {"w": w, "h": h, "F": f, "M": pool[1], "K1": pool[2], "K2": pool[3], "G": pool[4], "G2": pool[5], "O": pool[6]}
	for k in ["F", "M", "K1", "K2", "G", "G2", "O"]:
		var n: NPC = fam[k]
		w.brain._lodge(n, h)
		n.hunger = 100.0
		n.inv.items.clear()
		n.coins = 0
		n.children = []
		n.partner = -1
		n.mother = -1
		n.father = -1
	var m: NPC = fam.M
	f.role = "adult"; f.sex = "male"; f.born = -20
	m.role = "adult"; m.sex = "female"; m.born = -30          # older, and lower in the usual order: the father still heads
	for k in ["K1", "K2", "O"]:
		var c: NPC = fam[k]
		c.role = "child"
	(fam.G as NPC).role = "elder"
	(fam.G2 as NPC).role = "elder"
	f.partner = m.id
	m.partner = f.id
	for k in ["K1", "K2"]:
		var c: NPC = fam[k]
		c.father = f.id
		c.mother = m.id
		f.children.append(c.id)
		m.children.append(c.id)
	f.mother = (fam.G as NPC).id
	m.father = (fam.G2 as NPC).id
	pantry(fam, 0)
	if on:
		var j := JudgmentLive.attach(w)
		(j.cfg.decision.family as Dictionary).extreme_share_permille = 0       # no one with the rare temperament unless a test asks
	fam.on = on
	return fam


func pantry(fam: Dictionary, wheat: int) -> void:
	var p: Inventory = fam.w.households[fam.h].pantry
	p.items.clear()
	for i in wheat:
		p.add("wheat")


func hungry(fam: Dictionary, who: Array, hunger: float) -> void:
	for k in who:
		(fam[k] as NPC).hunger = hunger


func done(fam: Dictionary) -> void:
	fam.w.dispose()


func test_config() -> void:
	var c := JudgmentStore.default_cfg()
	check(bool(c.enabled), "judgment.json ships enabled: Build 19 has the family-first rules on (test_disabled is the Build 18 path)")
	check(bool(c.decision.integration.get("family_first", false)), "decision.integration.family_first exists (on with judgment on)")
	for p in ["family_meal", "family_pay", "family_work"]:
		check(c.decision.profiles.has(p), "profile " + p)
	for k in ["survival_floor_hunger", "coin_floor", "extreme_share_permille", "self_first_hunger", "work_coins_below"]:
		check(c.decision.family.has(k), "family setting " + k)


func test_off_is_build_18() -> void:
	# judgment off: the father eats from the pantry first, the richest pays the child's meal, as in Build 18
	var fam := new_world(false)
	var w: World = fam.w
	var f: NPC = fam.F
	var m: NPC = fam.M
	pantry(fam, 2)
	hungry(fam, ["K1", "K2"], 30.0)
	f.hunger = 40.0
	check(w.judgment == null, "no judgment store")
	var ate: bool = w.brain._plan_eat(f)
	check(ate and f.doing == "going home to eat", "off: the father eats from the short pantry (Build 18)")
	f.coins = 10
	m.coins = 50
	check(w.brain._payer_for(fam.K1, 4) == m, "off: the richest member pays the child's meal (Build 18)")
	check(w.brain._payer_for(fam.K1, 4) == w.brain._richest_in_household(fam.K1), "...exactly the old rule")
	done(fam)
	# judgment on but the family flag off: the same
	fam = new_world(true)
	w = fam.w
	w.judgment.cfg.decision.integration.family_first = false
	pantry(fam, 2)
	hungry(fam, ["K1", "K2"], 30.0)
	(fam.F as NPC).hunger = 40.0
	(fam.F as NPC).coins = 10
	(fam.M as NPC).coins = 50
	check(w.brain._plan_eat(fam.F) and (fam.F as NPC).doing == "going home to eat", "flag off: the father eats first, as in Build 18")
	check(w.brain._payer_for(fam.K1, 4) == fam.M, "flag off: the richest pays")
	check(w.judgment.family_trace.is_empty(), "flag off: nothing recorded")
	done(fam)


func test_hierarchy() -> void:
	var fam := new_world()
	var w: World = fam.w
	var hd := JudgmentFamily.head(w, fam.h)
	check(hd == fam.F, "both parents living: the father is the head, though the mother is older")
	var t := func(k: String) -> int: return JudgmentFamily.tier(w, hd, fam[k])
	check(t.call("K1") == JudgmentFamily.TIER_CHILD and t.call("K2") == JudgmentFamily.TIER_CHILD, "own children are children")
	check(t.call("O") == JudgmentFamily.TIER_CHILD, "a taken-in orphan counts as a child")
	check(t.call("M") == JudgmentFamily.TIER_SPOUSE, "the partner is the spouse")
	check(t.call("G") == JudgmentFamily.TIER_PARENT, "his own mother is a parent")
	check(t.call("G2") == JudgmentFamily.TIER_PARENT, "the spouse's father is a parent")
	check(t.call("F") == JudgmentFamily.TIER_HEAD, "the head is last")
	done(fam)


## Children, then spouse, then parents, then the head, when the pantry is short.
func test_meal_order() -> void:
	var fam := new_world()
	var w: World = fam.w
	pantry(fam, 2)                                              # 240 food points
	hungry(fam, ["K1", "K2", "O"], 30.0)
	hungry(fam, ["M", "G", "G2", "F"], 50.0)
	var d := func(k: String) -> bool: return JudgmentFamily.defers(w, fam[k], "pantry")
	check(not d.call("K1") and not d.call("O"), "children never give way")
	check(d.call("M"), "children hungry, food short: the spouse gives way to them")
	check(d.call("G") and d.call("G2"), "...and the parents")
	check(d.call("F"), "...and the head last of all")
	hungry(fam, ["K1", "K2", "O"], 90.0)
	pantry(fam, 1)                                              # still short for the adults left
	hungry(fam, ["M"], 30.0)
	check(not d.call("M"), "children fed: the spouse eats")
	check(d.call("G") and d.call("F"), "...parents and the head still give way to her")
	hungry(fam, ["M"], 90.0)
	check(not d.call("G") and not d.call("G2"), "spouse fed: the parents eat")
	check(d.call("F"), "...the head still gives way to the hungry parents")
	hungry(fam, ["G", "G2"], 90.0)
	check(not d.call("F"), "everyone below fed: the head eats")
	# enough food for all: nobody gives anything up (Build 18 behaviour even with the flag on)
	hungry(fam, ["K1", "K2", "O", "M", "G", "G2", "F"], 40.0)
	pantry(fam, 20)
	check(not d.call("F") and not d.call("M") and not d.call("G"), "plenty in the pantry: no one defers")
	# the actual meal plan: the head leaves the pantry; a child eats from it
	pantry(fam, 2)
	hungry(fam, ["K1"], 30.0)
	check(not w.brain._plan_eat(fam.F) or (fam.F as NPC).doing != "going home to eat", "the head does not go home to the short pantry")
	check(w.brain._plan_eat(fam.K1) and (fam.K1 as NPC).doing == "going home to eat", "the child does")
	var rows: Array = w.judgment.family_trace
	check(not rows.is_empty(), "the decisions are recorded")
	var row: Dictionary = rows[0]
	var seen := {}
	for r in row.trace:
		for k in (r.get("factors", {}) as Dictionary):
			seen[k] = true
	for k in ["family_child_need", "family_spouse_need", "family_parent_need", "self_need", "self_floor", "self_first_temperament"]:
		check(seen.has(k), "trace records factor " + k)
	check(str(row.kind).begins_with("meal_") and row.has("who") and row.has("day"), "...with the decision's kind, person and day")
	done(fam)


func test_survival_floor() -> void:
	var fam := new_world()
	var w: World = fam.w
	var f: NPC = fam.F
	pantry(fam, 2)
	hungry(fam, ["K1", "K2", "O", "M", "G", "G2"], 30.0)
	var floor_ := float(w.judgment.cfg.decision.family.survival_floor_hunger)
	f.hunger = floor_ + 1.0
	check(JudgmentFamily.defers(w, f, "pantry"), "just above the floor the head still gives way")
	f.hunger = floor_
	check(not JudgmentFamily.defers(w, f, "pantry"), "at the survival floor the head eats whatever the family needs")
	f.hunger = floor_ - 10.0
	check(not JudgmentFamily.defers(w, f, "pantry"), "below it too")
	var last: Dictionary = w.judgment.family_trace[w.judgment.family_trace.size() - 1]
	var floor_factor := 0
	for r in last.trace:
		floor_factor = maxi(floor_factor, int((r.get("factors", {}) as Dictionary).get("self_floor", 0)))
	check(floor_factor == 100000, "the floor is recorded as self_floor in the trace")
	done(fam)


func test_spending() -> void:
	var fam := new_world()
	var w: World = fam.w
	var f: NPC = fam.F
	var m: NPC = fam.M
	f.coins = 10
	m.coins = 50
	check(w.brain._payer_for(fam.K1, 4) == f, "on: the head's purse pays a child's meal first (not the richest)")
	check(w.brain._payer_for(fam.M, 4) == f, "...and the spouse's")
	check(w.brain._payer_for(fam.G, 4) == f, "...and a parent's")
	check(w.brain._payer_for(f, 4) == f, "the head's own meal: unchanged, he pays")
	f.coins = 7
	check(w.brain._payer_for(fam.K1, 4) == f, "the head pays down to the coin floor (3)")
	f.coins = 6
	check(w.brain._payer_for(fam.K1, 4) == m, "under the floor the live rule (richest) takes over: he keeps enough to go on working")
	f.coins = 0
	m.coins = 0
	check(w.brain._payer_for(fam.K1, 4) == null, "nobody has the coin: nobody pays")
	var rows: Array = w.judgment.family_trace
	var pay := rows.filter(func(r): return r.kind == "pay")
	check(pay.size() >= 3 and pay[0].has("for") and pay[0].has("price"), "payments recorded with who it was for")
	done(fam)


func test_work_over_leisure() -> void:
	var fam := new_world()
	var w: World = fam.w
	var f: NPC = fam.F
	pantry(fam, 1)
	hungry(fam, ["K1", "K2", "O"], 30.0)
	f.coins = 5
	check(JudgmentFamily.prefers_work(w, f), "dependants hungry, food and coin short: the head prefers paid work to leisure")
	check(w.judgment.family_trace[w.judgment.family_trace.size() - 1].chosen == "work", "...recorded")
	f.coins = 80
	check(not JudgmentFamily.prefers_work(w, f), "with coin in hand there is no pressure")
	f.coins = 5
	hungry(fam, ["K1", "K2", "O"], 90.0)
	check(not JudgmentFamily.prefers_work(w, f), "dependants fed: leisure as usual")
	hungry(fam, ["K1", "K2", "O"], 30.0)
	pantry(fam, 20)
	check(not JudgmentFamily.prefers_work(w, f), "food in the pantry: no pressure")
	# the evening plan: no tavern or company for a parent in this need
	pantry(fam, 1)
	f.coins = 5
	f.job = ""
	f.anim = "idle"
	w.brain._plan_evening(f, 10.0)
	check(f.doing != "", "the evening plan chose something (necessities such as firewood come first): " + f.doing)
	check(f.doing != "at the tavern" and not f.doing.begins_with("spending time"), "no tavern or company")
	done(fam)


func test_guardians() -> void:
	# a mother raising her children alone (a widow): she heads and gives way to them
	var fam := new_world()
	var w: World = fam.w
	var f: NPC = fam.F
	f.alive = false
	pantry(fam, 1)
	hungry(fam, ["K1", "K2", "O"], 30.0)
	hungry(fam, ["M"], 40.0)
	check(JudgmentFamily.head(w, fam.h) != f, "the dead father does not head")
	var hd := JudgmentFamily.head(w, fam.h)
	check(hd != null and hd.role in ["adult", "elder"], "someone heads: " + (hd.name if hd else "none"))
	check(JudgmentFamily.defers(w, fam.M, "pantry"), "the widowed mother gives way to her children")
	# a grandparent raising grandchildren: only elders and children remain
	(fam.M as NPC).alive = false
	check(JudgmentFamily.head(w, fam.h) in [fam.G, fam.G2], "a grandparent heads the household with no adult left")
	hungry(fam, ["G", "G2"], 40.0)
	var gp: NPC = JudgmentFamily.head(w, fam.h)
	check(JudgmentFamily.defers(w, gp, "pantry"), "the grandparent gives way to the grandchildren")
	check(JudgmentFamily.tier(w, gp, fam.K1) == JudgmentFamily.TIER_CHILD and JudgmentFamily.tier(w, gp, fam.O) == JudgmentFamily.TIER_CHILD, "grandchildren and a taken-in orphan are children")
	done(fam)


func test_temperament() -> void:
	var fam := new_world()
	var w: World = fam.w
	var f: NPC = fam.F
	var fc: Dictionary = w.judgment.cfg.decision.family
	pantry(fam, 2)
	hungry(fam, ["K1", "K2", "O", "M", "G", "G2"], 30.0)
	# find a villager with the potential for stubbornness, and one without
	var holder: NPC = null
	var plain: NPC = null
	for n: NPC in w.npcs:
		if w.judgment.pers.holds_stubbornness(n.id):
			holder = holder if holder != null else n
		else:
			plain = plain if plain != null else n
	check(holder != null and plain != null, "the village has both kinds")
	fc.extreme_share_permille = 1000
	var share := 0
	for n: NPC in w.npcs:
		if JudgmentFamily.self_first(w, n):
			share += 1
	check(share > 0 and share < w.npcs.size() / 2, "with every holder extreme, only the minority with the potential is (%d of %d)" % [share, w.npcs.size()])
	fc.extreme_share_permille = 150
	share = 0
	for n: NPC in w.npcs:
		if JudgmentFamily.self_first(w, n):
			share += 1
	check(share * 10 <= w.npcs.size(), "shipped share: uncommon (%d of %d villagers)" % [share, w.npcs.size()])
	# the extreme temperament eats earlier (above the floor, at self_first_hunger); recorded
	fc.extreme_share_permille = 1000
	var hh: Dictionary = w.households[fam.h]
	(hh.members as Array).append(holder.id)
	holder.household = fam.h
	holder.role = "adult"
	holder.partner = f.id          # becomes the head's spouse for the test
	f.partner = holder.id
	holder.hunger = float(fc.self_first_hunger) - 5.0
	check(JudgmentFamily.self_first(w, holder), "the holder has the extreme temperament")
	var again := JudgmentFamily.self_first(w, holder)
	check(again == JudgmentFamily.self_first(w, holder), "deterministic: a fixed hash, not a roll")
	check(not JudgmentFamily.defers(w, holder, "pantry"), "the extreme temperament puts self first below self_first_hunger")
	var row: Dictionary = w.judgment.family_trace[w.judgment.family_trace.size() - 1]
	var tf := 0
	for r in row.trace:
		tf = maxi(tf, int((r.get("factors", {}) as Dictionary).get("self_first_temperament", 0)))
	check(tf == 100000 and bool(row.temperament), "...and records self_first_temperament")
	fc.extreme_share_permille = 0
	check(JudgmentFamily.defers(w, holder, "pantry"), "without the temperament the same person gives way at that hunger")
	# the order is not touched: the tier of each member is the same whatever the temperament
	var hd := JudgmentFamily.head(w, fam.h)
	check(JudgmentFamily.tier(w, hd, fam.K1) < JudgmentFamily.tier(w, hd, fam.G) and JudgmentFamily.tier(w, hd, fam.G) < JudgmentFamily.tier(w, hd, hd), "tiers: children, parents, head, whoever's temperament")
	done(fam)


## An open-air cell near the village centre where the family can stand.
func open_cell(w: World, skip := 0) -> Vector2:
	var sp = w.map.data.spawns.player
	var found := 0
	for r in range(0, 14):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := Vector2i(int(sp[0]) + dx, int(sp[1]) + dy)
				if absi(dx) != r and absi(dy) != r:
					continue
				var p := Vector2(c) + Vector2(0.5, 0.5)
				if not w.map.is_solid(c) and w.place_of(p) == "":
					if found >= skip:
						return p
					found += 1
	return Vector2(sp[0], sp[1])


## FAM-SAC-01 danger ("Shield and fetch help", owner 2026-10-23): a threat near the head's dependants out of doors.
func danger_scene(stubborn := false, seed := 1) -> Dictionary:
	var fam := new_world(true, seed)
	var w: World = fam.w
	var j: JudgmentStore = w.judgment
	j.cfg.decision.trait_spread_permille = 0                # personality noise off: the exact weighing
	var tr: Dictionary = j.cfg.traits
	tr.stubbornness_share_permille = 1000 if stubborn else 0
	tr.stubbornness_start_min_permille = 0
	tr.stubbornness_start_max_permille = 0
	tr.stubbornness_start_permille = 600
	j.pers.configure(tr)
	var foe: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			foe = n
			break
	fam.foe = foe
	var at := open_cell(w)
	for k in ["F", "K1", "K2", "M"]:
		var n: NPC = fam[k]
		n.pos = at + Vector2(float(["F", "K1", "K2", "M"].find(k)) * 0.4, 0.0)
		n.depth = 0
		n.anim = "idle"
		n.plan = []
		n.target = -1
		n.report = {}
		n.hp = n.max_hp
	for g: NPC in w.npcs:
		if g.job == "guard":
			g.pos = at + Vector2(300.0, 0.0)                  # no guard within reach of the scene unless a test brings one
	foe.pos = at + Vector2(5.0, 0.0)
	foe.depth = 0
	foe.target = -1
	w.minutes = 8.0 * 1440.0 + 12 * 60.0
	j.threat_cache = {}
	return fam


func test_danger() -> void:
	var fc_keys := ["radius", "reach", "cornered_radius"]
	var c := JudgmentStore.default_cfg()
	check(c.decision.profiles.has("family_danger") and c.decision.family.has("danger"), "the danger profile and radii are configured")
	for k in fc_keys:
		check(c.decision.family.danger.has(k), "danger setting " + k)
	# no threat near: the ordinary day
	var fam := danger_scene()
	var w: World = fam.w
	var f: NPC = fam.F
	fam.foe.pos = f.pos + Vector2(60.0, 0.0)
	w.judgment.threat_cache = {}
	check(not JudgmentFamily.danger(w, f), "no threat within the radius of the family: nothing changes")
	done(fam)
	# a bandit near the children: shield, send them home, tell a guard
	fam = danger_scene()
	w = fam.w
	f = fam.F
	var k1: NPC = fam.K1
	check(JudgmentFamily.head(w, fam.h) == f and not JudgmentFamily.danger(w, fam.M), "the head acts; the mother (not the head while the father lives) does not")
	check(JudgmentLive.on(w, JudgmentFamily.FLAG), "(the family flag is on)")
	w.brain.decide(f)
	var row: Dictionary = w.judgment.family_trace[w.judgment.family_trace.size() - 1]
	check(row.kind == "danger" and row.chosen == "shield" and row.threat == "bandit" and int(row.dependants) >= 2, "a bandit comes within reach of the children: the head chooses to shield them (%s)" % str(row.chosen))
	check(k1.doing == "hurrying home from danger" and not k1.plan.is_empty(), "...the children are sent home")
	check(not f.plan.is_empty() and f.doing == "shielding the family", "...the head moves between the threat and them")
	check(int(f.report.get("offender", -9)) == fam.foe.id, "...and will run for a guard: a report of the bandit is carried by the ordinary path (PAR-05)")
	var traced := false
	for r in row.trace:
		if (r.get("factors", {}) as Dictionary).has("family_danger_child"):
			traced = true
	check(traced and (row.trace[0].factors as Dictionary).family_danger_child == 100000, "...the family-priority factors are recorded in the trace (XEXPL-01)")
	# the report is delivered: a guard takes on the bandit
	var g: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.job == "guard" and n.alive)[0]
	g.target = -1
	g.pos = f.pos
	f.pos = g.pos
	check(w.deliver_report(f, g) and g.target == fam.foe.id, "...and the guard answers it")
	done(fam)
	# cornered: the children are right beside the bandit
	fam = danger_scene()
	w = fam.w
	f = fam.F
	fam.foe.pos = (fam.K1 as NPC).pos + Vector2(1.2, 0.0)
	w.judgment.threat_cache = {}
	check(JudgmentFamily.danger(w, f) and f.target == fam.foe.id and f.doing == "defending the family", "cornered, the head stands and fights the bandit (the ordinary fight)")
	done(fam)
	# a stubborn head stands their ground even when not cornered; a plain one shields
	fam = danger_scene(true)
	w = fam.w
	check(JudgmentFamily.danger(w, fam.F) and (fam.F as NPC).target == fam.foe.id, "a stubborn head (stubbornness 60%) fights rather than shields: stubbornness bends readiness")
	done(fam)
	fam = danger_scene(false)
	w = fam.w
	check(JudgmentFamily.danger(w, fam.F) and (fam.F as NPC).target == -1 and (fam.F as NPC).doing == "shielding the family", "...a head without the potential shields (same scene)")
	done(fam)
	# a badly hurt head runs; so does the rare self-first temperament, recorded
	fam = danger_scene()
	w = fam.w
	(fam.F as NPC).hp = 4.0                                     # under a fifth of their health: the survival floor
	check(JudgmentFamily.danger(w, fam.F) and (fam.F as NPC).doing == "running from danger", "a head under the survival floor runs for home rather than die (a sacrifice is not a suicide)")
	done(fam)
	fam = danger_scene(true)
	w = fam.w
	(fam.F as NPC).hp = 8.0                                     # hurt, but above the floor: the stubborn head is less fit to stand
	check(JudgmentFamily.danger(w, fam.F) and (fam.F as NPC).doing in ["shielding the family", "defending the family"], "a hurt head above the floor still protects the family")
	done(fam)
	fam = danger_scene(true)
	w = fam.w
	w.judgment.cfg.decision.family.extreme_share_permille = 1000
	check(JudgmentFamily.danger(w, fam.F) and (fam.F as NPC).doing == "running from danger", "the rare extreme temperament puts self first")
	var r2: Dictionary = w.judgment.family_trace[w.judgment.family_trace.size() - 1]
	check(bool(r2.temperament) and r2.chosen == "flee", "...and that is recorded")
	done(fam)
	# dependants indoors, or nobody in their care near: no response
	fam = danger_scene()
	w = fam.w
	var inside := Vector2.ZERO
	var hi: int = w.place_ids.find((fam.K1 as NPC).home)
	for i in w.place_idx.size():
		if w.place_idx[i] == hi:
			inside = Vector2(i % w.map.w, i / w.map.w) + Vector2(0.5, 0.5)
			break
	for k in ["K1", "K2", "M"]:
		(fam[k] as NPC).pos = inside
	w.judgment.threat_cache = {}
	check(not JudgmentFamily.danger(w, fam.F), "dependants indoors are not in the open: no response")
	done(fam)
	# a wolf at the children: shield, and strike it when cornered
	fam = danger_scene()
	w = fam.w
	var wolf := Animal.new()
	wolf.id = 9901
	wolf.species = "wolf"
	wolf.skin = "mini_wolf"
	wolf.hp = 6.0
	wolf.pos = (fam.K1 as NPC).pos + Vector2(4.0, 0.0)
	wolf.anger = "npc:%d" % (fam.K1 as NPC).id
	wolf.anger_left = 20.0
	w.fauna.animals.append(wolf)
	fam.foe.pos = (fam.F as NPC).pos + Vector2(80.0, 0.0)
	w.judgment.threat_cache = {}
	check(JudgmentFamily.danger(w, fam.F) and (fam.F as NPC).doing == "shielding the family" and (fam.K1 as NPC).doing == "hurrying home from danger", "a wolf going for a child: the head shields and the children go home (no guard acts on a beast, so no report)")
	check((fam.F as NPC).report.is_empty(), "...no report is made for a beast")
	wolf.pos = (fam.K1 as NPC).pos + Vector2(1.0, 0.0)
	(fam.F as NPC).pos = wolf.pos + Vector2(0.5, 0.0)
	(fam.F as NPC).plan = []
	w.judgment.threat_cache = {}
	var hp0 := wolf.hp
	check(JudgmentFamily.danger(w, fam.F) and wolf.hp < hp0 and wolf.anger == "npc:%d" % (fam.F as NPC).id, "cornered, the head strikes the wolf and it turns on them")
	done(fam)
	# judgment off (Build 18): the day goes on as before
	JudgmentLive.test_disabled = true
	var off := World.new()
	off.setup(VillageMap.load_default(), 1)
	JudgmentLive.test_disabled = false
	check(off.judgment == null and not JudgmentLive.on(off, JudgmentFamily.FLAG), "judgment off: no danger behaviour exists (Build 18)")
	off.dispose()


func run_once() -> String:
	var fam := new_world(true, 3)
	var w: World = fam.w
	pantry(fam, 2)
	hungry(fam, ["K1", "K2", "O"], 30.0)
	hungry(fam, ["M", "G", "G2", "F"], 40.0)
	(fam.F as NPC).coins = 9
	(fam.M as NPC).coins = 40
	var out := []
	for k in ["F", "M", "G", "K1"]:
		out.append(JudgmentFamily.defers(w, fam[k], "pantry"))
	out.append((w.brain._payer_for(fam.K1, 4) as NPC).id)
	out.append(JudgmentFamily.prefers_work(w, fam.F))
	out.append(JSON.stringify(w.judgment.family_trace).hash())
	done(fam)
	return str(out)


func test_determinism() -> void:
	var a := run_once()
	var b := run_once()
	check(a == b, "same seed twice: the same decisions and the same traces")
