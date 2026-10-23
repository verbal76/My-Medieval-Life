# Requirements status by build

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Definitions: `docs/requirements/SCHEMA.md`. Counted: approved, in-scope requirements of the build (umbrella entries, deferred, superseded and rejected records, proposals and ideas excluded). Integration, verification and completion are separate counts; none implies release readiness. Effort bands are the audit's estimates where recorded; UNKNOWN where not.

| Measure | Build 18 | Build 19 | Build 20 | Build 21 |
|---|---|---|---|---|
| Approved requirements (in scope) | 82 | 13 | 8 | 1 |
| Fully specified (design SPECIFIED) | 66 of 82 (80%) | 6 of 13 (46%) | 0 of 8 (0%) | 0 of 1 (0%) |
| Waiting on an owner decision (design) | 0 | 0 | 0 | 0 |
| Design work still required | 2 | 3 | 0 | 0 |
| Design unknown | 14 | 4 | 8 | 1 |
| Not started (incl. READY) | 7 | 7 | 8 | 1 |
| In development (worker assigned) | 0 | 0 | 0 | 0 |
| Partially implemented | 3 | 3 | 0 | 0 |
| Implemented on a task branch | 0 | 3 | 0 | 0 |
| Implementation blocked | 0 | 0 | 0 | 0 |
| Integrated | 72 of 82 (88%) | 0 of 13 (0%) | 0 of 8 (0%) | 0 of 1 (0%) |
| Automated tests passed (targeted or better) | 70 of 82 (85%) | 4 of 13 (31%) | 0 of 8 (0%) | 0 of 1 (0%) |
| Integration verified (suite on the integrated build) | 55 of 82 (67%) | 0 of 13 (0%) | 0 of 8 (0%) | 0 of 1 (0%) |
| Gameplay verified | 0 of 82 (0%) | 0 of 13 (0%) | 0 of 8 (0%) | 0 of 1 (0%) |
| Owner playtested | 0 of 82 (0%) | 0 of 13 (0%) | 0 of 8 (0%) | 0 of 1 (0%) |
| Complete | 2 of 82 (2%) | 0 of 13 (0%) | 0 of 8 (0%) | 0 of 1 (0%) |
| Release blockers (open in-scope requirements) | 80 | 13 | 8 | 1 |
| Open owner decisions (of which blocking) | 6 (1) | 1 (0) | 14 (14) | 9 (9) |
| Deferred with approval | 2 | 1 | 0 | 0 |
| Proposals and ideas (not counted) | 3 | 1 | 2 | 5 |
| Integrated, awaiting gameplay or owner verification | 70 | 0 | 0 | 0 |
| Remaining implementation by effort band (not yet integrated) | S 1, M 5, UNKNOWN 4 | XS 2, M 3, L 5, XL 1, UNKNOWN 2 | UNKNOWN 8 | UNKNOWN 1 |
| Readiness | IN DEVELOPMENT (not feature complete) | PROTOTYPE ONLY (isolated branch; not integrated) | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation |

Build authority:

- **Build 18 (Combined release (tracks A, B, C)):** implementation authorized. B18-DIR, B18-SCOPE; no distributable without the owner's approval
- **Build 19 (NPC Judgment):** implementation authorized. PROS-01: prospective work on wip/expansion19-preparation only, isolated until Build 18 is complete
- **Build 20 (Living Economy):** implementation **NOT AUTHORIZED**. OD-30, OD-LE-01: numbering and placement only; implementation not authorized
- **Build 21 (Village Politics):** implementation **NOT AUTHORIZED**. OD-30: numbering only; implementation not authorized

Future backlog and unassigned: 108 open records (`BACKLOG.md`). Open owner decisions: 36 (`DECISIONS.md`).

