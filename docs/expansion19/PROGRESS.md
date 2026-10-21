# Expansion 19 prospective development: progress

Reporting fields from the owner directive `docs/directives/2026-10-21_parallel_prospective_development_18_19.md`
(PROS-01, PROS-19). Design, decisions and the owner-question table: `docs/expansion19/DESIGN.md`. Nothing here is
integrated gameplay: everything is off in the game, nothing is merged into staging, no build is made.

Updated 2026-10-21 (round 3: word of mouth spread over frames).

## Branch and latest pushed commit

`wip/expansion19-preparation`, branched from staging `b721616` (Build 16 released, plus records). Round 1: `3005d6f`
(isolated prototype), `221ac6f` (live adapter, off), `efbd31c` (performance suite, documents), `e05d367`. Round 2: `ff19cb2`, `693e0c3`
(compact records, sliced daily update, trade-hook shortcut, measurements). Round 3: the commits that add this update
(gossip queue, cheaper telling, the scheduled option, measurements). The pushed head is the branch head on GitHub.

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
| Round 3: word of mouth queued and told a few a tick; reads first tell the meetings they depend on | `JudgmentStore.meet_hourly/meet_later/gossip_tick/_flush_for` | `judgment_test.gd` (129 in all): same tellings, every read along the way, beliefs and end state as telling at once (also with retraction, a fading view and rumours), and the test fails if the flush is removed; perf: spread = told at once = round 2's end state at every size and rate; at 500 people live, frame p99 1.03 -> 0.87 ms and p99.9 5.66 -> 2.15 ms |
| Round 3: cheaper telling (cached settings, no formatting, packed sort, "nothing new" shortcut) | `JudgmentStore.tell/interpret/evaluate/_post` | results unchanged (same state hashes as round 2 at every size and rate) |
| Round 3 option: scheduled timing (off) | `gossip.timing` "scheduled" | `test_scheduled_gossip`: told at its own minute, never before, kept in a save, deterministic; frames p99 0.62 / p99.9 1.25 ms at 500 people live; results differ by design |
| Round 2: trade-hook shortcut | `JudgmentLive._first_stands` | `judgment_live_test.gd` (27): picks exactly as the full scan over twelve opinion mixes; economy_sim 10 days seed 1: about +20% wall time before, about +5% after, no leaks, same fingerprint |

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
- Gossip's frame cost (DESIGN.md section 7, round 3): at 500 people at the live rate, 99 frames in 100 now fit the
  phone budget on the 4x assumption (0.87 ms here). The rarest frames do not: 1 in 1000 reaches 2.15 ms here (about
  8.6 ms on the phone), when a read must first tell a long chain of queued meetings. Keeping the result identical
  requires that. The scheduled option halves those frames (1.25 ms) but changes when word passes, so it is a choice for
  the lead or the owner. A device check should decide.
- The daily update's worst single hour at 500 people varies with machine load (1.09 to 4.54 ms across runs; median day
  0.55 ms); a device check decides whether `dawn_slice` must run every frame. 2000 people is over the budget.
- Missing event feeds (DESIGN.md section 7): help, gifts, rescue, fair and cheating trade, villagers' thefts and
  killings, discovered thefts, legal facts, neutral facts. Listed only; wiring them changes live behaviour when on.
- `Relations.harmed` already spreads harm to the player instantly to kin and friends: with judgment live there would be
  two channels for the same harm until the owner decides (SJD-Q07) whether word of mouth replaces it.
- CRT-12's notoriety threshold remains the live courtship refusal (recorded conflict, EXP-C).
- Villagers' crimes have no record (DVW-B2): only attacks are published for them, so judgments of villagers are thin.
- INT entries in `docs/SYSTEM_INTERACTION_MANIFEST.md` are deferred to reconciliation (ids would collide).
- With judgment on, `trade_choices` adds a candidate scan per sale (32,864 weighed choices in 10 village days); its
  time cost on the live simulation is not yet measured.

## Outstanding owner decisions

All fourteen remain open. Blocking live integration (per DESIGN.md section 5 and the roadmap reconciliation): SJD-Q01
(NEUTRAL events), Q02 (decay), Q06 (confidence and rumour), Q07 (replacing today's instant harm spread), Q08 (law,
morality, loyalty), Q10 (what the player sees), Q11 (persistence by severity), Q14 (first live domain). Tunable, with
provisional values in data: Q03, Q04, Q05, Q09, Q12, Q13 (unless run-time learning is wanted). Also Q19-0 (whether the
TUNABLE/OWNER split is accepted).

## Integration-readiness (from tests actually run)

- Gates SJD-C (isolated prototype) and SJD-D (decision prototype): implemented and tested in isolation.
- Gate SJD-E (first gated integration): a feature-flagged prototype exists and is proven behaviour-neutral when off
  (suites and determinism gate) and conserving and reproducible when on (10-day simulation, one-day double run). Not
  ready to enable: it needs the owner's answers above, the Build 18 reconciliation, calibration runs (100- and 365-day
  matched seeds, judgment off vs on), device performance checks, and INT entries.
- Gates F to H: not started.
