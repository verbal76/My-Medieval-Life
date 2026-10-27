extends SceneTree
## EXPANSION 20 R5 (WDR-011-C): NPC aspirations in six domains, the owner's final decisions of 2026-10-27
## (docs/directives/2026-10-27_final_aspirations_decisions.md, "FAD"). One section per verification bullet of the
## directive's IMPLEMENTATION REQUIREMENTS, V1..V10, in its order (design docs/expansion20/R5_ASPIRATIONS_DESIGN.md s.9),
## plus the layer's own invariants (neutral = off, determinism, the recorder, heirs). Run headless:
##   godot --headless --path game --script res://tests/aspiration_test.gd

const Census := preload("res://tests/census.gd")
const STEP := 0.5
const A := preload("res://scripts/core/judgment/judgment_aspiration.gd")

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
	test_config()
	test_v1_survival()
	test_v1_danger_is_real_harm()
	test_v2_hungry_parent_protects()
	test_v3_no_needless_sacrifice()
	test_v4_job_choice()
	test_v5_romance()
	test_q8_proposals()
	test_q8_player_proposals()
	test_v6_perseverance()
	test_v7_standing()
	test_v8_save_load()
	test_v9_disabled_is_baseline()
	test_v10_no_resources()
	test_domains_and_neutral()
	test_recorder()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- fixtures ------------------------
func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


## Switch the layer on in `w`'s store. `exact`: no temperament spread, no age steps, no per-person weight spread and
## argmax selection, so a test can compute the weighing; the shipped values are PROVISIONAL and measured elsewhere.
func asp_on(w: World, exact := true) -> JudgmentAspiration:
	var j: JudgmentStore = w.judgment
	var c: Dictionary = j.cfg.aspiration
	c.enabled = true
	if exact:
		for k in ["priority_spread", "young_step", "old_step", "old_profession_step"]:
			c[k] = 0
		j.cfg.decision.trait_spread_permille = 0
		j.cfg.decision.selection = "argmax"
	j.asp.configure(c)
	return j.asp


func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.job != "guard":
			out.append(n)
	return out


func set_row(a: JudgmentAspiration, n: NPC, sat: Array, shift := [0, 0, 0, 0, 0, 0]) -> void:
	if not a.rows.has(n.id):
		a.rows[n.id] = a._new_row()
	a.rows[n.id].sat = sat.duplicate()
	a.rows[n.id].shift = shift.duplicate()
	for d in A.ND:
		a.rows[n.id].band[d] = a.band_of(int(sat[d]))


## The family-first household of family_first_test: father F (head), mother M, children K1 K2, the father's mother G,
## the mother's father G2, a taken-in orphan O. Pantry empty, everyone fed. `aspire`: the R5 layer on as well.
func family(aspire: bool, seed := 1) -> Dictionary:
	var w := world(seed)
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
	m.role = "adult"; m.sex = "female"; m.born = -30
	for k in ["K1", "K2", "O"]:
		(fam[k] as NPC).role = "child"
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
	w.judgment.cfg.decision.family.extreme_share_permille = 0
	w.judgment.cfg.decision.trait_spread_permille = 0
	if aspire:
		asp_on(w)
	return fam


func pantry(fam: Dictionary, wheat: int) -> void:
	var p: Inventory = fam.w.households[fam.h].pantry
	p.items.clear()
	for i in wheat:
		p.add("wheat")


func last_family_trace(w: World) -> String:
	var t: Array = w.judgment.family_trace
	return JSON.stringify(t[t.size() - 1].trace) if not t.is_empty() else ""


# ---------------------------------------------------------------- config --------------------------
func test_config() -> void:
	var c := JudgmentStore.default_cfg()
	check(c.has("aspiration") and not bool(c.aspiration.enabled), "judgment.json ships the aspiration section OFF (FAD: until validation and owner review)")
	check(not bool(c.decision.integration.get("job_choice", true)), "decision.integration.job_choice exists and ships OFF (its own flag, FAD Q2)")
	check(c.decision.profiles.has("job_choice"), "the job_choice profile is defined")
	check(str(c.aspiration._status).contains("PROVISIONAL"), "the aspiration numbers are marked PROVISIONAL (FAD Q5)")
	check(int(c.decision.family.survival_floor_hunger) == 25 and int(c.traits.stubbornness_share_permille) == 300,
			"the owner's values are where they were: survival floor 25, stubbornness share 300 (read there, not copied)")
	check(A.DOMAINS == ["food", "wealth", "property", "profession", "family", "standing"], "six domains (FAD Q6): food, wealth, property, profession, family, standing")
	for p in ["family_meal", "family_pay", "family_work", "family_danger"]:
		check(not (c.aspiration.factor_weights as Dictionary).has(p) and not c.decision.profiles[p].has("scaled_by"), "the family profile %s gains no aspiration factor and no scaling" % p)


# ---------------------------------------------------------------- V1 ------------------------------
## Severe hunger and injury alter priorities; after recovery the earlier ambitions regain influence.
func test_v1_survival() -> void:
	var w := world()
	var a := asp_on(w)
	var ps := adults(w)
	var n: NPC = ps[0]
	n.hunger = 100.0
	n.hp = n.max_hp
	check(a.raw_survival(n, w) == 0, "V1: fed and well: survival level 0")
	n.hunger = 25.0
	check(a.raw_survival(n, w) == 1000, "V1: hunger at the owner's survival floor 25: survival level 1000")
	n.hunger = 50.0
	check(a.raw_survival(n, w) == 0, "V1: hunger 50, an ordinary appetite before breakfast (below eat_below 55): no survival pressure")
	n.hunger = 30.0
	var mid := a.raw_survival(n, w)
	check(mid > 0 and mid < 1000, "V1: hunger 30 (between hunger_from 35 and the floor): partial (%d)" % mid)
	n.hunger = 100.0
	n.hp = n.max_hp * 0.2
	check(a.raw_survival(n, w) == 1000, "V1: health at the danger floor (20%%): survival level 1000")
	n.hp = n.max_hp * 0.85
	check(a.raw_survival(n, w) == 0, "V1: lightly hurt (85%%): no survival pressure")
	n.hp = n.max_hp
	# priorities: food rises, the others yield, nothing is cancelled
	set_row(a, n, [40000, 90000, 90000, 0, 90000, 90000])
	var pl0 := a.pressures(n, w, 0)
	check(int(pl0[1]) == A.PROFESSION, "V1: before: the profession ambition leads (a craftsman wanting to improve)")
	var pl1 := a.pressures(n, w, 1000)
	check(int(pl1[1]) == A.FOOD, "V1: starving: food leads")
	check(a.eff_priority(n, A.FOOD, 1000, w) > a.eff_priority(n, A.FOOD, 0, w), "V1: food's priority rises under survival pressure")
	for d in [A.WEALTH, A.PROPERTY, A.PROFESSION, A.FAMILY, A.STANDING]:
		var e := a.eff_priority(n, d, 1000, w)
		check(e < a.eff_priority(n, d, 0, w) and e > 0, "V1: %s yields but is not cancelled (%d of %d)" % [A.DOMAINS[d], e, a.eff_priority(n, d, 0, w)])
	check(a.yield_of(n.id, A.FAMILY) < a.yield_of(n.id, A.WEALTH), "V1: family yields least (protection and stability stay in view)")
	# personality: a stubborn villager holds on longer
	var stub: NPC = null
	var plain: NPC = null
	for o: NPC in ps:
		if w.judgment.pers.stubbornness(o.id, w.day()) > 0 and stub == null:
			stub = o
		elif not w.judgment.pers.holds_stubbornness(o.id) and plain == null:
			plain = o
	check(stub != null and plain != null, "V1: the village has stubborn and plain villagers (about 30%% hold stubbornness)")
	if stub != null and plain != null:
		check(a.yield_of(stub.id, A.PROFESSION) < a.yield_of(plain.id, A.PROFESSION), "V1: a stubborn villager's ambitions yield less under hardship (%d < %d)" % [a.yield_of(stub.id, A.PROFESSION), a.yield_of(plain.id, A.PROFESSION)])
	# recovery: the dawn lets the level fall 200 a day; the earlier lead returns
	n.hunger = 25.0
	a.dawn(w)
	check(int(a.rows[n.id].surv) == 1000, "V1: at dawn while starving the saved survival level is 1000")
	n.hunger = 100.0
	check(a.survival(n, w) == 1000, "V1: fed again at once, a decision still reads 1000 (it falls only by the dawn)")
	var levels := []
	var leads := []
	for day in 5:
		a.dawn(w)
		levels.append(int(a.rows[n.id].surv))
		leads.append(int(a.pressures(n, w, int(a.rows[n.id].surv))[1]))
	check(levels == [800, 600, 400, 200, 0], "V1: after recovery the level falls 200 a day (%s)" % str(levels))
	var r: Dictionary = a.rows[n.id]
	r.sat = [40000, 90000, 90000, 0, 90000, 90000]
	r.shift = [0, 0, 0, 0, 0, 0]                 # the dawns' band crossings shift priorities legitimately; isolate the survival path
	check(int(a.pressures(n, w, 1000)[1]) == A.FOOD and int(a.pressures(n, w, 200)[1]) == A.PROFESSION and int(a.pressures(n, w, 0)[1]) == A.PROFESSION,
			"V1: as it falls the profession ambition regains the lead (food at 1000, profession again by 200 and at 0)")
	var w2 := world()
	var a2 := asp_on(w2)
	var m: NPC = adults(w2)[0]
	m.hunger = 25.0
	a2.dawn(w2)
	m.hunger = 100.0
	for day in 6:
		a2.dawn(w2)
	var sh: Array = a2.rows[m.id].shift
	check(int(sh[1]) == 0 and int(sh[2]) == 0 and int(sh[3]) == 0 and int(sh[4]) == 0 and int(sh[5]) == 0,
			"V1: hunger and its recovery change no other domain's priority permanently (survival pressure is not a shift: %s)" % str(sh))
	w.dispose()
	w2.dispose()


## V1, danger (coordinator check after the 30-day measurement, 2026-10-27): "dangerous living conditions" are the villager's
## real situation (harm to them or their household), never village gossip about other people.
func test_v1_danger_is_real_harm() -> void:
	var w := world()
	var a := asp_on(w)
	var j: JudgmentStore = w.judgment
	var parent: NPC = null
	var child: NPC = null
	for c: NPC in w.npcs:
		if c.alive and c.role == "child" and c.household >= 0:
			for m in w.households[c.household].members:
				var o: NPC = w.npc(int(m))
				if o != null and o.alive and o.role == "adult" and o.job != "guard":
					parent = o
					child = c
					break
		if parent != null:
			break
	check(parent != null, "danger: a household with an adult and a child")
	var stranger: NPC = null
	var thug: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household != parent.household and o.household >= 0:
			if stranger == null:
				stranger = o
			elif thug == null and o.household != stranger.household:
				thug = o
	parent.hunger = 100.0
	parent.hp = parent.max_hp
	var p0 := a.survival_parts(parent, w)
	check(int(p0.hunger) == 0 and int(p0.injury) == 0 and int(p0.danger) == 0 and a.raw_survival(parent, w) == 0,
			"danger: a well-fed, unhurt villager in a peaceful household is under no pressure (%s)" % str(p0))
	# an assault on a stranger, which the parent saw and is told about again: hearsay about others raises nothing
	var ev := j.publish("assault", [thug.id], [stranger.id], [], 0)
	j.observe_all(ev, [parent.id])
	check(j.memories.get(parent.id, {}).has(ev), "danger: (the parent knows of the assault on a stranger)")
	check(int(a.survival_parts(parent, w).danger) == 0 and a.raw_survival(parent, w) == 0, "danger: knowing of an assault on a stranger raises no pressure")
	check(int(a.survival_parts(stranger, w).danger) > 0, "danger: ...it does for the one assaulted")
	# an assault on the parent's own child: pressure at once, without anyone telling the parent
	var ev2 := j.publish("assault", [thug.id], [child.id], [], 0)
	check(ev2 > 0 and int(a.survival_parts(parent, w).danger) == a.n_("danger_step") and a.raw_survival(parent, w) > 0,
			"danger: an assault on one's own child puts the parent under pressure (%d)" % int(a.survival_parts(parent, w).danger))
	# a theft from the household counts less; the level is capped
	j.publish("theft", [thug.id], [parent.id], [], 5)
	check(int(a.survival_parts(parent, w).danger) == a.n_("danger_step") + a.n_("theft_step"), "danger: a theft from the household adds theft_step")
	for i in 6:
		j.publish("assault", [thug.id], [child.id], [], 0)
	check(int(a.survival_parts(parent, w).danger) == 1000, "danger: capped at 1000")
	# past danger_days the harm no longer counts as present danger
	var w2 := world()
	var a2 := asp_on(w2)
	var p2: NPC = w2.npc(parent.id)
	w2.judgment.publish("assault", [thug.id], [child.id], [], 0)
	check(int(a2.survival_parts(p2, w2).danger) > 0, "danger: (fresh harm counts)")
	w2.minutes += float(a2.n_("danger_days") + 1) * 1440.0
	w2.judgment.day = w2.day()
	check(int(a2.survival_parts(p2, w2).danger) == 0, "danger: harm older than danger_days no longer counts")
	w2.dispose()
	w.dispose()


# ---------------------------------------------------------------- V2 ------------------------------
## Parents keep protecting the children when hungry themselves (FAMILY-01 unchanged); the hunger shows instead as more
## willingness to take paid work.
func test_v2_hungry_parent_protects() -> void:
	var traces := []
	var defer := []
	var margins := []
	for aspire in [false, true]:
		var fam := family(aspire)
		var w: World = fam.w
		var f: NPC = fam.F
		pantry(fam, 2)
		for k in ["K1", "K2", "O"]:
			(fam[k] as NPC).hunger = 30.0
		for k in ["M", "G", "G2"]:
			(fam[k] as NPC).hunger = 90.0
		f.hunger = 40.0
		if aspire:
			w.judgment.asp.dawn(w)
			check(w.judgment.asp.rows.has(f.id), "V2: the hungry father has aspirations")
		defer.append(JudgmentFamily.defers(w, f, "pantry"))
		traces.append(last_family_trace(w))
		# paid work offered by a neighbour: accept against doing without
		var cand := {"id": "accept", "counterparty": (fam.M as NPC).id, "factors": {"necessity": 0, "wage": 100000}}
		var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, f.id, "work_accept", [cand], [w.day(), 1])
		var ua := 0
		var uf := 0
		for row in r.trace:
			if str(row.id) == "accept":
				ua = int(row.utility)
			elif str(row.id) == "forgo":
				uf = int(row.utility)
		margins.append(ua - uf)
		w.dispose()
	check(defer[0] and defer[1], "V2: father hungry (40), children hungrier, pantry short: he gives way to them with aspirations off and on")
	check(traces[0] == traces[1] and traces[0] != "", "V2: the family_meal weighing is identical with aspirations on (no aspiration factor, no survival pressure in it)")
	check(margins[1] > margins[0], "V2: with aspirations on the hungry father is readier to take paid work (margin %d > %d)" % [margins[1], margins[0]])


# ---------------------------------------------------------------- V3 ------------------------------
## A surviving parent does not sacrifice themselves needlessly: at the survival floor they eat, and a badly hurt head may
## flee from a danger, whatever the aspirations say.
func test_v3_no_needless_sacrifice() -> void:
	for lead in ["food", "family"]:
		var fam := family(true)
		var w: World = fam.w
		var a: JudgmentAspiration = w.judgment.asp
		var f: NPC = fam.F
		pantry(fam, 2)
		for k in ["K1", "K2", "O", "M", "G", "G2"]:
			(fam[k] as NPC).hunger = 30.0
		f.hunger = 25.0
		a.dawn(w)
		if lead == "family":
			set_row(a, f, [100000, 100000, 100000, 100000, 0, 100000])          # a family-led ambition
		check(not JudgmentFamily.defers(w, f, "pantry"), "V3: %s-led father at the survival floor (25) eats (self_floor), the children still hungry" % lead)
		check(last_family_trace(w).contains("self_floor"), "V3: ...the floor is the recorded reason")
		w.dispose()
	# danger: a head under the health floor, a bandit near the children: flee stays available and is taken
	for aspire in [false, true]:
		var fam := family(aspire)
		var w: World = fam.w
		var j: JudgmentStore = w.judgment
		j.cfg.traits.stubbornness_share_permille = 0
		j.pers.configure(j.cfg.traits)
		var foe: NPC = null
		for n: NPC in w.npcs:
			if n.alive and n.role == "bandit":
				foe = n
				break
		var at := open_cell(w)
		for k in ["F", "K1", "K2", "M"]:
			var n: NPC = fam[k]
			n.pos = at + Vector2(float(["F", "K1", "K2", "M"].find(k)) * 0.4, 0.0)
			n.depth = 0
			n.anim = "idle"
			n.plan = []
			n.target = -1
			n.report = {}
		for g: NPC in w.npcs:
			if g.job == "guard":
				g.pos = at + Vector2(300.0, 0.0)
		foe.pos = at + Vector2(5.0, 0.0)
		foe.depth = 0
		w.minutes = 8.0 * 1440.0 + 12 * 60.0
		j.threat_cache = {}
		(fam.F as NPC).hp = 4.0
		if aspire:
			j.asp.dawn(w)
		check(JudgmentFamily.danger(w, fam.F) and (fam.F as NPC).doing == "running from danger",
				"V3: aspirations %s: a head under the health floor runs rather than die (a sacrifice is not a suicide)" % ("on" if aspire else "off"))
		w.dispose()


func open_cell(w: World) -> Vector2:
	var sp = w.map.data.spawns.player
	for r in range(0, 14):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := Vector2i(int(sp[0]) + dx, int(sp[1]) + dy)
				if absi(dx) != r and absi(dy) != r:
					continue
				var p := Vector2(c) + Vector2(0.5, 0.5)
				if not w.map.is_solid(c) and w.place_of(p) == "":
					return p
	return Vector2(sp[0], sp[1])


# ---------------------------------------------------------------- V4 ------------------------------
## Career ambitions influence job choices without ignoring economic necessity (FAD Q2: the blacksmith).
func test_v4_job_choice() -> void:
	var w := world()
	var j: JudgmentStore = w.judgment
	check(not JudgmentLive.on(w, "job_choice"), "V4: shipped: job_choice off")
	j.cfg.decision.integration.job_choice = true
	check(not JudgmentLive.on(w, "job_choice"), "V4: the job_choice flag alone, with aspirations off, is refused (no ambition to weigh)")
	var a := asp_on(w)
	check(JudgmentLive.on(w, "job_choice"), "V4: both on: job_choice consults the weighing")
	var n: NPC = adults(w)[0]
	n.hunger = 100.0
	n.hp = n.max_hp
	n.job = "smith"
	n.job_since = w.day() - 40
	n.skills = {"smithing": Skills.xp_for_level(6)}
	var opts := [["manor_hand", 11.0]]                             # 10% better than the 10 coins a day the smith earns
	n.coins = 60
	check(JudgmentLive.pick_job(w, n, opts, false, 10.0, "manor_hand", false, {"streak": 0}) == "",
			"V4: a skilled smith (level 6) stays at the forge rather than take a 10%% better-paid post")
	n.coins = 40
	check(JudgmentLive.pick_job(w, n, opts, false, 10.0, "manor_hand", false, {"streak": 1}) == "",
			"V4: ...also in mild hardship (40 coins, one bad day)")
	n.coins = 0
	check(JudgmentLive.pick_job(w, n, opts, false, 10.0, "manor_hand", false, {"streak": 8}) == "manor_hand",
			"V4: the same smith in severe hardship (no coins, eight unsustainable days) switches")
	var u: NPC = adults(w)[1]
	u.hunger = 100.0
	u.hp = u.max_hp
	u.job = "woodcutter"
	u.job_since = w.day()
	u.skills = {}
	u.coins = 40
	check(JudgmentLive.pick_job(w, u, opts, false, 10.0, "manor_hand", false, {"streak": 1}) == "manor_hand",
			"V4: an unskilled woodcutter just started switches in the same mild hardship")
	# survival pressure lowers the career ambition: a starving smith takes the pay sooner
	n.coins = 40
	n.hunger = 25.0
	check(JudgmentLive.pick_job(w, n, opts, false, 10.0, "manor_hand", false, {"streak": 3}) == "manor_hand",
			"V4: a starving smith (profession priority yielding) takes the paid post in moderate hardship")
	n.hunger = 100.0
	# unemployed: never 'stay'; the live rule's best stands when the career factors are equal
	u.job = ""
	check(JudgmentLive.pick_job(w, u, [["farmer", 8.0], ["manor_hand", 9.0]], true, 0.0, "manor_hand", true, {"streak": 0}) == "manor_hand",
			"V4: out of work with nothing to tell the options apart, the live rule's best stands")
	w.dispose()
	# flag off: seek_work exactly as the live rule (the flag set but aspirations off changes nothing)
	var hashes := []
	for k in 2:
		var x := world(2)
		if k == 1:
			x.judgment.cfg.decision.integration.job_choice = true
		for d in 2:
			x.brain.dawn()
		var jobs := []
		for o: NPC in x.npcs:
			jobs.append([o.id, o.job, o.job_since])
		hashes.append(JSON.stringify(jobs).hash())
		x.dispose()
	check(hashes[0] == hashes[1], "V4: flags off: the live seek_work gives the same jobs")


# ---------------------------------------------------------------- V5 ------------------------------
## Romantic preferences genuinely vary among individuals (FAD Q3).
func test_v5_romance() -> void:
	var w := world()
	var a := asp_on(w)
	var j: JudgmentStore = w.judgment
	var ps := adults(w)
	var ch := [ps[0], ps[1], ps[2]]
	var x1: NPC = ps[3]
	var x2: NPC = ps[4]
	var x3: NPC = ps[5]
	for n: NPC in ch + [x1, x2, x3]:
		n.hunger = 100.0
		n.hp = n.max_hp
		n.coins = 0
	# separate households for the three candidates and the choosers (purses and security from their own)
	var hx := {}
	for x: NPC in [x1, x2, x3]:
		hx[x.id] = x.household
	var econ_poor := {"sustainable": false, "days": 0.0, "streak": 5, "cost": 10.0, "adults": 1}
	var econ_rich := {"sustainable": true, "days": 20.0, "streak": 0, "cost": 10.0, "adults": 1}
	for n: NPC in ch + [x1, x2, x3]:
		w.brain._lodge(n, w.households.size() - 1 - (ch + [x1, x2, x3]).find(n))
	for n: NPC in ch + [x1, x2, x3]:
		for m in w.households[n.household].members:
			if int(m) != n.id:
				var o: NPC = w.npc(int(m))
				if o != null:
					o.coins = 0
	w.households[x1.household].econ = econ_poor.duplicate()
	w.households[x3.household].econ = econ_poor.duplicate()
	w.households[x2.household].econ = econ_rich.duplicate()
	x2.coins = 300
	x1.job = ""
	x2.job = "farmer"
	x2.job_since = w.day() - 40
	x3.job = "farmer"
	x3.job_since = w.day() - 40
	for x: NPC in [x1, x2, x3]:
		set_row(a, x, [50000, 50000, 80000 if x == x2 else 0, 50000, 50000, 50000])
		a.rows[x.id].lead = -1
	var low := [-300, -300, -300, -300, -300, -300]
	set_row(a, ch[0], [50000, 50000, 50000, 50000, 50000, 50000], low)                         # attraction-led
	set_row(a, ch[1], [50000, 50000, 50000, 50000, 50000, 50000], [300, 300, 300, 0, 0, 0])     # security and wealth
	set_row(a, ch[2], [50000, 50000, 50000, 50000, 50000, 50000], [-300, -300, -300, 0, 0, 0])  # overlooks wealth
	for n: NPC in ch:
		a.rows[n.id].lead = -1
	var t: Dictionary = w.relations.tie(ch[2].id, x3.id)
	t.regard = 90.0
	t.days_known = 16
	j.set_ledger(ch[2].id, x3.id, 30000, 0)                    # ch2 thinks well of x3
	var attraction := {x1.id: 100.0, x2.id: 50.0, x3.id: 50.0}
	var picks := []
	for n: NPC in ch:
		var p: NPC = JudgmentLive.pick_court(w, n, [x1, x2, x3], attraction)
		picks.append(p.id if p != null else -1)
	check(picks[0] == x1.id, "V5: an attraction-led villager courts the most attractive (%s)" % str(picks))
	check(picks[1] == x2.id, "V5: a villager who puts security and wealth first courts the secure, well-off one")
	check(picks[2] == x3.id, "V5: a villager with little care for wealth and an established bond courts the poor, well-liked one")
	check(picks[0] != picks[1] and picks[1] != picks[2] and picks[0] != picks[2], "V5: the same pool, three different choices")
	# no fixed wealth requirement: the poor candidates were weighed, never removed
	var r := JudgmentWeighting.choose(j, j.cfg, ch[1].id, "court_choice",
			[{"id": x1.id, "counterparty": x1.id, "factors": JudgmentLive.court_factors(w, ch[1], x1).merged({"attraction": 100000})}], [w.day(), 9])
	check(r.chosen == x1.id, "V5: a poor candidate alone in the pool is still chosen (no wealth gate)")
	# per-person spread: two villagers in the same state weigh the same factor differently
	j.cfg.decision.trait_spread_permille = 300
	var diff := false
	for i in range(1, ps.size()):
		if JudgmentWeighting.trait_weight(j.cfg, j.world_seed, ps[0].id, "security", 100, j) != JudgmentWeighting.trait_weight(j.cfg, j.world_seed, ps[i].id, "security", 100, j):
			diff = true
			break
	check(diff, "V5: the shipped per-person spread makes villagers weigh the same quality differently")
	j.cfg.decision.trait_spread_permille = 0
	# kinship and players: the live rules are untouched
	var parent: NPC = null
	var child: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.mother >= 0 and w.npc(o.mother) != null and w.npc(o.mother).alive:
			child = o
			parent = w.npc(o.mother)
			break
	if parent != null:
		check(not w.relations.can_court(parent.id, child.id), "V5: kin (mother and child) can never court (Relations.can_court, unchanged)")
	var pool_has_player := false
	for o in [x1, x2, x3]:
		pool_has_player = pool_has_player or Life.is_player_id(o.id)
	check(not pool_has_player and picks.all(func(p): return not Life.is_player_id(int(p))), "V5: no player is ever chosen by an NPC")
	w.dispose()


# ---------------------------------------------------------------- WDR-011-Q8 (answer A) ---------------
## Owner 2026-10-27 (D39): a villager's own romance preferences also decide whether they accept an eligible proposal. Hard
## limits come first and cannot be weighed away; a player's consent is never decided by an NPC; no financial cutoff.
func q8_world(aspire: bool) -> Dictionary:
	var w := world(6)
	var rel: Relations = w.relations
	var singles := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner == -1 and rel.willing(n) and n.job != "guard" and n.household >= 0:
			singles.append(n)
	var pick := []
	for cand: NPC in singles:
		var ok := []
		for o: NPC in singles:
			if o != cand and rel.can_court(cand.id, o.id):
				ok.append(o)
		for i in ok.size():
			for k in range(i + 1, ok.size()):
				if pick.is_empty():
					pick = [cand, ok[i], ok[k]]
	var st := {"w": w, "s": pick[0], "n1": pick[1], "n2": pick[2]}
	if aspire:
		asp_on(w)
	var sx: NPC = st.s
	var n1: NPC = st.n1
	var n2: NPC = st.n2
	for n: NPC in [sx, n1, n2]:
		w.brain._lodge(n, w.households.size() - 1 - [sx, n1, n2].find(n))
	for n: NPC in [sx, n1, n2]:
		for m in w.households[n.household].members:
			w.npc(int(m)).coins = 0
		n.hunger = 100.0
		n.hp = n.max_hp
	sx.job = ""
	n1.coins = 500                                                   # a well-off household
	w.households[sx.household].econ = {"sustainable": false, "days": 0.0, "streak": 5, "cost": 10.0, "adults": 1}
	w.households[n1.household].econ = {"sustainable": true, "days": 20.0, "streak": 0, "cost": 10.0, "adults": 1}
	w.households[n2.household].econ = {"sustainable": false, "days": 2.0, "streak": 2, "cost": 10.0, "adults": 1}
	for n: NPC in [sx, n1, n2]:
		var t: Dictionary = w.relations.tie(sx.id, n.id) if n != sx else {}
		if n != sx:
			t.stage = "courting"
			t.since = w.day() - 10
			t.attraction = 70.0
			t.regard = 30.0
			t.days_known = 13
	if aspire:
		var a: JudgmentAspiration = w.judgment.asp
		set_row(a, sx, [50000, 50000, 0, 50000, 0, 50000])
		a.rows[sx.id].lead = A.FAMILY
		set_row(a, n1, [50000, 0, 50000, 50000, 50000, 50000], [300, 300, 300, 0, 0, 0])     # security and wealth first
		a.rows[n1.id].lead = A.WEALTH
		set_row(a, n2, [50000, 50000, 50000, 50000, 0, 50000], [0, -300, 0, 0, 0, 0])        # cares little for wealth
		a.rows[n2.id].lead = A.FAMILY
	w.judgment.set_ledger(n2.id, sx.id, 30000, 0)                    # n2 is fond of the suitor; n1 has no opinion of them
	return st


func test_q8_proposals() -> void:
	# flags off: the live rule accepts both (the eligible proposal is accepted whatever the villager values)
	var off := q8_world(false)
	check(off.w.relations.propose(off.s.id, off.n1) == "", "Q8: flags off: the live rule accepts the eligible proposal (no preference weighed)")
	check(int(off.w.judgment.stats.get("proposal_weighed", 0)) == 0, "Q8: flags off: nothing weighed")
	off.w.dispose()
	var on := q8_world(true)
	var w: World = on.w
	var r1: String = w.relations.propose(on.s.id, on.n1)
	var r2: String = w.relations.propose(on.s.id, on.n2)
	check(r1 != "" and w.relations.peek(on.s.id, on.n1.id).refused, "Q8: a well-off villager who puts security first and has no opinion of the poor suitor refuses (%s)" % r1)
	check(r2 == "" and (on.n2 as NPC).partner == (on.s as NPC).id, "Q8: the same suitor's proposal is accepted by a poor villager who is fond of them and shares their ambition")
	check(int(w.judgment.stats.get("proposal_weighed", 0)) == 2, "Q8: both eligible proposals went through the one weighing (JudgmentWeighting.choose)")
	w.dispose()
	# no financial cutoff: the same poor suitor, but the security-minded villager now thinks well of them and shares the ambition
	var on2 := q8_world(true)
	on2.w.judgment.set_ledger(on2.n1.id, on2.s.id, 40000, 0)
	on2.w.judgment.asp.rows[on2.n1.id].lead = A.FAMILY
	check(on2.w.relations.propose(on2.s.id, on2.n1) == "", "Q8: no wealth cutoff: fondness and a shared plan outweigh the suitor's poverty for the same villager")
	on2.w.dispose()
	# hard limits first: kinship, an existing partner, too soon; weighting cannot overrule them
	var hl := q8_world(true)
	w = hl.w
	var j: JudgmentStore = w.judgment
	var parent: NPC = hl.s
	var child: NPC = hl.n2
	child.mother = parent.id                                         # the suitor is made the second villager's mother: kin
	parent.children.append(child.id)
	Life.kin_version += 1
	check(not w.relations.can_court(parent.id, child.id), "Q8: (mother and grown child are kin: Relations.can_court refuses)")
	if true:
		var tk: Dictionary = w.relations.tie(parent.id, child.id)
		tk.stage = "courting"
		tk.since = w.day() - 30
		tk.attraction = 100.0
		tk.regard = 100.0
		tk.days_known = 40
		j.set_ledger(child.id, parent.id, 100000, 0)
		check(w.relations.propose(parent.id, child) == "We aren't courting." and child.partner != parent.id, "Q8: kin can never marry, however the preferences weigh")
	var n1: NPC = hl.n1
	var sx: NPC = hl.s
	n1.partner = (hl.n2 as NPC).id
	j.set_ledger(n1.id, sx.id, 100000, 0)
	check(w.relations.propose(sx.id, n1) == "We aren't courting.", "Q8: someone already partnered cannot be married, however fond")
	n1.partner = -1
	var t1: Dictionary = w.relations.tie(sx.id, n1.id)
	t1.since = w.day() - 1
	check(w.relations.propose(sx.id, n1).begins_with("It's too soon"), "Q8: courtship still needs its separate days: too soon is too soon")
	check(int(j.stats.get("proposal_weighed", 0)) == 0, "Q8: none of these reached the weighing")
	w.dispose()



## PROP-EQ (D39 follow-up, WDR-012): a player's proposal to a villager, set up as test_q8_proposals' suitor: courting, eligible.
func q8_player(aspire: bool) -> Dictionary:
	var st := q8_world(aspire)
	var w: World = st.w
	var pl: PlayerState = w.player
	var pid := w.person_id(pl)
	pl.coins = 0
	pl.partner = -1
	for n: NPC in [st.n1, st.n2]:
		var t: Dictionary = w.relations.tie(pid, n.id)
		t.stage = "courting"
		t.since = w.day() - 10
		t.attraction = 70.0
		t.regard = 30.0
		t.days_known = 13
	w.judgment.set_ledger(st.n2.id, pid, 30000, 0)                  # n2 is fond of the player; n1 has no opinion of them
	st.pl = pl
	st.pid = pid
	return st


func test_q8_player_proposals() -> void:
	# flags off: the live rule answers a player's proposal, nothing weighed (unchanged)
	var res := []
	for aspire in [false, true]:
		var pw := q8_player(aspire)
		res.append([pw.w.relations.propose(pw.pid, pw.n2), int(pw.w.judgment.stats.get("proposal_weighed", 0))])
		pw.w.dispose()
	check(int(res[0][1]) == 0, "PROP-EQ: flags off: a player's proposal is answered by the live rule, never weighed (%s)" % str(res[0]))
	check(int(res[1][1]) == 1, "PROP-EQ: aspirations on: a player's eligible proposal goes through the same weighing as a villager's")
	# the player read in their own form: the same factors as a villager in the same position
	var q := q8_player(true)
	var w: World = q.w
	var n1: NPC = q.n1
	var twin: NPC = q.s                                               # a villager made the player's equal: no household, the
	twin.household = -1                                               # same purse, no trade, no parents, no aspiration row,
	twin.coins = q.pl.coins                                           # the same tie and the same opinion held of them
	twin.job = ""
	twin.mother = -1
	twin.father = -1
	q.pl.mother = -1
	q.pl.father = -1
	w.judgment.asp.rows.erase(twin.id)
	var tt: Dictionary = w.relations.tie(twin.id, n1.id)
	var tp: Dictionary = w.relations.tie(q.pid, n1.id)
	for k in ["attraction", "regard", "days_known"]:
		tt[k] = tp[k]
	var fp := JudgmentLive.court_factors(w, n1, q.pl)
	var fv := JudgmentLive.court_factors(w, n1, twin)
	var same := true
	for k in fv:
		if k != "standing" and fv[k] != fp[k]:
			same = false
			print("  differs: %s player %s villager %s" % [k, fp[k], fv[k]])
	check(same, "PROP-EQ: a player and a villager in the same position have the same courting factors (%s)" % JSON.stringify(fp))
	check(int(fp.standing) == w.judgment.asp.standing_excluding(q.pid, n1.id), "PROP-EQ: the player's standing is everyone else's opinion of the player, by their person id")
	# the player's own parents and purse are read
	var mom: NPC = q.n2
	q.pl.mother = mom.id
	w.judgment.set_ledger(n1.id, mom.id, 10000, 0)
	var fm := JudgmentLive.court_factors(w, n1, q.pl)
	check(int(fm.family_compat) == w.judgment.personal_disposition(n1.id, mom.id), "PROP-EQ: the player's mother counts in family compatibility as a villager's would")
	q.pl.mother = -1
	q.pl.coins = 5000
	check(int(JudgmentLive.court_factors(w, n1, q.pl).wealth) > int(fp.wealth), "PROP-EQ: the player's purse is the player's wealth")
	w.dispose()
	# preferences decide a player's eligible proposal as a villager's: refused by the security-minded villager who has no
	# opinion of a poor suitor; the player's own consent is never touched
	var r := q8_player(true)
	var a1: String = r.w.relations.propose(r.pid, r.n1)
	check(a1 != "" and r.w.relations.peek(r.pid, r.n1.id).refused and r.pl.partner == -1 and (r.n1 as NPC).partner == -1,
			"PROP-EQ: the security-minded villager refuses the poor player as they refuse a poor villager (%s)" % a1)
	r.w.dispose()
	var r2 := q8_player(true)
	r2.w.judgment.set_ledger(r2.n1.id, r2.pid, 40000, 0)
	r2.pl.coins = 600
	var a2: String = r2.w.relations.propose(r2.pid, r2.n1)
	check(a2 == "" and (r2.n1 as NPC).partner == r2.pid, "PROP-EQ: the same villager accepts a player they think well of and who can keep a home (%s)" % a2)
	r2.w.dispose()
	# hard limits first, for a player too: too soon, kinship
	var h := q8_player(true)
	(h.w.relations.tie(h.pid, h.n1.id) as Dictionary).since = h.w.day() - 1
	check(h.w.relations.propose(h.pid, h.n1).begins_with("It's too soon"), "PROP-EQ: a player's courtship still needs its separate days")
	h.pl.mother = (h.n2 as NPC).id
	(h.n2 as NPC).children.append(h.pid)
	Life.kin_version += 1
	check(h.w.relations.propose(h.pid, h.n2) == "We aren't courting.", "PROP-EQ: kin can never marry a player, however the preferences weigh")
	check(int(h.w.judgment.stats.get("proposal_weighed", 0)) == 0, "PROP-EQ: none of these reached the weighing")
	h.w.dispose()

# ---------------------------------------------------------------- V6 ------------------------------
## Stubbornness influences perseverance; wisdom speeds adaptation; repeated setbacks change even a stubborn villager.
func test_v6_perseverance() -> void:
	var w := world()
	var a := asp_on(w)
	var j: JudgmentStore = w.judgment
	var stub: NPC = null
	var plain: NPC = null
	var wise: NPC = null
	for o: NPC in adults(w):
		if j.pers.stubbornness(o.id, w.day()) > 0:
			if stub == null:
				stub = o
		elif not j.pers.holds_stubbornness(o.id):
			if plain == null:
				plain = o
			elif wise == null:
				wise = o
	j.pers.wisdom[wise.id] = {0: 400}
	var d := w.day()
	for n: NPC in [stub, plain, wise]:
		a.rows[n.id] = a._new_row()
		a.setback(w, n, A.WEALTH, d, "setback")
	var s0 := int(a.rows[stub.id].shift[A.WEALTH])
	var p0 := int(a.rows[plain.id].shift[A.WEALTH])
	var w0 := int(a.rows[wise.id].shift[A.WEALTH])
	check(s0 > 0, "V6: the same setback: the stubborn villager's wealth priority rises (+%d: perseveres)" % s0)
	check(p0 < 0, "V6: ...a plain villager's falls (%d: adapts, another ambition takes over)" % p0)
	check(w0 < p0, "V6: ...faster with wisdom (%d < %d)" % [w0, p0])
	a.setback(w, stub, A.WEALTH, d + 1, "setback")
	var s1 := int(a.rows[stub.id].shift[A.WEALTH])
	check(s1 > s0, "V6: a second setback: the stubborn one still perseveres")
	a.setback(w, stub, A.WEALTH, d + 2, "setback")
	var s2 := int(a.rows[stub.id].shift[A.WEALTH])
	check(s2 < s1, "V6: the third setback within the window (3 in 8 days): even the stubborn villager changes course (%d -> %d)" % [s1, s2])
	var x := stub
	a.rows[x.id] = a._new_row()
	a.setback(w, x, A.WEALTH, d, "setback")
	a.setback(w, x, A.WEALTH, d + 9, "setback")
	a.setback(w, x, A.WEALTH, d + 18, "setback")
	check(int(a.rows[x.id].shift[A.WEALTH]) > 0, "V6: setbacks spread over years do not exhaust a stubborn villager")
	# bounded: never beyond max_shift
	for i in 20:
		a.setback(w, plain, A.FAMILY, d + i * 9, "setback")
	check(absi(int(a.rows[plain.id].shift[A.FAMILY])) <= a.n_("max_shift"), "V6: shifts stay within +/- max_shift")
	# the loss of a family member is a setback met by personality
	var before := int(a.rows[plain.id].shift[A.FAMILY])
	a.on_loss(w, plain.id)
	check(int(a.rows[plain.id].shift[A.FAMILY]) <= before, "V6: a bereavement is met as a setback (family)")
	w.dispose()


# ---------------------------------------------------------------- V7 ------------------------------
## Social standing works without double counting judgment (FAD Q6).
func test_v7_standing() -> void:
	var w := world()
	var a := asp_on(w)
	var j: JudgmentStore = w.judgment
	var ps := adults(w)
	var ch: NPC = ps[0]
	var x: NPC = ps[1]
	var o1: NPC = ps[2]
	var o2: NPC = ps[3]
	var mid := int(j.cfg.decision.disposition_mid)
	check(a.standing_value(x.id) == mid, "V7: nobody holds a judgment of x: standing is the midpoint")
	j.set_ledger(o1.id, x.id, 20000, 0)
	j.set_ledger(o2.id, x.id, 0, 10000)
	j.set_ledger(ch.id, x.id, 40000, 0)
	var expect := mid + (20000 - 10000 + 40000) / 3 + 3 * a.n_("recognition_step")
	check(a.standing_value(x.id) == expect, "V7: actual standing = the mean of others' personal judgments + recognition (%d)" % expect)
	check(a.standing_excluding(x.id, ch.id) == mid + (20000 - 10000) / 2 + 2 * a.n_("recognition_step"), "V7: in the chooser's decision the chooser's own entry is left out")
	# court_choice: the chooser's own ledger moves disposition only
	var rows := []
	for give in [true, false]:
		j.set_ledger(ch.id, x.id, 40000 if give else 0, 0)
		var f := JudgmentLive.court_factors(w, ch, x).merged({"attraction": 60000})
		var r := JudgmentWeighting.choose(j, j.cfg, ch.id, "court_choice", [{"id": x.id, "counterparty": x.id, "factors": f}], [w.day(), 3])
		rows.append(r.trace[0])
	check(int(rows[0].factors.standing) == int(rows[1].factors.standing), "V7: the chooser's own judgment of x does not move the standing factor (%d)" % int(rows[0].factors.standing))
	check(int(rows[0].factors.disposition) != int(rows[1].factors.disposition), "V7: ...it moves disposition, where it belongs")
	# family colour never enters standing: o1 judges x's parent harshly; that colours o1's disposition of x only
	var par: NPC = w.npc(x.mother) if x.mother >= 0 else null
	if par == null:
		par = ps[4]
		x.mother = par.id
		par.children.append(x.id)
		Life.kin_version += 1
	j.set_ledger(o1.id, par.id, 0, 60000)
	var col := j.colour(o1.id, x.id)
	var st := a.standing_value(x.id)
	j.set_ledger(o1.id, par.id, 0, 0)
	check(st == a.standing_value(x.id), "V7: a family name's colour (%d on o1's view of x) does not move x's standing" % col)
	# the standing ambition: only deeds the judgment system scores serve it
	var fw: Dictionary = a.c.factor_weights
	for p in fw:
		var sf = a.c.fit[p].standing
		check((int(sf) != 0) == (p in ["family_help", "contract_accept"]), "V7: standing fit in %s is %s" % [p, str(sf)])
	set_row(a, ch, [100000, 100000, 100000, 100000, 100000, 0])
	check(int(a.factor(ch.id, "family_help", null, w).value) > mid and int(a.factor(ch.id, "contract_accept", null, w).value) > mid, "V7: a standing-led villager leans to help a relative's home and to take (and keep) a contract")
	check(int(a.factor(ch.id, "credit_lend", null, w).value) == mid and int(a.factor(ch.id, "work_accept", null, w).value) == mid, "V7: ...and nowhere else")
	w.dispose()


# ---------------------------------------------------------------- V8 ------------------------------
## All six domains persist through save and load; old sections load without a false crossing; unknown columns are kept.
func test_v8_save_load() -> void:
	var w := world()
	var a := asp_on(w)
	var j: JudgmentStore = w.judgment
	a.dawn(w)
	var n: NPC = adults(w)[0]
	a.setback(w, n, A.PROFESSION, w.day(), "setback")
	a.rows[n.id].shift[A.STANDING] = 120
	a.rows[n.id].surv = 600
	var d := j.to_dict()
	check(int(d.version) == JudgmentStore.ASPIRE_VERSION and d.has("aspire") and (d.aspire.domains as Array) == A.DOMAINS, "V8: the judgment section carries aspire, version 4, six named domains")
	var text := JSON.stringify(d)
	var k := JudgmentStore.new(j.cfg, JudgmentSocial.new(), j.world_seed)
	k.world = w
	check(k.load_dict(JSON.parse_string(text)) == "", "V8: it loads")
	check(JSON.stringify(k.to_dict()) == text, "V8: and saves byte-identically")
	for d2 in A.ND:
		check(int(k.asp.rows[n.id].shift[d2]) == int(a.rows[n.id].shift[d2]) and int(k.asp.rows[n.id].band[d2]) == int(a.rows[n.id].band[d2])
				and int(k.asp.rows[n.id].sat[d2]) == int(a.rows[n.id].sat[d2]), "V8: %s: shift, band and satisfaction kept" % A.DOMAINS[d2])
	check(int(k.asp.rows[n.id].lead) == int(a.rows[n.id].lead) and int(k.asp.rows[n.id].surv) == 600 and k.asp.rows[n.id].set == a.rows[n.id].set, "V8: the lead, survival level and setbacks kept")
	var w_store: JudgmentStore = w.judgment
	var f1 := a.factor(n.id, "work_accept", null, w)
	w.judgment = k
	var f2 := k.asp.factor(n.id, "work_accept", null, w)
	w.judgment = w_store
	check(JSON.stringify(f1) == JSON.stringify(f2), "V8: the next choice reads the same aspiration factor after loading")
	# a whole world, mid-scenario
	var wd := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(wd)))
	check(w2.judgment != null and not w2.judgment.asp.enabled, "V8: a loaded world uses the shipped switch (off)")
	check(JSON.stringify(w2.to_dict().judgment.aspire) == JSON.stringify(JSON.parse_string(JSON.stringify(wd)).judgment.aspire), "V8: ...and with the layer off its aspire section is carried unchanged, never dropped")
	w2.dispose()
	# unknown column carried through
	var dd: Dictionary = JSON.parse_string(text)
	dd.aspire.domains.append("faith")
	for row in dd.aspire.rows:
		row[1].append(77)
		row[2].append(2)
		row[3].append(44000)
		row[6].append([5])
	var u := JudgmentStore.new(j.cfg, JudgmentSocial.new(), j.world_seed)
	u.world = w
	check(u.load_dict(dd) == "" and u.asp.foreign_names == ["faith"], "V8: a domain this game does not know loads beside the six")
	var back: Dictionary = u.to_dict()
	check((back.aspire.domains as Array).has("faith") and int(back.aspire.rows[0][1][6]) == 77 and (back.aspire.rows[0][6][6] as Array) == [5], "V8: ...and is written back, never dropped")
	# the Build 22 save (judgment version 2): no rows, no false crossing at the first dawn
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/b22_save_v23_single.json"))
	check(int(fx.judgment.version) == 2 and not fx.judgment.has("aspire"), "V8: fixture b22_save_v23_single: judgment section version 2, no aspire")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), fx)
	check(int(w3.to_dict().judgment.version) == 3 and not w3.to_dict().judgment.has("aspire"), "V8: with the layer off it re-saves as version 3 with nothing invented")
	var a3 := asp_on(w3, false)
	a3.dawn(w3)
	var st: Dictionary = w3.judgment.stats
	check(int(st.get("aspire_success", 0)) == 0 and int(st.get("aspire_setback", 0)) == 0 and not a3.rows.is_empty(), "V8: switched on, its first dawn sets the bands without counting a crossing (%d rows)" % a3.rows.size())
	var none := true
	for p in a3.rows:
		none = none and a3.rows[p].shift == [0, 0, 0, 0, 0, 0]
	check(none, "V8: ...no priority shift from loading")
	check(int(w3.to_dict().judgment.version) == 4, "V8: it then saves as version 4")
	w3.dispose()
	w.dispose()


# ---------------------------------------------------------------- V9 ------------------------------
## Aspirations disabled produce the established baseline (G0, tools/sim_gate.py, is the world-level proof).
func test_v9_disabled_is_baseline() -> void:
	var w := world(3)
	var j: JudgmentStore = w.judgment
	check(not j.asp.enabled, "V9: shipped off")
	var tr := []
	for prof in ["work_accept", "contract_accept", "credit_lend", "barter_accept", "family_help"]:
		var r := JudgmentWeighting.choose(j, j.cfg, adults(w)[0].id, prof, [{"id": "yes", "counterparty": adults(w)[1].id, "factors": {"live_order": 100000, "necessity": 0}}], [1])
		tr.append(r)
	var clean := true
	for r in tr:
		var s := JSON.stringify(r)
		clean = clean and not s.contains("aspiration") and not s.contains("scale")
	check(clean, "V9: off: no aspiration factor, offset or scaling in any profile's trace")
	var base := JSON.stringify(j.cfg.decision.profiles.court_choice)
	var r2 := JudgmentWeighting.choose(j, j.cfg, adults(w)[0].id, "court_choice", [{"id": 1, "counterparty": adults(w)[1].id, "factors": {"attraction": 60000}}], [1])
	check((r2.trace[0].contributions as Dictionary).keys().size() == 2 and JSON.stringify(j.cfg.decision.profiles.court_choice) == base, "V9: off: court_choice weighs attraction and disposition only, as before")
	for i in 3:
		w.brain.dawn()
	check(int(j.stats.get("aspire_dawns", 0)) == 0 and j.asp.rows.is_empty(), "V9: off: the dawn update never runs")
	var d := j.to_dict()
	check(int(d.version) == 3 and not d.has("aspire"), "V9: off: the judgment section is version 3 without aspire (as before R5)")
	# the same village with the layer's object present but off writes the same bytes as one whose flags were never read
	var x := world(3)
	x.judgment.cfg.decision.integration.job_choice = true            # set, but refused while aspirations are off
	var y := world(3)
	for k in 2:
		x.brain.dawn()
		y.brain.dawn()
	check(JSON.stringify(x.to_dict()).md5_text() == JSON.stringify(y.to_dict()).md5_text(), "V9: off: two villages, one with job_choice set and refused, save the same bytes")
	x.dispose()
	y.dispose()
	w.dispose()


# ---------------------------------------------------------------- V10 -----------------------------
## Enabling aspirations never creates coins, food, items or other resources.
func test_v10_no_resources() -> void:
	var w := world(4)
	var a := asp_on(w, false)
	w.judgment.cfg.decision.integration.job_choice = true
	# the layer itself is a pure read: a dawn update and every factor leave every coin and good where it was
	var coins0 := w.total_coins()
	var goods0 := Census.goods(w)
	a.dawn(w)
	for n: NPC in adults(w):
		for p in ["work_accept", "contract_accept", "credit_lend", "barter_accept", "family_help"]:
			a.factor(n.id, p, null, w)
		a.standing_value(n.id)
	check(w.total_coins() == coins0 and JSON.stringify(Census.goods(w)) == JSON.stringify(goods0), "V10: the aspiration update and its factors move no coin and no good")
	# a village living with it: the currency still balances against what came in from outside
	var stats0 := w.stats.duplicate()
	var c0 := w.total_coins()
	var days := 4
	var steps := int(days * 1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for i in steps:
		w.update(STEP)
		w.player.hunger = 100.0
	var dd := func(k: String) -> int: return int(w.stats.get(k, 0)) - int(stats0.get(k, 0))
	var leak: int = w.total_coins() - c0 - dd.call("caravan_coins_in") - dd.call("newcomer_coins_in") + dd.call("caravan_coins_out")
	check(leak == 0, "V10: %d days with aspirations and job_choice on: the currency balances (leak %d)" % [days, leak])
	check(int(w.judgment.stats.get("aspire_dawns", 0)) >= days, "V10: ...and the layer ran every dawn (%d)" % int(w.judgment.stats.get("aspire_dawns", 0)))
	w.dispose()


# ---------------------------------------------------------------- the layer's own rules -----------
func test_domains_and_neutral() -> void:
	var w := world()
	var a := asp_on(w)
	var j: JudgmentStore = w.judgment
	var n: NPC = null
	for c in adults(w):
		if not j.pers.holds_stubbornness(c.id):
			n = c                                   # a stubborn chooser remembers the last choice: not a neutral comparison
			break
	n.hunger = 100.0
	n.hp = n.max_hp
	for m in w.households[n.household].members:
		w.npc(int(m)).coins = 0                     # a purse well under its target, so a gain shows
	a._hh_cache(w)
	var s0 := a.satisfaction(n, w)
	n.coins += 500
	var s1 := a.satisfaction(n, w)
	check(s1[A.WEALTH] > s0[A.WEALTH] and s1[A.FOOD] == s0[A.FOOD] and s1[A.FAMILY] == s0[A.FAMILY] and s1[A.STANDING] == s0[A.STANDING], "domains: coins move wealth only")
	n.coins -= 500
	var job := n.job
	n.job = ""
	var s2 := a.satisfaction(n, w)
	check(s2[A.PROFESSION] == 0, "domains: without a job, profession satisfaction is 0")
	n.job = job
	var o: NPC = adults(w)[1] if adults(w)[1] != n else adults(w)[2]
	j.set_ledger(o.id, n.id, 30000, 0)
	var s3 := a.satisfaction(n, w)
	check(s3[A.STANDING] > s0[A.STANDING] and s3[A.WEALTH] == s0[A.WEALTH], "domains: others' good opinion moves standing only")
	# neutral = off: content, or a lead this choice does not bear on, changes no answer
	set_row(a, n, [100000, 100000, 100000, 100000, 100000, 100000])
	var cand := [{"id": "yes", "counterparty": o.id, "factors": {"live_order": 100000, "necessity": 0}}]
	var on_r := JudgmentWeighting.choose(j, j.cfg, n.id, "credit_lend", cand, [7])
	a.enabled = false
	var off_r := JudgmentWeighting.choose(j, j.cfg, n.id, "credit_lend", cand, [7])
	a.enabled = true
	var margin := func(r: Dictionary) -> int:
		return int(r.trace[0].utility) - int(r.trace[1].utility)
	check(str(on_r.chosen) == str(off_r.chosen) and margin.call(on_r) == margin.call(off_r), "neutral: a content villager decides exactly as with the layer off (same margin)")
	set_row(a, n, [100000, 100000, 100000, 0, 100000, 100000])
	var pr := JudgmentWeighting.choose(j, j.cfg, n.id, "credit_lend", cand, [7])
	check(margin.call(pr) == margin.call(off_r), "neutral: a profession-led villager is neutral on lending (fit 0)")
	# infeasible is never chosen, whatever the aspiration
	set_row(a, n, [0, 100000, 100000, 100000, 100000, 100000])
	var inf := JudgmentWeighting.choose(j, j.cfg, n.id, "work_accept", [{"id": "accept", "counterparty": o.id, "feasible": false, "why": "no place", "factors": {}}], [8])
	check(str(inf.chosen) == "forgo", "an infeasible option is never chosen, however much it would serve the leading aspiration")
	# heirs: skills start empty and priorities come from their own hash
	var spread := A.new(j, {"enabled": true, "priority_spread": 300}, j.world_seed)
	var differs := false
	for d in A.ND:
		differs = differs or spread.base_priority(n.id, d) != spread.base_priority(o.id, d)
	check(differs, "heirs: each person's temperament is their own hash (a child does not inherit a parent's priorities)")
	check(not a.rows.has(-77), "heirs: a new person has no row until their first dawn as an adult (no shift carried over)")
	w.dispose()


class FakeRec:
	var events := []
	var choices := []

	func aspiration_event(person: int, kind: String, facts: Dictionary) -> void:
		events.append([person, kind, facts])

	func judgment_choice(_c: int, profile: String, _k: Array, r: Dictionary) -> void:
		choices.append([profile, r])

	func judgment_family(_row: Dictionary) -> void:
		pass


func test_recorder() -> void:
	var w := world()
	var a := asp_on(w)
	var j: JudgmentStore = w.judgment
	var fr := FakeRec.new()
	j.rec = fr
	var n: NPC = adults(w)[0]
	a.dawn(w)
	a.setback(w, n, A.WEALTH, w.day(), "setback")
	var kinds := {}
	for e in fr.events:
		kinds[e[1]] = true
	check(kinds.has("lead") and kinds.has("priority"), "recorder: lead changes and priority shifts are recorded as judgment/aspiration events (%s)" % str(kinds.keys()))
	set_row(a, n, [0, 100000, 100000, 100000, 100000, 100000])
	var o: NPC = adults(w)[1]
	JudgmentWeighting.choose(j, j.cfg, n.id, "work_accept", [{"id": "accept", "counterparty": o.id, "factors": {"necessity": 0, "wage": 100000}}], [1])
	var r: Dictionary = fr.choices[fr.choices.size() - 1][1]
	check(r.trace[0].has("aspiration") and str(r.trace[0].aspiration.domain) == "food" and r.trace[1].has("forgo_aspiration_offset"), "recorder: the choice carries the aspiration's domain, pressure, fit and the forgo offset")
	j.rec = null
	# the real recorder: the code is registered
	var codes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/recorder_codes.json"))
	check((codes.subsystems as Array).has("aspiration"), "recorder: judgment/aspiration is in recorder_codes.json")
	var root := OS.get_environment("TMPDIR") if OS.get_environment("TMPDIR") != "" else "user://"
	var rec := WorldRecorder.attach(w, {"root": root + "/aspiration_test_rec"})
	a.setback(w, n, A.FOOD, w.day(), "setback")
	JudgmentWeighting.choose(j, j.cfg, n.id, "work_accept", [{"id": "accept", "counterparty": o.id, "factors": {"necessity": 0, "wage": 100000}}], [2])
	rec.flush()
	check(rec.unknown_codes.is_empty(), "recorder: no unknown code (%s)" % str(rec.unknown_codes))
	w.dispose()


func run_once() -> String:
	var w := world(5)
	var a := asp_on(w, false)
	w.judgment.cfg.decision.integration.job_choice = true
	var steps := int(2 * 1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for i in steps:
		w.update(STEP)
		w.player.hunger = 100.0
	var out := JSON.stringify(a.to_dict()) + JSON.stringify(w.judgment.stats)
	for n: NPC in w.npcs:
		out += n.job
	w.dispose()
	return out


func test_determinism() -> void:
	var x := run_once()
	var y := run_once()
	check(x == y and x.contains("rows"), "determinism: two runs of the same seed with aspirations on give the same leads, rows and choices")
