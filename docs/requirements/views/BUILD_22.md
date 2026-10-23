# Build 22: Settlement Advancement Phase 2

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): read-only audit and architecture only; no implementation until the owner reviews the audit and approves the architecture; builds on Build 18's settlement systems, never duplicating them

Readiness: **IN DEVELOPMENT (not feature complete)**

| Count | Value |
|---|---|
| Approved requirements in scope | 3 |
| Integrated | 0 of 3 (0%) |
| Automated tests passed | 0 of 3 (0%) |
| Integration verified | 0 of 3 (0%) |
| Gameplay verified | 0 of 3 (0%) |
| Owner playtested | 0 of 3 (0%) |
| Complete | 0 of 3 (0%) |
| Open (release blockers) | 3 |
| Open owner decisions (blocking) | 3 (0) |

## Blocked (open owner decision, unfinished dependency or unsettled design) (3)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| E22-OD-01 | Hybrid regional simulation: detailed nearby NPCs and abstract distant settlements that preserve individual identities, households, property, economic state and history | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-OD-02 | Continuous geography: streamed regions, persistent world coordinates, persistent player and NPC modifications | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-P1 | Expansion 22 phase 1: read-only audit of the Settlement Advancement specification against Build 18 (complete, partial, missing), Phases A-E dependency map, capability matrix, regional data model proposal, player views and diagnostics plan; no implementation | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | lead / staging/my-medieval-life | NOT TESTED | owner reviews the audit and approves the architecture | design: UNKNOWN | UNKNOWN |

## Open owner decisions (3)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
| E22-OD-03 | Knowledge persistence: how industrial knowledge passes on (teaching, apprenticeship, written records) or is lost when skilled people die or leave; Build 18 keeps it only in living people | OPEN | no |  |
| E22-OD-04 | Regional trade and transport: do traders' trips take real travel time, carry limited loads and risk loss on routes (replacing the instant six-day road trade), and do settlements trade with each other beyond the village | OPEN | no |  |
| E22-OD-05 | Population across the region: should off-map settlements get housing and land that limit growth (REG-DEMO-D1 left this to future systems), and may whole settlements be abandoned | OPEN | no |  |

