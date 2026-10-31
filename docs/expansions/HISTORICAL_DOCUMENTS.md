# Historical and superseded documents: index

Owner directive 2026-10-31 (`docs/directives/2026-10-31_documentation_reconciliation.md`, DOC-RECON-01). Precedence and status
vocabulary: `docs/expansions/README.md`. A document listed here is kept for provenance. It is **not** authority for current
work: an older document never overrides a later owner decision, wherever it sits. When one of these documents disagrees with
the register (`docs/requirements/requirements.json`), a directive in `docs/directives/` or a status file in
`docs/expansions/`, those win.

"Banner" says whether the top of the file carries a status banner on staging (`owner 2026-10-27` = the owner's historical
banner; `DOC-RECON-01` = added on 2026-10-31; `none` = the lead or the owning expansion file decides).

## 1. Original game design (historical, owner 2026-10-27)

| Document | What it was | Replaced by | Banner |
|---|---|---|---|
| `docs/GAME_DESIGN.md` | First design draft (Undecided / Proposed / Confirmed lists) | The register and World Design Rules; OD-03 (D32) and OD-17 (D36) split its parts into CURRENT and PARKED | owner 2026-10-27 |
| `docs/BUILD_DECISIONS.md` | Agent choices for the first Godot prototype; its "deferred on purpose" list | Register records (e.g. PL2-015-OTHER cites it); `docs/DECISIONS.md` for agent decisions | owner 2026-10-27 |
| `docs/DESIGN_GAP_ASSESSMENT.md` | 2026-10-18 gap assessment and phased sequence (Q-11, DGA-*) | OD-09 (D35: reconcile old question ids, latest owner correction wins); the roadmap (`docs/EXPANSION_ROADMAP.md`, `docs/design/ROADMAP_20_27_PRIORITY.md`) | owner 2026-10-27 |
| `docs/game-designer/*` (README, MASTER_PROMPT, THE_WELL_SPEC_v1, SPEC_RECONCILIATION, CORRECTION_NOTES) | Game Designer ("Bob") interview spec and its reconciliation (REC-004) | OD-03, OD-09, OD-17 (owner, 2026-10-27); parked parts need the owner's reconfirmation. Files it names (`ARCHITECTURE_DECISIONS.md`, `EXCLUSIONS.md`, `FAILURE_LOG.md`, `GAMEPLAY_INVARIANTS.md`, `REQUIREMENTS_LEDGER.md`, `VERIFICATION.md`) were never in this repository | owner 2026-10-27 |
| `docs/ARCHITECTURE.md` | Engine proposal: "awaiting owner approval ... No engine project exists yet" | The established Godot 4.7 game (CLAUDE.md s.1; OD-03 "Godot on Android/Windows/Linux"); save rules in CLAUDE.md s.7 | DOC-RECON-01 |
| `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` | Owner-supplied concept v0.1, "Conceptual, non-binding" | World Design Rules, the Living Economy spec (Expansion 20) and the register; it remains a reference for intent | DOC-RECON-01 |
| `docs/LIVING_WORLD_ALIGNMENT.md` | Review of the concept against the repository; says implementation is "blocked by Gate A" | Gate A long passed; the systems it reviews are registered (FSE-*, LE-*, WDR-*) | DOC-RECON-01 |

## 2. Plans, queues and handoffs (historical)

| Document | Replaced by | Banner |
|---|---|---|
| `docs/DEVELOPMENT_PLAN.md` | `docs/CURRENT_DEVELOPMENT_STATE.md`, the register, `docs/requirements/views/` | owner 2026-10-27 (+ MEM-01 note) |
| `docs/DEVELOPMENT_QUEUE.md` | as above | owner 2026-10-27 (+ MEM-01 note) |
| `docs/HANDOFF.md` | `docs/CURRENT_DEVELOPMENT_STATE.md` | owner 2026-10-27 |
| `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_pre_2026-10-27_authority_cleanup.md` | `docs/CURRENT_DEVELOPMENT_STATE.md` | own banner |
| `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_to_2026-10-23.md` | `docs/CURRENT_DEVELOPMENT_STATE.md` | DOC-RECON-01 |
| `docs/handoffs/archive/CURRENT_SESSION_RECOVERY_to_2026-10-23.md` | `docs/handoffs/CURRENT_SESSION_RECOVERY.md` | DOC-RECON-01 |
| `docs/handoffs/X20_RECOVERY_HANDOFF.md` | Partly: its "development PAUSED" (2026-10-28) is superseded by X20-RESUME (2026-10-30); its remaining-work list is still cited by CLAUDE.md s.0. Status: Expansion 20 file | none (lead / Expansion 20 file) |
| `docs/BUILD_16_STATUS.md` | Build 16 status audit (2026-10-20); Build 16 released. Current: register and views | DOC-RECON-01 |
| `docs/SKIPPED_ITEMS.md` | Skipped-items table of the 2026-10-20 overnight directive; the register stays authoritative for status | none (rows carry register ids) |
| `docs/backlog/BUILD22_MINI_BUILD.md` | Says "Build 22 is not started"; Build 22 was released and its items reconciled under X20-OPEN-ITEMS | none (Expansion 20 file) |
| `docs/release/BUILD_7_ISSUES.md` ... `BUILD_16_*.md`, `OVERNIGHT_REPORT_2026-10-20.md` | Per-build issue lists, packets, readiness and tester notes: evidence of their time; statuses now in the register (B7-*, B8-*, B12A-*, B13-*, B14-*) | none |
| `docs/DECISIONS.md` | Narrative decision log, still appended for agent decisions (CLAUDE.md s.5); owner decisions are authoritative in the register and `docs/directives/` | none (active log) |

## 3. Superseded design packets and proposals

| Document | What superseded it | Banner |
|---|---|---|
| `docs/design/EXPANSIONS_20_21_DECISION_PACKET.md` ("neither expansion is authorized") | OD-LE answers, the 39-decision reconciliation (2026-10-27), X20-RESUME | none (Expansion 20/21 files) |
| `docs/design/ROADMAP_20_27_PRIORITY.md` "authorization today" column | 2026-10-26/27 authorizations; order 20 → 21 → 23 → 22 → 24 → 25 → 26 → 27 still current | none (roadmap, lead) |
| `docs/design/FLIGHT_RECORDER_DESIGN.md` ("nothing is implemented") | REC-19 integrated; developer reference `docs/design/FLIGHT_RECORDER.md` (on `wip/expansion20`); its planned `tools/recorder_xlsx.py` became `game/scripts/recorder_export/xlsx_writer.gd` | DOC-RECON-01 |
| `docs/design/ARMOUR_CATALOGUE_PROPOSAL.md` ("Nothing here is approved") | ARMOR-CATALOG-01 implemented; D16 answer B (2026-10-27) and the 2026-10-28 ruling: categories, items and visuals stand, numbers and materials PROVISIONAL | DOC-RECON-01 |
| `docs/design/IDENTITY_AND_RECONCILIATION_PROPOSAL.md` ("Nothing here is built") | ID-01 code merged into Build 19 and X; ID-D1, ID-D2 approved, ID-D3 provisional | none (ID-01 is assessed by the Expansion 17-19 file) |
| `docs/HOUSING_LAND_AUDIT.md` (2026-10-18 audit at `455e963`) | Property phases 1-2, HOUSE-01..12, FARM-01..09 | DOC-RECON-01 |
| `docs/expansion18/CARAVAN_REPLACEMENT.md` (on `wip/expansion20`) | Q18-3/Q18-4 (own header says so) | own header |
| `docs/expansion18/DESIGN.md`, `docs/expansion19/DESIGN.md` (on `wip/expansion20`; "PROSPECTIVE ... nothing integrated") | Builds 18 and 19 | none (only on `wip/expansion20`, which is frozen for Build 25 validation) |
| `docs/expansion20/LE05_RENTAL_REPAIR_PROPOSAL.md` (on `wip/expansion20`; "NOT implemented") | LE05-REPAIR, LE05-RENTAL integrated (`25663e5`) | none (same reason) |
| `docs/MULTIPLAYER.md` (on `wip/multiplayer`), `docs/multiplayer/PROTOTYPE_MULTIPLAYER_2026-10-19.md` | MP-MASTER and Batches A-D | none (multiplayer file) |
| `docs/directives/2026-10-21_master_expansion_roadmap.md` and the pack on `wip/roadmap-docs` (`docs/roadmap/22_Bandits.md`, `23_Legacy.md` use the old numbers) | Renumbering 2026-10-23 (22 Settlement Phase 2, 23 Bandits, 24 Legacy) and ROAD-03 order. Directives stay verbatim | never edited (directive) |
| `docs/juice/PRELIMINARY_ASSESSMENT.md` (only on `wip/juice-assessment`) | Not superseded: the current game-feel assessment, awaiting recovery in Build 26. Its decision D1 is answered by MUSIC-18/SFX-18 | n/a |

## 4. Morris research (historical literary research, owner 2026-10-27)

| Document | Status | Banner |
|---|---|---|
| `docs/world/*` (deliverables A-J), `research/` (sources, corpus, notes, extractions, registries) | Literary evidence and inspiration only, not game canon or design. OD-03 parks the Morris era, regions and counties | `docs/world/README.md` owner 2026-10-27; `research/` generated, no banner |

## 5. Referenced but missing

| Missing | Cited by | Note |
|---|---|---|
| `tools/recorder_xlsx.py` | `docs/design/FLIGHT_RECORDER_DESIGN.md` | Built in GDScript instead (above) |
| The owner's original over-the-air update answers | REC-002 | A chat upload never committed; moot if REC-002 is superseded by OD-17 D36e |
| Game Designer files (six, section 1) | `docs/game-designer/*` | Never in this repository |
| `docs/build17/CON02_SERVICES.md`, `docs/build18/FARMING_RETAINED_DEFERRED.md`, `docs/design/FLIGHT_RECORDER.md`, `docs/design/SIM_GATE_AUDIT.md` | register on staging | Present only on `wip/expansion20`; recovery in Build 26 |
