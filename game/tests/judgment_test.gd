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


## A fresh config (each test may change it without touching another's). The fixtures check the interpretation math
## exactly, so personal morality (Q08) and the proposed decay (Q02) are off here; each has its own tests below.
func cfg() -> Dictionary:
	var c := JudgmentStore.default_cfg().duplicate(true)
	c.interpret.morality_spread_permille = 0
	c.decay.ordinary_permille_per_day = 0
	return c


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
	test_sliced_day()
	test_spread_gossip()
	test_scheduled_gossip()
	test_q01_facts_and_zero()
	test_q02_decay_and_murder()
	test_q06_trust()
	test_q07_no_hop_limit()
	test_q08_morality()
	test_q11_permanent_memories()
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
	j.set_ledger(JOHN, BOB, 0, 12000)          # John already judges Bob at -12: a rival
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe_all(ev, [COUSIN, JOHN])
	check(j.bad(BOB, THIEF) == 1000 and j.good(BOB, THIEF) == 0, "the victim: BAD 1 x P +1.00 -> 1 BAD")
	check(j.bad(COUSIN, THIEF) == 550, "the cousin: P +0.55 -> 0.55 BAD")
	check(j.good(JOHN, THIEF) == 650 and j.bad(JOHN, THIEF) == 0, "Bob's rival John: P -0.65 -> 0.65 GOOD (the event stays BAD)")
	check(str(j.definition("theft").polarity) == "BAD" and int(j.fact(ev).revision) == 0, "the event's base polarity and severity do not change when an observer disagrees")
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
	j4.set_ledger(JOHN, VERBAL, 20000, 26590)
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
	check(not j.learn(STRANGER, ev, "told", COUSIN, 1, 560, j.fact(ev).actors), "a weaker telling of a known event changes nothing")
	# belief correction: it was John, not the thief
	j.revise_fact(ev, [JOHN])
	j.correct(STRANGER, ev)
	check(j.bad(STRANGER, THIEF) == 0 and j.ledger(STRANGER, THIEF)[2] == 0, "a correction takes the old actor's points back")
	check(j.bad(STRANGER, JOHN) == 300, "...and the new actor is judged instead")
	check(int(j.fact(ev).revision) == 1 and int(j.fact(ev).original_actors[0][0]) == THIEF, "the fact keeps its original with the revision (auditable)")
	j.correct(STRANGER, ev)
	check(j.bad(STRANGER, JOHN) == 300, "a correction applied twice is idempotent")
	# ledgers never go negative
	j.set_ledger(STRANGER, JOHN, 0, 100)
	j.correct(STRANGER, ev, [THIEF])
	check(j.bad(STRANGER, JOHN) == 0, "taking back more than a ledger holds leaves it at 0, never negative")


func test_confidence_policies() -> void:
	var c := cfg()
	var j := store(c)
	var ev := j.publish("theft", [THIEF], [BOB])
	j.learn(STRANGER, ev, "told", COUSIN, 1, 500, j.fact(ev).actors)
	check(j.bad(STRANGER, THIEF) == 150, "multiplier policy: S 1 x P 0.3 x C 0.5 -> 0.15 BAD")
	c.belief.confidence_policy = "threshold"
	var j2 := store(c)
	var e2 := j2.publish("theft", [THIEF], [BOB])
	j2.learn(STRANGER, e2, "told", COUSIN, 1, 500, j2.fact(e2).actors)
	j2.learn(FRIEND + 10, e2, "rumour", COUSIN, 2, 200, j2.fact(e2).actors)
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
	var j2 := store(c)
	var m := j2.publish("meeting", [THIEF], [BOB])
	j2.observe(m, STRANGER)
	check(m > 0 and not j2.belief(STRANGER, m).is_empty() and j2.ledger(STRANGER, THIEF)[2] == 0, "a NEUTRAL fact is recorded and remembered and posts no points (Q01)")
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
	check(j.memory_count(STRANGER) == 3 and j.belief(STRANGER, evs[0]).is_empty(), "memory is bounded: the least salient, then the oldest, goes")
	check(j.good(STRANGER, 100) == 500, "forgetting a memory keeps its points (retract_on_forget false: lifetime totals)")
	var k := j.publish("killing", [THIEF], [BOB])
	j.observe(k, STRANGER)
	check(not j.belief(STRANGER, k).is_empty() and j.ordinary_count(STRANGER) == 3 and j.memory_count(STRANGER) == 4,
			"a murder is remembered permanently, beside the ordinary memories and not counted in their capacity (Q11)")
	j.advance_day(5)
	var s5 := int(j.belief(STRANGER, evs[3]).sal)
	check(s5 < 500 and s5 > 0, "salience fades day by day (500 -> %d after 5 days)" % s5)
	check(int(j.belief(STRANGER, k).sal) == int(JudgmentMath.scale(3000, 1000)) and bool(j.belief(STRANGER, k).permanent), "a murder memory does not fade")
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
	c.decay.ordinary_permille_per_day = 100
	var j3 := store(c)
	var e3 := j3.publish("theft", [THIEF], [BOB])
	j3.observe(e3, BOB)
	j3.advance_day(1)
	check(j3.bad(BOB, THIEF) == 1000 and j3.net(BOB, THIEF) == -900, "the judgment decays (Q02) while the lifetime BAD is kept as history")


func test_horizon() -> void:
	var c := cfg()
	var j := store(c)
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe(ev, BOB)
	j.advance_day(int(c.memory.horizon_days) + 1)
	check(not j.has_fact(ev) and not (j.contrib.get(BOB, {}) as Dictionary).has(ev), "past the horizon the fact and its dedup key retire")
	check(j.bad(BOB, THIEF) == 1000, "...the victim's judgment stays")
	check(not j.learn(COUSIN, ev, "told", BOB, 1, 700, [[THIEF, 1000]]) and j.meet(BOB, COUSIN) == 0, "...and nobody can tell it on any more (no event counts twice)")


func test_gossip() -> void:
	var j := store()
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe(ev, BOB)
	check(j.meet(BOB, STRANGER) == 1, "Bob tells a stranger he meets")
	var b := j.belief(STRANGER, ev)
	check(str(b.src) == "told" and int(b.by) == BOB and int(b.hops) == 1, "provenance: told by Bob, one hop")
	check(int(b.conf) == 450, "confidence: 1.0 x hop 0.9 x credibility of a stranger 0.5 -> 0.45 (got %d)" % int(b.conf))
	check(j.bad(STRANGER, THIEF) == JudgmentMath.mul_div(1000 * 300, 450, 1000000), "the stranger judges by what he heard (0.3 x 0.45)")
	check(j.meet(BOB, STRANGER) == 0 and j.ledger(STRANGER, THIEF)[2] == 1, "told again: nothing more (no duplicate points)")
	j.meet(STRANGER, COUSIN)
	var r := j.belief(COUSIN, ev)
	check(str(r.src) == "rumour" and int(r.by) == STRANGER and int(r.hops) == 2, "told on second-hand it is a rumour")
	check(int(r.conf) < int(b.conf), "...believed less at each hop between strangers")
	check(j.meet(THIEF, BOB) == 0 or j.belief(THIEF, ev).is_empty(), "nobody is told of their own deed")
	# the daily budget
	var c := cfg()
	c.gossip.daily_budget = 1
	var j2 := store(c)
	for i in 3:
		j2.observe(j2.publish("theft", [THIEF + i], [BOB]), BOB)
	j2.meet(BOB, STRANGER)
	check(j2.memory_count(STRANGER) == 1, "a teller tells at most daily_budget a day (an exchange limit, Q07)")
	j2.advance_day(1)
	j2.meet(BOB, STRANGER)
	check(j2.memory_count(STRANGER) == 2, "...and more the next day")
	# no telling to someone the teller dislikes
	var j3 := store()
	var e3 := j3.publish("theft", [THIEF], [BOB])
	j3.observe(e3, BOB)
	j3.set_ledger(BOB, JOHN, 0, 30000)
	check(j3.meet(BOB, JOHN) == 0, "Bob tells nothing to someone he judges below share_net_at")
	# credibility: a disliked teller is believed less
	var j4 := store()
	var e4 := j4.publish("theft", [THIEF], [BOB])
	j4.observe(e4, BOB)
	j4.set_ledger(STRANGER, BOB, 0, 10000)
	j4.tell(BOB, STRANGER)
	check(int(j4.belief(STRANGER, e4).conf) == JudgmentMath.mul_div(1000 * 900, 400, 1000000), "credibility: a stranger the listener dislikes (-10) is believed less (0.5 -> 0.4)")


func test_misattribution() -> void:
	var c := cfg()
	c.gossip.misattribute_permille = 1000
	var j := store(c)
	j.set_ledger(BOB, JOHN, 0, 5000)                    # Bob dislikes John
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
	j.trace = true                                      # developer diagnostics: keep each interpretation's parts
	j.set_ledger(STRANGER, VERBAL, 0, 10000)                   # the stranger dislikes Verbal (-10)
	var ev := j.publish("trade_fair", [VERBAL], [], [JOHN])
	j.observe(ev, STRANGER)
	check(int(j.last_trace.get("prior_bias", 0)) == -100 and j.good(STRANGER, VERBAL) == JudgmentMath.scale(200, 200), "an ambiguous deed by someone disliked reads worse (P 0.3 - 0.1)")
	j.set_ledger(STRANGER, VERBAL, j.good(STRANGER, VERBAL), 900000)
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
	j.set_ledger(JOHN, VERBAL, 20000, 26590)
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
	j.set_ledger(JOHN, VERBAL, 0, 40000)        # strongly negative: -40
	j.set_ledger(JOHN, FRIEND, 30000, 0)        # a friend: +30
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
	j.set_ledger(JOHN, FRIEND, 100000, 0)       # adores the friend
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
	check(j2.bad(COUSIN, THIEF) == 550 and str(j2.belief(FRIEND, ev).src) == "told" and int(j2.fact(ev + 1).revision) == 1, "...ledgers, provenance and revisions intact")
	j2.meet(BOB, FRIEND)
	check(j2.ledger(FRIEND, THIEF)[2] == 1, "after loading, a retold rumour still adds nothing")
	var j3 := store(c)
	check(j3.load_dict({}) == "" and j3.counts().facts == 0, "a save from before judgment (every Build 16 save) loads an empty store")
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


## Round 2: the daily update spread over the day's hours (begin_day, dawn_slice, catch-up on touch) gives exactly the
## state and the choices the whole update at dawn gives, with events, gossip and decisions in between; with the
## default settings and with the options that make the update do more (forgetting takes points back, an effective
## view that fades, distorted rumours).
func test_sliced_day() -> void:
	var variants := [{}, {"retract": true, "fade": 100, "mis": 300}]
	for v in variants:
		var out := []
		for mode in ["whole", "sliced"]:
			var c := cfg()
			c.memory.capacity = 6
			c.memory.horizon_days = 4
			if v.has("retract"):
				c.memory.retract_on_forget = true
				c.decay.ordinary_permille_per_day = int(v.fade)
				c.gossip.misattribute_permille = int(v.mis)
			var j := JudgmentStore.new(c, JudgmentSocial.new().set_kin(1, 2).set_friends(3, 4).set_kin(5, 6), 5)
			var log := []
			for d in 12:
				for hr in 24:
					if hr == 6:
						if mode == "whole":
							j.advance_day(d)
						else:
							j.begin_day(d)
					if mode == "sliced":
						j.dawn_slice(1)                  # a person an hour: most are caught up on touch, the rest late in the day
					var i := d * 24 + hr
					if i % 3 == 0:
						var actor := JudgmentMath.hash_ints([i, 1]) % (20 + d * 3)      # newcomers join day by day, mid-day
						var other := (actor + 1 + JudgmentMath.hash_ints([i, 2]) % 7) % (20 + d * 3)
						var type: String = ["theft", "help_minor", "assault", "gift", "trade_fair"][i % 5]
						var bad := str(j.definition(type).polarity) == "BAD"
						var ev := j.publish(type, [actor], [other] if bad else [], [] if bad else [other])
						j.observe_all(ev, [(other + 2) % (20 + d * 3), (other + 3) % (20 + d * 3)])
					if hr >= 7 and hr < 21:
						var a := JudgmentMath.hash_ints([i, 3]) % 20
						log.append(j.meet(a, (a + 1 + JudgmentMath.hash_ints([i, 4]) % 5) % 20))
					if hr == 12:
						var r := JudgmentWeighting.choose(j, c, i % 20, "trade_buy", [
							{"id": 1, "counterparty": (i + 1) % 20, "factors": {"necessity": 40000, "affordability": 60000, "urgency": 10000}},
							{"id": 2, "counterparty": (i + 2) % 20, "factors": {"necessity": 40000, "affordability": 60000, "urgency": 10000}}])
						log.append(str(r.chosen))
						log.append(j.net(i % 20, (i + 1) % 20))
			out.append([j.state_hash(), log, j.counts()])
		var name := "with retraction, fading view and rumours" if v.has("retract") else "default settings"
		check(out[0][1] == out[1][1], "sliced day (%s): every telling, choice and opinion along the way is the same" % name)
		check(out[0][0] == out[1][0], "sliced day (%s): the same end state, hash for hash (%s)" % [name, JSON.stringify(out[0][2])])
	var j := store()
	j.observe(j.publish("theft", [THIEF], [BOB]), BOB)
	j.begin_day(1)
	var queued := j.pending(BOB)
	check(queued and j.memory_count(BOB) == 1 and not j.pending(BOB), "a queued person is brought up to date the moment they are read")
	j.begin_day(2)
	var left := j.dawn_hour()
	check(left == 0, "dawn_hour works through the queue (%d left)" % left)


## Round 3: an hour's meetings queued (meet_later) and told a few a tick (gossip_pump), with events, decisions and
## reads of people's beliefs and opinions between the ticks, give exactly the tellings, beliefs, opinions and end state
## that telling every meeting the moment it happens (meet) gives; with the default settings and with retraction, a
## fading view and distorted rumours on; also with the daily update sliced.
func test_spread_gossip() -> void:
	var variants := [{}, {"retract": true, "fade": 100, "mis": 300}]
	for v in variants:
		var out := []
		for mode in ["now", "spread"]:
			var c := cfg()
			c.memory.capacity = 6
			c.memory.horizon_days = 4
			if v.has("retract"):
				c.memory.retract_on_forget = true
				c.decay.ordinary_permille_per_day = int(v.fade)
				c.gossip.misattribute_permille = int(v.mis)
			var j := JudgmentStore.new(c, JudgmentSocial.new().set_kin(1, 2).set_friends(3, 4).set_kin(5, 6), 5)
			var log := []
			var queued_max := 0
			for d in 10:
				var people := 24 + d * 2
				for hr in 24:
					if hr == 6:
						j.begin_day(d)
					j.dawn_hour()
					var i := d * 24 + hr
					for e in 2:
						var actor := JudgmentMath.hash_ints([i, e, 1]) % people
						var other := (actor + 1 + JudgmentMath.hash_ints([i, e, 2]) % 7) % people
						var type: String = ["theft", "help_minor", "assault", "gift", "trade_fair"][(i + e) % 5]
						var bad := str(j.definition(type).polarity) == "BAD"
						var ev := j.publish(type, [actor], [other] if bad else [], [] if bad else [other])
						j.observe_all(ev, [(other + 2) % people, (other + 3) % people])
					if hr >= 7 and hr < 21:
						for m in 12:                                   # the hour's meetings, all at once (Relations.hour)
							var a := JudgmentMath.hash_ints([i, m, 3]) % people
							var b := (a + 1 + JudgmentMath.hash_ints([i, m, 4]) % 5) % people
							if mode == "now":
								j.meet(a, b)
							else:
								j.meet_later(a, b)
					queued_max = maxi(queued_max, j.gossip_queued())
					for tick in 6:                                     # the hour's ticks
						if mode == "spread":
							j.gossip_pump(2)
						var who := JudgmentMath.hash_ints([i, tick, 5]) % people
						if tick == 2:
							var r := JudgmentWeighting.choose(j, c, who, "trade_buy", [
								{"id": 1, "counterparty": (who + 1) % people, "factors": {"necessity": 40000, "affordability": 60000, "urgency": 10000}},
								{"id": 2, "counterparty": (who + 2) % people, "factors": {"necessity": 40000, "affordability": 60000, "urgency": 10000}}])
							log.append(str(r.chosen))
						if tick == 4:
							var ev2 := j.publish("assault", [who], [(who + 3) % people])
							j.observe_all(ev2, [(who + 4) % people])
						log.append(j.net(who, (who + 1) % people))
						log.append(j.memory_count(who))
			var beliefs := []
			for o in 44:
				for ev in range(1, j.next_event):
					var b := j.belief(o, ev)
					if not b.is_empty():
						beliefs.append([o, ev, b.src, b.by, b.hops, b.conf])
			out.append([j.state_hash(), log, beliefs, int(j.stats.get("tellings", 0)), queued_max, int(j.stats.get("gossip_flushes", 0)), int(j.stats.get("read_without_flush", 0))])
		var name := "with retraction, fading view and rumours" if v.has("retract") else "default settings"
		check(out[1][4] > 0 and out[1][5] > 0, "spread gossip (%s): meetings really waited in the queue (up to %d) and reads flushed what they needed (%d times)" % [name, out[1][4], out[1][5]])
		if v.has("mis"):
			check(out[1][6] == 0, "spread gossip (%s): with misattribution possible, every read tells the queue first (%d skipped)" % [name, out[1][6]])
		else:
			check(out[1][6] > 0, "spread gossip (%s): reads that could not change were answered without telling the queue first (%d times)" % [name, out[1][6]])
		check(out[0][3] == out[1][3], "spread gossip (%s): the same number of tellings (%d)" % [name, out[0][3]])
		check(out[0][1] == out[1][1], "spread gossip (%s): every opinion, memory count and choice read between ticks is the same" % name)
		check(out[0][2] == out[1][2], "spread gossip (%s): the same beliefs, provenance and confidence (%d beliefs)" % [name, out[0][2].size()])
		check(out[0][0] == out[1][0], "spread gossip (%s): the same end state, hash for hash" % name)
	var j := store()
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe(ev, BOB)
	j.meet_later(BOB, STRANGER)
	j.meet_later(STRANGER, COUSIN)
	check(j.gossip_queued() == 2 and j.belief(COUSIN, ev).src == "rumour" and j.gossip_queued() == 0,
			"reading the cousin's belief tells first the two meetings word passed through to reach her")
	j.meet_later(BOB, FRIEND)
	j.meet_later(JOHN, VERBAL)
	j.belief(FRIEND, ev)
	check(j.gossip_queued() == 1, "...and only those: a meeting of other people stays queued")
	check(j.gossip_pump() == 0, "the pump tells what is left")
	# a read between two queued meetings, with no pump between: the second meeting must not be missed
	var jq := store()
	var jn := store()
	for x in [jq, jn]:
		x.observe(x.publish("theft", [THIEF], [BOB]), BOB)
	jq.meet_later(STRANGER, JOHN)
	jn.meet(STRANGER, JOHN)
	check(jq.net(STRANGER, THIEF) == jn.net(STRANGER, THIEF) and jq.net(STRANGER, THIEF) == 0, "a read that nothing queued can change is answered at once")
	jq.meet_later(STRANGER, BOB)
	jn.meet(STRANGER, BOB)
	check(jq.net(STRANGER, THIEF) == jn.net(STRANGER, THIEF) and jq.net(STRANGER, THIEF) < 0, "a meeting queued after that read is not missed: Bob's story reaches the stranger before the next read (%d)" % jq.net(STRANGER, THIEF))


## Round 3 option, gossip.timing "scheduled" (off by default; a design choice, since it changes when word passes): each
## meeting is told at its own seeded minute of the hour; nothing is told before its minute; a save keeps the meetings
## still to come; the same seed gives the same minutes and the same result.
func test_scheduled_gossip() -> void:
	var c := cfg()
	c.gossip.timing = "scheduled"
	var hashes := []
	for run in 2:
		var j := store(c)
		var ev := j.publish("theft", [THIEF], [BOB])
		j.observe(ev, BOB)
		j.meet_hourly(BOB, STRANGER, 600)
		j.meet_hourly(BOB, COUSIN, 600)
		var minutes := []
		for mm in j._sched:
			minutes.append(int(mm))
		minutes.sort()
		check(minutes.size() >= 1 and minutes[0] >= 600 and minutes[-1] < 660, "scheduled: meetings fall within their hour (minutes %s)" % str(minutes))
		j.gossip_tick(minutes[0] - 1)
		check(j.belief(STRANGER, ev).is_empty() and j.belief(COUSIN, ev).is_empty(), "scheduled: nothing is told before its minute, even when read")
		var d := j.to_dict()
		check(d.has("scheduled") and (d.scheduled as Array).size() == 2, "scheduled: a save keeps the meetings still to come")
		var j2 := store(c)
		j2.load_dict(JSON.parse_string(JSON.stringify(d)))
		j.gossip_tick(659)
		j2.gossip_tick(659)
		check(str(j.belief(STRANGER, ev).src) == "told" and str(j.belief(COUSIN, ev).src) == "told", "scheduled: told when the minute comes")
		check(j.state_hash() == j2.state_hash(), "scheduled: saved and reloaded before the minute, the same result after it")
		hashes.append(j.state_hash())
	check(hashes[0] == hashes[1], "scheduled: the same seed gives the same minutes and the same result")


# ---------------------------------------------------------------- owner decisions, 2026-10-21 --------
## Q01: an event is a fact; each observer's interpretation may be positive, negative or zero; zero needs no third
## ledger; the fact is still remembered and told. A "personal" rule on a NEUTRAL type (none is configured by default)
## gives the owner's marriage example: positive to a close friend, negative to someone it hurt, nothing to others.
func test_q01_facts_and_zero() -> void:
	var c := cfg()
	var j := store(c)
	var wed := j.publish("marriage", [BOB, FRIEND + 30], [], [BOB, FRIEND + 30])
	j.observe_all(wed, [STRANGER, FRIEND, COUSIN])
	check(j.ledger(STRANGER, BOB)[2] == 0 and j.ledger(FRIEND, BOB)[2] == 0 and j.ledger(COUSIN, BOB)[2] == 0 and not j.belief(STRANGER, wed).is_empty(),
			"by default a marriage is remembered by everyone who saw it and means nothing morally to anyone (Q01)")
	check(j.meet(STRANGER, JOHN) == 1 and str(j.belief(JOHN, wed).type) == "marriage", "...and the fact is still told on")
	check(j.ledger(STRANGER, BOB).size() == 7, "no third ledger: a ledger is GOOD and BAD (lifetime, fading, permanent parts) and its count")
	c.events.marriage.personal = {"severity": 1000, "beneficiary": 0, "victim": -800, "kin": 500, "friend": 600}
	var j2 := store(c)
	var w2 := j2.publish("marriage", [BOB, FRIEND + 30], [JOHN], [BOB, FRIEND + 30])   # John hoped to marry Bob
	j2.observe_all(w2, [STRANGER, FRIEND, COUSIN])
	check(j2.good(FRIEND, BOB) == 300 and j2.bad(FRIEND, BOB) == 0, "with a personal rule: Bob's close friend is glad of it (GOOD, 0.6 split between the two)")
	check(j2.bad(JOHN, BOB) == 400 and j2.good(JOHN, BOB) == 0, "...the one it hurt sees it as BAD")
	check(j2.ledger(STRANGER, BOB)[2] == 0, "...and to an unrelated villager it is zero: nothing posted")


## Q02: ordinary judgments fade very slowly; murder never; both kinds coexist in one ledger; the lifetime totals stay as
## history; a save keeps the parts apart.
func test_q02_decay_and_murder() -> void:
	var c := cfg()
	c.decay.ordinary_permille_per_day = 3
	var j := store(c)
	var th := j.publish("theft", [THIEF], [BOB])
	j.observe(th, BOB)
	var k := j.publish("killing", [THIEF], [COUSIN])
	j.observe(k, BOB)
	var before := j.ledger(BOB, THIEF)
	check(int(before[4]) == 1000 and int(before[6]) == 1650 and j.net(BOB, THIEF) == -2650,
			"one ledger holds both: the theft in the fading part (1 BAD), the murder of his cousin in the permanent part (3 x 0.55 = 1.65 BAD)")
	for d in range(1, 101):
		j.advance_day(d)
	var after := j.ledger(BOB, THIEF)
	check(int(after[6]) == 1650, "after 100 days the murder's part is untouched (it never decays)")
	check(int(after[4]) < 1000 and int(after[4]) > 700, "the theft's part has faded slowly (1000 -> %d after 100 days at 3 permille a day)" % int(after[4]))
	check(int(after[1]) == 2650, "the lifetime BAD total is kept as history")
	var j2 := store(c)
	check(j2.load_dict(JSON.parse_string(JSON.stringify(j.to_dict()))) == "" and j2.ledger(BOB, THIEF) == after, "a save keeps the fading and permanent parts apart")
	for d in range(101, 1101):
		j.advance_day(d)
	check(int(j.ledger(BOB, THIEF)[6]) == 1650 and int(j.ledger(BOB, THIEF)[4]) < 100, "after 1100 days the theft has all but faded; the murder has not")
	var c0 := cfg()
	var j3 := store(c0)
	j3.observe(j3.publish("theft", [THIEF], [BOB]), BOB)
	j3.advance_day(50)
	check(j3.net(BOB, THIEF) == -1000, "with the rate at 0, nothing fades (the rate is a setting, proposed, not approved)")


## Q06: confidence in a told story comes from the listener's trust in the immediate teller, using the existing
## relationship number; witnesses need no storyteller; the chain's confidence reflects every link; a more trusted
## retelling updates the existing belief and its contribution, never a second one.
func test_q06_trust() -> void:
	var social := JudgmentSocial.new().set_regard(STRANGER, BOB, 90).set_regard(COUSIN, STRANGER, 0)
	var j := JudgmentStore.new(cfg(), social, 7)
	var ev := j.publish("theft", [THIEF], [BOB])
	j.observe(ev, BOB)
	j.observe(ev, JOHN)
	check(int(j.belief(JOHN, ev).conf) == 1000 and str(j.belief(JOHN, ev).src) == "witnessed", "a witness is firsthand: no storyteller to weigh")
	check(j.credibility(STRANGER, BOB) == 950 and j.credibility(COUSIN, STRANGER) == 500, "credibility from the relationship number: regard 90 -> 0.95, a stranger 0.5")
	j.tell(BOB, STRANGER)
	check(int(j.belief(STRANGER, ev).conf) == JudgmentMath.mul_div(1000 * 900, 950, 1000000), "told by a trusted friend: 0.9 x 0.95")
	j.tell(STRANGER, COUSIN)
	var chain := JudgmentMath.mul_div(JudgmentMath.mul_div(1000 * 900, 950, 1000000) * 900, 500, 1000000)
	check(int(j.belief(COUSIN, ev).conf) == chain, "over two links the confidence is the product along the chain (%d)" % chain)
	var once := j.bad(COUSIN, THIEF)
	j.tell(STRANGER, COUSIN)
	check(j.bad(COUSIN, THIEF) == once and j.ledger(COUSIN, THIEF)[2] == 1, "hearing the same story again never re-scores it")
	j.tell(JOHN, COUSIN)
	var up := j.belief(COUSIN, ev)
	check(int(up.conf) == 450 and int(up.by) == JOHN and j.ledger(COUSIN, THIEF)[2] == 1 and j.bad(COUSIN, THIEF) > once,
			"a more credible telling (from a witness) updates the existing belief and its contribution, not a second one")
	check(int(j.stats.get("upgraded", 0)) == 1, "...counted as an update")


## Q07: no fixed limit on retellings: a story travels as far as real meetings carry it, one meeting at a time; each
## person judges it once; processing ends. A murder (never forgotten, Q11) travels the whole line; an ordinary story
## goes on until it is too faint to remember (salience = severity x confidence, Q11's ordinary forgetting), not to a
## fixed count.
func test_q07_no_hop_limit() -> void:
	var social := JudgmentSocial.new()
	for i in 40:
		social.set_regard(i, (i + 1) % 40, 80)
	for type in ["killing", "assault"]:
		var j := JudgmentStore.new(cfg(), social, 7)
		var ev := j.publish(type, [99], [0])
		j.observe(ev, 0)
		var day_reached := {}
		var far := 0
		for d in 60:
			j.advance_day(d)
			for i in range(38, -1, -1):                  # neighbours meet along a line, the far end first: one step a day
				j.meet(i, i + 1)
			for i in 40:
				var b := j.belief(i, ev)
				if not b.is_empty():
					far = maxi(far, int(b.hops))
					if not day_reached.has(i):
						day_reached[i] = d
		if type == "killing":
			check(far == 39 and int(day_reached.get(39, -1)) >= 30, "no hop limit: a murder went %d retellings down the line, one meeting a day (the far end on day %d)" % [far, int(day_reached.get(39, -1))])
		else:
			check(far > 3 and far < 39, "an ordinary assault went %d retellings, past the old limit of 3, until too faint to remember" % far)
		var once := true
		for i in 40:
			if j.ledger(i, 99)[2] > 1:
				once = false
		check(once, "%s: each person judged it once, however many times it came round" % type)
		var told := int(j.stats.get("tellings", 0))
		for d in range(60, 80):
			j.advance_day(d)
			for i in range(38, -1, -1):
				j.meet(i, i + 1)
		check(int(j.stats.get("tellings", 0)) == told, "%s: processing ends: once everyone holds it as surely as they can be told it, meetings tell nothing more" % type)
	var jump := JudgmentStore.new(cfg(), social, 7)
	var e2 := jump.publish("assault", [99], [0])
	jump.observe(e2, 0)
	jump.advance_day(1)
	check(jump.belief(5, e2).is_empty() and jump.belief(39, e2).is_empty(), "no teleporting: nobody who met no one who knew has heard")


## Q08: interpretation from personal morality, relationships, loyalties and who was affected; law is not in here.
func test_q08_morality() -> void:
	var c := cfg()
	c.interpret.morality_spread_permille = 300
	var j := store(c)
	var ev := j.publish("theft", [THIEF], [BOB])
	var bys := []
	for o in range(200, 220):
		j.observe(ev, o)
		bys.append(j.bad(o, THIEF))
	var kinds := {}
	for v in bys:
		kinds[v] = true
	check(kinds.size() > 5, "people of no tie to anyone condemn the same theft by different amounts: their own morality (%d different readings)" % kinds.size())
	j.observe(ev, BOB)
	check(j.bad(BOB, THIEF) == 1000, "the one robbed reads it fully, whatever their morality")
	check(j.morality(201, 0) == j.morality(201, 0) and j.morality(201, 0) >= 700 and j.morality(201, 0) <= 1300, "a person's morality is fixed and bounded")
	var src := FileAccess.open("res://scripts/core/judgment/judgment_store.gd", FileAccess.READ).get_as_text()
	check(not src.contains("guard_confront") and not src.contains("report_crime") and not src.contains("treasury") and not src.contains("fine_for"), "no legal system inside the judgment store: fines, guards and reports stay in World (Q08)")


## Q11: murder memories are permanent; others by severity or personal significance; never expired by the ordinary
## horizon, never pushed out, kept by a save; ordinary memory stays bounded.
func test_q11_permanent_memories() -> void:
	var c := cfg()
	c.memory.capacity = 3
	var j := store(c)
	var k := j.publish("killing", [THIEF], [COUSIN])
	j.observe(k, STRANGER)
	var a := j.publish("assault", [JOHN], [BOB])
	j.observe_all(a, [STRANGER])
	check(bool(j.belief(BOB, a).permanent) and not bool(j.belief(STRANGER, a).permanent),
			"an assault is unforgettable to the one assaulted (personal significance) and ordinary to a bystander")
	for i in 10:
		j.observe(j.publish("help_minor", [300 + i], [], [STRANGER]), STRANGER)
	check(j.ordinary_count(STRANGER) == 3 and bool(j.belief(STRANGER, k).permanent), "ordinary memory stays bounded; the murder is not pushed out")
	for d in range(1, 121):
		j.advance_day(d)
	check(not j.belief(STRANGER, k).is_empty() and not j.belief(BOB, a).is_empty(), "120 days on, past the 30-day horizon: the murder and the personal assault are remembered")
	check(j.has_fact(k) and j.has_fact(a), "...their facts never retire, so they can still be told (and judged once: the knowers stay)")
	check(j.belief(STRANGER, a).is_empty(), "the bystander's ordinary memory of the assault faded away")
	check(j.meet(STRANGER, 400) == 1 and not j.belief(400, k).is_empty(), "a murder can be told years later")
	var j2 := store(c)
	j2.load_dict(JSON.parse_string(JSON.stringify(j.to_dict())))
	check(bool(j2.belief(STRANGER, k).permanent) and bool(j2.belief(BOB, a).permanent) and j2.has_fact(k), "a save and load keep permanent memories and their facts")
	for d in range(121, 200):
		j2.advance_day(d)
	check(not j2.belief(STRANGER, k).is_empty(), "...and they stay after the load")
