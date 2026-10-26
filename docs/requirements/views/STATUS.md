# Requirements status by build

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Definitions: `docs/requirements/SCHEMA.md`. Counted: approved, in-scope requirements of the build (umbrella entries, deferred, superseded and rejected records, proposals and ideas excluded). Integration, verification and completion are separate counts; none implies release readiness. Effort bands are the audit's estimates where recorded; UNKNOWN where not.

| Measure | Build 18 | Build 19 | Build 20 | Build 21 | Build 22 | Build 23 | Build 24 | Build 25 | Build 26 | Build 27 |
|---|---|---|---|---|---|---|---|---|---|---|
| Approved requirements (in scope) | 83 | 11 | 73 | 6 | 4 | 2 | 0 | 1 | 5 | 1 |
| Fully specified (design SPECIFIED) | 66 of 83 (80%) | 3 of 11 (27%) | 9 of 73 (12%) | 0 of 6 (0%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Waiting on an owner decision (design) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Design work still required | 2 | 0 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Design unknown | 15 | 8 | 60 | 6 | 4 | 2 | 0 | 1 | 5 | 1 |
| Not started (incl. READY) | 2 | 1 | 35 | 2 | 3 | 1 | 0 | 1 | 5 | 1 |
| In development (worker assigned) | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Partially implemented | 2 | 0 | 6 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Implemented on a task branch | 0 | 0 | 2 | 3 | 1 | 1 | 0 | 0 | 0 | 0 |
| Implementation blocked | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Integrated | 79 of 83 (95%) | 10 of 11 (91%) | 28 of 73 (38%) | 1 of 6 (17%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Automated tests passed (targeted or better) | 77 of 83 (93%) | 10 of 11 (91%) | 33 of 73 (45%) | 2 of 6 (33%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Integration verified (suite on the integrated build) | 57 of 83 (69%) | 1 of 11 (9%) | 28 of 73 (38%) | 1 of 6 (17%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Gameplay verified | 0 of 83 (0%) | 0 of 11 (0%) | 0 of 73 (0%) | 0 of 6 (0%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Owner playtested | 0 of 83 (0%) | 0 of 11 (0%) | 0 of 73 (0%) | 0 of 6 (0%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Complete | 2 of 83 (2%) | 1 of 11 (9%) | 0 of 73 (0%) | 0 of 6 (0%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Release blockers (open in-scope requirements) | 81 | 10 | 73 | 6 | 4 | 2 | 0 | 1 | 5 | 1 |
| Open owner decisions (of which blocking) | 1 (0) | 3 (0) | 14 (11) | 9 (7) | 3 (0) | 1 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) |
| Deferred with approval | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Proposals and ideas (not counted) | 3 | 3 | 2 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Integrated, awaiting gameplay or owner verification | 77 | 9 | 28 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Remaining implementation by effort band (not yet integrated) | S 1, M 1, UNKNOWN 2 | UNKNOWN 1 | XS 2, S 3, M 3, L 5, XL 1, UNKNOWN 31 | UNKNOWN 5 | UNKNOWN 4 | UNKNOWN 2 | none | UNKNOWN 1 | UNKNOWN 5 | UNKNOWN 1 |
| Readiness | RELEASED (private playtest draft (code 61ec528, run 39935635926, 2026-10-23)) | RELEASED (private playtest draft (code 2f72ec3, run 40044931601, 2026-10-24); complete as the development milestone (owner 2026-10-24)) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation |

Build authority:

- **Build 18 (Combined release (tracks A, B, C)):** implementation authorized. B18-DIR, B18-SCOPE; no distributable without the owner's approval
- **Build 19 (NPC Judgment):** implementation authorized. X19-SCOPE; owner 2026-10-24: Build 19 complete and accepted as the development baseline; the owner's playtest is not a prerequisite
- **Build 20 (Living Economy):** implementation authorized. owner directive 2026-10-23 (docs/directives/2026-10-23_expansion20_phase1_authorization.md): phase 1 only: LE-00 audit, registration, data contracts and isolated foundation components behind disabled hooks on wip/expansion20-preparation; no live economy, no merge to staging or main, no policy for open OD-LE decisions
- **Build 21 (Village Politics):** implementation authorized. owner directive 2026-10-23 (docs/directives/2026-10-23_expansion21_phase1_authorization.md): phase 1 only: P21-00 audit, P21-01 isolated civic foundations (records only, all political behaviour disabled), P21-02 decision mapping on wip/expansion21-preparation; no politics active, no merge to staging or main, no builds
- **Build 22 (Settlement Advancement Phase 2):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): read-only audit and architecture only; no implementation until the owner reviews the audit and approves the architecture; builds on Build 18's settlement systems, never duplicating them
- **Build 23 (Bandit Factions and Criminal Careers):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): BAN-A audit and requirements reconciliation only; no criminal actions or faction behaviour
- **Build 24 (Generational Legacy):** implementation **NOT AUTHORIZED**. OD-30 renumbered 2026-10-23: numbering only
- **Build 25 (Weather, Seasons and Disasters):** implementation **NOT AUTHORIZED**. WEATHER-01 (owner 2026-10-23): design only, no code
- **Build 26 (Creatures and Heroes):** implementation **NOT AUTHORIZED**. PET-01, MON-01 (owner 2026-10-23): design only, no code
- **Build 27 (World Exploration, Dungeons & Encounters):** implementation **NOT AUTHORIZED**. ROAD-Q1 (owner 2026-10-24): numbering only

Future backlog and unassigned: 115 open records (`BACKLOG.md`). Open owner decisions: 38 (`DECISIONS.md`).

