# Requirements status by build

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Definitions: `docs/requirements/SCHEMA.md`. Counted: approved, in-scope requirements of the build (umbrella entries, deferred, superseded and rejected records, proposals and ideas excluded). Integration, verification and completion are separate counts; none implies release readiness. Effort bands are the audit's estimates where recorded; UNKNOWN where not.

| Measure | Build 18 | Build 19 | Build 20 | Build 21 | Build 22 | Build 23 | Build 24 | Build 25 | Build 26 | Build 27 |
|---|---|---|---|---|---|---|---|---|---|---|
| Approved requirements (in scope) | 83 | 11 | 116 | 5 | 9 | 2 | 0 | 1 | 5 | 1 |
| Fully specified (design SPECIFIED) | 66 of 83 (80%) | 3 of 11 (27%) | 9 of 116 (8%) | 0 of 5 (0%) | 0 of 9 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Waiting on an owner decision (design) | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Design work still required | 2 | 0 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Design unknown | 15 | 8 | 101 | 5 | 9 | 2 | 0 | 1 | 5 | 1 |
| Not started (incl. READY) | 2 | 0 | 4 | 1 | 8 | 1 | 0 | 1 | 5 | 1 |
| In development (worker assigned) | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Partially implemented | 0 | 1 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Implemented on a task branch | 0 | 0 | 1 | 3 | 1 | 1 | 0 | 0 | 0 | 0 |
| Implementation blocked | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Integrated | 81 of 83 (98%) | 10 of 11 (91%) | 106 of 116 (91%) | 1 of 5 (20%) | 0 of 9 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Automated tests passed (targeted or better) | 79 of 83 (95%) | 10 of 11 (91%) | 110 of 116 (95%) | 2 of 5 (40%) | 0 of 9 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Integration verified (suite on the integrated build) | 58 of 83 (70%) | 9 of 11 (82%) | 64 of 116 (55%) | 1 of 5 (20%) | 0 of 9 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Gameplay verified | 0 of 83 (0%) | 0 of 11 (0%) | 0 of 116 (0%) | 0 of 5 (0%) | 0 of 9 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Owner playtested | 0 of 83 (0%) | 0 of 11 (0%) | 0 of 116 (0%) | 0 of 5 (0%) | 0 of 9 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Complete | 2 of 83 (2%) | 9 of 11 (82%) | 2 of 116 (2%) | 0 of 5 (0%) | 0 of 9 (0%) | 0 of 2 (0%) | 0 of 0 | 0 of 1 (0%) | 0 of 5 (0%) | 0 of 1 (0%) |
| Release blockers (open in-scope requirements) | 81 | 2 | 114 | 5 | 9 | 2 | 0 | 1 | 5 | 1 |
| Open owner decisions (of which blocking) | 0 (0) | 0 (0) | 1 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 5 (0) | 9 (0) | 0 (0) |
| Deferred with approval | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Proposals and ideas (not counted) | 3 | 2 | 2 | 5 | 0 | 4 | 5 | 0 | 0 | 4 |
| Integrated, awaiting gameplay or owner verification | 79 | 1 | 104 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Remaining implementation by effort band (not yet integrated) | S 1, M 1 | UNKNOWN 1 | XS 1, UNKNOWN 9 | UNKNOWN 4 | UNKNOWN 9 | UNKNOWN 2 | none | UNKNOWN 1 | UNKNOWN 5 | UNKNOWN 1 |
| Readiness | RELEASED (private playtest draft (code 61ec528, run 39935635926, 2026-10-23)) | RELEASED (private playtest draft (code 2f72ec3, run 40044931601, 2026-10-24); complete as the development milestone (owner 2026-10-24)) | RELEASED (Build 23 private draft (code c79b12c, run 40526826846, release 425699977, 2026-10-27); MP-INTERACT-01 integrated last and validated before the build (X20-FINAL); Build 24 private draft (code 4611d86, run 40636966840, release 426357144, 2026-10-28): Expansion 20 checkpoint, then development paused (X20-CHECKPOINT)) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | IN DEVELOPMENT (not feature complete) | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation | NOT AUTHORIZED for implementation |

Build authority:

- **Build 18 (Combined release (tracks A, B, C)):** implementation authorized. B18-DIR, B18-SCOPE; no distributable without the owner's approval
- **Build 19 (NPC Judgment):** implementation authorized. X19-SCOPE; owner 2026-10-24: Build 19 complete and accepted as the development baseline; the owner's playtest is not a prerequisite
- **Build 20 (Living Economy):** implementation authorized. owner directive 2026-10-26 (docs/directives/2026-10-26_build22_expansion20_execution_authorization.md, superseding the 2026-10-23 phase 1 limit): substantive Expansion 20 implementation on wip/expansion20; policies for open OD-LE decisions still need the owner. RELEASE BLOCKER (owner 2026-10-27, docs/directives/2026-10-27_multiplayer_interaction_release_blocker.md): no Expansion 20 build of any kind, private drafts included, until MP-INTERACT-01 is integrated and validated; COMPLETION PRIORITY (owner 2026-10-27, docs/directives/2026-10-27_complete_expansion20_first.md, X20-COMPLETE): finish Expansion 20 before any Expansion 21 implementation; Build 23 stays a private checkpoint
- **Build 21 (Village Politics):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansion21_phase1_authorization.md): phase 1 only (P21-00, P21-01, P21-02) on wip/expansion21-preparation, done, behaviour disabled; ON HOLD (owner 2026-10-27 X20-COMPLETE; 2026-10-28 'Do not start Expansion 21'; 2026-10-30 'Keep Expansion 21 politics isolated and on hold'); next phase Build 27 only after Build 26 is frozen and the owner explicitly authorizes (BUILD-SEQ-25-27, 2026-10-31). implementation_authorized true covers phase 1 only.
- **Build 22 (Settlement Advancement Phase 2):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): audit and architecture only (E22-P1, done); 'Do not begin implementation until we review the audit and approve the architecture'; 2026-10-30 'Do not begin Expansions 22–27'. implementation_authorized true covers the audit record only; no phase is authorized.
- **Build 23 (Bandit Factions and Criminal Careers):** implementation authorized. owner 2026-10-23 (docs/directives/2026-10-23_expansions_22_23_kickoff.md): audit and architecture only (E23-BANA, done); 'Do not begin implementation until we review the audit and approve the architecture'; 2026-10-30 'Do not begin Expansions 22–27'. implementation_authorized true covers the audit record only; no phase is authorized.
- **Build 24 (Generational Legacy):** implementation **NOT AUTHORIZED**. OD-30 renumbered 2026-10-23: numbering only
- **Build 25 (Weather, Seasons and Disasters):** implementation **NOT AUTHORIZED**. WEATHER-01 (owner 2026-10-23): design only, no code
- **Build 26 (Creatures and Heroes):** implementation **NOT AUTHORIZED**. PET-01, MON-01 (owner 2026-10-23): design only, no code
- **Build 27 (World Exploration, Dungeons & Encounters):** implementation **NOT AUTHORIZED**. ROAD-Q1 (owner 2026-10-24): numbering only

Future backlog and unassigned: 119 open records (`BACKLOG.md`). Open owner decisions: 26 (`DECISIONS.md`).

