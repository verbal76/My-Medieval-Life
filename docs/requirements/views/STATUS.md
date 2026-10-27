# Requirements status by build

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Definitions: `docs/requirements/SCHEMA.md`. Counted: approved, in-scope requirements of the build (umbrella entries, deferred, superseded and rejected records, proposals and ideas excluded). Integration, verification and completion are separate counts; none implies release readiness. Effort bands are the audit's estimates where recorded; UNKNOWN where not.

| Measure | Build 18 | Build 19 | Build 20 | Build 21 | Build 22 | Build 23 | Build 24 | Build 25 | Build 26 | Build 27 |
|---|---|---|---|---|---|---|---|---|---|---|
| Approved requirements (in scope) | 83 | 11 | 82 | 6 | 4 | 2 | 0 | 1 | 5 | 1 |
| Fully specified (design SPECIFIED) | 66 of 83 (80%) | 3 of 11 (27%) | 9 of 82 (11%) | 0 of 6 (0%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Waiting on an owner decision (design) | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Design work still required | 2 | 0 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Design unknown | 15 | 8 | 67 | 6 | 4 | 2 | 0 | 1 | 5 | 1 |
| Not started (incl. READY) | 2 | 1 | 10 | 2 | 3 | 1 | 0 | 1 | 5 | 1 |
| In development (worker assigned) | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Partially implemented | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Implemented on a task branch | 0 | 0 | 0 | 3 | 1 | 1 | 0 | 0 | 0 | 0 |
| Implementation blocked | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Integrated | 80 of 83 (96%) | 10 of 11 (91%) | 70 of 82 (85%) | 1 of 6 (17%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Automated tests passed (targeted or better) | 78 of 83 (94%) | 10 of 11 (91%) | 70 of 82 (85%) | 2 of 6 (33%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Integration verified (suite on the integrated build) | 57 of 83 (69%) | 9 of 11 (82%) | 36 of 82 (44%) | 1 of 6 (17%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Gameplay verified | 0 of 83 (0%) | 0 of 11 (0%) | 0 of 82 (0%) | 0 of 6 (0%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Owner playtested | 0 of 83 (0%) | 0 of 11 (0%) | 0 of 82 (0%) | 0 of 6 (0%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Complete | 2 of 83 (2%) | 9 of 11 (82%) | 2 of 82 (2%) | 0 of 6 (0%) | 0 of 4 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Release blockers (open in-scope requirements) | 81 | 2 | 80 | 6 | 4 | 2 | 0 | 1 | 5 | 1 |
| Open owner decisions (of which blocking) | 0 (0) | 0 (0) | 7 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) |
| Deferred with approval | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Proposals and ideas (not counted) | 3 | 3 | 2 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Integrated, awaiting gameplay or owner verification | 78 | 1 | 68 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Remaining implementation by effort band (not yet integrated) | S 1, M 1, UNKNOWN 1 | UNKNOWN 1 | XS 1, L 1, UNKNOWN 10 | UNKNOWN 5 | UNKNOWN 4 | UNKNOWN 2 | none | UNKNOWN 1 | UNKNOWN 5 | UNKNOWN 1 |
| Readiness | RELEASED (private playtest draft (code 61ec528, run 39935635926, 2026-10-23)) | RELEASED (private playtest draft (code 2f72ec3, run 40044931601, 2026-10-24); complete as the development milestone (owner 2026-10-24)) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation |

Build authority:

- **Build 18 (Combined release (tracks A, B, C)):** implementation authorized. B18-DIR, B18-SCOPE; no distributable without the owner's approval
- **Build 19 (NPC Judgment):** implementation authorized. X19-SCOPE; owner 2026-10-24: Build 19 complete and accepted as the development baseline; the owner's playtest is not a prerequisite
- **Build 20 (Living Economy):** implementation authorized. owner directive 2026-10-26 (docs/directives/2026-10-26_build22_expansion20_execution_authorization.md, superseding the 2026-10-23 phase 1 limit): substantive Expansion 20 implementation on wip/expansion20; policies for open OD-LE decisions still need the owner. RELEASE BLOCKER (owner 2026-10-27, docs/directives/2026-10-27_multiplayer_interaction_release_blocker.md): no Expansion 20 build of any kind, private drafts included, until MP-INTERACT-01 is integrated and validated
- **Build 21 (Village Politics):** implementation authorized. owner directive 2026-10-23 (docs/directives/2026-10-23_expansion21_phase1_authorization.md): phase 1 only: P21-00 audit, P21-01 isolated civic foundations (records only, all political behaviour disabled), P21-02 decision mapping on wip/expansion21-preparation; no politics active, no merge to staging or main, no builds
- **Build 22 (Settlement Advancement Phase 2):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): read-only audit and architecture only; no implementation until the owner reviews the audit and approves the architecture; builds on Build 18's settlement systems, never duplicating them
- **Build 23 (Bandit Factions and Criminal Careers):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): BAN-A audit and requirements reconciliation only; no criminal actions or faction behaviour
- **Build 24 (Generational Legacy):** implementation **NOT AUTHORIZED**. OD-30 renumbered 2026-10-23: numbering only
- **Build 25 (Weather, Seasons and Disasters):** implementation **NOT AUTHORIZED**. WEATHER-01 (owner 2026-10-23): design only, no code
- **Build 26 (Creatures and Heroes):** implementation **NOT AUTHORIZED**. PET-01, MON-01 (owner 2026-10-23): design only, no code
- **Build 27 (World Exploration, Dungeons & Encounters):** implementation **NOT AUTHORIZED**. ROAD-Q1 (owner 2026-10-24): numbering only

Future backlog and unassigned: 111 open records (`BACKLOG.md`). Open owner decisions: 8 (`DECISIONS.md`).

