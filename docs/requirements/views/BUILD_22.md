# Build 22: Settlement Advancement Phase 2

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): read-only audit and architecture only; no implementation until the owner reviews the audit and approves the architecture; builds on Build 18's settlement systems, never duplicating them

Readiness: **IN DEVELOPMENT (not feature complete)**

| Count | Value |
|---|---|
| Approved requirements in scope | 4 |
| Integrated | 0 of 4 (0%) |
| Automated tests passed | 0 of 4 (0%) |
| Integration verified | 0 of 4 (0%) |
| Gameplay verified | 0 of 4 (0%) |
| Owner playtested | 0 of 4 (0%) |
| Complete | 0 of 4 (0%) |
| Open (release blockers) | 4 |
| Open owner decisions (blocking) | 0 (0) |

## Blocked (open owner decision, unfinished dependency or unsettled design) (4)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| E22-CONDITION | Expansion 22 owns the one shared building-condition, damage, deterioration and repair system; Expansion 25 reuses it for weather and disaster effects (one extensible system, no separate damage models) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-OD-01 | Hybrid regional simulation: detailed nearby NPCs and abstract distant settlements that preserve individual identities, households, property, economic state and history | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-OD-02 | Continuous geography: streamed regions, persistent world coordinates, persistent player and NPC modifications | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-P1 | Expansion 22 phase 1: read-only audit of the Settlement Advancement specification against Build 18 (complete, partial, missing), Phases A-E dependency map, capability matrix, regional data model proposal, player views and diagnostics plan; no implementation | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | lead / staging/my-medieval-life | NOT TESTED | owner reviews the audit and approves the architecture | design: UNKNOWN | UNKNOWN |

