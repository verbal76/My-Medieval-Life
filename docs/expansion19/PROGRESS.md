# Expansion 19 prospective development: progress

Reporting fields from the owner directive `docs/directives/2026-10-21_parallel_prospective_development_18_19.md`
(PROS-01, PROS-19). Design, decisions and the owner-question table: `docs/expansion19/DESIGN.md`. Nothing here is
integrated gameplay: everything is off in the game, nothing is merged into staging, no build is made.

Updated 2026-10-23 (round 8: event feeds from the live acts, DESIGN.md section 9.3; X19-Q-TIMING implemented; SYNC-18 baseline). Earlier: 2026-10-22 (the investigation round on `05adc9d`: timing proposal, worst frame, memory).

**SYNC-18 baseline (2026-10-23):** Build 18 (`wip/build18` at `239bdff`) is merged into this branch at `c2ece16`. The
determinism gate (`tools/sim_gate.py`, seeds 1 and 2, days 10 and 30) is identical to the baseline both at `c2ece16` and
after the X19-Q-TIMING change (judgment is off, so nothing moves).

**X19-Q-TIMING (owner answer 2026-10-23) implemented:** `gossip.timing` "scheduled", closeness-weighted passing
(`gossip.closeness_floor_permille` 500, agent-proposed, needs owner review), pending meetings survive save/load (also across a
timing change). Details, tests and measurements: DESIGN.md section 15a.

## Branch and latest pushed commit

`wip/expansion19-preparation`, branched from staging `b721616` (Build 16 released, plus records). Round 1: `3005d6f`
(isolated prototype), `221ac6f` (live adapter, off), `efbd31c` (performance suite, documents), `e05d367`. Round 2: `ff19cb2`, `693e0c3`
(compact records, sliced daily update, trade-hook shortcut, measurements). Round 3: `940a989`, `6615da4` (gossip queue, cheaper telling, the scheduled option, measurements). Round 4: the
commits that add this update (the owner's SJD decisions, Q14 integrations, the decay demonstration). The pushed head is
the branch head on GitHub.

## Synchronized with Build 17 (SYNC-17)

**Build 17 baseline: `wip/build17` at `cd7439c`**, merged one way into this branch by merge commit `93c107f`. The branch
was at `1b05da0` before. Conflicts, the compatibility review and measurements are in DESIGN.md section 13.

Focused tests on the merged code (SIM-01), with private user data:

| Suite | Checks |
|---|---|
| `judgment_test` | 164 |
| `judgment_live_test` | 53 |
| `judgment_decay_demo` | 24 |
| `world_test` | 339 |
| `run_tests` | 3544 |
| `equip_test` | 51 |
| `contracts_test` | 138 |
| `conservation_test` | 8 |
| `wiki_test` | all passed |

All had 0 failures. Python unittest OK; `check_interactions`, `check_resources` and `check_materials` report 0 problems.
One 30-day `economy_sim --judgment` on seed 1 had no leaks at days 10, 20 and 30. `judgment_perf` at 500 people, live
rate: frame p99 1.41 ms and p99.9 3.67 ms, unchanged from round 4.

Outstanding from the sync: Build 17's contract breaches and acceptance (CON-01/02), and collapse deaths as remembered
facts, are new event feeds and decision points. They are not wired (no new judgment behaviour); they go in at the Build
18/19 reconciliation.

## Investigation round (owner-directed, 2026-10-22, on `05adc9d`)

Details are in DESIGN.md section 15 and `docs/expansion19/GOSSIP_TIMING_PROPOSAL.md`. Results are byte-identical:
- the same `judgment_perf` hashes in all six configurations;
- in the 30-day village on seed 1, the same world fingerprint `1c755f53d12c72bd470b7913fb5e52a6`, the same judgment
  state hash 1780545997, and no leaks.

- **X19-Q-TIMING:** (2026-10-22) written up; **answered and implemented 2026-10-23, see above and DESIGN.md section 15a.** The paper covers the scheduled option in detail and
  a third variant ("ordered": today's order of tellings, paced through the hour). The recommendation is to keep "hour"
  until Gate E, and to prefer "ordered" if a bounded frame is wanted then.
  - **Measured:** of 40,000 trade choices, none chose differently under "scheduled". The dispositions they read
    differed by at most 0.4 points (live) and 1.5 points (heavy) of 100.
- **Worst frame:** profiled.
  - The capacity check now runs in one pass (−27% of its time at the heavy rate).
  - The heaviest frame keeps its 107 and 188 tellings. Splitting or trimming the dependency flush cannot keep results
    identical (DESIGN.md 15.1).
  - Native code or a timing change would bound it; both are for the owner.
- **Memory:** ledgers are now packed per observer. Heavy rate 16.9 to 13.5 MB, live 5.7 to 3.6 MB at 500 people, both
  within the proposed 16 MB.

Tests: `judgment_test` 168, `judgment_live_test` 53, `judgment_decay_demo` 24, `judgment_perf` 9 checks, all with 0
failures.

## Gossip frame round (owner-directed, 2026-10-22)

Details are in DESIGN.md section 14. Results are byte-identical:
- the same `judgment_perf` state hashes in every configuration;
- in the 30-day village on seed 1, the same world fingerprint `1c755f53d12c72bd470b7913fb5e52a6`, the same judgment
  state hash 1780545997, and no leaks.

**What changed:**
- reads no longer tell queued meetings that cannot change what they read (cached under a version counter);
- ledger decay is applied lazily, entry by entry;
- interpretation builds no dictionary unless traced;
- the live adapter reads relationship ties without building blank ones.

**Results (500 people, live rate):**
- frame p99 1.27 to 1.05 ms;
- frame p99.9 3.35 to 1.81 ms;
- flushes 391 to 29 over 40 days;
- daily update 11.6 to 4.0 ms a day.

The worst single frame did not fall: 107 tellings live and 188 at stress, unchanged. It is a necessary dependency flush,
which only the pending scheduled timing (X19-Q-TIMING) would bound further.

Tests: `judgment_test` 168, `judgment_live_test` 53, `judgment_decay_demo` 24, `judgment_perf` 9 checks, all with 0
failures.

## Owner decisions of 2026-10-21: implemented and pending

The owner answered SJD-Q01, Q02, Q06, Q07, Q08, Q10, Q11 and Q14
(`docs/directives/2026-10-21_expansion19_sjd_final_decisions.md`, on staging; the register answers are on staging
`a900a56`). The rules and the tests are in DESIGN.md section 5.1. Approved design is not the same as implemented
gameplay: everything below is on the isolated branch, and all of it is off in the game.

| Decision | Implemented on the branch (tested) | Still pending |
|---|---|---|
| Q01 facts, zero interpretation | yes (`test_q01_facts_and_zero`) | which NEUTRAL types get personal rules (none set) |
| Q02 slow decay, murder permanent | yes, with fading and permanent ledger parts (`test_q02_decay_and_murder`, `judgment_decay_demo` 24 checks) | **the rate**: 3 permille a day proposed, unapproved; demonstration in DESIGN.md section 11 |
| Q06 trust from the relationship number | yes, Relations regard (`test_q06_trust`, `test_q06_live_trust`) | calibration of the proposed numbers |
| Q07 no hop limit, real encounters only | yes (`test_q07_no_hop_limit`) | the live `Relations.harmed` instant spread (conflict 1) |
| Q08 morality, loyalty, law separate | yes (`test_q08_morality`) | CRT-06's friendly guard (conflict 3) |
| Q10 no numbers to the player | yes: no UI reads judgment (`test_q10_no_numbers_in_ui`); refusals in words | player-facing attitude words at Gate E |
| Q11 permanent memories | yes (`test_q11_permanent_memories`; perf checks ordinary memory bounded and old facts permanent) | `permanent_personal_severity` 2000 is a proposal |
| Q14 universal integration | six existing decision points wired, each off by default, each tested both ways (DESIGN.md section 9.1) | contracts (Build 17 CON-01), favours, villager proposals (CRT-12, conflict 2), help and trade event feeds (section 9.2) |

## Implemented and tested

| Feature (directive item) | Code | Tests (checks, all passing) |
|---|---|---|
| Personal memory and event interpretation: facts, beliefs with provenance, bounded and fading memory, event horizon | `JudgmentStore` | `judgment_test.gd` (99 in all) |
| Signed opinion records and subjective judgment: GOOD/BAD contributions by signed interpretation (affected, kin, friend, bystander, rival, accomplice, loyalty, capped prior bias), idempotent replacement, corrections, never-negative ledgers, NET | `JudgmentStore` | `judgment_test.gd`: every fixture of spec s.15 (victim 1, cousin 0.55, rival 0.65 GOOD, disapproval of GOOD, indifference, NET -6.59, rumour repeat, belief correction, determinism) |
| Decision weighting: judgment one weighted factor over the live code's feasible candidates; explanation traces | `JudgmentWeighting` | `judgment_test.gd`: the 50-iron problem reproduces 81.841; need outweighs a -40 opinion when no one else sells; opinion tips a moderate need to doing without and outweighs a small price gap; a large price gap outweighs it; judgment's whole range moves a choice by its weight only; a positive judgment never makes an infeasible choice; argmax and seeded margin selection; per-person weight spread |
| Provenance and information sharing: told by whom, rumour after two hops, confidence by hop and credibility, budgets, max hops, min confidence, no telling to the disliked, optional seeded misattribution reversed by the truth | `JudgmentStore.meet/tell` | `judgment_test.gd` |
| Persistence and migration prototype: `mml-judgment/1` section, round trip identical through JSON text, draft v0 migration, newer or damaged sections kept unread and written back; World save section only when attached, SAVE_VERSION unchanged, Build 16 saves load with judgment off | `JudgmentStore.to_dict/load_dict/migrate`, World hooks | `judgment_test.gd`, `judgment_live_test.gd` |
| Deterministic decisions: integer arithmetic, seeded hashes (no `World.rng`) | `JudgmentMath` | `judgment_test.gd` (same state hash twice), `judgment_live_test.gd` (a day of the live village with judgment on, twice: same world and same judgment hash), `judgment_perf.gd` |
| Live adapter, off by default: observation from `World.witness`, `raise_alarm`, `kill`; word of mouth from `Relations.share`; dawn; save; trade-choice prototype in `NPCBrain._buyer_for` | `JudgmentLive` | `judgment_live_test.gd` (26): off by default; witnesses judge, distant villagers know nothing; player and villager assaults judged identically; the trade pick stays within the live rule's buyers, equals the live choice while judgments are neutral, avoids a strongly disliked buyer when another exists, still sells when every buyer is disliked |
| Large-population performance | `judgment_perf.gd` | 19 checks at 100 / 500 / 2000 people, live and stress event rates, hour by hour (memory bound, facts within horizon, save round trip, determinism); figures and budgets in DESIGN.md section 7 |
| Round 2: compact records (packed arrays) | `JudgmentStore` | memory at 500 people 10.7 -> 4.0 MB (live rate), 57.9 -> 16.1 MB (stress); every perf scenario's final state hash identical before and after |
| Round 2: daily update sliced over the day's hours, catch-up on touch | `JudgmentStore.begin_day/dawn_hour/dawn_slice`, World hooks | `judgment_test.gd` (105 in all): sliced and whole updates agree on every telling, choice, opinion and the end state hash over twelve days with newcomers, also with retraction, a fading view and rumours on; largest update hour at 500 people live: 11.38 ms (one call) -> 0.55 ms median day |
| Round 4: the owner's rules Q01, Q02, Q06, Q07, Q08, Q10, Q11 | `JudgmentStore`, `JudgmentSocial.regard`, `judgment.json` | `judgment_test.gd` 164 checks (one test per decision); `judgment_decay_demo.gd` 24 |
| Round 5 (2026-10-23 owner answers): Q05 no prior bias, Q09 near-best, X19-ASSAULT permanent | `judgment_store.gd`, `judgment_weighting.gd`, `judgment.json` | `judgment_test.gd` 189 checks (rewritten: prior bias; changed: selection, q07 line test now theft, q11 assault; new: `test_x19_assault_permanent`) |
| Round 8 (2026-10-23): event feeds from the live acts (gift, help_minor, help_build, rescue, trade_fair, trade_cheat, bandit theft, villagers' killings, unseen pickpocket, marriage) | `JudgmentLive.on_*`, one guarded call each in `Relations`, `Quests`, `Construction`, `MineWorks`, `Contracts`, `Credit`, `NPCBrain`, `World` | `judgment_live_test.gd` 98 checks (`test_event_feeds`: actor, victim, beneficiary, witnesses, trivia, determinism); sources and the events with no source: DESIGN.md section 9.3. 30-day `economy_sim --judgment` seed 1: 192 events (assault 61, gift 62, theft 59, trade_fair 7, marriage 3), no leaks, no script errors; `judgment_perf` 500 people live scheduled worst frame 6.95 ms; `sim_gate` identical |
| Round 4: Q14 integrations (buyer, timber seller, helper hire, taking work, befriending, courting) | `JudgmentLive`, one guarded line each in `NPCBrain`, `Construction`, `Business`, `Relations` | `judgment_live_test.gd` 53 checks: judgment changes the choice, need or closeness or attraction outweighs it, feasibility never overridden, neutral judgment = the live choice |
| Round 3: word of mouth queued and told a few a tick; reads first tell the meetings they depend on | `JudgmentStore.meet_hourly/meet_later/gossip_tick/_flush_for` | `judgment_test.gd` (129 in all): same tellings, every read along the way, beliefs and end state as telling at once (also with retraction, a fading view and rumours), and the test fails if the flush is removed; perf: spread = told at once = round 2's end state at every size and rate; at 500 people live, frame p99 1.03 -> 0.87 ms and p99.9 5.66 -> 2.15 ms |
| Round 3: cheaper telling (cached settings, no formatting, packed sort, "nothing new" shortcut) | `JudgmentStore.tell/interpret/evaluate/_post` | results unchanged (same state hashes as round 2 at every size and rate) |
| Round 3 option: scheduled timing (off) | `gossip.timing` "scheduled" | `test_scheduled_gossip`: told at its own minute, never before, kept in a save, deterministic; frames p99 0.62 / p99.9 1.25 ms at 500 people live; results differ by design |
| Round 2: trade-hook shortcut | `JudgmentLive._first_stands` | `judgment_live_test.gd` (27): picks exactly as the full scan over twelve opinion mixes; economy_sim 10 days seed 1: about +20% wall time before, about +5% after, no leaks, same fingerprint |

Round 4 regression evidence (judgment off), on this branch before the round-4 push:
- **Judgment suites:** `judgment_test` 164, `judgment_live_test` 53, `judgment_decay_demo` 24, `judgment_perf` 23
  checks, 0 failures.
- **Game suites:** `run_tests` 3535, `world_test` 200, `relations_test` 79, `parity_test` 55, `conservation_test` 8,
  `save_transfer_test` 21 checks, 0 failures.
- **Python unittest:** 105 OK.
- **Determinism gate:** `tools/sim_gate.py` **PASS, identical to the baseline**.
- **Judgment on:** the 10-day `economy_sim --judgment`, seed 1, had no currency or item leak and the baseline
  fingerprint. It made 1,599 tellings (499 before the hop limit was removed) and 1,101 belief upgrades, and its
  decision points recorded 32,864 sale choices, 245 timber-seller choices, 34 befriending checks and 15 courtship
  choices. No household hired a helper in those 10 days.

Round 3 regression evidence (judgment off), on this branch before the round-3 push: `judgment_test` 129,
`judgment_live_test` 27, `judgment_perf` 23, `run_tests` 3535, `world_test` 200, `relations_test` 79, `parity_test` 55,
`conservation_test` 8, `save_transfer_test` 21 checks, 0 failures; python unittest 105 OK; `tools/sim_gate.py` **PASS,
identical to the baseline**. With judgment on, the 10-day `economy_sim` (seed 1, run twice) gives 75.9 s and 75.2 s
against 78.1 s and 77.5 s with it off. There are no leaks, the fingerprint is the baseline's, and the judgment counts
and tellings equal round 2's.

Round 2 regression evidence (judgment off), on this branch before the round-2 push: `judgment_test` 105,
`judgment_live_test` 27, `judgment_perf` 19, `run_tests` 3535, `world_test` 200, `relations_test` 79, `parity_test` 55,
`conservation_test` 8, `save_transfer_test` 21 checks, 0 failures; python unittest 105 OK; `tools/sim_gate.py` **PASS,
identical to the baseline**. With judgment on, `economy_sim --judgment` 10 days seed 1 (twice): no currency or item leak,
day-10 fingerprint equal to the baseline's.

Round 1 regression evidence for the hooks (judgment off), run on this branch before pushing `221ac6f`: `run_tests` 3535,
`world_test` 200, `relations_test` 79, `parity_test` 55, `conservation_test` 8, `save_transfer_test` 21 checks, 0
failures; `python3 -m unittest discover -s tests` 105 OK; `python3 tools/sim_gate.py` (seeds 1 and 2, 30 days):
**PASS, identical to the baseline**. With judgment on, `economy_sim.gd --judgment --days 10 --seed 1`: no currency or
item leak, and the day-10 fingerprint equals the baseline's (the few events of a normal village moved no trade choice).

## Implemented provisionally

- Every number in `game/data/judgment.json` (severities, interpretation weights, confidence, memory capacity and
  fading, gossip reach, decision weights) is an agent default for isolated tests, not calibrated and not approved.
- The owner questions SJD-Q01..Q14 are parameters with provisional defaults (DESIGN.md section 5); none is answered.
- The trade-choice hook and its `trade_sell` profile (live order, need for coin, disposition; price weight 0).
- Event publication covers only what the live game detects today: the player's thefts, anyone's attacks (raise_alarm,
  including bandit robberies), the player killing a villager. Help, gifts, fair trade, rescue and villagers' thefts are
  in the catalog but not yet published by live code.
- The event horizon (30 days) and forgetting without retracting points (DESIGN.md A19-4, SJD-Q02/Q11).

## Dependencies awaiting Builds 17 and 18

- Build 17 contracts (CON-01 `evaluate` on `wip/build17`): the reconciliation recommends trade through CON-01 as the
  first live domain; the adapter would weigh contract acceptance there instead of (or as well as) `_buyer_for`.
- Build 18 settlement trade and regional economy (the Expansion 18 branch): inter-settlement trade decisions, caravan
  replacement, settlement inventories; judgment between villages and their traders needs those interfaces.
- Living-economy actors (proposed Build 20) would supply the needs and alternatives factors in general form.
- No unfinished Build 17 or 18 interface is used or assumed here; nothing from those branches was merged.

## Known integration risks

- Hooks touch `world.gd`, `relations.gd`, `npc_brain.gd` (one guarded line each, plus the save section): small but
  real merge points with Build 17 and 18 changes to the same functions.
- Round 4 frame cost (DESIGN.md section 12): with the owner's rules, the frame p99 at 500 people at the live rate rose
  from 0.87 to 1.45 ms here. The causes are the daily decay over every ledger, stories travelling further, and belief
  upgrades. The 2026-10-22 gossip round (section 14) made the decay lazy and brought p99 to 1.05 ms, with identical
  results.
- Permanent memories grow without a cap by design (Q11). At the stress rate, assault victims accumulate them (1,646 at
  500 people over 40 days) under the proposed `permanent_personal_severity` 2000. At the live rate there were 23.
- Conflicts with existing mechanics, not resolved here (DESIGN.md section 10): `Relations.harmed`'s instant spread to
  kin and friends (Q07), CRT-12's fixed notoriety and regard thresholds (Q14), CRT-06's friendly guard waiving a fine
  (Q08), and regard serving as both trust and harm (Q06).
- Gossip's frame cost (DESIGN.md sections 7 and 14): at 500 people at the live rate, 99 frames in 100 fit the phone
  budget on the 4x assumption (1.05 ms here). The rarest frames do not: 1 in 1000 reaches 1.81 ms here (about 7 ms on
  the phone), and the worst frame is a dependency flush of up to 107 tellings (about 6 ms here, 25 ms on the phone).
  Reads now skip flushes that cannot change what they read, but a needed flush stays whole: keeping the result
  identical requires that. The scheduled option halves those frames (1.25 ms) but changes when word passes, so it is a choice for
  the lead or the owner. A device check should decide.
- The daily update's worst single hour at 500 people varies with machine load (1.09 to 4.54 ms across runs; median day
  0.55 ms); a device check decides whether `dawn_slice` must run every frame. 2000 people is over the budget.
- Event feeds: wired in round 8 (DESIGN.md section 9.3); `self_defence`, `hoard_in_famine`, `false_accusation`, `meeting`, legal facts and ordinary market sales have no source (listed there).
- `Relations.harmed` already spreads harm to the player instantly to kin and friends: with judgment live there would be
  two channels for the same harm until the owner decides (SJD-Q07) whether word of mouth replaces it.
- CRT-12's notoriety threshold remains the live courtship refusal (recorded conflict, EXP-C).
- Villagers' crimes have no record (DVW-B2): only attacks are published for them, so judgments of villagers are thin.
- INT entries in `docs/SYSTEM_INTERACTION_MANIFEST.md` are deferred to reconciliation (ids would collide).
- With judgment on, `trade_choices` adds a candidate scan per sale (32,864 weighed choices in 10 village days); its
  time cost on the live simulation is not yet measured.

## Outstanding owner decisions

- **Answered 2026-10-21:** Q01, Q02, Q06, Q07, Q08, Q10, Q11, Q14 (see above).
- **Answered 2026-10-23 and applied (round 5):** Q05 (prior bias removed), Q09 (near-best, runner_up 150 proposed), X19-ASSAULT (assault permanent); Q04, Q12, X19-HARMED, X19-CRT12 already matched; X19-GUARD applied in `World.guard_confront` (friend guard halves the fine, never waives; round 6). Q03 and Q13 (own tolerance, shaped weights) wired in round 7 (DESIGN section 15c; numbers agent-proposed); X19-DECAY is the lead's next task; X19-REGARD done in round 6 (separate trust value in the store, DESIGN section 15b).
- **Answered 2026-10-23:** X19-Q-TIMING (spread by contact and closeness): "scheduled" timing with closeness weighting is
  implemented; the floor 500 is an agent-proposed number for owner review. Options record: `docs/expansion19/GOSSIP_TIMING_PROPOSAL.md`.
- **Needed from the owner before live integration (Gate E):**
  - the Q02 decay rate;
  - the four conflicts in DESIGN.md section 10 (instant harm spread, CRT-12 thresholds, CRT-06 friendly guard, and
    whether `permanent_personal_severity` should include being assaulted).
- None of these blocks further prospective work on this branch.

## Integration-readiness (from tests actually run)

- Gates SJD-C (isolated prototype) and SJD-D (decision prototype): implemented and tested in isolation.
- Gate SJD-E (first gated integration): a feature-flagged prototype exists and is proven behaviour-neutral when off
  (suites and determinism gate) and conserving and reproducible when on (10-day simulation, one-day double run). Not
  ready to enable: it needs the owner's answers above, the Build 18 reconciliation, calibration runs (100- and 365-day
  matched seeds, judgment off vs on), device performance checks, and INT entries.
- Gates F to H: not started.

## Round 7: SJD-Q03 and SJD-Q13 (personality)

Tolerance per person scales the rival and share NET thresholds; decision weights vary per person (trait spread 300);
firsthand life events shift tolerance (victims) and the disposition weight (the helped), bounded and saved in the
judgment section as `life`. Design and numbers: DESIGN.md section 15c. No personality system exists in the game, so
temperament is a seed-and-id hash. Everything stays behind `enabled: false`.
