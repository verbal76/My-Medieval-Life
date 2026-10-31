extends SceneTree
## Expansion 20, owner decisions SJD-H C1, C2, C5 and C6 (docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md):
##   C1  judgment takes part in the decisions it should, can change their outcome, and is calibrated without forcing it:
##       between comparable options a meaningful tendency toward the one trusted or liked; a disliked sole source of a
##       desperately needed item is still used; positive and negative judgment both count; neutral judgment changes nothing.
##   C2  hearsay of an assault or a lesser offence fades by the ordinary memory rules while the opinion it formed persists
##       (under the unchanged decay, C6); first-hand weighs more; killing and the memories of those it touched (the victim,
##       eyewitnesses, the victim's family) stay permanent; old saves load as saved.
##   C5  mixed feelings in real decisions: dislike, respect for ability, fear, dependence, loyalty and remembered help or
##       harm compete inside the existing weighing (JudgmentWeighting), never one collapsed score, never an automatic refusal;
##       the owner's blacksmith example, across personalities and circumstances.
## Run headless:  godot --headless --path game --script res://tests/judgment_calibration_test.gd

var failures := 0
var checks := 0

const SMITH := 1
const BRO := 2
const ME_ := 3
const EYE := 4
const HEAR := 5
const KIN := 6
const MERCH := 7
const HEAR2 := 8
const COUSIN := 9


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


## The shipped numbers (trait spread, decay, gain), with gossip told at once and certainly (the reference mode) and the
## family name and lies off, so a bare store's meetings are exact.
func shipped() -> Dictionary:
	var c := JudgmentStore.default_cfg()
	c.gossip.timing = "hour"
	c.gossip.closeness_floor_permille = 1000
	c.bonds.reach = "none"
	c.lies.chance_permille = 0
	return c


func social() -> JudgmentSocial:
	return JudgmentSocial.new().set_kin(BRO, ME_).set_kin(BRO, KIN).set_regard(EYE, HEAR, 100).set_regard(EYE, KIN, 100) \
			.set_regard(EYE, HEAR2, 100)


func _init() -> void:
	test_c2_hearsay_fades_opinion_persists()
	test_c2_killing_and_family()
	test_c2_ordinary_decay_and_refresh()
	test_c2_old_saves()
	test_c2_save_growth()
	test_c1_gain_neutral_and_spec()
	test_c1_comparable_sellers_live()
	test_c1_positive_judgment_live()
	test_c1_yes_or_forgo_live()
	test_c1_bar_seller_live()
	test_c5_mixed_feelings_bare()
	test_c5_blacksmith_live()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- C2 ------------------------------
func test_c2_hearsay_fades_opinion_persists() -> void:
	var c := shipped()
	var j := JudgmentStore.new(c, social(), 7)
	var a := j.publish("assault", [SMITH], [BRO])
	j.observe_all(a, [EYE])
	check(bool(j.belief(BRO, a).permanent) and bool(j.belief(EYE, a).permanent), "the one assaulted and an eyewitness never forget it (first-hand)")
	check(j.meet(EYE, HEAR) >= 1 and not j.belief(HEAR, a).is_empty(), "the eyewitness tells a neighbour")
	check(not bool(j.belief(HEAR, a).permanent), "C2: the neighbour's hearsay memory of the assault is an ordinary one (it can fade)")
	var led := j.ledger(HEAR, SMITH)
	check(int(led[6]) > 0 and int(led[4]) == 0, "...while the opinion it formed is in the permanent part of the ledger, as X19-ASSAULT and C6 keep it (%s)" % str(led))
	check(j.bad(EYE, SMITH) > j.bad(HEAR, SMITH), "first-hand weighs more than second-hand (%d > %d)" % [j.bad(EYE, SMITH), j.bad(HEAR, SMITH)])
	var net0 := j.net(HEAR, SMITH)
	for d in range(1, 121):
		j.advance_day(d)
	check(j.belief(HEAR, a).is_empty(), "120 days on, the neighbour's hearsay memory has faded and gone (memory.salience_fade_permille)")
	check(j.net(HEAR, SMITH) == net0 and j.ledger(HEAR, SMITH) == led, "...and the opinion it formed is exactly as it was (no decay change, C6)")
	check(not j.belief(BRO, a).is_empty() and not j.belief(EYE, a).is_empty(), "the victim and the eyewitness still remember it")
	check(j.has_fact(a), "the fact is kept (assault judgments are permanent), so a re-telling is recognised")
	j.meet(EYE, HEAR)
	check(j.ledger(HEAR, SMITH) == led, "hearing the same story again after forgetting adds nothing (each event judged once)")
	var a2 := j.publish("assault", [SMITH], [EYE])
	j.observe_all(a2, [])
	j.meet(EYE, HEAR)
	check(int(j.ledger(HEAR, SMITH)[6]) > int(led[6]), "a new offence, heard of, strengthens the opinion (%d > %d)" % [int(j.ledger(HEAR, SMITH)[6]), int(led[6])])


func test_c2_killing_and_family() -> void:
	var j := JudgmentStore.new(shipped(), social(), 7)
	var a := j.publish("assault", [SMITH], [BRO])
	j.observe_all(a, [EYE])
	j.meet(EYE, KIN)
	check(not j.belief(KIN, a).is_empty() and bool(j.belief(KIN, a).permanent), "C2: told that a family member was assaulted, the memory is permanent (personally significant)")
	check(j.bad(KIN, SMITH) > j.bad(HEAR, SMITH), "family weighs the deed more than an unrelated listener would (kin interpretation)")
	var k := j.publish("killing", [SMITH], [COUSIN])
	j.observe(k, EYE)
	j.meet(EYE, HEAR2)
	check(not j.belief(HEAR2, k).is_empty() and bool(j.belief(HEAR2, k).permanent), "a killing stays permanent for everyone who hears of it (Q11, unchanged)")
	for d in range(1, 121):
		j.advance_day(d)
	check(not j.belief(KIN, a).is_empty() and not j.belief(HEAR2, k).is_empty(), "120 days on, both are still remembered")
	# a told memory later confirmed first-hand becomes permanent and counts once
	var j2 := JudgmentStore.new(shipped(), social(), 7)
	var b := j2.publish("assault", [SMITH], [BRO])
	j2.observe(b, EYE)
	j2.meet(EYE, HEAR)
	check(not bool(j2.belief(HEAR, b).permanent), "setup: hearsay")
	j2.observe(b, HEAR, "witnessed")
	check(bool(j2.belief(HEAR, b).permanent) and j2._perm_refs.get(b, 0) == 2, "seen with one's own eyes after hearing of it: permanent, counted once (%s)" % str(j2._perm_refs.get(b, 0)))


func test_c2_ordinary_decay_and_refresh() -> void:
	var j := JudgmentStore.new(shipped(), social(), 7)
	var t := j.publish("theft", [SMITH], [BRO])
	j.observe_all(t, [EYE])
	j.meet(EYE, HEAR)
	var fb0 := int(j.ledger(HEAR, SMITH)[4])
	check(fb0 > 0 and not bool(j.belief(HEAR, t).permanent), "a lesser offence heard of: an ordinary memory, the fading part of the opinion")
	for d in range(1, 17):
		j.advance_day(d)
	var fb16 := int(j.ledger(HEAR, SMITH)[4])
	check(fb16 * 2 >= fb0 - 2 and fb16 * 2 <= fb0 + 2, "the approved decay is unchanged: half in 16 days (%d -> %d)" % [fb0, fb16])
	var t2 := j.publish("theft", [SMITH], [EYE])
	j.observe_all(t2, [])
	j.meet(EYE, HEAR)
	check(int(j.ledger(HEAR, SMITH)[4]) > fb16, "a repeat refreshes the opinion (%d > %d)" % [int(j.ledger(HEAR, SMITH)[4]), fb16])


func test_c2_old_saves() -> void:
	var j := JudgmentStore.new(shipped(), social(), 7)
	var a := j.publish("assault", [SMITH], [BRO])
	j.observe_all(a, [EYE])
	j.meet(EYE, HEAR)
	var d: Dictionary = JSON.parse_string(JSON.stringify(j.to_dict()))
	var found := false
	for r in d.memories:
		if int(r[0]) == HEAR and int(r[1]) == a:
			r[10] = 1                              # as Builds 19-24 saved it: a bystander's assault memory, permanent
			found = true
	check(found, "setup: the hearsay memory is in the save")
	var j2 := JudgmentStore.new(shipped(), social(), 7)
	j2.load_dict(d)
	check(bool(j2.belief(HEAR, a).permanent), "an old save's permanent hearsay memory loads permanent: saved data is never reinterpreted")
	for r in d.memories:
		if int(r[0]) == HEAR and int(r[1]) == a:
			r.resize(10)                           # a round-1..3 row without flags: permanence by the type's rule of its day
	var j3 := JudgmentStore.new(shipped(), social(), 7)
	j3.load_dict(d)
	check(bool(j3.belief(HEAR, a).permanent), "a row saved without flags reads by the old rule (assault permanent), as before")
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var f := FileAccess.open("res://tests/fixtures/b24_save_v23_judgment.json", FileAccess.READ)
	if f == null:
		f = FileAccess.open("res://../tests/fixtures/b24_save_v23_judgment.json", FileAccess.READ)
	if f != null:
		var sd = JSON.parse_string(f.get_as_text())
		var jd: Dictionary = (sd.get("world", sd) as Dictionary).get("judgment", {})
		var jb := JudgmentStore.new({}, null, 1)
		var err := jb.load_dict(jd)
		var perm := 0
		for o in jb.memories:
			for ev in jb.memories[o]:
				perm += 1 if (jb.memories[o][ev][JudgmentStore.M_FLAGS] & 1) == 1 else 0
		check(err == "" and perm == 227, "the Build 24 fixture's judgment section loads with every permanent memory as saved (%d)" % perm)
	else:
		print("note: Build 24 fixture not found; judgment_soak_test covers it")
	w.dispose()


## Save growth: forty hearsay assaults told to one listener; with C2 the listener's memory is bounded and the section smaller,
## while the opinion (the ledger) is identical either way.
func test_c2_save_growth() -> void:
	var sizes := []
	var leds := []
	for legacy in [true, false]:
		var c := shipped()
		if legacy:
			c.events.assault.erase("memory")      # Builds 19-24: permanent for everyone who knows
		var j := JudgmentStore.new(c, social(), 7)
		for i in 40:
			var a := j.publish("assault", [SMITH], [100 + i])
			j.observe(a, EYE)
			j.meet(EYE, HEAR)
			j.advance_day(i + 1)
		for d in range(41, 120):
			j.advance_day(d)
		sizes.append(JSON.stringify(j.to_dict()).length())
		leds.append(j.ledger(HEAR, SMITH))
		if not legacy:
			check(j.memory_count(HEAR) == 0, "C2: the listener's forty hearsay assault memories faded (memories held %d)" % j.memory_count(HEAR))
	check(int(sizes[1]) < int(sizes[0]), "the judgment section is smaller with fading hearsay (%d < %d bytes)" % [sizes[1], sizes[0]])
	check(leds[0] == leds[1], "...and the opinion formed is identical either way (%s)" % str(leds[1]))


# ---------------------------------------------------------------- C1 ------------------------------
func test_c1_gain_neutral_and_spec() -> void:
	var c := shipped()
	check(int(c.decision.get("opinion_gain_permille", 1000)) > 1000, "C1: decisions read an opinion with a gain above the raw 50 + NET (%d permille)" % int(c.decision.get("opinion_gain_permille", 1000)))
	var j := JudgmentStore.new(c, social(), 7)
	j.set_ledger(ME_, SMITH, 0, 1000)
	check(j.disposition(ME_, SMITH) == 49000, "the store's disposition is still the spec's 50 + NET (s.7.3), unchanged")
	var o := JudgmentWeighting.opinion(j, c, "trade_sell", ME_, SMITH, true)
	check(int(o[0]) == 50000 - JudgmentMath.mul_div(1000, int(c.decision.opinion_gain_permille), 1000), "the decision factor is 50 - gain x 1 point (%d)" % int(o[0]))
	check(int(JudgmentWeighting.opinion(j, c, "trade_sell", ME_, MERCH, true)[0]) == 50000, "no opinion: exactly neutral")


## Two comparable sellers (the same trade, the same tier of the live rule): a meaningful tendency toward the one trusted or
## liked; neutral judgment: the live rule's own pick, every time.
func test_c1_comparable_sellers_live() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var sellers := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "carpenter":
			sellers.append(o)
	var buyers := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "carpenter" and o.job != "woodcutter" and o.job != "guard" and w.brain.buy_role(o) != "merchant_raw":
			buyers.append(o)
	if sellers.size() < 2:
		var extra: NPC = buyers.pop_back()
		extra.job = "carpenter"
		NPC.roles_version += 1
		sellers.append(extra)
	if sellers.size() < 2:
		sellers.append(buyers.pop_back())
		sellers[-1].job = "carpenter"
		NPC.roles_version += 1
	for o: NPC in w.npcs:
		o.inv.remove("plank", o.inv.count("plank"))
	sellers[0].inv.add("plank", 5)
	sellers[1].inv.add("plank", 5)
	var j: JudgmentStore = w.judgment
	var live_first := 0
	var to_trusted := 0
	var to_liked := 0
	var n := mini(buyers.size(), 40)
	for i in n:
		var b: NPC = buyers[i]
		if w.brain._seller_of("plank", b) == sellers[0]:
			live_first += 1
	check(live_first == n, "neutral judgment: every buyer goes to the live rule's first seller (%d of %d)" % [live_first, n])
	var stubborn_stay := 0
	for i in n:
		var b: NPC = buyers[i]
		j.set_ledger(b.id, sellers[1].id, 1000, 0)
		stubborn_stay += 1 if j.pers.holds_stubbornness(b.id) and w.brain._seller_of("plank", b) == sellers[0] else 0
		j.set_ledger(b.id, sellers[1].id, 0, 0)
	print("note: %d stubborn buyers kept to the seller they chose last time (X19 stubbornness)" % stubborn_stay)
	j.last_choice.clear()                                 # fresh buyers: the tendency itself, without the habit just formed above
	for i in n:
		var b: NPC = buyers[i]
		j.trust_add(b.id, sellers[1].id, 8000)          # two fair deals' worth of trust in the second seller
		if w.brain._seller_of("plank", b) == sellers[1]:
			to_trusted += 1
		j.trust_add(b.id, sellers[1].id, -8000)
		j.last_choice.clear()
		j.set_ledger(b.id, sellers[1].id, 1000, 0)      # one point of good opinion (a gift, a fair deal or two)
		if w.brain._seller_of("plank", b) == sellers[1]:
			to_liked += 1
		j.set_ledger(b.id, sellers[1].id, 0, 0)
		j.last_choice.clear()
	check(to_trusted * 100 >= n * 60, "C1: two comparable sellers, the trusted one is chosen by most (%d of %d)" % [to_trusted, n])
	check(to_liked * 100 >= n * 60, "...and the better liked one (%d of %d)" % [to_liked, n])
	check(to_liked < n or to_trusted < n, "...a tendency, not a rule: the near-best is still sometimes taken (%d, %d of %d)" % [to_trusted, to_liked, n])
	# a woodcutter (a later tier of the live rule) is not preferred over the trade's own seller for a small liking
	w.dispose()


## Positive judgment counts as much as negative: a seller sells to the buyer who rescued them, among comparable buyers.
func test_c1_positive_judgment_live() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var buyers := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and w.brain.buy_role(o) == "merchant_raw":
			buyers.append(o)
	var others := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job not in ["guard", "smith", "merchant", "carpenter", "cook"]:
			others.append(o)
	while buyers.size() < 2 and not others.is_empty():
		var o: NPC = others.pop_back()
		o.job = "merchant"
		o.workplace = buyers[0].workplace if not buyers.is_empty() else o.workplace
		NPC.roles_version += 1
		if w.brain.buy_role(o) == "merchant_raw":
			buyers.append(o)
	if buyers.size() < 2:
		print("note: fewer than two raw-goods merchants; skipped")
		w.dispose()
		return
	for b: NPC in buyers:
		b.coins = 5000
		b.inv.remove("stone", b.inv.count("stone"))
	var j: JudgmentStore = w.judgment
	var picks := {}
	var n := 0
	for s: NPC in others.slice(0, 30):
		s.inv.add("stone", 3)
		var live: NPC = w.brain._buyer_for(s, "stone")
		if live == null:
			s.inv.remove("stone", 3)
			continue
		var other: NPC = buyers[1] if live == buyers[0] else buyers[0]
		j.set_ledger(s.id, other.id, 2000, 0)          # the other merchant once rescued them
		var pick: NPC = w.brain._buyer_for(s, "stone")
		picks[pick == other] = int(picks.get(pick == other, 0)) + 1
		j.set_ledger(s.id, other.id, 0, 0)
		s.inv.remove("stone", 3)
		n += 1
	check(n >= 10 and int(picks.get(true, 0)) * 100 >= n * 60, "C1: positive judgment: most sellers sell to the merchant who helped them (%d of %d)" % [int(picks.get(true, 0)), n])
	w.dispose()


## Yes-or-forgo choices: an assault victim (two points, permanent) still lends; someone assaulted twice by the buyer, with
## coin to spare, would rather not; the same person in need lends. Neutral: the live yes.
func test_c1_yes_or_forgo_live() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var j: JudgmentStore = w.judgment
	var refused_once := 0
	var refused_twice := 0
	var refused_needy := 0
	var n := 0
	var ps := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "guard":
			ps.append(o)
	var b: NPC = ps.pop_back()
	for s: NPC in ps.slice(0, 30):
		s.coins = 500
		check(JudgmentLive.lend_refusal(w, s, b) == "" if n == 0 else true, "neutral: the live yes")
		var a1 := j.publish("assault", [b.id], [s.id])
		j.observe(a1, s.id, "participant")
		refused_once += 1 if JudgmentLive.lend_refusal(w, s, b) != "" else 0
		var a2 := j.publish("assault", [b.id], [s.id])
		j.observe(a2, s.id, "participant")
		refused_twice += 1 if JudgmentLive.lend_refusal(w, s, b) != "" else 0
		s.coins = 0
		refused_needy += 1 if JudgmentLive.lend_refusal(w, s, b) != "" else 0
		n += 1
	print("C1 credit: assaulted once %d, twice %d, twice and needy %d refuse, of %d" % [refused_once, refused_twice, refused_needy, n])
	check(refused_once > 0 and refused_once < n, "C1: assaulted once by the buyer, with coin to spare: some would rather not lend, not all (influence, not dictate): %d of %d refuse" % [refused_once, n])
	check(refused_twice > refused_once and refused_twice * 100 >= n * 50, "...assaulted twice, more and most would rather not (%d of %d)" % [refused_twice, n])
	check(refused_needy == 0, "...and in need of coin, every one of them lends (%d refuse)" % refused_needy)
	w.dispose()


## The iron-bar seller (NPCBrain._bar_seller, newly weighed): the live rule's first while neutral; a trusted second smith is
## preferred by most once the buyer has dealt fairly with them.
func test_c1_bar_seller_live() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var j: JudgmentStore = w.judgment
	var ps := []
	for o: NPC in w.npcs:
		o.inv.remove("iron_bar", o.inv.count("iron_bar"))
		if o.alive and o.role == "adult" and o.job not in ["guard", "smith"] and w.brain.buy_role(o) != "merchant_goods":
			ps.append(o)
	var a: NPC = ps.pop_front()
	var b: NPC = ps.pop_front()
	a.job = "smith"
	b.job = "smith"
	NPC.roles_version += 1
	a.inv.add("iron_bar", 4)
	b.inv.add("iron_bar", 4)
	var first: NPC = w.brain._bar_seller(ps[0])
	var second: NPC = b if first == a else a
	var neutral := 0
	var trusted := 0
	for n: NPC in ps.slice(0, 30):
		neutral += 1 if w.brain._bar_seller(n) == first else 0
		j.trust_add(n.id, second.id, 8000)
		trusted += 1 if w.brain._bar_seller(n) == second else 0
		j.last_choice.clear()
	check(neutral == 30, "iron bars: neutral buyers go to the live rule's first smith (%d of 30)" % neutral)
	check(trusted * 100 >= 30 * 60, "...buyers who trust the other smith mostly go to him (%d of 30)" % trusted)
	w.dispose()


# ---------------------------------------------------------------- C5 ------------------------------
## The owner's example on a bare store: a man whose brother the blacksmith beat. Mixed feelings compete inside the weighing;
## people differ (trait spread) and circumstances decide.
func test_c5_mixed_feelings_bare() -> void:
	var c := shipped()
	var tally := {"sole_buy": 0, "alt_else": 0, "alt_smith": 0, "opt_forgo": 0, "opt_buy": 0, "kin_smith": 0, "helped_smith": 0, "same_else": 0}
	var n := 60
	for i in n:
		var me := 100 + i
		var s := JudgmentSocial.new().set_kin(BRO, me)
		var j := JudgmentStore.new(c, s, 7)
		var a := j.publish("assault", [SMITH], [BRO])
		j.observe_all(a, [me])                       # he saw the smith beat his brother
		if i == 0:
			check(j.net(me, SMITH) < 0 and JudgmentWeighting.fill(j, c, "tool_buy", me, SMITH, {}).fear > 0, "setup: dislike and fear of the smith (NET %d, fear %d)" % [j.net(me, SMITH), int(JudgmentWeighting.fill(j, c, "tool_buy", me, SMITH, {}).fear)])
		var smith := {"id": "smith", "counterparty": SMITH, "tier": 0, "factors": {"later": 0, "dearer": 0, "necessity": 100000, "respect": 80000}}
		var merch := {"id": "merch", "counterparty": MERCH, "tier": 1, "factors": {"later": 10000, "dearer": 20000, "necessity": 100000, "respect": 20000}}
		# sole source, desperate (an axe for a woodcutter out of work)
		var r1 := JudgmentWeighting.choose(j, c, me, "tool_buy", [smith], [1, 1])
		tally.sole_buy += 1 if str(r1.chosen) == "smith" else 0
		# an alternative at a fifth more
		var r2 := JudgmentWeighting.choose(j, c, me, "tool_buy", [smith, merch], [1, 2])
		tally.alt_else += 1 if str(r2.chosen) == "merch" else 0
		tally.alt_smith += 1 if str(r2.chosen) == "smith" else 0
		# an alternative of the same trade (a second smith) at a fifth more
		var smith2 := {"id": "smith2", "counterparty": MERCH, "tier": 0, "factors": {"later": 0, "dearer": 20000, "necessity": 100000, "respect": 80000}}
		var r2b := JudgmentWeighting.choose(j, c, me, "tool_buy", [smith, smith2], [1, 6])
		tally.same_else += 1 if str(r2b.chosen) == "smith2" else 0
		# an optional need (a shovel for a pit), sole source
		var opt := smith.duplicate(true)
		opt.factors.necessity = 30000
		var r3 := JudgmentWeighting.choose(j, c, me, "tool_buy", [opt], [1, 3])
		tally.opt_forgo += 1 if str(r3.chosen) == "forgo" else 0
		tally.opt_buy += 1 if str(r3.chosen) == "smith" else 0
		# loyalty: the same, but the smith is also his cousin
		s.set_kin(SMITH, me)
		var r4 := JudgmentWeighting.choose(j, c, me, "tool_buy", [smith, merch], [1, 4])
		tally.kin_smith += 1 if str(r4.chosen) == "smith" else 0
		# remembered help: the smith once rescued him (and is no kin)
		var s2 := JudgmentSocial.new().set_kin(BRO, me)
		var j2 := JudgmentStore.new(c, s2, 7)
		var a2 := j2.publish("assault", [SMITH], [BRO])
		j2.observe_all(a2, [me])
		var h := j2.publish("rescue", [SMITH], [], [me])
		j2.observe_all(h, [])
		var r5 := JudgmentWeighting.choose(j2, c, me, "tool_buy", [smith, merch], [1, 5])
		tally.helped_smith += 1 if str(r5.chosen) == "smith" else 0
	print("C5 tally over %d personalities: %s" % [n, str(tally)])
	check(tally.sole_buy == n, "C5: sole source, desperately needed: every one of them buys from the smith he dislikes and fears (%d of %d)" % [tally.sole_buy, n])
	check(tally.same_else * 100 >= n * 60, "...with a second smith at a fifth more, most pay more elsewhere (%d of %d)" % [tally.same_else, n])
	check(tally.alt_else * 100 >= n * 25 and tally.alt_smith > 0, "...with a seller of another trade (later in the live order) at a fifth more, many do, not all: personality and respect for his work decide (%d elsewhere, %d the smith)" % [tally.alt_else, tally.alt_smith])
	check(tally.opt_forgo > 0 and tally.opt_buy > 0, "an optional need, sole source: some put it off, some buy (%d forgo, %d buy)" % [tally.opt_forgo, tally.opt_buy])
	check(tally.kin_smith > tally.alt_smith, "loyalty: when the smith is also family, more of them deal with him (%d > %d)" % [tally.kin_smith, tally.alt_smith])
	check(tally.helped_smith > tally.alt_smith, "remembered help: a smith who once rescued him is dealt with more (%d > %d)" % [tally.helped_smith, tally.alt_smith])
	# no single collapsed score: the same NET read with fear and without leads to different choices
	var cnt := [0, 0]
	for i in n:
		var me := 300 + i
		for k in 2:
			var j := JudgmentStore.new(c, JudgmentSocial.new(), 7)
			if k == 0:
				j.set_ledger(me, SMITH, 0, 1100)           # dislike alone (fading)
			else:
				var a := j.publish("assault", [SMITH], [me])
				j.observe_all(a, [])                       # assaulted himself: dislike and fear
				j.set_ledger(me, SMITH, 0, 0)
				j._ledger_add(me, SMITH, 0, 1100, 0, true)   # the same 1.1 points, in the permanent (violence) part
			check(k == 0 or j.net(me, SMITH) == -1100, "setup: the same NET") if i == 0 else null
			var smith := {"id": "smith", "counterparty": SMITH, "tier": 0, "factors": {"later": 0, "dearer": 0, "necessity": 100000, "respect": 50000}}
			var merch := {"id": "merch", "counterparty": MERCH, "tier": 1, "factors": {"later": 10000, "dearer": 15000, "necessity": 100000, "respect": 50000}}
			var r := JudgmentWeighting.choose(j, c, me, "tool_buy", [smith, merch], [2, i])
			cnt[k] += 1 if str(r.chosen) == "merch" else 0
	check(int(cnt[1]) > int(cnt[0]), "not one collapsed score: the same NET with fear behind it sends more elsewhere (%d > %d)" % [cnt[1], cnt[0]])


## The live hook (NPCBrain._buy_tool): the woodcutter whose brother the smith beat. Two smiths sell axes; the one who beat
## him comes first in the live rule's order and is the cheaper (more stock).
func test_c5_blacksmith_live() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var j: JudgmentStore = w.judgment
	var people := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job not in ["guard", "carpenter"] and w.brain.buy_role(o) != "merchant_goods":
			people.append(o)
	for o: NPC in w.npcs:
		o.inv.remove("axe", o.inv.count("axe"))
		if w.brain.buy_role(o) == "merchant_goods" or o.job == "smith":
			o.job = "farmer" if o.job == "smith" else o.job
	NPC.roles_version += 1
	var smith: NPC = people.pop_front()
	var other: NPC = people.pop_front()
	smith.job = "smith"
	other.job = "smith"
	NPC.roles_version += 1
	var bro: NPC = people.pop_back()
	smith.inv.add("axe", 6)
	var a := j.publish("assault", [smith.id], [bro.id])
	var sole := 0
	var went_other := 0
	var stayed := 0
	var neutral_live := 0
	var n := 24
	for i in n:
		var me: NPC = people[i]
		me.job = "woodcutter"
		me.coins = 400
		other.inv.remove("axe", other.inv.count("axe"))
		if i == 0:
			check(w.brain._buy_tool(me, "axe") and int(me.plan[-1].args.vendor) == smith.id, "setup: neutral, the smith is the only seller")
		me.mother = 9000 + i
		bro.mother = 9000 + i                  # brothers
		Life.kin_version += 1
		j.observe(a, me.id, "witnessed")
		if w.brain._buy_tool(me, "axe") and str(me.plan[-1].get("act", "")) == "buy_from" and int(me.plan[-1].args.vendor) == smith.id:
			sole += 1
		other.inv.add("axe", 1)
		if w.brain._buy_tool(me, "axe") and str(me.plan[-1].get("act", "")) == "buy_from":
			if int(me.plan[-1].args.vendor) == other.id:
				went_other += 1
			elif int(me.plan[-1].args.vendor) == smith.id:
				stayed += 1
	print("C5 live: sole %d, other smith %d, stayed %d of %d" % [sole, went_other, stayed, n])
	check(sole == n, "C5 live: the only seller of the axe a woodcutter needs is the smith who beat his brother: he buys (%d of %d)" % [sole, n])
	check(went_other * 100 >= n * 50, "...with a second smith selling axes (dearer, later in the live order), most go there instead (%d of %d)" % [went_other, n])
	check(went_other + stayed == n, "...and nobody is left without one (%d + %d)" % [went_other, stayed])
	for i in range(n, mini(people.size(), n + 12)):
		var me: NPC = people[i]
		me.job = "woodcutter"
		me.coins = 400
		if w.brain._buy_tool(me, "axe") and int(me.plan[-1].args.vendor) == smith.id:
			neutral_live += 1
	check(neutral_live == mini(people.size(), n + 12) - n, "neutral buyers take the live rule's seller, the first smith (%d)" % neutral_live)
	w.dispose()
