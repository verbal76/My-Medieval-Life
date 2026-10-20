# Project memory: start here

This is the entry point for any new session (owner directives 2026-10-20, register MEM-01 and MEM-02; the session-start steps are CLAUDE.md section 0). The repository, not any conversation, is the record. Every file named below is authoritative for its subject. This index only says where things are and in what order to read them. It does not copy their contents.

## What the project is

My Medieval Life (Hot Attic Games, repository `verbal76/My-Medieval-Life`) is a 2D pixel-art medieval life simulation, built in Godot 4.7 (`game/`). It ships to Android first, then Windows and Linux, from one commit with one build number.

A village of about a hundred people works, trades, eats, courts, ages, builds and dies whether or not the player is present. The world must keep living on its own, and the player is the variable that changes its history, not what keeps it alive.

The governing principles are the owner's numbered World Design Rules in `docs/WORLD_DESIGN_RULES.md`. Rules 001–016 are verbatim from the owner's PDF in `docs/directives/`; 017 onward were added later. Among them:
- finite resources and real consumption;
- material and professional interdependency;
- a living world independent of the player;
- emergent gameplay;
- depth without obscurity;
- automated compliance.

The design intent is in `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md`. What is confirmed, proposed or undecided in the game design is in `docs/GAME_DESIGN.md`.

## Where everything is

| Subject | Authoritative record |
|---|---|
| Project rules, workflow, release policy, the session-start procedure | `CLAUDE.md` |
| Every owner requirement, proposal, open decision and rule, with id, source, approval, build, dependencies, status, acceptance, evidence and history | `docs/requirements/requirements.json` (the one register; validated by `tools/check_requirements.py`) |
| The same register for reading: counts, the Roadmap (every open item by build), the real-device queue, items by status | `docs/DEVELOPMENT_LEDGER.md` (generated; never edited by hand) |
| The owner's directives, verbatim, with the documents supplied | `docs/directives/`. The two memory directives: `2026-10-20_project_memory_hardening.md` (MEM-01) and `2026-10-20_permanent_project_memory_hardening.md` (MEM-02, wider) |
| Decisions with date and who decided (owner or agent proposal) | `docs/DECISIONS.md` |
| The five-build roadmap, the three expansions and their dependencies | `docs/EXPANSION_ROADMAP.md` |
| Expansion specifications (primary): Mining & Industrial (Build 17); Settlement Advancement & Regional Economy (Build 18); NPC Judgment System (Build 19) | `docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf`, `docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf`, `docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf` (text copies beside each) |
| Current work, last verified commit, tests, defects, next tasks | `docs/CURRENT_DEVELOPMENT_STATE.md` |
| How systems affect each other (INT-### entries, validated) | `docs/SYSTEM_INTERACTION_MANIFEST.md` (`tools/check_interactions.py`) |
| Design scopes for later work (upper floors and attics) | `docs/design/UPPER_FLOORS_SCOPE.md` |
| Simulation performance (runtime, timing, restarts, checkpoint evaluation) | `docs/release/SIMULATION_PERFORMANCE.md` |
| Architecture | `docs/ARCHITECTURE.md`; rules and open questions of the prototype in `docs/BUILD_DECISIONS.md` |
| Saves: format, safety, migration, carrying a save between builds, recovery | `docs/release/SAVE_CONTINUITY.md`; code in `game/scripts/core/save_store.gd` and `game/scripts/core/save_transfer.gd` |
| Long-run simulations and their results | `docs/release/LONG_RUN_SIMULATION.md`; harness `game/tests/economy_sim.gd` |
| Releases: the last packet, readiness, Android signing | `docs/release/BUILD_14_PACKET.md`, `docs/release/BUILD_14_READINESS.md`, `docs/release/ANDROID_SIGNING.md`, `.github/workflows/release.yml` |
| Harvestable resources and their uses | `game/data/resources.json` (`tools/check_resources.py`) |
| Assets: registry, licences, scaling, the mandatory pipeline skill | `docs/assets/ASSET_REGISTRY.md`, `docs/assets/packs.json`, `docs/assets/ASSET_SCALING_STANDARD.md`, `.claude/skills/asset-integration-pipeline/SKILL.md` |
| The world research (Morris) | `docs/world/` |
| The open-items audit and the 231-entry reconciliation against the five builds (2026-10-20) | `docs/requirements/RECONCILIATION_2026-10-20.md` (generated: what has closed, moved or been added since), frozen baseline `docs/requirements/baseline_2026-10-20.json` (the 231 open and 142 closed approved entries at `a203c0b`); the audit before it: `docs/release/BUILD_14_OPEN_ITEMS_AUDIT.md` |
| Builds 15–19, the Build 20+ backlog, multiplayer, owner decisions, owner or external actions | The Roadmap section of `docs/DEVELOPMENT_LEDGER.md`: one table per category, each entry with its gate and reason |
| Known limitations | Defects in progress: `docs/CURRENT_DEVELOPMENT_STATE.md` ("Known defects"); save limits: `docs/release/SAVE_CONTINUITY.md` section 3; last build's known issues: `docs/release/BUILD_14_READINESS.md`; prototype rules and open questions: `docs/BUILD_DECISIONS.md`; Android signing: `docs/release/ANDROID_SIGNING.md` |
| Older recovery records (history; the register supersedes their counts) | `docs/requirements/RECOVERY_2026-10-19.md`, `docs/HANDOFF.md`, `docs/DEVELOPMENT_QUEUE.md`, `docs/DEVELOPMENT_PLAN.md` (all marked historical) |

## How the register says where an item stands

Every entry has a stable id, a `kind` and a lifecycle `status` (the validator rejects anything else):

| The owner's category | In the register |
|---|---|
| Approved but not started | kind `approved`, status APPROVED — NOT STARTED |
| In progress | ACTIVE DEVELOPMENT, or PARTIALLY IMPLEMENTED |
| Implemented but not verified | IMPLEMENTED — TESTING REQUIRED, or AUTOMATED TESTS PASSED — PLAYTEST REQUIRED (waiting on a real device) |
| Verified complete | COMPLETE AND VERIFIED, with implementation, test or commit evidence (enforced) |
| Blocked | BLOCKED, with its blockers |
| Deferred | DEFERRED |
| Proposed | kind `proposal` (or `idea`): never counted as approved work |
| Awaiting owner decision | kind `decision`, status BLOCKED, until the owner's words are recorded in `owner_answer` (enforced) |
| Superseded | SUPERSEDED, with `superseded_by` naming the replacing entry (enforced) |
| Unknown | UNKNOWN — INVESTIGATION REQUIRED |

Every open entry also carries `target_build` (15–19, `20+`, `multiplayer`, `owner decision`, `owner action`), `roadmap_gate` and `roadmap_reason`, `acceptance` (completion criteria), `depends_on`, and a `history` line for every change.

## Roadmap (owner, 2026-10-20: ROAD-01)

| Build | Content | Status |
|---|---|---|
| 14 | Released as a private draft from `7dbae4f` | The current test build |
| 15 | Simulation stabilization: population, housing, wildlife, resources, economy, relationships | In development |
| 16 | Long-term equilibrium and validation: the baseline before the expansions | Planned |
| 17 | Mining & Industrial Development (EXP-A) | Approved objective; **not started**, needs authorization to begin |
| 18 | Settlement Advancement & Regional Economy (EXP-B) | Approved objective; **not started** |
| 19 | NPC Judgment System (EXP-C) | Approved objective; **not started**; 14 open design questions (SJD-Q01..Q14) unanswered |

Every open register entry has a `target_build`. The dependencies that touch the order are in `docs/EXPANSION_ROADMAP.md`. If work must span more builds, keep the approved objective, flag the scheduling issue to the owner, and never silently change the roadmap.

## Open owner decisions and blockers

In the register:
- entries of kind `decision` with status BLOCKED (owner decisions);
- entries whose `roadmap_gate` is `owner decision first`;
- entries with `target_build` `owner decision` or `owner action`.

The ledger's Roadmap section lists them under "Waiting on an owner decision" and "Owner or external action". A decision is resolved only by the owner's words (`owner_answer`), and the validator refuses anything else.

Never answer an open decision on the owner's behalf, and never treat a proposal as approved.

## Sources that cannot be checked from the repository

A few early register entries cite chat messages or uploads that were never committed (for example REC-002, REC-007 and REC-013). Their wording is copied into the entry itself, under `owner_wording`. Treat that copy as the record, and ask the owner only if it is not enough to act on.

## How to find the next approved task

1. `docs/CURRENT_DEVELOPMENT_STATE.md`, "Next approved tasks": the priority order.
2. Then the register: entries with `target_build` of the current build (15 now), kind `approved`, status not closed and no gate that is still waiting. The ledger's Roadmap section lists them by build.
3. Work the current build's items. Do not start a later build's items except where the roadmap names a dependency (SET-A's design during Build 17).

## What must not begin without further authorization

- Builds 17, 18 and 19: approved objectives only.
- Any release, upload or publication: only under the release authorization in force (REL-14-16 covers Builds 14–16 as private drafts) and its eight conditions. Public visibility needs its own approval.
- Merging into `main`; force-pushing or deleting `staging/my-medieval-life`.
- Merging multiplayer (`wip/multiplayer`) into staging.
- Answering the judgment system's 14 questions, or any open owner decision.
- New gameplay mechanics beyond approved requirements; breaking save compatibility; new paid dependencies or online features.
- The permanent Android signing key (deferred by the owner).

The full list is CLAUDE.md, section 11.
