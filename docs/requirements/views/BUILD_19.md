# Build 19: NPC Judgment

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: X19-SCOPE; owner 2026-10-24: Build 19 complete and accepted as the development baseline; the owner's playtest is not a prerequisite

Readiness: **RELEASED (private playtest draft (code 2f72ec3, run 40044931601, 2026-10-24); complete as the development milestone (owner 2026-10-24))**

| Count | Value |
|---|---|
| Approved requirements in scope | 11 |
| Integrated | 10 of 11 (91%) |
| Automated tests passed | 10 of 11 (91%) |
| Integration verified | 9 of 11 (82%) |
| Gameplay verified | 0 of 11 (0%) |
| Owner playtested | 0 of 11 (0%) |
| Complete | 9 of 11 (82%) |
| Open (release blockers) | 2 |
| Open owner decisions (blocking) | 2 (0) |

## Integrated, awaiting gameplay or owner verification (1)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| FAM-SAC-01 | Family sacrifice and responsibility: the father figure puts children, then spouse, then parents before himself, giving up food, comfort, wealth, time and reasonable safety in hardship, without suicidal choices that would leave the family worse off; through the existing household, needs, personality and decision code; factors recorded through XEXPL-01 and the flight recorder | OWNER APPROVED | INTEGRATED | Build 19 wip/build19 2f72ec3; Expansion 20 wip/expansion20 0b5287c | TARGETED TESTS PASSED | recorder D5: family_trace and judgment factors recorded (batch R3) |  | verification only |

## Blocked (open owner decision, unfinished dependency or unsettled design) (1)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| FR-11 | Personality, prestige and migration (owner's living-society list, 2026-10-17) | OWNER DECISION REQUIRED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |

## Complete (9)

| ID | Requirement | Verification | Release |
|---|---|---|---|
| FIX-D3 | Friendly-guard fine rule behind the judgment switch: Build 18 behaviour exactly with judgment off; halve, never waive, with judgment on | INTEGRATION VERIFIED | NOT READY |
| FIX-RECF1 | Fix the unsold-goods re-decision loop (REC-F1): find the actual cause and correct the condition that makes villagers reconsider an unavailable action hundreds of times; no arbitrary cooldown; autonomy, economy and prompt reaction preserved; isolated from other systems | INTEGRATION VERIFIED | NOT READY |
| SJD-B | Judgment expansion Gate B: architecture audit (Godot services, relationships, economic decisions, event hooks, save format, risks) and integration map with open questions | INTEGRATION VERIFIED | NOT READY |
| SJD-C | Judgment expansion Gate C: isolated prototype (event catalog, beliefs, signed interpretation, GOOD/BAD ledger, tests), no effect on live behaviour | INTEGRATION VERIFIED | NOT READY |
| SJD-D | Judgment expansion Gate D: decision prototype (factor registry, utility profiles, the 50-iron scenario, explanation traces, determinism) | INTEGRATION VERIFIED | NOT READY |
| X19-FOUND-BONDS | Relationship history and reconciliation: resentment softens with growth, neutrality restores neither friendship nor trust, familiarity gives about 10% more friendship progression to former friends (non-stacking, suspended by negative standing), trust recovers only by reliability; serious grievances last at least about one game year | INTEGRATION VERIFIED | NOT READY |
| X19-FOUND-FAMREP | Family reputation: known family history colours descendants' impressions, positive reputation about 5% more friendship progression (about 12% combined with familiarity, not 15%), familiarity not inherited, personal experience overrides inherited impressions, small spillover of wrongdoing onto relatives without inheriting the wrongdoing, trust stays individual | INTEGRATION VERIFIED | NOT READY |
| X19-FOUND-PERS | Personality framework: evolving traits, soft limits, learning from costly mistakes, practical wisdom, temporary emotions and anger, recovery and growth; about 30% of villagers with potential for self-defeating stubbornness (population level) | INTEGRATION VERIFIED | NOT READY |
| X19-SCOPE | Expansion 19 ships complete: judgment, personality, relationships, family reputation, gossip, memory, deliberate lies, inherited family stories, stubbornness and the family-sacrifice hierarchy all enabled and influencing NPC decisions; nothing core deferred to 19.x | INTEGRATION VERIFIED | RELEASE CANDIDATE |

## Open owner decisions (2)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
| SIM-F2 | Recorder finding F2: a stonecutter re-chose a failing iron-chisel purchase 328 times in one day (day 2, seed 1), losing a working day; same re-decision family as REC-F1. Approve a narrow fix? | OPEN | no |  |
| SIM-F3 | Recorder finding F3: bandits stalking at night leave their plan empty, so the brain re-decides every tick (400+ empty decisions a day each); behaviour works through the chase target. Approve giving the stalk a lasting plan step (performance fix, no behaviour change intended)? | OPEN | no |  |

## Not counted: umbrellas, proposals, ideas, deferred (5)

| ID | Item | Kind | Approval |
|---|---|---|---|
| B17F-PERF | Build 17 finding: long-run performance analysis (seed 2 took 118 min against 66-93) | idea | PROPOSED |
| E20-RISK-QUEUES | Unbounded growth and population-wide scans found in Build 18 economic code: NPCBrain.miss_log never cleared; courier jobs, agreements and contacts never pruned; credit._villager_deals O(n^2) at dawn; the heir-removal id reuse (life.gd:660) | proposal | PROPOSED |
| EXP-C | Expansion C: NPC Judgment System (Subjective Judgment & Universal Decision Engine; independent future expansion after a stable Build 16 baseline) | umbrella | OWNER APPROVED |
| FR-09 | Crime from desperation | approved | DEFERRED |
| REC-F1 | Recorder finding (10-day run, seed 1): villagers holding goods nobody buys ('holding unsold pottage, log, stone, feathers') re-decide every few game minutes without acting (400-600 decisions a day each against 4-19 actions by day 9), tripling decision volume as unsold stock grows. Existing Build 18 behaviour; not changed. | proposal | PROPOSED |

