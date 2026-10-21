extends SceneTree
## PROSPECTIVE (Expansion 19, PROS-19): the isolated judgment prototype (JudgmentStore, JudgmentWeighting) against the
## spec's fixtures (s.15) and the directive's example; no World, no live behaviour. Ids are made-up people: 1 Bob,
## 2 Bob's cousin, 3 John (a rival of Bob), 4 Verbal, 5 a stranger, 6 Bob's friend; -2 the player, judged by the same
## rules. Run headless:
##   godot --headless --path game --script res://tests/judgment_test.gd

var failures := 0
var checks := 0
const BOB := 1
const COUSIN := 2
const JOHN := 3
const VERBAL := 4
const STRANGER := 5
const FRIEND := 6
const THIEF := 7
const PLAYER := -2


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


## A fresh config (each test may change it without touching another's).
func cfg() -> Dictionary:
	return JudgmentStore.default_cfg().duplicate(true)


func store(config := {}) -> JudgmentStore:
	var s := JudgmentSocial.new().set_kin(BOB, COUSIN).set_friends(BOB, FRIEND)
	return JudgmentStore.new(config if not config.is_empty() else cfg(), s, 7)


func _init() -> void:
	test_math()
	test_spec_fixtures()
	test_rival_and_loyalty()
	test_idempotent_and_correction()
	test_confidence_policies()
	test_player_same_rules()
	test_catalog()
	test_memory_bounds_and_fading()
	test_horizon()
	test_gossip()
	test_misattribution()
	test_prior_bias()
	test_decision_iron()
	test_need_vs_opinion()
	test_feasibility()
	test_selection_policies()
	test_traits()
	test_save_and_migration()
	test_determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_math() -> void:
	check(JudgmentMath.mul_div(7, 1, 2) == 4 and JudgmentMath.mul_div(-7, 1, 2) == -4 and JudgmentMath.mul_div(5, 1, 3) == 2,
			"fixed point rounds half away from zero, the same for gains and losses")
	check(JudgmentMath.hash_ints([1, 2, 3]) == JudgmentMath.hash_ints([1, 2, 3]) and JudgmentMath.hash_ints([1, 2, 3]) != JudgmentMath.hash_ints([3, 2, 1]),
			"the seeded hash is repeatable and order-sensitive")
	check(JudgmentMath.hash_ints([-2, 99]) >= 0 and JudgmentMath.roll([-2, 99]) < 1000, "hashes of negative ids (the player) stay in range")
	check(JudgmentMath.pts(-6590) == "-6.590" and JudgmentMath.pts(43410) == "43.410", "points print as the spec writes them")


## Spec s.15: victim theft BAD +1; cousin BAD +0.55; rival reversal GOOD +0.65; disapproval of GOOD; indifference;
## NET example -6.59.
func test_spec_fixtures() -> void:
	var c := cfg()
	var j := store(c)
	j.ledger(JOHN, BOB, true)
	(j.ledgers[JOHN][BOB] as Array)[1] = 12000          # John already judges Bob at -12: a rival
	(j.ledgers[JOHN][BOB] as Array)[4] = 12000
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe_all(ev, [COUSIN, JOHN])
	check(j.bad(BOB, THIEF) == 1000 and j.good(BOB, THIEF) == 0, "the victim: BAD 1 x P +1.00 -> 1 BAD")
	check(j.bad(COUSIN, THIEF) == 550, "the cousin: P +0.55 -> 0.55 BAD")
	check(j.good(JOHN, THIEF) == 650 and j.bad(JOHN, THIEF) == 0, "Bob's rival John: P -0.65 -> 0.65 GOOD (the event stays BAD)")
	check(str(j.definition("theft").polarity) == "BAD" and int(j.facts[ev].revision) == 0, "the event's base polarity and severity do not change when an observer disagrees")
	check(j.net(STRANGER, THIEF) == 0 and j.ledger(STRANGER, THIEF)[2] == 0 and not j.ledgers.has(STRANGER),
			"someone who never learned of it has no belief and no ledger, not a zero-valued judgment")
	# disapproval of GOOD: GOOD 2 x P -0.5 -> BAD 1
	c.interpret.bystander = -500
	var j2 := store(c)
	var r := j2.publish("rescue", [VERBAL], [], [BOB])
	j2.observe(r, STRANGER)
	check(j2.bad(STRANGER, VERBAL) == 1000 and j2.good(STRANGER, VERBAL) == 0, "disapproval of a GOOD deed: GOOD 2 x P -0.5 -> 1 BAD")
	# indifference: P 0 posts nothing
	c.interpret.bystander = 0
	var j3 := store(c)
	var k := j3.publish("killing", [THIEF], [STRANGER + 100])
	j3.observe(k, STRANGER)
	check(j3.ledger(STRANGER, THIEF)[2] == 0 and j3.net(STRANGER, THIEF) == 0, "indifference (P 0): no contribution")
	check(not j3.belief(STRANGER, k).is_empty(), "...though they remember it")
	# NET example: GOOD 20, BAD 26.59
	var j4 := store()
	var l := j4.ledger(JOHN, VERBAL, true)
	l[0] = 20000
	l[1] = 26590
	check(j4.net(JOHN, VERBAL) == -6590 and JudgmentMath.pts(j4.net(JOHN, VERBAL)) == "-6.590", "GOOD 20, BAD 26.59: NET -6.59, fractional and exact")
	check(j4.disposition(JOHN, VERBAL) == 43410, "NET -6.59 maps to the spec's disposition 43.41")


func test_rival_and_loyalty() -> void:
	var c := cfg()
	var s := JudgmentSocial.new().set_kin(THIEF, COUSIN).set_friends(THIEF, FRIEND)
	var j := JudgmentStore.new(c, s, 7)
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe_all(ev, [COUSIN, FRIEND, STRANGER])
	check(j.bad(STRANGER, THIEF) == 300, "a bystander: P +0.30 -> 0.3 BAD")
	check(j.bad(COUSIN, THIEF) == 120, "the thief's own kin condemn it less (0.30 x kin_of_actor 0.40 -> 0.12 BAD)")
	check(j.bad(FRIEND, THIEF) == 210, "the thief's friend condemns it less (0.30 x 0.70 -> 0.21 BAD)")
	var t := j.publish("theft", [THIEF, JOHN], [BOB])
	j.observe(t, JOHN)
	check(j.good(JOHN, THIEF) == 150 and j.bad(JOHN, THIEF) == 0, "an accomplice approves of a partner's part (P -0.30 on a half share -> 0.15 GOOD)")
	check(j.ledger(JOHN, JOHN)[2] == 0, "nobody judges themselves")


func test_idempotent_and_correction() -> void:
	var j := store()
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe(ev, STRANGER)
	j.observe(ev, STRANGER)
	check(j.bad(STRANGER, THIEF) == 300 and j.ledger(STRANGER, THIEF)[2] == 1, "the same belief delivered twice: no duplicate contribution")
	check(not j.learn(STRANGER, ev, "told", COUSIN, 1, 560, j.facts[ev].actors), "a weaker telling of a known event changes nothing")
	# belief correction: it was John, not the thief
	j.revise_fact(ev, [JOHN])
	j.correct(STRANGER, ev)
	check(j.bad(STRANGER, THIEF) == 0 and j.ledger(STRANGER, THIEF)[2] == 0, "a correction takes the old actor's points back")
	check(j.bad(STRANGER, JOHN) == 300, "...and the new actor is judged instead")
	check(int(j.facts[ev].revision) == 1 and int(j.facts[ev].original_actors[0][0]) == THIEF, "the fact keeps its original with the revision (auditable)")
	j.correct(STRANGER, ev)
	check(j.bad(STRANGER, JOHN) == 300, "a correction applied twice is idempotent")
	# ledgers never go negative
	var l := j.ledger(STRANGER, JOHN)
	l[1] = 100
	j.correct(STRANGER, ev, [THIEF])
	check(j.bad(STRANGER, JOHN) == 0, "taking back more than a ledger holds leaves it at 0, never negative")


func test_confidence_policies() -> void:
	var c := cfg()
	var j := store(c)
	var ev := j.publish("theft", [THIEF], [BOB])
	j.learn(STRANGER, ev, "told", COUSIN, 1, 500, j.facts[ev].actors)
	check(j.bad(STRANGER, THIEF) == 150, "multiplier policy: S 1 x P 0.3 x C 0.5 -> 0.15 BAD")
	c.belief.confidence_policy = "threshold"
	var j2 := store(c)
	var e2 := j2.publish("theft", [THIEF], [BOB])
	j2.learn(STRANGER, e2, "told", COUSIN, 1, 500, j2.facts[e2].actors)
	j2.learn(FRIEND + 10, e2, "rumour", COUSIN, 2, 200, j2.facts[e2].actors)
	check(j2.bad(STRANGER, THIEF) == 300, "threshold policy: believed above the threshold counts in full")
	check(j2.bad(FRIEND + 10, THIEF) == 0 and not j2.belief(FRIEND + 10, e2).is_empty(), "...below it the rumour is remembered but posts nothing")


## The player is one more person: the same deed by the player or a villager is judged identically.
func test_player_same_rules() -> void:
	var j := store()
	var a := j.publish("theft", [PLAYER], [BOB])
	var b := j.publish("theft", [THIEF], [BOB])
	j.observe_all(a, [COUSIN, STRANGER])
	j.observe_all(b, [COUSIN, STRANGER])
	check(j.ledger(BOB, PLAYER) == j.ledger(BOB, THIEF) and j.ledger(COUSIN, PLAYER) == j.ledger(COUSIN, THIEF) and j.ledger(STRANGER, PLAYER) == j.ledger(STRANGER, THIEF),
			"a theft by the player and by a villager post the same points for every observer")


func test_catalog() -> void:
	var c := cfg()
	var j := store(c)
	check(j.publish("no_such_thing", [THIEF]) == -1, "an unknown event type is refused")
	check(j.publish("meeting", [THIEF], [BOB]) == -1, "NEUTRAL events are refused while neutral_events is off (SJD-Q01 open)")
	c.neutral_events = true
	var j2 := store(c)
	var m := j2.publish("meeting", [THIEF], [BOB])
	j2.observe(m, STRANGER)
	check(m > 0 and not j2.belief(STRANGER, m).is_empty() and j2.ledger(STRANGER, THIEF)[2] == 0, "with neutral_events on, a NEUTRAL fact is remembered and posts no points")
	c.events.theft.min_value = 5
	var j3 := store(c)
	check(j3.publish("theft", [THIEF], [BOB], [], 2) == -1 and j3.publish("theft", [THIEF], [BOB], [], 5) > 0, "a theft under min_value is not scored (SJD-Q12 parameter)")


func test_memory_bounds_and_fading() -> void:
	var c := cfg()
	c.memory.capacity = 3
	var j := store(c)
	var evs := []
	for i in 4:
		evs.append(j.publish("help_minor", [100 + i], [], [STRANGER]))
		j.observe(evs[-1], STRANGER)
	check((j.memories[STRANGER] as Dictionary).size() == 3 and j.belief(STRANGER, evs[0]).is_empty(), "memory is bounded: the least salient, then the oldest, goes")
	check(j.good(STRANGER, 100) == 500, "forgetting a memory keeps its points (retract_on_forget false: lifetime totals)")
	var k := j.publish("killing", [THIEF], [BOB])
	j.observe(k, STRANGER)
	check(not j.belief(STRANGER, k).is_empty() and (j.memories[STRANGER] as Dictionary).size() == 3, "a grave event displaces a fading one")
	j.advance_day(5)
	var s5 := int(j.belief(STRANGER, evs[3]).sal)
	check(s5 < 500 and s5 > 0, "salience fades day by day (500 -> %d after 5 days)" % s5)
	check(int(j.belief(STRANGER, k).sal) == int(JudgmentMath.scale(3000, 1000)), "a killing (permanent_severity) does not fade")
	j.advance_day(40)
	check(j.belief(STRANGER, evs[3]).is_empty() and not j.belief(STRANGER, k).is_empty(), "faint memories are forgotten; the killing is remembered")
	check(j.good(STRANGER, 103) == 500, "...and the ledger keeps every point")
	c.memory.retract_on_forget = true
	var j2 := store(c)
	var e := j2.publish("help_minor", [100], [], [STRANGER])
	j2.observe(e, STRANGER)
	j2.advance_day(60)
	check(j2.good(STRANGER, 100) == 0, "retract_on_forget (an owner option, SJD-Q02/Q11): forgetting takes the points back")
	c.memory.retract_on_forget = false
	c.memory.effective_fade_permille = 100
	var j3 := store(c)
	var e3 := j3.publish("theft", [THIEF], [BOB])
	j3.observe(e3, BOB)
	j3.advance_day(1)
	check(j3.bad(BOB, THIEF) == 1000 and j3.net(BOB, THIEF) == -900, "an effective view fades (option, off by default) while the lifetime BAD is kept")


func test_horizon() -> void:
	var c := cfg()
	var j := store(c)
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe(ev, BOB)
	j.advance_day(int(c.memory.horizon_days) + 1)
	check(not j.facts.has(ev) and not (j.contrib.get(BOB, {}) as Dictionary).has(ev), "past the horizon the fact and its dedup key retire")
	check(j.bad(BOB, THIEF) == 1000, "...the victim's judgment stays")
	check(not j.learn(COUSIN, ev, "told", BOB, 1, 700, [[THIEF, 1000]]) and j.meet(BOB, COUSIN) == 0, "...and nobody can tell it on any more (no event counts twice)")


func test_gossip() -> void:
	var j := store()
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe(ev, BOB)
	check(j.meet(BOB, STRANGER) == 1, "Bob tells a stranger he meets")
	var b := j.belief(STRANGER, ev)
	check(str(b.src) == "told" and int(b.by) == BOB and int(b.hops) == 1, "provenance: told by Bob, one hop")
	check(int(b.conf) == 560, "confidence: 1.0 x hop 0.7 x credibility 0.8 -> 0.56")
	check(j.bad(STRANGER, THIEF) == JudgmentMath.mul_div(1000 * 300, 560, 1000000), "the stranger judges by what he heard (0.3 x 0.56)")
	check(j.meet(BOB, STRANGER) == 0 and j.ledger(STRANGER, THIEF)[2] == 1, "told again: nothing more (no duplicate points)")
	j.meet(STRANGER, COUSIN)
	var r := j.belief(COUSIN, ev)
	check(str(r.src) == "rumour" and int(r.by) == STRANGER and int(r.hops) == 2, "told on second-hand it is a rumour")
	check(int(r.conf) < int(b.conf), "...believed less at each hop")
	j.meet(COUSIN, FRIEND + 20)
	var r3 := j.belief(FRIEND + 20, ev)
	check(int(r3.hops) == 3, "a third hop is still told (confidence %d)" % int(r3.conf))
	j.meet(FRIEND + 20, FRIEND + 21)
	check(j.belief(FRIEND + 21, ev).is_empty(), "a rumour stops at max_hops")
	var cm := cfg()
	cm.gossip.min_confidence = 400
	var jm := store(cm)
	var em := jm.publish("theft", [THIEF], [BOB])
	jm.observe(em, BOB)
	jm.meet(BOB, STRANGER)
	jm.meet(STRANGER, FRIEND + 22)
	check(not jm.belief(STRANGER, em).is_empty() and jm.belief(FRIEND + 22, em).is_empty(), "a rumour that would fall under min_confidence is not passed on")
	check(j.meet(THIEF, BOB) == 0 or j.belief(THIEF, ev).is_empty(), "nobody is told of their own deed")
	# the daily budget
	var c := cfg()
	c.gossip.daily_budget = 1
	var j2 := store(c)
	for i in 3:
		j2.observe(j2.publish("theft", [THIEF + i], [BOB]), BOB)
	j2.meet(BOB, STRANGER)
	check((j2.memories.get(STRANGER, {}) as Dictionary).size() == 1, "a teller tells at most daily_budget a day")
	j2.advance_day(1)
	j2.meet(BOB, STRANGER)
	check((j2.memories.get(STRANGER, {}) as Dictionary).size() == 2, "...and more the next day")
	# no telling to someone the teller dislikes
	var j3 := store()
	var e3 := j3.publish("theft", [THIEF], [BOB])
	j3.observe(e3, BOB)
	var l := j3.ledger(BOB, JOHN, true)
	l[1] = 30000
	check(j3.meet(BOB, JOHN) == 0, "Bob tells nothing to someone he judges below share_net_at")
	# credibility: a disliked teller is believed less
	var j4 := store()
	var e4 := j4.publish("theft", [THIEF], [BOB])
	j4.observe(e4, BOB)
	var l4 := j4.ledger(STRANGER, BOB, true)
	l4[1] = 10000
	j4.tell(BOB, STRANGER)
	check(int(j4.belief(STRANGER, e4).conf) == JudgmentMath.mul_div(1000 * 700, 600, 1000000), "credibility: a teller the listener dislikes (-10) is believed less (0.8 -> 0.6)")


func test_misattribution() -> void:
	var c := cfg()
	c.gossip.misattribute_permille = 1000
	var j := store(c)
	var l := j.ledger(BOB, JOHN, true)
	l[1] = 5000                                    # Bob dislikes John
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe(ev, BOB)
	j.tell(BOB, STRANGER)
	check(int(j.belief(STRANGER, ev).actors[0][0]) == JOHN and j.bad(STRANGER, JOHN) > 0 and j.bad(STRANGER, THIEF) == 0,
			"a distorted rumour names the teller's most disliked (misattribute_permille, seeded): the listener blames John")
	j.revise_fact(ev, [THIEF])
	j.correct(STRANGER, ev)
	check(j.bad(STRANGER, JOHN) == 0 and j.bad(STRANGER, THIEF) > 0, "learning the truth reverses the false blame")


func test_prior_bias() -> void:
	var j := store()
	var l := j.ledger(STRANGER, VERBAL, true)
	l[1] = 10000                                   # the stranger dislikes Verbal (-10)
	var ev := j.publish("trade_fair", [VERBAL], [], [JOHN])
	j.observe(ev, STRANGER)
	check(int(j.last_trace.get("prior_bias", 0)) == -100 and j.good(STRANGER, VERBAL) == JudgmentMath.scale(200, 200), "an ambiguous deed by someone disliked reads worse (P 0.3 - 0.1)")
	var l2 := j.ledger(STRANGER, VERBAL)
	l2[1] = 900000
	var e2 := j.publish("trade_fair", [VERBAL], [], [JOHN])
	j.observe(e2, STRANGER)
	check(int(j.last_trace.prior_bias) == -150, "the bias is capped (prior_bias_cap 0.15), so dislike cannot snowball")
	j.observe(j.publish("trade_fair", [VERBAL], [], [STRANGER]), STRANGER)
	check(not j.last_trace.has("prior_bias"), "no bias for the one directly affected")
	j.observe(j.publish("theft", [VERBAL], [JOHN]), STRANGER)
	check(not j.last_trace.has("prior_bias"), "no bias on unambiguous events")


## Spec s.7.3: John needs 50 iron; Verbal is the only supplier; John judges Verbal at -6.59: 81.841, he buys.
func test_decision_iron() -> void:
	var c := cfg()
	var j := store(c)
	var l := j.ledger(JOHN, VERBAL, true)
	l[0] = 20000
	l[1] = 26590
	var cands := [{"id": "verbal", "counterparty": VERBAL, "factors": {"necessity": 90000, "affordability": 70000, "urgency": 75000}}]
	var r := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", cands)
	check(int(r.utility) == 81841, "the iron problem: 27 + 25 + 10.5 + 15 + 4.341 = 81.841 (got %s)" % JudgmentMath.pts(int(r.utility)))
	check(str(r.chosen) == "verbal", "John buys from Verbal despite NET -6.59: need outweighs the opinion")
	check(j.net(JOHN, VERBAL) == -6590, "choosing to trade does not change the judgment (spec s.7.4)")
	print(JudgmentWeighting.explain(r))
	# a second supplier: John's opinion of Verbal is unchanged, the outcome changes
	cands.append({"id": "smith2", "counterparty": STRANGER, "factors": {"necessity": 90000, "affordability": 70000, "urgency": 75000}})
	var r2 := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", cands)
	check(str(r2.chosen) == "smith2" and j.net(JOHN, VERBAL) == -6590, "a second supplier on the same terms: John goes to the other, his opinion unchanged")
	# he can wait: dislike prevails
	var lazy := [{"id": "verbal", "counterparty": VERBAL, "factors": {"necessity": 20000, "affordability": 70000, "urgency": 10000}}]
	var r3 := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", lazy)
	check(str(r3.chosen) == "forgo", "when John can wait, he does without (utility under forgo)")


## The directive's rule both ways: need can outweigh opinion, and opinion can outweigh a weaker need or a small price
## difference; judgment shifts the choice by a bounded amount, never all of it.
func test_need_vs_opinion() -> void:
	var c := cfg()
	var j := store(c)
	j.ledger(JOHN, VERBAL, true)[1] = 40000        # strongly negative: -40
	j.ledger(JOHN, FRIEND, true)[0] = 30000        # a friend: +30
	var mk := func(id: String, who: int, need: int, afford: int, urg: int) -> Dictionary:
		return {"id": id, "counterparty": who, "factors": {"necessity": need, "affordability": afford, "urgency": urg}}
	# 1. strong need, only the disliked supplier: buy
	var r1 := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", [mk.call("verbal", VERBAL, 95000, 60000, 90000)])
	check(str(r1.chosen) == "verbal", "need outweighs a strongly negative opinion (-40) when nobody else sells")
	# 2. moderate need: the same dislike tips it to doing without, a neutral seller would be used
	var r2 := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", [mk.call("verbal", VERBAL, 40000, 60000, 10000)])
	var r2n := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", [mk.call("stranger", STRANGER, 40000, 60000, 10000)])
	check(str(r2.chosen) == "forgo" and str(r2n.chosen) == "stranger", "opinion outweighs a moderate need: from a stranger John buys, from Verbal he does without")
	# 3. two suppliers, the disliked one somewhat cheaper: the friend wins
	var r3 := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", [mk.call("verbal", VERBAL, 80000, 80000, 70000), mk.call("friend", FRIEND, 80000, 50000, 70000)])
	check(str(r3.chosen) == "friend", "opinion outweighs a small price difference: John pays his friend more")
	# 4. the disliked one far cheaper (the friend's price he can barely afford): Verbal wins
	var r4 := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", [mk.call("verbal", VERBAL, 80000, 100000, 70000), mk.call("friend", FRIEND, 80000, 0, 70000)])
	check(str(r4.chosen) == "verbal", "a large price difference outweighs the opinion: John buys from Verbal")
	# the bound: judgment's whole range moves utility by at most its weight (10 points)
	var lo := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", [{"id": "x", "counterparty": VERBAL, "factors": {"disposition": 0}}])
	var hi := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", [{"id": "x", "counterparty": VERBAL, "factors": {"disposition": 100000}}])
	var w := int(c.decision.profiles.trade_buy.weights.disposition)
	check(int(hi.trace[0].utility) - int(lo.trace[0].utility) == w * 100, "the most extreme judgment moves a choice by its weight only (%s points)" % JudgmentMath.pts(w * 100))


func test_feasibility() -> void:
	var c := cfg()
	var j := store(c)
	j.ledger(JOHN, FRIEND, true)[0] = 100000       # adores the friend
	var r := JudgmentWeighting.choose(j, c, JOHN, "trade_buy", [
		{"id": "friend", "counterparty": FRIEND, "feasible": false, "why": "no iron in stock", "factors": {"necessity": 100000}},
		{"id": "verbal", "counterparty": VERBAL, "factors": {"necessity": 100000, "affordability": 50000, "urgency": 100000}}])
	check(str(r.chosen) == "verbal", "a positive judgment never makes an infeasible choice happen")
	check(str(r.trace[0].why) == "no iron in stock", "the trace says why the friend was not an option")
	var none := JudgmentWeighting.choose(j, c, JOHN, "trade_sell", [{"id": "a", "counterparty": FRIEND, "feasible": false}])
	check(none.chosen == null, "nothing feasible and no forgo: no choice (the caller's fallback)")
	check(JudgmentWeighting.explain(r).contains("not feasible (no iron in stock)"), "the explanation lists feasibility failures")


func test_selection_policies() -> void:
	var c := cfg()
	var j := store(c)
	var cands := [{"id": "a", "counterparty": 10, "factors": {"live_order": 50000}}, {"id": "b", "counterparty": 11, "factors": {"live_order": 50000}}]
	check(str(JudgmentWeighting.choose(j, c, JOHN, "trade_sell", cands).chosen) == "a", "argmax: a tie keeps the live code's own order")
	c.decision.selection = "margin"
	var picks := {}
	for day in 20:
		var r := JudgmentWeighting.choose(j, c, JOHN, "trade_sell", cands, [day])
		picks[str(r.chosen)] = true
		if day < 2:
			check(str(JudgmentWeighting.choose(j, c, JOHN, "trade_sell", cands, [day]).chosen) == str(r.chosen), "margin pick day %d is reproducible" % day)
	check(picks.size() == 2, "margin (SJD-Q09 option): near-equal options are picked among by a seeded hash")
	cands[1].factors.live_order = 10000
	check(str(JudgmentWeighting.choose(j, c, JOHN, "trade_sell", cands, [3]).chosen) == "a", "...but never an option outside the margin")


func test_traits() -> void:
	var c := cfg()
	check(JudgmentWeighting.trait_weight(c, 7, JOHN, "disposition", 100) == 100, "trait spread 0: everyone weighs alike")
	c.decision.trait_spread_permille = 500
	var ws := {}
	for p in 20:
		var w := JudgmentWeighting.trait_weight(c, 7, p, "disposition", 100)
		if p < 2:
			check(w >= 50 and w <= 150, "person %d's disposition weight %d is within the spread" % [p, w])
		ws[w] = true
	check(ws.size() > 5 and JudgmentWeighting.trait_weight(c, 7, 3, "disposition", 100) == JudgmentWeighting.trait_weight(c, 7, 3, "disposition", 100),
			"with a spread, people differ in how much they weigh judgment, fixed by the seed (SJD-Q03/Q13 option)")


func test_save_and_migration() -> void:
	var c := cfg()
	c.neutral_events = true
	var j := store(c)
	var ev := j.publish("theft", [THIEF], [BOB], [], 4, ["hunger"])
	j.observe_all(ev, [COUSIN, STRANGER])
	j.meet(BOB, FRIEND)
	j.revise_fact(j.publish("assault", [JOHN], [VERBAL]), [THIEF])
	j.publish("meeting", [BOB], [JOHN])
	var d := j.to_dict()
	var text := JSON.stringify(d)
	var j2 := store(c)
	var err := j2.load_dict(JSON.parse_string(text))
	check(err == "", "a saved judgment section loads")
	check(JSON.stringify(j2.to_dict()) == text, "round trip through JSON text: identical")
	check(j2.bad(COUSIN, THIEF) == 550 and str(j2.belief(FRIEND, ev).src) == "told" and int(j2.facts[ev + 1].revision) == 1, "...ledgers, provenance and revisions intact")
	j2.meet(BOB, FRIEND)
	check(j2.ledger(FRIEND, THIEF)[2] == 1, "after loading, a retold rumour still adds nothing")
	var j3 := store(c)
	check(j3.load_dict({}) == "" and j3.facts.is_empty(), "a save from before judgment (every Build 16 save) loads an empty store")
	var v0 := {"format": "mml-judgment/0", "day": 3, "next_event": 9, "ledgers": {"3:4": {"good": 20.0, "bad": 26.59}}}
	check(j3.load_dict(v0) == "" and j3.net(JOHN, VERBAL) == -6590 and j3.next_event == 9, "migration: the draft v0 layout (float points) becomes exact milli-points")
	var future := {"format": "mml-judgment/1", "version": 99, "facts": []}
	var j4 := store(c)
	var why := j4.load_dict(future)
	check(why.contains("newer") and j4.to_dict() == future, "a newer section is refused with a reason and written back unchanged (never dropped)")
	check(store(c).load_dict({"format": "mml-judgment/1", "version": 1, "facts": []}).contains("damaged"), "a damaged section is refused, not half-read")


## The same seed and the same events give the same state, hash for hash (spec s.15 "Determinism").
func test_determinism() -> void:
	var h := []
	for run in 2:
		var c := cfg()
		c.gossip.misattribute_permille = 200
		var j := JudgmentStore.new(c, JudgmentSocial.new().set_kin(1, 2).set_friends(3, 4), 99)
		for d in 6:
			j.advance_day(d)
			for i in 12:
				var actor := (d * 7 + i * 3) % 15
				var victim := (actor + 1 + i) % 15
				var ev := j.publish(["theft", "help_minor", "assault", "gift"][i % 4], [actor], [victim] if i % 2 == 0 else [], [] if i % 2 == 0 else [victim])
				j.observe_all(ev, [(victim + 2) % 15, (victim + 5) % 15])
			for a in 15:
				j.meet(a, (a + d + 1) % 15)
		h.append(j.state_hash())
	check(h[0] == h[1], "two runs of the same scenario end in the same state hash")
