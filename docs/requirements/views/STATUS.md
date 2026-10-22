# Requirements status by build

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Definitions: `docs/requirements/SCHEMA.md`. Counted: approved, in-scope requirements of the build (umbrella entries, deferred, superseded and rejected records, proposals and ideas excluded). Integration, verification and completion are separate counts; none implies release readiness. Effort bands are the audit's estimates where recorded; UNKNOWN where not.

| Measure | Build 18 | Build 19 | Build 20 | Build 21 |
|---|---|---|---|---|
| Approved requirements (in scope) | 73 | 12 | 7 | 1 |
| Fully specified (design SPECIFIED) | 58 of 73 (79%) | 6 of 12 (50%) | 0 of 7 (0%) | 0 of 1 (0%) |
| Waiting on an owner decision (design) | 5 | 0 | 0 | 0 |
| Design work still required | 6 | 2 | 0 | 0 |
| Design unknown | 4 | 4 | 7 | 1 |
| Not started (incl. READY) | 21 | 6 | 7 | 1 |
| In development (worker assigned) | 3 | 0 | 0 | 0 |
| Partially implemented | 16 | 3 | 0 | 0 |
| Implemented on a task branch | 0 | 3 | 0 | 0 |
| Implementation blocked | 0 | 0 | 0 | 0 |
| Integrated | 33 of 73 (45%) | 0 of 12 (0%) | 0 of 7 (0%) | 0 of 1 (0%) |
| Automated tests passed (targeted or better) | 34 of 73 (47%) | 4 of 12 (33%) | 0 of 7 (0%) | 0 of 1 (0%) |
| Integration verified (suite on the integrated build) | 33 of 73 (45%) | 0 of 12 (0%) | 0 of 7 (0%) | 0 of 1 (0%) |
| Gameplay verified | 0 of 73 (0%) | 0 of 12 (0%) | 0 of 7 (0%) | 0 of 1 (0%) |
| Owner playtested | 0 of 73 (0%) | 0 of 12 (0%) | 0 of 7 (0%) | 0 of 1 (0%) |
| Complete | 1 of 73 (1%) | 0 of 12 (0%) | 0 of 7 (0%) | 0 of 1 (0%) |
| Release blockers (open in-scope requirements) | 72 | 12 | 7 | 1 |
| Open owner decisions (of which blocking) | 5 (2) | 1 (0) | 14 (14) | 9 (9) |
| Deferred with approval | 2 | 1 | 0 | 0 |
| Proposals and ideas (not counted) | 3 | 1 | 0 | 5 |
| Integrated, awaiting gameplay or owner verification | 32 | 0 | 0 | 0 |
| Remaining implementation by effort band (not yet integrated) | XS 1, S 12, M 15, L 5, XL 2, UNKNOWN 5 | XS 2, M 3, L 4, XL 1, UNKNOWN 2 | UNKNOWN 7 | UNKNOWN 1 |
| Readiness | IN DEVELOPMENT (not feature complete) | PROTOTYPE ONLY (isolated branch; not integrated) | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation |

Build authority:

- **Build 18 (Combined release (tracks A, B, C)):** implementation authorized. B18-DIR, B18-SCOPE; no distributable without the owner's approval
- **Build 19 (NPC Judgment):** implementation authorized. PROS-01: prospective work on wip/expansion19-preparation only, isolated until Build 18 is complete
- **Build 20 (Living Economy):** implementation **NOT AUTHORIZED**. OD-30, OD-LE-01: numbering and placement only; implementation not authorized
- **Build 21 (Village Politics):** implementation **NOT AUTHORIZED**. OD-30: numbering only; implementation not authorized

Future backlog and unassigned: 102 open records (`BACKLOG.md`). Open owner decisions: 36 (`DECISIONS.md`).

