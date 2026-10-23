# Consolidated owner decision packet (2026-10-23)

Every question below is open in the register; settled answers are not reopened. **B19** marks what blocks Expansion 19's release;
everything else can wait without stopping work in progress. Each line gives the recommendation and what it means in play.

## 1. ID-D3: determinism baseline (B19)

| Seed | First divergence | Cause (verified) | Kind |
|---|---|---|---|
| 1 | day 13, 12:00: Amice Holt arrives from Netherton to marry with her permanent id 1000067 (Build 18 gave her 122); the 16:00 chapel service then collects 280 coins, not 305 | chapel piety is a hash of the id (`chapel.gd:153`): 0.94 for 122, 0.21 for 1000067 (below the 0.3 minimum), so she no longer gives 25 coins | expected (approved permanent identity) |
| 2 | day 13, 12:00: Rose Underwood arrives from Wulstead, id 1000017 instead of 127; the caravan sale differs (she no longer buys fine cloth, Cecily Ford buys spice) | caravan taste is a hash of the id (`luxury.gd:48`): 0.61 for 127, 0.39 for 1000017 (minimum 0.4) | expected |

Day 10 is identical to Build 18 on both seeds; no coin or item leaks; Build 18 still reproduces the old baseline. **No regression found.**

**Additionally, the REC-F1 fix (approved) changes the gate from day 10** (fewer wasted decisions, equal or more work and trade).
**Recommendation:** approve one new baseline taken on the integration commit that carries both the identity foundation and the REC-F1
fix, after I confirm its first divergences are exactly these (identity from day 13, REC-F1 from day 10) and nothing else. Keep traits
seeded from the id (no redesign). *In play:* an arriving person's piety and taste follow their permanent id; nobody already in the
village changes.

## 2. Simulation findings (run 1: 10 days, seed 1, commit 94b1304)

| | What happened | Who | Recorded cause | Consequence | Proposed correction | Decision |
|---|---|---|---|---|---|---|
| SIM-F2 | A purchase that fails is chosen again at once, all day | stonecutter p:14, day 2: 328 failed iron-chisel purchases from vendor 46, 10:01-17:59, 12 coins | the plan re-chooses an action that just failed for a reason that has not changed (he could not pay or the smith had none) | a working day lost; wasted processing | after a failed purchase, the decision skips that same purchase until the reason changes (more coins, the seller's stock changes, a new day) — a condition, not a timer | approve? **Recommended: yes** |
| SIM-F3 | Bandits stalking at night re-decide every tick | p:102, p:104 (400+ empty decisions a day) | a stalk sets a chase target but no plan, so the brain runs again every tick | processing only; behaviour works | give the stalk a plan step that lasts while the target is valid | approve? **Recommended: yes** |
| SIM-F4 | The whole six-bandit band died within nine days | p:101 starved on day 2 while poaching; p:105 starved holding 140 coins | bandits eat only by poaching (a 25% chance when hungry) or from packs; the only food purchase needs at least 15 coins **and** 60% health, so a starving or injured bandit cannot buy food | the band vanishes each season; partly real scarcity | let the health condition stop blocking a hungry bandit's food purchase (coins still required); confirm with recorded death causes in run 2 first | approve after run 2? **Recommended: yes, conditional on run 2** |
| SIM-F9 | The REC-F1 bug also cuts short eating, medicine and a homeless villager's bed | all villagers | same stale wait (a plan starting with a wait) | meals and rest end early | apply the same one-line correction | approve? **Recommended: yes** (it changes eating and rest timing; part of the new baseline) |

## 3. Expansion 19: what remains

**Release blockers (B19)** — recommended defaults:
- **X19-DECAY:** half-life 16 game days (2 game years) for ordinary deeds; murder and assault permanent. *(Your earlier choice, held only for the calendar explanation, which was given.)*
- **Placeholder numbers** (accept all for the first release, retune from the year-long comparison):
  - **X19-GOSSIP-FLOOR:** a story passes between strangers half the time.
  - **X19-RUNNERUP:** a close second is chosen 15% of the time.
  - **X19-TRUST-RATES:** trust starts at a quarter of liking; deals move it by 4 and 20; a friendly guard halves a fine.
  - **X19-PERSONALITY:** temperaments differ by up to 30%.
- **X19-EVENT-Q:**
  - a guard killing an attacker is not a killing;
  - first meetings are not recorded as facts;
  - late repayment is a fair deal with a smaller trust gain;
  - self-defence is added later.
- **Tolerance:** when your personality formula later drives tolerance, it replaces today's step for that event (does not add).
  **Confirm.**
- **Ship the personality and family-reputation layers inert in the first Build 19 release** (X19-PERS-FORMULA, X19-TRAIT-DIST,
  X19-SPILL-REACH, X19-REP-TRANSMIT, X19-BOND-LIMITS stay open without blocking), so the release is the approved judgment,
  trust, gossip, the family-sacrifice rule and the recorder.

**Not blocking (can follow in a 19.x update):**
- **X19-MISINFO:** fabrication only by someone with a motive the engine already tracks (resentment or rivalry), rarely; a lie is
  "proven false" when a guard's report or a witness contradicts it, and only those who learn that correct their judgment.
- **X19-STORY-LIFE:** permanent deeds (murder, assault, betrayal) pass to children as family stories; ordinary ones fade with the
  decay.
- **Stubbornness:** what it does in a decision, and what counts as a costly mistake or a reminder.
- **XEXPL-D1:** in-world explanations only for now; the shared record keeps a panel possible later.

## 4. Expansion 20: architecture

**Approve the architecture** (`LE00_BUILD18_REFRESH.md`, `LE01_DATA_CONTRACTS.md`): it extends the existing money, goods,
contracts and credit; the reservation and event records and actor lookup are built and off. Then, to authorize LE-01 and LE-02:

| Decision | Recommended |
|---|---|
| OD-LE-02B offer visibility | Offers are seen in person (stalls, storefronts, meetings) or heard through Expansion 19's gossip; no village-wide board |
| OD-LE-10 knowledge | One channel with Expansion 19's gossip: each price carries its source, age and trust; it goes stale, it is not forgotten |
| OD-LE-04 / 07 business identity | A business owns its till and stock as its own party, belongs to one person and passes with their estate; one person may own several; the approved household/business separation (ECON-P3) is the rule |
| OD-LE-13B death of a party | The contract passes to the estate (heir or household) when the dead party held its goods or money; otherwise it ends and anything held returns |
| OD-LE-05B interest and lending | No interest in the first release; anyone with coins may lend; collection only through the approved terms (installments, goods, pledged collateral, surplus returned) |
| OD-LE-15 performance | Mid-range phone, 500 villagers, the economy's work under 4 ms in any frame |

The rest (wages OD-LE-03, manor OD-LE-06, barter and rental OD-LE-08, bandits OD-LE-09, speculation OD-LE-11, charity OD-LE-12,
player visibility OD-LE-14) wait for LE-03 to LE-05.

## 5. Expansion 21: government

| Decision | Recommended | In play |
|---|---|---|
| P21-STRUCTURE | The elected mayor takes over the reeve's evening business (taxes within the bands, relief, works, guard pay) and the village treasury; no lord in this release (the manor stays the village's institution); the five settlements keep their named governments as they are; councils later | one leader the villagers choose; nothing in today's government vanishes |
| P21-RESIDENCY | One game year (8 game days) living in the settlement | newcomers wait a year to vote or stand |
| Q-POL-4 vote privacy | Secret ballot; totals public | |
| Q-POL-5 ties | A second vote between the tied; if tied again, the longer-serving official among them, else the elder | |
| Q-POL-6 removal | Only by death, leaving, or the next election (no recall in this release) | |

Q-POL-8 (constable), Q-POL-9 (tax authority), corruption and courts wait. Voting needs Expansion 19 switched on.

## 6. Expansions 22 and 23: audits

**Expansion 22** (Build 18 already delivers most of the original specification): the main risk was identity, now solved by the
permanent ids. Recommended answers:
- **E22-OD-03 knowledge:** experience partly passes to someone working beside an experienced worker; otherwise it leaves with the person.
- **E22-OD-04 trade:** traders' trips take real time, carry limited loads and can lose goods; settlements trade with each other.
- **E22-OD-05 growth:** off-map settlements need housing to grow; a settlement with nobody left is abandoned.
- **Authorize:** the architecture document for the hybrid simulation (E22-OD-01) and continuous geography (E22-OD-02).

**Expansion 23:** **E23-OD-01** recommended: one faction to start (today's band); its territory is its camp and the roads near it;
on a leader's death the most experienced member leads; crimes act only on real goods reached by real travel. **Authorize BAN-B**
(the faction record inside the existing money and goods books).

## Order of integration

Build 19 = Expansion 19 + identity foundation + REC-F1 fix + family rule + recorder (off in public builds), integrated and gated
first; then 20, 21, 22, 23, each on its own branch and released in turn.
