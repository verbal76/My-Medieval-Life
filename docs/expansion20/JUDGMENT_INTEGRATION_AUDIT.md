# Judgment integration audit and calibration (SJD-H C1, C2, C5)

This audit covers owner decisions C1, C2 and C5, with C6 confirmed unchanged
(`docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md`). It was done on branch
`wip/x20-judgment` (Worker F), based on `531da40`, the integrated Expansion 20 code.

- **Evidence:** Worker D's 365-day soak, `docs/expansion20/SJDG_SOAK_REPORT.md` (Actions 41129188776),
  plus the tests named below.
- **Design authority:** the approved judgment framework, `docs/expansion19/DESIGN.md`.
- **Wiki:** this is a developer reference. The wiki pages describing judgment were checked; see section 6.

C1 distinguishes two things, and the tables below keep them apart:

- **Influence:** judgment changes which option is preferred.
- **Reversal:** judgment changes the outcome against the live rule's answer: another seller, a refusal,
  a delay.

## 1. Why judgment was nearly inert (finding)

Over two village-years, judgment changed 0.24–0.29% of sales and refused nothing (soak F5, F8). The
weights were not too small for any single reason. Two structural causes made it so:

1. **The opinion scale did not match the severities.**
   - A decision reads the disposition as 50 + NET on a 0–100 scale (spec s.7.3).
   - With the approved severities (0.2–3 points a deed), confidence and decay, live NETs stay within a
     few points. The soak's p1 to p99 range is −4.6 to +0.2.
   - So an assault on oneself (−2 points) moved a weighed utility by 0.3–0.6 of a point. Every
     choice-among-alternatives profile has a live-order step of 4 points plus a margin of 2.
   - In yes-or-no profiles, the per-person weight spread (±30%) acts on the 50-point midpoint. That
     makes ±4.5 points of personality noise, larger than any realistic opinion.
2. **The live order stepped between candidates the live rule could not tell apart.**
   - Buyers of one trade, timber sellers and hirable villagers were each a full step apart, purely by
     villager order.
   - So "two reasonably comparable merchants" were never comparable to the weighing.

Calibration, with no severity, decay or threshold changed (C1 rule 5, C6):

- **Opinion gain.** `decision.opinion_gain_permille` is 10000 (PROVISIONAL agent value). A decision
  reads an opinion as 50 + 10 × NET, clamped to 0–100.
  - The store keeps 50 + NET for every other reader, so the spec arithmetic tests still pin 1:1.
  - The gain scales only the distance from neutral, so the personality spread no longer drowns it, and
    neutral is exactly 50 at any gain.
  - It reads positive and negative opinions alike (C1 rule 7).
  - The family name's colour is read with the same gain.
- **Tiers.** Candidates the live rule cannot tell apart share a tier.
  - The live order steps only between tiers.
  - Within a tier, of candidates with identical weighed factors, only the first is weighed. So with
    neutral judgment the live rule's pick still stands, with no near-best draw among equals.
  - Judgment then decides among comparable options (C1: "a meaningful tendency").

## 2. Decision systems

| Decision (code) | Before: considered? | Before: can change the outcome? (evidence) | After |
|---|---|---|---|
| Whom a villager sells to: `trade_sell` (`NPCBrain._buyer_for` → `JudgmentLive.pick_buyer`) | yes | Rarely: 0.24–0.29% of sales (soak). The step between any two buyers was 4 points; a NET gap of about 27–40 points was needed. | **Integrated and calibrated.** The buyers of one trade are one tier; judgment chooses among them. Other trades still need a large opinion gap. The shortcut scans only the first's trade when later trades cannot be drawn; the result is exact (`judgment_live_test` 12 mixes, `judgment_soak_test` 40 mixes). `test_c1_positive_judgment_live`: most sellers sell to the merchant who helped them. |
| Whom a household buys timber from: `trade_buy_from` (`_seller_of` → `pick_seller`) | yes | Somewhat: 2.0–2.3% of buys (soak). | Carpenters and raw merchants are tier 0, woodcutters tier 1; trust and ambivalence added. `test_c1_comparable_sellers_live`: the trusted or liked seller gets 34 of 40; neutral buyers keep the live first 40 of 40. |
| Iron-bar seller (`NPCBrain._bar_seller`) | **no** | No: first in villager order. | **Newly integrated** (`pick_comparable`, `trade_buy_from`). `test_c1_bar_seller_live`. |
| Seed merchant (`NPCBrain._plan_buy_seed`) | **no** | No: first merchant. | **Newly integrated** (`pick_comparable`). |
| Tool seller, or putting the purchase off (`NPCBrain._buy_tool`, `_fetch_dress_tool`) | **no** | No: first seller by trade order, always bought. | **Newly integrated** (`tool_buy`, C5). See section 4. |
| Food from a neighbour: `food_seller` (`Credit._cheapest_food`) | yes | Rarely: a step per rank regardless of price. | Neighbours at one price per food point are one tier. Trust, fear (−) and loyalty (kin, friend) added. |
| Which seller a buyer asks first for a contract: `contract_seller` (`Contracts._order`, Prospecting kit) | yes | Rarely. | All one tier (the live rule asks in villager order); trust and ambivalence added. |
| Whom a household hires to carry: `hire_choice` (`Construction._keep_building`) | yes | Rarely. | All one tier; trust added. |
| Whether a seller takes a contract: `contract_accept` (`Contracts.evaluate`) | yes | **No:** 0 of 102–148 a year refused (soak). | Gain; ambivalence −50 ("wary but willing"). |
| Credit: `credit_lend` (`Credit.credit_refusal`) | yes | **No:** 0 refused (soak). A refusal needed NET below −33 points. | Gain; ambivalence −100. `test_c1_yes_or_forgo_live`, over 30 villagers: assaulted once by the buyer, 13 refuse; twice, 24; twice but needing coin, 0. Need outweighs dislike. |
| Barter: `barter_accept` (`Credit.barter_quote`) | yes | **No.** | Gain; ambivalence −50. |
| Taking work: `work_accept` (`Construction.hire`, `Business.hire`) | yes | **No:** 0 of 10398 (soak). | Gain. Need still dominates: a worker with no coin always accepts (`judgment_live_test::test_q14_hiring`). |
| Befriending: `befriend` (`Relations._befriend_if_close`) | yes | Held back 2.3–2.4% (soak). | Gain. A dislike now needs proportionately more closeness. Closeness, the live threshold, is never lowered by liking. |
| Whom to court: `court_choice` (`Relations._villagers_court`) | yes | Influence among candidates only (soak F11). | Gain. The courting cut-offs are unchanged (X19-CRT12). |
| Accepting a proposal: `proposal_accept` | yes, with aspirations on | Off by default (aspirations off). | Gain applies when on. |
| A relative's help toward a home: `family_help` (`Construction._family_help`) | yes | Never refused in the soak. | Gain. |
| Family priorities: meal, pay, work, danger (`JudgmentFamily`, FAMILY-01) | rule plus weighed exceptions | By design, a rule (children, spouse, parents, self). | Unchanged. Family-first is the owner's rule, not an opinion. |
| Reporting a crime: `report` (`World.report_crime`) | hook exists, **off** (`integration.report` false until R6 measures it) | No (off). | Unchanged; the gain will apply when the lead turns it on. **For the lead:** turning it on is an existing approved hook awaiting R6 measurement, not part of this work. |
| Gossip: whom a teller tells (`gossip.share_net_at` −20 points × tolerance); rival reading (`interpret.rival_net_at` −10) | yes, as NET thresholds | Practically never: NETs rarely reach −10 or −20 (soak NET min −13 to −24). | Unchanged. These shape how judgment is formed and passed on (C6 territory), not a decision weighting, so no threshold was moved. Recorded as an observation. |
| Lies (X19-MISINFO) | yes (resentment, rivalry) | Yes: 150–245 a year (soak). | Unchanged. |
| Job choice: `job_choice` (`NPCBrain.seek_work`) | with aspirations on | Off by default. | Unchanged. |
| Market offers with the economy on: `market_buy`, `market_sell` (`EconMarket`) | yes | Economy off by default. | Read through the same weighing, so the gain applies when on. Not run here: the economy is off. |
| Meal vendor and grain seller (`_vendor_with_food`, `_grain_seller`, `_plan_eat`, `_plan_provision`) | no | No: the nearest vendor. | **Not changed, deliberately.** These are survival purchases at the nearest vendor; the short household's path (`food_seller`) is weighed. Weighing walking distance against opinion here is a candidate for later work, and is listed for the lead. |
| Cart-part seller (`_part_seller`, nearest) | no | No. | Not changed: nearest-first, rare. Candidate for later work. |
| Evening company (`_plan_seek_company`: the friend of highest regard) | no (relationship regard only) | No. | Not changed: regard already carries liking. Candidate for later work. |
| Migration (`Migration`: work, land, marriage, hunger) | no | No. | **Not changed. Needs the owner.** Making judgment a reason to leave would add a fifth reason to the owner's four (Q18-7). |
| Settlement couriers (`CourierService.carriers`, `carrier_refusal`) | no | No. | Not changed: institutional carriers and booths. Candidate for later work. |
| Guard behaviour, bandit targets and combat choice | no | — | Out of scope: Worker D owns them (bandit AI, C3). |

## 3. C2: memory retention (and C6)

- An assault (catalog `"memory": "firsthand"`) is a permanent memory only for those it personally
  touched:
  - the one assaulted (participant);
  - eyewitnesses;
  - the family (`JudgmentSocial.kin`) of the one harmed: "personally significant".
- Anyone else's told or rumoured account is an ordinary memory. It fades
  (`memory.salience_fade_permille`) and is bounded by `memory.capacity`.
- The opinion formed stays exactly as before. It sits in the ledger's permanent part (X19-ASSAULT),
  forgetting keeps it (`retract_on_forget` false), and re-telling never re-scores it.
- Killing stays permanent for everyone (Q11).
- First-hand weighs more than second-hand through the existing confidence: told at 0.9 × credibility.
- A told memory later witnessed becomes permanent.
- Lesser offences (theft) were already ordinary memories. Their judgments still decay with the
  approved 16-day half-life (C6, unchanged). A repeat adds a new contribution and so refreshes the
  opinion.
- No artificial permanent hostility: nothing new is permanent.
- Saves:
  - Memory rows keep the flag they were saved with.
  - Rows without flags (rounds 1–3) read by the rule they were saved under.
  - No new saved field.
  - The Build 24 fixture loads with all 227 permanent memories (`test_c2_old_saves`).
- Family stories: parents pass on permanent memories. A parent's hearsay of an unrelated assault is no
  longer passed on; a family member's is.
- Tests: `judgment_calibration_test` `test_c2_*`, and `judgment_test::test_q07_no_hop_limit` (assault
  hearsay now travels until too faint, like theft).
- Save size after a year: section 5.

## 4. C5: mixed feelings

The weighing (`JudgmentWeighting._fill`) now reads separate factors, each with its own per-person weight.
Personality enters through the existing per-factor spread and through stubbornness. No factor is folded
into another.

| Factor | What it reads |
|---|---|
| opinion (`disposition`) | NET, with the gain (section 1) |
| trust | reliance moved by the person's own dealings and tellings (X19-REGARD; liking excluded) |
| fear | the permanent violence part held against the other × 25 per point |
| loyalty | kin 100, friend 70 |
| respect | the seller's skill in their trade |
| ambivalence | min of the effective GOOD and BAD: "wary but willing". This now reads the decayed parts; the lifetime totals only ever grew. |
| dependence | `sole_source` and `necessity` |

Tool purchase, `tool_buy` (the owner's blacksmith example):

- The candidates are the live rule's feasible sellers.
- The live order and the price enter as costs that are 0 for the live rule's first pick: `later`, 10
  points a later tier; `dearer`, the extra over the first's bargained price. So judgment shows against
  need instead of hiding under a big baseline.
- `necessity` is 100 for the tool of one's trade or the house axe, 30 for a shovel to open a pit.
- `forgo` (28 points) means putting it off: an idle wait, weighed again at the next plan.
- No automatic refusal.

Outcomes:

- **Bare store, 60 personalities** (`test_c5_mixed_feelings_bare`). The buyer saw the smith beat his
  brother: NET −1.18, fear 30.

| Circumstance | Outcome (of 60) |
|---|---|
| Sole source, desperately needed | buy 60 |
| A second smith at a fifth more | elsewhere 54 |
| A seller of another trade at a fifth more | elsewhere 22, the smith 38 (personality; respect for his work) |
| Optional need, sole source | put off 2, buy 58 |
| The smith is also family | 60 deal with him |
| The smith once rescued him | 60 deal with him |

- **Same NET with and without fear:** the feared seller sends more buyers elsewhere. Fear is not
  collapsed into the opinion.
- **Live** (`test_c5_blacksmith_live`, 24 woodcutters):
  - Sole source: all 24 buy from the smith who beat their brother.
  - With a second, dearer smith: all 24 go there.
  - Neutral buyers keep the live rule's seller.
- **Not implemented:** "ask someone else to negotiate". It would be a new mechanic (an intermediary
  purchase) and needs a design decision. The other alternatives the owner named are covered: trade, pay
  more elsewhere, delay, abandon (repeated delay).

## 5. Measurements

### 5.1 Local G0 (`tools/sim_gate.py`)

- **Run:** seeds 1 and 2, 30 days, code `2a2700d`.
- **Result:** differs from `docs/release/sim_baseline.json` at every checkpoint (28 differences). This
  is expected: judgment is on by default and its choices now move.
- **Conservation:** clean at all four checkpoints (days 10 and 30 of both seeds): currency leak 0, item
  leaks none.

| Checkpoint | Baseline → this branch |
|---|---|
| s1 day 10 | alive 110 → 108; treasury 11 → 1 |
| s1 day 30 | alive 117 → 115; treasury 6 → 8 |
| s2 day 10 | alive 105 → 113; treasury 106 → 95 |
| s2 day 30 | alive 111 → 123; treasury 1 → 100 |

- **Also differ:** fingerprints, currency, item ledger, deposits and animals.
- **Baseline:** not rewritten; the lead replaces it at integration.

### 5.2 Year-long runs

The new run is Actions 41166571846 (jobs 124435342689 seed 1, 124435342660 seed 2): `d99ec66`, shipped
switches, 365 days, every 10. Both ended with exit 0, 0 script errors and no FATAL line. Currency leak
was 0 and item leaks none at all 37 checkpoints of each seed. It is compared with Worker D's 41129188776
(`d0f623b`, before the SJD-G shortcut fix).

The two runs are not matched worlds: the seeds diverge from day 0, and the populations differ.

| | D s1 | F s1 | D s2 | F s2 |
|---|---|---|---|---|
| Day 365 alive; starved | 312; 81 | 360; 0 | 512; 0 | 290; 0 |
| Sales (`trade_sell`) changed by judgment | 311 of 107113 (0.29%) | 5395 of 84638 (6.4%) | 275 of 114380 (0.24%) | 3791 of 108849 (3.5%) |
| Timber (`trade_buy_from`) changed | 205 of 8901 (2.3%) | 1209 of 5069 (23.9%) | 113 of 5534 (2.0%) | 272 of 3779 (7.2%) |
| Contract seller asked first changed | n/a | 209 of 249 | n/a | 367 of 463 |
| Hiring changed | n/a | 0 of 7 | n/a | 66 of 76 |
| Food from a neighbour changed | n/a | 12 of 55 | n/a | 10 of 44 |
| Tool purchases weighed; changed; put off | n/a | 34; 3; 0 | n/a | 21; 1; 0 |
| Friendships held back | 142 of 5983 (2.4%) | 274 of 2458 (11.1%) | 83 of 3672 (2.3%) | 38 of 1826 (2.1%) |
| Refusals: contract, credit, barter, work | 0/148, 0/4, 0/6, 0/10398 | 0/111, 0/3, 0/0, 0/793 | 0/87, 0/5, 0/6, 0/61 | 0/170, 0/1, 0/6, 0/6584 |
| Memories (permanent) | 33115 (25211) | 8265 (708) | 53207 (43422) | 5711 (376) |
| Contributions; ledger entries | 27410; 34652 | 2648; 12749 | 45832; 25766 | 1705; 20427 |
| Judgment section, bytes | 4428882 | 1396577 | 5752694 | 1228014 |
| World save, bytes | 20201337 | 7676950 | 15438378 | 6411658 |
| Judgment section, bytes per living person | 14195 | 3879 | 11236 | 4235 |
| Static memory at end / peak, MB | 724 / 734 | 377 / 386 | 559 / 569 | 346 / 355 |
| Runtime, s; judgment's trade-choice time, s | 11043; 4386 | 10570; 4128 | 15526; 4869 | 11111; 3774 |
| Effective NET p1 / p5 / p50 (points) | −2.1 / −0.7 / 0 | −3.2 / −1.5 / −0.02 | −3.2 / −1.4 / −0.07 | −1.2 / −0.4 / 0 |
| Courtships / partnerships at the last checkpoint | 167 / 110 | 84 / 66 | 147 / 89 | 64 / 65 |

Readings:

- **Judgment now moves choices among comparable options.** The "changed" figures for contract seller and
  hiring are high because those live rules take villager order, which says nothing. A changed pick there
  means judgment decided among equals, not that it overrode a practical preference.
- **No refusals appeared in either year.** Yes-or-no offers were mostly made to people with neutral or
  mild opinions, and need outweighs dislike. C1 sets no target, and none was forced.
- **Tool purchases are rare.** None was put off, which is consistent with the sole-source guarantee.
- **C2 cut the judgment section to about a third or less per living person.** Permanent memories fell
  from 76–82% of all memories to 7–9%. NET distributions, the opinions themselves, stay of the same order.
- **Performance did not regress.** Runtime and the judgment trade-choice time are below D's
  (part of that is SJD-G's shortcut fix, which D's run predates), and memory is lower.
- **Courtship pacing needs a matched comparison.** D's report showed no regression at day 100. This
  run's day-100 figures are similar or higher: courtships about 14–22, partnerships 26–27. But the
  year-end totals are lower, against larger or smaller populations. Friendships held back rose in seed 1
  (11.1%), which the opinion gain on `befriend` can explain. A matched comparison (the same commit with
  `opinion_gain_permille` 1000 for `befriend` only) would isolate it. **Flagged for the lead;** no run was
  made beyond the budget.
- **One permanent entry reaches −158 points** (s1; −110 in s2). It comes from 176 contributions against
  one subject: repeated blows, each posted as an assault (twins: assault 113). That is the C3
  episode-counting defect Worker D is fixing; it is not this calibration.

## 6. Wiki

Updated `game/scripts/core/wiki_topics.gd`, page "What villagers think of you":
- **Memory and time:** hearsay of an assault fades, while the opinion it formed stays.
- **New section, Mixed feelings:** comparable sellers, the sole seller of a needed tool, paying more
  elsewhere, putting off a purchase, less willingness to lend to someone who wronged you.

`wiki_test` passes 141/0. No numbers or internals are shown.
