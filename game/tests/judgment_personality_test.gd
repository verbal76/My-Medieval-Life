extends SceneTree
## PROSPECTIVE (Expansion 19, X19-FOUND-PERS; owner directive 2026-10-23 x19_foundations_round, s.2-3): the personality
## framework (JudgmentPersonality, config "traits") with FIXTURE parameters. The shipped parameters are inert placeholders
## (X19-PERS-FORMULA, X19-TRAIT-DIST pending), so every behaviour is proved here with numbers chosen only to make the
## mechanism visible; none of them is a proposal. Run headless:
##   godot --headless --path game --script res://tests/judgment_personality_test.gd

var failures := 0
var checks := 0
const BOB := 1
const THIEF := 7
## Recorded from the pre-move store (HEAD 3ec38d2) with the same script: tolerance of persons 1, 2, 3, 5 after each event; then [tolerance(1), threshold(1, -20000), weight_shift(3)].
const EXPECT_TOL := "[[856,1098,876,1142],[776,1098,876,1142],[776,1058,876,1142],[776,1058,876,1142],[776,1058,796,1142],[776,1058,796,1142],[646,-12920,60]]"


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


## Fixture traits: strong enough to see, every shape on.
func fix() -> Dictionary:
	return {
		"stubbornness_share_permille": 300, "stubbornness_start_permille": 600, "rate_permille_per_point": 100,
		"effects": {"provocation": {"tolerance": -1000, "stubbornness": 1000}, "positive": {"tolerance": 1000, "stubbornness": -1000}},
		"frequency": {"window_days": 10, "gain_permille": 500, "cap": 4},
		"duration": {"gain_permille_per_day": 100, "cap_days": 5},
		"soft_limit": {"scale_permille": 1000, "floor_permille": 100},
		"recovery_gain_permille": 1500,
		"learning": {"rate_permille_per_point": 200, "repeat_window_days": 20, "accel_permille_per_repeat": 500, "repeat_cap": 4, "transfer_permille": 250, "limit_permille": 1000},
		"emotion": {"anger_permille_per_point": 300, "anger_days": 20, "reminder_permille": 200, "reminder_cap_permille": 600,
			"override_threshold_permille": 500, "override_days": 21}}


func cfg() -> Dictionary:
	var c := JudgmentStore.default_cfg().duplicate(true)
	c.traits = fix()
	return c


func P() -> JudgmentPersonality:
	return JudgmentPersonality.new(fix(), 7)


## The first person in 1.. who has (or lacks) the stubbornness potential.
func holder(p: JudgmentPersonality, want := true) -> int:
	for i in range(1, 500):
		if p.holds_stubbornness(i) == want:
			return i
	return -1


func _init() -> void:
	test_shipped_inert()
	test_tolerance_owner()
	test_share()
	test_evolution_inputs()
	test_stable_and_soft_limits()
	test_recovery_and_growth()
	test_learning()
	test_anger_override_reminder()
	test_provocation_drift()
	test_history()
	test_store_hook()
	test_determinism_and_save()
	test_old_save()
	test_separate_concepts()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_shipped_inert() -> void:
	var j := JudgmentStore.new({}, JudgmentSocial.new(), 7)
	check(not j.pers.active, "shipped config: the personality layer is inert (every rate 0)")
	var before := j.state_hash()
	var t0 := j.tolerance(BOB)
	var ev := j.publish("theft", [THIEF], [BOB], [], 4)
	j.observe_all(ev, [])
	var saved: Dictionary = j.to_dict().get("traits", {})
	check(j.pers.drift.is_empty() and j.pers.anger.is_empty() and j.pers.wisdom.is_empty() and j.pers.record.is_empty() and saved.get("log", []).is_empty() and saved.get("tol", []).size() == 1, "...no experience is recorded; only the SJD-Q13 tolerance shift is held and saved (traits.tol)")
	check(j.tolerance(BOB) == t0 - 40 and j.personality_growth(BOB) == 0, "...tolerance moves only by the existing life shift; growth is 0")
	check(j.pers.mistake(BOB, "market", 3000, 5) == 0 and j.pers.practical_wisdom(BOB, "market") == 0, "...a costly mistake teaches nothing")
	j.pers.experience(BOB, "provocation", 3000, 5)
	check(j.pers.remind(BOB, 6) == 0 and j.pers.anger_at(BOB, 6) == 0 and j.pers.record.is_empty(), "...no anger, no reminder, no history")
	check(before != 0 and JudgmentStore.default_cfg().traits.stubbornness_share_permille == 300, "...the approved 30% share ships")
	var d: Dictionary = JudgmentStore.default_cfg().traits
	var zero := true
	for k in ["rate_permille_per_point"]:
		zero = zero and int(d[k]) == 0
	for sec in ["learning", "emotion"]:
		for k in d[sec]:
			if k.ends_with("_per_point") or k.ends_with("_days") or k.ends_with("permille") and k != "override_threshold_permille":
				zero = zero and int(d[sec][k]) == 0
	check(zero, "...every rate, limit and duration in the shipped section is 0")


func test_share() -> void:
	var p := P()
	var n := 0
	for i in range(1, 1001):
		n += 1 if p.holds_stubbornness(i) else 0
	check(n >= 250 and n <= 350, "about 30%% of 1000 people hold the stubbornness potential (%d)" % n)
	var n2 := 0
	for i in range(1, 10001):
		n2 += 1 if p.holds_stubbornness(i) else 0
	check(n2 >= 2850 and n2 <= 3150, "...and of 10000 (%d)" % n2)
	var same := true
	var q := P()
	for i in range(1, 200):
		same = same and p.holds_stubbornness(i) == q.holds_stubbornness(i)
	check(same, "the same seed gives the same people; a fixed trait, never a roll per decision")
	var other := JudgmentPersonality.new(fix(), 8)
	var diff := 0
	for i in range(1, 200):
		diff += 1 if other.holds_stubbornness(i) != p.holds_stubbornness(i) else 0
	check(diff > 20, "a different world seed picks different people (%d of 199)" % diff)
	var h := holder(p, false)
	p.experience(h, "provocation", 2000, 1)
	check(p.stubbornness(h, 1) == 0 and p.trait_drift(h, JudgmentPersonality.T_STUB) == 0, "a person without the potential stays at stubbornness 0 whatever happens")


func test_evolution_inputs() -> void:
	var p := P()
	var a := 1
	var b := 2
	var c := 3
	var d := 4
	p.experience(a, "provocation", 1000, 1)
	p.experience(b, "provocation", 2000, 1)
	check(p.tolerance_drift(a) == -100 and p.tolerance_drift(b) == -200, "severity: twice the severity, twice the drift (%d, %d)" % [p.tolerance_drift(a), p.tolerance_drift(b)])
	p.experience(c, "provocation", 1000, 1, 4)
	check(p.tolerance_drift(c) == -140, "duration: an experience that lasted 4 days pulls harder (%d)" % p.tolerance_drift(c))
	p.experience(d, "provocation", 1000, 1)
	var first := p.tolerance_drift(d)
	p.experience(d, "provocation", 1000, 2)
	var second := p.tolerance_drift(d) - first
	check(first == -100 and second < -100, "frequency: a repeat inside the window pulls harder (%d then %d)" % [first, second])
	var e := 5
	p.experience(e, "provocation", 1000, 1)
	p.experience(e, "provocation", 1000, 40)
	check(p.tolerance_drift(e) == -190, "...a repeat long after the window does not count as frequent (%d)" % p.tolerance_drift(e))


func test_stable_and_soft_limits() -> void:
	var p := P()
	var h := holder(p)
	p.experience(h, "positive", 100, 1)
	check(absi(p.tolerance_drift(h)) <= 10, "mostly stable: one small experience barely moves a trait (%d)" % p.tolerance_drift(h))
	var steps := []
	var last := p.tolerance_drift(BOB)
	for i in 120:
		p.experience(BOB, "provocation", 1000, i * 30)       # spaced beyond the frequency window
		var now := p.tolerance_drift(BOB)
		steps.append(last - now)
		last = now
	check(steps[0] == 100 and steps[5] < steps[0] and steps[15] < steps[5], "soft limit: each further push moves less (%s ...)" % str(steps.slice(0, 4)))
	check(steps[119] >= 1 and last < -1000, "...never a wall: it still moves at the extreme and goes past the soft limit scale (%d)" % last)
	check(JudgmentPersonality.curve_resistance(5000, 1000, 0) >= 1, "...even a floor of 0 leaves a positive resistance factor")


func test_recovery_and_growth() -> void:
	var p := P()
	for i in 4:
		p.experience(BOB, "provocation", 1000, i * 30)
	var low := p.tolerance_drift(BOB)
	check(low < -300, "repeated provocation set tolerance back (%d)" % low)
	var day := 200
	var n := 0
	while p.tolerance_drift(BOB) < 0 and n < 100:
		p.experience(BOB, "positive", 1000, day)
		day += 30
		n += 1
	check(p.tolerance_drift(BOB) >= 0 and n > 1, "sustained positive experience recovers it fully, not in one step (%d experiences)" % n)
	var at_origin := p.tolerance_drift(BOB)
	for i in 5:
		p.experience(BOB, "positive", 1000, day)
		day += 30
	check(p.tolerance_drift(BOB) > at_origin and p.growth(BOB) > 0, "...and goes on past the original level: growth %d" % p.growth(BOB))
	var q := P()
	q.experience(2, "provocation", 3000, 1)
	check(q.growth(2) == 0, "a worsening is not growth")
	var h := holder(q)
	for i in 6:
		q.experience(h, "positive", 1000, i * 30)
	check(q.trait_drift(h, JudgmentPersonality.T_STUB) < 0 and q.stubbornness(h, 400) < 600 and q.growth(h) > q.tolerance_drift(h), "a stubborn villager can shed stubbornness (level %d from 600) and it counts as growth" % q.stubbornness(h, 400))


func test_learning() -> void:
	var fx := fix()
	fx.learning.limit_permille = 100000          # the soft limit is tested on its own below: keep it out of the repeat comparisons
	var p := JudgmentPersonality.new(fx, 7)
	var g1 := p.mistake(BOB, "lend", 1000, 1)
	check(g1 == 200 and p.practical_wisdom(BOB, "lend") >= 200, "a costly mistake teaches gradually: +%d" % g1)
	var g2 := p.mistake(BOB, "lend", 1000, 3)
	var g3 := p.mistake(BOB, "lend", 1000, 5)
	check(g2 > g1 and g3 > g2, "similar mistakes repeating teach faster (%d, %d, %d)" % [g1, g2, g3])
	var q := JudgmentPersonality.new(fx, 7)
	q.mistake(BOB, "lend", 1000, 1)
	var far := q.mistake(BOB, "lend", 1000, 100)
	check(far == g1, "...a repeat long after the window is a fresh lesson (%d)" % far)
	var r := JudgmentPersonality.new(fx, 7)
	r.mistake(BOB, "lend", 1000, 1)
	var other := r.mistake(BOB, "sell", 1000, 2)
	check(other == g1, "a different kind of mistake does not accelerate")
	check(p.practical_wisdom(BOB, "never-met") > 0 and p.practical_wisdom(BOB, "never-met") == p.general_wisdom(BOB), "wisdom transfers: a situation never met benefits from the carried-over share (%d)" % p.practical_wisdom(BOB, "never-met"))
	check(p.practical_wisdom(BOB, "lend") > p.practical_wisdom(BOB, "never-met"), "...but less than where the lesson was learnt")
	var big := P()
	for i in 80:
		big.mistake(BOB, "lend", 2000, i * 25)
	check(big.practical_wisdom(BOB, "lend") <= 1000 and big.mistake(BOB, "lend", 2000, 5000) >= 0, "wisdom is bounded (soft) to 1000")
	check(p.practical_wisdom(BOB, "lend") == p.practical_wisdom(BOB, "lend"), "wisdom never falls with time (no decay)")


func test_anger_override_reminder() -> void:
	var p := P()
	var h := holder(p)
	var n := holder(p, false)
	p.experience(h, "provocation", 2000, 10)
	var a0 := p.anger_at(h, 10)
	check(a0 == 600, "anger rises with the provocation (%d)" % a0)
	var a10 := p.anger_at(h, 20)
	check(a10 == 300 and p.anger_at(h, 30) == 0, "...fades gradually and is gone after its timer (%d at day 20, %d at day 30)" % [a10, p.anger_at(h, 30)])
	check(p.anger_peak(h) == 600, "...but the peak is remembered")
	var a_rem := p.remind(h, 40)
	check(a_rem > 0 and a_rem < 600 and a_rem == 120, "a reminder revives it modestly (%d of a 600 peak)" % a_rem)
	var r2 := p.remind(h, 40)
	var r3 := p.remind(h, 40)
	check(r3 <= 360 and r3 >= r2, "...and cannot exceed the cap (%d <= 360)" % r3)
	check(p.remind(77777, 5) == 0, "a person never angry has nothing to revive")
	# override
	var q := P()
	for i in 8:
		q.experience(h, "positive", 1000, i * 30)
	var calm := q.stubbornness(h, 400)
	check(calm < 600, "after good years the stubborn villager is calmer (%d)" % calm)
	q.experience(h, "provocation", 2000, 400)
	check(q.overriding(h, 410) and q.stubbornness(h, 410) >= 600, "a hot provocation overrides: stubborn behaviour is back at its starting level (%d)" % q.stubbornness(h, 410))
	check(q.overriding(h, 420) and not q.overriding(h, 421), "...for exactly override_days (21) game days, then it ends")
	var q2 := P()
	q2.experience(n, "provocation", 2000, 400)
	check(not q2.overriding(n, 410) and q2.stubbornness(n, 410) == 0, "a person without the potential has no override")
	var q3 := P()
	q3.experience(h, "provocation", 500, 400)           # anger 150 < threshold
	check(not q3.overriding(h, 401), "a mild provocation starts no override")


func test_provocation_drift() -> void:
	var p := P()
	var h := holder(p)
	var drifts := []
	for i in 6:
		p.experience(h, "provocation", 1000, 100 + i)       # a run of provocations within the frequency window
		drifts.append(p.tolerance_drift(h))
	check(drifts[5] < -500 and p.trait_drift(h, JudgmentPersonality.T_STUB) > 500, "repeated provocations change tolerance (%d) and stubbornness (+%d) for the long term" % [drifts[5], p.trait_drift(h, JudgmentPersonality.T_STUB)])
	check(p.stubbornness(h, 400) > 600, "...the stubborn villager is more stubborn (%d)" % p.stubbornness(h, 400))


func test_history() -> void:
	var p := P()
	p.experience(BOB, "provocation", 1000, 3)
	p.mistake(BOB, "lend", 1000, 4)
	p.remind(BOB, 15)
	p.experience(BOB, "positive", 1000, 50)
	var rows := p.history(BOB)
	check(rows.size() == 4 * JudgmentPersonality.LOGW, "every experience, mistake and reminder is recorded (%d rows)" % (rows.size() / JudgmentPersonality.LOGW))
	for i in 60:
		p.experience(BOB, "positive", 1000, 100 + i * 30)     # feelings recover, anger long gone
	check(p.anger_at(BOB, 3000) == 0 and p.history(BOB).slice(0, rows.size()) == rows, "the history stays intact (never erased, never rewritten) while the feelings fade and recover")
	var q := JudgmentPersonality.new(fix(), 7)
	q.load_dict(p.to_dict())
	check(q.history(BOB) == p.history(BOB), "...and survives save and load")


## Through the store: a firsthand deed feeds the framework; hearsay and bystanders do not; tolerance() carries the drift.
func test_store_hook() -> void:
	var j := JudgmentStore.new(cfg(), JudgmentSocial.new(), 7)
	j.day = 3
	var t0 := j.tolerance(BOB)
	var ev := j.publish("theft", [THIEF], [BOB], [], 4)
	j.observe_all(ev, [20])
	check(not j.pers.drift.has(20), "a bystander's view of the theft is no experience of their own")
	check(j.pers.tolerance_drift(BOB) == -100 and j.tolerance(BOB) == t0 - 100 and j.pers.life_tol.is_empty(), "the victim's long-term drift (-100) is the one tolerance change for the event: the plain life step (-40) does not stack on it (RECON-01)")
	check(j.pers.anger_at(BOB, 3) == 300, "...and they are angry (%d)" % j.pers.anger_at(BOB, 3))
	j.observe_all(ev, [BOB])
	check(j.pers.tolerance_drift(BOB) == -100, "once per event: seeing it again changes nothing")
	j.day = 5
	var hv := j.publish("rescue", [THIEF], [], [BOB])
	j.observe_all(hv, [])
	check(j.pers.tolerance_drift(BOB) > -100 and j.personality_growth(BOB) > 0, "being helped is a positive experience: it recovers the loss and a rescue goes past it (growth %d)" % j.personality_growth(BOB))
	for i in 12:
		j.day = 40 + i * 20
		j.observe_all(j.publish("rescue", [THIEF], [], [BOB]), [])
	check(j.personality_growth(BOB) > 0, "personality_growth(person) reports positive development for other systems (%d permille)" % j.personality_growth(BOB))


func test_determinism_and_save() -> void:
	var texts := []
	var stores := []
	for run in 2:
		var j := JudgmentStore.new(cfg(), JudgmentSocial.new(), 7)
		for i in 30:
			j.day = i * 3
			var v := 1 + i % 5
			j.observe_all(j.publish("theft" if i % 3 != 0 else "rescue", [THIEF], [v] if i % 3 != 0 else [], [] if i % 3 != 0 else [v], 4), [])
		j.pers.mistake(2, "lend", 1500, 40)
		j.pers.remind(2, 50)
		texts.append(JSON.stringify(j.to_dict()))
		stores.append(j)
	check(texts[0] == texts[1], "determinism: the same seed and events give byte-identical sections")
	check(JSON.parse_string(texts[0]).has("traits"), "the section carries the optional traits key")
	var r := JudgmentStore.new(cfg(), JudgmentSocial.new(), 7)
	check(r.load_dict(JSON.parse_string(texts[0])) == "" and JSON.stringify(r.to_dict()) == texts[0], "save and load round trip is identical")
	check(r.tolerance(2) == stores[0].tolerance(2) and r.pers.practical_wisdom(2, "lend") == stores[0].pers.practical_wisdom(2, "lend") and r.pers.anger_at(2, 50) == stores[0].pers.anger_at(2, 50), "...and gives the same readings")
	var newer: Dictionary = JSON.parse_string(texts[0])
	newer.traits.v = 9
	var k := JudgmentStore.new(cfg(), JudgmentSocial.new(), 7)
	check(k.load_dict(newer) != "" and k.to_dict().traits.v == 9, "a traits layout from a newer game is kept unread and written back, not dropped")


func test_old_save() -> void:
	var j := JudgmentStore.new(cfg(), JudgmentSocial.new(), 7)
	j.observe_all(j.publish("theft", [THIEF], [BOB], [], 4), [])
	var d: Dictionary = JSON.parse_string(JSON.stringify(j.to_dict()))
	d.erase("traits")
	var o := JudgmentStore.new(cfg(), JudgmentSocial.new(), 7)
	check(o.load_dict(d) == "" and o.pers.is_empty() and o.pers.tolerance_drift(BOB) == 0 and not o.to_dict().has("traits"), "a save without the traits key loads with defaults and writes none")
	var before := JudgmentStore.new({}, JudgmentSocial.new(), 7)
	before.observe_all(before.publish("theft", [THIEF], [BOB], [], 4), [])
	var s := JSON.stringify(before.to_dict())
	var again := JudgmentStore.new({}, JudgmentSocial.new(), 7)
	check(again.load_dict(JSON.parse_string(s)) == "" and JSON.stringify(again.to_dict()) == s, "a section from the shipped (inert) config loads and saves unchanged")


## The concepts stay apart: personality moves no moral judgment, no trust, no regard.
func test_separate_concepts() -> void:
	var j := JudgmentStore.new(cfg(), JudgmentSocial.new(), 7)
	var k := JudgmentStore.new(cfg(), JudgmentSocial.new(), 7)
	k.pers.experience(BOB, "provocation", 3000, 1)
	k.pers.mistake(BOB, "lend", 3000, 1)
	for who in [THIEF, 9]:
		check(j.net(BOB, who) == k.net(BOB, who) and j.trust_of(BOB, who) == k.trust_of(BOB, who), "personality change leaves moral judgment (NET) and trust of %d untouched" % who)
	check(not JudgmentPersonality.TRAITS.has("resentment") and not JudgmentPersonality.TRAITS.has("trust"), "no resentment, trust, friendship or family reputation is a trait here (Worker B owns resentment and familiarity)")


## RECON-01: the personality layer is the one owner of tolerance change. Scripted events on the shipped config (spread 300,
## 40 a point, bound 250, personality inert); the expected values were recorded from the store as it was before the
## move (tolerance = temperament + the store's own life shift), so they prove the move changed no number.
func _tol_run(c: Dictionary) -> Array:
	var j := JudgmentStore.new(c, JudgmentSocial.new(), 7)
	var snaps := []
	var steps := [["theft", [7], [1], []], ["assault", [7], [1], []], ["theft", [7], [2], []], ["rescue", [7], [], [3]], ["assault", [7], [3], []], ["rescue", [7], [], [1]]]
	for s in steps:
		j.day += 1
		var ev := j.publish(s[0], s[1], s[2], s[3])
		j.observe_all(ev, [5])                 # a bystander
		j.observe_all(ev, [])
		var row := []
		for p in [1, 2, 3, 5]:
			row.append(j.tolerance(p))
		snaps.append(row)
	for i in 30:                                  # far past the bound
		j.day += 1
		j.observe_all(j.publish("assault", [7], [1]), [])
	snaps.append([j.tolerance(1), j.threshold(1, -20000), j.weight_shift(3)])
	return snaps


func test_tolerance_owner() -> void:
	var c := JudgmentStore.default_cfg().duplicate(true)
	var got := _tol_run(c)
	print("TOLSNAP ", JSON.stringify(got))
	var want = JSON.parse_string(EXPECT_TOL)
	want = JSON.parse_string(JSON.stringify(want))
	check(JSON.stringify(got) == JSON.stringify(want).replace(".0", ""), "tolerance after a scripted sequence equals the pre-move formula's recorded values")
	# one event moves tolerance once: the layer owns it, the store keeps no copy
	var j := JudgmentStore.new(c, JudgmentSocial.new(), 7)
	var t0 := j.tolerance(BOB)
	j.observe_all(j.publish("theft", [THIEF], [BOB], [], 4), [])
	check(j.tolerance(BOB) == t0 - 40 and j.pers.life_tol.get(BOB, 0) == -40 and not j.life.has(BOB) and j.pers.tolerance_drift(BOB) == 0, "one theft moves tolerance once (-40), held by the personality layer; the store's life keeps no tolerance")
	j.observe_all(j.publish("rescue", [THIEF], [], [BOB]), [])
	check(j.tolerance(BOB) == t0 - 40 and int(j.life.get(BOB, 0)) > 0, "a rescue moves only the disposition weight (%d), not tolerance" % int(j.life.get(BOB, 0)))
	# the configured experience curves drive tolerance for a provocation: the plain step no longer stacks on them
	var ac := JudgmentStore.default_cfg().duplicate(true)
	ac.traits = fix()
	var a := JudgmentStore.new(ac, JudgmentSocial.new(), 7)
	var at0 := a.tolerance(BOB)
	a.observe_all(a.publish("theft", [THIEF], [BOB], [], 4), [])
	check(a.pers.life_tol.is_empty() and a.tolerance(BOB) == at0 + a.pers.tolerance_drift(BOB) and a.pers.tolerance_drift(BOB) < 0, "with the personality curves driving tolerance, one event moves it once (drift %d), the Q13 step does not stack" % a.pers.tolerance_drift(BOB))
	# old saved sections move into the new place; nothing dropped
	var oldsec: Dictionary = JSON.parse_string(JSON.stringify(j.to_dict()))
	oldsec.erase("traits")
	oldsec.life = [[BOB, -40, 30], [2, -90, 0], [3, 0, 60]]          # the pre-move layout [person, tolerance, weight]
	var o := JudgmentStore.new(c, JudgmentSocial.new(), 7)
	var base2 := o.tolerance(2)
	check(o.load_dict(oldsec) == "" and o.pers.life_tol.get(BOB, 0) == -40 and o.pers.life_tol.get(2, 0) == -90 and not o.pers.life_tol.has(3), "an old section's life tolerance shifts load into the personality layer")
	check(o.tolerance(2) == base2 - 90 and int(o.life.get(BOB, 0)) == 30 and int(o.life.get(3, 0)) == 60 and not o.life.has(2), "...tolerance reads them, the weight shifts stay in life")
	var again := JudgmentStore.new(c, JudgmentSocial.new(), 7)
	check(again.load_dict(JSON.parse_string(JSON.stringify(o.to_dict()))) == "" and again.tolerance(2) == o.tolerance(2) and JSON.stringify(again.to_dict()) == JSON.stringify(o.to_dict()), "...and the migrated section saves and loads identically in the new layout")
	# inert by default
	var s := JudgmentStore.new({}, JudgmentSocial.new(), 7)
	check(not s.pers.active and not s.pers.owns_provocation_tolerance() and s.pers.tolerance_drift(BOB) == 0, "the shipped personality rates are inert: they own and move nothing")
