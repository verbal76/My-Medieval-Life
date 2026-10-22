# Build 19: NPC Judgment

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: PROS-01: prospective work on wip/expansion19-preparation only, isolated until Build 18 is complete

Readiness: **PROTOTYPE ONLY (isolated branch; not integrated)**

| Count | Value |
|---|---|
| Approved requirements in scope | 12 |
| Integrated | 0 of 12 (0%) |
| Automated tests passed | 4 of 12 (33%) |
| Integration verified | 0 of 12 (0%) |
| Gameplay verified | 0 of 12 (0%) |
| Owner playtested | 0 of 12 (0%) |
| Complete | 0 of 12 (0%) |
| Open (release blockers) | 12 |
| Open owner decisions (blocking) | 1 (0) |

## Open, partially implemented (3)

| ID | Requirement | Design | Effort | Verification | Worker / branch | Remaining work | Decisions / depends on |
|---|---|---|---|---|---|---|---|
| DVW-B1 | Villager relationships, memory of favours/gifts/harms, gossip | PARTIAL | M | NOT TESTED |  | harms lower regard; gossip spreads deeds |  |
| SJD-E | Judgment expansion Gate E: first gated integration in one low-risk domain, feature flag off by default, matched-seed tests | SPECIFIED | L | TARGETED TESTS PASSED | wip/expansion19-preparation | rework for the owner's answers of 2026-10-23: SJD-Q05 no prior-opinion bias in interpretation; X19-REGARD trust separate from liking (new structure); X19-Q-TIMING gossip passed at each meeting by contact and closeness (the prototype batches by the hour); X19-ASSAULT assault permanent; X19-HARMED keep the instant harm to kin; X19-CRT12 keep the courtship cut-offs; X19-GUARD a friendly guard reduces, never waives, a fine; synchronize with the finished Build 18 (the branch is on Build 17 cd7439c) | after SJD-D |
| WDR-009-C | Comply with World Design Rule 9: Emergent Gameplay | UNKNOWN | UNKNOWN | NOT TESTED |  | GM-01 |  |

## Open, implemented on task branch (3)

| ID | Requirement | Design | Effort | Verification | Worker / branch | Remaining work | Decisions / depends on |
|---|---|---|---|---|---|---|---|
| SJD-B | Judgment expansion Gate B: architecture audit (Godot services, relationships, economic decisions, event hooks, save format, risks) and integration map with open questions | SPECIFIED | XS | TARGETED TESTS PASSED | wip/expansion19-preparation |  | after SJD-A |
| SJD-C | Judgment expansion Gate C: isolated prototype (event catalog, beliefs, signed interpretation, GOOD/BAD ledger, tests), no effect on live behaviour | SPECIFIED | M | TARGETED TESTS PASSED | wip/expansion19-preparation |  | after SJD-B |
| SJD-D | Judgment expansion Gate D: decision prototype (factor registry, utility profiles, the 50-iron scenario, explanation traces, determinism) | SPECIFIED | M | TARGETED TESTS PASSED | wip/expansion19-preparation |  | after SJD-C |

## Open, not started (6)

| ID | Requirement | Design | Effort | Verification | Worker / branch | Remaining work | Decisions / depends on |
|---|---|---|---|---|---|---|---|
| DVW-B2 | Assault and killing as recorded, fined crimes; heir inheritance of fines/stain | UNKNOWN | L | NOT TESTED |  |  |  |
| FR-11 | Personality, prestige and migration (owner's living-society list, 2026-10-17) | UNKNOWN | UNKNOWN | NOT TESTED |  |  |  |
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | UNKNOWN | L | NOT TESTED |  |  | after DVW-B1 |
| SJD-F | Judgment expansion Gate F: incremental rollout (trade, aid, friendship, courtship, employment, crime, politics) | SPECIFIED | XL | NOT TESTED |  |  | after SJD-E |
| SJD-G | Judgment expansion Gate G: full soak and calibration: 100/365-day comparisons, performance and save migration | PARTIAL | L | NOT TESTED |  |  | X19-DECAY, after SJD-F |
| SJD-H | Judgment expansion Gate H: owner review; release and broad enablement approved separately | SPECIFIED | XS | NOT TESTED |  |  | after SJD-G |

## Open owner decisions (1)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
| X19-DECAY | Judgment decay rate for ordinary contributions (proposed 3 permille a day, half-life 231 days; demonstrated 1-10 permille over 365 days; murder never decays) | PROVISIONAL | no | SJD-G |

## Not counted: umbrellas, proposals, ideas, deferred (4)

| ID | Item | Kind | Approval |
|---|---|---|---|
| B17F-PERF | Build 17 finding: long-run performance analysis (seed 2 took 118 min against 66-93) | idea | PROPOSED |
| EXP-C | Expansion C: NPC Judgment System (Subjective Judgment & Universal Decision Engine; independent future expansion after a stable Build 16 baseline) | umbrella | OWNER APPROVED |
| FR-09 | Crime from desperation | approved | DEFERRED |
| PROS-19 | Expansion 19 prospective implementation (personal memory, subjective judgment, signed opinions, decision weighting that influences not dictates, provenance and sharing, persistence and migration prototypes, determinism and large-population performance tests) | umbrella | OWNER APPROVED |

