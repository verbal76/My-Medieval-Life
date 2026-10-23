# Requirements status by build

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Definitions: `docs/requirements/SCHEMA.md`. Counted: approved, in-scope requirements of the build (umbrella entries, deferred, superseded and rejected records, proposals and ideas excluded). Integration, verification and completion are separate counts; none implies release readiness. Effort bands are the audit's estimates where recorded; UNKNOWN where not.

| Measure | Build 18 | Build 19 | Build 20 | Build 21 |
|---|---|---|---|---|
| Approved requirements (in scope) | 83 | 17 | 9 | 4 |
| Fully specified (design SPECIFIED) | 66 of 83 (80%) | 6 of 17 (35%) | 0 of 9 (0%) | 0 of 4 (0%) |
| Waiting on an owner decision (design) | 0 | 0 | 0 | 0 |
| Design work still required | 2 | 3 | 0 | 0 |
| Design unknown | 15 | 8 | 9 | 4 |
| Not started (incl. READY) | 2 | 7 | 9 | 2 |
| In development (worker assigned) | 0 | 4 | 0 | 0 |
| Partially implemented | 1 | 3 | 0 | 0 |
| Implemented on a task branch | 0 | 3 | 0 | 2 |
| Implementation blocked | 0 | 0 | 0 | 0 |
| Integrated | 80 of 83 (96%) | 0 of 17 (0%) | 0 of 9 (0%) | 0 of 4 (0%) |
| Automated tests passed (targeted or better) | 78 of 83 (94%) | 4 of 17 (24%) | 0 of 9 (0%) | 0 of 4 (0%) |
| Integration verified (suite on the integrated build) | 58 of 83 (70%) | 0 of 17 (0%) | 0 of 9 (0%) | 0 of 4 (0%) |
| Gameplay verified | 0 of 83 (0%) | 0 of 17 (0%) | 0 of 9 (0%) | 0 of 4 (0%) |
| Owner playtested | 0 of 83 (0%) | 0 of 17 (0%) | 0 of 9 (0%) | 0 of 4 (0%) |
| Complete | 2 of 83 (2%) | 0 of 17 (0%) | 0 of 9 (0%) | 0 of 4 (0%) |
| Release blockers (open in-scope requirements) | 81 | 17 | 9 | 4 |
| Open owner decisions (of which blocking) | 1 (0) | 11 (0) | 14 (14) | 9 (9) |
| Deferred with approval | 2 | 1 | 0 | 0 |
| Proposals and ideas (not counted) | 3 | 2 | 2 | 5 |
| Integrated, awaiting gameplay or owner verification | 78 | 0 | 0 | 0 |
| Remaining implementation by effort band (not yet integrated) | S 1, M 1, UNKNOWN 1 | XS 2, M 3, L 5, XL 1, UNKNOWN 6 | UNKNOWN 9 | UNKNOWN 4 |
| Readiness | RELEASED (private playtest draft (code 61ec528, run 39935635926, 2026-10-23)) | PROTOTYPE ONLY (isolated branch; not integrated) | NOT STARTED | IN DEVELOPMENT (not feature complete) |

Build authority:

- **Build 18 (Combined release (tracks A, B, C)):** implementation authorized. B18-DIR, B18-SCOPE; no distributable without the owner's approval
- **Build 19 (NPC Judgment):** implementation authorized. PROS-01: prospective work on wip/expansion19-preparation only, isolated until Build 18 is complete
- **Build 20 (Living Economy):** implementation authorized. owner directive 2026-10-23 (docs/directives/2026-10-23_expansion20_phase1_authorization.md): phase 1 only: LE-00 audit, registration, data contracts and isolated foundation components behind disabled hooks on wip/expansion20-preparation; no live economy, no merge to staging or main, no policy for open OD-LE decisions
- **Build 21 (Village Politics):** implementation authorized. owner directive 2026-10-23 (docs/directives/2026-10-23_expansion21_phase1_authorization.md): phase 1 only: P21-00 audit, P21-01 isolated civic foundations (records only, all political behaviour disabled), P21-02 decision mapping on wip/expansion21-preparation; no politics active, no merge to staging or main, no builds

Future backlog and unassigned: 110 open records (`BACKLOG.md`). Open owner decisions: 41 (`DECISIONS.md`).

