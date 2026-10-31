# Build 21: Village Politics

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: owner 2026-10-23 (docs/directives/2026-10-23_expansion21_phase1_authorization.md): phase 1 only (P21-00, P21-01, P21-02) on wip/expansion21-preparation, done, behaviour disabled; ON HOLD (owner 2026-10-27 X20-COMPLETE; 2026-10-28 'Do not start Expansion 21'; 2026-10-30 'Keep Expansion 21 politics isolated and on hold'); next phase Build 27 only after Build 26 is frozen and the owner explicitly authorizes (BUILD-SEQ-25-27, 2026-10-31). implementation_authorized true covers phase 1 only.

Readiness: **IN DEVELOPMENT (not feature complete)**

| Count | Value |
|---|---|
| Approved requirements in scope | 5 |
| Integrated | 1 of 5 (20%) |
| Automated tests passed | 2 of 5 (40%) |
| Integration verified | 1 of 5 (20%) |
| Gameplay verified | 0 of 5 (0%) |
| Owner playtested | 0 of 5 (0%) |
| Complete | 0 of 5 (0%) |
| Open (release blockers) | 5 |
| Open owner decisions (blocking) | 0 (0) |

## Integrated, awaiting gameplay or owner verification (1)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| ANDROID-RELEASE-SIGNING | Android builds signed with the permanent release identity from the four ANDROID_RELEASE_* secrets, no fallback | OWNER APPROVED | INTEGRATED | Build 21 wip/multiplayer-b19 6567c04 | INTEGRATION VERIFIED |  |  | verification only |

## Blocked (open owner decision, unfinished dependency or unsettled design) (4)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| P21-00 | Expansion 21 phase 1: government architecture audit (what exists, works, is incomplete or absent, by civic system) | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | lead / wip/expansion21-preparation | NOT TESTED | ON HOLD (owner 2026-10-27/28/30); stranded on wip/expansion21-preparation (base Build 18 239bdff, not in wip/expansion20); bring forward with the civic switch off in Build 26 recovery or Build 27 (owner to say which); owner review of the document(s) at Build 27 | design: UNKNOWN | UNKNOWN |
| P21-01 | Expansion 21 phase 1: isolated civic foundations (office ids, holders and tenure, jurisdiction, eligibility and authority metadata, succession events, treasury attribution, duty records, legacy records), all behaviour disabled | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | X21 foundation worker (Sonnet subagent) / wip/expansion21-preparation | TARGETED TESTS PASSED | ON HOLD (owner 2026-10-27/28/30); stranded on wip/expansion21-preparation (base Build 18 239bdff, not in wip/expansion20); bring forward with the civic switch off in Build 26 recovery or Build 27 (owner to say which); owner review of the document(s) at Build 27 | design: UNKNOWN | UNKNOWN |
| P21-02 | Expansion 21 phase 1: political decision architecture map (owner system, information needed, open owner choices per decision) and the grouped 12-topic owner decision packet | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | lead / wip/expansion21-preparation | NOT TESTED | ON HOLD (owner 2026-10-27/28/30); stranded on wip/expansion21-preparation (base Build 18 239bdff, not in wip/expansion20); bring forward with the civic switch off in Build 26 recovery or Build 27 (owner to say which); owner review of the document(s) at Build 27 | design: UNKNOWN | UNKNOWN |
| P21-MAYOR | Elected mayor: elected by established adult residents who are also eligible to stand; four-game-year terms; incumbents may stand again; an early vacancy calls a replacement election as soon as possible, the longest-serving eligible civic official holding authority meanwhile; voters judge candidates individually by policies, competence, interests, trust, relationships, family and their own priorities | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |

## Not counted: umbrellas, proposals, ideas, deferred (6)

| ID | Item | Kind | Approval |
|---|---|---|---|
| VP-01 | Living village politics: offices, individual NPC voting, elections, civic authority | umbrella | OWNER APPROVED |
| VP-01A | Village politics stage: Audit of the reeve, guard pay and succession decision points | proposal | PROPOSED |
| VP-01B | Village politics stage: Offices and civic work | proposal | PROPOSED |
| VP-01C | Village politics stage: Voting and the election lifecycle | proposal | PROPOSED |
| VP-01D | Village politics stage: Political consequences in village life | proposal | PROPOSED |
| VP-01E | Village politics stage: Soak, calibration and owner review | proposal | PROPOSED |

