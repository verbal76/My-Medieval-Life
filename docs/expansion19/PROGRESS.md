# Expansion 19 prospective development: progress

Reporting fields from the owner directive `docs/directives/2026-10-21_parallel_prospective_development_18_19.md`
(PROS-01, PROS-19). Design, decisions and the owner-question table: `docs/expansion19/DESIGN.md`. Nothing here is
integrated gameplay: everything is off in the game, nothing is merged into staging, no build is made.

Updated 2026-10-21.

## Branch and latest pushed commit

`wip/expansion19-preparation`, branched from staging `b721616` (Build 16 released, plus records). Commits:
`3005d6f` (isolated prototype), `221ac6f` (live adapter, off), and the commit that adds this file (performance suite,
CI listing, documents); the pushed head is the branch head on GitHub.

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
| Large-population performance | `judgment_perf.gd` | 10 checks at 100 / 500 / 2000 people (memory bound, facts within horizon, save round trip, determinism); figures and proposed budgets in DESIGN.md section 7 |

Regression evidence for the hooks (judgment off), run on this branch before pushing `221ac6f`: `run_tests` 3535,
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
- Memory and dawn cost at the stress rate (DESIGN.md section 7): 2000 people use 232 MB and a 123 ms dawn; the budgets
  need the dawn spread over hours and leaner memory records before large populations.
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
