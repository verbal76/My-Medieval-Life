extends SceneTree
## PROSPECTIVE (Expansion 19, PROS-19; owner directive 2026-10-23 sections 4 and 5; X19-FOUND-BONDS, X19-FOUND-FAMREP):
## the history of a pair of people (familiarity, betrayals), resentment as its own value, and family reputation
## (JudgmentBonds), and their one effect: a deterministic multiplier on a regard gain in Relations, only with a judgment
## store attached. Reach, transmission and the limits are unresolved (shipped inert), so the family tests use fixtures.
## Run headless:  godot --headless --path game --script res://tests/judgment_bonds_test.gd

var failures := 0
var checks := 0
const A := 1
const B := 2
const C := 3
const PA := 10       # a parent
const CH := 11       # PA's child
const GR := 12       # CH's child
const OBS := 20      # someone who hears stories
const OTHER := 21
const X := 30        # a stranger deed's victim
const PLAYER := -2


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


## The shipped config with the personality and morality noise off (fixtures check exact numbers) and, by default, the
## test fixtures for the unresolved choices: reach "line" (parents and children).
func cfg(reach := "line") -> Dictionary:
	var c := JudgmentStore.default_cfg().duplicate(true)
	c.interpret.morality_spread_permille = 0
	c.decay.ordinary_permille_per_day = 0
	c.gossip.timing = "hour"
	c.gossip.closeness_floor_permille = 1000
	c.decision.trait_spread_permille = 0
	c.personality = {"tolerance_spread_permille": 0, "tolerance_per_point": 0, "weight_per_point": 0, "max_shift_permille": 250}
	c.bonds.reach = reach
	c.bonds.friend_level = 25
	return c


func social() -> JudgmentSocial:
	return JudgmentSocial.new().set_parent(CH, PA).set_parent(GR, CH).set_friends(A, B)


func store(config := {}, soc: JudgmentSocial = null) -> JudgmentStore:
	return JudgmentStore.new(config if not config.is_empty() else cfg(), soc if soc != null else social(), 7)


func _init() -> void:
	test_shipped_inert()
	test_history_and_familiarity()
	test_negative_standing()
	test_betrayal_history()
	test_resentment_floor_and_softening()
	test_neutrality_restores_nothing()
	test_family_reputation()
	test_family_override_and_combination()
	test_spillover()
	test_determinism_and_save()
	test_relations_familiarity()
	test_relations_caps()
	test_relations_family()
	test_judgment_off_identical()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard":
			out.append(n)
	return out


## Make a pair former friends: up to friend level, then back below it.
func make_former(j: JudgmentStore, a: int, b: int) -> void:
	j.bonds.on_regard(a, b, 0.0, 30.0)
	j.bonds.on_regard(a, b, 30.0, 10.0)


func test_shipped_inert() -> void:
	var c: Dictionary = JudgmentStore.default_cfg()
	check(not bool(c.enabled), "judgment.json still ships enabled false")
	var b: Dictionary = c.bonds
	check(int(b.familiarity_permille) == 100 and int(b.family_permille) == 50 and int(b.combined_permille) == 120,
			"the owner's targets: familiarity ~10%, family ~5%, both ~12% (a configured value, not 15%)")
	check(str(b.reach) == "none" and int(b.soften_milli_per_day) == 0, "reach (X19-SPILL-REACH) ships none and softening ships inert")
	var j := store(JudgmentStore.default_cfg())
	check(j.bonds.family_reputation(OBS, CH) == 0 and j.bonds.gain_permille(OBS, CH) == 1000, "shipped, no family reputation exists at all")
	check(j.bonds.floor_days() == Life.year_days(), "the serious-grievance floor is one in-game year (Life.year_days())")
	check(not j.to_dict().has("bonds"), "a store with no bonds history writes no bonds key")


func test_history_and_familiarity() -> void:
	var j := store()
	j.bonds.on_regard(A, B, 0.0, 10.0)
	check(j.bonds.peak(A, B) == 0 and not j.bonds.familiar(A, B), "below friendship level nothing is recorded")
	j.bonds.on_regard(A, B, 10.0, 30.0)
	check(j.bonds.peak(A, B) == 30000 and not j.bonds.familiar(A, B), "reaching friendship level records the peak; not yet a former friend")
	check(j.bonds.gain_permille(A, B) == 1000, "a current friend has no familiarity bonus yet")
	j.bonds.on_regard(A, B, 30.0, 10.0)
	check(j.bonds.familiar(A, B) and j.bonds.peak(A, B) == 30000, "falling back below it: a former friend, the peak kept")
	check(j.bonds.gain_permille(A, B) == 1100 and j.bonds.gain_permille(B, A) == 1100, "familiarity is +10%, the same from either side")
	check(j.bonds.boost(A, B, 5.0) == 5.5 and j.bonds.boost(A, C, 5.0) == 5.0, "...exactly 5.5 on a gain of 5; a stranger's gain is unchanged")
	j.bonds.on_regard(A, B, 10.0, 40.0)
	check(j.bonds.familiar(A, B) and j.bonds.gain_permille(A, B) == 1100 and j.bonds.peak(A, B) == 40000, "it persists after the former level is restored")
	for i in 5:
		j.bonds.on_regard(A, B, 40.0, 5.0)
		j.bonds.on_regard(A, B, 5.0, 40.0)
	check(j.bonds.gain_permille(A, B) == 1100 and int(j.bonds.stats.familiar_set) == 1,
			"repeated separations and reunions do not stack: one flag, still +10%")


func test_negative_standing() -> void:
	var j := store()
	make_former(j, A, B)
	check(j.bonds.gain_permille(A, B) == 1100, "former friends with a clean slate: familiarity applies")
	j.set_ledger(A, B, 0, 5000)
	check(j.bonds.negative_standing(A, B) and j.bonds.gain_permille(A, B) == 1000, "a negative NET (either way) suspends familiarity")
	j.set_ledger(A, B, 0, 0)
	check(j.bonds.gain_permille(A, B) == 1100, "...and it returns when the standing is no longer negative")
	j.set_ledger(B, A, 0, 100)
	check(j.bonds.gain_permille(A, B) == 1000, "the other direction counts as well")
	j.set_ledger(B, A, 0, 0)
	j.bonds.resent[JudgmentBonds._dk(B, A)] = PackedInt64Array([3000, 0, -1, 0])
	check(j.bonds.negative_standing(A, B) and j.bonds.gain_permille(A, B) == 1000, "resentment above zero suspends it, with NET neutral")
	j.bonds.resent.erase(JudgmentBonds._dk(B, A))
	check(j.bonds.gain_permille(A, B) == 1100, "the flag itself was never lost")


func test_betrayal_history() -> void:
	var j := store()
	var ev := j.publish("theft", [B], [A])
	j.observe_all(ev, [A])
	check(j.bonds.betrayals(A, B).size() == 1 and str(j.bonds.betrayals(A, B)[0][3]) == "theft", "a deed done to a friend is recorded as a betrayal")
	check(j.bonds.resentment(A, B) == 1000 and j.bonds.resentment(B, A) == 0, "...and the victim resents the actor (1.0 point), not the other way")
	var ev2 := j.publish("theft", [C], [A])
	j.observe_all(ev2, [A])
	check(j.bonds.betrayals(A, C).is_empty() and j.bonds.resentment(A, C) == 1000, "a stranger's theft is resentment but not a betrayal")
	var ev3 := j.publish("theft", [B], [X])
	j.observe_all(ev3, [A, X])
	check(j.bonds.resentment(A, B) == 1000, "a deed a friend only witnessed (not done to them) raises no resentment")
	var ev4 := j.publish("gift", [B], [], [A])
	j.observe_all(ev4, [A])
	check(j.bonds.betrayals(A, B).size() == 1, "good deeds are not betrayals")
	j.bonds.resent[JudgmentBonds._dk(A, B)] = PackedInt64Array([0, 0, -1, 0])
	for d in range(1, 800):
		if d % 100 == 0:
			j.advance_day(d)
	check(j.bonds.betrayals(A, B).size() == 1, "betrayals are never erased: resentment at zero and every fact retired, the record stays")
	var l := store()
	l.load_dict(j.to_dict())
	check(l.bonds.betrayals(A, B).size() == 1 and l.bonds.betrayals(A, B) == j.bonds.betrayals(A, B), "...and survive save and load")


func test_resentment_floor_and_softening() -> void:
	var yr := Life.year_days()
	var c := cfg()
	c.bonds.soften_milli_per_day = 100
	c.bonds.serious_severity = 2000                      # assault (2.0) is serious; theft (1.0) is not
	var j := store(c)
	var growth := {A: 1000}
	j.bonds.growth_fn = func(p: int) -> int: return int(growth.get(p, 0))
	var ev := j.publish("assault", [B], [A])
	j.observe_all(ev, [A])
	var ev2 := j.publish("theft", [C], [A])
	j.observe_all(ev2, [A])
	check(j.bonds.resentment(A, B) == 2000 and j.bonds.resentment(A, C) == 1000, "resentment follows severity: assault 2.0, theft 1.0")
	j.advance_day(yr - 1)
	check(j.bonds.resentment(A, B) == 2000, "a serious grievance cannot soften before a year has passed, however much they grow")
	check(j.bonds.resentment(A, C) == 1000 - 100 * (yr - 1), "a lesser one softens through growth at once (rate 100 a day x growth 1.0)")
	j.advance_day(yr + 9)
	check(j.bonds.resentment(A, B) == 2000 - 100 * 9, "after the floor it softens by the configured rate x growth (9 days: 900)")
	check(j.bonds.betrayals(A, B).size() == 1 and j.net(A, B) < 0, "...and the betrayal and the judgment stay as they were")
	# without growth, time alone does nothing
	var d := store(c)
	var ev3 := d.publish("assault", [B], [A])
	d.observe_all(ev3, [A])
	d.advance_day(yr * 5)
	check(d.bonds.resentment(A, B) == 2000, "with no personality growth, five years of time alone soften nothing")
	var s := store()
	var ev4 := s.publish("assault", [B], [A])
	s.observe_all(ev4, [A])
	s.bonds.growth_fn = func(_p: int) -> int: return 1000
	s.advance_day(yr * 5)
	check(s.bonds.resentment(A, B) == 2000, "shipped inert: even with growth the shipped rate (0) changes nothing")


func test_neutrality_restores_nothing() -> void:
	var c := cfg()
	c.bonds.soften_milli_per_day = 1000
	var j := store(c)
	j.bonds.growth_fn = func(_p: int) -> int: return 1000
	j.bonds.on_regard(A, B, 0.0, 30.0)
	var ev := j.publish("theft", [B], [A])
	j.observe_all(ev, [A])
	j.bonds.on_regard(A, B, 30.0, 8.0)
	var net_before := j.net(A, B)
	var trust_before := j.trust_of(A, B)
	j.trust_add(A, B, -15000)
	trust_before = j.trust_of(A, B)
	j.advance_day(Life.year_days() * 2)
	check(j.bonds.resentment(A, B) == 0, "old resentment with personality growth returns to neutrality")
	check(j.trust_of(A, B) == trust_before, "...and trust did not recover by it: only reliability events move trust (15b)")
	check(j.net(A, B) == net_before, "...nor did the moral judgment")
	check(j.bonds.peak(A, B) == 30000 and j.bonds.betrayals(A, B).size() == 1, "...nor the history")
	check(j.bonds.gain_permille(A, B) == 1000, "while NET is still negative the familiarity advantage stays suspended")
	var sub := store()
	sub.bonds.on_regard(A, B, 0.0, 30.0)
	sub.bonds.on_regard(A, B, 30.0, 8.0)
	check(sub.social.regard(A, B) == 0, "judgment keeps no regard of its own to restore (Relations owns it)")
	var ev2 := j.publish("rescue", [B], [], [A])
	j.observe_all(ev2, [A])
	j.trust_add(A, B, 4000)
	check(j.trust_of(A, B) == trust_before + 4000, "trust recovers through the existing reliability events")


## Observer OBS has been told what the parent PA did: a rescue (GOOD, bystander 0.6 for a 2.0 deed).
func with_parent_story(j: JudgmentStore, observer := OBS) -> int:
	var ev := j.publish("rescue", [PA], [], [X])
	j.observe(ev, observer)
	return ev


func test_family_reputation() -> void:
	var j := store()
	check(j.bonds.gain_permille(OBS, CH) == 1000, "before any story is known there is no inherited impression")
	with_parent_story(j)
	check(j.net(OBS, PA) == 600, "the observer's judgment of the parent from the story: +0.6")
	check(j.bonds.family_reputation(OBS, CH) == 600, "the child's family reputation, for the observer who knows the story: +0.6")
	check(j.bonds.gain_permille(OBS, CH) == 1050 and j.bonds.gain_permille(CH, OBS) == 1050, "a positive qualifying reputation: +5% of friendship progression")
	check(j.bonds.gain_permille(OTHER, CH) == 1000 and j.bonds.family_reputation(OTHER, CH) == 0,
			"someone who has not heard the story gets nothing: only remembered or told stories count")
	check(j.net(OBS, CH) == 0 and j.ledger(OBS, CH)[2] == 0 and j.trust_of(OBS, CH) == 0,
			"the impression is not the child's own judgment (NET) and not trust")
	# told on: the story reaches someone through gossip
	j.meet(OBS, OTHER)
	check(j.bonds.gain_permille(OTHER, CH) == 1050, "a story passed on in a meeting gives the listener the same inheritance")
	# the grandchild: the parent's story does not reach two generations in the "line" fixture
	check(j.bonds.gain_permille(OBS, GR) == 1000, "reach 'line' covers parents and children only; the grandchild is not reached")
	# familiarity is not inherited
	make_former(j, OBS, CH)
	check(j.bonds.gain_permille(OBS, CH) == 1120, "both qualify: the combined value 12%, not 15%")
	check(j.bonds.gain_permille(OBS, GR) == 1000 and j.bonds.gain_permille(OTHER, GR) == 1000,
			"a descendant does not inherit the parent's familiarity flag")
	check(j.bonds.gain_permille(OTHER, CH) == 1050, "familiarity with the child is the pair's own: another observer still gets 5% only")
	# a custom reach (the interface): grandparents too
	j.bonds.reach_fn = func(s: int) -> Array: return [[CH, 1000, 300], [PA, 1000, 300]] if s == GR else []
	check(j.bonds.family_reputation(OBS, GR) == 600, "a replaced reach function is used: the extended family counts when the owner decides it does")
	j.bonds.reach_fn = Callable()
	j.bonds.transmit_fn = func(_o: int, _s: int, raw: int) -> int: return raw / 2
	check(j.bonds.family_reputation(OBS, CH) == 300, "a replaced transmission function is used (X19-REP-TRANSMIT left open)")
	j.bonds.transmit_fn = Callable()
	var n := store(cfg("none"))
	with_parent_story(n)
	check(n.bonds.gain_permille(OBS, CH) == 1000, "reach none: the same story gives no bonus (shipped state)")


func test_family_override_and_combination() -> void:
	var j := store()
	with_parent_story(j)
	make_former(j, OBS, CH)
	var seen := []
	for i in 12:
		seen.append(j.bonds.gain_permille(OBS, CH))
		var ev := j.publish("gift", [CH], [], [OBS])
		j.observe(ev, OBS, "participant")
		if j.bonds.family_reputation(OBS, CH) < 1:
			break
	check(seen[0] == 1120, "start: both qualify, 12%")
	check(seen[1] < seen[0] and seen[1] > 1100, "one experience of the person: the inherited part is partly replaced, so a bonus between 10% and 12%")
	check(seen[1] == 1100 + 20 * 900 / 1000, "...exactly: single 100 + (combined 120 - 100) x the 900 permille left = 118")
	var k := store()
	with_parent_story(k)
	for i in 4:
		k.observe(k.publish("gift", [CH], [], [OBS]), OBS, "participant")
	check(k.bonds.gain_permille(OBS, CH) == 1000 + 50 * 600 / 1000, "after four experiences 600 permille of the inheritance is left: 5% x 0.6 = 3%")
	for i in 6:
		k.observe(k.publish("gift", [CH], [], [OBS]), OBS, "participant")
	check(k.bonds.gain_permille(OBS, CH) == 1000, "ten experiences replace it entirely: personal experience gradually overrides")


func test_spillover() -> void:
	var j := store()
	var ev := j.publish("theft", [PA], [X])
	j.observe(ev, OBS)
	check(j.net(OBS, PA) == -300, "the observer judges the parent for the theft: -0.3 (a bystander)")
	check(j.bonds.family_reputation(OBS, CH) == -90, "the child's family reputation takes a small spillover: 30% of it")
	check(j.net(OBS, CH) == 0 and j.bad(OBS, CH) == 0 and j.ledger(OBS, CH)[2] == 0, "the deed and the NET are not transferred to the relative")
	check(j.trust_of(OBS, CH) == 0 and not j.trust.has(OBS), "trust stays individual: not touched")
	check(j.bonds.gain_permille(OBS, CH) == 1000, "a negative family reputation gives no progression bonus (and no penalty)")
	check(j.bonds.betrayals(OBS, CH).is_empty() and j.bonds.resentment(OBS, CH) == 0, "no betrayal or resentment passes to relatives")
	var ev2 := j.publish("rescue", [PA], [], [X])
	j.observe(ev2, OBS)
	check(j.net(OBS, PA) == 300 and j.bonds.family_reputation(OBS, CH) == 300, "good and bad stories about the parent net out in the observer's judgment of them (+0.6 -0.3), and the family reputation follows")


func test_determinism_and_save() -> void:
	var make := func() -> JudgmentStore:
		var j := store()
		with_parent_story(j)
		var ev := j.publish("theft", [B], [A])
		j.observe_all(ev, [A])
		make_former(j, A, B)
		make_former(j, OBS, CH)
		j.advance_day(40)
		return j
	var x: JudgmentStore = make.call()
	var y: JudgmentStore = make.call()
	check(x.state_hash() == y.state_hash() and JSON.stringify(x.bonds.to_dict()) == JSON.stringify(y.bonds.to_dict()), "two identical runs give the identical state and bonds hash")
	var d := x.to_dict()
	check(d.has("bonds") and (d.bonds.pairs as Array).size() == 2, "the bonds history is a section key of the judgment save")
	var l := store()
	check(l.load_dict(JSON.parse_string(JSON.stringify(d))) == "", "...and loads from its text form")
	check(l.state_hash() == x.state_hash(), "save and load round trip: the same state hash")
	check(l.bonds.familiar(OBS, CH) and l.bonds.resentment(A, B) == x.bonds.resentment(A, B) and l.bonds.betrayals(A, B).size() == 1,
			"...familiar flag, resentment and betrayals included")
	check(l.bonds.gain_permille(OBS, CH) == x.bonds.gain_permille(OBS, CH), "...and the same multiplier")
	var old := d.duplicate(true)
	old.erase("bonds")
	var o := store()
	check(o.load_dict(old) == "" and o.bonds.is_empty() and not o.to_dict().has("bonds"), "an older save without the key loads as an empty history")
	var reload := store()
	reload.bonds.on_regard(A, C, 0.0, 30.0)
	reload.load_dict(d)
	check(reload.bonds.peak(A, C) == 0, "loading replaces the history, nothing of the previous state lingers")


# ---------------------------------------------------------------- Relations, in a World -----------
func test_relations_familiarity() -> void:
	var w := new_world()
	var people := adults(w)
	var a: NPC = people[3]
	var b: NPC = people[4]
	var j := JudgmentLive.attach(w, cfg("none"))
	var t := w.relations.tie(a.id, b.id)
	for day in 3:                                              # +10 a day (help_regard), within regard_daily_cap 14
		w.minutes = float(day + 1) * World.DAY + 600.0
		w.relations.helped(a.id, b)
	check(is_equal_approx(float(t.regard), 30.0) and j.bonds.peak(a.id, b.id) == 30000, "plain gains first: regard 30, the peak recorded by Relations")
	check(not j.bonds.familiar(a.id, b.id), "...and no familiarity yet")
	w.minutes = 5.0 * World.DAY
	w.relations._raise(t, -22.0, 0.0, false, Vector2i(a.id, b.id))
	check(is_equal_approx(float(t.regard), 8.0) and j.bonds.familiar(a.id, b.id), "a drop below friendship level (Relations' own _raise): a former friend")
	w.minutes = 6.0 * World.DAY + 600.0
	w.relations.helped(a.id, b)
	check(is_equal_approx(float(t.regard), 8.0 + 11.0), "rebuilding: a help of 10 counts 11, +10% exactly")
	for day in 3:
		w.minutes = float(7 + day) * World.DAY + 600.0
		w.relations.helped(a.id, b)
	check(float(t.regard) > 25.0 and j.bonds.familiar(a.id, b.id), "the former level is restored")
	var before := float(t.regard)
	w.minutes = 11.0 * World.DAY + 600.0
	w.relations.helped(a.id, b)
	check(is_equal_approx(float(t.regard), minf(100.0, before + 11.0)), "the advantage persists after the former level is restored")
	j.bonds.resent[JudgmentBonds._dk(a.id, b.id)] = PackedInt64Array([2000, 0, -1, 0])
	before = float(t.regard)
	w.minutes = 12.0 * World.DAY + 600.0
	w.relations.helped(a.id, b)
	check(is_equal_approx(float(t.regard), minf(100.0, before + 10.0)), "active negative standing (resentment) suspends it: plain +10")
	w.dispose()


func test_relations_caps() -> void:
	var cap := float(Relations.cfg().regard_daily_cap)
	var shared_cap := float(Relations.cfg().shared.daily_cap)
	var plain := [0.0, 0.0]
	for with in [false, true]:
		var w := new_world()
		var people := adults(w)
		var a: NPC = people[3]
		var b: NPC = people[4]
		if with:
			var j := JudgmentLive.attach(w, cfg("none"))
			make_former(j, a.id, b.id)
		w.minutes = 3.0 * World.DAY + 600.0
		var t := w.relations.tie(a.id, b.id)
		w.relations.helped(a.id, b)
		w.relations.helped(a.id, b)
		var after_help := float(t.regard)
		check(after_help <= cap + 0.0001, "daily regard cap %s holds with%s the bonus (regard %s)" % [cap, "" if with else "out", after_help])
		plain[0 if not with else 1] = after_help
		w.dispose()
	check(is_equal_approx(plain[0], plain[1]) and is_equal_approx(plain[1], cap), "two helps in a day reach exactly the cap either way: the bonus never raises it")
	for with in [false, true]:
		var w := new_world()
		var people := adults(w)
		var a: NPC = people[3]
		var b: NPC = people[4]
		if with:
			var j := JudgmentLive.attach(w, cfg("none"))
			make_former(j, a.id, b.id)
		var t := w.relations.tie(a.id, b.id)
		for h in 6:                                            # six working hours, work_regard 2.0 each
			w.minutes = 3.0 * World.DAY + float(8 + h) * 60.0
			w.relations.share(a.id, b.id, "work")
		check(float(t.shared_today) <= shared_cap + 0.0001, "shared.daily_cap %s holds with%s the bonus (shared today %s)" % [shared_cap, "" if with else "out", t.shared_today])
		check(float(t.regard) <= cap + 0.0001, "...and so does the daily cap on regard")
		if with:
			check(is_equal_approx(float(t.shared_today), shared_cap), "the cap is reached sooner with the bonus, never exceeded")
		w.dispose()
	var w2 := new_world()
	var p2 := adults(w2)
	var j2 := JudgmentLive.attach(w2, cfg("none"))
	make_former(j2, p2[3].id, p2[4].id)
	var t2 := w2.relations.tie(p2[3].id, p2[4].id)
	w2.minutes = 3.0 * World.DAY + 600.0
	w2.relations.share(p2[3].id, p2[4].id, "work")
	check(is_equal_approx(float(t2.regard), 2.2), "one shared work hour (2.0) counts 2.2 for former friends")
	w2.dispose()


func test_relations_family() -> void:
	var w := new_world()
	var people := adults(w)
	var obs: NPC = people[3]
	var ch: NPC = people[4]
	var pa: NPC = people[5]
	ch.mother = pa.id
	pa.children = [ch.id]
	var j := JudgmentLive.attach(w, cfg("line"))
	var ev := j.publish("rescue", [pa.id], [], [people[6].id])
	j.observe(ev, obs.id)
	check(j.bonds.reach(ch.id).size() == 1 and int(j.bonds.reach(ch.id)[0][0]) == pa.id, "the live adapter reads the family graph of Life (mother, children)")
	w.minutes = 3.0 * World.DAY + 600.0
	w.relations.helped(obs.id, ch)
	check(is_equal_approx(float(w.relations.tie(obs.id, ch.id).regard), 10.5), "a descendant whose family's story is known: 10 counts 10.5 (+5%)")
	w.relations.helped(people[7].id, ch)
	check(is_equal_approx(float(w.relations.tie(people[7].id, ch.id).regard), 10.0), "a villager who has not heard it: plain 10")
	check(j.trust.is_empty() or not j.trust.has(obs.id), "trust is untouched by any of it")
	w.dispose()


func test_judgment_off_identical() -> void:
	var run := func(attach: bool) -> Array:
		var w := new_world(3)
		if attach:
			JudgmentLive.attach(w, cfg("none"))
		var people := adults(w)
		var a: NPC = people[3]
		var b: NPC = people[4]
		var out := []
		for d in 6:
			w.minutes = float(d + 2) * World.DAY + 600.0
			w.relations.helped(a.id, b)
			w.relations.share(a.id, people[5].id, "social")
			w.relations.talked(b)
			w.relations._raise(w.relations.tie(a.id, b.id), -3.0, 0.0, false, Vector2i(a.id, b.id))
			w.relations.dawn()
			out.append([snappedf(float(w.relations.tie(a.id, b.id).regard), 0.000001), snappedf(float(w.relations.tie(a.id, people[5].id).regard), 0.000001)])
		w.dispose()
		return out
	var off: Array = run.call(false)
	var on: Array = run.call(true)
	check(off == on, "with judgment attached but no history, Relations gives the same numbers as with judgment off")
	var w := new_world(3)
	check(w.judgment == null, "judgment off: no store, so no bonds call exists on any path")
	w.dispose()
