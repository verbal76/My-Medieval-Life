# Build 22: Settlement Advancement Phase 2

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): audit and architecture only (E22-P1, done); 'Do not begin implementation until we review the audit and approve the architecture'; 2026-10-30 'Do not begin Expansions 22–27'. implementation_authorized true covers the audit record only; no phase is authorized.

Readiness: **IN DEVELOPMENT (not feature complete)**

| Count | Value |
|---|---|
| Approved requirements in scope | 9 |
| Integrated | 0 of 9 (0%) |
| Automated tests passed | 0 of 9 (0%) |
| Integration verified | 0 of 9 (0%) |
| Gameplay verified | 0 of 9 (0%) |
| Owner playtested | 0 of 9 (0%) |
| Complete | 0 of 9 (0%) |
| Open (release blockers) | 9 |
| Open owner decisions (blocking) | 0 (0) |

## Blocked (open owner decision, unfinished dependency or unsettled design) (9)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| E22-A | Expansion 22 Phase A, architecture and regional ledger: one regional ledger view over the village and settlements; no duplicate ledgers or parallel NPC simulation | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-B | Expansion 22 Phase B, settlement capability model: capabilities from workers, tools, buildings, resources and knowledge transfer; unapproved formulas and thresholds left unresolved | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-C | Expansion 22 Phase C, abstract regional settlements: conserved economic state; promote and demote with identity, property and history kept (E22-OD-01) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-CONDITION | Expansion 22 owns the one shared building-condition, damage, deterioration and repair system; Expansion 25 reuses it for weather and disaster effects (one extensible system, no separate damage models) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-D | Expansion 22 Phase D, settlement development: dwellings, infrastructure, abandonment off-map; the shared building-condition system (E22-CONDITION) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-E | Expansion 22 Phase E, persistent regional networks on real routes (E22-OD-02), including travel-time route banditry on Expansion 23's faction records (ROAD-Q2) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-OD-01 | Hybrid regional simulation: detailed nearby NPCs and abstract distant settlements that preserve individual identities, households, property, economic state and history | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-OD-02 | Continuous geography: streamed regions, persistent world coordinates, persistent player and NPC modifications | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| E22-P1 | Expansion 22 phase 1: read-only audit of the Settlement Advancement specification against Build 18 (complete, partial, missing), Phases A-E dependency map, capability matrix, regional data model proposal, player views and diagnostics plan; no implementation | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | lead / staging/my-medieval-life | NOT TESTED | owner reviews the audit and approves the architecture | design: UNKNOWN | UNKNOWN |

## Not counted: umbrellas, proposals, ideas, deferred (1)

| ID | Item | Kind | Approval |
|---|---|---|---|
| EXP-22 | Expansion 22, Settlement Advancement Phase 2: a region of independent settlements that grow, stagnate, decline or disappear through simulated causes, building on Build 18 without rebuilding it (phases A-E) | umbrella | OWNER APPROVED |

