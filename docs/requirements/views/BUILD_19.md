# Build 19: NPC Judgment

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: PROS-01: prospective work on wip/expansion19-preparation only, isolated until Build 18 is complete

Readiness: **PROTOTYPE ONLY (isolated branch; not integrated)**

| Count | Value |
|---|---|
| Approved requirements in scope | 13 |
| Integrated | 0 of 13 (0%) |
| Automated tests passed | 4 of 13 (31%) |
| Integration verified | 0 of 13 (0%) |
| Gameplay verified | 0 of 13 (0%) |
| Owner playtested | 0 of 13 (0%) |
| Complete | 0 of 13 (0%) |
| Open (release blockers) | 13 |
| Open owner decisions (blocking) | 2 (0) |

## Ready to proceed now (approved, specified, nothing open blocks it) (1)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| DVW-B1 | Villager relationships, memory of favours/gifts/harms, gossip | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED | harms lower regard; gossip spreads deeds |  | M |

## Blocked (open owner decision, unfinished dependency or unsettled design) (12)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| DVW-B2 | Assault and killing as recorded, fined crimes; heir inheritance of fines/stain | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | L |
| FR-11 | Personality, prestige and migration (owner's living-society list, 2026-10-17) | OWNER DECISION REQUIRED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | DVW-B1, design: UNKNOWN | L |
| SJD-B | Judgment expansion Gate B: architecture audit (Godot services, relationships, economic decisions, event hooks, save format, risks) and integration map with open questions | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | wip/expansion19-preparation | TARGETED TESTS PASSED |  | SJD-A | XS |
| SJD-C | Judgment expansion Gate C: isolated prototype (event catalog, beliefs, signed interpretation, GOOD/BAD ledger, tests), no effect on live behaviour | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | wip/expansion19-preparation | TARGETED TESTS PASSED |  | SJD-B | M |
| SJD-D | Judgment expansion Gate D: decision prototype (factor registry, utility profiles, the 50-iron scenario, explanation traces, determinism) | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | wip/expansion19-preparation | TARGETED TESTS PASSED |  | SJD-C | M |
| SJD-E | Judgment expansion Gate E: first gated integration in one low-risk domain, feature flag off by default, matched-seed tests | OWNER APPROVED | PARTIALLY IMPLEMENTED | wip/expansion19-preparation | TARGETED TESTS PASSED | rework for the owner's answers of 2026-10-23: SJD-Q05 no prior-opinion bias in interpretation; X19-REGARD trust separate from liking (new structure); X19-Q-TIMING gossip passed at each meeting by contact and closeness (the prototype batches by the hour); X19-ASSAULT assault permanent; X19-HARMED keep the instant harm to kin; X19-CRT12 keep the courtship cut-offs; X19-GUARD a friendly guard reduces, never waives, a fine; synchronize with the finished Build 18 (the branch is on Build 17 cd7439c) | SJD-D | L |
| SJD-F | Judgment expansion Gate F: incremental rollout (trade, aid, friendship, courtship, employment, crime, politics) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | SJD-E | XL |
| SJD-G | Judgment expansion Gate G: full soak and calibration: 100/365-day comparisons, performance and save migration | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | X19-DECAY, SJD-F | L |
| SJD-H | Judgment expansion Gate H: owner review; release and broad enablement approved separately | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | SJD-G | XS |
| WDR-009-C | Comply with World Design Rule 9: Emergent Gameplay | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED | GM-01 | design: UNKNOWN | UNKNOWN |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | OWNER APPROVED | NOT STARTED | none | NOT TESTED | Build 19, designed with the personality, judgment and decision systems (B18-DP-07); no Build 18 model | design: DESIGN WORK REQUIRED | L |

## Open owner decisions (2)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
| X19-DECAY | Judgment decay rate for ordinary contributions (proposed 3 permille a day, half-life 231 days; demonstrated 1-10 permille over 365 days; murder never decays) | PROVISIONAL | no | SJD-G |
| X19-GOSSIP-FLOOR | Gossip closeness (X19-Q-TIMING): a story passes between strangers with the agent-proposed chance gossip.closeness_floor_permille = 500 (half the time), rising to certain between the closest friends. Keep 500, or another value? | OPEN | no |  |

## Not counted: umbrellas, proposals, ideas, deferred (4)

| ID | Item | Kind | Approval |
|---|---|---|---|
| B17F-PERF | Build 17 finding: long-run performance analysis (seed 2 took 118 min against 66-93) | idea | PROPOSED |
| EXP-C | Expansion C: NPC Judgment System (Subjective Judgment & Universal Decision Engine; independent future expansion after a stable Build 16 baseline) | umbrella | OWNER APPROVED |
| FR-09 | Crime from desperation | approved | DEFERRED |
| PROS-19 | Expansion 19 prospective implementation (personal memory, subjective judgment, signed opinions, decision weighting that influences not dictates, provenance and sharing, persistence and migration prototypes, determinism and large-population performance tests) | umbrella | OWNER APPROVED |

