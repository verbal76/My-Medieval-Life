# Build 19: NPC Judgment

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: PROS-01: prospective work on wip/expansion19-preparation only, isolated until Build 18 is complete

Readiness: **PROTOTYPE ONLY (isolated branch; not integrated)**

| Count | Value |
|---|---|
| Approved requirements in scope | 26 |
| Integrated | 0 of 26 (0%) |
| Automated tests passed | 12 of 26 (46%) |
| Integration verified | 0 of 26 (0%) |
| Gameplay verified | 0 of 26 (0%) |
| Owner playtested | 0 of 26 (0%) |
| Complete | 0 of 26 (0%) |
| Open (release blockers) | 26 |
| Open owner decisions (blocking) | 14 (0) |

## In development (worker assigned) (4)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| FAM-SAC-01 | Family sacrifice and responsibility: the father figure puts children, then spouse, then parents before himself, giving up food, comfort, wealth, time and reasonable safety in hardship, without suicidal choices that would leave the family worse off; through the existing household, needs, personality and decision code; factors recorded through XEXPL-01 and the flight recorder | OWNER APPROVED | IN DEVELOPMENT | family worker (Sonnet subagent) / wip/expansion19-preparation | NOT TESTED | next Expansion 19 task when a worker slot frees (after FIX-RECF1 or the recorder D3): household food, spending, work and danger decisions through the existing household and judgment code; recorder factors | design: UNKNOWN | UNKNOWN |
| FIX-RECF1 | Fix the unsold-goods re-decision loop (REC-F1): find the actual cause and correct the condition that makes villagers reconsider an unavailable action hundreds of times; no arbitrary cooldown; autonomy, economy and prompt reaction preserved; isolated from other systems | OWNER APPROVED | IN DEVELOPMENT | lead / wip/fix-recf1 | TARGETED TESTS PASSED | SIM-F9 correction and before/after comparison; then integrate identity + wait-plan fixes and propose one combined baseline | design: UNKNOWN | UNKNOWN |
| REC-19 | Build 19 Simulation Flight Recorder: full-scope interaction, decision, state-change and causal recording of the whole active simulation (player-independent), invariant and anomaly checks, coverage audit, structured archive with Excel export on Android, Windows and Linux; recording on/off deterministic; developer layer of XEXPL-01 | OWNER APPROVED | IN DEVELOPMENT | recorder worker (Sonnet subagent) / wip/recorder | TARGETED TESTS PASSED | merge the verified identity foundation; then D3 systems (life, employment, government, crime, player, save) and D4 records | design: UNKNOWN | UNKNOWN |
| REC-DIAG | Use the flight recorder now for autonomous simulation analysis: progressively longer runs, analysis between runs, findings with evidence, causes and recommended corrections; defects told apart from emergent behaviour; instrumentation gaps reported; no unrelated fixes without the owner | OWNER APPROVED | IN DEVELOPMENT | lead / wip/recorder (read-only runs) | NOT TESTED | run 2 only: 30 days, seeds 1 and 2, on the recorder head with FIX-RECF1 and D3; stop at day 30, a FATAL line or the storage cap | design: UNKNOWN | UNKNOWN |

## Ready to proceed now (approved, specified, nothing open blocks it) (1)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| DVW-B1 | Villager relationships, memory of favours/gifts/harms, gossip | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED | harms lower regard; gossip spreads deeds |  | M |

## Blocked (open owner decision, unfinished dependency or unsettled design) (21)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| DVW-B2 | Assault and killing as recorded, fined crimes; heir inheritance of fines/stain | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | L |
| FIX-D1D2 | Saves never activate a disabled feature, and a disabled feature keeps its saved section untouched (D1 judgment, D2 economy), following the civic-records pattern | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | repair workers (Sonnet subagents) / wip/expansion19-preparation, wip/expansion20-preparation | TARGETED TESTS PASSED |  | design: UNKNOWN | UNKNOWN |
| FIX-D3 | Friendly-guard fine rule behind the judgment switch: Build 18 behaviour exactly with judgment off; halve, never waive, with judgment on | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | repair worker X19 (Sonnet subagent) / wip/expansion19-preparation | TARGETED TESTS PASSED |  | design: UNKNOWN | UNKNOWN |
| FR-11 | Personality, prestige and migration (owner's living-society list, 2026-10-17) | OWNER DECISION REQUIRED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | DVW-B1, design: UNKNOWN | L |
| REC-STORE | Recorder keeps every decision's alternatives and factors in full; no reduction, sampling or discarding; storage limit stops recording, keeps data, marks the session incomplete | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| SJD-B | Judgment expansion Gate B: architecture audit (Godot services, relationships, economic decisions, event hooks, save format, risks) and integration map with open questions | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | wip/expansion19-preparation | TARGETED TESTS PASSED |  | SJD-A | XS |
| SJD-C | Judgment expansion Gate C: isolated prototype (event catalog, beliefs, signed interpretation, GOOD/BAD ledger, tests), no effect on live behaviour | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | wip/expansion19-preparation | TARGETED TESTS PASSED |  | SJD-B | M |
| SJD-D | Judgment expansion Gate D: decision prototype (factor registry, utility profiles, the 50-iron scenario, explanation traces, determinism) | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | wip/expansion19-preparation | TARGETED TESTS PASSED |  | SJD-C | M |
| SJD-E | Judgment expansion Gate E: first gated integration in one low-risk domain, feature flag off by default, matched-seed tests | OWNER APPROVED | PARTIALLY IMPLEMENTED | wip/expansion19-preparation | TARGETED TESTS PASSED | rework for the owner's answers of 2026-10-23: SJD-Q05 no prior-opinion bias in interpretation; X19-REGARD trust separate from liking (new structure); X19-Q-TIMING gossip passed at each meeting by contact and closeness (the prototype batches by the hour); X19-ASSAULT assault permanent; X19-HARMED keep the instant harm to kin; X19-CRT12 keep the courtship cut-offs; X19-GUARD a friendly guard reduces, never waives, a fine; synchronize with the finished Build 18 (the branch is on Build 17 cd7439c) | SJD-D | L |
| SJD-F | Judgment expansion Gate F: incremental rollout (trade, aid, friendship, courtship, employment, crime, politics) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | SJD-E | XL |
| SJD-G | Judgment expansion Gate G: full soak and calibration: 100/365-day comparisons, performance and save migration | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | X19-DECAY, SJD-F | L |
| SJD-H | Judgment expansion Gate H: owner review; release and broad enablement approved separately | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | SJD-G | XS |
| WDR-009-C | Comply with World Design Rule 9: Emergent Gameplay | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED | GM-01 | design: UNKNOWN | UNKNOWN |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | OWNER APPROVED | NOT STARTED | none | NOT TESTED | Build 19, designed with the personality, judgment and decision systems (B18-DP-07); no Build 18 model | design: DESIGN WORK REQUIRED | L |
| X19-FOUND | Expansion 19 foundations round: personality, relationship history and family reputation (judgment off) | OWNER APPROVED | PARTIALLY IMPLEMENTED | lead (merges Workers A and B) / wip/expansion19-preparation | TARGETED TESTS PASSED | owner: X19-PERS-FORMULA, X19-TRAIT-DIST, X19-SPILL-REACH, X19-REP-TRANSMIT, X19-BOND-LIMITS; what counts as a costly mistake and a reminder; the decision effect of stubbornness | design: UNKNOWN | UNKNOWN |
| X19-FOUND-BONDS | Relationship history and reconciliation: resentment softens with growth, neutrality restores neither friendship nor trust, familiarity gives about 10% more friendship progression to former friends (non-stacking, suspended by negative standing), trust recovers only by reliability; serious grievances last at least about one game year | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | X19 Worker B bonds (Sonnet subagent) / wip/expansion19-preparation | TARGETED TESTS PASSED |  | design: UNKNOWN | UNKNOWN |
| X19-FOUND-FAMREP | Family reputation: known family history colours descendants' impressions, positive reputation about 5% more friendship progression (about 12% combined with familiarity, not 15%), familiarity not inherited, personal experience overrides inherited impressions, small spillover of wrongdoing onto relatives without inheriting the wrongdoing, trust stays individual | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | X19 Worker B bonds (Sonnet subagent) / wip/expansion19-preparation | TARGETED TESTS PASSED |  | design: UNKNOWN | UNKNOWN |
| X19-FOUND-PERS | Personality framework: evolving traits, soft limits, learning from costly mistakes, practical wisdom, temporary emotions and anger, recovery and growth; about 30% of villagers with potential for self-defeating stubbornness (population level) | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | X19 Worker A personality (Sonnet subagent) / wip/expansion19-preparation | TARGETED TESTS PASSED |  | design: UNKNOWN | UNKNOWN |
| X19-MISINFO | Deliberate misinformation and its correction: NPCs may fabricate false accusations; listeners weigh credibility; accusations can be investigated; a falsehood proven false immediately corrects the negative judgment it caused, independent grievances remain; deliberate dishonesty has consequences by intent, harm, repetition and relationships | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| X19-STORY-LIFE | Family stories: reputation extends through a recognized family name, observers judge family members by their own knowledge, family reputation recovers through positive conduct, important stories may survive generations, minor stories fade when no longer retold | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |

## Open owner decisions (14)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
| SIM-F2 | Recorder finding F2: a stonecutter re-chose a failing iron-chisel purchase 328 times in one day (day 2, seed 1), losing a working day; same re-decision family as REC-F1. Approve a narrow fix? | OPEN | no |  |
| SIM-F3 | Recorder finding F3: bandits stalking at night leave their plan empty, so the brain re-decides every tick (400+ empty decisions a day each); behaviour works through the chase target. Approve giving the stalk a lasting plan step (performance fix, no behaviour change intended)? | OPEN | no |  |
| SIM-F4 | Recorder finding F4: the whole bandit band died within nine days; a bandit's only food purchase (_bandit_market) needs 15 coins and at least 60% health, so an injured or starving bandit with money cannot buy food. Confirm with death causes first; then should the health gate stop blocking food purchases? | OPEN | no |  |
| X19-BOND-LIMITS | Do specific relationship or reputation effects need additional balancing limits? | OPEN | no |  |
| X19-DECAY | Judgment decay rate for ordinary contributions (proposed 3 permille a day, half-life 231 days; demonstrated 1-10 permille over 365 days; murder never decays) | PROVISIONAL | no | SJD-G |
| X19-EVENT-Q | Expansion 19 event feeds raised four questions: (1) should a guard killing an assailant count as a killing (today it does: the game cannot tell them apart)? (2) should first acquaintance be recorded as a meeting fact? (3) should a late repayment score as a fair deal? (4) self-defence cannot yet be told from an attack: add that distinction later? | OPEN | no |  |
| X19-GOSSIP-FLOOR | Gossip closeness (X19-Q-TIMING): a story passes between strangers with the agent-proposed chance gossip.closeness_floor_permille = 500 (half the time), rising to certain between the closest friends. Keep 500, or another value? | OPEN | no |  |
| X19-PERS-FORMULA | The numerical formulas for personality evolution (rates by frequency, severity and duration; soft limits; learning acceleration; emotion length; recovery) | OPEN | no |  |
| X19-PERSONALITY | Agent-proposed numbers for per-person temperament (SJD-Q03, Q13): tolerance and weights vary by up to 30% between people; being wronged lowers tolerance 4% per severity point, being helped raises regard for opinion 3% per point, at most 25% either way; a shift applies to all dealings, not only the kind of deed. Keep, or change? | OPEN | no |  |
| X19-REP-TRANSMIT | The numerical formulas for family reputation transmission (how stories, their significance and retelling set an inherited impression) | OPEN | no |  |
| X19-RUNNERUP | Near-best choices (SJD-Q09): the agent-proposed chance that a villager takes a close second instead of the best option is 150 permille (15%), only among options within 2 points of the best. Keep 15%, or another value? | OPEN | no |  |
| X19-SPILL-REACH | How far does reputation spillover reach through extended family (parents, children, siblings, cousins, in-laws)? | OPEN | no |  |
| X19-TRAIT-DIST | Population trait distributions and learning percentages beyond the approved 30% stubbornness potential | OPEN | no |  |
| X19-TRUST-RATES | Agent-proposed numbers for Expansion 19 awaiting the owner: trust starts at a quarter of liking (a stranger at 0); a fair deal +4 trust, a cheat or false accusation -20, a rumour borne out +4 for the teller, one shown false -15; trust does not fade; a friendly guard halves a theft fine (at least 1 coin). Keep, or change any? | OPEN | no |  |

## Not counted: umbrellas, proposals, ideas, deferred (6)

| ID | Item | Kind | Approval |
|---|---|---|---|
| B17F-PERF | Build 17 finding: long-run performance analysis (seed 2 took 118 min against 66-93) | idea | PROPOSED |
| E20-RISK-QUEUES | Unbounded growth and population-wide scans found in Build 18 economic code: NPCBrain.miss_log never cleared; courier jobs, agreements and contacts never pruned; credit._villager_deals O(n^2) at dawn; the heir-removal id reuse (life.gd:660) | proposal | PROPOSED |
| EXP-C | Expansion C: NPC Judgment System (Subjective Judgment & Universal Decision Engine; independent future expansion after a stable Build 16 baseline) | umbrella | OWNER APPROVED |
| FR-09 | Crime from desperation | approved | DEFERRED |
| PROS-19 | Expansion 19 prospective implementation (personal memory, subjective judgment, signed opinions, decision weighting that influences not dictates, provenance and sharing, persistence and migration prototypes, determinism and large-population performance tests) | umbrella | OWNER APPROVED |
| REC-F1 | Recorder finding (10-day run, seed 1): villagers holding goods nobody buys ('holding unsold pottage, log, stone, feathers') re-decide every few game minutes without acting (400-600 decisions a day each against 4-19 actions by day 9), tripling decision volume as unsold stock grows. Existing Build 18 behaviour; not changed. | proposal | PROPOSED |

