# Requirements status by build

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Definitions: `docs/requirements/SCHEMA.md`. Counted: approved, in-scope requirements of the build (umbrella entries, deferred, superseded and rejected records, proposals and ideas excluded). Integration, verification and completion are separate counts; none implies release readiness. Effort bands are the audit's estimates where recorded; UNKNOWN where not.

| Measure | Build 18 | Build 19 | Build 20 | Build 21 | Build 22 | Build 23 | Build 24 |
|---|---|---|---|---|---|---|---|
| Approved requirements (in scope) | 83 | 19 | 9 | 5 | 3 | 1 | 0 |
| Fully specified (design SPECIFIED) | 66 of 83 (80%) | 6 of 19 (32%) | 0 of 9 (0%) | 0 of 5 (0%) | 0 of 3 (0%) | 0 of 1 (0%) | 0 of 0 |
| Waiting on an owner decision (design) | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Design work still required | 2 | 3 | 0 | 0 | 0 | 0 | 0 |
| Design unknown | 15 | 10 | 9 | 5 | 3 | 1 | 0 |
| Not started (incl. READY) | 2 | 9 | 8 | 2 | 2 | 0 | 0 |
| In development (worker assigned) | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Partially implemented | 1 | 4 | 0 | 0 | 0 | 0 | 0 |
| Implemented on a task branch | 0 | 6 | 1 | 3 | 1 | 1 | 0 |
| Implementation blocked | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Integrated | 80 of 83 (96%) | 0 of 19 (0%) | 0 of 9 (0%) | 0 of 5 (0%) | 0 of 3 (0%) | 0 of 1 (0%) | 0 of 0 |
| Automated tests passed (targeted or better) | 78 of 83 (94%) | 8 of 19 (42%) | 1 of 9 (11%) | 1 of 5 (20%) | 0 of 3 (0%) | 0 of 1 (0%) | 0 of 0 |
| Integration verified (suite on the integrated build) | 58 of 83 (70%) | 0 of 19 (0%) | 0 of 9 (0%) | 0 of 5 (0%) | 0 of 3 (0%) | 0 of 1 (0%) | 0 of 0 |
| Gameplay verified | 0 of 83 (0%) | 0 of 19 (0%) | 0 of 9 (0%) | 0 of 5 (0%) | 0 of 3 (0%) | 0 of 1 (0%) | 0 of 0 |
| Owner playtested | 0 of 83 (0%) | 0 of 19 (0%) | 0 of 9 (0%) | 0 of 5 (0%) | 0 of 3 (0%) | 0 of 1 (0%) | 0 of 0 |
| Complete | 2 of 83 (2%) | 0 of 19 (0%) | 0 of 9 (0%) | 0 of 5 (0%) | 0 of 3 (0%) | 0 of 1 (0%) | 0 of 0 |
| Release blockers (open in-scope requirements) | 81 | 19 | 9 | 5 | 3 | 1 | 0 |
| Open owner decisions (of which blocking) | 1 (0) | 11 (0) | 14 (11) | 9 (7) | 3 (0) | 1 (0) | 0 (0) |
| Deferred with approval | 2 | 1 | 0 | 0 | 0 | 0 | 0 |
| Proposals and ideas (not counted) | 3 | 2 | 2 | 5 | 0 | 0 | 0 |
| Integrated, awaiting gameplay or owner verification | 78 | 0 | 0 | 0 | 0 | 0 | 0 |
| Remaining implementation by effort band (not yet integrated) | S 1, M 1, UNKNOWN 1 | XS 2, M 3, L 5, XL 1, UNKNOWN 8 | UNKNOWN 9 | UNKNOWN 5 | UNKNOWN 3 | UNKNOWN 1 | none |
| Readiness | RELEASED (private playtest draft (code 61ec528, run 39935635926, 2026-10-23)) | PROTOTYPE ONLY (isolated branch; not integrated) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | NOT AUTHORIZED for implementation |

Build authority:

- **Build 18 (Combined release (tracks A, B, C)):** implementation authorized. B18-DIR, B18-SCOPE; no distributable without the owner's approval
- **Build 19 (NPC Judgment):** implementation authorized. PROS-01: prospective work on wip/expansion19-preparation only, isolated until Build 18 is complete
- **Build 20 (Living Economy):** implementation authorized. owner directive 2026-10-23 (docs/directives/2026-10-23_expansion20_phase1_authorization.md): phase 1 only: LE-00 audit, registration, data contracts and isolated foundation components behind disabled hooks on wip/expansion20-preparation; no live economy, no merge to staging or main, no policy for open OD-LE decisions
- **Build 21 (Village Politics):** implementation authorized. owner directive 2026-10-23 (docs/directives/2026-10-23_expansion21_phase1_authorization.md): phase 1 only: P21-00 audit, P21-01 isolated civic foundations (records only, all political behaviour disabled), P21-02 decision mapping on wip/expansion21-preparation; no politics active, no merge to staging or main, no builds
- **Build 22 (Settlement Advancement Phase 2):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): read-only audit and architecture only; no implementation until the owner reviews the audit and approves the architecture; builds on Build 18's settlement systems, never duplicating them
- **Build 23 (Bandit Factions and Criminal Careers):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): BAN-A audit and requirements reconciliation only; no criminal actions or faction behaviour
- **Build 24 (Generational Legacy):** implementation **NOT AUTHORIZED**. OD-30 renumbered 2026-10-23: numbering only

Future backlog and unassigned: 113 open records (`BACKLOG.md`). Open owner decisions: 46 (`DECISIONS.md`).

