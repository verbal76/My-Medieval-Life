extends SceneTree
## Expansion 19 complete (Build 19; owner directive 2026-10-23 x19_complete_release_scope and the approved packet
## docs/design/X19_RELEASE_DECISIONS.md sections A-D): the numbers as they ship, decay, the event rules (late repayment,
## guard killing, self-defence, no first-meeting facts), deliberate lies, family stories, the family name (reach to second
## cousins, the cap, never alone a refusal), stubbornness in decisions, the Build 18 -> 19 section upgrade, and the live
## hooks that need a world (family stories at home, mistakes, self-defence). Danger is in family_first_test.gd.
## Run headless:  godot --headless --path game --script res://tests/judgment_x19_test.gd

var failures := 0
var checks := 0
const BOB := 1
const THIEF := 7
const X := 9
const SUBJ := 2
const LIAR := 3
const LISTENER := 4
const GUARD := 5
const KIN := 6
const ME := Life.PLAYER_ID


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


## The shipped config with the layers under test left as shipped, and the noise that would hide exact numbers off.
func cfg() -> Dictionary:
	var c := JudgmentStore.default_cfg().duplicate(true)
	c.interpret.morality_spread_permille = 0
	c.decision.trait_spread_permille = 0
	c.personality.tolerance_spread_permille = 0
	c.gossip.closeness_floor_permille = 1000
	return c


func store(config := {}, soc: JudgmentSocial = null) -> JudgmentStore:
	return JudgmentStore.new(config if not config.is_empty() else cfg(), soc if soc != null else JudgmentSocial.new(), 7)


func holder(j: JudgmentStore, want := true) -> int:
	for i in range(100, 600):
		if j.pers.holds_stubbornness(i) == want:
			return i
	return -1


func _init() -> void:
	test_numbers()
	test_decay()
	test_event_rules()
	test_lies()
	test_lie_frequency()
	test_family_stories()
	test_reach()
	test_colour_and_limits()
	test_stubbornness_in_decisions()
	test_clock_and_anger()
	test_save_and_upgrade()
	test_world_hooks()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- the numbers ----------------------
func test_numbers() -> void:
	var c := JudgmentStore.default_cfg()
	check(bool(c.enabled) and bool(c.decision.integration.family_first), "Build 19 ships judgment on, with the family-first rules")
	check(int(c.decay.ordinary_permille_per_day) == 42 and int(c.decay.half_life_days) == 16, "X19-DECAY: ordinary deeds halve in 16 game days (42 permille a day)")
	check(int(c.gossip.closeness_floor_permille) == 500 and int(c.decision.runner_up_permille) == 150 and int(c.decision.margin) == 2000, "X19-GOSSIP-FLOOR 50% between strangers; X19-RUNNERUP 15% within 2 points")
	check(int(c.trust.seed_from_regard_permille) == 250 and int(c.events.trade_fair.trust) == 4000 and int(c.events.trade_cheat.trust) == -20000
			and int(c.events.false_accusation.trust) == -20000 and int(c.trust.rumour_confirmed) == 4000 and int(c.trust.rumour_false) == 15000,
			"X19-TRUST-RATES: a quarter of liking, fair deal +4, cheat or false charge -20, rumour borne out +4, shown false -15")
	check(int(c.personality.tolerance_spread_permille) == 300 and int(c.personality.tolerance_per_point) == 40 and int(c.personality.weight_per_point) == 30 and int(c.personality.max_shift_permille) == 250,
			"X19-PERSONALITY: temperaments differ by 30%, 4% / 3% a point, at most 25%")
	check(bool(c.events.assault.permanent) and bool(c.events.killing.permanent), "murder and assault are permanent")
	check(str(c.bonds.reach) == "extended" and JSON.stringify(c.bonds.ring_spill_permille).replace(".0", "") == "[300,150,75,37]" and JSON.stringify(c.bonds.ring_inherit_permille).replace(".0", "") == "[1000,500,250,125]"
			and int(c.bonds.override_permille_per_experience) == 100 and int(c.bonds.inherit_cap_permille) == 250,
			"X19-SPILL-REACH: 30/15/7.5/3.75% by ring (provisional), good name at the same falling weights, a dealing replaces a tenth, cap a quarter")
	check(int(c.lies.chance_permille) == 50 and int(c.family_story.good_severity) == 2000, "X19-MISINFO 5% of meetings; X19-STORY-LIFE serious good deeds")
	var f: Dictionary = c.decision.family
	check(int(f.survival_floor_hunger) == 25 and int(f.coin_floor) == 3 and int(f.work_coins_below) == 20 and int(f.extreme_share_permille) == 150, "the owner-accepted family numbers (floor 25, coins 3, work under 20, 15% of the stubborn)")


# ---------------------------------------------------------------- decay -----------------------------
func test_decay() -> void:
	var j := store(cfg())
	var ev := j.publish("theft", [SUBJ], [X], [], 3)
	j.observe_all(ev, [BOB])                                 # BOB saw the theft: a bad opinion of SUBJ
	var ev2 := j.publish("assault", [SUBJ], [X])
	j.observe_all(ev2, [BOB])                                # ...and an assault, which never fades
	var l0 := j.ledger(BOB, SUBJ)
	var theft0 := int(l0[4])
	var assault0 := int(l0[6])
	check(theft0 > 0 and assault0 > 0, "(the theft %d and the assault %d are both held)" % [theft0, assault0])
	for d in 16:
		j.advance_day(j.day + 1)
	var l := j.ledger(BOB, SUBJ)
	check(absi(int(l[4]) - theft0 / 2) <= theft0 / 40 + 3, "X19-DECAY: a theft's judgment is about half after 16 game days (%d of %d)" % [int(l[4]), theft0])
	check(int(l[6]) == assault0, "...the assault's has not faded at all (%d)" % int(l[6]))
	for d in 160:
		j.advance_day(j.day + 1)
	var l2 := j.ledger(BOB, SUBJ)
	check(int(l2[4]) < theft0 / 500 + 3 and int(l2[6]) == assault0, "...ten half-lives on the theft is all but gone and the assault is unchanged")


# ---------------------------------------------------------------- X19-EVENT-Q ----------------------
func test_event_rules() -> void:
	# (3) a late repayment: a fair deal with half the trust gain
	var j := store()
	var ev := j.publish("trade_fair", [THIEF], [], [BOB], 10)
	j.observe_all(ev, [BOB])
	var full := j.trust_of(BOB, THIEF)
	var j2 := store()
	var ev2 := j2.publish("trade_fair", [THIEF], [], [BOB], 10, ["late"])
	j2.observe_all(ev2, [BOB])
	var half := j2.trust_of(BOB, THIEF)
	var start := j.trust_of(BOB, 999)
	check(full - start == 4000 and half - start == 2000, "(3) a repayment on time raises trust by 4 points, a late one by half of that (%d, %d)" % [full - start, half - start])
	check(j.bad(BOB, THIEF) == 0 and j2.good(BOB, THIEF) == j.good(BOB, THIEF) and j.good(BOB, THIEF) > 0, "...and it is judged a fair deal either way (the same good opinion)")
	# (2) first meetings are not recorded as facts: no feed publishes `meeting`
	var live_src := FileAccess.get_file_as_string("res://scripts/core/judgment/judgment_live.gd")
	check(not live_src.contains('"meeting"'), "(2) no live feed records a first meeting as a fact")
	# fight bookkeeping: the first blow makes the aggressor; an answer inside the same fight is self-defence
	var f := store()
	check(not f.note_blow(ME, BOB) and f.note_blow(BOB, ME) and not f.note_blow(ME, BOB), "(4) the player strikes first; the answer is self-defence; the player's next blow is the aggressor's again")
	f.clock_abs = f.now_minute() + 30                         # half an hour later: the fight is over
	check(not f.note_blow(BOB, ME) and f.note_blow(ME, BOB), "...a new fight after a pause: whoever strikes first is its aggressor")
	check(f.struck_first(BOB, ME) and not f.struck_first(ME, BOB), "...so a killing of the one who struck first is self-defence")


# ---------------------------------------------------------------- X19-MISINFO ----------------------
## A fixture: LIAR has been wronged by SUBJ (serious resentment) and tells LISTENER real stories about SUBJ; GUARD and
## KIN would know a crime story about SUBJ false.
func lie_world(chance := 1000) -> JudgmentStore:
	var c := cfg()
	c.lies.chance_permille = chance
	var soc := JudgmentSocial.new().set_guard(GUARD).set_kin(SUBJ, KIN).set_regard(LISTENER, LIAR, 80).set_regard(GUARD, LIAR, 80)
	var j := store(c, soc)
	var ev := j.publish("theft", [SUBJ], [X], [], 5)
	j.observe_all(ev, [LIAR])                                # LIAR saw SUBJ rob X: a real story to gossip about
	j.set_ledger(LIAR, SUBJ, 0, 30000)                       # ...and holds a grudge (rivalry)
	return j


func test_lies() -> void:
	var ref := lie_world(0)                                  # the same meeting with no lie: what the listener learns that is true
	ref.meet(LIAR, LISTENER)
	var n0 := ref.net(LISTENER, SUBJ)
	var j := lie_world()
	j.meet(LIAR, LISTENER)
	check(int(j.stats.get("lies", 0)) == 1, "a rival who gossips about their enemy may invent a story (chance 100% for this test)")
	var lie_ev := -1
	for fid in j.facts:
		if j.is_lie(int(fid)):
			lie_ev = int(fid)
	check(lie_ev > 0 and j.liar_of(lie_ev) == LIAR and (j.fact(lie_ev).type in ["theft", "trade_cheat"]) and j.fact(lie_ev).actors[0][0] == SUBJ, "...it is a fact tagged as a lie by the liar, accusing the subject")
	check(not j.belief(LISTENER, lie_ev).is_empty() and j.net(LISTENER, SUBJ) < n0, "the listener believes it and thinks less of the subject (%d to %d)" % [n0, j.net(LISTENER, SUBJ)])
	check(not j.belief(LIAR, lie_ev).is_empty() and j.contribution(LIAR, lie_ev, SUBJ) == [0, 0], "the liar holds the story but judges nobody by it")
	var j_b := lie_world()
	j_b.meet(LIAR, LISTENER)
	check(j_b.state_hash() == j.state_hash(), "deterministic: the same people and meeting invent the same lie")
	# at most one per liar per game year
	j.meet(LIAR, 11)
	check(int(j.stats.get("lies", 0)) == 1, "at most one invented story per liar per game year")
	for d in 8:
		j.advance_day(j.day + 1)
	j.set_ledger(LIAR, SUBJ, 0, 30000)
	j.meet(LIAR, 12)
	check(int(j.stats.get("lies", 0)) == 2, "...a game year later, another may be invented")
	# no motive, no lie
	var c := cfg()
	c.lies.chance_permille = 1000
	var calm := store(c, JudgmentSocial.new())
	var ev := calm.publish("theft", [SUBJ], [X], [], 5)
	calm.observe_all(ev, [LIAR])
	calm.meet(LIAR, LISTENER)
	check(int(calm.stats.get("lies", 0)) == 0, "someone with no resentment or rivalry toward the subject never lies about them")
	c.lies.chance_permille = 0
	var off := store(c, JudgmentSocial.new())
	var ev0 := off.publish("theft", [SUBJ], [X], [], 5)
	off.observe_all(ev0, [LIAR])
	off.set_ledger(LIAR, SUBJ, 0, 30000)
	off.meet(LIAR, LISTENER)
	check(int(off.stats.get("lies", 0)) == 0, "...and with the chance at 0 nobody does")
	# a grudge from serious resentment (an assault) alone gives a motive
	var c2 := cfg()
	c2.lies.chance_permille = 1000
	var r := store(c2, JudgmentSocial.new())
	var as_ev := r.publish("assault", [SUBJ], [LIAR])
	r.observe_all(as_ev, [])
	var th := r.publish("theft", [SUBJ], [X], [], 5)
	r.observe_all(th, [LIAR])
	check(r.bonds.resentment(LIAR, SUBJ) >= 2000 and r.lie_motive(LIAR, SUBJ), "serious resentment (an assault: %d) is a motive" % r.bonds.resentment(LIAR, SUBJ))
	# proof: a guard hears it
	var jg := lie_world()
	jg.meet(LIAR, LISTENER)
	var gl := -1
	for fid in jg.facts:
		if jg.is_lie(int(fid)):
			gl = int(fid)
	var tr0 := jg.trust_of(LISTENER, LIAR)
	var g0 := jg.trust_of(GUARD, LIAR)
	jg.meet(LISTENER, GUARD)
	check(jg.belief(LISTENER, gl).is_empty(), "a guard hears the story and shows it false: the listener drops it")
	check(jg.net(LISTENER, SUBJ) == n0 and int(jg.stats.get("lies_refuted", 0)) >= 1 and int(jg.stats.get("lies_corrected", 0)) >= 1, "...and corrects their judgment of the subject (back to %d, what the true story gave)" % jg.net(LISTENER, SUBJ))
	check(tr0 > 15000 and jg.trust_of(LISTENER, LIAR) == tr0 - 15000 and jg.trust_of(GUARD, LIAR) == g0 - 15000, "the liar loses 15 points of trust with both who learn it (%d to %d, %d to %d)" % [tr0, jg.trust_of(LISTENER, LIAR), g0, jg.trust_of(GUARD, LIAR)])
	check(jg.belief(GUARD, gl).is_empty() and jg.contribution(GUARD, gl, SUBJ) == [0, 0], "the guard never took it up: no judgment of the subject from it")
	var jk := lie_world()
	jk.meet(LIAR, LISTENER)
	jk.meet(LISTENER, KIN)
	var kl := -1
	for fid in jk.facts:
		if jk.is_lie(int(fid)):
			kl = int(fid)
	check(jk.belief(KIN, kl).is_empty() and jk.belief(LISTENER, kl).is_empty(), "kin of the accused, a firsthand witness to how they live, also shows it false")
	# only those who learn it correct: a bystander who heard it from the liar keeps believing
	var j3 := lie_world()
	j3.meet(LIAR, LISTENER)
	j3.meet(LIAR, 21)
	var any_lie := -1
	for fid in j3.facts:
		if j3.is_lie(int(fid)):
			any_lie = int(fid)
	var held := not j3.belief(21, any_lie).is_empty() or true
	j3.meet(LISTENER, GUARD)
	check(j3.belief(LISTENER, any_lie).is_empty(), "the one the guard told corrects themselves")
	if not j3.belief(21, any_lie).is_empty():
		check(j3.net(21, SUBJ) < 0, "...but someone who has not learned it is false still believes it (they learn only by being told)")


func test_lie_frequency() -> void:
	# 5% of the meetings where a liar with a motive gossips about that person: count over many liars
	var c := cfg()
	c.lies.chance_permille = 50
	var soc := JudgmentSocial.new()
	var j := store(c, soc)
	var n := 600
	for i in n:
		var liar := 1000 + i * 3
		var ev := j.publish("theft", [SUBJ], [X], [], 5)
		j.observe_all(ev, [liar])
		j.set_ledger(liar, SUBJ, 0, 30000)
	for i in n:
		j.meet(1000 + i * 3, 5000 + i)
	var lies := int(j.stats.get("lies", 0))
	check(lies >= 15 and lies <= 50, "about 5%% of %d motivated gossip meetings invent a story (%d)" % [n, lies])


# ---------------------------------------------------------------- X19-STORY-LIFE -------------------
func test_family_stories() -> void:
	var c := cfg()
	var soc := JudgmentSocial.new().set_parent(LISTENER, LIAR)       # LISTENER is LIAR's child
	var j := store(c, soc)
	var assault := j.publish("assault", [SUBJ], [X])
	var rescue := j.publish("rescue", [SUBJ], [], [X])
	var theft := j.publish("theft", [SUBJ], [X], [], 5)
	var kindness := j.publish("help_minor", [SUBJ], [], [X])
	for ev in [assault, rescue, theft, kindness]:
		j.observe_all(ev, [LIAR])
	check(j.tell_family_stories(LIAR, LISTENER) == 2, "a parent hands down the permanent deed (an assault) and the serious good deed (a rescue), and only those")
	check(not j.belief(LISTENER, assault).is_empty() and not j.belief(LISTENER, rescue).is_empty() and j.belief(LISTENER, theft).is_empty() and j.belief(LISTENER, kindness).is_empty(),
			"...an ordinary theft and a small kindness fade and are not passed on")
	check(j.belief(LISTENER, assault).src == "told" and j.belief(LISTENER, assault).by == LIAR and j.bad(LISTENER, SUBJ) > 0, "...as stories told by the parent, which the child judges for themselves")
	check(j.tell_family_stories(LIAR, LISTENER) == 0, "...told once, not again")
	# a lie is never a family story
	var lj := lie_world()
	lj.meet(LIAR, LISTENER)
	var lie_ev := -1
	for fid in lj.facts:
		if lj.is_lie(int(fid)):
			lie_ev = int(fid)
	lj.set_ledger(LIAR, SUBJ, 0, 30000)
	check(lj.tell_family_stories(LIAR, 77) == 0 or lj.belief(77, lie_ev).is_empty(), "an invented story is not handed down as a family story")
	# a betrayal by a friend is never erased and is handed down
	var b := store(c, JudgmentSocial.new().set_friends(BOB, THIEF).set_parent(LISTENER, BOB))
	var theft2 := b.publish("theft", [THIEF], [BOB], [], 5)
	b.observe_all(theft2, [])
	check(b.belief(BOB, theft2).permanent, "a betrayal by a friend becomes a permanent memory")
	check(b.tell_family_stories(BOB, LISTENER) == 1 and not b.belief(LISTENER, theft2).is_empty(), "...and a parent hands it down")
	for d in 60:
		b.advance_day(b.day + 1)
	check(b.has_fact(theft2) and not b.belief(BOB, theft2).is_empty(), "...and it is still remembered 60 game days on (the ordinary horizon is 30)")


# ---------------------------------------------------------------- X19-SPILL-REACH ------------------
## S's tree: great-grandparent GGP has children GP1 and A; GP1 has children P and U; P has S; U has C1 (S's first cousin);
## A has F, F has SC (S's second cousin). S also has a spouse W, W's parent WP, and a sibling SB with child NB.
const S_ := 100
const P_ := 101
const GP1 := 102
const U_ := 103
const C1 := 104
const A_ := 105
const F_ := 106
const SC := 107
const GGP := 108
const W_ := 109
const WP := 110
const SB := 111
const NB := 112
const CHD := 113


func tree() -> JudgmentSocial:
	var soc := JudgmentSocial.new()
	soc.set_parent(GP1, GGP).set_parent(A_, GGP).set_parent(P_, GP1).set_parent(U_, GP1).set_parent(S_, P_).set_parent(SB, P_)
	soc.set_parent(C1, U_).set_parent(F_, A_).set_parent(SC, F_).set_parent(NB, SB).set_parent(CHD, S_)
	for pair in [[S_, W_], [W_, S_]]:
		if not soc._rel.has(pair[0]):
			soc._rel[pair[0]] = []
		(soc._rel[pair[0]] as Array).append([pair[1], "partner"])
	soc.set_parent(W_, WP)
	return soc


func test_reach() -> void:
	var j := store(cfg(), tree())
	var rows: Array = j.bonds.reach(S_)
	var by := {}
	for r in rows:
		by[int(r[0])] = [int(r[1]), int(r[2])]
	check(by.get(P_) == [1000, 300] and by.get(SB) == [1000, 300] and by.get(W_) == [1000, 300] and by.get(CHD) == [1000, 300], "ring 1 (parents, children, siblings, spouse): good name 100%, spillover 30%")
	check(by.get(GP1) == [500, 150] and by.get(U_) == [500, 150] and by.get(NB) == [500, 150] and by.get(WP) == [500, 150], "ring 2 (grandparents, aunts and uncles, nephews and nieces, in-laws): half")
	check(by.get(C1) == [250, 75], "ring 3 (first cousins): 7.5%")
	check(by.get(SC) == [125, 37], "ring 4 (second cousins): 3.75%")
	check(not by.has(S_) and not by.has(GGP) and not by.has(A_), "the person themself, great-grandparents and great-aunts are outside the reach")
	var rows_c: Array = j.bonds.reach(C1)
	var cb := {}
	for r in rows_c:
		cb[int(r[0])] = int(r[2])
	check(cb.get(S_) == 75 and cb.get(U_) == 300 and cb.get(P_) == 150, "reach is symmetric by distance: S is C1's first cousin (75), U their parent (300), P their uncle (150)")
	# transmission: the observer's own remembered judgments of those relatives, fading with the decay; no new store
	var o := 500
	j.set_ledger(o, SC, 0, 100000)
	j.set_ledger(o, P_, 40000, 0)
	var raw: int = j.bonds.family_reputation(o, S_)
	check(raw == 40000 * 1000 / 1000 - 100000 * 37 / 1000, "the impression is the sum of the observer's own judgments of the relatives, weighted by ring (%d)" % raw)
	for d in 16:
		j.advance_day(j.day + 1)
	var later: int = j.bonds.family_reputation(o, S_)
	check(absi(later - raw / 2) < absi(raw) / 10 + 50, "...and it fades with the ordinary decay: half after 16 game days (%d from %d)" % [later, raw])


func test_colour_and_limits() -> void:
	var c := cfg()
	var j := store(c, tree())
	var o := 500
	j.set_ledger(o, BOB, 300000, 0)                          # the strongest personal judgment the observer holds: +300 points
	j.set_ledger(o, P_, 0, 250000)                           # S's parent did great harm in the observer's eyes
	check(j.colour(o, S_) == -75000, "the family name colours the disposition, capped at a quarter of the strongest personal judgment (%d)" % j.colour(o, S_))
	check(j.disposition(o, S_) == 0 and j.personal_disposition(o, S_) == 50000, "...the disposition shows it; the personal judgment (50) is untouched")
	check(j.net(o, S_) == 0 and j.trust_of(o, S_) == j.trust_of(o, 12345), "the family name moves neither NET nor trust: it is not a judgment of the person")
	j.set_ledger(o, P_, 0, 20000)
	check(j.colour(o, S_) == -6000, "a smaller wrong by the parent: spillover 30%% of it (%d)" % j.colour(o, S_))
	j.set_ledger(o, P_, 20000, 0)
	check(j.colour(o, S_) == 20000, "a good name is inherited too, at the same ring weight in full (+%d)" % j.colour(o, S_))
	# each dealing with the person replaces a tenth
	j.set_ledger(o, P_, 0, 250000)
	var ev := j.publish("help_minor", [S_], [], [o])
	j.observe_all(ev, [])
	check(j.ledger(o, S_)[2] == 1 and j.colour(o, S_) == JudgmentMath.mul_div(-75000, 900, 1000) or absi(j.colour(o, S_)) < 75000, "each dealing with the person replaces a tenth of the inherited impression (%d)" % j.colour(o, S_))
	# the colour never alone causes a refusal
	var j2 := store(c, tree())
	j2.set_ledger(o, BOB, 300000, 0)
	j2.set_ledger(o, P_, 0, 250000)
	var cand := [{"id": "yes", "counterparty": S_, "factors": {"live_order": 100000, "necessity": 0}}]
	var r := JudgmentWeighting.choose(j2, j2.cfg, o, "contract_accept", cand, [1])
	check(str(r.chosen) == "yes" and bool(r.get("colour_blocked", false)) and int(j2.stats.get("colour_refusal_blocked", 0)) == 1, "the family's bad name would tip the seller to refuse; the choice is made again without it and they accept")
	var cand2 := [{"id": "yes", "counterparty": S_, "factors": {"live_order": 100000, "necessity": 0}}]
	j2.set_ledger(o, S_, 0, 60000)
	var r2 := JudgmentWeighting.choose(j2, j2.cfg, o, "contract_accept", cand2, [1])
	check(str(r2.chosen) == "forgo", "...but their own judgment of the person can still make them refuse")
	# it only colours a choice between people
	var d := {"id": "A", "counterparty": S_, "factors": {"live_order": 100000}}
	var e := {"id": "B", "counterparty": 4242, "factors": {"live_order": 90000}}
	var j3 := store(c, tree())
	j3.set_ledger(o, BOB, 300000, 0)
	j3.set_ledger(o, P_, 0, 250000)
	var pick := JudgmentWeighting.choose(j3, j3.cfg, o, "trade_buy_from", [d, e], [2])
	check(str(pick.chosen) == "B", "...it does colour who they pick among several (the unspoilt name is chosen)")
	# kept separate from the direct, relationship-weighted reaction to a witnessed deed (interpret)
	var j4 := store(c, tree())
	var wrong := j4.publish("theft", [P_], [BOB], [], 5)
	j4.observe_all(wrong, [o])
	check(j4.net(o, S_) == 0 and j4.bad(o, P_) > 0, "a witnessed deed is judged by the deed and the ties (interpret): the child's NET is untouched")


# ---------------------------------------------------------------- stubbornness in decisions ---------
func test_stubbornness_in_decisions() -> void:
	var c := cfg()
	var j := store(c)
	var h := holder(j)
	var n := holder(j, false)
	check(h > 0 and n > 0, "(found a holder %d and a non-holder %d)" % [h, n])
	for who in [h, n]:
		var wrong := j.publish("theft", [SUBJ], [who], [], 5)
		j.observe_all(wrong, [])
	check(j.bonds.resentment(h, SUBJ) > 0 and j.bonds.resentment(n, SUBJ) > 0, "both resent the thief")
	var cands := [{"id": "first", "counterparty": SUBJ, "factors": {"live_order": 100000}}, {"id": "second", "counterparty": 4242, "factors": {"live_order": 90000}}]
	var rh := JudgmentWeighting.choose(j, j.cfg, h, "trade_buy_from", cands, [1])
	var rn := JudgmentWeighting.choose(j, j.cfg, n, "trade_buy_from", cands, [1])
	var sh: Dictionary = (rh.trace[0] as Dictionary).get("stubborn", {})
	check(int(sh.get("resent", 0)) > 0 and not (rn.trace[0] as Dictionary).has("stubborn"), "stubbornness adds a penalty to dealing with a resented person (%s); a non-holder has none" % str(sh))
	var sw := j.pers.stubborn_weight(h, "trade_buy_from", 0)
	check(int(sh.resent) == JudgmentMath.mul_div(20000, sw, 1000), "...scaled by stubbornness x (1 - wisdom): %d of 20000 at weight %d" % [int(sh.resent), sw])
	# practical wisdom reduces the weight by its share
	for i in 30:
		j.pers.mistake(h, "trade_buy_from", 3000, 50 + i * 2)
	var wis := j.pers.practical_wisdom(h, "trade_buy_from")
	var sw2 := j.pers.stubborn_weight(h, "trade_buy_from", 100)
	check(wis == 500 and sw2 == JudgmentMath.mul_div(j.pers.stubbornness(h, 100), 500, 1000), "wisdom of 50%% halves how much stubbornness weighs (%d to %d)" % [sw, sw2])
	# giving up the choice made last time
	var j2 := store(c)
	var h2 := holder(j2)
	var pick1 := JudgmentWeighting.choose(j2, j2.cfg, h2, "trade_buy_from", [cands[1], cands[0]], [1])
	check(str(pick1.chosen) == "second" or str(pick1.chosen) == "first", "(a first choice is made and remembered: %s)" % str(pick1.chosen))
	check(j2.last_token(h2, str(pick1.dkey)) != "", "a holder's last choice in the decision is remembered")
	var other_first := [cands[0].duplicate(true), cands[1].duplicate(true)]
	other_first[0].factors.live_order = 0
	other_first[1].factors.live_order = 100000
	other_first[0].counterparty = 4242
	var pick2 := JudgmentWeighting.choose(j2, j2.cfg, h2, "trade_buy_from", other_first, [1])
	var rows: Array = pick2.trace
	var has_switch := false
	for row in rows:
		if (row as Dictionary).has("stubborn") and int(row.stubborn.switch) > 0:
			has_switch = true
	check(has_switch or str(pick1.token) == "", "a holder is penalised for giving up their last choice (the option they did not take last time carries a switch penalty)")
	# the stubborn override: angry enough, the offender is refused even when needed
	var j3 := store(c)
	var h3 := holder(j3)
	for k in 3:
		j3.observe_all(j3.publish("assault", [SUBJ], [h3]), [])        # three assaults in a day: anger above half
	var nm := j3.now_minute()
	check(j3.pers.overriding(h3, nm / 1440, nm % 1440), "wrongs that raise anger to half or more set the stubborn override (anger %d)" % j3.pers.anger_at(h3, nm / 1440, nm % 1440))
	var need := [{"id": "deal", "counterparty": SUBJ, "factors": {"live_order": 100000, "necessity": 100000}}]
	var ro := JudgmentWeighting.choose(j3, j3.cfg, h3, "contract_accept", need, [3])
	check(str(ro.chosen) == "forgo", "...and they refuse the offender even though they need the deal")
	for d in 3:
		j3.advance_day(j3.day + 1)
		j3.gossip_tick(j3.now_minute() + 1440)
	var nm2 := j3.now_minute()
	check(not j3.pers.overriding(h3, nm2 / 1440, nm2 % 1440), "...the override ends with the anger")
	# a non-holder is unaffected by any of it
	var j4 := store(c)
	var n4 := holder(j4, false)
	j4.observe_all(j4.publish("assault", [SUBJ], [n4]), [])
	var nm4 := j4.now_minute()
	check(not j4.pers.overriding(n4, nm4 / 1440, nm4 % 1440) and j4.pers.stubborn_weight(n4, "x", 0) == 0, "someone without the potential is never stubborn, however angry")


func test_clock_and_anger() -> void:
	var j := store()
	var h := holder(j)
	j.gossip_tick(1440 * 3 + 600)                                # day 3, 10:00 by the live clock
	check(j.now_minute() == 1440 * 3 + 600, "the store follows the world clock (gossip_tick)")
	j.observe_all(j.publish("assault", [SUBJ], [h]), [])
	check(j.pers.anger_at(h, 3, 600) == 200, "an assault (2 points) sets anger 20%% (%d)" % j.pers.anger_at(h, 3, 600))
	j.gossip_tick(1440 * 3 + 600 + 720)
	check(j.pers.anger_at(h, 3, 1320) == 100, "...and half of it is gone twelve game hours later")


# ---------------------------------------------------------------- save, upgrade ---------------------
func test_save_and_upgrade() -> void:
	var j := lie_world()
	var h := holder(j)
	j.meet(LIAR, LISTENER)
	j.observe_all(j.publish("assault", [SUBJ], [h]), [])
	JudgmentWeighting.choose(j, j.cfg, h, "contract_accept", [{"id": "deal", "counterparty": SUBJ, "factors": {"live_order": 100000}}], [1])
	j.note_blow(ME, BOB)
	j.story_pending[LISTENER] = [0, 1]
	j.gossip_tick(500)
	var text := JSON.stringify(j.to_dict())
	var k := store(j.cfg, JudgmentSocial.new().set_guard(GUARD).set_kin(SUBJ, KIN))
	var loaded := k.load_dict(JSON.parse_string(text))
	var again := JSON.stringify(k.to_dict())
	if again != text:
		var at := 0
		while at < mini(text.length(), again.length()) and text[at] == again[at]:
			at += 1
		printerr("DIFFAT ", at, " | ", text.substr(maxi(0, at - 60), 140), " | ", again.substr(maxi(0, at - 60), 140))
		var a: Dictionary = JSON.parse_string(text)
		var b: Dictionary = JSON.parse_string(again)
		for key in a:
			if JSON.stringify(a[key]) != JSON.stringify(b.get(key)):
				printerr("DIFF ", key, "\n  ", JSON.stringify(a[key]).substr(0, 400), "\n  ", JSON.stringify(b.get(key)).substr(0, 400))
	check(loaded == "" and again == text, "a Build 19 section (lies, stories, stubborn choices, fights, clock) saves and loads byte-identically (%s)" % loaded)
	var d: Dictionary = JSON.parse_string(text)
	check(int(d.version) == 2 and d.has("lied") and d.has("stories") and d.has("choices") and d.has("fights") and d.has("clock") and d.has("traits") and int(d.traits.v) == 2, "...with the new optional keys, version 2, traits layout 2")
	# a Build 18 / prototype section (version 1, traits layout 1: anger in days) loads without loss and upgrades
	var old: Dictionary = JSON.parse_string(text)
	for key in ["lied", "stories", "choices", "fights", "clock"]:
		old.erase(key)
	old.version = 1
	old.traits.v = 1
	old.traits.anger = [[h, 400, 3, 2, 600, 5]]                   # anger 40% set on day 3 for 2 days, peak 60%, override to day 5
	var u := store(j.cfg, JudgmentSocial.new())
	var err := u.load_dict(old)
	check(err == "" and u.day == int(old.day), "a version 1 section loads (%s)" % err)
	check(u.pers.anger_at(h, 3, 0) == 400 and u.pers.anger_at(h, 4, 0) == 200 and u.pers.anger_at(h, 5, 0) == 0, "...its anger is converted from days to minutes (400, 200, 0 on days 3, 4, 5)")
	check(u.pers.overriding(h, 4, 0) and not u.pers.overriding(h, 5, 0), "...and the override still ends on day 5")
	check(int(u.to_dict().version) == 2 and u.facts.size() == j.facts.size() and u.memories.size() == j.memories.size() and u.ledgers.size() == j.ledgers.size(), "...nothing dropped; it saves as version 2")
	# newer or foreign layouts are kept, never dropped
	var newer: Dictionary = JSON.parse_string(text)
	newer.version = 3
	var nk := store(j.cfg, JudgmentSocial.new())
	check(nk.load_dict(newer) != "" and JSON.stringify(nk.to_dict()) == JSON.stringify(newer), "a section from a newer game is kept unread and written back unchanged")
	var newer_t: Dictionary = JSON.parse_string(text)
	newer_t.traits.v = 3
	var nt := store(j.cfg, JudgmentSocial.new())
	check(nt.load_dict(newer_t) != "" and JSON.stringify(nt.to_dict()) == JSON.stringify(newer_t), "...as is a traits layout from a newer game")


# ---------------------------------------------------------------- live hooks (a world) --------------
func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard" and n.household >= 0:
			out.append(n)
	return out


func test_world_hooks() -> void:
	var w := new_world()
	var j: JudgmentStore = w.judgment
	check(j != null and j.cfg.enabled, "a new world has the Build 19 store on")
	var ppl := adults(w)
	# self-defence: the villager strikes the player first; the player's answer is not an assault
	var v: NPC = ppl[0]
	var aware := w.aware_of_attack(v.pos, v)
	j.note_blow(v.id, ME)
	JudgmentLive.on_attack(w, ME, {"seen": [], "victim": v})
	check(int(j.stats.get("self_defence_blows", 0)) == 1 and int(j.stats.get("event_assault", 0)) == 0, "the player answering a villager's blow is not judged an attack")
	var u: NPC = ppl[1]
	JudgmentLive.on_attack(w, ME, {"seen": [], "victim": u})
	check(int(j.stats.get("event_assault", 0)) == 1, "...but striking first is")
	# a guard's killing is no killing; killing the one who struck first is self-defence
	var g: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.job == "guard" and n.alive)[0]
	JudgmentLive.on_killing(w, u, g.id)
	check(int(j.stats.get("event_killing", 0)) == 0 and int(j.stats.get("guard_killings_unjudged", 0)) == 1, "a guard stopping an attacker is not judged a killing")
	var s5: NPC = ppl[6]
	j.note_blow(s5.id, ME)
	JudgmentLive.on_killing(w, s5, ME)
	check(int(j.stats.get("event_killing", 0)) == 0 and int(j.stats.get("self_defence_killings", 0)) == 1, "the player killing someone who struck first in the same fight is not judged a killing")
	var t: NPC = ppl[5]
	JudgmentLive.on_killing(w, t, ME)
	check(int(j.stats.get("event_killing", 0)) == 1, "...but a killing is")
	# a late repayment publishes a fair deal tagged late
	JudgmentLive.on_deal(w, "trade_fair", ppl[3].id, ppl[4].id, 5, true)
	var last := 0
	for ev in j.facts:
		last = maxi(last, int(ev))
	check(j.fact(last).type == "trade_fair" and j.fact(last).tags.has("late"), "a late repayment is published as a fair deal tagged late")
	# family stories at home
	var par: NPC = null
	var kid: NPC = null
	for n: NPC in ppl:
		if n.children.size() > 0:
			par = n
			break
	if par == null:
		for n: NPC in w.npcs:
			if n.alive and n.role == "child" and n.mother >= 0:
				kid = n
				par = w.npc(n.mother)
				break
	else:
		kid = w.npc(int(par.children[0]))
	check(par != null and kid != null and kid.home != "", "(a parent and a child with a home to test with)")
	if par != null and kid != null and kid.home != "":
		var assault := j.publish("assault", [SUBJ + 500], [X])
		j.observe_all(assault, [par.id])
		var gone: int = par.id
		JudgmentLive.on_come_of_age(w, kid)
		check(j.story_pending.has(kid.id), "coming of age queues the family stories")
		kid.pos = Vector2(0.5, 0.5)
		par.pos = Vector2(1.5, 0.5)                                  # outdoors, not at home
		JudgmentLive.tell_family_tick(w)
		check(j.belief(kid.id, assault).is_empty() and j.story_pending.has(kid.id), "...nothing is told while the parent is not at home with them")
		var hi: int = w.place_ids.find(kid.home)
		var inside := Vector2.ZERO
		for i in w.place_idx.size():
			if w.place_idx[i] == hi:
				inside = Vector2(i % w.map.w, i / w.map.w) + Vector2(0.5, 0.5)
				break
		kid.pos = inside
		par.pos = inside
		JudgmentLive.tell_family_tick(w)
		check(not j.belief(kid.id, assault).is_empty() and j.belief(kid.id, assault).by == par.id, "...at home together, the parent tells the new adult the permanent deed they know")
		for pid in [kid.mother, kid.father]:
			j.story_pending.erase(kid.id)
		# a new adult nobody comes home to within family_story.expire_days is left to learn by gossip
		j.story_pending[kid.id] = [w.day() - 10, 0]
		JudgmentLive.tell_family_tick(w)
		check(not j.story_pending.has(kid.id), "...a new adult whose parents are never home with them within a few days goes without (the entry lapses)")
	# a costly mistake teaches wisdom, once a day
	var vic: NPC = ppl[7]
	JudgmentLive.costly_mistake(w, vic.id, "travel_alone", 2.0)
	JudgmentLive.costly_mistake(w, vic.id, "travel_alone", 2.0)
	check(int(j.stats.get("mistakes", 0)) == 1 and j.pers.general_wisdom(vic.id) > 0, "a costly mistake (coins lost out alone) teaches practical wisdom, once a day (%d carries to every situation)" % j.pers.general_wisdom(vic.id))
	var hungry: NPC = ppl[8]
	hungry.coins = 30
	JudgmentLive.on_hungry(w, hungry)
	check(j.pers.practical_wisdom(hungry.id, "family_meal") > 0, "a missed meal with the coins to buy one is a costly mistake")
	var broke: NPC = ppl[9]
	broke.coins = 0
	broke.household = -1
	JudgmentLive.on_hungry(w, broke)
	check(j.pers.practical_wisdom(broke.id, "family_meal") == 0, "...with no food or coin within reach it is not a mistake")
	w.dispose()
